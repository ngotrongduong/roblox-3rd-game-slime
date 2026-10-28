--!strict
-- The training ground's 50 levels (the owner, 2026-10-28: "the same as the other areas"). Five eras
-- of ten levels; in each era:
--   level 1 of the era   the ground grows into a small arena, nothing taken away: era 2 wooden stands
--                        at the back; era 3 a punching bag with a second training spot, and flood-
--                        light masts at the corners; era 4 a canopy over the stands with a scoreboard,
--                        a third training spot facing the archery target; era 5 the slime-tech
--                        equipment and dummy (no trophy: the owner, 2026-10-28). The dummy is built
--                        here and toughens every era.
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
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the fence line: x -13.4 .. 13.4, z -12.4 .. 12.4, the entrance x -4 .. 4 at the front
local XF, ZF, GATE = 13.4, 12.4, 4
-- From the stands' era the ground grows 6 studs at the back, so the stands sit behind the dummy
-- instead of against it (the owner, 2026-10-28: a cramped area grows, and never shrinks again)
local GROW, GROW_FROM = 6, 11
local FLOOR = 0.4 -- the ground's floor stands this far above the lawn; props stand on its top

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
	{ 2.6, 3, 3.6, 3.8, 5.8 }, -- (big enough to read against the player)
	{ 2.2, 2.4, 2.8, 6.4, 5.4 },
	{ 1.8, 3.6, 2.6, 2.4, 5 },
	{ 3, 4, 5.5, 5, 5 },
}
-- where each slot stands and which way it faces (degrees; 0 to the front, 90 to -x, -90 to +x):
-- strength and agility against the side fences, recovery and gear in the back corners beside the
-- stands, all facing in
-- (recovery and gear move back into the grown strip beside the stands once it is there)
local SLOT_AT = { { -11.2, -4, -90 }, { 11.2, -3.5, 90 }, { -11.3, 10, -90 }, { 11.3, 10, 90 } }
local FOOT = { 5, 5.6, 3.8, 3.8 }
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
	local mid = (a + b) / 2
	local brick = t.wallMat == Enum.Material.Brick
	if brick then
		-- a low brick foundation under the brick era's fence (ChatGPT's 1st training review)
		part(
			m,
			"FenceBase",
			Vector3.new(0.9, 0.6, len + 0.9),
			frame * CFrame.new(mid.X, 0.3, mid.Z) * CFrame.lookAt(Vector3.zero, dir),
			t.walls,
			t.wallMat
		)
	end
	for k = 0, n do
		local p = a + dir * (len * k / n)
		local w = if brick then 0.95 else 0.7
		part(m, "FencePost", Vector3.new(w, 3.2, w), frame * CFrame.new(p.X, 1.6, p.Z), t.frame, t.frameMat)
		-- (a glowing trim lights every other cap only, so the fence frames the ground and no more)
		local dim = t.trimMat == Enum.Material.Neon and k % 2 == 1
		part(
			m,
			"FenceCap",
			Vector3.new(w + 0.25, 0.3, w + 0.25),
			frame * CFrame.new(p.X, 3.3, p.Z),
			if dim then t.frame else t.trim,
			if dim then t.frameMat else t.trimMat
		)
	end
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

-- Training equipment built from parts at a player's real size where the kit models came out as toys
-- (ChatGPT's 2nd training review): along the left fence the agility course (hurdles across a running
-- lane, a raised balance beam, a tall climbing wall with a landing mat, three upright glowing hoop
-- gates); on the right the log barbell on its rests and the slime-tech gravity press.
local function equipment(m: Model, frame: CFrame, j: number, e: number, tiers: { number })
	local t = TIERS[tiers[1]]
	local wood, woodMat = Color3.fromRGB(150, 104, 62), Enum.Material.Wood
	local function at(px: number, y: number, pz: number): CFrame
		return frame * CFrame.new(px, FLOOR + y, pz)
	end
	local lane = 9.6 -- the running lane along the left fence
	if j == 2 and e == 2 then
		for _, hz in { -8, -4, 0 } do
			for _, sx in { -1.2, 1.2 } do
				part(m, "HurdlePost", Vector3.new(0.25, 1.9, 0.25), at(lane + sx, 0.95, hz), t.frame, t.frameMat)
				part(m, "HurdleFoot", Vector3.new(0.3, 0.2, 1.1), at(lane + sx, 0.1, hz), t.frame, t.frameMat)
			end
			part(m, "HurdleBar", Vector3.new(2.6, 0.3, 0.25), at(lane, 1.75, hz), Color3.fromRGB(240, 80, 70))
			part(m, "HurdleStripe", Vector3.new(0.6, 0.32, 0.27), at(lane, 1.75, hz), Color3.fromRGB(250, 248, 240))
		end
	elseif j == 2 and e == 3 then
		part(m, "Beam", Vector3.new(0.7, 0.4, 6.4), at(lane, 1.4, -4), wood, woodMat)
		for _, bz in { -6.6, -1.4 } do
			part(m, "BeamLeg", Vector3.new(0.5, 1.2, 0.5), at(lane, 0.6, bz), t.frame, t.frameMat)
			part(m, "BeamFoot", Vector3.new(1.8, 0.25, 0.6), at(lane, 0.12, bz), t.frame, t.frameMat)
		end
		part(m, "Mat", Vector3.new(3.2, 0.15, 7.6), at(lane, 0.08, -4), Color3.fromRGB(90, 140, 220))
	elseif j == 2 and e == 4 then
		local wx = 12.4
		part(
			m,
			"ClimbWall",
			Vector3.new(0.5, 5.8, 4.6),
			at(wx, 2.9, -4),
			Color3.fromRGB(214, 176, 124),
			Enum.Material.WoodPlanks
		)
		for _, sz in { -1, 1 } do
			part(m, "ClimbFrame", Vector3.new(0.6, 6.1, 0.35), at(wx, 3.05, -4 + sz * 2.4), t.frame, t.frameMat)
		end
		local holds = {
			Color3.fromRGB(240, 80, 70),
			Color3.fromRGB(250, 200, 60),
			Color3.fromRGB(90, 160, 240),
			Color3.fromRGB(110, 200, 110),
		}
		for k = 0, 9 do
			local hold = part(
				m,
				"Hold",
				Vector3.new(0.4, 0.45, 0.45),
				at(wx - 0.35, 0.9 + (k % 5) * 1.05, -5.6 + (k * 1.37) % 3.4),
				holds[k % 4 + 1]
			) :: Part
			hold.Shape = Enum.PartType.Ball
		end
		part(m, "LandingMat", Vector3.new(3, 0.5, 4.6), at(wx - 1.9, 0.25, -4), Color3.fromRGB(150, 90, 200))
	elseif j == 2 and e == 5 then
		local mint = Color3.fromRGB(120, 240, 220)
		for k, hz in { -8, -4.5, -1 } do
			local h = 4 + k * 0.3
			for _, sx in { -1.4, 1.4 } do
				part(m, "HoopPost", Vector3.new(0.35, h, 0.35), at(lane + sx, h / 2, hz), mint, Enum.Material.Neon).CastShadow =
					false
			end
			part(m, "HoopTop", Vector3.new(3.15, 0.35, 0.35), at(lane, h, hz), mint, Enum.Material.Neon).CastShadow =
				false
			part(m, "HoopBase", Vector3.new(3.6, 0.3, 0.9), at(lane, 0.15, hz), t.frame, t.frameMat)
		end
	elseif j == 1 and e == 2 then
		-- a 4.5-stud log barbell resting on two forked posts, a second lying on the pad
		for _, bz in { -5.6, -2.4 } do
			part(m, "Rest", Vector3.new(0.4, 1.6, 0.4), at(-10.4, 0.8, bz), wood, woodMat)
		end
		local log = part(
			m,
			"BarLog",
			Vector3.new(4.6, 0.4, 0.4),
			at(-10.4, 1.75, -4) * CFrame.Angles(0, math.pi / 2, 0),
			Color3.fromRGB(176, 128, 84),
			woodMat
		) :: Part
		log.Shape = Enum.PartType.Cylinder
		for _, wz in { -6.1, -1.9 } do
			local w = part(
				m,
				"BarWeight",
				Vector3.new(0.6, 1.5, 1.5),
				at(-10.4, 1.75, wz) * CFrame.Angles(0, math.pi / 2, 0),
				wood,
				woodMat
			) :: Part
			w.Shape = Enum.PartType.Cylinder
		end
	elseif j == 1 and e == 5 then
		-- the gravity press: a base, two tall rails, a press bar with weights between them, a glowing
		-- slime core in the base and a cable up the rail
		local mint = Color3.fromRGB(120, 240, 220)
		local px = -10.6
		part(m, "PressBase", Vector3.new(2.6, 0.6, 4.4), at(px, 0.3, -4), t.frame, t.frameMat)
		for _, rz in { -1.8, 1.8 } do
			part(
				m,
				"PressRail",
				Vector3.new(0.45, 6, 0.45),
				at(px, 3.3, -4 + rz),
				Color3.fromRGB(150, 156, 166),
				Enum.Material.Metal
			)
		end
		part(m, "PressTop", Vector3.new(0.6, 0.5, 4.2), at(px, 6.3, -4), t.frame, t.frameMat)
		part(
			m,
			"PressBar",
			Vector3.new(0.35, 0.35, 3.6),
			at(px, 3.6, -4),
			Color3.fromRGB(60, 60, 66),
			Enum.Material.Metal
		)
		for _, wz in { -1.4, 1.4 } do
			local w = part(
				m,
				"PressWeight",
				Vector3.new(0.5, 1.4, 1.4),
				at(px, 3.6, -4 + wz) * CFrame.Angles(0, math.pi / 2, 0),
				Color3.fromRGB(70, 150, 140),
				Enum.Material.Metal
			) :: Part
			w.Shape = Enum.PartType.Cylinder
		end
		local core = part(m, "PressCore", Vector3.one * 0.9, at(px - 1.1, 0.75, -4), mint, Enum.Material.Neon) :: Part
		core.Shape = Enum.PartType.Ball
		core.CastShadow = false
		part(m, "PressCable", Vector3.new(0.15, 5.4, 0.15), at(px - 0.35, 3.3, -5.9), mint, Enum.Material.Neon).CastShadow =
			false
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

	local back = if level >= GROW_FROM then ZF + GROW else ZF
	local dz = back - ZF
	for _, d in area:GetChildren() do
		-- (the kit fence and dummy go: the layer builds them in the era's materials)
		local kitGone = (d.Name == "Fence" and d:IsA("Folder")) or (d.Name == "TrainingDummy" and d:IsA("Model"))
		if kitGone then
			d.Parent = nil
		elseif d.Name == "Floor" and d:IsA("BasePart") then
			skin(d, tiers[1], TIERS[tiers[1]].yard, TIERS[tiers[1]].yardMat)
		elseif d.Name == "FloorEdge" and d:IsA("BasePart") then
			skin(d, tiers[2], TIERS[tiers[2]].edge, TIERS[tiers[2]].yardMat)
			-- (the back edge moves out with the grown floor, the side edges stretch to it)
			local q = frame:ToObjectSpace(d.CFrame)
			if d:GetAttribute("HomeZ") == nil then
				d:SetAttribute("HomeZ", q.Z)
				d:SetAttribute("HomeLen", d.Size.Z)
			end
			local hz, hl = d:GetAttribute("HomeZ") :: number, d:GetAttribute("HomeLen") :: number
			if hz > ZF then
				d.CFrame = d.CFrame + frame:VectorToWorldSpace(Vector3.new(0, 0, hz + dz - q.Z))
			elseif math.abs(hz) < 1 then
				d.Size = Vector3.new(d.Size.X, d.Size.Y, hl + dz)
				d.CFrame = d.CFrame + frame:VectorToWorldSpace(Vector3.new(0, 0, dz / 2 - q.Z))
			end
		elseif (d.Name == "BannerFlag" and d:IsA("Model")) or (d.Name == "FlagBase" and d:IsA("BasePart")) then
			-- the banner stands outside the front fence beside the gate, not in the entrance where it hid
			-- the dummy (ChatGPT's 1st training review)
			if d:GetAttribute("Moved") == nil then
				d:SetAttribute("Moved", true)
				d:PivotTo(d:GetPivot() + frame:VectorToWorldSpace(Vector3.new(-5, 0, -5.4)))
			end
		elseif d.Name == "WeaponRack" and d:IsA("Model") and not d:GetAttribute("Turned") then
			d:SetAttribute("Turned", true)
			turn(d, -90)
			local box = d:GetBoundingBox()
			d:PivotTo(d:GetPivot() + (at(-12, 0, 3.9).Position - box.Position) * Vector3.new(1, 0, 1))
		end
	end

	if dz > 0 then
		local floor = area:FindFirstChild("Floor")
		local ext = part(
			m,
			"FloorExt",
			Vector3.new(XF * 2 - 0.8, 0.4, dz),
			at(0, 0.2, ZF - 0.4 + dz / 2),
			if floor and floor:IsA("BasePart") then floor.Color else TIERS[tiers[1]].yard
		)
		if floor and floor:IsA("BasePart") then
			ext.Material, ext.MaterialVariant, ext.TopSurface = floor.Material, floor.MaterialVariant, floor.TopSurface
		end
	end

	-- 3 the fence, open at the entrance
	fenceRun(m, frame, -XF, back, XF, back, tf)
	fenceRun(m, frame, -XF, -ZF, -XF, back, tf)
	fenceRun(m, frame, XF, -ZF, XF, back, tf)
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
		for k, step in { { 9.6 + dz, 1.2 }, { 11.2 + dz, 2.4 } } do
			part(m, "Stand", Vector3.new(18, step[2], 1.6), at(0, step[2] / 2, step[1]), tf.walls, tf.wallMat)
			part(m, "Seat", Vector3.new(18.2, 0.25, 0.7), at(0, step[2] + 0.12, step[1] - 0.45), tf.trim, tf.trimMat)
			if k == 2 then
				part(m, "StandBack", Vector3.new(18, 1.4, 0.3), at(0, 3.1, 11.95 + dz), tf.frame, tf.frameMat)
			end
		end
	end
	-- era 3: the punching bag with its spot, and floodlight masts at the corners
	if era >= 3 then
		place(m, frame, "PunchingBag", -6.5, 3, 5.5, 2.4, FLOOR)
		for _, s in { -1, 1 } do
			for _, z in { -12.9, back + 0.5 } do
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
			for _, z in { 8.9 + dz, 11.9 + dz } do
				part(m, "CanopyPost", Vector3.new(0.5, 7, 0.5), at(x, 3.5, z), tl.frame, tl.frameMat)
			end
		end
		part(
			m,
			"Canopy",
			Vector3.new(19.4, 0.5, 4.4),
			at(0, 7.2, 10.4 + dz) * CFrame.Angles(math.rad(-6), 0, 0),
			tl.roof,
			tl.roofMat
		)
		part(m, "Scoreboard", Vector3.new(8, 3.6, 0.5), at(0, 9.6, 11.4 + dz), tl.frame, tl.frameMat)
		for _, s in { -1, 1 } do
			local score = part(
				m,
				"ScoreLight",
				Vector3.new(2.2, 1.6, 0.2),
				at(s * 1.5, 9.2, 11.1 + dz),
				if s < 0 then Color3.fromRGB(255, 120, 90) else Color3.fromRGB(110, 200, 255),
				Enum.Material.Neon
			)
			score.CastShadow = false
		end
	end

	-- the training spots beyond the area's own: a straw mat each, with its marker
	for i = 2, spots do
		local p = SPOTS[i]
		local mat = part(
			m,
			"TrainSpot" .. i,
			Vector3.new(0.1, 3.6, 3.6),
			at(p[1], 0.45, p[2]) * CFrame.Angles(0, 0, math.rad(90)),
			TIERS[tiers[1]].base,
			TIERS[tiers[1]].baseMat
		) :: Part
		mat.Shape = Enum.PartType.Cylinder
		mat.CanCollide = false
		-- a light ring round the pad so it reads on the dark floors too
		local ring = part(
			m,
			"SpotRing",
			Vector3.new(0.06, 4.2, 4.2),
			at(p[1], 0.43, p[2]) * CFrame.Angles(0, 0, math.rad(90)),
			TIERS[tiers[1]].edge
		) :: Part
		ring.Shape = Enum.PartType.Cylinder
		ring.CanCollide = false
		local mark = Instance.new("Attachment")
		mark.Name = "WorkSpot" .. i
		mark.Parent = mat
	end

	-- the practice arena in the middle: a low outline round the three training spots, worn patches
	-- before the dummy, straw fallen from it (ChatGPT's 1st training review)
	local tb = TIERS[tiers[1]]
	local ax0, ax1, az0, az1 = -9, 9, -5.5, 8
	for _, e in
		{
			{ (ax0 + ax1) / 2, az0, ax1 - ax0, 0.3 },
			{ (ax0 + ax1) / 2, az1, ax1 - ax0, 0.3 },
			{ ax0, (az0 + az1) / 2, 0.3, az1 - az0 },
			{ ax1, (az0 + az1) / 2, 0.3, az1 - az0 },
		}
	do
		part(m, "ArenaLine", Vector3.new(e[3], 0.1, e[4]), at(e[1], FLOOR + 0.05, e[2]), tb.edge, tb.yardMat).CastShadow =
			false
	end
	for k, o in { { -0.8, 2.6, 2.2 }, { 1.1, 3.4, 1.6 } } do
		local worn = part(
			m,
			"Worn",
			Vector3.new(0.04, o[3], o[3] * 0.8),
			at(o[1], FLOOR + 0.03, o[2]) * CFrame.Angles(0, k, math.pi / 2),
			Color3.fromRGB(150, 130, 100)
		) :: Part
		worn.Shape = Enum.PartType.Cylinder
		worn.Transparency = 0.6
		worn.CastShadow = false
	end
	for k, o in { { -1.6, 4.6 }, { 1.4, 4.9 } } do
		wedge(
			m,
			"Straw",
			Vector3.new(1, 0.3, 0.7),
			at(o[1], FLOOR + 0.15, o[2]) * CFrame.Angles(0, k * 1.3, 0),
			Color3.fromRGB(232, 196, 120),
			Enum.Material.SmoothPlastic
		)
	end
	-- the training dummy, built here so it grows tougher with the eras in the ground's own materials
	-- (the owner, 2026-10-28): a cross-shaped dummy on a post, its target on the chest to the gate.
	--   rustic        a timber post on a plank foot, a straw body and arms tied with rope, a sack head
	--   painted       painted post, coloured arm bands, a padded head guard
	--   brick         a brick plinth, iron shoulder plates and a bolted chest board
	--   steel         a flanged steel post, segmented chest plates, ball joints at the shoulders
	--   slime tech    a dark tech base with a glowing ring, an armoured housing round a slime core,
	--                 glowing arm rings and target centre
	do
		local dx, dzz = 0, 6
		local S = 2 / 3 -- (two thirds of the kit dummy's size: the owner, 2026-10-28)
		local td = TIERS[era]
		local straw, rope = Color3.fromRGB(232, 196, 120), Color3.fromRGB(150, 110, 70)
		local sack = Color3.fromRGB(214, 180, 130)
		local iron, steel = Color3.fromRGB(70, 72, 80), Color3.fromRGB(160, 166, 176)
		local mint = Color3.fromRGB(120, 240, 220)
		local red, white = Color3.fromRGB(220, 70, 60), Color3.fromRGB(250, 246, 236)
		local function d(
			name: string,
			size: Vector3,
			x: number,
			y: number,
			z: number,
			col: Color3,
			mat: Enum.Material?
		): BasePart
			return part(
				m,
				name,
				size * S,
				at(dx + x * S, FLOOR + y * S, dzz + z * S),
				col,
				mat or Enum.Material.SmoothPlastic
			)
		end
		local function disc(name: string, r: number, y: number, z: number, col: Color3, mat: Enum.Material?): Part
			local p = part(
				m,
				name,
				Vector3.new(0.15, r * S, r * S),
				at(dx, FLOOR + y * S, dzz + z * S) * CFrame.Angles(0, math.pi / 2, 0),
				col,
				mat or Enum.Material.SmoothPlastic
			) :: Part
			p.Shape = Enum.PartType.Cylinder
			return p
		end
		-- the foot
		if era <= 2 then
			d("DummyFoot", Vector3.new(3.4, 0.4, 0.8), 0, 0.2, 0, td.frame, td.frameMat)
			d("DummyFoot", Vector3.new(0.8, 0.4, 3.4), 0, 0.2, 0, td.frame, td.frameMat)
		elseif era <= 4 then
			d("DummyPlinth", Vector3.new(3, 0.9, 3), 0, 0.45, 0, TIERS[3].walls, TIERS[3].wallMat)
			d("PlinthCap", Vector3.new(3.3, 0.25, 3.3), 0, 1, 0, TIERS[3].base, TIERS[3].baseMat)
		else
			d("DummyBase", Vector3.new(3.2, 0.8, 3.2), 0, 0.4, 0, td.frame, td.frameMat)
			d("BaseGlow", Vector3.new(3.4, 0.15, 3.4), 0, 0.85, 0, mint, Enum.Material.Neon).CastShadow = false
		end
		local foot = if era <= 2 then 0.4 else 1.1
		-- the post
		local postCol, postMat = Color3.fromRGB(150, 104, 62), Enum.Material.Wood
		if era == 2 then
			postCol, postMat = td.frame, td.frameMat
		elseif era >= 4 then
			postCol, postMat = steel, Enum.Material.Metal
		end
		d("DummyPost", Vector3.new(0.7, 4.2, 0.7), 0, foot + 2.1, 0, postCol, postMat)
		if era >= 4 then
			for _, s in { -1, 1 } do
				d("PostFlange", Vector3.new(1.1, 4.2, 0.15), 0, foot + 2.1, s * 0.4, postCol, postMat)
			end
		end
		-- the body: straw, tied; plated from steel on
		local by = foot + 5
		d("DummyBody", Vector3.new(2.4, 3, 1.6), 0, by, 0, straw)
		for _, ry in { -1, 0.9 } do
			d("BodyRope", Vector3.new(2.5, 0.22, 1.7), 0, by + ry, 0, rope)
		end
		if era >= 4 then
			for k = 0, 2 do
				d(
					"ChestPlate",
					Vector3.new(2.6, 0.8, 0.25),
					0,
					by - 0.9 + k * 0.9,
					-0.85,
					if era == 5 then td.frame else steel,
					Enum.Material.Metal
				)
			end
		elseif era == 3 then
			d("ChestBoard", Vector3.new(2, 2, 0.2), 0, by, -0.85, Color3.fromRGB(150, 104, 62), Enum.Material.Wood)
			for _, b in { { -0.8, 0.8 }, { 0.8, 0.8 }, { -0.8, -0.8 }, { 0.8, -0.8 } } do
				local bolt = d("Bolt", Vector3.one * 0.25, b[1], by + b[2], -0.97, iron, Enum.Material.Metal) :: Part
				bolt.Shape = Enum.PartType.Ball
			end
		end
		-- the target on the chest, in front of the plates
		local tz = if era >= 3 then -1.05 else -0.85
		disc("Target", 1.7, by, tz, white)
		disc("Target", 1.15, by, tz - 0.04, red)
		disc(
			"Target",
			0.55,
			by,
			tz - 0.08,
			if era == 5 then mint else white,
			if era == 5 then Enum.Material.Neon else nil
		)
		-- the arms: straw bundles on a crossbar, tied
		d("ArmBar", Vector3.new(6.4, 0.45, 0.45), 0, by + 0.9, 0, postCol, postMat)
		for _, s in { -1, 1 } do
			d("Arm", Vector3.new(2, 0.9, 0.9), s * 2.4, by + 0.9, 0, straw)
			d("ArmTie", Vector3.new(0.25, 1, 1), s * 3.2, by + 0.9, 0, rope)
			if era == 2 then
				d("ArmBand", Vector3.new(0.4, 1, 1), s * 2, by + 0.9, 0, td.frame, td.frameMat)
			elseif era == 3 then
				d("ShoulderPlate", Vector3.new(1.6, 0.4, 1.3), s * 1.5, by + 1.55, 0, iron, Enum.Material.Metal)
			elseif era >= 4 then
				local joint =
					d("ShoulderJoint", Vector3.one * 1.1, s * 1.4, by + 0.9, 0, iron, Enum.Material.Metal) :: Part
				joint.Shape = Enum.PartType.Ball
				if era == 5 then
					d("ArmRing", Vector3.new(0.3, 1.05, 1.05), s * 2.6, by + 0.9, 0, mint, Enum.Material.Neon).CastShadow =
						false
				end
			end
		end
		-- the head: a sack tied at the neck, a padded guard on painted timber, a helmet from steel on
		local hy = by + 2.5
		d("Neck", Vector3.new(0.7, 0.5, 0.7), 0, hy - 0.75, 0, rope)
		local head = d("Head", Vector3.one * 1.7, 0, hy, 0, sack) :: Part
		head.Shape = Enum.PartType.Ball
		if era == 2 then
			d("HeadGuard", Vector3.new(1.9, 0.5, 1.9), 0, hy + 0.65, 0, td.frame, td.frameMat)
		elseif era >= 3 then
			-- (a round helmet down over the head, cheek guards either side, the visor slit across)
			local helmet = d(
				"Helmet",
				Vector3.one * 2,
				0,
				hy + 0.2,
				0,
				if era == 3 then iron else steel,
				Enum.Material.Metal
			) :: Part
			helmet.Shape = Enum.PartType.Ball
			for _, s in { -1, 1 } do
				d(
					"CheekGuard",
					Vector3.new(0.3, 1, 1.2),
					s * 0.85,
					hy - 0.3,
					-0.2,
					if era == 3 then iron else steel,
					Enum.Material.Metal
				)
			end
			d(
				"Visor",
				Vector3.new(1.4, 0.25, 0.2),
				0,
				hy + 0.1,
				-0.98,
				if era == 5 then mint else iron,
				if era == 5 then Enum.Material.Neon else Enum.Material.Metal
			)
		end
	end

	-- spectators' benches on the lawn either side of the path, facing the ground, from the stands' era
	if era >= 2 then
		for _, x in { -9.5, 11.5 } do
			local bench = place(m, frame, "LogBench", x, -16, 2, 5.6, 0.1)
			part(
				m,
				"BenchPad",
				Vector3.new(6.4, 0.1, 2.4),
				at(x, 0.05, -16),
				Color3.fromRGB(176, 170, 160),
				Enum.Material.Slate
			)
			if bench then
				turn(bench, 180)
			end
		end
	end

	-- the training props
	for j = 1, 4 do
		local e = props[j]
		if e > 0 then
			local slot = SLOT_AT[j]
			local z = if j >= 3 and dz > 0 then 15 else slot[2]
			-- each station on its own pad (ChatGPT's 1st training review)
			part(
				m,
				"StationPad",
				Vector3.new(FOOT[j] + 0.8, 0.08, FOOT[j] + 0.8),
				at(slot[1] + (if slot[1] > 0 then -0.4 else 0.4), FLOOR + 0.04, z),
				TIERS[tiers[1]].base,
				TIERS[tiers[1]].baseMat
			)
			local built = (j == 2 and e >= 2) or (j == 1 and (e == 2 or e == 5))
			if built then
				equipment(m, frame, j, e, tiers)
			else
				local prop = place(m, frame, PROPS[j][e], slot[1], z, HEIGHT[j][e], FOOT[j], FLOOR + 0.08)
				local yaw = slot[3] + (FRONT_TURN[PROPS[j][e]] or 0)
				if prop and yaw ~= 0 then
					turn(prop, yaw)
				end
			end
		end
	end
	return m
end

return TrainingStages
