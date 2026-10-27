local serde = require("@lune/serde")

local Config = require("../../src/shared/Config")
local ProfileLogic = require("../../src/shared/ProfileLogic")

local Save = Config.Save

local function hooks(overrides: { [string]: any }?)
	local h = {
		schemaVersion = 1,
		migrations = {},
		newData = function(now)
			return { coins = 10, createdAt = now }
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

local function ctx(now: number, extra: { [string]: any }?)
	local c = { hooks = hooks(), jobId = "A", placeId = 1, now = now, release = false, trustPrevious = true }
	for k, v in extra or {} do
		c[k] = v
	end
	return c
end

local function lockedBy(jobId: string, at: number, data: any)
	return { schemaVersion = 1, savedAt = at, data = data, lock = { jobId = jobId, at = at } }
end

return function(T)
	T.test("the lock is free, mine, held while fresh, and stale after LockStaleSeconds", function()
		T.eq(select(2, ProfileLogic.canTake(nil, "A", 100)), "free")
		T.eq(select(2, ProfileLogic.canTake({ schemaVersion = 1, savedAt = 0, data = {} }, "A", 100)), "free")
		T.eq(select(2, ProfileLogic.canTake(lockedBy("A", 0, {}), "A", 100)), "mine")
		local can, state = ProfileLogic.canTake(lockedBy("B", 100, {}), "A", 100 + Save.LockStaleSeconds - 1)
		T.eq(can, false)
		T.eq(state, "held")
		can, state = ProfileLogic.canTake(lockedBy("B", 100, {}), "A", 100 + Save.LockStaleSeconds)
		T.eq(can, true)
		T.eq(state, "stale")
	end)

	T.test("takeLock refuses a newer schema and a fresh foreign lock", function()
		local env, why = ProfileLogic.takeLock({ schemaVersion = 5, savedAt = 0, data = {} }, hooks(), "A", 1, 10)
		T.eq(env, nil)
		T.eq(why, "newerSchema")
		env, why = ProfileLogic.takeLock(lockedBy("B", 10, {}), hooks(), "A", 1, 20)
		T.eq(env, nil)
		T.eq(why, "held")
		env, why = ProfileLogic.takeLock(nil, hooks(), "A", 1, 20)
		T.ok(env)
		T.eq(why, "free")
		T.eq((env :: any).lock.jobId, "A")
	end)

	T.test("migrations run in order, whatever order the list is in", function()
		local migrations = {
			{
				from = 2,
				to = 3,
				migrate = function(d)
					table.insert(d.steps, "2>3")
					return d
				end,
			},
			{
				from = 1,
				to = 2,
				migrate = function(d)
					table.insert(d.steps, "1>2")
					return d
				end,
			},
		}
		local ok, data = ProfileLogic.migrate({ steps = {} }, 1, 3, migrations, 0)
		T.eq(ok, true)
		T.same(data.steps, { "1>2", "2>3" })
	end)

	T.test("migrate refuses a newer schema, a missing step and a throwing step", function()
		local ok, _, err = ProfileLogic.migrate({}, 4, 3, {}, 0)
		T.eq(ok, false)
		T.eq(err, "newerSchema")
		ok = ProfileLogic.migrate(
			{},
			1,
			3,
			{ {
				from = 1,
				to = 2,
				migrate = function(d)
					return d
				end,
			} },
			0
		)
		T.eq(ok, false)
		ok = ProfileLogic.migrate(
			{},
			1,
			2,
			{ {
				from = 1,
				to = 2,
				migrate = function()
					error("boom")
				end,
			} },
			0
		)
		T.eq(ok, false)
	end)

	T.test("a new player gets newData", function()
		local result = ProfileLogic.prepareLoad(nil, hooks(), 50)
		T.eq(result.ok, true)
		T.eq(result.isNew, true)
		T.same(result.data, { coins = 10, createdAt = 50 })
		-- A key locked by a first load but never saved is still a new player.
		result = ProfileLogic.prepareLoad(lockedBy("A", 1, nil), hooks(), 50)
		T.eq(result.isNew, true)
	end)

	T.test("load runs repair and migrations", function()
		local h = hooks({
			schemaVersion = 2,
			migrations = {
				{
					from = 1,
					to = 2,
					migrate = function(d)
						d.v2 = true
						return d
					end,
				},
			},
		})
		local result = ProfileLogic.prepareLoad(lockedBy("A", 1, { coins = -4 }), h, 50)
		T.eq(result.ok, true)
		T.eq(result.migrated, true)
		T.same(result.data, { coins = 0, v2 = true })
	end)

	T.test("load refuses a newer schema", function()
		local result = ProfileLogic.prepareLoad({ schemaVersion = 9, savedAt = 0, data = { coins = 1 } }, hooks(), 50)
		T.eq(result.ok, false)
		T.eq(result.reason, "newerSchema")
	end)

	T.test("load falls back to the last-good copy, and refuses when nothing is readable", function()
		local h = hooks({
			repair = function(d)
				assert(d.broken == nil, "broken data")
				return d
			end,
		})
		local env = lockedBy("A", 100, { broken = true })
		env.lastGood = { schemaVersion = 1, savedAt = 50, data = { coins = 7 } }
		local result = ProfileLogic.prepareLoad(env, h, 200)
		T.eq(result.ok, true)
		T.eq(result.usedLastGood, true)
		T.same(result.data, { coins = 7 })

		env.lastGood = nil
		result = ProfileLogic.prepareLoad(env, h, 200)
		T.eq(result.ok, false)
		T.eq(result.reason, "corrupt")
		T.eq(ProfileLogic.prepareLoad("garbage", h, 200).reason, "corrupt")
	end)

	T.test("save is refused without the lock, and refused over a newer schema", function()
		local env, info = ProfileLogic.prepareSave(lockedBy("B", 100, {}), { coins = 1 }, ctx(110))
		T.eq(env, nil)
		T.eq(info.reason, "lockLost")
		env, info = ProfileLogic.prepareSave({ schemaVersion = 1, savedAt = 0, data = {} }, { coins = 1 }, ctx(110))
		T.eq(env, nil)
		T.eq(info.reason, "lockLost")
		local newer = lockedBy("A", 100, {})
		newer.schemaVersion = 7
		env, info = ProfileLogic.prepareSave(newer, { coins = 1 }, ctx(110))
		T.eq(env, nil)
		T.eq(info.reason, "newerSchema")
	end)

	T.test("save refreshes the lock, release clears it, repair runs first", function()
		local env = ProfileLogic.prepareSave(lockedBy("A", 100, {}), { coins = -3 }, ctx(110))
		T.ok(env)
		T.eq((env :: any).lock.at, 110)
		T.eq((env :: any).data.coins, 0)
		env = ProfileLogic.prepareSave(lockedBy("A", 100, {}), { coins = 2 }, ctx(110, { release = true }))
		T.ok(env)
		T.eq((env :: any).lock, nil)
	end)

	T.test("a throwing repair still saves the data but keeps the older last-good copy", function()
		local prev = lockedBy("A", 100, { coins = 5 })
		prev.lastGood = { schemaVersion = 1, savedAt = 0, data = { coins = 1 } }
		local c = ctx(100 + Save.LastGoodEverySeconds * 2)
		c.hooks = hooks({
			repair = function()
				error("bug")
			end,
		})
		local env, info = ProfileLogic.prepareSave(prev, { coins = 9 }, c)
		T.ok(env)
		T.ok(info.repairError)
		T.eq((env :: any).data.coins, 9)
		T.eq((env :: any).lastGood.data.coins, 1)
	end)

	T.test("the previous save becomes the last-good copy at most every LastGoodEverySeconds", function()
		local t = 1000
		local env = ProfileLogic.prepareSave(lockedBy("A", t, { coins = 1 }), { coins = 2 }, ctx(t + 10)) :: any
		T.same(env.lastGood.data, { coins = 1 })
		env = ProfileLogic.prepareSave(env, { coins = 3 }, ctx(t + 20)) :: any
		T.same(env.lastGood.data, { coins = 1 }, "kept within the interval")
		env = ProfileLogic.prepareSave(env, { coins = 4 }, ctx(t + 10 + Save.LastGoodEverySeconds)) :: any
		T.same(env.lastGood.data, { coins = 3 }, "rotated after the interval")
		-- Data we did not write ourselves (a corrupt save we fell back from) never becomes last-good.
		env = ProfileLogic.prepareSave(
			lockedBy("A", t, { broken = true }),
			{ coins = 2 },
			ctx(t + 10, { trustPrevious = false })
		) :: any
		T.eq(env.lastGood, nil)
	end)

	T.test("the size check warns, drops the last-good copy, then refuses", function()
		local big = string.rep("x", Save.WarnBytes)
		local env, info = ProfileLogic.prepareSave(lockedBy("A", 0, nil), { blob = big }, ctx(10))
		T.ok(env)
		T.eq(info.warn, true)

		local half = string.rep("y", math.floor(Save.LastGoodMaxBytes * 0.6))
		env, info = ProfileLogic.prepareSave(lockedBy("A", 0, { blob = half }), { blob = half }, ctx(10))
		T.ok(env)
		T.eq(info.droppedLastGood, true)
		T.eq((env :: any).lastGood, nil)

		env, info = ProfileLogic.prepareSave(lockedBy("A", 0, nil), { blob = string.rep("z", Save.MaxBytes) }, ctx(10))
		T.eq(env, nil)
		T.eq(info.reason, "tooLarge")

		_, info = ProfileLogic.prepareSave(lockedBy("A", 0, nil), { coins = 1 }, ctx(10))
		T.eq(info.warn, false)
		T.ok(Save.WarnBytes <= Save.MaxBytes / 2, "the warning comes well before the limit")
	end)

	T.test("estimateSize is close to the JSON length", function()
		local value = {
			name = 'Goo "the" Slime\n',
			stats = { 1, 2, 3, 40 },
			hp = 12.5,
			alive = true,
			tags = {},
			nested = { a = { b = { c = "d" } } },
		}
		local json = serde.encode("json", value)
		T.near(ProfileLogic.estimateSize(value), #json, 4)
	end)

	T.test("saveReason: key moments after their delay, autosave only when dirty, lock refresh, spacing", function()
		local base = { dirty = false, keyMomentAt = nil, lastSaveAt = 0, lastWriteAt = 0, lockAt = 0, failedAt = nil }
		local function with(changes)
			local s = table.clone(base)
			for k, v in changes do
				s[k] = v
			end
			return s
		end
		T.eq(ProfileLogic.saveReason(with({ dirty = true, keyMomentAt = 20 }), 19), nil)
		T.eq(ProfileLogic.saveReason(with({ dirty = true, keyMomentAt = 20 }), 20), "keyMoment")
		T.eq(ProfileLogic.saveReason(with({ dirty = false }), Save.AutosaveSeconds), "lockRefresh")
		T.eq(ProfileLogic.saveReason(with({ dirty = true }), Save.AutosaveSeconds), "autosave")
		T.eq(
			ProfileLogic.saveReason(with({ dirty = true, lockAt = Save.AutosaveSeconds - 1 }), Save.AutosaveSeconds - 1),
			nil
		)
		local t = Save.AutosaveSeconds * 2
		T.eq(ProfileLogic.saveReason(with({ dirty = true, keyMomentAt = 0, lastWriteAt = t - 1 }), t), nil)
		T.eq(ProfileLogic.saveReason(with({ dirty = true, keyMomentAt = 0, failedAt = t - 1 }), t), nil)
		T.eq(ProfileLogic.keyMomentDue(nil, 10), 10 + Save.KeyMomentDelaySeconds)
		T.eq(ProfileLogic.keyMomentDue(12, 13), 12, "a burst joins the first moment")
	end)
end
