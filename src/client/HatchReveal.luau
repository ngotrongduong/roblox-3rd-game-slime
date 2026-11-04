--!strict
-- The hatch reveal (docs/reference/04-vfx-animation.md §7, rebuilt in the world instead of an overlay). The server decides
-- what hatched and has already put the baby in the village; this module only draws the moment, from the data the baby's
-- Configuration carries (SecretId / DualId / Material / Colour, Village.luau). Escalating, each kind its OWN design:
--
--   plain     a quick double shake, then the baby's own colour pops out in a few sparkles
--   dual      a golden sunburst and a fountain of stars in the design's two colours, a small label
--   material  a shell that glints, a prism flash, glitter falling like a curtain in the material's colour, a label
--   secret    the egg rises and shakes while violet stars pour in and a column of light streaks goes up, a lightning star
--             bursts, rainbow glints rain, a title with the slime's name
--
-- Every kind runs: anticipation (the egg's ghost shakes harder, a light builds) -> flash -> main picture -> secondary
-- glitter -> decay. The baby's body stays off (holds) until the flash. All pictures are the owner's battle art or Roblox's
-- own sparkles (Config.HatchFx.Textures); no camera effect, no white flash; the numbers are Config.HatchFx.
--
-- One Heartbeat loop steps every live reveal and disconnects when none is left; every reveal is one Part that holds its
-- emitters, light and title, plus the egg's ghost, and `destroy` removes all of it on every way out (end, leaving the
-- village, stop). At most MaxLive at once; one more only gets the small pop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Colours = require(ReplicatedStorage.Shared.Colours)
local Config = require(ReplicatedStorage.Shared.Config)
local DualDesigns = require(ReplicatedStorage.Shared.DualDesigns)
local Materials = require(ReplicatedStorage.Shared.Materials)
local SecretRecipes = require(ReplicatedStorage.Shared.SecretRecipes)

local H = Config.HatchFx
local T = H.Textures
local WHITE = Color3.new(1, 1, 1)

export type Spec = {
	-- "plain", "dual", "material" or "secret"
	kind: string,
	-- the egg's centre
	position: Vector3,
	-- the slime's English name (Dual design, Material or Secret recipe); "" for plain
	name: string,
	-- the baby's body colour; a dual's second colour; a material's own colour
	colour: Color3,
	colour2: Color3?,
	tint: Color3?,
	-- how rich the material is: 1 common, Material.RareShare, Material.PreciousShare
	richness: number?,
	-- the village's folder, to stop a reveal when the village goes (nil in a test)
	root: Instance?,
	-- the egg's ghost (a clone of the egg's model, ours to destroy) and the baby whose body waits for the flash
	ghost: Model?,
	slimeId: string?,
	-- the player's own village: the title shows and every particle is drawn
	own: boolean,
}

type Motion = {
	from: number,
	to: number,
	hzFrom: number,
	hzTo: number,
	swell: number,
	rise: number,
	glow: number,
	glowRange: number,
	glowColour: Color3,
	flashLight: number,
	lightSeconds: number,
	-- how see-through the egg's glow tint still is when the egg is about to burst (1 = never tinted)
	tintEnd: number,
}

type Title = {
	gui: BillboardGui,
	scale: UIScale,
	labels: { TextLabel },
	strokes: { UIStroke },
	start: number,
	hold: number,
	fade: number,
	pop: number,
	base: number,
	rise: number,
}

type Live = {
	spec: Spec,
	tier: number,
	share: number,
	born: number,
	anticipation: number,
	finish: number,
	motion: Motion,
	anchor: Part,
	light: PointLight?,
	tint: Highlight?,
	ghost: Model?,
	ghostCFrame: CFrame,
	ghostScale: number,
	phase: number,
	gather: ParticleEmitter?,
	gatherFrom: number,
	gatherTo: number,
	column: ParticleEmitter?,
	columnFrom: number,
	columnRateFrom: number,
	columnRateTo: number,
	flashed: boolean,
	flashAge: number,
	-- (seconds after the flash, what to do), earliest first
	events: { { at: number, run: (Live) -> () } },
	title: Title?,
}

type Shower = {
	size: { number },
	life: { number },
	speed: { number },
	spread: number,
	accel: Vector3?,
	drag: number?,
	colour: ColorSequence,
	emission: number?,
	peak: number?,
	spin: number?,
	direction: Enum.NormalId?,
	parent: Instance?,
	zoffset: number?,
}

local HatchReveal = {}

local lives: { Live } = {}
local holds: { [string]: number } = {}
local loop: RBXScriptConnection? = nil
local folder: Folder? = nil

local function fxFolder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "HatchRevealFx"
	made.Parent = workspace
	folder = made
	return made
end

-- 0 = no particles, 1 = the light version, 2 = full; from the graphics quality the player chose (1..21, 0 = automatic).
local function effectsTier(): number
	if not H.Enabled then
		return 0
	end
	local ok, level = pcall(function()
		return (settings() :: any).Rendering.QualityLevel.Value :: number
	end)
	if not ok or level == 0 then
		return 2
	end
	if level <= H.LowQualityMax then
		return 0
	end
	return if level <= H.LightQualityMax then 1 else 2
end

local function count(live: Live, n: number): number
	return if n <= 0 then 0 else math.max(1, math.floor(n * live.share + 0.5))
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function lighten(c: Color3, share: number): Color3
	return c:Lerp(WHITE, share)
end

local function swatch(id: string?): Color3
	local colour = if id then Colours.get(id) else nil
	return if colour then Color3.fromHex(colour.swatch) else WHITE
end

-- ===== Holding the baby back until the flash =====

-- Whether the village should keep this slime's body off the screen (the baby of a reveal that has not flashed yet).
function HatchReveal.holds(slimeId: string): boolean
	local until_ = holds[slimeId]
	if until_ == nil then
		return false
	end
	if os.clock() >= until_ then
		holds[slimeId] = nil
		return false
	end
	return true
end

local function release(live: Live)
	local id = live.spec.slimeId
	if id then
		holds[id] = nil
	end
end

-- ===== Building blocks: every picture is an emitter that emits once =====

local function emitter(live: Live, texture: string, parent: Instance?, emission: number?): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Rate = 0
	e.LightInfluence = 0
	e.LightEmission = emission or 0.4
	e.Speed = NumberRange.new(0)
	e.TimeScale = H.TimeScale
	e.Parent = parent or live.anchor
	return e
end

-- One big picture that swells, turns and fades where it stands (the sunburst, the prism flash, the lightning star).
local function card(live: Live, texture: string, size: number, seconds: number, spin: number, tint: Color3?)
	local e = emitter(live, texture, nil, 0.5)
	e.Lifetime = NumberRange.new(seconds)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size * 0.55),
		NumberSequenceKeypoint.new(0.25, size),
		NumberSequenceKeypoint.new(1, size * 1.25),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(0.12, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	if tint then
		e.Color = ColorSequence.new(tint)
	end
	e.Rotation = NumberRange.new(math.random(0, 359))
	e.RotSpeed = NumberRange.new(spin)
	e.ZOffset = 2
	e:Emit(1)
end

-- A burst of small pictures thrown out of the egg.
local function shower(live: Live, texture: string, n: number, o: Shower): ParticleEmitter?
	n = count(live, n)
	if n <= 0 then
		return nil
	end
	local e = emitter(live, texture, o.parent, o.emission)
	e.Lifetime = NumberRange.new(o.life[1], o.life[2])
	local big, small = o.size[2], o.size[1]
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, small * 0.5, small * 0.2),
		NumberSequenceKeypoint.new(0.18, (big + small) / 2, (big - small) / 2),
		NumberSequenceKeypoint.new(1, small * 0.2),
	})
	local peak = o.peak or 0.05
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, peak),
		NumberSequenceKeypoint.new(0.65, peak + 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Color = o.colour
	e.Speed = NumberRange.new(o.speed[1], o.speed[2])
	e.SpreadAngle = Vector2.new(o.spread, o.spread)
	e.EmissionDirection = o.direction or Enum.NormalId.Top
	e.Acceleration = o.accel or Vector3.zero
	e.Drag = o.drag or 0
	e.Rotation = NumberRange.new(0, 359)
	local spin = o.spin or 120
	e.RotSpeed = NumberRange.new(-spin, spin)
	e.ZOffset = o.zoffset or 3
	e:Emit(n)
	return e
end

local function schedule(live: Live, at: number, run: (Live) -> ())
	table.insert(live.events, { at = at, run = run })
end

-- An invisible anchored part for an emitter that needs a shape of its own (a sphere to gather from, a sheet to fall from).
local function shapePart(live: Live, size: Vector3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "Shape"
	part.Size = size
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.CFrame = CFrame.new(position)
	part.Parent = live.anchor
	return part
end

-- Small pictures that pour INTO a point from a sphere around it (the gathering before the flash).
local function gatherer(live: Live, texture: string, radius: number, size: number, colour: ColorSequence, at: Vector3)
	local part = shapePart(live, Vector3.one * radius * 2, at)
	local e = emitter(live, texture, part, 0.6)
	local life = 0.55
	e.Shape = Enum.ParticleEmitterShape.Sphere
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	e.Lifetime = NumberRange.new(life * 0.8, life)
	e.Speed = NumberRange.new(radius / life)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size * 0.3),
		NumberSequenceKeypoint.new(0.3, size),
		NumberSequenceKeypoint.new(1, size * 0.1),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.1),
		NumberSequenceKeypoint.new(0.85, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Color = colour
	e.Rotation = NumberRange.new(0, 359)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.ZOffset = 3
	return e
end

local function sequence(colours: { Color3 }): ColorSequence
	local keys = {}
	for index, colour in colours do
		table.insert(keys, ColorSequenceKeypoint.new((index - 1) / math.max(1, #colours - 1), colour))
	end
	return ColorSequence.new(keys)
end

local function rainbow(): ColorSequence
	local colours = {}
	for _, value in H.Rainbow do
		table.insert(colours, Color3.fromHex(value))
	end
	return sequence(colours)
end

-- ===== The title / label over the egg =====

local function screenScale(): number
	local camera = workspace.CurrentCamera
	local K = H.Title
	return if camera then math.clamp(camera.ViewportSize.Y / K.ScaleReference, K.ScaleMin, K.ScaleMax) else 1
end

local function makeTitle(
	live: Live,
	first: string,
	second: string,
	firstColour: Color3,
	secondColour: Color3,
	big: boolean,
	delay: number,
	hold: number,
	fade: number,
	pop: number
)
	local K = H.Title
	local s = screenScale()
	local gui = Instance.new("BillboardGui")
	gui.Name = "HatchTitle"
	gui.Adornee = live.anchor
	-- (not AlwaysOnTop: those billboards are skipped by Studio's screen capture, and the words stand clear above the egg)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Size =
		UDim2.fromOffset((if big then K.Width else K.SmallWidth) * s, (if big then K.Height else K.SmallHeight) * s)
	local base = K.Lift + live.motion.rise
	gui.StudsOffsetWorldSpace = Vector3.new(0, base, 0)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = holder
	local labels: { TextLabel } = {}
	local strokes: { UIStroke } = {}
	local function line(text: string, colour: Color3, y: number, height: number)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0, y)
		label.Size = UDim2.fromScale(1, height)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = colour
		label.TextTransparency = 1
		label.Text = text
		label.Parent = holder
		-- a dark outline keeps the words readable on a bright field (it fades with them)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromHex(K.Stroke)
		stroke.Thickness = K.StrokePixels * s
		stroke.Transparency = 1
		stroke.Parent = label
		table.insert(labels, label)
		table.insert(strokes, stroke)
	end
	line(first, firstColour, 0, 0.56)
	line(second, secondColour, 0.54, 0.44)
	gui.Parent = live.anchor
	live.title = {
		gui = gui,
		scale = scale,
		labels = labels,
		strokes = strokes,
		start = live.flashAge + delay,
		hold = hold,
		fade = fade,
		pop = pop,
		base = base,
		rise = K.Rise,
	}
end

-- ===== The four designs =====

local function plainBurst(live: Live)
	local P = H.Plain
	local c = live.spec.colour
	local pale = lighten(c, P.WhiteShare)
	shower(live, T.sparkle, P.Sparkles, {
		size = { P.SparkleSize * 0.7, P.SparkleSize * 1.3 },
		life = { P.LifeMin, P.LifeMax },
		speed = { P.SpeedMin, P.SpeedMax },
		spread = 180,
		accel = Vector3.new(0, -8, 0),
		drag = 2,
		colour = ColorSequence.new(pale),
		emission = 0.5,
	})
	shower(live, T.star, P.Stars, {
		size = { P.StarSize * 0.7, P.StarSize },
		life = { P.LifeMin, P.LifeMax },
		speed = { P.SpeedMin, P.SpeedMax },
		spread = 180,
		accel = Vector3.new(0, -10, 0),
		drag = 2,
		colour = sequence({ lighten(c, 0.7), c }),
		emission = 0.3,
	})
end

local function dualBurst(live: Live)
	local D = H.Dual
	local c1 = live.spec.colour
	local c2 = live.spec.colour2 or c1
	local gold = Color3.fromHex(D.Gold)
	local cream = Color3.fromHex(D.Cream)
	card(live, T.sunburst, D.SunSize, D.SunSeconds, D.SunSpin)
	if live.tier >= 2 then
		schedule(live, D.SunBackDelay, function(l: Live)
			card(l, T.sunburst, D.SunBackSize, D.SunSeconds * 0.8, -D.SunSpin * 1.4)
		end)
	end
	-- the fountain: stars in the two colours of this design, going up and out and falling back
	local stars = sequence({ lighten(c1, 0.55), lighten(c2, 0.35), cream })
	shower(live, T.star, D.Stars, {
		size = { D.StarSize * 0.6, D.StarSize },
		life = { 0.9, 1.3 },
		speed = { D.StarSpeedMin, D.StarSpeedMax },
		spread = 65,
		accel = Vector3.new(0, -D.StarGravity, 0),
		drag = 0.6,
		colour = stars,
		emission = 0.35,
	})
	shower(live, T.sparkle, D.Sparkles, {
		size = { D.SparkleSize * 0.7, D.SparkleSize * 1.2 },
		life = { 0.6, 1 },
		speed = { 4, 9 },
		spread = 180,
		accel = Vector3.new(0, -6, 0),
		drag = 1.5,
		colour = sequence({ cream, gold }),
		emission = 0.6,
	})
	for _, at in D.LaterAt do
		schedule(live, at, function(l: Live)
			shower(l, T.star, D.LaterStars, {
				size = { D.StarSize * 0.5, D.StarSize * 0.8 },
				life = { 1, 1.4 },
				speed = { 2, 5 },
				spread = 50,
				accel = Vector3.new(0, -7, 0),
				drag = 0.8,
				colour = stars,
				emission = 0.35,
			})
		end)
	end
end

local function materialBurst(live: Live)
	local M = H.Material
	local tint = live.spec.tint or live.spec.colour
	local rich = live.spec.richness or 1
	local pale = lighten(tint, 0.35)
	card(live, T.prism, M.PrismSize, M.PrismSeconds, M.PrismSpin, pale)
	if live.tier >= 2 then
		schedule(live, 0.07, function(l: Live)
			card(l, T.prism, M.PrismBackSize, M.PrismSeconds, -M.PrismSpin, nil)
		end)
		if rich >= H.Material.PreciousShare then
			schedule(live, M.PreciousPrismDelay, function(l: Live)
				card(l, T.prism, M.PrismSize * 1.25, M.PrismSeconds, M.PrismSpin * 1.3, pale)
			end)
		end
	end
	-- the glitter curtain: a sheet above the egg lets sparkles and tinted stars fall slowly over it, down to the ground
	local sheet = shapePart(live, Vector3.new(5, 0.2, 5), live.spec.position + Vector3.new(0, 3.2, 0))
	local glitter = sequence({ WHITE, pale, tint })
	local function fall(l: Live, texture: string, n: number, size: number, colour: ColorSequence, emission: number)
		shower(l, texture, n, {
			size = { size * 0.6, size },
			life = { M.GlitterLifeMin, M.GlitterLifeMax },
			speed = { M.GlitterSpeedMin * 0.4, M.GlitterSpeedMax * 0.5 },
			spread = 60,
			direction = Enum.NormalId.Bottom,
			accel = Vector3.new(0, -M.GlitterGravity, 0),
			drag = 1.2,
			colour = colour,
			emission = emission,
			spin = 90,
			parent = sheet,
		})
	end
	fall(live, T.sparkle, M.Glitter * rich, M.GlitterSize, glitter, 0.6)
	fall(live, T.star, M.Stars * rich, M.StarSize, sequence({ pale, tint }), 0.35)
	-- and a burst out of the egg itself
	shower(live, T.sparkle, M.Glitter * 0.6 * rich, {
		size = { M.GlitterSize * 0.7, M.GlitterSize * 1.2 },
		life = { 0.6, 1.1 },
		speed = { M.GlitterSpeedMin, M.GlitterSpeedMax },
		spread = 180,
		accel = Vector3.new(0, -4, 0),
		drag = 1.5,
		colour = glitter,
		emission = 0.6,
	})
	for _, at in M.LaterAt do
		schedule(live, at, function(l: Live)
			fall(l, T.sparkle, M.LaterGlitter * rich, M.GlitterSize, glitter, 0.6)
		end)
	end
end

local function secretBurst(live: Live)
	local S = H.Secret
	local violet = Color3.fromHex(S.Violet)
	local bow = rainbow()
	card(live, T.arcane, S.StarSize, S.StarSeconds, S.StarSpin)
	if live.tier >= 2 then
		schedule(live, S.StarBackDelay, function(l: Live)
			card(l, T.arcane, S.StarBackSize, S.StarSeconds * 0.85, -S.StarSpin * 1.5)
		end)
	end
	-- the column of light goes out in one big pulse, then stops
	local column = live.column
	if column then
		column:Emit(count(live, S.ColumnBurst))
		column.Rate = 0
	end
	shower(live, T.star, S.Glints, {
		size = { S.GlintSize * 0.6, S.GlintSize },
		life = { 1, 1.5 },
		speed = { S.GlintSpeedMin, S.GlintSpeedMax },
		spread = 100,
		accel = Vector3.new(0, -S.GlintGravity, 0),
		drag = 0.7,
		colour = bow,
		emission = 0.4,
	})
	shower(live, T.arcaneStar, S.Motes, {
		size = { S.MoteSize * 0.6, S.MoteSize },
		life = { 0.8, 1.3 },
		speed = { 5, 10 },
		spread = 180,
		accel = Vector3.new(0, 1.5, 0),
		drag = 1.6,
		colour = ColorSequence.new(WHITE),
		emission = 0.5,
	})
	shower(live, T.sparkle, S.Sparkles, {
		size = { S.SparkleSize * 0.7, S.SparkleSize * 1.2 },
		life = { 1, 1.6 },
		speed = { 2, 6 },
		spread = 180,
		accel = Vector3.new(0, 2.5, 0),
		drag = 1.2,
		colour = sequence({ WHITE, lighten(violet, 0.4) }),
		emission = 0.6,
	})
	for _, at in S.LaterAt do
		schedule(live, at, function(l: Live)
			shower(l, T.star, S.LaterGlints, {
				size = { S.GlintSize * 0.5, S.GlintSize * 0.8 },
				life = { 1, 1.4 },
				speed = { 3, 7 },
				spread = 120,
				accel = Vector3.new(0, -5, 0),
				drag = 0.9,
				colour = bow,
				emission = 0.4,
			})
		end)
	end
end

local BURSTS: { [string]: (Live) -> () } = {
	plain = plainBurst,
	dual = dualBurst,
	material = materialBurst,
	secret = secretBurst,
}

-- The words over the egg, for the player's own hatches only (a plain one has none).
local function titleFor(live: Live)
	local K = H.Title
	local spec = live.spec
	if not spec.own then
		return
	end
	if spec.kind == "dual" then
		makeTitle(
			live,
			"DUAL!",
			spec.name,
			Color3.fromHex(K.DualText),
			Color3.fromHex(K.Cream),
			false,
			0.1,
			H.Dual.LabelSeconds,
			0.35,
			0.25
		)
	elseif spec.kind == "material" then
		makeTitle(
			live,
			"MATERIAL!",
			spec.name,
			lighten(spec.tint or spec.colour, 0.2),
			Color3.fromHex(K.Cream),
			false,
			0.1,
			H.Material.LabelSeconds,
			0.35,
			0.25
		)
	elseif spec.kind == "secret" then
		local S = H.Secret
		makeTitle(
			live,
			"SECRET SLIME!",
			spec.name,
			Color3.fromHex(K.SecretText),
			Color3.fromHex(K.Cream),
			true,
			S.TitleDelay,
			S.TitleHoldSeconds,
			S.TitleFadeSeconds,
			S.TitlePopSeconds
		)
	end
end

local function motionOf(kind: string): (Motion, number, number)
	if kind == "dual" then
		local D = H.Dual
		return {
			from = D.WobbleFrom,
			to = D.WobbleTo,
			hzFrom = D.HzFrom,
			hzTo = D.HzTo,
			swell = D.Swell,
			rise = 0,
			glow = D.Glow,
			glowRange = D.GlowRange,
			glowColour = Color3.fromHex(D.GlowColour),
			flashLight = D.FlashLight,
			lightSeconds = D.LightSeconds,
			tintEnd = D.TintEnd,
		},
			D.Anticipation,
			D.EndSeconds
	elseif kind == "material" then
		local M = H.Material
		return {
			from = M.WobbleFrom,
			to = M.WobbleTo,
			hzFrom = M.HzFrom,
			hzTo = M.HzTo,
			swell = M.Swell,
			rise = 0,
			glow = M.Glow,
			glowRange = M.GlowRange,
			glowColour = WHITE,
			flashLight = M.FlashLight,
			lightSeconds = M.LightSeconds,
			tintEnd = M.TintEnd,
		},
			M.Anticipation,
			M.EndSeconds
	elseif kind == "secret" then
		local S = H.Secret
		return {
			from = S.WobbleFrom,
			to = S.WobbleTo,
			hzFrom = S.HzFrom,
			hzTo = S.HzTo,
			swell = S.Swell,
			rise = S.Rise,
			glow = S.Glow,
			glowRange = S.GlowRange,
			glowColour = Color3.fromHex(S.GlowColour),
			flashLight = S.FlashLight,
			lightSeconds = S.LightSeconds,
			tintEnd = S.TintEnd,
		},
			S.Anticipation,
			S.EndSeconds
	end
	local P = H.Plain
	return {
		from = P.WobbleFrom,
		to = P.WobbleTo,
		hzFrom = P.HzFrom,
		hzTo = P.HzTo,
		swell = P.Swell,
		rise = 0,
		glow = 0,
		glowRange = 0,
		glowColour = WHITE,
		flashLight = 0,
		lightSeconds = 0,
		tintEnd = 1,
	},
		P.Anticipation,
		P.EndSeconds
end

-- ===== The step =====

local function destroy(live: Live)
	release(live)
	if live.ghost then
		live.ghost:Destroy()
		live.ghost = nil
	end
	live.anchor:Destroy()
end

local function flash(live: Live, age: number)
	live.flashed = true
	live.flashAge = age
	release(live)
	local ghost = live.ghost
	if ghost then
		ghost:Destroy()
		live.ghost = nil
	end
	live.anchor.CFrame = CFrame.new(live.spec.position + Vector3.new(0, live.motion.rise, 0))
	if live.gather then
		live.gather.Rate = 0
	end
	local light = live.light
	if light then
		light.Brightness = live.motion.flashLight
	end
	-- (the lowest setting has no particles and no light: the words only)
	if live.tier >= 1 then
		BURSTS[live.spec.kind](live)
	end
	titleFor(live)
end

local function smooth(p: number): number
	return p * p * (3 - 2 * p)
end

local function anticipate(live: Live, p: number, dt: number)
	local m = live.motion
	local e = p * p
	live.phase += dt * lerp(m.hzFrom, m.hzTo, e) * math.pi * 2
	local amp = math.rad(lerp(m.from, m.to, e))
	local ghost = live.ghost
	if ghost then
		local lift = m.rise * smooth(p)
		ghost:PivotTo(
			live.ghostCFrame
				* CFrame.new(0, lift, 0)
				* CFrame.Angles(amp * 0.5 * math.cos(live.phase * 0.83), 0, amp * math.sin(live.phase))
		)
		if m.swell > 0 then
			local target = live.ghostScale * (1 + m.swell * e * p)
			if math.abs(ghost:GetScale() - target) > 1e-3 then
				ghost:ScaleTo(target)
			end
		end
	end
	local light = live.light
	if light then
		light.Brightness = m.glow * smooth(p)
	end
	local tint = live.tint
	if tint then
		tint.FillTransparency = lerp(1, m.tintEnd, e)
	end
	local gather = live.gather
	if gather then
		gather.Rate = lerp(live.gatherFrom, live.gatherTo, e)
	end
	local column = live.column
	if column and p >= live.columnFrom then
		local k = (p - live.columnFrom) / (1 - live.columnFrom)
		column.Rate = lerp(live.columnRateFrom, live.columnRateTo, k)
	end
end

local function stepTitle(live: Live, age: number)
	local title = live.title
	if not title then
		return
	end
	local t = age - title.start
	if t < 0 then
		return
	end
	local total = title.pop + title.hold + title.fade
	if t >= total then
		title.gui:Destroy()
		live.title = nil
		return
	end
	-- a pop: grows past full size and settles (0.3 -> 1.15 -> 1), then holds, then fades while it floats up
	local scale
	if t < title.pop then
		local k = t / title.pop
		scale = if k < 0.6 then lerp(0.3, 1.15, k / 0.6) else lerp(1.15, 1, (k - 0.6) / 0.4)
	else
		scale = 1
	end
	title.scale.Scale = scale
	local alpha = if t < title.pop * 0.5
		then 1 - t / (title.pop * 0.5)
		elseif t < title.pop + title.hold then 0
		else (t - title.pop - title.hold) / title.fade
	for _, label in title.labels do
		label.TextTransparency = alpha
	end
	for _, stroke in title.strokes do
		stroke.Transparency = alpha
	end
	title.gui.StudsOffsetWorldSpace = Vector3.new(0, title.base + title.rise * smooth(math.clamp(t / total, 0, 1)), 0)
end

local function step(dt: number)
	local now = os.clock()
	for index = #lives, 1, -1 do
		local live = lives[index]
		local age = (now - live.born) * H.TimeScale
		if not live.anchor.Parent then
			destroy(live)
			table.remove(lives, index)
			continue
		end
		if not live.flashed then
			if age >= live.anticipation then
				flash(live, age)
			else
				anticipate(live, age / live.anticipation, dt * H.TimeScale)
			end
		end
		if live.flashed then
			local sinceFlash = age - live.flashAge
			while #live.events > 0 and live.events[1].at <= sinceFlash do
				local event = table.remove(live.events, 1)
				if event then
					event.run(live)
				end
			end
			local light = live.light
			if light then
				local k = 1 - sinceFlash / math.max(live.motion.lightSeconds, 0.01)
				if k <= 0 then
					light:Destroy()
					live.light = nil
				else
					light.Brightness = live.motion.flashLight * k * k
				end
			end
			stepTitle(live, age)
		end
		if age >= live.finish then
			destroy(live)
			table.remove(lives, index)
		end
	end
	if #lives == 0 and loop then
		loop:Disconnect()
		loop = nil
	end
end

-- ===== Starting one =====

-- Plays a reveal. Returns false when nothing was drawn (the caller's baby shows at once).
function HatchReveal.play(spec: Spec): boolean
	local ghost = spec.ghost
	local function fail(): boolean
		if ghost then
			ghost:Destroy()
		end
		if spec.slimeId then
			holds[spec.slimeId] = nil
		end
		return false
	end
	if not H.Enabled then
		return fail()
	end
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - spec.position).Magnitude > H.ViewStuds then
		return fail()
	end
	-- one over the cap only gets the small pop, with no wait
	local crowded = #lives >= H.MaxLive
	local kind = if crowded then "plain" else spec.kind
	local tier = effectsTier()
	local motion, anticipation, finish = motionOf(kind)
	if kind == "material" then
		-- the shell takes on the colour of the material (a plain white tint would not show on a white egg)
		motion.glowColour = lighten(spec.tint or spec.colour, 0.2)
	end
	if crowded then
		anticipation = 0
	elseif tier == 0 then
		anticipation = math.min(anticipation, H.LowAnticipationSeconds)
	end
	local anchor = Instance.new("Part")
	anchor.Name = "HatchReveal"
	anchor.Size = Vector3.new(1.4, 1, 1.4)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new(spec.position)
	anchor.Parent = fxFolder()
	local live: Live = {
		spec = spec,
		tier = tier,
		share = (if tier == 1 then H.LightShare else 1) * (if spec.own then 1 else H.OthersShare),
		born = os.clock(),
		anticipation = anticipation,
		finish = anticipation + finish,
		motion = motion,
		anchor = anchor,
		light = nil,
		tint = nil,
		ghost = ghost,
		ghostCFrame = CFrame.new(spec.position),
		ghostScale = 1,
		phase = 0,
		gather = nil,
		gatherFrom = 0,
		gatherTo = 0,
		column = nil,
		columnFrom = 1,
		columnRateFrom = 0,
		columnRateTo = 0,
		flashed = false,
		flashAge = 0,
		events = {},
		title = nil,
	}
	if kind ~= spec.kind then
		live.spec = table.clone(spec)
		live.spec.kind = kind
	end
	if ghost then
		ghost.Parent = fxFolder()
		live.ghostCFrame = ghost:GetPivot()
		live.ghostScale = ghost:GetScale()
	end
	-- the light that builds in the egg: one a reveal, none on the lowest setting
	if tier >= 1 and motion.glow > 0 and anticipation > 0 then
		local light = Instance.new("PointLight")
		light.Color = motion.glowColour
		light.Range = motion.glowRange
		light.Brightness = 0
		light.Shadows = false
		light.Parent = anchor
		live.light = light
	end
	-- the egg takes on the colour of what is inside it: a see-through tint that deepens (no outline, no box)
	if tier >= 1 and ghost and motion.tintEnd < 1 and anticipation > 0 then
		local tint = Instance.new("Highlight")
		tint.Adornee = ghost
		tint.FillColor = motion.glowColour
		tint.FillTransparency = 1
		tint.OutlineTransparency = 1
		tint.DepthMode = Enum.HighlightDepthMode.Occluded
		tint.Parent = ghost
		live.tint = tint
	end
	-- what gathers while the egg shakes: dual and secret pour stars into it, a material's shell glints
	if tier >= 1 and anticipation > 0 then
		local at = spec.position + Vector3.new(0, motion.rise * 0.6, 0)
		if kind == "dual" then
			local D = H.Dual
			local g = gatherer(
				live,
				T.star,
				D.GatherRadius,
				D.GatherSize,
				sequence({ Color3.fromHex(D.Gold), Color3.fromHex(D.Cream) }),
				at
			)
			live.gather, live.gatherFrom, live.gatherTo = g, D.GatherRateFrom * live.share, D.GatherRateTo * live.share
		elseif kind == "secret" then
			local S = H.Secret
			local g = gatherer(live, T.arcaneStar, S.GatherRadius, S.GatherSize, ColorSequence.new(WHITE), at)
			live.gather, live.gatherFrom, live.gatherTo = g, S.GatherRateFrom * live.share, S.GatherRateTo * live.share
			-- the column: streaks of the star, stretched along their way up
			local e = emitter(live, T.star, nil, 0.5)
			e.Orientation = Enum.ParticleOrientation.VelocityParallel
			e.EmissionDirection = Enum.NormalId.Top
			e.SpreadAngle = Vector2.new(5, 5)
			e.Speed = NumberRange.new(S.ColumnSpeed * 0.7, S.ColumnSpeed)
			e.Lifetime = NumberRange.new(S.ColumnLife * 0.7, S.ColumnLife)
			e.Squash = NumberSequence.new(-1.2)
			e.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, S.ColumnSize * 0.4),
				NumberSequenceKeypoint.new(0.3, S.ColumnSize),
				NumberSequenceKeypoint.new(1, S.ColumnSize * 0.2),
			})
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.25),
				NumberSequenceKeypoint.new(1, 1),
			})
			e.Color = sequence({ WHITE, Color3.fromHex(S.Violet) })
			e.ZOffset = 1
			live.column = e
			live.columnFrom = S.ColumnFrom
			live.columnRateFrom = S.ColumnRateFrom * live.share
			live.columnRateTo = S.ColumnRateTo * live.share
		elseif kind == "material" then
			local M = H.Material
			local part = shapePart(live, Vector3.one * M.GlintRadius * 2, at)
			local e = emitter(live, T.sparkle, part, 0.6)
			e.Shape = Enum.ParticleEmitterShape.Sphere
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			e.Lifetime = NumberRange.new(0.3, 0.5)
			e.Speed = NumberRange.new(0.5, 1.5)
			e.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, M.GlintSize * 0.3),
				NumberSequenceKeypoint.new(0.4, M.GlintSize),
				NumberSequenceKeypoint.new(1, 0),
			})
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.1),
				NumberSequenceKeypoint.new(1, 1),
			})
			e.Color = ColorSequence.new(lighten(spec.tint or spec.colour, 0.5))
			e.Rotation = NumberRange.new(0, 359)
			e.ZOffset = 3
			live.gather, live.gatherFrom, live.gatherTo = e, M.GlintRateFrom * live.share, M.GlintRateTo * live.share
		end
	end
	table.insert(lives, live)
	if not loop then
		loop = RunService.Heartbeat:Connect(step)
	end
	-- the baby's body waits for the flash
	if spec.slimeId then
		holds[spec.slimeId] = os.clock() + anticipation + H.WaitSlimeSeconds
	end
	return true
end

-- ===== From a hatched egg =====

local function attrString(inst: Instance, name: string): string?
	local value = inst:GetAttribute(name)
	return if type(value) == "string" and value ~= "" then value else nil
end

-- What kind of slime a baby's Configuration says it is, and what to call it.
local function describe(config: Instance?): (string, string, Color3, Color3?, Color3?, number)
	local colour = swatch(if config then attrString(config, "Colour") else nil)
	if not config then
		return "plain", "", colour, nil, nil, 1
	end
	local secretId = attrString(config, "SecretId")
	if secretId then
		local recipe = SecretRecipes.get(secretId)
		return "secret", if recipe then recipe.name else "Secret Slime", colour, nil, nil, 1
	end
	local dualId = attrString(config, "DualId")
	if dualId then
		local design = DualDesigns.get(dualId)
		if design then
			return "dual", design.name, swatch(design.bodyColour), swatch(design.patternColour), nil, 1
		end
		return "dual", "Dual Slime", colour, nil, nil, 1
	end
	local materialId = attrString(config, "Material")
	if materialId then
		local material = Materials.get(materialId)
		if material then
			local tint = if material.colour then Color3.fromHex(material.colour) else colour
			local richness = if material.tier == "precious"
				then H.Material.PreciousShare
				elseif material.tier == "rare" then H.Material.RareShare
				else 1
			return "material", material.name, colour, nil, tint, richness
		end
	end
	return "plain", "", colour, nil, nil, 1
end

-- Starts the reveal of an egg that has just hatched: `egg` is the egg's Configuration (its Offspring attribute names the
-- baby), `model` the egg's drawn model (cloned for the ghost; the caller still destroys it) and `position` its centre.
function HatchReveal.fromEgg(root: Instance, egg: Instance, model: Model?, position: Vector3, own: boolean)
	if not H.Enabled then
		return
	end
	local id = attrString(egg, "Offspring")
	if not id then
		return
	end
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - position).Magnitude > H.ViewStuds then
		return
	end
	holds[id] = os.clock() + H.WaitSlimeSeconds + 0.2
	local ghost = if model then model:Clone() else nil
	task.spawn(function()
		-- the baby's data arrives with (or a moment after) the egg's removal
		local deadline = os.clock() + H.WaitSlimeSeconds
		local slimes = root:FindFirstChild("Slimes")
		local config = if slimes then slimes:FindFirstChild(id) else nil
		while not (config and config:GetAttribute("Colour") ~= nil) and os.clock() < deadline and root.Parent do
			task.wait()
			slimes = root:FindFirstChild("Slimes")
			config = if slimes then slimes:FindFirstChild(id) else nil
		end
		if not root.Parent then
			if ghost then
				ghost:Destroy()
			end
			holds[id] = nil
			return
		end
		local kind, name, colour, colour2, tint, richness = describe(config)
		HatchReveal.play({
			kind = kind,
			position = position,
			name = name,
			colour = colour,
			colour2 = colour2,
			tint = tint,
			richness = richness,
			root = root,
			ghost = ghost,
			slimeId = id,
			own = own,
		})
	end)
end

-- Ends every reveal of one village (it left the world).
function HatchReveal.stopFor(root: Instance)
	for index = #lives, 1, -1 do
		local live = lives[index]
		if live.spec.root == root then
			destroy(live)
			table.remove(lives, index)
		end
	end
end

-- Ends everything at once.
function HatchReveal.stop()
	for index = #lives, 1, -1 do
		destroy(lives[index])
		table.remove(lives, index)
	end
	table.clear(holds)
	if loop then
		loop:Disconnect()
		loop = nil
	end
end

return HatchReveal
