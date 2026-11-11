# Molten Lava monster slimes: bones, weights and motion

Built by `tools/blender/monster_rig.py` with this region's rigs and motions in `tools/blender/monster_rig_lava.py`
(`tools/blender/monster_rig.ps1 lava all full`). Outputs are `<Name>/<Name>.fbx` and `<Name>/<Name>.png` (own 1024 texture,
UV map "Own"), `lava_rigged.blend` (actions `<Name>_<Action>`), `rig_lava.json` and `review/`.

Conventions, the cage, swell, the one rule for parts and the shared bodies are as in `../ice/MOTION.md` (which builds on
`../meadow/MOTION.md`).

- Joints, parents and part vectors: `rig_lava.json` (Blender and Roblox axes).
- Exact poses: its `golden` samples.

## Spine bodies (Scorchdart)

Scorchdart has no cage. Body (root) carries the body channels; Spine1..4 run along its length (y) as a chain.

- Spine1 sinks by 0.3 squash Hj.
- Every later bone moves along its own segment (`seg` in the JSON) by -0.3 squash, so a stretch lengthens the body.
- Loose pieces ride the nearest spine bone.

## Wickling (swarmer) — 3000 budget, peak 0.37 s

- **Crust** (parent Top): the highest big island, cut where its radius profile narrows.
- **Wick1-2** (chain on Crust): the wick, grown along the surface.
- `wick(p1, r1, p2, r2)`: p2, r2 default to 1.3 x p1, r1.
- std(hop 0.2).
- Idle:
  - wick(0.06 sin(pi t - 1) - 0.6 (pitch 0.2 s late - 0.05), 0.05 sin(pi t + 0.4), 0.1 sin(pi t - 1.8), 0.08 sin(pi t - 0.5))
  - Crust.z = 0.2H (squash - squash 0.12 s late)
- Move:
  - Wick1.p = -0.9 pitch 0.12 s late + 0.5 squash 0.15 s late
  - Wick2.p = -1.2 pitch 0.2 s late + 0.7 squash 0.22 s late
  - Crust.z = 0.3 (lift 0.05 s late - lift); Crust.r = ring(0.68, 0.06, 7, 0.25) (periodic)
- **Attack** (0.85 s):
  - Body:
    - fwd keys[(0,0),(0.22,0.3),(0.35,-1),(0.55,-0.9),(0.85,0)]
    - squash keys[(0,0),(0.22,0.2),(0.33,-0.22),(0.4,0.12),(0.5,0)]
    - pitch keys[(0,0),(0.22,-0.2),(0.35,0.28),(0.85,0)] + 0.15 hump(0.37,0.44) + 0.15 hump(0.46,0.53)
    - lift 0.3 hump(0.24,0.4)
  - Wick1.p = keys[(0,0),(0.22,0.25),(0.35,-0.3)] (1 - smoothstep(0.35,0.4)) + ring(0.37, -0.35, 3, 0.3)
  - Wick2.p = keys[(0,0),(0.25,0.35),(0.38,-0.4)] (1 - smoothstep(0.38,0.43)) + ring(0.4, -0.45, 3, 0.3)
  - Crust.p = ring(0.36, 0.06, 7, 0.25)
- Hit:
  - wick(ring(0.03, -0.3, 4, 0.3) e, ring(0.03, 0.15, 5, 0.3) e)
  - Crust.r = ring(0, 0.08, 9, 0.2) e; Crust.z = 0.06 hump(0,0.2)
- Die:
  - wick(keys[(0,0),(0.15,-0.2),(1.1,0.5)], keys[(0,0),(1.1,0.3)], keys[(0,0),(0.2,-0.2),(1.1,0.7)], keys[(0,0),(1.1,0.4)])
  - Crust.r = keys[(0,0),(1,0.2)]; Crust.z = keys[(0,0),(0.15,0.08),(1.1,-0.2)]

## Scorchdart (hunter, spine body) — peak 0.42 s

- `wave(A, f, lag, ph, grow 0.35)`: Spine k.y = A (1 + 0.35k) sin(2pi f t - lag k + ph), k = 0..3.
- Idle (2 s): squash 0.04 sin(pi t); pitch 0.02 sin(pi t - 0.5); wave(0.04, 0.5, lag 0.9).
- Move (0.6 s, a darting slither):
  - fwd -0.25 sin(wt); squash -0.12 sin(wt) + 0.04; yaw 0.08 sin(wt + 0.8); lift 0.03H (1 - cos wt)/2, with w = 2pi/0.6
  - wave(0.14, 1/0.6, lag 1.0)
- **Attack** (0.9 s, coil and strike):
  - Body:
    - fwd keys[(0,0),(0.3,0.5),(0.4,-2),(0.55,-1.9),(0.9,0)]
    - squash keys[(0,0),(0.3,0.25),(0.38,-0.35),(0.5,-0.2),(0.62,0.1),(0.9,0)]
    - pitch keys[(0,0),(0.3,-0.12),(0.4,0.12),(0.9,0)]
    - lift 0.15 hump(0.32,0.5)
  - coil = keys[(0,0),(0.3,1),(0.38,0)]
  - Spine k.y = coil (0, 0.3, -0.4, 0.45)[k] + ring(0.4 + 0.04k, (0, 0.12, -0.2, 0.3)[k], 3, 0.3)
- Hit: Spine k.y = ring(0.03k, 0.12 (1 + 0.3k), 4, 0.3) e.
- Die: Spine k.y = keys[(0,0),(0.15,-0.1),(1.1,0.25)]; Spine k.p = keys[(0,0),(1.1,-0.05k)] for k = 1..3.

## Blazegullet (spitter) — peak 0.64 s

- **Sac** (parent Top): the glowing belly, a smooth dome weight with an `out` vector.
- The lips have no clean cut and ride the cage.
- std(hop 0.15, heavy 1.15, depth 0.045).
- Idle: Sac.o = 0.06 sin(pi t - 0.5) + 0.03 sin(2pi t).
- Move: Sac.o = 0.5 squash 0.1 s late; Sac.z = 0.3 (lift 0.07 s late - lift).
- **Attack** (1.2 s, gulp and spit):
  - Body:
    - pitch keys[(0,0),(0.42,-0.25),(0.62,0.25),(1.2,0)] + ring(0.62, 0.06, 3, 0.4)
    - lift keys[(0,0),(0.42,0.25),(0.62,0)]
    - squash keys[(0,0),(0.42,-0.15),(0.62,0.2),(0.8,0)]
    - swell keys[(0,0),(0.42,0.12),(0.62,-0.05),(0.8,0)]
  - Sac.o = keys[(0,0),(0.42,0.35),(0.6,0.35),(0.66,-0.1),(0.85,0)] + ring(0.85, 0.05, 4, 0.3)
  - Sac.z = keys[(0,0),(0.42,-0.1),(0.66,0.05),(1,0)]
- Hit: Sac.o = ring(0.02, -0.15, 5, 0.3) e.
- Die: Sac.o = keys[(0,0),(0.15,0.1),(1.1,-0.1)]; Sac.z = keys[(0,0),(1.1,-0.2)].

## Pyrekeeper (healer, the only hover: 0.5) — peak 0.42 s

- **Brazier** (parent Top): everything above the neck, z 2.81.
- **Ring** (parent Body): the gold ring and its shards. `spin_axis` (0.02, -0.34, 0.94) Blender, from its principal axes.
- Flyer bodies (std).
- Idle is an 8 s loop, Move a 4 s loop (four 2 s / 1 s body cycles each), each holding one whole ring turn so they join.
- Idle:
  - Ring.spin = 2pi t/8; Ring.p = 0.03 sin(pi t/2)
  - Brazier.p = -0.5 (pitch 0.2 s late - 0.08); Brazier.r = -0.5 roll 0.2 s late
- Move: Ring.spin = 2pi t/4; Ring.p = -0.3 pitch 0.1 s late; Brazier.p = -0.7 pitch 0.12 s late.
- **Attack** (1.2 s, heal):
  - Body:
    - lift keys[(0,0),(0.3,0.3),(0.95,0.3),(1.2,0)]
    - squash keys[(0,0),(0.3,-0.1),(0.95,-0.1),(1.2,0)]
    - swell 0.08 (three humps 0.35-0.5, 0.55-0.7, 0.75-0.9)
    - pitch keys[(0,0),(0.3,-0.08),(1.2,0)]
  - Ring.spin = 2 x 2pi smoothstep(0.05,1.15,t)
  - Brazier.z = keys[(0,0),(0.3,0.3),(0.95,0.25),(1.2,0)]; Brazier.p = ring(0.3, -0.1, 2, 0.3); Brazier.r = ring(0.35, 0.06, 2.5, 0.3)
- Hit:
  - Ring.p = ring(0, 0.12, 4, 0.3) e; Ring.r = ring(0.03, 0.08, 5, 0.3) e
  - Brazier.r = ring(0, 0.08, 8, 0.25) e; Brazier.z = 0.06 hump(0,0.2)
- Die (falls to the ground):
  - Ring.p = keys[(0,0),(0.6,0.15),(1,0.3)]; Ring.spin = 0.6 smoothstep(0,0.9); Ring.z = keys[(0,0),(1,-0.3)]
  - Brazier.r = keys[(0,0),(1.1,0.35)]; Brazier.z = keys[(0,0),(1.1,-0.2)]

## Basaltback (armoured) — peak 0.58 s

- **Columns** (parent Top): every vertex above z 1.08, rigid.
- std(hop 0.06, heavy 1.4, depth 0.03).
- Idle: Columns.z = 0.2H (squash - squash 0.2 s late); Columns.p = 0.015 sin(pi t - 1.3).
- Move:
  - Columns.z = 0.4 (lift 0.06 s late - lift) + ring(0.68, -0.06, 6, 0.3)
  - Columns.p = ring(0.7, 0.05, 7, 0.3) (periodic)
- **Attack** (1.1 s, shoulder shove):
  - Body:
    - fwd keys[(0,0),(0.35,0.3),(0.45,0.3),(0.58,-1.2),(0.7,-1.1),(1.1,0)]
    - squash keys[(0,0),(0.35,0.2),(0.5,-0.1),(0.6,0.12),(0.8,0)] + ring(0.6, 0.05, 3, 0.4)
    - pitch keys[(0,0),(0.35,-0.12),(0.58,0.2),(1.1,0)]
  - Columns.f = 0.5 (fwd 0.06 s late - fwd); Columns.p = ring(0.58, 0.1, 5, 0.3); Columns.z = ring(0.58, -0.08, 6, 0.3)
- Hit: Columns.r = ring(0, 0.05, 10, 0.2) e; Columns.p = ring(0.02, 0.04, 9, 0.2) e; Columns.z = 0.05 hump(0,0.2).
- Die: Columns.p = keys[(0,0),(1.1,0.15)]; Columns.r = keys[(0,0),(1.1,-0.1)]; Columns.z = keys[(0,0),(0.15,0.08),(1.1,-0.3)].

## Magmaw (mini-boss) — peak 0.72 s

- **Jaw** (parent Front): a soft region below the mouth line z 4.06 (the gap between the teeth rows), forward of
  y -1.04, with the lower teeth.
- The 8 shoulder spikes ride Left and Right.
- std(hop 0.08, heavy 1.3, depth 0.035).
- Idle: Jaw.p = 0.05 + 0.04 sin(pi t - 0.8).
- Move: Jaw.p = 0.05 + 2.4 (lift 0.06 s late - lift)/H + 0.3 squash 0.1 s late.
- **Attack** (1.3 s, leap and chomp):
  - Body:
    - lift keys[(0,0),(0.45,1.2),(0.6,1.2),(0.72,0)]
    - squash keys[(0,0),(0.2,0.15),(0.45,-0.25),(0.62,-0.2),(0.72,0)] + ring(0.72, 0.6, 1.8, 0.35)
    - pitch keys[(0,0),(0.45,-0.3),(0.65,0.1),(1.3,0)]
  - Jaw.p = keys[(0,0.05),(0.45,0.45),(0.65,0.4),(0.74,-0.05),(1.3,0.05)] + ring(0.74, 0.08, 4, 0.3)
- Hit: Jaw.p = 0.05 + 0.2 hump(0,0.3) + ring(0.1, 0.05, 5, 0.3) e.
- Die: Jaw.p = keys[(0,0.05),(0.2,0.3),(1.1,0.4)].

## Calderos (boss) — peak 0.8 s

| Bone | Parent | What it holds |
|---|---|---|
| Mask | Top | the face mask, a box |
| PlateL / PlateR | Left / Right | the cheek plates |
| Mane1-3 | chain on Top | the mane along (0, 0.99, 0.15), with a height fade; the dark fins ride the Mane bones |

- `plates(z, r)` sets PlateL.z = PlateR.z = z, PlateL.r = r, PlateR.r = -r.
- Chain turns add up: about 0.4 rad of flare at the mane's end in all.
- std(hop 0.06, heavy 1.5, depth 0.03).
- Idle: Mane k.p = 0.04 (1 + 0.5k) sin(pi t - 0.8k) - 0.4 (pitch (0.2 + 0.1k) s late - 0.05); Mask.p = 0.01 sin(pi t - 0.3).
- Move:
  - Mane k.p = -0.6 pitch (0.1 + 0.07k) s late - 0.25 squash (0.12 + 0.07k) s late
  - plates(0.3 (lift 0.05 s late - lift))
- **Attack** (1.6 s, eruption):
  - Body:
    - squash keys[(0,0),(0.45,0.3),(0.75,-0.35),(0.95,-0.25),(1.05,0)] + ring(1.05, 0.6, 1.6, 0.35)
    - lift keys[(0,0),(0.45,0),(0.75,0.12H),(0.95,0.12H),(1.05,0)]
    - pitch keys[(0,0),(0.45,0.12),(0.75,-0.2),(1.05,0.08),(1.6,0)]
  - Mane k.p = keys at t - 0.04k [(0,0),(0.45,-0.04),(0.75,0.12+0.02k),(0.95,0.1)] (1 - smoothstep(0.95,1.3)) + ring(1.05 + 0.05k, -0.1, 1.4, 0.3)
  - Mask.p = keys[(0,0),(0.45,0.08),(0.75,-0.35),(0.95,-0.3),(1.2,0)] + ring(1.05, 0.15, 2.5, 0.3)
  - plates(ring(1.05, -0.12, 5, 0.3), keys[(0,0),(0.75,0.12),(1,0)])
- Hit: Mane k.p = -0.8 pitch (0.06 + 0.04k) s late; Mask.p = ring(0, -0.05, 6, 0.3) e.
- Die: Mane k.p = keys[(0,0),(0.2,0.05),(1.1,-0.12)]; Mask.p = keys[(0,0),(0.15,-0.1),(1.1,0.2)]; plates(keys[(0,0),(1.1,-0.2)]).

## Known limits

- Blazegullet's lips have no clean cut and ride the cage.
- Wickling's dead pose: one crust flake dips just below the ground at full melt (squash 0.85).
- Calderos's mane once over-rotated into the back; its amplitudes were cut to the numbers above and rechecked on the sheet.
