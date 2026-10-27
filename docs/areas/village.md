# The village: tall fence, gate, paths and plaza (home plot)

Built by `tools/map/build_village.luau` (paving, well, lamps, planters) and `replace_fences.luau`
(the kit palisade and VillageGate). Its upgrades are `src/server/VillageStages.luau`, run by
`AreaUpgrade.server.luau`. Pictures in `upgrades/`: `village-plaza-l25.jpg`, `village-plaza-l50.jpg`,
`village-gate-l25.jpg`, `village-gate-l35.jpg`, `village-l50.jpg`.

## Village level

The village has no prompt of its own: its level is the average of the six areas' levels, rounded
down (`VillageStages.levelOf`), so it grows as the player upgrades the farm. The layer is rebuilt
when that number moves.

## Upgrades, levels 1-50 (redone 2026-10-28 at the owner's word: the fence and gate must change with
the eras, lamps and paths too, many decorations a level, each placed, turned and sized sensibly)

- Era start (1 / 11 / 21 / 31 / 41): the whole look changes.
  - Fence: kit palisade > painted timber boards > stone wall with battlements and towers > steel
    and glass with light strips > marble wall with a balustrade and round columns.
  - Gate: kit gate > timber gatehouse > stone gatehouse with a battlemented bridge > steel and glass
    portal with a lit canopy > marble arch with a pediment and a golden crest.
  - Paths: plain > a darker border > a checked middle; the plaza gets rings (era 3) and spokes (era 4).
  - Lamps: 12, in the era's style (VillageLamp, LanternPost, IronStreetLamp, ModernLampPost,
    GoldenLampPost), on the lawn beside the paths and at the plaza's edge, facing the paths.
  - Centrepiece: the well > SmallFountain > TieredFountain > StatueFountain > GrandFountain.
- Level 2 of an era: 10 benches in the era's style (LogBench, ParkBench, IronBench, ModernBench,
  MarbleBench), one beside each path facing it and two facing the fountain from the gate side.
- Level 3: 8 more lamps on the paths' far halves.
- Level 4: market stalls round the plaza, one more each era (FlowerCart, FruitStall, IceCreamCart,
  BakeryKiosk, GooVending), the older ones stay; a notice board inside the gate and one at the plaza.
- Level 5: garden pieces in the path gaps (two, four from era 3, the newest and the one before by
  turns) and eight flower planters lining the gate path.
- Levels 6-10: plaza paving, path paving, fence walls, fence pillars, gate each move up one tier.

Nothing is set on free ground by chance: every prop checks its spot (not on the paving, not in an
area, not near the fence, at least 1.2 studs of room from what already stands, trees and the old
planters included) and slides along its path or back a little until it is free, or is left out;
small plants that ended up on a path are taken away (the owner, 2026-10-28: a lamp in front of a
bench, flowers in the middle of a path). Picture `upgrades/village-plaza-l45.jpg`.

Every model stands at its real height (the player is 5 studs): lamps 8.4-9.6, benches 1.5-2.8,
stalls 3.6-5.6, fountains 5-11.
