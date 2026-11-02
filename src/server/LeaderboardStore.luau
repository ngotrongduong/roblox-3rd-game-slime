--!strict
-- The leaderboard's two DataStores behind plain calls: an OrderedDataStore with each player's best score (the number the
-- board is ordered by) and a normal DataStore with the names that go with it. Everything from Roblox is injected, so the
-- Lune tests drive it with tests/lib/FakeDataStore and Studio plays with the memory pair below. Every call is in a pcall and
-- logs a line starting [GooLineage]; a failed call changes nothing and the caller keeps what it had.

-- On Roblox the shared modules sit in ReplicatedStorage; in Lune they are files next door.
local Leaderboard = if script
	then require(game:GetService("ReplicatedStorage").Shared.Leaderboard)
	else (require :: any)("../shared/Leaderboard")
local Config = if script
	then require(game:GetService("ReplicatedStorage").Shared.Config)
	else (require :: any)("../shared/Config")

-- (the same shape as shared/Leaderboard's Entry, repeated because that type cannot be read through the Lune-friendly require)
export type Entry = { userId: number, player: string, slime: string, level: number, at: number }

-- The part of an OrderedDataStore we use. GetSortedAsync gives pages: page:GetCurrentPage() is a list of { key, value }.
export type OrderedLike = {
	UpdateAsync: (self: any, key: string, transform: (any, any) -> ...any) -> ...any,
	GetSortedAsync: (self: any, ascending: boolean, pageSize: number) -> any,
}
export type NamesLike = {
	GetAsync: (self: any, key: string) -> any,
	SetAsync: (self: any, key: string, value: any, userIds: { number }?) -> ...any,
}
export type Deps = {
	scores: OrderedLike,
	names: NamesLike,
	log: ((message: string) -> ())?,
}
export type Store = {
	-- Sends a player's best if it beats what is stored: true when it was written. (false, nil): not better, nothing changed.
	submit: (entry: Entry) -> (boolean, string?),
	-- The best `count` stored lines in board order, or nil and why not.
	top: (count: number) -> ({ Entry }?, string?),
}

local LeaderboardStore = {}

function LeaderboardStore.new(deps: Deps): Store
	local log: (message: string) -> () = deps.log or print
	-- userId -> the names last read, and the level they were written for
	local cache: { [number]: { level: number, player: string, slime: string } } = {}
	local store = {} :: Store

	local function say(message: string)
		log(Config.LogPrefix .. " " .. message)
	end

	function store.submit(entry: Entry): (boolean, string?)
		local key = tostring(entry.userId)
		local improved = false
		-- (the transform may run more than once: it decides afresh each time and never yields)
		local ok, err = pcall(function()
			deps.scores:UpdateAsync(key, function(old: any): ...any
				improved = false
				if type(old) == "number" then
					local oldLevel = Leaderboard.decode(old)
					if oldLevel >= entry.level then
						return nil
					end
				end
				improved = true
				return Leaderboard.encode(entry.level, entry.at)
			end)
		end)
		if not ok then
			say("leaderboard: could not send " .. key .. "'s best: " .. tostring(err))
			return false, tostring(err)
		end
		if not improved then
			return false, nil
		end
		local named, namesErr = pcall(function()
			deps.names:SetAsync(key, { p = entry.player, s = entry.slime, l = entry.level }, { entry.userId })
		end)
		if not named then
			say("leaderboard: could not send " .. key .. "'s names: " .. tostring(namesErr))
			-- (the score is stored; the names are sent again with the next better slime)
		end
		say(string.format("leaderboard: %s's best is level %d (%s)", entry.player, entry.level, entry.slime))
		return true, nil
	end

	function store.top(count: number): ({ Entry }?, string?)
		local ok, page = pcall(function(): any
			return deps.scores:GetSortedAsync(false, count):GetCurrentPage()
		end)
		if not ok then
			say("leaderboard: could not read the top: " .. tostring(page))
			return nil, tostring(page)
		end
		local entries: { Entry } = {}
		for _, item in page :: { any } do
			local userId = tonumber(item.key)
			if userId == nil or type(item.value) ~= "number" then
				continue
			end
			local level, at = Leaderboard.decode(item.value)
			local known = cache[userId]
			-- the names are read again only when the score moved past the names we hold
			if known == nil or known.level ~= level then
				local read, record = pcall(function(): any
					return deps.names:GetAsync(tostring(userId))
				end)
				if not read then
					say("leaderboard: could not read " .. tostring(userId) .. "'s names: " .. tostring(record))
				elseif type(record) == "table" then
					known = {
						level = if type(record.l) == "number" then record.l else -1,
						player = Leaderboard.cleanName(record.p, Config.Leaderboard.FallbackPlayer),
						slime = Leaderboard.cleanName(record.s, Config.Leaderboard.FallbackSlime),
					}
					cache[userId] = known
				end
			end
			table.insert(entries, {
				userId = userId,
				player = if known then known.player else Config.Leaderboard.FallbackPlayer,
				slime = if known then known.slime else Config.Leaderboard.FallbackSlime,
				level = level,
				at = at,
			})
		end
		return entries, nil
	end

	return store
end

-- The pair kept in memory, for Studio and for a live server whose DataStores cannot be opened: the same calls, nothing
-- saved. The board then shows the players of this server only.
function LeaderboardStore.memory(): (OrderedLike, NamesLike)
	local scores: { [string]: number } = {}
	local names: { [string]: any } = {}
	local ordered: OrderedLike = {
		UpdateAsync = function(_self: any, key: string, transform: (any, any) -> ...any): ...any
			local value = transform(scores[key], nil)
			if value ~= nil then
				scores[key] = value
			end
			return value
		end,
		GetSortedAsync = function(_self: any, ascending: boolean, pageSize: number): any
			local items: { { key: string, value: number } } = {}
			for key, value in scores do
				table.insert(items, { key = key, value = value })
			end
			table.sort(items, function(a, b)
				if a.value ~= b.value then
					return if ascending then a.value < b.value else a.value > b.value
				end
				return a.key < b.key
			end)
			for i = #items, pageSize + 1, -1 do
				items[i] = nil
			end
			return {
				GetCurrentPage = function(): any
					return items
				end,
			}
		end,
	}
	local named: NamesLike = {
		GetAsync = function(_self: any, key: string): any
			local value = names[key]
			return if type(value) == "table" then table.clone(value) else value
		end,
		SetAsync = function(_self: any, key: string, value: any, _userIds: { number }?): ...any
			names[key] = if type(value) == "table" then table.clone(value) else value
		end,
	}
	return ordered, named
end

return LeaderboardStore
