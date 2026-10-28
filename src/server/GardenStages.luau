--!strict
-- The vegetable garden's 50 levels (the owner, 2026-10-28: "the same as the pantry"). Five eras of
-- ten levels; in each era:
--   level 1 of the era   the garden grows a building: era 2 a tool shed, era 3 a vine pergola over
--                        the entrance, era 4 a greenhouse over the beds, era 5 an irrigation windmill
--   levels 2-5           four garden props, one a level, each slot taking its next, better version:
--                        1 water (watering can > rain barrel > hand pump > sprinkler > watering drone)
--                        2 tools (tool rack > soil cart > seed spreader > tiller > garden robot)
--                        3 compost (compost bin > tumbler > fertiliser sacks > fertiliser tank > goo
--                        composter)   4 scarecrow (straw > hatted > pinwheel post > bird repeller >
--                        robot scarecrow)
--   levels 6-10          the garden's builds move up one material tier, one a level: bed frames,
--                        fence, path, the shed, the pergola and greenhouse frames
-- Tiers and helpers are the pantry's (PantryStages): the classic stud look, a tier in its colours;
-- every prop at its real height (the player is 5 studs). The beds, crops and work spot stay; the
-- soil floor stays soil. Positions are in the garden's own frame (x across, z from the gate in).
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)

local GardenStages = {}

GardenStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the fence (inside the area's frame): x from -13 to 13, z from -9 (front, gate x -4..4) to 15
local FX, FZ0, FZ1, GATE = 13, -9, 15, 4

-- props: slot -> era -> kit model, real height (studs), where, the room it has, a hover lift
local PROPS = {
	{ "WateringCan", "RainBarrel", "HandPump", "Sprinkler", "WaterDrone" },
	{ "ToolRack", "SoilCart", "SeedSpreader", "Tiller", "GardenBot" },
	{ "CompostBin", "CompostTumbler", "FertiliserSacks", "FertiliserTank", "GooComposter" },
	{ "StrawScarecrow", "HatScarecrow", "PinwheelPost", "BirdRepeller", "RobotScarecrow" },
}
-- 0.4 m can, 1 m barrel, 1.2 m pump, 0.9 m sprinkler, drone; 1.6 m rack, 0.8 m cart, 1 m spreader,
-- 1 m tiller, 1.2 m robot; 1 m bin, 1.3 m tumbler, 0.9 m sacks, 1.6 m tank, 1.6 m composter;
-- scarecrows 1.8-2 m
local HEIGHT = {
	{ 1.2, 2.9, 3.4, 2.6, 1.4 },
	{ 4.6, 2.3, 2.9, 2.9, 3.4 },
	{ 2.9, 2.4, 2.6, 4.6, 4.6 }, -- (the tumbler mesh is a wide drum: 2.4 keeps it in proportion)
	{ 5.4, 5.7, 5.1, 5.7, 5.4 },
}
-- The props stand on the lawn OUTSIDE the fence, where they have room for their real size (the
-- owner, 2026-10-28: squeezed into the paths they looked like toys): water and scarecrow by the
-- front corners, tools and compost along the sides; each turned toward the garden (degrees: 90
-- faces -x, -90 faces +x, 0 the front).
local SLOT_AT = { { 17, -4.5, 90 }, { 17.5, 6.5, 90 }, { -17.5, 6.5, -90 }, { -16.5, -4.5, 0 } }
local FOOT = { 4.5, 6, 6, 4.5 }

-- A ring of farm life on the lawn round all four sides, growing with the eras and never taken away
-- (the owner, 2026-10-28: use the space round the old pad): kit model, x, z, real height, foot,
-- turn (as SLOT_AT), from which era. +x is the garden's left as one walks in.
local SURROUND: { { any } } = {
	{ "WildflowersGrass", 7.5, -11.5, 1.6, 4, 0, 1 },
	{ "FlowerShrub", -10.5, -11, 2.4, 3, 0, 1 },
	{ "HayBale", 17, 13, 2.4, 3.6, 90, 1 },
	{ "FernCluster", -11, 21.5, 2.2, 3, 0, 1 },
	{ "Wheelbarrow", -15.5, 1, 2.2, 3.6, -60, 2 },
	{ "CrateStack", 16.5, 1, 3, 3.2, 90, 2 },
	{ "FlowerPot", 4.6, -10.4, 1.6, 1.4, 0, 2 },
	{ "FlowerPot", -4.6, -10.4, 1.6, 1.4, 0, 2 },
	{ "LogBench", 9, -13.5, 1.8, 4.6, 0, 3 },
	{ "WoodBarrel", -15.5, -8, 2.8, 2.2, 0, 3 },
	{ "WildflowersGrass", -20.5, 2.5, 1.6, 4, 0, 3 },
	{ "HayBale", 19.5, 10.5, 2.4, 3.6, 70, 4 },
	{ "RainBarrel", 15, -8.5, 2.9, 2.4, 90, 4 },
	{ "Planter", 13, -11.5, 1.6, 3, 0, 4 },
	{ "Planter", -13.5, -11.5, 1.6, 3, 0, 4 },
	-- (ChatGPT's 2nd review: the back was empty next to the front) planting behind from the start
	{ "PineBerryBush", 11, 21.5, 2.4, 3, 0, 1 },
	{ "FlowerShrub", 16.5, 18.5, 2.2, 3, 0, 2 },
	{ "WildflowersGrass", 3, 21.5, 1.4, 3.5, 0, 2 },
	{ "FlowerShrub", 6, 21.5, 2.4, 3, 0, 5 },
	{ "FlowerShrub", -6, 21.5, 2.4, 3, 0, 5 },
	{ "LogBench", -9.5, -13.5, 1.8, 4.6, 0, 5 },
}
local LIFT = { [5] = 2.4 } -- the watering drone hovers

-- What a level holds: shed, pergola, greenhouse, windmill; each prop slot's era (0: none); each
-- build's tier (bed frames, fence, path, shed, pergola and greenhouse).
function GardenStages.state(level: number): ({ boolean }, { number }, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local builds = { level >= 11, level >= 21, level >= 31, level >= 41 }
	local props, tiers = {}, {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	for k = 1, 5 do
		tiers[k] = if s >= k + 5 then era + 1 else era
	end
	return builds, props, tiers
end

function GardenStages.tierName(level: number): string
	local _, _, tiers = GardenStages.state(level)
	return TIERS[tiers[1]].name
end

-- A picket fence run with its tier's colours: pickets, two rails, posts every few pickets. By tier
-- (ChatGPT's review, 2026-10-28): natural timber on the first; painted white pickets with coloured
-- posts on painted timber; brick piers on a low brick base on brick; on marble ivory pickets,
-- marble posts and a thin gold top rail.
local function fenceRun(m: Model, frame: CFrame, x0: number, z0: number, x1: number, z1: number, t: any, tier: number)
	local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local along = CFrame.lookAt(Vector3.zero, dir)
	local n = math.max(1, math.round(len / 0.9))
	local picketCol, picketMat = t.trim, t.trimMat
	local postCol, postMat, postW, postH = t.frame, t.frameMat, 0.6, 2.8
	if tier == 1 then
		picketCol, picketMat = Color3.fromRGB(196, 140, 84), Enum.Material.Wood
	elseif tier == 3 then
		postCol, postMat, postW, postH = Color3.fromRGB(176, 88, 66), Enum.Material.Brick, 0.9, 2.9
	elseif tier >= 6 then
		picketCol, picketMat = Color3.fromRGB(246, 243, 236), Enum.Material.SmoothPlastic
		postCol, postMat, postW, postH = Color3.fromRGB(232, 226, 214), Enum.Material.Marble, 0.8, 3.1
	end
	if tier == 3 then
		local mid = (a + b) / 2
		part(
			m,
			"FenceBase",
			Vector3.new(0.6, 0.4, len),
			frame * CFrame.new(mid.X, 0.2, mid.Z) * along,
			postCol,
			postMat
		)
	end
	for k = 0, n do
		local p = a + dir * (len * k / n)
		local post = k % 6 == 0 or k == n
		local short = tier == 1 and k % 2 == 1 -- (a little uneven, hand made)
		part(
			m,
			if post then "FencePost" else "Picket",
			Vector3.new(
				if post then postW else 0.4,
				if post then postH else (if short then 2.05 else 2.3),
				if post then postW else 0.22
			),
			frame * CFrame.new(p.X, if post then postH / 2 else (if short then 1.03 else 1.15), p.Z) * along,
			if post then postCol else picketCol,
			if post then postMat else picketMat
		)
		if post and tier >= 6 then
			part(
				m,
				"PostCap",
				Vector3.new(postW + 0.2, 0.18, postW + 0.2),
				frame * CFrame.new(p.X, postH + 0.09, p.Z) * along,
				t.trim,
				t.trimMat
			)
		end
	end
	if tier >= 6 then
		local mid = (a + b) / 2
		part(
			m,
			"GoldRail",
			Vector3.new(0.18, 0.15, len),
			frame * CFrame.new(mid.X, 2.35, mid.Z) * along,
			t.trim,
			t.trimMat
		)
	end
	local mid = (a + b) / 2
	for _, y in { 0.7, 1.7 } do
		part(
			m,
			"FenceRail",
			Vector3.new(0.2, 0.3, len),
			frame * CFrame.new(mid.X, y, mid.Z) * along,
			t.frame,
			t.frameMat
		)
	end
end

-- The garden's layer for a level. `area` is the garden model: its bed frames take the tier, its
-- old fence, barrel, watering can and stepping stones go (the layer stands in for them).
function GardenStages.build(area: Instance, frame: CFrame, level: number): Model
	local builds, props, tiers = GardenStages.state(level)
	local tb, tf, tp, ts, tg = TIERS[tiers[1]], TIERS[tiers[2]], TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)

	-- the old pieces the layer replaces, and the bed frames
	for _, d in area:GetChildren() do
		if d.Name == "Fence" or d.Name == "WateringCan" or d.Name == "WoodBarrel" or d.Name == "SteppingStone" then
			d.Parent = nil
		end
	end
	for _, d in area:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "BedPlank" then
			d.Color = tb.walls
			PondStages.studLook(d, tb.wallMat)
		end
	end

	-- From the shed's era the garden grows 4 studs at the back, so the shed stands clear of the beds
	-- with a proper walk between (the owner, 2026-10-28): a strip of floor and the fence moved back.
	local back = if builds[1] then FZ1 + 4 else FZ1
	if builds[1] then
		local floor = area:FindFirstChild("Floor")
		local ext = part(
			m,
			"FloorExt",
			Vector3.new(FX * 2, 0.2, back - FZ1),
			frame * CFrame.new(0, 0.1, (FZ1 + back) / 2),
			if floor and floor:IsA("BasePart") then floor.Color else Color3.fromRGB(196, 134, 82)
		)
		if floor and floor:IsA("BasePart") then
			ext.Material, ext.TopSurface = floor.Material, floor.TopSurface
		end
	end

	-- 2 the fence
	fenceRun(m, frame, -FX, back, FX, back, tf, tiers[2])
	fenceRun(m, frame, -FX, FZ0, -FX, back, tf, tiers[2])
	fenceRun(m, frame, FX, FZ0, FX, back, tf, tiers[2])
	fenceRun(m, frame, -FX, FZ0, -GATE, FZ0, tf, tiers[2])
	fenceRun(m, frame, GATE, FZ0, FX, FZ0, tf, tiers[2])

	-- 3 the path from the gate to the work spot (ChatGPT's review: a continuous route that changes
	-- with the tier, not three stones): a 3.2-wide band, slabs on it, an edge on painted tiers up
	local pt = tiers[3]
	local bandCol = ({
		Color3.fromRGB(150, 108, 70), -- worn earth
		Color3.fromRGB(226, 208, 170), -- cream gravel
		Color3.fromRGB(176, 104, 80), -- brick
		Color3.fromRGB(150, 154, 160), -- concrete
		Color3.fromRGB(40, 90, 96), -- slime tech
		Color3.fromRGB(236, 230, 218), -- marble
	})[pt]
	local zFrom, zTo = FZ0 - 0.2, -0.4
	part(
		m,
		"PathBand",
		Vector3.new(3.2, 0.1, zTo - zFrom), -- (flush: a raised band read as a bulky step)
		frame * CFrame.new(0, 0.25, (zFrom + zTo) / 2),
		bandCol,
		Enum.Material.Plastic
	)
	if pt >= 2 then
		for _, s in { -1, 1 } do
			part(
				m,
				"PathEdge",
				Vector3.new(0.18, 0.15, zTo - zFrom),
				frame * CFrame.new(s * 1.7, 0.27, (zFrom + zTo) / 2),
				tp.edge,
				tp.yardMat
			)
		end
	end
	local slabs: { number } = if pt >= 4 then { -7.6, -5.5, -3.4, -1.3 } else { -7.6, -4.8, -2 }
	for k, z in ipairs(slabs) do
		local w = if pt >= 4 then 2.6 else 1.7 + (k % 2) * 0.3
		part(
			m,
			"PathStone",
			Vector3.new(w, 0.3, if pt >= 4 then 1.8 else 1.4),
			frame * CFrame.new(if pt >= 4 then 0 else (k % 2 - 0.5) * 0.5, 0.38, z),
			tp.base,
			tp.baseMat
		)
	end
	if pt >= 6 then
		for _, z in { FZ0 + 0.6, -4.45 } do
			part(
				m,
				"GoldStrip",
				Vector3.new(3.2, 0.1, 0.15),
				frame * CFrame.new(0, 0.42, z),
				Color3.fromRGB(232, 190, 80),
				Enum.Material.Foil
			)
		end
	end

	-- era 2: a potting and tool shed in the back-left corner, its door to the front (detail pass,
	-- 2026-10-28: a gable roof with overhang and fascia, a braced door in a frame, a window with a
	-- flower box, tools hung on the wall, battens on timber)
	if builds[1] then
		-- (bigger, ChatGPT's reviews; in the back strip, a 4-stud walk from the beds)
		local sx, sz, w, d, h = -9.8, 16.6, 6, 4.2, 4.8
		local at = function(x: number, y: number, z: number): CFrame
			return frame * CFrame.new(sx + x, y, sz + z)
		end
		local dark = Color3.fromRGB(42, 34, 30)
		local wood = Color3.fromRGB(150, 98, 60)
		part(m, "ShedBase", Vector3.new(w + 0.4, 0.4, d + 0.4), at(0, 0.2, 0), ts.base, ts.baseMat)
		part(m, "ShedWalls", Vector3.new(w, h, d), at(0, 0.4 + h / 2, 0), ts.walls, ts.wallMat)
		for _, s in { -1, 1 } do
			for _, z in { -d / 2, d / 2 } do
				part(
					m,
					"ShedCorner",
					Vector3.new(0.45, h, 0.45),
					at(s * (w / 2), 0.4 + h / 2, z),
					ts.frame,
					ts.frameMat
				)
			end
		end
		if tiers[4] <= 2 then
			for k = 1, 5 do
				part(
					m,
					"ShedBatten",
					Vector3.new(0.14, h - 0.2, 0.1),
					at(-w / 2 + k * w / 6, 0.4 + h / 2, -d / 2 - 0.05),
					ts.frame,
					ts.frameMat
				)
			end
		end
		-- the door: dark opening, frame, braced leaf, handle
		part(m, "ShedDoorway", Vector3.new(1.8, 3.1, 0.1), at(0.9, 1.95, -d / 2 - 0.02), dark)
		for _, s in { -1, 1 } do
			part(m, "ShedJamb", Vector3.new(0.3, 3.3, 0.3), at(0.9 + s * 1.05, 2.05, -d / 2 - 0.1), ts.trim, ts.trimMat)
		end
		part(m, "ShedHeader", Vector3.new(2.4, 0.3, 0.32), at(0.9, 3.65, -d / 2 - 0.1), ts.trim, ts.trimMat)
		part(m, "ShedDoor", Vector3.new(1.6, 3, 0.14), at(0.9, 1.9, -d / 2 - 0.08), wood, Enum.Material.WoodPlanks)
		part(
			m,
			"ShedBrace",
			Vector3.new(0.2, 3.1, 0.08),
			at(0.9, 1.9, -d / 2 - 0.17) * CFrame.Angles(0, 0, 0.45),
			ts.trim,
			ts.trimMat
		)
		part(
			m,
			"ShedHandle",
			Vector3.new(0.12, 0.45, 0.14),
			at(0.3, 1.9, -d / 2 - 0.2),
			Color3.fromRGB(60, 60, 66),
			Enum.Material.Metal
		)
		-- the window with a flower box under it
		part(m, "ShedWindowFrame", Vector3.new(1.4, 1.2, 0.2), at(-1.3, 2.7, -d / 2 - 0.08), ts.trim, ts.trimMat)
		part(m, "ShedWindow", Vector3.new(1, 0.8, 0.22), at(-1.3, 2.7, -d / 2 - 0.09), ts.glass, Enum.Material.Glass)
		part(m, "FlowerBox", Vector3.new(1.6, 0.4, 0.5), at(-1.3, 1.85, -d / 2 - 0.3), wood, Enum.Material.WoodPlanks)
		for k, c in { Color3.fromRGB(240, 132, 168), Color3.fromRGB(255, 220, 90), Color3.fromRGB(240, 132, 168) } do
			local bloom = part(
				m,
				"Bloom",
				Vector3.one * 0.38,
				at(-1.3 + (k - 2) * 0.45, 2.2, -d / 2 - 0.3),
				c,
				Enum.Material.SmoothPlastic
			) :: Part
			bloom.Shape = Enum.PartType.Ball
		end
		-- a tool rack on the front wall beside the door: a beam, a big rake and a big spade (ChatGPT:
		-- a few large tools read, small ones do not)
		local metal = Color3.fromRGB(150, 156, 166)
		-- (on the side wall that faces the beds)
		part(m, "RackBeam", Vector3.new(0.2, 0.18, 1.8), at(w / 2 + 0.15, 3.9, -0.3), wood, Enum.Material.Wood)
		for k, z in { -0.8, 0.2 } do
			part(m, "ToolHandle", Vector3.new(0.16, 2.8, 0.16), at(w / 2 + 0.3, 2.5, z), wood, Enum.Material.Wood)
			part(
				m,
				if k == 1 then "RakeHead" else "SpadeBlade",
				if k == 1 then Vector3.new(0.15, 0.2, 0.9) else Vector3.new(0.12, 0.8, 0.6),
				at(w / 2 + 0.32, if k == 1 then 3.9 else 1.05, z),
				metal,
				Enum.Material.Metal
			)
		end
		-- a potting bench by the fence in front of the shed, two pots and a seedling tray on it
		local bench = frame * CFrame.new(-12.1, 0, 8.6)
		part(m, "BenchTop", Vector3.new(0.9, 0.15, 2.2), bench * CFrame.new(0, 1.1, 0), wood, Enum.Material.WoodPlanks)
		for _, dz in { -0.95, 0.95 } do
			part(m, "BenchLeg", Vector3.new(0.7, 1.05, 0.15), bench * CFrame.new(0, 0.52, dz), wood, Enum.Material.Wood)
		end
		for k, dz in { -0.6, 0.15 } do
			local pot = part(
				m,
				"Pot",
				Vector3.new(0.45, 0.5, 0.5),
				bench * CFrame.new(0, 1.42, dz) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(196, 104, 70)
			) :: Part
			pot.Shape = Enum.PartType.Cylinder
			local sprout = part(
				m,
				"Sprout",
				Vector3.new(0.4, 0.35, 0.4),
				bench * CFrame.new(0, 1.8, dz),
				if k == 1 then Color3.fromRGB(104, 184, 74) else Color3.fromRGB(240, 132, 168)
			) :: Part
			sprout.Shape = Enum.PartType.Ball
		end
		part(m, "SeedTray", Vector3.new(0.6, 0.15, 0.6), bench * CFrame.new(0, 1.25, 0.8), Color3.fromRGB(60, 60, 66))
		-- a gable roof (ridge front to back) with overhang, fascia and a ridge cap
		local rise, ov = 1.6, 0.5
		for _, s in { -1, 1 } do
			wedge(
				m,
				"ShedRoof",
				Vector3.new(d + ov * 2, rise, w / 2 + ov),
				at(s * (w / 4 + ov / 2), 0.4 + h + rise / 2, 0)
					* CFrame.Angles(0, if s < 0 then math.pi / 2 else -math.pi / 2, 0),
				ts.roof,
				ts.roofMat
			)
			-- the gable ends, in the wall's material, sunk under the roof's face
			wedge(
				m,
				"ShedGable",
				Vector3.new(0.3, rise - 0.15, w / 2),
				at(s * w / 4, 0.4 + h + (rise - 0.15) / 2, -d / 2 + 0.15)
					* CFrame.Angles(0, if s < 0 then math.pi / 2 else -math.pi / 2, 0),
				ts.walls,
				ts.wallMat
			)
		end
		part(
			m,
			"ShedRidge",
			Vector3.new(0.4, 0.35, d + ov * 2 + 0.1),
			at(0, 0.4 + h + rise + 0.1, 0),
			ts.frame,
			ts.frameMat
		)
		-- barge boards along the front gable's two slopes
		local len = math.sqrt((w / 2 + ov) ^ 2 + rise ^ 2)
		for _, s in { -1, 1 } do
			part(
				m,
				"ShedBarge",
				Vector3.new(len, 0.35, 0.2),
				at(s * (w / 4 + ov / 2), 0.4 + h + rise / 2 + 0.1, -d / 2 - ov - 0.05)
					* CFrame.Angles(0, 0, -s * math.atan2(rise, w / 2 + ov)),
				ts.frame,
				ts.frameMat
			)
		end
	end

	-- era 3: a pergola over the gate, with vines (ChatGPT's review: braced posts, a top beam, three
	-- slats; on marble pale marble posts with gold capitals)
	if builds[2] then
		local postCol, postMat = tg.frame, tg.frameMat
		if tiers[5] >= 6 then
			postCol, postMat = Color3.fromRGB(240, 236, 228), Enum.Material.Marble
		end
		local pz0, pz1, top = FZ0 - 0.6, FZ0 + 0.9, 7.2
		for _, s in { -1, 1 } do
			for _, z in { pz0, pz1 } do
				part(
					m,
					"PergolaPost",
					Vector3.new(0.45, top, 0.45),
					frame * CFrame.new(s * (GATE - 0.6), top / 2, z),
					postCol,
					postMat
				)
				if tiers[5] >= 6 then
					part(
						m,
						"PostCapital",
						Vector3.new(0.75, 0.2, 0.75),
						frame * CFrame.new(s * (GATE - 0.6), top - 0.1, z),
						tg.trim,
						tg.trimMat
					)
				end
			end
			part(
				m,
				"PergolaBeam",
				Vector3.new(0.4, 0.45, pz1 - pz0 + 1),
				frame * CFrame.new(s * (GATE - 0.6), top + 0.22, (pz0 + pz1) / 2),
				postCol,
				postMat
			)
			-- corner braces under the beams
			for _, z in { pz0, pz1 } do
				local inward = if z == pz0 then 1 else -1
				part(
					m,
					"PergolaBrace",
					Vector3.new(0.2, 1, 0.2),
					frame
						* CFrame.new(s * (GATE - 0.6), top - 0.45, z + inward * 0.35)
						* CFrame.Angles(math.rad(inward * 45), 0, 0),
					postCol,
					postMat
				)
			end
		end
		for _, z in { pz0, pz1 } do
			part(
				m,
				"PergolaHeader",
				Vector3.new(GATE * 2 + 0.4, 0.4, 0.35),
				frame * CFrame.new(0, top + 0.5, z),
				postCol,
				postMat
			)
		end
		for k = -1, 1 do
			part(
				m,
				"PergolaSlat",
				Vector3.new(GATE * 2 + 1.2, 0.22, 0.3),
				frame * CFrame.new(0, top + 0.8, (pz0 + pz1) / 2 + k * 0.55),
				postCol,
				postMat
			)
		end
		-- climbing vines made of flat leaves in three greens (ChatGPT's review: the round clumps read
		-- as pom-poms): a canopy over the slats, strands hanging from them, stems winding up the
		-- posts with leaves on them, blooms; a planter of flowers at each side of the gate
		local greens = { Color3.fromRGB(112, 196, 78), Color3.fromRGB(86, 168, 62), Color3.fromRGB(58, 130, 50) }
		local pink, yellow = Color3.fromRGB(240, 132, 168), Color3.fromRGB(255, 214, 90)
		local seed = 7
		local function rnd(): number
			seed = (seed * 1103515245 + 12345) % 2147483648
			return seed / 2147483648
		end
		local function leaf(cf: CFrame)
			local p = part(
				m,
				"Leaf",
				Vector3.new(0.5 + rnd() * 0.2, 0.08, 0.32 + rnd() * 0.12),
				-- (nearly flat: steep leaves read as flying chips)
				cf * CFrame.Angles(rnd() * 0.5 - 0.25, rnd() * 6.28, rnd() * 0.5 - 0.25),
				greens[1 + math.floor(rnd() * 3)],
				Enum.Material.SmoothPlastic
			)
			p.CastShadow = false
		end
		for _ = 1, 30 do
			leaf(
				frame
					* CFrame.new(
						(rnd() - 0.5) * (GATE * 2 + 0.6),
						top + 0.95 + rnd() * 0.25,
						pz0 - 0.2 + rnd() * (pz1 - pz0 + 0.4)
					)
			)
		end
		for _, x in { -3, -2.1, -1.2, 0, 1.1, 2.2, 3.1 } do
			local len = 1 + rnd() * 0.8
			part(
				m,
				"VineStem",
				Vector3.new(0.1, len, 0.1),
				frame * CFrame.new(x, top + 0.7 - len / 2, (pz0 + pz1) / 2),
				greens[3],
				Enum.Material.SmoothPlastic
			)
			for j = 0, 2 do
				leaf(
					frame
						* CFrame.new(
							x + (rnd() - 0.5) * 0.3,
							top + 0.6 - j * len / 3,
							(pz0 + pz1) / 2 + (rnd() - 0.5) * 0.3
						)
				)
			end
		end
		for _, s in { -1, 1 } do
			for _, z in { pz0, pz1 } do
				local px = s * (GATE - 0.6)
				-- a stem winding up the post in short slanted steps, a leaf at each bend
				for j = 0, 5 do
					local y = 0.6 + j * 1.1
					local side = if j % 2 == 0 then 0.28 else -0.28
					part(
						m,
						"VineStem",
						Vector3.new(0.1, 1.25, 0.1),
						frame * CFrame.new(px + side * 0.5, y + 0.55, z - 0.28) * CFrame.Angles(0, 0, side * 0.5),
						greens[3],
						Enum.Material.SmoothPlastic
					)
					leaf(frame * CFrame.new(px + side, y + 0.9, z - 0.3))
				end
			end
			-- (inside the fence, beside the gate)
			part(
				m,
				"Planter",
				Vector3.new(2.2, 0.7, 0.9),
				frame * CFrame.new(s * (GATE + 1.4), 0.35, FZ0 + 1.1),
				Color3.fromRGB(150, 98, 60),
				Enum.Material.WoodPlanks
			)
			for j = -1, 1 do
				local b = part(
					m,
					"Bloom",
					Vector3.one * 0.45,
					frame * CFrame.new(s * (GATE + 1.4) + j * 0.6, 0.95, FZ0 + 1.1),
					if j == 0 then yellow else pink,
					Enum.Material.SmoothPlastic
				) :: Part
				b.Shape = Enum.PartType.Ball
			end
		end
		for k = 1, 7 do
			local b = part(
				m,
				"Bloom",
				Vector3.one * (0.32 + rnd() * 0.12),
				frame * CFrame.new((rnd() - 0.5) * GATE * 2, top + 1.05, pz0 + rnd() * (pz1 - pz0)),
				if k % 3 == 0 then yellow else pink,
				Enum.Material.SmoothPlastic
			) :: Part
			b.Shape = Enum.PartType.Ball
		end
	end

	-- era 4: a greenhouse over both beds, its door to the work spot's path. Rebuilt after ChatGPT's
	-- review (2026-10-28): the ridge runs front to back so the front shows a tall glass gable; eaves at
	-- 6.4 and ridge at 9.6; few, slim bars (three bays a side); clear matte glass (no reflections);
	-- a 4.8-wide door with two glass leaves swung open; a knee wall with a light cap; a ridge vent and
	-- finials; on marble a white frame, stone corner pilasters and gold only on the finials and vent.
	if builds[3] then
		local x0, x1, z0, z1, eave, ridge = -9.8, 9.8, -2.8, 10.8, 6.4, 9.6
		local zc = (z0 + z1) / 2
		local glass = Color3.fromRGB(196, 232, 246)
		local marble = tiers[5] >= 6
		local gFrame, gFrameMat = tg.frame, tg.frameMat
		if marble then
			gFrame, gFrameMat = Color3.fromRGB(246, 243, 236), Enum.Material.SmoothPlastic
		end
		-- the door leaves' edges stand out from the frame (ChatGPT's 2nd review): dark on white
		local doorEdge = if marble then Color3.fromRGB(96, 104, 116) else Color3.fromRGB(150, 158, 170)
		local doorEdgeMat = Enum.Material.Metal
		local function bar(name: string, size: Vector3, cf: CFrame)
			part(m, name, size, cf, gFrame, gFrameMat)
		end
		local function pane(name: string, size: Vector3, cf: CFrame)
			local p = part(m, name, size, cf, glass, Enum.Material.SmoothPlastic)
			p.Transparency = 0.62
			p.Reflectance = 0
			p.CastShadow = false
			p.CanCollide = false
		end
		local function glassWedge(size: Vector3, cf: CFrame)
			local g = Instance.new("WedgePart")
			g.Name = "GHGable"
			g.Size = size
			g.CFrame = cf
			g.Color = glass
			g.Material = Enum.Material.SmoothPlastic
			g.Transparency = 0.62
			g.CastShadow = false
			g.CanCollide = false
			g.Anchored = true
			g.Parent = m
		end
		-- the knee wall with a light cap, open at the door
		local doorHalf = 2.4
		for _, run in
			{
				{ x0, z1, x1, z1 },
				{ x0, z0, x0, z1 },
				{ x1, z0, x1, z1 },
				{ x0, z0, -doorHalf, z0 },
				{ doorHalf, z0, x1, z0 },
			}
		do
			local a, b = Vector3.new(run[1], 0, run[2]), Vector3.new(run[3], 0, run[4])
			local len = (b - a).Magnitude
			local alongX = run[2] == run[4]
			local mid = (a + b) / 2
			part(
				m,
				"KneeWall",
				if alongX then Vector3.new(len + 0.5, 0.9, 0.5) else Vector3.new(0.5, 0.9, len + 0.5),
				frame * CFrame.new(mid + Vector3.new(0, 0.45, 0)),
				tb.base,
				tb.baseMat
			)
			part(
				m,
				"KneeCap",
				if alongX then Vector3.new(len + 0.8, 0.15, 0.75) else Vector3.new(0.75, 0.15, len + 0.8),
				frame * CFrame.new(mid + Vector3.new(0, 0.97, 0)),
				Color3.fromRGB(226, 222, 214),
				Enum.Material.Concrete
			)
		end
		-- corner and bay posts on the long sides, the eave beams along them
		for _, x in { x0, x1 } do
			for _, z in { z0, zc, z1 } do
				if marble and z ~= zc then
					part(
						m,
						"GHPilaster",
						Vector3.new(0.55, eave, 0.55),
						frame * CFrame.new(x, eave / 2, z),
						Color3.fromRGB(232, 226, 214),
						Enum.Material.Marble
					)
				else
					bar("GHPost", Vector3.new(0.3, eave, 0.3), frame * CFrame.new(x, eave / 2, z))
				end
			end
			bar("GHEave", Vector3.new(0.35, 0.3, z1 - z0 + 0.3), frame * CFrame.new(x, eave, zc))
			pane("GHWall", Vector3.new(0.12, eave - 1, z1 - z0), frame * CFrame.new(x, 0.95 + (eave - 1) / 2, zc))
		end
		-- the back wall and the front either side of the door
		for _, x in { x0 / 2, x1 / 2 } do
			bar("GHPost", Vector3.new(0.3, eave, 0.3), frame * CFrame.new(x, eave / 2, z1))
		end
		pane("GHWall", Vector3.new(x1 - x0, eave - 1, 0.12), frame * CFrame.new(0, 0.95 + (eave - 1) / 2, z1))
		for _, s in { -1, 1 } do
			local w = x1 - doorHalf
			pane(
				"GHWall",
				Vector3.new(w, eave - 1, 0.12),
				frame * CFrame.new(s * (doorHalf + w / 2), 0.95 + (eave - 1) / 2, z0)
			)
			bar("GHPost", Vector3.new(0.3, eave, 0.3), frame * CFrame.new(s * (doorHalf + w / 2), eave / 2, z0))
		end
		for _, z in { z0, z1 } do
			bar("GHTie", Vector3.new(x1 - x0, 0.3, 0.3), frame * CFrame.new(0, eave, z))
		end
		-- the gables, front and back: glass triangles, a frame on their slopes, a king post
		local halfW, rise = (x1 - x0) / 2, ridge - eave
		local slopeLen = math.sqrt(halfW ^ 2 + rise ^ 2)
		local pitch = math.atan2(rise, halfW)
		for _, z in { z0, z1 } do
			for _, sx in { -1, 1 } do
				glassWedge(
					Vector3.new(0.12, rise, halfW),
					frame
						* CFrame.new(sx * halfW / 2, eave + rise / 2, z)
						* CFrame.Angles(0, if sx < 0 then math.pi / 2 else -math.pi / 2, 0)
				)
				bar(
					"GHGableBar",
					Vector3.new(slopeLen, 0.3, 0.32),
					frame * CFrame.new(sx * halfW / 2, eave + rise / 2 + 0.1, z) * CFrame.Angles(0, 0, -sx * pitch)
				)
			end
			bar("GHKingPost", Vector3.new(0.25, rise, 0.25), frame * CFrame.new(0, eave + rise / 2, z))
		end
		-- the roof: two glass slopes, three rafters each and a ridge beam
		for _, sx in { -1, 1 } do
			local cf = frame * CFrame.new(sx * halfW / 2, eave + rise / 2, zc) * CFrame.Angles(0, 0, -sx * pitch)
			pane("GHRoof", Vector3.new(slopeLen, 0.12, z1 - z0), cf)
			bar(
				"GHRafter",
				Vector3.new(slopeLen, 0.22, 0.22),
				frame * CFrame.new(sx * halfW / 2, eave + rise / 2 + 0.1, zc) * CFrame.Angles(0, 0, -sx * pitch)
			)
		end
		bar("GHRidge", Vector3.new(0.35, 0.35, z1 - z0 + 0.4), frame * CFrame.new(0, ridge + 0.05, zc))
		-- a ridge vent: a raised glass box with a cap (gold edge on marble), finials at the peaks
		pane("GHVent", Vector3.new(1.2, 0.6, (z1 - z0) * 0.45), frame * CFrame.new(0, ridge + 0.5, zc))
		part(
			m,
			"GHVentCap",
			Vector3.new(1.6, 0.2, (z1 - z0) * 0.45 + 0.3),
			frame * CFrame.new(0, ridge + 0.9, zc),
			if marble then tg.trim else gFrame,
			if marble then tg.trimMat else gFrameMat
		)
		for _, z in { z0, z1 } do
			local fin = part(
				m,
				"GHFinial",
				Vector3.one * 0.55,
				frame * CFrame.new(0, ridge + 0.45, z),
				if marble then tg.trim else gFrame,
				if marble then tg.trimMat else gFrameMat
			) :: Part
			fin.Shape = Enum.PartType.Ball
		end
		-- the door: posts, a header at 5.8, two glass leaves swung out
		for _, s in { -1, 1 } do
			bar("GHDoorPost", Vector3.new(0.35, eave, 0.35), frame * CFrame.new(s * doorHalf, eave / 2, z0))
			local leafCf = frame
				* CFrame.new(s * doorHalf, 2.75, z0)
				* CFrame.Angles(0, s * math.rad(-58), 0)
				* CFrame.new(-s * 1.1, 0, 0)
			local leafPane = part(m, "GHDoor", Vector3.new(2.1, 5.2, 0.1), leafCf, glass, Enum.Material.SmoothPlastic)
			leafPane.Transparency = 0.55
			leafPane.CanCollide = false
			for _, dy in { 2.55, -2.55, 0 } do
				part(
					m,
					"GHDoorRail",
					Vector3.new(2.2, 0.25, 0.18),
					leafCf * CFrame.new(0, dy, 0),
					doorEdge,
					doorEdgeMat
				)
			end
			for _, ex in { -1, 1 } do
				part(
					m,
					"GHDoorStile",
					Vector3.new(0.25, 5.2, 0.18),
					leafCf * CFrame.new(ex * 1, 0, 0),
					doorEdge,
					doorEdgeMat
				)
			end
			part(
				m,
				"GHDoorHandle",
				Vector3.new(0.12, 0.6, 0.25),
				leafCf * CFrame.new(-s * 0.75, 0, -0.15),
				Color3.fromRGB(60, 60, 66),
				Enum.Material.Metal
			)
		end
		bar("GHDoorHeader", Vector3.new(doorHalf * 2 + 0.4, 0.35, 0.35), frame * CFrame.new(0, 5.8, z0))
	end

	-- era 5: an irrigation windmill at the back, between the beds' ends and the fence
	if builds[4] then
		-- the landmark of the last era (ChatGPT's review: it read as a roof ornament; the owner: use
		-- the lawn outside): tall, on the lawn behind the tool shed, its rotor clear of the greenhouse;
		-- a pipe from it behind the fence and in at the back to two sprinkler heads over the beds
		-- (FarmWindmill: a slim lattice tower, a 7-stud rotor, a tank at its foot; ChatGPT's 2nd review:
		-- the old one read as a barrel on scaffolding)
		place(m, frame, "FarmWindmill", -19, 15, 18, 11)
		local pipe = Color3.fromRGB(70, 130, 170)
		part(
			m,
			"IrrigationPipe",
			Vector3.new(19, 0.22, 0.22), -- (in front of the shed, behind the greenhouse)
			frame * CFrame.new(-9.5, 0.35, 12.8),
			pipe,
			Enum.Material.Metal
		)
		part(
			m,
			"IrrigationPipe",
			Vector3.new(0.22, 0.22, 1.6),
			frame * CFrame.new(0, 0.35, 12.1),
			pipe,
			Enum.Material.Metal
		)
		part(
			m,
			"IrrigationPipe",
			Vector3.new(9.4, 0.22, 0.22),
			frame * CFrame.new(0, 0.35, 11.4),
			pipe,
			Enum.Material.Metal
		)
		for _, x in { -4.6, 4.6 } do
			part(
				m,
				"PipeRiser",
				Vector3.new(0.22, 2.1, 0.22),
				frame * CFrame.new(x, 1.4, 11.4),
				pipe,
				Enum.Material.Metal
			)
			part(
				m,
				"PipeArm",
				Vector3.new(0.22, 0.22, 1.4),
				frame * CFrame.new(x, 2.45, 10.75),
				pipe,
				Enum.Material.Metal
			)
			part(
				m,
				"SprinklerHead",
				Vector3.new(0.5, 0.18, 0.18),
				frame * CFrame.new(x, 2.45, 10.05),
				Color3.fromRGB(60, 60, 66),
				Enum.Material.Metal
			)
		end
	end

	-- the farm life round the outside
	local nowEra = math.clamp(math.ceil(level / 10), 1, 5)
	for _, s in SURROUND do
		if nowEra >= s[7] then
			local prop = place(m, frame, s[1], s[2], s[3], s[4], s[5])
			if prop and s[6] ~= 0 then
				local box = prop:GetBoundingBox()
				local centre = CFrame.new(box.Position)
				prop:PivotTo(centre * CFrame.Angles(0, math.rad(s[6]), 0) * centre:ToObjectSpace(prop:GetPivot()))
			end
		end
	end

	-- the garden props
	for j = 1, 4 do
		local era = props[j]
		if era > 0 then
			local slot = SLOT_AT[j]
			local prop = place(
				m,
				frame,
				PROPS[j][era],
				slot[1],
				slot[2],
				HEIGHT[j][era],
				FOOT[j],
				if j == 1 then LIFT[era] else nil
			)
			if prop and slot[3] ~= 0 then
				-- turned on the spot, about its own middle
				local box = prop:GetBoundingBox()
				local centre = CFrame.new(box.Position)
				prop:PivotTo(centre * CFrame.Angles(0, math.rad(slot[3]), 0) * centre:ToObjectSpace(prop:GetPivot()))
			end
		end
	end
	return m
end

return GardenStages
