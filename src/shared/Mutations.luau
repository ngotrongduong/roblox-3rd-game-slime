--!strict
-- One category roll, then a uniform choice from the pair's colour pools (docs/GAMEPLAY.md §1).

local Config = if script then require(script.Parent.Config) else require("./Config")
local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local DualDesigns = if script then require(script.Parent.DualDesigns) else require("./DualDesigns")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Luck = if script then require(script.Parent.Luck) else require("./Luck")
local Materials = if script then require(script.Parent.Materials) else require("./Materials")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local SecretRecipes = if script then require(script.Parent.SecretRecipes) else require("./SecretRecipes")

type Rng = typeof(Rng.new(0))
type ColourGenotype = typeof(Genetics.homozygous(""))
type Recipe = typeof(SecretRecipes.List[1])
type Design = typeof(DualDesigns.List[1])
type Material = typeof(Materials.List[1])

local Mutations = {}

export type Appearance = { type: string, definitionId: string? }
export type Parent = { colourGenotype: ColourGenotype, appearanceMutation: Appearance }
export type Outcome = {
	colourGenotype: ColourGenotype,
	appearance: Appearance,
	-- The category remains Plain when its separate material roll succeeds.
	rolled: string,
	hadSecret: boolean,
	hadDual: boolean,
}
export type Chances = {
	secret: number,
	dual: number,
	plain: number,
	random: number,
	material: number,
	colours: { string },
	secrets: { Recipe },
	duals: { Design },
	materials: { Material },
}

function Mutations.none(): Appearance
	return { type = "none" }
end

function Mutations.copy(appearance: Appearance): Appearance
	return { type = appearance.type, definitionId = appearance.definitionId }
end

function Mutations.rarity(appearance: Appearance): string
	if appearance.type == "secret" or appearance.type == "material" or appearance.type == "dual" then
		return appearance.type
	end
	return "base"
end

local function parentKind(parent: Parent): string
	local kind = parent.appearanceMutation.type
	return if kind == "secret" or kind == "dual" then kind else "plain"
end

function Mutations.pairingKind(a: Parent, b: Parent): string
	local ka, kb = parentKind(a), parentKind(b)
	local same = a.appearanceMutation.definitionId == b.appearanceMutation.definitionId
	if ka == "secret" and kb == "secret" then
		return if same then "secretSame" else "secretOther"
	elseif ka == "secret" or kb == "secret" then
		local other = if ka == "secret" then kb else ka
		return if other == "dual" then "secretDual" else "secretPlain"
	elseif ka == "dual" and kb == "dual" then
		return if same then "dualSame" else "dualOther"
	elseif ka == "dual" or kb == "dual" then
		return "dualPlain"
	end
	return if Genetics.baseColours(a)[1] == Genetics.baseColours(b)[1] then "plainSame" else "plainOther"
end

function Mutations.chances(a: Parent, b: Parent, luck: number): Chances
	local row = (Config.Inheritance :: { [string]: { secret: number, dual: number, random: number } })[Mutations.pairingKind(
		a,
		b
	)]
	local colours = Genetics.colourSet(a, b)
	local duals = Genetics.dualPool(colours)
	local secrets = Genetics.secretPool(colours)
	local baseSecret = if #secrets > 0 then row.secret else 0
	local baseDual = if #duals > 0 then row.dual else 0
	local secret = Luck.chance(baseSecret, luck)
	local dual = Luck.chance(baseDual, luck)
	local available = 1 - row.random
	-- Once Plain is exhausted, scale only the gains so luck never lowers either rare chance.
	if secret + dual > available then
		local gain = secret + dual - baseSecret - baseDual
		local scale = (available - baseSecret - baseDual) / gain
		secret = baseSecret + (secret - baseSecret) * scale
		dual = baseDual + (dual - baseDual) * scale
	end
	return {
		secret = secret,
		dual = dual,
		plain = math.max(0, available - secret - dual),
		random = row.random,
		material = Luck.chance(Config.Mutation.MaterialChance, luck),
		colours = colours,
		secrets = secrets,
		duals = duals,
		materials = Materials.List,
	}
end

function Mutations.rollCategory(rng: Rng, chances: Chances): string
	local roll = rng:next()
	if roll < chances.secret then
		return "secret"
	elseif roll < chances.secret + chances.dual then
		return "dual"
	elseif roll < 1 - chances.random then
		return "plain"
	end
	return "random"
end

function Mutations.resolveOffspring(a: Parent, b: Parent, rng: Rng, luck: number): Outcome
	local c = Mutations.chances(a, b, luck)
	local category = Mutations.rollCategory(rng, c)
	local appearance = Mutations.none()
	local genotype: ColourGenotype
	if category == "secret" then
		local recipe = rng:pick(c.secrets)
		appearance = { type = "secret", definitionId = recipe.id }
		genotype = { alleles = table.clone(recipe.parentPair) }
	elseif category == "dual" then
		local design = rng:pick(c.duals)
		appearance = { type = "dual", definitionId = design.id }
		genotype = { alleles = table.clone(design.parentPair) }
	elseif category == "plain" then
		genotype = Genetics.homozygous(rng:pick(c.colours))
		if rng:next() < c.material then
			local material = rng:weighted(c.materials, Materials.weight)
			appearance = { type = "material", definitionId = material.id }
		end
	else
		local others = {}
		for _, id in Colours.Ids do
			if not table.find(c.colours, id) then
				table.insert(others, id)
			end
		end
		genotype = Genetics.homozygous(rng:pick(others))
	end
	return {
		colourGenotype = genotype,
		appearance = appearance,
		rolled = category,
		hadSecret = #c.secrets > 0,
		hadDual = #c.duals > 0,
	}
end

-- Pity changes only plain appearances; material eggs reset the streak without being converted.
function Mutations.applyPity(outcome: Outcome, a: Parent, b: Parent, rng: Rng): Outcome
	if outcome.appearance.type ~= "none" then
		return outcome
	end
	local colours = Genetics.colourSet(a, b)
	local duals = Genetics.dualPool(colours)
	local secrets = Genetics.secretPool(colours)
	local appearance: Appearance
	if #secrets > 0 and (#duals == 0 or rng:next() < Config.Mutation.PitySecretShare) then
		appearance = { type = "secret", definitionId = rng:pick(secrets).id }
	elseif #duals > 0 then
		appearance = { type = "dual", definitionId = rng:pick(duals).id }
	else
		return outcome
	end
	local out = table.clone(outcome)
	out.appearance = appearance
	out.colourGenotype = Genetics.fromAppearance(appearance, outcome.colourGenotype)
	out.rolled = "pity"
	return out
end

-- The asset a slime shows: secret > material > dual > base colour. Unknown ids fall through to the base.
function Mutations.assetId(appearance: Appearance, baseColour: string): string
	local id = appearance.definitionId
	if appearance.type == "secret" and id then
		local recipe = SecretRecipes.get(id)
		if recipe then
			return recipe.assetId
		end
	end
	if appearance.type == "material" and id then
		local material = Materials.get(id)
		if material then
			return material.assetId
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
	elseif appearance.type == "material" then
		return id ~= nil and Materials.get(id) ~= nil
	end
	return false
end

-- Field-level repair of a loaded appearance. Dual/secret/material ids with no definition are KEPT
-- (placeholder art), never converted; only a malformed shape becomes "none".
function Mutations.validate(raw: any): Appearance
	if type(raw) == "table" and (raw.type == "dual" or raw.type == "secret" or raw.type == "material") then
		if type(raw.definitionId) == "string" and raw.definitionId ~= "" then
			return { type = raw.type, definitionId = raw.definitionId }
		end
	end
	return Mutations.none()
end

-- ===== selling =====

-- What a slime of this appearance is worth at level 0: Config.Economy.SellBase by kind, a material by
-- its tier (an unknown material id sells as the lowest tier).
function Mutations.sellBase(appearance: Appearance): number
	local base = Config.Economy.SellBase
	if appearance.type == "secret" then
		return base.secret
	elseif appearance.type == "dual" then
		return base.dual
	elseif appearance.type == "material" then
		local material = if appearance.definitionId then Materials.get(appearance.definitionId) else nil
		return if material then material.sellBase else Config.Material.SellBase.common
	end
	return base.none
end

-- floor(base × (1 + level × SellLevelStep)), never negative.
function Mutations.sellValue(appearance: Appearance, level: number): number
	local factor = 1 + math.max(0, level) * Config.Economy.SellLevelStep
	return math.max(0, math.floor(Mutations.sellBase(appearance) * factor))
end

-- Dual, Secret and Material slimes ask before they are sold.
function Mutations.needsSellConfirm(appearance: Appearance): boolean
	return appearance.type == "secret" or appearance.type == "material" or appearance.type == "dual"
end

return Mutations
