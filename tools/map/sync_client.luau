-- Copies client scripts from the repo into the work place open in Studio (StarterPlayerScripts), so a
-- play test there runs them. Run with the files passed as strings, NAME=path for each script:
--   node tools/studio_mcp.js run tools/map/sync_client.luau <studio_id> Edit FoliageSway=src/client/FoliageSway.client.luau PondFish=src/client/PondFish.client.luau FireFlicker=src/client/FireFlicker.client.luau
local folder = game:GetService("StarterPlayer").StarterPlayerScripts
local sources = { FoliageSway = FoliageSway, PondFish = PondFish, FireFlicker = FireFlicker }
local done = {}
for name, src in sources do
	if src then
		local old = folder:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		local s = Instance.new("LocalScript")
		s.Name = name
		s.Source = src
		s.Parent = folder
		table.insert(done, name)
	end
end
return "client scripts: " .. table.concat(done, ", ")
