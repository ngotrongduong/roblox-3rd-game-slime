--!strict
-- The breeding pen's landmark: the fenced pen, grown into a royal hatchery (village v2, skill landmark-build; the
-- owner approved the reference on 2026-11-17: docs/areas/village-v2/breeding-ref-sheet.jpg, the ladder is
-- breeding-ladder.md beside it). One place in five architectures, one an era of ten levels:
--   1 hamlet       woven wattle, brown timber and cream plaster under thatch, a fieldstone chimney
--   2 painted      cream pickets on rose-pink posts, cream plaster on rose-pink beams, red clay tiles, a brick stove room
--   3 town         a low stone wall with timber rails, a stone hall with one great arch, a round turret under a cone roof
--   4 slime tech   black steel and blue slate vaults, copper pipes, a glowing green goo boiler with a steel stack
--   5 capital      white marble and gold, columns and a pediment, blue glass domes on the wings, a marble tower
-- The same five things at every era, in the same places, so it stays one place: THE FENCE round the pen with THE GATE
-- in the middle of its front (-z); THE HALL across the back (front wall at HZ), hollow, its front wide open on the
-- straw beds and the egg shelves; THE EGG on the hall's roof, from level 10 on the tallest thing; THE HEART with a
-- white egg over the hall's open front; THE WARM ROOM with its chimney on the left as one walks in (+x). The nests,
-- the incubators, the care props and the lane are the area's own and stay BreedingStages' business.
-- `build` takes the AREA's frame (the pen is x -17..25 there) and works round the lane's middle line, OX across:
-- everything below is in that shifted frame. The lawn's top is y 0, the pen floor's top FLOOR.
-- An era's first level changes the architecture; levels 6-10 of each era add one feature each, and a feature once
-- added stays in every later era in that era's materials (25 in all, numbered in `build` as in the ladder).
local Architecture = require(script.Parent.Architecture)
local LibraryKit = require(script.Parent.LibraryKit)

local BreedingHouse = {}

local C = Color3.fromRGB
local M = Enum.Material
local V = Vector3.new
local IRON = C(60, 60, 66)
local DARK = C(42, 34, 30)
local PLANK = C(176, 128, 78)
local BOX = C(128, 84, 50)
local LEAF = C(86, 160, 70)
local IVY = C(124, 190, 92)
local STRAW = C(204, 156, 62) -- the darker course half way up a thatch
local HAY = C(236, 204, 104)
local GOO = C(96, 232, 70)
local EGG = C(250, 240, 214) -- the great egg's cream shell
local SPOT = C(176, 146, 228) -- its lavender spots, and the town's banners
local SPOT_LIT = C(126, 104, 250) -- (blue-violet: a redder one glowed hot magenta in the game's light)
local PINK = C(255, 122, 164) -- the heart
local ROSE = C(214, 72, 120) -- its rim
local WHITE = C(252, 250, 244)
local FIRE = C(255, 150, 60)
local EGGS = { C(250, 240, 214), C(176, 214, 240), C(255, 198, 214), C(192, 236, 200) }
local BLOOMS = { C(255, 120, 150), C(255, 214, 80), C(240, 90, 80) }
-- the hall's floor an era: colours with no material of their own, so they keep the stud look (the owner's choice)
local FLOORS = { C(178, 130, 80), C(178, 130, 80), C(170, 164, 154), C(92, 98, 110), C(232, 228, 220) }
local FRONT, BACK = V(0, 0, -1), V(0, 0, 1)

-- THE SHELL AN ERA'S BLENDER BODY STANDS FOR (see `raise`, the hall and its side rooms): these parts become ghosts
-- under it. The floor, the glass, the fans, the columns, the windows, the lamps and every feature keep their parts.
local SHELL: { [string]: boolean } = {}
for name in
	string.gmatch(
		"SideWall PostPad Post Rail Brace BackWall TieBeam Roof Gable BargeBoard Ridge EaveRoll ThatchCourse RidgeRoll "
			.. "Rafter KingPost Collar GableRail GableStrut LeanWall LeanRoof LeanPost Chimney ChimneyCap RoomWall "
			.. "RoomPlinth BayPost BayRail FrontWall Quoin Plinth ArchStone Keystone StringCourse Jetty JettyBracket "
			.. "UpperWall Turret TurretPlinth TurretCornice SidePost SideRail SideCap FrontPier FrontPierCap "
			.. "FrontPierFoot VaultGlass VaultRib Purlin FrontArch Transom LunetteBar WingWall WingVault WingSill "
			.. "WingPost WingRib WingTransom BoilerFoot BoilerFootCap Stack StackBand StackTop SideCornice SidePlinth "
			.. "Entablature Frieze Cornice Wing WingPlinth WingCornice Tower TowerPlinth TowerBand",
		"%a+"
	)
do
	SHELL[name] = true
end

local OX = 4 -- the lane's middle line in the area's frame
local FLOOR = 0.4 -- the pen floor's top
local HX, FZ0, FZ1 = 21, -19, 30 -- the fence: x -HX..HX, z FZ0..FZ1
local PX = 4 -- the gate's posts stand at x -PX and PX
local HZ = 20 -- the hall's front wall
local INC_PAD_Z = 14.2 -- just onto the back edge of the incubators' pad (BreedingStages: the pad ends at z 14.5)
local T = 0.6 -- a wall's thickness
local EGG_R = { 2.1, 2.9, 3.4, 3.9, 4.4 } -- half the egg's width at its five forms
-- (the egg's mesh is worn wider and lower than it was modelled: the sheet's eggs are broad domes, and the final
-- review read the modelled one as a tall ornament)
local EGG_WIDE = 1.1
local EGG_TALL = 0.85

type Look = {
	hw: number, -- half the hall's width
	depth: number,
	wallH: number, -- the walls' height over the floor (where the vault springs at era 4)
	rise: number, -- the roof's height over the walls
	wall: Color3,
	lower: Color3,
	stone: Color3,
	beam: Color3,
	board: Color3,
	roof: Color3,
	frame: Color3,
	glass: Color3,
	shutters: Color3,
	cloth: Color3,
	gold: Color3,
	accent: Color3,
	fence: Color3,
	mats: { [string]: Enum.Material },
}

local LOOKS: { Look } = {
	{ -- 1 hamlet
		hw = 7.2,
		depth = 11, -- (the owner, 2026-11-17: the houses lacked depth; as deep as the pier is long once grown)
		wallH = 6.6,
		rise = 5,
		wall = C(236, 220, 180),
		lower = C(170, 120, 72),
		stone = C(150, 146, 138),
		beam = C(110, 72, 42),
		board = C(92, 60, 36),
		roof = C(232, 190, 84),
		frame = C(126, 84, 50),
		glass = C(250, 204, 110),
		shutters = C(150, 110, 150),
		cloth = C(176, 146, 228),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		fence = C(190, 146, 88),
		mats = {
			wall = M.Plaster,
			lower = M.WoodPlanks,
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.Sand,
			frame = M.Wood,
			shutters = M.WoodPlanks,
			gold = M.Foil,
			accent = M.Metal,
			fence = M.Wood,
		},
	},
	{ -- 2 painted
		hw = 8.2,
		depth = 11,
		wallH = 7.2,
		rise = 5.4,
		wall = C(244, 238, 224),
		lower = C(190, 92, 66),
		stone = C(232, 222, 200),
		beam = C(246, 160, 158), -- (a light warm rose: under Wood in daylight a cooler pink turns purple)
		board = C(224, 122, 126),
		roof = C(198, 70, 58),
		frame = C(250, 246, 236),
		glass = C(250, 198, 100), -- (deep: lit Neon panes wash out to white in daylight)
		shutters = C(214, 104, 136),
		cloth = C(176, 146, 228),
		gold = C(236, 190, 70),
		accent = C(110, 72, 42),
		fence = C(250, 246, 236),
		mats = {
			wall = M.Plaster,
			lower = M.Brick,
			stone = M.Limestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.ClayRoofTiles,
			frame = M.WoodPlanks,
			shutters = M.WoodPlanks,
			gold = M.Foil,
			accent = M.Wood,
		},
	},
	{ -- 3 town
		hw = 8.6,
		depth = 11,
		wallH = 8,
		rise = 4.8,
		wall = C(240, 230, 206),
		lower = C(198, 190, 174),
		stone = C(128, 124, 118),
		beam = C(112, 72, 44),
		board = C(92, 60, 38),
		roof = C(190, 62, 50), -- (the owner, 2026-11-17: one roof an era for every landmark, the Granary's)
		frame = C(222, 216, 202),
		glass = C(250, 198, 100),
		shutters = C(150, 110, 150),
		cloth = C(176, 146, 228),
		gold = C(236, 190, 70),
		accent = C(112, 72, 44),
		fence = C(112, 72, 44),
		mats = {
			wall = M.Plaster,
			lower = M.Cobblestone,
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.ClayRoofTiles,
			frame = M.Limestone,
			shutters = M.WoodPlanks,
			gold = M.Foil,
		},
	},
	{ -- 4 slime tech
		hw = 8,
		depth = 11,
		wallH = 10,
		rise = 6.6,
		wall = C(150, 225, 215),
		lower = C(198, 112, 74),
		stone = C(74, 80, 92),
		beam = C(52, 56, 64),
		board = C(40, 44, 50),
		roof = C(62, 96, 160),
		frame = C(214, 208, 196),
		glass = C(250, 202, 108),
		shutters = C(40, 44, 50),
		cloth = C(176, 146, 228),
		gold = C(224, 170, 70),
		accent = C(226, 132, 78), -- (bright: Metal darkens it, and a duller copper read as brown wood)
		fence = C(40, 44, 50),
		mats = {
			wall = M.Glass,
			lower = M.Brick,
			stone = M.Slate,
			beam = M.Metal,
			board = M.Metal,
			roof = M.RoofShingles,
			frame = M.Limestone,
			gold = M.Metal,
			accent = M.Metal,
		},
	},
	{ -- 5 capital
		hw = 9.6,
		depth = 11,
		wallH = 10.5,
		rise = 3.6,
		wall = C(242, 239, 232), -- (not whiter: the facade's mouldings washed out in daylight)
		lower = C(214, 208, 196),
		stone = C(214, 208, 196),
		beam = C(228, 222, 210),
		board = C(236, 192, 76),
		roof = C(44, 84, 170),
		frame = C(236, 192, 76),
		glass = C(250, 204, 112),
		shutters = C(236, 192, 76),
		cloth = C(40, 70, 160),
		gold = C(236, 192, 76),
		accent = C(236, 192, 76), -- (beside marble every metal is gold: copper there reads rustic)
		fence = C(250, 249, 245),
		mats = {
			wall = M.Marble,
			stone = M.Marble,
			beam = M.Marble,
			roof = M.ClayRoofTiles,
			gold = M.Foil,
		},
	},
}

-- A level's era (1-5) and how many of the 25 features it has.
function BreedingHouse.features(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	return era, (era - 1) * 5 + math.max(0, s - 5)
end

-- The ground the place stands on, in the area's frame (x0, x1, z0, z1): scenery there goes.
-- (What Architecture.grow takes as the house: what stands at or behind SPLIT_Z; and the point it grows round.
-- The split lies in front of everything the hall carries on its face - the marble portico's columns at HZ - 1.2, its
-- pediment's ornaments at HZ - 2.4, the jettied storey's windows and flower boxes at HZ - 1.1 - and behind the urns
-- and statues beside the door, HZ - 2.9: at 19 those face pieces kept their drawn size under a grown hall.)
local SPLIT_Z, PIVOT_X, PIVOT_Z = 17.4, 4, 20
function BreedingHouse.footprint(_level: number): (number, number, number, number)
	return Architecture.grownBox(
		"BreedingHouse",
		SPLIT_Z,
		PIVOT_X,
		PIVOT_Z,
		OX - HX - 1.5,
		OX + HX + 1.5,
		FZ0 - 3,
		FZ1 + 1.5
	)
end

-- The fence stands round the GROWN house at its own size (the owner, 2026-11-17: the play yard out to both sides,
-- the incubators inside it): half its width and its back, where Architecture.grow puts the drawn fence's corner.
local WX, ZB = Architecture.grown("BreedingHouse", 0, PIVOT_Z, HX, FZ1)

-- The fence in the area's frame (x0, x1, z0, z1): BreedingStages lays the floor to it.
function BreedingHouse.fence(): (number, number, number, number)
	return OX - WX, OX + WX, FZ0, ZB
end

-- (`had`: what Architecture.grow leaves alone; the fence and its corners join it)
local function raise(m: Instance, area: CFrame, level: number, had: { Instance })
	local era, f = BreedingHouse.features(level)
	local L = LOOKS[era]
	local frame = area * CFrame.new(OX, 0, 0)
	local skins: { [string]: Enum.Material } = {
		[IRON:ToHex()] = M.Metal,
		[DARK:ToHex()] = M.Metal,
		[PLANK:ToHex()] = M.WoodPlanks,
		[BOX:ToHex()] = M.Wood,
		[LEAF:ToHex()] = M.LeafyGrass,
		[STRAW:ToHex()] = M.Sand,
		[HAY:ToHex()] = M.Sand,
	}
	for field, material in L.mats do
		skins[((L :: any)[field] :: Color3):ToHex()] = material
	end
	local b = Architecture.new(m, frame, skins, 0.4)
	local hw, depth, wallH, rise = L.hw, L.depth, L.wallH, L.rise
	local top = FLOOR + wallH -- the hall walls' top
	local zb = HZ + depth -- the hall's back
	local zc = HZ + depth / 2
	local turn = CFrame.Angles(0, math.pi / 2, 0) -- (a roof whose ridge runs front to back)
	local bigGold = if era >= 4 then M.Metal else nil

	-- a wall or a floor from corner to corner
	local function slab(
		name: string,
		xa: number,
		xb: number,
		y0: number,
		y1: number,
		za: number,
		zb2: number,
		colour: Color3,
		material: Enum.Material?
	)
		local x0, x1 = math.min(xa, xb), math.max(xa, xb)
		if x1 - x0 > 0.05 and y1 - y0 > 0.05 and zb2 - za > 0.05 then
			b.box(
				name,
				x1 - x0,
				y1 - y0,
				zb2 - za,
				b.at((x0 + x1) / 2, (y0 + y1) / 2, (za + zb2) / 2),
				colour,
				material
			)
		end
	end
	local function light(p: Instance, colour: Color3, range: number, brightness: number)
		local glow = Instance.new("PointLight")
		glow.Color = colour
		glow.Range = range
		glow.Brightness = brightness
		glow.Parent = p
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
		return if src then b.mesh(src, cf, V(sx, sy, sz), colour, material) else nil
	end
	-- THE OWNER'S MESHY PIECES wear their own picture: unpainted, at `s` times their size in Config.LibraryKit
	local function painted(name: string, cf: CFrame, s: number, deep: number?): BasePart?
		return piece(name, cf, s, s, deep or s, Color3.new(1, 1, 1), M.SmoothPlastic)
	end
	-- THE ERA'S BLENDER BODY (tools/blender/landmark_bodies.py): the hall and its side rooms as one model, a mesh a
	-- colour field, in the hall's own coordinates. Under it the shell's parts are ghosts (`shell`): its solid ones
	-- stay as what a player walks against, the rest is not made. Without the meshes the parts stand as before.
	local bodyName = "BreedingBody" .. era
	local bodied = LibraryKit.find(bodyName .. "_Roof") ~= nil
	local function shell(on: boolean)
		b.ghost(if on and bodied then SHELL else nil)
	end
	local slots: { { any } } = {
		{ "Stone", L.stone },
		{ "Wall", L.wall },
		{ "Lower", L.lower },
		{ "Beam", L.beam },
		{ "Gold", L.gold, bigGold },
		{ "Board", L.board },
		{ "Roof", L.roof },
		{ "Frame", L.frame },
		{ "Glass", L.glass, M.Neon },
		{ "Shutters", L.shutters },
	}
	local function worn(model: string)
		for _, slot in slots do
			piece(model .. "_" .. slot[1], b.at(0, 0, 0), 1, 1, 1, slot[2], slot[3])
		end
	end
	-- a tiled cone roof `r` round at the eave and `up` high, the middle of its foot at `cf`; `tip` its finial
	local function coneRoof(cf: CFrame, r: number, up: number, colour: Color3, tip: boolean)
		if piece("ConeRoof_Tiles", cf, r, up / 1.3, r, colour) then
			if tip then
				local s = r * 1.3
				piece("ConeRoof_Finial", cf * CFrame.new(0, up - 0.04 * s, 0), s, s, s, L.gold)
			end
		else
			b.cone(cf, r, up, if tip then 5 else 3, colour, if tip then L.gold else nil)
		end
	end
	-- the capital's dome in the era's roof tiles (the owner, 2026-11-17: a dome wears its era's roof), `r` round, on its drum's top at `cf`: golden ribs, a lantern and a finial
	local function dome(cf: CFrame, r: number)
		if piece("RoyalDome_Gold", cf, r, r, r, L.gold, M.Metal) then
			piece("RoyalDome_Shell", cf, r, r, r, L.roof)
		else
			b.ball("Dome", r, cf, L.roof)
			b.cyl("DomeLantern", r * 0.2, r * 0.5, cf * CFrame.new(0, r * 1.2, 0), L.gold, M.Metal, false)
			b.ball("Finial", r * 0.14, cf * CFrame.new(0, r * 1.55, 0), L.gold, M.Metal)
		end
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
	-- a balustrade from (xa, za) to (xb, zb2), its foot at `y`: a post about every four studs (`first` and `last`
	-- say whether its two ends get one), an urn on each when asked
	local function balustrade(
		xa: number,
		za: number,
		xb: number,
		zb2: number,
		y: number,
		colour: Color3,
		urns: boolean,
		first: boolean,
		last: boolean
	)
		local run = V(xb - xa, 0, zb2 - za)
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
			local post = (i > 0 or first) and (i < bays or last)
			if kit then
				if post then
					piece("Balustrade_Post", cf, 1, 1, 1, colour)
					if urns then
						piece("Balustrade_Urn", cf * CFrame.new(0, 1.3, 0), 1.8, 1.8, 1.8, L.gold)
					end
				end
				if i < bays then
					piece("Balustrade_Run", cf * CFrame.new(step / 2, 0, 0), (step - 0.5) / 4, 1, 1, colour)
				end
			else
				if post then
					b.trim("RailPost", 0.6, 1.3, 0.6, cf * CFrame.new(0, 0.65, 0), colour)
					if urns then
						b.ball("Urn", 0.42, cf * CFrame.new(0, 1.7, 0), L.gold)
					end
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
	-- a wall lantern, its plate on the wall at `face`: the owner's Meshy one, a part one until it comes
	local function lamp(face: CFrame, s: number, lit: boolean)
		local kit = painted("WallLantern_Iron", face, s)
		if not kit then
			b.lantern(face, L.glass, IRON, lit)
		elseif lit then
			light(kit, L.glass, 14, 0.6)
		end
	end
	-- a pipe through `points` (in the frame), a fitting at every bend and at its end
	local function pipe(points: { Vector3 }, r: number, colour: Color3)
		for i = 1, #points - 1 do
			b.rod("Pipe", r, points[i], points[i + 1], colour, bigGold)
			local p = points[i + 1]
			b.ball("PipeJoint", r * 1.5, b.at(p.X, p.Y, p.Z), L.gold, bigGold)
		end
	end
	-- a glowing globe lamp standing on (x, y, z)
	local function globe(x: number, y: number, z: number, lit: boolean)
		b.cyl("GlobeStem", 0.14, 0.6, b.at(x, y + 0.3, z), IRON, nil, false)
		b.cyl("GlobeCollar", 0.34, 0.2, b.at(x, y + 0.6, z), L.gold, bigGold, false)
		local g = b.ball("Globe", 0.75, b.at(x, y + 1.3, z), L.glass, M.Neon)
		if lit then
			light(g, L.glass, 16, 0.7)
		end
	end
	-- a glowing goo tube `h` high standing on (x, y, z), in brass collars
	local function gooTube(x: number, y: number, z: number, h: number)
		b.cyl("GooTube", 0.26, h, b.at(x, y + h / 2, z), GOO, M.Neon, false)
		for _, k in { 0.1, h - 0.1 } do
			b.cyl("GooTubeCollar", 0.36, 0.2, b.at(x, y + k, z), L.gold, bigGold, false)
		end
	end
	-- a banner hanging from `face`: lavender with a gold egg, the capital's blue one from the owner's sheets
	local function banner(face: CFrame, w: number, h: number)
		local all = h + w * 0.7
		if era == 5 and painted("Banner_SlimeBlue", face * CFrame.new(0, -all / 2, 0), all / 5) then
			return
		end
		local cloth = if era == 5 then L.cloth else SPOT
		b.trim("BannerRod", w + 0.5, 0.22, 0.22, face * CFrame.new(0, 0, -0.25), L.gold)
		-- (smooth, not Fabric: Fabric's dark weave turns cloth slate grey)
		b.trim("Banner", w, h, 0.1, face * CFrame.new(0, -h / 2, -0.35), cloth, M.SmoothPlastic)
		local side = w / math.sqrt(2)
		local point = face * CFrame.new(0, -h, -0.35) * CFrame.Angles(0, 0, math.pi / 4)
		b.trim("BannerPoint", side, side, 0.1, point, cloth, M.SmoothPlastic)
		b.trim("BannerBand", w, 0.2, 0.12, face * CFrame.new(0, -0.35, -0.37), L.gold)
		b.disc("BannerEgg", w * 0.27, 0.1, face * CFrame.new(0, -h * 0.62, -0.4), L.gold)
		b.disc("BannerEgg", w * 0.2, 0.1, face * CFrame.new(0, -h * 0.62 + w * 0.2, -0.4), L.gold)
	end
	-- THE HEART: a puffy pink heart in a raised rim with a white egg on it, `s` times two studs wide, held at its
	-- middle at `cf` (it has two faces: the gate's is seen from the yard too)
	local function emblem(cf: CFrame, s: number, rim: Color3, rimMat: Enum.Material?)
		-- (worn a little wider than modelled: from the yard's side view its two lobes closed into a teardrop)
		local w = s * 1.12
		if piece("HeartEmblem_Heart", cf, w, s, s, PINK, M.SmoothPlastic) then
			piece("HeartEmblem_Rim", cf, w, s, s, rim, rimMat or M.SmoothPlastic)
			piece("HeartEmblem_Egg", cf, s, s, s, WHITE, M.SmoothPlastic)
			return
		end
		for _, k in { -1, 1 } do
			b.ball("Heart", 0.55 * s, cf * CFrame.new(k * 0.42 * s, 0.3 * s, 0), PINK, M.SmoothPlastic)
		end
		local point = cf * CFrame.new(0, -0.12 * s, 0) * CFrame.Angles(0, 0, math.pi / 4)
		b.trim("Heart", s, s, 0.5 * s, point, PINK, M.SmoothPlastic)
		b.ball("HeartEgg", 0.34 * s, cf * CFrame.new(0, 0.08 * s, 0), WHITE, M.SmoothPlastic)
	end
	-- 7 an oven mouth with a glowing fire in a wall at `face` (the middle of its foot), under its own little roof
	-- when `hood` is given
	local function fireMouth(face: CFrame, surround: Color3, hood: Color3?)
		b.trim("OvenSurround", 2.8, 2.6, 0.5, face * CFrame.new(0, 1.3, -0.2), surround)
		b.trim("OvenMouth", 1.7, 1.2, 0.5, face * CFrame.new(0, 0.9, -0.28), DARK)
		b.disc("OvenMouth", 0.85, 0.5, face * CFrame.new(0, 1.5, -0.28), DARK)
		local fire = b.trim("OvenFire", 1.3, 0.6, 0.3, face * CFrame.new(0, 0.6, -0.45), FIRE, M.Neon)
		b.ball("OvenFire", 0.4, face * CFrame.new(0, 1.05, -0.4), C(255, 196, 80), M.Neon)
		light(fire, FIRE, 12, 0.8)
		if hood then
			b.wedge("OvenHood", 3.2, 0.9, 1.5, face * CFrame.new(0, 3.05, -0.75), hood)
		end
	end
	-- ARCHES round the line x `cx`: point `k` of eight on a half ring `half` wide and `R` high over `spring`
	local function arc(half: number, spring: number, R: number, k: number): (number, number)
		local a = math.rad(k * 22.5)
		return half * math.cos(a), spring + R * math.sin(a)
	end
	-- the wall over an arched opening, from the arch up to `y1` (the wall beside the opening is the caller's)
	local function archWall(
		name: string,
		cx: number,
		half: number,
		spring: number,
		R: number,
		y1: number,
		z: number,
		thick: number,
		colour: Color3,
		material: Enum.Material?
	)
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				local px, py = arc(half, spring, R, k)
				local qx, qy = arc(half, spring, R, k + 1)
				slab(name, cx + s * qx, cx + s * px, qy, y1, z - thick / 2, z + thick / 2, colour, material)
				-- (a wedge upside down: flat on top, its slope along the arch)
				b.wedge(
					name,
					thick,
					qy - py,
					px - qx,
					frame
						* CFrame.fromMatrix(
							V(cx + s * (px + qx) / 2, (py + qy) / 2, z),
							V(0, 0, s),
							V(0, -1, 0),
							V(s, 0, 0)
						),
					colour,
					material
				)
			end
		end
	end
	-- the filling under an arch, from `spring` up to the arch: a glass fan
	local function fan(
		cx: number,
		half: number,
		spring: number,
		R: number,
		z: number,
		colour: Color3,
		material: Enum.Material?
	)
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				local px, py = arc(half, spring, R, k)
				local qx, qy = arc(half, spring, R, k + 1)
				slab("Fan", cx + s * qx, cx + s * px, spring, py, z - 0.08, z + 0.08, colour, material)
				b.wedge(
					"Fan",
					0.16,
					qy - py,
					px - qx,
					frame
						* CFrame.fromMatrix(
							V(cx + s * (px + qx) / 2, (py + qy) / 2, z),
							V(0, 0, s),
							V(0, 1, 0),
							V(-s, 0, 0)
						),
					colour,
					material
				)
			end
		end
	end
	-- the ring of an arch: eight bars `deep` through the wall and `thick` across, every other one `colour2`
	local function archRing(
		name: string,
		cx: number,
		half: number,
		spring: number,
		R: number,
		z: number,
		deep: number,
		thick: number,
		colour: Color3,
		material: Enum.Material?,
		colour2: Color3?
	)
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				local px, py = arc(half, spring, R, k)
				local qx, qy = arc(half, spring, R, k + 1)
				b.beam(
					name,
					deep,
					thick,
					V(cx + s * px, py, z),
					V(cx + s * qx, qy, z),
					if colour2 and k % 2 == 1 then colour2 else colour,
					material
				)
			end
		end
	end
	-- a roof whose gable faces the front, over x cx - half..cx + half and z za..zb2 from `y`: thatch with its
	-- rolls at the hamlet, the era's roof after; `only` -1 leaves the front end open
	local function frontGable(
		cx: number,
		half: number,
		y: number,
		za: number,
		zb2: number,
		up: number,
		over: number,
		gableColour: Color3,
		only: number?
	)
		local thick = if era == 1 then 0.6 else nil
		b.gable(
			b.at(cx, y, (za + zb2) / 2) * turn,
			zb2 - za,
			half * 2,
			up,
			over,
			L.roof,
			gableColour,
			L.board,
			nil,
			thick,
			only
		)
		if era ~= 1 then
			return
		end
		-- (thatch: a roll along each eave and the ridge, a darker course half way up each slope)
		local k = math.min(1, half / 5)
		local pitch = up / half
		local ey = y - pitch * over - 0.25
		local cy = y + up - pitch * (half + over) / 2
		for _, s in { -1, 1 } do
			local x = cx + s * (half + over)
			b.rod("EaveRoll", 0.5 * k, V(x, ey, za - over), V(x, ey, zb2 + over), L.roof)
			local xm = cx + s * (half + over) / 2
			b.rod("ThatchCourse", 0.34 * k, V(xm, cy, za - over), V(xm, cy, zb2 + over), STRAW)
		end
		b.rod(
			"RidgeRoll",
			0.65 * k,
			V(cx, y + up + 0.1, za - over - 0.1),
			V(cx, y + up + 0.1, zb2 + over + 0.1),
			L.roof
		)
	end
	-- 9 a dormer with a lit window on a side slope (`s` -1 or 1) of the hall's roof: its face at x `xf`, its back
	-- where the slope has climbed over it at `xk`, its foot at `yb`
	local function dormer(s: number, xf: number, xk: number, yb: number, z: number)
		local out = V(s, 0, 0)
		if era <= 3 then
			-- (0.7 of the owner's piece: at half size it read as a red lump on the slope)
			local lit = painted("Dormer_RedRoof", b.face(s * xk, yb + 1.75, z, out), 0.7, (xf - xk) / 5.619)
			if lit then
				light(lit, L.glass, 10, 0.5)
				return
			end
		end
		local mid = s * (xf + xk) / 2
		b.box("Dormer", xf - xk, 1.6, 2.2, b.at(mid, yb + 0.8, z), if era == 4 then L.beam else L.wall)
		b.gable(b.at(mid, yb + 1.6, z), xf - xk + 0.4, 2.4, 0.9, 0.3, L.roof, L.wall, L.board, nil, nil, s)
		b.window(b.face(s * xf, yb + 0.9, z, out), 1.2, 1.2, L.frame, L.glass, { glow = true })
	end

	-- THE FENCE ------------------------------------------------------------------------------------------------
	-- One run from (xa, za) to (xb, zb2); the runs go round the pen so its inside is on a run's own +Z. `first`
	-- and `last` say whether its two ends get a post (a corner has one from the run before, the gate its own).
	local function fence(xa: number, za: number, xb: number, zb2: number, first: boolean, last: boolean, urns: boolean)
		local run = V(xb - xa, 0, zb2 - za)
		local len = run.Magnitude
		local dir = run.Unit
		local along = CFrame.Angles(0, math.atan2(-dir.Z, dir.X), 0)
		local function at(d: number, y: number): CFrame
			return b.at(xa + dir.X * d, FLOOR + y, za + dir.Z * d) * along
		end
		if era == 5 then
			-- a marble balustrade on a plinth, gold urns along the front
			b.box("FencePlinth", len + 0.9, 0.5, 0.9, at(len / 2, 0.25), L.stone)
			balustrade(xa, za, xb, zb2, FLOOR + 0.5, L.wall, urns, first, last)
			return
		end
		local bays = math.max(1, math.round(len / ({ 3, 4.4, 6, 4.4 })[era]))
		local step = len / bays
		for i = 0, bays do
			local d = i * step
			local mid = d + step / 2
			if (i > 0 or first) and (i < bays or last) then
				if era == 1 then
					b.cyl("FencePost", 0.24, 2.9, at(d, 1.45), L.beam)
				elseif era == 2 then
					b.box("FencePost", 0.6, 3.3, 0.6, at(d, 1.65), L.beam)
					b.ball("FenceCap", 0.42, at(d, 3.55), L.gold)
				elseif era == 3 then
					b.box("FencePier", 1.5, 2.7, 1.5, at(d, 1.35), L.lower)
					b.trim("FencePierCap", 1.8, 0.3, 1.8, at(d, 2.85), L.frame)
				else
					b.box("FencePost", 0.55, 3.5, 0.55, at(d, 1.75), L.fence)
					b.ball("FenceCap", 0.42, at(d, 3.75), L.gold, M.Metal)
				end
			end
			if i < bays then
				if era == 1 then
					-- woven wattle: four withy bands, each passing the posts on the other side from the last
					for k = 1, 4 do
						local side = if (i + k) % 2 == 0 then 0.14 else -0.14
						b.box(
							"Wattle",
							step + 0.1,
							0.5,
							0.2,
							at(mid, 0.1 + (k - 0.5) * 0.54) * CFrame.new(0, 0, side),
							if k % 2 == 0 then L.fence else L.lower
						)
					end
				elseif era == 2 then
					-- cream pickets on two rails
					for _, y in { 0.8, 2.2 } do
						b.box("FenceRail", step - 0.6, 0.28, 0.24, at(mid, y), L.fence)
					end
					local n = math.max(2, math.round((step - 0.6) / 1.05))
					for k = 1, n do
						local along2 = d + 0.3 + (step - 0.6) * (k - 0.5) / n
						b.trim("Picket", 0.66, 2.6, 0.16, at(along2, 1.45) * CFrame.new(0, 0, -0.2), L.fence)
					end
				elseif era == 3 then
					-- a low stone wall under two timber rails
					b.box("FenceWall", step - 1.5, 1.5, 1, at(mid, 0.75), L.stone)
					b.trim("FenceWallCap", step - 1.5, 0.25, 1.2, at(mid, 1.62), L.frame)
					for _, y in { 2.1, 2.6 } do
						b.trim("FenceRail", step - 1.5, 0.26, 0.26, at(mid, y), L.fence)
					end
					for _, k in { -1, 1 } do
						b.trim("FenceRailPost", 0.3, 1.1, 0.3, at(mid + k * (step - 1.5) / 6, 2.3), L.fence)
					end
				else
					-- black steel bars between two rails on a slate kerb
					b.box("FenceKerb", step - 0.55, 0.45, 0.5, at(mid, 0.22), L.stone)
					for _, y in { 0.75, 3.05 } do
						b.box("FenceRail", step - 0.55, 0.2, 0.2, at(mid, y), L.fence)
					end
					local n = math.max(2, math.round((step - 0.55) / 0.9))
					for k = 1, n do
						local along2 = d + 0.28 + (step - 0.55) * (k - 0.5) / n
						b.trim("FenceBar", 0.14, 2.9, 0.14, at(along2, 1.95), L.fence)
					end
				end
			end
		end
	end
	local gx = if era >= 3 then PX + 1.2 else PX + 0.45 -- where the fence meets the gate
	-- (no side gate: the incubators stand inside the wide yard)
	local fenceFrom = #m:GetChildren()
	fence(gx, FZ0, WX, FZ0, false, true, true)
	fence(WX, FZ0, WX, ZB, false, true, false)
	fence(WX, ZB, -WX, ZB, false, true, false)
	fence(-WX, ZB, -WX, FZ0, false, true, false)
	fence(-WX, FZ0, -gx, FZ0, false, false, true)
	-- the four corners: a pier at the capital (the balustrade is low), and what the features stand on
	local cornerTop = FLOOR + ({ 2.9, 3.5, 3, 3.95, 3 })[era]
	for _, c in { { -1, FZ0 }, { 1, FZ0 }, { -1, ZB }, { 1, ZB } } do
		local x, z = c[1] * WX, c[2]
		if era == 5 then
			b.box("CornerPier", 1.2, 2.8, 1.2, b.at(x, FLOOR + 1.4, z), L.wall)
			b.trim("CornerPierCap", 1.5, 0.2, 1.5, b.at(x, FLOOR + 2.9, z), L.gold)
		end
		if f >= 13 then
			-- 13 glowing globe lamps on the corner pillars (the two at the front give real light)
			globe(x, cornerTop, z, z == FZ0)
		end
		if f >= 18 and z == FZ0 then
			-- 18 glowing green goo tubes at the front corner posts (and beside the gate's piers, below)
			gooTube(x - c[1] * 0.85, FLOOR, z - 0.85, 3.2)
		end
	end
	Architecture.keep(m, fenceFrom, had)
	if f >= 6 then
		-- 6 flower boxes along the front fence on both sides of the gate (the owner's Meshy trough)
		for _, x in { -15.5, -9.6, 9.6, 15.5 } do
			if not painted("FlowerBox_Trough", b.at(x, 0, FZ0 - 1.4), 0.9) then
				flowerBox(b.face(x, 1.2, FZ0 - 0.5, FRONT), 3.4)
			end
		end
	end
	if f >= 21 then
		-- 21 gold urns of pink flowers at the fence's front corners (and beside the hall's door, below)
		for _, s in { -1, 1 } do
			local cf = b.at(s * (WX + 0.4), 0, FZ0 - 2)
			if not painted("FlowerUrn_Gold", cf, 0.95) then
				b.cyl("FlowerUrn", 0.9, 1.6, cf * CFrame.new(0, 0.8, 0), L.gold, bigGold, false)
				b.ball("Flower", 1, cf * CFrame.new(0, 2.2, 0), BLOOMS[1])
			end
		end
	end

	-- THE GATE -------------------------------------------------------------------------------------------------
	if era <= 2 then
		local h = 6
		for _, s in { -1, 1 } do
			b.box("GatePad", 1.3, 0.5, 1.3, b.at(s * PX, FLOOR + 0.25, FZ0), L.stone)
			b.box("GatePost", 0.9, h - 0.5, 0.9, b.at(s * PX, FLOOR + 0.5 + (h - 0.5) / 2, FZ0), L.beam)
			if f >= 1 then
				lamp(b.face(s * PX, FLOOR + 3.6, FZ0 - 0.45, FRONT), 0.8, true)
			else
				b.ball("GateKnob", 0.5, b.at(s * PX, FLOOR + h + 0.3, FZ0), L.beam)
			end
		end
		if f >= 1 and era == 1 then
			-- 1 a timber arch over the gate with the pink heart on it, a lantern on each post
			archRing("GateArch", 0, PX, FLOOR + h - 0.3, 2.2, FZ0, 0.7, 0.6, L.beam, nil, L.board)
			for _, s in { -1, 1 } do
				b.beam(
					"GateBrace",
					0.4,
					0.4,
					V(s * PX, FLOOR + h - 2, FZ0),
					V(s * (PX - 1.2), FLOOR + h + 0.9, FZ0),
					L.board
				)
			end
			emblem(b.face(0, FLOOR + h + 2.5, FZ0, FRONT), 0.85, ROSE)
		elseif f >= 1 then
			-- a red tiled roof over the gate, its gable to the front with the heart in it
			b.box("GateBeam", PX * 2 + 1.8, 0.6, 0.7, b.at(0, FLOOR + h - 0.3, FZ0), L.beam)
			for _, s in { -1, 1 } do
				b.trim("GateCrossBeam", 0.6, 0.5, 3, b.at(s * PX, FLOOR + h - 0.25, FZ0), L.board)
			end
			frontGable(0, PX + 0.8, FLOOR + h, FZ0 - 1.5, FZ0 + 1.5, 2.3, 0.5, L.wall)
			emblem(b.face(0, FLOOR + h + 0.95, FZ0 - 1.62, FRONT), 0.75, ROSE)
		end
	else
		-- piers under an arch: stone, then steel and teal glass, then marble and gold; a lantern on each
		local px, h = PX + 0.3, 4.2
		local spring, R = FLOOR + h + 0.4, 2.6
		for _, s in { -1, 1 } do
			b.box("GatePierFoot", 2.2, 0.6, 2.2, b.at(s * px, FLOOR + 0.3, FZ0), L.stone)
			b.box(
				"GatePier",
				1.8,
				h - 0.6,
				1.8,
				b.at(s * px, FLOOR + 0.6 + (h - 0.6) / 2, FZ0),
				if era == 5 then L.wall else L.lower
			)
			b.box(
				"GatePierCap",
				2.2,
				0.4,
				2.2,
				b.at(s * px, FLOOR + h + 0.2, FZ0),
				if era == 5 then L.gold else L.frame,
				if era == 5 then bigGold else nil
			)
			lamp(b.face(s * px, FLOOR + 3.7, FZ0 - 0.9, FRONT), 0.65, true)
			if f >= 11 then
				-- 11 banners with a gold egg on the gate's two pillars (and on the turret, below)
				banner(b.face(s * px, FLOOR + 3, FZ0 - 0.9, FRONT), 1.2, 1.7)
			end
			if f >= 18 then
				gooTube(s * (px + 1.25), FLOOR, FZ0 - 0.6, 3.2)
			end
		end
		local crown = spring + R
		if era == 3 then
			-- (proud voussoirs in two stones, a keystone)
			archRing("GateArch", 0, px, spring, R, FZ0, 1.3, 1, L.frame, nil, L.lower)
			b.trim("GateKeystone", 1, 1.4, 1.5, b.at(0, crown, FZ0), L.frame)
			emblem(b.face(0, crown + 1.35, FZ0, FRONT), 0.8, ROSE)
		elseif era == 4 then
			archRing("GateArch", 0, px + 0.45, spring, R + 0.45, FZ0, 0.6, 0.3, L.beam)
			archRing("GateArch", 0, px - 0.45, spring, R - 0.45, FZ0, 0.6, 0.3, L.beam)
			archRing("GateGlass", 0, px, spring, R, FZ0, 0.16, 0.7, L.wall)
			for k = 1, 7 do
				local ax, ay = arc(px - 0.45, spring, R - 0.45, k)
				local bx, by = arc(px + 0.45, spring, R + 0.45, k)
				b.rod("GateArchBar", 0.1, V(ax, ay, FZ0), V(bx, by, FZ0), L.beam)
			end
			if f >= 16 then
				-- 16 a brass gear wheel on the gate arch, the heart in its middle (a dark plate behind it: brass
				-- on glass does not read)
				local face = b.face(0, crown + 0.5, FZ0 - 0.35, FRONT)
				b.disc("GearPlate", 1.6, 0.2, face * CFrame.new(0, 0, 0.05), DARK)
				if not piece("Gear_Wheel", face * CFrame.new(0, 0, -0.3), 1.45, 1.45, 0.8, L.gold, M.Metal) then
					b.disc("Gear", 1.3, 0.3, face * CFrame.new(0, 0, -0.2), L.gold, M.Metal)
					for k = 0, 7 do
						b.trim(
							"GearTooth",
							0.45,
							0.5,
							0.3,
							face * CFrame.Angles(0, 0, k * math.pi / 4) * CFrame.new(0, 1.4, -0.2),
							L.gold,
							M.Metal
						)
					end
				end
				emblem(face * CFrame.new(0, 0, -0.65), 0.55, ROSE)
			else
				emblem(b.face(0, crown + 1.1, FZ0, FRONT), 0.8, ROSE)
			end
		else
			archRing("GateArch", 0, px, spring, R, FZ0, 1.2, 0.9, L.wall)
			-- (thin gold rims at the arch's two edges: one gold band over its whole back read as a gold arch)
			for _, dz in { -0.5, 0.5 } do
				archRing("GateArchGold", 0, px + 0.5, spring, R + 0.5, FZ0 + dz, 0.3, 0.16, L.gold, M.Metal)
			end
			archRing("GateArchGold", 0, px - 0.5, spring, R - 0.5, FZ0, 1.3, 0.16, L.gold, M.Metal)
			b.trim("GateKeystone", 0.9, 1.3, 1.4, b.at(0, crown, FZ0), L.gold, M.Metal)
			emblem(b.face(0, crown + 0.1, FZ0 - 0.9, FRONT), 0.6, L.gold, M.Metal)
			local cf = b.at(0, crown + 0.6, FZ0)
			if not piece("ChimneyCrown_Gold", cf, 0.85, 0.85, 0.85, L.gold, M.Metal) then
				b.cyl("GateCrown", 0.85, 0.5, cf * CFrame.new(0, 0.25, 0), L.gold, M.Metal, false)
				for k = 0, 5 do
					local a = k * math.pi / 3
					local point = cf * CFrame.new(0.78 * math.cos(a), 0.7, 0.78 * math.sin(a))
					b.ball("GateCrownPoint", 0.2, point, L.gold, M.Metal)
				end
			end
		end
	end

	-- THE HALL -------------------------------------------------------------------------------------------------
	-- what is seen through the open front, against the back wall at `zBack` on the floor `y`: egg shelves, straw
	-- beds with eggs in them, a stack of hay, a warm light at `lightY`
	local function interior(half: number, zBack: number, y: number, lightY: number)
		local z = zBack - 0.5
		for i, h in { 2.3, 3.8 } do
			b.trim("Shelf", half - 0.8, 0.18, 0.9, b.at(half / 2, y + h, z), PLANK)
			for k = 1, 3 do
				local x = half / 2 + (k - 2) * (half - 2) / 3
				b.cyl("ShelfStraw", 0.42, 0.16, b.at(x, y + h + 0.17, z), HAY, nil, false)
				b.ball("ShelfEgg", 0.36, b.at(x, y + h + 0.52, z), EGGS[(i + k) % 4 + 1], M.SmoothPlastic)
			end
		end
		for _, s in { -1, 1 } do
			b.trim("ShelfPost", 0.25, 4, 0.8, b.at(half / 2 + s * (half / 2 - 0.5), y + 2, z), BOX)
		end
		for i, p in { { -half * 0.55, zBack - 2.3 }, { half * 0.4, zBack - 3.4 }, { -half * 0.2, zBack - 4.6 } } do
			b.cyl("StrawBed", 1.35, 0.4, b.at(p[1], y + 0.2, p[2]), STRAW, nil, false)
			b.cyl("StrawBed", 1.05, 0.55, b.at(p[1], y + 0.3, p[2]), HAY, nil, false)
			b.ball("BedEgg", 0.48, b.at(p[1] - 0.3, y + 0.85, p[2]), EGGS[i], M.SmoothPlastic)
			b.ball("BedEgg", 0.4, b.at(p[1] + 0.45, y + 0.8, p[2] + 0.2), EGGS[i + 1], M.SmoothPlastic)
		end
		if not painted("HayBales_Stack", b.at(-half + 2.1, y, zBack - 1.6), 0.7) then
			b.box("HayBale", 2.4, 1.2, 1.4, b.at(-half + 2, y + 0.6, zBack - 1.2), HAY)
			b.box("HayBale", 1.8, 1.1, 1.3, b.at(-half + 2.1, y + 1.75, zBack - 1.2), HAY)
		end
		b.rod("LightCord", 0.05, V(0, lightY + 0.9, zBack - depth / 2), V(0, lightY, zBack - depth / 2), IRON)
		light(b.ball("HallLight", 0.32, b.at(0, lightY, zBack - depth / 2), L.glass, M.Neon), L.glass, 18, 0.6)
	end

	local crest = top + rise -- the hall roof's top
	local roofHalf = hw -- half the roof's width at its eaves
	-- the roof's height `x` out from its middle line
	local function roofAt(x: number): number
		if era == 4 then
			return top + rise * math.sqrt(math.max(0, 1 - (x / hw) ^ 2))
		end
		return crest - rise / roofHalf * x
	end
	local heartFace: CFrame -- where the heart hangs over the open front
	local hallFloor = FLOORS[era]

	if bodied then
		worn(bodyName)
		if era == 1 then
			-- (the open truss, then 2 the closed gable; 3 the warm room; 4 its chimney)
			worn(if f < 2 then "BreedingTruss1" else "BreedingGable1")
			if f >= 3 then
				worn("BreedingLean1")
			end
			if f >= 4 then
				worn("BreedingChimney1")
			end
		elseif era == 2 then
			if f >= 8 then
				worn("BreedingWing2")
			end
		elseif era == 3 then
			-- (the roof on the stone hall, or 14 the jettied storey under it)
			worn(if f >= 14 then "BreedingStorey3" else "BreedingRoof3")
		end
	end
	shell(true)

	if era <= 2 then
		-- A TIMBER HALL: plank (then plaster) walls framed in timber, its whole front open between two posts, its
		-- gable to the front
		local sill = FLOOR + 2.6
		local lower = if era == 1 then L.lower else L.wall
		slab("HallFloor", -hw - 0.4, hw + 0.4, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, hallFloor)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR, sill, HZ + 0.8, zb, lower)
			slab("SideWall", s * (hw - T), s * hw, sill, top, HZ + 0.8, zb, L.wall)
			b.timber(b.face(s * hw, (FLOOR + top) / 2, (HZ + 0.8 + zb) / 2, V(s, 0, 0)), depth - 0.8, wallH, L.beam)
			b.box("PostPad", 1.4, 0.5, 1.4, b.at(s * (hw - 0.45), FLOOR + 0.25, HZ + 0.45), L.stone)
			b.box(
				"Post",
				0.9,
				wallH - 0.5,
				0.9,
				b.at(s * (hw - 0.45), FLOOR + 0.5 + (wallH - 0.5) / 2, HZ + 0.45),
				L.beam
			)
			b.beam(
				"Brace",
				0.45,
				0.45,
				V(s * (hw - 0.7), top - 2.7, HZ + 0.45),
				V(s * (hw - 2.5), top - 0.8, HZ + 0.45),
				L.board
			)
		end
		slab("BackWall", -hw, hw, FLOOR, sill, zb - T, zb, lower)
		slab("BackWall", -hw, hw, sill, top, zb - T, zb, L.wall)
		b.timber(b.face(0, (FLOOR + top) / 2, zb, BACK), hw * 2, wallH, L.beam)
		-- (under a body it ends inside the posts: the model's beam does)
		b.box("TieBeam", if bodied then hw * 2 - 0.2 else hw * 2 + 1, 0.7, 0.9, b.at(0, top - 0.35, HZ + 0.45), L.beam)
		-- the roof: open as a truss until 2 closes it
		local open = f < 2
		local over = 1
		local pitch = rise / hw
		frontGable(0, hw, top, HZ, zb, rise, over, L.wall, if open then -1 else nil)
		if open then
			for _, s in { -1, 1 } do
				b.beam("Rafter", 0.5, 0.5, V(s * hw, top, HZ + 0.3), V(0, top + rise - 0.35, HZ + 0.3), L.beam)
				-- (the barge boards the roof's own gable end would have had)
				b.beam(
					"BargeBoard",
					0.25,
					0.9,
					V(s * (hw + over), top - pitch * over - 0.3, HZ - over - 0.05),
					V(0, top + rise - 0.3, HZ - over - 0.05),
					L.board
				)
			end
			b.box("KingPost", 0.5, rise - 0.7, 0.5, b.at(0, top + (rise - 0.7) / 2, HZ + 0.3), L.beam)
			b.box("Collar", if bodied then hw - 2.4 else hw, 0.4, 0.4, b.at(0, top + rise * 0.5, HZ + 0.3), L.beam)
		else
			-- 2 the gable closed with cream plaster (it carries the heart, below), lanterns on the two front posts
			b.trim(
				"GableRail",
				hw * 2 - 0.4,
				0.4,
				0.25,
				b.face(0, top + 0.2, HZ, FRONT) * CFrame.new(0, 0, -0.1),
				L.beam
			)
			for _, s in { -1, 1 } do
				b.beam(
					"GableStrut",
					0.3,
					0.3,
					V(s * hw * 0.62, top + 0.3, HZ - 0.1),
					V(s * hw * 0.3, top + rise * 0.66, HZ - 0.1),
					L.beam
				)
				lamp(b.face(s * (hw - 0.45), FLOOR + 3.9, HZ, FRONT), 1, true)
			end
			if f >= 6 then
				-- 6 two flower boxes on the gable's beam, one each side of the heart (one box in the middle hid it)
				for _, s in { -1, 1 } do
					flowerBox(b.face(s * hw * 0.56, top + 0.75, HZ, FRONT), 2.3, true)
				end
			end
		end
		heartFace = b.face(0, top + rise * 0.5, HZ - 0.3, FRONT)
		interior(hw - T, zb - T, FLOOR + 0.2, top - 1.2)
	elseif era == 3 then
		-- A STONE HALL with one great arch; 14 a jettied half-timbered storey under a higher roof
		local ow, spring, R = hw - 2.8, FLOOR + 3.6, 3.3
		slab("HallFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, hallFloor)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR, top, HZ, zb, L.lower)
			slab("FrontWall", s * ow, s * hw, FLOOR, top, HZ, HZ + 0.8, L.lower)
			-- (quoins at the corners, a lantern on each pier)
			for k = 0, 4 do
				b.trim(
					"Quoin",
					1.1 - (k % 2) * 0.3,
					0.8,
					1.1,
					b.at(s * (hw - 0.3), FLOOR + 0.6 + k * 1.6, HZ + 0.3),
					L.frame
				)
			end
			lamp(b.face(s * (ow + 1.5), FLOOR + 3.9, HZ, FRONT), 0.8, true)
		end
		slab("BackWall", -hw, hw, FLOOR, top, zb - T, zb, L.lower)
		slab("Plinth", -hw - 0.2, hw + 0.2, FLOOR, FLOOR + 0.7, zb - 0.1, zb + 0.2, L.stone)
		archWall("FrontWall", 0, ow, spring, R, top, HZ + 0.4, 0.8, L.lower)
		-- (proud voussoirs in two stones, a keystone)
		archRing("ArchStone", 0, ow + 0.45, spring, R + 0.45, HZ + 0.15, 1.3, 0.9, L.frame, nil, L.stone)
		b.trim("Keystone", 1.1, 1.3, 1.5, b.at(0, spring + R + 0.35, HZ + 0.15), L.frame)
		b.trim("StringCourse", hw * 2 + 0.5, 0.4, 0.5, b.at(0, top - 0.2, HZ - 0.1), L.frame)
		if f >= 12 then
			-- 12 ivy with white flowers climbs over the great arch (the owner's Meshy ivy at the two haunches)
			for _, s in { -1, 1 } do
				painted("Ivy_Corner", b.face(s * (ow + 0.9), top - 1.7, HZ - 0.05, FRONT), 0.5, 0.2)
			end
			for k = 1, 7 do
				local ax, ay = arc(ow + 0.6, spring, R + 0.6, k)
				-- (small light clumps: big balls of the leaf green read as dark blobs on the pale stones)
				b.ball("Ivy", 0.46 - (k % 2) * 0.1, b.at(ax, ay + 0.2, HZ - 0.55), IVY)
				b.ball("IvyFlower", 0.24, b.at(ax + 0.3, ay + 0.4, HZ - 0.95), WHITE, M.SmoothPlastic)
				b.ball("IvyFlower", 0.2, b.at(ax - 0.28, ay - 0.05, HZ - 0.95), WHITE, M.SmoothPlastic)
			end
		end
		local y2, half2, z2 = top, hw, HZ
		if f >= 14 then
			local st = 3.8
			y2, half2, z2 = top + st, hw + 0.3, HZ - 0.6
			slab("Jetty", -half2 - 0.1, half2 + 0.1, top, top + 0.4, z2 - 0.1, zb + 0.2, L.beam)
			for k = -3, 3 do
				if k ~= 0 then
					b.trim("JettyBracket", 0.4, 0.5, 0.7, b.at(k * (hw - 0.6) / 3, top - 0.65, HZ - 0.35), L.board)
				end
			end
			slab("UpperWall", -half2, half2, top + 0.4, y2, z2, z2 + 0.5, L.wall)
			slab("UpperWall", -half2, half2, top + 0.4, y2, zb - 0.3, zb + 0.2, L.wall)
			b.timber(b.face(0, top + 0.4 + (st - 0.4) / 2, z2, FRONT), half2 * 2, st - 0.4, L.beam)
			for _, s in { -1, 1 } do
				slab("UpperWall", s * (half2 - 0.5), s * half2, top + 0.4, y2, z2, zb + 0.2, L.wall)
				b.timber(
					b.face(s * half2, top + 0.4 + (st - 0.4) / 2, (z2 + zb) / 2, V(s, 0, 0)),
					zb - z2,
					st - 0.4,
					L.beam
				)
				local window = b.face(s * 3.9, top + 2.2, z2, FRONT)
				if not painted("Window_Shutters", window, 0.6, 0.3) then
					b.window(window, 1.5, 1.7, L.frame, L.glass, { shutters = L.shutters, glow = true })
				end
				flowerBox(window * CFrame.new(0, -1.25, 0), 2.6, s > 0)
			end
		end
		frontGable(0, half2, y2, z2, zb, rise, 0.9, L.wall)
		b.trim("GableRail", half2 * 2 - 0.4, 0.4, 0.25, b.face(0, y2 + 0.2, z2, FRONT) * CFrame.new(0, 0, -0.1), L.beam)
		for _, s in { -1, 1 } do
			b.beam(
				"GableStrut",
				0.3,
				0.3,
				V(s * half2 * 0.62, y2 + 0.3, z2 - 0.1),
				V(s * half2 * 0.3, y2 + rise * 0.66, z2 - 0.1),
				L.beam
			)
		end
		crest, roofHalf = y2 + rise, half2
		heartFace = b.face(0, y2 + rise * 0.48, z2 - 0.3, FRONT)
		interior(hw - T, zb - T, FLOOR + 0.2, top - 1.4)
	elseif era == 4 then
		-- A STEEL AND TEAL GLASS VAULT on brick, its brick-and-steel arch open to the front under a glass lunette
		slab("HallFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, hallFloor)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR, FLOOR + 2.8, HZ, zb, L.lower)
			slab("SideGlass", s * (hw - 0.4), s * (hw - 0.2), FLOOR + 2.8, top, HZ, zb, L.wall)
			for k = 0, 3 do
				local z = HZ + 0.3 + k * (depth - 0.6) / 3
				b.trim(
					"SidePost",
					0.5,
					wallH - 2.8,
					0.5,
					b.at(s * (hw - 0.3), FLOOR + 2.8 + (wallH - 2.8) / 2, z),
					L.beam
				)
			end
			b.trim("SideRail", 0.5, 0.5, depth, b.at(s * (hw - 0.3), top - 0.25, zc), L.beam)
			b.trim("SideCap", 0.9, 0.3, depth, b.at(s * (hw - 0.3), FLOOR + 2.95, zc), L.frame)
			-- the front piers, a lantern on each
			slab("FrontPier", s * (hw - 1.7), s * (hw + 0.2), FLOOR, top, HZ - 0.4, HZ + 0.8, L.lower)
			b.trim("FrontPierCap", 2.3, 0.4, 1.6, b.at(s * (hw - 0.75), top + 0.2, HZ + 0.2), L.frame)
			b.trim("FrontPierFoot", 2.3, 0.7, 1.6, b.at(s * (hw - 0.75), FLOOR + 0.35, HZ + 0.2), L.stone)
			lamp(b.face(s * (hw - 0.75), FLOOR + 4.4, HZ - 0.4, FRONT), 0.9, true)
		end
		slab("BackWall", -hw, hw, FLOOR, FLOOR + 2.8, zb - T, zb, L.lower)
		slab("BackGlass", -hw, hw, FLOOR + 2.8, top, zb - 0.3, zb - 0.1, L.wall)
		fan(0, hw - 0.3, top, rise - 0.3, zb - 0.2, L.wall)
		archRing("VaultGlass", 0, hw, top, rise, zc, depth, 0.18, L.roof)
		for k = 0, 3 do
			archRing("VaultRib", 0, hw + 0.1, top, rise + 0.1, HZ + 0.2 + k * (depth - 0.4) / 3, 0.45, 0.5, L.beam)
		end
		for k = 1, 7 do
			local ax, ay = arc(hw + 0.2, top, rise + 0.2, k)
			b.rod("Purlin", 0.13, V(ax, ay, HZ), V(ax, ay, zb), L.beam)
		end
		-- the front: a heavy ring in brick and stone, a steel transom, the lunette's glass and its glazing bars
		archRing("FrontArch", 0, hw + 0.2, top, rise + 0.2, HZ - 0.1, 1.1, 0.9, L.lower, nil, L.frame)
		b.trim("Transom", (hw - 1.7) * 2, 0.5, 0.6, b.at(0, top + 0.1, HZ + 0.1), L.beam)
		fan(0, hw - 0.5, top + 0.3, rise - 0.5, HZ + 0.15, L.wall)
		for k = 1, 7 do
			local ax, ay = arc(hw - 0.5, top + 0.3, rise - 0.5, k)
			b.rod("LunetteBar", 0.1, V(0, top + 0.3, HZ), V(ax, ay, HZ), L.beam)
		end
		-- (a dark plate behind the heart: pink on glass does not read)
		b.disc("HeartPlate", 2, 0.2, b.face(0, top + rise * 0.48, HZ - 0.15, FRONT), DARK)
		heartFace = b.face(0, top + rise * 0.48, HZ - 0.6, FRONT)
		interior(hw - T, zb - T, FLOOR + 0.2, top - 1.6)
	else
		-- A MARBLE HALL: four columns under an entablature and a pediment, a portico's depth in front of the wall
		local pz, ez = HZ - 1.2, HZ - 2
		slab("HallFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.25, ez, zb + 0.2, hallFloor)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR + 0.25, top, HZ, zb, L.wall)
			slab("FrontWall", s * (hw - 1.7), s * hw, FLOOR + 0.25, top - 1.3, HZ, HZ + T, L.wall)
			b.trim("SideCornice", 0.5, 0.35, depth + 0.4, b.at(s * (hw + 0.1), top - 0.2, zc), L.gold)
			b.trim("SidePlinth", 0.4, 0.7, depth + 0.2, b.at(s * (hw + 0.1), FLOOR + 0.6, zc), L.stone)
			lamp(b.face(s * (hw - 0.85), FLOOR + 4.6, HZ, FRONT), 0.9, true)
		end
		slab("BackWall", -hw, hw, FLOOR + 0.25, top, zb - T, zb, L.wall)
		slab("Entablature", -hw - 0.2, hw + 0.2, top - 1.3, top, ez, HZ + T, L.wall)
		b.trim("Frieze", hw * 2 + 0.5, 0.35, 0.2, b.at(0, top - 1.1, ez - 0.05), L.gold)
		b.trim("Cornice", hw * 2 + 1, 0.3, 0.5, b.at(0, top - 0.15, ez - 0.2), L.gold)
		for _, x in { -(hw - 0.9), -3.7, 3.7, hw - 0.9 } do
			column(x, pz, FLOOR + 0.25, top - 1.3, 0.6)
		end
		roofHalf = hw + 0.2
		frontGable(0, roofHalf, top, ez, zb, rise, 0.6, L.wall)
		for _, s in { -1, 1 } do
			b.ball("Acroterion", 0.45, b.at(s * (hw + 0.4), top + 0.5, ez - 0.2), L.gold, M.Metal)
		end
		b.ball("Acroterion", 0.5, b.at(0, crest + 0.7, ez - 0.4), L.gold, M.Metal)
		heartFace = b.face(0, top + 1.55, ez - 0.3, FRONT)
		if f >= 22 then
			-- 22 gold laurels round the heart on the pediment
			if not painted("Laurel_Gold", b.face(0, top + 1.75, ez - 0.05, FRONT), 0.78, 0.6) then
				for _, s in { -1, 1 } do
					for i = 0, 3 do
						local leaf = b.face(0, top + 1.5, ez - 0.2, FRONT)
							* CFrame.Angles(0, 0, s * math.rad(50 + i * 28))
							* CFrame.new(0, -1.9, 0)
						b.trim("Laurel", 0.5, 1, 0.2, leaf, L.gold, M.Metal)
					end
				end
			end
		end
		interior(hw - T, zb - T, FLOOR + 0.25, top - 2)
	end

	shell(false) -- (the heart, the dormers and the egg are parts of their own)

	-- THE HEART over the open front: 2 it comes with the closed gable, and stays
	if f >= 2 then
		local s = ({ 1.5, 1.5, 1.5, 1.55, 1.2 })[era]
		emblem(heartFace, s, if era == 5 then L.gold else ROSE, if era == 5 then M.Metal else nil)
	end

	-- 9 two dormers with lit windows on the hall's roof, one each side of the egg
	if f >= 9 then
		for _, s in { -1, 1 } do
			if era == 4 then
				dormer(s, hw * 0.92, hw * 0.74, top + rise * 0.38, zc)
			else
				local eave = crest - rise
				local pitch = rise / roofHalf
				local yb = eave + pitch * 0.5 - 0.15
				local reach = if era == 5 then 1.5 else 2.8
				local xk = math.max(roofHalf - (yb + reach - eave) / pitch, EGG_R[math.min(5, f // 5)] + 1.8)
				dormer(s, roofHalf - 0.5, xk, yb, zc)
			end
		end
	end

	-- THE EGG on the hall's roof: five forms, one bigger and grander at the last level of every era ------------------
	if f >= 5 then
		local stage = math.min(5, f // 5)
		local r = EGG_R[stage]
		local rw, rt = r * EGG_WIDE, r * EGG_TALL -- the egg as worn
		local rd = r + 0.25 -- its drum
		local ze = if stage == 1 then HZ + depth * 0.45 else zc
		local foot = roofAt(rd) - 0.2 -- (the drum goes down into the roof)
		local drumTop = crest + ({ 0.9, 1.5, 3.6, 3.6, 6 })[stage]
		if era == 5 and stage == 4 then
			drumTop = crest + 5
		end
		-- (on a drum the egg sits sunk to its widest, as in a cup: a whole egg on a drum's top reads tall and thin)
		local eggFoot = drumTop - (if stage >= 4 then 0.2 else 0.3) * rt
		local function ring(name: string, y: number, out: number, h: number, colour: Color3, material: Enum.Material?)
			b.cyl(name, rd + out, h, b.at(0, y, ze), colour, material, false)
		end
		-- a steep cone of the roof's own cover round the egg: its rim `R` out lies on the roof's two slopes, its
		-- side passes `rAt` out at the height `y`, its tip is hidden in the egg
		local function skirt(R: number, rAt: number, y: number, colour: Color3)
			local yb = roofAt(R)
			local steep = (y - yb) / (R - rAt)
			-- (never wider than the hall is deep: its rim came out through the front gable beside the heart; a
			-- short drum carries the narrower cone down to the slopes)
			local Rc = math.min(R, ze - HZ - 0.3)
			local yc = yb + (R - Rc) * steep
			-- (the cone's mesh stands 1.19 times its nominal height: its tip stays half a stud inside the egg's top)
			local up = math.min(Rc * steep, (eggFoot + 1.9 * rt - 0.5 - yc) / 1.19)
			coneRoof(b.at(0, yc, ze), Rc, up, colour, false)
			local y0 = roofAt(Rc) - 0.2
			if yc > y0 then
				b.cyl("EggCollarFoot", Rc - 0.05, yc - y0, b.at(0, (yc + y0) / 2, ze), colour, nil, false)
			end
		end
		if era <= 2 or stage == 2 then
			-- 5 an egg in a nest: no drum, the egg stands in a flared collar that rises out of the roof (thatch
			-- under a shaggy wreath, then tiles under a painted rim)
			local out = if stage == 1 then 1.4 else 1.75
			-- (the thatch nest a little higher, so its wreath shows over the gable's boards)
			eggFoot = roofAt(r + out) + 1.5 * out + (if era == 1 then 0.4 else 0)
			skirt(r + out, r, eggFoot, if era == 1 then STRAW else L.roof)
			if era == 1 then
				for course = 0, 1 do
					local rr, y = rw + 0.15 + course * 0.5, eggFoot + 0.3 - course * 0.6
					for k = 0, 11 do
						local a0 = (k + course * 0.5) * math.pi / 6
						local a1 = a0 + math.pi / 6
						b.rod(
							"EggNestRoll",
							0.5 + course * 0.1,
							V(rr * math.cos(a0), y, ze + rr * math.sin(a0)),
							V(rr * math.cos(a1), y, ze + rr * math.sin(a1)),
							if (k + course) % 2 == 0 then L.roof else HAY
						)
					end
				end
			else
				ring("EggCollarRim", eggFoot + 0.15, rw - r - 0.05, 0.45, if era == 2 then L.beam else L.frame)
			end
		elseif era == 3 then
			-- 15 a round stone drum with lit windows, a tiled apron at its foot on the roof's two slopes
			b.cyl("EggDrum", rd, drumTop - foot, b.at(0, (foot + drumTop) / 2, ze), L.lower)
			ring("EggDrumBand", drumTop - 0.2, 0.2, 0.4, L.frame)
			skirt(rd + 1.5, rd, crest + 0.5, L.roof)
		elseif era == 4 then
			-- a riveted steel drum in brass bands
			b.cyl("EggDrum", rd, drumTop - foot, b.at(0, (foot + drumTop) / 2, ze), L.beam)
			ring("EggDrumBand", drumTop - 0.2, 0.2, 0.4, L.gold, M.Metal)
			ring("EggDrumBand", crest + 0.4, 0.25, 0.5, L.gold, M.Metal)
		else
			-- a marble drum in gold bands; 25 taller, ringed with gold columns under a gold cornice
			b.cyl("EggDrum", rd, drumTop - foot, b.at(0, (foot + drumTop) / 2, ze), L.wall)
			ring("EggDrumBand", drumTop - 0.25, 0.3, 0.5, L.gold, M.Metal)
			ring("EggDrumBand", crest + 0.5, 0.3, 0.5, L.gold, M.Metal)
			if stage == 5 then
				ring("EggDrumFoot", crest + 2.2, 0.9, 0.4, L.wall)
				for k = 0, 11 do
					local a = (k + 0.5) * math.pi / 6
					local x, z = (rd + 0.6) * math.sin(a), ze - (rd + 0.6) * math.cos(a)
					b.cyl(
						"EggDrumColumn",
						0.26,
						drumTop - crest - 3.1,
						b.at(x, (crest + 2.4 + drumTop - 0.7) / 2, z),
						L.gold,
						M.Metal,
						false
					)
				end
				ring("EggDrumCornice", drumTop - 0.45, 0.95, 0.5, L.gold, M.Metal)
			end
		end
		if stage >= 3 then
			-- 15 lit windows round the tall drum
			local n = if stage == 5 then 6 else 8
			local wy = if stage == 5 then (crest + 2.4 + drumTop - 0.7) / 2 else crest + (drumTop - crest) * 0.52
			for k = 0, n - 1 do
				local a = k * 2 * math.pi / n
				local out = V(math.sin(a), 0, -math.cos(a))
				b.window(
					b.face(rd * out.X, wy, ze + rd * out.Z, out),
					1,
					1.7,
					if era == 4 then L.board else L.frame,
					L.glass,
					{ arch = true, glow = true }
				)
			end
		end
		local cf = b.at(0, eggFoot, ze)
		local glow = stage >= 4 -- 20 its spots glow
		local ribs = if stage >= 4 then (if era == 4 then L.board else L.gold) else nil
		if piece("EggDome_Shell", cf, rw, rt, rw, EGG, M.SmoothPlastic) then
			-- (a deep violet when lit: the lavender washes out to white under Neon in daylight)
			piece(
				"EggDome_Spots",
				cf,
				rw,
				rt,
				rw,
				if glow then SPOT_LIT else SPOT,
				if glow then M.Neon else M.SmoothPlastic
			)
			if ribs then
				-- 20 a great dome of ribs and bands over it (black steel and brass, then gold)
				piece("EggDome_Ribs", cf, rw, rt, rw, ribs, M.Metal)
				piece("EggDome_Bands", cf, rw, rt, rw, L.gold, M.Metal)
			end
		else
			b.ball("Egg", r, cf * CFrame.new(0, 0.3 * r, 0), EGG, M.SmoothPlastic)
			b.ball("Egg", 0.74 * r, cf * CFrame.new(0, 1.12 * r, 0), EGG, M.SmoothPlastic)
			for k = 0, 7 do
				local a = k * math.pi / 4 + 0.3
				local high = k % 2 == 1
				local out, y = if high then 0.66 * r else 0.9 * r, if high then 1.2 * r else 0.45 * r
				local spot = cf * CFrame.new(out * math.sin(a), y, -out * math.cos(a))
				b.ball("EggSpot", 0.22 * r, spot, SPOT, if glow then M.Neon else M.SmoothPlastic)
			end
			if ribs then
				b.cyl("EggBand", r * 1.03, 0.3, cf * CFrame.new(0, 0.3 * r, 0), L.gold, M.Metal, false)
				for k = 0, 3 do
					local a = k * math.pi / 4
					b.beam(
						"EggRib",
						0.3,
						0.3,
						V(r * math.sin(a), drumTop, ze - r * math.cos(a)),
						V(-r * math.sin(a), drumTop, ze + r * math.cos(a)),
						ribs,
						M.Metal
					)
				end
			end
		end
		local tip = cf * CFrame.new(0, 1.9 * rt, 0)
		if stage == 5 then
			-- 25 a gold crown on its top
			local crown = cf * CFrame.new(0, 1.78 * rt, 0)
			if not piece("ChimneyCrown_Gold", crown, 1.5, 1.5, 1.5, L.gold, M.Metal) then
				b.cyl("EggCrown", 1.5, 0.8, crown * CFrame.new(0, 0.4, 0), L.gold, M.Metal, false)
				for k = 0, 5 do
					local a = k * math.pi / 3
					local point = crown * CFrame.new(1.4 * math.cos(a), 1.1, 1.4 * math.sin(a))
					b.ball("EggCrownPoint", 0.34, point, L.gold, M.Metal)
				end
			end
			b.ball("EggCrownJewel", 0.5, tip * CFrame.new(0, 0.9, 0), PINK, M.Neon)
		elseif stage == 4 then
			-- a brass finial
			if not piece("ConeRoof_Finial", tip * CFrame.new(0, -0.15, 0), 5, 5, 5, L.gold, M.Metal) then
				b.cyl("EggFinial", 0.16, 1.2, tip * CFrame.new(0, 0.5, 0), L.gold, M.Metal, false)
				b.ball("EggFinial", 0.4, tip * CFrame.new(0, 1.2, 0), L.gold, M.Metal)
			end
		end
	end

	shell(true)

	-- THE WARM ROOM on the left as one walks in (+x), and THE RIGHT WING (-x) -----------------------------------
	-- a small closed room beside the hall under its own front gable: x xa..xb, z za..zb2, walls `h` high
	local function sideRoom(xa: number, xb: number, za: number, zb2: number, h: number, lower: Color3, upper: Color3)
		local cx, half = (xa + xb) / 2, math.abs(xb - xa) / 2
		local sill = FLOOR + math.min(3.2, h * 0.55)
		slab("RoomWall", xa, xb, FLOOR, sill, za, zb2, lower)
		slab("RoomWall", xa, xb, sill, FLOOR + h, za, zb2, upper)
		if upper ~= lower then
			b.timber(b.face(cx, (sill + FLOOR + h) / 2, za, FRONT), half * 2, FLOOR + h - sill, L.beam)
		end
		frontGable(cx, half, FLOOR + h, za, zb2, half * 0.85, 0.5, upper)
	end
	-- a round lit window in a wall at `face`
	local function roundWindow(face: CFrame, r: number)
		b.disc("RoundWindowFrame", r + 0.25, 0.3, face * CFrame.new(0, 0, -0.15), L.frame)
		b.disc("RoundWindow", r, 0.36, face * CFrame.new(0, 0, -0.17), L.glass, M.Neon)
		b.trim("RoundWindowBar", r * 2, 0.14, 0.4, face * CFrame.new(0, 0, -0.17), L.frame)
		b.trim("RoundWindowBar", 0.14, r * 2, 0.4, face * CFrame.new(0, 0, -0.17), L.frame)
	end
	-- a square chimney from the ground to `y1`, a cap and a pot
	local function chimney(x: number, z: number, y1: number, w: number, colour: Color3)
		b.box("Chimney", w, y1 - FLOOR, w, b.at(x, (FLOOR + y1) / 2, z), colour)
		b.trim("ChimneyCap", w + 0.5, 0.4, w + 0.5, b.at(x, y1 + 0.2, z), L.frame)
		b.cyl("ChimneyPot", w * 0.3, 0.9, b.at(x, y1 + 0.85, z), if era == 1 then L.accent else L.lower, nil, false)
	end
	local z0, z1 = HZ + 1.2, zb - 0.5 -- the side rooms' front and back
	local zm = (z0 + z1) / 2

	if era == 1 then
		if f >= 3 then
			-- 3 a thatched hay lean-to on the hall's left side with a lit window (high at the wall, low outside)
			local x1, x2 = hw, hw + 4.6
			local xm = (x1 + x2) / 2
			slab("LeanWall", x1, x2, FLOOR, FLOOR + 3.3, z0, z1, L.lower)
			b.wedge(
				"LeanWall",
				z1 - z0,
				1.7,
				x2 - x1,
				b.at(xm, FLOOR + 4.15, zm) * CFrame.Angles(0, -math.pi / 2, 0),
				L.wall
			)
			local roof = b.beam(
				"LeanRoof",
				z1 - z0 + 1.2,
				0.55,
				V(x1 + 0.1, FLOOR + 5.5, zm),
				V(x2 + 0.7, FLOOR + 3.45, zm),
				L.roof
			)
			roof.CastShadow = true
			b.rod("EaveRoll", 0.42, V(x2 + 0.6, FLOOR + 3.35, z0 - 0.6), V(x2 + 0.6, FLOOR + 3.35, z1 + 0.6), L.roof)
			b.rod("ThatchCourse", 0.3, V(xm + 0.4, FLOOR + 4.75, z0 - 0.6), V(xm + 0.4, FLOOR + 4.75, z1 + 0.6), STRAW)
			for _, x in { x1 + 0.3, x2 - 0.3 } do
				b.trim("LeanPost", 0.5, 3.3, 0.5, b.at(x, FLOOR + 1.65, z0 - 0.05), L.beam)
			end
			b.window(
				b.face(xm, FLOOR + 2.1, z0, FRONT),
				1.4,
				1.4,
				L.frame,
				L.glass,
				{ shutters = L.shutters, glow = true }
			)
			if not painted("HayBales_Stack", b.at(x2 + 1.1, FLOOR, z0 + 1.4), 0.5) then
				b.box("HayBale", 1.8, 1.1, 1.2, b.at(x2 + 1.1, FLOOR + 0.55, z0 + 1.4), HAY)
			end
			if f >= 4 then
				-- 4 a fieldstone chimney stands up through the lean-to's roof
				chimney(x2 - 1.4, z1 - 1.5, FLOOR + 10, 1.8, L.stone)
			end
		end
	elseif era == 2 then
		-- a red brick stove room with a brick chimney
		local x1, x2 = hw, hw + 5.6
		sideRoom(x1, x2, z0, z1, 5.2, L.lower, L.lower)
		b.trim("RoomPlinth", x2 - x1 + 0.3, 0.6, 0.4, b.at((x1 + x2) / 2, FLOOR + 0.3, z0 - 0.1), L.stone)
		local window = b.face(x1 + 1.5, FLOOR + 3.2, z0, FRONT)
		if not painted("Window_Shutters", window, 0.5, 0.3) then
			b.window(window, 1.3, 1.5, L.frame, L.glass, { shutters = L.shutters, glow = true })
		end
		chimney(x2 - 1.3, z1 - 1.4, FLOOR + 12.5, 1.7, L.lower)
		if f >= 7 then
			-- 7 a bread-oven mouth with a glowing fire in the stove room's front, under its own little tiled roof
			fireMouth(b.face(x1 + 3.9, FLOOR, z0, FRONT), L.stone, L.roof)
		end
		if f >= 8 then
			-- 8 a tiled bay on the hall's right side with a round lit window: the right wing
			local xa, xb = -hw - 5.2, -hw
			sideRoom(xa, xb, z0, z1, 5, L.wall, L.wall)
			for _, x in { xa + 0.3, xb - 0.3 } do
				b.trim("BayPost", 0.5, 5, 0.3, b.at(x, FLOOR + 2.5, z0 - 0.1), L.beam)
			end
			b.trim("BayRail", xb - xa, 0.4, 0.3, b.at((xa + xb) / 2, FLOOR + 4.8, z0 - 0.1), L.beam)
			roundWindow(b.face((xa + xb) / 2, FLOOR + 3.1, z0, FRONT), 0.95)
			flowerBox(b.face((xa + xb) / 2, FLOOR + 1.5, z0, FRONT), 2.8)
		end
	elseif era == 3 then
		-- a round stone turret under a red cone roof, its chimney behind; the right wing half-timbered
		local tx, tz, tr = hw + 3.4, HZ + 3.8, 3
		local th = FLOOR + 12
		b.cyl("Turret", tr, th - FLOOR, b.at(tx, (FLOOR + th) / 2, tz), L.lower)
		b.cyl("TurretPlinth", tr + 0.25, 0.8, b.at(tx, FLOOR + 0.4, tz), L.stone, nil, false)
		b.cyl("TurretCornice", tr + 0.35, 0.45, b.at(tx, th - 0.2, tz), L.frame, nil, false)
		coneRoof(b.at(tx, th, tz), tr + 0.8, 4.4, L.roof, true)
		chimney(tx + 1.9, tz + 2.6, FLOOR + 15.5, 1.4, L.stone)
		fireMouth(b.face(tx, FLOOR, tz - tr + 0.35, FRONT), L.frame, L.roof)
		b.window(b.face(tx, FLOOR + 6.2, tz - tr, FRONT), 1.1, 1.7, L.frame, L.glass, { arch = true, glow = true })
		b.window(b.face(tx + tr, FLOOR + 7.2, tz, V(1, 0, 0)), 1.1, 1.7, L.frame, L.glass, { arch = true, glow = true })
		if f >= 11 then
			banner(b.face(tx, FLOOR + 11.2, tz - tr - 0.05, FRONT), 1.4, 2.2)
		end
		local xa, xb = -hw - 5.6, -hw
		sideRoom(xa, xb, z0, z1, 6.4, L.lower, L.wall)
		roundWindow(b.face((xa + xb) / 2, FLOOR + 5, z0, FRONT), 0.95)
		b.window(b.face((xa + xb) / 2, FLOOR + 2, z0, FRONT), 1.6, 1.4, L.frame, L.glass, { glow = true })
		flowerBox(b.face((xa + xb) / 2, FLOOR + 0.9, z0, FRONT), 2.6)
	else
		-- eras 4 and 5: a wing on each side (a glass side vault, then marble with tall windows), and beyond the
		-- left one the goo boiler with its steel stack, then the marble tower
		local ww = 5.4
		for _, s in { -1, 1 } do
			local cx = s * (hw + ww / 2)
			if era == 4 then
				local half, spring, R = ww / 2 - 0.2, FLOOR + 4.4, 2.5
				slab("WingWall", s * (hw + ww - 0.5), s * (hw + ww), FLOOR, FLOOR + 1.8, z0, z1, L.lower)
				slab("WingGlass", s * (hw + ww - 0.35), s * (hw + ww - 0.15), FLOOR + 1.8, spring, z0, z1, L.wall)
				for _, z in { z0, z1 - 0.5 } do
					slab("WingWall", s * hw, s * (hw + ww), FLOOR, FLOOR + 1.8, z, z + 0.5, L.lower)
					slab("WingGlass", s * hw, s * (hw + ww), FLOOR + 1.8, spring, z + 0.15, z + 0.35, L.wall)
					fan(cx, half - 0.2, spring, R - 0.2, z + 0.25, L.wall)
				end
				b.trim("WingSill", ww + 0.3, 0.3, 0.8, b.at(cx, FLOOR + 1.95, z0 + 0.2), L.frame)
				for k = -1, 1 do
					b.trim(
						"WingPost",
						0.4,
						spring - FLOOR - 1.8,
						0.4,
						b.at(cx + k * half, (FLOOR + 1.8 + spring) / 2, z0 + 0.25),
						L.beam
					)
				end
				archRing("WingVault", cx, half, spring, R, zm, z1 - z0, 0.18, L.roof)
				for _, z in { z0 + 0.25, zm, z1 - 0.25 } do
					archRing("WingRib", cx, half + 0.1, spring, R + 0.1, z, 0.4, 0.4, L.beam)
				end
				b.trim("WingTransom", ww, 0.4, 0.5, b.at(cx, spring, z0 + 0.25), L.beam)
				light(b.ball("WingLight", 0.3, b.at(cx, spring + 0.6, zm), L.glass, M.Neon), L.glass, 12, 0.5)
			else
				local h = FLOOR + 7
				slab("Wing", s * hw, s * (hw + ww), FLOOR, h, z0, z1, L.wall)
				b.trim("WingPlinth", ww + 0.3, 0.7, 0.4, b.at(cx, FLOOR + 0.35, z0 - 0.1), L.stone)
				b.trim("WingCornice", ww + 0.6, 0.4, z1 - z0 + 0.6, b.at(cx, h + 0.2, zm), L.gold)
				for _, k in { -1, 1 } do
					local window = b.face(cx + k * 1.3, FLOOR + 3.4, z0, FRONT)
					if not painted("Window_Arched", window, 0.62, 0.25) then
						b.window(window, 1.5, 3, L.frame, L.glass, { arch = true, glow = true })
					end
				end
				for _, k in { -1, 0, 1 } do
					b.cyl(
						"WingPilaster",
						0.3,
						6.2,
						b.at(cx + k * (ww / 2 - 0.2), FLOOR + 3.5, z0 - 0.15),
						L.wall,
						nil,
						false
					)
				end
				balustrade(s * hw, z0 + 0.3, s * (hw + ww), z0 + 0.3, h + 0.4, L.wall, false, false, true)
				if f >= 24 then
					-- 24 small blue glass domes with gold ribs on the two wings
					b.cyl("WingDrum", 2.3, 0.7, b.at(cx, h + 0.75, zm + 0.4), L.wall, nil, false)
					dome(b.at(cx, h + 1.1, zm + 0.4), 2.15)
				end
			end
		end
		local bx, bz = hw + ww + 2.6, HZ + 4
		if era == 4 then
			-- the goo boiler: a glowing green tank on a brick foot, a riveted steel stack behind it
			slab("BoilerFoot", bx - 2.2, bx + 2.2, FLOOR, FLOOR + 3.2, bz - 2.2, bz + 2.2, L.lower)
			b.trim("BoilerFootCap", 4.8, 0.4, 4.8, b.at(bx, FLOOR + 3.4, bz), L.frame)
			fireMouth(b.face(bx, FLOOR, bz - 2.2, FRONT), L.stone, nil)
			local tx, tz = bx - 0.5, bz - 0.5
			local tank = painted("GooTank_Glass", b.at(tx, FLOOR + 3.6, tz), 1.2)
			if tank then
				light(tank, GOO, 16, 1)
			else
				-- (plain goo with a thin glowing slice: a big Neon volume burns out)
				b.cyl("GooTank", 1.6, 4.6, b.at(tx, FLOOR + 5.9, tz), GOO, M.Glass)
				light(b.cyl("GooGlow", 1.45, 0.3, b.at(tx, FLOOR + 5.5, tz), GOO, M.Neon, false), GOO, 16, 1)
				if piece("GlassDome_Frame", b.at(tx, FLOOR + 8.2, tz), 1.6, 1.6, 1.6, L.beam) then
					piece("GlassDome_Glass", b.at(tx, FLOOR + 8.2, tz), 1.6, 1.6, 1.6, GOO, M.Glass)
				else
					b.ball("GooTankCap", 1.6, b.at(tx, FLOOR + 8.2, tz), L.beam)
				end
			end
			local sx, sz, sy = bx + 1.35, bz + 1.35, FLOOR + 16.5
			b.cyl("Stack", 0.8, sy - FLOOR - 3.6, b.at(sx, (FLOOR + 3.6 + sy) / 2, sz), L.board)
			for y = FLOOR + 5, sy - 1, 2.8 do
				b.cyl("StackBand", 0.92, 0.3, b.at(sx, y, sz), L.gold, M.Metal, false)
			end
			b.cyl("StackTop", 1.05, 0.6, b.at(sx, sy - 0.1, sz), L.board, nil, false)
		else
			-- a marble tower with gold bands under a blue cone cap, the capital's banner on it
			local th = FLOOR + 15.5
			b.cyl("Tower", 2.4, th - FLOOR, b.at(bx, (FLOOR + th) / 2, bz), L.wall)
			b.cyl("TowerPlinth", 2.7, 0.9, b.at(bx, FLOOR + 0.45, bz), L.stone, nil, false)
			for _, y in { FLOOR + 4.6, FLOOR + 11.2, th - 0.25 } do
				b.cyl("TowerBand", 2.6, 0.45, b.at(bx, y, bz), L.gold, M.Metal, false)
			end
			coneRoof(b.at(bx, th, bz), 3.1, 4.4, L.roof, true)
			fireMouth(b.face(bx, FLOOR, bz - 1.95, FRONT), L.stone, L.roof)
			b.window(b.face(bx, FLOOR + 13.1, bz - 2.4, FRONT), 1, 1.8, L.frame, L.glass, { arch = true, glow = true })
			banner(b.face(bx, FLOOR + 10.6, bz - 2.42, FRONT), 1.3, 2.4)
		end
		local zw = HZ + 2.5 -- where the pipes cross the wings, behind their fronts
		if f >= 17 then
			-- 17 pipes from the boiler up over the hall's roof and down to the incubators (copper, then thin
			-- gold): over the wings, forward along the hall's side, over its front in front of the egg's drum
			local r = if era == 4 then 0.3 else 0.2
			local zr = if era == 4 then HZ - 0.1 else HZ - 1.2
			local side = if era == 4 then hw + 0.95 else hw + 1.1
			local wy = FLOOR + (if era == 4 then 7.8 else 9.3)
			local out = hw + ww + 0.5
			local points = {
				V(bx - 1.8, FLOOR + 5.6, zw),
				V(out, FLOOR + 5.6, zw),
				V(out, wy, zw),
				V(side, wy, zw),
				V(side, wy, zr),
			}
			if era == 4 then
				for k = 0, 8 do
					local ax, ay = arc(side, top, rise + 0.95, k)
					table.insert(points, V(ax, ay, zr))
				end
			else
				table.insert(points, V(side, top + 0.1, zr))
				table.insert(points, V(0, crest + 0.5, zr))
				table.insert(points, V(-side, top + 0.1, zr))
			end
			table.insert(points, V(-side, wy, zr))
			table.insert(points, V(-side, wy, zw))
			table.insert(points, V(-out - 0.1, wy, zw))
			-- (down the wing's outer wall: the incubators stand inside the yard now, in front of this corner)
			table.insert(points, V(-out - 0.1, FLOOR + 0.3, zw))
			pipe(points, r, L.accent)
			painted("PipeValve_Copper", b.face(-out - 0.1, FLOOR + 2.4, zw - r, FRONT), 0.4)
			-- (and along the yard's floor to the incubators' pad, laid where the grown pipe lands and kept out of
			-- Architecture.grow: the line must not end short of them)
			local px, pz = Architecture.grown("BreedingHouse", 0, PIVOT_Z, -out - 0.1, zw)
			local rk, foot = Architecture.grown("BreedingHouse", 0, 0, r, FLOOR + 0.3) -- (its radius and foot, grown)
			local runFrom = #m:GetChildren()
			pipe({ V(px, foot, pz), V(px, FLOOR + rk, pz), V(px, FLOOR + rk, INC_PAD_Z) }, rk, L.accent)
			Architecture.keep(m, runFrom, had)
		end
		if f >= 19 then
			-- 19 a second, smaller goo tank on the right wing, piped into the line to the incubators
			local tx, tz = -hw - ww - 1.9, HZ + 4.2
			slab(
				"TankFoot",
				tx - 1.4,
				tx + 1.4,
				FLOOR,
				FLOOR + 1.8,
				tz - 1.4,
				tz + 1.4,
				if era == 4 then L.lower else L.wall
			)
			b.trim("TankFootCap", 3.2, 0.3, 3.2, b.at(tx, FLOOR + 1.95, tz), if era == 4 then L.frame else L.gold)
			local tank = painted("GooTank_Glass", b.at(tx, FLOOR + 2.1, tz), 0.8)
			if tank then
				light(tank, GOO, 10, 0.8)
			else
				b.cyl("GooTank", 1, 3, b.at(tx, FLOOR + 3.6, tz), GOO, M.Glass)
				b.cyl("GooGlow", 0.9, 0.25, b.at(tx, FLOOR + 3.4, tz), GOO, M.Neon, false)
				b.ball("GooTankCap", 1, b.at(tx, FLOOR + 5.1, tz), L.beam)
			end
			pipe({ V(tx, FLOOR + 4.6, tz - 0.9), V(tx, FLOOR + 4.6, zw) }, if era == 4 then 0.24 else 0.18, L.accent)
		end
	end

	shell(false)

	-- BESIDE THE DOOR ---------------------------------------------------------------------------------------------
	if f >= 21 then
		for _, s in { -1, 1 } do
			local cf = b.at(s * 6.3, FLOOR, HZ - 2.9)
			if not painted("Urn_PinkFlowers", cf, 0.8) then
				b.cyl("FlowerUrn", 0.7, 1.3, cf * CFrame.new(0, 0.65, 0), L.gold, bigGold, false)
				b.ball("Flower", 0.8, cf * CFrame.new(0, 1.8, 0), BLOOMS[1])
			end
		end
	end
	if f >= 23 then
		-- 23 a golden slime statue on a pedestal each side of the door
		for _, s in { -1, 1 } do
			local x, z = s * 3.5, HZ - 3.4
			b.box("StatuePlinth", 2.2, 0.4, 2.2, b.at(x, FLOOR + 0.2, z), L.stone)
			b.box("StatuePedestal", 1.8, 1.4, 1.8, b.at(x, FLOOR + 1.1, z), L.wall)
			b.trim("StatuePedestalCap", 2.1, 0.25, 2.1, b.at(x, FLOOR + 1.9, z), L.gold)
			b.slime(b.at(x, FLOOR + 2, z), 0.95, L.gold, M.Metal)
		end
	end
end

-- The Breeding House at its drawn size, then its house grown (Config.Village.HouseScale).
function BreedingHouse.build(m: Instance, area: CFrame, level: number)
	local had = m:GetChildren()
	raise(m, area, level, had)
	Architecture.grow(m, had, area, "BreedingHouse", SPLIT_Z, PIVOT_X, PIVOT_Z)
end

return BreedingHouse
