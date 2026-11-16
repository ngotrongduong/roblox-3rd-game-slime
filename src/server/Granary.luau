--!strict
-- The pantry's landmark: the village's great granary with its clock tower (village v2; the owner, 2026-11-16:
-- the buildings taller and bigger, with more fine detail, better finished and built sensibly). One building in
-- five architectures, one an era of ten levels (references: docs/areas/village-v2/granary-ref-era*.jpg):
--   1 hamlet       thatch and plaster on brown beams, a small clock tower, wooden silos
--   2 painted      cream plaster on teal beams, red shingles, an arched door, shutters
--   3 town         a stone ground storey under a jettied half-timbered one, red tiles, a stone tower
--   4 slime tech   a steel frame under a glass roof, a glass-domed tower, glowing goo silos
--   5 capital      white marble and gold, a pediment with a golden slime, a blue dome
-- The hall stands x -hw..hw, z 0..d, its gable and door to the front (-z); the tower rises from the ridge; an
-- open lean-to shed runs along the right wall (-x) and the silos stand behind it.
-- An era's first level changes the architecture; levels 6-10 of each era add one feature each, and a feature
-- once added stays in every later era (25 in all, listed in `build`).
local Architecture = require(script.Parent.Architecture)

local Granary = {}

local C = Color3.fromRGB
local IRON = C(60, 60, 66)
local DARK = C(42, 34, 30)
local WHITE = C(250, 248, 240)
local BASE = 1.2 -- the hall's stone foot: its door stands a step above the yard
local FLOOR = 0.4 -- the yard's paving over the lawn
local FRONT = Vector3.new(0, 0, -1)
local LEFT, RIGHT = Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0) -- (as one walks in: +x is the left)
-- the lean-to along the right wall, front to back
local LEAN_Z0, LEAN_Z1, LEAN_OUT = 2.2, 9.6, 5.8

type WindowOpts = { shutters: Color3?, arch: boolean?, flowers: boolean?, glow: boolean? }
type Look = {
	hw: number, -- half the hall's width
	d: number, -- its depth
	wallH: number, -- the walls' top
	rise: number, -- the roof over the walls
	over: number, -- the roof's overhang
	doorW: number,
	doorH: number,
	lowerH: number?, -- a stone ground storey up to here, the upper storey jettied over it
	floors: { number }, -- the timber frame's bands, foot to top
	rows: { { number } }, -- rows of windows: the middle's height, width, height, 1 for a round head
	timber: boolean,
	wall: Color3,
	lower: Color3,
	stone: Color3,
	beam: Color3,
	board: Color3,
	surround: Color3,
	roof: Color3,
	roofMat: Enum.Material?,
	door: Color3,
	band: Color3,
	frame: Color3,
	glass: Color3,
	glow: boolean,
	shutters: Color3?,
	accent: Color3,
	cloth: Color3,
	gold: Color3,
	tower: number, -- the tower's width
	towerWall: Color3,
	towerRoof: string, -- "pyramid", "glass" or "dome"
	spire: number,
	siloR: number,
	siloH: number,
	siloDrum: Color3,
	siloHoop: Color3,
	siloCap: string,
	siloCapColour: Color3,
	goo: Color3?,
}

local LOOKS: { Look } = {
	{
		hw = 7,
		d = 12,
		wallH = 7.4,
		rise = 7,
		over = 1.4,
		doorW = 4,
		doorH = 5.2,
		floors = { BASE, 7.4 },
		rows = { { 4.4, 1.5, 1.9, 0 } },
		timber = true,
		wall = C(236, 220, 180),
		lower = C(236, 220, 180),
		stone = C(150, 146, 138),
		beam = C(110, 72, 42),
		board = C(110, 72, 42),
		surround = C(110, 72, 42),
		roof = C(232, 190, 84),
		door = C(150, 98, 54),
		band = IRON,
		frame = C(110, 72, 42),
		glass = C(255, 214, 120),
		glow = false,
		shutters = C(120, 150, 96),
		accent = C(214, 172, 74),
		cloth = C(52, 96, 190),
		gold = C(232, 190, 80),
		tower = 4.5,
		towerWall = C(236, 220, 180),
		towerRoof = "pyramid",
		spire = 5,
		siloR = 2.3,
		siloH = 8.5,
		siloDrum = C(170, 116, 66),
		siloHoop = C(96, 70, 50),
		siloCap = "cone",
		siloCapColour = C(214, 172, 74),
	},
	{
		hw = 8,
		d = 14,
		wallH = 9,
		rise = 8,
		over = 1.1,
		doorW = 4.4,
		doorH = 5.4,
		floors = { BASE, 5.1, 9 },
		rows = { { 3.95, 1.5, 1.9, 0 }, { 7.05, 1.4, 1.8, 0 } },
		timber = true,
		wall = C(244, 238, 224),
		lower = C(244, 238, 224),
		stone = C(156, 152, 146),
		beam = C(40, 128, 130),
		board = C(32, 104, 108),
		surround = C(40, 128, 130),
		roof = C(198, 70, 58),
		door = C(146, 96, 56),
		band = IRON,
		frame = WHITE,
		glass = C(255, 222, 140),
		glow = false,
		shutters = C(52, 150, 150),
		accent = C(52, 150, 150),
		cloth = C(52, 96, 190),
		gold = C(232, 190, 80),
		tower = 5.5,
		towerWall = C(244, 238, 224),
		towerRoof = "pyramid",
		spire = 6.5,
		siloR = 2.5,
		siloH = 10.5,
		siloDrum = C(236, 228, 208),
		siloHoop = C(32, 104, 108),
		siloCap = "cone",
		siloCapColour = C(52, 150, 150),
	},
	{
		hw = 9,
		d = 16,
		wallH = 11.4,
		rise = 9,
		over = 1.1,
		doorW = 4.8,
		doorH = 5.8,
		lowerH = 7.2,
		floors = { 7.2, 11.4 },
		rows = { { 4.3, 1.5, 2, 1 }, { 9.3, 1.4, 1.8, 0 } },
		timber = true,
		wall = C(240, 230, 206),
		lower = C(170, 166, 158),
		stone = C(128, 124, 118),
		beam = C(112, 72, 44),
		board = C(112, 72, 44),
		surround = C(206, 200, 188),
		roof = C(190, 62, 50),
		door = C(104, 66, 44),
		band = IRON,
		frame = C(112, 72, 44),
		glass = C(255, 222, 140),
		glow = false,
		accent = C(190, 62, 50),
		cloth = C(52, 96, 190),
		gold = C(232, 190, 80),
		tower = 6.5,
		towerWall = C(176, 172, 166),
		towerRoof = "pyramid",
		spire = 9,
		siloR = 2.8,
		siloH = 12.5,
		siloDrum = C(176, 172, 166),
		siloHoop = C(128, 124, 118),
		siloCap = "cone",
		siloCapColour = C(190, 62, 50),
	},
	{
		hw = 9.5,
		d = 17,
		wallH = 12.4,
		rise = 8,
		over = 1,
		doorW = 5.2,
		doorH = 6.2,
		floors = { BASE, 7.6, 12.4 },
		rows = { { 4.6, 1.6, 2.6, 0 }, { 10, 1.6, 2.6, 0 } },
		timber = true,
		-- (brick in a dark steel frame, as the reference picture has it: all-steel walls read as one navy block)
		wall = C(198, 112, 74),
		lower = C(198, 112, 74),
		stone = C(60, 66, 78),
		beam = C(48, 54, 66),
		board = C(48, 54, 66),
		surround = C(48, 54, 66),
		roof = C(90, 200, 220),
		roofMat = Enum.Material.Glass,
		door = C(150, 94, 54),
		band = C(48, 54, 66),
		frame = C(48, 54, 66),
		glass = C(120, 230, 235),
		glow = true,
		accent = C(196, 112, 66),
		cloth = C(40, 80, 160),
		gold = C(224, 170, 70),
		tower = 7,
		towerWall = C(72, 84, 104),
		towerRoof = "glass",
		spire = 0,
		siloR = 3,
		siloH = 13.5,
		siloDrum = C(190, 240, 200),
		siloHoop = C(60, 66, 78),
		siloCap = "dome",
		siloCapColour = C(70, 190, 205),
		goo = C(96, 232, 70),
	},
	{
		hw = 10,
		d = 18,
		wallH = 13.4,
		rise = 6,
		over = 1,
		doorW = 5.6,
		doorH = 6.6,
		floors = {},
		rows = { { 4.6, 1.6, 2.4, 1 }, { 9.8, 1.6, 2.4, 1 } },
		timber = false,
		wall = C(246, 243, 236),
		lower = C(246, 243, 236),
		stone = C(214, 208, 196),
		beam = C(228, 222, 210),
		board = C(236, 192, 76),
		surround = C(236, 192, 76),
		roof = C(44, 84, 170),
		door = C(44, 84, 170),
		band = C(236, 192, 76),
		frame = C(236, 192, 76),
		glass = C(130, 220, 240),
		glow = false,
		accent = C(44, 84, 170),
		cloth = C(40, 70, 160),
		gold = C(236, 192, 76),
		tower = 7.5,
		towerWall = C(246, 243, 236),
		towerRoof = "dome",
		spire = 0,
		siloR = 3,
		siloH = 14.5,
		siloDrum = C(240, 196, 70),
		siloHoop = C(246, 243, 236),
		siloCap = "dome",
		siloCapColour = C(44, 84, 170),
	},
}

-- A level's era (1-5) and how many of the 25 features it has.
function Granary.features(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	return era, (era - 1) * 5 + math.max(0, s - 5)
end

function Granary.halfWidth(level: number): number
	return LOOKS[(Granary.features(level))].hw
end

-- The lawn behind the yard (which ends at z 10) that the hall's back, the silos, the engine house and the hay
-- store on the left may stand on (x0, x1, z0, z1): scenery there goes.
function Granary.footprint(level: number): (number, number, number, number)
	local L = LOOKS[(Granary.features(level))]
	return -(L.hw + 4 * L.siloR + 4), L.hw + 17, 9, math.max(L.d, 12.4 + L.siloR * 4.5) + 2
end

-- where a wall's bays fall (as Architecture.timber sets its posts), so windows sit between posts
local function bayCentres(len: number): { number }
	local n = math.max(1, math.round(len / 3.2))
	local step = (len - 0.4) / n
	local out = {}
	for i = 1, n do
		out[i] = -len / 2 + 0.2 + (i - 0.5) * step
	end
	return out
end

function Granary.build(m: Instance, frame: CFrame, level: number)
	local era, f = Granary.features(level)
	local L = LOOKS[era]
	local b = Architecture.new(m, frame)
	local hw, d, wallH, dw = L.hw, L.d, L.wallH, L.doorW
	local lowerTop = L.lowerH or wallH
	local jet = if L.lowerH then 0.3 else 0
	local half = hw + jet -- half the roof's span
	local pitch = L.rise / half
	local ridge = wallH + L.rise
	local doorTop = BASE + L.doorH
	local function roofY(u: number): number -- the roof's height `u` from the ridge line
		return ridge - pitch * math.abs(u)
	end
	local tips: { Vector3 } = {} -- the tops of turrets and silos (beacons, flags)
	local glowMat = if L.glow then Enum.Material.Neon else nil

	local function slime(cf: CFrame, r: number) -- a golden slime, `cf` at its foot, looking along -Z
		b.cyl("SlimeFoot", r * 0.92, r * 0.5, cf * CFrame.new(0, r * 0.25, 0), L.gold, nil, false)
		b.ball("SlimeBody", r, cf * CFrame.new(0, r * 0.8, 0), L.gold)
		for _, s in { -1, 1 } do
			b.ball("SlimeEye", r * 0.14, cf * CFrame.new(s * r * 0.36, r, -r * 0.9), DARK)
		end
	end
	local function crown(cf: CFrame, r: number)
		b.cyl("Crown", r, r * 0.5, cf * CFrame.new(0, r * 0.25, 0), L.gold, nil, false)
		for k = 0, 5 do
			b.trim(
				"CrownPoint",
				r * 0.3,
				r * 0.7,
				r * 0.2,
				cf * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, r * 0.75, -r * 0.88),
				L.gold
			)
		end
	end

	-- THE HALL -------------------------------------------------------------------------------------------
	b.box("Plinth", hw * 2 + 0.6, BASE, d + 0.6, b.at(0, BASE / 2, d / 2), L.stone)
	b.box("Walls", hw * 2, lowerTop - BASE, d, b.at(0, (BASE + lowerTop) / 2, d / 2), L.lower)
	if L.lowerH then
		b.box("UpperWalls", half * 2, wallH - lowerTop, d + jet * 2, b.at(0, (lowerTop + wallH) / 2, d / 2), L.wall)
		b.trim("Jetty", half * 2 + 0.3, 0.45, d + jet * 2 + 0.3, b.at(0, lowerTop, d / 2), L.beam)
		-- quoins up the stone storey's front corners
		for _, s in { -1, 1 } do
			for i = 0, 3 do
				local wide = if i % 2 == 0 then 1.3 else 0.9
				b.trim(
					"Quoin",
					wide,
					0.9,
					wide,
					b.at(s * (hw - wide / 2 + 0.12), BASE + 0.7 + i * 1.5, wide / 2 - 0.12),
					L.surround
				)
			end
		end
	end

	-- the frame: bands of timber (steel on slime tech) on the sides, and on the front either side of the door
	local inner = dw / 2 + 0.9
	if L.timber then
		for i = 1, #L.floors - 1 do
			local y0, y1 = L.floors[i], L.floors[i + 1]
			local off = if L.lowerH then jet else 0
			local y, h = (y0 + y1) / 2, y1 - y0
			b.timber(b.face(hw + off, y, d / 2, LEFT), d + off * 2, h, L.beam)
			b.timber(b.face(-hw - off, y, d / 2, RIGHT), d + off * 2, h, L.beam)
			if y0 >= doorTop then
				b.timber(b.face(0, y, -off, FRONT), (hw + off) * 2, h, L.beam)
			else
				local len = hw + off - inner
				for _, s in { -1, 1 } do
					local face = b.face(s * (inner + len / 2), y, -off, FRONT)
					for _, ry in { -h / 2 + 0.2, h / 2 - 0.2 } do
						b.trim("Rail", len, 0.4, 0.3, face * CFrame.new(0, ry, -0.1), L.beam)
					end
					for _, px in { -len / 2 + 0.2, len / 2 - 0.2 } do
						b.trim("Post", 0.4, h, 0.3, face * CFrame.new(px, 0, -0.1), L.beam)
					end
				end
			end
		end
	else
		-- marble: pilasters with golden heads between the bays, a band under the roof
		local function pilaster(face: CFrame)
			local h = wallH - BASE
			b.trim("Pilaster", 0.9, h, 0.35, face * CFrame.new(0, h / 2, -0.12), L.beam)
			b.trim("PilasterFoot", 1.2, 0.5, 0.5, face * CFrame.new(0, 0.25, -0.15), L.beam)
			b.trim("PilasterHead", 1.3, 0.5, 0.55, face * CFrame.new(0, h - 0.25, -0.18), L.gold)
		end
		local n = math.round(d / 3.2)
		for i = 0, n do
			local z = 0.45 + i * (d - 0.9) / n
			pilaster(b.face(hw, BASE, z, LEFT))
			pilaster(b.face(-hw, BASE, z, RIGHT))
		end
		for _, x in { -hw + 0.45, -inner, inner, hw - 0.45 } do
			pilaster(b.face(x, BASE, 0, FRONT))
		end
		b.trim("Entablature", hw * 2 + 0.5, 0.7, d + 0.5, b.at(0, wallH - 0.35, d / 2), L.beam)
		b.trim("EntablatureLine", hw * 2 + 0.7, 0.2, d + 0.7, b.at(0, wallH - 0.75, d / 2), L.gold)
	end

	-- the roof, its ridge front to back
	b.gable(
		b.at(0, wallH, d / 2) * CFrame.Angles(0, math.pi / 2, 0),
		d + jet * 2,
		half * 2,
		L.rise,
		L.over,
		L.roof,
		L.wall,
		L.board,
		L.roofMat,
		if era == 1 then 0.9 else nil -- thatch is thick
	)
	if era == 1 then
		-- thatch ends in a thick roll along each eave
		for _, s in { -1, 1 } do
			local u = half + L.over - 0.3
			b.trim("EaveRoll", 0.9, 0.7, d + L.over * 2, b.at(s * u, roofY(u) - 0.15, d / 2), L.accent)
		end
	elseif L.roofMat == Enum.Material.Glass then
		-- glazing bars down the glass
		local n = math.round(d / 3.4)
		for i = 0, n do
			local z = i * d / n
			for _, s in { -1, 1 } do
				local u = half + L.over
				b.beam(
					"RoofBar",
					0.3,
					0.2,
					Vector3.new(0, ridge + 0.12, z),
					Vector3.new(s * u, roofY(u) + 0.12, z),
					L.beam
				)
			end
		end
	end
	if f >= 18 then
		-- a golden crest along the ridge
		local zT, tw = d * 0.6, L.tower
		for z = 0.4, d - 0.4, 1.7 do
			if math.abs(z - zT) > tw / 2 + 0.3 then
				b.trim("RidgeCrest", 0.2, 0.8, 0.6, b.at(0, ridge + 0.7, z), L.gold)
			end
		end
	end

	-- THE GABLE FRONT ------------------------------------------------------------------------------------
	local function gf(x: number, y: number): CFrame
		return b.face(x, y, -jet, FRONT)
	end
	b.trim("TieBeam", half * 2 + 0.3, 0.5, 0.35, gf(0, wallH) * CFrame.new(0, 0, -0.12), L.board)
	if L.timber then
		b.trim("KingPost", 0.4, L.rise - 0.9, 0.3, gf(0, wallH + (L.rise - 0.9) / 2) * CFrame.new(0, 0, -0.1), L.beam)
		for _, s in { -1, 1 } do
			b.beam(
				"Strut",
				0.3,
				0.36,
				Vector3.new(s * half * 0.62, wallH + 0.2, -jet - 0.1),
				Vector3.new(0, wallH + L.rise * 0.55, -jet - 0.1),
				L.beam
			)
		end
	end
	local gableY = wallH + L.rise * 0.36
	if era == 5 then
		-- the golden slime of the pediment
		slime(b.at(0, wallH + 0.5, -jet + 0.1), 1.9)
	elseif era == 1 then
		-- the loft hatch
		b.window(gf(0, gableY), 1.6, 1.8, L.frame, L.glass, { shutters = L.shutters, flowers = f >= 4 } :: WindowOpts)
	else
		local r = 1 + 0.15 * era
		b.disc("OculusRim", r + 0.3, 0.3, gf(0, gableY) * CFrame.new(0, 0, -0.2), L.frame)
		b.disc("OculusGlass", r, 0.36, gf(0, gableY) * CFrame.new(0, 0, -0.21), L.glass, glowMat)
		b.trim("OculusBar", 0.14, r * 2, 0.42, gf(0, gableY) * CFrame.new(0, 0, -0.21), L.frame)
		b.trim("OculusBar", r * 2, 0.14, 0.42, gf(0, gableY) * CFrame.new(0, 0, -0.21), L.frame)
	end
	if f >= 8 then
		-- a finial on the gable's peak
		b.rod(
			"GableSpike",
			0.1,
			Vector3.new(0, ridge, -jet - L.over),
			Vector3.new(0, ridge + 1.8, -jet - L.over),
			L.gold
		)
		b.ball("GableFinial", 0.3, b.at(0, ridge + 1.9, -jet - L.over), L.gold)
	end
	if f >= 10 and (era == 2 or era == 3) then
		-- the loft hoist: a jib out of the gable's peak, a sack on its rope
		local y, z1 = ridge - 1.4, -jet - L.over - 1.5
		b.beam("Jib", 0.4, 0.4, Vector3.new(0, y, -jet + 0.6), Vector3.new(0, y, z1), L.beam)
		b.disc("JibPulley", 0.4, 0.25, b.face(0.2, y - 0.45, z1 + 0.4, LEFT), IRON)
		local ropeEnd = y - 1.9 -- (a long rope swung the sack across the round window)
		b.rod("JibRope", 0.06, Vector3.new(0, y - 0.5, z1 + 0.4), Vector3.new(0, ropeEnd, z1 + 0.4), C(226, 196, 140))
		b.ball("JibSack", 0.75, b.at(0, ropeEnd - 0.6, z1 + 0.4), C(214, 190, 140))
		b.cyl("JibSackNeck", 0.25, 0.4, b.at(0, ropeEnd + 0.1, z1 + 0.4), C(190, 160, 110), nil, false)
	end
	if f >= 16 and era == 4 then
		-- the gear over the door
		local face, r = b.face(0, (doorTop + wallH) / 2 + 0.5, 0, FRONT), 1.5
		b.disc("Gear", r, 0.3, face * CFrame.new(0, 0, -0.3), L.gold)
		for k = 0, 7 do
			b.trim(
				"GearTooth",
				r * 0.34,
				r * 0.4,
				0.3,
				face * CFrame.Angles(0, 0, k * math.pi / 4) * CFrame.new(0, r * 1.05, -0.3),
				L.gold
			)
		end
		b.disc("GearEye", r * 0.45, 0.4, face * CFrame.new(0, 0, -0.32), L.glass, Enum.Material.Neon)
	end

	-- THE DOOR -------------------------------------------------------------------------------------------
	local function df(x: number, y: number): CFrame
		return b.face(x, y, 0, FRONT)
	end
	local dockHW = dw / 2 + 1.5
	b.box("Dock", dockHW * 2, BASE, 3.6, b.at(0, BASE / 2, -1.8), L.stone)
	b.box(
		"DockStep",
		dockHW * 2 - 1,
		FLOOR + (BASE - FLOOR) / 2,
		1.2,
		b.at(0, (FLOOR + (BASE - FLOOR) / 2) / 2, -4.2),
		L.stone
	)
	local arched = era >= 2
	local leafH = if arched then L.doorH - dw / 2 else L.doorH
	local spring = BASE + leafH
	-- (the leaves and jambs stand in front of the arch's discs, hiding their lower halves)
	for _, s in { -1, 1 } do
		b.trim("DoorLeaf", dw / 2 - 0.06, leafH, 0.3, df(s * dw / 4, BASE + leafH / 2) * CFrame.new(0, 0, -0.4), L.door)
		for _, t in { 0.22, 0.78 } do
			b.trim(
				"DoorBand",
				dw / 2 - 0.3,
				0.22,
				0.1,
				df(s * dw / 4, BASE + leafH * t) * CFrame.new(0, 0, -0.58),
				L.band,
				if era == 4 then Enum.Material.Neon else nil
			)
		end
		b.ball("DoorRing", 0.2, df(s * 0.45, BASE + leafH * 0.5) * CFrame.new(0, 0, -0.6), L.band)
		b.trim(
			"DoorJamb",
			0.55,
			leafH,
			0.56,
			df(s * (dw / 2 + 0.27), BASE + leafH / 2) * CFrame.new(0, 0, -0.29),
			L.surround
		)
	end
	-- (the marker the slimes carry to)
	b.trim("Door", 0.12, leafH, 0.34, df(0, BASE + leafH / 2) * CFrame.new(0, 0, -0.4), DARK)
	if arched then
		b.disc("DoorArch", dw / 2 + 0.55, 0.4, df(0, spring) * CFrame.new(0, 0, -0.2), L.surround)
		if era == 2 then
			b.disc("DoorHead", dw / 2, 0.5, df(0, spring) * CFrame.new(0, 0, -0.25), L.door)
			b.trim("DoorHeadSplit", 0.12, dw / 2, 0.54, df(0, spring + dw / 4) * CFrame.new(0, 0, -0.25), DARK)
		else
			b.disc("Fanlight", dw / 2, 0.5, df(0, spring) * CFrame.new(0, 0, -0.25), L.glass, glowMat)
			for _, a in { -45, 0, 45 } do
				b.trim(
					"FanlightBar",
					0.14,
					dw / 2,
					0.56,
					df(0, spring) * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(0, dw / 4, -0.25),
					L.surround
				)
			end
			b.trim("Keystone", 0.8, 1, 0.6, df(0, spring + dw / 2 + 0.4) * CFrame.new(0, 0, -0.3), L.surround)
		end
		b.trim("DoorImpost", dw + 1.3, 0.3, 0.66, df(0, spring) * CFrame.new(0, 0, -0.3), L.surround)
	else
		b.trim("DoorLintel", dw + 1.7, 0.6, 0.66, df(0, spring + 0.3) * CFrame.new(0, 0, -0.3), L.surround)
	end

	-- lanterns either side of the door (one of them a real light), banners over them
	local sideX = dw / 2 + 1.35
	for _, s in { -1, 1 } do
		b.lantern(df(s * sideX, BASE + 2.2), L.glass, IRON, s < 0)
		if f >= 6 then
			local top = math.min(wallH - 0.5, doorTop + 1.4)
			local z = if top > lowerTop then -jet else 0
			b.banner(b.face(s * sideX, top, z, FRONT), 1.1, 2.6, L.cloth, L.gold)
		end
	end

	-- THE WINDOWS ----------------------------------------------------------------------------------------
	local leanHi = math.min(wallH - 0.6, 8.2)
	local engine = f >= 17
	local engineZ0 = math.max(10.8, d - 7)
	for _, row in L.rows do
		local y, w, h, round = row[1], row[2], row[3], row[4] == 1
		local up = L.lowerH ~= nil and y > lowerTop
		local off = if up then jet else 0
		local function opts(flowers: boolean): WindowOpts
			return { shutters = if round then nil else L.shutters, arch = round, flowers = flowers, glow = L.glow }
		end
		-- the front: one each side of the door, or along the whole storey where it runs over the door
		if y - h / 2 > doorTop + 0.3 then
			local centres = bayCentres((hw + off) * 2)
			for i = 2, #centres - 1 do
				if math.abs(centres[i]) > 2.3 then
					b.window(b.face(centres[i], y, -off, FRONT), w, h, L.frame, L.glass, opts(false))
				end
			end
		else
			local wx = inner + (hw + off - inner) / 2 + 0.25
			for _, s in { -1, 1 } do
				b.window(b.face(s * wx, y, -off, FRONT), w, h, L.frame, L.glass, opts(f >= 4 and y < doorTop))
				if f >= 9 and y < BASE + 4 then
					local head = y + h / 2 + (if round then w / 2 + 0.5 else 0.55)
					b.awning(b.face(s * wx, head, -off, FRONT), w + 1.8, 1.5, L.cloth, WHITE)
				end
			end
		end
		-- the sides: between the posts; none behind the lean-to or the engine house
		local centres = bayCentres(d + off * 2)
		local first, last = 2, #centres - 1
		if not L.timber then
			first, last = 1, #centres
		end
		for i = first, last do
			local z = d / 2 + centres[i]
			if not (engine and z > engineZ0 - 1 and y < wallH * 0.5 + 1) then
				b.window(b.face(hw + off, y, z, LEFT), w, h, L.frame, L.glass, opts(false))
			end
			if y - h / 2 > leanHi + 0.4 or z > LEAN_Z1 + 1.4 then
				b.window(b.face(-hw - off, y, z, RIGHT), w, h, L.frame, L.glass, opts(false))
			end
		end
	end
	if f >= 14 then
		-- banners high on the left wall
		for _, t in { 0.12, 0.88 } do
			b.banner(b.face(half, wallH - 0.7, d * t, LEFT), 1.3, 3, L.cloth, L.gold)
		end
	end

	-- THE CLOCK TOWER ------------------------------------------------------------------------------------
	local tw, zT = L.tower, d * 0.6
	local r = tw * 0.34
	local stages = (if f >= 15 then 1 else 0) + (if f >= 20 then 1 else 0)
	local clockY = ridge + 1 + r + stages * 2.5
	local shaftTop = clockY + r + 1
	b.box("Tower", tw, shaftTop - wallH, tw, b.at(0, (wallH + shaftTop) / 2, zT), L.towerWall)
	local postFoot = roofY(tw / 2) - 0.4
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			b.trim(
				"TowerPost",
				0.5,
				shaftTop - postFoot,
				0.5,
				b.at(sx * (tw / 2 - 0.1), (postFoot + shaftTop) / 2, zT + sz * (tw / 2 - 0.1)),
				L.board
			)
		end
	end
	for i = 1, stages do
		-- each storey the tower gains has a louvred window to the front
		b.window(b.face(0, ridge + 0.5 + (i - 0.5) * 2.5, zT - tw / 2, FRONT), 1.2, 1.5, L.frame, DARK)
	end
	b.trim("TowerString", tw + 0.5, 0.35, tw + 0.5, b.at(0, clockY - r - 0.65, zT), L.board)
	local dial = if era == 4 then C(210, 250, 245) else WHITE
	b.clock(b.face(0, clockY, zT - tw / 2, FRONT), r, L.gold, dial, DARK)
	b.clock(b.face(tw / 2, clockY, zT, LEFT), r, L.gold, dial, DARK)
	b.clock(b.face(-tw / 2, clockY, zT, RIGHT), r, L.gold, dial, DARK)
	b.box("TowerCornice", tw + 1, 0.5, tw + 1, b.at(0, shaftTop + 0.25, zT), L.board)
	local top = shaftTop + 0.5
	if f >= 5 then
		-- the belfry: an open stage with the village bell
		local bh = 3.2
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				b.box(
					"BelfryPost",
					0.6,
					bh,
					0.6,
					b.at(sx * (tw / 2 - 0.3), top + bh / 2, zT + sz * (tw / 2 - 0.3)),
					L.board
				)
			end
			b.trim("BelfryRail", 0.2, 0.25, tw - 1.2, b.at(sx * (tw / 2 - 0.3), top + 1, zT), L.board)
			b.trim("BelfryRail", tw - 1.2, 0.25, 0.2, b.at(0, top + 1, zT + sx * (tw / 2 - 0.3)), L.board)
		end
		b.trim("BellBeam", tw - 0.6, 0.3, 0.3, b.at(0, top + bh - 0.2, zT), L.board)
		b.ball("Bell", 0.9, b.at(0, top + bh - 1.2, zT), L.gold)
		b.cyl("BellMouth", 1, 0.3, b.at(0, top + bh - 1.9, zT), L.gold, nil, false)
		b.box("BelfryTop", tw + 1, 0.5, tw + 1, b.at(0, top + bh + 0.25, zT), L.board)
		top += bh + 0.5
	end
	local tip: number
	if L.towerRoof == "pyramid" then
		b.trim("TowerEave", tw + 1.7, 0.3, tw + 1.7, b.at(0, top + 0.15, zT), L.board)
		b.pyramid(b.at(0, top + 0.3, zT), tw + 1.5, tw + 1.5, L.spire, L.roof)
		tip = top + 0.3 + L.spire
	elseif L.towerRoof == "glass" then
		local R = tw / 2
		b.cyl("DomeRing", R + 0.4, 0.5, b.at(0, top + 0.25, zT), L.gold, nil, false)
		b.ball("Dome", R, b.at(0, top + 0.5, zT), L.roof, Enum.Material.Glass)
		b.ball("DomeGoo", R * 0.45, b.at(0, top + 0.9, zT), L.goo or L.glass, Enum.Material.Neon)
		b.cyl("DomeCap", 0.9, 0.8, b.at(0, top + 0.5 + R + 0.1, zT), L.gold, nil, false)
		tip = top + 0.5 + R + 0.5
	else
		local R = tw / 2 + 0.2
		b.cyl("DomeDrum", R, 1.6, b.at(0, top + 0.8, zT), L.towerWall, nil, false)
		b.cyl("DomeRing", R + 0.3, 0.4, b.at(0, top + 1.6, zT), L.gold, nil, false)
		b.ball("Dome", R, b.at(0, top + 1.7, zT), L.roof)
		b.cyl("DomeLantern", 0.9, 1.6, b.at(0, top + 1.7 + R + 0.5, zT), L.towerWall, nil, false)
		b.ball("LanternCap", 1, b.at(0, top + 1.7 + R + 1.3, zT), L.gold)
		tip = top + 1.7 + R + 2.3
	end
	if f >= 25 then
		-- the crowned golden slime on the very top
		slime(b.at(0, tip - 0.2, zT), 1.4)
		crown(b.at(0, tip + 2.2, zT), 0.7)
	elseif f >= 4 then
		b.flag(Vector3.new(0, tip - 0.2, zT), 3.4, L.cloth, L.gold)
	else
		b.rod("TowerSpike", 0.1, Vector3.new(0, tip - 0.2, zT), Vector3.new(0, tip + 1.6, zT), L.gold)
		b.ball("TowerFinial", 0.35, b.at(0, tip + 0.2, zT), L.gold)
	end

	-- DORMERS --------------------------------------------------------------------------------------------
	-- a dormer on the slope `s` at `z`, its front `uF` from the ridge line: a box out of the roof under a
	-- small gable of its own
	local function dormer(
		s: number,
		z: number,
		uF: number,
		w: number,
		h: number,
		rise: number,
		winW: number,
		winH: number
	)
		local y0 = roofY(uF)
		local run = h / pitch + 0.2
		b.box("Dormer", run, h, w, b.at(s * (uF - run / 2), y0 + h / 2, z), L.wall)
		b.gable(b.at(s * (uF - run / 2), y0 + h, z), run, w, rise, 0.3, L.roof, L.wall, L.board, L.roofMat)
		b.window(
			b.face(s * uF, y0 + h * 0.52, z, Vector3.new(s, 0, 0)),
			winW,
			winH,
			L.frame,
			L.glass,
			{ glow = L.glow } :: WindowOpts
		)
	end
	if f >= 3 then
		for _, s in { -1, 1 } do
			dormer(s, d * 0.22, half * 0.7, 2.2, 1.9, 0.9, 1.1, 1.1)
		end
	end
	if f >= 7 then
		-- a big wall gable on the left, beside the tower
		dormer(1, zT, half, 4.4, 2.6, 1.8, 1.5, 1.6)
	end

	-- THE LEAN-TO SHED along the right wall --------------------------------------------------------------
	do
		local slope = 1.5 / LEAN_OUT
		local run = LEAN_OUT + 0.6
		local zc, len = (LEAN_Z0 + LEAN_Z1) / 2, LEAN_Z1 - LEAN_Z0
		local roofCol = if era == 4 then L.roof else L.accent
		b.trim(
			"LeanRoof",
			run * math.sqrt(1 + slope ^ 2),
			0.35,
			len + 1,
			b.at(-(hw + run / 2), leanHi - slope * run / 2, zc) * CFrame.Angles(0, 0, math.atan(slope)),
			roofCol,
			if era == 4 then Enum.Material.Glass else nil
		)
		b.trim("LeanPlate", 0.3, 0.4, len + 0.6, b.at(-hw - 0.15, leanHi - 0.3, zc), L.board)
		local px = -(hw + LEAN_OUT - 0.3)
		local beamY = leanHi - slope * (LEAN_OUT - 0.3) - 0.4
		b.trim("LeanBeam", 0.4, 0.4, len + 0.6, b.at(px, beamY, zc), L.board)
		for _, z in { LEAN_Z0 + 0.3, zc, LEAN_Z1 - 0.3 } do
			if era == 5 then
				b.cyl("LeanPost", 0.35, beamY - 0.2 - FLOOR, b.at(px, (FLOOR + beamY - 0.2) / 2, z), L.beam)
			else
				b.box("LeanPost", 0.5, beamY - 0.2 - FLOOR, 0.5, b.at(px, (FLOOR + beamY - 0.2) / 2, z), L.board)
				b.beam(
					"LeanBrace",
					0.3,
					0.3,
					Vector3.new(px, beamY - 1.5, z),
					Vector3.new(px + 1.3, beamY + 0.1, z),
					L.board
				)
			end
		end
		if f >= 8 then
			for _, z in { zc - len / 4, zc + len / 4 } do
				b.rod("LeanLampChain", 0.05, Vector3.new(px, beamY - 0.2, z), Vector3.new(px, beamY - 0.8, z), IRON)
				b.trim("LeanLamp", 0.5, 0.7, 0.5, b.at(px, beamY - 1.15, z), L.glass, Enum.Material.Neon)
			end
		end
	end

	-- THE SILOS behind the lean-to -----------------------------------------------------------------------
	do
		local sr, sh = L.siloR, L.siloH
		local x1, z1 = -(hw + 0.9 + sr), 12.4 + sr
		local spots = {} :: { { number } } -- x, z, height
		if f >= 1 then
			table.insert(spots, { x1, z1, sh })
		end
		if f >= 2 then
			table.insert(spots, { x1 - (2 * sr + 1), z1, sh * 0.86 })
		end
		if f >= 11 then
			table.insert(spots, { x1 - (sr + 0.5), z1 + sr * 1.95, sh * 1.12 })
		end
		for i, s in spots do
			local x, z, h = s[1], s[2], s[3]
			b.cyl("SiloPad", sr + 1.1, 0.4, b.at(x, 0.2, z), L.stone)
			b.silo(x, 0.4, z, sr, h, L.siloDrum, L.siloHoop, L.siloCap, L.siloCapColour, L.goo)
			local capTop = 0.4 + 0.8 + h + (if L.siloCap == "cone" then 0.3 + sr * 1.3 + 0.5 else sr + 0.7)
			if f >= 22 and L.siloCap == "dome" then
				crown(b.at(x, capTop - 0.5, z), 0.8)
				capTop += 0.5
			end
			table.insert(tips, Vector3.new(x, capTop, z))
			if era == 4 and i > 1 then
				-- copper pipes link the goo silos
				local y = 0.4 + 0.8 + spots[1][3] * 0.3
				b.rod("SiloPipe", 0.3, Vector3.new(spots[1][1], y, spots[1][2]), Vector3.new(x, y, z), L.accent)
			end
		end
		if era == 4 and #spots >= 1 then
			-- and one feeds the hall, with a valve wheel
			local y = 0.4 + 0.8 + sh * 0.6
			b.rod("SiloPipe", 0.3, Vector3.new(x1, y, z1), Vector3.new(-hw, y, z1), L.accent)
			b.disc("SiloValve", 0.6, 0.15, b.face(-hw - 0.45, y, z1 - 0.4, FRONT), L.gold)
		end
	end

	-- TURRETS on the front corners -----------------------------------------------------------------------
	local function turret(s: number)
		local tx, tz, tr = s * half, -jet, 1.6
		local y0 = (if L.lowerH then lowerTop else wallH * 0.55) - 1.5
		local tTop = wallH + 2.6
		for i = 1, 3 do
			b.cyl(
				"TurretCorbel",
				tr * (0.35 + 0.2 * i),
				0.5,
				b.at(tx, y0 + (i - 0.5) * 0.5, tz),
				L.surround,
				nil,
				false
			)
		end
		b.cyl("Turret", tr, tTop - y0 - 1.5, b.at(tx, (y0 + 1.5 + tTop) / 2, tz), L.towerWall, nil, false)
		b.cyl("TurretBand", tr + 0.2, 0.4, b.at(tx, tTop - 0.2, tz), L.board, nil, false)
		b.window(
			b.face(tx, tTop - 2.2, tz - tr + 0.05, FRONT),
			0.7,
			1.3,
			L.frame,
			L.glass,
			{ glow = L.glow } :: WindowOpts
		)
		local tTip: number
		if era == 3 then
			b.cone(b.at(tx, tTop, tz), tr + 0.5, 3.6, 5, L.roof, L.gold)
			tTip = tTop + 4.1
		else
			b.ball("TurretDome", tr, b.at(tx, tTop, tz), if era == 4 then L.gold else L.roof)
			b.ball("Finial", 0.3, b.at(tx, tTop + tr + 0.2, tz), L.gold)
			tTip = tTop + tr + 0.4
		end
		table.insert(tips, Vector3.new(tx, tTip, tz))
	end
	if f >= 12 then
		turret(1)
	end
	if f >= 13 then
		turret(-1)
	end

	-- THE ENGINE HOUSE at the back of the left wall, with its stack --------------------------------------
	if engine then
		local ez1 = d
		local ew, eh = 5, wallH * 0.5
		local ezc, exc, elen = (engineZ0 + ez1) / 2, hw + ew / 2, ez1 - engineZ0
		b.box("EngineFoot", ew + 0.3, BASE, elen + 0.3, b.at(exc, BASE / 2, ezc), L.stone)
		b.box("EngineHouse", ew, eh - BASE, elen, b.at(exc, (BASE + eh) / 2, ezc), L.lower)
		b.wedge(
			"EngineRoof",
			elen + 0.8,
			1.8,
			ew + 0.7,
			b.at(exc + 0.35, eh + 0.9, ezc) * CFrame.Angles(0, -math.pi / 2, 0),
			L.roof,
			L.roofMat
		)
		local glowing: WindowOpts = { glow = true, arch = era == 5 }
		b.window(b.face(exc, BASE + (eh - BASE) * 0.5, engineZ0, FRONT), 1.8, 2.2, L.frame, L.goo or L.glass, glowing)
		b.window(b.face(hw + ew, BASE + (eh - BASE) * 0.5, ezc, LEFT), 1.8, 2.2, L.frame, L.goo or L.glass, glowing)
		local sx, sz, st = hw + ew - 1.3, ez1 - 1.4, wallH + 3
		b.cyl("Stack", 0.8, st - eh, b.at(sx, (eh + st) / 2, sz), L.accent)
		for _, t in { 0.3, 0.65, 1 } do
			b.cyl("StackRing", 0.95, 0.35, b.at(sx, eh + (st - eh) * t - 0.2, sz), L.gold, nil, false)
		end
		b.cyl("StackGlow", 0.6, 0.2, b.at(sx, st + 0.05, sz), L.goo or L.glass, Enum.Material.Neon, false)
	end

	-- THE PORTICO of the capital -------------------------------------------------------------------------
	if f >= 21 then
		local colTop = doorTop + 1
		for _, x in { -(dockHW - 0.6), -(dockHW - 1.85), dockHW - 1.85, dockHW - 0.6 } do
			b.cyl("Column", 0.55, colTop - BASE - 0.8, b.at(x, (BASE + 0.4 + colTop - 0.4) / 2, -3), L.wall)
			b.cyl("ColumnFoot", 0.75, 0.4, b.at(x, BASE + 0.2, -3), L.beam, nil, false)
			b.cyl("ColumnHead", 0.75, 0.4, b.at(x, colTop - 0.2, -3), L.gold, nil, false)
		end
		b.box("PorticoBeam", dockHW * 2 + 0.6, 0.9, 3.9, b.at(0, colTop + 0.45, -1.75), L.wall)
		b.trim("PorticoLine", dockHW * 2 + 0.8, 0.2, 4.1, b.at(0, colTop + 0.2, -1.75), L.gold)
		b.gable(
			b.at(0, colTop + 0.9, -1.75) * CFrame.Angles(0, math.pi / 2, 0),
			3.9,
			dockHW * 2 + 0.6,
			2,
			0.3,
			L.roof,
			L.wall,
			L.gold
		)
		if f >= 23 then
			-- golden slimes on pedestals either side of the steps
			for _, s in { -1, 1 } do
				local x = s * (dockHW + 1.3)
				b.box("Pedestal", 1.5, 1.6, 1.5, b.at(x, FLOOR + 0.8, -3.6), L.wall)
				b.trim("PedestalCap", 1.8, 0.25, 1.8, b.at(x, FLOOR + 1.7, -3.6), L.gold)
				slime(b.at(x, FLOOR + 1.8, -3.6), 0.85)
			end
		end
	end

	-- beacons and flags on the turrets and the silos
	for _, p in tips do
		if f >= 24 then
			b.flag(p - Vector3.new(0, 0.3, 0), 2.6, L.cloth, L.gold)
		end
		if f >= 19 then
			b.ball("Beacon", 0.4, b.at(p.X, p.Y + 0.1, p.Z), L.goo or L.glass, Enum.Material.Neon)
		end
	end
end

return Granary
