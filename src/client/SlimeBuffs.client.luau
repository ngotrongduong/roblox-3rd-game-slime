--!strict
-- The dish buff on a slime, drawn on the client. The server publishes BuffStat / BuffPercent / BuffUntil /
-- BuffRarity on each slime's Configuration (all empty or 0 when no buff lives); this script only draws:
--
--   * a small badge beside the emote: the stat's icon, "+N%" and a frame in the rarity's colour (a BillboardGui sized
--     in pixels and scaled with the screen). It goes away by itself when BuffUntil passes (workspace:GetServerTimeNow),
--     no server message needed.
--   * a few particles of the stat's own design while the buff lives: attack = sparks rising, defence = the owner's
--     shields breathing on the skin, speed = soft streaks thrown back (fewer when it stands still), hp = small hearts
--     floating up. Rarer dishes are denser and brighter, never a different colour glow (the owner: no rarity glow in
--     the world).
--   * a short one-shot burst when BuffUntil goes up, a different one for each stat.
--
-- One owner: everything a buff starts hangs under the slime's body part (SlimeActor moves it each frame, so nothing
-- here runs per frame). `stop()` undoes it all and is called when this script is destroyed; a body that streams out
-- takes its own pieces with it, and the slow poll lets go of a buff when it ends or the slime goes far from the camera.
-- Only the nearest few buffed slimes get particles, none under a low graphics quality; no sound, no camera change.

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)

local C = Config.SlimeBuffFx
local B = C.Badge
local MESH_HEIGHT = Config.Slime.MeshHeight
local WATCHED = { "BuffStat", "BuffPercent", "BuffUntil", "BuffRarity" }
local STATS: { [string]: boolean } = { attack = true, defence = true, speed = true, hp = true }
-- A let-go emitter keeps its last particles for this long before it is destroyed (a little more than the longest
-- particle life in Config.SlimeBuffFx), so a buff ends softly instead of vanishing.
local FADE_SECONDS = 2.5
-- Pixels from the badge's left edge to its icon, and between icon and text.
local BADGE_PAD, BADGE_GAP = 5, 3

type Rarity = { rate: number, size: number, alpha: number, burst: number }
type Piece = { emitter: ParticleEmitter, rate: number, wind: boolean }
type Fx = { key: string, body: BasePart, pieces: { Piece }, moving: boolean }
type Badge = { key: string, body: BasePart, gui: BillboardGui, scale: UIScale, tween: Tween?, popUntil: number }
type State = {
	config: Configuration,
	stat: string,
	percent: number,
	rarity: string,
	untilTime: number,
	-- os.clock() when a start burst became due, or 0
	burstAt: number,
	bornAt: number,
	readQueued: boolean,
	fx: Fx?,
	badge: Badge?,
	connections: { RBXScriptConnection },
}
type Candidate = { st: State, body: BasePart, d: number }

local states: { [Configuration]: State } = {}
-- the slimes whose buff is alive right now (the only ones the poll looks at)
local live: { [Configuration]: State } = {}
local liveBursts: { [ParticleEmitter]: boolean } = {}
local burstCount = 0
local connections: { RBXScriptConnection } = {}
local running = true
local stepQueued = false
local candidates: { Candidate } = {}

-- ===== Small helpers =====

local function iconUrl(name: string): string
	local id = (Config.Ui.Icons :: any)[name]
	return if type(id) == "number" and id > 0 then "rbxassetid://" .. tostring(id) else ""
end

local function rarityOf(name: string): Rarity
	local found = (C.Rarity :: any)[name]
	return if found then found else C.Rarity.common
end

local function seq(points: { { number } }): NumberSequence
	local list: { NumberSequenceKeypoint } = {}
	for _, p in points do
		table.insert(list, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(list)
end

local function bodyScale(body: BasePart): number
	return body.Size.Y / MESH_HEIGHT
end

local function screenScale(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / B.ScaleReference, B.ScaleMin, B.ScaleMax) else 1
end

-- 0 = no particles, 1 = the light version, 2 = full; from the graphics quality the player chose (1..21, 0 = automatic).
local function effectsTier(): number
	if not C.Enabled then
		return 0
	end
	local ok, level = pcall(function()
		return (settings() :: any).Rendering.QualityLevel.Value :: number
	end)
	if not ok or level == 0 then
		return 2
	end
	if level <= C.LowQualityMax then
		return 0
	end
	return if level <= C.LightQualityMax then 1 else 2
end

local function isMoving(config: Configuration, now: number): boolean
	local from, to = config:GetAttribute("LegStart"), config:GetAttribute("LegEnd")
	return type(from) == "number" and type(to) == "number" and to > from and now >= from and now < to
end

local function newEmitter(parent: BasePart, texture: string): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Rate = 0
	e.LightInfluence = 0
	e.Parent = parent
	return e
end

-- How faint a particle may be at its peak: the stat's own base, nudged by the rarity (rarer = brighter).
local function peakOf(base: number, r: Rarity): number
	return math.clamp(base + r.alpha - C.Rarity.common.alpha, 0, 1)
end

-- ===== The ambient particles, one design a stat =====

local function attackPieces(body: BasePart, s: number, r: Rarity): { Piece }
	local A = C.Attack
	local e = newEmitter(body, C.SparkTexture)
	local size = A.Size * s * r.size
	e.Color = ColorSequence.new(Color3.fromHex(A.ColourA), Color3.fromHex(A.ColourB))
	e.LightEmission = 1
	e.Size = seq({ { 0, size * 0.3 }, { 0.25, size }, { 1, 0 } })
	e.Transparency = seq({ { 0, 1 }, { 0.15, r.alpha }, { 0.7, math.min(r.alpha + 0.15, 1) }, { 1, 1 } })
	e.Lifetime = NumberRange.new(A.LifeMin, A.LifeMax)
	e.Speed = NumberRange.new(A.SpeedMin * s, A.SpeedMax * s)
	e.Acceleration = Vector3.new(0, A.Rise * s, 0)
	e.SpreadAngle = Vector2.new(A.Spread, A.Spread)
	e.EmissionDirection = Enum.NormalId.Top
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	return { { emitter = e, rate = A.Rate * r.rate, wind = false } }
end

local function defencePieces(body: BasePart, s: number, r: Rarity): { Piece }
	local D = C.Defence
	local texture = iconUrl("defence")
	if texture == "" then
		return {}
	end
	local e = newEmitter(body, texture)
	local size = D.Size * s * r.size
	local peak = peakOf(D.Peak, r)
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.25
	e.Size = seq({ { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.85 } })
	e.Transparency = seq({ { 0, 1 }, { 0.3, peak }, { 0.7, peak }, { 1, 1 } })
	e.Lifetime = NumberRange.new(D.Life * 0.8, D.Life * 1.2)
	e.Speed = NumberRange.new(D.Drift * s * 0.5, D.Drift * s)
	e.Shape = Enum.ParticleEmitterShape.Sphere
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	e.LockedToPart = true
	e.ZOffset = 0.5
	return { { emitter = e, rate = D.Rate * r.rate, wind = false } }
end

-- Squashed along its flight, the soft puff reads as a streak.
local function styleStreak(e: ParticleEmitter)
	e.Texture = C.StreakTexture
	e.Color = ColorSequence.new(Color3.fromHex(C.Speed.Colour))
	e.LightEmission = 0.6
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.Squash = NumberSequence.new(C.Speed.Squash)
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
end

local function speedPieces(body: BasePart, s: number, r: Rarity): { Piece }
	local S = C.Speed
	local e = newEmitter(body, C.StreakTexture)
	styleStreak(e)
	local size = S.Size * s * r.size
	local peak = peakOf(S.Alpha, r)
	e.Size = seq({ { 0, size * 0.5 }, { 0.3, size }, { 1, size * 0.4 } })
	e.Transparency = seq({ { 0, 1 }, { 0.2, peak }, { 1, 1 } })
	e.Lifetime = NumberRange.new(S.LifeMin, S.LifeMax)
	e.Speed = NumberRange.new(S.SpeedMin * s, S.SpeedMax * s)
	-- thrown out of the slime's back (its front is -Z), left behind in the world
	e.EmissionDirection = Enum.NormalId.Back
	e.SpreadAngle = Vector2.new(12, 12)
	e.LockedToPart = false
	return { { emitter = e, rate = S.Rate * r.rate, wind = true } }
end

local function hpPieces(body: BasePart, s: number, r: Rarity): { Piece }
	local H = C.Hp
	local texture = iconUrl("hp")
	if texture == "" then
		return {}
	end
	local e = newEmitter(body, texture)
	local size = H.Size * s * r.size
	local peak = r.alpha * 0.6
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.1
	e.Size = seq({ { 0, size * 0.4 }, { 0.2, size }, { 1, size * 0.8 } })
	e.Transparency = seq({ { 0, 1 }, { 0.15, peak }, { 0.65, math.min(peak + 0.1, 1) }, { 1, 1 } })
	e.Lifetime = NumberRange.new(H.LifeMin, H.LifeMax)
	e.Speed = NumberRange.new(H.SpeedMin * s, H.SpeedMax * s)
	e.Acceleration = Vector3.new(0, 0.2 * s, 0)
	e.SpreadAngle = Vector2.new(H.Spread, H.Spread)
	e.EmissionDirection = Enum.NormalId.Top
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.Rotation = NumberRange.new(-20, 20)
	e.RotSpeed = NumberRange.new(-25, 25)
	return { { emitter = e, rate = H.Rate * r.rate, wind = false } }
end

local builders: { [string]: (BasePart, number, Rarity) -> { Piece } } = {
	attack = attackPieces,
	defence = defencePieces,
	speed = speedPieces,
	hp = hpPieces,
}

-- ===== The start burst, one design a stat =====

local function burstOf(stat: string, body: BasePart, s: number, r: Rarity): (ParticleEmitter?, number)
	if stat == "attack" then
		local A = C.Attack
		local e = newEmitter(body, C.SparkTexture)
		local size = A.BurstSize * s * r.size
		e.Color = ColorSequence.new(Color3.fromHex(A.ColourB), Color3.fromHex(A.ColourA))
		e.LightEmission = 1
		e.Size = seq({ { 0, size }, { 1, 0 } })
		e.Transparency = seq({ { 0, r.alpha * 0.5 }, { 1, 1 } })
		e.Lifetime = NumberRange.new(A.BurstLife * 0.7, A.BurstLife)
		e.Speed = NumberRange.new(A.BurstSpeedMin * s, A.BurstSpeedMax * s)
		e.Acceleration = Vector3.new(0, A.Rise * s, 0)
		e.Shape = Enum.ParticleEmitterShape.Sphere
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		e.Rotation = NumberRange.new(0, 360)
		return e, A.BurstCount
	elseif stat == "defence" then
		local D = C.Defence
		local texture = iconUrl("defence")
		if texture == "" then
			return nil, 0
		end
		local e = newEmitter(body, texture)
		local size = D.BurstSize * s * r.size
		e.Color = ColorSequence.new(Color3.new(1, 1, 1))
		e.LightEmission = 0.25
		e.Size = seq({ { 0, size * 0.4 }, { 1, size * 1.2 } })
		e.Transparency = seq({ { 0, 0.1 }, { 0.6, 0.3 }, { 1, 1 } })
		e.Lifetime = NumberRange.new(D.BurstLife * 0.8, D.BurstLife)
		e.Speed = NumberRange.new(D.BurstSpeed * s * 0.6, D.BurstSpeed * s)
		e.Shape = Enum.ParticleEmitterShape.Sphere
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		e.ZOffset = 0.5
		return e, D.BurstCount
	elseif stat == "speed" then
		local S = C.Speed
		local e = newEmitter(body, C.StreakTexture)
		styleStreak(e)
		local size = S.BurstSize * s * r.size
		e.Size = seq({ { 0, size }, { 1, size * 0.3 } })
		e.Transparency = seq({ { 0, 0.3 }, { 1, 1 } })
		e.Lifetime = NumberRange.new(S.BurstLife * 0.8, S.BurstLife)
		e.Speed = NumberRange.new(S.BurstSpeed * s * 0.7, S.BurstSpeed * s)
		e.Shape = Enum.ParticleEmitterShape.Sphere
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		return e, S.BurstCount
	end
	local H = C.Hp
	local texture = iconUrl("hp")
	if texture == "" then
		return nil, 0
	end
	local e = newEmitter(body, texture)
	local size = H.BurstSize * s * r.size
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.1
	e.Size = seq({ { 0, size * 0.5 }, { 0.3, size }, { 1, size * 0.7 } })
	e.Transparency = seq({ { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(H.BurstLife * 0.8, H.BurstLife)
	e.Speed = NumberRange.new(H.BurstSpeedMin * s, H.BurstSpeedMax * s)
	e.Acceleration = Vector3.new(0, -H.BurstFall * s, 0)
	e.SpreadAngle = Vector2.new(45, 45)
	e.EmissionDirection = Enum.NormalId.Top
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Rotation = NumberRange.new(-20, 20)
	e.RotSpeed = NumberRange.new(-40, 40)
	return e, H.BurstCount
end

local function playBurst(st: State, body: BasePart, tier: number)
	local r = rarityOf(st.rarity)
	local e, count = burstOf(st.stat, body, bodyScale(body), r)
	if not e then
		return
	end
	local share = if tier == 1 then C.LightShare else 1
	burstCount += 1
	liveBursts[e] = true
	e:Emit(math.max(1, math.floor(count * r.burst * share + 0.5)))
	task.delay(C.BurstLifeSeconds, function()
		if liveBursts[e] then
			liveBursts[e] = nil
			burstCount -= 1
			e:Destroy()
		end
	end)
end

-- ===== Letting go =====

local function dropFx(st: State)
	local fx = st.fx
	if not fx then
		return
	end
	st.fx = nil
	for _, piece in fx.pieces do
		piece.emitter.Enabled = false
		Debris:AddItem(piece.emitter, FADE_SECONDS)
	end
end

local function dropBadge(st: State)
	local badge = st.badge
	if not badge then
		return
	end
	st.badge = nil
	if badge.tween then
		badge.tween:Cancel()
	end
	badge.gui:Destroy()
end

local function removeState(st: State)
	for _, connection in st.connections do
		connection:Disconnect()
	end
	table.clear(st.connections)
	dropFx(st)
	dropBadge(st)
	live[st.config] = nil
	states[st.config] = nil
end

-- Undoes everything this script started: connections, badges, particles, bursts. Called when the script goes.
local function stop()
	running = false
	for _, st in states do
		removeState(st)
	end
	for e in liveBursts do
		e:Destroy()
	end
	table.clear(liveBursts)
	burstCount = 0
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

-- ===== The badge =====

local function buildBadge(st: State, body: BasePart, key: string): Badge
	local s = bodyScale(body)
	local rarities = Config.Food.Rarities :: any
	local entry = rarities[st.rarity] or rarities.common
	local gui = UiKit.make("BillboardGui", {
		Name = "BuffBadge",
		Adornee = body,
		Size = UDim2.fromOffset(B.Width, B.Height),
		-- (toward the viewer's left of where the emote pops up; camera space)
		StudsOffset = Vector3.new(-B.SideBody * s, B.LiftBody * s, 0),
		AlwaysOnTop = false,
		LightInfluence = 0,
		MaxDistance = C.BadgeStuds,
		Active = false,
	}, body)
	local pill = UiKit.make("Frame", {
		Name = "Pill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour("Cream"),
		BorderSizePixel = 0,
	}, gui)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
	UiKit.make("UIStroke", {
		Color = Color3.fromHex(entry.colour),
		Thickness = B.StrokePixels,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, pill)
	local scale = UiKit.make("UIScale", { Scale = 0 }, pill)
	UiKit.icon(pill, st.stat, B.IconPixels, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, BADGE_PAD, 0.5, 0),
	})
	local textLeft = BADGE_PAD + B.IconPixels + BADGE_GAP
	local label = UiKit.make("TextLabel", {
		Name = "Percent",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(textLeft, 0),
		Size = UDim2.new(1, -textLeft - BADGE_PAD + 1, 1, 0),
		Font = Enum.Font.FredokaOne,
		Text = string.format("+%d%%", math.floor(st.percent + 0.5)),
		TextColor3 = UiKit.colour("Brown"),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, pill)
	UiKit.make("UITextSizeConstraint", { MaxTextSize = B.TextSize }, label)
	local tween = TweenService:Create(
		scale,
		TweenInfo.new(B.PopSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = screenScale() }
	)
	tween:Play()
	return { key = key, body = body, gui = gui, scale = scale, tween = tween, popUntil = os.clock() + B.PopSeconds }
end

local function ensureBadge(st: State, body: BasePart)
	local key = table.concat({ st.stat, st.rarity, tostring(math.floor(st.percent + 0.5)) }, "|")
	local badge = st.badge
	if badge and (badge.body ~= body or badge.key ~= key or not badge.gui.Parent) then
		dropBadge(st)
		badge = nil
	end
	if not badge then
		st.badge = buildBadge(st, body, key)
	elseif os.clock() > badge.popUntil then
		-- the screen may have turned or resized
		local target = screenScale()
		if math.abs(badge.scale.Scale - target) > 0.01 then
			badge.scale.Scale = target
		end
	end
end

-- ===== The ambient particles, kept or rebuilt =====

local function ensureFx(st: State, body: BasePart, tier: number, now: number)
	local key = st.stat .. "|" .. st.rarity .. "|" .. tostring(tier)
	local fx = st.fx
	if fx and (fx.body ~= body or fx.key ~= key or not fx.body.Parent) then
		dropFx(st)
		fx = nil
	end
	local share = if tier == 1 then C.LightShare else 1
	if not fx then
		local build = builders[st.stat]
		if not build then
			return
		end
		local pieces = build(body, bodyScale(body), rarityOf(st.rarity))
		local made: Fx = { key = key, body = body, pieces = pieces, moving = false }
		for _, piece in pieces do
			piece.rate *= share
			piece.emitter.Rate = if piece.wind then piece.rate * C.Speed.IdleShare else piece.rate
		end
		st.fx = made
		fx = made
	end
	-- the speed streaks come thick while the slime travels and thin while it stands
	local moving = isMoving(st.config, now)
	if fx and fx.moving ~= moving then
		fx.moving = moving
		for _, piece in fx.pieces do
			if piece.wind then
				piece.emitter.Rate = if moving then piece.rate else piece.rate * C.Speed.IdleShare
			end
		end
	end
end

-- ===== The slow look at the live buffs =====

local function step()
	if not running then
		return
	end
	local now = workspace:GetServerTimeNow()
	local camera = workspace.CurrentCamera
	local actors = workspace:FindFirstChild("VillageClientActors")
	local tier = effectsTier()
	table.clear(candidates)
	for config, st in live do
		if st.untilTime <= now then
			-- the buff ran out: gone by itself, whether or not the server has said so yet
			live[config] = nil
			dropFx(st)
			dropBadge(st)
		else
			local model = if actors then actors:FindFirstChild(config.Name) else nil
			local body = if model then model:FindFirstChild("SlimeBody") else nil
			if camera and body and body:IsA("BasePart") then
				table.insert(candidates, {
					st = st,
					body = body,
					d = (body.Position - camera.CFrame.Position).Magnitude,
				})
			else
				-- no body drawn (far away, out on a squad): nothing to hang a buff on
				dropFx(st)
				dropBadge(st)
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.d < b.d
	end)
	local fxCount, badgeCount = 0, 0
	for _, c in candidates do
		local st = c.st
		local wantBadge = badgeCount < C.MaxBadges and c.d <= C.BadgeStuds * (if st.badge then C.ReleaseMargin else 1)
		if wantBadge then
			badgeCount += 1
			ensureBadge(st, c.body)
		else
			dropBadge(st)
		end
		local wantFx = tier > 0 and fxCount < C.MaxFx and c.d <= C.FxStuds * (if st.fx then C.ReleaseMargin else 1)
		if wantFx then
			fxCount += 1
			ensureFx(st, c.body, tier, now)
			if st.burstAt > 0 and burstCount < C.MaxBursts then
				st.burstAt = 0
				playBurst(st, c.body, tier)
			end
		else
			dropFx(st)
		end
		if st.burstAt > 0 and os.clock() - st.burstAt > C.BurstStaleSeconds then
			st.burstAt = 0
		end
	end
end

-- Look now (once, after the attributes of one change have all arrived), not at the next poll.
local function requestStep()
	if stepQueued then
		return
	end
	stepQueued = true
	task.defer(function()
		stepQueued = false
		step()
	end)
end

-- ===== Reading what the server published =====

local function read(st: State, announce: boolean)
	local config = st.config
	local statAttr, untilAttr = config:GetAttribute("BuffStat"), config:GetAttribute("BuffUntil")
	local percentAttr, rarityAttr = config:GetAttribute("BuffPercent"), config:GetAttribute("BuffRarity")
	local stat = if type(statAttr) == "string" and STATS[statAttr] then statAttr else ""
	local untilTime = if type(untilAttr) == "number" then untilAttr else 0
	local aliveNow = stat ~= "" and untilTime > workspace:GetServerTimeNow()
	-- BuffUntil went up while the buff lives: a dish was just eaten
	if announce and aliveNow and untilTime > st.untilTime + 0.5 then
		st.burstAt = os.clock()
	end
	st.stat = stat
	st.percent = if type(percentAttr) == "number" then percentAttr else 0
	st.rarity = if type(rarityAttr) == "string" and rarityAttr ~= "" then rarityAttr else "common"
	st.untilTime = untilTime
	if aliveNow then
		live[config] = st
		requestStep()
	else
		live[config] = nil
		dropFx(st)
		dropBadge(st)
	end
end

local function addSlime(inst: Instance)
	if not inst:IsA("Configuration") or states[inst] then
		return
	end
	local parent = inst.Parent
	if not parent or parent.Name ~= "Slimes" then
		return
	end
	local st: State = {
		config = inst,
		stat = "",
		percent = 0,
		rarity = "common",
		untilTime = 0,
		burstAt = 0,
		bornAt = os.clock(),
		readQueued = false,
		fx = nil,
		badge = nil,
		connections = {},
	}
	states[inst] = st
	for _, name in WATCHED do
		table.insert(
			st.connections,
			inst:GetAttributeChangedSignal(name):Connect(function()
				if st.readQueued then
					return
				end
				st.readQueued = true
				task.defer(function()
					st.readQueued = false
					if states[inst] == st then
						-- (attributes that arrive just after the slime does are its first state, not a dish eaten)
						read(st, os.clock() - st.bornAt > C.AnnounceAfterSeconds)
					end
				end)
			end)
		)
	end
	-- (what is already running when the slime appears is not announced with a burst)
	read(st, false)
end

local function removeSlime(inst: Instance)
	local st = states[inst :: Configuration]
	if st then
		removeState(st)
	end
end

-- ===== Start =====

task.spawn(function()
	local urls: { string } = {}
	for _, name in { "attack", "defence", "speed", "hp" } do
		local url = iconUrl(name)
		if url ~= "" then
			table.insert(urls, url)
		end
	end
	ContentProvider:PreloadAsync(urls)
end)

local villages = workspace:WaitForChild("Villages")
for _, inst in villages:GetDescendants() do
	addSlime(inst)
end
table.insert(connections, villages.DescendantAdded:Connect(addSlime))
table.insert(connections, villages.DescendantRemoving:Connect(removeSlime))
table.insert(connections, script.Destroying:Connect(stop))

task.spawn(function()
	while running do
		if next(live) ~= nil then
			step()
		end
		task.wait(C.PollSeconds)
	end
end)

print(Config.LogPrefix, "slime buff effects started")
