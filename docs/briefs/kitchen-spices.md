# Brief: spices, Legendary and Lasting dishes (slice 3 of the 2026-11-15 rebalance; rules and server only)

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
An agent that is unsure picks the simplest thing that fits the code around it and says so in its report.

## Why

The owner (2026-11-15), in short: the shop sells new cooking ingredients of several rarities at middling-to-high prices,
so the kitchen can make higher dishes with stronger or longer buffs; new recipes mix the farm's own food with the new
ingredients. Balanced, not too many new things.

## Read first

`CLAUDE.md`, `docs/briefs/kitchen-rules.md` (how the kitchen was built), `docs/GAMEPLAY.md` §5-6, `src/shared/Config.luau`
(`Config.Food`: `DishRarities`, `Dishes`, `DishOrder`, `Start`), `src/shared/Food.luau`, `src/shared/Stations.luau` (the
cook's recipe), `src/shared/Shop.luau`, `src/shared/Zombies.luau` (`fighter`: how a dish buff reaches a fight), the
auto-feed rule (Grep `autoFeed`/`AutoEat`/`hungry` in `src/shared/Brain.luau`, `VillageSim.luau`, `Food.luau`),
`src/shared/FarmState.luau`, `ProfileLogic.luau`, `FarmSave.luau`, `src/shared/VillageRequests.luau`,
`src/server/VillageRemotes.luau`, `tests/lib/FarmKit.luau`.

## Build exactly this

### 1. Spices (a store of their own)
`Config.Food.Spices`, bought for coins, kept apart from the raw food: never eaten raw, never used to revive, never
counted in the storehouse:

| id | name | rarity | price | used for |
|---|---|---|---|---|
| honey | Wild Honey | uncommon | 500 | Lasting Stew |
| truffle | Moon Truffle | epic | 8000 | Grand Lasting Stew |
| saffron | Golden Saffron | legendary | 40000 | the four Legendary dishes |

- Saved as `farm.spices = { honey, truffle, saffron }` (whole numbers, 0 at start). A new save field: bump
  `Config.SchemaVersion` to 17 with a migration that adds the zeros (the pattern of the earlier ones), plus `newFarm` and
  `repair`. Cap each at `Config.Food.SpiceCap` (99).
- Remote action `BuySpice` { spice, count } through `VillageRequests` + the server: whole count 1..10, at the Market
  (the range check the dish sale uses), coins taken and spices added in one step, refused on short coins or the cap.
- Add a `legendary` rarity to `Config.Food.Rarities` (name "Legendary", colour "#e0a020", order 5) for the spices and
  the new dishes.

### 2. Six new dishes (16 farm dishes stay exactly as they are)
`DishRarities` gains `legendary = { kitchenLevel = 45, percent = 20, buffSeconds = 1500, cookSeconds = 360, price = 0 }`.
- Four Legendary dishes, each an epic recipe plus 1 saffron, its epic dish's stat: `goldenCarpRoyale` "Golden Carp
  Royale" (goldenCarpFeast's ingredients + saffron, attack), `saffronPufferCrown` "Saffron Puffer Crown" (defence),
  `saffronStarTart` "Saffron Star Tart" (speed), `saffronBanquet` "Saffron Banquet" (hp); fullness 100.
- Two Lasting dishes, a small buff to ALL four stats for long: `lastingStew` "Lasting Stew" = honey 1 + trout 1 +
  carrot 1, kitchen level 10, +3% all, 3600 s; `lastingStewII` "Grand Lasting Stew" = truffle 1 + salmon 1 + pumpkin 1,
  kitchen level 25, +5% all, 5400 s; fullness 90. Their numbers are per dish (`stat = "all"`, `percent`, `buffSeconds`,
  `kitchenLevel`, `cookSeconds` 240), not from a rarity row; say how you fitted that into the code.
- `DishOrder`: the Lasting two after the uncommon dishes, the Legendary four last.

### 3. Rules for dishes with a spice
- One cook of a spice dish makes a batch of `Config.Food.SpiceBatch` (4) dishes into the fridge (the fridge's room
  still holds).
- A dish with a spice can never be sold (the `SellDish` action refuses it with a reason; the screen will hide its sell
  buttons: give the client a pure `Food.sellable(id)`), so buying spices, cooking and selling never makes coins.
- Still one buff per slime: a new dish replaces the old buff as today.
- Auto-feed: a slime that eats by itself never eats a buff dish while its current buff has more than
  `Config.Food.RebuffShare` (0.1) of its time left; it eats raw food instead (if there is none, it waits as today).
- `stat = "all"`: `Zombies.fighter` (and anything else that reads a dish buff, e.g. the slime sheet's numbers) raises
  attack, defence, speed and HP each by the percent. Make it one shared pure helper, not four copies.

## Tests (Lune, `tests/spec/`)
BuySpice takes the coins and adds the spices in one step and refuses short coins, the cap and a bad count; spices are not
raw food (not eaten, not revive, not in the storehouse count); a spice dish cooks a batch of 4 and needs its kitchen
level; spice dishes cannot be sold (no coin loop: buy + cook + sell is refused); auto-feed skips a buff dish while the
buff has more than 10% left and eats raw food; "all" raises all four stats in `fighter`; schema 16 -> 17 keeps
everything and adds zeros; `BuySpice` shape in `VillageRequests`.

## Gates
`& "C:\Roblox 3rd game\tools\check.ps1"` must end `CHECK OK`, `& "C:\Roblox 3rd game\tools\types.ps1"` must end
`TYPES OK`. Run `tools/balance/kitchen_sim.luau` if it exists and say what changed. Quote the gate lines in the report.

## Do not touch
`src/client/*` (Claude does the Grocer tab and the dish screens), `docs/`, git (Claude commits), the dungeon and smithy.

## Commands (the owner's hard rule: never make him click "Allow once")
One plain command per call. An inline command never contains `|`, `;`, `&&`, `Where-Object`, `Select-Object`,
`Format-Table`, `ForEach-Object`, a `{ }` script block or `$(...)`, nor a comma list or a lone `-` as an argument.
Finding files is Glob, searching text is Grep, reading is Read, every file change is Edit or Write (never sed). Anything
with several steps goes in a `.ps1` file in your scratchpad, run as `& "<path>.ps1"`.

## Slips to avoid
No unused variables (selene; `_` prefix); new typed fields go in the type, `newFarm` and `repair`; attribute reads are
`any`; tests use the seeded `Rng` and fixed times, never `os.time()`; every printed line starts with `[GooLineage]`;
every word in the game is English.

## Report
Files, what you decided where the brief left room, what the screens need (attributes published, actions), the two gate
lines.
