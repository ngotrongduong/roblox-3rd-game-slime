-- Colours of an effect. A piece is coloured by a ROLE of its effect's palette (core, accent, spark, or any name the
-- effect gives), by colours of its own, or not at all ("keep": its picture's own colours, the rule for the owner's art).
-- A palette entry, like a piece's own `color`, is one of
--   { r, g, b }                       one colour
--   { { r, g, b }, { r, g, b }, ... } a gradient over a particle's life, evenly spaced
--   { { t, { r, g, b } }, ... }       a gradient with its own times (what the baker writes)
--   "rainbow"                         the rainbow below
-- A game recolours a tintable effect by handing its own palette (`opts.palette = { core = {...} }`).
local Palette = {}

Palette.Rainbow = {
	{ 255, 90, 95 },
	{ 255, 201, 60 },
	{ 61, 220, 132 },
	{ 63, 169, 245 },
	{ 155, 93, 229 },
	{ 255, 90, 95 },
}

function Palette.color3(triple)
	return Color3.fromRGB(
		math.clamp(math.floor(triple[1] + 0.5), 0, 255),
		math.clamp(math.floor(triple[2] + 0.5), 0, 255),
		math.clamp(math.floor(triple[3] + 0.5), 0, 255)
	)
end

local function isTriple(value)
	return type(value) == "table" and type(value[1]) == "number" and #value == 3
end

-- The keyframes { { t, triple } } of a colour spec, nil for nil / "keep".
function Palette.stops(spec)
	if spec == nil or spec == "keep" then
		return nil
	end
	if spec == "rainbow" then
		spec = Palette.Rainbow
	end
	if isTriple(spec) then
		return { { 0, spec }, { 1, spec } }
	end
	local first = spec[1]
	if type(first) == "table" and type(first[1]) == "number" and isTriple(first[2]) then
		return spec
	end
	local stops = {}
	for index, triple in spec do
		stops[index] = { if #spec == 1 then 0 else (index - 1) / (#spec - 1), triple }
	end
	if #stops == 1 then
		stops[2] = { 1, stops[1][2] }
	end
	return stops
end

function Palette.sequence(spec)
	local stops = Palette.stops(spec)
	if not stops then
		return nil
	end
	local keys = {}
	for index, stop in stops do
		keys[index] = ColorSequenceKeypoint.new(stop[1], Palette.color3(stop[2]))
	end
	return ColorSequence.new(keys)
end

-- The part `from`..`to` (0 to 1) of a spec's sequence, stretched over 0..1 (a piece of something drawn in pieces), nil
-- for nil / "keep".
function Palette.span(spec, from, to)
	local stops = Palette.stops(spec)
	if not stops then
		return nil
	end
	local function at(x)
		for index = 2, #stops do
			local a, b = stops[index - 1], stops[index]
			if x <= b[1] or index == #stops then
				local mix = math.clamp((x - a[1]) / math.max(b[1] - a[1], 1e-6), 0, 1)
				return {
					a[2][1] + (b[2][1] - a[2][1]) * mix,
					a[2][2] + (b[2][2] - a[2][2]) * mix,
					a[2][3] + (b[2][3] - a[2][3]) * mix,
				}
			end
		end
		return stops[1][2]
	end
	local keys = { ColorSequenceKeypoint.new(0, Palette.color3(at(from))) }
	for _, stop in stops do
		if stop[1] > from and stop[1] < to then
			table.insert(keys, ColorSequenceKeypoint.new((stop[1] - from) / (to - from), Palette.color3(stop[2])))
		end
	end
	table.insert(keys, ColorSequenceKeypoint.new(1, Palette.color3(at(to))))
	return ColorSequence.new(keys)
end

-- The first colour of a spec as a triple (a light's colour), white when none.
function Palette.first(spec)
	local stops = Palette.stops(spec)
	return if stops then stops[1][2] else { 255, 255, 255 }
end

-- The colour spec a piece is drawn in: its own `color`, else its `role` in the palette (the game's over the effect's),
-- nil to keep the picture's colours.
function Palette.resolve(effect, piece, given)
	if piece.color ~= nil then
		return piece.color
	end
	local role = piece.role
	if role == nil or role == "keep" then
		return nil
	end
	if given and given[role] ~= nil and effect.tintable ~= false then
		return given[role]
	end
	return effect.palette and effect.palette[role]
end

-- `c` lightened toward white by `share` (0 to 1), as a triple.
function Palette.lighten(triple, share)
	return {
		triple[1] + (255 - triple[1]) * share,
		triple[2] + (255 - triple[2]) * share,
		triple[3] + (255 - triple[3]) * share,
	}
end

-- A colour that runs round a loop of triples (`position` 0 to 1).
function Palette.loop(colors, position)
	local count = #colors
	local at = (position % 1) * count
	local first = math.floor(at)
	local mix = at - first
	local a = colors[first % count + 1]
	local b = colors[(first + 1) % count + 1]
	return { a[1] + (b[1] - a[1]) * mix, a[2] + (b[2] - a[2]) * mix, a[3] + (b[3] - a[3]) * mix }
end

return Palette
