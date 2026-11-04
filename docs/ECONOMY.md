# Economy: how money is earned and what upgrades cost

The owner's design (2026-11-02), worked out and measured. Playable in MapWork: zombies on the map, sending squads, fights,
coins for each death, revive, loss for good, the shop (rules in `src/shared/Combat`, `Zombies`, `Shop`; `src/server/ZombieFights`;
`src/client/Zombie*`, `UiSquad`). The price table, the kitchen's dish prices and the coin vault are in `Config`. Tools: `tools/balance/fight_sim.luau`,
`income_sim.luau`, `kitchen_sim.luau`, `price_curve.luau` (with `income_model.luau` and `kitchen_lib.luau`, which they share).

## The owner's road

| Village level | Upgrades bought (6 a level) | Play time |
|---|---|---|
| 20 | 114 | about 2 h |
| 40 | 234 | about 12 h of continuous play |
| 50 (max) | 294 | about 1 week |

"1 week" is read as a calendar week of a keen player, about 28 active hours (3 h a day plus what the village does while
they are away). If it means 168 hours of continuous play, the last ten levels end at about 8 h an upgrade.

## Zombie slimes (the owner's design)

- Outside the village, zombie slimes wait in at least 3 camps: the **player's average level**, **+3** and **+5**.
- The player walks out on the map, finds the group they want and attacks it, with **up to 4 squads of 4 slimes** a trip.
- **Every slime killed pays coins, on either side**, by its level and how rare it is. Rarer zombies pay more.
- Slimes can also be sold at the shop, by level and rarity.

Decided while working it out:
- **Player level** = the average of the strongest 16 slimes able to fight, so keeping weak slimes at home makes nothing
  easier. Ghosts and babies do not count.
- **One reward rule**: `base x (1 + level x 0.05)`, the original's sell formula, for kills, deaths and sales alike.
- **Three zombie kinds**: Rotten (base 100), Toxic (500), Plague (2,500), each needing its own look.
- **Harder camps hold more rare zombies** (Plague 1% / 5% / 15%). Without this the +5 camp paid *less* per minute than the
  easy one, and nobody would have a reason to go.
- **A camp's danger comes from its own strength number**, not its level. Stats tied to the level gave 0% wins at +3 for a
  level 4 squad and 100% at +5 for a level 40 squad. Now the +3 and +5 mean the same risk all game; the shown level sets the reward.

### Measured (300 fights each, even squads)

| Camp | Wins | Slimes lost a fight | Fight length | Coins a minute at level 4 / 20 / 60 |
|---|---|---|---|---|
| Same level | 100% | 0.1-0.3 | 20-24 s | 2,150 / 3,650 / 8,650 |
| +3 | 100% | 0.9-1.1 | 27-32 s | 3,550 / 5,850 / 13,000 |
| +5 | 41-59% | 2.9-3.1 | 37-42 s | 4,450 / 6,500 / 13,600 |

Squads in play will not be this even, and hungry or buffed slimes change it: a play test comes next.

## Death is for good (the owner, 2026-11-02)

- A slime killed in a fight pays its coins and lies dead for **15 minutes**. In that time the player may spend food to
  revive it (`ceil(1 + level / 5)` raw items from the storehouse, the original's cost). Otherwise it is **lost for good**.

Decided while working it out:
- **The 15 minutes run only while the player is online**: a crash or a night away never costs a slime.
- **A village never dies out**: when only 2 slimes are left, a dead one comes back by itself when its time runs out, as
  the shop never sells the last 2. Otherwise a player could end the game with no way to breed.
- A fight dropped by leaving the game simply ends, and nobody dies in it.

## Income and the price table

Permanent death makes **slimes what limits income**. A village replaces about 14 slimes an hour through breeding at the
start (24 from level 21, 32 from level 41) and has food for about 10 revives. Run out and fights stop paying, so the camps
became a real choice: the easy camp loses 0.2-0.3 slimes a fight, the middle one 1, the hard one 3 with about half the fights lost.

A team marches from its gate and back (26, 46 and 66 s each way to the three rings at starter SPD), fights, then waits for
its wounds. With that, fights earn about 32,000 coins an hour at the start, 84,000 at village level 19 and 206,000 at the
top. Selling a baby instead of sending it adds a little: the shop is the side income the owner described.

**2026-11-04, the early game (owner: "new players get bored, one fight pays about 600 and then the slimes rest").**
Measured with the real modules (`tools/balance/early_game_sim.luau`, one team on Repeat at camp 1): a fight pays about
800 all game, but a 4 minute cycle held 23 s of fighting. The rest was sleeping (37%: 14 minute naps every 10 fights), healing
(26%) and marching. Three in four slimes fell in each fight at camp 1, and each became a ghost to feed back to life. Changed:
- the prices of levels 1-19 halved, with level 25 easing into the old curve (the vault ceiling factor 3 -> 6 keeps it where it was);
- wounds heal in 30 s instead of 2 min;
- a fight costs 2 energy instead of 8, and a nap runs 10 a minute instead of 5;
- camp 1's zombies go from 0.75 to 0.62 of an even slime.

Result: village level 5 at 10 min (was 22), 10 at 30 min (was 75), 20 at 2.9 h (was 7.8). The cycle is now 129 s, and 0.05
slimes fall per fight. The time columns below are the earlier solve's.

| Area level | Price | One upgrade takes | Village level reached | At (active hours) |
|---|---|---|---|---|
| 1 | 150 | 30 s | 2 | 0.05 |
| 5 | 260 | 40 s | 6 | 0.2 |
| 10 | 550 | 1 min | 11 | 0.5 |
| 15 | 1,100 | 1.4 min | 16 | 1.3 |
| 19 | 1,700 | 1.9 min | 20 | **2.9** |
| 25 | 6,000 | 3 min | 26 | 3.5 |
| 30 | 14,000 | 4.7 min | 31 | 5.5 |
| 35 | 24,000 | 7 min | 36 | 8.5 |
| 39 | 37,000 | 10 min | 40 | **12.0** |
| 45 | 67,000 | 16 min | 46 | 20 |
| 49 | 99,000 | 23 min | 50 | **28** |

One area from 1 to 50 costs about 1,005,000 coins; the whole village about 6 million. These prices are solved against the
three incomes together (fights, slimes sold, dishes sold), see the next section; against fights alone the same prices would
give 2.5 h, 14.8 h and 35 h.

### What this table rests on (assumed, not measured)

- Teams run on repeat all the time; healing waits of 60, 90 and 120 s by ring. One real trip in play: 78 s out and back at the first ring, 63 s of healing.
- Squads a village can spare: 1 at first, 2 from village level 6, 3 from 15, 4 from 20.
- The strongest slimes reach level 8 at village level 10, 12 at 20, 20 at 30, 30 at 40, 40 at 50. Dying slimes pull this
  down and it has not been measured with deaths in it: the largest unknown here.
- The player picks the best-paying camp the village can afford to lose slimes in.

Real play will move these, and every price scales with them: measure in a play test, then run `price_curve.luau` again.

## What is measured about breeding (`income_sim.luau`)

Each pair lays about 9 eggs an hour (18 at 2 pairs, 31 at 3, 40 at 4); every run stayed fed with a full storehouse.
Without fights, a level 50 village would earn only about 2.2 times a level 1 village.

## Kitchen and the three incomes (measured)

`tools/balance/kitchen_sim.luau` runs the real `VillageSim` on a full village (`FarmKit.fullVillage`, productive fraction 0.55
as `food_sim` does, every kitchen slot staffed with a worker and a reserve), 4 h warm-up and 12 h measured. A script picks each
cook's recipe every minute: the best-priced unlocked recipe the stock can complete (`Stations.setCookRecipe`). Variant A: dishes
sold as they appear (`Shop.sellDish`). B: the same with the fighters' hunger (squads as in `price_curve`, 4 slimes each, 25 fights
an hour, `FightFullness` each; at levels 10 and 20 the village has fewer slimes than workers plus squads, so the fighters are what
is left: 7 and 15). C: slimes eat dishes (autoDish set to the most plentiful dish), nothing sold.

Dish prices (`DishRarities`): common 1,000, uncommon 1,100, rare 1,300, epic 2,000. Buffs: 4 / 6 / 9 / 12 %.

| Level | B: hungry (max) | B: dishes/h | B: coins/h from dishes | B: share of fights | A: share of fights | C: hungry, dishes eaten/h |
|---|---|---|---|---|---|---|
| 1 | 0 | 1.8 common | 1,833 | 5.8% | 8.4% | 0, 3 |
| 10 | 0 | 3.4 (3.1 uncommon) | 3,725 | 7.2% | 13.2% | 0, 6 |
| 20 | 0 | 4.2 (4.1 rare) | 5,400 | 5.2% | 18.9% | 0, 16 |
| 30 | 0 | 16.6 (16.1 rare) | 21,450 | 14.7% | 24.0% | 0, 32 |
| 40 | 0 | 23.8 (9.7 rare, 14.1 epic) | 40,733 | 22.9% | 22.9% | 0, 23 |
| 50 | 0 | 25.2 (9.1 rare, 16.2 epic) | 44,142 | 21.0% | 23.5% | 0, 29 |

Fights an hour (`income_model.luau`): 31,800 / 51,800 / 103,700 / 145,800 / 177,600 / 209,700. The lowest fullness any slime
reached was 50 (they eat at 50): nobody got near hungry (25) in A, B or C. Raw made an hour: 65 / 72 / 143 / 224 / 322 / 350;
eaten raw in B: 58 / 64 / 134 / 191 / 261 / 298. At levels 1-20 the slimes eat nearly all the raw, so the cooks have little
to spare: that is why dishes there are few and why the common dish is priced as high as 1,000.

All three incomes an hour (`price_curve.luau`; slimes from `income_sim`, 4 h runs, noisy):

| Area level | Fights | Slimes sold | Dishes (B) | Dishes % of fights | Vault (3 x price) | Vault / price | Vault fills in |
|---|---|---|---|---|---|---|---|
| 1 | 31,800 | 3,500 | 1,500 | 4.7% | 2,000 | 6.5 | 3.8 min |
| 10 | 51,800 | 9,400 | 4,000 | 7.8% | 3,300 | 3.0 | 3.8 min |
| 20 | 103,700 | 9,900 | 6,000 | 5.8% | 10,800 | 3.0 | 6.2 min |
| 30 | 145,800 | 11,400 | 20,600 | 14.1% | 42,000 | 3.0 | 17 min |
| 40 | 177,600 | 10,000 | 44,000 | 24.8% | 123,000 | 3.0 | 42 min |
| 49 | 206,500 | 13,600 | 42,800 | 20.7% | 297,000 | 3.0 | 86 min |

(Dish income between the measured levels is interpolated.) The vault is above the next upgrade price at every level 1-49 with the
pantry level equal to the others; the pantry may trail the other areas by 4-14 levels (about 8-11 from level 10) before its vault
falls under the next price. Road with the real prices and all three incomes: village 20 at 2.07 h, 40 at 11.96 h, 50 at 27.9 h.

Buffs on a squad (`fight_sim.luau`, 300 fights, even squads; "mixed" = the four slimes on attack, defence, speed, hp; the buff
lasts the whole fight). The +5 camp, which is 41-59% wins with no buff:

| Level | Epic mixed: wins, coins/min vs none | Epic all attack: wins, vs none | Epic all hp | Rare mixed | Common mixed |
|---|---|---|---|---|---|
| 4 | 73%, +9% | 87%, +31% | 82%, +13% | 73% | 69% |
| 20 | 67%, +16% | 79%, +34% | 79%, +20% | 62% | 50% |
| 60 | 76%, +23% | 83%, +37% | 82%, +22% | 70% | 59% |

Deaths a fight at +5 fall from about 3.0 to 1.9-2.4 (mixed) and 1.4-2.0 (all attack); the same camp at +3 and at the squad's level
stays at 100% wins, with income up 2-15%. Defence alone does nothing at +5 (0-11%).

### What remains assumed

- Fight income, squads a village can spare and slime levels (above); slime income is income_sim's, which swings with the odd Dual
  or Secret.
- 0.55 productive for the cooks too (a dish takes 1/0.55 as long). Fighters eat at home at the same rate as idle slimes and
  never walk off the village's food; their energy cost (8 a fight) is left out. One seed per run; the shares move a point or two
  between runs, level 20 in B (5.2%) the most. Level 1 in A and B sit above 5%, only just in B.
- The player always has a dish for the buff they want; in play they pick a recipe, not the best price.
- Food, not coins, limits dishes at levels 1-20: more fighters or more `FightFullness` take the dishes away first.

## Sources

- Prices grow by a fixed share while income grows more slowly: [The Math of Idle Games](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i),
  [Idle Idol's post-mortem](https://gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol) (11-19% a purchase).
- Not found: published retention or session figures for Roblox games of this kind, so nothing here rests on any.

## Build list

Done and seen in a MapWork play test (2026-11-02): camps, the squad sheet, a won and a lost fight, a revive (2 food), a slime lost
when its time ran out (the time cut to 40 s for that test only), a sale. The 15-minute length itself ran only in Lune.

1. Each zombie kind's own hit and death sprites (its skin is in: `art/models/slime_body/skins/z_*.png`, made by ChatGPT).
2. First-discovery rewards, if still wanted.
3. A real hour of play to measure fights, deaths and slime levels, then the numbers again.
