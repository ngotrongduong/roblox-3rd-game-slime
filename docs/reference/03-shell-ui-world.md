# 03 — Player-facing shell: avatar, cosmetics, shops, UI, world map

Source: `reference/goo-lineage-web/` (unminified JS of "Goo Lineage V2", a 2D PixiJS + DOM game).
Modules read: avatar, avatarPanel, avatarCosmetics, customisePanel, traveller, travellerPanel, shopPanel,
craftingPanel, farmPanel, stationPicker, workstations, slimesPanel, slimeDetailsPanel, nestPanel, breedingPanel,
eggPanel, collectionPanel, achievementsPanel (+achievements), highscorePanel, upgradePanel (+upgrades),
panelKit, ui, loadingScreen, i18n, world, scene, map, mapLayout, mainMapLayout, assets/map/manifest,
mapSaves, mapEditor, slimeGrid, talkBubbles, devPanel, sound (+sound.manifest.json), assets.js,
emotions, economy, config, game.js (HUD, NPCs, input, farm loop), gameActions, battle/equipment, battle/recipes,
battle/loadoutPanel (headers), tutorial and eggReveal (headers only).

Conventions in this doc
- "px" = logical pixels on the fixed 1672 × 936 canvas (letterboxed to any screen). Origin is the top-left corner; +y is "down the screen" = toward the camera in the 2.5D view.
- "c" = coins. Times are real wall-clock time unless stated.
- Text in quotes is the exact on-screen string from the source.

---

## 1. Screen inventory at a glance

| # | Screen / panel | Opened from | Kind |
|---|---|---|---|
| 1 | Loading screen | game boot | full-screen DOM |
| 2 | HUD (avatar box, info rows, button grid, save status) | always on the farm | Pixi overlay |
| 3 | Egg tray (bottom-left cards) | appears when ≥1 egg exists | DOM strip |
| 4 | Egg details | tap an egg card | modal |
| 5 | Egg reveal (hatch celebration) | Hatch button / auto-hatch | full-screen modal (z30) |
| 6 | Banner toast | game events | bottom-center toast |
| 7 | Settings | HUD gear button | modal |
| 8 | Collection book | HUD button | modal, 3 tabs |
| 9 | Farm (workstations) + Station picker | HUD button | modal, 2 views |
| 10 | Breeding house | HUD button | modal |
| 11 | Highscores | HUD button | modal, 7 tabs |
| 12 | Slimes (inventory grid) | HUD button | modal |
| 13 | Slime details | tap slime on field / tap card in Slimes | modal |
| 14 | Siege team picker (battle) | HUD swords button | battle doc (not covered here) |
| 15 | Upgrades | HUD button | modal |
| 16 | Achievements | HUD trophy button | modal |
| 17 | Avatar ("Your Avatar") | tap the HUD avatar box, or tap your avatar on the field | modal |
| 18 | Customise Avatar Box | Avatar panel button | modal, 3 tabs |
| 19 | Equipment & inventory (Loadout) | Avatar panel button / Slime details "Equip" | modal (battle doc owns details) |
| 20 | Shop (merchant) | tap shopkeeper NPC | modal, 2 tabs |
| 21 | Smithy (crafting) | tap blacksmith NPC | modal, 3 tabs |
| 22 | Specialized Breeding (nest) | tap nest house (after unlock) | modal |
| 23 | Travelling Merchant stall | tap traveller or his cart while he is open | modal |
| 24 | Tutorial overlay | fresh farm / Settings "Replay tutorial" | non-blocking overlay (z19–21) |
| 25 | Dev panel + Map Editor | `?dev=1` + backquote key | developer only |

Global panel rules (game.js / panelKit.js)
- Panels are mutually exclusive: opening one closes every other (`openOnly`).
- Every modal = dim backdrop `rgba(20,30,16,.55)` + centered cream card; tapping the backdrop closes it; header has the title (20px bold) and a "✕ Close" button. Escape closes any open panel (else deselects the slime).
- While any panel is open, taps never reach the farm.
- Button kit (`mkBtn`): min height 40px, min width 64px, 3px wood-brown border, radius 10px, bold 14px; primary = orange-gold `#c98a3d` with cream text, secondary = cream `#fffdf4` with dark-brown text; hover brightens 12 %, press scales to 0.96; disabled = 45 % opacity.
- Tags (`mkTag`): small coloured pill, white bold 11px text.
- Countdown format: "42s", "4m 32s", "2h 05m".
- Portrait cell: 64×64 image on pale green `#e8f5d8`, 2px brown border; missing art = coloured blob with label; undiscovered = dark grey blob with "???".

---

## 2. HUD layout (ui.js `Hud`, game.js)

```
┌───────────────────────────────────────────────────────────────┐
│ ┌─────────┐                         [trophy?] ... [⚙ settings] │  row 1: up to 8 buttons, right→left
│ │ AVATAR  │                                         [trophy]   │  row 2: 9th button wraps under settings
│ │  BOX    │                                                    │
│ │ 288×288 │                                                    │
│ └─────────┘                                                    │
│ 🪙 1234                                                        │
│ 🍓 57 / 100                                                    │
│ 🟦 12 / 20                                                     │
│ Saved                                                          │
│                                                                │
│ [egg][egg][egg][egg]        (toast banner, 110px from bottom)  │
└───────────────────────────────────────────────────────────────┘
```

Left group (top-left, at 14,10)
- **Avatar box** 288×288 px: three layers — background art (clipped to the frame's inner opening; circular clip for round frames like "sun"), a LIVE second view of the avatar slime (idle breathing only, never hops, scale 1.2; wings/aura clipped to the opening), and the ornamental frame on top. Frame art is scaled by its measured OUTER rect so it fills the box; per-frame `outer`/`inner` fractions live in `AVATAR_FRAMES`. Tap → Avatar panel.
- **3 info rows** under the box (30px icon + bold 16px gold `#ffe9a8` text with dark-green stroke): coins (`mat-coins.png`), food "current / capacity" (`mat-food.png`), slimes "count / population limit" (icon = a slime body texture). Updated only on change.
- **Save status** text under the rows: "Saving…", "Saved", or an orange warning ("Save warning: …"). Localised (en/ja).
- Whole left group scales down so the box never exceeds 34 % of the shorter viewport side / 60 % of height (phones).

Right button grid (9 image buttons, user artwork `assets/ui.btn.<id>.png`, 115px art, 60×60 hit area, spaced 60px horizontally / 58px vertically, anchored 44px from the right edge, first row at y=40). Order (index 0 = rightmost):

| idx | id | Opens |
|---|---|---|
| 0 | settings | Settings (also shows save-recovery notes) |
| 1 | collection | Collection book |
| 2 | farm | Farm (workstations) |
| 3 | breeding | Breeding house |
| 4 | highscore | Highscores |
| 5 | slimes | Slimes list |
| 6 | siege | Siege team picker (battle; unlocks when any slime or the avatar reaches level 30) |
| 7 | upgrades | Upgrades |
| 8 | trophy | Achievements (wraps to row 2) |

Max 8 per row; narrow screens wrap at `floor((width-24)/60)` per row (min 3). If an icon fails to load the button draws three dots.

Other always-on elements
- **Egg tray** bottom-left (10,10 from corner), one 120px card per egg (see §4.4).
- **Banner toast** bottom-center 110px up: cream card, 3px border tinted by event colour, bold 18px, visible 2.6 s then fades (0.5 s). Only one at a time (latest wins).
- **Letterbox**: bars outside the 1672×936 canvas show the farm art stretched to cover, tinted `#8fa9b8` (dimmed blue).

Banner texts (exhaustive list from the shell)
- "🛒 The travelling merchant has set up his stall! (5 min)" (blue `#3a6b9a`)
- "Unlock to open" (tap locked nest house)
- "Sold {name} for {n} coins" (gold)
- "{name} revived!"
- "{Station} unlocked!"
- "🍓 +{n} food harvested" (every farm tick that produced food)
- "While away ({m} min[, cap reached]): +{n} food -{n} eaten {n} hungry {n} starving" (offline summary, only if ≥1 min)
- "Achievement unlocked! 🏆" (gold `#f0b429`, plays achievement jingle)
- "Tutorial complete — happy breeding!"
- Egg injections: "💉 Royal Jelly injected — the egg shimmers strangely…", "🌈 Prism Serum injected — colours swirl under the shell…", "💪 Vital Serum injected — the egg kicks with new strength…", plus error texts ("No Royal Jelly — defeat the World Boss to earn one.", "No serum left — the World Boss rarely drops them.", "This egg has already been injected.", "This egg already carries a mutation.", "This egg already drank a Vital Serum.", "That egg is gone.")

---

## 3. Loading screen (loadingScreen.js)

- Full-screen, background `assets/scene.loading.png` (cover). Title "Goo Lineage V2" (46px bold cream, dark-green shadow) placed above center.
- The real navy slime sprite (96px) bouncing: 1.1 s loop, rises 24px with squash/stretch (0.94/1.06 at apex, 1.06/0.94 at landing).
- Progress bar 320px (70 vw max), 16px tall, yellow→orange gradient (`#ffd75e`→`#f08a24`), tied to real asset loads: "Loading… n/total"; first status "Waking up the pasture…", final "Ready!". Fades out over 0.35 s.
- Rotating tip every 4 s at the bottom (italic): "Tip: happy slimes bounce higher." / "Tip: assign slimes to workstations for food." / "Tip: breeding two colours can reveal a rare dual." / "Tip: a favourite slime can never be sold." / "Tip: starving slimes nap instead of working."

---

## 4. Panels in detail

### 4.1 Settings (ui.js `SettingsPanel`, z10, width ≤460px)
- Title "Settings".
- Checkbox **Reduced motion** ("softer bounces, no flashing") — saved immediately.
- Checkbox **Sound effects** (on/off = master mute) — saved immediately.
- **Language**: buttons "English" / "日本語" (active one filled brown). Saved; HUD status + this panel re-render.
- "🌱 Replay tutorial" — closes and restarts the tour (replay mode).
- Text area (save JSON) + buttons: "⬆ Export" (fills area, copies to clipboard), "⬇ Import" (validates, shows "Ready to import N slime(s)." + repair notes, then reveals "Confirm import"), "Reset farm" (reveals a box: type `RESET` to enable "Confirm reset"; "Cancel"), "Close".
- Feedback line (green ok / red warning). On boot, save-repair warnings appear here.
- Roblox note: export/import/reset-by-typing are web-save tools; on Roblox use DataStore and drop export/import (keep a guarded "Reset farm").

### 4.2 Collection book (collectionPanel.js, width ≤760px)
- Tabs: "Base Colours", "Dual Colours", "Secret Slimes".
- Header: "X / Y discovered (P%)".
- 5-per-row grid of cells: portrait (or "???" when an undiscovered secret), name, optional detail line, then "date · ×hatchCount" or "not discovered". Undiscovered cells at 75 % opacity.

### 4.3 Farm (farmPanel.js + stationPicker.js, width ≤860px)
Grid view (title "Farm")
- Header: "Food: X / Cap" + orange bar.
- Responsive grid (min 300px columns) of 4 **station cards**, each: the full workstation artwork in a fixed 6:5 box (never cropped), name chip top-left, worker slimes drawn ON the art at fixed "spots" (10.5 % of art width, bobbing `gooWork` squash animation 1.6 s, staggered 0.45 s) with their live emotion face, and occasional **talk bubbles**. Footer row (56px): blue progress bar + "{cycle}s → {yield} food".
- Locked card: greyscale art, big 🔒, footer "Unlock for 🪙 {cost}" + green "Unlock" button; only the NEXT station in order can be bought ("Unlock the {name} first"); shows "— you have {coins}" if short.
- Hover (desktop) highlights orange; tapping an unlocked card opens the picker.

Stations (workstations.js)

| Station | Unlock cost | Base cycle | Base yield | Max workers | Worker spots on art (x,y fraction) |
|---|---|---|---|---|---|
| Berry Bush | free (start) | 120 s | 2 food | 3 | (0.26,0.75) stool, (0.13,0.70) left rock, (0.85,0.85) right rock |
| Farm Plot | 1,000c | 240 s | 4 | 3 | (0.68,0.56) stall table, (0.70,0.84) big rock, (0.38,0.66) crop rows |
| Fishing Pond | 5,000c | 360 s | 6 | 3 | (0.57,0.37) stool, (0.59,0.53) dock post, (0.75,0.88) rock |
| Cooking Station | 10,000c | 180 s | 3 | 3 | (0.51,0.81) stool, (0.615,0.85) 2nd stool, (0.43,0.69) by oven |

Crew math: fastest active (non-starving) worker sets cycle = base / (1 + speedBonus), speedBonus = min((SPD−1)×0.05, 3), min 5 s; every active worker adds floor(baseYield × (1+bonus)). Starving workers don't work.

Picker view (title "Farm — {Station}")
- "← Back"; header with 72×56 station thumbnail, "crew n/3", "base Ns → N food", current workers each with a "Remove" button.
- Search box "Search name…", "Sort: …" select (newest, level, attack, defence, speed, hp, colour, rarity, hunger), "Show: …" filter (all, available, idle, working, hungry, starving, favourite, base, dual, secret).
- Rows (44px portrait): ★ + name + Dual/Secret tag; "Lv · ATK DEF SPD HP"; hunger bar (green/orange/red) + state + current job or "idle"; green "Production: Ns → N food" (per that slime's speed). Unavailable rows greyed with red reason ("Already working at X", "Already assigned here."…). Available first.
- Tap an available slime: assigns and returns to grid. If the crew is full: inline orange bar "Crew is full — who does {name} replace?" with "Replace {old}" buttons + "Cancel".

Talk bubbles (talkBubbles.js): first bubble 2–7 s after showing; bubble shows 2.4–3.8 s, then 5–14 s silence. 8 % pure emote (♪ ❤ ! … ★), 64 % job-themed line, rest general banter. With ≥2 crew, 10 % chance of an argument: opener (speaker face = angry) then a crewmate retorts 1.4–2.2 s later (face = dare). Line pools:
- Fishing: "Here fishy fishy…", "A bass! A big one!", "Is that a trout?", "My bobber moved!", "Carp again…", "A golden koi?! …no.", "Worms are friends.", "Biggest catch today, I swear.", "Splash! …got away.", "Minnows are cute too."
- Farm plot: "Carrots coming up!", "These cabbages tho", "Water the pumpkins!", "Weed patrol!", "Tomatoes looking juicy", "Sprouts! Sprouts everywhere!", "Soil smells nice.", "One more row…", "Beet it, weeds.", "Big pumpkin energy."
- Berry bush: "Sweet blueberries!", "A ladybug! Hi!", "Raspberries today.", "These leaves tickle.", "Berry juice everywhere…", "Watch the thorns!", "A caterpillar friend!", "Strawberries are red-y.", "Basket almost full!", "Shiny beetle over there."
- Cooking: "Soup's on soon!", "More pepper!", "Smells AMAZING.", "Stir, stir, stir…", "Bread's rising!", "Careful, hot oven!", "A pinch of salt.", "Chop chop chop!", "Secret ingredient: love.", "Is it done yet?"
- General: "Nice weather!", "After this? Nap.", "I'm starving…", "Look at us go!", "Best crew ever.", "Snack break soon?", "Wiggle wiggle.", "This is fun!"
- Arguments: "Hey, that's MY spot!"/"Was first. Mine now."; "You're doing it wrong!"/"Am NOT!"; "Stop humming!"/"Make me. ♪"; "You ate my snack!"/"…no proof."

### 4.4 Egg tray + Egg details (eggPanel.js)
- Tray: fixed bottom-left, one card per egg (max 4 eggs): coloured egg art `assets/egg.<colour>.png` (navy uses blue), seconds left or "Ready!", green progress bar, "🔍 details" caption, or an orange "Hatch" button when ready. Badges "✨ injected" / "💪 boosted". Ready eggs also auto-hatch for everyone (500 ms tick, paused during battle and tutorial).
- Egg Details modal (z14, ≤440px): egg art + "hatches in Ns" / "Ready to hatch!"; Parents cards (colour dot, name, ⚔🛡👟❤ stats; departed parent → "has left the farm — its legacy lives in this egg."); "Possible outcomes": stat ranges between the parents, "📈 10% chance one stat improves beyond the stronger parent." (or Vital Serum guarantee line), "🎨 Dual colour: 5%/not possible for this pair", "🌟 Secret slime: 1%/no known recipe for this pair". Inject section (World Boss loot): "🌈 Prism Serum (n)" 10× mutation odds (50 % dual, 10 % secret), "💉 Royal Jelly (n)" guaranteed dual, 30 % secret, "💪 Vital Serum (n)" guaranteed random stat boost; or the hint "The World Boss rarely drops injection serums — bring a big squad."

### 4.5 Breeding house (breedingPanel.js, ≤760px)
- Two dashed "Parent A" / "Parent B" slots (portrait, name, colour, level, stats, "ready to breed"/"resting — ready in Ns").
- "Confirm breed" button right under the picks + red reason text: "Pick two different slimes.", "A slime cannot breed with itself.", "One parent is still resting.", "A parent is still growing up.", "The farm is full — no room for a baby.", "The nest is full.".
- Hint "Tap two slimes below to choose parents." + shared slime grid (5 per row, Sort select) showing only breedable slimes (not fallen, not working, not babies, cooldown over). Tapping a third slime drops the oldest pick.
- Footer: "Eggs n/4 · Farm used/limit", preview text for the pair, and while beginner luck is active: "🍀 Beginner's luck ×N — rare colours and stat bonuses are far more likely (M min left)".

### 4.6 Highscores (highscorePanel.js, ≤520px)
- Tabs: "Slime level", "Slimes bred", "Boss time", "Strongest", "Toughest", "Fastest", "Most HP".
- Slime level tab: platform leaderboard (top 10, refresh every 5 s while open). Submits the player's best slime level once per open. Rows: 🥇🥈🥉/#n, platform avatar (your row shows your slime avatar), name "(you)", "Lv N". Guests: "Sign in to appear on the board" button. Then "⭐ Your best slime" row.
- Other tabs are LOCAL farm records only: total eggs bred, fastest World Boss kill (m:ss), and the farm's best ATK / DEF / SPD / HP slime.
- Offline/unavailable fallback text: "The board is unavailable right now — your farm is fine, only the online ranking can't load."
- Roblox: use OrderedDataStore leaderboards (could rank every tab globally, not just level).

### 4.7 Slimes list (slimesPanel.js, ≤720px)
- Header: "N/limit slimes · E/4 eggs" (+ red tag "Farm full — breeding disabled") and a Sort select.
- 5-per-row cards: portrait, ★name, "Lv · A/D/S/HP", colour/Dual/Secret tag + blue "Baby" tag, "Grows up in …" (blue), "Breeding rest: …" (orange) or "Ready to breed" (green), hunger state + "· working". Countdowns tick every second. Tap → Slime details.

### 4.8 Slime details (slimeDetailsPanel.js)
- Portrait; ★Name (18px); colour tag + Dual/Secret tag; mutation name; Level; "ATK · DEF · SPD · HP"; "Hunger: n/100 (state)"; Job; Breeding ready/ready in Ns; "Sell value: N coins".
- Name input (max 24 chars; validation 1–16 chars of letters/digits/space/'/-) + "Rename".
- "☆ Favourite"/"★ Unfavourite"; "Equip" (opens the loadout screen for this slime); hidden "⚔ Siege"; "Sell Nc" (dual/secret need a second tap: first label "Sell (Nc)"). Disabled with reason: "Favourites cannot be sold.", "Remove it from its workstation first.", "The farm always keeps at least 2 slimes.".
- Fallen slimes: green "✚ Revive (N food)" + "👻 Fallen — feed a Revival Meal to bring this slime back."
- Sell value = floor(base × (1 + level × 0.05)); base 10 (normal) / 100 (dual) / 1000 (secret).

### 4.9 Upgrades (upgradePanel.js)
"Spend coins to improve the farm." Rows: name + "Lv n", description, green "current → next" effect, price button ("Nc", disabled grey when unaffordable, "MAX").
Price curve `rampCost(lv, max)` = round10(100 × 200^(lv/(max−1))): first level 100c, last level 20,000c, geometric between.

| Track | Effect per level | Max lv | Sample prices |
|---|---|---|---|
| Food Storage | +100 food capacity (base 100) | 20 | 100, 130, … 400 (lv5), 1630 (lv10), 6560 (lv15), 20000 |
| Faster Incubation | −5 s incubation (base 60 s → 35 s) | 5 | 100, 380, 1410, 5320, 20000 |
| Quicker Breeding | breed cooldown ×0.95 (max −64 %) | 20 | as Food Storage |
| Faster Growth | grow-up time ×0.95 (max −64 %) | 20 | as Food Storage |
| More Slime Slots | +5 slots (base 20 → 220) | 40 | 100 … 1510 (lv20) … 20000 |
| Specialized Breeding | one-time unlock of the nest house | 1 | **9c** (left at a testing value in the source — rebalance) |

(Auto-hatch was retired from the shop; ready eggs hatch for everyone.)

### 4.10 Achievements (achievementsPanel.js, ≤680px)
"Unlocked X / 40 achievement tiers". 8 cards, each: big emoji icon, name, unit, current value (formatted 10k / 1.2M), "next: N" or "all tiers done!", green progress bar, 5 tier chips I–V (🏆 gold when hit, 🔒 grey otherwise).

| Icon | Name | Unit | Tier thresholds |
|---|---|---|---|
| 💰 | Fortune Farmer | coins earned | 100 / 1k / 10k / 100k / 1M |
| 🥚 | Master Breeder | slimes hatched | 5 / 15 / 50 / 200 / 500 |
| ⭐ | Star Prodigy | best slime level | 10 / 25 / 50 / 100 / 250 |
| 🍓 | Great Harvest | food farmed | 100 / 1k / 10k / 100k / 1M |
| 📅 | Loyal Farmer | days playing | 1 / 3 / 7 / 30 / 100 |
| ⚔️ | Siege Slayer | mobs defeated | 10 / 100 / 1k / 10k / 50k |
| 👑 | Boss Breaker | bosses defeated | 1 / 5 / 20 / 50 / 100 |
| ✨ | Secret Seeker | secret slimes found | 1 / 5 / 15 / 30 / all secrets |

No rewards are attached; a watcher (~1 Hz) shows the banner + jingle whenever the total tier count rises.

### 4.11 Specialized Breeding nest (nestPanel.js)
- "Specialize a nest to auto-breed toward one stat."
- Locked state: "🔒 Locked — Buy the Specialized Breeding upgrade to unlock this nest."
- Unlocked: specialty buttons "★ Highest Level", "⚔ Highest ATK", "🛡 Highest DEF", "❤ Highest HP", "⚡ Highest SPD" (choosing one also turns auto-breeding on); toggle "Auto Breeding: ON/OFF"; line "Lineage: N slimes · breeding toward X" or "manual".
- On the field: when the nest picks a pair, both parents hop (double speed) to the nest-house door spots (235,640)/(307,640), linger 8 s with loved faces, go inside, and only then the egg starts incubating.

### 4.12 Shop (shopPanel.js) — the merchant at the shop stall
- Title "🛍 Shop", tabs SELL (default) / BUY.
- SELL: "Tap slimes to mark them for sale. N selected → Tc"; shared slime grid filtered to sellable slimes (not favourite, not working, keeps last 2), each card shows its value in coins; multi-select; button "Sell N for Tc" → banner per slime; feedback "Sold!" or "N could not be sold." Empty text: "No slimes available to sell (favourites, workers, and your last two are protected)."
- BUY: placeholder catalogue, all buttons disabled, note "Equipment shop coming soon — items are placeholders.":

| Item | Description | Price |
|---|---|---|
| Berry Basket | Holds more food. | 150c |
| Lucky Clover | A little extra luck. | 300c |
| Sturdy Boots | For long pasture walks. | 500c |
| Golden Bell | A chime the slimes love. | 800c |

So in the shipped game the only coin sinks are: upgrades, station unlocks, smithy coin costs, and the travelling merchant.

### 4.13 Smithy (craftingPanel.js — UI side; recipe data belongs to the battle/economy doc)
- Title "🔨 Smithy" (opened by tapping the blacksmith NPC).
- Header bar: coins + counts with icons for 13 materials (wood, cloth, ore, common_part, rare_part, boar_tusk, glow_spore, ember_scale, frost_crystal, monster_core, boss_essence, crown_shard, umbral_shard) + hint "Materials drop from siege battles."
- Tabs "🗡 Hand", "🎩 Head", "🎀 Tail" (avatar-only recipes for back/wings/aura exist in data — see §5.4; the UI tabs only list these three slots, so in the source those six recipes are not reachable from the Smithy tabs).
- Left: grouped 64px icon grid. Hand groups by family: "⚔️ Swords", "🏹 Bows", "✨ Staves", "🛡️ Shields", "🔮 Focuses", "🧪 Kits"; Head/Tail by tier: "🪵 Wooden", "🟤 Bronze", "⚙️ Iron", "✨ Enchanted", "👑 Mythic". Cell border = rarity colour; Epic/Mythic glow; unaffordable cells at 60 % opacity; selected cell gets an orange outline.
- Right detail card (230px): icon, name, rarity tag (+ twinkling ✦ sparkles for Epic/Mythic), description, green stat line ("+N ATK · +N DEF …" or "Cosmetic — no stats"), "Materials" list with icon, name, "have / need" (red when short), coin line, button "Craft" / "Missing materials" / "Not enough coins".
- Success: "Crafted {name}! It's in the inventory — equip it from a slime's Loadout." Errors: "Not enough materials.", "Not enough coins.", "This blueprint is still locked.".

### 4.14 Avatar panel ("Your Avatar", avatarPanel.js, ≤640px)
- Left: 140px portrait card, name + orange "Rank N" tag, rank progress bar, "x / 50 hatches to next rank".
- Right "Stats" box: "N points to spend"; rows Attack / Defence / Speed / HP: base value + green "+bonus" from equipment; "+1" (HP: "+10") button, plus "×10" when ≥10 points; footnote "Every 50 slimes hatched = 1 rank = 5 points. Green = from equipment."
- Buttons "🎒 Equipment & inventory" (loadout screen for the avatar) and "🖼 Customise box".

### 4.15 Customise Avatar Box (customisePanel.js, ≤640px)
- Tabs "🟢 Slime body", "🖼 Frame", "🌄 Background". Selecting applies immediately (HUD box and field avatar update).
- Body tab: every colour / dual / secret design the player has discovered (navy always). Hint "Any colour or design you have discovered on the farm."
- Frame/Background tabs: all 14 entries; not-owned ones greyed with 🔒 and tooltip "— sold by the travelling merchant". Hint "Free defaults plus pieces bought from the travelling merchant (🔒 = not owned yet; he visits every 15 min)."
- Cells 84×100 with 68px art, label, green ✓ on the selected one.

### 4.16 Travelling Merchant stall (travellerPanel.js, ≤680px) — see §6 for rules
- Title "🛒 Travelling Merchant"; quote "Eight treasures today, different ones next time — for your avatar only."; red clock "Leaves in N min" (ticks every second; panel auto-closes when he leaves: "Packing up…").
- "Your coins: 🪙 N" + result message ("Bought! Equip it from your avatar menu." or the reason: "Not in stock this visit.", "The merchant is not trading right now.", "You already own this.", "Not enough coins.").
- 8 cards: 64px art, name, kind tag (Frame brown / Background blue / Wings / Aura purple), rarity tag (Rare gold / Uncommon green / none for common), blurb, price button "🪙 N" (orange when affordable, pale when not, "Owned" grey).

### 4.17 Equipment & inventory (battle/loadoutPanel.js — summary only)
Diablo-style paper doll left, icon inventory right grouped: Swords, Shields, Bows, Arcane Foci, Healing Staves, Alchemy Kits, Hats & Helms, Tail Charms, and avatar-only Backpacks / Wings / Auras. Tap = details card with action (touch two-tap flow), hover tooltip with before→after stats on desktop. Panel never closes on selection. Full rules in the battle/equipment doc.

### 4.18 Dev features (devPanel.js, mapEditor.js, game.js) — developer only, never for players
- Enabled only with `?dev=1`; toggle with the backquote key.
- Dev panel: "⚔ Slime Siege (battle shell)" shortcut; "🛠 Open Map Editor"; selected-slime genetics readout (alleles, dominance, phenotype, mutation, discoveries); inheritance sampler ("Sample ×8", seeded, no baby created); mutation tester (colour pair → enabled dual/secret recipes, "Sim ×20"); forced breed (normal/dual/secret egg); emotion face gallery; map asset gallery.
- With the dev panel open: `H` makes all eggs hatch in 2 s; `C` toggles the collision/anchor/path overlay.
- Map Editor (purpose): in-game WYSIWYG layout tool — drag assets from a palette onto the meadow, move/scale/rotate/lock, layer (ground / y-sorted / foreground), collision on/off, undo/redo, test-walk mode, debounced draft autosave, publish (validated, versioned, previous version backed up). `mapSaves.js` stores draft/published/backup layouts on the platform's manual save-slot channel, separate from the farm save. The author's export is baked in as `mainMapLayout.js` (map version 10), which every player loads.
- Probe helpers `__goo.*`, traveller clock offset for forcing a visit.

---

## 5. Avatar: ranks, slots, cosmetics (avatar.js, avatarCosmetics.js)

### 5.1 What the avatar is
- A player-controlled slime with id `avatar`, default name "You", default look navy, spawns at (836, 580) (50 % width, 62 % height). It is NOT a farm slime: never eats, breeds, works, is sold, or counts toward population. It uses the same body/face art, hop animation and damage rules, and can join battles.
- Look: any discovered base colour, dual or secret design (body boost ×1.2 for secret bodies applies).
- Position is saved on every hop landing.

### 5.2 Ranks and stats
- Rank = 1 + floor(total slimes ever hatched / **50**).
- Each rank above 1 grants **5** stat points. Spend on ATK/DEF/SPD (+1) or HP (+10). Base stats 1/1/1/10. Caps like every slime: ATK/DEF/SPD 99, HP 9990.
- Level shown elsewhere uses the shared `calculateLevel(stats)` formula so gear comparisons match slimes.
- (Old code comments say "2 points / 10 hatches" — the constants above are the live values.)

### 5.3 Slots
Six slots: `hand`, `head`, `tail` (shared with slimes) + avatar-only `back` (stat backpack), `wings` and `aura` (pure cosmetics, no stats). Auto-equip never touches the avatar.

Render rules (farm): back sprite at 0.62 × body width, offset (−0.4, −0.5) × bw; wings = two hinged halves flapping (span 1.92 × bw, centred 0.38 × bw above the feet), with per-wing particle FX (glow + themed motes); aura = either a "fancy" layered effect (15 archetypes) or a plain additive glow 2.4 × bw that pulses (±8 %, 2.2 rad/s) and rotates slowly. Auras are grounded on the shadow (do not bounce with the body). Every cosmetic fades + scales in over 0.3 s when equipped. Farm sizes: hand item 0.6 × body, hat 0.9 × body.

### 5.4 Avatar-only items and how to get them

| Item id | Name | Slot | Rarity (tier) | Stats | Source |
|---|---|---|---|---|---|
| back-satchel | Leather Satchel | back | Uncommon (bronze) | +20 HP, +1 DEF | craft: 5 cloth, 2 wood, 25c |
| back-crystal | Crystal Backpack | back | Epic (enchanted) | +2 ATK, +1 SPD, +30 HP | craft: 5 ore, 6 frost_crystal, 10 rare_part, 1 monster_core, 150c |
| wings-fairy | Fairy Wings | wings | Rare (iron) | — | craft (6 cloth, 4 glow_spore, 2 common_part, 60c) or merchant 2,500c |
| wings-ember | Ember Wings | wings | Epic | — | craft (6 cloth, 8 ember_scale, 10 rare_part, 1 monster_core, 150c) or merchant 7,000c |
| aura-sun | Sunlit Aura | aura | Rare | — | craft (4 ore, 3 ember_scale, 2 common_part, 60c) or merchant 2,000c |
| aura-void | Void Aura | aura | Mythic | — | craft (3 umbral_shard, 1 boss_essence, 10 rare_part, 100c) or merchant 10,000c |
| wings-sun / void / starlight / blizzard / aurora / blossom / hellfire / nightsky / rain / autumn / firefly / coderain / thunder / electric / butterfly | (see §6.3) | wings | Mythic | — | merchant only |
| aura-starlight, aura-blizzard | Starlight Orbit, Blizzard Veil | aura | Epic | — | merchant only |
| aura-blossom | Blossom Drift | aura | Rare | — | merchant only |
| aura-nightsky / rain / autumn / firefly / coderain / thunder / electric / butterfly / aurora / hellfire / blaze | (see §6.3) | aura | Mythic | — | merchant only |

Rarity presentation (UI only — the user vetoed in-world rarity glows): Common grey `#8f97a0`, Uncommon green `#3a9b3a`, Rare blue `#2f7fd8`, Epic purple `#8a4fd0` (glow), Mythic orange `#f08a24` (glow).

### 5.5 Fancy aura archetypes (fancyAura.js — VFX detail for the VFX doc)
radiant (sun, void: rays + halo + motes), orbit (starlight comets on tilted rings), fall (blossom petals, blizzard flakes), veil (aurora curtains), nightsky (twinkles + shooting star), rain (private cloud + streaks + splash rings), leaves (autumn swirl → golden sparks), fireflies (rise from grass, slow pulses), coderain (96 glyph streams + hex ground disc — the only aura with a ground disc), thunder (storm cloud + bolt flipbook strikes), electric (static arcs front/back), butterfly (flapping butterfly flipbooks), meteor (hellfire meteors bursting), ascend (blaze: golden flame pillars, arcs, rising sparks, cracked power ring).

### 5.6 HUD box frames and backgrounds

Frames (`assets/ui-frame-<id>.png`): wood "Carved Wood" (free default), gold "Royal Gold", sun "Sunlit Radiance" (round), void "Void Gaze", starlight "Starlight Jewels", blossom "Sakura Branch", blizzard "Frozen Ice", hellfire "Magma Rock", aurora "Aurora Ribbon", nightsky "Midnight Velvet", rain "Rainy Slate", autumn "Birch & Maple", firefly "Glade Weave", vine "Berry Vine".

Backgrounds (`assets/ui-bg-<id>.png`): meadow "Sunny Meadow" (free default), night "Starry Night", sun "Sunlit Sky", void "Void Vortex", starlight "Starlit Sky", blossom "Sakura Spring", blizzard "Snowstorm", hellfire "Meteor Shower", aurora "Northern Lights", nightsky "Midnight Sky", rain "Rainy Day", autumn "Autumn Light", firefly "Summer Glade", lava "Volcano".

Theme sets: sun, void, starlight, blossom, blizzard, hellfire, aurora, nightsky, rain, autumn, firefly each have a matching frame + background + wings + aura ("matches the X aura").

---

## 6. Travelling merchant (traveller.js + game.js)

### 6.1 Schedule
- Global wall clock: a visit starts at every multiple of **15 min** since the Unix epoch and lasts **5 min**; away 10 min. Identical for every player (no server needed).
- Phases inside a visit: `arriving` (first 12 s, walks in from the left edge x=−140 to the stall), `open` (trading), `leaving` (last 12 s, turns round and walks back off the left edge), `away`. He stays visible until he has actually walked off.
- Stall spot: (900, 700) on the open bare patch lower-middle of the farm. His cart trails 110px behind on the side he came from; wheels spin and the cart bobs/tilts only while moving. Hop speed ×3.2 arriving, ×4.2 leaving.
- When he opens: banner "🛒 The travelling merchant has set up his stall! (5 min)". Tapping him or the cart opens the stall only while `open`.
- If the game opens mid-visit he spawns already at the stall.

### 6.2 Stock lottery
- Visit index = floor(now / 15 min). Stock = 8 distinct wares drawn by a deterministic xorshift PRNG seeded with `visit × 2654435761 + 12345`; weighted without replacement.
- Rarity from price: ≥9,000c **rare** (weight 1), ≥6,000c **uncommon** (weight 2), else **common** (weight 4).
- Purchase checks: in this visit's stock, phase is `open`, not already owned, enough coins. Frames/backgrounds are added to owned lists; wings/auras become inventory items (equip from the avatar's equipment screen). One-time purchases (owned items never re-sell).

### 6.3 Full catalogue (59 wares)

Frames (kind = frame)

| Ware | Price | Rarity |
|---|---|---|
| Berry Vine Frame | 1,500 | common |
| Royal Gold Frame | 6,000 | uncommon |
| Sunlit Radiance / Void Gaze / Starlight Jewels / Sakura Branch / Frozen Ice / Magma Rock / Aurora Ribbon / Midnight Velvet / Rainy Slate / Birch & Maple / Glade Weave Frame | 7,000 each | uncommon |

Backgrounds (kind = bg)

| Ware | Price | Rarity |
|---|---|---|
| Starry Night | 1,200 | common |
| Volcano Glow | 3,500 | common |
| Sunlit Sky / Void Vortex / Starlit Sky / Sakura Spring / Snowstorm / Meteor Shower / Northern Lights / Midnight Sky / Rainy Day / Autumn Light / Summer Glade | 4,000 each | common |

Wings (kind = item)

| Ware | Price | Rarity | Blurb |
|---|---|---|---|
| Fairy Wings | 2,500 | common | shimmering translucent wings |
| Ember Wings | 7,000 | uncommon | wings of living flame |
| Sunlit Wings | 9,000 | rare | golden wings shedding sunrays |
| Starlight Wings | 9,000 | rare | constellation wings that twinkle |
| Blizzard Wings | 9,000 | rare | ice wings shedding snow |
| Blossom Branch / Magma / Crescent Night / Tidewater / Maple Leaf / Glowmembrane / Holo-Grid / Stormblade / Plasma Arc / Monarch Wings | 9,200 each | rare | sakura branches; volcanic rock dripping magma; moon-blade wings full of stars; flowing water; tumbling autumn leaves; firefly-lit insect wings; digital panels streaming code; fans of frozen lightning; pure crackling electricity; butterfly wings shedding glitter |
| Void Wings | 9,500 | rare | torn obsidian, shards spiralling in |
| Aurora Wings | 9,500 | rare | wings of polar light |

Auras (kind = item)

| Ware | Price | Rarity | Blurb |
|---|---|---|---|
| Sunlit Aura | 2,000 | common | warm golden glow |
| Blossom Drift | 3,000 | common | cherry petals drift down |
| Blizzard Veil | 5,000 | common | soft snow falls |
| Firefly Glade | 7,500 | uncommon | fireflies at your feet |
| Starlight Orbit | 8,000 | uncommon | comets orbit on tilted rings |
| Autumn Whisper | 8,000 | uncommon | maple leaves swirl |
| Butterfly Flutter | 8,200 | uncommon | butterflies follow you |
| Rain Veil | 8,500 | uncommon | own little rain cloud, splashes included |
| Static Charge | 8,800 | uncommon | crackling arcs, a discharge every few seconds |
| Night Sky | 9,000 | rare | twinkling stars, the odd shooting star |
| Meteor Shower | 9,000 | rare | meteors rain down and burst |
| Thunderstorm | 9,200 | rare | "bring your own weather. The loud kind." |
| Aurora Veil | 9,500 | rare | your own northern lights |
| The Matrix | 9,800 | rare | "you are being decrypted. Constantly." |
| Blazing Ascendant | 9,800 | rare | golden flame pillars, crackling arcs |
| Void Aura | 10,000 | rare | slow violet swirl from the Eclipse |

---

## 7. The farm map (world.js, map.js, mainMapLayout.js, game.js)

### 7.1 Canvas and layers
- One screen, no scrolling camera: 1672 × 936 logical canvas letterboxed into the window. The whole meadow is walkable (pasture = full canvas) minus colliders.
- Layers bottom→top: meadow background `scene.farm.main.png` → ground layer (flat decals: flowers, grass, reeds, pond) → **y-sorted layer** (slimes, avatar, NPCs, buildings, bushes, rocks, trees; zIndex = ground y) → foreground layer (things slimes pass behind, e.g. shop awning) → FX layer (furnace sparks etc.). Farm world is hidden during battles.
- Breeze: plants (bushes, flowers, grass, reeds, seedlings) sway gently; trees sway with a skew; rocks and man-made props never move.

### 7.2 Landmarks (shipped layout "Main Farm", map version 10)

The meadow art has four round bare-dirt pads; the main buildings sit on them.

| Landmark | Position (px, ground point) | Size | Interaction |
|---|---|---|---|
| Blacksmith stall building (`blacksmith-01`) | (731, 261) top-center | 480 × 320 | solid; decor |
| Blacksmith NPC (`npc.blacksmith.png`) | (801, 304) | 100px wide | tap → **Smithy**. Hammer sprite swings above the anvil at (762,240) with sparks; furnace mouth at (801,196) has a persistent flame + occasional embers |
| Shop stall (`shop-front-01`) | (1300, 450) right-center | 480 × 320 | solid; decor |
| Shopkeeper NPC (`npc.merchant.png`) | (1140, 486) in front of the shop | 120px wide, idle bob | tap → **Shop** |
| Nest house (`nest-closed.png` / `nest-open.png`) | (271, 620) left, lower | 220px wide | closed door + 🔒 until Specialized Breeding is bought ("Unlock to open"), then open door → **Nest panel**. Collider ellipse centred (271,583) rx 80 ry 12 |
| Fishing pond (`pond-fishing-01`) | (222, 472) left | 620 × 293 | polygon collider (slimes walk around it); decorative only |
| Big tree (`tree-large-01`) | (302, 159) top-left | 452 × 433 | solid trunk collider |
| Travelling merchant stall spot | (900, 700) lower-middle pad | — | visit-only NPC + cart |
| Egg-nest drop-off point (`EGG_NEST`) | (640, 600) | — | hatchlings spawn here; breed "pop" FX here |
| Starter / spawn points | (700,520), (960,430), (1180,600), (810,690) | — | first four slimes |
| Avatar default spawn | (836, 580) | — | — |

Decor (all in `mainMapLayout.js`): ~20 bushes (green and white/pink flowering) framing the top edge, right edge and bottom-left/bottom-right corners; ~20 rocks (large/small) in clusters at the corners and near the shop; flower decals (tiny yellow/white/blue, tall pink, orange/white flower beds) mostly along the bottom-right and top; one grass tuft, one reed, one water reed by the pond. The middle of the field is open grass for slimes to roam.

Workstations are NOT on the map: Berry Bush, Farm Plot, Fishing Pond and Cooking Station exist only as artwork inside the Farm panel. Working slimes disappear from the field while employed (they appear on the station art in the panel instead). Slimes resting after breeding are also hidden (inside the nest house).

### 7.3 Slime movement on the farm
- Hop locomotion (config `MOVE`): idle "think" 2.5–5 s, then pick a random walkable target 48–260px away (straight line if clear, otherwise first waypoint of an A* path on a 28px grid that avoids colliders with 40px body clearance). Each hop: anticipation squash 0.12 s → airborne 0.38–0.48 s with 8–12 % vertical stretch, apex 26px → landing squash 0.14 s; average ground speed 24–32 px/s. A small dust puff on every landing (no landing sound — the user removed it).
- Idle breathing (2.5 % scale, 1.4 rad/s); blink = face squash only.
- Babies render at 0.62 scale and grow to adult size over 5 min (upgradeable).
- Facing flips with travel direction.
- Faces change with emotion (priority: starving → sleep; favourite selected or bred < 20 s ago → loved; poke → exciting; age < 15 s → exciting; hungry → sad; near a favourite → admiring; else a rare random ambient mood: normal/admiring/surprise/dare/exciting/sleep). Hearts float from loved slimes.
- Slime display width 67px (≈4 % of the canvas width); minimum tap target 44 CSS px (hit radius ≥ 58 logical px).

### 7.4 What the player can do on the farm
- **Move the avatar**: WASD / arrow keys steer (target kept 140px ahead; hop speed ×5.25, hops 0.55 scale so they are short and responsive; changing direction mid-air re-aims the hop). Or **tap/click empty ground** → the avatar hops there. Releasing keys stops after the current hop. The avatar never wanders on its own.
- **Tap a slime** → it does a happy poke hop, "select" sound, and Slime details opens.
- **Tap your avatar** → Avatar panel.
- **Tap NPCs/buildings**: shopkeeper → Shop, blacksmith → Smithy, nest house → Nest (or "Unlock to open"), traveller/cart → stall (only while open).
- HUD buttons for everything else.
- Escape closes panels / deselects.

### 7.5 Farm loop events visible on the map
- Food production ticks every 5 s of wall clock (sim in whole-minute steps) → "+N food harvested" banner.
- Offline catch-up (capped at 8 h) on return → offline summary banner.
- Auto-breeding nest escorts two parents to the nest door (§4.11).
- Hatch: full-screen reveal, then the newborn appears at the egg-nest point.

---

## 8. Sound and music (sound.js + sound.manifest.json)

One audio runtime; boots silently and unlocks on the first tap/key press; any failure = silent game. Mute toggle in Settings. Buses: master −3 dB → music 0 dB, sfx 0 dB (ui −2, impact −1, ambience −3), voice −2. Impact sounds duck the music by 3 dB (8 ms attack, 450 ms release). Max 24 voices.

Music states (looped, crossfaded)

| State | File | When | Crossfade | Gain |
|---|---|---|---|---|
| farm | `assets/bgm-farm.m4a` | on the farm (default) | 1200 ms | −8 dB |
| battle | `assets/bgm-battle.m4a` | during a siege | 900 ms | −7 dB |
| boss | `assets/bgm-boss.m4a` | wave-10 boss on the field / World Boss King | 700 ms | −6 dB |
| eclipse | `assets/bgm-eclipse.m4a` | World Boss Queen "Eclipse" | 700 ms | −6 dB |
| off | — | silence | — | — |

Ambience: `ambience.farm` = looped forest birdsong (`forest-birds-01.mp3`, `forest-birds-02.mp3`, −14 dB), plays only together with the farm music.

SFX cues

| Cue | When it plays | Notes |
|---|---|---|
| sfx.ui.select | tap a slime, tap your avatar, hatch an egg, inject an egg | −4 dB, 60 ms cooldown |
| sfx.achievement | achievement tier unlocked (with banner) | 800 ms cooldown |
| sfx.hit.squish / slash / pierce / magic / acid / ice / holy / crit | battle hits by type | battle doc |
| sfx.squad.fall | a squad member falls in battle | ducks music |
| sfx.enemy.pop | enemy death | **retired by the user** (asset exists, do not use) |
| sfx.slime.land | slime landing | **retired by the user** (too noisy on crowded farms) |

No sounds exist for: button taps in panels, buying, selling, crafting, levelling up, merchant arrival. (Opportunity for Roblox, keep subtle.)

---

## 9. Language support (i18n.js)

- Languages: English (default) and Japanese. Browser language `ja*` → Japanese, anything else → English; the saved choice always wins.
- Only a tiny surface is localised: HUD save status ("Saving…", "Saved", save warnings) and the whole Settings panel. Every other panel, banner, tip, NPC line and item name is hard-coded English.
- `t(key, vars)` with `{var}` interpolation; listeners re-render on switch.
- Roblox: put every string in a LocalizationTable from day one (English source + Japanese + Vietnamese at minimum); enable Roblox automatic translation for the rest.

---

## 10. Art direction (from viewing the PNGs + AGENTS.md rules)

Overall: bright, cozy, mobile-casual fantasy farm. Saturated colours, soft light, glossy "candy" surfaces, chunky readable silhouettes, warm wood + royal blue + cream + gold accents.

Slimes (`slime.base.navy.png`)
- Silhouette: a plump dewdrop / onion shape — wide rounded bottom that sits flat, sides bulging, tapering to a small soft point on top (Dragon-Quest-like). Roughly as wide as tall.
- Material: glossy jelly. One saturated hue (navy = deep royal blue), darker towards the base edge, large soft white specular glints (big curved highlight upper-left, smaller ones upper-right and along the lower rim), a tiny white "bubble" dot. No black outline — the edge is a darker shade of the body colour.
- No face baked in: faces are separate transparent overlays on a "face band" ~51 % up the body. Eyes are large vertical ovals, dark navy with a blue gradient and a white catch-light, set wide apart; a small thin smile between them. 9 expressions (normal, admiring, exciting, loved, sleep, angry, dare, sad, surprise).
- Babies 0.62 scale; secret slimes body ×1.2 (face counter-scaled).

NPCs (`npc.blacksmith.png`, `npc.merchant.slime.png`)
- Same slime body but light sky-blue, chibi-anime styling: thick dark outline, cel shading with glossy highlights, small stubby "hands", big expressive baked-in eyes with blush.
- Blacksmith: navy bandana, brass goggles, leather apron with anvil emblem, big hammer, anvil beside him.
- Traveller: red/white patterned turban with feather and blue gem, red neckerchief, wooden staff with glowing lantern, brown leather backpack with scroll and potion.

Buildings / props (`blacksmith-01`, `shop-front-01`, `nest-closed`, workstation art)
- Painted cartoon, 3/4 front view, clean transparent background, medium-thick dark brown outlines, soft cel shading.
- Palette: warm honey/brown wood beams with rope lashings, royal-blue + cream striped/scalloped awnings, a money-bag emblem on signs and banners (shop branding), gold coins, colourful potion bottles, glowing yellow lanterns, orange furnace fire, grey iron (anvil, weapons), green leaf garnish.
- Nest house: round cottage, golden thatched roof with green moss rim, cream plaster walls, wooden arched door, glowing round windows, egg-and-heart emblem above the door.
- Workstation dioramas (berry bush etc.): isometric cosy scenes — fence, stools, crates, baskets, sack, barrel, lantern, flowers, rocks — densely packed, very readable.

Ground (`scene.farm.main.png`)
- Top-down lush lime-to-grass-green meadow with fine painterly grass texture, sprinkled tiny white/yellow/blue flowers and sprouts, four round brown dirt pads with grassy edges, a subtle darker vignette at the borders.

UI
- Parchment panels `#fff6e0` / cards `#fffdf4`, thick wood-brown borders `#7a5230`, radius 10–14px, Trebuchet MS bold. Primary buttons orange-gold `#c98a3d` with cream text; selected tabs fill orange-gold.
- Semantic colours: success green `#3a6b2a`/`#54b848`, error red `#b04030`, info/baby blue `#2f9fd8`, dual orange `#f08a24`, secret purple `#8a4fd0`, achievement gold `#f0b429`.
- HUD numbers: pale gold text with dark-green outline.
- Item/material icons (`mat-coins`, `mat-mutation-serum`): sticker style — bold dark outline, glossy gradients, sparkles; serum = round flask with gold crown cork and swirling rainbow liquid.
- Equipment icons (per AGENTS rules): thick DARK-NAVY outline + glossy cel shading + bright highlights; hats are item-only (no head); nothing dangles below the brim.
- Avatar frames are more "rendered/realistic" ornaments (carved wood with brass studs; golden sun ring with flame rays). Avatar backgrounds are soft flat vector scenes (meadow: pastel blue sky, big white cloud, rolling green hills, yellow/white flowers).

Proportions on the 1672 × 936 canvas: slime 67px wide; NPC slimes 100–120px; traveller body ≈1.55 × slime; cart 2.5 × slime; buildings ~480px wide (≈7 slimes); nest house 220px; tree ~450px.

User vetoes to respect: user art is sacred (no recolours of originals); no in-world rarity glows; slime bodies stay static art (no body frame animation); avatar backgrounds stay static (no animated backgrounds/frames).

---

## 11. Asset inventory

Present = file exists in `reference/goo-lineage-web/assets/`. Missing = referenced by code but NOT in the download (must be recreated or re-exported from makeplay).

### 11.1 Scenes and legacy props

| File | What it is | Where used |
|---|---|---|
| scene.farm.main.png | top-down meadow with 4 dirt pads (1536×1024 source) | farm background + letterbox cover |
| scene.loading.png (missing) | loading-screen backdrop | loading screen |
| prop.tree.main.png | old single tree | manifest only; removed from scene |
| prop.fence.gate.webp | old fence gate | manifest only; removed from scene |
| prop.market.stall.png | market stall | reserved, never rendered |

### 11.2 Slime bodies and faces

| File | What it is | Where used |
|---|---|---|
| slime.base.navy.png | navy slime body (starter colour; avatar default) | field, portraits, loading screen, HUD slime icon |
| slime.base.<colour>.png (missing, lazy) | other base colours | field/portraits when discovered |
| slime.dual.*.png / slime.secret.*.png (missing) | dual and secret designs | field/portraits/collection |
| slime.emotion.{normal, admiring, exciting, loved, sleep, angry, dare, sad, surprise}.png | transparent face overlays | every slime view, farm-panel workers, dev gallery |
| egg.<colour>.png (missing) | coloured egg art | egg tray, egg details, reveal |

### 11.3 NPCs

| File | What it is | Where used |
|---|---|---|
| npc.merchant.png | shopkeeper | in front of the shop (1140,486), tap → Shop |
| npc.blacksmith.png | blacksmith slime with hammer + anvil | (801,304), tap → Smithy |
| hammer.png | swinging hammer sprite | child of blacksmith, strikes anvil |
| npc.merchant.slime.png | travelling merchant slime | visits every 15 min |
| npc.merchant.cart.png | his cart | trails behind him |

### 11.4 Workstation artwork (Farm panel only)

| File | Where used |
|---|---|
| prop.workstation.berry-bush.png | Berry Bush card + picker header |
| prop.workstation.farm-plot.png | Farm Plot card |
| prop.workstation.fishing-pond.png | Fishing Pond card |
| prop.workstation.cooking-kitchen.png | Cooking Station card |

### 11.5 Map assets (`assets/map/…`, all eagerly loaded; placement from mainMapLayout)

| File(s) | What it is | Collision | In shipped layout? |
|---|---|---|---|
| other/blacksmith-01.png | blacksmith stall building 480×320 | solid ellipse | yes (731,261) |
| other/shop-front-01.png | shop stall 480×320 | solid ellipse | yes (1300,450) |
| other/shop-counter-01.png, other/shop-awning-01.png, other/prop-shop-01.png | older shop pieces (awning = foreground) | solid / none / solid | no (editor palette) |
| other/bridge-01.png | wooden bridge decal | none | no |
| other/nest-closed.png, other/nest-open.png | nest house closed/open | code collider | code-placed (271,620) |
| other/reed-01…06.png | small reed clumps | none | reed-01 only |
| other/seedling-01.png | seedling | none | no |
| ponds/pond-fishing-01.png | pond 620×293 | polygon | yes (222,472) |
| trees/tree-large-01.png | large tree 452×433 | solid trunk | yes (302,159) |
| bushes/bush-green-01…05.png | leafy bushes | solid | yes (several) |
| bushes/bush-flower-pink-01.png, bush-flower-white-01…03.png | flowering bushes | solid | yes |
| flowers/flower-bed-orange-01, flower-bed-white-01 | flower mounds | none | yes |
| flowers/flower-pink-tall-01, flower-water-reed-01 | tall flower, water reed | none | yes |
| flowers/flower-tiny-{yellow,white,blue}-01…03 | tiny flower decals | none | yes (most) |
| grass/grass-tuft-01…06 | grass tufts | none | grass-tuft-02 only |
| ground-patches/ground-bare-patch-01…04 | dirt patch decals | none | no (pads are painted in the bg) |
| rocks/rock-large-01…05, 08 | boulders | solid | yes |
| rocks/rock-large-07, 09 | rock clusters (tagged "grass") | none | yes |
| rocks/rock-small-02…04 | pebbles | solid | yes |
| rocks/rock-small-01, 05…09 | pebbles (tagged "grass") | none | some |

### 11.6 HUD / UI art

| File | What it is | Where used |
|---|---|---|
| ui.btn.{settings, collection, farm, breeding, highscore, slimes, siege, upgrades, trophy}.png (missing) | 9 HUD button icons | right HUD grid |
| mat-coins.png | gold coin pile | HUD coin row, smithy/merchant prices |
| mat-food.png | food icon | HUD food row |
| ui-frame-{wood, gold, sun, void, starlight, blossom, blizzard, hellfire, aurora, nightsky, rain, autumn, firefly, vine}.png | 14 avatar-box frames | HUD box, Customise, Traveller |
| ui-bg-{meadow, night, sun, void, starlight, blossom, blizzard, hellfire, aurora, nightsky, rain, autumn, firefly, lava}.png | 14 avatar-box backgrounds | HUD box, Customise, Traveller |

### 11.7 Materials and consumables

| File | What it is | Where used |
|---|---|---|
| mat-mutation-serum.png | Prism Serum (crowned rainbow flask) | egg details inject button |
| mat-royal-jelly.png | Royal Jelly | egg details inject button |
| mat-stat-serum.png | Vital Serum | egg details inject button |
| mat-{wood, cloth, ore, common-part, rare-part, boar-tusk, glow-spore, ember-scale, frost-crystal, monster-core, boss-essence, crown-shard, umbral-shard}.png (missing) | crafting materials | Smithy header + costs, battle loot |
| equip-<id>.png (missing, ~90 files) | all weapon/hat/tail/back/wings/aura icons + farm sprites | gear on slimes, loadout, smithy, merchant |
| anim-{sword,bow,staff,shield,kit,focus}-{mythic,enchanted}/ (missing) | animated weapon frame packs | mythic/enchanted weapons |

### 11.8 Cosmetic FX textures

| File | What it is | Used by |
|---|---|---|
| fx-aura-rays-sun / fx-aura-halo-sun | sun rays + halo | aura-sun |
| fx-aura-rays-void / fx-aura-halo-void | void rays + halo | aura-void |
| fx-aurora-curtain-a / -b | aurora curtains | aura-aurora |
| fx-blaze-{tongue, ring, wisp, glow} | flame pillar, cracked ring, wisp, glow | aura-blaze |
| fx-bolts/frame-00 (partial; frames 00–04 used) | lightning flipbook | aura-thunder |
| fx-static/frame-00, 02 (partial; 00–09 used) | electric arc flipbook | aura-electric, aura-blaze, wings-thunder |
| fx-glyphs/frame-00, 03 (partial; 00–15 used) | code glyphs | aura-coderain, wings-coderain |
| fx-leaves/frame-00…05 | maple leaves (05 = rare variant) | aura-autumn, wings-autumn |
| fx-petals/frame-00…05 | sakura petals (05 = rare) | aura-blossom, wings-blossom |
| fx-wings/frame-00 (partial; 00–05 used) | butterfly flap flipbook | aura-butterfly |
| fx-bubble | water bubble | wings-rain |
| fx-comet-star | comet star | aura-starlight, aura-nightsky |
| fx-firefly | firefly | aura-firefly |
| fx-hex-ring | hex ground ring | aura-coderain |
| fx-meteor | meteor | aura-hellfire |
| fx-rain-cloud, fx-rain-streak | rain cloud + streak | aura-rain (streak also thunder) |
| fx-storm-cloud | storm cloud | aura-thunder |
| fx-snowflake | snowflake | aura-blizzard, wings-blizzard |
| fx-aura2-key, fx-aura2-debuff-key | alpha keys for the fire buff/debuff aura sheet | battle buff aura |

### 11.9 Battle FX textures (also reused as cosmetic motes)

| Files | Used by |
|---|---|
| battlefx-burst-{acid, arcane, fire, heal, ice, shock} | battle element bursts |
| battlefx-ring-{acid, arcane, fire, heal, ice, shock}, battlefx-ring | battle rings; ring-heal (aurora, coderain), ring-ice (rain), ring-shock (thunder, hellfire) |
| battlefx-mote-{acid, arcane, fire, heal, ice, shock} | battle motes; cosmetic motes: heal (aura-sun, aurora, firefly, coderain, wings-aurora/firefly), arcane (void), fire (wings-ember/hellfire), ice (rain), shock (thunder, wings-electric) |
| battlefx-spark-star | crits; cosmetic sparkle for wings-sun/starlight/nightsky/butterfly/fairy, aura nightsky/autumn/butterfly/hellfire/blaze |
| battlefx-{acid-drop, acid-splat, arrow, bite-marks, claw-marks, ember, fire-hit, fireball, flask, gem-shard, goo-blob, ground-crack, heal-cross, holy-hit, honey-drop, ice-crack, ice-impact, ice-shard, impact-puff, lava-glob, leaf, light-bolt, magic-hit, magic-orb, petal, pierce-hit, seed-dart, shockwave, slash-arc, snowflake, spirit-bolt, spore, thorn-spike, vine-crack, wisp}` | projectiles, impacts, enemy attacks (battle doc) |

### 11.10 Audio

| File | What it is |
|---|---|
| sound.manifest.json | cue/bus/music-state manifest (present) |
| sound.pack (missing) | packed SFX: achievement, enemy-pop, hit-{acid,crit,holy,ice,magic,pierce,slash,squish}, slime-land, squad-fall, ui-select |
| bgm-farm.m4a, bgm-battle.m4a, bgm-boss.m4a, bgm-eclipse.m4a (missing) | music loops |
| lib/bvker-foley/audio/ambience/forest-birds-01.mp3, -02.mp3 (missing) | farm birdsong ambience |

---

## 12. Notes for Roblox

### 12.1 UI: mobile first
General
- Build all UI as ScreenGuis (ResetOnSpawn off, IgnoreGuiInset on, respect the device safe area). Use Scale sizing + `UIAspectRatioConstraint` + a `UIScale` driven by the shorter screen side; author for a 390×844 phone in landscape and portrait, then check tablet and PC.
- Touch targets ≥ 48×48 px (Roblox minimum 44); spacing ≥ 8 px. The web HUD buttons have 60px hit boxes — keep that.
- One modal at a time (port `openOnly`), dim backdrop, tap backdrop or a large ✕ (top-right, 48px) to close; gamepad B / keyboard Esc close too. Tween in (0.15 s scale 0.95→1 + fade), respect a Reduced Motion setting.
- Re-create the parchment/wood look with 9-slice ImageLabels (one panel, one card, one primary button, one secondary button, one tab, one tag pill) so panels stay cheap. Font: `FredokaOne` or `GothamBold`-class rounded bold to match Trebuchet bold.
- Replace HTML `<select>` dropdowns with cycle buttons or segmented chips; replace hover tooltips with tap-to-open detail cards (the loadout already has a touch two-tap flow — use it everywhere).
- Long lists (slimes, collection, picker) = ScrollingFrame + UIGridLayout with virtualisation (only build visible cards) — farms can hold 220 slimes.
- Portraits: ViewportFrames are expensive; render slime portraits with a pre-made 2D image per colour (decal of the slime art) + face overlay ImageLabel; use one ViewportFrame only for the HUD avatar box.

HUD mapping
- Top-left: avatar box as a 2.5–3 cm square (≈110–140 px on phones): background ImageLabel clipped by a rounded CanvasGroup / circular mask for round frames, a ViewportFrame with the live avatar model (idle), frame ImageLabel on top; tap → Avatar panel.
- Under it: coins / food / slimes rows (icon + number, number tweens on change); save status becomes a tiny "cloud ✓" indicator.
- Right edge: 9 buttons in a vertical column on phones (2 columns if needed), horizontal row on PC; badge dots for "egg ready", "points to spend", "merchant here".
- Bottom-left: egg tray (max 4) above the Roblox thumbstick zone — on mobile move it to the bottom-center-left or make it a collapsible tray so it doesn't collide with the thumbstick; Hatch buttons ≥ 48px.
- Bottom-center: toast banner queue (don't drop messages; stack up to 2).
- Merchant arrival: banner + a pulsing cart icon on the right column with "4:12 left".

Screen → Roblox component mapping

| Web screen | Roblox treatment |
|---|---|
| Loading | ReplicatedFirst custom loading GUI: bouncing slime ImageLabel, ContentProvider:PreloadAsync progress, rotating tips |
| Settings | small modal: Music volume, SFX volume, Reduced motion, Language (auto from Roblox locale + override), Replay tutorial; drop export/import; keep Reset farm behind a type-RESET or hold-to-confirm |
| Collection | 3 tabs, 4-col grid on phone / 5 on PC |
| Farm + picker | station cards in a horizontal pager on phone; picker = full-height list with search TextBox + filter chips |
| Breeding house | two parent slots on top (sticky), grid below, big "Breed" button; preview text in a collapsible card |
| Highscores | OrderedDataStore boards for all 7 tabs (global), plus in-world leaderboard sign |
| Slimes / details | grid → details sheet sliding up from the bottom on phones |
| Upgrades | list of 6 rows; price buttons right-aligned |
| Achievements | list with tier chips; consider small coin rewards per tier |
| Avatar / Customise / Loadout | one "Avatar" hub with tabs: Stats, Gear, Look (body/frame/background) |
| Shop | Sell tab + real Buy tab (finish the placeholder catalogue or remove it) |
| Smithy | tabs Hand/Head/Tail/**Avatar** (add the missing avatar-gear tab), grid + detail card stacked vertically on phones |
| Nest | specialty chips + ON/OFF toggle |
| Traveller | 8 cards, timer, rarity colouring; ProximityPrompt opens it |
| Egg reveal | full-screen GUI + 3D particles, skippable after 1 s |
| Dev panel / map editor | Studio-only plugin or admin-gated debug GUI; never shipped to players |

### 12.2 World: from a 2D meadow to a 2.5D/3D Roblox place
Recommended camera: a **fixed-angle follow camera** (≈55° pitch, slight yaw, zoom range clamped) so the farm reads like the original 2.5D top-down view while staying fully 3D. Players can still rotate a little on PC; on phones keep default rotation off and use tap-to-move + thumbstick.

Scale: keep the original layout proportions. Suggested mapping x_studs = px × 0.1, z_studs = py × 0.14 (stretches depth to undo the painted foreshortening) → farm ≈ 167 × 131 studs. A slime (67px) becomes ≈ 5–6 studs wide — big, readable and cute next to buildings ≈ 48 studs wide. Adjust after a greybox test.

Multiplayer structure (decision for the director; recommendation): each server holds up to 6 players; each player owns a **farm plot** that copies the Main Farm layout (meadow, nest house, pond, tree, bushes, and — new — the 4 workstations placed physically). A **shared plaza** in the middle holds the shop stall + shopkeeper, the blacksmith stall + blacksmith, and the travelling merchant's cart stop (his schedule is already global, so every player sees him arrive together — a natural social moment). Farm data is per player (DataStore); plots are assigned on join.

Landmark placement on a plot (keeps the original composition): blacksmith/smithy top-center (or in the plaza), shop right-center (or plaza), nest house lower-left, pond left, big tree top-left, open grass in the middle for wandering slimes, traveller stop lower-middle, decor bushes/rocks framing the edges. Use the four dirt pads as building pads.

Workstations: make them real places on the plot (Berry Bush, Farm Plot, Fishing Pond, Cooking Station) built from the panel artwork; assigned workers walk there and play the work-bob and talk-bubble chatter (BillboardGuis, same timings and lines). Locked stations show greyed with a rope fence and a price sign; a ProximityPrompt opens the Farm panel focused on that station. This replaces "working slimes vanish".

Slimes in 3D
- One MeshPart dewdrop body per slime (colour via the original art as a texture/SurfaceAppearance, or vertex colour + glossy material), separate face Decal/SurfaceGui swapped per emotion, Humanoid-free. Keep the squash/stretch hop (anticipation → stretched arc → landing squash) with CFrame + Size tweens on the client.
- Wander AI: server owns targets at low frequency (think 2.5–5 s), clients interpolate hops locally (deterministic seeded motion); or simulate fully on the client of the plot owner and replicate only "rest positions" — 200+ slimes per server must stay cheap. Use PathfindingService or the original 28-stud-equivalent grid A* around colliders.
- Hidden slimes (working/resting) → visible at stations / inside the nest house door animation.
- Emotions + hearts as small BillboardGuis or particles; limit to on-screen slimes.

Player avatar
- Recommendation: the player plays as their **slime avatar** (custom StarterCharacter: slime body + face + equipment attachments for hand/head/tail/back/wings/aura), with the Roblox display name above. This keeps the game's identity and lets all cosmetics fit. Movement: Roblox thumbstick/WASD + tap-to-move; hop locomotion animation (short quick hops while steering). Jump button optional (a "happy hop").
- Wings: two-halves hinge rig (Motor6D/bones) flapping; auras = attachment-based ParticleEmitters/Beams grounded at the feet, built per archetype with the roblox-vfx-craft skill; budget particles for cheap phones and fade other players' auras with distance.
- HUD avatar box frame/background stay 2D UI art (port the 28 PNGs as decals).

NPCs
- Shopkeeper, blacksmith and traveller = rigged slime models with their accessories (bandana/goggles/apron; turban/feather/lantern staff/backpack). Blacksmith hammer swing + anvil sparks + furnace fire loop; traveller walks in with the cart (wheels spin only while moving), stays 5 of every 15 minutes (global clock via `os.time()`), walks out.
- Interaction: ProximityPrompt (hold 0.3 s) + tap on the model; open the matching panel.

Art direction in 3D
- Match the original: saturated cartoon colours, chunky silhouettes, soft cel-ish lighting (Future lighting with a warm sun, soft shadows, slight bloom), glossy slime material, painted textures on buildings (honey wood, royal-blue/cream awnings, money-bag emblems, gold trims, glowing lanterns), lush green terrain grass with tiny flower decals and round dirt pads.
- Respect user vetoes: no rarity glows on the field, slime bodies not frame-animated (procedural squash/stretch is fine — it was in the original), static avatar backgrounds.

Performance (cheap phones)
- StreamingEnabled; plots outside view streamed out; LOD for decor; merge decor into few meshes.
- Cap active ParticleEmitters per client; auras of other players reduced to a simple glow beyond ~60 studs.
- Run hop tweens only for slimes within camera range; sleep the rest.

### 12.3 Gaps / things to rebalance
- Missing art in the download: 9 HUD button icons, ~90 equipment icons, all non-navy slime colours and dual/secret designs, egg art, loading backdrop, 13 material icons, several flipbook frames, weapon animation packs, all music and the SFX pack. Re-export from makeplay.ai or recreate.
- Specialized Breeding costs 9c (test value). Shop BUY tab is a disabled placeholder. Smithy has no tab for its 6 avatar-gear recipes. Only en/ja for a handful of strings.
