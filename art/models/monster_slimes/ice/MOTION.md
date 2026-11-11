# Frozen Ice monster slimes: bones, weights and motion

Built by `tools/blender/monster_rig.py` with this region's rigs and motions in `tools/blender/monster_rig_ice.py` (run
`tools/blender/monster_rig.ps1 ice all full`; sheets by `monster_rig_sheets.py`). Source: `ice.blend` (never edited).
Output: `<Name>/<Name>.fbx` (mesh, armature, five takes Idle, Move, Attack, Hit, Die at 30 fps, own UVs), `<Name>/<Name>.png`
(its own 1024 texture, baked from the shared 4096), `ice_rigged.blend` (actions `<Name>_<Action>`), `rig_ice.json`, proof in
`review/<Name>_weights.png`, `_poses.png`, `_texture.png`. The Python functions are the reference; this file says the
same in words and numbers.

## Conventions

Exactly as `../meadow/MOTION.md` "Conventions" (1 metre = 1 stud, faces Blender -Y = Roblox -Z, axes (x, y, z) ->
(-x, z, y), L = own left = Blender +X, every move relative to the parent about the bone's own joint, `bone.Transform =
R0:Inverse() * (CFrame.new(offset) * turn) * R0`, the helpers `keys`, `ring`, `settle`, `hump`, `smoothstep`, lag `ch`).
Also:

- `_end(t)` = 1 - smoothstep(0.28, 0.4, t) (Hit ends at rest).
- A quaternion (w, x, y, z) in Blender is (w, -x, z, y) in Roblox (the axis map has determinant +1, so no sign flip of w).
- `rig_ice.json`, per monster:
  - height, hover, peak (attack contact time, s), texture
  - every bone's joint, parent and rest rotation (identity in model axes: all bones point up, no roll)
  - cage: Ht, Hb, reaches, equator directions, also in Roblox axes
  - every part vector (out, spin_axis, ...), Blender and Roblox axes
  - each action's length and loop flag
- `golden` in the JSON samples every bone's move (loc and rot, Blender and Roblox) at 8 times per action:
  - loops at k T/8, one-shots at k T/7, k = 0..7, so the last sample is the held end.
  - A port is right when it reproduces them.

## The cage

As the Meadow (`Body`, `Top`, `Front`, `Back`, `Left`, `Right`), plus two additions:

- **swell**, a body channel (0 in the Meadow, so the Meadow is unchanged). It puffs the body without lowering it:
  - Top offset z gains +0.5 swell Ht.
  - Each equator bone moves outward n * 0.45 (squash + swell) R.
- **Mid** (Shardspire only, a column), a child of Body between Body and Top:
  - offset (0.2 roll Ht, -0.2 pitch Ht, (-0.45 squash + 0.25 swell) Ht)
  - turn Y(0.3 roll) X(0.3 pitch)
  - so the column bends instead of hinging.

## Parts: one rule

Every part bone moves by drives named after it:

- turn = Z(n.y) * Y(n.r) * X(n.p) * (rotation by n.spin about the part's `spin_axis`)
- offset = (n.x, n.f, n.z) + out * n.o

A missing drive is 0. Hard parts are rigid 1.0 on their bone and fade over 2 edge rings into the jelly.

## Shared bodies

`std(r, hop, heavy, depth)` gives the Meadow's shared Idle (2 s), Move (1 s hop, height hop x H, heaviness `heavy`),
Hit (0.4 s) and Die (1.2 s). The numbers are in `../meadow/MOTION.md` "Shared bodies"; idle depth is `depth`.

## Frostnip (swarmer)

- Mesh: 2954 tris (from 5796), 8 bones, 4.4 studs.
- **Cap** (parent Top, joint (-0.45, 0.04, 2.60)): the white snow cap, every low-saturation vertex above 0.35 H, soft edge.
- std(hop 0.2).
- Idle: Cap.z = 0.2H (squash - squash 0.15 s late); Cap.p = -0.5 (pitch 0.2 s late - 0.05).
- Move: Cap.z = 0.35 (lift 0.07 s late - lift); Cap.p = -0.7 pitch 0.1 s late.
- **Attack** (0.9 s, a twisting nip; peak 0.4 s):
  - Body:
    - fwd keys[(0,0),(0.25,0.25),(0.38,-1.1),(0.55,-1.0),(0.9,0)]
    - yaw keys[(0,0),(0.25,-0.25),(0.4,0.2),(0.6,0),(0.9,0)]
    - squash keys[(0,0),(0.25,0.2),(0.36,-0.2),(0.44,0.12),(0.55,0)]
    - pitch keys[(0,0),(0.25,-0.15),(0.4,0.3),(0.9,0)]
    - lift 0.25 hump(0.26,0.42)
  - Cap.p = -0.6 pitch 0.1 s late; Cap.r = 0.5 yaw 0.08 s late; Cap.z = 0.1 hump(0.38,0.5).
- Hit: Cap.r = ring(0, 0.08, 7, 0.25) e; Cap.z = 0.06 hump(0,0.2).
- Die: Cap.r keys[(0,0),(1,0.3)]; Cap.x keys[(0,0),(1.1,0.3)]; Cap.z keys[(0,0),(0.15,0.08),(1.1,-0.05)].

## Rimesaw (hunter)

2810 tris, 8 bones, 3.6 studs.

How the blade ring was freed:

- The blade ring was **cut** free of the disc: an edge split along the circle r = 2.22 about the disc's middle, 0.9 of
  the notch radius 2.47. No vertex moved; 128 edges were split.
- **Blades** is a child of Body, joint at the disc middle (-0.02, -0.10, 2.00).
  - `spin_axis` is the disc normal (0.15, -0.60, 0.79) in Blender, (-0.15, 0.79, -0.60) in Roblox.
  - It spins without dragging the disc.
- The cage is measured on the disc only.

Motion (std(hop 0.06); peak 0.55 s):

- **Idle** (2 s): squash 0.03 sin(pi t), roll 0.03 sin(pi t + 0.6), pitch 0.04; Blades.spin = 2pi t / 2 (one turn a loop).
- **Move** (1 s): pitch 0.12 + 0.03 sin(2pi t), lift 0.03H (1 - cos 4pi t)/2, roll 0.04 sin(2pi t); Blades.spin = 2 x 2pi t (two turns).
- **Attack** (1.0 s):
  - Body:
    - fwd keys[(0,0),(0.35,0.3),(0.55,-1.8),(0.65,-1.7),(1,0)]
    - pitch keys[(0,0),(0.35,-0.15),(0.55,0.25),(1,0)]
    - squash keys[(0,0),(0.35,0.1),(0.5,-0.12),(0.6,0.1),(0.8,0)]
    - roll 0.05 sin(16pi t) hump(0.1,0.55)
  - Blades.spin = 4 x 2pi smoothstep(0,1,t); Blades.p = ring(0.55, 0.06, 6, 0.3).
- Hit: Blades.spin 0.4 hump(0,0.4); Blades.r ring(0, 0.06, 7, 0.25) e.
- Die: Blades.spin 1.2 smoothstep(0,1,t); Blades.p keys[(0,0),(1.1,0.25)]; Blades.z keys[(0,0),(1.1,-0.4)].

The loops hold whole turns, so they join. A port may instead spin Blades on its own clock (any speed) and play the rest.

## Shardspire (spitter, a column)

2742 tris, 9 bones (with Mid), 4.2 studs.

- **Crown** (parent Top, joint (-0.07, 0.00, 2.58)): the loose crystals plus the column above their foot (z 2.58), soft edge.
- std(hop 0.12, heavy 1.1, depth 0.04).
- Idle: Crown.p = -0.5 (pitch 0.2 s late - 0.05) + 0.02 sin(pi t - 1); Crown.r = -0.5 roll 0.2 s late.
- Move: Crown.p = -0.8 pitch 0.1 s late; Crown.z = 0.3 (lift 0.07 s late - lift).
- **Attack** (1.1 s, lean back, whip the shard; peak 0.55 s):
  - Body:
    - pitch keys[(0,0),(0.4,-0.3),(0.55,0.35),(0.62,0.3)], then from 0.62-0.66 blending into settle(0.64, 0.3, 1.6, 0.3)
    - squash keys[(0,0),(0.4,-0.12),(0.55,0.1),(0.8,0)]
  - Crown.p = -0.6 (pitch 0.08 s late - pitch) + ring(0.55, 0.12, 4, 0.3).
- Hit: Crown.p ring(0.03, -0.1, 5, 0.3) e; Crown.r ring(0.04, 0.06, 6, 0.3) e.
- Die: Crown.p keys[(0,0),(1.1,0.35)]; Crown.z keys[(0,0),(1.1,-0.3)].

## Snowshroud (healer)

2954 tris (from 8928), 10 bones, 3.8 studs.

| Bone | Parent | Joint | What it holds |
|---|---|---|---|
| Hood | Top | (0.00, 0.29, 2.09) | the hood, a soft ramp from 0.55 H |
| HoodTip1 | Hood | (-0.14, 0.80, 3.04) | the hood's curled tip, grown along the surface from 0.8 H |
| HoodTip2 | HoodTip1 | (0.24, 1.12, 3.35) | the second half of the tip |

Motion (std(hop 0.12, heavy 1.1, depth 0.04); peak 0.47 s):

- Idle: HoodTip1 p/r = 0.05 sin(pi t - 1), 0.03 sin(pi t + 0.2); HoodTip2 p/r = 0.08 sin(pi t - 1.7), 0.05 sin(pi t - 0.5); Hood.p = -0.4 (pitch 0.2 s late - 0.05).
- Move: HoodTip1.p = -0.6 pitch 0.14 s late; HoodTip2.p = -0.8 pitch 0.22 s late; Hood.z = 0.3 (lift 0.07 s late - lift); Hood.p = -0.5 pitch 0.1 s late.
- **Attack** (1.2 s, heal: rises, three pulses):
  - Body:
    - lift keys[(0,0),(0.35,0.3),(1,0.3),(1.2,0)]
    - squash keys[(0,0),(0.35,-0.12),(1,-0.12),(1.2,0)]
    - swell 0.08 (hump(0.4,0.55) + hump(0.6,0.75) + hump(0.8,0.95))
    - pitch keys[(0,0),(0.35,-0.1),(1.2,0)]
  - HoodTip1.p ring(0.3, 0.15, 2.5, 0.3); HoodTip2.p ring(0.36, 0.2, 2.5, 0.3)
  - Hood.z keys[(0,0),(0.35,0.25),(1,0.2),(1.2,0)]; Hood.p keys[(0,0),(0.35,-0.15),(1,-0.12),(1.2,0)]
  - The heal fires on the pulses.
- Hit: tips ring(0.04, 0.1, 4, 0.3) e and ring(0.08, 0.13, 4, 0.3) e; Hood.r ring(0, 0.06, 7, 0.25) e.
- Die: tips p keys[(0,0),(1.1,0.15)] and keys[(0,0),(1.1,0.2)]; Hood.p keys[(0,0),(1.1,0.25)]; Hood.z keys[(0,0),(1.1,-0.3)].

## Icebound (armoured)

2955 tris (from 6194), 8 bones, 4.6 studs.

- **Block** (parent Body, joint at the block's base middle (-0.04, 0.48, 0.48)):
  - Holds the ice block (everything above the puddle, z 0.35, and the high loose spikes and eyes), rigid, with a 2-ring fade.
- **The cage is the puddle** under it, measured thin (Hj 0.54), so squash spreads and splashes the puddle while the block
  stays hard.
- The block rocks on its edges:
  - block(p, r, z) sets Block.p = p, Block.r = r, Block.z = z + 1.43 |sin p| + 1.96 |sin r|.
  - The two constants are the block's half depth and half width in the JSON, so the rocking edge stays on the ground.

Motion (peak 0.7 s):

- Idle (2 s): squash 0.05 sin(pi t); block(0.008 sin(pi t - 0.5), 0.01 sin(pi t + 1)).
- Move (1.2 s, it rocks from corner to corner; each thump splashes the puddle): squash 0.15 |cos(2pi t/1.2)| - 0.05; block(0.02, 0.07 sin(2pi t/1.2)).
- **Attack** (1.2 s, it tips and slams its face down):
  - squash keys[(0,0),(0.6,-0.05),(0.7,0.3),(0.85,0)] + ring(0.7, 0.2, 3, 0.35); fwd keys[(0,0),(0.35,0.1),(0.7,-0.4),(1.2,0)]
  - block(keys[(0,0),(0.35,-0.08),(0.6,0.2),(0.7,0)] + ring(0.7, -0.04, 6, 0.3), 0, 0.08 hump(0.3,0.6))
- Hit (0.4 s): squash ring(0, 0.2, 4, 0.3) e; fwd 0.05H keys[(0,0),(0.08,1),(0.4,0)]; block(ring(0, -0.05, 6, 0.3) e, ring(0.02, 0.04, 7, 0.3) e).
- Die (1.2 s): squash keys[(0,0),(0.15,0.2),(1,0.85),(1.2,0.85)] (the puddle spreads); block(keys[(0,0),(1,0.06)], keys[(0,0),(0.2,-0.05),(1,0.15)], keys[(0,0),(1.1,-0.25)]).

## Rimetusk (mini-boss)

5909 tris (from 12321), 10 bones, 8 studs.

| Bone | Parent | Joint | What it holds |
|---|---|---|---|
| Mane | Top | (0.04, 0.00, 4.40) | the shaggy back and crown: soft ramp from 0.55 H, behind y -1.5, plus the high crystal islands |
| TuskL | Front | (1.72, -5.13, 3.86) | the left tusk: what stands out past the face front, low, on its side (largest connected piece) |
| TuskR | Front | (-2.23, -4.14, 2.89) | the right tusk, same rule |

Motion (std(hop 0.07, heavy 1.4, depth 0.035); peak 0.45 s, the first ram):

- Idle: TuskL.p = TuskR.p = 0.015 sin(pi t - 0.3); Mane.p = -0.5 (pitch 0.25 s late - 0.05); Mane.z = 0.15H (squash - squash 0.2 s late).
- Move: Mane.p = -0.7 pitch 0.12 s late; Mane.z = 0.4 (lift 0.08 s late - lift).
- **Attack** (1.6 s, head down, two rams):
  - Body:
    - fwd keys[(0,0),(0.3,0.4),(0.45,-1.5),(0.6,-1.3),(0.72,-0.6),(0.95,-2.2),(1.1,-2.0),(1.6,0)]
    - pitch keys[(0,0),(0.3,0.2),(1.1,0.2),(1.6,0)] + 0.1 hump(0.42,0.52) + 0.12 hump(0.92,1.02)
    - squash keys[(0,0),(0.3,0.15),(0.42,-0.1),(0.48,0.15),(0.6,0),(0.92,-0.12),(0.98,0.2),(1.15,0)]
  - Tusks p = keys[(0,0),(0.3,0.15),(1.1,0.15),(1.6,0)] + ring(0.45, -0.05, 5, 0.3) + ring(0.95, -0.06, 5, 0.3)
  - Mane.p = -0.6 (pitch 0.12 s late - pitch) + ring(0.47, 0.06, 3, 0.3) + ring(0.97, 0.08, 3, 0.3)
- Hit: Mane.p = -0.8 pitch 0.08 s late; Mane.r = ring(0.03, 0.04, 5, 0.3) e.
- Die: tusks p keys[(0,0),(1.1,0.12)]; Mane.p keys[(0,0),(1.1,0.15)]; Mane.z keys[(0,0),(1.1,-0.3)].

## Frostmaw (boss)

6816 tris, 9 bones, 10 studs.

| Bone | Parent | Joint | What it holds |
|---|---|---|---|
| HornL | Top | (3.04, 0.18, 9.01) | everything above 0.58 H beyond x 2.8 on its side (largest connected piece) |
| HornR | Top | (-3.04, 0.11, 7.16) | the same on the right |

- The two horn joints differ in height: the mesh's horns are not mirror twins.
- **No jaw bone**: the lower jaw is the body's own front, one surface with the gaping mouth, with no clean cut. The roar
  opens through the cage (Front forward, Top up and back with swell).

Motion (std(hop 0.06, heavy 1.5, depth 0.03); peak 0.6 s):

- horns(p, out) sets HornL.p = HornR.p = p, HornL.r = out, HornR.r = -out.
- Idle: horns(0.015 sin(pi t - 0.6) - 0.3 (pitch 0.2 s late - 0.05)).
- Move: horns(-0.4 pitch 0.1 s late).
- **Attack** (1.8 s, rears up, roars with a tremble, settles):
  - trem = 0.02 sin(18pi t) hump(0.55,1.3)
  - Body:
    - squash keys[(0,0),(0.25,0.15),(0.55,-0.3),(1.25,-0.25),(1.5,0)] + ring(1.5, 0.15, 2, 0.4)
    - lift keys[(0,0),(0.55,0.08H),(1.25,0.06H),(1.5,0)]
    - pitch keys[(0,0),(0.25,0.1),(0.55,-0.25),(1.25,-0.2),(1.6,0)] + trem
    - swell keys[(0,0),(0.55,0.12),(1.25,0.1),(1.5,0)]
    - roll trem
  - horns(keys[(0,0),(0.25,0.05),(0.55,-0.15),(1.25,-0.12),(1.6,0)], keys[(0,0),(0.55,0.06),(1.3,0)])
- Hit: horns(-0.5 pitch 0.06 s late).
- Die: horns(keys[(0,0),(0.2,-0.05),(1.1,0.12)], keys[(0,0),(1.1,-0.05)]).

## Known limits

Mesh and cuts:

- The meshes are image-to-3D:
  - Rimetusk's tusks and Frostmaw's horns are not mirror images, so the two sides' joints differ and they move a little differently.
  - The first attempt to mirror one side onto the other matched only 2-12% of vertices, so each side is found on its own.
- Frostmaw has no jaw bone (see above).
- Icebound's Left cage bone holds almost nothing (the puddle is thin there); the puddle is driven mostly by Front and Right.

Motion and texture:

- Rimesaw's blade ring and disc are now two touching rims (an edge split, no vertex moved). The turn slides one past the
  other: clean at 1/8 and 1/4 turn on the pose sheet. The ring is not a perfect circle, so a sliver may show at some angles.
- Past squash 0.85 (Die) the bodies melt rather than form a clean puddle, as in the Meadow.
- The texture is 1024 per monster (`<Name>.png`, its own UV map "Own"). The bake is an emission bake of the shared 4096,
  so fine detail softens a little; checked side by side in `review/<Name>_texture.png`.
