-- Play server (skill slime-wear): a grass stage high over the map for the owner to review every Secret slime with its
-- signature effect (2026-11-11, "xếp hết tất cả những con special lên 1 khu vực cùng với hiệu ứng riêng của chúng"), and
-- his character at its front edge facing the rows. Then run showcase.luau (Client) to put the slimes on it.
--   node tools/studio_mcp.js run .claude/skills/slime-wear/showcase_stage.luau <studio_id> Server
local Players = game:GetService("Players")

-- the middle of the stage's top face; showcase.luau reads the same numbers from the Showcase floor
local CENTRE = Vector3.new(184, 400, -450)
local SIZE = Vector3.new(150, 2, 115)

local old = workspace:FindFirstChild("Showcase")
if old then
	old:Destroy()
end
local floor = Instance.new("Part")
floor.Name = "Showcase"
floor.Anchored = true
floor.Size = SIZE
floor.CFrame = CFrame.new(CENTRE - Vector3.new(0, SIZE.Y / 2, 0))
floor.Material = Enum.Material.Grass
floor.Color = Color3.fromRGB(112, 190, 86)
floor.TopSurface = Enum.SurfaceType.Studs
floor.Parent = workspace

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
task.wait(0.5)
-- the front edge, looking down the rows (+Z)
local stand = CENTRE + Vector3.new(0, 4, -SIZE.Z / 2 + 8)
hrp.CFrame = CFrame.lookAt(stand, stand + Vector3.new(0, 0, 1))
return "stage at " .. tostring(CENTRE)
