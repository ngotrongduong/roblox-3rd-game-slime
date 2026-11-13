--!strict
-- The weapons the slimes hold (docs/WEAPONS.md §9): the owner's own 30 models (art/models/weapons/source/, cut by
-- tools/blender/weapon_kit.ps1 and uploaded as Models), where each family is worn and held, and how it moves
-- (shared/WeaponMoves, the original's battle/weaponAnims.js). Read as Config.Weapons; drawn by client/SlimeWeapon.
--
-- Places are on the slime's skin in body heights (mesh space: feet at y 0, one body height 1, the front -Z, the slime's
-- own right +X; the skin's radius at a height is SlimeShape.radius), and ride its squash and lean like a worn piece.
-- `turn` is degrees: a pitch about the slime's side axis (the tip forward is negative), then a yaw, then a roll, so a
-- move's swing always turns about the slime's own side axis.
--
-- The owner (2026-11-12): "trong làng, vũ khí như kiếm, khiên, cung tên, gậy phép các loại đặt ở vị trí vắt chéo sau
-- lưng, chỉ có túi thuốc là luôn ở vị trí bên trái của slime; trong trạng thái chiến đấu thì vũ khí ở trước mặt (khiên,
-- cung), kiếm, gậy phép ở vị trí bên phải". So every family has a `rest` place (on the back across, the kit at the
-- left) and a `fight` place (the shield and bow in front; sword, focus and staff at the right; the kit still at the left).
return {
	-- One texture a file of the owner's (rbxassetid).
	Textures = {
		sword = "rbxassetid://79193840384750",
		shield = "rbxassetid://124615631308611",
		bow = "rbxassetid://97040326986426",
		focus = "rbxassetid://133532200859702",
		staff = "rbxassetid://71001269983714",
		kit = "rbxassetid://117324534262136",
		legend = "rbxassetid://80995170831063",
	},
	-- Each weapon's mesh and its size as uploaded (Models sword 115975190425811, shield 71909880620944, bow
	-- 113363077178687, focus 76835823830520, staff 82544949076735, kit 85366375389422, Legendary 133155357704893).
	Models = {
		["sword-wood"] = { mesh = 80434216395575, size = { 0.1079, 0.3237, 0.043 } },
		["sword-iron"] = { mesh = 119707945544894, size = { 0.1196, 0.3218, 0.0435 } },
		["sword-core"] = { mesh = 97424107245270, size = { 0.1299, 0.3423, 0.041 } },
		["sword-bramble"] = { mesh = 71843935375370, size = { 0.1665, 0.3594, 0.0576 } },
		["sword-legend"] = { mesh = 81996377761925, size = { 0.1934, 0.4521, 0.0942 } },
		["shield-wood"] = { mesh = 127856880174003, size = { 0.1841, 0.2192, 0.0352 } },
		["shield-iron"] = { mesh = 90341434570164, size = { 0.1865, 0.2212, 0.0454 } },
		["shield-core"] = { mesh = 116292720216651, size = { 0.2095, 0.2471, 0.0537 } },
		["shield-bramble"] = { mesh = 129186109153522, size = { 0.2246, 0.2612, 0.0674 } },
		["shield-legend"] = { mesh = 83674461160207, size = { 0.2554, 0.3745, 0.1152 } },
		["bow-wood"] = { mesh = 97230629647098, size = { 0.123, 0.3188, 0.023 } },
		["bow-iron"] = { mesh = 112773650722902, size = { 0.1382, 0.3169, 0.0425 } },
		["bow-core"] = { mesh = 111238977776651, size = { 0.1528, 0.3135, 0.0474 } },
		["bow-bramble"] = { mesh = 104766470444826, size = { 0.2197, 0.3071, 0.0464 } },
		["bow-legend"] = { mesh = 93335732273912, size = { 0.1777, 0.4878, 0.0562 } },
		["focus-wood"] = { mesh = 92442075320062, size = { 0.145, 0.3213, 0.0552 } },
		["focus-iron"] = { mesh = 125565852267099, size = { 0.1553, 0.3296, 0.0562 } },
		["focus-core"] = { mesh = 97572294038584, size = { 0.1797, 0.3496, 0.0869 } },
		["focus-bramble"] = { mesh = 139305204493511, size = { 0.2061, 0.3496, 0.0869 } },
		["focus-legend"] = { mesh = 81239977190836, size = { 0.188, 0.499, 0.0923 } },
		["staff-wood"] = { mesh = 124624299880501, size = { 0.1611, 0.5132, 0.0522 } },
		["staff-iron"] = { mesh = 130447093872797, size = { 0.1807, 0.5283, 0.0596 } },
		["staff-core"] = { mesh = 89786047953347, size = { 0.1631, 0.5312, 0.0752 } },
		["staff-bramble"] = { mesh = 70628252854651, size = { 0.2109, 0.5391, 0.0747 } },
		["staff-legend"] = { mesh = 108485369255733, size = { 0.2183, 0.5127, 0.0874 } },
		["kit-wood"] = { mesh = 114659621315298, size = { 0.2222, 0.1748, 0.145 } },
		["kit-iron"] = { mesh = 84051801569656, size = { 0.2139, 0.1802, 0.1465 } },
		["kit-core"] = { mesh = 124242419318685, size = { 0.2188, 0.1777, 0.166 } },
		["kit-bramble"] = { mesh = 112658582626398, size = { 0.2285, 0.1792, 0.1494 } },
		["kit-legend"] = { mesh = 117838353973715, size = { 0.2925, 0.2798, 0.2358 } },
	},
	-- The family's Common piece is `length` body heights tall; its other tiers keep their size against it (the owner's
	-- higher tiers are bigger), and a Legendary one (another file, another scale) is LegendLength times the Common's.
	LegendLength = 1.12,
	-- The original's moves are in body widths; a body is this many heights wide.
	BodyWidth = 1.05,
	-- From the back to the hand (and back) in this long, as a fight begins and ends.
	DrawSeconds = 0.35,
	-- How much of its idle sway a weapon keeps on the back.
	RestSway = 0.3,
	-- The weapon's effects in the VFX library, per family, each with a variant a tier (docs/WEAPONS.md §9): the trail
	-- of a move while it plays, the burst at its head when a cast is let go, and the aura of the higher tiers in a fight.
	Fx = {
		Trail = "trail.weapon_",
		Cast = "burst.weapon_cast_",
		Aura = "aura.weapon_",
		AuraTiers = { core = true, bramble = true, legend = true },
		-- A plain blow as it lands on a foe: the family's own impact at its tier, over the mark. Its numbers are made
		-- for a body HitHeight studs tall: it is sized to the one struck.
		Hit = "hit.weapon_",
		HitHeight = 2.2,
	},
	Families = {
		-- `grip`: the point held, in the piece's own box (-0.5..0.5 a side); `muzzle`: where its shots and casts leave
		-- from, along its length (0 its middle, 0.5 its tip); `attack` and `cast` the moves (WeaponMoves).
		sword = {
			length = 0.95,
			grip = { 0, -0.36, 0 },
			muzzle = 0.5,
			attack = "swing",
			cast = "cleave",
			-- across the back, hilt up over the right shoulder (every slung piece leans the same way, its head up at the
			-- right, away from the kit's side)
			rest = { at = { 0, 0.55, 0.56 }, turn = { 0, 180, -140 } },
			-- in the right hand, the tip forward, the flat half turned to the camera behind
			fight = { at = { 0.62, 0.36, -0.08 }, turn = { -25, -50, 0 } },
		},
		shield = {
			length = 0.62,
			grip = { 0, 0, 0.5 },
			muzzle = 0,
			attack = "brace",
			cast = "bastion",
			rest = { at = { 0, 0.5, 0.56 }, turn = { 0, 180, -8 } },
			-- in front, its face to the foe, low and a little to the left so the eyes show over it
			fight = { at = { -0.15, 0.36, -0.62 }, turn = { 0, 12, 0 } },
		},
		bow = {
			length = 1,
			grip = { 0.4, 0, 0 },
			muzzle = 0,
			attack = "draw",
			cast = "volley",
			rest = { at = { 0, 0.55, 0.55 }, turn = { 0, 180, 38 } },
			-- in front, upright, the string to the slime, off the right eye
			fight = { at = { 0.42, 0.55, -0.6 }, turn = { 0, 90, 0 } },
		},
		focus = {
			length = 1,
			grip = { 0, -0.3, 0 },
			muzzle = 0.4,
			attack = "orbit",
			cast = "surge",
			rest = { at = { 0, 0.55, 0.56 }, turn = { 0, 180, 38 } },
			fight = { at = { 0.62, 0.4, -0.05 }, turn = { -10, -30, 0 } },
		},
		staff = {
			length = 1.25,
			grip = { 0, -0.2, 0 },
			muzzle = 0.45,
			attack = "raise",
			cast = "channel",
			rest = { at = { 0, 0.55, 0.56 }, turn = { 0, 180, 38 } },
			fight = { at = { 0.62, 0.4, -0.05 }, turn = { -8, -30, 0 } },
		},
		kit = {
			length = 0.5,
			grip = { 0, 0.45, 0 },
			muzzle = 0,
			attack = "shake",
			cast = "fling",
			-- always at the slime's left, hanging by its handle, its front outward
			rest = { at = { -0.6, 0.5, 0 }, turn = { 0, 90, 0 } },
			fight = { at = { -0.6, 0.52, -0.08 }, turn = { 0, 75, 0 } },
		},
	},
}
