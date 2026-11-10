-- Secret slimes' worn pieces (Config.Wear, drawn by client/SlimeWear): every entry names a real Secret and a kit, every
-- piece is whole, sits on the skin (a tentacle under the body), and a flap swings softly.
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
				local x, y, z = piece.anchor[1], piece.anchor[2], piece.anchor[3]
				local r, skin = math.sqrt(x * x + z * z), SlimeShape.radius(y)
				local bones = piece.bones
				if bones then
					-- a tentacle grows from under the body, inside its rim, and wriggles
					T.ok(y >= 0 and y <= 0.25 and r <= skin + 0.02, `{label} not under the body`)
					T.ok(#bones >= 2, `{label} bones`)
					for _, bone in bones do
						T.ok(#bone == 9, `{label} bone frame`)
					end
					local wriggle = piece.wriggle
					T.ok(wriggle ~= nil and three(wriggle.axis), `{label} does not wriggle`)
					if wriggle then
						T.ok(
							wriggle.degrees > 0 and wriggle.degrees <= 30 and wriggle.curl >= 0 and wriggle.curl <= 45,
							label
						)
						T.ok(wriggle.hz > 0 and wriggle.hz <= 3 and wriggle.curlHz > 0 and wriggle.curlHz <= 1, label)
					end
				else
					-- the anchor is on the body's skin or just under it
					T.ok(y >= 0 and y <= 1 and r <= skin + 0.02 and r >= skin - 0.15, `{label} anchor off the skin`)
				end
				local flap = piece.flap
				if flap then
					T.ok(three(flap.axis), label)
					T.ok(flap.degrees > 0 and flap.degrees <= 30 and flap.hz > 0 and flap.hz <= 3, `{label} flap`)
				end
				local twitch = piece.twitch
				if twitch then
					T.ok(three(twitch.axis), label)
					T.ok(twitch.degrees > 0 and twitch.degrees <= 30, `{label} twitch`)
					T.ok(twitch.every > W.Twitch.Length * 2, `{label} twitches too often`)
				end
				local lag = piece.lag
				if lag then
					T.ok(three(lag.axis) and lag.degrees > 0 and lag.degrees <= 30, `{label} lag`)
				end
			end
		end
	end)

	-- (the owner, 2026-11-10: tails and ears move)
	T.test("every tail and ear moves", function()
		T.ok(W.Twitch.Out > 0 and W.Twitch.Out < W.Twitch.Length, "Twitch")
		T.ok(W.Lag.Rise > 0 and W.Lag.HalfLife > 0 and W.Lag.Gap > 0, "Lag")
		for kitName, kit in W.Kits do
			for _, piece in kit.pieces do
				local label = `{kitName}.{piece.name}`
				if string.match(piece.name, "^Tail") then
					T.ok(piece.flap ~= nil and piece.lag ~= nil, `{label} does not wag and trail`)
				elseif string.match(piece.name, "^Ear") then
					T.ok(piece.twitch ~= nil and piece.lag ~= nil, `{label} does not twitch and trail`)
				end
			end
		end
	end)

	-- (a mirrored twin matches exactly; a pair the file holds both of, such as two ears, is two meshes that differ a
	-- little, each seated on the skin by its own foot; two vines of one file wrapped at mirrored spots are two
	-- different vines, so their middles differ more)
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
					T.near(piece.anchor[1], -other.anchor[1], 0.005, `{kitName}.{name}`)
					T.near(piece.anchor[3], other.anchor[3], 0.005, `{kitName}.{name}`)
					T.near(piece.at[1], -other.at[1], 0.07, `{kitName}.{name}`)
					T.near(piece.at[3], other.at[3], 0.07, `{kitName}.{name}`)
				end
			end
		end
	end)
end
