# The village: tall fence, gate and plaza (home plot)

Built by `tools/map/build_village.luau` (paving, well, lamps, planters) and `replace_fences.luau`
(the kit palisade and VillageGate). Its upgrades are `src/server/VillageStages.luau`, run by
`AreaUpgrade.server.luau`. Pictures `upgrades/village-l50.jpg`, `upgrades/village-plaza-l50.jpg`.

## Village level

The village has no prompt of its own: its level is the average of the six areas' levels, rounded
down (`VillageStages.levelOf`), so it grows as the player upgrades the farm and reaches 50 only when
every area is 50. The layer is rebuilt when that number moves.

## Upgrades, levels 1-50 (the pantry's pattern)

- Era start (1 / 11 / 21 / 31 / 41): 1 the well, stone footing and pillars along the fence, a paved
  landing at the gate; 11 a small fountain in place of the well, lanterns on the pillars, banner
  poles by the gate; 21 a two-tier fountain, stone wing walls either side of the gate; 31 a fountain
  with a slime statue, slime guardian statues outside the gate, pennants on every other pillar; 41
  the grand fountain with a golden slime, a golden crest over the gate.
- Levels 2-5 of an era: one plaza prop a level, on the lawn in the four path gaps without a lamp,
  facing the well. Seating: LogBench > ParkBench > GardenSwing > CafeTable > GoldenBench. Notices:
  Signpost > NoticeBoard > ClockPost > InfoKiosk > HoloBoard. Stalls: FlowerCart > FruitStall >
  IceCreamCart > BakeryKiosk > GooVending. Garden: Birdbath > Topiary > Sundial > LightTree >
  SlimeCrystal.
- Levels 6-10 of an era: plaza paving, path paving, fence pillars and footing, lanterns and banners,
  gate stonework each move up one material tier.
