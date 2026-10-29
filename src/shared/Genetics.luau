--!strict
-- Genes describe the visible design's base colours, never hidden alleles (docs/GAMEPLAY.md §1).

local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local DualDesigns = if script then require(script.Parent.DualDesigns) else require("./DualDesigns")
local SecretRecipes = if script then require(script.Parent.SecretRecipes) else require("./SecretRecipes")

local Genetics = {}

export type ColourGenotype = { alleles: { string } }
export type Appearance = { type: string, definitionId: string? }
export type Parent = { colourGenotype: ColourGenotype, appearanceMutation: Appearance }
type Design = typeof(DualDesigns.List[1])
type Recipe = typeof(SecretRecipes.List[1])

function Genetics.homozygous(colour: string): ColourGenotype
	return { alleles = { colour, colour } }
end

function Genetics.copy(genotype: ColourGenotype): ColourGenotype
	return { alleles = { genotype.alleles[1], genotype.alleles[2] } }
end

function Genetics.phenotype(genotype: ColourGenotype): string
	return if Colours.isValid(genotype.alleles[1]) then genotype.alleles[1] else Colours.Fallback
end

-- Unknown saved designs retain a usable base colour until their definition returns.
function Genetics.baseColours(parent: Parent): { string }
	local appearance = parent.appearanceMutation
	local id = appearance.definitionId
	local pair: { string }? = nil
	if id and appearance.type == "dual" then
		local design = DualDesigns.get(id)
		pair = if design then design.parentPair else nil
	elseif id and appearance.type == "secret" then
		local recipe = SecretRecipes.get(id)
		pair = if recipe then recipe.parentPair else nil
	end
	if pair then
		return if pair[1] == pair[2] then { pair[1] } else { pair[1], pair[2] }
	end
	return { Genetics.phenotype(parent.colourGenotype) }
end

function Genetics.fromAppearance(appearance: Appearance, genotype: ColourGenotype): ColourGenotype
	local colours = Genetics.baseColours({ appearanceMutation = appearance, colourGenotype = genotype })
	return { alleles = { colours[1], colours[2] or colours[1] } }
end

function Genetics.visibleColour(appearance: Appearance, genotype: ColourGenotype): string
	if appearance.type == "dual" and appearance.definitionId then
		local design = DualDesigns.get(appearance.definitionId)
		if design then
			return design.bodyColour
		end
	end
	return Genetics.baseColours({ appearanceMutation = appearance, colourGenotype = genotype })[1]
end

function Genetics.colourSet(a: Parent, b: Parent): { string }
	local seen: { [string]: boolean } = {}
	for _, parent in { a, b } do
		for _, colour in Genetics.baseColours(parent) do
			seen[colour] = true
		end
	end
	local out = {}
	for _, id in Colours.Ids do
		if seen[id] then
			table.insert(out, id)
		end
	end
	return out
end

function Genetics.dualPool(colours: { string }): { Design }
	local out = {}
	for i, a in colours do
		for j = i + 1, #colours do
			for _, design in DualDesigns.exact(a, colours[j]) do
				table.insert(out, design)
			end
		end
	end
	return out
end

function Genetics.secretPool(colours: { string }): { Recipe }
	local out = {}
	for i, a in colours do
		for j = i, #colours do
			for _, recipe in SecretRecipes.forPair(a, colours[j]) do
				table.insert(out, recipe)
			end
		end
	end
	return out
end

-- Breeding needs exactly two valid colour alleles.
function Genetics.isUsableColour(raw: any): boolean
	return type(raw) == "table"
		and type(raw.alleles) == "table"
		and #raw.alleles == 2
		and Colours.isValid(raw.alleles[1])
		and Colours.isValid(raw.alleles[2])
end

-- Field-level repair of a loaded colour genotype. nil when the shape is unusable (the caller
-- derives one); an unknown allele becomes the fallback colour.
function Genetics.validateColour(raw: any, warnings: { string }, prefix: string): ColourGenotype?
	if type(raw) ~= "table" then
		return nil
	end
	local alleles = raw.alleles
	if type(alleles) ~= "table" or #alleles ~= 2 then
		table.insert(warnings, prefix .. ": colour alleles missing, replaced")
		return nil
	end
	local out = {}
	local repaired = false
	for i = 1, 2 do
		if Colours.isValid(alleles[i]) then
			out[i] = alleles[i]
		else
			out[i] = Colours.Fallback
			repaired = true
		end
	end
	if repaired then
		table.insert(warnings, prefix .. ": invalid colour allele, set to " .. Colours.Fallback)
	end
	return { alleles = out }
end

return Genetics
