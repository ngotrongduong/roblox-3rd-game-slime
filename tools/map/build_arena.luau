-- Builds the 3D Arena of the valley (workspace.Map.Arena) from the reference art/concept/arena-34.webp (3/4 view) and arena-plan.webp
-- (top view): a round sand pit one step down inside a grey stone rim, three tiers of cream stands with royal-blue seats round its back,
-- the BLUE team gate (blue roof, glowing doorway) at the back, the ORANGE team gate (orange roof) on the rim at the front, banner poles
-- with pennant strings, four blue lamp posts, a big cream entrance arch with a gold crown and the ARENA sign, low walls and a fence, the
-- RANKING board (front left) and the winners' podium (front right), a cream-and-blue checker path to the Market.
-- Where: the lane between the Market and plot 1 (the Market's local x -205, z 78 = world 205, -578), the arch facing south (+Z) towards
-- the Market's latitude. Straight behind the Market the flat floor ends at z -690 (radius 690) and the Market's own back dressing reaches
-- -618, too little for 120 studs; beside it the whole footprint is flat ground at y 2 (checked by tools/map/check_arena.luau).
-- The named pieces the code finds sit directly in workspace.Map.Arena: Pit, BlueSpot, OrangeSpot, Entrance, Landing, Board, Podium1-3.
-- Arena frame: origin at the pit's centre on the ground, +x east, +z south (the arch side), y up from Config.Map.GroundY.
-- Run in Edit mode, as often as wanted (it removes and rebuilds workspace.Map.Arena only):
--   node tools/studio_mcp.js run tools/map/build_arena.luau <studio_id> Edit
-- Then tools/map/check_arena.luau must end ARENA OK. Kit models come from ServerStorage.PropKit and WildKit.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
-- (a work place whose modules carry the Network capability cannot be required from here: the same numbers as src/shared then)
local okConfig, Config = pcall(require, ReplicatedStorage.Shared.Config)
local okLayout, Layout = pcall(require, ReplicatedStorage.Shared.Layout)
if not okConfig then
	Config = { Map = { GroundY = 2 } }
end
if not okLayout then
	-- Layout.slotFrame(0): at the rim radius 500 to the north, its -Z looking at the valley centre
	Layout = { marketFrame = function() return CFrame.new(0, 0, -500) * CFrame.Angles(0, math.pi, 0) end }
end

local PropKit, WildKit = ServerStorage.PropKit, ServerStorage.WildKit
local M = Config.Map
local G = M.GroundY
local F = Layout.marketFrame()
local Mat = Enum.Material
local rng = Random.new(20261105)

-- where: the Market's frame (x across, z along the radius), as for Config.Market
local SITE = (Config.Arena and Config.Arena.Site) or { x = -205, z = 78 }
local W0 = F:PointToWorldSpace(Vector3.new(SITE.x, 0, SITE.z))
local EMBLEM = (Config.Ui and Config.Ui.Icons and Config.Ui.Icons.arena) or 113759764912682

local mapRoot = workspace.Map
local old = mapRoot:FindFirstChild("Arena")
if old then
	old:Destroy()
end
local root = Instance.new("Model")
root.Name = "Arena"
local function group(name: string): Folder
	local g = Instance.new("Folder")
	g.Name = name
	g.Parent = root
	return g
end

-- ===== the palette (the painting) =====
local CREAM = Color3.fromRGB(255, 238, 196)
local CREAM_DARK = Color3.fromRGB(244, 224, 178)
local BLUE = Color3.fromRGB(50, 98, 206)
local BLUE_DEEP = Color3.fromRGB(40, 78, 170)
local ORANGE = Color3.fromRGB(238, 120, 44)
local ORANGE_DEEP = Color3.fromRGB(214, 98, 34)
local GOLD = Color3.fromRGB(248, 192, 58)
local STONE = Color3.fromRGB(164, 168, 190)
local SAND = Color3.fromRGB(230, 188, 118)
local LAWN = Color3.fromRGB(104, 178, 62)
local WOOD = Color3.fromRGB(176, 112, 54)
local WOOD_DARK = Color3.fromRGB(120, 76, 40)
local POLE = Color3.fromRGB(112, 74, 44)
local WHITE = Color3.fromRGB(250, 248, 240)
local GLOW_BLUE = Color3.fromRGB(36, 96, 255)
local GLOW_ORANGE = Color3.fromRGB(255, 84, 60)
local LAMP_GLASS = Color3.fromRGB(255, 226, 120)
local PENNANTS = { ORANGE, BLUE, Color3.fromRGB(252, 210, 60), Color3.fromRGB(246, 240, 226), Color3.fromRGB(232, 84, 60), Color3.fromRGB(84, 190, 200) }

-- ===== pieces =====
local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(W0.X + x, G + y, W0.Z + z)
end
-- a frame at (x, z) whose Front (-Z) looks south (+z, to the Market side)
local function south(x: number, y: number, z: number): CFrame
	return at(x, y, z) * CFrame.Angles(0, math.pi, 0)
end
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
local function solid(p: BasePart, shadow: boolean?): BasePart
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = shadow == true
	return p
end
-- the classic stud look: Plastic with Studs on top
local function studs(p: BasePart): BasePart
	p.Material = Mat.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	return p
end
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
local function bar(parent: Instance, name: string, a: Vector3, b: Vector3, w: number, t: number, colour: Color3, material: Enum.Material?): BasePart
	return piece(parent, name, Vector3.new(w, t, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), colour, material)
end
-- a triangle in c's XY plane, thick t along Z. Down: its top edge centred on c, the point below. Up: its base centred on c, the point above.
local function triangle(parent: Instance, name: string, c: CFrame, w: number, h: number, t: number, colour: Color3, material: Enum.Material?, up: boolean?)
	for side = -1, 1, 2 do
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
local function decal(p: BasePart, face: Enum.NormalId, id: number)
	local d = Instance.new("Decal")
	d.Texture = "rbxassetid://" .. id
	d.Face = face
	d.Parent = p
end
-- the gold crown (the painting's one): a band, three tall points with ball tips, two small ones, a blue gem.
-- cf: the middle of its foot, Front (-Z) the readable side; s = 1 is 7 studs wide.
local function crown(parent: Instance, cf: CFrame, s: number)
	local m = Instance.new("Model")
	m.Name = "Crown"
	m.Parent = parent
	piece(m, "CrownBand", Vector3.new(7, 1.5, 1.1) * s, cf * CFrame.new(0, 0.75 * s, 0), GOLD)
	for _, x in { -2.6, 0, 2.6 } do
		triangle(m, "CrownPoint", cf * CFrame.new(x * s, 1.5 * s, 0), 2.6 * s, 2.3 * s, 1.0 * s, GOLD, nil, true)
		ball(m, "CrownTip", 1.0 * s, cf * CFrame.new(x * s, 3.9 * s, 0), GOLD)
	end
	for _, x in { -1.3, 1.3 } do
		triangle(m, "CrownPoint", cf * CFrame.new(x * s, 1.5 * s, 0), 1.8 * s, 1.4 * s, 1.0 * s, GOLD, nil, true)
	end
	ball(m, "CrownGem", 0.9 * s, cf * CFrame.new(0, 0.8 * s, -0.55 * s), Color3.fromRGB(70, 130, 255))
	return m
end
-- lettering on a part's face: a SurfaceGui with one TextLabel (the sign's words are the only text in the Arena)
local function lettering(p: BasePart, face: Enum.NormalId, text: string, colour: Color3, stroke: Color3, pxPerStud: number)
	local g = Instance.new("SurfaceGui")
	g.Name = "Lettering"
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = pxPerStud
	g.LightInfluence = 0.4
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = colour
	t.Parent = g
	local s = Instance.new("UIStroke")
	s.Thickness = math.max(2, pxPerStud * 0.07)
	s.Color = stroke
	s.Parent = t
end
-- A kit model: scaled to `size` (height, or width when wide), its foot at cf.
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

-- a point of the stands, by its angle from the back (-z) towards the east and its radius, and a block seated there that faces the pit
local function ring(r: number, deg: number, side: number, y: number): CFrame
	local a = math.rad(deg)
	local x, z = side * r * math.sin(a), -r * math.cos(a)
	return CFrame.lookAt(Vector3.new(W0.X + x, G + y, W0.Z + z), Vector3.new(W0.X, G + y, W0.Z))
end
-- a pillar: blue foot, cream body, blue cap, a gold ball on top. cf stands on the ground; returns the top of the ball.
local function pillar(parent: Instance, cf: CFrame, w: number, h: number, ballD: number?): number
	local bd = ballD or w * 0.62
	piece(parent, "PillarFoot", Vector3.new(w + 0.9, 1.3, w + 0.9), cf * CFrame.new(0, 0.65, 0), BLUE_DEEP)
	solid(piece(parent, "Pillar", Vector3.new(w, h - 1.3, w), cf * CFrame.new(0, 1.3 + (h - 1.3) / 2, 0), CREAM), true)
	studs(piece(parent, "PillarCap", Vector3.new(w + 0.9, 0.9, w + 0.9), cf * CFrame.new(0, h + 0.45, 0), BLUE))
	ball(parent, "Finial", bd, cf * CFrame.new(0, h + 0.9 + bd * 0.45, 0), GOLD)
	return h + 0.9 + bd * 0.95
end

local Y0 = 0.3 -- the lawn's top above the ground
local SAND_TOP = 0.4
local RIM_TOP = 1.4

-- ===== the lawn: a stud mat under everything, the path in =====
local lawn = group("Lawn")
do
	studs(solid(piece(lawn, "LawnMat", Vector3.new(108, 1, 126), at(0, Y0 - 0.5, 3), LAWN)))
	-- the checker path: 7 x 7 tiles, two wide, from the arch south then west to the Market's side
	local T = 7
	local function tile(ix: number, iz: number)
		-- ix: column index (-1: x -7..0, 0: 0..7 ...), iz: row index from z 66
		local x0, z0 = ix * T, 66 + iz * T
		local cream = (ix + iz) % 2 == 0
		studs(solid(piece(lawn, "PathTile", Vector3.new(T, 0.9, T), at(x0 + T / 2, Y0 - 0.45, z0 + T / 2), if cream then CREAM else BLUE)))
	end
	for iz = 0, 3 do
		tile(-1, iz)
		tile(0, iz)
	end
	for ix = -10, -2 do
		tile(ix, 2)
		tile(ix, 3)
	end
end
task.wait()

-- ===== the pit: sand rows with studs, one step down inside the stone rim =====
local pit = group("PitFloor")
do
	local R = 31.4
	for i = -15, 15 do
		local zc = 2 * i
		local near = math.max(0, math.abs(zc) - 1)
		local half = math.sqrt(R * R - near * near)
		local p = piece(i == 0 and root or pit, i == 0 and "Pit" or "PitRow", Vector3.new(half * 2, 1, 2), at(0, SAND_TOP - 0.5, zc), SAND)
		studs(solid(p))
		if i == 0 then
			p:SetAttribute("Radius", 30)
			p:SetAttribute("SurfaceY", G + SAND_TOP)
		end
	end
	-- the rim: grey stones round the sand, one step up, broken at both gates
	local rim = group("Rim")
	local N = 30
	local rc = 31.75
	local len = 2 * rc * math.tan(math.rad(180 / N)) + 0.25
	for k = 0, N - 1 do
		local deg = (k + 0.5) * 360 / N
		-- (deg 0 is the back, 180 the front; the two stones either side of each gate are left out)
		local fromBack = math.min(deg, 360 - deg)
		local fromFront = math.abs(deg - 180)
		if fromBack > 12.5 and fromFront > 12.5 then
			local shade = STONE:Lerp(Color3.fromRGB(150, 154, 178), rng:NextNumber(0, 1))
			studs(solid(piece(rim, "RimStone", Vector3.new(len, RIM_TOP + 1.0, 3.5), ring(rc, deg, 1, (RIM_TOP - 1.0) / 2), shade), true))
		end
	end
end
task.wait()

-- ===== the stands: three tiers of cream stone with blue seats, round the back =====
local stands = group("Stands")
do
	local A0, A1 = 19.5, 110.5
	local n = 11
	local dA = (A1 - A0) / n
	for tier = 1, 3 do
		local ri = 33.5 + 3 * (tier - 1)
		local rc = ri + 1.5
		local top = 0.4 + 2.4 * tier + 0.1
		local length = 2 * (rc + 0.75) * math.tan(math.rad(dA / 2)) + 0.12
		for side = -1, 1, 2 do
			for j = 1, n do
				local deg = A0 + (j - 0.5) * dA
				studs(solid(piece(stands, "TierStone", Vector3.new(length, top + 0.5, 3), ring(rc, deg, side, (top - 0.5) / 2), if j % 2 == 0 then CREAM else CREAM_DARK), true))
			end
			-- seats: two runs a side, the aisle between them
			local seatR = ri + 2.2
			local function seats(a, b)
				local m = math.max(1, math.floor((b - a) / 8.7 + 0.5))
				local d = (b - a) / m
				local l = 2 * (seatR + 0.7) * math.tan(math.rad(d / 2)) + 0.1
				for j = 1, m do
					studs(piece(stands, "Seat", Vector3.new(l, 0.9, 1.4), ring(seatR, a + (j - 0.5) * d, side, top + 0.45), BLUE))
				end
			end
			seats(21.5, 47.5)
			seats(56.5, 108.5)
		end
	end
	-- pillars with gold balls: at each aisle (behind the top tier) and at each end
	for side = -1, 1, 2 do
		pillar(stands, ring(44.8, 52, side, 0.3) * CFrame.Angles(0, 0, 0), 4, 11)
		pillar(stands, ring(38.4, 113.8, side, 0.3), 4.4, 11)
	end
end
task.wait()

-- ===== a gatehouse: cream wings, a gold-framed glowing doorway, a stepped roof, the emblem over it =====
-- gf: the frame at the ground, centred, its Front (-Z) one face and +Z the other; both are built alike.
local function gatehouse(parent: Instance, name: string, gf: CFrame, roof: Color3, roofDeep: Color3, glow: Color3, banners: boolean)
	local g = group(name)
	g.Parent = parent
	local function L(x: number, y: number, z: number): CFrame
		return gf * CFrame.new(x, y, z)
	end
	local W, D, H, OPEN_W, OPEN_H = 13, 12, 14.5, 5, 9
	for _, s in { -1, 1 } do
		solid(piece(g, "Wing", Vector3.new(W - OPEN_W, H, D), L(s * (W + OPEN_W) / 2, H / 2, 0), CREAM), true)
		piece(g, "WingFoot", Vector3.new(W - OPEN_W + 0.7, 1.3, D + 0.7), L(s * (W + OPEN_W) / 2, 0.65, 0), BLUE_DEEP)
	end
	solid(piece(g, "Lintel", Vector3.new(OPEN_W * 2, H - OPEN_H, D), L(0, OPEN_H + (H - OPEN_H) / 2, 0), CREAM), true)
	-- the doorway's glow, set back in the middle of the thickness, and a gold frame on both faces
	local panel = piece(g, "Glow", Vector3.new(OPEN_W * 2, OPEN_H, 0.5), L(0, OPEN_H / 2, 0), glow, Mat.Neon)
	panel.CastShadow = false
	for _, z in { -D / 2 - 0.2, D / 2 + 0.2 } do
		for _, s in { -1, 1 } do
			piece(g, "DoorFrame", Vector3.new(0.9, OPEN_H + 0.9, 0.7), L(s * (OPEN_W + 0.45), (OPEN_H + 0.9) / 2, z), GOLD)
		end
		piece(g, "DoorFrame", Vector3.new(OPEN_W * 2 + 1.8, 0.9, 0.7), L(0, OPEN_H + 0.45, z), GOLD)
	end
	-- the emblem over the doorway, framed in gold on a cream plaque
	for _, f in { -1, 1 } do
		-- (the +Z face is turned half round, so its Front looks out of the house too)
		local face = L(0, 11.9, f * (D / 2 + 0.1)) * (if f > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.new())
		piece(g, "CrestFrame", Vector3.new(5.0, 4.5, 0.3), face, GOLD)
		local plaque = piece(g, "Crest", Vector3.new(4.3, 3.8, 0.3), face * CFrame.new(0, 0, -0.2), CREAM)
		decal(plaque, Enum.NormalId.Front, EMBLEM)
	end
	-- the stepped roof
	local layers = { { 28.4, 14.4 }, { 22.4, 10.8 }, { 16.4, 7.2 }, { 10.4, 3.8 } }
	for k, l in layers do
		local colour = if k % 2 == 1 then roof else roofDeep
		studs(piece(g, "Roof", Vector3.new(l[1], 1.6, l[2]), L(0, H + 0.8 + (k - 1) * 1.6, 0), colour)).CastShadow = true
	end
	ball(g, "RoofBall", 1.8, L(0, H + 0.8 + 4 * 1.6 + 0.4, 0), GOLD)
	-- short pillars with gold balls at each outer side
	for _, s in { -1, 1 } do
		pillar(g, L(s * (W + 1.6), 0, 0), 2.6, 7)
	end
	if banners then
		-- small blue banners hung on the wings, on the pit side
		for _, s in { -1, 1 } do
			local bc = L(s * (W + OPEN_W) / 2, 6.6, -D / 2 - 0.2)
			piece(g, "Banner", Vector3.new(2.8, 6.4, 0.25), bc, BLUE)
			piece(g, "BannerEdge", Vector3.new(0.35, 6.6, 0.3), bc * CFrame.new(-1.45, 0, 0), GOLD)
			piece(g, "BannerEdge", Vector3.new(0.35, 6.6, 0.3), bc * CFrame.new(1.45, 0, 0), GOLD)
			triangle(g, "BannerPoint", bc * CFrame.new(0, -3.2, 0), 2.8, 1.6, 0.25, BLUE, Mat.SmoothPlastic)
			local pl = piece(g, "BannerCrest", Vector3.new(2.0, 1.8, 0.25), bc * CFrame.new(0, 0.6, -0.1), BLUE)
			decal(pl, Enum.NormalId.Front, EMBLEM)
		end
	end
	return g
end
-- the blue gate at the back (its glowing face towards the pit, +z), the orange gate at the front (towards the pit, -z)
-- (the blue gate's Front (-Z) must look at the pit, south: turned half round; the orange gate's Front looks north, at the pit)
gatehouse(root, "GateBlue", at(0, 0, -39.5) * CFrame.Angles(0, math.pi, 0), BLUE, BLUE_DEEP, GLOW_BLUE, true)
gatehouse(root, "GateOrange", at(0, 0, 39.5), ORANGE, ORANGE_DEEP, GLOW_ORANGE, false)
task.wait()

-- ===== the entrance arch with its crown, the sign and two banners =====
local arch = group("Arch")
local ARCH_Z = 62
do
	local AF = south(0, 0, ARCH_Z) -- Front (-Z) looks south, at the way in
	local function L(x: number, y: number, z: number): CFrame
		return AF * CFrame.new(x, y, z)
	end
	-- the opening: 16 wide between the pillars, 17 high under the lintel
	for _, s in { -1, 1 } do
		pillar(arch, L(s * 11, 0, 0), 6, 21, 3.4)
	end
	solid(piece(arch, "Lintel", Vector3.new(28, 3.2, 5.6), L(0, 18.6, 0), CREAM), true)
	-- the pitched blue roof between the pillars, its gable filled in cream
	triangle(arch, "Gable", L(0, 20.2, 0), 17.2, 3.8, 4.8, CREAM, Mat.SmoothPlastic, true)
	for _, s in { -1, 1 } do
		local slab = bar(arch, "ArchRoof", L(s * 8.8, 20.5, 0).Position, L(0, 24.5, 0).Position, 6.2, 1.0, BLUE)
		slab.CastShadow = true
	end
	piece(arch, "Ridge", Vector3.new(1.6, 1.0, 6.4), L(0, 24.8, 0), BLUE_DEEP)
	crown(arch, L(0, 24.6, 0), 1.0)
	-- the wooden sign on the lintel's south face
	local sign = piece(arch, "SignBoard", Vector3.new(12.4, 3.4, 0.9), L(0, 18.6, -3.2), WOOD)
	sign.Material = Mat.Wood
	for _, y in { 1.85, -1.85 } do
		piece(arch, "SignEdge", Vector3.new(13.0, 0.5, 1.2), L(0, 18.6 + y, -3.25), GOLD)
	end
	for _, s in { -1, 1 } do
		piece(arch, "SignEdge", Vector3.new(0.5, 4.2, 1.2), L(s * 6.45, 18.6, -3.25), GOLD)
	end
	lettering(sign, Enum.NormalId.Front, "ARENA", CREAM, Color3.fromRGB(86, 52, 24), 60)
	-- blue banners hung on the pillars' south faces
	for _, s in { -1, 1 } do
		local bc = L(s * 11, 10.4, -3.5)
		piece(arch, "Banner", Vector3.new(3.6, 9, 0.3), bc, BLUE)
		for _, e in { -1, 1 } do
			piece(arch, "BannerEdge", Vector3.new(0.4, 9.2, 0.35), bc * CFrame.new(e * 1.9, 0, -0.02), GOLD)
		end
		piece(arch, "BannerEdge", Vector3.new(4.2, 0.5, 0.4), bc * CFrame.new(0, 4.6, -0.02), GOLD)
		triangle(arch, "BannerPoint", bc * CFrame.new(0, -4.5, 0), 3.6, 1.8, 0.3, BLUE, Mat.SmoothPlastic)
		local pl = piece(arch, "BannerCrest", Vector3.new(2.6, 2.3, 0.3), bc * CFrame.new(0, 0.6, -0.1), BLUE)
		decal(pl, Enum.NormalId.Front, EMBLEM)
	end
end
task.wait()

-- ===== low walls from the arch, a lattice fence round the back and sides =====
local walls = group("Walls")
local FENCE_X, BACK_Z = 51, -57
do
	local function post(x: number, z: number, h: number)
		solid(piece(walls, "Post", Vector3.new(2.8, h, 2.8), at(x, h / 2, z), CREAM), true)
		piece(walls, "PostFoot", Vector3.new(3.4, 1.0, 3.4), at(x, 0.5, z), BLUE_DEEP)
		studs(piece(walls, "PostCap", Vector3.new(3.4, 0.8, 3.4), at(x, h + 0.4, z), BLUE))
	end
	-- the front walls, each side of the arch
	for _, s in { -1, 1 } do
		local x0, x1 = s * 14.2, s * FENCE_X
		local cx, len = (x0 + x1) / 2, math.abs(x1 - x0)
		solid(piece(walls, "WallBody", Vector3.new(len, 2.9, 1.8), at(cx, 1.45, ARCH_Z), CREAM), true)
		piece(walls, "WallBand", Vector3.new(len, 1.0, 2.2), at(cx, 0.5, ARCH_Z), BLUE_DEEP)
		studs(piece(walls, "WallTop", Vector3.new(len, 0.8, 2.4), at(cx, 3.3, ARCH_Z), BLUE))
		for _, px in { s * 24, s * 36, s * FENCE_X } do
			post(px, ARCH_Z, 4.6)
		end
	end
	-- the lattice fence: posts every 17, a top and a low rail, pickets between
	local function run(ax: number, az: number, bx: number, bz: number)
		local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
		local count = math.max(1, math.floor(len / 17 + 0.5))
		local yaw = math.atan2(-(bz - az), bx - ax)
		local mid = at((ax + bx) / 2, 0, (az + bz) / 2) * CFrame.Angles(0, yaw, 0)
		solid(piece(walls, "FenceRail", Vector3.new(len, 0.7, 0.7), mid * CFrame.new(0, 3.2, 0), CREAM))
		piece(walls, "FenceRail", Vector3.new(len, 0.7, 0.7), mid * CFrame.new(0, 1.4, 0), BLUE)
		local pickets = math.floor(len / 4.2)
		for k = 1, pickets - 1 do
			piece(walls, "Picket", Vector3.new(0.5, 2.6, 0.5), mid * CFrame.new(-len / 2 + k * len / pickets, 1.8, 0), CREAM)
		end
		for k = 1, count - 1 do
			local t = k / count
			post(ax + (bx - ax) * t, az + (bz - az) * t, 4.6)
		end
	end
	run(-FENCE_X, ARCH_Z, -FENCE_X, BACK_Z)
	run(FENCE_X, ARCH_Z, FENCE_X, BACK_Z)
	run(-FENCE_X, BACK_Z, FENCE_X, BACK_Z)
	post(-FENCE_X, BACK_Z, 4.6)
	post(FENCE_X, BACK_Z, 4.6)
end
task.wait()

-- ===== banner poles, the pennant strings, the two big banners =====
local poles = group("Poles")
local function pole(x: number, z: number, h: number): Vector3
	local base = at(x, 0, z)
	solid(piece(poles, "PoleBase", Vector3.new(3.2, 2.4, 3.2), base * CFrame.new(0, 1.2, 0), CREAM), true)
	piece(poles, "PoleFoot", Vector3.new(3.9, 0.9, 3.9), base * CFrame.new(0, 0.45, 0), BLUE_DEEP)
	studs(piece(poles, "PoleCap", Vector3.new(3.9, 0.7, 3.9), base * CFrame.new(0, 2.75, 0), BLUE))
	solid(cylinder(poles, "Pole", 1.1, h - 3, base * CFrame.new(0, 3.1 + (h - 3) / 2, 0), POLE, Mat.Wood))
	cylinder(poles, "PoleCollar", 1.7, 0.8, base * CFrame.new(0, h - 1.1, 0), GOLD)
	ball(poles, "Finial", 2.4, base * CFrame.new(0, h + 0.5, 0), GOLD)
	return base.Position + Vector3.new(0, h - 0.6, 0)
end
local function bunting(a: Vector3, b: Vector3, sag: number, count: number)
	local last = a
	for k = 1, count do
		local t = (k - 0.5) / count
		local s = 4 * t * (1 - t)
		local p = a:Lerp(b, t) - Vector3.new(0, sag * s, 0)
		local q = a:Lerp(b, k / count) - Vector3.new(0, sag * 4 * (k / count) * (1 - k / count), 0)
		bar(poles, "StringLine", last, q, 0.14, 0.14, POLE)
		local along = (q - last).Unit
		local c = CFrame.fromMatrix(p, along, Vector3.yAxis, along:Cross(Vector3.yAxis))
		triangle(poles, "Pennant", c, 2.8, 3.6, 0.14, PENNANTS[(k - 1) % #PENNANTS + 1], Mat.SmoothPlastic)
		last = q
	end
end
do
	for _, side in { -1, 1 } do
		local top1 = pole(side * 47 * math.sin(math.rad(27)), -47 * math.cos(math.rad(27)), 24)
		local top2 = pole(side * 50 * math.sin(math.rad(56)), -50 * math.cos(math.rad(56)), 24)
		bunting(top1, top2, 3.6, 6)
	end
	-- the two big banners on the sides: blue on the left (west), orange on the right (east)
	for _, side in { -1, 1 } do
		local colour = if side < 0 then BLUE else ORANGE
		local deep = if side < 0 then BLUE_DEEP else ORANGE_DEEP
		local top = pole(side * 47, 10, 24)
		bar(poles, "BannerArm", top - Vector3.new(0, 0.9, 0), top - Vector3.new(0, 0.9, 0) - Vector3.new(side * 8.4, 0, 0), 0.8, 0.8, POLE, Mat.Wood)
		local bc = south(side * 47 - side * 4.6, 16.2, 10)
		piece(poles, "BigBanner", Vector3.new(6.6, 11.2, 0.3), bc, colour)
		for _, e in { -1, 1 } do
			piece(poles, "BigBannerEdge", Vector3.new(0.5, 11.4, 0.35), bc * CFrame.new(e * 3.4, 0, 0), GOLD)
		end
		piece(poles, "BigBannerEdge", Vector3.new(7.4, 0.6, 0.4), bc * CFrame.new(0, 5.8, 0), GOLD)
		triangle(poles, "BigBannerPoint", bc * CFrame.new(0, -5.6, 0), 6.6, 2.8, 0.3, deep, Mat.SmoothPlastic)
		local pl = piece(poles, "BigBannerCrest", Vector3.new(4.4, 4.0, 0.3), bc * CFrame.new(0, 0.4, -0.12), colour)
		decal(pl, Enum.NormalId.Front, EMBLEM)
	end
end
task.wait()

-- ===== four blue lamp posts =====
local lamps = group("Lamps")
local function lamp(x: number, z: number)
	local base = at(x, 0, z)
	solid(piece(lamps, "LampBase", Vector3.new(3.0, 1.5, 3.0), base * CFrame.new(0, 0.75, 0), CREAM), true)
	studs(piece(lamps, "LampStep", Vector3.new(3.4, 0.6, 3.4), base * CFrame.new(0, 1.8, 0), BLUE))
	cylinder(lamps, "LampPole", 0.9, 5.6, base * CFrame.new(0, 5.1, 0), WHITE)
	cylinder(lamps, "LampCollar", 1.5, 0.7, base * CFrame.new(0, 3.1, 0), BLUE_DEEP)
	cylinder(lamps, "LampCollar", 1.5, 0.7, base * CFrame.new(0, 7.8, 0), BLUE_DEEP)
	piece(lamps, "LampFloor", Vector3.new(2.6, 0.5, 2.6), base * CFrame.new(0, 8.45, 0), BLUE)
	local glass = piece(lamps, "LampGlass", Vector3.new(1.9, 2.4, 1.9), base * CFrame.new(0, 9.9, 0), LAMP_GLASS, Mat.Neon)
	for _, c in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		piece(lamps, "LampBar", Vector3.new(0.3, 2.4, 0.3), base * CFrame.new(c[1] * 0.95, 9.9, c[2] * 0.95), BLUE)
	end
	piece(lamps, "LampRoof", Vector3.new(2.8, 0.6, 2.8), base * CFrame.new(0, 11.4, 0), BLUE)
	piece(lamps, "LampRoof", Vector3.new(1.7, 0.7, 1.7), base * CFrame.new(0, 12.0, 0), BLUE_DEEP)
	ball(lamps, "LampBall", 0.9, base * CFrame.new(0, 12.7, 0), GOLD)
	local light = Instance.new("PointLight")
	light.Color = LAMP_GLASS
	light.Brightness = 0.8
	light.Range = 14
	light.Shadows = false
	light.Parent = glass
end
lamp(-24, 52)
lamp(24, 52)
lamp(-46, 26)
lamp(46, 26)
task.wait()

-- ===== the RANKING board (front left), facing south, its plain cream face for the code's SurfaceGui =====
local boardM = group("RankingBoard")
local BX, BZ = -31, 40
do
	local BF = south(BX, 0, BZ)
	local function L(x: number, y: number, z: number): CFrame
		return BF * CFrame.new(x, y, z)
	end
	local face = piece(root, "Board", Vector3.new(16, 10, 0.5), L(0, 7.8, 0), CREAM_DARK:Lerp(WHITE, 0.55))
	solid(face)
	-- the wooden frame, blue feet and gold balls on its posts
	for _, s in { -1, 1 } do
		solid(piece(boardM, "BoardPost", Vector3.new(1.8, 14.4, 1.8), L(s * 9.4, 7.2, 0.2), WOOD, Mat.Wood))
		piece(boardM, "BoardFoot", Vector3.new(3.0, 1.6, 3.0), L(s * 9.4, 0.8, 0.2), BLUE_DEEP)
		ball(boardM, "Finial", 2.2, L(s * 9.4, 15.6, 0.2), GOLD)
		piece(boardM, "BoardBrace", Vector3.new(0.9, 0.9, 4.6), L(s * 9.4, 4, 2.2) * CFrame.Angles(math.rad(-30), 0, 0), WOOD_DARK, Mat.Wood)
	end
	piece(boardM, "FrameBottom", Vector3.new(19, 1.0, 1.2), L(0, 2.3, -0.2), WOOD, Mat.Wood)
	piece(boardM, "FrameSide", Vector3.new(1.0, 10.4, 1.2), L(-8.5, 7.8, -0.2), WOOD, Mat.Wood)
	piece(boardM, "FrameSide", Vector3.new(1.0, 10.4, 1.2), L(8.5, 7.8, -0.2), WOOD, Mat.Wood)
	piece(boardM, "FrameTop", Vector3.new(19.6, 1.4, 1.4), L(0, 13.4, -0.2), BLUE, Mat.SmoothPlastic)
	piece(boardM, "FrameTopGold", Vector3.new(19.8, 0.4, 1.6), L(0, 12.55, -0.25), GOLD)
	piece(boardM, "FrameBack", Vector3.new(19, 11, 0.5), L(0, 7.8, 0.6), WOOD_DARK, Mat.Wood)
	-- the title plaque above the face and the crown over it
	local plaque = piece(boardM, "TitlePlaque", Vector3.new(9.6, 2.6, 0.9), L(0, 15.1, -0.3), WOOD, Mat.Wood)
	for _, y in { -1.45, 1.45 } do
		piece(boardM, "TitleEdge", Vector3.new(10.2, 0.4, 1.1), L(0, 15.1 + y, -0.35), GOLD)
	end
	lettering(plaque, Enum.NormalId.Front, "RANKING", CREAM, Color3.fromRGB(86, 52, 24), 60)
	crown(boardM, L(0, 16.4, 0), 0.7)
end

-- ===== the winners' podium (front right) =====
local podium = group("PodiumSteps")
do
	local PX, PZ = 31, 40
	local PF = south(PX, 0, PZ)
	local function L(x: number, y: number, z: number): CFrame
		return PF * CFrame.new(x, y, z)
	end
	studs(solid(piece(podium, "Plinth", Vector3.new(23, 1.5, 10.4), L(0, 0.25, 0), Color3.fromRGB(168, 178, 204)), true))
	-- (the frame faces south, so its +x is west: the 2nd place stands on the left of someone looking at it from the south)
	local steps = { { 1, 0, 4, GOLD }, { 2, 6.4, 3, Color3.fromRGB(196, 204, 218) }, { 3, -6.4, 2, Color3.fromRGB(214, 150, 96) } }
	for _, s in steps do
		local n, x, h, medal = s[1], s[2], s[3], s[4]
		local base = 1.0
		solid(piece(podium, "PodiumBody", Vector3.new(6.2, h, 6.2), L(x, base + h / 2, 0), CREAM), true)
		local top = piece(root, "Podium" .. n, Vector3.new(6.6, 0.6, 6.6), L(x, base + h + 0.3, 0), BLUE)
		studs(solid(top, true))
		local num = piece(podium, "PodiumNumber", Vector3.new(5.0, math.min(h - 0.6, 2.8), 0.2), L(x, base + h * 0.5, -3.2), CREAM)
		lettering(num, Enum.NormalId.Front, tostring(n), medal, Color3.fromRGB(110, 74, 30), 90)
	end
end
task.wait()

-- ===== the invisible helpers the code finds =====
local function helper(name: string, size: Vector3, cf: CFrame): BasePart
	local p = piece(root, name, size, cf, WHITE)
	p.Transparency = 1
	return p
end
-- where each team lines up, 18 studs from the centre in front of its gate, on the sand, facing the pit's centre
helper("BlueSpot", Vector3.new(4, 0.2, 4), CFrame.lookAt(at(0, SAND_TOP + 0.1, -18).Position, at(0, SAND_TOP + 0.1, 0).Position))
helper("OrangeSpot", Vector3.new(4, 0.2, 4), CFrame.lookAt(at(0, SAND_TOP + 0.1, 18).Position, at(0, SAND_TOP + 0.1, 0).Position))
-- the arch's opening (a prompt goes here)
helper("Entrance", Vector3.new(15, 14, 3), at(0, 7.5, ARCH_Z))
-- on the path just outside the arch, its Front looking at the arch (north)
helper("Landing", Vector3.new(4, 0.4, 4), CFrame.lookAt(at(0, Y0 + 0.2, ARCH_Z + 10).Position, at(0, Y0 + 0.2, ARCH_Z).Position))

-- ===== what grows round it =====
local dress = group("Dressing")
local function plant(from: Instance, name: string, x: number, z: number, size: number, wide: boolean?, tint: Color3?)
	return kit(dress, from, name, at(x, Y0 - 0.1, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), size, wide, tint, false)
end
-- pines outside the fence, a few
for _, t in { { -66, -52, 26, "QtPine_1" }, { 62, -44, 30, "QtPine_5" }, { -68, 6, 24, "QtPine_5" }, { 69, 22, 27, "QtPine_1" }, { -64, 40, 26, "QtPine_1" } } do
	plant(WildKit, t[4], t[1], t[2], t[3])
end
-- flower bushes inside, in the corners and by the lamps
for _, b in { { -42, -48, 8 }, { 42, -48, 8 }, { -45, 45, 7.5 }, { 46, 46, 7.5 }, { -20, 57, 7 }, { 20, 57, 7 }, { -52.5, 12, 6.5 }, { 52.5, -4, 6.5 } } do
	plant(WildKit, "QtBush_Common_Flowers", b[1], b[2], b[3], true)
end

root.Parent = mapRoot

-- ===== the count =====
local parts, instances, tri = 0, 0, 0
local meshTris = { QtPine_1 = 1700, QtPine_5 = 1650, QtBush_Common_Flowers = 400 }
for _, d in root:GetDescendants() do
	instances += 1
	if d:IsA("BasePart") then
		parts += 1
		if d:IsA("WedgePart") then
			tri += 8
		elseif d:IsA("Part") then
			tri += if d.Shape == Enum.PartType.Block then 12 else 100
		end
	end
end
for _, m in dress:GetChildren() do
	tri += meshTris[m.Name] or 0
end
return string.format("Arena at world (%.0f, %.0f, %.0f): %d parts, %d instances, about %d triangles (primitives counted high)", W0.X, G, W0.Z, parts, instances, tri)
