-- What an effect of data is, and the first thing wrong with one (`Schema.problem`). The tests run it on every effect.
--
-- AN EFFECT (effects/<kind>/<id>.luau returns one):
--   id        "<kind>.<name>", lower case and underscores; the file is effects/<kind>/<name>.luau
--   name      what the catalog calls it (English)
--   kind      aura | trail | buff | wings | world (they last, on a host: VfxLib.attach)
--             hit | burst | reveal | skill (they play once: VfxLib.play)
--   tier      cheap | mid | heavy: the cost it promises (Budget.Tiers; the tests hold it to it). A heavy aura is a
--             SHOWCASE (Budget.Showcase: wider, more layers), full for the nearest one only (Lod.MaxShowcase)
--   host      pet | character | slime | egg | weapon | world | any: what it was made to sit on
--   refHeight studs: the height of the host the numbers were made for (a one-shot: the size of its box)
--   tags      words a game filters by: what it looks like and the owner's vetoes it respects ("no_ground_disc", ...)
--   blend     additive | normal | normal+bloom (normal with a faint additive copy: fire and aurora on a bright map)
--   palette   { role = colour } (Palette): the colours its pieces are drawn in by role; tintable = false: a game may not
--             hand its own
--   pieces    the emitters, each a PIECE (below)
--   bands     (trail) the Trails behind the runner, each a BAND (below)
--   wings     (wings) the pairs of wings on the back, each a WING (below): a flat picture on a Beam from its root to its
--             tip, the left one the right's mirror, beating about the spine
--   serpents  (a heavy aura, up to Budget's `serpents`) a dragon coiling round the host, or ribbons orbiting it, each a
--             SERPENT: { name, texture (one whole long picture, head at the top: tools/chatgpt/prepare_beam.py --turn
--             --length=1024), length, width, taper?, fade? (0..1: how see-through its tail end is, its head solid),
--             colors | color | role (head to tail), glow (0: drawn normal, a dark smoke), radius (studs from the host's
--             middle), low, high (studs over the feet it climbs between; the same: a flat orbit), turns (round the host
--             in a loop, whole, - the other way), period (seconds a loop), phase?,
--             side? }: its head climbs round the host from low to high and back down and a Trail lays the picture, uncut,
--             along the path just flown; `side` = true for a picture drawn from the side (its back at the picture's left
--             edge): the ribbon is turned to the camera by hand, its back kept up all round the loop. Or a 3D body:
--             { name, model (a key of Models), size? (0.3 to 2, of the model), colors | color | role (its tint),
--             radius, low, high, turns, period, phase? }: one skinned MeshPart in the model's look, its bones laid along the loop each frame, its back
--             kept up, its legs paddling
--   swimmers  (an aura, up to Budget's `swimmers`) small 3D fish going round the host head first, each a SWIMMER:
--             { name, model (a key of Models.fish), length (studs snout to tail at refHeight), orbit = { radius, period,
--             phase?, y, bob?, sway? } (as a piece's orbit: its path wanders), swim? = { degrees, period } (its tail's
--             sweep), secondary? }: one skinned MeshPart in its own picture, its tail sweeping side to side
--   cards     (an aura, up to Budget's `cards`: a held weapon's) a clip FIXED through the host's middle, turning and
--             tilting with it, never with the camera, each a CARD: { name, texture (a Grid4x4 atlas of 256-px cells,
--             stored mirrored: tools/chatgpt/clip_frames.py --fit), size (studs: the picture's side at refHeight,
--             centred on the host), period? (seconds a clip, 1.5), phase? (0..1), lift? (studs up the host),
--             brightness? (0.5..3, 1.2) }: one thin see-through part through the host's middle, across its thin side
--             (z, as a weapon's mesh is made), with a SurfaceGui each face, the front (-z) showing the clip as drawn
--   spirals   (an aura, up to Budget's `spirals` beams in all: a held weapon's) ribbons wound round the host's long axis
--             (its y), each a SPIRAL: { name, texture (a picture drawn along its length that repeats, the beam family:
--             `repeats` (1 to 12) times a turn, 4), colors | color | role (from the low end to the high end), low,
--             high (studs up the host from its middle, at refHeight), radius { low, high } (studs from the axis), width
--             { low, high } (studs), turns (round the host from low to high; - the other way), phase? (0..1 of a turn:
--             where it starts), flow? (pictures a second running up it, - down; 1), glow? (Brightness, 1), alpha?
--             (0..1), fade? (0..0.5: the share of its length at each end that fades in and out, 0.15), additive?
--             (LightEmission 1, true; false: drawn normal, its colour kept on a bright sky), zOffset?, secondary? }: one
--             Beam a half turn, curved, turned to the camera.
--             Its colours: `color` (one, or several from low to high) or a `role`
--   light   { role | color, brightness, range (studs at refHeight), keys = { { t, brightness } } (a one-shot's flare) }
--   glaze     (a mid or heavy aura on a body) { fill = { r, g, b }, outline? = { r, g, b }, fillTransparency? (0.5),
--             outlineTransparency? (0.2) }: the host's own body glazed by a Highlight while it is worn, a colour over
--             it and a bright rim (CGHOW's ice body, 2026-11-14); off when Lod turns the aura to a ribbon or off
--   dome      (a mid or heavy aura) { radius (studs at refHeight, 1 to 10), color = { r, g, b }, texture? (a key of
--             Textures: the streaks the ForceField draws over it, its light edges; none: a plain bubble), transparency?
--             (0..1, 0), fill? (0..1: the transparency of a Neon copy under it, a faint body, lesson 152) }: a real 3D half sphere (Models.Dome, made in Blender) over the host, its rim on the floor at the
--             host's feet, in ForceField: see-through, lit at its edges, the picture's streaks flowing over it by
--             themselves (CGHOW's magic dome, lesson 314); hidden when Lod turns the aura to a ribbon or off
--   highlight (one-shot) { fill = role, outline = role, fillTransparency, outlineTransparency, seconds, max }: an outline
--             on the instances the caller names (`opts.adornees`), fading out
--   projectile (one-shot) a PIECE that flies from `opts.from` to the spot first: { texture, size, seconds, arc, ... };
--             riders = { PIECE, ... }: born on the flying projectile (a `stream` sheds flames and sparks behind it, a
--             `count` at its `delay` bursts there: a launch flash); trail = { texture, colors | role, width, life, glow,
--             alpha, taper }: a ribbon behind it; wait = seconds before it leaves (the impact is then wait + seconds);
--             ease = "in": slow, then fast (a fall); head = { texture, length, width, colors | color | role, glow,
--             zOffset }: the picture on a Beam lying along the flight (its top row behind, its bottom at the front: a
--             dragon's head, a meteor), in place of the particle; path = { { f, x, y, z }, ... }: with a head or a body,
--             it flies a curve through these points (studs in the `along` frame at f of the way from the caster to the
--             spot), even with no `opts.from`; body = { texture | textures, length, width, taper, colors | color |
--             role, glow, zOffset } (with a path): a serpent's body, a curved Beam laid on the path just flown behind
--             the head, its top row at the neck; `textures` = { ... } (2 to 8): one long serpent picture cut in slices,
--             neck to tail, one Beam each, so it bends round a coil (with no head, the first slice is its head);
--             `overlap` (0 to 0.25, of a slice): how far each slice runs into its neighbours, where the pictures fade
--             into each other (prepare_beam.py --slices prints it: a cut seam shows as a line). A piece with
--             `cast = true` is timed from the cast, not the impact (a warning circle)
--   beams     (one-shot) ribbons of a picture between two points of the play's frame, each a BEAM (below): a crescent
--             slash, an energy beam, a crackling bolt
--   follow    (one-shot) true: played on a host, it moves and turns with it (a charge, a transformation)
--   duration  (one-shot) seconds until everything is cleaned up (default: the last particle's end)
--   markers   (one-shot) { name = seconds }: moments a game may sync to ("flash": show the hatched body); (a lasting
--             effect) `peak`: the moment after it is put on that its preview is shot (a serpent where it shows best)
--   start     (lasting) an effect of pieces played once when it is put on (`opts.burst`): a buff's "dish eaten"
--   variants  { name = fields }: a variant lays its fields over the effect; `extra` pieces are added, `drop` names
--             removed (`opts.variant`); defaultVariant names the one used when none is asked. A variant's own `tier`
--             promises less than the effect's (a rarity ladder: the wooden rung cheap, the legendary one mid) and is
--             held to it alone
--   grades    { name = { rate, size, count, alpha } }: multipliers by rarity (`opts.grade`)
--   idle      (lasting) the share of `motion = "run"` pieces (and of a trail's light) that stays while the host stands
--   source    { from = where it was lifted, art = whose pictures, licence }
--   notes     anything a reader must know (the owner's words that shaped it)
--
-- A PIECE (one ParticleEmitter; numbers in studs and seconds at refHeight; enum fields take the engine's names):
--   name      unique in the effect           texture   a key of Textures (never an id)
--   at        an anchor (Anchors)             box       { x, y, z }: born anywhere in this share of the host's box
--   radius    studs: born on/in a sphere of this radius (with shape = "Sphere"); on a one-shot the budget's cut of
--             its pictures shrinks it too
--   role      a palette role, or "keep" (the picture's own colours)          color  colours of its own (Palette)
--   rate      particles a second (lasting)    count     particles at once (one-shot), at `delay` seconds
--   bursts    { { t, n } }: several bursts     stream    { from, to, rate = { a, b }, burst = n }: a rate for a while
--   life      { min, max } seconds            size      { { t, v, e? } } studs over a life
--   transparency { { t, v, e? } }             speed     { min, max }       spread  { x, y } degrees
--   accel     { x, y, z }                     drag      number             rotation, rotSpeed  { min, max } degrees
--   lightEmission, lightInfluence, brightness, zOffset (studs toward the camera, grown with the host like every
--   length), inherit (VelocityInheritance), squash { { t, v } }
--   orientation  FacingCamera | FacingCameraWorldUp | VelocityParallel | VelocityPerpendicular
--   direction Top | Bottom | Front | Back | Left | Right       shape  Box | Sphere | Cylinder | Disc
--   shapeStyle Volume | Surface               shapeInOut Outward | Inward | InAndOut      shapePartial 0..1
--   flipbook  { layout = Grid2x2 | Grid4x4 | Grid8x8, mode = Loop | OneShot | PingPong | Random, fps = { a, b }, random }
--   locked    LockedToPart (lasting: true by default)     flat  true: lies on the ground (rings, sigils)
--   drift     fall | rise | hang (an acceleration sized to the host)       orbit  { radius, period, phase, y, bob?, sway?, heading? }
--             (bob = { studs, period }: up and down; sway = { studs, period }: in and out, so a companion's path wanders;
--             heading = true: its attachment turns to where it goes, Front ahead: with direction Front and
--             VelocityParallel, a locked fish swims head first)
--   aim       degrees: the mark lies across the blow (`opts.angle`)       motion "run": its rate follows the run
--   idle      the share it keeps standing still               secondary  true: not made on Low quality
--   spin      (one-shot, with a box or radius) turns a second of its box about its up axis: particles LOCKED to it
--             swirl (with shapeInOut Inward on a Disc: a pull that spirals into the middle)
--   onLand    (one-shot, with a count) born where each falling beam that `land`s on it lands, `count` each time
--   pose      { at = { x, y, z } studs from the anchor, turn = { x, y, z } degrees (X, then Y, then Z) }: the picture
--             held at a place of its own and turned (a wing with VelocityPerpendicular, as its pack placed it)
--   flap      (lasting, with a pose) { angle, period, phase? }: the posed picture beats about the spine, its far edge
--             swinging up and down `angle` degrees each way every `period` seconds (a wing; the left one mirrors the
--             right, by the side its pose holds it)
--   lift      (lasting) studs over its anchor: a floor aura's tilted swirl or sphere raised until its lowest edge is on
--             the ground (a piece of an effect tagged "floor" may not reach under it: Schema.sink)
--   steady    (lasting) true: a picture that must always be there (a clock's dial, its hands): its rate is kept exact,
--             never cut by quality, level of detail or budget, and one is out at once when it is put on. A hand
--             turning without a seam: rate = 1 / turn, rotSpeed = 360 / turn, life a hair over the turn
--   wing      (wings) the name of a WING it rides: one emitter on each side, at `along` (0..1, from the root to the tip;
--             0.7 by default) of it, beating with it (embers off a fire wing's feathers, dust off a fairy's).
--             `along = { from, to }`: each particle born at its own random spot of that span of the wing, `across` (0..1.5)
--             of its half width either side of its middle (a wing made of many small flames); it starts with `fling`
--             (0..3) times the speed the wing has there (1: it rides the wing a while, more: thrown ahead of the stroke)
--             plus its own `speed` along `direction` in the wing's frame (Right: out to the tip, Top: the leading edge,
--             Back: behind the wing); `beat` (0..1) gives the down stroke more of them and the up stroke fewer. locked = false
--             `off` (-1..1): the middle of the spread moved across the wing (+ toward the leading edge: a nozzle on the
--             trailing edge is -0.6); `throttle` (0..1, a mechanical wing): that share of its rate follows the motion's
--             thrust, `rate` being what it gives at full thrust (a jet's flames roar on the boost, puffs at each tick);
--             `nozzles = { { along, off }, ... }` in place of `along`: born at one of these spots of the wing each time
--             (a jet's nozzles, a machine's vents), `across` still spreading it, the rest as a span's
-- A WING (one Beam on each side; studs at refHeight, the host's frame: +x right, +y up, +z back):
--   name, texture (ONE right wing seen from behind, its root at the middle of the left edge, the file transposed:
--   tools/chatgpt/prepare_wing.py), role | color (several colours run from the root to the tip), at (an anchor, chest
--   by default), root { x, y, z } (the right root from the anchor; the left one's x mirrored), length (root to tip),
--   width (across), sweep (degrees the tips turn back), raise (degrees the tips lift), lean (degrees the wing leans
--   back), flap { angle, period, phase?, fold?, bird?, soft? } (the tips up and down `angle` degrees each way; fold:
--   a butterfly's, swung back about the spine; bird: rigged, shoulder, elbow and wrist beating in 3D, the tip
--   trailing, the hand folding on the up stroke, see Builder's BIRD; soft 0.2..2: how supple a bird's wing is; style:
--   how a bird's wing beats, beat (default) | power | natural | glide | soar, see Builder's STYLES; keys: a beat posed
--   key by key on a two-piece rig (dove | bat), see Builder's WING_KEYS, with `hand`), hand { texture, from, to,
--   wrist?, pivot? } (the picture cut at the wrist by tools/chatgpt/split_wing.py: `texture` the hand, the wing's own
--   `texture` the arm, cross-faded over from..to of the length; wrist: where along the length the hand turns, the
--   middle of from..to by default; pivot: how far off the wing's middle line the joint is, a share of the width, +
--   toward the leading edge), glow (Brightness), alpha (transparency), additive (by default when the
--   picture is drawn on black), zOffset, secondary (not made on Low quality)
--   A MACHINE'S wing: flap { mech = still | fan | hover | rune | holo, angle, period, phase? } never beats (rigid
--   plates: `still` holds them still with the engines at full, `fan` unfolds and folds its blades in hard steps,
--   `hover` spreads its blades wide now and then, `rune` ticks its gears a tooth at a time, `holo` glitches now and
--   then: see Builder's MECH); with `bird = true` too (still, rune or holo, no blades, no hover) the wing beats as a
--   bird's and the motion runs beside the beat every `cycle` seconds (flap.period by default) for its gears, light
--   (build, scan, glitch) and riders only (a magic wing beating gently as an angel's);
--   blades { count, raise = { first, last }, sweep = { first, last }?, shut = { raise, sweep }, ease?, at?, length?,
--   wide?, hover? }: the picture drawn `count` times fanned from the root, each blade unfolding in its turn as the
--   motion opens (degrees added to the wing's raise and sweep, open and shut); at = { first, last }: where along the
--   wing's length each blade's root sits (a row of hilts, all at the root by default); length = { first, last }:
--   each blade's length, a share of the wing's (0.2..1); wide = { first, last }: the raise when the motion spreads
--   them (`hover`); hover = { studs, seconds }: each blade bobs on its own phase;
--   gears { { texture, along, off?, size, step?, rps?, phase?,
--   both?, role | color } }: square pictures turning flat on the wing's outer face (`both`: on its inner face too, seen
--   from the front) (drawn over it as the camera sees it) at `along` and `off` (as a span's), `step`
--   degrees a tooth of the motion's spin (it ticks with it) and `rps` turns a second on their own (Budget `parts`);
--   hover = { studs, seconds }: the whole wing bobs up and down; build = seconds: when first worn the wing shows from
--   the root out to the tip; scan { texture, role | color, glow?, alpha?, band?, every? }: a copy of the wing drawn
--   additive over it, lit only in a band (`band` of the length) that runs root to tip every `every` seconds (a
--   hologram's scan line; 2 more Budget parts); a span piece with `blades = true` is born on a random blade, not the
--   wing
-- A BAND (one Trail): texture, colors | role, width, life, glow, alpha, taper, y (its middle over the feet), length
--   (studs between two repeats of the picture; none: stretched), shift (seconds round its colour loop), phase, span,
--   blade { base, tip } (a weapon's trail: shares of the host's longest side, from its negative end, -1 to 1.5: a
--   smear flung past the weapon's end, as a swung bag's potion: a bag swung by its top hides the arc it sweeps, its
--   smear must lie clear of it; width unused),
--   axis (with blade: X | Y | Z, the host's side the weapon's length runs along, when it is not the longest: an
--   alchemy kit wider than it is tall), face (false: a flat ribbon in the world, as a blade's arc; true by default: it
--   faces the camera). A weapon's trail taken off (VfxLib.detach) fades: its ribbon and sparks end their lives.
-- A BEAM (one Beam of a one-shot; studs at refHeight in the play's frame: -z ahead, +y up, +x right):
--   name, texture, colors | role, from { x, y, z }, to { x, y, z }, bulge { x, y, z } (both control points pushed this
--   way: an arc), width { atFrom, atTo }, delay, life (seconds), transparency / grow { { t, v } } (over its life; grow
--   multiplies the width), edge { atFrom, atTo } (transparency along its length), turn { x, y, z } degrees, aim (degrees
--   added to `opts.angle` about z: the blow's direction), segments, face (true: turns to the camera; else a flat ribbon,
--   lying in its arc's plane when it has a bulge: a slash; standing up when straight), length (studs
--   between two repeats; none: stretched), speed (TextureSpeed: the picture flows), glow (0-3), zOffset, jitter (studs: a bolt
--   whose curve is thrown anew every `flicker` seconds), secondary, start ("from": it leaves the caster, `opts.from`, its
--   `from` then studs off the caster; a lightning lance from the hand to the target), slide { x, y, z } (studs: it
--   starts that far off its place and falls into it over `fall` seconds, faster and faster: a sword dropped from the
--   sky), land (the name of an `onLand` piece born at its `to` end as it lands, or where a `strike` strikes; `landCount`
--   in place of its count), caster (true: from, to, slide and a strike's bend are studs in the CASTER's frame, at
--   `opts.from` facing the spot: -z toward it; a sword standing out of a portal behind the caster's back), emerge
--   (seconds: it comes out along its own line, point first, only what is out shown, the hilt last: out of a portal),
--   strike { at, seconds, bend?, aim?, wander?, trail? } (`at` seconds after its delay it leaves its place and darts,
--   point first, turned along its path, into the spot (`aim` studs off it, play frame) over `seconds`, faster and
--   faster, on a path bent `bend` studs (plus a random `wander`); `trail` = { texture, colors | role, width, life, glow,
--   alpha, taper }: a ribbon behind its hilt as it flies; it is gone as it strikes, its `land` piece born there).
-- A PIECE's `caster` { x, y, z } (one-shot, no box): born at that spot of the caster's frame (the portal behind them);
-- with `upright = true` the picture stands still in that frame, facing the spot, whatever the camera (a portal's face).
-- `upright` on any other one-shot piece stands it facing the play's ahead (-z): on a `follow` charge, the host's front
-- (a magic circle held before the hands; `locked = true` so it turns with the host).
-- A PIECE's or a BEAM's `along` (one-shot): a share of the way from the caster (0) to the spot (1), on the spot's
-- ground: the piece is born there, the beam's numbers are in a frame there (turned as the caster's: -z toward the
-- spot); a beam's along = { a, b } puts its from end at a and its to end at b (a crack running down the path). A BEAM's
-- `rise` (with emerge): the name of an `onLand` piece born where it starts to come out (`riseCount` in place of its
-- count): rocks and dust as a spike breaks the ground. A BEAM's `flat = true`: a straight ribbon lying level (a crack
-- of lava running along the ground), its width across its line; not with face, bulge, jitter or strike.
-- A BEAM's `stand = true`: a bulged flat ribbon standing up (its width up, a curved wall), not lying in its arc's
-- plane; not with face or flat. A BEAM's `roll = { to, seconds, at? }` (with a number `along`): `at` seconds after
-- its delay the whole beam slides along the path from its `along` to `to` (0 to 1.5) over `seconds`, at one speed (a
-- wave rolling to the target); not with caster, start, slide, strike, emerge or jitter. A BEAM's `taut = { at,
-- seconds }` (with a bulge, its slack): `at` seconds after its delay the bulge is pulled out over `seconds`, snapping
-- a little past straight and back (a chain drawn tight); an emerging beam may have a bulge then, `at` at least its
-- `emerge`.
-- A PIECE's `ride` (one-shot): the name of a rolling beam; the piece is born on that beam's middle and goes with it
-- (its box, when it has one, turned as the beam: x along its line; `offset` studs from the middle in that turned frame:
-- its foot on the ground), so a stream sheds spray all along the way. Not with along, caster or spin.
-- A PIECE's `offset` { x, y, z }: studs from its anchor (at refHeight); on an `along` piece, studs in the frame on
-- the path (-z toward the spot). `upright = "in"`: the picture stands facing the play's middle (level) from where it
-- is born, whatever the camera (portals round a target, each turned to it).
-- A PIECE's `ground = true` (one-shot): born on the floor straight under the spot, level and turned as the play about
-- the up axis (`offset` studs from there; a box or radius lies there too): the floor is `opts.ground` (a height or a
-- point) when the game gives it, else the first anchored, collidable surface below that is not a character's (one with
-- a Humanoid) nor one of `opts.ignore`, else the foot of the box. A cast played at a held weapon's head marks the
-- ground under the slime, whatever the weapon's tilt. Not with at, along, caster or ride.
local Anchors = require(if script then script.Parent.Anchors else "./Anchors")
local Budget = require(if script then script.Parent.Budget else "./Budget")
local Models = require(if script then script.Parent.Models else "./Models")
local Textures = require(if script then script.Parent.Textures else "./Textures")

local Schema = {}

Schema.Kinds = {
	aura = true,
	trail = true,
	buff = true,
	wings = true,
	world = true,
	hit = true,
	burst = true,
	reveal = true,
	skill = true,
}
Schema.Hosts = { pet = true, character = true, slime = true, egg = true, weapon = true, world = true, any = true }
Schema.Blends = { additive = true, normal = true, ["normal+bloom"] = true }

local ENUMS = {
	orientation = Enum.ParticleOrientation,
	direction = Enum.NormalId,
	shape = Enum.ParticleEmitterShape,
	shapeStyle = Enum.ParticleEmitterShapeStyle,
	shapeInOut = Enum.ParticleEmitterShapeInOut,
}

local textureProblem

-- The first thing wrong with a SWIMMER (one of the library's fish going round an aura's host), or nil.
function Schema.swimmerProblem(fields, swimmer, what)
	if fields.kind ~= "aura" then
		return `{what}: only an aura has swimmers`
	end
	if type(swimmer.name) ~= "string" then
		return `{what}: a name`
	end
	if Models.fish[swimmer.model] == nil then
		return `{what}: model is a key of Models.fish`
	end
	if type(swimmer.length) ~= "number" or swimmer.length <= 0 or swimmer.length > 3 then
		return `{what}: length is studs from snout to tail at refHeight, over 0 and at most 3`
	end
	local orbit = swimmer.orbit
	if
		type(orbit) ~= "table"
		or type(orbit.radius) ~= "number"
		or type(orbit.y) ~= "number"
		or type(orbit.period) ~= "number"
		or orbit.period == 0
	then
		return `{what}: orbit \{ radius, period (not 0), phase?, y, bob?, sway? }`
	end
	for _, field in { "bob", "sway" } do
		local beat = orbit[field]
		if
			beat ~= nil
			and (type(beat) ~= "table" or type(beat[1]) ~= "number" or type(beat[2]) ~= "number" or beat[2] <= 0)
		then
			return `{what}: orbit {field} is \{ studs, period } with a period over 0 seconds`
		end
	end
	local swim = swimmer.swim
	if swim ~= nil and (type(swim) ~= "table" or (swim.period ~= nil and swim.period <= 0)) then
		return `{what}: swim \{ degrees?, period? (over 0) }`
	end
	return nil
end

-- The first thing wrong with a CARD (a clip fixed through a held weapon's middle), or nil.
function Schema.cardProblem(fields, card, what)
	if fields.kind ~= "aura" then
		return `{what}: only an aura has cards`
	end
	if type(card.name) ~= "string" then
		return `{what}: a name`
	end
	local problem = textureProblem(card.texture, `{what} texture`)
	if problem then
		return problem
	end
	local numbers = {
		{ "size", 0.2, 12, true },
		{ "period", 0.3, 10 },
		{ "phase", 0, 1 },
		{ "lift", -6, 6 },
		{ "brightness", 0.5, 3 },
	}
	for _, rule in numbers do
		local value = card[rule[1]]
		if (value ~= nil or rule[4]) and (type(value) ~= "number" or value < rule[2] or value > rule[3]) then
			return `{what}: {rule[1]} is {rule[2]} to {rule[3]}`
		end
	end
	return nil
end

-- The first thing wrong with a SPIRAL (a ribbon wound round a held weapon), or nil.
function Schema.spiralProblem(fields, spiral, what)
	if fields.kind ~= "aura" then
		return `{what}: only an aura has spirals`
	end
	if type(spiral.name) ~= "string" then
		return `{what}: a name`
	end
	local problem = textureProblem(spiral.texture, `{what} texture`)
	if problem then
		return problem
	end
	for _, key in { "radius", "width" } do
		local pair = spiral[key]
		if
			type(pair) ~= "table"
			or type(pair[1]) ~= "number"
			or type(pair[2]) ~= "number"
			or pair[1] < 0
			or pair[2] < 0
			or pair[1] > 3
			or pair[2] > 3
		then
			return `{what}: {key} \{ low, high } of 0 to 3 studs`
		end
	end
	local numbers = {
		{ "low", -6, 6, true },
		{ "high", -6, 6, true },
		{ "turns", -6, 6, true },
		{ "phase", 0, 1 },
		{ "flow", -5, 5 },
		{ "glow", 0, 5 },
		{ "alpha", 0, 1 },
		{ "fade", 0, 0.5 },
		{ "zOffset", -2, 2 },
		{ "repeats", 1, 12 },
	}
	for _, rule in numbers do
		local value = spiral[rule[1]]
		if (value ~= nil or rule[4]) and (type(value) ~= "number" or value < rule[2] or value > rule[3]) then
			return `{what}: {rule[1]} is {rule[2]} to {rule[3]}`
		end
	end
	if spiral.high <= spiral.low then
		return `{what}: high over low`
	end
	if math.abs(spiral.turns) < 0.25 then
		return `{what}: a quarter turn at least`
	end
	if spiral.colors ~= nil then
		return `{what}: color (one or several, low to high) or a role, not colors`
	end
	if spiral.color == nil and spiral.role == nil then
		return `{what}: color or a role`
	end
	return nil
end

-- The first thing wrong with a SERPENT (an aura's dragon coiling round its host), or nil.
function Schema.serpentProblem(fields, serpent, what)
	if fields.kind ~= "aura" or fields.tier ~= "heavy" then
		return `{what}: only a heavy aura has a serpent`
	end
	if type(serpent.name) ~= "string" then
		return `{what}: a name`
	end
	if serpent.textures ~= nil or serpent.overlap ~= nil then
		return `{what}: one whole picture (texture), not slices: a Trail bends it with no joint`
	end
	local numbers = {
		{ "radius", 0.5, 12 },
		{ "low", -2, 12 },
		{ "high", -2, 16 },
		{ "turns", -6, 6 },
		{ "period", 1, 30 },
	}
	if serpent.model ~= nil then
		if Models.list[serpent.model] == nil then
			return `{what}: model is a key of Models`
		end
		for _, field in { "texture", "length", "width", "taper", "side", "glow" } do
			if serpent[field] ~= nil then
				return `{what}: a model has its own body (no {field})`
			end
		end
		if serpent.size ~= nil and (type(serpent.size) ~= "number" or serpent.size < 0.3 or serpent.size > 2) then
			return `{what}: size is 0.3 to 2 (of the model)`
		end
	else
		local problem = textureProblem(serpent.texture, `{what} texture`)
		if problem then
			return problem
		end
		table.insert(numbers, { "length", 2, 40 })
		table.insert(numbers, { "width", 0.2, 10 })
	end
	for _, rule in numbers do
		local value = serpent[rule[1]]
		if type(value) ~= "number" or value < rule[2] or value > rule[3] then
			return `{what}: {rule[1]} is {rule[2]} to {rule[3]}`
		end
	end
	if serpent.turns == 0 or serpent.turns % 1 ~= 0 then
		return `{what}: turns is a whole number, not 0 (the loop closes on itself)`
	end
	if serpent.taper ~= nil and (type(serpent.taper) ~= "number" or serpent.taper < 0 or serpent.taper > 1) then
		return `{what}: taper is 0 to 1`
	end
	if serpent.fade ~= nil and (type(serpent.fade) ~= "number" or serpent.fade < 0 or serpent.fade > 1) then
		return `{what}: fade is 0 to 1`
	end
	if serpent.phase ~= nil and type(serpent.phase) ~= "number" then
		return `{what}: phase is a share of a turn`
	end
	if serpent.side ~= nil and type(serpent.side) ~= "boolean" then
		return `{what}: side is true or false`
	end
	if serpent.colors == nil and serpent.color == nil and serpent.role == nil then
		return `{what}: colors, color or a role`
	end
	return nil
end

local function isEnumName(enum, name)
	if type(name) ~= "string" then
		return false
	end
	local ok, item = pcall(function()
		return (enum :: any)[name]
	end)
	return ok and item ~= nil
end

local function isPair(value)
	return type(value) == "table" and type(value[1]) == "number" and (value[2] == nil or type(value[2]) == "number")
end

local function isTriple(value)
	return type(value) == "table"
		and type(value[1]) == "number"
		and type(value[2]) == "number"
		and type(value[3]) == "number"
end

local function keysProblem(points, what, low, high)
	if type(points) ~= "table" or #points < 2 or #points > 20 then
		return `{what}: 2 to 20 keypoints`
	end
	if points[1][1] ~= 0 or points[#points][1] ~= 1 then
		return `{what}: keypoints run from t 0 to t 1`
	end
	local last = -1
	for _, point in points do
		if type(point[1]) ~= "number" or type(point[2]) ~= "number" or point[1] < last then
			return `{what}: a keypoint is \{ t, value, envelope? \} in order`
		end
		last = point[1]
		if point[2] < low or point[2] > high then
			return `{what}: a value is out of {low} to {high}`
		end
	end
	return nil
end

function textureProblem(key, what)
	if type(key) ~= "string" or Textures.get(key) == nil then
		return `{what}: texture {tostring(key)} is not a key of Textures`
	end
	return nil
end

-- The owner's art is never recoloured: a piece that wears it keeps its colours, unless its picture says the source game
-- tints it (Textures `tint`).
local function tintProblem(piece, what)
	local entry = Textures.get(piece.texture)
	if entry and entry.owner and not entry.tint then
		if piece.color ~= nil or (piece.role ~= nil and piece.role ~= "keep") then
			return `{what}: {piece.texture} is the owner's art, never recoloured (role "keep", no color)`
		end
	end
	return nil
end

-- (the beats Builder's STYLES knows)
local WING_STYLES = { beat = true, power = true, natural = true, glide = true, soar = true }
-- (the keyed beats Builder's WING_KEYS knows)
local WING_KEYS = { dove = true, bat = true }
-- (the machines' motions Builder's MECH knows, and how their moves go)
local WING_MECH = { still = true, fan = true, hover = true, rune = true, holo = true }
local MECH_EASES = { snap = true, smooth = true, linear = true, drop = true }

-- A hover { studs, seconds }: true when it is not one.
local function hoverProblem(hover)
	return type(hover) ~= "table"
		or type(hover[1]) ~= "number"
		or type(hover[2]) ~= "number"
		or hover[1] < 0
		or hover[1] > 0.6
		or hover[2] < 0.5
		or hover[2] > 10
end

local function flapProblem(flap, what)
	if type(flap) ~= "table" or type(flap.angle) ~= "number" or type(flap.period) ~= "number" then
		return `{what}: flap is \{ angle, period, phase?, fold? \}`
	end
	if flap.angle <= 0 or flap.angle > 60 or flap.period < 0.3 or flap.period > 10 then
		return `{what}: flap swings 0 to 60 degrees over 0.3 to 10 seconds`
	end
	if flap.bird and flap.fold then
		return `{what}: flap is a bird's (bird) or a butterfly's (fold), not both`
	end
	if flap.soft ~= nil and (not flap.bird or type(flap.soft) ~= "number" or flap.soft < 0.2 or flap.soft > 2) then
		return `{what}: flap.soft (0.2 to 2) is for a bird's beat`
	end
	if flap.style ~= nil and (not flap.bird or not WING_STYLES[flap.style]) then
		return `{what}: flap.style (beat, power, natural, glide, soar) is for a bird's beat`
	end
	if flap.keys ~= nil and (flap.bird or flap.fold or not WING_KEYS[flap.keys]) then
		return `{what}: flap.keys (dove, bat) is a beat of its own, posed key by key: not with bird or fold`
	end
	if flap.mech ~= nil and (flap.fold or flap.keys or not WING_MECH[flap.mech]) then
		return `{what}: flap.mech (still, fan, hover, rune, holo) is a machine's motion: not with fold or keys`
	end
	if flap.mech ~= nil and flap.bird and (flap.mech == "fan" or flap.mech == "hover") then
		return `{what}: a bird's wing takes a motion for its gears and light (still, rune, holo), not fan or hover`
	end
	if
		flap.cycle ~= nil
		and (not (flap.mech and flap.bird) or type(flap.cycle) ~= "number" or flap.cycle < 0.5 or flap.cycle > 20)
	then
		return `{what}: flap.cycle (0.5 to 20 seconds) is the motion's beat on a bird's wing with flap.mech`
	end
	return nil
end

-- A mechanical wing's blades { count, raise = { first, last }, sweep = { first, last }?, shut = { raise, sweep },
-- ease? } and gears { { texture, along, off?, size, step?, rps?, phase?, both?, role | color } }.
local function partsProblem(wing, what, span)
	local mech = wing.flap ~= nil and wing.flap.mech ~= nil
	local bird = wing.flap ~= nil and wing.flap.bird == true
	if (wing.blades ~= nil or wing.gears ~= nil) and not mech then
		return `{what}: blades and gears are a machine's: the wing needs flap.mech`
	end
	if (wing.blades ~= nil or wing.hover ~= nil) and bird then
		return `{what}: blades and hover are for a wing that stands still: not on a bird's beat`
	end
	local blades = wing.blades
	if blades ~= nil then
		if type(blades) ~= "table" or type(blades.count) ~= "number" or blades.count < 2 or blades.count > 8 then
			return `{what}: blades.count is 2 to 8`
		end
		if not isPair(blades.raise) or blades.raise[2] == nil then
			return `{what}: blades.raise is \{ first, last \} degrees, open`
		end
		if blades.sweep ~= nil and (not isPair(blades.sweep) or blades.sweep[2] == nil) then
			return `{what}: blades.sweep is \{ first, last \} degrees, open`
		end
		if not isPair(blades.shut) or blades.shut[2] == nil then
			return `{what}: blades.shut is \{ raise, sweep \} degrees, folded`
		end
		if blades.ease ~= nil and not MECH_EASES[blades.ease] then
			return `{what}: blades.ease is snap, smooth, linear or drop`
		end
		for _, field in { "at", "length" } do
			local pair = blades[field]
			if pair ~= nil and (not isPair(pair) or pair[2] == nil) then
				return `{what}: blades.{field} is \{ first, last \}, shares of the wing's length`
			end
		end
		if
			blades.at ~= nil and (math.min(blades.at[1], blades.at[2]) < 0 or math.max(blades.at[1], blades.at[2]) > 1)
		then
			return `{what}: blades.at is 0 to 1 of the wing's length`
		end
		if
			blades.length ~= nil
			and (math.min(blades.length[1], blades.length[2]) < 0.2 or math.max(blades.length[1], blades.length[2]) > 1)
		then
			return `{what}: blades.length is 0.2 to 1 of the wing's length`
		end
		if blades.wide ~= nil and (not isPair(blades.wide) or blades.wide[2] == nil) then
			return `{what}: blades.wide is \{ first, last \} degrees, spread wide`
		end
		if blades.hover ~= nil and hoverProblem(blades.hover) then
			return `{what}: blades.hover is \{ studs (0 to 0.6), seconds (0.5 to 10) \}`
		end
	end
	for index, gear in wing.gears or {} do
		local label = `{what} gear {index}`
		local problem = textureProblem(gear.texture, label)
		if problem then
			return problem
		end
		if type(gear.along) ~= "number" or gear.along < 0 or gear.along > 1 then
			return `{label}: along is 0 to 1 of the wing, from the root to the tip`
		end
		if gear.off ~= nil and (type(gear.off) ~= "number" or math.abs(gear.off) > 1) then
			return `{label}: off is -1 to 1 of the wing's half width, + toward the leading edge`
		end
		if type(gear.size) ~= "number" or gear.size <= 0 or gear.size > span then
			return `{label}: size is over 0 up to {span} studs`
		end
		if gear.rps ~= nil and (type(gear.rps) ~= "number" or math.abs(gear.rps) > 3) then
			return `{label}: rps (turns a second) is -3 to 3`
		end
		if gear.step ~= nil and (type(gear.step) ~= "number" or math.abs(gear.step) > 180) then
			return `{label}: step (degrees a tooth of the motion's spin) is -180 to 180`
		end
		if gear.both ~= nil and type(gear.both) ~= "boolean" then
			return `{label}: both (on the wing's inner face too) is true or false`
		end
		if gear.color == nil and gear.role == nil then
			return `{label}: colors or a role`
		end
		problem = tintProblem(gear, label)
		if problem then
			return problem
		end
	end
	if (wing.hover ~= nil or wing.scan ~= nil or wing.build ~= nil) and not mech then
		return `{what}: hover, scan and build are a machine's (special wings that stand still): the wing needs flap.mech`
	end
	if wing.hover ~= nil and hoverProblem(wing.hover) then
		return `{what}: hover is \{ studs (0 to 0.6), seconds (0.5 to 10) \}`
	end
	local scan = wing.scan
	if scan ~= nil then
		if type(scan) ~= "table" then
			return `{what}: scan is \{ glow, alpha?, band?, every?, texture? \}`
		end
		if scan.texture ~= nil then
			local problem = textureProblem(scan.texture, `{what} scan`)
			if problem then
				return problem
			end
		end
		if scan.glow ~= nil and (type(scan.glow) ~= "number" or scan.glow < 0 or scan.glow > 5) then
			return `{what}: scan.glow is 0 to 5`
		end
		if scan.alpha ~= nil and (type(scan.alpha) ~= "number" or scan.alpha < 0 or scan.alpha > 1) then
			return `{what}: scan.alpha is 0 to 1`
		end
		if scan.band ~= nil and (type(scan.band) ~= "number" or scan.band < 0.03 or scan.band > 0.3) then
			return `{what}: scan.band (a share of the length either side of the line) is 0.03 to 0.3`
		end
		if scan.every ~= nil and (type(scan.every) ~= "number" or scan.every < 0.8 or scan.every > 10) then
			return `{what}: scan.every (seconds a pass) is 0.8 to 10`
		end
	end
	if wing.build ~= nil and (type(wing.build) ~= "number" or wing.build < 0.3 or wing.build > 4) then
		return `{what}: build (seconds to build the wing from the root out) is 0.3 to 4`
	end
	return nil
end

function Schema.pieceProblem(_effect, piece, what, oneShot)
	if type(piece) ~= "table" then
		return `{what} is not a table`
	end
	if type(piece.name) ~= "string" or piece.name == "" then
		return `{what}: no name`
	end
	what = `{what} ({piece.name})`
	local problem = textureProblem(piece.texture, what)
	if problem then
		return problem
	end
	if piece.at ~= nil and not Anchors.exists(piece.at) then
		return `{what}: no anchor {tostring(piece.at)}`
	end
	if not isPair(piece.life) or piece.life[1] <= 0 or (piece.life[2] or piece.life[1]) > 20 then
		return `{what}: life is \{ min, max \} over 0 up to 20 seconds`
	end
	problem = keysProblem(piece.size, `{what}: size`, 0, 60)
	if problem then
		return problem
	end
	if piece.transparency ~= nil then
		problem = keysProblem(piece.transparency, `{what}: transparency`, 0, 1)
		if problem then
			return problem
		end
	end
	local gives = 0
	if piece.rate ~= nil then
		gives += 1
		if type(piece.rate) ~= "number" or piece.rate <= 0 or piece.rate > 100 then
			return `{what}: rate is over 0 up to 100 a second (the most a phone's emitter gives)`
		end
	end
	if piece.count ~= nil or piece.bursts ~= nil or piece.stream ~= nil then
		gives += 1
	end
	if gives ~= 1 then
		return `{what}: a piece has a rate (it lasts) or a count / bursts / stream (it plays once), not both`
	end
	if oneShot and piece.rate ~= nil then
		return `{what}: a one-shot's piece has a count, bursts or a stream, not a rate`
	end
	if not oneShot and piece.rate == nil then
		return `{what}: a lasting effect's piece has a rate (a "start" burst goes in start)`
	end
	for field, enum in ENUMS do
		if piece[field] ~= nil and not isEnumName(enum, piece[field]) then
			return `{what}: {field} {tostring(piece[field])} is not an engine name`
		end
	end
	if piece.flipbook ~= nil then
		local flipbook = piece.flipbook
		if not isEnumName(Enum.ParticleFlipbookLayout, flipbook.layout) then
			return `{what}: flipbook layout is Grid2x2, Grid4x4 or Grid8x8`
		end
		if flipbook.mode ~= nil and not isEnumName(Enum.ParticleFlipbookMode, flipbook.mode) then
			return `{what}: flipbook mode is Loop, OneShot, PingPong or Random`
		end
	end
	for _, field in { "speed", "rotation", "rotSpeed" } do
		if piece[field] ~= nil and not isPair(piece[field]) then
			return `{what}: {field} is \{ min, max \}`
		end
	end
	if piece.box ~= nil and (type(piece.box) ~= "table" or #piece.box ~= 3) then
		return `{what}: box is \{ x, y, z \} shares of the host's box`
	end
	if piece.lift ~= nil and (type(piece.lift) ~= "number" or piece.lift < 0 or piece.lift > 20 or oneShot) then
		return `{what}: lift is 0 to 20 studs over the anchor, on a lasting effect`
	end
	if piece.drift ~= nil and piece.drift ~= "fall" and piece.drift ~= "rise" and piece.drift ~= "hang" then
		return `{what}: drift is fall, rise or hang`
	end
	if piece.orbit ~= nil then
		for _, field in { "bob", "sway" } do
			local beat = piece.orbit[field]
			if beat ~= nil and (not isPair(beat) or beat[2] == nil or beat[2] <= 0) then
				return `{what}: orbit {field} is \{ studs, period } with a period over 0 seconds`
			end
		end
		if piece.orbit.heading ~= nil and piece.orbit.heading ~= true then
			return `{what}: orbit heading is true or left out`
		end
	end
	if piece.flap ~= nil then
		if piece.pose == nil or oneShot then
			return `{what}: flap swings a posed picture of a lasting effect (a wing): it needs a pose`
		end
		problem = flapProblem(piece.flap, what)
		if problem then
			return problem
		end
	end
	local along = piece.along
	local span = type(along) == "table"
	if piece.nozzles ~= nil then
		local nozzles = piece.nozzles
		if along ~= nil or type(nozzles) ~= "table" or #nozzles < 1 or #nozzles > 6 then
			return `{what}: nozzles is 1 to 6 spots \{ along, off } of its wing, in place of along`
		end
		for _, spot in nozzles do
			if not isPair(spot) or spot[2] == nil or spot[1] < 0 or spot[1] > 1 or math.abs(spot[2]) > 1 then
				return `{what}: a nozzle is \{ along 0..1, off -1..1 } of its wing`
			end
		end
		if piece.wing == nil or piece.locked ~= false then
			return `{what}: nozzles are on a wing and leave their particles in the air (locked = false)`
		end
		span = true
	elseif span then
		local from, to = along[1], along[2]
		if type(from) ~= "number" or type(to) ~= "number" or from < 0 or to > 1 or from >= to then
			return `{what}: along \{ from, to } is a span of its wing, 0 <= from < to <= 1`
		end
		if piece.wing == nil or piece.locked ~= false then
			return `{what}: a span rides a wing and leaves its particles in the air (locked = false)`
		end
	elseif along ~= nil and (type(along) ~= "number" or along < 0 or along > 1) then
		return `{what}: along is 0 to 1 of its wing, from the root to the tip`
	end
	for _, field in { { "across", 1.5 }, { "fling", 3 }, { "beat", 1 }, { "throttle", 1 } } do
		local value = piece[field[1]]
		if value ~= nil and (not span or type(value) ~= "number" or value < 0 or value > field[2]) then
			return `{what}: {field[1]} (0 to {field[2]}) is for a piece born over a span of its wing`
		end
	end
	if piece.off ~= nil and (not span or type(piece.off) ~= "number" or math.abs(piece.off) > 1) then
		return `{what}: off (-1 to 1 of the wing's half width) is for a piece born over a span of its wing`
	end
	if piece.blades ~= nil and (not span or piece.blades ~= true) then
		return `{what}: blades = true (born on the wing's blades) is for a piece born over a span of its wing`
	end
	if piece.lightEmission ~= nil and (piece.lightEmission < 0 or piece.lightEmission > 1) then
		return `{what}: lightEmission is 0 to 1`
	end
	if piece.spin ~= nil then
		if type(piece.spin) ~= "number" or math.abs(piece.spin) > 3 or not oneShot then
			return `{what}: spin is -3 to 3 turns a second, on a one-shot's piece`
		end
		if piece.box == nil and piece.radius == nil then
			return `{what}: spin turns the piece's box: it needs a box or a radius`
		end
	end
	if piece.onLand ~= nil and (piece.onLand ~= true or not oneShot or piece.count == nil or piece.bursts ~= nil) then
		return `{what}: onLand = true is a one-shot's piece with a count, born where each falling beam lands`
	end
	local caster = piece.caster
	local triple = type(caster) == "table"
		and type(caster[1]) == "number"
		and type(caster[2]) == "number"
		and type(caster[3]) == "number"
	if caster ~= nil and (not triple or not oneShot or piece.box ~= nil or piece.radius ~= nil) then
		return `{what}: caster is \{ x, y, z \} studs in the caster's frame, a one-shot's piece with no box or radius`
	end
	-- (a wing's piece has its own `along`: where on the wing)
	if piece.along ~= nil and piece.wing == nil then
		if type(piece.along) ~= "number" or not oneShot or caster ~= nil or piece.box ~= nil or piece.radius ~= nil then
			return `{what}: along is a share of the way from the caster to the spot, a one-shot's piece with no box, radius or caster`
		end
	end
	if
		piece.upright ~= nil
		and (
			(piece.upright ~= true and piece.upright ~= "in")
			or not oneShot
			or piece.flat ~= nil
			or piece.box ~= nil
			or piece.radius ~= nil
		)
	then
		return `{what}: upright = true (facing ahead) or "in" (facing the middle) stands a one-shot piece's picture (no flat, box or radius)`
	end
	if piece.offset ~= nil and not isTriple(piece.offset) then
		return `{what}: offset is \{ x, y, z \} studs from its anchor`
	end
	if piece.ride ~= nil then
		if type(piece.ride) ~= "string" or not oneShot then
			return `{what}: ride names a rolling beam of a one-shot`
		end
		if piece.along ~= nil or caster ~= nil or piece.spin ~= nil then
			return `{what}: a riding piece goes with its beam (no along, caster or spin)`
		end
	end
	if piece.cast ~= nil and (piece.cast ~= true or not oneShot) then
		return `{what}: cast = true times a one-shot piece from the cast, not the impact`
	end
	if
		piece.ground ~= nil
		and (
			piece.ground ~= true
			or not oneShot
			or piece.at ~= nil
			or piece.along ~= nil
			or caster ~= nil
			or piece.ride ~= nil
		)
	then
		return `{what}: ground = true lays a one-shot's piece on the floor under the spot (no at, along, caster or ride)`
	end
	return tintProblem(piece, what)
end

function Schema.beamProblem(_effect, beam, what)
	if type(beam) ~= "table" then
		return `{what} is not a table`
	end
	local problem = textureProblem(beam.texture, what)
	if problem then
		return problem
	end
	if not isTriple(beam.from) or not isTriple(beam.to) then
		return `{what}: from and to are \{ x, y, z \} studs`
	end
	if beam.start ~= nil and beam.start ~= "from" then
		return `{what}: start is "from" (the beam leaves the caster, opts.from) or nothing`
	end
	if beam.bulge ~= nil and not isTriple(beam.bulge) then
		return `{what}: bulge is \{ x, y, z \} studs`
	end
	if beam.turn ~= nil and not isTriple(beam.turn) then
		return `{what}: turn is \{ x, y, z \} degrees`
	end
	local width = beam.width
	if not isPair(width) or width[1] < 0 or width[1] > 20 or (width[2] or 0) < 0 or (width[2] or 0) > 20 then
		return `{what}: width is \{ atFrom, atTo \}, 0 to 20 studs`
	end
	if type(beam.life) ~= "number" or beam.life <= 0 or beam.life > 5 then
		return `{what}: life is over 0 up to 5 seconds`
	end
	if beam.delay ~= nil and (type(beam.delay) ~= "number" or beam.delay < 0) then
		return `{what}: delay is 0 or more seconds`
	end
	if beam.transparency ~= nil then
		problem = keysProblem(beam.transparency, `{what}: transparency`, 0, 1)
		if problem then
			return problem
		end
	end
	if beam.grow ~= nil then
		problem = keysProblem(beam.grow, `{what}: grow`, 0, 4)
		if problem then
			return problem
		end
	end
	if beam.edge ~= nil and (not isPair(beam.edge) or beam.edge[1] < 0 or beam.edge[1] > 1) then
		return `{what}: edge is \{ atFrom, atTo \} transparencies`
	end
	if beam.segments ~= nil and (type(beam.segments) ~= "number" or beam.segments < 1 or beam.segments > 50) then
		return `{what}: segments is 1 to 50`
	end
	if beam.jitter ~= nil and (type(beam.jitter) ~= "number" or beam.jitter < 0 or beam.jitter > 10) then
		return `{what}: jitter is 0 to 10 studs`
	end
	if beam.flicker ~= nil and (type(beam.flicker) ~= "number" or beam.flicker < 0.03) then
		return `{what}: flicker is at least 0.03 seconds (no strobe)`
	end
	if beam.colors == nil and beam.role == nil then
		return `{what}: colors or a role`
	end
	if beam.glow ~= nil and (beam.glow < 0 or beam.glow > 3) then
		return `{what}: glow is 0 to 3 (above 1: a black-backed picture drawn brighter, a slash that must pop)`
	end
	if beam.slide ~= nil and (not isTriple(beam.slide) or beam.jitter ~= nil) then
		return `{what}: slide is \{ x, y, z \} studs it falls from (not with jitter)`
	end
	if beam.fall ~= nil and (beam.slide == nil or type(beam.fall) ~= "number" or beam.fall < 0.03 or beam.fall > 2) then
		return `{what}: fall is 0.03 to 2 seconds of a sliding beam`
	end
	if beam.land ~= nil and ((beam.slide == nil and beam.strike == nil) or type(beam.land) ~= "string") then
		return `{what}: land names the piece born where a sliding or striking beam lands`
	end
	if beam.caster ~= nil and (beam.caster ~= true or beam.start ~= nil) then
		return `{what}: caster = true puts its numbers in the caster's frame (not with start)`
	end
	local along = beam.along
	if
		along ~= nil
		and (
			(type(along) ~= "number" and not (isPair(along) and type(along[2]) == "number"))
			or beam.caster ~= nil
			or beam.start ~= nil
		)
	then
		return `{what}: along is a share of the way from the caster to the spot (or \{ from, to \}), not with caster or start`
	end
	if
		beam.flat ~= nil
		and (beam.flat ~= true or beam.face == true or beam.bulge ~= nil or beam.jitter ~= nil or beam.strike ~= nil)
	then
		return `{what}: flat = true lays a straight beam on the ground (not with face, bulge, jitter or strike)`
	end
	if beam.rise ~= nil and (beam.emerge == nil or type(beam.rise) ~= "string") then
		return `{what}: rise names the piece born where an emerging beam comes out`
	end
	if beam.stand ~= nil and (beam.stand ~= true or beam.face == true or beam.flat ~= nil) then
		return `{what}: stand = true stands a flat ribbon up (not with face or flat)`
	end
	local roll = beam.roll
	if roll ~= nil then
		if type(roll) ~= "table" or type(roll.to) ~= "number" or roll.to < 0 or roll.to > 1.5 then
			return `{what}: roll is \{ to (0 to 1.5 of the way), seconds, at? \}`
		end
		if type(roll.seconds) ~= "number" or roll.seconds < 0.05 or roll.seconds > 4 then
			return `{what}: roll.seconds is 0.05 to 4`
		end
		if roll.at ~= nil and (type(roll.at) ~= "number" or roll.at < 0) then
			return `{what}: roll.at is 0 or more seconds after its delay`
		end
		if type(beam.along) ~= "number" then
			return `{what}: a rolling beam starts at a number along (a share of the way from the caster)`
		end
		if beam.slide ~= nil or beam.strike ~= nil or beam.emerge ~= nil or beam.jitter ~= nil then
			return `{what}: a rolling beam only rolls (no slide, strike, emerge or jitter)`
		end
		if (roll.at or 0) + roll.seconds > beam.life then
			return `{what}: a rolling beam lives until it has rolled (at + seconds within its life)`
		end
	end
	local taut = beam.taut
	if taut ~= nil then
		if type(taut) ~= "table" or type(taut.at) ~= "number" or taut.at < 0 then
			return `{what}: taut is \{ at, seconds \}`
		end
		if type(taut.seconds) ~= "number" or taut.seconds < 0.03 or taut.seconds > 2 then
			return `{what}: taut.seconds is 0.03 to 2`
		end
		if beam.bulge == nil then
			return `{what}: taut pulls out a bulge (its slack): it needs one`
		end
		if beam.strike ~= nil or beam.slide ~= nil or beam.jitter ~= nil or beam.roll ~= nil then
			return `{what}: a beam drawn tight stays where it is (no strike, slide, jitter or roll)`
		end
		if beam.emerge ~= nil and taut.at < beam.emerge then
			return `{what}: an emerging beam is drawn tight once it is out (taut.at at least emerge)`
		end
		if taut.at + taut.seconds > beam.life then
			return `{what}: taut ends within its life`
		end
	end
	local moving = beam.slide ~= nil
		or beam.jitter ~= nil
		or beam.start ~= nil
		or (beam.bulge ~= nil and beam.taut == nil)
	if beam.emerge ~= nil then
		if type(beam.emerge) ~= "number" or beam.emerge < 0.05 or beam.emerge > 2 then
			return `{what}: emerge is 0.05 to 2 seconds of coming out along its own line`
		end
		if moving then
			return `{what}: an emerging beam is straight and still (no slide, jitter, start; a bulge only with taut)`
		end
	end
	local strike = beam.strike
	if strike ~= nil then
		if type(strike) ~= "table" or type(strike.at) ~= "number" or strike.at < 0 then
			return `{what}: strike is \{ at, seconds, bend?, aim?, wander?, trail? \}`
		end
		if type(strike.seconds) ~= "number" or strike.seconds < 0.05 or strike.seconds > 2 then
			return `{what}: strike.seconds is 0.05 to 2 (its flight into the spot)`
		end
		if strike.at + strike.seconds > beam.life then
			return `{what}: a striking beam lives until it strikes (at + seconds within its life)`
		end
		if (strike.bend ~= nil and not isTriple(strike.bend)) or (strike.aim ~= nil and not isTriple(strike.aim)) then
			return `{what}: strike.bend and strike.aim are \{ x, y, z \} studs`
		end
		if strike.wander ~= nil and (type(strike.wander) ~= "number" or strike.wander < 0 or strike.wander > 10) then
			return `{what}: strike.wander is 0 to 10 studs`
		end
		if moving then
			return `{what}: a striking beam is straight before it leaves (no slide, jitter, start or bulge)`
		end
		local band = strike.trail
		if band ~= nil then
			problem = textureProblem(band.texture, `{what} strike trail`)
			if problem then
				return problem
			end
			if type(band.width) ~= "number" or band.width <= 0 or band.width > 6 then
				return `{what} strike trail: width is over 0 up to 6 studs`
			end
			if type(band.life) ~= "number" or band.life <= 0 or band.life > 2 then
				return `{what} strike trail: life is over 0 up to 2 seconds`
			end
			if band.colors == nil and band.role == nil then
				return `{what} strike trail: colors or a role`
			end
		end
	end
	return tintProblem(beam, what)
end

function Schema.wingProblem(effect, wing, what)
	if type(wing) ~= "table" or type(wing.name) ~= "string" or wing.name == "" then
		return `{what}: a wing is a table with a name`
	end
	what = `{what} ({wing.name})`
	local problem = textureProblem(wing.texture, what)
	if problem then
		return problem
	end
	if wing.at ~= nil and not Anchors.exists(wing.at) then
		return `{what}: no anchor {tostring(wing.at)}`
	end
	if wing.root ~= nil and not isTriple(wing.root) then
		return `{what}: root is \{ x, y, z \} studs from its anchor`
	end
	local row = Budget.kindRow(effect.kind, effect.tier)
	local span = row and row.span or 5
	for _, field in { "length", "width" } do
		local value = wing[field]
		if type(value) ~= "number" or value <= 0 or value > span then
			return `{what}: {field} is over 0 up to {span} studs (a {effect.tier} {effect.kind})`
		end
	end
	for _, field in { "sweep", "raise", "lean" } do
		if wing[field] ~= nil and (type(wing[field]) ~= "number" or math.abs(wing[field]) > 90) then
			return `{what}: {field} is -90 to 90 degrees`
		end
	end
	if wing.flap ~= nil then
		problem = flapProblem(wing.flap, what)
		if problem then
			return problem
		end
	end
	if wing.hand ~= nil then
		local hand = wing.hand
		if type(hand) ~= "table" or type(hand.from) ~= "number" or type(hand.to) ~= "number" then
			return `{what}: hand is \{ texture, from, to \} (the picture cut at the wrist)`
		end
		problem = textureProblem(hand.texture, `{what} hand`)
		if problem then
			return problem
		end
		if hand.from < 0.2 or hand.to > 0.8 or hand.from >= hand.to then
			return `{what}: hand from < to, within 0.2 to 0.8 of the length (where the two pieces cross-fade)`
		end
		if hand.wrist ~= nil and (type(hand.wrist) ~= "number" or hand.wrist <= hand.from or hand.wrist >= hand.to) then
			return `{what}: hand.wrist (the joint, a share of the length) is between from and to`
		end
		if hand.pivot ~= nil and (type(hand.pivot) ~= "number" or math.abs(hand.pivot) > 0.5) then
			return `{what}: hand.pivot (-0.5 to 0.5 of the width off the middle, + toward the leading edge)`
		end
	end
	problem = partsProblem(wing, what, span)
	if problem then
		return problem
	end
	if (wing.hand ~= nil) ~= (wing.flap ~= nil and wing.flap.keys ~= nil) then
		return `{what}: a wing in two pieces (hand) beats on keyed poses (flap.keys), and keys need the two pieces`
	end
	if wing.alpha ~= nil and (wing.alpha < 0 or wing.alpha > 1) then
		return `{what}: alpha is 0 to 1`
	end
	if wing.glow ~= nil and (wing.glow < 0 or wing.glow > 5) then
		return `{what}: glow is 0 to 5`
	end
	if wing.color == nil and wing.role == nil then
		return `{what}: colors or a role`
	end
	return tintProblem(wing, what)
end

local function variantNames(effect)
	local names = {}
	for name in effect.variants or {} do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- The first thing wrong with `effect`, nil when it is sound. `variantOf` is Builder.variantOf.
-- THE FLOOR RULE (the owner, 2026-11-07: "everything starts at the height of the feet and goes up"). How far (studs at
-- refHeight) a piece's pictures reach under the ground: its anchor's height and lift, less how far under it they are
-- born, less the half of the picture that hangs down. A flat picture lies on the ground; a VelocityPerpendicular one
-- sent up is tilted by its spread; anything else stands, at its biggest (at its first size when it flies off fast).
Schema.Edge = 0.45 -- the picture's visible edge, as a share of its square
Schema.FloorSink = 0.25 -- studs under the ground a floor aura's piece may reach
function Schema.sink(effect, piece)
	local point = Anchors.Points[piece.at or "body"]
	local height = effect.refHeight * point[1] + (point[3] or 0) + (piece.lift or 0)
	if piece.radius and piece.shape == "Sphere" then
		height -= piece.radius
	elseif piece.box then
		height -= effect.refHeight * piece.box[2] / 2
	end
	local biggest, first = 0, nil
	for _, key in piece.size do
		local value = key[2] + (key[3] or 0)
		biggest = math.max(biggest, value)
		first = first or value
	end
	local hang
	if piece.flat then
		hang = 0
	elseif piece.orientation == "VelocityPerpendicular" and (piece.direction or "Top") == "Top" then
		local spread = math.max(table.unpack(piece.spread or { 0 }))
		hang = Schema.Edge * biggest * math.sin(math.rad(spread))
	else
		local flies = piece.speed ~= nil and piece.speed[1] >= 1
		hang = Schema.Edge * (if flies then first else biggest)
	end
	return hang - height
end

local function hasTag(effect, tag)
	for _, word in effect.tags do
		if word == tag then
			return true
		end
	end
	return false
end

function Schema.problem(effect, variantOf)
	if type(effect) ~= "table" then
		return "an effect is a table"
	end
	if type(effect.id) ~= "string" or not string.match(effect.id, "^[a-z]+%.[a-z0-9_]+$") then
		return "id is <kind>.<name> in lower case"
	end
	local kind = string.match(effect.id, "^([a-z]+)%.")
	if effect.kind ~= kind or not Schema.Kinds[kind] then
		return `{effect.id}: kind is the first word of the id and one of the kinds`
	end
	if type(effect.name) ~= "string" or effect.name == "" then
		return `{effect.id}: no name`
	end
	if Budget.Tiers.continuous[effect.tier] == nil then
		return `{effect.id}: tier is cheap, mid or heavy`
	end
	if not Schema.Hosts[effect.host] then
		return `{effect.id}: host is pet, character, slime, egg, weapon, world or any`
	end
	if type(effect.refHeight) ~= "number" or effect.refHeight <= 0 then
		return `{effect.id}: refHeight is the height (studs) the numbers were made for`
	end
	if type(effect.tags) ~= "table" or #effect.tags == 0 then
		return `{effect.id}: tags are words a game filters by`
	end
	if not Schema.Blends[effect.blend] then
		return `{effect.id}: blend is additive, normal or normal+bloom`
	end
	if type(effect.source) ~= "table" or type(effect.source.from) ~= "string" then
		return `{effect.id}: source.from says where it came from`
	end
	local oneShot = not Budget.Continuous[kind]
	local function check(fields, label)
		local names = {}
		if type(fields.pieces) ~= "table" then
			return `{label}: pieces is a list`
		end
		if
			#fields.pieces == 0
			and #(fields.bands or {}) == 0
			and #(fields.beams or {}) == 0
			and #(fields.wings or {}) == 0
			and #(fields.serpents or {}) == 0
			and #(fields.swimmers or {}) == 0
			and #(fields.cards or {}) == 0
			and #(fields.spirals or {}) == 0
		then
			return `{label}: nothing to draw`
		end
		local cardNames = {}
		for index, card in fields.cards or {} do
			local problem = Schema.cardProblem(fields, card, `{label} card {index}`)
			if problem then
				return problem
			end
			if cardNames[card.name] then
				return `{label}: two cards are called {card.name}`
			end
			cardNames[card.name] = true
		end
		local spiralNames = {}
		for index, spiral in fields.spirals or {} do
			local problem = Schema.spiralProblem(fields, spiral, `{label} spiral {index}`)
			if problem then
				return problem
			end
			if spiralNames[spiral.name] then
				return `{label}: two spirals are called {spiral.name}`
			end
			spiralNames[spiral.name] = true
		end
		if fields.shell ~= nil then
			-- (a glow of the host's own mesh, tried on the held weapons 2026-11-13: it hid their detail, lesson 292)
			return `{label}: no shell (it hides the host's detail)`
		end
		if fields.glaze ~= nil then
			local glaze = fields.glaze
			local function triple(value)
				return type(value) == "table" and #value == 3 and type(value[1]) == "number"
			end
			if fields.kind ~= "aura" or (fields.tier ~= "mid" and fields.tier ~= "heavy") then
				return `{label}: only a mid or heavy aura has a glaze (a Highlight: a client draws 31 at most)`
			end
			if fields.host ~= "character" and fields.host ~= "pet" and fields.host ~= "slime" then
				return `{label}: a glaze is for a body (character, pet, slime), not a weapon's detail (lesson 292)`
			end
			if not triple(glaze.fill) or (glaze.outline ~= nil and not triple(glaze.outline)) then
				return `{label}: glaze fill (and outline) are \{ r, g, b \}`
			end
			for _, field in { "fillTransparency", "outlineTransparency" } do
				local value = glaze[field]
				if value ~= nil and (type(value) ~= "number" or value < 0 or value > 1) then
					return `{label}: glaze {field} is 0 to 1`
				end
			end
		end
		if fields.dome ~= nil then
			local dome = fields.dome
			if fields.kind ~= "aura" or (fields.tier ~= "mid" and fields.tier ~= "heavy") then
				return `{label}: only a mid or heavy aura has a dome`
			end
			if type(dome.radius) ~= "number" or dome.radius < 1 or dome.radius > 10 then
				return `{label}: dome radius is 1 to 10 studs`
			end
			local color = dome.color
			if type(color) ~= "table" or #color ~= 3 or type(color[1]) ~= "number" then
				return `{label}: dome color is \{ r, g, b \}`
			end
			if dome.texture ~= nil and Textures.url(dome.texture) == "" then
				return `{label}: dome texture {dome.texture} is not a picture of Textures`
			end
			for _, field in { "transparency", "fill" } do
				local alpha = dome[field]
				if alpha ~= nil and (type(alpha) ~= "number" or alpha < 0 or alpha > 1) then
					return `{label}: dome {field} is 0 to 1`
				end
			end
		end
		for index, serpent in fields.serpents or {} do
			local problem = Schema.serpentProblem(fields, serpent, `{label} serpent {index}`)
			if problem then
				return problem
			end
		end
		for index, swimmer in fields.swimmers or {} do
			local problem = Schema.swimmerProblem(fields, swimmer, `{label} swimmer {index}`)
			if problem then
				return problem
			end
		end
		local wingNames = {}
		for index, wing in fields.wings or {} do
			if kind ~= "wings" then
				return `{label}: only a wings effect has wings`
			end
			local problem = Schema.wingProblem(fields, wing, `{label} wing {index}`)
			if problem then
				return problem
			end
			if wingNames[wing.name] then
				return `{label}: two wings are called {wing.name}`
			end
			wingNames[wing.name] = true
		end
		for index, piece in fields.pieces do
			if type(piece) == "table" and piece.wing ~= nil and not wingNames[piece.wing] then
				return `{label} piece {index}: rides no wing called {tostring(piece.wing)}`
			end
		end
		for index, piece in fields.pieces do
			-- (named too: a game reading the warning finds the piece without counting)
			local problem = Schema.pieceProblem(
				fields,
				piece,
				`{label} piece {index}{if type(piece.name) == "string" then " (" .. piece.name .. ")" else ""}`,
				oneShot
			)
			if problem then
				return problem
			end
			if names[piece.name] then
				return `{label}: two pieces are called {piece.name}`
			end
			if hasTag(effect, "floor") then
				local sink = Schema.sink(effect, piece)
				if sink > Schema.FloorSink then
					return `{label} piece {index} ({piece.name}): reaches {string.format("%.2f", sink)} studs under the ground; a floor aura starts at the feet and goes up (lift it, tilt it less, or lay it flat)`
				end
			end
			names[piece.name] = true
		end
		for index, band in fields.bands or {} do
			if kind ~= "trail" then
				return `{label}: only a trail has bands`
			end
			local problem = textureProblem(band.texture, `{label} band {index}`)
			if problem then
				return problem
			end
			if band.blade ~= nil then
				local blade = band.blade
				if
					not isPair(blade)
					or blade[2] == nil
					or math.min(blade[1], blade[2]) < -1
					or math.max(blade[1], blade[2]) > 1.5
				then
					return `{label} band {index}: blade is \{ base, tip \}, shares -1 to 1.5 of the weapon's length`
				end
				if math.abs(blade[2] - blade[1]) < 0.1 then
					return `{label} band {index}: a blade band spans at least a tenth of the weapon`
				end
				if band.axis ~= nil and band.axis ~= "X" and band.axis ~= "Y" and band.axis ~= "Z" then
					return `{label} band {index}: axis is X, Y or Z (the weapon's side its length runs along)`
				end
			elseif band.axis ~= nil then
				return `{label} band {index}: axis is a blade band's`
			elseif type(band.width) ~= "number" or band.width <= 0 or band.width > 6 then
				return `{label} band {index}: width is over 0 up to 6 studs`
			end
			if band.face ~= nil and type(band.face) ~= "boolean" then
				return `{label} band {index}: face is true or false`
			end
			if type(band.life) ~= "number" or band.life <= 0 or band.life > 2 then
				return `{label} band {index}: life is over 0 up to 2 seconds`
			end
			if band.colors == nil and band.role == nil then
				return `{label} band {index}: colors or a role`
			end
		end
		if fields.projectile then
			local projectile = fields.projectile
			local problem = nil
			if (projectile.head == nil and projectile.body == nil) or projectile.texture ~= nil then
				problem = textureProblem(projectile.texture, `{label} projectile`)
				if problem then
					return problem
				end
			end
			if type(projectile.seconds) ~= "number" or projectile.seconds < 0.05 or projectile.seconds > 4 then
				return `{label} projectile: seconds is 0.05 to 4 (its flight)`
			end
			if
				projectile.wait ~= nil
				and (type(projectile.wait) ~= "number" or projectile.wait < 0 or projectile.wait > 3)
			then
				return `{label} projectile: wait is 0 to 3 seconds before it leaves`
			end
			if projectile.ease ~= nil and projectile.ease ~= "in" then
				return `{label} projectile: ease is "in" (slow, then fast: a fall) or none`
			end
			local path = projectile.path
			if path ~= nil then
				if type(path) ~= "table" or #path < 2 or #path > 12 then
					return `{label} projectile: path is 2 to 12 points \{ f, x, y, z \}`
				end
				for index, point in path do
					if
						type(point) ~= "table"
						or #point ~= 4
						or type(point[1]) ~= "number"
						or not isTriple({ point[2], point[3], point[4] })
					then
						return `{label} projectile path point {index}: \{ f, x, y, z \} (f of the way from the caster, then studs)`
					end
				end
				if projectile.head == nil and projectile.body == nil then
					return `{label} projectile: a path flies a head or a body (a picture along the flight)`
				end
				if projectile.arc ~= nil then
					return `{label} projectile: a path has no arc (its points are its shape)`
				end
			end
			local head = projectile.head
			if head ~= nil then
				problem = textureProblem(head.texture, `{label} projectile head`)
				if problem then
					return problem
				end
				if type(head.length) ~= "number" or head.length <= 0 or head.length > 30 then
					return `{label} projectile head: length is over 0 up to 30 studs`
				end
				if type(head.width) ~= "number" or head.width <= 0 or head.width > 20 then
					return `{label} projectile head: width is over 0 up to 20 studs`
				end
				if head.colors == nil and head.color == nil and head.role == nil then
					return `{label} projectile head: colors, color or a role`
				end
			end
			local body = projectile.body
			if body ~= nil then
				if path == nil then
					return `{label} projectile body: a body follows a path (and its head)`
				end
				if body.textures ~= nil then
					if body.texture ~= nil then
						return `{label} projectile body: texture or textures (slices of one picture), not both`
					end
					if type(body.textures) ~= "table" or #body.textures < 2 or #body.textures > 8 then
						return `{label} projectile body: textures is 2 to 8 slices, neck to tail`
					end
					for index, picture in body.textures do
						problem = textureProblem(picture, `{label} projectile body slice {index}`)
						if problem then
							return problem
						end
					end
					if
						body.overlap ~= nil
						and (type(body.overlap) ~= "number" or body.overlap < 0 or body.overlap > 0.25)
					then
						return `{label} projectile body: overlap (of a slice, into each neighbour) is 0 to 0.25`
					end
				elseif body.overlap ~= nil then
					return `{label} projectile body: overlap is for textures (slices)`
				else
					problem = textureProblem(body.texture, `{label} projectile body`)
					if problem then
						return problem
					end
				end
				if type(body.length) ~= "number" or body.length <= 0 or body.length > 40 then
					return `{label} projectile body: length is over 0 up to 40 studs`
				end
				if type(body.width) ~= "number" or body.width <= 0 or body.width > 10 then
					return `{label} projectile body: width is over 0 up to 10 studs`
				end
				if body.taper ~= nil and (type(body.taper) ~= "number" or body.taper < 0 or body.taper > 1) then
					return `{label} projectile body: taper (the tail's share of the width) is 0 to 1`
				end
				if body.colors == nil and body.color == nil and body.role == nil then
					return `{label} projectile body: colors, color or a role`
				end
			end
			for index, rider in projectile.riders or {} do
				problem = Schema.pieceProblem(fields, rider, `{label} rider {index}`, true)
				if problem then
					return problem
				end
				if rider.spin ~= nil or rider.onLand ~= nil or rider.box ~= nil or rider.radius ~= nil then
					return `{label} rider {index}: a rider is born on the projectile (no box, spin or onLand)`
				end
				if names[rider.name] then
					return `{label}: two pieces are called {rider.name}`
				end
				names[rider.name] = true
			end
			local band = projectile.trail
			if band ~= nil then
				problem = textureProblem(band.texture, `{label} projectile trail`)
				if problem then
					return problem
				end
				if type(band.width) ~= "number" or band.width <= 0 or band.width > 6 then
					return `{label} projectile trail: width is over 0 up to 6 studs`
				end
				if type(band.life) ~= "number" or band.life <= 0 or band.life > 2 then
					return `{label} projectile trail: life is over 0 up to 2 seconds`
				end
				if band.colors == nil and band.role == nil then
					return `{label} projectile trail: colors or a role`
				end
			end
		end
		if fields.beams ~= nil then
			if not oneShot then
				return `{label}: only a one-shot has beams`
			end
			for index, beam in fields.beams do
				local problem = Schema.beamProblem(fields, beam, `{label} beam {index}`)
				if problem then
					return problem
				end
				for _, name in { beam.land, beam.rise } do
					local landing = nil
					for _, piece in fields.pieces do
						if piece.name == name then
							landing = piece
						end
					end
					if landing == nil or landing.onLand ~= true then
						return `{label} beam {index}: names no piece called {name} with onLand = true`
					end
				end
			end
		end
		for index, piece in fields.pieces do
			if piece.ride ~= nil then
				local ridden = nil
				for _, beam in fields.beams or {} do
					if beam.name == piece.ride then
						ridden = beam
					end
				end
				if ridden == nil or ridden.roll == nil then
					return `{label} piece {index}: rides no rolling beam called {tostring(piece.ride)}`
				end
			end
		end
		if fields.follow ~= nil and (not oneShot or type(fields.follow) ~= "boolean") then
			return `{label}: follow is true or false, on a one-shot`
		end
		if fields.follow then
			for _, piece in fields.pieces do
				if piece.spin ~= nil or piece.ride ~= nil then
					return `{label}: a following one-shot's pieces do not spin or ride (their parts are welded to the host)`
				end
			end
		end
		return nil
	end
	local problem = check(effect, effect.id)
	if problem then
		return problem
	end
	for _, name in variantNames(effect) do
		problem = check(variantOf(effect, name), `{effect.id} variant {name}`)
		if problem then
			return problem
		end
	end
	if effect.start then
		for index, piece in effect.start.pieces or {} do
			problem = Schema.pieceProblem(effect, piece, `{effect.id} start piece {index}`, true)
			if problem then
				return problem
			end
		end
	end
	if effect.defaultVariant ~= nil and (effect.variants == nil or effect.variants[effect.defaultVariant] == nil) then
		return `{effect.id}: defaultVariant names no variant`
	end
	local measured = Budget.measure(effect, variantOf)
	local fits = Budget.tierOf(kind, measured)
	if fits == nil then
		return `{effect.id}: costs more than a heavy effect may`
	end
	local order = { cheap = 1, mid = 2, heavy = 3 }
	if order[fits] > order[effect.tier] then
		return `{effect.id}: promises {effect.tier} but costs {fits}`
	end
	-- (a variant may promise less than the effect: the plain rungs of a rarity ladder are cheap, the rich ones mid)
	for _, name in variantNames(effect) do
		local own = effect.variants[name].tier
		if own ~= nil then
			if order[own] == nil then
				return `{effect.id} variant {name}: tier is cheap, mid or heavy`
			end
			if order[own] > order[effect.tier] then
				return `{effect.id} variant {name}: promises {own}, more than the effect's {effect.tier}`
			end
			local alone = table.clone(variantOf(effect, name))
			alone.variants = nil
			local costs = Budget.tierOf(kind, Budget.measure(alone, variantOf))
			if order[costs] > order[own] then
				return `{effect.id} variant {name}: promises {own} but costs {costs}`
			end
		end
	end
	return nil
end

return Schema
