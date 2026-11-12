--!strict
local Config = if script then require(script.Parent.Config) else require("./Config")

local Classes = {}

-- Only a valid weapon in the hand slot grants a class; no class state needs saving.
function Classes.ofSlime(slime: any): (string?, number?)
	local worn = slime.gear
	local id = if type(worn) == "table" then worn.hand else nil
	local piece = if type(id) == "string" then (Config.Smithy.Gear :: any)[id] else nil
	if not piece or piece.slot ~= "hand" or not piece.family then
		return nil, nil
	end
	return (Config.Classes.Families :: any)[piece.family], (Config.Classes.Tiers :: any)[piece.tier]
end

return Classes
