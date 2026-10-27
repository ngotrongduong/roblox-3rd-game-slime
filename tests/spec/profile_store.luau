local Config = require("../../src/shared/Config")
local ProfileStore = require("../../src/server/ProfileStore")
local Fake = require("../lib/FakeDataStore")

local Save = Config.Save
local KEY = "Player_1"

local function newClock()
	local clock = { t = 1_000_000 }
	function clock.now()
		return clock.t
	end
	function clock.wait(seconds: number)
		clock.t += seconds
	end
	return clock
end

local function hooks(overrides: { [string]: any }?)
	local h = {
		schemaVersion = 1,
		migrations = {},
		newData = function()
			return { coins = 10 }
		end,
		repair = function(data)
			if type(data.coins) == "number" and data.coins < 0 then
				data.coins = 0
			end
			return data
		end,
	}
	for k, v in overrides or {} do
		h[k] = v
	end
	return h
end

-- One game server: its own fake DataStore view on a shared backing, its own job id and logs.
local function newServer(backing, jobId: string, clock, options: { [string]: any }?)
	local opts = options or {}
	local fake = Fake.new(backing)
	local server = { fake = fake, logs = {}, lost = {} }
	server.store = ProfileStore.new({
		store = fake,
		hooks = opts.hooks or hooks(),
		jobId = jobId,
		placeId = 1,
		now = clock.now,
		wait = clock.wait,
		budget = opts.budget,
		log = function(message)
			table.insert(server.logs, message)
		end,
		onLost = function(profile)
			table.insert(server.lost, profile)
		end,
	})
	return server
end

local function setup(options: { [string]: any }?)
	local clock = newClock()
	local backing = Fake.newBacking()
	local a = newServer(backing, "A", clock, options)
	local b = newServer(backing, "B", clock, options)
	return clock, a, b
end

local function setCoins(store, profile, coins: number)
	profile.data.coins = coins
	store.markDirty(profile)
end

return function(T)
	T.test("a new player gets newData, written soon after load", function()
		local clock, a = setup()
		local p = a.store.load(KEY, { 1 })
		T.ok(p)
		T.same(p.data, { coins = 10 })
		T.eq(p.dirty, true)
		T.eq(a.store.step(), 0, "not before the spacing between writes")
		clock.t += Save.MinSecondsBetweenWrites
		T.eq(a.store.step(), 1)
		T.same(a.fake.peek(KEY).data, { coins = 10 })
		T.eq(a.fake.peek(KEY).lock.jobId, "A")
		T.eq(p.dirty, false)
	end)

	T.test("data round-trips through save, release and a load on another server", function()
		local _, a, b = setup()
		local p = a.store.load(KEY)
		setCoins(a.store, p, 55)
		T.eq(a.store.save(p), true)
		T.eq(a.store.release(p), true)
		local q = b.store.load(KEY)
		T.ok(q)
		T.same(q.data, { coins = 55 })
		T.eq(q.dirty, false)
	end)

	T.test("repair runs on load", function()
		local _, a = setup()
		a.fake.put(KEY, { schemaVersion = 1, savedAt = 0, data = { coins = -5 } })
		local p = a.store.load(KEY)
		T.ok(p)
		T.eq(p.data.coins, 0)
	end)

	T.test("a second server cannot load while the lock is fresh, and gives up with 'locked'", function()
		local clock, a, b = setup()
		T.ok(a.store.load(KEY))
		local start = clock.t
		local q, why = b.store.load(KEY)
		T.eq(q, nil)
		T.eq(why, "locked")
		T.eq(clock.t - start, Save.LoadLockRetries * Save.LoadLockWaitSeconds, "it waited and retried")
		T.eq(a.fake.peek(KEY).lock.jobId, "A")
	end)

	T.test("a stale lock is taken over, and the old server can no longer save", function()
		local clock, a, b = setup()
		local p = a.store.load(KEY)
		a.store.save(p)
		clock.t += Save.LockStaleSeconds
		local q = b.store.load(KEY)
		T.ok(q, "the stale lock was taken")
		T.same(q.data, { coins = 10 })
		setCoins(a.store, p, 999)
		local ok, why = a.store.save(p)
		T.eq(ok, false)
		T.eq(why, "lockLost")
		T.eq(p.lost, true)
		T.eq(#a.lost, 1)
		T.eq(a.fake.peek(KEY).data.coins, 10)
		T.eq(a.fake.peek(KEY).lock.jobId, "B")
	end)

	T.test("a save without the lock is refused", function()
		local _, a = setup()
		local p = a.store.load(KEY)
		a.store.release(p)
		local ok, why = a.store.save(p)
		T.eq(ok, false)
		T.eq(why, "released")
		-- Someone else's fresh lock written over ours (should never happen) still stops the save.
		local q = a.store.load(KEY)
		local env = a.fake.peek(KEY)
		env.lock = { jobId = "Z", at = env.lock.at }
		a.fake.put(KEY, env)
		ok, why = a.store.save(q)
		T.eq(ok, false)
		T.eq(why, "lockLost")
	end)

	T.test("a short outage is ridden out with backoff inside one save", function()
		local clock, a = setup()
		local p = a.store.load(KEY)
		setCoins(a.store, p, 3)
		a.fake.failNext(2)
		local start = clock.t
		T.eq(a.store.save(p), true)
		T.eq(clock.t - start, Save.RetryBaseSeconds * 3)
		T.eq(a.fake.peek(KEY).data.coins, 3)
	end)

	T.test("a failed save keeps the data dirty and is retried", function()
		local clock, a = setup()
		local p = a.store.load(KEY)
		a.store.save(p)
		clock.t += Save.MinSecondsBetweenWrites
		setCoins(a.store, p, 42)
		a.fake.failNext(Save.Retries)
		local ok = a.store.save(p)
		T.eq(ok, false)
		T.eq(p.dirty, true)
		T.eq(a.fake.peek(KEY).data.coins, 10)
		T.eq(a.store.step(), 0, "waits before retrying")
		clock.t += Save.FailedSaveRetrySeconds
		T.eq(a.store.step(), 1)
		T.eq(a.fake.peek(KEY).data.coins, 42)
		T.eq(p.dirty, false)
	end)

	T.test("data from a newer schema is never overwritten", function()
		local _, a = setup()
		local future = { schemaVersion = 99, savedAt = 5, data = { future = true } }
		a.fake.put(KEY, future)
		local p, why = a.store.load(KEY)
		T.eq(p, nil)
		T.eq(why, "newerSchema")
		T.same(a.fake.peek(KEY), future)
		T.eq(a.fake.writes, 0)
	end)

	T.test("migrations run in order on load and the new version is saved", function()
		local function step(name)
			return function(d)
				table.insert(d.steps, name)
				return d
			end
		end
		local clock, a = setup({
			hooks = hooks({
				schemaVersion = 3,
				migrations = {
					{ from = 2, to = 3, migrate = step("2>3") },
					{ from = 1, to = 2, migrate = step("1>2") },
				},
			}),
		})
		a.fake.put(KEY, { schemaVersion = 1, savedAt = 0, data = { steps = {} } })
		local p = a.store.load(KEY)
		T.ok(p)
		T.same(p.data.steps, { "1>2", "2>3" })
		clock.t += Save.MinSecondsBetweenWrites
		T.eq(a.store.step(), 1)
		T.eq(a.fake.peek(KEY).schemaVersion, 3)
	end)

	T.test("release clears the lock, so the next server loads at once", function()
		local clock, a, b = setup()
		local p = a.store.load(KEY)
		T.eq(a.store.release(p), true)
		T.eq(a.fake.peek(KEY).lock, nil)
		local start = clock.t
		T.ok(b.store.load(KEY))
		T.eq(clock.t, start)
	end)

	T.test("a key moment and an autosave coalesce into one write", function()
		local clock, a = setup()
		local p = a.store.load(KEY)
		a.store.save(p)
		clock.t = p.lastSaveAt + Save.AutosaveSeconds - 2
		setCoins(a.store, p, 1)
		a.store.markKeyMoment(p, "hatch")
		setCoins(a.store, p, 2)
		a.store.markKeyMoment(p, "sell")
		clock.t += Save.KeyMomentDelaySeconds + 1
		local before = a.fake.writes
		T.eq(a.store.step(), 1)
		T.eq(a.fake.writes, before + 1)
		clock.t += 1
		T.eq(a.store.step(), 0)
		T.eq(a.fake.writes, before + 1)
		T.eq(a.fake.peek(KEY).data.coins, 2)
	end)

	T.test("nothing is written while idle except a lock refresh", function()
		local clock, a = setup()
		local p = a.store.load(KEY)
		a.store.save(p)
		local saved = a.fake.peek(KEY)
		clock.t += Save.LockRefreshSeconds - 1
		T.eq(a.store.step(), 0)
		clock.t += 1
		T.eq(a.store.step(), 1)
		local now = a.fake.peek(KEY)
		T.eq(now.lock.at, clock.t)
		T.same(now.data, saved.data)
		T.eq(now.savedAt, saved.savedAt, "the data was not rewritten")
	end)

	T.test("the size warning fires once", function()
		local _, a = setup({
			hooks = hooks({
				newData = function()
					return { blob = string.rep("x", Save.WarnBytes) }
				end,
			}),
		})
		local p = a.store.load(KEY)
		a.store.save(p)
		a.store.markDirty(p)
		a.store.save(p)
		local warnings = 0
		for _, line in a.logs do
			if string.find(line, "save is large", 1, true) then
				warnings += 1
			end
		end
		T.eq(warnings, 1)
	end)

	T.test("closeAll releases every profile, and later loads are refused", function()
		local _, a = setup()
		local p1 = a.store.load("Player_1")
		local p2 = a.store.load("Player_2")
		setCoins(a.store, p1, 7)
		T.eq(a.store.closeAll(Save.ShutdownSeconds), true)
		T.eq(p1.released and p2.released, true)
		T.eq(a.fake.peek("Player_1").lock, nil)
		T.eq(a.fake.peek("Player_1").data.coins, 7)
		T.eq(a.fake.peek("Player_2").lock, nil)
		local _, why = a.store.load("Player_3")
		T.eq(why, "closing")
	end)

	T.test("a load while the store is down gives nothing and writes nothing", function()
		local _, a = setup()
		a.fake.failNext(Save.Retries)
		local p, why = a.store.load(KEY)
		T.eq(p, nil)
		T.eq(why, "storeDown")
		T.eq(a.fake.peek(KEY), nil)
	end)

	T.test("a failed release is retried, and a rejoin before then keeps the copy in memory", function()
		local clock, a = setup()
		local p = a.store.load(KEY)
		setCoins(a.store, p, 31)
		a.fake.failNext(Save.Retries)
		T.eq(a.store.release(p), false)
		T.eq(p.leaving, true)
		local again = a.store.load(KEY)
		T.eq(again, p, "the same profile")
		T.eq(again.data.coins, 31)
		T.eq(again.leaving, false)

		a.fake.failNext(Save.Retries)
		a.store.release(p)
		clock.t += Save.FailedSaveRetrySeconds
		T.eq(a.store.step(), 1)
		T.eq(p.released, true)
		T.eq(a.fake.peek(KEY).lock, nil)
		T.eq(a.fake.peek(KEY).data.coins, 31)
	end)

	T.test("an empty request budget is waited for", function()
		local budgetLeft = 0
		local clock, a = setup({
			budget = function()
				budgetLeft += 1
				return if budgetLeft > 2 then 10 else 0
			end,
		})
		local start = clock.t
		T.ok(a.store.load(KEY))
		T.eq(clock.t - start, Save.BudgetPollSeconds * 2)
	end)

	T.test("every log line starts with [GooLineage]", function()
		local clock, a, b = setup()
		a.store.load(KEY)
		b.store.load(KEY)
		clock.t += 1
		T.ok(#b.logs > 0)
		for _, line in b.logs do
			T.eq(string.sub(line, 1, 12), "[GooLineage]")
		end
	end)
end
