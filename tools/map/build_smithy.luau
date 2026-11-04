-- Builds the Blacksmith of the Market (workspace.Map.Market.Blacksmith) from the owner's stall art
-- reference/goo-lineage-web/assets/map/other/blacksmith-01.png: a honey wood frame lashed with rope, a blue and cream awning under a
-- wooden board with the money-bag crest, a stone furnace with fire at the back, an anvil on a stump in front, a weapon rack, an armour
-- stand, a water barrel, a tool bucket, a hanging lantern and a blue banner. No slime: the keeper's spot is kept (KeeperSpot) for the owner.
-- It stands at Config.Market.Smithy and faces the fountain. Run in Edit mode in MapWork, as often as wanted (it removes what it made):
--   node tools/studio_mcp.js run tools/map/build_smithy.luau <studio_id> Edit
-- tools/map/build_market.luau keeps it (it clears every other child of the Market) and paints its yard.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PropKit = ServerStorage.PropKit
local M = Config.Map
-- (the work place's copy of Config can be older than the repo: the same values as src/shared/Config.luau's Config.Market)
local C = Config.Market :: any
local SPOT = C.Smithy or { x = 58, z = 34 }
local NAME = C.SmithyModel or "Blacksmith"
local F = Layout.marketFrame()
local G = M.GroundY
local Mat = Enum.Material

local market = workspace.Map:FindFirstChild(C.Model or "Market")
local old = market:FindFirstChild(NAME)
if old then
	old:Destroy()
end
local model = Instance.new("Model")
model.Name = NAME

-- ===== the palette (the owner's stall art; the same as the Market's buyer) =====
local WOOD = Color3.fromRGB(176, 112, 54)
local WOOD_LIGHT = Color3.fromRGB(198, 136, 70)
local WOOD_DARK = Color3.fromRGB(128, 80, 40)
local ROPE = Color3.fromRGB(226, 196, 138)
local BLUE = Color3.fromRGB(46, 92, 196)
local CREAM = Color3.fromRGB(246, 234, 204)
local GOLD = Color3.fromRGB(246, 190, 56)
local STONE = Color3.fromRGB(150, 146, 140)
local STONE_DARK = Color3.fromRGB(104, 100, 98)
local IRON = Color3.fromRGB(78, 82, 92)
local IRON_LIGHT = Color3.fromRGB(120, 126, 138)
local EMBER = Color3.fromRGB(255, 122, 36)
local WATER = Color3.fromRGB(70, 150, 230)
local GLOW = Color3.fromRGB(255, 206, 110)

-- ===== pieces (build_market.luau's) =====
local function piece(name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?, class: string?): BasePart
	local p = Instance.new(class or "Part") :: BasePart
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Mat.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = model
	return p
end
local function solid(p: BasePart): BasePart
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = true
	return p
end
-- a cylinder standing along cf's Y
local function cylinder(name: string, d: number, h: number, cf: CFrame, colour: Color3, material: Enum.Material?): BasePart
	local p = piece(name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), colour, material) :: Part
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(name: string, d: number, cf: CFrame, colour: Color3, material: Enum.Material?): BasePart
	local p = piece(name, Vector3.one * d, cf, colour, material) :: Part
	p.Shape = Enum.PartType.Ball
	return p
end
local function bar(name: string, a: Vector3, b: Vector3, w: number, t: number, colour: Color3, material: Enum.Material?): BasePart
	return piece(name, Vector3.new(w, t, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), colour, material)
end
-- A kit model scaled to `size` (height, or width when wide), its foot at cf.
local function kit(name: string, cf: CFrame, size: number, wide: boolean?, tint: Color3?, isSolid: boolean?): Model
	local src = PropKit:FindFirstChild(name)
	if not src then
		error("the kit has no " .. name)
	end
	local m = src:Clone() :: Model
	m.PrimaryPart = nil
	m:PivotTo(CFrame.new())
	local _, raw = m:GetBoundingBox()
	local ref = if wide then math.max(raw.X, raw.Z) else raw.Y
	m:ScaleTo(m:GetScale() * size / math.max(ref, 0.01))
	m:PivotTo(cf)
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = isSolid == true
			d.CanCollide = isSolid == true
			d.CastShadow = isSolid == true
			if isSolid and d:IsA("MeshPart") then
				d.CollisionFidelity = Enum.CollisionFidelity.Box
			end
			if tint then
				local sa = d:FindFirstChildOfClass("SurfaceAppearance")
				if sa then
					sa.Color = tint
				else
					d.Color = tint
				end
			end
		end
	end
	m.Parent = model
	return m
end
local function light(at: CFrame, colour: Color3, brightness: number, range: number)
	local h = piece("Glow", Vector3.one * 0.3, at, colour)
	h.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color = colour
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = h
end

-- The stall's frame: at its spot, its front (-Z) looking at the fountain.
local frame = F * CFrame.lookAt(Vector3.new(SPOT.x, G, SPOT.z), Vector3.new(0, G, 0))
local function L(x: number, y: number, z: number): CFrame
	return frame * CFrame.new(x, y, z)
end
local function V(x: number, y: number, z: number): Vector3
	return L(x, y, z).Position
end

-- ===== the frame: four lashed posts, beams, knee braces =====
local W, D = 24, 14
local FRONT, BACK = -D / 2, D / 2
local FRONT_H, BACK_H = 12.5, 16.6
local function post(at: CFrame, tall: number, w: number)
	solid(piece("Post", Vector3.new(w, tall, w), at * CFrame.new(0, tall / 2, 0), WOOD, Mat.Wood))
	piece("PostFoot", Vector3.new(w + 0.8, 0.6, w + 0.8), at * CFrame.new(0, 0.3, 0), STONE, Mat.Slate)
	ball("PostKnob", w + 0.3, at * CFrame.new(0, tall + 0.2, 0), WOOD_DARK, Mat.Wood)
end
local function lashing(at: CFrame, d: number, h: number)
	cylinder("RopeBand", d, h, at, ROPE)
end
for _, x in { -W / 2, W / 2 } do
	post(L(x, 0, FRONT), FRONT_H, 1.7)
	post(L(x, 0, BACK), BACK_H, 1.7)
	lashing(L(x, FRONT_H - 1.2, FRONT), 2.5, 1)
	lashing(L(x, 5, FRONT), 2.4, 0.7)
	lashing(L(x, BACK_H - 1.2, BACK), 2.5, 1)
	local inward = if x > 0 then -1 else 1
	bar("Brace", V(x, FRONT_H - 4, FRONT), V(x + inward * 3.2, FRONT_H - 0.6, FRONT), 0.8, 0.8, WOOD_DARK, Mat.Wood)
	bar("SideRail", V(x, FRONT_H - 0.6, FRONT), V(x, BACK_H - 0.6, BACK), 0.9, 0.9, WOOD, Mat.Wood)
end
cylinder("FrontBeam", 1.2, W + 5, L(0, FRONT_H - 0.3, FRONT - 0.4) * CFrame.Angles(0, 0, math.rad(90)), WOOD_LIGHT, Mat.Wood)
cylinder("BackBeam", 1.2, W + 6, L(0, BACK_H - 0.3, BACK) * CFrame.Angles(0, 0, math.rad(90)), WOOD_LIGHT, Mat.Wood)

-- ===== the awning: cream and blue stripes in two slopes, scallops with a gold edge, the middle stripe blue with the crest =====
local STRIPES = 5
local top = Vector3.new(0, 17.7, BACK + 0.9)
local mid = Vector3.new(0, 15.8, -2.6)
local edge = Vector3.new(0, 11.6, FRONT - 2.8)
local span = W + 3.6
local sw = span / STRIPES
for k = 1, STRIPES do
	local x = -span / 2 + (k - 0.5) * sw
	local colour = if k % 2 == 1 then CREAM else BLUE
	local a0, a1, a2 = V(x, top.Y, top.Z), V(x, mid.Y, mid.Z), V(x, edge.Y, edge.Z)
	bar("AwningUpper", a0, a1:Lerp(a2, 0.14), sw + 0.02, 0.4, colour).CastShadow = true
	bar("AwningLower", a1:Lerp(a0, 0.12), a2, sw + 0.02, 0.4, colour).CastShadow = true
	local slope = CFrame.lookAt(a1, a2)
	local foot = CFrame.new(a2) * (slope - slope.Position)
	local disc = piece("Scallop", Vector3.new(0.3, sw, sw), foot * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), colour) :: Part
	disc.Shape = Enum.PartType.Cylinder
	local rim = piece("ScallopEdge", Vector3.new(0.2, sw + 0.55, sw + 0.55), foot * CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD) :: Part
	rim.Shape = Enum.PartType.Cylinder
end
for _, x in { -span / 2, span / 2 } do
	bar("AwningSide", V(x, top.Y - 0.5, top.Z), V(x, mid.Y - 0.5, mid.Z), 0.3, 1.1, GOLD)
	bar("AwningSide", V(x, mid.Y - 0.5, mid.Z), V(x, edge.Y - 0.5, edge.Z), 0.3, 1.1, GOLD)
end
bar("AwningRidge", V(-span / 2, top.Y + 0.1, top.Z), V(span / 2, top.Y + 0.1, top.Z), 0.5, 0.7, WOOD_DARK, Mat.Wood)
-- the crest on the awning's middle stripe, facing out
kit("MoneyBagCrest", L(0, 13.6, -4.9) * CFrame.Angles(math.rad(-28), 0, 0), 2.6)

-- the arched board over the ridge with the crest, as in the picture
do
	local board = L(0, 20.6, BACK + 0.4)
	piece("TopBoard", Vector3.new(11, 3.6, 0.6), board, WOOD_LIGHT, Mat.Wood).CastShadow = true
	piece("TopBoardCap", Vector3.new(11.8, 0.5, 0.9), board * CFrame.new(0, 1.9, 0), WOOD_DARK, Mat.Wood)
	piece("TopBoardFoot", Vector3.new(11.8, 0.5, 0.9), board * CFrame.new(0, -1.9, 0), WOOD_DARK, Mat.Wood)
	for _, sx in { -1, 1 } do
		bar("TopBoardLeg", V(sx * 4.5, BACK_H - 0.2, BACK + 0.4), V(sx * 4.5, 19, BACK + 0.4), 0.6, 0.6, WOOD_DARK, Mat.Wood)
	end
	kit("MoneyBagCrest", board * CFrame.new(0, -1.3, -0.4), 2.6)
end

-- ===== the furnace at the back: a stone kiln with an arched mouth of fire, a chimney through the awning's back =====
do
	local base = L(3.5, 0, BACK - 3.4)
	solid(cylinder("FurnaceBody", 7.2, 7.4, base * CFrame.new(0, 3.7, 0), STONE, Mat.Cobblestone))
	piece("FurnacePlinth", Vector3.new(8.4, 0.9, 8.4), base * CFrame.new(0, 0.45, 0), STONE_DARK, Mat.Slate)
	ball("FurnaceDome", 7.2, base * CFrame.new(0, 7.4, 0), STONE, Mat.Cobblestone)
	cylinder("FurnaceBand", 7.5, 0.6, base * CFrame.new(0, 6.6, 0), IRON, Mat.Metal)
	cylinder("Chimney", 2.4, 8, base * CFrame.new(0, 13.4, 0.6), STONE_DARK, Mat.Cobblestone)
	cylinder("ChimneyCap", 3, 0.6, base * CFrame.new(0, 17.4, 0.6), IRON, Mat.Metal)
	-- the mouth: a dark arch set into the front, coals glowing in it, an iron lip
	local mouth = base * CFrame.new(0, 2.8, -3.35)
	piece("FurnaceMouth", Vector3.new(3.2, 2.4, 0.6), mouth, Color3.fromRGB(40, 24, 18))
	local arch = piece("FurnaceArch", Vector3.new(0.6, 3.2, 3.2), mouth * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(40, 24, 18), nil, "Part") :: Part
	arch.Shape = Enum.PartType.Cylinder
	arch.CFrame = mouth * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.rad(90), 0)
	piece("Coals", Vector3.new(2.8, 0.7, 0.4), mouth * CFrame.new(0, -0.7, -0.15), EMBER, Mat.Neon)
	piece("FurnaceLip", Vector3.new(4.2, 0.5, 1.2), mouth * CFrame.new(0, -1.45, -0.3), IRON, Mat.Metal)
	light(mouth * CFrame.new(0, 0, -1.2), EMBER, 2.2, 16)
	-- stacked logs beside it
	for k = 0, 2 do
		cylinder("Log", 1.1, 3.6, base * CFrame.new(-5.4 + k * 0.1, 0.55 + k * 0.95, 0.6 - (k % 2) * 0.5) * CFrame.Angles(math.rad(90), 0, 0), WOOD_DARK, Mat.Wood)
	end
end

-- ===== the anvil on a stump, in front, the hammer resting on it =====
do
	local base = L(1.5, 0, FRONT + 1.6) * CFrame.Angles(0, math.rad(12), 0)
	solid(cylinder("Stump", 2.8, 2.2, base * CFrame.new(0, 1.1, 0), WOOD, Mat.Wood))
	cylinder("StumpRing", 2.9, 0.3, base * CFrame.new(0, 1.9, 0), WOOD_DARK, Mat.Wood)
	local a = base * CFrame.new(0, 2.2, 0)
	piece("AnvilFoot", Vector3.new(2.6, 0.5, 1.8), a * CFrame.new(0, 0.25, 0), IRON, Mat.Metal)
	piece("AnvilWaist", Vector3.new(1.4, 0.8, 1), a * CFrame.new(0, 0.9, 0), IRON, Mat.Metal)
	piece("AnvilFace", Vector3.new(3.2, 0.7, 1.5), a * CFrame.new(-0.2, 1.65, 0), IRON_LIGHT, Mat.Metal)
	-- the horn, a wedge tapering out of the face
	piece("AnvilHorn", Vector3.new(1.2, 0.7, 1.6), a * CFrame.new(2.1, 1.65, 0) * CFrame.Angles(0, math.rad(-90), 0), IRON_LIGHT, Mat.Metal, "WedgePart")
	-- the hammer
	local h = a * CFrame.new(-0.6, 2.15, 0.1) * CFrame.Angles(0, math.rad(25), 0)
	piece("HammerHead", Vector3.new(0.6, 0.6, 1.3), h, IRON, Mat.Metal)
	piece("HammerHandle", Vector3.new(2.4, 0.28, 0.28), h * CFrame.new(1.3, -0.05, 0), WOOD_LIGHT, Mat.Wood)
end

-- ===== along the sides: a weapon rack and a barrel of swords on the left, the armour stand, water barrel and tools on the right =====
kit("WeaponRack", L(-W / 2 + 4.2, 0, 0.6) * CFrame.Angles(0, math.rad(90), 0), 6.4, false, nil, true)
kit("SwordBarrel", L(-W / 2 + 3, 0, -4.4) * CFrame.Angles(0, 0.6, 0), 4.2, false, nil, true)
kit("ArmorStand", L(-4.5, 0, BACK - 3) * CFrame.Angles(0, math.pi, 0), 6.8, false, nil, true)
do
	local barrel = L(W / 2 - 2.8, 0, -3.6)
	local b = kit("WoodBarrel", barrel, 4, false, nil, true)
	local _, size = b:GetBoundingBox()
	cylinder("Water", size.X * 0.78, 0.2, barrel * CFrame.new(0, size.Y - 0.3, 0), WATER, Mat.Glass).Transparency = 0.25
end
kit("ToolRack", L(W / 2 - 3.2, 0, BACK - 3.2) * CFrame.Angles(0, math.rad(-90), 0), 5.4, false, nil, true)

-- ===== a lantern on the left front post, a blue banner on the right =====
do
	local hang = L(-W / 2 - 1.6, FRONT_H - 1.6, FRONT)
	bar("LanternArm", V(-W / 2, FRONT_H - 1.6, FRONT), hang.Position, 0.5, 0.5, WOOD_LIGHT, Mat.Wood)
	kit("WoodLantern", hang * CFrame.new(0, -3, 0), 2.8)
	light(hang * CFrame.new(0, -1.8, 0), GLOW, 0.9, 13)
	-- the banner: blue with a gold edge and two crossed swords, on its own pole (the kit's flag is red and will not tint)
	local pole = L(W / 2 + 1.8, 0, FRONT + 0.2)
	cylinder("BannerPole", 0.5, 11, pole * CFrame.new(0, 5.5, 0), WOOD_DARK, Mat.Wood)
	ball("BannerKnob", 0.9, pole * CFrame.new(0, 11.2, 0), GOLD)
	bar("BannerArm", V(W / 2 + 1.8, 10.4, FRONT + 0.2), V(W / 2 + 1.8, 10.4, FRONT - 2.6), 0.4, 0.4, WOOD_DARK, Mat.Wood)
	local cloth = pole * CFrame.new(0, 7.6, -1.4) * CFrame.Angles(0, math.rad(90), 0)
	piece("BannerEdge", Vector3.new(2.9, 5.4, 0.16), cloth, GOLD)
	piece("Banner", Vector3.new(2.5, 5, 0.2), cloth, BLUE)
	for _, s in { -1, 1 } do
		local swordAt = cloth * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(s * 35))
		for _, face in { -1, 1 } do
			piece("BannerSword", Vector3.new(0.3, 3.2, 0.1), swordAt * CFrame.new(0, 0, face * 0.14), CREAM)
			piece("BannerHilt", Vector3.new(1, 0.25, 0.1), swordAt * CFrame.new(0, -1.1, face * 0.15), GOLD)
		end
	end
end

-- the keeper's spot behind the anvil (no slime here: the owner places the blacksmith slime himself)
do
	local spot = piece("KeeperSpot", Vector3.new(2, 0.2, 2), L(1.5, 0.1, FRONT + 4.6) * CFrame.Angles(0, math.pi, 0), WOOD)
	spot.Transparency = 1
end

model.Parent = market
local count = 0
for _, d in model:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
	end
end
return string.format("SMITHY OK: %d parts at local (%d, %d)", count, SPOT.x, SPOT.z)
