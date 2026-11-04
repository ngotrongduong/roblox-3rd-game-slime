--!strict
-- A fight between two sides, pure and seeded: the original's formulas (docs/reference/02-battle.md §8) without its
-- positions. Where units stand is for the client to draw; a hit lands when its cooldown ends.
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
	-- the coming blow has been announced (an "aim" event, WindupSeconds before it lands)
	aimed: boolean,
	-- how it fights: a slime's role (Combat.role), a zombie's kind
	role: string,
	-- blows struck so far (every Skills[role].every-th is its skill), and whether the coming one is
	blows: number,
	skillNext: boolean,
	-- a guard covers its team-mates until this many seconds into the fight
	guardUntil: number,
	-- stung slow: until this many seconds into the fight its beat runs at (1 - slowBy) speed
	slowUntil: number,
	slowBy: number,
}
-- `open`: more foes are still to come (the dungeon's queue), so the fight does not end when the foes in it are down; a
-- squad wiped out ends it all the same.
export type Fight = { units: { Unit }, rng: Rng, seconds: number, winner: string?, open: boolean?, fair: boolean? }
-- `skill` is the way of fighting whose skill struck (a key of Config.Combat.Skills); `n` the blow's number in a
-- several-blow skill; `splash` a blow that struck beside the target; `guard` the guard that took a blow aimed elsewhere;
-- `ranged` a blow from a fighter that keeps its distance; `slow` a sting that slowed its target. A "heal" event carries
-- the health given back in `amount`.
export type Event = {
	kind: string,
	from: string?,
	to: string,
	amount: number?,
	crit: boolean?,
	skill: string?,
	n: number?,
	splash: boolean?,
	guard: string?,
	ranged: boolean?,
	slow: boolean?,
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
	kind: string?,
}

local Combat = {}

function Combat.damage(raw: number, defence: number): number
	local c = Config.Combat
	local reduction = math.min(c.DefenceCap, defence / (defence + c.DefenceK))
	-- (not rounded as in the original: at the low stats here, rounding made one level up double the damage)
	return math.max(c.MinDamage, raw * c.DamageScale * (1 - reduction))
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

-- (each fighter opens at its own moment: a team that strikes all at once reads as one body, not four slimes)
local function unit(fighter: Fighter, side: string, rng: Rng): Unit
	local c = Config.Combat
	local role = fighter.role or fighter.kind or ""
	-- (each counts its blows from its own start, so fighters of one kind do not strike their skills all together)
	local s = (c.Skills :: any)[role]
	local blows = if s then math.floor(rng:next() * s.every) else 0
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
		blows = blows,
		skillNext = false,
		guardUntil = 0,
		slowUntil = 0,
		slowBy = 0,
	}
end

function Combat.new(squad: { Fighter }, foes: { Fighter }, rng: Rng, opts: { fair: boolean? }?): Fight
	local units: { Unit } = {}
	for _, fighter in squad do
		table.insert(units, unit(fighter, "squad", rng))
	end
	for _, fighter in foes do
		table.insert(units, unit(fighter, "foe", rng))
	end
	return { units = units, rng = rng, seconds = 0, fair = if opts then opts.fair else nil }
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

-- Whom a fighter goes for, by its way of fighting (Config.Combat.Aims): the one with the least health left, the one that
-- hits hardest, or anyone, though a guard draws more of the blows (Config.Combat.Pull).
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
		total += (c.Pull :: any)[other.role] or 1
	end
	local roll = fight.rng:next() * total
	for _, other in alive do
		roll -= (c.Pull :: any)[other.role] or 1
		if roll <= 0 then
			return other
		end
	end
	return alive[#alive]
end

-- A guard of the target's side that covers it now (not the target itself), or nil.
local function guardOf(fight: Fight, target: Unit): Unit?
	for _, other in fight.units do
		if other ~= target and other.side == target.side and other.hp > 0 and other.guardUntil > fight.seconds then
			return other
		end
	end
	return nil
end

-- One blow of `attacker` at `target`, `factor` times its usual weight: a guard may take it, the target may dodge it, a
-- slime's may crit. `extra` goes into the events (the skill, the blow's number, a splash).
local function blow(
	fight: Fight,
	attacker: Unit,
	target: Unit,
	factor: number,
	events: { Event },
	extra: { [string]: any }?
)
	local c = Config.Combat
	local guard = guardOf(fight, target)
	local struck = guard or target
	local function event(kind: string): Event
		local out: any = { kind = kind, from = attacker.id, to = struck.id, guard = if guard then guard.id else nil }
		if extra then
			for key, value in extra do
				out[key] = value
			end
		end
		if (c.Ranged :: any)[attacker.role] then
			out.ranged = true
		end
		return out
	end
	if fight.rng:next() < math.min(c.DodgeCap, struck.speed * c.DodgePerSpeed) then
		table.insert(events, event("dodge"))
		return
	end
	local defence = struck.defence * (if guard then (c.Skills :: any).defence.defence else 1)
	local amount = Combat.damage(attacker.attack, defence) * factor
	local crit = (attacker.side == "squad" or fight.fair == true)
		and fight.rng:next() < math.min(c.CritCap, c.CritBase + attacker.speed * c.CritPerSpeed)
	if crit then
		amount *= c.CritFactor
	end
	struck.hp = math.max(0, struck.hp - amount)
	local hit = event("hit")
	hit.amount, hit.crit = amount, crit
	-- (only a plain blow stings: a skill has its own weight)
	local sting = if extra == nil then (c.Stings :: any)[attacker.role] else nil
	if sting and struck.hp > 0 then
		struck.slowUntil = fight.seconds + sting.seconds
		struck.slowBy = sting.slow
		hit.slow = true
	end
	table.insert(events, hit)
	if struck.hp <= 0 then
		table.insert(events, event("fallen"))
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
	local s = (Config.Combat.Skills :: any)[attacker.role]
	local extra = { skill = attacker.role }
	if s.kind == "splash" then
		blow(fight, attacker, target, s.factor, events, extra)
		local others = foesOf(fight, attacker)
		for index = 1, math.min(s.spread, #others) do
			local other = others[index]
			if other ~= target and other.hp > 0 then
				blow(fight, attacker, other, s.splash, events, { skill = attacker.role, splash = true })
			end
		end
	elseif s.kind == "multi" then
		for n = 1, s.hits do
			if target.hp > 0 then
				blow(fight, attacker, target, s.factor, events, { skill = attacker.role, n = n })
			end
		end
	elseif s.kind == "guard" then
		attacker.guardUntil = fight.seconds + s.seconds
		table.insert(events, { kind = "guard", from = attacker.id, to = attacker.id, skill = attacker.role })
		blow(fight, attacker, target, s.factor, events, extra)
	elseif s.kind == "all" then
		for _, foe in foesOf(fight, attacker) do
			-- (a guard may already have fallen taking an earlier foe's blow)
			if foe.hp <= 0 then
				continue
			end
			blow(fight, attacker, foe, s.factor, events, extra)
			-- (knocked off its beat)
			foe.cooldown += s.stun or 0
		end
	else
		blow(fight, attacker, target, s.factor, events, extra)
	end
end

-- A healer's turn (Config.Combat.Heals): the most wounded living team-mate gets back a share of its attack instead of a
-- blow. False, and nothing done, when it is no healer or nobody is hurt.
local function heal(fight: Fight, healer: Unit, events: { Event }): boolean
	local h = (Config.Combat.Heals :: any)[healer.role]
	if not h then
		return false
	end
	local worst: Unit? = nil
	local worstShare = 1
	for _, other in fight.units do
		if other ~= healer and other.side == healer.side and other.hp > 0 and other.hp < other.maxHp then
			local share = other.hp / other.maxHp
			if share < worstShare then
				worst, worstShare = other, share
			end
		end
	end
	if not worst then
		return false
	end
	local amount = math.min(worst.maxHp - worst.hp, healer.attack * h.share)
	worst.hp += amount
	healer.cooldown += h.extraCooldown
	table.insert(events, { kind = "heal", from = healer.id, to = worst.id, amount = amount })
	return true
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
			-- (a stung fighter's beat runs slow)
			attacker.cooldown -= dt * (if attacker.slowUntil > fight.seconds then 1 - attacker.slowBy else 1)
			-- the blow is announced a moment before it lands, so the client can show the wind-up (and the skill's name)
			if not attacker.aimed and attacker.cooldown <= c.WindupSeconds then
				local target = attacker.target
				if not target or target.hp <= 0 then
					target = pick(fight, attacker)
					attacker.target = target
				end
				if target then
					attacker.aimed = true
					local s = (c.Skills :: any)[attacker.role]
					attacker.skillNext = s ~= nil and (attacker.blows + 1) % s.every == 0
					table.insert(events, {
						kind = "aim",
						from = attacker.id,
						to = target.id,
						skill = if attacker.skillNext then attacker.role else nil,
					})
				end
			end
			if attacker.cooldown <= 0 then
				attacker.aimed = false
				-- (a little off the beat each time, so fighters of the same speed drift apart)
				attacker.cooldown += Combat.cooldown(attacker.speed) * (1 + (fight.rng:next() * 2 - 1) * c.CooldownJitter)
				if heal(fight, attacker, events) then
					attacker.skillNext = false
					continue
				end
				local target = attacker.target
				if not target or target.hp <= 0 then
					target = pick(fight, attacker)
					attacker.target = target
				end
				if not target and fight.open then
					-- (no foe in the arena yet: it waits for the next one and opens at its own moment, as at the start)
					attacker.cooldown = c.OpeningCooldown + fight.rng:next() * c.OpeningSpread
				end
				if target then
					attacker.blows += 1
					if attacker.skillNext then
						skill(fight, attacker, target, events)
					else
						blow(fight, attacker, target, 1, events)
					end
					attacker.skillNext = false
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
