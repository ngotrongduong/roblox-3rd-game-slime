-- The Dungeon monsters' effects (Config.Dungeon.Fx.Monsters and the body effects of Config.Dungeon.Looks): every effect
-- they name is imported from the VFX library, every special's art belongs to a special the monster has, and every body
-- effect rides a bone its rig has.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local Builder = require("../../src/shared/VfxLib/Builder")
local Config = require("../../src/shared/Config")

local D = Config.Dungeon

-- (the library's Schema reads Roblox's Enum, which Lune keeps out of a module's globals: it is loaded with Enum given)
local Schema = luau.load(fs.readFile("src/shared/VfxLib/Schema.luau"), {
	debugName = "VfxLib/Schema",
	environment = {
		Enum = roblox.Enum,
		require = function(path: string)
			return require(`../../src/shared/VfxLib/{string.sub(path, 3)}`)
		end,
	},
})()

local function imported(id: string): boolean
	local kind, name = string.match(id, "^(%a+)%.([%w_]+)$")
	return kind ~= nil and fs.isFile(`src/shared/VfxLib/Effects/{kind}/{name}.luau`)
end

return function(T)
	T.test("every monster effect is imported", function()
		for id, fx in D.Fx.Monsters do
			for _, field in { "blow", "fall", "heal" } do
				if fx[field] then
					T.ok(imported(fx[field]), `{id}.{field} {fx[field]}`)
				end
			end
			for key, art in fx.skills or {} do
				for _, field in { "windup", "release" } do
					if art[field] then
						T.ok(imported(art[field]), `{id}.skills.{key}.{field} {art[field]}`)
					end
				end
			end
		end
		for id, look in D.Looks do
			for _, fx in look.fx or {} do
				T.ok(imported(fx.effect), `{id} body effect {fx.effect}`)
			end
		end
	end)

	-- (the library refuses an effect with one bad piece whole, in Play: a negative `lift` on Frostmaw's drift took every
	-- monster's body effect away, 2026-11-12)
	T.test("every monster effect passes the library's schema", function()
		local ids: { [string]: boolean } = {}
		for _, fx in D.Fx.Monsters do
			for _, field in { "blow", "fall", "heal" } do
				if fx[field] then
					ids[fx[field]] = true
				end
			end
			for _, art in fx.skills or {} do
				for _, field in { "windup", "release" } do
					if art[field] then
						ids[art[field]] = true
					end
				end
			end
		end
		for _, look in D.Looks do
			for _, fx in look.fx or {} do
				ids[fx.effect] = true
			end
		end
		-- (the bosses' bursts and the regulars' pops, named by client/ZombieFight)
		ids["skill.monster_mark"] = true
		ids["skill.monster_impact"] = true
		ids["hit.monster_pop"] = true
		for id in ids do
			local kind, name = string.match(id, "^(%a+)%.([%w_]+)$")
			if kind and imported(id) then
				local effect = require(`../../src/shared/VfxLib/Effects/{kind}/{name}`)
				local problem = Schema.problem(effect, Builder.variantOf)
				T.ok(problem == nil, `{id}: {problem}`)
			end
		end
	end)

	-- (aura.monster_signature: each variant's numbers are studs on an anchor of its refHeight, so the anchor is that size)
	T.test("every body effect's variant is there, made for its anchor's size", function()
		local seen: { [string]: string } = {}
		for id, look in D.Looks do
			for _, fx in look.fx or {} do
				if not fx.variant then
					continue
				end
				local kind, name = string.match(fx.effect, "^(%a+)%.([%w_]+)$")
				local effect = require(`../../src/shared/VfxLib/Effects/{kind}/{name}`)
				local variant = effect.variants and effect.variants[fx.variant]
				T.ok(variant ~= nil, `{id} wears the variant {fx.variant}`)
				if variant then
					T.eq(variant.refHeight, fx.size, `{id} {fx.variant} is made for its anchor`)
				end
				local key = `{fx.effect}/{fx.variant}`
				T.ok(seen[key] == nil, `{id} wears the same effect as {seen[key]}`)
				seen[key] = id
			end
		end
	end)

	-- (skill.monster_windup / skill.monster_special: one variant per special, named by the special's `variant`)
	T.test("every special's variant is there in the effect that has variants", function()
		for id, fx in D.Fx.Monsters do
			for key, art in fx.skills or {} do
				if not art.variant then
					continue
				end
				for _, field in { "windup", "release" } do
					local effectId = art[field]
					if not effectId then
						continue
					end
					local kind, name = string.match(effectId, "^(%a+)%.([%w_]+)$")
					local effect = require(`../../src/shared/VfxLib/Effects/{kind}/{name}`)
					if effect.variants then
						T.ok(
							effect.variants[art.variant] ~= nil,
							`{id}.skills.{key}.{field} has the variant {art.variant}`
						)
					end
				end
			end
		end
	end)

	-- (Fx.Burst: a boss's special with a wind-up is called its `windup` early, and its element has a mark, an impact and
	-- a glow)
	T.test("every boss's burst has its wind-up time, its mark, its impact and its glow", function()
		local mark = require("../../src/shared/VfxLib/Effects/skill/monster_mark")
		local impact = require("../../src/shared/VfxLib/Effects/skill/monster_impact")
		for id, fx in D.Fx.Monsters do
			for key, art in fx.skills or {} do
				local s = (Config.Combat.Skills :: any)[key]
				if art.windup then
					T.ok(s and s.windup ~= nil, `{id}.skills.{key} has a wind-up, so a windup time`)
					T.ok(fx.element ~= nil, `{id} has wind-ups, so an element`)
				end
			end
			if fx.element then
				T.ok(mark.variants[fx.element] ~= nil, `{id}: skill.monster_mark has {fx.element}`)
				T.ok(impact.variants[fx.element] ~= nil, `{id}: skill.monster_impact has {fx.element}`)
				T.ok(D.Fx.Burst.Glow[fx.element] ~= nil, `{id}: Fx.Burst.Glow has {fx.element}`)
			end
		end
	end)

	-- (Fx.Pop: a regular monster's attacking special has a shorter tell, and its element a pop)
	T.test("every regular monster's attacking special pops", function()
		local pop = require("../../src/shared/VfxLib/Effects/hit/monster_pop")
		for _, map in D.Maps do
			for _, monster in map.monsters do
				if monster.role == "boss" or monster.role == "miniboss" then
					continue
				end
				for _, key in monster.skills or {} do
					local s = (Config.Combat.Skills :: any)[key]
					if s.kind == "mend" or s.kind == "guard" then
						continue
					end
					local fx = D.Fx.Monsters[monster.id]
					local art = fx and fx.skills and fx.skills[key]
					T.ok(s.windup ~= nil, `{monster.id}'s {key} has a windup time`)
					T.ok(art == nil or art.windup == nil, `{monster.id}'s {key} pops, it has no wind-up art`)
					T.ok(fx and fx.element ~= nil, `{monster.id} has an element`)
					if fx and fx.element then
						T.ok(pop.variants[fx.element] ~= nil, `hit.monster_pop has {fx.element}`)
					end
				end
			end
		end
	end)

	T.test("a monster's special art is for one of its own specials", function()
		local skillsOf: { [string]: { [string]: boolean } } = {}
		for _, map in D.Maps do
			for _, monster in map.monsters do
				local own = {}
				for _, key in monster.skills or {} do
					own[key] = true
				end
				skillsOf[monster.id] = own
			end
		end
		for id, fx in D.Fx.Monsters do
			T.eq(fx.skill, nil, `{id} names its specials' art by key (skills)`)
			for key in fx.skills or {} do
				T.ok(skillsOf[id] and skillsOf[id][key], `{id} has the special {key}`)
			end
		end
	end)

	T.test("every body effect rides a bone of its monster's rig", function()
		for id, look in D.Looks do
			if not look.fx then
				continue
			end
			local data = require(`../../src/shared/MonsterClips/{look.clips}`)
			local bones = {}
			for _, rest in data.rest do
				bones[rest[1]] = true
			end
			for _, fx in look.fx do
				T.ok(bones[fx.bone], `{id} ({look.clips}) has the bone {fx.bone}`)
				T.ok(type(fx.size) == "number" and fx.size > 0, `{id} {fx.effect} has a size`)
			end
		end
	end)
end
