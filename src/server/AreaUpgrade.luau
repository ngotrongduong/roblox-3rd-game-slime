--!strict
-- Upgrading a home plot's areas by stepping on a pad (the owner, 2026-10-29; before that an E prompt), now for every plot of
-- the server. Each area has an upgrade pad beside its entrance (UpgradePads); the server keeps its level and swaps its
-- stage layer for the next level (PondStages for the fishing pond, each area's own Stages builder for the others). Clients
-- materialise newly changed pieces locally. At the pond the original level-1 dock and its tools are hidden while the stage
-- layer stands in for them. Upgrades are saved and paid through VillageRemotes, including the E prompts.
--
-- A plot's world is the copy Plots made of the hand-built village. Once the copy stands and the player's farm has loaded,
-- `attach` builds every area straight at the saved level, with no reveal (the visuals are not save data: they are made
-- again from the saved levels on every join), then tells Plots the village is ready. An upgrade later (the pad, the
-- AreaLevelChanged event) swaps one layer with the reveal. A player leaving drops everything made for the plot.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local VillageRemotes = require(script.Parent.VillageRemotes)
local UpgradePads = require(script.Parent.UpgradePads)
local UpgradeReveal = require(script.Parent.UpgradeReveal)
local ZFight = require(script.Parent.ZFight)
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

local GROUND = Config.Map.GroundY or 2
local DOCK_X = -3 -- the level-1 dock's line in the pond's frame (build_fishing_l1)
-- the level-1 pieces of the pond the stage layer replaces
local REPLACED = { "Dock", "Rod", "RodHolder", "Line", "BobberTop", "BobberBottom", "FishBucket", "Bucket", "Catch" }
-- the areas: model name, (col, row) in the plot
local AREAS: { { any } } = {
	{ "FishingPondL1", -1, 1, "fishing" },
	{ "GardenL1", 1, 1, "garden" },
	{ "PantryL1", 0, 1, "pantry" },
	{ "KitchenL1", -1, 0, "kitchen" },
	{ "BreedingL1", 1, 0, "breeding" },
	{ "TrainingL1", -1, -1, "training" },
}

type Handle = {
	plot: number,
	-- area id -> set the area to a level (the second argument: with the reveal)
	apply: { [string]: (number, boolean) -> () },
	stop: () -> (),
}

local AreaUpgrade = {}
local handles: { [Player]: Handle } = {}
-- the copy of a player's village, once it stands; and the players being attached now
local copies: { [Player]: { plot: number, model: Model } } = {}
local attaching: { [Player]: boolean } = {}

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

-- Builds every area of one plot at the saved levels. Yields between areas so a big village does not stall the server.
local function attach(plotNumber: number, plot: Model, levels: { [string]: number }): Handle
	local stopWatching = ZFight.watch(plot)
	-- The village layer, rebuilt when the average of the areas' levels moves on.
	local areaLevels: { [string]: number } = {}
	local village = plot:FindFirstChild("Village")
	local villageFrame = Layout.plotFrame(plotNumber) * CFrame.new(0, GROUND, 0)
	local villageLayer: Model? = nil
	local villageLevel = 0
	local function refreshVillage(effects: boolean?)
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
		if effects and villageLayer then
			UpgradeReveal.prepare(villageLayer, stage, "village", v)
		end
		stage.Parent = village
		if villageLayer then
			villageLayer:Destroy()
		end
		villageLayer = stage
		print(Config.LogPrefix, "village of plot", plotNumber, "is now level", v)
	end

	local applyLevel: { [string]: (number, boolean) -> () } = {}
	local padsFolder: Instance = plot:FindFirstChild("UpgradePads") or Instance.new("Folder")
	padsFolder.Name = "UpgradePads"
	padsFolder.Parent = plot

	local function setUp(name: string, col: number, row: number, areaId: string, startLevel: number)
		local area = plot:FindFirstChild(name)
		if not area then
			return
		end
		local frame = Layout.plotAreaFacing(plotNumber, col, row) * CFrame.new(0, GROUND, 0)
		local isPond = name == "FishingPondL1"
		local level = startLevel
		local layer: Model? = nil

		local function show(newLevel: number, effects: boolean)
			if isPond then
				-- (the pond itself grows: its new lobes are carved before the layer stands on them)
				PondStages.grow(area, frame, newLevel)
			end
			local old = layer
			local own = OWN_STAGES[name]
			local stage = if own
				then own.build(area, frame, newLevel)
				elseif isPond then PondStages.build(newLevel, frame * CFrame.new(DOCK_X, 0, 0))
				else AreaStages.build(name, area, frame, newLevel)
			if effects and old then
				-- The change marker rides on the new layer so late-joining clients never replay it.
				UpgradeReveal.prepare(old, stage, areaId, newLevel)
			end
			stage.Parent = area
			layer = stage
			if old then
				old:Destroy()
			end
		end

		-- the area's entrance: an invisible post (the village brain's "entrance" spot reads it)
		local spot = if isPond then { DOCK_X, -20 } else AreaStages.Specs[name].prompt
		local anchor = Instance.new("Part")
		anchor.Name = "UpgradePoint"
		anchor.Size = Vector3.new(1, 4, 1)
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.CFrame = frame * CFrame.new(spot[1], 2, spot[2])
		anchor.Parent = area

		-- the upgrade pad beside the path (replaces the E prompt)
		local padSpot = Config.Pads.Spots[areaId]
		local setPad = UpgradePads.add(padsFolder, plotNumber, areaId, frame * CFrame.new(padSpot[1], 0, padSpot[2]))

		local function apply(newLevel: number, effects: boolean)
			if newLevel == level then
				return
			end
			level = newLevel
			show(level, effects)
			setPad(level)
			areaLevels[name] = level
			refreshVillage(effects)
		end
		applyLevel[areaId] = apply

		if isPond then
			hidePondLevelOne(area)
		end
		show(level, false)
		setPad(level)
		areaLevels[name] = level
	end

	for _, a in AREAS do
		setUp(a[1], a[2], a[3], a[4], levels[a[4]] or 1)
		task.wait()
	end
	refreshVillage()
	return { plot = plotNumber, apply = applyLevel, stop = stopWatching }
end

local function savedLevels(farm: any): { [string]: number }
	local levels: { [string]: number } = {}
	for _, row in AREAS do
		local area = (farm.areas :: any)[row[4]]
		if area and type(area.level) == "number" then
			levels[row[4]] = area.level
		end
	end
	return levels
end

-- Once the copy stands and the farm has loaded: the plot's areas at the saved levels, then the village is ready.
local function tryFinish(player: Player)
	local copy = copies[player]
	if not copy or handles[player] or attaching[player] or not PlayerData.isReady(player) then
		return
	end
	local farm = PlayerData.get(player)
	if not farm then
		return
	end
	attaching[player] = true
	local began = os.clock()
	local ok, made = pcall(attach, copy.plot, copy.model, savedLevels(farm))
	if not ok then
		-- (a stage that cannot be built must not hold the whole village back: it is reported, the rest stands)
		warn(Config.LogPrefix, "upgrades: building plot", copy.plot, "failed:", made)
	end
	local handle = if ok then made :: Handle else nil
	if not attaching[player] or Plots.of(player) ~= copy.plot then
		-- the player left while the areas were built
		if handle then
			handle.stop()
		end
		return
	end
	attaching[player] = nil
	if handle then
		handles[player] = handle
	end
	Plots.setReady(player)
	print(
		Config.LogPrefix,
		string.format("upgrades: plot %d is at %s's saved levels (%.2f s)", copy.plot, player.Name, os.clock() - began)
	)
end

-- Called once by Main.
function AreaUpgrade.start()
	UpgradePads.start(VillageRemotes.upgrade)
	Plots.onBuilt(function(player: Player, plot: number, model: Model)
		copies[player] = { plot = plot, model = model }
		tryFinish(player)
	end)
	PlayerData.onReady(function(player: Player, _data: any)
		tryFinish(player)
	end)
	Plots.onFreed(function(player: Player, _plot: number)
		copies[player] = nil
		attaching[player] = nil
		local handle = handles[player]
		if handle then
			handle.stop()
			handles[player] = nil
		end
	end)
	local events = ServerStorage:WaitForChild("VillageEvents")
	local changed = events:WaitForChild("AreaLevelChanged") :: BindableEvent
	changed.Event:Connect(function(player: Player, areaId: string, level: number)
		local handle = handles[player]
		local apply = if handle then handle.apply[areaId] else nil
		if apply then
			apply(level, true)
		end
	end)
end

return AreaUpgrade
