-- Weapon Aura Staff: what Goo Lineage's finer Healing Staffs give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). Each rung's whole aura is one ChatGPT clip worn round the
-- staff (the owner's way, lesson 284: a GIF of this very staff wearing it, rebuilt as the effect alone round its empty
-- shape), one particle for four slimes on a phone. Core, the Enchanted staff: a violet ribbon of light spiralling up
-- round the shaft, the crystal pulsing violet, white sparkles. Bramble, Lifebloom: the crystal pulsing teal, teal and
-- pink ribbons spiralling up, blossom petals drifting away, teal sparkles, a cool light. Legend, Everbloom: a crown of
-- golden lily petals opening over the top, the emerald pulsing green, golden leaves spiralling up, green and gold
-- sparkles, a warm light.

-- (the whole aura in one picture drawn round the staff's empty shape; the clip once a life, 1.5 s, one always there,
-- the next taking over on the clip's dim first frame. `size`: the staff's height over its share of the picture,
-- halved, as clip_frames.py --fit prints it, the picture centred on the staff)
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
		-- (stood along the staff by a crawl up it, so the picture leans as it leans; VelocityParallel lays a
		-- picture's WIDTH along the flight, so the upright drawing is turned a quarter: lesson 255)
		speed = { 0.05, 0.05 },
		direction = "Top",
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 0,
		-- (over the head's faces: the crystal's glow lies on the crystal)
		zOffset = 0.4,
		locked = true,
	}
end

return {
	id = "aura.weapon_staff",
	name = "Weapon Aura Staff",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "staff", "held", "heal", "nature", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = { card("enchanted_aura_flip", 1.82) },
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = { card("lifebloom_aura_flip", 1.69) },
			light = { color = { 200, 255, 225 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = { card("everbloom_aura_flip", 2.27) },
			light = { color = { 255, 220, 130 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "enchanted_aura_flip, lifebloom_aura_flip, everbloom_aura_flip (ChatGPT's GIF of each staff wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit)",
		licence = "the owner's own art (drawn for the library by ChatGPT)",
	},
	notes = "VfxLib.attach(staffMeshPart, id, { variant = rarity }) while a core, bramble or legend staff is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
