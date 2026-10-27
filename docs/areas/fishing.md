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

## Later levels (to design next, one change each level, remodel at 4 / 7 / 10)

- Level 2-3: a second spot (mat) at the dock's side, a net rack, more lily pads.
- Level 4: the dock widens and gets a small roof over the end; spots 2-3.
- Level 7: a covered pier and a little rowing boat; spot 3-4 (slots: 1 at level 1, 2 at 3, 3 at 6, 4 at 9).
- Level 10: a long pier with a lighthouse-lantern tower.

## Open points

- The slime here is a stand-in (a navy ball with a tip); the real slime model is its own task.
- The rod should lean further out over the water; the lily pads sit at the measured water level but
  hardly show from the gate's angle.
