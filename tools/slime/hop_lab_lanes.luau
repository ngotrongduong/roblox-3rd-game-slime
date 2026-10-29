--!nocheck
-- The movement lab's lanes: ONE table, the source of both the motion (hop_lab_client.luau) and the sign text on the
-- floor (hop_lab.luau), so what the owner reads is what he sees. Installed as ModuleScript
-- StarterPlayerScripts.SlimeMotionLab.Lanes by tools/slime/hop_lab.ps1.
--
-- The numbers are named as in Config.Slime so a choice goes straight into Config (lengths in body heights; a slime is
-- 3 studs high here, as the largest village slime, Config.VillageClient.BodyHeight):
--   hop      HopHeight  (Config.VillageClient.HopHeight)  height of a hop, body heights
--            HopStuds   (Config.Village.HopStuds)         distance of one hop, studs
--            Rest       seconds standing still after a landing before the next crouch (the village uses the
--                       remainder of Config.Village.HopSeconds = 0.55 minus crouch minus air time, about 0.04)
--            Ease       true = the hop's travel eases in and out (the village's VillagePath.progress does);
--                       false = constant speed through the air (what a thrown body does)
--            HopLean    forward tip while airborne, in body heights, with a small rock back in the crouch (new)
--   physics  Gravity, CrouchSeconds, CrouchSquash, AirStretch, LandKick, SquashHz, SquashDamping, LeanHz,
--            LeanDamping, VolumeBulge (all Config.Slime)
--   glide    GlideSpeed studs/s, GlideBob squash wave while it slides, GlideBobHz, GlideLean forward tip (new)
-- EndIdle: seconds the slime stands at the end of a lane (it turns round in the middle of it).
-- Colours are the swatches of src/shared/Colours.luau.

local Lanes = {}

Lanes.Length = 40 -- studs from one end of a lane to the other
Lanes.Spacing = 9 -- studs between lanes
Lanes.EndIdle = 1.6
Lanes.TurnSeconds = 0.18 -- time constant of the smooth turn at the ends

Lanes.List = {
	{
		key = "A",
		name = "Gentle",
		colour = "#f27fb6", -- pink
		mode = "hop",
		HopHeight = 0.15,
		HopStuds = 1.2,
		Rest = 0.25,
		Ease = false,
		HopLean = 0.04,
		Gravity = 9,
		CrouchSeconds = 0.16,
		CrouchSquash = -0.18,
		AirStretch = 0.08,
		LandKick = 2,
		SquashHz = 2.8,
		SquashDamping = 0.35,
		LeanHz = 2.2,
		LeanDamping = 0.4,
		VolumeBulge = 0.55,
	},
	{
		key = "B",
		name = "Bouncy",
		colour = "#f08a24", -- orange
		mode = "hop",
		HopHeight = 0.45,
		HopStuds = 2.5,
		Rest = 0.1,
		Ease = false,
		HopLean = 0.08,
		Gravity = 14,
		CrouchSeconds = 0.1,
		CrouchSquash = -0.32,
		AirStretch = 0.18,
		LandKick = 3.5,
		SquashHz = 4,
		SquashDamping = 0.2,
		LeanHz = 2.6,
		LeanDamping = 0.35,
		VolumeBulge = 0.55,
	},
	{
		key = "C",
		name = "Heavy jelly",
		colour = "#8a4fd0", -- purple
		mode = "hop",
		HopHeight = 0.22,
		HopStuds = 1.6,
		Rest = 0.3,
		Ease = false,
		HopLean = 0.03,
		Gravity = 12,
		CrouchSeconds = 0.22,
		CrouchSquash = -0.38,
		AirStretch = 0.05,
		LandKick = 4.5,
		SquashHz = 2.2,
		SquashDamping = 0.22,
		LeanHz = 1.8,
		LeanDamping = 0.4,
		VolumeBulge = 0.7,
	},
	{
		key = "D",
		name = "Quick hops",
		colour = "#f2d13d", -- yellow
		mode = "hop",
		HopHeight = 0.12,
		HopStuds = 1,
		Rest = 0.02,
		Ease = false,
		HopLean = 0.05,
		Gravity = 18,
		CrouchSeconds = 0.06,
		CrouchSquash = -0.16,
		AirStretch = 0.1,
		LandKick = 1.8,
		SquashHz = 4.5,
		SquashDamping = 0.4,
		LeanHz = 3,
		LeanDamping = 0.45,
		VolumeBulge = 0.5,
	},
	{
		key = "E",
		name = "Big leaps",
		colour = "#54b848", -- green
		mode = "hop",
		HopHeight = 0.8,
		HopStuds = 4.5,
		Rest = 0.4,
		Ease = false,
		HopLean = 0.12,
		Gravity = 12,
		CrouchSeconds = 0.22,
		CrouchSquash = -0.34,
		AirStretch = 0.2,
		LandKick = 3.5,
		SquashHz = 3.2,
		SquashDamping = 0.25,
		LeanHz = 2.2,
		LeanDamping = 0.35,
		VolumeBulge = 0.55,
	},
	{
		key = "F",
		name = "Slow and soft",
		colour = "#3f9ff0", -- blue
		mode = "hop",
		HopHeight = 0.2,
		HopStuds = 1.4,
		Rest = 0.45,
		Ease = true,
		HopLean = 0.05,
		Gravity = 5,
		CrouchSeconds = 0.3,
		CrouchSquash = -0.2,
		AirStretch = 0.1,
		LandKick = 1.5,
		SquashHz = 2,
		SquashDamping = 0.3,
		LeanHz = 1.6,
		LeanDamping = 0.4,
		VolumeBulge = 0.55,
	},
	{
		key = "G",
		name = "Glide (no hops)",
		colour = "#9aa0a8", -- gray
		mode = "glide",
		GlideSpeed = 2,
		GlideBob = 0.035,
		GlideBobHz = 2.2,
		GlideLean = 0.07,
		-- (the springs that make the body wobble when it starts and stops)
		HopHeight = 0,
		HopStuds = 0,
		Rest = 0,
		Ease = false,
		HopLean = 0,
		Gravity = 10,
		CrouchSeconds = 0,
		CrouchSquash = 0,
		AirStretch = 0,
		LandKick = 0,
		SquashHz = 3,
		SquashDamping = 0.35,
		LeanHz = 2.2,
		LeanDamping = 0.4,
		VolumeBulge = 0.55,
	},
	{
		key = "H",
		name = "Current",
		colour = "#1b4fd8", -- navy
		mode = "hop",
		HopHeight = 0.18, -- Config.VillageClient.HopHeight
		HopStuds = 1.5, -- Config.Village.HopStuds
		Rest = 0.04, -- HopSeconds 0.55 - crouch 0.13 - air 0.38
		Ease = true,
		HopLean = 0,
		Gravity = 10,
		CrouchSeconds = 0.13,
		CrouchSquash = -0.26,
		AirStretch = 0.12,
		LandKick = 3,
		SquashHz = 3.2,
		SquashDamping = 0.28,
		LeanHz = 2.2,
		LeanDamping = 0.4,
		VolumeBulge = 0.55,
	},
}

-- Seconds in the air for a hop of this height.
function Lanes.airSeconds(p)
	return math.sqrt(8 * p.HopHeight / p.Gravity)
end

-- The small lines on the sign: the hop, the speed, the physics, the wobble.
function Lanes.describe(p)
	if p.mode == "glide" then
		return {
			("glide %.1f studs/s   lean %.2f"):format(p.GlideSpeed, p.GlideLean),
			("bob %.3f at %.1f Hz"):format(p.GlideBob, p.GlideBobHz),
			("wobble %.1f Hz damp %.2f"):format(p.SquashHz, p.SquashDamping),
			("lean %.1f Hz damp %.2f   bulge %.2f"):format(p.LeanHz, p.LeanDamping, p.VolumeBulge),
		}
	end
	local cycle = p.CrouchSeconds + Lanes.airSeconds(p) + p.Rest
	return {
		("height %.2f   %.1f studs a hop   rest %.2fs"):format(p.HopHeight, p.HopStuds, p.Rest),
		("%.2fs a hop = %.1f studs/s   travel %s   lean %.2f"):format(
			cycle,
			p.HopStuds / cycle,
			if p.Ease then "eased" else "even",
			p.HopLean
		),
		("gravity %g   crouch %.2fs %.2f   stretch %.2f   kick %g"):format(
			p.Gravity,
			p.CrouchSeconds,
			p.CrouchSquash,
			p.AirStretch,
			p.LandKick
		),
		("wobble %.1f Hz damp %.2f   bulge %.2f"):format(p.SquashHz, p.SquashDamping, p.VolumeBulge),
	}
end

return Lanes
