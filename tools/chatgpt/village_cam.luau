-- Client, in Play after shoot_camera.luau: defines _G.PlotShot(eye, target), both in the home plot's
-- frame (x across, z from the gate in, y up; the plaza at the middle, the gate at z -80).
--   node tools/studio_mcp.js run tools/chatgpt/village_cam.luau <studio_id> Client
-- Cameras used: overview (0, 55, -75) -> (0, 0, -8); gate (-14, 13, -112) -> (0, 9, -80); fountain
-- (0, 10, -18) -> (0, 3.5, 0).
local L = require(game.ReplicatedStorage.Shared.Layout)
local f = L.plotFrame(5) * CFrame.new(0, 2, 0)
_G.PlotShot = function(eye, target)
	_G.ShotCF = CFrame.lookAt((f * CFrame.new(eye)).Position, (f * CFrame.new(target)).Position)
end
print("plot camera ready")
