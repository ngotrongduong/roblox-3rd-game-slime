--!strict
-- Upgrading a home plot's fishing pond with the E key (the owner, 2026-10-27: walk up to the dock,
-- press E, see the pond change). The server keeps the level and swaps the pond's stage layer
-- (PondStages) for the next level, with a burst of sparkles, bigger at an era's remodel. The original
-- level-1 dock and its tools are hidden while the stage layer stands in for them.
-- shortcut: free upgrades and the level kept only while the server runs (no cost, not saved, any
-- player may press); upgrade when the farm's coins and saved area levels exist (Phase 2).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local PondStages = require(script.Parent.PondStages)

local PLOT = 5
local COOLDOWN = 0.4 -- seconds between two presses of one player
local GROUND = Config.Map.GroundY or 2
local DOCK_X = -3 -- the level-1 dock's line in the pond's frame (build_fishing_l1)
-- the level-1 pieces the stage layer replaces
local REPLACED = { "Dock", "Rod", "RodHolder", "Line", "BobberTop", "BobberBottom", "FishBucket", "Bucket", "Catch" }

local map = workspace:FindFirstChild("Map")
local plot = map and map:FindFirstChild("Plot" .. PLOT)
local pond = plot and plot:FindFirstChild("FishingPondL1")
if not pond then
	return -- (the built game has no map yet: the plots are made in the work place)
end

local area = Layout.plotAreaFacing(PLOT, -1, 1)
local cell = area * CFrame.new(DOCK_X, GROUND, 0)

local function hideLevelOne()
	for _, name in REPLACED do
		local inst = pond:FindFirstChild(name)
		if inst then
			for _, d in (if inst:IsA("BasePart") then { inst } else inst:GetDescendants()) :: { Instance } do
				if d:IsA("BasePart") then
					d.Transparency = 1
					d.CanCollide = false
				elseif d:IsA("Decal") then
					d.Transparency = 1
				end
			end
		end
	end
end

-- A one-shot burst of sparkles (and dust at a remodel) where the dock meets the shore.
local function burst(remodel: boolean)
	local at = Instance.new("Part")
	at.Name = "UpgradeBurst"
	at.Size = Vector3.one
	at.Transparency = 1
	at.Anchored = true
	at.CanCollide = false
	at.CanQuery = false
	at.CFrame = cell * CFrame.new(0, 2, -6)
	at.Parent = workspace
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 230, 140), Color3.fromRGB(255, 255, 255))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Speed = NumberRange.new(8, 16)
	sparkle.SpreadAngle = Vector2.new(70, 70)
	sparkle.Acceleration = Vector3.new(0, -12, 0)
	sparkle.Rate = 0
	sparkle.Parent = at
	sparkle:Emit(if remodel then 90 else 30)
	if remodel then
		local dust = Instance.new("ParticleEmitter")
		dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dust.Color = ColorSequence.new(Color3.fromRGB(240, 232, 214))
		dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8) })
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		dust.Lifetime = NumberRange.new(1, 1.6)
		dust.Speed = NumberRange.new(4, 8)
		dust.SpreadAngle = Vector2.new(180, 30)
		dust.Rate = 0
		dust.Parent = at
		dust:Emit(24)
	end
	task.delay(2.5, function()
		at:Destroy()
	end)
end

local level = 1
local layer: Model? = nil

-- the big landmarks stand in the area's two front corners, either side of the path to the dock
local SHORE = { Vector2.new(-19, -12), Vector2.new(23, -11) }

-- The level-1 dressing (bushes, rocks) a landmark would stand in is hidden while it stands there.
local hidden: { [BasePart]: number } = {}
local function clearSpots(stage: Model)
	for p, t in hidden do
		p.Transparency = t
	end
	table.clear(hidden)
	local nature = pond:FindFirstChild("Nature")
	if not nature then
		return
	end
	for _, lm in stage:GetChildren() do
		if lm:IsA("Model") and lm:GetAttribute("Landmark") then
			local box, size = lm:GetBoundingBox()
			local reach = math.max(size.X, size.Z) / 2 + 2
			for _, n in nature:GetChildren() do
				if n:IsA("Model") and n.Name ~= "WaterLily" then
					local d = n:GetPivot().Position - box.Position
					if Vector2.new(d.X, d.Z).Magnitude < reach then
						for _, p in n:GetDescendants() do
							if p:IsA("BasePart") and hidden[p] == nil then
								hidden[p] = p.Transparency
								p.Transparency = 1
							end
						end
					end
				end
			end
		end
	end
end

local function show(newLevel: number)
	local old = layer
	local stage = PondStages.build(newLevel, cell, false, SHORE)
	stage.Parent = pond
	layer = stage
	if old then
		old:Destroy()
	end
	clearSpots(stage)
end

-- the prompt: an invisible post at the shore end of the dock
local anchor = Instance.new("Part")
anchor.Name = "UpgradePoint"
anchor.Size = Vector3.new(1, 4, 1)
anchor.Transparency = 1
anchor.Anchored = true
anchor.CanCollide = false
anchor.CFrame = cell * CFrame.new(0, 2, -15)
anchor.Parent = pond
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Upgrade"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Parent = anchor

local function refreshPrompt()
	local era = PondStages.stage(level)
	prompt.ObjectText = string.format("Fishing Pond · Level %d · %s", level, PondStages.Eras[era].name)
	prompt.ActionText = if level >= PondStages.MaxLevel then "Max level" else "Upgrade"
	prompt.Enabled = level < PondStages.MaxLevel
end

local lastPress: { [Player]: number } = {}
prompt.Triggered:Connect(function(player: Player)
	local now = os.clock()
	if now - (lastPress[player] or 0) < COOLDOWN or level >= PondStages.MaxLevel then
		return
	end
	lastPress[player] = now
	level += 1
	local _, step = PondStages.stage(level)
	show(level)
	burst(step == 1)
	refreshPrompt()
	print(Config.LogPrefix, player.Name, "upgraded the fishing pond to level", level)
end)
Players.PlayerRemoving:Connect(function(player: Player)
	lastPress[player] = nil
end)

hideLevelOne()
show(level)
refreshPrompt()
