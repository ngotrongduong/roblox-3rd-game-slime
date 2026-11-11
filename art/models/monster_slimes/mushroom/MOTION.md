# Fungal Mushroom monster slimes: bones, weights and motion

Built by `tools/blender/monster_rig.py` with this region's rigs and motions in `tools/blender/monster_rig_mushroom.py`
(`tools/blender/monster_rig.ps1 mushroom all full`). Outputs are `<Name>/<Name>.fbx` and `<Name>/<Name>.png` (own 1024
texture, UV map "Own"), `mushroom_rigged.blend` (actions `<Name>_<Action>`), `rig_mushroom.json` and `review/`.

Conventions, the cage, swell, the one rule for parts (drives `<Part>.p/.r/.y/.x/.f/.z/.o/.spin`) and the shared bodies are
as in `../ice/MOTION.md` (which builds on `../meadow/MOTION.md`).

- Joints, parents and part vectors: `rig_mushroom.json`.
- Exact poses: its `golden` samples.

## Gloomtick (swarmer) — peak 0.46 s

- **Carapace** (parent Top): the shell rim at the widest slice, plus its thin spikes.
- **MandibleL/R** (parent Front): the pale mandible islands.
- `mand(a, droop)` sets MandibleL.y = a, MandibleR.y = -a, both .p = droop.
- std(hop 0.12).
- Idle:
  - mand(0.08 + 0.07 sin(3pi t) sin^2(pi t))
  - Carapace.z = 0.25H (squash - squash 0.15 s late); Carapace.p = 0.02 sin(pi t - 1)
- Move (0.6 s scuttle, w = 2pi/0.6):
  - Body: lift 0.05H |sin wt|; squash 0.1 cos 2wt; pitch 0.1 + 0.04 sin 2wt; roll 0.07 sin wt; yaw 0.05 sin(wt + 0.5)
  - mand(0.15 + 0.15 sin 2wt)
  - Carapace.z = 0.3 (lift 0.05 s late - lift); Carapace.r = 0.04 sin(2wt + 1); Carapace.p = 0.03 sin 2wt
- **Attack** (0.9 s):
  - Body:
    - fwd keys[(0,0),(0.3,0.25),(0.42,-1.2),(0.55,-1.1),(0.9,0)]
    - squash keys[(0,0),(0.3,0.25),(0.4,-0.2),(0.48,0.12),(0.6,0)]
    - pitch keys[(0,0),(0.3,-0.15),(0.42,0.3),(0.9,0)] + 0.15 hump(0.44,0.52)
    - lift 0.25 hump(0.3,0.46)
  - mand(keys[(0,0.08),(0.3,0.65),(0.4,0.65),(0.46,-0.12),(0.6,-0.1),(0.9,0.08)] + ring(0.46, 0.06, 6, 0.3))
  - Carapace.p = keys[(0,0),(0.3,-0.15),(0.45,0.15),(0.9,0)] + ring(0.45, 0.06, 7, 0.25); Carapace.z = 0.12 hump(0.3,0.5)
- Hit: mand(0.08 + 0.4 hump(0,0.3)); Carapace.r = ring(0, 0.08, 9, 0.2) e; Carapace.z = 0.08 hump(0,0.2).
- Die:
  - mand(keys[(0,0.08),(0.2,0.6),(1,0.45)], keys[(0,0),(1,0.35)])
  - Carapace.r = keys[(0,0),(1,0.22)]; Carapace.z = keys[(0,0),(0.15,0.1),(1.1,-0.2)]; Carapace.x = keys[(0,0),(1.1,0.2)]

## Glimlure (hunter) — peak 0.47 s

| Bone | Parent | What it holds |
|---|---|---|
| Lure1 / Lure2 | Top / Lure1 | the angler stalk (above 0.58 H, inferred) and its bulb; the stalk's foot fades along the stalk itself |
| Tail1-3 | chain on Body | the tail, along the body's horizontal long axis |

- The cage is measured on the head end only.
- `tail(A, f, lag, ph)`: Tail k.y = A (0.6 + 0.4k) sin(2pi f t - lag k + ph).
- std(hop 0.1).
- Idle:
  - tail(0.08, 0.5, 0.9)
  - Lure1.p = 0.06 sin(pi t - 0.5) - 0.5 (pitch 0.15 s late - 0.05)
  - Lure2.p = 0.1 sin(pi t - 1.3); Lure2.r = 0.05 sin(pi t + 0.4)
- Move (1 s slither, no hop):
  - Body: yaw 0.1 sin wt; side 0.03H sin(wt - 0.4); squash 0.04 sin 2wt; pitch 0.06; lift 0.02H (1 - cos 2wt)/2
  - tail(0.28, 1, 1.0, -1.2)
  - Lure1.p = -0.15 + 0.08 sin(2wt - 1); Lure2.p = -0.2 + 0.1 sin(2wt - 1.6); Lure1.y = -0.6 yaw 0.15 s late
- **Attack** (1.0 s):
  - Body:
    - fwd keys[(0,0),(0.3,0.5),(0.45,-1.8),(0.6,-1.7),(1,0)]
    - pitch keys[(0,0),(0.3,-0.25),(0.45,0.25),(1,0)] + 0.15 hump(0.47,0.55) + 0.12 hump(0.56,0.64)
    - squash keys[(0,0),(0.3,0.15),(0.42,-0.2),(0.5,0.1),(0.7,0)]
    - lift 0.2 hump(0.3,0.5)
  - Tail k.y = 0.25 (k+1)/3 hump(0.05,0.45) + ring(0.42 + 0.05k, -0.2 (k+1), 2.5, 0.3)
  - Lure1.p = keys[(0,0),(0.3,-0.4),(0.44,0.25),(0.55,0.2),(1,0)] + ring(0.55, -0.15, 3, 0.35)
  - Lure2.p = keys[(0,0),(0.33,-0.3),(0.46,0.3),(0.58,0.25),(1,0)] + ring(0.58, -0.2, 3.5, 0.3)
  - Forward is kept small: the stalk already arcs over the face.
- Hit: Tail k.y = ring(0.03k, 0.2, 4, 0.3) e; Lure1.p = ring(0.02, -0.3, 3.5, 0.3) e; Lure2.p = ring(0.06, -0.35, 3.5, 0.3) e.
- Die: Tail k.y = keys[(0,0),(0.15,-0.1),(1.1,0.3)]; Lure1.p = keys[(0,0),(0.15,-0.2),(1,0.25)]; Lure2.p = keys[(0,0),(0.2,-0.2),(1.1,0.35)].

## Bilebloat (spitter) — peak 0.58 s

- **Lips** (parent Front): found by protrusion from the front-most point.
- The body puffs with swell.
- std(hop 0.15, heavy 1.1, depth 0.05), plus swell:
  - idle swell 0.06 sin(pi t - 0.3)
  - hit swell ring(0.02, -0.15, 3.5, 0.3) e
  - die swell keys[(0,0),(0.15,0.15),(1,-0.25)]
- Idle: Lips.f = 0.04 sin 2pi t; Lips.p = 0.05 sin(pi t - 0.7).
- Move: Lips.f = 0.3 (lift 0.06 s late - lift); Lips.p = -0.5 squash 0.1 s late.
- **Attack** (1.1 s, inflate and spit):
  - Body:
    - swell keys[(0,0),(0.45,0.38),(0.52,0.4),(0.6,-0.12),(0.75,0)] + ring(0.75, 0.06, 3, 0.4)
    - pitch keys[(0,0),(0.45,-0.18),(0.58,0.22),(1.1,0)]
    - squash keys[(0,0),(0.45,-0.05),(0.58,0.08),(0.8,0)]
    - fwd keys[(0,0),(0.45,0.2),(0.6,-0.3),(1.1,0)]
  - Lips.f = keys[(0,0),(0.45,0.12),(0.58,-0.45),(0.7,-0.4),(1.1,0)]
  - Lips.p = keys[(0,0),(0.45,-0.15),(0.58,0.25),(1.1,0)] + ring(0.7, 0.08, 5, 0.3)
- Hit: Lips.f = ring(0, 0.12, 6, 0.3) e; Lips.p = ring(0.03, -0.15, 5, 0.3) e.
- Die: Lips.p = keys[(0,0),(0.2,-0.15),(1.1,0.5)]; Lips.z = keys[(0,0),(1.1,-0.1)].

## Hexcap (healer) — peak 0.42 s

- **Cap** (parent Top): above the stem top (the 97th-percentile height of stem colour near the axis).
- **CapTip1-2** (chain on Cap): the curled tip, grown along the surface.
- pulses = hump(0.35,0.5) + hump(0.55,0.7) + hump(0.75,0.9).
- std(hop 0.15, heavy 1.0, depth 0.04).
- Idle:
  - Cap.p = -0.5 (pitch 0.2 s late - 0.05) + 0.02 sin(pi t - 1); Cap.r = -0.5 roll 0.2 s late
  - CapTip1 p/r = 0.06 sin(pi t - 1.2), 0.05 sin(pi t + 0.3)
  - CapTip2 p/r = 0.1 sin(pi t - 1.9), 0.08 sin(pi t - 0.4)
- Move:
  - Cap.p = -0.7 pitch 0.1 s late; Cap.z = 0.35 (lift 0.07 s late - lift)
  - CapTip1.p = -0.8 pitch 0.15 s late; CapTip2.p = -1.0 pitch 0.22 s late; CapTip2.r = 0.3 squash 0.2 s late
- **Attack** (1.2 s, heal):
  - Body:
    - lift keys[(0,0),(0.3,0.25),(0.95,0.25),(1.2,0)]
    - squash keys[(0,0),(0.3,-0.12),(0.95,-0.12),(1.2,0)]
    - swell 0.08 pulses
    - pitch keys[(0,0),(0.3,-0.1),(1.2,0)]
  - Cap.p = keys[(0,0),(0.3,-0.3),(0.95,-0.25),(1.2,0)]; Cap.z = keys[(0,0),(0.3,0.25),(0.95,0.2),(1.2,0)]
  - CapTip1.p = ring(0.25, 0.25, 2.5, 0.3) + 0.06 pulses; CapTip2.p = ring(0.32, 0.35, 2.5, 0.3); CapTip1.r = ring(0.4, 0.15, 3, 0.3)
- Hit:
  - Cap.r = ring(0, 0.08, 7, 0.25) e; Cap.p = ring(0.02, 0.06, 6, 0.25) e
  - CapTip1.p = ring(0.05, 0.3, 4, 0.3) e; CapTip2.p = ring(0.08, 0.4, 4, 0.3) e
- Die:
  - Cap.r = keys[(0,0),(1,0.35)]; Cap.z = keys[(0,0),(0.2,0.1),(1.1,-0.35)]; Cap.x = keys[(0,0),(1.1,0.2)]
  - CapTip1.r = keys[(0,0),(1.1,0.4)]; CapTip2.r = keys[(0,0),(1.1,0.5)]

## Ruingut (armoured) — peak 0.62 s

- **Pillar** (parent Top): the highest grey piece within 1.25x the column's radius.
- The brow and the other slabs ride Front and Right.
- std(hop 0.07, heavy 1.3, depth 0.035).
- Idle:
  - Pillar.p = 0.025 sin(pi t - 1.2) - 0.5 (pitch 0.25 s late - 0.05)
  - Pillar.r = 0.02 sin(pi t + 0.6) - 0.5 roll 0.25 s late
- Move (rings periodic): Pillar.p = -0.8 pitch 0.12 s late + ring(0.7, 0.06, 4, 0.3); Pillar.r = ring(0.72, 0.04, 5, 0.3).
- **Attack** (1.2 s, shove; the pillar topples forward and springs back):
  - Body:
    - fwd keys[(0,0),(0.35,0.35),(0.45,0.35),(0.62,-1.2),(0.75,-1.1),(1.2,0)]
    - squash keys[(0,0),(0.35,0.18),(0.5,-0.12),(0.62,0.12),(0.8,0)] + ring(0.62, 0.06, 3, 0.4)
    - pitch keys[(0,0),(0.35,-0.1),(0.62,0.25),(1.2,0)]
  - Pillar.p = keys[(0,0),(0.4,-0.12),(0.6,0),(0.72,0.32)] before 0.72, then settle(0.72, 0.32, 1.3, 0.3)
  - Pillar.r = ring(0.72, 0.06, 2, 0.3)
- Hit: Pillar.p = ring(0.03, -0.1, 4, 0.3) e; Pillar.r = ring(0.05, 0.06, 5, 0.3) e.
- Die: Pillar.p = keys[(0,0),(0.2,-0.1),(1.1,0.45)]; Pillar.z = keys[(0,0),(1.1,-0.3)]; Pillar.r = keys[(0,0),(1.1,0.12)].

## Sporegorge (mini-boss) — peak 0.6 s

- **Sac1-7** (parent Top): the loose pink islands over 0.65 across, each with an `out` vector.
- std(hop 0.08, heavy 1.3, depth 0.04).
- Idle: Sac k.o = 0.12 sin(pi t - 1.3k).
- Move: Sac k.o = 0.5 (lift (0.05 + 0.02k) s late - lift) + 0.6 squash (0.08 + 0.015k) s late.
- **Attack** (1.4 s, spore burst):
  - Body:
    - squash keys[(0,0),(0.45,0.3),(0.6,-0.35),(0.75,-0.25),(1,0)] + ring(1, 0.1, 2, 0.4)
    - lift 0.1H hump(0.55,0.95)
    - swell keys[(0,0),(0.45,0.12),(0.6,0.2),(1,0)]
    - pitch keys[(0,0),(0.45,0.1),(0.6,-0.15),(1.4,0)]
  - Sac k.o = keys at t - 0.015k [(0,0),(0.45,0.2 + 0.05 sin k),(0.6,0.5),(0.72,0.45),(1.1,0)] + ring(1.1 + 0.02k, 0.12, 2.5, 0.35)
- Hit: Sac k.o = ring(0.02k, 0.15, 5, 0.3) e.
- Die: Sac k.o = keys[(0,0),(0.2,0.1),(1.1,-0.2)].

## Hollowheart (boss) — peak 0.82 s

- **Crown** (parent Top): the crown, one piece (its islands are not two halves, so there is no CrownL/R).
- `cr(p, r, z)` sets Crown.p = p, Crown.r = r, Crown.z = z.
- std(hop 0.07, heavy 1.5, depth 0.03).
- Idle: cr(-0.6 (pitch 0.35 s late - 0.05) + 0.02 sin(pi t - 2), -0.6 roll 0.35 s late + 0.015 sin(pi t + 0.5)).
- Move: cr(-0.9 pitch 0.18 s late + 0.08 squash 0.22 s late).
- **Attack** (1.6 s, leap and slam):
  - Body:
    - lift keys[(0,0),(0.3,0),(0.62,1.6),(0.72,1.6),(0.82,0)]
    - squash keys[(0,0),(0.3,0.25),(0.5,-0.3),(0.72,-0.25),(0.82,0)] + ring(0.82, 0.7, 1.6, 0.35)
    - pitch keys[(0,0),(0.3,0.05),(0.62,-0.18),(0.8,0.12),(1.6,0)]
  - cr(keys[(0,0),(0.3,0.08),(0.62,-0.4),(0.8,-0.3),(1,0)] + ring(0.82, 0.45, 1.2, 0.3))
- Hit: cr(-0.8 pitch 0.1 s late, -0.8 roll 0.1 s late).
- Die: cr(keys[(0,0),(0.2,-0.1),(1.1,0.35)], 0, keys[(0,0),(1.1,-0.3)]).

## Known limits

- Glimlure's lure base height (0.58 H) is inferred from the side view. Its forward swing is kept small so the bulb never
  folds into the face.
- Hollowheart's crown is one rigid piece.
- Ruingut's brow slab rides the cage, not the Pillar.
