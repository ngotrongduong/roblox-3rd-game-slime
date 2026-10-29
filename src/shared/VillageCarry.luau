--!strict
-- Pure item routing rules shared by player carrying and its validation tests.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Carry = {}

function Carry.allowed(item: string, source: string, destination: string): boolean
	if item == "Egg" then
		return string.match(source, "^nest:%d+$") ~= nil and string.match(destination, "^incubator:%d+$") ~= nil
	end
	if (Config.Food.Raw :: any)[item] ~= nil then
		return (source == "box:fishing" or source == "box:garden" or source == "storehouse")
			and (destination == "storehouse" or destination == "counter")
			and source ~= destination
	end
	if (Config.Food.Dishes :: any)[item] ~= nil then
		return source == "counter" and destination == "fridge"
	end
	return false
end

function Carry.pickupSources(spot: string): boolean
	return spot == "box:fishing"
		or spot == "box:garden"
		or spot == "storehouse"
		or spot == "counter"
		or string.match(spot, "^nest:%d+$") ~= nil
end

return Carry
