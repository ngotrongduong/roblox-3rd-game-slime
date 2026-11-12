--!strict
-- Weapons give a complete job at Common; higher-tier skills will join here in later steps.
-- Every tier currently uses only its Common skill, so rarity never gates the class's job.
return {
	Families = {
		sword = "warrior",
		shield = "guardian",
		bow = "ranger",
		focus = "mage",
		staff = "healer",
		kit = "alchemist",
	},
	Tiers = { wood = 1, iron = 2, core = 3, bramble = 4, legend = 5 },
	Kinds = {
		-- (`taken`: the Guardian always takes that share less, behind its shield; its Taunt raises it while it lasts)
		-- (the ranged reaches are 1.5 times the first ones, the owner, 2026-11-13: 16, 16, 15, 14)
		guardian = { beat = 1.1, factor = 0.8, magic = false, reach = 6, pull = 3, skill = "taunt", taken = 0.2 },
		warrior = { beat = 1, factor = 1.05, magic = false, reach = 6, pull = 1, skill = "dash_strike" },
		ranger = { beat = 1, factor = 1.05, magic = false, reach = 24, pull = 1, skill = "piercing_shot" },
		mage = { beat = 1, factor = 0.9, magic = true, reach = 24, pull = 1, skill = "arcane_barrage" },
		healer = { beat = 1.15, factor = 0.65, magic = true, reach = 22.5, pull = 1, skill = "mend" },
		alchemist = { beat = 1, factor = 0.9, magic = true, reach = 21, pull = 1, skill = "acid_rain" },
	},
	-- An attack skill weighs this many of its class's plain blows, by the weapon's tier (the owner, 2026-11-13: Common
	-- 1.1, Uncommon 1.2, ...), on every foe it strikes, so a better weapon's skill counts at every level; its own effect
	-- (the dash, the armour it ignores or melts) comes on top. A single-target skill strikes its target only; an area
	-- skill every foe within its `radius` of the target (a fight with no places, the camps and the Arena: `cap` foes).
	SkillPower = { 1.1, 1.2, 1.3, 1.4, 1.5 },
	-- 'every' keeps the shared skill catalogue compatible with its older consumers; classes use seconds instead.
	Skills = {
		taunt = {
			name = "Taunt",
			kind = "single",
			every = 1,
			cooldown = 8,
			range = 18,
			count = 3,
			seconds = 4,
			taken = 0.35,
			minimum = 2,
		},
		dash_strike = {
			name = "Dash Strike",
			kind = "single",
			every = 1,
			cooldown = 6,
			minStuds = 7,
			maxStuds = 18,
			seconds = 0.2,
		},
		piercing_shot = { name = "Piercing Shot", kind = "single", every = 1, cooldown = 6, ignore = 0.25 },
		arcane_barrage = { name = "Arcane Barrage", kind = "splash", every = 1, cooldown = 6, radius = 7, cap = 3 },
		-- (a heal, not an attack: `factor` heals, SkillPower leaves it alone)
		mend = { name = "Mend", kind = "single", every = 1, cooldown = 8, factor = 4, threshold = 0.6, range = 22.5 },
		acid_rain = {
			name = "Acid Rain",
			kind = "splash",
			every = 1,
			cooldown = 8,
			radius = 8,
			cap = 3,
			melt = 0.2,
			seconds = 4,
		},
	},
	-- Magic bypasses part of armour. A heal of factor 1 gives back what the healer's own blow would take off a slime as
	-- strong as itself (Combat.healAmount).
	MagicDefence = 0.65,
	PlainHeal = 0.9,
	HealThreshold = 0.9,
	-- In the Arena heals weaken as a fight drags on (docs/WEAPONS.md §7): { seconds, share }, straight between the points.
	HealFade = { { 30, 1 }, { 45, 0.8 }, { 60, 0.6 }, { 75, 0.4 } },
	-- Stagger the first signatures rather than opening the fight with all six at once.
	OpeningShare = 0.5,
	StunWindow = 10,
	StunSteps = { 1, 0.5, 0.25, 0 },
	MiniStunCap = 0.3,
	MiniStunFree = 6,
	SpecialGap = 8,
	TakenCap = 0.4,
	-- Effects on a unit, the strongest of a kind only (never added up), each capped here: a new kind is one line.
	--   melt: its DEF counts that share less;   taken: damage it takes is that share less (all sources, TakenCap).
	Effects = { melt = 0.75, taken = 0.4 },
	TauntFree = 2,
	-- A lone foe of these kinds going for a team-mate is worth a taunt by itself (a raider hunting the back row).
	TauntAlone = { hunter = true },
	-- The team-mates a Guardian peels foes off first: the ones that cannot take a beating.
	Squishy = { ranger = true, mage = true, healer = true, alchemist = true },
	HopStuds = 7,
	HopSeconds = 0.25,
	HopCooldown = { ranger = 6, mage = 9 },
	-- (a hop tries its full length first, then shorter ones, to land on a free spot)
	HopTries = { 1, 0.75, 0.5 },
	DangerStuds = 7,
	InterceptShare = 0.7,
	InterceptCooldown = 8,
	InterceptStuds = 9,
}
