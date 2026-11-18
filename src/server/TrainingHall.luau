--!strict
-- The training ground's landmark: the fenced yard, grown into the village's arena (village v2, skill landmark-build;
-- the owner approved the reference on 2026-11-17: docs/areas/village-v2/training-ref-sheet.jpg, the ladder is
-- training-ladder.md beside it). One place in five architectures, one an era of ten levels:
--   1 hamlet       a palisade of pointed logs, brown timber under thatch, a braced log lookout
--   2 painted      cream pickets on royal-blue posts, cream plaster on blue beams, red clay tiles, a boarded watchtower
--   3 town         a low stone wall with timber rails, a stone hall with one great arch, a round stone keep
--   4 slime tech   black steel and blue slate vaults, copper pipes, floodlights, a goo core in the steel tower
--   5 capital      white marble and gold, columns, arcade wings and a pediment, the tower under a blue and gold dome
-- The same five things at every era, in the same places, so it stays one place: THE FENCE round the yard with THE GATE
-- in the middle of its front (-z); THE HALL across the back (front wall at HZ), hollow, its front wide open on the
-- weapon racks and the benches; THE TOWER at the hall's right end as one comes in (-x), from level 10 on the tallest
-- thing, the squad's blue banner with its gold stripe on it; THE SHIELD with two crossed swords over the hall's open
-- front. The dummy, the training spots, the stations and the yard's floor are the area's own and stay TrainingStages'
-- business. `build` takes the AREA's frame: the lawn's top is y 0, the yard floor's top FLOOR.
-- An era's first level changes the architecture; levels 6-10 of each era add one feature each, and a feature once
-- added stays in every later era in that era's materials (25 in all, numbered in `build` as in the ladder).
local Architecture = require(script.Parent.Architecture)
local LibraryKit = require(script.Parent.LibraryKit)
local YardKit = require(script.Parent.YardKit)

local TrainingHall = {}

local C = Color3.fromRGB
local M = Enum.Material
local V = Vector3.new
local IRON = C(60, 60, 66)
local DARK = C(42, 34, 30)
local PLANK = C(176, 128, 78)
local BOX = C(128, 84, 50)
local LEAF = C(86, 160, 70)
local STRAW = C(204, 156, 62) -- the darker course half way up a thatch
local HAY = C(236, 204, 104)
local GOO = C(96, 232, 70)
local DOME = C(70, 124, 214) -- the capital's blue glass
local PANEL = C(224, 212, 186) -- the warmer stone in the capital's wall panels
local STEEL = C(208, 212, 220) -- sword blades and spear heads
local ROPE = C(214, 186, 128)
local BLOOMS = { C(255, 120, 150), C(255, 214, 80), C(240, 90, 80) }
-- the era's planter, from the owner's prop sheet (art/models/village_props/planter)
local PLANTERS = { "PropPlanterWood", "PropPlanterRiveted", "PropPlanterStone", "PropPlanterCrown", "PropPlanterRoyal" }
-- the hall's floor an era: colours with no material of their own, so they keep the stud look (the owner's choice)
local FLOORS = { C(178, 130, 80), C(178, 130, 80), C(170, 164, 154), C(92, 98, 110), C(232, 228, 220) }
local FRONT, BACK, SIDE = V(0, 0, -1), V(0, 0, 1), V(1, 0, 0)
local CORNERS = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }

local OX = 0 -- the yard's middle line in the area's frame
local FLOOR = 0.4 -- the yard floor's top
local XF, ZF, FZ1 = 18.8, 16.4, 28.4 -- the fence: x -XF..XF, z -ZF..FZ1 (the yard itself ends at z ZF)
local PX = 4 -- the gate's posts stand at x -PX and PX
local HZ = 17.4 -- the hall's front wall
local T = 0.6 -- a wall's thickness

-- THE SHELL: the hall's and the tower's parts the Blender bodies replace (tools/blender/landmark_bodies.py). Where
-- its body is there, a shell part that is only seen is not built, and a solid one stays as the wall a player
-- walks against, a hair inside the mesh.
local SHELL: { [string]: boolean } = {}
for name in
	string.gmatch(
		"SideWall PostPad Post Rail Brace BackWall TieBeam Roof Gable BargeBoard Ridge EaveRoll ThatchCourse VergeRoll "
			.. "EaveCourse RidgeRoll Rafter KingPost Collar GableRail GableStrut GablePost FrontWall Plinth ArchStone Keystone "
			.. "StringCourse StoreyBeam UpperWall Shoulder ShoulderFoot ShoulderCap SidePost SideRail SideCap FrontPier "
			.. "FrontPierCap FrontPierFoot Rivet VaultGlass VaultRib Purlin FrontArch Transom LunetteBar LunetteRing "
			.. "SideCornice WingBack WingEnd WingPlinth WingEndCornice WingPilaster WingPanel WingPanelCap WingFront WingArch "
			.. "WingRoof WingCornice Entablature Frieze Cornice RoofDeck TowerLeg TowerBrace PlatformPost PlatformRail "
			.. "Platform Ladder LadderRung CabinPost CabinFloor Cabin TowerFoot Tower TowerPost TowerBand TowerEave "
			.. "TowerCourse TowerNeck Corbel TowerCrown TowerMerlon TowerRib TowerHoop TowerRing",
		"%a+"
	)
do
	SHELL[name] = true
end

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
	cloth: Color3,
	gold: Color3,
	accent: Color3,
	fence: Color3,
	mats: { [string]: Enum.Material },
}

local LOOKS: { Look } = {
	{ -- 1 hamlet
		hw = 10,
		depth = 13.2, -- (the owner, 2026-11-17: the houses lacked depth; as deep as the pier is long once grown)
		wallH = 6.2,
		rise = 6,
		wall = C(196, 150, 98),
		lower = C(164, 114, 68),
		stone = C(150, 146, 138),
		beam = C(110, 72, 42),
		board = C(92, 60, 36),
		roof = C(232, 190, 84),
		frame = C(126, 84, 50),
		glass = C(238, 158, 60), -- (a deep amber: a paler lit pane washes out to white in daylight and loses its bars)
		cloth = C(52, 96, 204),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		fence = C(190, 146, 88),
		mats = {
			wall = M.WoodPlanks,
			lower = M.WoodPlanks,
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.Sand,
			frame = M.Wood,
			gold = M.Foil,
			accent = M.Metal,
			fence = M.Wood,
		},
	},
	{ -- 2 painted
		hw = 10.6,
		depth = 13.2,
		wallH = 6.8,
		rise = 6.4,
		wall = C(244, 238, 224),
		lower = C(226, 214, 190),
		stone = C(214, 206, 188),
		beam = C(70, 118, 224), -- (a light royal blue: Wood darkens it)
		board = C(48, 86, 184),
		roof = C(198, 70, 58),
		frame = C(250, 246, 236),
		glass = C(238, 158, 60),
		cloth = C(52, 96, 204),
		gold = C(236, 190, 70),
		accent = C(110, 72, 42),
		fence = C(250, 246, 236),
		mats = {
			wall = M.Plaster,
			lower = M.Limestone,
			stone = M.Limestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.ClayRoofTiles,
			frame = M.WoodPlanks,
			gold = M.Foil,
			accent = M.Wood,
		},
	},
	{ -- 3 town
		hw = 11,
		depth = 13.2,
		wallH = 7.4,
		rise = 5.6,
		wall = C(240, 230, 206),
		lower = C(192, 188, 178),
		stone = C(132, 128, 122),
		beam = C(112, 72, 44),
		board = C(92, 60, 38),
		roof = C(190, 62, 50), -- (the owner, 2026-11-17: one roof an era for every landmark, the Granary's)
		frame = C(224, 218, 204),
		glass = C(238, 158, 60),
		cloth = C(52, 96, 204),
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
			gold = M.Foil,
		},
	},
	{ -- 4 slime tech
		hw = 11.4,
		depth = 13.2,
		wallH = 6,
		rise = 8.4,
		wall = C(84, 190, 180), -- (teal darker than the sky: a paler pane read as one pale sheet)
		lower = C(72, 76, 88),
		stone = C(86, 90, 100),
		beam = C(52, 56, 64),
		board = C(40, 44, 50),
		roof = C(66, 108, 186),
		frame = C(104, 110, 122),
		glass = C(238, 158, 60),
		cloth = C(52, 96, 204),
		gold = C(224, 170, 70),
		accent = C(226, 132, 78), -- (bright: Metal darkens it, and a duller copper read as brown wood)
		fence = C(40, 44, 50),
		mats = {
			wall = M.Glass,
			lower = M.Metal,
			stone = M.Slate,
			beam = M.Metal,
			board = M.Metal,
			roof = M.RoofShingles,
			frame = M.Metal,
			gold = M.Metal,
			accent = M.Metal,
		},
	},
	{ -- 5 capital
		hw = 9.2,
		depth = 13.2,
		wallH = 9.5,
		rise = 3.9,
		wall = C(242, 239, 232), -- (not whiter: mouldings wash out in daylight)
		lower = C(214, 208, 196),
		stone = C(214, 208, 196),
		beam = C(228, 222, 210),
		board = C(236, 192, 76),
		roof = C(44, 84, 170),
		frame = C(236, 192, 76),
		glass = C(238, 158, 60),
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
function TrainingHall.features(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	return era, (era - 1) * 5 + math.max(0, s - 5)
end

-- The ground the place stands on, in the area's frame (x0, x1, z0, z1): scenery there goes.
-- (What Architecture.grow takes as the house: what stands at or behind SPLIT_Z; and the point it grows round.
-- The hall's face reaches 3 in front of its wall: the capital's portico, its lamp standards and urns, the steel
-- era's masts, the stone era's shoulder lamps, and the shield's blades stand another 1 proud of the pediment. At
-- 16.5 they kept their drawn size before a hall 1.9 times bigger. The fence is kept out by Architecture.keep, and
-- nothing else of the yard stands behind 13.5.)
local SPLIT_Z, PIVOT_X, PIVOT_Z = 13.5, 0, 17.4
function TrainingHall.footprint(_level: number): (number, number, number, number)
	return Architecture.grownBox(
		"TrainingHall",
		SPLIT_Z,
		PIVOT_X,
		PIVOT_Z,
		OX - XF - 1.5,
		OX + XF + 1.5,
		-ZF - 3,
		FZ1 + 1.5
	)
end

-- The fence stands round the GROWN hall at its own size (the owner, 2026-11-17: the yard out to both sides of the
-- hall): half its width and its back, where Architecture.grow puts the drawn fence's corner.
local WX, ZB = Architecture.grown("TrainingHall", 0, PIVOT_Z, XF, FZ1)

-- The fence in the area's frame (x0, x1, z0, z1): TrainingStages lays the floor to it.
function TrainingHall.fence(): (number, number, number, number)
	return OX - WX, OX + WX, -ZF, ZB
end

-- (`had`: what Architecture.grow leaves alone; the fence and its corners join it)
local function raise(m: Instance, area: CFrame, level: number, had: { Instance })
	local era, f = TrainingHall.features(level)
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
		[PANEL:ToHex()] = M.Marble,
	}
	for field, material in L.mats do
		skins[((L :: any)[field] :: Color3):ToHex()] = material
	end
	-- (0.08: at the other landmarks' 0.4, and still at 0.25, the vault's glass all but vanished in the game's daylight)
	local b = Architecture.new(m, frame, skins, 0.08)
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
	-- THE BODY: the era's hall as Blender meshes, a mesh a colour field, worn over the shell (see SHELL)
	local bodyName = "TrainingBody" .. era
	local bodied = LibraryKit.find(bodyName .. "_Stone") ~= nil -- the one field every era's body has
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
		{ "Shutters", PLANK },
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
	-- a glowing goo tube `h` high standing on (x, y, z), in brass collars
	local function gooTube(x: number, y: number, z: number, h: number)
		b.cyl("GooTube", 0.26, h, b.at(x, y + h / 2, z), GOO, M.Neon, false)
		for _, k in { 0.1, h - 0.1 } do
			b.cyl("GooTubeCollar", 0.36, 0.2, b.at(x, y + k, z), L.gold, bigGold, false)
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
			-- (the front edge: a thick darker roll up each slope and a second course over the eave, so the roof's
			-- edge reads as layered thatch and not as a lid)
			local vy = y - pitch * over + 0.15
			b.rod("VergeRoll", 0.45 * k, V(x, vy, za - over), V(cx, y + up + 0.15, za - over), STRAW)
			local xe = x - s * 0.8
			b.rod("EaveCourse", 0.4 * k, V(xe, vy + pitch * 0.8, za - over), V(xe, vy + pitch * 0.8, zb2 + over), STRAW)
		end
		b.rod(
			"RidgeRoll",
			0.65 * k,
			V(cx, y + up + 0.1, za - over - 0.1),
			V(cx, y + up + 0.1, zb2 + over + 0.1),
			L.roof
		)
	end
	-- (the helpers above are the village landmarks' own, as in BreedingHouse; from here on it is the Training Hall)
	-- a glowing globe lamp standing on (x, y, z)
	local function globe(x: number, y: number, z: number, glow: Color3, lit: boolean)
		b.cyl("GlobeStem", 0.14, 0.6, b.at(x, y + 0.3, z), IRON, nil, false)
		b.cyl("GlobeCollar", 0.34, 0.2, b.at(x, y + 0.6, z), L.gold, bigGold, false)
		local g = b.ball("Globe", 0.75, b.at(x, y + 1.3, z), glow, M.Neon)
		if lit then
			light(g, glow, 16, 0.7)
		end
	end
	-- the squad's cloth hanging from `face`: royal blue with a pointed foot, a gold stripe down it, or a gold sword
	local function banner(face: CFrame, w: number, h: number, sword: boolean)
		-- (smooth, not Fabric: Fabric's dark weave turns cloth slate grey)
		local side = w / math.sqrt(2)
		b.trim("BannerRod", w + 0.5, 0.22, 0.22, face * CFrame.new(0, 0, -0.25), L.gold)
		b.trim("Banner", w, h, 0.1, face * CFrame.new(0, -h / 2, -0.35), L.cloth, M.SmoothPlastic)
		local point = face * CFrame.new(0, -h, -0.35) * CFrame.Angles(0, 0, math.pi / 4)
		b.trim("BannerPoint", side, side, 0.1, point, L.cloth, M.SmoothPlastic)
		b.trim("BannerBand", w, 0.2, 0.12, face * CFrame.new(0, -0.35, -0.37), L.gold)
		if sword then
			b.trim("BannerSword", w * 0.15, h * 0.52, 0.1, face * CFrame.new(0, -h * 0.56, -0.4), L.gold)
			b.trim("BannerSword", w * 0.5, w * 0.13, 0.1, face * CFrame.new(0, -h * 0.36, -0.4), L.gold)
		else
			local long = h + side * 0.4 - 0.5
			b.trim("BannerStripe", w * 0.24, long, 0.1, face * CFrame.new(0, -0.5 - long / 2, -0.4), L.gold)
		end
	end
	-- THE SHIELD: a round shield with a boss and two crossed swords, `r` half its width, its back on the wall at `cf`
	local function shield(
		cf: CFrame,
		r: number,
		disc: Color3,
		discMat: Enum.Material?,
		rim: Color3,
		rimMat: Enum.Material?
	)
		local held = cf * CFrame.new(0, 0, -0.22 * r)
		if piece("ShieldEmblem_Disc", held, r, r, r, disc, discMat) then
			piece("ShieldEmblem_Rim", held, r, r, r, rim, rimMat)
			piece("ShieldEmblem_Blades", held, r, r, r, STEEL, M.Metal)
			piece("ShieldEmblem_Hilts", held, r, r, r, L.gold, M.Metal)
			return
		end
		b.disc("ShieldRim", r, 0.3, cf * CFrame.new(0, 0, -0.15), rim, rimMat)
		b.disc("Shield", r * 0.84, 0.44, cf * CFrame.new(0, 0, -0.22), disc, discMat)
		for _, s in { -1, 1 } do
			local lie = cf * CFrame.Angles(0, 0, s * math.pi / 4)
			b.trim("ShieldBlade", r * 0.2, r * 1.3, 0.14, lie * CFrame.new(0, r * 0.15, -0.52), STEEL, M.Metal)
			b.trim("ShieldGuard", r * 0.6, r * 0.13, 0.18, lie * CFrame.new(0, -r * 0.5, -0.54), L.gold, M.Metal)
			b.trim("ShieldGrip", r * 0.13, r * 0.3, 0.16, lie * CFrame.new(0, -r * 0.7, -0.53), L.gold, M.Metal)
		end
		b.ball("ShieldBoss", r * 0.16, cf * CFrame.new(0, 0, -0.62), L.gold, M.Metal)
	end
	-- battlements on a block `w` by `d` whose top is at `y`: a parapet and six merlons
	local function battlement(x: number, y: number, z: number, w: number, d: number, colour: Color3)
		b.trim("Parapet", w + 0.4, 0.45, d + 0.4, b.at(x, y + 0.22, z), L.frame)
		for k = -1, 1 do
			for _, s in { -1, 1 } do
				b.trim(
					"Merlon",
					0.62,
					0.85,
					0.55,
					b.at(x + k * (w / 2 - 0.1), y + 0.87, z + s * (d / 2 - 0.08)),
					colour
				)
			end
		end
	end

	-- THE FENCE ------------------------------------------------------------------------------------------------
	-- One straight run from (xa, za) to (xb, zb2), going round so the yard is on its +Z side in its own frame; `first`
	-- and `last` say whether its two ends get a post (a corner has one from the run before, the gate its own).
	-- The owner's fence of the era (YardKit) when it is in the kit, at era 1 from feature 3 (his rope-bound rails take
	-- the palisade's place; the plain fence before it); these parts while it loads.
	local palisade = era == 1 and f >= 3
	-- The owner's gate of the era (YardKit): era 1's thatched one is feature 1 (plain posts before it), the slime tech
	-- one is feature 18 (the steel and glass arch before it: the gate swapped is that step)
	local gateEra = if (era == 1 and f < 1) or (era == 4 and f < 18) then nil else era
	local gateHalf = if gateEra then YardKit.gateHalf(gateEra) else nil
	-- where the fence meets the gate
	local gx = gateHalf or (if era >= 3 then PX + 1.2 else PX + 0.45)
	local posts: number? = nil -- his posts' height
	local function fence(xa: number, za: number, xb: number, zb2: number, first: boolean, last: boolean, urns: boolean)
		local toGate = xb == -gx and zb2 == -ZF
		local tall = if era > 1 or palisade
			then YardKit.fence(b, era, V(xa, FLOOR, za), V(xb, FLOOR, zb2), toGate)
			else nil
		if tall then
			posts = tall
			return
		end
		local run = V(xb - xa, 0, zb2 - za)
		local len = run.Magnitude
		local dir = run.Unit
		local along = CFrame.Angles(0, math.atan2(-dir.Z, dir.X), 0)
		local function at(d: number, y: number): CFrame
			return b.at(xa + dir.X * d, FLOOR + y, za + dir.Z * d) * along
		end
		if era == 5 then
			-- a marble balustrade on a plinth, gold caps along the front
			b.box("FencePlinth", len + 0.9, 0.5, 0.9, at(len / 2, 0.25), L.stone)
			balustrade(xa, za, xb, zb2, FLOOR + 0.5, L.wall, urns, first, last)
			return
		end
		if palisade then
			-- 3 a palisade of pointed logs bound with two ropes
			local n = math.max(2, math.round(len / 1.25))
			for i = 0, n do
				if (i > 0 or first) and (i < n or last) then
					local h = 2.9 + (i % 3) * 0.3
					local colour = if i % 2 == 0 then L.fence else L.lower
					local cf = at(i * len / n, 0)
					b.cyl("PalisadeLog", 0.5, h, cf * CFrame.new(0, h / 2, 0), colour)
					-- (a four-sided point: two wedges read as a block's ridge from the side)
					b.pyramid(cf * CFrame.new(0, h, 0), 0.94, 0.94, 1, colour)
				end
			end
			for _, y in { 1, 2.2 } do
				b.trim("PalisadeRope", len, 0.2, 1.16, at(len / 2, y), ROPE)
			end
			return
		end
		local bays = math.max(1, math.round(len / ({ 3.2, 4.4, 6, 4.4 })[era]))
		local step = len / bays
		for i = 0, bays do
			local d = i * step
			local mid = d + step / 2
			if (i > 0 or first) and (i < bays or last) then
				if era == 1 then
					b.cyl("FencePost", 0.28, 2.7, at(d, 1.35), L.beam)
				elseif era == 2 then
					b.box("FencePost", 0.6, 3.3, 0.6, at(d, 1.65), L.beam)
					b.trim("FenceCap", 0.86, 0.22, 0.86, at(d, 3.4), L.board)
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
					-- two timber rails
					for _, y in { 1, 2.1 } do
						b.box("FenceRail", step + 0.1, 0.32, 0.22, at(mid, y) * CFrame.new(0, 0, -0.22), L.fence)
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
					if f >= 18 then
						-- 18 glowing green glass in the panels (plain glass, a thin glowing strip along the kerb)
						b.trim("FenceGlass", step - 0.6, 2.2, 0.1, at(mid, 1.9) * CFrame.new(0, 0, 0.14), GOO, M.Glass)
						b.trim("FenceGlow", step - 0.6, 0.16, 0.3, at(mid, 0.55), GOO, M.Neon)
					end
				end
			end
		end
	end
	local fenceFrom = #m:GetChildren()
	fence(gx, -ZF, WX, -ZF, false, true, true)
	fence(WX, -ZF, WX, ZB, false, true, false)
	fence(WX, ZB, -WX, ZB, false, true, false)
	fence(-WX, ZB, -WX, -ZF, false, true, false)
	fence(-WX, -ZF, -gx, -ZF, false, false, true)
	-- the four corners: a pier at the capital (the balustrade is low), and what the features stand on
	local cornerTop = FLOOR + (if palisade then 3.3 else ({ 2.7, 3.5, 3, 3.95, 3 })[era])
	local cornerHalf = ({ 0.3, 0.3, 0.75, 0.28, 0.6 })[era]
	for _, c in { { -1, -ZF }, { 1, -ZF }, { -1, ZB }, { 1, ZB } } do
		local x, z = c[1] * WX, c[2]
		if era == 5 and not posts then
			b.box("CornerPier", 1.2, 2.8, 1.2, b.at(x, FLOOR + 1.4, z), L.wall)
			b.trim("CornerPierCap", 1.5, 0.2, 1.5, b.at(x, FLOOR + 2.9, z), L.gold)
		end
		if f >= 8 then
			-- 8 gold ball caps on the corner posts (and the gate's, below), a lit lantern under each front one (the
			-- owner's fence posts wear their own caps)
			if not posts then
				b.ball("CornerCap", 0.55, b.at(x, cornerTop + (if era == 4 then -0.1 else 0.45), z), L.gold, bigGold)
			end
			if z < 0 then
				lamp(b.face(x, FLOOR + 2.2, z - cornerHalf, FRONT), 0.6, true)
			end
		end
	end
	Architecture.keep(m, fenceFrom, had)
	if f >= 7 then
		-- 7 flower boxes along the front fence on both sides of the gate: the era's planter from the owner's prop sheet
		-- (riveted iron, brick, crowned stone, a marble balustrade), his older trough while it loads
		for _, x in { -14.6, -8.6, 8.6, 14.6 } do
			local at = b.at(x, 0, -ZF - 1.4)
			if not painted(PLANTERS[era], at, 0.72) and not painted("FlowerBox_Trough", at, 0.9) then
				flowerBox(b.face(x, 1.2, -ZF - 0.5, FRONT), 3.4)
			end
		end
	end
	if era == 5 then
		-- clipped cone bushes in pots inside the front corners (the owner's sheet piece)
		for _, s in { -1, 1 } do
			if not painted("ConePot_Topiary", b.at(s * (WX - 1.9), FLOOR, -ZF + 1.9), 0.85) then
				b.cone(b.at(s * (WX - 1.9), FLOOR, -ZF + 1.9), 0.9, 3.4, 4, LEAF)
			end
		end
	end
	if f >= 21 then
		-- 21 gold urns of pink flowers at the fence's front corners and beside the hall's portico
		for _, p in { { -(WX + 0.4), -ZF - 2 }, { WX + 0.4, -ZF - 2 }, { -(hw + 1.3), HZ - 3 }, { hw + 1.3, HZ - 3 } } do
			local cf = b.at(p[1], if p[2] < 0 then 0 else FLOOR, p[2])
			if not painted("FlowerUrn_Gold", cf, 0.95) then
				b.cyl("FlowerUrn", 0.9, 1.6, cf * CFrame.new(0, 0.8, 0), L.gold, bigGold, false)
				b.ball("Flower", 1, cf * CFrame.new(0, 2.2, 0), BLOOMS[1])
			end
		end
	end

	-- THE GATE -------------------------------------------------------------------------------------------------
	if gateEra and YardKit.gate(b, gateEra, b.at(0, FLOOR, -ZF)) then
		-- what hangs on the owner's gate: 12 blue banners with a gold sword on its piers (the royal one has its own),
		-- 18 glowing goo beside it, 13 a raised portcullis under its arch with its spikes showing
		local px, out = YardKit.pier(gateEra)
		for _, s in { -1, 1 } do
			if f >= 12 and era < 5 then
				banner(b.face(s * px, FLOOR + 4.3, -ZF - out, FRONT), 1.25, 1.7, true)
			end
			if era == 4 then
				gooTube(s * (gx + 0.7), FLOOR, -ZF - 1, 3.2)
			end
		end
		if f >= 13 then
			local grille = if era == 3 then IRON elseif era == 4 then DARK else L.gold
			local low = YardKit.underArch(gateEra, 1.6) - 1.5
			for k = -2, 2 do
				local x = k * 0.8
				local high = YardKit.underArch(gateEra, x) - 0.1
				b.trim("Portcullis", 0.4, high - low, 0.4, b.at(x, FLOOR + (high + low) / 2, -ZF), grille, M.Metal)
				local spike = b.at(x, FLOOR + low - 0.1, -ZF) * CFrame.Angles(0, 0, math.pi / 4)
				b.trim("PortcullisSpike", 0.42, 0.42, 0.4, spike, grille, M.Metal)
			end
			for _, dy in { 0.35, 1.1 } do
				b.trim("PortcullisBar", 3.6, 0.3, 0.3, b.at(0, FLOOR + low + dy, -ZF), grille, M.Metal)
			end
		end
	elseif era <= 2 then
		local h = 5.6
		for _, s in { -1, 1 } do
			b.box("GatePad", 1.3, 0.5, 1.3, b.at(s * PX, FLOOR + 0.25, -ZF), L.stone)
			b.box("GatePost", 0.9, h - 0.5, 0.9, b.at(s * PX, FLOOR + 0.5 + (h - 0.5) / 2, -ZF), L.beam)
			if f >= 1 then
				lamp(b.face(s * PX, FLOOR + 3.6, -ZF - 0.45, FRONT), 0.8, true)
			end
			if f >= 8 then
				b.ball("GateCap", 0.55, b.at(s * PX, FLOOR + h + 0.5, -ZF), L.gold)
			else
				b.ball("GateKnob", 0.45, b.at(s * PX, FLOOR + h + 0.3, -ZF), L.beam)
			end
		end
		if f >= 1 then
			-- 1 a curved timber arch over the gate (the painted era's is blue with a gold boss), a lantern on each post
			archRing("GateArch", 0, PX, FLOOR + h - 0.4, 2.1, -ZF, 0.7, 0.6, L.beam, nil, L.board)
			for _, s in { -1, 1 } do
				b.beam(
					"GateBrace",
					0.4,
					0.4,
					V(s * PX, FLOOR + h - 2.2, -ZF),
					V(s * (PX - 1.3), FLOOR + h + 0.7, -ZF),
					L.board
				)
			end
			if era == 2 then
				b.ball("GateBoss", 0.42, b.at(0, FLOOR + h + 1.7, -ZF - 0.4), L.gold)
			end
		end
	else
		-- piers under an arch: stone, then steel and teal glass, then marble and gold; a lantern on each pier's side
		local px, h = PX + 0.3, 5
		local spring, R = FLOOR + h + 0.4, 2.6
		for _, s in { -1, 1 } do
			b.box("GatePierFoot", 2.2, 0.6, 2.2, b.at(s * px, FLOOR + 0.3, -ZF), L.stone)
			b.box(
				"GatePier",
				1.8,
				h - 0.6,
				1.8,
				b.at(s * px, FLOOR + 0.6 + (h - 0.6) / 2, -ZF),
				if era == 5 then L.wall else L.lower
			)
			b.box(
				"GatePierCap",
				2.2,
				0.4,
				2.2,
				b.at(s * px, FLOOR + h + 0.2, -ZF),
				if era == 5 then L.gold else L.frame,
				if era == 5 then bigGold else nil
			)
			lamp(b.face(s * (px + 0.9), FLOOR + 3.9, -ZF, V(s, 0, 0)), 0.65, true)
			if f >= 12 then
				-- 12 blue banners with a gold sword on the gate's two pillars
				banner(b.face(s * px, FLOOR + 4.3, -ZF - 0.9, FRONT), 1.25, 2.3, true)
			end
			if era == 4 and f >= 18 then
				-- 18 green globe lamps on the piers, glowing goo beside them
				globe(s * px, FLOOR + h + 0.4, -ZF, GOO, true)
				gooTube(s * (px + 1.25), FLOOR, -ZF - 0.6, 3.2)
			elseif era == 5 then
				globe(s * px, FLOOR + h + 0.4, -ZF, L.glass, false)
			else
				b.ball("GatePierBall", 0.55, b.at(s * px, FLOOR + h + 0.9, -ZF), L.gold, bigGold)
			end
		end
		local crown = spring + R
		if era == 3 then
			-- (proud voussoirs in two stones, a keystone)
			archRing("GateArch", 0, px, spring, R, -ZF, 1.3, 1, L.frame, nil, L.lower)
			b.trim("GateKeystone", 1, 1.4, 1.5, b.at(0, crown, -ZF), L.frame)
		elseif era == 4 then
			archRing("GateArch", 0, px + 0.45, spring, R + 0.45, -ZF, 0.6, 0.3, L.beam)
			archRing("GateArch", 0, px - 0.45, spring, R - 0.45, -ZF, 0.6, 0.3, L.beam)
			archRing("GateGlass", 0, px, spring, R, -ZF, 0.16, 0.7, if f >= 18 then GOO else L.wall, M.Glass)
			for k = 1, 7 do
				local ax, ay = arc(px - 0.45, spring, R - 0.45, k)
				local bx, by = arc(px + 0.45, spring, R + 0.45, k)
				b.rod("GateArchBar", 0.1, V(ax, ay, -ZF), V(bx, by, -ZF), L.beam)
			end
		else
			archRing("GateArch", 0, px, spring, R, -ZF, 1.2, 0.9, L.wall)
			-- (thin gold rims at the arch's two edges: one gold band over its whole back read as a gold arch)
			for _, dz in { -0.5, 0.5 } do
				archRing("GateArchGold", 0, px + 0.5, spring, R + 0.5, -ZF + dz, 0.3, 0.16, L.gold, M.Metal)
			end
			archRing("GateArchGold", 0, px - 0.5, spring, R - 0.5, -ZF, 1.3, 0.16, L.gold, M.Metal)
			b.trim("GateKeystone", 0.9, 1.3, 1.4, b.at(0, crown, -ZF), L.gold, M.Metal)
		end
		if f >= 13 then
			-- 13 a raised portcullis in the arch, its spikes showing under the stone
			local grille = if era == 3 then IRON elseif era == 4 then DARK else L.gold
			local foot = spring + 0.2
			for k = -3, 3 do
				local x = k * 0.95
				local yTop = spring + (R - 0.5) * math.sqrt(1 - (x / (px - 0.5)) ^ 2)
				b.trim("Portcullis", 0.4, yTop - foot, 0.4, b.at(x, (yTop + foot) / 2, -ZF), grille, M.Metal)
				local spike = b.at(x, foot - 0.1, -ZF) * CFrame.Angles(0, 0, math.pi / 4)
				b.trim("PortcullisSpike", 0.42, 0.42, 0.4, spike, grille, M.Metal)
			end
			for _, dy in { 0.55, 1.5 } do
				local w = (px - 0.5) * math.sqrt(1 - (dy / (R - 0.5)) ^ 2) * 2 - 0.3
				b.trim("PortcullisBar", w, 0.3, 0.3, b.at(0, spring + dy, -ZF), grille, M.Metal)
			end
		end
	end

	-- THE HALL -------------------------------------------------------------------------------------------------
	-- what is seen through the open front, against the back wall at `zBack` on the floor `y`: two weapon racks on
	-- the left, three tiers of benches with the squad's blue runner on the right, a warm light at `lightY`
	local function interior(half: number, zBack: number, y: number, lightY: number)
		local z = zBack - 0.55
		for _, x in { half * 0.3, half * 0.72 } do
			for _, k in { -1, 1 } do
				b.trim("RackPost", 0.25, 2.7, 0.3, b.at(x + k * 1.15, y + 1.35, z), BOX)
			end
			for _, h in { 0.9, 2.3 } do
				b.trim("RackRail", 2.6, 0.22, 0.34, b.at(x, y + h, z), BOX)
			end
			for k = -1, 1 do
				b.rod("Spear", 0.07, V(x + k * 0.7, y + 0.15, z - 0.25), V(x + k * 0.7, y + 3.3, z - 0.25), PLANK)
				b.trim("SpearHead", 0.22, 0.5, 0.08, b.at(x + k * 0.7, y + 3.5, z - 0.25), STEEL, M.Metal)
			end
		end
		local x0, x1 = -half + 0.3, -0.8
		local mid = (x0 + x1) / 2
		for i = 1, 3 do
			local za = zBack - 5 + i * 1.25
			local zn = if i < 3 then za + 1.25 else zBack - 0.1
			slab("Bench", x0, x1, y, y + i * 0.7, za, zn, PLANK)
			b.trim("Runner", 1.4, 0.06, zn - za, b.at(mid, y + i * 0.7 + 0.03, (za + zn) / 2), L.cloth, M.SmoothPlastic)
			b.trim("Runner", 1.4, 0.7, 0.06, b.at(mid, y + (i - 0.5) * 0.7, za - 0.03), L.cloth, M.SmoothPlastic)
		end
		b.rod("LightCord", 0.05, V(0, lightY + 0.9, zBack - depth / 2), V(0, lightY, zBack - depth / 2), IRON)
		light(b.ball("HallLight", 0.32, b.at(0, lightY, zBack - depth / 2), L.glass, M.Neon), L.glass, 18, 0.6)
	end

	local vault = era == 5 and f >= 23
	local shieldFace: CFrame -- where the shield hangs over the open front
	local hallFloor = FLOORS[era]

	if bodied then
		worn(bodyName)
		if era == 1 then
			worn(if f < 2 then "TrainingTruss1" else "TrainingGable1")
			if f >= 4 then
				worn("TrainingLookout1")
			end
			if f >= 5 then
				worn("TrainingCabin1")
			end
		elseif era == 2 then
			worn(if f >= 10 then "TrainingTall2" else "TrainingTower2")
		elseif era == 3 then
			worn(if f >= 14 then "TrainingStorey3" else "TrainingRoof3")
			worn(if f >= 15 then "TrainingTall3" else "TrainingTower3")
		elseif era == 4 then
			worn(if f >= 20 then "TrainingTall4" else "TrainingTower4")
		else
			worn(if vault then "TrainingVault5" else "TrainingRoof5")
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
		-- (under a body it ends inside the posts: a longer one stands out of the roof)
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
			b.box("Collar", if bodied then hw * 0.6 else hw, 0.4, 0.4, b.at(0, top + rise * 0.5, HZ + 0.3), L.beam)
		else
			-- 2 the gable closed with boards (it carries the shield, below), lanterns on the two front posts
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
					V(s * hw * 0.72, top + 0.3, HZ - 0.1),
					V(s * hw * 0.4, top + rise * 0.56, HZ - 0.1),
					L.beam
				)
				-- (a post where the strut lands, so the gable is framed bays and not one board)
				local ph = rise * 0.6 - 0.5
				b.trim(
					"GablePost",
					0.3,
					ph,
					0.25,
					b.face(s * hw * 0.4, top + 0.4 + ph / 2, HZ, FRONT) * CFrame.new(0, 0, -0.1),
					L.beam
				)
				lamp(b.face(s * (hw - 0.45), FLOOR + 3.9, HZ, FRONT), 1, true)
			end
		end
		shieldFace = b.face(0, top + rise * 0.46, HZ - 0.3, FRONT)
		interior(hw - T, zb - T, FLOOR + 0.2, top - 1.2)
	elseif era == 3 then
		-- A STONE HALL with one great arch between two shoulders; 14 a half-timbered storey under a higher roof
		local ow, spring, R = hw - 2.9, FLOOR + 3.4, 3.2
		slab("HallFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, hallFloor)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR, top, HZ, zb, L.lower)
			slab("FrontWall", s * ow, s * hw, FLOOR, top, HZ, HZ + 0.8, L.lower)
		end
		slab("BackWall", -hw, hw, FLOOR, top, zb - T, zb, L.lower)
		if not bodied then -- (the body's plinth stops at its back door)
			slab("Plinth", -hw - 0.2, hw + 0.2, FLOOR, FLOOR + 0.7, zb - 0.1, zb + 0.2, L.stone)
		end
		archWall("FrontWall", 0, ow, spring, R, top, HZ + 0.4, 0.8, L.lower)
		-- (proud voussoirs in two stones, a keystone)
		archRing("ArchStone", 0, ow + 0.45, spring, R + 0.45, HZ + 0.15, 1.3, 0.9, L.frame, nil, L.stone)
		b.trim("Keystone", 1.1, 1.3, 1.5, b.at(0, spring + R + 0.35, HZ + 0.15), L.frame)
		b.trim("StringCourse", hw * 2 - 3, 0.4, 0.5, b.at(0, top - 0.2, HZ - 0.1), L.frame)
		local y2 = top
		if f >= 14 then
			local st = 3.4
			y2 = top + st
			slab("StoreyBeam", -hw - 0.1, hw + 0.1, top, top + 0.4, HZ + 0.1, zb + 0.1, L.beam)
			slab("UpperWall", -hw, hw, top + 0.4, y2, HZ + 0.2, HZ + 0.7, L.wall)
			slab("UpperWall", -hw, hw, top + 0.4, y2, zb - 0.5, zb, L.wall)
			b.timber(b.face(0, top + 0.4 + (st - 0.4) / 2, HZ + 0.2, FRONT), (hw - 1.5) * 2, st - 0.4, L.beam)
			for _, s in { -1, 1 } do
				slab("UpperWall", s * (hw - 0.5), s * hw, top + 0.4, y2, HZ + 0.7, zb - 0.5, L.wall)
				b.timber(b.face(s * hw, top + 0.4 + (st - 0.4) / 2, (HZ + zb) / 2, V(s, 0, 0)), depth, st - 0.4, L.beam)
				b.window(b.face(s * 3.3, top + 2, HZ + 0.2, FRONT), 1.5, 1.7, L.frame, L.glass, { glow = true })
			end
		end
		-- the shoulders: a stone pier at each front corner, taller than the eaves
		for _, s in { -1, 1 } do
			local x, ph = s * (hw - 0.5), y2 + 0.5
			slab("Shoulder", x - 1, x + 1, FLOOR, ph, HZ - 1.5, HZ - 0.3, L.lower)
			b.trim("ShoulderFoot", 2.4, 0.8, 1.6, b.at(x, FLOOR + 0.4, HZ - 0.9), L.stone)
			b.trim("ShoulderCap", 2.4, 0.3, 1.6, b.at(x, ph + 0.15, HZ - 0.9), L.frame)
			lamp(b.face(x, FLOOR + 3.9, HZ - 1.5, FRONT), 0.8, true)
			if f >= 11 then
				-- 11 battlements on the hall's stone shoulders
				battlement(x, ph + 0.3, HZ - 0.9, 2, 1.2, L.lower)
			end
		end
		frontGable(0, hw, y2, HZ + 0.2, zb, rise, 0.5, L.wall)
		b.trim(
			"GableRail",
			hw * 2 - 3.4,
			0.4,
			0.25,
			b.face(0, y2 + 0.2, HZ + 0.2, FRONT) * CFrame.new(0, 0, -0.1),
			L.beam
		)
		for _, s in { -1, 1 } do
			b.beam(
				"GableStrut",
				0.3,
				0.3,
				V(s * hw * 0.7, y2 + 0.3, HZ + 0.1),
				V(s * hw * 0.38, y2 + rise * 0.56, HZ + 0.1),
				L.beam
			)
			local ph = rise * 0.62 - 0.5
			b.trim(
				"GablePost",
				0.3,
				ph,
				0.25,
				b.face(s * hw * 0.38, y2 + 0.4 + ph / 2, HZ + 0.2, FRONT) * CFrame.new(0, 0, -0.1),
				L.beam
			)
		end
		shieldFace = b.face(0, y2 + rise * 0.46, HZ + 0.1, FRONT)
		interior(hw - T, zb - T, FLOOR + 0.2, top - 1.4)
	elseif era == 4 then
		-- A STEEL AND TEAL GLASS VAULT on steel piers, open to the front under a lunette of steel struts
		slab("HallFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, hallFloor)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR, FLOOR + 2.4, HZ, zb, L.lower)
			slab("SideGlass", s * (hw - 0.4), s * (hw - 0.2), FLOOR + 2.4, top, HZ, zb, L.wall)
			for k = 0, 3 do
				local z = HZ + 0.3 + k * (depth - 0.6) / 3
				b.trim(
					"SidePost",
					0.5,
					wallH - 2.4,
					0.5,
					b.at(s * (hw - 0.3), FLOOR + 2.4 + (wallH - 2.4) / 2, z),
					L.beam
				)
			end
			b.trim("SideRail", 0.5, 0.5, depth, b.at(s * (hw - 0.3), top - 0.25, zc), L.beam)
			b.trim("SideCap", 0.9, 0.3, depth, b.at(s * (hw - 0.3), FLOOR + 2.55, zc), L.frame)
			-- the front piers, riveted, a lantern on each
			local x = s * (hw - 0.8)
			slab("FrontPier", x - 1.1, x + 1.1, FLOOR, top + 0.6, HZ - 0.5, HZ + 0.8, L.lower)
			b.trim("FrontPierCap", 2.6, 0.4, 1.7, b.at(x, top + 0.8, HZ + 0.15), L.frame)
			b.trim("FrontPierFoot", 2.6, 0.7, 1.7, b.at(x, FLOOR + 0.35, HZ + 0.15), L.stone)
			for k = 0, 2 do
				for _, e in { -0.8, 0.8 } do
					b.ball("Rivet", 0.16, b.at(x + e, FLOOR + 1.6 + k * 2.2, HZ - 0.5), L.gold, M.Metal)
				end
			end
			lamp(b.face(x, FLOOR + 4.3, HZ - 0.5, FRONT), 0.9, true)
			if f >= 11 then
				battlement(x, top + 1, HZ + 0.15, 2.2, 1.3, L.lower)
			end
		end
		slab("BackWall", -hw, hw, FLOOR, FLOOR + 2.4, zb - T, zb, L.lower)
		slab("BackGlass", -hw, hw, FLOOR + 2.4, top, zb - 0.3, zb - 0.1, L.wall)
		fan(0, hw - 0.3, top, rise - 0.3, zb - 0.2, L.wall)
		archRing("VaultGlass", 0, hw, top, rise, zc, depth, 0.18, L.roof)
		for k = 0, 3 do
			archRing("VaultRib", 0, hw + 0.1, top, rise + 0.1, HZ + 0.2 + k * (depth - 0.4) / 3, 0.45, 0.5, L.beam)
		end
		for k = 1, 7 do
			local ax, ay = arc(hw + 0.2, top, rise + 0.2, k)
			b.rod("Purlin", 0.2, V(ax, ay, HZ), V(ax, ay, zb), L.beam)
		end
		-- the front: a heavy steel ring in two tones, a transom, the lunette's struts; 19 its fan of teal glass
		archRing("FrontArch", 0, hw + 0.2, top, rise + 0.2, HZ - 0.1, 1.1, 0.9, L.lower, nil, L.frame)
		b.trim("Transom", (hw - 1.9) * 2, 0.5, 0.6, b.at(0, top + 0.1, HZ + 0.1), L.beam)
		for k = 1, 7 do
			local ax, ay = arc(hw - 0.5, top + 0.3, rise - 0.5, k)
			b.beam("LunetteBar", 0.3, 0.26, V(0, top + 0.3, HZ), V(ax, ay, HZ), L.beam)
		end
		-- (a second steel ring half way out: the lunette is panes in a frame, not one pale sheet)
		archRing("LunetteRing", 0, (hw - 0.5) * 0.64, top + 0.3, (rise - 0.5) * 0.64, HZ, 0.3, 0.26, L.beam)
		if f >= 19 then
			fan(0, hw - 0.5, top + 0.3, rise - 0.5, HZ + 0.15, L.wall)
		end
		shieldFace = b.face(0, top + rise * 0.47, HZ - 0.15, FRONT)
		interior(hw - T, zb - T, FLOOR + 0.2, top - 0.6)
	else
		-- A MARBLE HALL: four columns under an entablature and a pediment, a portico's depth in front of the wall,
		-- an arcade wing each side
		local pz, ez = HZ - 1.2, HZ - 2
		slab("HallFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.25, ez, zb + 0.2, hallFloor)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR + 0.25, top, HZ, zb, L.wall)
			slab("FrontWall", s * (hw - 1.7), s * hw, FLOOR + 0.25, top - 1.3, HZ, HZ + T, L.wall)
			b.trim("SideCornice", 0.5, 0.35, depth + 0.4, b.at(s * (hw + 0.1), top - 0.2, zc), L.gold)
			-- two arched windows high in each side wall, over the wing's roof, so the flank is not a blank slab
			for _, z in { zc - depth * 0.22, zc + depth * 0.22 } do
				b.window(
					b.face(s * hw, top - 1.95, z, V(s, 0, 0)),
					1,
					1.7,
					L.frame,
					L.glass,
					{ arch = true, glow = true }
				)
			end
			lamp(b.face(s * (hw - 0.85), FLOOR + 4.6, HZ, FRONT), 0.9, true)
			-- the wing: one arch under a flat roof with its balustrade
			local ww, wt = 3.2, FLOOR + 6.4
			local cx = s * (hw + ww / 2)
			local half, spring, R = 1, FLOOR + 3.3, 1.2
			slab("WingFloor", s * hw, s * (hw + ww), FLOOR, FLOOR + 0.25, HZ - 0.4, zb - 1.5, hallFloor)
			slab("WingBack", s * hw, s * (hw + ww), FLOOR + 0.25, wt, zb - 2.1, zb - 1.5, L.wall)
			slab("WingEnd", s * (hw + ww - T), s * (hw + ww), FLOOR + 0.25, wt, HZ, zb - 2.1, L.wall)
			-- the wing's end wall is the hall's flank: three panels of warmer stone between marble pilasters, on a
			-- plinth and under a gold cornice
			local xe, span, zm = s * (hw + ww), depth - 2.1, (HZ + zb - 2.1) / 2
			local bay = (span - 0.6) / 3
			b.trim("WingPlinth", 0.3, 0.8, span + 0.2, b.at(xe + s * 0.1, FLOOR + 0.65, zm), L.stone)
			b.trim("WingEndCornice", 0.4, 0.3, span + 0.4, b.at(xe + s * 0.15, wt - 0.2, zm), L.gold)
			for k = 0, 3 do
				b.trim("WingPilaster", 0.24, 5, 0.6, b.at(xe + s * 0.1, FLOOR + 3.55, HZ + 0.3 + k * bay), L.beam)
			end
			for k = 0, 2 do
				local z = HZ + 0.3 + (k + 0.5) * bay
				b.trim("WingPanel", 0.12, 3.9, bay - 1.1, b.at(xe + s * 0.04, FLOOR + 3.55, z), PANEL)
				b.trim("WingPanelCap", 0.16, 0.16, bay - 0.9, b.at(xe + s * 0.05, FLOOR + 5.6, z), L.gold)
			end
			slab("WingFront", cx - ww / 2, cx - half, FLOOR + 0.25, wt, HZ, HZ + T, L.wall)
			slab("WingFront", cx + half, cx + ww / 2, FLOOR + 0.25, wt, HZ, HZ + T, L.wall)
			archWall("WingFront", cx, half, spring, R, wt, HZ + T / 2, T, L.wall)
			archRing("WingArch", cx, half + 0.15, spring, R + 0.15, HZ - 0.05, 0.4, 0.3, L.gold, M.Metal)
			slab("WingRoof", s * hw, s * (hw + ww + 0.2), wt, wt + 0.3, HZ - 0.3, zb - 1.4, L.stone)
			b.trim("WingCornice", ww + 0.5, 0.3, 0.4, b.at(cx, wt + 0.15, HZ - 0.35), L.gold)
			balustrade(cx - ww / 2 + 0.2, HZ, cx + ww / 2 - 0.2, HZ, wt + 0.3, L.wall, true, true, true)
		end
		slab("BackWall", -hw, hw, FLOOR + 0.25, top, zb - T, zb, L.wall)
		slab("Entablature", -hw - 0.2, hw + 0.2, top - 1.3, top, ez, HZ + T, L.wall)
		b.trim("Frieze", hw * 2 + 0.5, 0.35, 0.2, b.at(0, top - 1.1, ez - 0.05), L.gold)
		b.trim("Cornice", hw * 2 + 1, 0.3, 0.5, b.at(0, top - 0.15, ez - 0.2), L.gold)
		for _, x in { -(hw - 0.9), -3.4, 3.4, hw - 0.9 } do
			column(x, pz, FLOOR + 0.25, top - 1.3, 0.75)
		end
		-- 16 at the capital: a lit gold lantern hangs in each bay of the portico (the steel hall's pipes do not
		-- belong on marble)
		for _, x in { -(hw + 2.5) / 2, 0, (hw + 2.5) / 2 } do
			local y = top - 1.3
			b.rod("LanternChain", 0.07, V(x, y, pz), V(x, y - 0.8, pz), L.gold, M.Metal)
			b.trim("LanternCap", 0.9, 0.2, 0.9, b.at(x, y - 0.9, pz), L.gold, M.Metal)
			b.trim("HallLantern", 0.65, 0.85, 0.65, b.at(x, y - 1.42, pz), L.glass, M.Neon)
			b.ball("LanternDrop", 0.18, b.at(x, y - 1.95, pz), L.gold, M.Metal)
		end
		if vault then
			-- 23 a vault in the era's blue tiles (its end fans stay glass) with gold ribs behind a marble balustrade with gold finials; the pediment
			-- keeps its own short roof
			local hv, R = hw - 1.5, rise + 1.7
			local za = HZ + 1.4
			frontGable(0, hw + 0.2, top, ez, za, rise, 0.6, L.wall)
			slab("RoofDeck", -hw, hw, top, top + 0.25, za, zb, L.stone)
			archRing("VaultGlass", 0, hv, top + 0.25, R, (za + zb) / 2 + 0.2, zb - za - 0.6, 0.18, L.roof)
			for k = 0, 3 do
				local z = za + 0.5 + k * (zb - za - 0.8) / 3
				archRing("VaultRib", 0, hv + 0.1, top + 0.25, R + 0.1, z, 0.4, 0.4, L.gold, M.Metal)
			end
			fan(0, hv - 0.2, top + 0.25, R - 0.2, za + 0.6, DOME, M.Glass)
			fan(0, hv - 0.2, top + 0.25, R - 0.2, zb - 0.3, DOME, M.Glass)
			for _, s in { -1, 1 } do
				balustrade(s * (hw - 0.35), za + 0.3, s * (hw - 0.35), zb - 0.3, top + 0.25, L.wall, true, true, true)
			end
		else
			frontGable(0, hw + 0.2, top, ez, zb, rise, 0.6, L.wall)
		end
		for _, s in { -1, 1 } do
			b.ball("Acroterion", 0.45, b.at(s * (hw + 0.4), top + 0.5, ez - 0.2), L.gold, M.Metal)
		end
		b.ball("Acroterion", 0.5, b.at(0, top + rise + 0.7, ez - 0.4), L.gold, M.Metal)
		shieldFace = b.face(0, top + 1.5, ez - 0.3, FRONT)
		interior(hw - T, zb - T, FLOOR + 0.25, top - 2)
	end
	shell(false)

	-- THE SHIELD over the open front: 2 it comes with the closed gable, and stays
	if f >= 2 then
		local sr = ({ 2.2, 2.4, 2, 2.8, 2 })[era]
		-- the capital's disc is the squad's blue: steel blades do not read on a gold one
		local disc = ({ PLANK, L.cloth, C(126, 130, 140), C(108, 116, 128), L.cloth })[era]
		local discMat = ({ M.WoodPlanks, M.SmoothPlastic, M.Metal, M.Metal, M.SmoothPlastic })[era]
		local rim = ({ BOX, L.gold, IRON, L.board, L.gold })[era]
		if era == 4 then
			if f >= 19 then
				-- 19 a great riveted steel ring with a glowing green rim round the shield
				b.disc("ShieldRing", sr * 1.42, 0.3, shieldFace, DARK, M.Metal)
				b.disc("ShieldGlow", sr * 1.22, 0.36, shieldFace, GOO, M.Neon)
				for k = 0, 7 do
					local at = shieldFace * CFrame.Angles(0, 0, k * math.pi / 4) * CFrame.new(0, sr * 1.32, -0.2)
					b.ball("Rivet", 0.2, at, L.gold, M.Metal)
				end
			else
				-- (a dark plate behind it: steel on open struts does not read)
				b.disc("ShieldPlate", sr * 1.12, 0.3, shieldFace, DARK, M.Metal)
			end
		elseif era == 5 then
			b.disc("ShieldRing", sr * 1.14, 0.2, shieldFace, L.gold, M.Metal)
			if f >= 22 then
				-- 22 gold laurels round the shield on the pediment (the owner's Meshy wreath, as wide as the shield
				-- and more)
				if not painted("Laurel_Gold", shieldFace * CFrame.new(0, 0.2, 0.2), 1.08, 0.7) then
					for _, s in { -1, 1 } do
						for i = 0, 3 do
							local leaf = shieldFace
								* CFrame.Angles(0, 0, s * math.rad(50 + i * 28))
								* CFrame.new(0, -sr * 1.35, -0.1)
							b.trim("Laurel", 0.6, 1.2, 0.2, leaf, L.gold, M.Metal)
						end
					end
				end
			end
		end
		local metal = if era >= 3 then M.Metal else nil
		shield(shieldFace * CFrame.new(0, 0, if era >= 4 then -0.2 else 0), sr, disc, discMat, rim, metal)
	end

	-- THE TOWER at the hall's right end (-x) ---------------------------------------------------------------------
	local tr = ({ 1.9, 2.3, 2.7, 2.7, 2.8 })[era] -- half its width
	local tx = -((if era == 5 then hw + 3.2 else hw) + tr + ({ 1.4, 1.2, 0.6, 0.5, 0.3 })[era])
	local tz = HZ + 3.3
	local capTop: number? -- the top of its cap, where the banner's mast stands
	local function towerWindow(y: number, side: boolean)
		local face = if side then b.face(tx + tr + 0.03, y, tz, SIDE) else b.face(tx, y, tz - tr - 0.03, FRONT)
		b.window(face, 1.1, 1.6, L.frame, L.glass, { arch = true, glow = true })
	end
	-- 9 a railed gallery round the tower, its floor at `y`
	local function gallery(y: number, round: boolean, floorColour: Color3, rail: Color3, railMat: Enum.Material?)
		local g = tr + 0.9
		local pts: { Vector3 } = {}
		if round then
			b.cyl("Gallery", g, 0.35, b.at(tx, y, tz), floorColour, nil, false)
			for k = 0, 7 do
				local a = k * math.pi / 4
				table.insert(pts, V(tx + (g - 0.15) * math.cos(a), y, tz + (g - 0.15) * math.sin(a)))
			end
		else
			b.trim("Gallery", g * 2, 0.35, g * 2, b.at(tx, y, tz), floorColour)
			for _, c in CORNERS do
				table.insert(pts, V(tx + c[1] * (g - 0.15), y, tz + c[2] * (g - 0.15)))
			end
		end
		for i, p in pts do
			local q = pts[i % #pts + 1]
			b.trim("GalleryPost", 0.24, 1.2, 0.24, b.at(p.X, y + 0.75, p.Z), rail, railMat)
			for _, up in { 0.7, 1.3 } do
				b.beam("GalleryRail", 0.2, 0.2, p + V(0, up, 0), q + V(0, up, 0), rail, railMat)
			end
		end
	end
	local bannerTop: number? -- 6 where the long banner hangs from on the tower's front

	shell(true)
	if era == 1 then
		if f >= 4 then
			-- 4 a lookout stand: four braced log legs, a railed platform as high as the eaves, a ladder
			local P = top
			local reach = if f >= 5 then P + 3.4 else P
			for i, a in CORNERS do
				local c = CORNERS[i % 4 + 1]
				local ax, az, cx, cz = tx + a[1] * tr, tz + a[2] * tr, tx + c[1] * tr, tz + c[2] * tr
				b.rod("TowerLeg", 0.3, V(ax, FLOOR, az), V(ax, reach, az), L.beam)
				b.beam("TowerBrace", 0.3, 0.3, V(ax, FLOOR + 0.5, az), V(cx, P - 0.6, cz), L.board)
				b.beam("TowerBrace", 0.3, 0.3, V(cx, FLOOR + 0.5, cz), V(ax, P - 0.6, az), L.board)
				local e = tr + 0.45
				local p, q = V(tx + a[1] * e, P, tz + a[2] * e), V(tx + c[1] * e, P, tz + c[2] * e)
				b.trim("PlatformPost", 0.3, 1.5, 0.3, b.at(p.X, P + 0.95, p.Z), L.beam)
				b.beam("PlatformRail", 0.25, 0.25, p + V(0, 1.6, 0), q + V(0, 1.6, 0), L.beam)
				b.beam("PlatformRail", 0.2, 0.2, p + V(0, 0.9, 0), q + V(0, 0.9, 0), L.board)
			end
			b.box("Platform", tr * 2 + 1.3, 0.4, tr * 2 + 1.3, b.at(tx, P, tz), PLANK)
			for _, k in { -0.45, 0.45 } do
				b.rod("Ladder", 0.1, V(tx + k, FLOOR, tz - tr - 2), V(tx + k, P + 0.2, tz - tr - 0.7), L.board)
			end
			for i = 1, 6 do
				local t = i / 7
				local y, z = FLOOR + t * (P + 0.2 - FLOOR), tz - tr - 2 + t * 1.3
				b.rod("LadderRung", 0.08, V(tx - 0.45, y, z), V(tx + 0.45, y, z), L.board)
			end
			if f >= 5 then
				-- 5 the lookout becomes a tower: a cabin with lit windows under a thatch cap, well above the hall
				local P2 = P + 3.4
				for i, a in CORNERS do
					local c = CORNERS[i % 4 + 1]
					local ax, az, cx, cz = tx + a[1] * tr, tz + a[2] * tr, tx + c[1] * tr, tz + c[2] * tr
					b.beam("TowerBrace", 0.28, 0.28, V(ax, P + 1.9, az), V(cx, P2 - 0.3, cz), L.board)
					b.trim("CabinPost", 0.4, 3, 0.4, b.at(ax, P2 + 1.7, az), L.beam)
				end
				b.box("CabinFloor", tr * 2 + 1, 0.4, tr * 2 + 1, b.at(tx, P2, tz), PLANK)
				slab("Cabin", tx - tr + 0.1, tx + tr - 0.1, P2 + 0.2, P2 + 3.2, tz - tr + 0.1, tz + tr - 0.1, L.wall)
				b.window(b.face(tx, P2 + 1.8, tz - tr + 0.08, FRONT), 1.5, 1.5, L.frame, L.glass, { glow = true })
				b.window(b.face(tx + tr - 0.08, P2 + 1.8, tz, SIDE), 1.5, 1.5, L.frame, L.glass, { glow = true })
				local cap = b.at(tx, P2 + 3.2, tz)
				local s = tr + 1.3
				if not piece("ThatchCap_Tower", cap, s, 2, s, Color3.new(1, 1, 1), M.SmoothPlastic) then
					b.cone(cap, s, 3.5, 4, L.roof)
				end
				capTop = P2 + 3.2 + 3.5
			end
		end
	elseif era == 2 then
		-- a watchtower boarded in cream between blue beams; 10 a storey taller under a tall cone of red tiles
		local H = FLOOR + (if f >= 10 then 14.2 else 11.2)
		local yG = H - 3.2
		slab("TowerFoot", tx - tr - 0.25, tx + tr + 0.25, FLOOR, FLOOR + 0.9, tz - tr - 0.25, tz + tr + 0.25, L.stone)
		slab("Tower", tx - tr, tx + tr, FLOOR + 0.9, H, tz - tr, tz + tr, L.wall)
		for _, c in CORNERS do
			b.trim(
				"TowerPost",
				0.5,
				H - FLOOR - 0.9,
				0.5,
				b.at(tx + c[1] * tr, (FLOOR + 0.9 + H) / 2, tz + c[2] * tr),
				L.beam
			)
		end
		for y = FLOOR + 3.6, yG - 1, 3.3 do
			b.trim("TowerBand", tr * 2 + 0.5, 0.4, tr * 2 + 0.5, b.at(tx, y, tz), L.beam)
		end
		b.trim("TowerEave", tr * 2 + 0.9, 0.4, tr * 2 + 0.9, b.at(tx, H - 0.2, tz), L.board)
		-- (a cross brace in the foot bay of the two faces the yard sees: framed, not a painted block)
		local e, ya, yb = tr - 0.3, FLOOR + 1.1, FLOOR + 3.3
		for _, s in { -1, 1 } do
			local zf, xs = tz - tr - 0.05, tx + tr + 0.05
			b.beam("TowerBrace", 0.3, 0.3, V(tx - s * e, ya, zf), V(tx + s * e, yb, zf), L.beam)
			b.beam("TowerBrace", 0.3, 0.3, V(xs, ya, tz - s * e), V(xs, yb, tz + s * e), L.beam)
		end
		towerWindow(FLOOR + 5.4, true)
		towerWindow(yG + 1.6, false)
		if f >= 9 then
			-- 9 a railed blue gallery round the tower under its cap, with lit windows
			gallery(yG, false, L.board, L.beam, nil)
			towerWindow(yG + 1.6, true)
		end
		if f >= 10 then
			coneRoof(b.at(tx, H, tz), tr * 1.5, 5, L.roof, true)
			capTop = H + 5
		else
			b.pyramid(b.at(tx, H, tz), tr * 2 + 1.4, tr * 2 + 1.4, 2.2, L.roof)
			capTop = H + 2.2
		end
		bannerTop = yG - 0.5
	elseif era == 3 then
		-- a round stone keep under a blue slate cone; 15 a floor taller with a crown of battlements on corbels
		local H = FLOOR + (if f >= 15 then 16.2 else 12.6)
		b.cyl("TowerFoot", tr + 0.3, 1, b.at(tx, FLOOR + 0.5, tz), L.stone)
		b.cyl("Tower", tr, H - FLOOR - 1, b.at(tx, (FLOOR + 1 + H) / 2, tz), L.lower)
		for y = FLOOR + 5, H - 2, 4 do
			b.cyl("TowerCourse", tr + 0.12, 0.35, b.at(tx, y, tz), L.frame, nil, false)
		end
		for y = FLOOR + 3.2, H - 1.5, 3.7 do
			towerWindow(y, true)
		end
		towerWindow(H - 2, false)
		b.cyl("TowerNeck", tr - 0.5, 1.7, b.at(tx, H + 0.85, tz), L.lower)
		if f >= 15 then
			for k = 0, 11 do
				local out = b.at(tx, H - 1.1, tz) * CFrame.Angles(0, k * math.pi / 6, 0)
				b.trim("Corbel", 0.5, 0.7, 0.7, out * CFrame.new(0, 0, -(tr + 0.3)), L.frame)
			end
			b.cyl("TowerCrown", tr + 0.8, 1.1, b.at(tx, H - 0.2, tz), L.lower)
			for k = 0, 9 do
				local out = b.at(tx, H + 0.8, tz) * CFrame.Angles(0, k * math.pi / 5, 0)
				b.trim("TowerMerlon", 0.95, 0.9, 0.6, out * CFrame.new(0, 0, -(tr + 0.48)), L.lower)
			end
			coneRoof(b.at(tx, H + 1.7, tz), tr + 0.1, 4.8, L.roof, true)
			capTop = H + 1.7 + 4.8
		else
			gallery(H - 0.2, true, L.frame, L.beam, nil)
			coneRoof(b.at(tx, H + 1.7, tz), tr + 0.2, 3.8, L.roof, true)
			capTop = H + 1.7 + 3.8
		end
		bannerTop = H - 4
	elseif era == 4 then
		-- a riveted steel tower; 20 its goo core: a glowing green tank between steel ribs under a glass-and-iron dome
		local H = FLOOR + 16.2
		local y0 = FLOOR + 9.6
		local solid = if f >= 20 then y0 else H
		b.cyl("TowerFoot", tr + 0.3, 1, b.at(tx, FLOOR + 0.5, tz), L.stone)
		b.cyl("Tower", tr, solid - FLOOR - 1, b.at(tx, (FLOOR + 1 + solid) / 2, tz), L.lower)
		for y = FLOOR + 3.2, solid, 3.2 do
			b.cyl("TowerBand", tr + 0.14, 0.4, b.at(tx, y, tz), L.beam, nil, false)
			for k = 0, 7 do
				local out = b.at(tx, y, tz) * CFrame.Angles(0, k * math.pi / 4 + 0.3, 0)
				b.ball("Rivet", 0.16, out * CFrame.new(0, 0, -(tr + 0.2)), L.gold, M.Metal)
			end
		end
		towerWindow(FLOOR + 4.8, true)
		if f >= 20 then
			-- (plain goo with a thin glowing slice: a big Neon volume burns out)
			b.cyl("GooTank", tr - 0.4, H - 1 - y0, b.at(tx, (y0 + H - 1) / 2, tz), GOO, M.Glass)
			b.cyl("GooCore", 0.55, H - 1.4 - y0, b.at(tx, (y0 + H - 1) / 2, tz), GOO, M.Neon, false)
			light(b.cyl("GooGlow", tr - 0.55, 0.3, b.at(tx, y0 + 1.4, tz), GOO, M.Neon, false), GOO, 22, 1)
			for k = 0, 5 do
				local out = b.at(tx, (y0 + H - 1) / 2, tz) * CFrame.Angles(0, k * math.pi / 3 + 0.5, 0)
				b.trim("TowerRib", 0.5, H - 1 - y0, 0.5, out * CFrame.new(0, 0, -(tr - 0.15)), L.beam)
			end
			-- (a steel hoop round the tank's middle: two lit sections, not one green slab)
			b.cyl("TowerHoop", tr - 0.25, 0.45, b.at(tx, (y0 + H - 1) / 2, tz), L.beam, nil, false)
			b.cyl("TowerRing", tr + 0.1, 1, b.at(tx, H - 0.5, tz), L.lower)
		else
			towerWindow(FLOOR + 12.6, false)
			towerWindow(FLOOR + 12.6, true)
		end
		gallery(H, true, L.frame, L.beam, M.Metal)
		local cap = b.at(tx, H + 0.15, tz)
		if f >= 20 then
			local r = tr - 0.1
			if piece("GlassDome_Frame", cap, r, r, r, L.beam) then
				piece("GlassDome_Glass", cap, r, r, r, GOO, M.Glass)
				piece("GlassDome_Finial", cap * CFrame.new(0, 0.99 * r, 0), r, r, r, L.gold)
			else
				b.ball("TowerCap", r, cap, L.beam)
			end
			capTop = H + 0.15 + 1.36 * r
		else
			b.cyl("TowerCapRing", tr - 0.5, 0.4, cap * CFrame.new(0, 0.2, 0), L.beam, nil, false)
			b.ball("TowerCap", tr - 0.7, cap * CFrame.new(0, 0.3, 0), L.roof)
			capTop = H + tr - 0.3
		end
		bannerTop = y0 - 0.5
	else
		-- a marble tower with gold bands; 24 a gallery of marble columns round its top, 25 the great dome on it
		local H = FLOOR + 17
		b.cyl("TowerFoot", tr + 0.3, 1, b.at(tx, FLOOR + 0.5, tz), L.stone)
		b.cyl("Tower", tr, H - FLOOR - 1, b.at(tx, (FLOOR + 1 + H) / 2, tz), L.wall)
		for _, y in { FLOOR + 1.2, FLOOR + 6.4, FLOOR + 12, H - 0.5 } do
			b.cyl("TowerBand", tr + 0.13, 0.4, b.at(tx, y, tz), L.gold, M.Metal, false)
		end
		for _, y in { FLOOR + 3.8, FLOOR + 9.2, FLOOR + 14.4 } do
			towerWindow(y, true)
		end
		towerWindow(FLOOR + 14.4, false)
		gallery(H, true, L.wall, L.gold, M.Metal)
		local base = H + 0.15
		if f >= 24 then
			b.cyl("BelvedereCore", tr - 1.3, 3.7, b.at(tx, H + 1.9, tz), L.wall)
			for k = 0, 7 do
				local a = k * math.pi / 4 + math.pi / 8
				column(tx + (tr - 0.45) * math.cos(a), tz + (tr - 0.45) * math.sin(a), H + 0.15, H + 3.7, 0.3)
			end
			b.window(b.face(tx, H + 1.9, tz - tr + 1.27, FRONT), 1, 1.8, L.frame, L.glass, { arch = true, glow = true })
			b.cyl("BelvedereRing", tr + 0.1, 0.6, b.at(tx, H + 4, tz), L.wall)
			b.cyl("BelvedereGold", tr + 0.22, 0.2, b.at(tx, H + 4.4, tz), L.gold, M.Metal, false)
			base = H + 4.5
		end
		if f >= 25 then
			local r = tr + 0.1
			dome(b.at(tx, base, tz), r)
			capTop = base + 1.9 * r
		else
			coneRoof(b.at(tx, base, tz), tr + 0.3, 2.8, L.roof, true)
			capTop = base + 2.8
		end
		bannerTop = FLOOR + 12.6
	end
	shell(false)
	if f >= 6 and bannerTop then
		-- 6 a long blue banner with the gold stripe down the tower's front
		banner(b.face(tx, bannerTop, tz - tr - 0.05, FRONT), 1.7, 4.6, false)
	end
	if capTop then
		-- the squad's banner over all: royal blue with its gold stripe
		local y = capTop + 3.2
		b.rod("FlagMast", 0.12, V(tx, capTop - 0.5, tz), V(tx, y, tz), if era >= 4 then L.gold else L.board)
		b.ball("FlagKnob", 0.25, b.at(tx, y + 0.2, tz), L.gold, bigGold)
		b.trim("Flag", 2.9, 1.7, 0.1, b.at(tx - 1.55, y - 0.95, tz), L.cloth, M.SmoothPlastic)
		b.trim("FlagStripe", 2.9, 0.42, 0.12, b.at(tx - 1.55, y - 0.95, tz), L.gold)
	end

	if f >= 16 and era == 4 then
		-- 16 copper pipes from the tower's top up over the hall's vault, and one down to a valve at its foot (the
		-- capital hangs lanterns in its portico in their place)
		local r, y = 0.4, FLOOR + 15.7
		for i, x in { -hw * 0.4, hw * 0.12 } do
			local z = tz - 2 + i * 1.5
			local roofY = top + rise * math.sqrt(math.max(0, 1 - (x / hw) ^ 2))
			pipe({ V(tx + tr * 0.5, y, z), V(x, y, z), V(x, roofY, z) }, r, L.accent)
		end
		local zf = tz - tr - 0.35
		pipe({ V(tx + 1.4, FLOOR + 7.5, zf), V(tx + 1.4, FLOOR + 1, zf), V(tx + tr + 1.1, FLOOR + 1, zf) }, r, L.accent)
	end
	if f >= 17 then
		-- 17 two floodlight masts of steel lattice at the yard's back corners, clear of the tower's banner, lit (the
		-- capital's are marble lamp standards at the wings' corners)
		for _, s in { -1, 1 } do
			if era == 4 then
				local x, z, h = s * (XF - 1.6), HZ - 2.4, 9.5
				local function leg(c: { number }, t: number): Vector3
					local e = 0.8 - 0.5 * t
					return V(x + c[1] * e, FLOOR + h * t, z + c[2] * e)
				end
				for i, a in CORNERS do
					local c = CORNERS[i % 4 + 1]
					b.rod("MastLeg", 0.12, leg(a, 0), leg(a, 1), L.beam)
					for k = 1, 4 do
						b.rod("MastTie", 0.08, leg(a, k / 4), leg(c, k / 4), L.beam)
						if (i + k) % 2 == 0 then
							b.rod("MastBrace", 0.07, leg(a, (k - 1) / 4), leg(c, k / 4), L.beam)
						else
							b.rod("MastBrace", 0.07, leg(c, (k - 1) / 4), leg(a, k / 4), L.beam)
						end
					end
				end
				local head = frame * CFrame.new(x, FLOOR + h + 0.9, z)
				local aim = CFrame.lookAt(head.Position, (frame * CFrame.new(0, FLOOR + 2, 2)).Position)
				b.trim("FloodFrame", 2.7, 1.9, 0.4, aim, DARK, M.Metal)
				local lampFace = b.trim("Floodlight", 2.3, 1.5, 0.2, aim * CFrame.new(0, 0, -0.2), L.glass, M.Neon)
				-- the head is a grid of six lamps, not a blank board
				b.trim("FloodBar", 2.3, 0.12, 0.1, aim * CFrame.new(0, 0, -0.32), DARK, M.Metal)
				for _, dx in { -0.4, 0.4 } do
					b.trim("FloodBar", 0.12, 1.5, 0.1, aim * CFrame.new(dx, 0, -0.32), DARK, M.Metal)
				end
				light(lampFace, L.glass, 30, 0.8)
			else
				local x, z = s * (hw + 3.7), HZ - 2.6
				column(x, z, FLOOR, FLOOR + 6.4, 0.32)
				b.trim("StandardCap", 1.2, 0.25, 1.2, b.at(x, FLOOR + 6.5, z), L.gold, M.Metal)
				light(
					b.trim("StandardLamp", 0.85, 1.1, 0.85, b.at(x, FLOOR + 7.15, z), L.glass, M.Neon),
					L.glass,
					22,
					0.7
				)
				b.trim("StandardCap", 1.1, 0.2, 1.1, b.at(x, FLOOR + 7.8, z), L.gold, M.Metal)
				b.ball("StandardFinial", 0.28, b.at(x, FLOOR + 8.15, z), L.gold, M.Metal)
			end
		end
	end
end

-- The Training Hall at its drawn size, then its house grown (Config.Village.HouseScale).
function TrainingHall.build(m: Instance, area: CFrame, level: number)
	local had = m:GetChildren()
	raise(m, area, level, had)
	Architecture.grow(m, had, area, "TrainingHall", SPLIT_Z, PIVOT_X, PIVOT_Z)
end

return TrainingHall
