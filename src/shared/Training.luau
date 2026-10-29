--!strict
-- Independent, seeded stat gain; HP is measured in blocks of ten for the soft cap.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Rng = typeof(Rng.new(0))
type SlimeStats = typeof(Stats.starter())
local Training = {}

function Training.gainChance(statKey: string, value: number, trainingLevel: number, luck: number): number
	if not table.find(Stats.Keys, statKey) then
		return 0
	end
	local t = Config.Training
	local v = if statKey == "hp" then value / Config.Stats.HpPerLevel else value
	local soft = t.Soft / (t.Soft + math.max(1, v) - 1)
	local levelFactor = 1
		+ (math.clamp(trainingLevel, Config.Village.StartLevel, Config.Village.MaxLevel) - 1) * t.ChancePerLevel
	return math.clamp(t.Base * soft * levelFactor * math.max(0, luck), 0, Config.Mutation.ChanceCap)
end

function Training.finishSession(stats: SlimeStats, statKey: string, rng: Rng, chance: number): SlimeStats
	local out = Stats.copy(stats)
	if table.find(Stats.Keys, statKey) and rng:next() < chance then
		local add = if statKey == "hp" then Config.Training.HpGain else Config.Training.Gain
		Stats.set(out, statKey, Stats.clamp(statKey, Stats.get(out, statKey) + add))
	end
	return out
end

return Training
