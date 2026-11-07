--!strict
-- A fight between two sides, pure and seeded: the original's formulas (docs/reference/02-battle.md §8) without its
-- positions. Where units stand is for the client to draw; a hit lands when its cooldown ends. Only the Slime Dungeon
-- turns on the positional mode (Combat.new's `moves`), where fighters walk into reach before they aim.
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
-- squad wiped out ends it all the same.
export type Fight = {
	units: { Unit },
	rng: Rng,
	seconds: number,
	winner: string?,
	open: boolean?,
	fair: boolean?,
	moves: boolean?,
}
-- `skill` is the way of fighting whose skill struck (a key of Config.Combat.Skills); `n` the blow's number in a
-- several-blow skill; `splash` a blow that struck beside the target; `guard` the guard that took a blow aimed elsewhere;
-- `ranged` a blow from a fighter that keeps its distance; `slow` a sting that slowed its target. A "heal" event carries
-- the health given back in `amount`. A "move" event (positional mode only) says a fighter walks: it stands at (x, z) and
-- goes to (tx, tz), which it reaches in `seconds`.
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
	x: number?,
	z: number?,
	tx: number?,
	tz: number?,
	seconds: number?,
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
	-- where it starts in the positional mode (flat, from the arena's middle)
	x: number?,
	z: number?,
}

local Combat = {}

-- How fast a fighter walks, in studs a second, from its SPD (Config.Dungeon.Move).
function Combat.walkSpeed(speed: number): number
	local m = Config.Dungeon.Move
	return math.min(m.MaxStuds, m.BaseStuds + m.PerSpeed * math.max(0, speed))
end

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
		x = fighter.x or 0,
		z = fighter.z or 0,
		slotAngle = 0,
		slotOf = "",
		walking = false,
		sentAt = 0,
	}
end

-- `moves` turns on the positional mode (only the dungeon does): each fighter has a place and walks toward its target at
-- Combat.walkSpeed until it is in reach (Config.Dungeon.Move), and neither aims nor strikes before. Off, a blow lands when
-- its cooldown ends, wherever the fighters are.
function Combat.new(squad: { Fighter }, foes: { Fighter }, rng: Rng, opts: { fair: boolean?, moves: boolean? }?): Fight
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

-- ===== Walking (the positional mode) =====

local function distance(a: Unit, b: Unit): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

-- How near a fighter must be its target to strike: a ranged one keeps its distance.
local function reachOf(attacker: Unit): number
	local m = Config.Dungeon.Move
	return if (Config.Combat.Ranged :: any)[attacker.role] then m.RangedStuds else m.MeleeStuds
end

-- Whether a blow may be aimed at or land on `target` now: always outside the positional mode.
local function canStrike(fight: Fight, attacker: Unit, target: Unit): boolean
	return not fight.moves or distance(attacker, target) <= reachOf(attacker) + Config.Dungeon.Move.BlowSlack
end

-- Nobody else (but the target) stands within MinApart of this place.
local function free(fight: Fight, mover: Unit, target: Unit, x: number, z: number): boolean
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
	local speed = Combat.walkSpeed(attacker.speed)
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
			-- (positional mode: a fighter that has announced its blow stands still; any other walks toward its target, and
			-- until it is in reach its beat stops short of the announcement)
			local inReach = true
			if fight.moves and not attacker.aimed then
				local target = attacker.target
				if not target or target.hp <= 0 then
					target = pick(fight, attacker)
					attacker.target = target
				end
				if target then
					inReach = walk(fight, attacker, target, dt, events)
				else
					attacker.walking = false
				end
			end
			local before = attacker.cooldown
			-- (a stung fighter's beat runs slow)
			attacker.cooldown -= dt * (if attacker.slowUntil > fight.seconds then 1 - attacker.slowBy else 1)
			if not inReach then
				attacker.cooldown = math.max(attacker.cooldown, math.min(before, c.WindupSeconds + 0.001))
			end
			-- the blow is announced a moment before it lands, so the client can show the wind-up (and the skill's name)
			if not attacker.aimed and attacker.cooldown <= c.WindupSeconds then
				local target = attacker.target
				if not target or target.hp <= 0 then
					target = pick(fight, attacker)
					attacker.target = target
				end
				if target and not canStrike(fight, attacker, target) then
					-- (positional mode: a target picked just now is out of reach; it walks there first)
					attacker.cooldown = c.WindupSeconds + 0.001
				elseif target then
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
				if target and not canStrike(fight, attacker, target) then
					-- (positional mode: its target fell or went out of reach during the wind-up; it walks to it and aims again)
					attacker.cooldown = c.WindupSeconds + 0.001
					attacker.skillNext = false
				elseif target then
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
