# Skill and weapon effects: what the library has, what it lacks, how to build the rest

Written 2026-11-12 at the owner's request: "find the matching skills in our library; where none fits, list them and
propose how they should look; redo the weapon effects so each tier stands out more and each kind has its own".
The library is `C:\roblox-vfx-library` (`CATALOG.md`); the game plays its effects through `View.Skill.Looks`
(`src/shared/ConfigZombies.luau`) and `client/ZombieFight`.

## 1. In the game now (2026-11-12)

| Skill | Library effect | How it plays |
|---|---|---|
| Dash Strike (Warrior) | `skill.flash_step` | From the aim: a white streak along the dash, the cuts hang on the foe and open as the blow lands (its `impact` marker, 0.56 s). |
| Piercing Shot (Ranger) | `skill.piercing_arrow` | The arrow leaves the bow and flies through every foe on its line to the farthest (the owner, 2026-11-13): each takes its blow as the arrow passes (the landing time by its distance, not before `PierceEarliest` of it) and wears the hit mark. |
| Mend (Healer) | `skill.blessing_light` | A ray of light falls from the sky on the one mended; the number shows as it reaches them (0.25 s). |
| Arcane Barrage (Mage) | `burst.ether_burst` on each foe | The focus still fires the owner's orbs; each bursts in the library's Ether Burst where it lands. |

The level follows the caster's weapon tier (`View.Skill.Levels`: Common and Uncommon `lv1`, Epic `lv2`, Mythic and
Legendary `lv3`) and so does the size (`TierScale`, 1 to 1.35). Flash Step: lv1 one cut, lv2 an X, lv3 an X and a level
cut; Piercing Arrow: lv1 the arrow, lv2 it flies on, lv3 speed lines and a cone of air.

Seen in Studio (`review/skill-*.jpg`, Frozen Ice): every one plays in a real run with no error. **On the snow the
library's white additive light nearly vanishes** (Flash Step's steel crescents above all). The four other maps are
darker; the snow needs a bright-map look in the library (`blend = "normal+bloom"` or a dark rim), see §4.

## 2. The 24 class skills against the library

Taken by a dungeon monster (one design a creature, never shared): `skill.ice_spear` and `skill.frost_charge` (Tusk
Mammoth), `skill.meteor_charge` (Lavastomp Bull), `skill.renewal_charge` (Bloomshell), `skill.leap_slam`,
`skill.blizzard`, `skill.phoenix_charge`, `skill.void_charge`.

| Class | Tier | Skill | Library | Wind-up |
|---|---|---|---|---|
| Guardian | Common | Taunt | **none** (stand-in: the owner's shockwave and rings) | - |
| Guardian | Uncommon | Shield Bash | **none** | - |
| Guardian | Epic | Shield Wall | **none** (`burst.shield_up` is only an icon bubble) | - |
| Guardian | Mythic | Bulwark | `skill.spirit_guardian` (a knight of light rises behind and raises his shield; lv2 a wall of runes) | `skill.summon_call` |
| Warrior | Common | Dash Strike | `skill.flash_step` (in) | `skill.battle_focus` |
| Warrior | Uncommon | Area Slash | `skill.great_cleave` | `skill.battle_focus` |
| Warrior | Epic | Breaker Strike | `skill.cross_cut` + `hit.shield_shatter` on the foe (its armour breaks) | `skill.battle_focus` |
| Warrior | Mythic | Whirlwind | `skill.whirlwind_slash` (lv3: three turns and a ring cut) | `skill.battle_focus` |
| Ranger | Common | Piercing Shot | `skill.piercing_arrow` (in) | `skill.draw_aim` |
| Ranger | Uncommon | Arrow Volley | `skill.fan_shot` (a fan of arrows at the group) | `skill.draw_aim` |
| Ranger | Epic | Snare Arrow | `skill.arrow_ring` (a fence of arrows closes on the foe) | `skill.draw_aim` |
| Ranger | Mythic | Arrow Rain | `skill.arrow_volley` (a rain of 15 arrows); its 1.2 s ground warning is **missing** | `skill.draw_aim` |
| Mage | Common | Arcane Barrage | **partly**: `burst.ether_burst` hits; the barrage itself (a volley of arcane missiles) is **missing** | - |
| Mage | Uncommon | Frost Burst | **none** (Ice Spear and Blizzard belong to the Mammoth and the Yeti) | - |
| Mage | Epic | Arcane Lance | `skill.arcane_ray` (a magic circle and a big pink-violet beam) | `skill.arcane_charge` |
| Mage | Mythic | Meteor | `skill.meteor_fall` (red warning circle, a burning rock from the sky) | **missing** (Meteor Charge is the Bull's) |
| Healer | Common | Mend | `skill.blessing_light` (in) | `skill.blessing_charge` |
| Healer | Uncommon | Healing Ring | `skill.renewal_rain` (a rain of light heals the group) | **missing** (Renewal Charge is Bloomshell's) |
| Healer | Epic | Ward | **none** (the owner: a Ward reads as a bubble) | - |
| Healer | Mythic | Sanctuary | `skill.healing_sanctuary` (the leaf-and-flower circle) | `skill.sanctuary_charge` |
| Alchemist | Common | Acid Rain | **none** (stand-in: the owner's flasks and acid rings) | - |
| Alchemist | Uncommon | Squad Tonic | **none** | - |
| Alchemist | Epic | Cursed Flask | **none** | - |
| Alchemist | Mythic | Catalyst Cloud | **none** | - |

Class skills wind up for only 0.3 s today (the server's aim); the library's wind-ups hold about 1.1 s, so they wait for
the skills of steps 4-5 that have long wind-ups (Whirlwind 0.8 s, Arrow Rain 1.2 s, Meteor 1.5 s).

## 3. Missing: what to build, and how it should look

Fourteen pieces. Each is its own design (no recolour of another), from art (ChatGPT or EffectCraft pictures, the
owner's battle art where it fits), within the phone budgets, and it must read from 25-45 studs behind the squad on
every map, the snow too. Colours follow the class's own weapons (§5).

**Guardian (all four tiers lack a look: the most urgent set).** One motif for the class: a golden shield emblem
(the crest on the Warden Shield) and blue-white light.
1. **Taunt**: the Guardian slams its shield on the ground; a golden shield emblem flashes over it and a ring of blue
   and gold light pulses out over the ground (thick, slow, seen from far). Every foe pulled gets a red-orange "!"
   flash over its head and a thin gold chain of light that snaps from the foe to the Guardian and fades: the turn of
   the head says who it now fights. While Taunt lasts, a faint gold rim turns under the Guardian's feet.
2. **Shield Bash**: a short shield-shaped shockwave (a flat crest of light) bursts from the shield into the foe, stone
   chips and a ring of dust; the stun shows as three small gold stars circling the foe's head for 0.5 s.
3. **Shield Wall**: translucent blue hexagon panels of light rise like a wall in front of each protected team-mate
   (two or three panels, gold edges), shimmering while the 3.5 s last, cracking into shards at the end.
4. **Bulwark** (wind-up for the library's Spirit Guardian): a gold circle with the shield emblem opens under the
   Guardian before the knight rises.

**Mage.**
5. **Arcane Barrage**: three to five small arcane missiles (violet-blue bolts with a white core and a short ribbon
   tail) leave the focus one after another on curving paths, each hitting a foe in a small rune burst; at lv3 a rune
   circle stands before the focus while it fires.
6. **Frost Burst**: a frost rune flashes on the ground under the foe, then ice shards burst up and outward in a star,
   frost mist rolls over the area and every slowed foe keeps a light coat of rime (white-blue frost on its skin) for the
   2.5 s. Not a spear and not a blizzard: those are the Mammoth's and the Yeti's.
7. **Meteor's wind-up**: the focus is raised and a small swirl of stars opens over the Mage (violet, not the Bull's
   orange sky window), stars streaming up into it.

**Healer.**
8. **Ward**: a round bubble of soft green-gold light closes over the team-mate (a leaf pattern faintly on its skin),
   with a slow shimmer while it holds; when it breaks or ends it pops into petals.
9. **Healing Ring's wind-up**: leaves and petals swirl up round the Healer and the staff's flower glows (its own, not
   Bloomshell's rain run backwards).

**Alchemist (all four tiers lack a look).** One motif: glass flasks, bubbling liquid and alchemy circles, in the
kit's purple, teal and gold.
10. **Acid Rain**: the Alchemist flings two or three green flasks up; they spin through the air, shatter over the
    foes with glass shards, and a green acid splash spreads on the ground with bubbles; each foe hit drips green and
    its armour fizzes (small smoke puffs) for the 4 s of melt.
11. **Squad Tonic**: a gold-orange potion bottle pops its cork over the Alchemist; a spray of orange sparkles falls on
    each team-mate, who glows with a rising orange "power" swirl and a small sword icon (the owner's attack buff art,
    `buff.stat_set`) for the 4 s.
12. **Cursed Flask**: a dark purple flask with a skull label hits the foe and bursts into purple smoke; a broken purple
    heart sign hangs over the foe and its heals show purple and smaller while the 5 s last.
13. **Catalyst Cloud**: an alchemy circle (gold runes, a triangle in a circle) draws itself on the ground under the
    foes, then a big swirling cloud of green-purple gas rises from it with bubbles and sparks; the armour melt shows
    as the foes dripping and fizzing, as Acid Rain's.

**Ranger.** 14. **Arrow Rain's warning**: a wide ring of arrow marks on the ground, red-orange, filling in for 1.2 s
before the library's rain falls (the volley's own art stays).

## 4. Weapon effects: redone so every tier stands out and every weapon has its own

What the owner saw: the trails, cast bursts and auras of step 3 (`trail.weapon_<family>`, `burst.weapon_cast_<family>`,
`aura.weapon_<family>`, the tier as the variant) are too faint and too alike. The new rule:

- **Every one of the 30 weapons has its own look**, read from its model (§5): its own colours, its own material (wood
  chips, steel sparks, runes, petals, stars, bubbles...), its own shapes. Two weapons never share a design recoloured.
- **The ladder is obvious from across the fight.** Each tier up adds a whole layer, not a brighter copy:
  - Common (wood): a clean short swing streak in the weapon's own colour and a little dust or chips on the hit.
  - Uncommon (iron): a longer, sharper streak with a hard white edge; sparks on the hit.
  - Epic: a coloured ribbon of the weapon's element and its particles (runes, frost, prism glints...); a soft idle
    glow of its gem while in hand; a cast burst with a small ground ring.
  - Mythic: a double ribbon, larger element particles that linger, a point light on the head, an idle aura with its
    element orbiting the weapon; a big cast burst with a ground ring and a flash.
  - Legendary: the grandest: a wide ribbon with a bright core, a burst of its element on every swing, the idle aura
    (its gems shimmering, a halo or crown of its motif over the weapon), a light, and a cast burst that marks the
    ground under the slime; seen and recognised from the far side of the fight.
- **Seen from the gameplay camera**: 25-45 studs behind the squad, the weapon about 2 studs long. Effects are sized for
  that distance (a ribbon wider than the blade, particles of at least half a stud), held long enough to be seen (a
  trail 0.3-0.5 s, a burst 0.6-1 s).
- **Every map, the snow too**: solid art (keyed, `normal` blend with bloom) for the main shapes, additive light only as
  a highlight on top; a dark or coloured rim so white steel reads on white snow.
- **Phone budget**: a squad of four Legendary weapons at once stays within the library's budgets; the idle aura is
  the cheapest layer (it is on all the time).

The 18 held auras (6 families x Epic, Mythic, Legendary) are ChatGPT clips fixed ON the weapon in 3D since the
library's b25782a (7c09514 first): the clip is a SurfaceGui card on one thin part through the weapon's middle, so it
turns and tilts with the weapon and never faces the camera, with two small mote emitters round it (and a small light
at bramble and legend). The host is the weapon's MeshPart, its thin side on local Z (all six meshes are). Sunfire
(`sword-legend`) has no card: its three gems glow, two flame strands wind up the blade (20 Beams), sparks hang in the
air and faint rainbow rays sit behind it. Seen in Play: an Arena fight with the late team, and a Sunfire sword up close,
whose gem glows sit on our mesh's gems (guard -0.37, pommel -1.34, blade 0.34 studs on the weapon's Y); no error.

## 5. The 30 weapons, their looks and a theme each

| Family | Common (wood) | Uncommon (iron) | Epic | Mythic | Legendary |
|---|---|---|---|---|---|
| Sword | Wooden Sword: brown wood | Iron Sword: grey steel | Runeblade: purple blade, lilac diamond runes, gold guard: **arcane runes** | Dawnbreaker: white and gold blade, pink-red gem, winged guard: **dawn light, sun rays and feathers** | Sunfire Blade: red and white blade, gold sun guard, red gems: **sunfire, crimson flame and gold embers** |
| Shield | Wooden Shield: planks | Iron Shield: wood and steel rim | Warden Shield: blue, steel, gold winged crest: **blue-gold crest of light** | Aegis of Goo: stone, gold, green vines, a green goo face: **goo drops and vines** | Royal Bastion: castle towers, blue banners, green goo gem, laurels: **royal gold, banners, a crown** |
| Bow | Wooden Bow | Iron Bow: steel caps | Windwhisper Bow: white with blue feathered tips: **wind and feathers** | Starfall Bow: violet and gold, star gems: **falling stars** | Moonsong Bow: white, blue, gold crescent moon and star: **moonlight, crescents and silver notes** |
| Arcane Focus | Arcane Focus: wood, blue orb | Iron-bound Focus: steel bands, blue orb | Prism Focus: gold spikes, pink-blue orb: **prism glints, rainbow shards** | Mythic Focus: vines and a violet orb: **violet arcane with leaves** | Astral Scepter: gold and white horns, a pink-blue gem: **galaxy, nebula and stars** |
| Healing Staff | Healing Staff: wood, white crystal, leaves | Iron-shod Staff: steel, blue crystal | Enchanted Staff: gold, purple crystal, ribbons: **purple sparkles and ribbons** | Lifebloom Staff: gold, white flowers, teal crystal, vines: **blossoms and petals** | Everbloom Staff: a white lily, a green gem, vines: **golden leaves and a blooming lily** |
| Alchemy Kit | Alchemy Kit: brown satchel, red and blue flasks | Iron Kit: steel straps | Alchemist's Satchel: purple, a scroll: **purple fizz and bubbles** | Philosopher's Kit: teal and gold, a green gem, books: **transmutation circle and green glow** | Grand Elixir Pack: purple and gold, violet potions: **rainbow elixir bubbles** |

The pictures: `art/models/weapons/review/<family>_front.png` and `legendary_front.png` in the game folder (renders of
the owner's models; on disk, not in git).

## 6. Effects that last: every fighter under one shows it (2026-11-13)

The owner: a buff or a debuff shows its own look on EVERY fighter it is on, for as long as it lasts (a heal over time, a
poison). The fight sends a `status` event each time one is put on or renewed (`Combat.luau`: who, on whom, what, how
long, which skill); `client/ZombieFight` puts the look on the fighter's body (welded, so it follows every hop), keeps it
while renewed, and takes it off when it runs out, when the fighter falls or when the fight ends. The looks are
`View.Status.Looks` (`ConfigZombies.luau`).

| Status | From | Look | Seen |
|---|---|---|---|
| taunted | Taunt, on every foe pulled (off when the Guardian falls) | `buff.emote` "angry": a red anger mark over the head | yes, Frozen Ice |
| shielded | Taunt, on the Guardian | `buff.stat_set` "defence": shields circling it, finer with its shield's tier | yes |
| guarded | Bark Wall and other guards | `buff.stat_set` "defence" | yes |
| stunned | stuns (Bramble Burst, Shield Bash, bosses), as long as the stun really lasts | `buff.emote` "confused" over the head | placement only |
| melted | Acid Rain, on every foe struck | `buff.acid_melt`: acid runs and popping bubbles on the body | yes, on the real slime mesh |
| slowed | stings and the monsters' slowing specials (acid, roots, frost) | `buff.slowed`, variants `sting`, `acid`, `roots`, `frost` by skill: round the foot | yes, on the real slime mesh |

Both came from the library on 2026-11-13. The first cut (e2037cf) hid the slime under `sting`'s honey cage and
`frost`'s flat wall: its ring was emitted round the slime's head. The library's 1da91f8 lays every slow on a flat ring
on the ground just outside the body, all six pictures ChatGPT clips: honey strands to a puddle, a low crust of frost
shards, sludge heaps, roots to 2.2 studs. Seen again on the game's slime mesh from close by: the slime stays clear.

## 7. The slimes' side raised to the monsters' level (2026-11-14, wave 1)

From the audit of 2026-11-14 (`docs/STATUS.md`). All of it is data in `Config.Zombies.View`; `client/ZombieFight` plays it.

| Moment | Look | Where |
|---|---|---|
| A slime aims a skill | its body glows in its way's colour, rising through the aim | `Skill.Power.Glow`, `GlowMost` |
| The skill lets go | the glow flashes white and fades | `letGo` |
| A crit or a heavy skill blow lands | hit-stop 0.13 s, a white flash on the one struck | `View.Hard` |
| A crit, by class | Warrior `hit.blade_cross`, Guardian `hit.comic_punch`, Ranger `hit.side_gust`, Mage `hit.shard_nova`, Healer `hit.holy` crit, Alchemist `burst.stylized_blast`, sized by the weapon's tier | `Fx.CritLooks` |
| Goo Slam lands | `burst.cghow_dust_shockwave` on the floor | `Skill.Looks.attack.lib` |
| Belly Bounce lands | `burst.prism_pop` on the floor | `Skill.Looks.hp.lib` |
| Taunt | `burst.shield_up` round the Guardian | `Skill.Looks.taunt.lib` |
| Acid Rain, each foe struck | `hit.acid_splat` | `Skill.Looks.acid_rain.hitVfx` |
| A slime falls | `burst.smoke_poof` | `FallVfx` |
| The winners cheer | `burst.reward_glitter` | `CheerVfx` |
| A big monster falls | `skill.monster_impact` in its element | `Dungeon.Fx.FallImpactSize` |

A floor effect is played at the body's middle with a `size` box, so its ground pieces lie on the floor (`onFloor`).
Taunt and Acid Rain are still stand-ins from the library's general shelf: their own designs stay on the list of §3.
Seen on a test row and in a real run on Frozen Ice; white hits read pale on the snow (§1), the weapon impact ladder
of wave 2 is drawn with colour and dark edges for that.
