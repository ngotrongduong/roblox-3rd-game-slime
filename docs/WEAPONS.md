# Weapons, classes and skills

The owner (2026-11-12): slimes hold and swing real weapons, in many forms and rarities; the weapon gives the slime its
class, the class's skills and the class's own way of fighting (AI); a lower rarity has fewer skills; bows and staffs fight
from range; the tank gathers the monsters and taunts them onto itself, the healer heals, archers and mages dodge and keep
their distance while they move and attack, warriors close in; and a few support and counter classes so the whole is "as
balanced an ecosystem as possible". He asked for it to be argued out with ChatGPT until it is complete and balanced: three
rounds in the chat "Combat System Review" (§12 keeps what each side said and what was taken).

The starting point is his own web game: its six weapon families, their AI and his art at every tier
(`docs/reference/02-battle.md` §9, §14 and "Weapon moves"; `reference/goo-lineage-web/assets/equip-*.png`).

Every number here is a starting value for `Config.Classes` (a new block file, `src/shared/ConfigClasses.luau`); the
headless simulator (§10) settles them before they ship, and the owner tunes by playing.

## 1. Decisions

| Question | Decision |
|---|---|
| Classes | Six, one a weapon family: **Guardian** (Shield), **Warrior** (Sword), **Ranger** (Bow), **Mage** (Arcane Focus), **Healer** (Healing Staff), **Alchemist** (Alchemy Kit). A slime with no weapon stays a **Brawler** (today's role from its strongest stat, with today's four skills). |
| Rogue, Bard | Not at launch. Rogue comes only if the protected-backline test (§10) fails; Bard's job (team buff) is the Alchemist's Tonic. |
| Rarity and skills | Common: the full class AI + its signature skill. Uncommon: + a 2nd skill. Epic: + a 3rd skill. Mythic: + the ultimate. Legendary: + its trait (§3.7). The skill that IS the class's job is always the signature, so a Common weapon is simple, never broken. |
| Legendary (the owner, 2026-11-12) | A fifth rarity above Mythic, weapons only (Head and Charm stop at Mythic), from the owner's own 3D set: one weapon of each family (§4). |
| Rarity and power | A tier up is a stronger team, as a higher level is: at the same slime stats it wins nearly always. What is held is the edge at the same Arena power (the matching counts gear points): measured in §13, about 55-62% a tier up from Common, 75-85% for Mythic, 80-90% for Legendary, since the owner's weapon points sit in the stat the class uses. A well-built Common team still beats a badly built Mythic or Legendary one. (Was "Mythic over Common 60-65% at the same stats": the sim's fights between equal slimes are too even for any stat gap to give that.) |
| Getting weapons | Crafted on purpose at the Smithy from dungeon and camp drops (the tiers wood, iron, core, bramble, legend = Common, Uncommon, Epic, Mythic, Legendary). Never Robux, never a lottery, no mastery system on top. |
| Skills | On cooldowns in seconds. A skill takes the place of the next plain blow: more skills give more choices, not free extra hits. |
| Ultimate | No energy bar. First ready 12 s into a fight or wave, then every 24 s; two ultimates of one team start at least 1.5 s apart. Its build-up shows as a charge effect on the slime (art), never a bar. |
| Team settings | The formation comes from the weapons (rings, §6), with a front / middle / back choice per slime; one of three tactics: Balanced, Focus Fire, Protect Backline. |
| Dungeon | One team a run (the owner, 2026-11-10: `Config.Dungeon.RunTeams = 1`). Support skills touch their own team only. |
| Visuals | One weapon at the hand anchor on one side, the tail item on the other, both swapping with facing; the sword swings in a big arc, the staff rises on a cast; every weapon its own projectile and hit art. The owner (2026-11-12): the higher the rarity, the more and finer effects a weapon carries and the better it moves (§9); this lifts the original's "no glow in the world" for weapons, but the effects are crafted from art, never a plain glow or aura (what that veto was against). |

## 2. Shared rules (every class)

- **Time.** The fight keeps its fixed 0.1 s step (`Config.Zombies.FightStepSeconds`, one step for dungeon, camps and arena).
  A slime decides every 0.3 s and at once on an urgent event. Blows landing on the same step are all dealt before anyone
  falls. HP stays fractional. Cosmetic randomness uses its own stream, never the fight's. A beat keeps its fraction from
  step to step (a 0.25 s beat lands 0.2, 0.3, 0.2, ... apart, not always 0.3), and reach is checked along the whole move
  of a step (a monster at 32 studs/s crosses 3.2 a step).
- **Beat.** Today's beat, `Combat.cooldown(speed)` (1 / (1 + 0.04 x SPD) s, floor 0.25 s), times the class's ratio (§3).
- **Damage.** Physical as today: `ATK x factor x 0.3 x (1 - min(0.75, DEF / (DEF + 50)))`. Magic counts the target's DEF
  as 65% of it. Heals and barriers weigh what the healer's own blow would take off a slime as strong as itself: the same
  formula with its ATK as the DEF (`ATK x factor x 0.3 x (1 - min(0.75, ATK / (ATK + 50)))`), so heals keep pace with blows
  at every level (with no armour at all, a heal at level 60 was a third stronger than the blows it answered, at level 200
  twice; balance pass, 2026-11-12).
- **Speed.** It keeps the beat and the walk. Crit no longer grows with it: a flat 10% crit at x1.6 on plain damaging blows
  only (a big hit is fun to see; never a skill, never a heal). Dodge stays only against plain basic blows (never a skill, a
  monster's special, an area, a telegraphed blow or poison): 0.5% per SPD, cap 20%. (SPD 20 dodges 10% of plain blows,
  about 6% of all damage; the beat is then 1.73x as fast, while ATK 20 hits 20x as hard: speed stays useful, not best.)
- **Skills.** A skill's cooldown starts when it is cast. It is used only when it is worth it (a heal that would mostly be
  wasted, a Tonic with no one to buff, an area with no one in it: never).
- **Areas.** Every area skill names its cap and its smaller share on the ones beside the target.
- **Effects.** Slows: the strongest only, at most 35% (a boss 15%). Damage taken lowered: at most 40% in all. Damage dealt
  raised: at most +25% in all. Armour melt, anti-heal, Tonic and barriers: the strongest of a kind only, never added up.
- **Stuns.** Each target counts the stuns that land on it in the last 10 s: full, half, a quarter, then none. Bosses
  cannot be stunned; a mini-boss at most 0.3 s, then 6 s free. Slimes obey the same count (the bosses' all-slime stuns).
- **Taunt.** A taunted monster must target the Guardian; it is never pulled or moved, it walks there itself (that walk is
  the gathering), and a ranged one shoots from where it stands. At most 3 a taunt; a monster freed from a taunt cannot be
  taunted again for 2 s, so two Guardians cannot chain it.
- **Threat.** A monster that picks freely weighs its threat on each slime: damage x1 (a Guardian's x2), healing x0.6,
  6% decay a second, +25 for one near and reachable. Its own kind still decides (a raider hunts the weakest).
- **Keeping a target.** The current target gets +12 (of 100) and is kept at least 1 s, unless it falls, can no longer be
  reached, or something urgent happens.
- **Ranged movement.** A ranged slime shoots while it moves at 80% of its walk (monsters already walk twice as fast, so
  this is a small trade, not the brake); it stops backing away after 2.5 s for 0.6 s; a telegraphed blow overrides both.
  A melee monster's blow commits it for 0.3-0.5 s (wind-up and recovery) in which it cannot chase at full speed: that is
  the window a hop buys.
- **Order of what matters** (a score, not a fixed list): escape a deadly telegraph if escape is possible; save a team-mate
  about to fall; the class's own job (intercept, heal, protect, keep distance); a strong skill; a plain blow or a step.

## 3. The classes

Distances in studs: slimes are about 3 wide and keep 3.5 apart; melee reach is 6 (`Config.Dungeon.Move.MeleeStuds`),
the bow's 16 (`RangedStuds`). Monsters walk twice as fast as a slime of the same SPD, so a slime never out-walks one: a
ranged slime keeps its distance by its hop.

| Class | Weapon | Plain blow | Beat ratio | Reach | Stays at | Ring |
|---|---|---|---|---|---|---|
| Guardian | Shield | 0.8 physical | 1.1 | 6 | in melee, near the one it protects | front |
| Warrior | Sword | 1.05 physical | 1.0 | 6 | in melee | front or middle |
| Ranger | Bow | 1.05 physical | 1.0 | 16 | 11-14 | middle |
| Mage | Arcane Focus | 0.9 magic | 1.0 | 16 | 10-13 | middle |
| Healer | Healing Staff | a heal of 0.9 on the most hurt below 90%; else a 0.65 magic bolt | 1.15 | 15 | 9-12 | back |
| Alchemist | Alchemy Kit | 0.9 magic flask | 1.0 | 14 | 10-12 | back |
| Brawler | none | today's | 1.0 | 6 | in melee | front |

(The balance pass of 2026-11-12 set these: with the first numbers a slime with a weapon fought worse than one without,
since a Brawler's skill comes every 4-5 blows and a class's only every 8-10 s. §13.)

### 3.1 Guardian (Shield): gather, protect, last

Passive **Shield** (every tier): it always takes 20% less damage; its Taunt raises that to 35% while it lasts (the
strongest only, §2). Passive **Intercept** (every tier): once every 8 s, a direct blow at a protected team-mate within 9
studs is 70% taken by the Guardian instead. Areas are not intercepted.

| Tier | Skill | What it does | Cooldown |
|---|---|---|---|
| Common | **Taunt** | Up to 3 foes attacking within 18 must attack the Guardian for 4 s; it takes 35% less damage meanwhile. | 8 s |
| Uncommon | **Shield Bash** | 1.15 physical, stun 0.5 s. | 11 s |
| Epic | **Shield Wall** | Up to 2 team-mates within 16 take 15% less damage for 3.5 s. | 17 s |
| Mythic | **Bulwark** (ultimate) | The whole team takes 18% less damage for 4 s; new stuns on it last 25% less. | 12 s, then 24 s |

AI: keeps its target until it falls; then a foe going for a squishy team-mate (bow, focus, staff, kit), else the
nearest. Stays within 16 of the team-mate it protects (the original's leash). Taunts when 2+ foes hit team-mates or a
raider reaches a back-row slime; Bash on a foe hurting a team-mate; Wall before a big hit lands on two of them.

### 3.2 Warrior (Sword): close in, hit hard

| Tier | Skill | What it does | Cooldown |
|---|---|---|---|
| Common | **Dash Strike** | Rushes up to 18 at a foe 7-18 away along a free path, 1.5 physical. | 6 s |
| Uncommon | **Area Slash** | 1.2 on the target, 0.55 on up to 2 others within 7 (cap 3). | 8 s |
| Epic | **Breaker Strike** | 1.45 physical, ignores 20% of its DEF. | 12 s |
| Mythic | **Whirlwind** (ultimate) | 0.8 s wind-up, 1.6 on the target, 0.7 on up to 3 others within 9 (cap 4). | 12 s, then 24 s |

AI: walks into reach of the most dangerous foe it can reach; dashes at a valuable foe 7-18 away (a spitter, a shaman);
Area Slash when 3 are near (2 if the second hit is worth it); Breaker on a high-DEF foe; never dashes through a
telegraphed area.

### 3.3 Ranger (Bow): steady damage from range, pierce armour

Passive **Hop**: when a foe would reach it within 0.3 s, it hops up to 7 toward a safer free spot (a 0.2-0.3 s move);
every 6 s; no invulnerability, and its beat runs on (the hop resets nothing).

| Tier | Skill | What it does | Cooldown |
|---|---|---|---|
| Common | **Piercing Shot** | 1.35 physical ignoring 25% DEF, and 0.55 on one foe lined up behind (cap 2). | 6 s |
| Uncommon | **Arrow Volley** | 0.85 on the target, 0.6 on up to 4 others within 9 of it (cap 5). | 12 s |
| Epic | **Snare Arrow** | 0.9 physical and a 25% slow for 2.5 s (a boss 15% for 1.5 s). | 13 s |
| Mythic | **Arrow Rain** (ultimate) | 1.2 s warning on the ground, then 1.3 on the target, 0.7 on up to 4 others within 9 (cap 5). | 12 s, then 24 s |

AI: a foe within its danger range first (the original), else the most valuable one it can hit; Piercing Shot on a
high-DEF foe or two lined up; Volley on a group; Snare a melee foe chasing it, then hop.

### 3.4 Mage (Arcane Focus): areas and magic

Passive **Hop**, as the Ranger's but every 9 s (the owner: archers and mages both dodge and keep their distance).

| Tier | Skill | What it does | Cooldown |
|---|---|---|---|
| Common | **Arcane Barrage** | 1.2 magic on the target, 0.4 on up to 2 others within 7 (cap 3). | 6 s |
| Uncommon | **Frost Burst** | Within 8 of a foe: 0.9 on it, 0.45 on up to 3 others (cap 4), all slowed 25% for 2.5 s. | 13 s |
| Epic | **Arcane Lance** | 1.55 magic on one foe; 35% more against a barrier. | 12 s |
| Mythic | **Meteor** (ultimate) | 1.5 s warning on the ground, then 1.65 on the target, 0.85 on up to 3 others within 9 (cap 4). | 12 s, then 24 s |

AI: the group where its area does the most good (not simply the biggest); Frost Burst on a group coming for the back
row; Lance on a shielded or high-DEF foe; never a Meteor where the foes are about to leave.

### 3.5 Healer (Healing Staff): keep them standing

Its plain action IS healing (the owner: the healer focuses on healing): while a team-mate is below 90%, every beat heals
the one with the least predicted health; only with everyone well does it throw a weak bolt. No passive regeneration.

| Tier | Skill | What it does | Cooldown |
|---|---|---|---|
| Common | **Mend** | A heal of 4.0 on a team-mate whose predicted health falls below 60%, within 15. | 8 s |
| Uncommon | **Healing Ring** | 0.7 on each of up to 4 hurt team-mates within 11 of one of them. | 16 s |
| Epic | **Ward** | A barrier of 2.5 on a team-mate within 15, at most 20% of its max HP, for 5 s. | 14 s |
| Mythic | **Sanctuary** (ultimate) | 1.1 on each of up to 4 team-mates; new stuns on them last 25% less for 3 s. | 12 s, then 24 s |

Aim: one Healer gives back about 30% of what an equal team deals. Worked through at ATK 1, DEF 1, SPD 1: four Warriors
deal about 1.22 HP/s; the Healer's plain heals give 0.27 HP/s and Mend (1.2 HP every 8 s, in place of a 0.3 plain heal)
0.11 more: 0.38 HP/s, 31%. The higher tiers may lift it to 35-40% at their best; §10 measures the real share. AI: stays
in the back ring near the team; heals by predicted health (blows on their way count), not by the current bar; Ring when
2+ would gain; Ward before a telegraphed hit or on a back-row slime under attack. No cleanse at launch (a weakness on
purpose). Healer and Alchemist have no hop: they fall back toward the Guardian.

### 3.6 Alchemist (Alchemy Kit): break armour, stop heals, lift the team

Its flasks are thrown in an arc, so it can hit a foe behind the front row (an area is never intercepted). One clear
effect a skill.

| Tier | Skill | What it does | Cooldown |
|---|---|---|---|
| Common | **Acid Rain** | Within 8 of a foe: 0.9 magic on it, 0.45 on up to 2 others (cap 3); their armour melts 20% for 4 s. | 8 s |
| Uncommon | **Squad Tonic** | Its team deals 20% more damage for 4 s. | 18 s |
| Epic | **Cursed Flask** | One foe: heals on it are 35% weaker for 5 s (no damage). | 12 s |
| Mythic | **Catalyst Cloud** (ultimate) | Within 10 of a foe: 1.15 on it, 0.55 on up to 3 others (cap 4); armour melts 25% for 4 s. | 12 s, then 24 s |

AI: stays back, 10-12 from the foes; Acid Rain on the armoured and on tight groups; Cursed Flask on a shaman or the one
being healed; Tonic when two or more team-mates will hit during it. Watch: it must not become a member of every winning
team (§10).

### 3.7 Legendary traits (the owner's fifth rarity, 2026-11-12)

A Legendary weapon has the Mythic kit and one trait: a passive, one clear effect, that makes the class's job grander
rather than adding a fifth button. Built with the ultimates (step 5); until then a Legendary weapon fights with its
Common skill and its stats.

| Class | Trait | What it does |
|---|---|---|
| Guardian | **Last Stand** | Once a fight, a blow that would make it fall leaves it at 1 HP, and it taunts at once if a foe is in range. |
| Warrior | **Momentum** | A foe it finishes makes its Dash Strike ready again. |
| Ranger | **Hawkeye** | Every 4th plain arrow also strikes one foe lined up behind (0.55, as Piercing Shot's). |
| Mage | **Echo** | Arcane Barrage strikes again 0.6 s later at half its weight. |
| Healer | **Overflow** | What a plain heal would waste becomes a barrier on the same slime, up to 10% of its max HP, for 4 s. |
| Alchemist | **Lingering Brew** | Its armour melts last 2 s longer. |

## 4. Weapons

Six families x five tiers = 30 weapons in the Weapon slot (saved as `hand`, as today). The class is the family of the
weapon worn; nothing else is saved for it. Today's swords keep their ids and become the Warrior's. Names are the owner's
own from the original where it had one. Stats are flat points, as all gear today (`docs/SMITHY.md` §3), each family
leaning on its own stat as in the original.

| Family | Common (wood) | Uncommon (iron) | Epic (core) | Mythic (bramble) | Legendary (legend) |
|---|---|---|---|---|---|
| Sword | Wooden Sword `sword-wood` ATK 1 | Iron Sword `sword-iron` ATK 2 | Runeblade `sword-core` ATK 4 SPD 1 | Dawnbreaker `sword-bramble` ATK 5 SPD 1 HP 20 | Sunfire Blade `sword-legend` ATK 7 SPD 2 HP 30 |
| Shield | Wooden Shield `shield-wood` DEF 1 | Iron Shield `shield-iron` DEF 2 HP 10 | Warden Shield `shield-core` DEF 4 HP 20 | Aegis of Goo `shield-bramble` DEF 5 HP 40 | Royal Bastion `shield-legend` DEF 7 HP 50 |
| Bow | Wooden Bow `bow-wood` ATK 1 | Iron Bow `bow-iron` ATK 2 SPD 1 | Windwhisper Bow `bow-core` ATK 3 SPD 2 | Starfall Bow `bow-bramble` ATK 5 SPD 2 HP 20 | Moonsong Bow `bow-legend` ATK 6 SPD 3 HP 30 |
| Arcane Focus | Arcane Focus `focus-wood` ATK 1 | Iron-bound Focus `focus-iron` ATK 2 SPD 1 | Prism Focus `focus-core` ATK 3 SPD 2 | Mythic Focus `focus-bramble` ATK 5 SPD 2 HP 20 | Astral Scepter `focus-legend` ATK 6 SPD 3 HP 30 |
| Healing Staff | Healing Staff `staff-wood` HP 10 | Iron-shod Staff `staff-iron` DEF 1 HP 20 | Enchanted Staff `staff-core` ATK 1 DEF 1 HP 40 | Lifebloom Staff `staff-bramble` ATK 2 DEF 1 HP 50 | Everbloom Staff `staff-legend` ATK 3 DEF 2 HP 70 |
| Alchemy Kit | Alchemy Kit `kit-wood` SPD 1 | Iron Kit `kit-iron` SPD 2 HP 10 | Alchemist's Satchel `kit-core` ATK 1 SPD 3 | Philosopher's Kit `kit-bramble` ATK 2 SPD 4 HP 20 | Grand Elixir Pack `kit-legend` ATK 3 SPD 6 HP 30 |

The Legendary names are ours, from the look of the owner's set; each is about 12 level points (Mythic 8-9). Its pictures
are renders of his models with a dark line like the painted ones (`tools/blender/weapon_icons.ps1`), not drawings.

Recipes: one recipe a tier for every family (the owner: few drops, recipes easy to read), today's sword recipes: wood 3;
ore 4 + wood 2 + 25 coins; ore 8 + Core Fragment 6 + Monster Core 1 + 150 coins; Bramble Horn 4 + Core Fragment 12 +
Monster Core 2 + Boss Essence 1 + 400 coins; Legendary: Ember Core 4 + Frost Fang 4 + Monster Core 3 + Boss Essence 2 +
1000 coins (the trophies of the two hardest maps, which had no use yet). Head and Charm stay as they are: small stats, no
skills, no Legendary.

Watch: flat points weigh far more at low levels (a Dawnbreaker's +5 ATK on a slime of ATK 1). The simulator measures
Mythic against Common at levels 4, 10, 20 and late; if the gap is far past 65% at low levels, the stat points shrink, the
skill ladder stays.

## 5. How the classes meet the monsters

| Class | Swarmer | Raider | Spitter | Shaman | Armoured | Mini-boss | Boss |
|---|---|---|---|---|---|---|---|
| Guardian | taunts several | peels it off the back row | draws its shots (it does not walk in) | cannot stop its heals | holds it | takes the specials | taunts its plain blows; Bulwark for the specials |
| Warrior | Area Slash | meets it if in reach | dashes to it | chases it down | Breaker Strike | steady damage | hits between telegraphs, dashes back in |
| Ranger | Volley | Snare, then hop | ranged duel | focused fire if in range | Piercing Shot | pierce | keeps away from the marked ground |
| Mage | Barrage, Frost Burst | slows it | magic duel | area pressure | magic counts DEF at 65% | magic and slow | slow capped at 15% |
| Healer | mends chip damage | Ward on its prey | heals ranged damage | a healing race | keeps the front up | heals the specials | Ward and Ring around the specials |
| Alchemist | Acid Rain | weakens it | lobs over the front | Cursed Flask | armour melt | melt and Tonic | melt and Tonic |

No monster may need a given class: a counter makes it easier, never possible at all.

## 6. Team sheet: formation and fight mode

The team sheet (a team chip opens it, 2026-11-12) shows the four slimes where they will stand: front, middle and back
rows, each slime with its weapon's picture. The rings come from the weapons (Guardian front; Warrior front or middle;
Ranger and Mage middle; Healer and Alchemist back; Brawler front); tapping a slime's row moves it (where it starts and
falls back to; its class brain stays). The fight mode is one of three pictures:

- **Balanced**: every class by its own rules.
- **Focus Fire**: the team's leader (Warrior, else Guardian, else the highest ATK) picks; the others give its target +25
  when they can reach it safely. The Healer never stops healing for it; the Alchemist may still pick a better flask target.
- **Protect Backline**: Guardian and Warrior give +25 to foes threatening the middle and back rows; those rows step back
  earlier.

Saved on the team (`formation` per slot, `tactic`); a team that has none is Balanced with the rings.

## 7. Arena (async PvP)

Same brains for attacker and defender. The defence is snapshotted when a fight is made. Heals and new barriers fade as a
fight drags: full to 30 s, 80% at 45 s, 60% at 60 s, 40% from 75 s; the limit drops from 120 s to 90 s and a timeout is
no longer a free defence win: most slimes standing, then the most health in percent, then the most damage dealt; an exact
tie is a successful defence (the Arena's results have no draws). Duplicate classes are allowed. Built 2026-11-12
(`Config.Classes.HealFade`, `ArenaFight.simulate`). An Arena fight is not positional (no walking, so no range and no
hop): the classes meet there by their blows, skills, heals and taunts alone.

## 8. Bosses

Boss telegraphs stay as the owner approved them (1.2 s). The all-slime stuns (0.5-0.7 s) stay but count in the slimes'
stun count (§2). A special still comes every 4-5 blows, but at least 8 s after the last one began and never while a
warning is still open (a fast boss would otherwise warn every second: about three specials in a 25 s boss fight). A
boss's plain blows can be taunted; its specials cannot be stopped. Later bosses mix in ground rings a
slime can step out of and targeted heavy hits the Guardian and the Healer can answer.

## 9. Looks

- **Models**: the owner's own (2026-11-12, `art/models/weapons/source/`): six Meshy files, one a family with its four
  tiers in a row from wood to Mythic (`sword`, `shield`, `bow`, `crystal_staves` = Arcane Focus, `druid_stave` = Healing
  Staff, `kit`), about 5000 triangles a file, and the Legendary set (`legendary.glb`, all six in a 3 x 2 grid, about 16500
  triangles). Step 3 cuts each weapon out (as `tools/blender/weapon_icons.py` does), sizes it to a slime's hand and
  lightens it for phones. Each tier is its own model: no recolours.
- **Rarity** (the owner, 2026-11-12): the higher the tier, the more and finer the weapon's effects and the better its
  motion. Common moves cleanly with its plain swing and hit; each tier up adds its own designed layer (a swing trail, then
  sparkles or motes in the weapon's colours, then a signature burst on its skill), and the Legendary set the grandest: its
  own idle shimmer of the weapon's gems and a richer motion. Every layer from art in the VFX library, its own design per
  family and tier, never a plain glow or aura, and within the phone budgets.
- **Holding** (the owner, 2026-11-12, one rule for every slime): at rest, in the village and between fights, the sword,
  shield, bow, focus and staff are slung across the back; the Alchemy Kit is always at the slime's left, at rest and in a
  fight. In a fight the shield and the bow are in front, the sword, the focus and the staff at the right. Every blow and
  cast has its own weapon move (the sword swings, the staff and focus swing or twirl to cast) with its motion or spell
  effect. The body's squash and lean carry the weapon.
- **Moves** (the original's timings): sword swing 0.34 s, a big arc, and cleave 0.5; bow draw 0.42 and volley 0.62;
  staff raise 0.6 and channel 0.85; focus orbit 0.55 and surge 0.75; kit shake 0.45 and fling 0.58; shield brace 0.4 and
  bastion 0.55; a gentle idle sway each.
- **Effects**: every skill its own design in the VFX library (`C:\roblox-vfx-library`, through its session): six
  projectiles (arrow, arcane bolt, flask, heal mote, and the sword's and shield's swing trails), six hit effects, 24 skill
  effects with their warnings on the ground, the ultimates' charge, and the rarity layers above.
- Taunt reads as monsters turning to the Guardian, a Ward as a bubble, armour melt as the monster's own drip; no camera
  effects in fights (the owner's rule).

## 10. Checking the balance

A headless simulator (`tools/sim`, Lune, no Roblox) runs the real `Combat` and class brains: at least 1000 seed-paired
fights a match-up, sides swapped, at levels 4, 10, 20 and late. It records damage dealt and prevented, healing and
overheal, time out of reach, target switches, casts, stun and taunt uptime, fight length.

- Each class against each monster role, the mini-boss and the boss (the table of §5 must hold).
- Six hard match-ups: Guardian, Mage, Mage, Healer against ranged and raiders (does the tank-and-mages clump win
  everything?); Guardian, Healer, Healer, Ranger against a balanced team (can healing stall?); Ranger, Ranger, Mage,
  Healer against Warrior, Warrior, Guardian, Alchemist (can melee reach range?); Warrior, Ranger, Mage, Alchemist against
  Guardian, Guardian, Healer, Alchemist (can a protected back row be broken without a Rogue? if the defence wins more
  than 65-70%, fix interception, taunt, flask reach and heals first; Rogue last), at all four tiers, since anti-heal
  only comes at Epic: two Common Healers must not stall four Common hitters on Focus Fire; Guardian, Guardian, Mage, Healer
  against stunning monsters and a mini-boss (can stuns lock it?); Guardian, Warrior, Ranger, Healer against Guardian,
  Mage, Alchemist, Healer (do both have a way to win?).
- Rarity: each tier against Common at the same Arena power (§1), and a well-built Common team against badly built Mythic
  and Legendary ones; four of one class never the best; a speed-bred slime is not the best build nor a dead one; the
  Alchemist is not in every winning team.
- Team fights are measured as the Arena fights them (`ArenaFight.simulate`: not positional, heals fading, the timeout
  rule); the positional dungeon part measures range, hops and the monsters.
- Ranged against fast monsters (the biggest risk ChatGPT names): how long Rangers and Mages really spend at their range;
  if too little, the monsters' blow commitment and the hop are tuned before anything else.
- Targets: a fight of four against four lasts about 25 s (today's tuning) and never past 90 s in the arena; overheal under
  a third; the same seed gives the same fight.

## 11. Build order

Each step is a commit that passes `tools/check.ps1` and `tools/types.ps1`; the steps the owner can see are shown to him in
a Studio play test.

1. **Rules core** (shared, tested): magic damage, heal weight, the speed change, skills on cooldowns that take a blow's
   place, the effects (slow, stun count, taunt, melt, anti-heal, Tonic, barrier, damage taken), threat and target keeping.
   The Brawler keeps fighting as today.
2. **Common classes**: the six brains (range bands, hop, intercept, leash, targets) and the six signature skills; the 24
   weapons and their recipes at the Smithy; the class from the weapon worn; the simulator and its first sweep.
3. **Weapons in hand**: the owner's 30 models (§9), held and swung, the projectiles and the signature skills' effects,
   more and finer effects and motion the higher the rarity; seen by the owner in a dungeon run.
4. **Uncommon and Epic skills** with their effects.
5. **Mythic ultimates** with the stagger and their charge effects; the Legendary traits (§3.7).
6. **Team sheet**: rows and the three fight modes (saved per team).
7. **Arena** rules (§7) and the full balance sweep (§10); numbers into `Config.Classes`. (The owner chose to balance before
   step 3: the Arena rules and a first tuning of the Common classes are in, §13; the sweep is run again after steps 4-6.)

## 12. The debate with ChatGPT (2026-11-12)

| ChatGPT proposed | Taken? | Why |
|---|---|---|
| Six classes, Bard later, Rogue as a dedicated diver | Six, but the owner's six (Alchemist, not Rogue) | His art, names and AI exist for them; one weapon at one hand anchor rules out twin daggers; the Alchemist covers anti-heal and team buff. ChatGPT agreed, with the protected-backline test as the condition. |
| Rarity must not unlock skills (all tiers one kit, a mastery system for the rest) | No | The owner asked that lower rarity has fewer skills. Reconciled: every tier has the full AI and the class's signature skill; ChatGPT accepted. |
| Mythic should win ~63%, not the 70% I proposed | Yes | A Mythic team should feel stronger without beating a Common counter-team. |
| Energy meter for ultimates | No | No player control means no decision to make; the owner's screens have no bars that only repeat numbers. ChatGPT agreed: cooldowns with an opening delay. |
| Several teams in a dungeon, capped at 3 with scaling | No | The owner had already set one team a run. |
| Taunt only changes targets, never pulls; cap 3 | Yes | Monsters walking to the tank is the gathering the owner wants. Uptime raised to the owner's original (4 s every 8 s, re-taunt shield). |
| Areas with caps and smaller shares | Yes | Stops the tank-and-two-mages farm. |
| Stun count, bosses immune, mini-boss 0.3 s | Yes | Stops stun-locks. |
| Speed loses crit and dodge | Partly | In our numbers speed is already the weakest stat per point (attack is linear, the beat hyperbolic): crit becomes flat, dodge only against plain blows. |
| Heals without the 0.3 damage weight | No | One heal would undo five blows; heals use the damage weight, and the Healer's plain action heals (the owner's wish). ChatGPT agreed and worked the numbers to 31%. |
| Shooting while moving at 60% | 80% | Monsters walk twice as fast, so a slime is caught anyway; the brake is the monsters' blow commitment and the hop. |
| Boss specials at least 8 s apart | Yes | At high speed a special every 4 blows would warn every second. |
| A fixed 10 Hz tick; then "event-driven is fine" | Already so | Our fight already steps every 0.1 s. Kept: same-step damage before deaths, a separate random stream for looks. |
| Utility AI with five priorities and target keeping | Yes | §2. |
| Tactics Balanced / Focus Fire / Protect Backline (not Focus Weak) | Yes | Focus Weak overlaps the Ranger's and Alchemist's own aims and drags the Guardian out of line. |
| Arena: heal fade, neutral timeout, 90 s | Yes | Healing stalemates were a free defence win. |
| Rework the all-slime boss stuns | Partly | The owner just approved them; they stay short and now count in the stun count. |
| Floating wand, twin daggers | No | The owner's one-hand-anchor rule. |
| Alchemist with two or three effects a skill | No | Young players: one clear effect a skill; it also keeps the Alchemist from being needed everywhere. |

## 13. As built (steps 1-2, 2026-11-12)

Built: the rules core and the six Common classes in `Combat`, their numbers in `Config.Classes`
(`src/shared/ConfigClasses.luau`), the class from the weapon worn (`Classes.ofSlime`), the 24 weapons at the Smithy (one
family a time on its Weapon tab; icons cut from the owner's `equip-*.png`), tests in `tests/spec/classes.luau`. Seen in a
Studio dungeon run with both debug teams: every class casts its skill, no errors. Every tier uses the Common skill until
steps 4-5.

Simpler than §2-§3 for now (each is a later fix, none changes a rule the owner sees):
- No threat table: a monster's target is still today's pick by its kind; a Guardian draws foes by Taunt and Pull (Pull 3).
- Ranged slimes do not shoot while walking (80%) and the Healer and Alchemist do not back away; Rangers and Mages hop.
- A dash does not check that its landing spot is free; a hop with no free spot of its three tries is skipped.
- Heals look at health now, not at blows on their way; a Mend with nobody below 60% still spends its cooldown.
- A boss special that was cancelled still counts for the 8 s gap. The Ranger does not prefer foes in its danger range.

### First sweep (`tools/balance/class_sim.luau`, positional, Common unless named)

Its team table fought team against team positionally, which the Arena never does; the balance pass below measures them
as the Arena fights.

Dungeon, meadow, slimes level 60, 30 runs a probe: every team of four clears level 2 or 3 (four of one class, Brawlers,
mixed: no class breaks the dungeon); GWRH with Mythic weapons clears 4. Rangers and Mages stand out of the danger range
56-68% of the time. Mend is cast about once a run (the plain heal does the work).

Team against team, slimes level 20 and 60, 1000 fights each, sides swapped (first team's wins, draws in brackets):

| Match-up | Level 20 | Level 60 | Reading |
|---|---|---|---|
| GHHR against WRMA | 83% (12%) | 98% (1%) | healing wins and stalls: too strong |
| RRMH against WWGA | 90% | 86% | melee does not reach range |
| GGHA against WRMA (wood, iron, core, bramble) | 7, 5, 16, 0% | 62, 54, 61, 43% | inside 65-70% at 60, broken easily at 20: no Rogue needed |
| HHGW against WWRM | 59% (19%) | 93% (4%) | two Healers stall four hitters: fails |
| GWRH against GMAH | 98% (2%) | 88% (11%) | GMAH has hardly a way to win: fails |
| GMMH against GWRH | 5% (8%) | 13% (17%) | the tank-and-mages clump is no farm |
| GWRH Mythic against GWRH Common | 100% | 100% | far over 60-65% (the weapons' stat gap, §4's watch) |
| WWWW, GGGG, RRRR, MMMM, AAAA against GWRH | 50, 0, 55, 5, 0% | 27, 0, 32, 5, 0% | no four of one class beats the mixed team at 60 |
| HHHH against GWRH | 0% (100%) | 0% (100%) | four Healers can neither win nor lose: a stall |
| BBBB (no weapons) against GWRH | 26% | 46% | at 60 a class adds little over today's Brawler |

What to tune first (step 7, before the arena uses classes): heals (the Healer's plain heal and Mend at the 0.3 weight;
the arena's heal fade of §7 is not built yet), melee reach against ranged (the walk, the dash, the hop's cooldown), the
weapons' stat gap between tiers, and what a class adds over a Brawler at high levels.

### Balance pass (2026-11-12, the owner chose to balance before step 3)

The sim's team and tier parts now run the Arena's own fight (`ArenaFight.simulate`); the dungeon part stays positional.
What changed:
- **Heals**: `Combat.healAmount(attack, factor) = Combat.damage(attack, attack) x factor`, what the healer's blow would
  take off a slime as strong as itself. The old weight (attack x 0.3) grew with attack while blows shrink by defence, so
  heals outran damage at high levels. The plain heal is 0.9 of that.
- **The Arena's rules (§7)**: heals fade from 30 s (80% at 45 s, 60% at 60, 40% at 75; `Config.Classes.HealFade`, Arena
  only), the limit is 90 s, and a fight at the limit goes to more slimes standing, then more health in percent, then more
  damage dealt; only an exact tie lets the defender hold (the limit was a free defence win).
- **The classes** (`ConfigClasses`): a weapon made a slime weaker than a Brawler, whose skills come every 4-5 blows while
  the class skills waited 6-10 s. Warrior and Ranger now beat at 1.0 with factor 1.05, Mage and Alchemist 1.0 / 0.9,
  Guardian 1.1 / 0.8 and always takes 20% less (Shield; 35% while taunting), Healer 1.15 / 0.65. Dash Strike 1.5 every
  6 s, Piercing Shot every 6 s, Arcane Barrage 1.2 (splash 0.4) every 6 s, Acid Rain every 8 s.
- **Legendary** (§1, §4): the fifth weapon tier, about 12 level points a weapon.

Team against team, 1000 seeded fights each, sides swapped (the first team's wins; Common weapons):

| Match-up | Level 20 | Level 60 | Level 120 | Reading |
|---|---|---|---|---|
| GWRH mirror | 52% | 50% | 51% | fair |
| GHHR against WRMA | 66% | 66% | 60% | healing helps, no stall (at most 2% reach the limit) |
| RRMH against WWGA | 61% | 47% | 41% | melee reaches range |
| GGHA against WRMA | 32% | 64% | 73% | inside 65-70% up to 60, a little over at 120 |
| HHGW against WWRM | 51% | 65% | 76% | two Healers grow strong late |
| GWRH against GMAH | 88% | 63% | 42% | GMAH weak early, fine later |
| GMMH against GWRH | 27% | 42% | 57% | the tank-and-mages clump is no farm |
| GWRH against WRMA (one Healer against none) | 85% | 71% | 62% | |
| WWWW, GGGG, RRRR, MMMM, AAAA against GWRH | 42, 0, 34, 15, 0% | 32, 3, 29, 20, 18% | 25, 5, 25, 35, 55% | no four of one class the best, but AAAA at 120 |
| HHHH against GWRH | 0% | 0% | 0% | 98-99% reach the limit and lose on the rule: no stall win |
| GWRH against BBBB (no weapons) | 97% | 71% | 52% | a class adds little at 120 |

One Healer heals 27-34% of the damage its team takes; two, 46-60%. Fights last 42-66 s (Healer teams the longest).

Tiers against Common, slimes level 60, GWRH and WRMA (first team's wins):

| Tier | Same stats | Same Arena power (the Common team gets the weapons' level points) |
|---|---|---|
| Uncommon | 84%, 76% | 59%, 52% |
| Epic | 100%, 94% | 77%, 52% |
| Mythic | 100%, 100% | 86%, 75% |
| Legendary | 100%, 100% | 90%, 78% |

A good Common GWRH against badly built Mythic and Legendary teams of four of one class: 0-6%, except HHHH, which it
beats at the limit every time. GWRH against BBBB at the same Arena power: 54%.

Dungeon (meadow, level 60, 30 runs a probe): every team of four clears level 2 or 3, GWRH with Mythic weapons clears 4;
Rangers and Mages stand out of danger 54-63% of the time; one Healer heals about 430 a run.

Known misses, kept for the sweep after steps 4-6:
- **Rarity outweighs the build.** With the owner's own stat points a Mythic or Legendary team beats a well-built Common
  one whatever its classes, and at the same Arena power the higher tier still wins 75-90% (target about 63%): a weapon's
  points, all in a few stats, are worth more than the same points spread over levels. The levers: smaller weapon points,
  or an Arena power that counts a weapon's points more. The owner's numbers are kept until he says otherwise.
- At level 20 GMAH has little way against GWRH (88%); at 120 a class adds little over a Brawler and AAAA beats GWRH 55%:
  the late game rests on the skills of steps 4-5.
- Fights run 42-66 s, not the 25 s §10 hoped for (the Guardian's Shield and the heal weight); only four Healers reach
  90 s.

## 14. As built (step 3, 2026-11-12): weapons in hand

- **Models**: `tools/blender/weapon_kit.py` (run by `weapon_kit.ps1`) cuts the owner's seven files into 30 weapons (each
  family's four tiers by their gaps, the Legendary grid by its 3 x 2 cells), centres each and writes one FBX and one
  1024 texture a file to `art/models/weapons/` (its renders, `review/kit_*.png`, stay out of git); 480-2850 triangles a weapon, Legendary
  up to 4255. Uploaded on the owner's account; the mesh ids and sizes are `Config.Weapons.Models` (`ConfigWeapons`).
- **Wearing** (`client/SlimeWeapon`): a slime whose hand gear is a weapon carries its model (the village from the
  slime's `Gear` attribute, the Dungeon squad from its node's). It rides the skin like a worn piece (SlimeActor's loop),
  sways gently, and goes from the back to the hand in 0.35 s. Places and turns per family in `Config.Weapons.Families`
  (body units: one body height, +X the slime's right, -Z its front); every slung piece leans its head up at the right.
  Size: the family's Common piece is `length` bodies tall, the other tiers keep their size against it, Legendary 1.12
  times. A slime that falls puts its weapon away.
- **Moves** (`shared/WeaponMoves`, the original's timings): each family's attack and cast move, started so its strike
  (`WeaponMoves.Strike`) meets the blow the server announced (the "aim" event, ZombieFight). The sword's swing and cleave
  stop just above the ground (the original's flat arc drove the blade into it).
- **Shots and marks** (the owner's battle art, `View.Fx.Styles`): the Ranger shoots an arrow from its bow and marks a
  pierce along the shot, the Mage an orb from its focus and a magic hit, the Healer a bolt of light from its staff and
  sends a heal mote to the one it mends, the Alchemist throws a flask and splashes acid, the Warrior's mark is the slash,
  the Guardian's the impact. Ranged marks at half size.
- **Skills** (`View.Skill.Looks`): Taunt rings out from the Guardian and rings every foe it pulls; Arcane Barrage fires an
  orb from the focus at every foe struck; Acid Rain drops flasks from the sky; Mend blooms with heal light. Dash Strike and
  Piercing Shot strike like a crit.
- **Rarity layers** come from the VFX library (`trail.weapon_<family>`, `burst.weapon_cast_<family>`,
  `aura.weapon_<family>` with the tier as the variant, the aura from Epic up): SlimeWeapon plays each as soon as the
  library has it and leaves it out until then. Asked of the library session on 2026-11-12; not imported yet.
- Seen in a Studio play test (`docs/weapons/review/`): the back, the left and the hand places from behind and in front,
  and a real Dungeon run (arrows, orbs, pierce and magic marks drawn). Not yet built: weapons on the Arena's replay bodies
  and on the zombie march.
