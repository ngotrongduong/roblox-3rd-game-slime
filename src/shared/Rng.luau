--!strict
-- A small seedable random number generator (mulberry32) for the farm rules.
-- Every rule takes an injected Rng instead of calling math.random, so a seed replays the same
-- outcome in tests, and the server can seed one per player from Random.new() later.
-- The helper methods (int, pick, weighted) consume rolls exactly like the original web game's
-- helpers, so the same sequence of rolls gives the same outcome as the original.

local Rng = {}

export type Rng = {
	-- A float in [0, 1).
	next: (self: Rng) -> number,
	-- An integer in [lo, hi], both ends included.
	int: (self: Rng, lo: number, hi: number) -> number,
	-- One entry of a non-empty list, each equally likely.
	pick: <T>(self: Rng, list: { T }) -> T,
	-- One entry of a non-empty list, chosen in proportion to weightFn(entry).
	weighted: <T>(self: Rng, list: { T }, weightFn: (T) -> number) -> T,
}

local TWO_32 = 4294967296

-- 32-bit multiply (like JS Math.imul): a plain multiply of two 32-bit numbers can exceed the
-- 53 bits a double holds exactly, so the product is built from 16-bit halves.
function Rng.imul(a: number, b: number): number
	a = bit32.band(a, 0xFFFFFFFF)
	b = bit32.band(b, 0xFFFFFFFF)
	local aHi, aLo = bit32.rshift(a, 16), bit32.band(a, 0xFFFF)
	local bHi, bLo = bit32.rshift(b, 16), bit32.band(b, 0xFFFF)
	local mid = (aHi * bLo + aLo * bHi) % 65536
	return (aLo * bLo + mid * 65536) % TWO_32
end

-- FNV-1a hash of a string as an unsigned 32-bit number (the original's per-slime seed).
function Rng.hash(text: string): number
	local h = 2166136261
	for i = 1, #text do
		h = bit32.bxor(h, string.byte(text, i))
		h = Rng.imul(h, 16777619)
	end
	return h
end

local function int(self: Rng, lo: number, hi: number): number
	return lo + math.floor(self:next() * (hi - lo + 1))
end

local function pick<T>(self: Rng, list: { T }): T
	return list[math.floor(self:next() * #list) + 1]
end

-- Same walk as the original weightedPick: subtract weights until the roll is used up; the last
-- entry catches any floating-point remainder.
local function weighted<T>(self: Rng, list: { T }, weightFn: (T) -> number): T
	local total = 0
	for _, entry in list do
		total += weightFn(entry)
	end
	local roll = self:next() * total
	for _, entry in list do
		roll -= weightFn(entry)
		if roll <= 0 then
			return entry
		end
	end
	return list[#list]
end

-- Wraps any source of floats in [0, 1) into an Rng.
function Rng.fromSource(source: () -> number): Rng
	local rng = {
		next = function(_self: Rng): number
			return source()
		end,
		int = int,
		pick = pick,
		weighted = weighted,
	}
	return rng :: any
end

-- A mulberry32 generator. Any number works as a seed; it is reduced to 32 bits.
function Rng.new(seed: number): Rng
	local state = bit32.band(math.floor(seed) % TWO_32, 0xFFFFFFFF)
	return Rng.fromSource(function(): number
		state = (state + 0x6D2B79F5) % TWO_32
		local t = Rng.imul(bit32.bxor(state, bit32.rshift(state, 15)), bit32.bor(state, 1))
		t = bit32.bxor(t, (t + Rng.imul(bit32.bxor(t, bit32.rshift(t, 7)), bit32.bor(t, 61))) % TWO_32)
		return bit32.bxor(t, bit32.rshift(t, 14)) / TWO_32
	end)
end

-- Replays a fixed list of rolls, then fails loudly: lets a test force one exact outcome
-- (for example "the secret roll hits") without searching for a seed.
function Rng.sequence(values: { number }): Rng
	local index = 0
	return Rng.fromSource(function(): number
		index += 1
		local value = values[index]
		if value == nil then
			error("Rng.sequence ran out of rolls after " .. tostring(#values), 2)
		end
		return value
	end)
end

return Rng
