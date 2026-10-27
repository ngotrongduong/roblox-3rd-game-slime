# The world map and the home plots — approved (2026-10-27)

The owner's direction (2026-10-27, before Phase 2): one wide map shared by a server. Around its
edge, 8 home plots (one a player) and a trading area. In the middle, a large flat forest-garden
where monster slimes appear at random; players take their slimes there to fight monsters, and may
fight other players' slimes. Each home plot holds a fishing area, a garden, a kitchen, a pantry, a
training ground and a breeding area; every area has many upgrade levels, each level changing its
look a little and raising its use. Visual quality first; balance later.

New rules the owner set at the same time (they replace the original where they differ):
- Slimes work to gather food; food can be cooked into dishes that fill them up more.
- An unfed slime does not breed and works at 50% (the original: starving workers stop).
- Fishing, garden and kitchen take up to 4 workers each, starting with 1 slot, more by upgrades.
- The breeding area takes the chosen slimes; babies take time to grow up (as in Phase 1).

Everything below is a proposal: names, sizes and level counts are starting points to try in a
greybox, not decisions.

## 1. The world: "the Goo Valley"

A round valley, about 1,000 × 1,000 studs, ringed by low hills and forest that close it in (no
edge to fall off, and a cozy "everything in one bowl" feel). Seen from above it is a clock face:

- **The rim (9 places):** the **Market** at 12 o'clock, and the **8 home plots** at the other
  eight places, evenly around the rim. Every plot is the same size and the same distance from
  the middle, so no player gets a better spot. Low hedges and trees separate neighbours.
- **The Wild Garden (the middle):** a flat forest-garden about 600 studs across, open grass with
  groves, flower beds, little streams with stepping stones and bridges, mushroom rings. Monster
  slimes live here.
- **Paths:** a ring road between the rim and the Wild Garden joins every plot to the Market and
  to its neighbours; each plot's gate opens onto it and faces the middle.

Walking speed on Roblox is about 16 studs a second: plot gate to the Wild Garden's edge is about
5 s, a plot to the Market up to about 40 s along the ring. On phones, three quick-travel buttons
(Home, Market, Wild Garden) save the walk; walking stays the pleasant way.

### 1.1 The Wild Garden: four moods and a heart

Flat everywhere (easy to walk, easy on phones), but split into four soft-edged quarters that
bring back the four battle maps of the original and its four enemy families, so the roster, art
direction and loot of `docs/reference/02-battle.md` carry over:

| Quarter | Mood | Monsters (from the original) | Map material |
|---|---|---|---|
| Sunny Meadow | flowers, butterflies, light | green: sprout, snail, bee, boar, turtle… | boar tusk |
| Mushroom Grove | big glowing mushrooms, shade, fireflies | dark: wisp, spider, moth, wolf, golem… | glow spore |
| Ember Garden | warm stones, red leaves, little lava streams kept to channels | magma: imp, beetle, slug, crab, bull… | ember scale |
| Frost Glade | frosted grass, blue pines, snow drifting | ice: snowball, owl, wolf, yeti… | frost crystal |

Monsters get stronger from the rim toward the middle: the band nearest the ring road is for new
squads, the inner band for strong ones. At the very middle is **the Heart**: a round clearing
with an old goo spring, where the **World Boss** (King Goo, later Queen Nyx) rises on a server
timer and everyone fights it together — the original's raid, now shared.

Monster slimes do not wander everywhere: they bubble up from **goo springs** (puddles that
glow softly when a monster is about to appear), a few per quarter, a capped number on the map
at once, so the Wild Garden is lively without costing phones too much.

### 1.2 Fights

- **Against monsters:** a player walks into the Wild Garden with a **squad** (a few slimes that
  follow them, chosen at home; the original's Siege squads were 10, a walking squad is smaller,
  e.g. 3 rising to 5 with upgrades). Touching a monster group starts a fight in place: the
  squad and the monsters fight on the spot inside a soft ring of light, with the original's
  combat rules (weapon classes, skills, crits, statuses). Win: drops (rare, as the owner wants).
  Lose: slimes faint and walk home to the training ground to recover; nothing is ever deleted.
- **Against other players:** only when both agree. Either a **challenge** (tap a player → Duel →
  they accept) fought on the spot, or the two **Duel Rings** at the edge of the Heart, where
  anyone can queue. No slime is lost; winners earn rank points and a small reward. A player
  who does not want fights is never attacked.

### 1.3 The Market (12 o'clock)

The social hub and the spawn point: a small square town in the owner's market style (honey wood,
royal-blue and cream awnings, money-bag emblems, gold trims, lanterns).

- **The Shop** (shopkeeper): sell slimes; buy seeds, bait, basic items.
- **The Smithy** (blacksmith, furnace and anvil): craft hand/head/tail gear from drops.
- **The Travelling Merchant's stop:** his cart rolls in for 5 of every 15 minutes, the same for
  the whole server, with 8 random rare wares (auras, wings, frames, backgrounds).
- **Trading stalls:** player-to-player trade (slimes, eggs, gear, materials) with a two-sided
  confirm window; a few stalls players can stand at to show what they offer.
- **The Notice Board:** leaderboards (best slime, raid score, duel rank), the World Boss timer.
- **The Fountain:** the spawn point and the place where quick travel lands.

## 2. A home plot

About 160 × 160 studs, a square opening onto the ring road. The plot's gate faces the middle;
its back is the valley's edge (hills, a waterfall feeding the pond). Its name sign and the
player's banner colour stand at the gate.

The areas are placed so food flows from the outside in, and the breeding area sits at the heart:

```
              valley edge (hills, waterfall)
   +------------------+------------------+------------------+
   |  Fishing pond    |  Pantry          |  Garden          |
   |  (back-left)     |  (back-middle)   |  (back-right)    |
   +------------------+------------------+------------------+
   |  Kitchen         |  Slime meadow    |  Breeding house  |
   |  (left)          |  + home house    |  + nursery (right)|
   +------------------+------------------+------------------+
   |  Training ground |  Gate & square   |  Hatchery nest   |
   |  (front-left)    |  (front-middle)  |  (front-right)   |
   +------------------+------------------+------------------+
              ring road → the Wild Garden
```

- Fishing pond and garden produce → the pantry beside them stores → the kitchen beside the
  pantry cooks → slimes eat in the meadow.
- The breeding house is beside the meadow (parents walk in from it), the hatchery nest and
  nursery in front of it (eggs, then babies growing up).
- The training ground is by the gate, the way out to the Wild Garden: squads gather there before
  a trip and come back there to recover.
- The slime meadow in the middle is where idle slimes wander, hop, nap and chatter.

**The plot as a small village (the owner, 2026-10-27).** Every area turns to face the middle
(`Layout.plotAreaFacing`; the corner areas sit at 45°). The middle is a round stone stud plaza with
a well, lamp posts and flower planters; stud stone paths run from it to each area's entrance and to
the gate. A tall wooden fence (10 studs, posts every 8) runs round the whole plot, with a gate of two
roofed towers and a name board at the front middle. Trees from the nature kit stand in a ring
inside the fence between the areas; the empty front-right cell is a small grove for now (kept for
the nursery). The slime meadow is skipped for now. The fishing pond holds real terrain water.
Built by `tools/map/build_village.luau`; pictures `docs/areas/village-gate.jpg`,
`docs/areas/village-top.jpg`.

### 2.1 Areas, workers and levels

Each area has **10 levels** (a starting point). Every level adds one small visible piece and a
little more use; levels 4, 7 and 10 are bigger remodels where the building itself grows.

| Area | What it does | Workers | Every level (small) | Remodels at 4 / 7 / 10 |
|---|---|---|---|---|
| Fishing pond | slimes catch fish (raw food) | 1 → 4 (slots at levels 1, 3, 6, 9) | a bucket, a lantern, a reed patch, a net rack, a second rod… | 4: a wooden dock; 7: a covered pier and a little boat; 10: a big lake pier with a lighthouse lantern |
| Garden | slimes grow vegetables and berries | 1 → 4 | a new row, a scarecrow, a watering can, sunflowers… | 4: raised beds; 7: a greenhouse corner; 10: a full greenhouse with sprinklers |
| Kitchen | cooks raw food into dishes (more fullness, later small buffs) | 1 → 4 | a pot, a spice shelf, a second stove, a chimney… | 4: an open-air kitchen with a roof; 7: a cottage kitchen with an oven; 10: a grand kitchen with a big cauldron and steam |
| Pantry | stores raw food and dishes; its level is the cap | — | more shelves, crates, barrels, sacks | 4: a stone cellar door; 7: a two-storey storehouse; 10: a granary with a weather vane |
| Training ground | raises stats slowly by training; squads gather and recover here | 1 → 4 | a dummy, a hurdle, a weights rack, a target | 4: a fenced yard; 7: a dojo roof; 10: an arena with banners |
| Breeding house | the chosen pairs breed here; level shortens rest and incubation, adds pairs at once | 1 → 3 pairs | flowers, a heart sign, cushions, a bell | 4: a bigger cottage; 7: a two-room house; 10: a manor with a garden |
| Hatchery nest + nursery | eggs incubate, babies grow; level adds egg places and speeds growing | 4 → 8 eggs | more straw, a warm lamp, a baby pen | 4: a covered nest; 7: a glass incubator; 10: a hatchery with a clock tower |

Upgrades cost coins and materials (fish, vegetables, wood, ore and the Wild Garden's drops),
so fights feed the farm and the farm feeds fights. All numbers come later, with the balance work.

Changing looks by level uses one model per area with numbered pieces that switch on with the
level (cheap, and always consistent), plus three remodel models per area; every model follows
the owner's art style and is checked against their paintings.

### 2.2 Food loop (the owner's new rules)

- Raw food: fish (pond), vegetables and berries (garden). Dishes: the kitchen turns raw food into
  dishes that fill more (e.g. a fish stew fills more than a fish).
- Slimes eat by themselves from the pantry when hungry; dishes first, then raw food.
- A hungry slime (not fed) does not breed and works and fights at 50%. Nothing dies, no stat is
  lost (as in the original).
- Offline: the farm keeps working while away, up to a cap, as in the original.

## 3. The server and phones

- 8 players a server (one plot each). A new player gets a free plot; their plot appears with
  their farm when they join and clears when they leave.
- StreamingEnabled: far plots and quarters stream out; other players' plots show a light
  version from afar. Monster count, particles and animated slimes are capped per client.
- One art style everywhere: chunky, rounded, saturated cartoon models matching the owner's
  paintings; bright soft daylight; the Wild Garden slightly more magical (fireflies, glow).

## 4. Approved by the owner (2026-10-27)

All four points below were approved as proposed.

1. The Market at 12 o'clock as the spawn and hub, plots around the rest of the rim.
2. The Wild Garden in four mood quarters (meadow, mushroom, ember, frost) with the World Boss at
   its heart — or one single meadow-forest everywhere.
3. Fights between players only when both agree (challenge or Duel Rings).
4. 10 levels an area, with a small change every level and remodels at 4, 7 and 10.
