--!strict
-- The dungeon's positional fight: fighters walk into reach at a speed from their SPD before they aim, ranged ones stop at
-- range, they keep apart, and a fight that is not positional (zombies, the Arena) is as it was.
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local Rng = require("../../src/shared/Rng")

local M = Config.Dungeon.Move
local DT = Config.Zombies.FightStepSeconds

local function fighter(id: string, speed: number, x: number, z: number, kind: string?): any
	return { id = id, attack = 1, defence = 0, speed = speed, hp = 1e6, kind = kind or "melee", x = x, z = z }
end

-- Steps until the first "aim" of `from`; returns the seconds, and the moves seen.
local function untilAim(fight: any, from: string): (number?, { any })
	local moves: { any } = {}
	for _ = 1, 4000 do
		for _, event in Combat.step(fight, DT) do
			if event.kind == "move" then
				table.insert(moves, event)
			elseif event.kind == "aim" and event.from == from then
				return fight.seconds, moves
			end
		end
	end
	return nil, moves
end

local function unitOf(fight: any, id: string): any
	for _, unit in fight.units do
		if unit.id == id then
			return unit
		end
	end
	error("no unit " .. id)
end

return function(T: any)
	T.test("walk speed rises with SPD up to the cap", function()
		T.eq(Combat.walkSpeed(0), M.BaseStuds)
		T.ok(Combat.walkSpeed(1) > Combat.walkSpeed(0))
		T.ok(Combat.walkSpeed(10) > Combat.walkSpeed(1))
		T.eq(Combat.walkSpeed(99), M.MaxStuds)
		-- a starter walks a few studs a second, no faster than a dash
		T.ok(Combat.walkSpeed(1) >= 3 and Combat.walkSpeed(1) <= 6)
	end)

	T.test("a far melee fighter walks into reach before it aims, in distance over speed", function()
		local far = 60
		local fight = Combat.new({ fighter("s", 1, 0, 0) }, { fighter("f", 0, far, 0) }, Rng.new(3), { moves = true })
		local seconds, moves = untilAim(fight, "s")
		T.ok(seconds ~= nil, "it aims in the end")
		local s = unitOf(fight, "s")
		local f = unitOf(fight, "f")
		T.ok(#moves > 0, "a move event went out")
		T.eq(moves[1].from, "s")
		-- at the aim it is in reach, and it walked about as long as the distance asked
		local gap = math.sqrt((s.x - f.x) ^ 2 + (s.z - f.z) ^ 2)
		T.ok(gap <= M.MeleeStuds + 1e-3, "in reach when it aims: " .. gap)
		-- (the foe walks to meet it: they close the distance together)
		local walked = (far - M.MeleeStuds) / (Combat.walkSpeed(1) + Combat.walkSpeed(0, true))
		T.ok(
			math.abs((seconds :: number) - walked) < 0.5,
			"arrived about on time: " .. tostring(seconds) .. " vs " .. walked
		)
	end)

	T.test("a faster SPD arrives sooner", function()
		local function arrival(speed: number): number
			local fight = Combat.new(
				{ fighter("s", speed, 0, 0) },
				{ fighter("f", 0, 60, 0) },
				Rng.new(3),
				{ moves = true }
			)
			local seconds = untilAim(fight, "s")
			return seconds :: number
		end
		T.ok(arrival(30) < arrival(10))
		T.ok(arrival(10) < arrival(1))
	end)

	T.test("nothing strikes before it has walked into reach", function()
		local fight = Combat.new({ fighter("s", 1, 0, 0) }, { fighter("f", 1, 60, 0) }, Rng.new(5), { moves = true })
		local struck: number? = nil
		for _ = 1, 4000 do
			for _, event in Combat.step(fight, DT) do
				if (event.kind == "hit" or event.kind == "dodge") and not struck then
					struck = fight.seconds
				end
			end
			if struck then
				break
			end
		end
		T.ok(struck ~= nil)
		-- the two close the 60 studs between them at their walking speeds (the monster's FoeGain faster): not before that
		T.ok(
			(struck :: number) > (60 - M.MeleeStuds) / (Combat.walkSpeed(1) + Combat.walkSpeed(1, true)) - 0.5,
			"struck at " .. tostring(struck)
		)
	end)

	T.test("a ranged fighter stops at its range, further than a melee one", function()
		local fight = Combat.new(
			{ fighter("s", 1, 0, 0) },
			{ fighter("f", 0, 60, 0, "ranged") },
			Rng.new(3),
			{ moves = true }
		)
		local seconds = untilAim(fight, "f")
		T.ok(seconds ~= nil)
		local s, f = unitOf(fight, "s"), unitOf(fight, "f")
		local gap = math.sqrt((s.x - f.x) ^ 2 + (s.z - f.z) ^ 2)
		T.ok(gap > M.MeleeStuds + 1 and gap <= M.RangedStuds + 1e-3, "stopped at range: " .. gap)
	end)

	T.test("fighters aiming at one target keep apart", function()
		local squad = {}
		for index = 1, 4 do
			table.insert(squad, fighter("s" .. index, 1, (index - 2.5) * 4.2, 0))
		end
		local fight = Combat.new(squad, { fighter("f", 0, 50, 0) }, Rng.new(8), { moves = true })
		unitOf(fight, "f").hp = 1e9
		for _ = 1, 400 do
			Combat.step(fight, DT)
		end
		for _, a in fight.units do
			for _, b in fight.units do
				if a.id < b.id and a.side == "squad" and b.side == "squad" then
					local gap = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
					T.ok(gap >= M.MinApart - 0.5, a.id .. " and " .. b.id .. " stand " .. gap .. " apart")
				end
			end
		end
	end)

	T.test("every blow lands in reach, also after its target fell and a new one was picked", function()
		local squad = {}
		for index = 1, 3 do
			table.insert(squad, fighter("s" .. index, 3, (index - 2) * 4.2, 0))
		end
		local foes = {}
		for index = 1, 6 do
			local foe = fighter("f" .. index, 1, (index - 3.5) * 9, 45)
			foe.hp = 3
			table.insert(foes, foe)
		end
		local fight = Combat.new(squad, foes, Rng.new(11), { moves = true })
		local blows = 0
		for _ = 1, 6000 do
			for _, event in Combat.step(fight, DT) do
				if (event.kind == "hit" or event.kind == "dodge") and event.from and not event.splash then
					local a, b = unitOf(fight, event.from :: string), unitOf(fight, event.to)
					local gap = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
					T.ok(gap <= M.MeleeStuds + M.BlowSlack + 1e-3, event.from .. " struck from " .. gap)
					blows += 1
				end
			end
			if fight.winner then
				break
			end
		end
		T.ok(blows >= 6, "blows were struck: " .. blows)
	end)

	T.test("a monster walks FoeGain times as fast as a slime of the same SPD", function()
		T.eq(Combat.walkSpeed(2, true), Combat.walkSpeed(2) * M.FoeGain)
	end)

	T.test("skills that reach past the target spare foes far away", function()
		-- a slime of the "hp" way (Belly Bounce, every foe at once) beside one foe, with another far off
		local slime = fighter("s", 1, 0, 0)
		slime.role = "hp"
		slime.attack = 50
		local fight = Combat.new(
			{ slime },
			{ fighter("near", 0, M.MeleeStuds - 1, 0), fighter("far", 0, 40, 0) },
			Rng.new(4),
			{ moves = true }
		)
		local far = unitOf(fight, "far")
		far.speed, far.hp = 0, 1e6
		-- (the far one is held in place: it would otherwise walk in)
		local struckFar = false
		for _ = 1, 3000 do
			far.x, far.z = 40, 0
			for _, event in Combat.step(fight, DT) do
				if event.kind == "hit" and event.to == "far" and event.from == "s" then
					local s = unitOf(fight, "s")
					struckFar = struckFar or math.abs(s.x - far.x) > M.AreaStuds
				end
			end
		end
		T.ok(not struckFar, "an all-foes skill hit a foe beyond AreaStuds")
	end)

	T.test("the squad's start places match the client's row", function()
		local seen: { [string]: boolean } = {}
		for index = 1, 4 do
			local x, z = Dungeon.squadSpot(index, 4)
			seen[x .. "," .. z] = true
			T.ok(math.abs(z) < 20, "near the middle")
		end
		local count = 0
		for _ in seen do
			count += 1
		end
		T.eq(count, 4, "four different places")
	end)

	T.test("a fight that is not positional has no places, no walking and no move events", function()
		local fight = Combat.new({ fighter("s", 1, 0, 0) }, { fighter("f", 1, 60, 0) }, Rng.new(5))
		local moved, first = false, nil
		for _ = 1, 400 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "move" then
					moved = true
				elseif event.kind == "aim" and not first then
					first = fight.seconds
				end
			end
		end
		T.ok(not moved)
		T.ok(first ~= nil and (first :: number) < 3, "the first blow is announced within seconds, wherever they stand")
		T.eq(unitOf(fight, "s").x, 0)
	end)

	T.test("Dungeon squadSpots places middle and back further toward the player than front", function()
		local rows = { "front", "middle", "back", "front" }
		local spots = Dungeon.squadSpots(rows)
		T.eq(#spots, #rows)
		local player = Config.Dungeon.PlayerSpot
		local magnitude = math.sqrt(player.x * player.x + player.z * player.z)
		local px, pz = player.x / magnitude, player.z / magnitude
		local function toward(index: number): number
			return spots[index].x * px + spots[index].z * pz
		end
		local depth = Config.Classes.Rows.Depth
		T.near(toward(2) - toward(1), depth, 1e-9)
		T.near(toward(3) - toward(1), 2 * depth, 1e-9)
		T.near(toward(4), toward(1), 1e-9)
		T.ok(toward(1) > 0, "all rows are on the squad's side of the arena")
		local acrossX, acrossZ = -pz, px
		local first = spots[1].x * acrossX + spots[1].z * acrossZ
		local fourth = spots[4].x * acrossX + spots[4].z * acrossZ
		T.near(first + fourth, 0, 1e-9, "the two front slimes are centred")
		T.near(fourth - first, Config.Zombies.View.FormationSpacing, 1e-9)
	end)

end
