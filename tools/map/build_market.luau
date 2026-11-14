-- RETIRED with the first valley (2026-11-14, docs/WORLD.md M4): the Market it built now stands at the hub of the big world
-- (moved there by tools/world/build_sites.luau) and the valley this script builds on is gone. Kept as the record of how
-- the Market is made; to build it again it must first take its frame from Layout.marketFrame().
-- Builds the Market square of the valley (workspace.Map.Market) and dresses what stands round it, from the reference art/concept/market-1.jpg
-- and the owner's stall art (reference/goo-lineage-web/assets/map/other/shop-*.png, shape and colour only).
-- The plan (the owner, 2026-11-05: "rearrange the shopping area so it is tidy and more beautiful"): a round paved plaza on the fountain,
-- its flagstones in neat rings inside a kerb; five places on one circle round it, each facing the fountain with a short paved path to its
-- front: the Slime Buyer (front left) and the VIP stall (front right), the Blacksmith (back left, tools/map/build_smithy.luau) and the
-- Dungeon portal (back right, placed by the game: src/server/DungeonPortal), the Leaderboard at the back in the middle. One straight paved
-- way in from the valley road at the front (the Landing on it), a lamp each side of the entrance and low walls beside it. Dressing in
-- mirror pairs: benches facing the fountain, flowers at the foot of each place, lamps at path mouths, trees behind, boulders outside.
-- The frame's -Z looks at the valley centre, +x is the left of someone walking in. The code finds SlimeBuyer, VipStall, Leaderboard (with
-- its part Screen, whose Front face looks at the square); the prompts stand at Config.Market's spots whatever is built here.
-- Run in Edit mode, as often as wanted (it removes what it made and paints the ground again):
--   node tools/studio_mcp.js run tools/map/build_market.luau <studio_id> Edit
-- Run it again after tools/map/build_wild_slices.luau, which resets the ground outside the ring road to grass. Then
-- tools/map/check_market.luau must end MARKET OK. tools/map/preview_portal.luau shows the portal for shots (remove it after).
-- Kit models come from ServerStorage.PropKit and WildKit: nothing is read at run time, it travels with the owner's save.
-- The floor: real terrain earth (Sandstone = WildDirt, as the valley's roads) under flat flagstones of the valley's own pebble mesh.
local ServerStorage = game:GetService("ServerStorage")
local AssetService = game:GetService("AssetService")

local PropKit, WildKit = ServerStorage.PropKit, ServerStorage.WildKit
-- An MCP `run` cannot require the shared modules ("Capabilities: Network") and the work place's copy can be older than the repo, so
-- the numbers are kept here, EQUAL to src/shared/Config.luau (Config.Map, Config.Market, Config.Dungeon.Portal.Market) and Layout.
local M = { GroundY = 2, RingRoadRadius = 356, RingRoadWidth = 24, PlotSize = 228, RimRadius = 500, PlotCount = 8 }
local C = {
	Landing = { x = 0, z = -56 },
	Buyer = { x = 48, z = -28 },
	Vip = { x = -48, z = -28 },
	Board = { x = 0, z = 62 },
	Smithy = { x = 48, z = 28 },
	Portal = { x = -51, z = 30 },
	Model = "Market",
	BuyerModel = "SlimeBuyer",
	VipModel = "VipStall",
	BoardModel = "Leaderboard",
	SmithyModel = "Blacksmith",
	ScreenName = "Screen",
}
-- Layout.slotFrame(slot): on the rim, looking at the valley centre (slot 0 is the Market, 1..8 the plots)
local function slotFrame(slot: number): CFrame
	local a = math.rad(slot * 360 / (M.PlotCount + 1))
	return CFrame.new(math.sin(a) * M.RimRadius, 0, -math.cos(a) * M.RimRadius) * CFrame.Angles(0, math.pi - a, 0)
end
local F = slotFrame(0)
local G = M.GroundY
local rng = Random.new(20261105)
local Mat = Enum.Material

local root = workspace.Map:FindFirstChild(C.Model)
if not root then
	root = Instance.new("Model")
	root.Name = C.Model
	root.Parent = workspace.Map
end
-- (the Blacksmith is tools/map/build_smithy.luau's)
for _, child in root:GetChildren() do
	if child.Name ~= "Spawn" and child.Name ~= C.SmithyModel then
		child:Destroy()
	end
end
-- The places on their circle: each one's compass angle from the front axis (0 = the way in, pi = the board) and the middle of what is
-- built there (the stalls and the smithy stand 3.5 behind their prompt, so the prompt is over the counter or the anvil).
local function angleOf(spot: { x: number, z: number }): number
	return math.atan2(spot.x, -spot.z)
end
local function pushedOut(spot: { x: number, z: number }, by: number): { x: number, z: number }
	local len = math.sqrt(spot.x * spot.x + spot.z * spot.z)
	return { x = spot.x * (1 + by / len), z = spot.z * (1 + by / len) }
end
local PLACES = {
	{ name = "Buyer", spot = C.Buyer, centre = pushedOut(C.Buyer, 3.5), front = 53 },
	{ name = "Vip", spot = C.Vip, centre = pushedOut(C.Vip, 3.5), front = 53 },
	{ name = "Smithy", spot = C.Smithy, centre = pushedOut(C.Smithy, 3.5), front = 52.5 },
	{ name = "Portal", spot = C.Portal, centre = C.Portal, front = 47 },
	{ name = "Board", spot = C.Board, centre = { x = C.Board.x, z = C.Board.z + 2 }, front = 55.5 },
}
-- the plaza: flower ring on the fountain's step, paving rings, the kerb
local PAVE_IN, PAVE_OUT, RING_W, JOINT = 21.6, 42.6, 4.2, 0.4
local KERB_R, KERB_D = 43.7, 2.2
local YARD_R = 46
local WAY_W, PATH_W = 13.2, 9.6 -- the way in and the paths to the places, paving across
local WAY_END = -124

local function group(name: string, class: string?, parent: Instance?): Instance
	local g = Instance.new(class or "Model")
	g.Name = name
	g.Parent = parent or root
	return g
end

-- ===== the palette (the owner's stall art, docs/reference/03) =====
local WOOD = Color3.fromRGB(176, 112, 54)
local WOOD_LIGHT = Color3.fromRGB(198, 136, 70)
local WOOD_DARK = Color3.fromRGB(128, 80, 40)
local ROPE = Color3.fromRGB(226, 196, 138)
local BLUE = Color3.fromRGB(46, 92, 196)
local BLUE_DEEP = Color3.fromRGB(38, 66, 150)
local CREAM = Color3.fromRGB(246, 234, 204)
local GOLD = Color3.fromRGB(246, 190, 56)
local PURPLE = Color3.fromRGB(104, 44, 140)
local PURPLE_DEEP = Color3.fromRGB(72, 30, 106)
local STONE = Color3.fromRGB(205, 198, 180)
local STONE_DARK = Color3.fromRGB(170, 164, 150)
local GLOW = Color3.fromRGB(255, 206, 110)
local WHITE = Color3.new(1, 1, 1)
local FLAG_TINTS = { Color3.fromRGB(255, 214, 156), Color3.fromRGB(240, 196, 142), Color3.fromRGB(222, 186, 140), Color3.fromRGB(250, 204, 140) }
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
	cylinder(parent, "RopeBand", d, h, cf, ROPE, Mat.SmoothPlastic)
end
-- A squared timber post with a stone foot and a darker cap.
local function post(parent: Instance, x: CFrame, tall: number, w: number)
	solid(piece(parent, "Post", Vector3.new(w, tall, w), x * CFrame.new(0, tall / 2, 0), WOOD, Mat.Wood))
	piece(parent, "PostFoot", Vector3.new(w + 0.8, 0.6, w + 0.8), x * CFrame.new(0, 0.3, 0), STONE_DARK, Mat.Slate)
	piece(parent, "PostCap", Vector3.new(w + 0.3, 0.3, w + 0.3), x * CFrame.new(0, tall + 0.15, 0), WOOD_DARK, Mat.Wood)
end

-- ===== the stalls =====
type Style = { a: Color3, b: Color3, trim: Color3, cloth: Color3, clothEdge: Color3, crest: string, royal: boolean }
local W, D = 22, 12 -- between the posts, across and deep
local STRIPES = 5
local function buildStall(name: string, spot: { x: number, z: number }, style: Style): Model
	local model = group(name) :: Model
	-- facing the fountain (the square's middle)
	local dx, dz = -spot.x, -spot.z
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
	piece(model, "ClothTop", Vector3.new(10, 0.12, cd + 1), L(0, 3.1, cz), style.cloth, Mat.SmoothPlastic)
	piece(model, "ClothFront", Vector3.new(10, 1.7, 0.14), L(0, 2.2, fz), style.cloth, Mat.SmoothPlastic)
	piece(model, "ClothEdgeL", Vector3.new(0.5, 1.7, 0.18), L(-4.75, 2.2, fz - 0.02), style.clothEdge, Mat.SmoothPlastic)
	piece(model, "ClothEdgeR", Vector3.new(0.5, 1.7, 0.18), L(4.75, 2.2, fz - 0.02), style.clothEdge, Mat.SmoothPlastic)
	triangle(model, "ClothEdgePoint", L(0, 1.36, fz + 0.02), 10, 1.2, style.clothEdge, Mat.SmoothPlastic)
	triangle(model, "ClothPoint", L(0, 1.36, fz - 0.06), 8.8, 0.95, style.cloth, Mat.SmoothPlastic)
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
		bar(model, "AwningUpper", a0, a1:Lerp(a2, 0.14), sw + 0.02, 0.4, colour, Mat.SmoothPlastic).CastShadow = true
		bar(model, "AwningLower", a1:Lerp(a0, 0.12), a2, sw + 0.02, 0.4, colour, Mat.SmoothPlastic).CastShadow = true
		local slope = CFrame.lookAt(a1, a2)
		local foot = CFrame.new(a2) * (slope - slope.Position)
		local disc = piece(model, "Scallop", Vector3.new(0.3, sw, sw), foot * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), colour, Mat.SmoothPlastic) :: Part
		disc.Shape = Enum.PartType.Cylinder
		local rim = piece(model, "ScallopEdge", Vector3.new(0.2, sw + 0.55, sw + 0.55), foot * CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), style.trim, Mat.SmoothPlastic) :: Part
		rim.Shape = Enum.PartType.Cylinder
		if style.royal then
			-- a gold tassel where two scallops meet
			if k < STRIPES then
				local tx = x + sw / 2
				local tp = L(tx, edge.Y - 1.2, edge.Z - 0.3)
				ball(model, "TasselKnot", 0.6, tp, GOLD)
				cylinder(model, "Tassel", 0.5, 1.2, tp * CFrame.new(0, -0.8, 0), GOLD, Mat.SmoothPlastic)
			end
		end
	end
	-- the awning's sides: a band along each edge
	for _, x in { -span / 2, span / 2 } do
		bar(model, "AwningSide", V(x, top.Y - 0.5, top.Z), V(x, mid.Y - 0.5, mid.Z), 0.3, 1.1, style.trim, Mat.SmoothPlastic)
		bar(model, "AwningSide", V(x, mid.Y - 0.5, mid.Z), V(x, edge.Y - 0.5, edge.Z), 0.3, 1.1, style.trim, Mat.SmoothPlastic)
	end
	bar(model, "AwningRidge", V(-span / 2, top.Y + 0.1, top.Z), V(span / 2, top.Y + 0.1, top.Z), 0.5, 0.7, style.trim, Mat.SmoothPlastic)

	-- what it sells: two baskets of gold on the counter, stacks of coins beside them, a lantern under the beam
	for _, x in { -5.8, 5.8 } do
		coinBasket(model, L(x, 3.05, cz + 0.3) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), 4.2)
	end
	kit(model, PropKit, "CoinStack", L(-9.6, 3.05, cz - 0.4), 2.6, true)
	lantern(model, L(-7, FRONT_H - 1, FRONT + 1), 2.6, true)
	lantern(model, L(7, FRONT_H - 1, FRONT + 1), 2.6, not style.royal)
	cylinder(model, "LanternRope", 0.14, 0.9, L(-7, FRONT_H - 0.6, FRONT + 1), ROPE, Mat.SmoothPlastic)
	cylinder(model, "LanternRope", 0.14, 0.9, L(7, FRONT_H - 0.6, FRONT + 1), ROPE, Mat.SmoothPlastic)
	return model
end

-- The stall's frame, as buildStall's: -Z looks at the fountain. `entry` is the sign of the stall's own x that points to the way in (+1
-- for the buyer on the left, -1 for the VIP stall on the right), so the two dress as a mirror pair.
local function frameOf(spot: { x: number, z: number }): CFrame
	local dx, dz = -spot.x, -spot.z
	local len = math.sqrt(dx * dx + dz * dz)
	dx, dz = dx / len, dz / len
	local px, pz = spot.x - dx * 3.5, spot.z - dz * 3.5
	return facing(px, pz, px + dx, pz + dz)
end
local function entryOf(spot: { x: number, z: number }): number
	return if frameOf(spot).RightVector:Dot(F.LookVector) > 0 then 1 else -1
end
-- what stands at a stall's feet, the same for both: a barrel at the far end, a coin basket and a sack in front of the counter, a bush
-- behind the far end
local function stallGoods(model: Model, spot: { x: number, z: number }, yawBarrel: number)
	local frame = frameOf(spot)
	local s = entryOf(spot)
	kit(model, PropKit, "WoodBarrel", frame * CFrame.new(-s * (W / 2 + 2.4), 0, -5.6) * CFrame.Angles(0, yawBarrel, 0), 4.2, false, nil, true)
	coinBasket(model, frame * CFrame.new(s * (W / 2 - 3.2), 0, -8.4) * CFrame.Angles(0, s * 0.25, 0), 5)
	kit(model, PropKit, "MoneySack", frame * CFrame.new(-s * (W / 2 - 2.6), 0, -8.2) * CFrame.Angles(0, -s * 0.5, 0), 3)
	kit(model, WildKit, "QtBush_Common_Green", frame * CFrame.new(-s * (W / 2 + 4.5), 0, 4), 7, true)
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
	local s = entryOf(C.Buyer)
	-- the hanging sign on its own tall post at the end toward the way in, its arm reaching in over the awning's front
	local px, pz = s * (W / 2 + 2.6), -D / 2 - 3
	local base = frame * CFrame.new(px, 0, pz)
	post(buyer, base, 21, 1.8)
	local armY = 19.6
	bar(buyer, "SignArm", (frame * CFrame.new(px + s * 1, armY, pz)).Position, (frame * CFrame.new(px - s * 12, armY, pz)).Position, 1.1, 1.1, WOOD_LIGHT, Mat.Wood)
	lashing(buyer, base * CFrame.new(0, armY, 0), 2.5, 1.3)
	bar(buyer, "SignBrace", (frame * CFrame.new(px, armY - 3.8, pz)).Position, (frame * CFrame.new(px - s * 3.8, armY - 0.2, pz)).Position, 0.7, 0.7, WOOD_DARK, Mat.Wood)
	local sign = frame * CFrame.new(px - s * 7.2, 15.6, pz - 0.1)
	piece(buyer, "SignBoard", Vector3.new(8.6, 4.8, 0.5), sign, WOOD_LIGHT, Mat.Wood).CastShadow = true
	piece(buyer, "SignEdgeTop", Vector3.new(9, 0.45, 0.7), sign * CFrame.new(0, 2.4, 0), WOOD_DARK, Mat.Wood)
	piece(buyer, "SignEdgeLow", Vector3.new(9, 0.45, 0.7), sign * CFrame.new(0, -2.4, 0), WOOD_DARK, Mat.Wood)
	for _, sx in { -3, 3 } do
		cylinder(buyer, "SignRope", 0.2, 1.8, frame * CFrame.new(px - s * 7.2 + sx, armY - 1, pz), ROPE, Mat.SmoothPlastic)
	end
	kit(buyer, PropKit, "MoneySack", sign * CFrame.new(0, -1.9, -0.32), 3.8, false, GOLD)
	stallGoods(buyer, C.Buyer, 1)
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
		piece(vip, "BackCurtain", Vector3.new(fw + 0.05, 15.6, 0.3), frame * CFrame.new(x, 7.8, BACK_Z + (k % 2) * 0.22), if k % 2 == 0 then PURPLE_DEEP else Color3.fromRGB(88, 38, 124), Mat.SmoothPlastic).CastShadow = k == 7
	end
	for _, side in { -1, 1 } do
		local x = side * (W / 2 + 0.2)
		for j = 0, 2 do
			local fx = x - side * j * 0.9
			local top = frame * CFrame.new(fx, 0, -D / 2 - 0.5)
			cylinder(vip, "Curtain", 1.2, 6.4, top * CFrame.new(0, 9.2, 0), if j == 1 then PURPLE_DEEP else PURPLE, Mat.SmoothPlastic)
			cylinder(vip, "CurtainFoot", 1.1, 4.6, top * CFrame.new(0, 2.3, 0), if j == 1 then PURPLE_DEEP else PURPLE, Mat.SmoothPlastic)
		end
		local tie = frame * CFrame.new(x - side * 0.9, 5, -D / 2 - 0.5)
		piece(vip, "CurtainTie", Vector3.new(3, 1, 1.3), tie, GOLD, Mat.SmoothPlastic)
		ball(vip, "CurtainKnot", 0.9, tie * CFrame.new(0, 0, -0.9), GOLD)
		cylinder(vip, "CurtainTassel", 0.45, 1.6, tie * CFrame.new(0, -1.3, -0.95), GOLD, Mat.SmoothPlastic)
		ball(vip, "PostKnob", 1.5, frame * CFrame.new(side * W / 2, 18.2, D / 2), GOLD)
	end
	kit(vip, PropKit, "CrownCrest", frame * CFrame.new(0, 15.6, D / 2 - 0.4), 7)
	local b = piece(vip, "CrestBar", Vector3.new(8, 0.6, 0.8), frame * CFrame.new(0, 15.9, D / 2 + 0.1), GOLD)
	b.CastShadow = false
	stallGoods(vip, C.Vip, 2)
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
	piece(banners, "Banner", Vector3.new(7, 12.4, 0.2), cloth, BLUE, Mat.SmoothPlastic).CastShadow = true
	for _, s in { -1, 1 } do
		piece(banners, "BannerEdge", Vector3.new(0.5, 12.4, 0.24), cloth * CFrame.new(s * 3.3, 0, -0.02), GOLD, Mat.SmoothPlastic)
	end
	piece(banners, "BannerTop", Vector3.new(7.4, 0.6, 0.4), cloth * CFrame.new(0, 6.2, 0), GOLD, Mat.SmoothPlastic)
	triangle(banners, "BannerPointEdge", cloth * CFrame.new(0, -6.2, 0), 7, 2.9, GOLD, Mat.SmoothPlastic)
	triangle(banners, "BannerPoint", cloth * CFrame.new(0, -6.2, -0.05), 6, 2.2, BLUE, Mat.SmoothPlastic)
	kit(banners, PropKit, "MoneySack", cloth * CFrame.new(0, -3, -0.2), 5.4, false, GOLD)
	for _, s in { -3, 3 } do
		cylinder(banners, "BannerRope", 0.2, 1, base * CFrame.new(s, 23, -1.2), ROPE, Mat.SmoothPlastic)
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
		bar(banners, "BuntingRope", last, q, 0.14, 0.14, ROPE, Mat.SmoothPlastic)
		local along = (q - last).Unit
		local c = CFrame.fromMatrix(p, along, Vector3.yAxis, along:Cross(Vector3.yAxis))
		triangle(banners, "Pennant", c, 2.9, 3.8, if k % 2 == 1 then BLUE else CREAM, Mat.SmoothPlastic)
		last = q
	end
end

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
		-- separate streams with the stone showing between them, as in the picture
		local width = 2 * math.pi * r0 / n * 0.42
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
			b.Width1 = width * 1.15
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
	curtains(2.9, m2, 4.4, m1, 6, 10)
	curtains(6, m1, 8.6, wl, 8, 18)
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

-- ===== the ground: a round dirt yard under the plaza, a pad under each place, the paths, painted in the terrain as the valley's roads =====
local DIRT = Mat.Sandstone
-- A strip from the plaza along a place's angle: below 0 inside (a box's distance, enough for painting).
local function stripValue(x: number, z: number, theta: number, r0: number, r1: number, half: number): number
	local along = x * math.sin(theta) - z * math.cos(theta)
	local across = math.abs(x * math.cos(theta) + z * math.sin(theta))
	return math.max(across - half, r0 - along, along - r1)
end
local function yardValue(x: number, z: number): number
	local d = math.sqrt(x * x + z * z) - YARD_R
	for _, p in PLACES do
		local dx, dz = x - p.centre.x, z - p.centre.z
		if p.name == "Board" then
			d = math.min(d, math.sqrt((dx / 1.7) ^ 2 + dz * dz) - 13)
		else
			d = math.min(d, math.sqrt(dx * dx + dz * dz) - 16)
		end
		d = math.min(d, stripValue(x, z, angleOf(p.spot), 30, p.front + 2, PATH_W / 2 + 1.5))
	end
	return math.min(d, stripValue(x, z, 0, 30, -WAY_END + 2, WAY_W / 2 + 2))
end
local function paintTerrain()
	local terrain = workspace.Terrain
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
				local target = Mat.Grass
				local v = yardValue(x, z)
				if math.sqrt(x * x + z * z) < YARD_R - 1 or stripValue(x, z, 0, 30, -WAY_END, WAY_W / 2) < 0 then
					-- the plaza and the way in are whole: no noise on them
					target = DIRT
				else
					-- the pads' rims fray a little into the grass
					v += math.noise(x / 7, z / 7, 41.7) * 2.5
					if v < 0 then
						target = DIRT
					end
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

-- ===== the paving: flagstones of the valley's pebble mesh in even rings, a kerb of cut stone round them, paths of the same =====
local court = group("Court", "Folder")
local PEBBLE = WildKit.QtPebble_Square_2:FindFirstChildWhichIsA("MeshPart", true)
local function flagstone(cf: CFrame, across: number, deep: number)
	local mesh = PEBBLE:Clone()
	mesh.Name = "Flagstone"
	mesh.Size = Vector3.new(across, 0.45, deep)
	-- (half a turn at random: the stones stay square to their ring but do not all look the same)
	mesh.CFrame = cf * CFrame.Angles(0, if rng:NextNumber() < 0.5 then 0 else math.pi, 0)
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
local function kerbStone(cf: CFrame, size: Vector3)
	piece(court, "Kerb", size, cf, STONE:Lerp(STONE_DARK, rng:NextNumber(0.2, 0.8)), Mat.Slate)
end
-- the paths: the way in (angle 0) and one to each place's front
local PATHS = { { theta = 0, r1 = -WAY_END, w = WAY_W, across = 3 } }
for _, p in PLACES do
	table.insert(PATHS, { theta = angleOf(p.spot), r1 = p.front, w = PATH_W, across = 2 })
end
do
	-- the rings (each ring's stones the same size, every other ring turned half a stone)
	local ring = 0
	local r = PAVE_IN
	while r + RING_W <= PAVE_OUT + 0.01 do
		local rc = r + RING_W / 2
		local n = math.max(8, math.floor(2 * math.pi * rc / 4.8 + 0.5))
		local span = 2 * math.pi * rc / n
		for k = 0, n - 1 do
			local a = (k + (ring % 2) * 0.5) * span / rc
			flagstone(at(math.cos(a) * rc, 0.05, math.sin(a) * rc, -a), RING_W - JOINT, span - JOINT)
		end
		ring += 1
		r += RING_W
	end
	-- the kerb, open where a path leaves
	local n = math.floor(2 * math.pi * KERB_R / 3.6 + 0.5)
	local span = 2 * math.pi * KERB_R / n
	for k = 0, n - 1 do
		local a = (k + 0.5) * span / KERB_R
		local x, z = math.cos(a) * KERB_R, math.sin(a) * KERB_R
		local open = false
		for _, path in PATHS do
			local ux, uz = math.sin(path.theta), -math.cos(path.theta)
			local along = x * ux + z * uz
			local across = math.abs(x * math.cos(path.theta) + z * math.sin(path.theta))
			if along > 0 and across < path.w / 2 + 1.4 + span / 2 then
				open = true
			end
		end
		if not open then
			kerbStone(at(x, 0.05, z, -a), Vector3.new(KERB_D, 0.9, span - 0.14))
		end
	end
	-- the paths: rows of stones across, a kerb along each side
	for _, path in PATHS do
		local ux, uz = math.sin(path.theta), -math.cos(path.theta)
		local px, pz = math.cos(path.theta), math.sin(path.theta)
		local r0 = KERB_R - KERB_D / 2 + 0.1
		local rows = math.floor((path.r1 - r0) / RING_W + 0.5)
		local cell = (path.w - path.across * JOINT) / path.across
		for row = 0, rows - 1 do
			local along = r0 + (row + 0.5) * RING_W
			for k = 1, path.across do
				local off = -path.w / 2 + (k - 0.5) * (cell + JOINT)
				flagstone(at(ux * along + px * off, 0.05, uz * along + pz * off, -path.theta), cell, RING_W - JOINT)
			end
		end
		local len = rows * RING_W
		local segs = math.max(1, math.floor(len / 4.2 + 0.5))
		for _, side in { -1, 1 } do
			local off = side * (path.w / 2 + 0.8)
			for k = 0, segs - 1 do
				local along = r0 + (k + 0.5) * len / segs
				kerbStone(at(ux * along + px * off, 0.05, uz * along + pz * off, -path.theta), Vector3.new(1.4, 0.9, len / segs - 0.14))
			end
		end
	end
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
-- a spot on a place's circle: its angle from the way in, how far out, how far along the circle (+ toward +x)
local function polar(theta: number, r: number): (number, number)
	return math.sin(theta) * r, -math.cos(theta) * r
end

-- big trees framing the square, in mirror pairs, behind the places; only the trunk collides
local function tree(name: string, x: number, z: number, height: number, yaw: number)
	local t = outdoor(WildKit, name, x, z, height, false, nil, false, yaw)
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
for _, s in { -1, 1 } do
	local x, z = polar(s * math.rad(62), 92)
	tree("QtCommonTree_1", x, z, 52, s * 0.8)
	x, z = polar(s * math.rad(122), 92)
	tree("QtCommonTree_5", x, z, 50, s * 1.9)
	tree("QtCommonTree_3", s * 34, 104, 54, s * 2.4)
	tree("QtCommonTree_3", s * 86, -92, 54, s * 0.3)
end

-- the entrance: a lamp each side of the way in, a low dry-stone wall from each lamp along the square's front, a bench before each wall
local WALL_H, WALL_LEN = 4.6, 4.6 * 12.3 / 6
local function arcWall(theta0: number, theta1: number, r: number)
	local count = math.max(1, math.floor(math.abs(theta1 - theta0) * r / WALL_LEN + 0.5))
	for k = 1, count do
		local th = theta0 + (theta1 - theta0) * (k - 0.5) / count
		local x, z = polar(th, r)
		note(x, z)
		kit(round, PropKit, "DryStoneWall", at(x, -0.15, z, -th + (if k % 2 == 0 then math.pi else 0)), WALL_H, false, nil, true)
	end
end
local function lanternPost(x: number, z: number, tx: number, tz: number, lit: boolean): Vector3
	note(x, z)
	local base = facing(x, z, tx, tz, -0.1)
	post(round, base, 10.5, 1.2)
	bar(round, "LanternArm", (base * CFrame.new(0, 9.8, 0)).Position, (base * CFrame.new(0, 9.8, -2.2)).Position, 0.5, 0.5, WOOD_LIGHT, Mat.Wood)
	lashing(round, base * CFrame.new(0, 8.4, 0), 1.8, 0.8)
	lantern(round, base * CFrame.new(0, 9.5, -1.9), 2.8, lit)
	return (base * CFrame.new(0, 10.6, 0)).Position
end

-- flowers in clumps: a big one and three small round it, the kinds taken in turn so neighbours differ
local FLOWERS = {
	{ WildKit, "DokiFlower3", 4.2, false },
	{ PropKit, "PinkDaisies", 4.2, true },
	{ WildKit, "DokiFlower1", 3.4, true },
	{ WildKit, "DokiFlower4", 4.2, false },
	{ WildKit, "DokiFlower2", 3.4, true },
}
local clumpTurn = 0
local function clump(x: number, z: number, scale: number?)
	clumpTurn += 1
	local k = scale or 1
	for j = 0, 3 do
		local e = FLOWERS[(clumpTurn + j) % #FLOWERS + 1]
		local px, pz = x, z
		if j > 0 then
			local a = j * 2.1 + clumpTurn
			px, pz = x + math.cos(a) * 1.9 * k, z + math.sin(a) * 1.9 * k
		end
		kit(round, e[1], e[2], at(px, -0.1, pz, rng:NextNumber(0, 6.2)), e[3] * k * (if j == 0 then 1.15 else 0.85), e[4])
	end
	note(x, z)
end

for _, s in { -1, 1 } do
	-- the way in
	local lx, lz = s * 10.8, -62
	lanternPost(lx, lz, 0, lz, true)
	arcWall(s * math.rad(13), s * math.rad(31), 64)
	-- a bench before each wall, facing the fountain, flowers between it and the wall
	local bx, bz = polar(s * math.rad(26), 52)
	note(bx, bz)
	kit(round, PropKit, "WoodBench", facing(bx, bz, 0, 0, -0.1), 9.5, true, nil, true)
	for _, th in { 19, 33 } do
		local fx, fz = polar(s * math.rad(th), 58.5)
		clump(fx, fz)
	end
	-- boulders outside the walls and the places
	local x, z = polar(s * math.rad(30), 76)
	outdoor(WildKit, "QtRock_Medium_1", x, z, 9, true, nil, true, s * 0.7)
	x, z = polar(s * math.rad(90), 84)
	outdoor(WildKit, "QtRock_Medium_2", x, z, 10, true, nil, true, s * 1.4)
	x, z = polar(s * math.rad(150), 92)
	outdoor(WildKit, "QtRock_Medium_3", x, z, 8, true, nil, true, s * 2.2)
	-- the side gap between the front place and the back one: a round flower bed in a ring of stones, a bush behind it
	local gx, gz = polar(s * math.rad(90), 50.5)
	for k = 0, 9 do
		local a = k * math.pi * 2 / 10
		kerbStone(at(gx + math.cos(a) * 4.4, 0.05, gz + math.sin(a) * 4.4, -a), Vector3.new(1.3, 0.9, 2.6))
	end
	clump(gx, gz, 1.2)
	x, z = polar(s * math.rad(90), 64)
	outdoor(WildKit, "QtBush_Common_Flowers", x, z, 8, true, nil, false, s)
end

-- lamps at the path mouths, each on the side of its path away from the way in (toward the board for the back ones)
local lampTop: { [string]: Vector3 } = {}
for _, p in PLACES do
	if p.name ~= "Board" then
		local theta = angleOf(p.spot)
		local ux, uz = math.sin(theta), -math.cos(theta)
		local px, pz = math.cos(theta), math.sin(theta)
		local off = PATH_W / 2 + 2.6
		local along = KERB_R + 2.4
		local ax, az = ux * along + px * off, uz * along + pz * off
		local bx, bz = ux * along - px * off, uz * along - pz * off
		local wantFront = p.spot.z < 0
		local x, z = ax, az
		-- (on the side away from the way in, so the view from it is not a row of posts: toward the side gap for the front places)
		if bz > az then
			x, z = bx, bz
		end
		-- (a light in every other lamp only: the front pair)
		lampTop[p.name] = lanternPost(x, z, ux * along, uz * along, wantFront)
	end
end
-- the bunting from the board's banner posts out to the back places, high over their backs (never across their fronts): on the left to
-- the Blacksmith's back post on the board's side (build_smithy.luau: 24 wide, 14 deep, 16.6 tall at the back), on the right to a mast
-- of the same height in the mirror spot behind the portal
local smithyPost: Vector3
do
	local c = pushedOut(C.Smithy, 3.5)
	local frame = facing(c.x, c.z, 0, 0)
	local a = F:PointToObjectSpace((frame * CFrame.new(-12, 0, 7)).Position)
	local b = F:PointToObjectSpace((frame * CFrame.new(12, 0, 7)).Position)
	local p = if a.Z > b.Z then a else b
	smithyPost = Vector3.new(p.X, 0, p.Z)
end
do
	local x, z = -smithyPost.X, smithyPost.Z
	note(x, z)
	local base = at(x, -0.1, z)
	post(round, base, 16.6, 1.7)
	lashing(round, base * CFrame.new(0, 15.4, 0), 2.5, 1)
	ball(round, "MastKnob", 1.6, base * CFrame.new(0, 17.1, 0), GOLD)
end
bunting(at(23.5 + 4.2, 23.2, C.Board.z - 1).Position, at(smithyPost.X, 16.4, smithyPost.Z).Position, 3, 11)
bunting(at(-23.5 - 4.2, 23.2, C.Board.z - 1).Position, at(-smithyPost.X, 16.4, smithyPost.Z).Position, 3, 11)

-- at the foot of each place: flowers at the stalls' near ends, either side of the smithy and the portal, and at the board
for _, spot in { C.Buyer, C.Vip } do
	local frame = frameOf(spot)
	local s = entryOf(spot)
	local p = F:PointToObjectSpace((frame * CFrame.new(s * (W / 2 + 5.5), 0, 1.5)).Position)
	clump(p.X, p.Z)
end
for _, spot in { pushedOut(C.Smithy, 3.5), C.Portal } do
	local theta = angleOf(spot)
	local r = math.sqrt(spot.x * spot.x + spot.z * spot.z)
	for _, side in { -1, 1 } do
		local x, z = polar(theta, r + 1)
		x += math.cos(theta) * side * 16
		z += math.sin(theta) * side * 16
		clump(x, z)
	end
	local x, z = polar(theta, r + 13)
	outdoor(WildKit, "QtBush_Common_Green", x, z, 8, true)
end
clump(-10, 54.5)
clump(10, 54.5)
-- a ring of flowers on the fountain's step, kinds in turn
for k = 0, 15 do
	local a = (k + 0.5) * math.pi * 2 / 16
	local e = FLOWERS[k % #FLOWERS + 1]
	kit(round, e[1], e[2], at(math.cos(a) * 20.2, -0.1, math.sin(a) * 20.2, rng:NextNumber(0, 6.2)), e[3] * 0.8, e[4])
	-- a leafy clump between each two flowers, so the ring reads as one green bed and not as sweets on bare earth
	local b = a + math.pi / 16
	kit(round, WildKit, "QtClover_1", at(math.cos(b) * 20.2, -0.1, math.sin(b) * 20.2, rng:NextNumber(0, 6.2)), 3.2, true, TUFT)
end

-- ===== the count, and what stands on a neighbour =====
local function plotClash(): { string }
	local clashes = {}
	for _, plot in { 1, 8 } do
		local frame = slotFrame(plot)
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

