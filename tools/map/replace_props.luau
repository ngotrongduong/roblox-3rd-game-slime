-- Swaps the part-built props of a home plot's areas for low-poly models of the prop kit (the owner,
-- 2026-10-27: "redesign every prop as beautiful and detailed as the crops, low poly"). Kit models are
-- made with generate_mesh and kept in the work place's ServerStorage.PropKit (pivot at the foot,
-- front toward -Z; generate_mesh hands its mesh back turned by some angle, so each kit model's mesh
-- part is set square, CFrame.new(position), when it goes into the kit). Each prop of an area is found as a group of parts around a seed part; the kit
-- model takes the group's place: standing on the same ground, centred on it, as tall as the group
-- was (its footprint capped by the group's), facing the area's front. Parts that carry gameplay
-- attachments (work spots, nests, incubators) stay as invisible markers. Floors, fences, paths and
-- the area signs (their icons are UI) stay as they are. Run in Edit mode through MCP after the area
-- builders and before polish_plot. Rerunnable after a rebuild of the areas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local plot = workspace.Map["Plot" .. PLOT]
local kit = ServerStorage:FindFirstChild("PropKit")
local AREAS = {
	FishingPondL1 = { -1, 1 },
	GardenL1 = { 1, 1 },
	KitchenL1 = { -1, 0 },
	PantryL1 = { 0, 1 },
	BreedingL1 = { 1, 0 },
	TrainingL1 = { -1, -1 },
}

-- area, kit model, seed part, the parts of the group, how far from the seed they may be, extra turn
-- (degrees) when the model's front is not its -Z, which parts stay as invisible markers, `all` to
-- swap every such group (else one), `light` to keep a lamp's light. "Village" is the plot's own
-- frame (build_village); kit models come from PropKit, else the owner's OwnerKit.
type Swap = {
	area: string,
	kit: string,
	seed: string,
	parts: { string },
	radius: number,
	turn: number?,
	keep: { string }?,
	all: boolean?,
	light: boolean?,
	grow: number?,
	tall: boolean?, -- fitted by height alone (tall, thin things such as lamp posts)
}
local SWAPS: { Swap } = {
	{
		area = "Village",
		kit = "StoneWell",
		seed = "WellBeam",
		parts = { "WellStone", "WellWater", "WellPost", "WellBeam", "WellRoof", "WellRope", "WellBucket" },
		radius = 6,
	},
	{ area = "Village", kit = "Planter", seed = "Planter", parts = { "Planter", "PlanterFlower" }, radius = 1.6, all = true },
	{ area = "Village", kit = "VillageLamp", seed = "LampPost", parts = { "LampPost", "Lamp", "LampCap" }, radius = 5, all = true, light = true, tall = true },
	{ area = "FishingPondL1", kit = "VillageLamp", seed = "LanternPost", parts = { "LanternPost", "Arm", "Lantern", "LanternCap" }, radius = 5, light = true, tall = true },
	{ area = "FishingPondL1", kit = "FishBucket", seed = "Bucket", parts = { "Bucket", "Catch" }, radius = 3 },
	{ area = "GardenL1", kit = "WateringCan", seed = "CanBody", parts = { "CanBody", "CanSpout" }, radius = 3 },
	{ area = "GardenL1", kit = "WoodBarrel", seed = "Barrel", parts = { "Barrel", "BarrelHoop", "BarrelWater" }, radius = 3 },
	{
		area = "KitchenL1",
		kit = "Stove",
		seed = "StoveBase",
		parts = { "StoveBase", "StoveTop", "Mouth", "Fire", "Chimney", "ChimneyCap", "Pot", "PotRim", "Soup", "Ladle" },
		radius = 9,
		keep = { "ChimneyCap" }, -- (its smoke)
	},
	{
		area = "KitchenL1",
		kit = "KitchenCounter",
		seed = "CounterBody",
		parts = { "CounterBody", "CounterTop", "Shelf", "Board", "Bowl", "Fish", "FishTail", "Carrot", "Cabbage" },
		radius = 5,
	},
	{ area = "KitchenL1", kit = "FirewoodPile", seed = "Firewood", parts = { "Firewood" }, radius = 4 },
	{
		area = "PantryL1",
		kit = "StorageShed",
		seed = "Walls",
		parts = { "Walls", "Gable", "RoofFront", "RoofBack", "Ridge", "CornerPost", "Door", "DoorRing", "DoorSplit", "Lintel", "Step", "Window", "WindowFrame", "Lantern", "LanternArm" },
		radius = 10,
	},
	{ area = "PantryL1", kit = "CrateStack", seed = "Crate", parts = { "Crate", "CrateBand", "Produce" }, radius = 5 },
	{ area = "PantryL1", kit = "WoodBarrel", seed = "Barrel", parts = { "Barrel", "Hoop", "BarrelLid" }, radius = 2 },
	{ area = "PantryL1", kit = "WoodBarrel", seed = "Barrel", parts = { "Barrel", "Hoop", "BarrelLid" }, radius = 2 },
	{
		area = "BreedingL1",
		kit = "Cottage",
		seed = "Walls",
		parts = { "Walls", "Roof", "RoofTip", "RoofHeart", "Door", "DoorArch", "DoorHeart", "DoorKnob", "Window", "WindowFrame", "Base", "Band", "Step" },
		radius = 14, -- (the heart on the roof is high above the walls)
	},
	{
		area = "BreedingL1",
		kit = "Incubator",
		seed = "IncBase",
		parts = { "IncBase", "IncTrim", "IncBed1", "IncBed2", "IncDome", "IncLamp", "IncCap", "Gauge", "GaugeNeedle", "GaugeRim", "Button" },
		radius = 3.5,
		keep = { "IncBed1", "IncBed2" },
	},
	{
		area = "BreedingL1",
		kit = "Incubator",
		seed = "IncBase",
		parts = { "IncBase", "IncTrim", "IncBed1", "IncBed2", "IncDome", "IncLamp", "IncCap", "Gauge", "GaugeNeedle", "GaugeRim", "Button" },
		radius = 3.5,
		keep = { "IncBed1", "IncBed2" },
	},
	{ area = "BreedingL1", kit = "BirdNest", seed = "NestLining", parts = { "NestLining", "NestTwig", "NestHollow1", "NestHollow2" }, radius = 3.6, keep = { "NestHollow1", "NestHollow2" } },
	{ area = "BreedingL1", kit = "BirdNest", seed = "NestLining", parts = { "NestLining", "NestTwig", "NestHollow1", "NestHollow2" }, radius = 3.6, keep = { "NestHollow1", "NestHollow2" } },
	{ area = "BreedingL1", kit = "FlowerPot", seed = "FlowerPot", parts = { "FlowerPot", "PotFlower" }, radius = 1.5 },
	{ area = "BreedingL1", kit = "FlowerPot", seed = "FlowerPot", parts = { "FlowerPot", "PotFlower" }, radius = 1.5 },
	{ area = "BreedingL1", kit = "WaterTrough", seed = "Trough", parts = { "Trough", "TroughWater" }, radius = 3, grow = 1.4 }, -- (a chunky model: fitted by height it came out short)
	{ area = "BreedingL1", kit = "HayBale", seed = "HayBale", parts = { "HayBale", "HayBand" }, radius = 2 },
	{ area = "TrainingL1", kit = "TrainingDummy", seed = "Dummy", parts = { "Dummy" }, radius = 1 },
	{
		area = "TrainingL1",
		kit = "ArcheryTarget",
		seed = "TargetFace",
		parts = { "TargetFace", "TargetRing", "TargetLeg", "TargetBackLeg", "Arrow", "ArrowFletch" },
		radius = 4,
	},
	{
		area = "TrainingL1",
		kit = "WeaponRack",
		seed = "RackBar",
		parts = { "RackBar", "RackPost", "Shield", "ShieldBoss", "ShieldRim", "Staff", "StaffGem", "SwordBlade", "SwordGrip", "SwordGuard" },
		radius = 5,
	},
	{ area = "TrainingL1", kit = "BannerFlag", seed = "FlagPole", parts = { "Flag", "FlagBase", "FlagPole", "FlagStripe", "FlagTop" }, radius = 8, keep = { "FlagBase" } },
}

local function isPart(i: Instance): boolean
	return i:IsA("BasePart") or i:IsA("Model")
end

-- A part's or model's box in the area's frame: min and max corners.
local function boxIn(frame: CFrame, i: Instance): (Vector3, Vector3)
	local cf, size
	if i:IsA("Model") then
		cf, size = i:GetBoundingBox()
	else
		cf, size = (i :: BasePart).CFrame, (i :: BasePart).Size
	end
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local p = frame:PointToObjectSpace((cf * CFrame.new(size.X / 2 * sx, size.Y / 2 * sy, size.Z / 2 * sz)).Position)
				lo, hi = lo:Min(p), hi:Max(p)
			end
		end
	end
	return lo, hi
end

local function centre(i: Instance): Vector3
	return if i:IsA("Model") then i:GetPivot().Position else (i :: BasePart).Position
end


local ownerKit = ServerStorage:FindFirstChild("OwnerKit")
local done, missing = 0, {}

-- Swaps one group; false when no group of this kind is left in the area.
local function swapOne(s: Swap): boolean
	local area = plot:FindFirstChild(s.area)
	local src = (kit and kit:FindFirstChild(s.kit)) or (ownerKit and ownerKit:FindFirstChild(s.kit))
	if not area then
		return false
	end
	if not src then
		table.insert(missing, s.kit)
		return false
	end
	local seed: Instance? = nil
	for _, c in area:GetChildren() do
		if c.Name == s.seed and isPart(c) and not c:GetAttribute("Swapped") then
			seed = c
			break
		end
	end
	if not seed then
		return false
	end
	local cr = AREAS[s.area]
	local frame = if cr then Layout.plotAreaFacing(PLOT, cr[1], cr[2]) else Layout.plotFrame(PLOT)
	local wanted = {}
	for _, n in s.parts do
		wanted[n] = true
	end
	local keep = {}
	for _, n in s.keep or {} do
		keep[n] = true
	end
	local origin = centre(seed)
	local group = {}
	local light: Light? = nil
	for _, c in area:GetChildren() do
		if wanted[c.Name] and isPart(c) and not c:GetAttribute("Swapped") and (centre(c) - origin).Magnitude <= s.radius then
			table.insert(group, c)
			light = light or c:FindFirstChildWhichIsA("Light")
		end
	end
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, c in group do
		local a, b = boxIn(frame, c)
		lo, hi = lo:Min(a), hi:Max(b)
	end
	local size = hi - lo
	local m = src:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local _, ms = m:GetBoundingBox()
	local scale = if s.tall then size.Y / ms.Y else math.min(size.Y / ms.Y, math.max(size.X, size.Z) * 1.1 / math.max(ms.X, ms.Z))
	m:ScaleTo(m:GetScale() * scale * (s.grow or 1))
	local foot = frame * CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	m:PivotTo(foot * CFrame.Angles(0, math.rad(s.turn or 0), 0))
	m.Name = s.kit
	m:SetAttribute("Swapped", true)
	m.Parent = area
	-- a lamp keeps its light: on a small invisible part near the model's top
	if s.light then
		local glow = Instance.new("Part")
		glow.Name = "LampLight"
		glow.Size = Vector3.one * 0.5
		glow.Transparency = 1
		glow.Anchored = true
		glow.CanCollide = false
		glow.CanQuery = false
		glow.CanTouch = false
		local box, bs = m:GetBoundingBox()
		glow.CFrame = CFrame.new(box.Position + Vector3.new(0, bs.Y / 2 - 1.2, 0))
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 200, 120)
		l.Brightness = if light and light:IsA("PointLight") then light.Brightness else 1
		l.Range = if light and light:IsA("PointLight") then light.Range else 14
		l.Parent = glow
		glow.Parent = m
	end
	for _, c in group do
		if keep[c.Name] and c:IsA("BasePart") then
			c.Transparency = 1
			c.CanCollide = false
			c:SetAttribute("Swapped", true)
		else
			c:Destroy()
		end
	end
	done += 1
	return true
end

-- The round straw mats that mark the work spots (FishingSpot1, CookingSpot1, ...) stay as invisible
-- markers for their attachments, as the owner had the dock's taken out (2026-10-27).
for _, areaName in { "FishingPondL1", "GardenL1", "KitchenL1", "TrainingL1" } do
	local area = plot:FindFirstChild(areaName)
	for _, c in if area then area:GetChildren() else {} do
		if c:IsA("BasePart") and c.Name:match("Spot%d+$") then
			c.Transparency = 1
			c.CanCollide = false
			c.CastShadow = false
		end
	end
end

for _, s in SWAPS do
	if s.all then
		while swapOne(s) do
		end
	else
		swapOne(s)
	end
end
return "props swapped: " .. done .. (if #missing > 0 then " (missing in kit: " .. table.concat(missing, ", ") .. ")" else "")
