--!strict
-- The breeding pen's 50 levels (the owner, 2026-10-28: "the same as the pantry and the garden"). Five
-- eras of ten levels; in each era:
--   level 1 of the era   the pen grows: the cupcake cottage becomes a bigger cake house (CakeCottage2
--                        .. 5, more tiers each era), and a nest or an incubator is added (a 3rd nest
--                        at 11, a 3rd incubator at 21, a 4th nest at 31, a 4th incubator at 41)
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
local part, place = PantryStages.part, PantryStages.place

-- the pen: x -11 .. 19, z -13 .. 13, the gate x 0 .. 8 at the front
local X0, X1, Z0, Z1, GATE0, GATE1 = -11, 19, -13, 13, 0, 8

local COTTAGES = { "Cottage", "CakeCottage2", "CakeCottage3", "CakeCottage4", "CakeCottage5" }
-- sized by their width, so each era's house is clearly bigger (the later models are wider than tall)
local COTTAGE_HEIGHT = { 12.5, 30, 30, 30, 30 }
local COTTAGE_FOOT = { 10.5, 11.8, 12.8, 13.8, 14.4 }

-- nests and incubators: where, and from which level
local NESTS = { { -5.5, -2, 1 }, { 13.5, -2, 1 }, { -7.5, -9, 11 }, { 16, -9, 31 } }
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
	{ 1.6, 1.8, 1.4, 1.4, 2 },
	{ 4.6, 5.2, 4.4, 4.4, 4.6 },
}
local SLOT_AT = { { -9, 3.5 }, { 17, 3.5 }, { 11, -8.5 }, { -2, -9 } }
local FOOT = { 3.4, 3.4, 4, 3 }
local LIFT = { [3] = { [5] = 1 } } -- the cloud bed floats

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
		part(m, "PenPostCap", Vector3.new(0.95, 0.3, 0.95), frame * CFrame.new(p.X, 3.5, p.Z), t.trim, t.trimMat)
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

	-- the cottage of this era, at the back of the pen, its door to the gate
	place(m, frame, COTTAGES[era], 4, 5.8, COTTAGE_HEIGHT[era], COTTAGE_FOOT[era])

	-- 1 the fence, open at the gate
	fenceRun(m, frame, X0, Z1, X1, Z1, tf)
	fenceRun(m, frame, X0, Z0, X0, Z1, tf)
	fenceRun(m, frame, X1, Z0, X1, Z1, tf)
	fenceRun(m, frame, X0, Z0, GATE0, Z0, tf)
	fenceRun(m, frame, GATE1, Z0, X1, Z0, tf)

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
			local lift = LIFT[j] and LIFT[j][e]
			place(m, frame, PROPS[j][e], SLOT_AT[j][1], SLOT_AT[j][2], HEIGHT[j][e], FOOT[j], lift)
		end
	end
	return m
end

return BreedingStages
