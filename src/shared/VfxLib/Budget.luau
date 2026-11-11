-- What an effect may cost, and the cut that holds it there (Egg Heist's PetVfx.limit / TrailBuilder's limit, merged).
--
-- WHAT COSTS IS THE AREA PAINTED. A transparent billboard costs the same to draw as a solid one, and the camera standing
-- inside the effect is what makes dozens of them fill a phone's screen: so what is held is the summed area of the
-- particles in the air (rate x life x the mean of their side squared over a life), as well as their number (a second, in
-- the air) and their size. A burst is held by its particles and the area they paint at their peak (count x side squared).
-- The cut keeps the look's proportions: every size is shrunk together, never below MinShrink, and the rest is done with
-- fewer particles.
--
-- Everything here works on SPECS, plain tables of a piece's numbers once scaled to its host (Builder makes them, the
-- tests and the catalog read the data the same way), never on Instances:
--   { size = { { t, v, e? } }, life = { min, max }, rate = n?, count = n? }
local Models = require(if script then script.Parent.Models else "./Models")

local Budget = {}

Budget.MinShrink = 0.5 -- sizes are cut by no more than this to meet an area; the rest is done with fewer particles
Budget.SpreadRate = 3 -- a giant's particles a second may pass the rate this many times (they stay small)

-- The hard caps of a host, by kind of effect. `light` is the reach of a light in studs (0: none).
Budget.Kinds = {
	-- (an aura's side reaches 10: a Level 2 aura's own floor circle is 8-10 studs, cheap as it is few and flat; the area
	-- still holds the whole, 2026-11-07; `swimmers`: small 3D fish going round it, one skinned MeshPart each)
	aura = { emitters = 6, rate = 40, alive = 80, size = 10, area = 900, light = 32, lights = 1, swimmers = 6 },
	trail = {
		emitters = 7,
		rate = 80,
		alive = 90,
		size = 3.5,
		area = 240,
		life = 2.5,
		bands = 3,
		bandLife = 1.8,
		bandLength = 70,
		light = 16,
		lights = 1,
	},
	buff = { emitters = 3, rate = 20, alive = 40, size = 2.5, area = 80, light = 0, lights = 0 },
	-- (`wings`: the wings' flat beams, two a pair; `span`: the longest a wing or its width may be, studs at refHeight;
	-- `parts`: a mechanical wing's other flat quads, its blades and gears, both sides counted)
	wings = {
		emitters = 6,
		rate = 40,
		alive = 80,
		size = 4,
		area = 400,
		light = 12,
		lights = 1,
		wings = 4,
		span = 5,
		parts = 8,
	},
	world = { emitters = 8, rate = 80, alive = 160, size = 10, area = 1500, light = 24, lights = 1 },
	-- (`beams`: the Beams of a one-shot, slashes and bolts: one ribbon each, cheap to draw but wide on screen)
	hit = { emitters = 5, count = 40, size = 7, burstArea = 700, light = 12, lights = 1, beams = 3 },
	burst = { emitters = 6, count = 90, size = 12, burstArea = 1600, light = 24, lights = 1, beams = 3 },
	reveal = { emitters = 12, count = 280, size = 16, burstArea = 3200, light = 24, lights = 1, beams = 2 },
	-- (a skill's beams up to 16: a rain or a volley of swords is one flat quad each; their area still counts)
	skill = { emitters = 12, count = 220, size = 20, burstArea = 4000, light = 24, lights = 1, beams = 16 },
}

-- A SHOWCASE: the caps of a kind's `heavy` effects, the ones a player looks at (their own aura, a boss's, a shop's
-- preview). Lod gives every layer to the nearest Lod.MaxShowcase of them only; the others run at half. Its numbers are
-- TerKungTH's ground aura brought down to a phone (docs/vfx/references/terkungth-ground-aura.md): layers as wide as
-- three bodies, a dozen of them.
Budget.Showcase = {
	-- (`serpents`: a dragon coiling round the host, one long picture on one Trail or one 3D body)
	aura = {
		emitters = 12,
		rate = 160,
		alive = 240,
		size = 20,
		area = 6000,
		light = 32,
		lights = 1,
		serpents = 1,
		swimmers = 6,
	},
	-- (a showcase pair spreads as wide as two bodies and wears a second pair, a glow and riders off its feathers)
	wings = {
		emitters = 10,
		rate = 120,
		alive = 200,
		size = 8,
		area = 3000,
		light = 24,
		lights = 1,
		wings = 8,
		span = 8,
		-- (a machine's blades and gears: one flat quad each, as cheap as a wing's beam; the area counts them)
		parts = 16,
	},
}

-- The caps an effect of `kind` promising `tier` is held to.
function Budget.kindRow(kind, tier)
	return (tier == "heavy" and Budget.Showcase[kind]) or Budget.Kinds[kind]
end

-- Kinds that last (attached to a host) and kinds that play once.
Budget.Continuous = { aura = true, trail = true, buff = true, wings = true, world = true }

-- The cost tiers an effect declares (`tier`) and the tests hold it to. Phone first: a cheap effect can be on every host.
Budget.Tiers = {
	continuous = {
		cheap = { emitters = 2, rate = 20, lights = 0, area = 150, bands = 1, wings = 2, parts = 0 },
		mid = { emitters = 8, rate = 80, lights = 1, area = 900, bands = 3, wings = 4, parts = 8 },
		heavy = { emitters = 30, rate = 260, lights = 2, area = 6000, bands = 7, wings = 8, parts = 16 },
	},
	oneShot = {
		cheap = { emitters = 3, count = 40, lights = 0, burstArea = 400, beams = 1 },
		mid = { emitters = 8, count = 160, lights = 1, burstArea = 2500, beams = 4 },
		heavy = { emitters = 14, count = 400, lights = 2, burstArea = 8000, beams = 16 },
	},
}
Budget.TierOrder = { "cheap", "mid", "heavy" }

-- The value of keypoints { { t, v, e? } } at t.
function Budget.valueAt(points, t)
	local before = points[1]
	for index = 2, #points do
		local after = points[index]
		if t <= after[1] then
			local span = after[1] - before[1]
			local f = if span > 0 then (t - before[1]) / span else 1
			return before[2] + (after[2] - before[2]) * f
		end
		before = after
	end
	return before[2]
end

-- The biggest side over a life, spread included.
function Budget.peak(points)
	local top = 0
	for _, point in points do
		top = math.max(top, point[2] + (point[3] or 0))
	end
	return top
end

function Budget.meanLife(spec)
	return (spec.life[1] + spec.life[2]) / 2
end

-- The mean of the side squared over a life.
function Budget.meanSquare(points)
	local sum, steps = 0, 12
	for index = 0, steps do
		local side = Budget.valueAt(points, index / steps)
		sum += side * side
	end
	return sum / (steps + 1)
end

-- The area a continuous spec keeps in the air (square studs).
function Budget.area(spec)
	return (spec.rate or 0) * Budget.meanLife(spec) * Budget.meanSquare(spec.size)
end

-- The area a burst spec paints at its peak.
function Budget.burstArea(spec)
	local side = Budget.peak(spec.size)
	return (spec.count or 0) * side * side
end

function Budget.scaleSize(spec, k)
	local points = {}
	for index, point in spec.size do
		points[index] = { point[1], point[2] * k, (point[3] or 0) * k }
	end
	spec.size = points
end

local function sum(specs, field)
	local total = 0
	for _, spec in specs do
		total += spec[field] or 0
	end
	return total
end

local function totalArea(specs)
	local total = 0
	for _, spec in specs do
		if spec.rate then
			total += Budget.area(spec)
		end
	end
	return total
end

local function totalBurstArea(specs)
	local total = 0
	for _, spec in specs do
		if spec.count then
			total += Budget.burstArea(spec)
		end
	end
	return total
end

-- Holds a list of specs to the budget `b` (a row of Budget.Kinds). `spread` > 1 (a giant host) asks for more particles,
-- as far as the area, the particles in the air and the rate allow. Changes the specs; returns them.
function Budget.limit(specs, b, spread)
	for _, spec in specs do
		local top = Budget.peak(spec.size)
		if b.size and top > b.size then
			Budget.scaleSize(spec, b.size / top)
		end
		if b.life and spec.life[2] > b.life then
			spec.life = { math.min(spec.life[1], b.life), b.life }
		end
	end

	-- the continuous ones
	local streams = {}
	for _, spec in specs do
		if spec.rate then
			table.insert(streams, spec)
		end
	end
	local function cutRates(factor)
		for _, spec in streams do
			spec.rate *= factor
		end
	end
	if #streams > 0 then
		local rate = sum(streams, "rate")
		if b.rate and rate > b.rate then
			cutRates(b.rate / rate)
		end
		local alive = 0
		for _, spec in streams do
			alive += spec.rate * Budget.meanLife(spec)
		end
		if b.alive and alive > b.alive then
			cutRates(b.alive / alive)
		end
		local area = totalArea(streams)
		if b.area and area > b.area then
			local cut = math.max(math.sqrt(b.area / area), Budget.MinShrink)
			for _, spec in streams do
				Budget.scaleSize(spec, cut)
			end
			area = totalArea(streams)
			if area > b.area then
				cutRates(b.area / area)
				area = b.area
			end
		end
		if spread and spread > 1 then
			rate = sum(streams, "rate")
			alive = 0
			for _, spec in streams do
				alive += spec.rate * Budget.meanLife(spec)
			end
			local more = spread
			if b.area then
				more = math.min(more, b.area / math.max(area, 0.001))
			end
			if b.alive then
				more = math.min(more, b.alive / math.max(alive, 0.001))
			end
			if b.rate then
				more = math.min(more, b.rate * Budget.SpreadRate / math.max(rate, 0.001))
			end
			if more > 1 then
				cutRates(more)
			end
		end
	end

	-- the bursts
	local bursts = {}
	for _, spec in specs do
		if spec.count then
			table.insert(bursts, spec)
		end
	end
	if #bursts > 0 then
		local area = totalBurstArea(bursts)
		if b.burstArea and area > b.burstArea then
			local cut = math.max(math.sqrt(b.burstArea / area), Budget.MinShrink)
			for _, spec in bursts do
				Budget.scaleSize(spec, cut)
			end
			area = totalBurstArea(bursts)
		end
		local factor = 1
		if b.burstArea and area > b.burstArea then
			factor = math.min(factor, b.burstArea / area)
		end
		local count = sum(bursts, "count")
		if b.count and count > b.count then
			factor = math.min(factor, b.count / count)
		end
		if factor < 1 then
			for _, spec in bursts do
				spec.count = math.max(math.floor(spec.count * factor), 1)
				if spec.bursts then
					for _, shot in spec.bursts do
						shot[2] = math.max(math.floor(shot[2] * factor), 1)
					end
				end
			end
		end
	end
	return specs
end

-- What a piece of DATA costs at its authored size: { rate, alive, area, count, burstArea }. A `stream` of a one-shot
-- (a rate for a while) counts as the particles it gives.
function Budget.pieceCost(piece)
	local cost = { rate = 0, alive = 0, area = 0, count = 0, burstArea = 0 }
	local size = piece.size or { { 0, 1 }, { 1, 1 } }
	local life = piece.life or { 1, 1 }
	local meanLife = (life[1] + life[2]) / 2
	if piece.rate then
		cost.rate = piece.rate
		cost.alive = piece.rate * meanLife
		cost.area = cost.alive * Budget.meanSquare(size)
	end
	local count = piece.count or 0
	for _, shot in piece.bursts or {} do
		count += shot[2]
	end
	if piece.stream then
		local stream = piece.stream
		local rates = stream.rate
		count += (rates[1] + (rates[2] or rates[1])) / 2 * (stream.to - stream.from) + (stream.burst or 0)
	end
	cost.count = count
	local side = Budget.peak(size)
	cost.burstArea = count * side * side
	return cost
end

-- The numbers of a piece as a spec Budget.limit can cut (a copy: the data is never changed).
local function specOfPiece(piece)
	local size = {}
	for index, point in piece.size or { { 0, 1 }, { 1, 1 } } do
		size[index] = { point[1], point[2], point[3] or 0 }
	end
	local life = piece.life or { 1, 1 }
	local spec = { size = size, life = { life[1], life[2] or life[1] }, rate = piece.rate }
	local count = Budget.pieceCost(piece).count
	if count > 0 then
		spec.count = count
	end
	return spec
end

-- What an effect of DATA costs as it is built at its authored size (its pieces held to the kind's budget, as the
-- builder holds them), its worst variant: { emitters, rate, alive, area, count, burstArea, lights, bands }.
function Budget.measure(effect, variantOf)
	local function one(fields)
		local total = {
			emitters = 0,
			rate = 0,
			alive = 0,
			area = 0,
			count = 0,
			burstArea = 0,
			lights = 0,
			bands = 0,
			beams = 0,
			wings = 0,
			parts = 0,
		}
		local specs = {}
		-- (a piece born where falling beams land: its count each time one lands)
		local landed = {}
		local byName = {}
		for _, piece in fields.pieces or {} do
			byName[piece.name] = piece
		end
		for _, beam in fields.beams or {} do
			local piece = beam.land and byName[beam.land]
			if piece then
				landed[piece.name] = (landed[piece.name] or 0) + (beam.landCount or piece.count or 1)
			end
		end
		for _, piece in fields.pieces or {} do
			local spec = specOfPiece(piece)
			if piece.onLand then
				spec.count = landed[piece.name] or 0
			end
			table.insert(specs, spec)
			if piece.wing then
				table.insert(specs, specOfPiece(piece)) -- (a rider is on both wings)
			end
		end
		-- (what rides a projectile: emitters of the effect like any other)
		for _, rider in (fields.projectile and fields.projectile.riders) or {} do
			table.insert(specs, specOfPiece(rider))
		end
		local b = Budget.kindRow(fields.kind, fields.tier)
		if b then
			Budget.limit(specs, b)
		end
		for _, spec in specs do
			total.emitters += 1
			local cost = Budget.pieceCost(spec)
			for key, value in cost do
				total[key] += value
			end
		end
		local head = fields.projectile and fields.projectile.head
		local body = fields.projectile and fields.projectile.body
		local slices = if body then #(body.textures or { body.texture }) else 0
		if head then
			-- (a head is a beam lying along the flight: its picture's area, once; counted with the beams below)
			total.burstArea += head.length * head.width
		end
		if body then
			-- (a serpent's body: curved beams, one a slice, its length times its width in all)
			total.burstArea += body.length * body.width
		end
		if fields.projectile and not head and not body then
			total.emitters += 1
			total.count += 1
		end
		total.beams = (if head then 1 else 0) + slices
		for _, beam in fields.beams or {} do
			-- (a beam paints its length times its width at its widest, once: added to the burst's area)
			total.beams += 1
			local from, to = beam.from, beam.to
			local length = math.sqrt((to[1] - from[1]) ^ 2 + (to[2] - from[2]) ^ 2 + (to[3] - from[3]) ^ 2)
			local width = beam.width or { 1, 1 }
			local grow = if beam.grow then Budget.peak(beam.grow) else 1
			total.burstArea += length * (width[1] + (width[2] or width[1])) / 2 * grow
			local streak = beam.strike and beam.strike.trail
			if streak then
				-- (a striking beam's ribbon: its width along the flight it draws in its life, as a projectile's)
				total.burstArea += streak.width * 20 * streak.life
			end
		end
		local band = fields.projectile and fields.projectile.trail
		if band then
			-- (a projectile's ribbon: a beam's worth, its width along the flight it draws in its life)
			total.beams += 1
			total.burstArea += band.width * 20 * band.life
		end
		for _, wing in fields.wings or {} do
			-- (a pair of flat beams: the picture's area painted once on each side)
			total.wings += 2
			total.area += 2 * wing.length * wing.width
			-- (a mechanical wing's other blades and its gears: a quad each side)
			local blades = if wing.blades then wing.blades.count - 1 else 0
			total.parts += 2 * blades
			total.area += 2 * blades * wing.length * wing.width
			for _, gear in wing.gears or {} do
				total.parts += 2
				total.area += 2 * gear.size * gear.size
			end
			if wing.scan then
				-- (a scan: a lit copy of the wing on its own beam, a quad each side, the whole wing's size)
				total.parts += 2
				total.area += 2 * wing.length * wing.width
			end
		end
		for _, serpent in fields.serpents or {} do
			-- (a serpent: one Trail, its picture's area painted once; or one skinned MeshPart, its model's area)
			total.parts += 1
			total.area += if serpent.model
				then Models.list[serpent.model].area * (serpent.size or 1) ^ 2
				else serpent.length * serpent.width
		end
		for _, swimmer in fields.swimmers or {} do
			-- (a fish: one skinned MeshPart about half as tall as it is long)
			total.parts += 1
			total.area += swimmer.length * swimmer.length / 2
		end
		total.bands = #(fields.bands or {})
		total.lights = if fields.light then 1 else 0
		return total
	end
	local worst = one(effect)
	for name in effect.variants or {} do
		local measured = one(variantOf(effect, name))
		for key, value in measured do
			worst[key] = math.max(worst[key], value)
		end
	end
	return worst
end

-- The cheapest tier a measure fits, and nil when it fits none.
function Budget.tierOf(kind, measured)
	local rows = if Budget.Continuous[kind] then Budget.Tiers.continuous else Budget.Tiers.oneShot
	for _, name in Budget.TierOrder do
		local row = rows[name]
		local fits = true
		for key, limit in row do
			if (measured[key] or 0) > limit + 1e-6 then
				fits = false
				break
			end
		end
		if fits then
			return name
		end
	end
	return nil
end

return Budget
