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

local KitchenStages = {}

KitchenStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the pad: x -11 .. 11, z -9 .. 9, the entrance at the front middle; the shelter over z -2.5 .. 9.2
local XW, ZF, ZB = 10.8, -2.5, 9.2
local EAVE, RISE = 9.6, 3.4 -- eave height, ridge above the eaves

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
	{ 2.6, 3.2, 4.2, 3.8, 3.8 },
	{ 3, 4.4, 3.2, 3.4, 4.2 },
	{ 3, 4.8, 3.4, 3.4, 5 },
}
-- where each slot stands and which way it faces (degrees; 0 to the front, 90 to -x, -90 to +x): the
-- ingredients and the water against the left wall in front of the counter, the dishes against the
-- right wall, all facing in; the grill out in the front yard, turned to the path
local SLOT_AT = { { -9.5, 0.7, -90 }, { 7.6, -6.2, 90 }, { -9.5, -2.4, -90 }, { 9.5, -1.4, 90 } }
local FOOT = { 2.8, 3.6, 2.6, 2.6 }
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
		-- the gable roof, its ridge along x
		local zc, half = (ZF + ZB) / 2, (ZB - ZF) / 2 + 0.8
		wedge(
			m,
			"RoofFront",
			Vector3.new(XW * 2 + 1.6, RISE, half),
			at(0, EAVE + RISE / 2, zc - half / 2),
			tl.roof,
			tl.roofMat
		)
		wedge(
			m,
			"RoofBack",
			Vector3.new(XW * 2 + 1.6, RISE, half),
			at(0, EAVE + RISE / 2, zc + half / 2) * CFrame.Angles(0, math.pi, 0),
			tl.roof,
			tl.roofMat
		)
		part(m, "Ridge", Vector3.new(XW * 2 + 1.8, 0.4, 0.6), at(0, EAVE + RISE + 0.1, zc), tl.frame, tl.frameMat)
	end

	-- era 3: the bread oven at the back right
	if era >= 3 then
		place(m, frame, "BrickOven", 7.2, 6.2, 6, 4.6)
	end
	-- era 4: a chimney stack from the stove's own chimney up through the roof, and a pot rack
	if era >= 4 then
		part(m, "Chimney", Vector3.new(1.8, 7, 1.8), at(2.3, 11.4, 5.9), tw.walls, tw.wallMat)
		part(m, "ChimneyTop", Vector3.new(2.3, 0.5, 2.3), at(2.3, 15.1, 5.9), tw.trim, tw.trimMat)
		part(m, "PotRack", Vector3.new(4.6, 0.3, 0.3), at(-7, 7.2, 3.6), tl.frame, tl.frameMat)
		for k, dx in { -1.6, 0, 1.6 } do
			part(m, "RackChain", Vector3.new(0.1, 1.9, 0.1), at(-7 + dx * 1.3, 8.3, 3.6), tl.frame, tl.frameMat)
			local pot = part(
				m,
				"HangingPot",
				Vector3.new(0.9, 0.5 + k * 0.15, 0.9),
				at(-7 + dx, 6.6, 3.6) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(196, 112, 64),
				Enum.Material.Metal
			) :: Part
			pot.Shape = Enum.PartType.Cylinder
		end
	end
	-- era 5: a vent lantern on the ridge with a pan weather vane
	if era >= 5 then
		local ry, zc = EAVE + RISE, (ZF + ZB) / 2
		part(m, "VentBase", Vector3.new(5, 2, 3), at(0, ry + 0.8, zc), tw.walls, tw.wallMat)
		part(m, "VentGlass", Vector3.new(4.2, 1.2, 2.4), at(0, ry + 2.3, zc), tw.glass, Enum.Material.Neon).CastShadow =
			false
		for _, s in { -1, 1 } do
			wedge(
				m,
				"VentRoof",
				Vector3.new(5.6, 1.2, 1.8),
				at(0, ry + 3.5, zc - s * 0.9) * CFrame.Angles(0, if s == 1 then 0 else math.pi, 0),
				tl.roof,
				tl.roofMat
			)
		end
		part(m, "VaneRod", Vector3.new(0.15, 2.2, 0.15), at(0, ry + 5.2, zc), ta.trim, ta.trimMat)
		local pan = part(
			m,
			"VanePan",
			Vector3.new(0.2, 1.3, 1.3),
			at(-0.5, ry + 5.8, zc) * CFrame.Angles(0, math.rad(90), 0),
			ta.trim,
			ta.trimMat
		) :: Part
		pan.Shape = Enum.PartType.Cylinder
		part(m, "VaneHandle", Vector3.new(1.2, 0.2, 0.2), at(0.6, ry + 5.8, zc), ta.trim, ta.trimMat)
	end

	-- 5 the entrance arch: two posts, a board and a frying pan
	for _, x in { -3, 3 } do
		part(m, "ArchPost", Vector3.new(0.8, 6.4, 0.8), at(x, 3.2, -9.2), ta.frame, ta.frameMat)
	end
	part(m, "ArchBoard", Vector3.new(7.6, 0.8, 0.5), at(0, 6, -9.2), ta.walls, ta.wallMat)
	-- the pan stands on the board, its face to the front
	local pan = part(
		m,
		"ArchPan",
		Vector3.new(0.3, 1.5, 1.5),
		at(-0.35, 7.2, -9.2) * CFrame.Angles(0, math.rad(90), 0),
		Color3.fromRGB(60, 60, 66),
		Enum.Material.Metal
	) :: Part
	pan.Shape = Enum.PartType.Cylinder
	part(
		m,
		"ArchPanHandle",
		Vector3.new(1.3, 0.3, 0.25),
		at(1.05, 7.2, -9.2),
		Color3.fromRGB(150, 96, 56),
		Enum.Material.Wood
	)

	-- the cooking spots beyond the area's own: a straw mat each, with its marker
	for i = 2, spots do
		local p = SPOTS[i]
		local mat = part(
			m,
			"CookingSpot" .. i,
			Vector3.new(0.1, 3.6, 3.6),
			at(p[1], 0.45, p[2]) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(226, 190, 120),
			Enum.Material.Fabric
		) :: Part
		mat.Shape = Enum.PartType.Cylinder
		mat.CanCollide = false
		local mark = Instance.new("Attachment")
		mark.Name = "WorkSpot" .. i
		mark.Parent = mat
	end

	-- the kitchen props
	for j = 1, 4 do
		local e = props[j]
		if e > 0 then
			local slot = SLOT_AT[j]
			local prop = place(m, frame, PROPS[j][e], slot[1], slot[2], HEIGHT[j][e], FOOT[j])
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
