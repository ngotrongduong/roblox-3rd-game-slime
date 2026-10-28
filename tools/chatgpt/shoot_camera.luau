-- Review shots, client side (run in the Client datamodel during a play test through MCP
-- execute_luau or `studio_mcp.js run ... Client`): holds the camera at _G.ShotCF every frame
-- (FieldOfView 50) and sets _G.ShotAt(areaCol, areaRow, eye, target) to aim it in an area's frame
-- (skill chatgpt-review).
local RS = game:GetService("RunService")
local L = require(game.ReplicatedStorage.Shared.Layout)
_G.ShotAt = function(col: number, row: number, eye: Vector3, target: Vector3)
	local f = L.plotAreaFacing(5, col, row) * CFrame.new(0, 2, 0)
	_G.ShotCF = CFrame.lookAt((f * CFrame.new(eye)).Position, (f * CFrame.new(target)).Position)
end
_G.ShotCF = workspace.CurrentCamera.CFrame
RS:UnbindFromRenderStep("ShotCam")
RS:BindToRenderStep("ShotCam", Enum.RenderPriority.Last.Value + 1, function()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 50
	cam.CFrame = _G.ShotCF
end)
return "camera ready"
