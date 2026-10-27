# Goo Lineage — Battle Reference Spec (for the Roblox rebuild)

Reverse-engineered from the original web game source in `reference/goo-lineage-web/` (read as data, never executed).
Every number below is copied from the source. The source file is given in brackets, for example `[battle/config.js]`.
All file paths are relative to `reference/goo-lineage-web/`.

Units used by the original:
- **px**: 2D world pixels. The battlefield centre (the "rally point") is (0, 0). +x is right and +y is DOWN (screen space).
- **s**: simulation seconds (`combat.simTime`). Every timer, cooldown and status runs on sim time, never wall-clock time.
- Stats: `attack` (ATK), `defence` (DEF), `speed` (SPD), `hp` (max HP). All are integers on the farm.

Contents
1. Game modes and unlocks
2. Team rules
3. Run lifecycle (state machine)
4. Maps, rotation and arena layout
5. Waves
6. Level ladder and scaling
7. Enemy roster
8. Combat model (kernel)
9. Squad weapon classes (AI and skills)
10. Enemy AI, boss kits and the level-2 skill kits
11. AVENGE, statuses, crits and elements
12. World bosses
13. Loot and the reward ledger
14. Equipment
15. Crafting
16. Revival and fallen slimes
17. Loadout, auto-equip and quick team
18. HUD, presentation, FX and animation timing
19. Quirks and probable bugs in the original
20. Notes for Roblox

---

## 1. Game modes and unlocks

| Mode | What it is | Unlock rule | Source |
|---|---|---|---|
| **Slime Siege** | A 10-wave ladder against map mobs (mini-boss at wave 5, boss at wave 10), repeatable at rising "levels". | At least one farm slime, or the player's avatar, has level ≥ **30**. | `SLIME_SIEGE.unlockSlimeLevel` [battle/config.js]; `siegeUnlocked()` [battle/run.js] |
| **World Boss: King Goo** | A single-encounter raid on the "Crystal Throne" map. | Farm slime capacity ≥ **50** (`slimePopulationLimit`). | `WORLD_BOSS.unlockSlimeCap` [battle/worldboss.js] |
| **World Boss II: Queen Nyx** | A single-encounter raid on the "Eclipse Garden" map. | `farm.wbKingSlain === true` (the king has been killed at least once). | `queenUnlocked()` [battle/worldboss.js] |

- Slime level = `floor(attack + defence + speed + hp/10)` [stats.js `calculateLevel`]. A starter slime is 1/1/1/10, so level 4.
- Slime capacity = `20 + 5 × slimeStorage upgrade level`, with the upgrade capped at 40 levels [upgrades.js, config.js `POPULATION_LIMIT = 20`]. The World Boss therefore needs 6 levels of "More Slime Slots". Upgrade price: `rampCost(level, 40)`, a geometric ramp from 100c to 20,000c, rounded to 10.
- The team panel always shows both tabs. A locked tab shows a padlock, the unlock text and a progress bar [battle/teamPanel.js]:
  - Siege: best level / 30.
  - World Boss: slime slots / 50.
- The avatar's stats: base 1/1/1/10, plus 5 stat points per avatar "rank". One rank is earned per 50 slimes hatched. 1 point in HP = +10 HP [avatar.js `AVATAR`].

## 2. Team rules

| Rule | Siege | World Boss raid | Source |
|---|---|---|---|
| Squad size | 1–10 | 1–20 (`worldBossSquadMax`) | [battle/config.js], [battle/worldboss.js] |
| Hand item required | Yes, except the avatar (it fights unarmed as `body`) | No. Unarmed slimes fight as `body` brawlers. | `eligibleSlime()` [battle/run.js] |

A slime is ineligible for either mode, and is simply not listed, when any of these is true [battle/run.js `eligibleSlime`, battle/teamPanel.js]:
- It no longer exists (`MISSING_SLIME`).
- It is already deployed (`ALREADY_DEPLOYED`).
- It is assigned to a workstation (`WORKING`).
- It is on a breeding cooldown, `breedReadyAt > now` (`BREEDING`).
- It is fallen (`FALLEN`).

The avatar skips all of these checks and is always eligible.

- **Role comes from the Hand item.** The item's `weaponBehaviourId` decides which AI the unit runs: `sword`, `bow`, `healing_staff`, `shield`, `arcane_focus` or `alchemy_kit`. With no Hand item the behaviour is `body`, which is only allowed for raids and for the avatar [battle/teamPanel.js start handler, battle/run.js `start`].
- **Battle stats** = the slime's base stats + the flat bonuses of every equipped item [battle/loadout.js `battleStats`]:
  - Farm slimes count head, hand and tail.
  - The avatar counts head, hand, tail, back, wings and aura. Wings and aura give no bonuses.
- **The last team is remembered** as `farm.lastSiegeTeam`. It is restored when the panel opens, and picks that are no longer eligible drop out [battle/teamPanel.js].
- **Quick team** selects the highest-level eligible slimes, up to the mode cap of 10 or 20 (section 17).
- **Auto-equip** button: section 17.
- **Locks during a run.** Deployed slimes are locked. Every equipped item (head, hand, tail, back) moves to ownership `BATTLE_ESCROW` and cannot be equipped elsewhere (`ITEM_IN_BATTLE_ESCROW`) [battle/run.js, battle/loadout.js].

## 3. Run lifecycle (state machine)

The run manager is `BattleRun` [battle/run.js]. Phases:

```
TEAM_SETUP → COUNTDOWN (1.0 s) → WAVE_ACTIVE ⇄ WAVE_CLEARED (2.5 s interlude) → … → VICTORY
                                     │                                                   │
                                     └──── squad wiped ──► DEFEAT          Next / Replay ─┘ (back to COUNTDOWN)
any phase ── Retreat / Return ──► RETURN_TO_FARM (endRun)
```

### Start (`start()`)
1. Validate the squad size against the mode cap.
2. Create the IDs:
   - `runId = "run-<now>-<int>"`
   - `seed = now % 2147483647`, where `now` is epoch ms.
3. Snapshot every slime's loadout and `startingStats = battleStats()`.
4. Collect every equipped item ID into the escrow set.
5. Assign formation positions (section 4).
6. Choose the map:
   - Raid: `eclipse` for the queen, `worldboss` for the king.
   - Siege: `BATTLE_MAPS[floor(mulberry32(seed + 77)() × 4)]`. The first map is seeded-random.
7. Build the combat state: `{ seed, simTime: 0, units, events, over: false, level: 1 }`.
8. Create the squad units (section 8).
9. Create a new `WaveDirector` and `RewardLedger(runId)`. Set `level = 1`, `round = 1` and `currentWave = 0`.
10. Set phase `COUNTDOWN` with `countdownLeft = 1.0`.

### Per tick (`stepCombat`, called at a fixed `dt = 1/30` s)
- **COUNTDOWN.** `simTime += dt`. When the countdown reaches 0, start wave 1 with `levelPowerMult(level)` and go to `WAVE_ACTIVE`.
- **WAVE_CLEARED.** Count down `wavePauseLeft`, which starts at 2.5 s. When it reaches 0, call `continueRun()`:
  - If the mode is a raid, or `currentWave >= 10`, go to `VICTORY`.
  - Otherwise `currentWave++`, start the next wave and go to `WAVE_ACTIVE`.
- **WAVE_ACTIVE.**
  1. `director.tick()` spawns queued enemies.
  2. The combat kernel takes one step.
  3. For each enemy `fallen` event:
     - Increment the kill counters: `killsMobs` always, `killsBosses` when `role === 'boss'`.
     - Record loot (section 13).
  4. If the squad is wiped (`combat.over`):
     - Discard the unfinished wave's loot.
     - In a raid, pay the consolation coins (section 12).
     - Go to `DEFEAT`.
  5. Else if the wave is cleared (spawn queue empty and no enemy alive):
     - Commit this wave's ledger.
     - Set `wavePauseLeft = 2.5` and go to `WAVE_CLEARED`.

### VICTORY and the next round (`startNextRound(mode)`)
- The victory panel appears 2.2 s after `VICTORY`, so the celebration plays first [game.js]. Its buttons:
  - **▶ Next Level N+1**: `level += 1`, and the map rotates to the next map in the cycle.
  - **↻ Replay Level N**: same level, same map.
  - **🏡 Return to Farm**.
- The raid has no ladder. Its victory panel only offers Return.
- Every next round, `round += 1` in both cases:
  - Enemy corpses are removed.
  - **Survivors heal to full HP** and return to their formation spots.
  - Statuses and targets are cleared. `attackCd = 0.5`, `areaCd = 0`, and skills are staggered again with `skillCd = 1.5 + i × 0.6`.
  - **Fallen squad slimes stay fallen for the rest of the run**, except the avatar, which always stands back up.
  - `simTime` is **not** reset. It stays monotonic so enemy and reward IDs never repeat.
  - Then `COUNTDOWN` runs again.
- **HP carries over between waves** inside a round. There is no healing between waves except from skills.

### DEFEAT
- The squad is wiped. The battle stays on screen with "DEFEAT", or "THE KING PREVAILS…" / "THE NIGHT PREVAILS…" in a raid.
- There is no panel. The player taps **Retreat** to go home [game.js, battle/hud.js].

### Retreat or Return (`retreat()` → `endRun()`)
- Retreat is allowed in any phase. It discards the provisional loot of the current ledger wave; committed waves are kept.
- `endRun()` is atomic:
  1. Every deployed **farm** slime whose combat unit ended `FALLEN_IN_BATTLE` gets these changes:
     - `fallen = true`. This flag is sticky.
     - `previousLoadout` = its loadout.
     - Its loadout is cleared, so its gear becomes free inventory.
  2. Every escrowed item returns to `INVENTORY` exactly once. Then `reconcileItemOwnership()` re-stamps the survivors' gear as equipped.
- The avatar is never marked fallen on the farm, because it is not in `farm.slimes`.
- After the run [game.js `endBattleRun`]: autosave immediately, music → `farm`.

## 4. Maps, rotation and arena layout

| mapId | Player name | Enemy theme | Map material | Source |
|---|---|---|---|---|
| `meadow` | Sunny Meadow | `greenfield` | `boar_tusk` | [battle/run.js `MAP_NAMES`, `themeForMap`], [battle/loot.js `MAP_MATERIAL`] |
| `mushroom` | Mushroom Grove | `darkforest` | `glow_spore` | " |
| `lava` | Volcano | `volcano` | `ember_scale` | " |
| `ice` | Snowy Peak | `ice` | `frost_crystal` | " |
| `worldboss` | Crystal Throne | `worldboss` | none | " |
| `eclipse` | Eclipse Garden | `eclipse` | none | " |

- **Rotation** for siege "Next Level": `meadow → mushroom → lava → ice → meadow …` [battle/run.js `BATTLE_MAPS`, `nextMapId`]. The first map of a run is seeded-random.
- **Map exclusivity.** Each map spawns only its own theme's mobs.
- A `classic` enemy set exists (swarmer, brute, …) but no map uses it any more. It is only the fallback boss for unknown themes.
- **Sim bounds**: x ∈ [-520, 520], y ∈ [-300, 300] px, which is 1040 × 600. Every move is clamped to these bounds [battle/config.js `COMBAT.bounds`].
- **Render field**: 1200 × 700 px, fit-scaled × 0.92. A full-screen map picture sits behind it, cover-scaled [battle/scene.js `BATTLEFIELD`]. Map art: `assets/battle.map.<mapId>.png`.
- **Siege formation** [battle/run.js `assignPositions`, `FORMATION`]: rings around (0, 0), one radius per behaviour.

  | Behaviour | Ring radius |
  |---|---|
  | shield | 220 |
  | sword | 170 |
  | bow | 120 |
  | arcane_focus | 120 |
  | healing_staff | 60 |
  | alchemy_kit | 60 |
  | anything else (body / avatar) | 60 |

  Each ring gets a seeded start angle `rng() × 2π` and spreads its members evenly around the circle.
- **Raid formation** [battle/run.js `assignWorldBossPositions`]: the boss sits at (0, 0) and the squad stands in two arcs south of it.
  - Front arc: sword, shield and body, radius 215.
  - Back arc: everyone else, radius 285.
  - Angles run from `0.3π + rng() × 0.05` to `0.7π`. Position: `x = cos(a) × r × 2.2`, `y = sin(a) × r`.
- **Enemy spawns**: a random point on one of the 4 edges of the bounds [battle/waves.js `pickEdgeSpawn`]. Up to 40 tries, rejecting points:
  - closer than 140 px to (0, 0), or
  - closer than 60 px to another living enemy.

  The fallback point is (480, 260). World bosses spawn at (0, 0) (`centerSpawn`).

## 5. Waves

Source: [battle/waves.js].

- **Budget**: `waveBudget(w) = min(round((6 + 3(w−1)) × (w ≥ 6 ? 1.3 : 1)), 40)`.

  | Wave | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
  |---|---|---|---|---|---|---|---|---|---|---|
  | Budget | 6 | 9 | 12 | 15 | — (mini-boss only) | 27 | 31 | 35 | 39 | — (boss only) |

- **Wave 5** = the theme's `miniboss` alone. **Wave 10** = the theme's `boss` alone.
- **Normal waves**: `rng = mulberry32(seed + wave × 7919)`. Repeat until the budget is reached:
  1. Pick a random def from the theme's normal pool (every role except miniboss and boss).
  2. If its `budgetCost` would overflow the budget, **stop** (the loop does not try a cheaper mob).
  3. Otherwise add it and pay its cost.
- **Spawning**:
  - The queue spawns one unit every **0.8 s**, while fewer than **8** enemies are alive (`maxActive`).
  - Per-spawn RNG: `mulberry32(seed + wave × 131 + floor(simTime × 1000))`.
- **Cleared** = the queue is empty AND no enemy is alive. In raids this includes summoned minions and mirrors: all of them must die before victory.
- **Raids**: the plan is a single unit (`goo_king` or `goo_queen`). The court and mirrors are spawned by the kernel during the fight.

## 6. Level ladder and scaling

Source: [battle/run.js].

- `levelPowerMult(L) = 5^(L−1)`. Enemy **HP and attack** are multiplied by this value and rounded at spawn [battle/waves.js `spawnWaveUnit`].
  - **Defence and speed are NOT scaled.**
  - The HUD text says "enemies +500%" per level. The math is actually ×5, which is +400%.
- `levelLootLuck(L) = 1 + 0.05 × (L−1)` (section 13).
- **Level-2 kits.** From `combat.level >= 2` (`skillUnlockLevel`), every mob gets its signature skill (section 10).
- Raid units, court minions and mirrors never scale with level.

| Level | ×HP / ×ATK | Example: Bramblehorn HP / ATK |
|---|---|---|
| 1 | 1 | 280 / 7 |
| 2 | 5 | 1,400 / 35 |
| 3 | 25 | 7,000 / 175 |
| 4 | 125 | 35,000 / 875 |
| 5 | 625 | 175,000 / 4,375 |

## 7. Enemy roster

Source: [battle/enemies.js]. ATK, DEF, SPD and HP are the level-1 base values. "Cost" = wave budget cost. "Kind" is the AI flag set from `behaveEnemy` [battle/combat.js]:
- **melee**: attack range 66 (60 + 6).
- **ranged**: attack range 130, except Lava Slug 170 and Ring Keeper 230. Ranged mobs back away when a target is within 70 px but keep firing.
- **hunter**: targets the living squad slime with the lowest absolute HP.
- **healer**: heals a wounded ally.

The level-2 skills are described in section 10.

### Sunny Meadow — `greenfield`

| id | Name | Role | Cost | ATK | DEF | SPD | HP | Kind / basic extra | Lv2 skill |
|---|---|---|---|---|---|---|---|---|---|
| green_sprout | Sproutling | swarmer | 1 | 1 | 0 | 3 | 13 | melee | Seed Burst |
| green_bee | Honey Bee | raider | 2 | 3 | 0 | 5 | 18 | melee, hunter; each basic sting slows the target by 70% for 2 s | Sting Dive |
| green_dandelion | Puffdandy | spitter | 2 | 3 | 0 | 2 | 16 | ranged 130 | Seed Storm |
| green_moth | Glowmoth | shaman | 2 | 1 | 0 | 2.5 | 20 | healer | Blinding Glow |
| green_snail | Clover Snail | armoured (elite) | 3 | 3 | 8 | 0.7 | 38 | melee | Shell Cyclone |
| green_turtle | Bloomshell | **miniboss** | — | 5 | 7 | 1.5 | 140 | melee | Pollen Shockwave |
| green_boar | Bramblehorn | **boss** | — | 7 | 4 | 2 | 280 | charger boss kit | Thorn Volley |

### Mushroom Grove — `darkforest`

| id | Name | Role | Cost | ATK | DEF | SPD | HP | Kind / basic extra | Lv2 skill |
|---|---|---|---|---|---|---|---|---|---|
| dark_spider | Sporeleg | swarmer | 1 | 1 | 0 | 3 | 14 | melee | Spore Pounce |
| dark_moth | Duskwing | raider | 2 | 3 | 0 | 4.5 | 16 | melee, hunter; each basic hit debuffs the target −20% for 3 s | Nightmare Veil |
| dark_wisp | Glimmerwisp | spitter | 2 | 2 | 0 | 2.2 | 16 | ranged 130 | Spirit Ward |
| dark_toad | Gloomwart | armoured (elite) | 3 | 3 | 8 | 1 | 38 | melee | Belly Flop |
| dark_wolf | Mossfang | **miniboss** | — | 6 | 3 | 4.5 | 150 | melee, hunter | Phantom Flurry |
| dark_golem | Rootwarden | **boss** | — | 7 | 5 | 1.5 | 300 | golem boss kit | Verdant Drain |

### Volcano — `volcano`

| id | Name | Role | Cost | ATK | DEF | SPD | HP | Kind / basic extra | Lv2 skill |
|---|---|---|---|---|---|---|---|---|---|
| magma_beetle | Cinder Beetle | swarmer | 1 | 2 | 1 | 2 | 16 | melee | Ember Burst |
| magma_bat | Ash Bat | raider | 2 | 3 | 0 | 5 | 20 | melee (not a hunter for basic targeting) | Soot Dive |
| magma_imp | Flame Imp | spitter | 2 | 4 | 0 | 2 | 20 | ranged 130 | Fire Juggle |
| magma_slug | Lava Slug | spitter | 3 | 4 | 3 | 0.7 | 45 | ranged 170 | Magma Rain |
| magma_crab | Basalt Crab | armoured (elite) | 3 | 4 | 9 | 1 | 40 | melee | Fissure Snap |
| magma_wolf | Cinderfang Wolf | **miniboss** | — | 8 | 3 | 5 | 190 | melee, hunter | Blazing Dash |
| magma_bull | Magmahorn | **boss** | — | 11 | 6 | 2 | 480 | charger boss kit | Magma Geysers |

### Snowy Peak — `ice` (no elite role on this map)

| id | Name | Role | Cost | ATK | DEF | SPD | HP | Kind / basic extra | Lv2 skill |
|---|---|---|---|---|---|---|---|---|---|
| ice_snowball | Snow Puff | swarmer | 1 | 1 | 0 | 2 | 14 | melee | Snowball Roll |
| ice_wolf | Frost Wolf | raider | 2 | 4 | 1 | 5 | 26 | melee, hunter | Frostbite Lunge |
| ice_owl | Rime Owl | raider | 2 | 3 | 1 | 4 | 24 | melee | Rime Gust |
| ice_spider | Crystal Spider | spitter | 3 | 4 | 2 | 2 | 24 | ranged 130 | Shard Nova |
| ice_alpha_wolf | Alpha Frost Wolf | **miniboss** | — | 7 | 3 | 5 | 160 | melee, hunter | Chilling Howl |
| ice_yeti | Frostjaw the Yeti | **boss** | — | 10 | 5 | 2 | 420 | yeti boss kit (lv1+) | none extra |

### Classic set (`classic`) — unused fallback, kept for completeness

| id | Name | Role | Cost | ATK | DEF | SPD | HP |
|---|---|---|---|---|---|---|---|
| swarmer | Swarmer | swarmer | 1 | 1 | 0 | 3 | 12 |
| brute | Brute | brute (elite) | 3 | 4 | 1 | 0.5 | 60 |
| raider | Raider | raider | 2 | 3 | 1 | 4 | 22 |
| spitter | Spitter | spitter (ranged 130) | 2 | 3 | 0 | 1 | 18 |
| shaman | Shaman | shaman (healer) | 2 | 1 | 0 | 1 | 20 |
| armoured | Armoured Mob | armoured (elite) | 3 | 3 | 8 | 1 | 35 |
| miniboss | Mini-Boss | miniboss | — | 5 | 3 | 2 | 120 |
| boss | Main Boss | boss | — | 8 | 5 | 2 | 250 |

### World Boss arena units

| id | Name | Role | ATK | DEF | SPD | HP | Notes |
|---|---|---|---|---|---|---|---|
| goo_king | King Goo, the Prismatic Tyrant | boss | 16 | 10 | 2 | 15000 | Never moves, never pushed. Spawns at centre. |
| goo_guard | Royal Lancer | raider | 9 | 6 | 3.8 | 200 | Court minion: Crystal Lance |
| goo_ring | Ring Keeper | spitter (ranged 230) | 8 | 2 | 3.2 | 130 | Court minion: Shard Halo |
| goo_golem | Gemstone Golem | armoured | 12 | 8 | 1.8 | 450 | Court minion: Facet Quake |
| goo_queen | Queen Nyx, the Umbral Empress | boss | 15 | 9 | 3 | 22000 | Teleports, never pushed. Spawns at centre. |
| goo_mirror | "Shadow of <slime name>" | swarmer | 70% of source ATK | source DEF | source SPD | 45% of source max HP | Queen summon; generic melee, no skills |

The court stats are duplicated in `COURT_STATS` [battle/combat.js] and must stay equal to the defs.

**Elite** means role `armoured` or `brute`; it matters only for the loot tables. Mini-boss and boss use the role names `miniboss` and `boss`.

## 8. Combat model (kernel)

Source: [battle/combat.js] and [battle/config.js `COMBAT`]. The kernel is pure and deterministic: the same seed and the same number of fixed steps always give the same result.

### Tick
- Fixed step `tickDt = 1/30` s, driven by an accumulator. At most **8** catch-up steps per frame; if the cap is hit, the backlog is dropped [game.js].
- The battle-speed button (1× or 2×) and cinematic slow-mo scale the real time fed into the accumulator. The results do not change.

Each step, in this order:
1. `simTime += dt`, and the event list is cleared.
2. For every unit, in array order (the squad first, then enemies in spawn order):
   - The avatar's steering override runs first, if active (see "Avatar control" below).
   - Dead units are skipped.
   - Every cooldown is decremented toward 0: `attackCd`, `areaCd`, `skillCd`, `skill2Cd`, `summonCd`, `rayCd`, `wardCd`, `novaCd`.
   - The unit's behaviour runs. The behaviour function is chosen by `behaviourId`.
   - Expired statuses are purged.
3. `separate()`: units push apart (see "Separation" below).
4. If no squad unit is alive, `over = true`.

### Units
Unit fields: id, team (`squad` or `enemy`), name, behaviourId, role, x, y, hp, maxHp, attack, defence, speed, state (`ALIVE` or `FALLEN_IN_BATTLE`), aiState (visual only), targetId, cooldowns, retargetAt, statuses `[{id, until, magnitude, sourceId}]`.

Initial values:

| Unit | attackCd | areaCd | skillCd | Other timers | HP |
|---|---|---|---|---|---|
| Squad unit | 0 | 0 | `1.5 + i × 0.6` (i = slot index; staggered openers) | — | full (`battleStats.hp`) |
| Normal enemy | 0.5 | 0 | `2 + ((unitCount × 7) % 10) × 0.35`, a deterministic 2.0–5.15 s | — | full |
| Boss / miniboss | 0.5 | 0 | 0 | — | full |
| King | 2 | 3 | 6 (Crown Barrage) | `skill2Cd` 10 (Goo Tide); `summonCd` 12 | full |
| Queen | 2 | 3 | 9 (Mirror Legion) | `skill2Cd` 6 (Phase Blink) | full |
| Court minion | 0.8 | 0 | `2 + i × 0.4` | — | full |
| Mirror | 0.8 | 0 | 9999 (never casts) | — | full |

- Enemy unit ID: `enemy-<defId>-<unitCount>-<floor(simTime × 1000)>`.
- Mirror ID: `mirror-<sourceSlimeId>-<n>-<ms>`.

### Core formulas

| Formula | Definition | Constants |
|---|---|---|
| Damage | `reduction = min(0.75, def / (def + 50))`; `dmg = max(1, round(raw × (1 − reduction)))` | `defK` 50, `defCap` 0.75, `minDamage` 1 |
| Attack cooldown | `max(0.25, 1.0 / (1 + max(0, spd) × 0.04))` s | — |
| Move speed | `60 × min(3, 1 + max(0, spd) × 0.05)` px/s | — |
| Slow | effective SPD for movement = `spd × (1 − magnitude)` | — |

- **Where slow applies.** It affects movement done through `moveTowardPoint` / `moveAwayFrom`: bow, healer, shield, arcane, alchemy, body and every enemy. **Sword movement ignores slow** (see section 19). Slow never changes attack cooldowns.
- **Default magnitudes.** Slow defaults to 0.5. Buff and debuff default to 0.2.

`applyDamage(target, raw, fromId)` does the following, in order:
1. If the attacker has `debuffed`: `raw × (1 − mag)`.
2. If the attacker has `buffed`: `raw × (1 + mag)`.
3. `dmg = computeDamage(raw, target.defence)`.
4. **Crit.**
   - Chance for squad attackers: `min(0.30, 0.10 + attacker.speed × 0.002)`. Enemies have 0 crit chance.
   - The roll is deterministic: `h = seed XOR round(simTime × 1000)`, then the bytes of `fromId` and `targetId` are mixed in with FNV-1a, then `mulberry32(h)()`.
   - On a crit, `dmg = round(dmg × 1.6)`.
5. If the target has `shielded`: `dmg = max(1, ceil(dmg × 0.7))`. This is a 30% soak and ignores the status magnitude.
6. `hp -= dmg`, and an `attack` event `{id, fromId, amount, crit}` is emitted.
7. If `hp <= 0`:
   - The target becomes `FALLEN_IN_BATTLE` and a `fallen` event is emitted.
   - If the target is a squad unit, AVENGE triggers (section 11).

**Heal**: capped at maxHp. Dead units cannot be healed.

**Every hit applies its damage instantly** at cast time. Projectiles, marks and damage numbers are visual-only and fire from the events.

### Targeting
- Units make target decisions 5 times a second (`targetHz` 5; `retargetAt = now + 0.2`).
- `pickTarget` = the closest living foe, with stickiness: the current target is kept unless the new one is more than **30 px** closer (`stickyMargin`).
- Hunters (`isWolf`) target the living foe with the lowest absolute HP: ice_wolf, ice_alpha_wolf, magma_wolf, green_bee, dark_wolf, dark_moth.

### Separation
- Minimum distance between units = 2 × `bodyRadius` 26 = **52 px**.
- Overlapping pairs are pushed apart by half the overlap each.
- **Squad units pass through each other.** Enemy–enemy and squad–enemy pairs separate.
- King and queen are never pushed; the other unit takes the full push.

### Avatar control
The player's avatar is a normal squad unit plus manual input [battle/combat.js `stepCombat`, battle/run.js `setAvatarInput`].
- **Input**: `{dx, dy}` is a normalised direction, plus an optional `focusId`. It is stored on the combat state and applied every tick until it changes.
- **Focus**: if `focusId` is a living foe, it becomes the avatar's target for 0.5 s at a time.
- **While steering** (dx or dy ≠ 0):
  - Cooldowns tick down.
  - The avatar moves at `max(moveSpeed(spd), moveSpeed(6)) × 1.9` px/s, clamped to the bounds.
  - It hits its current target with a plain attack (×1.0, cooldown = `attackCooldown`) when the target is in reach. Reach is 160 for bow, arcane, alchemy and staff, and 60 otherwise.
  - No skills or AI run while steering.
- **When not steering**, the normal class AI runs.

## 9. Squad weapon classes (AI and skills)

All multipliers are applied to the unit's `attack` [battle/combat.js, battle/config.js].

**Specials** are skills gated by `skillCd` (staggered openers). **Secondary abilities** are gated by `areaCd`. Each behaviour performs at most one action per tick, and the checks run in the order listed.

### Sword — "Close-range attacker" (`behaveSword`)
1. **Retarget**: `pickTarget` at 5 Hz.
2. **SPECIAL: Dash Strike** (`dash`).
   - Condition: `skillCd ≤ 0` and the target distance is in (90, 240] (90 = 1.5 × melee range).
   - Teleports to 42 px short of the target (0.7 × 60).
   - Hits **×1.8**.
   - `attackCd` is reset; `skillCd = 8`.
3. **Area Slash**.
   - Condition: `areaCd ≤ 0` and **≥ 3** enemies within 90 px.
   - Every one of them takes **×0.8**.
   - `areaCd = 6`.
4. **Basic**: walk toward the target (ignores slow). Within 60 px, hit ×1.0 with cooldown = `attackCooldown(spd)`.

### Bow — "Ranged attacker" (`behaveBow`)
1. **Retarget**:
   - If an enemy is within 80 px (`bowDangerRange`), target the nearest such pursuer.
   - Otherwise target the **farthest** non-dummy enemy.
2. **SPECIAL: Arrow Volley** (`volley`).
   - Condition: `skillCd ≤ 0`, the target is within 240 (1.5 × 160), and ≥ 2 enemies are within 120 of the target (the target included).
   - Hits up to **5** of them at **×0.9**.
   - `skillCd = 9`.
3. **Piercing Shot**.
   - Condition: `areaCd ≤ 0` and the target is within 240.
   - A single target takes **×1.5**.
   - `areaCd = 5`.
4. **Movement**:
   - Distance ≤ 80: move away (kite).
   - Distance > 160 (preferred range): approach.
   - Otherwise: basic ×1.0 with cooldown = `attackCooldown`.

### Healing Staff — "Healer" (`behaveHealer`)
1. **SPECIAL: Healing Ring** (`healring`).
   - Condition: `skillCd ≤ 0`, and among allies within 150 (self included) **≥ 2** are below 90% HP.
   - Every ally within 150 heals `round(atk × 1.5)`.
   - `skillCd = 12`.
2. **Self-save**.
   - Condition: own HP < 35% and `attackCd ≤ 0`.
   - Heals itself `atk × 2`.
   - Cooldown = `attackCooldown + 0.5`.
3. **Heal**.
   - Condition: some ally (not self) is below **60%** and `attackCd ≤ 0`.
   - Heals the lowest-% ally `atk × 2`.
   - Cooldown = `attackCooldown + 0.5`.
4. **Guardian Ward**.
   - Condition: `areaCd ≤ 0` and some ally is below 60%.
   - The lowest-% ally gets `shielded` for **3 s**.
   - `areaCd = 4`.
5. **Weak bolt**.
   - Hits the nearest enemy at **×0.5**, with no range limit.
   - Cooldown = `attackCooldown + 1.2`.
6. **Movement**: if more than 75 px from the living-ally centroid, walk to it at half speed.

### Shield — "Tank/protector" (`behaveShield`)
1. **SPECIAL: Taunt** (`taunt`).
   - Condition: `skillCd ≤ 0`, and among enemies within 100 there are ≥ 2, OR one of them is targeting another unit.
   - Each of those enemies gets `taunted` (4 s) and its `targetId` is set to the tank.
   - The tank gets `shielded` for 2.5 s.
   - `skillCd = 6`.
   - Note: `taunted` has no mechanical effect beyond the retarget (section 19).
2. **Committed target**:
   - Keep the target until it dies.
   - Then prefer an enemy whose target is a "squishy" squad unit (bow, healing_staff, arcane_focus or alchemy_kit). Otherwise take the nearest.
3. **Leash**: if more than 300 px (2 × 150) from the squad centroid and the target is more than 60 away, return toward the centroid at 0.8 speed.
4. **Shield Bash**.
   - Range 60.
   - Hits **×1.2**.
   - Fixed cooldown of **3 s** (`shieldBashCd`), whatever the SPD.

### Arcane Focus — "Ranged spellcaster" (`behaveArcane`)
1. **SPECIAL: Arcane Barrage** (`barrage`).
   - Condition: `skillCd ≤ 0`, the current target is within 168 (1.2 × 140), and the target's HP > own ATK.
   - Hits **×2.2**.
   - `skillCd = 10`.
2. **Frost Burst** (area event, ice FX).
   - Condition: `areaCd ≤ 0` and some enemy has ≥ 2 enemies within 100 of it (itself included).
   - Centred on the first such enemy, with **no range check from the caster**.
   - Every enemy within 100 takes **×1.3** and is `slowed` 50% for 2 s.
   - `areaCd = 7`.
3. **Retarget**: the enemy with the most neighbours within 100.
4. **Movement**:
   - Distance ≤ 80: kite.
   - Distance > 140: approach.
   - Otherwise: basic ×1.0.

### Alchemy Kit — "Buffer/debuffer" (`behaveAlchemy`)
Flask range = **150**. This is intentionally shorter than the bow's 160.
1. **SPECIAL: Acid Rain** (`acid`).
   - Condition: `skillCd ≤ 0`, and an enemy within flask range has ≥ 2 enemies within 90 of it.
   - Choose the densest such centre. Every enemy within 90 of it takes **×0.7** and is `debuffed` 20% for 4 s.
   - `skillCd = 12`.
2. **Squad Tonic**.
   - Condition: `areaCd ≤ 0` and any ally (**excluding self**) lacks `buffed`.
   - All unbuffed allies get `buffed` +20% for 5 s.
   - `areaCd = 6`.
3. **Cursed Flask**.
   - Condition: `attackCd ≤ 0` and an enemy is in flask range.
   - Aim at the in-range enemy whose 90 px splash contains the most un-hexed enemies. Each un-hexed enemy in the splash gets `debuffed` 20% for 4 s.
   - `attackCd = 6`.
   - If every enemy is already hexed, throw a **filler flask** instead: ×0.8 at the nearest in-range enemy, cooldown = `attackCooldown`.
4. **Movement**:
   - An enemy is within 70: kite.
   - Nothing is in flask range: approach the nearest enemy.
   - More than 75 from the ally centroid: return at half speed.

### Body — unarmed brawler (`behaveBody`; raids and the avatar)
- Nearest target (sticky).
- Melee range 60.
- Hits ×1.0 with cooldown = `attackCooldown + 0.2`.
- No skills.

**Skill unlocks for the squad:** there are no level gates. Every squad special is available from the first tick, after its staggered opener (`skillStartCd` 1.5 + 0.6 per slot).

## 10. Enemy AI, boss kits and the level-2 skill kits

### Generic enemy (`behaveEnemy`)
Each tick, the first branch that fires wins:
1. Yeti Glacier Slam.
2. Yeti Avalanche.
3. Charger / golem stomp.
4. Court minion skill.
5. Darkforest lv2 skill.
6. Volcano lv2 skill.
7. Ice lv2 skill.
8. Golem Entangling Roots.
9. Greenfield lv2 skill.
10. Retarget (5 Hz; hunters pick the lowest HP).
11. Healer heal.
12. Charger charge.
13. Basic attack and movement.

Details of the basic branches:
- **Healer** (`shaman`, `green_moth`).
  - Condition: `attackCd ≤ 0` and an enemy ally (not self) is below max HP.
  - Heals the lowest-% ally `atk × 3`.
  - Cooldown = `attackCooldown + 1`.
- **Basic attack.**
  - Condition: in range and `attackCd ≤ 0`.
  - Hits ×1.0 × phase multiplier.
  - Cooldown = `(attackCooldown(spd × phaseSpd) + (healer ? 1 : 0.3)) × enrageCd`.
- **Ranged mobs.** When a target is within 70, they back away and still fire if they can.
- **Movement.** If out of range, approach at speed × `phaseSpd`.

### Map-boss rage
"Big bosses" are `ice_yeti`, `magma_bull`, `green_boar` and `dark_golem`.

| HP | ATK multiplier | SPD multiplier | Cooldown multiplier |
|---|---|---|---|
| > 60% | ×1.0 | ×1.0 | ×1.0 |
| ≤ 60% | ×1.2 | ×1.0 | ×1.0 |
| ≤ 30% | ×1.4 | ×1.3 (attack cooldown and movement) | ×1.0 |
| any HP, after `simTime > 45` s (**enrage**) | unchanged | unchanged | ×0.7 on some cooldowns (see the boss kits) |

HUD phase for these bosses: `1 + (≤60%) + (≤30%)`.

### Boss kits (available from level 1)

| Boss | Skill (event id) | Trigger | Effect | Cooldown |
|---|---|---|---|---|
| Frostjaw (ice_yeti) | Glacier Slam (`stomp`) | `areaCd ≤ 0` and ≥ 2 squad within 110 | ×1.2 + slowed 45% for 2 s on each | 5 |
| Frostjaw | Avalanche (`avalanche`) | `skillCd ≤ 0` and squad at distance 130–520 | Up to 3 **farthest** take ×1.1 + slowed 50% for 2.5 s | 8 × enrage |
| Bramblehorn & Magmahorn (chargers) | Stomp (`stomp`) | ≥ 2 squad within 120 | ×1.1 + debuffed 25% for 4 s | 6 |
| Chargers | Molten / Wild Charge (`charge`) | `skillCd ≤ 0` and target distance in (130, 320] | Lands 48 px short of the target. Target ×2.0; others within 70 of the landing point ×0.6. Resets `attackCd`. | 9 |
| Rootwarden (dark_golem) | Verdant Slam (`stomp`) | Same as the charger stomp | ×1.1 + debuffed 25% for 4 s | 6 |
| Rootwarden | Entangling Roots (`roots`) | `skillCd ≤ 0`. Anchor = the squad unit within 460 with the most squad units within 95 (it fires even for a single unit). | All within 95 of the anchor take ×1.0 + slowed **92%** for 2.2 s | 10 |

### Level-2 kits (only when `combat.level ≥ 2`)
Constants are in [battle/config.js]. "Weakest" = the lowest absolute HP.
- **Dash-type skills** (sting dive, pounce, roll, frostbite, soot dive, lance): the caster teleports next to the prey, 0.7 × 60 = 42 px short. Snowball Roll lands 0.6 × 60 = 36 px short and Crystal Lance 0.8 × 60 = 48 px short.
- **AOE skills** are centred on the caster unless noted.
- The cooldowns of non-boss mobs are not affected by enrage.

| Mob | Skill (event id) | Trigger / targets | Damage and status | Cooldown |
|---|---|---|---|---|
| Sproutling | Seed Burst (`seedpop`) | ≥ 1 within 75 | ×1.5 | 10 |
| Honey Bee | Sting Dive (`stingdive`) | Weakest at distance 90–420 | ×2.0 + slowed 60% for 2.5 s | 8 |
| Puffdandy | Seed Storm (`seedstorm`) | 3 nearest within 170 | ×1.25 each | 9 |
| Glowmoth | Blinding Glow (`dazzle`) | ≥ 1 within 110 | ×1.2 + debuffed 25% for 3 s | 10 |
| Clover Snail | Shell Cyclone (`shellspin`) | ≥ 1 within 90 | ×1.6; the snail itself gets shielded for 2 s | 10 |
| Bloomshell (mini) | Pollen Shockwave (`pollenwave`) | ≥ 1 within 140 | ×1.5 + slowed 35% for 2 s | 9 |
| Bramblehorn (boss) | Thorn Volley (`thornvolley`) | Only when the nearest squad unit is ≤ 130 (pinned). Targets the 4 farthest at distance 100–520. | ×1.3 | 9 × enrage |
| Sporeleg | Spore Pounce (`sporeleap`) | Nearest at distance 60–200 | ×1.5 | 9 |
| Duskwing | Nightmare Veil (`nightveil`) | Nearest within 70 | ×1.8 + debuffed 35% for 4 s | 10 |
| Glimmerwisp | Spirit Ward (`spiritward`) | Up to 3 lowest-% enemy allies within 240 | Shielded for 4 s (no damage) | 12 |
| Gloomwart | Belly Flop (`bellyflop`) | Nearest at distance 40–170; lands on the prey | All within 90 take ×1.7 | 11 |
| Mossfang (mini) | Phantom Flurry (`fangflurry`) | Weakest within 320; blinks to it if more than 60 away | 3 hits of ×0.8 each | 9 |
| Rootwarden (boss) | Verdant Drain (`lifedrain`) | Only when no squad knot of ≥ 2 within 95 exists in range 460; then every squad unit within 340 | ×0.9; the golem heals 1.5 × the total damage dealt | 10 × enrage |
| Cinder Beetle | Ember Burst (`emberpop`) | ≥ 1 within 75 | ×1.5 | 10 |
| Ash Bat | Soot Dive (`sootdive`) | Weakest at distance 90–420 | ×1.8 + debuffed 25% for 3 s | 9 |
| Flame Imp | Fire Juggle (`firejuggle`) | 3 nearest within 180 | ×1.2 each | 9 |
| Lava Slug | Magma Rain (`magmarain`) | Densest squad knot (radius 90, ≥ 2 units) whose anchor is within 250 | ×1.3 + slowed 35% for 2 s | 11 |
| Basalt Crab | Fissure Snap (`fissuresnap`) | ≥ 1 within 95 | ×1.5 + slowed 45% for 2 s | 10 |
| Cinderfang (mini) | Blazing Dash (`flamedash`) | Weakest at distance 60–340. Dashes 70 px **past** it; every squad unit within 46 px of the lane is hit. If nothing is hit, it aborts and sets `skillCd = 1`. | ×1.3 | 9 |
| Magmahorn (boss) | Magma Geysers (`geyser`) | Pinned (nearest squad unit ≤ 130). Targets the 3 farthest at distance 100–520. | ×1.2 + debuffed 20% for 3 s | 9 × enrage |
| Snow Puff | Snowball Roll (`snowroll`) | Nearest at distance 60–240 | ×1.5 + slowed 30% for 1.5 s | 8 |
| Frost Wolf | Frostbite Lunge (`frostbite`) | Weakest at distance 50–260 | ×1.6 + slowed 55% for 2.5 s | 9 |
| Rime Owl | Rime Gust (`rimegust`) | ≥ 1 within 95 | ×1.2 + debuffed 20% for 3 s | 9 |
| Crystal Spider | Shard Nova (`shardnova`) | 3 nearest within 180 | ×1.15 each | 10 |
| Alpha Frost Wolf (mini) | Chilling Howl (`packhowl`) | ≥ 1 within 180 | ×0.9 + slowed 35% + debuffed 15%, both 2.5 s | 11 |

Thorn Volley and Magma Geysers share `skillCd` with the boss's charge; Verdant Drain shares it with Entangling Roots. The boss therefore alternates between them depending on how the squad stands.

## 11. AVENGE, statuses, crits and elements

### AVENGE
When a **squad** unit falls, every other living squad unit gets `buffed` with magnitude **0.25** for **5 s**. A `skill` event `avenge` is emitted [battle/combat.js `applyDamage`, battle/config.js `avengeAtkBuff`, `avengeDur`]. Visually, every rallied teammate plays a "roar" move.

### Statuses
Statuses do not stack. Re-applying a status refreshes `until = max(old, new)` and **overwrites** its magnitude and source.

| Status | Effect | Sources |
|---|---|---|
| `slowed` | Movement speed × (1 − mag) | Frost Burst, yeti, roots, bee, wolves, slug, crab, king and court, … |
| `debuffed` | The **owner's outgoing** damage × (1 − mag) | Alchemy flasks, stomps, moths, owl, bat, geysers, queen |
| `buffed` | The owner's outgoing damage × (1 + mag) | Squad Tonic 0.2, AVENGE 0.25, queen Eclipse self-buff 0.25 |
| `shielded` | Incoming damage × 0.7, rounded up, minimum 1 | Guardian Ward, Taunt, Spirit Ward, Shell Cyclone, Prismatic Ward |
| `taunted` | Icon only. The retarget is done directly. | Shield Taunt |

A unit can hold `buffed` and `debuffed` at the same time; both apply.

### Crits
- Squad only. The chance is 10% + 0.2% per SPD point, capped at 30%. Crit damage is ×1.6.
- The roll is deterministic (section 8).

### Elements
**There is no elemental damage system.** Elements (`fire`, `ice`, `heal`, `arcane`, `acid`, `shock`) only choose which VFX artwork plays [battle/fxKinds.js]:
- `ELEMENT_BY_ATTACK_KIND` maps the attack mark to an element: slash, claw, bite, impact and pierce → shock; ice → ice; magic → arcane; holy → heal; acid → acid; fire → fire.
- Old tint colours are sorted into elements by hue.

There are no resistances, weaknesses or bonus damage.

## 12. World bosses

Source: [battle/combat.js `behaveGooKing`, `behaveGooQueen`], [battle/config.js], [battle/worldboss.js], [battle/run.js], [game.js].

### Shared rules
- One encounter. The run starts at `currentWave = 1`, with ledger key 101.
- Squad up to 20, unarmed slimes allowed.
- Basic bolt: range 900, which covers the whole arena. Cooldown = `(attackCooldown(spd) + 0.9) × cdMult`, about 1.83 s at phase 1.
- **Phases** by HP fraction:

  | Phase | HP | atkMult | cdMult |
  |---|---|---|---|
  | 1 | > 70% | 1.0 | 1.0 |
  | 2 | ≤ 70% | 1.2 | 0.85 |
  | 3 | ≤ 40% | 1.35 | 0.75 |
  | Fury | ≤ 15% | 1.5 | 0.6 |
  | Frenzy | `simTime` > **150 s** | 1.7 | 0.5 |

- **Soft enrage** after frenzy: `ramp = 1 + ((simTime − 150) / 60) × 2`. This is +200% per minute and unbounded.
  - `atkMult ×= ramp`.
  - `cdMult /= min(ramp, 2)`.
  - The intent is that every raid ends within a few minutes.
- **Abilities unlocked by a phase** have their cooldowns start at 0, so they cast **instantly** on the tick the threshold is crossed.
- HUD: `Phase 1–4` (1 + p2 + p3 + fury). "ENRAGED" is shown when past frenzy or in fury, and "×ramp" is added when ramp > 1.

### King Goo — 15,000 HP, ATK 16, DEF 10, SPD 2
Stationary at (0, 0). The cast priority below is checked every tick; one cast per tick.

| # | Skill (event id) | Unlock | Trigger | Effect | Base cooldown (× cdMult) |
|---|---|---|---|---|---|
| 1 | Royal Slam (`royalslam`) | P1 | ≥ 1 squad unit within 150 | ×1.4 + slowed 50% for 1.5 s | 7 |
| 2 | Crown Nova (`crownnova`) | Fury or frenzy | Always | Whole arena ×1.6; units within 150 take **half** (×0.5) | 16 |
| 3 | Prism Ray (`prismray`) | P2 | Always | Beam from the king through the **highest-HP** squad unit (ties broken by id). Length 900, half-width 70. Everyone inside takes ×1.5. | 10 |
| 4 | Goo Tide (`gootide`) | P1 | ≥ 2 squad within 280 (330 in fury or frenzy) | ×1.1 + slowed 45% for 2 s | 12 (first cast at 10 s) |
| 5 | Crown Barrage (`prismbarrage`) | P1 | Always | The N **farthest** squad units take ×0.9. N = 5, or 6 in P2+, or 7 in fury or frenzy. | 9 (first cast at 6 s) |
| 6 | Prismatic Ward (`prismward`) | P3 | Always | The king gets `shielded` (30% soak) for 4 s | 16 |
| 7 | Royal Summons (`summons`) | P1 | Fewer than 8 court minions alive | Spawns `min(4, 8 − alive)` minions on a 150 px ring around the king. The order cycles Lancer → Ring Keeper → Lancer → Golem. Ring angle base = `(floor(simTime × 1000) % 628) / 100`. | 18 (first cast at 12 s) |
| — | Prism bolt | — | The target is within 900 | ×1.0 | `(attackCooldown + 0.9) × cdMult` |

Royal court signature moves. These are always unlocked and are not scaled by level or by the king's phase:

| Minion | Skill (event id) | Trigger | Effect | Cooldown |
|---|---|---|---|---|
| Royal Lancer | Crystal Lance (`spearlunge`) | Nearest squad unit at distance 70–240 | Dashes to 48 px short of it. Every squad unit on the thrust line (`along` ∈ [−10, d + 20], perpendicular ≤ 30) takes ×1.6. Resets `attackCd`. | 7 |
| Gemstone Golem | Facet Quake (`gemquake`) | ≥ 1 within 115 | ×1.3 + slowed 45% for 1.6 s | 9 |
| Ring Keeper | Shard Halo (`shardhalo`) | 3 nearest within 300 | ×1.1 each. Basic range 230; ranged kiting. | 8 |

### Queen Nyx — 22,000 HP, ATK 15, DEF 9, SPD 3
Designed as the king's inverse. Priority order each tick:

| # | Skill (event id) | Unlock | Trigger | Effect | Base cooldown (× cdMult) |
|---|---|---|---|---|---|
| 1 | Veil Rend (`veilrend`) | P1 | ≥ 1 squad unit within 140 | ×1.25 + debuffed 20% for 4 s | 6 |
| 2 | Void Nova (`voidnova`) | Fury or frenzy | Always | Whole arena ×1.3, multiplied by **1.5** within 200 or **0.75** beyond (the opposite of the king's nova) | 15 |
| 3 | Eclipse (`eclipse`) | P2 | Always | Every squad unit `debuffed` 20% for 6 s; the queen `buffed` 25% for 6 s | 18 |
| 4 | Umbral Grasp (`umbralgrasp`) | P3 | Always | Every squad unit is pulled 55% of the way to her, then all within 180 take ×1.5 | 14 |
| 5 | Mirror Legion (`mirrorlegion`) | P1 | Fewer than 6 mirrors alive | `min(3, 6 − alive)` shadow copies of the **highest-ATK** living squad units (ties broken by id) appear on a 120 px ring around her. Each copy has 45% of the source's max HP and 70% of its ATK, with the same DEF and SPD. | 20 (first cast at 9 s) |
| 6 | Phase Blink (`phaseblink`) | P1 | The **farthest** squad unit is more than 140 away | Teleports to `victim.x ± 70` (the side alternates on `floor(simTime × 100) % 2`), same y. Hits ×1.0. | 9 (first cast at 6 s) |
| — | Umbral bolt | — | The target is within 900 | ×1.0 | `(attackCooldown + 0.9) × cdMult` |

While she has `buffed`, `atkMult` also gets ×1.25. Because `applyDamage` applies the buff a second time, her total is effectively ×1.5625 (section 19).

### Raid rewards [battle/worldboss.js, battle/run.js]
On the boss's death, these drops are fixed (not rolled), recorded in the ledger and spilled as ground loot:

| Reward | King | Queen |
|---|---|---|
| Coins | 1500 | 2000 |
| Meat (pantry food; called "King's Roast" or "Moonfeast") | 12 | 10 |
| Exclusive shard | 1 `crown_shard` | 1 `umbral_shard` |
| `boss_essence` | 1 | 1 |
| `mutation_serum` (Prism Serum) | 25% | 25% |
| `stat_serum` (Vital Serum) | 25% | 25% |
| Defeat consolation, max coins | 500 | 650 |

- The serum rolls are two sequential draws from `mulberry32((seed XOR 0x51ED) >>> 0)` for the king, or `seed XOR 0xEC11` for the queen.
- The rewards are committed when the wave clears, which happens after the court and mirrors are also dead.
- Killing the king sets the permanent flag `farm.wbKingSlain = true`, which unlocks the queen.
- Court minions and mirrors killed during the raid roll the normal loot tables by role:
  - `goo_golem` (armoured) uses the elite table.
  - The others use the normal table.
- **Defeat consolation**: `floor(maxCoins × (1 − bossHp / bossMaxHp))`. It is committed immediately. All other provisional loot is discarded.
- `royal_jelly` is a legacy material and is no longer dropped. Royal Jelly, Prism Serum and Vital Serum are egg injections (farm side):
  - Jelly: 30% secret mutation, otherwise a guaranteed dual.
  - Prism Serum: 10% secret, else 50% dual, else it fizzles.
  - Vital Serum: one random stat goes above the stronger parent by +1–3, or +10–30 for HP.

### Raid score and leaderboard (AC-171) [battle/worldboss.js `raidScore`, game.js `submitRaidResult`]
- Wipe: `score = damage dealt`, which is boss maxHp − remaining HP, clamped to [0, maxHp]. The maximum is 22,000.
- Kill: `score = maxHp × 10 + max(0, 3600 − floor(simSeconds))`.
  - A king kill scores 150,000 + speed bonus.
  - A queen kill scores 220,000 + speed bonus.
  - `simSeconds` includes the 1 s countdown.
- The tiers are strict: any queen kill > any king kill > any wipe. Kills rank by speed; wipes rank by damage.
- Submission happens **once**, at the moment the raid reaches VICTORY or DEFEAT, through the host platform's `gp.player.submitScore(score)`, which returns `{best, rank, needLogin}`. Guests still play; they only see "sign in to enter the rankings".
- The team panel shows the top **8** (`topScores(8)`), fetched once per panel open.
- `describeRaidScore` renders scores as "🌑 Queen slain · mm:ss", "👑 King slain · mm:ss" or "⚔️ N dmg".
- A victory also stores the best kill time, `lifetime.bestRaidKillSec`, keeping the lowest value.
- AGENTS.md mentions `LEADERBOARD.json ruleVersion 1`, but that file was not part of the download (see the gaps at the end).

## 13. Loot and the reward ledger

Source: [battle/loot.js], [battle/run.js].

Ledger guarantees:
- Each defeated enemy produces **at most one** regular drop, plus an independent **map-material** roll.
- Drops are `PROVISIONAL` until their wave clears. Then they are `COMMITTED` exactly once to the farm: coins → `farm.coins`, food and meat → pantry, everything else → `farm.materials`.
- On defeat or retreat, the current wave's provisional drops become `DISCARDED`. Earlier waves are kept.
- Reward ID = `<runId>-w<round×100+wave>-<enemyId>`. It is idempotent.
- **Pantry overflow is lost.** Food beyond the pantry capacity disappears, and the toast shows "(pantry full!)".

### Regular drop roll (`rollEnemyDrop`)
- `hash = |fold(enemyId chars, (acc × 31 + charCode) | 0, start = seed)|`
- `rng = mulberry32(hash + (wave % 100) × 997)`
- `r = rng()`. The quantity draws use further `rng()` calls.
- `luck = 1 + 0.05 × (level − 1)`.

| Enemy role | r window | Drop | Qty |
|---|---|---|---|
| **boss** (wave 10) | r < 0.05 × luck | boss_essence | 1 |
| | r < 0.50 | coins | 12–20 (`floor(12 + rng × 9)`) |
| | r < 0.78 | ore | 2–3 |
| | else | rare_part | 1–2 |
| **miniboss** (wave 5) | r < 0.10 × luck | monster_core | 1 |
| | r < 0.55 | coins | 6–11 |
| | r < 0.85 | ore | 1–2 |
| | else | rare_part | 1 |
| **elite** (armoured or brute) | r < 0.25 / luck | nothing | — |
| | r < 0.45 | rare_part | 1 |
| | r < 0.70 | ore | 1–2 |
| | r < 0.85 | wood | 1–2 |
| | else | food | 3–5 |
| **normal** (every other role, including court raider/spitter and mirrors) | r < 0.40 / luck | nothing | — |
| | r < 0.55 | coins | 2–5 |
| | r < 0.75 | food | 3–5 |
| | r < 0.84 | common_part | 1 |
| | r < 0.91 | cloth | 1 |
| | r < 0.96 | wood | 1 |
| | else | ore | 1 |

### Map material (bonus roll, `rollMapMaterial`)
- **boss**: guaranteed **2** of the map material.
- **miniboss, armoured, brute**: 18% chance of 1. The roll is `mulberry32(fold(enemyId, start = seed XOR 0x5bd1e995))() < 0.18`.
- Other roles get nothing. Raid arenas have no map material.
- The Snowy map has no elite role, so its only frost crystal sources are the mini-boss (18%) and the boss (2).

### Expected yield
The design note in [battle/recipes.js] says one full classic clear yields about 5.5 rare parts, 0.10 monster cores and 0.05 boss essences. Epic gear therefore needs about 10 runs and Mythic about 20.

### Drop definitions (materials)
| id | Name | Notes |
|---|---|---|
| coins | Coins | |
| food | Slime Snacks | Pantry food |
| wood | Hardwood | |
| cloth | Linen Cloth | |
| ore | Iron Ore | |
| common_part | Slime Residue | |
| rare_part | Gooey Core Fragment | |
| monster_core | Monster Core | Mini-boss only |
| boss_essence | Boss Essence | Boss and raid |
| royal_jelly | Royal Jelly | Legacy, no longer dropped |
| meat | King's Roast | Pantry food |
| crown_shard | Crown Shard | King only |
| mutation_serum | Prism Serum | Raid only |
| stat_serum | Vital Serum | Raid only |
| umbral_shard | Umbral Shard | Queen only |
| boar_tusk | Boar Tusk | Meadow |
| glow_spore | Glow Spore | Mushroom Grove |
| ember_scale | Ember Scale | Volcano |
| frost_crystal | Frost Crystal | Snowy Peak |

An unknown drop ID shows a safe placeholder: "Unknown Material".

## 14. Equipment

Source: [battle/equipment.js]. Equipment gives **flat stat bonuses only**; no item has a special effect. The Hand item's `weaponBehaviourId` picks the battle AI (section 9). The slots are:
- Farm slimes: head, hand, tail.
- Avatar: hand, head, tail, back, wings, aura.

Rarity by tier [`RARITY`]:

| Tier | Rarity label | Colour | Glow |
|---|---|---|---|
| wooden | Common | #8f97a0 | no |
| bronze | Uncommon | #3a9b3a | no |
| iron | Rare | #2f7fd8 | no |
| enchanted | Epic | #8a4fd0 | yes |
| mythic | Mythic | #f08a24 | yes |

Rarity is shown only in the UI; there is no in-world rarity glow (a user veto).

Every new farm starts with these 9 items in its inventory [state.js]: `item-sword-1` (sword), `item-bow-1` (bow), `item-staff-1` (healing_staff), `item-staff-2` (healing_staff-2), `item-shield-1` (shield), `item-focus-1` (arcane_focus), `item-focus-2` (arcane_focus-2), `item-kit-1` (alchemy_kit) and `item-kit-2` (alchemy_kit-2).

Retired IDs that must never be reused: `sword-2`, `bow-2`, `shield-2`.

### Hand (31 items)
| id | Name | Class | Tier | ATK | DEF | SPD | HP | Source |
|---|---|---|---|---|---|---|---|---|
| sword | Sword | sword | wooden | 1 | | | | starter; r-sword-wood |
| sword-bronze | Bronze Sword | sword | bronze | 2 | | | | r-sword-bronze |
| sword-iron | Iron Sword | sword | iron | 3 | | | | r-sword-iron |
| sword-enchanted | Runeblade | sword | enchanted | 4 | | 1 | | r-sword-enchanted |
| sword-mythic | Dawnbreaker | sword | mythic | 5 | | 1 | 20 | r-sword-mythic |
| bow | Bow | bow | wooden | 1 | | | | starter; r-bow-wood |
| bow-bronze | Bronze Bow | bow | bronze | 2 | | 1 | | r-bow-bronze |
| bow-iron | Iron Bow | bow | iron | 3 | | 1 | | r-bow-iron |
| bow-enchanted | Windwhisper Bow | bow | enchanted | 4 | | 2 | | r-bow-enchanted |
| bow-mythic | Starfall Bow | bow | mythic | 5 | | 2 | 20 | r-bow-mythic |
| healing_staff | Healing Staff | healing_staff | wooden | | | | 10 | starter; r-staff-wood |
| healing_staff-2 | Oak Staff | healing_staff | bronze | | | | 10 | starter only |
| healing_staff-iron | Iron-shod Staff | healing_staff | iron | | 1 | | 20 | r-healing_staff-iron |
| healing_staff-enchanted | Enchanted Staff | healing_staff | enchanted | | 1 | 1 | 40 | r-staff-enchanted |
| healing_staff-mythic | Lifebloom Staff | healing_staff | mythic | | 1 | 1 | 50 | r-healing_staff-mythic |
| shield | Shield | shield | wooden | | 1 | | | starter; r-shield-wood |
| shield-bronze | Bronze Shield | shield | bronze | | 2 | | | r-shield-bronze |
| shield-iron | Iron Shield | shield | iron | | 3 | | | r-shield-iron |
| shield-enchanted | Warden Shield | shield | enchanted | | 4 | | 20 | r-shield-enchanted |
| shield-mythic | Aegis of Goo | shield | mythic | | 5 | | 40 | r-shield-mythic |
| arcane_focus | Arcane Focus | arcane_focus | wooden | 1 | | | | starter; r-focus-wood |
| arcane_focus-2 | Crystal Focus | arcane_focus | bronze | 1 | | | | starter only |
| arcane_focus-iron | Iron-bound Focus | arcane_focus | iron | 2 | | 1 | | r-arcane_focus-iron |
| arcane_focus-enchanted | Prism Focus | arcane_focus | enchanted | 3 | | 2 | | r-arcane_focus-enchanted |
| arcane_focus-mythic | Mythic Focus | arcane_focus | mythic | 5 | | 2 | 20 | r-focus-mythic |
| alchemy_kit | Alchemy Kit | alchemy_kit | wooden | | | 1 | | starter; r-kit-wood |
| alchemy_kit-2 | Travelling Kit | alchemy_kit | bronze | | | 1 | | starter only |
| alchemy_kit-bronze | Bronze Kit | alchemy_kit | bronze | | | 2 | | r-kit-bronze |
| alchemy_kit-iron | Iron Kit | alchemy_kit | iron | | | 2 | 10 | r-alchemy_kit-iron |
| alchemy_kit-enchanted | Alchemist's Satchel | alchemy_kit | enchanted | 1 | | 3 | | r-alchemy_kit-enchanted |
| alchemy_kit-mythic | Philosopher's Kit | alchemy_kit | mythic | 2 | | 4 | 20 | r-alchemy_kit-mythic |

Role labels per class:

| Class | Role label |
|---|---|
| sword | "Close-range attacker" |
| bow | "Ranged attacker" |
| healing_staff | "Healer" |
| shield | "Tank/protector" |
| arcane_focus | "Ranged spellcaster" |
| alchemy_kit | "Buffer/debuffer" |

### Head (17 items, all crafted)
| id | Name | Tier | ATK | DEF | SPD | HP |
|---|---|---|---|---|---|---|
| helm-straw | Straw Hat | wooden | | | | 20 |
| helm-wooden | Wooden Helm | wooden | | 1 | | |
| helm-bandana | Warrior Bandana | wooden | 1 | | | |
| helm-bronze | Bronze Helm | bronze | | 2 | | |
| helm-archer | Archer Hood | bronze | 1 | | 1 | |
| helm-circlet | Mage Circlet | bronze | 1 | | 1 | |
| helm-iron | Iron Helm | iron | | 3 | | |
| helm-squire | Squire Coif | iron | | 2 | | 10 |
| helm-goggles | Alchemist Goggles | iron | | | 2 | 10 |
| helm-sentinel | Sentinel Brow | iron | | 3 | | |
| helm-wizard | Wizard Hat | enchanted | 3 | | 1 | 20 |
| helm-feather | Ranger Cap | enchanted | 3 | | 2 | |
| helm-runeband | Runebound Band | enchanted | 2 | | 2 | |
| helm-crown | Core Crown | mythic | 4 | 2 | | 40 |
| helm-royal | Royal Crown (from Crown Shards) | mythic | 4 | 1 | 1 | 50 |
| helm-vialcrown | Toxin Crown | mythic | 2 | | 3 | 30 |
| helm-liege | Liege Great Helm | mythic | 2 | 4 | | 40 |

### Tail (16 items, all crafted)
| id | Name | Tier | ATK | DEF | SPD | HP |
|---|---|---|---|---|---|---|
| tail-cloth | Cloth Sash | wooden | | | 1 | |
| tail-swordknot | Sword Tassel | wooden | 1 | | | |
| tail-herbbag | Herb Pouch | wooden | | | | 15 |
| tail-pack | Travel Pack | bronze | | | | 20 |
| tail-quiver | Arrow Quiver | bronze | 1 | | 1 | |
| tail-bucklerstrap | Buckler Strap | bronze | | 2 | | |
| tail-iron | Iron Tail Guard | iron | | 2 | | |
| tail-staffring | Healer Ring | iron | | 1 | | 20 |
| tail-scroll | Arcane Scroll | iron | 2 | | 1 | |
| tail-charm | Lucky Charm | enchanted | 1 | | 3 | 20 |
| tail-bladering | Blade Ring | enchanted | 3 | | 1 | |
| tail-bowstring | Enchanted Bowstring | enchanted | 2 | | 2 | |
| tail-core | Core Pendant | mythic | 2 | 3 | | 40 |
| tail-shieldcrest | Shield Crest Badge | mythic | | 4 | | 30 |
| tail-vialbelt | Philosopher Belt | mythic | 2 | | 3 | 20 |
| tail-eclipse | Eclipse Charm (from Umbral Shards) | mythic | | | 3 | 40 |

### Avatar-only
- **Back** (gives stats):

  | id | Name | Tier | ATK | DEF | SPD | HP |
  |---|---|---|---|---|---|---|
  | back-satchel | Leather Satchel | bronze | | 1 | | 20 |
  | back-crystal | Crystal Backpack | enchanted | 2 | | 1 | 30 |

  Both have recipes, but the Smithy UI only has the hand, head and tail tabs, so they are unobtainable in practice (gap).
- **Wings** (cosmetic, no stats), 17 items:
  - `wings-fairy` (iron)
  - `wings-ember` (enchanted)
  - mythic: `wings-sun`, `-void`, `-starlight`, `-blizzard`, `-aurora`, `-blossom`, `-hellfire`, `-nightsky`, `-rain`, `-autumn`, `-firefly`, `-coderain`, `-thunder`, `-electric`, `-butterfly`

  They are sold by the travelling merchant (2,500–9,500 coins) [traveller.js].
- **Auras** (cosmetic), 16 items:
  - iron: `aura-sun`, `aura-blossom`
  - enchanted: `aura-starlight`, `aura-blizzard`
  - mythic: `aura-void`, `-nightsky`, `-rain`, `-autumn`, `-firefly`, `-coderain`, `-thunder`, `-electric`, `-butterfly`, `-aurora`, `-hellfire`, `-blaze`

  Merchant prices are 2,000–10,000 coins.
- Equipment display only (not battle-relevant): hat brim anchors `HAT_BRIM_Y` and tail placement `TAIL_PLACEMENT` [battle/equipment.js].

## 15. Crafting

Source: [battle/recipes.js], [battle/crafting.js], [craftingPanel.js].

- **Crafting is atomic.**
  1. Validate: the recipe exists, the recipe is unlocked, the output def exists, there are enough materials, and there are enough coins.
  2. Consume the exact materials and coins once.
  3. Create one item `item-<recipeId>-<now>-<serial>` in `INVENTORY`.

  A failed craft consumes nothing. Failure reasons: `RECIPE_NOT_FOUND`, `RECIPE_LOCKED`, `MISSING_OUTPUT_DEF`, `INSUFFICIENT_MATERIALS`, `INSUFFICIENT_COINS`.
- **Coin cost by tier**:

  | Tier | Coins |
  |---|---|
  | wooden | 0 |
  | bronze | 25 |
  | iron | 60 |
  | enchanted | 150 |
  | mythic | 400 (the shard recipes cost 100) |

  The stat preview always reads the real equipment def. Several recipe `description` strings are out of date (for example the Wizard Hat recipe says "+2 ATK"); **the def is the truth**.
- **The Smithy UI** is opened from the blacksmith NPC.
  - It has hand, head and tail tabs.
  - The Hand tab is grouped by weapon family; Head and Tail are grouped by tier.
  - A header shows coins and the material counts.
  - The detail card has a Craft button that reads "Not enough coins" or "Missing materials" when the craft is not possible.

| Recipe | Output | Tier | Materials | Coins |
|---|---|---|---|---|
| r-head-straw | helm-straw | wooden | wood 2, cloth 2 | 0 |
| r-head-wood | helm-wooden | wooden | wood 4 | 0 |
| r-head-bandana | helm-bandana | wooden | cloth 2 | 0 |
| r-head-bronze | helm-bronze | bronze | ore 4, cloth 2 | 25 |
| r-head-archer | helm-archer | bronze | cloth 4, wood 2 | 25 |
| r-head-circlet | helm-circlet | bronze | ore 3, glow_spore 2 | 25 |
| r-head-iron | helm-iron | iron | ore 7, boar_tusk 2, common_part 2 | 60 |
| r-head-squire | helm-squire | iron | ore 5, cloth 3, common_part 2 | 60 |
| r-head-goggles | helm-goggles | iron | ore 4, cloth 3, frost_crystal 2, common_part 1 | 60 |
| r-head-sentinel | helm-sentinel | iron | ore 7, boar_tusk 3, common_part 2 | 60 |
| r-head-wizard | helm-wizard | enchanted | cloth 8, glow_spore 5, rare_part 10, monster_core 1 | 150 |
| r-head-feather | helm-feather | enchanted | cloth 6, glow_spore 4, boar_tusk 2, rare_part 10, monster_core 1 | 150 |
| r-head-runeband | helm-runeband | enchanted | cloth 4, ore 4, ember_scale 3, rare_part 10, monster_core 1 | 150 |
| r-head-crown | helm-crown | mythic | ore 8, ember_scale 5, frost_crystal 5, common_part 10, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-head-vialcrown | helm-vialcrown | mythic | glow_spore 8, frost_crystal 4, common_part 10, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-head-liege | helm-liege | mythic | ore 10, ember_scale 6, boar_tusk 4, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-head-royal | helm-royal | mythic | crown_shard 3, boss_essence 1, rare_part 10 | 100 |
| r-sword-wood | sword | wooden | wood 3 | 0 |
| r-sword-bronze | sword-bronze | bronze | wood 3, ore 4 | 25 |
| r-sword-iron | sword-iron | iron | ore 7, wood 2, common_part 2 | 60 |
| r-sword-enchanted | sword-enchanted | enchanted | ore 8, ember_scale 4, rare_part 10, monster_core 1 | 150 |
| r-sword-mythic | sword-mythic | mythic | ember_scale 8, boar_tusk 4, common_part 10, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-bow-wood | bow | wooden | wood 2, cloth 1 | 0 |
| r-bow-bronze | bow-bronze | bronze | wood 5, ore 2 | 25 |
| r-bow-iron | bow-iron | iron | wood 5, ore 4, boar_tusk 2, common_part 1 | 60 |
| r-bow-enchanted | bow-enchanted | enchanted | wood 8, glow_spore 4, rare_part 10, monster_core 1 | 150 |
| r-bow-mythic | bow-mythic | mythic | wood 10, frost_crystal 6, glow_spore 4, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-staff-wood | healing_staff | wooden | wood 3 | 0 |
| r-healing_staff-iron | healing_staff-iron | iron | wood 4, ore 5, common_part 2 | 60 |
| r-staff-enchanted | healing_staff-enchanted | enchanted | wood 6, glow_spore 6, rare_part 10, monster_core 1 | 150 |
| r-healing_staff-mythic | healing_staff-mythic | mythic | wood 8, glow_spore 10, common_part 10, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-shield-wood | shield | wooden | wood 3, cloth 1 | 0 |
| r-shield-bronze | shield-bronze | bronze | ore 5, wood 3 | 25 |
| r-shield-iron | shield-iron | iron | ore 8, boar_tusk 2, common_part 2 | 60 |
| r-shield-enchanted | shield-enchanted | enchanted | ore 8, frost_crystal 4, rare_part 10, monster_core 1 | 150 |
| r-shield-mythic | shield-mythic | mythic | ore 10, ember_scale 6, frost_crystal 4, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-focus-wood | arcane_focus | wooden | wood 2, ore 1 | 0 |
| r-arcane_focus-iron | arcane_focus-iron | iron | ore 6, glow_spore 2, common_part 2 | 60 |
| r-arcane_focus-enchanted | arcane_focus-enchanted | enchanted | ore 6, frost_crystal 3, glow_spore 3, rare_part 10, monster_core 1 | 150 |
| r-focus-mythic | arcane_focus-mythic | mythic | ore 8, glow_spore 6, frost_crystal 6, common_part 10, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-kit-wood | alchemy_kit | wooden | wood 2, cloth 2 | 0 |
| r-kit-bronze | alchemy_kit-bronze | bronze | cloth 3, ore 3 | 25 |
| r-alchemy_kit-iron | alchemy_kit-iron | iron | ore 5, cloth 3, frost_crystal 2, common_part 2 | 60 |
| r-alchemy_kit-enchanted | alchemy_kit-enchanted | enchanted | cloth 8, glow_spore 5, rare_part 10, monster_core 1 | 150 |
| r-alchemy_kit-mythic | alchemy_kit-mythic | mythic | cloth 10, frost_crystal 6, glow_spore 6, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-tail-cloth | tail-cloth | wooden | cloth 3 | 0 |
| r-tail-swordknot | tail-swordknot | wooden | cloth 2 | 0 |
| r-tail-herbbag | tail-herbbag | wooden | cloth 2, wood 1 | 0 |
| r-tail-pack | tail-pack | bronze | cloth 4, wood 3 | 25 |
| r-tail-quiver | tail-quiver | bronze | cloth 3, wood 3 | 25 |
| r-tail-bucklerstrap | tail-bucklerstrap | bronze | ore 4, cloth 2 | 25 |
| r-tail-iron | tail-iron | iron | ore 6, cloth 2, common_part 2 | 60 |
| r-tail-staffring | tail-staffring | iron | ore 3, glow_spore 3, common_part 2 | 60 |
| r-tail-scroll | tail-scroll | iron | cloth 4, glow_spore 3, common_part 2 | 60 |
| r-tail-charm | tail-charm | enchanted | cloth 5, boar_tusk 4, rare_part 10, monster_core 1 | 150 |
| r-tail-bladering | tail-bladering | enchanted | ore 6, ember_scale 3, rare_part 10, monster_core 1 | 150 |
| r-tail-bowstring | tail-bowstring | enchanted | cloth 5, glow_spore 4, frost_crystal 2, rare_part 10, monster_core 1 | 150 |
| r-tail-core | tail-core | mythic | ember_scale 6, glow_spore 6, common_part 10, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-tail-shieldcrest | tail-shieldcrest | mythic | ore 8, frost_crystal 6, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-tail-vialbelt | tail-vialbelt | mythic | glow_spore 8, frost_crystal 4, common_part 10, rare_part 20, monster_core 3, boss_essence 1 | 400 |
| r-tail-eclipse | tail-eclipse | mythic | umbral_shard 3, boss_essence 1, rare_part 10 | 100 |
| r-back-satchel | back-satchel | bronze | cloth 5, wood 2 | 25 (no UI tab) |
| r-back-crystal | back-crystal | enchanted | ore 5, frost_crystal 6, rare_part 10, monster_core 1 | 150 (no UI tab) |
| r-wings-fairy | wings-fairy | iron | cloth 6, glow_spore 4, common_part 2 | 60 (no UI tab) |
| r-wings-ember | wings-ember | enchanted | cloth 6, ember_scale 8, rare_part 10, monster_core 1 | 150 (no UI tab) |
| r-aura-sun | aura-sun | iron | ore 4, ember_scale 3, common_part 2 | 60 (no UI tab) |
| r-aura-void | aura-void | mythic | umbral_shard 3, boss_essence 1, rare_part 10 | 100 (no UI tab) |
| r-boss-focus | arcane_focus-boss (no def) | mythic | — | locked placeholder (`unlock: 'boss'`), never craftable |

## 16. Revival and fallen slimes

Source: [battle/revival.js], [game.js], [slimeDetailsPanel.js].

- **Falling in battle.** A slime that reaches 0 HP is `FALLEN_IN_BATTLE` for the rest of the run, with no in-run revive. At run end the farm slime becomes `fallen`. Its gear is freed to the inventory and its old loadout is saved as `previousLoadout`.
- **While fallen**, a slime cannot deploy, work at a station, breed, or join the nest [run.js, jobs.js, breeding.js, nest.js].
- **Revival Meal**, from the slime details panel ("✚ Revive (N food)"):
  - Cost = `20 × ceil(1 + level / 5)` food, taken from `farm.food.basicFood`.
  - On success it clears `fallen` and sets `stats.hp = max(1, round(stats.hp × 0.5))`. This **permanently halves the base HP stat** (section 19).
  - Failure reasons: `NOT_FALLEN`, `MISSING_SLIME`, `INSUFFICIENT_FOOD`.
- `reequipPreviousLoadout()` re-equips only the items that are still free in the inventory and reports the missing ones. It exists but **no UI calls it**.
- The avatar never becomes fallen on the farm, and it stands back up at the start of each new round.

## 17. Loadout, auto-equip and quick team

Source: [battle/loadout.js], [battle/loadoutPanel.js], [battle/teamPanel.js].

- **Ownership states**: `INVENTORY`, `EQUIPPED_TO_SLIME{slimeId, slot}`, `BATTLE_ESCROW`, `PENDING_RETURN`.
  - The **loadout is the single source of truth.** `reconcileItemOwnership()` repairs stale or duplicate claims; the avatar wins ties.
  - Items that are locked in battle are never touched.
- **equipItem** is atomic.
  - It fails if the slot is wrong, the item is worn by another slime, or the item is locked in battle.
  - Avatar-only slots are rejected for farm slimes.
  - The previous item in the slot returns to the inventory.
- **unequipItem**: the item returns to the inventory.
- **Loadout panel.**
  - Left side: a paper doll with the slot boxes (click to unequip) and the derived stats.
  - Right side: the inventory, with Available / Equipped tabs, grouped by weapon class, then head, tail and the avatar-only groups.
  - Clicking an item worn by another slime "takes" it: unequip there, then equip here.
  - Rapid clicks are debounced.
  - **The panel never closes on a selection.**
- **Auto-equip** (`autoEquipAll`), available from the loadout and team panels. It is deterministic and idempotent.
  1. Lock the gear that cannot move: battle-locked gear and **all avatar gear** (auto-equip never touches the avatar).
  2. Unequip every other item from every farm slime.
  3. Build one pool per slot (hand, head, tail), sorted by `gearScore`, highest first:
     - `gearScore = tierIndex × 1e6 + (ATK×10 + DEF×10 + SPD×10 + HP) × 100 + (defCount − defIndex)`
     - Ties are broken by item ID.
  4. Recipients: non-fallen slimes, sorted by level (high first), then total stats `atk + def + spd + hp/10`, then id.
  5. Each recipient in turn takes the top remaining item for **hand, then head, then tail**.

  Fallen slimes give their gear to the pool but receive nothing. The panel reports "Auto-equipped N items across M slimes".
- **Quick team** (`pickHighestLevel`): eligible slimes sorted by level, then un-floored `levelScore`, then id; take the first 10 (siege) or 20 (raid).

## 18. HUD, presentation, FX and animation timing

Everything in this section is presentation only. None of it changes combat results.

### Battle HUD [battle/hud.js, game.js]
- **Top bar**: "Lv N · Wave W" (the level is hidden at level 1), or "Prepare…" before wave 1. Next to it: "X left" (enemies alive / total spawned).
- **Boss bar**: shown when a boss or miniboss is alive. Text: "<name> · <hp%>% · Phase P[ · ENRAGED[ ×ramp]]".
- **Controls**: Pause (⏸/▶), 1×/2× speed, Retreat.
- **Phase text** in the field:
  - Siege: "COUNTDOWN", "WAVE N", "WAVE N CLEARED", "LEVEL N CLEARED!", "DEFEAT".
  - King raid: "THE KING STIRS…", "👑 KING GOO", "THE THRONE FALLS!", "WORLD BOSS DEFEATED!", "THE KING PREVAILS…".
  - Queen raid: "THE MOON DARKENS…", "🌑 QUEEN NYX", "THE ECLIPSE BREAKS!", "THE NIGHT PREVAILS…".
- **Loot toasts**:
  - "Wave loot:" on each clear, held 3.2 s.
  - "Total loot:" on victory, held 8 s.
  - Each entry shows an icon and ×qty.
- **Ground loot**: each drop spills from the corpse with an arc and bounce. It is collected on wave clear or victory and discarded on defeat.
- **Victory panel**: appears 2.2 s after victory, over cheering hops, confetti and fireworks.
  - Siege: "🏆 Level N cleared!" with Next, Replay and Return.
  - Raid: "👑 WORLD BOSS DEFEATED!" with the hoard text, the raid-score line and Return.
- **Unit display**: HP bars and status icons:
  - slowed: blue dot
  - taunted: red ring
  - shielded: yellow square
  - buffed / debuffed: an animated flame aura, warm for buff and cold blue for debuff
- **Float texts**: damage numbers; crits get a gold flourish; heal crosses; the skill name shouted over the caster (for example "Royal Slam!", "Arrow Volley!"). Plain buffs and debuffs shout these names [battle/scene.js `STATUS_SHOUT`]: Squad Tonic, Cursed Flask, Guardian Ward, War Chant, Hex, Blinding Glow, Sticky Honey, Sleepy Dust, Spore Pounce, Soot Dive, Chilling Howl, Eclipse.
- **Music**: `battle`, `boss` (a wave-10 boss or the king raid) or `eclipse` (the queen raid); back to `farm` on exit.
- **Sound effects**: per hit kind (slash, squish, ice, magic, pierce, holy, acid); `squadFall` when a squad unit falls.
- **Render sizes** (px):

  | Unit | Size |
  |---|---|
  | normal enemy | 42 |
  | miniboss | 64 |
  | boss | 100 |
  | king | 280 |
  | queen | 250 |
  | mirror | 40 |
  | lancer | 50 |
  | ring keeper | 46 |
  | golem | 66 |

### Drama beats [battle/scene.js]
- **Enemy death**: a 0.5 s squash-fade, an impact puff and goo droplets, plus a 70 ms hit-stop (slow-mo depth 0.4).
- **Boss or miniboss death**:
  - Camera impulse: 1.0 for a boss, 0.7 for a miniboss.
  - Gold sparks.
  - Slow-mo: depth 0.22 for 1.0 s (boss) or 0.35 for 0.7 s (miniboss).
- **Last kill of a wave**: slow-mo 0.3 for 0.75 s.
- **Squad unit falls**: impulse 0.55. If it was the last one, slow-mo 0.3 for 1.0 s.
- In the original, slow-mo stretches how fast real time feeds the simulation. It is "render-side" in intent but does pace the sim.
- **Camera punch per skill** (`SKILL_PUNCH`, 0–1):
  - 0.8: crownnova
  - 0.7: royalslam
  - 0.65: charge, stomp
  - 0.55: avalanche, geyser, bellyflop
  - 0.5: gootide, roots
  - 0.45: fissuresnap, flamedash, magmarain, packhowl, avenge
  - 0.4: prismray, gemquake, lifedrain, pollenwave
  - 0.35: summons
  - 0.33: thornvolley, sporeleap, stingdive, sootdive, snowroll, frostbite, fangflurry
  - 0.3: prismbarrage
  - 0.28: shellspin, nightveil, rimegust, taunt
  - 0.25: prismward, spearlunge
  - 0.22: dash, seedpop, dazzle, emberpop, firejuggle, seedstorm, shardnova
  - 0.2: shardhalo
- The FX runtime owns all camera shake. Never hand-write shake (AGENTS.md).

### FX names [battle/fxKinds.js]
- **Hit marks** (by attacker; `ATTACK_FX_BY_BEHAVIOUR`): slash, claw, bite, impact, ice, magic, pierce, holy, acid, fire.
  - Squad: sword=slash, shield=impact, alchemy=acid, staff=holy, bow=pierce, arcane=magic, body=impact.
  - Every mob has its own mapping in the table. Slash and pierce marks point along the attack line.
- **Area FX override** (`AREA_FX_BY_BEHAVIOUR`):

  | Unit | Area FX |
  |---|---|
  | arcane (Frost Burst) | ice |
  | yeti | ice |
  | bull | fire |
  | boar | impact |
  | golem | magic |
  | king | magic |
  | queen | magic |

- **Projectiles** (`PROJECTILE_BY_BEHAVIOUR`):

  | Behaviour | Projectile |
  |---|---|
  | bow | arrow |
  | arcane | orb |
  | alchemy | flask |
  | staff | light |
  | spitter | goo |
  | ice_spider | shard |
  | magma_imp | fireball |
  | magma_slug | lavaglob |
  | green_dandelion | seeddart |
  | dark_wisp | spiritbolt |
  | king / queen / ring keeper | gem |
  | Thorn Volley | thorn |

  A multi-target "juggle", "nova" or "storm" skill fires one projectile per victim, so each mark and number lands on impact.
- **Skill overlay sprites**: ring, burst (shockwave), spark, crack, aciddrop, petal, vinecrack, icecrack, leaf, honeydrop, spore, wisp, ember, snowflake.
- **Element art**: a ring, burst and mote for each of fire, ice, heal, arcane, acid and shock.
- **Other**: the heal cross; the buff/debuff aura (a 6-frame flame loop at 9 fps, 2.1× body size, behind the body); the eclipse veil; confetti and fireworks on victory.

### Body action moves [battle/bossAnims.js]
Visual squash/stretch keyframe moves. Durations are in seconds.

| Move | Duration | Shape |
|---|---|---|
| slam | 1.35 | 120 px launch, then a flat squash |
| charge | 1.2 | shrink-tremble, then burst |
| tide | 1.0 | inhale, then belly-flop |
| recoil | 0.9 | 3 pulses |
| inflate | 1.05 | swell, then pop |
| lunge | 0.55 | — |
| quake | 1.1 | — |
| halo | 0.7 | — |
| pop | 0.6 | minion spawn entrance |
| roar | 0.95 | — |
| jab | 0.32 | squad melee follow-through |
| flinch | 0.28 | hit reaction |
| shoot | 0.3 | ranged release |
| crystal | 1.15 | — |

- **Skill → move** (`SKILL_MOVE`):

  | Move | Skills |
  |---|---|
  | slam | royalslam |
  | tide | gootide, umbralgrasp, bellyflop |
  | charge | crownnova, prismray, voidnova |
  | recoil | prismbarrage, phaseblink, geyser, thornvolley, volley, barrage |
  | inflate | summons, mirrorlegion, lifedrain, pollenwave, healring |
  | crystal | prismward, eclipse |
  | lunge | spearlunge, veilrend, charge, fangflurry, flamedash, dash |
  | quake | gemquake, stomp |
  | halo | shardhalo |
  | roar | avalanche, roots, packhowl, taunt, avenge |
  | shoot | acid |

- **Heavy-FX delay** (`BOSS_IMPACT_DELAY`): the FX and camera punch wait for the body's impact beat.

  | Skill | Delay (s) |
  |---|---|
  | royalslam | 0.64 |
  | gootide | 0.3 |
  | crownnova | 0.5 |
  | summons | 0.45 |
  | prismray | 0.5 |
  | gemquake | 0.42 |
  | stomp | 0.42 |
  | bellyflop | 0.3 |
  | umbralgrasp | 0.3 |
  | voidnova | 0.5 |
  | mirrorlegion | 0.45 |

  Damage has already been applied at cast time. AGENTS.md says to never change combat timing for animation.

### Weapon moves [battle/weaponAnims.js]
The hand sprite animates separately from the body. Durations are in seconds.

| Class | Basic attack move | Special move |
|---|---|---|
| sword | swing 0.34 | cleave 0.5 |
| bow | draw 0.42 | volley 0.62 |
| staff | raise 0.6 | channel 0.85 |
| arcane | orbit 0.55 | surge 0.75 |
| alchemy | shake 0.45 | fling 0.58 |
| shield | brace 0.4 | bastion 0.55 |

Sword, bow and staff pivot at the grip (0.25, 0.8). There are also idle sways per class and a tail-charm pendulum sway.

### Hit reactions
Visual nudge only: the attacker lunges 14 px toward its target, and the victim is knocked back 9 or 16 px and plays the flinch move (AGENTS.md).

## 19. Quirks and probable bugs in the original

Decide for each one whether to keep it or fix it. My recommendations are in brackets.

1. **The enrage timer uses the run's total `simTime`, not the time since the boss spawned.** In a siege, the wave-10 boss (and Avalanche, charges and the rest) is effectively always "enraged" (×0.7 cooldowns), because more than 45 s have passed. The HUD only shows ENRAGED for the yeti. [Fix: time it from the boss's spawn.]
2. **Level scaling multiplies HP and ATK by 5 per level, but not DEF or SPD.** By level 5 a boss has 175k HP. The HUD says "+500%" for what is really ×5. [Retune for Roblox, and use a power curve you can sustain.]
3. **Reviving permanently halves the slime's base `stats.hp`**, which also lowers its level, because the farm has no "current HP" concept. [Likely a bug. Use a proper revive that keeps the stats.]
4. **Unlimited-range squad abilities**: the healer's weak bolt and the arcane Frost Burst have no range check. [Add range caps.]
5. **Sword movement ignores `slowed`**; it uses `moveSpeed(u.speed)` directly. [Fix for consistency.]
6. **The queen's Eclipse self-buff counts twice**: ×1.25 in `atkMult` and ×1.25 again in `applyDamage`. [Keep it or fix it consciously.]
7. **`taunted` has no lasting effect.** Enemies re-pick targets at 5 Hz, and the sticky margin lets them leave the tank. Hunters ignore the taunt immediately. [Make taunt force the target until it expires.]
8. **Entangling Roots fires even on a single isolated slime** (`best` starts at −1). The comment says "knot". [Fine either way.]
9. **The alchemist never buffs itself** (Squad Tonic only targets other allies). Tonic skips allies that are already `buffed`, so an active AVENGE buff (0.25) is never weakened to 0.2. But AVENGE does overwrite a running tonic with 0.25, because statuses refresh and overwrite their magnitude.
10. **Avatar gear recipes (back, wings, aura) are unreachable** from the Smithy tabs.
11. **`reequipPreviousLoadout` is not wired** to any UI.
12. **Wave fill stops at the first over-budget pick**, so wave sizes vary.
13. **Dash-type teleports are instant.** The visual dash streak plays afterwards.
14. **The king's summons spawn even when the king is at full HP**, and court minions must all die before a raid can count as won.

## 20. Notes for Roblox

What has to change for a multiplayer, server-authoritative Roblox version.

### Server-side simulation
- Port the combat kernel to a **server ModuleScript** as pure Luau.
  - Keep the 2D simulation in px-like units in the X/Z plane, then map to studs with one scale constant. For example, 10 px = 1 stud gives bounds of ±52 × ±30 studs.
  - Step it at the fixed `1/30` s from `RunService.Heartbeat` with an accumulator and the 8-step cap. Never use per-unit `task.wait` timers.
- **Replicate state, not logic.**
  - Send unit snapshots (id, x, z, hp, statuses bitmask) to clients at 10–15 Hz through an UnreliableRemoteEvent or a buffer-packed RemoteEvent. Clients interpolate.
  - Send the kernel's **event stream** (`attack`, `area`, `skill`, `heal`, `buff`, `debuff`, `slow`, `taunt`, `fallen`, `loot`) reliably, in batches per tick. Clients use it to play every VFX, projectile, number, camera punch and animation in section 18.
  - Damage already happened on the server. Client projectiles and impact delays are cosmetic.
- **Slow-mo, hit-stop and pause** must become client-only visual effects in multiplayer. Do not dilate the shared server simulation.
  - Allow **pause and 2× speed only in solo runs**, for example in a reserved server or one sim instance per player.
  - In shared instances, drop them or replace them with a vote.
- **Performance caps for cheap phones.**
  - Unit caps: 8 active wave enemies, 20 squad units (×players in co-op), 8 court minions, 6 mirrors.
  - Pool all VFX instances. Keep the expensive area effects to one per cast.
  - Throttle damage numbers per unit.

### Deterministic RNG
- Generate every **seed on the server** (`Random.new()` or a GUID hash). Never accept a seed from a client.
- Port `mulberry32` exactly with `bit32` (emulate `Math.imul` with 16-bit split multiplies), along with the FNV-style crit hash and the string-fold hashes.
  - This makes runs replayable and auditable: same seed + same inputs ⇒ same result.
  - Exact parity with the JS is optional. Determinism within Luau is what matters.
- Keep unit iteration order deterministic. Use arrays in spawn order, never `pairs` over dictionaries.
- Record the avatar inputs `{tick, dx, dy, focusId}` in the run log so a run can be re-simulated for cheat review.

### Persistence and economy
- **Profiles**: use DataStore with session locking (ProfileStore-style). Store items (with unique IDs), materials, coins, the fallen flags, `wbKingSlain`, lifetime counters and `lastSiegeTeam`.
- **The reward ledger lives on the server.**
  - Commit **once per cleared wave** in a single profile mutation.
  - Reward IDs make the commit idempotent.
  - On player leave, crash or teleport mid-run, treat it as a Retreat: committed waves are kept and the unfinished wave is discarded.
  - Escrowed items are held in server memory only, and released at the end of the run.
- **Crafting, equipping, revival and auto-equip** run as server RemoteFunctions with the same atomic validate → consume → create order. Debounce per player.

### Co-op
- **Siege co-op (optional).** A party shares one wave director.
  - Each player brings up to 10 slimes, or reduce this to keep the unit count down.
  - Scale the wave budget (and maxActive, within the caps) by party size.
  - Loot is rolled **per player**, using a per-player seed salt, so nobody steals drops.
  - The map choice and next/replay decisions need a party vote or a host decision.
- **Raid co-op** (King and Queen). This is the natural multiplayer mode.
  - Pooled squad cap: for example 20 per player or 40 total.
  - Scale boss HP with the number of participants (for example `base × (1 + 0.75 × (players − 1))`) and keep the frenzy and soft-enrage timers. The court/mirror caps can grow a little.
  - Mirror Legion copies the highest-ATK units across all players.
  - Rewards are per participant. Require a minimum contribution (for example ≥ 2% of the boss's HP, or being alive in the last 30 s) to block AFK leeching. Roll the serum chances per player.
  - Queen unlock: per player (`wbKingSlain` on the player's own profile).
- **Leaderboard.**
  - Use one OrderedDataStore per board, with the score computed **on the server** using `raidScore` (keep the tiered formula; add a `ruleVersion` key).
  - Submit once per raid end. In co-op, credit every participant, or keep separate boards for solo and group.
  - Consider weekly boards (the key includes the week number). Show the top 8 in the team UI, plus the player's own best and rank.

### Anti-cheat
- **Clients send intents only**:
  - `StartRun(mode, boss, slimeIds[])`
  - `SetAvatarInput(dx, dy, focusId)` (rate-limited to about 20/s)
  - `Retreat`, `NextRound(next | replay)`, `Return`
  - `Craft(recipeId)`, `Equip/Unequip`, `AutoEquip`, `Revive(slimeId)`
- **The server validates**:
  - Eligibility (section 2), ownership and the unlock rules.
  - Clamp the avatar direction to a unit vector, and keep its speed on the server.
  - `focusId` must be a living enemy in the same run.
- The client never reports damage, kills, loot, HP or the score.
- Item IDs are generated by the server. Reject unknown or retired definition IDs.

### Data layout
- Put the shared tuning tables in ReplicatedStorage ModuleScripts: `COMBAT`/`SLIME_SIEGE` config, enemy defs, equipment defs, recipes, and the visual tables (FX kinds, anim moves).
- Keep **loot tables, ledger logic and seeds in ServerScriptService only**.
- Rebalance with the section 19 list in mind: the enrage timer, level scaling, revive, and range caps.

---

### Gaps / not covered
- `LEADERBOARD.json` (`ruleVersion 1`, mentioned in AGENTS.md) was not in the download. The platform `gp.player.submitScore` / `topScores` API is known only from how it is called.
- The detailed per-skill VFX choreography in `battle/scene.js` (`playSkillVisual`, about 2,400 lines) is summarised by name, delay and punch only, not frame by frame.
- Sound effect files and music tracks are listed only by name (`sound.js` was not read in depth).
- The training-dummy mode (`spawnDummies`) exists in the kernel but no run uses it.
