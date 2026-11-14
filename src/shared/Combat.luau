--!strict
-- A fight between two sides, pure and seeded: the original's formulas (docs/reference/02-battle.md §8). Every fight of the
-- game (the Slime Dungeon, the camps, the Arena) runs in the positional mode (Combat.new's `moves`, the owner, 2026-11-13:
-- one equipment system, the same fight everywhere), where fighters walk into reach before they aim; without it (the
-- tools' and tests' quick fights) a hit lands when its cooldown ends, wherever the fighters are.
-- A slime with a weapon fights by its class (docs/WEAPONS.md, Config.Classes): its own beat, reach, plain blow and one
-- skills on independent cooldowns in seconds; a slime without one is a Brawler and fights by its role, as before.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

type Rng = typeof(Rng.new(0))
export type Unit = {
	id: string,
	side: string,
	attack: number,
	defence: number,
	speed: number,
	hp: number,
	maxHp: number,
	cooldown: number,
	target: Unit?,
	-- the coming blow has been announced (an "aim" event, WindupSeconds or its special's `windup` before it lands)
	aimed: boolean,
	-- how it fights: a slime's role (Combat.role) or class, a zombie's kind
	role: string,
	class: string?,
	tier: number?,
	-- a monster's rank in the dungeon (`boss`, `miniboss`, ...): bosses shrug off stuns, mini-bosses mostly
	rank: string,
	-- blows struck so far (every Skills[role].every-th is its skill), and whether the coming one is
	blows: number,
	skillNext: boolean,
	-- its specials (keys of Config.Combat.Skills) taken in turn, how many have been struck, the key of the coming one,
	-- and how many times a healer has mended (a mend special comes on its heal turns, not its blows)
	skills: { string },
	specials: number,
	skillKey: string,
	mends: number,
	-- when its last wind-up special began, and whether one came too early and waits for the next blow (SpecialGap)
	specialAt: number,
	owed: boolean,
	-- a guard covers its team-mates until this many seconds into the fight, its defence times guardMul meanwhile
	guardUntil: number,
	guardMul: number,
	-- stung slow: until this many seconds into the fight its beat runs at (1 - slowBy) speed
	slowUntil: number,
	slowBy: number,
	-- the moments the stuns that counted landed (StunWindow), and when a mini-boss may be stunned again
	stuns: { number },
	stunFree: number,
	-- effects by kind (Config.Classes.Effects), the strongest only, each until its end
	effects: { [string]: { value: number, untilAt: number } },
	-- taunted: it must go for `tauntBy` until tauntUntil; it cannot be taunted again before tauntFree
	tauntBy: Unit?,
	tauntUntil: number,
	tauntFree: number,
	-- a class skill's next ready second, keyed by skill (separate clocks even for one class)
	skillReady: { [string]: number },
	-- a timed barrier absorbs damage before health; its remaining value never stacks with a new one
	barrier: number,
	barrierUntil: number,
	hopReady: number,
	interceptReady: number,
	-- positional mode only (Fight.moves): where it stands (flat, studs from the arena's middle), the place round its
	-- target it walks to (its angle round the target, and whose), whether it was walking last step, and when its
	-- walk was last sent
	x: number,
	z: number,
	slotAngle: number,
	slotOf: string,
	walking: boolean,
	sentAt: number,
}
-- `open`: more foes are still to come (the dungeon's queue), so the fight does not end when the foes in it are down; a
-- squad wiped out ends it all the same. `radius`: in the positional mode, how far from the middle anyone may hop.
-- `fade`: heals weaken as the fight drags on (the Arena's, Config.Classes.HealFade).
export type Fight = {
	units: { Unit },
	rng: Rng,
	seconds: number,
	winner: string?,
	open: boolean?,
	fair: boolean?,
	moves: boolean?,
	radius: number?,
	fade: boolean?,
}
-- `skill` is the way of fighting whose skill struck (a key of Config.Combat.Skills); `n` the blow's number in a
-- several-blow skill; `splash` a blow that struck beside the target; `guard` the guard that took a blow aimed elsewhere;
-- `ranged` a blow from a fighter that keeps its distance; `slow` a sting that slowed its target; `melt` a blow that
-- melted its target's armour. A "heal" event carries the health given back in `amount`. A "move" event (positional mode
-- only) says a fighter walks: it stands at (x, z) and goes to (tx, tz), which it reaches in `seconds`; `dash` a Warrior's
-- rush, `hop` a Ranger's or Mage's jump away. A "taunt" event: `from` taunted `to`. A "status" event: a lasting effect
-- (`status`: taunted, shielded, melted, slowed, stunned, guarded) is on `to` for `seconds` from now, put on by `from`
-- with `skill`; sent each time it is put on or renewed, so the client can show it as long as it lasts.
export type Event = {
	kind: string,
	from: string?,
	to: string,
	amount: number?,
	absorbed: number?,
	crit: boolean?,
	skill: string?,
	n: number?,
	splash: boolean?,
	guard: string?,
	ranged: boolean?,
	slow: boolean?,
	melt: boolean?,
	x: number?,
	z: number?,
	tx: number?,
	tz: number?,
	seconds: number?,
	dash: boolean?,
	hop: boolean?,
	status: string?,
}
-- `maxHp` is the full health when the fighter starts wounded (hp below it); left out, hp is the full health.
-- `role` is a slime's way of fighting (Combat.role), `kind` a zombie's kind; either sets whom it goes for.
export type Fighter = {
	id: string,
	attack: number,
	defence: number,
	speed: number,
	hp: number,
	maxHp: number?,
	role: string?,
	class: string?,
	tier: number?,
	kind: string?,
	-- its specials (keys of Config.Combat.Skills), taken in turn; left out, { role } when the role has a skill
	skills: { string }?,
	-- where it starts in the positional mode (flat, from the arena's middle)
	x: number?,
	z: number?,
}

-- How a blow counts its target's armour: `magic` at MagicDefence, `ignore` a share of it not at all.
type How = { magic: boolean?, ignore: number? }

local Combat = {}

-- How fast a fighter walks, in studs a second, from its SPD (Config.Dungeon.Move); a monster (`foe`) FoeGain times that.
function Combat.walkSpeed(speed: number, foe: boolean?): number
	local m = Config.Dungeon.Move
	return math.min(m.MaxStuds, m.BaseStuds + m.PerSpeed * math.max(0, speed)) * (if foe then m.FoeGain else 1)
end

-- `magic` counts the defence at Config.Classes.MagicDefence (magic slips past part of armour).
function Combat.damage(raw: number, defence: number, magic: boolean?): number
	local c = Config.Combat
	if magic then
		defence *= Config.Classes.MagicDefence
	end
	local reduction = math.min(c.DefenceCap, defence / (defence + c.DefenceK))
	-- (not rounded as in the original: at the low stats here, rounding made one level up double the damage)
	return math.max(c.MinDamage, raw * c.DamageScale * (1 - reduction))
end

-- A class heal: `factor` times what the healer's own blow would take off a slime as strong as itself (its attack at the
-- damage weight, through armour the size of its attack), so heals keep pace with blows at every level.
function Combat.healAmount(attack: number, factor: number): number
	return Combat.damage(attack, attack) * factor
end

function Combat.cooldown(speed: number): number
	local c = Config.Combat
	return math.max(c.MinCooldown, 1 / (1 + math.max(0, speed) * c.CooldownPerSpeed))
end

-- How a slime fights, from its strongest stat (hp counted per level, as Stats.level does); a tie is settled by the
-- slime's seed, so even starters with equal stats fight in different ways.
function Combat.role(fighter: Fighter, seed: number): string
	local values = {
		attack = fighter.attack,
		defence = fighter.defence,
		speed = fighter.speed,
		hp = (fighter.maxHp or fighter.hp) / Config.Stats.HpPerLevel,
	}
	local best = -math.huge
	local tied: { string } = {}
	for _, key in Config.Combat.Roles do
		local value = values[key]
		if value > best + 1e-9 then
			best = value
			tied = { key }
		elseif math.abs(value - best) <= 1e-9 then
			table.insert(tied, key)
		end
	end
	return tied[math.floor(math.abs(seed)) % #tied + 1]
end

-- The class numbers of a unit (Config.Classes.Kinds), nil for a Brawler or a monster.
local function kindOf(u: Unit): any
	return if u.class then (Config.Classes.Kinds :: any)[u.class] else nil
end

-- (each fighter opens at its own moment: a team that strikes all at once reads as one body, not four slimes)
local function unit(fighter: Fighter, side: string, rng: Rng): Unit
	local c = Config.Combat
	local role = fighter.role or fighter.kind or ""
	-- (each counts its blows from its own start, so fighters of one kind do not strike their skills all together)
	local list: { string } = fighter.skills or {}
	if not fighter.skills and (c.Skills :: any)[role] then
		list = { role }
	end
	local s = (c.Skills :: any)[list[1] or ""]
	local start = if s then math.floor(rng:next() * s.every) else 0
	local isMend = s ~= nil and s.kind == "mend"
	-- (a class skill's first use comes part of its cooldown in, so a fight does not open with six skills at once)
	local kind = if fighter.class then (Config.Classes.Kinds :: any)[fighter.class] else nil
	local ready: { [string]: number } = {}
	if kind then
		for index = 1, math.min(fighter.tier or 1, #kind.skills) do
			local key = kind.skills[index]
			ready[key] = c.OpeningCooldown + (c.Skills :: any)[key].cooldown * Config.Classes.OpeningShare
		end
	end
	return {
		id = fighter.id,
		side = side,
		attack = fighter.attack,
		defence = fighter.defence,
		speed = fighter.speed,
		hp = fighter.hp,
		maxHp = fighter.maxHp or fighter.hp,
		cooldown = c.OpeningCooldown + rng:next() * c.OpeningSpread,
		aimed = false,
		role = role,
		class = fighter.class,
		tier = fighter.tier,
		-- (a dungeon monster's `defRole`, Dungeon.monster; read loosely so the fighter types elsewhere need not carry it)
		rank = (fighter :: any).defRole or "",
		blows = if isMend then 0 else start,
		skillNext = false,
		skills = list,
		specials = 0,
		skillKey = "",
		mends = if isMend then start else 0,
		specialAt = -math.huge,
		owed = false,
		guardUntil = 0,
		guardMul = 1,
		slowUntil = 0,
		slowBy = 0,
		stuns = {},
		stunFree = 0,
		effects = {},
		tauntBy = nil,
		tauntUntil = 0,
		tauntFree = 0,
		skillReady = ready,
		barrier = 0,
		barrierUntil = 0,
		hopReady = 0,
		interceptReady = 0,
		x = fighter.x or 0,
		z = fighter.z or 0,
		slotAngle = 0,
		slotOf = "",
		walking = false,
		sentAt = 0,
	}
end

-- `moves` turns on the positional mode (every fight of the game): each fighter has a place and walks toward its target at
-- Combat.walkSpeed until it is in reach (Config.Dungeon.Move), and neither aims nor strikes before. Off, a blow lands when
-- its cooldown ends, wherever the fighters are. `radius` bounds the hops of the positional mode.
function Combat.new(
	squad: { Fighter },
	foes: { Fighter },
	rng: Rng,
	opts: { fair: boolean?, moves: boolean?, radius: number?, fade: boolean? }?
): Fight
	local units: { Unit } = {}
	for _, fighter in squad do
		table.insert(units, unit(fighter, "squad", rng))
	end
	for _, fighter in foes do
		table.insert(units, unit(fighter, "foe", rng))
	end
	return {
		units = units,
		rng = rng,
		seconds = 0,
		fair = if opts then opts.fair else nil,
		moves = if opts then opts.moves else nil,
		radius = if opts then opts.radius else nil,
		fade = if opts then opts.fade else nil,
	}
end

-- A fighter joins a fight that is going on (the dungeon's next monster): it opens at its own moment, as at the start.
-- A fight that has a winner is over; nobody joins it.
function Combat.add(fight: Fight, fighter: Fighter, side: string): Unit?
	if fight.winner then
		return nil
	end
	local joined = unit(fighter, side, fight.rng)
	table.insert(fight.units, joined)
	return joined
end

local function distance(a: Unit, b: Unit): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

-- Whether `b` is within `studs` of `a`: always outside the positional mode, where nobody has a place.
local function within(fight: Fight, a: Unit, b: Unit, studs: number): boolean
	return not fight.moves or (a.x - b.x) ^ 2 + (a.z - b.z) ^ 2 <= studs * studs
end

-- ===== Effects and stuns (docs/WEAPONS.md §2) =====

-- The share an effect of this kind has on the unit now (its cap at most), 0 when it has none.
local function effectOf(fight: Fight, u: Unit, kind: string): number
	local e = u.effects[kind]
	if e and e.untilAt > fight.seconds then
		return math.min(e.value, (Config.Classes.Effects :: any)[kind])
	end
	return 0
end

-- A lasting effect shows on the one it is on: the "status" event (Event) that says so, when there are events to send.
local function status(events: { Event }?, from: Unit?, u: Unit, name: string, seconds: number, key: string?)
	if events and seconds > 0 then
		local by = if from then from.id else nil
		table.insert(events, { kind = "status", from = by, to = u.id, status = name, seconds = seconds, skill = key })
	end
end

-- (the strongest only: a weaker one while a stronger lasts does nothing; as strong or stronger renews it) True when it
-- was put on.
local function addEffect(fight: Fight, u: Unit, kind: string, value: number, seconds: number): boolean
	local e = u.effects[kind]
	if e and e.untilAt > fight.seconds and e.value > value then
		return false
	end
	u.effects[kind] = { value = value, untilAt = fight.seconds + seconds }
	return true
end

-- Class slows share one cap and never replace a stronger live slow; monster stings still use their original rules.
local function classSlow(
	fight: Fight,
	u: Unit,
	share: number,
	seconds: number,
	events: { Event },
	from: Unit,
	key: string
): boolean
	local K = Config.Classes
	local capped = math.min(share, if u.rank == "boss" then K.SlowCapBoss else K.SlowCap)
	if u.slowUntil > fight.seconds and u.slowBy > capped then
		return false
	end
	u.slowUntil, u.slowBy = fight.seconds + seconds, capped
	status(events, from, u, "slowed", seconds, key)
	return true
end

-- Every stun that knocks a unit off its beat goes through here: within StunWindow the 1st counts full, the next ones by
-- StunSteps, then none until older ones age out. A boss is never stunned; a mini-boss MiniStunCap at most, then free.
-- With `events`, a stun that counted says so ("stunned", as long as it holds the unit off its beat).
function Combat.stun(fight: Fight, u: Unit, seconds: number, events: { Event }?, from: Unit?, key: string?)
	local K = Config.Classes
	if seconds <= 0 or u.rank == "boss" then
		return
	end
	if u.rank == "miniboss" then
		if fight.seconds < u.stunFree then
			return
		end
		u.cooldown += math.min(seconds, K.MiniStunCap)
		u.stunFree = fight.seconds + K.MiniStunFree
		status(events, from, u, "stunned", math.min(seconds, K.MiniStunCap), key)
		return
	end
	local kept: { number } = {}
	for _, at in u.stuns do
		if fight.seconds - at < K.StunWindow then
			table.insert(kept, at)
		end
	end
	local share = K.StunSteps[#kept + 1] or 0
	if share > 0 then
		u.cooldown += seconds * share
		table.insert(kept, fight.seconds)
		status(events, from, u, "stunned", seconds * share, key)
	end
	u.stuns = kept
end

-- ===== Whom it goes for =====

local function pullOf(u: Unit): number
	local kind = kindOf(u)
	return (Config.Combat.Pull :: any)[u.role] or (if kind then kind.pull else nil) or 1
end

-- Whom a fighter goes for, by its way of fighting (Config.Combat.Aims): the one with the least health left, the one that
-- hits hardest, or anyone, though a guard draws more of the blows (Config.Combat.Pull). A Guardian goes first for the
-- nearest foe that is after a squishy team-mate.
local function pick(fight: Fight, attacker: Unit): Unit?
	local c = Config.Combat
	local alive: { Unit } = {}
	for _, other in fight.units do
		if other.side ~= attacker.side and other.hp > 0 then
			table.insert(alive, other)
		end
	end
	if #alive == 0 then
		return nil
	end
	if attacker.class == "guardian" then
		local best: Unit? = nil
		local bestD = math.huge
		for _, other in alive do
			local prey = other.target
			if prey and prey.side == attacker.side and prey.hp > 0 and prey.class then
				if (Config.Classes.Squishy :: any)[prey.class] then
					local d = if fight.moves then distance(attacker, other) else 0
					if d < bestD then
						best, bestD = other, d
					end
				end
			end
		end
		if best then
			return best
		end
	end
	local aim = (c.Aims :: any)[attacker.role]
	if aim == "weakest" or aim == "strongest" then
		local best = alive[1]
		for _, other in alive do
			if (aim == "weakest" and other.hp < best.hp) or (aim == "strongest" and other.attack > best.attack) then
				best = other
			end
		end
		return best
	end
	local total = 0
	for _, other in alive do
		total += pullOf(other)
	end
	local roll = fight.rng:next() * total
	for _, other in alive do
		roll -= pullOf(other)
		if roll <= 0 then
			return other
		end
	end
	return alive[#alive]
end

-- Its target now: a taunted one goes for its taunter; one freed from a taunt cannot be taunted again for TauntFree and
-- picks again by its own rule; any other keeps its target until it falls.
local function targetOf(fight: Fight, a: Unit): Unit?
	local by = a.tauntBy
	if by then
		if by.hp > 0 and a.tauntUntil > fight.seconds then
			a.target = by
			return by
		end
		a.tauntBy = nil
		a.tauntFree = fight.seconds + Config.Classes.TauntFree
		a.target = pick(fight, a)
		return a.target
	end
	local target = a.target
	if not target or target.hp <= 0 then
		target = pick(fight, a)
		a.target = target
	end
	return target
end

-- A guard of the target's side that covers it now (not the target itself; in the positional mode only one standing
-- near it), or nil.
local function guardOf(fight: Fight, target: Unit): Unit?
	for _, other in fight.units do
		if
			other ~= target
			and other.side == target.side
			and other.hp > 0
			and other.guardUntil > fight.seconds
			and within(fight, target, other, Config.Dungeon.Move.GuardStuds)
		then
			return other
		end
	end
	return nil
end

-- A Guardian of the target's side whose Intercept is ready and stands near it (not the target itself), or nil.
local function interceptorOf(fight: Fight, target: Unit): Unit?
	local K = Config.Classes
	for _, other in fight.units do
		if
			other ~= target
			and other.class == "guardian"
			and other.side == target.side
			and other.hp > 0
			and other.interceptReady <= fight.seconds
			and within(fight, target, other, K.InterceptStuds)
		then
			return other
		end
	end
	return nil
end

-- ===== Blows =====

-- One blow of `attacker` at `target`, `factor` times its usual weight: a guard may take it, a Guardian intercept it, the
-- target may dodge a plain one, a slime's plain one may crit. `extra` goes into the events (the skill, the blow's number,
-- a splash); a blow without it is plain. `how` says how it counts armour.
local function blow(
	fight: Fight,
	attacker: Unit,
	target: Unit,
	factor: number,
	events: { Event },
	extra: { [string]: any }?,
	special: any?,
	how: How?
)
	local c = Config.Combat
	local K = Config.Classes
	local plain = extra == nil
	local guard = guardOf(fight, target)
	local struck = guard or target
	-- (only a direct blow is intercepted, once: a plain one or the first of a single-target skill, never an area)
	local direct = plain
		or (
			extra ~= nil
			and not extra.splash
			and special ~= nil
			and (special.kind == "single" or special.kind == "multi")
			and (extra.n == nil or extra.n == 1)
		)
	local catcher = if not guard and direct then interceptorOf(fight, target) else nil
	local ranged = (c.Ranged :: any)[attacker.role]
	local kind = kindOf(attacker)
	if kind and kind.reach > Config.Dungeon.Move.MeleeStuds then
		ranged = true
	end
	local function event(name: string, to: Unit, guardId: string?): Event
		local out: any = { kind = name, from = attacker.id, to = to.id, guard = guardId }
		if extra then
			for key, value in extra do
				out[key] = value
			end
		end
		if ranged then
			out.ranged = true
		end
		return out
	end
	if plain and fight.rng:next() < math.min(c.DodgeCap, struck.speed * c.DodgePerSpeed) then
		table.insert(events, event("dodge", struck, if guard then guard.id else nil))
		return
	end
	local function hurt(u: Unit): number
		local defence = u.defence
			* (if u == guard then u.guardMul else 1)
			* (1 - effectOf(fight, u, "melt"))
			* (1 - (if how and how.ignore then how.ignore else 0))
		-- (a class that always takes less, the Guardian behind its shield, counts as an effect of that kind that never ends)
		local own = kindOf(u)
		local taken = math.max(
			effectOf(fight, u, "taken"),
			math.min(if own and own.taken then own.taken else 0, Config.Classes.Effects.taken)
		)
		return Combat.damage(attacker.attack, defence, how and how.magic)
			* factor
			* (1 - taken)
			* (1 + effectOf(fight, attacker, "dealt"))
	end
	local crit = plain
		and (attacker.side == "squad" or fight.fair == true)
		and fight.rng:next() < math.min(c.CritCap, c.CritBase + attacker.speed * c.CritPerSpeed)
	-- who takes how much: the struck alone, or the target its share and the intercepting Guardian the rest
	local parts: { { u: Unit, share: number, guard: string? } } =
		{ { u = struck, share = 1, guard = if guard then guard.id else nil } }
	if catcher then
		catcher.interceptReady = fight.seconds + K.InterceptCooldown
		parts = {
			{ u = target, share = 1 - K.InterceptShare },
			{ u = catcher, share = K.InterceptShare, guard = catcher.id },
		}
	end
	for index, part in parts do
		local u = part.u
		local amount = hurt(u) * part.share * (if crit then c.CritFactor else 1)
		-- (an expired barrier cannot block the next blow; the hit shows health damage separately from absorption)
		local absorbed = 0
		if u.barrierUntil > fight.seconds and u.barrier > 0 then
			absorbed = math.min(amount, u.barrier)
			u.barrier -= absorbed
		end
		u.hp = math.max(0, u.hp - (amount - absorbed))
		local hit = event("hit", u, part.guard)
		hit.amount, hit.crit = amount - absorbed, crit
		if absorbed > 0 then
			hit.absorbed = absorbed
		end
		local endedWard = absorbed > 0 and u.barrier <= 0 and u.barrierUntil > fight.seconds
		-- (the riders land on the one aimed at, not on a Guardian that caught part of it)
		if index == 1 then
			-- (only a plain blow stings: a skill has its own weight)
			local sting = if plain then (c.Stings :: any)[attacker.role] else nil
			-- (its lasting riders go out after the hit that brought them)
			local riders: { Event } = {}
			if sting and u.hp > 0 then
				u.slowUntil = fight.seconds + sting.seconds
				u.slowBy = sting.slow
				hit.slow = true
				status(riders, attacker, u, "slowed", sting.seconds, nil)
			end
			if special and u.hp > 0 then
				local key = if extra then extra.skill else nil
				-- (a special's own riders: "all" knocks its foes off the beat itself; a several-blow one only on its first blow)
				if special.stun and special.kind ~= "all" and (extra == nil or extra.n == nil or extra.n == 1) then
					Combat.stun(fight, u, special.stun, riders, attacker, key)
				end
				if special.slow then
					if attacker.class then
						local seconds = if u.rank == "boss" then special.bossSeconds or special.seconds else special.seconds
						hit.slow = classSlow(fight, u, special.slow, seconds, riders, attacker, key)
					else
						u.slowUntil = fight.seconds + special.slowSeconds
						u.slowBy = special.slow
						hit.slow = true
						status(riders, attacker, u, "slowed", special.slowSeconds, key)
					end
				end
			end
			table.insert(events, hit)
			if endedWard then
				table.insert(events, { kind = "status", to = u.id, status = "warded", seconds = 0 })
			end
			for _, rider in riders do
				table.insert(events, rider)
			end
		else
			table.insert(events, hit)
			if endedWard then
				table.insert(events, { kind = "status", to = u.id, status = "warded", seconds = 0 })
			end
		end
		if u.hp <= 0 then
			table.insert(events, event("fallen", u))
		end
	end
end

-- The living fighters of the other side.
local function foesOf(fight: Fight, attacker: Unit): { Unit }
	local out: { Unit } = {}
	for _, other in fight.units do
		if other.side ~= attacker.side and other.hp > 0 then
			table.insert(out, other)
		end
	end
	return out
end

-- The fighter's skill (Config.Combat.Skills, by its way of fighting) instead of a plain blow.
local function skill(fight: Fight, attacker: Unit, target: Unit, events: { Event })
	local key = attacker.skillKey
	local s = (Config.Combat.Skills :: any)[key]
	if s.kind == "mend" then
		-- (its wounded were mended or fell during the wind-up: a plain blow, and the mend still to come)
		blow(fight, attacker, target, 1, events)
		return
	end
	attacker.specials += 1
	local extra = { skill = key }
	if s.kind == "splash" then
		blow(fight, attacker, target, s.factor, events, extra, s)
		-- (beside it: in the positional mode only foes near the target)
		local others: { Unit } = {}
		for _, other in foesOf(fight, attacker) do
			if other ~= target and within(fight, target, other, Config.Dungeon.Move.SplashStuds) then
				table.insert(others, other)
			end
		end
		for index = 1, math.min(s.spread, #others) do
			local other = others[index]
			if other.hp > 0 then
				blow(fight, attacker, other, s.splash, events, { skill = key, splash = true }, s)
			end
		end
	elseif s.kind == "multi" then
		for n = 1, s.hits do
			if target.hp > 0 then
				blow(fight, attacker, target, s.factor, events, { skill = key, n = n }, s)
			end
		end
	elseif s.kind == "guard" then
		attacker.guardUntil = fight.seconds + s.seconds
		attacker.guardMul = s.defence
		table.insert(events, { kind = "guard", from = attacker.id, to = attacker.id, skill = key })
		status(events, attacker, attacker, "guarded", s.seconds, key)
		blow(fight, attacker, target, s.factor, events, extra, s)
	elseif s.kind == "all" then
		for _, foe in foesOf(fight, attacker) do
			-- (a guard may already have fallen taking an earlier foe's blow; in the positional mode it reaches only foes near)
			if foe.hp <= 0 or not within(fight, attacker, foe, Config.Dungeon.Move.AreaStuds) then
				continue
			end
			blow(fight, attacker, foe, s.factor, events, extra, s)
			-- (knocked off its beat)
			if foe.hp > 0 then
				Combat.stun(fight, foe, s.stun or 0, events, attacker, key)
			end
		end
	else
		blow(fight, attacker, target, s.factor, events, extra, s)
	end
end

-- The key of the special that comes next for the fighter (its list taken in turn), or nil when it has none.
local function nextKey(fighter: Unit): string?
	local count = #fighter.skills
	if count == 0 then
		return nil
	end
	return fighter.skills[fighter.specials % count + 1]
end

-- How many seconds before its next blow a fighter announces it: WindupSeconds, or the `windup` of the special that blow
-- will be (a boss's, so its charge plays whole). A mend is decided on its heal turn and keeps the usual. A wind-up special
-- whose announcement would come sooner than SpecialGap after the last one began stays a plain blow's lead.
local function leadOf(fight: Fight, fighter: Unit): number
	local c = Config.Combat
	local key = nextKey(fighter)
	local s = if key then (c.Skills :: any)[key] else nil
	if s and s.windup and s.kind ~= "mend" then
		local first = (c.Skills :: any)[fighter.skills[1]]
		local announced = fight.seconds + math.max(0, fighter.cooldown - s.windup)
		if
			((fighter.blows + 1) % first.every == 0 or fighter.owed)
			and announced - fighter.specialAt >= Config.Classes.SpecialGap - 1e-6
		then
			return s.windup
		end
	end
	return c.WindupSeconds
end

-- The key of the "mend" special a healer's `count`-th mending is (every `every`-th mending), or nil.
local function mendSpecial(healer: Unit, count: number): string?
	local key = nextKey(healer)
	local s = if key then (Config.Combat.Skills :: any)[key] else nil
	if s and s.kind == "mend" and count % s.every == 0 then
		return key
	end
	return nil
end

-- A monster healer's turn (Config.Combat.Heals): the most wounded living team-mate gets back a share of its attack
-- instead of a blow. False, and nothing done, when it is no healer or nobody is hurt. Every `every`-th mending of a healer
-- with a "mend" special heals every wounded living team-mate by `share` times its attack each. (A Healer slime is a class
-- and heals by its own rule.)
local function heal(fight: Fight, healer: Unit, events: { Event }): boolean
	local h = (Config.Combat.Heals :: any)[healer.role]
	if not h or healer.class then
		return false
	end
	local worst: Unit? = nil
	local worstShare = 1
	local wounded: { Unit } = {}
	for _, other in fight.units do
		if other ~= healer and other.side == healer.side and other.hp > 0 and other.hp < other.maxHp then
			table.insert(wounded, other)
			local share = other.hp / other.maxHp
			if share < worstShare then
				worst, worstShare = other, share
			end
		end
	end
	if not worst then
		return false
	end
	healer.mends += 1
	local key = mendSpecial(healer, healer.mends)
	if key then
		local s = (Config.Combat.Skills :: any)[key]
		healer.specials += 1
		for _, other in wounded do
			local given = math.min(other.maxHp - other.hp, healer.attack * s.share * (1 - effectOf(fight, other, "curse")))
			other.hp += given
			table.insert(events, { kind = "heal", from = healer.id, to = other.id, amount = given, skill = key })
		end
		healer.cooldown += h.extraCooldown
		return true
	end
	local amount = math.min(worst.maxHp - worst.hp, healer.attack * h.share * (1 - effectOf(fight, worst, "curse")))
	worst.hp += amount
	healer.cooldown += h.extraCooldown
	table.insert(events, { kind = "heal", from = healer.id, to = worst.id, amount = amount })
	return true
end

-- ===== The classes (docs/WEAPONS.md §3, Common skills) =====

-- The living team-mate (not itself) within `studs` with the smallest health share below `below`, or nil.
local function lowestMate(fight: Fight, u: Unit, studs: number, below: number): Unit?
	local best: Unit? = nil
	local bestShare = below
	for _, other in fight.units do
		if other ~= u and other.side == u.side and other.hp > 0 and within(fight, u, other, studs) then
			local share = other.hp / other.maxHp
			if share < bestShare then
				best, bestShare = other, share
			end
		end
	end
	return best
end

-- The share of a heal that still lands now: 1, or in a fight that fades heals the HealFade curve (straight between its
-- points, its first share before them and its last after).
local function healShare(fight: Fight): number
	local curve = Config.Classes.HealFade
	if not fight.fade then
		return 1
	end
	local t = fight.seconds
	if t <= curve[1][1] then
		return curve[1][2]
	end
	for index = 2, #curve do
		local a, b = curve[index - 1], curve[index]
		if t <= b[1] then
			return a[2] + (b[2] - a[2]) * (t - a[1]) / (b[1] - a[1])
		end
	end
	return curve[#curve][2]
end

local function classHeal(fight: Fight, healer: Unit, mate: Unit, factor: number, events: { Event }, key: string?)
	local amount = math.min(
		mate.maxHp - mate.hp,
		Combat.healAmount(healer.attack, factor) * healShare(fight) * (1 - effectOf(fight, mate, "curse"))
	)
	mate.hp += amount
	table.insert(events, { kind = "heal", from = healer.id, to = mate.id, amount = amount, skill = key })
end

-- The foes a Guardian's Taunt would take now (within its range, going for a team-mate, free to be taunted), nearest
-- first, and whether that is worth a taunt.
local function tauntable(fight: Fight, g: Unit): ({ Unit }, boolean)
	local s = (Config.Combat.Skills :: any).taunt
	local out: { Unit } = {}
	local alone = false
	for _, foe in foesOf(fight, g) do
		local prey = foe.target
		if
			prey
			and prey ~= g
			and prey.side == g.side
			and prey.hp > 0
			and foe.tauntBy == nil
			and foe.tauntFree <= fight.seconds
			and within(fight, g, foe, s.range)
		then
			table.insert(out, foe)
			if (Config.Classes.TauntAlone :: any)[foe.role] then
				alone = true
			end
		end
	end
	if fight.moves then
		table.sort(out, function(a, b)
			return distance(g, a) < distance(g, b)
		end)
	end
	return out, alone or #out >= s.minimum
end

-- The foe with the most other foes within `radius` of it (ties to the higher DEF) among those it can strike now.
local function densest(fight: Fight, u: Unit, radius: number, canHit: (Unit) -> boolean): Unit?
	local foes = foesOf(fight, u)
	local best: Unit? = nil
	local bestCount = -1
	for _, foe in foes do
		if canHit(foe) then
			local count = 0
			for _, other in foes do
				if other ~= foe and within(fight, foe, other, radius) then
					count += 1
				end
			end
			if count > bestCount or (count == bestCount and best and foe.defence > best.defence) then
				best, bestCount = foe, count
			end
		end
	end
	return best
end

-- What a class's attack skill weighs against a plain blow: its plain factor times SkillPower at its weapon's tier.
local function skillWeight(u: Unit, s: any): number
	local power = Config.Classes.SkillPower
	return kindOf(u).factor * power[math.clamp(u.tier or 1, 1, #power)] * (s.power or 1)
end

-- An area skill: the target and every other foe within `radius` of it (nearest first; a fight with no places strikes
-- `cap` foes in all), each at `weight`; `melt` on every one it strikes when the skill has one.
local function area(fight: Fight, u: Unit, target: Unit, key: string, weight: number, events: { Event }, how: How)
	local s = (Config.Combat.Skills :: any)[key]
	local others: { Unit } = {}
	for _, other in foesOf(fight, u) do
		if other ~= target and within(fight, target, other, s.radius) then
			table.insert(others, other)
		end
	end
	if fight.moves then
		table.sort(others, function(a, b)
			return distance(target, a) < distance(target, b)
		end)
	end
	local struck = { target }
	blow(fight, u, target, weight, events, { skill = key, melt = if s.melt then true else nil }, s, how)
	for index, other in others do
		if not fight.moves and index >= s.cap then
			break
		end
		table.insert(struck, other)
		blow(
			fight,
			u,
			other,
			weight,
			events,
			{ skill = key, splash = true, melt = if s.melt then true else nil },
			s,
			how
		)
	end
	if s.melt then
		for _, each in struck do
			if each.hp > 0 and addEffect(fight, each, "melt", s.melt, s.seconds) then
				status(events, u, each, "melted", s.seconds, key)
			end
		end
	end
end

-- Piercing Shot: the arrow flies from the bow through its target and on to `length` studs from the bow, and strikes
-- every foe within `width` of its flight, nearest the bow first, each at `weight` (the owner, 2026-11-13). A fight with no
-- places strikes its target only.
local function pierce(fight: Fight, u: Unit, target: Unit, key: string, weight: number, events: { Event })
	local s = (Config.Combat.Skills :: any)[key]
	local struck = { target }
	local along: { [Unit]: number } = { [target] = distance(u, target) }
	local d = along[target]
	if fight.moves and d > 1e-6 then
		local dx, dz = (target.x - u.x) / d, (target.z - u.z) / d
		for _, other in foesOf(fight, u) do
			if other ~= target then
				local ox, oz = other.x - u.x, other.z - u.z
				local t = ox * dx + oz * dz
				if t > 0 and t <= s.length and math.abs(ox * dz - oz * dx) <= s.width then
					table.insert(struck, other)
					along[other] = t
				end
			end
		end
		table.sort(struck, function(a, b)
			return along[a] < along[b]
		end)
	end
	for _, each in struck do
		local extra = { skill = key, splash = if each ~= target then true else nil }
		blow(fight, u, each, weight, events, extra, s, { ignore = s.ignore })
	end
end

-- These five skills act on a team or curse a foe; their caster need not walk into attack range to use them.
local function noReachNeeded(key: string): boolean
	return key == "healing_ring"
		or key == "squad_tonic"
		or key == "shield_wall"
		or key == "ward"
		or key == "cursed_flask"
end

-- Count the foes an area would touch. In the tools' non-positional quick fights, only its cap are struck.
local function areaCount(fight: Fight, u: Unit, target: Unit, s: any): number
	local count = 1
	for _, other in foesOf(fight, u) do
		if other ~= target and within(fight, target, other, s.radius) then
			count += 1
		end
	end
	return if fight.moves then count else math.min(count, s.cap)
end

-- The Ring centres on the most hurt reachable team member (the caster may be that member), then heals the most
-- hurt wounded members near the centre. At least two must be below the normal heal threshold before it is worth it.
local function ringMates(fight: Fight, u: Unit, s: any): { Unit }
	local centre: Unit? = nil
	local share = 1
	for _, other in fight.units do
		if other.side == u.side and other.hp > 0 and other.hp < other.maxHp and within(fight, u, other, s.range) then
			local current = other.hp / other.maxHp
			if current < share then
				centre, share = other, current
			end
		end
	end
	if not centre then
		return {}
	end
	local mates: { Unit } = {}
	local needy = 0
	for _, other in fight.units do
		if other.side == u.side and other.hp > 0 and other.hp < other.maxHp and within(fight, centre, other, s.radius) then
			table.insert(mates, other)
			if other.hp / other.maxHp < Config.Classes.HealThreshold then
				needy += 1
			end
		end
	end
	if needy < s.minimum then
		return {}
	end
	table.sort(mates, function(a, b)
		local first, second = a.hp / a.maxHp, b.hp / b.maxHp
		return if first == second then a.id < b.id else first < second
	end)
	return mates
end

-- A team buff is worthwhile only when at least two living members can attack a living foe now, including the caster.
local function attackersReady(fight: Fight, u: Unit): number
	local count = 0
	local foes = foesOf(fight, u)
	for _, mate in fight.units do
		if mate.side == u.side and mate.hp > 0 then
			local kind = kindOf(mate)
			local m = Config.Dungeon.Move
			local reach = if kind then kind.reach elseif (Config.Combat.Ranged :: any)[mate.role] then m.RangedStuds else m.MeleeStuds
			for _, enemy in foes do
				if not fight.moves or distance(mate, enemy) <= reach + m.BlowSlack then
					count += 1
					break
				end
			end
		end
	end
	return count
end

-- Find threatened team-mates in range, weakest health share first; the Guardian cannot wall itself and a Ward cannot
-- protect its caster. A foe must already be going for that team-mate.
local function threatenedMates(fight: Fight, u: Unit, range: number, below: number): ({ Unit }, number)
	local mates: { Unit } = {}
	local living = 0
	for _, mate in fight.units do
		if mate ~= u and mate.side == u.side and mate.hp > 0 then
			living += 1
			if mate.hp / mate.maxHp < below and within(fight, u, mate, range) then
				for _, enemy in foesOf(fight, u) do
					if enemy.target == mate then
						table.insert(mates, mate)
						break
					end
				end
			end
		end
	end
	table.sort(mates, function(a, b)
		local first, second = a.hp / a.maxHp, b.hp / b.maxHp
		return if first == second then a.id < b.id else first < second
	end)
	return mates, living
end

-- Snare a reachable melee pursuer first; the foe already aimed at is the fallback.
local function snareTarget(fight: Fight, u: Unit, target: Unit, canHit: (Unit) -> boolean): Unit?
	local nearest: Unit? = nil
	local best = math.huge
	for _, enemy in foesOf(fight, u) do
		local enemyKind = kindOf(enemy)
		local melee = if enemyKind then enemyKind.reach <= Config.Dungeon.Move.MeleeStuds else not (Config.Combat.Ranged :: any)[enemy.role]
		if melee and enemy.target == u and canHit(enemy) then
			local d = if fight.moves then distance(u, enemy) else 0
			if d < best then
				nearest, best = enemy, d
			end
		end
	end
	return nearest or (if canHit(target) then target else nil)
end

-- An enemy healer makes a curse useful. The lowest-health uncursed foe is the preferred target, even when beyond the
-- Alchemist's normal reach (this is a debuff rather than a flask damage blow).
local function curseTarget(fight: Fight, u: Unit): Unit?
	local enemies = foesOf(fight, u)
	local healer = false
	for _, enemy in enemies do
		if enemy.class == "healer" or (Config.Combat.Heals :: any)[enemy.role] then
			healer = true
			break
		end
	end
	if not healer then
		return nil
	end
	local best: Unit? = nil
	local share = math.huge
	for _, enemy in enemies do
		if effectOf(fight, enemy, "curse") == 0 then
			local current = enemy.hp / enemy.maxHp
			if current < share then
				best, share = enemy, current
			end
		end
	end
	return best
end

-- Decide both whether a skill is worth its cooldown and which foe (if any) it should turn toward. Re-run this at
-- impact so a group that scattered or a team already healed does not waste the cooldown.
local function classWorth(
	fight: Fight,
	u: Unit,
	target: Unit,
	key: string,
	canHit: (Unit) -> boolean
): (boolean, Unit?)
	local s = (Config.Combat.Skills :: any)[key]
	if key == "taunt" then
		local _, worth = tauntable(fight, u)
		return worth, nil
	elseif key == "mend" then
		return lowestMate(fight, u, s.range, s.threshold) ~= nil, nil
	elseif key == "dash_strike" then
		return not fight.moves and canHit(target), nil
	elseif key == "healing_ring" then
		return #ringMates(fight, u, s) > 0, nil
	elseif key == "squad_tonic" then
		return attackersReady(fight, u) >= s.minimum, nil
	elseif key == "shield_wall" then
		local mates, living = threatenedMates(fight, u, s.range, 1)
		return #mates >= (if living == 1 then s.soloMinimum else s.minimum), nil
	elseif key == "ward" then
		local mates = threatenedMates(fight, u, s.range, s.below)
		return mates[1] ~= nil, nil
	elseif key == "cursed_flask" then
		local chosen = curseTarget(fight, u)
		return chosen ~= nil, chosen
	elseif key == "snare_arrow" then
		local chosen = snareTarget(fight, u, target, canHit)
		return chosen ~= nil, chosen
	elseif key == "acid_rain" then
		return canHit(target), densest(fight, u, s.radius, canHit) or target
	elseif key == "arrow_volley" or key == "frost_burst" then
		local chosen = densest(fight, u, s.radius, canHit)
		return chosen ~= nil and areaCount(fight, u, chosen :: Unit, s) >= s.minimum, chosen
	elseif key == "area_slash" then
		return canHit(target) and areaCount(fight, u, target, s) >= s.minimum, nil
	end
	return canHit(target), nil
end

-- A ready support skill can replace an attack even when its foe is too far away for the plain blow. Common skills
-- retain their old reach and aim timing, preserving tier-one fights.
local function supportReady(fight: Fight, u: Unit, target: Unit): boolean
	local kind = kindOf(u)
	for index = math.min(u.tier or 1, #kind.skills), 2, -1 do
		local key = kind.skills[index]
		if noReachNeeded(key) and (u.skillReady[key] or math.huge) <= fight.seconds then
			local worth = classWorth(fight, u, target, key, function(_foe: Unit): boolean
				return false
			end)
			if worth then
				return true
			end
		end
	end
	return false
end

-- A class attempts its highest unlocked, ready and worthwhile skill first; each one has its own clock.
local function classAim(fight: Fight, u: Unit, target: Unit, canHit: (Unit) -> boolean): string?
	local kind = kindOf(u)
	for index = math.min(u.tier or 1, #kind.skills), 1, -1 do
		local key = kind.skills[index]
		if (u.skillReady[key] or math.huge) <= fight.seconds then
			local worth, chosen = classWorth(fight, u, target, key, canHit)
			if worth then
				if chosen then
					u.target = chosen
				end
				return key
			end
		end
	end
	return nil
end

-- A classed unit's blow: its selected skill or plain action. The five non-damaging skills each issue cast before
-- their first status or heal; Common skills keep their earlier event sequence.
local function classAct(fight: Fight, u: Unit, target: Unit, events: { Event })
	local K = Config.Classes
	local kind = kindOf(u)
	if u.skillNext then
		local key = u.skillKey
		local s = (Config.Combat.Skills :: any)[key]
		local worth, chosen = classWorth(fight, u, target, key, function(foe: Unit): boolean
			return not fight.moves or distance(u, foe) <= kind.reach + Config.Dungeon.Move.BlowSlack
		end)
		-- Common skills keep the existing cast semantics; new ones abandon an obsolete aim without spending cooldown.
		if key == kind.skills[1] or worth then
			target = chosen or target
			if chosen then
				u.target = chosen
			end
			u.skillReady[key] = fight.seconds + s.cooldown
			if key ~= kind.skills[1] then
				table.insert(events, {
					kind = "cast",
					from = u.id,
					to = if noReachNeeded(key) and key ~= "cursed_flask" then u.id else target.id,
					skill = key,
				})
			end
			if key == "taunt" then
				local foes = tauntable(fight, u)
				for index = 1, math.min(s.count, #foes) do
					local foe = foes[index]
					foe.tauntBy, foe.tauntUntil, foe.target = u, fight.seconds + s.seconds, u
					local taunt: any = { kind = "taunt", from = u.id, to = foe.id, skill = key, seconds = s.seconds }
					table.insert(events, taunt)
					status(events, u, foe, "taunted", s.seconds, key)
				end
				if addEffect(fight, u, "taken", s.taken, s.seconds) then
					status(events, u, u, "shielded", s.seconds, key)
				end
				return
			elseif key == "mend" then
				local mate = lowestMate(fight, u, s.range, 1)
				if mate then
					classHeal(fight, u, mate, s.factor, events, key)
					return
				end
			elseif key == "healing_ring" then
				local mates = ringMates(fight, u, s)
				for index = 1, math.min(s.count, #mates) do
					classHeal(fight, u, mates[index], s.factor, events, key)
				end
				return
			elseif key == "squad_tonic" then
				for _, mate in fight.units do
					if mate.side == u.side and mate.hp > 0 and addEffect(fight, mate, "dealt", s.dealt, s.seconds) then
						status(events, u, mate, "empowered", s.seconds, key)
					end
				end
				return
			elseif key == "shield_wall" then
				local mates = threatenedMates(fight, u, s.range, 1)
				for index = 1, math.min(s.count, #mates) do
					local mate = mates[index]
					if addEffect(fight, mate, "taken", s.taken, s.seconds) then
						status(events, u, mate, "walled", s.seconds, key)
					end
				end
				return
			elseif key == "ward" then
				local mates = threatenedMates(fight, u, s.range, s.below)
				local mate = mates[1]
				if mate then
					local amount = math.min(Combat.healAmount(u.attack, s.factor) * healShare(fight), mate.maxHp * s.share)
					if mate.barrierUntil <= fight.seconds or amount >= mate.barrier then
						mate.barrier, mate.barrierUntil = amount, fight.seconds + s.seconds
						status(events, u, mate, "warded", s.seconds, key)
					end
				end
				return
			elseif key == "cursed_flask" then
				if addEffect(fight, target, "curse", s.curse, s.seconds) then
					status(events, u, target, "cursed", s.seconds, key)
				end
				return
			elseif key == "dash_strike" then
				blow(fight, u, target, skillWeight(u, s), events, { skill = key }, s)
				return
			elseif key == "piercing_shot" then
				pierce(fight, u, target, key, skillWeight(u, s), events)
				return
			elseif s.kind == "single" then
				local weight = skillWeight(u, s)
				if s.barrier and target.barrierUntil > fight.seconds and target.barrier > 0 then
					weight *= s.barrier
				end
				blow(fight, u, target, weight, events, { skill = key }, s, { magic = kind.magic, ignore = s.ignore })
				return
			else
				area(fight, u, target, key, skillWeight(u, s), events, { magic = kind.magic })
				return
			end
		end
	end
	if u.class == "healer" then
		local mate = lowestMate(fight, u, kind.reach, K.HealThreshold)
		if mate then
			classHeal(fight, u, mate, K.PlainHeal, events)
			return
		end
	end
	blow(fight, u, target, kind.factor, events, nil, nil, { magic = kind.magic })
end

-- ===== Walking (the positional mode) =====

-- How near a fighter must be its target to strike: a classed one by its class, a ranged one keeps its distance.
local function reachOf(attacker: Unit): number
	local m = Config.Dungeon.Move
	local kind = kindOf(attacker)
	if kind then
		return kind.reach
	end
	return if (Config.Combat.Ranged :: any)[attacker.role] then m.RangedStuds else m.MeleeStuds
end

-- Whether a blow may be aimed at or land on `target` now: always outside the positional mode.
local function canStrike(fight: Fight, attacker: Unit, target: Unit): boolean
	return not fight.moves or distance(attacker, target) <= reachOf(attacker) + Config.Dungeon.Move.BlowSlack
end

-- Nobody else (but the target) stands within MinApart of this place.
local function free(fight: Fight, mover: Unit, target: Unit?, x: number, z: number): boolean
	local apart = Config.Dungeon.Move.MinApart
	for _, other in fight.units do
		if other ~= mover and other ~= target and other.hp > 0 then
			if (other.x - x) ^ 2 + (other.z - z) ^ 2 < apart * apart then
				return false
			end
		end
	end
	return true
end

-- A fighter with a target out of its reach walks toward the place it has picked round it, at its own speed (a stung one
-- slowly), and stops where it is in reach. True when it is in reach now. A "move" event goes out when it sets off, changes
-- its mind, or every SyncSeconds of a long walk.
local function walk(fight: Fight, attacker: Unit, target: Unit, dt: number, events: { Event }): boolean
	local m = Config.Dungeon.Move
	local reach = reachOf(attacker)
	local dx, dz = attacker.x - target.x, attacker.z - target.z
	local d = math.sqrt(dx * dx + dz * dz)
	-- (in reach: it stops, unless it is still on its way and has come within MinApart of somebody)
	if d <= reach + 1e-4 and (not attacker.walking or free(fight, attacker, target, attacker.x, attacker.z)) then
		attacker.walking = false
		return true
	end
	local picked = attacker.slotOf == target.id
	local slotX, slotZ = 0, 0
	if picked then
		slotX = target.x + math.cos(attacker.slotAngle) * reach
		slotZ = target.z + math.sin(attacker.slotAngle) * reach
	end
	if not picked or not free(fight, attacker, target, slotX, slotZ) then
		local bearing = if d > 1e-6 then math.atan2(dz, dx) else 0
		local chosen = bearing
		for _, degrees in m.SlotAngles do
			local angle = bearing + math.rad(degrees)
			if
				free(fight, attacker, target, target.x + math.cos(angle) * reach, target.z + math.sin(angle) * reach)
			then
				chosen = angle
				break
			end
		end
		if not picked or chosen ~= attacker.slotAngle then
			attacker.sentAt = -math.huge
		end
		attacker.slotAngle, attacker.slotOf = chosen, target.id
		slotX = target.x + math.cos(chosen) * reach
		slotZ = target.z + math.sin(chosen) * reach
	end
	-- (monsters walk faster; in a fair fight, the Arena's, both sides are slimes and walk alike)
	local speed = Combat.walkSpeed(attacker.speed, attacker.side ~= "squad" and not fight.fair)
		* (if attacker.slowUntil > fight.seconds then 1 - attacker.slowBy else 1)
	speed = math.max(speed, 1e-3)
	local gx, gz = slotX - attacker.x, slotZ - attacker.z
	local left = math.sqrt(gx * gx + gz * gz)
	local travel = math.min(speed * dt, left)
	if left > 1e-6 then
		attacker.x += gx / left * travel
		attacker.z += gz / left * travel
	end
	local remaining = left - travel
	-- (in reach part way along the walk: it stops there)
	local near = distance(attacker, target) <= reach + 1e-4
		and (remaining <= 1e-3 or free(fight, attacker, target, attacker.x, attacker.z))
	if near then
		remaining = 0
	end
	if remaining > 0.05 and (not attacker.walking or fight.seconds - attacker.sentAt >= m.SyncSeconds) then
		attacker.sentAt = fight.seconds
		table.insert(events, {
			kind = "move",
			from = attacker.id,
			to = target.id,
			x = attacker.x,
			z = attacker.z,
			tx = slotX,
			tz = slotZ,
			seconds = remaining / speed,
		})
	end
	attacker.walking = remaining > 0.05
	return near
end

-- A Warrior whose Dash Strike is ready and whose target stands 7-18 studs away rushes to its reach instead of walking,
-- and its coming blow is the Dash Strike. True when it dashed.
local function dash(fight: Fight, u: Unit, target: Unit, events: { Event }): boolean
	local s = (Config.Combat.Skills :: any).dash_strike
	if u.class ~= "warrior" or (u.skillReady.dash_strike or math.huge) > fight.seconds then
		return false
	end
	local d = distance(u, target)
	if d < s.minStuds or d > s.maxStuds then
		return false
	end
	local reach = reachOf(u)
	local bearing = math.atan2(u.z - target.z, u.x - target.x)
	local tx, tz = target.x + math.cos(bearing) * reach, target.z + math.sin(bearing) * reach
	table.insert(events, {
		kind = "move",
		from = u.id,
		to = target.id,
		x = u.x,
		z = u.z,
		tx = tx,
		tz = tz,
		seconds = s.seconds,
		dash = true,
	})
	u.x, u.z = tx, tz
	u.walking, u.slotAngle, u.slotOf = false, bearing, target.id
	u.aimed, u.skillNext, u.skillKey = true, true, "dash_strike"
	u.cooldown = math.max(u.cooldown, s.seconds)
	table.insert(events, { kind = "aim", from = u.id, to = target.id, skill = "dash_strike" })
	return true
end

-- A Ranger's or Mage's Hop: a living foe going for it within DangerStuds, and its hop ready, it jumps up to HopStuds
-- straight away from that foe to a free spot inside the fight's radius. Its beat runs on.
local function hop(fight: Fight, u: Unit, events: { Event })
	local K = Config.Classes
	local every = if u.class then (K.HopCooldown :: any)[u.class] else nil
	if not every or u.hopReady > fight.seconds then
		return
	end
	local danger: Unit? = nil
	local nearest = K.DangerStuds
	for _, foe in foesOf(fight, u) do
		local d = distance(u, foe)
		if foe.target == u and d <= nearest then
			danger, nearest = foe, d
		end
	end
	if not danger then
		return
	end
	local dx, dz = u.x - danger.x, u.z - danger.z
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 1e-6 then
		dx, dz, length = 1, 0, 1
	end
	dx, dz = dx / length, dz / length
	for _, share in K.HopTries do
		local x, z = u.x + dx * K.HopStuds * share, u.z + dz * K.HopStuds * share
		local radius = fight.radius
		if radius then
			local r = math.sqrt(x * x + z * z)
			if r > radius then
				x, z = x * radius / r, z * radius / r
			end
		end
		if (x - u.x) ^ 2 + (z - u.z) ^ 2 > 1 and free(fight, u, nil, x, z) then
			table.insert(events, {
				kind = "move",
				from = u.id,
				to = danger.id,
				x = u.x,
				z = u.z,
				tx = x,
				tz = z,
				seconds = K.HopSeconds,
				hop = true,
			})
			u.x, u.z = x, z
			u.walking, u.sentAt = false, -math.huge
			u.hopReady = fight.seconds + every
			return
		end
	end
end

-- Moves the fight on by one step and returns what happened in it. Nothing changes once there is a winner.
function Combat.step(fight: Fight, dt: number): { Event }
	local events: { Event } = {}
	if fight.winner then
		return events
	end
	local c = Config.Combat
	fight.seconds += dt
	for _, attacker in fight.units do
		if attacker.hp > 0 then
			if attacker.barrierUntil <= fight.seconds then
				attacker.barrier = 0
			end
			local kind = kindOf(attacker)
			if fight.moves and kind then
				hop(fight, attacker, events)
			end
			-- (positional mode: a fighter that has announced its blow stands still; any other walks toward its target, and
			-- until it is in reach its beat stops short of the announcement)
			local inReach = true
			if fight.moves and not attacker.aimed then
				local target = targetOf(fight, attacker)
				if target then
					inReach = if kind and supportReady(fight, attacker, target)
						then true
						else dash(fight, attacker, target, events) or walk(fight, attacker, target, dt, events)
				else
					attacker.walking = false
				end
			end
			local before = attacker.cooldown
			local lead = leadOf(fight, attacker)
			-- (a stung fighter's beat runs slow)
			attacker.cooldown -= dt * (if attacker.slowUntil > fight.seconds then 1 - attacker.slowBy else 1)
			if not inReach then
				attacker.cooldown = math.max(attacker.cooldown, math.min(before, lead + 0.001))
			end
			-- the blow is announced a moment before it lands, so the client can show the wind-up (and the skill's name)
			if not attacker.aimed and attacker.cooldown <= lead then
				local target = targetOf(fight, attacker)
				if target and not canStrike(fight, attacker, target) and not (kind and supportReady(fight, attacker, target)) then
					-- (positional mode: a target picked just now is out of reach; it walks there first)
					attacker.cooldown = lead + 0.001
				elseif target then
					attacker.aimed = true
					local key = nextKey(attacker)
					local s = if key then (c.Skills :: any)[key] else nil
					if kind then
						local own = classAim(fight, attacker, target, function(foe: Unit): boolean
							return canStrike(fight, attacker, foe)
						end)
						target = attacker.target or target
						attacker.skillNext = own ~= nil
						key = own
					elseif s and s.kind == "mend" then
						-- (a mend special is announced on the heal turn; a healer with nobody wounded strikes a plain blow)
						attacker.skillNext = false
						if mendSpecial(attacker, attacker.mends + 1) then
							for _, other in fight.units do
								if
									other ~= attacker
									and other.side == attacker.side
									and other.hp > 0
									and other.hp < other.maxHp
								then
									attacker.skillNext = true
									break
								end
							end
						end
					else
						local first = (c.Skills :: any)[attacker.skills[1]]
						local turn = s ~= nil and ((attacker.blows + 1) % first.every == 0 or attacker.owed)
						if turn and s.windup then
							-- (a wind-up special only when its full charge was announced, SpecialGap after the last began;
							-- too early, this blow is plain and the special waits for the next)
							if lead < s.windup - 1e-6 then
								attacker.owed, turn = true, false
							else
								attacker.owed, attacker.specialAt = false, fight.seconds
								-- (the gap opened part way through a beat: the blow waits so its charge still plays whole)
								if before < s.windup then
									attacker.cooldown = s.windup
								end
							end
						end
						attacker.skillNext = turn
					end
					attacker.skillKey = key or ""
					table.insert(events, {
						kind = "aim",
						from = attacker.id,
						to = (target :: Unit).id,
						skill = if attacker.skillNext then key else nil,
					})
				end
			end
			if attacker.cooldown <= 0 then
				attacker.aimed = false
				-- (a little off the beat each time, so fighters of the same speed drift apart; a class has its own beat)
				attacker.cooldown += Combat.cooldown(attacker.speed) * (if kind then kind.beat else 1) * (1 + (fight.rng:next() * 2 - 1) * c.CooldownJitter)
				if heal(fight, attacker, events) then
					attacker.skillNext = false
					continue
				end
				local target = targetOf(fight, attacker)
				if not target and fight.open then
					-- (no foe in the arena yet: it waits for the next one and opens at its own moment, as at the start)
					attacker.cooldown = c.OpeningCooldown + fight.rng:next() * c.OpeningSpread
				end
				if
					target
					and not canStrike(fight, attacker, target)
					and not (kind and attacker.skillNext and noReachNeeded(attacker.skillKey))
				then
					-- (positional mode: its target fell or went out of reach during the wind-up; it walks to it and aims again)
					attacker.cooldown = leadOf(fight, attacker) + 0.001
					attacker.skillNext = false
				elseif target then
					attacker.blows += 1
					if kind then
						classAct(fight, attacker, target, events)
					elseif attacker.skillNext then
						skill(fight, attacker, target, events)
					else
						blow(fight, attacker, target, 1, events)
					end
					attacker.skillNext = false
					-- (a special with a wind-up longer than the beat waits for it: it lands its `windup` after this blow)
					attacker.cooldown = math.max(attacker.cooldown, leadOf(fight, attacker))
				end
			end
		end
	end
	local squad, foes = 0, 0
	for _, each in fight.units do
		if each.hp > 0 then
			if each.side == "squad" then
				squad += 1
			else
				foes += 1
			end
		end
	end
	if squad == 0 or (foes == 0 and not fight.open) then
		fight.winner = if squad > 0 then "squad" else "foe"
	end
	return events
end

return Combat
