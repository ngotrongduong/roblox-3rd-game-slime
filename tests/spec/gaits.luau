local Config = require("../../src/shared/Config")
local Gaits = require("../../src/shared/Gaits")
local Path = require("../../src/shared/VillagePath")

local function info(kind, emotion, extra)
	local i = { kind = kind, emotion = emotion, baby = false, tired = false, hungry = false }
	for k, v in extra or {} do
		i[k] = v
	end
	return i
end

return function(T)
	T.test("the gait follows what the slime is doing and feeling", function()
		T.eq(Gaits.choose(info("work", "proud")), "walk")
		T.eq(Gaits.choose(info("carryBox", "proud")), "walk")
		T.eq(Gaits.choose(info("chat", "happy")), "walk")
		T.eq(Gaits.choose(info("wander", "normal")), "stroll")
		T.eq(Gaits.choose(info("watchFish", "curious")), "stroll")
		T.eq(Gaits.choose(info("flowers", "happy")), "stroll")
		T.eq(Gaits.choose(info("splash", "laughing")), "stroll")
		T.eq(Gaits.choose(info("warm", "full")), "stroll")
		T.eq(Gaits.choose(info("court", "loved")), "stroll")
	end)

	T.test("tired, hungry and sad slimes glide, and needs beat the stroll", function()
		T.eq(Gaits.choose(info("work", "proud", { tired = true })), "glide")
		T.eq(Gaits.choose(info("eat", "hungry", { hungry = true })), "glide")
		T.eq(Gaits.choose(info("wander", "normal", { hungry = true })), "glide")
		for _, feeling in { "sad", "sulking", "crying", "bored" } do
			T.eq(Gaits.choose(info("wander", feeling)), "glide")
		end
	end)

	T.test("babies walk gently and hurry quickly, whatever they feel", function()
		T.eq(Gaits.choose(info("nursery", "curious", { baby = true })), "baby")
		T.eq(Gaits.choose(info("walkBaby", "happy", { baby = true })), "babyQuick")
		T.eq(Gaits.choose(info("playBaby", "happy", { baby = true })), "babyQuick")
		T.eq(Gaits.choose(info("feedBaby", "loved", { baby = true, hungry = true })), "baby")
	end)

	T.test("a leg takes whole hops of the gait's cycle", function()
		for _, name in { "walk", "stroll", "baby", "babyQuick", "bouncy", "heavy" } do
			local g = Config.Gaits[name]
			local cycle = g.CrouchSeconds + math.sqrt(8 * g.HopHeight / g.Gravity) + g.Rest
			T.near(Path.cycle(name), cycle, 1e-9)
			-- three and a bit hop lengths make four hops
			T.near(Path.duration(g.HopStuds * 3.2, 1, name), 4 * cycle, 1e-9)
			T.near(Path.duration(g.HopStuds * 2.9, 1, name), 3 * cycle, 1e-9)
			-- a faster slime (speed factor 2) needs half the hops
			T.near(Path.duration(g.HopStuds * 3.9, 2, name), 2 * cycle, 1e-9)
		end
		T.eq(Path.duration(0, 1, "walk"), 0)
	end)

	T.test("the walk covers ground faster than the stroll, and the baby gaits are slower", function()
		T.ok(Path.speed("walk", 1) > Path.speed("stroll", 1))
		T.ok(Path.speed("walk", 1) > Path.speed("baby", 1))
		T.near(Path.speed("glide", 1), Config.Gaits.glide.GlideSpeed, 1e-9)
		T.near(Path.speed("glide", 1.5), Config.Gaits.glide.GlideSpeed * 1.5, 1e-9)
	end)

	T.test("a glide covers its distance in distance over speed plus one ramp, and eases at both ends", function()
		local g = Config.Gaits.glide
		local length = 10
		local duration = Path.duration(length, 1, "glide")
		T.near(duration, length / g.GlideSpeed + g.GlideRampSeconds, 1e-9)
		T.near(Path.progress(100, 100 + duration, 100, "glide"), 0, 1e-9)
		T.near(Path.progress(100, 100 + duration, 100 + duration, "glide"), 1, 1e-9)
		-- between the ramps it moves at its cruise speed
		local mid = Path.progress(100, 100 + duration, 100 + duration / 2, "glide")
		local later = Path.progress(100, 100 + duration, 100 + duration / 2 + 0.5, "glide")
		T.near((later - mid) * length / 0.5, g.GlideSpeed, 1e-6)
		-- never backwards
		local last = 0
		for i = 0, 100 do
			local p = Path.progress(100, 100 + duration, 100 + duration * i / 100, "glide")
			T.ok(p >= last - 1e-9)
			last = p
		end
		T.near(Path.glideSpeedFraction(100, 100 + duration, 100 + duration / 2, "glide"), 1, 1e-9)
		T.near(Path.glideSpeedFraction(100, 100 + duration, 100, "glide"), 0, 1e-9)
		T.near(Path.glideSpeedFraction(100, 100 + duration, 100, "walk"), 0, 1e-9)
	end)

	T.test("the speed stat's factor", function()
		T.near(Gaits.factor(Config.Stats.Starter.speed), 1, 1e-9)
		T.ok(Gaits.factor(Config.Stats.Starter.speed + 10) > 1)
	end)
end
