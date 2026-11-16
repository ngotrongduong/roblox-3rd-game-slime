--!strict
-- The pantry's 50 levels (the owner, 2026-10-27: the store house itself must grow, and what is added
-- must belong to a store: things to keep goods in, things to move them, more floors). Five eras of
-- ten levels; in each era:
--   level 1 of the era   the building takes its next architecture (module `Granary`, village v2,
--                        2026-11-16: the great granary with its clock tower)
--   levels 2-5           four store props, one a level, each slot taking its next, better version:
--                        1 transport (wheelbarrow > hand cart > pallet jack > forklift > hover cart)
--                        2 containers (barrel rack > crate wall > grain silo > shipping container >
--                        goo tank)   3 lifting (ladder > pulley hoist > crane > conveyor > robot arm)
--                        4 stock (sack pallet > shelf > metal rack > plastic crates > vault)
--   levels 6-10          the granary gains one feature a level (silos, dormers, a belfry, turrets...);
--                        the yard's floor and the store hut still move up a material tier
-- Tiers: rustic wood, painted timber, brick, steel and glass, slime tech, marble and gold.
-- The granary is built from parts (`Granary`, `Architecture`); props are kit models
-- (ServerStorage PropKit / Kit.PropKit). Positions are in the pantry's own frame, y up from the ground.
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Granary = require(script.Parent.Granary)
local LibraryKit = require(script.Parent.LibraryKit)
local PondStages = require(script.Parent.PondStages)

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

-- The store props, each placed for what it DOES (the owner, 2026-10-28: ask of every piece "does it
-- belong here, is this the right spot, what goes beside it"; inside the yard where it works there,
-- outside on the lawn only when it is too big or the yard is full; every one at its real size, the
-- player is 5 studs = 1.75 m). The yard runs x -12..12, z -10..10; the house x -6..6, z 0..9 with
-- its dock in front (z -3.4..0); its front corners (x 5..11, z -9..-4 each side) are the loading
-- area, its sides (x 6.5..11.5, z 0..9) narrow strips along the walls. From the silo's era the yard
-- grows a service yard on its right (x -26..-12) for the big things, and never shrinks again (the
-- owner, 2026-10-28: an area may grow with an upgrade, never get smaller).
--   transport  parked in the front-left loading corner, nose toward the dock
--   containers small ones against the right wall at the back; the big ones (silo 4.9 m, a short
--              container, the goo tank) in the service yard
--   lifting    a ladder against the left wall, then a jib hoist beside it, a crane truck parked in
--              front of the silo, a conveyor along the left wall, a robot arm by the dock
--   stock      goods waiting on pallets in the front-right corner, shelving and then the vault
--              against the right wall
local PROPS = {
	{ "Wheelbarrow", "HandCart", "PalletJack", "Forklift", "HoverCart" }, -- transport
	{ "BarrelRack", "CrateWall", "GrainSilo", "ShippingContainer", "GooTank" }, -- containers
	{ "Ladder", "PulleyHoist", "StoreCrane", "Conveyor", "RobotArm" }, -- lifting
	{ "SackPallet", "StoreShelf", "MetalRack", "PlasticCrates", "Vault" }, -- stock
}
-- slot -> era -> { x, z, turn (degrees: 90 faces -x, -90 faces +x, 180 faces the house), real
-- height, the widest it may be, "pallet" (stands on a wooden pallet) or "side" (its long side
-- front to back) }. The middle of the yard (x -3.5..3.5) stays a clear lane from the gate to the
-- door (ChatGPT's 5th review). (Left and right as one walks in: +x is the left.)
local SPOT: { { { any } } } = {
	{
		{ 8.5, -6.5, 60, 2.6, 3.2 }, -- 0.9 m wheelbarrow (handles at a grown-up's hands), at an angle
		{ 8.5, -6.5, 90, 3, 3 }, -- 1 m hand cart
		-- 2.4 m small forklift ("pallet jack"), twice the first try (the owner, 2026-10-28), forks
		-- toward the dock
		{ 7.2, -5.4, 90, 6.8, 7.2 }, -- (well clear of the hoist's post)
		{ 8.6, -6.6, 90, 6, 6.5 }, -- 2.1 m forklift, forks toward the dock
		{ 8.5, -7, 90, 2.6, 4 }, -- hover cart, floating (the owner: it has no weight)
	},
	{
		{ -9, 6.8, 90, 3.6, 4.5 }, -- 1.25 m barrel rack against the left wall
		{ -8.4, 7.2, 0, 3.4, 3.4 }, -- 1.2 m crates in a low stack against the wall, a walk beside them
		{ -20, 4.5, 0, 14, 8.5 }, -- 4.9 m grain silo at the back of the service yard
		-- 2.5 m short container, doors to the front, 7 clear before them and 3 clear of the hut
		{ -18, 3.4, 0, 7, 6, "side" },
		{ -19, 3, 0, 8.5, 6.5 }, -- 3 m goo tank in the service yard, piped to the house
	},
	{
		{ 7.2, 5.2, -90, 7, 2.5 }, -- 2.5 m ladder against the right wall
		-- (the jib hoist, twice as tall, at the yard's front-left corner, its arm over the cart, built
		-- from parts below so its crate truly hangs from the hook; the owner, 2026-10-28)
		{ 11.3, -9.3, 0, 10, 0, "built" },
		-- 4.2 m (boom up) crane truck across the front of the silo, 4 clear of it, its boom swung in
		-- over the paving so its load hangs well inside the yard
		{ -20.2, -6.2, -90, 12, 13 },
		{ 8.6, 6.4, 0, 3, 6 }, -- 1.05 m conveyor along the left wall, behind the forklift
		{ 9.6, -1.4, 0, 8, 6.1 }, -- 2.8 m robot arm (twice the first try) between the dock and the cart
	},
	{
		{ -8.5, -6.5, 0, 3, 3.5, "pallet" }, -- 1.05 m sacks waiting on a pallet
		{ -7.4, 3, 90, 5.6, 5 }, -- 2 m shelf against the left wall
		{ -7.4, 3, 90, 6.3, 5 }, -- 2.2 m metal rack against the left wall
		{ -9, 2.6, 0, 3.4, 3.5, "pallet" }, -- 1.2 m crates waiting on a pallet by the right wall
		{ -9, 5.5, 0, 3.5, 3.2 }, -- 1.2 m vault against the left wall, its door to the approach
	},
}
-- Store life round the house and the yard, never taken away (kit model, x, z, real height, the
-- widest it may be, turn, from which era, lift): barrels and crates waiting by the dock, a hay
-- store behind the house, shrubs on the yard's front corners, planters by the gate.
local SURROUND: { { any } } = {
	{ "WoodBarrel", -5.4, -1.3, 2.6, 2, 0, 1 },
	{ "WoodBarrel", -7.2, -1.2, 2.6, 2, 0, 1 },
	{ "CrateStack", 5.8, -1.4, 2.9, 2.6, 0, 1 },
	{ "HayBale", 8.3, 12.6, 1.6, 2.8, 0, 1 },
	{ "HayBale", 11.1, 12.6, 1.6, 2.8, 0, 1 },
	{ "HayBale", 9.7, 12.6, 1.6, 2.8, 90, 1, 1.6 },
	{ "FlowerShrub", 19, -16, 2.2, 3, 0, 1 },
	{ "FlowerShrub", -19, -16, 2.2, 3, 0, 1 },
	{ "Wheelbarrow", 14.5, 13, 2.2, 3, 60, 2 },
	{ "BarrelRack", 8.5, 16.8, 3.4, 4.5, 0, 3 },
	{ "PlasticCrates", 12.4, 16.8, 3.2, 3, 0, 4 },
	{ "Planter", 4.5, -12, 1.6, 2.8, 0, 5 },
	{ "Planter", -4.5, -12, 1.6, 2.8, 0, 5 },
	-- the front of the service yard is not left bare (the owner, 2026-10-28): goods waiting to ship
	-- beside the container's apron from the steel era (a small store hut joins them on slime tech)
	{ "CrateStack", -13.3, -8.3, 2.9, 2.6, 0, 4 },
	{ "SackPallet", -13.3, -5.4, 3, 3, 0, 4 },
	{ "PlasticCrates", -24.8, -1, 3.2, 3, 0, 4 },
}
-- The village scale (2026-10-30): the yard in front of the house grows from x +-12, z -10 to x +-16.8, z -14,
-- and what stands in the front yard spreads with it (the house, the props against its walls and the service
-- yard stay); every position above is written for the old yard and passes through `spread`.
-- The owner's "spread the inside too" (the same day): the service yard moves 5 studs farther out and 4 deeper
-- to the front (x -32.5..-16, z -14..10, paved on from the front yard), what stands in its front half spread
-- 1.2 deep.
-- Village v2 (2026-11-16): the house is the great granary (`Granary`), wider and deeper with every era. Every
-- position above is still written for a house x -6..6; `grow` is how much farther out the hall's side walls
-- stand, and what leans against them moves out with them. The hay store that stood behind the house stands
-- behind the yard on the hall's left (past the engine house's ground from the slime-tech hall on).
local YARD_X, YARD_FRONT = 16.8, 14
local SERVICE_SHIFT, SERVICE_X0, SERVICE_X1 = -5, -32.5, -16
local function spread(x: number, z: number, grow: number): (number, number)
	if x < -12.5 and z > -12 then -- (in the old service yard; the shrubs on the yard's front corners stay)
		return x + SERVICE_SHIFT, if z < 0 then z * 1.2 else z
	elseif z < -1.5 and math.abs(x) <= 12.5 then
		return x * 1.4, z * 1.4
	elseif z < 0 and math.abs(x) <= 12.5 then
		if math.abs(x) >= 9 then -- (beside the hall's front corner)
			return x + math.sign(x) * grow, z
		end
		return x, z - 0.4 -- goods waiting by the dock, clear of the front windows' flower boxes
	elseif z > 9.5 then
		return x + grow + (if grow >= 3.5 then 5.5 else 0), z
	elseif math.abs(x) >= 5.5 and math.abs(x) <= 12.5 then
		return x + math.sign(x) * grow, z
	end
	return x, z
end

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
	p.Anchored = true
	PondStages.studLook(p, material)
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
	w.Anchored = true
	PondStages.studLook(w, material)
	w.Parent = parent
end

local function place(
	parent: Instance,
	frame: CFrame,
	key: string,
	x: number,
	z: number,
	height: number,
	foot: number,
	lift: number?,
	sideways: boolean? -- in a narrow slot: its longer side runs front to back, `foot` caps the other
): Model?
	local src: Instance? = nil
	for _, name in { "PropKit", "OwnerKit" } do
		local k = kit(name)
		if not src and k then
			src = k:FindFirstChild(key)
		end
	end
	-- (then the props from the free library, which load from Roblox the first time)
	src = src or LibraryKit.find(key)
	if not src or not src:IsA("Model") then
		return nil
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
	-- its real height; narrower only if it would not fit its slot
	local across = if sideways then math.min(s0.X, s0.Z) else math.max(s0.X, s0.Z)
	m:ScaleTo(m:GetScale() * math.min(height / s0.Y, foot / across))
	-- square to the area (the kit model's front, -Z, to the area's front); sideways: its long side
	-- along the area's depth
	local turn = if sideways and s0.X > s0.Z then CFrame.Angles(0, math.pi / 2, 0) else CFrame.identity
	m:PivotTo(CFrame.new(m:GetPivot().Position) * frame.Rotation * turn)
	local box, size = m:GetBoundingBox()
	local target = (frame * CFrame.new(x, (lift or 0) + size.Y / 2, z)).Position -- (lift: something that hovers)
	m:PivotTo(m:GetPivot() + (target - box.Position))
	m.Name = key
	m.Parent = parent
	return m
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
	local _, _, _, props, tiers = PantryStages.state(level)
	local tw, tr, to, tf, ty = TIERS[tiers[1]], TIERS[tiers[2]], TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
	-- (ChatGPT's 3rd review: glowing cyan belongs to slime tech; on the steel openings the trim is
	-- plain steel)
	if tiers[3] == 4 then
		to = table.clone(to)
		to.trim = Color3.fromRGB(150, 158, 170)
		to.trimMat = Enum.Material.Metal
	end
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)

	-- the yard: the area's own floor and edging take the yard tier
	-- the yard grows and never shrinks: a service yard on the right from L21
	local wing = level >= 21
	for _, d in area:GetChildren() do
		-- the old kit shed, barrels and crates: the house and the store props stand in for them
		if (d.Name == "StorageShed" or d.Name == "WoodBarrel" or d.Name == "CrateStack") and d:IsA("Model") then
			d.Parent = nil
		elseif d.Name == "Floor" and d:IsA("BasePart") then
			d.Color = ty.yard
			PondStages.studLook(d, ty.yardMat)
		elseif d.Name == "FloorEdge" and d:IsA("BasePart") then
			d.Color = ty.edge
			PondStages.studLook(d, ty.yardMat)
			-- (the right edge opens into the service yard once it is there)
			local open = wing and frame:PointToObjectSpace(d.Position).X < -15
			d.Transparency = if open then 1 else 0
			d.CanCollide = not open
		end
	end
	if wing then
		-- the service yard on the right, as deep as the yard, edged the same; any bush or fern of the
		-- scenery standing where it is paved goes
		local sw, sx = SERVICE_X1 - SERVICE_X0, (SERVICE_X0 + SERVICE_X1) / 2
		local sd, sz = 10 + YARD_FRONT, (10 - YARD_FRONT) / 2
		part(m, "ServiceYard", Vector3.new(sw, 0.4, sd), frame * CFrame.new(sx, 0.2, sz), ty.yard, ty.yardMat)
		for _, z in { -YARD_FRONT - 0.5, 10.5 } do
			part(m, "ServiceEdge", Vector3.new(sw, 0.6, 1), frame * CFrame.new(sx, 0.3, z), ty.edge, ty.yardMat)
		end
		part(
			m,
			"ServiceEdge",
			Vector3.new(1, 0.6, sd),
			frame * CFrame.new(SERVICE_X0 - 0.5, 0.3, sz),
			ty.edge,
			ty.yardMat
		)
		local plot: Instance = area.Parent or area
		for _, d in plot:GetDescendants() do
			if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
				local p = frame:PointToObjectSpace(d:GetPivot().Position)
				if p.X > SERVICE_X0 - 2 and p.X < -11 and p.Z > -YARD_FRONT - 2 and p.Z < 12 then
					d.Parent = nil
				end
			end
		end
	end

	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local iron = Color3.fromRGB(60, 60, 66)
	-- the great granary: the hall, its clock tower, lean-to shed and silos. It is deeper than the yard and its
	-- silos and hay store stand on the lawn behind: any tree or bush of the scenery there goes.
	Granary.build(m, frame, level)
	local hallHW = Granary.halfWidth(level)
	local grow = hallHW - 6
	do
		local gx0, gx1, gz0, gz1 = Granary.footprint(level)
		for _, d in (area.Parent or area):GetDescendants() do
			if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
				local p = frame:PointToObjectSpace(d:GetPivot().Position)
				if p.X > gx0 and p.X < gx1 and p.Z > gz0 and p.Z < gz1 then
					d.Parent = nil
				end
			end
		end
	end
	-- a model turned on the spot about its own middle
	local function turn(model: Model?, degrees: number)
		if model and degrees ~= 0 then
			local box = model:GetBoundingBox()
			local centre = CFrame.new(box.Position)
			model:PivotTo(centre * CFrame.Angles(0, math.rad(degrees), 0) * centre:ToObjectSpace(model:GetPivot()))
		end
	end
	-- what stands on the yard's paving stands on its top, 0.4 above the lawn
	local FLOOR = 0.4
	local function floorAt(x: number, z: number): number
		local onYard = z <= 10 and z >= -YARD_FRONT and (math.abs(x) <= YARD_X or (wing and x >= SERVICE_X0 and x < 0))
		return if onYard then FLOOR else 0
	end
	-- a model's middle and size along the area's own axes (GetBoundingBox answers in the model's axes,
	-- which a turned model no longer shares)
	local function extents(model: Model): (Vector3, Vector3)
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				local h = d.Size / 2
				for _, c in
					{ Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(-1, 1, 1) }
				do
					for _, sgn in { 1, -1 } do
						local q = frame:PointToObjectSpace((d.CFrame * CFrame.new(h * c * sgn)).Position)
						lo, hi = lo:Min(q), hi:Max(q)
					end
				end
			end
		end
		return (lo + hi) / 2, hi - lo
	end
	-- the store life round the yard
	local nowEra = math.clamp(math.ceil(level / 10), 1, 5)
	for _, s in SURROUND do
		if nowEra >= s[7] then
			local sx, sz = spread(s[2], s[3], grow)
			turn(place(m, frame, s[1], sx, sz, s[4], s[5], (s[8] or 0) + floorAt(sx, sz)), s[6])
		end
	end
	-- from slime tech a small store hut fills the front of the service yard, built like the house in
	-- the house's own tiers (the owner, 2026-10-28: the front stood bare): walls on a base, a roof
	-- overhanging on a trim, a roll-up door in a frame, a lamp over it
	if nowEra >= 5 then
		-- (along the service yard's outer edge, its door turned to the yard, so the container's doors
		-- and the room before them stay clear; the owner, 2026-10-28)
		local hx, hz, hw, hd, hh = 0, 0, 7, 4, 6.6 -- (a door a player walks through, 5.5 high)
		local hutX, hutZ = spread(-24.1, -6.4, grow)
		local hut = frame * CFrame.new(hutX, 0, hutZ) * CFrame.Angles(0, -math.pi / 2, 0) -- its -z: +x
		local function h(x: number, y: number, z: number): CFrame
			return hut * CFrame.new(x, y, z)
		end
		local hf = hz - hd / 2 -- its front face
		part(m, "HutBase", Vector3.new(hw + 0.3, 0.4, hd + 0.3), h(hx, FLOOR + 0.2, hz), tf.base, tf.baseMat)
		part(m, "HutWalls", Vector3.new(hw, hh, hd), h(hx, FLOOR + hh / 2, hz), tw.walls, tw.wallMat)
		part(m, "HutFascia", Vector3.new(hw + 0.9, 0.3, hd + 0.9), h(hx, FLOOR + hh + 0.15, hz), to.trim, to.trimMat)
		part(m, "HutRoof", Vector3.new(hw + 0.8, 0.4, hd + 0.8), h(hx, FLOOR + hh + 0.5, hz), tr.roof, tr.roofMat)
		part(m, "HutDoorDark", Vector3.new(3.2, 5.5, 0.1), h(hx, FLOOR + 2.75, hf - 0.03), Color3.fromRGB(42, 34, 30))
		for k = 0, 9 do
			part(
				m,
				"HutShutter",
				Vector3.new(3, 0.14, 0.08),
				h(hx, FLOOR + 0.5 + k * 0.5, hf - 0.1),
				to.trim,
				to.trimMat
			)
		end
		for _, s in { -1, 1 } do
			part(
				m,
				"HutJamb",
				Vector3.new(0.35, 5.8, 0.35),
				h(hx + s * 1.78, FLOOR + 2.9, hf - 0.12),
				tf.frame,
				tf.frameMat
			)
		end
		part(m, "HutHeader", Vector3.new(3.9, 0.4, 0.4), h(hx, FLOOR + 5.8, hf - 0.14), tf.frame, tf.frameMat)
		part(m, "HutLamp", Vector3.new(0.8, 0.3, 0.3), h(hx, FLOOR + 6.25, hf - 0.2), to.glass, Enum.Material.Neon).CastShadow =
			false
	end
	-- the jib hoist of the painted-timber era, built from parts so its crate truly hangs from the hook:
	-- a post on a base plate, an arm slewed over the cart in the loading corner with a brace, a pulley,
	-- a rope and a hook; a crate hangs while the hand cart waits below (none over the bigger forklift)
	local hoist = SPOT[3][props[3]]
	if props[3] > 0 and hoist[6] == "built" then
		local hx0, hz0 = spread(hoist[1], hoist[2], grow)
		local ox, oz = spread(8.3, -6.4, grow)
		local base = Vector3.new(hx0, FLOOR, hz0)
		local over = Vector3.new(ox, FLOOR, oz) -- where the cart waits
		local dir = (over - base).Unit
		local reach = (over - base).Magnitude
		local jibTop = FLOOR + hoist[4]
		local wood, woodMat = tf.frame, tf.frameMat
		local function beam(name: string, a: Vector3, b: Vector3, w: number)
			part(m, name, Vector3.new(w, w, (b - a).Magnitude), frame * CFrame.lookAt((a + b) / 2, b), wood, woodMat)
		end
		part(m, "HoistFoot", Vector3.new(1.8, 0.4, 1.8), at(base.X, FLOOR + 0.2, base.Z), tf.base, tf.baseMat)
		part(m, "HoistPost", Vector3.new(0.9, hoist[4], 0.9), at(base.X, FLOOR + hoist[4] / 2, base.Z), wood, woodMat)
		local armTop = Vector3.new(base.X, jibTop - 0.4, base.Z)
		beam("HoistArm", armTop - dir * 0.4, armTop + dir * (reach + 1.2), 0.7)
		beam("HoistBrace", Vector3.new(base.X, jibTop - 3, base.Z), armTop + dir * 2.4, 0.4)
		local hook = Vector3.new(over.X, jibTop - 0.9, over.Z)
		local pulley = part(
			m,
			"HoistPulley",
			Vector3.new(0.3, 0.7, 0.7),
			at(hook.X, hook.Y, hook.Z),
			iron,
			Enum.Material.Metal
		) :: Part
		pulley.Shape = Enum.PartType.Cylinder
		local withCrate = props[1] == 2
		-- (the crate clears the cart's load; the empty hook clears the forklift's roof by a stud)
		local ropeEnd = if withCrate then FLOOR + 6.8 else jibTop - 1.3
		part(
			m,
			"HoistRope",
			Vector3.new(0.12, hook.Y - ropeEnd, 0.12),
			at(hook.X, (hook.Y + ropeEnd) / 2, hook.Z),
			Color3.fromRGB(226, 196, 140),
			Enum.Material.Fabric
		)
		part(m, "HoistHook", Vector3.new(0.35, 0.5, 0.35), at(hook.X, ropeEnd - 0.2, hook.Z), iron, Enum.Material.Metal)
		if withCrate then
			for _, s in { -1, 1 } do -- the sling down to the crate's corners
				part(
					m,
					"HoistSling",
					Vector3.new(0.08, 1.1, 0.08),
					at(hook.X + s * 0.45, ropeEnd - 0.85, hook.Z) * CFrame.Angles(0, 0, s * 0.45),
					Color3.fromRGB(226, 196, 140),
					Enum.Material.Fabric
				)
			end
			part(
				m,
				"HoistCrate",
				Vector3.new(1.6, 1.3, 1.6),
				at(hook.X, ropeEnd - 2.05, hook.Z),
				Color3.fromRGB(196, 140, 80),
				Enum.Material.WoodPlanks
			)
		end
	end
	-- the store props
	local PALLET = 0.35
	for j = 1, 4 do
		local era = props[j]
		if era > 0 and SPOT[j][era][6] ~= "built" then
			local spot = SPOT[j][era]
			local x, z = spread(spot[1], spot[2], grow)
			local onPallet = spot[6] == "pallet"
			local floats = PROPS[j][era] == "HoverCart"
			local lift = floorAt(x, z) + (if onPallet then PALLET elseif floats then 1.3 else 0)
			local model = place(m, frame, PROPS[j][era], x, z, spot[4], spot[5], lift, spot[6] == "side")
			turn(model, spot[3])
			if model and floats then
				-- it bobs on each player's screen (HoverBob), over a soft glow on the paving
				CollectionService:AddTag(model, "Hover")
				local glow = part(
					m,
					"HoverGlow",
					Vector3.new(0.06, 3.6, 3.2),
					at(x, floorAt(x, z) + 0.04, z) * CFrame.Angles(0, 0, math.pi / 2),
					Color3.fromRGB(120, 255, 210),
					Enum.Material.Neon
				) :: Part
				glow.Shape = Enum.PartType.Cylinder
				glow.Transparency = 0.55
				glow.CastShadow = false
			end
			if model and onPallet then
				part(
					m,
					"Pallet",
					Vector3.new(spot[5] * 0.85, PALLET, spot[5] * 0.85),
					at(x, lift - PALLET / 2, z),
					Color3.fromRGB(176, 132, 84),
					Enum.Material.WoodPlanks
				)
			end
			local name = PROPS[j][era]
			if model and name == "GooTank" then
				-- a chunky pipe from the tank's back round to the house's side wall, behind the vault
				-- and clear of the working space (ChatGPT's 6th review), on posts, with a valve block
				local p, size = extents(model)
				local zp, py = 8.4, 1.3
				local pipeCol = Color3.fromRGB(70, 150, 140)
				local back = p.Z + size.Z / 2 - 0.5
				local run = part(
					m,
					"GooPipe",
					Vector3.new(zp - back, 0.6, 0.6),
					at(p.X, py, (back + zp) / 2) * CFrame.Angles(0, math.pi / 2, 0),
					pipeCol,
					Enum.Material.Metal
				) :: Part
				run.Shape = Enum.PartType.Cylinder
				local len = -hallHW - p.X
				local pipe = part(
					m,
					"GooPipe",
					Vector3.new(len, 0.6, 0.6),
					at(p.X + len / 2, py, zp),
					pipeCol,
					Enum.Material.Metal
				) :: Part
				pipe.Shape = Enum.PartType.Cylinder
				part(m, "PipeBend", Vector3.new(0.8, 0.8, 0.8), at(p.X, py, zp), pipeCol, Enum.Material.Metal)
				for _, t in { 0.3, 0.7 } do
					part(m, "PipePost", Vector3.new(0.4, py, 0.4), at(p.X + len * t, py / 2, zp), tf.base, tf.baseMat)
				end
				part(
					m,
					"PipeValve",
					Vector3.new(0.8, 0.9, 0.9),
					at(p.X + len * 0.5, py, zp),
					Color3.fromRGB(60, 60, 66),
					Enum.Material.Metal
				)
			elseif model and name == "StoreCrane" then
				-- four outriggers on pads: a crane at work stands on its legs (ChatGPT's 6th review)
				local p, size = extents(model)
				for _, ex in { -0.3, 0.3 } do
					for _, s in { -1, 1 } do
						local oz = p.Z + s * (size.Z / 2 + 0.5)
						part(
							m,
							"Outrigger",
							Vector3.new(0.4, 0.35, 1.4),
							at(p.X + ex * size.X, FLOOR + 0.9, p.Z + s * (size.Z / 2)),
							Color3.fromRGB(60, 60, 66),
							Enum.Material.Metal
						)
						part(
							m,
							"OutriggerLeg",
							Vector3.new(0.3, 0.9, 0.3),
							at(p.X + ex * size.X, FLOOR + 0.5, oz),
							Color3.fromRGB(60, 60, 66),
							Enum.Material.Metal
						)
						part(
							m,
							"OutriggerPad",
							Vector3.new(1, 0.15, 1),
							at(p.X + ex * size.X, FLOOR + 0.08, oz),
							Color3.fromRGB(230, 180, 60)
						)
					end
				end
			elseif model and name == "GrainSilo" then
				-- a discharge chute on the side toward the house, a pallet of filled sacks under it
				local p, size = extents(model)
				local sx = p.X + size.X / 2
				part(m, "SiloHopper", Vector3.new(1, 1, 1.2), at(sx - 0.2, FLOOR + 3.2, p.Z), tf.base, tf.baseMat)
				part(
					m,
					"SiloChute",
					Vector3.new(1.5, 0.45, 0.8),
					at(sx + 0.6, FLOOR + 2.6, p.Z) * CFrame.Angles(0, 0, -0.6),
					tf.base,
					tf.baseMat
				)
				place(m, frame, "SackPallet", sx + 1.8, p.Z, 2.2, 2.4, FLOOR)
			end
		end
	end
	-- the forklift's parking bay, two painted lines either side of it
	if props[1] == 4 then
		local fx, fz = spread(SPOT[1][4][1], SPOT[1][4][2], grow) -- (round the spread forklift)
		for _, s in { -1, 1 } do
			part(
				m,
				"BayLine",
				Vector3.new(0.25, 0.04, 5.8),
				at(fx + s * 2.7, FLOOR + 0.02, fz),
				Color3.fromRGB(240, 200, 60)
			)
		end
	end
	return m
end

-- the builders' helpers, shared with the garden's stages
PantryStages.part = part
PantryStages.wedge = wedge
PantryStages.place = place
PondStages.kitPlace = place

return PantryStages
