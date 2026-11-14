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
			["sword-legend"] = {
				name = "Sunfire Blade",
				stats = { attack = 7, speed = 2, hp = 30 },
				icon = "rbxassetid://132802169884969",
			},
			["shield-legend"] = {
				name = "Royal Bastion",
				stats = { defence = 7, hp = 50 },
				icon = "rbxassetid://121255860151167",
			},
			["bow-legend"] = {
				name = "Moonsong Bow",
				stats = { attack = 6, speed = 3, hp = 30 },
				icon = "rbxassetid://100440456507272",
			},
			["focus-legend"] = {
				name = "Astral Scepter",
				stats = { attack = 6, speed = 3, hp = 30 },
				icon = "rbxassetid://124216830470375",
			},
			["staff-legend"] = {
				name = "Everbloom Staff",
				stats = { attack = 3, defence = 2, hp = 70 },
				icon = "rbxassetid://107335820651194",
			},
			["kit-legend"] = {
				name = "Grand Elixir Pack",
				stats = { attack = 3, speed = 6, hp = 30 },
				icon = "rbxassetid://71919804799017",
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
		-- (Legendary is weapons only: no helm or charm)
		table.insert(order, "sword-legend")
		for _, family in { "shield", "bow", "focus", "staff", "kit" } do
			for _, tier in { "wood", "iron", "core", "bramble", "legend" } do
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
		T.same(Config.Classes.Tiers, { wood = 1, iron = 2, core = 3, bramble = 4, legend = 5 })
		T.same(Config.Smithy.TierOrder, { "wood", "iron", "core", "bramble", "legend" })
		T.eq(Config.Smithy.Tiers.legend.rarity, "Legendary")
	end)
	T.test("all 30 weapons grant their family class and tier with matching recipes", function()
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
		T.eq(count, 30)
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

	T.test("magic counts DEF at 0.65, a heal weighs the healer's blow on a slime of its own strength", function()
		local c = Config.Combat
		local physical = Combat.damage(10, 50)
		local magic = Combat.damage(10, 50, true)
		T.near(physical, 10 * c.DamageScale * (1 - 50 / 100), 1e-9)
		T.near(magic, 10 * c.DamageScale * (1 - 32.5 / 82.5), 1e-9)
		T.ok(magic > physical)
		T.near(Combat.healAmount(10, 4), 10 * c.DamageScale * (1 - 10 / 60) * 4, 1e-9)
		-- (so a heal keeps pace with blows: at ATK 50 it is half its old weight, as a blow on DEF 50 is)
		T.near(Combat.healAmount(50, 1) / Combat.damage(50, 50), 1, 1e-9)
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

	T.test("stuns, slows and walls say how long they show on everyone they are on", function()
		local function statuses(foes: { any }, seconds: number): { any }
			local fight = Combat.new({ slime("s"), slime("t") }, foes, Rng.new(3))
			for _, id in { "s", "t" } do
				freeze(unitOf(fight, id), unitOf(fight, foes[1].id))
			end
			local out: { any } = {}
			for _, event in run(fight, seconds) do
				if event.kind == "status" then
					table.insert(out, event)
				end
			end
			return out
		end
		-- a stun on all: each slime struck is stunned as long as it is held off its beat (the first in full)
		local stunned: { [string]: number } = {}
		for _, event in statuses({ foe("f", { skills = { "bramble_burst" }, speed = 40, attack = 1 }) }, 20) do
			if event.status == "stunned" and not stunned[event.to] then
				T.eq(event.from, "f")
				T.eq(event.skill, "bramble_burst")
				stunned[event.to] = event.seconds
			end
		end
		T.near(stunned.s, Skills.bramble_burst.stun, 1e-9)
		T.near(stunned.t, Skills.bramble_burst.stun, 1e-9)
		-- a hunter's sting slows the one it stings
		local slowed = statuses({ foe("h", { kind = "hunter", speed = 40, attack = 1 }) }, 5)
		T.ok(#slowed > 0, "the sting shows")
		T.eq(slowed[1].status, "slowed")
		T.eq(slowed[1].seconds, Config.Combat.Stings.hunter.seconds)
		-- a wall shows on the one that holds it up
		local walls = statuses({ foe("w", { skills = { "bark_wall" }, speed = 40, attack = 1 }) }, 20)
		local guarded = firstOf(walls, function(event: any): boolean
			return event.status == "guarded"
		end)
		T.ok(guarded ~= nil and guarded.to == "w" and guarded.seconds == Skills.bark_wall.seconds, "the wall shows")
	end)

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
		g.skillReady.taunt = 0
		local taunts: { any } = {}
		local statuses: { [string]: string } = {}
		local at = 0
		for _ = 1, 100 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "taunt" then
					table.insert(taunts, event)
					at = fight.seconds
				elseif event.kind == "status" then
					T.eq(event.seconds, Skills.taunt.seconds)
					statuses[event.to] = event.status
				end
			end
			if #taunts > 0 then
				break
			end
		end
		T.eq(#taunts, Skills.taunt.count)
		-- (every foe pulled shows it is taunted; the Guardian shows its shield)
		for _, event in taunts do
			T.eq(statuses[event.to], "taunted")
		end
		T.eq(statuses.g, "shielded")
		for _, event in taunts do
			local f = unitOf(fight, event.to)
			T.eq(f.tauntBy, g)
			T.eq(f.target, g)
			T.near(f.tauntUntil, at + 4, 1e-9)
		end
		T.near(g.effects.taken.value, Skills.taunt.taken, 1e-9)
		T.near(g.skillReady.taunt, at + Skills.taunt.cooldown, 1e-9)
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
		g.skillReady.taunt, f.target = 1e9, m
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
		-- (the Guardian's share comes through its shield: it always takes `taken` less)
		T.near(hits[1][2].amount, full * 0.7 * (1 - Config.Classes.Kinds.guardian.taken), 1e-9)
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

	T.test("Dash Strike when ready; positional it dashes from 7-18 and walks from farther", function()
		local fight = Combat.new({ slime("w", "warrior") }, { foe("f", { defence = 10 }) }, Rng.new(4))
		unitOf(fight, "w").skillReady.dash_strike = 0
		freeze(unitOf(fight, "f"))
		local hit = firstOf(run(fight, 3), function(event: any): boolean
			return event.kind == "hit" and event.from == "w"
		end)
		T.eq(hit.skill, "dash_strike")
		-- (a Common weapon's skill: SkillPower[1] of the Warrior's plain blow)
		local plainFactor = Config.Classes.Kinds.warrior.factor
		T.near(hit.amount, Combat.damage(10, 10) * plainFactor * Config.Classes.SkillPower[1], 1e-9)
		local near = Combat.new(
			{ slime("w", "warrior", { x = 0, z = 0 }) },
			{ foe("f", { x = 12, z = 0 }) },
			Rng.new(4),
			{ moves = true }
		)
		unitOf(near, "w").skillReady.dash_strike = 0
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
		unitOf(far, "w").skillReady.dash_strike = 0
		freeze(unitOf(far, "f"))
		local walked = firstOf(run(far, 0.5), function(event: any): boolean
			return event.kind == "move" and event.from == "w"
		end)
		T.ok(walked ~= nil and walked.dash == nil, "walks first from 40 studs")
	end)

	T.test("Piercing Shot: SkillPower ignoring 25% DEF, on every foe on its arrow's flight", function()
		local s = Config.Classes.Skills.piercing_shot
		local fight = Combat.new({ slime("r", "ranger", { x = 0, z = 0 }) }, {
			foe("t", { x = 10, z = 0, defence = 20 }),
			-- (on the flight, beyond the target and before it)
			foe("b", { x = 15, z = 0.5, defence = 20 }),
			foe("n", { x = 4, z = -1, defence = 20 }),
			-- (off it, past its end and behind the bow)
			foe("o", { x = 10, z = s.width + 1, defence = 20 }),
			foe("e", { x = s.length + 2, z = 0, defence = 20 }),
			foe("h", { x = -5, z = 0, defence = 20 }),
		}, Rng.new(5), { moves = true })
		local r = unitOf(fight, "r")
		r.skillReady.piercing_shot, r.target = 0, unitOf(fight, "t")
		for _, id in { "t", "b", "n", "o", "e", "h" } do
			freeze(unitOf(fight, id))
		end
		local hits: { any } = {}
		for _, event in run(fight, 3) do
			if event.kind == "hit" and event.from == "r" and event.skill then
				table.insert(hits, event)
			end
		end
		T.eq(#hits, 3, "the three on its flight")
		T.same({ hits[1].to, hits[2].to, hits[3].to }, { "n", "t", "b" }, "nearest the bow first")
		local weight = Config.Classes.Kinds.ranger.factor * Config.Classes.SkillPower[1]
		for _, hit in hits do
			T.near(hit.amount, Combat.damage(10, 15) * weight, 1e-9, "as hard on " .. hit.to)
			T.ok(hit.ranged, "a ranger's blow is ranged")
			T.ok((hit.to == "t") == (hit.splash == nil), "only the target is not a splash")
		end
		-- (a quick fight with no places: its target only)
		local quick = Combat.new({ slime("r", "ranger") }, { foe("t"), foe("b") }, Rng.new(5))
		local q = unitOf(quick, "r")
		q.skillReady.piercing_shot, q.target = 0, unitOf(quick, "t")
		freeze(unitOf(quick, "t"))
		freeze(unitOf(quick, "b"))
		local struck = 0
		for _, event in run(quick, 3) do
			if event.kind == "hit" and event.from == "r" and event.skill then
				struck += 1
			end
		end
		T.eq(struck, 1)
	end)

	T.test("an attack skill weighs SkillPower of its class's plain blow at its weapon's tier", function()
		for tier = 1, 5 do
			local fight = Combat.new(
				{ slime("w", "warrior", { tier = tier }) },
				{ foe("f", { defence = 10 }) },
				Rng.new(4)
			)
			unitOf(fight, "w").skillReady.dash_strike = 0
			freeze(unitOf(fight, "f"))
			local hit = firstOf(run(fight, 3), function(event: any): boolean
				return event.kind == "hit" and event.from == "w"
			end)
			local want = Combat.damage(10, 10) * Config.Classes.Kinds.warrior.factor * Config.Classes.SkillPower[tier]
			T.eq(hit.skill, "dash_strike")
			T.near(hit.amount, want, 1e-9, "tier " .. tier)
		end
		T.same(Config.Classes.SkillPower, { 1.1, 1.2, 1.3, 1.4, 1.5 })
	end)

	T.test("Arcane Barrage: every foe within its radius, as hard as the target; no places: cap foes", function()
		local weight = Config.Classes.Kinds.mage.factor * Config.Classes.SkillPower[1]
		local function barrage(fight: any, ids: { string }): { any }
			unitOf(fight, "m").skillReady.arcane_barrage = 0
			for _, id in ids do
				freeze(unitOf(fight, id))
			end
			local hits: { any } = {}
			for _, event in run(fight, 3) do
				if event.kind == "hit" and event.skill == "arcane_barrage" then
					table.insert(hits, event)
				end
			end
			return hits
		end
		local loose = Combat.new({ slime("m", "mage") }, {
			foe("a", { defence = 20 }),
			foe("b", { defence = 20 }),
			foe("c", { defence = 20 }),
			foe("d", { defence = 20 }),
		}, Rng.new(6))
		local hits = barrage(loose, { "a", "b", "c", "d" })
		T.eq(#hits, Skills.arcane_barrage.cap)
		for index, hit in hits do
			T.eq(hit.splash, if index == 1 then nil else true)
			T.near(hit.amount, Combat.damage(10, 20, true) * weight, 1e-9)
		end
		-- positional: the five within 7 of the target, never the one 10 away
		local placed = Combat.new({ slime("m", "mage", { x = 0, z = 0 }) }, {
			foe("t", { x = 20, z = 0, defence = 20 }),
			foe("p", { x = 23, z = 0, defence = 20 }),
			foe("q", { x = 20, z = 4, defence = 20 }),
			foe("s", { x = 17, z = -3, defence = 20 }),
			foe("u", { x = 24, z = -4, defence = 20 }),
			foe("far", { x = 30, z = 0, defence = 20 }),
		}, Rng.new(6), { moves = true })
		unitOf(placed, "m").target = unitOf(placed, "t")
		local struck: { [string]: boolean } = {}
		local count = 0
		for _, hit in barrage(placed, { "t", "p", "q", "s", "u", "far" }) do
			struck[hit.to] = true
			count += 1
			T.near(hit.amount, Combat.damage(10, 20, true) * weight, 1e-9)
		end
		T.eq(count, 5)
		T.ok(struck.t and struck.p and struck.q and struck.s and struck.u, "all within the area")
		T.ok(not struck.far, "none outside it")
	end)

	T.test("Healer heals below 90% instead of striking, Mends below 60%, bolts otherwise, never overheals", function()
		local function healerFight(share: number, ready: number, max: number?): (any, { any })
			local full = max or 1000
			local fight = Combat.new(
				{ slime("h", "healer"), slime("m", nil, { hp = share * full, maxHp = full }) },
				{ foe("f", { defence = 20 }) },
				Rng.new(7)
			)
			unitOf(fight, "h").skillReady.mend = ready
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
		T.near(plain.amount, Combat.healAmount(10, Config.Classes.PlainHeal), 1e-9)
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
		a.skillReady.acid_rain, a.target = 0, unitOf(fight, "lone")
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
		local weight = Config.Classes.Kinds.alchemist.factor * Config.Classes.SkillPower[1]
		T.near(hits[1].amount, Combat.damage(10, 30, true) * weight, 1e-9)
		for _, event in hits do
			T.ok(event.to ~= "lone", "the lone foe is spared")
			T.near(unitOf(fight, event.to).effects.melt.value, 0.2, 1e-9)
		end
		-- (each melted foe says so, for as long as the melt lasts)
		local melted: { [string]: boolean } = {}
		for _, event in hits do
			melted[event.to] = false
		end
		local fight2 = Combat.new({ slime("a", "alchemist", { x = 0, z = 0 }) }, {
			foe("b", { x = 0, z = 12, defence = 10 }),
			foe("c", { x = 2, z = 12, defence = 30 }),
			foe("d", { x = 0, z = 14, defence = 10 }),
		}, Rng.new(8), { moves = true })
		unitOf(fight2, "a").skillReady.acid_rain = 0
		for _, id in { "b", "c", "d" } do
			freeze(unitOf(fight2, id))
		end
		for _, event in run(fight2, 3) do
			if event.kind == "status" and event.status == "melted" then
				T.eq(event.from, "a")
				T.eq(event.skill, "acid_rain")
				T.eq(event.seconds, Skills.acid_rain.seconds)
				melted[event.to] = true
			end
		end
		for id, seen in melted do
			T.ok(seen, id .. " shows its melt")
		end
		-- the melt lowers DEF: the next blow on c counts 20% less of it
		local c = unitOf(fight, "c")
		a.skillReady.acid_rain, a.target = 1e9, c
		local next = firstOf(run(fight, 3), function(event: any): boolean
			return event.kind == "hit" and event.from == "a"
		end)
		local want = Combat.damage(10, 30 * 0.8, true) * Config.Classes.Kinds.alchemist.factor
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
				r.skillReady.piercing_shot = 1e9
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
			r.skillReady.piercing_shot = 1e9
			freeze(unitOf(edge, "f"), r)
			local hop = firstOf(run(edge, 0.3), function(event: any): boolean
				return event.kind == "move" and event.hop == true
			end)
			T.ok(hop ~= nil, "it hops at the edge")
			T.ok(math.sqrt(hop.tx ^ 2 + hop.tz ^ 2) <= 70 + 1e-6, "inside the radius")
		end
	)

	-- ===== Step 4: independent Uncommon and Epic skills =====

	-- Set just one skill ready so each rule can be tested without another unlocked skill stealing the next beat.
	local function arm(fight: any, id: string, key: string): any
		local actor = unitOf(fight, id)
		for name in actor.skillReady do
			actor.skillReady[name] = 1e9
		end
		actor.skillReady[key] = 0
		return actor
	end

	local function castOf(events: { any }, key: string): any
		return firstOf(events, function(event: any): boolean
			return event.kind == "cast" and event.skill == key
		end)
	end

	local function firstSkillHit(events: { any }, key: string): any
		return firstOf(events, function(event: any): boolean
			return event.kind == "hit" and event.skill == key
		end)
	end

	T.test("tiers gate class skills and a tier-three Mage uses all three independent clocks", function()
		for tier = 1, 5 do
			local fight = Combat.new({ slime("m", "mage", { tier = tier }) }, {
				foe("a"),
				foe("b"),
				foe("c"),
			}, Rng.new(81))
			local m = unitOf(fight, "m")
			T.eq(m.skillReady.arcane_barrage ~= nil, true)
			T.eq(m.skillReady.frost_burst ~= nil, tier >= 2)
			T.eq(m.skillReady.arcane_lance ~= nil, tier >= 3)
			for _, id in { "a", "b", "c" } do
				freeze(unitOf(fight, id))
			end
			if tier == 1 then
				local events = run(fight, 10)
				T.eq(castOf(events, "frost_burst"), nil)
				T.eq(castOf(events, "arcane_lance"), nil)
				T.eq(castOf(events, "arcane_barrage"), nil, "Common skills keep their earlier events")
			end
		end
		local fight = Combat.new({ slime("m", "mage", { tier = 3 }) }, {
			foe("a"),
			foe("b"),
			foe("c"),
		}, Rng.new(81))
		local m = unitOf(fight, "m")
		for key in m.skillReady do
			m.skillReady[key] = 0
		end
		for _, id in { "a", "b", "c" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 5)
		local keys: { string } = {}
		for _, event in events do
			if event.kind == "hit" and event.from == "m" and event.skill and not table.find(keys, event.skill) then
				table.insert(keys, event.skill)
			end
		end
		T.same({ keys[1], keys[2], keys[3] }, { "arcane_lance", "frost_burst", "arcane_barrage" })
		T.ok(m.skillReady.arcane_lance > fight.seconds and m.skillReady.frost_burst > fight.seconds)
		T.ok(m.skillReady.arcane_barrage > fight.seconds, "Common has its own timer too")
	end)

	T.test("Shield Bash casts first, strikes one target at tier power and stuns it", function()
		local fight = Combat.new({ slime("g", "guardian", { tier = 2 }) }, { foe("a"), foe("b") }, Rng.new(82))
		arm(fight, "g", "shield_bash")
		freeze(unitOf(fight, "a"))
		freeze(unitOf(fight, "b"))
		local events = run(fight, 3)
		local cast, hit = castOf(events, "shield_bash"), firstSkillHit(events, "shield_bash")
		T.ok(cast ~= nil and hit ~= nil)
		T.eq(cast.to, hit.to)
		T.near(
			hit.amount,
			Combat.damage(10, 0)
				* Config.Classes.Kinds.guardian.factor
				* Config.Classes.SkillPower[2]
				* Skills.shield_bash.power,
			1e-9
		)
		local statusEvent = firstOf(events, function(e: any): boolean
			return e.status == "stunned" and e.skill == "shield_bash"
		end)
		T.ok(statusEvent ~= nil and statusEvent.to == hit.to)
		T.eq(statusEvent.seconds, Skills.shield_bash.stun)
		local sawCast = false
		for _, event in events do
			if event == cast then
				sawCast = true
			elseif event == hit then
				T.ok(sawCast, "cast is before hit")
				break
			end
		end
	end)

	T.test("Area Slash needs two nearby foes and weighs every target equally", function()
		local fight = Combat.new({ slime("w", "warrior", { tier = 2 }) }, { foe("a"), foe("b"), foe("c") }, Rng.new(83))
		arm(fight, "w", "area_slash")
		for _, id in { "a", "b", "c" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 3)
		T.ok(castOf(events, "area_slash") ~= nil)
		local struck = 0
		for _, event in events do
			if event.kind == "hit" and event.skill == "area_slash" then
				struck += 1
				T.near(
					event.amount,
					Combat.damage(10, 0)
						* Config.Classes.Kinds.warrior.factor
						* Config.Classes.SkillPower[2]
						* Skills.area_slash.power,
					1e-9
				)
			end
		end
		T.eq(struck, Skills.area_slash.cap)
		local alone = Combat.new({ slime("w", "warrior", { tier = 2 }) }, { foe("a") }, Rng.new(83))
		arm(alone, "w", "area_slash")
		freeze(unitOf(alone, "a"))
		T.eq(castOf(run(alone, 3), "area_slash"), nil)
		T.eq(unitOf(alone, "w").skillReady.area_slash, 0, "worthless skill keeps its cooldown")
	end)

	T.test("Arrow Volley turns to the densest reachable group, not a lone target", function()
		local fight = Combat.new({ slime("r", "ranger", { tier = 2, x = 0, z = 0 }) }, {
			foe("lone", { x = 10, z = 0, defence = 50 }),
			foe("a", { x = 0, z = 12, defence = 10 }),
			foe("b", { x = 2, z = 12, defence = 30 }),
			foe("c", { x = 0, z = 14, defence = 10 }),
		}, Rng.new(84), { moves = true })
		local r = arm(fight, "r", "arrow_volley")
		r.target = unitOf(fight, "lone")
		for _, id in { "lone", "a", "b", "c" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 3)
		local cast = castOf(events, "arrow_volley")
		T.ok(cast ~= nil and cast.to == "b")
		local hit = firstSkillHit(events, "arrow_volley")
		T.eq(hit.to, "b")
		T.near(
			hit.amount,
			Combat.damage(10, 30)
				* Config.Classes.Kinds.ranger.factor
				* Config.Classes.SkillPower[2]
				* Skills.arrow_volley.power,
			1e-9
		)
		local count = 0
		for _, e in events do
			if e.kind == "hit" and e.skill == "arrow_volley" then
				count += 1
				T.ok(e.to ~= "lone")
			end
		end
		T.eq(count, 3)
	end)

	T.test("Frost Burst slows every surviving foe, bosses at their smaller cap", function()
		local fight = Combat.new({ slime("m", "mage", { tier = 2 }) }, {
			foe("ordinary"),
			foe("boss", { defRole = "boss" }),
		}, Rng.new(85))
		arm(fight, "m", "frost_burst")
		for _, id in { "ordinary", "boss" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 3)
		T.ok(castOf(events, "frost_burst") ~= nil)
		for _, id in { "ordinary", "boss" } do
			local u = unitOf(fight, id)
			T.near(u.slowBy, if id == "boss" then Config.Classes.SlowCapBoss else Skills.frost_burst.slow, 1e-9)
			local statusEvent = firstOf(events, function(e: any): boolean
				return e.kind == "status" and e.to == id and e.status == "slowed"
			end)
			T.ok(statusEvent ~= nil and statusEvent.skill == "frost_burst")
			T.eq(statusEvent.seconds, Skills.frost_burst.seconds)
		end
		local single = Combat.new({ slime("m", "mage", { tier = 2 }) }, { foe("f") }, Rng.new(85))
		arm(single, "m", "frost_burst")
		freeze(unitOf(single, "f"))
		T.eq(castOf(run(single, 3), "frost_burst"), nil)
		T.eq(unitOf(single, "m").skillReady.frost_burst, 0)
	end)

	T.test("Healing Ring requires two hurt members and heals most hurt first even out of foe reach", function()
		local fight = Combat.new({
			slime("h", "healer", { tier = 2, x = 0, z = 0 }),
			slime("a", nil, { hp = 35, maxHp = 100, x = 4 }),
			slime("b", nil, { hp = 65, maxHp = 100, x = 6 }),
			slime("c", nil, { hp = 100, maxHp = 100, x = 8 }),
		}, { foe("f", { x = 50 }) }, Rng.new(86), { moves = true })
		arm(fight, "h", "healing_ring")
		for _, id in { "a", "b", "c", "f" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 3)
		local cast = castOf(events, "healing_ring")
		T.ok(cast ~= nil and cast.to == "h", "a team cast does not need a foe within attack reach")
		local healed: { string } = {}
		for _, event in events do
			if event.kind == "heal" and event.skill == "healing_ring" then
				table.insert(healed, event.to)
				T.near(event.amount, Combat.healAmount(10, Skills.healing_ring.factor), 1e-9)
			end
		end
		T.same(healed, { "a", "b" })
		local alone = Combat.new({
			slime("h", "healer", { tier = 2 }),
			slime("a", nil, { hp = 50, maxHp = 100 }),
		}, { foe("f") }, Rng.new(86))
		arm(alone, "h", "healing_ring")
		freeze(unitOf(alone, "a"))
		freeze(unitOf(alone, "f"))
		T.eq(castOf(run(alone, 3), "healing_ring"), nil)
		T.eq(unitOf(alone, "h").skillReady.healing_ring, 0)
	end)

	T.test("Squad Tonic buffs living allies for four seconds; dealt is capped at 25 percent", function()
		local fight = Combat.new({
			slime("a", "alchemist", { tier = 2 }),
			slime("w", "warrior"),
		}, { foe("f") }, Rng.new(87))
		local a = arm(fight, "a", "squad_tonic")
		freeze(unitOf(fight, "w"))
		freeze(unitOf(fight, "f"))
		local events = run(fight, 3)
		local cast = castOf(events, "squad_tonic")
		T.ok(cast ~= nil and cast.to == "a")
		T.eq(unitOf(fight, "w").effects.dealt.value, Skills.squad_tonic.dealt)
		local empowered = 0
		for _, e in events do
			if e.kind == "status" and e.status == "empowered" then
				empowered += 1
				T.eq(e.skill, "squad_tonic")
				T.eq(e.seconds, Skills.squad_tonic.seconds)
			end
		end
		T.eq(empowered, 2)
		local plain = firstOf(events, function(e: any): boolean
			return e.kind == "hit" and e.from == "a" and e.skill == nil
		end)
		T.ok(plain ~= nil, "a plain hit follows the Tonic")
		local expected = Combat.damage(10, 0, true)
			* Config.Classes.Kinds.alchemist.factor
			* (1 + Skills.squad_tonic.dealt)
		T.near(plain.amount, expected * (if plain.crit then Config.Combat.CritFactor else 1), 1e-9)
		a.effects.dealt = { value = 0.9, untilAt = fight.seconds + 5 }
		local capped = firstOf(run(fight, 2), function(e: any): boolean
			return e.kind == "hit" and e.from == "a" and e.skill == nil
		end)
		T.ok(capped ~= nil)
		T.near(
			capped.amount,
			Combat.damage(10, 0, true)
				* Config.Classes.Kinds.alchemist.factor
				* (1 + Config.Classes.Effects.dealt)
				* (if capped.crit then Config.Combat.CritFactor else 1),
			1e-9
		)
		local solo = Combat.new({ slime("a", "alchemist", { tier = 2 }) }, { foe("f") }, Rng.new(87))
		arm(solo, "a", "squad_tonic")
		freeze(unitOf(solo, "f"))
		T.eq(castOf(run(solo, 3), "squad_tonic"), nil)
		T.eq(unitOf(solo, "a").skillReady.squad_tonic, 0)
	end)

	T.test("Shield Wall protects two threatened mates, or one when it is the only mate", function()
		local function wall(single: boolean): ({ any }, any)
			local squad =
				{ slime("g", "guardian", { tier = 3, x = 0 }), slime("a", nil, { hp = 50, maxHp = 100, x = 5 }) }
			if not single then
				table.insert(squad, slime("b", nil, { hp = 30, maxHp = 100, x = 8 }))
			end
			local fight = Combat.new(
				squad,
				{ foe("f", { x = 45 }), foe("e", { x = 46 }) },
				Rng.new(88),
				{ moves = true }
			)
			arm(fight, "g", "shield_wall")
			for _, id in { "a", "b" } do
				if not single or id == "a" then
					freeze(unitOf(fight, id))
				end
			end
			freeze(unitOf(fight, "f"), unitOf(fight, "a"))
			freeze(unitOf(fight, "e"), unitOf(fight, if single then "a" else "b"))
			return run(fight, 3), fight
		end
		local events, fight = wall(false)
		T.ok(castOf(events, "shield_wall") ~= nil)
		for _, id in { "a", "b" } do
			T.eq(unitOf(fight, id).effects.taken.value, Skills.shield_wall.taken)
		end
		T.eq(unitOf(fight, "g").effects.taken, nil)
		local walled = 0
		for _, event in events do
			if event.kind == "status" and event.status == "walled" then
				walled += 1
				T.eq(event.skill, "shield_wall")
				T.eq(event.seconds, Skills.shield_wall.seconds)
			end
		end
		T.eq(walled, 2)
		local one, alone = wall(true)
		T.ok(castOf(one, "shield_wall") ~= nil)
		T.eq(unitOf(alone, "a").effects.taken.value, Skills.shield_wall.taken)
		local noThreat = Combat.new({ slime("g", "guardian", { tier = 3 }), slime("a") }, { foe("f") }, Rng.new(88))
		arm(noThreat, "g", "shield_wall")
		freeze(unitOf(noThreat, "a"))
		freeze(unitOf(noThreat, "f"))
		T.eq(castOf(run(noThreat, 3), "shield_wall"), nil)
	end)

	T.test("Breaker Strike only strikes its target and ignores 20 percent of DEF", function()
		local fight = Combat.new({ slime("w", "warrior", { tier = 3 }) }, {
			foe("a", { defence = 50 }),
			foe("b", { defence = 50 }),
		}, Rng.new(89))
		arm(fight, "w", "breaker_strike")
		freeze(unitOf(fight, "a"))
		freeze(unitOf(fight, "b"))
		local events = run(fight, 3)
		T.ok(castOf(events, "breaker_strike") ~= nil)
		local hit = firstSkillHit(events, "breaker_strike")
		T.ok(hit ~= nil)
		T.near(
			hit.amount,
			Combat.damage(10, 50 * (1 - Skills.breaker_strike.ignore))
				* Config.Classes.Kinds.warrior.factor
				* Config.Classes.SkillPower[3]
				* Skills.breaker_strike.power,
			1e-9
		)
		local count = 0
		for _, e in events do
			if e.kind == "hit" and e.skill == "breaker_strike" then
				count += 1
			end
		end
		T.eq(count, 1)
	end)

	T.test("Snare Arrow chooses a melee pursuer; its slow respects boss duration and strongest cap", function()
		local fight = Combat.new({ slime("r", "ranger", { tier = 3, x = 0 }) }, {
			foe("far", { x = 14 }),
			foe("near", { x = 9 }),
			foe("other", { x = 12 }),
		}, Rng.new(90), { moves = true })
		local r = arm(fight, "r", "snare_arrow")
		r.target = unitOf(fight, "far")
		freeze(unitOf(fight, "far"))
		freeze(unitOf(fight, "near"), r)
		freeze(unitOf(fight, "other"), r)
		local events = run(fight, 3)
		T.eq(castOf(events, "snare_arrow").to, "near")
		T.eq(firstSkillHit(events, "snare_arrow").to, "near")
		T.eq(unitOf(fight, "near").slowBy, Skills.snare_arrow.slow)
		local bossFight = Combat.new({ slime("r", "ranger", { tier = 3 }) }, {
			foe("boss", { defRole = "boss" }),
		}, Rng.new(90))
		arm(bossFight, "r", "snare_arrow")
		freeze(unitOf(bossFight, "boss"))
		local bossEvents = run(bossFight, 3)
		local slowed = firstOf(bossEvents, function(e: any): boolean
			return e.status == "slowed" and e.skill == "snare_arrow"
		end)
		T.ok(slowed ~= nil)
		T.eq(slowed.seconds, Skills.snare_arrow.bossSeconds)
		T.eq(unitOf(bossFight, "boss").slowBy, Config.Classes.SlowCapBoss)
		local stronger = Combat.new({ slime("r", "ranger", { tier = 3 }) }, { foe("f") }, Rng.new(90))
		arm(stronger, "r", "snare_arrow")
		local victim = unitOf(stronger, "f")
		freeze(victim)
		victim.slowBy, victim.slowUntil = Config.Classes.SlowCap, 100
		run(stronger, 3)
		T.eq(victim.slowBy, Config.Classes.SlowCap, "a weaker class slow does not replace a stronger one")
		T.eq(victim.slowUntil, 100)
		local old = Skills.snare_arrow.slow
		Skills.snare_arrow.slow = 0.8
		local capFight = Combat.new({ slime("r", "ranger", { tier = 3 }) }, { foe("f") }, Rng.new(90))
		arm(capFight, "r", "snare_arrow")
		freeze(unitOf(capFight, "f"))
		run(capFight, 3)
		T.eq(unitOf(capFight, "f").slowBy, Config.Classes.SlowCap)
		Skills.snare_arrow.slow = old
	end)

	T.test("Arcane Lance weighs 1.35 against an active barrier and is single-target magic", function()
		local fight = Combat.new({ slime("m", "mage", { tier = 3 }) }, {
			foe("a", { defence = 20 }),
			foe("b", { defence = 20 }),
		}, Rng.new(91))
		arm(fight, "m", "arcane_lance")
		local target = unitOf(fight, "a")
		target.barrier, target.barrierUntil = 1000, 100
		unitOf(fight, "m").target = target
		freeze(target)
		freeze(unitOf(fight, "b"))
		local events = run(fight, 3)
		T.ok(castOf(events, "arcane_lance") ~= nil)
		local hit = firstSkillHit(events, "arcane_lance")
		T.eq(hit.to, "a")
		local expected = Combat.damage(10, 20, true)
			* Config.Classes.Kinds.mage.factor
			* Config.Classes.SkillPower[3]
			* Skills.arcane_lance.power
			* Skills.arcane_lance.barrier
		T.near(hit.amount, 0, 1e-9)
		T.near(hit.absorbed, expected, 1e-9)
	end)

	T.test("Ward caps at 20 percent max HP, absorbs health damage, ends when used up or expired", function()
		local function wardFight(): any
			local fight = Combat.new({
				slime("h", "healer", { tier = 3, attack = 300, x = 0 }),
				slime("m", nil, { hp = 60, maxHp = 100, x = 10 }),
			}, { foe("f", { attack = 100, x = 45 }) }, Rng.new(92), { moves = true })
			arm(fight, "h", "ward")
			freeze(unitOf(fight, "m"))
			freeze(unitOf(fight, "f"), unitOf(fight, "m"))
			return fight
		end
		local fight = wardFight()
		local events = run(fight, 3)
		T.ok(castOf(events, "ward") ~= nil)
		local mate = unitOf(fight, "m")
		T.near(mate.barrier, mate.maxHp * Skills.ward.share, 1e-9)
		local applied = firstOf(events, function(e: any): boolean
			return e.status == "warded" and e.seconds > 0
		end)
		T.ok(applied ~= nil and applied.to == "m" and applied.skill == "ward")
		local expiry = mate.barrierUntil
		run(fight, expiry - fight.seconds + DT)
		T.eq(mate.barrier, 0, "a barrier expires without stacking")
		local consumed = wardFight()
		run(consumed, 3)
		local cm = unitOf(consumed, "m")
		local f = unitOf(consumed, "f")
		-- (the Healer stops here: its plain heal would hide what the blow takes)
		freeze(unitOf(consumed, "h"))
		-- Bring the frozen foe into range only after the Ward exists, so its one blow exhausts the barrier.
		f.x, f.z = cm.x + 4, cm.z
		f.aimed, f.cooldown = false, 0.4
		local earlier = cm.hp
		local hits = run(consumed, 0.6)
		local hit = firstOf(hits, function(e: any): boolean
			return e.kind == "hit" and e.from == "f" and e.to == "m"
		end)
		T.ok(hit ~= nil and hit.absorbed ~= nil)
		T.near(hit.absorbed, cm.maxHp * Skills.ward.share, 1e-9)
		T.near(earlier - cm.hp, hit.amount, 1e-9)
		local ended = firstOf(hits, function(e: any): boolean
			return e.kind == "status" and e.status == "warded" and e.seconds == 0
		end)
		T.ok(ended ~= nil and ended.to == "m", "the look ends immediately when the barrier breaks")
	end)

	T.test("Cursed Flask needs an enemy healer and suppresses monster and class healing by 35 percent", function()
		local fight = Combat.new({ slime("a", "alchemist", { tier = 3 }) }, {
			foe("healer", { kind = "healer", attack = 10 }),
			foe("low", { hp = 50, maxHp = 100 }),
			foe("high", { hp = 80, maxHp = 100 }),
		}, Rng.new(93))
		arm(fight, "a", "cursed_flask")
		for _, id in { "healer", "low", "high" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 3)
		local cast = castOf(events, "cursed_flask")
		T.ok(cast ~= nil and cast.to == "low")
		T.eq(firstSkillHit(events, "cursed_flask"), nil, "a curse does no damage")
		T.eq(unitOf(fight, "low").effects.curse.value, Skills.cursed_flask.curse)
		local cursed = firstOf(events, function(e: any): boolean
			return e.kind == "status" and e.status == "cursed"
		end)
		T.ok(cursed ~= nil and cursed.to == "low" and cursed.skill == "cursed_flask")
		local h = unitOf(fight, "healer")
		h.aimed, h.cooldown = false, 0.4
		local healEvents = run(fight, 2)
		local healed = firstOf(healEvents, function(e: any): boolean
			return e.kind == "heal" and e.from == "healer" and e.to == "low"
		end)
		T.ok(healed ~= nil)
		T.near(healed.amount, h.attack * Config.Combat.Heals.healer.share * (1 - Skills.cursed_flask.curse), 1e-9)
		-- A shaman's every-third Mend is a different code path from its ordinary heal.
		local special = Combat.new({ slime("a", "alchemist", { tier = 3 }) }, {
			foe("healer", { kind = "healer", skills = { "bloom_mend" }, attack = 10 }),
			foe("low", { hp = 50, maxHp = 100 }),
		}, Rng.new(95))
		arm(special, "a", "cursed_flask")
		freeze(unitOf(special, "healer"))
		freeze(unitOf(special, "low"))
		run(special, 3)
		local shaman = unitOf(special, "healer")
		shaman.mends = Skills.bloom_mend.every - 1
		shaman.aimed, shaman.cooldown = false, 0.4
		local burst = firstOf(run(special, 2), function(e: any): boolean
			return e.kind == "heal" and e.from == "healer" and e.to == "low" and e.skill == "bloom_mend"
		end)
		T.ok(burst ~= nil)
		T.near(burst.amount, shaman.attack * Skills.bloom_mend.share * (1 - Skills.cursed_flask.curse), 1e-9)
		local classFight = Combat.new({ slime("a", "alchemist", { tier = 3 }) }, {
			foe("h", { class = "healer", role = "healer", attack = 10 }),
			foe("m", { hp = 50, maxHp = 100 }),
		}, Rng.new(94))
		arm(classFight, "a", "cursed_flask")
		freeze(unitOf(classFight, "h"))
		freeze(unitOf(classFight, "m"))
		run(classFight, 3)
		local m = unitOf(classFight, "m")
		T.eq(m.effects.curse.value, Skills.cursed_flask.curse)
		local ch = unitOf(classFight, "h")
		ch.skillReady.mend = 1e9
		ch.aimed, ch.cooldown = false, 0.4
		local classEvents = run(classFight, 2)
		local classHeal = firstOf(classEvents, function(e: any): boolean
			return e.kind == "heal" and e.from == "h" and e.to == "m"
		end)
		T.ok(classHeal ~= nil)
		T.near(
			classHeal.amount,
			Combat.healAmount(10, Config.Classes.PlainHeal) * (1 - Skills.cursed_flask.curse),
			1e-9
		)
		local noHealer = Combat.new({ slime("a", "alchemist", { tier = 3 }) }, { foe("f") }, Rng.new(93))
		arm(noHealer, "a", "cursed_flask")
		freeze(unitOf(noHealer, "f"))
		T.eq(castOf(run(noHealer, 3), "cursed_flask"), nil)
		T.eq(unitOf(noHealer, "a").skillReady.cursed_flask, 0)
	end)

	T.test("single-target Epic and Bash skills do not cast beyond reach; Volley needs a group", function()
		for _, entry in
			{
				{ class = "guardian", key = "shield_bash", tier = 2 },
				{ class = "warrior", key = "breaker_strike", tier = 3 },
				{ class = "ranger", key = "snare_arrow", tier = 3 },
				{ class = "mage", key = "arcane_lance", tier = 3 },
			}
		do
			local fight = Combat.new({ slime("s", entry.class, { tier = entry.tier, x = 0 }) }, {
				foe("f", { x = 100 }),
			}, Rng.new(96), { moves = true })
			arm(fight, "s", entry.key)
			freeze(unitOf(fight, "f"))
			local events = run(fight, 4)
			T.eq(castOf(events, entry.key), nil, entry.key .. " is not worth casting from far away")
			T.eq(unitOf(fight, "s").skillReady[entry.key], 0)
		end
		local volley = Combat.new({ slime("r", "ranger", { tier = 2 }) }, { foe("f") }, Rng.new(97))
		arm(volley, "r", "arrow_volley")
		freeze(unitOf(volley, "f"))
		T.eq(castOf(run(volley, 3), "arrow_volley"), nil)
		T.eq(unitOf(volley, "r").skillReady.arrow_volley, 0)
		local ward = Combat.new({ slime("h", "healer", { tier = 3 }), slime("m") }, { foe("f") }, Rng.new(97))
		arm(ward, "h", "ward")
		freeze(unitOf(ward, "m"))
		freeze(unitOf(ward, "f"), unitOf(ward, "m"))
		T.eq(castOf(run(ward, 3), "ward"), nil, "a healthy ally is not warded")
		T.eq(unitOf(ward, "h").skillReady.ward, 0)
	end)

	T.test("a Ring whose mates recover during its wind-up becomes a plain blow without a cooldown", function()
		local fight = Combat.new({
			slime("h", "healer", { tier = 2 }),
			slime("a", nil, { hp = 30, maxHp = 100 }),
			slime("b", nil, { hp = 40, maxHp = 100 }),
		}, { foe("f") }, Rng.new(98))
		local h = arm(fight, "h", "healing_ring")
		for _, id in { "a", "b", "f" } do
			freeze(unitOf(fight, id))
		end
		local aim: any = nil
		for _ = 1, 25 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "aim" and event.from == "h" and event.skill == "healing_ring" then
					aim = event
				end
			end
			if aim then
				break
			end
		end
		T.ok(aim ~= nil, "Ring was announced")
		unitOf(fight, "a").hp = 100
		unitOf(fight, "b").hp = 100
		local events = run(fight, 1)
		T.eq(castOf(events, "healing_ring"), nil)
		T.eq(h.skillReady.healing_ring, 0)
		local plain = firstOf(events, function(event: any): boolean
			return event.kind == "hit" and event.from == "h" and event.skill == nil
		end)
		T.ok(plain ~= nil, "the announced skill becomes a plain action")
	end)

	T.test("Healing Ring can heal its caster and a Ward never replaces a stronger live barrier", function()
		local ring = Combat.new({
			slime("h", "healer", { tier = 2, hp = 45, maxHp = 100 }),
			slime("m", nil, { hp = 35, maxHp = 100 }),
		}, { foe("f") }, Rng.new(99))
		arm(ring, "h", "healing_ring")
		freeze(unitOf(ring, "m"))
		freeze(unitOf(ring, "f"))
		local healed: { [string]: boolean } = {}
		for _, event in run(ring, 3) do
			if event.kind == "heal" and event.skill == "healing_ring" then
				healed[event.to] = true
			end
		end
		T.ok(healed.h and healed.m, "the caster is a valid Ring recipient")
		local ward = Combat.new({
			slime("h", "healer", { tier = 3, attack = 300 }),
			slime("m", nil, { hp = 50, maxHp = 100 }),
		}, { foe("f") }, Rng.new(99))
		arm(ward, "h", "ward")
		local mate = unitOf(ward, "m")
		mate.barrier, mate.barrierUntil = 25, 100
		freeze(mate)
		freeze(unitOf(ward, "f"), mate)
		local events = run(ward, 3)
		T.ok(castOf(events, "ward") ~= nil)
		T.eq(mate.barrier, 25, "a weaker Ward cannot overwrite a stronger barrier")
		T.eq(mate.barrierUntil, 100)
		T.eq(
			firstOf(events, function(e: any): boolean
				return e.status == "warded" and e.seconds > 0
			end),
			nil
		)
	end)


	-- ===== Step 5: Mythic ultimates, one side-wide announcement clock, and Legendary traits =====

	T.test("Mythic skill gates, first-ready clock and a late entrant's own twelve seconds", function()
		for _, entry in {
			{ class = "guardian", key = "bulwark" },
			{ class = "warrior", key = "whirlwind" },
			{ class = "ranger", key = "arrow_rain" },
			{ class = "mage", key = "meteor" },
			{ class = "healer", key = "sanctuary" },
			{ class = "alchemist", key = "catalyst_cloud" },
		} do
			for tier = 1, 5 do
				local fight = Combat.new({ slime("s", entry.class, { tier = tier }) }, { foe("f") }, Rng.new(101))
				local u = unitOf(fight, "s")
				T.eq(u.skillReady[entry.key] ~= nil, tier >= 4)
				if tier >= 4 then
					T.eq(u.skillReady[entry.key], Skills[entry.key].first)
				end
			end
		end
		local fight = Combat.new({ slime("s") }, { foe("f") }, Rng.new(102))
		freeze(unitOf(fight, "s"))
		freeze(unitOf(fight, "f"))
		run(fight, 6)
		local added = Combat.add(fight, slime("new", "mage", { tier = 5 }), "squad")
		T.ok(added ~= nil)
		T.near(added.skillReady.meteor, fight.seconds + Skills.meteor.first, 1e-9)
		T.near(
			added.skillReady.arcane_lance,
			Config.Combat.OpeningCooldown + Skills.arcane_lance.cooldown * Config.Classes.OpeningShare,
			1e-9
		)
	end)

	T.test("Mythic ultimates start their twenty-four second cooldown at cast, not aim", function()
		local fight = Combat.new({ slime("m", "mage", { tier = 4 }) }, {
			foe("a"), foe("b"),
		}, Rng.new(103))
		local m = arm(fight, "m", "meteor")
		m.cooldown = 0.4
		freeze(unitOf(fight, "a"))
		freeze(unitOf(fight, "b"))
		local aimAt: number? = nil
		local castAt: number? = nil
		for _ = 1, 40 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "aim" and event.skill == "meteor" then
					aimAt = fight.seconds
					T.eq(m.skillReady.meteor, 0, "aim does not spend the clock")
				elseif event.kind == "cast" and event.skill == "meteor" then
					castAt = fight.seconds
				end
			end
			if castAt then
				break
			end
		end
		T.ok(aimAt ~= nil and castAt ~= nil)
		T.near((castAt :: number) - (aimAt :: number), Skills.meteor.windup, DT + 1e-6)
		T.near(m.skillReady.meteor, (castAt :: number) + Skills.meteor.cooldown, 1e-9)
		T.eq(fight.ultimateAt.squad, aimAt)
		T.eq(m.skillReady.arcane_lance, 1e9, "other cooldowns did not change")
	end)

	T.test("ultimate announcements are staggered on one side but independent between sides", function()
		local fight = Combat.new({
			slime("a", "mage", { tier = 4 }),
			slime("b", "mage", { tier = 4 }),
		}, {
			slime("x", "mage", { tier = 4 }),
			foe("y"),
		}, Rng.new(104))
		for _, id in { "a", "b", "x" } do
			local u = arm(fight, id, "meteor")
			u.cooldown = 0.4
		end
		freeze(unitOf(fight, "y"))
		local aimed: { [string]: { number } } = { a = {}, b = {}, x = {} }
		for _ = 1, 100 do
			for _, event in Combat.step(fight, DT) do
				if event.kind == "aim" and event.skill == "meteor" then
					table.insert(aimed[event.from], fight.seconds)
				end
			end
			if #aimed.a + #aimed.b >= 2 and #aimed.x >= 1 then
				break
			end
		end
		T.eq(#aimed.a, 1)
		T.eq(#aimed.b, 1)
		T.ok(#aimed.x >= 1, "other side announces its own ultimate")
		T.ok(
			math.abs(aimed.a[1] - aimed.b[1]) >= Config.Classes.UltimateGap - 1e-6,
			"same-side announcements have the whole gap"
		)
		T.near(aimed.x[1], math.min(aimed.a[1], aimed.b[1]), DT + 1e-6)
	end)

	T.test("Whirlwind, Arrow Rain and Meteor wind up fully; ordinary aims keep the old lead", function()
		for _, entry in {
			{ class = "warrior", key = "whirlwind" },
			{ class = "ranger", key = "arrow_rain" },
			{ class = "mage", key = "meteor" },
		} do
			local fight = Combat.new({ slime("s", entry.class, { tier = 4 }) }, {
				foe("a"), foe("b"),
			}, Rng.new(105))
			local u = arm(fight, "s", entry.key)
			u.cooldown = 0.4
			freeze(unitOf(fight, "a"))
			freeze(unitOf(fight, "b"))
			local aimAt: number? = nil
			local castAt: number? = nil
			for _ = 1, 40 do
				for _, event in Combat.step(fight, DT) do
					if event.kind == "aim" and event.skill == entry.key then
						aimAt = fight.seconds
					elseif event.kind == "cast" and event.skill == entry.key then
						castAt = fight.seconds
					end
				end
				if castAt then
					break
				end
			end
			T.ok(aimAt ~= nil and castAt ~= nil, entry.key .. " fires")
			T.near((castAt :: number) - (aimAt :: number), Skills[entry.key].windup, DT + 1e-6)
		end
		local plain = Combat.new({ slime("m", "mage", { tier = 3 }) }, { foe("f") }, Rng.new(105))
		local u = unitOf(plain, "m")
		for key in u.skillReady do
			u.skillReady[key] = 1e9
		end
		u.cooldown = 0.4
		freeze(unitOf(plain, "f"))
		local aimAt: number? = nil
		local hitAt: number? = nil
		for _ = 1, 20 do
			for _, event in Combat.step(plain, DT) do
				if event.kind == "aim" and event.from == "m" then
					aimAt = plain.seconds
					T.eq(event.skill, nil)
				elseif event.kind == "hit" and event.from == "m" and not hitAt then
					hitAt = plain.seconds
				end
			end
			if hitAt then
				break
			end
		end
		T.near((hitAt :: number) - (aimAt :: number), Config.Combat.WindupSeconds, DT + 1e-6)
	end)

	T.test("stuns during an ultimate wind-up delay its cast and cancellation keeps the cooldown", function()
		local fight = Combat.new({ slime("m", "mage", { tier = 4 }) }, {
			foe("a"), foe("b"),
		}, Rng.new(106))
		local m = arm(fight, "m", "meteor")
		m.cooldown = 0.4
		freeze(unitOf(fight, "a"))
		freeze(unitOf(fight, "b"))
		local aimAt: number? = nil
		for _ = 1, 10 do
			for _, e in Combat.step(fight, DT) do
				if e.kind == "aim" and e.skill == "meteor" then
					aimAt = fight.seconds
				end
			end
			if aimAt then
				break
			end
		end
		T.ok(aimAt ~= nil)
		Combat.stun(fight, m, 1)
		local castAt: number? = nil
		for _ = 1, 40 do
			for _, e in Combat.step(fight, DT) do
				if e.kind == "cast" and e.skill == "meteor" then
					castAt = fight.seconds
				end
			end
			if castAt then
				break
			end
		end
		T.ok(castAt ~= nil)
		T.near((castAt :: number) - (aimAt :: number), Skills.meteor.windup + 1, DT + 1e-6)
		local lost = Combat.new({ slime("m", "mage", { tier = 4 }) }, {
			foe("a"), foe("b"),
		}, Rng.new(107))
		local caster = arm(lost, "m", "meteor")
		caster.cooldown = 0.4
		freeze(unitOf(lost, "a"))
		freeze(unitOf(lost, "b"))
		local announced = false
		for _ = 1, 10 do
			for _, e in Combat.step(lost, DT) do
				if e.kind == "aim" and e.skill == "meteor" then
					announced = true
				end
			end
			if announced then
				break
			end
		end
		T.ok(announced)
		unitOf(lost, "b").hp = 0
		local events = run(lost, 2)
		T.eq(castOf(events, "meteor"), nil)
		T.eq(caster.skillReady.meteor, 0)
		T.ok(firstOf(events, function(e: any): boolean
			return e.kind == "hit" and e.from == "m" and e.skill == nil
		end) ~= nil)
	end)

	T.test("four attack ultimates use one weight on all foes, need two or a boss, and cast first", function()
		for _, entry in {
			{ class = "warrior", key = "whirlwind" },
			{ class = "ranger", key = "arrow_rain" },
			{ class = "mage", key = "meteor" },
			{ class = "alchemist", key = "catalyst_cloud" },
		} do
			local s = Skills[entry.key]
			local enemies = {}
			for index = 1, s.cap + 1 do
				table.insert(enemies, foe("f" .. index, { defence = 20 }))
			end
			local fight = Combat.new({ slime("s", entry.class, { tier = 4 }) }, enemies, Rng.new(108))
			arm(fight, "s", entry.key)
			for _, enemy in enemies do
				freeze(unitOf(fight, enemy.id))
			end
			local events = run(fight, 4)
			T.ok(castOf(events, entry.key) ~= nil, entry.key .. " cast")
			local count = 0
			local started = false
			for _, e in events do
				if e.kind == "cast" and e.skill == entry.key then
					started = true
				elseif e.kind == "hit" and e.skill == entry.key then
					T.ok(started, "cast precedes damage")
					count += 1
					local magic = Config.Classes.Kinds[entry.class].magic
					local want = Combat.damage(10, 20, magic) * Config.Classes.Kinds[entry.class].factor
						* Config.Classes.SkillPower[4] * s.power
					T.near(e.amount, want, 1e-9)
				end
			end
			T.eq(count, s.cap)
			local ordinary = Combat.new({ slime("s", entry.class, { tier = 4 }) }, {
				foe("one"),
			}, Rng.new(109))
			arm(ordinary, "s", entry.key)
			freeze(unitOf(ordinary, "one"))
			T.eq(castOf(run(ordinary, 4), entry.key), nil, "one ordinary foe is not worthwhile")
			T.eq(unitOf(ordinary, "s").skillReady[entry.key], 0)
			local boss = Combat.new({ slime("s", entry.class, { tier = 4 }) }, {
				foe("boss", { defRole = "boss" }),
			}, Rng.new(110))
			arm(boss, "s", entry.key)
			freeze(unitOf(boss, "boss"))
			T.ok(castOf(run(boss, 4), entry.key) ~= nil, "one boss warrants the ultimate")
		end
	end)

	T.test("Arrow Rain, Meteor and Catalyst Cloud aim at the densest reachable group", function()
		for _, entry in {
			{ class = "ranger", key = "arrow_rain" },
			{ class = "mage", key = "meteor" },
			{ class = "alchemist", key = "catalyst_cloud" },
		} do
			local fight = Combat.new({ slime("s", entry.class, { tier = 4, x = 0, z = 0 }) }, {
				foe("lone", { x = -12, z = 0, defence = 40 }),
				foe("a", { x = 10, z = 0, defence = 10 }),
				foe("b", { x = 12, z = 0, defence = 30 }),
				foe("c", { x = 11, z = 2, defence = 10 }),
			}, Rng.new(111), { moves = true })
			local u = arm(fight, "s", entry.key)
			u.target = unitOf(fight, "lone")
			for _, id in { "lone", "a", "b", "c" } do
				freeze(unitOf(fight, id))
			end
			local cast = castOf(run(fight, 4), entry.key)
			T.ok(cast ~= nil and cast.to == "b", "ties pick the higher DEF group centre")
		end
	end)


	T.test("Bulwark protects its whole team only when enough living members are threatened", function()
		local function defence(threats: number): (any, { any })
			local fight = Combat.new({
				slime("g", "guardian", { tier = 4 }),
				slime("a", nil, { hp = 80, maxHp = 100 }),
				slime("b", nil, { hp = 70, maxHp = 100 }),
			}, { foe("f"), foe("e") }, Rng.new(112))
			arm(fight, "g", "bulwark")
			freeze(unitOf(fight, "a"))
			freeze(unitOf(fight, "b"))
			freeze(unitOf(fight, "f"), unitOf(fight, "a"))
			freeze(unitOf(fight, "e"), unitOf(fight, if threats == 2 then "b" else "a"))
			return fight, run(fight, 3)
		end
		local fight, events = defence(2)
		local cast = castOf(events, "bulwark")
		T.ok(cast ~= nil and cast.to == "g")
		local shown = 0
		for _, e in events do
			if e.kind == "status" and e.status == Skills.bulwark.status then
				shown += 1
				T.eq(e.seconds, Skills.bulwark.seconds)
				T.eq(e.skill, "bulwark")
			end
		end
		T.eq(shown, 3)
		for _, id in { "g", "a", "b" } do
			local u = unitOf(fight, id)
			T.eq(u.effects.taken.value, Skills.bulwark.taken)
			T.eq(u.effects.steady.value, Skills.bulwark.steady)
		end
		local no, quiet = defence(1)
		T.eq(castOf(quiet, "bulwark"), nil)
		T.eq(unitOf(no, "g").skillReady.bulwark, 0)
		local solo = Combat.new({ slime("g", "guardian", { tier = 4 }) }, { foe("f") }, Rng.new(112))
		arm(solo, "g", "bulwark")
		freeze(unitOf(solo, "f"), unitOf(solo, "g"))
		T.ok(castOf(run(solo, 3), "bulwark") ~= nil, "one threatened lone Guardian is enough")
	end)

	T.test("Sanctuary heals up to four lowest-health allies and sanctifies only those healed", function()
		local fight = Combat.new({
			slime("h", "healer", { tier = 4, x = 0 }),
			slime("a", nil, { hp = 25, maxHp = 100, x = 2 }),
			slime("b", nil, { hp = 45, maxHp = 100, x = 4 }),
			slime("c", nil, { hp = 85, maxHp = 100, x = 6 }),
			slime("d", nil, { hp = 90, maxHp = 100, x = 8 }),
			slime("e", nil, { hp = 70, maxHp = 100, x = 10 }),
		}, { foe("f", { x = 60 }) }, Rng.new(113), { moves = true })
		arm(fight, "h", "sanctuary")
		for _, id in { "a", "b", "c", "d", "e", "f" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 3)
		T.ok(castOf(events, "sanctuary") ~= nil)
		local healed: { string } = {}
		local blessed: { [string]: boolean } = {}
		for _, e in events do
			if e.kind == "heal" and e.skill == "sanctuary" then
				table.insert(healed, e.to)
				T.near(e.amount, Combat.healAmount(10, Skills.sanctuary.factor), 1e-9)
			elseif e.status == "sanctified" then
				blessed[e.to] = true
				T.eq(e.skill, "sanctuary")
				T.eq(e.seconds, Skills.sanctuary.seconds)
			end
		end
		T.same(healed, { "a", "b", "e", "c" })
		for _, id in healed do
			T.ok(blessed[id])
			T.eq(unitOf(fight, id).effects.steady.value, Skills.sanctuary.steady)
		end
		T.eq(blessed.d, nil, "fifth wounded ally is not selected")
		local one = Combat.new({
			slime("h", "healer", { tier = 4 }),
			slime("a", nil, { hp = 50, maxHp = 100 }),
		}, { foe("f") }, Rng.new(113))
		arm(one, "h", "sanctuary")
		freeze(unitOf(one, "a"))
		freeze(unitOf(one, "f"))
		T.eq(castOf(run(one, 3), "sanctuary"), nil, "one ordinary wound is not urgent")
		local dire = Combat.new({
			slime("h", "healer", { tier = 4 }),
			slime("a", nil, { hp = 30, maxHp = 100 }),
		}, { foe("f") }, Rng.new(113))
		arm(dire, "h", "sanctuary")
		freeze(unitOf(dire, "a"))
		freeze(unitOf(dire, "f"))
		T.ok(castOf(run(dire, 3), "sanctuary") ~= nil, "one dire wound is urgent")
	end)

	T.test("Catalyst Cloud melts every surviving target for four seconds", function()
		local fight = Combat.new({ slime("a", "alchemist", { tier = 4 }) }, {
			foe("f"), foe("g"), foe("h"),
		}, Rng.new(114))
		arm(fight, "a", "catalyst_cloud")
		for _, id in { "f", "g", "h" } do
			freeze(unitOf(fight, id))
		end
		local events = run(fight, 3)
		T.ok(castOf(events, "catalyst_cloud") ~= nil)
		local melted: { [string]: boolean } = {}
		for _, e in events do
			if e.kind == "status" and e.status == "melted" and e.skill == "catalyst_cloud" then
				melted[e.to] = true
				T.eq(e.seconds, Skills.catalyst_cloud.seconds)
			end
		end
		for _, id in { "f", "g", "h" } do
			T.ok(melted[id])
			T.eq(unitOf(fight, id).effects.melt.value, Skills.catalyst_cloud.melt)
		end
	end)

	T.test("steady cuts stun after its diminishing returns and mini-boss caps, never over fifty percent", function()
		local fight = Combat.new({ slime("s") }, { foe("f") }, Rng.new(115))
		local s = unitOf(fight, "s")
		s.effects.steady = { value = Skills.bulwark.steady, untilAt = 20 }
		local before = s.cooldown
		Combat.stun(fight, s, 1)
		T.near(s.cooldown - before, 1 - Skills.bulwark.steady, 1e-9)
		local second = s.cooldown
		Combat.stun(fight, s, 1)
		T.near(s.cooldown - second, Config.Classes.StunSteps[2] * (1 - Skills.bulwark.steady), 1e-9)
		local capped = Combat.new({ slime("s") }, { foe("f") }, Rng.new(115))
		local c = unitOf(capped, "s")
		c.effects.steady = { value = 0.9, untilAt = 20 }
		local old = c.cooldown
		Combat.stun(capped, c, 1)
		T.near(c.cooldown - old, 1 - Config.Classes.Effects.steady, 1e-9)
		local mini = Combat.new({ slime("s") }, { foe("f", { defRole = "miniboss" }) }, Rng.new(115))
		local m = unitOf(mini, "f")
		m.effects.steady = { value = Skills.sanctuary.steady, untilAt = 20 }
		local base = m.cooldown
		Combat.stun(mini, m, 1)
		T.near(
			m.cooldown - base,
			Config.Classes.MiniStunCap * (1 - Skills.sanctuary.steady),
			1e-9
		)
	end)

	T.test("Last Stand prevents a lethal blow once and immediately taunts as an ordinary Taunt", function()
		local fight = Combat.new({
			slime("g", "guardian", { tier = 5, hp = 10, maxHp = 10 }),
			slime("m", nil, { hp = 100, maxHp = 100 }),
		}, {
			foe("f", { attack = 100 }),
			foe("q"),
		}, Rng.new(116))
		local g, m = unitOf(fight, "g"), unitOf(fight, "m")
		freeze(g)
		freeze(m)
		local f = unitOf(fight, "f")
		freeze(f, g)
		f.aimed, f.cooldown = false, 0.4
		local q = unitOf(fight, "q")
		freeze(q, m)
		local first = run(fight, 0.8)
		T.eq(g.hp, Config.Classes.Traits.guardian.left)
		T.eq(g.lastStandUsed, 1)
		local trait = firstOf(first, function(e: any): boolean
			return e.kind == "trait" and e.trait == "last_stand"
		end)
		T.ok(trait ~= nil and trait.from == "g" and trait.to == "g")
		T.eq(q.tauntBy, g)
		local taunt = firstOf(first, function(e: any): boolean
			return e.kind == "taunt" and e.to == "q"
		end)
		T.ok(taunt ~= nil and taunt.skill == Config.Classes.Traits.guardian.taunt)
		T.eq(g.effects.taken.value, Skills.taunt.taken)
		f.aimed, f.cooldown, f.target = false, 0.4, g
		local second = run(fight, 0.8)
		T.eq(g.hp, 0, "the second lethal blow finishes the Guardian")
		T.eq(firstOf(second, function(e: any): boolean
			return e.kind == "trait" and e.trait == "last_stand"
		end), nil, "Last Stand is once per fight")
	end)

	T.test("Momentum readies Dash Strike after kills and emits at most one event per step", function()
		local fight = Combat.new({ slime("w", "warrior", { tier = 5 }) }, {
			foe("a", { hp = 1, maxHp = 100 }),
			foe("b", { hp = 1, maxHp = 100 }),
		}, Rng.new(117))
		local w = arm(fight, "w", "area_slash")
		freeze(unitOf(fight, "a"))
		freeze(unitOf(fight, "b"))
		local events = run(fight, 3)
		local count = 0
		local at: number? = nil
		for _, e in events do
			if e.kind == "trait" and e.trait == "momentum" then
				count += 1
				at = w.momentumAt
			end
		end
		T.eq(count, 1)
		T.ok(at ~= nil)
		T.eq(w.skillReady.dash_strike, at)
		T.ok(w.skillReady.area_slash > 0, "the killing skill still starts its own cooldown")
	end)

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
