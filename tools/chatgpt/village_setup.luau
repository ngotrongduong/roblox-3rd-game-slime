-- Server, in Play after shoot_setup.luau: parks the player and defines _G.VillageShow(level), which
-- rebuilds the home plot's village layer at that level and returns the models that found no room
-- (the layer's "Skipped" attribute, "Name@x,z ...").
--   node tools/studio_mcp.js run tools/chatgpt/village_setup.luau <studio_id> Server
local Layout = require(game.ReplicatedStorage.Shared.Layout)
local frame = Layout.plotFrame(5) * CFrame.new(0, 2, 0)
local p = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local char = p.Character or p.CharacterAdded:Wait()
task.wait(1)
char:PivotTo(frame * CFrame.new(30, 3, -100))
char.Humanoid.WalkSpeed = 0
local village = workspace.Map.Plot5.Village
local V = require(game.ServerScriptService:FindFirstChild("VillageStages", true))
_G.VillageShow = function(level)
	for _, c in village:GetChildren() do
		if c.Name == "VillageStage" then
			c:Destroy()
		end
	end
	local st = V.build(village, frame, level)
	st.Parent = village
	return st:GetAttribute("Skipped") or ""
end
print("village ready")
