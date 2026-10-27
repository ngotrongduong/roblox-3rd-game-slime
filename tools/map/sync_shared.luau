-- Copies the current source of shared modules into the work place open in Studio, so the map builders
-- there require the same Config and Layout as the repo. Run with the files passed as strings:
--   node tools/studio_mcp.js run tools/map/sync_shared.luau <studio_id> Edit CONFIG=src/shared/Config.luau LAYOUT=src/shared/Layout.luau
-- Each module is swapped for a fresh copy: Studio caches what require returned per ModuleScript, and a
-- plain Source write does not stick while the script is open in an editor tab.
local shared = game:GetService("ReplicatedStorage").Shared
local sources = { Config = CONFIG, Layout = LAYOUT }
local done = {}
for name, src in sources do
	local old = shared:FindFirstChild(name)
	if old and src then
		local m = old:Clone()
		m.Source = src
		old:Destroy()
		m.Parent = shared
		table.insert(done, name .. " (" .. #m.Source .. ")")
	end
end
return "synced " .. table.concat(done, ", ")
