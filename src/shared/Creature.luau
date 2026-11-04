-- Carried over from Egg Heist (C:\roblox 2nd game, the owner's earlier game; its docs/MOTION.md, Part 2, says how a
-- module is written): the dungeon's monsters are his Egg Heist creatures, moved by their own motion (client
-- CreatureRig plays them).
-- One module an animal: `Shared.Creatures.<name>` holds the joint map of ONE model and its own motion,
-- built from Shared.MotionKit. This is the little there is between such a module and whoever plays it.
--
-- The name of a module is the name of its model: `pet_<SpeciesId>` or `boss_<zoneId>`. Nobody lists them:
-- on Roblox a module is found in the folder by its name, in Lune the tests and the tools read the folder and
-- hand each over (`register`). A creature that has no module moves by the generic reader (Shared.RigMotion),
-- as before.
--
-- What a module is:
--   map       the joint map of its skinned model (MotionKit: `rig`), or
--   single    { pivot = { x, y, z } }: it is a model of ONE part with no bones; the pivot it turns about, in
--             shares of its box from the middle of it (y from the ground: 0.5 is the middle)
--   layer     "ground" (nil), "swim" or "fly": where it lives (Shared.PetLayer holds the height)
--   stroll    how it strolls in a plot (client PetWander): { froude (its walk, as a Froude number of its leg),
--             leg (its leg, a share of its height), or lengths (body lengths a second, for one that swims or
--             flies), rest = { least, most } seconds it stands between two strolls, radius (the tightest
--             circle it walks, in body lengths), cruise (true: it never stops, it glides from one place on to
--             the next) }
--   legs      the specs its legs were made from (the tools draw and measure them: `parts`)
--   new(rig, info)        its state; `info` = { seed (0 to 1, this one's own dice and clock) }. The state has
--                         `pose` (MotionKit.newPose) and may have `phase` (cycles of its stride or beat so far)
--   step(state, dt, input)   one frame: fills `state.pose`. `input` = { t (seconds on its own clock), x, z, yaw
--                         (where its pivot is in the world and which way it looks), speed (studs a second, as
--                         the client measures it), jump (it was put somewhere else), air (0 on the ground to 1
--                         in its layer), climb (studs a second it rises) } and, for a boss, what GuardianLife
--                         adds (state, prev, age, wake, look, lookX, lookY, lookZ, fresh: see Shared.BossKit).
local Kit = if script then require(script.Parent.MotionKit) else require("./MotionKit")
local FOUR_LEG_PACE = 1.5 -- (Egg Heist's Config.PetFourLegPace: the owner's pace for four-legged walkers)

local Creature = {}

local known = {} -- [name] = its module, false when it has none

-- Hands a module over (Lune: the tests and the tools read the folder themselves).
function Creature.register(name, def)
	known[name] = def
end

-- The module of a creature, nil when it has none.
function Creature.find(name)
	local def = known[name]
	if def ~= nil then
		return def or nil
	end
	local found = nil
	if script then
		local folder = script.Parent:FindFirstChild("Creatures")
		local module = folder and folder:FindFirstChild(name)
		if module then
			local ok, result = pcall(require, module)
			if ok and type(result) == "table" then
				found = result
			else
				warn(`[GooLineage] the motion of {name} could not be loaded: {result}`)
			end
		end
	end
	known[name] = found or false
	return found
end

-- The rig of a skinned model by the module's map: nil and why when the map does not fit these bones.
function Creature.rig(def, bones)
	if not def.map then
		return nil, "it has no joint map"
	end
	return Kit.rig(bones, def.map)
end

-- The rig of a model of one part: the size of its box and where the middle of it is, in the model's space.
function Creature.single(def, sx, sy, sz, cx, cy, cz)
	local single = def.single
	if not single then
		return nil
	end
	local pivot = single.pivot or { 0, 0.5, 0 }
	local rig = Kit.single(sx, sy, sz, cx + pivot[1] * sx, (cy - sy / 2) + pivot[2] * sy, cz + pivot[3] * sz)
	rig.cx, rig.cy, rig.cz = cx, cy, cz
	return rig
end

function Creature.new(def, rig, info)
	local state = def.new(rig, info or {})
	state.def, state.rig = def, rig
	state.pose = state.pose or Kit.newPose(rig)
	return state
end

function Creature.step(state, dt, input)
	state.def.step(state, dt, input)
end

-- How it strolls: { speed (studs a second), rest = { least, most }, radius (studs), cruise }, nil when the
-- module says nothing (the stroll of old).
function Creature.stroll(def, rig)
	local stroll = def.stroll
	if not stroll then
		return nil
	end
	local length = rig.length or rig.height
	local speed
	if stroll.lengths then
		speed = stroll.lengths * length
	else
		speed = math.sqrt((stroll.froude or 0.08) * Kit.G * (stroll.leg or 0.5) * rig.height)
		-- The owner (2026-10-13): the four-legged ones stroll half as fast again as their modules were tuned
		-- for (a longer step at the same look); the others keep their pace. A walker on the ground only (the
		-- Hippocampus has four legs and swims), and a module may say its own `pace` (a hopper: 1).
		local legs = 0
		local map = def.map
		if map and (def.layer or "ground") == "ground" then
			for _ in map.legs or {} do
				legs += 1
			end
			for _, limb in map.limbs or {} do
				if limb.role == "leg" then
					legs += 1
				end
			end
		end
		if legs == 4 then
			speed *= stroll.pace or FOUR_LEG_PACE
		end
	end
	return {
		speed = speed,
		rest = stroll.rest or { 3, 8 },
		radius = (stroll.radius or 0.8) * length,
		cruise = stroll.cruise == true,
	}
end

-- What the module takes each bone for, for the tools: { roles = { [bone] = role }, head, tail = { bones },
-- limbs = { { kind, name, bones (first to the point that is planted) } } }.
function Creature.parts(def, rig)
	local label = rig.label
	local roles = {}
	for i = 1, rig.n do
		roles[label[i]] = if rig.role[i] == "rigid" then "extra" else rig.role[i]
	end
	local parts = { roles = roles, limbs = {}, tail = {} }
	local head = rig.chains["the head"]
	if head then
		parts.head = label[head[#head]]
	end
	for _, i in rig.chains["the tail"] or {} do
		table.insert(parts.tail, label[i])
	end
	for _, spec in def.legs or {} do
		local bones = {}
		for _, name in spec.chain do
			table.insert(bones, label[rig.at[name]])
			if name == spec.contact then
				break
			end
		end
		table.insert(parts.limbs, { kind = "leg", name = spec.name or spec.id, bones = bones })
	end
	return parts
end

return Creature
