# Monster slimes: the Dungeon's four regions rebuilt as slimes

The owner, 2026-11-11: the monsters of the Dungeon maps become slime monsters. Their shape stays a slime (a jelly blob
body), but they are not cute: they are menacing. Each region has a few signature monsters and a boss. Claude designs
them; ChatGPT draws the concepts. This file is the plan; the pictures are in `art/concepts/monster_slimes/<map id>/`
(`meadow`, `mushroom`, `lava`, `ice`), one PNG a monster named after it (`burrling.png`).
They are in the game since 2026-11-11 (see "In the game" at the end).

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

The owner, 2026-11-11, after seeing the sheets: the monsters alone, no effects, no surroundings, no text, one picture a
region. `art/concepts/monster_slimes/<region>/group.png` is that: ChatGPT redrew each region's seven together from their
pictures on plain white, without smoke, mist, snow, sparks, motes, trails, breath or floating pieces. No flames either
(the owner, the same day): the Wickling's wick is a molten point, the Scorchdart's and the Calderos's manes are molten
jelly, the Pyrekeeper's brazier holds molten lava, and its floating shards became a ring set into its body.

## In the game

The owner made one 3D file a region from the group pictures and asked, 2026-11-11, for each monster split out, rigged
and moving, then put in the game ("tách riêng từng con ra và gắn xương, gắn chuyển động cho chúng"; no GIFs, he checks
them in the game). Done the same day:

- **Split and rigged** in Blender (`tools/blender/monster_split.ps1`, `monster_rig.ps1` with one rig file a region):
  `art/models/monster_slimes/<region>/<Name>/<Name>.fbx` and its 1024 texture, `rig_<region>.json`,
  `<region>_rigged.blend`, `MOTION.md` (each monster's bones and moves). Every monster has a jelly cage (Body, Top,
  Front, Back, Left, Right) for the slime's squash, stretch and lean, plus bones of its own pieces for most (Stinglob's
  wings and sting, Glimlure's lure and tail, Rimesaw's spinning blade ring, Frostmaw's horns...). Regulars
  up to 3000 triangles, mini-bosses 6000, bosses 8000. Built as tall as they stand in the game: 4.4, 3.6, 4.2, 3.8,
  4.6, 8 and 10 studs by slot (swarmer to boss), drawn bigger by `Config.Dungeon.LookScale`.
- **Moves**: Idle and Move (loops), Attack, Hit and Die (Die holds), each sampled at 30 frames a second into
  `src/shared/MonsterClips/<Name>.luau` (`tools/blender/monster_clips.ps1 <region>`), with `peak` (when the attack lands)
  so the fight times the blow. `shared/MonsterClip` plays them (walk while it moves, one-offs over it, a 0.15 s blend,
  dying outranks all); `client/ClipRig` loads the mesh, makes its bones and moves them. The fight starts Attack so its
  peak meets the hit, Hit on every blow taken, Die when it falls; a healer plays Attack when it mends.
- **Uploaded** by `node tools/kit/upload_monsters.js`: `art/models/monster_slimes/ids.json`, copied into
  `Config.Dungeon.Looks` (`clips`, `mesh`, `texture`, `height`, `shadow`; `turn` for the four whose model came turned
  from the three-quarter picture: Glimlure 57, Scorchdart 30, Bilebloat -20, Blazegullet -15). Their names on screen are
  the new ones. The Egg Heist creatures (`assets/MonsterKit.rbxm`) are no longer in the built game.
- Seen in a Studio play test: all 28 in a line-up (`tools/dungeon/monster_lineup.luau`), and an Ice run to wave 8.
  Known: Wickling's crust dips under the ground when it dies; the bodies melt past a clean puddle on Die; Frostmaw's jaw,
  Blazegullet's lips and Magmaw's jaw move with the body (not cut apart). Not seen: a phone.
- Showroom for the owner: `tools/dungeon/monster_show.luau` (one region at a time on a stage over the farm, names
  over them, the camera held in front, every move in turn).

## Effects on their bodies, and their attacks (the owner, 2026-11-11)

After seeing them move: "some monsters need effects, above all the fire ones: the 3D build dropped every flame, put
them back where they were; poison ones get poison (bubbles, toxic smoke); the others alike, only where needed. Then
design attacks fitting each one, and the bosses a few signature attacks. Look in the effects library first; build what
is missing and add it to the library."

### Body effects (lasting, riding a bone, only where the painting had one)

From each region's `sheet.png` (the pictures before the "no effects" redraw). One effect, `aura.monster_signature`
(`src/shared/VfxLib/Effects/aura/`), with a variant of its own design per monster (named after it, its numbers studs on
an anchor of its `refHeight`); cheap or mid by the library's budget. The game rides each on an invisible anchor kept on
the bone's spot every frame (`Config.Dungeon.Looks[id].fx`, `size` = the variant's `refHeight`), so it follows the hop,
the squash and the attack. Tuned on the showroom's bright grass and sky (the worst case, 2026-11-12): fire is full-colour
flipbooks solid from birth with little light (fully added fire washed out to white), poison and pollen are solid puffs and
glossy bubbles in the painting's neon lime, gold and teal, molten drips glossy drops; the Lava and Mushroom maps are darker.

| Monster | What | Where |
|---|---|---|
| Wickling | a small candle flame flickering on the wick, a few embers | the wick's tip (Wick2) |
| Scorchdart | a flame mane streaming back off its back, longer while it darts | its back (Spine) |
| Blazegullet | two smoke curls rising from its nostrils, now and then an ember | over its snout (Top) |
| Pyrekeeper | a pale golden flame burning in its brazier, sparks rising | the bowl (Brazier) |
| Magmaw | molten drips falling from its teeth, heat embers out of the maw | the mouth (Jaw) |
| Calderos | a roaring mane of fire up and back from its head, embers | the mane (Mane) |
| Bilebloat | toxic green bubbles swelling and popping on its skin, drool from the spout | the body, the spout (Lips) |
| Sporegorge | green toxic mist curling up from its split sacs, spores | the sacs |
| Hexcap | glowing spore orbs floating round its cap | the cap (Cap) |
| Hollowheart | faint teal spores drifting down from the mushrooms in its crown | the crown (Crown) |
| Glimlure | the lure's teal glow (a soft light and motes) | the lure's tip |
| Sapcaller | dandelion seeds drifting off its puff, golden pollen motes | the puff |
| Rotbloom | pollen dust puffing up out of the flower's middle | the flower |
| Rimetusk | frost breath puffing from its mouth | its front (Front) |
| Snowshroud | frost mist curling round its hem, a few flakes | its foot (Body) |
| Frostmaw | snow and wind swirling round its base, flakes | its foot (Body) |

Left without: the ones whose look is all in their body (Burrling, Stinglob, Gapebloom, Barkhide, Gloomtick, Ruingut,
Basaltback, Frostnip, Rimesaw, Shardspire, Icebound) and Bramblehorn.

### Attacks

Every monster keeps its plain blow (its `blow`, and a spitter's `shot`) and gains a special of its own, struck instead of
every few blows like the slimes' skills. A mini-boss has two specials and a boss three, taken in turn. A special's name
is called out over the monster as the slimes' are. Numbers are a first guess the owner tunes by playing (`factor` is a
blow's weight against a plain one; `stun` knocks each one struck off its beat; `slow` slows it for a while; `guard`
takes the blows aimed at team-mates near it; `mend` heals every wounded team-mate).

| Monster | Special(s) | What it does |
|---|---|---|
| Burrling | Burr Roll | rolls through its target: 2 blows x 0.7 |
| Stinglob | Honey Lance | a deep dive-sting: 1 blow x 1.8 |
| Gapebloom | Seed Volley | three seeds: 3 blows x 0.5 |
| Sapcaller | Bloom Mend | every 3rd mending heals every wounded team-mate |
| Barkhide | Bark Wall | guards its team-mates 3 s, defence x 1.3 |
| Gloomtick | Mandible Frenzy | 3 blows x 0.45 |
| Glimlure | Lure Flash | the lure dazzles, then the bite: x 1.5, stun 0.6 s |
| Bilebloat | Acid Splash | x 1.2 on the target, 2 beside it x 0.5, slowed 30% for 2 s |
| Hexcap | Hex Mend | as Bloom Mend |
| Ruingut | Rune Ward | guard, as Bark Wall |
| Wickling | Flare Pop | x 1.0 on the target, 2 beside it x 0.5 |
| Scorchdart | Comet Dash | 2 blows x 0.9 |
| Blazegullet | Fireball | x 1.6 on the target, 2 beside it x 0.6 |
| Pyrekeeper | Pyre Mend | as Bloom Mend |
| Basaltback | Basalt Wall | guard, as Bark Wall |
| Frostnip | Icicle Bite | x 1.4, slowed 40% for 1.5 s |
| Rimesaw | Saw Spin | 3 blows x 0.5 |
| Shardspire | Crystal Burst | x 1.3 on the target, 2 beside it x 0.6, slowed 30% for 2 s |
| Snowshroud | Frost Mend | as Bloom Mend |
| Icebound | Ice Wall | guard, as Bark Wall |
| Rotbloom | Pollen Shockwave; Root Snare | every slime x 0.5, stun 0.6; roots grab its target x 1.6, stun 1 s |
| Sporegorge | Spore Burst; Gorge Bite | every slime x 0.5, stun 0.5; one huge bite x 2.0 |
| Magmaw | Magma Stomp; Molten Chomp | target x 2.6, 3 beside it x 0.75; 2 bites x 1.2 |
| Rimetusk | Tusk Charge; Frost Breath | 2 rams x 1.4; target x 1.0, 3 beside it x 0.6, slowed 40% for 2 s |
| Bramblehorn | Thorn Charge; Bramble Burst; Horn Toss | target x 2, 2 beside x 0.6; thorns shoot out at every slime x 0.6, stun 0.4; hooks one and tosses it x 2.6 |
| Hollowheart | Den Slam; Root Grasp; Heart Pulse | target x 2.4, 3 beside x 0.7; dead roots hold every slime x 0.45, slowed 50% for 3 s; a teal rune wave x 0.7, stun 0.5 |
| Calderos | Eruption; Mane Lash; Meteor Rain | every slime x 0.6, stun 0.6; the fire mane whips its target x 2.0, 3 beside x 0.7; 3 magma rocks on one slime x 0.9 |
| Frostmaw | Blizzard; Glacier Gore; Frost Gale | every slime x 0.65, stun 0.7; the horns x 2.8; the roar's freezing wind, target x 1.2, 3 beside x 0.7, slowed 50% for 2.5 s |

Art: each special has its own look, named by its `variant` in `Config.Dungeon.Fx`: a release in
`skill.monster_special` (on itself, on the target, or rising), and for the bosses' and mini-bosses' specials a wind-up of
the same name in `skill.monster_windup`, played on the monster about 1.2 s before; its blows land as the blow effect's
`skill` variant. One design each, solid pictures first so they read on the bright maps. The plain blows made for the old
animals (2026-11-09) stay where they fit the new monster (Stinglob's sting, Blazegullet's firebolt, Bramblehorn's gore,
Sporegorge's spit, the ice ones...); the rest get blows of their own. The moves are the monster's Attack clip for now;
the bosses' signature specials get clips of their own next.

How they are placed (`client/ZombieFight`, found in the showroom 2026-11-12):
- The wind-up is drawn at the release's scale (`fxScale`, up to `Fx.MaxScale` for a boss); at scale 1 a big monster's
  body hid it.
- A release's box is the body it lands on, standing on the floor: its `ground` pieces lie on the floor and its `body` ones
  at the body's middle. A box of the effect's own size, as tall as a boss, put the rings under the floor.
- Flat rings sit a hair over the floor (`offset` 0.1) and are drawn toward the camera (`zOffset` 0.5); on the floor
  itself, the floor hid them.
- The face's emote part follows the head even while it shows nothing. Left at the world's origin, it stretched the
  model's box, and every effect played on the model came down about 150 studs away.
- `mote_glow` draws a dark square on a bright map; motes use `dot_round`. `embers_fly` is dark-backed too and is worn at
  lightEmission 1. The packs' 4 x 4 explosion is pixelated this big; the library's sharp redraw
  (`explosion_sharp_1..3`) plays instead.
- Ice and frost are a deep ice blue with little light of their own (lightEmission 0.1 to 0.15), never near-white: the
  Ice map's floor (`#ddebf5`) swallowed the pale blues. No light on an ice wind-up (it burnt the white floor to white),
  and no black-backed floor art there (`floor_snow` is added and vanished): Penguin's ring is `ring_crescents`. The
  body effects too: Frostmaw's whirl and snow drift and Rimetusk's breath are ice blue, the drift and Snowshroud's mist
  solid puffs and wisps (thin `smoke_tufts_flip` vanished, full-colour `smoke_frost` read as grey dirt). A body effect
  goes round OUTSIDE the body: Frostmaw's whirls at 5 units were inside its 13-stud body. A `radius` makes a cube as tall
  as it is wide (a ring of smoke round the feet rose to the shoulders): a low ring is a `box` (`lift` below 0 is refused
  on a lasting effect, and a refused piece takes the whole effect, every monster's, away).
- A boss's wind-up starts outside its body (its body hid rings and streams drawn close in), and a big pop on a body is
  raised so the floor does not cut it flat. Measure, do not work it out: a boss's streams play at scale 2.2, but its
  rings and flashes are bursts and the library's burst-area cap shrinks them together, down to half (Frostmaw's rings
  play at about 1.05 to 1.43). The probe is in the showroom: the emitters' sizes and places while frozen.
- `tools/dungeon/monster_show.luau`'s `special(id, key, [freeze at])` plays one special in the showroom, and can freeze
  it for a picture (`thaw()` lets it go on). Freezing stops the library's clock too (`VfxLib.freeze`): with only the
  particles stopped, a wind-up was cleaned up before the picture. The stage takes the map's own floor colour: effects
  judged on a green stage read wrong on the Ice map's white one.
