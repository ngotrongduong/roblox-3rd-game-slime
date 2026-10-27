# 05 - Owner chat history, part 2 (messages 258-514 of 514)

Source: the owner's own messages to the makeplay.ai builder for "Goo Lineage V2", `window.__user.slice(257)`
(seq 9561 - 20892), 2026-08-31 to 2026-10-03 (UTC). The final message (seq 20919, the ROBLOX_EXPORT.md request) was
sent by us and is ignored. From 2026-10-03 the owner writes in Vietnamese; quotes are translated.
Short Title-Case messages ("Add hit sounds", "Design a boss battle", "Make rings glow"...) look like clicked
suggestion chips, not typed wishes; they still show what was accepted.
Cross-refs: battle numbers -> 02-battle.md, avatar/merchant/HUD -> 03-shell-ui-world.md, auras/wings -> 04-vfx-animation.md.

---

## 1. Timeline

### 2026-08-31 - battle content, drops, tutorial, farm gating
- 9561: Each weapon gets an extra special skill on top of its normal AI: Shield **taunt** (mobs in a radius come to it), Sword **dash** to target, Healing Staff **healing ring** (heals all in radius); design similar ones for the other weapons.
- 9688-9689: Uploaded Volcano mobs (volcano-only); design attack types/projectiles/damage. **Magma Bull = boss** (special attack), **Wolf = mini-boss**.
- 9794-9902: Drop/crafting tuning. Clarified: NOT higher drop rates; epic gear should take >=10 runs of materials, mythic >=20 runs. Lower drop rates: **Boss Essence 5%, Monster Core 10%**; normal mobs drop randomly (coins, food, materials), not every kill. Loot should visibly drop on the ground when a monster dies.
- 10025: Shield dash leaves a **trail of slimes** instead of a white dash; every pet inside the healing ring gets healed with a **rising green cross** and maybe the heal number; all area attacks need real art, more particles, nicer impact (not plain coloured rings); generate assets as needed.
- 10135: Victory scene: slimes jump/cheer, confetti, fireworks. Then choose **replay same round or next level**; next level **100% harder, +5% drop rate**; battleground changes every 10 waves.
- 10300-10301: Uploaded Greenfield mobs: **Boar = boss**, **Turtle = mini-boss**. Design attack styles; generate or reuse assets.
- 10492-10493: Uploaded Dark Forest / Mushroom mobs: **Tree Golem = boss** (special moves), **Wolf = mini-boss**.
- 10608: "Upgrade the Snowy Peak boss".
- 10694: After the first 10 waves, at the higher difficulty every mob/boss unlocks a **new, stronger, unique attack** (some AOE, some single-target), with more VFX, "must be a professional quality". One map group at a time, Greenfield first. 10799 Mushroom Grove next; 10942 Volcano; 11020 Snowy group.
- 10882: Alchemist attack range too high; must be <= the bow's.
- 11091: First-time tutorial script (see section 5). 11223 add a Skip Tutorial button; 11238 "Add a tutorial for new players".
- 11290: Farm-station gating and food rebalance (see section 5).
- 11466: Polish all siege skills for slimes and monsters to make fights more exciting. 11585 hit sounds; 11704 battle music; 11743 "How about a boss battle?"
- 11831: Achievements tab with categories (see section 5). 12081 "continue".
- 12239: Dual mutation ~**5%**, secret ~**1%**.
- 12259: Remove the slime jump/walk sound (noisy with many slimes). 12288: remove the mob death sound.
- 12337: Newborn slimes briefly show the old/strange slime art before switching; check every colour uses the current art.

### 2026-09-01 - World Boss, mutation fixes, equipment fit, buff aura
- 12403: Post-wave-10 difficulty jump too small: make it **500% stronger**. New mode **World Boss**: huge boss (owner's image), boss centred on a generated battlefield, **20 slimes** (unequipped ones just bounce and body-hit; equipped ones use weapon AI), drops coins + special rewards that let you **inject an egg** for a secret-mutation chance; unlocks with the **max-50-slimes upgrade**; design special attack patterns, make it challenging. 12747 "Create boss abilities".
- 12876: Bought the 50-slot upgrade but no World Boss button; show it from the start with a lock.
- 12935: Replace the boss's spawned minions with the owner's uploaded minions, each with skills/patterns matching their character.
- 13073: Owner showed a screenshot of a helmet on a slime; asked what is wrong and for a better-fitting helmet. 13202 fit-check metal tails; 13258 fit-check hand weapons.
- 13290: Normal siege mobs can drop food too.
- 13365: Slimes under an alchemy buff need a visible aura. 13545: buff ring disappears after a few waves; wants an **animated aura, not a ring at the feet**.
- 13474: Eggs ready to hatch stay unhatched until clicked (complaint).
- 13546: Tail charms render behind the slime body (complaint).
- 13710: Uploaded an updated **flame corona** aura image to try.
- 13803: Remove the glow/aura from epic and legendary gear.
- 13804: Buff only ever reaches 2 slimes; asked whether more can get it. 13914 "Add debuffs for enemies". 13993 remove the triangle marker over buffed slimes (the aura is enough).
- 14027: More World Boss animation: launch up then slam for AOE; shrink then enlarge before a big spell; more moves. 14119 more minion animations; 14212 animate other bosses; 14306/14375 slimes and enemies "attack too" (anim chips).
- 14413: World Boss loot and **egg details panel**: click an egg to see both parents, possible outcomes (stats, mutation chances), and inject either **10x mutation** (dual 50%, secret 10%) or a **stats boost** (guaranteed random stat bonus instead of 10% chance). Loot table: gold, meat, exclusive crafting materials, rare 10x-mutation item, rare stats-boost item; make art for them.
- 14609: After 200+ breeds, zero dual or secret slimes; check the mutation rate.
- 14744: **Pity system**: after N failures the next breed is guaranteed to mutate.
- 14747: **Auto-equip**: highest-level slimes get the highest-rarity gear until none is left.

### 2026-09-02 - raid, hats, sizes, weapon motion, FX art
- 14826 "Design a boss battle"; 15135 World Boss fight freezes at a point (bug); 15268 "Add boss raid leaderboard".
- 15401: **Quick team** for siege and World Boss teams, highest level first.
- 15438: All hats are angled; remake every hat **straight-on**, based on its name, each unique; do not look at previous ones. 15534 hats **50% larger**. 15575 some hats cover the face; move up, check every hat. 15629 now all too high; lower a bit.
- 15651/15679: **Sun Lion +20% size**, but eyes/face stay the normal size (it has features outside the body, so same-size image looks smaller on the map).
- 15699: Weapon on one side, tail on the other, and they must swap when the slime changes direction. 15801: "you put them on the wrong side", must be opposite.
- 15743: All eyes/faces ~20% smaller.
- 15758: Royal Griffin +20%; check all secret slimes with extra features: +20% body, face unchanged. 15778 on those, eyes/mouth 20% lower. 15802 hats on them 20% lower too.
- 15818/15822: "Add a jumping mechanic" then immediately "no cancel this idea".
- 15824: Weapons get their own motion: gentle wavy idle on the farm map; in battle sword swings, staff raises on cast, etc. 16011 sword must swing in a **large arc**, not rotate in place. 16037 "Improve battle animations".
- 15949: Background does not cover the whole screen. 15991 "oh no" you replaced all battleground backgrounds; restore the previous set of 4. 16025 siege still shows the main farm map instead of the siege maps.
- 16073: Explosions, heal auras and other area FX all reuse one asset recoloured ("boring"); generate separate art per type/element and review it.
- 16193: In battle the weapon stays on one side; must switch with movement direction.
- 16194: Replace the "Buff" label with a proper skill name, shouted only by the caster, not above every slime.
- 16258: "Ring" FX should be many small particles/objects circling around the unit front-to-back, not a literal ring shape; burst explosions start tiny at the feet and expand fast; edges much softer (they look pasted). 16292: liked the previous ring/burst art after all; **revert to it, only soften edges**. 16303 "Make rings glow".
- 16311: Faster Incubation capped at level 5.
- 16332: Discovered colours show a grey circle instead of the unlocked colour.
- 16376: Egg details not updating in the main game (only in the test build); disable the dev panel in the main game. 16400: main game produces no food.
- 16464: Food progress bar real-time; all boxes exactly the same size.
- 16482-16524: Accessory placement: Iron Tail Guard lower and behind body; Cloth Sash on the body slightly under the eye; sash bow lower and off to the side; Lucky Charm, Core Pendant, Eclipse Charm same spot as the bow.
- 16533: **Player avatar slime** spec (see section 5).

### 2026-09-03 - avatar polish, HUD, merchant, crafting UI, auras
- 16803: Avatar at lv 4 had 128 stat points (bug?). 16815 rank-ups too easy: **one rank per 50 hatches**. 16824 stack identical equipment. 16836 avatar movement too slow/unresponsive; 16920 still slow, +50% speed, small hops fine.
- 16868: Explosion/burst/heal-ring FX on the **ground layer**; only sword hits, slashes, claw marks and projectile spells on top.
- 16884: Slime Siege tab unlocks when slimes reach **level 30**. 16904 slime slots upgrade capped at lv 40; 16905 Faster Growth and Quicker Breeding capped at lv 20.
- 16936/16939: Redesign top-left HUD (see section 5).
- 16979: Uploaded the **travelling merchant** (slime with cart): every 15 min, stays 5 min, same slime animation, cart animates only while moving; sells avatar frames, backgrounds, wings, auras for **1k-10k**.
- 17027/17041: Avatar box 2x but frame art must not scale with it; make thinner frames sized to the box; background fully inside the frame; slime ~50% larger than the last try; it can just stand and breathe.
- 17069: Equipment on the avatar-box slime flickers out when moving. 17099 Customise opens its own window to change body, frame, background. 17111 merchant vanishes before reaching his spot. 17145 merchant and cart too small (scale to slime size), walk to empty spots. 17167 slime must face its movement direction.
- 17123: Remove LV from the avatar (keep Rank), remove rank/LV explanations, replace with a progress bar; remove equipped list from the avatar card; remove the control tips text.
- 17133: Equipment window: equipped items in a separate tab; main tab shows only what is available.
- 17175: Full equipment list for every weapon type, Common to Mythic (skip existing).
- 17249: Smithy list too long: grid of item + rarity frame; click opens a side panel with materials and stats. 17265 remove the green circle on smithy items. 17274 rebalance recipes to rarity. 17319 recipes differ per item and make sense (no fabric for swords, cloth for Satchel); add map-specific materials from each of the 4 maps' mobs/bosses.
- 17295: Wings lower, to the middle of the slime. 17305 gentler flap. 17363 wings nice, flap at **1/2 speed**. 17441 wings +20%.
- 17374/17403: Two bushes bottom-right not Y-sorted (one with 3 white flowers, one with 5 yellow-orange-red flowers).
- 17413: Berry vine frame: natural soft edges, not cut-out straight edges.
- 17429: Ring and aura ~20% larger, more visible.
- 17450: Auras "over the top fancy", multi-layer, several techniques, research it; start with Sunlit. 17482 Void too. 17497 aura must **not bounce/breathe** with the slime. 17515 both are spinning rings; want other types (orbiting, falling from sky, rising from ground, flame, combinations). 17536 orbiting aura.
- 17552: Upgrade costs from ~**100** coins (first level) to ~**20,000** (last).
- 17565: Rank stat bonus should match bred-slime growth: at ~800 slimes the best was 33/27/37/191; "we will rebalance that later".
- 17574: Dislikes the Hellfire ring; make **meteor rain** that explodes mid-air or on impact with small shockwaves and sparks. 17604 likes it, but all meteors from the **same direction**, not crossing.
- 17590: Whole game froze.
- 17613: Blossom petals >= 3x larger. 17624 dislikes the flower on the back; more sakura petal variants, a few flowers, mostly loose petals. 17653 loves it: petals spin/twist/fly in varied paths, natural and realistic; new images 20% smaller; remove the blossom circle; some petals land and last a few seconds. 17663 new petal motion bad, **use the previous motion**.
- 17642: Slime shadows darker (barely visible).
- 17672: Starlight orbit: remove the moon on the ground, more orbiting stars.
- 17685: About **5 stat points per rank**.
- 17686: Bug: rapid direction changes make the avatar shrink until next press.
- 17714: Special reveal for a dual-colour slime with strong FX; secret slime reveal even bigger.
- 17715: New-player luck: first **30 min after the tutorial 5x luck**, next **30 min 3x**, then normal (affects dual, secret and stat bonus).
- 17753: New aura idea "Aurora sky veil".
- 17769: Under-statted for rarity: Wizard Hat, Core Crown, Royal Crown, Core Pendant, Mythic Focus, Enchanted Staff.
- 17784: Hellfire: remove the circle behind the body. 17814 Blizzard Veil: remove the moon circle, snowflakes 2x.
- 17837: New aura **Night Sky** (stars suspended around, twinkling, occasional shooting star). 17853 **Rain** aura (rain on body and ground, splashes). 17875 **Autumn** (maple leaves, several autumn colours). 17899 "Add another aura".
- 17913: Full spec for **Encrypted Code Rain** aura (see section 5). 18037 rename to **"The Matrix"**, more falling code, remove the vertical ellipse behind the body, ground circle at the feet. 18052 code spreads too wide; keep to the slime's width.
- 17939: Asked for lots of coins to test-buy auras (source of the later 500k bug).
- 17969: Design Thunderstorm and Electric auras.
- 17989: Full spec for **Aurora Veil** (see section 5).
- 18007: Ground circles must sit at the feet, centred exactly on the shadow; "you always put that one behind the slime body".
- 18069: Loading screen too slow; load main-screen assets first and the rest while playing (idle game); refactor into modules (auras, wings, avatar, frames). "Don't take my suggestion seriously as I don't know much about programming". 18129 compress main-screen assets; 18159 compress battle maps.

### 2026-09-04 - more auras, frames, wings
- 18186: **Butterfly** aura (colourful, real wing flaps). 18284 butterflies fly randomly like real ones, not in a circle.
- 18208: Firefly Glade barely visible: 3x larger, more glow.
- 18229: Owner showed a real aurora photo; recreate it, compare, try another method if not similar. 18570 too tall: about 30 px above the head then fade, bottom fades too, cycle all rainbow colours, add bloom. 18582 30% narrower; parts spill out of the avatar box: clip to the frame, do not shrink. 18596 move 20 px up. 18605 make it change colours.
- 18230: Night Sky stars 3x larger.
- 18282: Highscores: show each player's avatar slime; new categories: total bred, boss defeat time, strongest, highest DEF, highest speed, highest HP.
- 18283: Merchant cart 1.5x. 18369 cart out of scale.
- 18285: Thunderstorm: lightning strikes should not cause shockwaves/explosions; make several realistic strike variants. 18619 strikes are bad, owner uploaded preferred samples. 18634 uploaded a sprite sheet; black cloud 20 px lower. 18684 "the quality of your artwork is very low", use the owner's sprite sheets.
- 18336/18338: Static Charge redo from owner's **10-frame sprite set**, front and back of the body; wait for all 10. 18358 arcs wider to cover the whole body; frames should not be in lockstep, a random one may pause/blink. 18386 still only on top, extend down to the ground.
- 18397: Design avatar frames + backgrounds matching each aura theme, one at a time, each only from its own aura's theme. 18441 Void theme. 18695/18731/18766 more sets.
- 18471: Frames too thick, make all narrower. 18485 misunderstood, **revert**; only the Void frame box was too thick; redesign it more elegant. 18543 completely new Void frame; 18559 still does not match its background.
- 18507: Avatar frame does not shrink on small screens/windows and covers the screen (owner screenshot).
- 18531: Radiant frame and background mismatch; circle off-centre.
- 18767: Petals and flowers 30% smaller. 18805 petal pink too dark; match the background's pink.
- 18818: Merchant stocks **8 random items** per visit, some rarer than others, not the whole catalogue.
- 18832: Wings matching each aura/background set, multi-layer particle FX; flap motion is good. 18874 the duplicate translucent back pair must flap in sync. 18885 more wings, any material/style, not only feathers. 18917 wing particles 2x larger. 18928 Void wings have transparent holes, redo. 18964 remove the small explosion particles from Plasma Arc wings. 18975 remove water drips from Tidewater wings; use floating soap bubbles.
- 18941/18991: Slime (and avatar) sometimes squishes briefly then bounces back; remove/fix.
- 19005-19045: Stormcloud wings: new style; remove particles, add small lightning arcs running randomly; arcs to both sides with varied intensity and size; arcs flew too far ("unrealistic"), keep them on the tips/edges; arcs all look the same, add small variants.

### 2026-09-05
- 19053: Bug: every login/restart grants 500,000 coins; remove it.

### 2026-10-03 - (Vietnamese) animation review, refactor, Blazing Ascendant, gear, animated art
- 19102: Review all animations, list strengths/weaknesses, propose upgrades. 19126 a long English "improve based on player feedback" prompt (looks platform-suggested): localisable HUD strings table, English default + **Japanese**, browser-language detect, language selector in Settings saved in the save file, icons with tooltips, touch targets >= 44 px, keep art/HUD/gameplay unchanged. 19248 "do P0 first". 19287 asked what "prune AGENTS.md (over budget)" meant. 19289 continue with P1 animation.
- 19362: Back wings feel stiff (only a slight view-angle change); wants livelier, more lifelike motion. 19380 "not pretty, review it yourself". 19418 good, but only fits bird wings; redo for double/butterfly wings, self-review on a butterfly pair. 19481 why is there a blurred shadow behind the wings. 19502 butterfly flap slower and lighter.
- 19534: Review/optimise all code, split big files into modules without changing structure or behaviour, remove duplicate/conflicting/dead code; goal: lighter game.
- 19675: Wants a Dragon-Ball-style flame aura; layers: core glow, flame shell rising, outer wisps, sparks rising, random lightning, ground ring, heat distortion. 19706 the asset clearly misses the brief; check against the provided image. 19725 uploaded the reference image. 19839 shop icon for **Blazing Ascendant**; 19949 register `aura-blaze` in the shop.
- 19984: Re-sort blacksmith items into correct order and groups. 20344 re-sort head and tail items.
- 20004: Add **10 head + 10 tail** items fitting existing weapon sets; match the asset style; balance stats and recipes. 20144 the new art does not match the old equipment style and some head gear does not sit right on the slime; review all. 20265 tail items have different shapes/functions, so position each appropriately. 20297 swaying animation for Charms.
- 20376: Turn **Mythic Focus** into an animated weapon based only on its original image (orb + golden wings). 20418 "very beautiful", do it for all Mythic weapons. 20452 and Epic weapons.
- 20489: Animate secret slime bodies, in batches. 20532 slimes have **no legs**; follow the original design exactly, add nothing, only move the existing details/patterns; skip if not feasible; self-review against the original.
- 20592: Switch to animating all backgrounds and frames, keep sizes. 20620 backgrounds only, no frames. 20675 annoyed: look at each background image and animate its own theme (e.g. meteor shower background -> falling meteors), replacing the static ones. 20677 you changed some slimes/frames/backgrounds earlier; restore originals first. 20697 many special slimes still animated; restore them to original. 20752 wants each background as a short AI-generated video clip from a prompt based on the original image, fitted to the frame. 20810 "the way you do it is ugly". 20843 one at a time, **static camera**. 20884 not pretty: camera zooms in, hard jump at each loop, too short to feel smooth. 20892 **drop it**, revert the 2 backgrounds to static.

---

## 2. Owner preferences & taste
- **Rich, professional VFX**: "must be a professional quality" (10694); area FX need "nice art", "more particles, nicer impact" instead of simple shapes (10025); per-element art, not recoloured copies (16073); auras "over the top fancy", multi-layer, several techniques (17450); wing FX multi-layer (18832).
- **Soft edges and glow**: hates hard "pasted" edges (16258, 16292, 17413); wants bloom/glow (16303, 18570).
- **Natural, realistic motion**: petals spin/twist and land (17653); butterflies flutter randomly (18284); lightning realistic, arcs on wing edges (18285, 19036); wings flap gently and slowly (17305, 17363, 19502); lifelike wing articulation per wing type (19362, 19418); sword swings in a big arc (16011); boss jump-slam and shrink-grow wind-ups (14027).
- **Variety**: each aura a different archetype (17515); each hat/frame/wing unique, not derived from earlier ones (15438, 18397); non-feather wings welcome (18885); several variants of petals, strikes, arcs (17624, 18285, 19045).
- **Readable feedback**: green rising cross + heal numbers (10025); buffed slimes show an animated aura (13365, 13545); caster shouts a named skill (16194); loot drops on the ground (9902); victory celebration with confetti/fireworks (10135); spectacular dual/secret reveals (17714).
- **Layering**: ground FX at the feet, centred on the shadow, under units; only hits/slashes/projectiles on top (16868, 18007).
- **Visible sizes**: repeatedly asks for things larger (hats 50%, auras 20%, petals 3x, stars 3x, fireflies 3x, snowflakes 2x, wing particles 2x, wings 20%); but then trims when overdone (petals -20%, -30%).
- **Icons over words** in the HUD (16936); clean UI, remove explanatory text and tips (17123); compact grid + side panel (17249); stack duplicates (16824).
- **Elegant thin frames**, background fully inside the frame (17041, 18471, 18485).
- **Quiet audio**: no per-hop or per-death sounds when many units exist (12259, 12288); wants hit sounds and battle music (11585, 11704).
- **Responsive control**: avatar must feel fast and snappy (16836, 16920).
- **Grind and rarity**: drops rare, not every kill; epic ~10 runs, mythic ~20 runs (9861, 9902); big difficulty steps (500%, 12403); cosmetics expensive 1k-10k (16979); merchant stock random and rare (18818).
- **Generous onboarding**: tutorial with arrows, first egg random base colour with bonus stats "to make them excited" (11091); 5x/3x luck in the first hour (17715); pity guarantee (14744).
- **Phones/small screens and speed**: avatar frame must scale on small screens (18507); fast loading, stream assets while playing (18069); compress assets (18129, 18159); lighter code (19534).
- Liked and kept: wings motion (17363, 18832), Blossom Drift (17653), meteor Hellfire (17604), starlight orbit stars (17672), previous ring/burst art (16292), animated Mythic/Epic weapons (20418).

---

## 3. Vetoes & complaints (most important)
Drops, balance, difficulty
- 9861: rejected raising drop rates; wanted crafting to be slow (10 runs epic / 20 mythic).
- 9902: mobs/bosses must NOT drop every kill; Boss Essence 5%, Monster Core 10%.
- 10882: Alchemist range longer than Bow - not allowed.
- 12403: post-wave-10 difficulty increase "too small" -> 500% stronger.
- 14609: 200+ breeds with no dual/secret - mutation looked broken. 13804: buff reaches only 2 slimes.
- 16815: rank-ups too easy -> per 50 hatches. 16803: 128 stat points at lv 4 looked wrong. 17685: too many stat points per rank -> ~5.
- 17769: listed gear under-statted for its rarity (Wizard Hat, Core Crown, Royal Crown, Core Pendant, Mythic Focus, Enchanted Staff).
- 19053: free 500,000 coins on each login - remove (was a test grant from 17939).
Audio
- 12259: slime jump/walk sound "very noisy and unpleasant" with many slimes - removed. 12288: mob death sound removed.
Battle FX and presentation
- 10025: white shield-dash streak -> trail of slimes; plain colour-ring area attacks rejected.
- 13545: buff ring at feet disappears and is not wanted -> animated aura. 13993: triangle over buffed slimes removed. 16194: generic "Buff" text over every slime rejected.
- 13803: glow/aura on epic and legendary gear "look funny and not nice at all" - removed.
- 15991: builder replaced all 4 battleground backgrounds - "oh no", revert. 16025: siege showed the farm map. 15949: background not covering the screen.
- 16011: sword rotating in place rejected -> big arc. 16193 / 15699 / 15801: weapon not swapping sides, then on the wrong side.
- 16073: one recoloured FX asset for every element "kind of boring".
- 16258: literal ring shapes rejected (ring = circling particles); burst must grow from feet; sharp edges look pasted. 16292: the redone art was worse - revert to previous, only soften edges.
- 16868: area FX drawn on the top layer - must be ground level.
Equipment art and fit
- 13073: helmet fits badly. 13546: tail charms behind the body. 15438: hats drawn at an angle and derived from old ones - remake straight and fresh. 15575/15629: hats covering faces, then too high. 16482-16524: sash/bow/charm/tail-guard positions wrong.
- 17265: green circle behind smithy items removed. 17249: crafting list too long.
- 17319: identical recipes and nonsensical materials (fabric for swords) rejected.
- 20144: new head/tail art does not match the existing style; some head gear does not fit the slime. 20265: all tail items placed alike - wrong.
Slime art
- 12337: newborns flash the old slime design.
- 15679: enlarging Sun Lion also enlarged its face - face must stay normal size. 15743: faces too big (-20%). 15778/15802: faces and hats too high on featured secret slimes.
- 18941/18991: random squish-and-bounce on slimes/avatar - remove. 17686: avatar shrinks on rapid direction changes.
- 17642: shadows too faint.
- 20532: animated secret slimes must not gain legs or any extra details. 20677/20697: builder altered slimes/frames/backgrounds - restore all originals; special slimes left animated - revert to static originals.
Auras
- 17497: aura bouncing/breathing with the slime - no.
- 17515: two spinning-ring auras - wants different archetypes.
- 17574: Hellfire ring disliked -> meteors. 17604: meteors crossing each other - same direction. 17784: circle behind body on Hellfire removed.
- 17624: flower on the back of Blossom Drift disliked. 17653: blossom circle removed. 17663: new petal motion "not good" - revert to previous. 18805: petal pink too dark.
- 17672: moon on the ground in Starlight disliked. 17814: moon circle in Blizzard removed.
- 18007: ground circles placed behind the body instead of at the feet - repeated complaint ("you always...").
- 18037/18052: vertical ellipse behind body in Matrix removed; code rain spread too wide.
- 18208: Firefly barely visible. 18230: Night Sky stars too small.
- 18229, 18570-18605: Aurora not like the reference; too tall, too wide, spills out of the avatar box, not glowing, not colour-shifting.
- 18285: shockwaves/explosions on Thunderstorm strikes rejected. 18619/18684: builder's lightning "bad", "the quality of your artwork is very low" - use owner sprites. 18634: cloud too high.
- 18358/18386: Static Charge only on the top of the body, frames in lockstep.
- 19706: Dragon-Ball flame aura asset "does not meet the requirement".
Wings
- 17295: wings too high. 17363: flap too fast (half speed). 18874: back translucent pair out of sync. 18917: particles too small. 18928: Void wings with transparent holes. 18964: explosion particles on Plasma Arc removed. 18975: water drips on Tidewater removed (bubbles instead). 19018: particles on Stormcloud removed. 19036: arcs flying far from the wings "unrealistic". 19045: identical arcs.
- 19362: wing motion stiff/fake. 19380: "not pretty". 19418: bird-wing motion wrong for butterfly wings. 19481: blurred shadow behind wings. 19502: butterfly flap too fast/heavy.
Avatar, HUD, merchant, frames
- 17027/17041: avatar frame art scaled up with the box (too thick), background outside the frame, slime wrong size.
- 17069: equipment flickering on the avatar-box slime. 17123: LV display, rank/LV explanations, equipped list, control tips - all removed.
- 18471/18485: builder thinned ALL frames - wrong, revert; only the Void frame was too thick. 18543/18559: Void frame still bad / mismatched. 18531: Radiant frame/background misaligned.
- 18507: avatar frame not responsive on small screens.
- 17111: merchant disappears early. 17145/18283/18369: merchant and cart too small / cart out of scale. 18818: merchant carrying the whole catalogue rejected.
World / misc
- 17374/17403: two bushes not Y-sorted (builder first denied it).
- 17413: berry vine frame with straight cut edges.
- 16332: discovered colours shown as grey circles. 16376: dev panel visible in the real game; egg details stale. 16400: no food production in the main game. 13474: ready eggs not hatching until clicked. 15135/17590: World Boss fight stall, full game freeze.
- 15822: jumping mechanic cancelled.
Animated backgrounds (abandoned)
- 20675: builder misunderstood the task. 20810: "ugly". 20884: zooming camera, jerk at loop, too short. 20892: abandoned, both backgrounds back to static.

---

## 4. Working rules the owner set for the builder
- Self-review art against the brief / original / reference before showing it (16073, 19418, 19706, 20532); "review it yourself" (19380).
- Each new design comes only from its own theme; do not reference earlier generated items (15438, 18397).
- Work one item / one group at a time (10694 one mob group first, 18397 one aura set at a time, 20489 secrets in batches, 20843 one background at a time).
- Respect originals: never add details not in the source art; slimes have no legs (20532); keep sizes (20592); restore any originals changed by accident (20677, 20697); animate weapons only from the original image (20376).
- Reuse existing assets when they fit; generate new ones when needed (10300, 10492, 10025).
- Match the existing asset style and balance stats and recipes with any new gear (20004).
- Research advanced techniques for VFX (17450, 18832).
- Owner's technical suggestions are hints, not specs: "I don't know much about programming" (18069).
- Refactors must not change structure or behaviour (19534).
- Wait for all uploads before building from them (18336).
- Owner chose priority order of the animation review: P0 then P1 (19248, 19289).
- Dev-only tools (dev panel, coin grants) must not reach the real game (16376, 19053).

---

## 5. Specs the owner wrote that the code may not show
- **Weapon special skills** (9561): Shield taunt (radius pull), Sword dash, Staff healing ring; one extra for each other weapon, on top of normal AI.
- **Drops** (9902): Boss Essence 5%, Monster Core 10%; normal mobs drop random coins/food/materials; food from mobs (13290); epic gear ~10 runs, mythic ~20 runs of materials (9861); map-specific materials from each of the 4 maps (17319).
- **Level ladder** (10135, 12403): after 10 waves pick replay or next level; first "100% harder, +5% drop", later "500% stronger"; battleground changes every 10 waves; every mob/boss unlocks a stronger unique second attack at level 2 (10694).
- **Bosses**: Greenfield Boar (boss) + Turtle (mini); Mushroom Tree Golem (boss) + Wolf (mini); Volcano Magma Bull (boss) + Wolf (mini); Snowy Peak boss upgraded (10608).
- **Tutorial** (11091): highlight Breeding tab with an arrow -> pick 2 slimes -> Breed -> wait -> Hatch; tip about rare colours; first egg = random base colour + bonus stats; tell them slimes eat -> highlight Farm -> choose Berry Bush -> assign 1 slime; highlight shop NPC (sell extra slimes); highlight blacksmith (craft weapons from siege). Skip button (11223).
- **Farm gating** (11290): start with Berry Bush only (3 workers); Farm Plot 1,000, Fishing Pond 5,000, Cooking Station 10,000 coins; max 12 workers across 4 stations; locked stations unusable; 3 Berry workers should feed up to ~30 slimes, beyond that you must unlock the next station.
- **Achievements** (11831): money earned, slimes hatched, slime level, total food farmed, days played, mobs killed, bosses killed, secret slimes found.
- **Mutation** (12239): dual ~5%, secret ~1%; pity guarantee (14744); new-player luck 5x for 30 min after the tutorial then 3x for 30 min (17715).
- **World Boss** (12403, 12876, 14413): 20-slime team, unequipped slimes body-bounce, unlocked by the max-50-slots upgrade, button visible but locked before that; loot = gold, meat, exclusive crafting materials, rare 10x-mutation injection (dual 50%, secret 10%), rare stat-boost injection (guaranteed random bonus); egg details panel shows parents, possible stats and mutation odds; raid leaderboard (15268).
- **Auto-equip** (14747): highest-level slimes get highest-rarity gear first. **Quick team** (15401): highest level first, for siege and World Boss.
- **Upgrade caps**: Faster Incubation lv 5 (16311); slime slots lv 40 (16904); Faster Growth and Quicker Breeding lv 20 (16905). Upgrade cost curve ~100 -> ~20,000 (17552). Siege tab unlocks when slimes reach level 30 (16884).
- **Art sizing**: hats +50% (15534); faces -20% (15743); secret slimes with protruding features +20% body (Sun Lion, Royal Griffin...), face same size, face and hat 20% lower (15679-15802); weapon and tail on opposite sides, swapping with facing (15699, 15801); weapon idle sway on the farm, attack motions in battle (15824).
- **Avatar slime** (16533): WASD/arrow movement, click to attack/interact, same shape and animations as a normal slime, can recolour to any unlocked colour, own inventory and stats; base 1 ATK / 1 DEF / 1 SPD / 10 HP; levels from slimes hatched, 2 points per level chosen by the player (later: rank per 50 hatches, ~5 points per rank, 16815/17685; scale to match bred slimes, ~33/27/37/191 at 800 slimes, "rebalance later" 17565); slots weapon, hat, tail, backpack + cosmetic wings and aura; joins every battle under player control; top-left box shows its live look.
- **HUD top-left** (16936): avatar box on top at 2x size with frame + background; Customise button next to "Your Avatar" (opens its own window, 17099); remove the "Goo Lineage" title and the egg count; coins, food and slime count shown as icons (siege icons, standard slime image) under the box.
- **Travelling merchant** (16979, 18818): every 15 min, stays 5 min, walks with a moving cart to empty spots; sells frames, backgrounds, wings, auras at 1k-10k; 8 random items per visit with rarity weighting.
- **Smithy** (17249): grid of items with rarity frames; side panel with materials and stats; sorted by order and group (19984, 20344).
- **Highscores** (18282): avatar picture per player; categories: total bred, boss defeat time, strongest, highest DEF, SPD, HP.
- **Reveals** (17714): strong reveal for dual-colour, bigger for secret.
- **Aura specs written by the owner**:
  - The Matrix / Encrypted Code Rain (17913): emerald glow strongest at feet and torso; many falling encrypted glyphs (not readable text), long and short flickering streams, random brightening; code passes behind and in front; green ground projection with rotating hex rings at the feet; glitch pixel break-ups; periodic bright code column; some glyphs orbit briefly; cycle idle -> build-up -> peak -> pulse ring (nearby code freezes) -> dissolve. Later: denser, narrower, no vertical ellipse (18037, 18052).
  - Aurora Veil (17989): tall translucent vertical ribbons that sway and rise, rainbow colour shift (emerald, cyan, blue, violet, pink, gold), overlapping layers, edges dissolve into particles, wraps behind and in front, travelling shimmer, rising sparkles, faint rainbow ground glow; calm and majestic, "not rainbow flames"; additive blending + bloom + vertical gradient ribbons + wave distortion. Tuned: ~30 px above the head, fade at both ends, 30% narrower, then 20 px higher, colour cycling (18570-18605).
  - Night Sky (17837): suspended twinkling stars, occasional shooting star; stars 3x (18230).
  - Rain (17853), Autumn maple leaves (17875), Butterfly (18186, random flight), Thunderstorm (no impact shockwave; owner sprites; cloud 20 px lower), Static Charge (owner's 10 frames, front + back, whole body to the ground, desynced, random pause/blink), Hellfire meteors (one direction, mid-air or ground bursts with small shockwaves and sparks), Blossom Drift (petals of several shapes, few flowers, natural tumbling, some land briefly), Starlight (more stars, no moon), Blizzard (2x flakes, no moon circle), Firefly (3x, more glow).
  - Blazing Ascendant / `aura-blaze` (19675): Dragon-Ball-style layers: core glow, flame shell rising, outer wisps, rising sparks, random lightning, ground ring, heat distortion; from the owner's reference image (19725); sold in the shop with its own icon (19839, 19949).
- **Frames/backgrounds/wings per aura theme** (18397, 18832, 18885): one set per aura, thin elegant frames, wings of any material with themed particle layers; back translucent pair flaps in sync.
- **Localisation** (19126): EN default + Japanese, browser-language detection, selector in Settings, saved in the save file; icons with tooltips; >= 44 px touch targets.
- **Requested but never finished / abandoned**:
  - Animated backgrounds (20592-20892): abandoned, reverted to static. Frame animation dropped (20620).
  - Secret-slime body animation (20489-20532): reverted to static originals (20697).
  - Jumping mechanic: cancelled (15822).
  - Avatar stat curve: "we will rebalance that later" (17565).
  - Animation review P0/P1 (19102-19289): P0 and P1 were started; later priorities not mentioned.
  - Dragon-Ball flame aura reached the shop as Blazing Ascendant; the first attempt failed the brief (19706).
  - Japanese localisation and the code refactor (19126, 19534) were requested; completion not confirmed in the owner's messages.
  - "Add debuffs for enemies" (13914), Snowy Peak level-2 kit (11020) - requested, outcome not visible in messages.

---

## 6. Uploaded art (owner) and requested generation
Owner uploads
- 9688-9689: Volcano mobs incl. Magma Bull (boss) and Wolf (mini-boss).
- 10300-10301: Greenfield mobs incl. Boar (boss) and Turtle (mini-boss).
- 10492-10493: Dark Forest / Mushroom mobs incl. Tree Golem (boss) and Wolf (mini-boss).
- 12403: the first World Boss image. 12935: World Boss minions.
- 13073: screenshot of a helmet on a slime (fit problem).
- 13710: updated Flame Corona aura image.
- 16979: travelling merchant (slime + cart).
- 17403: screenshot of the two non-Y-sorted bushes.
- 18229: real aurora reference photo.
- 18336/18338: Static Charge animation, 10 frames (two batches of 5).
- 18507: screenshot of the oversized avatar frame on a small screen.
- 18619: preferred lightning-strike samples; 18634 and 18684: lightning sprite sheets for Thunderstorm.
- 19725: reference image for the Dragon-Ball-style flame aura (Blazing Ascendant).
Asked to generate
- New mob/boss assets and skill FX (10025, 10300, 10492, 10694); special loot art for World Boss drops (14413); separate per-element area-FX art (16073); straight-on unique hats (15438); thinner frames sized to the avatar box (17041); full Common-Mythic equipment set (17175); frames + backgrounds per aura theme (18397, 18695-18766); themed wings incl. non-feather (18832, 18885), new Void wings (18928), new Stormcloud wings and arc variants (19005-19045); soap bubbles for Tidewater (18975); maple leaves, sakura petal variants, butterflies (17624, 17875, 18186); shop icon for Blazing Ascendant (19839); 10 heads + 10 tails (20004, art later judged off-style, 20144); animated Mythic Focus, then all Mythic and Epic weapons (20376-20452, liked); AI-video animated backgrounds (20752, abandoned).
