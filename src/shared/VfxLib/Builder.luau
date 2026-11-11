-- THE ONE BUILDER: turns an effect of data (effects/<kind>/<id>.luau, see Schema) into Instances, and keeps them alive.
-- Merged from Egg Heist's PetVfx.attachEffect (auras), TrailBuilder (bands, orbits, a run that drives the rate),
-- MountFxBuilder (anchors, drift, flat pictures, bursts) and Goo Lineage's FightFx / HatchReveal / SlimeBuffs /
-- UpgradeReveal (one-shot marks, showers, gatherers, timelines, light flares, outlines). Code only places, scales,
-- tints, times and cleans the art; every visible thing is a picture of the data.
--
--   Builder.attach(effect, host, opts)  a lasting effect on a host (a Part, a Model, a character): its handle
--   Builder.update(handle, info)        a few times a second (Lod does it): info = { speed, mode, clock }
--   Builder.detach(handle)
--   Builder.play(effect, at, opts)      a one-shot at a Vector3 / CFrame / host: its handle; Builder.step runs it
--   Builder.step(live, dt)              advances a one-shot; false once it is over (it has cleaned itself up)
--   Builder.cancel(live, fade)          ends a one-shot softly (an interrupted attack): fades, then cleans up
--   Builder.measure(handle)             what a built effect costs now
--
-- Everything one effect makes lives in ONE folder (`VfxLib_<id>`): a lasting one on its host, a one-shot under the
-- workspace's `VfxLib` folder. A small invisible `Carrier` part, welded to the host's root, holds its attachments, its
-- box emitters and its light, so nothing collides, is queried or casts a shadow.
local Anchors = require(if script then script.Parent.Anchors else "./Anchors")
local Budget = require(if script then script.Parent.Budget else "./Budget")
local Models = require(if script then script.Parent.Models else "./Models")
local Palette = require(if script then script.Parent.Palette else "./Palette")
local Quality = require(if script then script.Parent.Quality else "./Quality")
local Textures = require(if script then script.Parent.Textures else "./Textures")

local Builder = {}

Builder.MaxScale = 8 -- a giant's effect is asked at most this many times its authored size (Budget cuts it after)
Builder.SpeedScale = 4 -- ... and its particles move at most this many times as fast (they cross a bigger body)
Builder.RunSpeed = 24 -- studs a second at which a `motion = "run"` piece comes at its full rate
Builder.MoveMin = 1.5 -- studs a second under which a runner stands still
Builder.Grain = 4 -- a rate is written in quarters of a particle a second (not every frame)
Builder.ShiftEvery = 0.1 -- seconds between two gradients of a band whose colours run
-- THE DRIFT of a piece (MountFxBuilder): shares of the host's height covered in one particle's life
Builder.DriftFall = 0.5
Builder.DriftRise = 0.35
Builder.HangDrag = 4
Builder.timeScale = 1 -- 0 freezes every particle of the library (the showroom's shots)
Builder.LegSwing = 18 -- degrees a 3D serpent's legs paddle each way as it flies
Builder.SwimDegrees = 16 -- degrees a swimming fish's tail bones each sweep, side to side (they add up toward the tip)
Builder.SwimPeriod = 1.2 -- seconds of one sweep (slowed at the owner's word, 2026-11-11)
Builder.SwimLag = 0.7 -- radians the sweep runs late in each bone toward the tail
Builder.LegPeriod = 1.6 -- seconds of one paddle

-- The engine's own reads, which Lune's fake Roblox cannot make: the tests put their own here.
Builder.engine = {
	emit = function(emitter, count)
		local ok = pcall(function()
			emitter:Emit(count)
		end)
		if not ok then
			emitter:SetAttribute("Emitted", (emitter:GetAttribute("Emitted") or 0) + count)
		end
	end,
	boundingBox = function(model)
		return model:GetBoundingBox()
	end,
	-- the camera's CFrame (nil: none, as on the server)
	camera = function()
		local camera = workspace.CurrentCamera
		return camera and camera.CFrame
	end,
	-- a MeshPart of a model's mesh (it yields; with its skin but no bones)
	meshPart = function(id)
		return game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(`rbxassetid://{id}`))
	end,
}

local function newPart(name, size, cframe, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Transparency = 1
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function weld(a, b)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = a
	constraint.Part1 = b
	constraint.Parent = b
end

local function newAttachment(parent, name, position)
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = position
	attachment.Parent = parent
	return attachment
end

-- A part inside an effect's folder (`VfxLib_<id>`) is the effect's, not the host's.
local function isEffectPart(item, host)
	local parent = item.Parent
	while parent and parent ~= host do
		if parent:IsA("Folder") and string.sub(parent.Name, 1, 7) == "VfxLib_" then
			return true
		end
		parent = parent.Parent
	end
	return false
end

-- The part a host is held by, and its box (the middle as a CFrame, the size). An effect already on the host is left
-- out of the box: a floor aura's 10-stud emitter parts once made the next effect think the host twice as tall, and put
-- it 4 studs under the ground (seen 2026-11-07: the showroom's last shot left on its pedestal).
function Builder.boxOf(host)
	if host:IsA("BasePart") then
		return host.CFrame, host.Size, host
	end
	if host:IsA("Attachment") then
		local parent = host.Parent
		return host.WorldCFrame, Vector3.one, if parent and parent:IsA("BasePart") then parent else nil
	end
	local root = host:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		root = if host:IsA("Model") then host.PrimaryPart else nil
	end
	local parts, effects = {}, false
	for _, item in host:GetDescendants() do
		if item:IsA("BasePart") then
			if isEffectPart(item, host) then
				effects = true
			else
				table.insert(parts, item)
			end
		end
	end
	root = root or parts[1]
	if not root then
		return nil, nil, nil
	end
	if not effects then
		local ok, cframe, size = pcall(Builder.engine.boundingBox, host)
		if ok and cframe then
			return cframe, size, root
		end
	end
	-- (with an effect on it, or in Lune: the box round the host's own parts, turned as the root)
	local rotation = root.CFrame - root.CFrame.Position
	local back = rotation:Inverse()
	local low, high = nil, nil
	for _, part in parts do
		local frame = back * part.CFrame
		local half = part.Size / 2
		for _, corner in
			{
				Vector3.new(-1, -1, -1),
				Vector3.new(-1, -1, 1),
				Vector3.new(-1, 1, -1),
				Vector3.new(-1, 1, 1),
				Vector3.new(1, -1, -1),
				Vector3.new(1, -1, 1),
				Vector3.new(1, 1, -1),
				Vector3.new(1, 1, 1),
			}
		do
			local point = frame * (half * corner)
			low = if low then low:Min(point) else point
			high = if high then high:Max(point) else point
		end
	end
	return rotation * CFrame.new((low + high) / 2), high - low, root
end

-- An effect with a variant laid over it: the variant's fields replace the effect's, its `extra` pieces are added and its
-- `drop` names are taken out; `scale` multiplies the sizes. nil `name`: the effect's `defaultVariant`, else itself.
function Builder.variantOf(effect, name)
	name = name or effect.defaultVariant
	local variant = name and effect.variants and effect.variants[name]
	if not variant then
		return effect
	end
	local merged = table.clone(effect)
	merged.variant = name
	for key, value in variant do
		if key ~= "extra" and key ~= "drop" then
			merged[key] = value
		end
	end
	local pieces = {}
	local dropped = {}
	for _, pieceName in variant.drop or {} do
		dropped[pieceName] = true
	end
	for _, piece in merged.pieces or {} do
		if not dropped[piece.name] then
			table.insert(pieces, piece)
		end
	end
	for _, piece in variant.extra or {} do
		table.insert(pieces, piece)
	end
	merged.pieces = pieces
	return merged
end

-- Keypoints { { t, v, e? } } times k, as a NumberSequence.
local function numbers(points, k)
	local keys = {}
	for index, point in points do
		local value = point[2] * (k or 1)
		local envelope = math.min((point[3] or 0) * (k or 1), math.abs(value))
		keys[index] = NumberSequenceKeypoint.new(point[1], value, envelope)
	end
	return NumberSequence.new(keys)
end

-- The transparency of a piece with a grade's `alpha`: the most solid it gets is moved to `alpha`, the rest in step.
local function graded(points, alpha)
	if alpha == nil then
		return points
	end
	local low = 1
	for _, point in points do
		low = math.min(low, point[2])
	end
	if low >= 1 then
		return points
	end
	local out = {}
	for index, point in points do
		local value = alpha + (point[2] - low) * (1 - alpha) / (1 - low)
		out[index] = { point[1], math.clamp(value, 0, 1), point[3] }
	end
	return out
end

local function range(pair, k)
	k = k or 1
	local a, b = pair[1] * k, (pair[2] or pair[1]) * k
	return NumberRange.new(math.min(a, b), math.max(a, b))
end

local function vector(triple, k)
	k = k or 1
	return Vector3.new(triple[1] * k, triple[2] * k, triple[3] * k)
end

-- The numbers of one piece once scaled to its host: what Budget holds and the emitter is made from.
local function specOf(piece, scale, grade)
	local sizeK = scale * (grade and grade.size or 1)
	local spec = {
		piece = piece,
		size = {},
		life = { piece.life[1], piece.life[2] or piece.life[1] },
	}
	for index, point in piece.size do
		spec.size[index] = { point[1], point[2] * sizeK, (point[3] or 0) * sizeK }
	end
	if piece.rate then
		spec.rate = piece.rate * (if piece.steady then 1 else (grade and grade.rate or 1))
	end
	local count = piece.count or 0
	if piece.bursts then
		spec.bursts = {}
		for index, shot in piece.bursts do
			spec.bursts[index] = { shot[1], shot[2] * (grade and grade.count or 1) }
			count += shot[2]
		end
	end
	if piece.count or piece.bursts then
		spec.count = count * (grade and grade.count or 1)
		if piece.count then
			spec.bursts = spec.bursts or {}
			table.insert(spec.bursts, 1, { piece.delay or 0, piece.count * (grade and grade.count or 1) })
		end
	end
	return spec
end

-- Makes the emitter of a piece.
--   ctx = { effect, palette (the game's), height (studs, of the host), move (speed factor), angle (degrees, a blow's
--           direction on screen), grade, continuous }
local function makeEmitter(piece, spec, ctx)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = piece.name or "Piece"
	emitter.Texture = Textures.url(piece.texture)
	emitter.Rate = 0
	emitter.Enabled = ctx.continuous == true
	emitter.Size = numbers(spec.size)
	emitter.Transparency = numbers(graded(piece.transparency or { { 0, 0 }, { 1, 1 } }, ctx.grade and ctx.grade.alpha))
	local colors = Palette.sequence(Palette.resolve(ctx.effect, piece, ctx.palette))
	emitter.Color = colors or ColorSequence.new(Color3.new(1, 1, 1))
	emitter.Lifetime = range(spec.life)
	local move = ctx.move
	emitter.Speed = range(piece.speed or { 0, 0 }, move)
	local spread = piece.spread or { 0, 0 }
	emitter.SpreadAngle = Vector2.new(spread[1], spread[2] or spread[1])
	emitter.Acceleration = vector(piece.accel or { 0, 0, 0 }, move)
	emitter.Drag = piece.drag or 0
	local rotation = piece.rotation or { 0, 0 }
	if piece.aim ~= nil then
		-- (a mark that lies across a blow: the blow's angle on screen, turned by `aim`)
		local angle = (ctx.angle or 0) + piece.aim
		rotation = { angle, angle }
	end
	emitter.Rotation = range(rotation)
	emitter.RotSpeed = range(piece.rotSpeed or { 0, 0 })
	emitter.LightInfluence = piece.lightInfluence or 0
	emitter.Brightness = piece.brightness or 1
	emitter.LightEmission = piece.lightEmission or 0
	emitter.ZOffset = piece.zOffset or 0
	emitter.LockedToPart = if piece.locked ~= nil then piece.locked else ctx.continuous == true
	emitter.VelocityInheritance = piece.inherit or 0
	emitter.TimeScale = Builder.timeScale
	if piece.orientation then
		emitter.Orientation = Enum.ParticleOrientation[piece.orientation]
	end
	if piece.direction then
		emitter.EmissionDirection = Enum.NormalId[piece.direction]
	end
	if piece.shape then
		emitter.Shape = Enum.ParticleEmitterShape[piece.shape]
	end
	if piece.shapeStyle then
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle[piece.shapeStyle]
	end
	if piece.shapeInOut then
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut[piece.shapeInOut]
	end
	if piece.shapePartial then
		emitter.ShapePartial = piece.shapePartial
	end
	if piece.squash then
		emitter.Squash = numbers(piece.squash)
	end
	if piece.windDrag ~= nil then
		pcall(function()
			emitter.WindAffectsDrag = piece.windDrag
		end)
	end
	local flipbook = piece.flipbook
	if flipbook then
		emitter.FlipbookLayout = Enum.ParticleFlipbookLayout[flipbook.layout]
		emitter.FlipbookMode = Enum.ParticleFlipbookMode[flipbook.mode or "Loop"]
		if flipbook.fps then
			emitter.FlipbookFramerate = range(flipbook.fps)
		end
		emitter.FlipbookStartRandom = flipbook.random == true
	end
	if piece.flat then
		-- a picture that lies on the ground (a ring, a sigil): it faces up, sent up so slowly it stays where it is
		emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.SpreadAngle = Vector2.new(0, 0)
		if (piece.speed or { 0 })[1] <= 0 then
			emitter.Speed = NumberRange.new(0.01)
		end
	elseif piece.upright then
		-- a picture standing still in the caster's frame, facing the spot (a portal's face): sent toward the spot so
		-- slowly it stays where it is (its attachment is turned as the caster's frame)
		emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		emitter.EmissionDirection = Enum.NormalId.Front
		emitter.SpreadAngle = Vector2.new(0, 0)
		if (piece.speed or { 0 })[1] <= 0 then
			emitter.Speed = NumberRange.new(0.01)
		end
	end
	-- THE DRIFT: an acceleration sized to the host's height (the height covered in one life), or a drag that stops them
	local drift = piece.drift
	if drift then
		local span = math.max(Budget.meanLife(spec), 0.1)
		local height = ctx.height
		if drift == "fall" then
			emitter.Acceleration = Vector3.new(0, -2 * Builder.DriftFall * height / (span * span), 0)
		elseif drift == "rise" then
			emitter.Acceleration = Vector3.new(0, 2 * Builder.DriftRise * height / (span * span), 0)
		elseif drift == "hang" then
			emitter.Acceleration = Vector3.new(0, 0, 0)
			emitter.Drag = math.max(emitter.Drag, Builder.HangDrag)
		end
	end
	-- THE BLACK-BACKED RULE: a picture drawn on black is always added (LightEmission 1) and dimmed by its brightness, the
	-- least it keeps a sixth of its light; anything less and its black shows as a square round every particle
	if Textures.isBlack(piece.texture) and emitter.LightEmission < 1 then
		local value = emitter.LightEmission
		emitter.LightEmission = 1
		emitter.Brightness = emitter.Brightness * math.max(value, 0.15)
	end
	return emitter
end

-- The parent of a piece's emitter on a lasting effect: a box part (born anywhere in it), a sphere part, an orbiting or
-- fixed attachment.
local function parentFor(handle, piece)
	local size = handle.size
	local scale = handle.scale
	if piece.box or piece.radius then
		local share = piece.box
		local partSize
		if piece.radius then
			local across = piece.radius * 2 * scale
			partSize = Vector3.new(across, across, across)
		else
			partSize = Vector3.new(size.X * share[1], size.Y * share[2], size.Z * share[3])
		end
		local offset = Anchors.offset(piece.at or "body", size, handle.behind)
			+ Vector3.new(0, (piece.lift or 0) * scale, 0)
		local frame = CFrame.new()
		local pose = piece.pose
		if pose then
			-- (a wing: where its picture is held and how it is turned, as its pack placed it)
			local at, turn = pose.at or { 0, 0, 0 }, pose.turn or { 0, 0, 0 }
			offset += Vector3.new(at[1], at[2], at[3]) * scale
			frame = CFrame.Angles(math.rad(turn[1]), math.rad(turn[2]), math.rad(turn[3]))
		end
		local key =
			`{piece.at}|{partSize.X}|{partSize.Y}|{partSize.Z}|{piece.lift or 0}|{if pose then piece.name else ""}`
		local part = handle.parts[key]
		if not part then
			local flapping = pose ~= nil and piece.flap ~= nil
			part = newPart("Box", partSize, handle.carrier.CFrame * CFrame.new(offset) * frame, handle.folder)
			local joint = nil
			if handle.carrier.Anchored then
				part.Anchored = true
			elseif flapping then
				-- (a Weld, not a WeldConstraint: its C0 turns the wing without moving the host)
				joint = Instance.new("Weld")
				joint.Part0 = handle.carrier
				joint.Part1 = part
				joint.C0 = CFrame.new(offset) * frame
				joint.Parent = part
			else
				weld(handle.carrier, part)
			end
			handle.parts[key] = part
			if flapping then
				-- (a wing beats about a hinge on the spine, at its own height and depth; the left one mirrors the right)
				local hinge = CFrame.new(0, offset.Y, offset.Z)
				table.insert(handle.flaps, {
					part = part,
					joint = joint,
					flap = piece.flap,
					hinge = hinge,
					rest = hinge:Inverse() * CFrame.new(offset) * frame,
					side = if (pose.at or { 0 })[1] < 0 then -1 else 1,
				})
			end
		end
		return part
	end
	if piece.orbit then
		local orbit = piece.orbit
		local y = -size.Y / 2 + orbit.y * scale
		local attachment = newAttachment(handle.carrier, "Orbit", Vector3.new(orbit.radius * scale, y, 0))
		table.insert(
			handle.orbits,
			{ attachment = attachment, orbit = orbit, y = y, radius = orbit.radius * scale, scale = scale }
		)
		return attachment
	end
	local at = piece.at or "body"
	local lift = piece.lift or 0
	local key = if lift == 0 then at else `{at}+{lift}`
	local attachment = handle.anchors[key]
	if not attachment then
		local offset = Anchors.offset(at, size, handle.behind) + Vector3.new(0, lift * handle.scale, 0)
		attachment = newAttachment(handle.carrier, "At_" .. key, offset)
		handle.anchors[key] = attachment
	end
	return attachment
end

local function colorOf(effect, spec, given)
	local resolved = spec.color or (spec.role and Palette.resolve(effect, { role = spec.role }, given))
	return Palette.first(resolved or { 255, 255, 255 })
end

-- A band of a trail: a `Trail` between two attachments behind the runner (TrailBuilder.bandTrail), or, with `blade`,
-- along a weapon from its base to its tip: a swing leaves the ribbon, a blade held still leaves none.
local function makeBand(handle, band, index)
	local scale = handle.scale
	local size = handle.size
	local b = handle.budget
	local a0, a1
	if band.blade then
		-- (the blade is the host's longest side; shares of it from its negative end)
		local axis = if size.Y >= size.X and size.Y >= size.Z
			then Vector3.new(0, 1, 0)
			elseif size.X >= size.Z then Vector3.new(1, 0, 0)
			else Vector3.new(0, 0, 1)
		local length = math.max(size.X, size.Y, size.Z)
		a0 = newAttachment(handle.carrier, `Band{index}Tip`, axis * length * (band.blade[2] - 0.5))
		a1 = newAttachment(handle.carrier, `Band{index}Base`, axis * length * (band.blade[1] - 0.5))
	else
		local width = band.width * scale
		local half = width / 2
		local feet = -size.Y / 2
		local middle = feet + (if band.y then band.y * scale else half + 0.2)
		local back = size.Z / 2 + Anchors.Behind
		a0 = newAttachment(handle.carrier, `Band{index}Top`, Vector3.new(0, middle + half, back))
		a1 = newAttachment(handle.carrier, `Band{index}Bottom`, Vector3.new(0, middle - half, back))
	end
	local trail = Instance.new("Trail")
	trail.Name = `Band{index}`
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = math.min(band.life, b.bandLife or band.life)
	trail.MinLength = if band.blade then 0.3 else 0.1 -- (a blade's idle sway leaves no ribbon)
	trail.MaxLength = b.bandLength or 70
	trail.FaceCamera = band.face ~= false
	trail.LightInfluence = 0
	local colors = band.colors or Palette.resolve(handle.effect, band, handle.opts.palette)
	trail.Color = Palette.sequence(colors) or ColorSequence.new(Color3.new(1, 1, 1))
	trail.Texture = Textures.url(band.texture)
	if band.length then
		trail.TextureMode = Enum.TextureMode.Wrap
		trail.TextureLength = band.length
	else
		trail.TextureMode = Enum.TextureMode.Stretch
	end
	local glow = band.glow or 0
	if Textures.isBlack(band.texture) then
		-- (drawn on black: stays additive, its glow is its brightness instead)
		trail.LightEmission = 1
		trail.Brightness = 0.35 + 0.65 * glow
	else
		trail.LightEmission = glow
	end
	local alpha = band.alpha or 0.1
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, alpha),
		NumberSequenceKeypoint.new(0.5, alpha + (1 - alpha) * 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new(1, band.taper or 0.3)
	trail.Parent = handle.folder
	return { trail = trail, band = band, colors = colors }
end

-- THE WINGS. A wing is a picture drawn as ONE right wing seen from behind (its root at the middle of its left edge; the
-- file is stored transposed, tools/chatgpt/prepare_wing.py) on a flat Beam from its root to its tip; the left one is the
-- same beam mirrored. The beat turns the beam's attachments about the spine, and the picture turns with them: a posed
-- particle cannot do that, its picture keeps its top to the world's up and only slides (seen 2026-11-07,
-- showroom/lab/wing_pose.luau and beam_wing.luau).
Builder.WingHalfEvery = 3 -- a wing at "half" detail beats on one update in this many (about 20 Hz instead of 60)

-- Where a wing's root is and how it is turned, on its side (1 right, -1 left), `beat` (-1..1) into its flap.
local function wingFrame(entry, beat)
	local wing, side, scale = entry.wing, entry.side, entry.scale
	local root = wing.root or { 0, 0, 0 }
	local sweep, raise = wing.sweep or 0, wing.raise or 0
	local flap = wing.flap
	if flap then
		if flap.fold then
			sweep += flap.angle * beat -- (a butterfly's: the wings swing back about the spine and open again)
		else
			raise += flap.angle * beat -- (a bird's: the tips beat up and down)
		end
	end
	return CFrame.new(entry.offset + Vector3.new(side * root[1], root[2], root[3]) * scale)
		* CFrame.Angles(math.rad(wing.lean or 0), 0, 0)
		* CFrame.Angles(0, math.rad(-side * sweep), 0)
		* CFrame.Angles(0, 0, math.rad(side * raise))
end

-- A BIRD'S wing (flap.bird) is rigged: a chain of three bones (upper arm, forearm, hand), each turned at its joint
-- every beat, and the picture laid on the chain by ONE curved Beam whose control points ride the upper arm and the hand,
-- so it bends and twists with the bones as a skinned wing would (a flat beam's width follows each end's Y and twists
-- between them: seen 2026-11-07, showroom/lab/bird_wing.luau). In the right wing's frame (+x out along the wing, +y its
-- leading edge, +z back): each joint swings the wing back and forth through its own plane (the stroke) and lifts it,
-- the elbow and the wrist a little LATER than the shoulder, so the wave runs out to the tip and the tip trails; on the
-- up stroke the hand folds down and back and its feathers close (the hand's width), on the down stroke it opens again;
-- the chord twists with the stroke. Slow and smooth: one sine, its harmonics delayed, no corners. `flap.soft` (1 by
-- default) scales what the elbow and the wrist add: under 1 a stiff wing (ice, gems), over 1 a supple one (a bat's).
local BIRD = {
	bones = { 0.3, 0.3, 0.4 }, -- shares of the length: upper arm, forearm, hand
	lag = 0.6, -- radians each joint runs behind the one before it
	stroke = { 1.8, 2.2, 2.6 }, -- times flap.angle: the swing back and forth at the shoulder, elbow, wrist
	lift = { 0.8, 1.0, 1.2 }, -- times flap.angle: the lift at each joint
	fold = { 0.8, -3, 2 }, -- times flap.angle on the up stroke: the elbow up, the hand down, the hand back
	twist = { 0.5, 0.9 }, -- times flap.angle: the chord's twist at the shoulder and the wrist
	close = 0.35, -- the hand's width lost when folded (its feathers closing)
}

-- How a bird's wing beats (flap.style). Real birds (Rosén et al., J Exp Biol 2004/2007) spend more of the beat on the
-- down stroke than on the up stroke and fold the wing on the way up (the upstroke span 60-90% of the downstroke's); an
-- animator's flap hangs at the top and snaps through the bottom, the tips trailing and overshooting. `down`: the share
-- of the beat spent on the down stroke; `hang`: how much slower the top of the stroke is than the bottom (0..0.6);
-- `fold`, `lag`, `size`, `rate`: times the base fold, joint lag, angle and beats per second; `glide`: so many beats,
-- then so many beats of a held glide (the wings spread, barely moving), again and again.
local STYLES = {
	beat = { down = 0.5, hang = 0, fold = 1, lag = 1, size = 1, rate = 1 }, -- one even sine (the first rig)
	power = { down = 0.42, hang = 0.5, fold = 1.3, lag = 1.35, size = 1.15, rate = 1 }, -- hangs up high, snaps down
	natural = { down = 0.6, hang = 0.15, fold = 1.9, lag = 1.15, size = 1, rate = 1 }, -- a long down stroke, a tucked up stroke
	glide = { down = 0.6, hang = 0.15, fold = 1.9, lag = 1.15, size = 1.1, rate = 1.1, glide = { 2, 1.6 } },
	soar = { down = 0.5, hang = 0.1, fold = 0.35, lag = 1.7, size = 0.45, rate = 0.6 }, -- spread, breathing, tips rippling
}
Builder.WingStyles = STYLES

local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- `beats` (beats since the start) into the angle of a bird's beat and how big it is now (1, less in a glide): the time
-- of the beat is warped, u = (theta + c(1 - cos theta) + h sin theta) / 2pi, so the down stroke (theta 0..pi) takes
-- `down` of it and the top of the stroke is `hang` slower; smooth, no corners (|c| + |h| < 1 keeps it one-way).
local function birdBeat(style, beats)
	local f = beats % 1
	local c, h = math.pi * (style.down - 0.5), style.hang
	local theta = 2 * math.pi * f
	for _ = 1, 6 do
		local g = theta + c * (1 - math.cos(theta)) + h * math.sin(theta) - 2 * math.pi * f
		theta -= g / (1 + c * math.sin(theta) + h * math.cos(theta))
	end
	local size = style.size
	if style.glide then
		-- (the last up stroke dies down into the glide; the glide's last half beat swells into the next down stroke)
		local flaps, rest = style.glide[1], style.glide[2]
		local s = beats % (flaps + rest)
		local quiet = smooth((s - (flaps - 0.5)) * 2) * (1 - smooth((s - (flaps + rest - 0.5)) * 2))
		size *= 1 - 0.85 * quiet
	end
	return theta, size
end

local function bezier(p0, p1, p2, p3, t)
	local u = 1 - t
	return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)
end

-- The bones' frames at `theta` (radians into the beat), in the right wing's frame from its anchor: shoulder, wrist,
-- tip, and how folded the hand is (0..1).
local function birdChain(entry, theta, size)
	local wing, scale = entry.wing, entry.scale
	local style = STYLES[wing.flap.style or "beat"]
	local a = wing.flap.angle * (size or style.size)
	local length = wing.length * scale
	local root = wing.root or { 0, 0, 0 }
	local soft = wing.flap.soft or 1
	local fold = (1 - math.sin(theta)) / 2
	fold *= fold * soft * style.fold -- (0 through the down stroke, the most in the middle of the up stroke)
	local swing, lift = {}, {}
	for k = 1, 3 do
		local wave = math.cos(theta - (k - 1) * BIRD.lag * style.lag) -- (1 at the top of the stroke: back and up)
		swing[k] = BIRD.stroke[k] * a * wave
		lift[k] = BIRD.lift[k] * a * wave
	end
	local twist = math.sin(theta)
	local function turn(back, up, pitch)
		return CFrame.Angles(0, math.rad(-back), 0)
			* CFrame.Angles(0, 0, math.rad(up))
			* CFrame.Angles(math.rad(pitch), 0, 0)
	end
	local shoulder = CFrame.new(Vector3.new(root[1], root[2], root[3]) * scale)
		* CFrame.Angles(math.rad(wing.lean or 0), 0, 0)
		* turn((wing.sweep or 0) + swing[1], (wing.raise or 0) + lift[1], BIRD.twist[1] * a * twist)
	local elbow = shoulder
		* CFrame.new(BIRD.bones[1] * length, 0, 0)
		* turn((swing[2] - swing[1]) * soft, (lift[2] - lift[1]) * soft + BIRD.fold[1] * a * fold, 0)
	local wrist = elbow
		* CFrame.new(BIRD.bones[2] * length, 0, 0)
		* turn(
			(swing[3] - swing[2]) * soft + BIRD.fold[3] * a * fold,
			(lift[3] - lift[2]) * soft + BIRD.fold[2] * a * fold,
			BIRD.twist[2] * a * twist * soft
		)
	local tip = wrist * CFrame.new(BIRD.bones[3] * length, 0, 0)
	return shoulder, wrist, tip, fold
end

-- `frame` (in the right wing's frame from the anchor) on `side`: the left one is its mirror across the spine.
local function sided(entry, frame)
	if entry.side > 0 then
		return entry.offset + frame.Position, frame
	end
	local function flip(v)
		return Vector3.new(-v.X, v.Y, v.Z)
	end
	local position = entry.offset + flip(frame.Position)
	return position, CFrame.fromMatrix(position, flip(frame.XVector), flip(frame.YVector))
end

-- A wing's CURVE at a moment, in the carrier's frame: the bezier p0..p3 its beam is drawn on, the frames at its root,
-- wrist and tip (f0, fw, f3: x out along the wing for a bird's, its leading edge y), its width at the root and the tip.
-- A wing that does not bend (`plain`) is one straight frame.
local function birdCurve(entry, theta, size)
	local shoulder, wrist, tip, fold = birdChain(entry, theta, size)
	local length = entry.wing.length * entry.scale
	local width = entry.wing.width * entry.scale
	local p0, f0 = sided(entry, shoulder)
	local p3, f3 = sided(entry, tip)
	local _, fw = sided(entry, wrist)
	-- (the control points: along the upper arm from the shoulder, back along the hand from the tip; a beam puts its
	-- second one at Attachment1 MINUS its axis times CurveSize1, seen 2026-11-07)
	local reach0, reach1 = BIRD.bones[1] * 1.1 * length, BIRD.bones[3] * 0.85 * length
	return {
		p0 = p0,
		p1 = p0 + f0.XVector * reach0,
		p2 = p3 - f3.XVector * reach1,
		p3 = p3,
		f0 = f0,
		fw = fw,
		f3 = f3,
		w0 = width,
		w1 = width * (1 - BIRD.close * fold),
		reach0 = reach0,
		reach1 = reach1,
	}
end

-- A KEYED wing (flap.keys) is a cut-out puppet: its picture cut at the wrist into two (wing.hand, split_wing.py), the
-- arm on one curved beam from the shoulder past the wrist, the hand on another from before the wrist to the tip, the
-- two cross-fading where they overlap, so the hand folds at a real joint instead of the whole picture bending as one.
-- Its bones (upper arm and forearm half the way to the wrist each, then the hand; the wrist at hand.wrist of the
-- length, turning about a joint hand.pivot of the width off the middle line: where the picture's wrist is) are posed
-- KEY BY KEY as an animator would, each key a moment of a real wingbeat, and run through smoothly (a Hermite curve
-- through the keys, each channel on its own). Each key, in the right wing's frame (x out, y up the picture, z back),
-- degrees added to the wing's own raise and sweep: the shoulder's raise (sr), sweep back (ss) and twist (st); the
-- elbow's raise (er) and sweep back (es); the wrist's raise (wr) and sweep back (ws); `open`: the hand's width at its
-- tip, a share of the wing's (feathers or fingers spread, 1, or drawn together). The angles are written for
-- flap.angle 20 and scale with it.
local WING_KEYS = {
	-- A dove's beat (frames of flying pigeons and doves; Rosen et al. 2004, 2007): the down stroke is longer and the
	-- wing fully spread, swept forward and pronated, the tips trailing up and then overshooting down; on the up stroke
	-- the elbow lifts and the wrist folds the hand down and back (the wing an M, its span much shorter), unfolding late
	-- and flicking open at the top, where the wings meet high over the back.
	dove = {
		{ t = 0.00, sr = 42, ss = 6, st = 0, er = 4, es = 0, wr = 14, ws = 0, open = 1 }, -- the top: raised high
		{ t = 0.12, sr = 30, ss = -6, st = -8, er = -2, es = -4, wr = 18, ws = -4, open = 1 }, -- down: tips trail up
		{ t = 0.30, sr = 4, ss = -14, st = -12, er = -4, es = -6, wr = 10, ws = -6, open = 1 }, -- level, swept forward
		{ t = 0.46, sr = -20, ss = -10, st = -6, er = -4, es = -2, wr = -4, ws = -2, open = 1 }, -- the bottom
		{ t = 0.56, sr = -18, ss = 2, st = 4, er = 12, es = 10, wr = -30, ws = 20, open = 0.86 }, -- up: the hand drops
		{ t = 0.70, sr = 4, ss = 12, st = 8, er = 18, es = 16, wr = -48, ws = 38, open = 0.75 }, -- tucked, an M
		{ t = 0.84, sr = 28, ss = 12, st = 4, er = 10, es = 8, wr = -20, ws = 18, open = 0.89 }, -- unfolding
		{ t = 0.94, sr = 40, ss = 9, st = 0, er = 6, es = 2, wr = 8, ws = 2, open = 1 }, -- the flick open
	},
	-- A bat's wing as the owner sees it (2026-11-07): long stiff bones, so two STRAIGHT pieces (the root to the wrist,
	-- the wrist to the tip, no bending: the elbow never turns, each piece one flat quad) meeting at an angle, the hand
	-- turning only a little about the wrist; it sweeps mostly FORWARD AND BACK, turning a little with the sweep, its
	-- tip tracing a flat loop (a little higher going back). A first try after bat flight films (a deep down stroke,
	-- the hand folded in an M on the way up, the skin going slack) read as a bird's supple wing, not a bat's.
	-- (more forward than the wing's sweep less 24, its root ran into the back and the body hid it: a wing beating so
	-- takes sweep 22 or so)
	bat = {
		{ t = 0.00, sr = 2, ss = -24, st = -8, er = 0, es = 0, wr = -4, ws = -6, open = 1 }, -- swept forward
		{ t = 0.25, sr = 10, ss = 2, st = 0, er = 0, es = 0, wr = -8, ws = 2, open = 1 }, -- going back, rising
		{ t = 0.50, sr = 6, ss = 26, st = 8, er = 0, es = 0, wr = -12, ws = 8, open = 0.92 }, -- swept back
		{ t = 0.75, sr = -4, ss = 2, st = 0, er = 0, es = 0, wr = -8, ws = 0, open = 0.96 }, -- coming forward, lower
	},
}
Builder.WingKeys = WING_KEYS
local KEY_CHANNELS = { "sr", "ss", "st", "er", "es", "wr", "ws", "open" }

-- The pose at `f` (0..1 into the beat): every channel through the keys on a looping Hermite curve (Catmull-Rom slopes
-- over the keys' own spacing, so it is smooth at every key however unevenly they are spaced).
local function keyedPose(keys, f)
	local n = #keys
	local i = n
	for k = 1, n do
		if keys[k].t <= f then
			i = k
		end
	end
	local function at(k)
		local wrap = math.floor((k - 1) / n)
		local key = keys[(k - 1) % n + 1]
		return key, key.t + wrap
	end
	local k0, t0 = at(i - 1)
	local k1, t1 = at(i)
	local k2, t2 = at(i + 1)
	local k3, t3 = at(i + 2)
	if f < t1 then
		f += 1
	end
	local span = t2 - t1
	local u = (f - t1) / span
	local u2, u3 = u * u, u * u * u
	local h00, h10, h01, h11 = 2 * u3 - 3 * u2 + 1, u3 - 2 * u2 + u, -2 * u3 + 3 * u2, u3 - u2
	local pose = {}
	for _, c in KEY_CHANNELS do
		local m1 = (k2[c] - k0[c]) / (t2 - t0) * span
		local m2 = (k3[c] - k1[c]) / (t3 - t1) * span
		pose[c] = h00 * k1[c] + h10 * m1 + h01 * k2[c] + h11 * m2
	end
	return pose
end

-- Where along a keyed wing its wrist is (a share of the length).
local function keyedWrist(wing)
	return wing.hand.wrist or (wing.hand.from + wing.hand.to) / 2
end

-- A keyed wing's bones at `clock` (nil: at rest, KEYED_REST into the beat: level and spread): shoulder, elbow, wrist,
-- tip frames in the right wing's frame from its anchor, and the pose.
local KEYED_REST = 0.3
local function keyedChain(entry, clock)
	local wing, scale = entry.wing, entry.scale
	local flap = wing.flap
	local keys = WING_KEYS[flap.keys]
	local f = if clock then (clock / flap.period + (flap.phase or 0)) % 1 else KEYED_REST
	local pose = keyedPose(keys, f)
	local k = flap.angle / 20
	local length = wing.length * scale
	local root = wing.root or { 0, 0, 0 }
	local wristAt = keyedWrist(wing)
	local pivot = CFrame.new(0, (wing.hand.pivot or 0) * wing.width * scale, 0)
	local function turn(back, up, pitch)
		return CFrame.Angles(0, math.rad(-back), 0)
			* CFrame.Angles(0, 0, math.rad(up))
			* CFrame.Angles(math.rad(pitch), 0, 0)
	end
	local shoulder = CFrame.new(Vector3.new(root[1], root[2], root[3]) * scale)
		* CFrame.Angles(math.rad(wing.lean or 0), 0, 0)
		* turn((wing.sweep or 0) + pose.ss * k, (wing.raise or 0) + pose.sr * k, pose.st * k)
	local elbow = shoulder * CFrame.new(wristAt / 2 * length, 0, 0) * turn(pose.es * k, pose.er * k, 0)
	-- (the hand turns about its joint, off the middle line where the picture's wrist is)
	local wrist = elbow
		* CFrame.new(wristAt / 2 * length, 0, 0)
		* pivot
		* turn(pose.ws * k, pose.wr * k, 0)
		* pivot:Inverse()
	local tip = wrist * CFrame.new((1 - wristAt) * length, 0, 0)
	return shoulder, elbow, wrist, tip, pose
end

-- A keyed wing at `clock`: the curve of the whole wing (for what rides it) and the two pieces' ends.
local function keyedCurve(entry, clock)
	local shoulder, elbow, wrist, tip, pose = keyedChain(entry, clock)
	local wing = entry.wing
	local length = wing.length * entry.scale
	local width = wing.width * entry.scale
	local wristAt = keyedWrist(wing)
	-- (a joint on the middle line: the arm runs on past the wrist along the hand to `to` and the hand starts before it
	-- along the forearm, at `from`, so the two bend into each other; a joint off the middle line (pivot: a bat's wrist
	-- at the leading edge, its fingers fanning from it) turns the hand like a fan, the arm stays straight on the forearm
	-- and the hand's piece turns whole: bent into each other there, the arm's end was dragged back to its root)
	local armEnd, handStart
	if wing.hand.pivot then
		armEnd = elbow * CFrame.new((wing.hand.to - wristAt / 2) * length, 0, 0)
		handStart = wrist * CFrame.new((wing.hand.from - wristAt) * length, 0, 0)
	else
		armEnd = wrist * CFrame.new((wing.hand.to - wristAt) * length, 0, 0)
		handStart = elbow * CFrame.new((wing.hand.from - wristAt / 2) * length, 0, 0)
	end
	local close = math.clamp(pose.open, 0.1, 1)
	local p0, f0 = sided(entry, shoulder)
	local p3, f3 = sided(entry, tip)
	local _, fw = sided(entry, wrist)
	local a1, fa = sided(entry, armEnd)
	local h0, fh = sided(entry, handStart)
	local reach0, reach1 = wristAt / 2 * 1.1 * length, (1 - wristAt) * 0.85 * length
	-- (each piece's control points a third of its chord in, so its picture runs evenly along it and the two pictures
	-- lie on each other where they overlap)
	local armReach, handReach = (a1 - p0).Magnitude / 3, (p3 - h0).Magnitude / 3
	return {
		p0 = p0,
		p1 = p0 + f0.XVector * reach0,
		p2 = p3 - f3.XVector * reach1,
		p3 = p3,
		f0 = f0,
		fw = fw,
		f3 = f3,
		w0 = width,
		w1 = width * close,
		reach0 = reach0,
		reach1 = reach1,
		arm = { p0 = p0, f0 = f0, p1 = a1, f1 = fa, c0 = armReach, c1 = armReach, w1 = width },
		hand = { p0 = h0, f0 = fh, p1 = p3, f1 = f3, c0 = handReach, c1 = handReach, w1 = width * close },
	}
end

-- A MECHANICAL wing (flap.mech) does not beat: it is a machine. Its plates are rigid (one flat quad each) and they move
-- as machines do, in hard steps: a fast move that overshoots and settles (a clunk), a hold, a hydraulic glide at an
-- even speed, a spring let go. Each motion is keyed like WING_KEYS but each key says how the move INTO it goes (`ease`:
-- snap, smooth, linear, drop), and its channels are a machine's: the root's raise (sr), sweep back (sw) and twist (st),
-- degrees added to the wing's own and written for flap.angle 20; `open` (0..1: how far a wing of blades has unfolded,
-- each blade snapping out in its turn, see `blades`); `spin` (the teeth its gears have turned, counting on round the
-- beat by the motion's `spin` each beat); `thrust` (0..1: how hard it works; what rides it with `throttle` follows it).
local MECH = {
	-- A machine holding still (the owner, 2026-11-07: machine wings do not beat like a bird's, they stand still): the
	-- plates never move, the engines run at full (what rides with `throttle` runs at its rate), and only the gears
	-- turning on their own (`rps`) move. An earlier jet trim-and-boost and a clockwork escapement swinging the whole
	-- wing were rejected: "not pretty".
	still = {
		keys = { { t = 0, thrust = 1 } },
	},
	-- Folding blades: a fan of steel blades shut behind the shoulder unfolds blade by blade, each one snapping out and
	-- locking (a puff at each lock, the hub's gear turning a tooth), holds spread, then folds back blade by blade from
	-- the last, venting, the gear winding back. The plate itself never lifts: only the blades move. (`open` runs
	-- evenly here: each blade snaps by the wing's blades.ease)
	fan = {
		rest = 0.6, -- (at rest: spread; `rest` is the share of the beat a wing shows when nothing moves it)
		shot = 0.54, -- (just spread, the last lock's sparks and steam in the air)
		keys = {
			{ t = 0.00, open = 0, spin = 0, thrust = 0 }, -- shut
			{ t = 0.06, open = 0, spin = 0, thrust = 0 },
			{ t = 0.12, open = 0.2, spin = 1, thrust = 1, ease = "linear" }, -- blade 1 locks
			{ t = 0.16, open = 0.2, spin = 1, thrust = 0 },
			{ t = 0.22, open = 0.4, spin = 2, thrust = 1, ease = "linear" },
			{ t = 0.26, open = 0.4, spin = 2, thrust = 0 },
			{ t = 0.32, open = 0.6, spin = 3, thrust = 1, ease = "linear" },
			{ t = 0.36, open = 0.6, spin = 3, thrust = 0 },
			{ t = 0.42, open = 0.8, spin = 4, thrust = 1, ease = "linear" },
			{ t = 0.46, open = 0.8, spin = 4, thrust = 0 },
			{ t = 0.52, open = 1, spin = 5, thrust = 1, ease = "linear" }, -- the last blade locks: spread
			{ t = 0.56, open = 1, spin = 5, thrust = 0 },
			{ t = 0.74, open = 1, spin = 5, thrust = 0 }, -- held spread
			{ t = 0.94, open = 0, spin = 0, thrust = 0.7, ease = "linear" }, -- folding back, venting
		},
	},
	-- Hovering blades (sword wings, 2026-11-08): the arm holds still, each blade bobs on its own (`blades.hover`), and
	-- once a beat the whole row spreads wide (`spread`: to `blades.wide`) and closes again, working (`thrust`, a gleam
	-- running out along the blades) as it opens.
	hover = {
		rest = 0.3,
		shot = 0.64, -- (just spread, the gleams on the blades)
		keys = {
			{ t = 0.00, spread = 0, thrust = 0 },
			{ t = 0.50, spread = 0, thrust = 0 },
			{ t = 0.60, spread = 1, thrust = 1 }, -- spreading wide, the gleams running out
			{ t = 0.72, spread = 1, thrust = 0.2 }, -- held
			{ t = 0.86, spread = 0, thrust = 0 }, -- closed
		},
	},
	-- A ring of glyphs lit one after another (rune wings, 2026-11-08): eight ticks of `spin` a beat, each a quick snap
	-- and a hold, so a gear on a `step` (the lit glyph) jumps from glyph to glyph; nothing else moves.
	rune = {
		spin = 8,
		keys = (function()
			local keys = {}
			for j = 0, 7 do
				table.insert(keys, { t = j / 8, spin = j, thrust = 1 })
				table.insert(keys, { t = j / 8 + 0.04, spin = j + 1, thrust = 1, ease = "snap" })
			end
			return keys
		end)(),
	},
	-- A hologram (2026-11-08): it holds still and, once a beat, glitches for a moment (`glitch`: the plate thrown about
	-- and flickering, see wingLight; `thrust` spits what rides it).
	holo = {
		rest = 0.2,
		keys = {
			{ t = 0.00, glitch = 0, thrust = 0 },
			{ t = 0.78, glitch = 0, thrust = 0 },
			{ t = 0.79, glitch = 1, thrust = 1, ease = "linear" },
			{ t = 0.85, glitch = 1, thrust = 1 },
			{ t = 0.86, glitch = 0, thrust = 0, ease = "linear" },
		},
	},
}
Builder.WingMech = MECH
local MECH_CHANNELS = { "sr", "sw", "st", "open", "spin", "thrust", "spread", "glitch" }
local MECH_REST = { open = 1 } -- (a channel a motion does not key: 0, but a fan it does not key stays open)

-- How a move goes from 0 to 1 over `u` (0..1): snap overshoots and settles back (a clunk), drop speeds up (a spring
-- or a weight let go), linear is even (hydraulic), smooth eases in and out.
local function mechEase(ease, u)
	u = math.clamp(u, 0, 1)
	if ease == "snap" then
		local c, v = 2.2, u - 1
		return 1 + (c + 1) * v * v * v + c * v * v
	elseif ease == "drop" then
		return u * u
	elseif ease == "linear" then
		return u
	end
	return u * u * (3 - 2 * u)
end
Builder.mechEase = mechEase

-- A mechanical motion's pose `beats` into it (beats since the start; a share of one beat at rest).
function Builder.mechPose(motion, beats)
	local keys = motion.keys
	local f = beats % 1
	local n = #keys
	local i = 1
	for k = 1, n do
		if keys[k].t <= f then
			i = k
		end
	end
	local a, b = keys[i], keys[i % n + 1]
	local finish = if i == n then 1 else b.t
	local p = mechEase(b.ease, (f - a.t) / math.max(finish - a.t, 1e-6))
	local pose = {}
	for _, c in MECH_CHANNELS do
		local from, to = a[c] or MECH_REST[c] or 0, b[c] or MECH_REST[c] or 0
		if c == "spin" and i == n then
			to += motion.spin or 0 -- (the gears go on round: the next beat starts where this one ended)
		end
		pose[c] = from + (to - from) * p
	end
	pose.spin += math.floor(beats) * (motion.spin or 0)
	pose.thrust = math.clamp(pose.thrust, 0, 1)
	return pose
end

local function mechTurn(back, up, pitch)
	return CFrame.Angles(0, math.rad(-back), 0)
		* CFrame.Angles(0, 0, math.rad(up))
		* CFrame.Angles(math.rad(pitch), 0, 0)
end

-- How far blade `i` of `n` has unfolded when the wing is `open` (0..1): each blade in its turn, snapping.
function Builder.bladeOpen(open, i, n, ease)
	return mechEase(ease or "snap", open * n - (i - 1))
end

-- How far up a thing that hovers ({ studs, seconds }) is at `clock` (nil: at rest), the `n`th of a row on its own
-- phase (the golden ratio apart: no two in step, however many).
local function hoverAt(hover, clock, n)
	if not clock then
		return 0
	end
	return hover[1] * math.sin((clock / hover[2] + n * 0.618) * 2 * math.pi)
end
Builder.hoverAt = hoverAt

-- A blade's length, a share of the wing's (`blades.length = { first, last }`; the whole length by default).
local function bladeLength(blades, share)
	return if blades.length then blades.length[1] + (blades.length[2] - blades.length[1]) * share else 1
end

-- A mechanical wing at `clock`: the frame at its root, and for a wing of blades, each blade's.
local function mechCurve(entry, clock)
	local wing, scale = entry.wing, entry.scale
	local flap = wing.flap
	local motion = MECH[flap.mech]
	local beats = if clock then clock / flap.period + (flap.phase or 0) else (motion.rest or 0)
	local pose = Builder.mechPose(motion, beats)
	local k = flap.angle / 20
	local sr, sw, st = pose.sr * k, pose.sw * k, pose.st * k
	local length = wing.length * scale
	local width = wing.width * scale
	local root = wing.root or { 0, 0, 0 }
	-- (a wing that hovers bobs up and down as a whole, what rides it too)
	local bob = if wing.hover then hoverAt(wing.hover, clock, 0) else 0
	local shoulder = CFrame.new(Vector3.new(root[1], root[2] + bob, root[3]) * scale)
		* CFrame.Angles(math.rad(wing.lean or 0), 0, 0)
		* mechTurn((wing.sweep or 0) + sw, (wing.raise or 0) + sr, st)
	local p0, f0 = sided(entry, shoulder)
	local p3 = sided(entry, shoulder * CFrame.new(length, 0, 0))
	local curve = {
		p0 = p0,
		p1 = p0:Lerp(p3, 1 / 3),
		p2 = p0:Lerp(p3, 2 / 3),
		p3 = p3,
		f0 = f0,
		fw = f0,
		f3 = f0,
		w0 = width,
		w1 = width,
		pose = pose,
		rigid = true,
	}
	local blades = wing.blades
	if blades then
		curve.blades = {}
		local n = blades.count
		for i = 1, n do
			local share = (i - 1) / (n - 1)
			local open = Builder.bladeOpen(pose.open, i, n, blades.ease)
			local spread = blades.raise[1] + (blades.raise[2] - blades.raise[1]) * share
			if blades.wide then
				-- (spread wide: the row fans out to its `wide` raises and back)
				spread += (blades.wide[1] + (blades.wide[2] - blades.wide[1]) * share - spread) * pose.spread
			end
			local raise = blades.shut[1] + (spread - blades.shut[1]) * open
			local sweep0 = blades.sweep and blades.sweep[1] or 0
			local sweep1 = blades.sweep and blades.sweep[2] or 0
			local sweep = blades.shut[2] + ((sweep0 + (sweep1 - sweep0) * share) - blades.shut[2]) * open
			-- (each blade's root along the arm, its own length, and its own bob, out of step with the others)
			local at = if blades.at then blades.at[1] + (blades.at[2] - blades.at[1]) * share else 0
			local long = bladeLength(blades, share)
			local float = if blades.hover then hoverAt(blades.hover, clock, i) * scale else 0
			local frame = CFrame.new(0, float, 0) * shoulder * CFrame.new(length * at, 0, 0) * mechTurn(sweep, raise, 0)
			local b0, fb = sided(entry, frame)
			curve.blades[i] = {
				p0 = b0,
				f = fb,
				p1 = sided(entry, frame * CFrame.new(length * long, 0, 0)),
				w = width * long,
			}
		end
	end
	return curve
end

local function thetaOf(flap, clock)
	return if flap and clock then (clock / flap.period + (flap.phase or 0)) * 2 * math.pi else 0
end

-- The curve of a wing at `clock` (seconds; nil: at rest), and its angle into the beat.
local function curveAt(entry, clock)
	local flap = entry.wing.flap
	local theta = thetaOf(flap, clock)
	if flap and flap.mech and not flap.bird then
		return mechCurve(entry, clock), theta
	end
	if flap and flap.keys then
		return keyedCurve(entry, clock), theta
	end
	if flap and flap.bird then
		local size
		if clock then
			local style = STYLES[flap.style or "beat"]
			theta, size = birdBeat(style, clock / flap.period * style.rate + (flap.phase or 0))
		end
		local curve = birdCurve(entry, theta, size)
		if flap.mech then
			-- (a bird's wing that is also magic (rune, holo, 2026-11-08: the owner wanted them beating gently as an
			-- angel's): it beats as a bird's, and its motion runs beside the beat, every `cycle` seconds, only for what
			-- its gears, light and riders do)
			local motion = MECH[flap.mech]
			local beats = if clock then clock / (flap.cycle or flap.period) + (flap.phase or 0) else (motion.rest or 0)
			curve.pose = Builder.mechPose(motion, beats)
		end
		return curve, theta
	end
	local frame = wingFrame(entry, if flap and clock then math.sin(theta) else 0)
	local reach = entry.side * entry.wing.length * entry.scale
	local width = entry.wing.width * entry.scale
	local p0, p3 = frame.Position, (frame * CFrame.new(reach, 0, 0)).Position
	return {
		p0 = p0,
		p1 = p0:Lerp(p3, 1 / 3),
		p2 = p0:Lerp(p3, 2 / 3),
		p3 = p3,
		f0 = frame,
		fw = frame,
		f3 = frame,
		w0 = width,
		w1 = width,
		plain = true,
		frame = frame,
		reach = reach,
	},
		theta
end

-- The spot of a curve `t` (0..1) from the root to the tip and `r` (-1..1) of its half width off its middle, and the
-- wing's frame there.
local function surface(curve, t, r)
	local frame = if t < 0.5 then curve.f0:Lerp(curve.fw, t * 2) else curve.fw:Lerp(curve.f3, t * 2 - 1)
	local at = bezier(curve.p0, curve.p1, curve.p2, curve.p3, t)
	if r ~= 0 then
		at += frame.YVector * (r * (curve.w0 + (curve.w1 - curve.w0) * t) / 2)
	end
	return at, frame
end

-- How far a gear is drawn toward the camera (Beam.ZOffset, studs at scale 1, seen square on), so it shows over its
-- wing. Gears near a wing's root were drawn under it, and moving them nearer the camera did not change that
-- (2026-11-08: pulled 0.3 studs nearer than the wing's middle, still under): only a ZOffset sorts them over it, 1 stud
-- seen from straight behind, more seen from a side. But a ZOffset slides the picture on the screen (it is drawn as if
-- that much nearer along the camera's look), so the gear is placed to undo that; and it shrinks as the wing turns
-- edge-on, where the gears of the far wing would be drawn over the body.
local GEAR_LIFT = 2.5
Builder.GearLift = GEAR_LIFT

-- A gear on a machine's wing, turned `turn` radians at `at` on the wing's `frame`, seen from `camera` (its CFrame in the
-- carrier's space; nil: none), lifted up to `lift` studs over the wing's own ZOffset `base`. It sits on the wing's
-- outer face (`out`, away from the body); seen from the other side, where the plate hides it, it is not drawn (the
-- owner saw gears in front of the body, 2026-11-08), unless the gear is on `both` faces: then it is drawn on the inner
-- face, lifted no more than the body's front stands nearer (`body`: the body's front, studs before the carrier's
-- middle), or it would show through the body. Seen from its side, it is placed so that, drawn nearer along the
-- camera's look, it lands on its hub: each of its offsets across the view and its size shrunk by (depth - lift) / depth.
local function placeGear(gear, at, frame, turn, out, camera, lift, base, both, body)
	local normal = if frame.ZVector:Dot(out) < 0 then -frame.ZVector else frame.ZVector
	local size = gear.size
	local shown = true
	if camera then
		local facing = (camera.Position - at).Unit:Dot(normal)
		local inner = both and facing < 0
		if inner then
			normal, facing = -normal, -facing
		end
		shown = facing > 0.1
		lift = math.floor(lift * math.max(facing, 0) * 10 + 0.5) / 10 -- (a tenth of a stud: few writes)
		if inner then
			-- (the gear stands at:Dot(out) behind the carrier's middle, the body's front `body` before it)
			lift = math.max(0, math.min(lift, math.floor((at:Dot(out) + body) * 0.8 * 10) / 10))
		end
	end
	at += normal * 0.02
	if camera then
		local view = camera:PointToObjectSpace(at)
		local depth = -view.Z
		if shown and depth > lift * 2 then
			local keep = (depth - lift) / depth
			at = camera:PointToWorldSpace(Vector3.new(view.X * keep, view.Y * keep, view.Z))
			size *= keep
		end
	end
	if gear.beam.ZOffset ~= base + lift then
		gear.beam.ZOffset = base + lift
	end
	local width = if shown then size else 0
	if gear.beam.Width0 ~= width then
		gear.beam.Width0 = width
		gear.beam.Width1 = width
	end
	local x = frame.XVector * math.cos(turn) + frame.YVector * math.sin(turn)
	local y = frame.YVector * math.cos(turn) - frame.XVector * math.sin(turn)
	gear.a0.CFrame = CFrame.fromMatrix(at - x * size / 2, x, y)
	gear.a1.CFrame = CFrame.fromMatrix(at + x * size / 2, x, y)
end

-- A number 0..1 that looks random but is the same for the same `n` (a glitch must be the same on both wings of a pair
-- and on a wing's body and glow).
local function hash(n)
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

-- How far a hologram's glitch throws its plate at `clock` (pose.glitch 0..1): a new jump 24 times a second, every
-- other one left in place, a few hundredths of a stud at most.
Builder.GlitchStuds = 0.14
Builder.GlitchRate = 24
Builder.LitSegments = 20 -- (a beam lit along its length: a build's front, a scan band, a twentieth of it a step)
local function glitchShake(entry, pose, clock)
	local glitch = pose.glitch or 0
	if glitch <= 0.01 or not clock then
		return Vector3.zero
	end
	local n = math.floor(clock * Builder.GlitchRate)
	if hash(n) < 0.35 then
		return Vector3.zero
	end
	local reach = Builder.GlitchStuds * entry.scale * glitch
	return Vector3.new((hash(n + 0.31) * 2 - 1) * reach, (hash(n + 0.57) * 2 - 1) * reach * 0.4, 0)
end

-- A Transparency along a beam: `alpha` from the root up to `front` (0..1), clear beyond it; and, if `band` (a share
-- of the length), only a band that wide either side of `front` (a scan line).
local function litAlong(alpha, front, band)
	if band then
		local a, b = math.max(front - band, 0.001), math.min(front + band, 0.999)
		if b <= a + 0.002 then
			return NumberSequence.new(1)
		end
		local mid = math.clamp(front, a + 0.001, b - 0.001)
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(a, 1),
			NumberSequenceKeypoint.new(mid, alpha),
			NumberSequenceKeypoint.new(b, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
	if front >= 1 then
		return NumberSequence.new(alpha)
	end
	local edge = math.clamp(front, 0.002, 0.95)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, if front <= 0 then 1 else alpha),
		NumberSequenceKeypoint.new(edge, if front <= 0 then 1 else alpha),
		NumberSequenceKeypoint.new(edge + 0.04, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
end
Builder.alongBeam = litAlong

-- How much of a wing is built `clock` seconds in (`build`: the seconds it takes, from the root out to the tip; the
-- clock of its first frame is when it was put on), 0..1, eased out.
local function builtAt(entry, clock)
	local build = entry.wing.build
	if not build or not clock then
		return 1
	end
	entry.born = entry.born or clock
	local u = math.clamp((clock - entry.born) / build, 0, 1)
	return 1 - (1 - u) * (1 - u)
end
Builder.builtAt = builtAt

-- A machine wing's light: built from the root out when it is put on (`build`), a scan band running over it (`scan`),
-- flickering in a glitch. Transparencies are written only when they change.
local function wingLight(entry, pose, clock)
	local wing = entry.wing
	local scan = entry.scan
	if not wing.build and not scan and (pose.glitch or 0) <= 0.01 and entry.lightKey == nil then
		return -- (a machine that never builds, scans nor glitches: its transparency is as made)
	end
	local built = builtAt(entry, clock)
	local glitch = pose.glitch or 0
	local alpha = wing.alpha or 0
	local key = math.floor(built * 50)
	if glitch > 0.01 and clock then
		-- (a flicker: the wing fades by a random step 24 times a second while the glitch lasts)
		local n = math.floor(clock * Builder.GlitchRate)
		alpha = math.min(alpha + hash(n + 0.83) * 0.65 * glitch, 1)
		key += 100 * (n % 1000 + 1)
	end
	if entry.lightKey ~= key then
		entry.lightKey = key
		local sequence = litAlong(alpha, built, nil)
		entry.beam.Transparency = sequence
		for _, blade in entry.blades do
			blade.beam.Transparency = sequence
		end
	end
	if scan then
		-- (while it builds, the band rides the front; then it runs root to tip every `every` seconds, resting off the
		-- ends a moment between passes)
		local spec = scan.spec
		local front = built
		if built >= 1 and clock then
			local every = spec.every or 2.4
			front = ((clock - (entry.born or 0)) % every) / every * 1.4 - 0.2
		end
		front = math.floor(front * 60 + 0.5) / 60
		if scan.front ~= front then
			scan.front = front
			scan.beam.Transparency = litAlong(spec.alpha or 0, front, spec.band or 0.08)
		end
	end
end

-- Where a wing is at `clock` (seconds; nil: at rest): its beam and the riders at one spot of it. `camera`: the
-- camera's CFrame in the carrier's space, if any.
local function placeWing(entry, clock, camera)
	local curve, theta = curveAt(entry, clock)
	entry.curve, entry.theta = curve, theta
	if curve.plain then
		entry.a0.CFrame = curve.frame
		entry.a1.CFrame = curve.frame * CFrame.new(curve.reach, 0, 0)
		for _, rider in entry.riders do
			if not rider.span then
				rider.attachment.CFrame = curve.frame * CFrame.new(curve.reach * rider.along, 0, 0)
			end
		end
		return
	end
	local pose = curve.pose
	local shake = if pose then glitchShake(entry, pose, clock) else Vector3.zero
	if curve.rigid then
		-- (a mechanical wing: rigid plates, its blades each on its own beam)
		local plates = curve.blades or { { p0 = curve.p0, f = curve.f0, p1 = curve.p3 } }
		for i, plate in plates do
			-- (the first on the wing's own beam; a blade the budget left out is not drawn)
			local blade = if i > 1 then entry.blades[i - 1] else entry
			if blade then
				blade.a0.CFrame = CFrame.fromMatrix(plate.p0 + shake, plate.f.XVector, plate.f.YVector)
				blade.a1.CFrame = CFrame.fromMatrix(plate.p1 + shake, plate.f.XVector, plate.f.YVector)
			end
		end
	elseif curve.arm then
		-- (a keyed wing: the arm on its beam, the hand on its own)
		for _, piece in
			{ { curve.arm, entry.beam, entry.a0, entry.a1 }, { curve.hand, entry.hand, entry.h0, entry.h1 } }
		do
			local at, beam = piece[1], piece[2]
			piece[3].CFrame = CFrame.fromMatrix(at.p0, at.f0.XVector, at.f0.YVector)
			piece[4].CFrame = CFrame.fromMatrix(at.p1, at.f1.XVector, at.f1.YVector)
			beam.CurveSize0 = at.c0
			beam.CurveSize1 = at.c1
			beam.Width1 = at.w1
		end
	else
		entry.a0.CFrame = CFrame.fromMatrix(curve.p0 + shake, curve.f0.XVector, curve.f0.YVector)
		entry.a1.CFrame = CFrame.fromMatrix(curve.p3 + shake, curve.f3.XVector, curve.f3.YVector)
		-- (a scan on a bird's wing: drawn on the same attachments, it bends and folds with the wing)
		for _, beam in { entry.beam, entry.scan and entry.scan.beam } do
			beam.CurveSize0 = curve.reach0
			beam.CurveSize1 = curve.reach1
			beam.Width1 = curve.w1
		end
	end
	if pose then
		-- (a machine's or a magic wing's light and its gears turned on it)
		wingLight(entry, pose, clock)
		-- (the wing's outer face looks away from the body: the root's own side of the carrier)
		local root = entry.wing.root or { 0, 0, 0 }
		local out = Vector3.new(0, 0, if root[3] < 0 then -1 else 1)
		for _, gear in entry.gears do
			local spec = gear.gear
			local at, frame = surface(curve, spec.along, spec.off or 0)
			local turn =
				math.rad((spec.step or 0) * pose.spin + (spec.rps or 0) * 360 * (clock or 0) + (spec.phase or 0))
			-- (the body's front: half a torso's depth, a fifth of the wing's reference height)
			local lift, base = GEAR_LIFT * entry.scale, entry.wing.zOffset or 0
			placeGear(gear, at + shake, frame, turn, out, camera, lift, base, spec.both, 0.5 * entry.scale)
		end
	end
	for _, rider in entry.riders do
		if not rider.span then
			local at, frame = surface(curve, rider.along, 0)
			rider.attachment.CFrame = frame.Rotation + at
		end
	end
end

-- A PIECE BORN OVER A SPAN of a wing (`along = { from, to }`): its emitter is moved to a random spot of the span and
-- fired one particle at a time, each thrown with `fling` times the wing's own speed at that spot (measured over
-- SpanStep seconds of the beat) plus its own speed: a wing made of many small flames that ride it and are shed by it.
Builder.SpanStep = 1 / 30
Builder.SpanBurst = 6 -- the most one span fires in an update (after a hitch: a few, never a burst)

-- A unit vector at most `degrees` off `direction`, evenly over that cone.
local function cone(direction, degrees)
	if degrees <= 0 then
		return direction
	end
	local cosine = 1 - math.random() * (1 - math.cos(math.rad(degrees)))
	local sine = math.sqrt(math.max(1 - cosine * cosine, 0))
	local turn = math.random() * 2 * math.pi
	local u = direction:Cross(if math.abs(direction.Y) < 0.9 then Vector3.new(0, 1, 0) else Vector3.new(1, 0, 0)).Unit
	local w = direction:Cross(u)
	return direction * cosine + (u * math.cos(turn) + w * math.sin(turn)) * sine
end

-- A piece's `direction` in the wing's frame at a spot (no direction: straight up).
local function spanAxis(entry, frame, direction)
	local out = frame.XVector * (if entry.curve.plain then entry.side else 1)
	local top = frame.YVector
	local back = out:Cross(top) * entry.side -- (the left wing's frame is the right's mirror: its cross product turns)
	if direction == "Right" then
		return out
	elseif direction == "Left" then
		return -out
	elseif direction == "Top" then
		return top
	elseif direction == "Bottom" then
		return -top
	elseif direction == "Back" then
		return back
	elseif direction == "Front" then
		return -back
	end
	return Vector3.new(0, 1, 0)
end

-- A spot `t` along and `r` across a wing's curve, or along blade `k` of it (nil: the wing's own plate).
local function spotOf(curve, k, t, r)
	if not k then
		return surface(curve, t, r)
	end
	local blade = curve.blades[k]
	return blade.p0:Lerp(blade.p1, t) + blade.f.YVector * (r * blade.w / 2), blade.f
end

local function emitSpans(entry, clock, dt)
	local later = nil
	for _, rider in entry.riders do
		local item = rider.item
		if rider.span and (item.want or 0) > 0 then
			local piece = item.piece
			local more = 1 + (piece.beat or 0) * math.sin(entry.theta) -- (the down stroke: 0..pi)
			local pose = entry.curve.pose
			if pose then
				-- (a machine, or a magic wing's motion: as hard as it works; `rate` is what it gives at full thrust)
				more *= 1 - (piece.throttle or 0) * (1 - pose.thrust)
			end
			rider.owed = math.min(rider.owed + item.want * dt * more, Builder.SpanBurst)
			local from, to = rider.along[1], rider.along[2]
			local speed = piece.speed or { 0, 0 }
			local spread = piece.spread or { 0, 0 }
			while rider.owed >= 1 do
				rider.owed -= 1
				local t = from + (to - from) * math.random()
				local r = (piece.off or 0) + (piece.across or 0) * (math.random() * 2 - 1)
				if piece.nozzles then
					-- (a machine's nozzles, vents or hubs: one of its spots each time)
					local spot = piece.nozzles[math.random(#piece.nozzles)]
					t, r = spot[1], spot[2] + (piece.across or 0) * (math.random() * 2 - 1)
				end
				-- (on a wing of blades, `blades`: on one of the blades drawn, each time another)
				local k = if piece.blades and entry.curve.blades then math.random(1 + #entry.blades) else nil
				local at, frame = spotOf(entry.curve, k, t, r)
				local velocity = Vector3.zero
				if (piece.fling or 0) > 0 then
					later = later or curveAt(entry, clock + Builder.SpanStep)
					velocity = (spotOf(later, k, t, r) - at) * (piece.fling / Builder.SpanStep)
				end
				local own = (speed[1] + ((speed[2] or speed[1]) - speed[1]) * math.random()) * rider.move
				if own > 0 then
					velocity += cone(spanAxis(entry, frame, piece.direction), math.max(spread[1], spread[2] or 0)) * own
				end
				-- (aimed along its own flight: the emitter sends it Top at exactly that speed)
				local length = velocity.Magnitude
				local up = if length > 1e-3 then velocity / length else Vector3.new(0, 1, 0)
				local across =
					up:Cross(if math.abs(up.Y) < 0.9 then Vector3.new(0, 1, 0) else Vector3.new(1, 0, 0)).Unit
				rider.attachment.CFrame = CFrame.fromMatrix(at, across, up)
				item.emitter.Speed = NumberRange.new(length)
				Builder.engine.emit(item.emitter, 1)
			end
		end
	end
end

local wingBeam

-- One side of a wing: two attachments on the carrier and the beam between them (a keyed wing: two of each), and of a
-- machine's, as many more blades and gears as `allowance` (the same on both sides).
local function makeWing(handle, wing, side, allowance)
	local scale = handle.scale
	local entry = {
		wing = wing,
		side = side,
		scale = scale,
		offset = Anchors.offset(wing.at or "chest", handle.size, false),
		riders = {},
	}
	local suffix = if side > 0 then "Right" else "Left"
	local keyed = wing.flap ~= nil and wing.flap.keys ~= nil
	entry.a0 = newAttachment(handle.carrier, `{wing.name}{suffix}Root`, Vector3.zero)
	entry.a1 = newAttachment(handle.carrier, `{wing.name}{suffix}Tip`, Vector3.zero)
	entry.beam = wingBeam(handle, wing, `{wing.name}{suffix}`, entry.a0, entry.a1, wing.texture, keyed)
	entry.blades, entry.gears, entry.parts = {}, {}, {}
	-- (a mechanical wing's other blades and its gears: a flat quad each, as many as the kind's `parts` allow)
	local allowed = allowance or 0
	for i = 2, if wing.blades then wing.blades.count else 1 do
		if allowed <= 0 then
			break
		end
		allowed -= 1
		local name = `{wing.name}{suffix}Blade{i}`
		local blade = { a0 = newAttachment(handle.carrier, name .. "Root", Vector3.zero) }
		blade.a1 = newAttachment(handle.carrier, name .. "Tip", Vector3.zero)
		blade.beam = wingBeam(handle, wing, name, blade.a0, blade.a1, wing.texture, false)
		-- (each blade a little behind the one before it: the fan's layers keep their order)
		blade.beam.ZOffset = (wing.zOffset or 0) - 0.02 * (i - 1)
		-- (a blade of its own length is as much narrower: the picture keeps its shape)
		local long = bladeLength(wing.blades, (i - 1) / (wing.blades.count - 1))
		blade.beam.Width0 = wing.width * scale * long
		blade.beam.Width1 = blade.beam.Width0
		table.insert(entry.blades, blade)
		table.insert(entry.parts, blade.beam)
	end
	if wing.blades then
		entry.beam.Width0 = wing.width * scale * bladeLength(wing.blades, 0)
		entry.beam.Width1 = entry.beam.Width0
	end
	for i, spec in wing.gears or {} do
		if allowed <= 0 then
			break
		end
		allowed -= 1
		local name = `{wing.name}{suffix}Gear{i}`
		local gear = { gear = spec, size = spec.size * scale }
		gear.a0 = newAttachment(handle.carrier, name .. "A", Vector3.zero)
		gear.a1 = newAttachment(handle.carrier, name .. "B", Vector3.zero)
		local look =
			{ texture = spec.texture, role = spec.role, color = spec.color, glow = spec.glow, width = spec.size }
		-- (drawn over the wing: see GEAR_LIFT and placeGear, which sets its ZOffset)
		look.zOffset = (wing.zOffset or 0) + GEAR_LIFT * scale
		gear.beam = wingBeam(handle, look, name, gear.a0, gear.a1, spec.texture, false)
		table.insert(entry.gears, gear)
		table.insert(entry.parts, gear.beam)
	end
	if wing.scan and allowed > 0 then
		-- (a scan: a lit copy of the picture on the wing's own attachments, seen only in a band: see wingLight)
		allowed -= 1
		local spec = wing.scan
		local look = {
			texture = spec.texture or wing.texture,
			role = spec.role or wing.role,
			color = spec.color or wing.color,
			glow = spec.glow,
			width = wing.width,
			additive = true,
			zOffset = (wing.zOffset or 0) + 0.05,
		}
		local beam = wingBeam(handle, look, `{wing.name}{suffix}Scan`, entry.a0, entry.a1, look.texture, false)
		beam.Segments = Builder.LitSegments
		beam.Transparency = NumberSequence.new(1)
		entry.scan = { beam = beam, spec = spec }
		table.insert(entry.parts, beam)
	end
	if wing.build or wing.scan then
		-- (a Transparency along the beam needs a quad for each step of it)
		entry.beam.Segments = Builder.LitSegments
		for _, blade in entry.blades do
			blade.beam.Segments = Builder.LitSegments
		end
	end
	if keyed then
		-- (a keyed wing's hand: its own beam from before the wrist to the tip)
		entry.h0 = newAttachment(handle.carrier, `{wing.name}{suffix}Wrist`, Vector3.zero)
		entry.h1 = newAttachment(handle.carrier, `{wing.name}{suffix}HandTip`, Vector3.zero)
		entry.hand = wingBeam(handle, wing, `{wing.name}{suffix}Hand`, entry.h0, entry.h1, wing.hand.texture, true)
	end
	placeWing(entry, nil)
	return entry
end

-- A wing's beam (or a keyed wing's arm or hand) between two attachments, drawn with `texture`.
function wingBeam(handle, wing, name, a0, a1, texture, keyed)
	local scale = handle.scale
	local beam = Instance.new("Beam")
	beam.Name = name
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	-- (a bird's wing bends: a curve of 12 quads; each piece of a keyed one bends less; a bat's pieces are straight,
	-- long stiff bones, one quad each)
	local rigid = keyed and wing.hand.pivot ~= nil
	beam.Segments = if rigid then 1 elseif keyed then 8 elseif wing.flap and wing.flap.bird then 12 else 1
	beam.FaceCamera = false
	beam.Texture = Textures.url(texture)
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
	beam.TextureSpeed = 0 -- (1 by default: the picture would slide along the wing)
	beam.LightInfluence = 0
	local additive = if wing.additive ~= nil then wing.additive else Textures.isBlack(wing.texture)
	beam.LightEmission = if additive then 1 else 0
	beam.Brightness = wing.glow or 1
	-- (a palette of several colours runs from the root to the tip; a keyed wing's arm and hand each take their part)
	local colors = Palette.resolve(handle.effect, wing, handle.opts.palette)
	local sequence = Palette.sequence(colors)
	if keyed then
		sequence = if texture == wing.texture
			then Palette.span(colors, 0, wing.hand.to)
			else Palette.span(colors, wing.hand.from, 1)
	end
	beam.Color = sequence or ColorSequence.new(Color3.new(1, 1, 1))
	beam.Transparency = NumberSequence.new(wing.alpha or 0)
	beam.ZOffset = wing.zOffset or 0
	beam.Width0 = wing.width * scale
	beam.Width1 = wing.width * scale
	beam.Parent = handle.folder
	return beam
end

-- ===== Serpents: an aura's dragon coiling round its host =====

-- Where a SERPENT's loop is at `u` (0..1 once round it, wrapping) in the carrier's frame, and the way it goes there: it
-- goes round the host `turns` times while it climbs from `low` to `high` studs over the feet and comes back down.
local function serpentAt(entry, u)
	local serpent = entry.serpent
	local turn = 2 * math.pi * serpent.turns
	local theta = turn * u + 2 * math.pi * (serpent.phase or 0)
	local wave = 2 * math.pi * u
	local rise = (serpent.high - serpent.low) * entry.scale
	local r = entry.radius
	local position = Vector3.new(
		r * math.cos(theta),
		entry.feet + serpent.low * entry.scale + rise * (1 - math.cos(wave)) / 2,
		r * math.sin(theta)
	)
	local heading =
		Vector3.new(-r * math.sin(theta) * turn, rise * math.pi * math.sin(wave), r * math.cos(theta) * turn)
	return position, heading
end

-- Which way a serpent's width runs at `position`, going along `heading`: across its line, as near up as it can be; or,
-- drawn from the SIDE (`side`) with a camera at `eye`, turned to the camera round its own line with its back kept on
-- the upper side, so it stays the right way up all round the host (a camera-facing ribbon turns its picture over on
-- the far side of the loop, where it runs the other way across the screen). Seen from straight above, back outward.
local function serpentWidth(position, heading, eye)
	local x = heading.Unit
	local width = if eye then x:Cross(eye - position) else Vector3.zero
	if width.Magnitude < 1e-4 then
		local up = if math.abs(x.Y) > 0.95 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
		return (up - x * up:Dot(x)).Unit
	end
	width = width.Unit
	local outward = Vector3.new(position.X, 0, position.Z)
	local lean = width.Y + 0.3 * (if outward.Magnitude > 1e-4 then width:Dot(outward.Unit) else 0)
	return if lean < 0 then -width else width
end

-- Moves a serpent's head to `clock / period` of the way round its loop: the Trail behind it lays the picture along
-- the path just flown, whole, `length` studs of it. A side-drawn one is turned to the camera at `eye` (in the
-- carrier's frame) when there is one.
local function placeSerpent(entry, clock, eye)
	local serpent = entry.serpent
	local position, heading = serpentAt(entry, (clock or 0) / serpent.period)
	local half = serpentWidth(position, heading, if serpent.side then eye else nil) * serpent.width * entry.scale / 2
	-- (the picture's left edge, its back when drawn from the side, at Attachment0)
	entry.back.Position = position + half
	entry.belly.Position = position - half
end

-- How far a 3D serpent's body swims off its path, `s` studs behind the snout at `clock`: up (its wave, running from
-- the head back, small at the head) and to its right (the tail's swish, growing to the tip).
local function modelSwim(entry, s, clock)
	local model, scale = entry.model, entry.modelScale
	local up, right = 0, 0
	local wave = model.wave
	if wave then
		local share = math.min(1, s / (0.3 * model.length * scale))
		up = wave.height
			* scale
			* (0.25 + 0.75 * share)
			* math.sin(2 * math.pi * (s / (wave.length * scale) - clock / wave.period))
	end
	local tail = model.tail
	if tail and s > entry.tailFrom then
		local share = math.min(1, (s - entry.tailFrom) / (entry.tailTo - entry.tailFrom))
		right = tail.sway * scale * share * math.sin(2 * math.pi * (s / (tail.length * scale) - clock / tail.period))
	end
	return up, right
end

-- Bends a 3D serpent (`model`) along its loop at `clock`: each spine bone where the head was `behind` studs ago, its
-- back kept up, the body swimming up and down on that path, the tail swishing, the head looking about and the legs
-- clawing. (A bone's rest is straight along +Z; `offset` turns that rest onto the frame.)
local function placeModelSerpent(entry, clock)
	if not entry.part then
		return
	end
	local serpent = entry.serpent
	clock = clock or 0
	local head = clock / serpent.period
	-- (each bone by length along the loop, not by its share of the time: it climbs slower than it turns, and a share
	-- of the time would squeeze the body where it is slow)
	local arc, steps = entry.arc, #entry.arc - 1
	local function shareAt(length)
		length %= entry.total
		local low, high = 1, steps + 1
		while high - low > 1 do
			local middle = (low + high) // 2
			if arc[middle] <= length then
				low = middle
			else
				high = middle
			end
		end
		local span = arc[high] - arc[low]
		return (low - 1 + (if span > 0 then (length - arc[low]) / span else 0)) / steps
	end
	local headU = head % 1
	local headIndex = math.floor(headU * steps)
	local headLength = arc[headIndex + 1] + (arc[headIndex + 2] - arc[headIndex + 1]) * (headU * steps - headIndex)
	local frames = entry.frames
	for index = 1, #entry.inverse do
		local s = entry.behind[index]
		local position, heading = serpentAt(entry, shareAt(headLength - s))
		local frame = CFrame.lookAt(position, position + heading, Vector3.yAxis)
		-- (off the path by its swim, and turned to the swim's slope: forward is towards the snout, `s` falling)
		local up, right = modelSwim(entry, s, clock)
		local upAhead, rightAhead = modelSwim(entry, s - 0.05, clock)
		local upBehind, rightBehind = modelSwim(entry, s + 0.05, clock)
		frames[index] = frame
			* CFrame.new(right, up, 0)
			-- (turned about its up first, then pitched: so it never rolls)
			* CFrame.fromEulerAnglesYXZ(
				math.atan((upAhead - upBehind) / 0.1),
				-math.atan((rightAhead - rightBehind) / 0.1),
				0
			)
	end
	local look = entry.model.head
	if look then
		-- (the neck bends a share at each joint from the bone behind the head forward, so the snout turns the most and
		-- no bone parts from the next)
		local turn = 2 * math.pi * clock / look.period
		local bend = CFrame.fromEulerAnglesYXZ(
			math.rad(look.pitch) * math.sin(1.37 * turn + 1) / look.bones,
			math.rad(look.yaw) * math.sin(turn) / look.bones,
			0
		)
		local was, now = frames[look.bones + 1], frames[look.bones + 1]
		for index = look.bones, 1, -1 do
			local rest = frames[index]
			frames[index] = now * bend * was:Inverse() * rest
			was, now = rest, frames[index]
		end
	end
	for index = 1, #entry.inverse do
		local transform = entry.inverse[index] * frames[index] * entry.offset[index]
		for _, layer in entry.layers do
			layer.bones[index].Transform = transform
		end
	end
	for n, leg in entry.legs do
		local stroke = 2 * math.pi * (clock / leg.period + leg.phase)
		-- (forward and back about the body's side, out and in about its up: out reaches the claws away from the body)
		local transform = CFrame.fromAxisAngle(leg.axis, leg.swing * math.sin(stroke))
			* CFrame.fromAxisAngle(leg.out, leg.spread * (0.5 + 0.5 * math.sin(stroke + 1)))
		for _, layer in entry.layers do
			layer.legs[n].Transform = transform
		end
	end
end

-- Shows or hides a 3D serpent's layers (Lod).
local function showModelSerpent(entry, on)
	entry.hidden = not on
	for _, layer in entry.layers or {} do
		layer.part.Transparency = if on then layer.alpha else 1
	end
end

-- A model's MeshPart with its bones, built once for each model (it loads its mesh) and cloned for each host.
local modelTemplates = {}

local function modelTemplate(key)
	local template = modelTemplates[key]
	if template then
		return template
	end
	local model = Models.list[key]
	local part = Builder.engine.meshPart(model.mesh)
	part.Name = key
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Material = (Enum.Material :: any)[model.look]
	local root = Instance.new("Bone")
	root.Name = "Root"
	root.Position = Vector3.new(table.unpack(model.root))
	root.Parent = part
	local t = model.turn
	local turn = CFrame.new(0, 0, 0, t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9])
	local spine = {}
	for index = 1, model.bones do
		local bone = Instance.new("Bone")
		bone.Name = Models.boneName(index)
		bone.CFrame = CFrame.new(0, 0, model.first - (index - 1) * model.step) * turn
		bone.Parent = root
		spine[index] = bone
	end
	for _, leg in model.legs or {} do
		local bone = Instance.new("Bone")
		bone.Name = leg.name
		bone.Position = Vector3.new(table.unpack(leg.at))
		bone.Parent = spine[leg.bone]
	end
	modelTemplates[key] = part
	return part
end

-- Puts a 3D serpent's body on its host once its mesh has loaded (run apart: loading yields), sized to the host.
local function wearModel(handle, entry)
	local key = entry.serpent.model
	local ok, template = pcall(modelTemplate, key)
	if not ok then
		warn(`VfxLib: {handle.id} could not load its model {key} ({template})`)
		return
	end
	if handle.dead then
		return
	end
	local model = Models.list[key]
	local scale = entry.scale * (entry.serpent.size or 1)
	local part = template:Clone()
	part.Size *= scale
	for _, bone in part:GetDescendants() do
		if bone:IsA("Bone") then
			bone.CFrame = bone.CFrame.Rotation + bone.CFrame.Position * scale
		end
	end
	part.Color = entry.color
	part.CFrame = handle.carrier.CFrame
	-- (its look, and a faint solid copy of the body under it: a see-through hologram alone fades out over a bright
	-- sky, lesson 51)
	entry.layers = { { part = part, alpha = 0 } }
	if model.fill then
		local fill = part:Clone()
		fill.Name = key .. "Fill"
		fill.Material = Enum.Material.Neon
		table.insert(entry.layers, { part = fill, alpha = model.fill })
	end
	local root = part:FindFirstChild("Root") :: Bone
	local snout = model.snout * scale
	entry.model, entry.modelScale, entry.frames = model, scale, {}
	entry.inverse, entry.offset, entry.behind, entry.legs = {}, {}, {}, {}
	for index = 1, model.bones do
		local bone = root:FindFirstChild(Models.boneName(index)) :: Bone
		local rest = root.CFrame * bone.CFrame
		local straight = CFrame.lookAt(rest.Position, rest.Position + Vector3.zAxis, Vector3.yAxis)
		entry.inverse[index] = rest:Inverse()
		entry.offset[index] = straight:Inverse() * rest
		entry.behind[index] = snout - rest.Position.Z
	end
	if model.tail then
		entry.tailFrom = entry.behind[model.bones - model.tail.bones]
		entry.tailTo = entry.behind[model.bones]
	end
	for _, leg in model.legs or {} do
		local parent = root:FindFirstChild(Models.boneName(leg.bone)) :: Bone
		local bone = parent:FindFirstChild(leg.name) :: Bone
		local rest = root.CFrame * parent.CFrame * bone.CFrame
		-- (it swings about the body's own side to side, and reaches out about its up, away from the body on each side:
		-- its axes in the leg's frame)
		local out = if leg.at[1] < 0 then Vector3.yAxis else -Vector3.yAxis
		table.insert(entry.legs, {
			axis = rest:VectorToObjectSpace(Vector3.xAxis),
			out = rest:VectorToObjectSpace(out),
			phase = leg.phase,
			swing = math.rad(leg.swing or Builder.LegSwing),
			spread = math.rad(leg.spread or 0),
			period = leg.period or Builder.LegPeriod,
		})
	end
	for _, layer in entry.layers do
		local layerRoot = layer.part:FindFirstChild("Root") :: Bone
		layer.bones, layer.legs = {}, {}
		for index = 1, model.bones do
			layer.bones[index] = layerRoot:FindFirstChild(Models.boneName(index)) :: Bone
		end
		for _, leg in model.legs or {} do
			table.insert(layer.legs, layer.bones[leg.bone]:FindFirstChild(leg.name) :: Bone)
		end
		weld(handle.carrier, layer.part)
		layer.part.Parent = handle.folder
	end
	showModelSerpent(entry, not entry.hidden)
	entry.part = part
	placeModelSerpent(entry, handle.serpentClock)
end

-- Where a point riding an orbit is at `clock`, in the carrier's frame (`entry`: its orbit, radius and height in studs).
local function orbitPoint(entry, clock)
	local orbit = entry.orbit
	local angle = (clock / orbit.period + (orbit.phase or 0)) * 2 * math.pi
	local radius, y = entry.radius, entry.y
	-- (a wandering path: its height and its reach rise and fall on beats of their own)
	if orbit.bob then
		y += math.sin(clock / orbit.bob[2] * 2 * math.pi) * orbit.bob[1] * entry.scale
	end
	if orbit.sway then
		radius += math.sin(clock / orbit.sway[2] * 2 * math.pi) * orbit.sway[1] * entry.scale
	end
	return Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius), angle
end

-- A fish's MeshPart in its own picture with its bones (by the names its skin was made with, at their rest frames),
-- built once for each fish (it loads its mesh) and cloned for each swimmer.
local fishTemplates = {}

local function fishTemplate(key)
	local template = fishTemplates[key]
	if template then
		return template
	end
	local fish = Models.fish[key]
	local part = Builder.engine.meshPart(fish.mesh)
	part.Name = key
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.TextureID = `rbxassetid://{fish.texture or Models.FishTexture}`
	local parent, rest = part, CFrame.identity
	for index, b in fish.bones do
		local frame = CFrame.fromMatrix(
			Vector3.new(b[1], b[2], b[3]),
			Vector3.new(b[4], b[5], b[6]),
			Vector3.new(b[7], b[8], b[9])
		)
		local bone = Instance.new("Bone")
		bone.Name = `{key}_{index - 1}`
		bone.CFrame = rest:Inverse() * frame
		bone.Parent = parent
		parent, rest = bone, frame
	end
	fishTemplates[key] = part
	return part
end

-- Moves a swimmer to `clock`: head first along its path (it tilts as the path climbs or falls), its tail sweeping side
-- to side, a wave running from the head back, the head barely turning.
local function placeSwimmer(handle, entry, clock)
	local at = orbitPoint(entry, clock)
	local ahead = orbitPoint(entry, clock + 0.05)
	local turn = CFrame.lookAt(at, ahead)
	if entry.joint and not entry.part.Anchored then
		entry.joint.C0 = turn
	else
		entry.part.CFrame = handle.carrier.CFrame * turn
	end
	local swim = entry.swimmer.swim or {}
	local beat = (clock / (swim.period or Builder.SwimPeriod) + entry.beat) * 2 * math.pi
	local reach = math.rad(swim.degrees or Builder.SwimDegrees)
	local count = #entry.bones
	for k, bone in entry.bones do
		local share = if k == 1 then 0.2 else (k - 1) / (count - 1)
		bone.Transform = CFrame.fromAxisAngle(entry.axes[k], reach * share * math.sin(beat - (k - 1) * Builder.SwimLag))
	end
end

-- Puts a swimmer's fish on its host once its mesh has loaded (run apart: loading yields), its length in studs at the
-- host's scale.
local function wearFish(handle, entry)
	local key = entry.swimmer.model
	local ok, template = pcall(fishTemplate, key)
	if not ok then
		warn(`VfxLib: {handle.id} could not load its fish {key} ({template})`)
		return
	end
	if handle.dead then
		return
	end
	local fish = Models.fish[key]
	local scale = entry.swimmer.length * entry.scale / fish.size[3]
	local part = template:Clone()
	part.Size *= scale
	entry.bones, entry.axes = {}, {}
	local parent: Instance = part
	for index, b in fish.bones do
		local bone = parent:FindFirstChild(`{key}_{index - 1}`) :: Bone
		bone.CFrame = bone.CFrame.Rotation + bone.CFrame.Position * scale
		-- (the sweep turns it about the fish's up, in the bone's own frame)
		local frame = CFrame.fromMatrix(Vector3.zero, Vector3.new(b[4], b[5], b[6]), Vector3.new(b[7], b[8], b[9]))
		entry.bones[index] = bone
		entry.axes[index] = frame:VectorToObjectSpace(Vector3.yAxis)
		parent = bone
	end
	if handle.carrier.Anchored then
		part.Anchored = true
	else
		-- (a Weld, not a WeldConstraint: its C0 carries the fish round without moving the host)
		local joint = Instance.new("Weld")
		joint.Part0 = handle.carrier
		joint.Part1 = part
		joint.Parent = part
		entry.joint = joint
	end
	part.Transparency = if entry.hidden then 1 else 0
	entry.part = part
	placeSwimmer(handle, entry, handle.serpentClock or 0)
	part.Parent = handle.folder
end

-- A SWIMMER of an aura: one of the library's fish (Models.fish) going round the host on its orbit, head first.
local function makeSwimmer(handle, swimmer)
	local orbit = swimmer.orbit
	local entry = {
		swimmer = swimmer,
		orbit = orbit,
		scale = handle.scale,
		y = -handle.size.Y / 2 + orbit.y * handle.scale,
		radius = orbit.radius * handle.scale,
		-- (each fish on a beat of its own, so a school never sweeps as one)
		beat = (orbit.phase or 0) * 3.7,
		hidden = false,
	}
	task.spawn(wearFish, handle, entry)
	return entry
end

-- A SERPENT of an aura: one long picture (`texture`, head first, uncut) on a Trail whose two attachments fly the loop
-- on the carrier: the Trail bends the picture smoothly along any curve, with no joint anywhere (the owner, on four
-- beams end to end: "where they meet does not look good when it turns").
local function makeSerpent(handle, serpent)
	local scale = handle.scale
	local entry = {
		serpent = serpent,
		scale = scale,
		radius = serpent.radius * scale,
		feet = -handle.size.Y / 2,
	}
	-- (the loop's length: its head's speed, so the Trail lasts as long as its body takes to pass)
	local total, last = 0, serpentAt(entry, 0)
	for step = 1, 64 do
		local point = serpentAt(entry, step / 64)
		total += (point - last).Magnitude
		last = point
	end
	entry.total = total
	if serpent.model then
		-- (a 3D body, one skinned MeshPart: its bones are laid along the loop every frame, by length along it)
		entry.arc = { 0 }
		local before = serpentAt(entry, 0)
		for step = 1, 256 do
			local point = serpentAt(entry, step / 256)
			entry.arc[step + 1] = entry.arc[step] + (point - before).Magnitude
			before = point
		end
		entry.total = entry.arc[257]
		entry.color = Palette.color3(colorOf(handle.effect, serpent, handle.opts.palette))
		task.spawn(wearModel, handle, entry)
		return entry
	end
	local length = serpent.length * scale
	local glow = serpent.glow or 1
	entry.back = newAttachment(handle.carrier, `{serpent.name}Back`, Vector3.zero)
	entry.belly = newAttachment(handle.carrier, `{serpent.name}Belly`, Vector3.zero)
	local trail = Instance.new("Trail")
	trail.Name = serpent.name
	trail.Attachment0 = entry.back
	trail.Attachment1 = entry.belly
	trail.Lifetime = length / (total / serpent.period)
	trail.MaxLength = length -- (a host on the run leaves no longer a dragon behind it)
	trail.MinLength = 0.05
	trail.FaceCamera = not serpent.side -- (a side-drawn one is turned to the camera by hand, its back kept up)
	trail.Texture = Textures.url(serpent.texture)
	trail.TextureMode = Enum.TextureMode.Stretch
	trail.LightInfluence = 0
	if Textures.isBlack(serpent.texture) then
		trail.LightEmission = 1
		trail.Brightness = 0.35 + 0.65 * glow
	else
		trail.LightEmission = math.min(glow, 1)
		trail.Brightness = math.max(glow, 1)
	end
	trail.Color = Palette.sequence(Palette.resolve(handle.effect, serpent, handle.opts.palette))
		or ColorSequence.new(Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new(0)
	trail.WidthScale = NumberSequence.new(1, serpent.taper or 1)
	entry.trail = trail
	placeSerpent(entry, 0)
	trail.Parent = handle.folder
	return entry
end

local function hostHeight(size, opts)
	return opts.height or size.Y
end

-- A LASTING effect on `host`. opts = { palette, variant, grade (a key of the effect's `grades`), height (studs: the host's
-- own, when its box says less), parent (where the folder goes, the host by default) }. nil when the host has no part.
function Builder.attach(effect, host, opts)
	opts = opts or {}
	local fields = Builder.variantOf(effect, opts.variant)
	local cframe, size, root = Builder.boxOf(host)
	if not cframe then
		return nil
	end
	local height = hostHeight(size, opts)
	local raw = height / (fields.refHeight or 5) * (fields.fit or 1)
	local scale = math.clamp(raw, 0.2, Builder.MaxScale)
	local move = math.clamp(raw, 0.2, Builder.SpeedScale)
	local kindBudget = Budget.kindRow(fields.kind, fields.tier) or Budget.Kinds.aura
	local grade = opts.grade and fields.grades and fields.grades[opts.grade]

	local folder = Instance.new("Folder")
	folder.Name = "VfxLib_" .. fields.id
	folder:SetAttribute("VfxId", fields.id)
	local carrier = newPart("Carrier", size * 0.8, cframe, folder)
	local handle = {
		id = fields.id,
		effect = fields,
		host = host,
		root = root,
		folder = folder,
		carrier = carrier,
		size = size,
		height = height,
		scale = scale,
		move = move,
		budget = kindBudget,
		opts = opts,
		behind = fields.kind == "trail",
		parts = {},
		anchors = {},
		orbits = {},
		flaps = {},
		wings = {},
		serpents = {},
		swimmers = {},
		wingTick = 0,
		partsLeft = kindBudget.parts or 0,
		items = {},
		bands = {},
		light = nil,
		mode = "full",
		shiftAt = -1,
		speed = 0,
		continuous = true,
	}

	for index, band in fields.bands or {} do
		if index > (kindBudget.bands or 3) then
			break
		end
		table.insert(handle.bands, makeBand(handle, band, index))
	end

	local wingsByName = {}
	for index, wing in fields.wings or {} do
		if index > (kindBudget.wings or 0) / 2 then
			break
		end
		if Quality.secondary() or not wing.secondary then
			-- (a machine's other blades and gears, a quad each side, out of the kind's parts: the same on both sides)
			local wants = (if wing.blades then wing.blades.count - 1 else 0)
				+ #(wing.gears or {})
				+ (if wing.scan then 1 else 0)
			local allowance = math.min(wants, math.floor(handle.partsLeft / 2))
			handle.partsLeft -= 2 * allowance
			local pair = { makeWing(handle, wing, 1, allowance), makeWing(handle, wing, -1, allowance) }
			handle.geared = handle.geared or #pair[1].gears > 0 -- (its gears are placed by the camera)
			wingsByName[wing.name] = pair
			table.insert(handle.wings, pair[1])
			table.insert(handle.wings, pair[2])
		end
	end

	for index, serpent in fields.serpents or {} do
		if index > (kindBudget.serpents or 0) then
			break
		end
		table.insert(handle.serpents, makeSerpent(handle, serpent))
	end

	for index, swimmer in fields.swimmers or {} do
		if index > (kindBudget.swimmers or 0) then
			break
		end
		if Quality.secondary() or not swimmer.secondary then
			table.insert(handle.swimmers, makeSwimmer(handle, swimmer))
		end
	end

	local specs = {}
	for _, piece in fields.pieces or {} do
		if #specs >= kindBudget.emitters then
			break
		end
		if piece.rate and (Quality.secondary() or not piece.secondary) then
			if piece.wing then
				-- (a piece that rides a wing: one emitter on each side, moving with it)
				for side, entry in wingsByName[piece.wing] or {} do
					local spec = specOf(piece, scale, grade)
					spec.rider = entry
					spec.side = side
					table.insert(specs, spec)
				end
			else
				table.insert(specs, specOf(piece, scale, grade))
			end
		end
	end
	Budget.limit(specs, kindBudget, if raw > 2 then raw / 2 else nil)
	for _, spec in specs do
		if spec.piece.steady then
			spec.rate = spec.piece.rate -- (a clock hand: one in the air, whatever the budget asks of the rest)
		end
	end
	local ctx = {
		effect = fields,
		palette = opts.palette,
		height = height,
		move = move,
		grade = grade,
		continuous = true,
	}
	for _, spec in specs do
		local emitter = makeEmitter(spec.piece, spec, ctx)
		local item = { emitter = emitter, spec = spec, piece = spec.piece, last = -1 }
		if spec.rider then
			local entry = spec.rider
			local along = spec.piece.along or 0.7
			local attachment = newAttachment(handle.carrier, `{spec.piece.name}{spec.side}`, Vector3.zero)
			if spec.piece.nozzles then
				along = { 0, 1 } -- (born at its nozzles: emitSpans picks one each time)
			end
			if type(along) == "table" then
				-- (born over a span of the wing, aimed and fired one at a time: emitSpans)
				item.span = true
				emitter.Enabled = false
				emitter.EmissionDirection = Enum.NormalId.Top
				emitter.SpreadAngle = Vector2.new(0, 0)
				table.insert(
					entry.riders,
					{ attachment = attachment, along = along, item = item, span = true, owed = 0, move = move }
				)
				entry.spans = true
			else
				table.insert(entry.riders, { attachment = attachment, along = along })
			end
			placeWing(entry, nil)
			emitter.Parent = attachment
		else
			emitter.Parent = parentFor(handle, spec.piece)
		end
		table.insert(handle.items, item)
	end

	local light = fields.light
	if light and (kindBudget.lights or 0) > 0 then
		local point = Instance.new("PointLight")
		point.Color = Palette.color3(colorOf(fields, light, opts.palette))
		point.Range = math.clamp((light.range or 10) * scale, 4, kindBudget.light)
		point.Brightness = light.brightness or 1
		point.Shadows = false -- (a light that casts them costs a depth pass for each host)
		point.Parent = carrier
		handle.light = point
		handle.lightBase = point.Brightness
	end

	folder.Parent = opts.parent or host
	if root then
		if root.Anchored and not opts.weld then
			carrier.Anchored = true
			for _, part in handle.parts do
				part.Anchored = true
			end
		else
			weld(root, carrier)
		end
	else
		carrier.Anchored = true
	end
	Builder.update(handle, { speed = 0, mode = "full" })
	return handle
end

function Builder.detach(handle)
	handle.dead = true
	if handle.folder then
		handle.folder:Destroy()
	end
end

-- The rates, light, orbits and colours of a lasting effect. info = { speed (studs a second; the trail's run), mode
-- ("full" | "half" | "ribbon" | "off": Lod's level of detail), light (false: Lod gave the light to another host), clock }
function Builder.update(handle, info)
	local effect = handle.effect
	local speed = info.speed or handle.speed
	handle.speed = speed
	local mode = info.mode or handle.mode
	handle.mode = mode
	local moving = math.clamp((speed - Builder.MoveMin) / (Builder.RunSpeed - Builder.MoveMin), 0, 1)
	local share = if mode == "full" then 1 elseif mode == "half" then 0.5 else 0
	local keep = handle.folder:GetAttribute("VfxKeepQuality") == true -- (the showroom: the authored look)
	for _, item in handle.items do
		local piece = item.piece
		local factor = share
		if piece.motion == "run" then
			factor *= math.max(moving, piece.idle or effect.idle or 0)
		end
		local rate = item.spec.rate * factor
		if piece.steady then
			rate = if share > 0 then item.spec.rate else 0 -- (exact: a hand out every turn, however slow)
		else
			if not keep then
				rate = Quality.rate(rate)
			end
			rate = math.floor(rate * Builder.Grain + 0.5) / Builder.Grain
		end
		if rate ~= item.last then
			if piece.steady and rate > 0 and item.last <= 0 then
				Builder.engine.emit(item.emitter, 1) -- (the engine's first would come one life later)
			end
			item.last = rate
			if item.span then
				item.want = rate -- (its emitter stays off: emitSpans fires it)
			else
				item.emitter.Rate = rate
				item.emitter.Enabled = rate > 0
			end
		end
	end
	local light = handle.light
	if light then
		local on = mode == "full" and info.light ~= false and (keep or Quality.lights(1) > 0)
		local run = 1
		if (effect.kind == "trail") or effect.idle then
			run = 0.4 + 0.6 * math.max(moving, effect.idle or 0)
			on = on and math.max(moving, effect.idle or 0) > 0
		end
		if light.Enabled ~= on then
			light.Enabled = on
		end
		local brightness = handle.lightBase * run
		if on and math.abs(light.Brightness - brightness) > 0.05 then
			light.Brightness = brightness
		end
	end
	for _, entry in handle.bands do
		local on = mode ~= "off"
		if entry.trail.Enabled ~= on then
			entry.trail.Enabled = on
		end
	end
	for _, entry in handle.wings do
		local on = mode ~= "off" and mode ~= "ribbon"
		if entry.beam.Enabled ~= on then
			entry.beam.Enabled = on
			if entry.hand then
				entry.hand.Enabled = on
			end
			for _, beam in entry.parts do
				beam.Enabled = on
			end
		end
	end
	for _, entry in handle.serpents do
		local on = mode == "full" or mode == "half"
		if entry.trail then
			if entry.trail.Enabled ~= on then
				entry.trail.Enabled = on
			end
		elseif entry.hidden ~= not on then
			showModelSerpent(entry, on)
		end
	end
	local clock = info.clock
	if clock then
		handle.serpentClock = clock
	end
	for _, entry in handle.swimmers do
		local on = mode == "full" or mode == "half"
		if entry.hidden ~= not on then
			entry.hidden = not on
			if entry.part then
				entry.part.Transparency = if on then 0 else 1
			end
		end
		-- (a fish swims on every frame, near or far, or it would stutter round the host)
		if clock and on and entry.part then
			placeSwimmer(handle, entry, clock)
		end
	end
	if clock and (mode == "full" or mode == "half") then
		-- (a serpent glides on: every frame, near or far, or its body would stutter round the host)
		local eye = nil
		for _, entry in handle.serpents do
			if entry.serpent.model then
				placeModelSerpent(entry, clock)
				continue
			end
			if entry.serpent.side and not eye then
				local ok, at = pcall(Builder.engine.camera)
				if ok and at then
					eye = handle.carrier.CFrame:PointToObjectSpace(at.Position)
				end
			end
			placeSerpent(entry, clock, eye)
		end
	end
	if clock and #handle.wings > 0 and (mode == "full" or mode == "half") then
		-- (near: every frame; farther: a few times less often, the beat still reads)
		handle.wingTick += 1
		if mode == "full" or handle.wingTick % Builder.WingHalfEvery == 0 then
			local dt = math.clamp(clock - (handle.wingClock or clock), 0, 0.25)
			handle.wingClock = clock
			local camera = nil
			if handle.geared then
				local ok, at = pcall(Builder.engine.camera)
				if ok and at then
					camera = handle.carrier.CFrame:ToObjectSpace(at)
				end
			end
			for _, entry in handle.wings do
				placeWing(entry, clock, camera)
				if entry.spans then
					emitSpans(entry, clock, dt)
				end
			end
		end
	end
	if clock then
		if mode ~= "off" and mode ~= "ribbon" then
			for _, entry in handle.orbits do
				local at, angle = orbitPoint(entry, clock)
				if entry.orbit.heading then
					-- (Front, -Z, along the way it goes round)
					entry.attachment.CFrame = CFrame.lookAt(at, at + Vector3.new(-math.sin(angle), 0, math.cos(angle)))
				else
					entry.attachment.Position = at
				end
			end
			for _, entry in handle.flaps do
				-- (a soft beat: a sine, the far edge up and down about the spine's front-to-back line)
				local flap = entry.flap
				local beat = math.sin((clock / flap.period + (flap.phase or 0)) * 2 * math.pi)
				local turn = entry.hinge * CFrame.Angles(0, 0, math.rad(flap.angle) * beat * entry.side) * entry.rest
				-- (an anchored host, a statue or the showroom's pedestal, anchors its wings too: a weld moves nothing there)
				if entry.joint and not entry.part.Anchored then
					entry.joint.C0 = turn
				else
					entry.part.CFrame = handle.carrier.CFrame * turn
				end
			end
		end
		if clock - handle.shiftAt >= Builder.ShiftEvery then
			handle.shiftAt = clock
			for _, entry in handle.bands do
				local band = entry.band
				if band.shift then
					local start = clock / band.shift + (band.phase or 0)
					local span = band.span or 0.6
					local list = {}
					for index = 1, 4 do
						list[index] = Palette.loop(band.colors, start + span * (index - 1) / 3)
					end
					entry.trail.Color = Palette.sequence(list)
				end
			end
		end
	end
end

-- ===== One-shots =====

local function playFolder(parent)
	if parent then
		return parent
	end
	local found = workspace:FindFirstChild("VfxLib")
	if not found then
		found = Instance.new("Folder")
		found.Name = "VfxLib"
		found.Parent = workspace
	end
	return found
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

-- The value at `t` of keys { { t, v } } held flat outside them.
-- A curve through world `points` (Catmull-Rom, its ends doubled), each leg timed by its length so the flight keeps one
-- speed: a dragon's climb, dive and coil, a meteor from the sky.
local function pathOf(points)
	local legs, total = {}, 0
	for index = 1, #points - 1 do
		legs[index] = (points[index + 1] - points[index]).Magnitude
		total += legs[index]
	end
	return { points = points, legs = legs, total = math.max(total, 1e-3) }
end

-- The position and heading `p` (0 to 1) of the way along a path from pathOf.
local function pathAt(path, p)
	local points, legs = path.points, path.legs
	local left = math.clamp(p, 0, 1) * path.total
	local index = 1
	while index < #legs and left > legs[index] do
		left -= legs[index]
		index += 1
	end
	local u = math.clamp(left / math.max(legs[index], 1e-3), 0, 1)
	local p0 = points[math.max(index - 1, 1)]
	local p1 = points[index]
	local p2 = points[index + 1]
	local p3 = points[math.min(index + 2, #points)]
	local b = p2 - p0
	local c = p0 * 2 - p1 * 5 + p2 * 4 - p3
	local d = p1 * 3 - p0 - p2 * 3 + p3
	local position = (p1 * 2 + b * u + c * (u * u) + d * (u * u * u)) * 0.5
	local heading = (b + c * (2 * u) + d * (3 * u * u)) * 0.5
	return position, heading
end

local function keyAt(keys, t)
	if t <= keys[1][1] then
		return keys[1][2]
	end
	for index = 2, #keys do
		local a, b = keys[index - 1], keys[index]
		if t <= b[1] then
			local span = b[1] - a[1]
			return lerp(a[2], b[2], if span > 0 then (t - a[1]) / span else 1)
		end
	end
	return keys[#keys][2]
end

-- An attachment frame at `position` whose X axis (the way a Beam's curve leaves it) points along `direction`. A flat
-- Beam's width runs along its attachments' Y axis (seen in Studio, docs/vfx/experiments/2026-11-06-storm-set.md): with
-- `normal` (an arc's plane) Y lies in that plane, so the ribbon lies flat in the swing; without, Y is as near up as it
-- can be (the ribbon stands).
local function axisFrame(position, direction, normal)
	local x = if direction.Magnitude > 1e-6 then direction.Unit else Vector3.new(0, 0, -1)
	if normal then
		local inPlane = normal:Cross(x)
		if inPlane.Magnitude > 1e-6 then
			return CFrame.fromMatrix(position, x, inPlane.Unit)
		end
	end
	local up = if math.abs(x.Y) > 0.95 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
	local y = (up - x * up:Dot(x)).Unit
	return CFrame.fromMatrix(position, x, y)
end

-- A BEAM of a one-shot: a ribbon of the picture between two points of the play's frame (a crescent slash bent by its
-- `bulge`, an energy beam, a bolt whose `jitter` crackles), lit for `life` seconds from `delay`.
local function makeBeam(live, beam, index, ctx)
	local turn = beam.turn or { 0, 0, 0 }
	local spin = turn[3] + (if beam.aim ~= nil then (ctx.angle or 0) + beam.aim else 0)
	local rotation = CFrame.Angles(math.rad(turn[1]), math.rad(turn[2]), math.rad(spin))
	-- (a `caster` beam's numbers are in the caster's frame: swords standing out of a portal behind the caster)
	-- (an `along` beam's are in a frame on the ground on the way from the caster to the spot: a spike rising on that
	-- path; along = { a, b }: its from end at a of the way, its to end at b, a crack running along it)
	local along = beam.along
	local frame = if along
		then ctx.along(if type(along) == "table" then along[1] else along)
		elseif beam.caster then ctx.caster
		else CFrame.new()
	local toFrame = if type(along) == "table" then ctx.along(along[2]) else frame
	local turned = frame.Rotation * rotation
	local from = frame * (rotation * vector(beam.from, ctx.scale))
	local to = toFrame * (rotation * vector(beam.to, ctx.scale))
	if beam.start == "from" and ctx.source then
		-- (a beam thrown from the caster: it starts at `opts.from`, `from` studs off it)
		from = ctx.cframe:PointToObjectSpace(ctx.source) + vector(beam.from, ctx.scale)
	end
	local bulge = if beam.bulge then turned * vector(beam.bulge, ctx.scale) else Vector3.new(0, 0, 0)
	-- (a flat arc lies in its own plane: a crescent slash is a blade of light in the swing, not a wall standing on it)
	local normal = nil
	-- (`stand`: no plane; the width is as near up as it can be, a curved wall standing on the ground)
	if beam.face ~= true and not beam.stand then
		local cross = (to - from):Cross(bulge)
		normal = if cross.Magnitude > 1e-6 then cross.Unit else nil
	end
	if beam.flat then
		normal = Vector3.new(0, 1, 0) -- (a straight ribbon lying level: a crack of lava along the ground)
	end
	-- (the attachments' X axis: the way the curve leaves them, the bulge; a flat beam's along its own line, so its
	-- width lies level across it)
	local axis = if beam.flat then to - from else bulge
	local a0 = Instance.new("Attachment")
	a0.Name = `Beam{index}From`
	a0.CFrame = axisFrame(from, axis, normal)
	a0.Parent = live.anchor
	local a1 = Instance.new("Attachment")
	a1.Name = `Beam{index}To`
	a1.CFrame = axisFrame(to, axis, normal)
	a1.Parent = live.anchor
	local item = Instance.new("Beam")
	item.Name = beam.name or `Beam{index}`
	item.Attachment0 = a0
	item.Attachment1 = a1
	-- (the control points sit `bulge` off both ends, the same way: an arc, not an S)
	item.CurveSize0 = bulge.Magnitude
	item.CurveSize1 = -bulge.Magnitude
	-- (an emerging beam's front is drawn in its Transparency along its length: it needs the segments, lesson 88)
	item.Segments = beam.segments
		or (if beam.emerge then Builder.LitSegments elseif beam.bulge or beam.jitter then 16 else 1)
	item.FaceCamera = beam.face == true
	item.Texture = Textures.url(beam.texture)
	if beam.length then
		item.TextureMode = Enum.TextureMode.Wrap
		item.TextureLength = beam.length * ctx.scale
	else
		item.TextureMode = Enum.TextureMode.Stretch
	end
	item.TextureSpeed = beam.speed or 0
	item.LightInfluence = 0
	local glow = beam.glow or 1
	if Textures.isBlack(beam.texture) then
		item.LightEmission = 1
		item.Brightness = 0.35 + 0.65 * glow
	else
		item.LightEmission = math.min(glow, 1)
		item.Brightness = math.max(glow, 1)
	end
	local colors = beam.colors or Palette.resolve(ctx.effect, beam, ctx.palette)
	item.Color = Palette.sequence(colors) or ColorSequence.new(Color3.new(1, 1, 1))
	item.ZOffset = beam.zOffset or 0
	item.Width0 = 0
	item.Width1 = 0
	item.Transparency = NumberSequence.new(1)
	item.Enabled = false
	item.Parent = live.folder
	local width = beam.width or { 1, 1 }
	local strike = nil
	if beam.strike then
		-- (it leaves its place `at` seconds in and darts, point first, along a bent path into the spot)
		local data = beam.strike
		local wander = data.wander or 0
		local random = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2 * wander
		strike = {
			at = ctx.delay + (beam.delay or 0) + data.at,
			seconds = data.seconds,
			bend = frame.Rotation * vector(data.bend or { 0, 0, 0 }, ctx.scale) + random * ctx.scale,
			target = vector(data.aim or { 0, 0, 0 }, ctx.scale),
			length = (to - from).Magnitude,
		}
		local band = data.trail
		if band then
			-- (a ribbon behind its hilt while it flies: the path each sword took)
			local top = Instance.new("Attachment")
			top.Name = `Beam{index}TrailTop`
			top.Parent = live.anchor
			local bottom = Instance.new("Attachment")
			bottom.Name = `Beam{index}TrailBottom`
			bottom.Parent = live.anchor
			local trail = Instance.new("Trail")
			trail.Name = (beam.name or `Beam{index}`) .. "Trail"
			trail.Attachment0 = top
			trail.Attachment1 = bottom
			trail.Texture = Textures.url(band.texture)
			trail.TextureMode = Enum.TextureMode.Stretch
			trail.FaceCamera = true
			trail.Lifetime = band.life or 0.3
			trail.LightInfluence = 0
			trail.LightEmission = 1
			trail.Brightness = band.glow or 1
			trail.Color = Palette.sequence(band.colors or Palette.resolve(ctx.effect, band, ctx.palette))
				or ColorSequence.new(Color3.new(1, 1, 1))
			trail.Transparency = NumberSequence.new(band.alpha or 0, 1)
			trail.WidthScale = NumberSequence.new(1, band.taper or 0.2)
			trail.Enabled = false
			trail.Parent = live.folder
			strike.trail = trail
			strike.top = top
			strike.bottom = bottom
			strike.half = (band.width or 1) * ctx.scale / 2
		end
	end
	return {
		beam = item,
		data = beam,
		a0 = a0,
		a1 = a1,
		p0 = from,
		p1 = to,
		bulge = bulge,
		axis = axis,
		normal = normal,
		from = ctx.delay + (beam.delay or 0),
		life = beam.life,
		w0 = width[1] * ctx.scale,
		w1 = (width[2] or width[1]) * ctx.scale,
		alpha = -1,
		flickerAt = -math.huge,
		slide = if beam.slide then turned * vector(beam.slide, ctx.scale) else nil,
		strike = strike,
		-- (a rolling beam's ends in its frame on the path, and that frame's place along the way; what rides it is put
		-- on its middle, turned as it)
		rollFrom = rotation * vector(beam.from, ctx.scale),
		rollTo = rotation * vector(beam.to, ctx.scale),
		alongAt = ctx.along,
		middle = (from + to) / 2 + bulge * 0.75,
		facing = turned,
	}
end

-- A rigid beam with its `to` end (a sword's point) at `point`, pointing along `direction`, `length` long.
local function placeAlong(entry, point, direction, length)
	entry.a0.CFrame = axisFrame(point - direction * length, entry.axis, entry.normal)
	entry.a1.CFrame = axisFrame(point, entry.axis, entry.normal)
end

-- A beam at the one-shot's time `t`: its width, its transparency (its keys over its life, laid over its `edge` along
-- its length), a crackle, and a quick fade once the one-shot is cancelled.
local function stepBeam(live, entry, t)
	local data = entry.data
	local p = (t - entry.from) / entry.life
	local on = p >= 0 and p < 1
	if live.cancelled and (entry.from > live.cancelled or t - live.cancelled >= live.fade) then
		on = false -- (cancelled: one still to come never comes, one lit fades out)
	end
	if on then
		local alpha = if data.transparency then Budget.valueAt(data.transparency, p) else math.max(0, 2 * p - 1)
		if live.cancelled then
			alpha = 1 - (1 - alpha) * math.max(0, 1 - (t - live.cancelled) / live.fade)
		end
		local grow = if data.grow then Budget.valueAt(data.grow, p) else 1
		entry.beam.Width0 = entry.w0 * grow
		entry.beam.Width1 = entry.w1 * grow
		if math.abs(alpha - entry.alpha) > 0.01 then
			entry.alpha = alpha
			local edge = data.edge or { 0, 0 }
			entry.beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1 - (1 - alpha) * (1 - edge[1])),
				NumberSequenceKeypoint.new(1, 1 - (1 - alpha) * (1 - edge[2])),
			})
		end
		if data.jitter and t - entry.flickerAt >= (data.flicker or 0.06) then
			-- (a bolt: both control points thrown somewhere new across the line, a few times a second)
			entry.flickerAt = t
			local reach = data.jitter * (live.scale or 1)
			local function across()
				return Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2
			end
			entry.a0.CFrame = axisFrame(entry.p0, entry.bulge + across() * reach, entry.normal)
			entry.a1.CFrame = axisFrame(entry.p1, entry.bulge + across() * reach, entry.normal)
			entry.beam.CurveSize0 = reach * (0.5 + math.random())
			entry.beam.CurveSize1 = -reach * (0.5 + math.random())
		end
	end
	if entry.slide and not entry.landed then
		-- (a beam falling into its place, faster and faster, as a sword dropped from the sky; where it lands its
		-- `land` piece is born)
		local s = math.clamp((t - entry.from) / (data.fall or 0.15), 0, 1)
		local offset = entry.slide * (1 - s * s)
		entry.a0.CFrame = axisFrame(entry.p0 + offset, entry.axis, entry.normal)
		entry.a1.CFrame = axisFrame(entry.p1 + offset, entry.axis, entry.normal)
		if s >= 1 then
			entry.landed = true
			local lander = data.land and live.landers[data.land]
			if lander and not live.cancelled then
				lander.emitter.Parent.CFrame = CFrame.new(entry.p1)
				local count = Quality.count(data.landCount or lander.count)
				if count > 0 then
					Builder.engine.emit(lander.emitter, count)
				end
			end
		end
	end
	if data.emerge and not entry.struck then
		-- (out of a portal: it slides out along its own line, its point first, and only what is out shows; the hilt last)
		local s = math.clamp((t - entry.from) / data.emerge, 0, 1)
		if data.rise and not entry.risen and t >= entry.from then
			-- (as it starts to come out, its `rise` piece is born where it comes out: rocks and dust as a spike breaks
			-- the ground)
			entry.risen = true
			local lander = live.landers[data.rise]
			if lander and not live.cancelled then
				lander.emitter.Parent.CFrame = CFrame.new(entry.p0)
				local count = Quality.count(data.riseCount or lander.count)
				if count > 0 then
					Builder.engine.emit(lander.emitter, count)
				end
			end
		end
		local out = 1 - (1 - s) * (1 - s)
		local back = (entry.p0 - entry.p1) * (1 - out)
		entry.a0.CFrame = axisFrame(entry.p0 + back, entry.axis, entry.normal)
		entry.a1.CFrame = axisFrame(entry.p1 + back, entry.axis, entry.normal)
		if on and s < 1 then
			local alpha = if data.transparency
				then Budget.valueAt(data.transparency, math.clamp(p, 0, 1))
				else math.max(0, 2 * p - 1)
			local cut = 1 - out
			local keys = { NumberSequenceKeypoint.new(0, 1) }
			if cut > 0.02 then
				table.insert(keys, NumberSequenceKeypoint.new(cut - 0.01, 1))
			end
			table.insert(keys, NumberSequenceKeypoint.new(math.max(cut, 0.001), alpha))
			table.insert(keys, NumberSequenceKeypoint.new(1, alpha))
			entry.beam.Transparency = NumberSequence.new(keys)
			entry.alpha = -1 -- (once out, the usual transparency is drawn again)
		end
	end
	local roll = data.roll
	if roll and not entry.rolled then
		-- (the whole beam slides along the path at one speed, from its `along` to `roll.to`: a wave rolling in)
		local s = math.clamp((t - entry.from - (roll.at or 0)) / roll.seconds, 0, 1)
		local frame = entry.alongAt(lerp(data.along, roll.to, s))
		entry.p0 = frame * entry.rollFrom
		entry.p1 = frame * entry.rollTo
		entry.middle = (entry.p0 + entry.p1) / 2 + entry.bulge * 0.75
		entry.a0.CFrame = axisFrame(entry.p0, entry.axis, entry.normal)
		entry.a1.CFrame = axisFrame(entry.p1, entry.axis, entry.normal)
		entry.rolled = s >= 1
	end
	local taut = data.taut
	if taut and not entry.tightened then
		-- (its slack, the bulge, pulled out: past straight a little and back, a chain snapping tight)
		local u = math.clamp((t - entry.from - taut.at) / taut.seconds, 0, 1)
		local v = u - 1
		local k = 1 - (1 + 2.70158 * v * v * v + 1.70158 * v * v)
		local reach = entry.bulge.Magnitude * k
		entry.beam.CurveSize0 = reach
		entry.beam.CurveSize1 = -reach
		entry.middle = (entry.p0 + entry.p1) / 2 + entry.bulge * (0.75 * k)
		entry.tightened = u >= 1
	end
	local strike = entry.strike
	if strike and not entry.struck and t >= strike.at then
		if not strike.start then
			-- (it turns from where it points and bends round into the spot)
			strike.start = entry.p1
			local direction = (entry.p1 - entry.p0).Unit
			local reach = (strike.target - strike.start).Magnitude
			strike.control = strike.start + direction * reach * 0.4 + strike.bend
			if strike.trail and not live.cancelled then
				strike.trail.Enabled = true
			end
		end
		local s = math.clamp((t - strike.at) / strike.seconds, 0, 1)
		local u = s * s -- (faster and faster: it darts)
		local a, c, b = strike.start, strike.control, strike.target
		local point = a * ((1 - u) * (1 - u)) + c * (2 * (1 - u) * u) + b * (u * u)
		local tangent = (c - a) * (2 * (1 - u)) + (b - c) * (2 * u)
		local direction = if tangent.Magnitude > 1e-6 then tangent.Unit else (b - a).Unit
		placeAlong(entry, point, direction, strike.length)
		if strike.trail then
			local hilt = point - direction * strike.length
			local side = direction:Cross(Vector3.new(0, 1, 0))
			side = if side.Magnitude > 1e-3 then side.Unit else Vector3.new(1, 0, 0)
			strike.top.Position = hilt + side * strike.half
			strike.bottom.Position = hilt - side * strike.half
		end
		if s >= 1 or live.cancelled then
			-- (it strikes: gone into the target, its `land` piece born there)
			entry.struck = true
			if strike.trail then
				strike.trail.Enabled = false
			end
			local lander = data.land and live.landers[data.land]
			if lander and not live.cancelled then
				lander.emitter.Parent.CFrame = CFrame.new(strike.target)
				local count = Quality.count(data.landCount or lander.count)
				if count > 0 then
					Builder.engine.emit(lander.emitter, count)
				end
			end
		end
	end
	if entry.struck then
		on = false
	end
	if entry.beam.Enabled ~= on then
		entry.beam.Enabled = on
	end
end

-- A ONE-SHOT. `at` is a Vector3, a CFrame or a host (played at its box, which also sizes `box` pieces). opts = {
-- palette, variant, grade, scale (a size factor), size (a Vector3: the box `box` pieces are shares of, e.g. an upgraded
-- area), from (a Vector3: a `projectile` flies from here first), angle (degrees on screen: the blow's direction, for
-- `aim` pieces), adornees (instances the effect's `highlight` outlines), parent, follow (true: played on a host, it
-- moves and turns with it: a charge on a runner; the effect's own `follow` says the same) }. Returns the live one-shot
-- (Builder.step runs it; Builder.cancel ends it softly): { markers, duration, ... }.
function Builder.play(effect, at, opts)
	opts = opts or {}
	local fields = Builder.variantOf(effect, opts.variant)
	local cframe, size, root
	local follow = false
	if typeof(at) == "Vector3" then
		cframe = CFrame.new(at)
	elseif typeof(at) == "CFrame" then
		cframe = at
	else
		cframe, size, root = Builder.boxOf(at)
		follow = root ~= nil and (opts.follow or fields.follow) == true
		if cframe and follow then
			cframe = CFrame.new(cframe.Position) * (root.CFrame - root.CFrame.Position) -- (it turns with the host)
		else
			cframe = cframe and CFrame.new(cframe.Position)
		end
	end
	if not cframe then
		return nil
	end
	local ref = fields.refHeight or 5
	local scale = (opts.scale or 1) * (fields.fit or 1)
	size = opts.size or size or Vector3.new(ref, ref, ref) * scale
	local kindBudget = Budget.Kinds[fields.kind] or Budget.Kinds.burst
	local grade = opts.grade and fields.grades and fields.grades[opts.grade]
	-- the caster's frame (pieces and beams marked `caster`): at `opts.from`, level, facing the spot (-z toward it); with
	-- no caster given, 12 studs back from the spot along the play's +z
	local casterFrame = cframe * CFrame.new(0, 0, 12)
	if opts.from then
		local flat = (cframe.Position - opts.from) * Vector3.new(1, 0, 1)
		casterFrame = if flat.Magnitude > 1e-3
			then CFrame.lookAt(opts.from, opts.from + flat)
			else CFrame.new(opts.from)
	end
	local casterLocal = cframe:ToObjectSpace(casterFrame)
	-- the path on the ground from the caster to the spot (beams and pieces marked `along`): a level frame at `f` of the
	-- way (0 under the caster, 1 under the spot), on the spot's ground, turned as the caster's frame (-z toward the spot)
	local groundY = Anchors.offset("ground", size).Y
	local pathFrom = Vector3.new(casterLocal.X, groundY, casterLocal.Z)
	local pathTo = Vector3.new(0, groundY, 0)
	local function alongFrame(f)
		return CFrame.new(pathFrom:Lerp(pathTo, f)) * casterLocal.Rotation
	end

	local folder = Instance.new("Folder")
	folder.Name = "VfxLib_" .. fields.id
	folder:SetAttribute("VfxId", fields.id)
	local anchor = newPart("Anchor", Vector3.new(0.2, 0.2, 0.2), cframe, folder)
	anchor.Anchored = true

	local delay = 0
	local live = {
		id = fields.id,
		effect = fields,
		folder = folder,
		anchor = anchor,
		t = 0,
		events = {},
		streams = {},
		lights = {},
		outlines = {},
		markers = table.clone(fields.markers or {}),
		emitters = {},
		beams = {},
		spins = {},
		landers = {},
		riding = {},
		scale = scale,
		longest = 0,
	}

	local function emitterParent(piece)
		if piece.ride then
			-- (born on a rolling beam's middle and going with it: moved each step, see `live.riding`; its box, when it has
			-- one, lies along the beam)
			local partSize = Vector3.new(0.2, 0.2, 0.2)
			if piece.box then
				partSize = Vector3.new(size.X * piece.box[1], size.Y * piece.box[2], size.Z * piece.box[3])
			end
			local part = newPart("Ride_" .. piece.name, partSize, cframe, folder)
			part.Anchored = true
			local shift = if piece.offset then vector(piece.offset, scale) else Vector3.zero
			table.insert(live.riding, { part = part, beam = piece.ride, offset = CFrame.new(shift) })
			return part
		end
		if piece.along then
			-- (a spot on the ground on the way from the caster to the spot, turned as the caster's frame; `offset` studs
			-- in that frame)
			local attachment = newAttachment(anchor, "Along_" .. piece.name, Vector3.new(0, 0, 0))
			attachment.CFrame = alongFrame(piece.along)
				* (if piece.offset then CFrame.new(vector(piece.offset, scale)) else CFrame.new())
			return attachment
		end
		if piece.caster then
			-- (a spot of the caster's frame: a portal standing behind the caster's back)
			local attachment = newAttachment(anchor, "Caster_" .. piece.name, casterLocal * vector(piece.caster, scale))
			-- (turned as the caster's frame: Front toward the spot, Top up)
			attachment.CFrame = casterLocal * CFrame.new(vector(piece.caster, scale))
			return attachment
		end
		local offset = Anchors.offset(piece.at or "origin", size)
		if piece.offset then
			-- (studs at refHeight from the anchor: a sheet of glitter over the egg)
			offset += vector(piece.offset, scale)
		end
		if piece.box or piece.radius then
			local partSize
			if piece.radius then
				local across = piece.radius * 2 * scale
				partSize = Vector3.new(across, across, across)
			else
				partSize = Vector3.new(size.X * piece.box[1], size.Y * piece.box[2], size.Z * piece.box[3])
			end
			local part = newPart("Box", partSize, cframe * CFrame.new(offset), folder)
			part.Anchored = true
			return part
		end
		if offset.Magnitude < 1e-3 then
			return anchor
		end
		return newAttachment(anchor, "At_" .. (piece.at or "origin"), offset)
	end

	-- the flight first: one picture thrown from `from` that lands at `at` (an arc of `arc` studs), turned along its path;
	-- or, with a `path`, a curve through its points (a dragon climbing, diving and coiling; a meteor from the sky)
	local riderCount = 0
	local projectile = fields.projectile
	local path = nil
	if projectile and projectile.path then
		path = {}
		for index, point in projectile.path do
			local spot = alongFrame(point[1]) * vector({ point[2], point[3], point[4] }, scale)
			path[index] = cframe * spot
		end
	end
	if projectile and (opts.from or path) then
		local seconds = projectile.seconds
		local wait = projectile.wait or 0
		local arc = projectile.arc or 0
		local gravity = 8 * arc / (seconds * seconds)
		local origin = if path then path[1] else opts.from
		local d = cframe.Position - origin
		local v0 = (d + Vector3.new(0, 0.5 * gravity * seconds * seconds, 0)) / seconds
		if path then
			v0 = (path[2] - path[1]) / seconds
		end
		local start = newPart("Shot", Vector3.new(0.2, 0.2, 0.2), CFrame.lookAt(origin, origin + v0), folder)
		start.Anchored = true
		if not (projectile.head or projectile.body) then
			local piece = table.clone(projectile)
			piece.riders = nil
			piece.trail = nil
			piece.life = { seconds, seconds }
			local spec = specOf(piece, scale, nil)
			local emitter =
				makeEmitter(piece, spec, { effect = fields, palette = opts.palette, height = ref, move = 1 })
			emitter.Speed = NumberRange.new(v0.Magnitude)
			emitter.EmissionDirection = Enum.NormalId.Front
			emitter.SpreadAngle = Vector2.new(0, 0)
			emitter.Acceleration = Vector3.new(0, -gravity, 0)
			emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
			emitter.Parent = start
			table.insert(live.events, {
				at = wait,
				run = function()
					Builder.engine.emit(emitter, 1)
				end,
			})
		end
		delay = wait + seconds
		live.markers.impact = delay
		if projectile.riders or projectile.trail or projectile.head or projectile.body then
			-- (what rides the flight: a part moved each step along the same arc as the picture, turned along its path;
			-- its riders shed flames and sparks into the air behind it, its trail draws a ribbon)
			local flight = newPart("Flight", Vector3.new(0.2, 0.2, 0.2), start.CFrame, folder)
			flight.Anchored = true
			live.flight = {
				part = flight,
				from = origin,
				velocity = v0,
				gravity = gravity,
				seconds = seconds,
				wait = wait,
				ease = projectile.ease,
				path = path and pathOf(path),
				done = false,
			}
			local head = projectile.head
			local back = 0
			if head then
				-- (the picture on a Beam lying along the flight, facing the camera: its `from` end behind, its `to`
				-- end at the front; a dragon's head, a meteor's rock and flames)
				back = head.length * scale
				local neck = newAttachment(flight, "HeadBack", Vector3.new(0, 0, back))
				local front = newAttachment(flight, "HeadFront", Vector3.zero)
				local beam = Instance.new("Beam")
				beam.Name = "Head"
				beam.Attachment0 = neck
				beam.Attachment1 = front
				beam.FaceCamera = true
				beam.Segments = 1
				beam.Texture = Textures.url(head.texture)
				beam.TextureMode = Enum.TextureMode.Stretch
				beam.TextureSpeed = 0 -- (1 by default: the picture would slide along the flight, its cut showing)
				beam.LightInfluence = 0
				local glow = head.glow or 1
				if Textures.isBlack(head.texture) then
					beam.LightEmission = 1
					beam.Brightness = 0.35 + 0.65 * glow
				else
					beam.LightEmission = math.min(glow, 1)
					beam.Brightness = math.max(glow, 1)
				end
				beam.Color = Palette.sequence(head.colors or Palette.resolve(fields, head, opts.palette))
					or ColorSequence.new(Color3.new(1, 1, 1))
				beam.Width0 = head.width * scale
				beam.Width1 = head.width * scale
				beam.ZOffset = head.zOffset or 2
				beam.Enabled = false
				beam.Parent = flight
				live.flight.head = beam
			end
			local body = projectile.body
			if body and path then
				-- (a serpent's body: curved Beams laid each step along the path just flown, from behind the head back
				-- `length` studs, one for each of its pictures (`textures`: one long serpent cut in slices, neck to
				-- tail, each running `overlap` of a slice into its neighbours, where they fade into each other); their top
				-- rows toward the neck. It follows the head's own path, so it coils as it did)
				local spine = newPart("Body", Vector3.new(0.2, 0.2, 0.2), CFrame.new(), folder)
				spine.Anchored = true
				local pictures = body.textures or { body.texture }
				local taper = body.taper or 0.4
				local beams = {}
				local color = Palette.sequence(body.colors or Palette.resolve(fields, body, opts.palette))
					or ColorSequence.new(Color3.new(1, 1, 1))
				for index, picture in pictures do
					local beam = Instance.new("Beam")
					beam.Name = if #pictures == 1 then "Body" else "Body" .. index
					beam.Attachment0 = newAttachment(spine, "BodyFront" .. index, Vector3.zero)
					beam.Attachment1 = newAttachment(spine, "BodyBack" .. index, Vector3.zero)
					beam.FaceCamera = true
					beam.Segments = math.max(6, math.ceil(24 / #pictures))
					beam.Texture = Textures.url(picture)
					beam.TextureMode = Enum.TextureMode.Stretch
					beam.TextureSpeed = 0
					beam.LightInfluence = 0
					local glow = body.glow or 1
					if Textures.isBlack(picture) then
						beam.LightEmission = 1
						beam.Brightness = 0.35 + 0.65 * glow
					else
						-- (a solid picture keeps its colours over a bright sky; `glow` under 1 is how much it shines)
						beam.LightEmission = math.min(glow, 1)
						beam.Brightness = math.max(glow, 1)
					end
					beam.Color = color
					beam.Width0 = body.width * scale * lerp(1, taper, (index - 1) / #pictures)
					beam.Width1 = body.width * scale * lerp(1, taper, index / #pictures)
					beam.ZOffset = (body.zOffset or 1)
					beam.Enabled = false
					beam.Parent = spine
					beams[index] = beam
				end
				live.flight.body =
					{ beams = beams, back = back, length = body.length * scale, overlap = body.overlap or 0 }
			end
			local riderCtx = { effect = fields, palette = opts.palette, height = ref, move = scale, continuous = false }
			for _, rider in projectile.riders or {} do
				if Quality.secondary() or not rider.secondary then
					local riderSpec = specOf(rider, scale, nil)
					local riderEmitter = makeEmitter(rider, riderSpec, riderCtx)
					riderEmitter.Parent = flight
					table.insert(live.emitters, riderEmitter)
					live.longest = math.max(live.longest, riderSpec.life[2])
					for _, shot in riderSpec.bursts or {} do
						local n = shot[2]
						table.insert(live.events, {
							at = wait + shot[1],
							run = function()
								local count = Quality.count(n)
								if count > 0 then
									Builder.engine.emit(riderEmitter, count)
								end
							end,
						})
					end
					if rider.stream then
						table.insert(live.streams, {
							emitter = riderEmitter,
							from = wait + rider.stream.from,
							to = wait + rider.stream.to,
							rates = rider.stream.rate,
							burst = rider.stream.burst,
							ease = rider.stream.ease,
						})
					end
					riderCount += 1
				end
			end
			local band = projectile.trail
			if band then
				local half = (band.width or 1) * scale / 2
				-- (behind the head, when there is one: the ribbon of scales or flames starts where the picture ends)
				local top = newAttachment(flight, "TrailTop", Vector3.new(0, half, back))
				local bottom = newAttachment(flight, "TrailBottom", Vector3.new(0, -half, back))
				local trail = Instance.new("Trail")
				trail.Name = "Trail"
				trail.Attachment0 = top
				trail.Attachment1 = bottom
				trail.Texture = Textures.url(band.texture)
				trail.TextureMode = Enum.TextureMode.Stretch
				trail.FaceCamera = true
				trail.Lifetime = band.life or 0.3
				trail.LightInfluence = 0
				trail.LightEmission = 1
				trail.Brightness = band.glow or 1
				trail.Color = Palette.sequence(band.colors or Palette.resolve(fields, band, opts.palette))
					or ColorSequence.new(Color3.new(1, 1, 1))
				trail.Transparency = NumberSequence.new(band.alpha or 0, 1)
				trail.WidthScale = NumberSequence.new(1, band.taper or 0.2)
				trail.Parent = flight
				live.flight.trail = trail
			end
		end
	end

	local specs = {}
	for _, piece in fields.pieces or {} do
		if #specs + riderCount >= kindBudget.emitters then
			break
		end
		if Quality.secondary() or not piece.secondary then
			table.insert(specs, specOf(piece, scale, grade))
		end
	end
	Budget.limit(specs, kindBudget)
	local ctx = {
		effect = fields,
		palette = opts.palette,
		height = size.Y,
		move = scale,
		angle = opts.angle,
		grade = grade,
		continuous = false,
	}
	local last = delay
	for _, spec in specs do
		local piece = spec.piece
		local emitter = makeEmitter(piece, spec, ctx)
		local parent = emitterParent(piece)
		if piece.upright == "in" and parent:IsA("Attachment") then
			-- (standing facing the play's middle from where it is, level: a portal turned to the target)
			local position = parent.CFrame.Position
			local inward = Vector3.new(-position.X, 0, -position.Z)
			if inward.Magnitude > 1e-3 then
				parent.CFrame = CFrame.lookAt(position, position + inward)
			end
		end
		emitter.Parent = parent
		table.insert(live.emitters, emitter)
		live.longest = math.max(live.longest, spec.life[2])
		if piece.spin and parent:IsA("BasePart") then
			-- (its part turns about its up axis: the particles locked to it swirl, a pull spirals into the middle)
			table.insert(live.spins, { part = parent, base = parent.CFrame, rps = piece.spin })
		end
		if piece.onLand then
			-- (born where a falling beam lands, each time one does: moved there, then emitted)
			emitter.Parent = newAttachment(anchor, "Land_" .. piece.name, Vector3.zero)
			live.landers[piece.name] = { emitter = emitter, count = piece.count or 1 }
			last = math.max(last, delay + spec.life[2])
			continue
		end
		-- (a `cast` piece counts from the cast, not the impact: the warning circle grows before the meteor lands)
		local base = if piece.cast then 0 else delay
		for _, shot in spec.bursts or {} do
			local n = shot[2]
			table.insert(live.events, {
				at = base + shot[1],
				run = function()
					local count = Quality.count(n)
					if count > 0 then
						Builder.engine.emit(emitter, count)
					end
				end,
			})
			last = math.max(last, base + shot[1] + spec.life[2])
		end
		local stream = piece.stream
		if stream then
			table.insert(live.streams, {
				emitter = emitter,
				from = base + stream.from,
				to = base + stream.to,
				rates = stream.rate,
				burst = stream.burst,
				ease = stream.ease,
			})
			last = math.max(last, base + stream.to + spec.life[2])
		end
	end

	local beamCtx = {
		effect = fields,
		palette = opts.palette,
		scale = scale,
		angle = opts.angle,
		delay = delay,
		cframe = cframe,
		source = opts.from,
		caster = casterLocal,
		along = alongFrame,
	}
	for index, beam in fields.beams or {} do
		if index > (kindBudget.beams or 0) then
			break
		end
		if Quality.secondary() or not beam.secondary then
			local entry = makeBeam(live, beam, index, beamCtx)
			table.insert(live.beams, entry)
			for _, rider in live.riding do
				if rider.beam == beam.name then
					rider.entry = entry
				end
			end
			last = math.max(last, entry.from + entry.life)
		end
	end

	local light = fields.light
	if light then
		local point = Instance.new("PointLight")
		point.Color = Palette.color3(colorOf(fields, light, opts.palette))
		point.Range = math.clamp((light.range or 10) * scale, 4, kindBudget.light or 24)
		point.Brightness = 0
		point.Shadows = false
		point.Enabled = Quality.lights(1) > 0
		point.Parent = anchor
		local keys = {}
		for index, key in light.keys or { { 0, light.brightness or 1 }, { 0.4, 0 } } do
			keys[index] = { delay + key[1], key[2] }
		end
		table.insert(live.lights, { light = point, keys = keys })
		last = math.max(last, keys[#keys][1])
	end

	local outline = fields.highlight
	if outline and opts.adornees then
		for index, adornee in opts.adornees do
			if index > (outline.max or 6) then
				break
			end
			local highlight = Instance.new("Highlight")
			highlight.Name = "VfxOutline"
			highlight.Adornee = adornee
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.FillColor =
				Palette.color3(Palette.first(Palette.resolve(fields, { role = outline.fill }, opts.palette)))
			highlight.OutlineColor =
				Palette.color3(Palette.first(Palette.resolve(fields, { role = outline.outline }, opts.palette)))
			highlight.FillTransparency = outline.fillTransparency or 0.75
			highlight.OutlineTransparency = outline.outlineTransparency or 0.1
			highlight.Parent = folder
			table.insert(live.outlines, {
				highlight = highlight,
				from = highlight.FillTransparency,
				outlineFrom = highlight.OutlineTransparency,
				seconds = outline.seconds or 2,
			})
		end
		last = math.max(last, outline.seconds or 2)
	end

	table.sort(live.events, function(a, b)
		return a.at < b.at
	end)
	live.duration = fields.duration or (last + 0.2)
	live.next = 1
	if follow then
		-- (held by the host instead of the world: welded, so it rides every move and turn)
		for _, part in folder:GetChildren() do
			if part:IsA("BasePart") then
				part.Anchored = false
				weld(root, part)
			end
		end
	end
	folder.Parent = playFolder(opts.parent)
	Builder.step(live, 0)
	return live
end

-- Advances a one-shot by `dt` seconds (times Builder.timeScale). Returns false once it is over and cleaned up.
function Builder.step(live, dt)
	if live.dead then
		return false
	end
	live.t += dt * Builder.timeScale
	local t = live.t
	while live.next <= #live.events and live.events[live.next].at <= t do
		live.events[live.next].run()
		live.next += 1
	end
	local flight = live.flight
	if flight and not flight.done then
		-- (the riders' part on the projectile's own arc, or along its path, turned along it, until it lands)
		local s = math.clamp(t - flight.wait, 0, flight.seconds)
		if flight.ease == "in" then
			s = flight.seconds * (s / flight.seconds) ^ 2 -- (it falls slowly, then fast)
		end
		local position, velocity
		if flight.path then
			position, velocity = pathAt(flight.path, s / flight.seconds)
		else
			local fall = Vector3.new(0, -flight.gravity, 0)
			position = flight.from + flight.velocity * s + fall * (0.5 * s * s)
			velocity = flight.velocity + fall * s
		end
		if velocity.Magnitude > 1e-4 then
			flight.part.CFrame = CFrame.lookAt(position, position + velocity)
		end
		local flying = t >= flight.wait and not live.cancelled
		if flight.head and flight.head.Enabled ~= flying then
			flight.head.Enabled = flying
		end
		if flight.trail and flight.trail.Enabled ~= flying then
			flight.trail.Enabled = flying
		end
		local spine = flight.body
		if spine then
			-- (the body on the path already flown: its neck just behind the head, its tail `length` studs farther
			-- back, each slice's curve fitted to the path's headings at its ends; the slices not yet out are hidden,
			-- the one coming out shorter)
			local total = flight.path.total
			local p = s / flight.seconds
			local slice = spine.length / #spine.beams / total
			local airborne = flying and t < flight.wait + flight.seconds
			for index, beam in spine.beams do
				local front = math.clamp(p - spine.back / total - slice * (index - 1 - spine.overlap), 0, 1)
				local tail = math.clamp(p - spine.back / total - slice * (index + spine.overlap), 0, 1)
				local shown = airborne and front - tail > 1e-3
				if shown then
					local a, ta = pathAt(flight.path, front)
					local b, tb = pathAt(flight.path, tail)
					beam.Attachment0.CFrame = axisFrame(a, -ta)
					beam.Attachment1.CFrame = axisFrame(b, -tb)
					local reach = (front - tail) * total / 3
					beam.CurveSize0 = reach
					beam.CurveSize1 = reach
				end
				if beam.Enabled ~= shown then
					beam.Enabled = shown
				end
			end
		end
		if t >= flight.wait + flight.seconds or live.cancelled then
			flight.done = true
			if flight.trail then
				flight.trail.Enabled = false
			end
			if flight.head then
				flight.head.Enabled = false
			end
		end
	end
	for _, spin in live.spins do
		spin.part.CFrame = spin.base * CFrame.Angles(0, t * spin.rps * 2 * math.pi, 0)
	end
	for _, stream in live.streams do
		local on = t >= stream.from and t < stream.to
		local rate = 0
		if on then
			local p = (t - stream.from) / math.max(stream.to - stream.from, 1e-3)
			if stream.ease == "in" then
				p *= p -- (it gathers slowly, then pours)
			end
			rate = Quality.rate(lerp(stream.rates[1], stream.rates[2] or stream.rates[1], p))
		end
		if t >= stream.to and not stream.ended then
			stream.ended = true
			if stream.burst then
				Builder.engine.emit(stream.emitter, Quality.count(stream.burst))
			end
		end
		rate = math.floor(rate * Builder.Grain + 0.5) / Builder.Grain
		if stream.emitter.Rate ~= rate then
			stream.emitter.Rate = rate
		end
		stream.emitter.Enabled = rate > 0
	end
	for _, entry in live.beams do
		stepBeam(live, entry, t)
	end
	for _, rider in live.riding do
		-- (a piece riding a rolling beam: on its middle, turned as it; left where it is when its beam was not made)
		if rider.entry then
			rider.part.CFrame = live.anchor.CFrame * CFrame.new(rider.entry.middle) * rider.entry.facing * rider.offset
		end
	end
	for _, entry in live.lights do
		entry.light.Brightness = keyAt(entry.keys, t)
	end
	for _, entry in live.outlines do
		local p = math.clamp(t / entry.seconds, 0, 1)
		local eased = 1 - (1 - p) * (1 - p)
		entry.highlight.FillTransparency = lerp(entry.from, 1, eased)
		entry.highlight.OutlineTransparency = lerp(entry.outlineFrom, 1, eased)
	end
	if t >= live.duration then
		Builder.stop(live)
		return false
	end
	return true
end

function Builder.stop(live)
	live.dead = true
	live.folder:Destroy()
end

-- Ends a one-shot SOFTLY (the attack was interrupted: a stun, a death, a cancel): nothing more is born, its beams and
-- light fade out over `fade` seconds, the particles in the air live out their lives (a second at most), then it is
-- cleaned up as usual. Never a pop, never anything left behind.
function Builder.cancel(live, fade)
	if live.dead or live.cancelled then
		return
	end
	fade = fade or 0.15
	local t = live.t
	live.cancelled = t
	live.fade = fade
	live.next = #live.events + 1 -- (the bursts still to come never come)
	for _, stream in live.streams do
		stream.to = math.min(stream.to, t)
		stream.burst = nil
	end
	for _, entry in live.lights do
		entry.keys = { { t, entry.light.Brightness }, { t + fade, 0 } }
	end
	live.duration = math.min(live.duration, t + math.max(fade, math.min(live.longest, 1)) + 0.05)
end

-- Every emitter of a handle or a one-shot to TimeScale `value` (0 freezes them for a picture).
function Builder.setTimeScale(thing, value)
	for _, item in thing.folder:GetDescendants() do
		if item:IsA("ParticleEmitter") then
			item.TimeScale = value
		end
	end
end

-- What a built lasting effect costs now (at a full run): { emitters, rate, alive, area, bands, light }.
function Builder.measure(handle)
	-- (the wings' beams are one flat quad each: counted, not added to the particles' area)
	local measured = {
		emitters = #handle.items,
		rate = 0,
		alive = 0,
		area = 0,
		bands = #handle.bands,
		wings = #handle.wings,
		parts = 0,
	}
	for _, entry in handle.wings do
		measured.parts += #entry.parts
	end
	for _, item in handle.items do
		local spec = item.spec
		measured.rate += spec.rate
		measured.alive += spec.rate * Budget.meanLife(spec)
		measured.area += Budget.area(spec)
	end
	measured.light = handle.light ~= nil
	return measured
end

return Builder
