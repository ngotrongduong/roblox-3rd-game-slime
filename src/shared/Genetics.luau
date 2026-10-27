--!strict
-- Two-allele genetics (docs/reference/01-core-farm.md §5.2–5.3).
-- Colour locus: each parent passes one of its two colour alleles; the more dominant one shows,
-- the other is carried silently and can come back in a later generation.
-- Pattern locus: "solid" is dominant, "duochrome" recessive; only duochrome/duochrome can show a
-- Dual design by itself, solid/duochrome is a hidden carrier.

local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

-- Sibling types come through typeof: an exported type cannot be read through the if-require.
type Rng = typeof(Rng.new(0))

local Genetics = {}

export type ColourGenotype = { alleles: { string } }
export type PatternGenotype = { alleles: { string } }

Genetics.Solid = "solid"
Genetics.Duochrome = "duochrome"

function Genetics.homozygous(colour: string): ColourGenotype
	return { alleles = { colour, colour } }
end

function Genetics.copy(genotype: { alleles: { string } }): { alleles: { string } }
	return { alleles = { genotype.alleles[1], genotype.alleles[2] } }
end

-- The colour a genotype shows. Same alleles → that colour; else the higher dominance, then the
-- higher tiePriority. Never fails: one valid allele wins, two invalid ones give the fallback.
function Genetics.phenotype(genotype: ColourGenotype): string
	local a, b = genotype.alleles[1], genotype.alleles[2]
	local ca = if type(a) == "string" then Colours.get(a) else nil
	local cb = if type(b) == "string" then Colours.get(b) else nil
	if ca and cb then
		if ca.dominance ~= cb.dominance then
			return if ca.dominance > cb.dominance then ca.id else cb.id
		end
		return if ca.tiePriority >= cb.tiePriority then ca.id else cb.id
	end
	if ca then
		return ca.id
	end
	if cb then
		return cb.id
	end
	return Colours.Fallback
end

-- One allele from each parent, each 50/50 (two rolls, A's first). Parents are not changed.
local function inherit(a: { alleles: { string } }, b: { alleles: { string } }, rng: Rng): { string }
	local fromA = a.alleles[if rng:next() < 0.5 then 1 else 2]
	local fromB = b.alleles[if rng:next() < 0.5 then 1 else 2]
	return { fromA, fromB }
end

function Genetics.inheritColour(a: ColourGenotype, b: ColourGenotype, rng: Rng): ColourGenotype
	return { alleles = inherit(a, b, rng) }
end

function Genetics.solid(): PatternGenotype
	return { alleles = { Genetics.Solid, Genetics.Solid } }
end

function Genetics.duochrome(): PatternGenotype
	return { alleles = { Genetics.Duochrome, Genetics.Duochrome } }
end

function Genetics.inheritPattern(a: PatternGenotype, b: PatternGenotype, rng: Rng): PatternGenotype
	return { alleles = inherit(a, b, rng) }
end

-- Only duochrome/duochrome can express a Dual design.
function Genetics.isDuochrome(g: PatternGenotype): boolean
	return g.alleles[1] == Genetics.Duochrome and g.alleles[2] == Genetics.Duochrome
end

-- solid/duochrome: looks plain but can pass the duochrome allele on.
function Genetics.isCarrier(g: PatternGenotype): boolean
	return not Genetics.isDuochrome(g) and (g.alleles[1] == Genetics.Duochrome or g.alleles[2] == Genetics.Duochrome)
end

local function isPatternAllele(v: any): boolean
	return v == Genetics.Solid or v == Genetics.Duochrome
end

-- Breeding needs exactly two valid colour alleles.
function Genetics.isUsableColour(raw: any): boolean
	return type(raw) == "table"
		and type(raw.alleles) == "table"
		and #raw.alleles == 2
		and Colours.isValid(raw.alleles[1])
		and Colours.isValid(raw.alleles[2])
end

-- Breeding needs two pattern alleles (as the original: it checks the count, repair checks values).
function Genetics.isUsablePattern(raw: any): boolean
	return type(raw) == "table" and type(raw.alleles) == "table" and #raw.alleles == 2
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

-- Field-level repair of a loaded pattern genotype; anything invalid becomes solid/solid.
function Genetics.validatePattern(raw: any, warnings: { string }, prefix: string): PatternGenotype
	if
		type(raw) == "table"
		and type(raw.alleles) == "table"
		and #raw.alleles == 2
		and isPatternAllele(raw.alleles[1])
		and isPatternAllele(raw.alleles[2])
	then
		return { alleles = { raw.alleles[1], raw.alleles[2] } }
	end
	table.insert(warnings, prefix .. ": invalid pattern genotype, set to solid/solid")
	return Genetics.solid()
end

return Genetics
