--!strict
-- The pantry's landmark: the village's great granary with its clock tower (village v2; the owner, 2026-11-16:
-- the buildings taller and bigger, with more fine detail, better finished and built sensibly; then, the same
-- day: as close to the reference picture as parts can come, real textures, hollow inside like a real warehouse,
-- the fourth era a steel-framed glasshouse). One building in five architectures, one an era of ten levels
-- (reference: docs/areas/village-v2/granary-ref-era5.jpg, all five on one sheet):
--   1 hamlet       thatch and plaster on brown beams, a small clock tower, wooden silos
--   2 painted      cream plaster on teal beams, red clay tiles, an arched door, a wing on the left
--   3 town         a stone ground storey under a jettied half-timbered one, a stone tower and turrets
--   4 slime tech   a steel-framed glasshouse on a brick foot, a glass-domed tower, glowing goo silos
--   5 capital      white marble and gold, a pediment with a golden slime, blue domes
-- The hall stands x -hw..hw, z 0..d, its gable and its great door to the front (-z). It is HOLLOW: walls a
-- player walks between, the door's leaves stand open, the store is inside (a loft, shelves, sacks, crates).
-- The tower rises from the ridge on two tie beams across the hall (its floor stays clear); a wing joins the left wall
-- (+x) from the second era; an open lean-to shed runs along the right wall (-x) and the silos stand behind it.
-- An era's first level changes the architecture; levels 6-10 of each era add one feature each, and a feature
-- once added stays in every later era (25 in all, listed in `build`).
local Architecture = require(script.Parent.Architecture)
local LibraryKit = require(script.Parent.LibraryKit)

local Granary = {}

local C = Color3.fromRGB
local M = Enum.Material
local IRON = C(60, 60, 66)
local DARK = C(42, 34, 30)
local WHITE = C(250, 248, 240)
local PLANK = C(176, 128, 78) -- floors, crates, barrels
local SACK = C(214, 190, 140)
local HAY = C(226, 186, 90)
local BASE = 1.2 -- the hall's stone foot: its floor stands a step above the yard
local FLOOR = 0.4 -- the yard's paving over the lawn
local T = 0.6 -- how thick a wall is
local FRONT = Vector3.new(0, 0, -1)
local LEFT, RIGHT = Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0) -- (as one walks in: +x is the left)
-- the lean-to along the right wall, front to back, and where the wing on the left begins
local LEAN_Z0, LEAN_Z1, LEAN_OUT = 1.6, 10.2, 6.2
local LEAN_SLOPE = 1.6 / LEAN_OUT
local WING_Z0 = 1.6
-- the shell's parts that an era's Blender body stands for (see THE BODY FROM BLENDER in `raise`)
local SHELL: { [string]: boolean } = {}
for name in
	string.gmatch(
		"Plinth Wall Rail Post Brace Roof Gable BargeBoard Ridge EaveRoll TieBeam KingPost Strut WindowFrame WindowGlass "
			.. "WindowBar WindowSill WindowHead WindowHeadGlass Shutter Dock DockStep DoorLeaf DoorBand DoorBrace DoorJamb "
			.. "DoorLintel Tower TowerTie TowerPost TowerLeg TowerString TowerCornice TowerEave LeanRoof LeanPlate LeanBeam "
			.. "LeanPost LeanBrace LeanKnee LeanRafter",
		"%a+"
	)
do
	SHELL[name] = true
end

type WindowOpts = { shutters: Color3?, arch: boolean?, flowers: boolean?, glow: boolean?, through: number? }
type Wing = { out: number, len: number, wallH: number, rise: number }
type Look = {
	hw: number, -- half the hall's width
	d: number, -- its depth
	wallH: number, -- the walls' top
	rise: number, -- the roof over the walls
	over: number, -- the roof's overhang
	doorW: number,
	doorH: number,
	lowerH: number?, -- the ground storey ends here and another wall begins (stone under plaster, brick under glass)
	jet: number, -- how far the upper storey stands out over the lower
	glassWalls: boolean, -- the upper walls are glass in a frame (no windows in them)
	floors: { number }, -- the frame's bands, foot to top
	rows: { { number } }, -- rows of windows: the middle's height, width, height, 1 for a round head
	timber: boolean,
	wing: Wing?, -- the wing on the left: how far out, how long, its walls' top, its roof's rise
	wall: Color3,
	lower: Color3,
	stone: Color3,
	beam: Color3,
	board: Color3,
	surround: Color3,
	roof: Color3,
	roof2: Color3, -- the lean-to's roof
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
	towerCap: Color3,
	spire: number,
	siloR: number,
	siloH: number,
	siloDrum: Color3,
	siloHoop: Color3,
	siloCap: string,
	siloCapColour: Color3,
	goo: Color3?,
	mats: { [string]: Enum.Material }, -- what each colour above is made of (the field's name -> the material)
}

local LOOKS: { Look } = {
	{
		hw = 8.5,
		d = 12,
		wallH = 9,
		rise = 7.5,
		over = 1.5,
		doorW = 7.6,
		doorH = 6.6,
		jet = 0,
		glassWalls = false,
		floors = { BASE, 9 },
		rows = { { 4.6, 1.5, 1.9, 0 } },
		timber = true,
		wall = C(236, 220, 180),
		lower = C(236, 220, 180),
		stone = C(150, 146, 138),
		beam = C(110, 72, 42),
		board = C(110, 72, 42),
		surround = C(110, 72, 42),
		roof = C(232, 190, 84),
		roof2 = C(232, 190, 84),
		door = C(150, 98, 54),
		band = IRON,
		frame = C(110, 72, 42),
		glass = C(255, 214, 120),
		glow = false,
		shutters = C(120, 150, 96),
		accent = C(214, 172, 74),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		tower = 5.5,
		towerWall = C(236, 220, 180),
		towerRoof = "pyramid",
		towerCap = C(232, 190, 84),
		spire = 4.6,
		siloR = 2.3,
		siloH = 8.5,
		siloDrum = C(170, 116, 66),
		siloHoop = C(96, 70, 50),
		siloCap = "cone",
		siloCapColour = C(214, 172, 74),
		mats = {
			wall = M.Plaster,
			stone = M.Cobblestone,
			beam = M.Wood,
			roof = M.Sand, -- (thatch: the one roof Studio has no material for; sand's ripples read as its layers)
			accent = M.Sand,
			door = M.WoodPlanks,
			gold = M.Foil,
			siloDrum = M.WoodPlanks,
			siloHoop = M.Metal,
		},
	},
	{
		hw = 10,
		d = 14,
		wallH = 9.4,
		rise = 9.5,
		over = 1.2,
		doorW = 8.6,
		doorH = 7.2,
		jet = 0,
		glassWalls = false,
		floors = { BASE, 5.3, 9.4 },
		rows = { { 4, 1.5, 1.9, 0 }, { 7.6, 1.3, 1.5, 0 } },
		timber = true,
		wing = { out = 8, len = 9, wallH = 6, rise = 3.6 },
		wall = C(244, 238, 224),
		lower = C(244, 238, 224),
		stone = C(156, 152, 146),
		beam = C(40, 128, 130),
		board = C(32, 104, 108),
		surround = C(40, 128, 130),
		roof = C(198, 70, 58),
		roof2 = C(198, 70, 58),
		door = C(146, 96, 56),
		band = IRON,
		frame = WHITE,
		glass = C(255, 222, 140),
		glow = false,
		shutters = C(56, 146, 146),
		accent = C(52, 150, 150),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		tower = 6.5,
		towerWall = C(244, 238, 224),
		towerRoof = "pyramid",
		towerCap = C(52, 150, 150),
		spire = 6.5,
		siloR = 2.5,
		siloH = 10.5,
		siloDrum = C(236, 228, 208),
		siloHoop = C(32, 104, 108),
		siloCap = "cone",
		siloCapColour = C(52, 150, 150),
		mats = {
			wall = M.Plaster,
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.ClayRoofTiles,
			accent = M.ClayRoofTiles,
			door = M.WoodPlanks,
			gold = M.Foil,
			siloDrum = M.WoodPlanks,
		},
	},
	{
		hw = 11,
		d = 16,
		wallH = 11.8,
		rise = 10,
		over = 1.2,
		doorW = 9.6,
		doorH = 8.2,
		lowerH = 9.6,
		jet = 0.3,
		glassWalls = false,
		floors = { 9.6, 11.8 },
		rows = { { 4.4, 1.5, 2, 1 }, { 10.75, 1.3, 1.4, 0 } },
		timber = true,
		wing = { out = 8.5, len = 9.6, wallH = 7, rise = 4 },
		wall = C(240, 230, 206),
		lower = C(170, 166, 158),
		stone = C(128, 124, 118),
		beam = C(112, 72, 44),
		board = C(112, 72, 44),
		surround = C(206, 200, 188),
		roof = C(190, 62, 50),
		roof2 = C(190, 62, 50),
		door = C(104, 66, 44),
		band = IRON,
		frame = C(112, 72, 44),
		glass = C(255, 222, 140),
		glow = false,
		accent = C(190, 62, 50),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		tower = 7.5,
		towerWall = C(176, 172, 166),
		towerRoof = "pyramid",
		towerCap = C(190, 62, 50),
		spire = 7.5,
		siloR = 2.8,
		siloH = 12.5,
		siloDrum = C(176, 172, 166),
		siloHoop = C(128, 124, 118),
		siloCap = "cone",
		siloCapColour = C(190, 62, 50),
		mats = {
			wall = M.Plaster,
			lower = M.Brick,
			stone = M.Cobblestone,
			beam = M.Wood,
			surround = M.Limestone,
			roof = M.ClayRoofTiles,
			door = M.WoodPlanks,
			gold = M.Foil,
			towerWall = M.Brick,
		},
	},
	{
		hw = 11.5,
		d = 17,
		wallH = 12,
		rise = 9,
		over = 1,
		doorW = 10,
		doorH = 8.4,
		lowerH = 5.8,
		jet = 0,
		glassWalls = true,
		floors = { 5.8, 8.9, 12 },
		rows = { { 3.6, 1.6, 2, 0 } },
		timber = true,
		wing = { out = 8.5, len = 10, wallH = 7, rise = 3.4 },
		-- (the owner, 2026-11-16: "the fourth era is a steel-framed glasshouse": glass in a dark steel frame on a
		-- brick foot, brick piers at the door and the corners, as the reference has it)
		wall = C(150, 225, 235),
		lower = C(198, 112, 74),
		stone = C(74, 80, 92),
		beam = C(58, 72, 96),
		board = C(58, 72, 96),
		surround = C(58, 72, 96),
		roof = C(62, 96, 160), -- (blue slate over the glass, as the reference has it)
		roof2 = C(62, 96, 160),
		door = C(150, 94, 54),
		band = C(58, 72, 96),
		frame = C(58, 72, 96),
		glass = C(120, 230, 235),
		glow = true,
		accent = C(196, 112, 66),
		cloth = C(40, 80, 160),
		gold = C(224, 170, 70),
		tower = 8,
		towerWall = C(90, 200, 220),
		towerRoof = "glass",
		towerCap = C(90, 200, 220),
		spire = 0,
		siloR = 3,
		siloH = 13.5,
		siloDrum = C(190, 240, 200),
		siloHoop = C(58, 72, 96),
		siloCap = "dome",
		siloCapColour = C(48, 84, 140),
		goo = C(96, 232, 70),
		mats = {
			wall = M.Glass,
			lower = M.Brick,
			stone = M.Slate,
			beam = M.Metal,
			roof = M.RoofShingles,
			towerWall = M.Glass,
			door = M.WoodPlanks,
			accent = M.Foil,
			gold = M.Foil,
			siloCapColour = M.Metal,
		},
	},
	{
		hw = 12,
		d = 18,
		wallH = 12.8,
		rise = 6.5,
		over = 1,
		doorW = 10,
		doorH = 8.6,
		jet = 0,
		glassWalls = false,
		floors = {},
		rows = { { 4.6, 1.6, 2.4, 1 }, { 11.15, 1.5, 1.5, 0 } },
		timber = false,
		wing = { out = 9, len = 10, wallH = 7.6, rise = 2.6 },
		wall = C(250, 249, 245),
		lower = C(250, 249, 245),
		stone = C(214, 208, 196),
		beam = C(228, 222, 210),
		board = C(236, 192, 76),
		surround = C(236, 192, 76),
		roof = C(44, 84, 170),
		roof2 = C(44, 84, 170),
		door = C(52, 90, 166),
		band = C(236, 192, 76),
		frame = C(236, 192, 76),
		glass = C(130, 220, 240),
		glow = false,
		accent = C(40, 80, 164),
		cloth = C(40, 70, 160),
		gold = C(236, 192, 76),
		tower = 8.5,
		towerWall = C(250, 249, 245),
		towerRoof = "dome",
		towerCap = C(44, 84, 170), -- (the owner, 2026-11-17: a dome wears its era's roof, colour and tiles)
		spire = 0,
		siloR = 3,
		siloH = 14.5,
		siloDrum = C(246, 204, 96), -- (brushed metal, which darkens it: as bright foil the drums outshone the hall)
		siloHoop = C(250, 249, 245),
		siloCap = "dome",
		siloCapColour = C(44, 84, 170),
		mats = {
			wall = M.Marble,
			stone = M.Marble,
			beam = M.Marble,
			gold = M.Foil,
			roof = M.ClayRoofTiles,
			door = M.WoodPlanks,
			accent = M.Metal,
			siloDrum = M.Metal,
		},
	},
}

-- A level's era (1-5) and how many of the 25 features it has.
function Granary.features(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	return era, (era - 1) * 5 + math.max(0, s - 5)
end

-- What Architecture.grow takes as the house (all of it: hall, wing and silos) and the point it grows round.
local SPLIT_Z, PIVOT_X, PIVOT_Z = -100, 0, 0

function Granary.halfWidth(level: number): number
	return LOOKS[(Granary.features(level))].hw
end

-- The ground beside and behind the yard (which ends at x +-16.8 and z 10) that the hall's back, the wing, the
-- silos and the hay store on the left may stand on (x0, x1, z0, z1): scenery there goes.
function Granary.footprint(level: number): (number, number, number, number)
	local L = LOOKS[(Granary.features(level))]
	return Architecture.grownBox(
		"Granary",
		SPLIT_Z,
		PIVOT_X,
		PIVOT_Z,
		-(L.hw + 4 * L.siloR + 4),
		L.hw + 17,
		0,
		math.max(L.d, 12.4 + L.siloR * 4.5) + 2
	)
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

local function raise(m: Instance, frame: CFrame, level: number)
	local era, f = Granary.features(level)
	local L = LOOKS[era]
	local skins: { [string]: Enum.Material } = {
		[IRON:ToHex()] = M.Metal,
		[PLANK:ToHex()] = M.WoodPlanks,
		[SACK:ToHex()] = M.Fabric,
		[HAY:ToHex()] = M.Sand,
	}
	for field, material in L.mats do
		skins[((L :: any)[field] :: Color3):ToHex()] = material
	end
	local b = Architecture.new(m, frame, skins, if L.glassWalls then 0.2 else nil)
	local hw, d, wallH, dw = L.hw, L.d, L.wallH, L.doorW
	local lowerTop = L.lowerH or wallH
	local jet = L.jet
	local half = hw + jet -- half the roof's span
	local pitch = L.rise / half
	local ridge = wallH + L.rise
	local doorTop = BASE + L.doorH
	local arched = era >= 2
	-- the great door is nearly half the front, as the reference has it; its arch is a low half-ellipse in three
	-- straight cuts a side (it must lie whole inside one storey of the wall)
	local R = if arched then dw * 0.36 else 0 -- the arch's rise
	local spring = doorTop - R
	local function archAt(k: number, grow: number): (number, number) -- its point `k` (0 the jamb, 3 the crown)
		local t = math.rad(k * 30)
		return (dw / 2 + grow) * math.cos(t), spring + (R + grow) * math.sin(t)
	end
	local W = L.wing
	local wz1 = WING_Z0 + (if W then W.len else 0)
	local wingRidge = if W then W.wallH + W.rise else 0
	local function roofY(u: number): number -- the roof's height `u` from the ridge line
		return ridge - pitch * math.abs(u)
	end
	local tips: { Vector3 } = {} -- the tops of turrets and silos (beacons, flags)
	local glowMat = if L.glow then M.Neon else nil

	-- a wall or a floor from corner to corner
	local function slab(
		name: string,
		x0: number,
		x1: number,
		y0: number,
		y1: number,
		z0: number,
		z1: number,
		colour: Color3
	)
		if x1 - x0 > 0.05 and y1 - y0 > 0.05 and z1 - z0 > 0.05 then
			b.box(name, x1 - x0, y1 - y0, z1 - z0, b.at((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour)
		end
	end
	-- the hall's storeys: foot, top, colour, how far out it stands
	local storeys: { { any } } = { { BASE, lowerTop, L.lower, 0 } }
	if L.lowerH then
		local upper: { any } = { lowerTop, wallH, L.wall, jet }
		table.insert(storeys, upper)
	end

	-- A statue of a slime: the game's own body (ClientKit.SlimeBody, in the living slimes' glossy skin, tinted gold)
	-- with the owner's own face pictures standing on its skin, as SlimeFace does for the living ones. `cf` at its
	-- foot, looking along -Z; `r` is half its width. Returns its height (the tip is thin: a crown sits at 0.8 of it).
	local function slime(cf: CFrame, r: number, colour: Color3?, material: Enum.Material?): number
		return b.slime(cf, r, colour or L.gold, material)
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
	-- THE BLENDER PIECES (docs/areas/village-v2/hard-pieces.md): the shapes parts cannot reach, as meshes of the library
	-- kit, each scaled from its drawing of one stud. `piece` is nil while a mesh is not there (not uploaded yet, or it
	-- did not load): the caller then builds its stand-in from parts.
	local function piece(
		name: string,
		cf: CFrame,
		sx: number,
		sy: number,
		sz: number,
		colour: Color3,
		material: Enum.Material?
	): BasePart?
		local src = LibraryKit.find(name)
		return if src then b.mesh(src, cf, Vector3.new(sx, sy, sz), colour, material) else nil
	end
	-- THE OWNER'S MESHY PIECES wear their own picture: unpainted, stretched from their size in Config.LibraryKit
	local function painted(name: string, cf: CFrame, sx: number, sy: number?, sz: number?): BasePart?
		return piece(name, cf, sx, sy or sx, sz or sx, Color3.new(1, 1, 1), M.SmoothPlastic)
	end
	-- the crowned golden slime, `r` half its width, its foot at `cf`: the owner's statue on its plinth, and until it
	-- comes the game's own slime (under a crown of parts `crownR` round)
	local function statue(cf: CFrame, r: number, crownR: number?)
		if not painted("SlimeStatue_Gold", cf, r) then
			local tall = slime(cf, r)
			if crownR then
				crown(cf * CFrame.new(0, tall * 0.8, 0), crownR)
			end
		end
	end
	-- a tiled cone roof `r` round at the eave and `rise` high, the middle of its foot at `cf`: its height, finial and all
	local function coneRoof(cf: CFrame, r: number, rise: number, colour: Color3): number?
		if not piece("ConeRoof_Tiles", cf, r, rise / 1.3, r, colour) then
			return nil
		end
		local s = r * 1.3
		piece("ConeRoof_Finial", cf * CFrame.new(0, rise - 0.04 * s, 0), s, s, s, L.gold)
		return rise + 0.2 * s
	end
	-- a dome of panes in a ribbed frame, `r` round: its height
	local function ribDome(cf: CFrame, r: number, panes: Color3): number?
		if not piece("GlassDome_Frame", cf, r, r, r, L.beam) then
			return nil
		end
		piece("GlassDome_Glass", cf, r, r, r, panes)
		piece("GlassDome_Finial", cf * CFrame.new(0, 0.99 * r, 0), r, r, r, L.gold)
		return 1.36 * r
	end
	-- the capital's dome, `r` round: a shell under golden ribs, a lantern (its cap 1.53-1.68 up) and a finial: its height
	local function royalDome(cf: CFrame, r: number, shell: Color3): number?
		if not piece("RoyalDome_Gold", cf, r, r, r, L.gold) then
			return nil
		end
		piece("RoyalDome_Shell", cf, r, r, r, shell)
		return 1.95 * r
	end
	-- a band round the outside of the hall's walls
	local function girdle(name: string, y: number, h: number, off: number, proud: number, colour: Color3)
		local X, z0, z1 = hw + off, -off, d + off
		b.trim(name, X * 2 + proud * 2, h, proud, b.at(0, y, z0 - proud / 2), colour)
		b.trim(name, X * 2 + proud * 2, h, proud, b.at(0, y, z1 + proud / 2), colour)
		b.trim(name, proud, h, z1 - z0, b.at(X + proud / 2, y, (z0 + z1) / 2), colour)
		b.trim(name, proud, h, z1 - z0, b.at(-X - proud / 2, y, (z0 + z1) / 2), colour)
	end

	-- THE BODY FROM BLENDER (the owner, 2026-11-17: "dựng lại tất cả các công trình bằng blender", "cánh cửa chính mở
	-- nhé, và có thể đi vào bên trong nhà"): tools/blender/landmark_bodies.py models an era's whole shell on this
	-- module's own numbers, hollow, its door open, one mesh a material. Where an era's model has come, the shell below
	-- is still built but as a ghost (Architecture's `b.ghost`): its solid parts are the collision inside the model,
	-- its trim is left out. Everything a level switches on stays as it is.
	local body = "GranaryBody" .. era
	local bodied = LibraryKit.find(body .. "_Plaster") ~= nil
	local function shell(on: boolean)
		b.ghost(if on and bodied then SHELL else nil)
	end
	if bodied then
		local slots: { { any } } = {
			{ "Stone", L.stone },
			{ "Plaster", L.wall },
			{ "Timber", L.beam },
			{ "Thatch", L.roof },
			{ "Planks", L.door },
			{ "Iron", IRON },
			{ "Pane", L.glass, glowMat },
		}
		for _, slot in slots do
			piece(body .. "_" .. slot[1], b.at(0, 0, 0), 1, 1, 1, slot[2], slot[3])
		end
		-- (the model's low rails along the lean-to's open side: nothing walks through them)
		local railZ0, railZ1 = LEAN_Z0 + 0.3, LEAN_Z1 - 0.3
		b.box(
			"LeanRailStop",
			0.3,
			2.2,
			railZ1 - railZ0,
			b.at(-(hw + LEAN_OUT - 0.3), FLOOR + 1.1, (railZ0 + railZ1) / 2),
			L.board
		).Transparency =
			1
	end
	shell(true)

	-- THE HALL'S SHELL -----------------------------------------------------------------------------------
	b.box("Plinth", hw * 2 + 0.6, BASE, d + 0.6, b.at(0, BASE / 2, d / 2), L.stone)
	local floorColour = if era <= 3 then PLANK elseif era == 4 then L.stone else L.beam
	b.trim("HallFloor", hw * 2 - T * 2, 0.1, d - T * 2, b.at(0, BASE + 0.05, d / 2), floorColour)
	local holeTop = if W then W.wallH - 0.8 else 0 -- the way through the left wall into the wing
	for _, st in storeys do
		local y0, y1, colour, off = st[1] :: number, st[2] :: number, st[3] :: Color3, st[4] :: number
		local X, z0, z1 = hw + off, -off, d + off
		slab("Wall", -X, X, y0, y1, z1 - T, z1, colour) -- the back
		slab("Wall", -X, -X + T, y0, y1, z0 + T, z1 - T, colour) -- the right
		-- the left, open to the wing
		if W and y0 < holeTop then
			local yb = math.min(y1, holeTop)
			slab("Wall", X - T, X, y0, yb, z0 + T, WING_Z0 + T, colour)
			slab("Wall", X - T, X, y0, yb, wz1 - T, z1 - T, colour)
			slab("Wall", X - T, X, yb, y1, z0 + T, z1 - T, colour)
		else
			slab("Wall", X - T, X, y0, y1, z0 + T, z1 - T, colour)
		end
		-- the front, round the door and its arch
		local lo = math.min(y1, doorTop)
		for _, s in { -1, 1 } do
			slab("Wall", if s > 0 then dw / 2 else -X, if s > 0 then X else -dw / 2, y0, lo, z0, z0 + T, colour)
		end
		slab("Wall", -X, X, math.max(y0, doorTop), y1, z0, z0 + T, colour)
		if arched and y0 <= spring and y1 >= doorTop then
			for k = 0, 2 do
				local px, py = archAt(k, 0)
				local qx, qy = archAt(k + 1, 0)
				for _, s in { -1, 1 } do
					slab("Wall", if s > 0 then qx else -px, if s > 0 then px else -qx, qy, doorTop, z0, z0 + T, colour)
					-- (a wedge turned over: its square corner up and out, its slope one cut of the arch)
					b.wedge(
						"Wall",
						T,
						qy - py,
						px - qx,
						frame
							* CFrame.fromMatrix(
								Vector3.new(s * (px + qx) / 2, (py + qy) / 2, z0 + T / 2),
								Vector3.new(0, 0, s),
								Vector3.new(0, -1, 0),
								Vector3.new(s, 0, 0)
							),
						colour
					)
				end
			end
		end
	end
	if L.lowerH and jet > 0 then
		girdle("Jetty", lowerTop, 0.45, jet, 0.15, L.beam)
		-- quoins up the stone storey's front corners
		for _, s in { -1, 1 } do
			for i = 0, 4 do
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
	if L.glassWalls then
		-- brick piers at the front corners, a stone cap on each and along the brick foot
		for _, s in { -1, 1 } do
			b.box("Pier", 1.4, spring - BASE, 1.4, b.at(s * (hw - 0.5), (BASE + spring) / 2, 0.5), L.lower)
			b.trim("PierCap", 1.7, 0.35, 1.7, b.at(s * (hw - 0.5), spring + 0.17, 0.5), L.stone)
		end
		girdle("FootCap", lowerTop, 0.3, 0, 0.2, L.stone)
	end

	-- the frame: bands of timber (steel on the glasshouse) on the sides, and on the front either side of the door
	local inner = dw / 2 + 0.9
	if L.timber then
		for i = 1, #L.floors - 1 do
			local y0, y1 = L.floors[i], L.floors[i + 1]
			local off = if y0 >= lowerTop then jet else 0
			local y, h = (y0 + y1) / 2, y1 - y0
			-- (under the eaves the side walls' top rail stops short: at the walls' full height it stood out of the
			-- roof's slope as a dark line)
			local cut = if i == #L.floors - 1 then 0.45 else 0
			local sy, sh = y - cut / 2, h - cut
			if W and y0 < holeTop then
				-- (no posts across the way into the wing)
				local len = d + off - wz1
				b.timber(b.face(hw + off, sy, wz1 + len / 2, LEFT), len, sh, L.beam)
			else
				b.timber(b.face(hw + off, sy, d / 2, LEFT), d + off * 2, sh, L.beam)
			end
			b.timber(b.face(-hw - off, sy, d / 2, RIGHT), d + off * 2, sh, L.beam)
			b.timber(b.face(0, y, d + off, Vector3.new(0, 0, 1)), (hw + off) * 2, h, L.beam)
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
			if not (W and z > WING_Z0 and z < wz1) then
				pilaster(b.face(hw, BASE, z, LEFT))
			end
			pilaster(b.face(-hw, BASE, z, RIGHT))
		end
		for _, x in { -hw + 0.45, -inner, inner, hw - 0.45 } do
			pilaster(b.face(x, BASE, 0, FRONT))
		end
		girdle("Entablature", wallH - 0.35, 0.7, 0, 0.25, L.beam)
		girdle("EntablatureLine", wallH - 0.75, 0.2, 0, 0.35, L.gold)
	end

	-- the roof, its ridge front to back
	local roofAt = b.at(0, wallH, d / 2) * CFrame.Angles(0, math.pi / 2, 0)
	b.gable(
		roofAt,
		d + jet * 2,
		half * 2,
		L.rise,
		L.over,
		L.roof,
		L.wall,
		L.board,
		nil,
		if era == 1 then 1.1 else nil -- thatch is thick
	)
	if era == 1 then
		-- thatch ends in a thick roll along each eave (the owner's choice, 2026-11-17: the Meshy straw laid over the
		-- slabs showed in patches)
		for _, s in { -1, 1 } do
			local u = half + L.over - 0.3
			b.trim("EaveRoll", 0.9, 0.7, d + L.over * 2, b.at(s * u, roofY(u) - 0.15, d / 2), L.accent)
		end
	end
	local tw, zT = L.tower, d * 0.55
	if f >= 18 then
		-- a golden crest along the ridge
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
	b.trim("TieBeam", half * 2 - 0.8, 0.5, 0.35, gf(0, wallH) * CFrame.new(0, 0, -0.12), L.board)
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
	if era <= 3 then
		-- ivy up the front's left corner and along under the eave (the owner's Meshy piece, modelled thick: flattened)
		painted("Ivy_Corner", b.face(half - 2.9, wallH - 3.1, -jet, FRONT), 1, 1, 0.4)
	end
	if era == 5 then
		-- the golden slime of the pediment, on a blue round with a golden rim: the owner's crest behind his statue
		if painted("Crest_Gold", gf(0, wallH + 2.9), 3) then
			statue(b.at(0, wallH + 0.7, -jet - 0.1), 1.6, 0.6)
		else
			b.disc("CrestRim", 3, 0.2, gf(0, wallH + 2.9) * CFrame.new(0, 0, -0.1), L.gold)
			b.disc("CrestField", 2.75, 0.26, gf(0, wallH + 2.9) * CFrame.new(0, 0, -0.1), L.roof)
			statue(b.at(0, wallH + 0.7, -jet - 0.1), 2.2, 0.8)
		end
	elseif era == 4 then
		-- the glowing slime in the glass gable
		slime(b.at(0, wallH + 0.6, -jet + 0.15), 2, L.goo, M.Neon)
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
		local ropeEnd = y - 1.1 -- (a long rope swung the sack across the round window)
		b.rod("JibRope", 0.06, Vector3.new(0, y - 0.5, z1 + 0.4), Vector3.new(0, ropeEnd, z1 + 0.4), SACK)
		b.ball("JibSack", 0.75, b.at(0, ropeEnd - 0.6, z1 + 0.4), SACK)
		b.cyl("JibSackNeck", 0.25, 0.4, b.at(0, ropeEnd + 0.1, z1 + 0.4), C(190, 160, 110), nil, false)
	end
	if f >= 16 and era == 4 then
		-- the gear over the door
		local face, r = b.face(0, doorTop + 1.3, 0, FRONT), 1.1
		local s = r * 2.5 / 1.994 -- (its teeth as far out as the stand-in's)
		-- (a dark plate behind it: brass teeth on pale glass could not be read)
		b.disc("GearBack", r * 1.35, 0.1, face * CFrame.new(0, 0, -0.05), L.beam)
		if piece("Gear_Wheel", face * CFrame.new(0, 0, -0.35), s, s, 0.8, L.gold) then
			-- (the goo glows between its spokes)
			b.disc("GearEye", r * 0.95, 0.16, face * CFrame.new(0, 0, -0.08), L.glass, M.Neon)
		else
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
			b.disc("GearEye", r * 0.45, 0.4, face * CFrame.new(0, 0, -0.32), L.glass, M.Neon)
		end
	end

	-- THE GREAT DOOR, its leaves open -----------------------------------------------------------------------
	local function df(x: number, y: number): CFrame
		return b.face(x, y, 0, FRONT)
	end
	local dockHW = dw / 2 + 1.5
	local leafW, leafH = dw / 2 - 0.06, spring - BASE
	-- the capital's leaves open into the hall (its portico stands before the door); the others out onto the dock,
	-- which is as deep as a leaf is wide
	local inward = era == 5
	local dockD = if inward then 3.6 else leafW + 0.6
	b.box("Dock", dockHW * 2, BASE, dockD, b.at(0, BASE / 2, -dockD / 2), L.stone)
	b.box(
		"DockStep",
		dockHW * 2 - 1,
		FLOOR + (BASE - FLOOR) / 2,
		1.2,
		b.at(0, (FLOOR + (BASE - FLOOR) / 2) / 2, -dockD - 0.6),
		L.stone
	)
	for _, s in { -1, 1 } do
		-- (each leaf swung past square, so the whole doorway shows the store inside)
		local swing = math.rad(100)
		local dir = Vector3.new(-s * math.cos(swing), 0, (if inward then 1 else -1) * math.sin(swing))
		local mid = Vector3.new(s * dw / 2, BASE + leafH / 2, if inward then T + 0.2 else -0.2) + dir * (leafW / 2)
		local leaf = frame * CFrame.fromMatrix(mid, dir, Vector3.yAxis)
		b.trim("DoorLeaf", leafW, leafH, 0.3, leaf, L.door)
		for _, t in { 0.22, 0.78 } do
			b.trim(
				"DoorBand",
				leafW - 0.3,
				0.22,
				0.42,
				leaf * CFrame.new(0, leafH * (t - 0.5), 0),
				L.band,
				if era == 4 then M.Neon else nil
			)
		end
		b.beam(
			"DoorBrace",
			0.4,
			0.22,
			(mid - dir * (leafW / 2 - 0.3)) - Vector3.new(0, leafH * 0.28 - 0.1, 0),
			(mid + dir * (leafW / 2 - 0.3)) + Vector3.new(0, leafH * 0.28 - 0.1, 0),
			L.band
		)
		-- the jambs: brick piers on the glasshouse, stone buttresses on the town's hall
		local jw = if L.glassWalls then 1.3 elseif era == 3 then 1.1 else 0.55
		local jh = spring - BASE
		b.trim(
			"DoorJamb",
			jw,
			jh,
			T + 0.5,
			df(s * (dw / 2 + jw / 2), BASE + jh / 2) * CFrame.new(0, 0, T / 2 - 0.15),
			if L.glassWalls then L.lower else L.surround
		)
		if arched then
			-- the arch's ring: a stone along each cut
			local zc = T / 2 - 0.15
			for k = 0, 2 do
				local px, py = archAt(k, 0.25)
				local qx, qy = archAt(k + 1, 0.25)
				b.beam("DoorArch", T + 0.5, 0.6, Vector3.new(s * px, py, zc), Vector3.new(s * qx, qy, zc), L.surround)
			end
			b.trim("DoorImpost", jw + 0.4, 0.35, T + 0.7, b.at(s * (dw / 2 + jw / 2), spring, zc), L.surround)
		end
	end
	-- (the gear sits over the arch in the keystone's place: the gold block hid its lower half)
	local geared = f >= 16 and era == 4
	if arched and not geared then
		b.trim("Keystone", 1, 1.3, T + 0.7, b.at(0, doorTop + 0.3, T / 2 - 0.15), if era == 3 then L.stone else L.gold)
	elseif not arched then
		b.trim("DoorLintel", dw + 1.7, 0.6, T + 0.5, b.at(0, doorTop + 0.3, T / 2 - 0.15), L.surround)
	end
	-- (the threshold: the marker the slimes carry to)
	b.trim("Door", dw - 0.2, 0.12, T + 0.2, b.at(0, BASE + 0.06, T / 2), L.surround)

	-- lanterns either side of the door (one of them a real light), banners over them
	local sideX = dw / 2 + (if L.glassWalls then 2.1 else 1.5)
	for _, s in { -1, 1 } do
		b.lantern(df(s * sideX, BASE + 2.4), L.glass, IRON, s < 0)
		if f >= 6 then
			local top = math.min(wallH - 0.5, doorTop + 1.4)
			local z = if top > lowerTop then -jet else 0
			-- (short enough to end above the lantern under it)
			local h = math.min(2.6, top - BASE - 4)
			if not painted("Banner_SlimeBlue", b.face(s * (sideX + 0.1), top - h / 2, z, FRONT), h / 5) then
				b.banner(b.face(s * (sideX + 0.1), top, z, FRONT), 1.1, h, L.cloth, L.gold)
			end
		end
	end

	-- THE WINDOWS ----------------------------------------------------------------------------------------
	-- the lean-to roof's height at the wall. Under the thatch's deep eave it would cut through the roof, so there
	-- it carries the thatch on at a flatter pitch from the eave's edge (a catslide)
	local leanHi = math.min(wallH - 0.6, 8.2)
	if era == 1 then
		local tuck = L.over - 0.4
		leanHi = roofY(half + tuck) - 0.1 + LEAN_SLOPE * tuck
	end
	for ri, row in L.rows do
		local low = ri == 1 -- (flower boxes and awnings on the ground floor's windows only)
		local y, w, h, round = row[1], row[2], row[3], row[4] == 1
		local up = L.lowerH ~= nil and y > lowerTop
		local off = if up then jet else 0
		local function opts(flowers: boolean): WindowOpts
			return {
				shutters = if round then nil else L.shutters,
				arch = round,
				flowers = flowers,
				glow = L.glow,
				through = T,
			}
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
				b.window(b.face(s * wx, y, -off, FRONT), w, h, L.frame, L.glass, opts(f >= 4 and low))
				if f >= 9 and low then
					local head = y + h / 2 + (if round then w / 2 + 0.5 else 0.55)
					b.awning(b.face(s * wx, head, -off, FRONT), w + 1.8, 1.5, L.cloth, WHITE)
				end
			end
		end
		-- the sides and the back: between the posts; none behind the lean-to or the wing, none in glass walls
		if not L.glassWalls then
			local centres = bayCentres(d + off * 2)
			local first, last = 2, #centres - 1
			if not L.timber then
				first, last = 1, #centres
			end
			for i = first, last do
				local z = d / 2 + centres[i]
				if not (W and z > WING_Z0 - 1 and z < wz1 + 1 and y - h / 2 < wingRidge + 0.3) then
					b.window(b.face(hw + off, y, z, LEFT), w, h, L.frame, L.glass, opts(false))
				end
				if y - h / 2 > leanHi + 0.4 or z > LEAN_Z1 + 1.4 then
					b.window(b.face(-hw - off, y, z, RIGHT), w, h, L.frame, L.glass, opts(false))
				end
			end
		end
	end

	-- THE CLOCK TOWER, on queen posts over two tie beams that span the hall under the roof ------------------------
	local r = tw * 0.34
	-- (stout and low, as the reference has it: the dial sits just over the ridge and the cap right on the dial's
	-- storey; the belfry and the extra storeys of the first build made it a thin spire)
	local clockY = ridge + 0.6 + r
	local shaftTop = clockY + r + 1
	local towerFoot = roofY(tw / 2) - 0.8
	b.box("Tower", tw, shaftTop - towerFoot, tw, b.at(0, (towerFoot + shaftTop) / 2, zT), L.towerWall)
	-- (posts down to the floor stood in the doorway's view, so the tower's weight goes to the side walls)
	local tieY = wallH - 0.9
	for _, sz in { -1, 1 } do
		local z = zT + sz * (tw / 2 - 0.3)
		b.beam("TowerTie", 0.6, 0.6, Vector3.new(-(hw - T), tieY, z), Vector3.new(hw - T, tieY, z), L.board)
		for _, sx in { -1, 1 } do
			local x = sx * (tw / 2 - 0.1)
			local pz = zT + sz * (tw / 2 - 0.1)
			b.trim("TowerPost", 0.5, shaftTop - towerFoot, 0.5, b.at(x, (towerFoot + shaftTop) / 2, pz), L.board)
			b.trim(
				"TowerLeg",
				0.6,
				towerFoot - tieY,
				0.6,
				b.at(sx * (tw / 2 - 0.3), (tieY + towerFoot) / 2, z),
				L.board
			)
		end
	end
	local stringY = clockY - r - 0.65
	b.trim("TowerString", tw + 0.5, 0.35, tw + 0.5, b.at(0, stringY, zT), L.board)
	local dial = if era == 4 then C(210, 250, 245) else WHITE
	b.clock(b.face(0, clockY, zT - tw / 2, FRONT), r, L.gold, dial, DARK)
	if f >= 5 then
		-- dials to the sides too
		b.clock(b.face(tw / 2, clockY, zT, LEFT), r, L.gold, dial, DARK)
		b.clock(b.face(-tw / 2, clockY, zT, RIGHT), r, L.gold, dial, DARK)
	end
	if f >= 15 then
		-- a gallery round the tower under the dial
		local gw = tw + 2.2
		local e = gw / 2 - 0.15
		b.trim("Gallery", gw, 0.3, gw, b.at(0, stringY, zT), L.board)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				b.trim("GalleryPost", 0.25, 1.1, 0.25, b.at(sx * e, stringY + 0.7, zT + sz * e), L.gold)
			end
			b.trim("GalleryRail", 0.15, 0.15, gw - 0.3, b.at(sx * e, stringY + 1.2, zT), L.gold)
			b.trim("GalleryRail", gw - 0.3, 0.15, 0.15, b.at(0, stringY + 1.2, zT + sx * e), L.gold)
		end
	end
	b.box("TowerCornice", tw + 1, 0.5, tw + 1, b.at(0, shaftTop + 0.25, zT), L.board)
	local top = shaftTop + 0.5
	if f >= 20 then
		-- a pinnacle on each corner of the tower's cornice, beside the dome
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local at = b.at(sx * (tw / 2 + 0.1), top, zT + sz * (tw / 2 + 0.1))
				b.cyl("Pinnacle", 0.3, 1.2, at * CFrame.new(0, 0.6, 0), L.gold, nil, false)
				b.ball("PinnacleTip", 0.42, at * CFrame.new(0, 1.4, 0), L.gold)
			end
		end
	end
	local tip: number
	local seat: number? -- where the slime of the last level sits, if not on the very tip
	if L.towerRoof == "pyramid" then
		b.trim("TowerEave", tw + 1.7, 0.3, tw + 1.7, b.at(0, top + 0.15, zT), L.board)
		local w = (tw + 1.5) * 1.1 -- (the straw cap hangs a little over the eave board)
		local up = L.spire + 0.5 -- (and ends in a knot)
		if era == 1 and painted("ThatchCap_Tower", b.at(0, top + 0.3, zT), w / 2, up / 1.772, w / 1.962) then
			tip = top + 0.3 + up
		else
			b.pyramid(b.at(0, top + 0.3, zT), tw + 1.5, tw + 1.5, L.spire, L.towerCap)
			tip = top + 0.3 + L.spire
		end
	elseif L.towerRoof == "glass" then
		local rd = tw / 2
		b.cyl("DomeRing", rd + 0.4, 0.5, b.at(0, top + 0.25, zT), L.gold, nil, false)
		b.ball("DomeGoo", rd * 0.45, b.at(0, top + 0.9, zT), L.goo or L.glass, M.Neon)
		local high = ribDome(b.at(0, top + 0.5, zT), rd, L.towerCap)
		if high then
			tip = top + 0.5 + high
		else
			b.ball("Dome", rd, b.at(0, top + 0.5, zT), L.towerCap)
			for k = 0, 3 do
				-- the dome's steel ribs
				b.cyl(
					"DomeRib",
					rd + 0.06,
					0.2,
					b.at(0, top + 0.5, zT) * CFrame.Angles(0, k * math.pi / 4, 0) * CFrame.Angles(math.pi / 2, 0, 0),
					L.beam,
					nil,
					false
				)
			end
			b.cyl("DomeCap", 0.9, 0.8, b.at(0, top + 0.5 + rd + 0.1, zT), L.gold, nil, false)
			tip = top + 0.5 + rd + 0.5
		end
	else
		local rd = tw / 2 + 0.2
		b.cyl("DomeDrum", rd, 1.6, b.at(0, top + 0.8, zT), L.towerWall, nil, false)
		b.cyl("DomeRing", rd + 0.3, 0.4, b.at(0, top + 1.6, zT), L.gold, nil, false)
		local high = royalDome(b.at(0, top + 1.8, zT), rd, L.towerCap)
		if high then
			tip = top + 1.8 + high
			seat = top + 1.8 + 1.58 * rd -- (in the lantern's cap: the finial stands hidden in the slime)
		else
			b.ball("Dome", rd, b.at(0, top + 1.7, zT), L.towerCap)
			for k = 0, 3 do
				-- golden ribs over the blue
				b.cyl(
					"DomeRib",
					rd + 0.08,
					0.25,
					b.at(0, top + 1.7, zT) * CFrame.Angles(0, k * math.pi / 4, 0) * CFrame.Angles(math.pi / 2, 0, 0),
					L.gold,
					nil,
					false
				)
			end
			b.cyl("DomeLantern", 0.9, 1.6, b.at(0, top + 1.7 + rd + 0.5, zT), L.towerWall, nil, false)
			b.ball("LanternCap", 1, b.at(0, top + 1.7 + rd + 1.3, zT), L.gold)
			tip = top + 1.7 + rd + 2.3
		end
	end
	if f >= 25 then
		-- the crowned golden slime on the very top
		statue(b.at(0, seat or tip - 0.2, zT), 1.4, 0.7)
	elseif f >= 4 then
		b.flag(Vector3.new(0, tip - 0.2, zT), 3.4, L.cloth, L.gold)
	else
		b.rod("TowerSpike", 0.1, Vector3.new(0, tip - 0.2, zT), Vector3.new(0, tip + 1.6, zT), L.gold)
		b.ball("TowerFinial", 0.35, b.at(0, tip + 0.2, zT), L.gold)
	end

	shell(false) -- (dormers, the store and the wing are built of the shell's helpers, and are no part of the model)

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
		b.gable(b.at(s * (uF - run / 2), y0 + h, z), run, w, rise, 0.3, L.roof, L.wall, L.board)
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
		-- a big wall gable on the right, over the lean-to beside the tower
		dormer(-1, zT, half, 4.4, 2.6, 1.8, 1.5, 1.6)
	end

	-- THE STORE INSIDE -----------------------------------------------------------------------------------
	local crateColour = if era <= 3 then PLANK elseif era == 4 then C(70, 130, 200) else WHITE
	local crateBand = if era == 5 then L.gold else L.board
	local function crate(x: number, y: number, z: number, s: number, yaw: number)
		local cf = b.at(x, y + s / 2, z) * CFrame.Angles(0, math.rad(yaw), 0)
		b.box("Crate", s, s, s, cf, crateColour)
		for _, t in { -0.3, 0.3 } do
			b.trim("CrateBand", s + 0.1, 0.18, s + 0.1, cf * CFrame.new(0, s * t, 0), crateBand)
		end
	end
	-- a pile of sacks lying across x: `n` on the floor, one fewer in every row above
	local function sacks(x: number, y: number, z: number, n: number)
		local row, yy = n, y + 0.55
		while row >= 1 do
			for i = 1, row do
				local zz = z + (i - (row + 1) / 2) * 1.15
				b.rod("Sack", 0.55, Vector3.new(x - 0.85, yy, zz), Vector3.new(x + 0.85, yy, zz), SACK)
			end
			row -= 1
			yy += 0.95
		end
	end
	local function barrel(x: number, y: number, z: number)
		b.cyl("Barrel", 0.85, 2.1, b.at(x, y + 1.05, z), PLANK)
		for _, t in { 0.5, 1.6 } do
			b.cyl("BarrelHoop", 0.9, 0.16, b.at(x, y + t, z), IRON, nil, false)
		end
	end
	do
		local inX = hw - T -- the inside of the side walls
		-- two trusses over the hall, a lamp hanging from the first
		for _, z in { d * 0.2, d - 1.6 } do
			b.trim("Truss", inX * 2, 0.45, 0.45, b.at(0, wallH - 0.25, z), L.board)
			b.trim("TrussPost", 0.4, L.rise - 0.6, 0.4, b.at(0, wallH + (L.rise - 0.6) / 2, z), L.board)
			for _, s in { -1, 1 } do
				b.beam(
					"TrussStrut",
					0.3,
					0.3,
					Vector3.new(s * inX * 0.6, wallH, z),
					Vector3.new(0, wallH + L.rise * 0.6, z),
					L.board
				)
			end
		end
		local lampY = math.max(doorTop + 0.2, wallH - 2.6)
		b.rod("LampChain", 0.06, Vector3.new(0, wallH - 0.4, d * 0.2), Vector3.new(0, lampY + 0.5, d * 0.2), IRON)
		b.trim("LampCap", 1, 0.2, 1, b.at(0, lampY + 0.5, d * 0.2), IRON)
		local lamp = b.trim("HallLamp", 0.7, 0.9, 0.7, b.at(0, lampY, d * 0.2), L.glass, M.Neon)
		local light = Instance.new("PointLight")
		light.Color = L.glass
		light.Range = 26
		light.Brightness = 0.9
		light.Parent = lamp

		-- the loft across the back (from the painted hall on), a ladder up to it on the right
		local lz0 = d - 4.6
		local loftY = BASE + math.min(5.2, (wallH - BASE) * 0.55)
		if era >= 2 then
			b.box("Loft", inX * 2, 0.35, d - T - lz0, b.at(0, loftY - 0.175, (lz0 + d - T) / 2), PLANK)
			b.trim("LoftBeam", inX * 2, 0.5, 0.4, b.at(0, loftY - 0.6, lz0 + 0.2), L.board)
			for _, x in { -inX * 0.5, 0, inX * 0.5 } do
				b.box(
					"LoftPost",
					0.45,
					loftY - 0.85 - BASE,
					0.45,
					b.at(x, (BASE + loftY - 0.85) / 2, lz0 + 0.2),
					L.board
				)
			end
			local railLen = inX * 2 - 2.6
			b.trim("LoftRail", railLen, 0.2, 0.2, b.at(1.3, loftY + 1.2, lz0 + 0.15), L.board)
			for i = 0, 4 do
				b.trim(
					"LoftBaluster",
					0.2,
					1.2,
					0.2,
					b.at(1.3 - railLen / 2 + i * railLen / 4, loftY + 0.6, lz0 + 0.15),
					L.board
				)
			end
			local lx = -inX + 1.3
			for _, s in { -1, 1 } do
				b.beam(
					"Ladder",
					0.16,
					0.16,
					Vector3.new(lx + s * 0.5, BASE, lz0 - 1.8),
					Vector3.new(lx + s * 0.5, loftY + 0.9, lz0 - 0.05),
					L.board
				)
			end
			for i = 1, 6 do
				local t = i / 7
				b.trim(
					"LadderRung",
					1,
					0.12,
					0.12,
					b.at(lx, BASE + (loftY + 0.9 - BASE) * t, lz0 - 1.8 + 1.75 * t),
					L.board
				)
			end
			-- the loft's store
			sacks(-inX * 0.35, loftY, d - T - 1.3, 3)
			crate(inX * 0.3, loftY, d - T - 1.2, 1.5, 8)
			crate(inX * 0.3 + 1.7, loftY, d - T - 1.1, 1.3, -6)
			crate(inX * 0.3 + 0.2, loftY + 1.5, d - T - 1.2, 1.1, 20)
			barrel(inX - 1.3, loftY, d - T - 1.2)
		end
		-- the ground floor's store, against the back wall (under the loft)
		local gy, gz = BASE, d - T - 1.3
		crate(inX - 1.3, gy, gz, 2, 0)
		crate(inX - 3.5, gy, gz + 0.1, 1.8, 6)
		crate(inX - 1.4, gy + 2, gz, 1.5, -10)
		sacks(0.6, gy, gz - 0.4, if era == 1 then 3 else 4)
		barrel(-inX + 3.6, gy, gz)
		barrel(-inX + 5.5, gy, gz + 0.1)
		barrel(-inX + 4.5, gy, gz - 1.7)
		-- hay by the door on the right (goo vats in the glasshouse, golden urns in the capital)
		local hx, hz = -inX + 1.5, 1.5
		if era <= 3 then
			b.box("Hay", 2.4, 1.3, 1.4, b.at(hx, BASE + 0.65, hz), HAY)
			b.box("Hay", 2.4, 1.3, 1.4, b.at(hx + 0.3, BASE + 1.95, hz), HAY)
			b.box("Hay", 1.4, 1.3, 2.4, b.at(hx + 2.3, BASE + 0.65, hz + 0.4), HAY)
		else
			for i = 0, 1 do
				local x = hx + 0.2 + i * 2.6
				-- (the owner's Meshy goo tank in the glasshouse, when it is there)
				if era == 4 and painted("GooTank_Glass", b.at(x, BASE, hz + 0.3), 0.83) then
					continue
				end
				b.cyl("VatFoot", 1.2, 0.5, b.at(x, BASE + 0.25, hz + 0.3), L.board)
				if era == 4 then
					local vat = b.cyl("VatGlass", 1.05, 3, b.at(x, BASE + 2, hz + 0.3), L.siloDrum, M.Glass)
					vat.Transparency = 0.6
					b.cyl("VatGoo", 0.85, 2.2, b.at(x, BASE + 1.6, hz + 0.3), L.goo or L.glass, M.Neon, false)
				else
					b.cyl("Urn", 0.95, 2.2, b.at(x, BASE + 1.6, hz + 0.3), L.gold)
					b.ball("UrnLid", 0.8, b.at(x, BASE + 2.8, hz + 0.3), L.gold)
				end
				b.cyl("VatLid", 1.15, 0.3, b.at(x, BASE + 3.6, hz + 0.3), L.board, nil, false)
			end
		end
		-- shelves along the right wall
		local sz0, sz1 = d * 0.3, d - 7.4
		if sz1 - sz0 > 2 then
			local sx = -inX + 0.6
			for _, z in { sz0, sz1 } do
				b.trim("ShelfPost", 1.1, 5, 0.25, b.at(sx, BASE + 2.5, z), L.board)
			end
			for i, y in { 0.9, 2.6, 4.3 } do
				b.trim("Shelf", 1.1, 0.16, sz1 - sz0, b.at(sx, BASE + y, (sz0 + sz1) / 2), PLANK)
				local n = math.max(2, math.floor((sz1 - sz0) / 1.5))
				for k = 1, n do
					local z = sz0 + (k - 0.5) * (sz1 - sz0) / n
					if (k + i) % 3 == 0 then
						b.cyl("Jar", 0.36, 0.9, b.at(sx, BASE + y + 0.53, z), L.accent, nil, false)
					elseif (k + i) % 3 == 1 then
						b.trim("Box", 0.9, 0.8, 1, b.at(sx, BASE + y + 0.48, z), crateColour)
					else
						b.rod(
							"Sack",
							0.4,
							Vector3.new(sx, BASE + y + 0.48, z - 0.5),
							Vector3.new(sx, BASE + y + 0.48, z + 0.5),
							SACK
						)
					end
				end
			end
		end
	end

	-- THE WING on the left: a hollow side store under a roof of its own, open to the hall ----------------------
	if W then
		local x0, x1, zc = hw, hw + W.out, (WING_Z0 + wz1) / 2
		slab("WingPlinth", x0, x1 + 0.3, 0, BASE, WING_Z0 - 0.3, wz1 + 0.3, L.stone)
		-- a paved walk along its outer wall (thin, on the lawn: the slime-tech conveyor stands on it)
		b.trim("WingWalk", 4.4, 0.12, W.len, b.at(x1 + 0.3 + 2.2, 0.06, zc), L.stone)
		b.trim("WingFloor", W.out - T, 0.1, W.len - T * 2, b.at(x0 + (W.out - T) / 2, BASE + 0.05, zc), floorColour)
		for _, st in storeys do
			local y0, y1, colour = st[1] :: number, math.min(st[2] :: number, W.wallH), st[3] :: Color3
			slab("WingWall", x0, x1, y0, y1, WING_Z0, WING_Z0 + T, colour)
			slab("WingWall", x0, x1, y0, y1, wz1 - T, wz1, colour)
			slab("WingWall", x1 - T, x1, y0, y1, WING_Z0 + T, wz1 - T, colour)
		end
		local over = 0.8
		if L.glassWalls then
			-- a glass barrel vault on steel ribs, its round end to the front as the reference's glasshouse wing has
			-- it: the ends glazed in steps, a fan of glazing bars on the front one
			local n, a = 6, W.out / 2
			local xm = hw + a
			local function arc(k: number, z: number): Vector3
				local t = math.pi * k / n
				return Vector3.new(xm + (a + 0.3) * math.cos(t), W.wallH + W.rise * math.sin(t), z)
			end
			for k = 0, n - 1 do
				b.beam("Vault", W.len + 0.6, 0.3, arc(k, zc), arc(k + 1, zc), L.wall)
				for _, z in { WING_Z0 - 0.25, zc, wz1 + 0.25 } do
					b.beam("VaultRib", 0.35, 0.45, arc(k, z), arc(k + 1, z), L.beam)
				end
				if k > 0 then
					local hub = Vector3.new(xm, W.wallH + 0.1, WING_Z0 - 0.1)
					b.beam("VaultFan", 0.2, 0.2, hub, arc(k, WING_Z0 - 0.1), L.beam)
				end
			end
			b.trim("VaultRidge", 0.4, 0.3, W.len + 0.8, b.at(xm, W.wallH + W.rise + 0.1, zc), L.beam)
			b.trim("VaultSill", W.out + 0.6, 0.35, 0.5, b.at(xm, W.wallH, WING_Z0 - 0.1), L.beam)
			for _, st in { { 0.94, 0, 0.42 }, { 0.74, 0.42, 0.74 }, { 0.44, 0.74, 0.95 } } do
				local y0, y1 = W.wallH + W.rise * st[2], W.wallH + W.rise * st[3]
				slab("VaultEnd", xm - a * st[1], xm + a * st[1], y0, y1, WING_Z0, WING_Z0 + T, L.wall)
				slab("VaultEnd", xm - a * st[1], xm + a * st[1], y0, y1, wz1 - T, wz1, L.wall)
			end
		else
			b.gable(
				b.at(hw + (W.out + over) / 2, W.wallH, zc),
				W.out - over,
				W.len,
				W.rise,
				over,
				L.roof,
				L.wall,
				L.board,
				nil,
				nil,
				1
			)
		end
		-- its frame, where the hall has one
		local wy0 = if L.glassWalls then lowerTop else BASE
		if L.timber and era ~= 3 then
			local y, h = (wy0 + W.wallH) / 2, W.wallH - wy0
			b.timber(b.face(x0 + W.out / 2, y, WING_Z0, FRONT), W.out, h, L.beam)
			b.timber(b.face(x1, y, zc, LEFT), W.len, h, L.beam)
		elseif era == 5 then
			girdle("WingLine", W.wallH - 0.3, 0.3, 0, 0.1, L.gold)
			b.trim("WingBand", W.out + 0.3, 0.5, W.len + 0.3, b.at(x0 + W.out / 2, W.wallH - 0.25, zc), L.gold)
		end
		if L.glassWalls then
			for _, z in { WING_Z0, wz1 } do
				b.trim(
					"FootCap",
					W.out + 0.2,
					0.3,
					T + 0.4,
					b.at(x0 + W.out / 2, lowerTop, z + (if z == wz1 then -T / 2 else T / 2)),
					L.stone
				)
			end
		else
			-- a window to the front with its flower box, two on the outer wall, a round one in the gable
			local wy = BASE + (W.wallH - BASE) * 0.55
			local row = L.rows[1]
			local o: WindowOpts = {
				shutters = if row[4] == 1 then nil else L.shutters,
				arch = row[4] == 1,
				flowers = f >= 4,
				glow = L.glow,
				through = T,
			}
			b.window(b.face(x0 + W.out / 2, wy, WING_Z0, FRONT), row[2], row[3], L.frame, L.glass, o)
			o.flowers = false
			for _, t in { 0.28, 0.72 } do
				b.window(b.face(x1, wy, WING_Z0 + W.len * t, LEFT), row[2], row[3], L.frame, L.glass, o)
			end
		end
		if not L.glassWalls then
			local eye = b.face(x1, W.wallH + W.rise * 0.36, zc, LEFT)
			b.disc("WingEye", 0.8, 0.3, eye * CFrame.new(0, 0, -0.1), L.frame)
			b.disc("WingEyeGlass", 0.55, 0.36, eye * CFrame.new(0, 0, -0.11), L.glass, glowMat)
		end
		if f >= 14 then
			-- banners on the wing's front
			for _, t in { 0.14, 0.86 } do
				local at = b.face(x0 + W.out * t, W.wallH - 0.5, WING_Z0, FRONT)
				if not painted("Banner_SlimeBlue", at * CFrame.new(0, -1.2, 0), 0.48) then
					b.banner(at, 1, 2.4, L.cloth, L.gold)
				end
			end
		end
		-- its store: sacks and crates along the outer wall
		sacks(x1 - T - 1.1, BASE, zc + 1.4, 3)
		crate(x1 - T - 1.2, BASE, WING_Z0 + T + 1.3, 1.8, 4)
		crate(x1 - T - 1.1, BASE + 1.8, WING_Z0 + T + 1.3, 1.3, -12)
		barrel(x0 + 1.4, BASE, wz1 - T - 1.2)
	end

	-- THE LEAN-TO SHED along the right wall --------------------------------------------------------------
	shell(true)
	do
		local slope = LEAN_SLOPE
		local run = LEAN_OUT + 0.6
		local zc, len = (LEAN_Z0 + LEAN_Z1) / 2, LEAN_Z1 - LEAN_Z0
		local thick = if era == 1 then 0.7 else 0.35
		-- (the slab's long side runs down the slope, so its tiles do)
		b.trim(
			"LeanRoof",
			len + 1,
			thick,
			run * math.sqrt(1 + slope ^ 2),
			b.at(-(hw + run / 2), leanHi - slope * run / 2, zc)
				* CFrame.Angles(0, math.pi / 2, 0)
				* CFrame.Angles(-math.atan(slope), 0, 0), -- high at the wall, low at the posts
			L.roof2
		).CastShadow =
			true
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
				-- knee braces along the beam, towards the next post: the ones above hide under the roof, and from
				-- the yard the shed stood on three bare sticks
				local knees: { number } = if z == zc then { -1.3, 1.3 } elseif z < zc then { 1.3 } else { -1.3 }
				for _, dz in knees do
					b.beam(
						"LeanKnee",
						0.3,
						0.3,
						Vector3.new(px, beamY - 1.5, z),
						Vector3.new(px, beamY - 0.1, z + dz),
						L.board
					)
				end
			end
			b.beam("LeanRafter", 0.3, 0.3, Vector3.new(px, beamY + 0.2, z), Vector3.new(-hw, leanHi - 0.5, z), L.board)
		end
		if f >= 8 then
			-- lamps: the owner's iron wall lanterns on the end posts' outer faces, a lit pane in each; until they
			-- come, two lamps hanging under the beam
			local out = if era == 5 then 0.35 else 0.25
			for i, z in { LEAN_Z0 + 0.3, LEAN_Z1 - 0.3 } do
				local on = b.face(px - out, beamY - 1.5, z, RIGHT)
				if painted("WallLantern_Iron", on, 1) then
					b.trim("LeanLamp", 0.3, 0.45, 0.3, on * CFrame.new(0, -0.3, -1.5), L.glass, M.Neon)
				else
					local hz = zc + (i * 2 - 3) * len / 4
					b.rod(
						"LeanLampChain",
						0.05,
						Vector3.new(px, beamY - 0.2, hz),
						Vector3.new(px, beamY - 0.8, hz),
						IRON
					)
					b.trim("LeanLamp", 0.5, 0.7, 0.5, b.at(px, beamY - 1.15, hz), L.glass, M.Neon)
				end
			end
		end
		if era <= 3 then
			-- a grain sack on a pulley beam at the shed's front post (the owner's Meshy piece; nothing until it comes)
			painted("HangingSack_Beam", b.face(px, beamY - 1.9, LEAN_Z0 + 0.05, FRONT), 1)
		end
	end
	shell(false)

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
			local drumTop = 0.4 + 0.8 + h
			local high: number? -- the cap as a mesh, in the era's manner
			if L.siloCap == "cone" then
				local capR, up = sr + 0.6, sr * 1.3 + 0.3
				if era == 1 and painted("ThatchCap_Silo", b.at(x, drumTop, z), capR, up / 1.389, capR) then
					high = up
				else
					high = coneRoof(b.at(x, drumTop, z), capR, up, L.siloCapColour)
				end
			elseif era == 4 then
				high = ribDome(b.at(x, drumTop, z), sr + 0.15, L.siloCapColour)
			else
				high = royalDome(b.at(x, drumTop, z), sr + 0.15, L.siloCapColour)
			end
			local capKind = if high then "none" else L.siloCap
			b.silo(x, 0.4, z, sr, h, L.siloDrum, L.siloHoop, capKind, L.siloCapColour, L.goo)
			local capTop = drumTop + (high or (if L.siloCap == "cone" then 0.3 + sr * 1.3 + 0.5 else sr + 0.7))
			if f >= 22 and L.siloCap == "dome" then
				if high then
					-- (round the dome's lantern, its finial through the middle)
					crown(b.at(x, drumTop + 1.48 * (sr + 0.15), z), 0.8)
				else
					crown(b.at(x, capTop - 0.5, z), 0.8)
					capTop += 0.5
				end
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
			-- and two climb from the first silo's shoulder over the eave and up the roof to the tower's foot
			local lift = 0.45 -- (how far a pipe rides over the slates)
			local ue = half + L.over * 0.5
			-- (side by side to the tower's back half: the second one used to cut through the big dormer)
			for i, zTo in { zT + tw / 4 + 1.1, zT + tw / 4 } do
				local z0 = z1 - (i - 1) * 1.1
				local from = Vector3.new(x1 + sr * 0.6, 0.4 + 0.8 + sh - 0.3, z0)
				local eave = Vector3.new(-ue, roofY(ue) + lift, z0)
				local to = Vector3.new(-tw / 2, roofY(tw / 2) + lift, zTo)
				-- out of the silo level, then straight up or down to the eave through a fitter's elbow (its mouths 0.7
				-- from its corner in the mesh, drawn for a pipe 0.25 round)
				local climb, port = eave.Y - from.Y, 0.7 * 1.2
				local turn = if climb > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.Angles(0, 0, math.pi)
				if
					math.abs(climb) > port + 0.2
					and eave.X - from.X > port + 0.2
					and piece("Pipe_Elbow", b.at(eave.X, from.Y, z0) * turn, 1.2, 1.2, 1.2, L.accent)
				then
					b.rod("RoofPipe", 0.3, from, Vector3.new(eave.X - port, from.Y, z0), L.accent)
					b.rod("RoofPipe", 0.3, Vector3.new(eave.X, from.Y + math.sign(climb) * port, z0), eave, L.accent)
				else
					b.rod("RoofPipe", 0.3, from, eave, L.accent)
				end
				b.rod("RoofPipe", 0.3, eave, to, L.accent)
				b.ball("PipeElbow", 0.42, b.at(eave.X, eave.Y, eave.Z), L.gold)
				b.ball("PipeElbow", 0.42, b.at(to.X, to.Y, to.Z), L.gold)
			end
		end
	end

	-- TURRETS: a round one from the ground at the wing's outer corner, one on the hall's right front corner ------
	local function turret(tx: number, tz: number, tr: number, y0: number, tTop: number, grounded: boolean)
		if grounded then
			b.cyl("TurretFoot", tr + 0.3, BASE, b.at(tx, BASE / 2, tz), L.stone)
			b.cyl("Turret", tr, tTop - BASE, b.at(tx, (BASE + tTop) / 2, tz), L.towerWall)
		else
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
		end
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
		local high: number? -- the roof as a mesh, in the era's manner
		if era == 3 then
			high = coneRoof(b.at(tx, tTop, tz), tr + 0.5, 3.6, L.roof)
		elseif era == 4 then
			high = ribDome(b.at(tx, tTop, tz), tr + 0.1, L.gold)
		else
			high = royalDome(b.at(tx, tTop, tz), tr + 0.1, L.towerCap)
		end
		if high then
			tTip = tTop + high
		elseif era == 3 then
			b.cone(b.at(tx, tTop, tz), tr + 0.5, 3.6, 5, L.roof, L.gold)
			tTip = tTop + 4.1
		else
			b.ball("TurretDome", tr, b.at(tx, tTop, tz), if era == 4 then L.gold else L.towerCap)
			b.ball("Finial", 0.3, b.at(tx, tTop + tr + 0.2, tz), L.gold)
			tTip = tTop + tr + 0.4
		end
		table.insert(tips, Vector3.new(tx, tTip, tz))
	end
	if f >= 12 and W then
		-- (at the back in the glass era: at the front it hid the vault's fan end)
		turret(hw + W.out, if era == 4 then wz1 else WING_Z0, 1.9, 0, wingRidge + 1.6, true)
	end
	if f >= 13 then
		turret(-half, -jet, 1.6, (if jet > 0 then lowerTop else wallH * 0.55) - 1.5, wallH + 2.6, false)
	end

	-- THE BOILER behind the wing, with its stack ------------------------------------------------------------
	if f >= 17 then
		local sx, sz, st = hw + 1.7, wz1 + 2, wallH + 3.5
		b.box("BoilerFoot", 3.4, 0.5, 3.4, b.at(sx, 0.25, sz), L.stone)
		b.cyl("Boiler", 1.4, 3, b.at(sx, 2, sz), L.accent)
		for _, t in { 0.9, 3.1 } do
			b.cyl("BoilerHoop", 1.5, 0.3, b.at(sx, t, sz), L.gold, nil, false)
		end
		b.cyl(
			"BoilerEye",
			0.5,
			0.2,
			b.face(sx, 2, sz - 1.4, FRONT) * CFrame.Angles(math.pi / 2, 0, 0),
			L.goo or L.glass,
			M.Neon,
			false
		)
		b.cyl("Stack", 0.8, st - 3.5, b.at(sx, (3.5 + st) / 2, sz), L.accent)
		for _, t in { 0.3, 0.65, 1 } do
			b.cyl("StackRing", 0.95, 0.35, b.at(sx, 3.5 + (st - 3.5) * t - 0.2, sz), L.gold, nil, false)
		end
		b.cyl("StackGlow", 0.6, 0.2, b.at(sx, st + 0.05, sz), L.goo or L.glass, M.Neon, false)
	end

	-- THE PORTICO of the capital -------------------------------------------------------------------------
	if f >= 21 then
		local colTop = doorTop + 1.2
		for _, x in { -(dockHW - 0.6), -(dockHW - 1.85), dockHW - 1.85, dockHW - 0.6 } do
			local foot, head = 0.4, 0.4
			local s = 1.1 -- (the meshes are drawn for a shaft one stud through)
			if piece("Column_Base", b.at(x, BASE, -3), s, s, s, L.gold) then
				foot, head = 0.45 * s, 0.7 * s
				piece("Column_Capital", b.at(x, colTop - head, -3), s, s, s, L.gold)
			else
				b.cyl("ColumnFoot", 0.75, 0.4, b.at(x, BASE + 0.2, -3), L.beam, nil, false)
				b.cyl("ColumnHead", 0.75, 0.4, b.at(x, colTop - 0.2, -3), L.gold, nil, false)
			end
			b.cyl("Column", 0.55, colTop - BASE - foot - head, b.at(x, (BASE + foot + colTop - head) / 2, -3), L.wall)
		end
		-- (a flat top with a rail: a roof of its own hid the pediment's slime behind it)
		b.box("PorticoBeam", dockHW * 2 + 0.6, 0.9, 3.9, b.at(0, colTop + 0.45, -1.75), L.wall)
		b.trim("PorticoLine", dockHW * 2 + 0.8, 0.2, 4.1, b.at(0, colTop + 0.2, -1.75), L.gold)
		local railW, railY = dockHW * 2 + 0.4, colTop + 0.9
		if LibraryKit.find("Balustrade_Run") then
			-- a marble balustrade between posts, an urn on each
			local bays = math.max(1, math.round(railW / 4))
			local step = (railW - 0.6) / bays
			for i = 0, bays do
				local x = -railW / 2 + 0.3 + i * step
				piece("Balustrade_Post", b.at(x, railY, -3.5), 1, 1, 1, L.wall)
				piece("Balustrade_Urn", b.at(x, railY + 1.3, -3.5), 1.3, 1.3, 1.3, L.gold)
				if i < bays then
					piece("Balustrade_Run", b.at(x + step / 2, railY, -3.5), (step - 0.5) / 4, 1, 1, L.wall)
				end
			end
		else
			b.trim("PorticoRail", railW, 0.15, 0.15, b.at(0, colTop + 1.7, -3.5), L.gold)
			for x = -dockHW, dockHW, dockHW / 3 do
				b.trim("PorticoBaluster", 0.2, 0.75, 0.2, b.at(x, colTop + 1.27, -3.5), L.gold)
			end
		end
		if f >= 23 then
			-- golden slimes on pedestals either side of the steps
			for _, s in { -1, 1 } do
				local x = s * (dockHW + 1.3)
				b.box("Pedestal", 1.5, 1.6, 1.5, b.at(x, FLOOR + 0.8, -3.6), L.wall)
				b.trim("PedestalCap", 1.8, 0.25, 1.8, b.at(x, FLOOR + 1.7, -3.6), L.gold)
				statue(b.at(x, FLOOR + 1.8, -3.6), 0.85)
			end
		end
	end

	-- beacons and flags on the turrets and the silos
	for _, p in tips do
		if f >= 24 then
			b.flag(p - Vector3.new(0, 0.3, 0), 2.6, L.cloth, L.gold)
		end
		if f >= 19 then
			b.ball("Beacon", 0.4, b.at(p.X, p.Y + 0.1, p.Z), L.goo or L.glass, M.Neon)
		end
	end
end

-- The Granary at its drawn size, then grown (Config.Village.HouseScale).
function Granary.build(m: Instance, frame: CFrame, level: number)
	local had = m:GetChildren()
	raise(m, frame, level)
	Architecture.grow(m, had, frame, "Granary", SPLIT_Z, PIVOT_X, PIVOT_Z)
end

return Granary
