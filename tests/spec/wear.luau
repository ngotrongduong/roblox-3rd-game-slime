-- Secret slimes' worn pieces (Config.Wear, drawn by client/SlimeWear): every entry names a real Secret and a kit, every
-- piece is whole, sits on the skin, and a flap swings softly.
local Config = require("../../src/shared/Config")
local SecretRecipes = require("../../src/shared/SecretRecipes")
local SlimeShape = require("../../src/shared/SlimeShape")

local W = Config.Wear

local function three(t)
	return type(t) == "table"
		and #t == 3
		and type(t[1]) == "number"
		and type(t[2]) == "number"
		and type(t[3]) == "number"
end

return function(T)
	T.test("every wearer is a Secret slime with a kit", function()
		local ids = {}
		for _, recipe in SecretRecipes.List do
			ids[recipe.id] = true
		end
		for id, kit in W.Secrets do
			T.ok(ids[id] == true, `{id} is not a Secret`)
			T.ok(W.Kits[kit] ~= nil, `{id} names a missing kit {kit}`)
		end
	end)

	T.test("every piece is whole and rests on the skin", function()
		for kitName, kit in W.Kits do
			T.ok(type(kit.texture) == "string" and string.match(kit.texture, "^rbxassetid://%d+$") ~= nil, kitName)
			local names = {}
			for _, piece in kit.pieces do
				local label = `{kitName}.{piece.name}`
				T.ok(names[piece.name] == nil, `{label} twice`)
				names[piece.name] = true
				T.ok(type(piece.mesh) == "number", label)
				T.ok(three(piece.size) and three(piece.at) and three(piece.anchor), label)
				for _, side in piece.size do
					T.ok(side > 0 and side < 1, `{label} size`)
				end
				-- the anchor is on the body's skin or just under it
				local x, y, z = piece.anchor[1], piece.anchor[2], piece.anchor[3]
				local r, skin = math.sqrt(x * x + z * z), SlimeShape.radius(y)
				T.ok(y >= 0 and y <= 1 and r <= skin + 0.02 and r >= skin - 0.15, `{label} anchor off the skin`)
				local flap = piece.flap
				if flap then
					T.ok(three(flap.axis), label)
					T.ok(flap.degrees > 0 and flap.degrees <= 30 and flap.hz > 0 and flap.hz <= 3, `{label} flap`)
				end
			end
		end
	end)

	T.test("a pair is mirrored across the body", function()
		for kitName, kit in W.Kits do
			local byName = {}
			for _, piece in kit.pieces do
				byName[piece.name] = piece
			end
			for name, piece in byName do
				local twin = string.match(name, "^(.+)L$")
				local other = twin and byName[twin .. "R"]
				if other then
					T.near(piece.at[1], -other.at[1], 1e-6, `{kitName}.{name}`)
					T.near(piece.anchor[1], -other.anchor[1], 1e-6, `{kitName}.{name}`)
					T.near(piece.at[3], other.at[3], 1e-6, `{kitName}.{name}`)
				end
			end
		end
	end)
end
