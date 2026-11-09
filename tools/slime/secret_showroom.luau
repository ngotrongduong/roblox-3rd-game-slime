--!nocheck
-- The Secret slime showroom, for the owner to see every Secret slime at once (2026-11-10): a stand of six steps high
-- above the map, eleven slimes a step in SecretRecipes' order, each drawn by the game's own code (client SlimeLook with
-- its skin from ClientKit.Looks, a still happy face from SlimeFace.still) and named on the step below it. The viewer
-- stands on the floor in front (Workspace.SecretShowroom.ViewSpot).
-- Run in Edit, after tools/map/sync_all.ps1 (it needs Shared, Client and ClientKit in the place):
--   node tools/studio_mcp.js run tools/slime/secret_showroom.luau <studio_id> Edit
-- Re-runnable: it replaces Workspace.SecretShowroom. Never save it into a place that is kept (StudioTest only).

local RS = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local Config = require(RS.Shared.Config)
local SecretRecipes = require(RS.Shared.SecretRecipes)
local SkinIds = require(RS.Shared.SkinIds)
local SlimeLook = require(Client.SlimeLook)
local SlimeFace = require(Client.SlimeFace)

local BASE = Vector3.new(0, 600, 0)
local PER_ROW = 11
local SHOW_SCALE = 1.4 -- times the village's size, so the skins read from the floor
local GAP_X = 9
local DEPTH = 11
-- a step rises more than a slime is tall, so the names along the top of each riser show above the row in front
local RISE = 6.5
local LABEL_H = 1.6
local FACE = "happy"
local FONT = Enum.Font.FredokaOne
local STEP_COLOUR = Color3.fromHex("#efe6d2")
local FLOOR_COLOUR = Color3.fromHex("#d9cdb4")
local SIGN_COLOUR = Color3.fromHex("#5a4636")
local TEXT_COLOUR = Color3.fromHex("#fff8e8")

local old = workspace:FindFirstChild("SecretShowroom")
if old then
	old:Destroy()
end
local room = Instance.new("Model")
room.Name = "SecretShowroom"

local rows = math.ceil(#SecretRecipes.List / PER_ROW)
local width = PER_ROW * GAP_X + 6

local function block(name, size, cf, colour)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.Parent = room
	return p
end

-- a strip facing the viewer (-Z) with `cells` equal columns, each a name over a smaller line
local function sign(name, size, cf, cells)
	local p = block(name, size, cf, SIGN_COLOUR)
	p.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = p
	for i, cell in cells do
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1 / #cells, 1)
		frame.Position = UDim2.fromScale((i - 1) / #cells, 0)
		frame.Parent = gui
		local top = Instance.new("TextLabel")
		top.BackgroundTransparency = 1
		top.Size = UDim2.fromScale(0.94, if cell[2] then 0.5 else 0.8)
		top.Position = UDim2.fromScale(0.03, if cell[2] then 0.08 else 0.1)
		top.Font = FONT
		top.TextScaled = true
		top.TextColor3 = TEXT_COLOUR
		top.Text = cell[1]
		top.Parent = frame
		if cell[2] then
			local low = top:Clone()
			low.Size = UDim2.fromScale(0.94, 0.3)
			low.Position = UDim2.fromScale(0.03, 0.62)
			low.TextTransparency = 0.25
			low.Text = cell[2]
			low.Parent = frame
		end
	end
	return p
end

-- the floor in front, the viewer's spot on it
block("Floor", Vector3.new(width + 20, 1, 60), CFrame.new(BASE + Vector3.new(0, -0.5, -DEPTH / 2 - 30)), FLOOR_COLOUR)
local spot = block("ViewSpot", Vector3.new(4, 0.2, 4), CFrame.new(BASE + Vector3.new(0, 0.1, -DEPTH / 2 - 34)), SIGN_COLOUR)
spot.CanCollide = false

local slimes = Instance.new("Folder")
slimes.Name = "Slimes"
slimes.Parent = room
for r = 0, rows - 1 do
	local top = BASE.Y + (r + 1) * RISE
	local z = BASE.Z + r * DEPTH
	block(
		"Step" .. r + 1,
		Vector3.new(width, top - BASE.Y + 1, DEPTH),
		CFrame.new(BASE.X, (top + BASE.Y - 1) / 2, z),
		STEP_COLOUR
	)
	local cells = {}
	for c = 1, PER_ROW do
		local recipe = SecretRecipes.List[r * PER_ROW + c]
		if not recipe then
			table.insert(cells, { "" })
			continue
		end
		local pair = recipe.parentPair[1] .. " + " .. recipe.parentPair[2]
		if not SkinIds.get(recipe.id) then
			pair ..= " (own 3D model, not in yet)"
		end
		table.insert(cells, { recipe.name, pair })

		local model = SlimeLook.build({ SecretId = recipe.id, Colour = recipe.parentPair[1], Scale = 1 })
		model.Name = recipe.id
		model:ScaleTo(model:GetScale() * SHOW_SCALE)
		local body = model:FindFirstChild("SlimeBody")
		if body then
			SlimeFace.still(model, body.Size.Y / Config.Slime.MeshHeight, FACE)
		end
		-- the face is on the model's look vector; turn it to the viewer (-Z)
		local eye = model:FindFirstChild("EyeL", true)
		local turn = if eye and eye.Position.Z > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
		-- the viewer looks along +Z, so +X is on their left, where the sign's first column is
		local x = BASE.X - (c - (PER_ROW + 1) / 2) * GAP_X
		model:PivotTo(CFrame.new(x, top, z) * turn)
		model.Parent = slimes
	end
	sign(
		"Names" .. r + 1,
		Vector3.new(width - 2, LABEL_H, 0.2),
		CFrame.new(BASE.X, top - LABEL_H / 2 - 0.15, z - DEPTH / 2 - 0.1),
		cells
	)
end
sign(
	"Title",
	Vector3.new(36, 5, 0.4),
	CFrame.new(BASE.X, BASE.Y + (rows + 1) * RISE + 6, BASE.Z + (rows - 1) * DEPTH + DEPTH / 2),
	{ { "Secret Slimes", #SecretRecipes.List .. " of them" } }
)

room.WorldPivot = spot.CFrame
room.Parent = workspace
return string.format("showroom: %d Secret slimes on %d steps, view spot at %s", #slimes:GetChildren(), rows, tostring(spot.Position))
