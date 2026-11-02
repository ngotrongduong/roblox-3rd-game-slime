-- Builds the Market square of the valley (workspace.Map.Market) and dresses what stands round it, from the reference art/concept/market-1.jpg
-- and the owner's stall art (reference/goo-lineage-web/assets/map/other/shop-*.png, shape and colour only). Places come from Config.Market:
-- the frame's -Z looks at the valley centre, +x is the left of someone walking in. The code finds SlimeBuyer, VipStall, Leaderboard (with its
-- part Screen, whose Front face looks at the square); the prompts stand at Config.Market's spots whatever is built here.
-- Run in Edit mode, as often as wanted (it removes what it made and paints the ground again):
--   node tools/studio_mcp.js run tools/map/build_market.luau <studio_id> Edit
-- Run it again after tools/map/build_wild_slices.luau, which resets the ground outside the ring road to grass. tools/map/market_kit_square.luau
-- ran once on the generated models. Then tools/map/check_market.luau must end MARKET OK.
-- Kit models come from ServerStorage.PropKit and WildKit: nothing is read at run time, it travels with the owner's save.
-- The floor: real terrain earth (Sandstone = WildDirt, Asphalt = WildWorn, as the valley's roads) under flat flagstones of the valley's own
-- pebble mesh, not stud tiles: this is an open-air square of the valley, not a built floor, and the reference is a dirt yard with stones.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")
local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PropKit, WildKit = ServerStorage.PropKit, ServerStorage.WildKit
local M = Config.Map
-- (the work place's copy of Config can be older than the repo: the same values as src/shared/Config.luau's Config.Market)
local C = Config.Market
	or {
		Landing = { x = 0, z = -56 },
		Buyer = { x = 55, z = -8 },
		Vip = { x = -55, z = -8 },
		Board = { x = 0, z = 62 },
		Model = "Market",
		BuyerModel = "SlimeBuyer",
		VipModel = "VipStall",
		BoardModel = "Leaderboard",
		ScreenName = "Screen",
	}
local F = Layout.marketFrame()
local G = M.GroundY
local rng = Random.new(20261102)
local Mat = Enum.Material

local root = workspace.Map:FindFirstChild(C.Model)
if not root then
	root = Instance.new("Model")
	root.Name = C.Model
	root.Parent = workspace.Map
end
for _, child in root:GetChildren() do
	if child.Name ~= "Spawn" then
		child:Destroy()
	end
end
local function group(name: string, class: string?, parent: Instance?): Instance
	local g = Instance.new(class or "Model")
	g.Name = name
	g.Parent = parent or root
	return g
end

-- ===== the palette (the owner's stall art, docs/reference/03) =====
local WOOD = Color3.fromRGB(205, 142, 66)
local WOOD_LIGHT = Color3.fromRGB(224, 166, 88)
local WOOD_DARK = Color3.fromRGB(150, 96, 46)
local ROPE = Color3.fromRGB(226, 196, 138)
local BLUE = Color3.fromRGB(46, 92, 196)
local BLUE_DEEP = Color3.fromRGB(38, 66, 150)
local CREAM = Color3.fromRGB(246, 234, 204)
local GOLD = Color3.fromRGB(246, 190, 56)
local PURPLE = Color3.fromRGB(122, 52, 170)
local PURPLE_DEEP = Color3.fromRGB(84, 36, 124)
local STONE = Color3.fromRGB(172, 166, 150)
local STONE_DARK = Color3.fromRGB(140, 134, 122)
local GLOW = Color3.fromRGB(255, 206, 110)
local WHITE = Color3.new(1, 1, 1)
local FLAG_TINTS = { Color3.fromRGB(226, 214, 190), Color3.fromRGB(206, 196, 176), Color3.fromRGB(190, 182, 166), Color3.fromRGB(216, 200, 170) }
local TUFT = Color3.fromRGB(240, 255, 200)

-- ===== pieces =====
local function piece(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?, class: string?): BasePart
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
	p.Parent = parent
	return p
end
local function solid(p: BasePart): BasePart
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = true
	return p
end
-- a cylinder standing along cf's Y
local function cylinder(parent: Instance, name: string, d: number, h: number, cf: CFrame, colour: Color3, material: Enum.Material?): BasePart
	local p = piece(parent, name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), colour, material) :: Part
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(parent: Instance, name: string, d: number, cf: CFrame, colour: Color3, material: Enum.Material?): BasePart
	local p = piece(parent, name, Vector3.one * d, cf, colour, material) :: Part
	p.Shape = Enum.PartType.Ball
	return p
end
-- a thin bar from a to b (its length along Z, its top along `up` as far as lookAt keeps it)
local function bar(parent: Instance, name: string, a: Vector3, b: Vector3, w: number, t: number, colour: Color3, material: Enum.Material?): BasePart
	return piece(parent, name, Vector3.new(w, t, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), colour, material)
end
-- a triangle cloth in c's XY plane. Down: its top edge centred on c, the point below. Up: its base centred on c, the point above.
local function triangle(parent: Instance, name: string, c: CFrame, w: number, h: number, colour: Color3, material: Enum.Material?, up: boolean?)
	local t = 0.14
	for side = -1, 1, 2 do
		-- (a wedge's right angle is at its +Z foot: turn +Z to the middle of the triangle)
		local turn = CFrame.Angles(0, math.rad(-side * 90), 0)
		local cf
		if up then
			cf = c * CFrame.new(side * w / 4, h / 2, 0) * turn
		else
			cf = c * CFrame.new(side * w / 4, -h / 2, 0) * turn * CFrame.Angles(0, 0, math.pi)
		end
		piece(parent, name, Vector3.new(t, h, w / 2), cf, colour, material, "WedgePart")
	end
end

-- A kit model as a Model: scaled to `size` (height, or width when wide), its foot at cf.
local function kit(parent: Instance, from: Instance, name: string, cf: CFrame, size: number, wide: boolean?, tint: Color3?, isSolid: boolean?): Model
	local src = from:FindFirstChild(name)
	if not src then
		error("the kit has no " .. name)
	end
	local model = src:Clone() :: Model
	model.PrimaryPart = nil
	model:PivotTo(CFrame.new())
	local _, raw = model:GetBoundingBox()
	local ref = if wide then math.max(raw.X, raw.Z) else raw.Y
	model:ScaleTo(model:GetScale() * size / math.max(ref, 0.01))
	model:PivotTo(cf)
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = false
			d.CanCollide = false
			d.CastShadow = false
			if isSolid then
				d.CanCollide = true
				d.CanQuery = true
				d.CastShadow = true
				if d:IsA("MeshPart") then
					d.CollisionFidelity = Enum.CollisionFidelity.Box
				end
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
	model.Parent = parent
	return model
end
-- A spot on the market's ground: local x, height above the ground, z, a turn about Y.
local function at(x: number, y: number, z: number, yaw: number?): CFrame
	return F * CFrame.new(x, G + y, z) * CFrame.Angles(0, yaw or 0, 0)
end
-- Looking from (x, z) at (tx, tz): the kit's front, -Z, faces it.
local function facing(x: number, z: number, tx: number, tz: number, y: number?): CFrame
	return F * CFrame.lookAt(Vector3.new(x, G + (y or 0), z), Vector3.new(tx, G + (y or 0), tz))
end

-- A hanging lantern: the kit's lantern under a ring, with a soft light only when lit.
local function lantern(parent: Instance, top: CFrame, tall: number, lit: boolean)
	local cf = top * CFrame.new(0, -tall, 0)
	local m = kit(parent, PropKit, "WoodLantern", cf, tall)
	if lit then
		local h = piece(parent, "LanternGlow", Vector3.one * 0.3, cf * CFrame.new(0, tall * 0.42, 0), GLOW)
		h.Transparency = 1
		local light = Instance.new("PointLight")
		light.Color = GLOW
		light.Brightness = 0.9
		light.Range = 13
		light.Shadows = false
		light.Parent = h
	end
	return m
end
-- A wicker basket of gold, built: the generated ones came back untextured or shredded (twice).
local function coinBasket(parent: Instance, cf: CFrame, across: number, full: boolean?)
	local deep, tall = across * 0.8, across * 0.42
	local weave = Color3.fromRGB(222, 178, 104)
	piece(parent, "Basket", Vector3.new(across, tall, deep), cf * CFrame.new(0, tall / 2, 0), weave, Mat.WoodPlanks)
	for k = 0, 2 do
		piece(parent, "BasketBand", Vector3.new(across + 0.1, across * 0.05, deep + 0.1), cf * CFrame.new(0, tall * (0.2 + k * 0.3), 0), Color3.fromRGB(190, 142, 74), Mat.WoodPlanks)
	end
	local rim = across * 0.1
	for _, s in { -1, 1 } do
		piece(parent, "BasketRim", Vector3.new(across + rim, rim, rim), cf * CFrame.new(0, tall, s * deep / 2), WOOD_LIGHT, Mat.Wood)
		piece(parent, "BasketRim", Vector3.new(rim, rim, deep + rim), cf * CFrame.new(s * across / 2, tall, 0), WOOD_LIGHT, Mat.Wood)
	end
	piece(parent, "BasketGold", Vector3.new(across * 0.86, rim * 0.8, deep * 0.84), cf * CFrame.new(0, tall + rim * 0.2, 0), GOLD)
	if full ~= false then
		kit(parent, PropKit, "CoinStack", cf * CFrame.new(0, tall + rim * 0.2, 0) * CFrame.Angles(0, across, 0), across * 0.72, true)
	end
end
local function lashing(parent: Instance, cf: CFrame, d: number, h: number)
	cylinder(parent, "RopeBand", d, h, cf, ROPE, Mat.Fabric)
end
-- A squared timber post with a stone foot and a darker cap.
local function post(parent: Instance, x: CFrame, tall: number, w: number)
	solid(piece(parent, "Post", Vector3.new(w, tall, w), x * CFrame.new(0, tall / 2, 0), WOOD, Mat.Wood))
	piece(parent, "PostFoot", Vector3.new(w + 0.8, 0.6, w + 0.8), x * CFrame.new(0, 0.3, 0), STONE_DARK, Mat.Slate)
	piece(parent, "PostCap", Vector3.new(w + 0.3, 0.3, w + 0.3), x * CFrame.new(0, tall + 0.15, 0), WOOD_DARK, Mat.Wood)
end

-- ===== the stalls =====
type Style = { a: Color3, b: Color3, trim: Color3, cloth: Color3, clothEdge: Color3, crest: string, royal: boolean }
local W, D = 26, 12 -- between the posts, across and deep
local STRIPES = 7
local function buildStall(name: string, spot: { x: number, z: number }, style: Style): Model
	local model = group(name) :: Model
	local dx, dz = C.Landing.x - spot.x, C.Landing.z - spot.z
	local len = math.sqrt(dx * dx + dz * dz)
	dx, dz = dx / len, dz / len
	-- the prompt's spot stands over the counter's middle, 3.5 in from the stall's own centre line
	local px, pz = spot.x - dx * 3.5, spot.z - dz * 3.5
	local frame = facing(px, pz, px + dx, pz + dz)
	local function L(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local function V(x: number, y: number, z: number): Vector3
		return L(x, y, z).Position
	end

	-- the frame: two low front posts, two tall back posts, beams, knee braces, rope lashings
	local FRONT, BACK = -D / 2, D / 2
	local FRONT_H, BACK_H = 12, 16.6
	for _, x in { -W / 2, W / 2 } do
		post(model, L(x, 0, FRONT), FRONT_H, 1.7)
		post(model, L(x, 0, BACK), BACK_H, 1.7)
		lashing(model, L(x, FRONT_H - 1.2, FRONT), 2.5, 1)
		lashing(model, L(x, 5.4, FRONT), 2.4, 0.7)
		lashing(model, L(x, BACK_H - 1.2, BACK), 2.5, 1)
		local inward = if x > 0 then -1 else 1
		bar(model, "Brace", V(x, FRONT_H - 4, FRONT), V(x + inward * 3.2, FRONT_H - 0.6, FRONT), 0.8, 0.8, WOOD_DARK, Mat.Wood)
		bar(model, "SideRail", V(x, FRONT_H - 0.6, FRONT), V(x, BACK_H - 0.6, BACK), 0.9, 0.9, WOOD, Mat.Wood)
	end
	cylinder(model, "FrontBeam", 1.2, W + 5, L(0, FRONT_H - 0.3, FRONT - 0.4) * CFrame.Angles(0, 0, math.rad(90)), WOOD_LIGHT, Mat.Wood)
	cylinder(model, "BackBeam", 1.2, W + 7, L(0, BACK_H - 0.3, BACK) * CFrame.Angles(0, 0, math.rad(90)), WOOD_LIGHT, Mat.Wood)

	-- the counter: 3 high, slats on a solid body, an overhanging top
	local cz, cd = -3, 4.4
	solid(piece(model, "CounterBody", Vector3.new(W - 1.5, 2.6, cd - 0.3), L(0, 1.3, cz), WOOD_DARK, Mat.Wood))
	solid(piece(model, "CounterTop", Vector3.new(W + 0.4, 0.5, cd + 0.9), L(0, 2.8, cz), WOOD_LIGHT, Mat.Wood))
	piece(model, "CounterFoot", Vector3.new(W - 0.6, 0.5, cd + 0.3), L(0, 0.25, cz), WOOD_DARK, Mat.Wood)
	local slats = 12
	for k = 1, slats do
		local sw = (W - 2) / slats
		local x = -(W - 2) / 2 + (k - 0.5) * sw
		piece(model, "CounterSlat", Vector3.new(sw - 0.16, 2.1, 0.22), L(x, 1.5, cz - cd / 2 - 0.02), if k % 2 == 0 then WOOD else WOOD_LIGHT, Mat.Wood)
	end
	-- the cloth over the counter: on the top, down the front, a point with a gold edge, its crest
	local fz = cz - cd / 2 - 0.5
	piece(model, "ClothTop", Vector3.new(10, 0.12, cd + 1), L(0, 3.1, cz), style.cloth, Mat.Fabric)
	piece(model, "ClothFront", Vector3.new(10, 1.7, 0.14), L(0, 2.2, fz), style.cloth, Mat.Fabric)
	piece(model, "ClothEdgeL", Vector3.new(0.5, 1.7, 0.18), L(-4.75, 2.2, fz - 0.02), style.clothEdge, Mat.Fabric)
	piece(model, "ClothEdgeR", Vector3.new(0.5, 1.7, 0.18), L(4.75, 2.2, fz - 0.02), style.clothEdge, Mat.Fabric)
	triangle(model, "ClothEdgePoint", L(0, 1.36, fz + 0.02), 10, 1.2, style.clothEdge, Mat.Fabric)
	triangle(model, "ClothPoint", L(0, 1.36, fz - 0.06), 8.8, 0.95, style.cloth, Mat.Fabric)
	kit(model, PropKit, style.crest, L(0, 0.9, fz - 0.16) , 2.4)

	-- the awning: stripes in two slopes, the lower steeper, so it reads rounded; a scallop on each stripe with a gold edge behind
	local top = Vector3.new(0, 17.7, BACK + 0.9)
	local mid = Vector3.new(0, 15.8, -2.6)
	local edge = Vector3.new(0, 11.4, -D / 2 - 2.8)
	local span = W + 3.6
	local sw = span / STRIPES
	for k = 1, STRIPES do
		local x = -span / 2 + (k - 0.5) * sw
		local colour = if k % 2 == 1 then style.a else style.b
		local a0, a1, a2 = V(x, top.Y, top.Z), V(x, mid.Y, mid.Z), V(x, edge.Y, edge.Z)
		-- (each runs a little past the crease: two slopes that only meet leave a slit on the outside of the bend)
		bar(model, "AwningUpper", a0, a1:Lerp(a2, 0.08), sw + 0.02, 0.4, colour, Mat.Fabric).CastShadow = true
		bar(model, "AwningLower", a1:Lerp(a0, 0.05), a2, sw + 0.02, 0.4, colour, Mat.Fabric).CastShadow = true
		local slope = CFrame.lookAt(a1, a2)
		local foot = CFrame.new(a2) * (slope - slope.Position)
		local disc = piece(model, "Scallop", Vector3.new(0.3, sw, sw), foot * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), colour, Mat.Fabric) :: Part
		disc.Shape = Enum.PartType.Cylinder
		local rim = piece(model, "ScallopEdge", Vector3.new(0.2, sw + 0.55, sw + 0.55), foot * CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), style.trim, Mat.SmoothPlastic) :: Part
		rim.Shape = Enum.PartType.Cylinder
		if style.royal then
			-- a gold tassel where two scallops meet
			if k < STRIPES then
				local tx = x + sw / 2
				local tp = L(tx, edge.Y - 1.2, edge.Z - 0.3)
				ball(model, "TasselKnot", 0.6, tp, GOLD)
				cylinder(model, "Tassel", 0.5, 1.2, tp * CFrame.new(0, -0.8, 0), GOLD, Mat.Fabric)
			end
		end
	end
	-- the awning's sides: a band along each edge
	for _, x in { -span / 2, span / 2 } do
		bar(model, "AwningSide", V(x, top.Y - 0.5, top.Z), V(x, mid.Y - 0.5, mid.Z), 0.3, 1.1, style.trim, Mat.Fabric)
		bar(model, "AwningSide", V(x, mid.Y - 0.5, mid.Z), V(x, edge.Y - 0.5, edge.Z), 0.3, 1.1, style.trim, Mat.Fabric)
	end
	bar(model, "AwningRidge", V(-span / 2, top.Y + 0.1, top.Z), V(span / 2, top.Y + 0.1, top.Z), 0.5, 0.7, style.trim, Mat.Fabric)

	-- what it sells: two baskets of gold on the counter, stacks of coins beside them, a lantern under the beam
	for _, x in { -6.6, 6.6 } do
		coinBasket(model, L(x, 3.05, cz + 0.3) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), 4.2)
	end
	kit(model, PropKit, "CoinStack", L(-10.8, 3.05, cz - 0.4), 2.8, true)
	lantern(model, L(-7, FRONT_H - 1, FRONT + 1), 2.6, true)
	lantern(model, L(7, FRONT_H - 1, FRONT + 1), 2.6, not style.royal)
	cylinder(model, "LanternRope", 0.14, 0.9, L(-7, FRONT_H - 0.6, FRONT + 1), ROPE, Mat.Fabric)
	cylinder(model, "LanternRope", 0.14, 0.9, L(7, FRONT_H - 0.6, FRONT + 1), ROPE, Mat.Fabric)
	return model
end

-- The buyer: blue and cream, a hanging sign on its own tall post, sacks and a barrel beside the counter.
local function frameOf(spot: { x: number, z: number }): CFrame
	local dx, dz = C.Landing.x - spot.x, C.Landing.z - spot.z
	local len = math.sqrt(dx * dx + dz * dz)
	dx, dz = dx / len, dz / len
	local px, pz = spot.x - dx * 3.5, spot.z - dz * 3.5
	return facing(px, pz, px + dx, pz + dz)
end

local buyer = buildStall(C.BuyerModel, C.Buyer, {
	a = CREAM,
	b = BLUE,
	trim = GOLD,
	cloth = BLUE,
	clothEdge = GOLD,
	crest = "MoneyBagCrest",
	royal = false,
})
do
	local frame = frameOf(C.Buyer)
	-- the sign's own tall post stands at the stall's inner end (-X, towards the fountain), so the Landing's view holds it; its arm reaches over the awning
	local x = W / 2 + 2.6
	local base = frame * CFrame.new(-x, 0, -D / 2 - 3) * CFrame.Angles(0, math.pi, 0)
	post(buyer, base, 21, 1.8)
	bar(buyer, "SignArm", (base * CFrame.new(-1, 19.6, 0)).Position, (base * CFrame.new(12, 19.6, 0)).Position, 1.1, 1.1, WOOD_LIGHT, Mat.Wood)
	lashing(buyer, base * CFrame.new(0, 19.6, 0), 2.5, 1.3)
	bar(buyer, "SignBrace", (base * CFrame.new(0, 15.8, 0)).Position, (base * CFrame.new(3.8, 19.4, 0)).Position, 0.7, 0.7, WOOD_DARK, Mat.Wood)
	local sign = frame * CFrame.new(-x + 7.2, 15.6, -D / 2 - 3.1)
	piece(buyer, "SignBoard", Vector3.new(8.6, 4.8, 0.5), sign, WOOD_LIGHT, Mat.Wood).CastShadow = true
	piece(buyer, "SignEdgeTop", Vector3.new(9, 0.45, 0.7), sign * CFrame.new(0, 2.4, 0), WOOD_DARK, Mat.Wood)
	piece(buyer, "SignEdgeLow", Vector3.new(9, 0.45, 0.7), sign * CFrame.new(0, -2.4, 0), WOOD_DARK, Mat.Wood)
	for _, sx in { -3, 3 } do
		cylinder(buyer, "SignRope", 0.2, 2, base * CFrame.new(7.2 + sx, 18.6, 0), ROPE, Mat.Fabric)
	end
	kit(buyer, PropKit, "MoneySack", sign * CFrame.new(0, -1.9, -0.32), 3.8, false, GOLD)
	-- by the counter
	kit(buyer, WildKit, "QtBush_Common_Green", frame * CFrame.new(x + 3, 0, 3), 7, true)
	kit(buyer, PropKit, "WoodBarrel", frame * CFrame.new(W / 2 + 2.4, 0, -6.4) * CFrame.Angles(0, 1, 0), 4.2, false, nil, true)
	kit(buyer, PropKit, "MoneySack", frame * CFrame.new(-W / 2 + 2.4, 0, -8.2) * CFrame.Angles(0, -0.6, 0), 3)
	coinBasket(buyer, frame * CFrame.new(W / 2 - 3, 0, -8.4) * CFrame.Angles(0, 0.3, 0), 5)
end

local vip = buildStall(C.VipModel, C.Vip, {
	a = PURPLE,
	b = PURPLE_DEEP,
	trim = GOLD,
	cloth = PURPLE,
	clothEdge = GOLD,
	crest = "CrownCrest",
	royal = true,
})
do
	local frame = frameOf(C.Vip)
	-- the back curtain in folds, a tied curtain at each front post, gold knobs, the crown crest on top
	local folds = 13
	local BACK_Z = D / 2 + 0.4
	for k = 1, folds do
		local fw = (W + 1) / folds
		local x = -(W + 1) / 2 + (k - 0.5) * fw
		piece(vip, "BackCurtain", Vector3.new(fw + 0.05, 15.6, 0.3), frame * CFrame.new(x, 7.8, BACK_Z + (k % 2) * 0.22), if k % 2 == 0 then PURPLE_DEEP else Color3.fromRGB(102, 44, 148), Mat.Fabric).CastShadow = k == 7
	end
	for _, side in { -1, 1 } do
		local x = side * (W / 2 + 0.2)
		for j = 0, 2 do
			local fx = x - side * j * 0.9
			local top = frame * CFrame.new(fx, 0, -D / 2 - 0.5)
			cylinder(vip, "Curtain", 1.2, 6.4, top * CFrame.new(0, 9.2, 0), if j == 1 then PURPLE_DEEP else PURPLE, Mat.Fabric)
			cylinder(vip, "CurtainFoot", 1.1, 4.6, top * CFrame.new(0, 2.3, 0), if j == 1 then PURPLE_DEEP else PURPLE, Mat.Fabric)
		end
		local tie = frame * CFrame.new(x - side * 0.9, 5, -D / 2 - 0.5)
		piece(vip, "CurtainTie", Vector3.new(3, 1, 1.3), tie, GOLD, Mat.Fabric)
		ball(vip, "CurtainKnot", 0.9, tie * CFrame.new(0, 0, -0.9), GOLD)
		cylinder(vip, "CurtainTassel", 0.45, 1.6, tie * CFrame.new(0, -1.3, -0.95), GOLD, Mat.Fabric)
		-- gold knobs on the tall posts
		ball(vip, "PostKnob", 1.5, frame * CFrame.new(side * W / 2, 18.2, D / 2), GOLD)
	end
	kit(vip, PropKit, "CrownCrest", frame * CFrame.new(0, 15.6, D / 2 - 0.4), 7)
	local b = piece(vip, "CrestBar", Vector3.new(8, 0.6, 0.8), frame * CFrame.new(0, 15.9, D / 2 + 0.1), GOLD)
	b.CastShadow = false
	kit(vip, PropKit, "WoodBarrel", frame * CFrame.new(W / 2 + 2.6, 0, -6.8) * CFrame.Angles(0, 2, 0), 4.2, false, nil, true)
	kit(vip, PropKit, "MoneySack", frame * CFrame.new(W / 2 - 1.8, 0, -8.4) * CFrame.Angles(0, 0.5, 0), 3)
	coinBasket(vip, frame * CFrame.new(-W / 2 + 3, 0, -8.4) * CFrame.Angles(0, -0.3, 0), 5)
	kit(vip, WildKit, "QtBush_Common_Green", frame * CFrame.new(-W / 2 - 4, 0, 3), 7, true)
end

-- ===== the leaderboard =====
local board = group(C.BoardModel) :: Model
do
	local base = at(C.Board.x, 0, C.Board.z)
	local function B(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local SW, SH, SY = 30, 20, 9 -- the screen, its bottom above the ground
	-- The Screen: its Front (-Z, as the frame's) looks at the square; canvas 1,200 x 800 at Config.Leaderboard.PixelsPerStud.
	local screen = piece(board, C.ScreenName, Vector3.new(SW, SH, 0.6), B(0, SY + SH / 2, 0), Color3.fromRGB(70, 44, 30), Mat.Wood)
	screen.CanCollide = true
	screen.CanQuery = true
	-- legs and a backing, a thick honey frame with corner blocks
	for _, side in { -1, 1 } do
		post(board, B(side * (SW / 2 + 1.6), 0, 0.2), SY + SH + 3.6, 2.4)
		solid(piece(board, "Brace", Vector3.new(1.2, 8, 1.2), B(side * (SW / 2 + 1.6), 4.5, 3) * CFrame.Angles(math.rad(-32), 0, 0), WOOD_DARK, Mat.Wood))
		piece(board, "FrameSide", Vector3.new(1.3, SH + 1.8, 1), B(side * (SW / 2 + 0.55), SY + SH / 2, -0.3), WOOD_LIGHT, Mat.Wood)
		for _, y in { SY - 0.5, SY + SH + 0.5 } do
			piece(board, "FrameCorner", Vector3.new(2.4, 2.4, 1.3), B(side * (SW / 2 + 0.7), y, -0.45), GOLD)
		end
	end
	piece(board, "FrameTop", Vector3.new(SW + 2, 1.3, 1), B(0, SY + SH + 0.5, -0.3), WOOD_LIGHT, Mat.Wood)
	piece(board, "FrameLow", Vector3.new(SW + 2, 1.3, 1), B(0, SY - 0.5, -0.3), WOOD_LIGHT, Mat.Wood)
	solid(piece(board, "Backing", Vector3.new(SW + 2, SH + 2, 0.5), B(0, SY + SH / 2, 0.6), WOOD_DARK, Mat.Wood))
	piece(board, "LowRail", Vector3.new(SW + 3, 1.2, 1), B(0, 2, 0.2), WOOD, Mat.Wood)
	-- the shingled roof: rows of slate-blue tiles down the front, a plain back, a timber gable, the crest
	local eave, ridge = Vector3.new(0, SY + SH + 2.8, -6.5), Vector3.new(0, SY + SH + 8.4, 1.2)
	local ROWS, TILES = 5, 14
	local RW = SW + 10
	for r = 1, ROWS do
		local t = (r - 0.5) / ROWS
		local y = ridge.Y + (eave.Y - ridge.Y) * t
		local z = ridge.Z + (eave.Z - ridge.Z) * t
		local slope = CFrame.lookAt(Vector3.new(0, ridge.Y, ridge.Z), Vector3.new(0, eave.Y, eave.Z))
		local tile = RW / TILES
		for k = 1, TILES do
			local x = -RW / 2 + (k - 0.5 + (r % 2) * 0.25) * tile
			local rot = slope - slope.Position
			local p = piece(board, "Shingle", Vector3.new(tile + 0.15, 0.5, 2.3), base * (CFrame.new(x, y + (k % 2) * 0.05, z) * rot), if (k + r) % 3 == 0 then BLUE_DEEP else Color3.fromRGB(62, 80, 164), Mat.Slate)
			p.CastShadow = r == 1 and k % 3 == 0
		end
	end
	piece(board, "RoofBack", Vector3.new(RW, 0.5, 9), B(0, SY + SH + 6.3, 4.6) * CFrame.Angles(math.rad(36), 0, 0), BLUE_DEEP, Mat.Slate).CastShadow = true
	piece(board, "Ridge", Vector3.new(RW + 0.6, 0.8, 1), B(0, ridge.Y + 0.1, ridge.Z), WOOD_DARK, Mat.Wood)
	piece(board, "Eave", Vector3.new(RW + 0.6, 0.7, 0.7), B(0, eave.Y - 0.1, eave.Z - 0.4), WOOD_LIGHT, Mat.Wood)
	-- the gable in front of the roof, the money-bag crest in it
	local GY = SY + SH + 2.2
	triangle(board, "Gable", B(0, GY, -6.9), 21, 7, WOOD, Mat.Wood, true)
	bar(board, "GableBeam", B(-11.5, GY - 0.3, -7.2).Position, B(0.4, GY + 7.8, -7.2).Position, 1.1, 1.1, WOOD_LIGHT, Mat.Wood)
	bar(board, "GableBeam", B(11.5, GY - 0.3, -7.2).Position, B(-0.4, GY + 7.8, -7.2).Position, 1.1, 1.1, WOOD_LIGHT, Mat.Wood)
	kit(board, PropKit, "MoneyBagCrest", B(0, GY - 2.4, -7.7), 9)
	-- lanterns on the frame's shoulders
	for _, side in { -1, 1 } do
		local arm = B(side * (SW / 2 + 2.7), SY + SH - 1, -0.6)
		bar(board, "LanternArm", arm.Position, (arm * CFrame.new(side * 2.4, 0, 0)).Position, 0.5, 0.5, WOOD_DARK, Mat.Wood)
		lantern(board, arm * CFrame.new(side * 2, -0.2, 0), 3.2, true)
	end
	-- a low stone bed under the screen, full of flowers (the dressing below)
	for _, side in { -1, 1 } do
		kit(board, PropKit, "DryStoneWall", B(side * 10.2, 0, -6) , 2.8, false, nil, true)
	end
end

-- The banner posts either side of the board, the bunting strung from them to the stalls.
local banners = group("Banners")
local function bannerPost(x: number)
	local base = at(C.Board.x + x, 0, C.Board.z - 1)
	post(banners, base, 25, 1.8)
	bar(banners, "BannerBar", (base * CFrame.new(-4.5, 23.4, 0)).Position, (base * CFrame.new(4.5, 23.4, 0)).Position, 0.9, 0.9, WOOD_LIGHT, Mat.Wood)
	lashing(banners, base * CFrame.new(0, 23.4, 0), 2.5, 1.2)
	local cloth = base * CFrame.new(0, 16.5, -1.2)
	piece(banners, "Banner", Vector3.new(7, 12.4, 0.2), cloth, BLUE, Mat.Fabric).CastShadow = true
	for _, s in { -1, 1 } do
		piece(banners, "BannerEdge", Vector3.new(0.5, 12.4, 0.24), cloth * CFrame.new(s * 3.3, 0, -0.02), GOLD, Mat.Fabric)
	end
	piece(banners, "BannerTop", Vector3.new(7.4, 0.6, 0.4), cloth * CFrame.new(0, 6.2, 0), GOLD, Mat.Fabric)
	triangle(banners, "BannerPointEdge", cloth * CFrame.new(0, -6.2, 0), 7, 2.9, GOLD, Mat.Fabric)
	triangle(banners, "BannerPoint", cloth * CFrame.new(0, -6.2, -0.05), 6, 2.2, BLUE, Mat.Fabric)
	kit(banners, PropKit, "MoneySack", cloth * CFrame.new(0, -3, -0.2), 5.4, false, GOLD)
	for _, s in { -3, 3 } do
		cylinder(banners, "BannerRope", 0.2, 1, base * CFrame.new(s, 23, -1.2), ROPE, Mat.Fabric)
	end
end
bannerPost(23.5)
bannerPost(-23.5)

local function bunting(a: Vector3, b: Vector3, sag: number, count: number)
	local last = a
	for k = 1, count do
		local t = (k - 0.5) / count
		local s = 4 * t * (1 - t)
		local p = a:Lerp(b, t) - Vector3.new(0, sag * s, 0)
		local q = a:Lerp(b, k / count) - Vector3.new(0, sag * 4 * (k / count) * (1 - k / count), 0)
		bar(banners, "BuntingRope", last, q, 0.14, 0.14, ROPE, Mat.Fabric)
		local along = (q - last).Unit
		local c = CFrame.fromMatrix(p, along, Vector3.yAxis, along:Cross(Vector3.yAxis))
		triangle(banners, "Pennant", c, 2.9, 3.8, if k % 2 == 1 then BLUE else CREAM, Mat.Fabric)
		last = q
	end
end
local function stallEnd(spot: { x: number, z: number }): Vector3
	local f = frameOf(spot)
	local p0, p1 = f * CFrame.new(W / 2, 17.4, D / 2), f * CFrame.new(-W / 2, 17.4, D / 2)
	local target = at(C.Board.x, 0, C.Board.z).Position
	local d0, d1 = (p0.Position - target).Magnitude, (p1.Position - target).Magnitude
	return if d0 < d1 then p0.Position else p1.Position
end
bunting(at(23.5 + 4.2, 23.2, C.Board.z - 1).Position, stallEnd(C.Buyer), 4.5, 13)
bunting(at(-23.5 - 4.2, 23.2, C.Board.z - 1).Position, stallEnd(C.Vip), 4.5, 13)

-- ===== the fountain (the village fountain's recipe, VillageFountain.luau: engine-driven water, no script) =====
local fountain = group("Fountain") :: Model
do
	local TEX = { drop = "rbxassetid://113689065664958", splash = "rbxassetid://243457340", ripple = "rbxassetid://101873502982973", curtain = "rbxassetid://1610017834" }
	local WATER = Color3.fromRGB(86, 176, 226)
	local WATER_LIGHT = Color3.fromRGB(190, 236, 255)
	local FOAM = Color3.fromRGB(240, 250, 255)
	local function A(x: number, y: number, z: number): CFrame
		return at(0, y, 0) * CFrame.new(x, 0, z)
	end
	local function disc(name: string, d: number, h: number, y: number, colour: Color3, material: Enum.Material?)
		return cylinder(fountain, name, d, h, A(0, y + h / 2, 0), colour, material)
	end
	local function holder(name: string, size: Vector3, cf: CFrame): Part
		local p = piece(fountain, name, size, cf, WHITE) :: Part
		p.Transparency = 1
		return p
	end
	local function pool(d: number, y: number, ripples: number)
		local water = disc("Water", d, 0.2, y - 0.2, WATER)
		water.Transparency = 0.1
		disc("WaterShimmer", d - 0.05, 0.05, y + 0.01, Color3.fromRGB(70, 160, 230), Mat.ForceField)
		if ripples > 0 then
			local h = holder("RippleArea", Vector3.new(0.1, d * 0.8, d * 0.8), A(0, y + 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)))
			h.Shape = Enum.PartType.Cylinder
			local e = Instance.new("ParticleEmitter")
			e.Name = "Ripples"
			e.Texture = TEX.ripple
			e.Shape = Enum.ParticleEmitterShape.Disc
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			e.EmissionDirection = Enum.NormalId.Right
			e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
			e.Speed = NumberRange.new(0.01)
			e.Lifetime = NumberRange.new(1.6, 2.2)
			e.Rate = ripples
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, d * 0.14) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.35), NumberSequenceKeypoint.new(1, 1) })
			e.Color = ColorSequence.new(WATER_LIGHT)
			e.LightEmission = 0.3
			e.Rotation = NumberRange.new(0, 360)
			e.Parent = h
		end
	end
	local function splashes(r: number, y: number, rate: number)
		local h = holder("SplashRing", Vector3.new(0.1, math.max(0.4, r * 2), math.max(0.4, r * 2)), A(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)))
		h.Shape = Enum.PartType.Cylinder
		local e = Instance.new("ParticleEmitter")
		e.Name = "Splashes"
		e.Texture = TEX.splash
		e.Shape = Enum.ParticleEmitterShape.Disc
		e.ShapeStyle = if r > 1 then Enum.ParticleEmitterShapeStyle.Surface else Enum.ParticleEmitterShapeStyle.Volume
		e.EmissionDirection = Enum.NormalId.Right
		e.Speed = NumberRange.new(3, 5)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Acceleration = Vector3.new(0, -20, 0)
		e.Lifetime = NumberRange.new(0.35, 0.55)
		e.Rate = rate
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1.7) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(FOAM)
		e.LightEmission = 0.2
		e.Rotation = NumberRange.new(0, 360)
		e.Parent = h
	end
	local function curtains(r0: number, y0: number, r1: number, y1: number, n: number, rate: number)
		local h = holder("Curtains", Vector3.one * 0.2, A(0, y0, 0))
		local width = 2 * math.pi * r0 / n * 1.08
		local turn = (F - F.Position):Inverse()
		for k = 0, n - 1 do
			local ang = k * math.pi * 2 / n
			local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local tangent = Vector3.new(-math.sin(ang), 0, math.cos(ang))
			local a0 = Instance.new("Attachment")
			a0.Position = out * r0
			a0.Axis = out
			a0.SecondaryAxis = tangent
			a0.Parent = h
			local a1 = Instance.new("Attachment")
			a1.Position = out * r1 + Vector3.new(0, y1 - y0, 0)
			a1.Axis = out
			a1.SecondaryAxis = tangent
			a1.Parent = h
			local b = Instance.new("Beam")
			b.Name = "WaterCurtain"
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Texture = TEX.curtain
			b.TextureMode = Enum.TextureMode.Wrap
			b.TextureLength = 4
			b.TextureSpeed = 1.2
			b.Width0 = width
			b.Width1 = width * (r1 / math.max(r0, 0.1))
			b.Segments = 8
			b.CurveSize0 = (r1 - r0) * 0.9
			b.CurveSize1 = 0
			b.Color = ColorSequence.new(WATER_LIGHT, FOAM)
			b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.8, 0.45), NumberSequenceKeypoint.new(1, 0.85) })
			b.LightEmission = 0.25
			b.LightInfluence = 0.6
			b.Parent = h
		end
		local _ = turn
		splashes(r1 + 0.1, y1 + 0.05, rate)
	end
	-- a ring of chunky stones, each its own height and shade, so the water shows inside
	local function stoneRing(r: number, n: number, depth: number, h: number, y: number, jitter: number, isSolid: boolean?)
		local span = 2 * math.pi * r / n
		for k = 1, n do
			local a = (k + 0.5) * math.pi * 2 / n
			local tall = h + rng:NextNumber(-jitter, jitter)
			local shade = STONE:Lerp(STONE_DARK, rng:NextNumber(0, 1))
			local cf = A(math.cos(a) * r, y + tall / 2, math.sin(a) * r) * CFrame.Angles(0, -a, 0)
			local p = piece(fountain, "BasinStone", Vector3.new(depth, tall, span - 0.12), cf, shade, Mat.Slate)
			if isSolid then
				solid(p)
			end
		end
	end
	-- a low round step of flat stones, the basin wall of big blocks with a paler cap, its water
	stoneRing(17.2, 20, 3.2, 0.9, 0, 0.1)
	stoneRing(14.3, 16, 3.6, 3.3, 0, 0.3, true)
	stoneRing(14.3, 16, 3.9, 0.5, 3.4, 0.05)
	disc("BasinFloor", 25, 0.5, 0.1, STONE_DARK, Mat.Slate)
	local wl = 3.1
	pool(25.4, wl, 4)
	-- the first bowl, on its column
	disc("ColumnFoot", 7, 1.4, wl - 0.4, STONE, Mat.Slate)
	cylinder(fountain, "Column", 4, 4, A(0, wl + 2.6, 0), STONE, Mat.Slate)
	disc("BowlUnder", 7, 0.7, wl + 4.2, STONE_DARK, Mat.Slate)
	disc("BowlUnder", 10.5, 0.8, wl + 4.9, STONE, Mat.Slate)
	local m1 = wl + 6.1
	stoneRing(6.1, 12, 1.6, 1.1, wl + 5.6, 0.08)
	pool(10.9, m1, 2)
	-- the second bowl
	disc("ColumnFoot", 3.6, 0.8, m1 - 0.1, STONE_DARK, Mat.Slate)
	cylinder(fountain, "Column", 2.4, 3.2, A(0, m1 + 1.6, 0), STONE, Mat.Slate)
	disc("BowlUnder", 4, 0.5, m1 + 3.1, STONE_DARK, Mat.Slate)
	local m2 = m1 + 4.4
	stoneRing(3.2, 9, 1.1, 0.9, m2 - 0.7, 0.05)
	disc("BowlUnder", 5.6, 0.5, m2 - 0.9, STONE, Mat.Slate)
	pool(5.6, m2, 0)
	disc("Finial", 1, 0.6, m2, STONE_DARK, Mat.Slate)
	curtains(2.9, m2, 5.2, m1, 8, 10)
	curtains(6, m1, 11, wl, 16, 18)
	-- a jet out of the top bowl
	local h = holder("Jet", Vector3.one * 0.15, A(0, m2 + 0.5, 0) * CFrame.Angles(math.rad(90), 0, 0))
	local e = Instance.new("ParticleEmitter")
	e.Name = "WaterJet"
	e.Texture = TEX.drop
	e.EmissionDirection = Enum.NormalId.Front
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.Speed = NumberRange.new(11, 12)
	e.SpreadAngle = Vector2.new(4, 4)
	e.Acceleration = Vector3.new(0, -32, 0)
	e.Lifetime = NumberRange.new(0.8, 0.95)
	e.Rate = 26
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.6) })
	e.Squash = NumberSequence.new(0.6)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.85, 0.25), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(FOAM, WATER_LIGHT)
	e.LightEmission = 0.35
	e.Parent = h
	splashes(0.6, m2 + 0.05, 6)
	-- lily pads on the water, moss on the rim
	for k, spot in { { 9.2, 0.4 }, { 9.8, 2.5 }, { 9, 4.6 }, { 8.6, 5.5 } } do
		local a = spot[2]
		local pad = cylinder(fountain, "LilyPad", 2.6 + (k % 2) * 0.8, 0.12, A(math.cos(a) * spot[1], wl + 0.1, math.sin(a) * spot[1]), Color3.fromRGB(84, 170, 72))
		pad.Material = Mat.SmoothPlastic
		if k % 2 == 1 then
			ball(fountain, "LilyFlower", 0.8, A(math.cos(a) * spot[1], wl + 0.45, math.sin(a) * spot[1]), Color3.fromRGB(250, 170, 200))
		end
	end
	for _, a in { 0.9, 2.1, 3.7, 5.2 } do
		kit(fountain, WildKit, "QtClover_1", A(math.cos(a) * 14.3, 3.8, math.sin(a) * 14.3), 3, true, TUFT)
	end
	kit(fountain, WildKit, "QtFern_1", A(math.cos(1.4) * 6, wl + 6.2, math.sin(1.4) * 6), 3.4, true, TUFT)
end

-- ===== the ground: dirt yard and road painted in the terrain, as the valley's =====
local DIRT, WORN = Mat.Sandstone, Mat.Asphalt
local function toSegment(px: number, pz: number, ax: number, az: number, bx: number, bz: number): number
	local dx, dz = bx - ax, bz - az
	local t = math.clamp(((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz), 0, 1)
	local qx, qz = ax + dx * t - px, az + dz * t - pz
	return math.sqrt(qx * qx + qz * qz)
end
-- The ways, as polylines of { x, z, half width }: the front way from the ring road, the road winding off beside the board (as in the picture)
local FRONT_WAY = { { 2, -116, 11 }, { -3, -96, 11 }, { 0, -70, 16 }, { 0, -44, 22 } }
local SIDE_ROAD = { { -24, 38, 8 }, { -44, 62, 5 }, { -36, 88, 4.5 }, { -56, 110, 4.5 }, { -92, 124, 4.5 }, { -112, 160, 4.5 } }
local function wayDistance(line, x: number, z: number): number
	local best = 1e9
	for k = 1, #line - 1 do
		local a, b = line[k], line[k + 1]
		local d = toSegment(x, z, a[1], a[2], b[1], b[2])
		-- (a half width that eases from one point to the next)
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local t = math.clamp(((x - a[1]) * dx + (z - a[2]) * dz) / (dx * dx + dz * dz), 0, 1)
		best = math.min(best, d - (a[3] + (b[3] - a[3]) * t))
	end
	return best
end
local function yardValue(x: number, z: number): number
	local d = math.sqrt(x * x + z * z) - 50
	d = math.min(d, math.sqrt((x - C.Buyer.x) ^ 2 + (z - C.Buyer.z) ^ 2) - 25)
	d = math.min(d, math.sqrt((x - C.Vip.x) ^ 2 + (z - C.Vip.z) ^ 2) - 25)
	d = math.min(d, math.sqrt((x / 1.5) ^ 2 + (z - 54) ^ 2) - 20)
	d = math.min(d, wayDistance(FRONT_WAY, x, z))
	d = math.min(d, wayDistance(SIDE_ROAD, x, z))
	return d
end
local function paintTerrain()
	local terrain = workspace.Terrain
	-- the square's box in the world
	local corners = { F:PointToWorldSpace(Vector3.new(-180, 0, -128)), F:PointToWorldSpace(Vector3.new(180, 0, 176)) }
	local lo = Vector3.new(math.min(corners[1].X, corners[2].X), -8, math.min(corners[1].Z, corners[2].Z))
	local hi = Vector3.new(math.max(corners[1].X, corners[2].X), 8, math.max(corners[1].Z, corners[2].Z))
	local region = Region3.new(lo, hi):ExpandToGrid(4)
	local mats, occ = terrain:ReadVoxels(region, 4)
	local inv = F:Inverse()
	local minP = region.CFrame.Position - region.Size / 2
	local changed = 0
	for ix = 1, mats.Size.X do
		local wx = minP.X + (ix - 0.5) * 4
		for iz = 1, mats.Size.Z do
			local wz = minP.Z + (iz - 0.5) * 4
			local p = inv:PointToWorldSpace(Vector3.new(wx, 0, wz))
			local x, z = p.X, p.Z
			-- the ground's own edges keep what the valley drew: only inside the box proper, and never on the ring road's side of the way
			local r = math.sqrt(wx * wx + wz * wz)
			if r > M.RingRoadRadius + M.RingRoadWidth / 2 + 6 and math.abs(x) <= 176 and z <= 172 then
				local noise = math.noise(x / 9, z / 9, 41.7) * 5 + math.noise(x / 4, z / 4, 3.3) * 1.5
				local v = yardValue(x, z) + noise
				local target = Mat.Grass
				if v < 0 then
					target = if math.noise(x / 13, z / 13, 88.1) > 0.42 then WORN else DIRT
					-- grass creeping in near the yard's rim
					if v > -9 and math.noise(x / 6, z / 6, 19.4) > 0.3 then
						target = Mat.Grass
					end
				end
				-- a road is whole: cells on its core are always earth (noise that frays a thin road falls it into dashes)
				if wayDistance(SIDE_ROAD, x, z) < -0.5 or wayDistance(FRONT_WAY, x, z) < -3 then
					target = DIRT
				end
				for iy = 1, mats.Size.Y do
					local m = mats[ix][iy][iz]
					if m ~= Mat.Air and m ~= Mat.Water and m ~= target and occ[ix][iy][iz] > 0 then
						mats[ix][iy][iz] = target
						changed += 1
					end
				end
			end
		end
		if ix % 16 == 0 then
			task.wait()
		end
	end
	terrain:WriteVoxels(region, 4, mats, occ)
	return changed
end
local paintedCells = paintTerrain()
task.wait()

-- ===== flagstones: the valley's pebble mesh laid flat, tinted =====
local court = group("Court", "Folder")
local function flagstone(x: number, z: number, across: number, deep: number)
	local names = { "QtPebble_Round_1", "QtPebble_Square_2", "QtPebble_Square_2" }
	local src = WildKit:FindFirstChild(names[rng:NextInteger(1, #names)])
	local mesh = src:FindFirstChildWhichIsA("MeshPart", true):Clone()
	mesh.Name = "Flagstone"
	mesh.Size = Vector3.new(across, 0.7, deep)
	mesh.CFrame = at(x, 0.12, z, rng:NextNumber(0, math.pi * 2))
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.CanTouch = false
	mesh.CanQuery = false
	mesh.CastShadow = false
	local tint = FLAG_TINTS[rng:NextInteger(1, #FLAG_TINTS)]
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		sa.Color = tint
	else
		mesh.Color = tint
	end
	mesh.Parent = court
end
do
	-- rings round the fountain
	local r = 22.5
	while r < 44 do
		local n = math.floor(2 * math.pi * r / 8.4)
		for k = 1, n do
			if rng:NextNumber() < 0.88 - (r - 22) * 0.012 then
				local a = (k + rng:NextNumber(-0.18, 0.18)) * math.pi * 2 / n + r
				local rr = r + rng:NextNumber(-0.9, 0.9)
				flagstone(math.cos(a) * rr, math.sin(a) * rr, rng:NextNumber(5.4, 7.6), rng:NextNumber(4.4, 6))
			end
		end
		r += 6.8
	end
	-- wide stones up the front way and over to each stall and the board
	local function line(ax: number, az: number, bx: number, bz: number, step: number, spread: number)
		local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
		for d = 0, len, step do
			local t = d / len
			flagstone(ax + (bx - ax) * t + rng:NextNumber(-spread, spread), az + (bz - az) * t + rng:NextNumber(-spread * 0.4, spread * 0.4), rng:NextNumber(5, 8.5), rng:NextNumber(4, 6))
		end
	end
	line(-6, -48, -7, -94, 9, 3)
	line(7, -50, 8, -92, 11, 3)
	line(40, -22, 30, -20, 8, 1.5)
	line(-40, -22, -30, -20, 8, 1.5)
	line(-6, 46, -8, 54, 7, 2)
	line(8, 46, 10, 54, 7, 2)
end
task.wait()

-- ===== what stands round it =====
local round = group("Surroundings", "Folder")
local placedAt: { { x: number, z: number } } = {}
local function note(x: number, z: number)
	table.insert(placedAt, { x = x, z = z })
end
local function outdoor(from: Instance, name: string, x: number, z: number, size: number, wide: boolean?, tint: Color3?, isSolid: boolean?, yaw: number?)
	note(x, z)
	return kit(round, from, name, at(x, -0.1, z, yaw or rng:NextNumber(0, math.pi * 2)), size, wide, tint, isSolid)
end

-- big trees framing the square, none between the Landing and what it must see; only the trunk collides
local function tree(name: string, x: number, z: number, height: number)
	local t = outdoor(WildKit, name, x, z, height)
	for _, d in t:GetDescendants() do
		if d:IsA("BasePart") then
			d.CastShadow = true
			if string.find(string.lower(d.Name), "bark") then
				d.CanCollide = true
				d.CanQuery = true
				if d:IsA("MeshPart") then
					d.CollisionFidelity = Enum.CollisionFidelity.Box
				end
			end
		end
	end
end
-- (off the line from the Landing through each stall, or a trunk stands as a dark panel in the stall's opening)
tree("QtCommonTree_5", 84, 62, 48)
tree("QtCommonTree_1", -84, 62, 46)
tree("QtCommonTree_3", 118, 74, 50)
tree("QtCommonTree_3", -4, 118, 54)

-- dry-stone walls with gaps: a row of the kit's wall along a line
local WALL_H, WALL_LEN = 4.6, 4.6 * 12.3 / 6
local function wall(ax: number, az: number, bx: number, bz: number)
	local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
	local count = math.max(1, math.floor(len / WALL_LEN + 0.5))
	local yaw = math.atan2(-(bz - az), bx - ax)
	for k = 1, count do
		local t = (k - 0.5) / count
		local x, z = ax + (bx - ax) * t, az + (bz - az) * t
		note(x, z)
		kit(round, PropKit, "DryStoneWall", at(x, -0.15 + (k % 2) * 0.1, z, yaw + (if k % 2 == 0 then math.pi else 0) + rng:NextNumber(-0.04, 0.04)), WALL_H, false, nil, true)
	end
end
-- front corners, on both sides of the way in, turning up the sides with gaps
wall(26, -86, 56, -88)
wall(78, -82, 96, -76)
wall(-26, -86, -56, -88)
wall(-78, -82, -96, -76)
-- behind the board, broken by the road on the VIP's side
wall(38, 86, 58, 84)

-- benches facing the fountain, a lantern post beside each; lantern posts at the way in
local function lanternPost(x: number, z: number, lit: boolean)
	note(x, z)
	local base = at(x, -0.1, z)
	post(round, base, 10.5, 1.2)
	bar(round, "LanternArm", (base * CFrame.new(0, 9.8, 0)).Position, (base * CFrame.new(0, 9.8, -2.2)).Position, 0.5, 0.5, WOOD_LIGHT, Mat.Wood)
	lashing(round, base * CFrame.new(0, 8.4, 0), 1.8, 0.8)
	lantern(round, base * CFrame.new(0, 9.5, -1.9), 2.8, lit)
end
lanternPost(-32, 36, false)
lanternPost(32, 40, true)

-- a fence along the road winding off
local function fence(ax: number, az: number, bx: number, bz: number)
	local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
	local count = math.max(1, math.floor(len / 9 + 0.5))
	local yaw = math.atan2(-(bz - az), bx - ax)
	for k = 1, count do
		local t = (k - 0.5) / count
		local x, z = ax + (bx - ax) * t, az + (bz - az) * t
		note(x, z)
		kit(round, PropKit, "RanchFence", at(x, -0.1, z, yaw), 9, true, nil, true)
	end
end
fence(-48, 72, -44, 92)
fence(-54, 102, -86, 116)

-- mossy boulders at the edges, in twos and threes
local function boulder(x: number, z: number, across: number)
	outdoor(WildKit, "QtRock_Medium_" .. rng:NextInteger(1, 3), x, z, across, true, nil, across > 7)
	if across >= 9 then
		kit(round, WildKit, "QtClover_1", at(x, across * 0.45, z, rng:NextNumber(0, 6)), across * 0.55, true, Color3.fromRGB(170, 215, 110))
	end
end
for _, b in { { 84, -94, 10 }, { 30, -100, 7 }, { -30, -102, 8 }, { -82, -96, 11 }, { -94, -88, 6 }, { 122, -14, 11 }, { -122, -4, 12 }, { 82, 92, 9 }, { -70, 92, 8 } } do
	boulder(b[1], b[2], b[3])
end

-- beds of flowers and leaves, each round something
local BED = {
	{ WildKit, "DokiFlower3", 4, false },
	{ PropKit, "PinkDaisies", 4.2, true },
	{ WildKit, "DokiFlower4", 4.6, false },
	{ WildKit, "DokiFlower1", 3.2, true },
	{ WildKit, "DokiFlower2", 3.2, true },
	{ WildKit, "DokiFlower3", 4.4, false },
	{ WildKit, "DokiFlower4", 4, false },
	{ WildKit, "QtFern_1", 5, true, TUFT },
	{ WildKit, "DokiGrass2", 3.4, false, TUFT },
	{ WildKit, "DokiGrass7", 3.4, false, TUFT },
}
local function bed(x: number, z: number, radius: number, count: number)
	for k = 1, count do
		local a, r = rng:NextNumber(0, math.pi * 2), radius * math.sqrt(rng:NextNumber())
		local e = BED[rng:NextInteger(1, #BED)]
		local px, pz = x + math.cos(a) * r, z + math.sin(a) * r
		if not (math.abs(px - C.Landing.x) < 14 and math.abs(pz - C.Landing.z) < 14) then
			kit(round, e[1], e[2], at(px, -0.1, pz, rng:NextNumber(0, 6.2)), e[3] * rng:NextNumber(0.85, 1.25), e[4], e[5])
		end
	end
end
for _, f in { { 66, -70 }, { -66, -70 } } do
	kit(round, WildKit, "QtFlower_3_Group", at(f[1], -0.1, f[2], rng:NextNumber(0, 6)), 4.2, true)
end
for _, s in { -1, 1 } do
	-- each with its back to a low wall at the front corner of the court, as in the picture
	local bx, bz = s * 30, -41
	note(bx, bz)
	kit(round, PropKit, "WoodBench", facing(bx, bz, 0, 0, -0.1), 9.5, true, nil, true)
	lanternPost(s * 41, -41, true)
	wall(s * 24, -47, s * 44, -50)
	bed(s * 34, -53, 7, 6)
	boulder(s * 52, -52, 8)
	kit(round, WildKit, "QtFlower_3_Group", at(s * 22, -0.1, -36, rng:NextNumber(0, 6)), 3.6, true)
	lanternPost(s * 17, -96, s > 0)
end
-- round the fountain's step, in arcs with gaps
for _, a in { 0.4, 1.3, 2.3, 3.2, 4.2, 5.2 } do
	bed(math.cos(a) * 20.2, math.sin(a) * 20.2, 3, 4)
end
-- at the board's foot, between the stone beds
bed(-10, 54, 8, 7)
bed(10, 54, 8, 7)
bed(0, 50, 3, 3)
-- along the walls at the front, by the benches
bed(40, -80, 9, 7)
bed(-40, -80, 9, 7)
bed(84, -68, 9, 6)
bed(-84, -68, 9, 6)
-- beside the stalls, outward
bed(88, -26, 9, 6)
bed(-88, -24, 9, 6)
bed(92, 22, 8, 3)
for _, b in { { 96, -44, 8 }, { -98, -40, 8 }, { 96, 56, 8 }, { -88, 62, 7 }, { 46, 74, 8 }, { -18, 78, 7 }, { 62, -96, 7 }, { -60, -98, 7 } } do
	outdoor(WildKit, "QtBush_Common_Green", b[1], b[2], b[3], true)
end
for _, b in { { 86, 70, 7 }, { -76, 48, 7 }, { 28, 76, 7 } } do
	outdoor(WildKit, "QtBush_Common_Flowers", b[1], b[2], b[3], true)
end

-- ===== the count, and what stands on a neighbour =====
local function plotClash(): { string }
	local clashes = {}
	for _, plot in { 1, 8 } do
		local frame = Layout.plotFrame(plot)
		for _, spot in placedAt do
			local p = frame:PointToObjectSpace(at(spot.x, 0, spot.z).Position)
			if math.abs(p.X) < M.PlotSize / 2 + 10 and math.abs(p.Z) < M.PlotSize / 2 + 10 then
				table.insert(clashes, string.format("(%.0f, %.0f) on plot %d", spot.x, spot.z, plot))
			end
		end
	end
	return clashes
end
local cache: { [string]: number } = {}
local function tris(p: BasePart): number
	if p:IsA("MeshPart") then
		if cache[p.MeshId] == nil then
			local ok, mesh = pcall(function()
				return AssetService:CreateEditableMeshAsync(p.MeshContent)
			end)
			cache[p.MeshId] = if ok and mesh then #mesh:GetFaces() else 0
			if ok and mesh then
				mesh:Destroy()
			end
		end
		return cache[p.MeshId]
	elseif p:IsA("WedgePart") then
		return 8
	elseif p:IsA("Part") then
		return if p.Shape == Enum.PartType.Block then 12 else 100
	end
	return 12
end
local lines = { "painted terrain cells: " .. paintedCells }
local total, instances = 0, 0
local tally: { [string]: number } = {}
for _, child in root:GetChildren() do
	local t, parts = 0, 0
	for _, d in child:GetDescendants() do
		instances += 1
		if d:IsA("BasePart") then
			t += tris(d)
			local owner = "(parts)"
			if d:IsA("MeshPart") then
				-- (the name of the kit model it came from: generated meshes sit in a "body" model of their own)
				local up = d.Parent
				while up and up.Parent and (up.Name == "body" or up.Name == "Geometry") do
					up = up.Parent
				end
				owner = up.Name
			end
			tally[owner] = (tally[owner] or 0) + tris(d)
			parts += 1
		end
	end
	total += t
	table.insert(lines, string.format("%s: %d parts, %d triangles", child.Name, parts, t))
end
table.insert(lines, string.format("TOTAL %d triangles, %d instances", total, instances))
local sorted = {}
for name, n in tally do
	table.insert(sorted, name .. " " .. n)
end
table.sort(sorted)
table.insert(lines, table.concat(sorted, ", "))
local clashes = plotClash()
table.insert(lines, if #clashes > 0 then "ON NEIGHBOURS: " .. table.concat(clashes, ", ") else "nothing within 10 of plots 1 and 8")
return table.concat(lines, "\n")
