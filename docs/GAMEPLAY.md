# Gameplay: the living slime village (approved by the owner, 2026-10-29)

The owner's direction for Phase 2 (`docs/DESIGN.md` §6): the game starts with 4 slimes living in the player's
village. They eat, rest, work, pair, lay eggs, carry eggs to the incubators, raise babies and train, as a lively
Sims-style ecosystem. Where this file differs from `docs/reference/01-core-farm.md` or `docs/MAP.md`, this file wins.
Every number is a first value in `Config`; the owner tunes them by playing.

## 1. Colours

### 1.1 The rule
1. Every slime carries its **base colours**: a plain slime of colour A carries {A}; a Dual of A+B carries {A, B}; a
   Secret of the A+B recipe carries {A, B}; a same-colour Secret (Snow Rabbit, white+white) carries {white}. A
   Material slime carries its base colour. What you see is what you breed: there is no dominance and no hidden
   allele any more, and the old pattern gene (solid / duochrome) is gone.
2. The **pair's colour set** is the union of both parents' base colours (n distinct colours, 1..4).
3. One categorical roll picks the baby's kind (table 1.2); then a uniform pick inside that kind's pool:
   - **Dual**: every unordered pair of two DIFFERENT colours of the set → n(n-1)/2 designs (`DualDesigns`, one per pair).
   - **Secret**: every unordered pair of the set, same colour included → n(n+1)/2 recipes (`SecretRecipes`, 66).
   - **Plain**: one base colour of the set.
   - **Random**: one BASE colour (plain only, never Dual or Secret) that neither parent carries.

| Colour set | Dual pool | Secret pool |
|---|---|---|
| 1 colour (navy × navy) | 0 | 1 |
| 2 colours (navy × red; Tartan × Tartan) | 1 | 3 |
| 3 colours (Tartan navy+red × yellow) | 3 | 6 |
| 4 colours (Tartan × Daisy yellow+white) | 6 | 10 |

### 1.2 The kind roll (luck 1)

The pairing kind comes from the parents' rarity (plain, dual, secret; a Material parent counts as plain) and, for two
rare parents, whether their appearance is the same definition.

| Pairing | Secret | Dual | Plain | Random |
|---|---|---|---|---|
| plain A × plain A | 1% | – | 89% | 10% |
| plain A × plain B | 1% | 4% | 85% | 10% |
| dual × plain | 2% | 25% | 63% | 10% |
| dual × same dual | 3% | 50% | 37% | 10% |
| dual × other dual | 4% | 40% | 46% | 10% |
| secret × plain | 3% | 20% | 67% | 10% |
| secret × dual | 5% | 40% | 45% | 10% |
| secret × same secret | 10% | 60% | 20% | 10% |
| secret × other secret | 7% | 45% | 38% | 10% |

- When the dual pool is empty (a one-colour set), the Dual share goes to Plain.
- **Luck** multiplies Secret and Dual (each capped at `Config.Mutation.ChanceCap`); what they gain is taken from Plain.
  Random stays 10%.
- **Material**: a Plain baby comes out in a material with `MaterialChance` (2%, × luck), weighted by tier as in
  `docs/MATERIALS.md`. Never inherited.
- **Pity**: the `PityThreshold`-th plain egg in a row (materials do not count as plain) becomes a Dual from the pool,
  or a Secret with `PitySecretShare` (always a Secret when the dual pool is empty).
- Examples: navy × red → navy 42.5%, red 42.5%, Tartan 4%, Secret 1% split evenly over navy-navy, red-red, navy-red,
  another base colour 10%. Tartan × Tartan → Tartan 50%, navy 18.5%, red 18.5%, Secret 3% (1% each of the three
  recipes), another base colour 10%.
- A slime's saved genes are its base colours: `colourGenotype.alleles` = {A, A} for plain A (or a material on A),
  {A, B} for a Dual or Secret of A+B. `visibleColour` = the plain colour, or the Dual's `bodyColour`, or for a Secret
  its first colour.

## 2. Luck

`Luck.multiplier(farm, now, serverBonus?)` = new-player luck (×5 for 30 min after the tutorial, ×3 for 30 more, as
now) × server bonus (`Config.Luck.ServerBonus`, 1; a live server event may pass more) × potion (farm field
`luckPotionUntil` + `Config.Luck.Potion`, not sold yet) × VIP (`Config.Luck.Vip`, a Robux pass at Launch, the owner
approves it; 1 for now). It multiplies the Secret and Dual chances, the Material chance and every stat-gain chance
(on hatching and at the training ground).

## 3. Stats

- Start 1 STR (attack) · 1 DEF · 1 SPD · 10 HP, level 4.
- On hatching: as before (`Breeding.inheritStats`): each stat between the parents; one stat beats both with
  `ImproveChance` × luck.
- **SPD** is movement speed (hauling, walking to work) and dodge in fights; walking speed =
  `Config.Village.WalkSpeed × (1 + (SPD - 1) × Config.Village.WalkPerSpeed)`. Work speed comes from the area level,
  not from stats.
- **Training ground**: the player assigns a slime and a stat. A session lasts `SessionSeconds` (90); at the end,
  `+1` (HP `+10`) with chance `Base × Soft / (Soft + value - 1)` × luck × area factor, where Base 0.60, Soft 10 and
  for HP value = hp / 10. Area factor `1 + (level - 1) × ChancePerLevel` (×2 at level 50); session time shrinks by
  level too.

## 4. Needs, personality, friends

| Need | Falls | Rises | Thresholds |
|---|---|---|---|
| Fullness 0-100 | 2 / min idle, 3 / min working or training | eating | ≤50 goes to eat · ≥60 may pair · ≤25 **hungry: no breeding, works at 50%** |
| Energy 0-100 | 2 / min working or training, 0.5 / min idle | sleeping +5 / min | ≤20 stops work and sleeps, wakes at ≥90 |
| Fun 0-100 | slowly | playing, chatting, babies | emotions only, no penalty |

Each slime has one personality trait (Hardworking, Lazy, Playful, Shy, Chatty, Glutton), fixed at hatching from its
seed, which weights what it likes to do and its faces; and up to 3 best friends (friendship grows by chatting and
playing). Nothing dies of hunger and no stat is ever lost to hunger.

## 5. Food: collection boxes → storehouse → kitchen → fridge

- Raw: Fish (pond) +20 fullness; Carrot and Cabbage (garden) +15.
- **Collection boxes** at the pond and the garden: the worker puts its catch or harvest there; a full box pauses the
  work.
- **Idle slimes carry** box → storehouse (pantry), and storehouse → kitchen counter when the cook needs ingredients;
  cooked dishes go into the **fridge** in the kitchen. With nobody idle, the worker itself carries when its box is
  full, so the village never jams. Offline (and in the abstract sim) every carry happens at once.
- **Dishes** (kitchen level 1; more recipes later): Grilled Fish (2 fish) +60, buff attack +10% for 20 min; Veggie
  Stew (2 carrot + 1 cabbage) +65, buff defence +10%; Fish & Veg Soup (1 fish + 1 carrot + 1 cabbage) +90, buff hp
  +10%. 120 s a dish. The cook makes the best dish its counter allows (most fullness).
- **Eating**: a hungry slime eats raw food from the storehouse. Only slimes the player **allowed** (a setting at the
  kitchen, a list of slime ids) eat dishes from the fridge, and fall back to the storehouse when it is empty. Eating
  order of raw food: whatever there is most of.
- Storehouse and fridge capacities grow with their area's level. Start: 10 fish + 10 carrots in the storehouse.
- Offline: the village runs up to 8 h (the original's cap), everything made goes straight to the storehouse.
- Buffs are kept on the slime (`buff = { stat, percent, untilTime }`) for the fights phase.

## 6. Work areas

| Area | Work | Level 1 output |
|---|---|---|
| Fishing pond | fish → its box | 1 fish / 60 s |
| Garden | plant → water → 4 growth stages → harvest → its box | 3 vegetables / 240 s (carrot or cabbage) |
| Kitchen | cooks from the counter | 1 dish / 120 s |
| Training ground | trains one stat | 1 session / 90 s |

- Each area starts with **1 work slot**; more at levels 11, 21, 31 (max 4). Each slot may also have one **reserve**
  slime who takes the shift when the worker is tired or hungry.
- A hungry worker works at 50%. Work time shrinks a little with the area level.
- **Population limit**: 20, +4 per village level (the village level is the average of the six areas' levels, as
  `VillageStages` already computes). Eggs hold a place.
- Area levels (1..50) are saved; upgrading costs coins (§8).

## 7. Breeding: nests, pairs, incubators

1. The breeding area starts with **2 nests, 2 incubators and 2 pair places**; levels add more.
2. The player sets the pairs at the breeding area (two adults a pair). A pair stays until the player changes it.
3. When both slimes of a pair are rested (`breedReadyAt` passed), fullness ≥ 60, not hungry, energy above the tired
   line, not working, and a nest is free and the village has room: they **walk in by themselves**, play and court in
   the room (hearts) for `CourtshipSeconds` (60), then go to a nest together and **lay one egg**. The baby is decided
   at that moment (§1, §3).
4. The egg **looks like a plain egg** until it hatches (the client is never told the embryo).
5. Incubation takes `IncubationSeconds + (babyLevel - 4) × IncubationPerLevel` (60 s + 1 s a level), shortened by
   the breeding area's level. The owner's rule (2026-10-29): right after laying, **one of the two parents carries the
   egg to a free incubator** (before resting). If none is free, the egg **stays in the nest and hatches there too,
   `NestSlowFactor` (2) times slower**; an idle slime moves it as soon as an incubator frees up. The clock runs from
   the moment the egg is laid: moved into an incubator, it keeps the progress made and runs the rest at full speed.
   (A nest egg saved before this rule starts its nest clock when the save is loaded.)
6. Parents rest after laying (the original's cooldown formula) and lose energy; then come back by themselves.
7. Hatching (the reveal by rarity comes later) → the baby lives in the **nursery inside the breeding area** and grows
   up (the existing growth formula, ~5 min). Adults bring it food, play with it, and sometimes take it for a walk
   round the plaza and back. Grown up, it leaves for the village.

## 8. Money, selling, death (rules now; fights come in the fights phase)

- Slimes earn coins by fighting monsters in the Wild Garden; coins pay for upgrades. SPD gives dodge; dish buffs help.
- A slime beaten by a monster too strong **dies** and becomes a **ghost** waiting at the village gate; it revives
  after **1 day** (`Config.Village.GhostSeconds`, server time). A ghost does not eat, work, breed or train. The save
  has the field from now on (`ghostUntil`).
- Spare slimes are **sold at the shop** in the Market; the higher the level, the more coins (`Mutations.sellValue`).
- In this build: selling at the shop and paying coins for area upgrades; fights and ghosts later.

## 9. Village life (the slime brain, server)

Slimes that are not working or breeding choose what to do from their needs, personality and what the village needs
(Sims-style smart objects that advertise actions):
- Errands: box → storehouse, storehouse → kitchen, nest → incubator, food to babies.
- Daily life: eat at the storehouse (or the fridge if allowed), nap (campfire seats, benches, tree shade), watch the
  fish, smell flowers, splash at the fountain, warm up at the campfire.
- Social: greet, chat (icon bubbles), argue and make up, play tag, sleep beside a best friend, play with babies and
  walk them.
- With the player: look at them, hop closer, cheer when they arrive.
- Each action has its own face and motion (`Expressions`, `SlimeMotion`, `SlimeActor`).

## 10. The owner's notes after the first play (2026-10-29)

- **UI**: the first screens were too plain. A professional UI kit made by the UI agent from the owner's own button and
  frame art (`reference/goo-lineage-web/` art, `docs/reference/03-shell-ui-world.md`): one screen button that opens
  the slime info (every slime, its look, stats, needs, job). Every slime list suggests the best slime for the place.
- **Upgrade pads** replace the E prompts: a small round pad on the ground at every upgradable place, beside the path
  (never in the middle of it), easy to see. It shows the price of the next level ($0 while prices are 0), green when
  the owner can pay, red when not. Stepping on it upgrades one level. Only the plot's owner can use it.
- **SPD also sets work speed** (the original's job speed bonus: `1 + (SPD − 1) × 0.05`, capped), besides walking and
  dodging; the picker suggests the free slime with the highest SPD for a work place.
- **Fishing**: up to 4 fishing places, each with its rod: 1 at the dock's end near the water, 2 in the middle of the
  dock, 3 on the side pier once an upgrade builds it, 4 on the blue rock beside the pond. Press F near a place → the
  slime list with the suggestion. The fisher casts, waits, reels in and drops each fish into the **fish bin** outside
  the pond (holds 10). Fish models from the Studio assets (the pond's koi and blue fish).
- **Garden**: 4 work places around the two garden beds. The gardener hoes empty soil, plants, waters (the watering can
  held over its head) as the crop grows through its 4 stage models, then pulls the ripe crop and carries it to the
  **vegetable bin** outside the garden (holds 10 of any vegetables).
- **Breeding program**: press F at the breeding area → the slime list to put slimes into the program: 4 slimes
  (2 pairs) at the start, up to 8 (4 pairs) at the top level with 4 nests. Slimes rest after breeding.
- **The player helps**: when no slime is free, the player can pick up and carry eggs, vegetables, fish and dishes to
  where they belong (the same places the slimes use).
- **Carrying**: what a slime carries rides on its head and moves up and down with every hop.
- **Movement**: slimes have a collision box and do not walk through things, people or each other; they find their way
  around obstacles (pathfinding). The hop-walk is slower and natural, a slime's pace, not a dash.

### 10.1 Gaits (the owner chose in the movement lab, 2026-10-29; numbers in `tools/slime/hop_lab_lanes.luau`)

| Gait | Lab lane | Used when |
|---|---|---|
| walk | E Big leaps | normal moving: going to work, errands, carrying |
| stroll | F Slow and soft | only inside the breeding area, while a pair courts (the owner corrected it the same day: outside the breeding area every slime moves at the normal walk, sightseeing included) |
| baby | A Gentle | babies walking |
| babyQuick | D Quick hops | babies hurrying: following an adult on a walk, playing |
| glide | G Glide (no hops) | tired or hungry slimes, and sad feelings that fit it (sad, sulking, crying, bored) |
| (kept, unused) | C Heavy jelly | the owner does not like it much; kept for later |
| (kept, unused) | B Bouncy | not chosen; kept for later |

## 11. Build order

1. Rules in `src/shared` with Lune tests (inheritance, luck, needs, food, stations, training, breeding flow, village
   sim, save schema 3).
2. Server: a village per player, the slime brain, remotes.
3. Client: slimes drawn with `SlimeActor`, work motions, carried items, boxes and fridge, pickers, a small HUD.
4. The hatch reveal by rarity and the nursery.
5. The shop in the Market; area upgrades cost coins.
