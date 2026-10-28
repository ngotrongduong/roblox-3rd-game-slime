--!strict
-- The 55 Dual designs (docs/DUALS.md): every pair of the 11 base colours has exactly one two-colour
-- design a baby can show on top of its base colour. It replaces the original's 20 designs on 18 pairs
-- and its fallback pool (docs/reference/01-core-farm.md §5.5): a Dual of A + B is always A + B's design.

local Colours = if script then require(script.Parent.Colours) else require("./Colours")

local DualDesigns = {}

export type Design = {
	id: string,
	number: string,
	name: string,
	-- The skin file is art/models/slime_body/skins/<skin>.png.
	skin: string,
	parentPair: { string },
	pattern: string,
	-- Which of the two colours is the body, and which draws the pattern.
	bodyColour: string,
	patternColour: string,
	assetId: string,
	enabled: boolean,
	weight: number,
}

-- { number, colour a, colour b, name, pattern, body colour } in the doc's order. The pattern colour is
-- the other one of the pair.
local PLAN: { { string } } = {
	{ "01", "black", "gray", "Pinstripe", "thin vertical stripes", "black" },
	{ "02", "black", "navy", "Midnight Fade", "fade, navy below to black on top", "navy" },
	{ "03", "black", "purple", "Batwing", "little bats", "purple" },
	{ "04", "black", "red", "Ladybug", "round spots and a black tip", "red" },
	{ "05", "black", "orange", "Tiger", "tiger stripes", "orange" },
	{ "06", "black", "yellow", "Honeycomb", "hexagon outlines", "yellow" },
	{ "07", "black", "green", "Dragonscale", "scale outlines", "green" },
	{ "08", "black", "pink", "Wild Rosette", "leopard rosettes", "pink" },
	{ "09", "black", "blue", "Neon Swirl", "spirals", "black" },
	{ "10", "black", "white", "Moo", "cow spots", "white" },
	{ "11", "gray", "navy", "Drizzle", "raindrops", "gray" },
	{ "12", "gray", "purple", "Geode", "crystal shards", "gray" },
	{ "13", "gray", "red", "Brickwork", "bricks", "red" },
	{ "14", "gray", "orange", "Lava Crack", "glowing cracks", "gray" },
	{ "15", "gray", "yellow", "Clockwork", "gears", "gray" },
	{ "16", "gray", "green", "Camo", "camouflage blobs", "green" },
	{ "17", "gray", "pink", "Sprinkle", "sprinkles", "gray" },
	{ "18", "gray", "blue", "Overcast", "clouds", "blue" },
	{ "19", "gray", "white", "Marble", "marble veins", "white" },
	{ "20", "navy", "purple", "Nebula", "nebula swirls and tiny stars", "navy" },
	{ "21", "navy", "red", "Tartan", "tartan", "red" },
	{ "22", "navy", "orange", "Peach Drip", "drip from the top", "navy" },
	{ "23", "navy", "yellow", "Firefly", "glowing dots", "navy" },
	{ "24", "navy", "green", "Forestpeak", "triangles", "green" },
	{ "25", "navy", "pink", "Sakura", "cherry blossoms", "navy" },
	{ "26", "navy", "blue", "Deepsea", "horizontal stripes", "navy" },
	{ "27", "navy", "white", "Snowflake", "snowflakes", "navy" },
	{ "28", "purple", "red", "Berrypatch", "berry clusters", "purple" },
	{ "29", "purple", "orange", "Pumpkin Patch", "little pumpkins", "purple" },
	{ "30", "purple", "yellow", "Crowned", "little crowns", "purple" },
	{ "31", "purple", "green", "Duskmoon", "crescent moons and sparkles", "purple" },
	{ "32", "purple", "pink", "Royal Diamond", "diamonds", "pink" },
	{ "33", "purple", "blue", "Periwinkle", "flowers", "purple" },
	{ "34", "purple", "white", "Lavender Stripe", "diagonal stripes", "purple" },
	{ "35", "red", "orange", "Wildfire", "flames rising from the base", "red" },
	{ "36", "red", "yellow", "Starburst", "stars and dots", "red" },
	{ "37", "red", "green", "Watermelon", "green rind at the base, green seeds", "red" },
	{ "38", "red", "pink", "Sweetheart", "hearts", "pink" },
	{ "39", "red", "blue", "Racer", "two racing stripes over the top", "red" },
	{ "40", "red", "white", "Pawprint", "paw prints", "red" },
	{ "41", "orange", "yellow", "Ember Chevron", "chevron", "yellow" },
	{ "42", "orange", "green", "Tangerine", "leafy cap on the tip", "orange" },
	{ "43", "orange", "pink", "Sunrise Fade", "fade, pink below to orange on top", "orange" },
	{ "44", "orange", "blue", "Goldfish", "little fish", "blue" },
	{ "45", "orange", "white", "Creamsicle Check", "checks", "orange" },
	{ "46", "yellow", "green", "Citrusleaf", "leaves", "green" },
	{ "47", "yellow", "pink", "Lollipop", "one swirl from the tip", "yellow" },
	{ "48", "yellow", "blue", "Sunwave", "waves", "blue" },
	{ "49", "yellow", "white", "Daisy", "daisies", "yellow" },
	{ "50", "green", "pink", "Clover", "four-leaf clovers", "pink" },
	{ "51", "green", "blue", "Seafoam", "rings", "blue" },
	{ "52", "green", "white", "Mint Chip", "dots", "green" },
	{ "53", "pink", "blue", "Cotton Candy", "soft swirled clouds", "pink" },
	{ "54", "pink", "white", "Lace", "lace scallops", "pink" },
	{ "55", "blue", "white", "Frostbolt", "lightning bolts", "white" },
}

DualDesigns.List = {} :: { Design }

local byId: { [string]: Design } = {}
local byPair: { [string]: Design } = {}
for _, row in PLAN do
	local a, b, body = row[2], row[3], row[6]
	local design: Design = {
		id = "dual-" .. a .. "-" .. b .. "-" .. row[1],
		number = row[1],
		name = row[4],
		skin = row[1] .. "_" .. string.gsub(string.lower(row[4]), " ", "_"),
		parentPair = { a, b },
		pattern = row[5],
		bodyColour = body,
		patternColour = if body == a then b else a,
		assetId = "slime.dual." .. row[1],
		enabled = true,
		weight = 1,
	}
	table.insert(DualDesigns.List, design)
	byId[design.id] = design
	byPair[Colours.pairKey(a, b)] = design
end

function DualDesigns.get(id: string): Design?
	return byId[id]
end

function DualDesigns.weight(design: Design): number
	return design.weight
end

-- The design of exactly this pair (either order): a list of one, or empty for a same-colour pair.
function DualDesigns.exact(a: string, b: string): { Design }
	local design = byPair[Colours.pairKey(a, b)]
	if design and design.enabled and a ~= b then
		return { design }
	end
	return {}
end

-- The designs a pairing can produce: its one design. Same-colour pairs have none: duals need mixing.
function DualDesigns.pool(a: string, b: string): { Design }
	return DualDesigns.exact(a, b)
end

return DualDesigns
