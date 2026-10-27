--!strict
-- The pantry's 50 levels (the owner, 2026-10-27: the store house itself must grow, and what is added
-- must belong to a store: things to keep goods in, things to move them, more floors). Five eras of
-- ten levels; in each era:
--   level 1 of the era   the building grows: era 2 a second floor, era 3 a loading canopy over the
--                        door, era 4 a third floor, era 5 a rooftop lantern tower
--   levels 2-5           four store props, one a level, each slot taking its next, better version:
--                        1 transport (wheelbarrow > hand cart > pallet jack > forklift > hover cart)
--                        2 containers (barrel rack > crate wall > grain silo > shipping container >
--                        goo tank)   3 lifting (ladder > pulley hoist > crane > conveyor > robot arm)
--                        4 stock (sack pallet > shelf > metal rack > plastic crates > vault)
--   levels 6-10          the building's materials move up one tier, one part a level: walls, roof,
--                        doors and windows, frame and foundation, the yard's floor
-- Tiers: rustic wood, painted timber, brick, steel and glass, slime tech, marble and gold.
-- The house is built from parts so its materials and floors can change; props are kit models
-- (ServerStorage PropKit / Kit.PropKit). Positions are in the pantry's own frame, y up from the ground.
local ServerStorage = game:GetService("ServerStorage")

local PantryStages = {}

PantryStages.MaxLevel = 50

type Tier = {
	name: string,
	walls: Color3,
	wallMat: Enum.Material,
	base: Color3,
	baseMat: Enum.Material,
	roof: Color3,
	roofMat: Enum.Material,
	frame: Color3,
	frameMat: Enum.Material,
	trim: Color3,
	trimMat: Enum.Material,
	glass: Color3,
	yard: Color3,
	yardMat: Enum.Material,
	edge: Color3,
}

local TIERS: { Tier } = {
	{
		name = "Rustic wood",
		walls = Color3.fromRGB(205, 146, 82),
		wallMat = Enum.Material.WoodPlanks,
		base = Color3.fromRGB(160, 156, 148),
		baseMat = Enum.Material.Slate,
		roof = Color3.fromRGB(196, 96, 64),
		roofMat = Enum.Material.WoodPlanks,
		frame = Color3.fromRGB(120, 78, 44),
		frameMat = Enum.Material.Wood,
		trim = Color3.fromRGB(245, 236, 214),
		trimMat = Enum.Material.Wood,
		glass = Color3.fromRGB(255, 226, 150),
		yard = Color3.fromRGB(178, 172, 160),
		yardMat = Enum.Material.Plastic,
		edge = Color3.fromRGB(140, 134, 124),
	},
	{
		name = "Painted timber",
		walls = Color3.fromRGB(240, 234, 220),
		wallMat = Enum.Material.WoodPlanks,
		base = Color3.fromRGB(150, 148, 144),
		baseMat = Enum.Material.Cobblestone,
		roof = Color3.fromRGB(80, 110, 150),
		roofMat = Enum.Material.Slate,
		frame = Color3.fromRGB(70, 100, 140),
		frameMat = Enum.Material.WoodPlanks,
		trim = Color3.fromRGB(255, 255, 255),
		trimMat = Enum.Material.SmoothPlastic,
		glass = Color3.fromRGB(255, 232, 170),
		yard = Color3.fromRGB(196, 170, 130),
		yardMat = Enum.Material.WoodPlanks,
		edge = Color3.fromRGB(70, 100, 140),
	},
	{
		name = "Brick",
		walls = Color3.fromRGB(176, 88, 66),
		wallMat = Enum.Material.Brick,
		base = Color3.fromRGB(110, 106, 100),
		baseMat = Enum.Material.Slate,
		roof = Color3.fromRGB(70, 74, 82),
		roofMat = Enum.Material.Slate,
		frame = Color3.fromRGB(230, 220, 200),
		frameMat = Enum.Material.Concrete,
		trim = Color3.fromRGB(236, 228, 210),
		trimMat = Enum.Material.SmoothPlastic,
		glass = Color3.fromRGB(255, 220, 150),
		yard = Color3.fromRGB(160, 96, 74),
		yardMat = Enum.Material.Brick,
		edge = Color3.fromRGB(110, 106, 100),
	},
	{
		name = "Steel and glass",
		walls = Color3.fromRGB(200, 206, 212),
		wallMat = Enum.Material.Metal,
		base = Color3.fromRGB(150, 152, 156),
		baseMat = Enum.Material.Concrete,
		roof = Color3.fromRGB(70, 76, 86),
		roofMat = Enum.Material.DiamondPlate,
		frame = Color3.fromRGB(60, 64, 72),
		frameMat = Enum.Material.Metal,
		trim = Color3.fromRGB(120, 200, 240),
		trimMat = Enum.Material.Glass,
		glass = Color3.fromRGB(170, 225, 255),
		yard = Color3.fromRGB(176, 178, 182),
		yardMat = Enum.Material.Concrete,
		edge = Color3.fromRGB(255, 200, 60),
	},
	{
		name = "Slime tech",
		walls = Color3.fromRGB(70, 150, 150),
		wallMat = Enum.Material.SmoothPlastic,
		base = Color3.fromRGB(30, 60, 66),
		baseMat = Enum.Material.Metal,
		roof = Color3.fromRGB(34, 74, 80),
		roofMat = Enum.Material.Metal,
		frame = Color3.fromRGB(26, 50, 56),
		frameMat = Enum.Material.Metal,
		trim = Color3.fromRGB(120, 255, 150),
		trimMat = Enum.Material.Neon,
		glass = Color3.fromRGB(150, 255, 190),
		yard = Color3.fromRGB(40, 90, 96),
		yardMat = Enum.Material.DiamondPlate,
		edge = Color3.fromRGB(120, 255, 150),
	},
	{
		name = "Marble and gold",
		walls = Color3.fromRGB(246, 243, 236),
		wallMat = Enum.Material.Marble,
		base = Color3.fromRGB(200, 196, 188),
		baseMat = Enum.Material.Marble,
		roof = Color3.fromRGB(46, 70, 130),
		roofMat = Enum.Material.Slate,
		frame = Color3.fromRGB(232, 190, 80),
		frameMat = Enum.Material.Foil,
		trim = Color3.fromRGB(232, 190, 80),
		trimMat = Enum.Material.Foil,
		glass = Color3.fromRGB(255, 230, 160),
		yard = Color3.fromRGB(240, 236, 228),
		yardMat = Enum.Material.Marble,
		edge = Color3.fromRGB(232, 190, 80),
	},
}
PantryStages.Tiers = TIERS

-- The store props: slot -> era -> kit model. Every model is scaled to its REAL height in studs, the
-- same scale as the player (5 studs = 1.75 m) and the store's door (4.3), so a wheelbarrow is waist
-- high and a forklift taller than a player (the owner: the props must be in proportion). Big props
-- (containers, transport) stand in the open front corners of the yard; slim ones (lifting, stock)
-- beside the house. A slot's width cap only keeps a model inside the yard.
local PROPS = {
	{ "Wheelbarrow", "HandCart", "PalletJack", "Forklift", "HoverCart" }, -- transport
	{ "BarrelRack", "CrateWall", "GrainSilo", "ShippingContainer", "GooTank" }, -- containers
	{ "Ladder", "PulleyHoist", "StoreCrane", "Conveyor", "RobotArm" }, -- lifting
	{ "SackPallet", "StoreShelf", "MetalRack", "PlasticCrates", "Vault" }, -- stock
}
local SLOT_AT = { { 8, -5.6 }, { -7.6, -5.6 }, { 9.2, 4.2 }, { -9.2, 4.2 } }
-- real heights (studs): 0.75 m wheelbarrow, 1 m cart, 1.1 m pallet jack (handle), 1.9 m forklift,
-- 0.85 m hover cart; 1.25 m barrel rack, 1.5 m crate wall, 2.1 m silo, 1.4 m mini container, 2.1 m
-- goo tank; 2.1 m ladder, 1.8 m hoist, 2.1 m yard crane, 1.05 m conveyor, 1.9 m robot arm; 1.05 m
-- sack pallet, 1.75 m shelf, 2.1 m rack, 1.2 m crate stack, 1.25 m vault
local HEIGHT = {
	{ 2.2, 3, 3.2, 5.5, 2.4 },
	{ 3.6, 4.4, 6, 4, 6 },
	{ 6, 5.2, 6, 3, 5.5 },
	{ 3, 5, 6, 3.4, 3.6 },
}
local FOOT = { 9, 9, 5.6, 5.6 } -- the widest a slot's model may be (the room it has)

-- the house: 12 wide (x), 9 deep (z from 0 to 9), its door to the front (-z)
local W, D, Z0 = 12, 9, 0
local H1, H2 = 6, 4.6 -- ground storey, upper storeys
local BASE = 0.8

local function kit(name: string): Instance?
	local direct = ServerStorage:FindFirstChild(name)
	if direct then
		return direct
	end
	local bundle = ServerStorage:FindFirstChild("Kit")
	return bundle and bundle:FindFirstChild(name)
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	colour: Color3,
	material: Enum.Material?
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = size.Magnitude > 4
	p.Parent = parent
	return p
end

local function wedge(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = colour
	w.Material = material
	w.Anchored = true
	w.Parent = parent
end

local function place(parent: Instance, frame: CFrame, key: string, x: number, z: number, height: number, foot: number)
	local src: Instance? = nil
	for _, name in { "PropKit", "OwnerKit" } do
		local k = kit(name)
		if not src and k then
			src = k:FindFirstChild(key)
		end
	end
	if not src or not src:IsA("Model") then
		return
	end
	local m = src:Clone() :: Model
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d:IsA("MeshPart") then
				d.DoubleSided = true
			end
		end
	end
	local _, s0 = m:GetBoundingBox()
	-- its real height; narrower only if it would not fit its corner
	m:ScaleTo(m:GetScale() * math.min(height / s0.Y, foot / math.max(s0.X, s0.Z)))
	local box, size = m:GetBoundingBox()
	local target = (frame * CFrame.new(x, size.Y / 2, z)).Position
	m:PivotTo(m:GetPivot() + (target - box.Position))
	m.Name = key
	m.Parent = parent
end

-- What a level holds: storeys, canopy, rooftop, each prop slot's era (0: none), each building part's
-- tier (walls, roof, openings, frame, yard).
function PantryStages.state(level: number): (number, boolean, boolean, { number }, { number })
	local era = math.clamp(math.ceil(level / 10), 1, 5)
	local s = level - (era - 1) * 10
	local storeys = 1 + (if level >= 11 then 1 else 0) + (if level >= 31 then 1 else 0)
	local props = {}
	for j = 1, 4 do
		props[j] = if s >= j + 1 then era else era - 1
	end
	local tiers = {}
	for k = 1, 5 do
		tiers[k] = if s >= k + 5 then era + 1 else era
	end
	return storeys, level >= 21, level >= 41, props, tiers
end

function PantryStages.tierName(level: number): string
	local _, _, _, _, tiers = PantryStages.state(level)
	return TIERS[tiers[1]].name
end

-- The pantry's layer for one level (the house, its props) in the area's `frame` (y = ground's top).
-- `area` is the pantry model: its yard floor takes the yard tier, its old kit shed is hidden.
function PantryStages.build(area: Instance, frame: CFrame, level: number): Model
	local storeys, canopy, rooftop, props, tiers = PantryStages.state(level)
	local tw, tr, to, tf, ty = TIERS[tiers[1]], TIERS[tiers[2]], TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)

	-- the yard: the area's own floor and edging take the yard tier
	for _, d in area:GetChildren() do
		-- the old kit shed, barrels and crates: the house and the store props stand in for them
		if (d.Name == "StorageShed" or d.Name == "WoodBarrel" or d.Name == "CrateStack") and d:IsA("Model") then
			d.Parent = nil
		elseif d.Name == "Floor" and d:IsA("BasePart") then
			d.Color = ty.yard
			d.Material = ty.yardMat
		elseif d.Name == "FloorEdge" and d:IsA("BasePart") then
			d.Color = ty.edge
			d.Material = if tiers[5] >= 4 then Enum.Material.SmoothPlastic else ty.yardMat
		end
	end

	local zc = Z0 + D / 2
	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	-- foundation
	part(m, "Foundation", Vector3.new(W + 0.8, BASE, D + 0.8), at(0, BASE / 2, zc), tf.base, tf.baseMat)
	-- storeys
	local top = BASE
	for k = 1, storeys do
		local h = if k == 1 then H1 else H2
		local y = top + h / 2
		part(m, "WallFront", Vector3.new(W, h, 0.6), at(0, y, Z0 + 0.3), tw.walls, tw.wallMat)
		part(m, "WallBack", Vector3.new(W, h, 0.6), at(0, y, Z0 + D - 0.3), tw.walls, tw.wallMat)
		for _, s in { -1, 1 } do
			part(m, "WallSide", Vector3.new(0.6, h, D - 1.2), at(s * (W / 2 - 0.3), y, zc), tw.walls, tw.wallMat)
			-- corner posts
			for _, cz in { Z0 + 0.3, Z0 + D - 0.3 } do
				part(m, "CornerPost", Vector3.new(0.9, h, 0.9), at(s * (W / 2 - 0.3), y, cz), tf.frame, tf.frameMat)
			end
		end
		-- the band between storeys
		part(m, "Band", Vector3.new(W + 0.4, 0.4, D + 0.4), at(0, top + h, zc), tf.frame, tf.frameMat)
		-- windows: either side of the door on the ground storey, three on the upper ones, one each side
		local wy = top + h * 0.55
		local xs: { number } = if k == 1 then { -4, 4 } else { -3.2, 0, 3.2 }
		for _, wx in xs do
			part(m, "WindowFrame", Vector3.new(1.9, 1.9, 0.3), at(wx, wy, Z0 - 0.05), to.trim, to.trimMat)
			local glass =
				part(m, "Window", Vector3.new(1.4, 1.4, 0.32), at(wx, wy, Z0 - 0.06), to.glass, Enum.Material.Neon)
			glass.CastShadow = false
		end
		for _, s in { -1, 1 } do
			part(m, "WindowFrame", Vector3.new(0.3, 1.9, 1.9), at(s * (W / 2 + 0.05), wy, zc), to.trim, to.trimMat)
			part(m, "Window", Vector3.new(0.32, 1.4, 1.4), at(s * (W / 2 + 0.06), wy, zc), to.glass, Enum.Material.Neon).CastShadow =
				false
		end
		top += h + 0.4
	end
	-- the double door and its lintel
	part(m, "DoorFrame", Vector3.new(3.8, 4.8, 0.3), at(0, BASE + 2.4, Z0 - 0.05), to.trim, to.trimMat)
	for _, s in { -1, 1 } do
		part(m, "Door", Vector3.new(1.55, 4.3, 0.35), at(s * 0.8, BASE + 2.15, Z0 - 0.1), tf.frame, tf.frameMat)
	end
	part(m, "Step", Vector3.new(4.4, 0.4, 1.4), at(0, 0.2, Z0 - 0.9), tf.base, tf.baseMat)
	-- the gable roof, ridge along x
	local rh = 3.2
	wedge(
		m,
		"RoofFront",
		Vector3.new(W + 1.2, rh, D / 2 + 0.6),
		at(0, top + rh / 2, Z0 + D / 4 - 0.3),
		tr.roof,
		tr.roofMat
	)
	wedge(
		m,
		"RoofBack",
		Vector3.new(W + 1.2, rh, D / 2 + 0.6),
		at(0, top + rh / 2, Z0 + D * 3 / 4 + 0.3) * CFrame.Angles(0, math.pi, 0),
		tr.roof,
		tr.roofMat
	)
	part(m, "Ridge", Vector3.new(W + 1.4, 0.4, 0.6), at(0, top + rh + 0.1, zc), tf.frame, tf.frameMat)
	for _, s in { -1, 1 } do
		-- the gable ends, filled with the wall material
		wedge(
			m,
			"Gable",
			Vector3.new(0.5, rh, D / 2),
			at(s * (W / 2 - 0.25), top + rh / 2, Z0 + D / 4),
			tw.walls,
			tw.wallMat
		)
		wedge(
			m,
			"Gable",
			Vector3.new(0.5, rh, D / 2),
			at(s * (W / 2 - 0.25), top + rh / 2, Z0 + D * 3 / 4) * CFrame.Angles(0, math.pi, 0),
			tw.walls,
			tw.wallMat
		)
	end
	-- a lantern by the door
	local lamp =
		part(m, "Lantern", Vector3.new(0.7, 0.9, 0.7), at(2.6, BASE + 4.2, Z0 - 0.6), to.glass, Enum.Material.Neon)
	lamp.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = to.glass
	light.Range = 10
	light.Brightness = 0.8
	light.Parent = lamp

	-- era 3: a loading canopy over the door, on two posts
	if canopy then
		for _, s in { -1, 1 } do
			part(m, "CanopyPost", Vector3.new(0.5, 4.8, 0.5), at(s * 3, 2.4 + BASE, Z0 - 3.4), tf.frame, tf.frameMat)
		end
		local cw = Instance.new("WedgePart")
		cw.Name = "Canopy"
		cw.Size = Vector3.new(7.6, 0.9, 3.8)
		cw.CFrame = at(0, BASE + 5.25, Z0 - 1.8)
		cw.Color = tr.roof
		cw.Material = tr.roofMat
		cw.Anchored = true
		cw.Parent = m
	end
	-- era 5: a lantern tower on the ridge
	if rooftop then
		local ry = top + rh
		part(m, "TowerBase", Vector3.new(2.6, 2.4, 2.6), at(0, ry + 1, zc), tw.walls, tw.wallMat)
		part(m, "TowerGlass", Vector3.new(2, 1.4, 2), at(0, ry + 2.9, zc), to.glass, Enum.Material.Neon).CastShadow =
			false
		for _, s in { -1, 1 } do
			wedge(
				m,
				"TowerRoof",
				Vector3.new(3, 1.4, 1.5),
				at(0, ry + 4.3, zc + s * -0.75) * CFrame.Angles(0, if s == 1 then 0 else math.pi, 0),
				tr.roof,
				tr.roofMat
			)
		end
		part(m, "Flag", Vector3.new(0.15, 1.6, 0.15), at(0, ry + 5.8, zc), tf.frame, tf.frameMat)
	end

	-- the store props
	for j = 1, 4 do
		local era = props[j]
		if era > 0 then
			place(m, frame, PROPS[j][era], SLOT_AT[j][1], SLOT_AT[j][2], HEIGHT[j][era], FOOT[j])
		end
	end
	return m
end

return PantryStages
