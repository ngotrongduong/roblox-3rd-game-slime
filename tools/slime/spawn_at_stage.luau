--!nocheck
-- MapWork only (`node tools/studio_mcp.js run`, Edit): every play test puts the player on the emotion
-- stage, facing the slimes, so the owner only presses Play; falling off respawns him there too.
-- Re-runnable; delete Workspace.SlimeEmotions.SpawnAtStage to spawn at the map's spawn again.

local f = workspace:FindFirstChild("SlimeEmotions")
assert(f, "build the emotion stage first (tools/slime/emotions.ps1)")
local old = f:FindFirstChild("SpawnAtStage")
if old then
	old:Destroy()
end
-- a strip in front of the stage to stand on (the stage itself starts at z -790)
local apron = f:FindFirstChild("Apron") or f.Stage:Clone()
apron.Name = "Apron"
apron.Size = Vector3.new(66, 1, 12)
apron.CFrame = CFrame.new(-75, 299.5, -784)
apron.Parent = f
local s = Instance.new("Script")
s.Name = "SpawnAtStage"
s.Source = [[
local Players = game:GetService("Players")
local SPOT = CFrame.lookAt(Vector3.new(-75, 303.5, -783), Vector3.new(-75, 303.5, -800))
local function onCharacter(c)
	local hrp = c:WaitForChild("HumanoidRootPart", 10)
	if hrp then
		task.wait(0.3)
		hrp.CFrame = SPOT
	end
end
local function onPlayer(p)
	p.CharacterAdded:Connect(onCharacter)
	if p.Character then
		onCharacter(p.Character)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	onPlayer(p)
end
]]
s.Parent = f
return "every play test now starts on the emotion stage"
