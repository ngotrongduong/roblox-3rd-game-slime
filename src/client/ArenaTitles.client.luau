--!strict
-- The Arena titles over the heads: a player in the season's top 10 (the Player attribute ArenaRank, 1..10, 0 = none; the server
-- refreshes it every minute and it replicates to everyone) wears a small text over the head, never a name: "No.1 Arena" in gold,
-- "No.2 Arena" silver, "No.3 Arena" bronze, "Top 10 Arena" blue. It is a BillboardGui sized in pixels and scaled with the screen
-- (not in studs), white text with the kit's dark outline, painted by a gradient of the title's colour that a slow light sweeps
-- across. ONE heartbeat moves the sweep of every title (no loop per title) and looks at the distances twice a second; it runs only
-- while a title exists. Ranks 1 to 3 also get one slow sparkle emitter (the game's sparkStar picture, FightFx's glint), switched
-- on only when the player is near and the graphics quality is not low. Follows respawns and rank changes; a title goes away when
-- the rank leaves the top 10. (The owner asked for these himself: an exception to "no names over heads", a title only.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local T = Config.Arena.View.Title
local FX = Config.SlimeBuffFx

type Entry = {
	player: Player,
	rank: number,
	head: BasePart?,
	gui: BillboardGui?,
	gradient: UIGradient?,
	emitter: ParticleEmitter?,
	near: boolean,
	sparkling: boolean,
	connections: { RBXScriptConnection },
}

local entries: { [Player]: Entry } = {}
local beat: RBXScriptConnection? = nil

local function rankOf(player: Player): number
	local value = player:GetAttribute("ArenaRank")
	if type(value) == "number" and value >= 1 and value <= T.Top then
		return math.floor(value)
	end
	return 0
end

-- 1 gold, 2 silver, 3 bronze, 4 the rest of the top 10
local function styleOf(rank: number): number
	return if rank <= 3 then rank else 4
end

local function colourOf(rank: number): Color3
	local colours: { string } = T.Colours :: any
	return Color3.fromHex(colours[styleOf(rank)])
end

local function screenScale(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / T.ScaleReference, T.ScaleMin, T.ScaleMax) else 1
end

-- 0 = no particles; the graphics quality the player chose (1..21, 0 = automatic) as SlimeBuffs reads it.
local function sparklesAllowed(): boolean
	if not FX.Enabled then
		return false
	end
	local ok, level = pcall(function()
		return (settings() :: any).Rendering.QualityLevel.Value :: number
	end)
	return not ok or level == 0 or level > FX.LowQualityMax
end

-- The title's colours: its own colour with a lighter band in the middle, which the shared sweep slides across the text.
local function bandOf(base: Color3): ColorSequence
	local light = base:Lerp(Color3.new(1, 1, 1), T.ShimmerLift)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, base),
		ColorSequenceKeypoint.new(0.4, base),
		ColorSequenceKeypoint.new(0.5, light),
		ColorSequenceKeypoint.new(0.6, base),
		ColorSequenceKeypoint.new(1, base),
	})
end

local function clearVisuals(entry: Entry)
	if entry.gui then
		entry.gui:Destroy()
	end
	if entry.emitter then
		entry.emitter:Destroy()
	end
	entry.gui, entry.gradient, entry.emitter = nil, nil, nil
	entry.sparkling = false
end

local function sparkleOf(entry: Entry, head: BasePart): ParticleEmitter
	local colour = colourOf(entry.rank)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ArenaSparkle"
	emitter.Texture = "rbxassetid://" .. tostring(Config.Zombies.View.Fx.Textures.sparkStar)
	emitter.Rate = T.SparkleRate
	emitter.Lifetime = NumberRange.new(T.SparkleLife * 0.7, T.SparkleLife)
	emitter.Speed = NumberRange.new(0.3, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Shape = Enum.ParticleEmitterShape.Sphere
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, T.SparkleSize),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(colour:Lerp(Color3.new(1, 1, 1), T.ShimmerLift))
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-60, 60)
	emitter.Enabled = false
	emitter.Parent = head
	return emitter
end

-- How far above the head the title sits: T.Lift, or higher when a hat or wings stand taller (accessories load after the
-- head, so the twice-a-second look keeps this current).
local function liftOf(head: BasePart): number
	local character = head.Parent
	local top = head.Position.Y + head.Size.Y / 2
	if character then
		for _, child in character:GetChildren() do
			local handle = if child:IsA("Accessory") then child:FindFirstChild("Handle") else nil
			if handle and handle:IsA("BasePart") then
				top = math.max(top, handle.Position.Y + handle.Size.Y / 2)
			end
		end
	end
	return math.max(T.Lift, top - head.Position.Y + T.HatClearance)
end

-- (Re)makes the title on the player's head for its rank.
local function build(entry: Entry)
	clearVisuals(entry)
	local head = entry.head
	if not head or not head.Parent then
		return
	end
	local style = styleOf(entry.rank)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ArenaTitle"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(T.Width, T.Height)
	gui.StudsOffset = Vector3.new(0, liftOf(head), 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = T.MaxDistance
	gui.LightInfluence = 0
	gui.Parent = head
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = (Enum.Font :: any)[Config.Ui.Font]
	label.Text = (T.Names :: any)[style]
	label.TextSize = T.TextSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	-- the kit's outline: dark, around the letters only (the gradient below is on the letters, not on the outline)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromHex(Config.Ui.KitOutline)
	stroke.Thickness = Config.Ui.KitOutlineThickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label
	local gradient = Instance.new("UIGradient")
	gradient.Color = bandOf(colourOf(entry.rank))
	gradient.Offset = Vector2.new(-1, 0)
	gradient.Parent = label
	entry.gui, entry.gradient = gui, gradient
	if entry.rank <= T.SparkleRanks then
		entry.emitter = sparkleOf(entry, head)
	end
end

local function attachHead(entry: Entry, character: Model)
	task.spawn(function()
		local head = character:WaitForChild("Head", 10)
		if entries[entry.player] ~= entry or entry.player.Character ~= character then
			return
		end
		if head and head:IsA("BasePart") then
			entry.head = head
			build(entry)
		end
	end)
end

local function stop()
	if beat and next(entries) == nil then
		beat:Disconnect()
		beat = nil
	end
end

local function remove(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	entries[player] = nil
	clearVisuals(entry)
	for _, connection in entry.connections do
		connection:Disconnect()
	end
	stop()
end

-- The distances, twice a second: the title shows by itself up to MaxDistance (the BillboardGui's own limit); the sparkle
-- is switched on only inside SparkleStuds.
local function look()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local allowed = sparklesAllowed()
	for _, entry in entries do
		local head = entry.head
		if head and head.Parent then
			local distance = (head.Position - eye).Magnitude
			entry.near = distance <= T.MaxDistance
			local gui = entry.gui
			if gui and entry.near then
				local lift = liftOf(head)
				if math.abs(gui.StudsOffset.Y - lift) > 0.1 then
					gui.StudsOffset = Vector3.new(0, lift, 0)
				end
			end
			local spark = allowed and entry.near and distance <= T.SparkleStuds
			local emitter = entry.emitter
			if emitter and spark ~= entry.sparkling then
				entry.sparkling = spark
				emitter.Enabled = spark
			end
		else
			entry.near = false
		end
	end
end

-- The one beat of every title: the light sweeps across during the first share of each period, then rests off the end.
local function start()
	if beat then
		return
	end
	local sinceLook, sinceSweep = T.CheckSeconds, 0
	local sweepStep = 1 / T.ShimmerHz
	beat = RunService.Heartbeat:Connect(function(dt)
		sinceLook += dt
		sinceSweep += dt
		if sinceLook >= T.CheckSeconds then
			sinceLook = 0
			look()
		end
		if sinceSweep < sweepStep then
			return
		end
		sinceSweep = 0
		local phase = (os.clock() % T.ShimmerSeconds) / T.ShimmerSeconds
		local x = if phase < T.ShimmerSweep then -1 + 2 * (phase / T.ShimmerSweep) else 1
		local offset = Vector2.new(x, 0)
		for _, entry in entries do
			local gradient = entry.gradient
			if gradient and entry.near then
				gradient.Offset = offset
			end
		end
	end)
end

local function apply(player: Player)
	local rank = rankOf(player)
	if rank == 0 then
		remove(player)
		return
	end
	local entry = entries[player]
	if not entry then
		local fresh: Entry = {
			player = player,
			rank = rank,
			head = nil,
			gui = nil,
			gradient = nil,
			emitter = nil,
			near = true,
			sparkling = false,
			connections = {},
		}
		entries[player] = fresh
		table.insert(
			fresh.connections,
			player.CharacterAdded:Connect(function(character)
				fresh.head = nil
				clearVisuals(fresh)
				attachHead(fresh, character)
			end)
		)
		table.insert(
			fresh.connections,
			player.CharacterRemoving:Connect(function()
				fresh.head = nil
				clearVisuals(fresh)
			end)
		)
		if player.Character then
			attachHead(fresh, player.Character)
		end
		start()
		return
	end
	if entry.rank ~= rank then
		entry.rank = rank
		build(entry)
	end
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("ArenaRank"):Connect(function()
		apply(player)
	end)
	apply(player)
end

Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(remove)
for _, player in Players:GetPlayers() do
	watch(player)
end
