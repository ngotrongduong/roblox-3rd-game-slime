-- The monster slimes' sampled actions (src/shared/MonsterClips, tools/blender/monster_clips.py) and their player
-- (shared/MonsterClip): every monster's data unpacks whole, its loops join, its moves stay a real pose; the player walks
-- while it moves, plays a one-off and comes back, never stops dying, and blends a switch.
local Config = require("../../src/shared/Config")
local MonsterClip = require("../../src/shared/MonsterClip")
local fs = require("@lune/fs")

local DIR = "src/shared/MonsterClips"

local function names(): { string }
	local list = {}
	if fs.isDir(DIR) then
		for _, file in fs.readDir(DIR) do
			if string.sub(file, -5) == ".luau" then
				table.insert(list, string.sub(file, 1, -6))
			end
		end
	end
	table.sort(list)
	return list
end

local function load(name: string): MonsterClip.Data
	return (require :: any)("../../src/shared/MonsterClips/" .. name)
end

-- A tiny monster of one bone: Idle stands, Move lifts it 1 stud half way, Attack pushes it forward, Hit and Die tip it.
local function fake(): MonsterClip.Data
	local function action(length: number, loop: boolean, low: number, span: number, codes: string): MonsterClip.Action
		return {
			length = length,
			loop = loop,
			frames = #codes // 2,
			ranges = { 0, 0, low, span, 0, 0, 0, 0, 0, 0, 0, 0 },
			data = codes,
		}
	end
	-- (the code "AA" is the low end, "//" the high end, "f/" about half way)
	return {
		height = 2,
		hover = 0,
		peak = 0.2,
		bones = { "Body" },
		actions = {
			Idle = action(1, true, 0, 0, ""),
			Move = action(1, true, 0, 1, "AA//AA"),
			Attack = action(0.5, false, 0, 1, "AA//"),
			Hit = action(0.4, false, -1, 1, "//AA"),
			Die = action(1, false, -1, 1, "//AA"),
		},
	}
end

return function(T: any)
	T.test("a monster's samples unpack: ends, middle, loops wrap and one-offs hold", function()
		local set = MonsterClip.set(fake())
		T.ok(MonsterClip.sample(set, "Move", 0)[2] == 0, "Move starts at 0")
		T.ok(math.abs(MonsterClip.sample(set, "Move", 0.5)[2] - 1) < 1e-9, "Move peaks half way")
		T.ok(math.abs(MonsterClip.sample(set, "Move", 0.25)[2] - 0.5) < 1e-9, "between two frames it blends")
		T.ok(math.abs(MonsterClip.sample(set, "Move", 1.5)[2] - 1) < 1e-9, "a loop wraps round")
		T.ok(math.abs(MonsterClip.sample(set, "Attack", 9)[2] - 1) < 1e-9, "a one-off holds its last frame")
		T.ok(MonsterClip.sample(set, "Idle", 0.3)[2] == 0, "a still channel is its value")
	end)

	T.test("the player walks while it moves and stands when it stops", function()
		local p = MonsterClip.new(MonsterClip.set(fake()), 0, 0)
		MonsterClip.step(p, 0, 1 / 60, false)
		T.ok(p.action == "Idle", "it starts standing")
		MonsterClip.step(p, 0.1, 1 / 60, true)
		T.ok(p.action == "Move", "a step starts the walk")
		MonsterClip.step(p, 0.2, 0.1, false)
		T.ok(p.action == "Move", "a short pause between hops is no stop")
		MonsterClip.step(p, 0.6, 0.4, false)
		T.ok(p.action == "Idle", "a real stop stands")
	end)

	T.test("a one-off plays, then the monster goes back; a fade blends the switch", function()
		local p = MonsterClip.new(MonsterClip.set(fake()), 0, 0)
		T.ok(MonsterClip.play(p, "Attack", 1, 0) == 0.5, "Attack plays and says its length")
		local blended = MonsterClip.step(p, 1 + MonsterClip.Fade / 2, 1 / 60, false)[2]
		local whole = MonsterClip.sample(p.set, "Attack", MonsterClip.Fade / 2)[2]
		T.ok(math.abs(blended - whole / 2) < 1e-6, "half way through the fade it is half the attack " .. blended)
		MonsterClip.step(p, 1.6, 1 / 60, false)
		T.ok(p.action == "Idle", "after its length it stands again")
		T.ok(MonsterClip.play(p, "Spin", 2, 0) == 0, "an action it does not have does not play")
	end)

	T.test("dying outranks everything and holds", function()
		local p = MonsterClip.new(MonsterClip.set(fake()), 0, 0)
		MonsterClip.play(p, "Hit", 0, 0)
		T.ok(MonsterClip.play(p, "Attack", 0.1, 0) == 0, "a hit is not cut by an attack")
		T.ok(MonsterClip.play(p, "Die", 0.2, 0) == 1, "dying cuts a hit")
		T.ok(MonsterClip.play(p, "Hit", 0.3, 0) == 0, "nothing cuts dying")
		local pose = MonsterClip.step(p, 9, 1 / 60, true)
		T.ok(p.action == "Die" and math.abs(pose[2] + 1) < 1e-9, "long after, it still lies as it fell")
	end)

	T.test("every monster slime's data is whole and its moves a real pose", function()
		local list = names()
		for _, name in list do
			local data = load(name)
			local ok, set = pcall(MonsterClip.set, data)
			T.ok(ok, name .. " unpacks (" .. tostring(set) .. ")")
			if ok then
				T.ok(data.height > 0 and data.hover >= 0 and data.peak > 0, name .. " height, hover, peak")
				for _, action in MonsterClip.Actions do
					local clip = set.clips[action]
					T.ok(clip ~= nil, name .. " has " .. action)
					if clip then
						T.ok(
							#data.actions[action].ranges == 12 * #data.bones,
							name .. "." .. action .. " a range a channel"
						)
						T.ok(
							clip.loop == (action == "Idle" or action == "Move"),
							name .. "." .. action .. " loops or not"
						)
						local first = MonsterClip.sample(set, action, 0)
						local last = MonsterClip.sample(set, action, clip.length - 1e-9)
						local sane, gap = true, 0
						for t = 0, clip.length, 1 / 30 do
							for i, v in MonsterClip.sample(set, action, t) do
								local limit = if (i - 1) % 6 < 3 then 2 * data.height else math.pi
								sane = sane and v == v and math.abs(v) <= limit
							end
						end
						for i, v in first do
							gap = math.max(gap, math.abs(v - last[i]))
						end
						T.ok(sane, name .. "." .. action .. " stays a real pose")
						if clip.loop then
							T.ok(gap < 0.02, name .. "." .. action .. " joins its loop (" .. gap .. ")")
						end
					end
				end
				T.ok(data.peak < set.clips.Attack.length, name .. " lands its blow inside its attack")
			end
		end
	end)

	T.test("every look that plays clips names data that is there", function()
		local have = {}
		for _, name in names() do
			have[name] = true
		end
		for id, look in Config.Dungeon.Looks :: any do
			if look.clips then
				T.ok(have[look.clips] == true, id .. ": src/shared/MonsterClips/" .. look.clips .. ".luau")
				T.ok(type(look.mesh) == "number" and type(look.texture) == "number", id .. " mesh and texture ids")
				T.ok(look.height > 0 and look.motion == nil and look.pieces == nil, id .. " height, one kind of look")
			end
		end
	end)
end
