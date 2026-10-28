# Dual slimes: one design for every colour pair (plan, 2026-10-28)

The owner's direction (2026-10-28): breeding two different colours can give a two-colour (Dual) slime, so
every pair of the 11 base colours needs its own pattern. 11 colours make **55 pairs**; each pair gets exactly
**one** design. This replaces the original's 20 designs on 18 pairs and its fallback pool
(`docs/reference/01-core-farm.md` §5.5).

## Rules for every design

- **Two colours only**: the two parents' swatches from `Colours.luau`. Small details (a flower's heart, a leaf's
  vein) may use a lighter or darker shade of those two, never a third colour.
- **Both colours read at a glance**: the smaller colour covers at least a quarter of the body seen from the front.
- **Which colour is the body** is chosen per design for looks (listed below), not by dominance.
- **All the way round**: the pattern covers front, sides, back and the tip; no seam, no stretching.
- **Nothing painted for light**: the pattern is colour only; highlights and shading come from the game's light on
  the same glossy body as the single colours.
- **The face**: scattered motifs keep a calm oval where the face decal sits (no motif cut in half by the eyes).
- **Size**: a motif is at least about 1/8 of the body's height, so it reads on the farm.
- **The owner's 20 paintings** keep their motif and are moved to the pair whose two colours their painting
  actually shows (the original names often did not match the painted colours). Their colours become the
  pair's two swatches.

## Families (how each is made)

| Family | Designs | Made by |
|---|---|---|
| Scattered motifs | dots, hearts, diamonds, rings, stars, sprinkles, moons, triangles, spirals, flowers, paws, bolts, leaves, bats, ladybug spots, raindrops, crystals, gears, clouds, fireflies, blossoms, snowflakes, berries, pumpkins, crowns, goldfish, daisies, clovers, rosettes | motif shapes from the owner's paintings (20) or from a ChatGPT painting of the new design (35), scattered over the body by script |
| All-over repeats | stripes, chevron, checks, waves, honeycomb, scales, brick, tartan, pinstripe, lace, tiger | script (exact, tileable) |
| Organic fields | cow spots, camo, marble, lava cracks, nebula, cotton candy | script noise, checked against the painting |
| Zones | drip, fade (2), flames, watermelon, racing stripes, leafy cap, lollipop swirl | script by height / angle on the body |

## The 55 pairs

Source: `owner NN` = the owner's painting `slime.dual.NN`; `new` = needs a ChatGPT painting in the owner's style
first (also the collection-book picture).

| # | Pair | Name | Pattern | Body | Pattern colour | Source |
|---|---|---|---|---|---|---|
| 1 | black + gray | Pinstripe | thin vertical stripes | black | gray | new |
| 2 | black + navy | Midnight Fade | fade, navy below to black on top | navy | black | new |
| 3 | black + purple | Batwing | little bats | purple | black | new |
| 4 | black + red | Ladybug | round spots and a black tip | red | black | new |
| 5 | black + orange | Tiger | tiger stripes | orange | black | new |
| 6 | black + yellow | Honeycomb | hexagon outlines | yellow | black | new |
| 7 | black + green | Dragonscale | scale outlines | green | black | new |
| 8 | black + pink | Wild Rosette | leopard rosettes | pink | black | new |
| 9 | black + blue | Neon Swirl | spirals | black | blue | owner 15 |
| 10 | black + white | Moo | cow spots | white | black | owner 08 |
| 11 | gray + navy | Drizzle | raindrops | gray | navy | new |
| 12 | gray + purple | Geode | crystal shards | gray | purple | new |
| 13 | gray + red | Brickwork | bricks | red | gray | new |
| 14 | gray + orange | Lava Crack | glowing cracks | gray | orange | new |
| 15 | gray + yellow | Clockwork | gears | gray | yellow | new |
| 16 | gray + green | Camo | camouflage blobs | green | gray | new |
| 17 | gray + pink | Sprinkle | sprinkles | gray | pink | owner 10 |
| 18 | gray + blue | Overcast | clouds | blue | gray | new |
| 19 | gray + white | Marble | marble veins | white | gray | new |
| 20 | navy + purple | Nebula | nebula swirls and tiny stars | navy | purple | new |
| 21 | navy + red | Tartan | tartan | red | navy | new |
| 22 | navy + orange | Peach Drip | drip from the top | navy | orange | owner 14 |
| 23 | navy + yellow | Firefly | glowing dots | navy | yellow | new |
| 24 | navy + green | Forestpeak | triangles | green | navy | owner 13 |
| 25 | navy + pink | Sakura | cherry blossoms | navy | pink | new |
| 26 | navy + blue | Deepsea | horizontal stripes | navy | blue | owner 04 |
| 27 | navy + white | Snowflake | snowflakes | navy | white | new |
| 28 | purple + red | Berrypatch | berry clusters | purple | red | new |
| 29 | purple + orange | Pumpkin Patch | little pumpkins | purple | orange | new |
| 30 | purple + yellow | Crowned | little crowns | purple | yellow | new |
| 31 | purple + green | Duskmoon | crescent moons and sparkles | purple | green | owner 12 |
| 32 | purple + pink | Royal Diamond | diamonds | pink | purple | owner 06 |
| 33 | purple + blue | Periwinkle | flowers | purple | blue | owner 16 |
| 34 | purple + white | Lavender Stripe | diagonal stripes | purple | white | owner 02 |
| 35 | red + orange | Wildfire | flames rising from the base | red | orange | new |
| 36 | red + yellow | Starburst | stars and dots | red | yellow | owner 09 |
| 37 | red + green | Watermelon | green rind at the base, green seeds | red | green | new |
| 38 | red + pink | Sweetheart | hearts | pink | red | owner 03 |
| 39 | red + blue | Racer | two racing stripes over the top | red | blue | new |
| 40 | red + white | Pawprint | paw prints | red | white | owner 18 |
| 41 | orange + yellow | Ember Chevron | chevron | yellow | orange | owner 05 |
| 42 | orange + green | Tangerine | leafy cap on the tip | orange | green | new |
| 43 | orange + pink | Sunrise Fade | fade, pink below to orange on top | orange | pink | new |
| 44 | orange + blue | Goldfish | little fish | blue | orange | new |
| 45 | orange + white | Creamsicle Check | checks | orange | white | owner 17 |
| 46 | yellow + green | Citrusleaf | leaves | green | yellow | owner 20 |
| 47 | yellow + pink | Lollipop | one swirl from the tip | yellow | pink | new |
| 48 | yellow + blue | Sunwave | waves | blue | yellow | owner 11 |
| 49 | yellow + white | Daisy | daisies | yellow | white | new |
| 50 | green + pink | Clover | four-leaf clovers | pink | green | new |
| 51 | green + blue | Seafoam | rings | blue | green | owner 07 |
| 52 | green + white | Mint Chip | dots | green | white | owner 01 |
| 53 | pink + blue | Cotton Candy | soft swirled clouds | pink | blue | new |
| 54 | pink + white | Lace | lace scallops | pink | white | new |
| 55 | blue + white | Frostbolt | lightning bolts | white | blue | owner 19 |

## What changes in the game

- `DualDesigns.luau`: 55 designs, one exact design per pair; the fallback pool goes (a Dual of A + B is always
  that pair's design). The collection book shows 55 Duals. Odds and pity unchanged.
- The body gets an all-round UV (today's is a front projection, mirrored on the back): the slime body is exported
  once more and the owner imports it again.
- Each design is one 1024 colour map with both colours, on the same glossy body; MeshPart colour white.

## Build order

1. Owner approves this table (names, patterns, which colour is the body).
2. ChatGPT paints the 35 new designs as front views in the owner's style (they are also the book pictures);
   the owner looks at them.
3. New UV, re-import; then the maps in batches of about ten (scripted families first), each batch shown in
   Studio beside its painting.
4. `DualDesigns.luau` and its tests to 55 pairs.
