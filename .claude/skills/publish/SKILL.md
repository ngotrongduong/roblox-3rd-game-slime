---
name: publish
description: Put a new version of Goo Lineage V2 on Roblox - the checks before, the steps in Studio, the checks after. Use only when the owner has said to publish this version.
---

# Publishing

Adapted from the owner's previous games. Publishing changes what real players get. It happens only after the owner said
so for this version (an approval is for that publish only).

## Before

1. Everything is committed; `& "C:\Roblox 3rd game\tools\check.ps1"` ends with `CHECK OK`; `tools\types.ps1` ends with
   `TYPES OK`; every test switch in `Config.luau` is off; no debug tool can reach players.
2. The change was play-tested (`playtest`), and anything touching saves, money, trades or remotes was read by the
   `reviewer` agent.
3. The save: a change to what the profile reads must load every save written by the version that is live. A spec feeds
   an old save through `ProfileLogic` / `FarmState.repair` before a field's meaning changes; never reuse a field name for
   something else. Note in `docs/STATUS.md` the commit that is live: a later hotfix is a worktree of THAT commit plus the
   fix, not of whatever master holds.

## Publishing

Studio must be signed in to the account that owns the game. The owner signs in; Claude never does, and never switches
accounts. Studio's publish dialogs are invisible to computer use, so the owner usually clicks them himself.

1. Open the built place (`GooLineage.rbxlx`).
2. File > Publish to Roblox As… > pick the experience by its name. **If the list does not show the game, this Studio is
   on another account: cancel and tell the owner.** Never click any other experience in that list.
3. Pick the existing place > Overwrite. A request to grant asset permissions is expected for assets of the owner's
   inventory.
4. Stop any play test in the published window and close that window with "Don't Save" (a window left open keeps running
   and keeps the file locked; close it by its process id, never every Studio: other windows may hold unsaved work).
5. A close stuck on "Applying script changes…" for more than a minute is a known Studio bug: the publish already
   finished; check the place's Version History on the Creator Hub, then end only that window's process.
6. When the save shape changed, **shut down all servers** (Creator Hub > Server management, forced migration) so that
   no old server writes saves in the old shape. Never roll back below a version whose saves the older code cannot read.

With an Open Cloud key set up by the owner, publishing is one script instead; the key is read from the owner's
environment and never written into the project.

## After

1. Verify: `games.roblox.com/v1/games?universeIds=<id>` (`updated`), or Studio's MCP `list_roblox_studios` /
   `script_grep` on the published place; press Play, read the log: no script errors, the save loads, the world line
   prints.
2. Saving is tried on the live game (Studio's "access to API services" may be off): change something, leave, come back,
   compare.
3. Commit, note in `docs/STATUS.md` and the project memory what was published and what was not seen.
4. Tell the owner in Vietnamese: what is new for players, what to try themselves (purchases above all).

## Not Claude's to do

Paying a publishing fee, buying anything, accepting terms, changing account or security settings (2-step verification,
ID check), switching the game between private and public without being asked.
