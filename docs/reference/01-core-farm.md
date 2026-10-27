# Goo Lineage — Core Farm & Progression Spec (reverse-engineered)

Source: `reference/goo-lineage-web/*.js` (Goo Lineage V2, save schema v15). Every number below is
copied from the code; the file that owns it is given in brackets, e.g. `[config]` = `config.js`.
Times in the original are **milliseconds of wall clock** (`Date.now()`) unless marked "sim-seconds".
Values marked *(computed)* were calculated from a formula in the code — implement the formula,
not the table.

---

## 1. The core loop in plain words

1. The player starts with **4 navy starter slimes** (all identical, level 4), **20 food**, **0 coins**,
   one unlocked workstation (Berry Bush) and 9 starter weapons.
2. **Breed**: pick two adult, rested slimes → an **egg** is created immediately with the baby
   fully decided (stats, colour genes, pattern genes, rare appearance). Parents go on cooldown.
3. **Incubate**: the egg hatches after 60 s (upgradeable). Ready eggs **auto-hatch** (one at a
   time) with a reveal animation; the baby appears at the nest spot as a small hatchling and
   grows to adult size over ~5 minutes. Babies cannot breed.
4. **Collect**: every hatch registers its base colour, and any Dual/Secret appearance, in the
   **Collection book** (11 base colours, 20 duals, 66 secrets).
5. **Feed**: every slime loses hunger over time and auto-eats from shared food storage. Food is
   produced by assigning slimes to **workstations** (1 food/min per worker at speed 1).
   Starving workers stop working.
6. **Sell** spare slimes to the merchant for **coins** (rarity × level). Coins buy **upgrades**
   (food storage, incubation, cooldown, growth, slime slots, auto-breeding nest) and
   **workstation unlocks**.
7. **Progress**: higher stats → higher level → more sale value, highscores, achievements,
   unlocks Siege battles at slime level 30, the World Boss at 50 slime slots. Every 50 hatches
   ranks up the player's avatar.
8. The farm keeps simulating while away (capped at 8 h).

---

## 2. Entities and fields

### 2.1 Farm (root save object) `[state, saveValidation]`

| Field | Type | Initial value | Notes |
|---|---|---|---|
| `slimes` | Slime[] | 4 starters | order = save order; never re-sorted |
| `selectedId` | string\|null | null | UI selection (cosmetic) |
| `eggs` | Egg[] | [] | max 4 active `[config BREEDING.maxActiveEggs]` |
| `breedsSinceMutation` | int ≥0 | 0 | mutation pity counter |
| `discoveries` | {base, dual, secret} | base.navy = {firstDiscoveredAt: now, hatchCount: 4} | each bucket: id → {firstDiscoveredAt, hatchCount≥1} |
| `food` | {basicFood, capacity} | {20, 100} | shared pantry |
| `workstations` | WorkstationState[] | 4 entries `station-1..4` | one per definition |
| `unlockedStations` | string[] | `['ws.berry-bush']` | definition ids |
| `lastSimulatedAt` | ms | now | farm sim clock |
| `coins` | int ≥0 | 0 | |
| `items` | Item[] | 9 starter items (see 2.6) | equipment instances |
| `materials` | {id: count} | {} | battle materials, serums, jelly |
| `upgrades` | UpgradeState | all 0 | see §8 |
| `nest` | Nest? | absent | created when the player first configures the specialized nest |
| `lifetime` | LifetimeStats | see §11 | achievement counters |
| `avatar` | Avatar | createAvatar(now) | player-controlled slime, NOT a farm slime |
| `tutorialDone` | bool? | false (fresh farm) | absent on legacy saves = tour done |
| `tutorialDoneAt` | ms? | set when tour completes/skips | starts New-Player Luck |
| `lastSiegeTeam` | string[]? | — | battle (out of scope) |
| `wbKingSlain` | true? | — | World Boss II unlock (out of scope) |

### 2.2 Slime `[state, breeding, saveValidation]`

| Field | Type | Notes |
|---|---|---|
| `id` | string | starters `slime-1..4`; bred = `slime-<ms base36>-<rand(1e9) base36>` (never changes) |
| `name` | string | starters `Slime 1..4`; hatchlings `Slime N` where N = (max existing `Slime <n>` number) + 1 |
| `x, y` | number | farm position (logical 1672×936 px) |
| `targetX, targetY` | number\|null | wander target |
| `seed` | uint32 | starters `0x9e3779b9 ^ (i * 0x85ebca6b)`; hatchlings = FNV-1a hash of id (offset 2166136261, prime 16777619) — drives per-slime RNG for movement/moods |
| `assetId` | string | `slime.base.<colour>` / `slime.dual.<NN>` / `slime.secret.<a>-<b>` |
| `stats` | {attack, defence, speed, hp} | integers |
| `colourGenotype` | {alleles:[c1,c2]} | two base colour ids |
| `patternGenotype` | {alleles:[p1,p2]} | `'solid'` or `'duochrome'` |
| `visibleColour` | colour id | ALWAYS = resolvePhenotype(colourGenotype); recomputed on load |
| `appearanceMutation` | {type:'none'} \| {type:'dual'\|'secret', definitionId} | cosmetic layer on top; never inherited |
| `isFavourite` | bool | favourites cannot be sold |
| `needs` | {hunger 0–100, hungerState} | hungerState derived |
| `createdAt` | ms | growth is derived from it; starters = now − 300 000 (already adult) |
| `breedReadyAt` | ms | 0 = ready; cooldown end |
| `loadout` | {head, hand, tail} item ids\|null | equipment (battle) |
| `fallen` | bool | knocked out in battle; can't breed/work |
| `previousLoadout` | loadout\|null | battle |

**Level is never stored**: `level = floor(attack + defence + speed + hp/10)` `[stats]`.

### 2.3 Egg `[breeding, saveValidation]`

| Field | Notes |
|---|---|
| `id` | `egg-<ms base36>-<rand base36>` |
| `parentIds` | [idA, idB] (parents may later be sold) |
| `createdAt`, `hatchAt` | ms; `hatchAt = createdAt + incubationMs(upgrades)` |
| `offspringId` | pre-reserved slime id |
| `embryo` | {stats, colourGenotype, patternGenotype, appearanceMutation} — **fully resolved at creation, never rerolled** |
| `status` | `'incubating'` \| `'ready'` — derived (`now >= hatchAt`), never trusted from disk |
| `injected` | true? — a mutation injection (Royal Jelly / Prism Serum) was used |
| `statBoosted` | true? — a Vital Serum was used |

### 2.4 Workstation definition `[workstations]` / state

State: `{ id:'station-N', definitionId, assignedSlimeIds: string[] (≤ maxWorkers), progressMs ≥0, pendingOutput int ≥0 }`.

### 2.5 Nest (Specialized Breeding) `[nest, saveValidation]`

`{ nestId:'main', enabled: bool, specialty: 'level'|'atk'|'def'|'hp'|'spd', memberSlimeIds: string[] (empty = whole farm), currentEggId?, pausedReason?:'PAUSED', pendingPair?: {ids:[a,b], pickedAt: ms} }`.
Created on first specialty pick (`enabled:true`, chosen specialty) or first toggle (`enabled:true, specialty:'level'`) `[game]`.

### 2.6 Items (only farm-relevant shape) `[state, saveValidation]`

`{ id, definitionId, ownership: {kind:'INVENTORY'} | {kind:'EQUIPPED_TO_SLIME', slimeId, slot:'head'|'hand'|'tail'} | {kind:'BATTLE_ESCROW'|'PENDING_RETURN'} }`.
Starter items (all INVENTORY): `item-sword-1` sword, `item-bow-1` bow, `item-staff-1` healing_staff,
`item-staff-2` healing_staff-2, `item-shield-1` shield, `item-focus-1` arcane_focus,
`item-focus-2` arcane_focus-2, `item-kit-1` alchemy_kit, `item-kit-2` alchemy_kit-2.
Selling a slime returns its gear to INVENTORY. Escrow states are released to INVENTORY on load.

### 2.7 Avatar `[avatar]`

Not a farm slime: never eats, breeds, works, is sold or counts toward population.
`{ name:'You' (≤16 chars), assetId:'slime.base.navy', x: 836, y: 580.32, stats {1,1,1,10}, spentPoints 0, loadout {head,hand,tail,back,wings,aura}, createdAt, frame:'wood', bg:'meadow', ownedFrames[], ownedBgs[] }`.
- Rank = `1 + floor(totalHatched / 50)`; `totalHatched` here = sum of hatchCount over **base + dual + secret** buckets (a Dual/Secret hatch counts twice; the 4 starters count).
- `unspentPoints = (rank − 1) × 5 − spentPoints`. A point = +1 ATK/DEF/SPD or +10 HP, capped by STAT_LIMITS.
- Looks: may wear any discovered base colour / dual / secret asset (navy always).
- Movement: keyboard target leads by 140 px, steer speed ×5.25, hop scale 0.55.

---

## 3. Stats, levels, limits `[config, stats]`

| Constant | Value |
|---|---|
| Starter stats | ATK 1, DEF 1, SPD 1, HP 10 → level 4 |
| ATK / DEF / SPD range | 1 – 99 (integers) |
| HP range | 10 – 9990 (integer) |
| Level formula | `floor(ATK + DEF + SPD + HP/10)` → max 99+99+99+999 = **1296** |
| Speed note | speed must never allow zero-duration jobs (min job 5 s) |

---

## 4. Breeding `[breeding, config, upgrades, growth]`

### 4.1 Eligibility (checked in this order; first failure returns its reason)

| # | Rule | Reason code / player text `[breedingPanel]` |
|---|---|---|
| 1 | idA ≠ idB | SAME_PARENT "A slime cannot breed with itself." |
| 2 | both exist | MISSING_PARENT "Pick two different slimes." |
| 3 | stats finite > 0, 2 valid colour alleles, 2 pattern alleles | INVALID_PARENT_DATA |
| 4 | neither `fallen` | PARENT_FALLEN |
| 5 | neither is a baby (still growing) | PARENT_TOO_YOUNG "A parent is still growing up." |
| 6 | `now ≥ breedReadyAt` for both | PARENT_ON_COOLDOWN "One parent is still resting." |
| 7 | `slimes.length + eggs.length + 1 ≤ populationLimit` (eggs reserve a slot) | SLIME_CAP_REACHED "The farm is full — no room for a baby." |
| 8 | `eggs.length < 4` | EGG_CAP_REACHED "The nest is full." |

UI also hides from the breeding picker: fallen slimes, slimes assigned to a workstation, babies, slimes on cooldown.

### 4.2 Timers

| Timer | Formula | Default |
|---|---|---|
| Incubation | `max(5000, 60000 − min(5, incubationLv) × 5000)` ms | 60 s; 35 s at max lv 5 |
| Parent cooldown | `round((60000 + max(0, maxParentLevel − 1) × 1000) × 0.95^min(20, breedCooldownLv))` ms; both parents get the same `breedReadyAt` | starters (lv4): 63 s |
| Grow-up (baby → adult) | `round((300000 + max(0, level − 1) × 1000) × 0.95^min(20, growthLv))` ms from `createdAt` | lv-4 baby: 303 s |
| Baby visual scale | `0.62 + 0.38 × clamp((now − createdAt)/growUp, 0, 1)` | `[config GROW]` |
| Hatchling `breedReadyAt` | = hatch time (but blocked by baby rule) | |

### 4.3 Stat inheritance `inheritStats`

1. For each stat: uniform random **integer between the two parents' values, inclusive**.
2. Improvement roll: `rng < min(0.95, 0.10 × luck)` → pick one stat uniformly among
   ATK/DEF/SPD/HP; set it to `max(parentA, parentB) + bonus`, bonus = randInt(1..3) for ATK/DEF/SPD,
   randInt(10..30) for HP. (Replaces the rolled value.)
3. Clamp every stat to its limits.
- "Improved stats" (for reveal FX) = stats where baby > BOTH parents.
- Preview text: "Baby ranges: ATK a–b · DEF … ", "10% chance one stat improves beyond the stronger parent.", "A rare discovery may be possible." when a secret recipe exists or (different colours and a dual pool exists — always true), plus pity "✨ Lucky charm: n/25 …" or "FULL — the next egg is guaranteed a rare mutation!" at 24.

### 4.4 Egg creation sequence `createEgg`

1. Eligibility check (4.1).
2. `luck = newPlayerLuck(farm, now)` (§4.7).
3. `outcome = resolveOffspring(...)` (§5.4) using parents' **visibleColour** (base phenotype — a dual/secret parent breeds as its base colour), colour genotypes and pattern genotypes.
4. **Pity**: if outcome appearance is `none` and `breedsSinceMutation + 1 ≥ 25`: secrets = recipe for the pair (always exists), duals = dualPool(pair). If `duals` empty (same colour) or `rng < 0.10` → Secret (weighted pick); else Dual (weighted pick from pool) and pattern genotype forced duochrome/duochrome.
5. Stats via 4.3 with the same luck.
6. Egg stored; parents' `breedReadyAt = now + cooldown`.
7. On commit: `breedsSinceMutation = 0` if embryo appearance ≠ none, else +1 (both manual breeding and nest). `lifetime.breeds += 1`.

### 4.5 Hatching `hatchEgg`, `gameActions`

- Fails with NOT_READY if `now < hatchAt`, MISSING_EGG if gone (idempotent).
- Baby: id = offspringId, name `Slime N`, position = nearest walkable to nest point **(640, 600)**, full hunger, `createdAt = now`, empty loadout, `assetId` = secret > dual > base asset.
- On reveal complete: remove egg, add slime, register dual/secret discovery (banner "New Dual Colour!" / "Secret Slime Discovered!" on first), register base colour discovery (always, +1 hatchCount), `lifetime.bestSlimeLevel = max(…, baby level)`, avatar rank-up banner if rank increased.
- **Auto-hatch** (baseline for everyone): every **500 ms** eggs past `hatchAt` become `ready`; then the **oldest ready egg** is hatched, one at a time, unless a battle is open, the tutorial is running, or a reveal is on screen. (`upgrades.autoHatch` is a dead legacy field.)
- Egg icon colour = `egg.<alleles[0]>.png` (navy shows the blue egg).

### 4.6 Tutorial first-egg boost `[gameActions, game]`

Applies when `tutorialDone === false && eggs.length === 0 && slimes.length === 4`:
- colour = random base colour ≠ navy, made **homozygous**; appearance forced `none`;
- 2 distinct random stats set to `max(parents) + bonus` (ATK/DEF/SPD +1..3, HP +10..30, clamped);
- `hatchAt = createdAt + 20 000` ms.
(Pity counter still +1.)

### 4.7 New-Player Luck `[luck]`

Starts at `tutorialDoneAt` (set when the tutorial finishes OR is skipped).
| Time since tutorialDoneAt | Luck |
|---|---|
| 0 – 30 min | ×5 |
| 30 – 60 min | ×3 |
| after, or no tutorialDoneAt, or tutorialDone not true | ×1 |

Luck multiplies: secret chance, dual chance, stat-improve chance (each capped at 0.95). It does **not** affect the base-colour mutation (10%) or pity.

---

## 5. Genetics

### 5.1 Base colours `[colours]` (dominance: higher wins; ties by tiePriority — all unique)

| Id | Name | Dominance | tiePriority | Asset | Swatch |
|---|---|---|---|---|---|
| black | Black | 11 | 11 | slime.base.black | #2b2b33 |
| gray | Gray | 10 | 10 | slime.base.gray | #9aa0a8 |
| navy | Navy | 9 | 9 | slime.base.navy | #1b4fd8 |
| purple | Purple | 8 | 8 | slime.base.purple | #8a4fd0 |
| red | Red | 7 | 7 | slime.base.red | #d8402f |
| orange | Orange | 6 | 6 | slime.base.orange | #f08a24 |
| yellow | Yellow | 5 | 5 | slime.base.yellow | #f2d13d |
| green | Green | 4 | 4 | slime.base.green | #54b848 |
| pink | Pink | 3 | 3 | slime.base.pink | #f27fb6 |
| blue | Blue ("Sky Blue") | 2 | 2 | slime.base.blue | #3f9ff0 |
| white | White | 1 | 1 | slime.base.white | #f5f2ea |

(Marked "TEMPORARY dominance order" in the source.) Starters: navy/navy. Order of `BASE_COLOUR_IDS` = table order (used by the base-mutation pick).

### 5.2 Colour inheritance `[genetics]`

- Baby gets one allele from each parent, each chosen 50/50.
- Phenotype: identical alleles → that colour; else higher dominance wins. Invalid ids: one valid wins; two invalid → `blue`.
- Recessive alleles are carried silently (e.g. black/white looks black).

### 5.3 Pattern locus (Dual carrier gene) `[patternGenetics]`

- Alleles `solid` (dominant) / `duochrome` (recessive). Starters solid/solid.
- Inheritance: one allele from each parent, 50/50.
- Only duochrome/duochrome can *express* a Dual naturally; solid/duochrome = carrier (looks base).

### 5.4 Offspring resolution `resolveOffspring` `[mutationResolver, config MUTATION]`

Inputs: parents' visible colours A, B; genotypes; pattern genotypes; luck.

```
secrets = recipes for pair {A,B}            (always 1 — every pair incl. same-colour has one)
duals   = A != B ? dualPool(A,B) : []        (exact pair designs, else every design that
                                              contains A or B; never empty when A != B)
secretChance = secrets ? min(0.95, 0.01*luck) : 0
dualChance   = duals   ? min(0.95, 0.05*luck) : 0
baseChance   = 0.10
colourGeno  = inherit(A geno, B geno);  phen = phenotype(colourGeno)
patternGeno = inherit(pattern A, pattern B)

if secrets and rng < secretChance:  SECRET (weighted pick, all weights 1); keep colourGeno+patternGeno
elif duals and rng < dualChance:    DUAL (weighted pick from pool); patternGeno := duochrome/duochrome
elif rng < 0.10:                    BASE MUTATION: new colour = uniform pick among the 10 colours
                                    != phen; colourGeno := new/new (homozygous); appearance none
else NORMAL:
   if patternGeno is duochrome/duochrome AND colourGeno alleles differ AND an EXACT dual design
      exists for those two alleles -> DUAL (weighted pick, exact designs only)
   else appearance none
```

The rolls are sequential conditionals (the code comment says production should be one categorical roll; it is not). Effective per-egg odds before pity:

| Case | Secret | Dual | Base colour mutation | Normal |
|---|---|---|---|---|
| Different colours, luck 1 | 1% | 4.95% | 9.405% | 84.645% |
| Different colours, luck 3 | 3% | 14.55% | 8.245% | 74.205% |
| Different colours, luck 5 | 5% | 23.75% | 7.125% | 64.125% |
| Same colour, luck 1 | 1% | 0 | 9.9% | 89.1% |
| Same colour, luck 5 | 5% | 0 | 9.5% | 85.5% |

(Normal outcomes may still express a Dual through carriers.)
Pity (§4.4): the 25th consecutive non-mutated egg is guaranteed: 10% secret / 90% dual (same colour → secret).
UI egg-details shows natural odds as "Dual colour: 5%" / "Secret slime: 1%".

### 5.5 Dual designs `[dualDefinitions]` — 20 designs, 18 distinct exact pairs

ID = `dual-<a>-<b>-<NN>`, asset `slime.dual.<NN>`, weight 1, all enabled.

| NN | Parent pair | Name | Pattern |
|---|---|---|---|
| 01 | green + white | Mint Chip | dots |
| 02 | purple + white | Lavender Stripe | stripes |
| 03 | pink + red | Sweetheart | hearts |
| 04 | blue + white | Glacier Stripe | stripes |
| 05 | orange + yellow | Ember Chevron | chevron |
| 06 | purple + pink | Royal Dot | dots |
| 07 | blue + green | Seafoam | patches |
| 08 | orange + red | Caramel | patches |
| 09 | red + black | Blazepatch | patches |
| 10 | gray + white | Cloudspot | patches |
| 11 | green + blue | Lagoon | patches |
| 12 | purple + navy | Duskpatch | patches |
| 13 | green + yellow | Citrusleaf | patches |
| 14 | gray + black | Ashpatch | patches |
| 15 | navy + blue | Deepsea | patches |
| 16 | blue + purple | Periwinkle | patches |
| 17 | orange + white | Sunset | patches |
| 18 | red + purple | Berrypatch | patches |
| 19 | white + blue | Frostdot | dots |
| 20 | green + navy | Forestpatch | patches |

Pair matching is order-independent (key = alphabetically sorted "a|b"). blue+white has 2 designs (04, 19); blue+green has 2 (07, 11). Pairs with no exact design (37 of 55 cross pairs) use the fallback pool = every design that contains either parent colour.

### 5.6 Secret recipes `[secretRecipes]` — 66 (all 55 cross pairs + 11 same-colour pairs)

ID = `secret-<x>-<y>` where x,y = the two colours sorted alphabetically; asset `slime.secret.<x>-<y>`; weight 1.
"Boost" = rendered ×1.2 body (face not scaled) because the art has wide features `[bodyBoost]`.

| ID suffix | Parents | Name | Description | Boost |
|---|---|---|---|---|
| white-white | white+white | Snow Rabbit | Fluffy snow texture, rabbit ears and a cotton tail | |
| pink-white | white+pink | Sakura Bunny | Pink-tipped ears with drifting cherry blossoms | |
| white-yellow | white+yellow | Daisy Chick | Yellow feather tuft and white daisy-petal markings | |
| green-white | white+green | Lily Spirit | Lily-of-the-valley flowers and delicate green vines | |
| orange-white | white+orange | Creamsicle Fox | Orange fox ears and tail with creamy-white tips | |
| red-white | white+red | Peppermint Slime | Red-and-white candy spirals with mint sparkles | |
| purple-white | white+purple | Moon Orchid | Pale orchid petals with a soft violet moon glow | |
| navy-white | white+navy | Arctic Wolf | Navy-tipped wolf ears, icy fur markings and frost breath | |
| gray-white | white+gray | Cloud Sheep | Cloud-like wool curls with tiny gray hooves | |
| black-white | white+black | Yin-Yang Koi | Two circling koi markings with flowing fin-like tails | |
| pink-pink | pink+pink | Rose Fairy | Rose-petal wings and floating pink pollen | |
| pink-yellow | pink+yellow | Peach Blossom | Peach-coloured flower crown and yellow pollen sparkles | |
| green-pink | pink+green | Watermelon Frog | Green outer skin, pink centre and seed spots | |
| orange-pink | pink+orange | Coral Axolotl | Coral-pink gills, orange fins and bubbly particles | yes |
| pink-red | pink+red | Lovebird Slime | Tiny feathered wings and heart-shaped markings | yes |
| pink-purple | pink+purple | Dream Butterfly | Large butterfly wings with glowing dream dust | yes |
| navy-pink | pink+navy | Twilight Moth | Navy moth wings decorated with pink moon patterns | |
| gray-pink | pink+gray | Rose Hedgehog | Soft gray spines covered with tiny pink roses | |
| black-pink | pink+black | Gothic Bat | Black bat wings, pink inner ears and rose-vine markings | yes |
| yellow-yellow | yellow+yellow | Sun Lion | Golden mane made from sun rays | yes |
| green-yellow | yellow+green | Lemon Gecko | Lime-green body markings with yellow citrus spots | |
| orange-yellow | yellow+orange | Sun Phoenix | Fiery feather crest and glowing orange wings | yes |
| red-yellow | yellow+red | Fire Salamander | Yellow-red flame markings and a flaming tail | |
| purple-yellow | yellow+purple | Royal Griffin | Purple feathered wings with a golden eagle crest | yes |
| navy-yellow | yellow+navy | Star Owl | Navy wings covered in glowing yellow stars | |
| gray-yellow | yellow+gray | Thunder Ram | Curved gray horns surrounded by yellow electricity | |
| black-yellow | yellow+black | Honeybee Slime | Black-yellow stripes, tiny wings and dripping honey | |
| green-green | green+green | Forest Dryad | Leafy hair, small antlers, flowers and orbiting leaves | |
| green-orange | green+orange | Autumn Fox | Leaf-shaped fox ears and a fiery autumn tail | |
| green-red | green+red | Holly Deer | Small antlers decorated with holly leaves and red berries | |
| green-purple | green+purple | Poison Frog | Bright toxic spots, frog feet and bubbling poison droplets | |
| green-navy | green+navy | Lagoon Turtle | Shell-like back pattern with seaweed and water ripples | |
| gray-green | green+gray | Moss Golem | Cracked stone texture covered with moss and tiny flowers | |
| black-green | green+black | Swamp Basilisk | Dark scales, green glowing eyespots and a reptile tail | |
| orange-orange | orange+orange | Ember Tiger | Fiery tiger stripes, rounded ears and a flame-tipped tail | |
| orange-red | orange+red | Fire Dragon | Dragon horns, small wings and burning scale patterns | yes |
| orange-purple | orange+purple | Witch Cat | Cat ears, curled tail, purple magical flames and a tiny hat marking | |
| navy-orange | orange+navy | Sunset Koi | Flowing fins coloured like an orange-and-blue sunset | |
| gray-orange | orange+gray | Copper Beetle | Metallic beetle shell, tiny legs and copper highlights | |
| black-orange | orange+black | Jack-o'-Slime | Pumpkin texture, curling vine and warm inner light | |
| red-red | red+red | Rose Dragon | Rose-petal scales, thorny horns and floral wings | |
| purple-red | red+purple | Dragonfruit Slime | Bright fruit skin, leafy crest and dark seed spots | |
| navy-red | red+navy | Fire-Ice Chimera | One flaming side and one frozen side with mismatched horns | |
| gray-red | red+gray | Iron Boar | Metal tusks, red armour markings and a strong rounded body | |
| black-red | red+black | Blood Moon Bat | Dark wings with a glowing crimson moon marking | |
| purple-purple | purple+purple | Amethyst Unicorn | Crystal horn, sparkling mane and amethyst hooves | |
| navy-purple | purple+navy | Galaxy Whale | Star-filled body with tiny fins and a floating cosmic tail | yes |
| gray-purple | purple+gray | Moonstone Gargoyle | Stone wings, small horns and glowing violet cracks | yes |
| black-purple | purple+black | Void Kraken | Shadowy tentacles, purple runes and floating void particles | yes |
| navy-navy | navy+navy | Deep-Sea Leviathan | Fins, glowing lure, dark scales and bioluminescent spots | |
| gray-navy | navy+gray | Storm Shark | Shark fin and tail surrounded by storm clouds and rain | |
| black-navy | navy+black | Midnight Raven | Black feathered wings with a navy starry sheen | yes |
| gray-gray | gray+gray | Stone Tortoise | Heavy stone shell with moss growing between the cracks | |
| black-gray | gray+black | Shadow Wolf | Smoky black fur markings, gray ears and a shadow tail | |
| black-black | black+black | Universe Slime | A living night sky containing stars, nebulae and miniature galaxies | |
| blue-blue | blue+blue | Cloud Pegasus | Fluffy cloud mane, tiny feathered wings and sparkling raindrops | |
| blue-white | blue+white | Frost Swan | White crystal wings, icy-blue feathers and drifting snowflakes | yes |
| blue-yellow | blue+yellow | Thunderbird | Golden lightning wings, a sky-blue crest and crackling sparks | |
| blue-green | blue+green | Sky Island Turtle | Grassy shell with tiny flowers, floating clouds and a miniature waterfall | yes |
| blue-orange | blue+orange | Sunshower Fox | Orange sun markings, cloud-like tails and glowing rainbow droplets | |
| blue-red | blue+red | Steam Dragon | Red-hot core, blue dragon horns and swirling clouds of steam | |
| blue-pink | blue+pink | Cotton Candy Sheep | Fluffy pink-and-blue cloud wool with floating sugar sparkles | |
| blue-purple | blue+purple | Aurora Jellyfish | Flowing violet tentacles, a translucent blue bell and aurora ribbons | |
| blue-navy | blue+navy | Celestial Manta | Wide navy fins decorated with glowing sky-blue constellations | |
| blue-gray | blue+gray | Raincloud Ram | Curled storm-cloud horns, soft gray wool and falling blue raindrops | yes |
| black-blue | blue+black | Tempest Dragon | Black storm wings, glowing cyan lightning cracks and swirling dark clouds | yes |

(The file header still says "55 recipes, Blue excluded" — stale; 66 are live.)

### 5.7 Appearance rules `[mutations]`

- Asset priority: secret > dual > base colour.
- Discovery registers only at hatch; repeat = hatchCount +1.
- Unknown dual/secret ids in a save are KEPT (placeholder art), never converted.

### 5.8 Egg injections (World Boss loot, affects farm eggs) `[battle/worldboss, eggPanel]`

| Item (material key) | Allowed when | Effect |
|---|---|---|
| Royal Jelly (`royal_jelly`) | egg not `injected`, embryo appearance none | 30% secret, else guaranteed dual; pools: exact embryo-allele recipes, else ANY enabled design. Sets `injected`. |
| Prism Serum (`mutation_serum`) | same | rng<0.10 → secret; else rng<0.50 → dual; else fizzle (serum still spent). Sets `injected`. |
| Vital Serum (`stat_serum`) | egg not `statBoosted` | random stat := max(parent best, embryo value) + bonus (1–3 / HP 10–30), clamped. Sets `statBoosted`. |

Drop rates: King boss 25% each serum; Queen 25% each. Injections don't touch the pity counter.

---

## 6. Hunger & food `[config FARM, hunger, food, offline]`

| Constant | Value |
|---|---|
| Max / starting hunger | 100 / 100 (hatchlings start full) |
| Hunger loss | 2 per minute (continuous formula, applied per 1-min sim step) |
| Auto-eat threshold | hunger ≤ 35 |
| Food per meal / hunger restored | 1 food / +20 hunger (clamped at 100) |
| Starting food | 20 |
| Base food capacity | 100 (+100 per Food Storage level, max lv 20 → 2100) |
| States | `full` > 35; `hungry` 0 < h ≤ 35; `starving` h ≤ 0 |

- Steady state: a fed slime eats 1 food per 10 min = 0.1 food/min/slime. From full: first meal at ~33 min, starving after 50 min without food.
- Per sim step (1 minute): every slime −2 hunger → then, in slime array order, each slime with hunger ≤ 35 eats ONE meal if the pantry has ≥1 food (max one meal per slime per step).
- Starving consequences: worker produces nothing (station pauses if all its workers starve); face = sleep. **No death, no stat loss.** Hungry face = sad.
- Food storage never goes negative; additions above capacity are rejected and stay as station `pendingOutput` (never lost).
- Other food sinks/sources: battle loot adds food (`battle/loot`); reviving a fallen slime costs `20 × ceil(1 + level/5)` food and sets its HP stat to `max(1, round(hp × 0.5))` (permanent — looks like a bug; on reload HP is clamped back to ≥10).

---

## 7. Jobs & workstations `[workstations, jobs, offline]`

### 7.1 Definitions

| Id | Name | Base cycle | Base yield | Max workers | Unlock cost (coins) | Order |
|---|---|---|---|---|---|---|
| ws.berry-bush | Berry Bush | 120 000 ms | 2 | 3 | 0 (starts unlocked) | 1 |
| ws.farm-plot | Farm Plot | 240 000 ms | 4 | 3 | 1 000 | 2 |
| ws.fishing-pond | Fishing Pond | 360 000 ms | 6 | 3 | 5 000 | 3 |
| ws.cooking-kitchen | Cooking Station | 180 000 ms | 3 | 3 | 10 000 | 4 |

All are 1 food/min per worker at speed 1. Stations must be bought **in this order** ("Unlock the X first."). 12 worker slots total.

### 7.2 Formulas

```
speedBonus(speed) = speed < 1 or invalid ? 0 : min((speed - 1) * 0.05, 3)      (caps at speed 61)
jobDurationMs     = max(5000, floor(baseDurationMs / (1 + speedBonus)))
jobYield          = max(1, floor(baseYield * (1 + speedBonus)))
crew cycle        = jobDurationMs of the FASTEST non-starving worker
crew yield/cycle  = sum of jobYield(each non-starving worker)
```
Example Berry Bush worker: speed 1 → 120 s / 2 food; speed 21 (bonus 1.0) → 60 s / 4 food (4/min); speed 61+ (bonus 3) → 30 s / 8 food (16/min). Output per worker scales ~(1+bonus)².

Per 1-minute sim step: `progressMs += 60000`; while `progressMs ≥ duration` → subtract and add every active worker's yield to `pendingOutput`; then flush `pendingOutput` into food storage (overflow stays pending). No active workers → station frozen (progress kept).

### 7.3 Assignment rules `canAssign`

Fails: MISSING_SLIME, MISSING_STATION, STATION_DISABLED, STATION_LOCKED, INVALID_SLIME_DATA, SLIME_BUSY (fallen, or already at any station), STATION_FULL (UI offers "replace worker": swap one crew member atomically, keeping progress/pending). Babies **can** work. Removing a worker never touches the slime.
- Working slimes and slimes on breeding cooldown are hidden from the field map (`isOnField`).
- A working slime cannot be sold ("Remove it from its workstation first.") and is excluded from the breeding picker and the nest.
- Worker chatter (cosmetic): bubble 2.4–3.8 s, quiet gap 5–14 s, first after 2–7 s; 10% chance two crew members argue (opener angry face, retort dare face 1.4–2.2 s later) `[farmPanel, talkBubbles]`.

---

## 8. Economy

### 8.1 Coin sources

| Source | Amount | File |
|---|---|---|
| Sell slime | `floor(base × (1 + level × 0.05))`; base 10 (none), 100 (dual), 1000 (secret) | economy, config ECONOMY |
| Siege / World Boss loot | King victory 1500c (+12 meat food, crown shard, essence); Queen 2000c; defeat consolation up to 500 / 650c | battle/* (out of scope) |

Sell examples: starter lv4 = 12; lv10 base = 15; lv50 base = 35; lv4 dual = 120; lv4 secret = 1200; lv100 secret = 6000.
Sell rules: not favourite; not assigned to a station; farm must keep ≥ 2 slimes; gear returns to inventory; `lifetime.coinsEarned += value`. Multi-sell runs the same checks per slime. Coins are floored, never negative.

### 8.2 Coin sinks — Upgrades `[upgrades]`

Shared price curve, cost of buying the NEXT level when the current level is `L`:
```
rampCost(L, maxLevel) = round10( 100 * 200 ^ min(1, L / (maxLevel - 1)) )      // round10 = Math.round(x/10)*10
```

| Track id | Name | Max lv | Effect per level | Effect formula |
|---|---|---|---|---|
| foodStorage | Food Storage | 20 | +100 capacity | `100 + lv×100` |
| incubationSpeed | Faster Incubation | 5 | −5 s incubation | `max(5000, 60000 − lv×5000)` ms |
| breedCooldown | Quicker Breeding | 20 | −5% (multiplicative) | `× 0.95^lv` (lv20 → ×0.3585, "64% less") |
| growthSpeed | Faster Growth | 20 | −5% (multiplicative) | `× 0.95^lv` |
| slimeStorage | More Slime Slots | 40 | +5 slots | `20 + lv×5` → max **220** |
| specializedBreeding | Specialized Breeding | 1 (one-time) | unlocks the auto-breeding nest house | cost **9 coins** ("for testing"); 999999 after |
| autoHatch | (retired) | — | auto-hatch is now free for everyone | field kept for saves |

Purchase is atomic: check max level, check coins ≥ cost, deduct, +1 level, re-apply food capacity.

*(computed)* price tables:

| L (current) | 5-lv track (Incubation) | 20-lv tracks (Food/Cooldown/Growth) | 40-lv track (Slots) |
|---|---|---|---|
| 0 | 100 | 100 | 100 |
| 1 | 380 | 130 | 110 |
| 2 | 1 410 | 170 | 130 |
| 3 | 5 320 | 230 | 150 |
| 4 | 20 000 | 310 | 170 |
| 5 | — | 400 | 200 |
| 6 | | 530 | 230 |
| 7 | | 700 | 260 |
| 8 | | 930 | 300 |
| 9 | | 1 230 | 340 |
| 10 | | 1 630 | 390 |
| 11 | | 2 150 | 450 |
| 12 | | 2 840 | 510 |
| 13 | | 3 750 | 580 |
| 14 | | 4 960 | 670 |
| 15 | | 6 560 | 770 |
| 16 | | 8 660 | 880 |
| 17 | | 11 450 | 1 010 |
| 18 | | 15 130 | 1 150 |
| 19 | | 20 000 | 1 320 |
| 20–29 | | — | 1 510, 1 730, 1 990, 2 280, 2 610, 2 990, 3 420, 3 920, 4 490, 5 140 |
| 30–39 | | | 5 890, 6 750, 7 730, 8 850, 10 140, 11 620, 13 310, 15 240, 17 460, 20 000 |
| **Total** | **27 210** | **81 860** each | **156 790** |

### 8.3 Other coin sinks

- Workstation unlocks: 1 000 / 5 000 / 10 000 (§7.1).
- Travelling merchant (avatar cosmetics: frames 1 500–7 000, backgrounds 1 200–4 000, wings 2 500–9 500, auras 2 000–10 000); visits every 15 min wall clock, stays 5 min `[traveller]` — cosmetic, covered elsewhere.

### 8.4 Progression gates

| Gate | Condition | File |
|---|---|---|
| Siege battles | any slime (or the avatar) reaches level **30** | battle/config `unlockSlimeLevel` |
| World Boss | slime capacity ≥ **50** (More Slime Slots lv 6) | battle/worldboss |
| World Boss II (Queen) | King slain once | battle/worldboss |
| Nest house | Specialized Breeding bought | upgrades, game |
| Workstations 2–4 | coins, in order | workstations |

---

## 9. Specialized Breeding nest (auto-breeder) `[nest, game]`

Runs inside the farm sim (once per sim minute) when `upgrades.specializedBreeding > 0`, nest exists, `enabled` and not `PAUSED`.

1. If `currentEggId` still exists in `eggs` → wait. If it hatched → clear and continue this same step.
2. If a `pendingPair` exists: if `now − pickedAt < 60 000` → wait (parents are walking); else commit now (fallback for offline/stuck).
3. Otherwise pick parents: members = `memberSlimeIds` (empty = whole farm) filtered by eligibility: not baby, not fallen, not at a station, not already in pendingPair, `breedReadyAt ≤ now`. Rank by specialty stat desc → level desc → id asc. Top 2 → `pendingPair = {ids, pickedAt: now}`.
4. Commit = normal `createEgg` (all §4.1 checks incl. pop/egg caps); failure silently drops the pair. Success: egg added, parents' cooldown, `currentEggId = egg.id`, pity bump, `lifetime.breeds +1` (live commit only).

Specialty stats: level = calculateLevel, atk, def, hp, spd. Labels: "Highest Level / ATK / DEF / HP / SPD".
Live world escort (cosmetic): the two parents hop at ×2 speed to door spots (235,640)/(307,640), timeout 60 sim-s, linger 8 sim-s, then the egg is committed when both are inside. Floating hearts every 0.45 s (scale 0.45→0.60, alpha 0.5 fading, rise 26 px/s, 1.4 s).
Status for UI: PAUSED; FARM_FULL (slimes+eggs(+reservedSlot) ≥ limit); ACTIVE (egg); GROWING (a member is a baby); COOLDOWN; ACTIVE if enabled else WAITING.

---

## 10. Offline progress & the sim clock `[offline, game]`

- **One** simulation for online and offline: `simulateFarm(farm, elapsedMs)` advances in fixed **60 000 ms steps**, max **480 steps** (8 h) per call. Each step: (1) hunger decay, (2) auto-eat, (3) workstation progress + flush, (4) nest step at timestamp `lastSimulatedAt + (step+1)×60000`.
- Online: `tickFarm` runs every ~1 s from the frame loop and every 5 s from a timer; only whole minutes are processed and `lastSimulatedAt += steps×60000` (remainder carried). Harvest banner "🍓 +N food harvested".
- Boot / tab return / import: `applyOfflineProgress` — elapsed clamped to **8 h** (`offlineCapMs = 28 800 000`), then `lastSimulatedAt = now` (time beyond the cap is lost, no double claim). Clock moved backwards → no progress, clock pinned to now.
- Offline summary banner (if ≥ 1 min processed): "While away (N min[, cap reached]): +F food −E eaten X hungry Y starving".
- Not capped (absolute wall-clock timestamps): egg `hatchAt`, `breedReadyAt`, growth from `createdAt`, luck window. Eggs hatch on return; babies may be adults.
- Nest RNG offline: deterministic per step (`mulberry32(((step+1) × 2654435761) >>> 0)`) when no rng is injected (online passes `Math.random`).
- Day counter: `touchPlayDay` on every tick/boot — a new local calendar day (`YYYY-MM-DD`) → `daysPlayed +1`.

---

## 11. Collection, achievements, highscores

### 11.1 Collection book `[collection]`

| Tab | Entries | Shows when undiscovered |
|---|---|---|
| Base | 11 colours | name + art (public knowledge) |
| Dual | 20 designs | "???", no art |
| Secret | 66 recipes | "???", id 'locked', no art, no hint |

Per entry: discovered, firstDiscoveredAt, hatchCount. Tab percent = round(discovered/available×100). Starters pre-register navy ×4.

### 11.2 Lifetime counters `[achievements]` (monotonic)

`coinsEarned` (sales + battle coins), `foodFarmed` (food that actually entered storage), `bestSlimeLevel` (max of record and any live slime), `daysPlayed`, `lastPlayedDay`, `mobsKilled`, `bossesKilled`, `breeds` (eggs bred), `bestRaidKillSec`. Fresh farm: daysPlayed 1, bestSlimeLevel 4.

### 11.3 Achievements — 8 categories × 5 tiers = 40 tiers (no rewards; banner on unlock)

| Id | Name | Icon | Measures | Tier thresholds |
|---|---|---|---|---|
| coins | Fortune Farmer | 💰 | coins earned | 100 · 1 000 · 10 000 · 100 000 · 1 000 000 |
| hatched | Master Breeder | 🥚 | slimes hatched (sum of BASE hatchCounts, incl. 4 starters) | 5 · 15 · 50 · 200 · 500 |
| level | Star Prodigy | ⭐ | best slime level | 10 · 25 · 50 · 100 · 250 |
| food | Great Harvest | 🍓 | food farmed | 100 · 1 000 · 10 000 · 100 000 · 1 000 000 |
| days | Loyal Farmer | 📅 | distinct days played | 1 · 3 · 7 · 30 · 100 |
| mobs | Siege Slayer | ⚔️ | mobs defeated | 10 · 100 · 1 000 · 10 000 · 50 000 |
| bosses | Boss Breaker | 👑 | bosses defeated | 1 · 5 · 20 · 50 · 100 |
| secrets | Secret Seeker | ✨ | distinct secrets discovered | 1 · 5 · 15 · 30 · 66 |

`tier = count of thresholds ≤ value`. Number format: ≥1M "1.5M", ≥10k "12k".

### 11.4 Highscores `[highscorePanel]`

- Online leaderboard (one score): **best slime level on the farm** (calculateLevel of the top slime). Submitted once per panel open (only if changed); top 10 shown; refresh every 5 s while open.
- Local "records" tabs (not ranked): Slimes bred (`lifetime.breeds`), Boss time (fastest World Boss kill m:ss), Strongest (max ATK), Toughest (max DEF), Fastest (max SPD), Most HP.

---

## 12. Tutorial `[tutorial, game]`

Auto-starts on fresh farms (`tutorialDone === false`). Never blocks input; steps advance by watching real state, polled every 150 ms; hidden during battles. "Skip tutorial »" completes it too (both set `tutorialDone = true`, `tutorialDoneAt = now` → New-Player Luck starts). Replay from Settings restarts at step 1 with baselines = current progress.

| # | Step id | Text (abridged) | Completes when | Fallback (guard) |
|---|---|---|---|---|
| 1 | open-breeding | Welcome… Tap the Breeding house! | breeding panel open | — |
| 2 | pick-parents | Choose the parents — tap 2 slimes below. | 2 slimes selected | panel closed → 1 |
| 3 | confirm-breed | Now tap Confirm breed. | a new egg exists | closed → 1; <2 picked → 2 |
| 4 | egg-wait | Your first egg! … Watch the timer | an egg is ready or a hatch happened | — |
| 5 | hatch | It is wiggling — tap Hatch! (manual: auto-hatch is off during the tour) | total hatched > baseline | no egg & no hatch → 1 |
| 6 | tip-rare | Meet your new slime — a brand-new colour with a stat bonus! … | Next button | — |
| 7 | need-food | Slimes get hungry… hungry slimes stop working. | Next | — |
| 8 | open-farm | Tap the Farm to grow some food. | farm panel open | — |
| 9 | pick-berry | Tap the Berry Bush. | Berry Bush selected or worker added | farm closed → 8 |
| 10 | assign-worker | Choose 1 slime to start picking berries. | Berry Bush workers > baseline | farm closed → 8; other station → 9 |
| 11 | sell-info | Berries now fill your pantry! … sell spare slimes to this merchant (closes panels) | Next | — |
| 12 | blacksmith-info | …the blacksmith! Win Siege battles to gather materials… | Finish | — |

Resume after refresh: workers on Berry Bush → step 11; hatched > 4 → step 7; ready egg → 5; any egg → 4; else 1. Completion banner "Tutorial complete — happy breeding!" (not when skipped). First egg is boosted (§4.6).

---

## 13. Emotions / moods (logic only) `[emotions, slime, game]`

Faces: normal, admiring, exciting, loved, sleep, angry, dare, sad, surprise.

Priority resolver (first match wins):
1. starving → **sleep**
2. (favourite AND selected) OR bred < 20 s ago (`now − (breedReadyAt − 60000)`) → **loved** (nest-bound parents also show loved)
3. selection poke hop (0.55 s) → **exciting**
4. age < 15 s → **exciting**
5. explicit hint (worker argument: angry / dare) → hint
6. hungry → **sad**
7. talking: line contains "!" → exciting; "♪" → surprise; "❤" or "★" → admiring
8. a favourite slime within 150 px → **admiring**
9. ambient mood

Ambient mood timing (per slime RNG, sim-seconds): first pick at 2–10 s; a mood lasts 2–4.5 s; then quiet 6–16 s.
Ambient table — baby (age < 300 s): normal 40%, exciting 20%, surprise 15%, admiring 13%, dare 12%. Adult: normal 50%, admiring 15%, surprise 13%, dare 12%, exciting 6%, sleep 4%.

Movement (cosmetic) `[config MOVE, slime]`: hop speed 24–32 px/s; think 2.5–5 s; compress 0.12 s; airborne 0.38–0.48 s; land 0.14 s; hop height 26 px; wander radius 260, min 48; selection hop ×1.15; breathing amp 0.025 @1.4. Slime display width 67 px.

---

## 14. Inventory / slime list `[inventory, config NAMING]`

- Filters: all, available, idle, working, hungry (≠ full), starving, favourite, base, dual, secret.
- Sorts (desc): newest (createdAt), level, attack, defence, speed, hp, colour (dominance), rarity (secret 2 > dual 1 > base 0), hunger.
- Rename: trim + collapse spaces; 1–16 chars; `^[A-Za-z0-9 '\-]+$`; id never changes.
- Details actions: rename, favourite toggle, equip, siege, revive (fallen only), sell.

---

## 15. Save data `[save, saveValidation, saveMigrations, config]`

Envelope (one JSON string, platform "latest" slot):
```
{ schemaVersion: 15, savedAt: ms, farm: Farm (§2.1), settings: { reducedMotion: bool, soundMuted: bool, language?: 'en'|'ja' } }
```
- Write policy: **immediate** for kinds `hatch, breed, sell, import, reset, manage, assign, sim`; cosmetic kinds (`settle` hop landings, `select`) coalesced with a 10 s minimum interval; flush on tab hide / pagehide; a rejected write retries once after 30 s.
- Load: parse → migrate (missing version = v1; newer version → refuse and start fresh, keeping the stored save untouched) → field-level validation that repairs fields instead of discarding the farm (stats clamped/rounded, phenotype recomputed, invalid eggs dropped, duplicate ids dropped, unknown stations dropped, assignments to missing slimes removed, Berry Bush always unlocked, slime array hard cap = max(populationLimit, 500)). No valid slimes → fresh farm with 4 starters.
- Boot also re-derives food capacity from the upgrade level.
- Export/import as JSON text; import goes through the same capped offline catch-up; reset = fresh farm.
- Migration history (v1→v15): stats+genotype, cooldowns+eggs, appearance+discoveries, hunger/food/stations/clock, coins+favourites+base discoveries, settings, Cooking Station, pattern locus, loadouts+items, fallen, materials, drop `lastValid` copy (size limit), station unlocks, lifetime counters.

---

## 16. Notes for Roblox (multiplayer, server-authoritative)

1. **Clock**: replace `Date.now()` with server `os.time()` (seconds) or `workspace:GetServerTimeNow()`; store all timestamps (hatchAt, breedReadyAt, createdAt, lastSimulatedAt, tutorialDoneAt) as server epoch seconds. Never accept client times. Day counter: use UTC day (or store the player's offset) — the web game used local calendar days.
2. **Server owns every rule**: breeding checks, egg resolution (RNG on the server with `Random.new()`; never reveal the embryo to the client before the reveal), hatch, sell, assign, upgrades, unlocks, injections. Client sends intents (`Breed(idA,idB)`, `Hatch(eggId)`, `Sell(ids)`, `Assign(slimeId, stationId)`, `BuyUpgrade(track)`, `UnlockStation(def)`, `Rename(id,name)`, `Favourite(id)`, `SetNest(...)`) via RemoteFunctions with rate limits and full re-validation.
3. **Sim tick**: run `simulateFarm` per player on the server on a heartbeat accumulator (e.g. every 5–10 s process whole minutes), plus `applyOfflineProgress` on join using `lastSimulatedAt` (8 h cap). Keep the 1-minute step and the 480-step cap so behaviour matches.
4. **Hidden info**: secret names/art stay server-side until discovered; collection data sent per player.
5. **DataStore shape**: one key per player, `{schemaVersion, savedAt, farm, settings}`; store slimes as an array of compact tables (short keys if size gets tight — 100+ slimes ≈ 130 KB JSON in the web game; DataStore limit is 4 MB). Use `UpdateAsync` with session locking (or ProfileStore) to prevent duplication across servers; save on change-debounced interval (~30–60 s), on leave, and on `BindToClose`. Keep the migration + field-repair approach. Don't store derived values (level, hungerState, egg status, visibleColour).
6. **Anti-cheat**: coins/food/stat changes only from server functions; clamp stats to limits; rename filter through `TextService:FilterStringAsync`; cooldowns, egg caps (4), population caps re-checked server-side; selling cannot drop below 2 slimes; IDs generated by the server (`HttpService:GenerateGUID` or a per-player counter).
7. **Leaderboards**: best slime level → `OrderedDataStore` (global) and leaderstats; local records stay in the profile.
8. **Balance / test values to fix before launch**: Specialized Breeding costs **9 coins** (a test value); mutation rolls are sequential conditionals (comment says to change to one categorical roll); colour dominance is marked temporary; revival permanently halves HP (likely a bug); avatar comment says 2 points/rank but code gives 5; avatar `totalHatched` double-counts mutated hatches vs. the achievement count.
9. **Multiplayer visibility**: each player has a private plot; slime positions/moods/movement are cosmetic and can be fully client-side (server only replicates the slime list). Hide working/cooldown slimes like `isOnField`. Consider streaming-friendly caps (220 slimes max per plot) — render only nearby slimes and use LOD/impostors on cheap phones.
10. **Auto-hatch**: run on the server (oldest ready egg, one at a time per player) but let the client play the reveal; skip while the tutorial teaches the manual hatch.
11. **Monetisation hooks (optional, not in original)**: incubation/cooldown skips, extra slots, luck boosts map naturally onto Developer Products / Game Passes — keep them server-validated and never sell the 8 h offline cap away without balance review.
