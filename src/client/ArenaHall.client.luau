--!strict
-- The Arena building (workspace.Map.Arena, tools/map/build_arena.luau): a prompt in its arch opens the Arena screen, and its
-- ranking board shows the season's top rows. Both are made here, on this client only, from the named parts the build left
-- (Entrance, Board); the world streams, so they are made again whenever those parts come back. The board asks the server's
-- Arena state only while the player is near it, every Board.RefreshSeconds.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiArena = require(script.Parent.UiArena)
local UiKit = require(script.Parent.UiKit)

local A = Config.Arena
local B = A.View.Board
local U = Config.Ui

-- the board's list frame while its part is here
local rows: Frame? = nil
local board: BasePart? = nil

local function promptOn(entrance: BasePart)
	if entrance:FindFirstChild("ArenaPromptAt") then
		return
	end
	-- (on an attachment at the opening's foot, PromptLift up: the opening's middle is 7 studs up, over the head in view)
	local at = Instance.new("Attachment")
	at.Name = "ArenaPromptAt"
	at.Position = Vector3.new(0, -entrance.Size.Y / 2 + A.PromptLift, 0)
	at.Parent = entrance
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ArenaPrompt"
	prompt.ActionText = "Arena"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = A.PromptStuds
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function()
		UiArena.open()
	end)
	prompt.Parent = at
end

local function boardOn(part: BasePart)
	if part:FindFirstChild("ArenaBoard") then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ArenaBoard"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = B.PixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = part
	local list = Instance.new("Frame")
	list.Name = "Rows"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.06, 0.06)
	list.Size = UDim2.fromScale(0.88, 0.88)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = list
	rows, board = list, part
end

local function paint(top: { any })
	local list = rows
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local medals: { string } = A.View.Medals :: any
	for index = 1, math.min(#top, B.Rows) do
		local row = top[index]
		local rank = if type(row.rank) == "number" then row.rank else index
		local label = Instance.new("TextLabel")
		label.Name = "Row" .. index
		label.LayoutOrder = index
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1 / B.Rows)
		label.Font = (Enum.Font :: any)[U.Font]
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = if medals[rank] then Color3.fromHex(medals[rank]) else UiKit.colour("Brown")
		label.Text = string.format("#%d  %s", rank, tostring(row.name))
		UiKit.outline(label, medals[rank] ~= nil)
		label.Parent = list
	end
end

local function watch(arena: Instance)
	local function look(child: Instance)
		if child.Name == "Entrance" and child:IsA("BasePart") then
			promptOn(child)
		elseif child.Name == "Board" and child:IsA("BasePart") then
			boardOn(child)
		end
	end
	for _, child in arena:GetChildren() do
		look(child)
	end
	arena.ChildAdded:Connect(look)
	arena.ChildRemoved:Connect(function(child)
		if child == board then
			rows, board = nil, nil
		end
	end)
end

local map = workspace:WaitForChild("Map")
local found = map:FindFirstChild("Arena")
if found then
	watch(found)
end
map.ChildAdded:Connect(function(child)
	if child.Name == "Arena" then
		watch(child)
	end
end)

-- The board's rows: asked while the player stands near the board (an answer that fails leaves the last rows).
task.spawn(function()
	while true do
		local part = board
		local character = Players.LocalPlayer.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if part and root and root:IsA("BasePart") and (root.Position - part.Position).Magnitude <= B.NearStuds then
			local answer = UiArena.state()
			if answer and answer.ok and type(answer.top) == "table" then
				paint(answer.top)
			end
			task.wait(B.RefreshSeconds)
		else
			task.wait(2)
		end
	end
end)
