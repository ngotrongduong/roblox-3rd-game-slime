--!strict
local ArenaSeason = if script then require(script.Parent.ArenaSeason) else require("./ArenaSeason")
local Config = if script then require(script.Parent.Config) else require("./Config")

export type State = {
	day: number,
	week: number,
	season: number,
	counts: { [string]: number },
	done: { [string]: boolean },
}
export type Grant = { id: string, points: number }
local ArenaQuests = {}

function ArenaQuests.new(now: number): State
	return {
		day = ArenaSeason.dayOf(now),
		week = ArenaSeason.weekOf(now),
		season = ArenaSeason.seasonOf(now),
		counts = {},
		done = {},
	}
end

function ArenaQuests.record(state: State, now: number, info: { won: boolean, stronger: boolean }): { Grant }
	local current = ArenaQuests.new(now)
	local changed = {
		day = state.day ~= current.day,
		week = state.week ~= current.week,
		season = state.season ~= current.season,
	}
	local grants: { Grant } = {}
	for _, quest in Config.Arena.Quests do
		if changed[quest.period] then
			state.counts[quest.id] = 0
			state.done[quest.id] = nil
		end
		if info.won and (not quest.stronger or info.stronger) and not state.done[quest.id] then
			local count = math.min(quest.wins, (state.counts[quest.id] or 0) + 1)
			state.counts[quest.id] = count
			if count >= quest.wins then
				state.done[quest.id] = true
				table.insert(grants, { id = quest.id, points = quest.points })
			end
		end
	end
	state.day, state.week, state.season = current.day, current.week, current.season
	return grants
end

return ArenaQuests
