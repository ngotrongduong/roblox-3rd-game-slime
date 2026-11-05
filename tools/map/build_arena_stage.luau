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
-- Look: the concept art/concept/arena-stage-view.webp (the view) and arena-stage-plan.webp (the plan). Classic stud look on
-- floors (Studs top surface), flat colours, shared parts, no text anywhere. Everything is Parts and a few Decals (pictures
-- uploaded from art/icons/arena_decal_*.png, arena_shield_*.png and arena_emblem.png), so a Lune run needs nothing from Studio.

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
	cream = rgb(244, 224, 178),
	creamShade = rgb(226, 202, 152),
	blue = rgb(40, 100, 232),
	blueDeep = rgb(26, 62, 170),
	floorBlue = rgb(112, 130, 226),
	gold = rgb(255, 196, 40),
	sand = rgb(232, 190, 120),
	orange = rgb(255, 128, 30),
	red = rgb(172, 48, 38),
	brick = rgb(150, 62, 48),
	curtain = rgb(214, 74, 36),
	wood = rgb(142, 92, 58),
	leaf = rgb(70, 170, 70),
	white = rgb(250, 250, 250),
	grass = rgb(92, 154, 68),
}

-- ===== a seeded random (so a re-run gives the same crowd) =====
local seed = 20261105
local function rnd(): number
	seed = (seed * 16807) % 2147483647
	return seed / 2147483647
end

-- ===== helpers =====
local PI = math.pi
local STEP = 10 -- degrees one ring piece spans
local WEDGE = 20 -- degrees either side of the blue gate and the orange gate left free for them
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

local function folder(parent: any, name: string): any
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- one block in the frame of a sector piece: lx across (tangent), y up, lz out (radial)
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

-- an upright cylinder (Roblox cylinders lie along X)
local function cyl(parent: any, name: string, pos: any, diameter: number, height: number, colour: any, o: any?): any
	local opt = o or {}
	opt.shape = Enum.PartType.Cylinder
	return mk(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, PI / 2), colour, opt)
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
-- a picture standing on a wall, facing +Z (a gate's front) or along the part's own -Z (use `facing` = the CFrame)
local function sign(parent: any, name: string, cf: any, size: number, image: string): any
	local p = mk(parent, name, Vector3.new(size, size, 0.1), cf, COL.white, { trans = 1, shadow = false })
	local d = Instance.new("Decal")
	d.Texture = image
	d.Face = Enum.NormalId.Front
	d.Parent = p
	return p
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
		-- 0.35 read as grey smoke)
		e.LightEmission = 0.55
		e.LightInfluence = 0
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, size),
			NumberSequenceKeypoint.new(0.4, size * 1.1),
			NumberSequenceKeypoint.new(1, size * 0.15),
		})
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, 0.1),
			NumberSequenceKeypoint.new(0.75, 0.35),
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
	layer(rgb(255, 95, 15), rgb(190, 30, 5), 3.2 * scale, 0.9, 9, 3.4 * scale)
	layer(rgb(255, 185, 40), rgb(255, 80, 10), 1.7 * scale, 0.6, 7, 2.6 * scale)
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 160, 80)
	l.Brightness = 0.8
	l.Range = 12
	l.Shadows = false
	l.Parent = holder
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
local southF = folder(model, "BlueGate")
local deckF = folder(model, "Seat")
local northF = folder(model, "OrangeGate")
local boxF = folder(model, "RoyalBox")
local rimF = folder(model, "Rim")
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
		local fromBlue = math.abs(((a + 180) % 360) - 180)
		if fromBlue >= WEDGE and (180 - fromBlue) >= WEDGE then
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

-- ===== the low wall round the sand, with gold finials =====
local W0_IN, W0_OUT, W0_TOP = 35, 37.2, 4.8
for _, a in SECTORS do
	ring(wallF, "Wall", a, W0_IN, W0_OUT, 0, W0_TOP - 0.4, COL.cream)
	ring(wallF, "WallCap", a, W0_IN - 0.15, W0_OUT + 0.1, W0_TOP - 0.4, W0_TOP, COL.blue, { mat = MAT.Plastic, studs = true })
end
local function finial(parent: any, aDeg: number, rr: number, y: number, size: number)
	local pos = polar(rr, aDeg, 0)
	local cf = ringCF(rr, aDeg, 0)
	mk(parent, "Post", Vector3.new(size, y + 0.0, size), cf * CFrame.new(0, y / 2, 0), COL.cream)
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

-- ===== the stands: three tiers, each a cream riser, a studded blue floor and a blue band =====
local TIERS = {
	{ rIn = 37.2, rOut = 44, floor = 3.4 },
	{ rIn = 44, rOut = 51, floor = 6.8 },
	{ rIn = 51, rOut = 58, floor = 10.2 },
}
for t, tier in TIERS do
	for _, a in SECTORS do
		ring(standsF, "Riser", a, tier.rIn, tier.rOut, 0, tier.floor - 0.7, COL.cream)
		ring(standsF, "Floor", a, tier.rIn - 0.2, tier.rOut, tier.floor - 0.7, tier.floor, COL.floorBlue, { mat = MAT.Plastic, studs = true })
		if t > 1 then
			ring(standsF, "Band", a, tier.rIn - 0.25, tier.rIn, tier.floor - 2.3, tier.floor - 1.3, COL.blue, { shadow = false })
		end
	end
	yieldNow()
end

-- ===== the upper arcade: a cream wall with arched openings, a blue band and a studded roof =====
local ARC_IN, ARC_OUT, ARC_RM = 58, 61, 59.5
local SILL, OPEN_BOT, OPEN_TOP, WALL_TOP = 10.2, 12.0, 19.5, 24.0
for _, a in SECTORS do
	local cfA = ringCF(ARC_RM, a, 0)
	local chord = chordAt(ARC_OUT)
	local ow = 6.2
	local pier = (chord - ow) / 2
	local function blk(name: string, lx: number, y0: number, y1: number, w: number, colour: any, depth: number?, o: any?)
		mk(arcadeF, name, Vector3.new(w, y1 - y0, depth or 3), cfA * CFrame.new(lx, (y0 + y1) / 2, 0), colour, o)
	end
	blk("Sill", 0, SILL, OPEN_BOT, chord + 0.02, COL.cream)
	blk("PierL", -(ow / 2 + pier / 2), OPEN_BOT, OPEN_TOP, pier + 0.02, COL.cream)
	blk("PierR", ow / 2 + pier / 2, OPEN_BOT, OPEN_TOP, pier + 0.02, COL.cream)
	blk("Lintel", 0, OPEN_TOP, WALL_TOP, chord + 0.02, COL.cream)
	for _, sx in { -1, 1 } do
		mk(arcadeF, "Chamfer", Vector3.new(2.4, 2.4, 3), cfA * CFrame.new(sx * ow / 2, OPEN_TOP, 0) * CFrame.Angles(0, 0, PI / 4), COL.cream, { shadow = false })
	end
	-- a blue-capped pilaster on the inner face at each side of the bay
	for _, sx in { -1, 1 } do
		local px = sx * (chord / 2 - 0.5)
		mk(arcadeF, "Pilaster", Vector3.new(1.0, OPEN_TOP - SILL, 0.5), cfA * CFrame.new(px, (SILL + OPEN_TOP) / 2, -1.7), COL.cream, { shadow = false })
		mk(arcadeF, "PilasterCap", Vector3.new(1.4, 0.7, 0.8), cfA * CFrame.new(px, OPEN_TOP + 0.35, -1.7), COL.blue, { shadow = false })
	end
	-- every other opening is closed at the back by a deep-blue panel, so the wall reads thick and not as holes in a flat sheet
	if (a // STEP) % 2 == 0 then
		mk(arcadeF, "ArchBack", Vector3.new(ow + 0.04, OPEN_TOP - OPEN_BOT + 1.2, 0.4), cfA * CFrame.new(0, (OPEN_BOT + OPEN_TOP) / 2 + 0.6, 1.3), COL.blueDeep, { shadow = false })
	end
	-- (the blue band sits on the inner face, a little proud)
	mk(arcadeF, "Band", Vector3.new(chord + 0.02, 1.2, 0.3), cfA * CFrame.new(0, 22.6, -1.6), COL.blue, { shadow = false })
	ring(arcadeF, "Roof", a, ARC_IN - 0.1, 66, WALL_TOP, WALL_TOP + 0.8, COL.floorBlue, { mat = MAT.Plastic, studs = true })
	ring(arcadeF, "Parapet", a, 64.8, 66, WALL_TOP + 0.8, WALL_TOP + 2.2, COL.cream)
	ring(arcadeF, "ParapetCap", a, 64.7, 66.1, WALL_TOP + 2.2, WALL_TOP + 2.6, COL.blue, { mat = MAT.Plastic, studs = true })
end
yieldNow()

-- ===== a gate: the blue one lets the player in, the orange one lets the rival in =====
-- zF is the world z of its front (the face that looks toward +Z), `depth` how far it runs back (toward -Z).
local function gate(parent: any, name: string, zF: number, depth: number, main: any, shieldImg: string, bannerImg: string, grid: boolean)
	local g = folder(parent, name)
	local halfW, openW, openH, body = 13.5, 5.0, 6.6, 9.0
	local zc = zF - depth / 2
	local function blk(n: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, colour: any, o: any?): any
		return mk(g, n, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour, o)
	end
	-- the body, left and right of the opening, and over it
	blk("BodyL", -halfW, -(openW + 1.4), 0, body, zF - depth, zF, COL.cream)
	blk("BodyR", openW + 1.4, halfW, 0, body, zF - depth, zF, COL.cream)
	blk("Over", -(openW + 1.4), openW + 1.4, openH + 1.4, body, zF - depth, zF, COL.cream)
	-- a gold frame round the opening, standing out of the front
	blk("FrameL", -(openW + 1.4), -openW, 0, openH + 1.4, zF - 0.2, zF + 0.7, COL.gold, { mat = MAT.Plastic })
	blk("FrameR", openW, openW + 1.4, 0, openH + 1.4, zF - 0.2, zF + 0.7, COL.gold, { mat = MAT.Plastic })
	blk("FrameTop", -(openW + 1.4), openW + 1.4, openH, openH + 1.4, zF - 0.2, zF + 0.7, COL.gold, { mat = MAT.Plastic })
	for _, sx in { -1, 1 } do
		mk(g, "FrameCorner", Vector3.new(2.6, 2.6, 0.9), CFrame.new(sx * (openW - 0.2), openH - 0.2, zF + 0.25) * CFrame.Angles(0, 0, PI / 4), COL.gold, { mat = MAT.Plastic, shadow = false })
	end
	-- a band in the gate's own colour over the frame
	blk("ArchBand", -(openW + 1.4), openW + 1.4, openH + 1.4, openH + 2.5, zF - 0.1, zF + 0.5, main, { mat = MAT.Plastic, studs = true })
	-- the tunnel's walls and its glowing floor, or the portcullis and its glow
	if grid then
		blk("Glow", -openW, openW, 0, openH, zF - depth + 1.2, zF - depth + 1.6, rgb(255, 130, 40), { mat = MAT.Neon, shadow = false })
		for i = -4, 4 do
			blk("Bar", i * 1.2 - 0.12, i * 1.2 + 0.12, 0, openH, zF - 0.5, zF - 0.2, COL.gold, { shadow = false })
		end
		for j = 1, 3 do
			blk("Rail", -openW, openW, j * openH / 4 - 0.12, j * openH / 4 + 0.12, zF - 0.55, zF - 0.15, COL.gold, { shadow = false })
		end
		glow(g, Vector3.new(0, 3.5, zF - 2), rgb(255, 140, 60), 1.4, 16)
	else
		blk("TunnelFloor", -openW, openW, 0, 0.35, zF - depth, zF, rgb(36, 96, 255), { mat = MAT.Neon, shadow = false })
		blk("TunnelWallL", -openW, -openW + 0.5, 0, openH, zF - depth, zF - 0.4, COL.blueDeep, { mat = MAT.Plastic, studs = false })
		blk("TunnelWallR", openW - 0.5, openW, 0, openH, zF - depth, zF - 0.4, COL.blueDeep, { mat = MAT.Plastic, studs = false })
		blk("TunnelRoof", -openW, openW, openH - 0.5, openH, zF - depth, zF - 0.4, COL.blueDeep, { mat = MAT.Plastic, studs = false })
		glow(g, Vector3.new(0, 3.3, zF - depth / 2), rgb(60, 120, 255), 1.6, 18)
	end
	-- roof steps in the gate's colour (stud blocks, a little pyramid)
	blk("Roof1", -halfW, halfW, body, body + 0.9, zF - depth, zF + 0.4, main, { mat = MAT.Plastic, studs = true })
	blk("Roof2", -(halfW - 3), halfW - 3, body + 0.9, body + 1.8, zF - depth + 2, zF - 1.6, main, { mat = MAT.Plastic, studs = true })
	-- pylons at each end with a cap and ball, and the banners between pylon and frame
	-- (the blue gate is under the View seat: only its pylon caps reach the frame's lower corners, where gold read as two
	-- bare yellow blocks, so there they are blue studs and have no ball)
	for _, sx in { -1, 1 } do
		local x0 = if sx < 0 then -halfW - 0.3 else halfW - 3
		blk("Pylon", x0, x0 + 3.3, 0, body + 1.6, zF - depth, zF + 0.4, COL.cream)
		blk("PylonBand", x0 - 0.2, x0 + 3.5, body - 0.4, body + 0.5, zF - depth - 0.2, zF + 0.6, main, { mat = MAT.Plastic })
		blk("PylonCap", x0 - 0.3, x0 + 3.6, body + 1.6, body + 2.3, zF - depth - 0.3, zF + 0.7, if grid then COL.gold else main, { mat = MAT.Plastic, studs = not grid })
		if grid then
			ball(g, "PylonBall", Vector3.new(x0 + 1.65, body + 3.2, zF - 0.3), 2.2, 2.2, 2.2, COL.gold, { reflect = 0.08 })
		end
		sign(bannerF, "GateBanner", CFrame.new(sx * 8.9, 4.6, zF + 0.2) * CFrame.Angles(0, PI, 0), 8.0, bannerImg)
	end
	-- the rival's gate gets a studded threshold running out onto the sand, where its team walks out
	if grid then
		blk("Threshold", -(openW + 1.4), openW + 1.4, 0, 0.35, zF, zF + 3.5, main, { mat = MAT.Plastic, studs = true, shadow = false })
		blk("ThresholdEdge", -(openW + 1.6), openW + 1.6, 0, 0.45, zF + 3.5, zF + 4.0, COL.gold, { mat = MAT.Plastic, shadow = false })
	end
	-- the shield with the crown stands on a pedestal over the frame
	blk("Pedestal", -2.6, 2.6, openH + 1.4, openH + 6.5, zF - 1.6, zF + 0.5, main, { mat = MAT.Plastic })
	sign(g, "Shield", CFrame.new(0, openH + 4.0, zF + 0.56) * CFrame.Angles(0, PI, 0), 5.0, shieldImg)
	return g
end

local BLUE_Z = 40
local ORANGE_Z = -33
gate(southF, "Gate", BLUE_Z, 9, COL.blue, IMG.blueShield, IMG.blueBanner, false)
gate(northF, "Gate", ORANGE_Z, 14, COL.orange, IMG.orangeShield, IMG.orangeBanner, true)
yieldNow()

-- ===== the seat deck behind the blue gate: the camera, the player's look-alike and the front row =====
do
	local function blk(n: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, colour: any, o: any?): any
		return mk(deckF, n, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour, o)
	end
	-- the plaza behind the gate: a blue studded floor the camera hangs over
	blk("Plaza", -34, 34, -0.6, 0, BLUE_Z - 3, 64, COL.floorBlue, { mat = MAT.Plastic, studs = true, shadow = false })
	-- a low cream rail with a blue cap at each side, and gold-capped posts at its ends
	for _, sx in { -1, 1 } do
		blk("Rail", sx * 33 - 0.5, sx * 33 + 0.5, 0, 1.4, BLUE_Z - 2, 64, COL.cream)
		blk("RailCap", sx * 33 - 0.6, sx * 33 + 0.6, 1.4, 1.8, BLUE_Z - 2, 64, COL.blue,{ mat = MAT.Plastic, studs = true })
		for _, z in { BLUE_Z - 1.5, 52 } do
			blk("Post", sx * 33 - 0.9, sx * 33 + 0.9, 0, 3.0, z - 0.9, z + 0.9, COL.cream)
			blk("PostCap", sx * 33 - 1.2, sx * 33 + 1.2, 3.0, 3.6, z - 1.2, z + 1.2, COL.gold, { mat = MAT.Plastic })
			ball(deckF, "Ball", Vector3.new(sx * 33, 4.7, z), 1.8, 1.8, 1.8, COL.gold, { reflect = 0.08 })
		end
	end
	-- the camera's seat (the player is not in the scene, only the camera: the owner, 2026-11-05)
	-- (the play test: from z 62 the blue gate's roof filled the lower half and the fighters were specks; from here, with
	-- Config.Arena.Stage.FieldOfView 50, the sand fills the frame under the royal box and the gate is below the frame)
	local view = mk(model, "View", Vector3.new(1, 1, 1), CFrame.new(0, 26.9, 50) * CFrame.Angles(-math.atan(18 / 58), 0, 0), COL.white, { trans = 1, shadow = false })
	view.Name = "View"
end

-- ===== the royal box above the orange gate =====
do
	local zF = ORANGE_Z
	local function blk(n: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, colour: any, o: any?): any
		return mk(boxF, n, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), colour, o)
	end
	local floorY = 17.8
	local DY = floorY - 14.0
	local zFront, zBack = zF - 3, zF - 14 -- the box's front edge and its back wall
	blk("Podium", -16.5, 16.5, 8.5, floorY - 0.6, zBack, zF - 1.5, COL.cream)
	blk("Floor", -15.5, 15.5, floorY - 0.6, floorY, zBack + 0.5, zFront + 0.2, COL.floorBlue, { mat = MAT.Plastic, studs = true })
	-- a blue band with gold trim across the podium's face (the bare cream wall under the balcony read as unfinished)
	blk("PodiumBand", -16.7, 16.7, 13.6, 15.0, zF - 1.7, zF - 1.1, COL.blue, { mat = MAT.Plastic, studs = true })
	blk("PodiumTrim", -16.8, 16.8, 15.0, 15.4, zF - 1.8, zF - 1.0, COL.gold, { mat = MAT.Plastic })
	blk("PodiumTrimLow", -16.8, 16.8, 13.2, 13.6, zF - 1.8, zF - 1.0, COL.gold, { mat = MAT.Plastic })
	-- back wall in brick red, with the curtains, and the trophy
	blk("BackWall", -15.5, 15.5, floorY, 27.4 + DY, zBack, zBack + 1.2, COL.brick)
	blk("SideL", -15.5, -14, floorY, 27.4 + DY, zBack, zFront, COL.cream)
	blk("SideR", 14, 15.5, floorY, 27.4 + DY, zBack, zFront, COL.cream)
	for _, sx in { -1, 1 } do
		for k = 0, 1 do
			local cx = sx * (6.2 + k * 3.1)
			blk("Curtain", cx - 1.3, cx + 1.3, floorY + 0.4, 25.6 + DY - k * 0.8, zBack + 1.2, zBack + 2.2, if k == 0 then COL.curtain else COL.red)
		end
		blk("Valance", sx * 8 - 5.2, sx * 8 + 5.2, 24.4 + DY, 26.2 + DY, zBack + 1.2, zBack + 2.6, COL.red)
		blk("ValanceTrim", sx * 8 - 5.2, sx * 8 + 5.2, 24.1 + DY, 24.4 + DY, zBack + 1.2, zBack + 2.8, COL.gold, { mat = MAT.Plastic })
		-- front columns with gold feet and capitals
		local cx = sx * 11.6
		local colz = zFront - 1.2
		cyl(boxF, "ColumnBase", Vector3.new(cx, floorY + 0.5, colz), 3.2, 1.0, COL.gold, { mat = MAT.Plastic })
		cyl(boxF, "Column", Vector3.new(cx, floorY + 7.2, colz), 2.4, 12.4, COL.cream)
		cyl(boxF, "ColumnCap", Vector3.new(cx, 26.9 + DY, colz), 3.4, 1.2, COL.gold, { mat = MAT.Plastic })
	end
	-- the trophy: a gold cup on a plinth
	local tz = zBack + 4.5
	blk("Plinth", -1.8, 1.8, floorY, floorY + 1.4, tz - 1.8, tz + 1.8, COL.cream)
	blk("PlinthTop", -2.1, 2.1, floorY + 1.4, floorY + 1.9, tz - 2.1, tz + 2.1, COL.gold, { mat = MAT.Plastic })
	cyl(boxF, "TrophyStem", Vector3.new(0, floorY + 2.7, tz), 0.9, 1.6, COL.gold, { reflect = 0.15 })
	cyl(boxF, "TrophyFoot", Vector3.new(0, floorY + 2.0, tz), 2.4, 0.3, COL.gold, { reflect = 0.15 })
	ball(boxF, "TrophyCup", Vector3.new(0, floorY + 4.3, tz), 3.4, 3.0, 3.4, COL.gold, { reflect = 0.15 })
	cyl(boxF, "TrophyRim", Vector3.new(0, floorY + 5.45, tz), 3.1, 0.35, COL.gold, { reflect = 0.15 })
	for _, sx in { -1, 1 } do
		ball(boxF, "TrophyHandle", Vector3.new(sx * 2.0, floorY + 4.5, tz), 1.1, 1.8, 0.5, COL.gold, { reflect = 0.15 })
	end
	-- the balustrade between the columns
	blk("RailBottom", -10.4, 10.4, floorY, floorY + 0.5, zFront - 0.2, zFront + 0.6, COL.cream)
	blk("RailTop", -10.4, 10.4, floorY + 2.3, floorY + 2.9, zFront - 0.3, zFront + 0.7, COL.cream)
	for i = -9, 9 do
		blk("Baluster", i * 1.1 - 0.15, i * 1.1 + 0.15, floorY + 0.5, floorY + 2.3, zFront, zFront + 0.4, COL.gold, { shadow = false })
	end
	-- the entablature, its gold trim and the pediment with the crowned slime
	blk("Entablature", -16.5, 16.5, 27.4 + DY, 29.8 + DY, zFront - 1.6, zFront + 1.2, COL.cream)
	blk("EntablatureTrim", -16.8, 16.8, 29.8 + DY, 30.4 + DY, zFront - 1.8, zFront + 1.4, COL.gold, { mat = MAT.Plastic })
	blk("EntablatureBand", -16.6, 16.6, 26.9 + DY, 27.4 + DY, zFront - 1.7, zFront + 1.3, COL.orange, { mat = MAT.Plastic })
	local ph = 7.6
	local base = 30.4 + DY
	for _, sx in { -1, 1 } do
		-- a triangle (two wedges' worth): a wedge turned so its slope rises toward the middle
		local w = Instance.new("WedgePart")
		w.Name = "PedimentHalf"
		w.Size = Vector3.new(2.2, ph, 16.4)
		-- (the wedge's tall face is on its +Z side: turn it to face the middle, lay its thin side along Z)
		w.CFrame = CFrame.new(sx * 8.2, base + ph / 2, zFront - 0.2) * CFrame.Angles(0, if sx < 0 then PI / 2 else -PI / 2, 0)
		w.Anchored = true
		w.CanCollide = false
		w.CanTouch = false
		w.CanQuery = false
		w.Color = COL.brick
		w.Material = MAT.SmoothPlastic
		w.TopSurface = SM
		w.BottomSurface = SM
		w.Parent = boxF
		partCount += 1
		local slopeLen = math.sqrt(16.4 ^ 2 + ph ^ 2)
		local ang = math.atan2(ph, 16.4)
		mk(boxF, "Rake", Vector3.new(slopeLen, 0.9, 2.6), CFrame.new(sx * 8.2, base + ph / 2 + 0.35, zFront - 0.2) * CFrame.Angles(0, 0, -sx * ang), COL.gold, { mat = MAT.Plastic })
		ball(boxF, "PedimentBall", Vector3.new(sx * 16.4, base + 1.5, zFront - 0.2), 2.2, 2.2, 2.2, COL.gold, { reflect = 0.08 })
	end
	sign(boxF, "Emblem", CFrame.new(0, base + 3.7, zFront + 1.2) * CFrame.Angles(0, PI, 0), 8.6, IMG.emblem)
end
yieldNow()

-- ===== braziers on pillars round the rim, and the bunting between them =====
local ROOF_Y = WALL_TOP + 0.8
local BRAZ_R = 62.4
local BRAZIERS = { 20, 60, 90, 130, 160, 200, 230, 270, 300, 340 }
for _, a in BRAZIERS do
	local cf = ringCF(BRAZ_R, a, 0)
	local pos = polar(BRAZ_R, a, 0)
	mk(rimF, "Plinth", Vector3.new(3.8, 1.6, 3.8), cf * CFrame.new(0, ROOF_Y + 0.8, 0), COL.cream)
	mk(rimF, "Pillar", Vector3.new(3.0, 4.2, 3.0), cf * CFrame.new(0, ROOF_Y + 3.7, 0), COL.cream)
	mk(rimF, "PillarBand", Vector3.new(3.5, 0.8, 3.5), cf * CFrame.new(0, ROOF_Y + 6.2, 0), COL.blue, { mat = MAT.Plastic, studs = true })
	cyl(rimF, "Bowl", pos + Vector3.new(0, ROOF_Y + 7.2, 0), 4.4, 1.2, COL.gold, { mat = MAT.SmoothPlastic, reflect = 0.1 })
	cyl(rimF, "BowlRim", pos + Vector3.new(0, ROOF_Y + 7.9, 0), 4.9, 0.4, COL.gold, { reflect = 0.1 })
	cyl(rimF, "Embers", pos + Vector3.new(0, ROOF_Y + 8.2, 0), 3.6, 0.2, rgb(255, 120, 30), { mat = MAT.Neon, shadow = false })
	flame(rimF, pos + Vector3.new(0, ROOF_Y + 8.9, 0), 1.3)
end

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
		mk(flagsF, "String", Vector3.new(0.14, 0.14, len), seg, rgb(96, 70, 56), { shadow = false })
		local flip = if i % 2 == 0 then CFrame.Angles(0, PI, 0) else CFrame.new()
		local cf = seg * flip * CFrame.Angles(0, 0, PI) + Vector3.new(0, -0.9, 0)
		local w = Instance.new("WedgePart")
		w.Name = "Pennant"
		w.Size = Vector3.new(0.12, 1.8, math.min(len * 0.8, 2.6))
		w.CFrame = cf
		w.Anchored = true
		w.CanCollide = false
		w.CanTouch = false
		w.CanQuery = false
		w.CastShadow = false
		w.Material = MAT.SmoothPlastic
		w.TopSurface = SM
		w.BottomSurface = SM
		w.Color = PENNANT[(i % #PENNANT) + 1]
		w.Parent = flagsF
		partCount += 1
		prev = pt
	end
end
local function topOf(a: number): any
	return polar(BRAZ_R, a, ROOF_Y + 6.4)
end
for _, span in { { 20, 60 }, { 60, 90 }, { 90, 130 }, { 130, 160 }, { 200, 230 }, { 230, 270 }, { 270, 300 }, { 300, 340 } } do
	bunting(topOf(span[1]), topOf(span[2]), 2.6)
end
-- the two strings that reach from the rim to the royal box's gold balls
bunting(topOf(160), Vector3.new(16.4, 35.7, ORANGE_Z - 3.2), 2.4)
bunting(topOf(200), Vector3.new(-16.4, 35.7, ORANGE_Z - 3.2), 2.4)
yieldNow()

-- ===== banners: small ones on the sand wall, big ones on the arcade by the braziers =====
for k = 0, 6 do
	local a = 30 + 20 * k
	for _, aa in { a, 360 - a } do
		local img = if aa > 90 and aa < 270 then IMG.orangeBanner else IMG.blueBanner
		if aa == 90 or aa == 270 then
			img = IMG.blueBanner
		end
		sign(bannerF, "WallBanner", ringCF(34.7, aa, 2.35) * CFrame.new(0, 0, 0), 4.6, img)
	end
end
for _, p in { { 90, IMG.blueBanner }, { 270, IMG.blueBanner }, { 130, IMG.orangeBanner }, { 230, IMG.orangeBanner } } do
	sign(bannerF, "ArcadeBanner", ringCF(57.7, p[1], 19.2), 9.6, p[2])
end
yieldNow()

-- ===== flower planters at the ends of the tiers =====
local function planter(aDeg: number, rr: number, y: number)
	local cf = ringCF(rr, aDeg, y)
	mk(plantF, "Pot", Vector3.new(3.4, 1.5, 2.2), cf * CFrame.new(0, 0.75, 0), COL.wood, { shadow = false })
	mk(plantF, "PotRim", Vector3.new(3.7, 0.3, 2.5), cf * CFrame.new(0, 1.6, 0), COL.creamShade, { shadow = false })
	local bush = mk(plantF, "Bush", Vector3.new(3.4, 2.2, 2.2), cf * CFrame.new(0, 2.5, 0), COL.leaf, { shape = Enum.PartType.Ball, shadow = false })
	for _, f in { { -0.9, 0.4 }, { 0.8, 0.9 }, { 0.1, -0.2 }, { 1.2, 0.1 } } do
		mk(plantF, "Flower", Vector3.new(0.75, 0.75, 0.75), cf * CFrame.new(f[1], 3.2 + f[2] * 0.5, -0.9), COL.white, { shape = Enum.PartType.Ball, shadow = false })
	end
	return bush
end
local PLANTERS = {}
for t, tier in TIERS do
	local rr = tier.rIn + 5.4
	for _, a in { 27, 333, 153, 207 } do
		table.insert(PLANTERS, a)
		planter(a, rr, tier.floor)
	end
end

-- ===== the crowd: SPOTS only, one invisible part a seat, filled on each client with the game's own slimes =====
-- (client/ArenaStage.prepare clones SlimeLook models onto them; nothing of a slime is built here.) A Spot's CFrame is the slime's
-- feet on the tier floor, its look vector towards the pit. One row a tier, seats SEAT_SPACING apart on the arc: a slime is
-- about 3.5 studs wide at Config.Arena.Stage.CrowdScale, so this is one body and a hand's gap. Fewer, bigger slimes than the
-- 344 two-ball stand-ins before: from the View seat the far stands are ~100 studs off and a body must be readable on a phone.
-- Seats within SEAT_CULL degrees of the blue gate are left out: they are behind and beside the View seat, never in frame.
local SEAT_SPACING = 4.0
local SEAT_ROW = 3.5 -- studs in from the tier's inner edge: the middle of the 6.8 deep floor
local SEAT_CULL = 40
local FLAG_SHARE = 0.09 -- a seat in this share has a little blue or orange flag on a pole beside it
local FLAGS = { COL.blue, COL.orange }
local flagF = folder(model, "CrowdFlags")
local seatCount = 0
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
-- every BAY_SEATS-th seat is a cream post with a gold cap instead, so the rows read as bays of a stadium, not shelves
local BAY_SEATS = 10
local function bayPost(tier: any, rr: number, aDeg: number)
	local cf = ringCF(rr, aDeg, tier.floor)
	mk(standsF, "BayPost", Vector3.new(1.4, 2.6, 1.4), cf * CFrame.new(0, 1.3, 0), COL.cream)
	mk(standsF, "BayPostCap", Vector3.new(1.8, 0.5, 1.8), cf * CFrame.new(0, 2.85, 0), COL.gold, { mat = MAT.Plastic })
	ball(standsF, "BayPostBall", (cf * CFrame.new(0, 3.6, 0)).Position, 1.1, 1.1, 1.1, COL.gold, { reflect = 0.08 })
end
local function seatArc(tier: any, rr: number, a0: number, a1: number, t: number)
	local a = a0
	local n = 0
	while a <= a1 do
		local skip = false
		for _, pa in PLANTERS do
			if math.abs(a - pa) < 4 then
				skip = true
			end
		end
		if not skip then
			n += 1
			if n % BAY_SEATS == 0 then
				bayPost(tier, rr, a)
			else
				seat(tier, rr, a, t)
			end
		end
		a += math.deg(SEAT_SPACING / rr)
	end
end
for t, tier in TIERS do
	local rr = tier.rIn + SEAT_ROW
	seatArc(tier, rr, math.max(22.5, SEAT_CULL), 157.5, t)
	seatArc(tier, rr, 202.5, math.min(337.5, 360 - SEAT_CULL), t)
	yieldNow()
end
yieldNow()

-- ===== the land beyond the arches: a green plain and soft hills (the game's own sky above) =====
do
	local ground = mk(landF, "Ground", Vector3.new(2, 3600, 3600), CFrame.new(0, -46, 0) * CFrame.Angles(0, 0, PI / 2), COL.grass, { shape = Enum.PartType.Cylinder, shadow = false })
	local greens = { rgb(104, 164, 76), rgb(122, 174, 86), rgb(88, 148, 76) }
	for k = 0, 17 do
		local a = k * 20 + rnd() * 12
		local r = 560 + rnd() * 500
		local w = 260 + rnd() * 240
		ball(landF, "Hill", Vector3.new(r * math.sin(math.rad(a)), -46, r * math.cos(math.rad(a))), w, 70 + rnd() * 40, w * (0.8 + rnd() * 0.4), greens[1 + k % 3], { shadow = false })
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
