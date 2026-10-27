-- Checks of the plain logic in src/shared, run by Lune outside Roblox (tools\check.ps1).
local Config = require("../src/shared/Config")

local failures = 0

local function check(name: string, ok: boolean)
	if ok then
		print("ok   " .. name)
	else
		failures += 1
		print("FAIL " .. name)
	end
end

check("config has the game name", Config.GameName == "Goo Lineage V2")

if failures > 0 then
	error(failures .. " check(s) failed")
end
print("all checks passed")
