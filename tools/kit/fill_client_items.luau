-- Puts the dishes, the egg and the work tools from the work place's ServerStorage.PropKit into the work place's own
-- ReplicatedStorage.ClientKit (Items/<key>, and ClientKit.Egg), the same as tools/kit/export_client_kit.luau does for
-- assets/ClientKit.rbxm, so a play test in the work place shows them before the place is saved and exported.
--   node tools/studio_mcp.js run tools/kit/fill_client_items.luau <studio_id> Edit
local kit = game:GetService("ReplicatedStorage"):FindFirstChild("ClientKit")
local props = game:GetService("ServerStorage"):FindFirstChild("PropKit")
local items = kit and kit:FindFirstChild("Items")
if not (kit and items and props) then
	return "no ClientKit.Items or PropKit"
end
local out = {}
local function put(key: string, parent: Instance)
	local src = props:FindFirstChild(key)
	local old = parent:FindFirstChild(key)
	if old then
		old:Destroy()
	end
	if src then
		local copy = src:Clone()
		copy.Parent = parent
		table.insert(out, key .. " in " .. parent.Name)
	else
		table.insert(out, key .. " MISSING")
	end
end
for _, key in { "grilledFish", "veggieStew", "fishVegSoup", "Egg", "Hoe", "WateringCan", "FishingRod" } do
	put(key, items)
end
put("Egg", kit)
return table.concat(out, "\n")
