--!strict
-- The loading screen. ReplicatedFirst runs it before anything else replicates: the owner's meadow, the navy slime
-- bouncing (tap it), a bar tied to the real steps and a tip every few seconds. It stays until the player's farm, the
-- ground around the character and the first screen's pictures are in and the frames have settled, so the start's
-- hitches happen behind it (the owner, 2026-11-12: "less lag when the game starts, and a loading screen").
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local L = require(script.Parent:WaitForChild("LoadingConfig"))

local player = Players.LocalPlayer
local font = Font.fromName(L.Font)

local gui = Instance.new("ScreenGui")
gui.Name = "GooLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = L.DisplayOrder
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local backdrop = Instance.new("ImageLabel")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = L.Shade
backdrop.BorderSizePixel = 0
backdrop.Image = L.Backdrop
backdrop.ScaleType = Enum.ScaleType.Crop
backdrop.Active = true -- (taps on the screen do not reach the world behind it)
backdrop.Parent = gui

local function text(name: string, height: number, y: number, words: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, y)
	label.Size = UDim2.fromScale(0.9, height)
	label.BackgroundTransparency = 1
	label.FontFace = font
	label.TextScaled = true
	label.TextColor3 = L.Cream
	label.Text = words
	local stroke = Instance.new("UIStroke")
	stroke.Color = L.Shade
	stroke.Transparency = 0.35
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = backdrop
	return label
end

local title = text("Title", L.TitleHeight, 0.24, L.Title)
title.FontFace = Font.new(font.Family, Enum.FontWeight.Bold)
local titleStroke = title:FindFirstChildOfClass("UIStroke") :: UIStroke
titleStroke.Thickness = 3

-- the slime: a square box as tall as SlimeHeight; the picture inside it stretches and hops from the box's floor
local box = Instance.new("Frame")
box.Name = "SlimeBox"
box.AnchorPoint = Vector2.new(0.5, 1)
box.Position = UDim2.fromScale(0.5, 0.62)
box.Size = UDim2.fromScale(1, L.SlimeHeight)
box.SizeConstraint = Enum.SizeConstraint.RelativeYY
box.BackgroundTransparency = 1
box.Parent = backdrop
local slime = Instance.new("ImageButton")
slime.Name = "Slime"
slime.AnchorPoint = Vector2.new(0.5, 1)
slime.BackgroundTransparency = 1
slime.Image = L.Slime
slime.ScaleType = Enum.ScaleType.Fit
slime.AutoButtonColor = false
slime.Parent = box
-- (beside the slime, so its big hop never covers the count)
local boops = text("Boops", L.StatusHeight, 0.53, "")
boops.Position = UDim2.fromScale(0.5 + L.BoopBeside, 0.53)
boops.Size = UDim2.fromScale(0.2, L.StatusHeight)
boops.TextXAlignment = Enum.TextXAlignment.Left
boops.Visible = false

local barBack = Instance.new("Frame")
barBack.Name = "Bar"
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.69)
barBack.Size = UDim2.fromScale(L.BarWidth, L.BarHeight)
barBack.BackgroundColor3 = L.BarBack
barBack.BackgroundTransparency = L.BarBackTransparency
barBack.Parent = backdrop
local barMax = Instance.new("UISizeConstraint")
barMax.MaxSize = Vector2.new(L.BarMaxPixels, math.huge)
barMax.Parent = barBack
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local barStroke = Instance.new("UIStroke")
barStroke.Color = L.Cream
barStroke.Transparency = 0.3
barStroke.Thickness = 2
barStroke.Parent = barBack
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BorderSizePixel = 0
fill.Parent = barBack
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(L.BarFrom, L.BarTo)
gradient.Parent = fill

local status = text("Status", L.StatusHeight, 0.76, L.Steps[1].text)
local tip = text("Tip", L.TipHeight, 0.93, L.Tips[math.random(#L.Tips)])
tip.FontFace = Font.new(font.Family, Enum.FontWeight.Regular, Enum.FontStyle.Italic)

local skip = Instance.new("TextButton")
skip.Name = "Skip"
skip.AnchorPoint = Vector2.new(1, 1)
skip.Position = UDim2.new(1, -16, 1, -16)
skip.Size = UDim2.fromScale(0.12, 0.07)
skip.BackgroundColor3 = L.BarTo
skip.FontFace = Font.new(font.Family, Enum.FontWeight.Bold)
skip.TextScaled = true
skip.TextColor3 = L.Cream
skip.Text = L.SkipText
skip.Visible = false
skip.Parent = backdrop
Instance.new("UICorner", skip).CornerRadius = UDim.new(0.3, 0)

gui.Parent = player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- The bounce, keyed like the original's gooLoadBounce; a tap adds one big hop.
local started = os.clock()
local boopAt, boopCount = -math.huge, 0
local function ease(a: number, b: number, k: number): number
	return a + (b - a) * (0.5 - 0.5 * math.cos(math.pi * k))
end
local function pose(now: number): (number, number, number)
	local since = now - boopAt
	if since < L.BoopSeconds then
		local k = since / L.BoopSeconds
		local stretch = math.sin(math.pi * k)
		return L.BoopUp * stretch, 1 - 0.1 * stretch, 1 + 0.1 * stretch
	end
	local t = ((now - started) % L.BounceSeconds) / L.BounceSeconds
	if t < 0.3 then
		local k = t / 0.3
		return ease(0, L.BounceUp, k), ease(1, 0.94, k), ease(1, 1.06, k)
	elseif t < 0.6 then
		local k = (t - 0.3) / 0.3
		return ease(L.BounceUp, 0, k), ease(0.94, 1.06, k), ease(1.06, 0.94, k)
	end
	local k = (t - 0.6) / 0.4
	return 0, ease(1.06, 1, k), ease(0.94, 1, k)
end
local bounce = RunService.RenderStepped:Connect(function()
	local up, sx, sy = pose(os.clock())
	slime.Size = UDim2.fromScale(sx, sy)
	slime.Position = UDim2.fromScale(0.5, 1 - up)
end)
slime.Activated:Connect(function()
	if os.clock() - boopAt < L.BoopSeconds * 0.5 then
		return
	end
	boopAt = os.clock()
	boopCount += 1
	boops.Visible = true
	boops.Text = string.format(L.BoopText, boopCount)
end)

local tips = task.spawn(function()
	while true do
		task.wait(L.TipSeconds)
		tip.Text = L.Tips[math.random(#L.Tips)]
	end
end)

local skipped = false
skip.Activated:Connect(function()
	skipped = true
end)
task.delay(L.SkipSeconds, function()
	skip.Visible = gui.Parent ~= nil
end)

local function setBar(share: number)
	TweenService:Create(fill, TweenInfo.new(L.BarEase), { Size = UDim2.fromScale(math.clamp(share, 0, 1), 1) }):Play()
end

-- Waits until `done` says yes, the time is up or the player pressed Play.
local function waitFor(seconds: number, done: () -> boolean)
	local until_ = os.clock() + seconds
	while not skipped and os.clock() < until_ and not done() do
		task.wait(0.1)
	end
end

local times = {} -- seconds each step took, for the log
local stepAt = os.clock()
local function step(index: number)
	if index > 1 then
		table.insert(times, string.format("%.1f", os.clock() - stepAt))
	end
	stepAt = os.clock()
	status.Text = L.Steps[index].text
end

-- 1. the game itself
step(1)
waitFor(math.huge, function()
	return game:IsLoaded()
end)
setBar(L.Steps[1].bar)

-- 2. the player's farm: the server makes workspace.Villages.<UserId> once the save has loaded
step(2)
local id = tostring(player.UserId)
waitFor(L.FarmSeconds, function()
	local villages = workspace:FindFirstChild("Villages")
	return villages ~= nil and villages:FindFirstChild(id) ~= nil
end)
setBar(L.Steps[2].bar)

-- 3. the character, and the world streamed in around it
step(3)
waitFor(L.CharacterSeconds, function()
	local character = player.Character
	return character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil
end)
local character = player.Character
local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
if not skipped and root and root:IsA("BasePart") and workspace.StreamingEnabled then
	local done = false
	task.spawn(function()
		pcall(function()
			player:RequestStreamAroundAsync(root.Position, L.StreamSeconds)
		end)
		done = true
	end)
	waitFor(L.StreamSeconds, function()
		return done
	end)
end
setBar(L.Steps[3].bar)

-- 4. the pictures of the first screen: every icon the game names, and the HUD as it stands
step(4)
local pictures: { any } = {}
local shared = ReplicatedStorage:WaitForChild("Shared", L.PictureSeconds)
local configModule = shared and shared:FindFirstChild("Config")
if configModule and configModule:IsA("ModuleScript") then
	local ok, Config = pcall(require, configModule)
	if ok and type(Config) == "table" and type(Config.Ui) == "table" and type(Config.Ui.Icons) == "table" then
		local seen = {}
		for _, icon in Config.Ui.Icons do
			if type(icon) == "number" and icon > 0 and not seen[icon] then
				seen[icon] = true
				table.insert(pictures, "rbxassetid://" .. tostring(icon))
			end
		end
	end
end
local hud = player.PlayerGui:FindFirstChild("GooVillageUI")
if hud then
	table.insert(pictures, hud)
end
local loaded, total = 0, #pictures
local before = L.Steps[3].bar
local share = L.Steps[4].bar - before
status.Text = string.format(L.Steps[4].text, 0, total)
local picturesDone = total == 0
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync(pictures, function()
			loaded = math.min(loaded + 1, total)
			status.Text = string.format(L.Steps[4].text, loaded, total)
			setBar(before + share * loaded / math.max(1, total))
		end)
	end)
	picturesDone = true
end)
waitFor(L.PictureSeconds, function()
	return picturesDone
end)
setBar(L.Steps[4].bar)

-- 5. the frames settle: the other scripts have started behind the screen; wait until they stop hitching
step(5)
local steady = 0
local frames = RunService.RenderStepped:Connect(function(dt: number)
	steady = if dt < 1 / L.SteadyFps then steady + 1 else 0
end)
waitFor(L.SettleSeconds, function()
	return steady >= L.SteadyFrames
end)
frames:Disconnect()
setBar(L.Steps[5].bar)

status.Text = L.Ready
table.insert(times, string.format("%.1f", os.clock() - stepAt))
print(
	L.Log,
	string.format(
		"loaded in %.1f s (steps %s; pictures %d/%d)",
		os.clock() - started,
		table.concat(times, " "),
		loaded,
		total
	)
)
task.wait(L.ReadyHold)

-- fade everything out, then go
local fade = TweenInfo.new(L.FadeSeconds)
for _, d in gui:GetDescendants() do
	if d:IsA("ImageLabel") or d:IsA("ImageButton") then
		TweenService:Create(d, fade, { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
	elseif d:IsA("TextLabel") or d:IsA("TextButton") then
		TweenService:Create(d, fade, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
	elseif d:IsA("Frame") then
		TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
	elseif d:IsA("UIStroke") then
		TweenService:Create(d, fade, { Transparency = 1 }):Play()
	end
end
backdrop.Active = false
task.wait(L.FadeSeconds)
bounce:Disconnect()
task.cancel(tips)
gui:Destroy()
