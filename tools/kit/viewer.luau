-- Lays out kit models in a row on a green stand far from the map (y 300, z 600, 20 studs apart from
-- x -40), each turned to show its front, for close shots before a model is used (skill prop-craft).
-- NAMES is a text file holding "A,B,C":
--   node tools/studio_mcp.js run tools/kit/viewer.luau <studio_id> Edit NAMES=<file>
-- Shoot with screen_capture camera (x, 306, 575) looking at (x, 303, 600), and from the side.
local kit = game:GetService("ServerStorage"):FindFirstChild("PropKit")
local old = workspace:FindFirstChild("KitViewer")
if old then
	old:Destroy()
end
local f = Instance.new("Model")
f.Name = "KitViewer"
local base = Instance.new("Part")
base.Anchored = true
base.Size = Vector3.new(120, 1, 40)
base.CFrame = CFrame.new(0, 299.5, 600)
base.Color = Color3.fromRGB(110, 190, 80)
base.Parent = f
local x = -40
local out = {}
for name in string.gmatch(NAMES, "[^,]+") do
	local src = kit:FindFirstChild(name)
	if src then
		local c = src:Clone()
		c:PivotTo(CFrame.new(x, 300, 600) * CFrame.Angles(0, math.pi, 0))
		c.Parent = f
		local _, size = c:GetBoundingBox()
		table.insert(out, string.format("%s at x=%d size %.1f,%.1f,%.1f", name, x, size.X, size.Y, size.Z))
		x += 20
	else
		table.insert(out, name .. " missing")
	end
end
f.Parent = workspace
print(table.concat(out, "\n"))
