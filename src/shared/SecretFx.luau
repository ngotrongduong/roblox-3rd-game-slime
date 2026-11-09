--!strict
-- The Secret slimes' signature effects: each Secret slime wears VfxLib's aura.secret_signature in the variant named
-- after it, in snake case ("Jack-o'-Slime" -> jack_o_slime).
local SecretRecipes = if script then require(script.Parent.SecretRecipes) else require("./SecretRecipes")

local SecretFx = {}

SecretFx.Effect = "aura.secret_signature"

-- The variant a Secret slime wears; nil for an id that is not a Secret.
function SecretFx.variant(secretId: string): string?
	local recipe = SecretRecipes.get(secretId)
	if not recipe then
		return nil
	end
	return (string.gsub(string.lower(recipe.name), "[^%w]+", "_"))
end

return SecretFx
