# Village food balance — 2026-10-30

## Decision and constraints

The owner wants **60–80 slimes at maximum upgrades**, not 216. The new level-50
population cap is **70** (12 at village level 1; +1.2 per level, rounded down).
Breeding and hatching already use `FarmState.populationLimit`, so eggs count toward
that same cap. The work slots remain unchanged: **4 fishing, 4 gardening, 4
cooking, 4 training**, plus **4 breeding pairs = 8 parents** when the relevant areas
have reached their milestones. This is up to 24 assigned adults (16 work
positions + 8 breeding places), leaving 46 adults for hauling and village life
at cap; reserve workers are *additional assignments*, not concurrent producers.

**Safety for existing saves:** `FarmState.repair` already retains up to
`Config.Farm.RepairSlimeHardCap` validated slimes, regardless of the current
population limit. Do not truncate previously earned slimes after lowering the
birth cap. An existing profile with more than its new cap can continue playing,
but cannot lay new eggs until it has free capacity. The future slime shop
should make downsizing possible voluntarily.

## Producer/consumer budget (SPD = 1)

All values below are theoretical *steady-state upper limits*, not measured
Roblox Studio throughput. No speed bonus, cooked dishes, baby discount or
automatic free food is counted. At a full population, count every configured
work position as occupied (including kitchen/training, which eat but do not
supply raw food). Sleeping and travel reduce actual output; couriers, storage
and bin congestion may also limit throughput. Thus the production margin is
deliberately greater than 1.

- Per-minute hunger: **1.25** idle, **1.9** working (previously 2 and 3).
- Fishing: **1 catch per 50 seconds** (previously 60).
- Gardening: **12.5 seconds per action** (previously 13.5);
  one vegetable needs roughly **six actions** (hoe, plant, water three times,
  harvest) plus growth and walking.
- Weighted raw food value from `Config.Food.Kinds`: **21.64 fullness/fish**
  and **21.08 fullness/vegetable** on average.
- Fishing and gardening production speed both benefit from the existing
  per-area level cycle factor; SPD bonuses are excluded.

| Village level | Population limit | Work slots/area | Ideal raw fullness/min | Demand/min at full work occupancy | Ideal ratio |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 12 | 1 | 42.8 | 17.6 | 2.43 |
| 10 (before 2nd slot) | 22 | 1 | 46.9 | 30.1 | 1.56 |
| 11 | 24 | 2 | 94.7 | 35.2 | 2.69 |
| 20 (before 3rd slot) | 34 | 2 | 103.7 | 47.7 | 2.17 |
| 21 | 36 | 3 | 157.1 | 52.8 | 2.98 |
| 30 (before 4th slot) | 46 | 3 | 172.0 | 65.3 | 2.63 |
| 31 | 48 | 4 | 231.6 | 70.4 | 3.29 |
| 40 | 58 | 4 | 253.5 | 82.9 | 3.06 |
| 41 | 60 | 4 | 256.1 | 85.4 | 3.00 |
| 50 | 70 | 4 | 280.4 | 97.9 | 2.86 |

The narrowest paper margin is **level 10**. It is more important to test the
transition just before a work-slot unlock than simply test level 50.

## Kitchen anti-waste rule

Cooked dishes are **opt-in**, not communal food. Previously a kitchen could
remove raw fish/vegetables from the pantry even when no slime could eat the
resulting dishes. Now `Food.canPrepare` requires a staffed kitchen and at
least one opted-in eater. Prepared dishes in the fridge **and** kitchen output
box count against a limit of two meals per eater (capped by fridge capacity).
`Food.ingredientsWanted` stops transferring raw ingredients when this
budget is full. It does not delete existing dishes or meals in transit.

## Acceptance and unknowns

`tests/spec/food_balance.luau` checks theoretical production margin at
levels 1, 10, 11, 20, 21, 30, 31, 40, 41, 50 and tests two hours of offline
production with full SPD-1 populations. It is not a substitute for Studio
testing. In Studio, measure the actual 20-minute rolling fish/vegetable
handoffs at level 10 with one fisher and one gardener, the percentage of time
workers rest or carry, available couriers, food consumed per minute, bin/full
store pauses and food remaining after two hours. Confirm players can maintain
needs even without any cooked-food permission. If poor pathing or hauling makes
actual throughput lower than modelled, fix that bottleneck before further
increasing raw yield.
