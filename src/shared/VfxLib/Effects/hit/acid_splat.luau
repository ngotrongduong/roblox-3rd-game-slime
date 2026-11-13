-- A spitter's blow, the whole trio: a glob of the owner's goo flies in a low arc from the attacker (`opts.from`), splats
-- as acid where it lands and throws acid drops; the `death` variant adds the acid burst over the body and a ring of acid
-- that spreads on the ground where it falls. Goo Lineage's toxic style (FightFx.shot, mark, burst, ring).
local MARK = 3

local function burst(name, texture, size)
	return {
		name = name,
		texture = texture,
		role = "keep",
		count = 1,
		life = { 0.45, 0.45 },
		size = { { 0, size * 0.75 }, { 1, size * 1.35 } },
		transparency = { { 0, 0.7 }, { 0.12, 0.02 }, { 0.55, 0.1 }, { 1, 1 } },
		rotation = { 0, 359 },
		rotSpeed = { -70, 70 },
		zOffset = 2,
	}
end

return {
	id = "hit.acid_splat",
	name = "Acid Splat",
	kind = "hit",
	tier = "mid",
	host = "slime",
	refHeight = 3,
	tags = { "impact", "acid", "poison", "toxic", "projectile", "death", "owner_art", "cartoon" },
	blend = "normal",
	palette = {},
	tintable = false,
	-- (the spit: one picture thrown on a real arc, turned along its flight by the engine; then the mark)
	projectile = {
		name = "spit",
		texture = "gooBlob",
		role = "keep",
		seconds = 0.24,
		arc = 2.5,
		size = { { 0, 1.8 }, { 1, 1.8 } },
		transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
		zOffset = 2,
	},
	pieces = {
		{
			name = "splat",
			texture = "acidSplat",
			role = "keep",
			count = 1,
			life = { 0.34, 0.34 },
			size = { { 0, MARK * 0.75 }, { 1, MARK * 1.35 } },
			transparency = { { 0, 0.7 }, { 0.12, 0.02 }, { 0.55, 0.1 }, { 1, 1 } },
			rotation = { 0, 359 },
			rotSpeed = { -70, 70 },
			zOffset = 2,
		},
		{
			name = "drops",
			texture = "acidDrop",
			role = "keep",
			count = 5,
			life = { 0.45, 0.75 },
			size = { { 0, MARK * 0.18 }, { 1, MARK * 0.18 * 0.3 } },
			transparency = { { 0, 0 }, { 1, 1 } },
			speed = { 8.4, 14 },
			spread = { 180, 180 },
			direction = "Top",
			accel = { 0, -28, 0 },
			drag = 1.5,
			rotation = { 0, 359 },
			rotSpeed = { -180, 180 },
			zOffset = 3,
		},
	},
	variants = {
		-- the blow that fells: the acid burst over the body, more drops, and the ring on the ground
		death = {
			extra = {
				burst("deathBurst", "burstAcid", 6),
				{
					name = "deathDrops",
					texture = "acidDrop",
					role = "keep",
					count = 8,
					life = { 0.45, 0.75 },
					size = { { 0, 6 * 0.12 }, { 1, 6 * 0.12 * 0.3 } },
					transparency = { { 0, 0 }, { 1, 1 } },
					speed = { 9.6, 16 },
					spread = { 180, 180 },
					direction = "Top",
					accel = { 0, -28, 0 },
					drag = 1.5,
					rotation = { 0, 359 },
					rotSpeed = { -180, 180 },
					zOffset = 3,
				},
				{
					name = "ring",
					texture = "ringAcid",
					role = "keep",
					at = "ground",
					flat = true,
					count = 1,
					life = { 0.65, 0.65 },
					-- (Goo Lineage tweens a disc from a quarter to the whole 9 studs, cubic out; the decal fades quad in)
					size = { { 0, 2.25 }, { 0.2, 6.2 }, { 0.5, 8.4 }, { 1, 9 } },
					transparency = { { 0, 0.05 }, { 0.5, 0.3 }, { 0.8, 0.66 }, { 1, 1 } },
					zOffset = -1,
				},
			},
		},
	},
	source = {
		from = "Goo Lineage FightFx, Styles.toxic (gooBlob shot, acidSplat + acidDrop, burstAcid, ringAcid)",
		art = "the owner's battle art (battlefx-*.png), uploaded 2026-11-03",
		licence = "the owner's own",
	},
	notes = "Play with opts.from = the spitter's mouth to get the flight; without it only the splat plays. "
		.. "Goo Lineage also throws glossy drops of the body itself (parts in the body's colour): that stays game code.",
}
