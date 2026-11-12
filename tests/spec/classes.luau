--!strict
local Classes = require("../../src/shared/Classes")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Zombies = require("../../src/shared/Zombies")
local ArenaFight = require("../../src/shared/ArenaFight")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")

return function(T: any)
	T.test("weapon names stats icons and stable catalogue order match the specification", function()
		local expected = {
			["sword-wood"] = { name = "Wooden Sword", stats = { attack = 1 }, icon = "rbxassetid://97081179497878" },
			["sword-iron"] = { name = "Iron Sword", stats = { attack = 2 }, icon = "rbxassetid://115806701784990" },
			["sword-core"] = {
				name = "Runeblade",
				stats = { attack = 4, speed = 1 },
				icon = "rbxassetid://118787761776736",
			},
			["sword-bramble"] = {
				name = "Dawnbreaker",
				stats = { attack = 5, speed = 1, hp = 20 },
				icon = "rbxassetid://121762848225486",
			},
			["shield-wood"] = { name = "Wooden Shield", stats = { defence = 1 }, icon = "rbxassetid://84928930460596" },
			["shield-iron"] = {
				name = "Iron Shield",
				stats = { defence = 2, hp = 10 },
				icon = "rbxassetid://79907995295146",
			},
			["shield-core"] = {
				name = "Warden Shield",
				stats = { defence = 4, hp = 20 },
				icon = "rbxassetid://86103832759452",
			},
			["shield-bramble"] = {
				name = "Aegis of Goo",
				stats = { defence = 5, hp = 40 },
				icon = "rbxassetid://137552517196617",
			},
			["bow-wood"] = { name = "Wooden Bow", stats = { attack = 1 }, icon = "rbxassetid://93958107174767" },
			["bow-iron"] = {
				name = "Iron Bow",
				stats = { attack = 2, speed = 1 },
				icon = "rbxassetid://94521275054756",
			},
			["bow-core"] = {
				name = "Windwhisper Bow",
				stats = { attack = 3, speed = 2 },
				icon = "rbxassetid://123955097028838",
			},
			["bow-bramble"] = {
				name = "Starfall Bow",
				stats = { attack = 5, speed = 2, hp = 20 },
				icon = "rbxassetid://74469585897273",
			},
			["focus-wood"] = { name = "Arcane Focus", stats = { attack = 1 }, icon = "rbxassetid://104986195515058" },
			["focus-iron"] = {
				name = "Iron-bound Focus",
				stats = { attack = 2, speed = 1 },
				icon = "rbxassetid://140142152690616",
			},
			["focus-core"] = {
				name = "Prism Focus",
				stats = { attack = 3, speed = 2 },
				icon = "rbxassetid://91222316863600",
			},
			["focus-bramble"] = {
				name = "Mythic Focus",
				stats = { attack = 5, speed = 2, hp = 20 },
				icon = "rbxassetid://138774108715212",
			},
			["staff-wood"] = { name = "Healing Staff", stats = { hp = 10 }, icon = "rbxassetid://139875318089887" },
			["staff-iron"] = {
				name = "Iron-shod Staff",
				stats = { defence = 1, hp = 20 },
				icon = "rbxassetid://88442861529702",
			},
			["staff-core"] = {
				name = "Enchanted Staff",
				stats = { attack = 1, defence = 1, hp = 40 },
				icon = "rbxassetid://102932731135237",
			},
			["staff-bramble"] = {
				name = "Lifebloom Staff",
				stats = { attack = 2, defence = 1, hp = 50 },
				icon = "rbxassetid://96105913237235",
			},
			["kit-wood"] = { name = "Alchemy Kit", stats = { speed = 1 }, icon = "rbxassetid://125482769696185" },
			["kit-iron"] = { name = "Iron Kit", stats = { speed = 2, hp = 10 }, icon = "rbxassetid://78313998911607" },
			["kit-core"] = {
				name = "Alchemist's Satchel",
				stats = { attack = 1, speed = 3 },
				icon = "rbxassetid://107138467869242",
			},
			["kit-bramble"] = {
				name = "Philosopher's Kit",
				stats = { attack = 2, speed = 4, hp = 20 },
				icon = "rbxassetid://96985155253549",
			},
		}
		for id, want in expected do
			local got = Config.Smithy.Gear[id]
			T.eq(got.name, want.name)
			T.same(got.stats, want.stats)
			T.eq(got.icon, want.icon)
		end
		local order = {}
		for _, tier in { "wood", "iron", "core", "bramble" } do
			for _, family in { "sword", "helm", "charm" } do
				table.insert(order, family .. "-" .. tier)
			end
		end
		for _, family in { "shield", "bow", "focus", "staff", "kit" } do
			for _, tier in { "wood", "iron", "core", "bramble" } do
				table.insert(order, family .. "-" .. tier)
			end
		end
		T.same(Config.Smithy.GearOrder, order)
		T.same(Config.Classes.Families, {
			sword = "warrior",
			shield = "guardian",
			bow = "ranger",
			focus = "mage",
			staff = "healer",
			kit = "alchemist",
		})
		T.same(Config.Classes.Tiers, { wood = 1, iron = 2, core = 3, bramble = 4 })
	end)
	T.test("all 24 weapons grant their family class and tier with matching recipes", function()
		local count = 0
		local seen = {}
		for _, id in Config.Smithy.GearOrder do
			T.ok(not seen[id], "unique catalogue entry")
			seen[id] = true
			local gear = Config.Smithy.Gear[id]
			if gear.slot == "hand" then
				count += 1
				local class, tier = Classes.ofSlime({ gear = { hand = id } })
				T.eq(class, Config.Classes.Families[gear.family])
				T.eq(tier, Config.Classes.Tiers[gear.tier])
				T.ok(string.match(gear.icon, "^rbxassetid://%d+$"))
				local recipe = Config.Smithy.Recipes[id]
				local sword = Config.Smithy.Recipes["sword-" .. gear.tier]
				T.eq(recipe.gear, id)
				T.eq(recipe.coins, sword.coins)
				T.same(recipe.materials, sword.materials)
			end
		end
		T.eq(count, 24)
		for family, class in Config.Classes.Families do
			for tier, index in Config.Classes.Tiers do
				local got, rank = Classes.ofSlime({ gear = { hand = family .. "-" .. tier } })
				T.eq(got, class)
				T.eq(rank, index)
			end
		end
	end)

	T.test("absent invalid or misplaced weapons are Brawlers", function()
		for _, slime in { {}, { gear = {} }, { gear = { hand = "missing" } }, { gear = { hand = "helm-wood" } } } do
			local class, tier = Classes.ofSlime(slime)
			T.eq(class, nil)
			T.eq(tier, nil)
		end
	end)

	T.test("builders keep Brawler roles and skills and replace them only for weapons", function()
		local slime: any = FarmState.newFarm(0).slimes[1]
		T.ok(slime ~= nil)
		slime.gear = {}
		for _, fighter in { Zombies.fighter(slime, 0, 1), ArenaFight.fighter(slime, "") } do
			T.eq(fighter.class, nil)
			T.eq(fighter.role, Combat.role(fighter, slime.seed))
			T.eq(fighter.skills, nil)
			local fight = Combat.new({ fighter }, {}, Rng.new(7))
			T.same(fight.units[1].skills, { fighter.role })
		end
		for family, class in Config.Classes.Families do
			slime.gear.hand = family .. "-core"
			for _, fighter in { Zombies.fighter(slime, 0, 1), ArenaFight.fighter(slime, "") } do
				T.eq(fighter.class, class)
				T.eq(fighter.role, class)
				T.eq(fighter.tier, 3)
				T.same(fighter.skills, {})
			end
		end
	end)

	-- ===== Part 2: the rules core; Part 3: the six Common classes =====

	local DT = Config.Zombies.FightStepSeconds
	local Skills: any = Config.Combat.Skills

	local function slime(id: string, class: string?, extra: { [string]: any }?): any
		local out: any = { id = id, attack = 10, defence = 0, speed = 0, hp = 1e6, class = class, role = class }
		if class then
			out.skills = {}
		end
		for key, value in extra or {} do
			out[key] = value
		end
		return out
	end
	local function foe(id: string, extra: { [string]: any }?): any
		local out: any = { id = id, attack = 0, defence = 0, speed = 0, hp = 1e6, kind = "melee" }
		for key, value in extra or {} do
			out[key] = value
		end
		return out
	end
	local function unitOf(fight: any, id: string): any
		for _, each in fight.units do
			if each.id == id then
				return each
			end
		end
		error("no unit " .. id)
	end
	-- (a foe that stands still and never strikes, so a test sees only what it asks about)
	local function freeze(u: any, target: any?)
		u.aimed, u.cooldown, u.target = true, 1e9, target
	end
	local function run(fight: any, seconds: number): { any }
		local all: { any } = {}
		for _ = 1, math.floor(seconds / DT + 0.5) do
			for _, event in Combat.step(fight, DT) do
				table.insert(all, event)
			end
		end
		return all
	end
	local function firstOf(events: { any }, check: (any) -> boolean): any
		for _, event in events do
			if check(event) then
				return event
			end
		end
		return nil
	end

	T.test("magic counts DEF at 0.65, heals weigh as damage with no DEF", function()
		local c = Config.Combat
		local physical = Combat.damage(10, 50)
		local magic = Combat.damage(10, 50, true)
		T.near(physical, 10 * c.DamageScale * (1 - 50 / 100), 1e-9)
		T.near(magic, 10 * c.DamageScale * (1 - 32.5 / 82.5), 1e-9)
		T.ok(magic > physical)
		T.eq(Config.Classes.HealWeight, c.DamageScale)
		T.near(Combat.healAmount(10, 4), 10 * 4 * c.DamageScale, 1e-9)
		T.eq(c.CritPerSpeed, 0)
		T.eq(c.DodgeCap, 0.2)
	end)

	T.test("crit and dodge never on a skill; dodge capped at 20%", function()
		local fight = Combat.new(
			{ slime("w", "warrior", { speed = 200 }), slime("m", "mage", { speed = 200 }) },
			{ foe("f", { speed = 200, attack = 1 }), foe("g", { speed = 200 }) },
			Rng.new(11)
		)
		local skilled, dodges, plain = 0, 0, 0
		for _, event in run(fight, 120) do
			if event.skill and (event.kind == "hit" or event.kind == "dodge") then
				skilled += 1
				T.eq(event.kind, "hit", "a skill is never dodged")
				T.ok(not event.crit, "a skill never crits")
			elseif event.kind == "dodge" and (event.from == "w" or event.from == "m") then
				dodges += 1
			elseif event.kind == "hit" and (event.from == "w" or event.from == "m") then
				plain += 1
			end
		end
		T.ok(skilled > 5, "skills struck: " .. skilled)
		T.ok(dodges > 0 and dodges / (dodges + plain) < 0.3, "dodges about the cap")
	end)

	T.test(
		"stuns count full, half, a quarter, then none in 10 s; bosses never, mini-bosses 0.3 then 6 s free",
		function()
			local fight = Combat.new(
				{ slime("s") },
				{ foe("b", { defRole = "boss" }), foe("m", { defRole = "miniboss" }) },
				Rng.new(1)
			)
			local s, b, m = unitOf(fight, "s"), unitOf(fight, "b"), unitOf(fight, "m")
			local function took(u: any, seconds: number): number
				local before = u.cooldown
				Combat.stun(fight, u, seconds)
				return u.cooldown - before
			end
			T.near(took(s, 1), 1, 1e-9)
			T.near(took(s, 1), 0.5, 1e-9)
			T.near(took(s, 1), 0.25, 1e-9)
			T.near(took(s, 1), 0, 1e-9)
			fight.seconds += 10.01
			T.near(took(s, 1), 1, 1e-9, "the window cleared")
			T.eq(took(b, 1), 0)
			T.near(took(m, 1), 0.3, 1e-9)
			fight.seconds += 5
			T.eq(took(m, 1), 0)
			fight.seconds += 1.01
			T.near(took(m, 0.2), 0.2, 1e-9)
		end
	)

	T.test("a wind-up special begins at least SpecialGap after the last, with its full wind-up", function()
		local fight = Combat.new(
			{ slime("s") },
			{ foe("f", { skills = { "horn_toss" }, speed = 40, attack = 1 }) },
			Rng.new(5)
		)
		local began: { number } = {}
		local aimAt = 0
		for _ = 1, math.floor(60 / DT) do
			for _, event in Combat.step(fight, DT) do
				if event.from == "f" and event.kind == "aim" then
					aimAt = fight.seconds
					if event.skill then
						table.insert(began, fight.seconds)
					end
				elseif event.from == "f" and event.kind == "hit" and event.skill and (event.n or 1) == 1 then
					T.near(fight.seconds - aimAt, Skills.horn_toss.windup, DT + 1e-6, "full wind-up")
				end
			end
		end
		T.ok(#began >= 3, "specials: " .. #began)
		for index = 2, #began do
			T.ok(began[index] - began[index - 1] >= Config.Classes.SpecialGap - 1e-6, "gap " .. index)
		end
	end)

	T.test("Taunt: up to 3 foes after team-mates, 4 s, then they pick again and cannot be taunted for 2 s", function()
		local fight = Combat.new(
			{ slime("g", "guardian"), slime("m") },
			{ foe("f1"), foe("f2"), foe("f3"), foe("f4") },
			Rng.new(2)
		)
		local g, m = unitOf(fight, "g"), unitOf(fight, "m")
		for _, id in { "f1", "f2", "f3", "f4" } do
			freeze(unitOf(fight, id), m)
		end
		g.skillReady = 0
		local taunts: { any } = {}
		local at = 0
		for _ = 1, 100 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "taunt" then
					table.insert(taunts, event)
					at = fight.seconds
				end
			end
			if #taunts > 0 then
				break
			end
		end
		T.eq(#taunts, Skills.taunt.count)
		for _, event in taunts do
			local f = unitOf(fight, event.to)
			T.eq(f.tauntBy, g)
			T.eq(f.target, g)
			T.near(f.tauntUntil, at + 4, 1e-9)
		end
		T.near(g.effects.taken.value, 0.25, 1e-9)
		T.near(g.skillReady, at + Skills.taunt.cooldown, 1e-9)
		run(fight, 4.1)
		-- (let them aim again: their next aim finds the taunt over and picks by its own rule)
		for _, event in taunts do
			local f = unitOf(fight, event.to)
			f.aimed, f.cooldown = false, 0.35
		end
		run(fight, 0.2)
		for _, event in taunts do
			local f = unitOf(fight, event.to)
			T.eq(f.tauntBy, nil)
			T.ok(f.tauntFree > fight.seconds and f.tauntFree <= fight.seconds + 2, "no re-taunt for 2 s")
		end
	end)

	T.test("Intercept: 70% of a blow at a team-mate within 9, once every 8 s", function()
		local fight = Combat.new({ slime("g", "guardian"), slime("m") }, { foe("f", { attack = 10 }) }, Rng.new(3))
		local g, m, f = unitOf(fight, "g"), unitOf(fight, "m"), unitOf(fight, "f")
		g.skillReady, f.target = 1e9, m
		-- (Guardian and team-mate never strike back)
		freeze(g, f)
		freeze(m, f)
		local hits: { { any } } = {}
		for _ = 1, math.floor(20 / DT) do
			local batch: { any } = {}
			for _, event in Combat.step(fight, DT) do
				if event.kind == "hit" and event.from == "f" then
					table.insert(batch, event)
				end
			end
			if #batch > 0 then
				table.insert(hits, batch)
			end
		end
		T.ok(#hits >= 10, "blows: " .. #hits)
		local full = Combat.damage(10, 0)
		T.eq(#hits[1], 2)
		T.eq(hits[1][1].to, "m")
		T.near(hits[1][1].amount, full * 0.3, 1e-9)
		T.eq(hits[1][2].to, "g")
		T.eq(hits[1][2].guard, "g")
		T.near(hits[1][2].amount, full * 0.7, 1e-9)
		T.eq(#hits[2], 1, "not again before 8 s")
		local intercepted = 0
		for _, batch in hits do
			if #batch == 2 then
				intercepted += 1
			end
		end
		T.ok(intercepted >= 2 and intercepted <= 3, "about every 8 s in 20 s: " .. intercepted)
		-- positional: a team-mate 12 studs from the Guardian is not covered
		local far = Combat.new(
			{ slime("g", "guardian", { x = 0, z = 0 }), slime("m", nil, { x = 12, z = 0 }) },
			{ foe("f", { attack = 10, x = 16, z = 0 }) },
			Rng.new(3),
			{ moves = true }
		)
		local fg, fm, ff = unitOf(far, "g"), unitOf(far, "m"), unitOf(far, "f")
		freeze(fg, ff)
		freeze(fm, ff)
		ff.target = fm
		local hit = firstOf(run(far, 5), function(event: any): boolean
			return event.kind == "hit" and event.from == "f"
		end)
		T.ok(hit ~= nil and hit.to == "m" and hit.guard == nil)
	end)

	T.test("Dash Strike: 1.35 when ready; positional it dashes from 7-18 and walks from farther", function()
		local fight = Combat.new({ slime("w", "warrior") }, { foe("f", { defence = 10 }) }, Rng.new(4))
		unitOf(fight, "w").skillReady = 0
		freeze(unitOf(fight, "f"))
		local hit = firstOf(run(fight, 3), function(event: any): boolean
			return event.kind == "hit" and event.from == "w"
		end)
		T.eq(hit.skill, "dash_strike")
		T.near(hit.amount, Combat.damage(10, 10) * 1.35, 1e-9)
		local near = Combat.new(
			{ slime("w", "warrior", { x = 0, z = 0 }) },
			{ foe("f", { x = 12, z = 0 }) },
			Rng.new(4),
			{ moves = true }
		)
		unitOf(near, "w").skillReady = 0
		freeze(unitOf(near, "f"))
		local events = run(near, 3)
		local move = firstOf(events, function(event: any): boolean
			return event.kind == "move" and event.from == "w"
		end)
		T.ok(move.dash == true, "dashed")
		T.eq(move.seconds, 0.2)
		T.near(math.abs(move.tx - 12), Config.Classes.Kinds.warrior.reach, 1e-6)
		local dashHit = firstOf(events, function(event: any): boolean
			return event.kind == "hit" and event.from == "w"
		end)
		T.eq(dashHit.skill, "dash_strike")
		local far = Combat.new(
			{ slime("w", "warrior", { x = 0, z = 0 }) },
			{ foe("f", { x = 40, z = 0 }) },
			Rng.new(4),
			{ moves = true }
		)
		unitOf(far, "w").skillReady = 0
		freeze(unitOf(far, "f"))
		local walked = firstOf(run(far, 0.5), function(event: any): boolean
			return event.kind == "move" and event.from == "w"
		end)
		T.ok(walked ~= nil and walked.dash == nil, "walks first from 40 studs")
	end)

	T.test("Piercing Shot: 1.35 ignoring 25% DEF, 0.55 on the one lined up behind", function()
		local fight = Combat.new({ slime("r", "ranger", { x = 0, z = 0 }) }, {
			foe("t", { x = 10, z = 0, defence = 20 }),
			foe("b", { x = 15, z = 0.5, defence = 20 }),
			foe("o", { x = 10, z = 7, defence = 20 }),
		}, Rng.new(5), { moves = true })
		local r = unitOf(fight, "r")
		r.skillReady, r.target = 0, unitOf(fight, "t")
		for _, id in { "t", "b", "o" } do
			freeze(unitOf(fight, id))
		end
		local hits: { any } = {}
		for _, event in run(fight, 3) do
			if event.kind == "hit" and event.from == "r" and event.skill then
				table.insert(hits, event)
			end
		end
		T.eq(#hits, 2)
		T.eq(hits[1].to, "t")
		T.near(hits[1].amount, Combat.damage(10, 15) * 1.35, 1e-9)
		T.eq(hits[2].to, "b")
		T.eq(hits[2].splash, true)
		T.near(hits[2].amount, Combat.damage(10, 15) * 0.55, 1e-9)
		T.ok(hits[1].ranged, "a ranger's blow is ranged")
	end)

	T.test("Arcane Barrage: 1.15 magic on the target, 0.4 on up to 2 others", function()
		local fight = Combat.new({ slime("m", "mage") }, {
			foe("a", { defence = 20 }),
			foe("b", { defence = 20 }),
			foe("c", { defence = 20 }),
			foe("d", { defence = 20 }),
		}, Rng.new(6))
		unitOf(fight, "m").skillReady = 0
		for _, id in { "a", "b", "c", "d" } do
			freeze(unitOf(fight, id))
		end
		local hits: { any } = {}
		for _, event in run(fight, 3) do
			if event.kind == "hit" and event.skill == "arcane_barrage" then
				table.insert(hits, event)
			end
		end
		T.eq(#hits, 3)
		T.near(hits[1].amount, Combat.damage(10, 20, true) * 1.15, 1e-9)
		for index = 2, 3 do
			T.eq(hits[index].splash, true)
			T.near(hits[index].amount, Combat.damage(10, 20, true) * 0.4, 1e-9)
		end
	end)

	T.test("Healer heals below 90% instead of striking, Mends below 60%, bolts otherwise, never overheals", function()
		local function healerFight(share: number, ready: number, max: number?): (any, { any })
			local full = max or 1000
			local fight = Combat.new(
				{ slime("h", "healer"), slime("m", nil, { hp = share * full, maxHp = full }) },
				{ foe("f", { defence = 20 }) },
				Rng.new(7)
			)
			unitOf(fight, "h").skillReady = ready
			freeze(unitOf(fight, "m"), unitOf(fight, "f"))
			freeze(unitOf(fight, "f"))
			return fight, run(fight, 2)
		end
		local _, low = healerFight(0.5, 0)
		local mend = firstOf(low, function(event: any): boolean
			return event.from == "h" and (event.kind == "heal" or event.kind == "hit")
		end)
		T.eq(mend.kind, "heal")
		T.eq(mend.skill, "mend")
		T.near(mend.amount, Combat.healAmount(10, 4), 1e-9)
		local _, hurt = healerFight(0.8, 1e9)
		local plain = firstOf(hurt, function(event: any): boolean
			return event.from == "h" and (event.kind == "heal" or event.kind == "hit")
		end)
		T.eq(plain.kind, "heal")
		T.eq(plain.skill, nil)
		T.near(plain.amount, Combat.healAmount(10, 1), 1e-9)
		local _, well = healerFight(0.95, 0)
		local bolt = firstOf(well, function(event: any): boolean
			return event.from == "h" and (event.kind == "heal" or event.kind == "hit")
		end)
		T.eq(bolt.kind, "hit")
		T.near(
			bolt.amount,
			Combat.damage(10, 20, true) * 0.65 * (if bolt.crit then Config.Combat.CritFactor else 1),
			1e-9
		)
		-- (missing 1.2 of 10, less than one plain heal of 3)
		local fight, nearly = healerFight(0.88, 1e9, 10)
		local small = firstOf(nearly, function(event: any): boolean
			return event.from == "h" and event.kind == "heal"
		end)
		T.near(small.amount, 1.2, 1e-6, "only what is missing")
		T.near(unitOf(fight, "m").hp, 10, 1e-9)
	end)

	T.test("Acid Rain picks the densest group (ties to higher DEF) and melts their armour", function()
		local fight = Combat.new({ slime("a", "alchemist", { x = 0, z = 0 }) }, {
			foe("lone", { x = 10, z = 0, defence = 40 }),
			foe("b", { x = 0, z = 12, defence = 10 }),
			foe("c", { x = 2, z = 12, defence = 30 }),
			foe("d", { x = 0, z = 14, defence = 10 }),
		}, Rng.new(8), { moves = true })
		local a = unitOf(fight, "a")
		a.skillReady, a.target = 0, unitOf(fight, "lone")
		for _, id in { "lone", "b", "c", "d" } do
			freeze(unitOf(fight, id))
		end
		local hits: { any } = {}
		for _, event in run(fight, 3) do
			if event.kind == "hit" and event.skill == "acid_rain" then
				table.insert(hits, event)
			end
		end
		T.eq(#hits, 3)
		T.eq(hits[1].to, "c")
		T.eq(hits[1].melt, true)
		T.near(hits[1].amount, Combat.damage(10, 30, true) * 0.9, 1e-9)
		for _, event in hits do
			T.ok(event.to ~= "lone", "the lone foe is spared")
			T.near(unitOf(fight, event.to).effects.melt.value, 0.2, 1e-9)
		end
		-- the melt lowers DEF: the next blow on c counts 20% less of it
		local c = unitOf(fight, "c")
		a.skillReady, a.target = 1e9, c
		local next = firstOf(run(fight, 3), function(event: any): boolean
			return event.kind == "hit" and event.from == "a"
		end)
		local want = Combat.damage(10, 30 * 0.8, true) * 0.75
		T.near(next.amount, if next.crit then want * Config.Combat.CritFactor else want, 1e-9)
	end)

	T.test(
		"Ranger and Mage hop away from a foe within 7, not again before their cooldown, never past the radius",
		function()
			for _, class in { "ranger", "mage" } do
				local fight = Combat.new(
					{ slime("r", class, { x = 0, z = 0 }) },
					{ foe("f", { x = 4, z = 0 }) },
					Rng.new(9),
					{ moves = true, radius = 70 }
				)
				local r, f = unitOf(fight, "r"), unitOf(fight, "f")
				r.skillReady = 1e9
				freeze(f, r)
				local hops: { any } = {}
				for _ = 1, math.floor(12 / DT) do
					for _, event in Combat.step(fight, DT) do
						if event.kind == "move" and event.hop then
							table.insert(hops, { at = fight.seconds, event = event })
						end
					end
					-- (the foe keeps at its heels)
					f.x, f.z = r.x + 4, r.z
				end
				local every = Config.Classes.HopCooldown[class]
				T.ok(#hops >= 2, class .. " hops: " .. #hops)
				T.near(hops[1].event.seconds, 0.25, 1e-9)
				T.ok(hops[1].event.tx < hops[1].event.x, "away from the foe")
				for index = 2, #hops do
					T.ok(hops[index].at - hops[index - 1].at >= every - 1e-6, "not before its cooldown")
				end
			end
			local edge = Combat.new(
				{ slime("r", "ranger", { x = 68, z = 0 }) },
				{ foe("f", { x = 64, z = 0 }) },
				Rng.new(9),
				{ moves = true, radius = 70 }
			)
			local r = unitOf(edge, "r")
			r.skillReady = 1e9
			freeze(unitOf(edge, "f"), r)
			local hop = firstOf(run(edge, 0.3), function(event: any): boolean
				return event.kind == "move" and event.hop == true
			end)
			T.ok(hop ~= nil, "it hops at the edge")
			T.ok(math.sqrt(hop.tx ^ 2 + hop.tz ^ 2) <= 70 + 1e-6, "inside the radius")
		end
	)

	T.test("a mixed class fight is the same from the same seed", function()
		local function play(): { any }
			local fight = Combat.new({
				slime("g", "guardian", { x = -4, z = 0 }),
				slime("w", "warrior", { x = -2, z = 0 }),
				slime("r", "ranger", { x = 0, z = 0 }),
				slime("m", "mage", { x = 2, z = 0 }),
				slime("h", "healer", { x = 4, z = 0 }),
				slime("a", "alchemist", { x = 6, z = 0 }),
			}, {
				foe("f1", { x = 30, z = 0, attack = 30, hp = 400, kind = "hunter" }),
				foe("f2", { x = 30, z = 10, attack = 30, hp = 400, defRole = "miniboss", skills = { "horn_toss" } }),
				foe("f3", { x = 30, z = -10, attack = 30, hp = 400, speed = 5 }),
			}, Rng.new(21), { moves = true, radius = 70 })
			return run(fight, 40)
		end
		local one, two = play(), play()
		T.ok(#one > 50)
		T.same(one, two)
		local kinds: { [string]: boolean } = {}
		for _, event in one do
			if event.skill then
				kinds[event.skill] = true
			end
		end
		T.ok(kinds.taunt or kinds.dash_strike or kinds.piercing_shot, "class skills fire in a real fight")
	end)
end
