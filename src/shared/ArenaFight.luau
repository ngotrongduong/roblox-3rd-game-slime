--!strict
local Classes = if script then require(script.Parent.Classes) else require("./Classes")
local Combat = if script then require(script.Parent.Combat) else require("./Combat")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Gear = if script then require(script.Parent.Gear) else require("./Gear")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

type Farm = typeof(FarmState.newFarm(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])
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
	-- (never set here: an Arena fighter stands in its class's row, Combat.unit)
	row: string?,
	skills: { string }?,
	-- (where it starts on the field: set by simulate, ArenaFight.spot)
	x: number?,
	z: number?,
}
-- The builder takes these exact attributes; plain rivals need only Colour (adult scale is its default).
export type Look = { Colour: string, Material: string?, DualId: string?, SecretId: string? }
export type Snapshot = { fighters: { Fighter }, looks: { Look }, power: number }
type Events = typeof(Combat.step(Combat.new({}, {}, Rng.new(0)), 0))
export type Replay = { won: boolean, seconds: number, steps: { { t: number, events: Events } } }
local ArenaFight = {}

function ArenaFight.fighter(slime: Slime, prefix: string): Fighter
	local bonus = Gear.bonus(slime)
	local stats = slime.stats
	local fighter: Fighter = {
		id = prefix .. slime.id,
		attack = stats.attack + bonus.attack,
		defence = stats.defence + bonus.defence,
		speed = stats.speed + bonus.speed,
		hp = stats.hp + bonus.hp,
		maxHp = stats.hp + bonus.hp,
	}
	fighter.class, fighter.tier = Classes.ofSlime(slime)
	fighter.role = fighter.class or Combat.role(fighter, slime.seed)
	fighter.skills = if fighter.class then {} else nil
	return fighter
end

function ArenaFight.power(fighters: { Fighter }): number
	local sum = 0
	for _, fighter in fighters do
		sum += fighter.attack + fighter.defence + fighter.speed + fighter.hp / Config.Stats.HpPerLevel
	end
	return math.round(sum)
end

function ArenaFight.snapshot(farm: Farm, slimeIds: { string }): Snapshot?
	if #slimeIds == 0 or #slimeIds > Config.Arena.TeamSize then
		return nil
	end
	local fighters: { Fighter } = {}
	local looks: { Look } = {}
	local seen: { [string]: boolean } = {}
	for _, id in slimeIds do
		local slime = FarmState.findSlime(farm, id)
		-- A repeated id would put the same owned slime in two seats and make replay targets ambiguous.
		if not slime or seen[id] then
			return nil
		end
		seen[id] = true
		table.insert(fighters, ArenaFight.fighter(slime, ""))
		local appearance = slime.appearanceMutation
		table.insert(looks, {
			Colour = slime.visibleColour,
			Material = if appearance.type == "material" then appearance.definitionId else nil,
			DualId = if appearance.type == "dual" then appearance.definitionId else nil,
			SecretId = if appearance.type == "secret" then appearance.definitionId else nil,
		})
	end
	return { fighters = fighters, looks = looks, power = ArenaFight.power(fighters) }
end

-- Where the `index`-th of `count` fighters of a side starts, flat from the field's middle: +z is the attackers' side (the
-- player's, in the replay), x across it; side by side, every other one a step back. The replay stands its bodies here.
function ArenaFight.spot(index: number, count: number, attacker: boolean): (number, number)
	local R = Config.Arena.View.Replay
	local sign = if attacker then 1 else -1
	return (index - (count + 1) / 2) * R.Spacing * sign, (R.SideGap - (index % 2) * R.Stagger) * sign
end

-- The fight is fought by places, as the Slime Dungeon's (the owner, 2026-11-13: one equipment system, the same fight
-- everywhere): both teams start on their side of the field and walk into reach.
function ArenaFight.simulate(attackers: { Fighter }, defenders: { Fighter }, seed: number): Replay
	local function side(fighters: { Fighter }, prefix: string): { Fighter }
		local out: { Fighter } = {}
		local seen: { [string]: boolean } = {}
		for index, fighter in fighters do
			assert(not seen[fighter.id], "Arena fighter ids must be unique within a team")
			seen[fighter.id] = true
			local copy = table.clone(fighter)
			copy.id = prefix .. fighter.id
			copy.x, copy.z = ArenaFight.spot(index, #fighters, prefix == "a:")
			table.insert(out, copy)
		end
		return out
	end
	local R = Config.Arena.View.Replay
	local fight = Combat.new(
		side(attackers, "a:"),
		side(defenders, "d:"),
		Rng.new(seed),
		{ fair = true, fade = true, moves = true, radius = R.FieldRadius - R.EdgeMargin }
	)
	local steps: { { t: number, events: Events } } = {}
	local dt, limit = Config.Zombies.FightStepSeconds, Config.Arena.MaxFightSeconds
	-- the damage each side has dealt, for a fight that runs to the limit
	local dealt: { [string]: number } = { a = 0, d = 0 }
	-- Compute the endpoint from the step number so floating-point drift cannot add a step past the deadline.
	for index = 1, math.ceil(limit / dt) do
		local endpoint = math.min(index * dt, limit)
		local events = Combat.step(fight, endpoint - fight.seconds)
		for _, event in events do
			if event.kind == "hit" and event.amount and event.from then
				local by = event.from:sub(1, 1)
				dealt[by] = (dealt[by] or 0) + event.amount
			end
		end
		if #events > 0 then
			table.insert(steps, { t = fight.seconds, events = events })
		end
		if fight.winner then
			break
		end
	end
	if not fight.winner then
		-- (at the limit: more slimes standing, then more health in percent, then more damage dealt; a tie holds)
		local standing: { [string]: number } = { squad = 0, foe = 0 }
		local health: { [string]: number } = { squad = 0, foe = 0 }
		local full: { [string]: number } = { squad = 0, foe = 0 }
		for _, u in fight.units do
			full[u.side] += u.maxHp
			if u.hp > 0 then
				standing[u.side] += 1
				health[u.side] += u.hp
			end
		end
		local function ahead(a: number, d: number): boolean?
			if math.abs(a - d) < 1e-9 then
				return nil
			end
			return a > d
		end
		local won = ahead(standing.squad, standing.foe)
		if won == nil then
			won = ahead(health.squad / math.max(1, full.squad), health.foe / math.max(1, full.foe))
		end
		if won == nil then
			won = ahead(dealt.a, dealt.d)
		end
		return { won = won == true, seconds = fight.seconds, steps = steps }
	end
	return { won = fight.winner == "squad", seconds = fight.seconds, steps = steps }
end

-- What the replay needs of one side, in team order (the order of its looks): the event id simulate gives each fighter
-- (prefix "a:" or "d:"), its role, its health and the weapon it holds (`hand`, a gear id; nil for a Brawler).
function ArenaFight.view(
	fighters: { Fighter },
	prefix: string
): { { id: string, role: string?, hp: number, maxHp: number, hand: string? } }
	local out = {}
	for _, fighter in fighters do
		table.insert(out, {
			id = prefix .. fighter.id,
			role = fighter.role,
			hp = fighter.hp,
			maxHp = fighter.maxHp or fighter.hp,
			hand = Classes.handOf(fighter.class, fighter.tier),
		})
	end
	return out
end

return ArenaFight
