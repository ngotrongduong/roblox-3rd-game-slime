--!strict
-- What each Robux good DOES to a farm (docs/MONETIZATION.md §2), pure: the server (server/Purchases) asks Roblox, then calls
-- `redeem` here inside PlayerData.update, so a real receipt and the Studio test grant take exactly the same road. The goods
-- are Config.Robux.Products; what each does is read from its own fields. Gold packs are plain coins, never multiplied by a boost
-- and never held by the vault; potions add to the time left; a good that cannot be used at the moment it is paid (a redraw,
-- a Streak Saver after the day turned) is banked in the save, so nothing paid for is ever lost.
local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Rewards = if script then require(script.Parent.Rewards) else require("./Rewards")

type Farm = typeof(FarmState.newFarm(0))
type Product = typeof(Config.Robux.Products[1])

local Products = {}

-- ===== the catalog =====

function Products.get(key: string): Product?
	for _, product in Config.Robux.Products do
		if product.key == key then
			return product
		end
	end
	return nil
end

-- The good a developer product id (or game pass id) belongs to; 0 never matches (a good that is not on Roblox yet).
local function byId(kind: string, id: number): Product?
	if type(id) ~= "number" or id == 0 then
		return nil
	end
	for _, product in Config.Robux.Products do
		if product.kind == kind and product.id == id then
			return product
		end
	end
	return nil
end

function Products.byProductId(id: number): Product?
	return byId("product", id)
end

function Products.byPassId(id: number): Product?
	return byId("pass", id)
end

-- Whether the good is a paid random item (wheel spins, the Starter Pack holds some): hidden and refused where the player's
-- region restricts them (PolicyService.ArePaidRandomItemsRestricted).
function Products.paidRandom(product: Product): boolean
	return product.spins ~= nil or (product.starter ~= nil and product.starter.spins > 0)
end

-- ===== may it be bought now =====

local function waitingEggs(farm: Farm, now: number): number
	local count = 0
	for _, egg in farm.eggs do
		if egg.hatchAt == nil or egg.hatchAt > now then
			count += 1
		end
	end
	return count
end

local function tiredSlimes(farm: Farm): number
	local count = 0
	for _, slime in farm.slimes do
		if slime.ghostUntil == nil and slime.needs.energy < Config.Needs.Start then
			count += 1
		end
	end
	return count
end

-- Whether a prompt for this good may open (the server asks before it prompts, so nobody pays for what would do nothing):
-- (true) or (false, reason): "UNKNOWN", "OWNED", "NEEDS_PASS", "BETTER_OWNED" (a lower Perm Luck than the one owned),
-- "STARTER_BOUGHT", "RESTRICTED" (a paid random item where the region forbids it), "NO_EGGS", "NOT_TIRED", "NO_QUEST",
-- "NOT_BROKEN" (the check-in run is not broken by exactly one missed day).
function Products.canBuy(farm: Farm, key: string, now: number, restricted: boolean?): (boolean, string?)
	local product = Products.get(key)
	if not product then
		return false, "UNKNOWN"
	elseif restricted and Products.paidRandom(product) then
		return false, "RESTRICTED"
	end
	if product.kind == "pass" then
		if Boosts.owns(farm, key) then
			return false, "OWNED"
		elseif product.requires and not Boosts.owns(farm, product.requires) then
			return false, "NEEDS_PASS"
		elseif product.luck and Boosts.permLuck(farm) >= product.luck then
			return false, "BETTER_OWNED"
		end
		return true, nil
	end
	if product.starter and farm.robux.starterBought then
		return false, "STARTER_BOUGHT"
	elseif product.effect == "hatchAll" and waitingEggs(farm, now) == 0 then
		return false, "NO_EGGS"
	elseif product.effect == "energy" and tiredSlimes(farm) == 0 then
		return false, "NOT_TIRED"
	elseif product.effect == "reroll" and #farm.rewards.quests.list == 0 then
		return false, "NO_QUEST"
	elseif product.effect == "saver" and not Rewards.mendable(farm, now) then
		return false, "NOT_BROKEN"
	end
	return true, nil
end

-- ===== effects =====

-- Eggs already in their clock hatch `factor` times faster from now on (a hatch boost that starts while they are growing).
local function speedUpEggs(farm: Farm, now: number, factor: number)
	if factor <= 1 then
		return
	end
	for _, egg in farm.eggs do
		if egg.hatchAt ~= nil and egg.hatchAt > now then
			FarmState.retimeEgg(egg, now, now + (egg.hatchAt - now) / factor)
			egg.status = FarmState.eggStatus(egg, now)
		end
	end
end

-- Every egg still growing hatches at the next village step, through the same road as any other (VillageSim: hatchAt reached).
-- Running it again changes nothing. Returns how many eggs it moved.
local function hatchAll(farm: Farm, now: number): number
	local moved = 0
	for _, egg in farm.eggs do
		if egg.hatchAt == nil or egg.hatchAt > now then
			egg.hatchAt = math.max(egg.createdAt, now)
			egg.status = FarmState.eggStatus(egg, now)
			moved += 1
		end
	end
	return moved
end

-- Every living slime's energy full and awake (a fallen one is not revived by a drink). Returns how many it filled.
local function fillEnergy(farm: Farm): number
	local filled = 0
	for _, slime in farm.slimes do
		if slime.ghostUntil == nil then
			if slime.needs.energy < Config.Needs.Start then
				filled += 1
			end
			slime.needs.energy = Config.Needs.Start
			slime.sleeping = nil
		end
	end
	return filled
end

-- A Roblox answer about a game pass: the farm's mirror of it. Returns whether it changed. A VIP that starts now speeds the eggs
-- in progress up (new eggs are timed with it from the start, shared/Breeding).
function Products.setPass(farm: Farm, key: string, owned: boolean, now: number): boolean
	local product = Products.get(key)
	if not product or product.kind ~= "pass" then
		return false
	end
	local had = farm.robux.passes[key] == true
	if had == owned then
		return false
	end
	if owned then
		farm.robux.passes[key] = true
	else
		farm.robux.passes[key] = nil
	end
	if owned and product.vip then
		-- (a Hatch Potion already running has sped them up once: only the VIP's own factor is added)
		speedUpEggs(farm, now, Config.Robux.HatchFactorVip)
	end
	return true
end

-- ===== a purchase =====

-- Hands the good `key` to the farm (a developer product; a pass is owned through setPass). (true, what it gave, for the log) or
-- (false, "UNKNOWN").
function Products.grant(farm: Farm, key: string, now: number): (boolean, string)
	local product = Products.get(key)
	if not product or product.kind ~= "product" then
		return false, "UNKNOWN"
	end
	if product.gold then
		local coins = product.gold * Rewards.coinBase(farm)
		farm.coins += coins
		return true, "gold " .. coins
	elseif product.spins then
		Rewards.pay(farm, { coins = 0, luck = 0, spins = product.spins, items = {} }, now)
		return true, "spins " .. product.spins
	elseif product.potion and product.minutes then
		local kind = product.potion
		local running = Boosts.active(farm, kind, now)
		local ends = Boosts.addPotion(farm, kind, product.minutes * 60, now)
		if kind == "hatch" and not running then
			speedUpEggs(farm, now, Config.Robux.HatchFactorPotion)
		end
		return true, kind .. " potion until " .. ends
	elseif product.effect == "energy" then
		-- (nobody tired when the receipt came: the drink is banked, used from the shop when someone is)
		if tiredSlimes(farm) == 0 then
			farm.robux.drinks += 1
			return true, "energy drink banked " .. farm.robux.drinks
		end
		return true, "energy for " .. fillEnergy(farm) .. " slimes"
	elseif product.effect == "hatchAll" then
		if waitingEggs(farm, now) == 0 then
			farm.robux.hatchAlls += 1
			return true, "hatch all banked " .. farm.robux.hatchAlls
		end
		return true, "hatched " .. hatchAll(farm, now) .. " eggs"
	elseif product.effect == "reroll" then
		farm.robux.rerolls += 1
		return true, "quest redraw banked " .. farm.robux.rerolls
	elseif product.effect == "saver" then
		if Rewards.mendStreak(farm, now) then
			return true, "check-in run mended"
		end
		farm.robux.savers += 1
		return true, "streak saver banked " .. farm.robux.savers
	elseif product.starter then
		-- (once an account; a second one that got paid anyway, two servers racing, is still given: it was bought)
		local starter = product.starter
		local coins = starter.gold * Rewards.coinBase(farm)
		farm.coins += coins
		-- (the luck is a paid potion: added to the time left, never capped like a reward's)
		Boosts.addPotion(farm, "luck", starter.luckMinutes * 60, now)
		Rewards.pay(farm, { coins = 0, luck = 0, spins = starter.spins, items = starter.items }, now)
		farm.robux.starterBought = true
		return true, "starter pack, gold " .. coins
	end
	return false, "UNKNOWN"
end

-- Spends one banked Energy Drink or Hatch All Now (a good that did nothing when it was paid, `grant`). (true) or (false, why):
-- "UNKNOWN", "NONE" (none banked), "NOT_TIRED" / "NO_EGGS" (still nothing to do: nothing is spent).
function Products.useBanked(farm: Farm, key: string, now: number): (boolean, string?)
	local product = Products.get(key)
	if not product or product.kind ~= "product" then
		return false, "UNKNOWN"
	elseif product.effect == "energy" then
		if farm.robux.drinks <= 0 then
			return false, "NONE"
		elseif tiredSlimes(farm) == 0 then
			return false, "NOT_TIRED"
		end
		fillEnergy(farm)
		farm.robux.drinks -= 1
		return true, nil
	elseif product.effect == "hatchAll" then
		if farm.robux.hatchAlls <= 0 then
			return false, "NONE"
		elseif waitingEggs(farm, now) == 0 then
			return false, "NO_EGGS"
		end
		hatchAll(farm, now)
		farm.robux.hatchAlls -= 1
		return true, nil
	end
	return false, "UNKNOWN"
end

-- Whether this receipt is already in the save.
function Products.hasReceipt(farm: Farm, receiptId: string): boolean
	return table.find(farm.robux.receipts, receiptId) ~= nil
end

-- Writes the receipt into the save (newest last, only the newest Config.Robux.ReceiptsKept stay). False when it was there.
function Products.takeReceipt(farm: Farm, receiptId: string): boolean
	if Products.hasReceipt(farm, receiptId) then
		return false
	end
	table.insert(farm.robux.receipts, receiptId)
	while #farm.robux.receipts > Config.Robux.ReceiptsKept do
		table.remove(farm.robux.receipts, 1)
	end
	return true
end

-- One purchase, once: the receipt is written and the good granted in the same change. (true, "GRANTED", detail), (true,
-- "DUPLICATE") when the receipt was already granted (answered as granted so Roblox stops asking), or (false, "UNKNOWN").
function Products.redeem(farm: Farm, key: string, receiptId: string, now: number): (boolean, string, string?)
	if Products.hasReceipt(farm, receiptId) then
		return true, "DUPLICATE", nil
	end
	local ok, detail = Products.grant(farm, key, now)
	if not ok then
		return false, detail, nil
	end
	Products.takeReceipt(farm, receiptId)
	return true, "GRANTED", detail
end

return Products
