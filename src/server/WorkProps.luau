--!strict
-- Things the work places need, built from parts in the owner's palette (honey wood, royal blue, cream, gold):
-- the fishing rod, the hoe, a stand for a rod, and the bins that hold ten fish or vegetables (docs/GAMEPLAY.md
-- §10). The rod and the hoe are also the tools of the animations: tools/kit/make_tools.luau builds them from here
-- into the work place's PropKit, and tools/kit/export_client_kit.luau puts them in ReplicatedStorage.ClientKit.Items.
-- Tool models stand upright with their pivot at the foot of the handle.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorkProps = {}

local HONEY = Color3.fromRGB(214, 150, 70)
local WOOD = Color3.fromRGB(150, 98, 52)
local CREAM = Color3.fromRGB(250, 240, 214)
local BLUE = Color3.fromRGB(52, 96, 190)
local GOLD = Color3.fromRGB(240, 190, 70)
local STEEL = Color3.fromRGB(168, 176, 188)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- an upright cylinder from `cf` (its middle) up
local function rod(parent: Instance, name: string, cf: CFrame, length: number, diameter: number, colour: Color3)
	local p =
		part(parent, name, Vector3.new(length, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ball(parent: Instance, name: string, cf: CFrame, diameter: number, colour: Color3)
	local p = part(parent, name, Vector3.one * diameter, cf, colour)
	p.Shape = Enum.PartType.Ball
	return p
end

-- A fishing rod: cork handle with a red grip band, a gold reel, a honey pole that bends forward (-Z) in
-- four segments, a line from the tip to a red and white bobber. About 5.4 studs tall, pivot at the handle's foot.
function WorkProps.fishingRod(): Model
	local m = Instance.new("Model")
	m.Name = "FishingRod"
	rod(m, "Handle", CFrame.new(0, 0.6, 0), 1.2, 0.3, Color3.fromRGB(224, 184, 130))
	rod(m, "Foot", CFrame.new(0, 0.06, 0), 0.12, 0.38, WOOD)
	rod(m, "Grip", CFrame.new(0, 1.15, 0), 0.22, 0.36, Color3.fromRGB(214, 70, 60))
	-- the reel on the handle's side
	local reel = part(m, "Reel", Vector3.new(0.16, 0.5, 0.5), CFrame.new(0.34, 0.8, 0), GOLD)
	reel.Shape = Enum.PartType.Cylinder
	part(m, "ReelBar", Vector3.new(0.3, 0.1, 0.1), CFrame.new(0.15, 0.8, 0), WOOD)
	part(m, "ReelCrank", Vector3.new(0.08, 0.08, 0.3), CFrame.new(0.46, 0.8, 0.14), STEEL)
	-- the pole: each segment a little thinner and leaning a little more
	local at = CFrame.new(0, 1.2, 0)
	local top = at
	for i = 1, 4 do
		local len = 1.0
		local d = 0.24 - i * 0.04
		at = at * CFrame.Angles(math.rad(-4 - i), 0, 0)
		rod(m, "Pole" .. i, at * CFrame.new(0, len / 2, 0), len, d, if i % 2 == 0 then HONEY else WOOD)
		at = at * CFrame.new(0, len, 0)
		top = at
	end
	ball(m, "Tip", top, 0.16, GOLD)
	-- the line hangs from the tip to the bobber
	rod(m, "Line", top * CFrame.new(0, -0.9, 0) * CFrame.Angles(math.rad(-4), 0, 0), 1.8, 0.04, CREAM)
	local bob = top * CFrame.new(0, -1.9, -0.08)
	ball(m, "BobberBottom", bob, 0.4, CREAM)
	local topHalf = ball(m, "BobberTop", bob * CFrame.new(0, 0.12, 0), 0.34, Color3.fromRGB(226, 66, 56))
	topHalf.Size = Vector3.new(0.34, 0.26, 0.34)
	m.WorldPivot = CFrame.new() -- (the foot, upright: the parts' own turns would tip a part's pivot)
	return m
end

-- A hoe: a long honey handle with a rounded end, an iron collar and a steel blade bent forward (-Z).
-- About 4.4 studs tall, pivot at the handle's foot.
function WorkProps.hoe(): Model
	local m = Instance.new("Model")
	m.Name = "Hoe"
	rod(m, "Handle", CFrame.new(0, 2.1, 0), 4.2, 0.26, HONEY)
	ball(m, "HandleEnd", CFrame.new(0, 0.15, 0), 0.3, WOOD)
	rod(m, "Grip", CFrame.new(0, 3.5, 0), 0.5, 0.32, WOOD)
	rod(m, "Collar", CFrame.new(0, 4.15, 0), 0.3, 0.36, STEEL)
	-- the neck bends forward and the blade hangs across it
	part(m, "Neck", Vector3.new(0.18, 0.18, 0.8), CFrame.new(0, 4.3, -0.35) * CFrame.Angles(math.rad(20), 0, 0), STEEL)
	part(m, "Blade", Vector3.new(0.9, 0.7, 0.12), CFrame.new(0, 4.0, -0.82) * CFrame.Angles(math.rad(-12), 0, 0), STEEL)
	part(m, "BladeEdge", Vector3.new(0.9, 0.12, 0.16), CFrame.new(0, 3.66, -0.84), Color3.fromRGB(210, 216, 226))
	m.WorldPivot = CFrame.new()
	return m
end

-- A little wooden stand a rod leans in: two posts with a crossbar, the rod resting in its fork.
-- `cf` is on the ground in front of the stand's middle; the rod leans toward its -Z.
function WorkProps.rodStand(parent: Instance, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "RodStand"
	part(m, "StandFoot", Vector3.new(1.3, 0.2, 1.1), cf * CFrame.new(0, 0.1, 0), WOOD, Enum.Material.Wood)
	for _, s in { -1, 1 } do
		part(m, "StandPost", Vector3.new(0.22, 1.9, 0.22), cf * CFrame.new(s * 0.5, 1.05, 0), HONEY, Enum.Material.Wood)
		part(m, "StandCap", Vector3.new(0.3, 0.12, 0.3), cf * CFrame.new(s * 0.5, 2.05, 0), GOLD)
	end
	part(m, "StandBar", Vector3.new(1.2, 0.18, 0.18), cf * CFrame.new(0, 1.4, 0.08), WOOD, Enum.Material.Wood)
	local r = WorkProps.fishingRod()
	r:PivotTo(cf * CFrame.new(0, 0.2, 0.3) * CFrame.Angles(math.rad(-14), 0, 0))
	r.Parent = m
	m.Parent = parent
	return m
end

-- A bin of eight staves (`a` and `b` alternate), a gold band and a base; open on top. Named `name` ("FishBin" or
-- "VegBin": the village brain finds the spot by that name), pivot on the ground at its middle. Carries the
-- attributes Area and Capacity and the tag "ItemBin"; its invisible part "BinFill" is the floor the client lays
-- the visible fish or vegetables on (src/client/Bins.client.luau).
function WorkProps.bin(
	parent: Instance,
	cf: CFrame,
	name: string,
	area: string,
	a: Color3,
	b: Color3,
	filler: Color3
): Model
	local m = Instance.new("Model")
	m.Name = name
	local apothem, height = 1.45, 1.8
	local width = 2 * apothem * math.tan(math.pi / 8) + 0.06
	rod(m, "Base", cf * CFrame.new(0, 0.12, 0), 0.24, 3.0, WOOD).Material = Enum.Material.Wood
	for k = 0, 7 do
		local turn = cf * CFrame.Angles(0, k * math.pi / 4, 0)
		local staff = part(
			m,
			"Stave",
			Vector3.new(width, height, 0.22),
			turn * CFrame.new(0, 0.24 + height / 2, apothem),
			if k % 2 == 0 then a else b,
			Enum.Material.WoodPlanks
		)
		staff.CFrame = staff.CFrame * CFrame.Angles(math.rad(-4), 0, 0)
		part(m, "Band", Vector3.new(width + 0.04, 0.2, 0.1), turn * CFrame.new(0, 0.9, apothem + 0.15), GOLD)
		part(
			m,
			"Rim",
			Vector3.new(width + 0.06, 0.12, 0.34),
			turn * CFrame.new(0, 0.24 + height, apothem + 0.02),
			CREAM
		)
	end
	for _, s in { -1, 1 } do
		part(m, "Handle", Vector3.new(0.34, 0.14, 0.14), cf * CFrame.new(s * (apothem + 0.3), 1.65, 0), GOLD)
	end
	-- a bed of ice or straw half way up, so the catch lies near the rim and shows from outside
	local bed = rod(m, "Bed", cf * CFrame.new(0, 1.0, 0), 0.12, 2.7, filler)
	bed.Material = Enum.Material.Fabric
	local fill = part(m, "BinFill", Vector3.new(2.2, 0.2, 2.2), cf * CFrame.new(0, 1.16, 0), WOOD)
	fill.Transparency = 1
	m.WorldPivot = cf
	-- A bin is solid: slimes and players walk round it, never through it (the owner, 2026-10-29).
	for _, piece in m:GetChildren() do
		if piece:IsA("BasePart") and (piece.Name == "Base" or piece.Name == "Stave") then
			piece.CanCollide = true
			piece.CanQuery = true
		end
	end
	m:SetAttribute("Area", area)
	m:SetAttribute("Capacity", Config.WorkPlaces.BinCapacity)
	CollectionService:AddTag(m, "ItemBin")
	m.Parent = parent
	return m
end

WorkProps.Colours = { honey = HONEY, wood = WOOD, cream = CREAM, blue = BLUE, gold = GOLD }

return WorkProps
