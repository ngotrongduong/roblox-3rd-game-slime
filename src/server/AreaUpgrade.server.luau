--!strict
-- Upgrading a home plot's areas with the E key (the owner, 2026-10-27: walk up to an area, press E,
-- see it change). Each area has an Upgrade prompt at its entrance; the server keeps its level and
-- swaps its stage layer for the next level (PondStages for the fishing pond, AreaStages for the
-- others), with a burst of sparkles, bigger when a material tier starts. At the pond the original
-- level-1 dock and its tools are hidden while the stage layer stands in for them.
-- shortcut: free upgrades and the levels kept only while the server runs (no cost, not saved, any
-- player may press); upgrade when the farm's coins and saved area levels exist (Phase 2).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local AreaStages = require(script.Parent.AreaStages)
local PantryStages = require(script.Parent.PantryStages)
local GardenStages = require(script.Parent.GardenStages)
-- areas redone one by one with their own stages (the owner reviews each): build(area, frame, level),
-- tierName(level)
local BreedingStages = require(script.Parent.BreedingStages)
local KitchenStages = require(script.Parent.KitchenStages)
local TrainingStages = require(script.Parent.TrainingStages)
local OWN_STAGES: { [string]: any } = {
	PantryL1 = PantryStages,
	GardenL1 = GardenStages,
	BreedingL1 = BreedingStages,
	KitchenL1 = KitchenStages,
	TrainingL1 = TrainingStages,
}
local PondStages = require(script.Parent.PondStages)
-- the fence, gate and plaza: their level follows the areas' (VillageStages.levelOf)
local VillageStages = require(script.Parent.VillageStages)

local PLOT = 5
local COOLDOWN = 0.4 -- seconds between two presses of one player
local GROUND = Config.Map.GroundY or 2
local DOCK_X = -3 -- the level-1 dock's line in the pond's frame (build_fishing_l1)
-- the level-1 pieces of the pond the stage layer replaces
local REPLACED = { "Dock", "Rod", "RodHolder", "Line", "BobberTop", "BobberBottom", "FishBucket", "Bucket", "Catch" }
-- the areas: model name, (col, row) in the plot
local AREAS: { { any } } = {
	{ "FishingPondL1", -1, 1 },
	{ "GardenL1", 1, 1 },
	{ "PantryL1", 0, 1 },
	{ "KitchenL1", -1, 0 },
	{ "BreedingL1", 1, 0 },
	{ "TrainingL1", -1, -1 },
}

local map = workspace:FindFirstChild("Map")
local plot = map and map:FindFirstChild("Plot" .. PLOT)
if not plot then
	return -- (the built game has no map yet: the plots are made in the work place)
end

-- A one-shot burst of sparkles (and dust when a tier starts) at a point.
local function burst(at: CFrame, remodel: boolean)
	local p = Instance.new("Part")
	p.Name = "UpgradeBurst"
	p.Size = Vector3.one
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CFrame = at
	p.Parent = workspace
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
	sparkle.Parent = p
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
		dust.Parent = p
		dust:Emit(24)
	end
	task.delay(2.5, function()
		p:Destroy()
	end)
end

local function hidePondLevelOne(pond: Instance)
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

-- The village layer, rebuilt when the average of the areas' levels moves on.
local areaLevels: { [string]: number } = {}
local village = plot:FindFirstChild("Village")
local villageFrame = Layout.plotFrame(PLOT) * CFrame.new(0, GROUND, 0)
local villageLayer: Model? = nil
local villageLevel = 0
local function refreshVillage()
	if not village then
		return
	end
	local all = {}
	for _, l in areaLevels do
		table.insert(all, l)
	end
	local v = VillageStages.levelOf(all)
	if v == villageLevel then
		return
	end
	villageLevel = v
	local stage = VillageStages.build(village, villageFrame, v)
	stage.Parent = village
	if villageLayer then
		villageLayer:Destroy()
	end
	villageLayer = stage
	print(Config.LogPrefix, "village is now level", v)
end

local lastPress: { [Player]: number } = {}
Players.PlayerRemoving:Connect(function(player: Player)
	lastPress[player] = nil
end)

local function setUp(name: string, col: number, row: number)
	local area = plot:FindFirstChild(name)
	if not area then
		return
	end
	local frame = Layout.plotAreaFacing(PLOT, col, row) * CFrame.new(0, GROUND, 0)
	local isPond = name == "FishingPondL1"
	local label = if isPond then "Fishing Pond" else AreaStages.Specs[name].label
	local level = 1
	local layer: Model? = nil

	local function show(newLevel: number)
		local old = layer
		local own = OWN_STAGES[name]
		local stage = if own
			then own.build(area, frame, newLevel)
			elseif isPond then PondStages.build(newLevel, frame * CFrame.new(DOCK_X, 0, 0))
			else AreaStages.build(name, area, frame, newLevel)
		stage.Parent = area
		layer = stage
		if old then
			old:Destroy()
		end
	end

	-- the prompt: an invisible post at the area's entrance
	local spot = if isPond then { DOCK_X, -15 } else AreaStages.Specs[name].prompt
	local anchor = Instance.new("Part")
	anchor.Name = "UpgradePoint"
	anchor.Size = Vector3.new(1, 4, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = frame * CFrame.new(spot[1], 2, spot[2])
	anchor.Parent = area
	local prompt = Instance.new("ProximityPrompt")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	local function refreshPrompt()
		local own = OWN_STAGES[name]
		local tier = if own then own.tierName(level) else PondStages.tierName(level)
		prompt.ObjectText = string.format("%s · Level %d · %s", label, level, tier)
		prompt.ActionText = if level >= PondStages.MaxLevel then "Max level" else "Upgrade"
		prompt.Enabled = level < PondStages.MaxLevel
	end

	prompt.Triggered:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastPress[player] or 0) < COOLDOWN or level >= PondStages.MaxLevel then
			return
		end
		lastPress[player] = now
		level += 1
		show(level)
		burst(anchor.CFrame * CFrame.new(0, 0, 6), level % 5 == 1) -- dust when a material tier starts
		refreshPrompt()
		print(Config.LogPrefix, player.Name, "upgraded", label, "to level", level)
		areaLevels[name] = level
		refreshVillage()
	end)

	if isPond then
		hidePondLevelOne(area)
	end
	show(level)
	refreshPrompt()
	areaLevels[name] = level
end

for _, a in AREAS do
	setUp(a[1], a[2], a[3])
end
refreshVillage()
