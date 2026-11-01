# Economy: how money is earned and what upgrades cost

The owner's design (2026-11-02), worked out and measured. Built so far: the fight and reward rules in `src/shared`
(`Combat`, `Zombies`, `Config.Combat`, `Config.Zombies`) with Lune tests, and sell values x10. **Not built: the zombies on
the map, sending squads, the shop, the prices.** `Config.Pads.FreeUpgrades = true` still keeps every upgrade at 0, and no
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
| Same level | 100% | 0.6-0.9 | 25-29 s | 1,900 / 3,300 / 7,600 |
| +3 | 88-95% | 1.6-1.9 | 32-37 s | 3,050 / 4,900 / 10,800 |
| +5 | 23-36% | 3.2-3.6 | 36-41 s | 3,800 / 5,800 / 12,000 |

Squads in play will not be this even, and hungry or buffed slimes change it: a play test comes next.

## The open question: how long a dead slime stays dead

`docs/GAMEPLAY.md` §8 and `Config.Village.GhostSeconds` say **1 day**, written before this design. It cannot stand:
at village level 20, four squads in the middle camp lose about 180 slimes an hour against a population of 27, so every
slime would be a ghost within minutes and fights would stop for the day.

**Recommended: 2 minutes** (about 6 of the 27 out at a time). A longer wait is still a cost, and more deaths need more
breeding, which keeps the farm feeding the fights. The number is one value in `Config`.

## Income and the price table

Fights are the main income: 52,000 coins an hour at the start, 190,000 at village level 19, 460,000 at the top. Selling
babies adds about 4,000 at the start, so the shop is the side income the owner described.

| Area level | Price | One upgrade takes | Village level reached | At (active hours) |
|---|---|---|---|---|
| 1 | 430 | 30 s | 2 | 0.05 |
| 5 | 620 | 40 s | 6 | 0.3 |
| 10 | 2,000 | 1 min | 11 | 0.7 |
| 15 | 4,400 | 1.5 min | 16 | 1.3 |
| 19 | 6,000 | 2 min | 20 | **2.0** |
| 25 | 15,000 | 3 min | 26 | 3.5 |
| 30 | 25,000 | 5 min | 31 | 5.5 |
| 35 | 42,000 | 7 min | 36 | 8.5 |
| 39 | 65,000 | 10 min | 40 | **12.0** |
| 45 | 120,000 | 17 min | 46 | 20 |
| 49 | 170,000 | 22 min | 50 | **28** |

One area from 1 to 50 costs about 1.8 million coins; the whole village about 10.7 million.

### What this table rests on (assumed, not measured)

- A squad is out fighting half the time, about 27 fights an hour, while the player also runs the village.
- Squads a village can spare: 1 at first, 2 from village level 6, 3 from 15, 4 from 20.
- The strongest slimes reach level 8 at village level 10, 12 at 20, 20 at 30, 30 at 40, 40 at 50.
- Players mostly use the middle camp.

Real play will move these, and every price scales with them: measure in a play test, then run `price_curve.luau` again.

## What is measured about breeding (`income_sim.luau`)

Each pair lays about 9 eggs an hour (18 at 2 pairs, 31 at 3, 40 at 4); every run stayed fed with a full storehouse.
Without fights, a level 50 village would earn only about 2.2 times a level 1 village.

## Sources

- Prices grow by a fixed share while income grows more slowly: [The Math of Idle Games](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i),
  [Idle Idol's post-mortem](https://gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol) (11-19% a purchase).
- Not found: published retention or session figures for Roblox games of this kind, so nothing here rests on any.

## Build list

1. The zombies on the map: camps around the player's plot, respawning; three looks (`art-pipeline`).
2. Sending squads: remote and rules on the server, fights run on the server, coins on the receipt of each death.
3. The squad picker and the fight drawn on the client.
4. The shop in the Market (the original's rules: not a favourite, not at work, keep 2, rare ones ask first).
5. The price table in `Config`, then `FreeUpgrades = false` at the owner's word.
6. A real hour of play, then the numbers again.
