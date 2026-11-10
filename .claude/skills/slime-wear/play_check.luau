-- Play client (skill slime-wear): every Secret slime that wears pieces (Config.Wear.Secrets), alive, in a row 14 studs in
-- front of the player and facing him. Prints whether each wears all its pieces and, for each, the camera of a close shot
-- from the front and from behind (`node tools/studio_mcp.js shot <studio_id> <out.png> cx cy cz lx ly lz`). Steps the
-- player's character aside so it stays out of the shots. Run again to rebuild the row.
--   node tools/studio_mcp.js run .claude/skills/slime-wear/play_check.luau <studio_id> Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer
local Client = player.PlayerScripts:WaitForChild("Client")
local SlimeLook = require(Client.SlimeLook)
local SlimeActor = require(Client.SlimeActor)

local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
local humanoid = char:WaitForChild("Humanoid") :: Humanoid

local old = workspace:FindFirstChild("WearCheck")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "WearCheck"
folder.Parent = workspace

local ids = {}
for id in Config.Wear.Secrets do
	table.insert(ids, id)
end
table.sort(ids)

local ahead = (hrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
local feet = Vector3.new(hrp.Position.X, hrp.Position.Y - hrp.Size.Y / 2 - humanoid.HipHeight, hrp.Position.Z)
local centre = feet + ahead * 14
-- the row faces the player
local face = CFrame.lookAt(centre, centre - ahead)
local models = {}
_G.WearCheckActors = {}
for k, id in ids do
	local model = SlimeLook.build({ SecretId = id, Colour = string.match(id, "^secret%-(%a+)"), Scale = 1 })
	model.Name = id
	model:PivotTo(face * CFrame.new((k - (#ids + 1) / 2) * 6, 0, 0))
	model.Parent = folder
	table.insert(_G.WearCheckActors, SlimeActor.new(model, "happy"))
	models[k] = model
end

local function worn(k: number): (number, number)
	local pieces = Config.Wear.Kits[Config.Wear.Secrets[ids[k]]].pieces
	local n = 0
	for _, spec in pieces do
		if models[k]:FindFirstChild(spec.name) then
			n += 1
		end
	end
	return n, #pieces
end

local t0 = os.clock()
repeat
	task.wait(0.25)
	local all = true
	for k in models do
		local n, of = worn(k)
		all = all and n == of
	end
until all or os.clock() - t0 > 15

hrp.CFrame += face.RightVector * 30

local function cam(from: Vector3, at: Vector3): string
	return string.format("%.1f %.1f %.1f %.1f %.1f %.1f", from.X, from.Y, from.Z, at.X, at.Y, at.Z)
end
local out = { string.format("loaded in %.1f s", os.clock() - t0) }
for k, model in models do
	local n, of = worn(k)
	local body = model:FindFirstChild("SlimeBody") :: BasePart
	local h = body.Size.Y
	local head = body.Position + Vector3.new(0, h * 0.3, 0)
	local front = face.LookVector
	table.insert(out, string.format("%s %s %d/%d pieces", ids[k], Config.Wear.Secrets[ids[k]], n, of))
	table.insert(out, "  front " .. cam(head + front * h * 1.6 + Vector3.new(0, h * 0.5, 0), head))
	table.insert(out, "  back  " .. cam(head - front * h * 1.6 + Vector3.new(0, h * 0.7, 0), head))
end
return table.concat(out, "\n")
