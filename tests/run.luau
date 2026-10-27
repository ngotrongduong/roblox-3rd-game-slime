-- Runs every spec in tests/spec (one file an area; each returns function(T)). Run by tools\check.ps1:
--   lune run tests/run.luau            all specs
--   lune run tests/run.luau genetics   only specs whose file name contains "genetics"
local fs = require("@lune/fs")
local process = require("@lune/process")

local T = require("./lib/T")

local filter = process.args[1]
local names = {}
for _, name in fs.readDir("tests/spec") do
	if string.sub(name, -5) == ".luau" and (filter == nil or string.find(name, filter, 1, true)) then
		table.insert(names, string.sub(name, 1, -6))
	end
end
table.sort(names)
if #names == 0 then
	print("no spec matched")
	process.exit(1)
end

for _, name in names do
	T.setFile(name)
	local ok, err = pcall(function()
		local spec = require("./spec/" .. name)
		spec(T)
	end)
	if not ok then
		T.setFile(name)
		T.test("(load)", function()
			error(err)
		end)
	end
end

if not T.report() then
	process.exit(1)
end
