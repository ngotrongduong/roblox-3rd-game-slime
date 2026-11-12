-- The weapons in hand (Config.Weapons, drawn by client/SlimeWeapon with shared/WeaponMoves): every hand gear has the
-- owner's model, every family its places and moves, and every move starts and ends at rest with its strike inside it.
local Config = require("../../src/shared/Config")
local WeaponMoves = require("../../src/shared/WeaponMoves")

local W = Config.Weapons

local function three(t)
	return type(t) == "table"
		and #t == 3
		and type(t[1]) == "number"
		and type(t[2]) == "number"
		and type(t[3]) == "number"
end

return function(T)
	T.test("every hand gear has a model of its own, sized", function()
		local meshes = {}
		for id, piece in Config.Smithy.Gear do
			if piece.slot == "hand" then
				local model = W.Models[id]
				T.ok(model ~= nil, `{id} has no model`)
				if model then
					T.ok(model.mesh > 0, `{id} has no mesh`)
					T.ok(meshes[model.mesh] == nil, `{id} shares its mesh with {meshes[model.mesh]}`)
					meshes[model.mesh] = id
					T.ok(three(model.size) and model.size[1] > 0 and model.size[2] > 0, `{id} has no size`)
				end
				T.ok(W.Families[piece.family] ~= nil, `{id} names a missing family {piece.family}`)
			end
		end
		for id in W.Models do
			local piece = Config.Smithy.Gear[id]
			T.ok(piece ~= nil and piece.slot == "hand", `model {id} is no hand gear`)
		end
	end)

	T.test("every family has its texture, its Common piece, its places and its moves", function()
		for name, family in W.Families do
			T.ok(string.match(W.Textures[name] or "", "^rbxassetid://%d+$") ~= nil, `{name} has no texture`)
			T.ok(W.Models[name .. "-wood"] ~= nil, `{name} has no Common piece to size by`)
			T.ok(family.length > 0, `{name} has no length`)
			T.ok(three(family.grip), `{name} has no grip`)
			T.ok(family.muzzle >= 0 and family.muzzle <= 0.5, `{name}'s muzzle is off the piece`)
			for _, key in { "rest", "fight" } do
				local place = family[key]
				T.ok(place and three(place.at) and three(place.turn), `{name} has no {key} place`)
			end
			T.ok(WeaponMoves.Seconds[family.attack] ~= nil, `{name}'s attack {family.attack} is no move`)
			T.ok(WeaponMoves.Seconds[family.cast] ~= nil, `{name}'s cast {family.cast} is no move`)
		end
		T.ok(string.match(W.Textures.legend or "", "^rbxassetid://%d+$") ~= nil, "the Legendary set has no texture")
	end)

	T.test(
		"on the back at rest, the kit always at the left; in a fight the shield and bow in front, the rest right",
		function()
			local F = W.Families
			for name, family in F do
				if name == "kit" then
					T.ok(family.rest.at[1] < 0 and family.fight.at[1] < 0, "the kit is not at the left")
				else
					T.ok(family.rest.at[3] > 0.3, `{name} does not rest on the back`)
				end
			end
			for _, name in { "shield", "bow" } do
				T.ok(F[name].fight.at[3] < -0.3, `{name} is not in front in a fight`)
			end
			for _, name in { "sword", "focus", "staff" } do
				T.ok(F[name].fight.at[1] > 0.3, `{name} is not at the right in a fight`)
			end
		end
	)

	T.test("every move rests before and after, strikes inside, and stays near the body", function()
		for kind, seconds in WeaponMoves.Seconds do
			local strike = WeaponMoves.Strike[kind]
			T.ok(strike ~= nil and strike > 0 and strike < 1, `{kind} has no strike inside it`)
			for _, t in { -0.01, seconds, seconds + 1 } do
				local s = WeaponMoves.sample(kind, t)
				T.eq(s.rot, 0, `{kind} is not at rest at {t}`)
				T.eq(s.dx + s.dy, 0, `{kind} is not at rest at {t}`)
			end
			for step = 0, 20 do
				local s = WeaponMoves.sample(kind, seconds * step / 21)
				T.ok(s.rot == s.rot and math.abs(s.rot) <= math.pi * 3 + 1e-6, `{kind} turns too far`)
				T.ok(math.abs(s.dx) <= 0.6 and math.abs(s.dy) <= 0.7, `{kind} leaves the body at step {step}`)
			end
		end
		for name in W.Families do
			local s = WeaponMoves.idle(name, 12.3)
			T.ok(math.abs(s.rot) < 0.3 and math.abs(s.dy) < 0.1, `{name}'s idle sway is too big`)
		end
	end)
end
