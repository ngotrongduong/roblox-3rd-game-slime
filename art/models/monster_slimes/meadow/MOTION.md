# Sunny Meadow monster slimes: bones, weights and motion

Built by `tools/blender/monster_rig.py` (run `tools/blender/monster_rig.ps1 meadow all full`; sheets by
`monster_rig_sheets.py`). Source: `meadow.blend` (never edited). Output: `<Name>/<Name>.fbx` (mesh, armature, five takes
Idle, Move, Attack, Hit, Die at 30 fps), `meadow_rigged.blend`, `rig_meadow.json` (every bone's joint in Blender and
Roblox axes, cage sizes, action lengths), proof in `review/<Name>_weights.png` (each bone a colour) and
`review/<Name>_poses.png` (rest, squash, stretch, attack peak, each part at its extremes; front row, side row).
The Python functions in `monster_rig.py` (`cage_pose`, `apply_pose`, `motions`) are the reference: this file says the
same in words and numbers.

## Conventions (read first)

- 1 Blender metre = 1 stud. The monster faces Blender -Y = Roblox -Z. Root at the origin on the ground, no skin.
- Names ending L are the monster's own left: Blender +X, Roblox -X.
- Axes: Blender (x, y, z) -> Roblox (-x, z, y). A rotation by angle a about Blender X is a rotation by **-a** about
  Roblox X; about Blender Y is **+a** about Roblox Z; about Blender Z is **+a** about Roblox Y. So in Roblox:
  `pitch` = `CFrame.Angles(-pitch, 0, 0)` (positive pitch leans the top forward, toward -Z), `roll` (top toward the
  monster's left) = rotation +roll about Z, `yaw` = rotation about Y.
- Every move below is a bone's offset and turn **relative to its parent, in model axes, about the bone's own joint**. All
  bones were made pointing up with no roll, so in Blender a bone's axes are the model's. In Roblox the imported Bone has
  its own rest orientation R0 (its CFrame's rotation): set `bone.Transform = R0:Inverse() * (CFrame.new(offset) * turn) * R0`.
- Roblox bones cannot scale: squash and stretch are made by **moving** the cage bones. The jelly body is a cage:
  `Body` (low centre, child of Root), and its children `Top` (upper body) and `Front`, `Back`, `Left`, `Right` (on the
  equator at 0.75 of its reach). Hard parts are children of Top (or of their own chain).
- Weights: jelly vertices blend over the six cage bones (a gaussian of the distance to each cage joint measured in the
  body's own proportions, sigma 0.6), at most 4 influences, normalised; hard parts are rigid 1.0 on their bone and fade
  over 2 edge rings into the jelly next to them (no tearing at the seam); nothing on Root.
- Helpers (t in seconds, all smooth):
  - `keys(t, [(t0,v0), (t1,v1), ...])`: value through the keys, smoothstep between each pair (zero slope at every key),
    held before the first and after the last.
  - `ring(t, t0, A, f, z)`: a spring struck at t0: `A * exp(-z*2*pi*f*u) * sin(2*pi*f*sqrt(1-z^2)*u)`, u = t - t0, 0 before.
    Its half-life is `ln2 / (z*2*pi*f)`.
  - `settle(t, t0, A, f, z)`: a spring let go from A at t0 (A before t0, then
    `A*exp(-z*w*u)*(cos(wd*u) + z/sqrt(1-z^2)*sin(wd*u))`).
  - `hump(t, a, b)`: `sin^2(pi*(t-a)/(b-a))` between a and b, else 0.
  - `smoothstep(a, b, t)`.
  - Follow-through `lag(ch, d)`: the body channel ch read d seconds late (in loops, wrapped modulo the loop length; in
    one-shot actions, held at its t=0 value before 0).
  - Loops join with no jump: a one-shot hop or dart `f` is made periodic as `g(t) = f(t mod T) + f(t mod T + T) + f(t mod T + 2T) + f(t mod T + 3T)`
    (the tails of the previous cycles), everything else in a loop is sines of whole cycles.

## The cage (all seven)

Each action gives seven body channels: `lift` (studs up, added to the hover height), `fwd` (studs along Blender y,
negative = forward), `side` (studs along x), `squash` (1 = top down by 0.9 of the cage height, negative = stretch),
`pitch`, `roll`, `yaw` (radians). With `Ht = Top.z - Body.z`, `Hb = equator z - Body.z` and each equator bone's reach R
and outward direction n (Front -y, Back +y, Left +x, Right -x):

| Bone | Offset (Blender) | Turn |
|---|---|---|
| Body | (side, fwd, lift + hover) | Z(yaw) * Y(0.35 roll) * X(0.35 pitch) |
| Top | (0.4 roll Ht, -0.4 pitch Ht, -0.9 squash Ht) | Y(0.65 roll) * X(0.65 pitch) |
| Front/Back/Left/Right | n * 0.45 squash R + (0, 0, -0.4 squash Hb) | none |

| Monster | Ht | Hb | Reach Front / Back / Left / Right | Hover |
|---|---|---|---|---|
| Burrling | 1.81 | 0.54 | 1.56 / 1.57 / 1.95 / 2.02 | 0 |
| Stinglob | 1.44 | 0.57 | 1.60 / 1.59 / 1.38 / 1.42 | 0.9 |
| Gapebloom | 1.19 | 0.48 | 1.67 / 1.66 / 1.69 / 1.69 | 0 |
| Sapcaller | 0.99 | 0.10 | 1.09 / 1.09 / 1.08 / 1.09 | 0.5 |
| Barkhide | 1.16 | 0.40 | 2.10 / 2.05 / 2.13 / 2.08 | 0 |
| Rotbloom | 2.75 | 0.27 | 3.82 / 3.84 / 4.34 / 4.35 | 0 |
| Bramblehorn | 3.72 | 1.49 | 3.30 / 4.02 / 4.45 / 4.39 | 0 |

Hover: the flyers float in every action (Body z + hover) and fall to the ground in Die.

## Shared bodies (H = the monster's height)

- **Idle, ground** (2 s loop, w = pi): squash = d sin(wt) + 0.3d sin(2wt + 0.7) with d = 0.05 (Rotbloom, Bramblehorn
  0.035: heavier, slower-looking); pitch = 0.05 + 0.025 sin(wt - 0.5) (always leaning in, menacing); roll = 0.02 sin(wt + 1.3);
  yaw = 0.03 sin(wt + 2.0).
- **Idle, flyer** (2 s loop): lift = 0.035H sin(2 pi t) (a 1 Hz bob); squash = -0.04 sin(2 pi t - 0.9) (stretches as it
  rises); pitch = 0.08 + 0.04 sin(2 pi t - 0.4); roll = 0.03 sin(pi t).
- **Move, ground** (1 s loop, one hop, made periodic): squash = keys[(0,0),(0.2,0.22k),(0.3,-0.2),(0.62,-0.06),(0.68,0)]
  (anticipation, launch stretch, air) then + ring(0.68, 0.55k, 2.2/sqrt(k) Hz, 0.35) (land squash, overshoot, settle);
  lift = h * 4u(1-u), u = (t-0.3)/0.38 in the air (0.3..0.68 s); pitch = keys[(0,0),(0.2,0.12),(0.3,-0.05),(0.6,-0.08),(0.68,0)]
  + ring(0.68, 0.35, 1.8, 0.4). Hop height h = 0.2H (Burrling, Gapebloom), 0.07H Barkhide, 0.1H Rotbloom, 0.07H Bramblehorn;
  heaviness k = 1, Barkhide 1.2, Rotbloom 1.3, Bramblehorn 1.4. In place: the game moves the root forward (-Z).
- **Move, flyer** (1 s loop, a dart, periodic): fwd = -0.6 (smoothstep(0.05,0.3,t) - smoothstep(0.35,0.95,t));
  pitch = 0.3 hump(0.02,0.45) + ring(0.3, -0.12, 2, 0.4); squash = -0.08 hump(0.05,0.3) + ring(0.3, 0.08, 3, 0.4);
  lift = 0.04H sin(4 pi t) (two bobs a second).
- **Hit** (0.4 s; e = 1 - smoothstep(0.28, 0.4, t) so it ends at rest): fwd = 0.08H keys[(0,0),(0.08,1),(0.4,0)] (knocked
  back); squash = ring(0, 0.25, 4, 0.3) e; pitch = -0.2 keys[(0,0),(0.07,1),(0.4,0)] + ring(0.07, 0.1, 3.5, 0.4) e;
  roll = ring(0, 0.08, 5, 0.3) e.
- **Die** (1.2 s, holds the last pose): squash = keys[(0,0),(0.12,0.2),(0.25,-0.1),(1.0,0.85),(1.2,0.85)] + ring(0.95, 0.05, 3, 0.4)
  (a flinch, then it melts flat: top down 77% of Ht, equator out 38% of its reach); pitch = keys[(0,0),(0.12,-0.2),(0.5,0.1),(1.2,0.05)];
  fwd = 0.05H keys[(0,0),(0.12,1),(0.6,0.6)]; flyers: lift = hover keys[(0,0),(0.2,0.15),(0.6,-1),(1.2,-1)] (falls to the ground).

## Burrling (swarmer)

2955 tris (from 4003), 7 bones, 4.4 studs. Cage only: its hooked thorns ride the jelly (they follow the cage weights, so
they bob and spread with the squash). Joints (Blender | Roblox): Body (0.05, -0.02, 0.91) | (-0.05, 0.91, -0.02);
Top (0.05, -0.02, 2.72) | (-0.05, 2.72, -0.02); Front (0.05, -1.19, 1.45); Back (0.05, 1.16, 1.45); Left (1.51, -0.02, 1.45);
Right (-1.46, -0.02, 1.45) (Roblox = (-x, z, y)).

Idle, Move, Hit, Die: the shared ground bodies. **Attack** (1.0 s, lunge and nip): fwd = keys[(0,0),(0.25,0.35),(0.4,-1.3),(0.62,-1.2),(1,0)];
squash = keys[(0,0),(0.25,0.22),(0.38,-0.25),(0.45,0.1),(0.55,0),(1,0)] + ring(0.6, 0.15, 3, 0.35); pitch = keys[(0,0),(0.25,-0.18),(0.4,0.3),(1,0)]
+ 0.18 hump(0.42,0.5) + 0.18 hump(0.52,0.6) (two snaps of the jaw); lift = 0.35 hump(0.28,0.44). Peak at 0.45 s.

## Stinglob (hunter, flyer)

842 tris, 11 bones, 3.6 studs, hovers 0.9. Wings are the two loose wing sheets; the stinger was grown along the surface from
its tip until the rings widen into the body (2.16 studs long).

| Bone | Parent | Joint Blender | Joint Roblox | Moves |
|---|---|---|---|---|
| WingL | Top | (0.29, -1.69, 1.70) | (-0.29, 1.70, -1.69) | turn `flap` about its hinge (-0.65, 0.50, 0.58) Blender (in the wing's plane, across its span; + takes the tip down) |
| WingR | Top | (-1.05, -0.55, 2.06) | (1.05, 2.06, -0.55) | `flap` about (-0.83, 0.40, -0.38) Blender |
| Stinger1 | Top | (0.52, 0.63, 2.90) | (-0.52, 2.90, 0.63) | X(sting1) (+ swings it forward over the back) |
| Stinger2 | Stinger1 | (0.82, 1.36, 3.23) | (-0.82, 3.23, 1.36) | X(sting2) |

(Hinge axes in Roblox: WingL (0.65, 0.58, 0.50), WingR (0.83, -0.38, 0.40).) flap(t, A) = -0.3 + A cos(p + 0.35 sin p),
p = 2 pi 6 t (6 Hz; the down stroke slower and stronger; keep the down stroke at or under +0.3 rad or the wing meets the
flank). The game may beat it faster (12-18 Hz); 6 Hz is what 30 fps keys can hold.

- **Idle**: flyer idle; flap A 0.55; sting1 = 0.08 sin(pi t - 1.0) - 0.5 (lag(pitch, 0.1) - 0.08); sting2 = 0.12 sin(pi t - 1.7).
- **Move**: flyer dart; flap A 0.65; sting1 = -0.7 lag(pitch, 0.08); sting2 = -0.5 lag(pitch, 0.16) (the stinger trails the dive).
- **Attack** (1.0 s, dive and stab): lift = keys[(0,0),(0.35,0.6),(0.52,-0.7),(0.6,-0.7),(1,0)]; fwd = keys[(0,0),(0.35,0.5),(0.52,-1.6),(0.62,-1.6),(1,0)];
  pitch = keys[(0,0),(0.35,-0.35),(0.5,0.55),(0.62,0.5),(1,0)] + ring(0.62, 0.1, 2.5, 0.4); squash = keys[(0,0),(0.35,0.12),(0.48,-0.15),(0.55,0.18),(0.7,0)];
  flap A 0.7; sting1 = keys[(0,0),(0.35,-0.3),(0.5,1.0),(0.62,1.0),(1,0)] + ring(0.62, -0.15, 3, 0.4); sting2 = keys[(0,0),(0.38,-0.2),(0.53,0.5),(0.62,0.5),(1,0)]. Peak 0.55 s.
- **Hit**: shared; flap A 0.3 + ring(0, 0.4, 3, 0.3); sting1 = -1.0 lag(pitch, 0.05); sting2 = -0.8 lag(pitch, 0.1).
- **Die**: shared flyer fall; flap = keys[(0,0.1),(0.2,-0.4),(0.7,0.45),(1.2,0.5)] + 0.3 cos(12 pi t)(1 - smoothstep(0,0.6,t)) (a last buzz, then the wings droop);
  sting1 = keys[(0,0),(0.6,0.2),(1,0.9)]; sting2 = keys[(0,0),(0.7,0.3),(1.2,0.6)].

## Gapebloom (spitter)

2639 tris, 15 bones, 4.2 studs. The flower head (everything not green above its base, and the teeth and seeds inside) is
rigid on Stem; its axis is the normal of the petal disc, (0.19, -0.64, 0.75) Blender (it faces forward and up); 7 petals
found as the separate sheets beyond 0.70 of the head's radius; each petal's weight ramps from 0 at the hinge radius
(0.90) to 1 at 1.55, the rest of the head stays on Stem. The curled tendrils are part of the body mesh and ride Top.

| Bone | Parent | Joint Blender | Joint Roblox |
|---|---|---|---|
| Stem | Top | (0.19, -0.13, 2.72) | (-0.19, 2.72, -0.13) |
| Petal1..7 | Stem | (1.10,-0.11,2.69) (0.76,0.31,3.32) (0.08,0.26,3.62) (-0.45,-0.01,3.43) (-0.61,-0.60,3.05) (-0.15,-0.87,2.31) (0.69,-0.63,2.16) | (-x, z, y) of each |

Stem turns X(stem_p) Y(stem_r) and moves (0, 0, stem_z). Petal k turns `petal(k)` about its hinge (axis x outward
direction; + folds it back and open, - cups it shut); an opening (+) is scaled by clamp((dir.z + 0.45)/0.7, 0, 1) of the
petal's outward direction so the front petals, which already hang down, never fold into the body.
- **Idle**: ground idle; stem_p = -0.6 (lag(pitch, 0.15) - 0.05); stem_r = -0.6 lag(roll, 0.15); petal(k) = 0.06 sin(pi t - 1.2 - k 2pi/7) (a ripple round the mouth) + 1.2 lag(squash, 0.2) (it breathes through the mouth).
- **Move**: ground hop; stem_p = 0.6 lag(pitch, 0.08) + 0.5 lag(squash, 0.08); petal(k) = 0.9 lag(squash, 0.1 + 0.01k) (flare on landing, cup in the air).
- **Attack** (1.0 s, rear and spit): pitch = keys[(0,0),(0.35,-0.3),(0.45,0.12),(1,0)] + ring(0.45, 0.06, 2.5, 0.35); squash = keys[(0,0),(0.35,-0.15),(0.45,0.25),(0.6,0)] + ring(0.6, 0.06, 3, 0.4);
  stem_p = keys[(0,0),(0.35,-0.3),(0.45,0.2),(1,0)] + ring(0.45, 0.08, 3, 0.3); petal(k) = keys at t - 0.012k [(0,0),(0.35,-0.35),(0.47,0.65),(0.6,0.65)] x (1 - smoothstep(0.6,1,t)) + ring(0.6 + 0.012k, -0.15, 3, 0.35) (clamp, then flare round the mouth one after another). Spit (projectile) at 0.47 s.
- **Hit**: shared; stem_p = -1.2 lag(pitch, 0.05); petal = -0.3 hump(0,0.3) + ring(0.05, 0.12, 5, 0.3)(1 - smoothstep(0.3,0.4,t)).
- **Die**: shared; stem_p = keys[(0,0),(0.15,-0.3),(1,0.6),(1.2,0.6)]; stem_z = -0.4 smoothstep(0.3,1,t); petal = keys[(0,0),(0.15,-0.3),(1,0.75)].

## Sapcaller (healer, floats)

2747 tris, 21 bones, 3.8 studs, hovers 0.5. Neck measured as the narrowest slice above the widest (z 2.00); the stalk chain
runs from the neck to the puff cluster's middle (0.27, 0.20, 2.65); the 11 loose puff and berry islands each ride their own
bone on Stalk3, rigid (so the cluster can swell by moving them apart: Roblox cannot scale).

| Bone | Parent | Joint Blender | Moves |
|---|---|---|---|
| Stalk1 | Top | (-0.11, -0.03, 2.00) | X(stalk_p[1]) Y(stalk_r[1]) |
| Stalk2 | Stalk1 | (0.02, 0.04, 2.22) | X(stalk_p[2]) Y(stalk_r[2]) |
| Stalk3 | Stalk2 | (0.14, 0.12, 2.43) | X(stalk_p[3]) Y(stalk_r[3]) |
| Puff1..11 | Stalk3 | at each island's point nearest the cluster middle (rig_meadow.json) | moves puff(k) studs along its own outward direction (island middle - cluster middle) |

- **Idle**: flyer idle; stalk_p = (0.04, 0.06, 0.08) x sin(pi t - 0.6 k); stalk_r = (0.03, 0.05, 0.07) x sin(pi t + 1 - 0.6 k) (a wave going up the stalk); puff(k) = 0.04 sin(2 pi t - 0.9 k).
- **Move**: flyer dart; stalk_p = (-0.4, -0.5, -0.6) x lag(pitch, 0.1 (k+1)); puffs as idle.
- **Attack** (1.0 s, heal pulse): lift = keys[(0,0),(0.3,0.3),(0.9,0.3),(1,0)]; squash = keys[(0,0),(0.3,-0.15),(0.9,-0.15),(1,0)] + 0.05 (hump(0.35,0.5) + hump(0.55,0.7) + hump(0.75,0.9)); pitch = keys[(0,0),(0.3,-0.08),(1,0)];
  stalk_p = (-0.05, -0.05, 0) hump(0.1,0.9); puff(k) = (0.3 keys[(0,0),(0.3,1),(0.85,1),(1,0)] + 0.1 (the three humps)) x (1 + 0.15 sin 1.7k) (swells, three pulses, deflates). Heal fires at the pulses 0.42, 0.62, 0.82 s.
- **Hit**: shared; stalk_p = (-0.8, -1.0, -1.2) x lag(pitch, 0.1 (k+1)); puff(k) = ring(0.02k, 0.08, 6, 0.3)(1 - smoothstep(0.3,0.4,t)).
- **Die**: shared flyer fall; stalk_p[k] = keys[(0,0),(0.15,-0.15),(1.1,0.35+0.1k)] (droops); puff = -0.1 smoothstep(0.5,1.1,t).

## Barkhide (armoured)

2751 tris, 8 bones, 4.6 studs. Shell = every bark-coloured vertex of the body (hue under 45, saturated) and the loose clover
leaves, rigid, fading 2 rings into the jelly; the teeth and the orange eye glow (69 specks) stay on the jelly.

| Bone | Parent | Joint Blender | Joint Roblox | Moves |
|---|---|---|---|---|
| Shell | Top | (0.24, 0.23, 1.35) | (-0.24, 1.35, 0.23) | X(shell_p) Y(shell_r) Z(shell_y), offset (0, shell_f, shell_z); - shell_p lifts the front (opens), + clamps |

- **Idle**: ground idle; shell_p = 0.03 sin(pi t - 1.4); shell_z = -0.3 (lag(squash, 0.2) - squash) (the shell rides the breath late).
- **Move**: heavy hop; shell_z = 0.4 (lag(lift, 0.06) - lift); shell_p = ring(0.7, 0.07, 6, 0.3) (a clack on landing).
- **Attack** (1.0 s, clamp and shove): fwd = keys[(0,0),(0.3,0.3),(0.4,0.3),(0.58,-1),(1,0)]; squash = keys[(0,0),(0.3,-0.08),(0.42,0.22),(0.6,0.05),(1,0)] + ring(0.6, 0.06, 3, 0.4);
  pitch = keys[(0,0),(0.3,-0.12),(0.45,0.15),(0.6,0.18),(1,0)]; shell_z = keys[(0,0),(0.3,0.25),(0.42,-0.12),(0.7,-0.08),(1,0)]; shell_p = keys[(0,0),(0.3,-0.2),(0.42,0.15),(0.75,0.1),(1,0)] + ring(0.42, 0.05, 7, 0.25). Peak 0.42 s.
- **Hit**: shared; the shell rattles: shell_y = ring(0, 0.06, 9, 0.2) e, shell_p = ring(0.02, 0.05, 8, 0.25) e, shell_z = 0.06 hump(0,0.2).
- **Die**: shared; shell_z = keys[(0,0),(0.15,0.12),(1,-0.25)]; shell_p = keys[(0,0),(1,0.12)]; shell_r = keys[(0,0),(1.1,0.08)].

## Rotbloom (mini-boss, Pollen Shockwave)

5909 tris (from 6750), 13 bones, 8 studs. Flower = the red blossom (red and its cream spots above the blossom's base),
axis (-0.08, -0.29, 0.95); 5 petals found as separate sheets beyond 0.60 of its radius; petal weights ramp from 1.66 to
3.04 studs from the centre; the centre ring stays rigid on Flower. Roots and leaves ride the cage.

| Bone | Parent | Joint Blender | Joint Roblox |
|---|---|---|---|
| Flower | Top | (-0.05, -0.07, 6.06) | (0.05, 6.06, -0.07) |
| Petal1..5 | Flower | (-0.94,-1.45,5.80) (0.77,-1.51,5.89) (1.56,-0.06,6.62) (0.07,1.35,7.05) (-1.69,0.23,6.39) | (-x, z, y) |

Flower: X(stem_p) Y(stem_r), offset (0, 0, stem_z). Petals as Gapebloom (same opening clamp).
- **Idle**: idle (d 0.035); stem_p = -0.5 (lag(pitch, 0.2) - 0.05); stem_r = -0.5 lag(roll, 0.2); petal(k) = 0.05 sin(pi t - 1 - k 2pi/5) + 1.0 lag(squash, 0.25).
- **Move**: heavy hop; stem_p = 0.5 lag(pitch, 0.1); stem_z = 0.3 (lag(lift, 0.06) - lift); petal(k) = 0.8 lag(squash, 0.1 + 0.015k).
- **Attack** (1.2 s, rear and slam): lift = 0.9 hump(0.3, 0.56) up to 0.43 s, then keys[(0.43,0.9),(0.56,0)]; squash = keys[(0,0),(0.3,-0.2),(0.5,-0.1),(0.56,0)] + ring(0.56, 0.6, 2, 0.35); pitch = keys[(0,0),(0.35,-0.2),(0.56,0.12),(1.2,0)];
  stem_z = ring(0.56, -0.5, 2.2, 0.35); stem_p = -0.4 pitch; petal(k) = keys[(0,0),(0.35,-0.3),(0.56,-0.1)] (1 - smoothstep(0.54,0.6,t)) + settle(0.6 + 0.015k, -0.6, 1.6 Hz, 0.35) smoothstep(0.54,0.6,t) (on the slam the petals whip up one after another and spring back: the shockwave). Shockwave at 0.56 s.
- **Hit**: shared; stem_p = -1.0 lag(pitch, 0.06); petal(k) = ring(0.02k, 0.25, 4, 0.3)(1 - smoothstep(0.3,0.4,t)).
- **Die**: shared; stem_z = -0.8 smoothstep(0.2,1,t); stem_p = keys[(0,0),(1,0.25)]; petal = keys[(0,0),(0.2,-0.2),(1.1,0.4)].

## Bramblehorn (boss, Thorn Charge)

7879 tris (from 11855), 10 bones, 10 studs. Horns: the wood-orange pieces (over 40 vertices, |x| > 2.3, in front of y 0.4)
at each side, cut apart by the vine wraps, plus every thin vertex (inward thickness < 1.2) within 0.3 of them; rigid,
fading 2 rings into the head. Thicket: berries and leaves (loose islands) above 0.55 of the dome top (8.65) and every thin
(< 0.9) vertex above 0.62 of it that is not horn: vines, thorns, flowers; rigid, fading 2 rings into the dome.

| Bone | Parent | Joint Blender | Joint Roblox | Moves |
|---|---|---|---|---|
| HornL | Top | (1.41, -2.69, 6.02) | (-1.41, 6.02, -2.69) | X(horn) Y(+horn_out) |
| HornR | Top | (-2.19, -0.20, 6.74) | (2.19, 6.74, -0.20) | X(horn) Y(-horn_out) |
| Thicket | Top | (0.84, 0.61, 5.58) | (-0.84, 5.58, 0.61) | X(thk_p) Y(thk_r) |

- **Idle**: idle (d 0.035); thk_p = -0.6 (lag(pitch, 0.3) - 0.05) + 0.02 sin(pi t - 2); thk_r = -0.6 lag(roll, 0.3) (slow, heavy, late); horn = 0.015 sin(pi t - 0.4).
- **Move**: heavy hop; thk_p = -0.8 lag(pitch, 0.15) + 0.06 (lag(lift, 0.12) - lift).
- **Attack** (1.2 s, Thorn Charge): fwd = keys[(0,0),(0.4,0.6),(0.65,-2.2),(0.75,-2.2),(1.2,0)]; squash = keys[(0,0),(0.4,0.2),(0.5,-0.15),(0.65,0)] + ring(0.65, 0.3, 2, 0.35);
  pitch = keys[(0,0),(0.4,0.25),(0.65,0.3),(1.2,0)]; lift = 0.25 hump(0.45,0.65); horn = keys[(0,0),(0.4,0.2),(0.75,0.2),(1.2,0)] + ring(0.65, 0.04, 4, 0.3) (head and horns down, then the charge);
  thk_p = -0.6 lag(pitch, 0.15) + ring(0.7, 0.2, 1.5, 0.3) (the thicket whips on impact). Impact at 0.65 s. In place: the server moves the boss for the real charge.
- **Hit**: shared; thk_p = -0.9 lag(pitch, 0.08); thk_r = -0.9 lag(roll, 0.08).
- **Die**: shared; thk_p = keys[(0,0),(0.2,0.1),(1.1,-0.2)]; thk_r = keys[(0,0),(1.1,0.12)]; horn = keys[(0,0),(1,0.15)]; horn_out = keys[(0,0),(1,0.08)].

## Which bones each state touches

Idle, Move, Hit, Die: every bone. Attack: every bone (Burrling: cage only). Root never moves. One owner per bone: play the
takes OR drive Bone.Transform from these formulas, never both on the same rig.

## Known limits

- Monster height H above is the mesh height (Burrling 4.4, Stinglob 3.6, Gapebloom 4.2, Sapcaller 3.8, Barkhide 4.6, Rotbloom 8, Bramblehorn 10).
- The meshes are image-to-3D (Tripo): Bramblehorn's horns are not mirror images (HornL sits forward at y -2.7, HornR at
  y -0.2), and Stinglob's two wings are placed differently; joints follow the mesh, so the two sides move a little differently.
- Squash moves vertices, it does not keep volume exactly; past squash 0.85 (Die) the base spreads 38% and the top
  sinks under the thorns/petals' rest height: it reads as a melt, not a clean puddle.
- Gapebloom's front petals open less than the others (clamped so they never fold into the body); Rotbloom's shockwave
  flap goes up, not down, for the same reason. Stinglob's down-stroke stops at +0.3 rad for the same reason.
- Wing beat is 6 Hz in the takes (30 fps); a procedural port can go faster.
- Weights are rigid on hard parts: horns, shell, stinger shaft and puffs never bend; the stinger bends only at its one
  middle joint (Stinger2).
- Texture: each monster now has its own 1024 (`<Name>/<Name>.png`, UV map "Own" in the FBX), an emission bake of the
  shared 4096 (`meadow_texture.jpg`); checked side by side in `review/<Name>_texture.png`. `rig_meadow.json` also carries
  height, peak, the cage, part vectors and `golden` samples (8 per action), as the other regions (see `../ice/MOTION.md`).
