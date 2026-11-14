# Brief: the Mythic ultimates and the Legendary traits (docs/WEAPONS.md §11, step 5) - rules only

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
Branch `chatgpt/class-skills-5` from the latest `main` (never `main`, no PR). Rules and tests only: no client file.

## Read first

`CLAUDE.md`; `docs/WEAPONS.md` §2, §3 (the design; the numbers below win where they differ: they follow the owner's
later skill-power rule, an area strikes every foe at one weight), §3.7, §13; `docs/briefs/class-skills-4.md` (step 4,
merged: the three skills a class, their clocks, `classWorth`, `classAim`, `classAct`, the "cast" event, the barrier,
`classSlow`, the effects `dealt` and `curse`); `src/shared/ConfigClasses.luau`; `src/shared/Combat.luau` (whole: also
`leadOf` and how a monster's special with a `windup` is announced that long before it lands, `Combat.stun`, `pierce`,
`Combat.add`); `tests/spec/classes.luau`.

## What to build

**A. The ultimate: a class's fourth skill.** `Kinds.<class>.skills[4]`; a unit of tier 4 or 5 knows it.
- Its Config has `ultimate = true`, `first = 12`, `cooldown = 24`. It is first ready `first` seconds into the fight (a
  unit that joins later through `Combat.add`: `first` seconds after it joins), then `cooldown` seconds after each cast.
  The other skills' clocks do not change.
- `classAim` tries it first (highest tier down, as today) when it is ready, worth it, and the stagger allows it.
- **Stagger** (`Config.Classes.UltimateGap = 1.5`): a unit does not announce an ultimate less than `UltimateGap`
  seconds after another unit of its side announced one (one number a side on the fight). A unit that has to wait
  announces a lower skill or a plain blow; its ultimate stays ready.
- **Wind-up** (`windup` seconds in its Config; Bulwark, Sanctuary and Catalyst Cloud have none): the ultimate is
  announced by its "aim" event `windup` seconds before it lands, as a monster's special with a `windup` is (the unit's
  blow is put off so that it lands `windup` after the aim; it does nothing else meanwhile). A stun during the wind-up
  delays it as it delays any blow. If it is not worth it any more when it lands, the unit falls back to its plain
  action and the cooldown does not start (as in step 4).
- An attack ultimate is "worth it" when `minimum = 2` or more foes would be struck, OR the foe it would land on has
  rank `boss` or `miniboss`.

| Key | Name | Class | Rule | Worth it when |
|---|---|---|---|---|
| `bulwark` | Bulwark | Guardian | every living member of its side (itself too) gets effect `taken = 0.18` and the new effect `steady = 0.25` for `seconds = 4`, status "bulwarked" on each | `minimum = 2` or more living members of its side are the target of a living foe (1 when it is the only one left) |
| `whirlwind` | Whirlwind | Warrior | `windup = 0.8`; area `radius = 9`, `cap = 4`, `power = 1.15` round its target | the attack rule above, and it can strike its target |
| `arrow_rain` | Arrow Rain | Ranger | `windup = 1.2`; area `radius = 9`, `cap = 5`, `power = 1`; turns to the densest group it can strike | the attack rule above |
| `meteor` | Meteor | Mage | `windup = 1.5`; magic area `radius = 9`, `cap = 4`, `power = 1.25`; densest group | the attack rule above |
| `sanctuary` | Sanctuary | Healer | a heal of `factor = 1.1` on each of up to `count = 4` hurt team-mates (itself too) within `range = 22.5` of it, the most hurt first; each one healed gets effect `steady = 0.25` for `seconds = 3`, status "sanctified" | 2 or more of them are below `below = 0.6` of their health, or one is below `dire = 0.35` |
| `catalyst_cloud` | Catalyst Cloud | Alchemist | magic area `radius = 10`, `cap = 4`, `power = 0.8`; every foe struck and still standing gets `melt = 0.25` for `seconds = 4`, status "melted" (as Acid Rain's); densest group | the attack rule above |

New effect `steady` (`Config.Classes.Effects.steady = 0.5` is its cap): a stun that lands on the unit lasts that share
less (in `Combat.stun`, after its own steps and caps). Bulwark and Sanctuary need no foe in reach (as the team skills
of step 4).

**B. The Legendary traits** (a unit of tier 5; `Config.Classes.Traits = { guardian = { key = "last_stand", ... }, ... }`,
every number there). When a trait acts it sends `{ kind = "trait", from = <the unit>, to = <see below>, trait = key }`
unless said otherwise (`Event` gets `trait: string?` and `echo: boolean?`).

| Key | Class | Rule |
|---|---|---|
| `last_stand` | Guardian | Once a fight, damage that would make it fall leaves it at 1 HP instead (one helper wherever a unit's health is taken, so every source counts). "trait" event (`to` = itself). Then at once, if `tauntable` finds any foe (whatever its "worth" and Taunt's cooldown), it taunts exactly as Taunt does (same events, same statuses) without touching Taunt's clock. |
| `momentum` | Warrior | A foe that falls to a blow of its own (plain or skill) makes its Dash Strike ready at once (`skillReady.dash_strike = fight.seconds`). "trait" event (`to` = the fallen foe), at most one a step. |
| `hawkeye` | Ranger | Every `every = 4`th plain arrow of its own (a counter on the unit) also strikes ONE more foe: the nearest living foe behind its target on the arrow's line, found as Piercing Shot finds its line (no places: the next living foe), at `share = 0.55` of the plain blow's weight. That second "hit" carries `trait = "hawkeye"`; no separate "trait" event. Never a crit, never dodged. |
| `echo` | Mage | Arcane Barrage strikes again `delay = 0.6` seconds after it was cast, on the same foes that still stand, at `share = 0.5` of its weight: "hit" events with `skill = "arcane_barrage"` and `echo = true`. It takes no beat and needs no aim (a pending strike on the unit, done in `Combat.step`); nothing if the Mage fell or is stunned at that moment. |
| `overflow` | Healer | The part of its PLAIN heal (not Mend, Healing Ring or Sanctuary) that the healed slime's full health wasted becomes a barrier on that slime: at most `share = 0.1` of its max HP, `seconds = 4`, by the barrier rules of step 4 (the strongest only). Status "warded" with `skill = "overflow"`; no "trait" event. |
| `lingering_brew` | Alchemist | The armour melts it puts on (Acid Rain, Catalyst Cloud) last `seconds = 2` longer (the effect and its "melted" status). No event. |

**C. Events** (the client draws from them):
- "aim" with the ultimate's key, `windup` seconds before it lands (the client reads `windup` from the skill's Config).
- "cast" as in step 4: the first event of each ultimate when it acts (`to` = the target foe; Bulwark and Sanctuary: the
  caster itself), then its "hit" / "heal" / "status" events with `skill = key`. Statuses: "bulwarked", "sanctified",
  "melted", and the ones above.
- "trait" and the new fields reach clients as the others do (check `src/server/ZombieFights.luau`,
  `src/server/Dungeon.luau`, `src/shared/ArenaFight.luau`: change them only if they filter by kind or field).

**D. Tests** in `tests/spec/classes.luau` (seeded `Rng`, fixed times, no `os.time()`), one or more a rule:
the tier gate (tier 3 never casts an ultimate; tier 4 and 5 do); `first` and `cooldown` (12 s, then 24 s after the
cast; a unit added with `Combat.add` 12 s after it joins); the stagger (two ultimates of one side never announced less
than 1.5 s apart; the other side is free); the wind-up (the "aim" comes `windup` before the hits; a plain blow's aim
is unchanged); each ultimate's rule and its "worth it" (cast, not cast, the boss exception); `steady` (a stun 25%
shorter, capped at 0.5); each trait (Last Stand once only, with its taunt; Momentum resets the clock; Hawkeye on the
4th arrow only, at 0.55; Echo 0.6 s later at half weight on those still standing; Overflow's barrier and its 10% cap;
Lingering Brew's 2 s); a tier 1, 2 and 3 fight gives exactly the same events as before this change.

## Gates (Claude runs them; write the code so they pass)

`tools/check.ps1` (stylua, selene, lune tests, rojo build) and `tools/types.ps1` (`--!strict`).

## Do not touch

`src/client/**`, `src/shared/VfxLib/**`, `src/shared/ConfigZombies.luau`, `docs/**` (but this brief), any file of the
world or the village. No new library. Keep the file's style: tabs, comments that say why, numbers only in Config.

## Slips to avoid (your last jobs)

Lines at most 120 columns (stylua; break long tables over several lines); no unused variables, imports or
parameters (selene; `_` prefix); a field added to `Unit` or `Event` goes in the type and in `unit()`; `Config.Classes`
values read through `:: any` where the type is too narrow; no require cycles; tests never use `os.time()`; do not
loosen or delete an existing test; the branch starts from the LATEST main and deletes nothing newer; skill names in
`classWorth` / `classAct` are never hard-coded where a Config field can say it (a new skill should be one Config row
and one rule).

## Report

The files changed, the tests added (names), anything decided where the brief was silent, anything not done.
