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
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
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
		{ 8.5, -6.5, 90, 3.4, 4 }, -- 1.2 m pallet jack
		-- a real forklift, twice the first try (the owner, 2026-10-28): 4.2 m to the guard's top, its
		-- length along the left side, in the left service strip that grows with it
		{ 10.4, -3.6, 0, 12, 12.6, "side" },
		{ 8.5, -7, 90, 2.6, 4 }, -- hover cart, floating (the owner: it has no weight)
	},
	{
		{ -9, 6.8, 90, 3.6, 4.5 }, -- 1.25 m barrel rack against the left wall
		{ -8.4, 7.2, 0, 3.4, 3.4 }, -- 1.2 m crates in a low stack against the wall, a walk beside them
		{ -20, 4.5, 0, 14, 8.5 }, -- 4.9 m grain silo at the back of the service yard
		{ -19, 3.4, 0, 7, 6, "side" }, -- 2.5 m short container, doors to the front, 7 clear before them
		{ -19, 3, 0, 8.5, 6.5 }, -- 3 m goo tank in the service yard, piped to the house
	},
	{
		{ 7.2, 5.2, -90, 7, 2.5 }, -- 2.5 m ladder against the right wall
		-- (the jib hoist, twice as tall, at the front of the yard: its post at the left edge, the jib
		-- over the loading corner where the hand cart waits; the owner, 2026-10-28)
		{ 7.6, -6.8, 90, 10, 9.4 },
		{ -19.5, -6.2, 90, 12, 13 }, -- 4.2 m (boom up) crane truck across the front of the silo, 4 clear
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
	{ "HayBale", 2.5, 12.6, 1.6, 2.8, 0, 1 },
	{ "HayBale", 5.3, 12.6, 1.6, 2.8, 0, 1 },
	{ "HayBale", 3.9, 12.6, 1.6, 2.8, 90, 1, 1.6 },
	{ "FlowerShrub", 13.8, -11.6, 2.2, 3, 0, 1 },
	{ "FlowerShrub", -13.8, -11.6, 2.2, 3, 0, 1 },
	{ "Wheelbarrow", 8.5, 12.8, 2.2, 3, 60, 2 },
	{ "BarrelRack", -4.5, 12.6, 3.4, 4.5, 180, 3 },
	{ "PlasticCrates", -8.5, 12.8, 3.2, 3, 0, 4 },
	{ "Planter", 4.5, -12, 1.6, 2.8, 0, 5 },
	{ "Planter", -4.5, -12, 1.6, 2.8, 0, 5 },
	-- the front of the service yard is not left bare (the owner, 2026-10-28): goods waiting to ship
	-- beside the container's apron from the steel era (a small store hut joins them on slime tech)
	{ "CrateStack", -14.3, -8.3, 2.9, 2.6, 0, 4 },
	{ "SackPallet", -14.3, -5.4, 3, 3, 0, 4 },
	{ "PlasticCrates", -24.8, -1, 3.2, 3, 0, 4 },
}
-- the house: 12 wide (x), 9 deep (z from 0 to 9), its door to the front (-z)
local W, D, Z0 = 12, 9, 0
local H1, H2 = 6, 4.6 -- ground storey, upper storeys
local BASE = 0.8
local DOOR_H = 5.2 -- a loading door a player could pass (the player is 5)

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
	local storeys, canopy, rooftop, props, tiers = PantryStages.state(level)
	local tw, tr, to, tf, ty = TIERS[tiers[1]], TIERS[tiers[2]], TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
	-- (ChatGPT's 3rd review: glowing cyan belongs to slime tech; on the steel openings the trim is
	-- plain steel)
	if tiers[3] == 4 then
		to = table.clone(to)
		to.trim = Color3.fromRGB(150, 158, 170)
		to.trimMat = Enum.Material.Metal
	end
	-- doors and hatches stand out from pale trim in dark wood (ChatGPT's 3rd review)
	local leafCol = if tiers[4] == 3 or tiers[4] == 6 then Color3.fromRGB(104, 66, 44) else tf.frame
	local leafMat = if tiers[4] == 3 or tiers[4] == 6 then Enum.Material.Wood else tf.frameMat
	local m = Instance.new("Model")
	m.Name = "AreaStage"
	m:SetAttribute("Level", level)

	-- the yard: the area's own floor and edging take the yard tier
	-- the yard grows and never shrinks: a service yard on the right from L21, a strip on the left for
	-- the forklift from L31
	local wing, wingL = level >= 21, level >= 31
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
			-- (a side edge opens into the yard grown beyond it)
			local ex = frame:PointToObjectSpace(d.Position).X
			local open = (wing and ex < -12) or (wingL and ex > 12)
			d.Transparency = if open then 1 else 0
			d.CanCollide = not open
		end
	end
	if wing then
		-- the service yard on the right, as deep as the yard, edged the same; any bush or fern of the
		-- scenery standing where it is paved goes
		part(m, "ServiceYard", Vector3.new(14, 0.4, 20), frame * CFrame.new(-19, 0.2, 0), ty.yard, ty.yardMat)
		for _, z in { -10.5, 10.5 } do
			part(m, "ServiceEdge", Vector3.new(14, 0.6, 1), frame * CFrame.new(-20, 0.3, z), ty.edge, ty.yardMat)
		end
		part(m, "ServiceEdge", Vector3.new(1, 0.6, 20), frame * CFrame.new(-26.5, 0.3, 0), ty.edge, ty.yardMat)
	end
	if wingL then
		part(m, "ServiceYard", Vector3.new(5, 0.4, 20), frame * CFrame.new(14.5, 0.2, 0), ty.yard, ty.yardMat)
		for _, z in { -10.5, 10.5 } do
			part(m, "ServiceEdge", Vector3.new(5, 0.6, 1), frame * CFrame.new(15.5, 0.3, z), ty.edge, ty.yardMat)
		end
		part(m, "ServiceEdge", Vector3.new(1, 0.6, 20), frame * CFrame.new(17.5, 0.3, 0), ty.edge, ty.yardMat)
	end
	if wing then
		local plot: Instance = area.Parent or area
		for _, d in plot:GetDescendants() do
			if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
				local p = frame:PointToObjectSpace(d:GetPivot().Position)
				local inR = p.X > -28 and p.X < -11
				local inL = wingL and p.X > 11 and p.X < 19
				if (inR or inL) and math.abs(p.Z) < 12 then
					d.Parent = nil
				end
			end
		end
	end

	local zc = Z0 + D / 2
	local at = function(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	-- a wall face's frame: at (x, y, z) on the outside of a wall, local -Z pointing out of it
	local function face(x: number, y: number, z: number, out: Vector3): CFrame
		local p = at(x, y, z)
		return CFrame.lookAt(p.Position, p.Position + frame:VectorToWorldSpace(out))
	end
	local wallTier, openTier = tiers[1], tiers[3]
	-- the loading door's width by the openings' tier (ChatGPT's 2nd review: the door must lead)
	local doorW = ({ 3.5, 4.2, 4.4, 5.6, 5.6, 5.6 })[openTier]
	-- corner posts and storey bands: on marble in sandstone, not gold (ChatGPT's 2nd review: gold
	-- should pick out a few edges, not outline every part)
	local postCol = if tiers[4] >= 6 then Color3.fromRGB(196, 174, 136) else tf.frame
	local postMat = if tiers[4] >= 6 then Enum.Material.Marble else tf.frameMat

	-- A window on a wall face (its middle at `cf`): a frame with depth, a cross of glazing bars, a
	-- sill; wooden shutters while the openings are timber, a stone lintel on brick.
	-- Each opening tier has its own window (ChatGPT's review, 2026-10-28: windows by function, less
	-- glow so the doors lead): small square ones on timber and brick, a wide low strip on steel and
	-- slime tech, a tall narrow one on marble. Only slime tech glows.
	local winW, winH = 1.4, 1.4
	if openTier == 4 or openTier == 5 then
		winW, winH = 2.4, 0.9
	elseif openTier >= 6 then
		winW, winH = 1, 2
	end
	local function window(cf: CFrame)
		part(
			m,
			"WindowFrame",
			Vector3.new(winW + 0.5, winH + 0.5, 0.3),
			cf * CFrame.new(0, 0, -0.05),
			to.trim,
			to.trimMat
		)
		local pane = part(
			m,
			"Window",
			Vector3.new(winW, winH, 0.32),
			cf * CFrame.new(0, 0, -0.06),
			to.glass,
			if openTier == 5 then Enum.Material.Neon else Enum.Material.Glass
		)
		pane.CastShadow = false
		part(m, "GlazingBar", Vector3.new(0.14, winH, 0.36), cf * CFrame.new(0, 0, -0.07), to.trim, to.trimMat)
		if winH < 2 then
			part(m, "GlazingBar", Vector3.new(winW, 0.14, 0.36), cf * CFrame.new(0, 0, -0.07), to.trim, to.trimMat)
		else
			part(m, "GlazingBar", Vector3.new(winW, 0.14, 0.36), cf * CFrame.new(0, 0.35, -0.07), to.trim, to.trimMat)
			part(
				m,
				"WindowCap",
				Vector3.new(winW + 0.8, 0.3, 0.45),
				cf * CFrame.new(0, winH / 2 + 0.4, -0.15),
				to.trim,
				to.trimMat
			)
		end
		part(
			m,
			"Sill",
			Vector3.new(winW + 0.9, 0.22, 0.5),
			cf * CFrame.new(0, -winH / 2 - 0.35, -0.2),
			tf.base,
			tf.baseMat
		)
		if openTier <= 2 then
			for _, s in { -1, 1 } do
				part(
					m,
					"Shutter",
					Vector3.new(0.85, 1.9, 0.12),
					cf * CFrame.new(s * 1.45, 0, -0.08),
					tf.frame,
					tf.frameMat
				)
				part(
					m,
					"ShutterRail",
					Vector3.new(0.85, 0.16, 0.16),
					cf * CFrame.new(s * 1.45, 0.45, -0.14),
					to.trim,
					to.trimMat
				)
				part(
					m,
					"ShutterRail",
					Vector3.new(0.85, 0.16, 0.16),
					cf * CFrame.new(s * 1.45, -0.45, -0.14),
					to.trim,
					to.trimMat
				)
			end
		elseif openTier == 3 then
			part(m, "Lintel", Vector3.new(2.3, 0.35, 0.4), cf * CFrame.new(0, 1.12, -0.12), tf.base, tf.baseMat)
		end
	end

	-- What dresses a wall of `len` studs and `h` high (its middle at `cf`), by the walls' tier:
	-- timber battens, brick quoins at the corners, steel panel seams, glowing slime strips, marble
	-- pilasters.
	local function dressWall(cf: CFrame, len: number, h: number)
		if wallTier <= 2 then
			local n = math.floor(len / 1.5)
			for j = 1, n - 1 do
				part(
					m,
					"Batten",
					Vector3.new(0.18, h - 0.2, 0.12),
					cf * CFrame.new(-len / 2 + j * len / n, 0, -0.04),
					tf.frame,
					tf.frameMat
				)
			end
		elseif wallTier == 3 then
			for _, s in { -1, 1 } do
				-- fewer, bigger sandstone quoins (ChatGPT's 2nd review: bright white ones looked striped)
				local rows = math.floor(h / 1.1)
				for j = 0, rows - 1 do
					local wide = j % 2 == 0
					part(
						m,
						"Quoin",
						Vector3.new(if wide then 1.3 else 0.9, 0.8, 0.16),
						cf * CFrame.new(s * (len / 2 - (if wide then 0.65 else 0.45)), -h / 2 + 0.5 + j * 1.1, -0.05),
						Color3.fromRGB(214, 192, 150),
						Enum.Material.Slate
					)
				end
			end
		elseif wallTier == 4 then
			for y = -h / 2 + 1.2, h / 2 - 0.4, 1.2 do
				part(m, "PanelSeam", Vector3.new(len, 0.12, 0.1), cf * CFrame.new(0, y, -0.03), tf.frame, tf.frameMat)
			end
		elseif wallTier == 5 then
			for _, y in { -h / 2 + 0.5, h / 2 - 0.5 } do
				part(
					m,
					"GlowStrip",
					Vector3.new(len, 0.16, 0.1),
					cf * CFrame.new(0, y, -0.03),
					tw.trim,
					Enum.Material.Neon
				).CastShadow =
					false
			end
		else
			-- marble: sandstone pilasters that stand out from the ivory walls, sunk panels between them,
			-- a cornice at the top of each storey (ChatGPT's review: white on white did not read)
			local sand = Color3.fromRGB(196, 174, 136) -- (#C4AE88, ChatGPT's pick against the ivory)
			for _, x in { -len / 3, len / 3 } do
				part(
					m,
					"Pilaster",
					Vector3.new(0.65, h - 0.3, 0.32),
					cf * CFrame.new(x, -0.05, -0.12),
					sand,
					Enum.Material.Marble
				)
				part(
					m,
					"PilasterCap",
					Vector3.new(0.95, 0.25, 0.42),
					cf * CFrame.new(x, h / 2 - 0.45, -0.16),
					tw.trim,
					tw.trimMat
				)
			end
			for _, x in { -len / 2 + len / 6 + 0.1, 0, len / 2 - len / 6 - 0.1 } do
				part(
					m,
					"InsetPanel",
					Vector3.new(len / 3 - 1.1, h - 1.8, 0.06),
					cf * CFrame.new(x, -0.1, -0.01),
					Color3.fromRGB(228, 220, 204),
					Enum.Material.Marble
				)
			end
			part(
				m,
				"Cornice",
				Vector3.new(len + 0.8, 0.45, 0.6),
				cf * CFrame.new(0, h / 2 - 0.25, -0.28),
				sand,
				Enum.Material.Marble
			)
		end
	end

	-- foundation, and a plinth course round the foot of the walls
	part(m, "Foundation", Vector3.new(W + 0.8, BASE, D + 0.8), at(0, BASE / 2, zc), tf.base, tf.baseMat)
	part(m, "Plinth", Vector3.new(W + 0.3, 0.5, D + 0.3), at(0, BASE + 0.25, zc), tf.base, tf.baseMat)
	-- storeys
	local top = BASE
	for k = 1, storeys do
		local h = if k == 1 then H1 else H2
		local y = top + h / 2
		part(m, "WallFront", Vector3.new(W, h, 0.6), at(0, y, Z0 + 0.3), tw.walls, tw.wallMat)
		part(m, "WallBack", Vector3.new(W, h, 0.6), at(0, y, Z0 + D - 0.3), tw.walls, tw.wallMat)
		dressWall(face(0, y, Z0, Vector3.new(0, 0, -1)), W - 0.9, h)
		dressWall(face(0, y, Z0 + D, Vector3.new(0, 0, 1)), W - 0.9, h)
		for _, s in { -1, 1 } do
			part(m, "WallSide", Vector3.new(0.6, h, D - 1.2), at(s * (W / 2 - 0.3), y, zc), tw.walls, tw.wallMat)
			dressWall(face(s * W / 2, y, zc, Vector3.new(s, 0, 0)), D - 0.9, h)
			-- corner posts
			for _, cz in { Z0 + 0.3, Z0 + D - 0.3 } do
				part(m, "CornerPost", Vector3.new(0.9, h, 0.9), at(s * (W / 2 - 0.3), y, cz), postCol, postMat)
			end
		end
		-- the band between storeys: from the top of this storey to the foot of the next, no gap
		part(m, "Band", Vector3.new(W + 0.4, 0.4, D + 0.4), at(0, top + h + 0.2, zc), postCol, postMat)
		-- windows: either side of the door on the ground storey, three on the upper ones (the second
		-- storey's middle one is the loft door), one each side
		local wy = top + h * 0.55
		-- (no ground-floor front windows beside a wide shutter; the top storey's middle is a vent)
		-- (on marble the top storey keeps only its vent: a store, not another floor of rooms)
		local xs: { number } = if k == 1
			then (if doorW > 5 then {} else { -4.2, 4.2 })
			elseif k == 3 and openTier >= 6 then {}
			else { -3.4, 3.4 }
		for _, wx in xs do
			window(face(wx, wy, Z0, Vector3.new(0, 0, -1)))
		end
		for _, s in { -1, 1 } do
			window(face(s * W / 2, wy, zc, Vector3.new(s, 0, 0)))
		end
		if k == 3 then
			-- the top storey stores too: a big dark louvred vent in the middle
			local vy = top + h * 0.5
			part(m, "VentFrame", Vector3.new(2.7, 3, 0.4), at(0, vy, Z0 - 0.1), to.trim, to.trimMat)
			part(m, "VentDark", Vector3.new(2.1, 2.4, 0.42), at(0, vy, Z0 - 0.11), Color3.fromRGB(46, 40, 38))
			for dy = -0.9, 0.95, 0.45 do
				part(m, "VentSlat", Vector3.new(2.1, 0.12, 0.5), at(0, vy + dy, Z0 - 0.2), tw.walls, tw.wallMat)
			end
		end
		if k == 2 then
			-- the loft door, bigger and sunk in a heavy frame; from steel on a sealed cargo hatch, before
			-- that a hoist (a braced beam out of the wall, a pulley, a rope, a crate held up above the
			-- loading canopy's line)
			local ly = top + 0.2
			-- (the frame stands proud of the wall, the doors sit back inside it)
			for _, s in { -1, 1 } do
				part(m, "LoftJamb", Vector3.new(0.35, 3.9, 0.5), at(s * 1.55, ly + 1.95, Z0 - 0.3), to.trim, to.trimMat)
			end
			part(m, "LoftSill", Vector3.new(3.5, 0.3, 0.6), at(0, ly + 0.1, Z0 - 0.3), to.trim, to.trimMat)
			part(m, "LoftRecess", Vector3.new(2.8, 3.6, 0.1), at(0, ly + 1.95, Z0 - 0.02), Color3.fromRGB(42, 34, 30))
			if openTier <= 3 then
				-- braced timber doors set back in the opening
				for _, s in { -1, 1 } do
					part(
						m,
						"LoftDoor",
						Vector3.new(1.3, 3.3, 0.16),
						at(s * 0.68, ly + 1.95, Z0 - 0.1),
						leafCol,
						leafMat
					)
					part(
						m,
						"LoftBrace",
						Vector3.new(0.2, 3.2, 0.1),
						at(s * 0.68, ly + 1.95, Z0 - 0.22) * CFrame.Angles(0, 0, s * 0.35),
						to.trim,
						to.trimMat
					)
				end
			else
				-- a sealed steel cargo hatch: a panel, two bars, two lock blocks
				part(m, "Hatch", Vector3.new(2.5, 3.2, 0.16), at(0, ly + 1.95, Z0 - 0.1), tf.frame, tf.frameMat)
				for _, dy in { -0.7, 0.7 } do
					part(
						m,
						"HatchBar",
						Vector3.new(2.6, 0.3, 0.22),
						at(0, ly + 1.95 + dy, Z0 - 0.2),
						to.trim,
						to.trimMat
					)
				end
				for _, s in { -1, 1 } do
					part(
						m,
						"HatchLock",
						Vector3.new(0.35, 0.5, 0.3),
						at(s * 1, ly + 1.95, Z0 - 0.25),
						Color3.fromRGB(60, 60, 66),
						Enum.Material.Metal
					)
				end
			end
			part(m, "LoftLintel", Vector3.new(3.8, 0.45, 0.7), at(0, ly + 4.05, Z0 - 0.3), tf.base, tf.baseMat)
		end
		if k == 2 and openTier <= 3 then
			part(m, "LoftRail", Vector3.new(2.6, 0.18, 0.4), at(0, top + 2.05, Z0 - 0.3), to.trim, to.trimMat)
			part(m, "HoistBeam", Vector3.new(0.55, 0.55, 2.6), at(0, top + h - 0.35, Z0 - 1.2), tf.frame, tf.frameMat)
			wedge(
				m,
				"HoistBrace",
				Vector3.new(0.4, 1, 1),
				at(0, top + h - 1.12, Z0 - 0.5) * CFrame.Angles(0, 0, math.pi),
				tf.frame,
				tf.frameMat
			)
			local pulley = part(
				m,
				"Pulley",
				Vector3.new(0.2, 0.6, 0.6),
				at(0, top + h - 0.75, Z0 - 2.2),
				Color3.fromRGB(70, 70, 76),
				Enum.Material.Metal
			) :: Part
			pulley.Shape = Enum.PartType.Cylinder
			part(
				m,
				"HoistRope",
				Vector3.new(0.1, 0.8, 0.1),
				at(0, top + h - 1.45, Z0 - 2.2),
				Color3.fromRGB(226, 196, 140),
				Enum.Material.Fabric
			)
			if canopy then
				-- the canopy is under it: only an iron hook waits (a crate could not come down)
				part(
					m,
					"HoistHook",
					Vector3.new(0.3, 0.4, 0.3),
					at(0, top + h - 2, Z0 - 2.2),
					Color3.fromRGB(60, 60, 66),
					Enum.Material.Metal
				)
			else
				part(
					m,
					"HoistCrate",
					Vector3.new(1.1, 0.9, 1.1),
					at(0, top + h - 2.3, Z0 - 2.2),
					Color3.fromRGB(196, 140, 80),
					Enum.Material.WoodPlanks
				)
			end
		end
		top += h + 0.4
	end
	-- The store door leads the front (ChatGPT's 2nd review): wider each opening tier, as tall as a
	-- player can pass, a dark recess behind it and a thick frame round it. Timber barn doors with Z
	-- braces and iron handles while the openings are timber or brick (a sliding-door rail on painted
	-- timber), a wide roll-up shutter with its box from steel on.
	local iron = Color3.fromRGB(60, 60, 66)
	part(
		m,
		"DoorRecess",
		Vector3.new(doorW + 0.2, DOOR_H + 0.3, 0.3),
		at(0, BASE + DOOR_H / 2, Z0 - 0.02),
		Color3.fromRGB(42, 34, 30)
	)
	-- (on marble a sandstone portal of two columns and a lintel, to carry the tall front)
	local jambCol = if openTier >= 6 then Color3.fromRGB(196, 174, 136) else to.trim
	local jambMat = if openTier >= 6 then Enum.Material.Marble else to.trimMat
	local jambW = if openTier >= 6 then 0.7 else 0.5
	for _, s in { -1, 1 } do
		part(
			m,
			"DoorJamb",
			Vector3.new(jambW, DOOR_H + 0.6, 0.6),
			at(s * (doorW / 2 + jambW / 2), BASE + DOOR_H / 2 + 0.3, Z0 - 0.2),
			jambCol,
			jambMat
		)
	end
	part(
		m,
		"DoorHeader",
		Vector3.new(doorW + jambW * 2 + 0.1, 0.6, 0.65),
		at(0, BASE + DOOR_H + 0.5, Z0 - 0.22),
		jambCol,
		jambMat
	)
	if openTier <= 3 then
		local leafW = doorW / 2 - 0.05
		for _, s in { -1, 1 } do
			local leaf = at(s * doorW / 4, BASE + DOOR_H / 2, Z0 - 0.1)
			part(m, "Door", Vector3.new(leafW, DOOR_H, 0.35), leaf, leafCol, leafMat)
			for _, ry in { DOOR_H / 2 - 0.5, -DOOR_H / 2 + 0.5 } do
				part(
					m,
					"DoorRail",
					Vector3.new(leafW - 0.1, 0.3, 0.12),
					leaf * CFrame.new(0, ry, -0.22),
					to.trim,
					to.trimMat
				)
			end
			part(
				m,
				"DoorBrace",
				Vector3.new(0.26, math.sqrt((DOOR_H - 1) ^ 2 + (leafW - 0.3) ^ 2), 0.12),
				leaf * CFrame.new(0, 0, -0.22) * CFrame.Angles(0, 0, s * math.atan2(leafW - 0.3, DOOR_H - 1)),
				to.trim,
				to.trimMat
			)
			part(
				m,
				"DoorHandle",
				Vector3.new(0.14, 0.7, 0.18),
				leaf * CFrame.new(-s * (leafW / 2 - 0.25), -0.1, -0.3),
				iron,
				Enum.Material.Metal
			)
		end
	else
		local shutter = at(0, BASE + DOOR_H / 2, Z0 - 0.1)
		part(m, "Shutter", Vector3.new(doorW, DOOR_H, 0.3), shutter, tf.frame, tf.frameMat)
		for y = -DOOR_H / 2 + 0.4, DOOR_H / 2 - 0.3, 0.5 do
			part(
				m,
				"ShutterSlat",
				Vector3.new(doorW - 0.1, 0.09, 0.34),
				shutter * CFrame.new(0, y, -0.01),
				tw.walls,
				tw.wallMat
			)
		end
		part(
			m,
			"ShutterBox",
			Vector3.new(doorW + 0.6, 0.6, 0.7),
			at(0, BASE + DOOR_H + 0.5, Z0 - 0.45),
			tf.frame,
			tf.frameMat
		)
		part(
			m,
			"ShutterHandle",
			Vector3.new(0.9, 0.14, 0.2),
			shutter * CFrame.new(0, -DOOR_H / 2 + 0.3, -0.25),
			iron,
			Enum.Material.Metal
		)
	end
	-- a loading dock before the door at the floor's height, steps down to the yard, bumpers on its face
	-- from steel on
	part(m, "Dock", Vector3.new(doorW + 2, BASE, 2.2), at(0, BASE / 2, Z0 - 1.1), tf.base, tf.baseMat)
	part(m, "DockEdge", Vector3.new(doorW + 2.1, 0.2, 0.3), at(0, BASE + 0.05, Z0 - 2.15), to.trim, to.trimMat)
	part(m, "Step", Vector3.new(2.6, BASE / 2, 0.9), at(0, BASE / 4, Z0 - 2.65), tf.base, tf.baseMat)
	if openTier >= 4 then
		for _, x in { -doorW / 2, doorW / 2 } do
			part(
				m,
				"DockBumper",
				Vector3.new(0.6, 0.6, 0.3),
				at(x, BASE / 2, Z0 - 2.35),
				Color3.fromRGB(30, 30, 34),
				Enum.Material.Rubber
			)
		end
	end
	-- The roof, ridge along x, its shape by the roof's tier (ChatGPT's review, 2026-10-28: each level
	-- its own silhouette): a gambrel barn roof on wood, a gable on brick, a low steel roof with
	-- standing seams on steel and slime tech, a gable with a cornice on marble. A profile is a list of
	-- (distance from the ridge line, height) from the eave in to the ridge; every segment is a wedge
	-- with a block under it, and the gable ends are filled the same way in the wall's material.
	local roofTier = tiers[2]
	local half = D / 2 + 0.6
	local profile: { { number } }
	-- (ChatGPT's 2nd review: a plain gable on the first shed, the tall gambrel saved for the painted
	-- barn so the two wooden levels differ)
	if roofTier == 2 then
		profile = { { half, 0 }, { half - 1.5, 2.6 }, { 0, 4.4 } }
	elseif roofTier == 4 or roofTier == 5 then
		profile = { { half, 0 }, { 0, 1.7 } }
	else
		profile = { { half, 0 }, { 0, 3 } }
	end
	local rh = profile[#profile][2]
	local function heightAt(e: number): number
		for k = 1, #profile - 1 do
			local a, b = profile[k], profile[k + 1]
			if e <= a[1] and e >= b[1] then
				return a[2] + (b[2] - a[2]) * (a[1] - e) / (a[1] - b[1])
			end
		end
		return rh
	end
	for _, sz in { -1, 1 } do
		local turn = if sz < 0 then CFrame.identity else CFrame.Angles(0, math.pi, 0)
		for k = 1, #profile - 1 do
			local a, b = profile[k], profile[k + 1]
			local depth, rise, mid = a[1] - b[1], b[2] - a[2], (a[1] + b[1]) / 2
			wedge(
				m,
				"Roof",
				Vector3.new(W + 1.2, rise, depth),
				at(0, top + a[2] + rise / 2, zc + sz * mid) * turn,
				tr.roof,
				tr.roofMat
			)
			if a[2] > 0 then
				part(
					m,
					"RoofBase",
					Vector3.new(W + 1.2, a[2], depth),
					at(0, top + a[2] / 2, zc + sz * mid),
					tr.roof,
					tr.roofMat
				)
			end
			-- the gable ends between the walls, and a barge board along each slope
			local eo = math.min(a[1], D / 2)
			if eo > b[1] then
				local yo = heightAt(eo)
				for _, s in { -1, 1 } do
					wedge(
						m,
						"Gable",
						Vector3.new(0.5, b[2] - yo, eo - b[1]),
						-- (sunk 0.2 under the roof's face, else the two faces flicker as a pale streak)
						at(s * (W / 2 - 0.25), top + yo + (b[2] - yo) / 2 - 0.2, zc + sz * (eo + b[1]) / 2) * turn,
						tw.walls,
						tw.wallMat
					)
					if yo > 0 then
						part(
							m,
							"GableBase",
							Vector3.new(0.5, yo, eo - b[1]),
							at(s * (W / 2 - 0.25), top + yo / 2, zc + sz * (eo + b[1]) / 2),
							tw.walls,
							tw.wallMat
						)
					end
				end
			end
			local len = math.sqrt(depth ^ 2 + rise ^ 2)
			for _, s in { -1, 1 } do
				part(
					m,
					"BargeBoard",
					Vector3.new(0.22, 0.42, len),
					at(s * (W / 2 + 0.65), top + (a[2] + b[2]) / 2 + 0.12, zc + sz * mid)
						* CFrame.Angles(sz * math.atan2(rise, depth), 0, 0),
					tf.frame,
					tf.frameMat
				)
			end
		end
		-- standing seams down the low steel roof
		if roofTier == 4 or roofTier == 5 then
			local len = math.sqrt(half ^ 2 + rh ^ 2)
			for x = -W * 3 / 8, W * 3 / 8 + 0.01, W / 4 do -- (four broad seams, no shimmer on phones)
				part(
					m,
					"RoofSeam",
					Vector3.new(0.14, 0.14, len),
					at(x, top + rh / 2 + 0.12, zc + sz * half / 2) * CFrame.Angles(sz * math.atan2(rh, half), 0, 0),
					-- (plain steel on steel; only slime tech glows)
					if roofTier == 4 then Color3.fromRGB(150, 158, 170) else tr.trim,
					if roofTier == 4 then Enum.Material.Metal else tr.trimMat
				)
			end
		end
	end
	-- a chunky ridge cap; on marble a cornice ring under the roof
	part(m, "Ridge", Vector3.new(W + 1.6, 0.6, 0.9), at(0, top + rh + 0.15, zc), tf.frame, tf.frameMat)
	if roofTier >= 6 then
		part(
			m,
			"RoofCornice",
			Vector3.new(W + 1.6, 0.5, D + 1.6),
			at(0, top - 0.1, zc),
			Color3.fromRGB(222, 198, 156),
			Enum.Material.Marble
		)
	end
	-- eaves: a fascia board under each roof edge, a gutter at the front, a downspout at a corner
	for _, sz in { -1, 1 } do
		local ez = if sz < 0 then Z0 - 0.6 else Z0 + D + 0.6
		part(m, "Fascia", Vector3.new(W + 1.3, 0.45, 0.22), at(0, top + 0.1, ez), tf.frame, tf.frameMat)
	end
	part(m, "Gutter", Vector3.new(W + 1.3, 0.3, 0.4), at(0, top - 0.25, Z0 - 0.85), tf.frame, tf.frameMat)
	-- (the downspout hugs the corner post, from the gutter's end down to the plinth)
	part(m, "SpoutElbow", Vector3.new(0.25, 0.25, 0.7), at(W / 2 + 0.25, top - 0.4, Z0 - 0.55), tf.frame, tf.frameMat)
	part(
		m,
		"Downspout",
		Vector3.new(0.25, top - 0.9, 0.25),
		at(W / 2 + 0.25, (top + 0.2) / 2 - 0.1, Z0 - 0.3),
		tf.frame,
		tf.frameMat
	)
	-- on the low steel roof a long low ridge vent (ChatGPT: a cottage cupola does not fit a depot);
	-- otherwise a vent cupola on the ridge until the lantern tower takes its place
	if roofTier == 4 or roofTier == 5 then
		part(m, "RidgeVent", Vector3.new(4.2, 0.6, 1.4), at(0, top + rh + 0.55, zc), tf.frame, tf.frameMat)
		for _, s in { -1, 1 } do
			part(
				m,
				"RidgeVentSlot",
				Vector3.new(3.6, 0.3, 0.1),
				at(0, top + rh + 0.55, zc + s * 0.72),
				Color3.fromRGB(46, 40, 38)
			)
		end
		part(m, "RidgeVentCap", Vector3.new(4.6, 0.2, 1.8), at(0, top + rh + 0.95, zc), tr.roof, tr.roofMat)
	elseif not rooftop then
		local ry = top + rh
		part(m, "Cupola", Vector3.new(1.6, 1.3, 1.6), at(0, ry + 0.45, zc), tw.walls, tw.wallMat)
		for _, s in { -1, 1 } do
			part(m, "Louvre", Vector3.new(1.3, 0.8, 0.12), at(0, ry + 0.5, zc + s * 0.82), Color3.fromRGB(46, 40, 38))
			for _, y in { 0.3, 0.55, 0.8 } do
				part(m, "LouvreSlat", Vector3.new(1.3, 0.08, 0.16), at(0, ry + y, zc + s * 0.86), tw.walls, tw.wallMat)
			end
			wedge(
				m,
				"CupolaRoof",
				Vector3.new(2, 0.8, 1),
				at(0, ry + 1.5, zc - s * 0.5) * CFrame.Angles(0, if s < 0 then 0 else math.pi, 0),
				tr.roof,
				tr.roofMat
			)
		end
	end
	-- a wall lantern on a bracket either side of the door, high, beside its frame
	local lx, ly = doorW / 2 + 0.85, BASE + DOOR_H + 0.15
	for _, s in { -1, 1 } do
		part(m, "LampBracket", Vector3.new(0.15, 0.15, 0.7), at(s * lx, ly + 0.6, Z0 - 0.35), iron, Enum.Material.Metal)
		part(m, "LampCap", Vector3.new(0.8, 0.2, 0.8), at(s * lx, ly + 0.55, Z0 - 0.75), iron, Enum.Material.Metal)
		local lamp =
			part(m, "Lantern", Vector3.new(0.6, 0.8, 0.6), at(s * lx, ly, Z0 - 0.75), to.glass, Enum.Material.Neon)
		lamp.CastShadow = false
		if s > 0 then
			local light = Instance.new("PointLight")
			light.Color = to.glass
			light.Range = 12
			light.Brightness = 0.45 -- (a warm glow that does not outshine the door)
			light.Parent = lamp
		end
	end

	-- era 3: a loading canopy over the door, on two posts
	-- a heavy loading canopy over the door and the dock, on two posts with braces, clear of the
	-- door's frame and of a player (ChatGPT's 2nd review: it read as a shop awning)
	if canopy then
		local cy = BASE + DOOR_H + 1.15 -- the canopy's underside at the posts
		local px = doorW / 2 + 0.9
		for _, s in { -1, 1 } do
			part(m, "CanopyPost", Vector3.new(0.6, cy, 0.6), at(s * px, cy / 2, Z0 - 3.4), tf.frame, tf.frameMat)
			part(m, "PostFoot", Vector3.new(1, 0.4, 1), at(s * px, 0.2, Z0 - 3.4), tf.base, tf.baseMat)
			part(m, "CanopyBeam", Vector3.new(0.45, 0.5, 3.8), at(s * px, cy + 0.25, Z0 - 1.6), tf.frame, tf.frameMat)
			wedge(
				m,
				"CanopyBrace",
				Vector3.new(0.35, 0.8, 0.8),
				at(s * px, cy - 0.4, Z0 - 2.9) * CFrame.Angles(0, math.pi, math.pi),
				tf.frame,
				tf.frameMat
			)
		end
		part(m, "CanopyHeader", Vector3.new(px * 2 + 0.8, 0.55, 0.5), at(0, cy + 0.3, Z0 - 3.55), tf.frame, tf.frameMat)
		local cw = Instance.new("WedgePart")
		cw.Name = "Canopy"
		cw.Size = Vector3.new(px * 2 + 1.2, 0.8, 4)
		cw.CFrame = at(0, cy + 0.95, Z0 - 1.9)
		cw.Color = tr.roof
		PondStages.studLook(cw, tr.roofMat)
		cw.Anchored = true
		cw.Parent = m
		part(m, "CanopyFascia", Vector3.new(px * 2 + 1.3, 0.3, 0.3), at(0, cy + 0.65, Z0 - 3.85), to.trim, to.trimMat)
	end
	-- era 5: a lantern tower on the ridge
	if rooftop then
		-- a real lantern tower standing well clear of the ridge (ChatGPT's 2nd review: it read as a
		-- chimney): a base, an open stage of four posts round warm panes, a gold-edged cap and a finial
		local ry = top + rh - 0.4
		part(m, "TowerBase", Vector3.new(2.6, 1.8, 2.6), at(0, ry + 0.9, zc), tw.walls, tw.wallMat)
		part(m, "TowerCornice", Vector3.new(3, 0.3, 3), at(0, ry + 1.95, zc), tw.trim, tw.trimMat)
		-- (open between the posts: a dark inside with one warm lamp, ChatGPT's 3rd review)
		part(m, "TowerInside", Vector3.new(1.5, 1.8, 1.5), at(0, ry + 3, zc), Color3.fromRGB(46, 40, 38))
		part(m, "TowerLamp", Vector3.new(0.7, 0.9, 0.7), at(0, ry + 3, zc), to.glass, Enum.Material.Neon).CastShadow =
			false
		for _, o in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
			part(m, "TowerPost", Vector3.new(0.4, 1.9, 0.4), at(o.X, ry + 3, zc + o.Z), tw.walls, tw.wallMat)
		end
		part(m, "TowerCapBase", Vector3.new(2.8, 0.35, 2.8), at(0, ry + 4.1, zc), tw.trim, tw.trimMat)
		for _, s in { -1, 1 } do
			wedge(
				m,
				"TowerRoof",
				Vector3.new(2.6, 1.3, 1.3),
				at(0, ry + 4.9, zc + s * -0.65) * CFrame.Angles(0, if s == 1 then 0 else math.pi, 0),
				tr.roof,
				tr.roofMat
			)
		end
		local finial = part(m, "Finial", Vector3.one * 0.6, at(0, ry + 5.75, zc), tw.trim, tw.trimMat) :: Part
		finial.Shape = Enum.PartType.Ball
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
		local onYard = math.abs(z) <= 10
			and (math.abs(x) <= 12 or (wing and x >= -26 and x < 0) or (wingL and x > 0 and x <= 17))
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
			turn(place(m, frame, s[1], s[2], s[3], s[4], s[5], (s[8] or 0) + floorAt(s[2], s[3])), s[6])
		end
	end
	-- from slime tech a small store hut fills the front of the service yard, built like the house in
	-- the house's own tiers (the owner, 2026-10-28: the front stood bare): walls on a base, a roof
	-- overhanging on a trim, a roll-up door in a frame, a lamp over it
	if nowEra >= 5 then
		local hx, hz, hw, hd, hh = -20.5, -5.8, 7, 5.5, 5.2
		local hf = hz - hd / 2 -- its front face
		part(m, "HutBase", Vector3.new(hw + 0.3, 0.4, hd + 0.3), at(hx, FLOOR + 0.2, hz), tf.base, tf.baseMat)
		part(m, "HutWalls", Vector3.new(hw, hh, hd), at(hx, FLOOR + hh / 2, hz), tw.walls, tw.wallMat)
		part(m, "HutFascia", Vector3.new(hw + 0.9, 0.3, hd + 0.9), at(hx, FLOOR + hh + 0.15, hz), to.trim, to.trimMat)
		part(m, "HutRoof", Vector3.new(hw + 0.8, 0.4, hd + 0.8), at(hx, FLOOR + hh + 0.5, hz), tr.roof, tr.roofMat)
		part(m, "HutDoorDark", Vector3.new(3.2, 3.9, 0.1), at(hx, FLOOR + 1.95, hf - 0.03), Color3.fromRGB(42, 34, 30))
		for k = 0, 6 do
			part(
				m,
				"HutShutter",
				Vector3.new(3, 0.14, 0.08),
				at(hx, FLOOR + 0.5 + k * 0.5, hf - 0.1),
				to.trim,
				to.trimMat
			)
		end
		for _, s in { -1, 1 } do
			part(
				m,
				"HutJamb",
				Vector3.new(0.35, 4.2, 0.35),
				at(hx + s * 1.78, FLOOR + 2.1, hf - 0.12),
				tf.frame,
				tf.frameMat
			)
		end
		part(m, "HutHeader", Vector3.new(3.9, 0.4, 0.4), at(hx, FLOOR + 4.2, hf - 0.14), tf.frame, tf.frameMat)
		part(m, "HutLamp", Vector3.new(0.8, 0.3, 0.3), at(hx, FLOOR + 4.65, hf - 0.2), to.glass, Enum.Material.Neon).CastShadow =
			false
	end
	-- the store props
	local PALLET = 0.35
	for j = 1, 4 do
		local era = props[j]
		if era > 0 then
			local spot = SPOT[j][era]
			local x, z = spot[1], spot[2]
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
				local len = -W / 2 - p.X
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
	-- a lean-to against the right wall over the small containers of the first eras (ChatGPT's 6th
	-- review: the rack stood alone): two posts and a sloping roof down from the wall
	if props[2] == 1 or props[2] == 2 then
		for _, z in { 5.8, 9.4 } do
			part(m, "LeanToPost", Vector3.new(0.4, 4.2, 0.4), at(-11.4, FLOOR + 2.1, z), tf.frame, tf.frameMat)
		end
		part(m, "LeanToBeam", Vector3.new(0.4, 0.4, 4), at(-11.4, FLOOR + 4.2, 7.6), tf.frame, tf.frameMat)
		part(
			m,
			"LeanToRoof",
			Vector3.new(6.2, 0.25, 4.6),
			at(-8.8, FLOOR + 4.85, 7.6) * CFrame.Angles(0, 0, 0.19),
			tr.roof,
			tr.roofMat
		)
	end
	-- the forklift's parking bay, two painted lines either side of it
	if props[1] == 4 then
		for _, x in { 6.4, 14.4 } do
			part(m, "BayLine", Vector3.new(0.25, 0.04, 13.2), at(x, FLOOR + 0.02, -3.4), Color3.fromRGB(240, 200, 60))
		end
	end
	return m
end

-- the builders' helpers, shared with the garden's stages
PantryStages.part = part
PantryStages.wedge = wedge
PantryStages.place = place

return PantryStages
