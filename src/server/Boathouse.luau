--!strict
-- The fishing pond's landmark: the Dock (village v2, skill landmark-build; the owner approved the reference on
-- 2026-11-17: docs/areas/village-v2/dock-ref-sheet.jpg, the ladder is dock-ladder.md beside it). One place in five
-- architectures, one an era of ten levels:
--   1 hamlet       a timber fishing shack on log stilts under thatch, a log rail fence, a whitewashed lighthouse
--   2 painted      cream plaster on royal-blue beams under red tiles, white pickets, the lighthouse under a red cone
--   3 town         a stone boathouse with one great boat arch, a quay wall with iron rails, a round stone lighthouse
--   4 slime tech   black steel and a blue slate vault, copper pipes, a quay crane, the lighthouse's green goo lamp
--   5 capital      white marble and gold, columns and a pediment, a blue tiled vault, the lighthouse under its dome
-- The owner's note on the sheet: the pond stays big. Nothing here takes water away: the house stands on the back bank
-- (a corner of lawn between the village's walls, 40 studs wide at the water and closing to a point), its landing out
-- over the water's edge on stilts. The same things at every era, in the same places: THE BOATHOUSE across the back
-- bank, its water side (-z) wide open on the nets, the fish rack, the barrels and the boat on its slip; THE LIGHTHOUSE
-- at its left end as one looks from the pier's foot (+x), from level 10 on the tallest thing; THE FISH on the gable
-- over the open front; THE FENCE on the near bank in two short runs either side of the pier's foot (the pond is never
-- closed in); THE BOAT tied to the pier. The pier, the fishing places, the bin and the banks' life are PondStages'.
-- `build` takes the AREA's frame: the lawn's top is y 0, the water's surface WATER.
-- (Since the pond grew to three times its water, 2026-11-17: everything here is still drawn round the old pond's back
-- bank, and `build` then grows the house and sets it back on the new far shore: BACK, Config.Village.Pond.)
-- An era's first level changes the architecture; levels 4 and 5 of each bring the boat and one piece on the bank;
-- levels 6-10 add one feature each, and a feature once added stays in every later era in that era's materials (25 in
-- all, numbered in `build` as in the ladder).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Architecture = require(script.Parent.Architecture)
local LibraryKit = require(script.Parent.LibraryKit)

local Boathouse = {}

local C = Color3.fromRGB
local M = Enum.Material
local V = Vector3.new
local IRON = C(60, 60, 66)
local DARK = C(42, 34, 30)
local PLANK = C(176, 128, 78)
local BOX = C(128, 84, 50)
local LEAF = C(86, 160, 70)
local STRAW = C(204, 156, 62) -- the darker course half way up a thatch
local OCHRE = C(178, 128, 50) -- the third course, nearer the ridge
local GOO = C(96, 232, 70)
local DOME = C(70, 124, 214) -- the capital's blue glass
local STEEL = C(208, 212, 220)
local ROPE = C(214, 186, 128)
local NET = C(112, 132, 126)
local WHITE = C(244, 240, 230) -- whitewash
local RED = C(204, 62, 54)
local AMBER = C(238, 158, 60) -- a lit pane (deep: a paler one washes out to white in daylight)
local PANE = C(190, 226, 240) -- the lantern room's clear glass
local FISH = { C(110, 170, 210), C(240, 150, 90), C(160, 200, 120) }
local BLOOMS = { C(255, 120, 150), C(255, 214, 80), C(240, 90, 80) }
-- the house's floor an era: colours with no material of their own, so they keep the stud look (the owner's choice)
local FLOORS = { C(178, 130, 80), C(178, 130, 80), C(170, 164, 154), C(92, 98, 110), C(232, 228, 220) }
local FRONT = V(0, 0, -1)

local BX = -2 -- the house's middle line in the area's frame
local HZ = 28.6 -- its open front, at the water's back edge
local LX, LZ = 12, 32.5 -- the lighthouse
local FLOOR = 0.4 -- the house's and the landing's floor
local WATER = -2.3 -- the water's surface (PondStages' WATER_Y)
local QZ = 24.4 -- the landing's edge over the water
local FZ = -17.4 -- the fence's line on the near bank
local PIER_X = -3 -- the pier's line (AreaUpgrade's DOCK_X)
local BOAT_X, BOAT_Z = -8.7, -6.5 -- the boat, alongside the pier on its right (as the owner's sheet has it)
local T = 0.6 -- a wall's thickness

-- THE SHELL: what the Blender bodies (tools/blender/landmark_bodies.py, "the Dock") draw of the house and of the
-- lighthouse. With a body worn these parts are ghosts: the thin ones are not built, the solid ones stand inside the
-- mesh and keep the walls a player cannot walk through.
local SHELL: { [string]: boolean } = {}
for name in
	string.gmatch(
		"HouseBack HouseSide WallBand FrontPost FrontHeader Roof Gable BargeBoard Ridge EaveRoll ThatchCourse VergeRoll "
			.. "EaveCourse RidgeRoll GableBatten KingPost Rafter Strut GablePost GableTie GableBrace Rail Post Brace "
			.. "FrontPier Impost Shoulder FrontWall ArchStone Keystone StringCourse StoreyFront HouseFoot HousePost "
			.. "HouseRail Pylon PylonBand FrontTie VaultPane VaultRib VaultPurlin VaultRidge CornerPier PierFoot PierCap "
			.. "Architrave Frieze Cornice LightFoot LightFootCap LightDrum LightHoop LightCourse LightRib LightRivet",
		"%a+"
	)
do
	SHELL[name] = true
end

type Look = {
	hw: number, -- half the house's width
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
	cloth: Color3,
	gold: Color3,
	accent: Color3,
	fence: Color3,
	deck: Color3,
	mats: { [string]: Enum.Material },
}

local LOOKS: { Look } = {
	{ -- 1 hamlet
		hw = 7.6,
		depth = 10.4, -- (the owner, 2026-11-17: the house at least as deep as the pier is long, once it has grown)
		wallH = 5.6,
		rise = 5.4,
		wall = C(196, 150, 98),
		lower = C(164, 114, 68),
		stone = C(150, 146, 138),
		beam = C(110, 72, 42),
		board = C(92, 60, 36),
		roof = C(232, 190, 84),
		frame = C(126, 84, 50),
		cloth = C(52, 96, 204),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		fence = C(190, 146, 88),
		deck = C(186, 138, 86),
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
			deck = M.WoodPlanks,
		},
	},
	{ -- 2 painted
		hw = 8,
		depth = 10.4,
		wallH = 6,
		rise = 5.6,
		wall = C(244, 238, 224),
		lower = C(226, 214, 190),
		stone = C(214, 206, 188),
		beam = C(70, 118, 224), -- (a light royal blue: Wood darkens it)
		board = C(48, 86, 184),
		roof = C(198, 70, 58),
		frame = C(250, 246, 236),
		cloth = C(52, 96, 204),
		gold = C(236, 190, 70),
		accent = C(110, 72, 42),
		fence = C(250, 246, 236),
		deck = C(236, 228, 208),
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
			deck = M.WoodPlanks,
		},
	},
	{ -- 3 town
		hw = 8.2,
		depth = 10.4,
		wallH = 6.8,
		rise = 5.4,
		wall = C(240, 230, 206),
		lower = C(192, 188, 178),
		stone = C(132, 128, 122),
		beam = C(112, 72, 44),
		board = C(92, 60, 38),
		roof = C(190, 62, 50), -- (the owner, 2026-11-17: one roof an era for every landmark, the Granary's)
		frame = C(224, 218, 204),
		cloth = C(52, 96, 204),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		fence = C(170, 166, 156),
		deck = C(150, 100, 60),
		mats = {
			wall = M.Plaster,
			lower = M.Cobblestone,
			stone = M.Cobblestone,
			beam = M.Wood,
			board = M.Wood,
			roof = M.ClayRoofTiles,
			frame = M.Limestone,
			gold = M.Foil,
			accent = M.Metal,
			fence = M.Cobblestone,
			deck = M.Wood,
		},
	},
	{ -- 4 slime tech
		hw = 8.4,
		depth = 10.4,
		wallH = 7,
		rise = 8.4,
		wall = C(84, 190, 180), -- (teal darker than the sky: a paler pane read as one pale sheet)
		lower = C(72, 76, 88),
		stone = C(86, 90, 100),
		beam = C(52, 56, 64),
		board = C(40, 44, 50),
		roof = C(66, 108, 186),
		frame = C(104, 110, 122),
		cloth = C(52, 96, 204),
		gold = C(224, 170, 70),
		accent = C(226, 132, 78), -- (bright: Metal darkens it, and a duller copper read as brown wood)
		fence = C(40, 44, 50),
		deck = C(96, 102, 114),
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
			deck = M.DiamondPlate,
		},
	},
	{ -- 5 capital
		hw = 8.4,
		depth = 10.4,
		wallH = 11,
		rise = 5,
		wall = C(242, 239, 232), -- (not whiter: mouldings wash out in daylight)
		lower = C(214, 208, 196),
		stone = C(214, 208, 196),
		beam = C(228, 222, 210),
		board = C(236, 192, 76),
		roof = C(44, 84, 170),
		frame = C(236, 192, 76),
		cloth = C(40, 70, 160),
		gold = C(236, 192, 76),
		accent = C(236, 192, 76), -- (beside marble every metal is gold: copper there reads rustic)
		fence = C(250, 249, 245),
		deck = C(236, 232, 224),
		mats = {
			wall = M.Marble,
			stone = M.Marble,
			beam = M.Marble,
			roof = M.ClayRoofTiles,
			gold = M.Foil,
			fence = M.Marble,
			deck = M.Marble,
		},
	},
}

-- A level's era (1-5) and how many of the 25 features it has.
function Boathouse.features(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	return era, (era - 1) * 5 + math.max(0, s - 5)
end

-- The back bank the house, the lighthouse and the crane stand on, in the area's frame (x0, x1, z0, z1): scenery there
-- goes.
-- (What Architecture.grow takes as the house: what stands at or behind SPLIT_Z; and the point it grows round.)
local SPLIT_Z, PIVOT_X, PIVOT_Z = 21, -2, 24.4
-- (the whole back bank stands BACK studs behind where it is drawn: the pond grew to three times its water, behind
-- the old one, and the house went back with the shore)
local BACK = Config.Village.Pond.BoathouseBack
function Boathouse.footprint(_level: number): (number, number, number, number)
	local x0, x1, z0, z1 = Architecture.grownBox("Boathouse", SPLIT_Z, PIVOT_X, PIVOT_Z, -16, 18.5, 24.5, 38)
	return x0, x1, z0 + BACK, z1 + BACK
end

local function raise(m: Instance, area: CFrame, level: number)
	local era, f = Boathouse.features(level)
	local step = level - (era - 1) * 10
	local boatForm = if step >= 4 then era else era - 1 -- (the boat is each era's fourth level)
	local bank = if step >= 5 then era else era - 1 -- (and one piece on the bank its fifth)
	local L = LOOKS[era]
	local frame = area
	local skins: { [string]: Enum.Material } = {
		[IRON:ToHex()] = M.Metal,
		[DARK:ToHex()] = M.Metal,
		[PLANK:ToHex()] = M.WoodPlanks,
		[BOX:ToHex()] = M.Wood,
		[LEAF:ToHex()] = M.LeafyGrass,
		[STRAW:ToHex()] = M.Sand,
		[STEEL:ToHex()] = M.Metal,
		[DOME:ToHex()] = M.Glass,
		[ROPE:ToHex()] = M.SmoothPlastic,
		[NET:ToHex()] = M.SmoothPlastic,
	}
	for field, material in L.mats do
		skins[((L :: any)[field] :: Color3):ToHex()] = material
	end
	-- (0.08: at the other landmarks' 0.4, and still at 0.25, a vault's glass all but vanished in the game's daylight)
	local b = Architecture.new(m, frame, skins, 0.08)
	local hw, depth, wallH, rise = L.hw, L.depth, L.wallH, L.rise
	local storey = if era == 3 and f >= 14 then 3 else 0 -- (f14: the half-timbered floor over the stone one)
	local base = FLOOR + wallH -- the ground floor's top
	local top = base + storey -- the walls' top
	local x0, x1 = BX - hw, BX + hw
	local zb = HZ + depth -- the house's back
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
		local xl, xr = math.min(xa, xb), math.max(xa, xb)
		if xr - xl > 0.05 and y1 - y0 > 0.05 and zb2 - za > 0.05 then
			b.box(
				name,
				xr - xl,
				y1 - y0,
				zb2 - za,
				b.at((xl + xr) / 2, (y0 + y1) / 2, (za + zb2) / 2),
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
	-- THE BLENDER BODY of the era: one mesh a colour field, drawn in this frame's own coordinates
	local bodyName = "DockBody" .. era
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
		{ "Glass", AMBER, M.Neon },
		{ "Shutters", PLANK },
		{ "White", WHITE },
		{ "Red", RED },
	}
	local function worn(model: string)
		for _, slot in slots do
			piece(model .. "_" .. slot[1], b.at(0, 0, 0), 1, 1, 1, slot[2], slot[3])
		end
	end
	-- THE OWNER'S MESHY PIECES wear their own picture: unpainted, at `sx` times their size in Config.LibraryKit
	local function painted(name: string, cf: CFrame, sx: number, sy: number?, sz: number?): BasePart?
		return piece(name, cf, sx, sy or sx, sz or sx, Color3.new(1, 1, 1), M.SmoothPlastic)
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
	-- a balustrade along x from `xa` to `xb` at z, its foot at `y`: a post about every four studs
	local function balustrade(xa: number, xb: number, z: number, y: number, colour: Color3)
		local len = math.abs(xb - xa)
		local dir = math.sign(xb - xa)
		local bays = math.max(1, math.round(len / 4))
		local run = len / bays
		local along = if dir > 0 then CFrame.identity else CFrame.Angles(0, math.pi, 0)
		local kit = LibraryKit.find("Balustrade_Run") ~= nil
		for i = 0, bays do
			local cf = b.at(xa + dir * i * run, y, z) * along
			if kit then
				piece("Balustrade_Post", cf, 1, 1, 1, colour)
				if i < bays then
					piece("Balustrade_Run", cf * CFrame.new(run / 2, 0, 0), (run - 0.5) / 4, 1, 1, colour)
				end
			else
				b.trim("RailPost", 0.6, 1.3, 0.6, cf * CFrame.new(0, 0.65, 0), colour)
				if i < bays then
					b.trim("RailTop", run - 0.5, 0.25, 0.45, cf * CFrame.new(run / 2, 1, 0), colour)
					b.trim("RailFoot", run - 0.5, 0.2, 0.4, cf * CFrame.new(run / 2, 0.1, 0), colour)
					local n = math.max(2, math.floor((run - 0.6) / 0.9))
					for k = 1, n do
						local d = 0.3 + (run - 0.6) * (k - 0.5) / n
						b.trim("Baluster", 0.26, 0.7, 0.26, cf * CFrame.new(d, 0.55, 0), colour)
					end
				end
			end
		end
	end
	-- a flower box `w` wide, the face at the middle of its back
	local function flowerBox(face: CFrame, w: number, yellow: boolean)
		-- (the owner's Meshy box is 3.6 wide and 3 deep: made `w` wide and half as deep, to sit on a fence)
		local s = w / 3.6
		local kind = if yellow then "FlowerBox_Yellow" else "FlowerBox_Pink"
		if painted(kind, face * CFrame.new(0, -0.35, -0.75 * s), s, s, s * 0.5) then
			return
		end
		b.trim("FlowerBox", w, 0.7, 0.9, face * CFrame.new(0, 0, -0.45), BOX)
		b.trim("FlowerLeaves", w - 0.2, 0.4, 0.75, face * CFrame.new(0, 0.45, -0.45), LEAF)
		local n = math.max(3, math.round(w / 0.7))
		for i = 1, n do
			local across = -w / 2 + (i - 0.5) * w / n
			local bloom = if yellow then BLOOMS[2] else BLOOMS[i % 2 * 2 + 1]
			b.ball("Flower", 0.3, face * CFrame.new(across, 0.72, -0.45 - (i % 2) * 0.15), bloom)
		end
	end
	-- a wall lantern, its plate on the wall at `face`: the owner's Meshy one, a part one until it comes
	local function lamp(face: CFrame, s: number, lit: boolean)
		local kit = painted("WallLantern_Iron", face, s)
		if not kit then
			b.lantern(face, AMBER, IRON, lit)
		elseif lit then
			light(kit, AMBER, 14, 0.6)
		end
	end
	-- a pipe through `points` (in the frame), a fitting at every bend and at its end
	local function pipe(points: { Vector3 }, r: number, colour: Color3)
		for i = 1, #points - 1 do
			b.rod("Pipe", r, points[i], points[i + 1], colour, M.Metal)
			local p = points[i + 1]
			b.ball("PipeJoint", r * 1.5, b.at(p.X, p.Y, p.Z), L.gold, bigGold)
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
		colour: Color3
	)
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				local px, py = arc(half, spring, R, k)
				local qx, qy = arc(half, spring, R, k + 1)
				slab(name, cx + s * qx, cx + s * px, qy, y1, z - thick / 2, z + thick / 2, colour)
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
					colour
				)
			end
		end
	end
	-- the filling under an arch, from `spring` up to the arch: a glass fan
	local function fan(cx: number, half: number, spring: number, R: number, z: number, colour: Color3)
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				local px, py = arc(half, spring, R, k)
				local qx, qy = arc(half, spring, R, k + 1)
				slab("Fan", cx + s * qx, cx + s * px, spring, py, z - 0.08, z + 0.08, colour, M.Glass)
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
					M.Glass
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
	-- a vault over x cx - half..cx + half and z za..zb2, `R` high over `spring`: eight panes between ribs and purlins
	local function vault(
		cx: number,
		half: number,
		spring: number,
		R: number,
		za: number,
		zb2: number,
		glass: Color3,
		rib: Color3
	)
		local zm = (za + zb2) / 2
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				local px, py = arc(half, spring, R, k)
				local qx, qy = arc(half, spring, R, k + 1)
				b.beam("VaultPane", zb2 - za, 0.2, V(cx + s * px, py, zm), V(cx + s * qx, qy, zm), glass)
				for _, z in { za + 0.2, zm, zb2 - 0.2 } do
					b.beam("VaultRib", 0.4, 0.42, V(cx + s * px, py, z), V(cx + s * qx, qy, z), rib, M.Metal)
				end
				if k > 0 then
					b.rod("VaultPurlin", 0.15, V(cx + s * px, py, za), V(cx + s * px, py, zb2), rib, M.Metal)
				end
			end
		end
		b.rod("VaultRidge", 0.22, V(cx, spring + R + 0.05, za - 0.2), V(cx, spring + R + 0.05, zb2 + 0.2), rib, M.Metal)
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
		local pitch = up / half
		local ey = y - pitch * over - 0.25
		local cy = y + up - pitch * (half + over) / 2
		for _, s in { -1, 1 } do
			local x = cx + s * (half + over)
			b.rod("EaveRoll", 0.5, V(x, ey, za - over), V(x, ey, zb2 + over), L.roof)
			local xm = cx + s * (half + over) / 2
			b.rod("ThatchCourse", 0.34, V(xm, cy, za - over), V(xm, cy, zb2 + over), STRAW)
			-- (and a third, ochre, nearer the ridge: the bands step up the slope)
			local xq = cx + s * (half + over) / 4
			local qy = y + up - pitch * (half + over) / 4
			b.rod("ThatchCourse", 0.3, V(xq, qy, za - over), V(xq, qy, zb2 + over), OCHRE)
			-- (the front edge: a thick darker roll up each slope and a second course over the eave, so the roof's
			-- edge reads as layered thatch and not as a lid)
			local vy = y - pitch * over + 0.15
			b.rod("VergeRoll", 0.45, V(x, vy, za - over), V(cx, y + up + 0.15, za - over), STRAW)
			local xe = x - s * 0.8
			b.rod("EaveCourse", 0.4, V(xe, vy + pitch * 0.8, za - over), V(xe, vy + pitch * 0.8, zb2 + over), STRAW)
		end
		b.rod("RidgeRoll", 0.65, V(cx, y + up + 0.1, za - over - 0.1), V(cx, y + up + 0.1, zb2 + over + 0.1), L.roof)
	end
	-- battlements on a block `w` by `d` whose top is at `y`: a parapet and six merlons
	local function battlement(x: number, y: number, z: number, w: number, d: number, colour: Color3, cap: Color3)
		b.trim("Parapet", w + 0.4, 0.45, d + 0.4, b.at(x, y + 0.22, z), cap)
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
	-- the pond's cloth hanging from `face`: royal blue with a pointed foot and a gold crown
	local function banner(face: CFrame, w: number, h: number)
		-- (smooth, not Fabric: Fabric's dark weave turns cloth slate grey)
		local side = w / math.sqrt(2)
		b.trim("BannerRod", w + 0.5, 0.22, 0.22, face * CFrame.new(0, 0, -0.25), L.gold)
		b.trim("Banner", w, h, 0.1, face * CFrame.new(0, -h / 2, -0.35), L.cloth, M.SmoothPlastic)
		local point = face * CFrame.new(0, -h, -0.35) * CFrame.Angles(0, 0, math.pi / 4)
		b.trim("BannerPoint", side, side, 0.1, point, L.cloth, M.SmoothPlastic)
		b.trim("BannerBand", w, 0.2, 0.12, face * CFrame.new(0, -0.35, -0.37), L.gold)
		b.trim("Crown", w * 0.62, w * 0.2, 0.1, face * CFrame.new(0, -h * 0.5, -0.41), L.gold)
		for k = -1, 1 do
			b.trim(
				"CrownPoint",
				w * 0.17,
				w * 0.32,
				0.1,
				face * CFrame.new(k * w * 0.22, -h * 0.5 + w * 0.22, -0.41),
				L.gold
			)
		end
	end
	-- a striped awning sloping out from `face` (the middle of its top edge), a valance along its foot
	local function awning(face: CFrame, w: number, deep: number, c1: Color3, c2: Color3)
		local n = math.max(3, math.round(w / 1.1))
		local sw = w / n
		for i = 1, n do
			local c = if i % 2 == 1 then c1 else c2
			local lie = face * CFrame.new(-w / 2 + (i - 0.5) * sw, 0, 0) * CFrame.Angles(math.rad(-22), 0, 0)
			b.trim("Awning", sw, 0.3, deep, lie * CFrame.new(0, 0, -deep / 2), c, M.SmoothPlastic)
			b.trim("AwningValance", sw, 0.65, 0.14, lie * CFrame.new(0, -0.38, -deep), c, M.SmoothPlastic)
		end
	end
	-- a fishing net hung from a bar, `face` at the middle of the bar: `w` wide, `h` long, floats along its foot
	local function net(face: CFrame, w: number, h: number)
		b.trim("NetBar", w + 0.5, 0.2, 0.2, face, L.board)
		local nx, ny = math.max(3, math.round(w / 0.6)), math.max(3, math.round(h / 0.6))
		for i = 0, nx do
			b.trim("Net", 0.09, h, 0.09, face * CFrame.new(-w / 2 + i * w / nx, -h / 2, 0), NET)
		end
		for j = 1, ny do
			b.trim("Net", w, 0.09, 0.09, face * CFrame.new(0, -j * h / ny, 0), NET)
		end
		for i = 0, 2 do
			local float = if i % 2 == 0 then RED else WHITE
			b.ball("NetFloat", 0.24, face * CFrame.new(-w / 2 + (i + 0.5) * w / 3, -h - 0.1, 0), float, M.SmoothPlastic)
		end
	end
	-- the owner's fish rack with the day's catch, `cf` at the middle of its foot
	local function rack(cf: CFrame, s: number)
		if painted("FishRack_Wood", cf, s) then
			return
		end
		for _, dx in { -1.8, 1.8 } do
			b.trim("RackPost", 0.3, 4.2 * s, 0.3, cf * CFrame.new(dx * s, 2.1 * s, 0), BOX)
		end
		b.trim("RackBar", 4.2 * s, 0.25, 0.25, cf * CFrame.new(0, 4 * s, 0), BOX)
		for k = -1, 1 do
			b.trim(
				"RackFish",
				0.5 * s,
				1.3 * s,
				0.2,
				cf * CFrame.new(k * 1.1 * s, 3.1 * s, 0),
				FISH[k + 2],
				M.SmoothPlastic
			)
		end
	end
	local function barrel(x: number, y: number, z: number, s: number)
		if not painted("Barrel_Oak", b.at(x, y, z), s) then
			b.cyl("Barrel", 1.3 * s, 3 * s, b.at(x, y + 1.5 * s, z), BOX)
		end
	end
	local function urn(x: number, y: number, z: number)
		if not painted("Urn_PinkFlowers", b.at(x, y, z), 0.8) then
			b.cyl("Urn", 0.7, 1.4, b.at(x, y + 0.7, z), L.gold, bigGold, false)
			b.ball("UrnFlowers", 0.9, b.at(x, y + 2, z), BLOOMS[1])
		end
	end
	-- a ring of sixteen bars round (cx, cy) on the plane z, `R` in radius: rivets on every other joint when asked
	local function ring(
		cx: number,
		cy: number,
		z: number,
		R: number,
		thick: number,
		colour: Color3,
		material: Enum.Material?,
		rivets: Color3?
	)
		for k = 0, 15 do
			local a0, a1 = k * math.pi / 8, (k + 1) * math.pi / 8
			local p = V(cx + R * math.cos(a0), cy + R * math.sin(a0), z)
			b.beam("EmblemRing", thick, thick, p, V(cx + R * math.cos(a1), cy + R * math.sin(a1), z), colour, material)
			if rivets and k % 2 == 0 then
				b.ball("Rivet", thick * 0.36, b.at(p.X, p.Y, p.Z - thick * 0.5), rivets, M.Metal)
			end
		end
	end
	-- THE FISH: a round sign with a fish in relief, `r` half its width, its back on the wall at (cx, cy, z)
	local function emblem(cx: number, cy: number, z: number, r: number)
		local face = b.face(cx, cy, z, FRONT)
		-- (the hamlet's: a wooden sign, the fish carved in pale wood; a blue one read as plastic on the thatch)
		local disc, rim, fish = PLANK, L.board, C(222, 184, 126)
		local metal: Enum.Material? = nil
		local discMat: Enum.Material? = nil
		if era == 2 then
			disc, rim, fish = L.frame, L.gold, L.beam
		elseif era == 3 then
			disc, rim, fish, metal = L.frame, IRON, IRON, M.Metal
		elseif era == 4 then
			disc, rim, fish, metal, discMat = L.lower, L.frame, STEEL, M.Metal, M.Metal
		elseif era == 5 then
			-- (a plate behind an emblem on marble is the era's cloth)
			disc, rim, fish, metal, discMat = L.cloth, L.gold, L.gold, M.Metal, M.SmoothPlastic
		end
		local held = face * CFrame.new(0, 0, -0.2 * r)
		if piece("FishEmblem_Disc", held, r, r, r, disc, discMat) then
			piece("FishEmblem_Rim", held, r, r, r, rim, metal)
			piece("FishEmblem_Fish", held, r, r, r, fish, metal)
			piece("FishEmblem_Eye", held, r, r, r, if era == 3 then L.frame else DARK, M.SmoothPlastic)
		else
			b.disc("EmblemRim", r, 0.3, face * CFrame.new(0, 0, -0.15), rim, metal)
			b.disc("EmblemDisc", r * 0.86, 0.4, face * CFrame.new(0, 0, -0.2), disc, discMat)
			b.trim("EmblemFish", r * 0.9, r * 0.44, 0.16, face * CFrame.new(-0.12 * r, 0, -0.48), fish, metal)
			local tail = face * CFrame.new(0.46 * r, 0, -0.48) * CFrame.Angles(0, 0, math.pi / 4)
			b.trim("EmblemTail", r * 0.36, r * 0.36, 0.16, tail, fish, metal)
		end
		if f >= 13 then -- f13: the great riveted ring round it
			local iron = if era == 5 then L.gold elseif era == 4 then L.board else IRON
			ring(cx, cy, z - 0.3, r * 1.3, 0.55, iron, M.Metal, if era == 3 then L.frame else L.gold)
		end
		if era == 4 and f >= 19 then -- f19: its rim glows green (a thin line of light, the ring itself stays steel)
			ring(cx, cy, z - 0.62, r * 1.3, 0.16, GOO, M.Neon)
		end
		if f >= 22 then -- f22: gold laurels round the fish
			-- (wider than the riveted ring, or the ring hides them)
			local s = r * 3.7 / 5.273
			if not painted("Laurel_Gold", face * CFrame.new(0, -0.1 * r, 0.1), s, s, 0.7) then
				for _, side in { -1, 1 } do
					b.beam(
						"Laurel",
						0.3,
						0.5,
						V(cx + side * r * 0.5, cy - r * 1.6, z - 0.3),
						V(cx + side * r * 1.8, cy, z - 0.3),
						L.gold
					)
				end
			end
		end
	end
	-- a boat, `cf` at the middle of its waterline, its bow to -z: the pond's own hull from parts, and what each era
	-- puts in it (1 oars, 2 a mast and a pennant, 3 a mast with a furled sail, 4 a funnel and a goo lamp, 5 a canopy)
	local function boat(cf: CFrame, form: number)
		local q = Architecture.new(m, cf, skins, 0.08)
		local hull = ({ PLANK, WHITE, C(150, 100, 60), C(52, 56, 64), C(246, 244, 238) })[form]
		local edge = ({ BOX, C(48, 86, 184), C(92, 60, 38), C(224, 170, 70), C(236, 192, 76) })[form]
		local hullMat = if form == 4 then M.Metal elseif form == 5 then M.SmoothPlastic else M.WoodPlanks
		local edgeMat = if form >= 4 then M.Metal else M.Wood
		q.trim("BoatFloor", 1.8, 0.22, 4.4, q.at(0, -0.3, 0.6), hull, hullMat)
		q.trim("BoatBowFloor", 1, 0.22, 1.5, q.at(0, -0.3, -2.2), hull, hullMat)
		for _, s in { -1, 1 } do
			q.trim("BoatSide", 0.22, 1.15, 4.4, q.at(s * 1.05, 0.2, 0.6) * CFrame.Angles(0, 0, -s * 0.2), hull, hullMat)
			q.beam("BoatBow", 0.22, 1.15, V(s * 1.14, 0.22, -1.6), V(0, 0.3, -3.5), hull, hullMat)
			q.trim("BoatGunwale", 0.32, 0.16, 4.5, q.at(s * 1.17, 0.8, 0.6), edge, edgeMat)
			q.beam("BoatBowRail", 0.32, 0.16, V(s * 1.17, 0.8, -1.65), V(0, 0.92, -3.55), edge, edgeMat)
		end
		q.trim("BoatStern", 2.3, 1.15, 0.22, q.at(0, 0.2, 2.8), hull, hullMat)
		q.trim("BoatStem", 0.26, 1.5, 0.26, q.at(0, 0.45, -3.55), edge, edgeMat)
		for _, z in { -0.5, 1.5 } do
			q.trim("BoatThwart", 2.1, 0.14, 0.55, q.at(0, 0.42, z), PLANK)
		end
		if form == 1 then
			for _, s in { -1, 1 } do
				q.rod("Oar", 0.07, V(s * 0.5, 0.58, 2.2), V(s * 0.75, 0.58, -1.6), BOX)
				q.trim("OarBlade", 0.34, 0.06, 0.9, q.at(s * 0.78, 0.58, -2), BOX)
			end
		elseif form == 2 then
			q.rod("BoatMast", 0.09, V(0, -0.2, -0.9), V(0, 3.8, -0.9), WHITE, M.SmoothPlastic)
			q.trim("Pennant", 0.06, 0.55, 1.1, q.at(0, 3.45, -0.3), RED, M.SmoothPlastic)
			q.ball("MastKnob", 0.16, q.at(0, 3.9, -0.9), C(236, 190, 70), M.Metal)
		elseif form == 3 then
			q.rod("BoatMast", 0.11, V(0, -0.2, -0.8), V(0, 5.8, -0.8), edge, edgeMat)
			q.rod("BoatBoom", 0.08, V(0, 1.5, -0.8), V(0, 1.5, 2.7), edge, edgeMat)
			q.rod("FurledSail", 0.27, V(0, 1.8, -0.6), V(0, 1.8, 2.5), C(240, 230, 206), M.SmoothPlastic)
			q.rod("Forestay", 0.035, V(0, 5.7, -0.8), V(0, 1, -3.5), ROPE)
			q.trim("Pennant", 0.06, 0.45, 0.9, q.at(0, 5.5, -0.3), RED, M.SmoothPlastic)
		elseif form == 4 then
			q.trim("LaunchCabin", 1.5, 1, 1.7, q.at(0, 0.75, 1), C(72, 76, 88), M.Metal)
			q.trim("LaunchGlass", 1.56, 0.4, 1.3, q.at(0, 0.9, 1), AMBER, M.Neon)
			q.trim("LaunchRoof", 1.8, 0.16, 2, q.at(0, 1.33, 1), edge, edgeMat)
			q.cyl("Funnel", 0.34, 1.9, q.at(0, 1.4, -0.6), edge, edgeMat, false)
			q.cyl("FunnelBand", 0.39, 0.3, q.at(0, 2.2, -0.6), C(40, 44, 50), M.Metal, false)
			q.rod("LampStem", 0.06, V(0, 0.8, -2.6), V(0, 1.7, -2.6), edge, edgeMat)
			light(q.ball("LaunchLamp", 0.3, q.at(0, 1.9, -2.6), GOO, M.Neon), GOO, 10, 0.6)
		else
			for _, s in { -1, 1 } do
				for _, z in { -0.7, 2.3 } do
					q.rod("CanopyPost", 0.07, V(s * 0.98, 0.8, z), V(s * 0.98, 2.75, z), edge, edgeMat)
				end
				q.trim("CanopyValance", 0.08, 0.4, 3.4, q.at(s * 1.2, 2.6, 0.8), edge, edgeMat)
			end
			q.trim("Canopy", 2.5, 0.2, 3.5, q.at(0, 2.85, 0.8), C(40, 70, 160), M.SmoothPlastic)
			q.ball("BargeFinial", 0.24, q.at(0, 1.35, -3.55), edge, edgeMat)
		end
	end

	-- THE BOATHOUSE --------------------------------------------------------------------------------------------
	slab("HouseFloor", x0, x1, 0, FLOOR, HZ, zb, FLOORS[era])
	local function walls(y0: number, y1: number, colour: Color3)
		slab("HouseBack", x0, x1, y0, y1, zb - T, zb, colour)
		for _, s in { -1, 1 } do
			local x = BX + s * (hw - T / 2)
			slab("HouseSide", x - T / 2, x + T / 2, y0, y1, HZ, zb - T, colour)
		end
	end
	local function sideWindows(y: number, w: number, h: number)
		for _, s in { -1, 1 } do
			b.window(b.face(BX + s * hw, y, zc, V(s, 0, 0)), w, h, L.frame, AMBER, { glow = true })
		end
	end
	-- timber in a gable whose foot is at `y`: a king post, a tie and two braces (the fish hangs over their meeting)
	local function gableTimber(y: number, z: number)
		b.trim("GablePost", 0.45, rise - 0.5, 0.25, b.at(BX, y + (rise - 0.5) / 2, z), L.beam)
		b.trim("GableTie", hw * 2 - 0.4, 0.45, 0.25, b.at(BX, y + 0.22, z), L.beam)
		for _, s in { -1, 1 } do
			b.beam(
				"GableBrace",
				0.25,
				0.4,
				V(BX + s * hw * 0.55, y + 0.3, z),
				V(BX + s * 0.2, y + rise * 0.6, z),
				L.beam
			)
		end
	end
	local lampX, frontZ = hw - 0.35, HZ - 0.16 -- where the two front lanterns hang (f1) and the front's outer face
	local fishY, fishZ, fishR = top + 2.3, HZ - 0.06, 2 -- the fish's middle and half its width
	-- (a header as long as the part build's stands out of the body's roof)
	local header = if bodied then hw * 2 - 0.2 else hw * 2 + 0.6

	shell(true)
	if era == 1 then
		walls(FLOOR, top, L.wall)
		for _, s in { -1, 1 } do
			b.trim("WallBand", T + 0.2, 1.4, depth, b.at(BX + s * (hw - T / 2), FLOOR + 0.7, zc), L.lower)
		end
		-- (the front posts are the stilts: logs down into the water's edge)
		for _, x in { x0 + 0.35, BX - hw / 3, BX + hw / 3, x1 - 0.35 } do
			b.cyl("FrontPost", 0.36, top + 3, b.at(x, (top - 3) / 2, HZ + 0.2), L.beam)
		end
		b.box("FrontHeader", header, 0.55, 0.55, b.at(BX, top - 0.28, HZ + 0.2), L.board)
		frontGable(BX, hw, top, HZ, zb, rise, 1, L.wall, if f >= 1 then nil else -1)
		if f >= 1 then
			-- f1: the truss is closed with boards (battens over their joints); the fish comes below
			for _, dx in { -4.6, -2.3, 2.3, 4.6 } do
				local h = rise * (1 - math.abs(dx) / hw) - 0.7
				b.trim("GableBatten", 0.3, h, 0.2, b.at(BX + dx, top + h / 2, HZ - 0.08), L.board)
			end
		else
			-- the open truss: a king post, two rafters under the thatch and two struts
			b.trim("KingPost", 0.45, rise - 0.7, 0.45, b.at(BX, top + (rise - 0.7) / 2, HZ + 0.25), L.board)
			for _, s in { -1, 1 } do
				b.beam(
					"Rafter",
					0.4,
					0.45,
					V(BX + s * hw, top - 0.3, HZ + 0.25),
					V(BX, top + rise - 0.9, HZ + 0.25),
					L.board
				)
				b.beam(
					"Strut",
					0.35,
					0.35,
					V(BX, top + 0.3, HZ + 0.25),
					V(BX + s * hw * 0.5, top + rise * 0.5 - 0.75, HZ + 0.25),
					L.board
				)
			end
		end
	elseif era == 2 then
		walls(FLOOR, top, L.wall)
		for _, s in { -1, 1 } do
			b.timber(b.face(BX + s * hw, FLOOR + wallH / 2, zc, V(s, 0, 0)), depth, wallH, L.beam)
		end
		sideWindows(FLOOR + wallH * 0.55, 1.8, 2.2)
		for _, x in { x0 + 0.35, BX - hw / 3, BX + hw / 3, x1 - 0.35 } do
			b.box("FrontPost", 0.7, top + 3, 0.7, b.at(x, (top - 3) / 2, HZ + 0.25), L.beam)
		end
		b.box("FrontHeader", header, 0.6, 0.6, b.at(BX, top - 0.3, HZ + 0.25), L.board)
		frontGable(BX, hw, top, HZ, zb, rise, 0.8, L.wall)
		gableTimber(top, HZ - 0.1)
		frontZ = HZ - 0.1
	elseif era == 3 then
		-- the boat arch, from shoulder to shoulder: half its width, where it springs, its rise
		local AH, spring, AR = 4.9, FLOOR + 2.6, 3.2
		local za = if storey > 0 then HZ - 0.4 else HZ -- (the timber floor stands out over the stone one)
		walls(FLOOR, base, L.lower)
		for _, s in { -1, 1 } do
			slab("FrontPier", BX + s * AH, BX + s * hw, FLOOR, base, HZ, HZ + T, L.lower)
			b.trim("Impost", 0.9, 0.4, T + 0.8, b.at(BX + s * (AH + 0.3), spring, HZ + T / 2 - 0.15), L.frame)
			-- the shoulders: a stone tower at each front corner
			local sx = BX + s * (hw - 0.95)
			b.box("Shoulder", 2.3, base + 1.1, 2.3, b.at(sx, (base + 1.1) / 2, HZ + 0.65), L.stone)
			if f >= 11 then -- f11: battlements on them
				battlement(sx, base + 1.1, HZ + 0.65, 2.3, 2.3, L.stone, L.frame)
			else
				b.trim("ShoulderCap", 2.7, 0.35, 2.7, b.at(sx, base + 1.27, HZ + 0.65), L.frame)
			end
		end
		archWall("FrontWall", BX, AH, spring, AR, base, HZ + T / 2, T, L.lower)
		-- (proud two-tone voussoirs with depth through the wall, and a keystone)
		archRing("ArchStone", BX, AH + 0.5, spring, AR + 0.5, HZ + T / 2 - 0.15, T + 0.7, 1, L.frame, nil, L.stone)
		b.trim("Keystone", 1.2, 1.35, T + 0.9, b.at(BX, spring + AR + 0.5, HZ + T / 2 - 0.15), L.frame)
		b.trim("StringCourse", hw * 2 - 4.2, 0.35, 0.4, b.at(BX, base - 0.17, HZ - 0.1), L.frame)
		if storey > 0 then
			-- f14: a half-timbered floor under a higher roof
			walls(base, top, L.wall)
			slab("StoreyFront", x0, x1, base, top, za, za + T, L.wall)
			b.timber(b.face(BX, base + storey / 2, za, FRONT), hw * 2, storey, L.beam)
			for _, s in { -1, 1 } do
				b.timber(b.face(BX + s * hw, base + storey / 2, zc, V(s, 0, 0)), depth, storey, L.beam)
				b.window(b.face(BX + s * 4.7, base + storey / 2, za, FRONT), 1.4, 1.5, L.frame, AMBER, { glow = true })
			end
		end
		sideWindows(FLOOR + 3.6, 1.6, 2.2)
		frontGable(BX, hw, top, za, zb, rise, 0.8, L.wall)
		gableTimber(top, za - 0.1)
		lampX, frontZ = hw - 0.95, HZ - 0.5 -- (the lanterns hang on the shoulders: the arch takes the wall between)
		fishY, fishZ, fishR = top + 2.45, za - 0.06, 1.6
	elseif era == 4 then
		-- a steel portal, glass walls on a steel foot, the vault springing from the walls' top
		for _, s in { -1, 1 } do
			local x = BX + s * (hw - T / 2)
			slab("HouseFoot", x - T / 2, x + T / 2, FLOOR, FLOOR + 2.4, HZ, zb, L.lower)
			slab("HouseGlass", x - 0.15, x + 0.15, FLOOR + 2.4, top, HZ, zb, L.wall)
			for k = 0, 2 do
				local z = HZ + 0.35 + k * (depth - 0.7) / 2
				b.box("HousePost", 0.7, top - FLOOR, 0.7, b.at(BX + s * (hw - 0.35), (FLOOR + top) / 2, z), L.board)
			end
			b.trim("HouseRail", 0.5, 0.4, depth, b.at(BX + s * (hw - 0.3), FLOOR + 4.7, zc), L.board)
			-- the shoulders: a steel pylon at each front corner
			local sx = BX + s * (hw - 0.95)
			b.box("Pylon", 2.2, top + 2, 2.2, b.at(sx, (top + 2) / 2, HZ + 0.6), L.board)
			b.trim("PylonBand", 2.4, 0.4, 2.4, b.at(sx, top - 0.2, HZ + 0.6), L.gold, bigGold)
			battlement(sx, top + 2, HZ + 0.6, 2.2, 2.2, L.lower, L.gold) -- (f11, in steel and brass)
		end
		slab("HouseBack", x0, x1, FLOOR, top, zb - T, zb, L.lower)
		b.box("FrontTie", hw * 2 - 2, 0.7, 0.7, b.at(BX, top - 0.35, HZ + 0.35), L.board)
		vault(BX, hw, top, rise, HZ, zb, L.roof, L.board)
		fan(BX, hw - 0.3, top, rise - 0.3, zb - 0.3, L.wall)
		fan(BX, hw - 0.3, top, rise - 0.3, HZ + 0.35, L.wall)
		-- the lunette's bars: three, and from f19 a round fan window (seven bars and a ring half way out)
		local bars: { number } = if f >= 19 then { 1, 2, 3, 4, 5, 6, 7 } else { 2, 4, 6 }
		for _, k in bars do
			local a = math.rad(k * 22.5)
			local tip = V(BX + (hw - 0.4) * math.cos(a), top + (rise - 0.4) * math.sin(a), HZ + 0.2)
			b.rod("FanBar", 0.14, V(BX, top, HZ + 0.2), tip, L.board, M.Metal)
		end
		if f >= 19 then
			archRing("FanRing", BX, hw * 0.66, top, rise * 0.66, HZ + 0.2, 0.3, 0.3, L.board, M.Metal)
		end
		lampX, frontZ = hw - 0.95, HZ - 0.5
		fishY, fishZ, fishR = top + 3.1, HZ + 0.1, 1.9
	else
		local ent = 1.3 -- the entablature's height
		local ph = top - ent -- the columns' top
		walls(FLOOR, top, L.wall)
		sideWindows(FLOOR + 4.2, 1.8, 3)
		-- two corner piers and four columns carry the entablature and the pediment
		for _, s in { -1, 1 } do
			slab("CornerPier", BX + s * (hw - 1.7), BX + s * hw, FLOOR, ph, HZ, HZ + 1.7, L.wall)
			b.trim("PierFoot", 2, 0.5, 2, b.at(BX + s * (hw - 0.85), FLOOR + 0.25, HZ + 0.85), L.stone)
			b.trim("PierCap", 2, 0.4, 2, b.at(BX + s * (hw - 0.85), ph - 0.2, HZ + 0.85), L.gold)
			for _, dx in { 1.9, 4.5 } do
				column(BX + s * dx, HZ + 0.85, FLOOR, ph, 0.55)
			end
			-- (f11 at the capital: a gold finial on each corner of the pediment)
			if not painted("Finial_GoldStone", b.at(BX + s * (hw - 0.3), top + 0.1, HZ + 0.6), 0.7) then
				b.ball("Acroterion", 0.5, b.at(BX + s * (hw - 0.3), top + 0.6, HZ + 0.6), L.gold, bigGold)
			end
		end
		b.box("Architrave", hw * 2 + 0.4, 0.7, 2, b.at(BX, ph + 0.35, HZ + 0.9), L.beam)
		b.trim("Frieze", hw * 2 + 0.5, 0.3, 2.1, b.at(BX, ph + 0.85, HZ + 0.9), L.gold)
		b.trim("Cornice", hw * 2 + 1.3, 0.3, 2.7, b.at(BX, top - 0.15, HZ + 0.9), L.wall)
		if f >= 23 then
			-- f23: the roof is a vault in the era's blue tiles with gold ribs, behind the pediment (its end fans stay glass)
			frontGable(BX, hw, top, HZ - 0.3, HZ + 2.3, rise, 0.6, L.wall)
			vault(BX, hw - 0.5, top, rise + 0.8, HZ + 2.3, zb, L.roof, L.gold)
			fan(BX, hw - 0.7, top, rise + 0.6, HZ + 2.5, DOME)
			fan(BX, hw - 0.7, top, rise + 0.6, zb - 0.3, DOME)
		else
			frontGable(BX, hw, top, HZ - 0.3, zb, rise, 0.6, L.wall)
		end
		-- (the pediment's field: a shaded marble panel inside a thin gold border, so the fish hangs in a frame)
		local tw, th, ty, tz = hw * 0.74, rise * 0.74, top + 0.35, HZ - 0.34
		for _, s in { -1, 1 } do
			local lie = CFrame.fromMatrix(V(BX + s * tw / 2, ty + th / 2, tz), V(0, 0, s), V(0, 1, 0), V(-s, 0, 0))
			b.wedge("Tympanum", 0.08, th, tw, frame * lie, L.lower)
			b.beam(
				"TympanumBorder",
				0.14,
				0.16,
				V(BX + s * tw, ty, tz - 0.06),
				V(BX, ty + th, tz - 0.06),
				L.gold,
				M.Metal
			)
		end
		b.trim("TympanumBorder", tw * 2, 0.16, 0.14, b.at(BX, ty, tz - 0.06), L.gold, M.Metal)
		if f >= 16 then -- f16 at the capital: a gold lantern hangs in each bay of the portico
			for i, dx in { 0, -3.2, 3.2, -5.6, 5.6 } do
				b.rod("LanternChain", 0.05, V(BX + dx, ph, HZ + 0.85), V(BX + dx, ph - 1.1, HZ + 0.85), L.gold, M.Metal)
				b.trim("LanternCap", 0.75, 0.18, 0.75, b.at(BX + dx, ph - 1.15, HZ + 0.85), L.gold, M.Metal)
				-- (warm glass round a small lit core: a whole Neon box washes out to white in daylight)
				local at = b.at(BX + dx, ph - 1.65, HZ + 0.85)
				b.trim("Lantern", 0.55, 0.8, 0.55, at, C(250, 200, 105), M.Glass).Transparency = 0.35
				local glow = b.trim("LanternCore", 0.24, 0.5, 0.24, at, AMBER, M.Neon)
				b.trim("LanternFoot", 0.65, 0.14, 0.65, b.at(BX + dx, ph - 2.1, HZ + 0.85), L.gold, M.Metal)
				if i == 1 then
					light(glow, AMBER, 16, 0.6)
				end
			end
		end
		if f >= 21 then -- f21: the pond's banners on the corner piers
			for _, s in { -1, 1 } do
				banner(b.face(BX + s * (hw - 0.85), ph - 0.8, HZ - 0.02, FRONT), 1.3, 4.2)
			end
		end
		lampX, frontZ = hw - 0.85, HZ
		fishY, fishZ, fishR = top + 2.3, HZ - 0.36, 1.5
	end
	shell(false)
	if bodied then
		worn(bodyName)
		if era == 1 then
			worn(if f >= 1 then "DockGable1" else "DockTruss1")
		elseif era == 3 then
			worn(if storey > 0 then "DockStorey3" else "DockRoof3")
		elseif era == 5 then
			worn(if f >= 23 then "DockVault5" else "DockRoof5")
		end
	end

	-- THE FISH over the open front, from f1 (the hamlet's open truss has none before)
	if f >= 1 then
		emblem(BX, fishY, fishZ, fishR)
		-- f1: a lantern on each of the two front posts (the left one lit)
		for _, s in { -1, 1 } do
			lamp(b.face(BX + s * lampX, FLOOR + 3.6, frontZ - 0.02, FRONT), 0.55, s > 0)
		end
	end

	-- inside, seen across the pond through the open front: a warm light, a net on the back wall, the fish rack, barrels,
	-- the boat on its slip
	local glow = b.trim("InsideGlow", 0.4, 0.4, 0.4, b.at(BX, FLOOR + math.min(wallH, 7) - 0.8, zc), AMBER, M.Neon)
	glow.Transparency = 1
	light(glow, C(255, 214, 150), 18, 0.7)
	net(b.face(BX + hw * 0.5, FLOOR + 4.6, zb - T - 0.15, FRONT), 4.6, 3)
	rack(b.at(BX - hw * 0.52, FLOOR, zb - T - 0.9), 0.95)
	barrel(x1 - 1.7, FLOOR, HZ + 2.2, 0.6)
	barrel(x1 - 1.9, FLOOR, HZ + 4.2, 0.6)
	for _, z in { zc - 1.6, zc + 1.9 } do
		b.trim("SlipTrestle", 2.8, 0.9, 0.4, b.at(BX, FLOOR + 0.45, z), L.board)
	end
	boat(b.at(BX, FLOOR + 1.25, zc + 0.2), 1)
	-- the slip: two dark rails down the middle of the floor and out over the landing to its edge
	local slipRail = if era >= 3 then IRON else LOOKS[1].board
	for _, s in { -1, 1 } do
		local x = BX + s * 1.1
		slab(
			"SlipRail",
			x - 0.17,
			x + 0.17,
			FLOOR,
			FLOOR + 0.14,
			if f >= 2 then QZ + 0.1 else HZ,
			zb - T - 0.5,
			slipRail
		)
	end

	-- THE LANDING --------------------------------------------------------------------------------------------
	-- f2: a plank landing on stilts out over the water's edge; f12: a stone quay apron with steps and mooring rings
	local qx0, qx1 = x0 - 0.6, x1 + 0.6
	if f >= 2 then
		if f >= 12 then
			local quay = if era == 4 then L.stone else L.lower
			slab("Quay", qx0, qx1, -3.4, FLOOR - 0.3, QZ, HZ, quay)
			slab("QuayTop", qx0 - 0.15, qx1 + 0.15, FLOOR - 0.3, FLOOR, QZ - 0.15, HZ, L.deck)
			for k = 1, 4 do
				slab("QuayStep", BX - 2, BX + 2, -3.4, FLOOR - k * 0.6, QZ - k * 0.8, QZ - (k - 1) * 0.8, quay)
			end
			for _, dx in { -7, -4.2, 4.2, 7 } do
				local face = b.face(BX + dx, -0.6, QZ - 0.02, FRONT)
				b.disc("MooringRing", 0.45, 0.16, face, IRON)
				b.disc("MooringEye", 0.26, 0.2, face, quay)
			end
			for _, s in { -1, 1 } do
				b.cyl("Bollard", 0.34, 0.9, b.at(BX + s * 3, FLOOR + 0.45, QZ + 0.6), IRON)
				b.cyl("BollardCap", 0.44, 0.2, b.at(BX + s * 3, FLOOR + 0.95, QZ + 0.6), L.gold, bigGold, false)
			end
		else
			slab("Landing", qx0, qx1, FLOOR - 0.35, FLOOR, QZ, HZ, L.deck)
			b.trim("LandingEdge", qx1 - qx0 + 0.3, 0.45, 0.35, b.at(BX, FLOOR - 0.25, QZ - 0.05), L.board)
			for i = 0, 4 do
				local x = qx0 + 0.5 + i * (qx1 - qx0 - 1) / 4
				for _, z in { QZ + 0.4, QZ + 2.4 } do
					b.cyl("Stilt", 0.3, FLOOR + 3.1, b.at(x, (FLOOR - 0.35 - 3.4) / 2, z), L.beam)
				end
			end
		end
		-- the landing's life: a net hung to dry between two posts at its right end, barrels and crates at its left
		local nx = qx0 + 4.3
		for _, dx in { -2.3, 2.3 } do
			b.cyl("NetPost", 0.2, 3.5, b.at(nx + dx, FLOOR + 1.75, QZ + 0.5), L.board)
		end
		net(b.face(nx, FLOOR + 3.3, QZ + 0.5, FRONT), 4.2, 2.2)
		painted("RopeHook_Coil", b.face(nx + 2.3, FLOOR + 1.5, QZ + 0.3, FRONT), 0.5)
		barrel(qx1 - 2.7, FLOOR, QZ + 1.3, 0.6)
		if not painted("CrateStack_Wood", b.at(qx1 - 5, FLOOR, QZ + 1.5), 0.5) then
			b.box("Crate", 1.6, 1.4, 1.5, b.at(qx1 - 5, FLOOR + 0.7, QZ + 1.5), BOX)
		end
		if bank >= 5 then -- 45: gold urns of pink flowers on the quay's corners
			urn(qx0 + 0.9, FLOOR, QZ + 0.9)
			urn(qx1 - 0.9, FLOOR, QZ + 0.9)
		end
	end
	-- f6: a striped awning over the landing at the house's right (a glass canopy at the slime-tech era)
	if f >= 6 then
		if era == 2 then
			awning(b.face(BX - hw * 0.62, top - 0.6, frontZ - 0.3, FRONT), 5, 3.2, L.board, WHITE)
		else
			local aw = if era == 3 then 3 else 4 -- (the stone era's hangs on the right shoulder, clear of the boat arch)
			local face = b.face(x0 + aw / 2, FLOOR + 5, frontZ - 0.05, FRONT)
			if era == 4 then
				local lie = face * CFrame.Angles(math.rad(-14), 0, 0)
				b.trim("Canopy", 4, 0.16, 2.6, lie * CFrame.new(0, 0, -1.3), L.roof, M.Glass)
				for _, dx in { -1.9, 0, 1.9 } do
					b.trim("CanopyRib", 0.2, 0.26, 2.7, lie * CFrame.new(dx, 0, -1.35), L.board)
				end
			else
				awning(
					face,
					aw,
					2.6,
					if era == 3 then L.roof else L.cloth,
					if era == 3 then L.wall else C(244, 226, 170)
				)
			end
		end
	end
	-- 35: a steel crane on the bank at the house's right, a crate hanging from its hook over the water's edge
	if bank >= 4 then
		local cx, cz = qx0 - 2.8, HZ - 1.6
		local mast = if era == 5 then L.wall else L.board
		local jib = if era == 5 then L.gold else L.board
		local tip = V(cx + 3.8, 9.8, cz - 3.4)
		b.box("CraneBase", 2.2, 0.8, 2.2, b.at(cx, 0.4, cz), L.stone)
		b.box("CraneMast", 0.7, 8, 0.7, b.at(cx, 4.8, cz), mast)
		b.cyl("CraneCap", 0.55, 0.4, b.at(cx, 9, cz), L.gold, bigGold, false)
		b.beam("CraneJib", 0.45, 0.5, V(cx, 6.4, cz), tip, jib, M.Metal)
		b.disc("CranePulley", 0.5, 0.22, b.face(tip.X, tip.Y - 0.1, tip.Z, V(0.67, 0, 0.74)), L.gold, M.Metal)
		b.rod("CraneStay", 0.09, V(cx, 9, cz), tip, IRON)
		b.rod("CraneBrace", 0.09, V(cx, 8.6, cz), V(cx + 1.9, 8.1, cz - 1.7), IRON)
		b.rod("CraneCable", 0.06, tip, tip - V(0, 3.3, 0), IRON)
		b.trim("CraneHook", 0.32, 0.4, 0.32, b.at(tip.X, tip.Y - 3.45, tip.Z), L.gold, M.Metal)
		local crate = b.at(tip.X, tip.Y - 4.4, tip.Z) * CFrame.Angles(0, 0.4, 0)
		b.box("CraneCrate", 1.6, 1.5, 1.6, crate, BOX)
		for _, y in { -0.5, 0.5 } do
			b.trim("CrateBand", 1.7, 0.16, 1.7, crate * CFrame.new(0, y, 0), IRON)
		end
	end

	-- THE LIGHTHOUSE -------------------------------------------------------------------------------------------
	-- f4 a beacon, then its five forms at each era's last level (f5, f10, f15, f20, f25): it takes an era's
	-- materials at the era's first level and grows at its last
	local grown = math.floor(f / 5)
	if f >= 4 then
		local y0 = 1.1 -- the foot's top
		-- (the tower's foot and shaft are a Blender body from its first real height; the beacon stays parts)
		local lit = bodied and grown >= 1
		shell(lit)
		b.cyl("LightFoot", 3.1, 3.9, b.at(LX, -1.05, LZ), if era == 4 then L.lower else L.stone)
		b.cyl("LightFootCap", 3.3, 0.3, b.at(LX, 0.95, LZ), if era >= 4 then L.gold else L.frame, bigGold, false)
		if grown == 0 then
			-- f4: a whitewashed stump a storey high, a fire basket burning on it
			b.cyl("Beacon", 2.2, 4.2, b.at(LX, y0 + 2.1, LZ), WHITE)
			b.cyl("BeaconCap", 2.45, 0.35, b.at(LX, y0 + 4.37, LZ), L.stone, nil, false)
			local fire = painted("Brazier_Fire", b.at(LX, y0 + 4.5, LZ), 0.75)
			if not fire then
				b.cyl("FireBasket", 0.9, 1, b.at(LX, y0 + 5, LZ), IRON, nil, false)
				fire = b.ball("Fire", 0.8, b.at(LX, y0 + 5.8, LZ), AMBER, M.Neon)
			end
			light(fire :: BasePart, AMBER, 22, 1)
		else
			local H = 8.5 + 2.6 * grown -- the tower's height
			local n = 4 + grown -- its drums
			local hd = H / n
			local r0, r1 = 2.5, 1.9
			local function radius(y: number): number
				return r0 + (r1 - r0) * y / H
			end
			local metal = if era >= 4 then L.gold else L.frame
			for k = 1, n do
				local colour = L.wall
				if era <= 2 then
					-- (whitewash, one red band, a second from the painted era's last level)
					colour = if k == n - 1 or (era == 2 and grown >= 2 and k == n - 3) then RED else WHITE
				elseif era <= 4 then
					colour = L.stone -- (at era 4 lighter than its hoops and ribs, or the tower is one dark pole)
				end
				-- (inside the body's taper, which is narrower than a drum at the drum's top)
				local r = radius((k - 0.5) * hd) - (if lit then 0.12 else 0)
				b.cyl("LightDrum", r, hd, b.at(LX, y0 + (k - 0.5) * hd, LZ), colour)
				if era == 4 and k < n then
					b.cyl("LightHoop", radius(k * hd) + 0.16, 0.5, b.at(LX, y0 + k * hd, LZ), L.board, M.Metal, false)
				elseif era >= 3 and k < n then
					b.cyl("LightCourse", radius(k * hd) + 0.12, 0.24, b.at(LX, y0 + k * hd, LZ), metal, bigGold, false)
				end
			end
			if era == 4 then
				-- four ribs up the steel tower, clear of the door and the window; brass rivets where the front two cross a hoop
				for _, deg in { -152, -28, 28, 152 } do
					local out = V(math.cos(math.rad(deg)), 0, math.sin(math.rad(deg)))
					local foot = V(LX, y0, LZ) + out * (r0 + 0.1)
					b.beam("LightRib", 0.3, 0.3, foot, V(LX, y0 + H, LZ) + out * (r1 + 0.1), L.board, M.Metal)
					if deg < 0 then
						for k = 1, n - 1 do
							local at = V(LX, y0 + k * hd, LZ) + out * (radius(k * hd) + 0.36)
							b.ball("LightRivet", 0.2, b.at(at.X, at.Y, at.Z), L.gold, M.Metal)
						end
					end
				end
			end
			shell(false)
			if lit then
				worn((if grown == era and era > 1 then "DockTall" else "DockLight") .. era)
			end
			-- the door, and one lit window over it
			local door = if era >= 4 then L.gold elseif era == 3 then L.board else L.beam
			b.trim(
				"LightDoorFrame",
				1.7,
				2.9,
				0.3,
				b.at(LX, y0 + 1.45, LZ - r0 + 0.02),
				if era >= 3 then L.frame else L.board
			)
			b.trim("LightDoor", 1.2, 2.5, 0.36, b.at(LX, y0 + 1.25, LZ - r0 - 0.02), door, bigGold)
			-- (the owner, 2026-11-17: "the original lighthouse has only 1 window": one, over the door, at every level)
			local wy = 2.5 * hd
			local wface = b.face(LX, y0 + wy, LZ - radius(wy) - 0.02, FRONT)
			b.window(wface, 1.3, 1.8, if era >= 4 then L.gold else L.board, AMBER, { arch = true, glow = true })
			if f >= 21 then
				banner(b.face(LX, y0 + H - 0.9, LZ - r1 - 0.2, FRONT), 1.7, 4.2)
			end
			-- the gallery: timber at the hamlet; f9 a wider railed one, in each later era's materials
			local timber = era == 1 or (era == 2 and f < 9)
			local gy = y0 + H
			local gr = r1 + (if timber then 0.8 else 1.15)
			local deck = if timber
				then LOOKS[1].beam
				elseif era == 3 then L.stone
				elseif era == 5 then L.wall
				else L.board
			local rail = if timber then LOOKS[1].board elseif era == 2 then L.beam elseif era == 3 then IRON else L.gold
			local railMat = if era >= 3 then M.Metal else nil
			b.cyl("Gallery", gr, 0.35, b.at(LX, gy + 0.17, LZ), deck, nil, false)
			for k = 0, 9 do
				local a, a2 = k * math.pi / 5, (k + 1) * math.pi / 5
				local p = V(LX + math.cos(a) * (gr - 0.15), gy + 0.35, LZ + math.sin(a) * (gr - 0.15))
				local p2 = V(LX + math.cos(a2) * (gr - 0.15), gy + 0.35, LZ + math.sin(a2) * (gr - 0.15))
				b.trim("GalleryPost", 0.2, 1.25, 0.2, b.at(p.X, p.Y + 0.62, p.Z), rail, railMat)
				b.beam("GalleryRail", 0.18, 0.18, p + V(0, 1.2, 0), p2 + V(0, 1.2, 0), rail, railMat)
				if not timber and k % 2 == 0 then
					-- (corbels: a bracket under the deck, out from the tower)
					local out = V(math.cos(a), 0, math.sin(a))
					local foot = V(LX, gy - 1, LZ) + out * (r1 + 0.05)
					b.beam("Corbel", 0.3, 0.3, foot, V(p.X, gy, p.Z), if era == 3 then L.frame else rail, railMat)
				end
			end
			-- the lantern room: panes in a frame round the lamp; from f20 twice as tall
			local tall = grown >= 4
			local lh = if tall then 4.6 else 2.5
			local lr = 1.45
			local ly = gy + 0.35
			local iron = if era >= 4
				then L.gold
				elseif era == 2 then L.board
				elseif era == 1 then LOOKS[1].board
				else IRON
			b.cyl("LampFloor", lr + 0.15, 0.3, b.at(LX, ly + 0.15, LZ), iron, railMat, false)
			local panes = b.cyl("LampGlass", lr, lh, b.at(LX, ly + 0.3 + lh / 2, LZ), PANE, M.Glass, false)
			panes.Transparency = 0.55
			for k = 0, 5 do
				local a = k * math.pi / 3
				local at = b.at(LX + math.cos(a) * lr, ly + 0.3 + lh / 2, LZ + math.sin(a) * lr)
				-- (the steel era frames its lamp in dark bars: brass ones vanished against the green)
				local bw = if era == 4 then 0.3 else 0.22
				b.trim("LampFrame", bw, lh, bw, at, if era == 4 then L.board else iron, railMat)
			end
			if era == 4 and tall then
				b.cyl("LampBelt", lr + 0.08, 0.24, b.at(LX, ly + 0.3 + lh * 0.46, LZ), L.board, M.Metal, false)
				-- f20: the goo lamp, a tall tank of green goo between the ribs (the body takes the game's light, only
				-- thin slices glow)
				b.cyl("GooLamp", 0.95, lh - 0.3, b.at(LX, ly + 0.3 + (lh - 0.3) / 2, LZ), GOO, M.SmoothPlastic, false)
				for _, t in { 0.3, 0.62, 0.94 } do
					b.cyl("GooLampGlow", 0.97, 0.22, b.at(LX, ly + 0.3 + lh * t, LZ), GOO, M.Neon, false)
				end
				light(panes, GOO, 24, 1)
			else
				local hl = if tall then 2.8 else 1.5
				b.cyl("Lamp", 0.7, hl, b.at(LX, ly + 0.5 + hl / 2, LZ), AMBER, M.Neon, false)
				light(panes, AMBER, 24, 1)
			end
			local capY = ly + 0.6 + lh
			b.cyl("LampEave", lr + 0.45, 0.3, b.at(LX, capY - 0.15, LZ), iron, railMat, false)
			local cap = b.at(LX, capY, LZ)
			if era == 1 then
				if not painted("ThatchCap_Tower", cap * CFrame.new(0, -0.2, 0), 2.1, 2.6 / 1.772, 4.2 / 1.962) then
					b.cone(cap, 2.1, 2.6, 3, L.roof)
				end
			elseif era == 2 then
				-- (a low red cap; f10: a tall cone of tile rows with a gold finial)
				coneRoof(cap, 2.15, if grown >= 2 then 4.8 else 1.8, L.roof, grown >= 2)
			elseif era == 3 then
				coneRoof(cap, 2.15, if grown >= 3 then 5.6 else 3, L.roof, grown >= 3)
			elseif era == 4 then
				-- (a small glass cap; f20: the glass-and-iron dome over the goo lamp)
				local r = if tall then 2.1 else 1.75
				if piece("GlassDome_Frame", cap, r, r, r, L.beam) then
					piece("GlassDome_Glass", cap, r, r, r, if tall then GOO else L.roof, M.Glass)
					piece("GlassDome_Finial", cap * CFrame.new(0, 0.99 * r, 0), r, r, r, L.gold)
				else
					b.ball("LightCap", r, cap, L.beam)
				end
			else
				if f >= 24 then
					-- f24: a gallery of marble columns with a gold rail round the lantern room, carrying a ring
					for k = 0, 7 do
						local a = (k + 0.5) * math.pi / 4
						local x, z = LX + math.cos(a) * (gr - 0.4), LZ + math.sin(a) * (gr - 0.4)
						b.cyl(
							"GalleryColumn",
							0.2,
							capY - gy - 0.35,
							b.at(x, (gy + 0.35 + capY) / 2, z),
							L.wall,
							nil,
							false
						)
						b.cyl("GalleryCapital", 0.3, 0.25, b.at(x, capY - 0.12, z), L.gold, M.Metal, false)
					end
					b.cyl("GalleryRing", gr + 0.1, 0.45, b.at(LX, capY + 0.22, LZ), L.wall, nil, false)
					b.cyl("GalleryRingGold", gr + 0.22, 0.16, b.at(LX, capY + 0.5, LZ), L.gold, M.Metal, false)
					cap = b.at(LX, capY + 0.55, LZ)
				end
				-- (a small blue cap; f25: the great dome on the gallery's ring)
				dome(cap, if grown >= 5 then gr - 0.1 else 1.8)
			end
		end
	end
	-- f17: a round tank of glowing goo at the lighthouse's foot (at the capital: blue glass in gold bands)
	if f >= 17 then
		local tx, tz = LX + 4.6, LZ - 2.3
		if era == 4 then
			local tank = painted("GooTank_Glass", b.at(tx, 0, tz), 1.15)
			if tank then
				light(tank, GOO, 14, 0.7)
			else
				b.silo(tx, 0, tz, 1.4, 3.6, PANE, L.board, "dome", L.board, GOO)
			end
			b.rod("TankPipe", 0.2, V(tx - 1.3, 2.6, tz + 0.6), V(LX + 2.2, 2.6, LZ - 0.6), L.accent, M.Metal)
		else
			b.silo(tx, 0, tz, 1.4, 3.6, DOME, L.gold, "dome", L.gold)
		end
	end
	-- f16: copper pipes from the lighthouse up over the vault and down to a valve at the house's right foot (the
	-- capital hangs lanterns in its portico instead: pipes do not belong on marble)
	if era == 4 and f >= 16 then
		local pz = HZ - 0.9
		local points = { V(LX - 2.2, 0, LZ), V(LX - 2.2, 0, pz) }
		for k = 1, 7 do
			local px, py = arc(hw + 0.45, top, rise + 0.45, k)
			table.insert(points, V(BX + px, py, pz))
		end
		local _, py = arc(hw + 0.45, top, rise + 0.45, 1)
		points[1] = V(LX - 2.2, py, LZ)
		points[2] = V(LX - 2.2, py, pz)
		table.insert(points, V(BX - hw - 0.45, top, pz))
		table.insert(points, V(BX - hw - 0.45, 2.6, pz))
		pipe(points, 0.22, L.accent)
		painted("PipeValve_Copper", b.face(BX - hw - 0.45, 2.3, pz + 0.3, FRONT), 0.5)
	end

	-- THE FENCE on the near bank (f3), a short run either side of the pier's foot: the pond is never closed in --------
	if f >= 3 then
		for _, s in { -1, 1 } do
			local xa = PIER_X + s * 4.7 -- the post by the pier
			local xb = xa + s * 6.4
			if era == 5 then
				balustrade(xa, xb, FZ, 0, L.fence)
			end
			for i = 0, 2 do
				local x = xa + s * i * 3.2
				local gate = i == 0
				local h = if gate then 2.5 else 1.9
				if era == 1 then
					b.cyl("FencePost", 0.3, h, b.at(x, h / 2 - 0.1, FZ), L.fence, nil, false)
					for _, y in { 0.75, 1.4 } do
						b.cyl("FenceRope", 0.36, 0.2, b.at(x, y, FZ), ROPE, nil, false)
					end
				elseif era == 2 then
					b.trim("FencePost", 0.55, h, 0.55, b.at(x, h / 2, FZ), L.beam)
				elseif era == 3 then
					b.trim("FencePier", 0.95, h, 0.95, b.at(x, h / 2, FZ), L.stone)
					b.trim("FencePierCap", 1.2, 0.25, 1.2, b.at(x, h + 0.12, FZ), L.frame)
					h += 0.25
				elseif era == 4 then
					b.trim("FencePost", 0.45, h, 0.45, b.at(x, h / 2, FZ), L.fence, M.Metal)
					b.trim("FencePostCap", 0.65, 0.2, 0.65, b.at(x, h + 0.1, FZ), L.gold, bigGold)
					h += 0.2
				elseif gate then
					b.trim("FencePier", 0.9, h, 0.9, b.at(x, h / 2, FZ), L.fence)
				else
					h = 1.3
				end
				-- f8: gold ball caps on the posts (f18: green globes), a lit lantern on the two by the pier
				if f >= 8 then
					if gate then
						local iron = if era >= 4 then L.gold elseif era == 2 then L.board else IRON
						b.trim("GateLampFoot", 0.6, 0.15, 0.6, b.at(x, h + 0.07, FZ), iron, M.Metal)
						local glass = if era == 4 and f >= 18 then GOO else AMBER
						local lantern = b.trim("GateLamp", 0.5, 0.75, 0.5, b.at(x, h + 0.52, FZ), glass, M.Neon)
						b.trim("GateLampCap", 0.8, 0.2, 0.8, b.at(x, h + 1, FZ), iron, M.Metal)
						b.ball("GateLampKnob", 0.16, b.at(x, h + 1.2, FZ), L.gold, M.Metal)
						light(lantern, glass, 12, 0.6)
					elseif era == 4 and f >= 18 then
						b.ball("FenceGlobe", 0.48, b.at(x, h + 0.4, FZ), GOO, M.Neon)
					else
						b.ball("FenceCap", 0.47, b.at(x, h + 0.36, FZ), if era == 3 then L.frame else L.gold, bigGold)
					end
				end
				if i < 2 then
					local xm = x + s * 1.6 -- the span to the next post
					if era == 1 then
						for _, y in { 0.75, 1.4 } do
							b.rod("FenceRail", 0.17, V(x, y, FZ), V(x + s * 3.2, y, FZ), L.fence)
						end
					elseif era == 2 then
						for _, y in { 0.5, 1.25 } do
							b.trim("FenceRail", 2.7, 0.16, 0.14, b.at(xm, y, FZ + 0.08), L.fence)
						end
						for k = -2, 2 do
							b.trim("Picket", 0.34, 1.5, 0.12, b.at(xm + k * 0.52, 0.85, FZ), L.fence)
						end
					elseif era == 3 then
						b.trim("FenceWall", 2.3, 0.9, 0.7, b.at(xm, 0.45, FZ), L.fence)
						b.trim("FenceCoping", 2.4, 0.2, 0.9, b.at(xm, 1, FZ), L.frame)
						b.rod("FenceRail", 0.09, V(x, 1.65, FZ), V(x + s * 3.2, 1.65, FZ), IRON)
						for k = -1, 1 do
							b.rod("FenceBar", 0.06, V(xm + k * 0.75, 1.1, FZ), V(xm + k * 0.75, 1.65, FZ), IRON)
						end
					elseif era == 4 then
						for _, y in { 0.3, 1.6 } do
							b.trim("FenceRail", 2.8, 0.2, 0.2, b.at(xm, y, FZ), L.fence, M.Metal)
						end
						if f >= 18 then
							-- f18: glowing green glass in the panels (plain glass, a thin line of light along its top)
							b.trim("FenceGlass", 2.6, 1.1, 0.12, b.at(xm, 0.95, FZ), GOO, M.Glass)
							b.trim("FenceGlow", 2.6, 0.12, 0.16, b.at(xm, 1.44, FZ), GOO, M.Neon)
						else
							for k = -2, 2 do
								b.rod(
									"FenceBar",
									0.07,
									V(xm + k * 0.5, 0.3, FZ),
									V(xm + k * 0.5, 1.6, FZ),
									L.fence,
									M.Metal
								)
							end
						end
					end
				end
			end
			-- f7: a flower box on the fence each side of the pier's foot, pink on one side and yellow on the other
			if f >= 7 then
				flowerBox(b.face(xa + s * 1.6, 1.05, FZ - 0.15, FRONT), 2.8, s > 0)
			end
			if bank >= 5 then -- 45: and an urn at each run's far end
				urn(xb + s * 1.5, 0, FZ)
			end
		end
	end

	-- THE BANK AND THE BOAT ----------------------------------------------------------------------------------
	-- 5: a fish-drying rack on the near bank, between the fence and the water
	if bank >= 1 then
		rack(b.at(5.2, 0, -15.6), 1.1)
	end
	-- 4, 14, 24, 34, 44: the boat tied to the pier, its bow out to the pond
	if boatForm >= 1 then
		boat(b.at(BOAT_X, WATER + 0.32, BOAT_Z) * CFrame.Angles(0, math.rad(172), 0), boatForm)
		b.rod("Mooring", 0.05, V(BOAT_X + 1.1, WATER + 1.15, BOAT_Z - 1), V(PIER_X - 2.6, 0.6, BOAT_Z - 0.65), ROPE)
	end
end

-- The Boathouse at its drawn size, then its house grown (Config.Village.HouseScale) and set back on the pond's far
-- shore (BACK). The fence and the boat by the pier, before SPLIT_Z, stay where they are drawn.
function Boathouse.build(m: Instance, area: CFrame, level: number)
	local had = m:GetChildren()
	raise(m, area, level)
	Architecture.grow(m, had, area, "Boathouse", SPLIT_Z, PIVOT_X, PIVOT_Z, BACK)
end

return Boathouse
