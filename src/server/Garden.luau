--!strict
-- The garden's landmark: the fenced vegetable garden, grown into a royal palm-house garden (village v2, skill
-- landmark-build; the owner approved the reference on 2026-11-17: docs/areas/village-v2/garden-ref-sheet.jpg, the
-- ladder is garden-ladder.md beside it). One garden in five architectures, one an era of ten levels:
--   1 hamlet       woven wattle, thatch on brown posts, a cream plaster gable, a fieldstone well under a trestle
--   2 painted      cream pickets on teal posts, cream plaster on teal beams, red clay tiles, a red brick tower foot
--   3 town         a low stone wall with timber rails, a stone orangery under a half-timbered storey, a round mill
--   4 slime tech   black steel and teal glass, a vaulted greenhouse, copper pipes, green goo, a steel wind wheel
--   5 capital      white marble and gold, columns and a pediment, blue glass domes, blue and gold sails
-- The same four things at every era, in the same places, so it stays one garden: THE FENCE round it with THE GATE in
-- the middle of its front (-z); THE GARDEN HOUSE across the back (front wall at HZ), hollow, its front wide open so
-- the pots, tools and seed sacks are seen from outside; THE WATER TOWER in the back left corner as one walks in (+x),
-- the tallest thing once its trestle stands, its wheel turning (a "Turn" model, client/WindTurn). The two beds, the
-- crops and the work spots between them are the area's own and stay GardenStages' business. Everything is in the
-- area's frame: the lawn's top is y 0, the garden's floor FLOOR.
-- An era's first level changes the architecture; levels 6-10 of each era add one feature each, and a feature once
-- added stays in every later era in that era's materials (25 in all, numbered in `build` as in the ladder).
local CollectionService = game:GetService("CollectionService")

local Architecture = require(script.Parent.Architecture)
local LibraryKit = require(script.Parent.LibraryKit)

local Garden = {}

local C = Color3.fromRGB
local M = Enum.Material
local IRON = C(60, 60, 66)
local DARK = C(42, 34, 30)
local PLANK = C(176, 128, 78)
local BOX = C(128, 84, 50)
local LEAF = C(86, 160, 70)
local VINE = C(60, 128, 58)
local STRAW = C(204, 156, 62) -- the darker course half way up a thatch (ChatGPT's review: flat thatch reads as a lid)
local POT = C(196, 112, 74)
local SACK = C(206, 178, 128)
local WATER = C(96, 170, 220)
local GRAPE = C(126, 78, 160)
local GLAZE = C(190, 232, 226) -- a cold frame's panes
local GOO = C(96, 232, 70)
local DOME = C(70, 124, 214) -- the capital's blue glass
local BLOOMS = { C(255, 120, 150), C(255, 214, 80), C(240, 90, 80) }
local FRONT, BACK = Vector3.new(0, 0, -1), Vector3.new(0, 0, 1)
local LEFT, RIGHT = Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0) -- (+x is the garden's left as one walks in)

local FLOOR = 0.2 -- the garden floor's top
local FX, FZ0, FZ1 = 18, -12, 28.5 -- the fence: x -FX..FX, z FZ0..FZ1
local PX = 3.3 -- the gate's posts stand at x -PX and PX
local HZ = 18.5 -- the garden house's front wall
local TX, TZ = 14.6, 24 -- the water tower's middle
local BEDX = 8.5 -- the middle of a bed (they lie at x -BEDX and BEDX, z -0.3..11.7)
local T = 0.6 -- a wall's thickness

type Look = {
	hw: number, -- half the house's width (its nave at era 4, its hall at era 5)
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
	sail: Color3,
	mats: { [string]: Enum.Material },
}

local LOOKS: { Look } = {
	{ -- 1 hamlet
		hw = 5.4,
		depth = 6.8,
		wallH = 6.2,
		rise = 4.2,
		wall = C(236, 220, 180),
		lower = C(170, 120, 72),
		stone = C(150, 146, 138),
		beam = C(110, 72, 42),
		board = C(92, 60, 36),
		roof = C(232, 190, 84),
		frame = C(126, 84, 50),
		glass = C(255, 214, 120),
		shutters = C(120, 150, 96),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		accent = C(70, 66, 62),
		fence = C(190, 146, 88),
		sail = C(150, 104, 62),
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
			sail = M.WoodPlanks,
		},
	},
	{ -- 2 painted
		hw = 6.5,
		depth = 7,
		wallH = 6.8,
		rise = 4.8,
		wall = C(244, 238, 224),
		lower = C(190, 92, 66),
		stone = C(232, 222, 200),
		beam = C(40, 128, 130),
		board = C(32, 104, 108),
		roof = C(198, 70, 58),
		frame = C(250, 246, 236),
		glass = C(250, 198, 100), -- (deeper than the Kitchen's: lit Neon panes washed out to white in daylight)
		shutters = C(56, 146, 146),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		accent = C(110, 72, 42),
		fence = C(250, 246, 236),
		sail = C(236, 220, 184),
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
			sail = M.SmoothPlastic, -- (not Fabric: its dark weave turns cream cloth slate grey)
		},
	},
	{ -- 3 town
		hw = 7.2,
		depth = 8,
		wallH = 6.8,
		rise = 4.6,
		wall = C(240, 230, 206),
		lower = C(198, 190, 174),
		stone = C(128, 124, 118),
		beam = C(112, 72, 44),
		board = C(92, 60, 38),
		roof = C(172, 64, 52),
		frame = C(222, 216, 202),
		glass = C(250, 198, 100),
		shutters = C(120, 150, 96),
		cloth = C(52, 96, 190),
		gold = C(236, 190, 70),
		accent = C(112, 72, 44),
		fence = C(112, 72, 44),
		sail = C(176, 128, 78),
		mats = {
			wall = M.Plaster,
			lower = M.Brick,
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
		hw = 5.4,
		depth = 8.5,
		wallH = 9.4,
		rise = 5.4,
		wall = C(150, 225, 215),
		lower = C(198, 112, 74),
		stone = C(74, 80, 92),
		beam = C(52, 56, 64),
		board = C(40, 44, 50),
		roof = C(120, 222, 205),
		frame = C(214, 208, 196),
		glass = C(250, 202, 108),
		shutters = C(40, 44, 50),
		cloth = C(40, 80, 160),
		gold = C(224, 170, 70),
		accent = C(226, 132, 78), -- (bright: Metal darkens it, and a duller copper read as brown wood)
		fence = C(40, 44, 50),
		sail = C(120, 126, 136),
		mats = {
			wall = M.Glass,
			lower = M.Brick,
			stone = M.Slate,
			beam = M.Metal,
			board = M.Metal,
			roof = M.Glass,
			frame = M.Limestone,
			gold = M.Metal,
			accent = M.Metal,
			sail = M.Metal,
		},
	},
	{ -- 5 capital
		hw = 5.5,
		depth = 9,
		wallH = 9,
		rise = 3.2,
		wall = C(250, 249, 245),
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
		accent = C(206, 128, 72),
		fence = C(250, 249, 245),
		sail = C(40, 70, 160),
		mats = {
			wall = M.Marble,
			stone = M.Marble,
			beam = M.Marble,
			roof = M.Slate,
			gold = M.Foil,
			accent = M.Metal,
		},
	},
}

-- A level's era (1-5) and how many of the 25 features it has.
function Garden.features(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	return era, (era - 1) * 5 + math.max(0, s - 5)
end

-- The ground the garden stands on and its sails sweep over (x0, x1, z0, z1): scenery there goes.
function Garden.footprint(_level: number): (number, number, number, number)
	return -FX - 1.5, FX + 6.5, FZ0 - 3, FZ1 + 1.5
end

-- The garden's fence (half its width, its front, its back): GardenStages lays the floor to it.
function Garden.fence(): (number, number, number)
	return FX, FZ0, FZ1
end

function Garden.build(m: Instance, frame: CFrame, level: number)
	local era, f = Garden.features(level)
	local L = LOOKS[era]
	local skins: { [string]: Enum.Material } = {
		[IRON:ToHex()] = M.Metal,
		[PLANK:ToHex()] = M.WoodPlanks,
		[BOX:ToHex()] = M.Wood,
		[LEAF:ToHex()] = M.LeafyGrass,
		[VINE:ToHex()] = M.LeafyGrass,
		[POT:ToHex()] = M.SmoothPlastic,
		[SACK:ToHex()] = M.Fabric,
		[GRAPE:ToHex()] = M.SmoothPlastic,
	}
	for field, material in L.mats do
		skins[((L :: any)[field] :: Color3):ToHex()] = material
	end
	local b = Architecture.new(m, frame, skins, 0.4)
	local hw, depth, wallH, rise = L.hw, L.depth, L.wallH, L.rise
	local top = FLOOR + wallH -- the house walls' top
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
	-- the capital's dome of blue glass, `r` round, on its drum's top at `cf`: golden ribs, a lantern and a finial
	local function dome(cf: CFrame, r: number)
		if piece("RoyalDome_Gold", cf, r, r, r, L.gold, M.Metal) then
			piece("RoyalDome_Shell", cf, r, r, r, DOME, M.Glass)
		else
			b.ball("Dome", r, cf, DOME, M.Glass)
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
	-- a balustrade from (xa, za) to (xb, zb), its foot at `y`: a post about every four studs (`first` and `last`
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
		local run = Vector3.new(xb - xa, 0, zb2 - za)
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
			light(pane, L.glass, 14, 0.6)
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
	-- a pipe through `points` (in the garden's frame), a fitting at every bend and at its end
	local function pipe(points: { Vector3 }, r: number, colour: Color3)
		for i = 1, #points - 1 do
			b.rod("Pipe", r, points[i], points[i + 1], colour)
			local p = points[i + 1]
			b.ball("PipeJoint", r * 1.5, b.at(p.X, p.Y, p.Z), L.gold, bigGold)
		end
	end
	-- ARCHES, round the garden's middle line (x 0): point `k` of eight on a half ring `half` wide and `R` high
	-- over `spring`
	local function arc(half: number, spring: number, R: number, k: number): (number, number)
		local a = math.rad(k * 22.5)
		return half * math.cos(a), spring + R * math.sin(a)
	end
	-- the wall over an arched opening, from the arch up to `y1` (the wall beside the opening is the caller's)
	local function archWall(
		name: string,
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
				slab(name, s * qx, s * px, qy, y1, z - thick / 2, z + thick / 2, colour, material)
				-- (a wedge upside down: flat on top, its slope along the arch)
				b.wedge(
					name,
					thick,
					qy - py,
					px - qx,
					frame
						* CFrame.fromMatrix(
							Vector3.new(s * (px + qx) / 2, (py + qy) / 2, z),
							Vector3.new(0, 0, s),
							Vector3.new(0, -1, 0),
							Vector3.new(s, 0, 0)
						),
					colour,
					material
				)
			end
		end
	end
	-- the filling under an arch, from `spring` up to the arch: a glass fan
	local function fan(half: number, spring: number, R: number, z: number, colour: Color3, material: Enum.Material?)
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				local px, py = arc(half, spring, R, k)
				local qx, qy = arc(half, spring, R, k + 1)
				slab("Fan", s * qx, s * px, spring, py, z - 0.08, z + 0.08, colour, material)
				b.wedge(
					"Fan",
					0.16,
					qy - py,
					px - qx,
					frame
						* CFrame.fromMatrix(
							Vector3.new(s * (px + qx) / 2, (py + qy) / 2, z),
							Vector3.new(0, 0, s),
							Vector3.new(0, 1, 0),
							Vector3.new(-s, 0, 0)
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
					Vector3.new(s * px, py, z),
					Vector3.new(s * qx, qy, z),
					if colour2 and k % 2 == 1 then colour2 else colour,
					material
				)
			end
		end
	end

	-- THE FENCE ------------------------------------------------------------------------------------------------
	-- One run from (xa, za) to (xb, zb2); the runs go round the garden so its inside is on a run's own +Z. `first`
	-- and `last` say whether its two ends get a post (a corner has one from the run before, the gate its own).
	local function fence(xa: number, za: number, xb: number, zb2: number, first: boolean, last: boolean, urns: boolean)
		local run = Vector3.new(xb - xa, 0, zb2 - za)
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
	fence(gx, FZ0, FX, FZ0, false, true, true)
	fence(FX, FZ0, FX, FZ1, false, true, false)
	fence(FX, FZ1, -FX, FZ1, false, true, false)
	fence(-FX, FZ1, -FX, FZ0, false, true, false)
	fence(-FX, FZ0, -gx, FZ0, false, false, true)
	if f >= 6 then
		-- 6 flower boxes along the front fence on both sides of the gate (the owner's Meshy trough; gold urns of
		-- flowers at the capital); the map's own garden sign stands at x -9 in this row, where a fourth would be
		for _, x in { -13.2, 7.8, 13.2 } do
			if era == 5 then
				if not painted("FlowerUrn_Gold", b.at(x, 0, FZ0 - 1.5), 0.9) then
					b.cyl("FlowerUrn", 0.9, 1.6, b.at(x, 0.8, FZ0 - 1.5), L.gold, bigGold, false)
					b.ball("Flower", 1, b.at(x, 2.2, FZ0 - 1.5), BLOOMS[1])
				end
			elseif not painted("FlowerBox_Trough", b.at(x, 0, FZ0 - 1.3), 1) then
				flowerBox(b.face(x, 1, FZ0 - 0.5, FRONT), 3.6)
			end
		end
	end

	-- THE GATE -------------------------------------------------------------------------------------------------
	if era <= 2 then
		-- two posts; 1 a little roof over them (thatch, then tiles) and a lantern on each
		local h = 6.2
		for _, s in { -1, 1 } do
			b.box("GatePad", 1.3, 0.5, 1.3, b.at(s * PX, FLOOR + 0.25, FZ0), L.stone)
			b.box("GatePost", 0.9, h - 0.5, 0.9, b.at(s * PX, FLOOR + 0.5 + (h - 0.5) / 2, FZ0), L.beam)
			if f >= 1 then
				b.beam(
					"GateBrace",
					0.4,
					0.4,
					Vector3.new(s * (PX - 0.3), FLOOR + h - 2.1, FZ0),
					Vector3.new(s * (PX - 1.7), FLOOR + h - 0.6, FZ0),
					L.board
				)
				lamp(b.face(s * PX, FLOOR + 3.7, FZ0 - 0.45, FRONT), 0.8, true)
			else
				b.ball("GateKnob", 0.5, b.at(s * PX, FLOOR + h + 0.3, FZ0), L.beam)
			end
		end
		if f >= 1 then
			b.box("GateBeam", PX * 2 + 1.8, 0.6, 0.7, b.at(0, FLOOR + h - 0.3, FZ0), L.beam)
			-- (3 deep, not 3.6: the gate's roof must not outweigh the house behind it)
			local up, span, over = if era == 1 then 1.6 else 1.9, 3, 0.5
			b.gable(
				b.at(0, FLOOR + h, FZ0),
				PX * 2 + 1.6,
				span,
				up,
				over,
				L.roof,
				L.board,
				L.board,
				nil,
				if era == 1 then 0.55 else nil
			)
			if era == 1 then
				-- (thatch: a roll along each eave and the ridge, a darker course half way up each slope)
				local reach = PX + 1.3
				local ey = FLOOR + h - up / (span / 2) * over - 0.2
				local cy = FLOOR + h + up - up / (span / 2) * (span / 2 + over) / 2
				for _, s in { -1, 1 } do
					local z = FZ0 + s * (span / 2 + over)
					b.rod("EaveRoll", 0.38, Vector3.new(-reach, ey, z), Vector3.new(reach, ey, z), L.roof)
					z = FZ0 + s * (span / 2 + over) / 2
					b.rod("ThatchCourse", 0.26, Vector3.new(-reach, cy, z), Vector3.new(reach, cy, z), STRAW, M.Sand)
				end
				b.rod(
					"RidgeRoll",
					0.45,
					Vector3.new(-reach - 0.1, FLOOR + h + up + 0.1, FZ0),
					Vector3.new(reach + 0.1, FLOOR + h + up + 0.1, FZ0),
					L.roof
				)
			end
		end
	elseif era == 3 then
		-- stone pillars under a timber lintel and a little tiled roof, a lantern on each
		local px = PX + 0.3
		for _, s in { -1, 1 } do
			b.box("GatePierFoot", 2.1, 0.6, 2.1, b.at(s * px, FLOOR + 0.3, FZ0), L.stone)
			b.box("GatePier", 1.7, 5.2, 1.7, b.at(s * px, FLOOR + 3.2, FZ0), L.lower)
			b.box("GatePierCap", 2.1, 0.4, 2.1, b.at(s * px, FLOOR + 6, FZ0), L.frame)
			lamp(b.face(s * px, FLOOR + 3.9, FZ0 - 0.85, FRONT), 0.8, true)
		end
		b.box("GateBeam", px * 2 + 2.6, 0.7, 0.9, b.at(0, FLOOR + 6.55, FZ0), L.beam)
		b.gable(b.at(0, FLOOR + 6.9, FZ0), px * 2 + 2.4, 3, 1.9, 0.5, L.roof, L.board, L.board)
	else
		-- piers under an arch: steel and teal glass, then marble and gold with a gold crown; a lantern on each
		local px, h = PX + 0.3, 4.6
		local spring, R = FLOOR + h + 0.4, PX + 0.3
		for _, s in { -1, 1 } do
			b.box("GatePierFoot", 2.2, 0.6, 2.2, b.at(s * px, FLOOR + 0.3, FZ0), L.stone)
			b.box(
				"GatePier",
				1.8,
				h - 0.6,
				1.8,
				b.at(s * px, FLOOR + 0.6 + (h - 0.6) / 2, FZ0),
				if era == 4 then L.lower else L.wall
			)
			b.box(
				"GatePierCap",
				2.2,
				0.4,
				2.2,
				b.at(s * px, FLOOR + h + 0.2, FZ0),
				if era == 4 then L.frame else L.gold,
				bigGold
			)
			lamp(b.face(s * px, FLOOR + 3.9, FZ0 - 0.9, FRONT), 0.65, true)
			if f >= 19 then
				-- 19 blue banners on the gate piers
				if not painted("Banner_SlimeBlue", b.face(s * px, FLOOR + 2, FZ0 - 0.9, FRONT), 0.48) then
					b.banner(b.face(s * px, FLOOR + 3.1, FZ0 - 0.9, FRONT), 1.3, 2, L.cloth, L.gold)
				end
			end
		end
		if era == 4 then
			archRing("GateArch", R + 0.45, spring, R + 0.45, FZ0, 0.6, 0.3, L.beam)
			archRing("GateArch", R - 0.45, spring, R - 0.45, FZ0, 0.6, 0.3, L.beam)
			archRing("GateGlass", R, spring, R, FZ0, 0.16, 0.7, L.wall)
			for k = 1, 7 do
				local ax, ay = arc(R - 0.45, spring, R - 0.45, k)
				local bx, by = arc(R + 0.45, spring, R + 0.45, k)
				b.rod("GateArchBar", 0.1, Vector3.new(ax, ay, FZ0), Vector3.new(bx, by, FZ0), L.beam)
			end
			if f >= 17 then
				-- 17 a brass gear wheel on the gate arch (a dark plate behind it: brass on glass does not read)
				local face = b.face(0, spring + R + 0.3, FZ0 - 0.35, FRONT)
				b.disc("GearPlate", 1.5, 0.2, face * CFrame.new(0, 0, 0.05), DARK, M.Metal)
				if not piece("Gear_Wheel", face * CFrame.new(0, 0, -0.3), 1.35, 1.35, 0.8, L.gold, M.Metal) then
					b.disc("Gear", 1.2, 0.3, face * CFrame.new(0, 0, -0.2), L.gold, M.Metal)
					for k = 0, 7 do
						b.trim(
							"GearTooth",
							0.45,
							0.5,
							0.3,
							face * CFrame.Angles(0, 0, k * math.pi / 4) * CFrame.new(0, 1.3, -0.2),
							L.gold,
							M.Metal
						)
					end
				end
			end
		else
			archRing("GateArch", R, spring, R, FZ0, 1.2, 0.9, L.wall)
			archRing("GateArchGold", R + 0.5, spring, R + 0.5, FZ0, 1.3, 0.16, L.gold)
			archRing("GateArchGold", R - 0.5, spring, R - 0.5, FZ0, 1.3, 0.16, L.gold)
			b.trim("GateKeystone", 0.9, 1.3, 1.4, b.at(0, spring + R, FZ0), L.gold, M.Metal)
			local crown = b.at(0, spring + R + 0.6, FZ0)
			-- (0.85, not 1.1: the crown must not draw the eye from the palm house's dome)
			if not piece("ChimneyCrown_Gold", crown, 0.85, 0.85, 0.85, L.gold, M.Metal) then
				b.cyl("GateCrown", 0.85, 0.5, crown * CFrame.new(0, 0.25, 0), L.gold, M.Metal, false)
				for k = 0, 5 do
					local a = k * math.pi / 3
					local at = crown * CFrame.new(0.78 * math.cos(a), 0.7, 0.78 * math.sin(a))
					b.ball("GateCrownPoint", 0.2, at, L.gold, M.Metal)
				end
			end
		end
	end

	if f >= 11 then
		-- 11 a pergola behind the gate, heavy with vines and grapes, over the path to the beds (timber, then
		-- steel, then marble posts under gold beams)
		local ph = FLOOR + 5.7
		local post = if era == 5 then L.wall else L.beam
		local bar = if era == 5 then L.gold else L.beam
		for _, s in { -1, 1 } do
			for _, z in { -9.9, -6.9, -3.9 } do
				if era == 5 then
					b.cyl("PergolaPost", 0.34, ph - FLOOR, b.at(s * 2.9, (FLOOR + ph) / 2, z), post)
				else
					b.box("PergolaPost", 0.55, ph - FLOOR, 0.55, b.at(s * 2.9, (FLOOR + ph) / 2, z), post)
				end
			end
			b.trim("PergolaBeam", 0.45, 0.5, 7.4, b.at(s * 2.9, ph + 0.25, -6.9), bar)
			-- (the owner's Meshy trellis of ivy closes each side)
			for _, z in { -8.4, -5.4 } do
				painted("Trellis_Ivy", b.face(s * 3.15, FLOOR + 2.3, z, Vector3.new(s, 0, 0)), 0.6, 0.3)
			end
		end
		for i = 0, 6 do
			b.trim("PergolaRafter", 7.6, 0.4, 0.3, b.at(0, ph + 0.7, -10.2 + i * 1.1), bar)
		end
		-- (round clumps of leaves, not flat slabs: a slab read as a mossy lid from the play camera; six light
		-- clumps with the rafters showing between them: nine dark ones read as shrubs standing beside the beds)
		for i, p in
			{
				{ -2.4, -9.5, 1.1 },
				{ 2.2, -9, 1.2 },
				{ -0.2, -7.1, 1.05 },
				{ 2.7, -6.2, 0.9 },
				{ -2.5, -4.9, 1.2 },
				{ 1.6, -4.1, 1.05 },
			}
		do
			b.ball(
				"PergolaLeaves",
				p[3],
				b.at(p[1], ph + 0.85 + (i % 3) * 0.12, p[2]),
				if i % 2 == 0 then LEAF else LEAF:Lerp(VINE, 0.45),
				M.Grass
			)
		end
		for i, p in { { -1.7, -9 }, { 1.5, -7.6 }, { -1.2, -5.9 }, { 1.9, -4.6 } } do
			local x, z = p[1], p[2]
			b.ball("Grapes", 0.3, b.at(x, ph + 0.2, z), GRAPE)
			b.ball("Grapes", 0.27, b.at(x + 0.12, ph - 0.15, z + 0.1), GRAPE)
			b.ball("Grapes", 0.2, b.at(x - 0.05, ph - 0.45, z), GRAPE)
			b.ball("GrapeLeaf", 0.28, b.at(x + (if i % 2 == 0 then 0.3 else -0.3), ph + 0.35, z), LEAF)
		end
	end

	if f >= 9 then
		-- 9 two round clipped bushes in pots where the path reaches the house (the owner's Meshy bush pot; the
		-- rose arch that stood here went at his word, 2026-11-17: it did not fit this garden)
		for _, s in { -1, 1 } do
			local cf = b.at(s * 3.2, FLOOR, HZ - 3.6)
			if not painted("BushPot_Round", cf, 1.1) then
				b.cyl("BushPot", 0.8, 1.1, cf * CFrame.new(0, 0.55, 0), POT, nil, false)
				b.ball("Bush", 1.2, cf * CFrame.new(0, 2.2, 0), LEAF, M.Grass)
			end
		end
	end

	-- THE GARDEN HOUSE -----------------------------------------------------------------------------------------
	-- what is seen through the open front, against the back wall at `zBack` on the floor `y`: shelves of pots over
	-- a potting bench, the tools on their board, seed sacks, a warm light at `lightY`
	local function interior(half: number, zBack: number, y: number, lightY: number)
		local z = zBack - 0.45
		for i, h in { 2.4, 3.7 } do
			b.trim("Shelf", half - 0.6, 0.18, 0.8, b.at(half / 2, y + h, z), PLANK)
			for k = 1, 3 do
				local x = half / 2 + (k - 2) * (half - 1.6) / 3
				b.cyl("Pot", 0.3, 0.45, b.at(x, y + h + 0.32, z), POT, nil, false)
				b.ball(
					"PotPlant",
					0.36,
					b.at(x, y + h + 0.82, z),
					if (i + k) % 2 == 0 then LEAF else BLOOMS[(i + k) % 3 + 1]
				)
			end
		end
		b.trim("Bench", half - 0.6, 0.22, 1.3, b.at(half / 2, y + 1.2, z - 0.2), PLANK)
		for _, s in { -1, 1 } do
			b.trim("BenchLeg", 0.25, 1.1, 1.1, b.at(half / 2 + s * (half / 2 - 0.5), y + 0.55, z - 0.2), BOX)
		end
		b.cyl("Pot", 0.42, 0.6, b.at(half / 2 - 0.6, y + 1.6, z - 0.3), POT, nil, false)
		b.ball("PotPlant", 0.5, b.at(half / 2 - 0.6, y + 2.2, z - 0.3), LEAF)
		local bx = -half / 2
		b.trim("ToolBoard", half - 0.8, 2.6, 0.16, b.at(bx, y + 2.9, zBack - 0.1), PLANK)
		for k = -1, 1 do
			local x = bx + k * (half - 1.8) / 3
			b.rod("ToolHandle", 0.08, Vector3.new(x, y + 2, zBack - 0.3), Vector3.new(x, y + 4, zBack - 0.3), BOX)
			b.trim("ToolHead", if k == 0 then 0.55 else 0.42, 0.55, 0.1, b.at(x, y + 1.8, zBack - 0.3), IRON)
		end
		b.ball("SeedSack", 0.68, b.at(bx - 0.7, y + 0.6, zBack - 1.3), SACK)
		b.ball("SeedSack", 0.68, b.at(bx + 0.6, y + 0.6, zBack - 1.6), SACK)
		b.ball("SeedSack", 0.55, b.at(bx, y + 1.5, zBack - 1.45), SACK)
		b.rod(
			"LightCord",
			0.05,
			Vector3.new(0, lightY + 0.9, zBack - depth / 2),
			Vector3.new(0, lightY, zBack - depth / 2),
			IRON
		)
		light(b.ball("HouseLight", 0.32, b.at(0, lightY, zBack - depth / 2), L.glass, M.Neon), L.glass, 18, 0.6)
	end
	-- a tiled roof over x -half..half, z z0..z1 from `y`: its ridge across the garden, a gable over the door facing
	-- the front (`cross` wide, `crossUp` high) with a shuttered window; 6 a flower box under that window
	local function tiledRoof(
		y: number,
		half: number,
		z0: number,
		z1: number,
		up: number,
		cross: number,
		crossUp: number
	)
		local mid = (z0 + z1) / 2
		b.gable(b.at(0, y, mid), half * 2, z1 - z0, up, 0.9, L.roof, L.wall, L.board)
		for _, s in { -1, 1 } do
			local face = b.face(s * half, y, mid, Vector3.new(s, 0, 0)) * CFrame.new(0, 0, -0.1)
			b.trim("GablePost", 0.4, up - 1, 0.2, face * CFrame.new(0, (up - 1) / 2, 0), L.beam)
			b.trim("GableRail", (z1 - z0) * 0.5, 0.35, 0.2, face * CFrame.new(0, up * 0.42, 0), L.beam)
		end
		local len = (z1 - z0) / 2 + 0.3
		b.gable(b.at(0, y, z0 + len / 2) * turn, len, cross, crossUp, 0.6, L.roof, L.wall, L.board, nil, nil, 1)
		local face = b.face(0, y, z0, FRONT)
		b.trim("GableRail", cross, 0.45, 0.25, face * CFrame.new(0, 0.05, -0.1), L.beam)
		if not painted("Window_Shutters", face * CFrame.new(0, crossUp * 0.42, 0), 0.5, 0.3) then
			b.window(
				face * CFrame.new(0, crossUp * 0.42, 0),
				1.3,
				1.4,
				L.frame,
				L.glass,
				{ shutters = L.shutters, glow = true }
			)
		end
		if f >= 6 then
			flowerBox(face * CFrame.new(0, 0.5, 0), 2.6, true)
		end
	end
	-- 7 a dormer with a lit window on the front slope of a roof that starts at `y` over the wall at z `z0` (the
	-- owner's Meshy dormer)
	local function dormer(x: number, y: number, z0: number, pitch: number)
		-- its face stands half a stud up the slope, its back ends where the slope reaches its own roof: a steep roof
		-- makes a short dormer, and none of it is buried
		local zf, yb = z0 + 0.5, y + pitch * 0.5 - 0.15
		local zk = z0 + (yb + 2 - y) / pitch
		local lit = painted("Dormer_RedRoof", b.face(x, yb + 1.25, zk, FRONT), 0.5, (zk - zf) / 5.619)
		if not lit then
			b.box("Dormer", 2.2, 1.6, zk - zf, b.at(x, yb + 0.8, (zf + zk) / 2), L.wall)
			b.gable(
				b.at(x, yb + 1.6, (zf + zk) / 2) * turn,
				zk - zf + 0.4,
				2.4,
				0.9,
				0.3,
				L.roof,
				L.wall,
				L.board,
				nil,
				nil,
				1
			)
			b.window(b.face(x, yb + 0.9, zf, FRONT), 1.2, 1.2, L.frame, L.glass, { glow = true })
		else
			light(lit, L.glass, 10, 0.5)
		end
	end

	if era == 1 then
		-- A POTTING SHED: plank and plaster walls framed in timber, thatch, its whole front open between two posts
		local sill = FLOOR + 2.4
		slab("HouseFloor", -hw - 0.4, hw + 0.4, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, PLANK)
		for _, s in { -1, 1 } do
			slab("SideWall", s * (hw - T), s * hw, FLOOR, sill, HZ + 0.8, zb, L.lower)
			slab("SideWall", s * (hw - T), s * hw, sill, top, HZ + 0.8, zb, L.wall)
			b.timber(
				b.face(s * hw, (FLOOR + top) / 2, (HZ + 0.8 + zb) / 2, Vector3.new(s, 0, 0)),
				depth - 0.8,
				wallH,
				L.beam
			)
			b.box("PostPad", 1.3, 0.5, 1.3, b.at(s * (hw - 0.4), FLOOR + 0.25, HZ + 0.4), L.stone)
			b.box(
				"Post",
				0.8,
				wallH - 0.5,
				0.8,
				b.at(s * (hw - 0.4), FLOOR + 0.5 + (wallH - 0.5) / 2, HZ + 0.4),
				L.beam
			)
			b.beam(
				"Brace",
				0.4,
				0.4,
				Vector3.new(s * (hw - 0.6), top - 2.5, HZ + 0.4),
				Vector3.new(s * (hw - 2.2), top - 0.75, HZ + 0.4),
				L.board
			)
		end
		slab("BackWall", -hw, hw, FLOOR, sill, zb - T, zb, L.lower)
		slab("BackWall", -hw, hw, sill, top, zb - T, zb, L.wall)
		b.timber(b.face(0, (FLOOR + top) / 2, zb, BACK), hw * 2, wallH, L.beam)
		b.box("TieBeam", hw * 2 + 1, 0.7, 0.8, b.at(0, top - 0.35, HZ + 0.4), L.beam)
		-- the roof: its gable faces the front, open as a truss until 2 closes it
		local open = f < 2
		local over = 1
		local pitch = rise / hw
		b.gable(
			b.at(0, top, zc) * turn,
			depth,
			hw * 2,
			rise,
			over,
			L.roof,
			L.wall,
			L.board,
			nil,
			0.6,
			if open then -1 else nil
		)
		local ey = top - pitch * over - 0.25
		local cy = top + rise - pitch * (hw + over) / 2
		for _, s in { -1, 1 } do
			local x = s * (hw + over)
			b.rod("EaveRoll", 0.5, Vector3.new(x, ey, HZ - over), Vector3.new(x, ey, zb + over), L.roof)
			-- (a darker course half way up the slope: the thatch reads as laid in layers)
			b.rod(
				"ThatchCourse",
				0.34,
				Vector3.new(x / 2, cy, HZ - over),
				Vector3.new(x / 2, cy, zb + over),
				STRAW,
				M.Sand
			)
		end
		b.rod(
			"RidgeRoll",
			0.65,
			Vector3.new(0, top + rise + 0.1, HZ - over - 0.1),
			Vector3.new(0, top + rise + 0.1, zb + over + 0.1),
			L.roof
		)
		if open then
			for _, s in { -1, 1 } do
				b.beam(
					"Rafter",
					0.5,
					0.5,
					Vector3.new(s * hw, top, HZ + 0.3),
					Vector3.new(0, top + rise - 0.35, HZ + 0.3),
					L.beam
				)
				-- (the barge boards the roof's own gable end would have had)
				b.beam(
					"BargeBoard",
					0.25,
					0.9,
					Vector3.new(s * (hw + over), top - pitch * over - 0.3, HZ - over - 0.05),
					Vector3.new(0, top + rise - 0.3, HZ - over - 0.05),
					L.board
				)
			end
			b.box("KingPost", 0.5, rise - 0.7, 0.5, b.at(0, top + (rise - 0.7) / 2, HZ + 0.3), L.beam)
			b.box("Collar", hw, 0.4, 0.4, b.at(0, top + rise * 0.5, HZ + 0.3), L.beam)
		else
			-- 2 the gable closed with cream plaster and a shuttered window, big lanterns on the two front posts
			local face = b.face(0, top + 1.5, HZ, FRONT)
			if not painted("Window_Shutters", face, 0.55, 0.3) then
				b.window(face, 1.5, 1.5, L.frame, L.glass, { shutters = L.shutters, glow = true })
			end
			b.trim(
				"GableRail",
				hw * 2 - 0.4,
				0.4,
				0.25,
				b.face(0, top + 0.2, HZ, FRONT) * CFrame.new(0, 0, -0.1),
				L.beam
			)
			for _, s in { -1, 1 } do
				lamp(b.face(s * (hw - 0.4), FLOOR + 3.9, HZ, FRONT), 1, true)
			end
		end
		if f >= 3 then
			-- 3 a straw lean-to on the shed's side over a potting bench, herbs hung to dry (high at the wall, low at
			-- its posts)
			local x1, x2 = -hw, -hw - 3.6
			local lz0, lz1 = HZ + 1, zb - 0.4
			local lzc = (lz0 + lz1) / 2
			b.beam(
				"LeanRoof",
				lz1 - lz0 + 0.8,
				0.5,
				Vector3.new(x1 + 0.1, FLOOR + 4.9, lzc),
				Vector3.new(x2 - 0.6, FLOOR + 3.5, lzc),
				L.roof
			).CastShadow =
				true
			b.rod(
				"EaveRoll",
				0.42,
				Vector3.new(x2 - 0.6, FLOOR + 3.4, lz0 - 0.4),
				Vector3.new(x2 - 0.6, FLOOR + 3.4, lz1 + 0.4),
				L.roof
			)
			for _, z in { lz0, lz1 } do
				b.box("LeanPost", 0.5, 3.3, 0.5, b.at(x2, FLOOR + 1.65, z), L.beam)
			end
			b.box("LeanPlate", 0.45, 0.45, lz1 - lz0 + 0.5, b.at(x2, FLOOR + 3.5, lzc), L.beam)
			b.trim("Bench", 2.2, 0.22, lz1 - lz0 - 0.8, b.at(x1 - 1.4, FLOOR + 1.3, lzc), PLANK)
			for _, z in { lz0 + 0.7, lz1 - 0.7 } do
				b.trim("BenchLeg", 2, 1.2, 0.25, b.at(x1 - 1.4, FLOOR + 0.6, z), BOX)
			end
			for k = 0, 2 do
				local z = lz0 + 1 + k * (lz1 - lz0 - 2) / 2
				b.cyl("Pot", 0.34, 0.5, b.at(x1 - 1.4, FLOOR + 1.66, z), POT, nil, false)
				b.ball("PotPlant", 0.42, b.at(x1 - 1.4, FLOOR + 2.2, z), if k == 1 then BLOOMS[2] else LEAF)
				b.trim("Herbs", 0.35, 0.8, 0.35, b.at(x2 + 0.1, FLOOR + 2.85, z), if k == 1 then VINE else LEAF)
			end
		end
		interior(hw - T, zb - T, FLOOR + 0.2, top + 0.4)
	elseif era == 2 then
		-- A COTTAGE: cream plaster on teal beams under red tiles, one wide arch in its front
		local aw, spring, R = 3.4, FLOOR + 3.9, 1.9
		local zf = HZ + T / 2
		slab("HouseFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, L.stone)
		for _, s in { -1, 1 } do
			slab("FrontWall", s * aw, s * hw, FLOOR, top, HZ, HZ + T, L.wall)
			slab("SideWall", s * (hw - T), s * hw, FLOOR, top, HZ + T, zb, L.wall)
			b.timber(b.face(s * hw, (FLOOR + top) / 2, zc, Vector3.new(s, 0, 0)), depth, wallH, L.beam)
			local front = b.face(0, 0, HZ, FRONT) * CFrame.new(0, 0, -0.1)
			b.trim("FramePost", 0.5, wallH, 0.25, front * CFrame.new(-s * (hw - 0.25), FLOOR + wallH / 2, 0), L.beam)
			b.trim(
				"FramePost",
				0.45,
				spring - FLOOR,
				0.25,
				front * CFrame.new(-s * (aw + 0.22), (FLOOR + spring) / 2, 0),
				L.beam
			)
			lamp(b.face(s * (aw + 1.6), FLOOR + 3.9, HZ, FRONT), 1, true)
		end
		archWall("FrontWall", aw, spring, R, top, zf, T, L.wall)
		archRing("ArchRing", aw + 0.2, spring, R + 0.2, HZ - 0.1, 0.3, 0.45, L.beam)
		b.trim("FrameRail", hw * 2, 0.5, 0.25, b.face(0, top - 0.25, HZ, FRONT) * CFrame.new(0, 0, -0.1), L.beam)
		slab("BackWall", -hw, hw, FLOOR, top, zb - T, zb, L.wall)
		b.timber(b.face(0, (FLOOR + top) / 2, zb, BACK), hw * 2, wallH, L.beam)
		b.window(
			b.face(hw, FLOOR + 3.6, zc + 1.75, LEFT),
			1.5,
			2,
			L.frame,
			L.glass,
			{ shutters = L.shutters, glow = true }
		)
		tiledRoof(top, hw, HZ, zb, rise, 5.6, 3.3)
		if f >= 7 then
			dormer(4.5, top, HZ, rise / (depth / 2))
		end
		-- the lean-to is a glass cold frame now: a brick foot, panes sloping from the wall
		local x1, x2 = -hw, -hw - 3.2
		local cz0, cz1 = HZ + 1, zb - 0.6
		local czc = (cz0 + cz1) / 2
		slab("ColdFrameFoot", x2, x1, FLOOR, FLOOR + 0.9, cz0, cz1, L.lower)
		b.beam(
			"ColdFrameGlass",
			cz1 - cz0,
			0.12,
			Vector3.new(x1, FLOOR + 4, czc),
			Vector3.new(x2, FLOOR + 2.1, czc),
			GLAZE,
			M.Glass
		)
		b.trim("ColdFrameGlass", 0.12, 1.2, cz1 - cz0, b.at(x2 + 0.06, FLOOR + 1.5, czc), GLAZE, M.Glass)
		for _, z in { cz0, czc, cz1 } do
			b.beam("ColdFrameBar", 0.2, 0.2, Vector3.new(x1, FLOOR + 4.05, z), Vector3.new(x2, FLOOR + 2.15, z), L.beam)
			b.trim("ColdFrameBar", 0.2, 1.2, 0.2, b.at(x2 + 0.06, FLOOR + 1.5, z), L.beam)
		end
		b.trim("ColdFrameBar", 0.2, 0.2, cz1 - cz0, b.at(x2 + 0.06, FLOOR + 2.15, czc), L.beam)
		for k = 0, 2 do
			b.ball(
				"PotPlant",
				0.5,
				b.at(x1 - 1.5, FLOOR + 1.3, cz0 + 1 + k * (cz1 - cz0 - 2) / 2),
				if k == 1 then BLOOMS[3] else LEAF
			)
		end
		interior(hw - T, zb - T, FLOOR + 0.2, top - 0.9)
	elseif era == 3 then
		-- AN ORANGERY: a stone storey with one wide arch between two lit arched windows; 15 a jettied
		-- half-timbered storey over it under a higher roof
		local aw, spring, R = 2.8, FLOOR + 3.8, 2.4
		local zf = HZ + T / 2
		slab("HouseFloor", -hw - 0.3, hw + 0.3, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, L.stone)
		local front = b.face(0, 0, HZ, FRONT) * CFrame.new(0, 0, -0.1)
		for _, s in { -1, 1 } do
			slab("FrontWall", s * aw, s * hw, FLOOR, top, HZ, HZ + T, L.lower)
			slab("SideWall", s * (hw - T), s * hw, FLOOR, top, HZ + T, zb, L.lower)
			b.trim("Quoin", 1, wallH, 0.3, front * CFrame.new(-s * (hw - 0.5), FLOOR + wallH / 2, 0), L.frame)
			b.trim("Plinth", hw - aw, 0.8, 0.3, front * CFrame.new(-s * (hw + aw) / 2, FLOOR + 0.4, -0.05), L.stone)
			local window = b.face(s * (aw + hw) / 2 + s * 0.15, FLOOR + 3.5, HZ, FRONT)
			if not painted("Window_Arched", window, 0.72, 0.25) then
				b.window(window, 2, 2.4, L.frame, L.glass, { arch = true, glow = true })
			end
			lamp(b.face(s * (aw + 0.5), FLOOR + 4.5, HZ, FRONT), 0.75, true)
		end
		archWall("FrontWall", aw, spring, R, top, zf, T, L.lower)
		archRing("ArchRing", aw + 0.25, spring, R + 0.25, HZ - 0.1, 0.35, 0.55, L.frame, nil, L.stone)
		b.trim("Keystone", 0.8, 1, 0.5, front * CFrame.new(0, spring + R + 0.2, -0.1), L.frame)
		b.trim("Cornice", hw * 2 + 0.6, 0.45, 0.5, front * CFrame.new(0, top - 0.22, -0.1), L.frame)
		slab("BackWall", -hw, hw, FLOOR, top, zb - T, zb, L.lower)
		b.window(b.face(hw, FLOOR + 3.6, zc, LEFT), 1.8, 2.4, L.frame, L.glass, { arch = true, glow = true })
		-- the cold frame is a stone side bay now, under a tiled lean-to roof
		local x1, x2 = -hw, -hw - 3.4
		local bz0, bz1 = HZ + 1.6, zb - 0.8
		local bzc = (bz0 + bz1) / 2
		slab("BayWall", x2, x1, FLOOR, FLOOR + 3.9, bz0, bz0 + T, L.lower)
		slab("BayWall", x2, x2 + T, FLOOR, FLOOR + 3.9, bz0 + T, bz1, L.lower)
		slab("BayWall", x2, x1, FLOOR, FLOOR + 3.9, bz1 - T, bz1, L.lower)
		b.beam(
			"BayRoof",
			bz1 - bz0 + 1,
			0.4,
			Vector3.new(x1, FLOOR + 5.7, bzc),
			Vector3.new(x2 - 0.7, FLOOR + 3.8, bzc),
			L.roof
		).CastShadow =
			true
		b.window(
			b.face((x1 + x2) / 2, FLOOR + 2.3, bz0, FRONT),
			1.4,
			1.8,
			L.frame,
			L.glass,
			{ arch = true, glow = true }
		)
		if f >= 13 then
			-- 13 ivy climbs the orangery's two front corners and over its arch (the owner's Meshy ivy up the
			-- corners; leaves and white blooms along the arch)
			for _, s in { -1, 1 } do
				painted("Ivy_Corner", b.face(s * (hw - 0.7), FLOOR + 3.3, HZ, FRONT), 0.42, 0.14)
				b.trim(
					"IvyBand",
					hw - aw - 1.2,
					0.9,
					0.35,
					front * CFrame.new(-s * (hw + aw) / 2, top - 0.9, -0.2),
					VINE
				)
			end
			archRing("IvyArch", aw + 0.7, spring, R + 0.7, HZ - 0.3, 0.45, 0.8, VINE, nil, LEAF)
			for k = 1, 7 do
				local x, y = arc(aw + 0.8, spring, R + 0.8, k)
				b.ball("IvyBloom", 0.28, b.at(x, y, HZ - 0.6), C(250, 248, 240), M.SmoothPlastic)
			end
		end
		local roofY, half, z0, z1 = top, hw, HZ, zb
		if f >= 15 then
			-- 15 a jettied half-timbered storey: the house stands a floor taller
			local sh = 3.8
			half, z0, z1 = hw + 0.3, HZ - 0.6, zb + 0.2
			roofY = top + sh
			b.box("Bressummer", half * 2 + 0.2, 0.5, 0.6, b.at(0, top + 0.25, z0 + 0.3), L.beam)
			for _, x in { -half + 0.3, -aw - 0.5, aw + 0.5, half - 0.3 } do
				b.beam(
					"JettyBracket",
					0.4,
					0.4,
					Vector3.new(x, top - 1.1, HZ - 0.05),
					Vector3.new(x, top + 0.1, z0 + 0.2),
					L.board
				)
			end
			slab("UpperWall", -half, half, top + 0.5, roofY, z0, z0 + T, L.wall)
			slab("UpperWall", -half, half, top + 0.5, roofY, z1 - T, z1, L.wall)
			for _, s in { -1, 1 } do
				slab("UpperWall", s * (half - T), s * half, top + 0.5, roofY, z0 + T, z1 - T, L.wall)
				b.timber(
					b.face(s * half, top + 0.5 + (sh - 0.5) / 2, (z0 + z1) / 2, Vector3.new(s, 0, 0)),
					z1 - z0,
					sh - 0.5,
					L.beam
				)
				b.window(
					b.face(s * 4.7, top + 0.5 + (sh - 0.5) / 2, z0, FRONT),
					1.4,
					1.7,
					L.frame,
					L.glass,
					{ shutters = L.shutters, glow = true }
				)
			end
			b.timber(b.face(0, top + 0.5 + (sh - 0.5) / 2, z0, FRONT), half * 2, sh - 0.5, L.beam)
			b.window(b.face(0, top + 0.5 + (sh - 0.5) / 2, z0, FRONT), 2, 1.8, L.frame, L.glass, { glow = true })
		end
		local up = if f >= 15 then 5 else rise
		tiledRoof(roofY, half, z0, z1, up, 6, 3.6)
		for _, s in { -1, 1 } do
			dormer(s * 5, roofY, z0, up / ((z1 - z0) / 2))
			painted("Finial_GoldStone", b.at(s * (half + 0.6), roofY + up - 0.1, (z0 + z1) / 2), 0.6)
		end
		painted("Finial_GoldStone", b.at(0, roofY + 3.5, z0 - 0.3), 0.6)
		interior(hw - T, zb - T, FLOOR + 0.2, top - 0.9)
	elseif era == 4 then
		-- A GREENHOUSE: a nave under a glass vault between two glass aisles, black steel on a brick plinth
		local ax = 9 -- the aisles' outer walls
		local spring, R = top, rise
		local eave = FLOOR + 4.6 -- the aisles' eaves
		local az = HZ + 0.9 -- the aisles' front
		slab("HouseFloor", -ax - 0.3, ax + 0.3, FLOOR, FLOOR + 0.2, HZ - 0.8, zb + 0.2, L.stone)
		-- the walls: a brick plinth, glass over it
		local function glassWall(xa: number, xb: number, z0: number, z1: number, y1: number)
			slab("Plinth", xa, xb, FLOOR, FLOOR + 1.3, z0, z1, L.lower)
			slab("PlinthCap", xa - 0.1, xb + 0.1, FLOOR + 1.3, FLOOR + 1.5, z0 - 0.1, z1 + 0.1, L.frame)
			local thin = 0.2
			if xb - xa > z1 - z0 then
				slab("GlassWall", xa, xb, FLOOR + 1.5, y1, (z0 + z1) / 2 - thin / 2, (z0 + z1) / 2 + thin / 2, L.wall)
			else
				slab("GlassWall", (xa + xb) / 2 - thin / 2, (xa + xb) / 2 + thin / 2, FLOOR + 1.5, y1, z0, z1, L.wall)
			end
		end
		glassWall(-ax, ax, zb - T, zb, eave)
		slab("GlassWall", -hw, hw, eave, spring, zb - 0.4, zb - 0.2, L.wall)
		for _, s in { -1, 1 } do
			local xa, xb = math.min(s * hw, s * ax), math.max(s * hw, s * ax)
			glassWall(xa, xb, az, az + T, eave)
			glassWall(math.min(s * (ax - T), s * ax), math.max(s * (ax - T), s * ax), az + T, zb - T, eave)
			-- steel posts: the nave's four to the vault, the aisles' to their eaves
			for _, z in { HZ, zb } do
				b.box("SteelPost", 0.6, wallH, 0.6, b.at(s * hw, FLOOR + wallH / 2, z), L.beam)
			end
			for _, z in { az, zb } do
				b.box("SteelPost", 0.45, eave - FLOOR, 0.45, b.at(s * ax, (FLOOR + eave) / 2, z), L.beam)
			end
			b.box("NavePlate", 0.5, 0.5, depth, b.at(s * hw, spring - 0.25, zc), L.beam)
			-- the clerestory: the nave's glass between the aisle's roof and the vault
			slab("GlassWall", s * hw - 0.1, s * hw + 0.1, FLOOR + 6.9, spring - 0.5, az, zb, L.wall)
			b.box(
				"SteelPost",
				0.4,
				spring - FLOOR - 7.4,
				0.4,
				b.at(s * hw, (FLOOR + 6.9 + spring - 0.5) / 2, zc),
				L.beam
			)
			b.box("AislePlate", 0.4, 0.4, zb - az, b.at(s * ax, eave, (az + zb) / 2), L.beam)
			b.box("AislePlate", ax - hw, 0.4, 0.4, b.at(s * (ax + hw) / 2, eave, az), L.beam)
			-- an aisle's roof: glass, high at the nave and low at its eave
			local amid = (az + zb) / 2
			b.beam(
				"AisleRoof",
				zb - az,
				0.15,
				Vector3.new(s * hw, FLOOR + 6.7, amid),
				Vector3.new(s * (ax + 0.3), eave + 0.05, amid),
				L.roof
			)
			for _, z in { az, amid, zb } do
				b.beam(
					"AisleRib",
					0.25,
					0.25,
					Vector3.new(s * hw, FLOOR + 6.8, z),
					Vector3.new(s * (ax + 0.3), eave + 0.15, z),
					L.beam
				)
			end
			-- brackets under the tie beam, a lantern hanging each side of the opening
			b.beam(
				"Bracket",
				0.4,
				0.4,
				Vector3.new(s * hw, spring - 2.2, HZ),
				Vector3.new(s * (hw - 2), spring - 0.3, HZ),
				L.beam
			)
			lantern(b.at(s * 2.6, spring - 0.25, HZ), true)
			-- (13, in glass and steel: the owner's Meshy trellis of ivy on each aisle's front)
			painted("Trellis_Ivy", b.face(s * (ax + hw) / 2, FLOOR + 2.7, az, FRONT), 0.68, 0.3)
			for k = 0, 1 do
				b.cyl("Pot", 0.5, 0.7, b.at(s * (hw + 1.4 + k * 1.6), FLOOR + 0.55, az + 2 + k * 2.2), POT, nil, false)
				b.ball("PotPlant", 0.8, b.at(s * (hw + 1.4 + k * 1.6), FLOOR + 1.5, az + 2 + k * 2.2), LEAF)
			end
		end
		b.box("TieBeam", hw * 2 + 0.6, 0.5, 0.5, b.at(0, spring, HZ), L.beam)
		-- the vault: flat panes between steel ribs, a glass fan in each end
		for k = 0, 7 do
			local px, py = arc(hw, spring, R, k)
			local qx, qy = arc(hw, spring, R, k + 1)
			b.beam("Vault", depth, 0.15, Vector3.new(px, py, zc), Vector3.new(qx, qy, zc), L.roof)
			if k > 0 then
				b.rod("Purlin", 0.1, Vector3.new(px, py + 0.05, HZ), Vector3.new(px, py + 0.05, zb), L.beam)
			end
		end
		for _, z in { HZ, zc, zb } do
			archRing("VaultRib", hw, spring, R, z, 0.35, 0.3, L.beam)
		end
		for _, z in { HZ + 0.1, zb - 0.1 } do
			fan(hw - 0.1, spring + 0.25, R - 0.1, z, L.wall)
		end
		for k = 1, 7 do
			local x, y = arc(hw - 0.15, spring, R - 0.15, k)
			b.rod("FanBar", 0.08, Vector3.new(0, spring + 0.3, HZ), Vector3.new(x, y, HZ), L.beam)
		end
		b.disc("FanHub", 0.7, 0.3, b.face(0, spring + 0.3, HZ, FRONT), L.gold, M.Metal)
		-- (7, in glass: a raised lantern vault along the ridge)
		local r2 = 2
		local s2 = spring + math.sqrt(R * R - r2 * r2) - 0.15
		local lz0, lz1 = HZ + 1.6, zb - 1.6
		for k = 0, 7 do
			local px, py = arc(r2, s2, r2, k)
			local qx, qy = arc(r2, s2, r2, k + 1)
			b.beam("Vault", lz1 - lz0, 0.12, Vector3.new(px, py, zc), Vector3.new(qx, qy, zc), L.roof)
		end
		for _, z in { lz0, lz1 } do
			archRing("VaultRib", r2, s2, r2, z, 0.3, 0.25, L.beam)
			fan(r2 - 0.1, s2, r2 - 0.1, z, L.wall)
		end
		b.rod(
			"VaultRidge",
			0.14,
			Vector3.new(0, s2 + r2 + 0.1, lz0 - 0.2),
			Vector3.new(0, s2 + r2 + 0.1, lz1 + 0.2),
			L.gold,
			M.Metal
		)
		if f >= 18 then
			-- 18 copper pipes from the tower over the aisle and up the vault to the roof's lantern
			local up = 0.45
			local points = { Vector3.new(TX - 2.7, FLOOR + 6.4, TZ), Vector3.new(ax + 0.6, FLOOR + 6.4, TZ) }
			table.insert(points, Vector3.new(ax + 0.6, eave + up + 0.1, TZ))
			table.insert(points, Vector3.new(hw + 0.3, FLOOR + 6.8 + up, TZ))
			for k = 1, 3 do
				local x, y = arc(hw + up, spring, R + up, k)
				table.insert(points, Vector3.new(x, y, TZ))
			end
			table.insert(points, Vector3.new(r2 + 0.5, s2 + 0.5, TZ))
			pipe(points, 0.3, L.accent)
			painted("PipeValve_Copper", b.face(TX - 2.6, FLOOR + 4.2, TZ + 1.2, RIGHT), 0.55)
		end
		interior(hw - 0.4, zb - T, FLOOR + 0.2, spring - 1.4)
	else
		-- A PALM HOUSE: a marble hall behind four columns and a pediment, a wing each side under a balustrade
		local aw, spring, R = 2.6, FLOOR + 5, 2.4
		local zf = HZ + T / 2
		local wx = 10 -- the wings' outer walls
		local wz0, wz1 = HZ + 0.9, zb - 0.4
		local wh = FLOOR + 6.4 -- the wings' roofs
		local pz = HZ - 1.9 -- the portico's front
		local et = top + 0.6 -- the entablature's top
		slab("HouseFloor", -wx - 0.3, wx + 0.3, FLOOR, FLOOR + 0.25, wz0 - 0.6, zb + 0.2, L.stone)
		slab("Stylobate", -hw - 1.2, hw + 1.2, FLOOR, FLOOR + 0.25, pz - 1, HZ, L.stone)
		slab("Stylobate", -hw - 0.7, hw + 0.7, FLOOR + 0.25, FLOOR + 0.5, pz - 0.5, HZ, L.wall)
		local front = b.face(0, 0, HZ, FRONT) * CFrame.new(0, 0, -0.1)
		for _, s in { -1, 1 } do
			slab("FrontWall", s * aw, s * hw, FLOOR, top, HZ, HZ + T, L.wall)
			slab("SideWall", s * (hw - T), s * hw, FLOOR, top, HZ + T, zb, L.wall)
			for _, x in { 3.5, 5.3 } do
				column(s * x, HZ - 1.2, FLOOR + 0.5, top - 0.4, 0.45)
			end
			lantern(b.at(s * 4.4, top - 0.4, HZ - 1.1), true)
			-- a wing: marble walls round a lit arched window, a flat roof under a balustrade
			local x0, x1 = s * hw, s * wx
			slab("WingWall", x0, x1, FLOOR, wh, wz0, wz0 + T, L.wall)
			slab("WingWall", s * (wx - T), x1, FLOOR, wh, wz0 + T, wz1, L.wall)
			slab("WingWall", x0, x1, FLOOR, wh, wz1 - T, wz1, L.wall)
			slab("WingRoof", x0, s * (wx + 0.3), wh, wh + 0.4, wz0 - 0.3, wz1 + 0.3, L.stone)
			local wface = b.face(s * (hw + wx) / 2, 0, wz0, FRONT) * CFrame.new(0, 0, -0.1)
			b.trim("WingCornice", wx - hw + 0.4, 0.25, 0.3, wface * CFrame.new(0, wh + 0.2, -0.3), L.gold)
			b.trim("WingPlinth", wx - hw, 0.8, 0.3, wface * CFrame.new(0, FLOOR + 0.4, 0), L.stone)
			b.trim(
				"Pilaster",
				0.7,
				wh - FLOOR,
				0.3,
				wface * CFrame.new(-s * (wx - hw - 0.7) / 2, (FLOOR + wh) / 2, 0),
				L.beam
			)
			local window = b.face(s * (hw + wx) / 2 - s * 0.2, FLOOR + 3.4, wz0, FRONT)
			if not painted("Window_Arched", window, 0.8, 0.25) then
				b.window(window, 2.2, 2.8, L.frame, L.glass, { arch = true, glow = true })
			end
			balustrade(x0 + s * 0.3, wz0, s * wx, wz0, wh + 0.4, L.wall, true, true, true)
			balustrade(s * wx, wz0, s * wx, wz1, wh + 0.4, L.wall, false, false, true)
			-- (13, in marble: the owner's Meshy flowering vine up each wing's outer corner)
			painted("Ivy_Corner", b.face(s * (wx - 0.7), FLOOR + 3.1, wz0, FRONT), 0.4, 0.14)
			if f >= 24 then
				-- 24 small blue glass domes with gold ribs on the two side wings
				local dx, dz = s * (hw + wx) / 2 + s * 0.2, (wz0 + wz1) / 2 + 0.4
				b.cyl("WingDrum", 1.95, 0.9, b.at(dx, wh + 0.85, dz), L.wall)
				b.cyl("WingDrumBand", 2.05, 0.22, b.at(dx, wh + 1.3, dz), L.gold, M.Metal, false)
				dome(b.at(dx, wh + 1.3, dz), 1.85)
			end
		end
		archWall("FrontWall", aw, spring, R, top, zf, T, L.wall)
		archRing("ArchGold", aw + 0.15, spring, R + 0.15, HZ - 0.1, 0.3, 0.3, L.gold)
		b.trim("Keystone", 0.8, 1, 0.5, front * CFrame.new(0, spring + R + 0.2, -0.1), L.gold)
		slab("BackWall", -hw, hw, FLOOR, top, zb - T, zb, L.wall)
		-- the entablature on the columns, the pediment roof over the hall
		slab("Entablature", -hw - 0.6, hw + 0.6, top - 0.4, et, pz + 0.1, HZ, L.wall)
		for _, y in { top - 0.3, et - 0.1 } do
			b.trim("Frieze", hw * 2 + 1.4, 0.2, 0.2, b.face(0, y, pz + 0.1, FRONT) * CFrame.new(0, 0, -0.1), L.gold)
		end
		local rz = (pz + zb) / 2
		b.gable(b.at(0, et, rz) * turn, zb - pz, hw * 2 + 1.2, rise, 0.5, L.roof, L.wall, L.gold)
		if f >= 23 then
			-- 23 a golden slime between gold laurels on the pediment (the game's own slime; the owner's Meshy laurel)
			local foot = b.at(0, et + 0.15, pz - 0.55)
			b.trim("CrestShelf", 2.6, 0.2, 1, b.at(0, et + 0.05, pz - 0.4), L.gold, M.Metal)
			b.slime(foot, 0.75, L.gold)
			if not painted("Laurel_Gold", b.face(0, et + 1.25, pz, FRONT), 0.5) then
				for _, s in { -1, 1 } do
					b.trim(
						"Laurel",
						0.3,
						1.6,
						0.2,
						b.face(s * 1.2, et + 1, pz, FRONT) * CFrame.Angles(0, 0, -s * 0.3),
						L.gold
					)
				end
			end
		else
			b.disc("PedimentBoss", 0.9, 0.25, b.face(0, et + 1.1, pz, FRONT), L.gold, M.Metal)
		end
		if f >= 25 then
			-- 25 the great blue glass dome with gold ribs and a gold lantern over the palm house, a palm under it
			local dr = 3.7
			local dy = et + rise + 0.6
			b.cyl("Drum", dr, dy - top, b.at(0, (top + dy) / 2, zc), L.wall)
			b.cyl("DrumBand", dr + 0.15, 0.35, b.at(0, dy - 0.15, zc), L.gold, M.Metal, false)
			b.cyl("DrumBand", dr + 0.12, 0.25, b.at(0, et + rise - 0.6, zc), L.gold, M.Metal, false)
			for k = 0, 7 do
				local a = k * math.pi / 4 + math.pi / 8
				b.trim(
					"DrumWindow",
					1,
					1.3,
					0.2,
					b.at(0, dy - 1.2, zc) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -dr),
					L.glass,
					M.Neon
				)
			end
			dome(b.at(0, dy, zc), dr - 0.1)
			b.cyl("PalmTrunk", 0.3, 2.6, b.at(0, dy + 1.3, zc), BOX, nil, false)
			for k = 0, 5 do
				local a = k * math.pi / 3
				b.beam(
					"PalmLeaf",
					0.9,
					0.15,
					Vector3.new(0, dy + 2.6, zc),
					Vector3.new(math.cos(a) * 2.2, dy + 3.3, zc + math.sin(a) * 2.2),
					LEAF
				)
			end
		else
			b.rod(
				"RidgeGold",
				0.22,
				Vector3.new(0, et + rise + 0.3, pz - 0.4),
				Vector3.new(0, et + rise + 0.3, zb + 0.4),
				L.gold
			)
		end
		interior(hw - T, zb - T, FLOOR + 0.25, 7.4)
	end

	-- THE WATER TOWER ------------------------------------------------------------------------------------------
	-- a trestle of four legs leaning in from `h0` out at `y0` to `h1` out at `y1`, girts and a brace a face a tier
	local function trestle(y0: number, y1: number, h0: number, h1: number, colour: Color3, tiers: number)
		local corners = { { 1, 1 }, { -1, 1 }, { -1, -1 }, { 1, -1 } }
		local function at(c: { number }, y: number): Vector3
			local h = h0 + (h1 - h0) * (y - y0) / (y1 - y0)
			return Vector3.new(TX + c[1] * h, y, TZ + c[2] * h)
		end
		for i, c in corners do
			b.beam("TrestleLeg", 0.5, 0.5, at(c, y0), at(c, y1), colour)
			local n = corners[i % 4 + 1]
			for t = 1, tiers do
				local ya, yb = y0 + (y1 - y0) * (t - 1) / tiers, y0 + (y1 - y0) * t / tiers
				b.beam("TrestleGirt", 0.35, 0.35, at(c, yb), at(n, yb), colour)
				if (t + i) % 2 == 0 then
					b.beam("TrestleBrace", 0.28, 0.28, at(c, ya), at(n, yb), colour)
				else
					b.beam("TrestleBrace", 0.28, 0.28, at(n, ya), at(c, yb), colour)
				end
			end
		end
		b.box("TowerDeck", h1 * 2 + 1.3, 0.3, h1 * 2 + 1.3, b.at(TX, y1 + 0.15, TZ), PLANK)
	end
	-- a water barrel standing at `y` under a little cone roof; returns its tip
	local function barrel(y: number, r: number, h: number): number
		b.cyl("Barrel", r, h, b.at(TX, y + h / 2, TZ), PLANK)
		for _, t in { 0.22, 0.78 } do
			b.cyl("BarrelHoop", r + 0.06, 0.18, b.at(TX, y + h * t, TZ), IRON, nil, false)
		end
		b.cone(b.at(TX, y + h, TZ), r + 0.35, 1.1, 3, L.roof, L.gold)
		return y + h + 1.1
	end
	-- THE WHEEL AND THE SAILS turn: a model of their own round the hub (tag "Turn", client/WindTurn turns it)
	local function rotor(hubY: number, hubZ: number, speed: number)
		local model = Instance.new("Model")
		model.Name = "Rotor"
		local hub = b.face(TX, hubY, hubZ, FRONT)
		model.WorldPivot = hub
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model:SetAttribute("TurnSpeed", speed)
		CollectionService:AddTag(model, "Turn")
		model.Parent = m
		b.rod("Axle", 0.2, Vector3.new(TX, hubY, hubZ), Vector3.new(TX, hubY, TZ), IRON)
		return Architecture.new(model, frame, skins, 0.4), hub
	end
	-- 5 a many-bladed wind wheel `r` round (the Blender piece; flat blades until it comes)
	local function wheel(hubY: number, hubZ: number, r: number, colour: Color3, material: Enum.Material?)
		local rb, hub = rotor(hubY, hubZ, 50)
		local src = LibraryKit.find("WindWheel_Blades")
		if src then
			rb.mesh(src, hub, Vector3.new(r, r, r), colour, material)
		else
			for i = 0, 7 do
				local arm = hub * CFrame.Angles(0, 0, i * math.pi / 4)
				rb.trim(
					"Blade",
					r * 0.34,
					r * 0.7,
					0.12,
					arm * CFrame.new(0, r * 0.63, 0) * CFrame.Angles(0, math.rad(18), 0),
					colour,
					material
				)
				rb.trim("Spoke", 0.14, r * 0.95, 0.14, arm * CFrame.new(0, r * 0.475, 0.12), colour, material)
			end
		end
		rb.disc("Hub", math.max(0.4, r * 0.15), 0.5, hub * CFrame.new(0, 0, -0.1), L.gold, bigGold)
	end
	-- 10 four sails `r` long: cream cloth, then lattice, then blue cloth in gold
	local function sails(hubY: number, hubZ: number, r: number)
		local rb, hub = rotor(hubY, hubZ, 28)
		local w, y0 = r * 0.3, r * 0.24
		local edge = if era == 5 then L.gold else L.accent
		for i = 0, 3 do
			local arm = hub * CFrame.Angles(0, 0, i * math.pi / 2 + math.pi / 4)
			local mid = (y0 + r) / 2
			rb.trim("SailStock", 0.3, r, 0.3, arm * CFrame.new(0, r / 2, 0.05), edge)
			if era == 3 then
				for k = 0, 2 do
					rb.trim("SailBar", 0.14, r - y0, 0.12, arm * CFrame.new(0.15 + w * k / 2, mid, -0.05), L.sail)
				end
				for k = 0, 5 do
					rb.trim(
						"SailBar",
						w,
						0.14,
						0.12,
						arm * CFrame.new(0.15 + w / 2, y0 + (r - y0) * k / 5, -0.05),
						L.sail
					)
				end
			else
				rb.trim(
					"Sail",
					w,
					r - y0,
					0.1,
					arm * CFrame.new(0.15 + w / 2, mid, -0.08),
					L.sail,
					if era == 5 then M.SmoothPlastic else nil
				)
				rb.trim("SailBar", 0.14, r - y0, 0.16, arm * CFrame.new(0.15 + w, mid, -0.08), edge)
				for _, y in { y0, r } do
					rb.trim("SailBar", w, 0.14, 0.16, arm * CFrame.new(0.15 + w / 2, y, -0.08), edge)
				end
				if era == 2 then
					-- (laths over the cloth: bare panels read as four boards)
					for k = 1, 2 do
						rb.trim(
							"SailBar",
							w,
							0.12,
							0.16,
							arm * CFrame.new(0.15 + w / 2, y0 + (r - y0) * k / 3, -0.08),
							edge
						)
					end
					rb.trim("SailBar", 0.12, r - y0, 0.16, arm * CFrame.new(0.15 + w / 2, mid, -0.08), edge)
				elseif era == 5 then
					rb.trim(
						"SailLeaf",
						w * 0.5,
						w * 0.5,
						0.14,
						arm * CFrame.new(0.15 + w / 2, mid, -0.1) * CFrame.Angles(0, 0, math.pi / 4),
						L.gold
					)
				end
			end
		end
		rb.disc("Hub", 0.75, 0.6, hub * CFrame.new(0, 0, -0.15), L.gold, bigGold)
	end
	-- 8 a basin at the tower's foot (its front wall at z `front`), filled from a spout; 12 the water pours from a
	-- spout `spoutY` high down a stone chute into the basin, which then stands further out
	local function basin(front: number, chute: boolean, spoutY: number)
		local bz = front - (if chute then 3.7 else 1.35)
		local body = if era == 5 then L.wall else L.lower
		local rim = if era == 5 then L.gold else if era == 4 then L.frame else L.stone
		slab("Basin", TX - 1.9, TX + 1.9, FLOOR, FLOOR + 1.25, bz - 1.25, bz + 1.25, body)
		for _, s in { -1, 1 } do
			b.trim("BasinRim", 4.1, 0.25, 0.4, b.at(TX, FLOOR + 1.35, bz + s * 1.15), rim)
			b.trim("BasinRim", 0.4, 0.25, 1.9, b.at(TX + s * 1.85, FLOOR + 1.35, bz), rim)
		end
		b.trim("BasinWater", 3.3, 0.14, 1.9, b.at(TX, FLOOR + 1.3, bz), WATER, M.Glass)
		local metal = if era >= 4 then L.accent else IRON
		if not chute then
			b.trim("Spout", 0.5, 0.4, 1, b.at(TX, FLOOR + 2.7, front - 0.45), metal)
			b.trim("WaterFall", 0.36, 1.4, 0.14, b.at(TX, FLOOR + 1.95, front - 0.85), WATER, M.Glass)
			return
		end
		local head = Vector3.new(TX, 3.3, front - 0.5)
		local foot = Vector3.new(TX, 1.75, bz + 1)
		b.trim("Spout", 0.9, 0.5, 0.9, b.at(TX, spoutY, front - 0.4), metal)
		b.trim("WaterFall", 0.7, spoutY - 3.4, 0.14, b.at(TX, (spoutY + 3.4) / 2, front - 0.75), WATER, M.Glass)
		b.box("ChutePier", 1.5, 3.1 - FLOOR, 1, b.at(TX, (FLOOR + 3.1) / 2, front - 0.5), body)
		b.beam("Chute", 1.4, 0.3, head, foot, L.stone)
		for _, s in { -1, 1 } do
			local side = Vector3.new(s * 0.65, 0.2, 0)
			b.beam("ChuteLip", 0.22, 0.6, head + side, foot + side, L.stone)
		end
		local lift = Vector3.new(0, 0.22, 0)
		b.beam("ChuteWater", 1, 0.1, head + lift, foot + lift, WATER, M.Glass)
	end
	-- a square brick foot `h` high: a door on the side to the house, a small lit window over the spout
	local function brickFoot(h: number)
		b.box("TowerBase", 5.7, 0.7, 5.7, b.at(TX, FLOOR + 0.35, TZ), L.stone)
		b.box("TowerFoot", 5.2, h - 0.7, 5.2, b.at(TX, FLOOR + 0.7 + (h - 0.7) / 2, TZ), L.lower)
		b.box("TowerCap", 5.8, 0.45, 5.8, b.at(TX, FLOOR + h + 0.22, TZ), if era == 2 then L.stone else L.frame)
		local door = b.face(TX - 2.6, FLOOR + 2.2, TZ, RIGHT)
		b.trim("TowerDoor", 1.7, 3, 0.25, door * CFrame.new(0, 0, -0.05), L.board)
		b.disc("TowerDoorHead", 0.85, 0.25, door * CFrame.new(0, 1.5, -0.05), L.board)
		b.window(b.face(TX, FLOOR + h - 1.2, TZ - 2.6, FRONT), 1, 1, L.frame, L.glass, { glow = true })
	end
	-- a round tower in two stages, to `y1` and `y2`, under a cone cap `capUp` high; returns its tip
	local function roundTower(y1: number, y2: number, capUp: number): number
		local body = if era == 5 then L.wall else L.lower
		local band = if era == 5 then L.gold else L.frame
		b.cyl("TowerBase", 3.4, 0.8, b.at(TX, FLOOR + 0.4, TZ), L.stone)
		b.cyl("Tower", 3, y1 - FLOOR - 0.8, b.at(TX, (FLOOR + 0.8 + y1) / 2, TZ), body)
		b.cyl("TowerBand", 3.15, 0.4, b.at(TX, y1 + 0.2, TZ), band, bigGold, false)
		b.cyl("Tower", 2.7, y2 - y1 - 0.4, b.at(TX, (y1 + 0.4 + y2) / 2, TZ), body)
		b.cyl("TowerBand", 3, 0.45, b.at(TX, y2 + 0.22, TZ), band, bigGold, false)
		coneRoof(b.at(TX, y2 + 0.45, TZ), 3.5, capUp, L.roof)
		local door = b.face(TX - 3, FLOOR + 2.3, TZ, RIGHT)
		b.trim("TowerDoor", 1.7, 3, 0.3, door, L.board)
		b.disc("TowerDoorHead", 0.85, 0.3, door * CFrame.new(0, 1.5, 0), L.board)
		b.window(b.face(TX, FLOOR + 6, TZ - 3, FRONT), 1.1, 1.5, L.frame, L.glass, { arch = true, glow = true })
		b.window(b.face(TX, y1 + 4.2, TZ - 2.7, FRONT), 1, 1.4, L.frame, L.glass, { arch = true, glow = true })
		b.window(b.face(TX - 2.7, y1 + 4.2, TZ, RIGHT), 1, 1.4, L.frame, L.glass, { arch = true, glow = true })
		return y2 + 0.45 + capUp
	end
	-- 14 a gallery round the tower at `y`, from the wall `inner` out to `outer`: a deck on struts, a rail
	local function gallery(y: number, inner: number, outer: number, deck: Color3, rail: Color3)
		b.cyl("Gallery", outer, 0.3, b.at(TX, y, TZ), deck, nil, false)
		local function ring(k: number, r: number, up: number): Vector3
			local a = k * math.pi / 4 + math.pi / 8
			return Vector3.new(TX + math.cos(a) * r, y + up, TZ + math.sin(a) * r)
		end
		for k = 0, 7 do
			local p = ring(k, outer - 0.2, 0.8)
			b.trim("GalleryPost", 0.3, 1.4, 0.3, b.at(p.X, p.Y, p.Z), rail)
			b.beam("GalleryRail", 0.22, 0.22, ring(k, outer - 0.2, 1.5), ring(k + 1, outer - 0.2, 1.5), rail)
			b.beam("GalleryRail", 0.16, 0.16, ring(k, outer - 0.2, 0.8), ring(k + 1, outer - 0.2, 0.8), rail)
			b.beam("GalleryStrut", 0.26, 0.26, ring(k, inner, -1.7), ring(k, outer - 0.3, -0.15), rail)
		end
	end

	if era == 1 then
		-- a fieldstone well with a winch; 4 a tall timber trestle over it carrying a water barrel; 5 the wooden
		-- wind wheel, turning, and the blue pennant
		b.cyl("Well", 1.9, 1.5, b.at(TX, FLOOR + 0.75, TZ), L.stone)
		b.cyl("WellRim", 2.05, 0.25, b.at(TX, FLOOR + 1.6, TZ), L.stone, nil, false)
		b.cyl("WellWater", 1.55, 0.1, b.at(TX, FLOOR + 1.72, TZ), WATER, M.Glass, false)
		for _, s in { -1, 1 } do
			b.box("WinchPost", 0.4, 3.6, 0.4, b.at(TX + s * 1.75, FLOOR + 1.8, TZ), L.beam)
		end
		b.rod("Winch", 0.28, Vector3.new(TX - 1.75, FLOOR + 3.2, TZ), Vector3.new(TX + 1.75, FLOOR + 3.2, TZ), L.frame)
		b.rod(
			"WinchCrank",
			0.08,
			Vector3.new(TX - 2, FLOOR + 3.2, TZ),
			Vector3.new(TX - 2.4, FLOOR + 2.6, TZ - 0.3),
			IRON
		)
		b.rod("WinchRope", 0.05, Vector3.new(TX + 0.3, FLOOR + 3.2, TZ), Vector3.new(TX + 0.3, FLOOR + 2.4, TZ), SACK)
		b.cyl("Bucket", 0.36, 0.5, b.at(TX + 0.3, FLOOR + 2.15, TZ), PLANK, nil, false)
		if f >= 4 then
			trestle(FLOOR, 10.8, 2.7, 1.3, L.beam, 3)
			local tip = barrel(11.1, 1.25, 2.3)
			if f >= 5 then
				wheel(12.2, TZ - 2.2, 2.9, L.sail, nil)
				b.flag(Vector3.new(TX, tip - 0.1, TZ), 3.2, L.cloth, L.gold)
			end
		end
	elseif era == 2 then
		-- the trestle stands on a red brick foot; 8 a brick basin; 10 the wheel becomes four cream cloth sails
		brickFoot(5.4)
		trestle(FLOOR + 5.85, 12.6, 2.2, 1.2, L.accent, 2)
		local tip = barrel(12.9, 1.2, 2.2)
		if f >= 10 then
			sails(14, TZ - 2.7, 5.4)
		else
			wheel(14, TZ - 2.7, 2.9, PLANK, nil)
		end
		b.flag(Vector3.new(TX, tip - 0.1, TZ), 3, L.cloth, L.gold)
		if f >= 8 then
			basin(TZ - 2.6, false, 0)
		end
	elseif era == 3 then
		-- a round stone mill under a red cone cap, lattice sails; 12 the chute; 14 a timber gallery under its cap
		local tip = roundTower(8, 15.2, 4.6)
		b.flag(Vector3.new(TX, tip - 0.4, TZ), 3, L.cloth, L.gold)
		if f >= 14 then
			gallery(11, 2.7, 4.1, L.beam, L.board)
		end
		sails(13.4, TZ - 4.5, 5.4)
		basin(TZ - 3, f >= 12, 4.6)
	elseif era == 4 then
		-- a black steel trestle on the brick foot under a many-bladed steel wheel; 20 a glowing goo tank in it and
		-- two smaller tanks at its foot, piped to the beds
		brickFoot(5.4)
		trestle(FLOOR + 5.85, 16.4, 2.3, 1.3, L.beam, 3)
		b.box("WheelHead", 1.7, 1.5, 2.2, b.at(TX, 17.45, TZ - 0.2), L.board)
		b.trim("Vane", 0.12, 1.7, 2.4, b.at(TX, 17.6, TZ + 2.6), L.sail)
		b.rod("VaneArm", 0.12, Vector3.new(TX, 17.5, TZ), Vector3.new(TX, 17.5, TZ + 2.4), L.board)
		wheel(17.5, TZ - 2.5, 3.5, L.sail, M.Metal)
		b.flag(Vector3.new(TX, 18.1, TZ), 3.2, L.cloth, L.gold)
		-- (14, in steel: a walkway round the trestle with a brass rail)
		local wy = FLOOR + 5.85 + (16.4 - FLOOR - 5.85) * 2 / 3
		b.box("Walkway", 5.2, 0.25, 5.2, b.at(TX, wy, TZ), L.board)
		for i, c in { { 1, 1 }, { -1, 1 }, { -1, -1 }, { 1, -1 } } do
			local n = ({ { 1, 1 }, { -1, 1 }, { -1, -1 }, { 1, -1 } })[i % 4 + 1]
			b.ball("WalkwayKnob", 0.3, b.at(TX + c[1] * 2.5, wy + 1.4, TZ + c[2] * 2.5), L.gold, M.Metal)
			b.rod(
				"WalkwayPost",
				0.1,
				Vector3.new(TX + c[1] * 2.5, wy, TZ + c[2] * 2.5),
				Vector3.new(TX + c[1] * 2.5, wy + 1.3, TZ + c[2] * 2.5),
				L.gold,
				M.Metal
			)
			b.rod(
				"WalkwayRail",
				0.1,
				Vector3.new(TX + c[1] * 2.5, wy + 1.2, TZ + c[2] * 2.5),
				Vector3.new(TX + n[1] * 2.5, wy + 1.2, TZ + n[2] * 2.5),
				L.gold,
				M.Metal
			)
		end
		pipe({ Vector3.new(TX + 1.1, FLOOR + 5.9, TZ + 1.1), Vector3.new(TX + 1.1, 16.2, TZ + 1.1) }, 0.25, L.accent)
		if f >= 20 then
			local tank = painted("GooTank_Glass", b.at(TX, FLOOR + 5.85, TZ), 1.1)
			if tank then
				light(tank, GOO, 16, 1)
			else
				b.cyl("GooTank", 1.5, 4.4, b.at(TX, FLOOR + 5.85 + 2.2, TZ), C(120, 222, 205), M.Glass, false)
				light(b.cyl("Goo", 1.3, 3.6, b.at(TX, FLOOR + 5.85 + 1.9, TZ), GOO, M.Neon, false), GOO, 16, 1)
			end
			for _, z in { 20.1, 22.3 } do
				if not painted("GooTank_Glass", b.at(10.7, FLOOR, z), 0.6) then
					b.cyl("GooTank", 0.8, 2.6, b.at(10.7, FLOOR + 1.3, z), GOO, M.Neon, false)
				end
			end
			pipe({
				Vector3.new(10.7, FLOOR + 0.5, 19.2),
				Vector3.new(10.7, FLOOR + 0.5, 13),
				Vector3.new(BEDX, FLOOR + 0.5, 13),
			}, 0.2, L.accent)
		end
		basin(TZ - 2.6, true, 4.3)
		painted("PipeValve_Copper", b.face(TX - 1.6, FLOOR + 3.2, TZ - 2.6, FRONT), 0.45)
	else
		-- a marble tower with gold bands under a blue cone cap, blue and gold sails; 22 a gold crown on its top
		local tip = roundTower(8.6, 17, 4.8)
		if f >= 22 then
			local crown = b.at(TX, 17.45 + 4.8 * 0.48, TZ)
			if not piece("ChimneyCrown_Gold", crown, 1.8, 1.8, 1.8, L.gold, M.Metal) then
				b.cyl("TowerCrown", 1.9, 0.9, crown * CFrame.new(0, 0.45, 0), L.gold, M.Metal, false)
				for k = 0, 7 do
					local a = k * math.pi / 4
					b.ball(
						"TowerCrownPoint",
						0.3,
						crown * CFrame.new(math.cos(a) * 1.8, 1.2, math.sin(a) * 1.8),
						L.gold,
						M.Metal
					)
				end
			end
		end
		b.flag(Vector3.new(TX, tip - 0.4, TZ), 3, L.cloth, L.gold)
		gallery(11.6, 2.7, 4.1, L.wall, L.gold)
		sails(14.6, TZ - 4.5, 5.4)
		basin(TZ - 3, true, 4.6)
		-- (20, at the capital: the two goo tanks stay at the tower's foot)
		for _, z in { 20.1, 22.3 } do
			painted("GooTank_Glass", b.at(10.7, FLOOR, z), 0.6)
		end
	end

	-- OVER THE BEDS --------------------------------------------------------------------------------------------
	if f >= 16 then
		-- 16 copper irrigation arches with sprinkler heads over both beds (the Blender piece), a header pipe along
		-- their tops down to the ground behind the bed
		-- (gold at the capital: copper hoops read as rustic wood beside marble)
		local hoop = if era == 5 then L.gold else L.accent
		for _, s in { -1, 1 } do
			local x = s * BEDX
			for _, z in { 1.7, 5.7, 9.7 } do
				if not piece("IrrigationArch_Copper", b.at(x, FLOOR, z), 3.6, 4.6, 3.6, hoop, M.Metal) then
					for k = 0, 7 do
						local a0, a1 = math.rad(k * 22.5), math.rad((k + 1) * 22.5)
						b.rod(
							"IrrigationArch",
							0.16,
							Vector3.new(x + 3.6 * math.cos(a0), FLOOR + 4.6 * math.sin(a0), z),
							Vector3.new(x + 3.6 * math.cos(a1), FLOOR + 4.6 * math.sin(a1), z),
							hoop
						)
					end
					b.ball("Sprinkler", 0.3, b.at(x, FLOOR + 4.3, z), L.gold, M.Metal)
				end
			end
			pipe(
				{ Vector3.new(x, FLOOR + 4.7, 1.7), Vector3.new(x, FLOOR + 4.7, 13), Vector3.new(x, FLOOR + 0.5, 13) },
				0.2,
				hoop
			)
		end
	end
	if f >= 21 then
		-- 21 cone topiaries in gold urns at the front corners and beside the house (the owner's Meshy topiary)
		for _, p in { { -15.6, -9.6 }, { 15.6, -9.6 }, { -11.8, 16.4 }, { 10.6, 15.4 } } do
			if not painted("ConePot_Topiary", b.at(p[1], FLOOR, p[2]), 1.25) then
				b.cyl("TopiaryUrn", 0.9, 1.4, b.at(p[1], FLOOR + 0.7, p[2]), L.gold, M.Metal, false)
				b.cone(b.at(p[1], FLOOR + 1.4, p[2]), 1.2, 4, 4, LEAF)
			end
		end
	end
end

return Garden
