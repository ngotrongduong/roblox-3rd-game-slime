# Optimization results — pre-launch audit

Branch `chore/prelaunch-audit` from `b22b948`. Findings and their evidence: `PRELAUNCH_AUDIT.md`.

## 1. Baseline and final checks

| Check | Baseline (`b22b948`) | Final |
| --- | --- | --- |
| `tools\check.ps1` (stylua, selene, Lune tests, Rojo build) | CHECK OK, 823 passed, selene 0 errors 0 warnings | CHECK OK, 824 passed, selene 0 / 0 |
| `tools\types.ps1` (luau-lsp, all of `src`) | TYPES OK | TYPES OK |
| `lune run tools/build_publish.luau` (the release place, local file) | not run | PUBLISH PLACE OK; leaves out `UiDebug`, `DebugPresets`, `OwnerDebug` and the work place's 11 labs |

## 2. Measured in Studio (2026-11-16)

MapWork (the real world) with the repo's code synced in (`tools/map/sync_all.ps1`), one player, the in-memory save, a
PC. Numbers were read by `execute_luau` probes: frame times counted over a 5-6 s `Heartbeat` / `RenderStepped` window,
memory as the Lua heap of that datamodel (`gcinfo`), counts from `Stats` and the workspace. **Studio runs server and
client in one process on one machine: these are a PC baseline to compare later runs with, not a phone or a live
server.** Client numbers taken while Studio's window had no focus (66 ms every frame, Studio's 15 fps throttle) are
left out.

| Scenario | Server | Client |
| --- | --- | --- |
| Fresh player, 40 s after joining (village, 4 slimes) | 59.9 Hz, worst frame 19 ms, Lua heap 39.7 MB, 110,015 instances, send 1.2 kbps | 43 fps, frame 19 ms (render CPU 7 ms, GPU 4 ms), p95 36 ms, worst 55 ms, Lua heap 47.6 MB, 39,068 streamed workspace instances (21,454 parts, 328 emitters of which 67 on, 102 lights on) |
| Dungeon run, Ember Lava level 1, Late farm (4 slimes of level 80), first run of the server | 57.7 Hz; 7 frames of 42-482 ms around waves 8-9; Lua heap 57 MB; send 5.1 kbps | 59.9 fps, p95 18 ms, worst 21 ms (wave 3), Lua heap 53.6 MB, 83 beams and 44 emitters on |
| The same run replayed (warm) | 60.0 Hz over 72 s of waves 1-7, no frame over 34 ms | not valid (window unfocused) |
| Three runs back to back (memory) | Lua heap a sawtooth: up to 56-58 MB, back to 38-39 MB after each collection, the same floor all three times | after runs 1, 2, 3: 46, 56, 45 MB; instances 99,517, 99,536, 99,496 |
| Loading | | "loaded in 7.9 s" (the game's own loading line; 81 of 81 pictures) |

What these say: no memory grows across runs on either side; the server holds 60 Hz in a warm run; the cold first run
has hitches whose source is not isolated (see readiness).

## 3. Timed outside Roblox (Lune)

`lune run tools/perf/server_bench.luau` (new; Lune has no native code generation, so these are upper bounds):

| Work | Fresh farm (4 slimes, 5.9 KB) | Debug Late farm (40 slimes, 25.6 KB) |
| --- | --- | --- |
| Village tick, `VillageSim.step` (once a second a player) | 0.049 ms | 0.155 ms |
| Copy of the farm, `ProfileLogic.deepCopy` | 0.039 ms | 0.139 ms |
| JSON of the farm (what a save writes) | 0.272 ms | 1.011 ms |

The heaviest per-player server work costs well under a millisecond a second; a Late save is 0.6% of the 4 MB DataStore
limit. No optimization of these paths is justified by the numbers.

## 4. What changed

| Commit | Change | Why | Proof |
| --- | --- | --- | --- |
| `3dbe08c` | `Products.redeem` grants on a copy of the farm and keeps it only when the grant finished | a grant that threw halfway would keep half a purchase and no receipt, and Roblox's retry would pay that half again | new test in `tests/spec/purchases.luau`; `purchases` 27 passed; CHECK OK |
| `004fe91` | `tools/build_publish.luau` leaves `DebugPresets` out of the release place and refuses `Config.Robux.TestGrant` / `Config.Village.DevFreeUpgrades` | the debug presets reached every client unused; two test switches were not gated | PUBLISH PLACE OK, its log shows `DebugPresets` left out |
| `004fe91` | `ArenaReplay.playing` removed | called nowhere | CHECK OK, TYPES OK |
| this commit | `tools/perf/server_bench.luau`; two traps in skill `playtest`; these three reports | reproducible timing; how to measure in Studio | the table above |

Files removed: none (no file was proven unused). Modules refactored: none. Gameplay, balance, economy, combat, drop
rates, save keys and the save shape: unchanged (schema stays 17).

## 5. Tests

- Added: "a grant that throws halfway changes nothing and keeps no receipt; the retry grants it whole once"
  (`tests/spec/purchases.luau`).
- Executed: the full suite, 824 passed, 0 failed. No test was changed to pass.

## 6. Improvements

- **Supported by evidence**: the Robux double-grant path is closed (test); the release build ships one module less to
  every client (build log).
- **Suspected, not measured**: none claimed. The release place sending `DebugPresets` (646 lines) no more is a few
  kilobytes of the client's download, not measured.

## 7. Left unchanged on purpose

- The village tick's deep copy, `syncGarden`'s repeated hiding of the template crops, the per-kill `markKeyMoment`: all
  measured or small; changing them would risk behaviour for no shown gain.
- The large Config and fight files (no failing behaviour; other sessions are editing them).
- `MotionKit.sense`, `lay`, `playKeys` (documented kit API, never run).
- VfxLib (the owner's library; changes go through `C:\roblox-vfx-library`).
- The client-trusted "favorite" gift (Roblox offers servers no check; the owner's design).
