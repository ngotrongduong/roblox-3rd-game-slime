--!strict
-- The Lucky Wheel: one free spin a UTC day (lost at midnight), a VIP's extra one, a bank that never expires, a roll that is
-- the server's alone and by the stated odds, and a prize paid once through the rewards' own pay.
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Rewards = require("../../src/shared/Rewards")
local Rng = require("../../src/shared/Rng")
local Wheel = require("../../src/shared/Wheel")

local DAY = 86400
local NOW = 20000 * DAY + 12 * 3600
local W = Config.Wheel

-- A dice that lands in the middle of slice `index` (the weights in Config order).
local function landing(index: number): any
	local total, before = Wheel.totalWeight(), 0
	for i = 1, index - 1 do
		before += W.Slices[i].weight
	end
	return Rng.sequence({ (before + W.Slices[index].weight / 2) / total })
end

local function sliceIndex(id: string): number
	for i, slice in W.Slices do
		if slice.id == id then
			return i
		end
	end
	error("no slice " .. id)
end

return function(T: any)
	T.test("the nine slices and their weights are the approved ones", function()
		T.eq(#W.Slices, 9)
		T.eq(Wheel.totalWeight(), 100)
		local expected = {
			coinsSmall = 26,
			coinsBig = 14,
			food = 14,
			luck = 12,
			ore = 10,
			fragment = 9,
			spin = 7,
			core = 5,
			jackpot = 3,
		}
		for _, slice in W.Slices do
			T.eq(slice.weight, expected[slice.id], slice.id)
		end
		local farm: any = FarmState.newFarm(NOW)
		local base = Rewards.coinBase(farm)
		local view = Wheel.view(farm, NOW)
		T.eq(#view.slices, 9)
		T.near(view.slices[1].chance, 26, 1e-9)
		T.ok(view.slices[1].coins >= Config.Rewards.CoinFloor, "small coins never fall under the floor")
		T.near(view.slices[2].coins, 1.5 * base, 1.5 * base * 0.05, "big coins are one and a half")
		T.eq(view.slices[9].luck, 60)
		T.eq(view.slices[9].items[1].id, "boss_essence")
		T.eq(view.slices[3].items[1].kind, "food")
	end)

	T.test("one free spin a day; with none left a spin is refused and changes nothing", function()
		local farm: any = FarmState.newFarm(NOW)
		T.eq(Wheel.freeSpins(farm, NOW, false), 1)
		T.eq(Wheel.spinsLeft(farm, NOW, false), 1)
		local ok, why, index, grant = Wheel.spin(farm, landing(sliceIndex("fragment")), NOW, false)
		T.ok(ok and index == sliceIndex("fragment") and grant, tostring(why))
		T.eq(Wheel.freeSpins(farm, NOW + 60, false), 0)
		T.eq(farm.lifetime.wheelSpins, 1)
		local before = {
			coins = farm.coins,
			materials = table.clone(farm.materials),
			wheel = table.clone(farm.rewards.wheel),
		}
		-- (a roll that would have landed on the jackpot: it must not even be thrown)
		local again, reason, none, nothing = Wheel.spin(farm, Rng.sequence({}), NOW + 60, false)
		T.same({ again, reason, none, nothing }, { false, "NO_SPIN", nil, nil })
		T.eq(farm.coins, before.coins, "a refusal pays nothing")
		T.same(farm.materials, before.materials)
		T.same(farm.rewards.wheel, before.wheel)
		T.eq(farm.lifetime.wheelSpins, 1, "a refused spin is not counted")
	end)

	T.test("the free spin is used before the bank and lost at midnight while the bank stays", function()
		local farm: any = FarmState.newFarm(NOW)
		farm.rewards.wheel.bank = 3
		-- a prize that pays nothing into the bank (fragments)
		local fragment = sliceIndex("fragment")
		T.eq(Wheel.spinsLeft(farm, NOW, false), 4)
		local ok, _, index = Wheel.spin(farm, landing(fragment), NOW, false)
		T.ok(ok)
		T.eq(index, fragment)
		T.eq(farm.rewards.wheel.bank, 3, "the free spin went first")
		T.eq(Wheel.freeSpins(farm, NOW, false), 0)
		-- the bank is spent next
		Wheel.spin(farm, landing(fragment), NOW + 10, false)
		T.eq(farm.rewards.wheel.bank, 2)
		-- the free spin comes back at the next UTC midnight, the bank is never touched by the day
		local midnight = (Rewards.dayOf(NOW) + 1) * DAY
		T.eq(Wheel.freeSpins(farm, midnight - 1, false), 0)
		T.eq(Wheel.freeSpins(farm, midnight, false), 1)
		T.eq(farm.rewards.wheel.bank, 2)
		-- a free spin not used on its day is lost: three days later there is still one, not four
		T.eq(Wheel.freeSpins(farm, midnight + 2 * DAY, false), 1)
		T.eq(Wheel.spinsLeft(farm, midnight + 2 * DAY, false), 3)
		Wheel.spin(farm, landing(fragment), midnight + 2 * DAY, false)
		T.eq(Wheel.freeSpins(farm, midnight + 2 * DAY, false), 0)
		T.eq(farm.rewards.wheel.bank, 2)
	end)

	T.test("a VIP has one more free spin a day", function()
		local farm: any = FarmState.newFarm(NOW)
		T.eq(Wheel.freeSpins(farm, NOW, true), 2)
		T.eq(Wheel.freeMax(true), 2)
		T.eq(Wheel.freeMax(false), 1)
		local fragment = sliceIndex("fragment")
		T.ok((Wheel.spin(farm, landing(fragment), NOW, true)))
		T.ok((Wheel.spin(farm, landing(fragment), NOW, true)))
		T.eq(Wheel.freeSpins(farm, NOW, true), 0)
		T.eq((Wheel.spin(farm, landing(fragment), NOW, true)), false)
		-- without the pass the same day shows no free spin left
		T.eq(Wheel.freeSpins(farm, NOW, false), 0)
	end)

	T.test("each slice pays what the wheel shows", function()
		local base = Rewards.coinBase(FarmState.newFarm(NOW))
		for index, slice in W.Slices do
			local farm: any = FarmState.newFarm(NOW)
			local coins = farm.coins
			local ok, _, got, grant = Wheel.spin(farm, landing(index), NOW, false)
			T.ok(ok, slice.id)
			T.eq(got, index)
			T.eq(farm.coins, coins + grant.coins, slice.id)
			if slice.reward.coins then
				-- (two figures: 225 is paid as 230)
				T.eq(grant.coins, Rewards.grant(slice.reward, FarmState.newFarm(NOW)).coins, slice.id)
			end
			if slice.reward.luck then
				T.eq(farm.luckPotionUntil, NOW + slice.reward.luck * 60, slice.id)
			end
			for _, item in slice.reward.items or {} do
				local held = if item.kind == "material"
					then farm.materials[item.id]
					elseif item.kind == "food" then farm.storehouse[item.id]
					else farm.gear[item.id]
				T.ok((held or 0) >= item.count, slice.id .. " " .. item.id)
			end
			-- the free spin was used; the +1 spin slice puts one into the bank
			T.eq(farm.rewards.wheel.bank, slice.reward.spins or 0, slice.id)
			T.eq(farm.lifetime.wheelSpins, 1)
		end
		-- the jackpot is the three prizes together
		local farm: any = FarmState.newFarm(NOW)
		Wheel.spin(farm, landing(sliceIndex("jackpot")), NOW, false)
		T.eq(farm.materials.boss_essence, 1)
		T.eq(farm.luckPotionUntil, NOW + 60 * 60)
		T.eq(farm.coins, Rewards.grant({ coins = 5 }, farm).coins)
	end)

	T.test("the roll follows the odds and is the same for the same seed", function()
		local hits = {}
		local trials = 20000
		local rng = Rng.new(2024)
		local farm: any = FarmState.newFarm(NOW)
		for _ = 1, trials do
			farm.rewards.wheel = { day = 0, used = 0, bank = 0 }
			local _, _, index = Wheel.spin(farm, rng, NOW, false)
			hits[index :: number] = (hits[index :: number] or 0) + 1
		end
		for index, slice in W.Slices do
			T.near((hits[index] or 0) / trials * 100, slice.weight, 1.2, slice.id)
		end
		local a: any, b: any = FarmState.newFarm(NOW), FarmState.newFarm(NOW)
		local _, _, first = Wheel.spin(a, 99, NOW, false)
		local _, _, second = Wheel.spin(b, 99, NOW, false)
		T.eq(first, second)
	end)

	T.test("a spin counts for the wheel quest and the bank is capped for a damaged save", function()
		local farm: any = FarmState.newFarm(NOW)
		T.eq(Rewards.count(farm, "spin"), 0)
		Wheel.spin(farm, 5, NOW, false)
		T.eq(Rewards.count(farm, "spin"), 1)
		Rewards.pay(farm, { coins = 0, luck = 0, spins = 1e9 }, NOW)
		T.eq(farm.rewards.wheel.bank, W.BankCap)
	end)
end
