--!strict
-- Prefer true interaction markers; use existing prop geometry when a stage has no markers.
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

local function plain(id: string, area: string, position: Vector3): Spot
	return { id = id, area = area, x = position.X, y = position.Y, z = position.Z }
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

local function marker(container: Instance?, names: { string }): Vector3?
	if container then
		for _, name in names do
			local hit = container:FindFirstChild(name, true)
			if hit then
				local position = location(hit)
				if position then
					if hit:IsA("Model") then
						return Vector3.new(position.X, Config.Map.GroundY, position.Z)
					end
					return position
				end
			end
		end
	end
	return nil
end

local function near(container: Instance?, names: { string }, centre: Vector3): Vector3?
	if not container then
		return nil
	end
	local nearest: Vector3? = nil
	local closest = Config.Village.SpotSearchStuds
	for _, inst in container:GetDescendants() do
		for _, name in names do
			if inst.Name == name or string.sub(inst.Name, 1, #name) == name then
				local position = location(inst)
				if position then
					local delta = position - centre
					local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
					if distance < closest then
						closest = distance
						-- Models may pivot above their floor; destinations belong on the ground.
						nearest = Vector3.new(position.X, Config.Map.GroundY, position.Z)
					end
				end
				break
			end
		end
	end
	return nearest
end

local function front(model: Instance?): Vector3?
	if model and model:IsA("Model") then
		-- Kit buildings face into the village; put feet on the door side, not at the pivot.
		local position = model:GetPivot().Position
			+ model:GetPivot().LookVector * (model:GetExtentsSize().Z / 2 + Config.Village.SpotDoorOffset)
		return Vector3.new(position.X, Config.Map.GroundY, position.Z)
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

	local function add(id: string, area: string, container: Instance?, names: { string }, modelPosition: Vector3?)
		local marked = marker(container, names)
		local position = marked or modelPosition
		if position then
			found += 1
			table.insert(foundNames, id .. (if marked then " (marker)" else " (model)"))
		else
			position = frames[area] or frames.plaza
			fallback += 1
			table.insert(fallbackNames, id)
		end
		result[id] = plain(id, area, position :: Vector3)
	end

	local models: { [string]: Instance } = {}
	for area: string, name: string in MODELS :: { [string]: string } do
		local model = if plot then plot:FindFirstChild(name) else nil
		if model then
			models[area] = model
		end
		add("entrance:" .. area, area, model, { "UpgradePoint", "Entrance", "Gate" }, front(model))
		if area == "fishing" or area == "garden" or area == "kitchen" or area == "training" then
			for slot, spotName in Config.Village.SpotNames.Work do
				add("work:" .. area .. ":" .. slot, area, model, { spotName }, nil)
			end
		end
	end

	local pantry = models.pantry
	local kitchen = models.kitchen
	local breeding = models.breeding
	local fishing = models.fishing
	local garden = models.garden
	local spots = Config.Village.SpotNames
	local pantryDoor = marker(pantry, spots.StorehouseModels) or front(pantry)
	add("storehouse", "pantry", pantry, spots.Storehouse, pantryDoor)
	local counterPosition = near(kitchen, spots.CounterModels, frames.kitchen)
	if not counterPosition and kitchen and kitchen:IsA("Model") then
		counterPosition = front(kitchen)
		if counterPosition then
			counterPosition += kitchen:GetPivot().RightVector * Config.Village.SpotCounterOffsetX
		end
	end
	add("counter", "kitchen", kitchen, spots.Counter, counterPosition)
	local fridgePosition = near(kitchen, spots.FridgeModels, frames.kitchen)
	if not fridgePosition and kitchen and kitchen:IsA("Model") then
		local counter = result.counter
		fridgePosition = Vector3.new(counter.x, counter.y, counter.z)
			+ kitchen:GetPivot().RightVector * Config.Village.SpotFridgeOffsetX
	end
	add("fridge", "kitchen", kitchen, spots.Fridge, fridgePosition)
	for _, area in { "fishing", "garden", "kitchen" } do
		local model = models[area]
		local approximate = front(model)
		if area == "kitchen" and kitchen and kitchen:IsA("Model") then
			local counter = result.counter
			approximate = Vector3.new(counter.x, counter.y, counter.z)
				+ kitchen:GetPivot().RightVector * Config.Village.SpotBoxOffsetX
		elseif area == "garden" then
			local entrance = result["entrance:garden"]
			approximate = Vector3.new(entrance.x, entrance.y, entrance.z)
		end
		add("box:" .. area, area, model, spots.Box, approximate)
	end

	add("breeding", "breeding", breeding, { "Entrance", "Nest1" }, front(breeding))
	add("nursery", "breeding", breeding, spots.Nursery, nil)
	for index, name in spots.Nest do
		add("nest:" .. index, "breeding", breeding, { name }, nil)
	end
	for index, name in spots.Incubator do
		add("incubator:" .. index, "breeding", breeding, { name }, nil)
	end
	local village = if plot then plot:FindFirstChild("Village") else nil
	local plazaPosition = near(plot, spots.Plaza, frames.plaza)
	add("plaza", "plaza", village, spots.Plaza, plazaPosition)
	local gatePosition = near(plot, spots.Gate, frames.gate)
	add("gate", "gate", village, spots.Gate, gatePosition)
	local well = near(plot, spots.FountainModels, frames.plaza)
	add("fountain", "plaza", village, spots.Fountain, well)
	add("flowers", "garden", garden, spots.Flowers, nil)
	add("pond", "fishing", fishing, spots.Pond, nil)
	local fire = near(plot, spots.CampfireModels, frames.hatchery)
	add("campfire", "hatchery", village, spots.Campfire, fire)
	local campfire = result.campfire
	local centre = Vector3.new(campfire.x, campfire.y, campfire.z)
	local seat = near(plot, spots.NapModels, centre)
	if not seat then
		-- Without a bench model, rest beside the fire rather than on its flames.
		seat = centre + Layout.plotFrame(plotNumber).RightVector * Config.Village.SpotNapOffset
	end
	add("nap", "hatchery", village, spots.Nap, seat)

	-- World markers can be added later without changing brain destinations.
	if plot then
		print(Config.LogPrefix, "village spots found:", found, table.concat(foundNames, ", "))
		print(Config.LogPrefix, "village spots fallback:", fallback, table.concat(fallbackNames, ", "))
	else
		print(Config.LogPrefix, "Plot" .. plotNumber .. " missing; using", fallback, "fallback village spots")
	end
	return result
end

return Spots
