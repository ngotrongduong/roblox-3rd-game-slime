# Pre-launch audit — Goo Lineage V2

Branch `chore/prelaunch-audit`, from `main` at `b22b948` (2026-11-15). Read with `OPTIMIZATION_RESULTS.md` (what changed
and what was measured) and `RELEASE_READINESS.md` (the gates and the decision).

How it was done: every source file was scanned by script for orphan modules, unused exports and per-player tables that
are never cleared; the save path, Robux and every remote were read end to end by a separate reviewer agent and its
findings checked against the code; the runtime was measured in a Studio play test of the real world (MapWork with the
repo's code synced in) and the server's per-player tick was timed in Lune. Each finding below says which.

## 1. What is in the repository and what is not

| Part | Where | Size |
| --- | --- | --- |
| Server services | `src/server` (42 modules) | 21,311 lines |
| Client | `src/client` (67) | 29,794 lines |
| Shared logic, data, effects | `src/shared` (285) | 99,016 lines, of which VfxLib 37,701 (148), MonsterClips 16,900 (28), Creatures 9,986 (28) |
| Loading screen | `src/first` (2) | 378 lines |
| Tests | `tests/spec` + `tests/lib` (Lune) | 824 tests |
| Tools | `tools/` (check, types, build_publish, balance sims, world/map builders, Blender, ChatGPT helpers) | not shipped |

**Not in the repository** (only in Studio or on Roblox): the whole world (`Workspace.World`, `Workspace.Map`: village
template, Market, terrain), `ServerStorage.WorldKit` and the work place's labs, all in `assets/raw/MapWork.rbxlx`
(gitignored); every uploaded mesh, texture, sound and animation is referenced by asset id and lives on Roblox; the
Robux products (22 goods still have id 0, see readiness). These were checked only where the play test touched them.

## 2. Architecture

- **Start-up** (`src/server/Main.server.luau`): Plots, VillageRemotes, Village, AreaUpgrade, ZombieFights, QuickTravel,
  Guide, Rewards, DungeonPortal, ZoneGuards, Dungeon register their hooks first; then PlayerData (profiles), Purchases,
  Leaderboard, Arena; OwnerDebug only when `RunService:IsStudio()` and only if its module exists. The order matters:
  `VillageRemotes.start` creates `ServerStorage.VillageEvents`, which `AreaUpgrade.start` waits for (no timeout). Safe
  as written; a reorder of `Main` would hang the server at start.
- **Trust boundary**: five RemoteFunctions — `Village` (one dispatcher, `VillageRemotes` -> `shared/VillageRequests`:
  every action validated by `valid()`, rate-limited per player), `Arena`, `QuickTravel`, `Purchase`, `Debug`
  (Studio only) — and one RemoteEvent `Fight`, server to client only (`Dungeon`, `ZombieFights`). No `OnServerEvent`
  handler exists.
- **State to clients**: attributes on the player's village root and on slime models, JSON for tables, written only when
  the value changed (`Village.set`, `Rewards`, `Purchases`); fights stream events over `Fight`.
- **Saves**: `ProfileStore` (session lock, last-good rotation, retry, `BindToClose`), `PlayerData` (the only writer:
  get / update / markKeyMoment / saveNow), `shared/ProfileLogic` (envelope, migrations 1 -> 17), `FarmState.repair`.
  Studio play tests use an in-memory store.
- **Simulation**: pure shared modules (`VillageSim`, `Combat`, `Dungeon`, `Zombies`, `Breeding`, ...) stepped by the
  server: the village once a second a player, fights at a fixed step with a capped catch-up
  (`Config.Zombies.FightStepSeconds`, `MaxStepsPerFrame`).
- **Loaded by name** (static search cannot see a caller; REQUIRED): `Shared.Creatures.pet_<id>` / `boss_<zone>`
  (looked up from the model's name, `shared/Creature`), `Shared.MonsterClips.<clips>` (named in `Config.Dungeon.Looks`),
  `SlimeMotion` drivers `work<Phase>` (built from the phase name, `client/Village.client.luau:638`), `VipTag`'s
  `TextChatService.OnIncomingMessage` callback, the debug modules found by `FindFirstChild`.
- **Imported code**: `src/shared/VfxLib` is the owner's own effects library, imported from `C:\roblox-vfx-library`
  (`import.ps1`); changes to it go through that library, not here. The skills under `.claude/` are dev-only.

## 3. File and artifact cleanup

| Item | Class | Evidence | Done |
| --- | --- | --- | --- |
| `DebugPresets` in the published place | CONFIRMED UNUSED at run time | required only by `OwnerDebug` and `UiDebug`, both already stripped by `tools/build_publish.luau` | stripped from the publish build (module kept for Studio and its tests) |
| 20 `Creatures/*` modules no file names | REQUIRED | loaded by model name | kept |
| `art/vfx/*_check.jpg`, `docs/ui/dungeon/*.png`, `art/models/monsters/*/*.json`, `art/models/accessories/fantasy_wings/` (untracked) | UNKNOWN: other sessions' check pictures and model data | not referenced by code; may still be wanted by those sessions | left untouched, not committed |
| `assets/raw/MapWork-before-scale-2026-10-30.rbxlx` | PROBABLY UNUSED (an old backup of the work place) | gitignored, read by no tool | kept: the owner's data |
| 6 tracked files shown as modified (`DungeonFight`, `ArenaFight`, `Combat`, `ConfigClasses`, specs `dungeon_move`, `zombies`) | line endings only | `git diff --stat` is empty for them | left as they were |
| `.gitignore` | REQUIRED | already ignores build outputs (`*.rbxlx`, `*.rbxl`, `sourcemap.json`), work places, other authors' packs | unchanged |

No obsolete prototype, backup or old config copy was found inside `src/`, `tests/` or `tools/`. The work place's labs
(`SlimeMotionLab`, `SlimeShowcase`, `DevSpawn`, `SlimeFaceStage` ...) never reach players: `tools/build_publish.luau`
drops them (its log lists each one).

## 4. Dead code and duplicate logic

- Orphan scan (every module's name searched in `src`, `tests`, `tools`): no module outside `Creatures` is unnamed.
- Unused-export scan (every `function M.name` whose name is used nowhere else): 12 hits.
  - `ArenaReplay.playing`: CONFIRMED UNUSED, removed.
  - `SlimeMotion` `workCast` ... `workHarvest` (7): REQUIRED (looked up by phase name).
  - `VipTag.OnIncomingMessage`: REQUIRED (engine callback).
  - `MotionKit.sense`, `MotionKit.lay`, `MotionKit.playKeys`: PROBABLY UNUSED: documented parts of the creature motion
    kit (a snake's body, keyed limbs) that no creature module calls today; pure, never run, kept.
- Selene reports 0 unused locals or imports (`tools/check.ps1`).
- Duplicates: the `Remotes` folder and `Fight` remote are made by whichever of `Dungeon` and `ZombieFights` starts first
  (the same few lines in both). Left: a shared helper would cost more than it saves.

## 5. Refactoring decisions

None made. The large files (`Config` 3,757 lines, `ConfigDungeon` 2,474, `ZombieFight` 2,235, `Village` 2,206) are
large because of data and drawing, are already split by area, and stay under Studio's 200,000-character script limit.
Splitting them now would be churn across code other sessions are changing, with no failing behaviour to fix.

## 6. Performance findings

Measured numbers are in `OPTIMIZATION_RESULTS.md`. Static findings:
- **Client loops** that run all game long (`FoliageSway`, `HoverBob`, `FireFlicker`, `FlagWave`, `PondFish`,
  `EffectsLod`) are throttled to 20-30 updates a second and touch only what is near the camera; fight and actor loops
  connect only while something is alive (`SlimeActor`, `ZombieFight`, `ZombieMarch`, `FightFx`, `WorkMoves`).
- **Per-player and per-instance tables**: every server table keyed by `Player` is cleared when the player leaves; the
  three client caches keyed by instances (`SlimeWear.worn`, `WorkMoves.parsed`, `UpgradeReveal.seen`) are weak tables.
- **Server per-frame work**: `Dungeon` and `ZombieFights` step fights at a fixed step with a catch-up cap; one broken
  session is caught by `pcall` and warned once. `UpgradePads` checks owners' feet every `CheckSeconds`.
- **Village tick** (1 s a player): `VillageSim.step` deep-copies the farm each tick. Timed at 0.155 ms on the Late farm
  (40 slimes) in Lune: not worth changing.
- **Networking**: attributes are written only on change; the measured send rate was 1.2 kbps idle and 5.1 kbps during a
  Dungeon run, one player.
- **Repeated `syncGarden` work**: every village tick hides the template's decorative crops again (a `GetDescendants`
  over a few `Crop` models). Small; left.
- **First Dungeon run of a server**: seven server frames of 42-482 ms around waves 8-9 in Studio; a second run of the
  same map had none over 34 ms in 72 s. Studio runs client and server in one process, so the cause (server work, the
  client's first build of monster rigs and effects, or Studio) is not isolated. Needs the MicroProfiler on a live test
  server.

## 7. Security and reliability findings

From the reviewer's read of the save path, Robux and every remote, each checked in the code by the orchestrator:

| # | Severity | Finding | Decision |
| --- | --- | --- | --- |
| 1 | P2, fixed | `Products.redeem` granted into the farm before writing the receipt; `PlayerData.update` keeps a change even when its callback throws, so a grant that failed halfway (after paying coins) would keep them with no receipt and Roblox's retry would pay them again | the grant now runs on a copy that replaces the farm only once it finished; test in `purchases` ("a grant that throws halfway changes nothing ...") |
| 2 | P2, by design | the "favorite" community gift takes the client's word (Roblox gives a server no way to see a favorite); paid once | kept (the owner's design, `docs/STATUS.md` 2026-11-14) |
| 3 | P2 | `UpgradeArea` has no distance check (spends only the player's own coins on their own village); `Unassign` skips the `isOut` check | kept: nothing to gain for a cheater |
| 4 | P2 | a save over `Config.Save.MaxBytes` is refused, and so is its release, so the last minutes would be lost | kept: the saved tables are bounded (receipts 200, slime cap); the Late farm saves 25.6 KB of 4 MB |
| 5 | P2 | a NaN or mixed table in a farm would make every `UpdateAsync` throw (kept in memory, retried) | kept: remotes refuse non-finite numbers; no path that writes NaN was found |
| 6 | P2, fixed | the publish gate did not check `Config.Robux.TestGrant` and `Config.Village.DevFreeUpgrades` (both also Studio-gated at run time) | added to `tools/build_publish.luau` |

Checked and sound: a failed load never becomes a new farm (`storeDown`, `corrupt`, `newerSchema` refuse and keep the
data); migrations 1 -> 17 have no gap and match `SchemaVersion = 17`; `BindToClose` waits within the shutdown budget;
receipts are granted inside `update` and written with `saveNow` before `PurchaseGranted`, a repeat answers `DUPLICATE`;
every Village action is type-, range- and length-checked and rate-limited; `PlayerData.update` does not yield, so two
sells in one instant cannot both pass; the Arena fight is simulated on the server from a server seed against the
server's own offer list; the debug menu is Studio-only three times over (Main, `OwnerDebug.start`'s assert, the
publish build's strip and check). All test switches are off in the committed Config.

## 8. Unverified dependencies (Studio or Roblox only)

- `rbxassetid://136198076207142`, the texture of the Heart's `HeartGuardian` (6) and `CrownGuardian` (2) statues
  (`Workspace.World.Sites.Heart`, `ServerStorage.WorldKit`): Studio said "No asset content representation found".
- `rbxassetid://102905861327564`, the texture of the Ember Lava monster `lava_tortoise` (`Config.Dungeon.Looks`,
  clips Basaltback): the same message when it spawned in a run.
- `rbxassetid://203785492`: "Asset type does not match requested type"; in no texture, image, sound or mesh property
  of the place's Workspace, ReplicatedStorage, ServerStorage, Lighting, StarterGui or SoundService; possibly a Studio
  plugin loaded in the session. UNKNOWN.
- The world's instance counts and streaming were seen only in Studio on a PC; no phone was used.

## 9. Outstanding issues

See `RELEASE_READINESS.md`, sections 4 and 5.
