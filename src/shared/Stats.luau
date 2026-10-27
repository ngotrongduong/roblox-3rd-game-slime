--!strict
-- Slime stats and levels (docs/reference/01-core-farm.md §3). The level is never stored: it is
-- always computed from the current stats, so it can never drift from them.

local Config = if script then require(script.Parent.Config) else require("./Config")

local Stats = {}

export type Stats = {
	attack: number,
	defence: number,
	speed: number,
	hp: number,
}

-- Stat names in the original order; the improvement roll picks from this list by index.
Stats.Keys = { "attack", "defence", "speed", "hp" }

local function limits(key: string): { min: number, max: number }
	return (Config.Stats.Limits :: any)[key]
end

-- A fresh copy of the starter stats (level 4).
function Stats.starter(): Stats
	local s = Config.Stats.Starter
	return { attack = s.attack, defence = s.defence, speed = s.speed, hp = s.hp }
end

function Stats.copy(stats: Stats): Stats
	return { attack = stats.attack, defence = stats.defence, speed = stats.speed, hp = stats.hp }
end

function Stats.get(stats: Stats, key: string): number
	return (stats :: any)[key]
end

function Stats.set(stats: Stats, key: string, value: number)
	(stats :: any)[key] = value
end

-- floor(attack + defence + speed + hp / 10): 4 for the starters, 1296 at the limits.
function Stats.level(stats: Stats): number
	return math.floor(stats.attack + stats.defence + stats.speed + stats.hp / Config.Stats.HpPerLevel)
end

function Stats.clamp(key: string, value: number): number
	local l = limits(key)
	return math.clamp(value, l.min, l.max)
end

function Stats.clampAll(stats: Stats): Stats
	return {
		attack = Stats.clamp("attack", stats.attack),
		defence = Stats.clamp("defence", stats.defence),
		speed = Stats.clamp("speed", stats.speed),
		hp = Stats.clamp("hp", stats.hp),
	}
end

local function isFiniteNumber(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- Breeding refuses a parent unless every stat is a finite number above zero.
function Stats.isUsable(raw: any): boolean
	if type(raw) ~= "table" then
		return false
	end
	for _, key in Stats.Keys do
		local v = raw[key]
		if not isFiniteNumber(v) or v <= 0 then
			return false
		end
	end
	return true
end

-- Field-level repair of loaded stats: a bad stat becomes the starter value, others are rounded
-- and clamped. Always returns a fresh, valid table.
function Stats.validate(raw: any, warnings: { string }, prefix: string): Stats
	local source = raw
	if type(source) ~= "table" then
		table.insert(warnings, prefix .. ": missing, starter stats applied")
		source = {}
	end
	local starter = Config.Stats.Starter :: any
	local out = {}
	for _, key in Stats.Keys do
		local v = source[key]
		local l = limits(key)
		if not isFiniteNumber(v) then
			if type(raw) == "table" then
				table.insert(warnings, prefix .. "." .. key .. ": invalid, reset to " .. tostring(starter[key]))
			end
			out[key] = starter[key]
		else
			local n = math.round(v)
			if n < l.min or n > l.max then
				table.insert(warnings, prefix .. "." .. key .. ": out of range, clamped")
				n = math.clamp(n, l.min, l.max)
			elseif n ~= v then
				table.insert(warnings, prefix .. "." .. key .. ": not an integer, rounded")
			end
			out[key] = n
		end
	end
	return (out :: any) :: Stats
end

return Stats
