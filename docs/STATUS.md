# Status

## 2026-11-04 — the Slime Dungeon (Sunny Meadow), first playable

The owner: an arena where monsters come in waves, more each wave, their level and strength rising. `docs/GAMEPLAY.md` §14.
A portal beside every village gate (Egg Heist's portal, rebuilt by the server from its published kit meshes, as the owner asked)
opens a sheet: pick teams and the level, Enter. A private arena per player; 10 waves of Sunny Meadow's 7 monsters (mini-boss on 5,
boss on 10); drops paid at each wave clear, the open wave lost on a defeat or a leave; Next Level / Replay / Leave at the end.
Saved: **schema 9** (`farm.dungeon.best`), so a publish must shut down old servers. Drop icons and the portal icon from ChatGPT
(`art/icons/dg_*.png`). Balance: the original's numbers beat four starters in wave 1, so `StatScale` 0.3 and a level is x1.6.

Proved in Studio play tests (`Publish.rbxl`): the portal at the gate (`docs/ui/dungeon-portal-gate.jpg`), the sheet with the drop
pictures, the HUD, slimes fighting, waves 1-2 cleared and paid (coins and carrots in the HUD), a defeat in wave 3 with the
Defeated card, Leave back in front of the portal, no console errors. Still stand-ins: the greybox arena and the monsters (zombie
bodies tinted by kind); next are the Sunny Meadow arena scene and the seven monster models from the owner's paintings. Not seen
live: a victory, Next Level, the mini-boss and boss skills, a phone screen.

## 2026-11-04 — new players start with eight slimes

The owner: the start is slow; begin with 8 slimes so a player can fight at once. `Config.Farm.StarterCount` is 8 (was 4): a full team of
four and four more for the fisher, the gardener and a pair (village level 1 holds 12). Only new farms; existing saves keep their slimes.
The test farm (`FarmKit.farm`) keeps the four slimes the specs were written for; a new spec checks that the tutorial's team step no longer
waits for a baby. Proved in a Studio play test of a fresh player: 8 slimes, 8/12 in the HUD, team 1 set to slimes 5-8 at the banner at
once, no game errors.

## 2026-11-04 — daily check-in, daily quests, online gifts and the slime Index

Retention features (`docs/GAMEPLAY.md` §13): a trophy button with a badge opens Daily (7-day check-in), Quests (3 a day, all done gives
luck) and Online (9 gifts for minutes played); coins scale with the cheapest next upgrade, luck is minutes of the x2 potion with a chip in
the top strip. The slime book has a second page, the Index of all 150 kinds (Secrets as shadows). Icons for the tabs and luck from ChatGPT
(`art/icons/`), the trophy and Index buttons are the owner's art. Two new intros. Saved in the farm: **schema 8**, so a publish must shut
down old servers; old saves start the rewards fresh. Lune tests in `tests/spec/rewards.luau` (383 pass), CHECK OK, TYPES OK.

Proved in a Studio play test (`Publish.rbxl`, shots in `docs/ui/rewards/`): the trophy hidden during the tutorial and shown after it with a
badge; Day 1 claimed (+160 coins, the tile Taken, the clock to midnight); three quests drawn; the 1-minute gift opened on its own and was
claimed (+100); the Index tabs with the found Navy and dark shadows; no errors from the new code in the console. Not seen live: quest
progress and its claim, the quest bonus, a real luck claim (the chip was shown by a local preview), a found Secret's golden shadow, the
two new intros (all covered by the Lune tests), and a real phone.

## 2026-11-03 — tutorial: the trail points the right way, breeding is quick while it runs

The owner: the arrows on the trail pointed the wrong way; speed up breeding during the tutorial. The trail is now a row of the gold
arrows each turned on the screen along the way (a Beam had laid the picture sideways); seen in a Studio shot pointing at the pond. While
the tutorial runs: courtship 10 s, hatching 10 s, growing up 30 s, and a pair goes courting before a nap or a meal
(`docs/GAMEPLAY.md` §12). Measured in Studio play tests: egg to hatch 16 s (was 68), hatch to adult 30 s with the baby growing from small
(was about 300), pair to egg 57-109 s (was 159), the rest being the parents' walk to the nest.

## 2026-11-03 — a step-by-step tutorial and feature intros

The owner: a detailed tutorial that walks a new player through the game and introduces the features. Now 14 steps (slime book, a fisher,
a gardener, the Food chip, a pair, the egg, the hatch, the Market, selling, home, the upgrade pads, a team, an attack, the win) and 12
one-time intros for later features (`docs/GAMEPLAY.md` §12). Each step points at the real thing and moves on only from real farm state
checked on the server; Skip at any time. Saved in the farm: **schema 7**, so a publish must shut down old servers; old saves count the
tutorial as done. Lune tests in `tests/spec/guide.luau`.

Proved in a Studio play test of a fresh player (`Publish.rbxl`): all 14 steps passed in order from real play (book and Food by clicks,
the egg laid at 159 s and hatched at 227 s, quick travel to the Market and home, the wait line until the baby grew up, the team, the
attack, 140 coins), then the "slime fell" intro with its arrow on the skull, closed by its button, and the Repeat intro after it; no game
errors in the console. Not seen: the world arrow and its trail in a picture (Studio captures show only the GUI), a real phone.

## 2026-11-03 — waving flags at the gate and the training ground

The owner: the team banner and the training ground's flag must be thin and fly softly like a real flag. Now both are one waving flag
(`tools/blender/flag.py` -> `art/models/flag/`, imported by the owner; meshes in `Config.Flag`): a wooden pole, a gold finial and a thin
two-sided cloth with the owner's sword art crossed, on a chain of 8 bones. The server puts it together from the meshes (`server/WavingFlag`,
the bones under the cloth so the skin follows them) and every client waves it (`client/FlagWave`: a ripple running to the free end, a slow
swing about the pole, a little droop; only near the camera, 30 updates a second). The kit's stiff BannerFlag is no longer used. Proved in a
Studio play test: both flags built, the cloth bends and moves, no errors. Not seen on a phone.

## 2026-11-03 — team banner at the gate, shorter prompt ranges, teams open with the village

The owner: the Teams prompt and the attack prompt worked from very far; put something at the gate for the line-ups; more teams as the village
levels up (4 at most). Now a team banner stands just inside the gate (Teams prompt within 10 studs), an attack needs 16 studs, and teams 2-4 open
at village levels 10, 20, 30 (`docs/GAMEPLAY.md` §8 "Teams"). Proved in a Studio play test: the banner beside the path, the prompt shown only near
it, team 2 refused (LOCKED) at village level 1, a line-up refused from 18 studs, an attack refused from 21 studs and sent from 12, only tab 1 shown at
level 1 and tabs 1-3 at level 20.

## 2026-11-03 — fights made dramatic (owner: "4 slimes attack in unison, no impact effects")

Done in three steps (`docs/GAMEPLAY.md` §8 "The fight"): each fighter on its own beat with a wind-up, a lunge, the owner's battle art on
impact, goo, knock-back, falls and a cheer; each moves about the field by its way of fighting (its strongest stat, a zombie's kind) and keeps
clear of the others; skills every few blows with their names called out. No camera effects (the owner). Balance re-run with `fight_sim`.

Proved in Studio play tests (`Publish.rbxl`): two fights won with no errors; the skill names showed once per cast (Goo Slam 7, Dash Strike 7,
Belly Bounce 5, Chomp 15); Goo Slam's cracks and rings, Belly Bounce's ring, Dash Strike's slashes and Jelly Guard's guard events all fired;
fighters stood apart. Not seen close up: Acid Rain (cast in play, not caught on camera) and Plague Burst (no plague zombie in the test groups), a real phone. No hit
sounds yet (the game has no sound assets).

## 2026-11-03 — before a publish, from the whole-repo audit: start here

Fixed: a publish now goes through `lune run tools/build_publish.luau`, which writes `assets/raw/Publish.rbxl` (the MapWork world, the repo's code, no labs or test stages, streaming on);
a Studio play test always uses the in-memory store (`Config.Save.StudioUsesRealStore`, off); a catch or garden chore whose slime is gone no longer jams its work place (`Stations.freeAbandoned`).

Proved by playing `Publish.rbxl` in Studio: the village, Market and slimes load with no errors; quick travel works; going to the far side of the valley dropped the client from about 9,000 parts to
2,630, and coming home brought back the village, prompts, bins and pad labels. Re-assigning a carrying fisher in play put the fish in the storehouse and the next catch came 59 s later;
a gardener re-assigned between chores carried on. Not measured: a real phone, 8 players at once, a real publish.

Also from the audit: a lost save lock now runs the leaving clean-up; a crashed server's lock frees in 300 s (refresh 60 s, 300 so a few minutes of DataStore trouble cannot steal a live lock); one
capacity formula and one pair check (`FarmState`); the request rules moved to `shared/VillageRequests` with a spec; team and health publishing runs 4 times a second; the dish toast shows what the server
paid; dead code removed. A reviewer read both audit commits: nothing blocking.

Proved in MapWork play tests: refusals with the right reasons; a slime sale paying 120; a march and fight with its reward; a cooked dish sold with 3 asked and 1 held, paying 1000; a real foreign lock
written to the store (a temporary patch, gone) lost the session, removed the village folder, freed the zombie group and kicked the player. Only read or tested, not seen: the crash lock time, the toast on screen.

Load test in `Publish.rbxl` with seven more village copies built by script (40,180 parts on the server, no slimes or other players): the client held 12,354 parts at home, 16,066 at the Market, 22,954 at
the valley's centre; the server kept 60 Hz. The frame rate means nothing here: 60, then a steady 14 wherever the character stood, probably Studio's window in the background.

What only the owner can do before players come: look on a real phone (F9 memory, frame rate), a test with friends, and say when to publish (`publish` skill).

## 2026-11-03 — the kitchen

Done and committed on `main`, not published (rules in `docs/GAMEPLAY.md` §5, numbers and measurements in `docs/ECONOMY.md`): a recipe per cook, 16 dishes with rarity
and timed buffs, Feed and When hungry, selling dishes at the Market, food rarity by pond and garden level, the coin vault, real upgrade prices (FreeUpgrades off),
13 new dish models in the kit, the buff badge and four effects from the owner's stat icons. Schema 6: a publish must shut down all old servers.

Proved in a MapWork play test: a cook takes the recipe's ingredients and makes the dish; a missing ingredient floats crossed out over the cook; a locked recipe is refused; the
recipe list and dish sheet open and act; Feed sets the buff; selling at the Market pays 1000; an upgrade pad charges 310 and raises the level; the vault-full number and toast
(with the coins set by script); badge and effects of all four stats at the player's camera (with epic buffs set by script); auto-eat (two slimes set to Grilled Fish got hungry on their
own, ate it and got the attack buff, with no script help). A reviewer read money, saves and remotes.

Only passed tests, not seen in play: dish buffs inside a real fight, fight income stopping at the vault, the save migration on a real old save, recipes above common.

Not seen or not known
- No screen has been seen on a phone frame: Claude cannot switch Studio's device view. To look at: the Market header (tight at 360 wide), recipe rows, the buff badge.
- Income from fights is still `price_curve`'s assumption, not a measured hour of play, so prices may need tuning. Dish prices are close together (1000 to 2000), to give
  level 1 some income.
- Golden Carp Feast and Starfruit Glazed Puffer came out peach rather than gold, and the puffer has small loose star slices: redo if the owner dislikes them.
- A rarer buff only means denser particles and a coloured badge frame; the effects use the owner's icons and have no glow.
- Graphics quality 0 (automatic) counts as full effects: no effects setting exists in the game yet.

## 2026-11-02 (late) — the Market built, the HUD made for phones: start here

Done and committed on `main`; nothing has been pushed to `origin/main` this stretch.
- The Market in MapWork, saved by the owner at 23:19 (`workspace.Map.Market`, `tools/map/build_market.luau`, `check_market.luau` ends MARKET OK; run the
  builder after `build_wild_slices`): slime buyer, VIP stall, a board of the 6 best slimes, fountain, surroundings, compared with `art/concept/market-1.jpg`
  in real shots and seen in play. The kit in the repo holds its new models; they did not change after the export.
- Quick travel: Market and Home buttons, the camera turns behind the character on arrival.
- HUD: coins, food, slimes and the village plate in one row on the line of Roblox's buttons (a ScreenGui with `TopbarSafeInsets`); the round buttons in a
  column on the right edge. The owner approved the compact size and asked for that line.
- Claude Code Game Studios installed, only the parts that fit (see `CLAUDE.md`).

Not done or not known
- The HUD's last move has not been seen on a phone frame, by Claude or (as far as reported) the owner.
- The Market is about 83,000 triangles by the builder's estimate against a target of 60,000; frame time on a cheap phone never measured. Cut first:
  `PinkDaisies`, `QtFern_1`, then walls.
- Still unlike the picture: grey flagstones (the tint does not take), thinner tree crowns. The Sell button at the buyer's has not been pressed in a test,
  and real DataStores for the board are untested.
- `rbxassetid://203785492` logs an asset error in play; it is in neither `src` nor the saved place, so probably the test player's avatar. `14025376080` ("Asset is not approved for the requester") is one particle texture of the owner's `CampFlame` pack, so that one emitter draws nothing in Studio; look at the campfire after a publish.
- VIP products and prices wait for the owner; none exist.

## 2026-11-02 — village bar done, economy researched

Playable in MapWork with one player: a village per player copied at their saved levels to the first free plot (`Plots`), 108 zombie groups shared
by the server in 9 slices (`docs/MAP.md` 1.4), teams set at the gate, orders given at a group, marches, wounds, repeat, a home notice, one sorted
slime list everywhere, revive within 15 minutes of play or a slime is lost for good, the shop, the rebuilt middle of the valley
(`tools/map/build_wild_slices.luau`).

Not done: Studio's multi-player test (nothing with two players has run); prices (upgrades still free; table in `docs/ECONOMY.md`); frame time on a
phone with the new map and roaming zombies. The owner saved MapWork on 2026-11-02 with all of this in it, and the kit in the repo matches that save.

## 2026-11-01 — ChatGPT's branch reviewed and partly redone: start here

Merged into `main` after a play test in MapWork: the upgrade reveal, the garden order, the population and hunger numbers, and the kitchen
rule. What was kept, redone, proved in play and still unchecked is in `docs/BUG_TRACKER.md`, "Claude's review of this branch".

## 2026-10-27 — project started

Done
- The original web game (makeplay.ai, "Goo Lineage V2") was read in full: its JS source, its
  `AGENTS.md`, 600+ art, sound and animation files (`reference/goo-lineage-web/`, gitignored),
  and all 514 messages the owner sent its AI builder.
- Reference specs written: `docs/reference/01`–`05` (farm, battle, UI and world, effects, the
  owner's history of requests and vetoes).
- `docs/DESIGN.md`: what the Roblox version keeps and changes, and the build order.
- Project skeleton: Rojo tree, Lune tests, StyLua, Selene, `tools/check.ps1` (CHECK OK).

Decided by the owner
- The look (`docs/DESIGN.md` §3): full 3D cartoon in the style of their art. Start Phase 1.

## 2026-10-27 — Phase 1, Foundation: done (logic and tests; not yet run in Studio)

Done
- Farm rules in `src/shared` (pure Luau, run in Lune and Roblox): `Rng` (mulberry32, matches the
  JS), `Colours`, `DualDesigns` (20), `SecretRecipes` (66), `Stats`, `Genetics` (colour + pattern
  genes), `Luck`, `Growth`, `Mutations`, `Breeding` (eligibility, timers, stat inheritance, eggs,
  pity, tutorial first egg), `Hatching` (idempotent), `FarmState` (types, `newFarm`, field-by-field
  `repair`). Times are server seconds.
- Player profiles: `ProfileLogic` (envelope, session lock, migrations, last-good copy, size
  budget), server `ProfileStore` (UpdateAsync lock, retries, budget, BindToClose) and `PlayerData`
  (get / update / markKeyMoment; autosave every 5 min when changed, key moments within 4 s).
  `FarmSave` plugs the farm in: a stored farm that cannot be read is never replaced by a fresh one.
- 136 Lune checks pass; `tools/types.ps1` TYPES OK.

Decisions taken while porting
- Starters are created already adult (the original left them babies for 3 s).
- Mutation rolls stay sequential like the original (secret 1%, dual 5%, base 10%), in one function
  (`Mutations.rollCategory`) so a single categorical roll can replace it later.
- Starting slots 20 (+5 a level, max 220), as in the original.

## 2026-10-27 — the map and the UI come first (owner)

The owner asked to redesign the map and the UI before Phase 2: one valley for 8 players, home
plots and a trading area on the rim, a flat Wild Garden in the middle with monster slimes and
fights (also between players' slimes), and six upgradable areas a plot (fishing, garden, kitchen,
pantry, training, breeding), each level changing the look a little. Proposal: `docs/MAP.md`;
waiting on the owner's choices in its §4. The UI redesign follows the map.

## 2026-10-27 — map approved, greybox built

- The owner approved all four points of `docs/MAP.md`, and set the UI direction (`docs/UI.md`):
  the simplest possible screen; every upgrade and interaction is done on the objects in the world.
  The detailed UI design waits; the owner asked to build the map first.
- `src/shared/Layout.luau` (+ `Config.Map`, `tests/spec/layout.luau`): every position of the valley.
- `tools/map/build_terrain.luau` and `tools/map/build_greybox.luau`: run through Studio's MCP in a
  work place (`assets/raw/MapWork.rbxlx`, a copy of the built place, gitignored), they build the
  terrain (floor, hills, the four quarters, streams, lava rills, ring road, paths, ponds) and a
  greybox (hedged plots with every area blocked out, the Market stalls, the Heart, goo springs,
  trees, lighting). Pictures: `docs/map-greybox/`.
- Open: the map is built in a work place only. The plan is to move both builders into the game
  (a server `World` module that builds the valley from `Layout` at start), so the real place needs
  no hand-saved terrain. Lava in the Ember rills is hidden under the basalt (fix in the art pass).

## 2026-10-27 — concept art before 3D (owner)

The owner asked not to build 3D yet: first ChatGPT concept art of the home plot, "the best
possible visuals, but a simple and clean design". Prompts: `docs/art/chatgpt-home-plot.md`
(style lock + the whole plot + each area at levels 1/4/7/10), with the owner's reference art
copied to `art/chatgpt-refs/`. All 9 pictures were generated (2026-10-27) in the owner's ChatGPT chat
"Image placement suggestion" (prompts sent from the browser pane; the reference pictures were pasted
through the ChatGPT desktop app, as the pane cannot attach files). Picture 1 approved and saved as
`art/inbox/1-plot.png`; 2-9 wait for the owner to download them (the pane cannot download).
The owner saved 2-9 in the project root; they are now `art/concept/2-fishing.png` .. `9-home.png`
(picture 1 was not among them).

First 3D trial (owner's request): the level-1 breeding house from `art/concept/7-breeding-L1.png`.
Three tries in the MapWork place: `generate_procedural_model` from the picture failed (red error box);
two `generate_mesh` text prompts written from the picture both came out cute; the second (scalloped
pink roof, heart on top, beams, stone base, arched door, round window) is placed in Plot 5's breeding
spot. Side by side: `docs/map-greybox/compare-breeding-L1.png`. Close in shape and colours; missing
the dressing around it (bushes, flower pots, stepping stones), the heart emblem over the door, the
warm window, and a real slime model; the roof is a little lilac.

## 2026-10-27 — plot areas, built directly in Studio (owner's restart)

- Level-1 fishing pond (`docs/areas/fishing.md`, approved) and level-1 vegetable garden built in Plot 5 of the
  work place by `tools/map/build_fishing_l1.luau`, `build_garden_l1.luau`; dressed with the free Creator Store
  "Nature stylized Pack" by `dress_plot_nature.luau`; lit by `lighting_storybook.luau` (research in
  `.claude/skills/studio-build/RESEARCH.md`, "Stylized cozy look"). Pictures `docs/areas/*-v3.jpg`.
- Builders place from `Config.Map.GroundY` (terrain surface at y = 2).
- Research "Do this first" items not yet applied: stylized grass MaterialVariant, darker rims, cartoon water,
  shadow discs, reed sway, outlines on hero props, CC0 packs (KayKit, Quaternius crops, Kenney).

## 2026-10-27 — the plot as a small village (owner)

- All six areas of Plot 5 (pond, pantry, garden, kitchen, breeding pen, training ground) now face
  the plot's middle (`Layout.plotAreaFacing`, tested). `tools/map/build_village.luau` adds the stone
  plaza with a well, lamps and planters, paved paths to each area and the gate, a tall wooden fence
  round the plot with a towered gate and name board, and kit trees, bushes and flowers; it clears the
  greybox hedge, meadow house and hatchery nest. Pictures `docs/areas/village-*.jpg`.
- The pond now holds real terrain water (owner's request; `pond_water_l1.luau`), the painted flat
  water is gone. The boulder "SteppingStones" models were removed from the pond and garden entrances
  (owner: badly placed); the garden has a straight line of flat stepping stones instead.
- Pond, second pass (owner): terrain water fills whole 4-stud voxels, so its surface sits near y = 0,
  two studs under the floor; the bank now steps down to it in two sand steps (`stud_floor.luau`), so no
  grass shows. Water as clear as it goes (`WaterTransparency` 1). Lilies sit on the surface. Five fish
  (koi and little blue fish, `generate_mesh`, kept in the work place's `ServerStorage.FishKit`) swim
  loose loops just under the surface, moved on the client by `src/client/PondFish.client.luau` (tag
  "PondFish"); seen working in a Studio play test. Deeper than about 1 stud the water's tint hides them.
  Pictures `docs/areas/fishing-real-water.jpg`, `fishing-fish.jpg`.
- Campfire, third pass (owner): in the empty front-right cell, a round earth stud floor with a stone
  ring, a log teepee and real-looking fire, six small seats (the owner's log benches and kit stumps,
  turned to the fire), lantern posts and tall trees behind; a path from the plaza. Picture
  `docs/areas/campfire.jpg`. The owner's models are in the work place's `ServerStorage.OwnerKit`
  (inserted from the Mue_you inventory with MCP `insert_asset`, scripts removed).
- Fire "like real" for the campfire and the kitchen stove (one recipe, `addFire` in both builders):
  the glow, embers and heat of the "Realistic Fire VFX" pack in the owner's inventory
  (`OwnerKit.CampFlame`, scaled, bloom calmed, tongues kept low), two layers of licking flames with
  Roblox's flame texture, and a light that flickers (`src/client/FireFlicker.client.luau`, tag
  "Flicker"). The stove's chimney smokes a little. Pictures `campfire.jpg`, `kitchen-fire.jpg`.
- Trees: every code-built tree (the greybox's trunk-and-ball trees on the valley rim and in the Wild
  Garden, 140) swapped for the owner's own tree models by `replace_greybox_trees.luau`;
  `build_greybox.luau` places the same on a rebuild. The ring of big trees inside the plot fence is
  the owner's trees too, 22-28 studs tall. Nothing in a home plot sways (owner).
- Taken out (owner): the eggs in the nest and the incubator, the two round grain sacks at the
  pantry, the round seed sack in the garden.
- Crops in growth stages (owner: they grow like a real process, seedling to harvest): Carrot1..4 and
  Cabbage1..4 (seedling, young, growing, ripe; `generate_mesh`, in the work place's
  `ServerStorage.CropKit`; the carrot root is buried, only its shoulder shows). Each plant in a bed is
  a model tagged "Crop" with attributes Crop and Stage; the beds now show the stages side by side.
  Picture `garden-crop-stages.jpg`.
- For later (Phase 2), as the owner asked: the growing system sets a plant's Stage over time and
  swaps in the next stage's model, scaling it up smoothly from the last; the training ground's dummy,
  target and rack get motion when a slime trains there.
- Props remade low poly (owner: "as beautiful and detailed as the crops, everything"): 21 models from
  `generate_mesh` in the work place's `ServerStorage.PropKit` — Stove, KitchenCounter, FirewoodPile,
  StorageShed, CrateStack, WoodBarrel, Cottage, Incubator, BirdNest, WaterTrough, HayBale,
  FlowerPot, TrainingDummy, ArcheryTarget, WeaponRack, BannerFlag, FishBucket, WateringCan,
  StoneWell, Planter, VillageLamp. `tools/map/replace_props.luau` (after build_village) swaps each
  part-built prop group for its kit model, fitted to the group's place and height and facing the
  area's front; the work-spot, nest and incubator markers stay as invisible parts, lamps keep their
  light. generate_mesh hands meshes back turned by a random angle: each kit mesh is set square when
  it goes into the kit. Floors, paths, fences and the area signs stay in the stud look. Pictures
  `docs/areas/props-*.jpg`, `prop-kit.jpg`.
- Fences, gates and signs low poly too (owner): PalisadeFence (the plot's tall fence),
  PicketFence (garden), RanchFence (breeding pen, training ground), VillageGate (keeps the plot's name
  board as a SurfaceGui on the model's board), PenGate (heart arch), and six signposts with their
  icon painted on (SignFishing, SignGarden, SignKitchen, SignPantry, SignBreeding, SignTraining).
  `tools/map/replace_fences.luau` cuts each fence run into bays and stretches one section mesh per
  bay (a MeshPart sizes freely); gates and signs go through `replace_props.luau`.
- Owner fixes: `tools/map/tidy_plot.luau` (last step) moves every tree, bush and prop that reached
  past the plot fence back inside, smaller if needed, and lays a skirt of small bushes, rocks, ferns
  and tufts along the outside foot of the fence (gate kept clear). `stud_floor.luau` now cuts only
  the plot itself and raises a 16-stud ring of grass round it to the floor's height (measured 1.4 to
  2.6 against the floor's 2), so the plot sits level with the ground round it.
- Build order now: ... build_village, replace_props, replace_fences, stud_floor, pond_water_l1,
  tidy_plot. Pictures `docs/areas/fence-*.jpg`, `village-top.jpg`.
- The kit is saved in the repo (owner: never make it again): `assets/Kit/*.rbxm` (PropKit, CropKit,
  FishKit, OwnerKit, NatureKit, HomePlot), exported from the saved work place by
  `lune run tools/kit/export_kit.luau`, built by Rojo into `ServerStorage.Kit`; index with every
  asset id in `docs/kit/README.md`. After each Ctrl+S in Studio, export again.
- The green blob-shadow discs under bushes and rocks are gone (owner); no builder makes them now.
- Area upgrades, 50 levels each, press E at an area's entrance (owner, 2026-10-27): the fishing pond
  (`src/server/PondStages.luau`) and the garden, pantry, kitchen, breeding pen and training ground
  (`src/server/AreaStages.luau`), all run by `src/server/AreaUpgrade.server.luau`. Every area keeps
  its size; five parts that never go away (floor/frame, rails or a bench, lamps, a crate, planters
  and light strips); levels 1-5 add them, then each level moves one part up a material tier
  (rustic wood ... marble and gold). Free and not saved yet (Phase 2: coins, saved levels, owner
  only). `tools/map/sync_server.luau` copies the server code into the work place; play tests start
  on the plaza (`tools/map/dev_spawn.luau`). Pictures `docs/areas/upgrades/`, `fishing-ingame/`.
- Pantry upgrades redone (owner: the store house itself must grow, and what is added must belong
  to a store): `src/server/PantryStages.luau`. The kit shed is replaced by a part-built house so its
  materials and storeys can change. Five eras of ten levels: the era's first level grows the house
  (2nd storey at 11, loading canopy at 21, 3rd storey at 31, rooftop lantern tower at 41); levels
  2-5 of the era add or upgrade four store props (transport, containers, lifting, stock: wheelbarrow
  > hand cart > pallet jack > forklift > hover cart; barrel rack > crate wall > grain silo >
  shipping container > goo tank; ladder > pulley hoist > crane > conveyor > robot arm; sack pallet
  > shelf > metal rack > plastic crates > vault, 20 new PropKit models); levels 6-10 move walls,
  roof, doors and windows, frame and foundation, yard up one material tier (rustic wood, painted
  timber, brick, steel and glass, slime tech, marble and gold). The other four areas wait for the
  owner's review one by one (AreaStages is the stopgap). Pictures `docs/areas/upgrades/pantry-v2-*`.
- Garden and breeding pen redone the pantry's way (owner approved the garden, 2026-10-28):
  `src/server/GardenStages.luau` (tool shed, vine pergola, greenhouse with an open door, irrigation
  windmill; water, tools, compost and scarecrow props) and `src/server/BreedingStages.luau` (the
  cupcake cottage grows into CakeCottage2..5, a nest or incubator more every era up to four each with
  their markers; feed, egg care, comfort and warmth props; fence, floor, nest platforms, pad and gate
  arch climb the tiers). 44 new PropKit models; `tools/kit/intake.luau` takes generated models into
  the kit square and fitted. The incubators are part-built with a clear glass dome so the egg shows
  (owner, 2026-10-28); the owner approved the pen.
- Kitchen redone the same way (`src/server/KitchenStages.luau`, `docs/areas/kitchen.md`): roof,
  walls and bread oven, chimney and pot rack, vent lantern; ingredients, grill, water and dishes
  props (19 new PropKit models); the props stand against the walls facing in (owner, 2026-10-28).
- Training ground redone the same way (`src/server/TrainingStages.luau`, `docs/areas/training.md`):
  stands, punching bag and floodlights, canopy and scoreboard, trophy podium; strength, agility,
  recovery and gear props (22 new PropKit models); the owner approved the kitchen and the training
  ground (2026-10-28). All six areas now have their own stages; `AreaStages` only gives the labels
  and prompt spots.
- The village (tall fence, gate, plaza) upgrades too (`src/server/VillageStages.luau`,
  `docs/areas/village.md`): its level is the average of the areas' levels; the well grows into
  fountains, pillars, lanterns, banners, wing walls, guardians and a crest join the fence and gate,
  (24 new PropKit models). Redone at the owner's word the same day: fence, gate, lamps and paving
  change style every era, decorations come in groups (benches, lamps, stalls, gardens, planters);
  7 more PropKit models (era lamps and benches). Waiting for the owner's review.
- Detail review loop (the owner, 2026-10-28): each main building is rebuilt with more detail,
  self-reviewed, then reviewed by ChatGPT in Claude's own browser pane (skill `chatgpt-review`) and
  revised. Pantry done in 3 rounds (pictures `docs/areas/upgrades/review/pantry-r*`): a roof shape
  per level (gable shed, gambrel barn, brick gable, low seamed steel, corniced marble), loading doors
  that lead the front, loft doors and hoist, then a cargo hatch from steel, windows by function,
  sandstone detail and a real lantern tower on marble. Next: the garden, breeding pen, kitchen,
  training ground and dock the same way.
- `tools/map/sync_client.luau` copies the client scripts into the work place for play tests.
- `tools/map/sync_shared.luau` copies the repo's Config and Layout into the work place (it swaps in
  fresh ModuleScripts, since Studio caches what require returned).
- Build order in Studio: build_fishing_l1, build_garden_l1, dress_plot_nature, polish_plot,
  build_kitchen_l1, build_pantry_l1, build_breeding_l1, build_training_l1, build_village, stud_floor,
  pond_water_l1.
- The work place must be saved in Studio (Ctrl+S) to keep the build.

## 2026-10-30 — end of the day: start here

Read `docs/LESSONS-village.md`; skills `village-playtest` and `chatgpt-code-job` are the repeated steps. The owner will pass the code on to
ChatGPT next: `docs/briefs/HANDOVER-2026-10-30.md` lists the open items. Fixed last: the frozen screen (a glide gait with no hop numbers stopped the
render loop), training without a chosen stat, each pair courting at its own nest. The kit in the repo matches the place the owner saved at 3:38 PM.

## 2026-10-29..30 — the living village through the owner's play rounds (hand-over)

Done since the first play test (every item checked in MapWork play tests; agents' reports in the commit messages)
- UI kit from the owner's art (`UiKit`, slime book, HUD with one Food chip opening `UiFood`), work-position markers with a
  per-place F prompt and one-tap picker (Suggested = highest SPD), a slime assigned to work pops up at its place; the
  breeding sheet ("Pairs" prompt) optimistic and instant; no area Manage prompts.
- Movement: PathfindingService routes, ground snapping, solid bins, gaits from the owner's movement lab
  (`Config.Gaits`: walk = Big leaps, stroll only inside the breeding area, baby gaits, glide when tired/hungry/sad),
  seats (`SeatShape`: resting and sleeping slimes sit on benches, logs and stumps).
- Work: fishing with rods, line, bobber and tosses into the fish bin; the garden cycle on saved CropPlots; SPD sets
  work speed; progress clocks over workers, courting pairs and eggs; hauling for every trait (`ErrandUrgency`, loads).
- Breeding: 2 -> 4 pairs by level; an egg's clock starts when laid, half speed in a nest, a parent carries it to a free
  incubator; eggs one real size (`EggScale`).
- Food: 6 fish and 6 vegetables with rarities (`Config.Food.Kinds`), the player carries in the right hand,
  Deposit store at the storehouse sign.
- Emotes: short pop-ups; z's, hearts (one at a time) and dizzy stars as lasting effects, sized in the world.
- Village scale (`docs/VILLAGE_SCALE.md`): plot 160 -> 228, valley x1.39, paths kept at the owner's 6 studs, every area
  spread (breeding 42x38, pond x1.3, garden x1.4, kitchen and training x1.3, storehouse yard), probes green at levels
  1/21/41 (`tools/map/probe_paths|probe_pads|probe_seats|scan_zfight|scan_rocks`), backup of the old place at
  `assets/raw/MapWork-before-scale-2026-10-30.rbxlx`.

Open
- The owner presses Ctrl+S in MapWork after the last spread (kitchen, storehouse, training), then
  `lune run tools/kit/export_kit.luau`.
- The areas still look small in their bigger cells (lots of lawn); the owner judges in play.
- Phase D/E of the scale plan: the Market, Wild Garden art pass (an odd straight water line), a 20-slime play test.
- Art: the clock-face badge (ChatGPT prompt sent), icons for close/back/plus/energy/fun, Secret slime 3D art.
- Next game steps: the hatch reveal by rarity, the slime shop and plot hand-out for 8 players, recipes for the new food.

## 2026-10-29 — Phase 2 started: the living slime village (gameplay approved, `docs/GAMEPLAY.md`)

Done (code by Codex and ChatGPT from briefs in `docs/briefs/`, checked and merged by the orchestrator)
- Colours: the pair's colour set and pools (Duals n(n-1)/2, Secrets n(n+1)/2), the 9-row kind table, random = a base
  colour the parents lack, materials on plain babies; luck sources (new player, server, potion, VIP); save schema 3.
- Village rules: needs (fullness, energy, fun), traits, friends, food chain (boxes, storehouse, counter, fridge, dishes,
  cooked-food permission), work slots and reserves, training, saved area levels and upgrade costs, population by
  village level, breeding pairs with courtship, nests and incubators, `VillageSim` (online, 8 h offline), ghosts;
  save schema 4.
- Server: the slime brain (`Brain`), a village per player (dev plot 5), routes through the plaza, spots from the plot's
  markers, replicated slime and egg state, the `Village` remote, paid saved upgrades.
- Client: slimes drawn from their look with `SlimeActor`, hopping along the server's legs, action motions, carried food,
  eggs; Manage sheets (key F) and the HUD strip. Surface looks come ready made in `ClientKit.Looks`
  (`tools/kit/export_client_kit.luau`): a game script may not set SurfaceAppearance maps.
- Play tests in MapWork: `tools/map/sync_all.ps1 -StudioId <id>` copies the whole game code in. The player spawns at the
  emotion stage: move the character to the plaza (slimes far from the camera do not animate).

Open
- Play-tested (picture `docs/play/village-first-test.jpg`): fishing and the garden fill their boxes, slimes carry to
  the storehouse and kitchen, a pair courts and lays, the egg is carried to an incubator and hatches, the baby waits in
  the nursery. Seen to fix next: a courting pair should go into the breeding house together (one partner courted
  alone at the plaza); the courtship and nursery spots need real markers.
- Art: collection boxes, the level-1 fridge, dishes, the egg, Config.Ui.Icons (18 icons), Secret slime 3D art.
- The hatch reveal by rarity and the nursery (step 4), the slime shop and plot hand-out for 8 players (step 5).

## 2026-10-28 — the village and every area's upgrades: done (owner: "the village design is finished")

Done (all checked in Studio at every era, committed, the kit exported into `assets/Kit`)
- Every area went through the review loop (skill `area-review`, ChatGPT rounds in each area's own chat, then the
  owner's play-test notes): pantry, garden, breeding pen, kitchen, training ground, fishing pond. Each was approved by
  the owner.
- The village (`VillageStages`): the plaza grows a ring each era; four seating nooks facing the fountain; the picnic
  green (gazebo, laid table beside it), the community green (a stage with its audience), the market street under an
  arch; era planters spread along all the paths; every path paved like the avenue; small plants moved off paving.
- The fence and the main gate per era (`VillageWalls`): painted timber, brick with ivy and torches, steel and glass,
  marble; lanterns and torches built and centred on every post; no plot name sign any more.
- The area gates (`GateArch`, breeding, kitchen, training) with generated emblems; the incubator rebuilt in detail per
  tier (`BreedingStages`).
- The fountain (`VillageFountain`): one per era, moving water (beam curtains, jets, splashes, ripples, shimmer), the
  golden slime statue on the marble one.
- The base slime body (2026-10-28): Blender build `tools/blender/slime_body.py`, files in `art/models/slime_body/`
  (rigged `SlimeBody.fbx` + `SlimeBodyOutline.fbx` hull, overlay/roughness/normal maps, `rounds.md`). Front silhouette
  IoU 0.984 against `slime.base.navy.png` (the ceiling for a round body); 2,400 triangles; bones Root/Base/Top and
  Left/Right/Front/Back (Bone.Transform squash about the feet). (First import 89067624889078 is superseded by the
  re-import below.) The look (owner): nothing painted on - highlights and shading come
  from the light; colour = Colours.luau's swatch on a glossy SurfaceAppearance (roughness 0.10), the hull at x0.6;
  `Lighting.EnvironmentSpecularScale` 1 (was 0) so the gloss reflects the sky. The baked overlay map is unused.
  `tools/slime/showcase.luau` puts the 11 on a stage in MapWork (shot `art/models/slime_body/studio_lineup.jpg`).
- The 55 Dual skins (2026-10-29, `docs/DUALS.md`): one design per colour pair, made by `tools/skins/make_skins.py`
  on the body's new all-round UV; re-imported body ids SlimeBody 71117254607762, SlimeBodyOutline 99817746239640;
  skin image ids in `art/models/slime_body/skins/asset_ids.json`. All 66 stand on the MapWork stage
  (`tools/slime/showcase.luau`, run with `node tools/studio_mcp.js run`). Approved by the owner in play
  ("every design is very beautiful"); `DualDesigns.luau` holds the 55.
- Slime materials (2026-10-29, the owner's pick; stage `tools/slime/materials.luau` beside the slime stage): Gold,
  Silver as "Mirror" metals (Chrome cut: it looked like Silver) (metalness 1, roughness 0.03, the chrome reflection map
  `art/models/slime_body/skins/mirror_metal.png` id 138184721337623 tinted per metal; standard PBR read milky because
  Roblox reflects only a blurred sky), Ice and Jelly see-through, and 14 Roblox materials: Neon, Wood, Marble,
  CrackedLava, Brick, Granite, Mud, Fabric, Sand, Grass, Glass, ForceField, ClayRoofTiles, Leather. They are a rare
  hatch mutation (`docs/MATERIALS.md`, `src/shared/Materials.luau`, rolled in `Mutations`); the Duals are one design
  per pair (55). Logic and tests done (save schema 2); the client drawing, the Sell remote and the book UI come with
  Phase 2.
- Faces, emotions and jelly motion (2026-10-29, approved by the owner in play: "everything is very good"): the owner's
  9 faces cut into parts plus drawn pieces (`art/faces/`, `tools/faces/make_faces.py`, ids in `src/shared/FaceArt.luau`);
  24 emotions as data (`src/shared/Expressions.luau`); face plates that ride the deformed skin
  (`src/shared/SlimeShape.luau`); spring-based jelly body motion with crouch-launch-land-wobble hops
  (`src/shared/SlimeMotion.luau`; the owner lifted the 2D squash vetoes, `docs/DESIGN.md`); the client rig
  `src/client/SlimeFace.luau` and the API for the future brain `src/client/SlimeActor.luau` (`Actor.new(model, emotion)`,
  `:setEmotion`, `:lookAt`, `:playMotion`, `:hop`); numbers in `Config.Slime`. Weak spots the owner may raise: gaze
  slides the whole eye (pupils are painted in), the yawn mouth, sulk turns far, every spring number untuned, drawn
  pieces (lids, swirl, brows, blush, sweat, emote icons) could become art.
- Review stages in MapWork, all at y 300 around z -800, joined by walkways: emotions at x -75
  (`tools/slime/emotions.ps1`), the 66 slimes at x 0 (`tools/slime/showcase.luau`), materials at x 75
  (`tools/slime/materials.luau`). `tools/slime/spawn_at_stage.luau` makes every Play start in front of the emotion
  stage (delete `Workspace.SlimeEmotions.SpawnAtStage` to spawn at the map's spawn again).
- How it was done is packaged: skills `area-review`, `prop-craft` (new: the owner's quality bar and placing rules,
  the generate/check/export tools `tools/kit/intake|viewer|upright|export_kit|check_kit.luau`), `chatgpt-review`;
  lessons in `.claude/skills/studio-build/LESSONS.md`; shots in `docs/areas/upgrades/review/`.

Next (proposed to the owner 2026-10-29, he ended the session before choosing; ask him first)
- Phase 2, step 1 (recommended): the slimes live on the farm with a first brain - a player's slimes appear on their
  plot drawn with their colour / Dual skin / material and faces (`SlimeActor`), the server owns needs (hunger, energy,
  fun, social), personality per slime and positions; Sims-style "smart objects" (the pantry, beds, the pond,
  benches, flowers...) advertise actions; slimes wander, eat, sleep, play, greet and argue, with emotions and looks
  toward the player. The owner wants motion, interaction and emotion as rich as possible: this game is a life-SIM.
- Step 2: breeding, eggs and the hatch reveal (escalating by rarity: normal, Dual, Material, Secret).
- Step 3: the collection book (11 + 55 + 18 + 66), selling (helpers exist in `Mutations`), the HUD strip.
- Not measured yet: the frame time of the full plot at the last era on a phone (the fountain alone is ~200 particles/s;
  the brick wall's ivy is ~1,100 small parts).

Next (after the map and UI are agreed)
- Phase 2, The farm: the 3D plot and the slimes on it, the nest house, eggs and the reveal, the
  breeding house, the collection book, selling. Needs the first 3D models (slime body, nest house)
  made from the owner's paintings, and remotes for Breed / Hatch / Sell.
- First Studio play test of the profile layer (in-memory store in an unpublished place).

Notes
- The MakePlay builder also wrote a `ROBLOX_EXPORT.md` in the original project on request, but the
  file is not served by the game host; it was rebuilt from its own notes (it has no access to the
  old chat), so the owner-history docs here are the better source.
- Sounds in `assets/lib/bvker-foley/` of the original come from a third-party library: check its
  licence before uploading them to Roblox.
