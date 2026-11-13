-- Weapon Aura Bow: what Goo Lineage's finer bows give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon bows have none). Each rung's whole aura is one ChatGPT clip worn round the bow (the
-- owner's way, lesson 284: a GIF of this very bow wearing it, rebuilt as the effect alone round its empty shape), one
-- particle for four slimes on a phone. Core, Windwhisper: teal wind arcs sweeping round the bow's back, the string
-- shimmering, white feathers drifting. Bramble, Starfall: violet starlight along the limbs, the star gems flaring, the
-- string shimmering, gold stars falling, a violet light. Legend, Moonsong: silver moonlight swirling round the bow,
-- crescent moons orbiting, notes drifting, a moon halo over the tip like a crown, a moon light.

-- (the whole aura in one picture drawn round the bow's empty shape; the clip once a life, 1.5 s, one always there, the
-- next taking over on the clip's dim first frame. `size`: the bow's height over its share of the picture, halved, as
-- clip_frames.py --fit prints it, the picture centred on the bow)
local function card(texture, size)
	return {
		name = "aura",
		texture = texture,
		role = "keep",
		at = "body",
		rate = 1 / 1.5,
		steady = true,
		life = { 1.52, 1.52 },
		size = { { 0, size }, { 1, size } },
		transparency = { { 0, 0 }, { 1, 0 } },
		-- (stood along the bow by a crawl up it, so the picture leans as it leans; VelocityParallel lays a
		-- picture's WIDTH along the flight, so the upright drawing is turned a quarter: lesson 255)
		speed = { 0.05, 0.05 },
		direction = "Top",
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 0,
		zOffset = 0.4,
		locked = true,
	}
end

return {
	id = "aura.weapon_bow",
	name = "Weapon Aura Bow",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "bow", "held", "glint", "feather", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = { card("windwhisper_aura_flip", 2.24) },
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = { card("starfall_aura_flip", 1.93) },
			light = { color = { 195, 160, 255 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = { card("moonsong_aura_flip", 2.43) },
			light = { color = { 175, 195, 255 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "windwhisper_aura_flip, starfall_aura_flip, moonsong_aura_flip (ChatGPT's GIF of each bow wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit)",
		licence = "the owner's own art (drawn for the library by ChatGPT)",
	},
	notes = "VfxLib.attach(bowMeshPart, id, { variant = rarity }) while a core, bramble or legend bow is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
