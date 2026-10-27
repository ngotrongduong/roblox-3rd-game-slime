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
local SLOT_AT = { { 8, -5.6 }, { -11.3, 3 }, { -8, -5.6 }, { 11.3, 3 } }
local FOOT = { 6, 3.2, 6, 3.2 }
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

-- A picket fence run with its tier's colours: pickets, two rails, posts every few pickets.
local function fenceRun(m: Model, frame: CFrame, x0: number, z0: number, x1: number, z1: number, t: any)
	local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local along = CFrame.lookAt(Vector3.zero, dir)
	local n = math.max(1, math.round(len / 0.9))
	for k = 0, n do
		local p = a + dir * (len * k / n)
		local post = k % 4 == 0
		part(
			m,
			if post then "FencePost" else "Picket",
			Vector3.new(if post then 0.6 else 0.45, if post then 2.8 else 2.3, if post then 0.6 else 0.25),
			frame * CFrame.new(p.X, if post then 1.4 else 1.15, p.Z) * along,
			if post then t.frame else t.trim,
			if post then t.frameMat else t.trimMat
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

	-- 2 the fence
	fenceRun(m, frame, -FX, FZ1, FX, FZ1, tf)
	fenceRun(m, frame, -FX, FZ0, -FX, FZ1, tf)
	fenceRun(m, frame, FX, FZ0, FX, FZ1, tf)
	fenceRun(m, frame, -FX, FZ0, -GATE, FZ0, tf)
	fenceRun(m, frame, GATE, FZ0, FX, FZ0, tf)

	-- 3 the path from the gate to the work spot
	for _, z in { -7.6, -4.8, -2 } do
		part(m, "PathStone", Vector3.new(2.4, 0.3, 2.2), frame * CFrame.new(0, 0.35, z), tp.base, tp.baseMat)
	end

	-- era 2: a tool shed in the back-left corner, its door to the front
	if builds[1] then
		local sx, sz, w, d, h = -10.4, 12.6, 4.4, 3.4, 4.2
		local at = function(x: number, y: number, z: number): CFrame
			return frame * CFrame.new(sx + x, y, sz + z)
		end
		part(m, "ShedBase", Vector3.new(w + 0.4, 0.4, d + 0.4), at(0, 0.2, 0), ts.base, ts.baseMat)
		part(m, "ShedWalls", Vector3.new(w, h, d), at(0, 0.4 + h / 2, 0), ts.walls, ts.wallMat)
		for _, s in { -1, 1 } do
			part(m, "ShedCorner", Vector3.new(0.4, h, 0.4), at(s * (w / 2), 0.4 + h / 2, -d / 2), ts.frame, ts.frameMat)
		end
		part(m, "ShedDoor", Vector3.new(1.6, 3, 0.2), at(0.6, 1.9, -d / 2 - 0.05), ts.frame, ts.frameMat)
		part(m, "ShedWindow", Vector3.new(1, 0.9, 0.2), at(-1.3, 2.9, -d / 2 - 0.05), ts.glass, Enum.Material.Neon).CastShadow =
			false
		wedge(m, "ShedRoof", Vector3.new(w + 0.8, 1.4, d + 0.8), at(0, 0.4 + h + 0.7, 0), ts.roof, ts.roofMat)
	end

	-- era 3: a pergola over the gate, with vines
	if builds[2] then
		for _, s in { -1, 1 } do
			for _, z in { FZ0 - 0.6, FZ0 + 0.8 } do
				part(
					m,
					"PergolaPost",
					Vector3.new(0.5, 6, 0.5),
					frame * CFrame.new(s * (GATE - 0.6), 3, z),
					tg.frame,
					tg.frameMat
				)
			end
			part(
				m,
				"PergolaBeam",
				Vector3.new(0.4, 0.4, 2.4),
				frame * CFrame.new(s * (GATE - 0.6), 6.2, FZ0 + 0.1),
				tg.frame,
				tg.frameMat
			)
		end
		for k = -3, 3 do
			part(
				m,
				"PergolaSlat",
				Vector3.new(GATE * 2 + 0.8, 0.3, 0.3),
				frame * CFrame.new(0, 6.5, FZ0 + 0.1 + k * 0.4),
				tg.frame,
				tg.frameMat
			)
		end
		local leaf = Color3.fromRGB(96, 176, 70)
		for k = -3, 3 do
			local v = part(
				m,
				"Vine",
				Vector3.new(1.2, 0.5, 1.2),
				frame * CFrame.new(k * 1.2, 6.8, FZ0 + 0.1 + (k % 2) * 0.5),
				if k % 3 == 0 then Color3.fromRGB(240, 132, 168) else leaf,
				Enum.Material.Ground
			) :: Part
			v.Shape = Enum.PartType.Ball
		end
	end

	-- era 4: a greenhouse over both beds, its door to the work spot's path
	if builds[3] then
		local x0, x1, z0, z1, eave, ridge = -9.8, 9.8, -2.8, 10.8, 5, 7.4
		local glass = Color3.fromRGB(200, 236, 255)
		local function pane(name: string, size: Vector3, cf: CFrame)
			local p = part(m, name, size, cf, glass, Enum.Material.Glass)
			p.Transparency = 0.7
			p.CastShadow = false
			p.CanCollide = false
		end
		for _, x in { x0, -5, 0, 5, x1 } do
			for _, z in { z0, z1 } do
				-- no post in the middle of the front: that is the door (the owner, 2026-10-28)
				if not (x == 0 and z == z0) then
					part(
						m,
						"GHPost",
						Vector3.new(0.4, eave, 0.4),
						frame * CFrame.new(x, eave / 2, z),
						tg.frame,
						tg.frameMat
					)
				end
			end
		end
		for _, z in { z0, z1 } do
			part(m, "GHEave", Vector3.new(x1 - x0, 0.3, 0.4), frame * CFrame.new(0, eave, z), tg.frame, tg.frameMat)
		end
		part(
			m,
			"GHRidge",
			Vector3.new(x1 - x0, 0.4, 0.4),
			frame * CFrame.new(0, ridge, (z0 + z1) / 2),
			tg.frame,
			tg.frameMat
		)
		-- side walls of glass, the front left open over the path for the door
		pane("GHWall", Vector3.new(0.15, eave, z1 - z0), frame * CFrame.new(x0, eave / 2, (z0 + z1) / 2))
		pane("GHWall", Vector3.new(0.15, eave, z1 - z0), frame * CFrame.new(x1, eave / 2, (z0 + z1) / 2))
		pane("GHWall", Vector3.new(x1 - x0, eave, 0.15), frame * CFrame.new(0, eave / 2, z1))
		for _, s in { -1, 1 } do
			pane(
				"GHWall",
				Vector3.new(x1 - 1.6, eave, 0.15),
				frame * CFrame.new(s * (1.6 + (x1 - 1.6) / 2), eave / 2, z0)
			)
		end
		-- the roof: two slopes of glass on rafters
		local half = (z1 - z0) / 2
		local slope = math.sqrt(half * half + (ridge - eave) ^ 2)
		local tilt = math.atan2(ridge - eave, half)
		for _, s in { -1, 1 } do
			local cf = frame
				* CFrame.new(0, (eave + ridge) / 2, (z0 + z1) / 2 + s * half / 2)
				* CFrame.Angles(s * tilt, 0, 0)
			pane("GHRoof", Vector3.new(x1 - x0, 0.15, slope), cf)
			for _, x in { x0, -5, 0, 5, x1 } do
				part(
					m,
					"GHRafter",
					Vector3.new(0.3, 0.3, slope),
					frame
						* CFrame.new(x, (eave + ridge) / 2, (z0 + z1) / 2 + s * half / 2)
						* CFrame.Angles(s * tilt, 0, 0),
					tg.frame,
					tg.frameMat
				)
			end
		end
	end

	-- era 5: an irrigation windmill at the back, between the beds' ends and the fence
	if builds[4] then
		place(m, frame, "IrrigationWindmill", 0, 12.4, 11, 5.4)
	end

	-- the garden props
	for j = 1, 4 do
		local era = props[j]
		if era > 0 then
			place(
				m,
				frame,
				PROPS[j][era],
				SLOT_AT[j][1],
				SLOT_AT[j][2],
				HEIGHT[j][era],
				FOOT[j],
				if j == 1 then LIFT[era] else nil,
				j == 2 or j == 4 -- the side slots are narrow
			)
		end
	end
	return m
end

return GardenStages
