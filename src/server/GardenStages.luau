--!strict
-- The vegetable garden's 50 levels. Since 2026-11-17 the garden is a landmark (village v2, skill landmark-build;
-- the ladder is docs/areas/village-v2/garden-ladder.md): its fence, gate, garden house and water tower are
-- server/Garden, in five architectures of ten levels each. This module keeps what is the area's own:
--   the floor, grown once at the back (the house and the tower stand behind the beds), and the path from the gate
--   the bed frames, in the era's material
--   levels 2-5 of each era: four garden props, one a level, each slot taking its next, better version:
--                        1 water (watering can > rain barrel > hand pump > sprinkler > watering drone)
--                        2 tools (tool rack > soil cart > seed spreader > tiller > garden robot)
--                        3 compost (compost bin > tumbler > fertiliser sacks > fertiliser tank > goo
--                        composter)   4 scarecrow (straw > hatted > pinwheel post > bird repeller >
--                        robot scarecrow)
--   the farm life round the outside, the work spots, the crop markers and the vegetable bin
-- Tiers and helpers are the pantry's (PantryStages): the classic stud look, a tier in its colours;
-- every prop at its real height (the player is 5 studs). The beds, crops and work spot stay; the
-- soil floor stays soil. Positions are in the garden's own frame (x across, z from the gate in).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Garden = require(script.Parent.Garden)
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)
local WorkProps = require(script.Parent.WorkProps)

local GardenStages = {}

GardenStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, place = PantryStages.part, PantryStages.place

-- the fence (inside the area's frame; it is Garden's) stands round the grown house: x from -WX to WX, z from FZ0
-- (front, the gate in its middle) back. The map's own soil is x -FX..FX and ends at z 21: a strip carries it to
-- z 28.5 under the house. The soil is laid on to the whole fence at every level (the owner, 2026-11-17: "why is the
-- back half green? make the whole area earth") and pairs of beds join the map's two era by era
-- (Config.Village.GardenYard; the owner, the same day: "the brown ground is small ... more garden beds and more area
-- after the upgrades").
-- (the village scale, 2026-10-30: the layout spread by about 1.4 from x +-13, z -9..15; the beds stand 11 studs
-- apart, every prop keeps its size; SPOT and SURROUND are written in the old layout, the numbers below in the new)
local WX, FZ0, ZB = Garden.fence()
local FX, FLOOR_END = 18, 21
local EDGE = 0.2 -- the soil runs this far under the fence, so no grass shows inside it
local YARD = Config.Village.GardenYard
local K = 1.4 -- the spread of every position written in the old layout
-- an era's material tier (PantryStages.Tiers) for the bed frames and the path
local ERA_TIER = { 1, 2, 3, 5, 6 }

-- The garden props, each placed for what it DOES (the owner, 2026-10-28: ask of every piece "does it
-- belong here, is this the right spot, what goes beside it"; inside the fence where it works, outside
-- only when it is too big or the garden is full; each at its real size, the player is 5 studs). The
-- beds lie at x 5.5..11.5 on each side, z -0.3..11.7, with the work path between them; the front corners
-- inside are open ground, the sides narrow strips along the beds; the garden house stands across the back,
-- the water tower in the back-left corner (+x is the garden's left as one walks in).
--   water      a watering can on its stand at a bed's front edge; then a rain barrel under the house's
--              eave; a hand pump in the front-right corner; a sprinkler on a stand between the beds; a
--              watering drone hovering over the beds
--   tools      a tool rack against the left fence by the beds; then carts and machines parked in
--              the front-left corner, turned to the path
--   compost    in the left strip behind the beds, where the beds' waste goes (clear of the tower's basin)
--   scarecrow  in the right side strip beside the beds, facing the vegetables
local PROPS = {
	{ "WateringCan", "RainBarrel", "HandPump", "Sprinkler", "WaterDrone" },
	{ "ToolRack", "SoilCart", "SeedSpreader", "Tiller", "GardenBot" },
	{ "CompostBin", "CompostTumbler", "FertiliserSacks", "FertiliserTank", "GooComposter" },
	{ "StrawScarecrow", "HatScarecrow", "PinwheelPost", "BirdRepeller", "RobotScarecrow" },
}
-- slot -> era -> { x, z, turn (degrees: 90 faces -x, -90 faces +x, 180 faces the back), real
-- height, the widest it may be, a hover lift }
local SPOT = {
	{
		{ -4.6, -3.2, 30, 1.2, 1.6 }, -- 0.4 m watering can by the right bed's front edge, on its stand
		{ 5.86, 12.57, 0, 2.9, 2.4 }, -- 1 m rain barrel at the house's front corner, under its eave
		{ -9.5, -6.2, 0, 3.4, 2.4 }, -- 1.2 m hand pump in the front-right corner
		{ 0, 4.07, 0, 2.8, 2 }, -- 1 m sprinkler on its stand in the middle of the work path
		{ 0, 4, 0, 1.4, 2.4, 6.6 }, -- watering drone over the work path, well above a player's head
	},
	{
		{ 10.36, 4, -90, 4.6, 3.6 }, -- 1.6 m tool rack beside the left bed, facing it (clear of the next bed out)
		-- (the machines' bay: before the tool shed of the work yard (WINGS), beside its door, handles toward
		-- the beds, clear to pull them out)
		{ 23.6, -2.9, -120, 2.6, 2.6 }, -- 0.9 m soil cart
		{ 23.6, -2.9, -120, 3, 3.6 }, -- 1 m seed spreader
		{ 23.6, -2.9, -120, 3.2, 4.4 }, -- 1.1 m tiller
		{ 23.6, -2.9, -120, 3.6, 3.4 }, -- 1.25 m garden robot, on its charging pad
	},
	{
		-- (the left strip behind the beds: the tower's basin and chute took the back-left corner)
		{ 10.86, 10, 0, 2.9, 2.6 }, -- 1 m compost bin
		{ 10.86, 10, 0, 3.2, 3.4 }, -- 1.1 m tumbler
		{ 10.86, 10, 0, 2.6, 2.8 }, -- 0.9 m stack of fertiliser sacks
		{ 10.86, 10, 0, 5, 3 }, -- 1.75 m fertiliser tank
		{ 10.86, 10, 0, 5, 3.4 }, -- 1.75 m goo composter
	},
	{
		-- (in the right strip beside the beds, clear of the fence, facing the vegetables)
		{ -11, 3.8, -90, 5.4, 3.6 }, -- 1.9 m scarecrow, arms along the bed
		{ -11, 3.8, -90, 5.7, 3.6 },
		{ -11, 3.8, 0, 5.4, 2.8 }, -- pinwheel post
		{ -11, 3.8, 0, 5.7, 3.2 }, -- bird repeller
		{ -11, 3.8, -90, 5.6, 3.6 }, -- robot scarecrow
	},
}
-- Farm life round the garden that grows with the eras and is never taken away (kit model, x, z,
-- real height, the widest it may be, turn, from which era): flowers at the gate, harvest crates
-- waiting inside by the path, a wheelbarrow of produce by the gate outside, shrubs along the front
-- fence outside, out to its corners. (The benches outside went when the garden got its own seat, WINGS.)
-- (2026-11-17: the grown house stands where the shrubs behind the old fence were; they line the wide front instead)
local SURROUND: { { any } } = {
	{ "WildflowersGrass", 7.5, -11.5, 1.6, 4, 0, 1 },
	{ "FlowerShrub", -10.5, -11, 2.4, 3, 0, 1 },
	{ "FlowerShrub", 14.5, -10.5, 2.2, 3, 0, 1 },
	{ "PineBerryBush", 30.7, -11.1, 2.4, 3, 0, 1 },
	{ "FernCluster", -30.7, -11.1, 2.2, 3, 0, 1 },
	{ "CrateStack_Wood", -5.6, -7.4, 2, 2.2, 20, 2 }, -- harvest waiting beside the gate, low, off the path
	{ "Wheelbarrow", 6.8, -11.6, 2.2, 3, -30, 2 },
	{ "FlowerShrub", 21.4, -11.1, 2.2, 3, 0, 2 },
	{ "WildflowersGrass", -21.4, -11.1, 1.4, 3.5, 0, 2 },
	{ "HayBales_Stack", 8.2, 10.5, 2.6, 2.9, 90, 3 }, -- straw for mulch, by the compost behind the beds
	{ "Planter", 13, -11.5, 1.6, 3, 0, 4 },
	{ "Planter", -13.5, -11.5, 1.6, 3, 0, 4 },
	{ "FlowerShrub", 26.1, -11.1, 2.4, 3, 0, 5 },
	{ "FlowerShrub", -26.1, -11.1, 2.4, 3, 0, 5 },
}
-- The two wings of soil beside the beds (the owner, 2026-11-17: about four beds, the rest of the soil for the
-- garden's side works and ornaments, "each in its right place and at its right size for what it does, not to fill
-- the ground; what we do not have is proposed, not forced in"). They are used from the era the beds double, in
-- REAL positions (not the old layout), each piece against the side fence at the beds' depth:
--   the tower's side   the work yard: a tool shed, its door to the beds (the machines park before it, SPOT)
--   the other side     the seat: a bench looking over the beds, its lamp beside it, a flower bed at each end
-- (sizes and models as the village's own benches, lamps and flower beds). The rest of the soil stays open; what
-- could stand there one day is listed in docs/areas/village-v2/garden-ladder.md.
-- { x, z, turn, the widest it may be, the models of the eras 2, 3, 4 and 5 (fewer: none later), their real heights }
local FLOWER_BEDS = { "PropPlanterRiveted", "PropPlanterStone", "PropPlanterCrown", "PropPlanterRoyal" }
local WINGS: { { any } } = {
	-- (the kit's shed is timber under red tiles: right beside the red-tiled houses of the eras 2 and 3, wrong beside
	-- steel and glass or marble, so the last two eras have a tool store of their own: Garden.toolStore)
	{ 40.5, 3, 90, 10, { "StorageShed", "StorageShed" }, { 9, 9 } },
	{ -44.4, 6, -90, 4.4, { "ParkBench", "IronBench", "ModernBench", "MarbleBench" }, { 2.7, 2.7, 1.5, 2.8 } },
	{
		-45,
		9.25,
		0,
		4.4,
		{ "LanternPost", "PropLampStone", "PropLampTech", "PropLampRoyal" },
		{ 8.6, 9.2, 9.6, 9.2 },
	},
	{ -45, -1, -90, 5.4, FLOWER_BEDS, { 4, 4, 4, 4 } },
	{ -45, 13, -90, 5.4, FLOWER_BEDS, { 4, 4, 4, 4 } },
}
-- the scenery's two sunflowers stand at the front of the soil, left of the gate (the house took their place at the
-- back, the third bed their place beside the beds)
local SUNFLOWERS = { { 20, -9.5 }, { 22, -9.5 } }

-- What a level holds: its era, and each prop slot's era (0: none).
function GardenStages.state(level: number): (number, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local props = {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	return era, props
end

function GardenStages.tierName(level: number): string
	local era = GardenStages.state(level)
	return TIERS[ERA_TIER[era]].name
end

-- The garden's layer for a level. `area` is the garden model: its bed frames take the era's tier, its
-- old fence, barrel, watering can and stepping stones go (the layer stands in for them).
function GardenStages.build(area: Instance, frame: CFrame, level: number): Model
	local era, props = GardenStages.state(level)
	local pt = ERA_TIER[era]
	local tier = TIERS[pt]
	local gold = Color3.fromRGB(232, 190, 80)
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)

	-- the old pieces the layer replaces, and the bed frames (marble with a gold strip at the capital)
	for _, d in area:GetChildren() do
		if d.Name == "Fence" or d.Name == "WateringCan" or d.Name == "WoodBarrel" or d.Name == "SteppingStone" then
			d.Parent = nil
		end
	end
	local function gild(plank: BasePart)
		if era == 5 then
			part(
				m,
				"BedGold",
				Vector3.new(plank.Size.X + 0.06, 0.12, plank.Size.Z + 0.06),
				plank.CFrame * CFrame.new(0, plank.Size.Y / 2 + 0.06, 0),
				gold,
				Enum.Material.Foil
			)
		end
	end
	for _, d in area:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "BedPlank" then
			d.Color = tier.walls
			PondStages.studLook(d, tier.wallMat)
			gild(d)
		end
	end
	-- the beds beyond the map's two: a pair at a time, outside the ones before (copies of the map's, so they wear
	-- the era's frames too)
	local more = (YARD.Beds[era] - 2) / 2
	local beds = area:FindFirstChild("Beds")
	if beds then
		for k = 1, more do
			for _, d in beds:GetDescendants() do
				if d:IsA("BasePart") then
					local side = if frame:PointToObjectSpace(d.Position).X < 0 then -1 else 1
					local copy = d:Clone()
					copy.CFrame = d.CFrame + frame:VectorToWorldSpace(Vector3.new(side * k * YARD.BedPitch, 0, 0))
					copy.Parent = m
					if d.Name == "BedPlank" then
						gild(copy)
					end
				end
			end
		end
	end

	-- the scenery: the two sunflowers move beside the beds; any other tree or bush where the house, the tower
	-- and its sails stand goes
	local sunflower = 0
	local x0, x1, z0, z1 = Garden.footprint(level)
	for _, d in (area.Parent or area):GetDescendants() do
		if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
			local p = frame:PointToObjectSpace(d:GetPivot().Position)
			if d.Name == "Sunflower" and d:IsDescendantOf(area) and sunflower < #SUNFLOWERS then
				sunflower += 1
				local to = SUNFLOWERS[sunflower]
				d:PivotTo(d:GetPivot() + frame:VectorToWorldSpace(Vector3.new(to[1] - p.X, 0, to[2] - p.Z)))
			elseif p.X > x0 and p.X < x1 and p.Z > z0 and p.Z < z1 then
				d.Parent = nil
			end
		end
	end

	-- the soil: the whole fenced garden, behind the map's floor and on both sides of it
	local floor = area:FindFirstChild("Floor")
	local function soil(name: string, xFrom: number, xTo: number, zFrom: number, zTo: number)
		local p = part(
			m,
			name,
			Vector3.new(xTo - xFrom, 0.2, zTo - zFrom),
			frame * CFrame.new((xFrom + xTo) / 2, 0.1, (zFrom + zTo) / 2),
			if floor and floor:IsA("BasePart") then floor.Color else Color3.fromRGB(196, 134, 82)
		)
		if floor and floor:IsA("BasePart") then
			p.Material, p.TopSurface = floor.Material, floor.TopSurface
		end
	end
	soil("FloorExt", -FX, FX, FLOOR_END, ZB + EDGE)
	soil("SoilWing", FX, WX + EDGE, FZ0, ZB + EDGE)
	soil("SoilWing", -WX - EDGE, -FX, FZ0, ZB + EDGE)

	-- the fence, the gate, the garden house and the water tower
	Garden.build(m, frame, level)

	-- the path from the gate to the work spot (ChatGPT's review: a continuous route that changes
	-- with the tier, not three stones): a 3.2-wide band, slabs on it, an edge on painted tiers up
	local bandCol = ({
		Color3.fromRGB(150, 108, 70), -- worn earth
		Color3.fromRGB(226, 208, 170), -- cream gravel
		Color3.fromRGB(176, 104, 80), -- brick
		Color3.fromRGB(150, 154, 160), -- concrete
		Color3.fromRGB(40, 90, 96), -- slime tech
		Color3.fromRGB(236, 230, 218), -- marble
	})[pt]
	local zFrom, zTo = FZ0 - 0.2, -0.4 * K
	part(
		m,
		"PathBand",
		Vector3.new(3.2, 0.1, zTo - zFrom), -- (flush: a raised band read as a bulky step)
		frame * CFrame.new(0, 0.25, (zFrom + zTo) / 2),
		bandCol,
		Enum.Material.Plastic
	)
	if pt >= 2 then
		for _, s in { -1, 1 } do
			part(
				m,
				"PathEdge",
				Vector3.new(0.18, 0.15, zTo - zFrom),
				frame * CFrame.new(s * 1.7, 0.27, (zFrom + zTo) / 2),
				tier.edge,
				tier.yardMat
			)
		end
	end
	local slabs: { number } = if pt >= 4 then { -10.6, -7.7, -4.8, -1.9 } else { -10.6, -6.7, -2.8 }
	for k, z in ipairs(slabs) do
		local w = if pt >= 4 then 2.6 else 1.7 + (k % 2) * 0.3
		part(
			m,
			"PathStone",
			Vector3.new(w, 0.3, if pt >= 4 then 1.8 else 1.4),
			frame * CFrame.new(if pt >= 4 then 0 else (k % 2 - 0.5) * 0.5, 0.38, z),
			tier.base,
			tier.baseMat
		)
	end
	if pt >= 6 then
		for _, z in { FZ0 + 0.6, -4.45 * K } do
			part(m, "GoldStrip", Vector3.new(3.2, 0.1, 0.15), frame * CFrame.new(0, 0.42, z), gold, Enum.Material.Foil)
		end
	end

	-- the farm life round the outside
	-- (the garden's soil stands 0.2 above the lawn: what is on it stands on its top)
	local function floorAt(x: number, z: number): number
		return if math.abs(x) <= WX and z >= FZ0 and z <= ZB then 0.2 else 0
	end
	-- a kit model standing at a spot, turned about its own middle
	local function stand(key: string, x: number, z: number, height: number, widest: number, yaw: number)
		local old = PantryStages.StandIn[key]
		local prop = place(m, frame, key, x, z, height, widest, floorAt(x, z))
			or (old and place(m, frame, old, x, z, height, widest, floorAt(x, z)))
		if prop and yaw ~= 0 then
			local box = prop:GetBoundingBox()
			local centre = CFrame.new(box.Position)
			prop:PivotTo(centre * CFrame.Angles(0, math.rad(yaw), 0) * centre:ToObjectSpace(prop:GetPivot()))
		end
	end
	for _, s in SURROUND do
		if era >= s[7] then
			stand(s[1], s[2] * K, s[3] * K, s[4], s[5], s[6])
		end
	end
	-- the work yard and the seat in the two wings
	if era >= 2 then
		for _, w in WINGS do
			local key = w[5][era - 1]
			if key then
				stand(key, w[1], w[2], w[6][era - 1], w[4], w[3])
			end
		end
		-- (the shed's spot at the eras 4 and 5: the era's own tool store, its door to the beds)
		local shed = WINGS[1]
		Garden.toolStore(
			m,
			frame * CFrame.new(shed[1], floorAt(shed[1], shed[2]), shed[2]) * CFrame.Angles(0, math.rad(shed[3]), 0),
			era
		)
	end

	-- the garden props
	for j = 1, 4 do
		local propEra = props[j]
		if propEra > 0 then
			local slot = SPOT[j][propEra]
			local name = PROPS[j][propEra]
			local x, z, yaw = slot[1] * K, slot[2] * K, slot[3]
			local lift = (slot[6] or 0) + floorAt(x, z)
			-- small parts that say what a prop is for (ChatGPT's 5th garden review)
			local function bit(
				n: string,
				size: Vector3,
				dx: number,
				y: number,
				dz: number,
				col: Color3,
				mat: Enum.Material?
			)
				return part(m, n, size, frame * CFrame.new(x + dx, y, z + dz), col, mat)
			end
			local metal, teal = Color3.fromRGB(110, 116, 126), Color3.fromRGB(70, 190, 170)
			if name == "WateringCan" then
				-- the can stands on a plank stand, a bucket beside it: a 1.2-stud can alone is too small to
				-- be a level's step
				local plank, leg = Color3.fromRGB(176, 128, 78), Color3.fromRGB(128, 84, 50)
				bit("CanStand", Vector3.new(2.4, 0.2, 1.6), 0, lift + 1.2, 0, plank, Enum.Material.WoodPlanks)
				for _, s in { -1, 1 } do
					bit("CanStandLeg", Vector3.new(0.3, 1.1, 1.4), s * 0.9, lift + 0.55, 0, leg, Enum.Material.Wood)
				end
				bit("CanStandRail", Vector3.new(1.8, 0.25, 0.2), 0, lift + 0.45, 0, leg, Enum.Material.Wood)
				local bucket =
					bit("Bucket", Vector3.new(1, 1, 1), 1.9, lift + 0.5, -0.3, metal, Enum.Material.Metal) :: Part
				bucket.Shape = Enum.PartType.Cylinder
				bucket.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
				local water = bit(
					"BucketWater",
					Vector3.new(0.1, 0.8, 0.8),
					1.9,
					lift + 0.98,
					-0.3,
					Color3.fromRGB(96, 170, 220)
				) :: Part
				water.Shape = Enum.PartType.Cylinder
				water.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
				lift += 1.3
			elseif name == "RainBarrel" then
				-- a downpipe from the house's eave into the barrel, a tap low on its front
				bit("Downpipe", Vector3.new(0.22, 3, 0.22), -1.7, lift + 4.4, 0, metal, Enum.Material.Metal)
				bit("DownpipeElbow", Vector3.new(1.7, 0.22, 0.22), -0.85, lift + 3, 0, metal, Enum.Material.Metal)
				bit("Tap", Vector3.new(0.25, 0.25, 0.5), 0, lift + 0.7, -1.2, metal, Enum.Material.Metal)
			elseif name == "HandPump" then
				local bucket =
					bit("Bucket", Vector3.new(0.8, 0.9, 0.9), 0, lift + 0.4, -1.4, metal, Enum.Material.Metal) :: Part
				bucket.Shape = Enum.PartType.Cylinder
				bucket.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
			elseif name == "WaterDrone" then
				-- its dock before the palm house's right wing, where it rests when it is not flying
				bit("DroneDock", Vector3.new(1.8, 0.15, 1.8), -8.2, 0.28, 11.4, teal, Enum.Material.SmoothPlastic)
			elseif name == "GardenBot" then
				-- a charging pad under it and a charging post beside it
				bit(
					"ChargePad",
					Vector3.new(3.2, 0.1, 3.2),
					0,
					lift + 0.05,
					0,
					Color3.fromRGB(60, 70, 80),
					Enum.Material.Metal
				)
				bit("ChargePost", Vector3.new(0.35, 1.8, 0.35), 2.4, lift + 0.9, 0, metal, Enum.Material.Metal)
				bit("ChargeLight", Vector3.new(0.45, 0.3, 0.45), 2.4, lift + 1.9, 0, teal, Enum.Material.Neon).CastShadow =
					false
				lift += 0.1
			end
			local prop = place(m, frame, name, x, z, slot[4], slot[5], lift)
			if prop and yaw ~= 0 then
				-- turned on the spot, about its own middle
				local box = prop:GetBoundingBox()
				local centre = CFrame.new(box.Position)
				prop:PivotTo(centre * CFrame.Angles(0, math.rad(yaw), 0) * centre:ToObjectSpace(prop:GetPivot()))
			end
		end
	end
	-- The work places (the owner, 2026-10-29): four, one on each side of the two beds, as invisible markers
	-- WorkSpot1..4 (front, right, back, left), found from where the beds really are; the vegetable bin
	-- outside the gate beside the path; and a marker CropPlot1..n at every planting spot of the beds, for
	-- the crop cycle (numbered along x, then z; the attribute Bed is 1 for the left bed, 2 for the right).
	local W = Config.WorkPlaces
	local function marker(name: string, cf: CFrame, size: Vector3): Part
		local mk = part(m, name, size, cf, Color3.new(1, 1, 1)) :: Part
		mk.Transparency = 1
		mk.CanCollide = false
		mk.CanQuery = false
		mk.CanTouch = false
		mk.CastShadow = false
		return mk
	end
	if beds and beds:IsA("Model") then
		local box, size = beds:GetBoundingBox()
		local c = frame:PointToObjectSpace(box.Position)
		local hx, hz = size.X / 2, size.Z / 2
		local gap, shift = W.GardenGap, W.GardenSideShift
		local places = {
			Vector3.new(c.X, 0, c.Z - hz - gap), -- front, on the path from the gate
			Vector3.new(math.min(c.X + hx + gap, WX - 1.5), 0, c.Z + shift),
			Vector3.new(c.X, 0, c.Z + hz + gap), -- back
			Vector3.new(math.max(c.X - hx - gap, -WX + 1.5), 0, c.Z + shift),
		}
		for k, p in places do
			marker("WorkSpot" .. k, frame * CFrame.new(p.X, 0.35, p.Z), Vector3.new(1.6, 0.2, 1.6))
		end
	end
	local plots: { { x: number, z: number, y: number } } = {}
	for _, d in area:GetChildren() do
		if d.Name == "Crop" and d:IsA("Model") then
			local p = frame:PointToObjectSpace(d:GetPivot().Position)
			table.insert(plots, { x = p.X, z = p.Z, y = p.Y })
		end
	end
	table.sort(plots, function(a, b)
		if math.abs(a.x - b.x) > 0.5 then
			return a.x < b.x
		end
		return a.z < b.z
	end)
	local count = 0
	local function plot(x: number, y: number, z: number, bed: number)
		if count < Config.Work.GardenMaxPlotCount then
			count += 1
			local mk = marker("CropPlot" .. count, frame * CFrame.new(x, y, z), Vector3.new(1.2, 0.2, 1.2))
			mk:SetAttribute("Bed", bed)
		end
	end
	for _, p in plots do
		plot(p.x, p.y, p.z, if p.x < 0 then 1 else 2)
	end
	-- (the added beds' plots are numbered after the map's, a bed at a time: a saved plot keeps its place)
	for k = 1, more do
		for _, side in { -1, 1 } do
			for _, p in plots do
				if (p.x < 0) == (side < 0) then
					plot(p.x + side * k * YARD.BedPitch, p.y, p.z, k * 2 + (if side < 0 then 1 else 2))
				end
			end
		end
	end
	m:SetAttribute("CropPlots", count)

	local V = W.VegBin
	WorkProps.bin(
		m,
		frame * CFrame.new(V[1], 0, V[2]) * CFrame.Angles(0, math.rad(V[3]), 0),
		"VegBin",
		"garden",
		WorkProps.Colours.honey,
		WorkProps.Colours.cream,
		Color3.fromRGB(226, 190, 100) -- a bed of straw
	)
	return m
end

return GardenStages
