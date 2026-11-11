--!strict
-- The monsters' specials: a fighter's `skills` taken in turn, stun and slow riders, a monster guard with its own defence,
-- the mend special of a healer, and every monster's list pointing at skills that exist.
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Rng = require("../../src/shared/Rng")

local DT = 0.05

local function fighter(id: string, kind: string?, extra: { [string]: any }?): any
	local out: any = { id = id, attack = 1, defence = 0, speed = 0, hp = 1e9, kind = kind or "melee" }
	for key, value in extra or {} do
		out[key] = value
	end
	return out
end

local function unitOf(fight: any, id: string): any
	for _, unit in fight.units do
		if unit.id == id then
			return unit
		end
	end
	error("no unit " .. id)
end

-- Every event of `seconds` of fight.
local function run(fight: any, seconds: number): { any }
	local all: { any } = {}
	for _ = 1, math.floor(seconds / DT) do
		for _, event in Combat.step(fight, DT) do
			table.insert(all, event)
		end
	end
	return all
end

return function(T: any)
	T.test("a fighter's specials come in turn, every `every` blows of the first", function()
		local fight = Combat.new(
			{ fighter("s") },
			{ fighter("f", "melee", { skills = { "seed_volley", "honey_lance" } }) },
			Rng.new(4)
		)
		local order: { string } = {}
		for _, event in run(fight, 60) do
			if event.kind == "hit" and event.from == "f" and event.skill and (event.n == nil or event.n == 1) then
				table.insert(order, event.skill)
			end
		end
		T.ok(#order >= 4, "at least four specials in a minute: " .. #order)
		for index, key in order do
			T.eq(key, if index % 2 == 1 then "seed_volley" else "honey_lance", "special " .. index)
		end
	end)

	T.test("a fighter without skills fights as it did", function()
		local fight = Combat.new({ fighter("s") }, { fighter("f", "melee") }, Rng.new(4))
		for _, event in run(fight, 30) do
			T.eq(event.skill, nil, "a plain melee fighter has no skill")
		end
		-- a slime's role still gives its own skill, and the event says it
		local slimes = Combat.new({ fighter("s", nil, { role = "attack" }) }, { fighter("f", "melee") }, Rng.new(4))
		local seen = false
		for _, event in run(slimes, 30) do
			if event.from == "s" and event.skill then
				T.eq(event.skill, "attack")
				seen = true
			end
		end
		T.ok(seen, "the attack role struck its Goo Slam")
	end)

	T.test("a single special can stun the one it strikes", function()
		local fight = Combat.new({ fighter("s") }, { fighter("f", "melee", { skills = { "lure_flash" } }) }, Rng.new(4))
		local victim = unitOf(fight, "s")
		victim.cooldown = 100
		local found = false
		for _ = 1, 2000 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "hit" and event.skill == "lure_flash" then
					found = true
				end
			end
			if found then
				break
			end
		end
		T.ok(found, "the special struck")
		T.near(victim.cooldown, 100 - fight.seconds + Config.Combat.Skills.lure_flash.stun, 1e-6)
	end)

	T.test("a splash special slows every foe it strikes, and says so", function()
		local fight = Combat.new(
			{ fighter("a"), fighter("b"), fighter("c") },
			{ fighter("f", "melee", { skills = { "acid_splash" } }) },
			Rng.new(4)
		)
		for _, unit in fight.units do
			if unit.side == "squad" then
				unit.cooldown = 1e6
			end
		end
		local slowed: { [string]: boolean } = {}
		local seconds = 0
		for _ = 1, 2000 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "hit" and event.skill == "acid_splash" then
					T.eq(event.slow, true)
					slowed[event.to] = true
					seconds = fight.seconds
				end
			end
			if seconds > 0 then
				break
			end
		end
		T.ok(slowed.a and slowed.b and slowed.c, "the target and the two beside it")
		local s = Config.Combat.Skills.acid_splash
		for _, id in { "a", "b", "c" } do
			local unit = unitOf(fight, id)
			T.eq(unit.slowBy, s.slow)
			T.near(unit.slowUntil, seconds + s.slowSeconds, 1e-6)
		end
	end)

	T.test("a monster guard takes a blow aimed at its team-mate with its own defence", function()
		local skill = Config.Combat.Skills.bark_wall
		local was = skill.defence
		skill.defence = 2.5
		local fight = Combat.new({ fighter("s", nil, { attack = 10 }) }, {
			fighter("g", "melee", { skills = { "bark_wall" }, defence = 8 }),
			fighter("m", "melee"),
		}, Rng.new(4))
		unitOf(fight, "g").blows = 0
		unitOf(fight, "g").cooldown = 0.01
		unitOf(fight, "m").cooldown = 1e6
		local s = unitOf(fight, "s")
		s.cooldown = 1e6
		local guarded = false
		-- (its fifth blow is the wall: step until it stands)
		for _ = 1, 4000 do
			unitOf(fight, "m").cooldown = 1e6
			for _, event in Combat.step(fight, DT) do
				if event.kind == "guard" then
					guarded = true
				end
			end
			if guarded then
				break
			end
		end
		skill.defence = was
		T.ok(guarded, "the monster raised its wall")
		T.eq(unitOf(fight, "g").guardMul, 2.5)
		s.target = unitOf(fight, "m")
		s.cooldown = 0.01
		local landed: any = nil
		for _ = 1, 40 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "hit" and event.from == "s" then
					landed = event
				end
			end
			if landed then
				break
			end
		end
		T.ok(landed ~= nil, "the slime struck")
		T.eq(landed.guard, "g")
		T.eq(landed.to, "g")
		local expected = Combat.damage(10, 8 * 2.5)
		if landed.crit then
			expected *= Config.Combat.CritFactor
		end
		T.near(landed.amount, expected, 1e-6)
	end)

	T.test("a mend special heals every wounded team-mate, one event each", function()
		local fight = Combat.new({
			fighter("h", "healer", { attack = 10, skills = { "bloom_mend" } }),
			fighter("a", nil, { hp = 5, maxHp = 100 }),
			fighter("b", nil, { hp = 40, maxHp = 100 }),
			fighter("c", nil, { hp = 100, maxHp = 100 }),
			fighter("d", nil, { hp = 98, maxHp = 100 }),
		}, { fighter("e") }, Rng.new(4))
		for _, unit in fight.units do
			if unit.id ~= "h" then
				unit.cooldown = 1e9
			end
		end
		unitOf(fight, "h").mends = 0
		local plain: { any } = {}
		local special: { any } = {}
		local announced = false
		for _ = 1, 400 do
			local step = Combat.step(fight, DT)
			for _, event in step do
				if event.kind == "aim" and event.skill == "bloom_mend" then
					announced = true
				end
				if event.kind == "heal" then
					table.insert(if event.skill then special else plain, event)
				end
			end
			if #special > 0 then
				break
			end
		end
		T.eq(#plain, 2, "two plain mends first")
		T.eq(plain[1].to, "a", "the most wounded")
		T.ok(announced, "the special was announced")
		T.eq(#special, 3, "a, b and d; not c")
		local share = Config.Combat.Skills.bloom_mend.share
		local by: { [string]: number } = {}
		for _, event in special do
			T.eq(event.skill, "bloom_mend")
			T.eq(event.from, "h")
			by[event.to] = event.amount
		end
		T.near(by.a, 10 * share, 1e-6)
		T.near(by.b, 10 * share, 1e-6)
		T.near(by.d, 2, 1e-6, "capped at its maximum")
		T.eq(by.c, nil)
		T.eq(unitOf(fight, "d").hp, 100)
	end)

	T.test("a healer with nobody wounded strikes a plain blow and its mend count stays", function()
		local fight = Combat.new({ fighter("h", "healer", { skills = { "bloom_mend" } }), fighter("a") }, {
			fighter("e"),
		}, Rng.new(4))
		unitOf(fight, "e").cooldown = 1e9
		unitOf(fight, "a").cooldown = 1e9
		unitOf(fight, "h").mends = 0
		local blows = 0
		for _, event in run(fight, 10) do
			T.ok(event.kind ~= "heal", "nothing to heal")
			if event.kind == "hit" and event.from == "h" then
				T.eq(event.skill, nil)
				blows += 1
			end
		end
		T.ok(blows >= 3, "it struck plain blows")
		T.eq(unitOf(fight, "h").mends, 0)
	end)

	T.test("every monster has specials that exist, and every special has a name", function()
		for key, skill in Config.Combat.Skills do
			T.eq(type(skill.name), "string", key .. " has a name")
			T.ok(skill.name ~= "", key .. " name is not empty")
			T.eq(type(skill.every), "number", key .. " has every")
		end
		for mapId, map in Config.Dungeon.Maps do
			for _, monster in map.monsters do
				local label = mapId .. "/" .. monster.id
				T.eq(type(monster.skills), "table", label .. " has skills")
				local want = if monster.role == "boss" then 3 elseif monster.role == "miniboss" then 2 else 1
				T.eq(#monster.skills, want, label .. " has " .. want .. " specials")
				for _, key in monster.skills do
					T.ok(Config.Combat.Skills[key] ~= nil, label .. " special " .. key .. " exists")
				end
				if want > 1 then
					T.eq(monster.skills[1], monster.kind, label .. " keeps its own first")
				end
			end
		end
		for key in Config.Dungeon.Skills do
			T.ok(Config.Combat.Skills[key] ~= nil, key .. " copied into Combat")
		end
	end)
end
