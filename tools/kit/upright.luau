-- Turns a kit model in ServerStorage.PropKit by ROT ("Name,degX,degZ", a text file) about its foot and
-- sets its pivot at the middle of its foot again. Check from TWO sides first: a model that looks tilted
-- from one camera is often straight (skill prop-craft).
--   node tools/studio_mcp.js run tools/kit/upright.luau <studio_id> Edit ROT=<file>
local name, ax, az = string.match(ROT, "([%w_]+),([%-%d%.]+),([%-%d%.]+)")
local m = game:GetService("ServerStorage").PropKit:FindFirstChild(name)
local turn = CFrame.Angles(math.rad(tonumber(ax) :: number), 0, math.rad(tonumber(az) :: number))
for _, d in m:GetDescendants() do
	if d:IsA("BasePart") then
		d.CFrame = turn * d.CFrame
	end
end
local box, size = m:GetBoundingBox()
m.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
m:PivotTo(CFrame.new())
print(string.format("%s %.1f x %.1f x %.1f", name, size.X, size.Y, size.Z))
