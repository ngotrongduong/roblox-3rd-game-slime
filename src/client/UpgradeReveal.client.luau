--!strict
-- Short local-only reveal of the ACTUAL changed stage pieces, plus a readable celebration
-- over them. Never tween server-owned collision/geometry or saved levels.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Fx = Config.UpgradeFx
local player = Players.LocalPlayer
local startedAt = workspace:GetServerTimeNow()
-- weak: a destroyed stage must not stay in memory for the whole session
local seen: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
-- one celebration an area: a second quick upgrade replaces the first instead of stacking titles
local live: { [string]: BasePart } = {}

local NAMES: { [string]: string } = {
	fishing = "FISHING POND",
	garden = "GARDEN",
	pantry = "STOREHOUSE",
	kitchen = "KITCHEN",
	breeding = "BREEDING PEN",
	training = "TRAINING GROUND",
	village = "VILLAGE",
}

local function rgb(values: { number }): Color3
	return Color3.fromRGB(values[1], values[2], values[3])
end

local function emitter(texture: string, parent: Instance): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Rate = 0
	particles.Shape = Enum.ParticleEmitterShape.Box
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = parent
	return particles
end

-- The anchor covers the changed pieces, so the sparkles rise where the work happened, not at their middle.
local function flash(parts: { BasePart }, focus: Vector3, area: string, level: number)
	local low, high = focus, focus
	for _, part in parts do
		local half = part.Size / 2
		low = low:Min(part.Position - half)
		high = high:Max(part.Position + half)
	end
	local anchor = Instance.new("Part")
	anchor.Name = "UpgradeCelebration"
	anchor.Size = (high - low):Max(Vector3.one):Min(Vector3.one * Fx.BurstMaxStuds)
	anchor.CFrame = CFrame.new((low + high) / 2)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Anchored = true
	anchor.Parent = workspace
	Debris:AddItem(anchor, Fx.FxLifetimeSeconds)
	if live[area] then
		live[area]:Destroy()
	end
	live[area] = anchor

	local newEra = level >= Fx.FirstEraUpgradeLevel and level % Fx.EraStepLevels == 1
	local sparkle = emitter("rbxasset://textures/particles/sparkles_main.dds", anchor)
	sparkle.Color = ColorSequence.new(rgb(Fx.Gold), rgb(Fx.Cream))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, Fx.SparkleSize),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Lifetime = NumberRange.new(Fx.SparkleLifetimeMin, Fx.SparkleLifetimeMax)
	sparkle.Speed = NumberRange.new(Fx.SparkleSpeedMin, Fx.SparkleSpeedMax)
	sparkle.Acceleration = Vector3.new(0, Fx.SparkleAccelerationY, 0)
	sparkle:Emit(math.floor(Fx.SparkleCount * (if newEra then Fx.EraSparkleMultiplier else 1)))
	task.delay(Fx.SparkleSecondDelay, function()
		if sparkle.Parent then
			sparkle:Emit(math.floor(Fx.SparkleSecondCount * (if newEra then Fx.EraSparkleMultiplier else 1)))
		end
	end)
	if newEra then
		-- a new era is real building work: a cloud of dust rolls out from it
		local dust = emitter("rbxasset://textures/particles/smoke_main.dds", anchor)
		dust.Color = ColorSequence.new(rgb(Fx.Dust))
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, Fx.DustSizeStart),
			NumberSequenceKeypoint.new(1, Fx.DustSizeEnd),
		})
		dust.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, Fx.DustTransparency),
			NumberSequenceKeypoint.new(1, 1),
		})
		dust.Lifetime = NumberRange.new(Fx.DustLifetimeMin, Fx.DustLifetimeMax)
		dust.Speed = NumberRange.new(Fx.DustSpeedMin, Fx.DustSpeedMax)
		dust:Emit(Fx.DustCount)
	end

	-- The outline shows what is new: the biggest changed pieces (`parts` comes biggest first), not the whole area.
	for index = 1, math.min(#parts, Fx.OutlinedParts) do
		local highlight = Instance.new("Highlight")
		highlight.Name = "UpgradeOutline"
		highlight.Adornee = parts[index]
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = rgb(Fx.Gold)
		highlight.FillTransparency = 0.75
		highlight.OutlineColor = rgb(Fx.Cream)
		highlight.OutlineTransparency = 0.1
		highlight.Parent = anchor
		TweenService:Create(
			highlight,
			TweenInfo.new(Fx.OutlineSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FillTransparency = 1, OutlineTransparency = 1 }
		):Play()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "UpgradeTitle"
	gui.Adornee = anchor
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local screen = math.clamp(workspace.CurrentCamera.ViewportSize.Y / Fx.ScreenBaseY, Fx.ScreenMin, Fx.ScreenMax)
	gui.Size = UDim2.fromOffset(Fx.MessageWidthPixels * screen, Fx.MessageHeightPixels * screen)
	local above = anchor.Size.Y / 2 + Fx.MessageHeightStuds
	gui.StudsOffsetWorldSpace = Vector3.new(0, above, 0)
	gui.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Area"
	title.Size = UDim2.fromScale(1, 0.45)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = rgb(Fx.Cream)
	title.TextStrokeColor3 = rgb(Fx.Shadow)
	title.TextStrokeTransparency = 0
	title.Text = NAMES[area] or string.upper(area)
	title.Parent = gui

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Level"
	subtitle.Position = UDim2.fromScale(0, 0.43)
	subtitle.Size = UDim2.fromScale(1, 0.31)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.FredokaOne
	subtitle.TextScaled = true
	subtitle.TextColor3 = rgb(Fx.Gold)
	subtitle.TextStrokeColor3 = rgb(Fx.Shadow)
	subtitle.TextStrokeTransparency = 0
	subtitle.Text = if newEra then "NEW ERA! LEVEL " .. tostring(level) else "LEVEL " .. tostring(level) .. " UNLOCKED!"
	subtitle.Parent = gui

	-- what the new level does (Config.Pads.Gives)
	local gives = Instance.new("TextLabel")
	gives.Name = "Gives"
	gives.Position = UDim2.fromScale(0, 0.75)
	gives.Size = UDim2.fromScale(1, 0.25)
	gives.BackgroundTransparency = 1
	gives.Font = Enum.Font.FredokaOne
	gives.TextScaled = true
	gives.TextColor3 = rgb(Fx.Cream)
	gives.TextStrokeColor3 = rgb(Fx.Shadow)
	gives.TextStrokeTransparency = 0
	gives.Text = (Config.Pads.Gives :: any)[area] or ""
	gives.Parent = gui

	TweenService:Create(
		gui,
		TweenInfo.new(Fx.MessageSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = Vector3.new(0, above + Fx.MessageRiseStuds, 0) }
	):Play()
	for _, label in { title, subtitle, gives } do
		TweenService:Create(
			label,
			TweenInfo.new(Fx.MessageSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()
	end
end

-- A part's LocalTransparencyModifier does not reach its decals and textures: the stud look would float on its own.
local function setFade(part: BasePart, faces: { Decal }, value: number)
	part.LocalTransparencyModifier = value
	for _, face in faces do
		face.LocalTransparencyModifier = value
	end
end

local function reveal(inst: Instance)
	if seen[inst] then
		return
	end
	seen[inst] = true
	if not inst:IsA("Model") then
		return
	end
	local timestamp = inst:GetAttribute("UpgradeFxAt")
	local area = inst:GetAttribute("UpgradeFxArea")
	local level = inst:GetAttribute("UpgradeFxLevel")
	local rawFocus = inst:GetAttribute("UpgradeFxFocus")
	if type(timestamp) ~= "number" or type(area) ~= "string" or type(level) ~= "number" then
		return
	end
	local now = workspace:GetServerTimeNow()
	if timestamp < startedAt - Fx.JoinGraceSeconds or now - timestamp > Fx.MaxEventAgeSeconds then
		return -- never replay an old saved upgrade when joining or streaming distant scenery
	end
	local focus: Vector3 = if typeof(rawFocus) == "Vector3" then rawFocus else inst:GetPivot().Position
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") and (root.Position - focus).Magnitude > Fx.ViewDistanceStuds then
		return
	end

	-- Hide marked pieces the moment they exist (a big stage arrives over several frames, and a piece
	-- seen for one frame before it fades reads as a flicker). Their server collision stays intact.
	local parts: { BasePart } = {}
	local faces: { [BasePart]: { Decal } } = {}
	local function hide(descendant: Instance)
		local owner = if descendant:IsA("Decal") then descendant.Parent else descendant
		if not owner or not owner:IsA("BasePart") or owner:GetAttribute(Fx.PartAttribute) ~= true then
			return
		end
		if not faces[owner] then
			faces[owner] = {}
			table.insert(parts, owner)
			owner.LocalTransparencyModifier = 1
		end
		if descendant:IsA("Decal") then
			table.insert(faces[owner], descendant)
			descendant.LocalTransparencyModifier = 1
		end
	end
	local arriving = inst.DescendantAdded:Connect(hide)
	for _, descendant in inst:GetDescendants() do
		hide(descendant)
	end
	task.wait(Fx.ClientSettleSeconds)
	arriving:Disconnect()
	if not inst.Parent then
		return
	end

	-- biggest first for the outlines, ground up for the build: the area rises in waves
	table.sort(parts, function(a: BasePart, b: BasePart): boolean
		return a.Size.Magnitude > b.Size.Magnitude
	end)
	flash(parts, focus, area, level)
	local order = table.clone(parts)
	table.sort(order, function(a: BasePart, b: BasePart): boolean
		return a.Position.Y < b.Position.Y
	end)
	local start = os.clock()
	local fading: RBXScriptConnection
	-- One loop for every piece: a hundred tweens on a cheap phone are a hundred needless objects.
	fading = RunService.Heartbeat:Connect(function()
		local clock = os.clock() - start
		for index, part in order do
			local at = (index - 1) / #order * Fx.RevealStaggerSeconds
			local alpha = math.clamp((clock - at) / Fx.RevealSeconds, 0, 1)
			setFade(
				part,
				faces[part],
				1 - TweenService:GetValue(alpha, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			)
		end
		if clock >= Fx.RevealStaggerSeconds + Fx.RevealSeconds or not inst.Parent then
			fading:Disconnect()
		end
	end)
end

CollectionService:GetInstanceAddedSignal(Fx.Tag):Connect(reveal)
for _, inst in CollectionService:GetTagged(Fx.Tag) do
	task.spawn(reveal, inst)
end
