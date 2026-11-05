--!strict
-- New-player luck (docs/reference/01-core-farm.md §4.7): once the tutorial is finished or
-- skipped, the first window plays at ×5 luck and the next at ×3, then ×1. Luck multiplies the
-- secret, dual, material and stat-improvement chances; never Random or pity.
-- Everything Robux sells and the server hands out is a luck LABEL (docs/MONETIZATION.md §1): Perm Luck (the highest tier
-- owned), VIP, a Luck Potion and a server bonus multiply into one label, and the label becomes the real factor on the
-- chances by a falling curve, real = 1 + PerDoubling * log2(label) ("Luck x8 does not mean an 8x rate"). The new-player
-- boost stays a real factor outside the curve. The chance cap (Luck.chance) stays.

local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")
local Config = if script then require(script.Parent.Config) else require("./Config")

local Luck = {}

-- Only the fields luck reads, so any farm-shaped table fits (robux.passes: the owned passes; see shared/Boosts).
export type LuckFarm = {
	tutorialDone: boolean?,
	tutorialDoneAt: number?,
	luckPotionUntil: number?,
	robux: any?,
}

local function newPlayerMultiplier(farm: LuckFarm, now: number): number
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

-- The luck label of the owned passes and the live potion: Perm Luck x VIP x Luck Potion x the server's bonus (1 for none).
function Luck.label(farm: LuckFarm, now: number, serverBonus: number?): number
	local vip = if Boosts.isVip(farm) then Config.Luck.Vip else 1
	local potion = if Boosts.active(farm, "luck", now) then Config.Luck.Potion else 1
	return Boosts.permLuck(farm) * vip * potion * (serverBonus or Config.Luck.ServerBonus)
end

-- The real factor a label gives the chances: 1 for a label of 1 (or less), then PerDoubling more for each doubling.
function Luck.real(label: number): number
	if label <= 1 then
		return 1
	end
	return 1 + Config.Luck.PerDoubling * math.log(label, 2)
end

-- What the shop line shows: the label ("Luck x12") and the real factor ("Rare babies x2.4"), new-player luck left out.
function Luck.view(farm: LuckFarm, now: number, serverBonus: number?): (number, number)
	local label = Luck.label(farm, now, serverBonus)
	return label, Luck.real(label)
end

-- The factor on every rare chance: the new-player boost (real) times the real factor of the label.
function Luck.multiplier(farm: LuckFarm, now: number, serverBonus: number?): number
	return newPlayerMultiplier(farm, now) * Luck.real(Luck.label(farm, now, serverBonus))
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
