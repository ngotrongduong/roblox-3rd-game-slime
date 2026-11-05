# The Arena (asynchronous PVP)

The owner's request (2026-11-05): register a squad of slimes, fight other players' teams automatically, 10 attacks a day,
take-the-place ranks, Arena points spent in an Arena shop, a monthly ladder over 1000 bots, a title over the heads of the top
10, all on the server. The plan the owner approved: `C:\Users\ngotr\.claude\plans\sorted-meandering-stearns.md` (v2).
Every number named here lives in `Config.Arena`.

## How it plays

- **Team**: up to `TeamSize` slimes, attack and defence alike. Both sides fight by the same rule (`ArenaFight`, Combat's
  `fair` option): base stats and gear only; hunger, food buffs and wounds do not count.
- **Tickets**: `TicketsPerDay` attacks a UTC day; a loss uses one too.
- **Rivals**: `Opponents` teams from the ranks above you (down to `AboveShare` of your rank; one hard, two middle, the rest
  near) plus `BelowOpponents` team just below (beating it pays `BelowShare` of a win and moves no rank: the ranks above are
  all stronger, so a settled team would otherwise lose almost every fight), a new list at most every `RefreshSeconds`. In the top 5 the list is filled with teams below and the **Champion**
  (level `ChampionLevel`): beating them pays `BelowShare` of a win and moves no rank, so rank 1 still has 10 fights a day.
- **Take the place**: beating someone above you puts you in their place; everyone from that place to your old one drops one
  step. Beating someone below changes nothing. A fight that runs past `MaxFightSeconds` is a successful defence.
- **Arena points** never reset: `WinPoints` (+`ClimbBonusPerStep` a step climbed, at most `ClimbBonusCap`), `LossPoints`
  for a loss, the capped `Quests` (first win of the day, 5 wins a week, beat a stronger team, season milestones) and the
  monthly `SeasonRewards` by rank bracket, with a badge.
- **Defence**: no points (so an alt account cannot feed a main); Defense Wins and the defence log (`LogKeep` entries).
- **Season** = a calendar month in UTC (`seasonId = YYYYMM`). Ranks reset, points stay. New attacks stop `LockSeconds`
  before the end; the ladder is final `FinalizeSeconds` after it. Rewards are claimed once a season at the next login
  (looking back `ClaimLookback` seasons); `history` keeps `KeepSeasons` seasons (best rank, final rank, wins, badge).
- **Bots**: `Bots` teams named "Rival …", strength fixed by bot id (1 strongest), level
  `BotLevelMin + (BotLevelMax - BotLevelMin) * ((Bots - id) / (Bots - 1)) ^ BotLevelExponent`: many weak, few strong. A bot
  pushed down the ladder keeps its strength. Teams are rebuilt from (season, bot id) with `Rng`; no Duals or Secrets.
- **Shop** (`Shop`): dungeon materials and one gear piece the Smithy cannot sell, each with a limit per UTC week
  (Monday 00:00); a buy re-sent with the same request id buys nothing twice.
- **Top 10 title**: "No.1 Arena" / "Top 10 Arena" over the head (the owner's one exception to "no names over heads"), shimmer
  gradient; it rises over tall hats.

## Balance (`tools/balance/arena_sim.luau`, 2026-11-05)

Real fights (`ArenaBots`, `ArenaFight`, `ArenaLadder`, `ArenaQuests`) of player teams on ECONOMY.md's road at 1.5 h a day
against the 1000 bots, 10 tickets a day for 30 days. Bots now level 8.75..150 (power 36 at rank 1000, 617 at rank 1),
Champion 190. A fight is nearly decided by power (10% stronger wins about every time).

| Team | Power | Settles at (not growing) | Points a day (growing) |
|------|-------|--------------------------|------------------------|
| day 1 (wins ~64% of its first rivals) | 40 | ~740 | ~185 |
| week 1 | 148 | ~370 | ~195 |
| month 1 | 262 | ~210 | ~170 |
| month 3 | 479 | ~25 | ~160 |

- The top 10 and rank 1 need more than a month-3 team; they are for real players later.
- A bare starter team (power 16) wins no Arena fight: the Arena is for a farm that has grown a little.
- Week 1 settles higher than the first aim (500-700); meeting it would need a flatter curve than the cubic.
- Shop: a growing player makes ~1,200 points a week, so `ore5` and `fragment2` are daily buys, `charm_core` (450, a
  shortcut for the Smithy recipe) about two days, and the rare drops stay mostly a dungeon thing (weekly limits).
- Assumed, not measured: late growth past village 50 (0.5 levels an hour) and the gear each stage owns. Move
  `BotLevelMax` with the late-game levels once they are measured: `lune run tools/balance/arena_sim.luau 200 8`.

## Where it lives

| Part | Files |
|------|-------|
| Pure rules (Lune-tested) | `src/shared/ArenaLadder` (insert, idempotent apply, rival choice), `ArenaBots`, `ArenaFight`, `ArenaSeason`, `ArenaQuests`, `ArenaRules` (tickets, points, shop), `ArenaPlay` (snapshots) |
| Save | `farm.arena` (schema 11, `ProfileLogic.migrateArena`, checked in `FarmState.repair`) |
| Stores | `src/server/ArenaStore` (DataStore `StoreName`: `Ladder_<season>`, `Def_<userId>`, `Log_<userId>`; MemoryStore queue `QueueName`, lease `LeaseMapName`); `ArenaMemory` is the in-memory MemoryStore used by Studio and the tests |
| Service | `src/server/Arena` (`Remotes.Arena`: `state`, `setTeam`, `opponents`, `attack`, `buy`, `log`) |
| Screens | `src/client/UiArena` (tabs Battle, Team, Ranking, Shop, Records; opened by the Arena round button of `UiHud`), `ArenaReplay` (the fight on the sand, x2 and Skip, no camera effects), `ArenaTitles` |
| Scene | `src/client/ArenaStage` and the model `ReplicatedStorage.ArenaStage` (see "The Arena scene"); `Config.Arena.Stage` |

## The Arena scene (owner's decision, 2026-11-05)

The Arena is not a building on the farm map. It is a separate scene drawn on each player's own client:

1. The player attacks (Arena round button beside the Market button, then Battle). The screen fades to the game's dark brown.
2. While covered, `ArenaStage.enter` copies `ReplicatedStorage.ArenaStage` (once per session, kept) into `workspace.ArenaStageClient`
   at `Config.Arena.Stage.Origin` (0, 500, 9000: far beyond the map's rim, high above any roof), sets the camera Scriptable at the
   model's `View` (still: no camera effects in fights), switches the player's controls off and stands a look-alike of their
   character at `Avatar`. The server only simulates the fight; nobody else sees the scene, so any number of players on one server
   watch their own fights at once.
3. `ArenaReplay` stands both teams on the Pit (blue side towards `BlueSpot`) and replays the fight. The crowd hops now and then
   and cheers when it ends (more for a win), at most `Stage.CrowdMax` spectators moving.
4. When it ends the screen fades, the scene goes (parent nil), the look-alike is destroyed, the camera (type, subject, CFrame,
   focus) and controls are given back exactly, the screen fades in on the farm and the result card shows.
   `ArenaReplay.stop()` (a dungeon run starts, the screen closes) does the same at once, with no fade.

The model's children, found by name anywhere below it: `Pit` (BasePart, the round sand; its top is the field's middle), `BlueSpot`
and `OrangeSpot` (BaseParts on the sand), `View` (invisible BasePart: the camera's seat in the stands behind the blue side, looking at
the pit), `Avatar` (invisible BasePart, optional: the player's look-alike stands there facing the pit), `Crowd` (Folder, optional: invisible
parts named `Spot`, one a seat, CFrame = the slime's feet facing the pit, attribute `Tier` 1..3). Each client fills the spots with the
game's own slimes (`SlimeLook.build`, a still face from `SlimeFace.still`; a few looks built, the rest cloned) in the background,
`ArenaStage.prepare()` (the Arena screen opening, or `enter`), `Stage.CrowdPerFrame` steps a frame. The model's WorldPivot is the Pit's centre. With no model in ReplicatedStorage `enter` changes nothing and the fight is
replayed in front of the player, as before; `tools/build_publish.luau` prints a warning for it until the scene is built.

## Why results never get lost or counted twice

1. **One writer.** A server's attack result goes onto the MemoryStore queue. Only the server holding the leader lease
   (`LeaseSeconds`, renewed every `TickSeconds`) reads the queue and writes the season's ladder, once a tick, in queue order.
   A leader that dies is replaced within a lease. Ladder writes stay under `WriteBytesPerMinute`; past `WarnDocBytes` it warns.
2. **One match = one transaction.** `attack` checks and spends the ticket and writes `pending` (match id `userId:seq`) inside
   one `PlayerData.update`, behind a per-player lock; a re-sent request id returns the same match.
3. **Idempotent apply.** The ladder applies a player's result only if its `seq` is newer, and writes the outcome
   (`rankAfter`, `climbed`) into the document.
4. **Points only on confirm.** The attacker's server sees the outcome in the ladder, then adds the points (for the real
   climb) and clears `pending` in one update. A player who left is settled at the next login. A result not seen after
   `ResendSeconds` is sent again (safe by `seq`). Late results for a final season are void and the ticket comes back.

These cases are Lune tests (`tests/spec/arena_store.luau` and the other `arena_*` specs, `FakeDataStore` + `ArenaMemory`): two attacks at once, re-sent
request ids, a write that failed but landed, a lost queue item, a leader dying mid-tick, a fight at 23:59:50, an order that
changed under the attacker, and 50 servers' load.

## Testing in Studio

- `lune run tools/build_publish.luau studio` builds `assets/raw/StudioTest.rbxl` with the owner's debug menu (`OwnerDebug`,
  `UiDebug`, with the pure list `DebugPresets`); the publish build removes `OwnerDebug` and `UiDebug` and checks they are
  gone (`DebugPresets` stays: nothing else requires it). The season tools (End season, Clock reset, Pause leader) refuse
  unless the Arena runs on the in-memory stores.
- In Studio the Arena uses in-memory stores unless `StudioUsesRealStore` is on (off in anything committed).
- The debug menu's Arena group: Open Arena, Team: best 4, Opponents, Attack 1st, Arena state, Tickets 10, Rank 1 / 7 / 50,
  +1000 Arena points, End season, Clock reset, Fake servers x5, Pause leader.
- The scene is not built yet: until `ReplicatedStorage.ArenaStage` exists a fight plays in front of the player.

## Not yet proven

- **Scale** (review, 2026-11-05). Every server reads the one `Ladder_<season>` key (at most every `SettleReadSeconds`), and
  the document grows ~165 bytes per player who sets a team that month. Before the Arena has thousands of players a month:
  the leader writes each outcome to a small MemoryStore map that settling reads instead of the whole ladder, and players
  who never attacked leave the document well before DataStore's 4 MB a key (`WarnDocBytes` warns at 1 MB, ~6,000 players).
  The defence snapshot cache in `ArenaStore` is never trimmed (grows over a server's life).
- Real DataStore and MemoryStore with several live servers: only after a publish. That publish changes the save shape
  (schema 11), so it must shut down all old servers.
- The scene model itself (`ReplicatedStorage.ArenaStage`, a scene artist's job) and a way to carry it into the game like
  `ClientKit` (the screen's medals, power and quest icons came from ChatGPT on 2026-11-05).
