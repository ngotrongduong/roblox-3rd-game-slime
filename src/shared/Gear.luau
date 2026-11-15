--!strict
-- Gear and the Smithy's rules (docs/SMITHY.md): what a slime's worn gear adds to its stats in a fight, crafting a piece from
-- drops, and moving pieces between the farm's bag (`farm.gear`) and a slime's three slots (`slime.gear`). Pure: the request
-- checks (who asks, how often, where they stand) are server/VillageRemotes and shared/VillageRequests.
-- Every step is all-or-nothing: a refusal changes nothing, and equipping or unequipping only moves pieces, so the count of
-- each piece in the bag plus on the slimes never changes by it (a craft adds one, a sold slime hands its gear back).
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Farm = typeof(FarmState.newFarm(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])

local Gear = {}

local S = Config.Smithy

-- The definition of a piece of gear ({ name, slot, tier, stats }), nil for an id that is none.
function Gear.get(gearId: any): any
	if type(gearId) ~= "string" then
		return nil
	end
	return (S.Gear :: any)[gearId]
end

-- The flat points the gear a slime wears adds to its stats, by stat (all four keys, zero when nothing adds to it).
function Gear.bonus(slime: Slime): typeof(Stats.starter())
	local out = { attack = 0, defence = 0, speed = 0, hp = 0 }
	local worn: any = slime.gear
	if type(worn) ~= "table" then
		return out
	end
	for _, slot in S.Slots do
		local piece = Gear.get(worn[slot])
		-- (a piece in the wrong slot counts for nothing; repair sends it back to the bag)
		if piece and piece.slot == slot then
			for _, key in Stats.Keys do
				(out :: any)[key] += piece.stats[key] or 0
			end
		end
	end
	return out
end

-- Puts `count` pieces of a gear id into the bag (the one place that adds to it: a craft and the Arena shop both come
-- here). False, and nothing added, for an id that is none or a count below 1.
function Gear.give(farm: Farm, gearId: any, count: number): boolean
	if Gear.get(gearId) == nil or count < 1 then
		return false
	end
	farm.gear[gearId] = (farm.gear[gearId] or 0) + count
	return true
end

-- Can this recipe be made now? True, or false and why: "RECIPE_NOT_FOUND", "INSUFFICIENT_MATERIALS" or "INSUFFICIENT_COINS".
function Gear.canCraft(farm: Farm, recipeId: any): (boolean, string?)
	local recipe = if type(recipeId) == "string" then (S.Recipes :: any)[recipeId] else nil
	if not recipe then
		return false, "RECIPE_NOT_FOUND"
	end
	for item, need in recipe.materials do
		if (farm.materials[item] or 0) < need then
			return false, "INSUFFICIENT_MATERIALS"
		end
	end
	if farm.coins < recipe.coins then
		return false, "INSUFFICIENT_COINS"
	end
	return true, nil
end

-- Makes one piece: validates first, then takes the materials and the coins once and puts the piece in the bag. Returns the
-- piece's id, or nil and why not (as canCraft); a refusal changes nothing.
function Gear.craft(farm: Farm, recipeId: any): (string?, string?)
	local ok, why = Gear.canCraft(farm, recipeId)
	if not ok then
		return nil, why
	end
	local recipe = (S.Recipes :: any)[recipeId]
	for item, need in recipe.materials do
		local left = (farm.materials[item] or 0) - need
		farm.materials[item] = if left > 0 then left else nil
	end
	farm.coins -= recipe.coins
	Gear.give(farm, recipe.gear, 1)
	-- (the quests and goals of Rewards count the pieces made)
	farm.lifetime.gearCrafted += 1
	return recipe.gear, nil
end

-- The trophy of the Dungeon map whose group material is `basic`.
local function trophyOf(basic: string): string
	for _, each in Config.Dungeon.Maps :: { [string]: any } do
		if each.basic == basic then
			return each.trophy
		end
	end
	error("no dungeon map for " .. basic)
end

-- What tempering this plain piece takes from this farm (Config.Smithy.Temper): the trophies of the two maps its family's
-- basics come from ("either": the one the bag has more of) and the catalysts. Nil when the piece cannot be tempered (a
-- tempered one, or Common).
function Gear.temperCost(farm: Farm, plainId: any): { [string]: number }?
	local piece = Gear.get(plainId)
	local rule: any = if piece and not piece.tempered then (S.Temper :: any)[piece.tier] else nil
	if not rule then
		return nil
	end
	local pair: any = (S.Pairs :: any)[string.match(plainId, "^(%a+)%-")]
	local first, second = trophyOf(pair[1]), trophyOf(pair[2])
	local cost: { [string]: number } = table.clone(rule.extra)
	if rule.of == "each" then
		cost[first] = rule.count
		cost[second] = rule.count
	else
		cost[if (farm.materials[second] or 0) > (farm.materials[first] or 0) then second else first] = rule.count
	end
	return cost
end

-- Tempers one plain piece of the bag into its twin (shared in Config.Smithy.Gear as id .. "-t": +1 to its main stat): takes
-- the piece and the cost (temperCost), adds the tempered one, counts as a craft. A piece a slime wears is not in the bag, so
-- it cannot be tempered until it is taken off. Returns the twin's id, or nil and why not: "GEAR_NOT_FOUND", "CANNOT_TEMPER",
-- "NOT_IN_BAG" or "INSUFFICIENT_MATERIALS"; a refusal changes nothing.
function Gear.temper(farm: Farm, plainId: any): (string?, string?)
	if Gear.get(plainId) == nil then
		return nil, "GEAR_NOT_FOUND"
	end
	local cost = Gear.temperCost(farm, plainId)
	if not cost then
		return nil, "CANNOT_TEMPER"
	elseif (farm.gear[plainId] or 0) < 1 then
		return nil, "NOT_IN_BAG"
	end
	for item, need in cost do
		if (farm.materials[item] or 0) < need then
			return nil, "INSUFFICIENT_MATERIALS"
		end
	end
	local materials: any, bag: any = farm.materials, farm.gear
	for item, need in cost do
		local left = (materials[item] or 0) - need
		materials[item] = if left > 0 then left else nil
	end
	local held: number = bag[plainId] or 0
	bag[plainId] = if held > 1 then held - 1 else nil
	Gear.give(farm, plainId .. "-t", 1)
	farm.lifetime.gearCrafted += 1
	return plainId .. "-t", nil
end

-- One piece from the bag onto the slime, in the slot the piece belongs to; what that slot held goes back to the bag.
-- Returns the slot, or nil and why not: "MISSING_SLIME", "GEAR_NOT_FOUND" (no such piece) or "NOT_IN_BAG".
function Gear.equip(farm: Farm, slimeId: any, gearId: any): (string?, string?)
	local slime = if type(slimeId) == "string" then FarmState.findSlime(farm, slimeId) else nil
	if not slime then
		return nil, "MISSING_SLIME"
	end
	local piece = Gear.get(gearId)
	if not piece then
		return nil, "GEAR_NOT_FOUND"
	end
	local held = farm.gear[gearId] or 0
	if held < 1 then
		return nil, "NOT_IN_BAG"
	end
	if type(slime.gear) ~= "table" then
		slime.gear = FarmState.emptyGear()
	end
	local worn: any = slime.gear
	local before = worn[piece.slot]
	local bag: any = farm.gear
	bag[gearId] = if held > 1 then held - 1 else nil
	if before then
		farm.gear[before] = (farm.gear[before] or 0) + 1
	end
	worn[piece.slot] = gearId
	return piece.slot, nil
end

-- The piece in this slot of the slime goes back to the bag. Returns its id, or nil and why not: "MISSING_SLIME",
-- "INVALID_SLOT" or "EMPTY_SLOT".
function Gear.unequip(farm: Farm, slimeId: any, slot: any): (string?, string?)
	local slime = if type(slimeId) == "string" then FarmState.findSlime(farm, slimeId) else nil
	if not slime then
		return nil, "MISSING_SLIME"
	end
	if type(slot) ~= "string" or table.find(S.Slots, slot) == nil then
		return nil, "INVALID_SLOT"
	end
	local worn: any = slime.gear
	local id = if type(worn) == "table" then worn[slot] else nil
	if type(id) ~= "string" then
		return nil, "EMPTY_SLOT"
	end
	worn[slot] = nil
	farm.gear[id] = (farm.gear[id] or 0) + 1
	return id, nil
end

-- Everything the slime wears goes back to the bag (for a slime sold or released; FarmState.removeSlime does it too).
function Gear.returnAll(farm: Farm, slime: Slime)
	FarmState.returnGear(farm, slime)
end

return Gear
