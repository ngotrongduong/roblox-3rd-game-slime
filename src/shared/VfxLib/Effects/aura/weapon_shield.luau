-- Weapon Aura Shield: what Goo Lineage's finer shields give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon shields have none). Each rung's whole aura is one ChatGPT clip worn round the shield
-- (the owner's way, lesson 284: a GIF of this very shield wearing it, rebuilt as the effect alone round its empty
-- shape), one particle for four slimes on a phone. Core, the Warden: a royal-blue light running round the rim, a gold
-- glint sweeping the crest, blue stars twinkling. Bramble, the Aegis of Goo: lime goo oozing round the rim and
-- dripping off the point, bubbles rising and popping, leaves glowing, a green light. Legend, the Royal Bastion: golden
-- rays fanning out behind it, gold light round the rim and towers, a crown of light over the top, golden fleurs-de-lis
-- rising, a gold light.

-- (the whole aura in one picture drawn round the shield's empty shape; the clip once a life, 1.5 s, one always there,
-- the next taking over on the clip's dim first frame. `size`: the shield's height over its share of the picture,
-- halved, as clip_frames.py --fit prints it, the picture centred on the shield)
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
		-- (stood along the shield by a crawl up it, so the picture leans as it leans; VelocityParallel lays a
		-- picture's WIDTH along the flight, so the upright drawing is turned a quarter: lesson 255)
		speed = { 0.05, 0.05 },
		direction = "Top",
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 0,
		-- (before the shield's face: inside its thick body the shield's own mesh hid the light on its face)
		zOffset = 0.7,
		locked = true,
	}
end

return {
	id = "aura.weapon_shield",
	name = "Weapon Aura Shield",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "shield", "held", "ward", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = { card("warden_aura_flip", 1.9) },
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = { card("goo_aegis_aura_flip", 2.44) },
			light = { color = { 150, 255, 110 }, brightness = 1.2, range = 8 },
		},
		legend = {
			pieces = { card("bastion_aura_flip", 2.25) },
			light = { color = { 255, 215, 120 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "warden_aura_flip, goo_aegis_aura_flip, bastion_aura_flip (ChatGPT's GIF of each shield wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit)",
		licence = "the owner's own art (drawn for the library by ChatGPT)",
	},
	notes = "VfxLib.attach(shieldMeshPart, id, { variant = rarity }) while a core, bramble or legend shield is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
