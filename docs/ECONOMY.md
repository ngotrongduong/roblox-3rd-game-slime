# Economy: how money is earned and what upgrades cost

Research for the owner's targets (2026-11-02). Nothing here is in the game yet except the rules named under "Today".
Numbers come from `tools/balance/income_sim.luau` (the real `VillageSim`) and `tools/balance/price_curve.luau`.

## The owner's road

| Village level | Upgrades bought (6 a level) | Play time |
|---|---|---|
| 20 | 114 | about 2 h |
| 40 | 234 | about 12 h of continuous play |
| 50 (max) | 294 | about 1 week |

"1 week" is read here as a calendar week of a keen player: about 3 h a day (21 h), plus what the village makes while
they are away, worth about 7 h more: **28 active hours**. If it means 168 hours of continuous play instead, the last ten
levels take about 8 h an upgrade by the end and cost up to about 700,000 coins each (a rough sum), which reads as a wall.

## Today

- **There is no way to earn a coin.** `Mutations.sellValue` exists but no shop, remote or UI uses it; fights come in a
  later phase; `Config.Pads.FreeUpgrades = true` keeps every price at 0.
- Prices if switched on (`Village.upgradeCost`): 100 to 20,000, the original's curve. Measured income makes level 1 take
  about 16 minutes an upgrade at today's sell values, and the whole road about 245 h: far too slow, above all early.

## Measured: selling every baby the moment it hatches

Plain parents of different colours, level 4 babies, 6 simulated hours, every food slot staffed.

| Village level | Pairs | Eggs/hour | Coins/hour (sell values as now) | Lowest fullness |
|---|---|---|---|---|
| 1 | 2 | 18 | 380 | 51 |
| 10-11 | 2 | 18-20 | 1,100-1,300 | 50 |
| 20 | 2 | 20 | 500 | 50 |
| 21-30 | 3 | 31 | 1,400-1,550 | 50-52 |
| 40 | 3 | 31 | 1,300 | 51 |
| 41-50 | 4 | 40-41 | 1,400-1,800 | 50-51 |

What this says:
1. **Eggs are the income, and only breeding places raise them**: 9 eggs an hour a pair, held back by rest and energy.
   Upgrades otherwise barely raise income: a village at level 50 earns only about 2.2 times a village at level 1.
2. **A Secret decides a whole run**: 1% of eggs, worth 1,200 of the roughly 33 coins an average egg pays, so runs of the
   same length differ by more than 3 times. The table's bumps are Secrets, not levels.
3. **Food does not limit breeding**: every run stayed fed with a full storehouse, so the pond and garden earn nothing
   beyond feeding the village.
4. **Better parents are the real lever, and they need no new system**: by `Config.Inheritance`, a Dual pair pays about
   105 coins an egg against 33, a Secret pair about 230, and each slime level adds 5%. So choosing parents is what makes
   a player richer, which suits a breeding game.

## What other games teach

- Prices grow by a fixed percentage while income grows much more slowly, and that is what makes each purchase take longer
  ([Math of Idle Games](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)). Rates of 7-15% a purchase
  are usual ([Idle Idol's post-mortem](https://gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol)
  reports 11-19%). Our upgrade times come out growing 4-12% a level, gentler since a level here is six purchases.
- Model it rather than design it by feel, and track what flows in against what flows out
  ([a game economy design guide](https://openskillindex.com/skills/alterlab-ieu-alterlab-gameforge-game-economy-designer);
  a low-authority source, used only for the idea).
- Not found: published retention or session-length figures for Roblox games of this kind, so nothing here rests on any.

## Recommendation

**Where money comes from**
1. **The slime shop in the Market** (the main source, now): the original's rules: not a favourite, not at work, keep at
   least 2 slimes, Duals, Secrets and materials ask first.
2. **First discovery in the book** (new, one time each): coins for the first Dual, Secret or material of each kind. It
   rewards the collection, softens bad luck, and gives a reason not to sell everything. Sized when it is built.
3. **Fights in the Wild Garden** (`docs/GAMEPLAY.md` §8, in their own phase): when they arrive, prices must go up by what
   they pay, or the road gets shorter. Run `price_curve.luau` again then.
4. Not now: selling surplus food (a full village has only about 100 items an hour to spare, a small sum, and it invites
   starving the village), daily rewards, and rebirth. Robux stays out until Launch and never pays to win.

**Sell values x10** (plain 100, Dual 1,000, Secret 10,000, materials 1,500 / 3,000 / 8,000). Otherwise the first upgrades
would cost 13 coins. A level 4 baby then sells for 120: about one upgrade at the start.

**Prices**, one table in `Config`, the same for every area:

| Area level | Price | One upgrade takes | Village level reached | At (active hours) |
|---|---|---|---|---|
| 1 | 130 | 29 s | 2 | 0.05 |
| 5 | 230 | 38 s | 6 | 0.3 |
| 10 | 360 | 68 s | 11 | 0.7 |
| 15 | 400 | 2 min | 16 | 1.3 |
| 19-20 | 400 | under 2 min | 20 | **about 2** |
| 25 | 1,100 | 2.5 min | 26 | 3.2 |
| 30 | 2,300 | 4 min | 31 | 4.9 |
| 35 | 4,800 | 8 min | 36 | 8 |
| 39-40 | 9,700 | 13 min | 40 | **about 12** |
| 45 | 19,000 | 16 min | 46 | 21 |
| 49 | 26,000 | 19 min | 50 | **28** |

One area from 1 to 50 costs about 252,000 coins; the whole village about 1.5 million. Prices stay flat from about level
12 to 20 because the new-player luck (x5, then x3, first hour) pays for the early levels at 2-3 times the normal rate.

## What the road rests on (not measured)

- Online slimes lose a fifth of their egg rate to walking: `income_sim` has no walking. A play test of a real hour is the
  first thing to do once the shop exists; every price scales with this.
- Coins an egg rise as players pick better parents: 330 at level 1, 600 at 10, 1,000 at 20, 1,500 at 30, 2,000 at 40, 3,000
  at 50 (sell values x10). A player who keeps plain parents goes far slower, and one who sells only spares is slower too.
- The player sells every plain baby at once. Keeping slimes for the collection costs time, which is a choice they make.
- A lucky Secret sold at level 15 pays for about 30 upgrades. That is left in as a happy moment; it can be cut with the
  Secret's sell value alone.

## Build list, once approved

1. `Config`: sell values x10, the price table; `Village.upgradeCost` reads it; existing tests follow.
2. Sell remote on the server with the rules above, tested in Lune; shop UI in the Market.
3. First-discovery rewards.
4. `Config.Pads.FreeUpgrades = false` (the owner's switch: until now he kept prices at 0).
5. A real hour of play to measure the egg rate, then `price_curve.luau` again.
