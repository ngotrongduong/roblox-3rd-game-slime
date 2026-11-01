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
}
export type Fight = { units: { Unit }, rng: Rng, seconds: number, winner: string? }
export type Event = { kind: string, from: string?, to: string, amount: number?, crit: boolean? }
export type Fighter = { id: string, attack: number, defence: number, speed: number, hp: number }

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

local function unit(fighter: Fighter, side: string): Unit
	return {
		id = fighter.id,
		side = side,
		attack = fighter.attack,
		defence = fighter.defence,
		speed = fighter.speed,
		hp = fighter.hp,
		maxHp = fighter.hp,
		cooldown = Config.Combat.OpeningCooldown,
	}
end

function Combat.new(squad: { Fighter }, foes: { Fighter }, rng: Rng): Fight
	local units: { Unit } = {}
	for _, fighter in squad do
		table.insert(units, unit(fighter, "squad"))
	end
	for _, fighter in foes do
		table.insert(units, unit(fighter, "foe"))
	end
	return { units = units, rng = rng, seconds = 0 }
end

local function pick(fight: Fight, side: string): Unit?
	local alive: { Unit } = {}
	for _, other in fight.units do
		if other.side ~= side and other.hp > 0 then
			table.insert(alive, other)
		end
	end
	return if #alive > 0 then alive[math.floor(fight.rng:next() * #alive) + 1] else nil
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
			attacker.cooldown -= dt
			if attacker.cooldown <= 0 then
				attacker.cooldown += Combat.cooldown(attacker.speed)
				local target = attacker.target
				if not target or target.hp <= 0 then
					target = pick(fight, attacker.side)
					attacker.target = target
				end
				if target then
					if fight.rng:next() < math.min(c.DodgeCap, target.speed * c.DodgePerSpeed) then
						table.insert(events, { kind = "dodge", from = attacker.id, to = target.id })
					else
						local amount = Combat.damage(attacker.attack, target.defence)
						local crit = attacker.side == "squad"
							and fight.rng:next() < math.min(c.CritCap, c.CritBase + attacker.speed * c.CritPerSpeed)
						if crit then
							amount *= c.CritFactor
						end
						target.hp = math.max(0, target.hp - amount)
						table.insert(
							events,
							{ kind = "hit", from = attacker.id, to = target.id, amount = amount, crit = crit }
						)
						if target.hp <= 0 then
							table.insert(events, { kind = "fallen", from = attacker.id, to = target.id })
						end
					end
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
	if squad == 0 or foes == 0 then
		fight.winner = if squad > 0 then "squad" else "foe"
	end
	return events
end

return Combat
