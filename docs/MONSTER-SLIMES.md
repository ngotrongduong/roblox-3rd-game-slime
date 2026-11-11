# Monster slimes: the Dungeon's four regions rebuilt as slimes

The owner, 2026-11-11: the monsters of the Dungeon maps become slime monsters. Their shape stays a slime (a jelly blob
body), but they are not cute: they are menacing. Each region has a few signature monsters and a boss. Claude designs
them; ChatGPT draws the concepts. This file is the plan; the pictures are in `art/concepts/monster_slimes/<map id>/`
(`meadow`, `mushroom`, `lava`, `ice`), one PNG a monster named after it (`burrling.png`).
3D models and putting them in the game come later.

## The set

Each region keeps the seven places a run already uses (`Config.Dungeon.Maps.<map>.monsters`): five regulars (swarmer,
hunter, spitter, healer, armoured), the mini-boss (wave 5) and the boss (wave 10). So every new monster replaces one of
today's animals one for one, with the same id, role, stats and skill; only the look and the name change. 28 monsters.

Rules every design keeps:
- **A slime first.** A glossy jelly body (the owner's slime: thick dark outline, glassy highlights, colour seen through
  the jelly), no legs, no arms with hands, no animal head. It hops, slides or hovers like a slime. What makes it a
  monster sits ON or IN the jelly: thorns, shells, crystals, horns, a maw, things it swallowed.
- **Menacing, not cute.** Narrow or glowing eyes, teeth, drool, hunched or lunging poses. No blush, no big round
  pupils, no smile. Each face its own: one eye, many eyes, compound eyes, eyes in a crack, eyes under a brim.
- **Own silhouette.** No two share a body shape, in a region or across regions. One shape recoloured is not a design.
- **Region colours.** Meadow: leaf and lime greens, honey, bark brown, flower red. Grove: violet, toxic green, teal glow,
  dark moss. Lava: near-black violet basalt, hot orange, yellow. Ice: white, ice blue, slate, cyan; nothing warm.
- **Buildable later.** One jelly body plus a few hard pieces (the way Secret slimes wear horns and shells, skill
  `slime-wear`), so each can become a low-poly model with the slime's own squash and hop. No ground disc, no rarity
  glow (vetoes 1 and 2 in `docs/reference/04-vfx-animation.md` §14).
- Sizes are the game's: regulars about a slime's size (`Looks.Sizes.normal 3`, armoured 4), mini-boss 7, boss 10.

## Sunny Meadow: thorns, honey, pollen, bark

| Slot (id) | Name | Role in a fight | Silhouette | Signature |
|---|---|---|---|---|
| swarmer (`green_sprout`) | **Burrling** | small, comes in packs, nips | a small ball bristling all over with hooked thorns, a burr | lime jelly, brown bramble hooks, a wide grin of needle teeth, two slanted red eyes |
| hunter (`green_bee`) | **Stinglob** | fast; dives on the weakest slime, its sting slows | a teardrop lying forward, lunging | amber honey jelly with black stripes on its back, a long black stinger at its tail, two buzzing glassy wings, compound eyes, honey drips |
| spitter (`green_dandelion`) | **Gapebloom** | ranged; lobs seeds from afar | a squat pod whose top opens as a flower that is a mouth | green jelly base, red-and-cream petals around a round maw ringed with teeth, seeds in its throat |
| healer (`green_moth`) | **Sapcaller** | mends wounded monsters | a small body under a huge round seed-puff | a dandelion clock as big as itself growing from its tip, glowing pollen motes, hollow pale eyes, a thin crooked smile |
| armoured (`green_snail`) | **Barkhide** | slow wall, high defence | a low dome under overlapping armour plates | pangolin-like bark plates over the jelly, moss tufts, glaring eyes under the front plate, a heavy jaw |
| mini-boss (`green_turtle`) | **Rotbloom** | Pollen Shockwave | a huge squat body with a giant flower erupting from its back | a red spotted corpse-flower blossom, pollen dust, an underslung jaw full of teeth, small furious eyes |
| boss (`green_boar`) | **Bramblehorn** | Thorn Charge | a huge low wedge pushed forward, built to charge | two enormous curved bramble-wood horns, a thicket of thorny brambles on its back, a bramble mane, a heavy brow over glowing amber eyes (keeps the trophy, Bramble Horn) |

## Mushroom Grove: spores, toxins, violet runes

| Slot (id) | Name | Role in a fight | Silhouette | Signature |
|---|---|---|---|---|
| swarmer (`dark_hare`) | **Gloomtick** | small, comes in packs | a flat round tick | a hard violet carapace plate on its back, bone mandibles, a cluster of tiny teal eyes |
| hunter (`dark_bat`) | **Glimlure** | fast; hunts the weakest, its bite weakens | long and low, slithering | dark see-through violet jelly with a line of teal glowing spots, an anglerfish lure on a stalk from its tip, a wide grin of needle teeth |
| spitter (`dark_fox`) | **Bilebloat** | ranged; spits acid globs | a round swollen balloon with a spout | toxic green goo inside a violet membrane, pustules, bubbles leaking, a puckered spout-mouth |
| healer (`dark_deer`) | **Hexcap** | mends wounded monsters | tall, under a very wide brim | a witch-hat mushroom cap with glowing teal runes, spore orbs floating round it, several small eyes glowing under the brim |
| armoured (`dark_totem`) | **Ruingut** | slow wall, high defence | tall, a broken pillar standing out of its top | a mossy ruin pillar and stone slabs swallowed into the jelly as armour, roots binding them, teal rune cracks, eyes between slabs |
| mini-boss (`dark_wyrm`) | **Sporegorge** | Spore Burst | a big lumpy mass of sacs on top | puffball spore sacs bulging from its back, some split and leaking green mist, a gaping maw, many small eyes |
| boss (`dark_bear`) | **Hollowheart** | Den Slam (leaps and lands) | a towering body under a crown of dead branches | an antler-like crown of dead black branches hung with glowing mushrooms, a teal rune heart seen inside the dark violet jelly, a huge underbite maw |

## Ember Lava: magma, basalt, flame

| Slot (id) | Name | Role in a fight | Silhouette | Signature |
|---|---|---|---|---|
| swarmer (`lava_newt`) | **Wickling** | small, comes in packs | a small drop with a flame on its tip like a candle | molten orange-yellow jelly, a cracked black crust cap, a flame burning from its tip, molten drips, a jagged little mouth |
| hunter (`lava_wolf`) | **Scorchdart** | fast; hunts the weakest | a sleek comet lying forward | streamlined molten jelly, a swept-back flame mane trailing, a row of obsidian blade fins down its back, slit eyes |
| spitter (`lava_phoenix`) | **Blazegullet** | ranged; spits fireballs | round, with a swollen throat sac | a glowing see-through throat pouch full of fire, wide flat lips, charcoal speckled jelly, smoke from its nostrils |
| healer (`lava_drake`) | **Pyrekeeper** | mends wounded monsters | a hovering body inside a ring of floating shards | a brazier bowl set in its top burning with a pale golden flame, a ring of obsidian shards orbiting it, hollow ember eyes |
| armoured (`lava_tortoise`) | **Basaltback** | slow wall, high defence | a low body under a little fortress of stone columns | a cluster of tall hexagonal basalt columns of different heights on its back, glowing orange seams between them, small glaring eyes under the front columns, a heavy jaw (not crust plates: the Wickling wears those) |
| mini-boss (`lava_bull`) | **Magmaw** | Magma Stomp | wide, most of it a mouth | a cavernous molten mouth across half its body, jagged obsidian teeth, magma drooling, two basalt shoulder spikes |
| boss (`lava_golem`) | **Calderos** | Eruption (fire straight up) | a colossal body under a blazing mane | its face covered by a cracked black obsidian war-mask with white-hot eye slits and a fanged grille, a wild mane of fire roaring up and back from its head, magma pouring down its sides from under the mask, obsidian plates on its flanks (a crater on top and a row of chimneys were both dropped: the Wickling and the Basaltback already carry them) |

## Frozen Ice: frost, snow, crystal

| Slot (id) | Name | Role in a fight | Silhouette | Signature |
|---|---|---|---|---|
| swarmer (`ice_fox`) | **Frostnip** | small, comes in packs | a small blob with icicles hanging from its grin | pale ice-blue frosted jelly, a snow cap on its tip, icicle teeth, frost fuzz |
| hunter (`ice_leopard`) | **Rimesaw** | fast; hunts the weakest | a flat disc gliding on the ice | a ring of sharp ice blades round its rim like a saw, one cold eye on top, frost trails |
| spitter (`ice_wisp`) | **Shardspire** | ranged; fires ice shards | tall, crowned by a crystal cluster | pointed ice crystals growing out of its head, deep blue core, a slit mouth, shard chips around |
| healer (`ice_penguin`) | **Snowshroud** | mends wounded monsters | a tall hooded shape | a heavy snow-white fur hood and mantle over the jelly, one glowing blue eye in the hood's dark, frost mist curling |
| armoured (`ice_golem`) | **Icebound** | slow wall, high defence | a square block | a slime frozen inside a thick cracked block of ice, its glaring face pressed inside, snow piled on top, ice spikes at the corners |
| mini-boss (`ice_mammoth`) | **Rimetusk** | Tusk Charge (two rams) | a big shaggy hump with tusks in front | two huge curved ice tusks, a shaggy snow mane on its back, small mean eyes, frost breath |
| boss (`ice_yeti`) | **Frostmaw** | Blizzard | a colossal body with two back-swept horns, roaring | deep navy and slate see-through jelly (dark, so it reads on the white ice floor, where the white Yeti did not), a blizzard vortex swirling inside it, two smooth horns of layered glacier ice, hollow white-burning eyes, its jaw split wide in a roar pouring out a freezing gale, a snow tornado round its base (no fur, crystal crown or icicle grin: the others have those) |

## The pictures

Drawn by ChatGPT (image generator, thinking effort High) with the owner's paintings as the style lock: the World Boss
`enemy-goo-king.png` (how menacing a slime of this game looks), `slime.base.green.png` (the body) and two Secret slimes
`slime.secret.black-red.png`, `slime.secret.gray-red.png` (worn pieces on the jelly). Flat magenta `#FF00FF`
background, no text, one monster a picture, a three-quarter front view, "with the image generator, not code"; keyed and
trimmed with `tools/chatgpt/prepare_icons.py`'s `key_out`. The flood key walks through violet outlines and ate the Grove's
violet bodies, so the Grove and Lava pictures were keyed stricter (the flood only crosses near-pure magenta), and the
Ice pictures and the see-through Meadow ones (Stinglob's wings, Sapcaller's puff) had leftover magenta unmixed (the
`unmix_magenta.py` rule of skill `chatgpt-art`). Redrawn after review: Rotbloom (its first flower was a toothed mouth
like the Gapebloom's), Bramblehorn (its face was the Barkhide's) and Calderos twice (a crater, then chimneys: the
Wickling's and the Basaltback's). One contact sheet per region: `art/concepts/monster_slimes/<region>/sheet.png`.
