--!strict
-- Prefer true interaction markers; use existing prop geometry when a stage has no markers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

-- fx/fy/fz: what a slime standing here faces (the well, the bin, the fire) when the spot was moved out of it.
export type Spot = {
	id: string,
	area: string,
	x: number,
	y: number,
	z: number,
	fx: number?,
	fy: number?,
	fz: number?,
}
local Spots = {}

local V = Config.Village

-- Everything a slime may not stand in or on: slimes and characters are not the world.
local function ignored(): { Instance }
	local list: { Instance } = {}
	local villages = workspace:FindFirstChild("Villages")
	if villages then
		table.insert(list, villages)
	end
	for _, player in game:GetService("Players"):GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

-- The walkable surface under (or a little above) a point: nil over water or over nothing. Parts that do
-- not collide (crops, flowers, markers) are not ground; the slimes stand on what a player would stand on.
function Spots.ground(position: Vector3, up: number?, depth: number?): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignored()
	params.RespectCanCollide = true
	local lift = up or V.GroundProbeUp
	local down = Vector3.new(0, -(lift + (depth or V.GroundProbeDown)), 0)
	local hit = workspace:Raycast(position + Vector3.new(0, lift, 0), down, params)
	if not hit or hit.Material == Enum.Material.Water then
		-- A thin ray falls through the gaps between dock planks: a ball does not (started a little higher,
		-- since a ball that begins inside the floor passes through it).
		local start = position + Vector3.new(0, lift + V.GroundProbeRadius, 0)
		hit = workspace:Spherecast(start, V.GroundProbeRadius, down, params)
	end
	if not hit or hit.Material == Enum.Material.Water then
		return nil
	end
	return hit.Position
end

-- A slime-sized box standing on `feet` touches nothing solid (exact shapes, not bounding boxes: a tree's
-- canopy does not block the grass under it).
local probe = Instance.new("Part")
probe.Anchored = true
probe.CanCollide = false
probe.CanQuery = false
probe.CanTouch = false
probe.Size = Vector3.new(V.SpotClearWidth, V.SpotClearHeight, V.SpotClearWidth)
function Spots.free(feet: Vector3): boolean
	probe.CFrame = CFrame.new(feet + Vector3.new(0, V.SpotClearLift + V.SpotClearHeight / 2, 0))
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignored()
	params.RespectCanCollide = true
	return #workspace:GetPartsInPart(probe, params) == 0
end

-- The nearest place to `position` where a slime can stand: on solid ground, out of water, inside no model.
-- Rings of candidates widen until one fits; among one ring the one nearest `toward` wins (the side of a
-- well or a bin that faces the path). Nil when nothing within SpotSettleRings fits.
-- `maxDrop`: a derived place (a spread around a busy spot) also may not step down into a hollow (the pond's dry rim).
function Spots.settle(position: Vector3, toward: Vector3?, maxDrop: number?, avoid: { Vector3 }?): Vector3?
	for ring = 0, V.SpotSettleRings do
		local radius = ring * V.SpotSettleStep
		local count = if ring == 0 then 1 else math.max(V.SpotSettleMinAngles, ring * V.SpotSettleAnglesPerRing)
		local best: Vector3? = nil
		local bestScore = math.huge
		for k = 1, count do
			local angle = (k - 1) * math.pi * 2 / count
			local candidate = position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			local feet = Spots.ground(candidate)
			-- (never on top of a prop: a log of the campfire, a bench, an incubator's lid)
			local step = if feet then feet.Y - position.Y else 0
			local taken = false
			if feet and avoid then
				for _, other in avoid do
					if (Vector3.new(other.X - feet.X, 0, other.Z - feet.Z)).Magnitude < V.SpotApartStuds then
						taken = true
						break
					end
				end
			end
			if
				feet
				and not taken
				and step <= V.SpotMaxRise
				and (not maxDrop or -step <= maxDrop)
				and Spots.free(feet)
			then
				local score = if toward
					then (Vector3.new(feet.X, 0, feet.Z) - Vector3.new(toward.X, 0, toward.Z)).Magnitude
					else 0
				if score < bestScore then
					best, bestScore = feet, score
				end
			end
		end
		if best then
			return best
		end
	end
	return nil
end

-- Move a spot onto the ground beside whatever it was inside of; it then faces that thing. `gap`: stand at least
-- this far from the middle of the thing (a bin: a step in front of it, never against it).
function Spots.place(spot: Spot, toward: Vector3?, gap: number?)
	local original = Vector3.new(spot.x, spot.y, spot.z)
	local settled = Spots.settle(original, toward)
	if not settled then
		warn(Config.LogPrefix, "village spot has no free ground near it:", spot.id)
		return
	end
	local flat = Vector3.new(settled.X - original.X, 0, settled.Z - original.Z)
	if gap and gap > 0 then
		local away = if flat.Magnitude > V.PathPointEpsilon
			then flat.Unit
			else (if toward
				then Vector3.new(toward.X - original.X, 0, toward.Z - original.Z).Unit
				else Vector3.new(1, 0, 0))
		-- (measured from the middle of the thing: the bins do not collide, so nothing pushed the spot out)
		local reach = math.max(gap, flat.Magnitude)
		settled = Spots.settle(original + away * reach, toward) or settled
		flat = Vector3.new(settled.X - original.X, 0, settled.Z - original.Z)
	end
	if flat.Magnitude > V.SpotFacePull then
		spot.fx, spot.fy, spot.fz = original.X, original.Y, original.Z
	end
	spot.x, spot.y, spot.z = settled.X, settled.Y, settled.Z
end

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

-- Service markers may be the *inside* pivot of a counter or a door.
-- Move them to the path-facing side of the whole building, not the pivot of that prop.
local function outside(model: Instance?, position: Vector3?, plaza: Vector3): Vector3?
	if not model or not model:IsA("Model") or not position then
		return position
	end
	-- Use the building pivot's facing, not the world-aligned bounding-box rotation.
	local cf, size = model:GetPivot(), model:GetExtentsSize()
	local p = cf:PointToObjectSpace(position)
	local frontZ = -size.Z / 2 - Config.Village.SpotDoorOffset
	local x = math.clamp(p.X, -size.X / 2, size.X / 2)
	local nearest: Vector3? = nil
	-- Test the nearest door-facing points first; the kitchen counter and fridge used to target
	-- their interior pivots, making every path from the plaza fail.
	for _, offset in Config.Village.SpotOutsideOffsets do
		local candidate =
			cf:PointToWorldSpace(Vector3.new(math.clamp(x + offset[1], -size.X / 2, size.X / 2), 0, frontZ - offset[2]))
		candidate = Vector3.new(candidate.X, Config.Map.GroundY, candidate.Z)
		nearest = nearest or candidate
		local path = PathfindingService:CreatePath({
			AgentRadius = Config.Village.PathMinRadius,
			AgentHeight = Config.Village.PathHeightPerScale,
			AgentCanJump = false,
			WaypointSpacing = Config.Village.PathWaypointStuds,
			Costs = { Water = Config.Village.PathWaterCost },
		})
		local ok = pcall(function()
			path:ComputeAsync(plaza, candidate)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			return candidate
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
		if id == "storehouse" or id == "counter" or id == "fridge" then
			position = outside(container, position, frames.plaza)
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

	local gardenStage = if garden then garden:FindFirstChild("AreaStage") else nil
	local stageCount = if gardenStage then gardenStage:GetAttribute("CropPlots") else nil
	local cropCount = if type(stageCount) == "number"
		then math.clamp(math.floor(stageCount), 1, Config.Work.GardenMaxPlotCount)
		else Config.Work.GardenPlotCount
	for index = 1, cropCount do
		add("crop:" .. index, "garden", garden, { "CropPlot" .. index }, nil)
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

	-- Every destination stands on the ground outside the models (the owner, 2026-10-29: a slime stood inside
	-- the plaza's well and hovered by the campfire). The plaza comes first, on the gate's side of the well;
	-- the rest settle on the side that faces the plaza, a bin's and an area's things on the side of the
	-- area's entrance. Bins keep a step between them and the slime, which tosses things in.
	Spots.place(result.plaza, frames.gate)
	local plazaPoint = Vector3.new(result.plaza.x, result.plaza.y, result.plaza.z)
	for id, spot in result do
		if id ~= "plaza" and string.sub(id, 1, 9) == "entrance:" then
			Spots.place(spot, plazaPoint)
		end
	end
	for id, spot in result do
		if id == "plaza" or string.sub(id, 1, 9) == "entrance:" or string.sub(id, 1, 5) == "crop:" then
			continue
		end
		local entrance = result["entrance:" .. spot.area]
		local toward = if entrance and (string.sub(id, 1, 4) == "box:" or string.sub(id, 1, 5) == "work:")
			then Vector3.new(entrance.x, entrance.y, entrance.z)
			else plazaPoint
		Spots.place(spot, toward, if string.sub(id, 1, 4) == "box:" then V.BinStandStuds else nil)
	end
	-- A gardener stands beside the plant, on the side of its own work place, never on the crop.
	local gardenHome = result["work:garden:1"]
	for index = 1, cropCount do
		local spot = result["crop:" .. index]
		local plant = Vector3.new(spot.x, spot.y, spot.z)
		local home = Vector3.new(gardenHome.x, plant.Y, gardenHome.z)
		local away = if (home - plant).Magnitude > V.PathPointEpsilon then (home - plant).Unit else Vector3.new(1, 0, 0)
		local stand = plant + away * V.CropStandStuds
		-- (on the garden floor, beside the bed: a bed is too high a step to stand on)
		spot.x, spot.y, spot.z = stand.X, gardenHome.y, stand.Z
		Spots.place(spot, home)
		spot.fx, spot.fy, spot.fz = plant.X, plant.Y, plant.Z
	end
	-- Each fishing place's rod stand: the slime turns to it to take the rod and to put it back.
	local pondStage = if fishing
		then fishing:FindFirstChild("PondStage") or fishing:FindFirstChild("AreaStage")
		else nil
	for slot = 1, #V.SpotNames.Work do
		local place = if pondStage then pondStage:FindFirstChild("WorkSpot" .. slot) else nil
		if place and place:IsA("BasePart") then
			local nearest: Model? = nil
			local distance = math.huge
			for _, stand in (pondStage :: Instance):GetChildren() do
				if stand:IsA("Model") and stand.Name == "RodStand" then
					local d = (stand:GetPivot().Position - place.Position).Magnitude
					if d < distance then
						nearest, distance = stand, d
					end
				end
			end
			if nearest then
				result["rod:" .. slot] = plain("rod:" .. slot, "fishing", nearest:GetPivot().Position)
			end
		end
	end

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
