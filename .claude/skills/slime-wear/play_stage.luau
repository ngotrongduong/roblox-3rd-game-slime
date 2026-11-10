-- Play server (skill slime-wear): put the owner's character on the open lawn east of the well, facing the stretch where
-- play_check.luau lines the Secrets up (2026-11-10: clear of the village slimes; only the row's far ends reach a fence,
-- which play_close.luau steps one Secret clear of).
--   node tools/studio_mcp.js run .claude/skills/slime-wear/play_stage.luau <studio_id> Server
local Players = game:GetService("Players")

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
task.wait(1)
hrp.CFrame = CFrame.new(184.2, 4, -450) * CFrame.Angles(0, math.pi, 0)
return "staged at " .. tostring(hrp.Position)
