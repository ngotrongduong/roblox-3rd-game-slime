--!strict
-- The kitchen's landmark: the village's cookhouse, grown into a grand restaurant (village v2, skill landmark-build;
-- the owner approved the reference on 2026-11-16: docs/areas/village-v2/kitchen-ref-sheet.jpg, the ladder is
-- kitchen-ladder.md beside it). One building in five architectures, one an era of ten levels:
--   1 hamlet       thatch on brown posts, a cream plaster gable, a fieldstone chimney
--   2 painted      cream plaster on teal beams, red clay tiles, a red brick chimney with a cream cap
--   3 town         a stone storey with one wide arch under a half-timbered gable, a stone chimney
--   4 slime tech   brick piers, a black steel frame, a glass vault, copper hoods and pipes
--   5 capital      white marble and gold, columns and a pediment, blue slate and domes
-- The same three things at every era, so it stays one building: THE HALL (x -HW..HW, z Z0..Z1), its gable and its
-- one wide opening to the front (-z) so the cooking line is seen from outside, hollow, the area's own stove, counter
-- and cooking spots inside; THE GREAT CHIMNEY outside the left wall (+x), about the tallest thing, smoking; THE
-- TERRACE on the right (-x) where the food is eaten. It stands on the kitchen's pad in the area's frame (the lawn's
-- top is y 0, the pad's floor FLOOR).
-- An era's first level changes the architecture; levels 6-10 of each era add one feature each, and a feature once
-- added stays in every later era in that era's materials (25 in all, numbered in `build` as in the ladder).
local Architecture = require(script.Parent.Architecture)
local LibraryKit = require(script.Parent.LibraryKit)

local Kitchen = {}

local C = Color3.fromRGB
local M = Enum.Material
local IRON = C(60, 60, 66)
local DARK = C(42, 34, 30)
local SOOT = C(36, 34, 38) -- the cauldron
local WHITE = C(250, 248, 240)
local PLANK = C(176, 128, 78)
local EMBER = C(255, 150, 60)
local LEAF = C(86, 160, 70)
local AWN_RED = C(214, 60, 52)
local BOX = C(128, 84, 50) -- flower boxes, the emblem's plaque
local BLOOMS = { C(255, 120, 150), C(255, 214, 80), C(240, 90, 80) }
local HW = 14.3 -- half the hall's width: the pad's
local Z0, Z1 = -5, 12.3 -- its front and its back
local ZC, LEN = (Z0 + Z1) / 2, Z1 - Z0
local T = 0.6 -- how thick a wall is
local FLOOR = 0.4 -- the pad's floor over the lawn
local BAY = 9.5 -- half the great opening: the side bays stand from here to the corners
local AISLE = 10.7 -- the capital's pediment roof spans this far each side; flat roofs cover the rest
local FRONT, BACK = Vector3.new(0, 0, -1), Vector3.new(0, 0, 1)
local CX, CZ = 16.5, 6.2 -- the chimney's middle
local TZ0, TZ1 = -4.6, 5.6 -- the terrace's cover, front to back
local TX = -22.9 -- and how far out it reaches
local TCX, TCZ = -19.5, 0.5 -- the dining table's place under it
local WING_X, WING_Z = -22.3, 6.2 -- the wing's outer wall and its front
-- how far back the wide terrace runs past the wing's side (the owner, 2026-11-17: "the picnic tables' ground can
-- reach further back"): two more parasol tables stand there
local TERRACE_BACK = 17.5
local KETTLES = { { 22.4, -1 }, { 20.8, 3.4 } }

type Look = {
	wallH: number, -- the eaves
	rise: number, -- the roof over them
	over: number, -- its overhang
	thick: number, -- how deep a roof slab is
	stack: number, -- how far the grown chimney stands over the ridge
	spring: number, -- the front arch (eras 3-5): where it springs,
	archR: number, -- and how high it rises
	emblemY: number, -- the gable's emblem over the eaves
	winY: number, -- the gable's window over the eaves
	wall: Color3, -- upper walls and the gable (plaster, glass, marble)
	lower: Color3, -- the ground storey (planks, stone, brick)
	stone: Color3, -- pads, plinths, the terrace
	beam: Color3, -- posts and frames
	board: Color3, -- barge boards and bands
	roof: Color3,
	frame: Color3, -- window frames, quoins, the arch's stones
	glass: Color3, -- a lit pane
	shutters: Color3?,
	chimney: Color3,
	cap: Color3, -- its shoulders and capstone
	oven: Color3,
	cloth: Color3,
	gold: Color3,
	accent: Color3, -- iron, then copper
	goo: Color3?,
	mats: { [string]: Enum.Material },
}

local LOOKS: { Look } = {
	{
		wallH = 8.2,
		rise = 9.6,
		over = 1.8,
		thick = 0.9,
		stack = 6.5,
		spring = 0,
		archR = 0,
		emblemY = 3,
		winY = 5,
		wall = C(236, 220, 180),
		lower = C(170, 120, 72),
		stone = C(150, 146, 138),
		beam = C(110, 72, 42),
		board = C(92, 60, 36),
		roof = C(232, 190, 84),
		frame = C(126, 84, 50),
		glass = C(255, 214, 120),
		shutters = C(120, 150, 96),
		chimney = C(140, 138, 134),
		cap = C(112, 110, 108),
		oven = C(190, 100, 70),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		mats = {
			wall = M.Plaster,
			lower = M.WoodPlanks,
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.Sand, -- (thatch)
			frame = M.Wood,
			shutters = M.Wood,
			chimney = M.Brick, -- (grey: cut fieldstone in courses)
			cap = M.Slate,
			oven = M.Brick,
			gold = M.Foil,
			accent = M.Metal,
		},
	},
	{
		wallH = 8.6,
		rise = 9.6,
		over = 1.5,
		thick = 0.6,
		stack = 6.5,
		spring = 0,
		archR = 0,
		emblemY = 3,
		winY = 5,
		wall = C(244, 238, 224),
		lower = C(244, 238, 224),
		stone = C(156, 152, 146),
		beam = C(40, 128, 130),
		board = C(32, 104, 108),
		roof = C(198, 70, 58),
		frame = C(250, 246, 236),
		glass = C(255, 222, 140),
		shutters = C(56, 146, 146),
		chimney = C(190, 92, 66),
		cap = C(232, 222, 200),
		oven = C(204, 110, 76),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		mats = {
			wall = M.Plaster,
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.ClayRoofTiles,
			frame = M.Wood,
			shutters = M.Wood,
			chimney = M.Brick,
			cap = M.Limestone,
			oven = M.Brick,
			gold = M.Foil,
			accent = M.Metal,
		},
	},
	{
		wallH = 9.6,
		rise = 10.4,
		over = 1.4,
		thick = 0.6,
		stack = 6.5,
		spring = 4.4, -- (a low spring and a high crown: at 5.2 and 3.2 the arch read as a square opening)
		archR = 3.8,
		emblemY = 2.8,
		winY = 7,
		wall = C(240, 230, 206),
		lower = C(198, 190, 174),
		stone = C(128, 124, 118),
		beam = C(112, 72, 44),
		board = C(92, 60, 38),
		roof = C(190, 62, 50),
		frame = C(222, 216, 202),
		glass = C(255, 222, 140),
		chimney = C(150, 146, 140),
		cap = C(120, 116, 112),
		oven = C(198, 104, 72),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		mats = {
			wall = M.Plaster,
			lower = M.Brick, -- (pale: dressed stone in courses)
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.ClayRoofTiles,
			frame = M.Limestone,
			chimney = M.Brick,
			cap = M.Slate,
			oven = M.Brick,
			gold = M.Foil,
			accent = M.Metal,
		},
	},
	{
		wallH = 9.6,
		rise = 9.4,
		over = 0.8,
		thick = 0.2,
		stack = 6,
		spring = 5,
		archR = 3.4,
		emblemY = 4.4,
		winY = 0,
		wall = C(150, 225, 215),
		lower = C(198, 112, 74),
		stone = C(74, 80, 92),
		beam = C(52, 56, 64),
		board = C(40, 44, 50),
		roof = C(62, 96, 160), -- (the owner, 2026-11-17: one roof an era for every landmark, the Granary's)
		frame = C(214, 208, 196),
		glass = C(255, 226, 150),
		chimney = C(124, 122, 120),
		cap = C(84, 86, 92),
		oven = C(190, 100, 70),
		cloth = C(40, 80, 160),
		gold = C(224, 170, 70),
		accent = C(196, 112, 66),
		goo = C(96, 232, 70),
		mats = {
			wall = M.Glass,
			lower = M.Brick,
			stone = M.Slate,
			beam = M.Metal,
			board = M.Metal,
			roof = M.RoofShingles,
			frame = M.Limestone,
			chimney = M.Brick,
			cap = M.Slate,
			oven = M.Brick,
			gold = M.Metal,
			accent = M.Metal,
		},
	},
	{
		wallH = 12,
		rise = 6.5,
		over = 0.5,
		thick = 0.5,
		stack = 11,
		spring = 6.2,
		archR = 4,
		emblemY = 2.9,
		winY = 0,
		wall = C(250, 249, 245),
		lower = C(250, 249, 245),
		stone = C(214, 208, 196),
		beam = C(228, 222, 210),
		board = C(236, 192, 76),
		roof = C(44, 84, 170),
		frame = C(236, 192, 76),
		glass = C(255, 230, 160),
		chimney = C(244, 242, 236),
		cap = C(206, 200, 188),
		oven = C(240, 236, 226),
		cloth = C(40, 70, 160),
		gold = C(236, 192, 76),
		accent = C(206, 128, 72),
		goo = C(96, 232, 70),
		mats = {
			wall = M.Marble,
			stone = M.Marble,
			beam = M.Marble,
			roof = M.ClayRoofTiles,
			chimney = M.Marble,
			cap = M.Marble,
			oven = M.Marble,
			gold = M.Foil, -- (thin trims; the big gold pieces ask for Metal)
			accent = M.Metal,
		},
	},
}

-- A level's era (1-5) and how many of the 25 features it has.
function Kitchen.features(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	return era, (era - 1) * 5 + math.max(0, s - 5)
end

-- The lawn beside the pad that the chimney, the oven, the kettles, the terrace and the wing stand on (x0, x1, z0,
-- z1): scenery there goes. (SPLIT_Z: what Architecture.grow takes as the house, all of it; the point it grows round.)
local SPLIT_Z, PIVOT_X, PIVOT_Z = -100, 0, -5
function Kitchen.footprint(level: number): (number, number, number, number)
	local _, f = Kitchen.features(level)
	local x0 = if f >= 12 then -34 elseif f >= 5 then -25.5 else -15.5
	local x1 = if f >= 20 then 25 else 19.6
	return Architecture.grownBox(
		"Kitchen",
		SPLIT_Z,
		PIVOT_X,
		PIVOT_Z,
		x0,
		x1,
		-7,
		if f >= 12 then TERRACE_BACK + 0.7 else 13.6
	)
end

-- Where the dining table stands (x, z) and the top of the ground under it (a stud towards the hall while the
-- lean-to's posts stand at its far end; in the middle of the colonnade).
function Kitchen.terrace(level: number): (number, number, number)
	local _, f = Kitchen.features(level)
	return if f >= 24 then TCX else TCX + 1, TCZ, if f >= 11 then 0.7 else 0.12
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
	local era, f = Kitchen.features(level)
	local L = LOOKS[era]
	local skins: { [string]: Enum.Material } = {
		[IRON:ToHex()] = M.Metal,
		[SOOT:ToHex()] = M.Metal,
		[PLANK:ToHex()] = M.WoodPlanks,
		[BOX:ToHex()] = M.Wood,
		[AWN_RED:ToHex()] = M.Fabric,
	}
	for field, material in L.mats do
		skins[((L :: any)[field] :: Color3):ToHex()] = material
	end
	local b = Architecture.new(m, frame, skins, 0.4)
	local wallH, rise = L.wallH, L.rise
	local vault = era == 4
	local half = if era == 5 then AISLE else HW -- half the main roof's span
	local pitch = rise / half
	local ridge = wallH + rise
	local zf = Z0 + T / 2 -- the middle of the front wall
	local turn = CFrame.Angles(0, math.pi / 2, 0) -- (a roof whose ridge runs front to back)
	local bigGold = if era >= 4 then M.Metal else nil
	local function roofY(u: number): number -- the roof's height `u` from the ridge line
		u = math.abs(u)
		if u >= half then
			return wallH
		end
		return if vault then wallH + rise * math.sqrt(1 - (u / half) ^ 2) else ridge - pitch * u
	end
	local function roofU(y: number): number -- how far from the ridge line the roof stands at height `y`
		local t = math.clamp((y - wallH) / rise, 0, 1)
		return if vault then half * math.sqrt(1 - t * t) else half * (1 - t)
	end

	-- a wall or a floor from corner to corner
	local function slab(
		name: string,
		xa: number,
		xb: number,
		y0: number,
		y1: number,
		z0: number,
		z1: number,
		colour: Color3,
		material: Enum.Material?
	)
		local x0, x1 = math.min(xa, xb), math.max(xa, xb)
		if x1 - x0 > 0.05 and y1 - y0 > 0.05 and z1 - z0 > 0.05 then
			b.box(name, x1 - x0, y1 - y0, z1 - z0, b.at((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour, material)
		end
	end
	-- THE BLENDER PIECES (docs/areas/village-v2/hard-pieces.md): meshes of the library kit, nil while one is not
	-- there (not uploaded yet, or it did not load): the caller then builds its stand-in from parts.
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
	-- THE OWNER'S MESHY PIECES wear their own picture: unpainted, at `s` times their size in Config.LibraryKit
	local function painted(name: string, cf: CFrame, s: number, deep: number?): BasePart?
		return piece(name, cf, s, s, deep or s, Color3.new(1, 1, 1), M.SmoothPlastic)
	end
	-- a tiled cone roof `r` round at the eave and `up` high, the middle of its foot at `cf`
	local function coneRoof(cf: CFrame, r: number, up: number, colour: Color3)
		if piece("ConeRoof_Tiles", cf, r, up / 1.3, r, colour) then
			local s = r * 1.3
			piece("ConeRoof_Finial", cf * CFrame.new(0, up - 0.04 * s, 0), s, s, s, L.gold)
		else
			b.cone(cf, r, up, 5, colour, L.gold)
		end
	end
	-- the capital's dome, `r` round, on its drum's top at `cf`: a shell under golden ribs, a lantern and a finial.
	-- Returns its height.
	local function dome(cf: CFrame, r: number): number
		if piece("RoyalDome_Gold", cf, r, r, r, L.gold, M.Metal) then
			piece("RoyalDome_Shell", cf, r, r, r, L.roof)
		else
			b.ball("Dome", r, cf, L.roof)
			b.cyl("DomeLantern", r * 0.2, r * 0.5, cf * CFrame.new(0, r * 1.2, 0), L.gold, M.Metal, false)
			b.ball("Finial", r * 0.14, cf * CFrame.new(0, r * 1.55, 0), L.gold, M.Metal)
		end
		return 1.95 * r
	end
	-- a column `r` round from `y0` to `y1`: its base and capital from the kit
	local function column(x: number, z: number, y0: number, y1: number, r: number)
		local s = r / 0.5 -- (the meshes are drawn for a shaft one stud through)
		local foot, head = 0.4, 0.4
		if piece("Column_Base", b.at(x, y0, z), s, s, s, L.gold) then
			foot, head = 0.45 * s, 0.7 * s
			piece("Column_Capital", b.at(x, y1 - head, z), s, s, s, L.gold)
		else
			b.cyl("ColumnFoot", r + 0.2, 0.4, b.at(x, y0 + 0.2, z), L.stone, nil, false)
			b.cyl("ColumnHead", r + 0.2, 0.4, b.at(x, y1 - 0.2, z), L.gold, nil, false)
		end
		b.cyl("Column", r, y1 - y0 - foot - head, b.at(x, (y0 + foot + y1 - head) / 2, z), L.wall)
	end
	-- a balustrade from (xa, za) to (xb, zb), its foot at `y`: a post about every four studs, an urn on each when
	-- asked
	local function balustrade(xa: number, za: number, xb: number, zb: number, y: number, colour: Color3, urns: boolean)
		local run = Vector3.new(xb - xa, 0, zb - za)
		local len = run.Magnitude
		if len < 1 then
			return
		end
		local dir = run.Unit
		local bays = math.max(1, math.round(len / 4))
		local step = len / bays
		local along = CFrame.Angles(0, math.atan2(-dir.Z, dir.X), 0)
		local kit = LibraryKit.find("Balustrade_Run") ~= nil
		for i = 0, bays do
			local cf = b.at(xa + dir.X * i * step, y, za + dir.Z * i * step) * along
			if kit then
				piece("Balustrade_Post", cf, 1, 1, 1, colour)
				if urns then
					piece("Balustrade_Urn", cf * CFrame.new(0, 1.3, 0), 1.3, 1.3, 1.3, L.gold)
				end
				if i < bays then
					piece("Balustrade_Run", cf * CFrame.new(step / 2, 0, 0), (step - 0.5) / 4, 1, 1, colour)
				end
			else
				b.trim("RailPost", 0.6, 1.3, 0.6, cf * CFrame.new(0, 0.65, 0), colour)
				if urns then
					b.ball("Urn", 0.42, cf * CFrame.new(0, 1.7, 0), L.gold)
				end
				if i < bays then
					b.trim("RailTop", step - 0.5, 0.25, 0.45, cf * CFrame.new(step / 2, 1, 0), colour)
					b.trim("RailFoot", step - 0.5, 0.2, 0.4, cf * CFrame.new(step / 2, 0.1, 0), colour)
					local n = math.max(2, math.floor((step - 0.6) / 0.9))
					for k = 1, n do
						local along2 = 0.3 + (step - 0.6) * (k - 0.5) / n
						b.trim("Baluster", 0.26, 0.7, 0.26, cf * CFrame.new(along2, 0.55, 0), colour)
					end
				end
			end
		end
	end
	-- a flower box `w` wide, the face at the middle of its back
	local function flowerBox(face: CFrame, w: number, yellow: boolean?)
		-- (the owner's Meshy box is 3.6 wide and 3 deep: made `w` wide and half as deep, to sit under a window)
		local s = w / 3.6
		local kind = if yellow then "FlowerBox_Yellow" else "FlowerBox_Pink"
		if painted(kind, face * CFrame.new(0, -0.35, -0.75 * s), s, s * 0.5) then
			return
		end
		b.trim("FlowerBox", w, 0.7, 0.9, face * CFrame.new(0, 0, -0.45), BOX)
		b.trim("FlowerLeaves", w - 0.2, 0.4, 0.75, face * CFrame.new(0, 0.45, -0.45), LEAF)
		local n = math.max(3, math.round(w / 0.7))
		for i = 1, n do
			local across = -w / 2 + (i - 0.5) * w / n
			b.ball("Flower", 0.3, face * CFrame.new(across, 0.72, -0.45 - (i % 2) * 0.15), BLOOMS[i % 3 + 1])
		end
	end
	-- a big lantern hanging from `cf`
	local function lantern(cf: CFrame, lit: boolean)
		b.trim("LanternChain", 0.12, 0.5, 0.12, cf * CFrame.new(0, -0.25, 0), IRON)
		b.trim("LanternTop", 0.8, 0.25, 0.8, cf * CFrame.new(0, -0.45, 0), IRON)
		b.trim("LanternCap", 1.3, 0.22, 1.3, cf * CFrame.new(0, -0.66, 0), IRON)
		local pane = b.trim("Lantern", 0.95, 1.3, 0.95, cf * CFrame.new(0, -1.4, 0), L.glass, M.Neon)
		for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			b.trim("LanternBar", 0.12, 1.3, 0.12, cf * CFrame.new(c[1] * 0.48, -1.4, c[2] * 0.48), IRON)
		end
		b.trim("LanternFoot", 1.15, 0.2, 1.15, cf * CFrame.new(0, -2.14, 0), IRON)
		if lit then
			local light = Instance.new("PointLight")
			light.Color = L.glass
			light.Range = 14
			light.Brightness = 0.6
			light.Parent = pane
		end
	end
	-- the owner's Meshy wall lantern, its plate on the wall at `cf`, lit; false while it is not there
	local function wallLantern(cf: CFrame, s: number): boolean
		local lamp = painted("WallLantern_Iron", cf, s)
		if lamp then
			local light = Instance.new("PointLight")
			light.Color = L.glass
			light.Range = 14
			light.Brightness = 0.6
			light.Parent = lamp
		end
		return lamp ~= nil
	end
	-- a pipe through `points` (in the building's frame), a fitting at every bend and at its end
	local function pipe(points: { Vector3 }, r: number, colour: Color3)
		for i = 1, #points - 1 do
			b.rod("Pipe", r, points[i], points[i + 1], colour)
			local p = points[i + 1]
			b.ball("PipeJoint", r * 1.5, b.at(p.X, p.Y, p.Z), L.gold, bigGold)
		end
	end

	-- THE FRONT ------------------------------------------------------------------------------------------------
	local bayX = if era == 5 then (BAY + HW) / 2 else 12.1 -- the middle of a side bay's window
	if era <= 2 then
		-- posts on stone pads under a tie beam, knee braces; the side bays a plank rail, then a low plaster wall
		local tieY = wallH - 0.9
		local zp = Z0 + 0.45
		for _, x in { -(HW - 0.45), -BAY, BAY, HW - 0.45 } do
			b.box("PostPad", 1.5, 0.6, 1.5, b.at(x, FLOOR + 0.3, zp), L.stone)
			b.box("Post", 0.9, tieY - FLOOR - 0.6, 0.9, b.at(x, (FLOOR + 0.6 + tieY) / 2, zp), L.beam)
		end
		b.box("TieBeam", HW * 2 + 1.2, 0.9, 0.9, b.at(0, tieY + 0.45, zp), L.beam)
		for _, s in { -1, 1 } do
			for _, br in { { BAY - 0.45, -2.6 }, { BAY + 0.45, 1.6 }, { HW - 0.9, -1.6 } } do
				local foot = Vector3.new(s * br[1], tieY - math.abs(br[2]), zp)
				b.beam("Brace", 0.5, 0.5, foot, Vector3.new(s * (br[1] + br[2]), tieY, zp), L.beam)
			end
			local x0, x1 = BAY + 0.45, HW - 0.9
			local bx = s * (x0 + x1) / 2
			if era == 1 then
				for _, y in { 1.6, 2.8 } do
					b.trim("BayRail", x1 - x0, 0.35, 0.3, b.at(bx, y, zp), L.lower)
				end
			else
				b.box("BayWall", x1 - x0, 3.2, 0.5, b.at(bx, FLOOR + 1.6, zp), L.wall)
				b.trim("BayCap", x1 - x0 + 0.2, 0.35, 0.9, b.at(bx, FLOOR + 3.37, zp), L.beam)
				if f >= 6 then
					flowerBox(b.face(bx, FLOOR + 2.7, Z0 + 0.2, FRONT), 3.2) -- 6 (at the front corners)
				end
			end
			if f >= 1 and not wallLantern(b.at(s * BAY, tieY - 0.5, Z0 - 0.3), 1.5) then
				-- 1 a big lantern on each front post, with a real light
				b.trim("LanternArm", 0.2, 0.2, 1.4, b.at(s * BAY, tieY + 0.45, Z0 - 0.6), IRON)
				lantern(b.at(s * BAY, tieY + 0.35, Z0 - 1.05), true)
			end
		end
	else
		-- piers either side of ONE wide arch (four straight cuts a side), a ring of stones round it
		local spring, R = L.spring, L.archR
		local function archAt(k: number, grow: number): (number, number) -- its point `k` (0 the jamb, 4 the crown)
			local t = math.rad(k * 22.5)
			return (BAY + grow) * math.cos(t), spring + (R + grow) * math.sin(t)
		end
		local top = if era == 5 then wallH - 1.2 else wallH -- (the capital's entablature takes the rest)
		local ring = if era == 3 then L.frame elseif era == 4 then L.beam else L.gold
		for _, s in { -1, 1 } do
			local bx = s * (BAY + HW) / 2
			b.box("Pier", HW - BAY, wallH, T, b.at(bx, wallH / 2, zf), L.lower)
			b.trim("PierFoot", HW - BAY + 0.4, 1, T + 0.4, b.at(bx, 0.5, zf), L.stone)
			if era <= 4 then
				for i = 0, 3 do
					local long = if i % 2 == 0 then 1.3 else 0.9
					b.trim("Quoin", long, 0.62, T + 0.16, b.at(s * (BAY + long / 2), 1.35 + i * 0.9, zf), L.frame)
				end
			end
			b.trim("Impost", 1.5, 0.45, T + 0.4, b.at(s * (BAY + 0.55), spring - 0.1, zf), L.frame)
			for k = 0, 3 do
				local px, py = archAt(k, 0)
				local qx, qy = archAt(k + 1, 0)
				slab("FrontWall", s * qx, s * px, qy, top, Z0, Z0 + T, L.lower)
				-- (a wedge turned over: its flat face up under the wall, its slope along the arch)
				b.wedge(
					"FrontWall",
					T,
					qy - py,
					px - qx,
					frame
						* CFrame.fromMatrix(
							Vector3.new(s * (px + qx) / 2, (py + qy) / 2, zf),
							Vector3.new(0, 0, s),
							Vector3.new(0, -1, 0),
							Vector3.new(s, 0, 0)
						),
					L.lower
				)
				-- (the town's arch is cut stone: prouder voussoirs, every other one darker)
				local cut = era == 3
				local ax, ay = archAt(k, if cut then 0.45 else 0.35)
				local ex, ey = archAt(k + 1, if cut then 0.45 else 0.35)
				b.beam(
					"ArchRing",
					T + (if cut then 0.7 else 0.3),
					if cut then 0.9 else 0.7,
					Vector3.new(s * ax, ay, zf),
					Vector3.new(s * ex, ey, zf),
					if cut and k % 2 == 1 then L.stone else ring,
					bigGold
				)
				if era == 5 then
					-- (the capital's portal: a marble lining inside the gold ring, deeper than the wall)
					local ix, iy = archAt(k, -0.3)
					local jx, jy = archAt(k + 1, -0.3)
					b.beam("PortalSoffit", T + 1, 0.6, Vector3.new(s * ix, iy, zf), Vector3.new(s * jx, jy, zf), L.wall)
				end
			end
			if era == 5 then
				b.box("PortalJamb", 0.6, spring, T + 1, b.at(s * (BAY - 0.3), spring / 2, zf), L.wall)
				b.trim("PortalImpost", 0.9, 0.3, T + 1.3, b.at(s * (BAY - 0.35), spring + 0.15, zf), L.gold, bigGold)
			end
			-- the side bay: a blank arched recess, then (13) a lit arched window; a flower box under it (6)
			local wy = if era == 5 then 4 else 3.2
			local face = b.face(s * bayX, wy, Z0, FRONT)
			if f >= 13 then
				b.window(face, 1.8, 2.4, L.frame, L.glass, { arch = true, glow = true })
			else
				b.trim("Recess", 1.8, 2.4, 0.16, face * CFrame.new(0, 0, -0.02), L.stone)
				b.disc("RecessHead", 0.9, 0.16, face * CFrame.new(0, 1.2, -0.02), L.stone)
				b.trim("RecessSill", 2.7, 0.25, 0.6, face * CFrame.new(0, -1.5, -0.3), L.frame)
			end
			flowerBox(face * CFrame.new(0, -2, 0), 2.6)
			if f >= 16 and not painted("Banner_SlimeBlue", b.face(s * bayX, top - 2.15, Z0, FRONT), 0.7) then
				-- 16 blue banners on the front piers
				b.banner(b.face(s * bayX, top - 0.4, Z0, FRONT), 1.5, 2.6, L.cloth, L.gold)
			end
			if f >= 1 then
				-- 1 the big lanterns: beside the arch, and inside it once columns stand before the piers
				if era == 5 then
					-- (on the portal's lining, 0.6 inside the opening)
					local jx = BAY - 0.6
					if not wallLantern(b.face(s * jx, spring + 1, Z0 - 0.15, Vector3.new(-s, 0, 0)), 1.2) then
						b.trim("LanternArm", 1.6, 0.2, 0.2, b.at(s * (jx - 0.8), spring + 1.9, Z0 - 0.15), IRON)
						lantern(b.at(s * (jx - 1.4), spring + 1.8, Z0 - 0.15), true)
					end
				elseif not wallLantern(b.at(s * (BAY + 0.75), 6.5, Z0), 1.5) then
					b.trim("LanternArm", 0.2, 0.2, 1.4, b.at(s * (BAY + 0.75), 7.6, Z0 - 0.6), IRON)
					lantern(b.at(s * (BAY + 0.75), 7.5, Z0 - 1.05), true)
				end
			end
		end
		local key = if era == 3 then 1.5 else 1.2
		b.trim("Keystone", key, key + 0.1, T + key - 0.7, b.at(0, spring + R + 0.55, zf), ring, bigGold)
	end

	-- THE WALLS ------------------------------------------------------------------------------------------------
	-- the back wall, two lit windows through it either side of the stove
	local backColour = if era == 3 or era == 4 then L.lower else L.wall
	slab("BackWall", -HW, HW, FLOOR, wallH, Z1 - T, Z1, backColour)
	if era <= 2 then
		b.timber(b.face(0, (FLOOR + wallH) / 2, Z1 - T, FRONT), HW * 2 - T * 2, wallH - FLOOR, L.beam)
	end
	for _, x in { -6, 6 } do
		b.window(b.face(x, 5.6, Z1, BACK), 2, 2.2, L.frame, L.glass, { glow = true, through = T, arch = era >= 3 })
	end
	-- the side walls
	local sideLen = LEN - T * 2
	local bays = bayCentres(sideLen)
	local zm = (Z0 + T + Z1 - T) / 2
	for _, s in { -1, 1 } do
		local out = Vector3.new(s, 0, 0)
		local xw = s * (HW - T / 2)
		if era == 1 then
			-- a plank half wall between posts: a shed, open under the eaves
			slab("HalfWall", s * (HW - T), s * HW, FLOOR, 3.6, Z0 + 0.9, Z1 - T, L.lower)
			b.trim("WallCap", T + 0.3, 0.3, Z1 - T - Z0 - 0.9, b.at(xw, 3.75, (Z0 + 0.9 + Z1 - T) / 2), L.beam)
			for i = 1, 3 do
				local z = Z0 + 0.45 + i * (LEN - 0.75) / 4
				b.box("SidePost", 0.7, wallH - FLOOR, 0.7, b.at(s * (HW - 0.4), (FLOOR + wallH) / 2, z), L.beam)
			end
			b.box("WallPlate", 0.8, 0.6, LEN, b.at(s * (HW - 0.4), wallH - 0.3, ZC), L.beam)
		elseif vault then
			-- a brick foot under glass in a steel frame
			slab("SideWall", s * (HW - T), s * HW, FLOOR, 4.4, Z0 + T, Z1 - T, L.lower)
			b.box("SideGlass", 0.3, wallH - 4.9, sideLen, b.at(s * (HW - 0.3), (4.4 + wallH - 0.5) / 2, zm), L.wall)
			b.box("WallPlate", 0.7, 0.5, LEN, b.at(s * (HW - 0.35), wallH - 0.25, ZC), L.beam)
			b.trim("SillRail", 0.8, 0.3, sideLen, b.at(s * (HW - 0.3), 4.55, zm), L.beam)
			for i = 0, 4 do
				local z = Z0 + 0.2 + i * (LEN - 0.4) / 4
				b.trim("SidePost", 0.5, wallH - 4.4, 0.4, b.at(s * (HW - 0.3), (4.4 + wallH) / 2, z), L.beam)
			end
		else
			slab("SideWall", s * (HW - T), s * HW, FLOOR, wallH, Z0 + T, Z1 - T, if era == 3 then L.lower else L.wall)
			-- framing (teal timber, then the capital's pilasters) at the bays' edges, the windows between
			local n = #bays
			local step = (sideLen - 0.4) / n
			if era ~= 3 then
				for i = 0, n do
					local z = Z0 + T + 0.2 + i * step
					if era == 2 then
						b.trim("Post", 0.3, wallH - FLOOR, 0.4, b.at(s * (HW + 0.1), (FLOOR + wallH) / 2, z), L.beam)
					else
						b.trim("Pilaster", 0.3, wallH - 1.2, 1, b.at(s * (HW + 0.15), (wallH - 1.2) / 2, z), L.stone)
					end
				end
			end
			if era == 2 then
				for _, y in { FLOOR + 0.2, 6.2, wallH - 0.2 } do
					b.trim("Rail", 0.3, 0.4, sideLen, b.at(s * (HW + 0.1), y, zm), L.beam)
				end
			end
			-- (on the left the chimney and the oven take the middle; on the right the terrace is the front half)
			local at: { number } = if s > 0 then { 1, 5 } else { 1, 3 }
			for _, i in at do
				b.window(
					b.face(s * HW, 4, zm - s * bays[i], out),
					1.8,
					2.2,
					L.frame,
					L.glass,
					{ shutters = L.shutters, arch = era >= 3, glow = true, through = T }
				)
			end
		end
	end

	-- THE ROOF -------------------------------------------------------------------------------------------------
	if era <= 3 then
		-- a great gable to the front. Before feature 2 its front is an open truss; then it is closed with plaster
		-- between timbers and a shuttered window (2).
		local open = f < 2
		b.gable(
			b.at(0, wallH, ZC) * turn,
			LEN,
			HW * 2,
			rise,
			L.over,
			L.roof,
			L.wall,
			L.board,
			nil,
			L.thick,
			if open then -1 else nil
		)
		local under = L.thick + 0.5 -- (how far a timber's top keeps under the roof's line)
		if open then
			local zr = Z0 + 0.45
			for _, s in { -1, 1 } do
				b.beam(
					"Rafter",
					0.6,
					0.6,
					Vector3.new(s * (HW - 0.3), wallH + 0.1, zr),
					Vector3.new(0, ridge - under, zr),
					L.beam
				)
				b.beam(
					"Strut",
					0.45,
					0.45,
					Vector3.new(s * 3.4, wallH, zr),
					Vector3.new(s * 6.8, roofY(6.8) - under - 0.4, zr),
					L.beam
				)
				-- (the barge board the roof's own would have had)
				local zb = Z0 - L.over - 0.05
				b.beam(
					"BargeBoard",
					0.25,
					L.thick + 0.3,
					Vector3.new(s * (HW + L.over), wallH - pitch * L.over - L.thick / 2, zb),
					Vector3.new(0, ridge - L.thick / 2, zb),
					L.board
				)
			end
			b.trim("KingPost", 0.6, rise - under, 0.6, b.at(0, wallH + (rise - under) / 2, zr), L.beam)
			b.trim("Collar", roofU(wallH + rise * 0.55) * 2 - 1, 0.5, 0.5, b.at(0, wallH + rise * 0.55, zr), L.beam)
		else
			local zg = Z0 - 0.1
			for _, s in { -1, 1 } do
				b.beam(
					"GableRafter",
					0.3,
					0.5,
					Vector3.new(s * (HW - 0.4), wallH + 0.3, zg),
					Vector3.new(0, ridge - under - 0.25, zg),
					L.beam
				)
				b.beam(
					"GableStrut",
					0.3,
					0.45,
					Vector3.new(s * 3.4, wallH + 0.2, zg),
					Vector3.new(s * 6.8, roofY(6.8) - under - 0.5, zg),
					L.beam
				)
			end
			b.trim("GablePost", 0.5, rise - under - 0.5, 0.3, b.at(0, wallH + (rise - under - 0.5) / 2, zg), L.beam)
			b.trim("GableCollar", roofU(wallH + 3.3) * 2 - 2, 0.45, 0.3, b.at(0, wallH + 3.3, zg), L.beam)
			local wy = wallH + L.winY
			local ww = if era == 3 then 1.6 else 2.2
			b.window(b.face(0, wy, Z0, FRONT), ww, ww - 0.2, L.frame, L.glass, { shutters = L.shutters, glow = true })
			if f >= 6 then
				flowerBox(b.face(0, wy - ww / 2 - 0.75, Z0, FRONT), ww + 0.9, true) -- 6 (under the gable window)
			end
		end
		if era == 1 then
			-- thatch: a roll along each eave and over the ridge (the owner's choice, 2026-11-17: the Meshy straw laid
			-- over the slabs showed in patches, "xấu lắm")
			for _, s in { -1, 1 } do
				local ex, ey = s * (HW + L.over), wallH - pitch * L.over - 0.25
				b.rod("EaveRoll", 0.55, Vector3.new(ex, ey, Z0 - L.over), Vector3.new(ex, ey, Z1 + L.over), L.roof)
			end
			b.rod(
				"RidgeRoll",
				0.7,
				Vector3.new(0, ridge + 0.1, Z0 - L.over - 0.1),
				Vector3.new(0, ridge + 0.1, Z1 + L.over + 0.1),
				L.roof
			)
		end
		-- two trusses inside, seen through the open front (clear of the stove)
		for _, z in { Z0 + 4.3, Z1 - 1.8 } do
			b.box("Truss", HW * 2 - T * 2, 0.6, 0.6, b.at(0, wallH - 0.3, z), L.beam)
			b.trim("TrussPost", 0.5, rise - under, 0.5, b.at(0, wallH + (rise - under) / 2, z), L.beam)
			for _, s in { -1, 1 } do
				b.beam(
					"TrussRafter",
					0.5,
					0.5,
					Vector3.new(s * (HW - 0.8), wallH + 0.1, z),
					Vector3.new(0, ridge - under, z),
					L.beam
				)
			end
		end
		if era == 3 then
			-- the timber gable stands out over the stone storey on a beam and corbels
			b.box("JettyBeam", HW * 2 + 0.8, 0.8, 1.3, b.at(0, wallH - 0.4, Z0 + 0.15), L.beam)
			-- (corbels on the piers only: over the opening they stood in the arch's stones)
			for _, x in { -HW + 0.5, -11.9, -BAY, BAY, 11.9, HW - 0.5 } do
				b.trim("Corbel", 0.6, 0.7, 0.9, b.at(x, wallH - 1.15, Z0 - 0.2), L.beam)
			end
		end
	elseif vault then
		-- a glass vault: six flat panes a side between steel ribs, purlins where the panes meet
		local function vaultAt(k: number, grow: number): (number, number) -- its point `k` (0 the eave, 6 the crown)
			local t = math.rad(k * 15)
			return (HW + grow) * math.cos(t), wallH + (rise + grow) * math.sin(t)
		end
		local za, zb = Z0 - L.over, Z1 + L.over
		for k = 0, 5 do
			local px, py = vaultAt(k, 0)
			local qx, qy = vaultAt(k + 1, 0)
			for _, s in { -1, 1 } do
				b.beam(
					"VaultGlass",
					LEN + L.over * 2,
					L.thick,
					Vector3.new(s * px, py, ZC),
					Vector3.new(s * qx, qy, ZC),
					L.roof
				)
				if k > 0 then
					b.beam("Purlin", 0.3, 0.3, Vector3.new(s * px, py, za), Vector3.new(s * px, py, zb), L.beam)
				end
			end
		end
		b.beam("Purlin", 0.4, 0.4, Vector3.new(0, ridge, za), Vector3.new(0, ridge, zb), L.beam)
		for i = 0, 4 do
			local z = Z0 + 0.2 + i * (LEN - 0.4) / 4
			-- (straight ribs, pane by pane: a curved model would stand off the flat glass)
			for k = 0, 5 do
				local px, py = vaultAt(k, 0)
				local qx, qy = vaultAt(k + 1, 0)
				for _, s in { -1, 1 } do
					b.beam("VaultRib", 0.4, 0.5, Vector3.new(s * px, py, z), Vector3.new(s * qx, qy, z), L.beam)
				end
			end
		end
		-- the vault's two ends: glass with a steel fan at the front, brick at the back
		local function tympanum(z0: number, deep: number, colour: Color3)
			for k = 0, 5 do
				local px, py = vaultAt(k, 0)
				local qx, qy = vaultAt(k + 1, 0)
				slab("Tympanum", -qx, qx, py, qy, z0, z0 + deep, colour)
				for _, s in { -1, 1 } do
					b.wedge(
						"Tympanum",
						deep,
						qy - py,
						px - qx,
						frame
							* CFrame.fromMatrix(
								Vector3.new(s * (px + qx) / 2, (py + qy) / 2, z0 + deep / 2),
								Vector3.new(0, 0, s),
								Vector3.new(0, 1, 0),
								Vector3.new(-s, 0, 0)
							),
						colour
					)
				end
			end
		end
		-- (the front glass stands 0.9 behind the steel fan, on a deep tie beam: flush with it the vault's face read
		-- as a flat drawn window)
		tympanum(Z0 + 0.9, 0.3, L.wall)
		tympanum(Z1 - T, T, L.lower)
		b.box("TieBeam", HW * 2 + 0.6, 0.5, 1.5, b.at(0, wallH, Z0 + 0.5), L.beam)
		local hub = Vector3.new(0, wallH + 0.2, Z0 + 0.2)
		for k = 1, 5 do
			local vx, vy = vaultAt(k, -0.4)
			for _, s in { -1, 1 } do
				b.beam("Fan", 0.5, 0.3, hub, Vector3.new(s * vx, vy, Z0 + 0.2), L.beam)
			end
		end
		b.beam("Fan", 0.5, 0.3, hub, Vector3.new(0, ridge - 0.4, Z0 + 0.2), L.beam)
		-- (a half ring through the spokes, round the emblem)
		local function ringAt(k: number): (number, number)
			local t = math.rad(k * 15)
			return 0.55 * HW * math.cos(t), wallH + 0.2 + 0.55 * rise * math.sin(t)
		end
		for k = 0, 5 do
			local px, py = ringAt(k)
			local qx, qy = ringAt(k + 1)
			for _, s in { -1, 1 } do
				local from, to = Vector3.new(s * px, py, Z0 + 0.2), Vector3.new(s * qx, qy, Z0 + 0.2)
				b.beam("FanRing", 0.5, 0.3, from, to, L.beam)
			end
		end
	else
		-- the capital: a pediment roof in blue slate over the middle, flat roofs over the side bays, an
		-- entablature on columns across the front
		b.gable(b.at(0, wallH, ZC) * turn, LEN, AISLE * 2, rise, L.over, L.roof, L.wall, L.gold, nil, L.thick)
		for _, s in { -1, 1 } do
			b.box("AisleRoof", HW - AISLE, 0.4, LEN, b.at(s * (HW + AISLE) / 2, wallH, ZC), L.stone)
			b.trim("Cornice", 0.5, 1.2, LEN, b.at(s * (HW + 0.25), wallH - 0.6, ZC), L.wall)
			b.trim("CorniceLine", 0.6, 0.2, LEN + 0.1, b.at(s * (HW + 0.3), wallH - 0.1, ZC), L.gold)
			for _, x in { BAY + 0.6, HW - 0.6 } do
				b.box("Pedestal", 1.7, 1.2, 1.7, b.at(s * x, 0.6, Z0 - 0.9), L.stone)
				column(s * x, Z0 - 0.9, 1.2, wallH - 1.2, 0.6)
			end
		end
		b.box("Entablature", HW * 2 + 1.1, 1.2, 2.3, b.at(0, wallH - 0.6, Z0 - 0.55), L.wall)
		b.trim("EntablatureLine", HW * 2 + 1.3, 0.2, 2.5, b.at(0, wallH - 0.1, Z0 - 0.55), L.gold)
		b.trim("EntablatureLine", HW * 2 + 1.2, 0.16, 2.4, b.at(0, wallH - 1.12, Z0 - 0.55), L.gold)
	end

	-- THE GREAT CHIMNEY ----------------------------------------------------------------------------------------
	-- three tiers on the left; from feature 3 a third taller, with a capstone, a flue and smoke
	local tall = f >= 3
	local top = ridge + (if tall then L.stack else 1.5)
	local midTop = math.min(wallH + 6, top - 3)
	local round = era == 5
	local function tier(name: string, w: number, y0: number, y1: number, colour: Color3, material: Enum.Material?)
		if round then
			b.cyl(name, w * 0.55, y1 - y0, b.at(CX, (y0 + y1) / 2, CZ), colour, material)
		else
			b.box(name, w, y1 - y0, w, b.at(CX, (y0 + y1) / 2, CZ), colour, material)
		end
	end
	tier("ChimneyFoot", 4.4, 0, 5, L.chimney)
	tier("ChimneyShoulder", 4, 5, 5.6, L.cap)
	tier("Chimney", 3.4, 5.6, midTop, L.chimney)
	tier("ChimneyShoulder", 3.2, midTop, midTop + 0.5, L.cap)
	tier("Chimney", 2.8, midTop + 0.5, top, L.chimney)
	if era >= 4 then
		for _, t in { 0.2, 0.55, 0.9 } do
			local y = midTop + (top - midTop) * t
			tier("ChimneyBand", 3.1, y - 0.22, y + 0.22, L.gold, M.Metal)
		end
		tier("ChimneyBand", 3.7, 8.2, 8.7, L.gold, M.Metal)
	elseif era == 3 then
		tier("ChimneyBand", 3.05, midTop + 4, midTop + 4.4, L.frame)
	end
	if tall then
		tier("ChimneyCap", 3.6, top, top + 0.7, L.cap)
		local flue = b.cyl("Flue", 0.85, 0.9, b.at(CX, top + 1.15, CZ), DARK, nil, false)
		-- 3 smoke: one soft emitter (the client's EffectsLod stops it far from the camera)
		local mouth = Instance.new("Attachment")
		mouth.Name = "SmokeMouth"
		mouth.Parent = flue
		mouth.WorldCFrame = b.at(CX, top + 1.6, CZ)
		local smoke = Instance.new("ParticleEmitter")
		smoke.Name = "ChimneySmoke"
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(C(248, 246, 242))
		smoke.LightEmission = 0
		smoke.Rate = 1.5
		smoke.Lifetime = NumberRange.new(5, 7)
		smoke.Speed = NumberRange.new(2.2, 3)
		smoke.SpreadAngle = Vector2.new(8, 8)
		smoke.Acceleration = Vector3.new(0.5, 0, 0)
		smoke.Rotation = NumberRange.new(0, 360)
		smoke.RotSpeed = NumberRange.new(-15, 15)
		smoke.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.4, 3.4),
			NumberSequenceKeypoint.new(1, 4.8),
		})
		smoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(0.6, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		smoke.Parent = mouth
	else
		b.trim("ChimneyMouth", 2, 0.1, 2, b.at(CX, top + 0.05, CZ), DARK)
	end
	if f >= 15 then
		-- 15 the smokehouse turret on the chimney's front corner: a lantern room on a corbel under a cone roof
		local tx, tz = CX + 1.5, CZ - 1.9
		local y0 = ridge - 4.5
		local drum = if vault then L.lower else L.wall
		b.cyl("TurretCorbel", 1.1, 0.6, b.at(tx, y0 - 0.9, tz), L.cap, nil, false)
		b.cyl("TurretCorbel", 1.6, 0.6, b.at(tx, y0 - 0.3, tz), L.cap, nil, false)
		b.cyl("TurretDrum", 1.9, 4, b.at(tx, y0 + 2, tz), drum)
		for _, y in { y0 + 0.2, y0 + 3.8 } do
			b.cyl("TurretBand", 2.05, 0.4, b.at(tx, y, tz), L.board, nil, false)
		end
		for k = -3, 1 do
			local spin = b.at(tx, y0 + 2, tz) * CFrame.Angles(0, k * math.pi / 4, 0)
			b.trim("TurretWindow", 1, 1.7, 0.2, spin * CFrame.new(0, 0, -1.84), L.glass, M.Neon)
			local post = spin * CFrame.Angles(0, math.pi / 8, 0) * CFrame.new(0, 0, -1.9)
			b.trim("TurretPost", 0.3, 3.6, 0.25, post, L.board)
		end
		coneRoof(b.at(tx, y0 + 4, tz), 2.5, 3.6, if vault then L.accent else L.roof)
	end
	if f >= 22 then
		-- 22 a gold crown on the chimney's top
		local cf, r = b.at(CX, top + 0.7, CZ), 2.1
		if not piece("ChimneyCrown_Gold", cf, r, r, r, L.gold, M.Metal) then
			b.cyl("Crown", r, r * 0.5, cf * CFrame.new(0, r * 0.25, 0), L.gold, M.Metal, false)
			for k = 0, 5 do
				local point = cf * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, r * 0.75, -r * 0.88)
				b.trim("CrownPoint", r * 0.3, r * 0.7, r * 0.2, point, L.gold, M.Metal)
			end
		end
	end
	if f >= 10 then
		-- 10 the domed bread oven at the chimney's front foot, its mouth glowing
		-- (the owner's Meshy ovens: the red brick one, then the stone one from the town era on)
		local ox, oz = CX, 2
		local brick = era == 2
		if not painted(if brick then "Oven_Brick" else "Oven_Stone", b.at(ox, 0, oz), if brick then 1 else 0.85) then
			b.box("OvenBase", 4.4, 2, 4, b.at(ox, 1, oz), L.chimney)
			b.trim("OvenShelf", 4.7, 0.3, 4.3, b.at(ox, 2.15, oz), L.cap)
			b.ball("OvenDome", 2, b.at(ox, 2.3, oz), L.oven)
			b.trim("OvenPorch", 2.5, 0.7, 1, b.at(ox, 2.65, oz - 1.6), L.oven)
			b.disc("OvenArch", 1.25, 1, b.face(ox, 3, oz - 1.6, FRONT), L.oven)
			b.trim("OvenHole", 1.6, 0.6, 0.12, b.at(ox, 2.6, oz - 2.12), DARK)
			b.disc("OvenHole", 0.8, 0.12, b.face(ox, 2.9, oz - 2.12, FRONT), DARK)
			b.disc("OvenFire", 0.55, 0.1, b.face(ox, 2.75, oz - 2.2, FRONT), EMBER, M.Neon)
			b.trim("OvenFire", 1.2, 0.3, 0.1, b.at(ox, 2.48, oz - 2.2), EMBER, M.Neon)
		end
	end
	if f >= 20 and L.goo then
		-- 20 two kettles of glowing goo beside the chimney, piped into it
		for i, k in KETTLES do
			local kx, kz = k[1], k[2]
			b.cyl("KettleBase", 2, 1.4, b.at(kx, 0.7, kz), if era == 5 then L.stone else L.lower)
			b.silo(kx, 1.4, kz, 1.5, 3.2, L.wall, L.gold, "none", IRON, L.goo)
			local cap = b.at(kx, 5.4, kz)
			if piece("GlassDome_Frame", cap, 1.55, 1.55, 1.55, IRON) then
				piece("GlassDome_Glass", cap, 1.55, 1.55, 1.55, L.goo, M.Glass)
				piece("GlassDome_Finial", cap * CFrame.new(0, 0.99 * 1.55, 0), 1.55, 1.55, 1.55, L.gold)
			else
				b.ball("KettleCap", 1.55, cap, IRON)
				b.ball("Finial", 0.3, cap * CFrame.new(0, 1.7, 0), L.gold, M.Metal)
			end
			local y = 8.6 + i
			local z = CZ + 1.2 - i * 0.8
			pipe({
				Vector3.new(kx, 6.8, kz),
				Vector3.new(kx, y, kz),
				Vector3.new(kx, y, z),
				Vector3.new(CX + 1.6, y, z),
			}, 0.3, L.accent)
		end
	end

	-- THE TERRACE ----------------------------------------------------------------------------------------------
	local tY = if f >= 11 then 0.7 else 0.12 -- its floor's top
	if f >= 11 then
		-- 11 raised on stone, a balustrade round it; 12 it reaches further out and back past the wing's side, four
		-- parasols over new tables
		local edge = if f >= 12 then -33 else TX - 1.2 -- how far out the raised floor reaches
		local rail = if era == 5 then L.wall else L.frame
		local zr = Z0 + 0.15
		slab("Terrace", edge, -HW, 0, tY, Z0 - 0.2, WING_Z, L.stone)
		local paved = b.at((edge - HW) / 2, tY + 0.03, (Z0 - 0.2 + WING_Z) / 2)
		b.trim("TerracePaving", -HW - edge - 0.8, 0.06, WING_Z - Z0 - 0.6, paved, rail)
		for i = 1, 2 do
			-- (two steps up at the table: the lower one further out)
			b.box("TerraceStep", 4.4, 0.35 * i, 0.8, b.at(TCX, 0.175 * i, Z0 - 0.6 - (2 - i) * 0.8), L.stone)
		end
		balustrade(-HW - 0.4, zr, TCX + 2.4, zr, tY, rail, false)
		balustrade(TCX - 2.4, zr, edge + 0.35, zr, tY, rail, false)
		if f >= 12 then
			-- (the back part: beside the wing and a little behind it, railed on its three open sides)
			local back, inner = TERRACE_BACK, WING_X - 0.4
			slab("Terrace", edge, inner, 0, tY, WING_Z, back, L.stone)
			local paved2 = b.at((edge + inner) / 2, tY + 0.03, (WING_Z + back) / 2 - 0.4)
			b.trim("TerracePaving", inner - edge - 0.8, 0.06, back - WING_Z, paved2, rail)
			balustrade(edge + 0.35, zr, edge + 0.35, back - 0.35, tY, rail, false)
			balustrade(edge + 0.35, back - 0.35, inner - 0.35, back - 0.35, tY, rail, false)
			balustrade(inner - 0.35, back - 0.35, inner - 0.35, Z1 + 0.9, tY, rail, false)
		else
			balustrade(edge + 0.35, zr, edge + 0.35, WING_Z - 0.35, tY, rail, false)
			balustrade(edge + 0.35, WING_Z - 0.35, WING_X - 0.4, WING_Z - 0.35, tY, rail, false)
		end
		if f >= 12 then
			for i, z in { -2.2, 3.1, 8.6, 13.9 } do
				-- (in a zigzag, one nearer the house, one further out: all show from the front and none touches another)
				local x = if i % 2 == 1 then -26.4 else -30
				-- (the owner's Meshy parasol tables, stools and all: red ones and blue ones)
				if painted(if i % 2 == 1 then "ParasolTable_Red" else "ParasolTable_Blue", b.at(x, tY, z), 0.75) then
					continue
				end
				b.cyl("ParasolTable", 1.3, 0.25, b.at(x, tY + 2.2, z), PLANK, nil, false)
				b.cyl("ParasolFoot", 0.55, 0.3, b.at(x, tY + 0.15, z), IRON, nil, false)
				b.rod("ParasolPole", 0.14, Vector3.new(x, tY, z), Vector3.new(x, tY + 6.9, z), IRON)
				for _, sx in { -1.9, 1.9 } do
					b.cyl("Stool", 0.5, 1.3, b.at(x + sx, tY + 0.65, z), PLANK, nil, false)
				end
				b.cyl("ParasolRim", 2.8, 0.2, b.at(x, tY + 5.6, z), WHITE, M.Fabric, false)
				b.cone(b.at(x, tY + 5.7, z), 2.7, 1.3, 3, AWN_RED, L.gold)
			end
		end
	end
	if f >= 24 then
		-- 24 a round colonnade under its own small blue dome
		local r, up = 5, 7.4
		for k = 0, 7 do
			local a = math.rad(22.5 + k * 45)
			column(TCX + r * math.cos(a), TCZ + r * math.sin(a), tY, up, 0.5)
		end
		b.cyl("ColonnadeRing", r + 0.7, 1, b.at(TCX, up + 0.5, TCZ), L.wall)
		b.cyl("ColonnadeLine", r + 0.8, 0.22, b.at(TCX, up + 1, TCZ), L.gold, M.Metal, false)
		b.cyl("ColonnadeLine", r + 0.75, 0.16, b.at(TCX, up + 0.1, TCZ), L.gold, M.Metal, false)
		b.cyl("DomeDrum", 4.6, 0.9, b.at(TCX, up + 1.45, TCZ), L.wall)
		dome(b.at(TCX, up + 1.9, TCZ), 4.4)
	elseif f >= 5 then
		-- 5 a lean-to on posts over the table: straw, then tiles; 8 a striped awning; 19 a glass canopy with lamps
		local xp = TX + 0.5 -- the posts' line
		local y0 = math.min(wallH - 1.6, 8) -- the cover's height at the wall (under the main eave),
		local y1 = y0 - 1.5 -- and at its outer edge
		local mid, deep = (TZ0 + TZ1) / 2, TZ1 - TZ0
		local iron = if era == 5 then L.gold else L.beam
		for _, z in { TZ0 + 0.3, mid, TZ1 - 0.3 } do
			b.box("TerracePost", 0.6, y1 - tY, 0.6, b.at(xp, (tY + y1) / 2, z), if era == 5 then L.wall else L.beam)
		end
		b.box("TerraceBeam", 0.6, 0.5, deep, b.at(xp, y1 + 0.2, mid), iron)
		b.trim("TerraceLedger", 0.4, 0.5, deep, b.at(-HW - 0.2, y0 - 0.3, mid), iron)
		local a, c = Vector3.new(-HW, y0, mid), Vector3.new(TX - 0.5, y1 + 0.25, mid)
		if f >= 19 then
			local rise2 = Vector3.new(0, 0.2, 0)
			local knee = Vector3.new(-20.2, y0 - 0.25, mid)
			local canopy = if L.goo then L.wall else L.glass
			b.beam("CanopyGlass", deep + 0.4, 0.15, a + rise2, knee, canopy, M.Glass)
			b.beam("CanopyGlass", deep + 0.4, 0.15, knee, c, canopy, M.Glass)
			for _, z in { TZ0 + 0.1, mid, TZ1 - 0.1 } do
				local dz = Vector3.new(0, 0, z - mid)
				b.beam("CanopyRafter", 0.3, 0.35, a + rise2 + dz, knee + dz, iron)
				b.beam("CanopyRafter", 0.3, 0.35, knee + dz, c + dz, iron)
			end
			local side = Vector3.new(0, 0, deep / 2)
			b.rod("CanopyPurlin", 0.16, knee - side, knee + side, iron)
			for _, z in { TZ0 + 1.6, mid, TZ1 - 1.6 } do
				b.trim("LampChain", 0.08, 0.4, 0.08, b.at(xp + 1.6, y1 + 0.1, z), IRON)
				b.trim("LampCap", 0.75, 0.15, 0.75, b.at(xp + 1.6, y1 - 0.15, z), IRON)
				b.trim("HangingLamp", 0.55, 0.75, 0.55, b.at(xp + 1.6, y1 - 0.55, z), L.glass, M.Neon)
			end
		elseif f >= 8 then
			local n = 8
			local sw = (deep + 0.6) / n
			for i = 1, n do
				local dz = Vector3.new(0, 0, TZ0 - 0.3 + (i - 0.5) * sw - mid)
				local colour = if i % 2 == 1 then AWN_RED else WHITE
				-- (smooth, not Fabric: Fabric's dark weave greys the white stripes)
				-- (thick cloth with a deep valance, on struts from the wall: a sheet 0.16 thick read as paper)
				b.beam("Awning", sw, 0.3, a + dz, c + dz, colour, M.SmoothPlastic)
				b.trim("AwningEdge", 0.25, 0.7, sw, b.at(c.X, c.Y - 0.35, mid + dz.Z), colour, M.SmoothPlastic)
			end
			for _, z in { TZ0 + 0.3, TZ1 - 0.3 } do
				local under = Vector3.new((a.X + c.X) / 2, (a.Y + c.Y) / 2 - 0.25, z)
				b.beam("AwningStrut", 0.25, 0.25, Vector3.new(-HW - 0.1, y0 - 2.6, z), under, iron)
			end
		else
			local thick = if era == 1 then 0.9 else math.max(0.4, L.thick * 0.7)
			b.beam("LeanRoof", deep + 0.8, thick, a, c, L.roof).CastShadow = true
			if era == 1 then
				-- (straw is thick, not a sheet: a fat roll along the eave, one down each edge, a timber fascia under it)
				local side = Vector3.new(0, -0.1, deep / 2 + 0.4)
				b.rod("EaveRoll", 0.65, c - Vector3.new(0, 0.2, 0) - side, c + side, L.roof)
				for _, e in { -1, 1 } do
					local dz = Vector3.new(0, 0.1, e * (deep / 2 + 0.4))
					b.rod("EdgeRoll", 0.45, a + dz, c + dz, L.roof)
				end
				b.trim("Fascia", 0.35, 0.45, deep + 0.6, b.at(c.X + 0.25, c.Y - 0.6, mid), L.beam)
			end
		end
	end
	if f >= 7 then
		-- 7 a small gabled wing at the right back, its gable and its lit window to the front
		local wh, wr = 7, 4.2
		local wx = (WING_X - HW) / 2
		local wide = -HW - WING_X
		local wallColour = if era == 3 or era == 4 then L.lower else L.wall
		slab("WingWall", WING_X, -HW, 0, wh, WING_Z, WING_Z + T, wallColour)
		slab("WingWall", WING_X, WING_X + T, 0, wh, WING_Z + T, Z1, wallColour)
		slab("WingWall", WING_X + T, -HW, 0, wh, Z1 - T, Z1, wallColour)
		b.gable(b.at(wx, wh, (WING_Z + Z1) / 2) * turn, Z1 - WING_Z, wide, wr, 0.6, L.roof, wallColour, L.board)
		if era == 2 then
			b.timber(b.face(wx, wh / 2, WING_Z, FRONT), wide, wh, L.beam)
		elseif era == 3 then
			b.trim("WingBeam", wide + 0.4, 0.5, 0.4, b.at(wx, wh, WING_Z - 0.1), L.beam)
		elseif era == 5 then
			b.trim("WingLine", wide + 0.4, 0.25, 0.4, b.at(wx, wh, WING_Z - 0.1), L.gold)
		end
		b.window(
			b.face(wx, 3.9, WING_Z, FRONT),
			2.2,
			2.4,
			L.frame,
			L.glass,
			{ shutters = L.shutters, arch = era >= 3, glow = true }
		)
		local rose = b.face(wx, wh + 1.5, WING_Z, FRONT) * CFrame.new(0, 0, -0.15)
		b.disc("WingRose", 0.8, 0.3, rose, L.frame)
		b.disc("WingRoseGlass", 0.6, 0.34, rose, L.glass, M.Neon)
	end

	-- INSIDE ---------------------------------------------------------------------------------------------------
	if era >= 2 then
		-- two lanterns hanging from the roof over the cooking line
		for _, s in { -1, 1 } do
			local x, z = s * 7.8, 4.4
			b.rod("LanternChain", 0.06, Vector3.new(x, 8.2, z), Vector3.new(x, roofY(x) - L.thick - 0.2, z), IRON)
			lantern(b.at(x, 8.2, z), true)
		end
	end
	local cx, cz = -4.6, 1.5
	-- (the owner's Meshy cauldron when it is there: on its timber frame, over its own fire)
	local cauldron = era <= 3 and painted("CauldronFrame_Fire", b.at(cx, FLOOR, cz), 0.8) ~= nil
	if era <= 3 and not cauldron then
		-- a cauldron on a tripod over its own embers
		local x, z = cx, cz
		local apex = Vector3.new(x, 5.2, z)
		for k = 0, 2 do
			local a = math.rad(90 + k * 120)
			b.rod("Tripod", 0.12, Vector3.new(x + 1.7 * math.cos(a), FLOOR, z + 1.7 * math.sin(a)), apex, IRON)
		end
		b.rod("CauldronChain", 0.06, apex, Vector3.new(x, 3.4, z), IRON)
		b.ball("Cauldron", 1.1, b.at(x, 2.4, z), SOOT)
		b.cyl("CauldronRim", 0.95, 0.25, b.at(x, 3.3, z), SOOT, nil, false)
		b.cyl("CauldronSoup", 0.8, 0.1, b.at(x, 3.42, z), C(236, 168, 84), nil, false)
		b.cyl("Embers", 0.9, 0.2, b.at(x, FLOOR + 0.1, z), EMBER, M.Neon, false)
		for k = 0, 2 do
			local a = math.rad(k * 60)
			local d = Vector3.new(math.cos(a), 0, math.sin(a)) * 1.1
			b.rod("Log", 0.2, Vector3.new(x, FLOOR + 0.25, z) - d, Vector3.new(x, FLOOR + 0.25, z) + d, L.board)
		end
	elseif era > 3 then
		-- three copper vent hoods over the cooking line on one duct to the chimney's wall
		local z, y = 2.2, 7.4
		for _, x in { -5.2, 0, 5.2 } do
			if not piece("VentHood_Copper", b.at(x, y, z), 2, 2, 2, L.accent) then
				b.cone(b.at(x, y, z), 2, 1.5, 3, L.accent, nil)
			end
			b.cyl("HoodStem", 0.45, 2, b.at(x, y + 2.5, z), L.accent, nil, false)
		end
		b.rod("HoodDuct", 0.45, Vector3.new(-5.2, y + 3.5, z), Vector3.new(HW - 0.3, y + 3.5, z), L.accent)
		-- a pot rack on chains from the roof, over the back of the right side (the owner's Meshy piece)
		local rx, rz, ry = -9.1, 8.2, 8.4
		for _, s in { -1.9, 1.9 } do
			local hook = Vector3.new(rx + s, roofY(rx + s) - L.thick - 0.1, rz)
			b.rod("RackChain", 0.07, Vector3.new(rx + s, ry - 0.2, rz), hook, IRON)
		end
		if not painted("PotRack_Iron", b.at(rx, ry, rz), 1) then
			b.trim("PotRack", 4.6, 0.3, 0.3, b.at(rx, ry - 0.15, rz), IRON)
			for k, dx in { -1.6, 0, 1.6 } do
				b.trim("PotHook", 0.1, 0.7, 0.1, b.at(rx + dx, ry - 0.65, rz), IRON)
				b.cyl("HangingPot", 0.45, 0.5 + k * 0.15, b.at(rx + dx, ry - 1.3, rz), C(196, 112, 64), M.Metal, false)
			end
		end
	end
	-- herbs drying: under the front beam, then on the right pier's inside
	if era >= 2 then
		local hx, hz, hy = -7.7, Z0 + 0.45, wallH - 0.9
		if era >= 3 then
			hx, hz, hy = -(BAY + HW) / 2, Z0 + T + 0.3, 6.6
			b.trim("HerbRail", 2.6, 0.14, 0.14, b.at(hx, hy, hz), IRON)
		end
		for k = -1, 1 do
			local bundle = if k == 0 then C(240, 236, 220) else C(110, 170, 80)
			b.trim("HerbString", 0.08, 0.7, 0.08, b.at(hx + k * 0.9, hy - 0.35, hz), C(226, 196, 140))
			b.trim("HerbBundle", 0.5, 0.9, 0.5, b.at(hx + k * 0.9, hy - 1.1, hz), bundle)
		end
	end

	-- ON THE ROOF ----------------------------------------------------------------------------------------------
	if f >= 9 then
		-- 9 a dormer on each slope (towards the front, clear of the capital's dome)
		local uF = half * (if vault then 0.85 else 0.6)
		local h, w, z = 2.6, 3.4, -2.6
		local y0 = roofY(uF)
		local run = uF - roofU(y0 + h) + 0.2
		for _, s in { -1, 1 } do
			local out = Vector3.new(s, 0, 0)
			b.box("Dormer", run, h, w, b.at(s * (uF - run / 2), y0 + h / 2, z), L.wall)
			b.gable(b.at(s * (uF - run / 2), y0 + h, z), run, w, 1.5, 0.3, L.roof, L.wall, L.board)
			b.window(b.face(s * uF, y0 + h * 0.52, z, out), 1.8, 1.6, L.frame, L.glass, { glow = true })
		end
	end
	if f >= 17 then
		-- 17 copper pipes from the chimney over the roof
		if vault then
			local over: { Vector3 } = { Vector3.new(CX - 1.7, wallH + (rise + 0.45) * math.sin(math.rad(30)), CZ) }
			for k = 2, 8 do
				local t = math.rad(k * 15)
				table.insert(over, Vector3.new((HW + 0.45) * math.cos(t), wallH + (rise + 0.45) * math.sin(t), CZ))
			end
			pipe(over, 0.3, L.accent)
			local y = wallH + rise + 0.3
			pipe({
				Vector3.new(1.6, y, CZ),
				Vector3.new(1.6, y, Z0 - 0.5),
				Vector3.new(1.6, wallH + L.emblemY + 3.1, Z0 - 0.5),
			}, 0.3, L.accent)
		else
			for _, z in { CZ, CZ - 1.4 } do
				pipe({
					Vector3.new(CX - 1.8, wallH + 1.8, z),
					Vector3.new(AISLE + 0.3, wallH + 1.8, z),
					Vector3.new(4.6, roofY(4.6) + 0.4, z),
				}, 0.3, L.accent)
			end
		end
	end
	if f >= 21 then
		-- 21 a balustrade with gold urns along the roof's edge: over the side bays at the front, down both sides
		for _, s in { -1, 1 } do
			balustrade(s * (AISLE + 0.5), Z0 - 1.3, s * (HW + 0.2), Z0 - 1.3, wallH, L.wall, true)
			balustrade(s * (HW + 0.2), Z0 - 1.3, s * (HW + 0.2), Z1, wallH, L.wall, true)
		end
	end
	local flagAt = if era <= 3
		then Vector3.new(0, ridge + 0.3, Z0 - L.over + 0.7)
		elseif vault then Vector3.new(0, ridge + 0.2, Z0 + 0.3)
		else Vector3.new(0, ridge + 0.3, Z0 - 0.1)
	if f >= 25 then
		-- 25 the great blue dome with gold ribs and a gold lantern, on a drum of lit windows over the hall
		local zd, r = ZC + 0.6, 5.2
		local y0, y1 = roofY(r + 0.4) - 0.6, ridge + 2.2
		b.cyl("DomeDrum", r + 0.4, y1 - y0, b.at(0, (y0 + y1) / 2, zd), L.wall)
		b.cyl("DrumLine", r + 0.55, 0.3, b.at(0, y1 - 0.15, zd), L.gold, M.Metal, false)
		b.cyl("DrumLine", r + 0.5, 0.2, b.at(0, ridge + 0.2, zd), L.gold, M.Metal, false)
		for k = 0, 7 do
			local spin = b.at(0, y1 - 1.1, zd) * CFrame.Angles(0, math.rad(22.5 + k * 45), 0)
			b.trim("DrumWindow", 1.1, 1.4, 0.2, spin * CFrame.new(0, 0, -(r + 0.34)), L.glass, M.Neon)
		end
		flagAt = Vector3.new(0, y1 + dome(b.at(0, y1, zd), r) - 0.4, zd)
	end
	if f >= 4 then
		-- 4 a gold finial with the blue pennant
		local h = 3.4
		b.rod("FlagPole", 0.14, flagAt, flagAt + Vector3.new(0, h, 0), L.gold)
		-- (the dome carries its own gold lantern: the Meshy finial is the ridge's)
		if f >= 25 or not painted("Finial_GoldStone", b.at(flagAt.X, flagAt.Y - 0.1, flagAt.Z), 0.6) then
			b.ball("Finial", 0.42, b.at(flagAt.X, flagAt.Y + 0.3, flagAt.Z), L.gold, bigGold)
		end
		b.ball("FlagKnob", 0.26, b.at(flagAt.X, flagAt.Y + h + 0.2, flagAt.Z), L.gold, bigGold)
		-- (smooth, not Fabric: Fabric's dark weave turns the pennant navy-black against the sky)
		b.trim("Flag", 2.6, 1.5, 0.1, b.at(flagAt.X + 1.4, flagAt.Y + h - 0.85, flagAt.Z), L.cloth, M.SmoothPlastic)
	end

	-- THE EMBLEM on the gable ----------------------------------------------------------------------------------
	if f >= 14 then
		local face = b.face(0, wallH + L.emblemY, Z0, FRONT)
		if f >= 18 then
			-- 18 a brass gear wheel round it, on a dark plate so it reads against glass (royal blue on the marble gable)
			local dia = 5.6
			local gs = dia / 1.994 -- (the mesh is 1.994 round)
			b.disc("GearPlate", dia / 2 + 0.2, 0.3, face * CFrame.new(0, 0, -0.2), if era == 5 then L.cloth else IRON)
			if not piece("Gear_Wheel", face * CFrame.new(0, 0, -0.45), gs, gs, 0.8, L.gold, M.Metal) then
				b.disc("Gear", dia / 2 - 0.2, 0.35, face * CFrame.new(0, 0, -0.5), L.gold, M.Metal)
				for k = 0, 7 do
					local tooth = face * CFrame.Angles(0, 0, k * math.pi / 4) * CFrame.new(0, dia / 2 - 0.1, -0.5)
					b.trim("GearTooth", 0.9, 0.7, 0.35, tooth, L.gold, M.Metal)
				end
			end
		end
		if f >= 23 then
			-- 23 the hat becomes a golden chef slime between gold laurels (the game's own slime; its hat and the
			-- laurels are the owner's Meshy pieces, with stand-ins until they come)
			local foot = b.at(0, wallH + 0.3, Z0 - 0.7)
			local hat = foot * CFrame.new(0, b.slime(foot, 1.6, L.gold) * 0.8, 0)
			-- (the hat is modelled flat at the back: twice as deep makes it round)
			if not painted("ChefHat_White", hat, 1.15, 2.3) then
				b.cyl("HatBand", 0.75, 0.6, hat * CFrame.new(0, 0.3, 0), L.gold, M.Metal, false)
				for _, p in { { -0.55, 0.85 }, { 0, 1.1 }, { 0.55, 0.85 } } do
					b.ball("HatPuff", 0.55, hat * CFrame.new(p[1], p[2], 0), L.gold, M.Metal)
				end
			end
			-- (the wreath stands before the gear, round the slime's middle)
			if not painted("Laurel_Gold", face * CFrame.new(0, 2.6 - L.emblemY, -0.65), 1.3) then
				for _, s in { -1, 1 } do
					for i = 0, 3 do
						local leaf = face
							* CFrame.new(s * (3.3 + i * 0.35), -2.1 + i * 0.65, -0.4)
							* CFrame.Angles(0, 0, s * math.rad(-25 - i * 8))
						b.trim("Laurel", 0.5, 1, 0.2, leaf, L.gold, M.Metal)
					end
				end
			end
		elseif not painted("ChefEmblem_Plaque", face * CFrame.new(0, 0, if f >= 18 then -0.35 else 0), 1) then
			-- 14 the chef-hat emblem with wheat ears on a round dark-wood plaque: the owner's Meshy piece, and this
			-- stand-in from parts until it comes
			b.disc("EmblemRim", 2.4, 0.3, face * CFrame.new(0, 0, -0.5), L.gold, bigGold)
			b.disc("EmblemPlaque", 2.15, 0.4, face * CFrame.new(0, 0, -0.55), BOX)
			b.trim("HatBand", 1.5, 0.7, 0.4, face * CFrame.new(0, -0.55, -0.95), WHITE)
			for _, p in { { -0.6, 0.25 }, { 0, 0.5 }, { 0.6, 0.25 } } do
				b.ball("HatPuff", 0.62, face * CFrame.new(p[1], p[2], -0.95), WHITE)
			end
			for _, s in { -1, 1 } do
				local ear = face * CFrame.new(s * 1.55, -0.1, -0.85) * CFrame.Angles(0, 0, s * math.rad(-20))
				b.trim("Wheat", 0.3, 1.9, 0.2, ear, L.gold)
			end
		end
	end
end

-- The Kitchen at its drawn size, then grown (Config.Village.HouseScale).
function Kitchen.build(m: Instance, frame: CFrame, level: number)
	local had = m:GetChildren()
	raise(m, frame, level)
	Architecture.grow(m, had, frame, "Kitchen", SPLIT_Z, PIVOT_X, PIVOT_Z)
end

return Kitchen
