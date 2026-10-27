--!strict
-- The 20 Dual designs (docs/reference/01-core-farm.md §5.5): a two-colour pattern a baby can
-- show on top of its base colour. 18 distinct exact pairs (blue+white and blue+green have two).

local Colours = if script then require(script.Parent.Colours) else require("./Colours")

local DualDesigns = {}

export type Design = {
	id: string,
	number: string,
	name: string,
	parentPair: { string },
	pattern: string,
	assetId: string,
	enabled: boolean,
	weight: number,
}

-- { number, colour a, colour b, name, pattern } in the original order (the weighted pick walks it).
local PLAN: { { string } } = {
	{ "01", "green", "white", "Mint Chip", "dots" },
	{ "02", "purple", "white", "Lavender Stripe", "stripes" },
	{ "03", "pink", "red", "Sweetheart", "hearts" },
	{ "04", "blue", "white", "Glacier Stripe", "stripes" },
	{ "05", "orange", "yellow", "Ember Chevron", "chevron" },
	{ "06", "purple", "pink", "Royal Dot", "dots" },
	{ "07", "blue", "green", "Seafoam", "patches" },
	{ "08", "orange", "red", "Caramel", "patches" },
	{ "09", "red", "black", "Blazepatch", "patches" },
	{ "10", "gray", "white", "Cloudspot", "patches" },
	{ "11", "green", "blue", "Lagoon", "patches" },
	{ "12", "purple", "navy", "Duskpatch", "patches" },
	{ "13", "green", "yellow", "Citrusleaf", "patches" },
	{ "14", "gray", "black", "Ashpatch", "patches" },
	{ "15", "navy", "blue", "Deepsea", "patches" },
	{ "16", "blue", "purple", "Periwinkle", "patches" },
	{ "17", "orange", "white", "Sunset", "patches" },
	{ "18", "red", "purple", "Berrypatch", "patches" },
	{ "19", "white", "blue", "Frostdot", "dots" },
	{ "20", "green", "navy", "Forestpatch", "patches" },
}

DualDesigns.List = {} :: { Design }

local byId: { [string]: Design } = {}
for _, row in PLAN do
	local design: Design = {
		id = "dual-" .. row[2] .. "-" .. row[3] .. "-" .. row[1],
		number = row[1],
		name = row[4],
		parentPair = { row[2], row[3] },
		pattern = row[5],
		assetId = "slime.dual." .. row[1],
		enabled = true,
		weight = 1,
	}
	table.insert(DualDesigns.List, design)
	byId[design.id] = design
end

function DualDesigns.get(id: string): Design?
	return byId[id]
end

function DualDesigns.weight(design: Design): number
	return design.weight
end

-- Designs made for exactly this pair (either order).
function DualDesigns.exact(a: string, b: string): { Design }
	local key = Colours.pairKey(a, b)
	local out = {}
	for _, d in DualDesigns.List do
		if d.enabled and Colours.pairKey(d.parentPair[1], d.parentPair[2]) == key then
			table.insert(out, d)
		end
	end
	return out
end

-- The designs a pairing can produce: its exact designs; when it has none (37 of 55 cross pairs),
-- every design that shares a parent colour, so any two different colours have a dual chance.
-- Same-colour pairs have none: duals need mixing.
function DualDesigns.pool(a: string, b: string): { Design }
	local exact = DualDesigns.exact(a, b)
	if #exact > 0 or a == b then
		return exact
	end
	local out = {}
	for _, d in DualDesigns.List do
		local p = d.parentPair
		if d.enabled and (p[1] == a or p[2] == a or p[1] == b or p[2] == b) then
			table.insert(out, d)
		end
	end
	return out
end

return DualDesigns
