# Status

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
  Left/Right/Front/Back (Bone.Transform squash about the feet). Imported by the owner on Mue_you: model ids SlimeBody
  89067624889078, SlimeBodyOutline 125941562766782. The look (owner): nothing painted on - highlights and shading come
  from the light; colour = Colours.luau's swatch on a glossy SurfaceAppearance (roughness 0.10), the hull at x0.6;
  `Lighting.EnvironmentSpecularScale` 1 (was 0) so the gloss reflects the sky. The baked overlay map is unused.
  `tools/slime/showcase.luau` puts the 11 on a stage in MapWork (shot `art/models/slime_body/studio_lineup.jpg`).
- The 55 Dual skins (2026-10-29, `docs/DUALS.md`): one design per colour pair, made by `tools/skins/make_skins.py`
  on the body's new all-round UV; re-imported body ids SlimeBody 71117254607762, SlimeBodyOutline 99817746239640;
  skin image ids in `art/models/slime_body/skins/asset_ids.json`. All 66 stand on the MapWork stage
  (`tools/slime/showcase.luau`, run with `node tools/studio_mcp.js run`). Waiting for the owner's look in play.
  Next: `DualDesigns.luau` to 55 pairs, then the face decal and the hop in the farm code.
- Slime materials (2026-10-29, the owner's pick; stage `tools/slime/materials.luau` beside the slime stage): Gold,
  Silver, Chrome as "Mirror" metals (metalness 1, roughness 0.03, the chrome reflection map
  `art/models/slime_body/skins/mirror_metal.png` id 138184721337623 tinted per metal; standard PBR read milky because
  Roblox reflects only a blurred sky), Ice and Jelly see-through, and 14 Roblox materials: Neon, Wood, Marble,
  CrackedLava, Brick, Granite, Mud, Fabric, Sand, Grass, Glass, ForceField, ClayRoofTiles, Leather. They are a rare
  hatch mutation (`docs/MATERIALS.md`, `src/shared/Materials.luau`, rolled in `Mutations`); the Duals are one design
  per pair (55). Logic and tests done (save schema 2); the client drawing, the Sell remote and the book UI come with
  Phase 2.
- How it was done is packaged: skills `area-review`, `prop-craft` (new: the owner's quality bar and placing rules,
  the generate/check/export tools `tools/kit/intake|viewer|upright|export_kit|check_kit.luau`), `chatgpt-review`;
  lessons in `.claude/skills/studio-build/LESSONS.md`; shots in `docs/areas/upgrades/review/`.

Next
- The owner chooses the next session's direction (Phase 2, the farm and its slimes, is the next build phase).
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
