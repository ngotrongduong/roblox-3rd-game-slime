# Status

## 2026-10-27 — project started

Done
- The original web game (makeplay.ai, "Goo Lineage V2") was read in full: its JS source, its
  `AGENTS.md`, 600+ art, sound and animation files (`reference/goo-lineage-web/`, gitignored),
  and all 514 messages the owner sent its AI builder.
- Reference specs written: `docs/reference/01`–`05` (farm, battle, UI and world, effects, the
  owner's history of requests and vetoes).
- `docs/DESIGN.md`: what the Roblox version keeps and changes, and the build order.
- Project skeleton: Rojo tree, Lune tests, StyLua, Selene, `tools/check.ps1` (CHECK OK).

Decided by the owner
- The look (`docs/DESIGN.md` §3): full 3D cartoon in the style of their art. Start Phase 1.

## 2026-10-27 — Phase 1, Foundation: done (logic and tests; not yet run in Studio)

Done
- Farm rules in `src/shared` (pure Luau, run in Lune and Roblox): `Rng` (mulberry32, matches the
  JS), `Colours`, `DualDesigns` (20), `SecretRecipes` (66), `Stats`, `Genetics` (colour + pattern
  genes), `Luck`, `Growth`, `Mutations`, `Breeding` (eligibility, timers, stat inheritance, eggs,
  pity, tutorial first egg), `Hatching` (idempotent), `FarmState` (types, `newFarm`, field-by-field
  `repair`). Times are server seconds.
- Player profiles: `ProfileLogic` (envelope, session lock, migrations, last-good copy, size
  budget), server `ProfileStore` (UpdateAsync lock, retries, budget, BindToClose) and `PlayerData`
  (get / update / markKeyMoment; autosave every 5 min when changed, key moments within 4 s).
  `FarmSave` plugs the farm in: a stored farm that cannot be read is never replaced by a fresh one.
- 136 Lune checks pass; `tools/types.ps1` TYPES OK.

Decisions taken while porting
- Starters are created already adult (the original left them babies for 3 s).
- Mutation rolls stay sequential like the original (secret 1%, dual 5%, base 10%), in one function
  (`Mutations.rollCategory`) so a single categorical roll can replace it later.
- Starting slots 20 (+5 a level, max 220), as in the original.

Next
- Phase 2, The farm: the 3D plot and the slimes on it, the nest house, eggs and the reveal, the
  breeding house, the collection book, selling. Needs the first 3D models (slime body, nest house)
  made from the owner's paintings, and remotes for Breed / Hatch / Sell.
- First Studio play test of the profile layer (in-memory store in an unpublished place).

Notes
- The MakePlay builder also wrote a `ROBLOX_EXPORT.md` in the original project on request, but the
  file is not served by the game host; it was rebuilt from its own notes (it has no access to the
  old chat), so the owner-history docs here are the better source.
- Sounds in `assets/lib/bvker-foley/` of the original come from a third-party library: check its
  licence before uploading them to Roblox.
