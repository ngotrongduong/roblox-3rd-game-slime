-- Weapon Aura Sword: what Goo Lineage's finer swords give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon swords have none). Each rung's whole aura is one ChatGPT clip worn round the sword (the
-- owner's way, lesson 284: a GIF of this very sword wearing it, rebuilt as the effect alone round its empty shape), one
-- particle for four slimes on a phone. Core, the Runeblade: a violet glow tracing the edges, lilac diamond runes lighting
-- up the blade, a ribbon circling. Bramble, the Dawnbreaker: gold and pink light ribbons up the blade, the gem pulsing, a
-- star on the tip, feathers spiralling, a warm light. Legend, Sunfire: crimson flames licking up the edges, embers, a
-- golden sun turning over the tip like a crown, a fire light.

-- (the whole aura in one picture drawn round the sword's empty shape; the clip once a life, 1.5 s, one always there,
-- the next taking over on the clip's dim first frame. `size`: the sword's height over its share of the picture, halved,
-- as clip_frames.py --fit prints it, the picture centred on the sword)
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
		-- (stood along the blade by a crawl up it, so the picture leans as the sword leans; VelocityParallel lays
		-- a picture's WIDTH along the flight, so the upright drawing is turned a quarter: lesson 255)
		speed = { 0.05, 0.05 },
		direction = "Top",
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 0,
		-- (over the sword's faces: the gem's glow lies on the gem)
		zOffset = 0.3,
		locked = true,
	}
end

return {
	id = "aura.weapon_sword",
	name = "Weapon Aura Sword",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "sword", "held", "glint", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = { card("runeblade_aura_flip", 1.75) },
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = { card("dawn_aura_flip", 2.24) },
			light = { color = { 255, 210, 150 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = { card("sunfire_aura_flip", 2.59) },
			light = { color = { 255, 140, 70 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "runeblade_aura_flip, dawn_aura_flip, sunfire_aura_flip (ChatGPT's GIF of each sword wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit)",
		licence = "the owner's own art (drawn for the library by ChatGPT)",
	},
	notes = "VfxLib.attach(swordMeshPart, id, { variant = rarity }) while a core, bramble or legend sword is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
