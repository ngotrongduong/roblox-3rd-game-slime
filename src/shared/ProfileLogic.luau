--!strict
-- Player profiles, the pure part: the stored envelope, the session lock, migrations, the last-good
-- copy, the size budget and when to write. The farm rules inject
-- newData(now) and repair(data, now). The DataStore calls live in server/ProfileStore.
-- Every rule here prefers keeping data over writing over it, because lost progress was the owner's
-- sharpest complaint about the web game (docs/reference/05-owner-history-part1.md §3).

local Config = if script then require(script.Parent.Config) else require("./Config")

local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

local Save = Config.Save

local ProfileLogic = {}

-- What one DataStore key holds.
export type Lock = { jobId: string, placeId: number?, at: number }
export type Snapshot = { schemaVersion: number, savedAt: number, data: any }
export type Envelope = {
	schemaVersion: number,
	savedAt: number,
	data: any,
	lock: Lock?,
	lastGood: Snapshot?,
}

-- One step of the data shape: data at version `from` becomes data at version `to`.
export type Migration = { from: number, to: number, migrate: (data: any, now: number) -> any }

-- What the farm rules inject.
export type Hooks = {
	schemaVersion: number,
	migrations: { Migration }?,
	newData: (now: number) -> any,
	repair: (data: any, now: number) -> any,
}

export type LockState = "free" | "mine" | "stale" | "held"

export type LoadResult = {
	ok: boolean,
	-- Why not ok: "newerSchema" (a newer server wrote it) or "corrupt" (nothing restorable).
	reason: string?,
	error: string?,
	data: any,
	isNew: boolean,
	migrated: boolean,
	usedLastGood: boolean,
	fromVersion: number,
}

export type SaveContext = {
	hooks: Hooks,
	jobId: string,
	placeId: number?,
	now: number,
	-- Clear the lock with this write (the player left or the server closes).
	release: boolean?,
	-- The stored data was written by this session (not a corrupt save we fell back from), so it may
	-- become the last-good copy.
	trustPrevious: boolean?,
}

export type SaveInfo = {
	-- Why the write was refused: "lockLost", "newerSchema", "noData" or "tooLarge".
	reason: string?,
	size: number,
	warn: boolean,
	droppedLastGood: boolean,
	repairError: string?,
}

-- What decides the next write of a loaded profile.
export type SaveState = {
	dirty: boolean,
	keyMomentAt: number?,
	lastSaveAt: number,
	lastWriteAt: number,
	lockAt: number,
	failedAt: number?,
}

local function versionOf(envelope: any): number
	local v = if type(envelope) == "table" then envelope.schemaVersion else nil
	if type(v) == "number" then
		return v
	end
	return Save.FirstSchemaVersion
end

-- A plain copy of a value, the way a DataStore round trip would give it back (tables only; no
-- metatables, no cycles).
function ProfileLogic.deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[ProfileLogic.deepCopy(k)] = ProfileLogic.deepCopy(v)
	end
	return copy
end

-- ===== Session lock =====

function ProfileLogic.newLock(jobId: string, placeId: number?, now: number): Lock
	return { jobId = jobId, placeId = placeId, at = now }
end

function ProfileLogic.lockState(envelope: any, myJobId: string, now: number): LockState
	local lock = if type(envelope) == "table" then envelope.lock else nil
	if type(lock) ~= "table" then
		return "free"
	end
	if lock.jobId == myJobId then
		return "mine"
	end
	-- A lock with no readable time cannot be refreshed by anyone: treat it as dead.
	if type(lock.at) ~= "number" or now - lock.at >= Save.LockStaleSeconds then
		return "stale"
	end
	return "held"
end

-- May this server take the profile? Free, already ours, or left behind by a dead server.
function ProfileLogic.canTake(envelope: any, myJobId: string, now: number): (boolean, LockState)
	local state: LockState = ProfileLogic.lockState(envelope, myJobId, now)
	local can: boolean = state ~= "held"
	return can, state
end

local function withLock(prev: { [any]: any }, lock: Lock?): Envelope
	local env = table.clone(prev)
	env.lock = lock
	return (env :: any) :: Envelope
end

-- The UpdateAsync transform of a load: the envelope to write (ours locked), or nil and why not:
-- "held", "newerSchema" (never touch data a newer server wrote) or "corrupt".
function ProfileLogic.takeLock(
	prev: any,
	hooks: Hooks,
	jobId: string,
	placeId: number?,
	now: number
): (Envelope?, string)
	local lock = ProfileLogic.newLock(jobId, placeId, now)
	if prev == nil then
		-- A new player: lock the key now; the data is written by the first save.
		return { schemaVersion = hooks.schemaVersion, savedAt = now, data = nil, lock = lock }, "free"
	end
	if type(prev) ~= "table" then
		return nil, "corrupt"
	end
	if versionOf(prev) > hooks.schemaVersion then
		return nil, "newerSchema"
	end
	local can, state = ProfileLogic.canTake(prev, jobId, now)
	if not can then
		return nil, "held"
	end
	return withLock(prev, lock), state
end

-- The transform of a lock-only write (refresh while idle, or release with nothing new to save):
-- the stored data is kept exactly as it is.
function ProfileLogic.touchLock(prev: any, ctx: SaveContext): (Envelope?, string?)
	if type(prev) ~= "table" or ProfileLogic.lockState(prev, ctx.jobId, ctx.now) ~= "mine" then
		return nil, "lockLost"
	end
	local lock = if ctx.release then nil else ProfileLogic.newLock(ctx.jobId, ctx.placeId, ctx.now)
	return withLock(prev, lock), nil
end

-- ===== Migrations =====

-- Preserve the old displayed colour for embryos, which had no stored visibleColour.
local function legacyColour(raw: any): string
	if Colours.isValid(raw.visibleColour) then
		return raw.visibleColour
	end
	local genes = raw.colourGenotype
	if type(genes) == "table" and type(genes.alleles) == "table" then
		-- The legacy dominance order was exactly Colours.Ids, highest first.
		for _, id in Colours.Ids do
			if genes.alleles[1] == id or genes.alleles[2] == id then
				return id
			end
		end
	end
	return if type(raw.assetId) == "string"
		then Colours.fromAssetId(raw.assetId) or Colours.Fallback
		else Colours.Fallback
end

-- Schema 2 -> 3: keep appearances, timers and unrelated progress; retire hidden genes.
function ProfileLogic.migrateInheritance(data: any, _now: number): any
	if type(data) ~= "table" then
		return data
	end
	local out = ProfileLogic.deepCopy(data)
	local function rewrite(raw: any)
		if type(raw) ~= "table" then
			return
		end
		raw.patternGenotype = nil
		local appearance = Mutations.validate(raw.appearanceMutation)
		raw.colourGenotype = Genetics.fromAppearance(appearance, Genetics.homozygous(legacyColour(raw)))
	end
	if type(out.slimes) == "table" then
		for _, slime in out.slimes do
			rewrite(slime)
		end
	end
	if type(out.eggs) == "table" then
		for _, egg in out.eggs do
			if type(egg) == "table" then
				rewrite(egg.embryo)
			end
		end
	end
	return out
end

-- Schema 3 -> 4: preserve the genetics, money, equipment and original egg timers.
-- Assign incumbent eggs to incubators before using unincubated nests for overflow.
function ProfileLogic.migrateVillage(data: any, _now: number): any
	if type(data) ~= "table" then
		return data
	end
	local out = ProfileLogic.deepCopy(data)
	local areas: any = {}
	for _, id in Config.Village.Areas do
		areas[id] = { level = Config.Village.StartLevel }
	end
	out.areas = areas
	local work: any = {}
	for _, id in Config.Work.Areas do
		work[id] = { slots = { { progress = 0 } }, box = {} }
	end
	out.work = work
	out.counter = {}
	out.fridge = {}
	out.cookedAllowed = {}
	out.breeding = { pairs = { {}, {} } }
	local oldFood = if type(out.food) == "table" and type(out.food.basicFood) == "number"
		then math.max(0, math.floor(out.food.basicFood))
		else 0
	out.storehouse = {
		fish = math.min(oldFood, Config.Food.StorehouseBase),
	}
	if type(out.slimes) == "table" then
		for _, slime in out.slimes do
			if type(slime) == "table" then
				local oldNeeds = slime.needs
				local hunger = if type(oldNeeds) == "table" and type(oldNeeds.hunger) == "number"
					then oldNeeds.hunger else Config.Needs.Start
				slime.needs = {
					fullness = math.clamp(hunger, 0, Config.Needs.Max),
					energy = Config.Needs.Start,
					fun = Config.Needs.Start,
				}
				local seed = if type(slime.seed) == "number" then slime.seed
					else Rng.hash(tostring(slime.id))
				slime.trait = Config.Village.Traits[math.floor(seed % #Config.Village.Traits) + 1]
				slime.friends = {}
				slime.buff = nil
				slime.ghostUntil = nil
				slime.fallen = nil
				slime.previousLoadout = nil
			end
		end
	end
	if type(out.eggs) == "table" then
		local incubators = Config.Breeding.BasePlaces
		for i, egg in out.eggs do
			if type(egg) == "table" then
				egg.place = if i <= incubators then "incubator" else "nest"
				egg.slot = if i <= incubators then i else i - incubators
				if egg.place == "nest" then egg.hatchAt = nil end
			end
		end
	end
	out.food = nil
	out.workstations = nil
	out.unlockedStations = nil
	out.upgrades = nil
	out.nest = nil
	return out
end

-- Runs the steps from `fromVersion` to `toVersion`, each found by its `from`, so the list may be in
-- any order. Refuses data from a newer version instead of guessing at it.
function ProfileLogic.migrate(
	data: any,
	fromVersion: number,
	toVersion: number,
	migrations: { Migration }?,
	now: number
): (boolean, any, string?)
	if fromVersion > toVersion then
		return false, nil, "newerSchema"
	end
	local list: { Migration } = migrations or {}
	local version = fromVersion
	local current = data
	while version < toVersion do
		local step: Migration? = nil
		for _, m in list do
			if m.from == version then
				step = m
				break
			end
		end
		if step == nil then
			return false, nil, "no migration from version " .. tostring(version)
		end
		if step.to <= version or step.to > toVersion then
			return false, nil, "migration from version " .. tostring(version) .. " has a bad target"
		end
		local ok, result = pcall(step.migrate, current, now)
		if not ok then
			return false,
				nil,
				"migration " .. tostring(version) .. "->" .. tostring(step.to) .. ": " .. tostring(result)
		end
		if result == nil then
			return false, nil, "migration " .. tostring(version) .. "->" .. tostring(step.to) .. " returned nothing"
		end
		current = result
		version = step.to
	end
	return true, current, nil
end

-- ===== Load =====

-- Migrate then repair one stored copy. Returns ok, the data, whether it migrated, and the error.
local function restore(data: any, version: number, hooks: Hooks, now: number): (boolean, any, boolean, string?)
	local ok, migrated, err = ProfileLogic.migrate(data, version, hooks.schemaVersion, hooks.migrations, now)
	if not ok then
		return false, nil, false, err
	end
	local repairedOk, repaired = pcall(hooks.repair, migrated, now)
	if not repairedOk then
		return false, nil, false, "repair: " .. tostring(repaired)
	end
	if repaired == nil then
		return false, nil, false, "repair returned nothing"
	end
	return true, repaired, version ~= hooks.schemaVersion, nil
end

-- What a load gives the game: new data for a new player, else the stored data migrated and
-- repaired, else the last-good copy. Never new data over a save that exists but cannot be read:
-- that is refused, so the stored save stays for a fix.
function ProfileLogic.prepareLoad(envelope: any, hooks: Hooks, now: number): LoadResult
	local result: LoadResult = {
		ok = false,
		reason = nil,
		error = nil,
		data = nil,
		isNew = false,
		migrated = false,
		usedLastGood = false,
		fromVersion = versionOf(envelope),
	}
	if envelope ~= nil and type(envelope) ~= "table" then
		result.reason = "corrupt"
		result.error = "the stored value is a " .. type(envelope)
		return result
	end
	if result.fromVersion > hooks.schemaVersion then
		result.reason = "newerSchema"
		return result
	end
	local lastGood = if envelope then envelope.lastGood else nil
	if envelope == nil or (envelope.data == nil and lastGood == nil) then
		result.ok = true
		result.isNew = true
		result.data = hooks.newData(now)
		result.fromVersion = hooks.schemaVersion
		return result
	end

	local errors = {}
	if envelope.data ~= nil then
		local ok, data, migrated, err = restore(envelope.data, result.fromVersion, hooks, now)
		if ok then
			result.ok = true
			result.data = data
			result.migrated = migrated
			return result
		end
		table.insert(errors, "data: " .. tostring(err))
	end
	if type(lastGood) == "table" and lastGood.data ~= nil then
		local version = versionOf(lastGood)
		local ok, data, _, err = restore(lastGood.data, version, hooks, now)
		if ok then
			result.ok = true
			result.data = data
			result.migrated = true
			result.usedLastGood = true
			result.fromVersion = version
			return result
		end
		table.insert(errors, "lastGood: " .. tostring(err))
	end
	result.reason = "corrupt"
	result.error = table.concat(errors, "; ")
	return result
end

-- ===== Save =====

-- About how many characters JSONEncode would give: close enough to watch the 4 MB budget, cheap
-- enough to run on every save.
function ProfileLogic.estimateSize(value: any): number
	local kind = type(value)
	if kind == "string" then
		local _, escapes = string.gsub(value, '[%c"\\]', "")
		return #value + 2 + escapes
	elseif kind == "number" then
		if value == math.floor(value) and math.abs(value) < 2 ^ 53 then
			return #string.format("%d", value)
		end
		return #tostring(value)
	elseif kind == "boolean" then
		return if value then 4 else 5
	elseif kind == "table" then
		local count, total = 0, 2
		local isArray = true
		for k, v in value do
			count += 1
			total += ProfileLogic.estimateSize(v)
			if type(k) ~= "number" then
				isArray = false
			end
		end
		if count == 0 then
			return 2
		end
		total += count - 1
		if not (isArray and count == #value) then
			for k in value do
				total += #tostring(k) + 3
			end
		end
		return total
	end
	return 4
end

-- The UpdateAsync transform of a save: the envelope to write, or nil and why not. Only while we
-- hold the lock; never over a newer schema; repair runs first; the previous save becomes the
-- last-good copy at most every LastGoodEverySeconds, while it fits the size budget.
function ProfileLogic.prepareSave(prev: any, data: any, ctx: SaveContext): (Envelope?, SaveInfo)
	local info: SaveInfo = { reason = nil, size = 0, warn = false, droppedLastGood = false, repairError = nil }
	if type(prev) ~= "table" or ProfileLogic.lockState(prev, ctx.jobId, ctx.now) ~= "mine" then
		info.reason = "lockLost"
		return nil, info
	end
	if versionOf(prev) > ctx.hooks.schemaVersion then
		info.reason = "newerSchema"
		return nil, info
	end
	if data == nil then
		info.reason = "noData"
		return nil, info
	end

	-- A repair that throws is a bug in the farm rules: write the data as it is rather than lose the
	-- session's progress, and keep the older last-good copy since this one may be bad.
	local toWrite = data
	local repairedOk, repaired = pcall(ctx.hooks.repair, data, ctx.now)
	if repairedOk and repaired ~= nil then
		toWrite = repaired
	else
		info.repairError = if repairedOk then "repair returned nothing" else tostring(repaired)
	end

	local lastGood: Snapshot? = if type(prev.lastGood) == "table" then prev.lastGood else nil
	local rotate = ctx.trustPrevious == true
		and info.repairError == nil
		and prev.data ~= nil
		and (
			lastGood == nil
			or type(lastGood.savedAt) ~= "number"
			or ctx.now - lastGood.savedAt >= Save.LastGoodEverySeconds
		)
	if rotate then
		local savedAt = if type(prev.savedAt) == "number" then prev.savedAt else ctx.now
		lastGood = { schemaVersion = versionOf(prev), savedAt = savedAt, data = prev.data }
	end

	local env: Envelope = {
		schemaVersion = ctx.hooks.schemaVersion,
		savedAt = ctx.now,
		data = toWrite,
		lock = if ctx.release then nil else ProfileLogic.newLock(ctx.jobId, ctx.placeId, ctx.now),
		lastGood = lastGood,
	}
	-- 200 covers the envelope's own fields and the lock.
	local size = 200 + ProfileLogic.estimateSize(toWrite)
	if lastGood then
		local withCopy = size + ProfileLogic.estimateSize(lastGood)
		if withCopy > Save.LastGoodMaxBytes then
			env.lastGood = nil
			info.droppedLastGood = true
		else
			size = withCopy
		end
	end
	info.size = size
	info.warn = size >= Save.WarnBytes
	if size > Save.MaxBytes then
		info.reason = "tooLarge"
		return nil, info
	end
	return env, info
end

-- ===== When to write =====

-- The time a key moment's write is due: the first moment of a burst sets it, later ones join it.
function ProfileLogic.keyMomentDue(existing: number?, now: number): number
	return existing or now + Save.KeyMomentDelaySeconds
end

-- Why a loaded profile should be written now ("keyMoment", "autosave", "lockRefresh") or nil.
-- One write covers every reason that is due, so a key moment and an autosave become one write.
function ProfileLogic.saveReason(s: SaveState, now: number): string?
	if now - s.lastWriteAt < Save.MinSecondsBetweenWrites then
		return nil
	end
	if s.failedAt and now - s.failedAt < Save.FailedSaveRetrySeconds then
		return nil
	end
	if s.dirty then
		if s.keyMomentAt and now >= s.keyMomentAt then
			return "keyMoment"
		end
		if now - s.lastSaveAt >= Save.AutosaveSeconds then
			return "autosave"
		end
	end
	if now - s.lockAt >= Save.LockRefreshSeconds then
		return "lockRefresh"
	end
	return nil
end

return ProfileLogic
