--!strict
-- New-player luck (docs/reference/01-core-farm.md §4.7): once the tutorial is finished or
-- skipped, the first window plays at ×5 luck and the next at ×3, then ×1. Luck multiplies the
-- secret, dual and stat-improvement chances (each capped); never the base-colour mutation or pity.

local Config = if script then require(script.Parent.Config) else require("./Config")

local Luck = {}

-- Only the two fields luck reads, so any farm-shaped table fits.
export type LuckFarm = {
	tutorialDone: boolean?,
	tutorialDoneAt: number?,
}

function Luck.multiplier(farm: LuckFarm, now: number): number
	local at = farm.tutorialDoneAt
	if at == nil or at == 0 or farm.tutorialDone ~= true then
		return 1
	end
	local elapsed = now - at
	local window = Config.Luck.WindowSeconds
	if elapsed < 0 then
		return 1
	elseif elapsed < window then
		return Config.Luck.First
	elseif elapsed < window * 2 then
		return Config.Luck.Second
	end
	return 1
end

-- Seconds left in the current boosted window; 0 when there is no boost.
function Luck.secondsLeft(farm: LuckFarm, now: number): number
	local at = farm.tutorialDoneAt
	if at == nil or at == 0 or farm.tutorialDone ~= true then
		return 0
	end
	local elapsed = now - at
	local window = Config.Luck.WindowSeconds
	if elapsed < 0 then
		return 0
	elseif elapsed < window then
		return window - elapsed
	elseif elapsed < window * 2 then
		return window * 2 - elapsed
	end
	return 0
end

-- A luck-multiplied chance, never above the cap.
function Luck.chance(base: number, luck: number): number
	return math.min(Config.Mutation.ChanceCap, base * luck)
end

return Luck
