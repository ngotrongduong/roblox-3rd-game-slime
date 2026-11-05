--!nocheck
-- Builds the Arena scene (ReplicatedStorage.ArenaStage, drawn by client/ArenaStage.luau on the attacking player's client only).
-- One file, two ways to run it, both from nothing (re-runnable):
--   Studio (the work place StudioTest.rbxl, Edit mode, for looking):
--     node tools/studio_mcp.js run tools/map/build_arena_stage.luau <studio_id> Edit
--     builds ReplicatedStorage.ArenaStage and a copy workspace.ArenaStagePreview at Config.Arena.Stage.Origin for shots.
--   Lune (what goes into the game; no Studio needed):
--     lune run tools/map/build_arena_stage.luau
--     writes assets/ArenaStage.rbxm (Rojo puts it in ReplicatedStorage.ArenaStage; tools/build_publish.luau copies it
--     into the published place).
-- The model's frame: the Pit's top centre is (0, 0, 0). The blue gate and the player's seat are on +Z, the orange gate and the
-- royal box on -Z; the camera (`View`) looks along -Z. Angles (degrees) run from +Z (0) round to -Z (180).
-- Look: the concept art/concept/arena-stage-view.webp (the view) and the close-ups arena-detail-1-stands, -2-royalbox (and
-- -2b), -3-arcade and -4-gate. Classic stud look on floors and caps, cream stone walls laid in offset courses (blocks of three
-- creams with a gap that shows the darker core as mortar), flat colours, shared sizes, no unions, no text anywhere. Everything
-- is Parts and a few Decals (pictures uploaded from art/icons/arena_*.png), so a Lune run needs nothing from Studio.
-- Detail is spent where the seat's camera looks: ring pieces nearer than DETAIL_FROM degrees to the blue gate are never in
-- frame and are built plain.

-- ===== which runtime =====
local roblox: any = nil
do
	local ok, lib = pcall(function()
		return (require :: any)("@lune/roblox")
	end)
	if ok then
		roblox = lib
	end
end
local LUNE = roblox ~= nil
local Instance: any = if LUNE then roblox.Instance else Instance
local Vector3: any = if LUNE then roblox.Vector3 else Vector3
local Vector2: any = if LUNE then roblox.Vector2 else Vector2
local CFrame: any = if LUNE then roblox.CFrame else CFrame
local Color3: any = if LUNE then roblox.Color3 else Color3
local Enum: any = if LUNE then roblox.Enum else Enum
local ColorSequence: any = if LUNE then roblox.ColorSequence else ColorSequence
local NumberSequence: any = if LUNE then roblox.NumberSequence else NumberSequence
local NumberSequenceKeypoint: any = if LUNE then roblox.NumberSequenceKeypoint else NumberSequenceKeypoint
local NumberRange: any = if LUNE then roblox.NumberRange else NumberRange

local ORIGIN = Vector3.new(0, 500, 9000) -- Config.Arena.Stage.Origin (the preview in Studio only)
local OUT = "assets/ArenaStage.rbxm"

-- ===== pictures (rbxassetid) =====
local IMG = {
	crest = "rbxassetid://93953857395806", -- sand crest: crowned slime face and laurels
	blueCircle = "rbxassetid://112750484203202",
	orangeCircle = "rbxassetid://101709964447020",
	blueBanner = "rbxassetid://124390176479990",
	orangeBanner = "rbxassetid://91266776612077",
	blueShield = "rbxassetid://102433418322300", -- gate shields with the crown (art/icons/arena_shield_*.png)
	orangeShield = "rbxassetid://84359194905186",
	emblem = "rbxassetid://134708042395076", -- royal-box medallion (art/icons/arena_emblem.png)
}

-- ===== colours =====
local function rgb(r: number, g: number, b: number): any
	return Color3.fromRGB(r, g, b)
end
local COL = {
	-- (warmer than a plain cream: under the game's bright sun the first creams read as white)
	cream = rgb(234, 200, 146),
	stoneB = rgb(222, 184, 128),
	stoneC = rgb(242, 214, 164),
	mortar = rgb(168, 126, 82),
	creamShade = rgb(226, 202, 152),
	blue = rgb(40, 100, 232),
	blueDeep = rgb(26, 62, 170),
	floorBlue = rgb(112, 130, 226),
	latticeBack = rgb(150, 170, 242),
	gold = rgb(255, 196, 40),
	sand = rgb(232, 190, 120),
	orange = rgb(255, 128, 30),
	orangeDeep = rgb(232, 96, 22),
	red = rgb(172, 48, 38),
	brick = rgb(150, 62, 48),
	curtain = rgb(214, 74, 36),
	wood = rgb(142, 92, 58),
	pot = rgb(214, 110, 40),
	potRim = rgb(246, 156, 56),
	leaf = rgb(70, 170, 70),
	leafLight = rgb(96, 190, 80),
	white = rgb(250, 250, 250),
	-- (a soft, hazy green: the full grass green filled the open arches as flat bright panels)
	grass = rgb(136, 178, 112),
	iron = rgb(44, 48, 76),
	bronze = rgb(150, 96, 52),
	lampGlow = rgb(232, 92, 22),
	tunnel = rgb(128, 52, 30),
	tunnelGlow = rgb(240, 78, 24),
}

-- ===== a seeded random (so a re-run gives the same stones and crowd) =====
local seed = 20261105
local function rnd(): number
	seed = (seed * 16807) % 2147483647
	return seed / 2147483647
end

-- ===== helpers =====
local PI = math.pi
local STEP = 10 -- degrees one ring piece spans
local WEDGE = 20 -- degrees either side of the blue gate and the orange gate left free for them
local DETAIL_FROM = 50 -- ring pieces nearer the blue gate than this (degrees) are behind or beside the seat: built plain
local partCount = 0
local MAT = Enum.Material
local SM = Enum.SurfaceType.Smooth

local function mk(parent: any, name: string, size: any, cf: any, colour: any, o: any?): any
	local opt = o or {}
	local p = Instance.new("Part")
	p.Name = name
	if opt.shape then
		p.Shape = opt.shape
	end
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = opt.collide == true
	p.CanTouch = false
	p.CanQuery = opt.query == true
	p.Color = colour
	p.Material = opt.mat or MAT.SmoothPlastic
	p.TopSurface = if opt.studs then Enum.SurfaceType.Studs else SM
	p.BottomSurface = SM
	p.LeftSurface = SM
	p.RightSurface = SM
	p.FrontSurface = SM
	p.BackSurface = SM
	if opt.shadow ~= nil then
		p.CastShadow = opt.shadow
	else
		p.CastShadow = size.Magnitude >= 7
	end
	if opt.trans then
		p.Transparency = opt.trans
	end
	if opt.reflect then
		p.Reflectance = opt.reflect
	end
	p.Parent = parent
	partCount += 1
	return p
end

local function wedge(parent: any, name: string, size: any, cf: any, colour: any): any
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Anchored = true
	w.CanCollide = false
	w.CanTouch = false
	w.CanQuery = false
	w.CastShadow = false
	w.Color = colour
	w.Material = MAT.SmoothPlastic
	w.TopSurface = SM
	w.BottomSurface = SM
	w.Parent = parent
	partCount += 1
	return w
end

local function folder(parent: any, name: string): any
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- A box given by its extents in a frame F. Every frame here has x across, y up and -z pointing OUT of the face toward the
-- viewer (the middle of the arena), so "proud" means negative z.
local function lb(parent: any, name: string, F: any, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, colour: any, o: any?): any
	return mk(parent, name, Vector3.new(x1 - x0, y1 - y0, z1 - z0), F * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour, o)
end

-- the frame of a ring piece: lx across (tangent), y up, lz out (radial); its -Z looks at the middle
local function ringCF(r: number, aDeg: number, y: number): any
	local a = math.rad(aDeg)
	return CFrame.new(r * math.sin(a), y, r * math.cos(a)) * CFrame.Angles(0, a, 0)
end
local function chordAt(r: number): number
	return 2 * r * math.tan(math.rad(STEP / 2))
end
local function ring(parent: any, name: string, aDeg: number, rIn: number, rOut: number, y0: number, y1: number, colour: any, o: any?): any
	return mk(parent, name, Vector3.new(chordAt(rOut) + 0.02, y1 - y0, rOut - rIn), ringCF((rIn + rOut) / 2, aDeg, (y0 + y1) / 2), colour, o)
end
local function polar(r: number, aDeg: number, y: number): any
	local a = math.rad(aDeg)
	return Vector3.new(r * math.sin(a), y, r * math.cos(a))
end
local function fromBlue(aDeg: number): number
	return math.abs(((aDeg + 180) % 360) - 180)
end
local function detailed(aDeg: number): boolean
	return fromBlue(aDeg) >= DETAIL_FROM
end

-- an upright cylinder (Roblox cylinders lie along X)
local function cyl(parent: any, name: string, pos: any, diameter: number, height: number, colour: any, o: any?): any
	local opt = o or {}
	opt.shape = Enum.PartType.Cylinder
	return mk(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, PI / 2), colour, opt)
end
-- a cylinder lying along the frame's x (a rod)
local function rod(parent: any, name: string, cf: any, length: number, diameter: number, colour: any, o: any?): any
	local opt = o or {}
	opt.shape = Enum.PartType.Cylinder
	return mk(parent, name, Vector3.new(length, diameter, diameter), cf, colour, opt)
end
local function ball(parent: any, name: string, pos: any, sx: number, sy: number, sz: number, colour: any, o: any?): any
	local opt = o or {}
	opt.shape = Enum.PartType.Ball
	return mk(parent, name, Vector3.new(sx, sy, sz), CFrame.new(pos), colour, opt)
end

-- a picture on a flat invisible part (a Decal draws on a part with Transparency 1)
local function picture(parent: any, name: string, cf: any, w: number, h: number, image: string, face: any, o: any?): any
	local opt = o or {}
	-- (a picture on the Top face reads upright from the -Z side after this half turn: its top points to -Z, the orange gate)
	local p = mk(parent, name, Vector3.new(w, 0.1, h), if face == Enum.NormalId.Top then cf * CFrame.Angles(0, PI, 0) else cf, COL.white, { trans = 1, shadow = false, query = opt.query })
	local d = Instance.new("Decal")
	d.Texture = image
	d.Face = face
	if opt.tint then
		d.Color3 = opt.tint
	end
	if opt.alpha then
		d.Transparency = opt.alpha
	end
	d.Parent = p
	return p
end
-- a picture standing upright, facing along the CFrame's -Z
local function sign(parent: any, name: string, cf: any, size: number, image: string): any
	local p = mk(parent, name, Vector3.new(size, size, 0.1), cf, COL.white, { trans = 1, shadow = false })
	local d = Instance.new("Decal")
	d.Texture = image
	d.Face = Enum.NormalId.Front
	d.Parent = p
	return p
end

-- a banner on a gold rod with a knob at each end, hanging from (x, yTop) on the face of frame F
local function hangBanner(parent: any, F: any, x: number, yTop: number, z: number, size: number, image: string)
	local w = size * 0.5
	rod(parent, "BannerRod", F * CFrame.new(x, yTop, z - 0.15), w + 0.4, size * 0.07 + 0.12, COL.gold, { shadow = false })
	for _, sx in { -1, 1 } do
		ball(parent, "BannerKnob", (F * CFrame.new(x + sx * (w / 2 + 0.3), yTop, z - 0.15)).Position, size * 0.12 + 0.2, size * 0.12 + 0.2, size * 0.12 + 0.2, COL.gold, { shadow = false })
	end
	sign(parent, "Banner", F * CFrame.new(x, yTop - size / 2 + size * 0.06, z), size, image)
end

local function glow(parent: any, pos: any, colour: any, brightness: number, range: number)
	local holder = mk(parent, "Glow", Vector3.new(0.4, 0.4, 0.4), CFrame.new(pos), COL.white, { trans = 1, shadow = false })
	local l = Instance.new("PointLight")
	l.Color = colour
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = holder
end

-- a flame: two emitters on an attachment in a tiny invisible part (the game's own fire texture)
local function flame(parent: any, pos: any, scale: number)
	local holder = mk(parent, "Fire", Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), COL.white, { trans = 1, shadow = false })
	local at = Instance.new("Attachment")
	at.Name = "Flames"
	at.Parent = holder
	local function layer(c0: any, c1: any, size: number, life: number, rate: number, speed: number)
		local e = Instance.new("ParticleEmitter")
		e.Name = "Flame"
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Color = ColorSequence.new(c0, c1)
		-- (full light emission washes the flame to white against the bright sky the seat looks into;
		-- 0.35 read as grey smoke; a dark red tail still read as brown smoke high on the towers, so the tail fades early)
		e.LightEmission = 0.65
		e.LightInfluence = 0
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, size),
			NumberSequenceKeypoint.new(0.4, size * 1.1),
			NumberSequenceKeypoint.new(1, size * 0.15),
		})
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, 0.05),
			NumberSequenceKeypoint.new(0.55, 0.3),
			NumberSequenceKeypoint.new(0.8, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Lifetime = NumberRange.new(life * 0.7, life)
		e.Rate = rate
		e.Speed = NumberRange.new(speed * 0.7, speed)
		e.SpreadAngle = Vector2.new(10, 10)
		e.RotSpeed = NumberRange.new(-30, 30)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = at
	end
	layer(rgb(255, 110, 20), rgb(235, 60, 10), 3.2 * scale, 0.9, 9, 3.4 * scale)
	layer(rgb(255, 205, 60), rgb(255, 110, 20), 1.7 * scale, 0.6, 7, 2.6 * scale)
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 160, 80)
	-- (a full light on each small gate torch washed the orange gate to yellow)
	l.Brightness = 0.8 * math.min(scale, 1)
	l.Range = 6 + 6 * math.min(scale, 1)
	l.Shadows = false
	l.Parent = holder
end

-- Stone courses on a face of frame F: rows of offset blocks in three creams over x0..x1, y0..y1, standing `proud` out of the
-- face plane zFace, with a GAP between them so the darker core behind reads as mortar.
local GAP = 0.14
local STONE = { COL.cream, COL.stoneB, COL.stoneC, COL.cream, COL.stoneB }
local function courses(parent: any, F: any, x0: number, x1: number, y0: number, y1: number, rowH: number, blockW: number, zFace: number?, proud: number?)
	local rows = math.max(1, math.floor((y1 - y0) / rowH + 0.5))
	local rh = (y1 - y0) / rows
	local n = math.max(1, math.floor((x1 - x0) / blockW + 0.5))
	local bw = (x1 - x0) / n
	local zf = zFace or 0
	local pr = proud or 0.15
	for r = 0, rows - 1 do
		local ya = y0 + r * rh
		local xs = { x0 }
		local x = x0 + (if r % 2 == 1 then bw / 2 else bw)
		while x < x1 - 0.25 do
			table.insert(xs, x)
			x += bw
		end
		table.insert(xs, x1)
		for i = 1, #xs - 1 do
			local shade = STONE[1 + math.floor(rnd() * #STONE)]
			lb(parent, "Stone", F, xs[i] + GAP / 2, xs[i + 1] - GAP / 2, ya + GAP / 2, ya + rh - GAP / 2, zf - pr, zf + 0.5, shade, { shadow = false })
		end
	end
end

-- An X lattice: one crossed pair of bars a cell over x0..x1, y0..y1, at depth z of frame F.
local function lattice(parent: any, F: any, x0: number, x1: number, y0: number, y1: number, z: number, cellW: number, colour: any, thick: number)
	local n = math.max(1, math.floor((x1 - x0) / cellW + 0.5))
	local cw = (x1 - x0) / n
	local h = y1 - y0
	local len = math.sqrt(cw * cw + h * h) - thick * 0.6
	local ang = math.atan2(h, cw)
	for i = 0, n - 1 do
		local cx = x0 + cw * (i + 0.5)
		for k, s in { 1, -1 } do
			-- (the two bars of an X sit 0.04 apart in depth so their crossing does not flicker)
			mk(parent, "Lattice", Vector3.new(len, thick, 0.18), F * CFrame.new(cx, (y0 + y1) / 2, z - k * 0.04) * CFrame.Angles(0, 0, s * ang), colour, { shadow = false })
		end
	end
end

-- A round arch ring of n stones in frame F: centre (0, ys), inner radius rIn, `t` thick, front at zFront, every other stone a
-- touch prouder (their ends overlap at the inner edge). colours = a list cycled; `key` (optional) builds the top stone.
local function archRing(parent: any, F: any, ys: number, rIn: number, t: number, n: number, zFront: number, depth: number, colours: { any }, key: any?)
	local rm = rIn + t / 2
	local len = 2 * rm * math.tan(PI / (2 * n)) * 0.97
	for i = 0, n - 1 do
		local th = PI * (i + 0.5) / n
		local cf = F * CFrame.new(math.cos(th) * rm, ys + math.sin(th) * rm, 0) * CFrame.Angles(0, 0, th - PI / 2)
		if key and i == (n - 1) / 2 then
			key(cf, len)
		else
			local zf = zFront - (i % 2) * 0.05
			mk(parent, "Voussoir", Vector3.new(len, t, depth), cf * CFrame.new(0, 0, zf + depth / 2), colours[(i % #colours) + 1], { shadow = false })
		end
	end
end

-- The wall round an arch opening that the ring does not cover: stepped blocks outside the ring's middle circle, in frame F,
-- between the opening's centre line and |x| = xOut, from the springing line ys up to ys + height.
local function spandrels(parent: any, F: any, ys: number, rMid: number, height: number, xOut: number, z0: number, z1: number, colour: any)
	local slices = 4
	for j = 0, slices - 1 do
		local y0 = ys + height * j / slices
		local y1 = ys + height * (j + 1) / slices
		local dy = y1 - ys
		local xin = math.sqrt(math.max(0, rMid * rMid - dy * dy))
		if xin < xOut then
			for _, sx in { -1, 1 } do
				local a, b = sx * xin, sx * xOut
				lb(parent, "Spandrel", F, math.min(a, b), math.max(a, b), y0, y1, z0, z1, colour, { shadow = false })
			end
		end
	end
end

local function yieldNow()
	if not LUNE then
		task.wait()
	end
end

-- ===== the model =====
local model = Instance.new("Model")
model.Name = "ArenaStage"
local sandF = folder(model, "Sand")
local wallF = folder(model, "Wall")
local standsF = folder(model, "Stands")
local arcadeF = folder(model, "Arcade")
local towerF = folder(model, "Towers")
local southF = folder(model, "BlueGate")
local deckF = folder(model, "Seat")
local northF = folder(model, "OrangeGate")
local boxF = folder(model, "RoyalBox")
local flagsF = folder(model, "Bunting")
local bannerF = folder(model, "Banners")
local plantF = folder(model, "Planters")
local landF = folder(model, "Landscape")
local crowd = folder(model, "Crowd")

-- which ring pieces exist: everything but the two gate wedges
local function sectors(): { number }
	local list = {}
	for i = 0, 35 do
		local a = 5 + STEP * i
		local fb = fromBlue(a)
		if fb >= WEDGE and (180 - fb) >= WEDGE then
			table.insert(list, a)
		end
	end
	return list
end
local SECTORS = sectors()

-- ===== the sand =====
local pit = mk(sandF, "Pit", Vector3.new(76, 2, 76), CFrame.new(0, -1, 0), COL.sand, { mat = MAT.Plastic, studs = true, collide = true, query = true, shadow = false })
-- the crest and the two team circles (pictures on the sand; their parts are the spots the contract names)
picture(sandF, "Crest", CFrame.new(0, 0.32, 0), 30, 30, IMG.crest, Enum.NormalId.Top, { alpha = 0.15, tint = rgb(170, 190, 255) })
local blueSpot = picture(sandF, "BlueSpot", CFrame.new(0, 0.34, 20), 16, 16, IMG.blueCircle, Enum.NormalId.Top, { alpha = 0.05 })
local orangeSpot = picture(sandF, "OrangeSpot", CFrame.new(0, 0.34, -20), 16, 16, IMG.orangeCircle, Enum.NormalId.Top, { alpha = 0.05 })

-- ===== the low wall round the sand: a blue foot, three courses of stone, a cream coping and a blue studded cap =====
local W0_IN, W0_OUT, W0_TOP = 35, 37.2, 4.8
for _, a in SECTORS do
	local F = ringCF(W0_IN, a, 0)
	local c = chordAt(W0_IN)
	local fine = detailed(a)
	ring(wallF, "Wall", a, W0_IN, W0_OUT, 0, W0_TOP - 0.9, if fine then COL.mortar else COL.cream)
	lb(wallF, "WallFoot", F, -c / 2, c / 2, 0, 0.7, -0.3, 0.6, COL.blue, { mat = MAT.Plastic, shadow = false })
	if fine then
		courses(wallF, F, -c / 2, c / 2, 0.7, W0_TOP - 0.9, 1.07, 3.0)
	end
	lb(wallF, "WallCoping", F, -c / 2 - 0.03, c / 2 + 0.03, W0_TOP - 0.9, W0_TOP - 0.45, -0.45, 2.2, COL.stoneC, { shadow = false })
	ring(wallF, "WallCap", a, W0_IN - 0.3, W0_OUT + 0.1, W0_TOP - 0.45, W0_TOP + 0.05, COL.blue, { mat = MAT.Plastic, studs = true })
end
local function finial(parent: any, aDeg: number, rr: number, y: number, size: number)
	local pos = polar(rr, aDeg, 0)
	local cf = ringCF(rr, aDeg, 0)
	mk(parent, "PostFoot", Vector3.new(size + 0.5, 1.0, size + 0.5), cf * CFrame.new(0, 0.5, 0), COL.blue, { mat = MAT.Plastic })
	mk(parent, "Post", Vector3.new(size, y - 1.0, size), cf * CFrame.new(0, 1.0 + (y - 1.0) / 2, 0), COL.stoneC)
	mk(parent, "PostBand", Vector3.new(size + 0.3, 0.6, size + 0.3), cf * CFrame.new(0, y - 0.9, 0), COL.blue, { mat = MAT.Plastic })
	mk(parent, "PostCap", Vector3.new(size + 0.6, 0.7, size + 0.6), cf * CFrame.new(0, y + 0.35, 0), COL.gold, { mat = MAT.Plastic, studs = false })
	ball(parent, "Ball", pos + Vector3.new(0, y + 0.7 + size * 0.5, 0), size * 0.95, size * 0.95, size * 0.95, COL.gold, { mat = MAT.SmoothPlastic, reflect = 0.08 })
end
for k = 1, 17 do
	local a = 20 * k
	if a >= 20 and a <= 160 or a >= 200 and a <= 340 then
		finial(wallF, a, 36.1, 6.6, 2.1)
	end
end
-- small banners on gold rods hang from the wall's coping between the posts
for k = 0, 6 do
	local a = 30 + 20 * k
	for _, aa in { a, 360 - a } do
		local img = if aa > 100 and aa < 260 then IMG.orangeBanner else IMG.blueBanner
		hangBanner(bannerF, ringCF(W0_IN, aa, 0), 0, W0_TOP - 1.05, -0.6, 4.0, img)
	end
end
yieldNow()

-- ===== the stands: three tiers =====
-- Each tier: a stone riser (courses, a capped coping), a blue studded floor, and on tiers 2-3 a rail at the front edge (a
-- light-blue panel with blue X lattice, a cream top rail) with gold-capped posts every other piece. Tier 1's front is the
-- sand wall. Aisles with stairs split the stands into bays; banners hang on the riser faces; planters at the bay ends.
local TIERS = {
	{ rIn = 37.2, rOut = 44, floor = 3.4 },
	{ rIn = 44, rOut = 51, floor = 6.8 },
	{ rIn = 51, rOut = 58, floor = 10.2 },
}
local AISLES = { 65, 115, 245, 295 } -- sector centres; each runs up to an open arch of the arcade
local AISLE_HALF = 2.1
local function isAisle(a: number): boolean
	for _, x in AISLES do
		if x == a then
			return true
		end
	end
	return false
end
-- banners on the riser faces: { angle, tier whose riser they hang on }
local TIER_BANNERS = {}
for _, b in { { 85, 2 }, { 135, 2 }, { 95, 3 }, { 145, 3 } } do
	table.insert(TIER_BANNERS, { a = b[1], t = b[2] })
	table.insert(TIER_BANNERS, { a = 360 - b[1], t = b[2] })
end

local function railPost(F: any, x: number, y: number)
	lb(standsF, "RailPost", F, x - 0.6, x + 0.6, y - 0.75, y + 2.0, -0.45, 0.75, COL.stoneC)
	lb(standsF, "RailPostCap", F, x - 0.8, x + 0.8, y + 2.0, y + 2.4, -0.65, 0.95, COL.gold, { mat = MAT.Plastic, shadow = false })
	ball(standsF, "RailPostBall", (F * CFrame.new(x, y + 2.95, 0.15)).Position, 1.1, 1.1, 1.1, COL.gold, { reflect = 0.08, shadow = false })
end

local function stairs(F: any, yLow: number, yHigh: number, n: number, tread: number, half: number)
	local rise = (yHigh - yLow) / n
	for k = 1, n do
		local top = yLow + k * rise
		local zFront = -(n - k + 1) * tread
		lb(standsF, "Step", F, -half, half, yLow, top - 0.25, zFront, 0, COL.stoneC, { shadow = false })
		lb(standsF, "Tread", F, -half, half, top - 0.25, top, zFront, if k == n then 0.85 else zFront + tread, COL.blue, { mat = MAT.Plastic, studs = true, shadow = false })
	end
	-- a sloping cream cheek wall each side
	local L, H = n * tread, yHigh - yLow
	local len = math.sqrt(L * L + H * H)
	local ang = math.atan2(H, L)
	for _, sx in { -1, 1 } do
		mk(standsF, "Cheek", Vector3.new(0.5, 0.9, len), F * CFrame.new(sx * (half + 0.25), yLow + H / 2 + 0.3, -L / 2) * CFrame.Angles(-ang, 0, 0), COL.stoneC, { shadow = false })
	end
end

for t, tier in TIERS do
	for _, a in SECTORS do
		local fine = detailed(a)
		local F = ringCF(tier.rIn, a, 0)
		local c = chordAt(tier.rIn)
		local aisle = isAisle(a)
		if t == 1 then
			ring(standsF, "Riser", a, tier.rIn, tier.rOut, 0, tier.floor - 0.7, COL.cream)
			ring(standsF, "Floor", a, tier.rIn - 0.2, tier.rOut, tier.floor - 0.7, tier.floor, COL.floorBlue, { mat = MAT.Plastic, studs = true })
		else
			local yLow = TIERS[t - 1].floor
			ring(standsF, "Riser", a, tier.rIn, tier.rOut, 0, tier.floor - 0.75, if fine then COL.mortar else COL.cream)
			ring(standsF, "Floor", a, tier.rIn + 0.8, tier.rOut, tier.floor - 0.75, tier.floor, COL.floorBlue, { mat = MAT.Plastic, studs = true })
			if fine then
				courses(standsF, F, -c / 2, c / 2, yLow, tier.floor - 0.75, 1.1, 2.8)
			end
			-- the coping and the rail, split round an aisle
			local spans = if aisle then { { -c / 2, -AISLE_HALF - 0.5 }, { AISLE_HALF + 0.5, c / 2 } } else { { -c / 2, c / 2 } }
			for _, s in spans do
				local x0, x1 = s[1], s[2]
				lb(standsF, "Coping", F, x0 - 0.03, x1 + 0.03, tier.floor - 0.75, tier.floor, -0.4, 0.8, COL.stoneC, { studs = true, shadow = false })
				lb(standsF, "RailPanel", F, x0, x1, tier.floor, tier.floor + 1.2, 0.1, 0.4, COL.latticeBack, { shadow = false })
				lb(standsF, "RailTop", F, x0, x1, tier.floor + 1.2, tier.floor + 1.55, -0.15, 0.6, COL.stoneC, { shadow = false })
				if fine then
					lattice(standsF, F, x0, x1, tier.floor, tier.floor + 1.2, 0.05, 2.5, COL.blue, 0.3)
				end
			end
			if aisle then
				for _, sx in { -1, 1 } do
					railPost(F, sx * (AISLE_HALF + 0.5), tier.floor)
				end
				stairs(F, yLow, tier.floor, 4, 1.0, AISLE_HALF)
			end
			-- gold-capped posts at every other joint (the joint on the piece's low-angle side)
			if fine and ((a - 5) % 20 == 0) then
				railPost(ringCF(tier.rIn, a - 5, 0), 0, tier.floor)
			end
		end
	end
	yieldNow()
end
-- the banners on the riser faces
for _, b in TIER_BANNERS do
	local tier = TIERS[b.t]
	hangBanner(bannerF, ringCF(tier.rIn, b.a, 0), 0, tier.floor - 0.95, -0.6, 3.6, IMG.blueBanner)
end
yieldNow()

-- ===== the upper arcade =====
-- Each bay: a sill, piers, a round arch of stone voussoirs with a gold keystone, imposts at the springing line, a blue band, a
-- blue X lattice band, a cream coping and the studded roof walk with its parapet. Pilasters at the joints (blue foot, stone
-- shaft, a gold rosette, a blue cap standing over the coping). Most arches are open to the land with a gold rail across;
-- every third is closed by a deep-blue panel. Arches at the aisles are open and reached by two steps.
local ARC_IN, ARC_OUT = 58, 61
local SILL, OPEN_BOT, WALL_TOP = 10.2, 12.0, 24.0
local ARCH_R, ARCH_T, SPRING = 3.1, 1.0, 16.0
local BAND0, BAND1, LAT1, COPE1 = 20.4, 21.1, 23.2, 24.0
local TOWERS = { 40, 80, 120, 160, 200, 240, 280, 320 } -- joints where a tower stands instead of a pilaster
local BIG_BANNERS = { { 100, IMG.blueBanner }, { 140, IMG.orangeBanner }, { 220, IMG.orangeBanner }, { 260, IMG.blueBanner } }
local function isTower(b: number): boolean
	for _, x in TOWERS do
		if x == b then
			return true
		end
	end
	return false
end
local function isBigBanner(b: number): boolean
	for _, x in BIG_BANNERS do
		if x[1] == b then
			return true
		end
	end
	return false
end

local function pilaster(b: number)
	local F = ringCF(ARC_IN, b, 0)
	lb(arcadeF, "PilasterFoot", F, -1.25, 1.25, OPEN_BOT, OPEN_BOT + 1.2, -0.75, 0.3, COL.blue, { mat = MAT.Plastic, shadow = false })
	courses(arcadeF, F, -1.05, 1.05, OPEN_BOT + 1.2, BAND0 - 0.6, 2.2, 2.1, 0, 0.5)
	if not isBigBanner(b) then
		lb(arcadeF, "Rosette", F, -0.95, 0.95, BAND0 - 0.6, BAND1 + 0.5, -0.8, 0.2, COL.gold, { mat = MAT.Plastic, shadow = false })
		ball(arcadeF, "RosetteBoss", (F * CFrame.new(0, (BAND0 + BAND1) / 2 - 0.05, -0.85)).Position, 0.95, 0.95, 0.95, COL.gold, { reflect = 0.1, shadow = false })
	end
	courses(arcadeF, F, -1.05, 1.05, BAND1 + 0.5, LAT1, 3, 2.1, 0, 0.5)
	lb(arcadeF, "PilasterCap", F, -1.35, 1.35, LAT1, COPE1 + 0.9, -0.8, 1.2, COL.blue, { mat = MAT.Plastic, studs = true, shadow = false })
end

for i, a in SECTORS do
	local F = ringCF(ARC_IN, a, 0)
	local c = chordAt(ARC_OUT)
	local fine = detailed(a)
	local depth = ARC_OUT - ARC_IN
	local idx = (a - 5) // STEP
	-- (one in four is closed: one in three in deep blue read as a row of blue doors against the warm stone)
	local closed = (idx % 4 == 2) and not isAisle(a)
	if fine then
		-- the sill, a course of stone over a mortar core
		lb(arcadeF, "Sill", F, -c / 2, c / 2, SILL, OPEN_BOT, 0, depth, COL.mortar)
		courses(arcadeF, F, -c / 2, c / 2, SILL, OPEN_BOT, 1.8, 3.4)
		-- piers up to the springing line, the wall round the arch, the wall over it
		for _, sx in { -1, 1 } do
			lb(arcadeF, "Pier", F, math.min(sx * ARCH_R, sx * c / 2), math.max(sx * ARCH_R, sx * c / 2), OPEN_BOT, SPRING, 0, depth, COL.cream)
			lb(arcadeF, "Impost", F, math.min(sx * (ARCH_R - 0.25), sx * (ARCH_R + 1.3)), math.max(sx * (ARCH_R - 0.25), sx * (ARCH_R + 1.3)), SPRING - 0.55, SPRING, -0.35, 1.0, COL.stoneC, { shadow = false })
		end
		spandrels(arcadeF, F, SPRING, ARCH_R + ARCH_T / 2, ARCH_R + ARCH_T, c / 2, 0.1, depth, COL.cream)
		lb(arcadeF, "Upper", F, -c / 2, c / 2, SPRING + ARCH_R + 0.35, WALL_TOP, 0, depth, COL.cream)
		archRing(arcadeF, F, SPRING, ARCH_R, ARCH_T, 7, -0.3, 0.8, { COL.stoneC, COL.stoneB }, function(cf: any, len: number)
			mk(arcadeF, "Keystone", Vector3.new(len * 1.25, ARCH_T + 0.5, 1.0), cf * CFrame.new(0, 0.2, -0.05), COL.gold, { mat = MAT.Plastic, shadow = false })
			ball(arcadeF, "KeystoneBoss", (cf * CFrame.new(0, 0.25, -0.6)).Position, 0.75, 0.75, 0.75, COL.gold, { reflect = 0.1, shadow = false })
		end)
		lb(arcadeF, "Band", F, -c / 2, c / 2, BAND0, BAND1, -0.3, 0.3, COL.blue, { mat = MAT.Plastic, shadow = false })
		-- (lattice on every other bay, stone courses between: one unbroken lattice band read as a busy blue zigzag)
		if idx % 2 == 0 then
			lattice(arcadeF, F, -c / 2, c / 2, BAND1, LAT1, -0.1, 3.4, COL.blue, 0.26)
		else
			courses(arcadeF, F, -c / 2, c / 2, BAND1, LAT1, 1.05, 3.4)
		end
		lb(arcadeF, "Coping", F, -c / 2 - 0.03, c / 2 + 0.03, LAT1, COPE1, -0.45, depth + 0.2, COL.stoneC, { shadow = false })
		if closed then
			-- (set back at the arch's far face in a shadowed blue-grey: a saturated blue panel near the front read as a flat door)
			lb(arcadeF, "ArchBack", F, -ARCH_R, ARCH_R, OPEN_BOT, SPRING + ARCH_R + 0.4, depth - 0.4, depth, rgb(112, 128, 172), { shadow = false })
			lb(arcadeF, "ArchBackRail", F, -ARCH_R, ARCH_R, OPEN_BOT + 1.5, OPEN_BOT + 1.85, 1.0, 1.4, COL.gold, { mat = MAT.Plastic, shadow = false })
		else
			lb(arcadeF, "ArchRail", F, -ARCH_R, ARCH_R, OPEN_BOT + 1.5, OPEN_BOT + 1.85, 1.0, 1.4, COL.gold, { mat = MAT.Plastic, shadow = false })
			for _, sx in { -1, 1 } do
				lb(arcadeF, "ArchRailPost", F, sx * (ARCH_R - 0.6) - 0.18, sx * (ARCH_R - 0.6) + 0.18, OPEN_BOT, OPEN_BOT + 1.5, 1.05, 1.35, COL.gold, { mat = MAT.Plastic, shadow = false })
			end
		end
		if isAisle(a) then
			-- two steps from the top tier up into the arch
			for k = 1, 2 do
				lb(arcadeF, "ArchStep", F, -ARCH_R, ARCH_R, SILL, SILL + k * 0.9, -(3 - k) * 1.0, 0.0, COL.stoneC, { studs = true, shadow = false })
			end
		end
		-- the pilaster at this piece's low-angle joint (and at its far joint where the stands end)
		local b0 = a - 5
		if not isTower(b0) then
			pilaster(b0)
		end
		if fromBlue(a + 5) < DETAIL_FROM + 1 or (180 - fromBlue(a + 5)) < WEDGE + 1 then
			if not isTower(a + 5) then
				pilaster(a + 5)
			end
		end
	else
		-- out of the seat's frame: a plain bay
		local ow = 2 * ARCH_R
		local pier = (c - ow) / 2
		lb(arcadeF, "Sill", F, -c / 2, c / 2, SILL, OPEN_BOT, 0, depth, COL.cream)
		lb(arcadeF, "PierL", F, -c / 2, -c / 2 + pier, OPEN_BOT, SPRING + ARCH_R, 0, depth, COL.cream)
		lb(arcadeF, "PierR", F, c / 2 - pier, c / 2, OPEN_BOT, SPRING + ARCH_R, 0, depth, COL.cream)
		lb(arcadeF, "Lintel", F, -c / 2, c / 2, SPRING + ARCH_R, WALL_TOP, 0, depth, COL.cream)
		lb(arcadeF, "Band", F, -c / 2, c / 2, BAND0, BAND1, -0.3, 0.3, COL.blue, { mat = MAT.Plastic, shadow = false })
	end
	ring(arcadeF, "Roof", a, ARC_IN - 0.1, 66, WALL_TOP, WALL_TOP + 0.8, COL.floorBlue, { mat = MAT.Plastic, studs = true })
	ring(arcadeF, "Parapet", a, 64.8, 66, WALL_TOP + 0.8, WALL_TOP + 2.2, COL.cream)
	ring(arcadeF, "ParapetCap", a, 64.7, 66.1, WALL_TOP + 2.2, WALL_TOP + 2.6, COL.blue, { mat = MAT.Plastic, studs = true })
	if i % 6 == 0 then
		yieldNow()
	end
end

-- big banners on gold rods hang in front of the arcade's joints
for _, bb in BIG_BANNERS do
	hangBanner(bannerF, ringCF(ARC_IN, bb[1], 0), 0, BAND0 - 0.3, -1.1, 9.0, bb[2])
end
yieldNow()

-- ===== the towers: tall stone piers at joints of the arcade, blue bands, two blue badge panels with gold diamonds, a gold
-- brazier with fire on top =====
local TOWER_TOP = 29.0
for _, b in TOWERS do
	local F = ringCF(ARC_IN, b, 0)
	local fine = detailed(b)
	local z0, z1 = -1.6, 3.4
	lb(towerF, "Shaft", F, -1.9, 1.9, SILL, TOWER_TOP, z0 + 0.15, z1, if fine then COL.mortar else COL.cream)
	if fine then
		courses(towerF, F, -1.9, 1.9, SILL + 1.3, TOWER_TOP - 1.4, 1.6, 1.9, z0 + 0.15, 0.15)
		-- the badge panels: blue shields with a gold diamond
		for _, sx in { -1, 1 } do
			lb(towerF, "Badge", F, sx * 0.95 - 0.7, sx * 0.95 + 0.7, TOWER_TOP - 5.2, TOWER_TOP - 2.2, z0 - 0.3, z0 + 0.2, COL.blue, { mat = MAT.Plastic, shadow = false })
			mk(towerF, "BadgeDiamond", Vector3.new(0.8, 0.8, 0.3), F * CFrame.new(sx * 0.95, TOWER_TOP - 3.7, z0 - 0.4) * CFrame.Angles(0, 0, PI / 4), COL.gold, { mat = MAT.Plastic, shadow = false })
		end
	end
	lb(towerF, "TowerFoot", F, -2.25, 2.25, SILL, SILL + 1.3, z0 - 0.15, z1 + 0.3, COL.blue, { mat = MAT.Plastic, shadow = false })
	lb(towerF, "TowerBand", F, -2.2, 2.2, LAT1, COPE1 + 0.4, z0 - 0.2, z1 + 0.3, COL.blue, { mat = MAT.Plastic, studs = true, shadow = false })
	lb(towerF, "TowerCap", F, -2.45, 2.45, TOWER_TOP - 1.4, TOWER_TOP, z0 - 0.35, z1 + 0.35, COL.blue, { mat = MAT.Plastic, studs = true })
	local mid = (F * CFrame.new(0, 0, (z0 + z1) / 2)).Position
	-- (a bronze bowl under a gold rim: an all-gold bowl read as a bright yellow disc against the sky)
	cyl(towerF, "BrazierFoot", mid + Vector3.new(0, TOWER_TOP + 0.5, 0), 3.0, 1.0, COL.gold, { mat = MAT.Plastic })
	cyl(towerF, "Brazier", mid + Vector3.new(0, TOWER_TOP + 1.6, 0), 4.6, 1.4, COL.bronze, { reflect = 0.05 })
	cyl(towerF, "BrazierRim", mid + Vector3.new(0, TOWER_TOP + 2.45, 0), 5.1, 0.4, COL.gold, { mat = MAT.Plastic })
	cyl(towerF, "Embers", mid + Vector3.new(0, TOWER_TOP + 2.7, 0), 3.8, 0.2, rgb(255, 110, 30), { mat = MAT.Neon, shadow = false })
	flame(towerF, mid + Vector3.new(0, TOWER_TOP + 3.4, 0), 1.3)
end
yieldNow()

-- ===== the blue gate (under the seat: mostly out of frame, kept simple and clean) =====
local BLUE_Z = 40
local ORANGE_Z = -33
do
	local g = southF
	local zF, depth, main = BLUE_Z, 9, COL.blue
	local halfW, openW, openH, body = 13.5, 5.0, 6.6, 9.0
	local function blk(n: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, colour: any, o: any?): any
		return mk(g, n, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour, o)
	end
	blk("BodyL", -halfW, -(openW + 1.4), 0, body, zF - depth, zF, COL.cream)
	blk("BodyR", openW + 1.4, halfW, 0, body, zF - depth, zF, COL.cream)
	blk("Over", -(openW + 1.4), openW + 1.4, openH + 1.4, body, zF - depth, zF, COL.cream)
	blk("FrameL", -(openW + 1.4), -openW, 0, openH + 1.4, zF - 0.2, zF + 0.7, COL.gold, { mat = MAT.Plastic })
	blk("FrameR", openW, openW + 1.4, 0, openH + 1.4, zF - 0.2, zF + 0.7, COL.gold, { mat = MAT.Plastic })
	blk("FrameTop", -(openW + 1.4), openW + 1.4, openH, openH + 1.4, zF - 0.2, zF + 0.7, COL.gold, { mat = MAT.Plastic })
	blk("ArchBand", -(openW + 1.4), openW + 1.4, openH + 1.4, openH + 2.5, zF - 0.1, zF + 0.5, main, { mat = MAT.Plastic, studs = true })
	blk("TunnelFloor", -openW, openW, 0, 0.35, zF - depth, zF, rgb(36, 96, 255), { mat = MAT.Neon, shadow = false })
	blk("TunnelWallL", -openW, -openW + 0.5, 0, openH, zF - depth, zF - 0.4, COL.blueDeep, { mat = MAT.Plastic })
	blk("TunnelWallR", openW - 0.5, openW, 0, openH, zF - depth, zF - 0.4, COL.blueDeep, { mat = MAT.Plastic })
	blk("TunnelRoof", -openW, openW, openH - 0.5, openH, zF - depth, zF - 0.4, COL.blueDeep, { mat = MAT.Plastic })
	glow(g, Vector3.new(0, 3.3, zF - depth / 2), rgb(60, 120, 255), 1.6, 18)
	blk("Roof1", -halfW, halfW, body, body + 0.9, zF - depth, zF + 0.4, main, { mat = MAT.Plastic, studs = true })
	blk("Roof2", -(halfW - 3), halfW - 3, body + 0.9, body + 1.8, zF - depth + 2, zF - 1.6, main, { mat = MAT.Plastic, studs = true })
	-- (the pylons stop at the roof: their raised caps were the only thing in the frame's lower corners and read as stray
	-- blue blocks)
	for _, sx in { -1, 1 } do
		local x0 = if sx < 0 then -halfW - 0.3 else halfW - 3
		blk("Pylon", x0, x0 + 3.3, 0, body + 0.9, zF - depth, zF + 0.4, COL.cream)
		blk("PylonBand", x0 - 0.2, x0 + 3.5, body - 0.4, body + 0.5, zF - depth - 0.2, zF + 0.6, main, { mat = MAT.Plastic })
		sign(bannerF, "GateBanner", CFrame.new(sx * 8.9, 4.6, zF + 0.2) * CFrame.Angles(0, PI, 0), 8.0, IMG.blueBanner)
	end
	blk("Pedestal", -2.6, 2.6, openH + 1.4, openH + 6.5, zF - 1.6, zF + 0.5, main, { mat = MAT.Plastic })
	sign(g, "Shield", CFrame.new(0, openH + 4.0, zF + 0.56) * CFrame.Angles(0, PI, 0), 5.0, IMG.blueShield)
end
yieldNow()

-- ===== the seat deck behind the blue gate and the camera =====
do
	local function blk(n: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, colour: any, o: any?): any
		return mk(deckF, n, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour, o)
	end
	blk("Plaza", -34, 34, -0.6, 0, BLUE_Z - 3, 64, COL.floorBlue, { mat = MAT.Plastic, studs = true, shadow = false })
	for _, sx in { -1, 1 } do
		blk("Rail", sx * 33 - 0.5, sx * 33 + 0.5, 0, 1.4, BLUE_Z - 2, 64, COL.cream)
		blk("RailCap", sx * 33 - 0.6, sx * 33 + 0.6, 1.4, 1.8, BLUE_Z - 2, 64, COL.blue, { mat = MAT.Plastic, studs = true })
		for _, z in { BLUE_Z - 1.5, 52 } do
			blk("Post", sx * 33 - 0.9, sx * 33 + 0.9, 0, 3.0, z - 0.9, z + 0.9, COL.cream)
			blk("PostCap", sx * 33 - 1.2, sx * 33 + 1.2, 3.0, 3.6, z - 1.2, z + 1.2, COL.gold, { mat = MAT.Plastic })
			ball(deckF, "Ball", Vector3.new(sx * 33, 4.7, z), 1.8, 1.8, 1.8, COL.gold, { reflect = 0.08 })
		end
	end
	-- the camera's seat (the player is not in the scene, only the camera: the owner, 2026-11-05)
	-- (from z 62 the blue gate's roof filled the lower half and the fighters were specks; from here, with
	-- Config.Arena.Stage.FieldOfView 50, the sand fills the frame under the royal box and the gate is below the frame)
	local view = mk(model, "View", Vector3.new(1, 1, 1), CFrame.new(0, 26.9, 50) * CFrame.Angles(-math.atan(18 / 58), 0, 0), COL.white, { trans = 1, shadow = false })
	view.Name = "View"
end

-- ===== a lantern: an iron frame with a glowing glass, hanging from a hook (wall fixtures are built, not generated) =====
local function lantern(parent: any, top: any, s: number)
	local function at(dy: number): any
		return top + Vector3.new(0, dy * s, 0)
	end
	mk(parent, "LanternHook", Vector3.new(0.18 * s, 0.9 * s, 0.18 * s), CFrame.new(at(-0.45)), COL.iron, { shadow = false })
	ball(parent, "LanternKnob", at(-1.0), 0.45 * s, 0.45 * s, 0.45 * s, COL.iron, { shadow = false })
	mk(parent, "LanternRoof", Vector3.new(1.3 * s, 0.4 * s, 1.3 * s), CFrame.new(at(-1.35)), COL.iron, { shadow = false })
	mk(parent, "LanternGlass", Vector3.new(0.85 * s, 1.2 * s, 0.85 * s), CFrame.new(at(-2.15)), COL.lampGlow, { mat = MAT.Neon, shadow = false })
	for _, d in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		mk(parent, "LanternBar", Vector3.new(0.16 * s, 1.25 * s, 0.16 * s), CFrame.new(at(-2.15) + Vector3.new(d[1] * 0.47 * s, 0, d[2] * 0.47 * s)), COL.iron, { shadow = false })
	end
	mk(parent, "LanternBase", Vector3.new(1.1 * s, 0.3 * s, 1.1 * s), CFrame.new(at(-2.9)), COL.iron, { shadow = false })
	ball(parent, "LanternDrop", at(-3.2), 0.4 * s, 0.4 * s, 0.4 * s, COL.iron, { shadow = false })
	glow(parent, at(-2.15), rgb(255, 170, 90), 0.7, 10)
end

-- ===== a wall torch: a bronze bracket, a cup and the flame recipe =====
local function torch(parent: any, F: any, x: number, y: number)
	lb(parent, "TorchPlate", F, x - 0.45, x + 0.45, y - 1.6, y - 0.2, -0.25, 0.1, COL.bronze, { shadow = false })
	lb(parent, "TorchArm", F, x - 0.18, x + 0.18, y - 1.3, y - 0.95, -1.1, -0.2, COL.bronze, { shadow = false })
	lb(parent, "TorchStem", F, x - 0.22, x + 0.22, y - 1.3, y, -1.3, -0.86, COL.bronze, { shadow = false })
	local cup = (F * CFrame.new(x, y + 0.3, -1.08)).Position
	cyl(parent, "TorchCup", cup, 1.0, 0.7, COL.bronze, { reflect = 0.05, shadow = false })
	cyl(parent, "TorchEmbers", cup + Vector3.new(0, 0.36, 0), 0.8, 0.1, rgb(255, 110, 30), { mat = MAT.Neon, shadow = false })
	flame(parent, cup + Vector3.new(0, 0.8, 0), 0.45)
end

-- ===== a planter: an orange box with a rim, a bush of three leaf balls and white flowers =====
local function planter(cf: any)
	mk(plantF, "Pot", Vector3.new(3.4, 1.3, 2.2), cf * CFrame.new(0, 0.65, 0), COL.pot, { shadow = false })
	mk(plantF, "PotRim", Vector3.new(3.8, 0.35, 2.6), cf * CFrame.new(0, 1.45, 0), COL.potRim, { shadow = false })
	for _, l in { { -0.8, 2.15, 0.1, 1.9, COL.leaf }, { 0.85, 2.2, 0.0, 2.0, COL.leafLight }, { 0.05, 2.75, -0.1, 2.1, COL.leaf } } do
		mk(plantF, "Bush", Vector3.new(l[4] * 1.1, l[4], l[4]), cf * CFrame.new(l[1], l[2], l[3]), l[5], { shape = Enum.PartType.Ball, shadow = false })
	end
	for _, f in { { -1.0, 2.75, -0.75 }, { 0.6, 3.25, -0.85 }, { 1.35, 2.45, -0.7 } } do
		mk(plantF, "Flower", Vector3.new(0.65, 0.65, 0.65), cf * CFrame.new(f[1], f[2], f[3]), COL.white, { shape = Enum.PartType.Ball, shadow = false })
	end
end

-- ===== the orange gate and the royal box over it: one front, built in the frame FN =====
-- FN: x across (mirrored, the front is symmetric), y up, -z toward the sand; the gate's face is z = 0 (world z ORANGE_Z), the
-- tunnel runs back to z 14. The podium face: stone courses, the gate's arch (gold voussoirs inside orange ones) with the
-- crowned shield on its keystone, a gold portcullis with spikes over a glowing tunnel, plinthed pilasters with gold balls,
-- wall torches, orange banners, gold scroll brackets under the balcony. The box: a balcony with a blue band and a lattice
-- balustrade, columns with bases and capitals, red back wall and curtains, orange swags with gold tassels, the trophy,
-- lanterns, a layered entablature, a brick-red pediment with gold rakes, the medallion and a gold crown; planters beside it.
local FN = CFrame.new(0, 0, ORANGE_Z) * CFrame.Angles(0, PI, 0)
local function w(p: any): any -- a point of FN in the model's frame
	return (FN * CFrame.new(p)).Position
end
do
	local G = northF
	local HALF = 16.5 -- the podium's half width
	local DEEP = 14 -- the podium's depth (the tunnel's length)
	local OR = 4.6 -- the opening's radius (half width)
	local YS = 4.8 -- the springing line
	local GT, OT = 1.0, 1.3 -- gold and orange ring thickness
	local RO = OR + GT + OT -- the rings' outer radius
	local SLAB0, SLAB1 = 14.2, 15.5 -- the balcony slab
	-- the core (mortar) round the opening
	lb(G, "CoreL", FN, -HALF, -OR, 0, SLAB1, 0, DEEP, COL.mortar)
	lb(G, "CoreR", FN, OR, HALF, 0, SLAB1, 0, DEEP, COL.mortar)
	lb(G, "CoreOver", FN, -OR, OR, YS + OR + 0.35, SLAB1, 0, DEEP, COL.mortar)
	-- the face: a blue foot and courses each side of the rings, and over them
	lb(G, "Foot", FN, -HALF, -RO, 0, 0.8, -0.35, 0.5, COL.blue, { mat = MAT.Plastic, shadow = false })
	lb(G, "Foot", FN, RO, HALF, 0, 0.8, -0.35, 0.5, COL.blue, { mat = MAT.Plastic, shadow = false })
	courses(G, FN, -HALF, -RO, 0.8, SLAB0, 1.2, 2.8)
	courses(G, FN, RO, HALF, 0.8, SLAB0, 1.2, 2.8)
	courses(G, FN, -RO, RO, YS + RO, SLAB0, 1.2, 2.8)
	spandrels(G, FN, YS, RO - OT / 2, RO, RO, -0.15, 0.6, COL.cream)
	-- the rings: gold voussoirs inside, orange outside; straight jambs below the springing line with gold impost blocks
	archRing(G, FN, YS, OR, GT, 9, -0.75, 1.2, { COL.gold, rgb(255, 210, 70) })
	archRing(G, FN, YS, OR + GT, OT, 11, -0.55, 1.0, { COL.orange, COL.orangeDeep })
	for _, sx in { -1, 1 } do
		local function xs(a: number, b: number): (number, number)
			return math.min(sx * a, sx * b), math.max(sx * a, sx * b)
		end
		local g0, g1 = xs(OR, OR + GT)
		lb(G, "JambGold", FN, g0, g1, 1.2, YS, -0.75, 0.45, COL.gold, { mat = MAT.Plastic, shadow = false })
		lb(G, "JambGoldFoot", FN, g0 - 0.15, g1 + 0.15, 0, 1.2, -0.9, 0.45, COL.gold, { mat = MAT.Plastic, shadow = false })
		local o0, o1 = xs(OR + GT, RO)
		lb(G, "JambOrange", FN, o0, o1, 0, YS - 0.6, -0.55, 0.45, COL.orange, { mat = MAT.Plastic, shadow = false })
		local i0, i1 = xs(OR + GT - 0.1, RO + 0.5)
		lb(G, "Impost", FN, i0, i1, YS - 0.6, YS, -0.8, 0.45, COL.gold, { mat = MAT.Plastic, shadow = false })
	end
	-- the crowned shield on the keystone
	sign(G, "Shield", FN * CFrame.new(0, YS + RO - 0.4, -0.95), 5.6, IMG.orangeShield)
	-- the tunnel: orange walls, a studded orange floor, an inner rib, a glowing back
	lb(G, "TunnelFloor", FN, -OR, OR, -0.3, 0.25, -0.2, DEEP - 1, COL.orange, { mat = MAT.Plastic, studs = true, shadow = false })
	lb(G, "TunnelWallL", FN, -OR - 0.2, -OR + 0.4, 0, YS + 1.5, 0.3, DEEP - 1, COL.tunnel, { shadow = false })
	lb(G, "TunnelWallR", FN, OR - 0.4, OR + 0.2, 0, YS + 1.5, 0.3, DEEP - 1, COL.tunnel, { shadow = false })
	lb(G, "TunnelRoof", FN, -OR, OR, YS + OR - 0.5, YS + OR + 0.4, 0.3, DEEP - 1, COL.tunnel, { shadow = false })
	for _, sx in { -1, 1 } do
		lb(G, "TunnelRib", FN, sx * (OR - 0.9) - 0.4, sx * (OR - 0.9) + 0.4, 0, YS + 1.0, 6.0, 7.0, COL.orangeDeep, { shadow = false })
	end
	lb(G, "TunnelRibTop", FN, -OR, OR, YS + 2.4, YS + OR, 6.0, 7.0, COL.orangeDeep, { shadow = false })
	-- (the glow is low, as in the gate close-up: a fire-lit floor at the far end, the dark wall above it)
	lb(G, "TunnelGlow", FN, -OR, OR, 0, YS - 0.8, DEEP - 1.4, DEEP - 1, COL.tunnelGlow, { mat = MAT.Neon, shadow = false })
	lb(G, "TunnelBack", FN, -OR, OR, YS - 0.8, YS + OR, DEEP - 1.4, DEEP - 1, COL.tunnel, { shadow = false })
	-- (deep in the tunnel and soft: a bright light at its mouth washed the whole gate front to fluorescent yellow)
	glow(G, w(Vector3.new(0, 2.5, 9)), rgb(255, 130, 50), 0.9, 11)
	-- the portcullis: gold bars following the arch, spikes under, raised a little so the glowing tunnel shows below
	local PZ, PB = 0.8, 1.6 -- its depth in the opening, the height of its lowest bar
	for i = -3, 3 do
		local x = i * 1.25
		local top = YS + math.sqrt(OR * OR - x * x) - 0.1
		lb(G, "PortBar", FN, x - 0.19, x + 0.19, PB, top, PZ, PZ + 0.35, COL.gold, { mat = MAT.Plastic, shadow = false })
		mk(G, "PortSpike", Vector3.new(0.5, 0.5, 0.3), FN * CFrame.new(x, PB - 0.05, PZ + 0.17) * CFrame.Angles(0, 0, PI / 4), COL.gold, { mat = MAT.Plastic, shadow = false })
	end
	for _, y in { PB + 0.35, 3.6, 5.5, 7.3, 8.7 } do
		local half = if y <= YS then OR - 0.05 else math.sqrt(math.max(0, OR * OR - (y - YS) ^ 2)) - 0.1
		lb(G, "PortRail", FN, -half, half, y - 0.19, y + 0.19, PZ - 0.1, PZ + 0.25, COL.gold, { mat = MAT.Plastic, shadow = false })
	end
	-- the threshold onto the sand
	lb(G, "Threshold", FN, -RO, RO, 0, 0.35, -4.0, 0, COL.orange, { mat = MAT.Plastic, studs = true, shadow = false })
	lb(G, "ThresholdEdge", FN, -RO - 0.2, RO + 0.2, 0, 0.45, -4.5, -4.0, COL.gold, { mat = MAT.Plastic, shadow = false })
	-- pilasters each side: an orange plinth, a gold block, stone, a gold-and-orange capital, stone, a blue band, a gold ball
	for _, sx in { -1, 1 } do
		local x = sx * 8.5
		lb(G, "PlinthOrange", FN, x - 1.6, x + 1.6, 0, 1.6, -1.2, 0.4, COL.orange, { mat = MAT.Plastic })
		lb(G, "PlinthGold", FN, x - 1.35, x + 1.35, 1.6, 2.5, -1.0, 0.3, COL.gold, { mat = MAT.Plastic, shadow = false })
		courses(G, FN, x - 1.1, x + 1.1, 2.5, 10.0, 1.5, 2.2, -0.15, 0.6)
		lb(G, "CapitalOrange", FN, x - 1.35, x + 1.35, 10.0, 10.7, -1.0, 0.3, COL.orange, { mat = MAT.Plastic, shadow = false })
		lb(G, "CapitalGold", FN, x - 1.5, x + 1.5, 10.7, 11.5, -1.15, 0.3, COL.gold, { mat = MAT.Plastic, shadow = false })
		courses(G, FN, x - 1.1, x + 1.1, 11.5, SLAB0, 1.4, 2.2, -0.15, 0.6)
		lb(G, "PilasterBand", FN, x - 1.4, x + 1.4, SLAB0, SLAB1 + 0.4, -2.3, 0.4, COL.blue, { mat = MAT.Plastic, studs = true, shadow = false })
		lb(G, "PilasterTop", FN, x - 1.2, x + 1.2, SLAB1 + 0.4, SLAB1 + 1.0, -2.1, -0.1, COL.gold, { mat = MAT.Plastic, shadow = false })
		ball(G, "PilasterBall", w(Vector3.new(x, SLAB1 + 2.0, -1.1)), 2.0, 2.0, 2.0, COL.gold, { reflect = 0.1 })
		-- the wall torch between the pilaster and the banner
		torch(G, FN, sx * 11.0, 8.4)
		-- the orange banner on its rod
		hangBanner(G, FN, sx * 13.4, 12.9, -0.55, 7.0, IMG.orangeBanner)
		-- a gold scroll bracket under the balcony, between the arch and the pilaster
		local bx = sx * 5.6
		lb(G, "BracketTop", FN, bx - 0.45, bx + 0.45, SLAB0 - 0.45, SLAB0, -1.9, 0, COL.gold, { mat = MAT.Plastic, shadow = false })
		lb(G, "BracketSpine", FN, bx - 0.45, bx + 0.45, SLAB0 - 2.2, SLAB0 - 0.3, -0.7, 0, COL.gold, { mat = MAT.Plastic, shadow = false })
		rod(G, "BracketCurl", FN * CFrame.new(bx, SLAB0 - 0.75, -1.45), 0.9, 1.0, COL.gold, { mat = MAT.Plastic, shadow = false })
		rod(G, "BracketScroll", FN * CFrame.new(bx, SLAB0 - 2.3, -0.75), 0.9, 1.5, COL.gold, { mat = MAT.Plastic, shadow = false })
		ball(G, "BracketDrop", w(Vector3.new(bx, SLAB0 - 3.35, -0.75)), 0.8, 0.8, 0.8, COL.gold, { shadow = false })
		-- the outer buttress, under a planter
		local ox0, ox1 = math.min(sx * 15.2, sx * HALF), math.max(sx * 15.2, sx * HALF)
		lb(G, "Buttress", FN, ox0, ox1, 0, SLAB0 - 1.4, -1.0, 1.0, COL.stoneC)
		lb(G, "ButtressFoot", FN, ox0 - 0.15, ox1 + 0.15, 0, 1.3, -1.2, 1.0, COL.blue, { mat = MAT.Plastic, shadow = false })
		lb(G, "Ledge", FN, math.min(sx * 12.6, sx * (HALF + 0.3)), math.max(sx * 12.6, sx * (HALF + 0.3)), SLAB0 - 1.4, SLAB0 - 0.5, -1.3, 1.6, COL.gold, { mat = MAT.Plastic, shadow = false })
		lb(G, "LedgeBlue", FN, math.min(sx * 12.6, sx * (HALF + 0.3)), math.max(sx * 12.6, sx * (HALF + 0.3)), SLAB0 - 0.5, SLAB1, -1.2, 1.6, COL.blue, { mat = MAT.Plastic, studs = true, shadow = false })
		planter(FN * CFrame.new(sx * 14.4, SLAB1, 0.5))
	end
	-- the balcony slab: a cream core, a blue band between gold trims, standing out over the gate
	lb(G, "Slab", FN, -12.4, 12.4, SLAB0, SLAB1, -2.0, 0.5, COL.stoneC, { studs = true })
	lb(G, "SlabBand", FN, -12.6, 12.6, SLAB0 + 0.3, SLAB1 - 0.3, -2.25, -1.9, COL.blue, { mat = MAT.Plastic, shadow = false })
	lb(G, "SlabTrimTop", FN, -12.7, 12.7, SLAB1 - 0.3, SLAB1, -2.35, -1.85, COL.gold, { mat = MAT.Plastic, shadow = false })
	lb(G, "SlabTrimLow", FN, -12.7, 12.7, SLAB0, SLAB0 + 0.3, -2.35, -1.85, COL.gold, { mat = MAT.Plastic, shadow = false })
	-- the podium's top beside the box: a blue studded floor
	for _, sx in { -1, 1 } do
		lb(G, "PodiumTop", FN, math.min(sx * 10.4, sx * HALF), math.max(sx * 10.4, sx * HALF), SLAB1 - 0.2, SLAB1 + 0.05, 1.6, DEEP, COL.floorBlue, { mat = MAT.Plastic, studs = true, shadow = false })
	end
	-- wings: the stone wall that joins the box to the towers beside it
	for _, sx in { -1, 1 } do
		local x0, x1 = math.min(sx * 10.4, sx * 21), math.max(sx * 10.4, sx * 21)
		lb(G, "Wing", FN, x0, x1, SLAB1, 22.0, DEEP - 1, DEEP + 10, COL.cream)
		lb(G, "WingBand", FN, x0, x1, 20.2, 20.9, DEEP - 1.3, DEEP + 10, COL.blue, { mat = MAT.Plastic, shadow = false })
		lb(G, "WingCap", FN, x0, x1, 22.0, 22.6, DEEP - 1.4, DEEP + 10, COL.stoneC, { studs = true, shadow = false })
		lattice(G, FN, x0, x1, 20.9, 22.0, DEEP - 1.15, 2.6, COL.blue, 0.3)
	end
end
yieldNow()

do
	local B = boxF
	local FL = 15.5 -- the box floor
	local X = 10.4 -- the box's inner half width
	local ZB = 12.0 -- its back wall
	local ARCH0 = 23.7 -- the entablature's foot
	lb(B, "Floor", FN, -X, X, FL, FL + 0.3, -1.9, ZB, COL.floorBlue, { mat = MAT.Plastic, studs = true, shadow = false })
	-- the back wall and the sides
	lb(B, "BackWall", FN, -X, X, FL, ARCH0, ZB, ZB + 1.0, COL.brick)
	for _, sx in { -1, 1 } do
		local x0, x1 = math.min(sx * X, sx * (X + 2.0)), math.max(sx * X, sx * (X + 2.0))
		lb(B, "Side", FN, x0, x1, FL, ARCH0, 1.5, ZB + 1.0, COL.mortar)
		lb(B, "SideBand", FN, x0 - 0.1, x1 + 0.1, 20.6, 21.4, 1.4, ZB + 1.1, COL.blue, { mat = MAT.Plastic, shadow = false })
		courses(B, FN, x0, x1, FL + 0.3, 20.6, 1.3, 2.0, 1.5, 0.15)
		courses(B, FN, x0, x1, 21.4, ARCH0, 1.15, 2.0, 1.5, 0.15)
	end
	-- the columns: a square plinth, a gold base, a cream shaft, a gold capital, a gold abacus
	for _, sx in { -1, 1 } do
		local cx = sx * 9.6
		local p = Vector3.new(cx, 0, 0.7)
		lb(B, "ColumnPlinth", FN, cx - 1.4, cx + 1.4, FL + 0.3, FL + 1.6, -0.7, 2.1, COL.stoneC)
		cyl(B, "ColumnBase", w(p + Vector3.new(0, FL + 1.9, 0)), 2.5, 0.6, COL.gold, { mat = MAT.Plastic })
		cyl(B, "Column", w(p + Vector3.new(0, FL + 4.95, 0)), 1.9, 5.5, COL.cream)
		cyl(B, "ColumnCapital", w(p + Vector3.new(0, ARCH0 - 1.05, 0)), 2.5, 0.7, COL.gold, { mat = MAT.Plastic })
		lb(B, "ColumnAbacus", FN, cx - 1.45, cx + 1.45, ARCH0 - 0.7, ARCH0, -0.75, 2.15, COL.gold, { mat = MAT.Plastic })
	end
	-- the balustrade: four posts with gold balls, rails, cream X lattice (the red back shows through)
	local BZ = -1.35
	-- (the gate's pilaster balls at x 8.5 are its end posts, as in the gate close-up)
	for _, px in { -2.5, 2.5 } do
		lb(B, "BalPost", FN, px - 0.6, px + 0.6, FL + 0.3, FL + 2.9, BZ - 0.6, BZ + 0.6, COL.stoneC)
		lb(B, "BalPostCap", FN, px - 0.75, px + 0.75, FL + 2.9, FL + 3.2, BZ - 0.75, BZ + 0.75, COL.gold, { mat = MAT.Plastic, shadow = false })
		ball(B, "BalPostBall", w(Vector3.new(px, FL + 3.65, BZ)), 0.95, 0.95, 0.95, COL.gold, { reflect = 0.1, shadow = false })
	end
	lb(B, "BalRailTop", FN, -7.6, 7.6, FL + 2.3, FL + 2.7, BZ - 0.3, BZ + 0.3, COL.stoneC, { shadow = false })
	lb(B, "BalRailLow", FN, -7.6, 7.6, FL + 0.3, FL + 0.7, BZ - 0.3, BZ + 0.3, COL.stoneC, { shadow = false })
	for _, span in { { -7.5, -3.1 }, { -1.9, 1.9 }, { 3.1, 7.5 } } do
		lattice(B, FN, span[1], span[2], FL + 0.7, FL + 2.3, BZ, 1.9, COL.white, 0.28)
	end
	-- the curtains: red side drapes with gold tie-backs, an orange valance with three swags and gold tassels
	for _, sx in { -1, 1 } do
		local a0, a1 = math.min(sx * 7.2, sx * 8.9), math.max(sx * 7.2, sx * 8.9)
		lb(B, "Curtain", FN, a0, a1, FL + 3.2, ARCH0 - 0.6, 1.6, 2.2, COL.red, { shadow = false })
		local b0, b1 = math.min(sx * 7.9, sx * 8.9), math.max(sx * 7.9, sx * 8.9)
		lb(B, "CurtainFall", FN, b0, b1, FL + 0.3, FL + 3.4, 1.6, 2.2, COL.red, { shadow = false })
		lb(B, "TieBack", FN, a0 - 0.1, a1 + 0.1, FL + 3.0, FL + 3.5, 1.5, 2.3, COL.gold, { mat = MAT.Plastic, shadow = false })
	end
	lb(B, "Valance", FN, -9.0, 9.0, ARCH0 - 0.7, ARCH0, 1.0, 1.5, COL.curtain, { shadow = false })
	-- (a Ball part is always a sphere: a swag is a disc standing behind the valance, only its lower curve showing)
	for _, sx in { -6.0, 0, 6.0 } do
		rod(B, "Swag", FN * CFrame.new(sx, ARCH0 + 0.6, 1.75) * CFrame.Angles(0, PI / 2, 0), 0.5, 6.0, COL.curtain, { shadow = false })
	end
	for _, tx in { -9.0, -3.0, 3.0, 9.0 } do
		cyl(B, "TasselCord", w(Vector3.new(tx, ARCH0 - 1.1, 1.0)), 0.35, 0.9, COL.gold, { shadow = false })
		ball(B, "Tassel", w(Vector3.new(tx, ARCH0 - 1.75, 1.0)), 0.65, 0.65, 0.65, COL.gold, { shadow = false })
	end
	-- two orange banners on the back wall, the trophy on its plinth in the middle
	local BF = FN * CFrame.new(0, 0, ZB)
	for _, sx in { -1, 1 } do
		hangBanner(B, BF, sx * 4.6, ARCH0 - 1.4, -0.1, 5.2, IMG.orangeBanner)
	end
	local tz = ZB - 4.0
	lb(B, "TrophyPlinth", FN, -1.6, 1.6, FL + 0.3, FL + 1.8, tz - 1.6, tz + 1.6, COL.stoneC)
	lb(B, "TrophyPlinthTop", FN, -1.9, 1.9, FL + 1.8, FL + 2.2, tz - 1.9, tz + 1.9, COL.gold, { mat = MAT.Plastic })
	local tp = Vector3.new(0, 0, tz)
	-- the cup: a foot, a stem with a knot, a bowl (a ball under a short cylinder), a rim, two ring handles (discs)
	cyl(B, "TrophyFoot", w(tp + Vector3.new(0, FL + 2.4, 0)), 1.9, 0.4, COL.gold, { reflect = 0.05 })
	cyl(B, "TrophyStem", w(tp + Vector3.new(0, FL + 3.1, 0)), 0.55, 1.1, COL.gold, { reflect = 0.05 })
	ball(B, "TrophyKnot", w(tp + Vector3.new(0, FL + 3.1, 0)), 0.9, 0.9, 0.9, COL.gold, { reflect = 0.05 })
	ball(B, "TrophyBowl", w(tp + Vector3.new(0, FL + 4.5, 0)), 2.7, 2.7, 2.7, COL.gold, { reflect = 0.05 })
	cyl(B, "TrophyBody", w(tp + Vector3.new(0, FL + 5.15, 0)), 2.7, 1.3, COL.gold, { reflect = 0.05 })
	cyl(B, "TrophyRim", w(tp + Vector3.new(0, FL + 5.9, 0)), 3.1, 0.3, COL.gold, { reflect = 0.05 })
	for _, sx in { -1, 1 } do
		rod(B, "TrophyHandle", FN * CFrame.new(sx * 1.55, FL + 5.0, tz) * CFrame.Angles(0, PI / 2, 0), 0.35, 1.5, COL.gold, { reflect = 0.05, shadow = false })
	end
	-- lanterns hang inside the columns
	for _, sx in { -1, 1 } do
		lantern(B, w(Vector3.new(sx * 7.6, ARCH0 - 0.3, -0.3)), 0.95)
	end
	-- the entablature: a cream architrave with a blue frieze band, a gold cornice
	lb(B, "Architrave", FN, -12.4, 12.4, ARCH0, ARCH0 + 1.3, -0.8, ZB + 1.0, COL.stoneC)
	lb(B, "Frieze", FN, -12.5, 12.5, ARCH0 + 0.3, ARCH0 + 1.0, -1.0, -0.7, COL.blue, { mat = MAT.Plastic, shadow = false })
	lb(B, "Cornice", FN, -13.0, 13.0, ARCH0 + 1.3, ARCH0 + 2.0, -1.2, ZB + 1.2, COL.gold, { mat = MAT.Plastic })
	-- the pediment: two wedges of brick red, gold rakes, gold-balled corner blocks, the medallion, the crown
	local base = ARCH0 + 2.0
	local half, ph = 12.0, 5.4
	for _, sx in { -1, 1 } do
		-- (a WedgePart's slope rises toward its +Z face: turn it so +Z points at the middle)
		wedge(B, "Pediment", Vector3.new(1.6, ph, half), FN * CFrame.new(sx * half / 2, base + ph / 2, 0.0) * CFrame.Angles(0, if sx < 0 then PI / 2 else -PI / 2, 0), COL.brick)
		local len = math.sqrt(half * half + ph * ph) + 0.6
		local ang = math.atan2(ph, half)
		local nx, ny = sx * math.sin(ang) * 0.45, math.cos(ang) * 0.45
		mk(B, "Rake", Vector3.new(len, 0.9, 2.2), FN * CFrame.new(sx * half / 2 + nx, base + ph / 2 + ny, 0.0) * CFrame.Angles(0, 0, -sx * ang), COL.gold, { mat = MAT.Plastic })
		lb(B, "Acroterion", FN, sx * 12.6 - 1.0, sx * 12.6 + 1.0, base, base + 1.2, -1.0, 1.0, COL.orange, { mat = MAT.Plastic, shadow = false })
		ball(B, "AcroterionBall", w(Vector3.new(sx * 12.6, base + 2.0, 0)), 1.6, 1.6, 1.6, COL.gold, { reflect = 0.1 })
	end
	sign(B, "Emblem", FN * CFrame.new(0, base + 2.3, -0.9), 4.6, IMG.emblem)
	-- the crown: a band, three points (squares turned on their corner, half sunk), ball tips and a red gem
	local cy = base + ph - 0.2
	lb(B, "CrownBand", FN, -1.7, 1.7, cy, cy + 1.0, -0.6, 0.6, COL.gold, { mat = MAT.Plastic })
	for _, p in { { -1.25, 1.2 }, { 0, 1.55 }, { 1.25, 1.2 } } do
		mk(B, "CrownPoint", Vector3.new(p[2], p[2], 1.0), FN * CFrame.new(p[1], cy + 1.0, 0) * CFrame.Angles(0, 0, PI / 4), COL.gold, { mat = MAT.Plastic, shadow = false })
		ball(B, "CrownTip", w(Vector3.new(p[1], cy + 1.0 + p[2] * 0.707 + 0.15, 0)), 0.55, 0.55, 0.55, COL.gold, { reflect = 0.1, shadow = false })
	end
	ball(B, "CrownGem", w(Vector3.new(0, cy + 0.5, -0.6)), 0.7, 0.7, 0.4, COL.red, { reflect = 0.1, shadow = false })
end
yieldNow()

-- ===== bunting: from tower to tower, and from the towers by the box to its corner balls =====
local PENNANT = { COL.blue, COL.gold, COL.orange, COL.gold }
local function bunting(p0: any, p1: any, sag: number)
	local n = math.max(4, math.floor((p1 - p0).Magnitude / 4.2))
	local prev = p0
	for i = 1, n do
		local t = i / n
		local pt = p0:Lerp(p1, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		local mid = (prev + pt) / 2
		local len = (pt - prev).Magnitude
		local seg = CFrame.new(mid, pt)
		mk(flagsF, "String", Vector3.new(0.14, 0.14, len), seg, rgb(250, 244, 230), { shadow = false })
		local flip = if i % 2 == 0 then CFrame.Angles(0, PI, 0) else CFrame.new()
		local cf = seg * flip * CFrame.Angles(0, 0, PI) + Vector3.new(0, -0.9, 0)
		local wp = wedge(flagsF, "Pennant", Vector3.new(0.12, 1.8, math.min(len * 0.8, 2.6)), cf, PENNANT[(i % #PENNANT) + 1])
		wp.CastShadow = false
		prev = pt
	end
end
local function topOf(b: number): any
	return polar(ARC_IN + 0.9, b, TOWER_TOP - 0.7)
end
for _, span in { { 40, 80 }, { 80, 120 }, { 120, 160 }, { 200, 240 }, { 240, 280 }, { 280, 320 } } do
	bunting(topOf(span[1]), topOf(span[2]), 2.6)
end
bunting(topOf(160), w(Vector3.new(-12.6, 25.7 + 1.2, 0)), 2.2)
bunting(topOf(200), w(Vector3.new(12.6, 25.7 + 1.2, 0)), 2.2)
yieldNow()

-- ===== planters at the bay ends: beside the aisles and where the stands meet the royal box =====
local PLANTERS = {}
local function rowR(t: number): number
	return TIERS[t].rIn + 3.5
end
local function aisleOffset(t: number): number
	return math.deg((AISLE_HALF + 1.9) / rowR(t))
end
for _, p in { { 65, 1, 1 }, { 65, 3, -1 }, { 115, 1, -1 }, { 115, 3, 1 } } do
	local off = aisleOffset(p[2]) * p[3]
	table.insert(PLANTERS, { a = p[1] + off, t = p[2] })
	table.insert(PLANTERS, { a = 360 - (p[1] + off), t = p[2] })
end
for t = 1, 3 do
	table.insert(PLANTERS, { a = 155.5, t = t })
	table.insert(PLANTERS, { a = 204.5, t = t })
end
for _, p in PLANTERS do
	planter(ringCF(rowR(p.t), p.a, TIERS[p.t].floor))
end

-- ===== the crowd: SPOTS only, one invisible part a seat, filled on each client with the game's own slimes =====
-- (client/ArenaStage.prepare clones SlimeLook models onto them; nothing of a slime is built here.) A Spot's CFrame is the slime's
-- feet on the tier floor, its look vector towards the pit. One row a tier, seats SEAT_SPACING apart on the arc: a slime is
-- about 3.5 studs wide at Config.Arena.Stage.CrowdScale, so this is one body and a hand's gap. Seats within SEAT_CULL degrees
-- of the blue gate are left out (behind and beside the View seat, never in frame), and none stand in an aisle, on a planter or
-- in front of a riser banner.
local SEAT_SPACING = 4.0
local SEAT_CULL = 30
local FLAG_SHARE = 0.09 -- a seat in this share has a little blue or orange flag on a pole beside it
local FLAGS = { COL.blue, COL.orange }
local flagF = folder(model, "CrowdFlags")
local seatCount = 0
local function blocked(a: number, rr: number, t: number): boolean
	for _, x in AISLES do
		if math.abs(a - x) < math.deg((AISLE_HALF + 1.85) / rr) then
			return true
		end
	end
	for _, p in PLANTERS do
		if p.t == t and math.abs(a - p.a) < math.deg(3.7 / rr) then
			return true
		end
	end
	for _, b in TIER_BANNERS do
		if b.t == t + 1 and math.abs(a - b.a) < math.deg(2.2 / rr) then
			return true
		end
	end
	return false
end
local function seat(tier: any, rr: number, aDeg: number, t: number)
	-- (ringCF's look vector points at the middle; Lune's CFrame.lookAt turned the seats every which way)
	local cf = ringCF(rr, aDeg, tier.floor)
	local spot = mk(crowd, "Spot", Vector3.new(0.4, 0.4, 0.4), cf, COL.white, { trans = 1, shadow = false })
	spot:SetAttribute("Tier", t)
	seatCount += 1
	if rnd() < FLAG_SHARE then
		-- (on the slime's right, in the gap to its neighbour; the flag floats over the neighbour's head)
		local flag = if aDeg > 90 and aDeg < 270 then FLAGS[2] else FLAGS[1]
		cyl(flagF, "Pole", (cf * CFrame.new(2.0, 2.6, 0)).Position, 0.16, 5.2, COL.cream, { shadow = false })
		mk(flagF, "Flag", Vector3.new(1.6, 1.0, 0.08), cf * CFrame.new(2.8, 4.5, 0), flag, { shadow = false })
	end
end
local function seatArc(tier: any, rr: number, a0: number, a1: number, t: number)
	local a = a0
	while a <= a1 do
		if not blocked(a, rr, t) then
			seat(tier, rr, a, t)
		end
		a += math.deg(SEAT_SPACING / rr)
	end
end
for t, tier in TIERS do
	local rr = rowR(t)
	local edge = 160 - math.deg(2.0 / rr)
	seatArc(tier, rr, SEAT_CULL, edge, t)
	seatArc(tier, rr, 360 - edge, 360 - SEAT_CULL, t)
	yieldNow()
end

-- ===== the land beyond the arches: a green plain and soft hills (the game's own sky above) =====
do
	mk(landF, "Ground", Vector3.new(2, 3600, 3600), CFrame.new(0, -46, 0) * CFrame.Angles(0, 0, PI / 2), COL.grass, { shape = Enum.PartType.Cylinder, shadow = false })
	local greens = { rgb(142, 184, 116), rgb(152, 190, 124), rgb(128, 172, 108) }
	for k = 0, 17 do
		local a = k * 20 + rnd() * 12
		local r = 560 + rnd() * 500
		local wd = 260 + rnd() * 240
		ball(landF, "Hill", Vector3.new(r * math.sin(math.rad(a)), -46, r * math.cos(math.rad(a))), wd, 70 + rnd() * 40, wd * (0.8 + rnd() * 0.4), greens[1 + k % 3], { shadow = false })
	end
end

-- ===== finish =====
model.WorldPivot = CFrame.new(0, 0, 0)
local instances = 0
for _ in model:GetDescendants() do
	instances += 1
end
local report = string.format("parts %d, instances %d, seats %d", partCount, instances, seatCount)
if LUNE then
	local fs = require("@lune/fs")
	fs.writeFile(OUT, roblox.serializeModel({ model }))
	print("wrote " .. OUT .. ": " .. report)
else
	local rs = game:GetService("ReplicatedStorage")
	local old = rs:FindFirstChild("ArenaStage")
	if old then
		old:Destroy()
	end
	model.Parent = rs
	local oldPreview = workspace:FindFirstChild("ArenaStagePreview")
	if oldPreview then
		oldPreview:Destroy()
	end
	local preview = model:Clone()
	preview.Name = "ArenaStagePreview"
	preview.Parent = workspace
	preview:PivotTo(CFrame.new(ORIGIN))
	return "built: " .. report
end
