-- Play client (skill slime-wear), after play_check.luau: bring one Secret of the row 7 studs out in front of it onto
-- open ground (the row's ends can run into a fence: the close shots then showed planks), keep it alive there, and print
-- five camera lines: front, back, side, three-quarter (all from above, as the game sees it) and level (the painting's
-- view). The actor puts its model back on its own `root` every frame, so the root moves too.
--   node tools/studio_mcp.js run .claude/skills/slime-wear/play_close.luau <studio_id> Client SECRET=<file with the id>
-- (shoot_close.ps1 runs the whole stage, line-up and shots)
local id = string.gsub(SECRET, "%s", "")
local folder = workspace:FindFirstChild("WearCheck")
if not folder then
	return "no WearCheck row: run play_check.luau first"
end
local model = folder:FindFirstChild(id)
if not model then
	return "no " .. id .. " in the row (is it in Config.Wear.Secrets?)"
end

local sum, n = Vector3.zero, 0
for _, m in folder:GetChildren() do
	if m:IsA("Model") then
		sum += m:GetPivot().Position
		n += 1
	end
end
local old = model:GetPivot()
-- (the row faces the player: out in front of it is along the models' own look)
local spot = sum / n + old.LookVector * 7
local cf = CFrame.new(spot.X, old.Position.Y, spot.Z) * old.Rotation
for _, a in _G.WearCheckActors do
	if a.model == model then
		a.root = cf
	end
end
model:PivotTo(cf)
task.wait(0.5)

local body = model:FindFirstChild("SlimeBody") :: BasePart
local h = body.Size.Y
local head = body.Position + Vector3.new(0, h * 0.3, 0)
local front, right = cf.LookVector, cf.RightVector
local function cam(from: Vector3, at: Vector3): string
	return string.format("%.1f %.1f %.1f %.1f %.1f %.1f", from.X, from.Y, from.Z, at.X, at.Y, at.Z)
end
return table.concat({
	cam(head + front * h * 1.6 + Vector3.new(0, h * 0.5, 0), head),
	cam(head - front * h * 1.6 + Vector3.new(0, h * 0.7, 0), head),
	cam(head + right * h * 1.7 + Vector3.new(0, h * 0.3, 0), head),
	cam(head + (front + right).Unit * h * 1.7 + Vector3.new(0, h * 0.6, 0), head),
	cam(head + front * h * 1.9 - Vector3.new(0, h * 0.15, 0), head - Vector3.new(0, h * 0.2, 0)),
}, "\n")
