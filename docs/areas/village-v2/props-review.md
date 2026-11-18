# Village props review (2026-11-18)

The owner: "các prop trước kia sử dụng của roblox tự generate có nhiều món tôi không thấy đẹp cho lắm. bấy giờ bạn hãy
rà soát lại những asset đang dùng cho làng, rồi sau đó thanh lọc những món không phù hợp với style hiện tại và đề xuất
ra những asset thay thế hoặc một số asset mới."

**The yardstick** is the owner's own era sheets (`props/*-sheet.jpg`) and the Meshy pieces built from them
(`hard-pieces.md`, "Era props", "Fences and gates"): chunky hand-painted shapes with real material detail, one look an
era: 1 rustic timber, thatch, rope and field stones; 2 teal-painted timber, cream panels, red clay tiles, gold caps;
3 pale stone brick, ivy, gold diamonds; 4 slime-tech: dark riveted iron, teal glass, brass gears, copper pipes (a
storybook machine, never a modern or sci-fi plastic one); 5 royal: cream marble, gold, blue banners with crowns, pink
roses.

**How it was judged**: every model the live modules place by name was listed (`VillageStages`, `VillageWalls`,
`VillageFountain` and the six areas' `*Stages`; `AreaStages.build` is dead), then the 141 `generate_mesh` models among
them were laid out in MapWork, fitted to an 8-stud box, and shot one by one from the front-left (the lineup was removed
afterwards, nothing saved). The marked sheets are `props/review/village_review_<place>.jpg`: green KEEP, blue SWAP to a
piece we already own, red REDO. Not judged: the owner's own `OwnerKit` pieces, the Quaternius library props and the new
Meshy pieces.

## Result: 50 keep, 14 swap, 77 redo

The pattern: the rustic eras 1-3 mostly hold up; eras 4-5 came out as modern or sci-fi plastic (vending machine, water
cooler, forklift, drones, holo screens, pastel toys), which the village's era ladder never draws.

### Swap now, no new art (the Meshy pieces already in `ConfigMeshyKit`)

| Now | Becomes | Where |
|---|---|---|
| FlowerBedWood, FlowerBedBrick, FlowerBedSteel2, FlowerBedMarble | `PropPlanter*` of the same era | village walls and gate, garden seating wing |
| GoldenLampPost, IronStreetLamp, ModernLampPost | `PropLampRoyal`, `PropLampStone`, `PropLampTech` | walls' era 5 landing, garden seating wing |
| MarbleUrn | `PropPotUrn` | walls' era 5 column tops and pediment |
| SlimeStatue | `SlimeStatue_Gold` | fountain, era 5 |
| ClippedTopiary | `ConePot_Topiary` | village garden piece, era 2 |
| CrateStack, WoodBarrel | `CrateStack_Wood`, `Barrel_Oak` | market, pantry, garden, breeding, kitchen |
| HayBale | `HayBales_Stack` | breeding, garden, pantry |
| MarketArch | the era's `PropGate*` | market street |

**Done 2026-11-18, all 14**: in `VillageStages`, `VillageWalls`, `VillageFountain`, `PantryStages`, `GardenStages`,
`BreedingStages` and `KitchenStages`, each with the old model as its stand-in while the meshes load
(`PantryStages.StandIn`). Seen in MapWork's play test at levels 20, 30, 40 and 50 (and the kitchen at 10): every new
piece stands, no stand-in left (`props/review/swaps_in_play.jpg`).

### Tripo's free gallery (2026-11-18, nothing exported yet)

The owner asked to look there first and to see the pictures before any download. The eight closest fits are on
`props/review/tripo_candidates.jpg` with their triangles now and after a Blender reduction: A stone-and-ivy bench (era
3), B cream-and-gold bench (era 5), C rustic timber stall (era 1), D tiled stall with columns (era 3), E striped-awning
stall (era 2), F stone gazebo with a blue dome (era 3 or 5), G pink-and-gold gazebo (era 5), H sundial (too dirty).
Recommended: A, B, C, F, G. An export costs 5 Tripo credits (the account has 1650).

### Redo, grouped as era sets (one ChatGPT picture an object, Meshy Smart Topology)

**Phase 1, the village common (seen by everyone): 23 pieces**

| Set | Replaces | Pieces |
|---|---|---|
| Benches, one an era | ParkBench, IronBench, ModernBench, MarbleBench | 5 (era 1 rustic log-and-plank, 2 teal-painted with cream back, 3 stone ends with a timber seat, 4 riveted iron with brass, 5 marble with gold scrolls) |
| Market stalls, one an era | FlowerCart, FruitStall, IceCreamCart, BakeryKiosk, GooVending | 5 (thatch-roof crate stall, striped-awning painted stall, tiled-roof stone stall, glass-and-iron goo stall, royal canopy stall) |
| Notice boards, eras 3-5 | ClockPost, InfoKiosk, HoloBoard | 3 (stone-framed board with a clock, brass-and-teal-glass board with gears, marble board with a gold crown) |
| Garden centrepieces | Birdbath, Sundial, LightTree, SlimeCrystal | 4 (era 1 field-stone birdbath, 3 stone sundial with ivy, 4 brass orb lamp on iron legs, 5 marble slime fountain) |
| Gazebos, eras 2-5 | PavilionWood, PavilionMarble | 4 (teal timber with red tiles, stone with ivy, iron and teal glass dome, marble with a blue-and-gold dome) |
| Fountain pieces | KoiSpout, GoldCrest | 2 (carved stone koi spout, gold-and-blue royal crest) |

**Phase 2, the areas' work props (mostly their eras 3-5): 57 pieces, one sheet an area**

| Area | Replaces |
|---|---|
| Kitchen (10) | SpiceCabinet, StoneGrill, ServingCart, SteelGrill, SteelSink, BuffetWarmer, GooFridge, PlasmaGrill, GooTap, FoodDispenser |
| Garden (11) | SoilCart, CompostTumbler, SeedSpreader, Sprinkler, Tiller, FertiliserTank, BirdRepeller, WaterDrone, GardenBot, GooComposter, RobotScarecrow |
| Breeding (13) | CushionPile, HeatLamp, GrainFeeder, EggCart, Trampoline, AutoFeeder, EggScanner, SlimeBed, MonitorStation, GooFeeder, EggPod, CloudBed, HoloBeacon |
| Training (9) | TyreRun, WaterCooler, DumbbellRack, MassageTable, PunchingBag, WeightBench, SparringBot, HealPod, HoloTrainer |
| Pond (2) | FishCooler, CrystalBuoy |
| Pantry (12) | CrateWall, PalletJack, GrainSilo, MetalRack, StoreCrane, Forklift, ShippingContainer, Conveyor, PlasticCrates, HoverCart, GooTank, RobotArm |

Each keeps its job (a feeder still feeds, a grill still grills) in the era's look: era 4 a brass-and-iron machine with
teal glass and gears, era 5 marble and gold.

### New pieces the village lacks (phase 3, 21 pieces)

- **Wall lanterns**, one an era (5): the walls' lanterns and torches are built from parts today.
- **Hanging flower baskets**, one an era (5): for lamp arms and walls, also parts today.
- **Banner poles**, one an era (5): each era's festive look on the plaza, in place of the era 2 parts-built bunting.
- **Picnic tables**, eras 2-5 (4): only one rustic table serves every era today.
- **Garden life** (2): a bird house and a beehive beside the Garden, eras 1-3.

### Cost

Meshy has 18 credits (one generation at 15). Phase 1 is 23 x 15 = 345 credits, phase 2 855, phase 3 315; topping up
is the owner's call. ChatGPT pictures cost nothing. The 14 swaps cost nothing (done, above).
