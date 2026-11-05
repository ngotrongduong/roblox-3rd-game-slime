--!strict
-- What Robux passes and potions DO to a farm (docs/MONETIZATION.md §2), read in one place so the rules that care (luck, coins
-- earned, hatching, teams, slime room) never look at the save's fields themselves. Pure: it reads `farm.robux.passes` (the
-- passes Roblox said the player owns, kept in the save by server/Purchases so a rule needs no service to ask) and the potion
-- end times (`farm.boosts.gold` / `.hatch`, and `farm.luckPotionUntil` for the luck potion that the rewards also pay).
-- The farm is typed loosely on purpose: hand-built farms of older specs have none of these fields and mean "nothing owned".
local Config = if script then require(script.Parent.Config) else require("./Config")

local Boosts = {}

local function passes(farm: any): { [string]: boolean }
	local robux = farm.robux
	if type(robux) == "table" and type(robux.passes) == "table" then
		return robux.passes
	end
	return {}
end

-- Whether the farm's owner has the pass `key` (Config.Robux.Products, kind "pass").
function Boosts.owns(farm: any, key: string): boolean
	return passes(farm)[key] == true
end

function Boosts.isVip(farm: any): boolean
	return Boosts.owns(farm, "vip")
end

-- The Perm Luck label: only the highest tier owned counts (1 when none).
function Boosts.permLuck(farm: any): number
	local best = 1
	for _, product in Config.Robux.Products do
		local tier = product.luck
		if tier and Boosts.owns(farm, product.key) then
			best = math.max(best, tier)
		end
	end
	return best
end

-- When a potion runs out: "luck" | "gold" | "hatch" (0 when it never ran).
function Boosts.endsAt(farm: any, kind: string): number
	if kind == "luck" then
		return farm.luckPotionUntil or 0
	end
	local boosts = farm.boosts
	return if type(boosts) == "table" and type(boosts[kind]) == "number" then boosts[kind] else 0
end

function Boosts.active(farm: any, kind: string, now: number): boolean
	return Boosts.endsAt(farm, kind) > now
end

-- Seconds a potion has left (0 when none).
function Boosts.left(farm: any, kind: string, now: number): number
	return math.max(0, Boosts.endsAt(farm, kind) - now)
end

-- Adds `seconds` of a potion to the time it has left (a second potion starts when the first ends). Returns the new end.
function Boosts.addPotion(farm: any, kind: string, seconds: number, now: number): number
	local ends = math.max(now, Boosts.endsAt(farm, kind)) + seconds
	if kind == "luck" then
		farm.luckPotionUntil = ends
	else
		farm.boosts[kind] = ends
	end
	return ends
end

-- ===== coins earned =====

-- The factor on coins EARNED now: VIP 1.5 x, a Gold Potion 2 x, both together 3 x.
function Boosts.coinFactor(farm: any, now: number): number
	local factor = 1
	if Boosts.isVip(farm) then
		factor *= Config.Robux.CoinFactorVip
	end
	if Boosts.active(farm, "gold", now) then
		factor *= Config.Robux.CoinFactorPotion
	end
	return factor
end

-- An amount of coins earned (a fight, a sale, a reward) with the boosts on it, to a whole coin. Robux gold packs never come
-- through here.
function Boosts.earn(farm: any, amount: number, now: number): number
	local factor = Boosts.coinFactor(farm, now)
	if factor == 1 then
		return amount
	end
	return math.floor(amount * factor + 0.5)
end

-- ===== hatching =====

-- How many times faster eggs hatch now: VIP 1.5 x, a Hatch Potion 2 x, both 3 x.
function Boosts.hatchFactor(farm: any, now: number): number
	local factor = 1
	if Boosts.isVip(farm) then
		factor *= Config.Robux.HatchFactorVip
	end
	if Boosts.active(farm, "hatch", now) then
		factor *= Config.Robux.HatchFactorPotion
	end
	return factor
end

-- ===== room =====

-- Teams the passes add on top of what the village has opened.
function Boosts.extraTeams(farm: any): number
	local count = 0
	for _, product in Config.Robux.Products do
		if product.teams and Boosts.owns(farm, product.key) then
			count += product.teams
		end
	end
	return count
end

-- Slime slots the passes add (Bigger Ranch).
function Boosts.extraSlots(farm: any): number
	local count = 0
	for _, product in Config.Robux.Products do
		if product.slots and Boosts.owns(farm, product.key) then
			count += product.slots
		end
	end
	return count
end

return Boosts
