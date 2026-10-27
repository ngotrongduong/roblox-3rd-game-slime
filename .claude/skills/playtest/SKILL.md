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
- The owner opens the built `GooLineage.rbxlx` himself when there is no Studio open with it; after a rebuild he reopens
  it (a second open says "in use by another Studio instance"). Never `open_application` Studio: it starts a second,
  empty Studio. Never take the mouse or keyboard while the owner is using the machine.
- If the owner is playing in the Studio window, let him play and read the log instead of grabbing the mouse.
- A local place file has no DataStore: nothing is saved there (the profile layer uses its in-memory store). Saving is
  tried in the published place only (see `publish`).

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
- Studio dialogs (Asset Manager import, File > Publish As) are invisible to computer use: the owner clicks them.
- The command bar runs a multi-line command with Ctrl+Enter; a command that touches `CurrentCamera` or destroys things
  in Edit mode asks "Dangerous Command Detected".
