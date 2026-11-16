--!strict
-- The kitchen's 50 levels (the owner, 2026-10-28: "the same as the pantry, the garden and the pen").
-- Five eras of ten levels; in each era:
--   level 1 of the era   the cookhouse takes its next architecture (module `Kitchen`, village v2,
--                        2026-11-16: the hall, its great chimney and its terrace); era 3 brings a brick
--                        bread oven and a second cooking spot, era 4 a third
--   levels 2-5           four kitchen props, one a level, each slot taking its next, better version:
--                        1 ingredients (veggie crates > pickle barrels > spice cabinet > ice box >
--                        goo fridge)   2 grill (camp grill > stone grill > brick BBQ > steel grill >
--                        plasma grill)   3 water (rain barrel > hand pump > stone sink > steel sink >
--                        goo tap)   4 dishes (dish rack > plate shelf > serving cart > buffet warmer >
--                        food dispenser)
--   levels 6-10          the cookhouse gains one feature a level (lanterns, a lean-to, a wing, dormers,
--                        domes...); the floor, its border, the yard's lamps and the entrance arch still
--                        move up a material tier
-- Tiers and helpers are the pantry's. The kit stove, counter and firewood stay the area's own; the
-- cooking spots keep their markers (CookingSpotN with an Attachment WorkSpotN) for the work rules.
-- Positions are in the kitchen's own frame (x across, z from the front in).
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)
local GateArch = require(script.Parent.GateArch)
local Kitchen = require(script.Parent.Kitchen)

local KitchenStages = {}

KitchenStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, place = PantryStages.part, PantryStages.place

-- The village scale (the owner, 2026-10-30: "spread the inside of the kitchen too"): the whole kitchen is
-- laid out 1.3 times wider than before about its middle (pad, walls, roof span, spots, props against the
-- walls), every model and piece keeping its own size. The positions below are the spread ones.
-- the pad: x -14.3 .. 14.3, z -11.7 .. 11.7, the entrance at the front middle; the hall over z -5 .. 12.3
local XW = 14 -- the inside of the hall's side walls
local FLOOR = 0.4 -- the pad's floor stands this far above the lawn; props stand on its top

-- cooking spots: where, and from which level (the first is the area's own)
local SPOTS = { { 0, -1.6, 1 }, { 7.3, 1.8, 21 }, { -7.8, 1.2, 31 } }

local PROPS = {
	{ "VeggieCrates", "PickleBarrels", "SpiceCabinet", "IceBox", "GooFridge" },
	{ "CampGrill", "StoneGrill", "BrickBBQ", "SteelGrill", "PlasmaGrill" },
	{ "WoodBarrel", "HandPump", "StoneSink", "SteelSink", "GooTap" },
	{ "DishRack", "PlateShelf", "ServingCart", "BuffetWarmer", "FoodDispenser" },
}
-- real heights (studs, the player is 5)
local HEIGHT = {
	{ 2.2, 3.2, 5.2, 5.6, 6 },
	{ 3, 3.6, 4.4, 4.2, 4.2 }, -- (a cooking face at a grown-up's waist)
	{ 3, 4.4, 3.2, 3.4, 4.2 },
	{ 3, 4.8, 3.4, 3.4, 5 },
}
-- where each slot stands and which way it faces (degrees; 0 to the front, 90 to -x, -90 to +x): the
-- ingredients and the water against the left wall in front of the counter, the dishes against the
-- right wall, all facing in; the grill out in the front yard, turned to the path
local SLOT_AT = { { -12.4, 0.9, -90 }, { 9.9, -8.1, 90 }, { -12.4, -3.1, -90 }, { 12.4, -1.8, 90 } }
local FOOT = { 2.8, 4.2, 2.6, 2.6 }
-- kit models whose front came out of generate_mesh sideways: the turn (degrees) that brings it to -Z
local FRONT_TURN: { [string]: number } = { HandPump = 90, GooTap = -90 }

-- What a level holds: the era, how many cooking spots, each prop slot's era (0: none), each build's
-- tier (floor, border, rails and walls, lamps and roof, arch).
function KitchenStages.state(level: number): (number, number, { number }, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local spots = 0
	for _, p in SPOTS do
		spots += if level >= p[3] then 1 else 0
	end
	local props, tiers = {}, {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	for k = 1, 5 do
		tiers[k] = if s >= k + 5 then era + 1 else era
	end
	return era, spots, props, tiers
end

function KitchenStages.tierName(level: number): string
	local _, _, _, tiers = KitchenStages.state(level)
	return TIERS[tiers[1]].name
end

-- A part of the area itself takes a tier's colour; at tier 1 it keeps the look it was built with.
local function skin(p: BasePart, tier: number, colour: Color3, material: Enum.Material)
	if p:GetAttribute("BuiltColor") == nil then
		p:SetAttribute("BuiltColor", p.Color)
	end
	p.Color = if tier <= 1 then p:GetAttribute("BuiltColor") :: Color3 else colour
	PondStages.studLook(p, material)
end

local function glow(m: Model, name: string, size: Vector3, cf: CFrame, colour: Color3, range: number)
	local p = part(m, name, size, cf, colour, Enum.Material.Neon)
	p.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = colour
	light.Range = range
	light.Brightness = 0.7
	light.Parent = p
end

-- The kitchen's layer for a level. `area` is the kitchen model: its floor and border take their
-- tiers, its firewood moves aside when the bread oven comes.
function KitchenStages.build(area: Instance, frame: CFrame, level: number): Model
	local era, spots, props, tiers = KitchenStages.state(level)
	local tw, tl = TIERS[tiers[3]], TIERS[tiers[4]]
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)
	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end

	for _, d in area:GetChildren() do
		if d.Name == "Floor" and d:IsA("BasePart") then
			skin(d, tiers[1], TIERS[tiers[1]].yard, TIERS[tiers[1]].yardMat)
		elseif d.Name == "FloorEdge" and d:IsA("BasePart") then
			skin(d, tiers[2], TIERS[tiers[2]].edge, TIERS[tiers[2]].yardMat)
		elseif d.Name == "CookingSpot1" and d:IsA("BasePart") then
			-- a stone standing pad, not straw by the fire (ChatGPT's 1st kitchen review)
			skin(d, 2, tw.base, tw.baseMat)
		elseif d.Name == "FirewoodPile" and d:IsA("Model") then
			-- by the stove until the bread oven takes its place, then against the right wall
			local _, size = d:GetBoundingBox()
			local x, z = if era >= 3 then XW - 1.8 else 8.5, if era >= 3 then 2.1 else 3.9
			d:PivotTo(d:GetPivot() + (at(x, size.Y / 2, z).Position - d:GetBoundingBox().Position))
		end
	end

	-- the cookhouse: its hall, great chimney and terrace (the pot rack, the herbs and the roof lanterns are its own).
	-- The chimney, the terrace and the wing stand on the lawn beside the pad: any tree or bush of the scenery
	-- there goes.
	Kitchen.build(m, frame, level)
	do
		local x0, x1, z0, z1 = Kitchen.footprint(level)
		for _, d in (area.Parent or area):GetDescendants() do
			if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
				local p = frame:PointToObjectSpace(d:GetPivot().Position)
				if p.X > x0 and p.X < x1 and p.Z > z0 and p.Z < z1 then
					d.Parent = nil
				end
			end
		end
	end

	-- 4 lamps at the yard's front corners
	for _, s in { -1, 1 } do
		part(m, "LampPost", Vector3.new(0.5, 5, 0.5), at(s * 13.5, 2.5, -10.9), tl.frame, tl.frameMat)
		glow(m, "Lamp", Vector3.new(0.9, 0.9, 0.9), at(s * 13.5, 5.4, -10.9), tl.glass, 10)
	end

	-- era 3: the bread oven at the back right
	if era >= 3 then
		place(m, frame, "BrickOven", 9.4, 8.1, 6, 4.6, FLOOR)
	end

	-- 5 the entrance arch (GateArch): warm orange, the chef's hat emblem on top
	GateArch.build(m, frame, 0, 6, -12, tiers[5], Color3.fromRGB(240, 150, 60), "EmblemKitchen")

	-- the cooking spots beyond the area's own: a straw mat each, with its marker
	for i = 2, spots do
		local p = SPOTS[i]
		local mat = part(
			m,
			"CookingSpot" .. i,
			Vector3.new(0.1, 3.6, 3.6),
			at(p[1], 0.45, p[2]) * CFrame.Angles(0, 0, math.rad(90)),
			tw.base,
			tw.baseMat
		) :: Part
		mat.Shape = Enum.PartType.Cylinder
		mat.CanCollide = false
		local mark = Instance.new("Attachment")
		mark.Name = "WorkSpot" .. i
		mark.Parent = mat
	end

	-- signs of a kitchen in use (the owner's word on the pen, 2026-10-28: more life, in order): a table
	-- where the food is eaten in the front-left yard, the grill across the path from it; herbs drying
	-- under the front beam; a flour sack by the ingredients, a bucket by the water; a picture board by
	-- the entrance. Small bits do not collide or cast shadows.
	local tt = TIERS[tiers[3]]
	local function bit(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?): BasePart
		local p = part(m, name, size, cf, col, mat or Enum.Material.SmoothPlastic)
		p.CanCollide = false
		p.CastShadow = false
		return p
	end
	-- the dining table, outside on the cookhouse's terrace at the right (the owner, 2026-10-28: bigger, and
	-- outside): on its own deck until the terrace is raised on stone; the grill on its heatproof slab in the yard
	local tx, tz, DY = Kitchen.terrace(level)
	if DY < 0.5 then
		part(
			m,
			"DiningDeck",
			Vector3.new(8.4, 0.12, 6.6),
			at(tx, 0.06, tz),
			Color3.fromRGB(214, 176, 124),
			Enum.Material.WoodPlanks
		)
	end
	part(
		m,
		"GrillSlab",
		Vector3.new(4.8, 0.08, 4.8),
		at(SLOT_AT[2][1], FLOOR + 0.04, SLOT_AT[2][2]),
		Color3.fromRGB(150, 146, 140),
		Enum.Material.Slate
	)
	if era >= 4 then
		-- a warm brick hearth round the old stove, so the steel and slime-tech floors stay cozy there
		part(m, "Hearth", Vector3.new(8, 0.06, 5.4), at(0, FLOOR + 0.03, -0.65), TIERS[3].walls, TIERS[3].wallMat)
	end
	if era >= 3 then
		-- a bread peel against the side wall by the oven, a loaf on its paddle
		part(
			m,
			"PeelHandle",
			Vector3.new(0.15, 3.2, 0.15),
			at(XW - 0.6, FLOOR + 2.2, 10.7) * CFrame.Angles(0, 0, 0.18),
			Color3.fromRGB(176, 128, 84),
			Enum.Material.Wood
		)
		part(
			m,
			"PeelPaddle",
			Vector3.new(0.12, 1.1, 1),
			at(XW - 0.4, FLOOR + 0.6, 10.7) * CFrame.Angles(0, 0, 0.18),
			Color3.fromRGB(176, 128, 84),
			Enum.Material.Wood
		)
	end
	local top = DY + 2.75
	part(m, "TableTop", Vector3.new(6.4, 0.35, 2.6), at(tx, top, tz), tt.walls, tt.wallMat)
	for _, lx in { -2.8, 2.8 } do
		for _, lz in { -1, 1 } do
			part(m, "TableLeg", Vector3.new(0.35, 2.6, 0.35), at(tx + lx, DY + 1.3, tz + lz), tt.frame, tt.frameMat)
		end
	end
	for _, bz in { -1.9, 1.9 } do
		part(m, "Bench", Vector3.new(6, 0.3, 1), at(tx, DY + 1.6, tz + bz), tt.walls, tt.wallMat)
		for _, lx in { -2.4, 2.4 } do
			part(m, "BenchLeg", Vector3.new(0.35, 1.45, 0.8), at(tx + lx, DY + 0.73, tz + bz), tt.frame, tt.frameMat)
		end
	end
	for _, o in { { -2.2, -0.65 }, { 2.2, -0.65 }, { -2.2, 0.65 }, { 2.2, 0.65 } } do
		local plate = bit(
			"Plate",
			Vector3.new(0.08, 1, 1),
			at(tx + o[1], top + 0.22, tz + o[2]) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(250, 248, 240)
		) :: Part
		plate.Shape = Enum.PartType.Cylinder
	end
	local bowl = bit(
		"FruitBowl",
		Vector3.new(0.35, 1.2, 1.2),
		at(tx, top + 0.3, tz) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(196, 140, 84)
	) :: Part
	bowl.Shape = Enum.PartType.Cylinder
	for k, c in { Color3.fromRGB(240, 150, 60), Color3.fromRGB(150, 210, 80), Color3.fromRGB(230, 70, 70) } do
		local fruit = bit(
			"Fruit",
			Vector3.one * 0.5,
			at(tx - 0.3 + (k - 1) * 0.3, top + 0.62, tz + (k % 2) * 0.2 - 0.1),
			c
		) :: Part
		fruit.Shape = Enum.PartType.Ball
	end
	bit("FlourSack", Vector3.new(0.9, 1.2, 0.8), at(-13, FLOOR + 0.6, 3.5), Color3.fromRGB(240, 232, 210))
	bit("SackTie", Vector3.new(0.5, 0.2, 0.45), at(-13, FLOOR + 1.25, 3.5), Color3.fromRGB(196, 150, 90))
	local bucket = bit(
		"Bucket",
		Vector3.new(0.9, 0.9, 0.9),
		at(-12.7, FLOOR + 0.45, -6.4) * CFrame.Angles(0, 0, math.pi / 2),
		if era >= 3 then Color3.fromRGB(150, 156, 166) else Color3.fromRGB(150, 104, 62),
		if era >= 3 then Enum.Material.Metal else Enum.Material.Wood
	) :: Part
	bucket.Shape = Enum.PartType.Cylinder
	-- the picture board: a dish and a fork drawn on it, its face to the path (left of the entrance, the
	-- grill's slab takes the right at the village scale)
	local board = at(-6, FLOOR + 2.2, -10.8) * CFrame.Angles(0, math.rad(20), 0)
	for _, s in { -1, 1 } do
		part(
			m,
			"EaselLeg",
			Vector3.new(0.2, 2.6, 0.2),
			board * CFrame.new(s * 0.6, -0.95, 0.2) * CFrame.Angles(-0.2, 0, 0),
			tt.frame,
			tt.frameMat
		)
	end
	part(m, "Board", Vector3.new(1.6, 1.3, 0.15), board, Color3.fromRGB(56, 76, 64))
	local dish = bit(
		"BoardDish",
		Vector3.new(0.05, 0.7, 0.7),
		board * CFrame.new(-0.2, 0, -0.1) * CFrame.Angles(0, math.pi / 2, 0),
		Color3.fromRGB(250, 248, 240)
	) :: Part
	dish.Shape = Enum.PartType.Cylinder
	bit("BoardFork", Vector3.new(0.1, 0.8, 0.05), board * CFrame.new(0.45, 0, -0.1), Color3.fromRGB(250, 248, 240))

	-- the cooking story, station by station (ChatGPT's 2nd kitchen review): a bread shelf with loaves
	-- and a flour sack beside the bread oven; a burner with a big pot for the third cook; a bread
	-- basket and a pie on the table; a ladle on the pot rack
	local loafCol = Color3.fromRGB(206, 146, 80)
	if era >= 3 then
		part(m, "BreadShelf", Vector3.new(1.8, 0.2, 1.1), at(4.9, FLOOR + 2.2, 10.7), tt.frame, tt.frameMat)
		for _, lx in { -0.5, 0.5 } do
			part(
				m,
				"ShelfLeg",
				Vector3.new(0.2, 2.2, 0.2),
				at(4.9 + lx * 1.5, FLOOR + 1.1, 10.7),
				tt.frame,
				tt.frameMat
			)
		end
		for k = -1, 1 do
			local loaf =
				bit("Loaf", Vector3.new(0.5, 0.45, 0.8), at(4.9 + k * 0.55, FLOOR + 2.5, 10.7), loafCol) :: Part
			loaf.Shape = Enum.PartType.Ball
		end
		bit("FlourSack", Vector3.new(0.9, 1.2, 0.8), at(4.9, FLOOR + 0.6, 10.7), Color3.fromRGB(240, 232, 210))
	end
	if spots >= 3 then
		part(
			m,
			"Burner",
			Vector3.new(1.3, 1.5, 1.3),
			at(-4.7, FLOOR + 0.75, 4.2),
			Color3.fromRGB(60, 60, 66),
			Enum.Material.Metal
		)
		bit(
			"BurnerFlame",
			Vector3.new(1, 0.12, 1),
			at(-4.7, FLOOR + 1.56, 4.2),
			Color3.fromRGB(255, 140, 60),
			Enum.Material.Neon
		)
		local pot = part(
			m,
			"BigPot",
			Vector3.new(1.2, 1.4, 1.4),
			at(-4.7, FLOOR + 2.2, 4.2) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(196, 112, 64),
			Enum.Material.Metal
		) :: Part
		pot.Shape = Enum.PartType.Cylinder
		local soup = bit(
			"Soup",
			Vector3.new(0.06, 1.2, 1.2),
			at(-4.7, FLOOR + 2.86, 4.2) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(240, 170, 80)
		) :: Part
		soup.Shape = Enum.PartType.Cylinder
	end
	local basket = bit(
		"BreadBasket",
		Vector3.new(1, 0.4, 0.8),
		at(tx - 1.15, top + 0.38, tz),
		Color3.fromRGB(196, 140, 84),
		Enum.Material.Wood
	)
	basket.Name = "BreadBasket"
	for k = -1, 1, 2 do
		local loaf =
			bit("Loaf", Vector3.new(0.45, 0.4, 0.65), at(tx - 1.15 + k * 0.22, top + 0.62, tz), loafCol) :: Part
		loaf.Shape = Enum.PartType.Ball
	end
	local pie = bit(
		"Pie",
		Vector3.new(0.35, 1.2, 1.2),
		at(tx + 1.15, top + 0.35, tz) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(230, 170, 90)
	) :: Part
	pie.Shape = Enum.PartType.Cylinder

	-- outdoor dining on the lawn at the kitchen's left, past the great chimney (the owner, 2026-10-28: the lawn
	-- round an area is there to use), growing each era and never taken away: a picnic blanket, a second one, then
	-- a picnic table under a sunshade. The right side is the cookhouse's own terrace.
	local function picnicTable(x: number, z: number, shade: Color3?)
		part(m, "PicnicTop", Vector3.new(4.8, 0.3, 2), at(x, 2.5, z), tt.walls, tt.wallMat)
		for _, bz in { -1.35, 1.35 } do
			part(m, "PicnicBench", Vector3.new(4.8, 0.25, 0.9), at(x, 1.45, z + bz), tt.walls, tt.wallMat)
		end
		for _, ex in { -1.6, 1.6 } do
			part(m, "PicnicEnd", Vector3.new(0.3, 2.4, 3.4), at(x + ex, 1.2, z), tt.frame, tt.frameMat)
		end
		for _, o in { { -1.1, -0.4 }, { 1.1, 0.4 } } do
			local plate = bit(
				"Plate",
				Vector3.new(0.08, 0.8, 0.8),
				at(x + o[1], 2.6, z + o[2]) * CFrame.Angles(0, 0, math.pi / 2),
				Color3.fromRGB(250, 248, 240)
			) :: Part
			plate.Shape = Enum.PartType.Cylinder
		end
		local jug = bit(
			"Jug",
			Vector3.new(0.5, 0.8, 0.5),
			at(x, 2.95, z),
			Color3.fromRGB(200, 230, 245),
			Enum.Material.Glass
		) :: Part
		jug.Transparency = 0.3
		if shade then
			part(m, "ShadePole", Vector3.new(0.25, 5.6, 0.25), at(x, 2.8, z), tt.frame, tt.frameMat)
			local canopy = part(
				m,
				"Shade",
				Vector3.new(0.35, 4.6, 4.6),
				at(x, 5.6, z) * CFrame.Angles(0, 0, math.pi / 2),
				shade,
				Enum.Material.Fabric
			) :: Part
			canopy.Shape = Enum.PartType.Cylinder
			local shadeTop = part(
				m,
				"ShadeTop",
				Vector3.new(0.5, 1.6, 1.6),
				at(x, 5.95, z) * CFrame.Angles(0, 0, math.pi / 2),
				shade,
				Enum.Material.Fabric
			) :: Part
			shadeTop.Shape = Enum.PartType.Cylinder
		end
	end
	local function blanket(x: number, z: number, a: Color3)
		for qx = -1, 1, 2 do
			for qz = -1, 1, 2 do
				bit(
					"Blanket",
					Vector3.new(1.6, 0.06, 1.6),
					at(x + qx * 0.8, 0.04, z + qz * 0.8),
					if qx == qz then a else Color3.fromRGB(250, 248, 240)
				)
			end
		end
		bit(
			"Basket",
			Vector3.new(1, 0.6, 0.7),
			at(x + 0.6, 0.35, z - 0.5),
			Color3.fromRGB(196, 140, 84),
			Enum.Material.Wood
		)
		bit(
			"BasketHandle",
			Vector3.new(0.9, 0.12, 0.12),
			at(x + 0.6, 0.9, z - 0.5),
			Color3.fromRGB(176, 120, 70),
			Enum.Material.Wood
		)
		local apple = bit("Apple", Vector3.one * 0.45, at(x - 0.5, 0.28, z + 0.4), Color3.fromRGB(230, 70, 70)) :: Part
		apple.Shape = Enum.PartType.Ball
	end
	-- (the village scale: 7 studs of lawn from the pad, clear of the chimney, its oven and its kettles)
	blanket(25, -5, Color3.fromRGB(220, 80, 80))
	if era >= 2 then
		blanket(27, -12, Color3.fromRGB(90, 140, 220))
	end
	if era >= 4 then
		picnicTable(27.5, 4, Color3.fromRGB(250, 236, 200))
	end

	-- the kitchen props
	for j = 1, 4 do
		local e = props[j]
		if e > 0 then
			local slot = SLOT_AT[j]
			local prop = place(m, frame, PROPS[j][e], slot[1], slot[2], HEIGHT[j][e], FOOT[j], FLOOR)
			local yaw = slot[3] + (FRONT_TURN[PROPS[j][e]] or 0)
			if prop and yaw ~= 0 then
				-- turned on the spot, about its own middle
				local box = prop:GetBoundingBox()
				local centre = CFrame.new(box.Position)
				prop:PivotTo(centre * CFrame.Angles(0, math.rad(yaw), 0) * centre:ToObjectSpace(prop:GetPivot()))
			end
		end
	end
	return m
end

return KitchenStages
