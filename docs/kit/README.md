# The reusable kit

Everything made for the map is kept here so it never has to be made again (the owner, 2026-10-27).
The models live in `assets/Kit/*.rbxm` and Rojo puts them in the game's `ServerStorage.Kit`
(`default.project.json`). They are exported from the Studio work place by
`lune run tools/kit/export_kit.luau` after the place is saved (Ctrl+S in Studio).

Every kit model is fitted for placing: one mesh part, set square, pivot at the middle of its foot,
front toward -Z. The map scripts (`tools/map/replace_props.luau`, `replace_fences.luau`) scale each
one to the place it fills; a fence section's mesh is stretched to the length of its bay.

Generated models were made with Studio's `generate_mesh`; each was also published to the owner's
Roblox inventory (Mue_you) as a "Roblox Generated Object" package with the id below. A model can be
inserted again from that id with the Studio MCP `insert_asset` tool, but then it has to be set square
and fitted again, so the `.rbxm` files are the copy to use.

## PropKit.rbxm (low poly, `generate_mesh`)

| Model | Asset id | Where it is used |
|---|---|---|
| Stove | 115617955950396 | kitchen |
| KitchenCounter | 120461205826474 | kitchen |
| FirewoodPile | 93547347462534 | kitchen |
| StorageShed | 103161405175824 | pantry |
| CrateStack | 137515654870929 | pantry |
| WoodBarrel | 82427373753217 | pantry, garden |
| Cottage | 78284776654915 | breeding pen (cupcake cottage) |
| Incubator | 136544449694786 | breeding pen |
| BirdNest | 135151274906513 | breeding pen |
| WaterTrough | 117039255974740 | breeding pen |
| HayBale | 83169898646374 | breeding pen |
| FlowerPot | 134924338348361 | breeding pen |
| PenGate | 99717571996418 | breeding pen gate |
| TrainingDummy | 129863500374663 | training ground |
| ArcheryTarget | 127690627864375 | training ground |
| WeaponRack | 135658017505844 | training ground |
| BannerFlag | 80599160518599 | training ground (squad point) |
| FishBucket | 120424330202921 | fishing pond |
| WateringCan | 74900497080556 | garden |
| StoneWell | 107185965125202 | village plaza |
| Planter | (not published) | village plaza |
| VillageLamp | (not published) | plaza, paths, campfire, pond |
| VillageGate | 106358388545379 | the plot's gate (name board) |
| PalisadeFence | 118109591341169 | the plot's tall fence (one bay) |
| PicketFence | 75420362279149 | garden fence (one bay) |
| RanchFence | 138804851869534 | breeding pen and training fences (one bay) |
| SignFishing | 106033278740482 | area sign |
| SignGarden | 98563486397505 | area sign |
| SignKitchen | 76093453594926 | area sign |
| SignPantry | 101554592390526 | area sign |
| SignBreeding | 132443521605200 | area sign |
| SignTraining | 123495039378329 | area sign |

The upgrade props (`src/server/*Stages.luau`) are in PropKit.rbxm too; each stages file names them
by slot and era. Kitchen and training ground models (asset ids of the published packages):

| Model | Asset id | Where it is used |
|---|---|---|
| BrickOven | 118203938657530 | kitchen, era 3 |
| VeggieCrates, PickleBarrels, SpiceCabinet, IceBox, GooFridge | 140478146221749, 117135357440078, 111650889820112, 134066039561377, 87557326756033 | kitchen ingredients |
| CampGrill, StoneGrill, BrickBBQ, SteelGrill, PlasmaGrill | 126222793130223, 76228495432781, 76219880836241, 110514836287914, 119476949479673 | kitchen grill |
| StoneSink, SteelSink, GooTap | 132777941364597, 136567789348320, 91161691928474 | kitchen water (with WoodBarrel, HandPump) |
| DishRack, PlateShelf, ServingCart, BuffetWarmer, FoodDispenser | 103388093607977, 83109074195733, 133533832558955, 84869899859876, 84638350019559 | kitchen dishes |
| StoneWeights, WoodBarbell, DumbbellRack, WeightBench, GravityPress | 98728420061090, 136127332275224, 106023791465165, 82786216395396, 101432759063471 | training strength |
| TyreRun, JumpHurdles, BalanceBeam, ClimbingWall, HoloHoops | 75145332661860, 79890434166097, 123303078276792, 82515207548293, 134153062822365 | training agility |
| RestBench, WaterCooler, MassageTable, IceBath, HealPod | 134839277279194, 78754672854621, 111882833173817, 80918511455769, 108140629726030 | training recovery |
| SwordBarrel, ShieldRack, ArmorStand, SparringBot, HoloTrainer | 119723960867461, 126486671607445, 117449409718587, 125146860165818, 91864478146987 | training gear |
| PunchingBag, ChampionTrophy | 106739653183504, 121466755406359 | training, eras 3 and 5 |
| FlowerBedWood, FlowerBedBrick, FlowerBedSteel, FlowerBedMarble | 92089182893246, 120841523625422, 76502321904483, 84253715977949 | village planters, eras 1-2, 3, 4, 5 |
| PicnicTable | 105886899973840 | village picnic green |
| PavilionWood, PavilionMarble | 125901976896948, 118518637222522 | village picnic gazebo, eras 2-3 and 4-5 |
| VillageStagePlatform | 113165254288603 | village community green, from era 3 |
| MarketArch | 120075755924816 | village market street |
| ClippedTopiary | 118869481227017 | village garden piece, era 2 |
| PaintedLampPost, SteelStreetLamp | 81425132591063, 135167358158216 | village lamps, eras 2 and 4 |

## CropKit.rbxm (four growth stages: 1 seedling, 2 young, 3 growing, 4 ripe)

| Model | Asset id |
|---|---|
| Carrot1 | (not published) |
| Carrot2 | 132798768783194 |
| Carrot3 | 73384831694824 |
| Carrot4 | Carrot3 made bigger and less buried |
| Cabbage1 | (not published) |
| Cabbage2 | 135555751584417 |
| Cabbage3 | 124850743356250 |
| Cabbage4 | 75959098934976 |

## FishKit.rbxm

KoiFish 89590294358011, BlueFish 110184517960885 (moved by `src/client/PondFish.client.luau`).

## OwnerKit.rbxm (the owner's own library, Mue_you inventory)

| Model | Asset id |
|---|---|
| LogBench | 83472590122735 |
| LanternPost | 95876339242517 |
| TallPineLarge | 95371001306341 |
| TallPineDense | 114299240865205 |
| TallPineSparse | 117060782884661 |
| TallPineSlender | 79987065244560 |
| TallPineWindswept | 138022471255825 |
| BroadleafTree | 101901384798883 |
| BanyanTree | 112088675902578 |
| VineTree | 136114848396213 |
| FrozenDeadTree | 137472019227542 |
| PineBerryBush | 114031299444464 |
| FlatBoulder | 128315234153746 |
| WideBoulder | 85866561244773 |
| StackedRocks | 104600664594613 |
| JaggedRocks | 87247551693627 |
| FernCluster | 92105464772499 |
| WildflowersGrass | 140653033074199 |
| FlowerShrub | 76342140455262 |
| CampFlame | from "Realistic Fire VFX" 12136850996 in the owner's inventory (another creator's free pack, scripts removed) |

## NatureKit.rbxm

The free Creator Store "Nature stylized Pack" (109637424937405, no scripts): bushes, flowers, ferns,
tufts, rocks, stumps, logs, water lilies, trees.

## HomePlot.rbxm

The finished level-1 home plot (Plot 5, the village) as built by `tools/map/*`. The terrain under it
(the flat plot, the ring round it, the pond's water) is not in the file: `stud_floor.luau` and
`pond_water_l1.luau` make it.
