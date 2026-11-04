-- The monsters' looks in Config.Dungeon.Looks: every Sunny Meadow monster is an Egg Heist creature in the kit whose own
-- motion fits its bones and walks; and the piece motion (shared/MonsterMotion): every piece turns about a real axis, the
-- two halves of a pair run apart, and walking legs rest when standing.
local Config = require("../../src/shared/Config")
local MonsterMotion = require("../../src/shared/MonsterMotion")
local Creature = require("../../src/shared/Creature") :: any
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local CFrame = roblox.CFrame

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

	T.test("every Sunny Meadow monster's Egg Heist creature is in the kit and walks by its own motion", function()
		local kit = roblox.deserializeModel(fs.readFile("assets/MonsterKit.rbxm"))[1]
		for _, def in D.Maps.meadow.monsters do
			local look = D.Looks[def.id]
			T.ok(look ~= nil, "a look for " .. def.id)
			if look and look.motion then
				T.ok(type(look.model) == "string" and look.height > 0, def.id .. " model and height")
				local motion = require("../../src/shared/Creatures/" .. look.motion) :: any
				Creature.register(look.motion, motion)
				local model = kit:FindFirstChild(look.model)
				T.ok(model ~= nil, def.id .. ": " .. look.model .. " in assets/MonsterKit.rbxm")
				if model then
					local part = model.PrimaryPart or model:FindFirstChildWhichIsA("MeshPart")
					-- the bones as CreatureRig reads them: each from the ground under the middle of the part, named by
					-- its number
					local ground = CFrame.new(0, part.Size.Y / 2, 0)
					local bones, index, world = {}, {}, {}
					for _, item in part:GetDescendants() do
						if item:IsA("Bone") then
							table.insert(bones, item)
							index[item] = #bones
						end
					end
					local function rest(bone)
						if not world[bone] then
							local parent = bone.Parent
							world[bone] = (if parent:IsA("Bone") then rest(parent) else ground) * bone.CFrame
						end
						return world[bone]
					end
					local list = {}
					for i, bone in bones do
						local at = rest(bone).Position
						local parent = index[bone.Parent]
						list[i] = {
							name = tostring(i),
							label = bone.Name,
							parent = if parent then tostring(parent) else nil,
							x = at.X,
							y = at.Y,
							z = at.Z,
						}
					end
					local rig, problem = Creature.rig(motion, list)
					T.ok(rig ~= nil, def.id .. ": the motion fits the model (" .. tostring(problem) .. ")")
					if rig then
						local state = Creature.new(motion, rig, { seed = 0.3 })
						local input = { t = 0, x = 0, z = 0, yaw = 0, speed = 0, jump = false, air = 0, climb = 0 }
						input.air = if (look.hover or 0) > 0 then 1 else 0
						local fine = true
						for frame = 1, 120 do
							input.t = frame / 60
							-- (the kit's models stand under 2 studs: a stroll at their own size)
							input.speed = if frame > 30 then 1 else 0
							input.z -= input.speed / 60
							Creature.step(state, 1 / 60, input)
							for _, angle in state.pose.rx do
								fine = fine and angle == angle and math.abs(angle) < 10
							end
						end
						T.ok(fine, def.id .. ": its pose stays a real pose while it stands and walks")
					end
				end
			end
		end
	end)

	T.test("a look of rigid pieces has sane pieces", function()
		for id, look in D.Looks do
			if look.pieces then
				local def = { id = id }
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
