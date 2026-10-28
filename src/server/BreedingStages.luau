--!strict
-- The breeding pen's 50 levels (the owner, 2026-10-28: "the same as the pantry and the garden"). Five
-- eras of ten levels; in each era:
--   level 1 of the era   the pen grows: the nesting shelter is rebuilt bigger in the era's material with
--                        its own roof, and a nest or an incubator is added (a 3rd nest at 11, a 3rd
--                        incubator at 21, a 4th nest at 31, a 4th incubator at 41)
--   levels 2-5           four care props, one a level, each slot taking its next, better version:
--                        1 feed (bucket > hay feeder > grain feeder > auto feeder > goo feeder)
--                        2 egg care (basket > crate > egg cart > egg scanner > egg pod)
--                        3 comfort (straw pile > cushions > trampoline > slime bed > cloud bed)
--                        4 warmth (oil lamp > heat lamp > warming stove > monitor > holo beacon)
--   levels 6-10          the pen's builds move up one material tier, one a level: fence, pen floor,
--                        nest platforms, incubator pad, gate arch
-- Tiers and helpers are the pantry's: the stud look, a tier in its colours, every prop at its real
-- height (the player is 5 studs). Nests and incubators keep their invisible markers (NestHollowN with
-- an Attachment NestN, IncBedN with IncubatorN) for the breeding rules. Positions are in the pen's
-- own frame (x across, z from the gate in).
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)

local BreedingStages = {}

BreedingStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the pen: x -11 .. 19, z -13 .. 13, the gate x 0 .. 8 at the front
local X0, X1, Z0, Z1, GATE0, GATE1 = -11, 19, -13, 13, 0, 8

-- The nesting shelter at the back of the pen (the owner, 2026-10-28: the cake house did not fit the
-- farm's buildings; ChatGPT's layout stays; open, not a closed house): in the era's material tier, a
-- bigger shelter each era with its own roof, open to the gate, a heart in the front truss (the
-- pen's mark), nest cubbies along its back, and one piece that says what it is for: straw and a
-- lantern, a cupola, an iron stove, a skylight over the nests, a glowing heart lantern.
-- era -> width, depth, height to the beams, roof rise, width of the straw spill at the front
local BARN = {
	-- (the beams 6+ studs clear of the floor: a player walks in under them)
	{ 9, 7, 6.6, 3.6, 3.2 },
	{ 10.5, 7.5, 6.8, 4.2, 3.6 },
	{ 11.5, 8, 7, 3.6, 3.8 },
	{ 12.5, 8.5, 7.2, 1.8, 4.2 },
	{ 13, 8.5, 7.4, 3, 4.2 },
}
local BX, BZ = 4, 2.6 -- the middle of its front face (the gate's middle is x 4)

-- nests and incubators: where, and from which level
local NESTS = { { -5.5, -2, 1 }, { 13.5, -2, 1 }, { -7.5, -9, 11 }, { 19, -9, 31 } }
-- From the 4th nest's era the pen grows 4 studs on its left, so that nest and the comfort corner both
-- have room (ChatGPT's 1st breeding review); it never shrinks again.
local X1_WIDE, WIDE_FROM = 23, 31
local INCUBATORS = { { -17, -3.5, 1 }, { -17, 5.5, 1 }, { -17, -10.5, 21 }, { -17, 12.5, 41 } }

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
-- Each slot where it does its job (the owner, 2026-10-28: ask of every piece "does it belong here");
-- +x is the pen's left as one walks in, the incubators stand outside its right fence:
--   feed     on the left right beside the hay bale, the pen's feed store
--   egg care on the right just inside the side gate to the incubators (eggs go from nests to them)
--   comfort  in the front-left, inward from the gate post so it shows from the gate
--   warmth   against the right fence between the two right-hand nests, warming them (ChatGPT's 1st
--            review: at the gate it read as a gate light)
local SLOT_AT = { { 15.5, 4.8 }, { -8.6, 5 }, { 12, -7.2 }, { -9.8, -5 } }
local FOOT = { 3.4, 3, 4, 2.2 }
local LIFT = { [3] = { [5] = 1 } } -- the cloud bed floats
local FLOOR = 0.4 -- the pen's floor stands this far above the lawn; what is on it stands on its top
-- the side gate in the right fence, toward the incubators
local SIDE0, SIDE1 = -1.2, 2.8

-- What a level holds: the cottage's era, how many nests and incubators, each prop slot's era (0:
-- none), each build's tier (fence, floor, nest platforms, incubator pad, gate arch).
function BreedingStages.state(level: number): (number, number, number, { number }, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local nests, incubators = 0, 0
	for _, n in NESTS do
		nests += if level >= n[3] then 1 else 0
	end
	for _, n in INCUBATORS do
		incubators += if level >= n[3] then 1 else 0
	end
	local props, tiers = {}, {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	for k = 1, 5 do
		tiers[k] = if s >= k + 5 then era + 1 else era
	end
	return era, nests, incubators, props, tiers
end

function BreedingStages.tierName(level: number): string
	local _, _, _, _, tiers = BreedingStages.state(level)
	return TIERS[tiers[1]].name
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

-- A ranch fence run: posts every three studs, two rails.
local function fenceRun(m: Model, frame: CFrame, x0: number, z0: number, x1: number, z1: number, t: any)
	local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local along = CFrame.lookAt(Vector3.zero, dir)
	local n = math.max(1, math.round(len / 3))
	for k = 0, n do
		local p = a + dir * (len * k / n)
		part(m, "PenPost", Vector3.new(0.7, 3.4, 0.7), frame * CFrame.new(p.X, 1.7, p.Z), t.frame, t.frameMat)
		-- (a glowing trim lights every other cap only, so the fence does not outshine the pen)
		local dim = t.trimMat == Enum.Material.Neon and k % 2 == 1
		part(
			m,
			"PenPostCap",
			Vector3.new(0.95, 0.3, 0.95),
			frame * CFrame.new(p.X, 3.5, p.Z),
			if dim then t.frame else t.trim,
			if dim then t.frameMat else t.trimMat
		)
	end
	local mid = (a + b) / 2
	for _, y in { 1.2, 2.6 } do
		part(m, "PenRail", Vector3.new(0.3, 0.4, len), frame * CFrame.new(mid.X, y, mid.Z) * along, t.walls, t.wallMat)
	end
end

-- An incubator standing on `base` (its foot, front to -Z): a cream drum with a pink band, a straw
-- bed at the height an egg is set (IncBedN, y 2.8 above the foot), a clear glass dome over it, a
-- warm lamp cap on top and a gauge on the front. The cap takes the pad's tier colour.
local function incubator(m: Model, base: CFrame, t: any)
	local cream, pink = Color3.fromRGB(255, 244, 228), Color3.fromRGB(240, 132, 168)
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
	drum("IncBody", 1.2, 2.4, 3.6, cream)
	drum("IncBand", 2.5, 0.4, 3.9, pink)
	drum("IncStraw", 2.65, 0.3, 3, Color3.fromRGB(232, 196, 120), Enum.Material.Fabric)
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
	local cap = drum("IncCap", 4.5, 0.4, 1.1, t.trim, t.trimMat)
	local glow = drum("IncLamp", 4.25, 0.2, 0.8, Color3.fromRGB(255, 200, 120), Enum.Material.Neon)
	glow.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 120)
	light.Range = 7
	light.Brightness = 0.8
	light.Parent = cap
	local gauge = part(
		m,
		"IncGauge",
		Vector3.new(0.15, 0.9, 0.9),
		base * CFrame.new(-0.6, 1.3, -1.82) * CFrame.Angles(0, math.rad(90), 0),
		cream
	) :: Part
	gauge.Shape = Enum.PartType.Cylinder
	part(m, "IncButton", Vector3.new(0.4, 0.4, 0.2), base * CFrame.new(0.7, 1.3, -1.82), Color3.fromRGB(230, 70, 70))
end

-- The nesting shelter of an era (see BARN): open on every side so what the slimes do inside shows
-- (the owner, 2026-10-28: "a covered frame, not a closed house"): a base with a soft bed that
-- changes with the era, posts at the corners and the side middles, beams round the top with knee
-- braces, a gable roof whose ridge runs to the back, an open truss to the gate with the pen's big
-- pink heart in it, a closed back gable, resting cubbies with straw in a low back wall, and the era's
-- own structural piece (ChatGPT's 2nd breeding review): a lantern, a real cupola, brick piers with an
-- iron stove on its hearth, glass panes in a steel roof, a slime-tech ridge conduit and lantern.
local function nestingBarn(m: Model, frame: CFrame, era: number)
	local t = TIERS[era]
	local b = BARN[era]
	local w, d, h, rise, dw = b[1], b[2], b[3], b[4], b[5]
	local zc, zb = BZ + d / 2, BZ + d
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(BX + x, FLOOR + y, z)
	end
	local dark = Color3.fromRGB(46, 40, 38)
	local pink = Color3.fromRGB(240, 132, 168)
	local deepPink = Color3.fromRGB(176, 72, 112)
	local straw = Color3.fromRGB(240, 206, 120)
	local strawLight = Color3.fromRGB(252, 226, 150)
	local iron = Color3.fromRGB(60, 60, 66)
	local mint = Color3.fromRGB(120, 230, 200)
	-- (on slime tech the trim glows; the shelter keeps its glow for the heart and a few accents)
	local soft, softMat = t.trim, t.trimMat
	if softMat == Enum.Material.Neon then
		soft, softMat = t.frame, t.frameMat
	end

	-- the base
	part(m, "ShelterBase", Vector3.new(w + 0.6, 0.5, d + 0.6), at(0, 0.25, zc), t.base, t.baseMat)

	-- the bed under the roof, raised and soft, its own kind each era; the stove's corner kept clear
	local bx = if era == 3 then 1.3 else 0 -- (the brick era's stove stands in the right-hand bay)
	local bw, bd = w - 1.4 - (if era == 3 then 2.6 else 0), d - 3
	local bz = BZ + 0.6 + bd / 2
	if era == 3 then
		part(m, "BedPlinth", Vector3.new(bw + 0.5, 0.35, bd + 0.5), at(bx, 0.67, bz), t.walls, t.wallMat)
	end
	local bedTop = if era == 3 then 0.85 else 0.5
	local bedCol, bedMat = straw, Enum.Material.SmoothPlastic
	if era == 4 then
		bedCol, bedMat = Color3.fromRGB(236, 226, 210), Enum.Material.SmoothPlastic
	elseif era == 5 then
		bedCol, bedMat = Color3.fromRGB(196, 240, 222), Enum.Material.SmoothPlastic
	end
	part(m, "ShelterBed", Vector3.new(bw, 0.3, bd), at(bx, bedTop + 0.15, bz), bedCol, bedMat)
	if era <= 3 then
		-- a lighter hollow in the middle, straw heaped at the edges
		part(
			m,
			"BedHollow",
			Vector3.new(bw * 0.5, 0.06, bd * 0.5),
			at(bx, bedTop + 0.32, bz),
			strawLight,
			Enum.Material.SmoothPlastic
		)
		for _, o in { { -1, 0.6, 0 }, { 1, -0.6, math.pi }, { 0.2, 1, math.pi / 2 } } do
			wedge(
				m,
				"StrawHeap",
				Vector3.new(1.6, 0.6, 1.2),
				at(bx + o[1] * (bw / 2 - 0.9), bedTop + 0.6, bz + o[2] * (bd / 2 - 0.7)) * CFrame.Angles(0, o[3], 0),
				straw,
				Enum.Material.SmoothPlastic
			)
		end
	elseif era == 4 then
		-- padded sections
		for k = -1, 1 do
			part(
				m,
				"BedPad",
				Vector3.new(bw / 3 - 0.3, 0.2, bd - 0.4),
				at(bx + k * bw / 3, bedTop + 0.4, bz),
				Color3.fromRGB(150, 200, 230),
				Enum.Material.SmoothPlastic
			)
		end
	else
		-- a mint and pink slime mattress with a soft glowing edge
		part(
			m,
			"BedPad",
			Vector3.new(bw - 0.8, 0.2, bd - 0.8),
			at(bx, bedTop + 0.4, bz),
			Color3.fromRGB(255, 200, 220),
			Enum.Material.SmoothPlastic
		)
		local rim = part(
			m,
			"BedGlow",
			Vector3.new(bw + 0.1, 0.08, bd + 0.1),
			at(bx, bedTop + 0.02, bz),
			mint,
			Enum.Material.Neon
		)
		rim.CastShadow = false
	end
	if era == 2 then
		-- two pastel cushions on the straw
		part(
			m,
			"BedCushion",
			Vector3.new(1.6, 0.5, 1.2),
			at(bx - 0.25 * bw, bedTop + 0.55, bz + 0.3),
			Color3.fromRGB(255, 196, 214),
			Enum.Material.SmoothPlastic
		)
		part(
			m,
			"BedCushion",
			Vector3.new(1.6, 0.5, 1.2),
			at(bx + 0.25 * bw, bedTop + 0.55, bz + 0.3),
			Color3.fromRGB(196, 220, 255),
			Enum.Material.SmoothPlastic
		)
	end

	-- posts (brick piers with caps and feet on the brick era, flanged steel from the steel era), the
	-- beams round the top, knee braces at the open front
	local postCol, postMat, pw = t.frame, t.frameMat, 0.55
	if era == 3 then
		postCol, postMat, pw = t.walls, t.wallMat, 1.1
	end
	for _, sx in { -1, 1 } do
		for _, z in { BZ, zc, zb } do
			part(m, "ShelterPost", Vector3.new(pw, h, pw), at(sx * w / 2, 0.5 + h / 2, z), postCol, postMat)
			if era == 3 then
				part(m, "PierFoot", Vector3.new(pw + 0.3, 0.5, pw + 0.3), at(sx * w / 2, 0.75, z), t.base, t.baseMat)
				part(
					m,
					"PierCap",
					Vector3.new(pw + 0.25, 0.3, pw + 0.25),
					at(sx * w / 2, 0.5 + h - 0.6, z),
					t.base,
					t.baseMat
				)
			elseif era >= 4 then
				for _, fz in { -1, 1 } do
					part(
						m,
						"PostFlange",
						Vector3.new(pw + 0.35, h, 0.12),
						at(sx * w / 2, 0.5 + h / 2, z + fz * pw / 2),
						postCol,
						postMat
					)
				end
			end
		end
		part(m, "ShelterBeam", Vector3.new(0.45, 0.45, d + 0.6), at(sx * w / 2, 0.5 + h - 0.2, zc), t.frame, t.frameMat)
		part(
			m,
			"ShelterBrace",
			Vector3.new(0.25, 1.8, 0.25),
			at(sx * (w / 2 - 0.6), 0.5 + h - 0.85, BZ) * CFrame.Angles(0, 0, sx * math.rad(45)),
			t.frame,
			t.frameMat
		)
	end
	for _, z in { BZ, zb } do
		part(m, "ShelterBeam", Vector3.new(w + 0.6, 0.45, 0.45), at(0, 0.5 + h - 0.2, z), t.frame, t.frameMat)
	end
	local top = 0.5 + h

	-- the roof: two slopes from a ridge running front to back; the back gable closed, the front an
	-- open truss (a king post) so the inside shows
	local reach = w / 2 + 0.7
	local pitch = math.atan2(rise, w / 2)
	local slope = reach / math.cos(pitch)
	for _, sx in { -1, 1 } do
		local slab = at(sx * reach / 2, top + rise - reach * math.tan(pitch) / 2 + 0.2, zc)
			* CFrame.Angles(0, 0, -sx * pitch)
		part(m, "ShelterRoof", Vector3.new(slope, 0.45, d + 1.4), slab, t.roof, t.roofMat)
		if era == 4 then
			-- glass panes set in the steel roof, steel rails round them: light over the bed
			local pane = part(
				m,
				"Skylight",
				Vector3.new(slope * 0.45, 0.1, d * 0.6),
				slab * CFrame.new(-sx * slope * 0.12, 0.25, 0),
				Color3.fromRGB(170, 225, 245),
				Enum.Material.Glass
			)
			pane.Transparency = 0.25
			for _, rz in { -1, 1 } do
				part(
					m,
					"SkylightRail",
					Vector3.new(slope * 0.47, 0.14, 0.14),
					slab * CFrame.new(-sx * slope * 0.12, 0.3, rz * d * 0.3),
					t.trim,
					t.trimMat
				)
			end
		end
		-- (a wedge's tall face is its +Z; turned so it rises toward the ridge)
		wedge(
			m,
			"ShelterGable",
			Vector3.new(0.3, rise, w / 2),
			at(sx * w / 4, top + rise / 2, zb) * CFrame.Angles(0, -sx * math.pi / 2, 0),
			t.walls,
			t.wallMat
		)
	end
	part(m, "ShelterRidge", Vector3.new(0.5, 0.5, d + 1.6), at(0, top + rise + 0.25, zc), soft, softMat)
	part(m, "ShelterKingPost", Vector3.new(0.35, rise, 0.35), at(0, top + rise / 2, BZ), t.frame, t.frameMat)

	-- the pen's heart, big and solid pink on a darker backing, hung in the front truss (under the
	-- beam on the low steel roof); a bit bigger each era, glowing on slime tech
	local s = 1 + 0.12 * (era - 1)
	local hy = if rise >= 3 then top + rise * 0.42 else top - 1.6
	local function heart(dz: number, k: number, col: Color3, mat: Enum.Material)
		local z = BZ - 0.3 + dz
		for _, dx in { -0.5, 0.5 } do
			local lobe = part(
				m,
				"ShelterHeart",
				Vector3.new(1.45 * k, 1.45 * k, 0.3),
				at(dx * k, hy + 0.32 * k, z),
				col,
				mat
			) :: Part
			lobe.Shape = Enum.PartType.Ball
		end
		part(
			m,
			"ShelterHeart",
			Vector3.new(1.2 * k, 1.2 * k, 0.3),
			at(0, hy - 0.12 * k, z) * CFrame.Angles(0, 0, math.rad(45)),
			col,
			mat
		)
	end
	heart(0.18, 1.18 * s, deepPink, Enum.Material.SmoothPlastic)
	heart(0, s, pink, if era == 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic)

	-- a low back wall with resting cubbies in it: open boxes with a warm wood inside and straw in them
	part(m, "BackWall", Vector3.new(w, 1.8, 0.5), at(0, 1.4, zb - 0.25), t.walls, t.wallMat)
	local n = if era >= 3 then 4 else 3
	for k = 1, n do
		local x = (k - (n + 1) / 2) * (w - 1.6) / n
		local cz = zb - 1.2
		part(
			m,
			"CubbyBack",
			Vector3.new(1.9, 1.7, 0.2),
			at(x, 1.35, cz + 0.6),
			Color3.fromRGB(176, 128, 84),
			Enum.Material.Wood
		)
		for _, ex in { -1, 1 } do
			part(m, "CubbySide", Vector3.new(0.2, 1.7, 1.4), at(x + ex * 0.85, 1.35, cz), soft, softMat)
		end
		part(m, "CubbyTop", Vector3.new(1.9, 0.2, 1.4), at(x, 2.2, cz), soft, softMat)
		part(m, "CubbyStraw", Vector3.new(1.5, 0.35, 1.2), at(x, 0.7, cz), straw, Enum.Material.SmoothPlastic)
		if era == 5 then
			part(m, "CubbyEdge", Vector3.new(1.9, 0.08, 0.08), at(x, 2.3, cz - 0.7), mint, Enum.Material.Neon).CastShadow =
				false
		end
	end

	-- the era's own piece
	local ridge = top + rise
	if era == 1 then
		-- straw spilling out over the front, a lantern hung from the front beam
		part(
			m,
			"ShelterStrawSpill",
			Vector3.new(dw + 1.2, 0.14, 1.6),
			at(0, 0.07, BZ - 0.9),
			straw,
			Enum.Material.SmoothPlastic
		)
		part(m, "LampChain", Vector3.new(0.1, 0.6, 0.1), at(w / 2 - 1.2, top - 0.75, BZ), dark)
		part(m, "ShelterLamp", Vector3.new(0.5, 0.7, 0.5), at(w / 2 - 1.2, top - 1.4, BZ), t.glass, Enum.Material.Neon).CastShadow =
			false
	elseif era == 2 then
		-- a real cupola on the ridge, airing the nests: a square body with dark vent slots, a little
		-- gable roof and a finial
		local cy = ridge + 0.3
		part(m, "Cupola", Vector3.new(2, 1.8, 2), at(0, cy + 0.9, zc), t.walls, t.wallMat)
		for _, fz in { -1, 1 } do
			for _, vx in { -0.45, 0, 0.45 } do
				part(m, "CupolaSlot", Vector3.new(0.22, 1.1, 0.1), at(vx, cy + 0.95, zc + fz * 1.01), dark)
			end
		end
		for _, sx in { -1, 1 } do
			part(
				m,
				"CupolaRoof",
				Vector3.new(1.6, 0.25, 2.5),
				at(sx * 0.62, cy + 2.15, zc) * CFrame.Angles(0, 0, -sx * math.rad(35)),
				t.roof,
				t.roofMat
			)
		end
		local fin = part(m, "CupolaFinial", Vector3.one * 0.5, at(0, cy + 2.75, zc), t.trim, t.trimMat) :: Part
		fin.Shape = Enum.PartType.Ball
	elseif era == 3 then
		-- an iron stove on a stone hearth in the right-hand bay, a low brick guard toward the bed,
		-- its flue up through the roof
		local sx, sz = -w / 2 + 1.5, zc - 0.2
		part(m, "Hearth", Vector3.new(2.2, 0.25, 2.2), at(sx, 0.62, sz), t.base, t.baseMat)
		part(m, "Stove", Vector3.new(1.4, 1.5, 1.3), at(sx, 1.5, sz), iron, Enum.Material.Metal)
		part(
			m,
			"StoveFire",
			Vector3.new(0.8, 0.5, 0.1),
			at(sx, 1.35, sz - 0.66),
			Color3.fromRGB(255, 140, 60),
			Enum.Material.Neon
		).CastShadow =
			false
		part(m, "StoveGuard", Vector3.new(0.35, 0.9, 2.2), at(sx + 1.3, 0.95, sz), t.walls, t.wallMat)
		local head = top + rise * 0.3 + 1.6
		part(
			m,
			"StoveFlue",
			Vector3.new(0.45, head - 2.25, 0.45),
			at(sx, 2.25 + (head - 2.25) / 2, sz),
			iron,
			Enum.Material.Metal
		)
		part(m, "FlueCap", Vector3.new(0.8, 0.25, 0.8), at(sx, head + 0.12, sz), iron, Enum.Material.Metal)
	elseif era == 4 then
		part(m, "RoofVent", Vector3.new(1.2, 0.9, 1.2), at(w / 4, ridge - 0.2, BZ + d * 0.8), t.trim, t.trimMat)
	else
		-- a mint conduit along the ridge, and a lantern on it with a glowing heart inside
		part(m, "RidgeConduit", Vector3.new(0.2, 0.2, d + 1.2), at(0, ridge + 0.55, zc), mint, Enum.Material.Neon).CastShadow =
			false
		part(m, "LanternBase", Vector3.new(2.2, 1, 2.2), at(0, ridge + 0.6, zc), t.walls, t.wallMat)
		part(m, "LanternInside", Vector3.new(1.4, 1.5, 1.4), at(0, ridge + 1.85, zc), dark)
		local glow =
			part(m, "LanternHeart", Vector3.one * 0.9, at(0, ridge + 1.85, zc), pink, Enum.Material.Neon) :: Part
		glow.Shape = Enum.PartType.Ball
		glow.CastShadow = false
		for _, o in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
			part(
				m,
				"LanternPost",
				Vector3.new(0.3, 1.6, 0.3),
				at(o.X * 0.85, ridge + 1.85, zc + o.Z * 0.85),
				soft,
				softMat
			)
		end
		part(m, "LanternCap", Vector3.new(2.4, 0.35, 2.4), at(0, ridge + 2.8, zc), t.roof, t.roofMat)
		local fin = part(m, "LanternFinial", Vector3.one * 0.5, at(0, ridge + 3.2, zc), soft, softMat) :: Part
		fin.Shape = Enum.PartType.Ball
	end
end

-- The pen's layer for a level. `area` is the pen model: its kit fence, gate and cottage go (the
-- layer stands in for them); its floor and incubator pad take their tiers.
function BreedingStages.build(area: Instance, frame: CFrame, level: number): Model
	local era, nests, incubators, props, tiers = BreedingStages.state(level)
	local tf, tn, tp, tg = TIERS[tiers[1]], TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
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
			skin(d, tiers[2], TIERS[tiers[2]].yard, TIERS[tiers[2]].yardMat)
		elseif d.Name == "IncubatorPad" and d:IsA("BasePart") then
			skin(d, tiers[4], tp.base, tp.baseMat)
		end
	end

	-- the pen grown on its left from the 4th nest's era: its floor carried on, the scenery standing
	-- there taken away
	local x1 = if level >= WIDE_FROM then X1_WIDE else X1
	if x1 > X1 then
		local floor = area:FindFirstChild("PenFloor")
		local ext = part(
			m,
			"PenFloorExt",
			Vector3.new(x1 - X1, 0.4, Z1 - Z0),
			frame * CFrame.new((X1 + x1) / 2, 0.2, (Z0 + Z1) / 2),
			if floor and floor:IsA("BasePart") then floor.Color else TIERS[tiers[2]].yard
		)
		if floor and floor:IsA("BasePart") then
			ext.Material, ext.MaterialVariant, ext.TopSurface = floor.Material, floor.MaterialVariant, floor.TopSurface
		end
		for _, d in (area.Parent or area):GetDescendants() do
			if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
				local p = frame:PointToObjectSpace(d:GetPivot().Position)
				if p.X > X1 - 0.5 and p.X < x1 + 1.5 and p.Z > Z0 - 1 and p.Z < Z1 + 1 then
					d.Parent = nil
				end
			end
		end
	end

	-- the nesting shelter of this era, at the back of the pen, open to the gate
	nestingBarn(m, frame, era)

	-- 1 the fence, open at the gate
	fenceRun(m, frame, X0, Z1, x1, Z1, tf)
	-- (the right fence opens at a side gate toward the incubators, a paved step across the grass)
	fenceRun(m, frame, X0, Z0, X0, SIDE0, tf)
	fenceRun(m, frame, X0, SIDE1, X0, Z1, tf)
	part(
		m,
		"SidePath",
		Vector3.new(3.2, 0.4, SIDE1 - SIDE0), -- (right across to the pad's edge, no grass between)
		frame * CFrame.new(X0 - 1.6, 0.2, (SIDE0 + SIDE1) / 2),
		tp.base,
		tp.baseMat
	)
	fenceRun(m, frame, x1, Z0, x1, Z1, tf)
	fenceRun(m, frame, X0, Z0, GATE0, Z0, tf)
	fenceRun(m, frame, GATE1, Z0, x1, Z0, tf)

	-- 5 the gate arch: two posts, a board and a pink heart
	for _, x in { GATE0, GATE1 } do
		part(m, "GatePost", Vector3.new(0.9, 6.4, 0.9), frame * CFrame.new(x, 3.2, Z0), tg.frame, tg.frameMat)
	end
	part(
		m,
		"GateBoard",
		Vector3.new(GATE1 - GATE0 + 1.6, 1.2, 0.5),
		frame * CFrame.new((GATE0 + GATE1) / 2, 6.3, Z0),
		tg.walls,
		tg.wallMat
	)
	local pink = Color3.fromRGB(240, 132, 168)
	local heart = frame * CFrame.new((GATE0 + GATE1) / 2, 7.6, Z0 - 0.1)
	for _, dx in { -0.32, 0.32 } do
		local lobe = part(
			m,
			"GateHeart",
			Vector3.new(1, 1, 0.4),
			heart * CFrame.new(dx, 0.2, 0),
			pink,
			Enum.Material.SmoothPlastic
		) :: Part
		lobe.Shape = Enum.PartType.Ball
	end
	part(
		m,
		"GateHeart",
		Vector3.new(0.8, 0.8, 0.38),
		heart * CFrame.new(0, -0.12, 0) * CFrame.Angles(0, 0, math.rad(45)),
		pink
	)

	-- nests (the first two are the area's own), each on a round platform
	for i = 1, nests do
		local n = NESTS[i]
		local disc = part(
			m,
			"NestPlatform",
			Vector3.new(0.3, 5.6, 5.6),
			frame * CFrame.new(n[1], 0.55, n[2]) * CFrame.Angles(0, 0, math.rad(90)),
			tn.yard,
			tn.yardMat
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
				Vector3.new(7, 0.4, 4.6),
				frame * CFrame.new(n[1], 0.2, n[2]),
				if tiers[4] <= 1 then Color3.fromRGB(255, 244, 228) else tp.base,
				tp.baseMat
			)
		end
		incubator(m, frame * CFrame.new(n[1], 0.4, n[2]), tp)
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

	-- the care props
	for j = 1, 4 do
		local e = props[j]
		if e > 0 then
			local lift = FLOOR + (LIFT[j] and LIFT[j][e] or 0)
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
