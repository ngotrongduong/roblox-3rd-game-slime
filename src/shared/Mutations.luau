--!strict
-- Offspring resolution (docs/reference/01-core-farm.md §5.4, §5.7): the baby's colour and
-- pattern genes and its rare appearance (Secret / Dual / none), decided once when the egg is laid.
-- Appearances are a cosmetic layer over the base colour and are never inherited: parents always
-- breed with their base (visible) colour.

local Config = if script then require(script.Parent.Config) else require("./Config")
local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local DualDesigns = if script then require(script.Parent.DualDesigns) else require("./DualDesigns")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Luck = if script then require(script.Parent.Luck) else require("./Luck")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local SecretRecipes = if script then require(script.Parent.SecretRecipes) else require("./SecretRecipes")

-- Sibling types come through typeof: an exported type cannot be read through the if-require.
type Rng = typeof(Rng.new(0))
type ColourGenotype = typeof(Genetics.homozygous(""))
type PatternGenotype = typeof(Genetics.solid())
type Recipe = typeof(SecretRecipes.List[1])
type Design = typeof(DualDesigns.List[1])

local Mutations = {}

-- type is "none", "dual" or "secret"; definitionId is set for dual and secret.
export type Appearance = { type: string, definitionId: string? }

export type Parents = {
	colourA: string,
	colourB: string,
	genotypeA: ColourGenotype,
	genotypeB: ColourGenotype,
	patternA: PatternGenotype,
	patternB: PatternGenotype,
}

export type Outcome = {
	colourGenotype: ColourGenotype,
	patternGenotype: PatternGenotype,
	appearance: Appearance,
	-- "secret", "dual", "base" (colour mutation), "normal" (may still show a carrier Dual) or "pity".
	rolled: string,
	hadSecret: boolean,
	hadDual: boolean,
}

export type Chances = {
	secret: number,
	dual: number,
	base: number,
	secrets: { Recipe },
	duals: { Design },
}

function Mutations.none(): Appearance
	return { type = "none" }
end

function Mutations.copy(appearance: Appearance): Appearance
	return { type = appearance.type, definitionId = appearance.definitionId }
end

-- "secret" > "dual" > "base", for sorting, prices and the reveal.
function Mutations.rarity(appearance: Appearance): string
	if appearance.type == "secret" or appearance.type == "dual" then
		return appearance.type
	end
	return "base"
end

-- The pools and chances of one pairing. Same-colour pairs have no dual pool.
function Mutations.chances(colourA: string, colourB: string, luck: number): Chances
	local m = Config.Mutation
	local secrets = SecretRecipes.forPair(colourA, colourB)
	local duals = if colourA ~= colourB then DualDesigns.pool(colourA, colourB) else {}
	return {
		secret = if #secrets > 0 then Luck.chance(m.SecretChance, luck) else 0,
		dual = if #duals > 0 then Luck.chance(m.DualChance, luck) else 0,
		base = m.BaseChance,
		secrets = secrets,
		duals = duals,
	}
end

-- Which kind of egg this is. KEPT AS IN THE ORIGINAL: three sequential rolls (secret; else dual;
-- else base), so dual and base odds are "of the rest" (e.g. dual 4.95%, not 5%, at luck 1).
-- The original's comment says a single categorical roll was intended; this is the one place to
-- change if that is ever decided. A zero chance (no pool) spends no roll, like the original.
function Mutations.rollCategory(rng: Rng, secretChance: number, dualChance: number, baseChance: number): string
	if secretChance > 0 and rng:next() < secretChance then
		return "secret"
	end
	if dualChance > 0 and rng:next() < dualChance then
		return "dual"
	end
	if rng:next() < baseChance then
		return "base"
	end
	return "normal"
end

-- The whole egg outcome, in the original's order of rolls: colour genes, pattern genes, the
-- category roll, then the pick inside the category.
function Mutations.resolveOffspring(parents: Parents, rng: Rng, luck: number): Outcome
	local c = Mutations.chances(parents.colourA, parents.colourB, luck)
	local hadSecret, hadDual = #c.secrets > 0, #c.duals > 0

	local colourGenotype = Genetics.inheritColour(parents.genotypeA, parents.genotypeB, rng)
	local phenotype = Genetics.phenotype(colourGenotype)
	local patternGenotype = Genetics.inheritPattern(parents.patternA, parents.patternB, rng)

	local category = Mutations.rollCategory(rng, c.secret, c.dual, c.base)
	if category == "secret" then
		local recipe = rng:weighted(c.secrets, SecretRecipes.weight)
		return {
			colourGenotype = colourGenotype,
			patternGenotype = patternGenotype,
			appearance = { type = "secret", definitionId = recipe.id },
			rolled = "secret",
			hadSecret = hadSecret,
			hadDual = hadDual,
		}
	elseif category == "dual" then
		-- A rolled Dual makes the baby a true duochrome, so it can pass the pattern on.
		local design = rng:weighted(c.duals, DualDesigns.weight)
		return {
			colourGenotype = colourGenotype,
			patternGenotype = Genetics.duochrome(),
			appearance = { type = "dual", definitionId = design.id },
			rolled = "dual",
			hadSecret = hadSecret,
			hadDual = hadDual,
		}
	elseif category == "base" then
		-- A brand-new colour, made homozygous so it shows; the pattern genes are kept.
		local others = {}
		for _, id in Colours.Ids do
			if id ~= phenotype then
				table.insert(others, id)
			end
		end
		local newColour = rng:pick(others)
		return {
			colourGenotype = Genetics.homozygous(newColour),
			patternGenotype = patternGenotype,
			appearance = Mutations.none(),
			rolled = "base",
			hadSecret = hadSecret,
			hadDual = hadDual,
		}
	end

	-- Normal: carrier parents can still give a duochrome/duochrome baby, which shows a Dual when
	-- its two colour alleles differ and an EXACT design exists for them.
	if Genetics.isDuochrome(patternGenotype) and colourGenotype.alleles[1] ~= colourGenotype.alleles[2] then
		local exact = DualDesigns.exact(colourGenotype.alleles[1], colourGenotype.alleles[2])
		if #exact > 0 then
			local design = rng:weighted(exact, DualDesigns.weight)
			return {
				colourGenotype = colourGenotype,
				patternGenotype = patternGenotype,
				appearance = { type = "dual", definitionId = design.id },
				rolled = "normal",
				hadSecret = hadSecret,
				hadDual = hadDual,
			}
		end
	end
	return {
		colourGenotype = colourGenotype,
		patternGenotype = patternGenotype,
		appearance = Mutations.none(),
		rolled = "normal",
		hadSecret = hadSecret,
		hadDual = hadDual,
	}
end

-- Bad-luck protection: turns a plain outcome into a guaranteed rare one. Secret with
-- PitySecretShare (always when the pair has no dual pool, i.e. same colour), else a Dual from
-- the pair's pool (which also makes the baby duochrome). The dual pool is asked even for a
-- same-colour pair (it is empty), so no roll is spent there, as in the original.
function Mutations.applyPity(outcome: Outcome, colourA: string, colourB: string, rng: Rng): Outcome
	local duals = DualDesigns.pool(colourA, colourB)
	local secrets = SecretRecipes.forPair(colourA, colourB)
	if #secrets > 0 and (#duals == 0 or rng:next() < Config.Mutation.PitySecretShare) then
		local recipe = rng:weighted(secrets, SecretRecipes.weight)
		local out = table.clone(outcome)
		out.appearance = { type = "secret", definitionId = recipe.id }
		out.rolled = "pity"
		return out
	elseif #duals > 0 then
		local design = rng:weighted(duals, DualDesigns.weight)
		local out = table.clone(outcome)
		out.appearance = { type = "dual", definitionId = design.id }
		out.patternGenotype = Genetics.duochrome()
		out.rolled = "pity"
		return out
	end
	return outcome
end

-- The asset a slime shows: secret > dual > base colour. Unknown ids fall through to the base.
function Mutations.assetId(appearance: Appearance, baseColour: string): string
	local id = appearance.definitionId
	if appearance.type == "secret" and id then
		local recipe = SecretRecipes.get(id)
		if recipe then
			return recipe.assetId
		end
	end
	if appearance.type == "dual" and id then
		local design = DualDesigns.get(id)
		if design then
			return design.assetId
		end
	end
	return "slime.base." .. baseColour
end

function Mutations.isKnown(appearance: Appearance): boolean
	local id = appearance.definitionId
	if appearance.type == "none" then
		return true
	elseif appearance.type == "dual" then
		return id ~= nil and DualDesigns.get(id) ~= nil
	elseif appearance.type == "secret" then
		return id ~= nil and SecretRecipes.get(id) ~= nil
	end
	return false
end

-- Field-level repair of a loaded appearance. Dual/secret ids with no definition are KEPT
-- (placeholder art), never converted; only a malformed shape becomes "none".
function Mutations.validate(raw: any): Appearance
	if type(raw) == "table" and (raw.type == "dual" or raw.type == "secret") then
		if type(raw.definitionId) == "string" and raw.definitionId ~= "" then
			return { type = raw.type, definitionId = raw.definitionId }
		end
	end
	return Mutations.none()
end

return Mutations
