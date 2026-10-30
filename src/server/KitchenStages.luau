--!strict
-- The kitchen's 50 levels (the owner, 2026-10-28: "the same as the pantry, the garden and the pen").
-- Five eras of ten levels; in each era:
--   level 1 of the era   the kitchen grows, nothing taken away: era 2 a gable roof on posts over the
--                        cooking line, with hanging lanterns; era 3 a back wall with windows, half
--                        walls at the sides, a brick bread oven and a second cooking spot; era 4 a
--                        chimney stack from the stove through the roof, a pot rack and a third
--                        cooking spot; era 5 a vent lantern on the ridge with a weather vane
--   levels 2-5           four kitchen props, one a level, each slot taking its next, better version:
--                        1 ingredients (veggie crates > pickle barrels > spice cabinet > ice box >
--                        goo fridge)   2 grill (camp grill > stone grill > brick BBQ > steel grill >
--                        plasma grill)   3 water (rain barrel > hand pump > stone sink > steel sink >
--                        goo tap)   4 dishes (dish rack > plate shelf > serving cart > buffet warmer >
--                        food dispenser)
--   levels 6-10          the kitchen's builds move up one material tier, one a level: floor, floor
--                        border, rails and walls, lamps and roof, the entrance arch
-- Tiers and helpers are the pantry's. The kit stove, counter and firewood stay the area's own; the
-- cooking spots keep their markers (CookingSpotN with an Attachment WorkSpotN) for the work rules.
-- Positions are in the kitchen's own frame (x across, z from the front in).
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)
local GateArch = require(script.Parent.GateArch)

local KitchenStages = {}

KitchenStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the pad: x -11 .. 11, z -9 .. 9, the entrance at the front middle; the shelter over z -2.5 .. 9.2
local XW, ZF, ZB = 10.8, -2.5, 9.2
-- (eaves low enough that the camera sees the cooking line under them, still well over a player)
local EAVE, RISE = 7.6, 4.4 -- eave height, ridge above the eaves
local FLOOR = 0.4 -- the pad's floor stands this far above the lawn; props stand on its top

-- cooking spots: where, and from which level (the first is the area's own)
local SPOTS = { { 0, -1.2, 1 }, { 5.6, 1.4, 21 }, { -6, 0.9, 31 } }

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
local SLOT_AT = { { -9.5, 0.7, -90 }, { 7.6, -6.2, 90 }, { -9.5, -2.4, -90 }, { 9.5, -1.4, 90 } }
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

-- A low rail run (eras 1-2) along a side or the back: posts every three studs and two rails.
local function railRun(m: Model, frame: CFrame, x0: number, z0: number, x1: number, z1: number, t: any)
	local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local n = math.max(1, math.round(len / 3))
	for k = 0, n do
		local p = a + dir * (len * k / n)
		part(m, "RailPost", Vector3.new(0.6, 3, 0.6), frame * CFrame.new(p.X, 1.5, p.Z), t.frame, t.frameMat)
	end
	local mid = (a + b) / 2
	for _, y in { 1.2, 2.6 } do
		part(
			m,
			"Rail",
			Vector3.new(0.3, 0.4, len),
			frame * CFrame.new(mid.X, y, mid.Z) * CFrame.lookAt(Vector3.zero, dir),
			t.walls,
			t.wallMat
		)
	end
end

-- The kitchen's layer for a level. `area` is the kitchen model: its floor and border take their
-- tiers, its firewood moves aside when the bread oven comes.
function KitchenStages.build(area: Instance, frame: CFrame, level: number): Model
	local era, spots, props, tiers = KitchenStages.state(level)
	local tw, tl, ta = TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
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
			local x, z = if era >= 3 then 9 else 6.5, if era >= 3 then 1.6 else 3
			d:PivotTo(d:GetPivot() + (at(x, size.Y / 2, z).Position - d:GetBoundingBox().Position))
		end
	end

	-- 3 rails, then walls: the back and both sides
	if era < 3 then
		railRun(m, frame, -XW, ZB, XW, ZB, tw)
		railRun(m, frame, -XW, -5, -XW, ZB, tw)
		railRun(m, frame, XW, -5, XW, ZB, tw)
	else
		local h = EAVE
		part(m, "WallBack", Vector3.new(XW * 2, h, 0.6), at(0, h / 2, ZB), tw.walls, tw.wallMat)
		for _, wx in { -4.7, 4.4 } do -- either side of the stove, clear of the bread oven
			part(m, "WindowFrame", Vector3.new(2.6, 2.2, 0.3), at(wx, 6, ZB - 0.35), tw.trim, tw.trimMat)
			part(m, "Window", Vector3.new(2, 1.6, 0.32), at(wx, 6, ZB - 0.36), tw.glass, Enum.Material.Neon).CastShadow =
				false
		end
		for _, s in { -1, 1 } do
			local len = ZB - ZF
			part(m, "HalfWall", Vector3.new(0.6, 3.4, len), at(s * XW, 1.7, (ZF + ZB) / 2), tw.walls, tw.wallMat)
			part(m, "WallCap", Vector3.new(0.9, 0.3, len + 0.3), at(s * XW, 3.55, (ZF + ZB) / 2), tw.trim, tw.trimMat)
		end
	end

	-- 4 lamps at the front corners (and, from era 2, the roof on its posts)
	for _, s in { -1, 1 } do
		part(m, "LampPost", Vector3.new(0.5, 5, 0.5), at(s * 10.4, 2.5, -8.4), tl.frame, tl.frameMat)
		glow(m, "Lamp", Vector3.new(0.9, 0.9, 0.9), at(s * 10.4, 5.4, -8.4), tl.glass, 10)
	end
	if era >= 2 then
		for _, s in { -1, 1 } do
			for _, z in { ZF, ZB } do
				part(m, "RoofPost", Vector3.new(0.8, EAVE, 0.8), at(s * XW, EAVE / 2, z), tl.frame, tl.frameMat)
			end
			part(
				m,
				"EaveBeam",
				Vector3.new(0.6, 0.6, ZB - ZF + 0.8),
				at(s * XW, EAVE - 0.3, (ZF + ZB) / 2),
				tl.frame,
				tl.frameMat
			)
			-- lanterns hanging under the roof
			part(m, "LanternChain", Vector3.new(0.12, 1.6, 0.12), at(s * 6, EAVE + 0.4, 3.4), tl.frame, tl.frameMat)
			glow(m, "Lantern", Vector3.new(0.8, 1, 0.8), at(s * 6, EAVE - 0.9, 3.4), tl.glass, 12)
		end
		for _, z in { ZF, ZB } do
			part(m, "PlateBeam", Vector3.new(XW * 2 + 0.8, 0.6, 0.6), at(0, EAVE - 0.3, z), tl.frame, tl.frameMat)
		end
		-- the gable roof, its ridge running front to back so the front is an open truss the camera
		-- looks in through (ChatGPT's 1st kitchen review: a slope to the front hid the whole kitchen);
		-- a light fascia on the slopes' front edges, a ridge cap, a king post; the back gable closed
		-- once the back wall stands
		local zc = (ZF + ZB) / 2
		local reach = XW + 0.8
		-- (on slime tech the trim glows: the roof edges keep the frame colour so the kitchen is not lit
		-- cyan all over; ChatGPT's 1st kitchen review)
		local edge, edgeMat = tl.trim, tl.trimMat
		if edgeMat == Enum.Material.Neon then
			edge, edgeMat = tl.frame, tl.frameMat
		end
		local pitch = math.atan2(RISE, XW)
		local slope = reach / math.cos(pitch)
		for _, sx in { -1, 1 } do
			local slab = at(sx * reach / 2, EAVE + RISE - reach * math.tan(pitch) / 2 + 0.2, zc)
				* CFrame.Angles(0, 0, -sx * pitch)
			part(m, "Roof", Vector3.new(slope, 0.45, ZB - ZF + 1.4), slab, tl.roof, tl.roofMat)
			part(
				m,
				"Fascia",
				Vector3.new(slope, 0.5, 0.35),
				slab * CFrame.new(0, 0, -(ZB - ZF + 1.4) / 2),
				edge,
				edgeMat
			)
			if era >= 3 then
				-- (a wedge's tall face is its +Z; turned so it rises toward the ridge)
				wedge(
					m,
					"BackGable",
					Vector3.new(0.3, RISE, XW),
					at(sx * XW / 2, EAVE + RISE / 2, ZB) * CFrame.Angles(0, -sx * math.pi / 2, 0),
					tw.walls,
					tw.wallMat
				)
			end
		end
		part(m, "Ridge", Vector3.new(0.6, 0.5, ZB - ZF + 1.6), at(0, EAVE + RISE + 0.25, zc), edge, edgeMat)
		part(m, "KingPost", Vector3.new(0.45, RISE, 0.45), at(0, EAVE + RISE / 2, ZF), tl.frame, tl.frameMat)
	end

	-- era 3: the bread oven at the back right
	if era >= 3 then
		place(m, frame, "BrickOven", 7.2, 6.2, 6, 4.6, FLOOR)
	end
	-- era 4: a chimney stack from the stove's own chimney up through the roof, and a pot rack
	if era >= 4 then
		part(m, "Chimney", Vector3.new(1.8, 6, 1.8), at(2.3, 10.9, 5.9), tw.walls, tw.wallMat)
		part(m, "ChimneyTop", Vector3.new(2.3, 0.5, 2.3), at(2.3, 14.1, 5.9), tw.trim, tw.trimMat)
		part(m, "PotRack", Vector3.new(4.6, 0.3, 0.3), at(-7, EAVE - 1.4, 3.6), tl.frame, tl.frameMat)
		for k, dx in { -1.6, 0, 1.6 } do
			part(m, "RackChain", Vector3.new(0.1, 1.9, 0.1), at(-7 + dx * 1.3, EAVE - 0.4, 3.6), tl.frame, tl.frameMat)
			local pot = part(
				m,
				"HangingPot",
				Vector3.new(0.9, 0.5 + k * 0.15, 0.9),
				at(-7 + dx, EAVE - 2, 3.6) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(196, 112, 64),
				Enum.Material.Metal
			) :: Part
			pot.Shape = Enum.PartType.Cylinder
		end
	end
	-- era 5: a vent lantern on the ridge with a pan weather vane
	if era >= 5 then
		local ry, zc = EAVE + RISE, (ZF + ZB) / 2
		part(m, "VentBase", Vector3.new(3, 1.6, 5), at(0, ry + 0.8, zc), tw.walls, tw.wallMat)
		part(m, "VentGlass", Vector3.new(2.4, 1, 4.2), at(0, ry + 2.1, zc), tw.glass, Enum.Material.Neon).CastShadow =
			false
		for _, s in { -1, 1 } do
			part(
				m,
				"VentRoof",
				Vector3.new(1.9, 0.3, 5.6),
				at(s * 0.8, ry + 2.85, zc) * CFrame.Angles(0, 0, -s * 0.5),
				tl.roof,
				tl.roofMat
			)
		end
		part(m, "VaneRod", Vector3.new(0.15, 2.2, 0.15), at(0, ry + 4, zc), ta.trim, ta.trimMat)
		local pan = part(
			m,
			"VanePan",
			Vector3.new(0.2, 1.3, 1.3),
			at(-0.5, ry + 4.6, zc) * CFrame.Angles(0, math.rad(90), 0),
			ta.trim,
			ta.trimMat
		) :: Part
		pan.Shape = Enum.PartType.Cylinder
		part(m, "VaneHandle", Vector3.new(1.2, 0.2, 0.2), at(0.6, ry + 4.6, zc), ta.trim, ta.trimMat)
	end

	-- 5 the entrance arch (GateArch): warm orange, the chef's hat emblem on top
	GateArch.build(m, frame, 0, 6, -9.2, tiers[5], Color3.fromRGB(240, 150, 60), "EmblemKitchen")

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
	-- the dining table, out on the lawn beside the kitchen's right as a big outdoor table on its own
	-- deck (the owner, 2026-10-28: bigger, and outside), the grill on its heatproof slab in the yard
	local tx, tz, DY = -17.5, -6.6, 0.12
	part(
		m,
		"DiningDeck",
		Vector3.new(8.4, 0.12, 6.6),
		at(tx, 0.06, tz),
		Color3.fromRGB(214, 176, 124),
		Enum.Material.WoodPlanks
	)
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
		part(m, "Hearth", Vector3.new(8, 0.06, 5.4), at(0, FLOOR + 0.03, -0.5), TIERS[3].walls, TIERS[3].wallMat)
	end
	if era >= 3 then
		-- a bread peel against the side wall by the oven, a loaf on its paddle
		part(
			m,
			"PeelHandle",
			Vector3.new(0.15, 3.2, 0.15),
			at(10.2, FLOOR + 2.2, 8.2) * CFrame.Angles(0, 0, 0.18),
			Color3.fromRGB(176, 128, 84),
			Enum.Material.Wood
		)
		part(
			m,
			"PeelPaddle",
			Vector3.new(0.12, 1.1, 1),
			at(10.4, FLOOR + 0.6, 8.2) * CFrame.Angles(0, 0, 0.18),
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
	if era >= 2 then
		for k, hx in { -8.2, -7.3, -6.4 } do
			bit("HerbString", Vector3.new(0.08, 0.8, 0.08), at(hx, EAVE - 1, ZF + 0.2), Color3.fromRGB(226, 196, 140))
			bit(
				"HerbBundle",
				Vector3.new(0.45, 0.85, 0.45),
				at(hx, EAVE - 1.8, ZF + 0.2),
				if k == 2 then Color3.fromRGB(240, 236, 220) else Color3.fromRGB(110, 170, 80)
			)
		end
	end
	bit("FlourSack", Vector3.new(0.9, 1.2, 0.8), at(-10, FLOOR + 0.6, 2.7), Color3.fromRGB(240, 232, 210))
	bit("SackTie", Vector3.new(0.5, 0.2, 0.45), at(-10, FLOOR + 1.25, 2.7), Color3.fromRGB(196, 150, 90))
	local bucket = bit(
		"Bucket",
		Vector3.new(0.9, 0.9, 0.9),
		at(-9.8, FLOOR + 0.45, -4.4) * CFrame.Angles(0, 0, math.pi / 2),
		if era >= 3 then Color3.fromRGB(150, 156, 166) else Color3.fromRGB(150, 104, 62),
		if era >= 3 then Enum.Material.Metal else Enum.Material.Wood
	) :: Part
	bucket.Shape = Enum.PartType.Cylinder
	-- the picture board: a dish and a fork drawn on it, its face to the path
	local board = at(4.3, FLOOR + 2.2, -8.3) * CFrame.Angles(0, math.rad(-20), 0)
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
		part(m, "BreadShelf", Vector3.new(1.8, 0.2, 1.1), at(3.8, FLOOR + 2.2, 8.2), tt.frame, tt.frameMat)
		for _, lx in { -0.5, 0.5 } do
			part(m, "ShelfLeg", Vector3.new(0.2, 2.2, 0.2), at(3.8 + lx * 1.5, FLOOR + 1.1, 8.2), tt.frame, tt.frameMat)
		end
		for k = -1, 1 do
			local loaf = bit("Loaf", Vector3.new(0.5, 0.45, 0.8), at(3.8 + k * 0.55, FLOOR + 2.5, 8.2), loafCol) :: Part
			loaf.Shape = Enum.PartType.Ball
		end
		bit("FlourSack", Vector3.new(0.9, 1.2, 0.8), at(3.8, FLOOR + 0.6, 8.2), Color3.fromRGB(240, 232, 210))
	end
	if spots >= 3 then
		part(
			m,
			"Burner",
			Vector3.new(1.3, 1.5, 1.3),
			at(-3.6, FLOOR + 0.75, 3.2),
			Color3.fromRGB(60, 60, 66),
			Enum.Material.Metal
		)
		bit(
			"BurnerFlame",
			Vector3.new(1, 0.12, 1),
			at(-3.6, FLOOR + 1.56, 3.2),
			Color3.fromRGB(255, 140, 60),
			Enum.Material.Neon
		)
		local pot = part(
			m,
			"BigPot",
			Vector3.new(1.2, 1.4, 1.4),
			at(-3.6, FLOOR + 2.2, 3.2) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(196, 112, 64),
			Enum.Material.Metal
		) :: Part
		pot.Shape = Enum.PartType.Cylinder
		local soup = bit(
			"Soup",
			Vector3.new(0.06, 1.2, 1.2),
			at(-3.6, FLOOR + 2.86, 3.2) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(240, 170, 80)
		) :: Part
		soup.Shape = Enum.PartType.Cylinder
		bit(
			"Ladle",
			Vector3.new(0.12, 1.6, 0.12),
			at(-7, EAVE - 2.3, 4.2),
			Color3.fromRGB(150, 156, 166),
			Enum.Material.Metal
		)
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

	-- one construction signature per era (ChatGPT's 2nd kitchen review): brick plinths at the posts,
	-- metal seams on the steel roof, a goo pipe from the vent down the back corner
	if era == 3 then
		for _, sx in { -1, 1 } do
			for _, z in { ZF, ZB } do
				part(
					m,
					"Plinth",
					Vector3.new(1.5, 1.3, 1.5),
					at(sx * XW, FLOOR + 0.65, z),
					TIERS[3].walls,
					TIERS[3].wallMat
				)
				part(
					m,
					"PlinthCap",
					Vector3.new(1.7, 0.2, 1.7),
					at(sx * XW, FLOOR + 1.4, z),
					TIERS[3].base,
					TIERS[3].baseMat
				)
			end
		end
	elseif era == 4 then
		local pitch = math.atan2(RISE, XW)
		local reach = XW + 0.8
		for _, sx in { -1, 1 } do
			local slab = at(sx * reach / 2, EAVE + RISE - reach * math.tan(pitch) / 2 + 0.2, (ZF + ZB) / 2)
				* CFrame.Angles(0, 0, -sx * pitch)
			for _, dz in { -4, 0, 4 } do
				part(
					m,
					"RoofSeam",
					Vector3.new(reach / math.cos(pitch), 0.14, 0.3),
					slab * CFrame.new(0, 0.28, dz),
					Color3.fromRGB(150, 158, 170),
					Enum.Material.Metal
				)
			end
		end
	elseif era == 5 then
		local mint = Color3.fromRGB(120, 230, 200)
		part(
			m,
			"GooPipe",
			Vector3.new(0.55, EAVE - 0.8, 0.55),
			at(-10.1, FLOOR + (EAVE - 0.8) / 2, 8.3),
			Color3.fromRGB(70, 150, 140),
			Enum.Material.Metal
		)
		part(
			m,
			"GooPipe",
			Vector3.new(10.1, 0.55, 0.55),
			at(-5.05, EAVE - 0.8, 8.3),
			Color3.fromRGB(70, 150, 140),
			Enum.Material.Metal
		)
		for _, y in { 1.6, 4.2 } do
			bit("PipeRing", Vector3.new(0.7, 0.18, 0.7), at(-10.1, FLOOR + y, 8.3), mint, Enum.Material.Neon)
		end
	end

	-- outdoor dining on the lawn round the kitchen (the owner, 2026-10-28: the lawn round an area is
	-- there to use; picnic and outdoor tables), growing each era and never taken away: on the right
	-- (by the dining nook) a picnic blanket, then picnic tables with sunshades, string lights, and a
	-- deck under them on slime tech; on the left (by the grill) a blanket and a table later on
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
	local red, pinkShade, cream =
		Color3.fromRGB(220, 80, 80), Color3.fromRGB(240, 150, 180), Color3.fromRGB(250, 236, 200)
	blanket(23, -5, red) -- (the village scale: the picnic ground 4 studs farther from the kitchen)
	if era >= 2 then
		picnicTable(-19.2, -0.8)
		blanket(25, -10, Color3.fromRGB(90, 140, 220))
	end
	if era >= 3 then
		picnicTable(-25, -0.8, pinkShade)
	end
	if era >= 4 then
		picnicTable(24, 1.2, cream)
		-- string lights over the right-hand tables
		local corners =
			{ Vector3.new(-17, 0, -3.8), Vector3.new(-27, 0, -3.8), Vector3.new(-27, 0, 2.6), Vector3.new(-17, 0, 2.6) }
		for _, c in corners do
			part(m, "LightPost", Vector3.new(0.3, 6, 0.3), at(c.X, 3, c.Z), tt.frame, tt.frameMat)
		end
		for k = 1, 4 do
			local a, b = corners[k], corners[k % 4 + 1]
			local mid = (a + b) / 2
			bit(
				"LightLine",
				Vector3.new(0.06, 0.06, (b - a).Magnitude),
				at(mid.X, 5.7, mid.Z) * CFrame.lookAt(Vector3.zero, (b - a).Unit),
				Color3.fromRGB(60, 60, 66)
			)
			for t = 1, 3 do
				local p = a + (b - a) * (t / 4)
				local bulb = bit(
					"Bulb",
					Vector3.one * 0.3,
					at(p.X, 5.55, p.Z),
					Color3.fromRGB(255, 220, 140),
					Enum.Material.Neon
				) :: Part
				bulb.Shape = Enum.PartType.Ball
			end
		end
	end
	if era >= 5 then
		part(
			m,
			"PicnicDeck",
			Vector3.new(10, 0.12, 6.4),
			at(-22, 0.06, -0.6),
			Color3.fromRGB(214, 176, 124),
			Enum.Material.WoodPlanks
		)
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
