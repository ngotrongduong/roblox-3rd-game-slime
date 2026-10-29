--!strict
-- Pure village needs: rates are per minute, never per frame.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Needs = {}

export type Values = { fullness: number, energy: number, fun: number }

function Needs.tick(values: Values, activity: string, seconds: number, baby: boolean?): Values
	local n = Config.Needs
	local minutes = math.max(0, seconds) / Config.Village.StepSeconds
	local fullnessRate = if activity == "work" then n.WorkFullnessPerMinute else n.IdleFullnessPerMinute
	if baby then
		fullnessRate *= n.BabyFactor
	end
	local energyDelta = if activity == "sleep"
		then n.SleepEnergyPerMinute
		elseif activity == "work" then -n.WorkEnergyPerMinute
		else -n.IdleEnergyPerMinute
	return {
		fullness = math.clamp(values.fullness - minutes * fullnessRate, 0, n.Max),
		energy = math.clamp(values.energy + minutes * energyDelta, 0, n.Max),
		fun = math.clamp(values.fun - minutes * n.FunFallPerMinute, 0, n.Max),
	}
end

function Needs.eatValue(values: Values, fullness: number): Values
	return {
		fullness = math.clamp(values.fullness + math.max(0, fullness), 0, Config.Needs.Max),
		energy = values.energy,
		fun = values.fun,
	}
end

function Needs.wantsFood(values: Values): boolean
	return values.fullness <= Config.Needs.WantsFood
end

function Needs.isHungry(values: Values): boolean
	return values.fullness <= Config.Needs.Hungry
end

function Needs.isTired(values: Values): boolean
	return values.energy <= Config.Needs.Tired
end

function Needs.rested(values: Values): boolean
	return values.energy >= Config.Needs.Rested
end

function Needs.canPair(values: Values): boolean
	return values.fullness >= Config.Needs.PairFullness and not Needs.isTired(values)
end

function Needs.workFactor(values: Values): number
	return if Needs.isHungry(values) then Config.Needs.HungryWorkFactor else 1
end

return Needs
