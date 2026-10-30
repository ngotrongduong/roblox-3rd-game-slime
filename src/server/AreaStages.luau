--!strict
-- The 50 levels of the home plot's other areas (the owner, 2026-10-27: "do the same for the other
-- areas" as the fishing pond): each area keeps its size and its buildings; it gains five parts that
-- never go away, and their materials climb the same ten tiers as the pond (PondStages.Tiers):
--   1 the floor and frame (the area's own floor and edging take the tier's materials; at tier 1 they
--     keep their first look)   2 the area's extra (rails, or benches)   3 lamps at its entrance
--   4 a crate or bin   5 planters, and light strips along the floor's edges in the modern tiers
-- Levels 1-5 add parts 2-5 one by one in rustic wood (level 1 is the area as built); from level 6
-- every five levels are a tier and each level moves one part up to it (PondStages.parts).
-- Positions are in each area's own frame (Layout.plotAreaFacing), y up from the ground.
local ServerStorage = game:GetService("ServerStorage")

local PondStages = require(script.Parent.PondStages)

local AreaStages = {}

type Tier = PondStages.Tier
type Spec = {
	label: string,
	floor: { string }, -- part names (anywhere in the area) that take the tier's floor
	frame: { string }, -- part names that take the tier's frame
	rails: { { number } }?, -- runs x0, z0, x1, z1
	benches: { { number } }?, -- x, z, turn
	lamps: { { number } }, -- x, z
	crate: { number }, -- x, z, turn
	planters: { { number } }, -- x, z
	trim: { { number } }, -- runs x0, z0, x1, z1 along the floor's edges
	prompt: { number }, -- x, z of the Upgrade point
}

AreaStages.Specs = {
	KitchenL1 = {
		label = "Kitchen",
		floor = { "Floor" },
		frame = { "FloorEdge" },
		rails = { { -10.7, -5, -10.7, 8.4 }, { 10.7, -5, 10.7, 8.4 }, { -10.7, 8.6, 10.7, 8.6 } },
		lamps = { { -10.5, -8.4 }, { 10.5, -8.4 } },
		crate = { 8.5, -6.3, 0 },
		planters = { { -9, -6.4 }, { 9.4, 0.5 } },
		trim = { { -11, -9, 11, -9 }, { -11, 9, 11, 9 }, { -11, -9, -11, 9 }, { 11, -9, 11, 9 } },
		prompt = { 0, -13 }, -- (the village scale: the kitchen's pad spread to z -12.2)
	},
	PantryL1 = {
		label = "Pantry",
		floor = { "Floor" },
		frame = { "FloorEdge" },
		rails = { { -11.6, -8, -11.6, 9.4 }, { 11.6, -8, 11.6, 9.4 } },
		lamps = { { -11, -9.3 }, { 11, -9.3 } },
		crate = { -9, 7, 0 },
		planters = { { 9.2, 7 }, { 5, -8.6 } },
		trim = { { -12, -10, 12, -10 }, { -12, 10, 12, 10 }, { -12, -10, -12, 10 }, { 12, -10, 12, 10 } },
		prompt = { 0, -15.4 }, -- (the village scale)
	},
	GardenL1 = {
		label = "Garden",
		floor = {},
		frame = { "BedPlank" },
		benches = { { -10.5, -4, 90 } },
		lamps = { { -4.6, -8.3 }, { 4.6, -8.3 } },
		crate = { 10.4, 12, 0 },
		planters = { { 10.6, -6.6 }, { 10.6, 4 } },
		trim = { { -13, -9, -4, -9 }, { 4, -9, 13, -9 }, { -13, 15, 13, 15 }, { -13, -9, -13, 15 }, { 13, -9, 13, 15 } },
		prompt = { 0, -13.5 }, -- (the village scale: the fence's front at z -12)
	},
	BreedingL1 = {
		label = "Breeding Pen",
		floor = { "PenFloor", "IncubatorPad" },
		frame = {},
		-- (the pen of the village scale, BreedingStages: x -17 .. 25, z -19 .. 19)
		benches = { { -12, -16.5, 0 } },
		lamps = { { -1, -20.4 }, { 9, -20.4 } },
		crate = { 22.8, -16, 0 },
		planters = { { 23.6, 3 }, { -15.6, 3 } },
		trim = {
			{ -17, -19, 0, -19 },
			{ 8, -19, 25, -19 },
			{ -17, 19, 25, 19 },
			{ -17, -19, -17, 19 },
			{ 25, -19, 25, 19 },
		},
		prompt = { 4, -21 },
	},
	TrainingL1 = {
		label = "Training Ground",
		floor = { "Floor" },
		frame = { "FloorEdge" },
		benches = { { 10, -7.5, 0 } },
		lamps = { { -6.6, -11.6 }, { 6.6, -11.6 } },
		crate = { -10.5, -3, 90 },
		planters = { { 11.4, 10.2 }, { -11.4, 10.2 } },
		trim = { { -13, -12, 13, -12 }, { -13, 12, 13, 12 }, { -13, -12, -13, 12 }, { 13, -12, 13, 12 } },
		prompt = { 0, -17 }, -- (the village scale: the front fence at z -16.4)
	},
} :: { [string]: Spec }

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	colour: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Anchored = true
	PondStages.studLook(p, material)
	p.CastShadow = size.Magnitude > 4
	p.Parent = parent
	return p
end

local function pole(
	parent: Instance,
	name: string,
	cf: CFrame,
	height: number,
	diameter: number,
	colour: Color3,
	material: Enum.Material?
): Part
	local p = part(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		cf * CFrame.Angles(0, 0, math.rad(90)),
		colour,
		material
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function rail(parent: Instance, frame: CFrame, run: { number }, t: Tier)
	local a, b = Vector3.new(run[1], 0, run[2]), Vector3.new(run[3], 0, run[4])
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local along = CFrame.lookAt(Vector3.zero, dir)
	local n = math.max(1, math.round(len / 3))
	for k = 0, n do
		local p = a + dir * (len * k / n)
		part(parent, "RailPost", Vector3.new(0.4, 1.8, 0.4), frame * CFrame.new(p.X, 0.9, p.Z), t.frame, t.frameMat)
	end
	local mid = (a + b) / 2
	part(
		parent,
		"Rail",
		Vector3.new(0.35, 0.3, len + 0.4),
		frame * CFrame.new(mid.X, 1.85, mid.Z) * along,
		t.accent,
		t.accentMat
	)
	part(
		parent,
		"RailLow",
		Vector3.new(0.25, 0.2, len),
		frame * CFrame.new(mid.X, 0.9, mid.Z) * along,
		t.frame,
		t.frameMat
	)
end

local function bench(parent: Instance, frame: CFrame, b: { number }, t: Tier)
	local base = frame * CFrame.new(b[1], 0, b[2]) * CFrame.Angles(0, math.rad(b[3]), 0)
	part(parent, "BenchSeat", Vector3.new(3.6, 0.3, 1.1), base * CFrame.new(0, 1.15, 0), t.planks[1], t.deck)
	part(parent, "BenchBack", Vector3.new(3.6, 0.9, 0.2), base * CFrame.new(0, 1.9, 0.5), t.planks[2], t.deck)
	for _, dx in { -1.5, 1.5 } do
		part(parent, "BenchLeg", Vector3.new(0.3, 1, 1), base * CFrame.new(dx, 0.5, 0), t.frame, t.frameMat)
	end
end

local function lamp(parent: Instance, frame: CFrame, l: { number }, t: Tier)
	local base = frame * CFrame.new(l[1], 0, l[2])
	pole(parent, "LampPost", base * CFrame.new(0, 1.8, 0), 3.6, 0.35, t.frame, t.frameMat)
	local head =
		part(parent, "Lamp", Vector3.new(0.7, 0.8, 0.7), base * CFrame.new(0, 3.95, 0), t.light, Enum.Material.Neon)
	head.CastShadow = false
	part(parent, "LampCap", Vector3.new(0.95, 0.25, 0.95), base * CFrame.new(0, 4.45, 0), t.accent, t.accentMat)
	local light = Instance.new("PointLight")
	light.Color = t.light
	light.Range = 10
	light.Brightness = 0.8
	light.Parent = head
end

local function crate(parent: Instance, frame: CFrame, c: { number }, t: Tier)
	local base = frame * CFrame.new(c[1], 0, c[2]) * CFrame.Angles(0, math.rad(c[3]), 0)
	part(parent, "Crate", Vector3.new(2.2, 1.4, 1.6), base * CFrame.new(0, 0.7, 0), t.box, t.boxMat)
	part(parent, "CrateLid", Vector3.new(2.35, 0.2, 1.75), base * CFrame.new(0, 1.5, 0), t.accent, t.accentMat)
	for _, dx in { -0.75, 0.75 } do
		part(parent, "CrateBand", Vector3.new(0.15, 1.42, 1.65), base * CFrame.new(dx, 0.7, 0), t.accent, t.accentMat)
	end
end

local function flowers(parent: Instance, at: CFrame)
	local nature = ServerStorage:FindFirstChild("NatureKit")
	local bundle = ServerStorage:FindFirstChild("Kit")
	nature = nature or (bundle and bundle:FindFirstChild("NatureKit"))
	local src = nature and nature:FindFirstChild("FlowerPatch")
	if not src or not src:IsA("Model") then
		return
	end
	local m = src:Clone()
	local _, s0 = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * 1.1 / s0.Y)
	local box, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (at.Position + Vector3.new(0, size.Y / 2, 0) - box.Position))
	m.Parent = parent
end

local function planter(parent: Instance, frame: CFrame, p: { number }, t: Tier)
	local base = frame * CFrame.new(p[1], 0, p[2])
	part(parent, "Planter", Vector3.new(1.6, 0.9, 1.6), base * CFrame.new(0, 0.45, 0), t.box, t.boxMat)
	part(parent, "PlanterRim", Vector3.new(1.8, 0.15, 1.8), base * CFrame.new(0, 0.95, 0), t.accent, t.accentMat)
	part(
		parent,
		"PlanterSoil",
		Vector3.new(1.4, 0.1, 1.4),
		base * CFrame.new(0, 0.92, 0),
		Color3.fromRGB(110, 72, 44),
		Enum.Material.Ground
	)
	flowers(parent, base * CFrame.new(0, 0.95, 0))
end

local function trim(parent: Instance, frame: CFrame, run: { number }, colour: Color3)
	local a, b = Vector3.new(run[1], 0, run[2]), Vector3.new(run[3], 0, run[4])
	local mid = (a + b) / 2
	local strip = part(
		parent,
		"Trim",
		Vector3.new(0.15, 0.12, (b - a).Magnitude),
		frame * CFrame.new(mid.X, 0.62, mid.Z) * CFrame.lookAt(Vector3.zero, (b - a).Unit),
		colour,
		Enum.Material.Neon
	)
	strip.CastShadow = false
end

-- Gives the area's floor and frame parts a tier's look (tier 1: the look they were built with).
local function skin(area: Instance, spec: Spec, tier: number)
	local floorNames, frameNames = {}, {}
	for _, n in spec.floor do
		floorNames[n] = true
	end
	for _, n in spec.frame do
		frameNames[n] = true
	end
	local t = PondStages.Tiers[tier]
	for _, d in area:GetDescendants() do
		if d:IsA("BasePart") and (floorNames[d.Name] or frameNames[d.Name]) then
			if d:GetAttribute("BuiltColor") == nil then
				d:SetAttribute("BuiltColor", d.Color)
				d:SetAttribute("BuiltMaterial", d.Material.Name)
			end
			if tier <= 1 then
				d.Color = d:GetAttribute("BuiltColor") :: Color3
				d.Material = (Enum.Material :: any)[d:GetAttribute("BuiltMaterial")]
			elseif floorNames[d.Name] then
				d.Color = t.planks[1]
				PondStages.studLook(d, t.deck)
			else
				d.Color = t.frame
				PondStages.studLook(d, t.frameMat)
			end
		end
	end
end

-- Puts an area at a level: skins its floor and frame, and returns the layer of added parts (the
-- caller parents it to the area and destroys the previous one).
function AreaStages.build(areaName: string, area: Instance, frame: CFrame, level: number): Model
	local spec = AreaStages.Specs[areaName]
	local at = PondStages.parts(level)
	local tiers = PondStages.Tiers
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)
	skin(area, spec, at[1])
	if at[2] > 0 then
		for _, r in (spec.rails or {}) :: { { number } } do
			rail(m, frame, r, tiers[at[2]])
		end
		for _, b in (spec.benches or {}) :: { { number } } do
			bench(m, frame, b, tiers[at[2]])
		end
	end
	if at[3] > 0 then
		for _, l in spec.lamps do
			lamp(m, frame, l, tiers[at[3]])
		end
	end
	if at[4] > 0 then
		crate(m, frame, spec.crate, tiers[at[4]])
	end
	if at[5] > 0 then
		for _, p in spec.planters do
			planter(m, frame, p, tiers[at[5]])
		end
		local glow = tiers[at[5]].trim
		if glow then
			for _, r in spec.trim do
				trim(m, frame, r, glow)
			end
		end
	end
	return m
end

return AreaStages
