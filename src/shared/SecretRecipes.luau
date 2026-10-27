--!strict
-- The 66 Secret slimes (docs/reference/01-core-farm.md §5.6): one recipe for every colour pair,
-- the 55 cross pairs and the 11 same-colour pairs, so every breeding has a secret chance.
-- "big" marks art with wide features (wings, crests): its body is drawn Config.Farm.SecretBodyBoost
-- times larger, the face is not.

local Colours = if script then require(script.Parent.Colours) else require("./Colours")

local SecretRecipes = {}

export type Recipe = {
	id: string,
	name: string,
	description: string,
	parentPair: { string },
	assetId: string,
	enabled: boolean,
	weight: number,
	big: boolean,
}

-- { colour a, colour b, name, description, "big" or "" } in the original order.
local RECIPES: { { string } } = {
	{ "white", "white", "Snow Rabbit", "Fluffy snow texture, rabbit ears and a cotton tail", "" },
	{ "white", "pink", "Sakura Bunny", "Pink-tipped ears with drifting cherry blossoms", "" },
	{ "white", "yellow", "Daisy Chick", "Yellow feather tuft and white daisy-petal markings", "" },
	{ "white", "green", "Lily Spirit", "Lily-of-the-valley flowers and delicate green vines", "" },
	{ "white", "orange", "Creamsicle Fox", "Orange fox ears and tail with creamy-white tips", "" },
	{ "white", "red", "Peppermint Slime", "Red-and-white candy spirals with mint sparkles", "" },
	{ "white", "purple", "Moon Orchid", "Pale orchid petals with a soft violet moon glow", "" },
	{ "white", "navy", "Arctic Wolf", "Navy-tipped wolf ears, icy fur markings and frost breath", "" },
	{ "white", "gray", "Cloud Sheep", "Cloud-like wool curls with tiny gray hooves", "" },
	{ "white", "black", "Yin-Yang Koi", "Two circling koi markings with flowing fin-like tails", "" },
	{ "pink", "pink", "Rose Fairy", "Rose-petal wings and floating pink pollen", "" },
	{ "pink", "yellow", "Peach Blossom", "Peach-coloured flower crown and yellow pollen sparkles", "" },
	{ "pink", "green", "Watermelon Frog", "Green outer skin, pink centre and seed spots", "" },
	{ "pink", "orange", "Coral Axolotl", "Coral-pink gills, orange fins and bubbly particles", "big" },
	{ "pink", "red", "Lovebird Slime", "Tiny feathered wings and heart-shaped markings", "big" },
	{ "pink", "purple", "Dream Butterfly", "Large butterfly wings with glowing dream dust", "big" },
	{ "pink", "navy", "Twilight Moth", "Navy moth wings decorated with pink moon patterns", "" },
	{ "pink", "gray", "Rose Hedgehog", "Soft gray spines covered with tiny pink roses", "" },
	{ "pink", "black", "Gothic Bat", "Black bat wings, pink inner ears and rose-vine markings", "big" },
	{ "yellow", "yellow", "Sun Lion", "Golden mane made from sun rays", "big" },
	{ "yellow", "green", "Lemon Gecko", "Lime-green body markings with yellow citrus spots", "" },
	{ "yellow", "orange", "Sun Phoenix", "Fiery feather crest and glowing orange wings", "big" },
	{ "yellow", "red", "Fire Salamander", "Yellow-red flame markings and a flaming tail", "" },
	{ "yellow", "purple", "Royal Griffin", "Purple feathered wings with a golden eagle crest", "big" },
	{ "yellow", "navy", "Star Owl", "Navy wings covered in glowing yellow stars", "" },
	{ "yellow", "gray", "Thunder Ram", "Curved gray horns surrounded by yellow electricity", "" },
	{ "yellow", "black", "Honeybee Slime", "Black-yellow stripes, tiny wings and dripping honey", "" },
	{ "green", "green", "Forest Dryad", "Leafy hair, small antlers, flowers and orbiting leaves", "" },
	{ "green", "orange", "Autumn Fox", "Leaf-shaped fox ears and a fiery autumn tail", "" },
	{ "green", "red", "Holly Deer", "Small antlers decorated with holly leaves and red berries", "" },
	{ "green", "purple", "Poison Frog", "Bright toxic spots, frog feet and bubbling poison droplets", "" },
	{ "green", "navy", "Lagoon Turtle", "Shell-like back pattern with seaweed and water ripples", "" },
	{ "green", "gray", "Moss Golem", "Cracked stone texture covered with moss and tiny flowers", "" },
	{ "green", "black", "Swamp Basilisk", "Dark scales, green glowing eyespots and a reptile tail", "" },
	{ "orange", "orange", "Ember Tiger", "Fiery tiger stripes, rounded ears and a flame-tipped tail", "" },
	{ "orange", "red", "Fire Dragon", "Dragon horns, small wings and burning scale patterns", "big" },
	{
		"orange",
		"purple",
		"Witch Cat",
		"Cat ears, curled tail, purple magical flames and a tiny hat marking",
		"",
	},
	{ "orange", "navy", "Sunset Koi", "Flowing fins coloured like an orange-and-blue sunset", "" },
	{ "orange", "gray", "Copper Beetle", "Metallic beetle shell, tiny legs and copper highlights", "" },
	{ "orange", "black", "Jack-o'-Slime", "Pumpkin texture, curling vine and warm inner light", "" },
	{ "red", "red", "Rose Dragon", "Rose-petal scales, thorny horns and floral wings", "" },
	{ "red", "purple", "Dragonfruit Slime", "Bright fruit skin, leafy crest and dark seed spots", "" },
	{ "red", "navy", "Fire-Ice Chimera", "One flaming side and one frozen side with mismatched horns", "" },
	{ "red", "gray", "Iron Boar", "Metal tusks, red armour markings and a strong rounded body", "" },
	{ "red", "black", "Blood Moon Bat", "Dark wings with a glowing crimson moon marking", "" },
	{ "purple", "purple", "Amethyst Unicorn", "Crystal horn, sparkling mane and amethyst hooves", "" },
	{ "purple", "navy", "Galaxy Whale", "Star-filled body with tiny fins and a floating cosmic tail", "big" },
	{ "purple", "gray", "Moonstone Gargoyle", "Stone wings, small horns and glowing violet cracks", "big" },
	{ "purple", "black", "Void Kraken", "Shadowy tentacles, purple runes and floating void particles", "big" },
	{ "navy", "navy", "Deep-Sea Leviathan", "Fins, glowing lure, dark scales and bioluminescent spots", "" },
	{ "navy", "gray", "Storm Shark", "Shark fin and tail surrounded by storm clouds and rain", "" },
	{ "navy", "black", "Midnight Raven", "Black feathered wings with a navy starry sheen", "big" },
	{ "gray", "gray", "Stone Tortoise", "Heavy stone shell with moss growing between the cracks", "" },
	{ "gray", "black", "Shadow Wolf", "Smoky black fur markings, gray ears and a shadow tail", "" },
	{
		"black",
		"black",
		"Universe Slime",
		"A living night sky containing stars, nebulae and miniature galaxies",
		"",
	},
	{
		"blue",
		"blue",
		"Cloud Pegasus",
		"Fluffy cloud mane, tiny feathered wings and sparkling raindrops",
		"",
	},
	{ "blue", "white", "Frost Swan", "White crystal wings, icy-blue feathers and drifting snowflakes", "big" },
	{ "blue", "yellow", "Thunderbird", "Golden lightning wings, a sky-blue crest and crackling sparks", "" },
	{
		"blue",
		"green",
		"Sky Island Turtle",
		"Grassy shell with tiny flowers, floating clouds and a miniature waterfall",
		"big",
	},
	{
		"blue",
		"orange",
		"Sunshower Fox",
		"Orange sun markings, cloud-like tails and glowing rainbow droplets",
		"",
	},
	{ "blue", "red", "Steam Dragon", "Red-hot core, blue dragon horns and swirling clouds of steam", "" },
	{
		"blue",
		"pink",
		"Cotton Candy Sheep",
		"Fluffy pink-and-blue cloud wool with floating sugar sparkles",
		"",
	},
	{
		"blue",
		"purple",
		"Aurora Jellyfish",
		"Flowing violet tentacles, a translucent blue bell and aurora ribbons",
		"",
	},
	{
		"blue",
		"navy",
		"Celestial Manta",
		"Wide navy fins decorated with glowing sky-blue constellations",
		"",
	},
	{
		"blue",
		"gray",
		"Raincloud Ram",
		"Curled storm-cloud horns, soft gray wool and falling blue raindrops",
		"big",
	},
	{
		"blue",
		"black",
		"Tempest Dragon",
		"Black storm wings, glowing cyan lightning cracks and swirling dark clouds",
		"big",
	},
}

SecretRecipes.List = {} :: { Recipe }

local byId: { [string]: Recipe } = {}
for _, row in RECIPES do
	local suffix = (string.gsub(Colours.pairKey(row[1], row[2]), "|", "-"))
	local recipe: Recipe = {
		id = "secret-" .. suffix,
		name = row[3],
		description = row[4],
		parentPair = { row[1], row[2] },
		assetId = "slime.secret." .. suffix,
		enabled = true,
		weight = 1,
		big = row[5] == "big",
	}
	table.insert(SecretRecipes.List, recipe)
	byId[recipe.id] = recipe
end

function SecretRecipes.get(id: string): Recipe?
	return byId[id]
end

function SecretRecipes.weight(recipe: Recipe): number
	return recipe.weight
end

-- The recipes for a pair, either order (always exactly one with the shipped data).
function SecretRecipes.forPair(a: string, b: string): { Recipe }
	local key = Colours.pairKey(a, b)
	local out = {}
	for _, r in SecretRecipes.List do
		if r.enabled and Colours.pairKey(r.parentPair[1], r.parentPair[2]) == key then
			table.insert(out, r)
		end
	end
	return out
end

return SecretRecipes
