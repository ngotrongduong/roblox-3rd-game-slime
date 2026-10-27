# Goo Lineage V2 on Roblox — design

The owner's web game, rebuilt for Roblox. The original is fully documented in `docs/reference/`
(numbers, tables, screens, effects, and the owner's own history of requests and vetoes); this file
says what the Roblox version keeps, what it changes, and in which order it is built. Where this
file is silent, the original behaviour (as written in `docs/reference/`) is the spec.

## 1. What the game is

"Raise a wobbling bloodline on a sunny slime farm." A cozy idle farm on a hand-painted meadow:

1. **Breed** two rested adult slimes → an egg whose baby is decided at once (stats inherited
   between the parents with a 10% chance to beat the stronger one; two-allele colour genetics with
   dominance; a hidden pattern gene; Dual designs 5% and Secret slimes 1%, a pity egg after 25 plain
   eggs, new-player luck 5×/3×).
2. **Hatch** — eggs auto-hatch with a reveal that escalates with rarity; babies grow up in ~5 min.
3. **Collect** — 11 base colours, 20 Dual designs, 66 Secret slimes in the collection book.
4. **Feed** — slimes get hungry; slimes assigned to workstations (Berry Bush, Farm Plot, Fishing
   Pond, Cooking Kitchen) make food; starving workers stop.
5. **Sell** spare slimes for coins → **upgrades** (slots, food storage, incubation, cooldown, growth,
   the auto-breeding nest) and workstation unlocks. The farm keeps running while away (8 h cap).
6. **Fight** — at slime level 30, Siege: a squad of 10 equipped slimes plus the player's avatar
   against 10-wave runs on 4 rotating maps, ×5 harder each level; drops of materials → the Smithy
   crafts hand/head/tail gear (31/17/16 items, bronze → mythic). At 50 slots, World Boss raids
   (King Goo 15,000 HP, Queen Nyx 22,000 HP) with 20 slimes, a raid score and a leaderboard.
7. **Show off** — the avatar slime ranks up every 50 hatches and wears gear, wings (17) and fancy
   auras (16), frames and backgrounds from the Travelling Merchant (8 random wares, 5 of every 15
   minutes, the same for everyone).

Pillars, in the owner's words and choices: a **hand-made, alive world** (breathing, blinking,
hopping slimes, swaying plants, chatter); **juicy but never overdone** effects; **rarity and
grind** (drops rare, epic ≈ 10 runs, mythic ≈ 20); **never lose progress**; **smooth on phones**.

## 2. What changes for Roblox

| Area | Web original | Roblox |
|---|---|---|
| Players | single player in a browser | a server of up to 6 players; each owns a **farm plot**; a shared **plaza** in the middle holds the shop stall, the Smithy and the Travelling Merchant's stop (his clock is already global: everyone sees him arrive together) |
| Rules | client JS | the **server decides everything** (breeding, eggs, RNG, coins, drops); clients draw and ask. Times are server epoch seconds |
| Save | localStorage, schema v15 | one DataStore profile per player with session locking; saved on key moments (hatch, breed, sell, buy, run end), every few minutes, on leave and on shutdown — never constantly, never lost (the owner's sharpest complaint about the original) |
| The player | a slime avatar shown in a HUD box, steered with WASD in battle | the player **is** the avatar slime in the world (custom character: slime body + face + gear, wings and aura attachments), with a snappy hop-walk; the HUD box keeps the portrait |
| Workstations | only inside the Farm panel | real places on the plot; assigned workers go there and work |
| Siege | single player | the same runs, played on the server in a private arena; friends may later join |
| World Boss | single player, local leaderboard | co-op raid (each player brings a squad) and a global leaderboard |
| UI | DOM panels for PC | mobile-first ScreenGuis, touch targets ≥ 48 px, one modal at a time, the owner's cream/brown parchment style and their button art |
| Text | en + a little ja | Roblox localisation tables (en first, vi and ja next) |
| Money | none | Robux later (passes and products), never pay-to-win against the grind the owner wants; decided with the owner at that phase |

## 3. Look: how the owner's 2D art lives in a 3D engine

**Decided by the owner (2026-10-27): full 3D cartoon in the style of their art.** Slimes,
buildings, trees, props, NPCs, gear, wings and enemies become 3D models that match the owner's
paintings: saturated colours, chunky rounded silhouettes, glossy cel-like slimes, honey wood and
royal-blue/cream awnings, gold trims. The owner's PNGs are the reference for every model (shape,
proportions, colours, details — nothing added that the painting does not have, slimes have no
legs), and each model is checked side by side against its painting before it is used. Low poly for
cheap phones. 2D art keeps its place where it is 2D by nature: UI (the owner's button icons, frames,
avatar backgrounds, item icons) and the slime faces (the owner's emotion art as decals on the 3D
bodies). Dual and Secret designs keep their painted look as textures on the body where possible.

The camera follows the player at a comfortable top-down angle that recalls the original view, with
limited rotation and zoom.

The old options (painted 2.5D cut-outs; mixed) were not chosen.

Whatever the choice, the art goes to Roblox by the owner's own upload (Studio's Asset Manager or
an Open Cloud key the owner creates); Claude never signs in or uploads with the owner's account.

## 4. Owner rules carried over (summary — the full lists are in `docs/reference/04` §14 and `05-*` §3)

- Never redraw, recolour, crop, squash or resize the owner's art; never add details (slimes have
  no legs); new art only where the owner allowed it, matching the existing style.
- No rarity glow on gear or slimes in the world; no selection rings, ovals or circles under or
  behind slimes; no boxes or crack lines on the hatching egg; no white full-screen flash.
- Ground effects sit at the feet, centred on the shadow, under the units; only hits, slashes and
  projectiles go on top. No plain colour rings and no one asset recoloured per element.
- Auras do not bounce with the slime; wings flap gently and slowly; no random squash-and-bounce.
- No sound per hop or per enemy death; hit sounds and music are welcome.
- Drops are rare; difficulty steps are big; cosmetics are expensive.
- No animated slime bodies or avatar backgrounds (static originals; procedural squash/hop is fine).
- Lists keep their scroll and sort and hide slimes that cannot be used; icons over words.
- Dev tools never reach players.

## 5. Known issues of the original to fix while porting

Specialized Breeding costs 9 coins (a test value); the shop's Buy tab is a placeholder; the Smithy
has no tab for its 6 avatar-gear recipes; reviving halves a slime's base HP for good; the wave-10
boss is always enraged (the enrage clock starts at run start); the avatar counts mutated hatches
twice; mutation rolls are sequential where a single roll was intended. Each is decided when its
system is ported, and noted in `docs/STATUS.md`.

## 6. Build order

Each phase ends with `tools/check.ps1` at `CHECK OK`, a play test in Studio, and a short report to
the owner.

1. **Foundation** — the shared rules as pure Luau with tests: config, colours and genetics, stats
   and levels, breeding and egg resolution (duals, secrets, pity, luck), hatching, growth. The
   player profile: load, save, migrate, session lock.
2. **The farm** — the plot, the slimes on it (wander, hop, blink, moods), the nest house, eggs and
   the reveal, the breeding house, the collection book, selling, slots. First playable.
3. **Farm economy** — hunger and food, the four workstations with workers, upgrades, the
   auto-breeding nest, offline progress, the tutorial, achievements, highscores.
4. **The avatar and the plaza** — the slime avatar character, ranks, gear slots, wings and auras
   (the effects work), frames and backgrounds, the shop, the Travelling Merchant.
5. **Siege** — squads and loadouts, the server combat sim, the four maps, enemies and bosses,
   loot, the Smithy and crafting, revival.
6. **World Boss** — King Goo and Queen Nyx raids, co-op, the global leaderboard.
7. **Launch** — performance pass on a cheap phone, localisation, Robux products with the owner,
   badges, analytics.
