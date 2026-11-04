--!strict
-- Plays an Egg Heist creature (a skinned MeshPart with its bones, from ReplicatedStorage.MonsterKit) by its own motion
-- module (Shared.Creatures.<name>, Shared.Creature): every frame it is told where its pivot is, which way it looks and
-- how fast it goes, and it poses its bones (legs plant their feet, wings beat, head looks about). Nothing is uploaded and
-- the rest pose is never touched: the bones turn through Bone.Transform. Taken from Egg Heist's client PetAnimator
-- (bindCreature, restOf, applyBones, input), the owner's earlier game.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Creature = require(ReplicatedStorage.Shared.Creature) :: any

local CreatureRig = {}

export type Rig = {
	bones: { Bone },
	turns: { CFrame },
	back: { CFrame },
	rig: any,
	state: any,
	input: { [string]: any },
	t0: number,
	speed: number,
}

-- The rest pose of every bone from the pivot (the ground under the middle of the part's box, as Egg Heist's pets stand):
-- the list a rig is made from (a bone is named by its number, `label` is its real name), and how each is turned at rest
-- and back.
local function restOf(part: BasePart, bones: { Bone })
	local ground = CFrame.new(0, part.Size.Y / 2, 0)
	local index: { [Bone]: number } = {}
	for i, bone in bones do
		index[bone] = i
	end
	local world: { [Instance]: CFrame } = {}
	local function rest(bone: Bone): CFrame
		local cached = world[bone]
		if cached then
			return cached
		end
		local parent = bone.Parent
		local base = if parent and parent:IsA("Bone") then rest(parent) else ground
		local cf = base * bone.CFrame
		world[bone] = cf
		return cf
	end
	local list, turns, back = {}, {}, {}
	for i, bone in bones do
		local cf = rest(bone)
		local at = cf.Position
		local parent = bone.Parent
		table.insert(list, {
			name = tostring(i),
			label = bone.Name,
			parent = if parent and parent:IsA("Bone") and index[parent] then tostring(index[parent]) else nil,
			x = at.X,
			y = at.Y,
			z = at.Z,
		})
		local turn = cf - at
		turns[i] = turn
		back[i] = turn:Inverse()
	end
	return list, turns, back
end

-- The creature of a skinned part by the module `name`, or nil and why (no module, no bones, a map that does not fit).
-- Bind it at the size it is drawn: the rig is read from the bones as they stand.
function CreatureRig.bind(part: BasePart, name: string, seed: number): (Rig?, string?)
	local def = Creature.find(name)
	if not def then
		return nil, "no motion module " .. name
	end
	local bones: { Bone } = {}
	for _, item in part:GetDescendants() do
		if item:IsA("Bone") then
			table.insert(bones, item)
		end
	end
	if #bones == 0 then
		return nil, "no bones"
	end
	local list, turns, back = restOf(part, bones)
	local rig, problem = Creature.rig(def, list)
	if not rig then
		return nil, problem
	end
	return {
		bones = bones,
		turns = turns,
		back = back,
		rig = rig,
		state = Creature.new(def, rig, { seed = seed }),
		input = { t = 0, x = 0, z = 0, yaw = 0, speed = 0, jump = false, air = 0, climb = 0 },
		t0 = seed * 100,
		speed = 0,
	},
		nil
end

-- One frame: `pivot` is where it stands now (the ground under the middle of its part, facing its way), `speed` how fast it goes (studs a second), `air` 1 for a flyer aloft.
function CreatureRig.step(r: Rig, dt: number, now: number, pivot: CFrame, speed: number, air: number)
	local input = r.input
	local look = pivot.LookVector
	-- (the speed measured frame by frame is smoothed, as Egg Heist does, so one late frame is not a stumble)
	r.speed += (speed - r.speed) * math.min(1, dt * 8)
	input.t = now + r.t0
	input.x, input.z, input.yaw, input.speed = pivot.X, pivot.Z, math.atan2(-look.X, -look.Z), r.speed
	input.jump, input.air, input.climb = false, air, 0
	Creature.step(r.state, dt, input)
	local pose = r.state.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local back, turns = r.back, r.turns
	local rootIndex = r.rig.root
	local bob, slideX, slideZ = pose.bob, pose.ox or 0, pose.oz or 0
	for i, bone in r.bones do
		local t = back[i] * (CFrame.fromEulerAnglesYXZ(rx[i], ry[i], rz[i]) * turns[i])
		if i == rootIndex and (bob ~= 0 or slideX ~= 0 or slideZ ~= 0) then
			t = CFrame.new(back[i] * Vector3.new(slideX, bob, slideZ)) * t
		end
		bone.Transform = t
	end
end

return CreatureRig
