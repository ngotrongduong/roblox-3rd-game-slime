--!strict
-- The 11 base colours (docs/reference/01-core-farm.md §5.1). Higher dominance wins the phenotype;
-- tiePriority breaks ties (all unique, so the result is always deterministic). The list order is
-- the original BASE_COLOUR_IDS order, which the base-colour mutation pick depends on.

local Colours = {}

export type Colour = {
	id: string,
	name: string,
	dominance: number,
	tiePriority: number,
	assetId: string,
	swatch: string,
}

local function colour(id: string, name: string, dominance: number, swatch: string): Colour
	return {
		id = id,
		name = name,
		dominance = dominance,
		tiePriority = dominance,
		assetId = "slime.base." .. id,
		swatch = swatch,
	}
end

-- The original marks this dominance order as temporary; it is data, so it can change here alone.
Colours.List = {
	colour("black", "Black", 11, "#2b2b33"),
	colour("gray", "Gray", 10, "#9aa0a8"),
	colour("navy", "Navy", 9, "#1b4fd8"),
	colour("purple", "Purple", 8, "#8a4fd0"),
	colour("red", "Red", 7, "#d8402f"),
	colour("orange", "Orange", 6, "#f08a24"),
	colour("yellow", "Yellow", 5, "#f2d13d"),
	colour("green", "Green", 4, "#54b848"),
	colour("pink", "Pink", 3, "#f27fb6"),
	colour("blue", "Blue", 2, "#3f9ff0"),
	colour("white", "White", 1, "#f5f2ea"),
}

-- Ids in list order.
Colours.Ids = {} :: { string }

local byId: { [string]: Colour } = {}
for _, c in Colours.List do
	byId[c.id] = c
	table.insert(Colours.Ids, c.id)
end

-- What an unreadable genotype falls back to (the original's choice).
Colours.Fallback = "blue"

function Colours.get(id: string): Colour?
	return byId[id]
end

function Colours.isValid(id: any): boolean
	return type(id) == "string" and byId[id] ~= nil
end

-- Order-independent key of a colour pair ("a|b", alphabetical): duals and secrets match on it.
function Colours.pairKey(a: string, b: string): string
	if a <= b then
		return a .. "|" .. b
	end
	return b .. "|" .. a
end

-- "slime.base.navy" → "navy"; nil when the asset carries no base colour.
function Colours.fromAssetId(assetId: string): string?
	local id = string.match(assetId, "^slime%.base%.([a-z]+)$")
	if id and byId[id] then
		return id
	end
	return nil
end

return Colours
