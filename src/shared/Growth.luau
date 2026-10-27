--!strict
-- Baby → adult growth (docs/reference/01-core-farm.md §4.2). Growth is never stored: it is
-- derived from the slime's createdAt, its level and the Faster Growth upgrade level.

local Config = if script then require(script.Parent.Config) else require("./Config")

local Growth = {}

-- Rounds to whole milliseconds, like the original (which worked in ms), so the numbers match it.
local function roundMs(seconds: number): number
	return math.round(seconds * 1000) / 1000
end

function Growth.speedMultiplier(growthLevel: number?): number
	local g = Config.Growth
	return g.UpgradeFactor ^ math.min(g.UpgradeMaxLevel, growthLevel or 0)
end

-- Seconds from hatch to adult: 303 s for a level-4 baby with no upgrade.
function Growth.growUpSeconds(level: number, growthLevel: number?): number
	local g = Config.Growth
	local base = g.GrowUpSeconds + math.max(0, level - 1) * g.GrowUpPerLevelSeconds
	return roundMs(base * Growth.speedMultiplier(growthLevel))
end

-- Seconds until adult; 0 for adults.
function Growth.remainingSeconds(createdAt: number, now: number, level: number, growthLevel: number?): number
	return math.max(0, Growth.growUpSeconds(level, growthLevel) - math.max(0, now - createdAt))
end

-- A baby is a slime still growing: it cannot breed yet.
function Growth.isBaby(createdAt: number, now: number, level: number, growthLevel: number?): boolean
	return Growth.remainingSeconds(createdAt, now, level, growthLevel) > 0
end

-- Draw scale: BabyScale at hatch, easing to 1 at adulthood.
function Growth.scale(createdAt: number, now: number, level: number, growthLevel: number?): number
	local t = math.clamp((now - createdAt) / Growth.growUpSeconds(level, growthLevel), 0, 1)
	local baby = Config.Growth.BabyScale
	return baby + (1 - baby) * t
end

return Growth
