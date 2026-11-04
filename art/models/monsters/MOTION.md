# Sunny Meadow monsters: pieces, joints and motions

Built by `tools/blender/monsters/*.py` (shared helper `common.py`; `build_all.ps1` rebuilds everything). One FBX and one 256 px palette png per monster in `art/models/monsters/<Name>/`.

## Conventions (read first)

- Scale: 1 Blender metre = 1 stud. The monster faces Blender -Y, which is Roblox -Z (the front of a Roblox model).
- Every monster is SEPARATE rigid mesh pieces, no armature (the game animates them procedurally, like the slimes). `Body` is the root; its origin is on the ground under the middle (feet at z 0, a hovering monster is lifted by the game).
- Each other piece has its ORIGIN AT ITS JOINT (the pivot to rotate about). Pieces keep their positions relative to Body, so the model is whole when every piece sits at its Body-relative joint.
- Names ending L are the monster's own LEFT. Seen from the front (the monster facing you) its left is on your right. In Blender that is +X; in Roblox mesh space it is -X.
- Axis mapping Blender (bx, by, bz) to Roblox mesh space: (-bx, bz, by); the FBX export (axis_forward -Z, axis_up Y) already does this, so in Studio the front is -Z and up is +Y. The joint tables below list Blender metres and the Roblox offset from Body.
- Material: one palette texture (nearest sampling), no baked light; the game light shades it. Faces are single-sided: Studio's backface culling is fine, leaves are thin double-sided sheets where it matters.
- Triangle budgets: normal 800-2000, elite up to 2500, mini-boss and boss up to 4000.

## Sproutling (normal, melee)

Painting `enemy-green-sprout.png`; 1947 tris, 6 pieces, 4.37 studs tall (target 4.2); walks and hops on the ground.
Bounding box (Blender metres): x -2.23..2.13, y -1.40..1.21, z -0.16..4.21.

| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |
|---|---|---|---|---|
| Body | 820 | 0.00, 0.00, 0.00 | -0.00, 0.00, 0.00 | Squash and hop by code; the whole monster follows it. Origin on the ground under the centre. |
| Sprout | 139 | 0.08, 0.00, 2.79 | -0.08, 2.79, 0.00 | Sway side to side (rotate about the joint, +-12 deg, 0.8 Hz) and bob with the hop. |
| EarL | 144 | 1.18, -0.17, 1.99 | -1.18, 1.99, -0.17 | Wiggle: rotate about the root +-10 deg at 1.5 Hz, extra flick when it attacks. |
| EarR | 144 | -0.73, -0.26, 1.80 | 0.73, 1.80, -0.26 | Wiggle: rotate about the root +-10 deg at 1.5 Hz, extra flick when it attacks. |
| FootL | 332 | 1.04, -0.52, 0.71 | -1.04, 0.71, -0.52 | Swing +-25 deg about the hip while walking (alternate), stamp on attack. |
| FootR | 368 | -0.89, -0.86, 0.69 | 0.89, 0.69, -0.86 | Swing +-25 deg about the hip while walking (alternate), stamp on attack. |

## HoneyBee (normal, hunter)

Painting `enemy-green-bee.png`; 1972 tris, 9 pieces, 4.12 studs tall (target 4.3); flies: the game lifts the whole model 3-5 studs and bobs it.
Bounding box (Blender metres): x -2.24..2.24, y -1.21..3.14, z 0.00..4.12.

Wings: each WingL/WingR holds a fore- and a hind-wing as flat sheets; set Transparency about 0.35 on both in game (the painting's wings are glassy). Flap 12-20 Hz about the root joint (rotate about the line along the body, the model's Y axis in Blender, Z in Roblox).

| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |
|---|---|---|---|---|
| Body | 658 | 0.00, 0.00, 0.00 | -0.00, 0.00, 0.00 | Root. Hover bob +-0.15 stud at 3 Hz; lean forward when it dives. Origin under the head. |
| Abdomen | 244 | 0.00, 0.53, 2.02 | -0.00, 2.02, 0.53 | Wobble about the joint (pitch +-8 deg, 1.2 Hz) and curl down when it stings. |
| Bud | 220 | 0.00, 2.25, 3.11 | -0.00, 3.11, 2.25 | Sway about the joint (+-10 deg, 2 Hz, lags the abdomen); drips glow on a hit. |
| WingL | 96 | 0.57, 0.02, 2.29 | -0.57, 2.29, 0.02 | Flap about the root axis (the line along the body): +-38 deg at 14-18 Hz while flying; slow +-10 deg at idle. |
| WingR | 96 | -0.57, 0.02, 2.29 | 0.57, 2.29, 0.02 | Flap about the root axis (the line along the body): +-38 deg at 14-18 Hz while flying; slow +-10 deg at idle. |
| AntennaL | 99 | 0.27, -0.91, 1.75 | -0.27, 1.75, -0.91 | Bob and sway about the root (+-12 deg, 1.6 Hz, out of phase with the other). |
| AntennaR | 99 | -0.27, -0.91, 1.75 | 0.27, 1.75, -0.91 | Bob and sway about the root (+-12 deg, 1.6 Hz, out of phase with the other). |
| LegsL | 310 | 0.40, 0.53, 1.30 | -0.40, 1.30, 0.53 | Swing the three legs a few degrees about the joint (+-14 deg) as it flies; tuck up when it dives. |
| LegsR | 150 | -0.40, 0.53, 1.30 | 0.40, 1.30, 0.53 | Swing the three legs a few degrees about the joint (+-14 deg) as it flies; tuck up when it dives. |

## Puffdandy (normal, ranged)

Painting `enemy-green-dandelion.png`; 1987 tris, 5 pieces, 4.41 studs tall (target 4.4); floats: the game lifts the whole model about 2 studs and drifts it.
Bounding box (Blender metres): x -1.87..1.78, y -1.33..1.30, z 0.12..4.53.

The three loose dandelion seeds around the painting are NOT in the model (effect: drift them by code).

| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |
|---|---|---|---|---|
| Body | 572 | 0.00, 0.00, 0.00 | -0.00, 0.00, 0.00 | Float: bob +-0.25 stud at 1.2 Hz and drift; origin on the ground under the blob (the game lifts it). |
| Puff | 1116 | -0.04, 0.07, 1.86 | 0.04, 1.86, 0.07 | Sway on the neck (+-6 deg, 1 Hz), puff up (scale 1.1) when it shoots, shake loose on a hit. Origin where it sits on the body. |
| ArmR | 80 | -0.82, -0.07, 1.32 | 0.82, 1.32, -0.07 | Wave: rotate about the root +-25 deg at 1.8 Hz; swing wide when it shoots. |
| ArmL | 80 | 0.86, -0.04, 1.45 | -0.86, 1.45, -0.04 | Wave: rotate about the root +-25 deg at 1.8 Hz; swing wide when it shoots. |
| Tail | 139 | 0.27, 0.04, 0.95 | -0.27, 0.95, 0.04 | Swish: rotate about the root +-18 deg at 1.5 Hz with a travelling wave (tip lags). |

## Glowmoth (normal, healer)

Painting `enemy-green-moth.png`; 1852 tris, 7 pieces, 3.98 studs tall (target 4.0); flies: the game lifts the whole model 3-4 studs and bobs it.
Bounding box (Blender metres): x -2.56..2.56, y -1.32..1.07, z -0.07..3.91.

Wings: set Transparency about 0.2 if wanted; the flap is slow (3-4 Hz, +-30 deg), a moth not a bee. The two antennae end in glowing drops (give them a PointLight / Neon material in game).

| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |
|---|---|---|---|---|
| Body | 890 | 0.00, 0.00, 0.00 | -0.00, 0.00, 0.00 | Float: bob +-0.3 stud at 1.5 Hz, tilt a few degrees with the flap. Origin on the ground under the body. |
| WingL | 192 | 1.07, 0.25, 1.74 | -1.07, 1.74, 0.25 | Slow soft flap about the root: +-30 deg at 3-4 Hz (a moth, not a bee); the healing pulse spreads them wide. |
| WingR | 192 | -1.07, 0.25, 1.74 | 1.07, 1.74, 0.25 | Slow soft flap about the root: +-30 deg at 3-4 Hz (a moth, not a bee); the healing pulse spreads them wide. |
| AntennaL | 177 | 0.33, 0.00, 2.35 | -0.33, 2.35, 0.00 | Bob and curl about the root (+-10 deg, 1.2 Hz, the drop swings after); the drop glows when it heals. |
| AntennaR | 177 | -0.33, 0.00, 2.35 | 0.33, 2.35, 0.00 | Bob and curl about the root (+-10 deg, 1.2 Hz, the drop swings after); the drop glows when it heals. |
| FootL | 112 | 0.39, -0.16, 0.49 | -0.39, 0.49, -0.16 | Tuck up while flying; swing a few degrees (+-10) with the bob. |
| FootR | 112 | -0.49, -0.12, 0.64 | 0.49, 0.64, -0.12 | Tuck up while flying; swing a few degrees (+-10) with the bob. |

## CloverSnail (elite)

Painting `enemy-green-snail.png`; 2476 tris, 4 pieces, 4.75 studs tall (target 5.0); slides on the ground.
Bounding box (Blender metres): x -1.88..1.50, y -2.67..3.34, z 0.00..4.75.

The shell's spiral is on the monster's RIGHT side only (the painting shows that flank); the left side is plain leaves and dark shell.

| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |
|---|---|---|---|---|
| Body | 876 | 0.00, 0.00, 0.00 | -0.00, 0.00, 0.00 | Slither: squash-stretch along Y at 1 Hz (length x1.08 / height x0.94) and ripple the foot lobes; origin on the ground under the foot. |
| StalkL | 114 | 0.55, -1.27, 1.80 | -0.55, 1.80, -1.27 | Sway about the root (+-14 deg, 1.1 Hz, out of phase); lean toward the target when it spots one. |
| StalkR | 114 | -0.55, -1.27, 1.80 | 0.55, 1.80, -1.27 | Sway about the root (+-14 deg, 1.1 Hz, out of phase); lean toward the target when it spots one. |
| Shell | 1372 | 0.00, 0.75, 0.55 | -0.00, 0.55, 0.75 | Wobble about the joint (+-5 deg roll, 1 Hz) with the slither; rattle on a hit. Origin where it rests on the foot. |

## Bloomshell (mini-boss, wave 5)

Painting `enemy-green-turtle.png`; 3636 tris, 7 pieces, 7.98 studs tall (target 8.0); walks on four legs.
Bounding box (Blender metres): x -4.25..4.25, y -5.87..4.64, z -0.67..7.31.

The Bud swells and glows before a big attack; Head lunges forward on a bite.

| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |
|---|---|---|---|---|
| Body | 1524 | 0.00, 0.00, 0.00 | -0.00, 0.00, 0.00 | Root. Slow lumbering sway (+-2 deg roll, 0.9 Hz) and a heavy 0.25 stud dip per step; origin on the ground under the middle. |
| Bud | 500 | 0.00, 0.86, 4.86 | -0.00, 4.86, 0.86 | Sway about the joint (+-6 deg, 0.7 Hz), swell (scale 1.08) and glow before a big attack; opens (petals out 25 deg) when it enrages. |
| Head | 628 | 0.00, -2.74, 1.33 | -0.00, 1.33, -2.74 | Look/turn about the neck (yaw +-30 deg), lunge forward 0.6 stud on a bite, bob down at each step. |
| LegFL | 246 | 2.81, -2.02, 1.94 | -2.81, 1.94, -2.02 | Swing +-20 deg about the hip, diagonal pairs together (walk cycle 1.1 Hz); stamp (+-35 deg) on the slam attack. |
| LegFR | 246 | -2.81, -2.02, 1.94 | 2.81, 1.94, -2.02 | Swing +-20 deg about the hip, diagonal pairs together (walk cycle 1.1 Hz); stamp (+-35 deg) on the slam attack. |
| LegBL | 246 | 2.88, 2.88, 1.87 | -2.88, 1.87, 2.88 | Swing +-20 deg about the hip, diagonal pairs together (walk cycle 1.1 Hz); stamp (+-35 deg) on the slam attack. |
| LegBR | 246 | -2.88, 2.88, 1.87 | 2.88, 1.87, 2.88 | Swing +-20 deg about the hip, diagonal pairs together (walk cycle 1.1 Hz); stamp (+-35 deg) on the slam attack. |

## Bramblehorn (boss, wave 10)

Painting `enemy-green-boar.png`; 3933 tris, 9 pieces, 10.96 studs tall (target 11.0); walks on four legs, charges.
Bounding box (Blender metres): x -4.39..4.83, y -9.82..10.68, z 0.00..10.96.

Glowing amber cores (back and one flank) are in the palette as bright colours: a Neon part or an emission pulse in game makes them glow.

| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |
|---|---|---|---|---|
| Body | 2074 | 0.00, 0.00, 0.00 | -0.00, 0.00, 0.00 | Root. Heavy breathing (scale Y 1.02 at 0.6 Hz), stomp dip 0.3 stud per step, rear-up lean on the charge wind-up; origin on the ground under the middle. |
| Head | 978 | 0.00, -3.17, 3.84 | -0.00, 3.84, -3.17 | Look/turn about the neck (yaw +-30 deg); head-butt: dip 20 deg and thrust 1.5 studs; roar: lift 12 deg. |
| EarL | 46 | 2.06, -4.80, 5.28 | -2.06, 5.28, -4.80 | Flick: rotate about the root +-15 deg at 2.5 Hz, pin back when it charges. |
| EarR | 46 | -2.06, -4.80, 5.28 | 2.06, 5.28, -4.80 | Flick: rotate about the root +-15 deg at 2.5 Hz, pin back when it charges. |
| LegFL | 162 | 2.59, -1.92, 5.18 | -2.59, 5.18, -1.92 | Swing +-22 deg about the hip, diagonal pairs together (walk 1.0 Hz); stamp (+-30 deg) on the slam. |
| LegFR | 162 | -2.59, -1.92, 5.18 | 2.59, 5.18, -1.92 | Swing +-22 deg about the hip, diagonal pairs together (walk 1.0 Hz); stamp (+-30 deg) on the slam. |
| LegBL | 132 | 2.69, 5.38, 5.18 | -2.69, 5.18, 5.38 | Swing +-22 deg about the hip, diagonal pairs together (walk 1.0 Hz); stamp (+-30 deg) on the slam. |
| LegBR | 132 | -2.69, 5.38, 5.18 | 2.69, 5.18, 5.38 | Swing +-22 deg about the hip, diagonal pairs together (walk 1.0 Hz); stamp (+-30 deg) on the slam. |
| Tail | 201 | 0.00, 7.68, 6.24 | -0.00, 6.24, 7.68 | Swish: rotate about the root +-25 deg at 1.4 Hz with a travelling wave (the leaves lag). |
