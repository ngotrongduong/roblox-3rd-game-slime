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

-- The hand gear of a class at a tier (one weapon each, Config.Smithy.Gear), nil for a Brawler: what an Arena team shows
-- in hand from the class and tier its snapshot keeps.
function Classes.handOf(class: string?, tier: number?): string?
	if not class or not tier then
		return nil
	end
	for id, piece in Config.Smithy.Gear :: any do
		if
			piece.slot == "hand"
			and piece.family
			and (Config.Classes.Families :: any)[piece.family] == class
			and (Config.Classes.Tiers :: any)[piece.tier] == tier
		then
			return id
		end
	end
	return nil
end

return Classes
