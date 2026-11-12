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
	skills: { string }?,
	-- (where it starts in a positional fight, which the Arena never is: Combat.Fighter's fields, kept so the types agree)
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

function ArenaFight.simulate(attackers: { Fighter }, defenders: { Fighter }, seed: number): Replay
	local function side(fighters: { Fighter }, prefix: string): { Fighter }
		local out: { Fighter } = {}
		local seen: { [string]: boolean } = {}
		for _, fighter in fighters do
			assert(not seen[fighter.id], "Arena fighter ids must be unique within a team")
			seen[fighter.id] = true
			local copy = table.clone(fighter)
			copy.id = prefix .. fighter.id
			table.insert(out, copy)
		end
		return out
	end
	local fight = Combat.new(side(attackers, "a:"), side(defenders, "d:"), Rng.new(seed), { fair = true })
	local steps: { { t: number, events: Events } } = {}
	local dt, limit = Config.Zombies.FightStepSeconds, Config.Arena.MaxFightSeconds
	-- Compute the endpoint from the step number so floating-point drift cannot add a step past the deadline.
	for index = 1, math.ceil(limit / dt) do
		local endpoint = math.min(index * dt, limit)
		local events = Combat.step(fight, endpoint - fight.seconds)
		if #events > 0 then
			table.insert(steps, { t = fight.seconds, events = events })
		end
		if fight.winner then
			break
		end
	end
	return { won = fight.winner == "squad", seconds = fight.seconds, steps = steps }
end

-- What the replay needs of one side, in team order (the order of its looks): the event id simulate gives each fighter
-- (prefix "a:" or "d:"), its role and its health.
function ArenaFight.view(
	fighters: { Fighter },
	prefix: string
): { { id: string, role: string?, hp: number, maxHp: number } }
	local out = {}
	for _, fighter in fighters do
		table.insert(
			out,
			{ id = prefix .. fighter.id, role = fighter.role, hp = fighter.hp, maxHp = fighter.maxHp or fighter.hp }
		)
	end
	return out
end

return ArenaFight
