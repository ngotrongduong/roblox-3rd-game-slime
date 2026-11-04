-- The monsters' piece motion (shared/MonsterMotion) and their looks in Config.Dungeon.Looks: every Sunny Meadow monster
-- has one, every piece turns about a real axis, the two halves of a pair run apart, and walking legs rest when standing.
local Config = require("../../src/shared/Config")
local MonsterMotion = require("../../src/shared/MonsterMotion")

local D = Config.Dungeon

return function(T: any)
	T.test("a piece swings its full amplitude and back", function()
		local piece = { axis = "z", amp = 30, hz = 1 }
		local _, _, top = MonsterMotion.angles(piece, 0.25, false, 0)
		local _, _, bottom = MonsterMotion.angles(piece, 0.75, false, 0)
		T.ok(math.abs(top - math.rad(30)) < 1e-6, "top " .. top)
		T.ok(math.abs(bottom + math.rad(30)) < 1e-6, "bottom " .. bottom)
	end)

	T.test("the axis picks which way it turns, the sign mirrors it", function()
		local x, y, z = MonsterMotion.angles({ axis = "x", amp = 20, hz = 1 }, 0.25, false, 0)
		T.ok(x > 0 and y == 0 and z == 0, "pitch")
		local _, yaw = MonsterMotion.angles({ axis = "y", amp = 20, hz = 1 }, 0.25, false, 0)
		T.ok(yaw > 0, "yaw")
		local _, _, left = MonsterMotion.angles({ axis = "z", amp = 20, hz = 1, sign = -1 }, 0.25, false, 0)
		T.ok(left < 0, "mirrored")
	end)

	T.test("a walking leg rests to a breath while the monster stands", function()
		local leg = { axis = "x", amp = 20, hz = 1, walk = true }
		local standing = MonsterMotion.angles(leg, 0.25, false, 0)
		local walking = MonsterMotion.angles(leg, 0.25, true, 0)
		T.ok(math.abs(standing - walking * MonsterMotion.IdleShare) < 1e-6, "standing " .. standing)
	end)

	T.test("an attack throws the hit in", function()
		local ear = { axis = "z", amp = 0, hz = 1, hit = 25 }
		local _, _, calm = MonsterMotion.angles(ear, 0, false, 0)
		local _, _, flick = MonsterMotion.angles(ear, 0, false, 1)
		T.ok(calm == 0 and math.abs(flick - math.rad(25)) < 1e-6, "flick " .. flick)
	end)

	T.test("every Sunny Meadow monster has a look with sane pieces", function()
		for _, def in D.Maps.meadow.monsters do
			local look = D.Looks[def.id]
			T.ok(look ~= nil, "a look for " .. def.id)
			if look then
				T.ok(type(look.model) == "string" and look.height > 0, def.id .. " model and height")
				T.ok(#look.min == 3, def.id .. " min corner")
				for name, piece in look.pieces do
					T.ok(#piece.joint == 3, def.id .. "." .. name .. " joint")
					T.ok(piece.axis == "x" or piece.axis == "y" or piece.axis == "z", def.id .. "." .. name .. " axis")
					T.ok(piece.sign == nil or piece.sign == 1 or piece.sign == -1, def.id .. "." .. name .. " sign")
					T.ok(
						(piece.amp or 0) <= 45 and (piece.hz or 0) <= 20,
						def.id .. "." .. name .. " a believable swing"
					)
				end
			end
		end
	end)
end
