--!strict
-- The face of one slime, built of separate layers so each can move on its own: two eye plates (eye, brow, blush,
-- sweat, tears) and a mouth plate, each a transparent Part carrying a SurfaceGui, standing on the slime's skin. A
-- Decal or SurfaceGui put on the skinned MeshPart itself would not follow the bones (it is drawn on the part's flat
-- box), so every frame the plates are placed on the deformed skin from the same rig numbers as Bone.Transform
-- (SlimeShape), tilted to the surface and stretched with it. The emote above the head is a BillboardGui.
--
-- Blinks, eyes that look at things, lids, a talking / chewing / yawning / quivering mouth and a small swell on every
-- change of emotion live here; what each emotion shows is data in Expressions. Everything is driven from SlimeActor's
-- single loop (`update`); there is no connection, thread or tween in here. The art is FaceArt: the owner's own pixels
-- and the few pieces drawn in the same style.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Expressions = require(ReplicatedStorage.Shared.Expressions)
local FaceArt = require(ReplicatedStorage.Shared.FaceArt)
local SlimeShape = require(ReplicatedStorage.Shared.SlimeShape)

local C = Config.Slime
local TAU = math.pi * 2

local EYE_PLATE_W, EYE_PLATE_H = 0.4, 0.62
local MOUTH_PLATE_W, MOUTH_PLATE_H = 0.5, 0.34
local EMOTE_PIXELS = 56
local EMOTE_RIGHT, EMOTE_UP = 0.3, 0.3
-- The owner (2026-10-29): an emote icon is a short pop-up when the feeling starts, not a sign that stays. Three feelings
-- keep a living effect instead while they last: sleep and sleepy breathe out rising z's, loved sends up hearts that
-- fade, dizzy has stars circling the head. Each is drawn from the owner's own emote sprites.
local STREAM_MODE: { [string]: string } = { sleep = "zzz", sleepy = "zzz", loved = "hearts", dizzy = "orbit" }
local STREAM_SPRITE: { [string]: string } = { zzz = "icon_zzz", hearts = "icon_heart", orbit = "icon_star" }
local STREAM_BITS = 4
-- a stream's billboard is this many emote sizes wide and tall (room to rise or to circle)
local STREAM_W, STREAM_H = 2, 2.6

type Layer = {
	label: ImageLabel,
	x: number,
	y: number,
	w: number,
	h: number,
	rot: number,
	trans: number,
	shown: boolean,
	image: string,
}

type Plate = {
	part: Part,
	gui: SurfaceGui,
	content: Frame,
	u: number, -- where the plate stands on the face
	v: number,
	w: number, -- its size, body heights
	h: number,
	layers: { [string]: Layer },
	scaleU: number,
	scaleV: number,
}

export type Face = {
	folder: Folder,
	scale: number, -- studs per body height
	eyeL: Plate,
	eyeR: Plate,
	mouth: Plate,
	emote: Part,
	emoteGui: BillboardGui,
	emoteLabel: ImageLabel,
	emoteScale: UIScale,
	emoteBits: { ImageLabel },
	-- "pop" (a short pop-up) or a lasting effect: "zzz", "hearts", "orbit"
	emoteMode: string,
	expr: Expressions.Expression,
	t: number,
	popT: number,
	emoteT: number,
	blinkAt: number,
	blinkT: number, -- seconds into a blink, or -1
	blinkAgain: boolean,
	gx: number,
	gy: number,
	targetX: number?,
	targetY: number?,
	wanderX: number,
	wanderY: number,
	wanderAt: number,
	yawnT: number, -- seconds into a yawn, or -1
	yawnAt: number,
	stepT: number, -- phase for the mouth loop
	seed: number,
}

local Face = {}
Face.__index = Face

local preloaded = false
local function preload()
	if preloaded then
		return
	end
	preloaded = true
	local urls: { string } = {}
	for _, s in FaceArt.Sprites do
		table.insert(urls, "rbxassetid://" .. s.id)
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(urls)
	end)
end

local function spriteUrl(name: string): string
	local s = FaceArt.Sprites[name]
	return if s then "rbxassetid://" .. s.id else ""
end

local function layerOf(plate: Plate, name: string, z: number): Layer
	local label = Instance.new("ImageLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.ZIndex = z
	label.Visible = false
	label.ScaleType = Enum.ScaleType.Stretch
	label.Parent = plate.content
	local layer: Layer = {
		label = label,
		x = -9,
		y = -9,
		w = -9,
		h = -9,
		rot = 0,
		trans = 0,
		shown = false,
		image = "",
	}
	plate.layers[name] = layer
	return layer
end

-- Put a layer where it belongs on its plate: centre (dx, dy) from the plate centre and size (w, h), all in body
-- heights; writes only what changed.
local function place(
	plate: Plate,
	layer: Layer,
	image: string,
	dx: number,
	dy: number,
	w: number,
	h: number,
	rot: number?
)
	local label = layer.label
	if not layer.shown then
		layer.shown = true
		label.Visible = true
	end
	if layer.image ~= image then
		layer.image = image
		label.Image = image
	end
	local x, y = 0.5 + dx / plate.w, 0.5 - dy / plate.h
	if math.abs(layer.x - x) > 0.0008 or math.abs(layer.y - y) > 0.0008 then
		layer.x, layer.y = x, y
		label.Position = UDim2.fromScale(x, y)
	end
	local sw, sh = w / plate.w, h / plate.h
	if math.abs(layer.w - sw) > 0.0008 or math.abs(layer.h - sh) > 0.0008 then
		layer.w, layer.h = sw, sh
		label.Size = UDim2.fromScale(sw, sh)
	end
	local r = rot or 0
	if math.abs(layer.rot - r) > 0.2 then
		layer.rot = r
		label.Rotation = r
	end
end

local function fade(layer: Layer, trans: number)
	if math.abs(layer.trans - trans) > 0.01 then
		layer.trans = trans
		layer.label.ImageTransparency = trans
	end
end

local function hide(layer: Layer)
	if layer.shown then
		layer.shown = false
		layer.label.Visible = false
	end
end

local function newPlate(folder: Folder, name: string, u: number, v: number, w: number, h: number, scale: number): Plate
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(w * scale, h * scale, 0.02)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(math.ceil(w * C.CanvasPerUnit), math.ceil(h * C.CanvasPerUnit))
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = part
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.Position = UDim2.fromScale(0.5, 0.5)
	content.Size = UDim2.fromScale(1, 1)
	content.Parent = gui
	part.Parent = folder
	return { part = part, gui = gui, content = content, u = u, v = v, w = w, h = h, layers = {}, scaleU = 1, scaleV = 1 }
end

local function rand(lo: number, hi: number): number
	return lo + (hi - lo) * math.random()
end

-- `model` holds the body; `scale` is studs per body height (the model's scale).
function Face.new(model: Model, scale: number, seed: number?): Face
	preload()
	local old = model:FindFirstChild("Face")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Face"
	local eyeL = newPlate(folder, "EyeL", -C.EyeX, C.EyeY, EYE_PLATE_W, EYE_PLATE_H, scale)
	local eyeR = newPlate(folder, "EyeR", C.EyeX, C.EyeY, EYE_PLATE_W, EYE_PLATE_H, scale)
	local mouth = newPlate(folder, "Mouth", 0, C.MouthY, MOUTH_PLATE_W, MOUTH_PLATE_H, scale)
	for _, p in { eyeL, eyeR } do
		layerOf(p, "blush", 1)
		layerOf(p, "eye", 2)
		layerOf(p, "brow", 3)
		layerOf(p, "tear1", 4)
		layerOf(p, "tear2", 4)
		layerOf(p, "sweat", 4)
	end
	layerOf(mouth, "mouth", 2)

	local emote = Instance.new("Part")
	emote.Name = "Emote"
	emote.Anchored = true
	emote.CanCollide = false
	emote.CanQuery = false
	emote.CanTouch = false
	emote.CastShadow = false
	emote.Transparency = 1
	emote.Size = Vector3.new(0.2, 0.2, 0.2)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(EMOTE_PIXELS, EMOTE_PIXELS)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui.Enabled = false
	gui.Parent = emote
	local label = Instance.new("ImageLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = gui
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = label
	-- the small copies a lasting effect moves (z's, hearts, circling stars)
	local bits: { ImageLabel } = {}
	for i = 1, STREAM_BITS do
		local bit = Instance.new("ImageLabel")
		bit.Name = "Bit" .. i
		bit.BackgroundTransparency = 1
		bit.AnchorPoint = Vector2.new(0.5, 0.5)
		bit.Visible = false
		bit.Parent = gui
		bits[i] = bit
	end
	emote.Parent = folder
	folder.Parent = model

	local sd = seed or 1
	local normal = Expressions.get("normal") :: Expressions.Expression
	local self: Face = {
		folder = folder,
		scale = scale,
		eyeL = eyeL,
		eyeR = eyeR,
		mouth = mouth,
		emote = emote,
		emoteGui = gui,
		emoteLabel = label,
		emoteScale = uiScale,
		emoteBits = bits,
		emoteMode = "pop",
		expr = normal,
		t = 0,
		popT = 1,
		emoteT = 1,
		blinkAt = 0.5 + (sd * 0.37) % 3,
		blinkT = -1,
		blinkAgain = false,
		gx = 0,
		gy = 0,
		targetX = nil,
		targetY = nil,
		wanderX = 0,
		wanderY = 0,
		wanderAt = 0,
		yawnT = -1,
		yawnAt = 3,
		stepT = 0,
		seed = sd,
	}
	return setmetatable(self, Face) :: any
end

function Face.setEmotion(self: Face, id: string)
	local e = Expressions.get(id)
	if not e or e == self.expr then
		return
	end
	self.expr = e
	self.popT = 0
	self.yawnT = -1
	self.yawnAt = self.t + 2
	-- the emote above the head: a lasting effect for a few feelings, else a short pop-up of the icon
	local stream = STREAM_MODE[e.id]
	local streamSprite = if stream then FaceArt.Sprites[STREAM_SPRITE[stream]] else nil
	self.emoteT = 0
	if stream and streamSprite then
		self.emoteMode = stream
		self.emoteLabel.Visible = false
		self.emoteGui.Size = UDim2.fromOffset(EMOTE_PIXELS * STREAM_W, EMOTE_PIXELS * STREAM_H)
		local size = if stream == "orbit" then 0.45 else 0.6
		for _, bit in self.emoteBits do
			bit.Image = spriteUrl(STREAM_SPRITE[stream])
			bit.Size = UDim2.fromOffset(EMOTE_PIXELS * size, EMOTE_PIXELS * size)
			bit.Visible = false
		end
		self.emoteGui.Enabled = true
	elseif e.icon and FaceArt.Sprites[e.icon] then
		self.emoteMode = "pop"
		for _, bit in self.emoteBits do
			bit.Visible = false
		end
		self.emoteGui.Size = UDim2.fromOffset(EMOTE_PIXELS, EMOTE_PIXELS)
		self.emoteLabel.Image = spriteUrl(e.icon)
		self.emoteLabel.ImageTransparency = 0
		self.emoteLabel.Visible = true
		self.emoteGui.Enabled = true
	else
		self.emoteGui.Enabled = false
	end
	-- parts that only some emotions use go away; update puts the rest in place
	for _, p in { self.eyeL, self.eyeR } do
		for _, name in { "brow", "blush", "tear1", "tear2", "sweat" } do
			hide(p.layers[name])
		end
	end
end

-- Where the eyes look: x toward the viewer's right and y up, both -1..1, or nil for nothing in particular.
function Face.setGaze(self: Face, x: number?, y: number?)
	self.targetX = x
	self.targetY = y
end

local function blinkShut(self: Face): number
	if self.blinkT < 0 then
		return 0
	end
	local k = self.blinkT / C.BlinkSeconds
	return 1 - math.abs(2 * k - 1)
end

-- Poses the eye plate of one side. `side` is -1 (screen left) or 1.
local function eyeSide(self: Face, plate: Plate, side: number, shut: number)
	local e = self.expr
	local key = if side < 0 then "L" else "R"
	local name = if side < 0 then e.eyeL else e.eyeR
	local turned = if side < 0 then e.eyeTurnedL else e.eyeTurnedR
	local brow = if side < 0 then e.browL else e.browR
	local slotX = side * C.EyeX
	local layers = plate.layers
	local pop = 1 + C.PopSize * math.sin(math.pi * math.min(self.popT / C.PopSeconds, 1))

	-- a lid: a step 0..4 swapped in for the open eye
	if e.lid then
		local level = e.lid + (e.lidAmp or 0) * math.sin(TAU * (e.lidHz or 0) * self.t + self.seed)
		if self.yawnT >= 0 then
			level = 4
		end
		local step = math.floor(math.clamp(level, 0, 4) + 0.5)
		if step >= 1 then
			name = "lid" .. step .. "_" .. key
		end
	end
	local spr = FaceArt.Sprites[name]
	if not spr then
		return
	end
	-- (gx, gy already carry how far this emotion's eyes follow a target)
	local ex, ey = spr.cx - slotX, spr.cy - C.EyeY
	if e.alive then
		ex += self.gx * C.GazeX
		ey += self.gy * C.GazeY
	end
	-- the blink squashes the eye, not the body
	local squash = 1 - C.BlinkShut * shut
	local rot = if turned then 180 else 0
	if e.spin then
		rot = (self.t * e.spin * -side) % 360
	end
	place(plate, layers.eye, spriteUrl(name), ex, ey, spr.w, spr.h * squash, rot)

	-- a brow
	local browLayer = layers.brow
	if brow then
		local bspr = FaceArt.Sprites["brow_" .. key]
		local top = ey + spr.h * 0.5 * squash
		place(
			plate,
			browLayer,
			spriteUrl("brow_" .. key),
			ex,
			top + 0.045 + (brow.dy or 0),
			bspr.w,
			bspr.h,
			brow.tilt * (if side < 0 then -1 else 1)
		)
	else
		hide(browLayer)
	end

	-- blush under the eye
	if e.blush then
		local b = FaceArt.Sprites.blush
		place(plate, layers.blush, spriteUrl("blush"), side * 0.015, -0.135, b.w, b.h)
		fade(layers.blush, 0.1 + 0.05 * math.sin(self.t * 2 + self.seed))
	else
		hide(layers.blush)
	end

	-- a sweat drop at the outer upper corner of the right eye
	if e.sweat and side > 0 then
		local s = FaceArt.Sprites.sweat
		place(plate, layers.sweat, spriteUrl("sweat"), 0.115, 0.12 - 0.012 * math.sin(self.t * 3), s.w, s.h)
	else
		hide(layers.sweat)
	end

	-- tears running down from the outer lower corner, two drops half a cycle apart
	if e.tears then
		local d = FaceArt.Sprites.tear_drop
		for i, nm in { "tear1", "tear2" } do
			local k = (self.t * 1.1 + (i - 1) * 0.5) % 1
			place(
				plate,
				layers[nm],
				spriteUrl("tear_drop"),
				side * (0.05 + 0.02 * k),
				-0.07 - 0.2 * k * k,
				d.w * (0.6 + 0.5 * k),
				d.h * (0.6 + 0.5 * k)
			)
			fade(layers[nm], math.clamp((k - 0.55) / 0.45, 0, 1))
		end
	else
		hide(layers.tear1)
		hide(layers.tear2)
	end

	-- the swell of a change of emotion, and the skin's own stretch
	local su, sv = plate.scaleU * pop, plate.scaleV * pop
	local c = plate.content
	if math.abs(c.Size.X.Scale - su) > 0.004 or math.abs(c.Size.Y.Scale - sv) > 0.004 then
		c.Size = UDim2.fromScale(su, sv)
	end
end

local function mouthPlate(self: Face, plate: Plate)
	local e = self.expr
	local layer = plate.layers.mouth
	local name = e.mouth
	local scale = e.mouthScale or 1
	local sy = 1
	local jitter = 0
	local anim = e.mouthAnim
	if anim == "talk" then
		sy = 0.55 + 0.45 * math.abs(math.sin(TAU * 2.2 * self.t))
	elseif anim == "laugh" then
		sy = 0.5 + 0.5 * math.abs(math.sin(TAU * 3.2 * self.t))
	elseif anim == "chew" then
		local k = math.sin(TAU * 2.3 * self.t)
		if k > 0.1 and e.mouthAlt then
			name = e.mouthAlt
		end
		sy = 0.9 + 0.12 * k
	elseif anim == "quiver" then
		jitter = 0.004 * math.sin(TAU * 17 * self.t)
		sy = 1 + 0.12 * math.sin(TAU * 11 * self.t)
	elseif anim == "yawn" and self.yawnT >= 0 then
		local p = self.yawnT / 3.2
		local open = math.sin(math.pi * math.clamp(p, 0, 1)) ^ 0.6
		name = "surprise_mouth"
		scale = scale * (1 + 1.7 * open)
	end
	local spr = FaceArt.Sprites[name]
	if not spr then
		return
	end
	local pop = 1 + C.PopSize * math.sin(math.pi * math.min(self.popT / C.PopSeconds, 1))
	local dx = spr.cx + jitter
	local dy = spr.cy - C.MouthY
	if name == "surprise_mouth" and e.mouth ~= name then
		dx, dy = 0, 0
	end
	place(plate, layer, spriteUrl(name), dx, dy, spr.w * scale, spr.h * scale * sy)
	local su, sv = plate.scaleU * pop, plate.scaleV * pop
	local c = plate.content
	if math.abs(c.Size.X.Scale - su) > 0.004 or math.abs(c.Size.Y.Scale - sv) > 0.004 then
		c.Size = UDim2.fromScale(su, sv)
	end
end

local function frame(plate: Plate, bones: SlimeShape.Bones, scale: number, feet: CFrame): CFrame
	local p = SlimeShape.plate(plate.u, plate.v, bones)
	plate.scaleU, plate.scaleV = p.scaleU, p.scaleV
	local off = C.PlateOffset
	local pos = Vector3.new(p.px + p.nx * off, p.py + p.ny * off, p.pz + p.nz * off) * scale
	-- the part's right is the viewer's left, so the GUI's +x runs toward the viewer's right (SlimeShape)
	return feet * CFrame.fromMatrix(pos, Vector3.new(-p.rx, -p.ry, -p.rz), Vector3.new(p.ux, p.uy, p.uz))
end

-- Advance the face by dt and place its parts: appends the parts and where they go to the two arrays (the caller
-- moves them all in one BulkMoveTo). `bones` is the body's pose in mesh units, `feet` the body's CFrame at the feet
-- (look vector = front). Returns whether a blink began this frame, so the body can answer it.
function Face.update(
	self: Face,
	dt: number,
	bones: SlimeShape.Bones,
	feet: CFrame,
	parts: { BasePart },
	cfs: { CFrame }
): boolean
	local e = self.expr
	self.t += dt
	if self.popT < C.PopSeconds then
		self.popT += dt
	end

	-- blinks, each slime on its own rhythm, sometimes a double
	local began = false
	if e.alive and e.blink > 0 then
		if self.blinkT < 0 and self.t >= self.blinkAt then
			self.blinkT = 0
			began = true
		end
	end
	if self.blinkT >= 0 then
		self.blinkT += dt
		if self.blinkT >= C.BlinkSeconds then
			self.blinkT = -1
			if self.blinkAgain then
				self.blinkAgain = false
				self.blinkAt = self.t + C.DoubleBlinkGapSeconds
			else
				local slow = if e.blink == 2 then 1.6 else 1
				self.blinkAt = self.t + rand(C.BlinkMinSeconds, C.BlinkMaxSeconds) * slow
				self.blinkAgain = math.random() < C.DoubleBlinkChance
			end
		end
	end
	local shut = blinkShut(self)

	-- where the eyes look
	local tx, ty = 0, 0
	local target = self.targetX
	if e.alive then
		if target then
			tx = target * e.gaze
			ty = (self.targetY or 0) * e.gaze
		elseif e.gazeJitter then
			if self.t >= self.wanderAt then
				self.wanderAt = self.t + rand(0.2, 0.6)
				self.wanderX, self.wanderY = rand(-1, 1), rand(-0.6, 0.6)
			end
			tx, ty = self.wanderX, self.wanderY
		else
			if self.t >= self.wanderAt then
				self.wanderAt = self.t + (if e.gazeWander then rand(2, 4) else rand(1.2, 3.5))
				local amp = if e.gazeWander then 1 else 0.45
				self.wanderX, self.wanderY = rand(-amp, amp), rand(-0.4, 0.4) * amp
			end
			tx, ty = self.wanderX, self.wanderY
		end
		tx += e.gazeBiasX or 0
		ty += e.gazeBiasY or 0
	end
	local k = 1 - math.exp(-C.GazeRate * dt)
	self.gx += (math.clamp(tx, -1, 1) - self.gx) * k
	self.gy += (math.clamp(ty, -1, 1) - self.gy) * k

	-- a yawn now and then (sleepy)
	if e.mouthAnim == "yawn" then
		if self.yawnT >= 0 then
			self.yawnT += dt
			if self.yawnT > 3.2 then
				self.yawnT = -1
				self.yawnAt = self.t + rand(5, 8)
			end
		elseif self.t >= self.yawnAt then
			self.yawnT = 0
		end
	end

	eyeSide(self, self.eyeL, -1, shut)
	eyeSide(self, self.eyeR, 1, shut)
	mouthPlate(self, self.mouth)

	-- the plates on the skin
	local n = #parts
	for _, plate in { self.eyeL, self.eyeR, self.mouth } do
		n += 1
		parts[n] = plate.part
		cfs[n] = frame(plate, bones, self.scale, feet)
	end

	-- the emote: a pop-up beside the head, or a lasting effect over it
	if self.emoteGui.Enabled then
		local mode = self.emoteMode
		local side = if mode == "pop" or mode == "zzz" then -EMOTE_RIGHT else 0
		local x, y, z = SlimeShape.deform(side, 0.95, 0, bones)
		local lift = if mode == "pop" then EMOTE_UP else EMOTE_UP * 0.6
		n += 1
		parts[n] = self.emote
		cfs[n] = feet * CFrame.new(Vector3.new(x, y + lift, z) * self.scale)
		self.emoteT += dt
		local t = self.emoteT
		if mode == "pop" then
			-- pops in, bobs a moment, fades and is gone
			local pop = math.min(t / 0.3, 1)
			local back = 1 + 2.7 * (pop - 1) ^ 3 + 1.7 * (pop - 1) ^ 2 -- ease out back
			self.emoteScale.Scale = back * (1 + 0.05 * math.sin(TAU * 1.6 * self.t))
			self.emoteLabel.Position = UDim2.new(0.5, 0, 0.5, -3 * math.sin(TAU * 1.1 * self.t))
			local fadeFrom = C.EmoteShowSeconds - C.EmoteFadeSeconds
			self.emoteLabel.ImageTransparency = math.clamp((t - fadeFrom) / C.EmoteFadeSeconds, 0, 1)
			if t >= C.EmoteShowSeconds then
				self.emoteGui.Enabled = false
			end
		elseif mode == "orbit" then
			-- stars circle the top of the head; the ones behind it are smaller and paler
			local count = math.min(C.OrbitStars, #self.emoteBits)
			for i, bit in self.emoteBits do
				bit.Visible = i <= count
				if i <= count then
					local a = TAU * (C.OrbitHz * t + (i - 1) / count)
					local depth = math.sin(a)
					bit.Position = UDim2.fromScale(0.5 + 0.36 * math.cos(a), 0.62 + 0.08 * depth)
					bit.ImageTransparency = 0.35 - 0.35 * depth
					bit.ZIndex = if depth > 0 then 2 else 1
				end
			end
		else
			-- z's or hearts: born one after another at the bottom, rise, sway, grow and fade
			local every = if mode == "zzz" then C.ZzzEverySeconds else C.HeartsEverySeconds
			local life = if mode == "zzz" then C.ZzzLifeSeconds else C.HeartsLifeSeconds
			for i, bit in self.emoteBits do
				local age = t - (i - 1) * every
				local cycle = every * #self.emoteBits
				local f = if age < 0 then -1 else (age % cycle) / life
				bit.Visible = f >= 0 and f <= 1
				if bit.Visible then
					local sway = if mode == "zzz" then 0.18 * f else 0.12 * math.sin(TAU * (f * 1.5 + i * 0.3))
					bit.Position = UDim2.fromScale(0.35 + sway, 0.92 - 0.8 * f)
					bit.Rotation = if mode == "zzz" then -12 + 20 * f else 10 * math.sin(TAU * f)
					-- a z is born small and grows as it drifts away (z Z z); hearts swell a little and shrink
					local grow = if mode == "zzz" then 0.55 + 0.75 * f else 0.48 + 0.18 * math.sin(math.pi * f)
					bit.Size = UDim2.fromOffset(EMOTE_PIXELS * grow, EMOTE_PIXELS * grow)
					bit.ImageTransparency = math.clamp((f - 0.55) / 0.45, 0, 1)
				end
			end
		end
	end
	return began
end

function Face.destroy(self: Face)
	self.folder:Destroy()
end

return Face
