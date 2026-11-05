# Monetization, the Lucky Wheel and richer rewards

Approved by the owner on 2026-11-06 (the list and the prices below; a new product or a changed price is asked again,
skill `robux-products`). The owner changed the direction of `docs/DESIGN.md` §2: Robux now sells luck, VIP, gold and
team slots. Numbers live in `Config` (`Config.Robux`, `Config.Wheel`, `Config.Rewards`, `Config.Luck`).

## 1. Luck

Every luck *label* (Perm Luck, VIP, Luck Potion, server events) multiplies with the others; the product is turned into
the real factor on rare-baby chances by a falling curve: `real = 1 + PerDoubling * log2(label)` with
`Config.Luck.PerDoubling = 0.4` (each doubling of the label adds 40% of the base chance). The owner: "x8 does not mean an
8x rate, only higher than base". New-player luck (x5, then x3) stays a real factor outside the curve. The ChanceCap
stays. Perm Luck: only the highest tier owned counts.

| Has | Label | Real | Secret (base 1%) | Dual (base 4%) |
|---|---|---|---|---|
| nothing | x1 | x1.0 | 1% | 4% |
| Luck x2 | x2 | x1.4 | 1.4% | 5.6% |
| Luck x4 | x4 | x1.8 | 1.8% | 7.2% |
| Luck x8 | x8 | x2.2 | 2.2% | 8.8% |
| x8 + VIP | x12 | x2.4 | 2.4% | 9.7% |
| x8 + VIP + Potion | x24 | x2.8 | 2.8% | 11% |

The shop card names the label ("Luck x8") and one short line with the real effect ("Rare babies x2.2").

## 2. What is sold

Game passes

| Name | Robux | Gives |
|---|---|---|
| VIP | 249 | luck label x1.5, coins earned x1.5 (fights, slime and dish sales, rewards; never Robux gold), hatching x1.5 faster, +1 free wheel spin a day, a gold [VIP] chat tag and a small VIP badge over the head (as the Arena titles) |
| Luck x2 | 19 | Perm Luck label x2 |
| Luck x4 | 59 | Perm Luck label x4 |
| Luck x8 | 159 | Perm Luck label x8 |
| Extra Team | 99 | +1 team (the 5th) |
| Extra Team II | 149 | +1 more team (the 6th) |
| Bigger Ranch | 79 | +50 slime slots |

Teams: the village still opens teams 1-4 at levels 1/10/20/30; each team pass adds one on top of what the village has
opened, up to 6 (`Config.Zombies.Teams` = 6). The shop shows only the next team pass.

Developer products

| Name | Robux | Gives |
|---|---|---|
| Pouch of Gold | 29 | coins = 2 x the village's cheapest next upgrade (`Rewards.coinBase`) |
| Sack of Gold | 89 | 7 x |
| Chest of Gold | 199 | 18 x |
| Vault of Gold | 499 | 50 x |
| Lucky Spin | 25 | 1 spin |
| Spin Bundle | 99 | 5 spins |
| Spin Crate | 199 | 12 spins |
| Luck Potion | 29 | luck label x2 for 30 min, added to the time left |
| Gold Potion | 29 | coins earned x2 for 30 min |
| Hatch Potion | 19 | hatching x2 faster for 30 min |
| Energy Drink | 19 | every slime's energy full |
| Hatch All Now | 19 | every egg in an incubator or nest hatches now |
| Quest Reroll | 9 | redraw one daily quest (one free redraw a day) |
| Streak Saver | 19 | mends a check-in run broken by one missed day (offered only the day after the miss) |
| Starter Pack | 49 | once an account: 5 spins, a Sack of Gold's coins, Luck Potion 60 min, 5 Iron Ore |

Bonus and "Save n%" labels are computed from the real prices of the smallest pack, never written by hand. Names on the
Creator Hub have no digits. Bought spins are paid random items: the wheel's odds are shown before a buy, and spin
products are hidden from players whose `PolicyService` restricts paid random items.

Outside the shop (the owner's Creator Hub settings): private servers 50 Robux a month; Roblox Premium players +10% coins.
Cosmetics: §6. Later: gifting.

## 3. The Lucky Wheel

- Spins: 1 free a day (UTC day, lost if not used), VIP +1 free a day; the 60-minute online gift gives one spin (once a
  day); check-in days, quests, the wheel itself and Robux add spins to a bank that never runs out.
- The server rolls the prize first; the client turns the wheel to that slice. The odds are on the wheel's screen.

| Slice | Chance |
|---|---|
| Coins, small (0.5 x coinBase) | 26% |
| Coins, big (1.5 x) | 14% |
| Food basket | 14% |
| Luck Potion 20 min | 12% |
| Iron Ore x5 | 10% |
| Core Fragment x3 | 9% |
| +1 spin | 7% |
| Monster Core x1 | 5% |
| JACKPOT: coins 5 x + Boss Essence + Luck 60 min | 3% |

## 4. Rewards

A reward can pay coins, luck minutes, spins, food, dishes, dungeon materials and gear.

- Check-in, 7 days: 1 coins 0.5 + food basket; 2 coins 0.75 + 1 spin; 3 coins 1 + Iron Ore x5; 4 luck 30 + Core
  Fragment x2; 5 coins 1.5 + 2 spins; 6 coins 2 + Monster Core; 7 coins 3 + luck 60 + 3 spins + Monster Core x2.
  Milestones of total check-ins 14 / 30 / 60 / 100 (30: the charm-core gear).
- Online, 9 gifts: 1' coins, 3' food, 5' coins, 10' luck 10, 15' Iron Ore x3, 20' coins, 30' Core Fragment + luck 10,
  45' coins + a dish, 60' coins + 1 spin.
- Daily quests: 4 a day (easy, medium, medium, hard), one free redraw, coins + items; all 4 claimed: 1 spin + luck 20.
  New kinds beside the old six: dungeon waves, arena attacks, gear crafted, dishes cooked, fish caught, crops harvested,
  a new kind of slime found, wheel spins, minutes played.
- Weekly quests: 5 a UTC week (Monday, as the Arena), paying spins, Monster Cores, Boss Essence; all 5: the Weekly Chest.
- Goals (for ever): hatch 10/50/200/1000 eggs, find 10/25/50/100/150 kinds, village level 10/20/30/40/50, sell
  10/100/500 slimes, dungeon best level, ... each paid once. A "Goals" tab in Rewards.

## 5. Build order

1. Rewards with items, the new check-in, online gifts, quests, weekly quests, goals (save schema 12).
2. The Lucky Wheel.
3. The Robux core: catalog in `Config.Robux` (id 0 = SOON), `server/Purchases` (receipts granted once, through
   `PlayerData`), pass effects, potions, the VIP Shop with tabs, the VIP tag.
4. Products created on the Creator Hub after the code, icons from ChatGPT, ids filled in, the owner's own test buys.
5. Cosmetics (§6).

## 6. Cosmetics: Wings, Auras, Trails (the owner, 2026-11-06)

Visual only: a slime wears up to one Wings, one Aura and one Trail; nothing changes a stat. Each item is its OWN design
(own sprites or mesh, motion and burst; one effect recoloured is not a new item), from the owner's VFX packs, ChatGPT
textures and Blender wings, made with skill `roblox-vfx-craft`, cheap on phones: drawn only on slimes near the camera,
an emitter budget, off under a low effects setting.

- Owned as copies in a wardrobe (`farm.cosmetics`); a copy is worn by one slime; taking it off, selling or losing the
  slime puts it back (as gear does). Three style slots on the slime's page beside the gear slots.
- Where they come from: the gold shop (a "Style" tab of the VIP Shop, open from village level 15, the mid game),
  rare rewards (the wheel's Style Box slice, the dungeon boss, the Weekly Chest), and Robux (the Legendary ones).
- Gold prices are set by the balance-tester as hours of mid-game income: Common about 1 h, Rare about 4 h.

| Item | Kind | Tier | From |
|---|---|---|---|
| Leaf Wings | Wings | Common | gold |
| Butterfly Wings | Wings | Rare | gold |
| Fairy Wings | Wings | Rare | gold |
| Bat Wings | Wings | Epic | dungeon boss (rare drop) |
| Angel Wings | Wings | Epic | wheel Style Box, Weekly Chest |
| Phoenix Wings | Wings | Legendary | Robux 199 |
| Crystal Wings | Wings | Legendary | Robux 199 |
| Sparkle Aura | Aura | Common | gold |
| Bubble Aura | Aura | Common | gold |
| Heart Aura | Aura | Rare | gold |
| Flame Aura | Aura | Epic | dungeon boss (rare drop) |
| Frost Aura | Aura | Epic | wheel Style Box, Weekly Chest |
| Galaxy Aura | Aura | Legendary | Robux 149 |
| Rainbow Aura | Aura | Legendary | Robux 149 |
| Flower Trail | Trail | Common | gold |
| Goo Drip Trail | Trail | Common | gold |
| Star Trail | Trail | Rare | gold |
| Lightning Trail | Trail | Epic | dungeon boss (rare drop) |
| Rainbow Trail | Trail | Legendary | Robux 99 |
| Comet Trail | Trail | Legendary | Robux 99 |

The wheel gains a "Style Box" slice (2%, taken from the small coins slice) that gives one Epic item of the box's
list, shown with its odds. Robux items are developer products (one more copy each buy).
