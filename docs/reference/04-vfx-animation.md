# 04 - VFX and animation catalogue (Goo Lineage web -> Roblox)

Source: `reference/goo-lineage-web/` (reference data only, never executed). Every number below is copied
from the code; file names are given so a builder can re-check. Read the **User vetoes** section at the end
before building anything.

## 0. Conventions used in this document

- **bw** = the slime's body width. Web value: `SLIME_WIDTH = 67` logical px on the farm, 40 px in battle.
  In Roblox, pick one stud value for bw (the slime model's body width) and scale everything from it.
  `R = 1.25 bw` (aura radius used by fancyAura).
- Web y grows DOWN. "Up 1.1 bw" in this doc already means up in world space.
- **groundY** = the shadow centre under the feet (auras and rings are grounded there, not on the bouncing body).
- Blend: **ADD** = additive (Roblox: `LightEmission = 1`, `LightInfluence = 0`), **NORMAL** = alpha blend
  (`LightEmission = 0`).
- "deterministic in T" = the web draws every particle as a pure function of time (no RNG). In Roblox this
  does not need to be copied literally: GPU ParticleEmitters are cheaper than Lua-moved parts. Only the few
  choreographed elements (orbits, meteors, butterflies, bolts) need script-driven CFrames.
- Phone cost tags: **[cheap]** < 20 live particles / no per-frame Lua, **[mid]** 20-80 particles or a few
  per-frame CFrame writes, **[heavy]** > 80 particles, big translucent overdraw, or many per-frame writes.
- Roblox engine facts relied on (Creator Hub): emitters top out about 100 particles/s on mobile; flipbook
  grids are 2x2 / 4x4 / 8x8 only (`FlipbookLayout`), speed via `FlipbookFramerate`, `FlipbookMode`
  Loop / OneShot / PingPong / Random; Beams/Trails need two attachments; Highlight max ~255 per client.

---

## 1. The FX runtime (`@makeplay/fx`) and how the game calls it

The package itself is NOT in the download (only `game.js` imports it), so preset internals are unknown;
only names and parameters are visible.

Setup (`game.js` 127): `createPixiFx({ PIXI, app, world: fxLayer, screen: fxScreen, referenceSpan: SLIME_WIDTH, onImpulse })`.
- `fxLayer` lives inside the farm `worldRoot`; `fxScreen` is a screen-space layer.
- `referenceSpan = 67` -> presets are sized relative to one slime width.
- `fx.update(realDt)` is called once per frame and **returns a timeScale**; the farm sim runs on
  `realDt * timeScale` (so the runtime can freeze the sim for a hit-stop).
- `onImpulse(next)` delivers `{ offsetX, offsetY, roll, fovPunch }`. The game applies only the offsets:
  farm `worldRoot += offset * 6 px`, battle root `+= offset * 12 px`; both skipped under reduced motion.
  `roll` and `fovPunch` are unused (2D).

Calls in the code (complete list):

| Effect name | Call | Where / trigger | Params |
|---|---|---|---|
| `land-dust` | `fx.play` | every farm slime landing (`game.js` 1307) | `pos` feet, `power 0.5` (no sound - user) |
| `land-dust` | `fx.play` | slime placed / escorted arrival (`game.js` 1734) | `power 0.4` |
| `pickup-pop` | `fx.play` | egg nest actions: collect/hatch/breed (`gameActions.js` 114-164) | `pos` EGG_NEST, `power 0.6-0.7` |
| `fire-sparks` | `fx.play` | blacksmith hammer hits anvil (once per 1.43 s cycle) | `pos` anvil face, `dir {0.15,-0.99}`, `power 0.55`, `scale 0.45` |
| `fire-sparks` | `fx.play` | furnace embers, one every 1.4-2.4 s | random +-10 px x, dir +-35 deg around up, `power 0.28`, `scale 0.3` |
| `fire-candle` | `fx.start` / `fx.stop` | furnace mouth, continuous, restarted every 285 s | `duration 290`, `power 0.5`, `scale 0.8` |
| `heavy-hit` | `fx.play` | battle camera punch (`hooks.impulse(power)`), visual placed off-screen at centre so only its camera impulse is used | `power` 0..1 from tables below |

Roblox build:
- `land-dust`: one shared ParticleEmitter (Rate 0) on a pooled ground attachment; `:Emit(4-6)` small
  grey-beige puffs, Speed 1-2 studs/s outward, Drag 4, Lifetime 0.35-0.5, Size 0.3->0.6 bw, Transparency
  0.4->1. Low tier: Emit(2). **[cheap]** - but it fires on EVERY hop of every slime: cap at ~6 emits/s
  farm-wide and skip slimes > 60 studs from the camera.
- `pickup-pop`: Emit 8 sparkles + a 0.25 s scale-pop of the egg (TweenService Back-Out). **[cheap]**
- `fire-sparks`: emitter with `Orientation = VelocityParallel` streaks, Acceleration (0,-30,0), Lifetime
  0.3-0.6, Emit(6-10 x power). **[cheap]**
- `fire-candle`: looping fire emitter (flipbook fire) + 1 tiny PointLight (Range 6). **[cheap]**
- `heavy-hit` impulse: see section 9 (camera shake module). Build ONE CameraShake client module; nothing
  else may move the camera (AGENTS veto: "FX OWNS camera shake - NO hand-written shake").

---

## 2. Farm slime body animation (`slimeRenderer.js`, `config.js`, `slime.js`)

Layer stack per slime: shadow ellipse (26x8 px radius, alpha 0.55) -> bodyWrap { equipBackWrap (wings,
behind-body gear), body sprite (anchor 0.5, 0.94), faceWrap (face PNG), equipWrap (hat/weapon/tail) } -> name
plate (selected only). Body art is STATIC (see vetoes).

| Animation | Trigger | Look | Numbers | Easing |
|---|---|---|---|---|
| Idle breathe | phase `idle` | soft vertical pulse | `sy = 1 + 0.025 sin(2pi*1.4 t + phase)`, `sx = 1 - 0.0175 sin(...)`; phase de-synced per slime (seed) | sine |
| Hop: compress | before each hop | **no body squash** (user) - shadow only | 0.12 s, shadow scale 1 -> 1.08 | easeOutCubic |
| Hop: air | airborne | stretch follows the arc, lift | dur 0.38-0.48 s; stretch = 0.10 x amplitude x sin(pi t); `sy = 1 + stretch`, `sx = 1 - 0.6 stretch`; lift = sin(pi t) x 26 px x amplitude; shadow scale 1 - 0.35 sin(pi t), alpha 0.55(1 - 0.5 sin(pi t)) | sine arc |
| Hop: land | touchdown | **no landing squash** (user) - shadow settles + `land-dust` | 0.14 s, shadow 1.3 -> 1 | linear |
| Wander | AI | hop chains toward a target | speed 24-32 px/s, think 2.5-5 s idle between targets, target radius 260 px, min 48 px | - |
| Selection hop | tap select | visual-only hop in place | 0.55 s; lift sin(pi t) x 26 x 1.15; `sy *= 1 + 0.08 sin(pi t)`; emotion forced to `exciting` | sine |
| Facing turn | moving | smooth flip, never snaps | `facing += (dir - facing) * 0.18` per frame, |facing| >= 0.2 | exp lerp |
| Blink | idle only | **FACE ONLY** eyelid squash | every 3.5-6 s (per slime), lasts 0.12 s, faceWrap scaleY = 0.12 | step |
| Emotion swap pop | face texture changes | face micro-swell | 150 ms, scale 1 + 0.08 sin(pi t/0.15) | sine |
| Growth | age | hatchling grows | scale 0.62 -> 1.0 over 300 s (+1 s per level) | linear |
| Body boost | secret slimes | body x1.2, face counter-scaled 1/1.2, face & hat 20% lower | - | - |
| Fallen ghost | fallen slime on farm | half transparent | bodyWrap alpha 0.5 | - |
| Name plate | selected | bold text, dark stroke | 20 pt, stroke 4 | - |
| Reduced motion | setting | no breathe/blink; bounces x0.45, lift x0.4 | - | - |

Roblox build:
- Slime = one skinned MeshPart body (static art look; no body flipbook - veto) + a face part.
  Squash/stretch without resizing parts: author the body with a `Root` bone at the feet, a `Top` bone
  and two side bones; stretch = move `Top` up/down (sy) and the side bones in/out (sx). Pure
  `Bone.Transform` writes - cheap, and the feet stay planted. (Tweening `MeshPart.Size` per frame for
  30 slimes is the expensive alternative; avoid it.)
- Drive all farm slimes from ONE client Heartbeat loop (no per-slime scripts). Far slimes (> 80 studs):
  update at 15 Hz; off-screen: skip.
- Hop arc: position Y offset of the visual model only; the server owns the logical XZ position.
- Shadow: a flat decal-on-part (or a single ParticleEmitter-free `Decal` on a 0.05-stud part) whose Size
  tweens with the arc. **[cheap]**
- Blink: face is a `SurfaceGui` -> `ImageLabel` (AnchorPoint 0.5,0.5); blink = Size.Y.Scale 1 -> 0.12 -> 1
  in 0.12 s. Never scale the body for a blink. **[cheap]**
- Emotion pop: `UIScale` on the face ImageLabel 1 -> 1.08 -> 1 over 0.15 s. **[cheap]**

---

## 3. Emotions (`emotions.js`) and talk bubbles (`talkBubbles.js`, `farmPanel.js`)

Faces: 9 user PNGs (`assets/slime.emotion.<id>.png`, all present): normal, admiring (star eyes),
exciting (> < eyes + open grin), loved (heart eyes), sleep (closed lids), angry (slanted brows + frown),
dare (raised brow + smirk), sad (droopy eyes + tears), surprise (O mouth). Face colour deep navy `#1a2f6e`.
Face size 0.64 x SLIME_WIDTH, centred at 0.51 x body height above the feet.

Resolver priority (first match wins): starving -> sleep; favourite+selected or bred < 20 s ago -> loved;
selection hop -> exciting; age < 15 s -> exciting; job hint (argue: opener angry, retort dare); hungry ->
sad; talk line with `!` -> exciting, `♪` -> surprise, `❤/★` -> admiring; near a favourite (< 150 px) ->
admiring; else ambient mood. Escorted (nest-bound) parents: loved the whole walk.
Ambient mood: picked for 2-4.5 s, then a quiet gap. Adult: 50% normal, 15% admiring, 13% surprise,
12% dare, 6% exciting, 4% sleep. Baby (< 5 min): 40 normal, 20 exciting, 15 surprise, 13 admiring, 12 dare.

Talk bubbles (workstation crews in the farm panel): first line after 2-7 s; shown 2.4-3.8 s; quiet gap
5-14 s; 8% pure emote (`♪ ❤ ! … ★`), ~64% job line, rest general banter; 10% chance of a two-line argue
(retort forced on a crewmate 1.4-2.2 s later). Bubble: cream `#fffdf4`, 2 px brown `#7a5230` border,
radius 9, 10.5 px text, small down-pointing tail. Worker sprite bob `gooWork` 1.6 s loop: scale
(1.07, 0.92) at 45%, (0.97, 1.05) at 70%, bottom-anchored.

Breeding hearts (`game.js` 1692): while parents walk to the nest, every 0.45 s one heart above a random
parent: scale 0.45, alpha 0.5, spawn x +-10 px, rises 26 px/s, life 1.4 s, alpha 0.5(1 - k^2), scale 0.45 -> 0.6.

Roblox build:
- Faces: 9 decal ids swapped on the face ImageLabel; resolver runs client-side on the same priority table.
- Talk bubble: `BillboardGui` (AlwaysOnTop false, MaxDistance 60) with TextLabel + `UICorner` 9 +
  `UIStroke` + a tail ImageLabel; pop-in UIScale 0.85 -> 1 over 0.12 s Back-Out. Only crews near the
  camera talk. **[cheap]**
- Hearts: ParticleEmitter on the parent's head attachment, Rate 2.2, Lifetime 1.4, Speed 1 bw/s up,
  Size 0.45 -> 0.6 (relative), Transparency 0.5 -> 1 (quadratic), LightEmission 0. **[cheap]**

---

## 4. Avatar cosmetics: equip fade, plain aura (`avatarCosmetics.js`)

Auras and wings are **avatar-only** cosmetics (the player's own slime, id `avatar`).
- Equip fade (P0): every cosmetic summons in over 0.3 s, ease-out quad, alpha 0 -> 1 and scale 0.85 -> 1.
- Aura is GROUNDED on the view root (does not bounce or breathe with the body); back layer behind the
  body, front layer in front; layer centre at -0.45 bw; mirrored with facing.
- Plain aura fallback (aura id with no layer art): additive equip icon, 2.4 bw wide, rotates 0.3 rad/s,
  breathes x(1 + 0.08 sin 2.2t), alpha 0.95 +- 0.05.
- Backpack: sprite 0.62 bw at (-0.4 bw, -0.5 bw), behind the body.
- Battle copy (`battle/scene.js` 740): wings span 77 px for a 40 px body; fancy aura size 40; plain aura 96 px.

Roblox: one `CosmeticsController` per visible avatar. Fade = Transparency NumberSequence offset is not
tweenable, so fade emitters by scaling `Rate` 0 -> full over 0.3 s and Beams by `Transparency` swaps
(4 steps). Scale-in by tweening the cosmetic root attachment's offset scale (or `Model:ScaleTo` on the
wings model 0.85 -> 1).

---

## 5. Fancy auras (`fancyAura.js`) - all 15 archetypes

16 aura items map onto 15 motion styles (`radiant` is shared by Sun and Void; `flame` is a legacy style
no current item uses). Common facts: `size = bw`, `R = 1.25 bw`; all layers are sprites with ADD blend
unless stated (fall/leaves/fireflies/butterfly motes are NORMAL); depth = a sprite moves between the
back and front container by the sign of its orbit angle. **Ground glow disc is removed for every aura
except Code Rain** (user veto). Phase de-sync per avatar.

General Roblox recipe for an aura: an `AuraRig` Model welded to the avatar root (not the bouncing body),
containing (a) 2-6 ParticleEmitters on attachments, (b) at most ~12 script-moved parts/attachments for
choreographed elements, (c) optional Beams. One client loop updates all visible auras; LOD: full detail
< 40 studs, rates x0.5 40-100 studs, off beyond 100 studs or off-screen. Low tier halves rates and drops
"bloom" / secondary layers.

### 5.1 Radiant - `aura-sun`, `aura-void`
- Art: `fx-aura-rays-{sun,void}.png` (spoked ray wheel on black), `fx-aura-halo-{sun,void}.png`,
  motes `battlefx-mote-heal` (sun) / `battlefx-mote-arcane` (void), glow = equip icon.
- Look: breathing glow + two counter-rotating ray wheels + a pulsing halo with an outward pulse wave +
  8 orbiting motes (front/back) + 6 rising embers.
- Numbers: glow 2R x (1 + 0.07 sin 1.6T), alpha 0.85 +- 0.15, spins 0.15 rad/s. Rays A 2.3R, +0.35 rad/s,
  alpha 0.55 +- 0.2 (2.3 rad/s). Rays B 2.0R x 1.4R (ellipse), -0.55 rad/s, alpha 0.45 +- 0.2. Halo 1.6R
  x (1 + 0.06 sin 3.1T), alpha 0.9. Pulse wave: every 2.6 s grows 1.6R -> 3.2R, fades in 8% then out by 78%.
  Motes: 8 on a 0.95R ellipse (squash 0.35), 1.1 rad/s, size 0.16-0.26 bw by depth, alpha 0.55-1.
  Embers: 6, life 1.8 s, rise 1.1 bw, size 0.11 bw shrinking 50%, fade in 15% / out 85%.
- Roblox: rays = 2 ParticleEmitters with 1 long-lived particle each (Lifetime 20, Rate 0.05, `Emit(1)` at
  spawn, `RotSpeed` 20 deg/s and -31 deg/s, `LockedToPart`, `LightEmission 1`; black background art is
  fine under additive) - or 2 `BillboardGui` ImageLabels rotated by script. Halo + pulse = one emitter,
  Rate 1/2.6, Lifetime 2.6, Size curve 1.6R -> 3.2R, Transparency 0 -> 1. Motes: one attachment spun
  each frame with 8 child attachments, each holding a tiny always-on emitter (or 8 small Neon-free
  billboard parts). Embers: emitter Rate 3.3, Lifetime 1.8, Speed up. **[mid]** (overdraw from 3 big
  additive discs - keep ray wheels <= 2.3R and Transparency >= 0.4 on phones).

### 5.2 Orbit - `aura-starlight`
- Art: `fx-comet-star.png` (comet with tail streaking LEFT). 12 comets, no ground glow (user).
- Look: comets circle the body on two tilted rings in opposite directions, passing in front and behind,
  each pointing along its motion; rings "breathe" with organic jitter.
- Numbers: ring 0 tilt 0.35, lean 0.25 rad, speed +1.4 rad/s, radius 1.05R; ring 1 tilt 0.6, lean -0.4,
  speed -1.0, radius 0.8R. Jitter +-0.16 rad phase, +-10% radius, +-14% tilt (incommensurate sines 0.53,
  1.21, 0.71 rad/s). Size 0.22-0.34 bw (x1.6 wide), alpha 0.6-1 by depth. Centre -0.45 bw.
- Roblox: two ring attachments rotated each frame (tilt via CFrame), 6 child attachments each; each comet
  = one attachment pair + a **Trail** (Lifetime 0.25, WidthScale taper, LightEmission 1) plus a single
  sparkle emitter per ring for the head glints. 2 CFrame writes per frame (rings), children follow free.
  **[mid]**

### 5.3 Fall - `aura-blossom`, `aura-blizzard`
- Art: blossom = `fx-petals/frame-00..04` + every 5th particle `frame-05` (whole flower) (user: mostly
  petals, a few flowers); blizzard = `fx-snowflake.png`. NORMAL blend. 15 / 16 particles, moteScale 2.1 / 2.
  No ground glow and no embers for these two (user).
- Look: particles drift down from above the head with sideways sway and spin, fading at the ground.
- Numbers: life 3.2 s (clock x0.9), top -1.9 bw -> feet; x spread +-1.1R, sway +-0.16 bw (1.6 rad/s);
  size 0.128 bw x moteScale (20% smaller than an earlier pass - user); spin 1.2 +- 0.3 rad/s; fade in 10%,
  out last 15%.
- Roblox: one ParticleEmitter on a disc part above the head (Shape Disc or a 2.2R box), Rate ~5, Lifetime
  3.5, Speed 0.6 bw/s down, Acceleration small, `RotSpeed` 60-80 deg/s, Transparency in/out. Petals: the
  5 petal frames + flower in a **4x4 atlas with FlipbookMode Random** (one random frame per
  particle; fill the 16 cells with ~13 petal cells and ~3 flower cells to keep the 4:1 ratio). Sway: `Drag` + small
  `SpreadAngle`, or a second emitter with opposite wind. **[cheap]**

### 5.4 Veil (Aurora Sky Veil v3) - `aura-aurora`
- Art: `fx-aurora-curtain-a/b.png` (striated **neutral grey** curtains - the tint owns the colour),
  flecks `battlefx-mote-heal`, ground reflection `battlefx-ring-heal`.
- Look: 5 tall translucent curtains in an arc behind/around the slime (one small front curtain that
  comes and goes), fabric rippling, each cycling the full rainbow; 5 additive "bloom" copies make the
  colours glow; 14 rainbow flecks float up; a faint rainbow reflection on the ground.
- Numbers: 12 s cycle envelope: idle 0-3 s (env 0) -> build 3-6 s -> aurora wave 6-8 s (a bright band
  sweeps left->right, `waveP`) -> peak 8-9.5 s (+35% swell) -> settle 9.5-12 s. Curtains [x, base y, width,
  height, alpha, phase]: [0, .05, 2.25, 1.55, .6, 0], [-.63R, .08, 1.6, 1.4, .55, 1.7], [.56R, .1, 1.55,
  1.35, .6, 3.1], [-.21R, .12, 1.25, 1.25, .55, 4.4], [.18R, .15, 1.0, 1.1, .4, 5.6] (bw units); tops about
  30 px above the head, lifted ~20 px (user). Width x(0.9 + 0.2 env), height x(0.85 + 0.3 env); bloom copies
  x1.08/1.06, alpha 0.35. Curtain alpha = depthA x 1.25 x (0.7 + 0.3 env). Mesh 14x6 vertices: ripple
  sin(6.5u + 1.4T) x (0.03 + 0.11 top) + sin(13u - 2.3T) x 0.025 top; sway 0.06; wave band width 0.25,
  amp 0.08. Tint = 9-stop rainbow `ff6b6b ffb347 fff36b 6bff8a 5ee6ff 6b8cff b36bff ff6bd8`, ~6 s per
  full rainbow (`T*0.16`), curtains offset 0.2 of the wheel. Flecks: 14, life 3.6 s, rise 2 bw, size 0.05 bw,
  alpha sin(pi p) x (0.5 + 0.4 env). Ground ring 2.6R x 0.42, alpha 0.16 + 0.1 env.
- Why NORMAL + bloom: additive-only curtains whited out on the daylit farm (user); keep NORMAL main
  layer + low-alpha ADD copy.
- Roblox: **Beams** are the right tool. Each curtain = a vertical Beam (Attachment0 at the feet,
  Attachment1 at the curtain top) with `Width0/Width1` =
  curtain width, `FaceCamera false`, `Segments 10`, `CurveSize0/1` animated by script for the sway/ripple,
  `TextureMode Stretch`, `TextureSpeed` 0.05 for the shimmer band, `LightEmission 0`, `Color` = a
  ColorSequence rewritten ~10 times/s from the rainbow table. Bloom = a second Beam per curtain with
  `LightEmission 1`, Transparency 0.65. 5 + 5 beams, 10 attachment pairs, 2 property writes per beam per
  frame -> **[mid]**; Low tier: drop the 5 bloom beams and the front curtain, update colour at 4 Hz.
  Flecks: one emitter (Rate 4, Lifetime 3.6, rainbow ColorSequence). Ground reflection: one flat decal part.

### 5.5 Night Sky - `aura-nightsky`
- Art: stars `battlefx-spark-star.png` (18), shooting stars `fx-comet-star.png` (2). No ground disc (user).
- Look: stars hang in a loose shell around the body, each twinkling on its own rhythm with rare sharp
  flashes; two shooting stars streak upper-left -> lower-right now and then.
- Numbers: shell radius 1.25-1.6R, height -0.55 bw +- 0.75 bw, drift 0.03 bw; twinkle 0.55 +- 0.45 at
  1.1-2.45 rad/s; flash when sin > 0.96 (x0.8 size, +0.4 alpha); base size 0.21 bw x (0.6-1.0) (3x - user).
  Shooting star: cycle 7.5 s (offset 3.9 s), visible 14% (~1.05 s), travels 4.8R wide x 0.55 bw drop,
  0.75 x 0.14 bw, fade in 15% / out 30%.
- Roblox: 18 fixed attachments on the rig, one emitter each is too many -> use ONE emitter with
  `Shape = Sphere` (in a small invisible part), Rate 6, Lifetime 3, Speed 0, Size curve with two bumps
  (twinkle), `LockedToPart true`; shooting star = one attachment tweened across + Trail (Lifetime 0.3).
  **[cheap]**

### 5.6 Rain Veil - `aura-rain`
- Art: `fx-rain-cloud.png`, streak `fx-rain-streak.png` (22), ripple `battlefx-ring-ice.png`, droplet
  `battlefx-mote-ice.png`. No ground disc (user).
- Look: a storm cloud hovers above (rare faint lightning flicker), rain falls at a slant; ~35% land on the
  slime's crown (droplet burst), the rest hit the ground ellipse -> flat ripple ring + 3 droplets hopping up.
- Numbers: cloud at -2.05 bw, 1.9 bw wide x0.6, drifts +-0.08 bw (0.4 rad/s), bobs 0.04 bw; flicker when
  sin(0.7T + 1.2) > 0.985 -> tint `dde8ff`. Drop cycle 0.9 s (clock x1.15), falls 55% of it, slant 0.18,
  streak 0.045 x 0.36-0.46 bw, alpha 0.85. Ripple 0.12 -> 0.67 bw (x0.38 flat), alpha 0.7 -> 0. Droplets:
  3 per hit, fan -0.25..-0.75 pi, speed 0.35 bw (body) / 0.5 bw (ground), gravity 1.4 bw, size 0.07 bw.
- Roblox: cloud = billboard ImageLabel (or a single long-life particle); rain = emitter under the cloud,
  `Orientation VelocityParallel`, Speed 4 bw/s, slanted `EmissionDirection` + 10 deg, Lifetime 0.5, Rate 24.
  Ripples + splashes: a second emitter on a ground disc part (Shape Disc, flat orientation via
  `Orientation = VelocityPerpendicular` with Speed 0.01 up) Rate 14, Lifetime 0.4, Size 0.12 -> 0.67 bw;
  crown splash emitter Rate 6. No per-drop Lua. **[mid]** (keep streak Size tiny; rain overdraw is low).

### 5.7 Autumn Whisper - `aura-autumn`
- Art: `fx-leaves/frame-00..04` maple leaves + rare `frame-05` (every 5th), golden sparks
  `battlefx-spark-star.png` (12). NORMAL leaves. Leaf tints `ffffff ffe6c8 ffd9a0 fff1d6`.
- Look: leaves tumble down with a 3D flip (width squash) and zig-zag glide; in the last 38% of the fall
  a low vortex catches them and spirals them around the feet, then they dissolve into golden sparks that
  drift up.
- Numbers: 16 leaves, life 4.6 s (clock x0.8), from -2.0 bw, x spread 1.3R, glide +-0.28 bw + zig-zag
  0.12 bw, size 0.30 bw; flip rate 1.6 +- 0.6 rad/s (width 25-100%); swirl: 2.2 turns, radius 1.25R -> 0.8R,
  lift 0.35 bw at the end, fade over the last 30%. Sparks: 12, life 2.2 s, rise 0.9 bw on a 0.9R ring, tint
  `ffd070`, size 0.07 bw.
- Roblox: falling leaves = emitter (Random-frame 4x4 atlas, `RotSpeed`, slight Drag) for the drift; the
  vortex = a second emitter on a ground ring attachment that **spins** (rotate the attachment each frame,
  `LockedToPart true` so particles orbit), Lifetime 1.7, Size 0.3 bw shrinking, then sparks emitter at the
  feet (Rate 5, LightEmission 1, tint gold). 3D flip comes for free if leaves are 3D-oriented
  (`Orientation = VelocityPerpendicular`) - the flat card turning reads as a tumble. **[cheap-mid]**

### 5.8 Firefly Glade - `aura-firefly`
- Art: `fx-firefly.png` (14, additive, tint `eaffc0`), pollen `battlefx-mote-heal` (10, tint `d8ff9a`).
- Look: fireflies rise lazily from the grass around the feet on wandering figure-8 paths, each glow
  pulsing bright -> dim -> dark gap like real fireflies; faint pollen drifts.
- Numbers: life 5.5 s (clock x0.7), rise 1.7 bw, ring radius 0.7-1.3R x (0.75-1.25), wander +-0.22 bw
  x, +-0.08 bw y; per-cycle hash re-picks anchor/radius/pace; pulse: bright for 1.3 rad of a 2pi cycle
  (0.55-1.0), else 0.2 floor ("brighter floor" - user); size 0.33 bw (3x - user); faces its drift
  direction. Pollen: 10, life 4 s, 0.035 bw, alpha <= 0.45.
- Roblox: emitter on a ground ring (Shape Cylinder in a flat part), Rate 2.5, Lifetime 5.5, Speed 0.3
  bw/s up, `Drag 0.5`, random `SpreadAngle 40`, Size NumberSequence with 2-3 bright bumps and dark gaps
  (fakes the pulse; vary by `FlipbookStartRandom`-style random lifetime), LightEmission 1. Optional 1
  PointLight (Range 4, Brightness 0.6) on the rig, High tier only. **[cheap]**

### 5.9 Encrypted Code Rain - `aura-coderain` (the ONLY aura with a ground disc)
- Art: `fx-glyphs/frame-00..15` (16 glyphs; download only has 00 and 03), hex ring `fx-hex-ring.png`,
  pulse ring `battlefx-ring-heal`, pixels `battlefx-mote-heal`. Colours: green `39ff88`, dim `1d8f4c`,
  white `d8ffe8`.
- Look: 12 glyph streams x 4 glyphs fall through the body (half behind, half in front) within the body's
  own width (user: tight); 10 s cycle idle (sparse) -> build -> peak (dense, bright, glitch pixels) ->
  pulse (hex ring expands, code FREEZES) -> dissolve. Ground: green glow disc + two counter-wobbling hex
  rings + 6 rapidly swapping ground symbols; 6 fragments orbit the torso and get pulled down.
- Numbers: intensity 0.3 (0-2 s) -> 1 (4.5 s) -> hold -> pulse 7-7.8 s -> 1 -> 0.3 by 10 s. Streams
  x = +-0.55 bw, fall from -2.3 bw to feet+0.1, life 2.6/speed (speed 0.9-1.4), glyph spacing 0.11 of the
  cycle, head glyph green, tail dim, alpha 1/0.63/0.51/0.39; random scan flash to white; 2 of 3 streams
  continuous, 1 of 3 bursty. Glyph 0.13 bw. Disc 2.4R x 1.0R, alpha 0.35-0.75. Hex rings 2.0R / 2.5R wide
  x0.42, wobble +-0.08 rad, second mirrored. Pulse ring 0.5 -> 3.7 bw over 0.8 s. Ground symbols swap
  at 6 Hz. Glitch pixels 12, only at peak, flicker 20 Hz. The vertical light column was REMOVED (user).
- Roblox: streams = 2 emitters (front/back planes) with a glyph 4x4 atlas `FlipbookMode Random`,
  Speed 1.5 bw/s down, Lifetime 1.6, Rate scaled by a script envelope (Rate is cheap to write 10x/s);
  "freeze" = set the emitters' `TimeScale = 0` for 0.8 s (ParticleEmitter.TimeScale). Ground disc + hex
  rings = 3 flat decal parts (rings rotate slowly by script). Pulse ring: one emitter Emit(1) at 7 s.
  Glitch pixels: emitter Rate 15 only during peak. **[mid]** - the web uses 96 glyph sprites; Roblox
  target <= 40 live glyphs.

### 5.10 Thunderstorm - `aura-thunder`
- Art: `fx-bolts/frame-00..04` = **USER sprite sheet, byte-identical** (download has frame-00 only),
  storm cloud `fx-storm-cloud.png` x2, drizzle `fx-rain-streak.png` (10). Shock rings / spark flecks are
  allocated but switched off (user: "no shock ring / explosion").
- Look: two dark clouds overhead flash from inside just before each strike; 4 bolts on staggered loops
  strike the ground ellipse or the crown, flickering; faint drizzle.
- Numbers: bolt cycle 3.1 s each (4 bolts offset by 1.37 x life/4) -> ~1.3 strikes/s overall; strike
  window 14% = 0.43 s; frame map over the strike: 0-10% frame 1 (leader from cloud), 10-20% frame 0 (tip
  at ground), 20-55% frame 2 (full strike, flicker to 0.7 at 45 Hz), 55-80% frame 3 (fading), 80-100%
  frame 4 (thin tail, alpha 0.7); jitter +-0.01 bw at 40 Hz; 30% land on the crown (-0.9 bw); bolt height
  2.1 bw + land offset, width keeps art aspect x1.15, random mirror. Clouds at +-0.45 bw, -1.75/-1.87 bw,
  1.5/1.25 bw wide; tint `8a84b8` during the last 10% before a strike, `bfb5ff` flashing at 25 Hz during
  it. Drizzle 10 streaks, life 0.8 s, 0.03 x 0.25 bw, alpha <= 0.4, tint `b0b8ff`.
- Roblox: each bolt = a ParticleEmitter (Rate 0) with the 5 frames packed into a **2x2 is too small ->
  use a 4x4 atlas whose 16 cells encode the timing** (cells: 1,0,2,2,2,2,2,2,3,3,3,3,4,4,4,4 approx),
  `FlipbookMode OneShot`, `FlipbookFramerate 37`, Lifetime 0.43, Size = bolt height, `Orientation
  FacingCameraWorldUp`, LightEmission 1; script calls `:Emit(1)` at a random point every ~0.75 s. Cloud
  flash = cloud ImageLabel `ImageColor3` set for 0.43 s (slow the 25 Hz flicker to <= 8 Hz for comfort).
  Optional PointLight flash (High tier, Range 8, 0.1 s). **[cheap]**

### 5.11 Static Charge v2 - `aura-electric`
- Art: `fx-static/frame-00..09` = **the user's 10-frame arc flipbook, byte-identical** (download has 00
  and 02). No particles (user removed the spark bursts).
- Look: arcs crackle across the whole body front and back, wrapping it from the feet past the crown; the
  two layers run on independent clocks, each sometimes holds a frame and blinks.
- Numbers: 14 fps; front cycle 3.7 s, back 5.0 s; the last 0.35 s of each cycle holds one frame and blinks
  at 24 Hz (alpha 1 / 0.25); frame offset jumps by 4 each cycle; box 1.6 bw x 1.45 bw anchored at the feet;
  back mirrored, alpha front 1 / back 0.75; additive.
- Roblox: 2 ParticleEmitters with 1 particle each (Lifetime = cycle, `LockedToPart`), a 4x4 atlas holding
  the 10 frames + 6 repeats, `FlipbookMode Loop`, `FlipbookFramerate 14`, Size 1.6 bw. Or 2 BillboardGui
  ImageLabels stepping `ImageRectOffset` at 14 fps from one loop (exact frame control, includes the hold).
  The 24 Hz blink: reduce to a 2-step dim on Low tier. **[cheap]**

### 5.12 Butterfly Flutter - `aura-butterfly`
- Art: `fx-wings/frame-00..05` (6 colourful single wings; download has 00), sparkles
  `battlefx-spark-star` tint `fff2b0` (6). NORMAL wings.
- Look: 8 butterflies, each two wing halves hinged at the body seam with a real fold flap, wander freely
  (not circling - user) around the body on never-repeating paths, bank into turns, face travel direction,
  slowly swap front/back; sparkles trail.
- Numbers: path = sum of 3 sines per axis (0.37/0.91/1.73 and 0.29/0.83/1.51 rad/s), x range 1.5R,
  y -0.7 bw +- 0.9 bw; burst-and-glide: 2.2 s cycle, 0.9 s burst (flap 14 rad/s, bob up 0.12 bw) then glide
  (flap 4.5 rad/s, sink 0.06 bw); fold = 0.15 + 0.85 |cos(flap)|; wing 0.17 bw tall x 1.15; bank +-0.4 rad;
  back alpha 0.8. Sparkles: 6, life 1.6 s, fall 0.25 bw under a butterfly, 0.05 bw.
- Roblox: 8 tiny models (2 wing planes on a hinge each) moved by one loop with `workspace:BulkMoveTo`;
  flap = hinge rotation about the body axis (3D does the fold naturally). Low tier: 4 butterflies, flap
  at 15 Hz updates. Sparkle: 1 emitter, Rate 4. **[mid]** (16 CFrame writes per frame).

### 5.13 Hellfire (meteor) - `aura-hellfire`
- Art: `fx-meteor.png` (5), impact ring `battlefx-ring-shock`, flecks `battlefx-spark-star` (4 per
  meteor). No ground disc (user).
- Look: meteors streak down diagonally (all from the upper-LEFT, same direction, no crossing - user)
  around the slime on staggered loops; ~40% burst mid-air, the rest hit the ground -> expanding shock ring
  + 4 flecks flung up that arc back down.
- Numbers: cycle 2.4 s; fall 50% (ground) / 62% (mid-air) of the cycle, accelerating q^2; start 1.6 bw
  left and 2.6 bw above the landing point; landing x +-1.1R, y ground ellipse +-0.3R; mid-air burst at
  0.9 bw height; meteor 0.42 bw (x1.7 long), rotated along the fall. Ring 0.3 -> 1.6 bw (x0.45 flat; mid-air
  rings half size and round), alpha 0.9 -> 0 over 70% of the remaining time. Flecks: fan -0.2..-0.8 pi,
  speed 1.0-1.4 bw, gravity 1.8 bw, size 0.14 bw shrinking 60%.
- Roblox: meteor = ParticleEmitter on a high attachment, `Orientation VelocityParallel`, fixed slanted
  direction, Speed 6 bw/s, Acceleration along the fall, Lifetime 0.6, + Trail-like streak via the art's own
  tail; impacts need sync -> script spawns per meteor: `:Emit(1)` meteor, then after the fall time
  `:Emit(1)` ring (flat ground emitter) + `:Emit(4)` flecks (Acceleration -gravity). 5 meteors / 2.4 s =
  ~2 events/s. **[cheap-mid]**

### 5.14 Blazing Ascendant (ascend) - `aura-blaze` (mythic, 9800 coins, from the travelling merchant)
- Art: `fx-blaze-tongue.png` (tall branching flame on black), `fx-blaze-ring.png`, `fx-blaze-wisp.png`,
  `fx-blaze-glow.png` (core), arcs = the user's `fx-static` frames, sparks `battlefx-spark-star`.
- Look: Dragon-Ball-style power-up. Golden core glow hugging the body; a shell of 6 tall flame tongues
  rising past the crown; 2 lightning arc flipbooks snapping to new spots; 3 big curling wisps orbiting
  slowly; twin crack rings pulsing outward at the feet; 10 rising sparks.
- Numbers: core centred at -0.45 bw, 1.35 x 1.6 bw x breath (1 + 0.06 sin 2.1T), alpha 0.75 + 0.2 sin 1.7T.
  Ground rings: cycle 1.8 s (outer at 0.7x speed, 0.9 s offset), width (1.1 / 1.45 bw) x (0.9 -> 1.15), x0.38
  flat, alpha 0.9 / 0.65 -> 0. Tongues: 6 on a 0.38 bw circle, base at the feet, height 1.55 +- 0.45 bw x
  flicker (0.75-1.0 at 7-11 rad/s), width 0.38 bw, lean +-0.12 rad, alpha 0.8-1. Arcs: snap rate 6.5 / 7.8
  per s, jitter +-0.18 bw, 1.55 bw box at the feet, blink to 0.3 one frame in 4 at 30 Hz, alpha 0.6/0.5.
  Wisps: orbit 0.28-0.42 rad/s at 1.25-1.61R, flat orbit (0.38), size 0.55-0.75 bw, alpha 0.55-0.85.
  Sparks: life 1.2-1.6 s, rise 1.8 bw, drift 0.12 bw, white -> `ffe080` after 40%.
- Roblox: tongues = 1 emitter (Shape Cylinder at the feet, radius 0.38 bw), Rate 10, Lifetime 0.5, Speed
  small up, Size 0.38 -> 1.6 bw stretched (use a tall texture, `Squash` NumberSequence to stretch
  vertically), LightEmission 1. Core glow: 1 long-life particle. Arcs: as Static Charge (5.11) at 7 fps
  frame snap with random rotation. Wisps: 1 spun attachment with 3 children + a soft emitter each, or 3
  billboard images. Rings: 1 flat emitter Rate 1.1. Sparks: Rate 7. **[mid-heavy]** - the biggest additive
  stack; Low tier: drop wisps and back arc, tongue Rate 6.

### 5.15 Flame (legacy, no item uses it)
- Fallback style in `updateFancyAura`: ring of flame tongues at the feet flickering (9 + 23 rad/s glow
  flicker, tongue height 0.55-0.8 bw x flicker), 6 rising embers life 1.4 s. Keep only as a recipe.

---

## 6. Wings (`wingFlap.js` v4, `wingMotion.js`, `wingFx.js`)

17 wing items: fairy, ember, sun, void, starlight, blizzard, aurora, blossom, hellfire, nightsky, rain,
autumn, firefly, coderain, thunder, electric, butterfly. Art = one PNG per wing pair (`equip-wings-*.png`,
**not in the download**), split into left/right halves; each half is ONE MeshPlane 10 columns x 3 rows.
Placement: span 1.92 bw (+20% - user), centred, hinge columns at the body seam, base y -0.38 bw, behind the
body. Fade-in 0.3 s (section 4).

### 6.1 Flight styles
**Bird** (default; all except butterfly / fairy / firefly) - feathered or energy wings, a soft membrane
that BENDS shoulder -> tip with wrist lag.
- Beat phase `T*0.55 + 0.16 sin(0.43T) + 0.07 sin(0.97T + 1.3)` -> ~0.55 beats/s (~1.8 s per flap), wandering.
- Stroke curve: power DOWN in the first 38% (1 - k^2), slow recovery 62% (smoothstep).
- Tip lags the shoulder by 0.16 beat; bend angle interpolates root -> tip with f^1.2; tip swing x1.15;
  swing range -0.10 .. +0.55 rad x amp (1 + 0.08 sin 0.83T) x (1 - 0.75 glide); fold shortens segments by
  up to 30% when raised.
- Glide envelope: `sin(0.23T + 1.9)` mapped, edge 0.72 over 0.18 -> occasional glides on held dihedral
  0.55 + 0.07 sin(1.1T).
- L/R asymmetry +-0.018 beat (0.61 / 0.67 rad/s).
- Body lift: root y -= 0.028 span x (1 - stroke(beat - 0.12)) x (1 - 0.5 glide) - the body rises just
  AFTER the downstroke.

**Butterfly** (`wings-butterfly`, `wings-fairy`, `wings-firefly`) - RIGID double wing that claps shut
above the back and flings open (rotation about the body's vertical axis + a screen-plane lift); never a
membrane bend.
- Beat `T*0.85 + 0.2 sin(0.33T) + 0.08 sin(0.83T + 1.1)` -> ~0.85 claps/s ("slower and gentler" - user).
- Close curve: smoothstep close 45% -> dwell 8% with a shiver 0.025 sin(90 ph) -> fling open 47%,
  (1-k)^1.35.
- Max close 1.05 rad about the vertical axis (tip flexes 0.9 -> 1.0), lift 0.35 rad at full clap.
- Amplitude 1 + 0.07 sin(0.77T); L/R offset +-0.02.
- Coast envelope `sin(0.29T + 0.8)`, edge 0.68: wings held open at 0.12 + 0.05 sin(1.3T).
- Body bob: +0.02 span x (close(beat - 0.08) - 0.35) - lowest at the clap.

Roblox build: each wing half = a flat skinned MeshPart (the PNG on a subdivided plane) with a 4-bone
chain hinge -> tip (Bird) or a plain hinge (Butterfly). One client loop computes the same curves and
writes `Bone.Transform` (Bird: 4 bones x 2 wings) or one `Motor6D.C0` per wing (Butterfly: Y rotation =
close, Z rotation = lift). 3D makes the butterfly clap read better than the web's x-compression.
LOD: < 40 studs 60 Hz, 40-100 studs 20 Hz, beyond 100 studs freeze open. **[cheap]** per avatar.

### 6.2 Wing FX layers (`wingFx.js`)
Three layers per wing set: (1) glow = a second hinged pair of the same art, ADD, 1.04x span, posed by the
SAME flap code (it must beat in lockstep - the old static glow showed as a ghost behind the wing, user
bug "bóng mờ sau cánh"), alpha 0.18 + 0.22 x beat (brightest at the top of the upstroke), tinted: aurora
and butterfly = slow rainbow (0.12 cycles/s), void `9a5aff`, coderain `39ff88`, electric `9af2ff`, others
white; electric/thunder flicker to 40% one frame in four at 30 Hz. (2) tip / edge particles (theme
below), sized x2 (user). (3) edge shimmer (part of the theme particles).

| Wing | Mote art | Count | Particle behaviour |
|---|---|---|---|
| sun | spark-star | 10 | rays drift up and out from the tips, fast twinkle, white -> gold `ffe08a` |
| void | mote-arcane | 12 | shards spiral INWARD to the seam and vanish (`b46bff` -> `5a2a9a`) |
| starlight | spark-star | 12 | stars twinkle along the leading edge; outer ones detach and drift up |
| blizzard | snowflake | 12 | crystals shed and sway down, spinning |
| aurora | mote-heal | 12 | rainbow motes rise from the edge in slow ribbons |
| ember | mote-fire | 12 | embers rise and flicker, cooling yellow `ffb347` -> red `ff5a2a` |
| blossom | petal frame-00 | 10 | petals loosen and drift down, swaying, spinning, flipping |
| hellfire | mote-fire | 12 | 1 in 3 = magma drips falling from the lower edge; rest = embers rising |
| nightsky | spark-star | 10 | stars twinkle in the blades; one shooting star sweeps across a wing every 6.7 s |
| rain | `fx-bubble.png` (NORMAL) | 10 | soap bubbles float up from the edges (user), wobble, grow 60 -> 110%, pop |
| autumn | leaves frame-01 | 8 | default edge drift |
| firefly | mote-heal | 12 | default edge drift (`d8ff8a` / `fff6b0`) |
| coderain | glyph frame-03 | 14 | half stream DOWN the panels, half break off the tips as flickering glitch bits |
| thunder | `fx-static` frames 2,3,4,6,7,8,9 | 6 | small lightning arcs crawl along the LEADING EDGE only (user), ~25% of the edge per burst, 0.55-0.9 s bursts, 30% skipped, random size/intensity, flicker 40 Hz |
| electric | mote-shock | 14 | NO particles (user removed the sparks) - crackling glow pair only |
| butterfly | spark-star | 10 | rainbow glitter dust shaken off each beat, drifting down |
| fairy | spark-star | 8 | soft sparkles orbiting each tip |

Particle cycle (all themes): life 2.2 +- 0.6 s, fade in 15% / out 25%, base size 0.05 span (x2).

Roblox build: glow = a duplicate wing mesh 1.04x, `Transparency` = 1 - (0.18 + 0.22 beat), tinted
`Color`, driven by the SAME bones/motor values (share the pose table, never a second clock). Particles =
1-2 emitters per wing set on tip/edge attachments that ride the wing bones (attachments parented to the
tip bone move with the flap for free). Thunder edge arcs = 1 emitter with the static-arc atlas, Rate 3,
Lifetime 0.6, `Squash` for elongation. **[cheap-mid]**.

---

## 7. Egg hatch reveal (`eggReveal.js`)

Full-screen overlay (DOM), rarity decided before the reveal (animation never rerolls). Tap anywhere to
skip. Background dim `rgba(10,16,10,.82)`.

Tiers: **base** (quick), **dual** (rays + confetti), **secret** (+ white flash, rainbow wheel, orbiting
stars, slow zoom). Colours: base burst `#fff6e0` glow white 0.6; dual `#ffd75e`; secret `#b478ff` with
rainbow palette `#ff6ad5 #6ad5ff #ffe66a #8dff6a #c48dff #fff`. Labels: "A new slime!", "A rare Dual
slime!", "A SECRET slime!" + slime name.

Timeline (ms, multiplied by tier scale base 1.0 / dual 1.35 / secret 1.9; auto-finish 4200 ms x scale,
then 0.25 s fade-out):

| t (ms) | Stage | What happens |
|---|---|---|
| 50 | EGG_ENTRANCE | `eggDrop` 0.5 s ease-out: from -40vh, scale 0.5, alpha 0 -> 60%: on the spot, squash (1.1, 0.9) -> 80%: (0.94, 1.06) -> 1 |
| 600 | ANTICIPATION | `eggWobble` +-4 deg, 0.5 s loop; round radial glow (220 px) fades in 0.3 s; stat icons (only when stats improved: 4-6 icons, 34 px) orbit at r 134 px, 2.6 s/rev |
| 1400 | CRACKING | `eggShake` 0.12 s x3: +-4 px, +-6 deg (no crack line - shake then burst) |
| 1800 | ENERGY_BURST | full-screen radial burst (0.1 s in); egg scale 1.3 + vanish; ring1 4 px `ringExpand` 0.55 s (scale 0.25 -> 3.4, alpha 0.95 -> 0); ring2 2 px 0.75 s +0.12 s; stat icons sucked into the egg (scale 0, 0.5 s ease-in); **rare**: ring3 8 px with 30 px glow, 0.9 s +0.05 s; **secret**: white screen flash 0.7 s (peak at 10%) |
| 1950 | SILHOUETTE | burst off; slime art shown at brightness 0 (black silhouette); **rare**: ray wheel (12-spoke conic in burst colour; secret = rainbow) grows scale 0 -> 1 with a 360 deg turn in 1.0 s (secret 1.4 s), then spins 6 s/rev forever; **secret**: second reverse wheel 1.6 s, then 9 s/rev; 8 stat twinkles pop (0.85 s, stagger 0.11 s, scale 0 -> 1.3 -> 0.7) |
| 2300 | SLIME_REVEAL | colour returns (brightness 1), art scale 1.15; confetti 34 (dual) / 60 (secret) pieces: 6-14 x 10-25 px, round or square, fly 180-420 px (+60 secret) outward then +260 px fall, spin up to 720 deg, 1.4-2.15 s, cubic-bezier(.2,.7,.3,1), stagger 0-0.2 s; dual: gold drop-shadow 18 px; secret: 10 ✦ stars orbit (r 118/150, 3.4 s/rev), art slow zoom 1.15 -> 1.45 over 2.4 s, violet drop-shadow 28 px; 4 stat icons rise and fade (1.1 s, stagger 0.16 s) |
| 2700 | RESULT | banner fades in; rare: `bannerPop` 0.6 s (0.3 -> 1.18 -> 1), font 30 px dual / 34 px secret; non-secret art eases back to scale 1 |

Total: base 4.2 s, dual 5.7 s, secret 8.0 s. Stat-reveal FX only when the child beats BOTH parents (AGENTS).
Art used: `egg.<colour>.png` (navy -> blue), slime art, `stat-<kind>.png` (egg + stat icons not in the download).

Roblox build: a `ScreenGui` overlay (IgnoreGuiInset) with the egg and slime as 3D models in a
`ViewportFrame` (lets the egg wobble/shake with real 3D and the silhouette via `ViewportFrame.ImageColor3`
black -> white tween - an exact match for `brightness(0)`). Ray wheel = an ImageLabel of a ray texture
rotated by `Rotation` (UIGradient for the rainbow), rings = ImageLabels of a soft ring texture scaled with
`UIScale` + `ImageTransparency` tweens; confetti = 34/60 small Frames tweened by TweenService (GUI only,
fine on phones); stars orbit = a rotating Frame. Burst = radial ImageLabel. Secret white flash: comfort
deviation - use a lavender `#e8dcff` flash peaking at 0.6 transparency-inverse, single pulse, skipped
under reduce-motion. All tweens owned by one controller with a single `finish()` cleanup (tap-to-skip,
auto-finish, leave). Preload egg/slime meshes + textures with `ContentProvider:PreloadAsync` before the
stage starts. **[cheap]** (GUI tweens; ViewportFrame with one model).

---

## 8. Combat: units, hit reactions, marks (`battle/scene.js`, `bossAnims.js`, `weaponAnims.js`, `fxLibrary.js`, `fxKinds.js`)

Rule from AGENTS: **never touch combat timing for animation** - every visual below is render-side.

### 8.1 Unit locomotion and idle (battle)
- Move blend m: approaches 1 when moving, 0 when standing, rate 8/s.
- Bob phase speed 1.8 + 6m rad/s; hop height |sin(bob)| x (1.5 + 5m) px.
- Body squash (body only, HP bar steady): s = (arc - 0.5) x 2 x 0.13 x m + sin(bob) x 0.03 x (1 - m);
  sy = 1 + s, sx = 1 - 0.7 s -> idle +-3% breath, moving +-13% hop stretch.
- Facing: `stepFacing` lerp 0.3 per frame toward the travel side when |dx| > 0.2, never |flip| < 0.3;
  enemy art faces LEFT, squad art faces RIGHT; body and gear flip together (capture travelDx BEFORE the flip).
- Dead squad units alpha 0.45.
- Roblox: same loop as farm slimes (section 2), on the battle unit models. **[cheap]**

### 8.2 Action moves (`sampleBossAnim`) - body scale multipliers + lift
All end on a damped jelly spring `settle: d = (1-p)^2 cos(4 pi p)` back to 1x1. `eo` = ease-out quad,
`ei` = ease-in quad. Multipliers apply to the CAPTURED base scale (never overwrite it).

| Move | Dur (s) | Keyframes |
|---|---|---|
| slam | 1.35 | crouch 0.14 (sy 0.76, sx 1.18) -> launch 0.30 (lift 120 px, sy 1.26, sx 0.86) -> hang 0.10 (tremble 2 px) -> dive 0.10 ei (sy 1.32, sx 0.82) -> flat squash 0.12 (sy 0.52, sx 1.5) -> settle 0.59 |
| charge | 1.2 | shrink+tremble 0.5 (sy 0.8, sx 0.84, tremble 0.02 at 42 rad/s) -> burst 0.12 (sy 1.32, sx 1.22) -> settle 0.58 |
| tide | 1.0 | inhale 0.28 (sy 1.2, sx 0.86) -> belly-flop 0.14 ei (sy 0.58, sx 1.45) -> settle 0.58 |
| recoil | 0.9 | 3 pulses: sy 1 - 0.12, sx 1 + 0.1, lift 5 px, decaying to 40% |
| inflate | 1.05 | swell 0.45 to 1.16 (+jitter 0.012 at 18 rad/s) -> pop 0.13 (0.92/0.9) -> settle 0.47 |
| lunge | 0.55 | 0.1 to sx 1.4, sy 0.72 -> settle 0.45 |
| quake | 1.1 | heave 0.32 (lift 26, sy 1.18, sx 0.9) -> drop 0.10 ei -> crash 0.12 (sy 0.6, sx 1.38) -> settle 0.56 |
| halo | 0.7 | hover 12 px while sx = max(0.3, abs(cos 14t)) (spin read) -> settle |
| pop (minion spawn) | 0.6 | 0.18 from 0.2 to 1.25 -> settle (1.25, 1.3) |
| roar | 0.95 | rear 0.35 (sy 1.28, sx 0.88) -> bellow tremble 0.15 (0.025 at 34 rad/s) -> thump 0.1 ei (sy 0.82, sx 1.15) -> settle 0.35 |
| jab (melee basic attack) | 0.32 | 0.08 to sx 1.18, sy 0.86 -> settle 0.24 |
| shoot (ranged basic attack) | 0.3 | 0.07 to sy 1.12, sx 0.9, lift 3 px -> settle 0.23 |
| flinch (hit reaction) | 0.28 | 0.06 to sx 1.22, sy 0.8 -> settle 0.22 |
| crystal | 1.15 | tighten 0.25 to 0.93 -> shimmer freeze to 0.78 (0.008 at 26 rad/s) -> settle 0.37 |

Skill -> move map (`SKILL_MOVE`): King royalslam=slam, gootide=tide, crownnova=charge, prismray=charge,
prismbarrage=recoil, summons=inflate, prismward=crystal; court spearlunge=lunge, gemquake=quake,
shardhalo=halo; Queen veilrend=lunge, phaseblink=recoil, mirrorlegion=inflate, eclipse=crystal,
umbralgrasp=tide, voidnova=charge; map bosses stomp=quake, charge=lunge, avalanche=roar, roots=roar,
lifedrain=inflate, geyser=recoil, thornvolley=recoil; minibosses pollenwave=inflate, fangflurry=lunge,
flamedash=lunge, packhowl=roar, bellyflop=tide; squad specials dash=lunge, taunt=roar, volley=recoil,
barrage=recoil, healring=inflate, acid=shoot, avenge=roar. Basic attacks: sword/shield/body/dummy = jab,
bow/arcane/alchemy/staff = shoot; enemies jab (melee) or shoot (projectile). A running move is never
interrupted; a flinch during a move is blended at HALF strength on top (AGENTS: "mid-move victims HALF flinch").

`BOSS_IMPACT_DELAY` (heavy FX + camera punch wait for the touchdown beat): royalslam 0.64, gootide 0.3,
crownnova 0.5, summons 0.45, prismray 0.5, gemquake 0.42, stomp 0.42, bellyflop 0.3, umbralgrasp 0.3,
voidnova 0.5, mirrorlegion 0.45.

Roblox build: units are skinned meshes with Root/Top/Side bones (section 2); a move = a pure function
sampled per frame writing bone offsets (squash) + model Y offset (lift). No AnimationTracks needed (and
no animation assets to upload). Queue impact FX with `task.delay(BOSS_IMPACT_DELAY)` owned by the
battle FX controller (cancel all on battle end). **[cheap]**

### 8.3 Hit reactions and juice
- **Nudge** (visual-only position offset, exp decay e^(-9 dt), removed below 0.3 px): melee attacker
  (non-boss, not mid-move) lunges 14 px toward the target; victim knocked back 9 px (16 px on crit) and
  flinches. Bosses (king/queen) never get nudged or knocked back ("bosses are mountains"); area-hit
  victims are not knocked back.
- **Hit flash** timer 0.12 s on victims (0.15-0.2 s on casters/heal/buff); the current code resets tint to
  white each frame, so the flash is effectively off - do not rebuild a white body flash unless asked.
- **Crit** (deterministic, x1.6 damage): floating text gold `ffd84a` 22 pt with "!", mark size x1.3,
  knockback 16, `playCritFlourish` = 8 gold burst sparks (radius 46) + a 42 px warm burst flash + camera
  impulse 0.25, plus a "crit" sound accent.
- **Floating text**: bold, dark stroke 3; rises 36 px/s, linear fade over 0.8 s; damage white 16 pt,
  crit gold 22, heal green `54e05a` "+N", skill shouts 18-26 pt in the skill colour (one shout per caster
  per batch).
- **Heal crosses**: 3 crosses (16/14/12 px), staggered 0.09 s, 0.85 s each, follow the unit, rise 34 px,
  scale 0.7 -> 1.2, alpha 1 - k^2. Art `battlefx-heal-cross.png`.
- **Buff/debuff aura** (SOLE status cue - no icon): user fire sheet `fx-aura2-key.png` (3x2 grid of 512 px
  frames, alpha-keyed derivative), NORMAL blend (additive fire vanished on the Snowy map), 9 fps loop,
  width max(80 px, 2.1 x body), anchor at the flame base (0.5, 0.86) +4 px, BEHIND the body, alpha
  0.88 +- 0.08 (6.5 rad/s), scale pulse +-5% (5 rad/s), random phase. Debuff = `fx-aura2-debuff-key.png`
  (R<->B channel swap = cold blue "cursed" fire). Status expiry follows combat.simTime.
- **Other status icons**: slowed = blue dot, taunted = red ring, shielded = yellow square (tiny, above HP bar).
- **HP bars**: 50x6 (bosses 220x10), dark back `2a1a10`, squad green `54b848`, enemy red `d8402f`.

Roblox build:
- Nudge/flinch: model-local offsets in the unit loop. **[cheap]**
- Floating text: pooled `BillboardGui` + TextLabel + UIStroke, tween offset up 1.2 studs & TextTransparency
  over 0.8 s; pool size 24, oldest recycled. **[cheap]**
- Heal crosses: ParticleEmitter Emit(3) on the unit's head attachment, `LockedToPart true`. **[cheap]**
- Buff aura: ParticleEmitter, 1 particle `LockedToPart`, Lifetime 20, the 6 frames repacked into a 4x4
  atlas (frames repeated to 16 cells, FlipbookFramerate 9 x 16/6 ~ 24 to keep 9 fps of distinct art, or
  a 2x2 of 4 frames at 9 fps), LightEmission 0 (NORMAL); debuff swaps the texture. Exactly one per unit.
  **[cheap]**, but overdraw: ~2.1 bw wide translucent card per buffed unit - cap visible auras at 12.

### 8.4 Attack hit marks (`fxLibrary.js`)
One hit = one mark, always the ATTACKER's weapon kind (never the victim's): sword slash, shield impact,
alchemy acid, staff holy, bow pierce, arcane magic; full table in `fxKinds.js ATTACK_FX_BY_BEHAVIOUR`.
Ranged weapons fly a projectile and the mark waits for impact.

| Mark | Art | Dur | Motion |
|---|---|---|---|
| generic (claw, bite, impact, ice, magic, holy, acid, fire) | `battlefx-<kind>.png` | 0.32 s | random rotation + 50% mirror, jitter +-5 px, 0.3 size above the hit point, spin +-1.2 rad/s, swell +35%, alpha 0.95(1 - k^2) |
| pierce | `battlefx-pierce-hit.png` | 0.30 s | points along the attack line, swell +40%, no spin, size x1.4 |
| slash (melee sword) | `battlefx-slash-arc.png` | 0.36 s | perpendicular to the attack line, sweeps (k - 0.4) x 1.7 rad across the victim, fade-in first 12%, swell +25%, size x1.15 |

Sizes: victim size x1.1 (x1.4 for area hits) x1.3 crit; ranged marks (pierce/acid/magic) at 50% (user);
World Boss hits use 60 px, scattered +-85 px x and 50-200 px up the body ("boss marks <= 60 px" - marks
piled into a white cloud otherwise).

Projectiles: linear 0.35 s; art faces RIGHT and aims along the path (arrow, shard, goo, light, fireball,
seed dart, thorn, gem); orb pulses +-15% at 26 rad/s; flask tumbles 9 rad/s. Widths: arrow 34, flask 24,
goo 28, fireball 34, lava glob 30, seed dart 34, thorn 42, others 26 px. Queen bolts = gem tinted violet.

Roblox build: marks = one pooled ParticleEmitter per kind at a hit attachment, `:Emit(1)`, Lifetime 0.32,
Size curve +35%, RotSpeed +-70 deg/s, `Rotation` random; slash = Emit with `Rotation` set per hit from the
attack angle and `RotSpeed` ~97 deg/s for the sweep (or a 4-frame flipbook OneShot). Projectiles: pooled
parts moved by the battle loop (or `BodyMover`-free CFrame lerp) for 0.35 s + optional Trail (arrow/orb).
**[cheap]**.

### 8.5 Area / skill FX primitives (art per element, rendered UNTINTED)
Elements: fire, ice, heal, arcane, acid, shock. Each has its own ring (`battlefx-ring-<el>.png`),
burst core (`battlefx-burst-<el>.png`) and mote art (user: one asset in different colours was boring;
**no plain colour rings**). The element is explicit at the call site or classified from the old tint by
HUE (`elementForAreaTint`: greys -> shock, reds/oranges -> fire, golds/greens -> heal, toxic yellow-green
-> acid, cyan/pale blue -> ice, deep blue/purple -> arcane).

| Primitive | Dur | Motion | Layer |
|---|---|---|---|
| Ring wave | 0.65 s (+delay) | diameter radius x 2.4/0.72 x (0.25 + 0.75 easeOutCubic), flattened to 0.55 of its height (ground ellipse), alpha 0.95(1 - p^2); + an ADD glow copy x1.18 pulsing +-0.08 (4 pulses), alpha 0.7 | on the floor (zIndex y-1) |
| Burst flash | 0.38 s | size 0.45 -> 1 (ease-out quad), random rotation, alpha in 15% then out | floor (y-1); hit marks stay on top |
| Sparks 'burst' | 0.55-0.9 s, start stagger 0-0.18 s | spark-star (or petal/leaf/ember/snowflake/spore/wisp/honeydrop), 9-20 px, speed 70-250 px/s outward, vertical x0.45 - 70 up, gravity 320, spin 1-3 rad/s, twinkle sin(22p) and shrink 40% | floor |
| Sparks 'rise' | same | scattered over the circle (+-0.9 r x, +-0.38 r y), float up 45-100 px/s, no gravity | above units |
| Ground crack | 1.25 s | crack / vinecrack / icecrack art, flat 0.5, grows 0.8 -> 1 in the first 20%, alpha in 10%, hold to 55%, fade | floor |
| Dash streak | 0.3 s | a line whose tail catches up to the head, width 8.5 -> 1.5 px, alpha 0.75 -> 0 | ground |
| Slime afterimages | 0.45 s each | 6 ghost copies of the body along the dash, stagger 0.045 s, alpha (1-p)(0.3 + 0.45 k), drift up 3 px | - |
| Acid rain | 0.34 s per drop | 9 drops fall 210-280 px (p^2) staggered 0.055 s, each splats an acid mark + 3 sparks | floor |
| Falling ice shard | 0.3 s | drops 150 px (p^2), point down +-0.22 rad | - |
| Eclipse veil | 6 s (`queenEclipseDur`) | full-arena `14082e` overlay, alpha 0.42, fade in 12% / out 18% | above all units |
| Loot drop | fly -> rest -> collect/discard | toss vx +-45, vy -110..-180 px/s, gravity 620, bounce restitution 0.38 (vx x0.55), max 2 bounces; rest bob 1.6 px at 3.2 rad/s; collect = rise 46 px + fade 0.55 s; discard = grey + sink 6 px, 0.8 s | ground |

Roblox build: ring = flat ParticleEmitter (Rate 0, `Orientation VelocityPerpendicular`, Speed 0.01 up,
Lifetime 0.65, Size NumberSequence 0.25 -> 1 eased, Transparency 0.05 -> 1) + glow twin (LightEmission 1,
Size x1.18); a flattened ellipse comes free from the 3D camera angle - use round art. Burst = billboard
emitter Emit(1) Lifetime 0.38. Sparks = one shared emitter per texture with `Acceleration (0,-g,0)` for
burst and `Speed` up for rise; Emit(count). Crack = decal on a flat pooled part, Transparency tween.
Dash streak = Beam between two attachments with Width0 tween, or a Trail on the dashing unit (it moves,
so a Trail is natural). Afterimages = 6 pooled clones of the body mesh with `Transparency` tween (or 1
Highlight-free ghost material). Eclipse veil = `ColorCorrectionEffect` TintColor + Brightness -0.25
tween (client-only, cleaned up on battle end) - cheaper than a giant translucent part. **[cheap]** each;
budget the burst-heavy bosses below.

### 8.6 Weapon motion (`weaponAnims.js`) - the hand sprite moves independently of the body
Grip pivot = lower-left of the art (0.25, 0.8); dx/dy in body-width units.

| Move | Dur | Look |
|---|---|---|
| swing (sword basic) | 0.34 | wind back -1.4 rad (30%, ease-out) -> fast slash to +1.9 rad, hand travels forward 0.45 bw (30%, ease-in) -> settle wobble |
| draw (bow) | 0.42 | pull back -0.55 rad, toward body, stretch (0.9, 1.12) -> snap forward and up, settle |
| raise (staff) | 0.6 | sweep up -1.1 rad, 0.5 bw up -> hold with glow-swell pulse 1.1 x(1 +- 0.08) -> sweep down |
| orbit (arcane focus) | 0.55 | float up 0.3 bw and spin one full turn, swell 12% |
| shake (alchemy kit) | 0.45 | rattle +-0.3 rad x3 -> toss up 0.2 bw |
| brace (shield) | 0.4 | thrust forward 0.22 bw, up, x1.15 -> hold -> pull back |
| cleave (sword special) | 0.5 | slow high wind-up -1.9 rad (45% = the telegraph) -> huge overhead cut to +2.5 rad, x1.3 |
| volley (bow special) | 0.62 | full draw -1.05 rad aimed skyward, trembling hold -> release up-and-forward |
| channel (staff special) | 0.85 | raise high overhead and swell to 1.2x, pulsing -> lower |
| surge (arcane special) | 0.75 | rocket up 0.42 bw, 1.5 turns, swell to 1.3x |
| fling (alchemy special) | 0.58 | wind back low -> hurl high with a full overhead spin (acid-rain lob) |
| bastion (shield special) | 0.55 | slam forward 0.34 bw at x1.25 and PLANT it (taunt hold) -> drag back |

Farm/battle idle sway: staff/focus float + slow twirl (+-0.12 rad @1.1, bob 0.04 @1.6); bow pendulum
+-0.1 @1.3; shield heave +-0.05 @0.9; kit jiggle +-0.07 @2.2; sword wag +-0.14 @1.5 (rad/s).
Tail charm sway (rotation ONLY): `sin(5.2t) + 0.25 sin(2.3t + 1.7)` (~+-1.25 rad) x per-item
`TAIL_PLACEMENT.sway`.
Animated weapons: all 6 mythic + 6 enchanted weapons step a frame pack (`assets/anim-*`, manifest fps)
on the shared clock (not in the download). Accepted drifts: mythic bow lost its nocked arrow, enchanted
staff emerald became a leaf-glow.

Roblox build: the weapon is a separate part welded through a `Motor6D` whose C0 is written by the same
pure function (pivot = grip attachment). Animated weapons: a `SurfaceAppearance`-free flipbook is
awkward on a 3D weapon - prefer a static 3D weapon + a small emitter (glow/sparkle) for mythic/enchanted.
**[cheap]**

---

## 9. Hit-stop, slow-mo and camera shake

- **Kill hit-stop**: every enemy death calls `startSlowmo(0.4, 0.07)` = sim speed 40% for ~70 ms;
  chained kills inside the window collapse into one stop.
- Slow-mo curve (`getTimeDilation`): hold the depth for the first 35% of the duration, then ease back
  quadratically to 1. A deeper beat is never replaced by a shallower one.
- Drama beats: boss death 0.22 for 1.0 s; miniboss death 0.35 for 0.7 s; last enemy of a wave 0.3 for
  0.75 s; whole squad down 0.3 for 1.0 s; Crown Nova / Void Nova 0.5 for 0.7 s (covers charge + blast).
- The FX runtime also returns a timeScale each frame (farm sim), see section 1.
- **Camera impulse power** (via `heavy-hit`): crit 0.25; squad member falls 0.55; miniboss death 0.7;
  boss death 1.0; skills `SKILL_PUNCH`: royalslam 0.7, gootide 0.5, summons 0.35, prismbarrage 0.3,
  crownnova 0.8, prismray 0.4, prismward 0.25, gemquake 0.4, spearlunge 0.25, shardhalo 0.2, charge 0.65,
  stomp 0.65, avalanche 0.55, geyser 0.55, bellyflop 0.55, roots 0.5, lifedrain 0.4, fissuresnap 0.45,
  flamedash 0.45, magmarain 0.45, packhowl 0.45, avenge 0.45, pollenwave 0.4, thornvolley/sporeleap/
  stingdive/sootdive/snowroll/frostbite/fangflurry 0.33, shellspin/nightveil/rimegust/taunt 0.28,
  dash/seedpop/dazzle/emberpop/firejuggle/seedstorm/shardnova 0.22. Impact-staged skills punch at
  `BOSS_IMPACT_DELAY`, not at cast. Offsets: battle x12 px, farm x6 px; reduced motion = none.

Roblox build: if battles run as a deterministic client-side simulation (like the web), slow-mo can
stretch the sim clock exactly as above. If the server runs combat, slow-mo/hit-stop must be visual-only:
freeze client visuals for 70 ms (`ParticleEmitter.TimeScale = 0.4`, unit loop dt x0.4) and never delay
server outcomes. Camera: ONE `CameraShake` module bound with `RunService:BindToRenderStep` after the
camera, decaying spring (frequency ~18 Hz, half-life ~0.12 s), amplitude = power x 0.35 studs + small roll
(power x 1.5 deg) + FOV punch (power x 2 deg) - the web's unused `roll`/`fovPunch` fit 3D well; respect a
reduce-motion setting; restore FOV on every exit path.

---

## 10. Enemy death, squad fall, victory

- **Enemy death** ("squash-fade + goo-pop + 70 ms hit-stop"): 0.5 s, ease k^2 (slow start, fast end = a
  deflate): scale (1 + 0.45e, max(0.06, 1 - 0.94e)), alpha 1 - e, then hidden. Plus an impact puff mark
  (0.9 x size), goo-pop 6 burst sparks tint `a6dd6e`, hit-stop. Boss/miniboss: + camera 1.0/0.7 + 16 gold
  `ffd84a` burst sparks + slow-mo. Deaths that fell outside a rendered tick still play the squash.
  Death "pop" sound and enemy-pop foley are RETIRED (user) - kills are visual-only.
- **Squad member falls**: "squadFall" sound + camera 0.55; last one: slow-mo 0.3/1.0.
- **Victory celebration**: survivors hop on their own beat (1.05 Hz, 30 px, stretch 1 + 0.2 up,
  squat 0.12 on landing, width compensates 1/sqrt(stretch)); confetti tosses every 0.26 s from a random
  cheering slime (9 pieces, 5-10 x 3-6 px, 8 tints `ff5a5a ffd23d 54e05a 4fa8ff d06ae0 ff9433 7ae8e8 fff6e0`,
  vx +-120, vy -180..-320, gravity 430, terminal fall 110 px/s, flutter 20-60 px, spin 3-8 rad/s, 1.3-1.9 s,
  fade last 20%); fireworks: opening salvo of 2, then every 0.5-1.05 s - rocket spark streaks up 0.5-0.7 s
  (ease-out) then a 130 px burst flash + 26 sparks (speed 130-240, drag 1.1, gravity 170, 8-17 px, twinkle,
  0.8-1.2 s), 6 tints. Stop restores positions/scales.

Roblox build: death = bone squash + Transparency tween 0.5 s, then pool the model; goo-pop = Emit(6) green
droplets. Celebration: per survivor the same hop function; confetti = one emitter (Rate 0) Emit(9) with
`Orientation VelocityPerpendicular` flat cards, `Drag 1.6`, Acceleration -gravity, multicolour
ColorSequence random; fireworks = 1 rocket emitter (Trail on a pooled part) + 1 burst emitter Emit(26)
at the apex, LightEmission 1. Celebration cap: <= 120 live particles. **[mid]**

---

## 11. World bosses (King Goo, Queen Nyx) and map bosses

Facts (AGENTS + config): King Goo 15000 HP, static at the arena centre, phases at 70/40/15% HP, fury at
15% (`kingFuryAt 0.15`), frenzy after 150 sim-s + soft enrage (future bosses must escalate without bound).
Queen Nyx ('eclipse') 22000 HP, inverse kit, unlocked by slaying the king, own music 'eclipse'.

Boss idle: deeper jelly breath sin(bob) x 0.038; when furious/frenzied the breath runs 3.4x faster at
0.05 and the body trembles sideways sin(11 bob) x 2.4 px ("seethes" - the throne never moves). Court
minions (guard, ring keeper, golem, mirror) bubble in with the `pop` move. HP bar 220 x 10 lifted above
the crown. Raid hit marks capped at 60 px and scattered over the body.

| Skill (boss) | Move | Staging (delay = BOSS_IMPACT_DELAY) | Punch |
|---|---|---|---|
| Royal Slam (King) | slam | at 0.64 s: ground crack 2 x slam range, arcane ring + gold ring (0.1 s), 150 px violet burst, 14 gold burst sparks, 8 cyan rising | 0.7 |
| Goo Tide (King) | tide | at 0.3 s: 3 rings (violet r, cyan 0.75r +0.12, gold 0.5r +0.24), 130 px ice burst, 16 cyan burst + 10 violet rise sparks; radius bigger in fury | 0.5 |
| Crown Barrage | recoil | crown flash 110 px + 18 prism sparkles; gem projectiles per victim | 0.3 |
| Prism Ray | charge | at 0.5 s: 9 rainbow flashes march crown -> endpoint over 0.22 s (`ff8a8a ffd75e 8aff9a 6fd9ff c79af0`), white crown flash, white sparks on victims | 0.4 |
| Prismatic Ward | crystal | 2 rings (170/120 px) at chest, 120 px cool flash, 18 rising sparks | 0.25 |
| CROWN NOVA (desperation) | charge | slow-mo 0.5/0.7; at 0.5 s: crack 2.4 x slam range, 240 px white flash, rings 500/380/260 (gold/violet/cyan, +0.12 steps), 18 + 12 burst + 10 rise sparks | 0.8 |
| Royal Summons | inflate | at 0.45 s: violet ring; each new minion 55 px flash + 5 rise sparks | 0.35 |
| Veil Rend (Queen) | lunge | dark ring, 130 px violet flash, silver burst + violet rise sparks | - |
| Phase Blink | recoil | 160 px dark burst at departure + violet streak to arrival + 170 px flash (+0.08 s) | - |
| Mirror Legion | inflate | at 0.45 s: dark ring + flash per mirror | - |
| ECLIPSE | crystal | arena dusk veil 6 s (alpha 0.42 `14082e`), 2 rings, violet flash, 12 rising silver sparks; squad gets cursed blue fire (debuff aura) | - |
| Umbral Grasp | tide | 3 rings largest first (420, 300, grasp r) read as an inward collapse, then at 0.3 s 190 px violet burst + sparks | - |
| VOID NOVA | charge | the Crown Nova in negative: violet/silver/cyan rings 500/380/260, 250 px silver flash, cold star rain | - |
| Crystal Lance (guard) | lunge | violet dash streak + afterimages, gold arrival burst | 0.25 |
| Facet Quake (golem) | quake | at 0.42 s: crack, cyan + violet rings, 4-colour sparks | 0.4 |
| Shard Halo (ring keeper) | halo | small gold ring, violet flash, 6 cyan sparks | 0.2 |

Map bosses / minibosses (same primitives, by biome): Magmahorn (Molten Charge, Eruption Stomp, Magma
Geysers - staggered fire columns per victim 0.14 s apart), Bramblehorn (Wild Charge, Thorn Bloom with
natural pink petals, Thorn Volley spikes), Rootwarden (Verdant Slam teal runes, Entangling Roots,
Verdant Drain wisps), Frostjaw (Glacier Slam ice crack, Avalanche - 3 falling shards per victim then
ring/flash at fall+delay), plus ~20 mob skills (Seed Burst, Sting Dive, Dazzle double flash, Shell
Cyclone, Pollen Shockwave, Spore Pounce, Nightmare Veil, Spirit Ward, Belly Flop, Phantom Flurry 3
staggered slashes, Ember Burst, Soot Dive, Fire Juggle, Magma Rain, Fissure Snap, Blazing Dash,
Snowball Roll, Frostbite Lunge, Rime Gust, Shard Nova, Chilling Howl). Squad specials: Dash (afterimages),
Taunt (red shock ring), Arrow Volley, Healing Ring (2 green rings + 14 rising), Arcane Barrage (2 cosmetic
side orbs), Acid Rain, Avenge (red flare where the ally fell + "Avenge!" on every rallied ally).
All are listed with exact radii/tints in `battle/scene.js` 1338-1935; build them as data rows over the
section 8.5 primitives (one table, no per-skill code).

Roblox build for bosses: boss body = big skinned mesh, moves via section 8.2; staging = data-driven calls
into the primitive library with `task.delay`. Novas are the worst case: 3 rings + 1 flash + 40 sparks +
crack + camera + slow-mo - fine if sparks use one shared emitter (Emit 40) and rings are 3 particles.
Eclipse = `ColorCorrectionEffect` + `Lighting` tween, 6 s, one cleanup. **[mid]** at peak.

---

## 12. Ambient world and UI motion

- Wind: plants rotate +- 0.03 rad x amp around their base, trees shear the canopy (skew 0.02 x sway),
  wind clock 1.6 rad/s with per-object phase.
- NPC idle: merchant y-scale 1 + 0.035 sin(2.2t), tilt 0.03 sin(1.6t); blacksmith 1 + 0.04 sin(1.9t),
  tilt 0.03 sin(1.4t).
- Blacksmith hammer: 1.43 s cycle - wind-up 45% (smoothstep, +0.55 rad, up 14 px) -> strike 23% (ease-in,
  -1.95 rad, down 34 px) -> bounce 12% (sine, up 8 px) -> recover 20% (smoothstep); `fire-sparks` at the
  strike frame.
- Furnace: `fire-candle` loop + an ember puff every 1.4-2.4 s.
- Loading screen: meadow backdrop, title "Goo Lineage V2", the real navy slime bouncing (`gooLoadBounce`
  1.1 s: 30% up 24 px with (0.94, 1.06), 60% landing (1.06, 0.94)), gold->orange progress bar
  (`#ffd75e -> #f08a24`, 0.2 s width transition), tips rotating every 4 s, fade 0.35-0.4 s.
- Rarity UI twinkle (UI ONLY): ✦ sparks, 1.8 s, scale 0.35 -> 1.15, rotate 30 deg, opacity 0 -> 0.95.
- Tutorial: pointer bob 10 px, orange pulse glow, card pop 0.92 -> 1.

Roblox build: wind = one loop over a few dozen decor parts at 15-20 Hz (or bake into a skinned foliage
bone); NPC bob = bone or `Model:ScaleTo`-free CFrame wobble; loading = a ScreenGui with a ViewportFrame
slime bouncing by tween + `ContentProvider:PreloadAsync` progress. **[cheap]**

---

## 13. Art inventory for the rebuild (what exists in the download)

Present: `fx-aura-rays/halo-{sun,void}`, `fx-aura2-key`, `fx-aura2-debuff-key`, `fx-aurora-curtain-a/b`,
`fx-blaze-{glow,ring,tongue,wisp}`, `fx-bubble`, `fx-comet-star`, `fx-firefly`, `fx-hex-ring`, `fx-meteor`,
`fx-rain-cloud`, `fx-rain-streak`, `fx-snowflake`, `fx-storm-cloud`, `fx-leaves/00-05`, `fx-petals/00-05`,
55 `battlefx-*` files (marks, element rings/bursts/motes, projectiles, cracks, particles), 9 emotion faces.
Missing from the download: `fx-bolts/01-04`, `fx-static/01,03-09`, `fx-glyphs` (14 of 16), `fx-wings/01-05`,
all `equip-wings-*` / `equip-aura-*` icons, `assets/anim-*` weapon packs, egg art, stat icons.

Observations from viewing the art: the fire buff sheet is a 3x2 grid of photoreal flames on black;
`fx-static` and `fx-bolts` frames are blue-white glowing arcs on transparency; `fx-aura-rays-sun` and
`fx-blaze-tongue` sit on BLACK (made for additive) - in Roblox use them only with `LightEmission = 1`
(black adds nothing) or they show as dark squares in GUI/NORMAL use; `fx-aurora-curtain-a` is a neutral
grey striated curtain (tint owns colour); `battlefx-ring-fire` is a painted flame ring on black;
`fx-wings/frame-00` is a monarch-style single wing with dark outline.

Atlas note: Roblox flipbooks must be 2x2 / 4x4 / 8x8 grids in one image (<= 1024 px). Repacking the
user's frames into a grid keeps every pixel identical (no recolour) - treat it as layout, keep the
originals untouched, and pad cells 2-4 px.

---

## 14. User vetoes - never do

Copied from `AGENTS.md` and code comments (user requests):
1. **No in-world rarity glows.** Rarity is UI-only. (AGENTS 11; `game.js`: the Epic/Mythic gear foot-auras
   were removed - "it look funny"; "no rarity glow on equipped slimes".)
2. **No ground disc / ground glow under auras**, except Code Rain. (AGENTS 9; Starlight "moon" glow removed,
   Blossom/Blizzard disc removed, Hellfire "no ground disc behind the body", "no ground disc (user rule for auras)".)
3. **No plain colour rings** for element FX - use the per-element feathered, untinted art. (AGENTS 13; fxKinds.)
4. **No hand-written camera shake** - the FX runtime owns shake; request punches only. (AGENTS 13.)
5. **Never change combat timing for animation**; visuals never touch the deterministic sim. (AGENTS 16.)
6. **Slime bodies stay the original static art** - no body frame animation (`bodyAnims` + `anim-slime-*`
   deleted). (AGENTS 25.)
7. **No background / frame animation** for avatar backgrounds or UI frames (bg-anim, bg-fx, ui-frame
   abandoned: camera zoom + loop-seam jerks). Do not retry unless the user asks. (AGENTS 26.)
8. **Blink squashes the FACE only, never the body** (a body-wide squish read as deflating). (AGENTS 23;
   slimeRenderer.)
9. **No body squash before the hop and no landing squash** on farm slimes ("squished then bounced back"
   removed); stretch follows the arc only. (slimeRenderer.)
10. **No walk/jump/landing sound** on the farm (per-hop foley stacked into noise); **enemy-pop and
    slime-land foley retired**; death pop foley removed - kills are visual-only. (AGENTS 20; game.js; scene.js.)
11. **User art is sacred**: never recolour or regenerate originals; thunder/electric/blaze arcs are the
    user's flipbooks byte-identical; derived anim packs only when the user asks. (AGENTS 4, 9.)
12. **Buff/debuff: the flame aura is the SOLE cue** - no triangle/icon over the slime. (AGENTS 14; scene.js.)
13. **Butterfly aura: free wandering, not circling**; **butterfly wings: slower and gentler**. (fancyAura; wingMotion.)
14. **Hellfire meteors all fall from the same upper-left direction, no crossing.** (fancyAura.)
15. **Code Rain: no vertical light column; streams stay within the body width.** (fancyAura.)
16. **Thunderstorm aura: no shock ring / explosion at the strike.** (fancyAura.)
17. **Electric wings: no spark particles** (glow pair only). (wingFx.)
18. **Wing glow must share the wing's flap pose** - a static glow copy = "ghost behind the wing" bug. (AGENTS 10.)
19. **Aurora curtains: NORMAL blend + low-alpha additive bloom** - additive alone whites out on the daylit farm. (fancyAura.)
20. **Fire buff aura: NORMAL blend, alpha-keyed** - additive fire disappears on the Snowy map. (scene.js.)
21. **Ranged hit marks (arrow, flask, arcane) at half size**; **World Boss marks <= 60 px**. (scene.js; AGENTS 15.)
22. **No yellow rally-point marker** at the battlefield centre; **no duplicate Retreat button**. (scene.js.)
23. **No generic "buff" text over every recipient** - the caster shouts the skill's proper name once. (scene.js.)
24. **Aura is grounded** (does not bounce or breathe with the body). (avatarCosmetics.)
25. Never `scale.set` after width/height writes (engine pitfall; in Roblox: never overwrite a captured base
    scale - multiply it). (AGENTS 13.)

---

## 15. Phone budget

Target: 60 fps on a mid phone, never below 30 on a cheap one, at the worst case = farm with ~30 slimes +
the player's avatar (aura + wings) + 3-5 other players' avatars; battle with 6 squad + ~15 enemies + a
World Boss nova.

Graphics tiers (read `UserGameSettings().SavedQualityLevel` + a game setting; Low on phones by default
until measured):

| Budget item | High | Medium | Low (cheap phone) |
|---|---|---|---|
| Live particles on screen (all effects) | 600 | 350 | 180 |
| Own avatar aura | full recipe | rates x0.7, bloom kept | rates x0.5, no bloom/secondary layers, flipbooks at half fps |
| Other players' auras | full < 40 studs | x0.5 < 40, off > 80 | static single layer < 30 studs, else off |
| Wings bone updates | 60 Hz < 40 studs | 30 Hz | 20 Hz, glow layer off |
| Beams (aurora) | 10 | 5 (no bloom) | 4, colour update 4 Hz |
| Big additive cards overlapping (> 1.5 bw) | 6 | 4 | 2 |
| PointLights from VFX | 4 | 2 | 0 |
| Highlights | 0 needed (use none for VFX) | 0 | 0 |
| Floating texts alive | 24 | 16 | 10 |
| Buff/debuff fire auras visible | 12 | 8 | 6 (rest: tint the HP bar instead) |
| Farm `land-dust` emits per second | 8 | 5 | 2 |
| Boss nova sparks | 40 | 28 | 16 |

Rules:
- Every effect has an owner, a cap and one cleanup; battle FX controller cancels all `task.delay` staging
  on retreat/victory/defeat; egg reveal cleanup on skip/leave.
- Emitters for everything that just flies (GPU); Lua CFrame writes only for choreographed elements, all
  from ONE client loop, `workspace:BulkMoveTo` for batches; far/off-screen objects skipped.
- Density from Size and Lifetime, not Rate (mobile caps emit rate ~100/s per emitter).
- Preload flipbook atlases and aura textures on equip / battle start with `ContentProvider:PreloadAsync`.
- All decorative effects are client-side; the server only announces moments (hit, death, skill, hatch,
  equip) by RemoteEvent/attribute.
- Comfort: no flashing faster than ~3/s for anything large (slow the web's 25-45 Hz cloud/bolt flickers
  to <= 8 Hz or make them small); no full-white screen flash (secret egg uses a tinted, softer pulse);
  shakes small and short; a reduce-motion setting disables shake, slow-mo, breathing, blinking and
  flicker and softens hops, as the web's `reducedMotion` did.
- Acceptance per effect: look at start/peak/fade near and far on a busy scene; measure frame time,
  particle count and memory on the lowest quality before and after; repeat-trigger and kill-mid-effect
  tests leave nothing behind.
