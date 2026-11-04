--!strict
local ArenaSeason = if script then require(script.Parent.ArenaSeason) else require("./ArenaSeason")
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

type Rng = typeof(Rng.new(0))
export type Out = { seq: number, won: boolean, rankAfter: number, climbed: number, points: number, void: boolean? }
export type Meta = { n: string, p: number, sp: number, dw: number, seq: number, out: Out? }
export type Doc = { v: number, season: number, order: { string }, players: { [string]: Meta }, final: boolean? }
export type Result = {
	attacker: string,
	seq: number,
	defender: string,
	won: boolean,
	above: boolean,
	season: number,
	name: string,
	power: number,
}
export type Opponent = { id: string, rank: number?, above: boolean }
local ArenaLadder = {}

function ArenaLadder.new(season: number): Doc
	local order: { string } = {}
	for index = 1, Config.Arena.Bots do
		table.insert(order, "b" .. index)
	end
	return { v = Config.Arena.Version, season = season, order = order, players = {} }
end

function ArenaLadder.rankOf(doc: Doc, id: string): number?
	return table.find(doc.order, id)
end

function ArenaLadder.ranks(doc: Doc): { [string]: number }
	local ranks: { [string]: number } = {}
	for rank, id in doc.order do
		ranks[id] = rank
	end
	return ranks
end

function ArenaLadder.join(doc: Doc, id: string, name: string, power: number): number
	assert(not string.match(id, "^c%d+$"), "Champions cannot join the Arena ladder")
	local rank = ArenaLadder.rankOf(doc, id) or 0
	if rank == 0 then
		table.insert(doc.order, id)
		rank = #doc.order
	end
	local meta = doc.players[id]
	if meta then
		meta.n, meta.p = name, power
	else
		doc.players[id] = { n = name, p = power, sp = 0, dw = 0, seq = 0 }
	end
	return rank
end

function ArenaLadder.apply(doc: Doc, result: Result): (string, Out?)
	if doc.final or result.season ~= doc.season then
		return "void",
			{
				seq = result.seq,
				won = result.won,
				rankAfter = ArenaLadder.rankOf(doc, result.attacker) or 0,
				climbed = 0,
				points = 0,
				void = true,
			}
	end
	local meta = doc.players[result.attacker]
	if meta and result.seq <= meta.seq then
		return "dup", meta.out
	end
	local oldRank = ArenaLadder.join(doc, result.attacker, result.name, result.power)
	local joined = assert(doc.players[result.attacker], "join made the attacker's meta")
	local newRank = oldRank
	local defenderRank = ArenaLadder.rankOf(doc, result.defender)
	if result.won and defenderRank and defenderRank < oldRank then
		table.remove(doc.order, oldRank)
		table.insert(doc.order, defenderRank, result.attacker)
		newRank = defenderRank
	end
	local climbed = oldRank - newRank
	local points = ArenaSeason.winPoints(result.won, climbed, result.above)
	local out: Out = { seq = result.seq, won = result.won, rankAfter = newRank, climbed = climbed, points = points }
	joined.sp += points
	joined.seq, joined.out = result.seq, out
	local defender = doc.players[result.defender]
	if defender and not result.won then
		defender.dw += 1
	end
	return "applied", out
end

function ArenaLadder.opponents(doc: Doc, id: string, rng: Rng, count: number): { Opponent }
	local c = Config.Arena
	local r = ArenaLadder.rankOf(doc, id) or (#doc.order + 1)
	local lo, hi = math.max(1, math.floor(r * c.AboveShare)), r - 1
	local out: { Opponent } = {}
	local pools: { { number } } = {}
	for band = 1, c.OpponentBands do
		pools[band] = {}
	end
	for rank = lo, hi do
		local band = math.floor((rank - lo) * c.OpponentBands / (hi - lo + 1)) + 1
		table.insert(pools[band], rank)
	end
	local function take(band: number, wanted: number)
		local pool = pools[band]
		for _ = 1, math.min(wanted, #pool, count - #out) do
			local rank = table.remove(pool, rng:int(1, #pool)) :: number
			table.insert(out, { id = doc.order[rank], rank = rank, above = true })
		end
	end
	take(1, c.HardOpponents)
	take(2, c.MiddleOpponents)
	take(c.OpponentBands, count - #out)
	-- Small windows can exhaust a band; use every remaining rank above before offering a defence below.
	for band = c.OpponentBands, 1, -1 do
		take(band, count - #out)
	end
	for rank = r + 1, #doc.order do
		if #out >= count then
			break
		end
		table.insert(out, { id = doc.order[rank], rank = rank, above = false })
	end
	local champion = 1
	while #out < count do
		local championId = "c" .. champion
		if championId ~= id then
			table.insert(out, { id = championId, above = false })
		end
		champion += 1
	end
	return out
end

function ArenaLadder.top(doc: Doc, n: number): { { rank: number, id: string } }
	local out = {}
	for rank = 1, math.min(n, #doc.order) do
		table.insert(out, { rank = rank, id = doc.order[rank] })
	end
	return out
end

return ArenaLadder
