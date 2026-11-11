-- Play client (skill slime-wear): every Secret slime (SecretRecipes, in the original order, 11 to a row) alive on the
-- showcase stage (showcase_stage.luau, run first), each wearing its pieces and its signature effect as the village
-- draws it, with its name on a small tag at its feet so the owner can say which one he means. Review only: nothing
-- here reaches players. Run again to rebuild.
--   node tools/studio_mcp.js run .claude/skills/slime-wear/showcase.luau <studio_id> Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SecretRecipes = require(ReplicatedStorage.Shared.SecretRecipes)
local SecretFx = require(ReplicatedStorage.Shared.SecretFx)
local VfxLib = require(ReplicatedStorage.Shared.VfxLib)
local Client = Players.LocalPlayer.PlayerScripts:WaitForChild("Client")
local SlimeLook = require(Client.SlimeLook)
local SlimeActor = require(Client.SlimeActor)

local PER_ROW = 11
local GAP_X = 12
local GAP_Z = 15

local floor = workspace:WaitForChild("Showcase", 10) :: BasePart
assert(floor, "no Showcase stage: run showcase_stage.luau (Server) first")
local top = floor.Position + Vector3.new(0, floor.Size.Y / 2, 0)

if _G.ShowcaseActors then
	for _, actor in _G.ShowcaseActors do
		SlimeActor.destroy(actor)
	end
end
local old = workspace:FindFirstChild("ShowcaseSlimes")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "ShowcaseSlimes"
folder.Parent = workspace
_G.ShowcaseActors = {}

local rows = math.ceil(#SecretRecipes.List / PER_ROW)
local count, effects = 0, 0
for k, recipe in SecretRecipes.List do
	local col = (k - 1) % PER_ROW
	local row = (k - 1) // PER_ROW
	local at = top + Vector3.new((col - (PER_ROW - 1) / 2) * GAP_X, 0, (row - (rows - 1) / 2) * GAP_Z)
	-- every slime faces the stage's front edge, where the owner starts
	local face = CFrame.lookAt(at, at - Vector3.new(0, 0, 1))
	local model = SlimeLook.build({
		SecretId = recipe.id,
		Colour = string.match(recipe.id, "^secret%-(%a+)"),
		Scale = 1,
	})
	model.Name = recipe.id
	model:PivotTo(face)
	model.Parent = folder
	table.insert(_G.ShowcaseActors, SlimeActor.new(model, "happy"))
	count += 1
	local body = model:FindFirstChild("SlimeBody")
	local variant = SecretFx.variant(recipe.id)
	if body and variant and VfxLib.attach(body, SecretFx.Effect, { variant = variant, weld = true }) then
		effects += 1
	end

	-- the name tag, on the ground in front of its feet
	local tag = Instance.new("Part")
	tag.Name = recipe.id .. "-tag"
	tag.Anchored = true
	tag.CanCollide = false
	tag.CanQuery = false
	tag.Transparency = 1
	tag.Size = Vector3.new(0.2, 0.2, 0.2)
	tag.Position = at + Vector3.new(0, 0.4, -4)
	tag.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(170, 30)
	-- only the names near him, so far rows do not pile up into one strip of text
	gui.MaxDistance = 28
	gui.AlwaysOnTop = false
	gui.Parent = tag
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(255, 248, 232)
	label.BackgroundTransparency = 0.1
	label.TextColor3 = Color3.fromRGB(92, 58, 36)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = string.format("%d. %s", k, recipe.name)
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end
return string.format("%d slimes, %d effects", count, effects)
