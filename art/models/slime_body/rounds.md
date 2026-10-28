# Slime body: rounds

Reference: `reference/goo-lineage-web/assets/slime.base.navy.png` (398 x 409 px, front view only). The other ten
`slime.base.*.png` were looked at for the shape and highlight layout (same design; yellow and blue show the highlights).
Build: `tools/blender/slime_body.ps1 -Round N` (script `tools/blender/slime_body.py`); check of the exports:
`tools/blender/slime_body_roundtrip.py` -> `review/roundtrip.json`.

Measured from the painting's alpha (>= 0.5, sub-pixel edges): body 371.75 px tall (rows 12.14 to 383.89), widest
392.8 px at z = 0.335 H, width/height 1.056; one vertical axis at x = 198.85 px; the painting leans (tip centre
194.5 px, upper body centre 201 px), so a symmetric body cannot beat a row IoU of 0.9844 (the ceiling). Flat contact
disc radius 0.117 H (the bottom edge rises 1 % of the height by r = 0.27 H, 4 % by r = 0.40 H: a soft lip curving
under). Colour of the painting's body (central columns, median sRGB): 0,71,215 upper, 0,68,208 middle, 0,37,154
lower, a bright lip ring 0,83,222 at z = 0.048, dark rim 0,30,136 at the base.

Judge: the fresh-subagent judge could not be run (this agent has no tool to start a subagent); every round below was
judged by me with the ROBLOX.md prompt, on the numbers in `review/rN/metrics.json` and the sheets. The orchestrator
should run the fresh judge on `review/r4/` before sign-off.

Sheets per round (`review/rN/`): `sheet_front.png` = painting | render with outline hull | render body only |
silhouette overlap (grey both, red painting only, blue model only); `sheet_views.png` = side | back | top | game
camera front-left | game camera back-right | game camera with hull; `sheet_deform.png` = rest | squash (sy 0.52,
sx 1.5) | stretch (sy 1.32, sx 0.82), front ortho then game camera; `sheet_wire.png` = wire front, game, top, clay
top, clay game.

## Round 1 (first draft)

Revolved profile (40 segments x 30 curvature-placed rings, 2,400 tris, analytic custom normals), front-projected UV,
overlay = white with alpha from the painting's red channel (navy's R is 0, highlights are white), rig Root/Base/Top/
Left/Right/Front/Back with exact affine weights, inverted hull at +0.8 % H.

- IoU front body 0.9842 (ceiling 0.9844); body + hull 0.9678. Widths per height within 1 px except z 0.02 (-4 px).
  Ring chord sag 1.03 painting px.
- Score 7.5/10: silhouette 4, parts 3, colour 0.5, details 0 (highlight smear on the sides, below).
- Faults: (major) side, top and squash views show a vertical/horizontal streaky band where the front projection
  turns sideways: the painting's edge pixels smear over the sides. (major) preview colour too pale (sky ambient too
  strong): middle not measured yet, visibly lighter than the painting. (minor) game camera too far.

## Round 2

Fixed: overlay fades out between 0.92 and 0.985 of the radius at each height (painted streaks end by 0.88);
hemisphere ambient (sky above, ground below); preview sun aimed so its real glint lands in the painted upper-left
streak (centroid of the streak, reflected about the surface normal there); colour measured per band.

- IoU 0.9842 / 0.9678. Colour (painting -> render): upper 0,71,215 -> 40,76,210; middle 0,68,208 -> 33,60,169;
  lower 1,37,154 -> 11,30,108.
- Score 8.5: silhouette 4, parts 3, colour 1, details 0.5. Side/top smears gone (verified in side.png, top.png).
- Faults: (major) lower body 30 % too dark against the painting; (major) the painting's bright lip ring above the base
  is missing; (minor) hull rim thinner than the painting's dark rim (render ~1.5 px at 1x vs ~4 px).

## Round 3

Fixed: lip ring added to the overlay as a fixed-height ring measured from the painting (white alpha 0.2, centre
z 0.048, sigma 0.012; rows 359-371); more ground bounce in the preview ambient; outline colour 0.6 x body.

- IoU 0.9842 / 0.9678. Colour: upper 43,80,220; middle 37,66,184; lower 25,46,138.
- Score 9: silhouette 4, parts 3, colour 1.5, details 0.5.
- Faults: (major) dark rim still thin; (minor) preview desaturated by the white sky reflection (R 37-43 vs 0).

## Round 4 (final)

Fixed: hull inflation 1.1 % H (the painting's rim is ~4 px of 372); bluer sky in the preview. Added clay top/game
renders to check the tip and base poles: no pinch or ring artifact at the tip (clay_top.png), the neck's concave
shading is real geometry.

- IoU front body **0.9842** (symmetric ceiling 0.9844); body + hull 0.9568 (the hull adds 1.1 % outside the painted
  silhouette, whose dark rim lies inside its alpha). Width/height 1.054 vs painting 1.056. Widths per height band
  within 1 px of the painting except z 0.85 (+2 px, the tip's lean) and z 0.02 (-4 px, flat contact disc).
- Colour (preview lights, game navy #1b4fd8): upper 37,76,220 / 0,71,215; middle 32,62,184 / 0,68,208; lower
  25,45,138 / 1,37,154.
- Deformation exact: squash height 0.520 (sy 0.52) width 1.584 = 1.5 x 1.056; stretch 1.320 / 0.866 = 0.82 x 1.056;
  base stays at z = 0; smooth and round in both extremes (sheet_deform.png).
- Round trip (roundtrip.json): 2,400 tris each, 1,202 verts, max 4 influences, weights sum to 1.0, custom normals
  and UVMap present, bones and positions as built, Root unskinned.
- Score 9/10: silhouette 4, parts 3, colour 1.5, details 0.5.
- Remaining (minor, not fixable in this model): the painting's lean and right-side bulge (red/blue fringes in the
  overlap tile, the IoU ceiling); the painting's light inner band just inside the whole outline is view-dependent
  (Fresnel), it comes from Roblox's gloss, not from a fixed map; the hull is a solid line where the painting's rim
  is soft; preview desaturation is the preview's sky, not the model.

# Slime colours (body and rim colour per single-colour slime, the shared gloss)

Brief (changed mid-run by the owner's word): highlights and the top-light / bottom-dark ramp in the paintings are
light, not colour, so nothing is baked: no per-slime colour map. Every slime shares one SurfaceAppearance (flat
normal map, roughness map, no ColorMap); MeshPart.Color = the painting's body colour; outline hull = its rim colour.
References: `reference/goo-lineage-web/assets/slime.base.<colour>.png`, the 11 single colours (front view each).
Build: `tools/blender/slime_colours.ps1 -Pass N -Rough R` (script `tools/blender/slime_colours.py`; it opens
`SlimeBody.blend` and never changes the mesh, rig or UVs). Output `colours/colours.json`; sheets in
`review/colours/pN/`: `sheet_<colour>.png` = painting | front | game camera | swatches per band (painting left,
render right; upper, middle, lower), `sheet_roughness.png` = rows navy front, navy game camera, yellow front, white
front; columns painting, roughness 0.05, 0.1, 0.15, 0.25; `contact.png` = 11 front renders above the 11 paintings.

Measuring: each painting's own silhouette, axis and lean (`slime_body.measure`); body = median sRGB of the interior
in the mid-height band 0.35-0.60 H, columns within half the half-width, 7 px inside the alpha edge (rim and its light
inner band cut away), highlight pixels (lighter toward white than the band median by > 0.03) left out. Rim = median of
the 1st and 2nd solid px inside the alpha edge (the per-depth profile shows the dark line is 2 px; from the 3rd px it
is the body's lower shading). Judge: no fresh subagent could be started (no tool for it); judged by me on the sheets.

## Pass 1
Round-4 preview light (blue sky 0.60,0.74,1.0, sun 2.1) plus three hand-placed soft bright areas. Rim from px 2-4.
- Faults: (major) warm slimes olive and 25-30 % too dark in the middle band (yellow 252,229,19 -> 183,179,50): the
  round-4 sky was tuned blue for navy; (major) the soft areas reflect as dull blobs in the middle of the body, no
  streaks, roughness 0.05-0.25 hardly differ; (minor) rim measured too light (px 2-4 are the lower body shading).

## Pass 2
Fixed: rim = px 1-2; neutral sky (0.82,0.88,1.0), warm-grey ground; the clouds now come from the painting itself:
every navy highlight pixel is mirrored about the front surface normal into a sky direction (`sky_clouds.png`), LDR
(white, no brighter than the sky's strength) like a Roblox skybox.
- Faults: (major) no streak shows: white clouds on a near-white sky have no contrast; (major) middle band still
  ~30 % too dark (yellow -> 178,170,49): the preview exposure is low; (minor) a soft diagonal terminator of the sun.

## Pass 3
Fixed: blue sky for contrast; exposure calibrated with a grey probe body (albedo 0.5 linear renders at 0.5 in the
mid band: +1.5 stops).
- Faults: (major) the blue sky now tints every slime blue (probe 170,186,234; red 239,70,87, gray 147,167,220):
  in EEVEE the same sky lights the diffuse and the reflections.

# All-round UV (round 5) and the 55 Dual skins

Brief (2026-10-28): replace the front-projection UV (mirrored on the back) by a cylindrical one so patterns wrap all
the way round; mesh, rig, weights and normals unchanged; then 55 two-colour skins generated by script, flat, exact
swatch colours (`src/shared/Colours.luau`), table `docs/DUALS.md`; owner motifs after `slime.dual.NN`.

## Round 5: the UV
`tools/blender/slime_body.ps1 -Round 5`. u = angle (seam at the back centre, front u 0.5, toward the slime's own
left), v = arc length of the ring polyline from the base centre to the tip (L = 1.6105 body heights, contact ring at
v 0.0726); pole loops take their face's u; seam faces unwrapped to u 1. Check: 1,240 faces, all UV-CCW on the body
(all CW on the flipped hull, as its faces), no zero-area face; IoU 0.9842 and 2,400 / 2,400 triangles as round 4
(mesh unchanged). `uv_profile.json`: 256 rows of r(v), z(v) plus the ring table. The painted-highlight overlay is
retired (owner: light comes from the game; it was drawn for the old UV), the preview is plain colour.
Test skin (`tools/skins/make_skins.ps1 -Test`, `review/skins/p1/test_uv_sheet.png`: front, side, back, top, game
cameras): equal discs read round at every height, the disc across the seam shows no seam, grid even, a ring beside
the tip stays a ring.

## Skins pass 1 (`review/skins/p1/`)
All 55 made (signed-distance motifs as tangent-plane decals, Poisson disc by area, analytic antialiasing).
- Faults: low-fill motifs too small (bats, drops, berries, pumpkins, crowns, fish, leaves, bolts, spirals);
  noise fields too coarse (Moo two huge blobs, Camo, Nebula and Cotton Candy unbalanced front vs back); Peach Drip and
  Tangerine zones only on the tip spike (arc from the tip to the shoulders is ~0.6, not 0.3); Tiger read as a
  pumpkin (regular meridian stripes); Tartan navy-dominant (0.56); Lollipop near-horizontal bands (pitch too small);
  Midnight Fade black too high; Marble veins faint (0.125).

## Skins pass 2 (`review/skins/p2/`)
Fixed all of the above (sizes x1.2-1.3, noise frequency x1.6-1.8, drip cap to arc 0.58 with drips down to mid-body,
pitch 0.6 for the lollipop, tartan bands 0.17, fade 0.22-0.72, tiger as tapered strokes from tip and base).
- Faults: Tiger strokes too thin (0.12); Tangerine leaves small; Nebula sparkles invisible at farm size.

## Skins pass 3 (`review/skins/p3/`, copied to `duals_front.png` / `duals_back.png`)
Tiger strokes 0.13-0.21 wide (cover 0.25), Tangerine leaves R 0.25-0.30, Nebula stars fatter and bigger.
Seen front and back: no seam on any design, both colours read on all 55. Still weak: Nebula's stars are small next
to its clouds; Racer, Tangerine and the low-fill motif designs (Batwing, Frostbolt, Goldfish, Berrypatch) cover
under a quarter (0.17-0.22) because their shapes fill little of their circle; Pinstripe and the checks pinch into
the tip (they follow the curvature, by design).
