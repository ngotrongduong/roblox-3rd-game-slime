-- Weapon Aura Shield: what Goo Lineage's finer shields give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon shields have none). Quiet, for four slimes on a phone: a ward shimmers up over the face
-- now and then and a few specks hang in the air round it. Core: a violet ward, violet specks. Bramble: a green ward, gold
-- specks, a leaf now and then. Legend: a gold ward, gold specks and twinkles, a glint on the rim.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a ward shimmering up over the shield's face, faint, now and then)
local function shimmer(color, size)
	return {
		name = "shimmer",
		texture = "shield_icon",
		color = color,
		at = "body",
		-- (a little before the face and wider than the shield: inside its body the shield's own mesh hid the ward, from
		-- the front or behind)
		offset = { 0, 0, -0.3 },
		-- (one after another, never gone: at 0.5 a second and 0.6 at its brightest it was mostly not there)
		rate = 1.2,
		life = { 1.5, 1.5 },
		size = { { 0, size * 0.85 }, { 1, size * 1.1 } },
		transparency = { { 0, 1 }, { 0.3, 0.4 }, { 0.7, 0.4 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = 1,
	}
end

-- (specks hanging in the air round the shield)
local function specks(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		-- (wider than the shield, or most are inside it)
		box = { 1.8, 1.5, 1 },
		rate = rate,
		life = { 0.7, 1 },
		size = { { 0, 0 }, { 0.3, size }, { 1, 0 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } },
		speed = { 0.1, 0.4 },
		spread = { 180, 180 },
		rotation = { 0, 359 },
		lightEmission = 1,
		locked = false,
	}, over)
end

return {
	id = "aura.weapon_shield",
	name = "Weapon Aura Shield",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "shield", "held", "ward", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		shimmer({ 190, 150, 255 }, 3.3),
		specks("specks", "spec_star", { { 230, 215, 255 }, { 160, 110, 255 } }, 4, 0.6),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				shimmer({ 160, 235, 110 }, 3.4),
				specks("specks", "spec_star", { { 255, 240, 190 }, { 255, 205, 80 } }, 4, 0.6),
				specks("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 1, 0.6, {
					size = { { 0, 0.6 }, { 1, 0.42 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					accel = { 0, -2.5, 0 },
					rotSpeed = { -150, 150 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				}),
			},
		},
		legend = {
			pieces = {
				shimmer({ 255, 215, 110 }, 3.6),
				specks("specks", "spec_star", { { 255, 245, 210 }, { 255, 205, 90 } }, 5, 0.65),
				specks("twinkles", "star_twinkle", { { 255, 245, 210 }, { 150, 180, 255 } }, 2.5, 0.75),
				{
					name = "glint",
					texture = "star_glint_small",
					color = { { 255, 255, 240 }, { 255, 215, 110 } },
					at = "head",
					box = { 0.8, 0.1, 0.3 },
					rate = 1,
					life = { 0.3, 0.4 },
					size = { { 0, 0 }, { 0.35, 1.2 }, { 1, 0 } },
					rotation = { -20, 20 },
					lightEmission = 1,
					zOffset = 1.5,
				},
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: shield_icon, spec_star, star_twinkle, star_glint_small); leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(shieldMeshPart, id, { variant = rarity }) while a core, bramble or legend shield is held; VfxLib.detach(handle) when it is put away. Core is cheap, bramble and legend mid; no light.",
}
