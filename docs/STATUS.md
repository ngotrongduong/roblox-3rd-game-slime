# Status

## 2026-11-15 — VfxLib d5bfc24: Bulwark's spirit knight is the owner's 3D knight as a hologram

The game's VfxLib copy taken up to the library's main (`import.ps1 --update`, same 130 effects): the runtime learnt
one-shot 3D `bodies`, and `skill.spirit_guardian` (Bulwark's knight) is now the owner's own 3D knight drawn as a
see-through ghost. The weapon impacts by tier and the class skill pieces were already in the game since 60b30ec.
**Proved:** CHECK OK (797 passed), TYPES OK (`src/shared/VfxLib`); MapWork play: the knight played on meadow grass
and on snow with no VfxLib error in either log. **Seen:** on grass it reads as a pale gold ghost with its shield;
on snow, pale gold on white, it is hard to pick out, and from a far camera it melts into the glow. Not tried in a
real fight or on a phone.

## 2026-11-14 — the Heart redesigned (the central area)

**What it is** (the owner: "the central area is designed too poorly, redesign it"; then two notes while it was built:
no giant crystal on the shrine's roof, and the spouts' water must come from inside the statues' mouths).
- The whole Heart is built by `tools/world/build_heart.luau` (re-runnable; `build_sites.luau` now keeps `Sites.Heart`):
  the Crown Shrine at the north of the island with two big guardians, a paved arena (stud slabs, a gold rim, the
  crowned-slime crest as one picture, `rbxassetid://139392512230048`) ringed by 10 rune stones, flower beds and trees,
  kerbs with 24 crystal lanterns and 6 guardians along the three causeways, crystal islets and lily pads in the lake,
  4 slime-head spouts whose water wells up in the throat and falls from the lip, 6 ruined colonnades and two rows of
  trees on the far shore, Crownfall with moving streaks.
- Six new models (ChatGPT asset sheet -> Meshy Smart Topology, 90 credits, 673 -> 583): `art/models/world/heart/*.glb`,
  ledger in `docs/turnaround.md`, loader `tools/world/take_heart.luau`. The crest: `art/world/heart_medallion.png`
  (`tools/chatgpt/prepare_floor.py`). No game code changed.
- References, cameras, the four rounds' scores and the count: `docs/references/heart/rounds.md` (shots beside it).
- Lessons: `.claude/skills/studio-build/LESSONS.md` ("The Heart, redesigned"), `.claude/skills/playtest/SKILL.md`
  ("Driving a test without the mouse"), and the owner-level skills `chatgpt-art` and `meshy-multiview`. New tool:
  `tools/world/glb_section.py` (a model's side profile in text).

**Proved:** the builder's last run: "heart: 512 kit pieces, 961 parts, 25 lights, 31 beams; floor 132.0 lake 128.0;
missing:" (nothing missing); MapWork saved with it. In a MapWork play test (the repo's code synced in) the world came
up with no new error ("zones of the big world ready: 14 fights, 3 gates sealed, the rim walled in 60 pieces, 22
waystones"), the Heart's fight anchor stood at 136 (terrain 132 + lift) over a floor top of 132.1, and the causeway, the
arena and a spout's running water were seen at the game's camera (`docs/references/heart/shots/play_*.jpg`).
`build_sites.luau` re-run after it learnt to keep the Heart: "sites: 433 kit pieces, 4274 instances; missing:" and the
Heart still held its 31 beams and 4 spouts.
The Heart's own fight was run on the new floor (MapWork play test, the zone's lock lifted in the work place only and
put back by a sync, the debug menu's "late" farm): waves 1 to 3 of 4 were seen, the squad's slimes stood with their
bodies' bottoms at 132.0 and a monster (Calderos) at 131.9 over a floor top of 132.1
(`docs/references/heart/shots/play_fight_*.jpg`).

**Not verified:** the fight's last wave and its win were not waited for; skill marks drawn flat on the ground were not
looked at one by one over the floor; nothing was seen in a phone view; FPS on a phone not measured (about 91,000 new
triangles across the crater). StudioTest.rbxl has not been rebuilt from the new MapWork
(`lune run tools/build_publish.luau studio`, with StudioTest closed).

**Needs the owner:** nothing. The models live in MapWork (saved) and as GLB files in the repo.

## 2026-11-14 — exploration teams, one job a team, richer slime lists

**What it is** (the owner's request of 2026-11-14).
- A team can be set to **explore** one of the map's 8 level bands (`WorldPacks.bandName`, "Lv 1-20" ...): it then roams
  from pack to pack of that band by itself and comes home only when it is called back or every member has fallen. Saved as
  `farm.teams[n].explore` (optional, schema unchanged); request `SetTeamExplore { team, band }` (band 0 = call back, from
  anywhere; starting needs the player at the home team banner, the team home and not empty). Server: `ZombieFights`
  (`roamOn`, `recall`, the `Explore` attribute on `Teams/<n>`), rules in `shared/VillageRequests`.
- An exploring team's fights cost no energy or fullness and its wounds heal on the walk between packs. It walks at the
  slimes' own pace: `Config.Zombies.ExplorePace` (3 times as fast) was taken out on 2026-11-15, the owner wants slimes at
  their original speed everywhere (only players walk twice as fast). Its coins and losses are
  added up over the whole outing for the "home" notice.
- One job a team: the Dungeon refuses a team set to explore ("TEAM_OUT"); the Arena refuses an attack while one of its
  fighters is in an exploring team ("EXPLORING"; the Arena keeps its own line-up, so the rule is by slime).
- A line-up is changed only at the home team banner and only while the team is home ("TOO_FAR", "TEAM_OUT"); a buff dish
  can be fed to a slime that is out (`FeedDish`).
- Screens (`client/UiTeams`, `UiSlimeList`, `UiKit.dropdown`, numbers in `Config.Ui.Team`):
  - the home team sheet (the banner) has **Explore** in the place of Repeat: a dropdown of the 8 bands; while the team
    explores the button is "Call back", the line under the slots reads "Exploring Lv 1-20" and the slime list is hidden.
    Repeat stays on the pack's attack sheet, where an exploring team's card reads "Exploring <band>" and cannot be sent;
  - a team chip of the HUD opens the **members sheet**: only that team's own slimes (portrait, name, level, four stats,
    health, gear, a dish button), its job (Home / Marching / Fighting / Exploring <band> / Coming home) and "Call back";
    no other slimes and no way to change the line-up. The dish button opens `UiFood.open(own, slimeId)`: only the dishes,
    and the dish sheet has that slime chosen (Feed / When hungry);
  - every slime list (all go through `UiSlimeList`) shows on each tile the four fight stats and the worn gear, and its
    sort buttons are one "Sort: <name>" button at the right with a dropdown (picking the current one flips the order).
- Pictures still missing (stand-ins in use): an exploring / compass icon (the `map` icon stands in on the chip and the
  sheet; the Explore button is text only).
- The owner's number of the same day: players walk at `Config.World.WalkSpeed` 32.
- The minimap covering other HUD parts on a flattened window: the owner said no fix is needed (full screen is fine).

**Proved in a StudioTest play** (mid preset, band 1): the team went pack to pack without coming home (legs 19-32 s, 57-95 s
before `ExplorePace`, which is the pace again since 2026-11-15); called back while walking it was home in 6 s (with `ExplorePace`), called back in a fight it finished the fight and came
home; a team sent at band 8 died and its exploring ended; the Dungeon answered "TEAM_OUT", the Arena "EXPLORING", and
starting away from the banner "TOO_FAR". Seen on screen in the same play (a 1920 x 928 window): the home sheet with the new
tiles, the band dropdown, "Exploring Lv 1-20" with Call back, the members sheet with all four members and their dish
buttons, the Sort dropdown. `check.ps1`: 797 passed, CHECK OK; `types.ps1`: TYPES OK.

**Not verified:** the heal on the walk and the summed "home" notice were not looked at in play (the test vault was full, so
every kill paid 0); the dish list for one slime was seen only empty ("No dishes yet": the test save has no cooked dish);
the Book's, the Arena's and the Dungeon's slime lists were not opened; nothing was seen in Studio's phone device view.

## 2026-11-14 — M5b: packs Lv 4-150, the Heart's rim closed, waystones, the map (done)

**What it is** (the owner's request of 2026-11-14; every decision in `docs/WORLD.md` §7 "M5b").
- The Heart can only be entered through its three gates: an unseen wall runs along the crater's crest (`Config.World.RimWall`).
- Monsters stand all over the world in packs of 3-5 Dungeon monsters of their region, each pack at a fixed level by its
  distance from the nearest village: Lv 4 beside a village to Lv 150 at the farthest, read in 8 bands of 20 levels
  (`Config.World.Packs`, `shared/WorldPacks`, server `ZombieFights`). The camps at the gates are gone.
- 22 waystones (`server/Waystone`, `ZoneGuards`): one beside every zone's pad, one inside every village's gate. A zone's
  waystone opens for a player who has beaten that zone's guard; travel is `Remotes.Travel { action = "Zone" }`.
- The map (`client/UiMap`, `shared/MapView`): a small map at the top left of the HUD and the whole world on a sheet with
  the bands' legend, packs, zones, waystones and a Travel button. Eight icons by ChatGPT (`Config.Ui.Icons.map` ...).
- No save shape change (wins were already saved by M5, schema 15).

**Proved.** `tools\check.ps1`: CHECK OK, 795 passed. `tools\types.ps1`: TYPES OK. StudioTest play test (in-memory
store): 108 packs in bands 1-8 (42 / 15 / 13 / 8 / 8 / 10 / 6 / 6), Lv 4-150; a Lv 5 pack fought, gone, back after
30 s; the rim held a walking, jumping character at 8 points; "waystones: 22 stand in the world"; a zone's and a home's
waystone seen standing right with the rune lit; the sheet opened from the small map and from a waystone's prompt;
a locked zone read "Beat its guard to open"; Travel took the player Home, and to m1's waystone after m1 was won; no
error or warning of the map, packs or waystones in the log. Shots: `docs/references/world/shots/m5b_*.jpg`.
A pack pays: with room in the vault a Lv 4 pack of five paid 120 a swarmer and 180 a spitter, "earned 660".
A play test that logs "paid 0" has a full vault, not a fault: every Debug preset holds more coins than the vault
(early 2000 of 2000, mid 50000 of 7200, late 1000000 of 246000) and fight income stops at the vault. Spend the
coins first (area upgrades cost them) until the wallet is under the vault to see coins paid.

**Not verified.** A phone frame (the small map against the team chips at 360 x 640; the sheet's legend under the map
on a narrow screen). The
last numbers (`OutStuds` 54, set after measuring every zone's spot in the place) were not seen again in play. Two
players at once. MapWork has not been given this code (StudioTest has).

**Owner's numbers** (`Config.World`): `Packs.StatFactor` 0.85 (how strong a pack is against slimes of its level),
`Packs.Curve` 1.6, `Packs.GridStuds` 280 (how many packs), `Packs.CoinBase`, `Packs.MarchMostStuds` 60,
`Waystones.Look.Scale` 0.7; `Config.Ui.Map.MiniStuds` 700 (how much the small map shows).

**Zone guards match their packs (the owner said yes, 2026-11-14).** A zone is now made for a team of the level of the
packs round it and shows that level everywhere (`ZoneFights.level`; sign, HUD, monster tags): m1 6, m2 5, m3 24, m4 63,
b1 55, m5 26, m6 89, b2 63, m7 103, m8 114, m9 148, m10 127, b3 117, heart 150 (`Config.World.Zones` `level`, fitted
by `tools/balance/zone_sim.luau 40 fit`). Proved: CHECK OK (795 passed), TYPES OK; the sim at 80 seeds gives the target
team 61-86 % wins; StudioTest play: the 14 anchors carry those levels, m1 fought and won with the HUD and both tags
reading "Lv 6", no script error. Not verified: a far zone fought in play (only the sim), the zone's prompt card read by
eye.

**Guards' coins match their levels (the owner said yes, 2026-11-14).** `Config.World.Reward` coins are now mini
1000-1600, boss 3000-4500, mega 8000-12000 at level 0, raised by the zone's level as a pack monster's are (x 1 +
level x 0.05; `CoinsPerTier` is gone): m1 1300-2080, m9 8400-13440, b3 20550-30825, the Heart 68000-102000. Fight
income still stops at the vault. Proved: CHECK OK (795 passed), TYPES OK; StudioTest play: m1 won, the log "paid coins
1925", the Victory card shows 1925, the wallet rose by it. Not verified: a boss or the Heart's payout in play.

**Open.** Packs pay coins only. The waystone
is the same lit stone for everyone (the map says which are open). King Goo's own model. Studio said once "No asset
content representation" for `rbxassetid://135413526793030` (the Dungeon's green dandelion texture, not M5b's).

## 2026-11-14 — the team sheet: rows and three tactics (WEAPONS step 6; built and seen in play)

**What it is.** On the Teams sheet every slime of a team has a row pill (Front / Mid / Back, tap to cycle) and the team
one tactic button (Balanced / Focus Fire / Protect, pictures from ChatGPT in the owner's style, `Config.Ui.Icons.tactic*`).
Saved on the team (`formation`, `tactic`; optional fields, schema stays 15). The server places the squad by rows at the
start of a camp / pack fight and a Dungeon run and gives the tactic to `Combat.new`; the rules are in
`docs/WEAPONS.md` §13 "Step 6", the contract in `docs/briefs/team-sheet.md` (rules, server and tests by ChatGPT, branch
`chatgpt/team-sheet`; the screen by Claude). The Arena is untouched.

**Proved.** `tools\check.ps1`: CHECK OK, 791 tests passed, on top of M5b's packs (new: farmstate repair, zombies rows, requests
`SetTeamRow` / `SetTeamTactic`, dungeon `squadSpots`, classes: Balanced parity, Focus leadership, Protect targeting,
row hops). `tools\types.ps1`: TYPES OK for `src/shared`, `src/server`, `UiTeams`, `ZombieTeams`, `DungeonFight`.
`class_sim.luau 20 tactics`: no tactic dominates (table in WEAPONS §13).

**Seen in play** (MapWork at f462001, the emulated phone frame 750 x 381, `Debug late`): the sheet shows the row pill
under each slot and the tactic button with its picture, all inside the frame; a tap on a pill went Mid -> Back, a tap
on the button Balanced -> Focus Fire. `SetTeamRow` / `SetTeamTactic` change `Rows` / `Tactic` on `Teams/<n>` and
refuse a wrong row, tactic or slime. A Dungeon run (level 6) started in three rows: front +5 studs, middle 0, back -5
along the squad's facing. A pack fight (p4x7, team 2 = back, back, front, front) started with the fronts about 11
studs from the centre and the backs about 21, and was won. No error or warning from the sheet or the fights in the
client or server log.

**Not verified.** A tactic visibly changing whom the squad hits in a live fight (level-80 slimes end a fight in
seconds; the rules are proved by tests and `class_sim` only). A real phone. The slots do not show the weapon's
picture (§6 mentions it; not built).

**Also today.** VfxLib 60b30ec: Bulwark's spirit knight redrawn solid for bright ground: seen in play on the meadow
grass at the game camera, gold and navy, clear against the bright ground (Studio warned once "No asset content
representation" for its picture `summon_guardian_bright`, and for `rime_flip`, `acid_fizz_flip` and the dark totem's;
the knight drew all the same).
Ember Lava seen in a run with both Legendary debug teams: Meteor is strong and Catalyst Cloud reads on the dark ground;
Bulwark, Whirlwind, Arrow Rain, Momentum and Last Stand played there but were not framed.

## 2026-11-14 — M5, fights in the big world (done, except King Goo's own model)

**What it is.** Every zone of `WorldPlan.Zones` is a short Dungeon run fought in the open on the zone's pad
(`Config.World` = `shared/ConfigWorld`, rules `shared/ZoneFights`, server `ZoneGuards` + `server/Dungeon`, client
`UiDungeon.watchZones`, `DungeonFight`). The last wave is the zone's guard, which pays the zone's reward; a won zone
rests (mini 300 s, boss 900 s, mega 1800 s); the three boss zones open the gates of the Heart; the Heart needs all
three and is held by the four region bosses until King Goo has a model (M6). Wins are saved as
`farm.world.beaten` (**schema 15**: a publish must shut down all old servers). Zombie camps stay at the village gates.

**Proved.** `lune run tests/run.luau zone_fights`: 8 passed. `tools/balance/zone_sim.luau 60`: every zone 72-85 % for
its target team. Play test in StudioTest (in-memory store): 14 prompts and 3 seals made, far / locked / unknown /
resting entries refused, zones m1 and b1 fought on their pads and won, end card shows Leave only after a win and
Replay + Leave after a defeat (b3 lost), `Zone_m1` set, prompt reads "Resting 4:30", locks hang on the sealed gates,
gate_w's wall and lock went when b1 was won. Detail and every decision: `docs/WORLD.md` §7.

**Not verified.** The zone sheet opened from the prompt by hand (entry was sent by script); a phone view; what other
players see of a zone fight (it is drawn only for its owner); the Heart's own fight (only its lock was tried); MapWork
has not been given this code (StudioTest has). `tools\check.ps1` ends CHECK FAILED on one test that is not M5's:
`debug_presets:194` (the Late preset in `DebugPresets.luau` stands changed to `dungeonBest = 27`, uncommitted, by the
effects session); every other test passes (774). `types.ps1`: 1 finding, also theirs
(`VfxLib/Effects/skill/arrow_ring.luau:60`).

**Next.** King Goo's own model (`docs/WORLD.md` §5 row 10) and M6; the owner plays the zones and names the numbers
(`Config.World.Zones`, one `level` a zone). Publishing is the owner's, and this version changes the save shape.

## 2026-11-14 — the big world: the main map rebuilt ten times larger, and the game now runs in it (M4)

**M4, the switch (done).** `Layout` takes the Market's frame and the eight plot frames from `WorldPlan` (plot n =
village n, gate towards the hub; the Market at the hub, front to the north); nothing else in the game changed, saves
keep their shape. In MapWork (saved): the hand-built village `Map.Plot5` and `Map.Market` stand in the world, the
ground and pond basin lie under all eight plots, the old valley's scenery is parked in `ServerStorage.OldValley` and
its terrain is cleared (`tools/world/switch_over.luau`, `build_sites.luau`, `tools/map/prepare_plots.luau`; the file
before the move is `C:\tmp\MapWork.before-M4.rbxlx`). `tools/build_publish.luau` keeps `workspace.World`, drops
`OldValley`, streams with target 700 / minimum 64. Zombie groups stand out from each village's gate
(`Layout.campFrame`), an interim until M5. Detail and decisions: `docs/WORLD.md` §7.
**Proved:** `tools\check.ps1`: 745 passed, `CHECK OK`; play test in MapWork: plot 1 built in 0.28 s on its pad, Home and
Market travel through the real remote, portal and leaderboard in the Market, 81 zombie groups on land (server probe:
none on water or a slope), shots `docs/references/world/shots/play_village.jpg`, `play_market.jpg`; play test of the
streaming build (`StudioTest.rbxl`): same start, the client holds 3,454 of 18,603 scenery instances, travel without a
pause.
**Not verified:** a phone frame and FPS, a second player in another village, a zombie fight and a dungeon run in the
new world (the code paths did not change, they were not played), far views under streaming (the mountains do not
show from a village: `docs/WORLD.md` §6). `tools\types.ps1` ends with 1 finding, in the effects session's
`VfxLib/Effects/skill/arrow_ring.luau:60` (not this work's file; `WorldPlan.Roads` got its type here).
**Next.** M5: the fights move into the zones (design with `game-designer` first), then own models (M6), the phone
pass (M7).

### How the world was built (before M4)

The owner: keep the player village, rebuild the rest from the ground up, about 10x larger, natural (no chessboard),
made to explore: 8 villages, 1 shopping hub, 10 mini-boss zones, 3 boss zones, 1 mega-boss zone; kit assets first.
Everything about it is in **`docs/WORLD.md`** (audit, layout, zones, missing assets with ChatGPT and Meshy prompts,
plan, validation).

**Done.** `src/shared/WorldPlan.luau` (places, roads, river, the Heart; `tests/spec/world_plan.luau`, 9 tests) and
three re-runnable builders in `tools/world/` (terrain heightfield, scatter, sites). Built and saved in
`assets/raw/MapWork.rbxlx` as `workspace.World` + terrain, 6,000 studs north of the old valley, which is untouched:
Home Vale (Market at the hub, 8 village pads with gates, lane, 4 bridges, quay and lighthouse), Wayfarers' Cross
under a great oak, Mushroom Grove, Ember Terraces with the volcano, Frost Reach with peaks, and the Heart (rock mesa,
crater lake, island, three causeways and gates, the Crown, Crownfall feeding the river to the sea); 13 arena rings.

**Seen** (edit-mode shots, `docs/references/world/shots/`): the Cross view matches reference 2, the Heart from above
matches reference 1, hub, a bridge, Gloomroot Throne, Molten Throne, Glacier Throne, the quay. Counts: scenery 10,994
MeshParts from 88 meshes, sites 2,141 parts.
**Not verified:** a phone frame, triangles in view, FPS.

**Gates through Meshy (done: the three gates stand in the world).** Meshy's
Image to 3D has a **Smart Topology** tab (Meshy T2.5: ONE picture, a poly count typed in, Texture on with Meshy N1
2K = 15 credits, about 40 s, no Remesh needed; no multi-view there). Sources cut from `world_ref_3`:
`art/turnaround/<root|ember|frost>_gate/source.png`. Generated and textured in the owner's Meshy workspace (top of
the list), credits 718 -> 673; the textured GLB of each is in `art/models/world/gates/` (one mesh, one 2K texture,
about 1 unit wide, the passage along Z): **Root Gate** 3,930 triangles, **Ember Gate** 3,110, **Frost Gate** 3,167.
Uploaded as Models on the owner's account (Root 110858843893866, Ember 131059782610116, Frost 83305165757925)
through `open_cloud_invoke` on the Studio that has a place saved to Roblox ("Showroom skills"): a Studio on a local
file (MapWork) gets no asset token ("Scope 'asset:read' has not been granted") even after the owner grants it.
`tools/world/take_gates.luau` loads them into `ServerStorage.WorldKit`; section 4 of `tools/world/build_sites.luau`
stands them in place of the RuinArch, 42 studs tall, lantern side down the causeway. The mesh does not collide (its
automatic hulls left a passage one character wide, measured by Blockcast); two unseen `GateLeg` blocks stand in the
legs and leave the middle 14 studs free (Blockcast: a character box passes at the middle, is stopped from 5 studs
off-centre). Seen in edit-mode shots from the causeway side: `docs/references/world/shots/root_gate.jpg`,
`ember_gate.jpg`, `frost_gate.jpg`. A shot from INSIDE the Heart then showed the Root and Frost Gates stood back to
front (lanterns, mushrooms and flowers looking into the Heart; only the Ember Gate was right): their files face the
other way, so `build_sites.luau` turns those two; the three shots above are the corrected ones, all with the lantern
side to the causeway. **MapWork is saved with the gates** (2026-11-14 12:12, `ServerStorage.WorldKit` and the rebuilt
Sites); to rebuild from nothing: `tools/world/take_gates.luau`, then `tools/world/build_sites.luau` (PLAN=WorldPlan).
**Not verified:** a walk through each gate in a play test (the game still sends a character placed in the new world
back, until M4), the game's own camera, a phone.

## 2026-11-14 — fight effects audit; wave 1: the slimes' side raised to the monsters' level

The owner: audit weapons, monsters, monster skills, slime skills and battle effects, and raise the visuals as far as
possible with the VFX library's showroom (whole, in part or combined), Genshin Impact as the bar.

**Audit.** The monsters (28, their specials, the bosses' Burst and the regulars' Pop) already play the library end to
end. The slimes lagged: a crit was only a bigger 2D mark, their skills had no wind-up glow, no release flash and no
hit-stop, Taunt, Acid Rain, Goo Slam and Belly Bounce were 2D stand-ins, a fall was stars only, a win had no effect.
Weapons: trail, cast and aura by tier are in; the plain blow's impact is the same flat mark at every tier. Only the six
Common class skills are built.

**Wave 1, done** (`Config.Zombies.View`, `client/ZombieFight`, VfxLib a6e5ca3, 93 effects):
- Every slime skill: the caster glows in its way's colour through the aim (`Skill.Power`), flashes as it lets go, and a
  crit or a heavy skill blow gets hit-stop 0.13 s and a white flash (`View.Hard`).
- A crit has its class's own burst over the mark, sized by the weapon's tier (`Fx.CritLooks`: Warrior
  `hit.blade_cross`, Guardian `hit.comic_punch`, Ranger `hit.side_gust`, Mage `hit.shard_nova`, Healer `hit.holy`
  crit, Alchemist `burst.stylized_blast`).
- Goo Slam lands in `burst.cghow_dust_shockwave`, Belly Bounce in `burst.prism_pop`, Taunt raises `burst.shield_up`,
  Acid Rain splashes `hit.acid_splat` on each foe.
- A slime falls in `burst.smoke_poof`; the winners cheer in `burst.reward_glitter`; a big monster (size
  `Dungeon.Fx.FallImpactSize` or more) marks the ground in its element as it falls.
- Test: every library effect the slimes' fight names is imported (`tests/spec/monster_fx.luau`).

**Seen** in a MapWork play test (Frozen Ice, phone frame, 24-35 studs): each new effect on a test row at the game's
camera distance; a real Dungeon run of 8 waves played `burst.shield_up`, `hit.blade_cross` and `skill.monster_impact`
with no warning or error. **Not verified:** each moment framed in a live fight (they last 0.3 s), the four darker
maps, a real phone. White additive hits still read pale on the snow.

**Wave 2a, done the same day** (VfxLib 8984735, 99 effects): a plain blow of a held weapon lands in its family's own
impact at its tier, `hit.weapon_<family>` (six families x wood, iron, core, bramble, legend = 30 designs), over the
owner's mark, sized to the one struck, its floor pieces at the foe's feet (`Config.Weapons.Fx.Hit`, `HitHeight`;
`client/ZombieFight` `impact`). Seen in MapWork Play on Frozen Ice: the six families at wood, core and legend on a
test row from 26 studs, and a real run playing `hit.weapon_sword`, `_shield`, `_bow` and `_focus` with no warning.
Coloured bodies hold on the snow (sword, shield, kit, staff at core); still pale there: legend bow, staff and focus,
core shield and bow; the kit's burst reads as black ink. Sent back to the library session. Not seen: iron and
bramble, the dark maps, a real phone.

**Wave 2b, done the same day** (VfxLib 5c79d3b, 104 effects):
- **Taunt** is the library's Guardian Taunt (`skill.guardian_taunt`: three crimson rings, a gold shield emblem, a floor
  ring) instead of the icon bubble `burst.shield_up` (removed from the game's copy).
- **A charge per class through the aim** (`View.Skill.Power.Charge`, one line in `client/ZombieFight` `onAim`): Guardian
  `skill.guardian_charge`, Ranger `skill.draw_aim`, Mage `skill.arcane_charge`, Healer `skill.blessing_charge`,
  Alchemist `skill.alchemist_charge`; it rides the caster and fades as the skill fires.
- **The weapon impacts that were pale on snow were redone in the library** and imported again.
- Seen in MapWork Play on Frozen Ice: a real run played `skill.guardian_taunt`, `skill.guardian_charge`,
  `skill.arcane_charge`, `skill.draw_aim` and four `hit.weapon_*` with no warning; the charges on the real squad from
  behind (a ring of light round each; Mage and Healer strong, Guardian and Alchemist soft gold on the snow); a test row
  of the six impacts at legend (all coloured and clear now) and wood (small, each its own shape); Taunt's red rings
  read on snow, its gold emblem and floor ring are faint there.
- **Not verified:** the Healer's and the Alchemist's charge fired by a real skill (only played by hand on the squad),
  iron and bramble impacts, the four darker maps, a real phone.
- **Left as they are on purpose:** Acid Rain keeps the owner's flasks (the library's `skill.alchemist_acid_rain` flies
  0.73 s and drips 4-5 s, which does not fit the game's rain; `buff.acid_melt` already shows the drip) and Arcane
  Barrage keeps the owner's orbs with `burst.ether_burst` (the library's `skill.mage_barrage` is heavy and still pale
  on snow).

**Wave 3, done the same day: the twelve Uncommon and Epic class skills** (`docs/WEAPONS.md` §11 step 4; brief
`docs/briefs/class-skills-4.md`; VfxLib 3373918, 119 effects):
- **Rules** (`Combat`, `ConfigClasses`, written by ChatGPT, 16 tests): a class knows one skill a weapon tier
  (`Kinds.<class>.skills`), each on its own clock; the highest one that is ready and worth it is cast. Guardian Shield
  Bash, Shield Wall; Warrior Area Slash, Breaker Strike; Ranger Arrow Volley, Snare Arrow; Mage Frost Burst, Arcane
  Lance; Healer Healing Ring, Ward (a barrier); Alchemist Squad Tonic, Cursed Flask. Each sends a "cast" event first.
- **Drawing** (`View.Skill.Looks` rows with `cast`, `client/ZombieFight` `onCast`): each skill is one library effect
  played once from its "cast", and its blows, heals and statuses land on the effect's marker: `skill.guardian_bash`,
  `guardian_wall`, `great_cleave`, `cross_cut` (+ `hit.shield_shatter`), `fan_shot`, `arrow_ring`, `mage_frost_burst`,
  `arcane_ray`, `renewal_rain`, `healer_ward` (then `buff.warded` while the barrier holds), `alchemist_tonic`,
  `alchemist_cursed`. Squad Tonic and Shield Wall leave the attack / defence icons of `buff.stat_set` on those they cover.
- **Seen** in MapWork Play, real Dungeon runs (levels 3 and 6, both debug teams in Mythic weapons, the camera 22 studs
  behind the squad, pictures taken in the engine at each effect's beats): all twelve were cast with no warning or
  error; looked at: Shield Bash, Breaker Strike, Arrow Volley, Frost Burst, Arcane Lance, Shield Wall, Squad Tonic,
  Cursed Flask, Healing Ring, Ward. **Not verified:** Area Slash and Snare Arrow framed (they played, not looked at),
  Ward's lasting bubble alone (only in a crowded melee), a real phone. Healing Ring is faint on the bright meadow.

**Wave 4, done the same day: the six Mythic ultimates and the six Legendary traits** (`docs/WEAPONS.md` §11 step 5;
brief `docs/briefs/class-skills-5.md`; VfxLib 1a3ee47, 130 effects). Every weapon tier now has its own skill.
- **Rules** (`Combat`, `ConfigClasses`, written by ChatGPT, 57 tests in `classes`): the fourth skill of a class is its
  ultimate, known from a Mythic weapon (first cast after 12 s, then every 24 s, two ultimates of a team at least 1.5 s
  apart): Guardian Bulwark (the team takes less and is steadier), Warrior Whirlwind (0.8 s wind-up), Ranger Arrow Rain
  (1.2 s), Mage Meteor (1.5 s), Healer Sanctuary (four heals over 3 s), Alchemist Catalyst Cloud (the foes melt). A
  Legendary weapon adds its trait: Last Stand (Guardian), Momentum (Warrior), Hawkeye (Ranger), Echo (Mage), Overflow
  (Healer), Lingering Brew (Alchemist); Last Stand and Momentum send a "trait" event.
- **Drawing** (`View.Skill.Looks`, `View.Skill.Traits`, `client/ZombieFight`): Bulwark `skill.guardian_bulwark` (the
  seal) then `skill.spirit_guardian`, and `buff.stat_set` defence on those it covers; Whirlwind
  `skill.whirlwind_slash` after `skill.battle_focus`, the Warrior stays where it is; Arrow Rain
  `skill.ranger_rain_warning` on the ground through the wind-up, then `skill.arrow_volley`; Meteor
  `skill.mage_meteor_windup`, then `skill.meteor_fall`; Sanctuary `skill.healing_sanctuary`; Catalyst Cloud
  `skill.alchemist_catalyst` (+ `buff.acid_melt` on the foes); Last Stand `burst.last_stand` and Momentum
  `burst.momentum` on the slime with the trait's name. Hawkeye, Echo, Overflow and Lingering Brew change blows, heals
  and times that are already drawn.
- **Seen** in MapWork Play, real Dungeon runs (levels 3, 6 and 9, both debug teams in Legendary weapons, the camera 22
  studs behind the squad, pictures taken in the engine): all six ultimates and both trait flourishes played; the log
  has no warning or error from the fight drawing. Meteor, Whirlwind and Arrow Rain are strong; Bulwark's seal, circle
  and the shields on the squad read.
- **Bright maps, fixed in the library the same day (VfxLib 172d1da) and seen again in Dungeon runs:** Sanctuary on the
  snow was a white dome of glare that hid the fighters: now a gold ornamented ring on the ground, everyone in it
  visible (thin and pale on snow, but it reads). Bulwark's spirit knight on the meadow was a yellow-white blaze: now
  his crown, pale body, cape and raised blue-gold shield can be told. Catalyst Cloud's gas hardly showed on the meadow:
  now dark violet smoke over the foes, who stay visible.
- **Balance after steps 4-5** (`docs/WEAPONS.md` §13): at the same Arena power a higher tier now beats Common 75-100%
  (target about 63%): the skills are worth more than the Arena's power counts. **The owner decided 2026-11-14 to keep
  it** (rarer weapons are meant to win in the Arena): no rebalance.
- **Not verified:** Last Stand in a picture (it played twice, not framed), Sanctuary on a dark map, Hawkeye / Echo /
  Overflow / Lingering Brew by eye (tests only), a real phone.

## 2026-11-14 — favorite the game and join the group: a big gift each, the tutorial's last step

The owner: every game asks players to favorite it and join its community, with a big reward; put it at the end of the
tutorial. Done (`shared/Social`, `Config.Social`, save schema 14 `rewards.social`):
- **Tutorial step `social`** (last of `Config.Guide.Steps`): "A big gift! Tap the trophy..." with Next and Skip; the
  arrow points at the trophy, which shows on this step; the sheet opens on its new **Community** tab. Taking every gift
  or Next ends the tutorial. Players past the tutorial find the same tab on the trophy (its badge counts what waits).
- **Favorite** (3x the cheapest upgrade in coins, 30 min luck, 3 spins) and **Join our group** (5x, 60 min, 5 spins, 2
  monster cores), each paid once. The group is checked on the server (`IsInGroupAsync`, then the player's group list);
  a favorite cannot be seen by a server, so the client's word is taken once. `Config.Social.GroupId` is 0: **the group
  row stays hidden until the owner sends his group id**.
- Debug menu: Guide > "Last step". Seen in Studio on an iPhone 17 Pro frame: the card, the arrow at the trophy, the
  Community tab with its row. Not verifiable in Studio: Roblox's favorite and join prompts (an unpublished place has no
  favorite; no group id yet). The two icons (`favorite`, `community`) are stand-ins until drawn.

## 2026-11-13 — one fight everywhere: camps and the Arena by places, Piercing Shot pierces, weapons drawn

The owner: Piercing Shot must fly through, every foe on the arrow's path takes the blow; the camps and the Arena must be
fought by each fighter's place like the Dungeon; slimes there showed no weapon or skill; fights are the same everywhere
(one equipment system). Done (`docs/WEAPONS.md` §2, §3.3, §7; `docs/weapons/SKILL-VFX.md` §1):
- **Piercing Shot**: every foe within 36 studs along the arrow and 2.5 either side takes the full skill blow, nearest
  first (`Config.Classes.Skills.piercing_shot` length, width); the arrow flies to the farthest and each foe is struck as
  it passes.
- **Camps**: the fight is positional (`Config.Zombies.FieldRadius` 30): the team stands in its march formation, the
  zombies on their ring (`Zombies.formation`, `Zombies.ringSpot`, shared by server and client), and the bodies walk by
  the server's moves. March bodies wear their weapon on the back and draw it at the fight.
- **Arena**: positional too, two rows facing (`ArenaFight.spot`), both sides at slime walking speed, inside the field
  less `EdgeMargin`; the replay walks the bodies and each slime holds its weapon (`hand` in the replay's view).
- Seen in Studio: a camp-3 fight at level 85 (bodies walk, weapons from back to hand, skills, two slimes fell) and
  three Arena replays (walking, weapons in hand, skill bursts, Victory), no script error. Not seen: a clear frame of
  the arrow passing several foes (the tests check who is struck), a phone, the owner.
- **Arena bots hold weapons** (the owner's yes, the same day): four different classes a team at the tier of its level
  (`Config.Arena.BotTierLevels`, Common to Legendary), skills and all, power unchanged; `arena_sim` moved by noise
  only. Seen in an Arena replay: the rival team in its row, each with its weapon in hand.
- **Library e2037cf imported**: the redone weapon effects (78 new designs, same ids) and the last two status looks,
  `buff.acid_melt` and `buff.slowed`, so every lasting effect now shows. Weapon casts that mark the floor skip their
  own slime and weapon (`ignore`). The owner found the first cut ugly; the library redrew them as ChatGPT clips
  (1da91f8, imported): the slows now sit round the foot and the slime stays clear. Seen in an Arena replay (no error)
  and on the real slime mesh (`SKILL-VFX.md` §6).
- **Library b25782a imported**: the 18 held weapon auras are ChatGPT clips fixed on the weapon in 3D (a card through
  its middle that turns with it, motes round it); Sunfire is built in 3D (glowing gems, a flame winding up the blade).
  Seen in an Arena fight and up close, no error; not tried on a phone.

## 2026-11-13 — longer ranged reach, skill power by rarity, single and area targets, effects that last show

The owner: ranged reach 1.5 times; an attack skill weighs the plain blow times the weapon's rarity (Common 1.1,
Uncommon 1.2, ...) plus the weapon's own effect; single-target skills hit one foe, area skills every foe in the area;
buffs and debuffs show on every fighter under them while they last. Done (`docs/WEAPONS.md` §2-3,
`docs/weapons/SKILL-VFX.md` §6):
- **Reach**: Bow and Focus 24, Staff 22.5, Kit 21 (`Config.Classes.Kinds`); Mend's range 22.5.
- **Skill power**: `Config.Classes.SkillPower` = 1.1, 1.2, 1.3, 1.4, 1.5 by tier, on Dash Strike, Piercing Shot,
  Arcane Barrage and Acid Rain (a Common Dash Strike is now 1.1 x 1.05 of an ATK blow, it was 1.5).
- **Targets**: Piercing Shot strikes its foe only; Barrage and Acid Rain every foe within 7 / 8 of the target at full
  weight (the camps and the Arena, which have no places: 3 foes).
- **Effects that last**: a `status` event; taunted, shielded, guarded, stunned, melted and slowed each have a look worn
  on the body for as long as they last. Seen in a Frozen Ice run (taunt marks and Guardian shields, on the right
  fighters); the acid melt and the slow are ordered from the library and show nothing until they come.

Not done: the library's acid melt and slow; a balance sweep with the new numbers. Not seen: a phone, the owner.

## 2026-11-12 — skill effects from the library; the missing ones listed; weapon effects to be redone

The owner asked to redo the skill effects from our VFX library, to list and design the ones it lacks (he builds those
himself), and to redo the weapon effects: more striking at every tier, every weapon its own. Done
(`docs/weapons/SKILL-VFX.md`):
- **In the game**: Dash Strike plays the library's Flash Step (its cuts open as the blow lands), Piercing Shot its
  Piercing Arrow, Mend its Blessing Light, Arcane Barrage's orbs burst in its Ether Burst; each at the level of the
  caster's weapon tier (`View.Skill.Levels`, `TierScale`). Seen in a Frozen Ice run and a lineup, no errors.
- **The map of the 24 skills**: 15 have a library skill (the four in, and Bulwark, Area Slash, Breaker Strike,
  Whirlwind, Arrow Volley, Snare Arrow, Arrow Rain, Arcane Lance, Meteor, Healing Ring, Sanctuary for steps 4-5); 9
  have none (Taunt, Shield Bash, Shield Wall, Frost Burst, Ward, Acid Rain, Squad Tonic, Cursed Flask, Catalyst Cloud).
  Fourteen pieces in all are missing (those nine, Arcane Barrage's missiles, three wind-ups, Arrow Rain's warning),
  each with a proposed look.
- **Weapon effects**: the new rule (every weapon its own look from its model, a whole layer more at every tier, read
  from the gameplay camera and on the snow) and a theme for each of the 30, sent to the library session to build.

Not done: the library's new weapon effects (in the library session); the fourteen missing skills (the owner builds
them). Seen only on the snow map, where the library's white light is faint. Not seen: a phone, the owner.

## 2026-11-12 — weapons in hand (step 3): worn on the back, held in a fight, swung, shot and cast

The owner said "Làm bước 3" and set one rule for where weapons sit: at rest and in the village every weapon is slung
across the back, the Alchemy Kit always at the slime's left; in a fight the shield and the bow are in front, the sword,
focus and staff at the right; every blow and cast moves the weapon with its own effect. Done (`docs/WEAPONS.md` §14):
- **Models**: the owner's seven files cut into 30 weapons by `tools/blender/weapon_kit.ps1`, uploaded, named in
  `Config.Weapons.Models`.
- **Wearing and moves** (`client/SlimeWeapon`, `shared/WeaponMoves`): village slimes wear theirs on the back, Dungeon
  squads draw them as a fight begins and put them away when they fall; each family's attack and cast move (the
  original's) is timed so its blow meets the server's hit.
- **Shots and skills**: arrows from the bow, orbs from the focus, bolts of light from the staff, flasks from the kit,
  each with the owner's battle-art marks; Taunt rings, Arcane Barrage orbs, Acid Rain flasks, Mend light, the healer's
  heal mote. `tests/spec/weapons.luau` holds the placement rule, the models and the moves.
- Seen in Studio: the back, left and hand places from behind and in front, a full Frozen Ice run (arrows, orbs, marks),
  no errors (`docs/weapons/review/`).

- **Swing trails** from the VFX library (cdf384f): every family's move leaves its ribbon, finer each tier (the Legendary
  sword a crimson and gold arc with starlight and embers). Seen in a lineup and riding the weapons in a Dungeon run.
- **Cast bursts and auras** from the library (80de5f4): every cast goes off at the weapon's head (the Legendary shield's
  golden dome, the Everbloom staff's leaves of light), and Epic-and-up weapons wear their aura while in hand. Seen in a
  lineup and a Frozen Ice run.

Not done: weapons on the Arena's replay bodies and the zombie march; the higher-tier skills (steps 4-5). Not seen: a
phone, the owner.

## 2026-11-12 — classes balanced for the Arena; Legendary, a fifth weapon rarity; the owner's 30 weapon models in

The owner chose "balance first", then sent his 3D weapons (six Meshy files, a family's four tiers in a row each) and a
Legendary set ("a new grade ... rarity: Legendary"), and asked that higher rarities carry more and finer effects and move
better. Done:
- **Balance** (`docs/WEAPONS.md` §13): the first sweep had fought team against team positionally, which the Arena never
  does; the sim now runs `ArenaFight.simulate` itself. Heals weigh like a blow on a slime of the healer's own strength
  (they had outgrown blows at high levels); the Arena's rules of §7 are in (heals fade from 30 s, 90 s limit, the timeout
  goes to who stands, then health, then damage; was a free defence win). The Guardian always takes 20% less (35% while
  taunting); the damage classes beat at 1.0 with signature skills every 6-8 s (a weapon had made a slime weaker than a
  Brawler). Measured at level 60: mirror 50%, weapons over none 71%, one Healer heals 27-34% of the damage taken, every
  hard match-up of §10 inside 35-66%, no four of one class above 32%.
- **Legendary**: a fifth tier `legend` for weapons (Head and Charm stop at Mythic), six weapons (Sunfire Blade, Royal
  Bastion, Moonsong Bow, Astral Scepter, Everbloom Staff, Grand Elixir Pack), about 12 level points each, crafted from
  the Ember Lava and Frozen Ice trophies (4 + 4, Monster Core 3, Boss Essence 2, 1000 coins), pictures rendered from his
  set (`tools/blender/weapon_icons.ps1`); traits designed (§3.7), built with the ultimates in step 5. Seen in Studio:
  the Smithy's Legendary card, gold, with picture, stats and recipe.
- **Models**: all seven files in `art/models/weapons/source/`, looked at (`tools/blender/weapon_look.ps1`); step 3 cuts
  and holds them. The owner's rule on rarity looks is in WEAPONS.md §1 and §9.

Not done: weapons in hand (step 3, next), the higher-tier skills (steps 4-5). Not seen: a phone.

## 2026-11-12 — weapon classes built (steps 1-2): the weapon gives the class, six Common classes fight

The owner said "Bắt đầu xây". `docs/WEAPONS.md` steps 1-2 are in: the rules core in `Combat` (magic damage, heal
weight, flat crit, dodge on plain blows, skills on cooldowns, stun count, boss specials 8 s apart, melt, taunt), the six
Common classes with their brains and signature skills (Guardian Taunt and Intercept, Warrior Dash Strike, Ranger Piercing
Shot and hop, Mage Arcane Barrage and hop, Healer heals and Mend, Alchemist Acid Rain), numbers in `Config.Classes`;
the 24 weapons at the Smithy (one family a time on the Weapon tab, icons from the owner's equip art); a slime with no
weapon is a Brawler as before. Seen in Studio: dungeon runs with both debug teams, every class casting, no errors; the
Smithy's family row. The first sweep (`tools/balance/class_sim.luau`, WEAPONS.md §13) shows heals too strong (stalls),
ranged beating melee, Mythic winning 100% over Common, and little gain over a Brawler at level 60: tuning is step 7. Next: step 3, the
weapons in hand (models, swings, projectiles, skill effects through the VFX library). Not seen: a phone.

## 2026-11-12 — weapons, classes and skills designed (with ChatGPT); dungeon fixes

The owner asked for slimes that hold and swing weapons, a class and its skills and AI from the weapon, fewer skills at a
lower rarity, and support and counter classes, argued out with ChatGPT. Three rounds later the design is
`docs/WEAPONS.md`: his original's six families (Guardian/Shield, Warrior/Sword, Ranger/Bow, Mage/Arcane Focus,
Healer/Healing Staff, Alchemist/Alchemy Kit) plus the weaponless Brawler; Common = full AI + the signature skill,
Uncommon and Epic one skill more each, Mythic the ultimate; cooldown ultimates, taunt, stun count, threat, three fight
modes and the rings on the team sheet; its §11 is the build order (next: the rules core). Nothing of it is built yet.
Fixed before it (bc6cb40): village slimes no longer follow the player into the Dungeon (`Config.Brain.PlayerFollowStuds`),
knock-backs no longer add up and a big body is heavy (`KnockWeight`; not measured in a boss fight), the team chips are a
2 x 2 grid and a tap opens that team's sheet anywhere.

## 2026-11-12 — a loading screen that hides the start's hitches

The owner asked for a game loader (less lag when the game starts) and a loading screen that is not boring.
`src/first/Loader.client.luau` (Rojo puts it in `ReplicatedFirst.Loading`; numbers in `src/first/LoadingConfig.luau`,
since Config has not arrived when it starts) is the original's screen (`docs/reference/03-shell-ui-world.md` §3): the
owner's meadow (`scene.loading.png`, uploaded), the navy slime bouncing (tap it: a big hop and a "Boing! xN" count), a
gold bar and rotating tips. It waits for the game, the player's farm, the ground streamed around the character, the
first screen's pictures (every `Config.Ui.Icons` id and the HUD) and 15 smooth frames, each step capped, with a Play
button after 20 s; the log prints each step's seconds. `tools/build_publish.luau` and `tools/map/sync_all.ps1` carry it,
and the build no longer asks for the old MonsterKit (the monsters are uploaded meshes now). Seen in Studio: about 20 s
there, most of it the server building the plot (1-12 s in Studio, which runs both sides on one machine). Not seen: a
phone, a real server.

## 2026-11-11 — the 28 monster slimes are in the Dungeon, rigged and moving

The owner's four 3D files (one a region) are split into 28 monsters, rigged and given Idle, Move, Attack, Hit and Die in
Blender, uploaded, and every Dungeon monster now is its monster slime (`docs/MONSTER-SLIMES.md`, "In the game"): its
mesh from Roblox, its moves sampled into `src/shared/MonsterClips` and played by `client/ClipRig`, the fight starting
its attack so the blow lands on the hit. Their new names show over them. The Egg Heist creatures left the built game
(`assets/MonsterKit.rbxm` stays in the repo). Seen in Studio: all 28 in a line-up, an Ice run to wave 8, no errors. The
owner checks them in the game next ("khi nào xong hết tôi sẽ vào game kiểm tra 1 lượt"). Not seen: a phone.

## 2026-11-10 — Secret slimes wear their own pieces (Tempest Dragon, Steam Dragon, Fire-Ice Chimera, Shadow Wolf)

The owner sends a Meshy model per Secret slime (so far each one tail, one bat wing, one horn): `secret-black-blue`
Tempest Dragon, `secret-blue-red` Steam Dragon. `tools/blender/wear_kit.ps1 <Kit>` (a table per kit in `wear_kit.py`)
splits them, mirrors the wing and horn into pairs, sets them on a body one unit tall, renders `review/` and writes
`wear.json`; the FBX goes up through `open_cloud_invoke` (the owner approved `art/models` in Studio's MCP Permissions;
models 107139793078199 and 78918189995011), `InsertService:LoadAsset` gives the five mesh ids. `Config.Wear` maps a
Secret to its kit; `client/SlimeWear` builds the pieces from their mesh ids, `SlimeLook` puts them on, `SlimeActor` makes
them ride the skin (anchor + the jelly's lean) and flap (wings 12 degrees, 0.8 Hz). Next kit: a new table entry, run,
upload, a new `Config.Wear` entry. The owner saved the test place to Roblox as "Slime" (place 118370379105805). Not
seen: a phone.
Owner's note on the horns ("góc sừng của con steam dragon chưa đúng ... gốc của 2 cặp sừng còn bị lộ"): a horn's flat
base (found as the plane its bottom rests on; Steam's is the lip of a hollow cup) is now turned level, and the horn is
seated on the body so that base never shows (see the rule below); Steam's tips curl out to the sides
(`curl = "out"`), Tempest keeps its old look. Seen close up in Play.
Two more kits, the same day: `secret-navy-red` Fire-Ice Chimera (a red horn on its red side, a blue one on its blue
side, a red-to-blue arrow tail; model 109191823877589) and `secret-black-gray` Shadow Wolf (two wolf ears at the
shoulders, open to the front, and a bushy smoky tail; Tripo, model 89148182836943). `wear_kit.py` now takes any pieces
per kit (`pieces`: horn for horns and ears, wing, tail; `twin` mirrors one into a pair; `level = false` keeps a part as
the file stands it; a tail's `base` end and `sink`). Seen in Play from the front and the back.
Owner's rule for every horn and ear, the same day ("nằm sát phần ngoài của slime nhiều nhất có thể để giữ được các chi
tiết gần gốc"; the wolf's ears sank and lost their lower fur): a piece is no longer sunk to its collar. It is moved
along its axis until its foot (a horn's sole, the lowest tenth of an ear, `foot = "low"`) touches the skin, only the
foot's rim 0.02 under it, and where the shoulder falls away under the foot the lowest part is drawn down onto the skin
(`seat` in `wear_kit.py`). All four kits rebuilt: the wolf's ears stand at the shoulder edges with their fur hanging
down, the Chimera's spiked collars and the dragons' horn bands show. Models now 137031942711781, 88958587355820,
119200639103906, 117979860637781 (wings and tails kept their meshes).
The whole job is now the project skill `slime-wear` (the owner asked for a standard way, kept current): steps, every kit
field, upload and Config, lessons, `tools/blender/wear_inspect.ps1` (a file's loose bits and six renders before its kit
is written) and `play_check.luau` (every dressed Secret alive in a row in Play, with close-shot cameras). A dry run by
a fresh agent found its gaps (colour ids, kinds the tool lacks, sort and budget errors), now written in.
Three more kits, the same day: `secret-black-navy` Midnight Raven (two starry feathered wings; the owner: the painting's
wings are wrong, raised they stood too high, folded at the sides or on the back they were not what he wants: so, as
his sketch over the back view draws them, they grow from mid-back near the spine and spread wide and level out to the
sides, the long feathers curling up at the ends, beating slowly: kind `aim`; model 105971591012484; the owner approved
it as the standard for every bird's wing pair, pose, place and motion, in skill `slime-wear`), `secret-black-orange` Jack-o'-Slime (a sheet of pumpkin vines and leaves; the owner: the
vines grow out past the body as his painting draws them, so a leafy vine rises off each shoulder and a curling vine runs
down each side, upright and out past the outline, kind `frame`; vines at the foot in front and a big curly vine with
leaves on the back lie on the skin, kind `wrap`; the face stays clear; model 104420315090131) and `secret-black-pink`
Gothic Bat (bat ears, bat wings, a thorny tail growing from a rose to a pink tip; model 96930448698996). Tails and ears
now move (the owner: "gắn thêm chuyển động cho phần đuôi và tai"): every tail wags (`flap` about the up axis) and
trails the hop (`lag`: a spring on the slime's climb), every ear flicks back now and then on its own clock (`twitch`)
and trails the hop; `Config.Wear.Twitch` and `Config.Wear.Lag` hold the shared numbers, `tests/spec/wear.luau` fails a
tail or an ear that does not move. All seven dressed Secrets seen alive in Play (n/n pieces), the three new ones close
from the front, three-quarter and back; tails measured turning 10-20 degrees and ears 16-22 in Play. Not seen: a phone.
Three more, the same day: `secret-black-purple` Void Kraken (eight cosmic tentacles; the owner: they grow from under
the body and curl, uncurl and wriggle like an octopus's arms): new kind `tentacle` in `wear_kit.py` rigs each arm
with five bones (weights by distance along the arm over its surface) and exports them in the FBX; `client/SlimeWear`
makes the Bones by name under each skinned MeshPart and turns them each frame, a wave running to the tip while the arm
slowly curls and uncurls, every arm on its own beat; the front pair at +-40 degrees, the back pair tall so their curls
show over the shoulders; model 100288988956406, seen bending in Play. `secret-blue-orange` Sunshower Fox (fox ears and
a bushy tail; model 111111432845594). `secret-blue-pink` Cotton Candy Sheep (pink ram horns, sheep ears out to the
sides that flick up, a cotton-candy garland worn as a crown, puffs at the sides and in front; model 109726191050235).
All ten dressed Secrets n/n in Play; the older seven rebuilt unchanged after the tool change. Not seen: a phone.
The owner's look the same day: the sheep keeps only its horns and the tuft on its head; some tentacles sank into the
body and showed as stubs at its side, some turned their purple suckers up. `wear_kit` now finds each arm's suckers by
the texture's colour and searches its climb and roll: every arm joins under the body and goes out low, suckers down or
out, nothing through the side; model 91899436585494, seen in Play from the front, the back, low and above.
Three more from one file of the owner's (one white feathered wing, one bee wing, one torn bat wing), the same day:
`secret-blue-blue` Cloud Pegasus wears the white wing mirrored into a pair in the Raven's pose, smaller (model
87390925158467); `secret-black-yellow` Honeybee Slime the bee wings rising up and out from the upper back, buzzing
(14 degrees, 3 Hz) and see-through (new piece field `clear`, 0.35; model 71604348945099); `secret-black-red` Blood
Moon Bat the bat wings up and out from the upper shoulders as its painting has them, the two holes torn through the
membrane mended (`mend` in `wear_kit.py`: each hole found from the wing's outline, patched just under both faces,
each patch face wearing its own tile of the membrane's texture; model 113673886578474). All thirteen dressed Secrets
n/n in Play, the older ten rebuilt unchanged; the three new ones seen front and back, the mended wing close. Not
seen: a phone.
Then `secret-gray-purple` Moonstone Gargoyle from the owner's `gray_purple.glb` (stone bat wings, two horns, an
arrow-tipped tail): the wings spread up and out from the back of the shoulders (spread wing motion, 12 degrees at
0.8 Hz), the horns on the front of the head's top corners as the painting has them (set further back they merged with
the wing roots from the game's camera), the tail hanging from the back with a slow heavy wag (the painting shows no
tail; the file has one, so it is worn). Model 128659610713284; all fourteen dressed Secrets n/n in Play, the gargoyle
seen front, back, side and three-quarter. Not seen: a phone.
Then `secret-blue-white` Frost Swan from the owner's `ice crystal wings 3d model.glb` (the painting's ice pieces as
raised plaques), worn proud of the body as he asked: the two crystal frills up the lower front sides, their feathers
out past the outline to eye height, as the painting draws them (he said they are not a bird's wings: new kind `front`
in `wear_kit.py`, which keeps a plaque's relief outside the skin), and the crest on the front under the top (`wrap`).
Left out: the foot's crest (it would meet the ground as the jelly squashes) and the snowflake (it would sit on the
face). Model 106684279429446; all fifteen dressed Secrets n/n in Play, the older kits rebuilt unchanged, the swan seen
front, level, back, side and three-quarter. Not seen: a phone.
Hand-over: 15 of the 56 Secrets wear their pieces. The next one starts when the owner sends its file: skill
`slime-wear` from step 1. Everything learnt today, right and wrong, is in the skill (the owner's rules in SKILL.md, a
"What worked" list and every mistake with its fix in LESSONS.md); the close shots in Play are one command now,
`.claude/skills/slime-wear/shoot_close.ps1 <studio> <secret> <out>`.
Then three at once, the owner: "không cần phải chính xác như trong hình, chỉ cần gắn lên cho đẹp".
`secret-green-green` Forest Dryad: antlers at the top corners, the leafy hair round the top as the painting has it
(`front`), blossoms, a leaf and a vine on the back (model 117231029918059). `secret-gray-red` Iron Boar: two metal
tusks in red cuffs out of the lower sides, tips curling up (the owner: "là 2 cái nanh, không phải sừng"; worn as horns
with the new `spread` 90, which finds a sole facing sideways), a spiked circlet round the head (`aim`) and an armoured
tail (model 89853209729270); left out: two curved armour plates (they stood off the body like fins), the collar and a
gem. `secret-pink-yellow` Peach Blossom: the blossom crown across the top as painted (`front`), two clusters behind it
and a festoon across the back (model 136245608358614); left out: a bead blossom (on the face), a branch and petals.
All eighteen dressed Secrets n/n in Play, the three seen front, level, back, side and three-quarter; the other kits
were not rebuilt (`spread` defaults to the old 40). Not seen: a phone.
The owner's notes on them: the flower and leaf meshes were deformed ("giữ nguyên mesh ... không cần phải kéo để nó ôm
sát thân"), and the boar's tusks belong on the front of the face, not the sides. New kind `rigid` in `wear_kit.py`
(turned, moved and scaled only, touching the body at its deepest point): the Dryad's hair, blossoms, leaf and vine and
all of Peach Blossom's pieces now keep the file's 3D shape, with nearly all their triangles. The tusks stand low on the
front either side of the mouth, pointing forward, tips curling up (`spin`, a new horn field). Models: Forest Dryad
73928175279860, Iron Boar 122177229873839, Peach Blossom 136863691703075. Seen in Play from five sides; no other kit
uses the new fields. Not seen: a phone.
`secret-purple-purple` Amethyst Unicorn (model 130026127101028): the crystal horn at the top front, the mane from just
behind it over the head and down the back to the feet like a horse's (the owner's rule and sketch: pressed onto the
body, part of it in the jelly, flattened in width; never down the sides of the face), the file's row of five crystals
across the lower front. `secret-gray-orange` Copper Beetle (model 136341424878040): the painting's shell, every plate
as the file shapes it laid close on the body: the cap on the head, the shield down the back, shoulder and side plates
on the back and again on the front either side of the face (the owner: "nhớ ghép cả giáp ở phần trước thân nữa"), four
claws at the feet; left out: three small bands and two rivets. `rigid` gained `squash`, `tuck`, `fit` and `lay="side"`,
and a part may be worn twice; Forest Dryad and Peach Blossom rebuilt to the same numbers. `Config.Wear` moved to
`src/shared/ConfigWear.luau` (Config.luau neared Studio's script limit). All twenty dressed Secrets n/n in Play, the two
seen from five sides. Not seen: a phone.

Five more Secrets wear wings from the owner's `fantasy wings 3d model.glb` (five single wings, each mirrored into a
pair): `secret-pink-pink` Rose Fairy (fairy wings), `secret-pink-purple` Dream Butterfly, `secret-navy-pink` Twilight
Moth, all three worn on their straight inner edge down the back either side of the spine, level with the body (the
owner: not as their paintings, lower, bigger, joined at the straight edge, not the point), beating as a butterfly's do:
turning on that edge back toward each other and open again (fairy quick, butterfly slow, moth soft; `flap` gained
`bias`, `aim` gained `edge`);
`secret-orange-yellow` Sun Phoenix and `secret-purple-yellow` Royal Griffin, feathered wings in Midnight Raven's pose
and beat, tips at about +-1.0. All twenty-five dressed Secrets n/n in Play, the five seen from five sides. Not seen: a
phone.

Four more wear ears and a tail from the owner's `stylized fox tail 3d model.glb` (four rows of two ears and a tail):
`secret-navy-white` Arctic Wolf, `secret-orange-orange` Ember Tiger, `secret-orange-purple` Witch Cat and
`secret-orange-white` Creamsicle Fox. The ears stand at the top corners as the paintings have them, leaning out a
little, and flick now and then; the bushy tails sit low on the back, wagging and trailing the hop (wolf brisk, tiger slow,
cat lazy, fox bushy). The reference painting `slime.secret.orange-white.png` is the Yellow+White daisy slime (the
owner, 2026-11-10); the game's own Creamsicle Fox skin is right. All twenty-nine dressed Secrets n/n in Play. Not seen: a
phone.

The owner still saw light under those ears after the first fix. They now lean with the shoulder, set 0.08 into the
jelly with their foot drawn on over most of their height, and swivel about the upright instead of flicking back (a
flick tipped the foot's rim off the skin); every root checked in 3x close-ups of the Play shots from four sides.
Then the owner shot Ember Tiger and Creamsicle Fox close and low and still saw an ear's foot off the body: each pair
had one mirrored angle, though the file's two ears differ. Now every ear is turned on its own (`fit` in `wear_kit.py`)
to lay its whole foot rim on the skin, and the close shots add two from low at the front (`-lowright`, `-lowleft`).
The owner: each round made them worse; copy Sunshower Fox, whose ears he likes. The four now wear their ears at
Sunshower's exact place and angles (`at` +-0.34, 0, 0.7, lean out 32, no lean back, the default seat), scaled to its
height; the per-ear fit is gone from the tool, and the skill says every pair of ears copies Sunshower Fox.
He still saw them differ and placed the eight ears himself in the new ear editor (skill slime-wear: `ear_editor.luau`
puts the slimes on a stage over the map for Studio's Move and Rotate tools, `ear_read.luau` and `ear_write.py` bring
his places back). A piece now keeps an optional `turn` (degrees, about its own middle) in Config.Wear, drawn by
`SlimeWear` at rest and in motion; a hand-set pair is not held to the mirror test. Rebuilt from Config, the stage
reads back unchanged, and the Play shots show his angles. His rule from now on: Claude places ears roughly, he
fine-tunes them in the editor.

2026-11-11: seven more Secrets wear pieces from three owner files. `demon_wings.glb`: Coral Axolotl (`secret-orange-pink`,
gills that sway and small leaves) and Fire Dragon (`secret-orange-red`, big and small horns, bat wings that beat; the
file's wing was torn, `mend`'s new `scallop` fills the bitten edge to a smooth arc and the whole wing is worn on both
sides). `fantasy_icons.glb`: Autumn Fox (`secret-green-orange`, leaf fox ears, Sunshower's standard), Holly Deer
(`secret-green-red`, antlers with holly), Deep-Sea Leviathan (`secret-navy-navy`, paddling fins and a lure that bobs).
`bunny_ears.glb`: Snow Rabbit (`secret-white-white`) and Sakura Bunny (`secret-pink-white`, no painting: placed like
Snow Rabbit), ears and a cotton tail each. Models 136774730886462, 95357458515961, 134708971114673, 127539713384618,
81131164014814, 109887950093986, 111477370477627. The wings and fins were moved forward after the first Play shots hid
them behind the body from the front. Then the owner placed every piece of the seven himself in the editor (he added a
second pair of gills to Coral Axolotl) and asked for both sides alike: `ear_mirror.luau` evens each pair, and his
places are in Config.Wear, seen in Play.

2026-11-11, six more from two owner files, placed roughly for the owner to fine-tune in the editor (his rule).
`fantasy_wings_b.glb` (his second "fantasy wings" file): Rose Dragon (`secret-red-red`, red horns with a spiked collar,
whole bat wings that beat), Star Owl (`secret-navy-yellow`, starry feathered wings, Raven's pose), Thunder Ram
(`secret-gray-yellow`, ram horns, the file's left one on both sides; the golden cloud swirl worn as a wagging tail, the
painting shows none). `golden_wing.glb`: Thunderbird (`secret-blue-yellow`, golden wings, Raven's pose), Watermelon
Frog (`secret-green-pink`) and Poison Frog (`secret-green-purple`), frog feet flat on the ground at the front sides.
Not in the files: the Star Owl's and Thunderbird's crests, the Poison Frog's eyes. Models 112581261439114,
127121329117477, 138808936970841, 136944893323987, 100454179348381, 94042749760826. Seen in Play; the editor is open on
them in Studio.

2026-11-11, own bodies: Moss Golem (`secret-gray-green`), Stone Tortoise (`secret-gray-gray`) and Dragonfruit Slime
(`secret-purple-red`) now wear the owner's own 3D models as their whole body instead of a skin on the shared body
(`docs/turnaround.md`, last section: `tools/blender/secret_body.ps1`, `Config.Wear.Bodies`, `SlimeLook` applies the mesh
to the shared rigged body, no outline). Models 113714112407896, 83371849239636, 99837639422512. Seen in Play with
their faces and jelly motion.

2026-11-11, Sun Lion (`secret-yellow-yellow`) and Rose Hedgehog (`secret-gray-pink`): the owner's own models had a lumpy
front, so their body is now the shared body itself ("đúng với dáng của con slime gốc ... phần tóc giữ nguyên"):
`tools/blender/secret_mane.ps1 <folder>` fits the model onto the shared body, bakes its colours onto the shared UV (a new
skin in `SkinIds`; under the mane the sides grow over the back) and cuts the mane / spines with roses off as one worn
piece (`Config.Wear` kits SunLion and RoseHedgehog; a piece may carry its own `texture`). From the owner's phoenix file
(`PHOENIX_TAIL` in `wear_kit.py`): Sun Lion wears the golden lion's tail, Fire Salamander (`secret-red-yellow`) the red
flame ears and flame tail, placed roughly like the foxes'. Models 108739731666477, 133933723128891, 109881506240835,
99746958007317. Seen in Play.

2026-11-11, the owner's floral crown file ("tách chúng ra rồi trang trí cho mấy con slime đó"): `FLORAL_CROWN` in
`wear_kit.py` splits it into ten parts, worn rigid by five Secrets: Lily Spirit (`secret-green-white`) the lily vine
crown and a lily charm, Lemon Gecko (`secret-green-yellow`) the lemon crown and a lemon charm, Daisy Chick
(`secret-white-yellow`) the daisy headband and clip, Moon Orchid (`secret-purple-white`) the moon tiara, a charm and a
lock of violet hair with an orchid down the back, Sakura Bunny (`secret-pink-white`) a pink bow at the foot of its ear.
The owner then set them in the ear editor (the charms moved down onto the belly, the tiara narrowed); his squashed
charm sizes were made even again; then he took off Moon Orchid's hair and Daisy Chick's headband. Models 107571426691299, 110419457246053, 109973044006494, 100562823598542,
89760937609092. Seen in Play.
2026-11-11, the owner reviewed all 66 Secrets on the showcase stage (`.claude/skills/slime-wear/showcase_stage.luau` +
`showcase.luau`) and listed what to change in `aura.secret_signature`: every size x1.7 and rate x1.5 now (`GROW`,
`MORE`), the effect `mid` (up to six pieces, 40 a second), and per Secret: a candy rain (new `candy_rain_flip`, ChatGPT,
not red or white) on Peppermint; more petals (Moon Orchid, Rose Fairy); frosty steam and brighter snow (Arctic Wolf); a
cloud bank at the feet (Cloud Sheep); two koi swimming round on opposite sides (Yin-Yang) and a school of five (Sunset
Koi); pink and green bubbles (Watermelon Frog), more bubbles and hearts; three butterflies or moths always circling
(Dream Butterfly, Twilight Moth); the bats turned upright (Gothic Bat); real licking fire and embers (Sun Phoenix, Fire
Salamander, the Chimera's fire side, snow falling on its ice side); stars of three kinds (Star Owl, Galaxy Whale's ring);
crackling sparks over the body (Thunder Ram, bigger bolts on Tempest Dragon); Christmas lights blinking in four colours
(Holly Deer); rising bubbles (Lagoon Turtle, Void Kraken, Deep-Sea Leviathan, whose lure light now flashes); a grey cloud
with a lightning strike (Storm Shark) or rain (Raincloud Ram); shadow smoke at the feet (Shadow Wolf); a little solar
system (Universe Slime); drifting mist instead of the cartoon cloud (Sky Island Turtle). The runtime's orbits gained
`bob`, `sway` (a wandering path) and `heading` (a fish swims head first). In ConfigWear the Amethyst Unicorn's horn
stands upright and the Leviathan's lure arcs forward from the middle of its forehead. Then, at the owner's word ("we have
an effect library: take from it what can be used"), the fire, lightning and shadow pieces are the library's own Level 1
pet auras at a slime's size (`licks`, `embers`, `sparks` from `blazing_flames`; `bolts`, `zaps`, `charge` from
`electric_bolts`; `shadow_wisps`' dark smoke and wisps; the owner's `frozen_snowfall` flakes on Arctic Wolf), on Sun
Phoenix, Fire Salamander, the Chimera, Thunder Ram, Tempest Dragon and Shadow Wolf; the planets are twice the size. All
seen in Play on the showcase stage (horn, lure and upright bats included).

2026-11-11, the owner's eight decorative fish (`art/models/fish/decorative_fish.glb`): `tools/blender/fish_rig.py` (run by
`fish_rig.ps1`) splits them, names them (`moon_ink`, `gold_ink`, `sakura_ink`, `silver_ink`, `frost_white`, `cream_gold`,
`blossom_pink`, `lilac_white`), gives each a 4-bone spine and writes `fish.fbx` + `fish.json`. VfxLib gained `swimmers`
(`Models.fish`, `Builder` `fishTemplate`/`placeSwimmer`: a fish rides an orbit head first, its tail sweeping in a wave down
the bones; up to 6 an aura, full/half LOD only; Schema `swimmerProblem`). Yin-Yang Koi now has a white and a dark koi on
opposite sides, Sunset Koi a school of five; their old flipbook koi are gone. Seen in Play; `lilac_white` is not used yet.

## 2026-11-10 — Dungeon fight effects per monster, from the VFX library

The owner paused the old effect work and asked for each map group's skills to be rebuilt from his VFX library
(`C:\roblox-vfx-library`). Done: every one of the 28 dungeon monsters has its own blow and fall (`hit.<map>_<monster>`,
`death`/`shot` variants), each healer its own mend (`burst.{moth,deer,drake,penguin}_mend`), and each boss two skills
(wind-up, release): Meadow turtle `renewal_charge`/`pollen_shockwave`, boar `bramble_rage`/`burst.rock_smash`; Mushroom
wyrm `void_charge`/`spore_burst`, bear `umbral_growl`/`leap_slam`; Lava bull `meteor_charge`/`meteor_crash`, golem
`phoenix_charge`/`flame_jet`; Ice mammoth `frost_charge`/`ice_spear`, yeti `frost_howl`/`blizzard`. Wiring:
`Config.Dungeon.Fx` by monster id, `client/ZombieFight` and `client/DungeonFight` play them through `src/shared/VfxLib`
(imported copy; the village zombies and the slimes' own blows are unchanged). In-game shots of every moment:
`docs/ui/dungeon/fx-<map>-<moment>.png`. `skill.earth_rupture`'s stone Beams draw as blank white quads in this place (fine in
the Showroom): not used. Weak spots left: the Mushroom fox shot (not confirmed in game), the bear wind-up is faint on the
dark map, the Lava bull wind-up is pink-white. Not seen: a real phone.

## 2026-11-09 — Frozen Ice, the fourth and last dungeon map (round 4 after ChatGPT's review)

`MapOrder = {meadow, mushroom, lava, ice}`: all four maps of the original now turn per level. Props:
`tools/library/build_ice.ps1` + `make_ice.py` -> `IceProps.glb` (84 meshes: faceted snow ridges, a far land silhouette, snowy
cliff landmarks in the left and right thirds, hero/mid/small crystal clusters, snowbanks, frost bushes, frost patches and
cracks, Ultimate Nature snow pines and bare trees), imported by the owner, ids in `Config.LibraryKit.Props`. New plan kind
`mound`, `NeonAlpha` for translucent crystals, a `Lighting.Clouds` key in `DungeonLight` (overcast winter sky). Monsters: Arctic
Fox, Snow Leopard, Frost Wisp, Penguin (healer), Ice Golem, Mammoth (miniboss, `tuskcharge`), Yeti (`boss_Peaks`, `blizzard`,
a dark ground shadow, drops 2 `frost_fang`, icon from ChatGPT). Seen in a play test: Lava -> Ice swap, every monster, both
skills, the victory panel; shots `docs/ui/dungeon/ice-r1..r4-*.png`. Open: a thin teal strip of the place's far sea and a
green hill can still show at the edge of some views; ice effect art for the two skills and the Wisp shot; no phone view.
Lesson: a minimized Studio window renders the 3D view white (restore it before shooting).

## 2026-11-09 — Ember Lava, the third dungeon map (round 4 after ChatGPT's review)

`MapOrder = {meadow, mushroom, lava}`. Props: `tools/library/build_lava.ps1` + `make_lava.py` -> `LavaProps.glb` (low
basalt masses, ledges, plates, peaks, four connected lava fissures ending in six lit pools with burnt banks), imported by the
owner, ids in `Config.LibraryKit.Props`. Charcoal stud floor `#3F3A42`, starless night with `ExposureCompensation` per map in
`DungeonLight`. Monsters: Fire Newt, Ember Wolf, Phoenix, Inferno Dragon (healer), Rock Tortoise, Magma Bull (miniboss,
`lavastomp`), Magma Golem (`boss_Volcano`, `eruption`, drops 2 `ember_core`, icon from ChatGPT). Seen in a play test: Grove ->
Lava swap, every monster fighting, both skills, the victory panel; shots `docs/ui/dungeon/lava-r1..r4-*.png`. Open: fire
effect art for the two skills and the Phoenix shot (they reuse the battle art), the fissures read small from the player camera,
the far hills are round domes, faint clouds in the sky, no phone view; monsters still read small (all maps).

## 2026-11-09 — Mushroom Grove, round 3 (ChatGPT's review: the glow and runes carry the magic)

Floor `#6c7a40` (darker, less yellow, studs kept); six lit glow clusters (`Glow.Lights = {2,2,1,1}` per quarter, front quarters
first, Brightness 2.2, Range 18, Lift 2, no shadows) placed before the bushes so they find room (`Glows = 2` a corner, seed
`20261124`, the first seed that kept every plan count); runes `#8fffe5` with wider, longer marks (`Runes.MarkWidth/MarkLength`);
cooler shade (Ambient `#758f9c`, OutdoorAmbient `#8ca7b1`, Brightness 2.7, `GradeContrast 0.08` in `DungeonLight`, restored to 0
on exit; the brief's `#6f8a96`/`#86a0aa` was a touch murky); far woods a step darker than the near trees
(`BackdropTints`, zone-aware in the plan, Meadow untouched) so the near willows read against the wall. Seen: player, corner and
a live wave shot, `docs/ui/dungeon/mushroom-r3-*.png`, JPEGs in `review/`. Fewer roots/rocks on the rim than before (the crowd
was the price of six lights).

## 2026-11-09 — Mushroom Grove, phase B done (real props, dusk light, live run seen)

The owner's import of `MushroomProps.glb` is in: 46 Grove props are in `Config.LibraryKit.Props` (MeshId, `tex = "P"`,
`size` from the imported mesh, `at = {0, height/2, 0}`), so the arena stands on its real meshes (631 parts, 268 kit models in
the log). Light: `Config.Dungeon.Arenas.mushroom.Lighting` is dusk teal (ClockTime 17.82, Brightness 2.6, Ambient #8a98b8,
OutdoorAmbient #9aaac8, cool Atmosphere, a faint blue grade); lower ClockTimes (18+) turned the engine sky pitch black and
17.2 left it bright blue, the sunset window is narrow. The floor is a dusk olive (`FloorColour = #7d8742`).
Seen in a StudioTest play test (test-copy Config only: 4 waves, weak monsters, no entry limits; `MapFirstRandom = true` stays
in the repo): Meadow level 1 won, then Next level swapped to the Grove without a fall or flicker, the light eased in, and
over the Next and Replay runs all six Grove monsters fought (Forest Deer, Totem Golem, Cave Bat x2, Fairy Fox, Jungle Wyrm
on wave 3, Mama Bear on wave 4); the Victory panel shows the `glow_spore` chip (2 from the boss) with its own icon.
Shots: `docs/ui/dungeon/mushroom-r2-player.png`, `-r2-corner.png`, `mushroom-live-*.png`, JPEGs in
`docs/ui/dungeon/review/`. Not seen: a real phone, 8 players, the two-camera boss slam from close up, the light on the
Lava/Ice maps (not built). Still plain: the roots read as thin dark strips and the willows as dark blobs at dusk.

## 2026-11-08 — Mushroom Grove, phase A (code, props file, monsters; waits for the owner's import)

Built: the map turns per level (`Dungeon.mapForLevel(UserId, level)`, `Config.Dungeon.MapOrder = meadow, mushroom`; the run's
`mapId`, an arena swap on Next level, player attribute `DungeonMap`), per-map arenas (`Config.Dungeon.Arenas.<id>`,
`DungeonArena.template(mapId)`, `DungeonArenaPlan` with flagstone paths, rune circles, ruins, roots, glowing clusters with
a few point lights), the Grove's light (`client/DungeonLight`), seven monsters from Egg Heist (Jackalope, Cave Bat, Fairy
Fox, Deer, Totem Golem, Jungle Wyrm miniboss, Woods boss "Mama Bear"; `assets/MonsterKit.rbxm`, `src/shared/Creatures/`),
`glow_spore` as the map's trophy. The props are one file, `art/library/converted/MushroomProps.glb` (52 props, built by
`tools/library/build_grove.ps1`): THE OWNER MUST File > Import 3D it once. Until then the arena stands on a fallback of the
owner's own mushrooms and the valley's rocks and teal trees (seen at x=5000 in StudioTest, one warning in the log).
Next (phase B): MeshIds and sizes into `Config.LibraryKit.Props`, a player-camera play test, fix rounds, shots
`docs/ui/dungeon/mushroom-rN-*.png`. Not seen: the real props, the dusk light in a play test, the arena swap between maps
in a live run, Cave Bat / Fairy Fox / Deer / Wyrm / Woods in a fight, the `glow_spore` icon (missing, needs ChatGPT).

## 2026-11-08 — the Dungeon's Sunny Meadow rebuilt with library props (start here for the dungeon maps)

The owner asked for prettier dungeon maps from the downloaded packs and new monsters: Sunny Meadow first, then Mushroom,
Lava, Ice. Done: the Meadow arena (`server/DungeonArena`, `shared/DungeonArenaPlan`, `Config.Dungeon.Arena`) is built from
25 Quaternius Ultimate Nature props recoloured to the painting (`tools/library/take_fbx.ps1`, `fbx_to_glb.py`), packed by
`combine_glb.py` and imported by the owner with one File > Import 3D (`Config.LibraryKit.Props`): layered rim, two rows of
backdrop woods, a ring of hills, four tapered paths, the 35-stud fight circle clear. 273 models, about 70k triangles.
Reviewed with ChatGPT (darker woods, softer hills, paths fade before the fight); shots `docs/ui/dungeon/meadow-r9-*`.
Next: `docs/DUNGEON_MAPS.md` (Mushroom, Lava, Ice: props, seven Egg Heist monsters each, the map turning per level).
Not seen: a real phone's frame time with the 70k-triangle arena.

## 2026-11-06 — Rewards with items, the Lucky Wheel, the VIP Shop and the Robux core (start here)

The owner approved the list and the prices in `docs/MONETIZATION.md` (VIP 249, Luck x2/x4/x8 19/59/159, two team passes,
Bigger Ranch, gold packs, spins, potions, Starter Pack...) and asked for a daily Lucky Wheel and richer rewards.
- Rewards pay spins, food, dishes, materials and gear; 7-day check-in with milestones 14/30/60/100; 4 daily quests with a
  free redraw; weekly quests and chest; 27 Goals; the 60-minute online gift gives a spin. The Lucky Wheel: 1 free spin a
  day (VIP +1), a bank of spins, 9 slices with odds shown. Schema 12. Art by ChatGPT (`art/icons/`: wheel, 20 icons).
- Robux core: catalog `Config.Robux` (every id 0, the shop shows SOON), `server/Purchases` (receipts granted once, saved
  before PurchaseGranted), `shared/Products`, `shared/Boosts`, the luck curve (label -> real 1 + 0.4 log2), VIP and potion
  effects, 6 teams, the VIP chat tag and head crown, the VIP Shop with 4 tabs at the VIP counter. Schema 13. A reviewer
  read it; its 7 findings are fixed.
- Seen in StudioTest play tests: the Rewards sheet with item pictures, a wheel spin landing on its slice and paying once,
  the VIP Shop's VIP and Gold tabs. Not seen: Spins tab (PolicyService restricts in Studio), a real purchase, teams 5-6,
  the crown, the phone frame.
- Next: create the products on the Creator Hub (skill `robux-products`), fill the ids, the owner's test buys; a publish
  must shut down old servers (schema 13). Then the shared VFX library and the slime cosmetics (`MONETIZATION.md` §6).

## 2026-11-05 — The Market square tidied, the old Arena building removed (start here)

The owner: remove the arena built beside the Market, make the shopping area tidy and prettier. Done and saved in MapWork
(2026-11-06), seen in a StudioTest play test (`art/concept/review/market-tidy-r5-eye.png`, `-r5-play.jpg`): every prompt
and the portal at their new spots, no new errors in the log.
- `workspace.Map.Arena` deleted (the Arena is its own client scene since this morning).
- `tools/map/build_market.luau` rewritten: a round flagstone plaza on the fountain, five places on one circle facing it
  (`Config.Market`: Buyer 48,-28; Vip -48,-28; Smithy 48,28; Board 0,62; `Config.Dungeon.Portal.Market` -51,30), one
  straight paved way in, dressing in mirror pairs. `build_smithy.luau`: the Blacksmith gets its own roof, walls and
  chimney. `check_market.luau` MARKET OK. The MCP builders cannot `require` Config, so each keeps a copy of the numbers
  marked EQUAL to Config: change them together. `tools/map/preview_portal.luau` shows the portal in Edit shots (remove it
  before a save).
- Open: the owner's own look; a phone-frame look.

## 2026-11-05 — The Arena scene rebuilt in high detail

The owner after playing: spectators must face the middle (fixed: `ringCF`, never Lune's `CFrame.lookAt`), no player
in the arena (fixed), and the design was far too plain. Rebuilt from four ChatGPT close-ups
(`art/concept/arena-detail-*.webp`) plus a ChatGPT art-director review of the play shot: stone in offset courses, blue
rails with gold-capped posts, four aisle stairs, round arches with keystones and pilasters, eight towers with bronze
braziers and fire, a royal box with columns, drapes, trophy, crown and medallion, an orange gate with a deep tunnel,
portcullis and torches. 3,748 parts, 111 seats. Latest play shot `art/concept/review/arena-detail-r7-play.jpg`.
- Not taken from the review: more crowd density, a bigger trophy, a wider fighter formation (left for the owner's look).
- Open: the owner's own look in Studio; a phone-frame look.

## 2026-11-05 — The Arena is its own scene, seen by the attacker only

The owner: the building was too plain and must not be on the main map; only the attacking player sees a fight; many
attacks on one server at once must work. Done, details in `docs/ARENA.md`:
- `assets/ArenaStage.rbxm` (built by `lune run tools/map/build_arena_stage.luau`, from ChatGPT concept art, 8 review
  rounds): a colosseum with sand, crest, team gates, royal box, three tiers, braziers, bunting. Rojo ships it to
  ReplicatedStorage; `build_publish` copies it.
- `client/ArenaStage`: on Attack the screen fades, this client's own copy stands far from the map, the camera sits in the
  stands (FOV 50), controls are off; the player is not in the scene, only the camera; fade back afterwards. The
  server only simulates, so concurrent attacks cost nothing extra. The old building, its travel stop and prompt are gone.
- The stands hold 127 of the game's REAL slimes (owner's wish): `Crowd` spots filled by `ArenaStage.prepare()` with
  SlimeLook bodies and a still face (`SlimeFace.still`), 6 a frame, some hop and all cheer at the end.
- Gate shields and the royal medallion are ChatGPT art (`art/icons/arena_shield_*.png`, `arena_emblem.png`).
- Open: a phone-frame look at the scene; the owner's own look in Studio.

## 2026-11-05 — Arena stage 3: the screen, replay, titles, shop, the building, balance, review

Everything about the Arena is in `docs/ARENA.md`.
- Screen `UiArena` (Battle, Team, Ranking, Shop, Records), the replay on the Arena's sand (`ArenaReplay`, no camera
  effects), the "No.1 Arena" / "Top 10 Arena" title over heads (`ArenaTitles`), the shop on the server.
- The building (`tools/map/build_arena.luau`): beside the Market, in the lane towards plot 1 (the only flat ground big
  enough); Quick Travel "Arena", a gate prompt, the ranking board. **It is in MapWork only after the owner presses Ctrl+S
  there** (it was built and checked in StudioTest).
- Balance by simulated fights (`tools/balance/arena_sim.luau`): bots 8.75..150, every rival list keeps one team just
  below so a settled team still wins fights; a growing player earns ~160-230 points a day.
- Review and security audit: no way found for a client to cheat or count anything twice. Fixed: debug season tools only
  on the memory ladder, the publish check covers `Config.Arena.StudioUsesRealStore`, resend backs off, a shorter queue
  life, fewer ladder reads, a log race that could show "Match cancelled" for a confirmed match, a replay could clear a
  dungeon run's field.
- Open: the ladder's scale work before thousands of players a month (`docs/ARENA.md`, "Not yet proven"); the
  building's missing pictures (crests, numerals, lettering); a phone-frame look at the screen; real stores only after a
  publish (schema 11: shut down old servers).

## 2026-11-05 — Arena stages 1 and 2, the owner's Studio debug menu

The owner asked for an asynchronous PVP Arena (plan v2: `C:\Users\ngotr\.claude\plans\sorted-meandering-stearns.md`) and
a debug menu only he sees while testing.
- Debug menu (`OwnerDebug`, `UiDebug`, `DebugPresets`): Studio only, stripped from the published place by
  `tools/build_publish.luau`, which fails if either module is left. `lune run tools/build_publish.luau studio` builds
  `assets/raw/StudioTest.rbxl` with the menu, because Studio's MCP scripts cannot add modules to `Shared`.
- Arena logic (`Arena*` in `src/shared`), save schema 11 (`farm.arena`), `ArenaStore` (one ladder document a season,
  written only by the MemoryStore-elected leader; results on a MemoryStore queue; idempotent by seq), `Arena` service
  and `Remotes.Arena`. Points and rank count only once the ladder holds the match's outcome.
- Seen in a StudioTest play test: attack, apply, confirm (+60, rank 759); five fake servers with the real leader paused,
  88 attacks, 88 confirmed, 0 void, 0 left; End season, with the reward claimed once.
- Not seen: real MemoryStore and DataStore on a published server (the publish shuts old servers down: schema 11).
- Next: stage 3 (the Arena screen with 5 tabs, replay viewer, shop, top-10 titles, the 3D arena, then balance, review and
  security audit).

## 2026-11-05 — smoother on phones, server loops that survive an error

Measured in a `Publish.rbxl` play test (repo code synced in, one player). The server holds 60 Hz with a 0.12 ms heartbeat, and
remote traffic is near 0 kbps. DataStore use is within budget (autosave every 5 min, key moments merged into one write every
4 s, leaderboard reads every 60 s). The cost is in drawing, at the home plot:
- the Market's Dungeon portal was outside `EffectsLod`, so its 10 emitters and 4 lights stayed on from every plot. Now
  managed: 55 -> 45 emitters and 21 -> 17 lights on at home (none past their range), and 10/10 come on at the portal. Its 14
  rune canvases stop at 170 studs;
- every face (slimes, zombies, monsters) has 3 SurfaceGuis, all drawn at any distance. They now stop at
  `Config.Slime.FarStuds`, where a face no longer moves. SurfaceGuis drawn: 125 -> 25 at home, most of them from roaming
  zombies across the valley;
- the slime loop no longer makes a closure per slime per frame (pressure on the garbage collector).

Bugs fixed:
- five client scripts logged "Infinite yield possible" on `Villages` at every join: the server now makes the folder at
  start;
- an error in a player's village tick, or in its carry-prompt refresh, stopped that player's village for the whole
  session;
- one player's broken fight frame stopped the fights of every player after them;
- an error while a plot was being copied left it busy, so it could never be built or cleared again;
- Next level and Replay in the Dungeon could leave a run half reset;
- Home and Market travel worked inside a Dungeon run, and then the arena pulled the player back. It now says "Leave the
  Dungeon first."

Not seen live: the Dungeon travel refusal (a run needs 20 slimes and village level 15), a real phone, and 8 players. With 8
players the villages next door (342 studs away) are drawn too. From a read-only review, left as they are: a window in
`AreaUpgrade` where an upgrade that finishes while the plot is attaching may not show; leaderboard loops without pcall; no
length cap on some request ids (they are rejected later).

## 2026-11-04 — smoother frames, a faster first hour

The owner: the game stutters, and new players get bored waiting.

**Frames.** Measured in a play test with ScriptProfilerService:
- every script together takes under 1 ms a frame, and the server holds a steady 60 Hz;
- the cost is drawing: every plot's fires, fountain and lamps (49 emitters, 30 lights) stayed on at any distance, with big soft
  smoke particles.

Changes:
- `client/EffectsLod`: the Map's emitters stop beyond `Config.Perf.EmitterStuds` (170) and its lights beyond `LightStuds` (150),
  checked 4 times a second. In a play test: 27 emitters on at the village fire, 6 at the Market.
- `tools/build_publish.luau`, for the player place only:
  - small parts cast no shadow (314 parts);
  - meshes that are not skinned use Automatic detail (319);
  - streaming pauses only when the ground right around the character is missing (`MinimumRadiusPause` instead of
    `PauseOutsideLoadedArea`, which froze a running character).

These ship with the next publish.

**Early game** (`docs/ECONOMY.md`, `tools/balance/early_game_sim.luau`). Changes:
- the prices of levels 1-19 are halved;
- wounds heal in 30 s;
- a fight costs 2 energy and naps are twice as fast;
- camp 1 is easier (0.62).

Village level 5 now comes at 10 min (was 22), 10 at 30 min (was 75), 20 at 2.9 h (was 7.8). The fight cycle is 129 s instead
of 244 s.

## 2026-11-04 — cooks work a pan, trainees hit the dummy

The owner: a pan and a stove for the cooks, a dummy for the trainees. `client/WorkMoves` (client only, from what the server
publishes: Working, ClockKind, the village's Work slots), while the place's clock runs:
- cook: a frying pan built from parts like the rod and the hoe, steaming (Roblox's smoke picture); every `Cook.TossSeconds` the
  pan flicks and one of the dish's ingredients (their kit models, in turn) flies up, turns over and lands in it; motion
  `workCook`.
- trainee: every `Train.BeatSeconds` a windup, a lunge to the skin of the nearest dummy or punching bag and back, a mark in
  the style of the stat the place trains (FightFx, the battle art), every 4th blow heavy; the dummy rocks from its foot
  (client side, restored after). The archery target (and any target out of reach) is spat at with goo, aimed at the
  middle of its board. Motion `workTrain`.
Numbers in `Config.VillageClient.Cook` / `.Train`. Seen in a play test with the training ground at level 35, all three
places staffed: the dummy lunge 6.6 -> 2.1 studs and back each beat, the punching bag 8.3 -> 2.5 studs with the bag
rocking 8.6 degrees, the goo flying from the third place's slime to the archery board (`docs/work/cook-pan.jpg`,
`train-dummy.jpg`, `train-bag.jpg`, `train-archery.jpg`).

## 2026-11-04 — "Best" on the Teams sheet

The owner: a button that fills a team with the best slimes that can fight. `client/UiTeams`: "Best" (gold, beside Repeat) puts
the four strongest slimes that may join into the open tab's team: not at work, in a pair, a baby, a ghost or in another team;
those ready to march (awake, rested, unhurt) first, then by level, then HP. One `SetTeam` request; the server checks it as any
other. Seen in a play test on the phone frame: team 1 of three Lv 4 slimes became Lv 41, 41, 35, 35 (`docs/ui/kit/phone-teams-best.jpg`).

## 2026-11-04 — one frame per slime; every screen looked over for what is off

The owner: a frame inside a frame means nothing; drop one frame for each slime on every screen, and straighten anything off
centre, unbalanced or spilling out of its frame.
- Slime tiles (book, pickers, sell, teams), the old slime cards, team rows at the Dungeon gate and attack cards: the slime sits
  bare in its card; the tile's slime, level and stat line are stacked and centred.
- Book filters All / Free / Work / Baby were squeezed into circles with the word touching the edge: now pills wide enough.
- Sell sheet: tabs at the left as in the book, coins after them; the list takes the bottom room while no slime is picked.
  Teams: the empty "waiting" line no longer leaves a band above the list.
- Dish sale, Food panel and recipe rows: the kit's row plate instead of the old white boxes; "1" / "All" buttons are pills.
- Seen on the 844 x 350 phone frame (`docs/ui/kit/`): book, kitchen picker, sell, dish sale, Dungeon gate with a team, Teams,
  Food panel, recipes.

## 2026-11-04 — every screen in ChatGPT's painted UI kit; the slime page as in the concept

The owner: the UI in the game exactly like the one ChatGPT made, every other screen in the same style, and ask ChatGPT for any
piece that is missing. (`docs/UI.md`, "The UI kit".)
- ChatGPT drew the kit in three sheets (frames, buttons, ornaments) after the slime page concept; 28 pieces cut, 9-sliced and
  uploaded (`art/ui/kit/`, `Config.Ui.Kit`). The owner's ui-frame-gold and ui-frame-wood frames are retired.
- `UiKit` draws every modal, card, button, chip and bar with the kit, so the HUD chips, the book, Bag, Rewards, Smithy, Dungeon
  gate, Teams and every other screen changed together. A picked tile or row is tinted through `UiKit.setFill`.
- The slime page rebuilt piece by piece after the concept: hexagon portrait, name ribbon and Lv pill; slots with name plates;
  the pedestal and gold accents; the needs plate; a Feed button (dishes from the fridge) and an Equip button; the stats panel
  with its diamond, rows and green "+n" pills; the trait scroll.
- Seen in a MapWork play test on the 844 x 350 phone frame (`docs/ui/kit/`): slime page, Bag (and a picked tile), Smithy, Dungeon
  gate, Teams; Feed lowered Grilled Fish x2 → x1, Equip opened the Head list. Not done: the concept's warm glow behind the slime
  (needs a painted glow piece).

## 2026-11-04 — one Dungeon portal in the Market, a Bag, and the slime's page as an RPG sheet

The owner: Hand becomes Weapon and Tail becomes Charm; one portal for everyone in the Market, each player sent to their own
dungeon, a lock on it for a player who may not enter; the gate sheet without the two needs rows, only the drops as a plain list;
an inventory for each player, well sorted; and a slime page in the style of an RPG.
- Slot names: `Config.Smithy.SlotNames` (Weapon / Head / Charm) on every screen; the saved ids (hand, head, tail) stay.
- Portal: `Layout.marketPortal()` (`Config.Dungeon.Portal.Market`, back right of the square, the Blacksmith's mirror, facing the
  fountain), built once by `server/DungeonPortal`; entering still makes a private arena per player, leaving lands at the portal.
  The client puts a lock picture (`Config.Ui.Icons.lock`) over it and the prompt reads "Locked" (a tap says why) while
  `Dungeon.entryBlock` says no. Studio's screen capture never draws BillboardGuis, so the lock was checked by its state (shown at
  8 slimes / village 1, gone with 22 / village 15), not by a picture.
- Gate sheet: the needs row is gone; the drops are a two-column list (icon, name, amount) without frames.
- The Bag (`client/UiBag`, a round button beside the book's, once the Rewards are open): Materials as a grid of slots (empty ones
  faint, `Config.Ui.Bag.MaterialSlots`), Gear grouped Weapon / Head / Charm with the tier colour, "xN" and a badge for pieces a
  slime wears; a tap shows the item and what it makes or gives. Read-only.
- The slime's page (`client/UiSlimeSheet`, after a ChatGPT concept, `docs/ui/slime-sheet/concept.webp`): the slime on a
  pedestal with Weapon, Head and Charm slots round it, its needs under it, the four stats with the gear bonus in green, trait,
  Stop work. A slot opens a small picker (Take off, or a piece from the bag). The book takes the sheet's height on a wide screen
  (`UiKit.setModalHeight`). New icons by ChatGPT: lock, bag, the three empty slots.
- Seen in a MapWork play test (`docs/ui/slime-sheet/*.jpg`): the page, the picker, swapping a wooden sword for an iron one
  (+1 → +2 ATK, the wooden one back in the bag), both Bag tabs and the details strip; on the 844 x 350 phone frame both screens
  fit. Not done: the lock seen in a real client, the pedestal is plain parts of the frame (no art yet).

## 2026-11-04 — the Dungeon is for grown farms: 20 slimes and village level 15

The owner: a starter team losing is right, the Dungeon is not for new players; entering needs at least 20 slimes and a village
of a set level. The difficulty (`StatScale`, `WaveGrowth`) is unchanged.
- `Config.Dungeon.EnterMinSlimes = 20` (eggs not counted) and `EnterMinVillageLevel = 15`: 15 is the first village level whose
  population limit holds 20 slimes, so the two needs arrive together. `Dungeon.entryBlock` gives "FEW_SLIMES" or
  "VILLAGE_LEVEL"; the server checks it in `DungeonEnter` before anything else; a test covers both.
- The gate sheet shows the two needs at the top (slime picture "8/20", house picture "Lv 1/15", red while short) and keeps
  Enter off; the row is gone once both are met. The "Dungeon is open!" intro waits for the same.
- `tools/balance/dungeon_sim.luau` takes StatScale and WaveGrowth on its command line and has rows with wood and iron gear.
  Level 1, 40 seeds: starters reach wave 3.0, with wood gear 4.0, with iron gear 6.1, four level-20 slimes 8.3, level 40 clear.
- Seen in a MapWork play test (`docs/ui/dungeon/gate-needs.jpg`, `gate-met.jpg`): 8 slimes and village 1 → red needs, the server
  answers FEW_SLIMES; 22 slimes and village 15 → the row is gone and the server moves on to the team check.
- Phone frame: the game's screen squeezed to 844 x 350 points (UIScale 1, as on a phone) in the play test. The Smithy sheet
  (460 x 330) and the slime's page with its three gear slots (about 55 points each) fit and read
  (`docs/ui/smithy/phone-smithy.jpg`, `phone-gear.jpg`). A simulated frame, not a phone or Studio's device view.

## 2026-11-04 — fewer drops, gear crafted at the Blacksmith in the Market

The owner: few kinds of drops shared by the monsters (only the rate differs), a few rare things from the mini-boss and boss,
recipes for gear from them, and a Blacksmith in the Market. The design is `docs/SMITHY.md`.
- Drops: six materials (Hardwood, Iron Ore, Core Fragment, Monster Core, Boss Essence, Bramble Horn) plus coins and food, one
  `drops` list a monster in `Config.Dungeon.Maps`, each line rolled on its own, luck capped at 1 (`Dungeon.rollDrops`). Cloth and
  common parts no longer drop; held ones stay.
- Gear: 12 pieces in 3 slots (hand, head, tail) and 4 tiers, one recipe each (`Config.Smithy`, `shared/Gear`). Flat points in every
  fight (`Zombies.fighter`), never the slime's own stats. Save schema 10: `farm.gear` (the bag) and `slime.gear`; a sold or lost slime
  hands its gear back. Requests `SmithyCraft` (only near the stall, "FAR" otherwise), `GearEquip`, `GearUnequip`.
- Screens: the "Blacksmith" prompt opens the Smithy sheet (`client/UiSmithy`: tabs Hand/Head/Tail, have/need, Craft); the slime's
  page in the book has three gear slots (`client/UiGearSlots`). Icons by ChatGPT in the drop icons' style (`art/icons/gear_*.png`);
  `tools/chatgpt/prepare_icons.py` now keeps a violet gem that sits inside an outline.
- The stall: `tools/map/build_smithy.luau` after the owner's `blacksmith-01.png` (honey wood frame, blue and cream awning, crest
  board, stone furnace with fire, anvil, weapon rack, armour stand, water barrel, tools, blue banner), at `Config.Market.Smithy`
  facing the fountain; `build_market.luau` keeps it, paints its yard and lost the bush in front of it. No keeper slime: its spot
  is kept (`KeeperSpot`) for the owner.
- Seen in a MapWork play test: a dungeon run dropping by the new lists, the stall at the real camera, a craft (materials and coins
  taken once, "x1" in the bag), a second equip of the same piece refused, the slot on the slime's page with "+2 ATK"
  (`docs/ui/smithy/*.jpg`).

Not done or not known
- MapWork needs the owner's Ctrl+S for the stall; then `build_publish`.
- The "x1" moved 12 px in from the card's edge after the shot, not seen again. (Phone frame: see the entry above.)
- The Market is now about 96,000 triangles (the stall 13,000) against a 60,000 target.
- MapWork has no `MonsterKit`: its play test draws stand-ins for the monsters (Publish.rbxl has it).
- Starter slimes lose level 1 at wave 3: as the owner wants (see the entry above).

## 2026-11-04 — the dungeon's monsters are the owner's Egg Heist creatures

The owner: "Egg Heist already has many monster models; use them to save effort." The seven Sunny Meadow roles are now his Egg
Heist creatures, picked to fit a meadow and each role: Twigling (swarmer), Parrot (flying hunter), Bloom Sprite (ranged), Aurora Owl
(flying healer), Hedgehog (armoured), Mossback Gorilla (mini-boss, the gorilla with moss and blossoms) and Bramblehorn (boss, the
flower-frilled Triceratops). Names in `Config.Dungeon.Maps.meadow` follow the models; ids, stats and skills are unchanged.
`tools/kit/eggheist_models.luau` reads Egg Heist's `assets/Pets/*.rbxm` (read only) and writes `assets/MonsterKit.rbxm` (`kit`), or a
script that rebuilds them in an open Studio place from the owner's uploaded meshes (`studio`). They move by Egg Heist's own motion:
`shared/MotionKit`, `shared/Creature` and the seven `shared/Creatures/pet_*` modules are copied from Egg Heist, played by
`client/CreatureRig` (feet planted, wings beating, head looking about), on the same unseen slime body as before
(`Config.Dungeon.Looks`: `motion`, `height`, `hover`). `tools/map/sync_all.ps1` now syncs `src/shared/Creatures`. A spec checks that
every look's model is in the kit and its motion fits its bones and walks. Seen in a play test: all seven walking at the real camera,
a run in the arena with Parrots, Hedgehogs and Bloom Sprites fighting, no console errors (`docs/ui/dungeon/eggheist-*.jpg`). The
Blender builds stay in `art/models/monsters/` (a look with `pieces` still works). Not seen live: the mini-boss and the boss in a
run (seen walking in the lineup), a phone screen. The map's drop is still "Boar Tusk".

## 2026-11-04 — the Slime Dungeon's art: the Sunny Meadow arena and the seven monsters in 3D

The arena is built by the server from the kit after the owner's painting `battle.map.meadow.png` (`server/DungeonArena`, placed
by the pure, tested `shared/DungeonArenaPlan`, numbers in `Config.Dungeon.Arena`): stud grass, four dirt paths, rocks, flowers,
bushes, tree clumps in the corners, pines by the side paths, and a ring of woods behind that is NOT in the painting (it hides the
floor's edge; `BackdropCount` 0 removes it). About 330 parts. Shots: `docs/ui/dungeon/arena-meadow-*.jpg`.

The seven monsters were built in Blender from the owner's paintings by `tools/blender/monsters` (two rounds against the paintings,
`art/models/monsters/sheet.png`, `rounds.md`) as rigid pieces with their origins at the joints; the owner imported the FBX files
and they live in `assets/MonsterKit.rbxm` (ReplicatedStorage.MonsterKit; `tools/kit/export_monsters.luau` writes it from a saved
place). No animation is uploaded: `shared/MonsterMotion` turns each piece about its joint and `SlimeActor.dress` puts the pieces
on an unseen slime body, so the fight code is unchanged; joints and swings in `Config.Dungeon.Looks`. Seen in a play test: all
seven in the arena at the real camera, flyers hovering, a run with the models, no console errors (`docs/ui/dungeon/monsters-*.jpg`).
Weak still: Bramblehorn reads more ox than mossy boar, the bee flies level (the painting dives), the flyers' health bars may sit
low, the kit's flowers lack the painting's blue and white.

## 2026-11-04 — the Slime Dungeon (Sunny Meadow), first playable

The owner: an arena where monsters come in waves, more each wave, their level and strength rising. `docs/GAMEPLAY.md` §14.
A portal beside every village gate (Egg Heist's portal, rebuilt by the server from its published kit meshes, as the owner asked)
opens a sheet: pick teams and the level, Enter. A private arena per player; 10 waves of Sunny Meadow's 7 monsters (mini-boss on 5,
boss on 10); drops paid at each wave clear, the open wave lost on a defeat or a leave; Next Level / Replay / Leave at the end.
Saved: **schema 9** (`farm.dungeon.best`), so a publish must shut down old servers. Drop icons and the portal icon from ChatGPT
(`art/icons/dg_*.png`). Balance: the original's numbers beat four starters in wave 1, so `StatScale` 0.3 and a level is x1.6.

Proved in Studio play tests (`Publish.rbxl`): the portal at the gate (`docs/ui/dungeon-portal-gate.jpg`), the sheet with the drop
pictures, the HUD, slimes fighting, waves 1-2 cleared and paid (coins and carrots in the HUD), a defeat in wave 3 with the
Defeated card, Leave back in front of the portal, no console errors. Still stand-ins: the greybox arena and the monsters (zombie
bodies tinted by kind); next are the Sunny Meadow arena scene and the seven monster models from the owner's paintings. Not seen
live: a victory, Next Level, the mini-boss and boss skills, a phone screen.

## 2026-11-04 — new players start with eight slimes

The owner: the start is slow; begin with 8 slimes so a player can fight at once. `Config.Farm.StarterCount` is 8 (was 4): a full team of
four and four more for the fisher, the gardener and a pair (village level 1 holds 12). Only new farms; existing saves keep their slimes.
The test farm (`FarmKit.farm`) keeps the four slimes the specs were written for; a new spec checks that the tutorial's team step no longer
waits for a baby. Proved in a Studio play test of a fresh player: 8 slimes, 8/12 in the HUD, team 1 set to slimes 5-8 at the banner at
once, no game errors.

## 2026-11-04 — daily check-in, daily quests, online gifts and the slime Index

Retention features (`docs/GAMEPLAY.md` §13): a trophy button with a badge opens Daily (7-day check-in), Quests (3 a day, all done gives
luck) and Online (9 gifts for minutes played); coins scale with the cheapest next upgrade, luck is minutes of the x2 potion with a chip in
the top strip. The slime book has a second page, the Index of all 150 kinds (Secrets as shadows). Icons for the tabs and luck from ChatGPT
(`art/icons/`), the trophy and Index buttons are the owner's art. Two new intros. Saved in the farm: **schema 8**, so a publish must shut
down old servers; old saves start the rewards fresh. Lune tests in `tests/spec/rewards.luau` (383 pass), CHECK OK, TYPES OK.

Proved in a Studio play test (`Publish.rbxl`, shots in `docs/ui/rewards/`): the trophy hidden during the tutorial and shown after it with a
badge; Day 1 claimed (+160 coins, the tile Taken, the clock to midnight); three quests drawn; the 1-minute gift opened on its own and was
claimed (+100); the Index tabs with the found Navy and dark shadows; no errors from the new code in the console. Not seen live: quest
progress and its claim, the quest bonus, a real luck claim (the chip was shown by a local preview), a found Secret's golden shadow, the
two new intros (all covered by the Lune tests), and a real phone.

## 2026-11-03 — tutorial: the trail points the right way, breeding is quick while it runs

The owner: the arrows on the trail pointed the wrong way; speed up breeding during the tutorial. The trail is now a row of the gold
arrows each turned on the screen along the way (a Beam had laid the picture sideways); seen in a Studio shot pointing at the pond. While
the tutorial runs: courtship 10 s, hatching 10 s, growing up 30 s, and a pair goes courting before a nap or a meal
(`docs/GAMEPLAY.md` §12). Measured in Studio play tests: egg to hatch 16 s (was 68), hatch to adult 30 s with the baby growing from small
(was about 300), pair to egg 57-109 s (was 159), the rest being the parents' walk to the nest.

## 2026-11-03 — a step-by-step tutorial and feature intros

The owner: a detailed tutorial that walks a new player through the game and introduces the features. Now 14 steps (slime book, a fisher,
a gardener, the Food chip, a pair, the egg, the hatch, the Market, selling, home, the upgrade pads, a team, an attack, the win) and 12
one-time intros for later features (`docs/GAMEPLAY.md` §12). Each step points at the real thing and moves on only from real farm state
checked on the server; Skip at any time. Saved in the farm: **schema 7**, so a publish must shut down old servers; old saves count the
tutorial as done. Lune tests in `tests/spec/guide.luau`.

Proved in a Studio play test of a fresh player (`Publish.rbxl`): all 14 steps passed in order from real play (book and Food by clicks,
the egg laid at 159 s and hatched at 227 s, quick travel to the Market and home, the wait line until the baby grew up, the team, the
attack, 140 coins), then the "slime fell" intro with its arrow on the skull, closed by its button, and the Repeat intro after it; no game
errors in the console. Not seen: the world arrow and its trail in a picture (Studio captures show only the GUI), a real phone.

## 2026-11-03 — waving flags at the gate and the training ground

The owner: the team banner and the training ground's flag must be thin and fly softly like a real flag. Now both are one waving flag
(`tools/blender/flag.py` -> `art/models/flag/`, imported by the owner; meshes in `Config.Flag`): a wooden pole, a gold finial and a thin
two-sided cloth with the owner's sword art crossed, on a chain of 8 bones. The server puts it together from the meshes (`server/WavingFlag`,
the bones under the cloth so the skin follows them) and every client waves it (`client/FlagWave`: a ripple running to the free end, a slow
swing about the pole, a little droop; only near the camera, 30 updates a second). The kit's stiff BannerFlag is no longer used. Proved in a
Studio play test: both flags built, the cloth bends and moves, no errors. Not seen on a phone.

## 2026-11-03 — team banner at the gate, shorter prompt ranges, teams open with the village

The owner: the Teams prompt and the attack prompt worked from very far; put something at the gate for the line-ups; more teams as the village
levels up (4 at most). Now a team banner stands just inside the gate (Teams prompt within 10 studs), an attack needs 16 studs, and teams 2-4 open
at village levels 10, 20, 30 (`docs/GAMEPLAY.md` §8 "Teams"). Proved in a Studio play test: the banner beside the path, the prompt shown only near
it, team 2 refused (LOCKED) at village level 1, a line-up refused from 18 studs, an attack refused from 21 studs and sent from 12, only tab 1 shown at
level 1 and tabs 1-3 at level 20.

## 2026-11-03 — fights made dramatic (owner: "4 slimes attack in unison, no impact effects")

Done in three steps (`docs/GAMEPLAY.md` §8 "The fight"): each fighter on its own beat with a wind-up, a lunge, the owner's battle art on
impact, goo, knock-back, falls and a cheer; each moves about the field by its way of fighting (its strongest stat, a zombie's kind) and keeps
clear of the others; skills every few blows with their names called out. No camera effects (the owner). Balance re-run with `fight_sim`.

Proved in Studio play tests (`Publish.rbxl`): two fights won with no errors; the skill names showed once per cast (Goo Slam 7, Dash Strike 7,
Belly Bounce 5, Chomp 15); Goo Slam's cracks and rings, Belly Bounce's ring, Dash Strike's slashes and Jelly Guard's guard events all fired;
fighters stood apart. Not seen close up: Acid Rain (cast in play, not caught on camera) and Plague Burst (no plague zombie in the test groups), a real phone. No hit
sounds yet (the game has no sound assets).

## 2026-11-03 — before a publish, from the whole-repo audit: start here

Fixed: a publish now goes through `lune run tools/build_publish.luau`, which writes `assets/raw/Publish.rbxl` (the MapWork world, the repo's code, no labs or test stages, streaming on);
a Studio play test always uses the in-memory store (`Config.Save.StudioUsesRealStore`, off); a catch or garden chore whose slime is gone no longer jams its work place (`Stations.freeAbandoned`).

Proved by playing `Publish.rbxl` in Studio: the village, Market and slimes load with no errors; quick travel works; going to the far side of the valley dropped the client from about 9,000 parts to
2,630, and coming home brought back the village, prompts, bins and pad labels. Re-assigning a carrying fisher in play put the fish in the storehouse and the next catch came 59 s later;
a gardener re-assigned between chores carried on. Not measured: a real phone, 8 players at once, a real publish.

Also from the audit: a lost save lock now runs the leaving clean-up; a crashed server's lock frees in 300 s (refresh 60 s, 300 so a few minutes of DataStore trouble cannot steal a live lock); one
capacity formula and one pair check (`FarmState`); the request rules moved to `shared/VillageRequests` with a spec; team and health publishing runs 4 times a second; the dish toast shows what the server
paid; dead code removed. A reviewer read both audit commits: nothing blocking.

Proved in MapWork play tests: refusals with the right reasons; a slime sale paying 120; a march and fight with its reward; a cooked dish sold with 3 asked and 1 held, paying 1000; a real foreign lock
written to the store (a temporary patch, gone) lost the session, removed the village folder, freed the zombie group and kicked the player. Only read or tested, not seen: the crash lock time, the toast on screen.

Load test in `Publish.rbxl` with seven more village copies built by script (40,180 parts on the server, no slimes or other players): the client held 12,354 parts at home, 16,066 at the Market, 22,954 at
the valley's centre; the server kept 60 Hz. The frame rate means nothing here: 60, then a steady 14 wherever the character stood, probably Studio's window in the background.

What only the owner can do before players come: look on a real phone (F9 memory, frame rate), a test with friends, and say when to publish (`publish` skill).

## 2026-11-03 — the kitchen

Done and committed on `main`, not published (rules in `docs/GAMEPLAY.md` §5, numbers and measurements in `docs/ECONOMY.md`): a recipe per cook, 16 dishes with rarity
and timed buffs, Feed and When hungry, selling dishes at the Market, food rarity by pond and garden level, the coin vault, real upgrade prices (FreeUpgrades off),
13 new dish models in the kit, the buff badge and four effects from the owner's stat icons. Schema 6: a publish must shut down all old servers.

Proved in a MapWork play test: a cook takes the recipe's ingredients and makes the dish; a missing ingredient floats crossed out over the cook; a locked recipe is refused; the
recipe list and dish sheet open and act; Feed sets the buff; selling at the Market pays 1000; an upgrade pad charges 310 and raises the level; the vault-full number and toast
(with the coins set by script); badge and effects of all four stats at the player's camera (with epic buffs set by script); auto-eat (two slimes set to Grilled Fish got hungry on their
own, ate it and got the attack buff, with no script help). A reviewer read money, saves and remotes.

Only passed tests, not seen in play: dish buffs inside a real fight, fight income stopping at the vault, the save migration on a real old save, recipes above common.

Not seen or not known
- No screen has been seen on a phone frame: Claude cannot switch Studio's device view. To look at: the Market header (tight at 360 wide), recipe rows, the buff badge.
- Income from fights is still `price_curve`'s assumption, not a measured hour of play, so prices may need tuning. Dish prices are close together (1000 to 2000), to give
  level 1 some income.
- Golden Carp Feast and Starfruit Glazed Puffer came out peach rather than gold, and the puffer has small loose star slices: redo if the owner dislikes them.
- A rarer buff only means denser particles and a coloured badge frame; the effects use the owner's icons and have no glow.
- Graphics quality 0 (automatic) counts as full effects: no effects setting exists in the game yet.

## 2026-11-02 (late) — the Market built, the HUD made for phones: start here

Done and committed on `main`; nothing has been pushed to `origin/main` this stretch.
- The Market in MapWork, saved by the owner at 23:19 (`workspace.Map.Market`, `tools/map/build_market.luau`, `check_market.luau` ends MARKET OK; run the
  builder after `build_wild_slices`): slime buyer, VIP stall, a board of the 6 best slimes, fountain, surroundings, compared with `art/concept/market-1.jpg`
  in real shots and seen in play. The kit in the repo holds its new models; they did not change after the export.
- Quick travel: Market and Home buttons, the camera turns behind the character on arrival.
- HUD: coins, food, slimes and the village plate in one row on the line of Roblox's buttons (a ScreenGui with `TopbarSafeInsets`); the round buttons in a
  column on the right edge. The owner approved the compact size and asked for that line.
- Claude Code Game Studios installed, only the parts that fit (see `CLAUDE.md`).

Not done or not known
- The HUD's last move has not been seen on a phone frame, by Claude or (as far as reported) the owner.
- The Market is about 83,000 triangles by the builder's estimate against a target of 60,000; frame time on a cheap phone never measured. Cut first:
  `PinkDaisies`, `QtFern_1`, then walls.
- Still unlike the picture: grey flagstones (the tint does not take), thinner tree crowns. The Sell button at the buyer's has not been pressed in a test,
  and real DataStores for the board are untested.
- `rbxassetid://203785492` logs an asset error in play; it is in neither `src` nor the saved place, so probably the test player's avatar. `14025376080` ("Asset is not approved for the requester") is one particle texture of the owner's `CampFlame` pack, so that one emitter draws nothing in Studio; look at the campfire after a publish.
- VIP products and prices wait for the owner; none exist.

## 2026-11-02 — village bar done, economy researched

Playable in MapWork with one player: a village per player copied at their saved levels to the first free plot (`Plots`), 108 zombie groups shared
by the server in 9 slices (`docs/MAP.md` 1.4), teams set at the gate, orders given at a group, marches, wounds, repeat, a home notice, one sorted
slime list everywhere, revive within 15 minutes of play or a slime is lost for good, the shop, the rebuilt middle of the valley
(`tools/map/build_wild_slices.luau`).

Not done: Studio's multi-player test (nothing with two players has run); prices (upgrades still free; table in `docs/ECONOMY.md`); frame time on a
phone with the new map and roaming zombies. The owner saved MapWork on 2026-11-02 with all of this in it, and the kit in the repo matches that save.

## 2026-11-01 — ChatGPT's branch reviewed and partly redone: start here

Merged into `main` after a play test in MapWork: the upgrade reveal, the garden order, the population and hunger numbers, and the kitchen
rule. What was kept, redone, proved in play and still unchecked is in `docs/BUG_TRACKER.md`, "Claude's review of this branch".

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

## 2026-10-27 — the map and the UI come first (owner)

The owner asked to redesign the map and the UI before Phase 2: one valley for 8 players, home
plots and a trading area on the rim, a flat Wild Garden in the middle with monster slimes and
fights (also between players' slimes), and six upgradable areas a plot (fishing, garden, kitchen,
pantry, training, breeding), each level changing the look a little. Proposal: `docs/MAP.md`;
waiting on the owner's choices in its §4. The UI redesign follows the map.

## 2026-10-27 — map approved, greybox built

- The owner approved all four points of `docs/MAP.md`, and set the UI direction (`docs/UI.md`):
  the simplest possible screen; every upgrade and interaction is done on the objects in the world.
  The detailed UI design waits; the owner asked to build the map first.
- `src/shared/Layout.luau` (+ `Config.Map`, `tests/spec/layout.luau`): every position of the valley.
- `tools/map/build_terrain.luau` and `tools/map/build_greybox.luau`: run through Studio's MCP in a
  work place (`assets/raw/MapWork.rbxlx`, a copy of the built place, gitignored), they build the
  terrain (floor, hills, the four quarters, streams, lava rills, ring road, paths, ponds) and a
  greybox (hedged plots with every area blocked out, the Market stalls, the Heart, goo springs,
  trees, lighting). Pictures: `docs/map-greybox/`.
- Open: the map is built in a work place only. The plan is to move both builders into the game
  (a server `World` module that builds the valley from `Layout` at start), so the real place needs
  no hand-saved terrain. Lava in the Ember rills is hidden under the basalt (fix in the art pass).

## 2026-10-27 — concept art before 3D (owner)

The owner asked not to build 3D yet: first ChatGPT concept art of the home plot, "the best
possible visuals, but a simple and clean design". Prompts: `docs/art/chatgpt-home-plot.md`
(style lock + the whole plot + each area at levels 1/4/7/10), with the owner's reference art
copied to `art/chatgpt-refs/`. All 9 pictures were generated (2026-10-27) in the owner's ChatGPT chat
"Image placement suggestion" (prompts sent from the browser pane; the reference pictures were pasted
through the ChatGPT desktop app, as the pane cannot attach files). Picture 1 approved and saved as
`art/inbox/1-plot.png`; 2-9 wait for the owner to download them (the pane cannot download).
The owner saved 2-9 in the project root; they are now `art/concept/2-fishing.png` .. `9-home.png`
(picture 1 was not among them).

First 3D trial (owner's request): the level-1 breeding house from `art/concept/7-breeding-L1.png`.
Three tries in the MapWork place: `generate_procedural_model` from the picture failed (red error box);
two `generate_mesh` text prompts written from the picture both came out cute; the second (scalloped
pink roof, heart on top, beams, stone base, arched door, round window) is placed in Plot 5's breeding
spot. Side by side: `docs/map-greybox/compare-breeding-L1.png`. Close in shape and colours; missing
the dressing around it (bushes, flower pots, stepping stones), the heart emblem over the door, the
warm window, and a real slime model; the roof is a little lilac.

## 2026-10-27 — plot areas, built directly in Studio (owner's restart)

- Level-1 fishing pond (`docs/areas/fishing.md`, approved) and level-1 vegetable garden built in Plot 5 of the
  work place by `tools/map/build_fishing_l1.luau`, `build_garden_l1.luau`; dressed with the free Creator Store
  "Nature stylized Pack" by `dress_plot_nature.luau`; lit by `lighting_storybook.luau` (research in
  `.claude/skills/studio-build/RESEARCH.md`, "Stylized cozy look"). Pictures `docs/areas/*-v3.jpg`.
- Builders place from `Config.Map.GroundY` (terrain surface at y = 2).
- Research "Do this first" items not yet applied: stylized grass MaterialVariant, darker rims, cartoon water,
  shadow discs, reed sway, outlines on hero props, CC0 packs (KayKit, Quaternius crops, Kenney).

## 2026-10-27 — the plot as a small village (owner)

- All six areas of Plot 5 (pond, pantry, garden, kitchen, breeding pen, training ground) now face
  the plot's middle (`Layout.plotAreaFacing`, tested). `tools/map/build_village.luau` adds the stone
  plaza with a well, lamps and planters, paved paths to each area and the gate, a tall wooden fence
  round the plot with a towered gate and name board, and kit trees, bushes and flowers; it clears the
  greybox hedge, meadow house and hatchery nest. Pictures `docs/areas/village-*.jpg`.
- The pond now holds real terrain water (owner's request; `pond_water_l1.luau`), the painted flat
  water is gone. The boulder "SteppingStones" models were removed from the pond and garden entrances
  (owner: badly placed); the garden has a straight line of flat stepping stones instead.
- Pond, second pass (owner): terrain water fills whole 4-stud voxels, so its surface sits near y = 0,
  two studs under the floor; the bank now steps down to it in two sand steps (`stud_floor.luau`), so no
  grass shows. Water as clear as it goes (`WaterTransparency` 1). Lilies sit on the surface. Five fish
  (koi and little blue fish, `generate_mesh`, kept in the work place's `ServerStorage.FishKit`) swim
  loose loops just under the surface, moved on the client by `src/client/PondFish.client.luau` (tag
  "PondFish"); seen working in a Studio play test. Deeper than about 1 stud the water's tint hides them.
  Pictures `docs/areas/fishing-real-water.jpg`, `fishing-fish.jpg`.
- Campfire, third pass (owner): in the empty front-right cell, a round earth stud floor with a stone
  ring, a log teepee and real-looking fire, six small seats (the owner's log benches and kit stumps,
  turned to the fire), lantern posts and tall trees behind; a path from the plaza. Picture
  `docs/areas/campfire.jpg`. The owner's models are in the work place's `ServerStorage.OwnerKit`
  (inserted from the Mue_you inventory with MCP `insert_asset`, scripts removed).
- Fire "like real" for the campfire and the kitchen stove (one recipe, `addFire` in both builders):
  the glow, embers and heat of the "Realistic Fire VFX" pack in the owner's inventory
  (`OwnerKit.CampFlame`, scaled, bloom calmed, tongues kept low), two layers of licking flames with
  Roblox's flame texture, and a light that flickers (`src/client/FireFlicker.client.luau`, tag
  "Flicker"). The stove's chimney smokes a little. Pictures `campfire.jpg`, `kitchen-fire.jpg`.
- Trees: every code-built tree (the greybox's trunk-and-ball trees on the valley rim and in the Wild
  Garden, 140) swapped for the owner's own tree models by `replace_greybox_trees.luau`;
  `build_greybox.luau` places the same on a rebuild. The ring of big trees inside the plot fence is
  the owner's trees too, 22-28 studs tall. Nothing in a home plot sways (owner).
- Taken out (owner): the eggs in the nest and the incubator, the two round grain sacks at the
  pantry, the round seed sack in the garden.
- Crops in growth stages (owner: they grow like a real process, seedling to harvest): Carrot1..4 and
  Cabbage1..4 (seedling, young, growing, ripe; `generate_mesh`, in the work place's
  `ServerStorage.CropKit`; the carrot root is buried, only its shoulder shows). Each plant in a bed is
  a model tagged "Crop" with attributes Crop and Stage; the beds now show the stages side by side.
  Picture `garden-crop-stages.jpg`.
- For later (Phase 2), as the owner asked: the growing system sets a plant's Stage over time and
  swaps in the next stage's model, scaling it up smoothly from the last; the training ground's dummy,
  target and rack get motion when a slime trains there.
- Props remade low poly (owner: "as beautiful and detailed as the crops, everything"): 21 models from
  `generate_mesh` in the work place's `ServerStorage.PropKit` — Stove, KitchenCounter, FirewoodPile,
  StorageShed, CrateStack, WoodBarrel, Cottage, Incubator, BirdNest, WaterTrough, HayBale,
  FlowerPot, TrainingDummy, ArcheryTarget, WeaponRack, BannerFlag, FishBucket, WateringCan,
  StoneWell, Planter, VillageLamp. `tools/map/replace_props.luau` (after build_village) swaps each
  part-built prop group for its kit model, fitted to the group's place and height and facing the
  area's front; the work-spot, nest and incubator markers stay as invisible parts, lamps keep their
  light. generate_mesh hands meshes back turned by a random angle: each kit mesh is set square when
  it goes into the kit. Floors, paths, fences and the area signs stay in the stud look. Pictures
  `docs/areas/props-*.jpg`, `prop-kit.jpg`.
- Fences, gates and signs low poly too (owner): PalisadeFence (the plot's tall fence),
  PicketFence (garden), RanchFence (breeding pen, training ground), VillageGate (keeps the plot's name
  board as a SurfaceGui on the model's board), PenGate (heart arch), and six signposts with their
  icon painted on (SignFishing, SignGarden, SignKitchen, SignPantry, SignBreeding, SignTraining).
  `tools/map/replace_fences.luau` cuts each fence run into bays and stretches one section mesh per
  bay (a MeshPart sizes freely); gates and signs go through `replace_props.luau`.
- Owner fixes: `tools/map/tidy_plot.luau` (last step) moves every tree, bush and prop that reached
  past the plot fence back inside, smaller if needed, and lays a skirt of small bushes, rocks, ferns
  and tufts along the outside foot of the fence (gate kept clear). `stud_floor.luau` now cuts only
  the plot itself and raises a 16-stud ring of grass round it to the floor's height (measured 1.4 to
  2.6 against the floor's 2), so the plot sits level with the ground round it.
- Build order now: ... build_village, replace_props, replace_fences, stud_floor, pond_water_l1,
  tidy_plot. Pictures `docs/areas/fence-*.jpg`, `village-top.jpg`.
- The kit is saved in the repo (owner: never make it again): `assets/Kit/*.rbxm` (PropKit, CropKit,
  FishKit, OwnerKit, NatureKit, HomePlot), exported from the saved work place by
  `lune run tools/kit/export_kit.luau`, built by Rojo into `ServerStorage.Kit`; index with every
  asset id in `docs/kit/README.md`. After each Ctrl+S in Studio, export again.
- The green blob-shadow discs under bushes and rocks are gone (owner); no builder makes them now.
- Area upgrades, 50 levels each, press E at an area's entrance (owner, 2026-10-27): the fishing pond
  (`src/server/PondStages.luau`) and the garden, pantry, kitchen, breeding pen and training ground
  (`src/server/AreaStages.luau`), all run by `src/server/AreaUpgrade.server.luau`. Every area keeps
  its size; five parts that never go away (floor/frame, rails or a bench, lamps, a crate, planters
  and light strips); levels 1-5 add them, then each level moves one part up a material tier
  (rustic wood ... marble and gold). Free and not saved yet (Phase 2: coins, saved levels, owner
  only). `tools/map/sync_server.luau` copies the server code into the work place; play tests start
  on the plaza (`tools/map/dev_spawn.luau`). Pictures `docs/areas/upgrades/`, `fishing-ingame/`.
- Pantry upgrades redone (owner: the store house itself must grow, and what is added must belong
  to a store): `src/server/PantryStages.luau`. The kit shed is replaced by a part-built house so its
  materials and storeys can change. Five eras of ten levels: the era's first level grows the house
  (2nd storey at 11, loading canopy at 21, 3rd storey at 31, rooftop lantern tower at 41); levels
  2-5 of the era add or upgrade four store props (transport, containers, lifting, stock: wheelbarrow
  > hand cart > pallet jack > forklift > hover cart; barrel rack > crate wall > grain silo >
  shipping container > goo tank; ladder > pulley hoist > crane > conveyor > robot arm; sack pallet
  > shelf > metal rack > plastic crates > vault, 20 new PropKit models); levels 6-10 move walls,
  roof, doors and windows, frame and foundation, yard up one material tier (rustic wood, painted
  timber, brick, steel and glass, slime tech, marble and gold). The other four areas wait for the
  owner's review one by one (AreaStages is the stopgap). Pictures `docs/areas/upgrades/pantry-v2-*`.
- Garden and breeding pen redone the pantry's way (owner approved the garden, 2026-10-28):
  `src/server/GardenStages.luau` (tool shed, vine pergola, greenhouse with an open door, irrigation
  windmill; water, tools, compost and scarecrow props) and `src/server/BreedingStages.luau` (the
  cupcake cottage grows into CakeCottage2..5, a nest or incubator more every era up to four each with
  their markers; feed, egg care, comfort and warmth props; fence, floor, nest platforms, pad and gate
  arch climb the tiers). 44 new PropKit models; `tools/kit/intake.luau` takes generated models into
  the kit square and fitted. The incubators are part-built with a clear glass dome so the egg shows
  (owner, 2026-10-28); the owner approved the pen.
- Kitchen redone the same way (`src/server/KitchenStages.luau`, `docs/areas/kitchen.md`): roof,
  walls and bread oven, chimney and pot rack, vent lantern; ingredients, grill, water and dishes
  props (19 new PropKit models); the props stand against the walls facing in (owner, 2026-10-28).
- Training ground redone the same way (`src/server/TrainingStages.luau`, `docs/areas/training.md`):
  stands, punching bag and floodlights, canopy and scoreboard, trophy podium; strength, agility,
  recovery and gear props (22 new PropKit models); the owner approved the kitchen and the training
  ground (2026-10-28). All six areas now have their own stages; `AreaStages` only gives the labels
  and prompt spots.
- The village (tall fence, gate, plaza) upgrades too (`src/server/VillageStages.luau`,
  `docs/areas/village.md`): its level is the average of the areas' levels; the well grows into
  fountains, pillars, lanterns, banners, wing walls, guardians and a crest join the fence and gate,
  (24 new PropKit models). Redone at the owner's word the same day: fence, gate, lamps and paving
  change style every era, decorations come in groups (benches, lamps, stalls, gardens, planters);
  7 more PropKit models (era lamps and benches). Waiting for the owner's review.
- Detail review loop (the owner, 2026-10-28): each main building is rebuilt with more detail,
  self-reviewed, then reviewed by ChatGPT in Claude's own browser pane (skill `chatgpt-review`) and
  revised. Pantry done in 3 rounds (pictures `docs/areas/upgrades/review/pantry-r*`): a roof shape
  per level (gable shed, gambrel barn, brick gable, low seamed steel, corniced marble), loading doors
  that lead the front, loft doors and hoist, then a cargo hatch from steel, windows by function,
  sandstone detail and a real lantern tower on marble. Next: the garden, breeding pen, kitchen,
  training ground and dock the same way.
- `tools/map/sync_client.luau` copies the client scripts into the work place for play tests.
- `tools/map/sync_shared.luau` copies the repo's Config and Layout into the work place (it swaps in
  fresh ModuleScripts, since Studio caches what require returned).
- Build order in Studio: build_fishing_l1, build_garden_l1, dress_plot_nature, polish_plot,
  build_kitchen_l1, build_pantry_l1, build_breeding_l1, build_training_l1, build_village, stud_floor,
  pond_water_l1.
- The work place must be saved in Studio (Ctrl+S) to keep the build.

## 2026-10-30 — end of the day: start here

Read `docs/LESSONS-village.md`; skills `village-playtest` and `chatgpt-code-job` are the repeated steps. The owner will pass the code on to
ChatGPT next: `docs/briefs/HANDOVER-2026-10-30.md` lists the open items. Fixed last: the frozen screen (a glide gait with no hop numbers stopped the
render loop), training without a chosen stat, each pair courting at its own nest. The kit in the repo matches the place the owner saved at 3:38 PM.

## 2026-10-29..30 — the living village through the owner's play rounds (hand-over)

Done since the first play test (every item checked in MapWork play tests; agents' reports in the commit messages)
- UI kit from the owner's art (`UiKit`, slime book, HUD with one Food chip opening `UiFood`), work-position markers with a
  per-place F prompt and one-tap picker (Suggested = highest SPD), a slime assigned to work pops up at its place; the
  breeding sheet ("Pairs" prompt) optimistic and instant; no area Manage prompts.
- Movement: PathfindingService routes, ground snapping, solid bins, gaits from the owner's movement lab
  (`Config.Gaits`: walk = Big leaps, stroll only inside the breeding area, baby gaits, glide when tired/hungry/sad),
  seats (`SeatShape`: resting and sleeping slimes sit on benches, logs and stumps).
- Work: fishing with rods, line, bobber and tosses into the fish bin; the garden cycle on saved CropPlots; SPD sets
  work speed; progress clocks over workers, courting pairs and eggs; hauling for every trait (`ErrandUrgency`, loads).
- Breeding: 2 -> 4 pairs by level; an egg's clock starts when laid, half speed in a nest, a parent carries it to a free
  incubator; eggs one real size (`EggScale`).
- Food: 6 fish and 6 vegetables with rarities (`Config.Food.Kinds`), the player carries in the right hand,
  Deposit store at the storehouse sign.
- Emotes: short pop-ups; z's, hearts (one at a time) and dizzy stars as lasting effects, sized in the world.
- Village scale (`docs/VILLAGE_SCALE.md`): plot 160 -> 228, valley x1.39, paths kept at the owner's 6 studs, every area
  spread (breeding 42x38, pond x1.3, garden x1.4, kitchen and training x1.3, storehouse yard), probes green at levels
  1/21/41 (`tools/map/probe_paths|probe_pads|probe_seats|scan_zfight|scan_rocks`), backup of the old place at
  `assets/raw/MapWork-before-scale-2026-10-30.rbxlx`.

Open
- The owner presses Ctrl+S in MapWork after the last spread (kitchen, storehouse, training), then
  `lune run tools/kit/export_kit.luau`.
- The areas still look small in their bigger cells (lots of lawn); the owner judges in play.
- Phase D/E of the scale plan: the Market, Wild Garden art pass (an odd straight water line), a 20-slime play test.
- Art: the clock-face badge (ChatGPT prompt sent), icons for close/back/plus/energy/fun, Secret slime 3D art.
- Next game steps: the hatch reveal by rarity, the slime shop and plot hand-out for 8 players, recipes for the new food.

## 2026-10-29 — Phase 2 started: the living slime village (gameplay approved, `docs/GAMEPLAY.md`)

Done (code by Codex and ChatGPT from briefs in `docs/briefs/`, checked and merged by the orchestrator)
- Colours: the pair's colour set and pools (Duals n(n-1)/2, Secrets n(n+1)/2), the 9-row kind table, random = a base
  colour the parents lack, materials on plain babies; luck sources (new player, server, potion, VIP); save schema 3.
- Village rules: needs (fullness, energy, fun), traits, friends, food chain (boxes, storehouse, counter, fridge, dishes,
  cooked-food permission), work slots and reserves, training, saved area levels and upgrade costs, population by
  village level, breeding pairs with courtship, nests and incubators, `VillageSim` (online, 8 h offline), ghosts;
  save schema 4.
- Server: the slime brain (`Brain`), a village per player (dev plot 5), routes through the plaza, spots from the plot's
  markers, replicated slime and egg state, the `Village` remote, paid saved upgrades.
- Client: slimes drawn from their look with `SlimeActor`, hopping along the server's legs, action motions, carried food,
  eggs; Manage sheets (key F) and the HUD strip. Surface looks come ready made in `ClientKit.Looks`
  (`tools/kit/export_client_kit.luau`): a game script may not set SurfaceAppearance maps.
- Play tests in MapWork: `tools/map/sync_all.ps1 -StudioId <id>` copies the whole game code in. The player spawns at the
  emotion stage: move the character to the plaza (slimes far from the camera do not animate).

Open
- Play-tested (picture `docs/play/village-first-test.jpg`): fishing and the garden fill their boxes, slimes carry to
  the storehouse and kitchen, a pair courts and lays, the egg is carried to an incubator and hatches, the baby waits in
  the nursery. Seen to fix next: a courting pair should go into the breeding house together (one partner courted
  alone at the plaza); the courtship and nursery spots need real markers.
- Art: collection boxes, the level-1 fridge, dishes, the egg, Config.Ui.Icons (18 icons), Secret slime 3D art.
- The hatch reveal by rarity and the nursery (step 4), the slime shop and plot hand-out for 8 players (step 5).

## 2026-10-28 — the village and every area's upgrades: done (owner: "the village design is finished")

Done (all checked in Studio at every era, committed, the kit exported into `assets/Kit`)
- Every area went through the review loop (skill `area-review`, ChatGPT rounds in each area's own chat, then the
  owner's play-test notes): pantry, garden, breeding pen, kitchen, training ground, fishing pond. Each was approved by
  the owner.
- The village (`VillageStages`): the plaza grows a ring each era; four seating nooks facing the fountain; the picnic
  green (gazebo, laid table beside it), the community green (a stage with its audience), the market street under an
  arch; era planters spread along all the paths; every path paved like the avenue; small plants moved off paving.
- The fence and the main gate per era (`VillageWalls`): painted timber, brick with ivy and torches, steel and glass,
  marble; lanterns and torches built and centred on every post; no plot name sign any more.
- The area gates (`GateArch`, breeding, kitchen, training) with generated emblems; the incubator rebuilt in detail per
  tier (`BreedingStages`).
- The fountain (`VillageFountain`): one per era, moving water (beam curtains, jets, splashes, ripples, shimmer), the
  golden slime statue on the marble one.
- The base slime body (2026-10-28): Blender build `tools/blender/slime_body.py`, files in `art/models/slime_body/`
  (rigged `SlimeBody.fbx` + `SlimeBodyOutline.fbx` hull, overlay/roughness/normal maps, `rounds.md`). Front silhouette
  IoU 0.984 against `slime.base.navy.png` (the ceiling for a round body); 2,400 triangles; bones Root/Base/Top and
  Left/Right/Front/Back (Bone.Transform squash about the feet). (First import 89067624889078 is superseded by the
  re-import below.) The look (owner): nothing painted on - highlights and shading come
  from the light; colour = Colours.luau's swatch on a glossy SurfaceAppearance (roughness 0.10), the hull at x0.6;
  `Lighting.EnvironmentSpecularScale` 1 (was 0) so the gloss reflects the sky. The baked overlay map is unused.
  `tools/slime/showcase.luau` puts the 11 on a stage in MapWork (shot `art/models/slime_body/studio_lineup.jpg`).
- The 55 Dual skins (2026-10-29, `docs/DUALS.md`): one design per colour pair, made by `tools/skins/make_skins.py`
  on the body's new all-round UV; re-imported body ids SlimeBody 71117254607762, SlimeBodyOutline 99817746239640;
  skin image ids in `art/models/slime_body/skins/asset_ids.json`. All 66 stand on the MapWork stage
  (`tools/slime/showcase.luau`, run with `node tools/studio_mcp.js run`). Approved by the owner in play
  ("every design is very beautiful"); `DualDesigns.luau` holds the 55.
- Slime materials (2026-10-29, the owner's pick; stage `tools/slime/materials.luau` beside the slime stage): Gold,
  Silver as "Mirror" metals (Chrome cut: it looked like Silver) (metalness 1, roughness 0.03, the chrome reflection map
  `art/models/slime_body/skins/mirror_metal.png` id 138184721337623 tinted per metal; standard PBR read milky because
  Roblox reflects only a blurred sky), Ice and Jelly see-through, and 14 Roblox materials: Neon, Wood, Marble,
  CrackedLava, Brick, Granite, Mud, Fabric, Sand, Grass, Glass, ForceField, ClayRoofTiles, Leather. They are a rare
  hatch mutation (`docs/MATERIALS.md`, `src/shared/Materials.luau`, rolled in `Mutations`); the Duals are one design
  per pair (55). Logic and tests done (save schema 2); the client drawing, the Sell remote and the book UI come with
  Phase 2.
- Faces, emotions and jelly motion (2026-10-29, approved by the owner in play: "everything is very good"): the owner's
  9 faces cut into parts plus drawn pieces (`art/faces/`, `tools/faces/make_faces.py`, ids in `src/shared/FaceArt.luau`);
  24 emotions as data (`src/shared/Expressions.luau`); face plates that ride the deformed skin
  (`src/shared/SlimeShape.luau`); spring-based jelly body motion with crouch-launch-land-wobble hops
  (`src/shared/SlimeMotion.luau`; the owner lifted the 2D squash vetoes, `docs/DESIGN.md`); the client rig
  `src/client/SlimeFace.luau` and the API for the future brain `src/client/SlimeActor.luau` (`Actor.new(model, emotion)`,
  `:setEmotion`, `:lookAt`, `:playMotion`, `:hop`); numbers in `Config.Slime`. Weak spots the owner may raise: gaze
  slides the whole eye (pupils are painted in), the yawn mouth, sulk turns far, every spring number untuned, drawn
  pieces (lids, swirl, brows, blush, sweat, emote icons) could become art.
- Review stages in MapWork, all at y 300 around z -800, joined by walkways: emotions at x -75
  (`tools/slime/emotions.ps1`), the 66 slimes at x 0 (`tools/slime/showcase.luau`), materials at x 75
  (`tools/slime/materials.luau`). `tools/slime/spawn_at_stage.luau` makes every Play start in front of the emotion
  stage (delete `Workspace.SlimeEmotions.SpawnAtStage` to spawn at the map's spawn again).
- How it was done is packaged: skills `area-review`, `prop-craft` (new: the owner's quality bar and placing rules,
  the generate/check/export tools `tools/kit/intake|viewer|upright|export_kit|check_kit.luau`), `chatgpt-review`;
  lessons in `.claude/skills/studio-build/LESSONS.md`; shots in `docs/areas/upgrades/review/`.

Next (proposed to the owner 2026-10-29, he ended the session before choosing; ask him first)
- Phase 2, step 1 (recommended): the slimes live on the farm with a first brain - a player's slimes appear on their
  plot drawn with their colour / Dual skin / material and faces (`SlimeActor`), the server owns needs (hunger, energy,
  fun, social), personality per slime and positions; Sims-style "smart objects" (the pantry, beds, the pond,
  benches, flowers...) advertise actions; slimes wander, eat, sleep, play, greet and argue, with emotions and looks
  toward the player. The owner wants motion, interaction and emotion as rich as possible: this game is a life-SIM.
- Step 2: breeding, eggs and the hatch reveal (escalating by rarity: normal, Dual, Material, Secret).
- Step 3: the collection book (11 + 55 + 18 + 66), selling (helpers exist in `Mutations`), the HUD strip.
- Not measured yet: the frame time of the full plot at the last era on a phone (the fountain alone is ~200 particles/s;
  the brick wall's ivy is ~1,100 small parts).

Next (after the map and UI are agreed)
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
