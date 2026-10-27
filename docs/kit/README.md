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
| FlowerShrub | 76342140455262 |
| CampFlame | from "Realistic Fire VFX" 12136850996 in the owner's inventory (another creator's free pack, scripts removed) |

## NatureKit.rbxm

The free Creator Store "Nature stylized Pack" (109637424937405, no scripts): bushes, flowers, ferns,
tufts, rocks, stumps, logs, water lilies, trees.

## HomePlot.rbxm

The finished level-1 home plot (Plot 5, the village) as built by `tools/map/*`. The terrain under it
(the flat plot, the ring round it, the pond's water) is not in the file: `stud_floor.luau` and
`pond_water_l1.luau` make it.
