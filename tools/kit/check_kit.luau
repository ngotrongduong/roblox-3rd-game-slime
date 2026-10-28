-- Says which of the named models are in assets/Kit/PropKit.rbxm (after an export):
--   lune run tools/kit/check_kit.luau Name1 Name2 ...
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local kit = roblox.deserializeModel(fs.readFile("assets/Kit/PropKit.rbxm"))[1]
local missing = 0
for _, name in process.args do
	local found = kit:FindFirstChild(name) ~= nil
	if not found then
		missing += 1
	end
	print(string.format("%-22s %s", name, if found then "ok" else "MISSING"))
end
print(if missing == 0 then "KIT OK" else missing .. " missing")
