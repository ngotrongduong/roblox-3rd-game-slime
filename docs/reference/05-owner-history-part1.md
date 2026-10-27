# 05 — Owner history, part 1 (messages 1–257, seq 0 → 9560, 2026-08-24 → 2026-08-31)

Source: the owner's own messages to the makeplay.ai builder (`window.__user.slice(0,257)`), oldest first. Attachments (images) are not visible in the text; where a message says "here is / use this", art was attached. Exact repeats are noted as "(re-sent)". The game was first called **"Slimeage"**; the battle mode is **"Slime Siege"**.

Context to keep in mind: the builder twice lost work and the owner made it write a `PROJECT_HANDOFF.md` and restart from a "fresh recovery session" (seq 2427/2442, re-sent 3741/3763 and 7568/7569/7595). Many complaints below come from that unstable period.

---

## 1. Timeline

### 2026-08-24 — Phased rebuild spec (Phases 1–6)
- **0** — Master brief "Rebuild … Slimeage": loop *breed → discover mutations → produce food → sell → expand → repeat*; cozy illustrated farm (pond, tree, storage chest, breeding house, food workstations, market stall). Small phases, stop for approval, tests + console check + commit after every edit, files < 300 lines, all balance in `config.ts`. No combat yet. 4 starting slimes 1/1/1/10HP. "I already have all the artwork. Do not generate, redraw, or permanently modify any assets." 11 base colours / 19 duals / 55 secrets (read totals from data). Equipment slots planned: Head, Tail, Held, Off-hand. Save safety + performance rules.
- **145** — Phase 2: stats, level formula, 11 colour IDs, two-allele genotype vs phenotype, dominance table (temporary, "show me the table"), dev-only genetics panel, save migration, tests.
- **221** (re-sent **313**) — Phase 3: breeding, cooldowns, eggs with embryo fixed at creation, population reservation, idempotent hatch, simple crack/pop effect, breeding panel that hides recessive genes.
- **318** — Phase 4: Dual & Secret as separate `appearanceMutation`; mutated parents breed as their base phenotype; one roll per category; reveal text "New Dual Colour!" / "Secret Slime Discovered!"; discovery tracking; dev force tool.
- **456** — Phase 5: workstations (Berry Bush, Farm Plot, Fishing Pond), shared food, hunger, auto-eat, capped offline progress (numbers in §5).
- **595** — Phase 6A/6B: coins & selling, favourites, capacity, slime grid + filters/sorts, details panel, collection book (Base/Dual/Secret tabs), HUD; polish (art integration, slime idle animation, collision, Y-sort, egg reveal, UI, perf audit, full regression).

### 2026-08-25 — First feedback, farm UI, emotions, new map
- **693** — Slime list: show stats next to LV; **remove the filter tabs** (Base/Dual/Secret/Favourite/Hungry/Working/Available); 5 cards per row.
- **803** — Breeding house: no Parent A/B pickers; show the slime-list (available only, same sort), pick 2, confirm.
- **804** — All slimes ~30% smaller; babies/growing slimes smaller than adults.
- **805** — Remove yellow selection ring; clicking a slime opens its details.
- **806** — Don't save constantly; every 5 minutes is enough.
- **807 / 961** — Farm window redesign: compact grid of workstation cards (image, worker, progress, time→food, status); click a card → slime picker in the same window with per-slime predicted output ("84s → 6 Food"), replace-worker confirm; cream panel/brown borders/rounded. Uploaded 3 station artworks (Fishing Dock, Berry Collection, Farming).
- **1038** — Asked for the whole code zipped so they could audit it.
- **1090** — Add **Cooking station**; remove white box covering the bottom of each station picture; **3 slimes per station** sitting at fixed seats (Fishing: stool / post / rock; Farm Plot: table / by wheelbarrow / on the field; Berry Bush: stool / rock / second rock; Cooking: stool / stool / by the oven); only assigned slimes appear; themed random talk bubbles (fish, veg, berries/bugs/leaves, cooking, arguing, small talk) with quiet gaps.
- **1184** — Slime list shows "baby" + grow-up countdown and breeding cooldown.
- **1222** — Remove the info banner under each station; fit art fully; only progress bar + food per cycle; station slimes 30% smaller; recheck seat positions.
- **1270 / 1365** — Uploaded emotion art; build an emotion module for all slimes.
- **1383** — "remove all the emotion and faces I gave you … just make your own emotion" (reversed in 1441+).
- **1441** — Use this (transparent) emotion art directly on the slime. **1481** — remove the blue oval under the eyes. **1497** — asked which emotions exist.
- **1534** — New Farm Plot art; all 4 station windows same size; slimes must sit centred on stool tops / rocks / table.
- **1535** — Working/breeding slimes are not shown on the main field.
- **1536 / 1615 / 1851 / 1852 / 1880 / 2109** — Reviewed emotion art; removed some, replaced others with new uploads (2109: replace the builder-drawn "Sad" with owner art).
- **1637, 1663, 1679–1681, 1834, 1835, 1902, 2110, 2198** — Many pixel nudges of seat positions per station (e.g. Berry Bush rock seats −15px y, Cooking all +15px down, Fishing top seat up 20/left 5).
- **1695** — Talk bubbles must sit above the slime's head. **1717** — change emotions to feel lively. **1805** — emotions changed every time a slime moved: make it natural and varied.
- **1765** — Highscore board: top players by highest LV / ATK / DEF / SPD / HP.
- **1833** — Breeding window: Confirm Breed at the top; remove bottom Close button.
- **1914** — Sprite-sheet extraction of map assets (ponds, trees, bushes, rocks, flowers, grass, ground patches) into individual PNGs + manifest; **2.5D depth = dynamic Y-sorting by feet/ground anchor, not blur**; pond fully non-walkable (polygon), trees collide at trunk base, bushes/rocks at footprint, bare patches/grass = walkable decals; pathfinding with navgrid; layer order bg → ground decals → pond → Y-sorted → foreground → UI.
- **2108** — Dev-only Map Editor (palette, drag/scale/duplicate/delete/undo, overlays, Test Map, drafts, export/import JSON, **Publish & Lock Main Map** to a versioned file all players load).
- **2213** — New background art; remove all assets from the map. **2277** — still a wooden fence and tree; remove.
- **2314** — Editor: drag-and-drop placement recorded automatically; button to hide UI while editing.
- **2348** — Gentle breeze sway for all bushes, grass, plants, flowers; trees sway only top 2/3 (base still); rocks never move.
- **2368 / 2369** — Replaced rock-large-06 (it is actually a flower → flowers group, must sway) and tree-large-01.
- **2383** — Complaint: all assets they had placed on the map were erased after a code change.
- **2427** — "Stop coding now" → write `PROJECT_HANDOFF.md`. **2442** — fresh recovery session rules (§4). **2443** — full audit & optimisation brief: "The game is now complete, and I have manually adjusted many gameplay and visual details" — preserve everything.

### 2026-08-25/26 — Map publishing, mutations art
- **2452** — Make the loading screen.
- **2488** — Complaint: game reset/deleted everything after map editing; export/import JSON, Save/Load Draft all broken ("draft saved" then "No saved draft").
- **2533, 2538–2541** — Pasted their saved map JSON (3 parts) and asked to make it the permanent main map for every player (see §5).
- **2578** — Uploading mutation art; temporary test chances 90% base / 50% dual / 30% secret; first 5 dual artworks, "you just name it yourself". **2582–2584** — next 3 groups of 5 duals (20 dual artworks total).
- **2692** — Mutation-system audit spec: final dominance table, base-colour mutation, recessive pattern gene (solid/duochrome), Secret recipes (55, 10 colours, Blue excluded for now), single categorical roll, data files.
- **2707** — Full list of 55 Secret names + designs (§5).
- **2712** — "<300 lines" is a guideline, not strict; chances corrected to **Secret 0.1%, Base mutation 10%, Dual 1%**.
- **2854** — Temporary test chances: base 70%, dual 50%, secret 30%.
- **2911 / 2917** — Complaint: strange mutations appeared that are not their art ("these are not what I send you").
- **2947 / 2970** — Uploaded base-colour slime art. **2981 / 3005** — slimes squished: keep original shape; check all.
- **3001** — "do we have these colour yet" (art check).
- **3035 → 3496** (3035, 3052, 3065–3069, 3107, 3119, 3289, 3306, 3477, 3478, 3496) — Uploaded Secret slime art in batches with name+parents+design text; "if the name and picture don't match, ask me".
- **3120** — Slimes cluster in the centre: remove old-map boundary, roam anywhere in the map.
- **3194** — Collection book: even grid, 5 per row.
- **3195 / 3269 / 3316** — Shop asset at ~(1311, 526), scale 1.5, solid like a rock, must stay still (no sway).
- **3331 / 3353 / 3354 / 3355** — New assets: one walk-over ground layer; one solid top-layer object; one "very top layer, slime only goes behind"; remove old shop to rebuild from 3 new pieces. **3419** — the 3 pieces never move. **3433** — use them at original size so they join up.
- **3461** — Pasted JSON for shop pieces (bridge-01, shop-counter-01, shop-awning-01 + rocks/grass).
- **3507** — Design and replace all buttons.
- **3529** — Uploaded loading-screen background; a real bouncing slime (own asset) on it.
- **3543** — Complaint: a newly discovered mutation first shows a strange slime picture, then snaps to newborn size.

### 2026-08-27 — Shop NPC, Sky Blue secrets, Slime Siege phases 0–12
- **3581** — Shopkeeper slime on the bridge in front of the shop, idle-animated, click → shop window with **BUY** and **SELL** tabs (placeholder items; multi-select selling of slimes); closes only on outside click or Close. **3623** — move to (1140, 486). **3640** — keeper above everything.
- **3656 / 3668 / 3669** — 11 new Secret recipes for **Sky Blue** (§5).
- **3723 / 3774 / 3828** — Awning & counter must Y-sort; counter still covers slimes → make counter ground-level and solid like the pond.
- **3799** — Slimes with big decorations get tiny bodies when scaled to the same frame: detect body and equalise body size.
- **3839** — Slime Siege Phase 0 (feature flag, battle folder, state machine TEAM_SETUP→…→RETURN_TO_FARM, one exclusive activity state). **3865** Phase 1 equipment data (Head/Hand/Tail, ownership states). **3922** Phase 2 loadout UI. **3964** Phase 3 battle scene/team select/formation. **4073** Phase 4 combat kernel + Sword AI. **4168** Phase 5 other five Hand AIs. **4210** Phase 6 enemies & wave director. **4296** Phase 7 fallen/revival. **4432** Phase 8 loot ledger. **4498** Phase 9 crafting tiers. **4518** Phase 10 bosses/checkpoints/exclusive rewards. **4536** Phase 11 UI/VFX/audio. **4570** Phase 12 save recovery/balance/perf/release.
- **4619** — Uploaded random battle maps; add a button to join Siege; random map per battle; "also generate the enemies".
- **4681** — 10 starter weapons (2 each of 6 types) with one stat bonus each (§5).
- **4715** — Complaint: no weapons to equip. **4720** — Equipment must be visible on the slime; uploaded anchor guide image (red = hat, purple = weapon, black = tail, yellow = face).

### 2026-08-28 — Battle fixes, egg reveal, upgrades, buttons, blacksmith
- **4785** — Siege has no background (use theirs), slimes 50% smaller, no visible weapons on slimes/enemies, no movement animation.
- **4843** — Dead slimes still visible on farm: show half-transparent; revive with food; then fully normal. **4913** — dead slimes not in breeding list.
- **4883** — Hatching an egg froze the game.
- **4938** — Autosave at important moments (after siege battle, new discovery, rare/secret hatch).
- **4966/4967/4968 (re-sent 4970)** — Team-select list must not scroll to top on each click; battlefield background full-screen; some slimes vanish; remember the last Siege team.
- **5048** — Ranged slimes are the ones disappearing. **5050** — Saving constantly during battle; save only at the end.
- **5082** — Want to see projectiles and buff/debuff effects. **5146** — Can't see healing or alchemist buffs.
- **5175** — Farm slimes clickable while the battle result window is still open.
- **5191** — Reset mutation chances to normal.
- **5219** — Remove counter/awning/bridge; use one new shop-front art, Y-sorted; NPC merchant Y-sorted too. **5297** — shop front up 60px.
- **5267 / 5347** — Asset category fixes (several "rock" files are grass; several flowers belong to bushes).
- **5307** — Grass draws over a slime that is lower on screen: Y-sort bug.
- **5366** — Fancy rarity-based egg reveal in screen centre: PRELOAD→EGG_ENTRANCE→ANTICIPATION→CRACKING→ENERGY_BURST→SILHOUETTE→SLIME_REVEAL→RESULT→COMPLETE; never reroll.
- **5409** — Uploaded rainbow egg set: cut and use for reveal and incubation images.
- **5444** — Breeding cooldown and grow-up time rise with level (~1 s per level); HP improvement 5–10 (superseded by 5847).
- **5500** — Upgrades button (§5); new players start with 20 slime slots.
- **5592 / 5647** — Remove the rectangle box around the egg during reveal (still there at 5647). **5593** — crack lines look bad; remove, find a better way.
- **5609** — Reset still shows 100 slots; new players must get 20. **5755** — bought slot upgrade, capacity unchanged.
- **5627** — Design icons for all buttons. **5665** — Replace HUD buttons with owner's new art (Upgrades, Siege map, Slime list, Highscore, Breeding, Working station, Slime gallery, Settings): "No brown creamy circle, only my artwork alone". **5691** — squashed: keep original shape. **5707** — 2× larger. **5890** — +20% more.
- **5730** — Add blacksmith at (731, 261), Y-sorted like the shop. **5756** — add a slime (blacksmith NPC) at (801, 304). **5906** — replaced blacksmith art.
- **5754** — All windows close when clicking outside.
- **5816 → 6318** — Hammer-on-anvil animation saga: 5873 realistic large arc, hit, small bounce, at (712,220); 5907 at (742,220), half the swing height, slower, flipped; 6019 (762,240); 6053 just mirror it, no re-checking; 6091 redo the arc for the flipped image; 6111 up 20px; 6124 +5px, sparks at impact, furnace flames; **6148 "you ruined the whole game, revert"**; 6184 redo agreed steps; 6204 sparks + fire again; 6236 sparks/flame hidden behind anvil/furnace; 6318 spark +5 up / −5 left.
- **5847** — Restated stat inheritance (10% chance, +1–3 ATK/DEF/SPD, **HP +10–30**); verify.
- **5931** — Upgrade: auto-hatch ready eggs.

### 2026-08-29 — Specialized Breeding nest, egg FX, Snowy mobs
- **5969** — Specialized Breeding nest spec (§5); two images: door open (free slots) / door closed (breeding); chosen pair walks to the house front.
- **6037 / 6264 / 6394** — Test price 9 coins for Specialized Breeding and Auto-hatch (6394: still 99999c).
- **6265** — Nest at (271, 620); locked door + "Unlock to open" until purchased; after unlock clicking opens the nest window.
- **6344** — Furnace flame looked like a volcano: should be gentle flicker, embers drift up slowly; anvil sparks spray randomly upward over an area. **6380** — flame at (801, 196).
- **6420** — Egg must sit centred in the glow circle.
- **6452 / 6453** — Breeding cooldown and grow-up time not working (babies breed instantly).
- **6548** — Sell list sort resets to Newest after each click.
- **6549 / 6550 / 6551 / 6717** — Specialized breeding: no slimes come; toggle doesn't update; remove Pause (on/off only); later "cannot turn on or off".
- **6747** — Don't list not-ready slimes in the breeding group.
- **6779** — Upgrades lost after reset/reload.
- **6839 / 6985** — Pair walks to the house; egg starts only when both arrive; pair walks at 2× speed.
- **6905** — Breeding house solid (walk around, no jumping through).
- **6951** — Pair shows "loved" emotion with hearts floating up while walking. **7059 / 7099** — hearts 50% smaller, 50% transparent.
- **7098** — Stat-boost egg FX: HP = hearts gathering into egg, ATK = stars, DEF = shield, SPD = lightning; new matching icon set; special reveal. **7157** — only eggs with an improved stat get it.
- **7239** — All equipment drawn 3× larger (later 50% smaller, 8741).
- **7293** — Snowy map mobs (uploaded): Big Ice Monkey = boss; spider = ranged; others melee; add projectiles and an FX library (slashes, claw marks, bite marks) reusable for other mobs; "make as many assets as you can".

### 2026-08-30/31 — Save loss, battle VFX, gear
- **7479 / 8305 / 8787** — Save regressions: returning loads an old save; slime progress lost on refresh while upgrades survive; 50 slimes back to 20.
- **7570** (re-sent 7604) — Audit & optimisation brief again.
- **7650** — Optimise battle scenes. **7758** — After a wave clears the game stops; should start next wave after a short pause.
- **7900** — Projectiles per weapon (arrows, magic orbs, sword cuts); green healing crosses rising on healed slime; buff aura for the whole buff duration; debuff aura on enemies. **8019** — sword slash effects.
- **8049** — Hide unavailable slimes in Siege team list.
- **8077** — Battle slimes block each other: let them pass through allies.
- **8078** — Verify healers actually heal.
- **8079** — Food storage +100 per upgrade level.
- **8398** — Hit effects must match weapon (arrows were showing claw marks).
- **8550** — Some slimes vanished from the list but still hold weapons that can't be unequipped. **9489** — a stray shield labelled `Item_in_battle_escrow`: remove it.
- **8551 / 9405** — Shield slimes flip between targets / hang back; they are melee: lock a target and close in.
- **8656 / 8657** — New art for all weapons the builder had generated; replace; generate any missing ones in that style. **8741** — weapons 50% smaller. **8846** — remove Iron Sword, Longbow, Shield (no art yet).
- **8931** — Enemies drop gold, food, sometimes crafting materials; design crafting recipes for weapons, hats, tails with small bonuses; generate drop/equipment art.
- **9125** — Crafted items fall into 6 AI families; Diablo-style loadout (item icons, hover tooltips, live preview on the slime, inventory stays open while equipping).
- **9187** — Rarity border colours. **9246** — Glowing particle effects. **9316** — Impact hits (arrow, potion, magic) 50% smaller. **9341** — Enemy death animation. **9404** — More natural movement animation for slimes and mobs.
- **9406** — Mythic/Epic gear glow on the farm: golden beacon for Mythic should be ~1.5× slime height, must not vanish, must follow the slime.
- **9560** — Remove the yellow circle in the middle of the battlefield.

---

## 2. Owner preferences & taste

- **Cozy, illustrated, hand-made look.** UI = "Warm cream panel, brown borders, rounded cards and buttons", large images, colour-coded bars (green working, orange hungry/pending, red starving/invalid, gray unavailable) (961). Later wanted their own button art *alone*, no frame (5665).
- **Alive world.** Slimes breathe, wobble, blink, hop, small idle actions, staggered so they don't sync (595); varied, natural emotion changes (1717, 1805); themed chatter bubbles with quiet pauses (1090); plants sway in a gentle breeze, trees only the top 2/3, rocks and buildings never move (2348, 3269, 3419).
- **2.5D depth by Y-sorting** on feet/ground anchors, never blur (1914); repeated insistence that shops, counters, NPCs, grass sort correctly (3723, 3774, 5219, 5307).
- **Freedom of movement:** slimes roam the whole map, not a central blob (3120); obstacles are walked around, not jumped through (6905).
- **Juicy but readable effects:** rarity-escalating egg reveal in the centre of the screen (5366); stat-themed egg FX (7098); hearts for love pairs (6951); weapon-matched projectiles and hit marks, healing crosses, buff/debuff auras (7900, 8398); sparks and embers that drift and scatter (6344); enemy death animation, glow, rarity borders (9187–9341).
- **But not overdone:** "Avoid sudden full-screen white flashes", smooth glow gradients not stacked rings, Reduced Motion setting (595); FX sizes often cut 50% (hearts 7059, impacts 9316, weapons 8741); egg reveal without boxes or ugly crack lines (5592/5593).
- **Size/proportion sensitivity:** never squash art, keep original shape and size (2981, 3005, 3433, 5691); equal body size across slimes with big decorations (3799); babies smaller than adults (804).
- **Compact, tidy UI:** grids of 5 per row (693, 3194); no duplicate Close buttons (961, 1833); action buttons at the top (1833); windows close on outside click (3581, 5754); lists keep scroll position and chosen sort (4966, 6548); only show slimes that are actually eligible (4913, 6747, 8049); Diablo-like item grid with hover tooltips (9125).
- **Simple controls:** on/off toggle instead of extra Pause button (6551).
- **Saving:** not constantly (806: every 5 min; 5050: during battle only at the end) but always at key moments (4938) and never losing progress (7479, 8305, 8787).
- **Balance taste:** gear bonuses small, "not overly power" (+1–5 stats or 20–50 HP) (8931); starter weapons +1 stat (4681); revival must always be possible with ordinary farm food; slimes never deleted (4296); no auto-sell inside auto-breeding (5969).
- **Pacing:** waves should flow automatically with a short pause (7758); paired breeders hurry (2× speed) (6985); breeding cooldown and grow-up time scale with level (5444).
- **Smoothness/performance** is a constant theme (0, 595, 2443, 7650): one update loop, no per-slime timers, pool effects, "Do not lower visual quality without proving it is necessary".
- **Collection is central:** discovery book, hidden secrets until found, highscores by stat (1765).

## 3. Vetoes & complaints (most important)

**Art / visuals**
- **Never generate, redraw, recolour, tint, crop or modify their art** (0, 318, 595, 1914, 2443). Exceptions they explicitly granted later: "make your own emotion" (1383, then reversed by uploading art 1441+), button icons (5627, then replaced by their own 5665), enemies (4619), Snowy FX/assets (7293), missing weapons "in the style of these" (8657), drop/equipment art (8931).
- 2911/2917: mutations appeared that weren't their art: "these are not what I send you".
- 3543: a strange placeholder slime flashes before a new mutation shows; remove it.
- 2981/3005: slimes squished; keep original shape. 5691: buttons squashed. 3433: pieces scaled down so they don't fit together.
- 5665: no brown/cream circle behind their button art.
- 805: no yellow ring under selected slime. 1481: no blue oval under the eyes. 9560: no yellow circle in battlefield centre.
- 1090/1222: no white box or info banner covering station art; show full art.
- 5592/5647: no rectangle box around the hatching egg. 5593: egg crack lines "look bad".
- 6344: flame like a volcano; want gentle flicker and slowly drifting embers; sparks spread over an area, not one point. 6236: effects hidden behind the anvil/furnace.
- 5873/5907/6053/6091: hammer swing unrealistic, too high, too fast, wrong direction; 5907 hammer hit the slime's head instead of the anvil.
- 7157: stat-boost FX shown on every egg; only improved eggs.
- 7059/7099: love hearts too big and opaque.
- 9406: Mythic beacon too tall, vanishes, doesn't follow the slime.
- 8398: arrow hits showing claw marks; hit FX must match the weapon.
- 3269/3419: shop pieces must not sway. 5307: grass drawn over a lower slime.
- 3774/3828: shop counter covered slimes.
- 2277: remove leftover fence and tree from the old map.
- 1805: emotion changed on every move, felt unnatural.

**UI**
- 693: removed slime-list filter tabs (Base/Dual/Secret/Favourite/Hungry/Working/Available). Note the Phase 6/Farm specs had asked for them; the owner then cut them from the slime list.
- 803: no Parent A/Parent B pickers; use the list + confirm.
- 961/1833: duplicate bottom Close buttons removed.
- 961: Farm window was too big with every slime's hunger bar; removed.
- 4966: list jumping to top after each click. 6548: sort resetting to Newest.
- 6550/6551: toggle not refreshing; Pause button removed.
- 4913/6747/8049: don't list dead / not-ready / unavailable slimes.
- 5175: farm clickable behind open battle-result window.

**Saves & data loss** (repeated and angry)
- 2383: placed map assets erased after a code change. 2488: whole game reset after map editing; drafts/import/export broken.
- 6779: upgrades lost. 7479/8305/8787: progress lost on refresh (50 slimes back to 20, upgrades kept).
- 806: constant saving unwanted. 5050: constant saving during battle unwanted.
- 5609/5755: slot count wrong (100 on reset; upgrade not applied).

**Gameplay bugs they called out**
- 4715: no weapons available. 4785: no battle background, slimes too large, no visible weapons, no move animation. 4967/5048: (ranged) slimes vanish in battle. 5146/8078: healing/buffs not visible or not working. 7758: waves stop after clearing. 8077: slimes block each other. 8551/9405: shield slimes indecisive / hang back. 8550/9489: orphaned equipped items, stray escrow shield.
- 4843: dead slimes looked normal on the farm. 4883: hatch froze the game.
- 6452/6453: cooldown and grow-up time missing. 6549/6717: Specialized Breeding didn't work. 6985: egg created before both parents reached the house.
- 3120: slimes clustered in the centre (old boundary).
- 6394: test price still 99999c.

**Process**
- 6148: "you ruined the whole game, revert it back" (after sparks/flames change) → restore last good step and redo only the agreed steps.
- 2427: "Stop coding now. Do not attempt any more fixes" → handoff + fresh session.
- 6053: for trivial asks "just do it as I said, dont need to check back anything".
- 2712: the 300-line rule is not strict.

## 4. Working rules the owner set for the builder

- Work in small phases; stop and wait for approval after each (0, every phase brief).
- After each meaningful edit: type-check + tests, launch game, check console, fix all errors, confirm old features, commit/backup. "Never continue building on broken code." Do not weaken/delete failing tests (3839).
- Keep gameplay logic separate from rendering/UI; balance values in config; data-driven tables; no hardcoded totals (11/19/55); injected seeded RNG, never `Math.random()` in logic.
- Files short (< 300 lines aimed, not strict — 2712).
- Art: never generate/redraw/modify; labelled placeholders + stable asset IDs; ask for art in small groups; missing art never crashes; load each texture once.
- Saves: versioned, validated, migrations, last-good backup, debounced, export/import, confirmed reset; never wipe the whole save for one bad field; never reroll an egg; idempotent hatch/sell/reward.
- Performance: one update loop, no per-entity intervals, no per-frame UI rebuilds, no per-frame pathfinding, capped offline steps (≤ 480).
- Dev tools (genetics panel, mutation forcer, map editor, overlays) never visible to players.
- Published map is shared by all players and must not depend on a local save; never overwrite the only valid map without backup (2108); do not move anything on the published map (2443).
- Recovery-session rules (2442): read code + handoff first, diagnose with evidence, one task at a time, one hypothesis per attempt, **stop after two failed attempts and explain**, don't repeat failed fixes, keep an attempt log, don't touch gameplay/balance/assets/map/saves unless needed, never delete code/assets unless proven unused, revert to checkpoint on regression, concise replies.
- Audit brief (2443/7570): audit before refactor, measure before/after, preserve all manual tweaks, keep old migrations.
- Slime Siege: feature flag until finished; one phase at a time with testing gate (3839).
- When matching uploaded art to names: ask if a picture and a name don't match (3035).

## 5. Specs the owner wrote that the code may not show

**Core numbers (Phases 1–6)**
- Start: 4 slimes, ATK 1 / DEF 1 / SPD 1 / HP 10; `Level = ATK + DEF + SPD + HP/10`, display floor, never stored.
- Breeding cooldown 60 s; hatch 60 s; max 4 active eggs; eggs reserve a slime slot; slimes are sexless, can't self-breed.
- Stat inheritance: each stat rolled between parents (inclusive); one 10% chance per egg to improve one random stat from the stronger parent: ATK/DEF/SPD +1–3, HP +10–30 (0, 221; reconfirmed 5847; 5444's "HP 5–10" superseded).
- Cooldown and grow-up time grow with level, ~+1 s per level (5444); upgrades reduce them by 5%/level (5500).
- Hunger: max 100, start 100, −1/min, auto-eat at ≤ 35, +50 per food, 1 food per meal; start food 20, storage 100; starving pauses work, never kills.
- Speed: bonus 0.05 per point above 1, max +300%; job min 5 s; `duration = base/(1+b)`, `yield = floor(base*(1+b))`, ≥ 1.
- Offline cap 8 h, 60 s steps (≤ 480); backward clock = 0.
- Selling: base 10 / dual 100 / secret 1000 coins × (1 + level × 0.05); keep ≥ 2 slimes; favourites unsellable; confirm Dual/Secret sale; workers can't be sold.
- Saves: every 5 min (806) + key events (4938).
- Stations: Berry Bush, Farm Plot, Fishing Pond, + Cooking (1090); 3 workers each with fixed seats (1090).

**Genetics & mutation (2692, 2712)**
- Dominance: Black 11, Gray 10, Navy 9, Purple 8, Red 7, Orange 6, Yellow 5, Green 4, Pink 3, Blue 2, White 1 (tie priority same).
- One categorical roll per egg, order Secret → Base mutation → Dual → Normal. Final rates (2712): **Secret 0.1%** (only if recipe exists), **Base-colour mutation 10%** (random different colour, both alleles set to it, inheritable), **Dual 1%** (only if parents' visible colours differ). Unused Secret chance returns to normal.
- Pattern gene: `solid` dominant / `duochrome` recessive; Dual mutation gives duochrome/duochrome; carriers look Base; Dual expression needs duochrome/duochrome and two different source colours.
- Secrets keep the base genotype underneath, aren't inherited, breed as base phenotype; themed (animal, flower, food, mineral, mythic, weather, cosmic), but "the basic slime body must remain recognizable".
- Test-only chances used along the way: 90/50/30 (2578), 70/50/30 (2854); reset to normal at 5191.
- Duals: 19 planned at start; owner then uploaded 20 dual artworks and let the builder name them (2578–2584). Patterns: spots, stripes, hearts, waves, patches.
- **Secret recipes (2707), 55 for 10 colours:** White×White Snow Rabbit; W×Pink Sakura Bunny; W×Yellow Daisy Chick; W×Green Lily Spirit; W×Orange Creamsicle Fox; W×Red Peppermint Slime; W×Purple Moon Orchid; W×Navy Arctic Wolf; W×Gray Cloud Sheep; W×Black Yin-Yang Koi; Pink×Pink Rose Fairy; P×Yellow Peach Blossom; P×Green Watermelon Frog; P×Orange Coral Axolotl; P×Red Lovebird Slime; P×Purple Dream Butterfly; P×Navy Twilight Moth; P×Gray Rose Hedgehog; P×Black Gothic Bat; Yellow×Yellow Sun Lion; Y×Green Lemon Gecko; Y×Orange Sun Phoenix; Y×Red Fire Salamander; Y×Purple Royal Griffin; Y×Navy Star Owl; Y×Gray Thunder Ram; Y×Black Honeybee Slime; Green×Green Forest Dryad; G×Orange Autumn Fox; G×Red Holly Deer; G×Purple Poison Frog; G×Navy Lagoon Turtle; G×Gray Moss Golem; G×Black Swamp Basilisk; Orange×Orange Ember Tiger; O×Red Fire Dragon; O×Purple Witch Cat; O×Navy Sunset Koi; O×Gray Copper Beetle; O×Black Jack-o'-Slime; Red×Red Rose Dragon; R×Purple Dragonfruit Slime; R×Navy Fire-Ice Chimera; R×Gray Iron Boar; R×Black Blood Moon Bat; Purple×Purple Amethyst Unicorn; Pu×Navy Galaxy Whale; Pu×Gray Moonstone Gargoyle; Pu×Black Void Kraken; Navy×Navy Deep-Sea Leviathan; N×Gray Storm Shark; N×Black Midnight Raven; Gray×Gray Stone Tortoise; Gr×Black Shadow Wolf; Black×Black Universe Slime. (Each has a one-line design description in 2707.)
- **Sky Blue recipes (3656–3669), 11 more → 66 total:** SkyBlue×SkyBlue Cloud Pegasus; ×White Frost Swan; ×Yellow Thunderbird; ×Green Sky Island Turtle; ×Orange Sunshower Fox; ×Red Steam Dragon; ×Pink Cotton Candy Sheep; ×Purple Aurora Jellyfish; ×Navy Celestial Manta; ×Gray Raincloud Ram; ×Black Tempest Dragon. (Owner calls Blue "Sky Blue" here.)

**Map (2538–2541, 3461, later edits)**
- Main Farm map v2: bounds 1672 × 936, background `scene.farm.main`, spawn points (700,520) (960,430) (1180,600) (810,690); ~70 placed objects (pond-fishing-01 at ≈(222,472); tree-large-01 at ≈(302,159); bushes/rocks/flowers/reeds mostly along edges). Layer/collision rules: ground decals walkable; pond = blocked polygon; trees/bushes/rocks Y-sorted solid footprint.
- Shop: first ≈(1311,526) ×1.5 → rebuilt from bridge/counter/awning (≈1283–1299, 464–502, scale 0.3) → replaced by single Y-sorted shop front (5219), moved up 60px (5297). Shopkeeper NPC at (1140,486).
- Blacksmith at (731,261) Y-sorted; blacksmith slime at (801,304); hammer finally ≈(762,240) then up ~30px; furnace flame at (801,196); sparks at the anvil top.
- Specialized-breeding house (nest-open-01 / nest-closed-01) at (271,620), solid.

**Upgrades (5500, 5931, 5969, 8079)**
- Food storage (+100 per level, 8079); incubation −5 s/level; breeding cooldown −5%/level; grow-up −5%/level; slime slots +5/level; **new players start with 20 slots** (5500, 5609); Auto-hatch; Specialized Breeding (test price 9c).

**Specialized Breeding nest (5969, 6265, 6839–6985)**
- Specialties: Level ★, ATK ⚔, DEF 🛡, HP ♥, SPD (wing/lightning). Ranks members by permanent stats only (no gear), tie-break Level then slime ID; picks top 2 eligible; newborns join the lineage and only replace parents once grown and better; pauses with "Farm Full — Auto Breeding Paused"; never sells/deletes; specialty change affects next cycle only; release-from-lineage option; capped offline cycles. Locked door + "Unlock to open" until bought. Pair shows love emotion + hearts, walks at 2× speed, egg starts only when both are at the house; door open/closed art.

**Egg reveal (5366, 5409, 7098)**
- Centre-screen state machine (PRELOAD … COMPLETE), escalating by rarity (Normal gentle glow/pop; Dual colour burst; Secret stronger light + pause). Rainbow egg art for incubation and reveal. Stat-boost foreshadow: hearts (HP), stars (ATK), shield (DEF), lightning (SPD), only when a stat improved.

**Slime Siege (3839–4570 and later)**
- Squad 1–10 slimes; slots Head / Hand / Tail; Hand item gives the temporary role/AI; no permanent class on the slime.
- Hand families: Sword (close-range, area slash), Bow (kites, prefers ranged/healer targets, Piercing Shot; not "furthest enemy"), Healing Staff (self first when critical, lowest HP%, one cleanse/shield, weak attack when idle), Shield (outer ring, Taunt with expiry, Shield Bash, leash; owner later: must lock on and close in), Arcane Focus (cluster-scoring area spell e.g. Frost Burst with slow), Alchemy Kit (non-stacking buffs, debuff bosses/elites, damaging flask).
- Formation rings: Shield outer; Sword outer/middle; Bow & Arcane middle; Healer & Alchemy inner.
- Combat: targeting 4–6×/s with stickiness; DEF diminishing returns with cap; min damage; SPD capped cooldown; deterministic seed; jumps visual only. Later: allies pass through each other (8077).
- Enemy roles: Swarmer, Brute, Raider (dives backline), Spitter (ranged), Shaman (heals/buffs), Armoured Mob. Edge spawns, per-wave budget, active-enemy cap.
- Waves 1–4 normal, 5 mini-boss, 6–9 stronger, 10 main boss; boss pattern repeats every 5/10; Continue or Safe Retreat after 5 and 10; auto-continue after a short pause otherwise (7758).
- Fallen: never deleted; gear goes PENDING_RETURN → inventory at run end; Revival Meal from farm food, `reviveCost = BASE × ceil(1 + level/INTERVAL)`; Re-equip Previous Loadout; farm shows fallen slimes half-transparent (4843).
- Loot: coins, wood, cloth, ore, monster materials, rare parts/cores (later also food, 8931); wave ledger committed on wave clear; unfinished wave's loot lost on defeat.
- Crafting tiers Wooden → Bronze → Iron → Enchanted → Mythic (rarity colours incl. Epic/Mythic glow, 9406); no durability; bonuses small (+1–5 stats, +20–50 HP).
- Main-boss reward ideas: Secret Mutation Catalyst (only for valid recipes, consumed at egg creation), permanent stat treats (capped), exclusive blueprints, mutation fragments, cosmetics/auras, Group Revival Feast.
- HUD: wave/enemy count, HP bars + role icons, boss HP/phase/enrage, buff icons, pause / 1× / 2×; telegraphs under characters; reduced particles/shake/flash settings; separate audio sliders.
- Starter gear (4681): 10 items, 2 per type; Sword/Bow/Arcane +1 ATK, Healing Staff +10 HP, Shield +1 DEF, Alchemy Kit +1 SPD. Later Iron Sword, Longbow, Shield removed for lack of art (8846).
- Equipment visible on slime at anchors (hat, hand/weapon, tail, face) (4720); sizes changed 3× (7239) then 50% smaller (8741).
- Battle saves only at the end (5050); last team remembered (4968).
- Snowy map roster (7293): Big Ice Monkey boss, spider ranged, others melee; reusable hit-FX library (slashes, claws, bites).

## 6. Uploaded art (mentions)

- Station art: Fishing Dock, Berry Collection, Farming (961); Cooking station (implied by 1090); new Farm Plot (1534).
- Emotion art sets (1270, 1365), single transparent emotion (1441), replacements (1615, 1852/1853, 1880), Sad replacement (2109).
- Map sprite sheet of ponds/trees/bushes/rocks/flowers/grass/patches (1914); new farm background (2213); replacement rock-large-06 (a flower) and tree-large-01 (2368, 2369).
- 20 Dual-colour mutation artworks in 4 batches (2578, 2582, 2583, 2584), names left to builder.
- Base-colour slime art (2947, 2970; check at 3001).
- Secret slime art for all 55 recipes in batches (3035, 3052, 3065–3069, 3107, 3119, 3289, 3306, 3477, 3478, 3496); Sky Blue secret list at 3656–3669 (art likely attached).
- Shop (3195), three new map pieces (3331, 3353, 3354), shop counter/awning/bridge (3461), single shop front (5219).
- Loading-screen background (3529).
- Shopkeeper slime (3581).
- Battle maps (4619) incl. a Snowy battleground; equipment anchor guide image (4720).
- Rainbow egg asset set (5409).
- HUD button art: Upgrades, Siege map, Slime list, Highscore, Breeding, Working station, Slime gallery, Settings (5665).
- Blacksmith building (5730, replaced 5906), blacksmith slime (5756), hammer (5816 onward), anvil/furnace part of the blacksmith art.
- Specialized-breeding house, door open + door closed (5969, ids nest-open-01 / nest-closed-01 at 6265).
- Snowy-map mobs incl. Big Ice Monkey and a spider (7293).
- New weapon art replacing builder-made weapons (8656, 8657).

**Art the owner asked the builder to generate:** own emotions (1383, later replaced), button icons (3507, 5627; then replaced by owner art 5665), enemies (4619), stat-boost icon set (7098), Snowy-map FX + "as many assets as you can" (7293), missing weapons in the style of theirs (8657), drop and equipment art for crafting (8931).
