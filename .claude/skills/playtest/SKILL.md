---
name: playtest
description: Run Goo Lineage V2 in Roblox Studio and find out what happened - build, open, play, read the log, look at what only eyes can judge. Use whenever a change has to be seen working in the real engine, not just pass tools\check.ps1.
---

# Play-testing in Studio

Adapted from the owner's previous games. Orchestrator only: Studio runs on the owner's screen. An agent that needs a
play test reports what to look at instead.

## 1. Before

1. `& "C:\Roblox 3rd game\tools\check.ps1"` must end with `CHECK OK` (it also builds `GooLineage.rbxlx`).
2. A start-up state the test needs (coins, slimes, a ready egg, fast timers) is a test switch in `src/shared/Config.luau`;
   every switch goes back to off before anything is committed. When the game has a debug panel (Studio only, never
   reaching players), prefer it: nothing has to be restored afterwards.

## 2. Run

- With Studio's MCP server (`Roblox_Studio` tools in the session; `node tools/studio_mcp.js` in a subagent):
  `list_roblox_studios` for the id (ids change when a place is reopened), `start_stop_play`, `get_console_output`,
  `screen_capture`, `execute_luau` in the Server or Client datamodel. It does not take over the screen.
- Test in `assets/raw/MapWork.rbxlx` (`village-playtest`): the built `GooLineage.rbxlx` has no world. To try what players
  would get, `lune run tools/build_publish.luau`, open `assets/raw/Publish.rbxl`, and pass `studio_id` to each Studio
  tool. With the Studio debug menu: `lune run tools/build_publish.luau studio` writes `assets/raw/StudioTest.rbxl`,
  the ONE test copy (the owner, 2026-11-08: more copies made him edit the wrong file). Close it in Studio before
  rebuilding instead of opening a renamed copy, and never build or save anything in it that must stay: map work goes in
  MapWork + Ctrl+S. Never `open_application` Studio: it starts a second, empty Studio. Never take the mouse or keyboard while the
  owner is using the machine.
- If the owner is playing in the Studio window, let him play and read the log instead of grabbing the mouse.
- A Studio play test saves nothing and never touches real saves (the profile layer uses its in-memory store). Saving is
  tried on the live game only (see `publish`).

## 3. Read what happened

`& "C:\Roblox 3rd game\tools\read_log.ps1"` prints the game's own lines (`[GooLineage] …`) and every script warning or
error of the newest Studio log; `… read_log.ps1" 200` for more lines. Every rule prints a line when it fires (a breed, an
egg, a hatch, a sale, an upgrade, a save), so most of a test can be judged without a screenshot.

Look for, in this order: any `Error` line; the world's and the profile's start lines with the expected counts; then the
lines of what was tried.

**Frame rates**: Studio throttles a window without focus to about 15 frames a second; a reading taken then is worthless.

## 4. What only eyes can judge

Sizes and overlaps on a narrow screen (Studio's device emulator), how slimes and models look next to their paintings,
effects at the game's REAL camera distance (a visual change is not done until seen there: in the previous game code that
"worked" was invisible from the camera), brightness. Take one screenshot per question, not a tour.

## 5. After

Stop the play test, restore `Config.luau` if a switch was set, and write down in the report what was seen and what was
not.

## Traps met before (the owner's earlier games, same machine)

- Studio may be signed in to a different Roblox account than the one that owns the game (the owner has more than one).
  Running a local file works anyway; publishing does not.
- A Studio window left in Play keeps the place file locked: the next build says "file is in use".
- `Authentication required` (401) lines all over the log mean Studio's session was revoked (it happened after the owner
  turned on 2-step verification); the owner signs out and in again. Nothing can be judged until then.
- Windows Defender blocks PowerShell scripts that grab the screen. Do not work around it; use Studio's `screen_capture`.
- A Studio window that is minimised or behind another Studio window draws no 3D: `screen_capture` returns the HUD on
  plain white. `& "C:\Roblox 3rd game\tools\studio_front.ps1" StudioTest` brings it forward; afterwards bring back
  the window the owner was using the same way (2026-11-08).
- `tools/map/sync_all.ps1`: Studio refuses a script Source of 200000 characters or more; the sync blanks the whole-line
  comments of a file that big. Config passed it on 2026-11-08 and was split into parts (CLAUDE.md, "Rules of the code").
- Studio dialogs (Asset Manager import, File > Publish As) are invisible to computer use: the owner clicks them.
- The command bar runs a multi-line command with Ctrl+Enter; a command that touches `CurrentCamera` or destroys things
  in Edit mode asks "Dangerous Command Detected".

## Driving a test without the mouse (2026-11-14, the exploration teams and the Heart)

- **A world change is played in MapWork itself**: `& "C:\Roblox 3rd game\tools\map\sync_all.ps1" -StudioId <MapWork id>`
  (the repo's code into the work place), `start_stop_play` `is_start: true`, look, `is_start: false`, `save_place`. No
  rebuild of StudioTest, and no window has to be closed.
- **Put the character where the thing is**, from the Server datamodel:
  `player.Character:PivotTo(CFrame.lookAt(spot, target))`, then on the Client `task.wait(2)` and set
  `workspace.CurrentCamera.CFrame` behind the character: the game's camera keeps that side long enough for a
  `screen_capture` at the real distance. (A free camera far from the character needs the render-step trick in
  `studio-build/LESSONS.md`.)
- **A ProximityPrompt is pressed from the Client datamodel**: `prompt:InputHoldBegin()`, `task.wait(0.3)`,
  `prompt:InputHoldEnd()`, with the character inside its `MaxActivationDistance`. A zone's prompt is answered on the
  client and a locked zone only shows a toast (`UiDungeon.watchZones`): read the player's `Zone_<id>` attributes first;
  the Heart needs b1, b2 and b3 won.
- **To run a locked zone's fight anyway** (the Heart, proved 2026-11-14): in Edit, in the work place only, replace
  `needs = { "b1", "b2", "b3" }` by `needs = {}` in `ReplicatedStorage.Shared.ConfigWorld.Source`; start Play; give the
  empty test farm a squad with the Studio debug menu's remote from the Client:
  `ReplicatedStorage:FindFirstChild("Debug", true):InvokeServer({ action = "late" })` (40 slimes of level 80, teams set);
  press the prompt, click `...Modal_dungeon.Panel.Body.Content.Bar.Enter` by its path. Afterwards stop Play, run
  `sync_all.ps1` (it puts the repo's `ConfigWorld` back), check the `needs` line is there again, THEN save. A command
  cannot reach the live farm by `require`: it gets its own copy of every module, so the remote is the way in.
- **Fighters are measured, not guessed**: on the Client, each model of `workspace.ZombieClientActors` (`Dungeon_*` the
  squad, `Monster_*`): the visible MeshPart's centre minus half its height against the floor's top. Their parts have
  `CanQuery` off, so `GetPartBoundsInBox` finds none. A monster the camera did not face read with its mesh at
  its pivot, half buried by the numbers (probably not posed while off screen; not proved): turn the camera to it before
  believing the number.
- **A button is clicked by its path**, not by pixels: `user_mouse_input` with the GuiObject's `instance_path`
  (`search_game_tree` or a short Client script finds it). Pixels move with the window's size.
- **`tools\read_log.ps1` reads the newest log file, which may belong to another Studio window** when several are open:
  `get_console_output` with the window's id reads that window's own Output.
- **What the test save lacks hides what you came to see**: the test vault was full, so every kill paid 0 and the
  payout of an exploring team could not be looked at; the save has no cooked dish, so the dish list showed empty. Say
  such things under "Not verified", or set the save up first through `PlayerData.update` in the same play.
- **The owner's avatar carries its own particles** (ghosts, music notes): in a play shot they look like creatures in
  the scene. Before chasing one, ask the client which parts stand there.
- **Other windows' oddities are not yours**: MapWork's client prints `CreatureRig is not a valid member of ...
  SlimeFaceStage` (the movement lab kept in the work place); it was there before and does not ship.
