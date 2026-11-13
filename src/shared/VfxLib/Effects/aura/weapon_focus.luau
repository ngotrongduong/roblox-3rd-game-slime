-- Weapon Aura Focus: what Goo Lineage's finer Arcane Focuses give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). Each rung's whole aura is one ChatGPT clip worn round the
-- focus (the owner's way, lesson 284: a GIF of this very focus wearing it, rebuilt as the effect alone round its empty
-- shape), one particle for four slimes on a phone. Core, the Prism: a rainbow glow breaking out of the gem ring, a
-- rainbow ribbon swirling up round the focus, prism shards drifting. Bramble, the Mythic Focus: violet rings orbiting
-- the head, the gem pulsing violet, glowing green leaves drifting, violet sparkles, a violet light. Legend, the Astral
-- Scepter: a violet and blue nebula swirling round it, a little golden galaxy turning over its tip like a crown,
-- twinkling gold stars, a starlight glow.

-- (the whole aura in one picture drawn round the focus's empty shape; the clip once a life, 1.5 s, one always there,
-- the next taking over on the clip's dim first frame. `size`: the focus's height over its share of the picture,
-- halved, as clip_frames.py --fit prints it, the picture centred on the focus)
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
		-- (stood along the focus by a crawl up it, so the picture leans as it leans; VelocityParallel lays a
		-- picture's WIDTH along the flight, so the upright drawing is turned a quarter: lesson 255)
		speed = { 0.05, 0.05 },
		direction = "Top",
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 0,
		-- (over the head's faces: the gem's glow lies on the gem)
		zOffset = 0.4,
		locked = true,
	}
end

return {
	id = "aura.weapon_focus",
	name = "Weapon Aura Focus",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "focus", "held", "arcane", "orbit", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = { card("prism_aura_flip", 2.12) },
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = { card("mythic_aura_flip", 1.89) },
			light = { color = { 195, 140, 255 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = { card("astral_aura_flip", 2.21) },
			light = { color = { 170, 140, 255 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "prism_aura_flip, mythic_aura_flip, astral_aura_flip (ChatGPT's GIF of each focus wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit)",
		licence = "the owner's own art (drawn for the library by ChatGPT)",
	},
	notes = "VfxLib.attach(focusMeshPart, id, { variant = rarity }) while a core, bramble or legend focus is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
