-- Edit datamodel (skill slime-wear): the ear editor. Puts the Secrets named in EDIT, dressed and still, twice the
-- game's size, on a stage high over the map, with the Studio camera on them, so the owner can drag and turn each worn
-- piece (those PIECES names) with Studio's Move (Ctrl+2) and Rotate (Ctrl+3) tools; then `ear_read.luau` reads what he
-- did back into numbers for Config.Wear. Each slime's parts sit in a Folder (not a Model) so a click picks one piece;
-- everything else is locked. REFERENCE slimes stand at the end, locked whole, to compare with. Run again to start over from Config.
--   node tools/studio_mcp.js run .claude/skills/slime-wear/ear_editor.luau <studio_id> Edit
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local EDIT = {
	"secret-orange-pink",
	"secret-orange-red",
	"secret-green-orange",
	"secret-green-red",
	"secret-navy-navy",
	"secret-white-white",
	"secret-pink-white",
}
local REFERENCE = {}
-- the worn pieces he may move: names matching this pattern ("Ear" for ears only; "" for every piece)
local PIECES = ""
-- each slime's body this many studs tall (the game's is about 4)
local HEIGHT = 8
local STAGE = Vector3.new(0, 600, 0)

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeLook = require(StarterPlayer.StarterPlayerScripts.Client.SlimeLook)

local old = workspace:FindFirstChild("EarEditor")
if old then
	old:Destroy()
end
local stage = Instance.new("Folder")
stage.Name = "EarEditor"
stage.Parent = workspace

local all = table.clone(EDIT)
for _, id in REFERENCE do
	table.insert(all, id)
end
local gap = HEIGHT * 1.8
local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Locked = true
floor.Size = Vector3.new(gap * #all + 10, 1, 30)
floor.CFrame = CFrame.new(STAGE - Vector3.new(0, 0.5, 0))
floor.Color = Color3.fromRGB(120, 170, 90)
floor.Parent = stage

local function editable(kit, name: string): boolean
	for _, spec in kit.pieces do
		if spec.name == name then
			return string.find(name, PIECES, 1, true) ~= nil
		end
	end
	return false
end

local out = {}
for k, id in all do
	local kit = Config.Wear.Kits[Config.Wear.Secrets[id]]
	local model = SlimeLook.build({ SecretId = id, Colour = string.match(id, "^secret%-(%a+)"), Scale = 1 })
	model.Parent = stage
	local t0 = os.clock()
	local n = 0
	repeat
		task.wait(0.2)
		n = 0
		for _, spec in kit.pieces do
			if model:FindFirstChild(spec.name) then
				n += 1
			end
		end
	until n == #kit.pieces or os.clock() - t0 > 20
	local slime = model:FindFirstChild("SlimeBody") :: BasePart
	model:ScaleTo(model:GetScale() * HEIGHT / slime.Size.Y)
	-- the row faces -Z, where the camera stands (its right is -X), the first on the left; feet on the floor
	model:PivotTo(CFrame.new(STAGE - Vector3.new((k - (#all + 1) / 2) * gap, 0, 0)))
	local feetY = (slime.CFrame * CFrame.new(0, -Config.Slime.MeshCentre * slime.Size.Y / Config.Slime.MeshHeight, 0)).Y
	model:PivotTo(model:GetPivot() + Vector3.new(0, STAGE.Y - feetY, 0))
	local reference = table.find(REFERENCE, id) ~= nil
	local folder = Instance.new("Folder")
	folder.Name = Config.Wear.Secrets[id] .. (if reference then " (reference)" else "")
	folder:SetAttribute("SecretId", id)
	folder.Parent = stage
	for _, child in model:GetChildren() do
		child.Parent = folder
	end
	model:Destroy()
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.Locked = reference or not editable(kit, d.Name)
		end
	end
	local body = folder:FindFirstChild("SlimeBody") :: BasePart
	local tag = Instance.new("BillboardGui")
	tag.Name = "Label"
	tag.Size = UDim2.fromOffset(220, 40)
	tag.StudsOffsetWorldSpace = Vector3.new(0, body.Size.Y * 0.95, 0)
	tag.AlwaysOnTop = true
	tag.Adornee = body
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.Text = folder.Name
	text.Parent = tag
	tag.Parent = body
	table.insert(out, string.format("%s %s %d/%d pieces", id, folder.Name, n, #kit.pieces))
end

local camera = workspace.CurrentCamera
local look = STAGE + Vector3.new(0, HEIGHT * 0.6, 0)
camera.CFrame = CFrame.lookAt(look + Vector3.new(0, HEIGHT * 0.9, -gap * #all * 0.62), look)
camera.Focus = CFrame.new(look)
game:GetService("Selection"):Set({})
return table.concat(out, "\n")
