-- Lays dishes (pivot at the middle, about 1 stud) in a row 1.8 studs apart on a stand far from the map for close shots
-- (y 300, z 600, centred on x 0). NAMES is a text file holding "A,B,C":
--   node tools/studio_mcp.js run tools/kit/viewer_dishes.luau <studio_id> Edit NAMES=<file>
-- Shoot from (0, 302.2, 596.5) looking at (0, 300.4, 600), and from the side at (-6, 301.5, 600).
local kit = game:GetService("ServerStorage"):FindFirstChild("PropKit")
local old = workspace:FindFirstChild("DishViewer")
if old then
	old:Destroy()
end
local f = Instance.new("Model")
f.Name = "DishViewer"
local base = Instance.new("Part")
base.Anchored = true
base.Size = Vector3.new(40, 1, 12)
base.CFrame = CFrame.new(0, 299.5, 600)
base.Color = Color3.fromRGB(210, 190, 150)
base.Parent = f
local names = {}
for name in string.gmatch(NAMES, "[^,]+") do
	table.insert(names, name)
end
local out = {}
local step = 1.8
local x = -(#names - 1) * step / 2
for _, name in names do
	local src = kit:FindFirstChild(name)
	if src then
		local c = src:Clone()
		local _, size = c:GetBoundingBox()
		c:PivotTo(CFrame.new(x, 300 + size.Y / 2, 600))
		c.Parent = f
		table.insert(out, string.format("%s at x=%.1f size %.2f,%.2f,%.2f", name, x, size.X, size.Y, size.Z))
	else
		table.insert(out, name .. " missing")
	end
	x += step
end
f.Parent = workspace
return table.concat(out, "\n")
