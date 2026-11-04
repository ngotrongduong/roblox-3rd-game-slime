# Drops, gear and the Smithy

The owner (2026-11-04): few kinds of drops, so crafting recipes stay easy to read. Several monsters share a material
and differ only in how often they drop it; only the mini-boss and boss give the few rare things worth noticing. Gear is
crafted from these drops at a Blacksmith in the Market. Numbers live in `Config.Dungeon` (drops) and `Config.Smithy`
(gear, recipes); the original's §13–15 (`docs/reference/02-battle.md`) are the starting point, cut down on purpose.

## 1. The materials (six, for every map)

| id | Name | Who drops it | Feel |
|---|---|---|---|
| `wood` | Hardwood | plant monsters, some flyers | common |
| `ore` | Iron Ore | beasts, armoured, the bosses | common |
| `rare_part` | Core Fragment | elites, mini-boss, boss | uncommon |
| `monster_core` | Monster Core | the mini-boss (and the boss, rarely) | rare |
| `boss_essence` | Boss Essence | the boss only | very rare |
| `boar_tusk` | Bramble Horn | Sunny Meadow's boss (always 2), its mini-boss (sometimes) | the map's trophy |

Coins and food (Slime Snacks) still drop, as before. `cloth` and `common_part` no longer drop: what a player already
holds stays in `farm.materials` and is simply unused (a later map may take them back). The ids are kept (saves hold them);
`boar_tusk` is only renamed on screen. Every later map adds at most ONE trophy material of its own; the other five are shared.

## 2. Who drops what (Sunny Meadow)

Each monster has its own list; every line is rolled on its own (`chance`, an amount `min`..`max`). Luck
(`1 + LuckPerLevel x (level - 1)`) multiplies every chance below 1, never above 1. The boss's two horns never fail.

| Monster | Coins | Food | Wood | Ore | Core Fragment | Monster Core | Boss Essence | Bramble Horn |
|---|---|---|---|---|---|---|---|---|
| Twigling | 25% 2–4 | 15% 3–5 | 35% 1 | | | | | |
| Parrot | 25% 2–5 | 10% 3–5 | 15% 1 | 10% 1 | | | | |
| Bloom Sprite | 25% 2–5 | 15% 3–5 | 30% 1 | | | | | |
| Aurora Owl | 25% 2–5 | 10% 3–5 | | 15% 1 | 5% 1 | | | |
| Hedgehog | 30% 3–6 | 10% 3–5 | | 45% 1–2 | 12% 1 | | | |
| Mossback Gorilla (mini-boss) | 100% 6–11 | | | 100% 2–3 | 60% 1–2 | 30% 1 | | 20% 1 |
| Bramblehorn (boss) | 100% 12–20 | | | 100% 3–5 | 100% 2–3 | 50% 1 | 25% 1 | 100% 2 |

A full clear of level 1 (about 30 monsters) gives roughly 5 wood, 8 ore, 4 Core Fragments, 0.8 Monster Core, 0.25 Boss
Essence and 2.2 Horns: iron gear after one or two runs, core gear after a few, bramble gear after a handful of boss kills.

## 3. Gear

Three slots on every slime: **Hand** (a weapon: attack), **Head** (a helm: defence and health), **Tail** (a charm: speed).
Gear adds flat points to the slime's stats in every fight (dungeon and zombies); it never changes the slime's own stats,
its level or its price. Four tiers, the rarity colour shown only on screens (the original's veto: no glow in the world).

| Tier | Rarity | Colour |
|---|---|---|
| wood | Common | #8f97a0 |
| iron | Uncommon | #3a9b3a |
| core | Epic | #8a4fd0 |
| bramble | Mythic | #f08a24 |

| id | Name | Slot | Tier | ATK | DEF | SPD | HP |
|---|---|---|---|---|---|---|---|
| `sword-wood` | Wooden Sword | hand | wood | 1 | | | |
| `helm-wood` | Wooden Helm | head | wood | | 1 | | |
| `charm-wood` | Twig Charm | tail | wood | | | 1 | |
| `sword-iron` | Iron Sword | hand | iron | 2 | | | |
| `helm-iron` | Iron Helm | head | iron | | 2 | | 10 |
| `charm-iron` | Iron Charm | tail | iron | | | 1 | 10 |
| `sword-core` | Core Blade | hand | core | 4 | | 1 | |
| `helm-core` | Core Helm | head | core | | 3 | | 30 |
| `charm-core` | Core Charm | tail | core | 1 | | 3 | |
| `sword-bramble` | Bramble Sword | hand | bramble | 5 | | 1 | 20 |
| `helm-bramble` | Bramble Crown | head | bramble | 2 | 4 | | 40 |
| `charm-bramble` | Bramble Charm | tail | bramble | | 2 | 3 | 30 |

## 4. Recipes (one a gear piece)

| Gear | Materials | Coins |
|---|---|---|
| Wooden Sword | wood 3 | 0 |
| Wooden Helm | wood 4 | 0 |
| Twig Charm | wood 2 | 0 |
| Iron Sword | ore 4, wood 2 | 25 |
| Iron Helm | ore 5 | 25 |
| Iron Charm | ore 3, wood 2 | 25 |
| Core Blade | ore 8, Core Fragment 6, Monster Core 1 | 150 |
| Core Helm | ore 8, Core Fragment 6, Monster Core 1 | 150 |
| Core Charm | wood 6, Core Fragment 6, Monster Core 1 | 150 |
| Bramble Sword | Bramble Horn 4, Core Fragment 12, Monster Core 2, Boss Essence 1 | 400 |
| Bramble Crown | Bramble Horn 4, Core Fragment 12, Monster Core 2, Boss Essence 1 | 400 |
| Bramble Charm | Bramble Horn 4, Core Fragment 12, Monster Core 2, Boss Essence 1 | 400 |

Crafting is atomic (the original's rule): check the recipe, the materials and the coins; take them once; add one piece to
the player's gear bag. A failed craft takes nothing. A recipe shows its materials as pictures with "have / need".

## 5. Saving

Schema 10: `farm.gear = { [gearId] = count }` (the bag: pieces nobody wears) and on each slime `gear = { hand, head, tail }`
(gear ids, each optional). Equipping moves one piece from the bag to the slime (what it wore goes back to the bag);
unequipping moves it back. A slime that is sold or released gives its gear back to the bag. Repair drops unknown ids and
negative counts; the migration from 9 adds an empty bag.

## 6. The Blacksmith (Market)

A stall in the Market built after the owner's `blacksmith-01.png` (honey wood frame with rope lashings, blue and cream
awning with the money-bag emblem, a stone furnace with fire, an anvil, a weapon rack, an armour stand, a water barrel,
banners) with the blacksmith slime of `npc.blacksmith.png` (navy bandana, brass goggles, leather apron, hammer) at the
anvil. Prompt "Blacksmith" opens the **Smithy** sheet: tabs Hand / Head / Tail, each a grid of its four pieces (picture,
name, rarity colour, stats as +numbers); a piece's card shows its materials (picture, have/need) and coins, and Craft
(greyed with "Missing materials" or "Not enough coins"). The bag's count shows on each piece. Gear is worn from the slime's
card (three slots; tap one, pick a piece from the bag, or take it off).
