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

-- Whether a carry prompt shows (not the storehouse's, which only takes things back). The fridge has a prompt only once a real one stands in
-- the kitchen; until then a dish could go nowhere, so the counter offers none, though it still takes ingredients.
function Carry.promptOpen(
	spot: string,
	holding: boolean,
	fits: boolean,
	hasItem: boolean,
	fridgeBuilt: boolean
): boolean
	if spot == "fridge" and not fridgeBuilt then
		return false
	end
	if holding then
		return fits
	end
	if spot == "counter" and not fridgeBuilt then
		return false
	end
	return hasItem and Carry.pickupSources(spot)
end

return Carry
