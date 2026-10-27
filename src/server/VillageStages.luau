--!strict
-- The village's 50 levels: the tall fence, the gate and the plaza (the owner, 2026-10-28). The
-- village level follows the plot's areas: the average of their six levels, rounded down, so the
-- village grows as the player upgrades the farm. Five eras of ten levels; in each era:
--   level 1 of the era   the village grows, nothing taken away: the well in the plaza becomes a
--                        fountain, bigger every era (SmallFountain, TieredFountain, StatueFountain,
--                        GrandFountain); era 2 lanterns on the fence pillars and banner poles by the
--                        gate; era 3 stone wing walls either side of the gate; era 4 slime guardian
--                        statues outside the gate and pennants on the pillars; era 5 a golden crest
--                        over the gate
--   levels 2-5           four plaza props, one a level, each slot taking its next, better version:
--                        1 seating (log bench > park bench > garden swing > cafe table > golden
--                        bench)   2 notices (signpost > notice board > clock post > info kiosk > holo
--                        board)   3 stalls (flower cart > fruit stall > ice cream cart > bakery kiosk
--                        > goo vending machine)   4 garden (birdbath > topiary > sundial > light
--                        tree > slime crystal)
--   levels 6-10          the village's builds move up one material tier, one a level: plaza paving,
--                        path paving, fence pillars and plinth, lanterns and banners, the gate's
--                        stonework
-- Tiers and helpers are the pantry's. The kit fence, gate, lamps and planters stay as they are;
-- the pillars, plinth and the rest stand with them. Positions are in the plot's frame (x across, z
-- from the gate in, y up from the ground), the plaza at the middle.
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)

local VillageStages = {}

VillageStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

local HALF = 80 -- the fence line (Config.Map.PlotSize / 2)
local GATE = 10.5 -- the gate towers' x either side
local PLAZA = 15 -- the plaza's radius: paving inside it is the plaza's, beyond it the paths'

local CENTRES = { "", "SmallFountain", "TieredFountain", "StatueFountain", "GrandFountain" }
local CENTRE_HEIGHT = { 0, 5, 7, 9, 11 }
local CENTRE_FOOT = { 0, 8, 10, 12, 13 }

local PROPS = {
	{ "LogBench", "ParkBench", "GardenSwing", "CafeTable", "GoldenBench" },
	{ "Signpost", "NoticeBoard", "ClockPost", "InfoKiosk", "HoloBoard" },
	{ "FlowerCart", "FruitStall", "IceCreamCart", "BakeryKiosk", "GooVending" },
	{ "Birdbath", "Topiary", "Sundial", "LightTree", "SlimeCrystal" },
}
-- real heights (studs, the player is 5)
local HEIGHT = {
	{ 1.8, 2.8, 5.5, 5, 2.8 },
	{ 5.5, 5, 8, 5.5, 6 },
	{ 3.8, 5.5, 5, 6, 6 },
	{ 3, 4, 3.2, 7, 5 },
}
local FOOT = { 6, 4, 5, 4 }
-- the slots stand on the lawn round the plaza, in the gaps between the paths that have no lamp,
-- facing the plaza's middle: angle (degrees, 0 to the back, 180 to the gate) and distance
local SLOT_AT = { { 157.5, 21 }, { 247.5, 21 }, { 337.5, 21 }, { 67.5, 21 } }

-- What a level holds: the era, each prop slot's era (0: none), each build's tier (plaza, paths,
-- pillars and plinth, lanterns and banners, gate stonework).
function VillageStages.state(level: number): (number, { number }, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local props, tiers = {}, {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	for k = 1, 5 do
		tiers[k] = if s >= k + 5 then era + 1 else era
	end
	return era, props, tiers
end

-- The village's level from its areas' levels: their average, rounded down.
function VillageStages.levelOf(areaLevels: { number }): number
	local sum = 0
	for _, l in areaLevels do
		sum += l
	end
	return math.clamp(math.floor(sum / math.max(1, #areaLevels)), 1, VillageStages.MaxLevel)
end

function VillageStages.tierName(level: number): string
	local _, _, tiers = VillageStages.state(level)
	return TIERS[tiers[1]].name
end

-- A part of the village itself takes a tier's colour; at tier 1 it keeps the look it was built with.
local function skin(p: BasePart, tier: number, colour: Color3, material: Enum.Material)
	if p:GetAttribute("BuiltColor") == nil then
		p:SetAttribute("BuiltColor", p.Color)
	end
	p.Color = if tier <= 1 then p:GetAttribute("BuiltColor") :: Color3 else colour
	PondStages.studLook(p, material)
end

local function glow(m: Model, name: string, size: Vector3, cf: CFrame, colour: Color3, range: number?)
	local p = part(m, name, size, cf, colour, Enum.Material.Neon)
	p.CastShadow = false
	if range then
		local light = Instance.new("PointLight")
		light.Color = colour
		light.Range = range
		light.Brightness = 0.8
		light.Parent = p
	end
end

-- The pillar spots along the fence: every corner, and about every 24 studs between, leaving the gate
-- clear.
local function pillarSpots(): { Vector3 }
	local spots: { Vector3 } = {}
	local function run(a: Vector3, b: Vector3, ends: boolean)
		local n = math.max(1, math.round((b - a).Magnitude / 24))
		for k = if ends then 0 else 1, n do
			table.insert(spots, a:Lerp(b, k / n))
		end
	end
	run(Vector3.new(-HALF, 0, HALF), Vector3.new(HALF, 0, HALF), true) -- back, both corners
	run(Vector3.new(-HALF, 0, -HALF), Vector3.new(-HALF, 0, HALF), false) -- sides (back corners done)
	run(Vector3.new(HALF, 0, -HALF), Vector3.new(HALF, 0, HALF), false)
	run(Vector3.new(-HALF, 0, -HALF), Vector3.new(-GATE - 4, 0, -HALF), true) -- front, to the gate
	run(Vector3.new(HALF, 0, -HALF), Vector3.new(GATE + 4, 0, -HALF), true)
	-- the front corners were counted by the sides' starts too: drop duplicates
	local out: { Vector3 } = {}
	for _, p in spots do
		local seen = false
		for _, q in out do
			seen = seen or (p - q).Magnitude < 1
		end
		if not seen then
			table.insert(out, p)
		end
	end
	return out
end
local PILLARS = pillarSpots()

-- The village's layer for a level. `village` is the plot's Village model (paving, well, gate, fence);
-- `frame` is the plot's frame at the ground's top.
function VillageStages.build(village: Instance, frame: CFrame, level: number): Model
	local era, props, tiers = VillageStages.state(level)
	local tp, tl, tg = TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
	local m = Instance.new("Model")
	m.Name = "VillageStage"
	m:SetAttribute("Level", level)
	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end

	-- 1, 2 the paving: the plaza's tiles and the paths' tiles take their tiers
	for _, d in village:GetChildren() do
		if d.Name == "Paving" and d:IsA("BasePart") then
			local q = frame:PointToObjectSpace(d.Position)
			if Vector2.new(q.X, q.Z).Magnitude <= PLAZA then
				skin(d, tiers[1], TIERS[tiers[1]].base, TIERS[tiers[1]].baseMat)
			else
				skin(d, tiers[2], TIERS[tiers[2]].yard, TIERS[tiers[2]].yardMat)
			end
		elseif d.Name == "StoneWell" and d:IsA("Model") and era >= 2 then
			d.Parent = nil -- the fountain stands in for it
		end
	end

	-- the plaza's centrepiece from era 2
	if era >= 2 then
		place(m, frame, CENTRES[era], 0, 0, CENTRE_HEIGHT[era], CENTRE_FOOT[era])
	end

	-- 3 the fence's stone footing and pillars (lanterns on them from era 2, pennants from era 4)
	for _, run in
		{
			{ -HALF, HALF, HALF, HALF },
			{ -HALF, -HALF, -HALF, HALF },
			{ HALF, -HALF, HALF, HALF },
			{ -HALF, -HALF, -GATE - 1.5, -HALF },
			{ GATE + 1.5, -HALF, HALF, -HALF },
		}
	do
		local a, b = Vector3.new(run[1], 0, run[2]), Vector3.new(run[3], 0, run[4])
		local mid, len = (a + b) / 2, (b - a).Magnitude
		local size = if run[2] == run[4] then Vector3.new(len + 2.4, 1.4, 2.4) else Vector3.new(2.4, 1.4, len + 2.4)
		part(m, "FencePlinth", size, at(mid.X, 0.5, mid.Z), tp.base, tp.baseMat)
	end
	for k, p in PILLARS do
		part(m, "FencePillar", Vector3.new(2.8, 13, 2.8), at(p.X, 6.3, p.Z), tp.frame, tp.frameMat)
		part(m, "PillarCap", Vector3.new(3.6, 0.7, 3.6), at(p.X, 13.1, p.Z), tp.trim, tp.trimMat)
		if era >= 2 then
			glow(m, "PillarLantern", Vector3.new(1.4, 1.6, 1.4), at(p.X, 14.3, p.Z), tl.glass)
			part(m, "LanternCap", Vector3.new(2, 0.4, 2), at(p.X, 15.3, p.Z), tl.frame, tl.frameMat)
		end
		if era >= 4 and k % 2 == 0 then
			part(m, "PennantPole", Vector3.new(0.25, 4, 0.25), at(p.X, 17.5, p.Z), tl.frame, tl.frameMat)
			-- a small three-cornered flag pointing into the plot, its tall edge at the pole
			local top = at(p.X, 18.6, p.Z)
			local flag = CFrame.lookAt(top.Position, (top * CFrame.new(Vector3.new(-p.X, 0, -p.Z).Unit)).Position)
			wedge(
				m,
				"Pennant",
				Vector3.new(0.15, 1.4, 2.2),
				flag * CFrame.new(0, 0, -1.1),
				tl.trim,
				Enum.Material.Fabric
			)
		end
	end

	-- 5 the gate's stonework: a paved landing in front, from era 2 banner poles, era 3 wing walls,
	-- era 4 guardians, era 5 a crest
	part(m, "GateLanding", Vector3.new(GATE * 2 + 2, 0.4, 7), at(0, 0.2, -HALF - 4.5), tg.base, tg.baseMat)
	if era >= 2 then
		for _, s in { -1, 1 } do
			part(
				m,
				"BannerPole",
				Vector3.new(0.6, 15, 0.6),
				at(s * (GATE + 5.5), 7.5, -HALF - 3),
				tl.frame,
				tl.frameMat
			)
			part(
				m,
				"BannerBar",
				Vector3.new(3.4, 0.35, 0.35),
				at(s * (GATE + 5.5), 14.2, -HALF - 3.3),
				tl.frame,
				tl.frameMat
			)
			local banner = part(
				m,
				"Banner",
				Vector3.new(2.8, 6, 0.15),
				at(s * (GATE + 5.5), 10.9, -HALF - 3.4),
				tl.roof -- (the tier's roof colour: bright enough at every tier, unlike Fabric)
			)
			banner.CastShadow = false
			glow(m, "BannerStar", Vector3.new(1, 1, 0.2), at(s * (GATE + 5.5), 11.6, -HALF - 3.5), tl.glass)
		end
	end
	if era >= 3 then
		for _, s in { -1, 1 } do
			part(m, "GateWing", Vector3.new(4.5, 8, 2), at(s * (GATE + 3.4), 4, -HALF - 1.6), tg.walls, tg.wallMat)
			part(
				m,
				"GateWingCap",
				Vector3.new(5.1, 0.6, 2.6),
				at(s * (GATE + 3.4), 8.3, -HALF - 1.6),
				tg.trim,
				tg.trimMat
			)
		end
	end
	if era >= 4 then
		for _, s in { -1, 1 } do
			part(m, "GuardianPlinth", Vector3.new(3.4, 1.6, 3.4), at(s * 7.2, 0.8, -HALF - 6), tg.walls, tg.wallMat)
			local g = place(m, frame, "SlimeGuardian", s * 7.2, -HALF - 6, 4.5, 3.2, 1.6)
			if g then
				-- turned a little toward the path, as if greeting who comes in
				local box = g:GetBoundingBox()
				local centre = CFrame.new(box.Position)
				g:PivotTo(centre * CFrame.Angles(0, math.rad(s * 20), 0) * centre:ToObjectSpace(g:GetPivot()))
			end
		end
	end
	if era >= 5 then
		local crest = part(
			m,
			"GateCrest",
			Vector3.new(0.4, 4, 4),
			at(0, 18.6, -HALF - 1) * CFrame.Angles(0, math.rad(90), 0),
			tg.trim,
			tg.trimMat
		) :: Part
		crest.Shape = Enum.PartType.Cylinder
		glow(m, "CrestGem", Vector3.new(1.4, 1.4, 0.5), at(0, 18.6, -HALF - 1.3), tl.glass, 12)
	end

	-- the plaza props, facing the plaza's middle
	for j = 1, 4 do
		local e = props[j]
		if e > 0 then
			local a = math.rad(SLOT_AT[j][1])
			local dir = Vector3.new(math.sin(a), 0, math.cos(a))
			local p = dir * SLOT_AT[j][2]
			local facing = frame * CFrame.new(p) * CFrame.lookAt(Vector3.zero, -dir)
			place(m, facing, PROPS[j][e], 0, 0, HEIGHT[j][e], FOOT[j])
		end
	end
	return m
end

return VillageStages
