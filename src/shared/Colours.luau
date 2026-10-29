--!strict
-- The 11 base colours in stable pool order (docs/GAMEPLAY.md §1).

local Colours = {}

export type Colour = {
	id: string,
	name: string,
	assetId: string,
	swatch: string,
}

local function colour(id: string, name: string, swatch: string): Colour
	return {
		id = id,
		name = name,
		assetId = "slime.base." .. id,
		swatch = swatch,
	}
end

-- Stable order for deterministic inheritance; there is no colour dominance.
Colours.List = {
	colour("black", "Black", "#2b2b33"),
	colour("gray", "Gray", "#9aa0a8"),
	colour("navy", "Navy", "#1b4fd8"),
	colour("purple", "Purple", "#8a4fd0"),
	colour("red", "Red", "#d8402f"),
	colour("orange", "Orange", "#f08a24"),
	colour("yellow", "Yellow", "#f2d13d"),
	colour("green", "Green", "#54b848"),
	colour("pink", "Pink", "#f27fb6"),
	colour("blue", "Blue", "#3f9ff0"),
	colour("white", "White", "#f5f2ea"),
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
