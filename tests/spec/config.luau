local Config = require("../../src/shared/Config")

return function(T)
	T.test("the game is called Goo Lineage V2", function()
		T.eq(Config.GameName, "Goo Lineage V2")
	end)
end
