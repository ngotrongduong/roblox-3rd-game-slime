# The reusable kit

Everything made for the map is kept here so it never has to be made again (the owner, 2026-10-27).
The models live in `assets/Kit/*.rbxm` and Rojo puts them in the game's `ServerStorage.Kit`
(`default.project.json`). They are exported from the Studio work place by
`lune run tools/kit/export_kit.luau` after the place is saved (Ctrl+S in Studio);
`lune run tools/kit/check_kit.luau Name1 Name2 ...` then says whether those models made it in.

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
| FlowerBedWood, FlowerBedBrick, FlowerBedSteel2, FlowerBedMarble | 92089182893246, 120841523625422, 78643288731064, 84253715977949 | village planters, eras 1-2, 3, 4, 5 (FlowerBedSteel 76502321904483 came out bent: unused) |
| EmblemBreeding, EmblemKitchen, EmblemTraining | 121457674801892, 114509872454727, 105153830412202 | the top of each area's entrance arch (GateArch) |
| WallLantern, TorchSconce, MarbleUrn, GoldCrest | 130426004663067, 137742128678187, 102536557732140, 113569450995994 | the plot's fence and main gate (VillageWalls) |
| SlimeStatue, KoiSpout | 114758986895985, 111368147797938 | the village fountain: the golden slime on the marble one, the koi spouts on the brick one |
| IvyLeaf | 140233145136608 | one ivy leaf: the brick wall's vines are built from it (VillageStages ivyVine) |
| PicnicTable | 105886899973840 | village picnic green |
| PavilionWood, PavilionMarble | 125901976896948, 118518637222522 | village picnic gazebo, eras 2-3 and 4-5 |
| VillageStagePlatform | 113165254288603 | village community green, from era 3 |
| MarketArch | 120075755924816 | village market street |
| ClippedTopiary | 118869481227017 | village garden piece, era 2 |
| PaintedLampPost, SteelStreetLamp | 81425132591063, 135167358158216 | village lamps, eras 2 and 4 |

The shared middle of the valley (`tools/map/build_wild_slices.luau`, rebuilt 2026-11-02 after the owner rejected the first look;
in the work place's PropKit until the owner's Ctrl+S and the export). Triangles are measured in the scene, not the ceiling asked for:

| Model | Asset id | Triangles, where it is used |
|---|---|---|
| GlowMushrooms | 108230156976781 | 400, Mushroom Grove (three caps, turquoise) |
| AmethystRocks | 98736474914475 | 300, inner ring |
| AutumnPlant | 122337295279967 | 1,150 (asked for 220), Ember Garden |
| PinkDaisies | 99877208898698 | 300, Sunny Meadow |
| MossyLog | 102252511379031 | 596, by the trees: short and brick red, not the references' long hollow log |
| CrystalCluster | 89565445204716 | 120, Frost Glade, blue |
| RuinArch | 119137243254659 | 600, the Heart |
| GooBasin | 109097409899804 | 400, the Heart's spring, pressed low |
| TwistedTree, GiantMushroom, EmberPlant | 120350717564903, 82978024017038, 140577747992093 | no longer used: too simple beside the references |

A lupin clump (83620754016104) came out shredded and was thrown away. The first look's ground map
`rbxassetid://138249545071236` and its `WildFlat*` variants are gone from the map; the image stays on the owner's account, unused.

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

## Food and tools for the slimes' hands (ClientKit.Items, 2026-10-29)

The dishes and the egg were made with `generate_mesh` (the free Creator Store search for food returned only
unrelated or pack-spam models, so none was taken; these are the owner's own generated objects, no scripts). They sit
in `PropKit` and `tools/kit/export_client_kit.luau` puts them in `ClientKit.Items` (the egg also at `ClientKit.Egg`).

| Model (ClientKit.Items) | Asset id | Notes |
|---|---|---|
| grilledFish | 132026139176704 | a fish with a lemon wedge, about 1 stud; its colour is a little pale, may be redone |
| veggieStew | 76768389164850 | a wooden bowl of orange stew with carrot and cabbage pieces |
| fishVegSoup | 92364044048347 | a royal-blue and cream bowl of golden soup |
| Egg | 140402081795858 | a plain cream egg |
| FishingRod, Hoe | built from parts | `src/server/WorkProps.luau`; `tools/kit/make_tools.luau` puts them in PropKit; pivot at the foot of the handle |
| WateringCan | 74900497080556 | the garden's (PropKit) |
| fish, carrot, cabbage | KoiFish, Carrot4, Cabbage4 | as before |

`tools/kit/fill_client_items.luau` copies the same models into the work place's own ClientKit for a play test.

## FoodKit (more fish and vegetables, 2026-10-30)

The owner asked for several kinds of fish and vegetables with rarities (`Config.Food.Kinds`). The free Creator Store
search (scope creator_store, free) was tried for each kind: it returned unrelated, pack-spam or unvetted models of mixed
styles, and the owner's inventory has no food, so none was taken (no unknown scripts, one look). Seven were made with
`generate_mesh` (the owner's generated objects, no scripts, same look as the dishes); the blue fish is the pond's own.
`tools/kit/intake_food.luau` fits them (scripts removed, anchored, scaled, pivot at the middle, fish side-on facing +X
like the koi) into `ServerStorage.FoodKit` and copies the ripe vegetables into `CropKit` as `Tomato4`, `Corn4`,
`Pumpkin4`, `Starfruit4` (the garden shows them when ripe; stages 1-3 of a new vegetable use the cabbage sprouts,
`Config.Food.SproutCrop`). `tools/kit/export_client_kit.luau` and `fill_client_items.luau` put them in `ClientKit.Items`.

| Model (Items id) | Source |
|---|---|
| fish (Koi) | KoiFish 89590294358011 (FishKit) |
| blueFish (Blue Fish) | BlueFish 110184517960885 (FishKit, the pond's) |
| trout, salmon, pufferfish, goldenCarp | generate_mesh, 2026-10-30 (the golden carp is a second try; it comes out peach-gold) |
| carrot, cabbage | Carrot4, Cabbage4 (CropKit) |
| tomato, corn, pumpkin, starfruit | generate_mesh, 2026-10-30 (the starfruit reads as a pale gold melon: may be redone) |

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

## WildKit.rbxm (the valley's middle, free Creator Store packs, no scripts)

Fitted by `tools/map/wild_kit.luau` (anchored, pivot at the foot), which also removed the packs' labelled display boards. Exported
once the owner has pressed Ctrl+S.

| Models | From | Notes |
|---|---|---|
| YasuTree01-20, YasuBush01-03, YasuRoots* | "Yasu's Stylized Tree Pack" 79689531752352, by mvyasu (the original; the search also lists many re-uploads under other names, not to be used) | two meshes a tree, 460-2,500 triangles; colourless canopies tinted per mood through `SurfaceAppearance.Color`, alpha leaves |
| DokiGrass1-8, DokiFlower1-7 | "Doki3D Plant Pack 01" 132133490211548, by Doki_3D | DokiFlower3 and 4 are the lupin spikes (24 triangles); the single grass blades read as lonely spikes and are not placed |

Tried and left out: "Stylized Colorful Tree Pack" 96193157220829 (ceconello, 15-31 meshes a tree), `ServerStorage.AssetTest.StylizedNature_Vexa`
(plain cones and cubes).

## Qt*, Own*, Mix* in WildKit (added 2026-11-02)

`Qt*` (30): Quaternius' "Stylized Nature MegaKit" standard version (the pack and its licence file say CC0; the author's site-wide licence, QAL v1.0 of 2026-08-28, allows use in games but
not passing the assets on as files, so the .glb files stay out of this public repo; https://quaternius.com/packs/stylizednaturemegakit.html), shrunk
for phones by `tools/map/prepare_quaternius.py`, imported by the owner. Measured triangles: rocks 244-522, pebbles 78-136, stepping stone
300, fern 288, plants 112-360, grass 155-200, clover 199, flower groups 368-449, bushes 316-499, mushrooms 250-449, trees 1,300-3,300.
`tools/map/wild_kit.luau` turns each leaf piece's `TextureID` into a `SurfaceAppearance` (ColorMap, AlphaMode Transparency): as a
TextureID Roblox ignores the alpha and every leaf card draws as a dark opaque sheet. A tint (`SurfaceAppearance.Color`) only multiplies:
the red twisted crowns stay red, the common crowns green (the wisp grass is naturally golden, `Bush_Common` naturally red).
The first import's `Bark` meshes of the trees were shredded (a decimation fault, since fixed); the owner re-imported the 11 trees with
whole trunks, which `wild_kit.luau` flattens from the imported `Scene` models in the Workspace into `QtCommonTree_1/3/5`, `QtTwistedTree_1-3`,
`QtDeadTree_1/3/5`, `QtPine_1/5` (a `Skin` crown and a `Bark` trunk, pivot at the foot). Triangles: common 2,000-2,300, twisted 3,200-3,300,
dead 1,500, pine 1,500-1,800. The trial `Mix*` trees (a crown on a Yasu trunk) are retired.

Recoloured crowns (a tint only multiplies): `tools/map/recolour_leaves.py` repaints the pack's leaf pictures (alpha kept) into
`art/models/quaternius/recolour/` (gitignored: the author's licence forbids passing the assets on as files), they were uploaded with the Studio
`upload_image` tool, and `wild_kit.luau` makes the variants `Qt<Tree>_<Colour>` with the picture as the crown's ColorMap:

| Variant | Leaf picture (asset id) |
|---|---|
| `QtTwistedTree_1/2/3_Purple` | 122236132244225 |
| `QtTwistedTree_1/2/3_Orange` | 100102769739429 |
| `QtTwistedTree_1/2/3_Gold` | 128362824192938 |
| `QtCommonTree_1/3/5_Teal` | 104754989321409 |
| `QtCommonTree_1/3/5_Purple` | 112755273870028 |
| `QtBush_Common_Green` (316 triangles) | 114563508725763 |

`QtBush_Common` wears the twisted trees' red leaf picture; `tools/map/recolour_leaves.py` (job `Twisted_Green`, picture read out of
`art/models/quaternius/Bush_Common.glb`) makes it green, for the village's bushes (2026-11-02).

The village (the home plot's template) uses these as well (`tools/map/dress_village_trees.luau`): `QtPine_1/5` and
`QtCommonTree_1/3/5` for the trees, `QtBush_Common_Green` and `QtBush_Common_Flowers` for the bushes, `QtFlower_3/4_Group`,
`QtGrass_Common_Short/Tall`, `QtFern_1`, `QtPlant_1_Big` for flower patches, grass and ferns, placed so that no upgrade piece of any
level of any area ever stands where they do (`tools/map/check_village_trees.luau`). They live in the plot's Nature folders and
FenceSkirt as Models (attribute `VillageTrees`), so `HomePlot.rbxm` carries them: nothing is read from the kit at run time.

Terrain earth: `tools/map/make_dirt.py` makes `art/textures/watercolor/DirtRoad.png` (the earthy tan road, asset 115722630865787, in `WildDirt` over
Sandstone) and `DirtWorn.png` (a dark rust brown, asset 102870054982158, in `WildWorn` over Asphalt, a terrain material no Part uses; the worn
earth of the valley's middle is Asphalt, so `Ground` stays the village soil's). Both are from Voxel Core Lab's DirtPath (CC0).

`Own*` (20), loaded by `wild_kit.luau` with `InsertService:LoadAsset` from the owner's inventory (triangles measured):

| Model | Asset id | Triangles | Used |
|---|---|---|---|
| OwnAncientJungleTree | 138768266237986 | 5,231 | grove hero |
| OwnMossyRockStack, OwnJungleStoneShelf | 95076775374326, 88910027293012 | 2,281, 3,041 | boulders (few) |
| OwnStackedBasalt, OwnMoltenPlateau | 120326438638537, 117158825911208 | 2,328, 2,390 | ember rocks |
| OwnEmberCrystalPatch, OwnMagmaCrystalCluster, OwnFiregrass | 131791034889052, 128091965429686, 79610957358740 | 1,894, 2,526, 3,164 | ember, a few each |
| OwnIceCrystalCluster, OwnIceCrystalSpire, OwnFrozenRockSpire, OwnSnowberryBush | 118055572065490, 96014375258879, 73340583537098, 133807897663279 | 2,098, 2,762, 1,496, 3,080 | frost, a few each |
| OwnFlowerBush | 110932950369537 | 3,940 | meadow, a few |
| OwnMushBlue, OwnMushPurple, OwnMushPurpleSpotted, OwnMushPink | 108230156976781, 82978024017038, 129368300885107, 105673382838100 | 400, 300, 200, 300 | grove, inner ring |
| OwnCrystalPaleBlue, OwnCrystalRed, OwnCrystalBlue | 89565445204716, 83837005139701, 81030539240809 | 120, 300, 120 | frost, ember |

The hand-made pieces cost 1,500-5,200 triangles each, so they are sprinkled by count (`SPRINKLES` in the build), never scattered.

Road texture: `art/textures/watercolor/DirtPath.png`, from Voxel Core Lab's "Hand-Painted Seamless Terrain Textures" (CC0, by Jonas
Voland, https://voxelcorelab.itch.io/watercolor-terrain-textures), brightened and shifted to tan.

## HomePlot.rbxm

The finished level-1 home plot (Plot 5, the village) as built by `tools/map/*`. The terrain under it
(the flat plot, the ring round it, the pond's water) is not in the file: `stud_floor.luau` and
`pond_water_l1.luau` make it.

## Effect textures (free Creator Store images, used by VillageFountain)

Water droplet (decal 111709169217539, daye_dreamer), "PARTICLE Water Splash" (decal 243457341, dragonome), "WaterRipple" (decal 95861972723548, Wond3rShark), "Waterfall Texture" (decal 1610017853, scopedrifle29). Images only, no scripts.
