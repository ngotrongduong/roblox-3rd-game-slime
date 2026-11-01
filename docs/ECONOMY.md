# Economy: how money is earned and what upgrades cost

The owner's design (2026-11-02), worked out and measured. Playable in MapWork: zombies on the map, sending squads, fights,
coins for each death, revive, loss for good, the shop (rules in `src/shared/Combat`, `Zombies`, `Shop`; `src/server/ZombieFights`;
`src/client/Zombie*`, `UiSquad`). **Not in yet: the price table.** `Config.Pads.FreeUpgrades = true` still keeps every upgrade at 0, and no
coin can be earned yet. Tools: `tools/balance/fight_sim.luau`, `income_sim.luau`, `price_curve.luau`.

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

Fights earn about 44,000 coins an hour at the start, 102,000 at village level 19 and 263,000 at the top. Selling a baby
instead of sending it adds a little: the shop is the side income the owner described.

| Area level | Price | One upgrade takes | Village level reached | At (active hours) |
|---|---|---|---|---|
| 1 | 360 | 30 s | 2 | 0.05 |
| 5 | 530 | 40 s | 6 | 0.3 |
| 10 | 1,000 | 1 min | 11 | 0.7 |
| 15 | 2,300 | 1.5 min | 16 | 1.3 |
| 19 | 3,200 | 2 min | 20 | **2.0** |
| 25 | 7,900 | 3 min | 26 | 3.5 |
| 30 | 13,000 | 4.5 min | 31 | 5.5 |
| 35 | 23,000 | 7 min | 36 | 8.5 |
| 39 | 34,000 | 10 min | 40 | **12.0** |
| 45 | 67,000 | 16 min | 46 | 20 |
| 49 | 99,000 | 23 min | 50 | **28** |

One area from 1 to 50 costs about 980,000 coins; the whole village about 5.9 million.

### What this table rests on (assumed, not measured)

- A squad is out fighting half the time while the player also runs the village.
- Squads a village can spare: 1 at first, 2 from village level 6, 3 from 15, 4 from 20.
- The strongest slimes reach level 8 at village level 10, 12 at 20, 20 at 30, 30 at 40, 40 at 50. Dying slimes pull this
  down and it has not been measured with deaths in it: the largest unknown here.
- The player picks the best-paying camp the village can afford to lose slimes in.

Real play will move these, and every price scales with them: measure in a play test, then run `price_curve.luau` again.

## What is measured about breeding (`income_sim.luau`)

Each pair lays about 9 eggs an hour (18 at 2 pairs, 31 at 3, 40 at 4); every run stayed fed with a full storehouse.
Without fights, a level 50 village would earn only about 2.2 times a level 1 village.

## Sources

- Prices grow by a fixed share while income grows more slowly: [The Math of Idle Games](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i),
  [Idle Idol's post-mortem](https://gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol) (11-19% a purchase).
- Not found: published retention or session figures for Roblox games of this kind, so nothing here rests on any.

## Build list

Done and seen in a MapWork play test (2026-11-02): camps, the squad sheet, a won and a lost fight, a revive (2 food), a slime lost
when its time ran out (the time cut to 40 s for that test only), a sale. The 15-minute length itself ran only in Lune.

1. Each zombie kind's own hit and death sprites (its skin is in: `art/models/slime_body/skins/z_*.png`, made by ChatGPT).
2. The price table in `Config`, then `FreeUpgrades = false` at the owner's word.
3. First-discovery rewards, if still wanted.
4. A real hour of play to measure fights, deaths and slime levels, then the numbers again.
