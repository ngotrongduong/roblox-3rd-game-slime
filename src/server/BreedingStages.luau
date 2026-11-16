--!strict
-- The breeding pen's 50 levels (the owner, 2026-10-28: "the same as the pantry and the garden"). Five
-- eras of ten levels; in each era:
--   level 1 of the era   the Breeding House, its fence and gate, the pen floor, the nest platforms, the incubators
--                        and their pad take the era's material, and a nest or an incubator is added (a 3rd nest at
--                        11, a 3rd incubator at 21, a 4th nest at 31, a 4th incubator at 41)
--   levels 2-5           four care props, one a level, each slot taking its next, better version:
--                        1 feed (bucket > hay feeder > grain feeder > auto feeder > goo feeder)
--                        2 egg care (basket > crate > egg cart > egg scanner > egg pod)
--                        3 comfort (straw pile > cushions > trampoline > slime bed > cloud bed)
--                        4 warmth (oil lamp > heat lamp > warming stove > monitor > holo beacon)
--   levels 6-10          one feature of the Breeding House a level (server/BreedingHouse, the landmark of 2026-11-17:
--                        docs/areas/village-v2/breeding-ladder.md)
-- The hall, its warm room, the egg on its roof, the fence and the gate are BreedingHouse's; this module keeps the
-- pen's own: the floor, the nests, the incubators, the lane, the two working corners and the care props.
-- Tiers and helpers are the pantry's: the stud look, a tier in its colours, every prop at its real
-- height (the player is 5 studs). Nests and incubators keep their invisible markers (NestHollowN with
-- an Attachment NestN, IncBedN with IncubatorN) for the breeding rules. Positions are in the pen's
-- own frame (x across, z from the gate in).
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)
local BreedingHouse = require(script.Parent.BreedingHouse)

local BreedingStages = {}

BreedingStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the pen: x -17 .. 25, z -19 .. 19, the gate x 0 .. 8 at the front (the village scale, 2026-10-30: the pen
-- was 30 x 26 and slimes got stuck between the nests, the trough and the fence; it is now 42 x 38, about twice
-- the floor, with 6+ studs (WorkFront) round every nest and between the nests and the fence; models keep their
-- size, docs/VILLAGE_SCALE.md)
-- (the Breeding House, 2026-11-17: the yard still ends at z 19; the hall, its warm room and its right wing stand in
-- the strip behind it, to the back fence at z 30, BreedingHouse.fence)
local X0, X1, Z0, Z1 = -17, 25, -19, 19
local BX = 4 -- the lane's middle line, from the gate's middle to the hall's door
-- an era's material tier (PantryStages.Tiers) for the floor, the nest platforms and the incubators' pad, and the
-- incubators' own style (steel with screens at the slime-tech era, as the reference sheet draws them)
local ERA_TIER = { 1, 2, 3, 5, 6 }
local INC_TIER = { 1, 2, 3, 4, 6 }

-- nests and incubators: where, and from which level
-- (in two neat rows either side of the lane from the gate: the area's own two in front of the
-- shelter, the 3rd and 4th straight in front of them; the owner, 2026-10-28: "put it in order")
-- (the first two of each match tools/map/build_breeding_l1, which lays their markers)
local NESTS = { { -8, 1.5, 1 }, { 16, 1.5, 1 }, { -8, -10.5, 11 }, { 16, -10.5, 31 } }
local INC_X = X0 - 8 -- the incubators' line, outside the right fence
local INCUBATORS = { { INC_X, -4.5, 1 }, { INC_X, 7.5, 1 }, { INC_X, -16.5, 21 }, { INC_X, 19.5, 41 } }
local INC_PAD_EXT = 10 -- the depth of the pad piece added under the 3rd and 4th

local PROPS = {
	{ "FeedBucket", "HayFeeder", "GrainFeeder", "AutoFeeder", "GooFeeder" },
	{ "EggBasket", "EggCrate", "EggCart", "EggScanner", "EggPod" },
	{ "StrawPile", "CushionPile", "Trampoline", "SlimeBed", "CloudBed" },
	{ "OilLamp", "HeatLamp", "WarmingStove", "MonitorStation", "HoloBeacon" },
}
-- real heights (studs, the player is 5)
local HEIGHT = {
	{ 1.6, 3.4, 3.6, 4, 3.8 },
	{ 1.4, 1.8, 2.6, 3.4, 3.4 },
	{ 1.6, 1.8, 1.4, 2.6, 2 }, -- (the slime bed big enough to read as a bed)
	{ 4.6, 5.2, 4.4, 4.4, 4.6 },
}
-- The pen in order (the owner, 2026-10-28: the props stood about with no order): a paved lane from
-- the gate to the shelter; the nests in two rows either side of it; the two back corners beside the
-- shelter are its working corners, each on its own mat. +x is the pen's left as one walks in, the
-- incubators stand outside its right fence.
--   feed     back-left, the feed and rest corner, beside the hay store
--   egg care back-right, the water and egg corner, just inside the side gate to the incubators
--   comfort  back-left at the front of the straw mat, facing the nests (the hay store and the
--            feeder behind it against the back fence; ChatGPT's 3rd breeding review)
--   warmth   against the right fence between the two right-hand nests, warming them (a flower box
--            stands in the same place between the left-hand nests)
local SLOT_AT = { { 23, 13.5 }, { -14, 7.5 }, { 18.5, 10 }, { -14.5, -5.5 } }
local FOOT = { 2.6, 3, 3.6, 2.2 }
local HAY = Vector3.new(19.5, 0, 17.2) -- the hay store, against the back fence
local LIFT = { [3] = { [5] = 1 } } -- the cloud bed floats
local FLOOR = 0.4 -- the pen's floor stands this far above the lawn; what is on it stands on its top
-- the side gate in the right fence, toward the incubators
local SIDE0, SIDE1 = -1.5, 3.5

-- What a level holds: the era, how many nests and incubators, each prop slot's era (0: none).
function BreedingStages.state(level: number): (number, number, number, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local nests, incubators = 0, 0
	for _, n in NESTS do
		nests += if level >= n[3] then 1 else 0
	end
	for _, n in INCUBATORS do
		incubators += if level >= n[3] then 1 else 0
	end
	local props = {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	return era, nests, incubators, props
end

function BreedingStages.tierName(level: number): string
	local era = BreedingStages.state(level)
	return TIERS[ERA_TIER[era]].name
end

-- A part of the area itself takes a tier's colour; at tier 1 it keeps the look it was built with.
local function skin(p: BasePart, tier: number, colour: Color3, material: Enum.Material)
	if p:GetAttribute("BuiltColor") == nil then
		p:SetAttribute("BuiltColor", p.Color)
	end
	if tier <= 1 then
		p.Color = p:GetAttribute("BuiltColor") :: Color3
	else
		p.Color = colour
	end
	PondStages.studLook(p, material)
end

-- An incubator standing on `base` (its foot, front to -Z), in the style of the pad's tier (the owner,
-- 2026-10-28: "design the incubator carefully and in detail"): a foot ring on four little feet, a
-- round body with ribs and bands, a front panel (a lit porthole, a dial with its needle, two buttons, a
-- vent grille), a straw bed at the height an egg is set (IncBedN, y 2.8 above the foot), a clear glass
-- dome held by four curved ribs so the egg shows, a lamp cap with a handle on top, and a cable to the
-- pad behind. Wood with brass bands, cream enamel and pink, riveted copper, brushed steel with a
-- screen and blue lights, slime tech with glowing rings, marble with gold.
local INC_STYLE = {
	-- body, ribs and bands, the accent band, fittings, the glow
	{
		Color3.fromRGB(150, 98, 56),
		Color3.fromRGB(196, 156, 72),
		Color3.fromRGB(196, 156, 72),
		Color3.fromRGB(196, 156, 72),
		Color3.fromRGB(255, 196, 120),
	},
	{
		Color3.fromRGB(255, 244, 228),
		Color3.fromRGB(250, 226, 212),
		Color3.fromRGB(240, 132, 168),
		Color3.fromRGB(214, 214, 220),
		Color3.fromRGB(255, 200, 130),
	},
	{
		Color3.fromRGB(196, 110, 70),
		Color3.fromRGB(150, 76, 46),
		Color3.fromRGB(226, 182, 90),
		Color3.fromRGB(226, 182, 90),
		Color3.fromRGB(255, 176, 100),
	},
	{
		Color3.fromRGB(204, 210, 218),
		Color3.fromRGB(120, 128, 140),
		Color3.fromRGB(90, 170, 240),
		Color3.fromRGB(150, 156, 166),
		Color3.fromRGB(150, 210, 255),
	},
	{
		Color3.fromRGB(236, 246, 242),
		Color3.fromRGB(60, 120, 120),
		Color3.fromRGB(120, 255, 180),
		Color3.fromRGB(70, 150, 150),
		Color3.fromRGB(120, 255, 180),
	},
	{
		Color3.fromRGB(246, 243, 236),
		Color3.fromRGB(232, 190, 80),
		Color3.fromRGB(232, 190, 80),
		Color3.fromRGB(232, 190, 80),
		Color3.fromRGB(255, 226, 160),
	},
}
local INC_MAT = {
	Enum.Material.Wood,
	Enum.Material.SmoothPlastic,
	Enum.Material.Metal,
	Enum.Material.Metal,
	Enum.Material.SmoothPlastic,
	Enum.Material.Marble,
}
local function incubator(m: Model, base: CFrame, tier: number)
	local i = math.clamp(tier, 1, #INC_STYLE)
	local st = INC_STYLE[i]
	local body, rib, band, metal, glowC = st[1], st[2], st[3], st[4], st[5]
	local bodyMat = INC_MAT[i]
	local metalMat = if tier == 2 or tier == 5 then Enum.Material.SmoothPlastic else Enum.Material.Metal
	local function drum(name: string, y: number, h: number, d: number, colour: Color3, material: Enum.Material?): Part
		local p = part(
			m,
			name,
			Vector3.new(h, d, d),
			base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
			colour,
			material
		) :: Part
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	local function bit(name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?): Part
		local p = part(m, name, size, cf, colour, material or Enum.Material.SmoothPlastic) :: Part
		p.CanCollide = false
		p.CastShadow = false
		return p
	end
	local face = CFrame.Angles(0, math.rad(90), 0) -- (a disc facing the front)
	-- the foot: a ring on four little feet
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		bit(
			"IncFoot",
			Vector3.one * 0.55,
			base * CFrame.new(math.cos(a) * 1.55, 0.22, math.sin(a) * 1.55),
			metal,
			metalMat
		).Shape =
			Enum.PartType.Ball
	end
	drum("IncFootRing", 0.42, 0.36, 3.9, rib, metalMat)
	-- the body with its bands and ribs
	drum("IncBody", 1.5, 1.8, 3.6, body, bodyMat)
	drum("IncBandLow", 0.75, 0.22, 3.72, rib, metalMat)
	drum("IncBand", 2.45, 0.4, 3.9, band, if tier == 5 then Enum.Material.Neon else metalMat)
	for k = 0, 7 do
		local a = k * math.pi / 4 + math.pi / 8
		bit(
			"IncRib",
			Vector3.new(0.18, 1.5, 0.22),
			base * CFrame.new(math.sin(a) * 1.8, 1.5, math.cos(a) * 1.8) * CFrame.Angles(0, a, 0),
			rib,
			metalMat
		)
		if tier == 3 then -- (rivets on the copper body)
			bit(
				"IncRivet",
				Vector3.one * 0.14,
				base * CFrame.new(math.sin(a) * 1.86, 2.1, math.cos(a) * 1.86),
				metal,
				metalMat
			).Shape =
				Enum.PartType.Ball
		end
	end
	-- the front panel: a lit porthole, a dial (a screen on steel), two buttons, a vent grille
	local front = base * CFrame.new(0, 0, -1.8)
	bit("IncPortRing", Vector3.new(0.12, 1.2, 1.2), front * CFrame.new(-0.55, 1.55, -0.02) * face, metal, metalMat).Shape =
		Enum.PartType.Cylinder
	bit(
		"IncPorthole",
		Vector3.new(0.1, 0.9, 0.9),
		front * CFrame.new(-0.55, 1.55, -0.06) * face,
		glowC,
		Enum.Material.Neon
	).Shape =
		Enum.PartType.Cylinder
	if tier == 4 then
		bit("IncScreen", Vector3.new(0.9, 0.6, 0.08), front * CFrame.new(0.6, 1.7, -0.04), Color3.fromRGB(30, 40, 56))
		bit(
			"IncScreenBar",
			Vector3.new(0.6, 0.12, 0.04),
			front * CFrame.new(0.55, 1.7, -0.09),
			glowC,
			Enum.Material.Neon
		)
	else
		bit(
			"IncDial",
			Vector3.new(0.1, 0.8, 0.8),
			front * CFrame.new(0.6, 1.75, -0.04) * face,
			Color3.fromRGB(250, 246, 236)
		).Shape =
			Enum.PartType.Cylinder
		bit("IncDialRing", Vector3.new(0.08, 0.92, 0.92), front * CFrame.new(0.6, 1.75, -0.01) * face, metal, metalMat).Shape =
			Enum.PartType.Cylinder
		bit(
			"IncNeedle",
			Vector3.new(0.05, 0.32, 0.03),
			front * CFrame.new(0.66, 1.8, -0.1) * CFrame.Angles(0, 0, math.rad(-35)),
			Color3.fromRGB(200, 50, 50)
		)
	end
	for k, c in { Color3.fromRGB(230, 70, 70), Color3.fromRGB(90, 200, 110) } do
		bit("IncButton", Vector3.new(0.1, 0.26, 0.26), front * CFrame.new(0.4 + (k - 1) * 0.42, 1.08, -0.05) * face, c).Shape =
			Enum.PartType.Cylinder
	end
	for k = 0, 2 do
		bit("IncVent", Vector3.new(0.9, 0.08, 0.06), front * CFrame.new(-0.55, 0.95 - k * 0.15, -0.03), rib, metalMat)
	end
	-- the straw bed and a few tufts on its rim
	drum("IncStraw", 2.65, 0.3, 3, Color3.fromRGB(240, 206, 128), Enum.Material.SmoothPlastic)
	for k = 0, 5 do
		local a = k * math.pi / 3
		bit(
			"IncTuft",
			Vector3.new(0.5, 0.18, 0.2),
			base * CFrame.new(math.cos(a) * 1.45, 2.85, math.sin(a) * 1.45) * CFrame.Angles(0, a, math.rad(20)),
			Color3.fromRGB(252, 226, 150),
			Enum.Material.SmoothPlastic
		)
	end
	-- the glass dome and the four ribs that hold it
	local dome = part(
		m,
		"IncDome",
		Vector3.one * 3.4,
		base * CFrame.new(0, 2.7, 0),
		Color3.fromRGB(215, 240, 255),
		Enum.Material.Glass
	) :: Part
	dome.Shape = Enum.PartType.Ball
	dome.Transparency = 0.75
	dome.CastShadow = false
	dome.CanCollide = false
	for k = 0, 3 do
		local turn = CFrame.Angles(0, k * math.pi / 2 + math.pi / 4, 0)
		local prev: Vector3? = nil
		for j = 0, 6 do
			local a = math.rad(j * 15)
			local p = Vector3.new(0, 2.7 + math.sin(a) * 1.72, -math.cos(a) * 1.72)
			if prev then
				local c = (prev + p) / 2
				bit(
					"IncDomeRib",
					Vector3.new(0.12, 0.12, (p - prev).Magnitude + 0.05),
					base * turn * CFrame.lookAt(c, p),
					metal,
					metalMat
				)
			end
			prev = p
		end
	end
	-- the lamp cap on top with its handle, and the warm light
	local cap = drum("IncCap", 4.5, 0.4, 1.1, metal, metalMat)
	drum("IncCapRim", 4.3, 0.12, 1.3, rib, metalMat)
	local glow = drum("IncLamp", 4.22, 0.16, 0.85, glowC, Enum.Material.Neon)
	glow.CastShadow = false
	for _, s in { -1, 1 } do
		bit("IncHandlePost", Vector3.new(0.12, 0.35, 0.12), base * CFrame.new(s * 0.32, 4.85, 0), metal, metalMat)
	end
	bit("IncHandle", Vector3.new(0.76, 0.12, 0.14), base * CFrame.new(0, 5.03, 0), metal, metalMat)
	local light = Instance.new("PointLight")
	light.Color = glowC
	light.Range = 7
	light.Brightness = 0.8
	light.Parent = cap
	-- a cable from the back down to the pad
	bit(
		"IncCable",
		Vector3.new(0.16, 0.16, 1.2),
		base * CFrame.new(0, 1.0, 2.25) * CFrame.Angles(math.rad(-50), 0, 0),
		Color3.fromRGB(50, 50, 56)
	)
end

-- The pen's layer for a level. `area` is the pen model: its kit fence, gate and cottage go (the
-- layer stands in for them); its floor and incubator pad take the era's tier.
function BreedingStages.build(area: Instance, frame: CFrame, level: number): Model
	local era, nests, incubators, props = BreedingStages.state(level)
	local pt = ERA_TIER[era]
	local tier = TIERS[pt]
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)

	for _, d in area:GetChildren() do
		if
			d.Name == "Fence"
			or d.Name == "PenGate"
			or d.Name == "Cottage"
			or d.Name == "FlowerPot"
			or (d.Name == "Incubator" and d:IsA("Model"))
		then
			d.Parent = nil
		elseif d.Name == "PenFloor" and d:IsA("BasePart") then
			skin(d, pt, tier.yard, tier.yardMat)
		elseif d.Name == "IncubatorPad" and d:IsA("BasePart") then
			skin(d, pt, tier.base, tier.baseMat)
		elseif d.Name == "HayBale" and d:IsA("Model") then
			-- the hay store stands against the back fence, the bed in front of it
			local hp = frame:PointToObjectSpace(d:GetPivot().Position)
			d:PivotTo(d:GetPivot() + frame:VectorToWorldSpace(Vector3.new(HAY.X - hp.X, 0, HAY.Z - hp.Z)))
		end
	end

	-- the strip behind the yard, where the house stands: any tree or bush there goes, and the floor is carried to
	-- the back fence
	local fx0, fx1, _, fz1 = BreedingHouse.fence()
	local sx0, sx1, _, sz1 = BreedingHouse.footprint(level)
	for _, d in (area.Parent or area):GetDescendants() do
		if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
			local p = frame:PointToObjectSpace(d:GetPivot().Position)
			if p.X > sx0 and p.X < sx1 and p.Z > Z1 - 0.5 and p.Z < sz1 then
				d.Parent = nil
			end
		end
	end
	local floor = area:FindFirstChild("PenFloor")
	local ext = part(
		m,
		"FloorExt",
		Vector3.new(fx1 - fx0, FLOOR, fz1 - Z1),
		frame * CFrame.new((fx0 + fx1) / 2, FLOOR / 2, (Z1 + fz1) / 2),
		if floor and floor:IsA("BasePart") then floor.Color else tier.yard
	)
	PondStages.studLook(ext, tier.yardMat)

	-- the fence, the gate, the hall with its warm room and wing, the egg on its roof
	BreedingHouse.build(m, frame, level)

	-- (the right fence opens at a side gate toward the incubators, a paved step across the grass)
	part(
		m,
		"SidePath",
		Vector3.new(X0 - (INC_X + 3.5), 0.4, SIDE1 - SIDE0), -- (right across to the pad's edge, no grass between)
		frame * CFrame.new((X0 + INC_X + 3.5) / 2, 0.2, (SIDE0 + SIDE1) / 2),
		tier.base,
		tier.baseMat
	)

	-- nests (the first two are the area's own), each on a round platform
	for i = 1, nests do
		local n = NESTS[i]
		local disc = part(
			m,
			"NestPlatform",
			Vector3.new(0.3, 5.6, 5.6),
			frame * CFrame.new(n[1], 0.55, n[2]) * CFrame.Angles(0, 0, math.rad(90)),
			tier.yard,
			tier.yardMat
		) :: Part
		disc.Shape = Enum.PartType.Cylinder
		if i > 2 then
			local nest = place(m, frame, "BirdNest", n[1], n[2], 2.1, 5, 0.7)
			if nest then
				local hollow = part(
					m,
					"NestHollow" .. i,
					Vector3.new(2.6, 0.2, 2.6),
					frame * CFrame.new(n[1], 1.5, n[2]),
					Color3.new(1, 1, 1)
				)
				hollow.Transparency = 1
				hollow.CanCollide = false
				local mark = Instance.new("Attachment")
				mark.Name = "Nest" .. i
				mark.Parent = hollow
			end
		end
	end

	-- incubators, built here with a clear glass dome so the egg inside shows (the owner, 2026-10-28:
	-- the kit model's dome was solid); those beyond the first two stand on the pad made longer
	for i = 1, incubators do
		local n = INCUBATORS[i]
		if i > 2 then
			part(
				m,
				"IncubatorPadExt",
				Vector3.new(7, 0.4, INC_PAD_EXT),
				frame * CFrame.new(n[1], 0.2, n[2]),
				if pt <= 1 then Color3.fromRGB(255, 244, 228) else tier.base,
				tier.baseMat
			)
		end
		incubator(m, frame * CFrame.new(n[1], 0.4, n[2]) * CFrame.Angles(0, math.rad(-90), 0), INC_TIER[era])
		if i > 2 then
			local bed = part(
				m,
				"IncBed" .. i,
				Vector3.new(2.4, 0.2, 2.4),
				frame * CFrame.new(n[1], 3.2, n[2]),
				Color3.new(1, 1, 1)
			)
			bed.Transparency = 1
			bed.CanCollide = false
			local mark = Instance.new("Attachment")
			mark.Name = "Incubator" .. i
			mark.Parent = bed
		end
	end

	-- the order of the pen: the lane, the two corner mats, and the life round them
	local tfl = tier
	local function flat(name: string, x0: number, x1z: number, z0: number, z1: number, col: Color3, mat: Enum.Material)
		part(
			m,
			name,
			Vector3.new(x1z - x0, 0.06, z1 - z0),
			frame * CFrame.new((x0 + x1z) / 2, FLOOR + 0.03, (z0 + z1) / 2),
			col,
			mat
		)
	end
	-- the lane from the gate to the hall's door, paved and edged
	flat("Lane", 1.8, 6.2, Z0 + 0.4, Z1 + 0.2, tfl.base, tfl.baseMat)
	for _, x in { 1.65, 6.35 } do
		flat("LaneEdge", x - 0.15, x + 0.15, Z0 + 0.4, Z1 + 0.2, tfl.edge, tfl.baseMat)
	end
	-- the feed and rest corner on straw, the water and egg corner on stone (both stop short of the hall's front)
	flat("FeedMat", 14.5, X1 - 0.4, 7, Z1 - 1, Color3.fromRGB(226, 192, 120), Enum.Material.SmoothPlastic)
	flat("WaterMat", X0 + 0.4, -3.6, 6.5, Z1 - 1, tfl.base, tfl.baseMat)
	-- a second bale on the hay store, a water barrel by the trough
	place(m, frame, "HayBale", HAY.X, HAY.Z, 1.7, 2.4, 2.45)
	place(m, frame, "WoodBarrel", -15, 16.5, 2.4, 1.8, FLOOR)
	-- a flower box between the left-hand nests, planters inside the gate
	place(m, frame, "Planter", 22.5, -5.5, 1.5, 2.2, FLOOR)
	for _, x in { -2, 10 } do
		place(m, frame, "Planter", x, Z0 + 1.4, 1.5, 2.2, FLOOR)
	end

	-- signs of everyday life (ChatGPT's 3rd breeding review: "a nursery, not a showroom"); small,
	-- few, and kept off the lane
	local wood, woodMat = Color3.fromRGB(150, 104, 62), Enum.Material.Wood
	local hay = Color3.fromRGB(232, 196, 120)
	local metal = Color3.fromRGB(150, 156, 166)
	local function bit(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?): BasePart
		local p = part(m, name, size, cf, col, mat or Enum.Material.SmoothPlastic)
		p.CanCollide = false
		p.CastShadow = false
		return p
	end
	local function on(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, FLOOR + y, z)
	end
	-- the feed corner: loose hay by the store, a scoop by the feeder, a broom against the fence
	for _, h in { { HAY.X - 2, HAY.Z - 1.2, 0.4 }, { HAY.X - 1.4, HAY.Z - 2.3, 2.2 } } do
		wedge(
			m,
			"LooseHay",
			Vector3.new(1.4, 0.45, 1),
			on(h[1], 0.22, h[2]) * CFrame.Angles(0, h[3], 0),
			hay,
			Enum.Material.SmoothPlastic
		)
	end
	local feed = SLOT_AT[1]
	bit(
		"ScoopBowl",
		Vector3.new(0.7, 0.35, 0.5),
		on(feed[1] + 0.2, 0.18, feed[2] + 2.4),
		if era >= 4 then metal else wood,
		woodMat
	)
	bit(
		"ScoopHandle",
		Vector3.new(0.15, 0.15, 0.9),
		on(feed[1] + 0.2, 0.25, feed[2] + 3) * CFrame.Angles(0.2, 0, 0),
		wood,
		woodMat
	)
	bit("BroomStick", Vector3.new(0.15, 3.2, 0.15), on(X1 - 0.6, 1.55, 8) * CFrame.Angles(0, 0, -0.22), wood, woodMat)
	bit("BroomHead", Vector3.new(0.4, 0.7, 1.1), on(X1 - 1, 0.35, 8), hay)
	-- the water side: a bucket by the trough, a damp patch before it; the egg side dry, on a slab,
	-- and a sign with an egg and an arrow by the side gate, pointing out to the incubators
	local bucket = bit(
		"Bucket",
		Vector3.new(1, 0.9, 0.9),
		on(-6.5, 0.5, 15.5) * CFrame.Angles(0, 0, math.pi / 2),
		if era >= 3 then metal else wood,
		if era >= 3 then Enum.Material.Metal else woodMat
	) :: Part
	bucket.Shape = Enum.PartType.Cylinder
	local damp = bit(
		"DampPatch",
		Vector3.new(0.04, 3, 1.4),
		on(-10, 0.02, 11.8) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(90, 120, 150)
	) :: Part
	damp.Transparency = 0.6
	bit("EggSlab", Vector3.new(3.4, 0.1, 3.4), on(SLOT_AT[2][1], 0.05, SLOT_AT[2][2]), Color3.fromRGB(240, 226, 196))
	part(m, "SignPost", Vector3.new(0.25, 3, 0.25), on(X0 + 0.7, 1.5, SIDE0 - 1.2), wood, woodMat)
	local board = on(X0 + 0.7, 2.7, SIDE0 - 1.2) * CFrame.Angles(0, -math.pi / 2, 0) -- its front to the pen
	bit(
		"SignBoard",
		Vector3.new(1.8, 1.1, 0.15),
		board * CFrame.new(0, 0, -0.15),
		if era >= 4 then metal else wood,
		woodMat
	)
	local egg = bit(
		"SignEgg",
		Vector3.new(0.5, 0.7, 0.12),
		board * CFrame.new(0.35, 0, -0.25),
		Color3.fromRGB(255, 250, 240)
	) :: Part
	egg.Shape = Enum.PartType.Ball
	wedge(
		m,
		"SignArrow",
		Vector3.new(0.1, 0.5, 0.6),
		board * CFrame.new(-0.45, 0, -0.25) * CFrame.Angles(0, math.pi / 2, math.pi / 2),
		Color3.fromRGB(240, 132, 168),
		Enum.Material.SmoothPlastic
	)
	-- the nests: a tuft of straw at each, and the era's small marker on the front of the rim
	local accents = {
		Color3.fromRGB(255, 196, 214),
		Color3.fromRGB(196, 220, 255),
		Color3.fromRGB(255, 226, 150),
		Color3.fromRGB(200, 240, 210),
	}
	for i = 1, nests do
		local n = NESTS[i]
		local side = if n[1] > BX then 1 else -1
		wedge(
			m,
			"NestStraw",
			Vector3.new(1.2, 0.4, 0.9),
			on(n[1] + side * 2.9, 0.2, n[2] + (i % 2) * 1.2 - 0.6) * CFrame.Angles(0, side * 1.2 + i, 0),
			hay,
			Enum.Material.SmoothPlastic
		)
		local rim = on(n[1], 1.9, n[2] - 2.45)
		if era == 2 then
			bit("NestRibbon", Vector3.new(1.2, 0.35, 0.12), rim, accents[i])
		elseif era == 3 then
			part(
				m,
				"NestMarker",
				Vector3.new(0.7, 0.6, 0.4),
				on(n[1], 0.35, n[2] - 2.9),
				TIERS[3].walls,
				TIERS[3].wallMat
			)
		elseif era == 4 then
			bit("NestTab", Vector3.new(0.8, 0.45, 0.1), rim, metal, Enum.Material.Metal)
			bit("NestTabStripe", Vector3.new(0.8, 0.12, 0.12), rim * CFrame.new(0, 0, -0.03), accents[i])
		elseif era == 5 then
			bit("NestGlow", Vector3.new(1.4, 0.1, 0.1), rim, Color3.fromRGB(120, 230, 200), Enum.Material.Neon)
		end
	end
	-- the floor: a slime's shiny trail mark by the right nests, pebbles in the front-left corner
	local trail = bit(
		"SlimeMark",
		Vector3.new(0.04, 1.3, 0.9),
		on(-1, 0.02, -6) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(150, 230, 200)
	) :: Part
	trail.Shape = Enum.PartType.Cylinder
	trail.Transparency = 0.45
	for k, o in { { X1 - 1.4, Z0 + 1.8 }, { X1 - 0.9, Z0 + 2.4 }, { X1 - 1.8, Z0 + 2.6 } } do
		local stone = bit(
			"Pebble",
			Vector3.one * (0.5 + k * 0.08),
			on(o[1], 0.2, o[2]),
			Color3.fromRGB(176, 170, 160),
			Enum.Material.Slate
		) :: Part
		stone.Shape = Enum.PartType.Ball
	end
	-- (the gate is BreedingHouse's: its heart-and-egg emblem and lanterns stand where the plaque and the bell hung)

	-- the care props
	for j = 1, 4 do
		local e = props[j]
		if e > 0 then
			local lift = FLOOR + (LIFT[j] and LIFT[j][e] or 0) + (if j == 2 then 0.1 else 0)
			if j == 3 and e == 5 then
				-- the floating cloud bed, built: a plump pad ringed with cloud puffs, a pink cushion in
				-- it (ChatGPT's 2nd breeding review: the kit model read as a ring on the floor)
				local cx, cz = SLOT_AT[3][1], SLOT_AT[3][2]
				local white = Color3.fromRGB(250, 250, 255)
				part(
					m,
					"CloudPad",
					Vector3.new(3.2, 0.6, 2.6),
					frame * CFrame.new(cx, lift + 0.5, cz),
					white,
					Enum.Material.SmoothPlastic
				)
				for a = 0, 5 do
					local r = math.rad(a * 60)
					local puff = part(
						m,
						"CloudPuff",
						Vector3.one * 1.3,
						frame * CFrame.new(cx + math.cos(r) * 1.55, lift + 0.75, cz + math.sin(r) * 1.25),
						white,
						Enum.Material.SmoothPlastic
					) :: Part
					puff.Shape = Enum.PartType.Ball
				end
				part(
					m,
					"CloudCushion",
					Vector3.new(1.8, 0.4, 1.4),
					frame * CFrame.new(cx, lift + 0.95, cz),
					Color3.fromRGB(255, 196, 214),
					Enum.Material.SmoothPlastic
				)
			else
				place(m, frame, PROPS[j][e], SLOT_AT[j][1], SLOT_AT[j][2], HEIGHT[j][e], FOOT[j], lift)
			end
			if j == 4 and e == 5 then
				-- the holo beacon's warm field: a soft glowing disc on the floor round it
				local disc = part(
					m,
					"WarmField",
					Vector3.new(0.06, 2.4, 2.4),
					frame * CFrame.new(SLOT_AT[4][1], FLOOR + 0.04, SLOT_AT[4][2]) * CFrame.Angles(0, 0, math.pi / 2),
					Color3.fromRGB(255, 170, 200),
					Enum.Material.Neon
				) :: Part
				disc.Shape = Enum.PartType.Cylinder
				disc.Transparency = 0.5
				disc.CastShadow = false
			end
		end
	end
	return m
end

return BreedingStages
