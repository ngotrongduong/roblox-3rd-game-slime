-- Effects quality, Low / Medium / High, for the session (Egg Heist's FxQuality, its numbers). A game with a setting of
-- its own plugs it in with `Quality.plug(get, onChange)`; otherwise the client picks the default from the device.
--   rate      continuous particles a second
--   count     particles of a burst (never fewer than one when the effect asks for any)
--   distance  how far the levels of detail reach
--   lights    the share of the lights that may shine (0: none)
--   full      the share of the hosts that get every layer
--   secondary whether the pieces marked `secondary` are made at all
local Quality = {}

Quality.Tiers = {
	-- cheap phones: far fewer continuous particles, readable bursts, no lights, no secondary layers
	Low = { rate = 0.35, count = 0.5, distance = 0.6, lights = 0, full = 0.5, secondary = false },
	-- touch devices on Automatic: the same shape, less overdraw, half the lights
	Medium = { rate = 0.6, count = 0.75, distance = 0.8, lights = 0.5, full = 0.75, secondary = true },
	-- the authored look and every budget exactly
	High = { rate = 1, count = 1, distance = 1, lights = 1, full = 1, secondary = true },
}

local tier = "High"
local listeners = {}
local plugged = nil

function Quality.get()
	if plugged then
		local value = plugged()
		if Quality.Tiers[value] then
			return value
		end
	end
	return tier
end

function Quality.set(value)
	if Quality.Tiers[value] == nil or value == tier then
		return
	end
	tier = value
	for _, callback in listeners do
		callback(tier)
	end
end

function Quality.onChange(callback)
	table.insert(listeners, callback)
end

-- A game's own setting: `get()` answers "Low" | "Medium" | "High"; `subscribe(callback)` (optional) calls back on a
-- change.
function Quality.plug(get, subscribe)
	plugged = get
	if subscribe then
		subscribe(function()
			for _, callback in listeners do
				callback(Quality.get())
			end
		end)
	end
end

local function now()
	return Quality.Tiers[Quality.get()]
end

function Quality.rate(n)
	return n * now().rate
end

function Quality.count(n)
	local rounded = math.floor(n * now().count + 0.5)
	return if n >= 1 then math.max(1, rounded) else rounded
end

function Quality.distance(d)
	return d * now().distance
end

function Quality.lights(n)
	return math.floor(n * now().lights)
end

function Quality.full(n)
	return math.floor(n * now().full)
end

function Quality.secondary()
	return now().secondary
end

-- The tier a device starts on: the engine's graphics level when it is set (1-3 Low, 4-6 Medium, 7-10 High), else a
-- phone (touch, no keyboard) is Medium and anything else High.
function Quality.default(info)
	local level = info.quality or 0
	if level >= 1 and level <= 3 then
		return "Low"
	elseif level >= 4 and level <= 6 then
		return "Medium"
	elseif level >= 7 and level <= 10 then
		return "High"
	end
	return if info.touch and not info.keyboard then "Medium" else "High"
end

return Quality
