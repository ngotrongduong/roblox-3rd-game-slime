--!nocheck
-- The kitchen on the real VillageSim: hungry slimes, food made and eaten, dishes by rarity and what selling them earns
-- beside the fights. lune run tools/balance/kitchen_sim.luau [hours] [productive fraction]
local process = require("@lune/process")
local Kitchen = require("./kitchen_lib")
local Model = require("./income_model")

local hours = tonumber(process.args[1]) or 12
local productive = tonumber(process.args[2]) or 0.55
Kitchen.setProductive(productive)

local variants = {
	{ name = "A: dishes sold, no fights", opts = { mode = "sell" } },
	{ name = "B: dishes sold, fighters' extra hunger (25 fights/h)", opts = { mode = "sell", fighters = true } },
	{ name = "C: slimes eat dishes (autoDish), nothing sold, fighters", opts = { mode = "autoDish", fighters = true } },
}
print(string.format("%d h measured after 4 h warm-up, productive fraction %.2f", hours, productive))
for _, variant in variants do
	print("\n" .. variant.name)
	print(
		"level slimes cooks fight hungryMax hungry% lowest | raw/h rawEaten/h dishEaten/h | made/h  com unc rare epic | coins/h  fights/h  share"
	)
	for _, level in { 1, 10, 20, 30, 40, 50 } do
		variant.opts.hours = hours
		local r = Kitchen.run(level, variant.opts)
		local fights = Model.fightIncome(level)
		print(
			string.format(
				"%5d %6d %5d %5d %9d %7.1f %6.1f | %5.0f %10.0f %12.0f | %6.1f %4.1f %3.1f %4.1f %4.1f | %7.0f %9.0f %5.1f%%",
				level,
				r.slimes,
				r.cooks,
				r.fighters,
				r.hungryMax,
				r.hungryShare * 100,
				r.lowest,
				r.raw,
				r.rawEaten,
				r.dishEaten,
				r.made,
				r.cooked.common / hours,
				r.cooked.uncommon / hours,
				r.cooked.rare / hours,
				r.cooked.epic / hours,
				r.coins,
				fights,
				r.coins / fights * 100
			)
		)
	end
end
