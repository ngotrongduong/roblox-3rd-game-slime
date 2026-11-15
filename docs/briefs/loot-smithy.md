# Brief: four dungeons' loot, family-pair recipes and Tempering (slice 2 of the 2026-11-15 rebalance)

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
An agent that is unsure picks the simplest thing that fits the code around it and says so in its report.

## Why

The owner (2026-11-15), in short: four dungeons, each drops ONE group of materials; every recipe needs at least two
groups; deeper levels drop the higher materials; mini-bosses and bosses drop the important ones for rare items; world
monsters outside the dungeon drop some craft materials too, the dungeon at a higher rate; bosses drop rare things found
only in the dungeon; dungeon-made gear is a little better than world-made gear, but a rarer tier is always better; five
tiers; a new player reaches Iron weapons easily before village level 20; few materials, easy to read.

Slice 1 is done and committed: the four dungeons (the player picks one, `run.mapId`), the shared depth
(`farm.dungeon.best`, `farm.dungeon.maps`), monster levels by band (`Dungeon.plan`, `Dungeon.stats`), schema 16.

## Read first

`CLAUDE.md`, `docs/SMITHY.md`, `src/shared/Dungeon.luau`, `src/shared/ConfigDungeon.luau` (Materials, DropOrder, the
`drops` lines of every monster), `src/shared/Config.luau` (`Config.Smithy`), `src/shared/Gear.luau`,
`src/shared/ZoneFights.luau` + `src/shared/ConfigWorld.luau` (`Reward`, `Trophy`, `Packs`), `src/shared/WorldPacks.luau`,
`src/server/Dungeon.luau` (dropsOf, clearWave), `src/server/ZombieFights.luau` (where a won pack pays its coins),
`src/shared/Guide.luau`, `src/shared/VillageRequests.luau`, the remotes in `src/server/VillageRemotes.luau`.

## Build exactly this

### 1. Materials (`Config.Dungeon.Materials`, `DropOrder`)
- New: `silk` = "Mushroom Silk" (short "Silk"), `crystal` = "Frost Crystal" (short "Crystal"), kind "material",
  `icon = ""` (the picture comes later; the screens already draw a plain tile with `short` when there is none).
- The four group materials ("basics"), one per dungeon: meadow `wood`, mushroom `silk`, lava `ore`, ice `crystal`.
  The trophies, one per dungeon: meadow `boar_tusk`, mushroom `glow_spore`, lava `ember_core`, ice `frost_fang`.
  Put both maps in Config (e.g. `Config.Dungeon.Maps.<id>.basic` / `.trophy`, or one `Groups` block).
- Catalysts, shared: `rare_part` (Core Fragment, Epic), `monster_core` (Mythic), `boss_essence` (Legendary).
- `cloth` and `common_part` stay in Materials (saves hold them) but are never dropped or asked for.
- Remove `LuckPerLevel`, `Dungeon.luck`, `Dungeon.chance` (no luck multiplier any more).

### 2. Dungeon drops (replace every monster's material lines; keep its `coins` and `food` lines as they are)
Rolled per fallen monster from its map, its role (regular = swarmer/raider/spitter/shaman/armoured) and the run's dungeon
level L. All numbers in Config (one `Loot` block in ConfigDungeon), none in logic:
- basic of the map, 1 unit: regular monsters by band of L: 1-20 20%, 21-50 24%, 51-90 30%, 91+ 40%; mini-boss 2-3
  units and boss 3-5 units always.
- clear bonus: when wave 10 is cleared, +35% (rounded) of the basics the run collected, paid with wave 10.
- `rare_part`: regulars 2% at L 21-50, 1% at 51-90, 0 from 91; mini-boss 3% at L 1-20 then 35%; boss 3% at 1-20 then 70%.
- `monster_core`: regulars 2% at 51-90, 3% from 91; mini-boss and boss 3% at 31-50, from 51 mini 50%, boss 100%.
- `boss_essence`: boss 10% at L 81 rising evenly to 25% at 99; from L 100 boss 100% (1 unit), mini-boss 20%.
- trophy of the map: mini-boss 30%, boss 100% (1 unit), every level.
Expected full clears give about 27 / 32 / 40 / 54 basics at L 1-20 / 21-50 / 51-90 / 91+: say in your report what your
tables really give (a short script or test). `rollDrops` stays seeded and pure (a line spends its rolls whether it hits or
not). The gate's list of what a dungeon drops (`client/UiDungeon.luau` `dropRanges`) must keep working: give it a pure
function that lists a map's possible drops and ranges at a level (e.g. `Dungeon.dropTable(mapId, level)`), and use it there.

### 3. World packs (the open world; `WorldPacks`, `server/ZombieFights`)
- Every pack has ONE basic: the region's own (meadow region -> wood, mushroom -> silk, ember -> ore, frost -> crystal);
  a Home Vale pack (region `vale`) gets one of the four in turn by its cell, so a new player meets all four near home.
  Pure: `WorldPacks.material(cell or pack id, x, z)`; publish it on the pack so the client can show it (an attribute).
- A won pack pays 1 unit of its basic into `farm.materials`; from pack level 60 a second unit at 50%.
  `rare_part` 1 in 6 packs from pack level 25; `monster_core` 1 in 10 from level 65. Never a trophy, never Essence.
  Seeded so a pack's drop is fixed by its roll (as its monsters are). Numbers in `Config.World.Packs`.
- Target: four exploring teams together get no more basics an hour than one team in the Dungeon (say what yours give).

### 4. Zone guards (`Config.World.Reward`)
Remove the `trophy` lines (trophies are the Dungeon's own now); keep coins and catalysts. Zone crowds drop their defs'
coins and food only.

### 5. Recipes (`Config.Smithy.Recipes`), one fixed pair of basics per family
sword ore+wood, shield ore+crystal, bow wood+silk, focus crystal+silk, staff wood+crystal, kit silk+ore,
helm ore+silk, charm crystal+wood (A first). Per tier (TierOrder wood, iron, core, bramble, legend =
Common, Uncommon, Epic, Mythic, Legendary):

| tier | A | B | catalyst | coins |
|---|---|---|---|---|
| wood | 3 | 2 | - | 0 |
| iron | 6 | 4 | - | 500 |
| core | 12 | 8 | 2 rare_part | 3000 |
| bramble | 20 | 12 | 3 monster_core | 12000 |
| legend | 30 | 20 | 5 monster_core + 2 boss_essence | 30000 |

Helm and charm cost half of every amount, rounded up. No recipe asks for a trophy. Write the table once in Config and
build the 40 recipes from it (a loop in Config is fine), not 40 hand-written lines.

### 6. Tempering ("dungeon-made is a little better")
- A tempered piece is its own gear id beside the plain one (e.g. `sword-iron-t`): the same card, +1 to the piece's main
  stat (the stat with the most points; +10 HP when HP is the main one). Only tiers iron and up. Build the tempered
  entries from the plain ones in Config (a loop), `tempered = true`, `base = <plain id>`.
- `Gear.temper(farm, plainId)`: takes one plain piece from the bag (a piece a slime wears may not be tempered; say how
  the screen should tell the player), takes the cost, adds one tempered piece; all or nothing (atomic), false + a reason
  otherwise. Cost by tier, the trophies of the family's two dungeons (the maps of A and B):
  iron 1 trophy of either of the two; core 1 of each; bramble 1 of each + 2 monster_core; legend 2 of each +
  2 boss_essence. (For "either", take the one the bag has more of.)
- Check: a tempered piece of tier N is still weaker than the plain piece of tier N+1 in every family (a test).
- Equip, unequip, sell or whatever else handles gear ids must accept tempered ids.
- Remote `SmithyTemper` through `VillageRequests` + the server, with the same range check as `SmithyCraft`
  (`env.atSmithy`) and the same rate limit; `farm.lifetime.gearCrafted` counts it like a craft.

### 7. The guide's starter kit
The Guide step that sends the player to the Smithy for the first time pays 3 of each basic (wood, silk, ore, crystal),
enough for the first Common weapon. If no such step exists, add one beside the existing Smithy/gear step. Once only.

## Tests (Lune, `tests/spec/`)
Drop tables have no luck and match the bands above; a seeded drop is the same twice; the clear bonus is paid once with
wave 10 and never on a lost wave; packs' materials by region and the Vale's rotation; recipes need two basics and the
right catalysts; Tempering is all-or-nothing (a missing trophy leaves the bag untouched), refuses a worn piece and Common;
tempered N < plain N+1; the guide pays the kit once; `SmithyTemper` shape in `VillageRequests`. Update older tests that
asked for the old drops or recipes.

## Gates
`& "C:\Roblox 3rd game\tools\check.ps1"` must end `CHECK OK`, `& "C:\Roblox 3rd game\tools\types.ps1"` must end
`TYPES OK`. Quote both last lines in your report.

## Do not touch
`src/client/*` except `UiDungeon.luau`'s `dropRanges` (Claude does the screens: UiSmithy, UiBag, pack tags), the slice-1
level model (`Dungeon.plan`, `Dungeon.stats`, `PowerCurve`, `RoleFactor`), `docs/` (Claude writes them), git (Claude
commits).

## Commands (the owner's hard rule: never make him click "Allow once")
One plain command per call. An inline command never contains `|`, `;`, `&&`, `Where-Object`, `Select-Object`,
`Format-Table`, `ForEach-Object`, a `{ }` script block or `$(...)`, nor a comma list or a lone `-` as an argument.
Finding files is Glob, searching text is Grep, reading is Read, every file change is Edit or Write (never sed). Anything
with several steps goes in a `.ps1` file in your scratchpad, run as `& "<path>.ps1"`.

## Slips to avoid
No unused variables, imports or parameters (selene; `_` prefix); typed fields added later go in the type, `newFarm` and
`repair`; attribute reads are `any`; no require cycles (Dungeon requires Zombies, Food, FarmState: do not make those
require Dungeon); tests use the seeded `Rng` and fixed times, never `os.time()`; every line printed starts with
`[GooLineage]`; every word in the game is English.

## Report
What you built (files), the drop and pack numbers your tables really give, what you decided where the brief left room,
anything that needs a screen (for Claude), the two gate lines.
