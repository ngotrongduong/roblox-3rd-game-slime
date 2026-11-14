# Brief: the Uncommon and Epic class skills (docs/WEAPONS.md §11, step 4) - rules only

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
Branch `chatgpt/class-skills-4` from the latest `main` (never `main`, no PR). Rules and tests only: no client file.

## Read first

`CLAUDE.md`; `docs/WEAPONS.md` §2, §3 (the design; the numbers below win where they differ: they follow the owner's
later skill-power rule), §13; `src/shared/ConfigClasses.luau`; `src/shared/Combat.luau` (whole: `blow`, `area`,
`pierce`, `classAim`, `classAct`, `addEffect`, `effectOf`, `status`, `Combat.stun`, `unit`, `Combat.step`);
`tests/spec/classes.luau` (how a class fight is tested: copy its helpers).

## What exists

A slime with a weapon fights by its class with ONE skill (`Kinds.<class>.skill`, one timer `Unit.skillReady`). A skill
takes the place of the coming blow: `classAim` says which skill the coming blow is (announced by an "aim" event 0.3 s
before), `classAct` does it. `Unit.tier` is the weapon's tier, 1-5 (nil = 1).

## What to build

**A. Several skills a class, by the weapon's tier.**
- `Kinds.<class>.skills = { common, uncommon, epic }` replaces `skill` (every reader moves to `skills[1]` or the list).
  A unit of tier t knows the first `min(t, #skills)` of them (tiers 4 and 5 fight with the three until step 5).
- Each skill has its own cooldown: `Unit.skillReady` becomes `{ [key]: number }` (seconds into the fight). At the start
  every skill is first ready at `OpeningCooldown + its cooldown * OpeningShare`, as the one skill is today.
- `classAim` tries the unit's skills from the highest tier down and announces the first that is ready AND worth it
  (rules below); none: a plain blow. Only the skill cast starts its own cooldown. Behaviour of a tier 1 unit must not
  change at all (every existing test passes untouched, same seeds, same numbers).
- An attack skill weighs `kind.factor * SkillPower[tier] * (s.power or 1)` on every foe it strikes (`skillWeight`
  takes the skill). A single-target skill strikes its target only; an area skill every foe within `radius` of the
  target, all at the same weight (a fight with no places: `cap` foes), through the existing `area`.

**B. New effects** (`Config.Classes.Effects` caps; the strongest of a kind only, through `addEffect` / `effectOf`):
- `dealt = 0.25`: damage the unit deals is that share more (every blow of its, in `blow`).
- `curse = 0.5`: heals ON the unit are that share weaker (a monster healer's heal and mend special, `classHeal`).
- `slow`: class slows go through one helper that keeps the strongest and caps it: `SlowCap = 0.35`, a boss
  (`rank == "boss"`) `SlowCapBoss = 0.15`. It sets the existing `slowUntil` / `slowBy` and sends status "slowed" with
  the skill's key. The monsters' stings keep working as today.
- A barrier: `Unit.barrier` (health it still absorbs) and `Unit.barrierUntil`. Damage is taken from the barrier
  first; the "hit" event's `amount` is what reached the health and a new field `absorbed` what the barrier took. The
  strongest only (a new one replaces a weaker or ended one, never adds). When it is used up before its time, send
  `{ kind = "status", to = id, status = "warded", seconds = 0 }` (the client ends the look).

**C. The twelve skills** (`Config.Classes.Skills`; names exactly these; every number in Config, none in the logic).

| Key | Name | Class, tier | Rule | Worth it when | Cooldown |
|---|---|---|---|---|---|
| `shield_bash` | Shield Bash | Guardian 2 | `kind = "single"`, `power = 1.2`, `stun = 0.5` on its target | always when ready and it can strike | 11 |
| `area_slash` | Area Slash | Warrior 2 | area `radius = 7`, `cap = 3`, `power = 0.85` | 2 or more foes would be struck | 8 |
| `arrow_volley` | Arrow Volley | Ranger 2 | area `radius = 9`, `cap = 5`, `power = 0.7`; turns to the densest group it can strike (as Acid Rain does) | 2 or more foes would be struck | 12 |
| `frost_burst` | Frost Burst | Mage 2 | magic area `radius = 8`, `cap = 4`, `power = 0.7`; every foe struck and still standing is slowed `slow = 0.25` for `seconds = 2.5`; densest group | 2 or more foes would be struck | 13 |
| `healing_ring` | Healing Ring | Healer 2 | a heal of `factor = 0.7` on each of up to `count = 4` hurt team-mates (itself too) within `radius = 11` of the most hurt one within `range = 22.5`, the most hurt first | 2 or more of them are below `Config.Classes.HealThreshold` | 16 |
| `squad_tonic` | Squad Tonic | Alchemist 2 | every living member of its side (itself too) gets `dealt = 0.2` for `seconds = 4`, status "empowered" | 2 or more members of its side have a living target they can strike now | 18 |
| `shield_wall` | Shield Wall | Guardian 3 | up to `count = 2` team-mates (not itself) within `range = 16` that a living foe is going for, the most hurt first, get effect `taken = 0.15` for `seconds = 3.5`, status "walled" | 2 or more such team-mates (1 when only one team-mate is left) | 17 |
| `breaker_strike` | Breaker Strike | Warrior 3 | `kind = "single"`, `power = 1.1`, `ignore = 0.2` of the target's DEF | always when ready and it can strike | 12 |
| `snare_arrow` | Snare Arrow | Ranger 3 | `kind = "single"`, `power = 0.7`, slows `slow = 0.25` for `seconds = 2.5` (a boss the capped share for `bossSeconds = 1.5`); it turns to the nearest melee foe going for it that it can strike, else its target | always when ready and it can strike | 13 |
| `arcane_lance` | Arcane Lance | Mage 3 | magic `kind = "single"`, `power = 1.3`; `barrier = 1.35` times that against a target with a barrier | always when ready and it can strike | 12 |
| `ward` | Ward | Healer 3 | a barrier of `Combat.healAmount(attack, factor = 2.5) * healShare`, at most `share = 0.2` of the team-mate's max HP, for `seconds = 5`, status "warded", on the team-mate (not itself) within `range = 15` that a living foe is going for with the smallest health share below `below = 0.8` | such a team-mate exists | 14 |
| `cursed_flask` | Cursed Flask | Alchemist 3 | no damage: its target foe gets `curse = 0.35` for `seconds = 5`, status "cursed"; the target is the living foe with the smallest health share that is not cursed now | the foes have a living healer (a role in `Config.Combat.Heals`, or class "healer") and such a target exists | 12 |

The skills that strike nobody (Healing Ring, Squad Tonic, Shield Wall, Ward, Cursed Flask) need no foe in reach: they
are cast in place of the coming blow like Taunt and Mend. A skill that is not worth it at the moment it acts (its
team-mates healed, the foes gone) falls back to the plain action and does NOT start its cooldown.

**D. Events** (the client draws from them; `Event` gets the new fields):
- "aim": as today, with the new skill's key.
- A new `{ kind = "cast", from = caster, to = <the target foe; for a team skill the caster itself>, skill = key }`,
  the first event of each of the twelve skills when it acts (not for the six Common skills: their drawing stays).
- "hit" / "heal" with `skill = key` as today; "status" with `status` = "slowed", "stunned", "empowered", "walled",
  "warded", "cursed" and `skill = key`.
- Check that the server forwards the new kind and fields to clients as it does the others
  (`src/server/ZombieFights.luau`, `src/server/Dungeon.luau`, `src/shared/ArenaFight.luau`): change them only if they
  filter by kind.

**E. Tests** in `tests/spec/classes.luau` (seeded `Rng`, fixed times, no `os.time()`), one or more a skill:
the tier gate (a tier 1 unit never casts a tier 2 skill; a tier 3 unit casts all three, each on its own cooldown);
each skill's rule and its "worth it" (cast and not cast); the weight formula; stun, slow (cap, boss cap and seconds),
dealt (+20% on a plain blow, capped at 0.25), curse (a monster's heal and a class heal 35% weaker), the barrier
(absorbs first, `absorbed` on the hit, never above 20% of max HP, ends at its time, the "warded" 0 event when used
up, Arcane Lance's 1.35), the "cast" event first; a tier 1 fight gives the same events as before.

## Gates (Claude runs them; write the code so they pass)

`tools/check.ps1` (stylua, selene, lune tests, rojo build) and `tools/types.ps1` (`--!strict`).

## Do not touch

`src/client/**`, `src/shared/VfxLib/**`, `src/shared/ConfigZombies.luau`, `docs/**` (but this brief), any file of the
world or the village. No new library. Keep the file's style: tabs, comments that say why, numbers only in Config.

## Slips to avoid (your last jobs)

No unused variables, imports or parameters (selene; `_` prefix); a field added to `Unit` or `Event` goes in the type
and in `unit()`; `Config.Classes` values read through `:: any` where the type is too narrow; no require cycles; tests
never use `os.time()`; do not loosen or delete an existing test; the branch starts from the LATEST main and deletes
nothing newer; `Config.luau` copies `Config.Classes.Skills` into `Config.Combat.Skills` already (line ~902).

## Report

The files changed, the tests added (names), anything decided where the brief was silent, anything not done.
