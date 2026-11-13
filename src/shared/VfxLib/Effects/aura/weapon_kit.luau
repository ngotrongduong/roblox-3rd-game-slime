-- Weapon Aura Kit: what Goo Lineage's finer Alchemy Kits give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon ones have none). Each rung's whole aura is one ChatGPT clip worn round the kit (the
-- owner's way, lesson 284: a GIF of this very kit wearing it, rebuilt as the effect alone round its empty shape), one
-- particle for four slimes on a phone. Core, the Alchemist's Satchel: violet light swirling round the bag, red and
-- blue potion drops glowing at its sides, bubbles rising. Bramble, the Philosopher's Kit: a golden alchemy circle
-- turning round it, a teal star pulsing in the bag, a little flask and a sprout glowing, a green light. Legend, the
-- Grand Elixir Pack: a golden halo over the handle, the gem pulsing violet, violet wisps curling up its sides, rainbow
-- bubbles drifting, a violet light.

-- (the whole aura in one picture drawn round the kit's empty shape; the clip once a life, 1.5 s, one always there,
-- the next taking over on the clip's dim first frame. `size`: the kit's height over its share of the picture,
-- halved, as clip_frames.py --fit --height 2.5 prints it, the picture centred on the kit)
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
		-- (stood along the kit by a crawl up it, so the picture leans as it leans; VelocityParallel lays a
		-- picture's WIDTH along the flight, so the upright drawing is turned a quarter: lesson 255)
		speed = { 0.05, 0.05 },
		direction = "Top",
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 0,
		-- (out over the bag's thick front: the light round it is drawn on top of the pouches)
		zOffset = 0.7,
		locked = true,
	}
end

return {
	id = "aura.weapon_kit",
	name = "Weapon Aura Kit",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 2.5,
	tags = { "weapon", "alchemy", "kit", "held", "bubbles", "potion", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = { card("satchel_aura_flip", 2.04) },
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = { card("philosopher_aura_flip", 2.35) },
			light = { color = { 150, 255, 190 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = { card("elixir_aura_flip", 1.9) },
			light = { color = { 215, 150, 255 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "satchel_aura_flip, philosopher_aura_flip, elixir_aura_flip (ChatGPT's GIF of each kit wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit --height 2.5)",
		licence = "the owner's own art (drawn for the library by ChatGPT)",
	},
	notes = "VfxLib.attach(kitMeshPart, id, { variant = rarity }) while a core, bramble or legend kit is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
