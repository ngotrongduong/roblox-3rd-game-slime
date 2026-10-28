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
--   level 2              seating: a bench beside every path, facing it, and two facing the fountain
--   level 3              more light: eight more lamps along the paths' far halves
--   level 4              the market: stalls round the plaza (one more every era, the older ones
--                        stay) and notice boards at the gate and the plaza
--   level 5              the gardens: garden pieces in the path gaps (more from era 3) and flower
--                        planters lining the gate path
--   levels 6-10          the builds move up one material tier, one a level: plaza paving, path
--                        paving, the fence's footing and walls, its pillars, the gate
-- Every model stands at its real height (the player is 5 studs). Tiers and helpers are the
-- pantry's. Positions are in the plot's frame (x across, z from the gate in, y up from the ground),
-- the plaza at the middle.
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)

local VillageStages = {}

VillageStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

local HALF = 80 -- the fence line (Config.Map.PlotSize / 2)
local GATE_X = 11.5 -- the gate towers' middle, either side; the way through is 18 wide
local FENCE_END = 14.5 -- where the front fence runs stop beside the gate
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

local CENTRES = { "", "SmallFountain", "TieredFountain", "StatueFountain", "GrandFountain" }
local CENTRE_HEIGHT = { 0, 5, 8, 9.5, 11 }
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
local GARDENS = { "Birdbath", "Topiary", "Sundial", "LightTree", "SlimeCrystal" }
local GARDEN_HEIGHT = { 3, 3.6, 3, 6.5, 4.6 }

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
	local tw, tp, tg = TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
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
		if onPaving(flat, 0) and (d.Name == "FlowerPatch" or d.Name == "GrassTuft" or d.Name == "Fern") then
			d.Parent = nil -- small plants that ended up on a path go
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
			return model
		end
		model:Destroy()
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
			-- the paths: from era 2 a border, from era 3 a checked middle; the avenue from the gate is
			-- the grand one, the other paths stay calm (ChatGPT's 1st village review: every spoke as
			-- loud as the next looked like roads)
			local avenue = math.abs(q.X) < 4.5 and q.Z < 0
			local check = era >= 3 and avenue and (x + z) % 2 == 0
			local border = edge and era >= 2 and (avenue or era < 3)
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

	-- ===== the plaza's centrepiece =====
	if era >= 2 then
		place(m, frame, CENTRES[era], 0, 0, CENTRE_HEIGHT[era], CENTRE_FOOT[era])
		table.insert(taken, { at = Vector3.zero, r = CENTRE_FOOT[era] / 2 })
	end

	-- ===== 3, 4 the fence: footing and pillars always, walls in the era's style =====
	local runs = {
		{ Vector3.new(-HALF, 0, HALF), Vector3.new(HALF, 0, HALF) },
		{ Vector3.new(-HALF, 0, -HALF), Vector3.new(-HALF, 0, HALF) },
		{ Vector3.new(HALF, 0, -HALF), Vector3.new(HALF, 0, HALF) },
		{ Vector3.new(-HALF, 0, -HALF), Vector3.new(-FENCE_END, 0, -HALF) },
		{ Vector3.new(HALF, 0, -HALF), Vector3.new(FENCE_END, 0, -HALF) },
	}
	local pillarAt: { Vector3 } = {}
	for _, run in runs do
		local a, b = run[1], run[2]
		local len = (b - a).Magnitude
		local dir = (b - a).Unit
		local turn = CFrame.lookAt(Vector3.zero, dir) -- local -Z along the run
		local n = math.max(1, math.round(len / 24))
		part(
			m,
			"FenceFooting",
			Vector3.new(2.6, 1.4, len + 2.6),
			frame * CFrame.new((a + b) / 2 + Vector3.new(0, 0.5, 0)) * turn,
			tw.base,
			tw.baseMat
		)
		for k = 0, n do
			local p = a:Lerp(b, k / n)
			local seen = false
			for _, q in pillarAt do
				seen = seen or (p - q).Magnitude < 1
			end
			if not seen then
				table.insert(pillarAt, p)
			end
			if k < n and era >= 2 then
				-- one wall between two pillars, in the era's style
				local mid = a:Lerp(b, (k + 0.5) / n)
				local w = len / n - 2.4
				local seg = frame * CFrame.new(mid) * turn
				if era == 2 then
					-- painted timber: three wide boards and a top rail
					for _, y in { 2.6, 5.6, 8.6 } do
						part(m, "FenceBoard", Vector3.new(0.6, 2.2, w), seg * CFrame.new(0, y, 0), tw.walls, tw.wallMat)
					end
					part(m, "FenceRail", Vector3.new(0.9, 0.6, w), seg * CFrame.new(0, 10.3, 0), tw.frame, tw.frameMat)
				elseif era == 3 then
					-- a stone wall with battlements
					part(m, "FenceWall", Vector3.new(2, 9.6, w), seg * CFrame.new(0, 5.6, 0), tw.walls, tw.wallMat)
					part(m, "FenceCoping", Vector3.new(2.6, 0.6, w), seg * CFrame.new(0, 10.7, 0), tw.trim, tw.trimMat)
					if k % 2 == 0 then
						-- ivy climbing the inner face, a flower bed at its foot (less of a fortress)
						local inward = frame:VectorToObjectSpace(seg.RightVector)
						local sgn = if (mid + inward).Magnitude < mid.Magnitude then 1 else -1
						-- (two vines from the ground, each a wandering chain of leaf clumps that thins as it
						-- climbs; ChatGPT's 2nd village review: separate green slabs read as holes)
						local ivyGreens = { Color3.fromRGB(62, 122, 52), Color3.fromRGB(84, 146, 62) }
						for v = -1, 1, 2 do
							local vz = v * w / 5
							for j = 0, 5 do
								local sway = math.sin(j * 1.7 + v) * 0.7
								local wide = 2 - j * 0.22
								local ivy = part(
									m,
									"Ivy",
									Vector3.new(0.35, 1.7, wide),
									seg * CFrame.new(sgn * 1.1, 0.9 + j * 1.5, vz + sway),
									ivyGreens[(j + v) % 2 + 1],
									Enum.Material.SmoothPlastic
								)
								ivy.CastShadow = false
								if j % 2 == 1 then
									local side = part(
										m,
										"Ivy",
										Vector3.new(0.3, 1, 1.1),
										seg * CFrame.new(sgn * 1.12, 0.9 + j * 1.5 + 0.4, vz + sway + v * wide * 0.7),
										ivyGreens[j % 2 + 1],
										Enum.Material.SmoothPlastic
									)
									side.CastShadow = false
								end
							end
						end
						part(
							m,
							"WallBed",
							Vector3.new(1.6, 0.7, w * 0.6),
							seg * CFrame.new(sgn * 2, 0.35, 0),
							tw.base,
							tw.baseMat
						)
					end
					local merlons = math.max(1, math.floor(w / 4))
					for j = 1, merlons do
						local zj = -w / 2 + (j - 0.5) * w / merlons
						part(m, "Merlon", Vector3.new(2, 1.6, 1.8), seg * CFrame.new(0, 11.8, zj), tw.walls, tw.wallMat)
					end
				elseif era == 4 then
					-- steel and glass: a low wall, a glass panel, a steel top rail
					part(m, "FenceBase", Vector3.new(1.6, 2.6, w), seg * CFrame.new(0, 2.5, 0), tw.walls, tw.wallMat)
					local glass = part(
						m,
						"FenceGlass",
						Vector3.new(0.3, 6.6, w),
						seg * CFrame.new(0, 7.1, 0),
						tw.glass,
						Enum.Material.Glass
					)
					glass.Transparency = 0.45
					glass.CastShadow = false
					part(m, "FenceRail", Vector3.new(0.8, 0.6, w), seg * CFrame.new(0, 10.6, 0), tw.frame, tw.frameMat)
					glow("FenceLight", Vector3.new(0.2, 0.2, w), seg * CFrame.new(0, 3.9, 0), tw.trim)
				else
					-- a marble wall with a balustrade on top
					part(m, "FenceWall", Vector3.new(1.8, 7, w), seg * CFrame.new(0, 4.3, 0), tw.walls, tw.wallMat)
					-- (the glow stays on the pillar caps; the long runs in the wall's own trim)
					local soft, softMat = tw.trim, tw.trimMat
					if softMat == Enum.Material.Neon then
						soft, softMat = tw.frame, tw.frameMat
					end
					part(m, "FenceCornice", Vector3.new(2.4, 0.6, w), seg * CFrame.new(0, 8.1, 0), soft, softMat)
					local posts = math.max(2, math.floor(w / 1.6))
					for j = 1, posts do
						local zj = -w / 2 + (j - 0.5) * w / posts
						part(
							m,
							"Baluster",
							Vector3.new(0.5, 1.8, 0.5),
							seg * CFrame.new(0, 9.3, zj),
							tw.walls,
							tw.wallMat
						)
					end
					part(m, "Handrail", Vector3.new(0.9, 0.5, w), seg * CFrame.new(0, 10.45, 0), soft, softMat)
				end
			end
		end
	end
	-- the pillars: wood posts, then stone, then slim steel with a light, then marble columns
	for k, p in pillarAt do
		local c = frame * CFrame.new(p)
		if era <= 2 then
			part(m, "FencePillar", Vector3.new(2.6, 12.6, 2.6), c * CFrame.new(0, 6, 0), tp.frame, tp.frameMat)
			part(m, "PillarCap", Vector3.new(3.4, 0.7, 3.4), c * CFrame.new(0, 12.6, 0), tp.trim, tp.trimMat)
			if era == 2 then
				glow("PillarLantern", Vector3.new(1.3, 1.5, 1.3), c * CFrame.new(0, 13.7, 0), tp.glass)
				part(m, "LanternCap", Vector3.new(1.9, 0.4, 1.9), c * CFrame.new(0, 14.65, 0), tp.frame, tp.frameMat)
			end
		elseif era == 3 then
			part(m, "FenceTower", Vector3.new(4, 14, 4), c * CFrame.new(0, 6.8, 0), tp.walls, tp.wallMat)
			for _, o in
				{
					Vector3.new(1.4, 0, 1.4),
					Vector3.new(-1.4, 0, 1.4),
					Vector3.new(1.4, 0, -1.4),
					Vector3.new(-1.4, 0, -1.4),
				}
			do
				part(
					m,
					"TowerMerlon",
					Vector3.new(1.2, 1.6, 1.2),
					c * CFrame.new(o + Vector3.new(0, 14.6, 0)),
					tp.walls,
					tp.wallMat
				)
			end
			if k % 2 == 0 then
				glow("TowerTorch", Vector3.new(0.8, 1, 0.8), c * CFrame.new(0, 14.4, 0), tp.glass)
			end
		elseif era == 4 then
			part(m, "FencePillar", Vector3.new(1.6, 12.4, 1.6), c * CFrame.new(0, 5.9, 0), tp.frame, tp.frameMat)
			glow("PillarLight", Vector3.new(1.7, 2.4, 1.7), c * CFrame.new(0, 10.6, 0), tp.trim)
			part(m, "PillarCap", Vector3.new(2.2, 0.5, 2.2), c * CFrame.new(0, 12.3, 0), tp.frame, tp.frameMat)
		else
			local column = part(
				m,
				"FenceColumn",
				Vector3.new(11.6, 2.6, 2.6),
				c * CFrame.new(0, 5.8, 0) * CFrame.Angles(0, 0, math.rad(90)),
				tp.walls,
				tp.wallMat
			) :: Part
			column.Shape = Enum.PartType.Cylinder
			part(m, "ColumnCap", Vector3.new(3.4, 0.9, 3.4), c * CFrame.new(0, 12, 0), tp.trim, tp.trimMat)
			local ball =
				part(m, "ColumnBall", Vector3.one * 1.6, c * CFrame.new(0, 13.2, 0), tp.trim, tp.trimMat) :: Part
			ball.Shape = Enum.PartType.Ball
		end
	end

	-- ===== 5 the gate: the kit gate in era 1, then the era's own; a paved landing always =====
	part(m, "GateLanding", Vector3.new(GATE_X * 2 + 4, 0.4, 7), at(0, 0.2, -HALF - 4.5), tg.base, tg.baseMat)
	if era == 2 then
		-- a timber gatehouse: square towers with gable roofs, a beam and the sign board
		for _, sx in { -1, 1 } do
			local tower = at(sx * GATE_X, 0, -HALF)
			part(m, "GateTower", Vector3.new(4.4, 15, 4.4), tower * CFrame.new(0, 7.5, 0), tg.walls, tg.wallMat)
			part(m, "TowerBand", Vector3.new(4.8, 0.6, 4.8), tower * CFrame.new(0, 15.2, 0), tg.frame, tg.frameMat)
			for _, sz in { -1, 1 } do
				wedge(
					m,
					"TowerRoof",
					Vector3.new(5.4, 3, 2.7),
					tower * CFrame.new(0, 17, sz * 1.35) * CFrame.Angles(0, if sz < 0 then 0 else math.pi, 0),
					tg.roof,
					tg.roofMat
				)
			end
			glow("GateLantern", Vector3.new(1, 1.3, 1), tower * CFrame.new(-sx * 2.6, 9.5, -2.4), tg.glass, 12)
		end
		part(m, "GateBeam", Vector3.new(GATE_X * 2, 1.4, 1.4), at(0, 13.6, -HALF), tg.frame, tg.frameMat)
		part(m, "SignBoard", Vector3.new(10, 3.6, 0.6), at(0, 11, -HALF - 0.3), tg.walls, tg.wallMat)
	elseif era == 3 then
		-- a stone gatehouse: big towers with battlements, a battlemented bridge over the way
		for _, sx in { -1, 1 } do
			local tower = at(sx * (GATE_X + 0.5), 0, -HALF)
			part(m, "GateTower", Vector3.new(6, 18, 6), tower * CFrame.new(0, 9, 0), tg.walls, tg.wallMat)
			for _, o in
				{
					Vector3.new(2.2, 0, 2.2),
					Vector3.new(-2.2, 0, 2.2),
					Vector3.new(2.2, 0, -2.2),
					Vector3.new(-2.2, 0, -2.2),
				}
			do
				part(
					m,
					"TowerMerlon",
					Vector3.new(1.6, 2, 1.6),
					tower * CFrame.new(o + Vector3.new(0, 19, 0)),
					tg.walls,
					tg.wallMat
				)
			end
			glow("GateTorch", Vector3.new(0.9, 1.3, 0.9), tower * CFrame.new(-sx * 3.4, 10, -3.2), tg.glass, 12)
		end
		part(m, "GateBridge", Vector3.new(GATE_X * 2, 3.4, 4), at(0, 15.3, -HALF), tg.walls, tg.wallMat)
		for j = -2, 2 do
			part(m, "BridgeMerlon", Vector3.new(1.8, 1.6, 4), at(j * 3.6, 17.8, -HALF), tg.walls, tg.wallMat)
		end
		part(m, "SignBoard", Vector3.new(10, 3.6, 0.6), at(0, 11, -HALF - 0.3), tg.trim, tg.trimMat)
	elseif era == 4 then
		-- a steel and glass portal: slim frames, glass towers, a lit canopy over the way
		for _, sx in { -1, 1 } do
			local tower = at(sx * GATE_X, 0, -HALF)
			local glass = part(
				m,
				"GateGlass",
				Vector3.new(3.2, 16, 3.2),
				tower * CFrame.new(0, 8, 0),
				tg.glass,
				Enum.Material.Glass
			)
			glass.Transparency = 0.35
			for _, o in
				{
					Vector3.new(1.6, 0, 1.6),
					Vector3.new(-1.6, 0, 1.6),
					Vector3.new(1.6, 0, -1.6),
					Vector3.new(-1.6, 0, -1.6),
				}
			do
				part(
					m,
					"GateFrame",
					Vector3.new(0.5, 16, 0.5),
					tower * CFrame.new(o + Vector3.new(0, 8, 0)),
					tg.frame,
					tg.frameMat
				)
			end
			glow("GateLight", Vector3.new(0.4, 14, 0.4), tower * CFrame.new(-sx * 1.65, 8, -1.65), tg.trim, 12)
		end
		local canopy = part(
			m,
			"GateCanopy",
			Vector3.new(GATE_X * 2 + 6, 0.6, 7),
			at(0, 16.3, -HALF - 1),
			tg.glass,
			Enum.Material.Glass
		)
		canopy.Transparency = 0.3
		part(m, "CanopyBeam", Vector3.new(GATE_X * 2 + 6, 1, 1), at(0, 16.3, -HALF - 4.5), tg.frame, tg.frameMat)
		glow("CanopyLight", Vector3.new(GATE_X * 2 + 5, 0.2, 0.3), at(0, 15.75, -HALF - 4.5), tg.trim)
		part(m, "SignBoard", Vector3.new(10, 3.6, 0.6), at(0, 11, -HALF - 0.3), tg.frame, tg.frameMat)
	elseif era == 5 then
		-- a marble arch: columns, a beam and a pediment, a golden crest
		for _, sx in { -1, 1 } do
			for _, dz in { -1.6, 1.6 } do
				local col = part(
					m,
					"GateColumn",
					Vector3.new(15, 2.6, 2.6),
					at(sx * GATE_X, 7.9, -HALF + dz) * CFrame.Angles(0, 0, math.rad(90)),
					tg.walls,
					tg.wallMat
				) :: Part
				col.Shape = Enum.PartType.Cylinder
			end
			part(m, "ColumnBase", Vector3.new(4, 0.8, 6.4), at(sx * GATE_X, 0.4, -HALF), tg.base, tg.baseMat)
			part(m, "Capital", Vector3.new(4, 1, 6.4), at(sx * GATE_X, 15.9, -HALF), tg.trim, tg.trimMat)
		end
		part(m, "Entablature", Vector3.new(GATE_X * 2 + 5, 2.4, 6.4), at(0, 17.6, -HALF), tg.walls, tg.wallMat)
		for _, sx in { -1, 1 } do
			wedge(
				m,
				"Pediment",
				Vector3.new(6, 3.4, (GATE_X * 2 + 5) / 2),
				at(sx * (GATE_X * 2 + 5) / 4, 20.5, -HALF) * CFrame.Angles(0, math.rad(-sx * 90), 0),
				tg.walls,
				tg.wallMat
			)
		end
		local crest = part(
			m,
			"GateCrest",
			Vector3.new(0.4, 3.2, 3.2),
			at(0, 20.4, -HALF - 3.3) * CFrame.Angles(0, math.rad(90), 0),
			tg.trim,
			tg.trimMat
		) :: Part
		crest.Shape = Enum.PartType.Cylinder
		glow("CrestGem", Vector3.new(1.2, 1.2, 0.4), at(0, 20.4, -HALF - 3.6), tg.glass, 12)
		part(m, "SignBoard", Vector3.new(10, 3.6, 0.6), at(0, 11, -HALF - 0.3), tg.trim, tg.trimMat)
	end

	-- ===== the lamps: 12 at the era's start (four on the lawn at the plaza's edge, one beside each
	-- path), 8 more at its level 3 (the paths' far halves, the other side); all on the lawn, off the
	-- paving; the first 12 give light. The steel era's lamp is built here: a straight post and a long
	-- lit head (ChatGPT's 1st village review: the kit one read as a little windmill) =====
	local lampSpots: { { Vector3 } } = {}
	for g = 1, 8, 2 do
		local d = dirOf(GAPS[g])
		table.insert(lampSpots, { d * (plazaR + 2), -d })
	end
	for i = 1, #PATHS do
		local p, look = besidePath(i, 0.5, if i % 2 == 0 then 1 else -1, 5.6)
		table.insert(lampSpots, { p, look })
	end
	if s >= 3 then
		for i = 1, #PATHS do
			local p, look = besidePath(i, 0.85, if i % 2 == 0 then -1 else 1, 5.6)
			table.insert(lampSpots, { p, look })
		end
	end
	local steel, steelDark = Color3.fromRGB(176, 182, 192), Color3.fromRGB(70, 74, 84)
	for k, spot in lampSpots do
		local lamp: Instance? = nil
		if era == 2 then
			-- the painted era's lamp is built too: the kit LanternPost is a 4-stud wall lantern, a
			-- toy beside a 5-stud player. A white post, a blue arm and a lantern hung from it
			local p = findSpot(spot[1], spot[2], 1.2)
			if p then
				table.insert(taken, { at = p, r = 1.2 })
				local base = frame * CFrame.new(p) * CFrame.lookAt(Vector3.zero, spot[2])
				local white, blue = Color3.fromRGB(244, 244, 238), Color3.fromRGB(52, 98, 178)
				local lm = Instance.new("Model")
				lm.Name = "PaintedLamp"
				part(
					lm,
					"LampFoot",
					Vector3.new(1.3, 0.7, 1.3),
					base * CFrame.new(0, 0.35, 0),
					blue,
					Enum.Material.Wood
				)
				part(
					lm,
					"LampPost",
					Vector3.new(0.55, 8, 0.55),
					base * CFrame.new(0, 4.6, 0),
					white,
					Enum.Material.Wood
				)
				part(
					lm,
					"LampCollar",
					Vector3.new(0.8, 0.3, 0.8),
					base * CFrame.new(0, 7.2, 0),
					blue,
					Enum.Material.Wood
				)
				part(
					lm,
					"LampArm",
					Vector3.new(0.3, 0.3, 1.9),
					base * CFrame.new(0, 8.4, -0.8),
					blue,
					Enum.Material.Wood
				)
				part(
					lm,
					"LampHook",
					Vector3.new(0.15, 0.5, 0.15),
					base * CFrame.new(0, 8.05, -1.6),
					blue,
					Enum.Material.Metal
				)
				part(
					lm,
					"LanternCap",
					Vector3.new(1.1, 0.3, 1.1),
					base * CFrame.new(0, 7.65, -1.6),
					blue,
					Enum.Material.Wood
				)
				local glass = part(
					lm,
					"LanternGlass",
					Vector3.new(0.8, 1, 0.8),
					base * CFrame.new(0, 7, -1.6),
					Color3.fromRGB(255, 226, 160),
					Enum.Material.Neon
				)
				glass.CastShadow = false
				part(
					lm,
					"LanternBase",
					Vector3.new(1, 0.25, 1),
					base * CFrame.new(0, 6.4, -1.6),
					blue,
					Enum.Material.Wood
				)
				lm.Parent = m
				lamp = lm
			end
		elseif era == 4 then
			local p = findSpot(spot[1], spot[2], 1.2)
			if p then
				table.insert(taken, { at = p, r = 1.2 })
				local base = frame * CFrame.new(p) * CFrame.lookAt(Vector3.zero, spot[2])
				local lm = Instance.new("Model")
				lm.Name = "SteelLamp"
				part(
					lm,
					"LampFoot",
					Vector3.new(1.4, 0.5, 1.4),
					base * CFrame.new(0, 0.25, 0),
					steelDark,
					Enum.Material.Metal
				)
				part(lm, "LampPost", Vector3.new(0.5, 9, 0.5), base * CFrame.new(0, 4.7, 0), steel, Enum.Material.Metal)
				part(
					lm,
					"LampArm",
					Vector3.new(0.35, 0.35, 1.6),
					base * CFrame.new(0, 9.1, -0.6),
					steel,
					Enum.Material.Metal
				)
				part(
					lm,
					"LampHood",
					Vector3.new(1.5, 0.7, 2.8),
					base * CFrame.new(0, 9, -1.7),
					steelDark,
					Enum.Material.Metal
				)
				-- (a thick housing, its lit panel facing down: ChatGPT's 2nd village review read the
				-- flat head as a sign or a camera)
				local head = part(
					lm,
					"LampHead",
					Vector3.new(1.2, 0.2, 2.4),
					base * CFrame.new(0, 8.6, -1.7),
					Color3.fromRGB(255, 236, 190),
					Enum.Material.Neon
				)
				head.CastShadow = false
				lm.Parent = m
				lamp = lm
			end
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

	-- a little paved pad under something set on the lawn (a bench, a sign): it reads as placed there
	local tPath = TIERS[tiers[2]]
	local function pad(model: Model?, grow: number)
		if model then
			local cf, size = model:GetBoundingBox()
			local q = frame:PointToObjectSpace(cf.Position)
			local look = frame:VectorToObjectSpace(cf.LookVector)
			local turn = CFrame.lookAt(Vector3.zero, Vector3.new(look.X, 0, look.Z))
			local p = part(
				m,
				"Pad",
				Vector3.new(size.X + grow, 0.12, size.Z + grow),
				frame * CFrame.new(q.X, 0.06, q.Z) * turn,
				tPath.base,
				tPath.baseMat
			)
			p.CastShadow = false
		end
	end
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

	-- ===== level 2: benches beside every path on a little pad; the two front greens =====
	if s >= 2 then
		for i = 1, #PATHS do
			if i ~= 5 then -- (the gate path is lined by the flower beds)
				local p, look = besidePath(i, 0.32, if i % 2 == 0 then -1 else 1, 6.2)
				pad(put(BENCHES[era], p, look, BENCH_HEIGHT[era], 4.4), 1.2)
			end
		end
		-- benches round the plaza's edge facing the centrepiece, in pairs either side of the gate path
		for _, a in { 168, 192 } do
			local d = dirOf(a)
			pad(put(BENCHES[era], d * (plazaR + 3), -d, BENCH_HEIGHT[era], 4.4), 1.2)
		end

		-- the picnic green, front-left of the gate path (ChatGPT's 1st village review): a shade tree,
		-- a picnic table with log seats, a flower bed with a garden piece; a shade roof from the brick
		-- era; half the green left open
		local g = dirOf(GAPS[4])
		local gc = g * 41
		local across = Vector3.new(g.Z, 0, -g.X)
		place(m, frame, "BroadleafTree", gc.X - across.X * 7, gc.Z - across.Z * 7, 13, 11)
		table.insert(taken, { at = gc - across * 7, r = 5 })
		local tc = gc + across * 1.5
		local tt = TIERS[tiers[2]]
		local face = CFrame.lookAt(Vector3.zero, g)
		local tbl = frame * CFrame.new(tc) * face
		-- (sized for 5-stud players; ChatGPT's 2nd village review: the first one read as a toy)
		part(m, "PicnicTop", Vector3.new(6.2, 0.3, 2.6), tbl * CFrame.new(0, 2.7, 0), tt.walls, tt.wallMat)
		for _, bz in { -1.8, 1.8 } do
			part(m, "PicnicSeat", Vector3.new(6.2, 0.3, 1), tbl * CFrame.new(0, 1.5, bz), tt.walls, tt.wallMat)
		end
		for _, ex in { -2.4, 2.4 } do
			part(m, "PicnicEnd", Vector3.new(0.3, 2.55, 4.6), tbl * CFrame.new(ex, 1.28, 0), tt.frame, tt.frameMat)
		end
		for _, ex in { -4.1, 4.1 } do
			part(m, "PicnicStool", Vector3.new(1.1, 1.5, 1.1), tbl * CFrame.new(ex, 0.75, 0), tt.frame, tt.frameMat)
		end
		local basket = bit(
			"Basket",
			Vector3.new(1, 0.6, 0.7),
			tbl * CFrame.new(1, 3.15, 0),
			Color3.fromRGB(196, 140, 84),
			Enum.Material.Wood
		)
		basket.Name = "PicnicBasket"
		bit("Cloth", Vector3.new(3, 0.04, 1.9), tbl * CFrame.new(-0.8, 2.87, 0), Color3.fromRGB(230, 90, 90))
		bit("Jug", Vector3.new(0.5, 0.8, 0.5), tbl * CFrame.new(-2, 3.25, 0.5), Color3.fromRGB(120, 168, 214))
		table.insert(taken, { at = tc, r = 5 })
		if era >= 2 then
			-- a shelter over the table from the painted era, open on all four sides, 6.9 studs clear,
			-- its underside light; on plinths from the brick era, a lantern under it
			local roofT = TIERS[tiers[4]]
			local trim, trimMat = tt.trim, tt.trimMat
			if trimMat == Enum.Material.Neon then
				trim, trimMat = tt.frame, tt.frameMat
			end
			for _, ex in { -3.6, 3.6 } do
				for _, ez in { -2.9, 2.9 } do
					if era >= 3 then
						part(
							m,
							"ShadePlinth",
							Vector3.new(1.1, 1.2, 1.1),
							tbl * CFrame.new(ex, 0.6, ez),
							tt.base,
							tt.baseMat
						)
					end
					part(m, "ShadePost", Vector3.new(0.5, 7, 0.5), tbl * CFrame.new(ex, 3.5, ez), tt.frame, tt.frameMat)
				end
			end
			part(m, "ShadeCeiling", Vector3.new(8, 0.2, 6.6), tbl * CFrame.new(0, 7.05, 0), tt.walls, tt.wallMat)
			part(m, "ShadeTrim", Vector3.new(8.8, 0.3, 7.4), tbl * CFrame.new(0, 7.25, 0), trim, trimMat)
			part(m, "ShadeRoof", Vector3.new(8.6, 0.45, 7.2), tbl * CFrame.new(0, 7.55, 0), roofT.roof, roofT.roofMat)
			bit("LanternCord", Vector3.new(0.1, 0.5, 0.1), tbl * CFrame.new(0, 6.7, 0), tt.frame)
			bit(
				"Lantern",
				Vector3.new(0.6, 0.6, 0.6),
				tbl * CFrame.new(0, 6.2, 0),
				Color3.fromRGB(255, 226, 160),
				Enum.Material.Neon
			)
		end
		-- the flower bed in front of the green, with the era's garden piece in it
		local bc = gc + g * 7 + across * 4
		local bed = frame * CFrame.new(bc) * face
		part(m, "BedEdge", Vector3.new(6, 0.7, 3.2), bed * CFrame.new(0, 0.35, 0), tPath.edge, tPath.baseMat)
		part(
			m,
			"BedSoil",
			Vector3.new(5.4, 0.2, 2.6),
			bed * CFrame.new(0, 0.75, 0),
			Color3.fromRGB(110, 80, 56),
			Enum.Material.Ground
		)
		for k = 0, 7 do
			local fl = bit(
				"Flower",
				Vector3.one * 0.7,
				bed * CFrame.new(-2.2 + (k % 4) * 1.45, 1.15, -0.6 + math.floor(k / 4) * 1.2),
				bunt[k % 4 + 1]
			) :: Part
			fl.Shape = Enum.PartType.Ball
		end
		table.insert(taken, { at = bc, r = 3.4 })
		put(GARDENS[era], gc - g * 6 + across * 2, g, GARDEN_HEIGHT[era], 3.4)

		-- the community green, front-right: an open patch in a half ring of benches, a notice board,
		-- a banner pole and bunting from the painted era
		local h = dirOf(GAPS[5])
		local hc = h * 40
		for _, a in { -55, 0, 55 } do
			local d = (CFrame.Angles(0, math.rad(a), 0) * CFrame.lookAt(Vector3.zero, -h)).LookVector
			pad(put(BENCHES[era], hc - d * 6, d, BENCH_HEIGHT[era], 4.4), 1.2)
		end
		-- (a worn clearing in the middle of the half ring, where the gathering happens: an uneven
		-- edge of smaller worn blobs and a few stones; ChatGPT's 2nd village review: one flat cream
		-- disc looked unfinished)
		local worn = Color3.fromRGB(170, 150, 108)
		local function disc(name: string, centre: Vector3, d: number, y: number, colour: Color3, mat: Enum.Material?)
			local p = part(
				m,
				name,
				Vector3.new(0.1, d, d),
				frame * CFrame.new(centre + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				colour,
				mat or Enum.Material.SmoothPlastic
			) :: Part
			p.Shape = Enum.PartType.Cylinder
			p.CastShadow = false
			p.CanCollide = false
		end
		disc("GreenPatch", hc, 7, 0.05, worn)
		for k = 0, 6 do
			local a = math.rad(k * 51 + 20)
			disc("GreenPatch", hc + Vector3.new(math.cos(a), 0, math.sin(a)) * 3.1, 1.8 + (k % 3) * 0.5, 0.04, worn)
		end
		for k = 0, 4 do
			local a = math.rad(k * 73 + 40)
			bit(
				"Pebble",
				Vector3.new(0.7, 0.35, 0.5),
				frame * CFrame.new(hc + Vector3.new(math.cos(a), 0, math.sin(a)) * 4.6 + Vector3.new(0, 0.18, 0)),
				Color3.fromRGB(150, 150, 146),
				Enum.Material.Slate
			)
		end
		-- each era its own edge round the clearing: brick sections, an inset paved ring, four small
		-- glowing markers
		if era == 3 then
			for k = 0, 5 do
				local a = k * 60 + 15
				local cf = frame * CFrame.new(hc) * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 0.2, -4.4)
				part(m, "ClearingBrick", Vector3.new(2.2, 0.4, 0.6), cf, tPath.edge, tPath.baseMat)
			end
		elseif era == 4 then
			disc("ClearingRing", hc, 9.4, 0.03, tPath.base, tPath.baseMat)
			disc("GreenPatch", hc, 8, 0.06, worn)
		elseif era == 5 then
			for k = 0, 3 do
				local cf = frame * CFrame.new(hc) * CFrame.Angles(0, math.rad(k * 90 + 45), 0) * CFrame.new(0, 0, -5)
				part(m, "MarkerPost", Vector3.new(0.5, 1.2, 0.5), cf * CFrame.new(0, 0.6, 0), tPath.edge, tPath.baseMat)
				bit(
					"MarkerGlow",
					Vector3.new(0.6, 0.25, 0.6),
					cf * CFrame.new(0, 1.3, 0),
					tPath.trim,
					Enum.Material.Neon
				)
			end
		end
		-- the clearing's open side faces the plaza: an announcement post there, a low stage from the
		-- brick era, an arch over it in the last
		local hAcross = Vector3.new(h.Z, 0, -h.X)
		local stage = frame * CFrame.new(hc - h * 5.6) * CFrame.lookAt(Vector3.zero, h)
		if era >= 3 then
			part(m, "Stage", Vector3.new(5, 0.6, 2.6), stage * CFrame.new(0, 0.3, 0), tPath.base, tPath.baseMat)
			part(m, "StageEdge", Vector3.new(5.2, 0.2, 2.8), stage * CFrame.new(0, 0.7, 0), tPath.edge, tPath.baseMat)
		end
		local lift = if era >= 3 then 0.8 else 0
		for _, ex in { -0.9, 0.9 } do
			part(
				m,
				"NoticePost",
				Vector3.new(0.3, 3.4, 0.3),
				stage * CFrame.new(ex, lift + 1.7, 0.9),
				tPath.frame,
				tPath.frameMat
			)
		end
		part(
			m,
			"NoticeBoard",
			Vector3.new(2.4, 1.6, 0.2),
			stage * CFrame.new(0, lift + 2.8, 0.95),
			TIERS[tiers[2]].walls,
			TIERS[tiers[2]].wallMat
		)
		for k = 0, 2 do
			bit(
				"Notice",
				Vector3.new(0.6, 0.7, 0.05),
				stage * CFrame.new(-0.7 + k * 0.7, lift + 2.8, 0.83),
				bunt[k + 1]
			)
		end
		if era == 5 then
			for _, ex in { -2.8, 2.8 } do
				part(
					m,
					"ArchPost",
					Vector3.new(0.6, 6.4, 0.6),
					stage * CFrame.new(ex, 3.2, 0),
					tPath.edge,
					tPath.baseMat
				)
			end
			part(m, "ArchBeam", Vector3.new(6.4, 0.6, 0.8), stage * CFrame.new(0, 6.6, 0), tPath.edge, tPath.baseMat)
			part(m, "ArchCrown", Vector3.new(2.4, 0.9, 0.6), stage * CFrame.new(0, 7.3, 0), tPath.trim, tPath.trimMat)
		end
		table.insert(taken, { at = hc - h * 5.6, r = 3 })
		local poleA, poleB = hc - h * 7 + hAcross * 7, hc - h * 7 - hAcross * 7
		if era >= 2 then
			pole(poleA.X, poleA.Z, 6)
			pole(poleB.X, poleB.Z, 6)
			bunting(poleA, poleB, 5.8)
		end
		-- stepping stones from each front green toward the plaza: the greens join the village
		-- instead of floating in the lawn (ChatGPT's 2nd village review)
		for _, dir in { g, h } do
			for k = 0, 3 do
				local side = Vector3.new(dir.Z, 0, -dir.X) * (if k % 2 == 0 then 0.7 else -0.7)
				local spot = dir * (33 - k * 2.4) + side
				if findSpot(spot, dir, 0.9, side) == spot then
					bit(
						"SteppingStone",
						Vector3.new(1.6 - (k % 2) * 0.3, 0.2, 1.3),
						frame * CFrame.new(spot + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, k * 0.6, 0),
						Color3.fromRGB(158, 156, 148),
						Enum.Material.Slate
					)
				end
			end
		end
	end

	-- ===== level 4: the market, one place for every stall (ChatGPT's 1st village review): in the
	-- green between the pantry and the garden paths, a shallow U facing the plaza, one stall more
	-- each era (the older ones stay), crates, barrels and a cart beside them, a market sign and
	-- bunting over it; the notice boards at the gate and by the market =====
	if s >= 4 then
		local md = dirOf(GAPS[8])
		local mAcross = Vector3.new(md.Z, 0, -md.X)
		local spots =
			{ md * 30, md * 30 + mAcross * 6, md * 30 - mAcross * 6, md * 37 + mAcross * 4, md * 37 - mAcross * 4 }
		-- one paved square under the whole market, wider at the back, so it reads as one place
		-- (ChatGPT's 2nd village review); the stalls face the plaza over a clear strip
		local mFace = CFrame.lookAt(Vector3.zero, -md)
		for _, slab in { { 28.5, 5, 15 }, { 36.5, 11, 19 } } do
			local cf = frame * CFrame.new(md * slab[1]) * mFace
			part(
				m,
				"MarketSquare",
				Vector3.new(slab[3], 0.16, slab[2]),
				cf * CFrame.new(0, 0.08, 0),
				tPath.yard,
				tPath.baseMat
			)
		end
		for e = 1, era do
			pad(put(STALLS[e], spots[e], -md, STALL_HEIGHT[e], 5), 1.6)
		end
		put("CrateStack", md * 38 + mAcross * 8.5, -md, 2.6, 2.4)
		put("WoodBarrel", md * 41.5 + mAcross * 1.5, -md, 2.4, 1.8)
		put("HandCart", md * 41.5 - mAcross * 3, -md, 3, 3)
		-- the market's entrance sign over the way in, on two posts, about 8 studs high
		local sc = md * 22.5
		local sign = frame * CFrame.new(sc) * mFace
		for _, ex in { -2.7, 2.7 } do
			part(
				m,
				"SignPost",
				Vector3.new(0.45, 7.6, 0.45),
				sign * CFrame.new(ex, 3.8, 0),
				tPath.frame,
				tPath.frameMat
			)
		end
		part(
			m,
			"SignBoard",
			Vector3.new(6.2, 1.5, 0.3),
			sign * CFrame.new(0, 6.9, 0),
			TIERS[tiers[2]].walls,
			TIERS[tiers[2]].wallMat
		)
		for k = -1, 1 do -- (three fruit shapes on it: a market without words)
			local fr = bit("SignFruit", Vector3.one * 0.9, sign * CFrame.new(k * 1.6, 6.9, -0.3), bunt[k + 2]) :: Part
			fr.Shape = Enum.PartType.Ball
		end
		for _, ex in { -2.7, 2.7 } do
			table.insert(taken, { at = sc + mAcross * ex, r = 0.8 })
		end
		local ba, bb = md * 33 + mAcross * 10, md * 33 - mAcross * 10
		pole(ba.X, ba.Z, 7)
		pole(bb.X, bb.Z, 7)
		bunting(ba, bb, 6.8)
		put(NOTICES[era], Vector3.new(6.5, 0, -HALF + 10), Vector3.new(-1, 0, 0), NOTICE_HEIGHT[era], 3.6)
		pad(put(NOTICES[era], md * 23 + mAcross * 5.8, -md, NOTICE_HEIGHT[era], 3.6), 1)
	end

	-- ===== level 5: the gardens in the back gaps and two flower beds lining the gate path =====
	if s >= 5 then
		local gardenGaps: { number } = if era >= 3 then { 1, 7, 2, 3 } else { 1, 7 }
		for j, gg in ipairs(gardenGaps) do
			local d = dirOf(GAPS[gg])
			-- the newest garden piece and the one before it, by turns
			local e = if j % 2 == 0 and era > 1 then era - 1 else era
			put(GARDENS[e], d * 25, -d, GARDEN_HEIGHT[e], 4.5)
		end
		-- (long raised beds with edging in the paths' material and flowers in clusters, broken where
		-- the benches and lamps stand; ChatGPT's 1st village review: the pots read as loose dots)
		for _, seg in { { 0.28, 0.46 }, { 0.56, 0.78 } } do
			for _, side in { -1, 1 } do
				local a = besidePath(5, seg[1], side, 5.8)
				local b = besidePath(5, seg[2], side, 5.8)
				local len = (b - a).Magnitude
				local mid = (a + b) / 2
				local bed = frame * CFrame.new(mid) * CFrame.lookAt(Vector3.zero, (b - a).Unit)
				part(m, "BedEdge", Vector3.new(2.8, 0.7, len), bed * CFrame.new(0, 0.35, 0), tPath.edge, tPath.baseMat)
				part(
					m,
					"BedSoil",
					Vector3.new(2.3, 0.2, len - 0.5),
					bed * CFrame.new(0, 0.75, 0),
					Color3.fromRGB(110, 80, 56),
					Enum.Material.Ground
				)
				-- (every flower in its own leafy clump, heights and colours in uneven runs;
				-- ChatGPT's 2nd village review: bare balls on soil read as candy trays)
				local greens = { Color3.fromRGB(78, 140, 60), Color3.fromRGB(100, 164, 72) }
				local n = math.floor(len / 1.3)
				for k = 0, n - 1 do
					local z = -len / 2 + 0.65 + k * 1.3
					local x = math.sin(k * 2.3 + side) * 0.45
					local tall = (k * 7 + side) % 3
					local d = 1 + tall * 0.25
					local leaf =
						bit("Leaf", Vector3.one * d, bed * CFrame.new(x, 0.85 + d * 0.25, z), greens[k % 2 + 1]) :: Part
					leaf.Shape = Enum.PartType.Ball
					local fl = bit(
						"Flower",
						Vector3.one * (0.5 + tall * 0.1),
						bed * CFrame.new(x, 0.95 + d * 0.75, z),
						bunt[(math.floor(k / 2) + (if side > 0 then 1 else 3)) % 4 + 1]
					) :: Part
					fl.Shape = Enum.PartType.Ball
				end
				table.insert(taken, { at = mid, r = 1.5 })
			end
		end
	end
	return m
end

return VillageStages
