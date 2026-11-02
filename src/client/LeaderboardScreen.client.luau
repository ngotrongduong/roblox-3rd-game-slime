--!strict
-- The Market's leaderboard, drawn on a SurfaceGui on the part named Config.Market.ScreenName inside
-- workspace.Map.Market.<Config.Market.BoardModel> (the scene artist's model). The rows come from the server as attributes of
-- ReplicatedStorage.<Config.Leaderboard.Folder> (Count, Row1..RowN: "player<TAB>slime<TAB>level", server/Leaderboard.luau).
-- Nothing here blocks: the model may not exist yet or may stream in later, so a slow loop looks for the screen, and the
-- rows are only redrawn when the server changed them. Big letters, high contrast: it is read from across the square.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Board = require(ReplicatedStorage.Shared.Leaderboard)

local L = Config.Leaderboard
local M = Config.Market
local U = Config.Ui
local FONT = (Enum.Font :: any)[U.Font] :: Enum.Font

type Row = { frame: Frame, rank: TextLabel, player: TextLabel, slime: TextLabel, level: TextLabel }
type Drawn = { gui: SurfaceGui, rows: { Row }, empty: TextLabel }

local folder: Folder? = nil
local drawn: Drawn? = nil
local lastSignature = ""
local queued = false

local function colour(name: string): Color3
	return Color3.fromHex((U.Colours :: any)[name])
end

-- The size in studs of the face of a part that the board is drawn on.
local function faceSize(part: BasePart, face: Enum.NormalId): Vector2
	if face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		return Vector2.new(part.Size.Z, part.Size.Y)
	elseif face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		return Vector2.new(part.Size.X, part.Size.Z)
	end
	return Vector2.new(part.Size.X, part.Size.Y)
end

local function text(parent: Instance, name: string, x: number, width: number, align: Enum.TextXAlignment, tint: string)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(x, 0)
	label.Size = UDim2.fromScale(width, 1)
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = colour(tint)
	label.TextXAlignment = align
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = ""
	label.Parent = parent
	return label
end

-- The empty board on the screen: a title and L.Rows blank lines.
local function build(screen: BasePart): Drawn
	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.Face = (Enum.NormalId :: any)[L.Face] :: Enum.NormalId
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = faceSize(screen, gui.Face) * L.PixelsPerStud
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = colour("Parchment")
	back.BorderSizePixel = 0
	back.Parent = gui

	local title = text(back, "Title", 0.04, 0.92, Enum.TextXAlignment.Center, "Wood")
	title.Size = UDim2.fromScale(0.92, L.TitleShare * 0.8)
	title.Position = UDim2.fromScale(0.04, L.TitleShare * 0.1)
	title.Text = L.Title

	local top = L.TitleShare
	local height = (1 - top - 0.03) / L.Rows
	local rows: { Row } = {}
	for index = 1, L.Rows do
		local frame = Instance.new("Frame")
		frame.Name = "Row" .. index
		frame.Position = UDim2.fromScale(0.03, top + (index - 1) * height)
		frame.Size = UDim2.fromScale(0.94, height * 0.92)
		frame.BackgroundColor3 = colour(if index % 2 == 1 then "CardDeep" else "Card")
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.Parent = back
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = frame
		table.insert(rows, {
			frame = frame,
			rank = text(frame, "Rank", 0.02, 0.1, Enum.TextXAlignment.Center, if index == 1 then "Gold" else "Brown"),
			player = text(frame, "Player", 0.14, 0.34, Enum.TextXAlignment.Left, "Brown"),
			slime = text(frame, "Slime", 0.5, 0.32, Enum.TextXAlignment.Left, "BrownSoft"),
			level = text(frame, "Level", 0.84, 0.14, Enum.TextXAlignment.Right, "Brown"),
		})
		-- (the letters grow to fill the row, up to a limit)
		for _, label in { rows[index].rank, rows[index].player, rows[index].slime, rows[index].level } do
			local limit = Instance.new("UITextSizeConstraint")
			limit.MinTextSize = L.TextMin
			limit.MaxTextSize = L.TextMax
			limit.Parent = label
		end
	end
	local empty = text(back, "Empty", 0.04, 0.92, Enum.TextXAlignment.Center, "BrownSoft")
	empty.Position = UDim2.fromScale(0.04, top + height)
	empty.Size = UDim2.fromScale(0.92, height)
	empty.Text = L.Empty
	empty.Visible = false

	gui.Parent = screen
	return { gui = gui, rows = rows, empty = empty }
end

-- Puts the server's rows on the screen, if they changed.
local function draw()
	queued = false
	local target, source = drawn, folder
	if not target or not source then
		return
	end
	local published = source:GetAttribute("Count")
	local count = if type(published) == "number" then math.clamp(published, 0, L.Rows) else 0
	local lines: { string } = {}
	for index = 1, count do
		local row = source:GetAttribute("Row" .. index)
		table.insert(lines, if type(row) == "string" then row else "")
	end
	local signature = table.concat(lines, "\n")
	if signature == lastSignature and target.gui.Parent then
		return
	end
	lastSignature = signature
	for index, row in target.rows do
		local player, slime, level = Board.decodeRow(lines[index])
		row.frame.Visible = player ~= nil
		if player and slime and level then
			row.rank.Text = tostring(index)
			row.player.Text = player
			row.slime.Text = slime
			row.level.Text = tostring(level)
		end
	end
	target.empty.Visible = count == 0
end

local function schedule()
	if not queued then
		queued = true
		task.defer(draw)
	end
end

local function findScreen(): BasePart?
	local map = workspace:FindFirstChild("Map")
	local market = if map then map:FindFirstChild(M.Model) else nil
	local board = if market then market:FindFirstChild(M.BoardModel) else nil
	local screen = if board then board:FindFirstChild(M.ScreenName, true) else nil
	return if screen and screen:IsA("BasePart") then screen else nil
end

-- The published rows: the server makes the folder at start; a client that is early waits for it.
task.spawn(function()
	local found = ReplicatedStorage:WaitForChild(L.Folder, 30)
	if found and found:IsA("Folder") then
		folder = found
		found.AttributeChanged:Connect(schedule)
		schedule()
	else
		warn(Config.LogPrefix, "leaderboard: the server has not published ReplicatedStorage." .. L.Folder)
	end
end)

-- The screen: looked for slowly until it exists, and again if it leaves (a streamed-out model).
task.spawn(function()
	local warned = false
	while true do
		local current = drawn
		if current and not current.gui:IsDescendantOf(workspace) then
			current.gui:Destroy()
			drawn = nil
			lastSignature = ""
		end
		if not drawn then
			local screen = findScreen()
			if screen then
				drawn = build(screen)
				warned = false
				print(Config.LogPrefix, "leaderboard: screen found, drawing the board")
				schedule()
			elseif not warned then
				warned = true
				warn(
					Config.LogPrefix,
					"leaderboard: waiting for workspace.Map." .. M.Model .. "." .. M.BoardModel .. "." .. M.ScreenName
				)
			end
		end
		task.wait(L.ScreenLookSeconds)
	end
end)
