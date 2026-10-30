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
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)
local WorkProps = require(script.Parent.WorkProps)

local GardenStages = {}

GardenStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the fence (inside the area's frame): x from -18 to 18, z from -12 (front, gate x -4..4) to 21
-- (the village scale, 2026-10-30: the layout spread by about 1.4 from x +-13, z -9..15; the beds stand 11 studs
-- apart, every prop keeps its size; the comments below give the old layout's words, the numbers are the new)
local FX, FZ0, FZ1, GATE = 18, -12, 21, 4
local K = 1.4 -- the spread of every position written in the old layout

-- The garden props, each placed for what it DOES (the owner, 2026-10-28: ask of every piece "does it
-- belong here, is this the right spot, what goes beside it"; inside the fence where it works, outside
-- only when it is too big or the garden is full; each at its real size, the player is 5 studs). The
-- fence runs x -13..13, z -9..15 (19 from the shed's era); the beds x -9.3..9.3, z -2.3..10.3 with
-- the work path between them; the front corners inside (x 2..12, z -8..-3 each side) are open
-- ground, the sides (x 9.5..12.5) narrow strips along the beds, the back (z 10.5..) the working
-- corner; the shed stands back-right (+x is the garden's left as one walks in).
--   water      a watering can at a bed's front edge; then a rain barrel under the shed's eaves; a
--              hand pump in the front-right corner; a sprinkler on a stand between the beds' far
--              ends; a watering drone hovering over the beds
--   tools      a tool rack against the right fence by the beds; then carts and machines parked in
--              the front-left corner, turned to the path
--   compost    in the back-left corner, where the beds' waste goes (clear of the shed door)
--   scarecrow  in the right side strip beside the beds, facing the gate
local PROPS = {
	{ "WateringCan", "RainBarrel", "HandPump", "Sprinkler", "WaterDrone" },
	{ "ToolRack", "SoilCart", "SeedSpreader", "Tiller", "GardenBot" },
	{ "CompostBin", "CompostTumbler", "FertiliserSacks", "FertiliserTank", "GooComposter" },
	{ "StrawScarecrow", "HatScarecrow", "PinwheelPost", "BirdRepeller", "RobotScarecrow" },
}
-- slot -> era -> { x, z, turn (degrees: 90 faces -x, -90 faces +x, 180 faces the back), real
-- height, the widest it may be, a hover lift }
local SPOT = {
	{
		{ -4.6, -3.2, 30, 1.2, 1.6 }, -- 0.4 m watering can by the right bed's front edge
		{ -5.6, 15.6, 0, 2.9, 2.4 }, -- 1 m rain barrel at the shed's side, under its eaves
		{ -9.5, -6.2, 0, 3.4, 2.4 }, -- 1.2 m hand pump in the front-right corner
		{ 0, 11.6, 0, 2.8, 2 }, -- 1 m sprinkler on its stand between the beds' far ends
		{ 0, 4, 0, 1.4, 2.4, 6.6 }, -- watering drone over the work path, well above a player's head
	},
	{
		{ 11.6, 4, -90, 4.6, 3.6 }, -- 1.6 m tool rack against the left fence, facing the beds
		-- (the machines' bay: the front-left corner, handles toward the gate path, 3 studs clear to
		-- pull them out; ChatGPT's 5th garden review)
		{ 8.8, -5.6, -120, 2.6, 2.6 }, -- 0.9 m soil cart
		{ 8.8, -5.6, -120, 3, 3.6 }, -- 1 m seed spreader
		{ 8.8, -5.6, -120, 3.2, 4.4 }, -- 1.1 m tiller
		{ 8.8, -5.6, -120, 3.6, 3.4 }, -- 1.25 m garden robot, on its charging pad
	},
	{
		{ 10.4, 12.6, 0, 2.9, 2.6 }, -- 1 m compost bin in the back-left corner (clear of the shed door)
		{ 10.4, 12.6, 0, 3.2, 3.4 }, -- 1.1 m tumbler
		{ 10.4, 12.6, 0, 2.6, 2.8 }, -- 0.9 m stack of fertiliser sacks
		-- (the tanks stand beside the shed, clear of the greenhouse corner; the owner, 2026-10-28)
		{ -4.6, 16.4, 0, 5, 3 }, -- 1.75 m fertiliser tank
		{ -4.6, 16.4, 0, 5, 3.6 }, -- 1.75 m goo composter
	},
	{
		-- (in the right strip beside the beds, clear of the pickets, facing the vegetables)
		{ -11, 3.8, -90, 5.4, 3.6 }, -- 1.9 m scarecrow, arms along the bed
		{ -11, 3.8, -90, 5.7, 3.6 },
		{ -11, 3.8, 0, 5.4, 2.8 }, -- pinwheel post
		{ -11, 2.8, 0, 5.7, 3.2 }, -- bird repeller, a stud forward clear of the shed corner
		{ -11, 3.8, -90, 5.6, 3.6 }, -- robot scarecrow
	},
}
-- Farm life round the garden that grows with the eras and is never taken away (kit model, x, z,
-- real height, the widest it may be, turn, from which era): flowers at the gate, harvest crates
-- waiting inside by the path, a wheelbarrow of produce by the gate outside, benches along the
-- path outside, shrubs on the outside corners and behind.
local SURROUND: { { any } } = {
	{ "WildflowersGrass", 7.5, -11.5, 1.6, 4, 0, 1 },
	{ "FlowerShrub", -10.5, -11, 2.4, 3, 0, 1 },
	{ "FlowerShrub", 14.5, -10.5, 2.2, 3, 0, 1 },
	{ "PineBerryBush", 11, 21.5, 2.4, 3, 0, 1 },
	{ "FernCluster", -11, 21.5, 2.2, 3, 0, 1 },
	{ "CrateStack", -5.6, -7.4, 2, 2.2, 20, 2 }, -- harvest waiting beside the gate, low, off the path
	{ "Wheelbarrow", 6.8, -11.6, 2.2, 3, -30, 2 },
	{ "FlowerShrub", 16.5, 18.5, 2.2, 3, 0, 2 },
	{ "WildflowersGrass", 3, 21.5, 1.4, 3.5, 0, 2 },
	{ "LogBench", 9.5, -14, 1.8, 4.6, 0, 3 },
	{ "HayBale", 16.5, 13, 1.6, 2.8, 90, 3 }, -- straw for mulch, outside by the compost corner
	{ "HayBale", 16.5, 15.6, 1.6, 2.8, 90, 3 },
	{ "Planter", 13, -11.5, 1.6, 3, 0, 4 },
	{ "Planter", -13.5, -11.5, 1.6, 3, 0, 4 },
	{ "FlowerShrub", 6, 21.5, 2.4, 3, 0, 5 },
	{ "FlowerShrub", -6, 21.5, 2.4, 3, 0, 5 },
	{ "LogBench", -9.5, -14, 1.8, 4.6, 0, 5 },
}
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
	elseif tier == 5 then
		-- mint-white pickets; the glow only on one thin top rail, so the props in front still read
		-- (ChatGPT's 5th garden review)
		picketCol, picketMat = Color3.fromRGB(214, 240, 232), Enum.Material.SmoothPlastic
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
	if tier >= 5 then
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
	local back = if builds[1] then FZ1 + 5 else FZ1
	-- the two sunflowers of the scenery go back against the fence as soon as the garden grows (the
	-- owner, 2026-10-28: by the beds they pressed into the greenhouse's corner)
	local nature: Instance = area:FindFirstChild("Nature") or area
	for _, s in nature:GetChildren() do
		if s.Name == "Sunflower" and s:IsA("Model") then
			local p = frame:PointToObjectSpace(s:GetPivot().Position)
			if s:GetAttribute("HomeX") == nil then
				s:SetAttribute("HomeX", p.X)
			end
			if s:GetAttribute("HomeZ") == nil then
				s:SetAttribute("HomeZ", p.Z)
			end
			local homeX, homeZ = s:GetAttribute("HomeX") :: number, s:GetAttribute("HomeZ") :: number
			-- (and toward the back-left corner, where the greenhouse roof does not hide their heads)
			local x = if builds[1] then math.min(homeX + 2.3, FX - 1.4) else homeX
			local z = if builds[1] then back - 1.6 else homeZ
			s:PivotTo(s:GetPivot() + frame:VectorToWorldSpace(Vector3.new(x - p.X, 0, z - p.Z)))
		end
	end
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
	local zFrom, zTo = FZ0 - 0.2, -0.4 * K
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
	local slabs: { number } = if pt >= 4 then { -10.6, -7.7, -4.8, -1.9 } else { -10.6, -6.7, -2.8 }
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
		for _, z in { FZ0 + 0.6, -4.45 * K } do
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
		local sx, sz, w, d, h = -9.8 * K, back - 3.2, 6, 4.2, 4.8
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
		local bench = frame * CFrame.new(-FX + 0.9, 0, 8.6 * K)
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
		-- (over both beds of the village scale, which stand 1.4 times as far apart)
		local x0, x1, z0, z1, eave, ridge = -9.8 * K, 9.8 * K, -2.8 * K + 1, 10.8 * K - 1, 6.4, 10.4
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
		place(m, frame, "FarmWindmill", -FX - 7, 15 * K, 18, 11)
		local pipe = Color3.fromRGB(70, 130, 170)
		-- (the bed ends of the village scale: z 11.7; the pipe runs behind the greenhouse to the windmill)
		local pz = 10.8 * K + 0.6
		part(
			m,
			"IrrigationPipe",
			Vector3.new(FX + 7, 0.22, 0.22), -- (in front of the shed, behind the greenhouse)
			frame * CFrame.new(-(FX + 7) / 2, 0.35, pz + 1.4),
			pipe,
			Enum.Material.Metal
		)
		part(
			m,
			"IrrigationPipe",
			Vector3.new(0.22, 0.22, 1.6),
			frame * CFrame.new(0, 0.35, pz + 0.7),
			pipe,
			Enum.Material.Metal
		)
		part(
			m,
			"IrrigationPipe",
			Vector3.new(4.6 * K * 2 + 0.2, 0.22, 0.22),
			frame * CFrame.new(0, 0.35, pz),
			pipe,
			Enum.Material.Metal
		)
		for _, x in { -4.6 * K, 4.6 * K } do
			part(
				m,
				"PipeRiser",
				Vector3.new(0.22, 2.1, 0.22),
				frame * CFrame.new(x, 1.4, pz),
				pipe,
				Enum.Material.Metal
			)
			part(
				m,
				"PipeArm",
				Vector3.new(0.22, 0.22, 1.4),
				frame * CFrame.new(x, 2.45, pz - 0.65),
				pipe,
				Enum.Material.Metal
			)
			part(
				m,
				"SprinklerHead",
				Vector3.new(0.5, 0.18, 0.18),
				frame * CFrame.new(x, 2.45, pz - 1.35),
				Color3.fromRGB(60, 60, 66),
				Enum.Material.Metal
			)
		end
	end

	-- the farm life round the outside
	-- (the garden's floor stands 0.2 above the lawn: what is inside the fence stands on it)
	local function floorAt(x: number, z: number): number
		return if math.abs(x) <= FX and z >= FZ0 and z <= back then 0.2 else 0
	end
	local nowEra = math.clamp(math.ceil(level / 10), 1, 5)
	for _, s in SURROUND do
		if nowEra >= s[7] then
			local sx, sz = s[2] * K, s[3] * K
			local prop = place(m, frame, s[1], sx, sz, s[4], s[5], floorAt(sx, sz))
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
			local slot = SPOT[j][era]
			local name = PROPS[j][era]
			local x, z, yaw = slot[1] * K, slot[2] * K, slot[3]
			if builds[3] and j == 4 then
				-- once the greenhouse stands the side strip is a walk: the bird scarer moves to the
				-- empty front-right corner, facing the beds (the owner, 2026-10-28)
				x, z, yaw = -10.4 * K, -6.6 * K, 180
			elseif builds[3] and j == 1 and era == 3 then
				x, z = -7.4 * K, -4.4 * K -- (the hand pump makes room for it, the one level they meet)
			end
			local lift = (slot[6] or 0) + floorAt(x, z)
			-- small parts that say what a prop is for (ChatGPT's 5th garden review)
			local function bit(
				n: string,
				size: Vector3,
				dx: number,
				y: number,
				dz: number,
				col: Color3,
				mat: Enum.Material?
			)
				return part(m, n, size, frame * CFrame.new(x + dx, y, z + dz), col, mat)
			end
			local metal, teal = Color3.fromRGB(110, 116, 126), Color3.fromRGB(70, 190, 170)
			if name == "WateringCan" then
				-- the can rests on a pale stone so it reads against the soil
				bit(
					"CanSlab",
					Vector3.new(1.6, 0.1, 1.3),
					0,
					lift + 0.05,
					0,
					Color3.fromRGB(214, 206, 190),
					Enum.Material.Slate
				)
				lift += 0.1
			elseif name == "RainBarrel" then
				-- a downpipe from the shed's eave into the barrel, a tap low on its front
				bit("Downpipe", Vector3.new(0.22, 1.6, 0.22), -1, lift + 4, 0, metal, Enum.Material.Metal)
				bit("DownpipeElbow", Vector3.new(1.1, 0.22, 0.22), -0.5, lift + 3.3, 0, metal, Enum.Material.Metal)
				bit("Tap", Vector3.new(0.25, 0.25, 0.5), 0, lift + 0.7, -1.2, metal, Enum.Material.Metal)
			elseif name == "HandPump" then
				local bucket =
					bit("Bucket", Vector3.new(0.8, 0.9, 0.9), 0, lift + 0.4, -1.4, metal, Enum.Material.Metal) :: Part
				bucket.Shape = Enum.PartType.Cylinder
				bucket.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
			elseif name == "WaterDrone" then
				-- its dock by the shed, where it rests when it is not flying
				bit("DroneDock", Vector3.new(1.8, 0.15, 1.8), -7, 0.28, 12.5, teal, Enum.Material.SmoothPlastic)
			elseif name == "GardenBot" then
				-- a charging pad under it and a charging post beside it
				bit(
					"ChargePad",
					Vector3.new(3.2, 0.1, 3.2),
					0,
					lift + 0.05,
					0,
					Color3.fromRGB(60, 70, 80),
					Enum.Material.Metal
				)
				bit("ChargePost", Vector3.new(0.35, 1.8, 0.35), 2.4, lift + 0.9, 0, metal, Enum.Material.Metal)
				bit("ChargeLight", Vector3.new(0.45, 0.3, 0.45), 2.4, lift + 1.9, 0, teal, Enum.Material.Neon).CastShadow =
					false
				lift += 0.1
			end
			local prop = place(m, frame, name, x, z, slot[4], slot[5], lift)
			if prop and yaw ~= 0 then
				-- turned on the spot, about its own middle
				local box = prop:GetBoundingBox()
				local centre = CFrame.new(box.Position)
				prop:PivotTo(centre * CFrame.Angles(0, math.rad(yaw), 0) * centre:ToObjectSpace(prop:GetPivot()))
			end
		end
	end
	-- The work places (the owner, 2026-10-29): four, one on each side of the two beds, as invisible markers
	-- WorkSpot1..4 (front, right, back, left), found from where the beds really are; the vegetable bin
	-- outside the gate beside the path; and a marker CropPlot1..n at every planting spot of the beds, for
	-- the crop cycle (numbered along x, then z; the attribute Bed is 1 for the left bed, 2 for the right).
	local W = Config.WorkPlaces
	local function marker(name: string, cf: CFrame, size: Vector3): Part
		local mk = part(m, name, size, cf, Color3.new(1, 1, 1)) :: Part
		mk.Transparency = 1
		mk.CanCollide = false
		mk.CanQuery = false
		mk.CanTouch = false
		mk.CastShadow = false
		return mk
	end
	local beds = area:FindFirstChild("Beds")
	if beds and beds:IsA("Model") then
		local box, size = beds:GetBoundingBox()
		local c = frame:PointToObjectSpace(box.Position)
		local hx, hz = size.X / 2, size.Z / 2
		local gap, shift = W.GardenGap, W.GardenSideShift
		local places = {
			Vector3.new(c.X, 0, c.Z - hz - gap), -- front, on the path from the gate
			Vector3.new(math.min(c.X + hx + gap, FX - 1.5), 0, c.Z + shift),
			Vector3.new(c.X, 0, c.Z + hz + gap), -- back
			Vector3.new(math.max(c.X - hx - gap, -FX + 1.5), 0, c.Z + shift),
		}
		for k, p in places do
			marker("WorkSpot" .. k, frame * CFrame.new(p.X, 0.35, p.Z), Vector3.new(1.6, 0.2, 1.6))
		end
	end
	local plots: { { x: number, z: number, y: number } } = {}
	for _, d in area:GetChildren() do
		if d.Name == "Crop" and d:IsA("Model") then
			local p = frame:PointToObjectSpace(d:GetPivot().Position)
			table.insert(plots, { x = p.X, z = p.Z, y = p.Y })
		end
	end
	table.sort(plots, function(a, b)
		if math.abs(a.x - b.x) > 0.5 then
			return a.x < b.x
		end
		return a.z < b.z
	end)
	for i, p in plots do
		local mk = marker("CropPlot" .. i, frame * CFrame.new(p.x, p.y, p.z), Vector3.new(1.2, 0.2, 1.2))
		mk:SetAttribute("Bed", if p.x < 0 then 1 else 2)
	end
	m:SetAttribute("CropPlots", #plots)

	local V = W.VegBin
	WorkProps.bin(
		m,
		frame * CFrame.new(V[1], 0, V[2]) * CFrame.Angles(0, math.rad(V[3]), 0),
		"VegBin",
		"garden",
		WorkProps.Colours.honey,
		WorkProps.Colours.cream,
		Color3.fromRGB(226, 190, 100) -- a bed of straw
	)
	return m
end

return GardenStages
