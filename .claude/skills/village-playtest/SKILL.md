---
name: village-playtest
description: Run and diagnose the living slime village of Goo Lineage V2 in the MapWork play test - sync the code, start play, give slimes jobs, read what server and client really do, read the console, measure, then save and export. Use whenever the owner reports slimes stuck, frozen, idle or misplaced, or a village change must be proved in the running game.
---

# Village play test

Read `docs/LESSONS-village.md` first. Studio: the one named `MapWork.rbxlx` (`list_roblox_studios`), never Egg Heist.

## 1. Run it
1. If a play test runs and it is not yours, wait unless the owner told you otherwise. Stop yours with `start_stop_play`.
2. `& "C:\Roblox 3rd game\tools\map\sync_all.ps1" -StudioId <id>` (refuses during Play).
3. `start_stop_play` true. The character spawns on the plaza; slimes far from the camera do not animate, so move it:
   `game.Players:GetPlayers()[1].Character:PivotTo(CFrame.lookAt(pos, target))` in the Server datamodel.
4. Give jobs from the Client datamodel (one call every 1.2 s, the remote is rate limited):
   `game.ReplicatedStorage.Remotes.Village:InvokeServer({ action = "Assign", area = "fishing", slot = 1, slimeId = "slime-3", asReserve = false })`,
   `{ action = "SetPair", index = 1, a = "slime-1", b = "slime-2" }`, `{ action = "SetTrainingStat", slot = 1, stat = "attack" }`.

## 2. When something looks wrong: this order
1. **Console first**: `get_console_output`. A repeating error explains more than any theory.
2. **Server state** (Server datamodel), `workspace.Villages:GetChildren()[1]`:
   folder attributes `Pairs` (JSON, with `waiting` reasons), `Work`, `Box`, `Storehouse`, `Fridge`, `Population`;
   `Slimes/<id>` attributes `Action`, `Gait`, `Emotion`, `Fullness`, `Energy`, `Sleeping`, `Seated`, `WorkPhase`, `WorkArea`, `Carry`,
   `FromX/Z`, `ToX/Z`, `LegStart`, `LegEnd`; `Eggs/<id>` `Place`, `Slot`, `HatchAt`, `ClockStart`, `ClockEnd`.
3. **Client state** (Client datamodel): `workspace.VillageClientActors.<id>.SlimeBody.Position` against the slime's leg. Never use a
   model's `GetPivot` (stale). A near slime far from its leg = the client is broken.
4. **Look**: `screen_capture` (white = window covered: rely on numbers), or, if the owner asked, computer use on Roblox Studio.

Sample over time in one call (`task.wait(20)` in a loop, a line per sample) rather than many calls. `execute_luau` cannot use the real
`PlayerData` (a separate module copy): saves and needs cannot be changed by script.

## 3. The world probes
Run with `node tools/studio_mcp.js run tools/map/<probe>.luau <id> Server` (play) or `Edit`, at levels 1, 21, 41 (fire
`ServerStorage.VillageEvents.AreaLevelChanged`, or step on the pads): `probe_paths`, `probe_pads`, `probe_seats`, `scan_zfight`,
`scan_rocks`; repairs in Edit: `fix_rocks`, `fix_zfight`. Re-scan after every repair.

## 4. Finish
- `tools/check.ps1` -> CHECK OK and `tools/types.ps1` -> TYPES OK, a Lune test for the rule that broke, commit, push.
- If the place changed: the owner clicks the MapWork window and presses Ctrl+S. Check `assets/raw/MapWork.rbxlx`'s time changed,
  then `lune run tools/kit/export_kit.luau` (and `export_client_kit.luau` when items changed), commit, push.
- Report what was proved in play and what only passed tests. Leave a play test running only when the owner will look.
