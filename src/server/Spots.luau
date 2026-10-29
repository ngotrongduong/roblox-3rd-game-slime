--!strict
-- World markers are optional: a bare work place still has logical village destinations.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

export type Spot = { id: string, area: string, x: number, y: number, z: number }
local Spots = {}

local MODELS = {
	fishing = "FishingPondL1",
	garden = "GardenL1",
	kitchen = "KitchenL1",
	pantry = "PantryL1",
	training = "TrainingL1",
	breeding = "BreedingL1",
}

local function plain(id: string, area: string, point: Vector3): Spot
	return { id = id, area = area, x = point.X, y = point.Y, z = point.Z }
end

local function location(inst: Instance): Vector3?
	if inst:IsA("Attachment") then
		return inst.WorldPosition
	elseif inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

function Spots.build(plotNumber: number, plot: Instance?): { [string]: Spot }
	local found, fallback = 0, 0
	local foundNames: { string } = {}
	local fallbackNames: { string } = {}
	local result: { [string]: Spot } = {}
	local frames: { [string]: Vector3 } = {}
	for _, cell in Layout.PlotAreas do
		frames[cell.id] = Layout.plotAreaFacing(plotNumber, cell.col, cell.row).Position
			+ Vector3.new(0, Config.Map.GroundY, 0)
	end
	frames.plaza = Layout.plotFrame(plotNumber).Position + Vector3.new(0, Config.Map.GroundY, 0)
	frames.gate = Layout.plotGate(plotNumber).Position + Vector3.new(0, Config.Map.GroundY, 0)

	local function add(id: string, area: string, container: Instance?, names: { string })
		local position: Vector3? = nil
		if container then
			for _, name in names do
				local marker = container:FindFirstChild(name, true)
				if marker then
					position = location(marker)
					if position then
						break
					end
				end
			end
		end
		if position then
			found += 1
			table.insert(foundNames, id)
		else
			position = frames[area] or frames.plaza
			fallback += 1
			table.insert(fallbackNames, id)
		end
		result[id] = plain(id, area, position :: Vector3)
	end

	for area: string, name: string in MODELS :: { [string]: string } do
		local model = if plot then plot:FindFirstChild(name) else nil
		add("entrance:" .. area, area, model, { "UpgradePoint", "Entrance", "Gate" })
		if area == "fishing" or area == "garden" or area == "kitchen" or area == "training" then
			for slot, marker in Config.Village.SpotNames.Work do
				add("work:" .. area .. ":" .. slot, area, model, { marker })
			end
		end
		if area == "fishing" or area == "garden" or area == "kitchen" then
			add("box:" .. area, area, model, { "CollectionBox", "FishBucket", "HarvestBox", "DishBox" })
		end
	end

	local pantry = if plot then plot:FindFirstChild(MODELS.pantry) else nil
	local kitchen = if plot then plot:FindFirstChild(MODELS.kitchen) else nil
	local breeding = if plot then plot:FindFirstChild(MODELS.breeding) else nil
	local fishing = if plot then plot:FindFirstChild(MODELS.fishing) else nil
	local garden = if plot then plot:FindFirstChild(MODELS.garden) else nil
	local village = if plot then plot:FindFirstChild("Village") else nil
	add("storehouse", "pantry", pantry, Config.Village.SpotNames.Storehouse)
	add("counter", "kitchen", kitchen, Config.Village.SpotNames.Counter)
	add("fridge", "kitchen", kitchen, Config.Village.SpotNames.Fridge)
	add("breeding", "breeding", breeding, { "Entrance", "Nest1" })
	add("nursery", "breeding", breeding, Config.Village.SpotNames.Nursery)
	for index, marker in Config.Village.SpotNames.Nest do
		add("nest:" .. index, "breeding", breeding, { marker })
	end
	for index, marker in Config.Village.SpotNames.Incubator do
		add("incubator:" .. index, "breeding", breeding, { marker })
	end
	add("nap", "plaza", village, Config.Village.SpotNames.Nap)
	add("fountain", "plaza", village, Config.Village.SpotNames.Fountain)
	add("flowers", "garden", garden, Config.Village.SpotNames.Flowers)
	add("pond", "fishing", fishing, Config.Village.SpotNames.Pond)
	add("campfire", "hatchery", village, Config.Village.SpotNames.Campfire)
	add("plaza", "plaza", village, { "Plaza", "PlazaCentre" })
	add("gate", "gate", village, { "Gate", "FrontGate" })
	-- Client and brain use only these plain coordinates; a missing map never blocks the service.
	if plot then
		print(Config.LogPrefix, "village spots found:", found, table.concat(foundNames, ", "))
		print(Config.LogPrefix, "village spots fallback:", fallback, table.concat(fallbackNames, ", "))
	else
		print(Config.LogPrefix, "Plot" .. plotNumber .. " missing; using", fallback, "fallback village spots")
	end
	return result
end

return Spots
