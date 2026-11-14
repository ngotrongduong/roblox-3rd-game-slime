# Brief: the team sheet - rows and tactics (docs/WEAPONS.md §6, §11 step 6) - rules, save and server

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
Branch `chatgpt/team-sheet` from the latest `main` (never `main`, no PR). Shared rules, the save, the server and tests
only: no client file (Claude builds the screen and the client's drawing against the contract below).

## Read first

`CLAUDE.md`; `docs/WEAPONS.md` §1 (Team settings), §3 (the Ring column), §6, §13; `src/shared/ConfigClasses.luau`;
`src/shared/Combat.luau` (whole: `Fighter`, `Unit`, `unit()`, `Combat.new`, `pick`, `targetOf`, `classAim`, `hop`,
`threatenedMates`); `src/shared/FarmState.luau` (`Team`, `newTeams`, `validateTeams`, `removeSlime`, `teamOf`);
`src/shared/Zombies.luau` (`setTeam`, `formation`, `fighter`); `src/shared/VillageRequests.luau` (`valid`, `run`:
`SetTeam`, `SetTeamRepeat`); `src/server/VillageRemotes.luau`; `src/shared/Dungeon.luau` (`squadSpot`);
`src/server/Dungeon.luau` (`squadFor`, `setSquad`, `startRun`, how the squad is placed again between waves, the start
event); `src/server/ZombieFights.luau` (`publishTeam`, `launch`, `beginFight`); `tools/balance/class_sim.luau`;
tests `farmstate`, `zombies`, `village_requests`, `classes`, `dungeon_move`, `zone_fights`.

## The owner's design (§6)

A team of four stands in rows: front, middle, back. The row comes from the weapon (Guardian, Warrior and a slime with
no weapon: front; Ranger, Mage: middle; Healer, Alchemist: back); the player may move a slime to another row (where it
starts a fight and a wave; its class brain stays). The team has one of three tactics: Balanced, Focus Fire, Protect
Backline. Both are saved on the team; a team that has none is Balanced with the weapons' rows.

## What to build

**A. Config** (`src/shared/ConfigClasses.luau`, every number and name here):
```
Rows = { Order = { "front", "middle", "back" }, Depth = 5, Brawler = "front",
	Default = { guardian = "front", warrior = "front", ranger = "middle", mage = "middle",
		healer = "back", alchemist = "back" } },
Tactics = { Order = { "balanced", "focus", "protect" }, protect = { danger = 1.5 } },
```
`Depth`: studs between two rows.

**B. The save** (`FarmState`): `Team` gets two OPTIONAL fields, absent by default (so `newTeams()` and every
`{ members = {}, repeatOn = false }` literal stay as they are, and no schema bump or migration is needed):
- `formation: { [string]: string }?` - slime id -> row, only for members whose row the player chose;
- `tactic: string?` - "focus" or "protect"; absent means Balanced.
`validateTeams` keeps a `formation` entry only for a current member with a row of `Rows.Order`, and a `tactic` only
when it is "focus" or "protect" (an empty `formation` is dropped to nil). `removeSlime` and `Zombies.setTeam` drop the
entries of slimes that are no longer members (a slime that stays in the team keeps its row).

**C. Pure helpers** (`src/shared/Zombies.luau`, or `Classes.luau` where it fits better; no require cycle):
- `rowOf(farm, slimeId): string` - the saved row of that member's team, else its class's default (`Classes.ofSlime`),
  else `Rows.Brawler`.
- `tacticOf(team): string` - "balanced" when absent.
- `rowSpots(rows: { string }): { { across: number, back: number } }` - one place a member, parallel to `rows`: the
  members of one row stand side by side, centred, `Config.Zombies.View.FormationSpacing` apart, in the order they come;
  `back` is 0 for the front row, `Depth` for the middle, `2 * Depth` for the back. A team whose rows are all the same
  stands in one line (no odd-slot stagger any more in a fight; the march keeps today's `Zombies.formation`).
- The fight spots use it everywhere a squad starts: the Dungeon (`Dungeon.squadSpot` becomes, or is joined by,
  `Dungeon.squadSpots(rows): { { x: number, z: number } }`, the same middle and `SquadBack` as today, rows stepping
  away from the monsters' side; wherever the squad is put back on its spots between waves uses the same) and the
  camp / zone fight (`ZombieFights.beginFight`: `Zombies.formation`'s place for a fight takes the rows; rows are
  looked up by slime id, since `launch` drops members). `tools/balance/class_sim.luau` keeps running (default rows).
- The Arena keeps `ArenaFight.spot` and the Balanced tactic (out of scope); its units still get their class's row.

**D. Combat** (`src/shared/Combat.luau`):
- `Fighter` gets `row: string?`; `Unit` gets `row: string` (set in `unit()`: the fighter's, else the class's default,
  else `Rows.Brawler`; a foe "front"). `Combat.new` takes the squad's tactic in its options (for example
  `opts.tactics = { squad = "focus" }`), kept on the fight per side; absent is "balanced"; the foe side is always
  "balanced". A Balanced fight gives exactly the same events as before this change (same seed).
- **Focus Fire.** The side's leader is its living Warrior, else its living Guardian, else its living unit with the
  highest attack (the first by unit order on a tie). When another unit of the side picks a target freely (in `pick`:
  after a taunt and after the Guardian's own protect branch, before `Aims` and the weighted roll), it takes the
  leader's target if that foe lives (resolve the leader's target first, through `targetOf`). The leader picks as
  today. A Healer's heals and an Alchemist's or any class's skill retarget (`classAim`, `snareTarget`, `curseTarget`,
  the densest group) are unchanged.
- **Protect Backline.** (1) A Guardian or a Warrior of the side goes for the nearest living foe whose target is a
  living team-mate of row "middle" or "back" (the Guardian's branch of today, by row instead of `Squishy`, and for the
  Warrior too), and it leaves its current target for such a foe (checked where `targetOf` keeps a target; not while it
  is taunted). With no such foe it picks as today. (2) In `hop`, a unit of row "middle" or "back" counts
  `K.DangerStuds * Tactics.protect.danger` as its danger range.
- `Zombies.fighter` does not set the row (it has no farm): the callers do (`fighter.row = rowOf(farm, id)` in the
  Dungeon's `startRun` and in `beginFight`), and pass the team's tactic to `Combat.new`. A Dungeon run has one team
  (`RunTeams = 1`): its tactic; if several ever go, the first team's.

**E. Requests** (`VillageRequests.valid` / `run`, beside `SetTeamRepeat`; a log line in `VillageRemotes` as the others):
- `{ action = "SetTeamRow", team = <1..Teams>, slimeId = <id>, row = <a row of Rows.Order> }`: refuses `BAD_TEAM`,
  `LOCKED` (as `SetTeam` does for a team not opened yet), `TEAM_OUT` (as `SetTeam`), `NO_SLIME` (not a member of that
  team), `BAD_ROW`. A row equal to the slime's default removes its entry.
- `{ action = "SetTeamTactic", team = <1..Teams>, tactic = <one of Tactics.Order> }`: refuses `BAD_TEAM`, `LOCKED`,
  `TEAM_OUT`, `BAD_TACTIC`; "balanced" removes the field.

**F. What the client reads** (the contract; Claude writes the client):
- `publishTeam` (`ZombieFights`) adds two attributes on `Teams/<n>`: `Rows`, a comma string parallel to `Members` with
  each member's row as `rowOf` gives it (the default included), and `Tactic` ("balanced", "focus" or "protect").
  They are published again after `SetTeam`, `SetTeamRow` and `SetTeamTactic` as the other team attributes are.
- The Dungeon's start event (the one that carries `members`) gets `rows`: the rows parallel to `members`, so the client
  calls the same `Dungeon.squadSpots(rows)`. Keep `Dungeon.squadSpot(index, count)` working (all "front") until the
  client is moved, or say in the report that it is gone.
- The camp fight's start event already carries `spots`: nothing new.

**G. Tests** (seeded `Rng`, fixed times, no `os.time()`):
- `farmstate`: a new farm's teams are unchanged; `repair` keeps a valid `formation` / `tactic`, drops a row of a slime
  that is not a member, a bad row, a bad tactic; `removeSlime` drops the slime's row.
- `zombies`: `setTeam` keeps the rows of slimes that stay and drops the others; `rowOf` (saved, class default,
  Brawler); `rowSpots` (4 in one row centred; 2 front + 1 middle + 1 back: the depths and the centring; the order kept).
- `village_requests`: both requests, every refusal, the default row / "balanced" removing the field.
- `dungeon_move`: `squadSpots` puts the middle and back rows farther from the monsters' side than the front, on the
  squad's side of the field.
- `classes`: a Balanced fight's events are identical to a fight made with no tactic; Focus Fire (the followers take
  the leader's target; the leader order Warrior, Guardian, highest attack; a taunted follower still obeys the taunt);
  Protect Backline (a Warrior turns to the foe that targets its Healer; with no such foe it picks as today; a back-row
  unit hops at the wider range and a front-row one does not).

## Gates (Claude runs them; write the code so they pass)

`tools/check.ps1` (stylua, selene, lune tests, rojo build) and `tools/types.ps1` (`--!strict`).

## Do not touch

`src/client/**`, `src/shared/VfxLib/**`, `src/shared/ConfigZombies.luau` (read `FormationSpacing` from it), the Arena
(`ArenaFight`, `ArenaRules`, `server/Arena`), `docs/**` (but this brief), any file of the world or the village's map.
No new library. Keep the file's style: tabs, comments that say why, numbers only in Config.

## Slips to avoid (your last jobs)

Lines at most 120 columns (stylua); no unused variables, imports or parameters (selene; `_` prefix); a field added to
`Unit`, `Fighter` or `Event` goes in the type and in `unit()`; a table literal handed to a typed list is typed first
(`local e: Event = {...}`); `Config.Classes` values read through `:: any` where the type is too narrow; no require
cycles (`Classes` requires `Config` only); tests never use `os.time()` and read only lists they filled themselves; do
not loosen or delete an existing test; the branch starts from the LATEST main and deletes nothing newer.

## Report

The files changed, the tests added (names), the exact shapes of the new attributes and event field, anything decided
where the brief was silent, anything not done.
