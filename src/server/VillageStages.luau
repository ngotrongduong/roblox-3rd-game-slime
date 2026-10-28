--!strict
-- The village's 50 levels: the tall fence, the gate, the paths and the plaza (the owner, 2026-10-28:
-- the fence and the gate must grow with the village, not just get pillars; lamps and paths change
-- with the levels; many decorations a level where the kind allows, each placed and turned sensibly).
-- The village level follows the plot's areas: the average of their six levels, rounded down.
-- Five eras of ten levels; in each era:
--   level 1 of the era   a new look for the whole village: the fence (era 1 the kit palisade, then
--                        painted timber, a stone wall with battlements, steel and glass, a marble
--                        balustrade), the gate (the kit gate, then a timber gatehouse, a stone
--                        gatehouse, a steel and glass portal, a marble arch), the paths' paving
--                        pattern, the lamp posts (12 of them, in the era's style) and the plaza's
--                        centrepiece (the well, then fountains, bigger every era)
--   level 2              seating: four nooks round the plaza (a bench facing the centrepiece, a
--                        lamp, a flower pot), the picnic green and the community green
--   level 3              more light: eight more lamps along the paths' far halves
--   level 4              the market street (one stall more every era, the older ones stay) and
--                        the notice board at the gate
--   level 5              the gardens: one garden piece of each era so far, and planters lining
--                        the gate avenue
--                        (what levels 2-5 add stays in every later era: never smaller)
--   levels 6-10          the builds move up one material tier, one a level: plaza paving, path
--                        paving, the fence's footing and walls, its pillars, the gate
-- Every model stands at its real height (the player is 5 studs). Tiers and helpers are the
-- pantry's. Positions are in the plot's frame (x across, z from the gate in, y up from the ground),
-- the plaza at the middle.
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)
local VillageWalls = require(script.Parent.VillageWalls)
local VillageFountain = require(script.Parent.VillageFountain)
local ServerStorage = game:GetService("ServerStorage")

local VillageStages = {}

VillageStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, place = PantryStages.part, PantryStages.place

local HALF = 80 -- the fence line (Config.Map.PlotSize / 2)
local PLAZA = 15 -- the plaza's radius: paving inside it is the plaza's, beyond it the paths'
local CAMP = Vector3.new(-160 / 3, 0, -160 / 3) -- the campfire's middle; its floor keeps its look

-- The paths out of the plaza as build_village lays them (from Layout's area fronts): angle
-- (degrees, atan2(x, z): 0 to the back, 180 to the gate) and the length from the middle.
local PATHS = {
	{ 0, 41.8 }, -- pantry
	{ 42, 57.5 }, -- fishing pond
	{ 90, 42.8 }, -- kitchen
	{ 135, 61.9 }, -- training ground
	{ 180, 79 }, -- the gate
	{ -135, 65 }, -- campfire
	{ -84.2, 39.5 }, -- breeding pen
	{ -45, 65.4 }, -- garden
}
-- the gaps between the paths, round the plaza (degrees)
local GAPS = { 21, 66, 112.5, 157.5, -157.5, -109.6, -64.6, -22.5 }

local CENTRE_FOOT = { 0, 9, 11, 12.5, 13.5 }

-- the era's models and their real heights
local LAMPS = { "VillageLamp", "LanternPost", "IronStreetLamp", "ModernLampPost", "GoldenLampPost" }
local LAMP_HEIGHT = { 8.4, 8.6, 9.2, 9.6, 9.2 }
local BENCHES = { "LogBench", "ParkBench", "IronBench", "ModernBench", "MarbleBench" }
local BENCH_HEIGHT = { 1.8, 2.7, 2.7, 1.5, 2.8 } -- (the modern bench has no back)
local STALLS = { "FlowerCart", "FruitStall", "IceCreamCart", "BakeryKiosk", "GooVending" }
local STALL_HEIGHT = { 3.6, 5.4, 5, 5.6, 5.6 }
local NOTICES = { "Signpost", "NoticeBoard", "ClockPost", "InfoKiosk", "HoloBoard" }
local NOTICE_HEIGHT = { 5.2, 4.6, 8, 5.2, 5.4 }
local GARDENS = { "Birdbath", "ClippedTopiary", "Sundial", "LightTree", "SlimeCrystal" }
local GARDEN_HEIGHT = { 3, 4.4, 3, 6.5, 4.6 }
-- the planters lining the gate avenue, each era's own (generated models, the owner, 2026-10-28:
-- props as fine as the greenhouse vegetables); their length along the path
local BEDS = { "FlowerBedWood", "FlowerBedWood", "FlowerBedBrick", "FlowerBedSteel2", "FlowerBedMarble" }
local BED_LENGTH = 5.4
-- the shelter over the picnic table: a timber gazebo, then a marble one
local PAVILIONS = { "", "PavilionWood", "PavilionWood", "PavilionMarble", "PavilionMarble" }
local PAVILION_HEIGHT = { 0, 12.5, 12.5, 15.5, 15.5 }
-- the plaza's seating nooks, in the path gaps either side of the gate avenue and of the sides
local NOOKS = { 2, 4, 5, 7 }
-- the market street's way, in the gap between the pantry and the garden paths
local MARKET = Vector3.new(math.sin(math.rad(GAPS[8])), 0, math.cos(math.rad(GAPS[8])))
local MARKET_ACROSS = Vector3.new(MARKET.Z, 0, -MARKET.X)
local function inMarket(p: Vector3): boolean
	local along = p:Dot(MARKET)
	return along > 18 and along < 54 and math.abs(p:Dot(MARKET_ACROSS)) < 10
end

-- What a level holds: the era, its step within the era (1-10), each build's tier (plaza, paths,
-- fence walls, fence pillars, gate).
function VillageStages.state(level: number): (number, number, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local tiers = {}
	for k = 1, 5 do
		tiers[k] = if s >= k + 5 then era + 1 else era
	end
	return era, s, tiers
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

-- An ivy vine climbing a wall from the ground: `face` stands at the wall's face at its foot, its
-- front away from the wall. A wandering stem with two side branches, the kit's ivy leaf along them
-- by turns either side, smaller as it climbs (the owner, 2026-10-28: the vine made of green slabs
-- was not pretty). The leaf is one generated mesh shared by every copy.
local function ivyVine(parent: Instance, face: CFrame, height: number, seed: number)
	local kit = ServerStorage:FindFirstChild("PropKit")
	if not kit then
		local bundle = ServerStorage:FindFirstChild("Kit")
		kit = bundle and bundle:FindFirstChild("PropKit")
	end
	local src = kit and kit:FindFirstChild("IvyLeaf")
	local leaf = src and src:FindFirstChildWhichIsA("BasePart", true)
	if not leaf then
		return
	end
	local stemColour = Color3.fromRGB(92, 104, 58)
	local rng = Random.new(seed)
	local function stem(a: Vector3, b: Vector3, thick: number)
		local p = part(
			parent,
			"IvyStem",
			Vector3.new(thick, thick, (b - a).Magnitude + thick),
			face * CFrame.lookAt((a + b) / 2, b),
			stemColour,
			Enum.Material.SmoothPlastic
		)
		p.CanCollide = false
		p.CastShadow = false
	end
	local function leafAt(at: Vector3, size: number, turn: number)
		local l = leaf:Clone() :: BasePart
		l.Name = "IvyLeaf"
		l.Size = leaf.Size * (size / math.max(leaf.Size.X, leaf.Size.Y))
		l.CFrame = face * CFrame.new(at) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, turn)
		l.Anchored = true
		l.CanCollide = false
		l.CanTouch = false
		l.CanQuery = false
		l.CastShadow = false
		l.Parent = parent
	end
	-- the stems: points up the wall (x across, y up, z out from the face)
	local function climb(from: Vector3, dir: Vector3, len: number, thick: number, leafSize: number)
		local steps = math.max(2, math.floor(len / 1.15))
		local p = from
		for j = 1, steps do
			local t = j / steps
			local q = from + dir * len * t + Vector3.new(math.sin(t * 5 + seed) * 0.35, 0, 0)
			q = Vector3.new(q.X, q.Y, -0.12)
			stem(p, q, thick * (1 - t * 0.5))
			-- (a pair of leaves at every step, one either side, the upper one smaller)
			for _, side in { -1, 1 } do
				local up = if (j + side) % 4 == 0 then 0.35 else 0
				leafAt(
					q + Vector3.new(side * rng:NextNumber(0.5, 0.8), 0.1 + up, -0.1),
					leafSize * (1.05 - t * 0.4) * rng:NextNumber(0.85, 1.15) * (1 - up),
					side * rng:NextNumber(0.3, 0.9)
				)
			end
			p = q
		end
	end
	climb(Vector3.new(0, 0, -0.12), Vector3.new(0.08, 1, 0).Unit, height, 0.3, 2.1)
	climb(Vector3.new(0.1, height * 0.25, -0.12), Vector3.new(-0.8, 1, 0).Unit, height * 0.5, 0.22, 1.8)
	climb(Vector3.new(0, height * 0.45, -0.12), Vector3.new(0.85, 1, 0).Unit, height * 0.45, 0.2, 1.7)
	-- a few leaves at its root
	for k = -1, 1 do
		leafAt(Vector3.new(k * 0.8, 0.6, -0.2), 2, k * 0.9)
	end
end

local function dirOf(degrees: number): Vector3
	local a = math.rad(degrees)
	return Vector3.new(math.sin(a), 0, math.cos(a))
end

-- A point beside path `i`: `t` of the way from the plaza's edge to its end, `side` (-1, 1) and
-- `off` studs out from its middle line; and the way to face the path from there.
local function besidePath(i: number, t: number, side: number, off: number): (Vector3, Vector3)
	local d = dirOf(PATHS[i][1])
	local across = Vector3.new(d.Z, 0, -d.X)
	local along = PLAZA + (PATHS[i][2] - PLAZA) * t
	return d * along + across * side * off, -across * side
end

-- The village's layer for a level. `village` is the plot's Village model (paving, well, gate,
-- fence, lamps); `frame` is the plot's frame at the ground's top.
function VillageStages.build(village: Instance, frame: CFrame, level: number): Model
	local era, s, tiers = VillageStages.state(level)
	-- what a level step of the era adds stays in every later era (the owner: the village never gets
	-- smaller with a level), in the new era's look
	local function has(step: number): boolean
		return era > 1 or s >= step
	end
	local m = Instance.new("Model")
	m.Name = "VillageStage"
	m:SetAttribute("Level", level)
	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	-- ===== free ground: nothing is set on the paving, in an area, on the fence line or on top of
	-- something already standing (the owner, 2026-10-28: a lamp in front of a bench, flowers in the
	-- middle of a path) =====
	local paved: { [string]: boolean } = {}
	for _, d in village:GetChildren() do
		if d.Name == "Paving" and d:IsA("BasePart") then
			local q = frame:PointToObjectSpace(d.Position)
			paved[math.floor(q.X / 2) .. "," .. math.floor(q.Z / 2)] = true
		end
	end
	local function onPaving(p: Vector3, r: number): boolean
		for _, o in
			{ Vector3.zero, Vector3.new(r, 0, 0), Vector3.new(-r, 0, 0), Vector3.new(0, 0, r), Vector3.new(0, 0, -r) }
		do
			local q = p + o
			if paved[math.floor(q.X / 2) .. "," .. math.floor(q.Z / 2)] then
				return true
			end
		end
		return false
	end
	-- the areas' boxes, in their own frames
	local areaBoxes: { { cf: CFrame, size: Vector3 } } = {}
	local plot = village.Parent
	if plot then
		for _, a in plot:GetChildren() do
			if a:IsA("Model") and string.match(a.Name, "L1$") then
				local cf, size = a:GetBoundingBox()
				table.insert(areaBoxes, { cf = cf, size = size })
			end
		end
	end
	local taken: { { at: Vector3, r: number } } = {} -- flat positions in the plot's frame
	local smallPlants: { { plant: Instance, at: Vector3 } } = {}
	-- (an area's own flowers that stand on the village's paving in front of its gate move too)
	for _, a in (if plot then plot:GetChildren() else {}) :: { Instance } do
		local areaNature = if a:IsA("Model") and string.match(a.Name, "L1$") then a:FindFirstChild("Nature") else nil
		for _, d in (if areaNature then areaNature:GetChildren() else {}) :: { Instance } do
			if d:IsA("Model") and (d.Name == "FlowerPatch" or d.Name == "GrassTuft" or d.Name == "Fern") then
				local q = frame:PointToObjectSpace(d:GetPivot().Position)
				local flat = Vector3.new(q.X, 0, q.Z)
				if onPaving(flat, 1.1) then
					local plant: Instance = d
					table.insert(smallPlants, { plant = plant, at = flat })
				end
			end
		end
	end
	-- what already stands in the village: trees, logs, stumps, the old planters, the campfire
	local nature = village:FindFirstChild("Nature")
	for _, d in (if nature then nature:GetChildren() else {}) :: { Instance } do
		local cf: CFrame, size: Vector3
		if d:IsA("Model") then
			cf, size = d:GetBoundingBox()
		elseif d:IsA("BasePart") then
			cf, size = d.CFrame, d.Size
		else
			continue
		end
		local q = frame:PointToObjectSpace(cf.Position)
		local flat = Vector3.new(q.X, 0, q.Z)
		local small = d.Name == "FlowerPatch" or d.Name == "GrassTuft" or d.Name == "Fern"
		if small then
			-- (they never block: see put; once the plaza has grown, those on paving move: see below)
			table.insert(smallPlants, { plant = d, at = flat })
		else
			table.insert(taken, { at = flat, r = math.min(math.min(size.X, size.Z) / 2, 3) })
		end
	end
	for _, d in village:GetChildren() do
		if d.Name == "Planter" and d:IsA("Model") then
			local q = frame:PointToObjectSpace(d:GetPivot().Position)
			table.insert(taken, { at = Vector3.new(q.X, 0, q.Z), r = 1.2 })
		end
	end
	table.insert(taken, { at = CAMP, r = 12 })
	local function free(p: Vector3, r: number): boolean
		if math.abs(p.X) > HALF - 4 - r or math.abs(p.Z) > HALF - 4 - r or onPaving(p, r * 0.8) then
			return false
		end
		local world = frame:PointToWorldSpace(p)
		for _, b in areaBoxes do
			local q = b.cf:PointToObjectSpace(world)
			if math.abs(q.X) < b.size.X / 2 + r and math.abs(q.Z) < b.size.Z / 2 + r then
				return false
			end
		end
		for _, t in taken do
			if (t.at - p).Magnitude < t.r + r + 1.2 then -- (room to walk between)
				return false
			end
		end
		return true
	end
	-- the nearest free spot for something of radius `r` meant for `pos`: it slides along `slide` (2
	-- studs a step, either way) and a little back from what it faces, or there is none
	local function findSpot(pos: Vector3, look: Vector3, r: number, slide: Vector3?): Vector3?
		local step = (slide or Vector3.new(look.Z, 0, -look.X)).Unit * 2
		local back = -look.Unit
		for _, out in { 0, 1.5, 3 } do
			for k = 0, 8 do
				for _, sign in (if k == 0 then { 1 } else { 1, -1 }) :: { number } do
					local p = pos + step * k * sign + back * out
					if free(p, r) then
						return p
					end
				end
			end
		end
		return nil
	end
	-- a kit model standing at `pos`, its front turned toward `look`, on free ground: if the spot is
	-- taken it slides (findSpot) until it is free, or is left out
	local function put(
		key: string,
		pos: Vector3,
		look: Vector3,
		height: number,
		foot: number,
		lift: number?,
		slide: Vector3?
	): Model?
		local spot = frame * CFrame.new(pos) * CFrame.lookAt(Vector3.zero, look)
		local model = place(m, spot, key, 0, 0, height, foot, lift)
		if not model then
			return nil
		end
		local _, size = model:GetBoundingBox()
		local r = math.max(size.X, size.Z) / 2
		local p = findSpot(pos, look, r, slide)
		if p then
			model:PivotTo(model:GetPivot() + frame:VectorToWorldSpace(p - pos))
			table.insert(taken, { at = p, r = r })
			-- (a flower patch or a tuft of grass under it goes rather than push it aside)
			for _, sp in smallPlants do
				if (sp.at - p).Magnitude < r + 0.6 then
					sp.plant.Parent = nil
				end
			end
			return model
		end
		model:Destroy()
		-- (named on the layer, so a model that found no room can be looked up in a play test)
		m:SetAttribute(
			"Skipped",
			((m:GetAttribute("Skipped") or "") :: string) .. string.format("%s@%.0f,%.0f ", key, pos.X, pos.Z)
		)
		return nil
	end
	local function glow(name: string, size: Vector3, cf: CFrame, colour: Color3, range: number?): BasePart
		local p = part(m, name, size, cf, colour, Enum.Material.Neon)
		p.CastShadow = false
		if range then
			local light = Instance.new("PointLight")
			light.Color = colour
			light.Range = range
			light.Brightness = 0.8
			light.Parent = p
		end
		return p
	end

	-- ===== the old kit pieces this layer takes over =====
	for _, d in village:GetChildren() do
		if
			d.Name == "VillageLamp"
			or d.Name == "GateSign" -- (no name sign over the gate: the owner, 2026-10-28)
			or (d.Name == "StoneWell" and era >= 2)
			or (d.Name == "VillageGate" and era >= 2)
			or (d.Name == "Fence" and d:IsA("Folder") and era >= 2)
		then
			d.Parent = nil
		end
	end

	-- ===== 1, 2 the paving: each era its pattern, each tier its colours =====
	local tiles: { [string]: BasePart } = {}
	for _, d in village:GetChildren() do
		if d.Name == "Paving" and d:IsA("BasePart") then
			local q = frame:PointToObjectSpace(d.Position)
			if (Vector3.new(q.X, 0, q.Z) - CAMP).Magnitude > 12 then
				tiles[math.floor(q.X / 2) .. "," .. math.floor(q.Z / 2)] = d
			end
		end
	end
	for key, d in tiles do
		local gx, gz = string.match(key, "(-?%d+),(-?%d+)")
		local x, z = tonumber(gx) :: number, tonumber(gz) :: number
		local edge = not (
			tiles[(x + 1) .. "," .. z]
			and tiles[(x - 1) .. "," .. z]
			and tiles[x .. "," .. (z + 1)]
			and tiles[x .. "," .. (z - 1)]
		)
		local q = frame:PointToObjectSpace(d.Position)
		local r = Vector2.new(q.X, q.Z).Magnitude
		if d:GetAttribute("BuiltColor") == nil then
			d:SetAttribute("BuiltColor", d.Color)
		end
		local inPlaza = r <= PLAZA
		local tier = if inPlaza then tiers[1] else tiers[2]
		local t = TIERS[tier]
		local colour: Color3
		if tier <= 1 and era <= 1 then
			colour = d:GetAttribute("BuiltColor") :: Color3
		elseif inPlaza then
			-- the plaza: a darker ring at its edge; from era 3 rings, from era 4 spokes too
			local ring = r > PLAZA - 2.2
			local band = era >= 3 and math.floor(r / 2.6) % 2 == 1
			local a = math.deg(math.atan2(q.X, q.Z)) % 45
			local spoke = era >= 4 and r > 6 and (a < 4 or a > 41)
			colour = if ring or spoke then t.edge elseif band then t.yard else t.base
		else
			-- the paths: from era 2 a border, from era 3 a checked middle, every path paved as finely as
			-- the avenue from the gate (the owner, 2026-10-28: the other paths looked unfinished)
			local check = era >= 3 and (x + z) % 2 == 0
			local border = edge and era >= 2
			colour = if border then t.edge elseif check then t.base else t.yard
		end
		d.Color = colour
		PondStages.studLook(d, Enum.Material.Plastic)
	end

	-- ===== the plaza grows each era, never smaller (ChatGPT's 1st village review: the heart of the
	-- village was only a crossroads): a ring of tiles round it, out to plazaR, in the plaza's colours
	-- with a darker rim =====
	local plazaR = PLAZA + (era - 1) * 1.5
	do
		local tp1 = TIERS[tiers[1]]
		local gr = math.ceil(plazaR / 2)
		for gx = -gr, gr - 1 do
			for gz = -gr, gr - 1 do
				local key = gx .. "," .. gz
				local cx, cz = gx * 2 + 1, gz * 2 + 1
				local r = Vector2.new(cx, cz).Magnitude
				if not paved[key] and r <= plazaR and r > PLAZA - 1 then
					paved[key] = true
					local tile = part(
						m,
						"PlazaTile",
						Vector3.new(2, 0.4, 2),
						at(cx, 0.2, cz),
						if r > plazaR - 2.2 then tp1.edge else tp1.base,
						Enum.Material.Plastic
					)
					tile.CastShadow = false
				end
			end
		end
	end

	-- ===== small plants on the paving (the plaza's ring, a path's edge) or in the market street move
	-- to the nearest free lawn (the owner, 2026-10-28: flowers growing on the path) =====
	for _, sp in smallPlants do
		if onPaving(sp.at, 1.1) or (has(4) and inMarket(sp.at)) then
			local to: Vector3? = nil
			for ring = 1, 6 do
				for k = 0, 7 do
					local a = k * math.pi / 4 + ring * 0.4
					local p = sp.at + Vector3.new(math.cos(a), 0, math.sin(a)) * ring * 1.6
					if not to and free(p, 1.1) and not (has(4) and inMarket(p)) then
						to = p
					end
				end
			end
			local plant = sp.plant
			if to then
				local shift = frame:VectorToWorldSpace(to - sp.at)
				if plant:IsA("Model") then
					plant:PivotTo(plant:GetPivot() + shift)
				elseif plant:IsA("BasePart") then
					plant.CFrame += shift
				end
				sp.at = to
			else
				plant.Parent = nil
			end
		end
	end

	-- ===== the plaza's centrepiece: the era's fountain, built with its moving water (VillageFountain)
	if era >= 2 then
		VillageFountain.build(m, frame, era, tiers[1])
		table.insert(taken, { at = Vector3.zero, r = CENTRE_FOOT[era] / 2 })
	end

	-- ===== 3, 4, 5 the fence and the main gate, each era's own (VillageWalls) =====
	VillageWalls.build(m, frame, era, tiers, { glow = glow, ivy = ivyVine })

	-- ===== the lamps: 12 at the era's start (one in each of the plaza's four seating nooks, beside
	-- where its bench comes, one beside each path), 8 more at its level 3 (the paths' far halves,
	-- the other side); all on the lawn, off the paving; the first 12 give light =====
	local lampSpots: { { Vector3 } } = {}
	for _, gi in NOOKS do
		local d = dirOf(GAPS[gi])
		table.insert(lampSpots, { d * (plazaR + 3.2) + Vector3.new(d.Z, 0, -d.X) * 4.8, -d })
	end
	-- (a lamp that would stand in the market street goes to the path's other side)
	local function lampBeside(i: number, t: number, side: number)
		local p, look = besidePath(i, t, side, 5.6)
		if has(4) and inMarket(p) then
			p, look = besidePath(i, t, -side, 5.6)
		end
		table.insert(lampSpots, { p, look })
	end
	for i = 1, #PATHS do
		lampBeside(i, 0.5, if i % 2 == 0 then 1 else -1)
	end
	if has(3) then
		for i = 1, #PATHS do
			lampBeside(i, 0.85, if i % 2 == 0 then -1 else 1)
		end
	end
	for k, spot in lampSpots do
		local lamp: Instance? = nil
		if era == 2 then
			-- (a generated Victorian lamp: the kit LanternPost was a 4-stud wall lantern and the one built
			-- from parts too plain; the owner, 2026-10-28)
			lamp = put("PaintedLampPost", spot[1], spot[2], 9, 3)
		elseif era == 4 then
			lamp = put("SteelStreetLamp", spot[1], spot[2], 9.6, 3)
		else
			lamp = put(LAMPS[era], spot[1], spot[2], LAMP_HEIGHT[era], 3)
		end
		if lamp and k <= 12 and era >= 2 then
			-- the generated lamps carry no light of their own: one at the head
			local model = lamp :: Model
			local box, size = model:GetBoundingBox()
			local head = Instance.new("Attachment")
			head.Parent = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
			head.WorldPosition = box.Position + Vector3.new(0, size.Y / 2 - 1, 0)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 214, 150)
			light.Range = 14
			light.Brightness = 0.9
			light.Parent = head
		end
	end

	local tPath = TIERS[tiers[2]]
	local function bit(name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?): BasePart
		local p = part(m, name, size, cf, colour, material or Enum.Material.SmoothPlastic)
		p.CanCollide = false
		p.CastShadow = false
		return p
	end
	-- a line of bunting between two points `h` high: a cord and little coloured flags
	local bunt = {
		Color3.fromRGB(240, 110, 110),
		Color3.fromRGB(250, 210, 90),
		Color3.fromRGB(110, 180, 240),
		Color3.fromRGB(150, 220, 130),
	}
	local function bunting(a: Vector3, b: Vector3, h: number)
		local len = (b - a).Magnitude
		local dir = (b - a).Unit
		local along = CFrame.lookAt(Vector3.zero, dir)
		bit(
			"BuntingCord",
			Vector3.new(0.06, 0.06, len),
			frame * CFrame.new((a + b) / 2 + Vector3.new(0, h, 0)) * along,
			Color3.fromRGB(240, 240, 240)
		)
		local n = math.floor(len / 1.4)
		for k = 1, n - 1 do
			local p = a:Lerp(b, k / n)
			local sag = -0.6 * math.sin(math.pi * k / n)
			local flag = Instance.new("WedgePart")
			flag.Name = "BuntingFlag"
			flag.Size = Vector3.new(0.08, 0.8, 0.7)
			flag.CFrame = frame
				* CFrame.new(p + Vector3.new(0, h + sag - 0.4, 0))
				* along
				* CFrame.Angles(math.pi, 0, 0)
			flag.Color = bunt[k % 4 + 1]
			flag.Anchored = true
			flag.CanCollide = false
			flag.CastShadow = false
			PondStages.studLook(flag, Enum.Material.SmoothPlastic)
			flag.Parent = m
		end
	end
	local function pole(x: number, z: number, h: number)
		part(m, "Pole", Vector3.new(0.35, h, 0.35), at(x, h / 2, z), tPath.frame, tPath.frameMat)
	end

	-- ===== level 2: seating with a purpose (the owner, 2026-10-28: benches set anyhow beside the paths
	-- had no reason to be there). Four nooks round the plaza, a bench in each facing the centrepiece
	-- with its lamp on one side and a flower pot on the other; the two front greens =====
	if has(2) then
		-- (one system with small local differences, ChatGPT's 3rd village review: the second nook
		-- has its lamp only, the fourth a pot either side of its bench)
		for k, gi in NOOKS do
			local d = dirOf(GAPS[gi])
			local side = Vector3.new(d.Z, 0, -d.X)
			local bench = put(BENCHES[era], d * (plazaR + 3.2), -d, BENCH_HEIGHT[era], 4.4, nil, d)
			if bench and k ~= 2 then
				local q = frame:PointToObjectSpace(bench:GetPivot().Position)
				local at0 = Vector3.new(q.X, 0, q.Z)
				put("FlowerPot", at0 - side * 4.3, -d, 2.6, 2.2, nil, d)
				if k == 4 then
					put("FlowerPot", at0 + side * 7.4, -d, 2.2, 1.9, nil, d)
				end
			end
		end

		-- the picnic green, front-left of the gate path: a shade tree, a picnic table laid for a meal
		-- under a gazebo from the painted era, a planter in front; half the green left open
		local g = dirOf(GAPS[4])
		local gc = g * 41
		local across = Vector3.new(g.Z, 0, -g.X)
		place(m, frame, "BroadleafTree", gc.X - across.X * 9, gc.Z - across.Z * 9, 13, 11)
		table.insert(taken, { at = gc - across * 9, r = 5 })
		local tc = gc + g * 3 -- (clear of the avenue's planters)
		local here = frame * CFrame.new(tc) * CFrame.lookAt(Vector3.zero, g)
		if PAVILIONS[era] ~= "" then
			place(m, here, PAVILIONS[era], 0, 0, PAVILION_HEIGHT[era], 15)
		end
		table.insert(taken, { at = tc, r = if PAVILIONS[era] ~= "" then 7.5 else 0 })
		-- (the picnic table on the open lawn between the gazebo and the shade tree, not inside the
		-- gazebo: the owner, 2026-10-28)
		put("PicnicTable", gc - g * 6 - across * 3, across, 4.6, 6.2)

		-- the community green, front-right: a worn clearing in a half ring of benches that face its
		-- open side, where the notice board stands, and from the brick era a little stage
		local h = dirOf(GAPS[5])
		local hc = h * 40
		local stageAt = hc - h * 6
		-- (the audience in a fan facing the stage behind a clear apron; ChatGPT's 3rd village
		-- review: three benches round a blob did not read as a place to watch from)
		for _, a in { -34, 0, 34 } do
			local d = (CFrame.Angles(0, math.rad(a), 0) * CFrame.lookAt(Vector3.zero, h)).LookVector
			put(BENCHES[era], stageAt + d * 11.5, -d, BENCH_HEIGHT[era], 4.4)
		end
		-- (the clearing: an uneven worn edge of smaller blobs; ChatGPT's 2nd village review: one flat
		-- cream disc looked unfinished)
		local worn = Color3.fromRGB(170, 150, 108)
		local function disc(centre: Vector3, d: number, y: number)
			local p = part(
				m,
				"GreenPatch",
				Vector3.new(0.1, d, d),
				frame * CFrame.new(centre + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				worn,
				Enum.Material.SmoothPlastic
			) :: Part
			p.Shape = Enum.PartType.Cylinder
			p.CastShadow = false
			p.CanCollide = false
		end
		local apron = stageAt + h * 5.5
		disc(apron, 6, 0.05)
		for k = 0, 6 do
			local a = math.rad(k * 51 + 20)
			disc(apron + Vector3.new(math.cos(a), 0, math.sin(a)) * 2.8, 1.6 + (k % 3) * 0.5, 0.04)
		end
		table.insert(taken, { at = apron, r = 3.2 }) -- (kept clear: the players' standing room)
		if era >= 3 then
			put("VillageStagePlatform", stageAt, h, 5.5, 6.4)
		else
			put(NOTICES[era], stageAt, h, NOTICE_HEIGHT[era], 3.6)
			if era == 2 then
				local hAcross = Vector3.new(h.Z, 0, -h.X)
				local poleA, poleB = hc - h * 7 + hAcross * 7, hc - h * 7 - hAcross * 7
				pole(poleA.X, poleA.Z, 6)
				pole(poleB.X, poleB.Z, 6)
				bunting(poleA, poleB, 5.8)
			end
		end
	end

	-- ===== level 4: the market, one place for every stall (ChatGPT's 1st village review): in the
	-- green between the pantry and the garden paths, a shallow U facing the plaza on its own paved
	-- square, one stall more each era (the older ones stay), crates, a barrel and a cart behind
	-- them, the market's arch over the way in, bunting; the notice board at the gate =====
	if has(4) then
		-- (a market street: the arch over its way in, stalls either side facing the aisle, the
		-- newest closing its end; the green between the two paths is only 12-16 studs wide)
		local mFace = CFrame.lookAt(Vector3.zero, -MARKET)
		-- (measured from the arch, which stands just beyond the plaza's ring, however big it grew)
		local start = math.min(plazaR + 3, 22.5) -- (the pantry yard begins about 17 studs beyond)
		local function m2(along: number, side: number): Vector3
			return MARKET * (start + along) + MARKET_ACROSS * side
		end
		for _, slab in { { 6, 8, 12 }, { 13, 7, 16 } } do
			part(
				m,
				"MarketSquare",
				Vector3.new(slab[3], 0.16, slab[2]),
				frame * CFrame.new(m2(slab[1], 0)) * mFace * CFrame.new(0, 0.08, 0),
				tPath.yard,
				tPath.baseMat
			)
		end
		-- (the first stalls well inside the arch: the owner, 2026-10-28, a cart touched its post)
		local stalls = { { 7.5, -4.8 }, { 7.5, 4.8 }, { 13.5, -4.8 }, { 13.5, 4.8 }, { 17.5, 0 } }
		table.insert(taken, { at = m2(1, 0), r = 3 }) -- (the way in under the arch stays open)
		for e = 1, era do
			local sp = stalls[e]
			local look = if sp[2] < 0 then MARKET_ACROSS elseif sp[2] > 0 then -MARKET_ACROSS else -MARKET
			put(STALLS[e], m2(sp[1], sp[2]), look, STALL_HEIGHT[e], 5, nil, MARKET)
		end
		-- (the arch spans the way in: placed as planned, only its two posts keep their ground)
		place(m, frame * CFrame.new(m2(0, 0)) * mFace, "MarketArch", 0, 0, 8.2, 8)
		put("CrateStack", m2(17.5, -7.5), MARKET_ACROSS, 2.6, 2.4)
		put("WoodBarrel", m2(17.5, 7.5), -MARKET_ACROSS, 2.4, 1.8)
		put("HandCart", m2(10.5, -8.5), MARKET_ACROSS, 3, 3)
		local ba, bb = m2(10.5, 7), m2(10.5, -7)
		pole(ba.X, ba.Z, 7)
		pole(bb.X, bb.Z, 7)
		bunting(ba, bb, 6.8)
		put(NOTICES[era], Vector3.new(9.5, 0, -HALF + 10), Vector3.new(-1, 0, 0), NOTICE_HEIGHT[era], 3.6)
	end

	-- ===== level 5: the garden pieces behind the nooks and in the back gaps, each kind once (the
	-- newest first, then the eras before it; the owner, 2026-10-28: two sundials side by side), and
	-- the era's planters spread through the village (the owner, 2026-10-28: all at the gate and
	-- nothing inside): a pair either side of the gate avenue, and one beside every other path where
	-- it leaves the plaza, along it =====
	if has(5) then
		for j, gg in ipairs({ 1, 7, 2, 3 }) do
			local e = era - (j - 1)
			if e >= 1 then
				local d = dirOf(GAPS[gg])
				put(GARDENS[e], d * (plazaR + 9), -d, GARDEN_HEIGHT[e], 4.5)
			end
		end
		for _, t in { 0.3, 0.62 } do
			for _, side in { -1, 1 } do
				local p, look = besidePath(5, t, side, 6.4)
				put(BEDS[era], p, look, 4, BED_LENGTH, nil, dirOf(PATHS[5][1]))
			end
		end
		for i = 1, #PATHS do
			if i ~= 5 then
				local side = if i % 2 == 0 then -1 else 1
				local p, look = besidePath(i, 0.3, side, 6.4)
				if not put(BEDS[era], p, look, 4, BED_LENGTH, nil, dirOf(PATHS[i][1])) then
					p, look = besidePath(i, 0.3, -side, 6.4)
					put(BEDS[era], p, look, 4, BED_LENGTH, nil, dirOf(PATHS[i][1]))
				end
			end
		end
	end
	return m
end

return VillageStages
