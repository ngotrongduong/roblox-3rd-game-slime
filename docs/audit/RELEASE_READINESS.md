# Release readiness — Goo Lineage V2

Branch `chore/prelaunch-audit` (merged into `main` with a merge commit), from `b22b948`, 2026-11-16. Evidence:
`PRELAUNCH_AUDIT.md`, `OPTIMIZATION_RESULTS.md`.

## Decision: CONDITIONAL GO

No critical bug, data-loss path, exploit or failing check is known, and the one money bug found (a Robux grant that
could pay twice after a crash halfway) is fixed and tested. It is not a plain GO because the mandatory phone and
live-server gates were not run in this session: the game has been measured only on a PC in Studio. Launch when the
conditions in section 6 are met.

## 1. Passed gates

| Gate | Evidence |
| --- | --- |
| Format, lint, tests, build | `tools\check.ps1`: CHECK OK, 824 passed, 0 failed, selene 0 errors 0 warnings |
| Types | `tools\types.ps1` on all of `src`: TYPES OK |
| Release place | `lune run tools/build_publish.luau`: PUBLISH PLACE OK; the debug menu (`OwnerDebug`, `UiDebug`, `DebugPresets`) and the work place's 11 labs left out; no script from outside the repo |
| Play test in the engine | MapWork with the repo's code, 2026-11-16: a fresh player joined ("loaded in 7.9 s"), the village ran, four Ember Lava Dungeon runs were won through the real remotes; no error from the game's code (the only script error is the work place's `SlimeFaceStage` lab, which the release place does not contain) |
| Memory over time | three runs back to back: server Lua heap back to 38-39 MB after each collection, client 46 / 56 / 45 MB, instances flat |
| Test switches | all off (`Save`, `Arena`, `Leaderboard.StudioUsesRealStore`, `Pads.FreeUpgrades`, `Village.DevFreeUpgrades`, `Robux.TestGrant`); the release build now refuses any of them on |
| Remotes | every handler checks the sender's data (types, ranges, lengths, ownership) and its rate; read end to end by the reviewer |
| Saves | migrations 1 -> 17 without a gap, tested from a version-1 save (`farm_save`); a failed load never becomes a new farm; Studio tests use an in-memory store |
| Robux receipts | granted once, inside the save, written before Roblox is told; a grant that throws keeps nothing (new test) |
| Secrets | none in the repo (searched for keys, tokens, passwords, cookies, `.ROBLOSECURITY`; no `.env` or key files) |

## 2. Failed gates

None.

## 3. Tests not run

- A real phone, or Studio's device emulator, for frame rate and screens (no phone FPS exists for this world).
- A live (published) test server: server frame time apart from the client, DataStore saves for real, two or more
  players at once, rejoining and a server shutting down with players in it.
- The MicroProfiler on the cold first Dungeon run (below).
- Opening and closing the big screens many times; a session of an hour or more.
- Robux purchases on Roblox (no product exists yet).

## 4. Outstanding issues (none critical)

1. **Hitches on a server's first Dungeon run**: seven server frames of 42-482 ms around waves 8-9 of the first run in
   Studio; a warm replay had none over 34 ms. The source (server work, the client's first build of monster rigs and
   effects in the same Studio process, or Studio itself) is not isolated.
2. **Two textures do not load** ("No asset content representation found"): `rbxassetid://136198076207142` on the
   Heart's eight guardian statues, and `rbxassetid://102905861327564` on the Ember Lava monster `lava_tortoise`. They
   may show untextured.
3. **`rbxassetid://203785492`** ("Asset type does not match requested type") from an unknown source, possibly a Studio
   plugin.
4. **22 Robux goods have id 0** and stay hidden; `Config.Social.GroupId` is 0, so the group gift is hidden.
5. The save shape changed twice since the last publish noted in `docs/STATUS.md` (schemas 16 and 17): a publish must
   shut down every old server.

## 5. Remaining risks

- Phone performance of the big world (about 21,000 parts streamed in near the village, 100+ lights and 300+ emitters
  in view) is unknown; VfxLib's distance cut and streaming are the safeguards, not measured on a weak device.
- Several servers' worth of DataStore traffic has never been seen; the profile layer is well tested in Lune
  (`profile_store`, `profile_logic`, `farm_save`) but not on Roblox.

## 6. Conditions for launch, and who does them

| Condition | Who |
| --- | --- |
| Publish to a private test place or keep the game private, play one hour on a cheap phone, watch FPS (Shift+F5) and memory (F9); one first Dungeon run with the MicroProfiler | the owner plays; Claude reads the numbers he sends |
| Look at the two textures in Creator Hub (still in moderation, deleted, or the wrong type) and upload again if needed | the owner (uploads and moderation are on his account) |
| Decide on Robux at launch: create the products and prices he approves, or launch without them | the owner |
| Send the group id if the group gift should show | the owner |
| At publish: shut down all servers (the save shape changed) | the owner |

## 7. Rollback

- Every change of this audit is in the merge of `chore/prelaunch-audit` into `main`. To undo all of it:
  `git -C "C:/Roblox 3rd game" revert -m 1 <merge commit>` (the merge commit is the first `Merge branch
  'chore/prelaunch-audit'` in `git log --oneline main`).
- One change only: `git revert 3dbe08c` (Robux grant on a copy) or `git revert 004fe91` (publish build, dead
  function).
- No save data, DataStore key or schema was touched, so a rollback needs no migration.
- A bad publish on Roblox: Creator Hub -> the place -> Version History -> restore the previous version, then shut down
  all servers.
