--!strict
-- Player profiles on a DataStore: one key a player holding ProfileLogic's envelope, guarded by a
-- session lock so two servers never both own a farm (which would duplicate or roll it back).
-- Everything from Roblox is injected (the DataStore, clock, wait, spawn, request budget, job id) so
-- the Lune tests drive it with tests/lib/FakeDataStore and a fake clock; PlayerData passes the real
-- ones. Calls are dot-style: store.load(key), store.save(profile).

-- On Roblox the shared modules sit in ReplicatedStorage; in Lune they are files next door. The
-- type checker only knows the Roblox tree, so the Lune path is hidden from it.
local ProfileLogic = if script
	then require(game:GetService("ReplicatedStorage").Shared.ProfileLogic)
	else (require :: any)("../shared/ProfileLogic")
local Config = if script
	then require(game:GetService("ReplicatedStorage").Shared.Config)
	else (require :: any)("../shared/Config")

local Save = Config.Save

local ProfileStore = {}

-- The part of a DataStore we use. UpdateAsync's transform gets the stored value and returns the
-- new value (and the user ids for data-erasure requests), or nil to cancel the write.
export type DataStoreLike = {
	UpdateAsync: (self: any, key: string, transform: (any, any) -> ...any) -> ...any,
}

export type Profile = {
	key: string,
	userIds: { number }?,
	-- The live data. Read freely; change it only through PlayerData.update (which calls markDirty).
	data: any,
	dirty: boolean,
	changes: number,
	keyMomentAt: number?,
	keyReasons: { string },
	lastSaveAt: number,
	lastWriteAt: number,
	lockAt: number,
	failedAt: number?,
	-- A write is in flight (one at a time a profile).
	busy: boolean,
	-- The player left; the release write is pending or retrying.
	leaving: boolean,
	released: boolean,
	-- Another server took the lock: this copy must never be written again.
	lost: boolean,
	-- The stored data is this session's own, so it may become the last-good copy.
	trustStored: boolean,
	sizeWarned: boolean,
	writes: number,
}

-- The farm rules' hooks: the same shape as ProfileLogic.Hooks, repeated here because the type
-- checker cannot see that module's types through the Lune-friendly require above.
export type Hooks = {
	schemaVersion: number,
	migrations: { { from: number, to: number, migrate: (data: any, now: number) -> any } }?,
	newData: (now: number) -> any,
	repair: (data: any, now: number) -> any,
}

export type Deps = {
	store: DataStoreLike,
	hooks: Hooks,
	jobId: string,
	placeId: number?,
	-- Epoch seconds (os.time on Roblox).
	now: () -> number,
	wait: (seconds: number) -> (),
	-- Runs a function on its own thread (task.spawn on Roblox); inline when missing.
	spawn: ((fn: () -> ()) -> ())?,
	-- What is left of the UpdateAsync request budget; no budget check when missing.
	budget: (() -> number)?,
	log: ((message: string) -> ())?,
	-- Called when another server took a profile's lock (the player should be kicked).
	onLost: ((profile: Profile) -> ())?,
}

export type Store = {
	-- The profile, or nil and why: "locked", "newerSchema", "corrupt", "storeDown", "closing".
	load: (key: string, userIds: { number }?) -> (Profile?, string?),
	save: (profile: Profile, deadline: number?) -> (boolean, string?),
	refreshLock: (profile: Profile) -> (boolean, string?),
	release: (profile: Profile, deadline: number?) -> (boolean, string?),
	markDirty: (profile: Profile) -> (),
	markKeyMoment: (profile: Profile, reason: string) -> (),
	-- Starts every write that is due (key moments, autosaves, lock refreshes, retried releases).
	step: () -> number,
	-- Releases every profile within maxSeconds; true when all were written.
	closeAll: (maxSeconds: number) -> boolean,
	get: (key: string) -> Profile?,
}

type Mode = "save" | "refresh" | "release"

function ProfileStore.new(deps: Deps): Store
	local hooks = deps.hooks
	local spawn = deps.spawn or function(fn: () -> ())
		fn()
	end
	local log: (message: string) -> () = deps.log or print
	local loaded: { [string]: Profile } = {}
	local closing = false

	local function say(message: string)
		log(Config.LogPrefix .. " " .. message)
	end

	local function waitForBudget(deadline: number?)
		local budget = deps.budget
		if budget == nil then
			return
		end
		local waited = 0
		while waited < Save.BudgetMaxWaitSeconds do
			local ok, left = pcall(budget)
			if not ok or type(left) ~= "number" or left >= 1 then
				return
			end
			if deadline and deps.now() + Save.BudgetPollSeconds > deadline then
				return
			end
			deps.wait(Save.BudgetPollSeconds)
			waited += Save.BudgetPollSeconds
		end
	end

	-- One UpdateAsync with retries and exponential backoff. Returns ok and the last error.
	local function update(key: string, transform: (any, any) -> ...any, deadline: number?): (boolean, string?)
		local lastError = "unknown error"
		for attempt = 1, Save.Retries do
			waitForBudget(deadline)
			local ok, err = pcall(function()
				deps.store:UpdateAsync(key, transform)
			end)
			if ok then
				return true, nil
			end
			lastError = tostring(err)
			say(
				string.format("DataStore update of %s failed (try %d of %d): %s", key, attempt, Save.Retries, lastError)
			)
			if attempt < Save.Retries then
				local delay = math.min(Save.RetryBaseSeconds * 2 ^ (attempt - 1), Save.RetryMaxSeconds)
				if deadline and deps.now() + delay > deadline then
					break
				end
				deps.wait(delay)
			end
		end
		return false, lastError
	end

	local function waitIdle(profile: Profile)
		while profile.busy do
			deps.wait(Save.BusyPollSeconds)
		end
	end

	local function markLost(profile: Profile, why: string)
		if profile.lost then
			return
		end
		profile.lost = true
		if loaded[profile.key] == profile then
			loaded[profile.key] = nil
		end
		say(string.format("%s: lost the session lock (%s); this server stops saving it", profile.key, why))
		local onLost = deps.onLost
		if onLost then
			spawn(function()
				onLost(profile)
			end)
		end
	end

	local function write(profile: Profile, mode: Mode, deadline: number?): (boolean, string?)
		waitIdle(profile)
		if profile.lost then
			return false, "lockLost"
		end
		if profile.released then
			return false, "released"
		end
		profile.busy = true
		local withData = mode == "save" or (mode == "release" and profile.dirty)
		local changesAtStart = profile.changes
		local refusal: string? = nil
		local info: any = nil
		local writeTime = deps.now()
		-- The transform may run more than once (Roblox retries it on conflicts): it resets what it
		-- reports each time and never yields.
		local ok, err = update(profile.key, function(prev: any): ...any
			local now = deps.now()
			writeTime = now
			local ctx = {
				hooks = hooks,
				jobId = deps.jobId,
				placeId = deps.placeId,
				now = now,
				release = mode == "release",
				trustPrevious = profile.trustStored,
			}
			local env: any
			if withData then
				local saveInfo
				env, saveInfo = ProfileLogic.prepareSave(prev, profile.data, ctx)
				info = saveInfo
				refusal = saveInfo.reason
			else
				local why
				env, why = ProfileLogic.touchLock(prev, ctx)
				info = nil
				refusal = why
			end
			if env == nil then
				return nil
			end
			return env, profile.userIds
		end, deadline)
		profile.busy = false

		if not ok then
			profile.failedAt = deps.now()
			if mode == "save" then
				-- Due again as soon as the retry wait is over, not at the next autosave.
				profile.keyMomentAt = profile.keyMomentAt or profile.failedAt
			end
			say(
				string.format(
					"%s: %s write failed, kept in memory and retried later (%s)",
					profile.key,
					mode,
					tostring(err)
				)
			)
			return false, "storeDown"
		end
		if refusal then
			if refusal == "lockLost" or refusal == "newerSchema" then
				markLost(profile, refusal)
			else
				profile.failedAt = deps.now()
				say(
					string.format(
						"%s: %s write refused (%s); the previous save is untouched",
						profile.key,
						mode,
						refusal
					)
				)
			end
			return false, refusal
		end

		profile.writes += 1
		profile.lastWriteAt = writeTime
		profile.lockAt = writeTime
		profile.failedAt = nil
		if withData then
			profile.lastSaveAt = writeTime
			table.clear(profile.keyReasons)
			-- Changes made while the write was in flight still need a write, soon if a key moment
			-- came with them.
			profile.dirty = profile.changes ~= changesAtStart
			local momentInFlight = profile.dirty and profile.keyMomentAt ~= nil
			profile.keyMomentAt = if momentInFlight then ProfileLogic.keyMomentDue(nil, writeTime) else nil
			if info then
				profile.trustStored = info.repairError == nil
				if info.repairError then
					say(string.format("%s: repair failed while saving, saved as is: %s", profile.key, info.repairError))
				end
				if info.droppedLastGood then
					say(string.format("%s: no room for the last-good copy (%d chars)", profile.key, info.size))
				end
				if info.warn and not profile.sizeWarned then
					profile.sizeWarned = true
					say(
						string.format(
							"%s: save is large: %d of %d chars (warning at %d)",
							profile.key,
							info.size,
							Save.MaxBytes,
							Save.WarnBytes
						)
					)
				end
			end
		end
		if mode == "release" then
			profile.released = true
			profile.leaving = false
			if loaded[profile.key] == profile then
				loaded[profile.key] = nil
			end
		end
		return true, nil
	end

	-- Hands the lock back without touching the data (a load we could not finish).
	local function giveBack(key: string, userIds: { number }?)
		update(key, function(prev: any): ...any
			local env = ProfileLogic.touchLock(prev, {
				hooks = hooks,
				jobId = deps.jobId,
				placeId = deps.placeId,
				now = deps.now(),
				release = true,
			})
			if env == nil then
				return nil
			end
			return env, userIds
		end)
	end

	local store = {} :: Store

	function store.load(key: string, userIds: { number }?): (Profile?, string?)
		if closing then
			return nil, "closing"
		end
		local existing = loaded[key]
		if existing then
			-- The player came back to this server before their leaving write finished: the copy in
			-- memory is the newest, so keep using it.
			waitIdle(existing)
			if not existing.released and not existing.lost then
				existing.leaving = false
				return existing, nil
			end
		end

		for attempt = 1, Save.LoadLockRetries + 1 do
			local stored: any = nil
			local refusal: string? = nil
			local ok = update(key, function(prev: any): ...any
				stored = prev
				local env, why = ProfileLogic.takeLock(prev, hooks, deps.jobId, deps.placeId, deps.now())
				if env == nil then
					refusal = why
					return nil
				end
				refusal = nil
				return env, userIds
			end)
			if not ok then
				-- Never fall back to fresh data when the store cannot be read: that would overwrite.
				return nil, "storeDown"
			end
			if refusal == nil then
				local now = deps.now()
				local result = ProfileLogic.prepareLoad(stored, hooks, now)
				if not result.ok then
					say(string.format("%s: not loaded (%s) %s", key, tostring(result.reason), result.error or ""))
					giveBack(key, userIds)
					return nil, result.reason
				end
				if result.usedLastGood then
					say(string.format("%s: the latest save could not be read, loaded the last-good copy", key))
				end
				local dirty = result.isNew or result.migrated or result.usedLastGood
				local profile: Profile = {
					key = key,
					userIds = userIds,
					data = result.data,
					dirty = dirty,
					changes = 0,
					-- New, migrated or recovered data is written soon, like a key moment.
					keyMomentAt = if dirty then ProfileLogic.keyMomentDue(nil, now) else nil,
					keyReasons = if dirty then { "load" } else {},
					lastSaveAt = now,
					lastWriteAt = now,
					lockAt = now,
					failedAt = nil,
					busy = false,
					leaving = false,
					released = false,
					lost = false,
					trustStored = not result.usedLastGood,
					sizeWarned = false,
					writes = 0,
				}
				loaded[key] = profile
				if closing then
					-- The server began closing while this load waited: hand it straight back.
					store.release(profile)
					return nil, "closing"
				end
				return profile, nil
			elseif refusal ~= "held" then
				say(string.format("%s: not loaded (%s); the stored save is untouched", key, tostring(refusal)))
				return nil, refusal
			end
			if attempt <= Save.LoadLockRetries then
				say(string.format("%s: another server still holds this profile, waiting (%d)", key, attempt))
				deps.wait(Save.LoadLockWaitSeconds)
			end
		end
		return nil, "locked"
	end

	function store.save(profile: Profile, deadline: number?): (boolean, string?)
		return write(profile, "save", deadline)
	end

	function store.refreshLock(profile: Profile): (boolean, string?)
		return write(profile, "refresh", nil)
	end

	function store.release(profile: Profile, deadline: number?): (boolean, string?)
		if profile.released or profile.lost then
			return profile.released, if profile.lost then "lockLost" else nil
		end
		profile.leaving = true
		return write(profile, "release", deadline)
	end

	function store.markDirty(profile: Profile)
		profile.changes += 1
		profile.dirty = true
	end

	function store.markKeyMoment(profile: Profile, reason: string)
		if profile.lost or profile.released then
			return
		end
		profile.dirty = true
		profile.keyMomentAt = ProfileLogic.keyMomentDue(profile.keyMomentAt, deps.now())
		if not table.find(profile.keyReasons, reason) then
			table.insert(profile.keyReasons, reason)
		end
	end

	function store.step(): number
		local now = deps.now()
		local started = 0
		for _, profile in loaded do
			if profile.busy or profile.lost or profile.released then
				continue
			end
			if profile.leaving then
				if profile.failedAt == nil or now - profile.failedAt >= Save.FailedSaveRetrySeconds then
					started += 1
					spawn(function()
						store.release(profile)
					end)
				end
				continue
			end
			local why = ProfileLogic.saveReason(profile, now)
			if why == "keyMoment" or why == "autosave" then
				started += 1
				spawn(function()
					store.save(profile)
				end)
			elseif why == "lockRefresh" then
				started += 1
				spawn(function()
					store.refreshLock(profile)
				end)
			end
		end
		return started
	end

	function store.closeAll(maxSeconds: number): boolean
		closing = true
		local deadline = deps.now() + maxSeconds
		local list = {}
		for _, profile in loaded do
			table.insert(list, profile)
		end
		for _, profile in list do
			spawn(function()
				store.release(profile, deadline)
			end)
		end
		local waited = 0
		while next(loaded) ~= nil and waited < maxSeconds do
			deps.wait(Save.BusyPollSeconds)
			waited += Save.BusyPollSeconds
		end
		local left = 0
		for key in loaded do
			left += 1
			say(string.format("%s: not saved before shutdown", key))
		end
		return left == 0
	end

	function store.get(key: string): Profile?
		return loaded[key]
	end

	return store
end

-- A DataStore kept in memory, for Studio without API access. Values are copied in and out as a
-- real store's JSON round trip would, so code behaves the same on both.
function ProfileStore.memoryStore(): DataStoreLike
	local values: { [string]: any } = {}
	return {
		UpdateAsync = function(_self: any, key: string, transform: (any, any) -> ...any): any
			local current = ProfileLogic.deepCopy(values[key])
			local nextValue = transform(current, nil)
			if nextValue == nil then
				return current
			end
			values[key] = ProfileLogic.deepCopy(nextValue)
			return ProfileLogic.deepCopy(nextValue)
		end,
	}
end

return ProfileStore
