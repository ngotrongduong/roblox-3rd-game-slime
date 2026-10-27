--!strict
-- The training ground's 50 levels (the owner, 2026-10-28: "the same as the other areas"). Five eras
-- of ten levels; in each era:
--   level 1 of the era   the ground grows into a small arena, nothing taken away: era 2 wooden stands
--                        at the back; era 3 a punching bag with a second training spot, and flood-
--                        light masts at the corners; era 4 a canopy over the stands with a scoreboard,
--                        a third training spot facing the archery target; era 5 a champion's podium
--                        with a golden trophy by the entrance
--   levels 2-5           four training props, one a level, each slot taking its next, better version:
--                        1 strength (stone weights > log barbell > dumbbell rack > weight bench >
--                        gravity press)   2 agility (tyre run > hurdles > balance beam > climbing wall
--                        > holo hoops)   3 recovery (rest bench > water cooler > massage table > ice
--                        bath > heal pod)   4 gear (sword barrel > shield rack > armour stand >
--                        sparring bot > holo trainer)
--   levels 6-10          the ground's builds move up one material tier, one a level: floor, floor
--                        border, fence and stands, lamps and masts, the entrance arch and podium
-- Tiers and helpers are the pantry's. The dummy, the archery target, the weapon rack and the banner
-- stay the area's own; the training spots keep their markers (TrainSpotN with an Attachment
-- WorkSpotN) for the training rules. Positions are in the ground's own frame (x across, z from the
-- front in); every prop stands against the fence facing in.
local PantryStages = require(script.Parent.PantryStages)
local PondStages = require(script.Parent.PondStages)

local TrainingStages = {}

TrainingStages.MaxLevel = 50

local TIERS = PantryStages.Tiers
local part, place = PantryStages.part, PantryStages.place

-- the fence line: x -13.4 .. 13.4, z -12.4 .. 12.4, the entrance x -4 .. 4 at the front
local XF, ZF, GATE = 13.4, 12.4, 4

-- training spots: where, and from which level (the first is the area's own)
local SPOTS = { { 0, 1, 1 }, { -6.5, -0.8, 21 }, { 5.5, -3, 31 } }

local PROPS = {
	{ "StoneWeights", "WoodBarbell", "DumbbellRack", "WeightBench", "GravityPress" },
	{ "TyreRun", "JumpHurdles", "BalanceBeam", "ClimbingWall", "HoloHoops" },
	{ "RestBench", "WaterCooler", "MassageTable", "IceBath", "HealPod" },
	{ "SwordBarrel", "ShieldRack", "ArmorStand", "SparringBot", "HoloTrainer" },
}
-- real heights (studs, the player is 5)
local HEIGHT = {
	{ 1.4, 2.4, 3.2, 3.2, 5 },
	{ 1.2, 2, 2.2, 6, 4 },
	{ 1.8, 3.6, 2.6, 2.4, 5 },
	{ 3, 4, 5.5, 5, 5 },
}
-- where each slot stands and which way it faces (degrees; 0 to the front, 90 to -x, -90 to +x):
-- strength and agility against the side fences, recovery and gear in the back corners beside the
-- stands, all facing in
local SLOT_AT = { { -11.2, -4, -90 }, { 11.2, -3.5, 90 }, { -11.3, 10, -90 }, { 11.3, 10, 90 } }
local FOOT = { 3.2, 3.4, 2.8, 2.8 }
-- kit models whose front came out of generate_mesh sideways: the turn (degrees) that brings it to -Z
local FRONT_TURN: { [string]: number } = {}

-- What a level holds: the era, how many training spots, each prop slot's era (0: none), each
-- build's tier (floor, border, fence and stands, lamps and masts, arch and podium).
function TrainingStages.state(level: number): (number, number, { number }, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local spots = 0
	for _, p in SPOTS do
		spots += if level >= p[3] then 1 else 0
	end
	local props, tiers = {}, {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	for k = 1, 5 do
		tiers[k] = if s >= k + 5 then era + 1 else era
	end
	return era, spots, props, tiers
end

function TrainingStages.tierName(level: number): string
	local _, _, _, tiers = TrainingStages.state(level)
	return TIERS[tiers[1]].name
end

-- A part of the area itself takes a tier's colour; at tier 1 it keeps the look it was built with.
local function skin(p: BasePart, tier: number, colour: Color3, material: Enum.Material)
	if p:GetAttribute("BuiltColor") == nil then
		p:SetAttribute("BuiltColor", p.Color)
	end
	p.Color = if tier <= 1 then p:GetAttribute("BuiltColor") :: Color3 else colour
	PondStages.studLook(p, material)
end

local function glow(m: Model, name: string, size: Vector3, cf: CFrame, colour: Color3, range: number)
	local p = part(m, name, size, cf, colour, Enum.Material.Neon)
	p.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = colour
	light.Range = range
	light.Brightness = 0.7
	light.Parent = p
end

-- A model turned on the spot about its own middle.
local function turn(model: Model, degrees: number)
	local box = model:GetBoundingBox()
	local centre = CFrame.new(box.Position)
	model:PivotTo(centre * CFrame.Angles(0, math.rad(degrees), 0) * centre:ToObjectSpace(model:GetPivot()))
end

-- A ranch fence run: posts every three studs, two rails.
local function fenceRun(m: Model, frame: CFrame, x0: number, z0: number, x1: number, z1: number, t: any)
	local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local n = math.max(1, math.round(len / 3))
	for k = 0, n do
		local p = a + dir * (len * k / n)
		part(m, "FencePost", Vector3.new(0.7, 3.2, 0.7), frame * CFrame.new(p.X, 1.6, p.Z), t.frame, t.frameMat)
		part(m, "FenceCap", Vector3.new(0.95, 0.3, 0.95), frame * CFrame.new(p.X, 3.3, p.Z), t.trim, t.trimMat)
	end
	local mid = (a + b) / 2
	for _, y in { 1.1, 2.5 } do
		part(
			m,
			"FenceRail",
			Vector3.new(0.3, 0.4, len),
			frame * CFrame.new(mid.X, y, mid.Z) * CFrame.lookAt(Vector3.zero, dir),
			t.walls,
			t.wallMat
		)
	end
end

-- The ground's layer for a level. `area` is the training ground: its kit fence goes (the layer
-- stands in for it), its floor and border take their tiers, its weapon rack stands against the
-- left fence facing in.
function TrainingStages.build(area: Instance, frame: CFrame, level: number): Model
	local era, spots, props, tiers = TrainingStages.state(level)
	local tf, tl, ta = TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)
	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end

	for _, d in area:GetChildren() do
		if d.Name == "Fence" and d:IsA("Folder") then
			d.Parent = nil
		elseif d.Name == "Floor" and d:IsA("BasePart") then
			skin(d, tiers[1], TIERS[tiers[1]].yard, TIERS[tiers[1]].yardMat)
		elseif d.Name == "FloorEdge" and d:IsA("BasePart") then
			skin(d, tiers[2], TIERS[tiers[2]].edge, TIERS[tiers[2]].yardMat)
		elseif d.Name == "WeaponRack" and d:IsA("Model") and not d:GetAttribute("Turned") then
			d:SetAttribute("Turned", true)
			turn(d, -90)
			local box = d:GetBoundingBox()
			d:PivotTo(d:GetPivot() + (at(-12, 0, 3.9).Position - box.Position) * Vector3.new(1, 0, 1))
		end
	end

	-- 3 the fence, open at the entrance
	fenceRun(m, frame, -XF, ZF, XF, ZF, tf)
	fenceRun(m, frame, -XF, -ZF, -XF, ZF, tf)
	fenceRun(m, frame, XF, -ZF, XF, ZF, tf)
	fenceRun(m, frame, -XF, -ZF, -GATE, -ZF, tf)
	fenceRun(m, frame, GATE, -ZF, XF, -ZF, tf)

	-- 4 lamps either side of the entrance
	for _, s in { -1, 1 } do
		part(m, "LampPost", Vector3.new(0.5, 4.6, 0.5), at(s * 6.4, 2.3, -11.6), tl.frame, tl.frameMat)
		glow(m, "Lamp", Vector3.new(0.9, 0.9, 0.9), at(s * 6.4, 5, -11.6), tl.glass, 10)
	end

	-- 5 the entrance arch: two posts, a board, two crossed swords on a round shield
	for _, s in { -1, 1 } do
		part(m, "ArchPost", Vector3.new(0.9, 7, 0.9), at(s * GATE, 3.5, -ZF), ta.frame, ta.frameMat)
	end
	part(m, "ArchBoard", Vector3.new(GATE * 2 + 1.6, 0.9, 0.5), at(0, 6.6, -ZF), ta.walls, ta.wallMat)
	local shield = part(
		m,
		"ArchShield",
		Vector3.new(0.3, 1.8, 1.8),
		at(0, 8, -ZF) * CFrame.Angles(0, math.rad(90), 0),
		ta.trim,
		ta.trimMat
	) :: Part
	shield.Shape = Enum.PartType.Cylinder
	for _, s in { -1, 1 } do
		part(
			m,
			"ArchSword",
			Vector3.new(0.25, 2.8, 0.2),
			at(0, 8, -ZF - 0.25) * CFrame.Angles(0, 0, math.rad(s * 40)),
			Color3.fromRGB(210, 214, 222),
			Enum.Material.Metal
		)
	end

	-- era 2: wooden stands along the back, two steps behind the dummy
	if era >= 2 then
		for k, step in { { 9.6, 1.2 }, { 11.2, 2.4 } } do
			part(m, "Stand", Vector3.new(18, step[2], 1.6), at(0, step[2] / 2, step[1]), tf.walls, tf.wallMat)
			part(m, "Seat", Vector3.new(18.2, 0.25, 0.7), at(0, step[2] + 0.12, step[1] - 0.45), tf.trim, tf.trimMat)
			if k == 2 then
				part(m, "StandBack", Vector3.new(18, 1.4, 0.3), at(0, 3.1, 11.95), tf.frame, tf.frameMat)
			end
		end
	end
	-- era 3: the punching bag with its spot, and floodlight masts at the corners
	if era >= 3 then
		place(m, frame, "PunchingBag", -6.5, 3, 5.5, 2.4)
		for _, s in { -1, 1 } do
			for _, z in { -12.9, 12.9 } do
				local x = s * 12.9
				part(m, "Mast", Vector3.new(0.6, 11, 0.6), at(x, 5.5, z), tl.frame, tl.frameMat)
				local face = CFrame.lookAt(at(x, 11.2, z).Position, at(0, 0, 0).Position)
				part(m, "MastHead", Vector3.new(2, 1.2, 0.5), face, tl.frame, tl.frameMat)
				local lamp = part(
					m,
					"MastLamp",
					Vector3.new(1.7, 0.9, 0.2),
					face * CFrame.new(0, 0, -0.3),
					tl.glass,
					Enum.Material.Neon
				)
				lamp.CastShadow = false
			end
		end
	end
	-- era 4: a canopy over the stands, a scoreboard on top
	if era >= 4 then
		for _, x in { -9, 9 } do
			for _, z in { 8.9, 11.9 } do
				part(m, "CanopyPost", Vector3.new(0.5, 7, 0.5), at(x, 3.5, z), tl.frame, tl.frameMat)
			end
		end
		part(
			m,
			"Canopy",
			Vector3.new(19.4, 0.5, 4.4),
			at(0, 7.2, 10.4) * CFrame.Angles(math.rad(-6), 0, 0),
			tl.roof,
			tl.roofMat
		)
		part(m, "Scoreboard", Vector3.new(6.4, 2.8, 0.5), at(0, 9.2, 11.4), tl.frame, tl.frameMat)
		for _, s in { -1, 1 } do
			local score = part(
				m,
				"ScoreLight",
				Vector3.new(2.2, 1.6, 0.2),
				at(s * 1.5, 9.2, 11.1),
				if s < 0 then Color3.fromRGB(255, 120, 90) else Color3.fromRGB(110, 200, 255),
				Enum.Material.Neon
			)
			score.CastShadow = false
		end
	end
	-- era 5: the champion's podium by the entrance, a golden trophy on it
	if era >= 5 then
		local podium = part(
			m,
			"Podium",
			Vector3.new(1.2, 3.4, 3.4),
			at(8, 0.6, -8) * CFrame.Angles(0, 0, math.rad(90)),
			ta.base,
			ta.baseMat
		) :: Part
		podium.Shape = Enum.PartType.Cylinder
		local rim = part(
			m,
			"PodiumRim",
			Vector3.new(0.3, 3.7, 3.7),
			at(8, 1.25, -8) * CFrame.Angles(0, 0, math.rad(90)),
			ta.trim,
			ta.trimMat
		) :: Part
		rim.Shape = Enum.PartType.Cylinder
		place(m, frame, "ChampionTrophy", 8, -8, 3.6, 3, 1.4)
	end

	-- the training spots beyond the area's own: a straw mat each, with its marker
	for i = 2, spots do
		local p = SPOTS[i]
		local mat = part(
			m,
			"TrainSpot" .. i,
			Vector3.new(0.1, 3.6, 3.6),
			at(p[1], 0.45, p[2]) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(226, 190, 120),
			Enum.Material.Fabric
		) :: Part
		mat.Shape = Enum.PartType.Cylinder
		mat.CanCollide = false
		local mark = Instance.new("Attachment")
		mark.Name = "WorkSpot" .. i
		mark.Parent = mat
	end

	-- the training props
	for j = 1, 4 do
		local e = props[j]
		if e > 0 then
			local slot = SLOT_AT[j]
			local prop = place(m, frame, PROPS[j][e], slot[1], slot[2], HEIGHT[j][e], FOOT[j])
			local yaw = slot[3] + (FRONT_TURN[PROPS[j][e]] or 0)
			if prop and yaw ~= 0 then
				turn(prop, yaw)
			end
		end
	end
	return m
end

return TrainingStages
