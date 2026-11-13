--!strict
-- The fight drawn. The server runs it (src/server/ZombieFights.luau) and sends Remotes.Fight events; this only draws them
-- on the bodies of the march (ZombieMarch stands the team's slimes at the end of the leg, facing the zombies). Every
-- fighter is its own slime (the owner, 2026-11-03): it winds up when its blow is announced ("aim"), lunges to the skin of
-- its target and holds there a beat, and its blow leaves the mark of its own way of fighting (a slime's role, a zombie's
-- kind; src/client/FightFx) with goo knocked out of the one hit, which is thrown back; a toxic zombie spits instead; a
-- dodge leaves after-images; a zombie that falls bursts on a ring with its coins, a slime that falls sees stars and fades;
-- a team that wins cheers. No camera effects: the player watches from outside. State follows the events even for a
-- fight far from the camera; bodies, bars and particles exist only while the group or the team is near. One error never
-- stops the drawing: per-fighter work is in pcall.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local FightFx = require(script.Parent.FightFx)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeWeapon = require(script.Parent.SlimeWeapon)
local UiKit = require(script.Parent.UiKit)
local UiTeams = require(script.Parent.UiTeams)
local VfxLib = require(ReplicatedStorage.Shared.VfxLib)
local ZombieLook = require(script.Parent.ZombieLook)
local ZombieMarch = require(script.Parent.ZombieMarch)
local ZombieTeams = require(script.Parent.ZombieTeams)
local ZombieWorld = require(script.Parent.ZombieWorld)

local V = Config.Zombies.View
local F = V.Fx

type Fighter = {
	id: string,
	fallen: boolean,
}
type Fight = {
	team: number,
	groupId: string,
	fighters: { [string]: Fighter },
	order: { string },
	roles: { [string]: string },
	-- the zombies of the group when the fight began (a group beaten or left is respawned with new ids at once)
	foes: { string },
	over: boolean,
	-- a camp fight's middle (the group's position, flat): its "move" events are flat from here
	centre: Vector3?,
}
type Bar = {
	gui: BillboardGui,
	fill: Frame,
	lag: Frame,
	node: Instance,
	connection: RBXScriptConnection,
}
-- A body somebody else stands on this field (the Slime Dungeon, client/DungeonFight: the squad and the monsters of the
-- arena), registered with ZombieFight.adopt so the same fight drawing works on it. `way` is the way it fights, `stand`
-- where it began, `foe` whether it is a monster, `node` where its Hp / MaxHp are read, `gone` runs when a monster has
-- fallen and burst away.
export type Extra = {
	actor: SlimeActor.Slime,
	stand: Vector3,
	foe: boolean,
	way: string,
	-- a Dungeon monster's own fight effects (Config.Dungeon.Fx.Monsters), drawn by VfxLib instead of its way's art
	fx: any?,
	size: number,
	dead: boolean,
	node: Instance,
	gone: (() -> ())?,
}
-- A move out from the standing place and back: reaches `delta` after `out` of `duration`, holds there `hold` seconds,
-- then comes back; or, when `stay`, a move to a new standing place (home + delta) over `duration`.
type Anim = {
	actor: SlimeActor.Slime,
	home: Vector3,
	delta: Vector3,
	start: number,
	duration: number,
	out: number,
	hold: number,
	stay: boolean,
	-- where the body was against `home` when this move began (a blow landing mid-knock): eased away over the move
	carry: Vector3,
}

local ZombieFight = {}
local fights: { [number]: Fight } = {}
local bars: { [string]: Bar } = {}
local anims: { Anim } = {}
local animLoop: RBXScriptConnection? = nil
local syncing = false
local numbersAlive = 0
local burstsAlive = 0
local warned: { [string]: boolean } = {}
-- The Slime Dungeon's bodies (see Extra) and the round field they fight on (nil outside it).
local extras: { [string]: Extra } = {}
local arena: { centre: Vector3, radius: number }? = nil
local dungeonHandler: ((events: { any }) -> ())? = nil
-- The fighters of a camp fight, fought by places as the Dungeon's (the server walks them; nothing here dashes or circles)
local placed: { [string]: boolean } = {}

-- Whether the server walks this fighter (the Dungeon's, the Arena's and a camp's: every fight since 2026-11-13).
local function byPlaces(id: string): boolean
	return extras[id] ~= nil or placed[id] == true
end

local function safe(label: string, work: () -> ())
	local ok, err = pcall(function(): any
		work()
		return nil
	end)
	if not ok and not warned[label] then
		warned[label] = true
		warn(Config.LogPrefix, "zombie fight", label, "error:", err)
	end
end

local function number(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if type(value) == "number" and value == value then value else default
end

-- ===== Floating numbers and coins =====

local function screenScale(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / 900, 0.7, 1.3) else 1
end

local function floatText(position: Vector3, text: string, colour: Color3, size: number)
	if numbersAlive >= V.MaxNumbers then
		return
	end
	numbersAlive += 1
	local jitter = Vector3.new((math.random() - 0.5) * 1.6, 0, (math.random() - 0.5) * 1.6)
	local anchor = FightFx.anchorAt(position + jitter)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, size + 16)
	gui.AlwaysOnTop = true
	gui.MaxDistance = Config.Zombies.DrawDistance
	gui.LightInfluence = 0
	gui.Adornee = anchor
	gui.Parent = anchor
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextSize = size
	label.TextColor3 = colour
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
	label.Parent = gui
	local info = TweenInfo.new(V.NumberSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = anchor.Position + Vector3.new(0, V.NumberRise, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(V.NumberSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(V.NumberSeconds + 0.1, function()
		numbersAlive -= 1
		anchor:Destroy()
	end)
end

-- The owner's coins thrown up out of a fallen zombie; never more than View.MaxBursts showers alive.
local function coinShower(position: Vector3, strength: number)
	local id = (Config.Ui.Icons :: any).coins
	if burstsAlive >= V.MaxBursts or type(id) ~= "number" or id <= 0 then
		return
	end
	burstsAlive += 1
	local anchor = FightFx.anchorAt(position)
	local coin = Instance.new("ParticleEmitter")
	coin.Texture = "rbxassetid://" .. tostring(id)
	coin.Rate = 0
	coin.LightInfluence = 0
	coin.Size = NumberSequence.new(V.Coin.size)
	coin.Lifetime = NumberRange.new(V.Coin.life)
	coin.Speed = NumberRange.new(V.Coin.speedMin, V.Coin.speedMax)
	coin.SpreadAngle = Vector2.new(35, 35)
	coin.EmissionDirection = Enum.NormalId.Top
	coin.Acceleration = Vector3.new(0, -V.Coin.gravity, 0)
	coin.Parent = anchor
	coin:Emit(math.floor(V.CoinBurst * strength))
	Debris:AddItem(anchor, V.BurstSeconds)
	task.delay(V.BurstSeconds, function()
		burstsAlive -= 1
	end)
end

-- ===== Motion =====

local function stopAnim(actor: SlimeActor.Slime)
	for index = #anims, 1, -1 do
		if anims[index].actor == actor then
			table.remove(anims, index)
		end
	end
end

local function shapeOf(anim: Anim, elapsed: number): number
	if anim.stay then
		local t = math.clamp(elapsed / anim.duration, 0, 1)
		return t * t * (3 - 2 * t)
	end
	local outSeconds = anim.duration * anim.out
	if elapsed < outSeconds then
		local t = elapsed / outSeconds
		return 1 - (1 - t) * (1 - t)
	elseif elapsed < outSeconds + anim.hold then
		return 1
	end
	local back = math.max(anim.duration - outSeconds, 1e-3)
	local t = math.clamp((elapsed - outSeconds - anim.hold) / back, 0, 1)
	return 1 - t * t * (3 - 2 * t)
end

-- The lunges, knock-backs and side-steps: out and back from the standing place, once.
local function stepAnims()
	local now = os.clock()
	for index = #anims, 1, -1 do
		local anim = anims[index]
		if anim.actor.destroyed then
			table.remove(anims, index)
		else
			local elapsed = now - anim.start
			safe("motion", function()
				local k = shapeOf(anim, elapsed)
				local t = math.clamp(elapsed / anim.duration, 0, 1)
				local carried = anim.carry * (1 - t * t * (3 - 2 * t))
				SlimeActor.setCFrame(
					anim.actor,
					CFrame.new(anim.home + anim.delta * k + carried) * anim.actor.root.Rotation
				)
			end)
			if elapsed >= anim.duration + anim.hold and anims[index] == anim then
				table.remove(anims, index)
			end
		end
	end
	if #anims == 0 and animLoop then
		animLoop:Disconnect()
		animLoop = nil
	end
end

-- Where each fighter stands now: it moves about the field during the fight (nil = where it began: the end of the march
-- or its place in the group), and whom it last went for (from the "aim" events).
local homes: { [string]: Vector3 } = {}
local targets: { [string]: string } = {}

-- The Slime Dungeon's walkers (ZombieFight.walk): a fighter that goes to a place the server picked, at the server's pace,
-- hopping on the way. Its `homes` entry follows it, so anything that starts from where it stands starts from where it is.
type Walk = {
	id: string,
	from: Vector3,
	to: Vector3,
	dir: Vector3,
	start: number,
	duration: number,
	length: number,
	hopAt: number,
}
local walks: { [SlimeActor.Slime]: Walk } = {}
local walkLoop: RBXScriptConnection? = nil

local function stepWalks()
	local now = os.clock()
	local P = Config.Dungeon.View
	for actor, walk in walks do
		if actor.destroyed then
			walks[actor] = nil
		else
			local t = math.clamp((now - walk.start) / walk.duration, 0, 1)
			local at = walk.from:Lerp(walk.to, t)
			homes[walk.id] = at
			safe("walk", function()
				SlimeActor.setCFrame(actor, CFrame.lookAt(at, at + walk.dir))
				if walk.length * t >= walk.hopAt then
					walk.hopAt += P.WalkHopStuds
					SlimeActor.hop(actor, P.WalkHop)
				end
			end)
			if t >= 1 then
				walks[actor] = nil
			end
		end
	end
	if next(walks) == nil and walkLoop then
		walkLoop:Disconnect()
		walkLoop = nil
	end
end

local function play(
	actor: SlimeActor.Slime,
	home: Vector3,
	delta: Vector3,
	seconds: number,
	out: number?,
	hold: number?,
	stay: boolean?
)
	-- A move cut short by another (blows landing faster than a knock-back comes back) starts from where the body is and
	-- comes back to where it stood, never from the half-way place: knock-backs that added up walked a boss away.
	local carry = Vector3.zero
	for _, running in anims do
		if running.actor == actor and not running.stay then
			home = running.home
			local off = actor.root.Position - home
			carry = Vector3.new(off.X, 0, off.Z)
		end
	end
	stopAnim(actor)
	-- (a lunge or a knock-back takes the body over from its walk; the next "move" from the server sets it going again)
	walks[actor] = nil
	table.insert(anims, {
		actor = actor,
		home = home,
		delta = delta,
		start = os.clock(),
		duration = seconds,
		out = out or 0.5,
		hold = hold or 0,
		stay = stay == true,
		carry = carry,
	})
	if not animLoop then
		animLoop = RunService.RenderStepped:Connect(stepAnims)
	end
end

-- ===== Who is who =====

local function fightOf(id: string): Fight?
	for _, fight in fights do
		if fight.fighters[id] then
			return fight
		end
	end
	return nil
end

-- The body and the standing place of a fighter (a body of the march) or a zombie by its id; the last is whether it is a
-- zombie (a zombie id never matches a slime of a team).
local function find(id: string): (SlimeActor.Slime?, Vector3?, boolean)
	local extra = extras[id]
	if extra then
		-- (a Dungeon fighter moves all the time: where its body really is, so nothing ever starts from somewhere else)
		local base = homes[id] or extra.stand
		local at = extra.actor.root.Position
		return extra.actor, Vector3.new(at.X, base.Y, at.Z), extra.foe
	end
	if fightOf(id) then
		local body = ZombieMarch.body(id)
		if body then
			return body.actor, homes[id] or body.stand, false
		end
		return nil, nil, false
	end
	local zombie = ZombieWorld.zombie(id)
	if zombie then
		return zombie.actor, homes[id] or zombie.spot, true
	end
	return nil, nil, true
end

-- Where a fighter began (its side of the field): the end of the march, or its place in the group.
local function anchorOf(id: string): Vector3?
	local extra = extras[id]
	if extra then
		return extra.stand
	end
	if fightOf(id) then
		local body = ZombieMarch.body(id)
		return if body then body.stand else nil
	end
	local zombie = ZombieWorld.zombie(id)
	return if zombie then zombie.spot else nil
end

-- A fighter's way of fighting: a slime's role, a zombie's kind.
local function wayOf(id: string): string
	local extra = extras[id]
	if extra then
		return extra.way
	end
	local fight = fightOf(id)
	if fight then
		return fight.roles[id] or "attack"
	end
	local zombie = ZombieWorld.zombie(id)
	return if zombie then zombie.kind else "rotten"
end

-- How a fighter's blows look.
local function styleOf(id: string): FightFx.Style
	return FightFx.style(wayOf(id))
end

-- A Dungeon monster's own fight effects (Config.Dungeon.Fx.Monsters), or nil: everyone else keeps its way's art.
local DFx = Config.Dungeon.Fx
local charges: { [string]: any } = {}

local function fxOf(id: string?): any
	local extra = if id then extras[id] else nil
	return if extra then extra.fx else nil
end

-- The art of the special an event struck: the monster's `skills[key]` (a mini-boss or boss has several, a regular one),
-- or its one `skill`; nil for a plain blow or a monster without.
local function specialOf(fx: any, event: { [string]: any }): any
	if not fx or type(event.skill) ~= "string" then
		return nil
	end
	return if fx.skills then fx.skills[event.skill] else fx.skill
end

local function fxScale(id: string?): number
	local extra = if id then extras[id] else nil
	return math.clamp((if extra then extra.size else 1) * DFx.Scale, 1, DFx.MaxScale)
end

-- Plays one library effect, never letting a broken one stop the fight.
local function vfx(effect: string?, at: any, opts: { [string]: any }?): any
	if not effect then
		return nil
	end
	local ok, live = pcall(VfxLib.play, effect, at, opts)
	if not ok then
		if not warned[effect] then
			warned[effect] = true
			warn("[GooLineage] fight effect " .. effect .. ": " .. tostring(live))
		end
		return nil
	end
	return live
end

-- ===== A boss's burst (DFx.Burst): the mark under where it comes down, the body's glow, the flash of what it strikes =====

local marks: { [string]: any } = {}
local glows: { [string]: Highlight } = {}

-- A tint over a body (no outline, hidden behind walls).
local function tint(model: Instance, colour: Color3, fill: number): Highlight
	local glow = Instance.new("Highlight")
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.FillColor = colour
	glow.FillTransparency = fill
	glow.OutlineTransparency = 1
	glow.Parent = model
	return glow
end

local function fadeTint(glow: Highlight)
	local seconds = DFx.Burst.FlashSeconds
	TweenService:Create(glow, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
	}):Play()
	Debris:AddItem(glow, seconds + 0.1)
end

-- A skill's wind-up ends: it went off (`fired`: a boss's body flashes as it lets go), or its caster fell.
local function endCharge(id: string, fired: boolean?)
	local live, mark, glow = charges[id], marks[id], glows[id]
	charges[id], marks[id], glows[id] = nil, nil, nil
	if live then
		pcall(VfxLib.cancel, live, DFx.WindupFade)
	end
	if mark then
		pcall(VfxLib.cancel, mark, DFx.WindupFade)
	end
	if glow then
		if fired then
			glow.FillColor = glow.FillColor:Lerp(Color3.new(1, 1, 1), 0.5)
			glow.FillTransparency = DFx.Burst.FlashFill
		end
		fadeTint(glow)
	end
end

local function flat(delta: Vector3): Vector3
	return Vector3.new(delta.X, 0, delta.Z)
end

local function along(delta: Vector3, fallback: Vector3): Vector3
	local line = flat(delta)
	return if line.Magnitude > 1e-3 then line.Unit else flat(fallback).Unit
end

local function radius(actor: SlimeActor.Slime): number
	return actor.body.Size.X / 2
end

-- A fixed number in 0..1 for a fighter (its own angle round a target, the same every time).
local function hash(id: string): number
	local h = 0
	for index = 1, #id do
		h = (h * 31 + string.byte(id, index)) % 100003
	end
	return h / 100003
end

-- ===== Moving about the field =====

-- The ground under a place on the field: in the Dungeon's arena the flat floor at the arena's height, kept inside its
-- rim; elsewhere the map's ground.
local function groundFor(point: Vector3): Vector3
	local field = arena
	if not field then
		return ZombieWorld.groundOnMap(point.X, point.Z)
	end
	local offset = flat(point - field.centre)
	local limit = field.radius - Config.Dungeon.View.EdgeMargin
	if offset.Magnitude > limit then
		offset = offset.Unit * limit
	end
	return Vector3.new(field.centre.X + offset.X, field.centre.Y, field.centre.Z + offset.Z)
end

-- The fighter hops to a new standing place, turned to `faceAt`.
local function moveTo(
	id: string,
	actor: SlimeActor.Slime,
	from: Vector3,
	to: Vector3,
	faceAt: Vector3,
	seconds: number?
)
	local M = V.Moves
	local distance = flat(to - from).Magnitude
	if distance < M.MinStuds then
		return
	end
	local spot = groundFor(to)
	local time = seconds or math.clamp(distance / M.Speed, M.MinSeconds, M.MaxSeconds)
	homes[id] = spot
	local look = along(faceAt - from, actor.root.LookVector)
	SlimeActor.setCFrame(actor, CFrame.lookAt(from, from + look))
	SlimeActor.hop(actor, M.Hop)
	if time <= M.DashSeconds then
		FightFx.afterImages(actor.body, spot - from)
	end
	play(actor, from, spot - from, time, nil, nil, true)
end

-- The guard's place: between its most hurt team-mate and the foe it faces.
local function guardSpot(id: string, actor: SlimeActor.Slime, foeAt: Vector3): Vector3?
	local fight = fightOf(id)
	local team = if fight then ZombieTeams.get(fight.team) else nil
	if not fight or not (team or extras[id]) then
		return nil
	end
	local weakest: string? = nil
	local lowest = 1
	for _, other in fight.order do
		local extra = extras[other]
		local node = if extra then extra.node elseif team then team.node:FindFirstChild(other) else nil
		if other ~= id and node and not fight.fighters[other].fallen then
			local share = number(node, "Hp", 1) / math.max(number(node, "MaxHp", 1), 1)
			if share < lowest then
				weakest, lowest = other, share
			end
		end
	end
	if not weakest then
		return nil
	end
	local ally, allyAt = find(weakest)
	if not ally or not allyAt then
		return nil
	end
	return allyAt + along(foeAt - allyAt, actor.root.LookVector) * (radius(ally) + radius(actor) + V.Moves.Gap)
end

-- The fight a fighter is in: as a slime of the team or a zombie of the group.
local function fightAround(id: string): Fight?
	local fight = fightOf(id)
	if fight then
		return fight
	end
	local extra = extras[id]
	if extra and extra.foe then
		return fights[0]
	end
	for _, each in fights do
		local group = ZombieWorld.group(each.groupId)
		if group and group.byId[id] then
			return each
		end
	end
	return nil
end

-- `spot` moved off every other fighter of the fight, slimes and zombies alike, where they stand or are going (each
-- keeps Gap studs of air round it), in a few passes, as one push can land on another.
local function apart(id: string, actor: SlimeActor.Slime, spot: Vector3): Vector3
	local fight = fightAround(id)
	if not fight then
		return spot
	end
	-- (not its own target: the place is already outside it, and a push off it would carry the fighter out of reach)
	local targetId = targets[id]
	local others: { string } = {}
	for _, other in fight.order do
		if other ~= id and other ~= targetId and not fight.fighters[other].fallen then
			table.insert(others, other)
		end
	end
	local group = ZombieWorld.group(fight.groupId)
	if group then
		for other in group.byId do
			if other ~= id and other ~= targetId and not ZombieWorld.isDead(other) then
				table.insert(others, other)
			end
		end
	end
	if fight.team == 0 then
		-- (the Dungeon's monsters)
		for other, extra in extras do
			if extra.foe and other ~= id and other ~= targetId and not extra.dead then
				table.insert(others, other)
			end
		end
	end
	local look = actor.root.LookVector
	local across = Vector3.new(-look.Z, 0, look.X)
	for _ = 1, V.Moves.Passes do
		local moved = false
		for _, other in others do
			local body, at = find(other)
			if body and at then
				local need = radius(actor) + radius(body) + V.Moves.Gap
				local gap = flat(spot - at)
				if gap.Magnitude < need then
					spot += along(gap, across) * (need - gap.Magnitude)
					moved = true
				end
			end
		end
		if not moved then
			break
		end
	end
	return spot
end

-- Where a fighter wants to stand against its target: on its own side, at its own angle round the target (a fast one
-- circles to a new flank each time), as far as its way of fighting keeps; a guard covers its most hurt team-mate. Not on
-- top of another fighter.
local function spotFor(id: string, actor: SlimeActor.Slime, targetId: string): (Vector3?, Vector3?)
	local M = V.Moves
	local target, at = find(targetId)
	local anchor = anchorOf(id)
	if not target or not at or not anchor then
		return nil, nil
	end
	local way = wayOf(id)
	if way == "defence" then
		local guard = guardSpot(id, actor, at)
		if guard then
			return apart(id, actor, guard), at
		end
	end
	local spread = (M.Spread :: any)[way] or 30
	local angle = if way == "speed" then (math.random() * 2 - 1) * spread else (hash(id) * 2 - 1) * spread
	local side = CFrame.Angles(0, math.rad(angle), 0):VectorToWorldSpace(along(anchor - at, -target.root.LookVector))
	local keep = ((M.Stand :: any)[way] or 0.4) * actor.body.Size.X
	return apart(id, actor, at + side * (radius(target) + radius(actor) + M.Gap + keep)), at
end

-- After its blow (or before one it cannot reach) a fighter takes its place against its target.
local function reposition(id: string, seconds: number?)
	local targetId = targets[id]
	local actor, home = find(id)
	local extra = extras[id]
	local gone = if extra then extra.dead else ZombieWorld.isDead(id)
	if not targetId or not actor or not home or actor.destroyed or gone then
		return
	end
	local fight = fightOf(id)
	if fight and (fight.over or fight.fighters[id].fallen) then
		return
	end
	if extra and extra.foe and (not fights[0] or fights[0].over) then
		return
	end
	local spot, at = spotFor(id, actor, targetId)
	if spot and at then
		moveTo(id, actor, home, spot, at, seconds)
	end
end

-- How long after its event a blow reaches its target: a spit flies, a lunge reaches the skin.
local function contactSeconds(style: FightFx.Style): number
	return if style.shot then F.ShotSeconds else V.LungeSeconds * V.ContactShare
end

-- The skill an event belongs to (Config.Combat.Skills), or nil for a plain blow.
local function skillOf(event: { [string]: any }): any
	return if type(event.skill) == "string" then (Config.Combat.Skills :: any)[event.skill] else nil
end

-- The element of a boss's burst (DFx.Burst): a special with a `windup` and wind-up art of its own, struck by a monster
-- with an `element`; nil for any other blow.
local function burstOf(event: { [string]: any }): string?
	local s = skillOf(event)
	local fx = fxOf(event.from)
	local special = specialOf(fx, event)
	return if s and s.windup and fx and fx.element and special and special.windup then fx.element else nil
end

-- The element of a regular monster's pop (DFx.Pop): a special with a `windup` but no wind-up art; nil otherwise.
local function popOf(event: { [string]: any }): string?
	local s = skillOf(event)
	local fx = fxOf(event.from)
	return if s and s.windup and fx and fx.element and not burstOf(event) then fx.element else nil
end

-- The pop's own blow: the first one on the fighter it was aimed at (not a splash, not a later hit of a flurry).
local function popHit(event: { [string]: any }): string?
	local pop = popOf(event)
	return if pop and event.splash ~= true and (type(event.n) ~= "number" or event.n <= 1) then pop else nil
end

-- A blow that lands hard (View.Hard): a crit, or the heavy blow of a slime's or a zombie's skill (not a splash, not one
-- of a flurry). A Dungeon monster's burst and pop have their own.
local function hardOf(event: { [string]: any }): boolean
	local s = skillOf(event)
	return event.crit == true or (s ~= nil and s.kind ~= "multi" and event.splash ~= true and not fxOf(event.from))
end

-- A slime's or a zombie's skill goes off (View.Skill.Power): its body flashes its way's colour, out of the glow of its
-- wind-up when it had one. A Dungeon monster keeps its own.
local function letGo(id: string)
	local colour = (V.Skill.Power.Glow :: any)[wayOf(id)]
	local actor = find(id)
	if fxOf(id) or not colour or not actor then
		return
	end
	if not glows[id] then
		glows[id] = tint(actor.model, Color3.fromHex(colour), 1)
	end
	endCharge(id, true)
end

-- A library effect standing on the floor at `at`: its box is as tall as the body there (its ground pieces lie on the
-- floor, its body ones at that body's middle), as the monsters' are played.
local function onFloor(effect: string?, at: Vector3, tall: number, scale: number?, variant: string?)
	local wide = 5 * (scale or 1)
	return vfx(effect, at + Vector3.new(0, tall * 0.5, 0), {
		scale = scale,
		variant = variant,
		size = Vector3.new(wide, tall, wide),
	})
end

-- How a skill looks (View.Skill.Looks).
local function looksOf(event: { [string]: any }): { [string]: any }
	return (V.Skill.Looks :: any)[event.skill] or {}
end

-- A weapon class's skill the VFX library draws (its look's `vfx`), or nil: a Dungeon monster keeps its own art.
local function libraryLook(event: { [string]: any }): { [string]: any }?
	local look = looksOf(event)
	return if look.vfx and not fxOf(event.from) then look else nil
end

-- A library skill's level and size for its caster: its weapon's tier (Common's with none in hand).
local function levelOf(caster: SlimeActor.Slime?): (string, number)
	local tier = (if caster then SlimeWeapon.tierOf(caster.model) else nil) or "wood"
	return (V.Skill.Levels :: any)[tier] or "lv1", (V.Skill.TierScale :: any)[tier] or 1
end

-- How long after it is played a library skill's blow lands: its `impact` marker at that level.
local function landingOf(look: { [string]: any }, level: string): number
	local effect = VfxLib.get(look.vfx)
	local variant = if effect and effect.variants then effect.variants[level] else nil
	local markers = (variant and variant.markers) or (effect and effect.markers) or {}
	return markers[look.impact] or F.ShotSeconds
end

-- A library skill played on a body: at its middle, in a box as tall as it (its ground pieces lie on the floor), thrown
-- from `source` when it has a flight.
local function playOn(
	look: { [string]: any },
	level: string,
	scale: number,
	body: SlimeActor.Slime,
	at: Vector3,
	source: Vector3?
)
	local tall = body.body.Size.Y
	local wide = 5 * scale
	return vfx(look.vfx, at + Vector3.new(0, tall * 0.5, 0), {
		variant = level,
		scale = scale,
		from = source,
		size = Vector3.new(wide, tall, wide),
	})
end

-- When a skill played from its aim (Dash Strike's dash) lands, by its caster: its blow waits for it.
local leads: { [string]: number } = {}

-- A piercing skill's arrow (its look's `pierce`), by its caster: everyone its batch strikes, and the farthest of them,
-- where the arrow is aimed and its own hit plays (the others get the mark of the blow as it passes).
local lines: { [string]: { string } } = {}
local aims: { [string]: string } = {}

-- ===== Health bars =====

local function dropBar(id: string)
	local bar = bars[id]
	if bar then
		bar.connection:Disconnect()
		bar.gui:Destroy()
		bars[id] = nil
	end
end

local function showBar(id: string, actor: SlimeActor.Slime, node: Instance, ours: boolean)
	local bar = bars[id]
	if bar and bar.gui.Adornee == actor.body then
		return
	end
	dropBar(id)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HpBar"
	gui.Adornee = actor.body
	gui.Size = UDim2.fromOffset(V.BarWidth, V.BarHeight)
	gui.StudsOffset = Vector3.new(0, SlimeActor.topOffset(actor) + V.BarLift, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = V.BarDistance
	gui.LightInfluence = 0
	gui.Parent = actor.body
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local track = UiKit.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
	}, gui)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
	-- the health just lost shows white a moment, then drains after the bar
	local lag = UiKit.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, track)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, lag)
	local fill = UiKit.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour(if ours then "Green" else "Red"),
		BorderSizePixel = 0,
	}, track)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	local function share(): number
		local maxHp = math.max(number(node, "MaxHp", 1), 1)
		return math.clamp(number(node, "Hp", maxHp) / maxHp, 0, 1)
	end
	fill.Size = UDim2.fromScale(share(), 1)
	lag.Size = fill.Size
	local function update()
		local size = UDim2.fromScale(share(), 1)
		fill.Size = size
		task.delay(V.BarLagSeconds, function()
			if lag.Parent then
				TweenService:Create(lag, TweenInfo.new(V.BarDrainSeconds), { Size = fill.Size }):Play()
			end
		end)
	end
	bars[id] = {
		gui = gui,
		fill = fill,
		lag = lag,
		node = node,
		connection = node:GetAttributeChangedSignal("Hp"):Connect(update),
	}
end

-- Bars follow the bodies: drawn while the team or the group is near, gone when it is not (the fight itself goes on).
local function sync(fight: Fight)
	if fight.team == 0 then
		-- (the Dungeon: every body is registered, there is no march or camp to look up)
		for id, extra in extras do
			safe("sync " .. id, function()
				local fighter = fight.fighters[id]
				local standing = if extra.foe then not extra.dead else fighter ~= nil and not fighter.fallen
				if not fight.over and standing and not extra.actor.destroyed then
					showBar(id, extra.actor, extra.node, not extra.foe)
				else
					dropBar(id)
				end
			end)
		end
		return
	end
	local group = ZombieWorld.group(fight.groupId)
	local team = ZombieTeams.get(fight.team)
	for _, id in fight.order do
		local fighter = fight.fighters[id]
		if fighter then
			safe("sync " .. id, function()
				local body = ZombieMarch.body(id)
				local node = if team then team.node:FindFirstChild(id) else nil
				if not fight.over and not fighter.fallen and body and node and node:IsA("Configuration") then
					showBar(id, body.actor, node, true)
				else
					dropBar(id)
				end
			end)
		end
	end
	if group then
		for id, entry in group.byId do
			safe("sync " .. id, function()
				if group.drawn and not fight.over and entry.actor and not ZombieWorld.isDead(id) then
					showBar(id, entry.actor, entry.config, false)
				else
					dropBar(id)
				end
			end)
		end
	end
end

local function syncLoop()
	if syncing then
		return
	end
	syncing = true
	task.spawn(function()
		while next(fights) ~= nil do
			for _, fight in fights do
				sync(fight)
			end
			task.wait(V.SyncSeconds)
		end
		syncing = false
	end)
end

-- ===== Events =====

local function onStart(teamIndex: number, event: { [string]: any })
	local members: { string } = event.members
	local roles = if type(event.roles) == "table" then event.roles else {}
	local fight: Fight =
		{ team = teamIndex, groupId = event.group, fighters = {}, order = {}, roles = roles, foes = {}, over = false }
	local group = ZombieWorld.group(event.group)
	if group then
		for id in group.byId do
			table.insert(fight.foes, id)
		end
	end
	fights[teamIndex] = fight
	for _, id in members do
		fight.fighters[id] = { id = id, fallen = false }
		table.insert(fight.order, id)
	end
	for _, id in members do
		-- (the fighters stand where the march ended before the first move is worked out from their places)
		homes[id], targets[id] = nil, nil
		ZombieMarch.settle(id)
	end
	-- a fight by places (every camp fight since 2026-11-13): each body goes to the place it starts from (the team is
	-- there already, at the end of its march; a zombie that had roamed off walks back to its ring)
	local centre = event.centre
	if type(centre) == "table" and type(centre[1]) == "number" and type(centre[2]) == "number" then
		fight.centre = Vector3.new(centre[1], 0, centre[2])
		local middle = fight.centre :: Vector3
		for id, spot in (if type(event.spots) == "table" then event.spots else {}) :: { [string]: any } do
			if type(id) == "string" and type(spot) == "table" and type(spot[1]) == "number" then
				placed[id] = true
				ZombieFight.walk(id, Vector3.new(middle.X + spot[1], 0, middle.Z + spot[2]), 0)
			end
		end
	end
	sync(fight)
	syncLoop()
end

-- A camp fighter walks (a "move" event, flat from the fight's middle); the Dungeon's and the Arena's walk through
-- client/DungeonFight and client/ArenaReplay, which know their fields.
local function onMove(teamIndex: number, event: { [string]: any })
	local fight = fights[teamIndex]
	local centre = if fight then fight.centre else nil
	if
		centre
		and type(event.from) == "string"
		and type(event.tx) == "number"
		and type(event.tz) == "number"
		and type(event.seconds) == "number"
	then
		ZombieFight.walk(event.from, Vector3.new(centre.X + event.tx, 0, centre.Z + event.tz), event.seconds)
	end
end

-- A blow is coming: the attacker turns to its target and winds up (a squash; a spitter puffs up). One too far to reach
-- its target dashes in first (its blow lands at the end of the wind-up).
local function onAim(event: { [string]: any })
	targets[event.from] = event.to
	local attacker, from = find(event.from)
	local target, to = find(event.to)
	if not attacker or not from or not target or not to then
		return
	end
	local s = skillOf(event)
	local deeper = if s then V.Skill.Windup else 1
	local fx = fxOf(event.from)
	local special = specialOf(fx, event)
	local windup = if s and s.windup then s.windup else Config.Combat.WindupSeconds
	local burst, pop = burstOf(event), popOf(event)
	if s and (special or pop) then
		endCharge(event.from)
	end
	local drawn = if s then libraryLook(event) else nil
	if drawn and drawn.aim then
		-- (Dash Strike: the library's streak flies along the dash from where it starts; its blow lands on the marker)
		local level, scale = levelOf(attacker)
		playOn(drawn, level, scale, target, to, from + Vector3.new(0, attacker.body.Size.Y * 0.5, 0))
		leads[event.from] = os.clock() + landingOf(drawn, level)
	end
	if s and special then
		-- (an effect without that variant plays as it is: one variant name serves the wind-up and the release; the
		-- wind-up is drawn as big as the release, or a big monster's body hides it)
		charges[event.from] = vfx(
			special.windup,
			attacker.model,
			{ follow = true, variant = special.variant, scale = fxScale(event.from) }
		)
	end
	if burst and special then
		-- a boss's burst: the ground marked where it comes down (as wide as its release there)
		local scale = fxScale(event.from)
		local wide = 5 * scale
		if special.at == "target" then
			local tall = target.body.Size.Y
			marks[event.from] = vfx("skill.monster_mark", to + Vector3.new(0, tall * 0.5, 0), {
				variant = burst,
				scale = scale,
				size = Vector3.new(wide, tall, wide),
			})
		else
			local tall = attacker.body.Size.Y
			marks[event.from] = vfx("skill.monster_mark", from + Vector3.new(0, tall * 0.5, 0), {
				variant = burst,
				scale = scale * DFx.Burst.MarkWide,
				size = Vector3.new(wide, tall, wide),
			})
		end
	end
	local element = burst or pop
	if element then
		-- a burst's or a pop's body glowing its element as it winds up (a pop's softer)
		local glow = tint(attacker.model, Color3.fromHex(DFx.Burst.Glow[element] or "#ffffff"), 1)
		glows[event.from] = glow
		TweenService:Create(glow, TweenInfo.new(windup, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			FillTransparency = if burst then DFx.Burst.GlowMost else DFx.Pop.GlowMost,
		}):Play()
	end
	local power = if s and not fx then (V.Skill.Power.Glow :: any)[wayOf(event.from)] else nil
	if power then
		-- a slime's or a zombie's skill: its body glows its way's colour through the wind-up (letGo flashes it as the
		-- skill goes off; a skill that never does, its target gone, lets the glow go a moment later)
		endCharge(event.from)
		local glow = tint(attacker.model, Color3.fromHex(power), 1)
		glows[event.from] = glow
		TweenService:Create(glow, TweenInfo.new(windup, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			FillTransparency = V.Skill.Power.GlowMost,
		}):Play()
		task.delay(windup + 1, function()
			if glows[event.from] == glow then
				endCharge(event.from)
			end
		end)
	end
	if s then
		floatText(
			from + Vector3.new(0, attacker.body.Size.Y + 1.5, 0),
			s.name,
			Color3.fromHex(V.Skill.Colour),
			V.Skill.TextSize
		)
	end
	-- (a skill that strikes everyone is struck from where its caster stands)
	local gap = flat(to - from).Magnitude - radius(attacker) - radius(target)
	local shot = styleOf(event.from).shot ~= nil
	local reaching = not (s and s.kind == "all")
	-- (a monster slime plays its own attack, timed so its blow lands as the wind-up and the lunge end: a boss's long
	-- wind-up waits for its start)
	local peak = SlimeActor.attackPeak(attacker)
	if peak then
		local lead = windup + (if shot then 0 else V.LungeSeconds * V.ContactShare)
		if lead > peak then
			task.delay(lead - peak, function()
				if not attacker.destroyed then
					SlimeActor.act(attacker, "Attack", 0)
				end
			end)
		else
			SlimeActor.act(attacker, "Attack", peak - lead)
		end
	end
	-- (a slime with a weapon in hand moves it too: the swing, the draw, the cast, timed so its blow meets the strike)
	if SlimeWeapon.familyOf(attacker.model) then
		SlimeWeapon.cue(attacker.model, s ~= nil, windup + (if shot then 0 else V.LungeSeconds * V.ContactShare))
	end
	-- (where the server walks the fighters it announces a blow only once its fighter is in reach: no dash)
	if
		not byPlaces(event.from)
		and reaching
		and ((not shot and gap > V.Moves.Reach) or (shot and gap < V.Moves.TooClose))
	then
		reposition(event.from, windup * 0.8)
		return
	end
	local look = along(to - from, attacker.root.LookVector)
	SlimeActor.setCFrame(attacker, CFrame.lookAt(attacker.root.Position, attacker.root.Position + look))
	if shot or (s and s.kind == "all") then
		SlimeActor.kick(attacker, "puff", V.WindupPuff * deeper)
	else
		SlimeActor.kick(attacker, "squash", V.WindupSquash * deeper)
	end
end

-- The blow reaches the target: its mark, the goo, the knock-back, the number. A skill's heavy blow (not a splash, not one
-- of Dash Strike's quick ones) hits like a crit; a blow a guard took for a team-mate flashes on the guard.
local function impact(event: { [string]: any }, style: FightFx.Style)
	local target, to, foe = find(event.to)
	if not target or not to then
		return
	end
	local attacker, from = find(event.from)
	local crit = event.crit == true
	local s = skillOf(event)
	local heavy = crit or (s ~= nil and s.kind ~= "multi" and event.splash ~= true)
	local hard = hardOf(event)
	local dir = along(to - (from or to - target.root.LookVector), -target.root.LookVector)
	local height = target.body.Size.Y
	local skin = to - dir * radius(target) * 0.8 + Vector3.new(0, height * 0.5, 0)
	local fx = fxOf(event.from)
	-- (a boss's burst strikes harder: the body freezes longer and flashes white; a regular's pop a little less)
	local burst = burstOf(event)
	local pop = popHit(event)
	if fx and fx.blow then
		-- (a Dungeon monster's own blow; a ranged one's came with its shot, in strike)
		if not (fx.shot and style.shot) then
			vfx(fx.blow, skin, {
				scale = fxScale(event.from),
				variant = if s then DFx.SkillVariant else nil,
				angle = math.random(-25, 25),
			})
		end
	elseif not (s and looksOf(event).ownHit) or (looksOf(event).pierce and aims[event.from] ~= event.to) then
		-- (a class skill the library draws brings its own hit; a piercing arrow's only where it is aimed)
		FightFx.mark(style, skin, skin - dir * 3, heavy)
		local family = if attacker and not s then SlimeWeapon.familyOf(attacker.model) else nil
		if attacker and family then
			-- (a plain blow of a held weapon: its family's own impact at its tier, along the blow, sized to the one
			-- struck; the higher tiers' floor pieces lie at its feet)
			local W = Config.Weapons.Fx
			vfx(W.Hit .. family, CFrame.lookAt(skin, skin + dir), {
				variant = SlimeWeapon.tierOf(attacker.model),
				scale = height / W.HitHeight,
				ground = to.Y,
			})
		end
		local own = if crit then (F.CritLooks :: any)[wayOf(event.from)] else nil
		if own then
			-- (a weapon class's crit: its own library burst over the mark, facing along the blow, bigger by the tier)
			local _, scale = levelOf(attacker)
			vfx(own.vfx, CFrame.lookAt(skin, skin + dir), { variant = own.variant, scale = scale * (own.scale or 1) })
		end
	end
	if pop then
		-- (its box is the body it strikes, standing on the floor: the ring lies there)
		local wide = 5 * fxScale(event.from)
		vfx("hit.monster_pop", to + Vector3.new(0, height * 0.5, 0), {
			variant = pop,
			scale = fxScale(event.from),
			size = Vector3.new(wide, height, wide),
		})
	end
	FightFx.goo(target.body, skin, dir, if heavy then F.Goo.count * 2 else F.Goo.count)
	SlimeActor.act(target, "Hit")
	local stop = if burst
		then DFx.Burst.HitStopSeconds
		elseif pop then DFx.Pop.HitStopSeconds
		elseif hard then V.Hard.HitStopSeconds
		else V.HitStopSeconds
	-- (a big body is heavy: a boss hardly moves)
	local weight = math.max(1, if extras[event.to] then extras[event.to].size else 1) ^ V.KnockWeight
	play(target, to, dir * V.KnockStuds * (if heavy then V.CritKnock else 1) / weight, V.KnockSeconds, 0.2, stop)
	if burst or pop or hard then
		local flash = if burst then DFx.Burst.HitFlash elseif pop then DFx.Pop.HitFlash else V.Hard.HitFlash
		fadeTint(tint(target.model, Color3.new(1, 1, 1), flash))
	end
	local side = if math.random() < 0.5 then -1 else 1
	SlimeActor.kick(target, "side", side * V.FlinchSide * (if heavy then 2 else 1))
	SlimeActor.kick(target, "squash", V.FlinchSquash * (if heavy then 2 else 1))
	if type(event.guard) == "string" and not fxOf(event.guard) then
		local guard = V.Skill.Looks.defence
		FightFx.burst(guard.burst, skin, V.Skill.Burst * 0.5, nil)
	end
	local colours = V.NumberColours
	local hit = math.max(1, math.floor((event.amount or 0) + 0.5))
	floatText(
		to + Vector3.new(0, height, 0),
		(if crit then "-" .. hit .. "!" else "-" .. hit),
		Color3.fromHex(if crit then colours.Crit else (if foe then colours.Foe else colours.Ours)),
		if crit then V.CritTextSize else V.HitTextSize
	)
end

-- Where a shot leaves its shooter: a slime's weapon (the bow, the focus, the staff's head, the kit), else its mouth.
local function muzzle(shooter: SlimeActor.Slime, from: Vector3, dir: Vector3): Vector3
	local head = SlimeWeapon.headOf(shooter.model)
	return if head then head.Position else from + dir * radius(shooter) + Vector3.new(0, shooter.body.Size.Y * 0.6, 0)
end

-- The attacker's move: a spitter spits, the rest lunge to the skin of their target and hold a beat there. `land` runs
-- when the blow arrives.
local function strike(event: { [string]: any }, style: FightFx.Style, land: () -> ())
	local attacker, from = find(event.from)
	local target, to = find(event.to)
	if not attacker or not from or not target or not to then
		task.delay(contactSeconds(style), land)
		return
	end
	local line = flat(to - from)
	local dir = along(line, attacker.root.LookVector)
	if style.shot then
		SlimeActor.kick(attacker, "lean", 1.5)
		local mouth = muzzle(attacker, from, dir)
		local skin = to - dir * radius(target) + Vector3.new(0, target.body.Size.Y * 0.5, 0)
		local fx = fxOf(event.from)
		if fx and fx.shot and fx.blow then
			-- (the flight and, as it lands, the blow: impact draws no second one)
			vfx(fx.blow, skin, { from = mouth, scale = fxScale(event.from) })
			task.delay(DFx.ShotSeconds, land)
		else
			FightFx.shot(style.shot :: string, mouth, skin, land)
		end
		return
	end
	local reach = math.max(0, line.Magnitude - (radius(attacker) + radius(target)) * 0.85)
	if byPlaces(event.from) then
		-- (the server strikes only in reach; a body still catching up its walk never lunges further than that)
		reach = math.min(reach, Config.Dungeon.Move.MeleeStuds)
	end
	-- (a boss's burst and a regular's pop hold it there as long as the body it strikes)
	local stop = if burstOf(event)
		then DFx.Burst.HitStopSeconds
		elseif popHit(event) then DFx.Pop.HitStopSeconds
		elseif hardOf(event) then V.Hard.HitStopSeconds
		else V.HitStopSeconds
	play(attacker, from, dir * reach, V.LungeSeconds, V.ContactShare, stop)
	SlimeActor.hop(attacker, V.LungeHop)
	task.delay(contactSeconds(style), land)
end

-- A class skill the library draws, struck with one blow at one foe: a melee one lunges and lands when the effect played
-- at its aim says (Dash Strike's cuts opening); a shot's library projectile leaves the weapon and the blow lands on its
-- marker.
local function libraryStrike(
	event: { [string]: any },
	style: FightFx.Style,
	look: { [string]: any },
	first: boolean,
	land: () -> ()
)
	local attacker, from = find(event.from)
	local target, to = find(event.to)
	local K = V.Skill
	if not attacker or not from or not target or not to then
		task.delay(contactSeconds(style), land)
		return
	end
	if look.aim then
		if first then
			strike(event, style, function() end)
		end
		local wait = math.max((leads[event.from] or 0) - os.clock(), contactSeconds(style))
		task.delay(wait + (if first then 0 else K.MultiGap), land)
		return
	end
	local level, scale = levelOf(attacker)
	if look.pierce then
		-- (the arrow flies through them all to the farthest; each blow lands as it passes)
		local far, farAt, farId = target, to, event.to
		local farthest = flat(to - from).Magnitude
		local struck: { string } = lines[event.from] or {}
		for _, other in struck do
			local body, at = find(other)
			if body and at and flat(at - from).Magnitude > farthest then
				far, farAt, farId, farthest = body, at, other, flat(at - from).Magnitude
			end
		end
		if first then
			aims[event.from] = farId
			SlimeActor.kick(attacker, "lean", 1.5)
			local mouth = muzzle(attacker, from, along(farAt - from, attacker.root.LookVector))
			playOn(look, level, scale, far, farAt, mouth)
		end
		local share = math.clamp(flat(to - from).Magnitude / math.max(farthest, 1e-3), K.PierceEarliest, 1)
		task.delay(landingOf(look, level) * share, land)
		return
	end
	if first then
		SlimeActor.kick(attacker, "lean", 1.5)
		local mouth = muzzle(attacker, from, along(to - from, attacker.root.LookVector))
		playOn(look, level, scale, target, to, mouth)
	end
	task.delay(landingOf(look, level) + (if first then 0 else K.MultiGap), land)
end

-- The one who strikes a skill moves once for all its blows: Goo Slam leaps onto its target, Belly Bounce leaps where it
-- stands, the rest puff up; when it comes down the skill's art bursts and rings the ground (View.Skill.Looks).
-- A Dungeon boss's skill goes off: its wind-up ends and its release plays (Config.Dungeon.Fx: on the caster's feet, on
-- the target from the caster, or rising from the caster). True when it had one (the way's art is then left out).
local function release(event: { [string]: any }, centre: Vector3?): boolean
	local fx = fxOf(event.from)
	local skill = specialOf(fx, event)
	if not skill then
		return false
	end
	endCharge(event.from, true)
	local caster, from = find(event.from)
	local target, to = find(event.to)
	if not caster or not from then
		return true
	end
	local scale = fxScale(event.from)
	local opts: { [string]: any } = { scale = scale, variant = skill.variant }
	-- (a boss's burst flares and marks the ground under its release: skill.monster_impact, DFx.Burst)
	local burst = burstOf(event)
	-- (its box is the body it lands on, standing on the floor: its `ground` pieces lie on the floor and its `body` ones
	-- at that body's middle; a box of the effect's own size, as tall as a boss, put the rings under the floor)
	local wide = 5 * scale
	if skill.at == "target" and to then
		local tall = if target then target.body.Size.Y else caster.body.Size.Y
		opts.from = from + Vector3.new(0, caster.body.Size.Y * 0.5, 0)
		opts.size = Vector3.new(wide, tall, wide)
		vfx(skill.release, to + Vector3.new(0, tall * 0.5, 0), opts)
		if burst then
			vfx(
				"skill.monster_impact",
				to + Vector3.new(0, tall * 0.5, 0),
				{ scale = scale, variant = burst, size = opts.size }
			)
		end
	else
		if skill.at == "up" then
			local base = from + Vector3.new(0, caster.body.Size.Y * 0.6, 0)
			vfx(skill.release, CFrame.lookAt(base, base + Vector3.yAxis), opts)
		end
		local tall = caster.body.Size.Y
		local at = (centre or from) + Vector3.new(0, tall * 0.5, 0)
		opts.size = Vector3.new(wide, tall, wide)
		if skill.at ~= "up" then
			vfx(skill.release, at, opts)
		end
		if burst then
			vfx("skill.monster_impact", at, { scale = scale * DFx.Burst.MarkWide, variant = burst, size = opts.size })
		end
	end
	return true
end

local function cast(event: { [string]: any }, looks: { [string]: any })
	local caster, from = find(event.from)
	local target, to = find(event.to)
	if not caster or not from then
		return
	end
	local K = V.Skill
	local centre = from
	if looks.leap then
		SlimeActor.hop(caster, K.Leap)
		if looks.onTarget and target and to then
			local line = flat(to - from)
			local reach = math.max(0, line.Magnitude - (radius(caster) + radius(target)) * 0.85)
			local seconds = K.CastSeconds + V.KnockSeconds
			play(
				caster,
				from,
				along(line, caster.root.LookVector) * reach,
				seconds,
				K.CastSeconds / seconds,
				V.HitStopSeconds
			)
			centre = to
		end
	else
		SlimeActor.kick(caster, "puff", V.WindupPuff * K.Windup)
	end
	task.delay(if looks.leap then K.CastSeconds else 0, function()
		safe("cast", function()
			if caster.destroyed then
				return
			end
			if looks.leap then
				SlimeActor.kick(caster, "squash", V.WindupSquash * K.Windup)
			end
			if release(event, centre) then
				return
			end
			if looks.burst then
				FightFx.burst(looks.burst, centre + Vector3.new(0, caster.body.Size.Y * 0.5, 0), K.Burst, looks.bits)
			end
			if looks.ring then
				FightFx.ring(looks.ring, centre, K.Ring)
			end
			if looks.ring2 then
				FightFx.ring(looks.ring2, centre, K.Ring * 0.7)
			end
			onFloor(looks.lib, centre, caster.body.Size.Y, looks.libScale)
		end)
	end)
end

-- How a blow gets to its target, then `land`: a plain blow lunges or spits (strike); a skill's blows wait for its caster
-- (`first` is the skill's first blow in this batch, which moves the caster): Dash Strike dashes through and lands its
-- blows one after another, a skill that strikes around lands them when its caster comes down, acid falls from above.
local function deliver(event: { [string]: any }, style: FightFx.Style, first: boolean, land: () -> ())
	local s = skillOf(event)
	local K = V.Skill
	local drawn = if s then libraryLook(event) else nil
	if drawn and s.kind ~= "multi" and s.kind ~= "all" and s.kind ~= "splash" then
		libraryStrike(event, style, drawn, first, land)
	elseif not s or (s.kind ~= "multi" and s.kind ~= "all" and s.kind ~= "splash") then
		if s and first and specialOf(fxOf(event.from), event) then
			-- (a Dungeon monster's one heavy special: its release goes off as the blow lands)
			strike(event, style, function()
				safe("release", function()
					release(event, nil)
				end)
				land()
			end)
		else
			strike(event, style, land)
		end
	elseif s.kind == "multi" then
		if first then
			local attacker, from = find(event.from)
			local target, to = find(event.to)
			if attacker and from and target and to then
				local line = flat(to - from)
				FightFx.afterImages(
					attacker.body,
					along(line, attacker.root.LookVector) * (line.Magnitude - radius(target))
				)
			end
			strike(event, style, function() end)
			release(event, nil)
		end
		local n = if type(event.n) == "number" then event.n else 1
		task.delay(contactSeconds(style) + (n - 1) * K.MultiGap, land)
	else
		local looks = looksOf(event)
		if first then
			cast(event, looks)
		end
		local target, to = find(event.to)
		local own = fxOf(event.from)
		if looks.rain and target and to and not specialOf(own, event) then
			local skin = to + Vector3.new(0, target.body.Size.Y * 0.5, 0)
			FightFx.shot(looks.rain, skin + Vector3.new(0, K.RainHeight, 0), skin, function()
				safe("rain", function()
					if looks.rainRing then
						FightFx.ring(looks.rainRing, to, K.Ring * 0.45)
					end
					if looks.hitVfx then
						-- (an Alchemist's flask breaks on the foe: the library's splash, bigger by the kit's tier)
						local _, scale = levelOf((find(event.from)))
						vfx(looks.hitVfx, skin, { scale = scale * (looks.hitScale or 1) })
					end
				end)
				land()
			end)
		elseif looks.fire and target and to and not specialOf(own, event) then
			-- (one shot from the caster's weapon at every foe it strikes, the splashed ones a beat later)
			local caster, from = find(event.from)
			local skin = to + Vector3.new(0, target.body.Size.Y * 0.5, 0)
			local mouth = if caster and from
				then muzzle(caster, from, along(to - from, caster.root.LookVector))
				else skin
			task.delay(if event.splash then K.MultiGap else 0, function()
				FightFx.shot(looks.fire, mouth, skin, function()
					if looks.hitVfx then
						-- (each bursts where it lands, as hard as the rest; bigger the higher the weapon's tier)
						local _, scale = levelOf(caster)
						vfx(looks.hitVfx, skin, { scale = scale })
					end
					land()
				end)
			end)
		else
			task.delay(K.CastSeconds + (if event.splash then K.MultiGap else 0), land)
		end
	end
end

-- After its blow, once back from the lunge, the attacker takes its place again (a fast one circles to a new flank).
local function afterBlow(event: { [string]: any }, style: FightFx.Style)
	if byPlaces(event.from) then
		-- (the fighters keep the place the server walked them to)
		return
	end
	local back = if style.shot then 0 else V.LungeSeconds * (1 - V.ContactShare) + V.HitStopSeconds
	if skillOf(event) then
		back = math.max(back, V.Skill.CastSeconds + V.KnockSeconds)
	end
	task.delay(back, function()
		safe("move", function()
			reposition(event.from)
		end)
	end)
end

local function onHit(event: { [string]: any }, first: boolean)
	local style = styleOf(event.from)
	if first and popOf(event) then
		-- (a regular's pop lets go: its glow flashes and fades; a burst's goes with its release)
		endCharge(event.from, true)
	elseif first and skillOf(event) then
		letGo(event.from)
	end
	deliver(event, style, first, function()
		safe("impact", function()
			impact(event, style)
		end)
		if first then
			afterBlow(event, style)
		end
	end)
end

-- Jelly Guard: the guard glows and rings the ground; for a while it takes the blows aimed at its team-mates.
local function onGuard(event: { [string]: any })
	local guard, at = find(event.from)
	if not guard or not at then
		return
	end
	local looks = V.Skill.Looks.defence
	SlimeActor.kick(guard, "puff", V.WindupPuff * V.Skill.Windup)
	letGo(event.from)
	if release(event, nil) then
		-- (a Dungeon monster's wall is its own art, on itself)
		return
	end
	FightFx.burst(looks.burst, at + Vector3.new(0, guard.body.Size.Y * 0.5, 0), V.Skill.Burst, looks.bits)
	FightFx.ring(looks.ring, at, V.Skill.Ring * 0.8)
end

-- A healer mends a team-mate (the Dungeon's monsters do): the healer puffs up, the mended one gets the cross and a green
-- number. A mend special heals them all at once, one event each: its release goes off once, on the healer.
local mended: { [string]: number } = {}
local function onHeal(event: { [string]: any })
	local healer = find(event.from)
	local target, to = find(event.to)
	if event.skill and os.clock() - (mended[event.from] or -1) > 0.5 then
		mended[event.from] = os.clock()
		letGo(event.from)
		release(event, nil)
	end
	if healer then
		SlimeActor.kick(healer, "puff", V.WindupPuff)
		-- (a monster slime healer's own healing move peaks a moment after the mending shows)
		local peak = SlimeActor.attackPeak(healer)
		if peak then
			SlimeActor.act(healer, "Attack", math.max(0, peak - Config.Dungeon.View.ClipHealLead))
		end
	end
	if target and to then
		local amount = math.max(1, math.floor((event.amount or 0) + 0.5))
		local P = Config.Dungeon.View
		local fx = fxOf(event.from)
		local centre = to + Vector3.new(0, target.body.Size.Y * 0.5, 0)
		local function healNumber()
			floatText(
				to + Vector3.new(0, target.body.Size.Y, 0),
				"+" .. amount,
				UiKit.colour(P.HealColour),
				V.HitTextSize
			)
		end
		local look = if event.skill then libraryLook(event) else nil
		if look then
			-- (a Healer's Mend: the library's light falls from the sky on the one it mends, its number as the light
			-- reaches it)
			local level, scale = levelOf(healer)
			vfx(look.vfx, target.model, { variant = level, scale = scale })
			task.delay(landingOf(look, level), healNumber)
			return
		end
		local function mend()
			if fx and fx.heal then
				vfx(fx.heal, target.model, nil)
			else
				FightFx.burst("healCross", centre, P.HealBurst, nil)
			end
			healNumber()
		end
		-- (a slime with a staff sends its healing light from the staff's head)
		local head = if healer and healer ~= target then SlimeWeapon.headOf(healer.model) else nil
		if head and not fx then
			FightFx.shot(V.Skill.HealShot, head.Position, centre, mend)
		else
			mend()
		end
	end
end

-- A Guardian's Taunt: its shield rings out once (on the first foe of the batch) and every foe it pulls is marked.
local taunted: { [string]: number } = {}
local function onTaunt(event: { [string]: any })
	local guard, at = find(event.from)
	local foe, there = find(event.to)
	local looks = looksOf(event)
	if guard and at and os.clock() - (taunted[event.from] or -1) > 0.5 then
		taunted[event.from] = os.clock()
		SlimeActor.kick(guard, "puff", V.WindupPuff * V.Skill.Windup)
		if looks.burst then
			FightFx.burst(looks.burst, at + Vector3.new(0, guard.body.Size.Y * 0.5, 0), V.Skill.Burst, looks.bits)
		end
		if looks.ring then
			FightFx.ring(looks.ring, at, V.Skill.Ring)
		end
		letGo(event.from)
		onFloor(looks.lib, at, guard.body.Size.Y, looks.libScale)
	end
	if foe and there and looks.mark then
		FightFx.ring(looks.mark, there, foe.body.Size.X * 1.6)
	end
end

-- When the blow an event came with reaches its target (after the lunge, the spit, the skill's cast or rain).
local function blowLanding(event: { [string]: any }): number
	local style = if type(event.from) == "string" then styleOf(event.from) else FightFx.style(nil)
	local s = skillOf(event)
	local landing = contactSeconds(style)
	if s and s.kind == "multi" then
		landing += ((if type(event.n) == "number" then event.n else 1) - 1) * V.Skill.MultiGap
	elseif s and (s.kind == "all" or s.kind == "splash") then
		landing = if looksOf(event).rain
			then F.ShotSeconds
			else V.Skill.CastSeconds + (if event.splash then V.Skill.MultiGap else 0)
	end
	return landing
end

-- ===== Lasting effects: each shows on the one it is on while it lasts (a "status" event, View.Status) =====

type Worn = { handle: any, untilAt: number, from: string? }
local worn: { [string]: { [string]: Worn } } = {}

local function takeOff(id: string, name: string)
	local on = worn[id]
	local each = if on then on[name] else nil
	if on and each then
		on[name] = nil
		pcall(VfxLib.detach, each.handle, V.Status.FadeSeconds)
	end
end

-- A fighter fell, or its fight is over: what it wears goes, and what it put on others only while it stands (a taunt).
local function takeOffAll(id: string)
	local own = worn[id]
	if own then
		for name in own do
			takeOff(id, name)
		end
	end
	worn[id] = nil
	for other, on in worn do
		for name, each in on do
			local look = (V.Status.Looks :: any)[name]
			if each.from == id and look and look.whileFrom then
				takeOff(other, name)
			end
		end
	end
end

local function wear(event: { [string]: any }, look: { [string]: any })
	local id, name, seconds = event.to, event.status, event.seconds
	local actor = find(id)
	if not actor or actor.destroyed then
		return
	end
	local on = worn[id] or {}
	worn[id] = on
	local untilAt = os.clock() + seconds
	local each: Worn? = on[name]
	if each then
		-- (renewed: it lasts longer, nothing new is put on)
		each.untilAt = math.max(each.untilAt, untilAt)
	else
		local caster = if type(event.from) == "string" then find(event.from) else nil
		local tier = if caster then SlimeWeapon.tierOf(caster.model) else nil
		-- (on the body part, welded, as the village's slimes wear theirs: on the whole model the box of a slime and its
		-- weapon and wear is far wider than the slime, and the look stood beside it, seen 2026-11-13)
		local opts: { [string]: any } = {
			variant = (if look.variants then look.variants[event.skill or ""] else nil) or look.variant,
			grade = if look.graded then (V.Status.Grades :: any)[tier or "wood"] else nil,
			weld = true,
		}
		if look.minHeight and actor.body.Size.Y < look.minHeight then
			opts.height = look.minHeight
		end
		local ok, handle = pcall(VfxLib.attach, actor.body, look.vfx, opts)
		if not ok or not handle then
			return
		end
		local made: Worn = { handle = handle, untilAt = untilAt, from = event.from }
		on[name] = made
		each = made
	end
	local kept = each :: Worn
	task.delay(seconds, function()
		safe("status", function()
			if worn[id] and worn[id][name] == kept and os.clock() >= kept.untilAt - 0.05 then
				takeOff(id, name)
			end
		end)
	end)
end

-- A lasting effect was put on (or renewed): it shows as the blow that brought it lands (a taunt or a wall at once).
local function onStatus(event: { [string]: any })
	local name = event.status
	local look = if type(name) == "string" then (V.Status.Looks :: any)[name] else nil
	if type(event.to) ~= "string" or type(event.seconds) ~= "number" or not look or not VfxLib.get(look.vfx) then
		return
	end
	local wait = if look.atOnce then 0 else blowLanding(event)
	task.delay(wait, function()
		safe("status", function()
			wear(event, look)
		end)
	end)
end

-- A miss: the blow comes, the target is already stepping aside and leaves fading copies of itself.
local function onDodge(event: { [string]: any }, first: boolean)
	local style = styleOf(event.from)
	local target, home = find(event.to)
	if target and home then
		local side = if math.random() < 0.5 then -1 else 1
		local across = Vector3.new(-target.root.LookVector.Z, 0, target.root.LookVector.X)
		local step = across * side * V.DodgeStuds
		FightFx.afterImages(target.body, step)
		play(target, home, step, V.DodgeSeconds)
		SlimeActor.hop(target, V.LungeHop)
	end
	deliver(event, style, first, function()
		safe("miss", function()
			local body, at = find(event.to)
			if body and at then
				floatText(at + Vector3.new(0, body.body.Size.Y, 0), "Miss", Color3.new(1, 1, 1), V.HitTextSize)
			end
		end)
		if first then
			afterBlow(event, style)
		end
	end)
end

local function fall(event: { [string]: any })
	local id: string = event.to
	local coins: number = event.coins or 0
	takeOffAll(id)
	local actor, spot, foe = find(id)
	local size = V.RewardTextSize
	local monster = extras[id]
	if monster and monster.foe then
		-- a Dungeon monster: it bursts in the way it fights; its drops are the Dungeon's to show (no coins fly from it)
		monster.dead = true
		dropBar(id)
		endCharge(id)
		local style = FightFx.style(monster.way)
		local own = monster.fx
		local bigness = math.clamp(monster.size, 1, Config.Dungeon.View.DeathBigness)
		local body = monster.actor.body
		local at = spot or monster.stand
		local centre = at + Vector3.new(0, body.Size.Y * 0.5, 0)
		SlimeActor.kick(monster.actor, "squash", V.DeathSquash)
		-- (a monster slime dies its own way first and bursts as it ends)
		local dying = SlimeActor.act(monster.actor, "Die")
		task.delay(math.max(V.DeathDelay, dying), function()
			safe("burst", function()
				if own and own.fall then
					-- (the effect's box stands on the ground where the monster fell)
					local scale = bigness * DFx.Scale
					local up = DFx.FallBox * scale * 0.5
					vfx(own.fall, at + Vector3.new(0, up, 0), { scale = scale, variant = DFx.FallVariant })
					if own.element and monster.size >= DFx.FallImpactSize then
						-- (a boss's fall shakes its ground: the flash, the shock ring and the mark of its map's element)
						onFloor("skill.monster_impact", at, body.Size.Y, scale, own.element)
					end
				else
					FightFx.burst(style.death or "burstShock", centre, F.DeathBurst * bigness, style.bits)
					FightFx.ring(style.ring or "ringShock", at, F.DeathRing * bigness)
				end
				FightFx.goo(body, centre, body.CFrame.LookVector, F.DeathGoo)
			end)
			local gone = monster.gone
			if gone then
				gone()
			end
		end)
		return
	end
	if foe then
		local zombie = ZombieWorld.zombie(id)
		local kind = if zombie then zombie.kind else nil
		local style = FightFx.style(kind)
		local look = if kind then ZombieLook.look(kind) else nil
		local bigness = if look then look.size else 1
		size = size * bigness
		ZombieWorld.kill(id)
		dropBar(id)
		if actor and spot then
			local body = actor.body
			local centre = spot + Vector3.new(0, body.Size.Y * 0.5, 0)
			task.delay(V.DeathDelay, function()
				safe("burst", function()
					FightFx.burst(style.death or "burstShock", centre, F.DeathBurst * bigness, style.bits)
					FightFx.ring(style.ring or "ringShock", spot, F.DeathRing * bigness)
					FightFx.goo(body, centre, body.CFrame.LookVector, F.DeathGoo)
					coinShower(centre, bigness ^ 2)
				end)
			end)
		end
	else
		for _, fight in fights do
			local fighter = fight.fighters[id]
			if fighter then
				fighter.fallen = true
				dropBar(id)
				if actor then
					SlimeActor.setEmotion(actor, "sad")
					SlimeActor.kick(actor, "turn", V.FallTurn)
					SlimeWeapon.fight(actor.model, false)
					FightFx.stars(actor.body.Position + Vector3.new(0, actor.body.Size.Y * 0.6, 0), V.StarSize)
					vfx(V.FallVfx, actor.body.Position, nil)
					for _, part in actor.model:GetDescendants() do
						if part:IsA("MeshPart") then
							TweenService
								:Create(part, TweenInfo.new(V.FadeSeconds), {
									Transparency = math.max(part.Transparency, Config.VillageClient.GhostTransparency),
									Color = part.Color:Lerp(Color3.new(1, 1, 1), V.FadeWhiten),
								})
								:Play()
						end
					end
				end
			end
		end
	end
	if actor and spot and coins > 0 then
		floatText(
			spot + Vector3.new(0, actor.body.Size.Y + 1, 0),
			"+" .. UiKit.money(coins),
			Color3.fromHex(V.NumberColours.Coins),
			size
		)
	end
end

-- A fall shows when the blow that caused it lands (after the lunge or the spit), not before.
local function onFallen(event: { [string]: any })
	-- (as deliver lands a skill's blows)
	task.delay(blowLanding(event) + V.HitStopSeconds, function()
		safe("fall", function()
			fall(event)
		end)
	end)
end

-- The team that won hops for joy, one after another, while it stays on the field (Config.Zombies.CheerSeconds).
local function cheer(fight: Fight)
	for index, id in fight.order do
		local fighter = fight.fighters[id]
		local extra = extras[id]
		local body = if extra then nil else ZombieMarch.body(id)
		local actor = if extra then extra.actor elseif body then body.actor else nil
		if fighter and not fighter.fallen and actor then
			local start = (index - 1) * V.CheerStagger + V.HitStopSeconds
			task.delay(start, function()
				if not actor.destroyed then
					SlimeActor.setEmotion(actor, "happy")
					FightFx.stars(actor.body.Position + Vector3.new(0, actor.body.Size.Y * 0.6, 0), V.StarSize)
					local tall = actor.body.Size.Y
					onFloor(V.CheerVfx, actor.body.Position - Vector3.new(0, tall * 0.5, 0), tall, V.CheerVfxScale)
				end
			end)
			for hop = 0, V.CheerHops - 1 do
				task.delay(start + hop * V.CheerGap, function()
					if not actor.destroyed then
						SlimeActor.hop(actor, V.CheerHop)
					end
				end)
			end
		end
	end
end

-- The fight is over: the bars go; a winning team cheers, then hops home on the march (the server sets it going).
local function onEnd(teamIndex: number, event: { [string]: any })
	local fight = fights[teamIndex]
	if not fight then
		return
	end
	fight.over = true
	-- every zombie of the fight: those it began with and any of the group now
	local foes = table.clone(fight.foes)
	local group = ZombieWorld.group(fight.groupId)
	if group then
		for id in group.byId do
			table.insert(foes, id)
		end
	end
	for _, id in fight.order do
		dropBar(id)
		takeOffAll(id)
	end
	for _, id in foes do
		dropBar(id)
		takeOffAll(id)
	end
	if event.winner == "squad" then
		-- (after the last blow has landed)
		task.delay(V.LungeSeconds, function()
			safe("cheer", function()
				cheer(fight)
			end)
		end)
		-- then back into line where the march left them, just before it takes them home
		task.delay(Config.Zombies.CheerSeconds - V.Moves.RegroupSeconds, function()
			safe("regroup", function()
				for _, id in fight.order do
					local body = ZombieMarch.body(id)
					local home = homes[id]
					if body and home and not fight.fighters[id].fallen and not body.actor.destroyed then
						moveTo(id, body.actor, home, body.stand, body.stand + body.facing, V.Moves.RegroupSeconds)
					end
				end
			end)
		end)
	end
	if teamIndex == 0 then
		-- (the Dungeon's field stays as it is until DungeonFight clears it: the end card is on the screen)
		return
	end
	task.delay(Config.Zombies.CheerSeconds, function()
		if fights[teamIndex] == fight then
			fights[teamIndex] = nil
		end
		for _, id in fight.order do
			homes[id], targets[id], placed[id] = nil, nil, nil
		end
		for _, id in foes do
			homes[id], targets[id], placed[id] = nil, nil, nil
			dropBar(id)
		end
	end)
end

-- The team is back at the gate: the small notice says which, how many died and what it earned.
local function onHome(payload: { [string]: any }, event: { [string]: any })
	local team = event.team
	local dead = event.dead
	local coins = event.coins
	pcall(
		UiTeams.notice,
		if type(team) == "number" then team else payload.team,
		if type(dead) == "number" then dead else 0,
		if type(coins) == "number" then coins else 0
	)
end

local function onEvents(payload: any)
	if type(payload) ~= "table" or type(payload.team) ~= "number" or type(payload.events) ~= "table" then
		return
	end
	-- (the Slime Dungeon's bodies are made first, so every event of the batch finds them)
	local handler = dungeonHandler
	if payload.dungeon == true and handler then
		safe("dungeon", function()
			handler(payload.events)
		end)
	end
	-- (a skill's blows come together in one batch; its caster moves for the first of them only; a piercing arrow's blows
	-- are gathered first, so it is aimed at the farthest)
	local casting: { [string]: boolean } = {}
	local gathered: { [string]: boolean } = {}
	for _, event in payload.events do
		if
			type(event) == "table"
			and (event.kind == "hit" or event.kind == "dodge")
			and type(event.from) == "string"
			and type(event.to) == "string"
			and looksOf(event).pierce
		then
			if not gathered[event.from] then
				gathered[event.from] = true
				lines[event.from] = {}
			end
			table.insert(lines[event.from], event.to)
		end
	end
	for _, event in payload.events do
		safe("event " .. tostring(event.kind), function()
			local kind = event.kind
			local first = true
			if (kind == "hit" or kind == "dodge") and event.skill ~= nil and type(event.from) == "string" then
				first = not casting[event.from]
				casting[event.from] = true
			end
			if kind == "start" then
				onStart(payload.team, event)
			elseif kind == "aim" then
				onAim(event)
			elseif kind == "guard" then
				onGuard(event)
			elseif kind == "hit" then
				onHit(event, first)
			elseif kind == "dodge" then
				onDodge(event, first)
			elseif kind == "fallen" then
				onFallen(event)
			elseif kind == "heal" then
				onHeal(event)
			elseif kind == "taunt" then
				onTaunt(event)
			elseif kind == "status" then
				onStatus(event)
			elseif kind == "move" then
				onMove(payload.team, event)
			elseif kind == "end" then
				onEnd(payload.team, event)
			elseif kind == "home" then
				onHome(payload, event)
			end
		end)
	end
end

-- ===== The Slime Dungeon's door into the drawing (client/DungeonFight) =====

-- The round field the fight is on (its middle at the floor's top, its radius), nil when there is none.
function ZombieFight.setArena(centre: Vector3?, rim: number?)
	arena = if centre and rim then { centre = centre, radius = rim } else nil
end

-- Who gets the batches of events that say `dungeon = true`, before ZombieFight draws them.
function ZombieFight.setDungeon(handler: ((events: { any }) -> ())?)
	dungeonHandler = handler
end

-- The Arena replay's door (client/ArenaReplay): a batch of events for the field team 0 holds, drawn like any other.
function ZombieFight.feed(events: { any })
	onEvents({ team = 0, events = events })
end

-- A body of the Dungeon joins the fight under `id` (the id the events name); a new run reuses ids, so what the last run
-- left under it is forgotten.
function ZombieFight.adopt(id: string, extra: Extra)
	homes[id], targets[id] = nil, nil
	dropBar(id)
	takeOffAll(id)
	extras[id] = extra
	local fight = fights[0]
	if fight then
		safe("adopt", function()
			sync(fight)
		end)
	end
end

-- A fighter of the Dungeon walks to `to` (the floor's top, in the world) and is there in `seconds`, as the server says:
-- from where its body is now (a lunge or knock-back in progress is cut short where it is), hopping, facing where it goes. It
-- never goes faster than Config.Dungeon.View.WalkCatchUp times the fastest walk, so a fighter that has fallen behind catches
-- up smoothly and never jumps.
-- A camp's fighter (a body of the march or a zombie) walks the same way.
function ZombieFight.walk(id: string, to: Vector3, seconds: number)
	local extra = extras[id]
	local actor = if extra then extra.actor else find(id)
	if not actor or actor.destroyed or (extra and extra.dead) or (not extra and ZombieWorld.isDead(id)) then
		return
	end
	-- (from where the body is this frame: mid-walk, mid-lunge or mid-knock alike)
	local from = groundFor(actor.root.Position)
	stopAnim(actor)
	local spot = groundFor(to)
	local line = flat(spot - from)
	local length = line.Magnitude
	if length < V.Moves.MinStuds * 0.25 then
		return
	end
	local fastest = Config.Dungeon.Move.MaxStuds * Config.Dungeon.View.WalkCatchUp
	local previous = walks[actor]
	walks[actor] = {
		id = id,
		from = from,
		to = spot,
		dir = line.Unit,
		start = os.clock(),
		duration = math.max(seconds, length / fastest, 0.05),
		length = length,
		-- (a walk renewed on the way keeps its hop going rather than hopping at once)
		hopAt = if previous then Config.Dungeon.View.WalkHopStuds * 0.5 else 0,
	}
	homes[id] = from
	if not walkLoop then
		walkLoop = RunService.RenderStepped:Connect(stepWalks)
	end
end

function ZombieFight.release(id: string)
	local extra = extras[id]
	if extra then
		walks[extra.actor] = nil
	end
	dropBar(id)
	extras[id], homes[id], targets[id] = nil, nil, nil
end

-- Where a body of the fight stands now (nil when it is not known).
function ZombieFight.where(id: string): Vector3?
	local _, at = find(id)
	return at
end

-- The run is over: every body and bar is let go, and the field with it.
function ZombieFight.endDungeon()
	table.clear(walks)
	for id in extras do
		dropBar(id)
		homes[id], targets[id] = nil, nil
	end
	table.clear(extras)
	table.clear(mended)
	fights[0] = nil
	arena = nil
end

function ZombieFight.start()
	-- (the game has no effects setting of its own: VfxLib follows the device's graphics quality)
	VfxLib.setup({ log = "[GooLineage]" })
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local remote = remotes:WaitForChild("Fight")
		if remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(onEvents)
		end
	end)
end

return ZombieFight
