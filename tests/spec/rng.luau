local Rng = require("../../src/shared/Rng")

return function(T)
	T.test("mulberry32 matches the JavaScript reference", function()
		local r = Rng.new(12345)
		T.near(r:next(), 0.9797282677609473, 1e-12)
		T.near(r:next(), 0.3067522644996643, 1e-12)
		T.near(r:next(), 0.484205421525985, 1e-12)
		local z = Rng.new(0)
		T.near(z:next(), 0.26642920868471265, 1e-12)
		T.near(z:next(), 0.0003297457005828619, 1e-12)
	end)

	T.test("the same seed repeats the same rolls", function()
		local a, b = Rng.new(777), Rng.new(777)
		for _ = 1, 100 do
			T.eq(a:next(), b:next())
		end
		T.ok(Rng.new(1):next() ~= Rng.new(2):next(), "different seeds differ")
	end)

	T.test("next stays in [0, 1)", function()
		local r = Rng.new(42)
		for _ = 1, 10000 do
			local v = r:next()
			T.ok(v >= 0 and v < 1, "out of range: " .. v)
		end
	end)

	T.test("int covers both ends and nothing else", function()
		local r = Rng.new(5)
		local seen = {}
		for _ = 1, 2000 do
			local v = r:int(3, 7)
			T.ok(v >= 3 and v <= 7 and v == math.floor(v), "bad int " .. v)
			seen[v] = true
		end
		for v = 3, 7 do
			T.ok(seen[v], "never rolled " .. v)
		end
		T.eq(r:int(4, 4), 4)
	end)

	T.test("pick and weighted follow the rolls", function()
		local list = { "a", "b", "c", "d" }
		T.eq(Rng.sequence({ 0 }):pick(list), "a")
		T.eq(Rng.sequence({ 0.99 }):pick(list), "d")
		T.eq(Rng.sequence({ 0.5 }):pick(list), "c")
		local w = function(x: { w: number })
			return x.w
		end
		local items = { { w = 1 }, { w = 3 } }
		T.eq(Rng.sequence({ 0.2 }):weighted(items, w), items[1])
		T.eq(Rng.sequence({ 0.3 }):weighted(items, w), items[2])
		T.eq(Rng.sequence({ 0.999 }):weighted(items, w), items[2])
	end)

	T.test("weighted honours the weights over many rolls", function()
		local r = Rng.new(9)
		local items = { { w = 1 }, { w = 3 } }
		local heavy = 0
		for _ = 1, 20000 do
			if r:weighted(items, function(x)
				return x.w
			end) == items[2] then
				heavy += 1
			end
		end
		T.near(heavy / 20000, 0.75, 0.015)
	end)

	T.test("a sequence fails loudly when it runs out", function()
		local r = Rng.sequence({ 0.1 })
		r:next()
		T.throws(function()
			r:next()
		end)
	end)

	T.test("imul and hash match JavaScript", function()
		-- Math.imul(0x9e3779b9, 0x85ebca6b) >>> 0
		T.eq(Rng.imul(0x9e3779b9, 0x85ebca6b), 3238976083)
		-- FNV-1a of "" and "a"
		T.eq(Rng.hash(""), 2166136261)
		T.eq(Rng.hash("a"), 0xe40c292c)
	end)
end
