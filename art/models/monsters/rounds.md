# Sunny Meadow monsters: rounds

Method: each painting (`reference/goo-lineage-web/assets/enemy-green-*.png`) is ONE 3/4 view, so the camera that
matches the painting is found by a search (or fixed where the painting's view is known) and the silhouette IoU is
measured at that camera, after scaling the render to the painting's area and centring it. Tiles in every
`<Name>/review/sheet_<round>.png`: painting | studio render | flat-colour render | overlap (red = painting only, blue =
render only, grey = both). `views_<round>.png` shows front, 3/4, side, back, 3/4 other side and top (sides and back are
inferred). Every picture was looked at.

HONEST NOTE ON THE JUDGE: the brief asks for a FRESH subagent judge each round. This agent has no subagent tool, so
every round was self-judged against the `ROBLOX.md` rubric (silhouette 0-4, parts 0-3, colour 0-2, details 0-1) by
looking at the sheets. A real judge pass by the orchestrator is still worth doing before the models go in.
The IoU of a single painted 3/4 pose against a model built level facing the front is limited by the pose (the painted
wings, tails and heads point in directions the model does not take); 0.75-0.85 is a good value for that, 0.63 for the bee.

## Sproutling (normal, 800-2000 tris)

- r1 (first draft): 1947 tris, IoU 0.847 (az 0, el 16). Score 8/10. Ears and body right; foot rings too thin, brows missing in the look.
- r2: ears re-measured from the painting (EarL tip 1065,170; EarR 150,330), gold ring radii 42/52, eye size, sprout leaves. 1947 tris, IoU 0.847, 9/10.
- r3: the dark brow bars thickened (radius 27/20) and pushed out so the angry look reads. 1947 tris, IoU 0.849, aspect error -5.5 %. Score 9/10 (silhouette 3, parts 3, colour 2, details 1).
- Still differs: painting's gloss and drops (by design none: the game's light does that); the back and under side are inferred; the feet sit a little below z 0 (-0.16 studs, the paw pads).

## HoneyBee (normal, hunter, flies)

- r1: 2070 tris (over budget), IoU 0.622. Wings huge and hiding the abdomen, abdomen thin. 4/10.
- r2: wings shortened (450 x 215 fore, 320 x 165 hind), abdomen lathe 10 sides, search to az 90. 2026 tris, IoU 0.592: wings still cover the abdomen. 5/10.
- r3: wings moved lower and out (axis 0.93, 0.3, 0.28), abdomen widened 12 %. IoU 0.592, but the abdomen and bud read like the painting. 6/10.
- r4: body pitch 42 -> 32 deg, leg tubes 4 sides, 5-sided leaf cuffs. 1972 tris (in budget), IoU 0.633 (az 28, el 30), aspect -4.6 %. Score 6/10 (silhouette 2, parts 3, colour 1, details 0).
- Still differs: the painting's wings are glassy with a pearly sheen (in game set Transparency about 0.35); the painted head is bigger and the fur ruff fluffier; a wing sheet is single, its shape and the pose are only approximated (the painted bee is mid-dive, the model hovers level).

## Puffdandy (normal, ranged, floats)

- r1: 1639 tris, IoU 0.793. Puff a flat-topped hat. 6/10.
- r2: puff now a true sphere-ish oblate ball (exponent 2.0), leaf arms enlarged. IoU 0.785 (arms too big and low, blue in the overlap). 6/10.
- r3: arm leaf tips raised and widths reduced (110/140 and 130/100). 1639 tris, IoU 0.787 (az 0, el 0), aspect -0.1 %. Score 7/10 (silhouette 3, parts 2, colour 1, details 1).
- Still differs: the three loose seeds are NOT built (effects by code); the fluff of the puff is a smooth ball with petal fans and a brown star centre, not hundreds of wisps; the stem tail's curl is simplified. Studio's grey puff is only the dark studio light, the flat render shows true white.

## Glowmoth (normal, healer, flies)

- r1: 1816 tris, IoU 0.768 at a searched camera (az 20, el 32) that did not look like the painting. 5/10.
- r2: a cream face mask was added behind the eyes. 1852 tris, IoU 0.768. Too skull-like. 5/10.
- r3: camera fixed to the painting's front view (0, 12). IoU 0.743, aspect 7.7 %. The mask still too big. 6/10.
- r4: mask smaller and fur-yellow (r 175, height 0.6) so the cream stays on the chest. 1852 tris, IoU 0.743. Score 7/10 (silhouette 3, parts 2, colour 1, details 1).
- Still differs: antennae are simpler (the painting's two differ in curl; made symmetrical), the wings lack the painted pearly veins, the fluffy rim of the body is smooth.

## CloverSnail (elite, up to 2500 tris)

- r1: 2298 tris, IoU 0.819 at az -50 (silhouette good). The spiral leaves were almost invisible: the 14-sided shell ovoid's facets sag 0.05 m below its true surface and hid leaves placed 3 px off it. 5/10.
- r2: leaves, clovers, flowers pushed 45-55 px off the shell; leaf bend reduced; a wrong-side test at az +30 showed the plain flank (IoU 0.640) and proved the sides. IoU 0.806 at az -30 el 20. 6/10.
- r3: camera fixed to the painting's view of the right flank (-62, 24); IoU 0.703.
- r4: 16 leaves, bigger; shell flank painted leaf green; height too big (5.9). IoU 0.717. 6/10.
- r5: leaves smaller (width 215+6k, length 250+10k), S 0.0055 -> 0.0050 (5.18 studs). IoU 0.708.
- r6: camera (-46, 28), closer to the painting's. 2410 tris, IoU 0.749, aspect error 17.9 %. Score 6/10 (silhouette 2, parts 2, colour 1, details 1).
- Still differs: the painting's shell is a tight spiral of big leaves with a clear whorl and large clovers; ours is a heap of flat leaf shingles with small clovers, and the face is less frontal. The slime body's glossy drips and the foot's puddle lobes are simplified. Triangle count 2410 is near the 2500 cap, so more leaf detail needs a coarser body.

## Bloomshell (mini-boss, up to 4000 tris)

- r1: 3280 tris, IoU 0.783, height 8.78. Bud too large, shell narrow, legs boxy. 6/10.
- r2: bud 17 % smaller (petals 310 x 200), shell wider (radius 520), legs slimmer (125/120/115), S 0.0078 -> 0.0072. 3300 tris, IoU 0.793, height 7.61. 6/10.
- r3: head enlarged (235 x 215 x 175), two leaf plates added on each leg. 3524 tris, IoU 0.797 (az 10, el 24), aspect 7.1 %, height 7.87. Score 7/10 (silhouette 3, parts 2, colour 1, details 1).
- Still differs: the painted head is lower and wider with a brow line (ours has gold cheek spikes but a calmer face); the leg leaf plates are mostly hidden inside the thick legs (the legs read as plain green columns); the rear legs are inferred (one rear claw set shows); no plastron or tail (neither shows).

## Bramblehorn (boss, up to 4000 tris)

- r1: 3073 tris, IoU 0.775, height 13.13 (target 11). Wide cream slabs (leg tops and flank) not in the painting. 4/10.
- r2: S 0.0115 -> 0.0096 (10.96 studs), search widened to az +-80 (the front view still wins). IoU 0.775.
- r3: cream only on the belly; seven leaf shingles per flank added. 3465 tris. 5/10.
- r4: the leg tube cream replaced by moss, the cream slab disappears. 5/10.
- r5: leg radii 135/115/100 and hips pulled in to 270/280, so the legs are not slabs. 3465 tris, IoU 0.755 (az -10, el 10), aspect -3.4 %, height 10.96. Score 6/10 (silhouette 3, parts 2, colour 1, details 0).
- Still differs: the painted boar is mid-charge with its head low and body turned (ours stands level, facing the front); the whole body in the painting is smothered in leaves, flowers and bark (ours has 14 leaf plates, 10 small flowers, three bark bands and two glowing cores); legs are still sturdier and plainer than the painted gnarled bark legs; the tail is shorter and the painted rear hoof's bark cuffs are only one band.

## Coordinator round (colour, puff, boar, snail spiral, turtle legs)

The coordinator judged `sheet.png`: renders olive and muddy against bright, saturated paintings. Fixes:
- Colours: every palette re-picked from the paintings' lit mid tones (`sample.ps1` prints a painting colour at a point) and brightened
  (Sproutling lime green #9AD42C with cream belly; Glowmoth fur #FFD535, cream #FFF1CC, saturated pink #F5607E; Bee yellow #FFCB14, green #5E9E1E,
  wings #FFFCEA with a #FFE68A edge; snail teal #25CC8E, shell greens; boar moss #5E8E1E, gold #FFC428; turtle leaves #C2E23A/#92D23E).
- Comparison renders are now "lit": 20 % Workbench studio shading over 80 % true palette (the studio light alone is a dim room); the
  flat tile is the pure palette. Same blend in `lineup.png`.
- Puffdandy: puff is white (#F8F8F2) with a pale-gold centre, a scalloped rim of 15 + 10 white tuft fans, so the silhouette is fluffy; scale
  0.0040 -> 0.0037, camera fixed to the painting's front view (0, 8). 1987 tris, IoU 0.711, height 4.41. 7/10.
- CloverSnail: two winding ribbons (leaf-lime and light green, 2 turns) from a swirl centre make a visible spiral; a big 4-lobe clover up-right of
  the whorl, a small one in its eye, three more small ones; shell sphere 16 x 10 (hidden side stays coarse), 4 big outer leaves, 8 rim spikes.
  2476 tris (cap 2500), IoU 0.748, height 4.75. 7/10.
- Bloomshell: three leaf plates per leg follow the leg's slope and stand on its front (visible now), head lowered 40 px and moved forward,
  crest lowered, brighter palette. 3636 tris, IoU 0.785, height 7.98. 7/10.
- Bramblehorn: tusks bigger (radius 88 -> 8, five-point curve, rising 700 px, two spikes), head lower and a little forward, 16 back leaf
  clusters, 6 white and 10 blue flowers, a front leaf ruff of 17 leaf plates over the shoulders, brighter palette; camera (-10, 16). 3933 tris,
  IoU 0.724, height 10.96. 7/10. A tried camera (-24, 32) showed the back but shrank IoU to 0.61 (the painting is nearly head-on), so it was dropped.
  A hash-mottled torso looked like a checkerboard and was dropped.
- Glowmoth, HoneyBee, Sproutling: palette only (same shapes, IoU unchanged).

## Boar redesign round (Bramblehorn only; the ox/cow read was the problem)

- r9 (round 1): rebuilt as a low heavy moss-covered wild boar. Torso = shoulder hump (higher) + lower rump, bark bands, glowing core, spikes,
  shingled leaves and flowers over the back; head = pitched wedge sloping to a flat DARK brown snout disc with two nostrils, small eyes under a
  heavy brow, short pointed leaf ears, moss/leaf face, clover crest with gem, small gold forehead spikes; gold tusks from the lower jaw curving
  up and back (no sideways horns); short thick legs with dark hooves and gold tips; height 11.1. First builds were 4175-4627 tris, over budget;
  cut with fewer shingle leaves, coarser torso spheres (14x8, 12x7), two leg-plate rows instead of three, 6-sided band tubes: 3983 tris.
- r10 (round 2): tusks thicker (radius 0.55 -> 0.72) and taller, leaf cuff wider, cream chin beard leaves larger (no extra tris).
  3983 tris, IoU 0.753 (az -30, el 8), aspect err 1.5 %, height 11.10.
- Still differs: the painting's beard and cheek ruff are fuller and cream (ours: three small cream leaves, barely visible); painted head is
  broader with leaf-clad cheeks; painting has a stronger eye glare; legs in the painting are gnarled bark. No second judge subagent was available,
  so both rounds were self-judged against the painting overlays.

## Budgets (final)

| Monster | Tris (budget) | Pieces | Height studs (target) | IoU | Camera | Score (self) |
|---|---|---|---|---|---|---|
| Sproutling | 1947 (800-2000) | 6 | 4.37 (4.2) | 0.849 | 0, 16 | 9 |
| HoneyBee | 1972 (800-2000) | 9 | 4.12 (4.3) | 0.633 | 28, 30 | 6 |
| Puffdandy | 1987 (800-2000) | 5 | 4.41 (4.4) | 0.711 | 0, 8 | 7 |
| Glowmoth | 1852 (800-2000) | 7 | 3.98 (4.0) | 0.743 | 0, 12 | 7 |
| CloverSnail | 2476 (up to 2500) | 4 | 4.75 (5.0) | 0.748 | -46, 28 | 7 |
| Bloomshell | 3636 (up to 4000) | 7 | 7.98 (8.0) | 0.785 | 10, 24 | 7 |
| Bramblehorn | 3983 (up to 4000) | 9 | 11.10 (11.0) | 0.753 | -30, 8 | 7 (boar redesign, see below) |

Every monster: one 256 px palette png (nearest sampling, no baked light), at most one material, rigid pieces with the
origin at the joint, Body root at the ground centre, no armature.
