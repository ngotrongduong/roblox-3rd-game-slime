-- Review shots, server side (run in the Server datamodel during a play test through MCP
-- execute_luau): parks the player out of the way and defines _G.AreaShow(stagesModule, areaName,
-- col, row, level) to rebuild an area's stage layer at any level. Pair it with a client camera bound
-- to _G.ShotCF (skill chatgpt-review).
local L = require(game.ReplicatedStorage.Shared.Layout)
local p = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local char = p.Character or p.CharacterAdded:Wait()
workspace.Map.Plot5:WaitForChild("PantryL1")
task.wait(1)
char:PivotTo(L.plotFrame(5) * CFrame.new(0, 5, -110))
char.Humanoid.WalkSpeed = 0
_G.AreaShow = function(modName: string, areaName: string, col: number, row: number, level: number)
	local a = workspace.Map.Plot5[areaName]
	local f = L.plotAreaFacing(5, col, row) * CFrame.new(0, 2, 0)
	local M = require(game.ServerScriptService:FindFirstChild(modName, true))
	for _, c in a:GetChildren() do
		if c.Name == "AreaStage" then
			c:Destroy()
		end
	end
	local st = M.build(a, f, level)
	st.Parent = a
	return #st:GetDescendants()
end
return "ready"
