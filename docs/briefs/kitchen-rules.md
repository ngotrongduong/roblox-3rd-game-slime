# Brief: kitchen recipes, dish buffs, rarity by level, coin vault, upgrade prices (rules and server only)

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done. If unsure, pick the
simplest thing that fits the code around it and say so in the report.

Branch: `chatgpt/kitchen-rules` from the latest `main` (never `main`, no PR).

Read first: `CLAUDE.md`, `docs/GAMEPLAY.md` §5-6, `docs/ECONOMY.md`, `docs/LESSONS-village.md`, then `src/shared/Food.luau`,
`Stations.luau` (`setTrainingStat` is the pattern for recipes), `VillageSim.luau`, `Brain.luau`, `Shop.luau`, `Zombies.luau`, `Village.luau`,
`FarmState.luau`, `ProfileLogic.luau`, `FarmSave.luau`, `src/server/VillageRemotes.luau`, `src/server/Village.luau`, `tests/lib/FarmKit.luau`.

## The owner's words (summary)

The player tells a cook which recipe to make; it cooks only with all the ingredients. Cooking costs time and ingredients but fills more and
gives a timed buff (% attack, defence, speed or HP, 10-15 minutes). From the cooked food list the player feeds a chosen slime now, or sets
it to eat that dish by itself when hungry. Surplus dishes sell at the shop. Fish and vegetables have rarity, so dishes do too, with matching
buff and price. Kitchen level: faster cooking and higher rarities. Pond and garden level: rarer catches. Pantry level: more food and more cash
storage. Upgrades now cost real coins.

## Build

### Config (`src/shared/Config.luau`; every number here, none in logic)

`Config.Food.DishRarities` (cook seconds at kitchen level 1; the existing `Stations` level factor still applies):

| rarity | kitchenLevel | percent | buffSeconds | cookSeconds | price |
|---|---|---|---|---|---|
| common | 1 | 8 | 600 | 120 | 300 |
| uncommon | 8 | 12 | 660 | 150 | 800 |
| rare | 20 | 18 | 780 | 200 | 2500 |
| epic | 35 | 25 | 900 | 300 | 10000 |

`Config.Food.Dishes` (16; keep the three existing ids and their ingredients; each gets `rarity`; `percent`, duration, seconds and price come
from the rarity, not per dish). `DishOrder` lists them by rarity then attack, defence, speed, hp. Remove `BuffSeconds`.

| id | name | ingredients | stat | fullness | rarity |
|---|---|---|---|---|---|
| grilledFish | Grilled Fish | fish 2 | attack | 60 | common |
| veggieStew | Veggie Stew | carrot 2, cabbage 1 | defence | 65 | common |
| blueFishSkewer | Blue Fish Skewer | blueFish 2 | speed | 60 | common |
| fishVegSoup | Fish and Veggie Soup | fish 1, carrot 1, cabbage 1 | hp | 90 | common |
| bakedTrout | Baked Trout | trout 1, fish 1 | attack | 70 | uncommon |
| cornChowder | Corn Chowder | corn 1, cabbage 1, carrot 1 | defence | 85 | uncommon |
| sweetCornSalad | Sweet Corn Salad | corn 1, tomato 1 | speed | 70 | uncommon |
| tomatoFishStew | Tomato Fish Stew | tomato 1, blueFish 1 | hp | 75 | uncommon |
| salmonSteak | Salmon Steak | salmon 1, tomato 1 | attack | 80 | rare |
| pumpkinStew | Pumpkin Stew | pumpkin 1, corn 1 | defence | 85 | rare |
| pufferfishRolls | Pufferfish Rolls | pufferfish 1, cabbage 1 | speed | 80 | rare |
| salmonPumpkinBisque | Salmon Pumpkin Bisque | salmon 1, pumpkin 1 | hp | 100 | rare |
| goldenCarpFeast | Golden Carp Feast | goldenCarp 1, salmon 1 | attack | 100 | epic |
| starfruitGlazedPuffer | Starfruit Glazed Puffer | starfruit 1, pufferfish 1 | defence | 100 | epic |
| starfruitTart | Starfruit Tart | starfruit 1, pumpkin 1 | speed | 100 | epic |
| goldenBanquet | Golden Banquet | goldenCarp 1, starfruit 1 | hp | 100 | epic |

`Config.Food.DefaultRecipe = "grilledFish"`, `Config.Food.CookReservePerSlime = 1`.

`Config.Food.Kinds`: add `topWeight` (the weight at area level 50; `weight` stays the level 1 weight, linear between; each group's sum is 100):
fish 25, blueFish 20, trout 30, salmon 13, pufferfish 7, goldenCarp 5, carrot 23, cabbage 22, tomato 17, corn 13, pumpkin 20, starfruit 5.

Vault: `Config.Village.CoinCapMin = 2000`, `CoinCapPriceFactor = 3`.

Upgrade prices: `Config.Village.UpgradePrices`, anchors of `{ level, price }`: 1 270, 5 390, 10 840, 15 1900, 19 2600, 25 6600, 30 11000,
35 19000, 39 29000, 45 52000, 49 78000. Between anchors interpolate geometrically, rounded with the existing nice rounding (2 significant
digits); a price never falls. Remove `UpgradeBase`, `UpgradeMaxCost`, `UpgradeLastFromLevel` if nothing else reads them.
`Config.Pads.FreeUpgrades = false`.

### Rules (`src/shared`)

Food:
- `Food.roll(group, rng, level)`: weights by area level as above. Every caller passes the level of its area (`VillageSim`, `src/server/Village.luau`).
- `Food.recipeUnlocked(id, kitchenLevel)`, `Food.slotRecipe(slot, kitchenLevel)`: the slot's recipe if known and unlocked, else `DefaultRecipe`. A slot
  with no recipe therefore simply cooks the default; no assign-time code is needed.
- `Food.cookSeconds(id, kitchenLevel)`: the rarity's seconds with the same level factor as `Stations.cycleSeconds`. Every place that reads the kitchen's
  cycle (`VillageSim`, the work clock in `src/server/Village.luau`) uses it, with the speed factor as today.
- `Food.canCook(farm)`: only the fridge-room test. `cookedAllowed` is gone from the game (below).
- `Food.ingredientsWanted(farm)`: from each staffed slot's recipe, summed across slots, minus the counter, and only for recipes the counter plus storehouse can
  complete. Returns `{}` while the storehouse total is below `#farm.slimes * CookReservePerSlime`, so cooking never starves the village. Stay within
  `CounterCapacity`. `Food.bestDish` goes.
- `VillageSim` kitchen: the slot's recipe; missing an ingredient means progress 0 and waiting, nothing taken.
- `Food.cheapestRaw(stock)`: lowest rarity first, then most count, then Config order. `chooseMeal` and `Zombies.revive` use it, so rare food is kept for recipes.
- `chooseMeal`: if the slime has `autoDish` and the fridge holds it, that dish from the fridge; else raw. Nothing else eats dishes.
- `Food.eat` and a new `Food.feed(farm, slimeId, dishId, now): (boolean, string?)`: a shared private step applies fullness and sets
  `slime.buff = { stat, percent, untilTime, dish }`, replacing any buff. `feed` refuses a dead slime, an unknown dish or none in the fridge, changing nothing;
  it works at any fullness (the buff is the point).
- `Food.setAutoDish(farm, slimeId, dishId?)`: validates; nil clears.

Stations: `setCookRecipe(farm, slotIndex, recipeId): boolean`, refusing unknown or locked recipes; sets `slot.recipe`, progress 0, and moves counter items no staffed
slot's recipe needs back to the storehouse as far as they fit, so a change cannot jam the counter.

Shop: `Shop.sellDish(farm, dishId, count): (number?, string?)`: sells `min(count, held)`, needs at least one, pays the rarity's price each, adds to `lifetime.coinsEarned`.

Village: `upgradeCost` from the table; `Village.coinCap(pantryLevel) = max(CoinCapMin, CoinCapPriceFactor * upgradeCost(pantryLevel))`, at the max level using the last price.

Zombies: `pay` adds only up to the cap (`max(0, cap - coins)`), counts only what was paid and returns it; `fall` and `ZombieFights` report the amount really paid. **Sales of
slimes and dishes always pay in full and may go above the cap. Coins already held are never reduced.** Require order: check there is no cycle.

Save (`FarmState`, `ProfileLogic`, `FarmSave`, `Config.Save.SchemaVersion = 6`): `slot.recipe` (kitchen slots), `slime.autoDish`, `buff.dish` optional, all in the types, `newFarm` and `repair`;
repair drops unknown recipe and dish ids, an old buff with no dish stays valid. Remove `cookedAllowed` everywhere (type, `newFarm`, `repair`, `removeSlime`, migration). A migration 5 -> 6
keeps everything else untouched. Add it to the migration test.

### Server (`src/server`)

`VillageRemotes`: actions `SetCookRecipe { slot, recipe }`, `FeedDish { slimeId, dish }`, `SetAutoDish { slimeId, dish? }`, `SellDish { dish, count }`, validated like their neighbours (types,
integer count from 1 to the fridge capacity, ownership, the existing rate limit); `SellDish` needs the Market's range exactly as `Sell` does. Remove `SetCookedAllowed`.

`Village.luau` publishes: on each slime `BuffStat`, `BuffPercent`, `BuffUntil`, `BuffRarity` (empty or 0 when expired or none), `AutoDish`; on the root `CoinCap`, `Counter` (JSON, if not yet published),
and each kitchen slot's effective recipe in whatever attribute already carries slot data (or `CookRecipes`, a JSON list). Use the existing `set` helper so unchanged values are not rewritten. Remove `CookedAllowed`.

### Client: only what the removal needs

Remove the Cooked/Raw button in `src/client/UiBook.luau` and `CookedAllowed` in `src/client/VillageUI.luau`. Any place that assumes `dish.percent` or `Config.Food.BuffSeconds` follows the new shape. The new screens are NOT part of this job.

## Tests (Lune, `tests/spec/kitchen.luau` plus changes to existing specs)

Seeded `Rng`, fixed times. Cover: weights at level 1 and 50 sum to 100 and every group's rolls at level 50 hold more epics than at level 1; locked recipe refused, level unlocks it; a cook with a missing ingredient waits and takes nothing; cook time falls with kitchen level and rises with rarity;
two slots with different recipes order the sum; reserve holds back ingredients; recipe change clears the counter; feed sets the buff, replaces an old one, refuses when none; `autoDish` eaten when hungry, raw when out; raw eaten lowest rarity first; `Zombies.fighter` applies a speed buff; `sellDish` partial count and price; `pay` stops at the cap, sale goes over it, coins never fall; upgrade price table matches the anchors, never falls; migration 5 -> 6.
`tests/spec/food_balance.luau` must still pass unloosened, with cooks cooking.

## Gates

`tools/check.ps1` must end `CHECK OK` and `tools/types.ps1` `TYPES OK`. You cannot run them: read carefully, Claude will run them and send failures back.

## Do not touch

`Config` blocks other than those named, the world builders (`*Stages`, `tools/map`), `tools/balance`, art, `docs/` (Claude updates them). No new libraries.

## Slips to avoid

No unused variables, imports or parameters (selene; `_` prefix). Typed fields added later go in the type, `newFarm` and `repair`. Attribute reads are `any`. No require cycles. Tests use seeded `Rng` and fixed times, never `os.time()`. Tabs, comments that say why, English everywhere. Update all callers of a changed signature (grep). Do not loosen an existing test: if one fails because a rule really changed, change only that expectation and say so in the report.

## Report

Files changed, decisions you took on your own, anything left undone, every existing test expectation you changed and why.
