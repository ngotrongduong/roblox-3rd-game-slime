# Fishing pond (home plot, back-left area)

The owner restarted the plot design on 2026-10-27: each area is designed and built directly in
Studio, one at a time, simple and clean, starting with the level-1 fishing pond with ONE spot where a
slime stands and fishes. (The earlier route, ChatGPT concept sheets turned into generated meshes, is
set aside; the concept sheets in `art/concept/` stay as mood references only.)

## Level 1 (built: `tools/map/build_fishing_l1.luau`, pictures `fishing-l1.jpg`, `fishing-l1-wide.jpg`)

Inside the plot's fishing cell (about 53 x 53 studs):

| Piece | What | Notes |
|---|---|---|
| Pond | terrain water in three soft lobes (radius 16 + 11 + 11 studs), a sandy rim, grass around | room for a longer dock and more spots later |
| Dock | 6 x 19 studs of planks in two honey tones, two beams under, four round posts with rope rings | from the front shore straight out over the water |
| Fishing spot 1 | a round straw mat at the dock's end with an Attachment `WorkSpot1` | where the working slime stands, facing the water; gameplay reads its WorldCFrame |
| Rod | in a holder beside the spot, line and red-and-white bobber on the water | the slime's tool; later held by the slime's animation |
| Bucket | metal bucket with the catch beside the spot | fills as fish are caught (later) |
| Lantern post + sign | at the shore end of the dock; the sign shows a fish icon | the sign is the area's interaction point: tap it to see the level and upgrade (docs/UI.md) |
| Dressing | two reed clumps, lily pads, round stones, two flowering bushes | few, big, readable |

Interaction (to build with gameplay): tap the mat (or a ProximityPrompt there) to assign a slime;
tap the sign to open the small upgrade card. No text in the world: icons only, in English when text
is needed.

## 50 levels, second pass (the owner, 2026-10-27; replaces the eras table below)

The dock keeps its size; nothing is ever taken away. Five parts: 1 deck (planks, beams, posts),
2 rails, 3 lamps at both ends, 4 a bait box, 5 bollards with rope (and light strips from tier 7).
Levels 1-5 add them one by one in rustic wood; from level 6 every five levels are a material tier
(painted wood, stone and timber, brick, workshop iron, glass house, modern metal, tech, slime tech,
marble and gold) and each level moves one part up to it, in the same order. No rods (slimes carry
their own) and no side platforms: work spots 1-4 are on the dock's open far end (2 from level 11,
3 from 21, 4 from 31). In game: walk to the dock and press E (`src/server/AreaUpgrade.server.luau`,
stages in `src/server/PondStages.luau`). Play tests start beside the pond (`tools/map/dev_spawn.luau`).
Pictures `docs/areas/fishing-ingame/v2-*.jpg`.

## 50 levels, ten eras (first pass, replaced above)

Approved plan: 50 levels, a remodel every 5 (the first level of each era: 1, 6, 11 ... 46) and one
small change at each level between, always in this order: a decoration, rails along the dock (the
material step), a fishing tool, lights or glow. Work spots: 1 (eras 1-2), 2 (3-4), 3 (5-6), 4 (7-10).
The owner asked to see it built straight away, no picture first.

| Era | Levels | Look | Landmarks (PropKit, generate_mesh) |
|---|---|---|---|
| 1 | 1-5 | rustic wood | (none) |
| 2 | 6-10 | painted wood, blue posts | NetRack |
| 3 | 11-15 | stone pier head, timber | NetRack, FishingHut |
| 4 | 16-20 | brick pier head | Boathouse, RowBoat |
| 5 | 21-25 | workshop, iron posts | WaterWheel, NetCrane, RowBoat |
| 6 | 26-30 | white glass-house | GlassPavilion, FishTank |
| 7 | 31-35 | metal deck, warm trim | ModernKiosk (solar roof), FishCooler |
| 8 | 36-40 | dark tech deck, blue neon | AutoReel, Drone, ModernKiosk |
| 9 | 41-45 | slime tech, green neon | GooPump, CrystalBuoy, Drone |
| 10 | 46-50 | marble and gold | Lighthouse, GoldFountain, CrystalBuoy |

Showcase (to look at, not the game): `tools/map/build_pond_showcase.luau` builds floating ponds west
of the valley in the work place: row 1 each era at its last level, row 2 the five levels of era 4.
Pictures `docs/areas/fishing-eras/*.jpg`.

## Later levels (old plan, replaced above: one change each level, remodel at 4 / 7 / 10)

- Level 2-3: a second spot (mat) at the dock's side, a net rack, more lily pads.
- Level 4: the dock widens and gets a small roof over the end; spots 2-3.
- Level 7: a covered pier and a little rowing boat; spot 3-4 (slots: 1 at level 1, 2 at 3, 3 at 6, 4 at 9).
- Level 10: a long pier with a lighthouse-lantern tower.

## Open points

- No slime is placed in the builds (the owner: slimes come later).
- The rod should lean further out over the water; the lily pads sit at the measured water level but
  hardly show from the gate's angle.
