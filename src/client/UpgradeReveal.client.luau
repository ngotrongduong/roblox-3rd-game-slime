--!strict
-- Short local-only reveal of the ACTUAL changed stage pieces, plus a readable celebration
-- over the upgraded area. Never tween server-owned collision/geometry or saved levels.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Fx = Config.UpgradeFx
local player = Players.LocalPlayer
local startedAt = workspace:GetServerTimeNow()
local seen: { [Instance]: boolean } = {}

local NAMES: { [string]: string } = {
	fishing = "FISHING POND",
	garden = "GARDEN",
	pantry = "STOREHOUSE",
	kitchen = "KITCHEN",
	breeding = "BREEDING PEN",
	training = "TRAINING GROUND",
	village = "VILLAGE",
}

local function rgb(values: { number }): Color3
	return Color3.fromRGB(values[1], values[2], values[3])
end

local function flash(stage: Model, position: Vector3, area: string, level: number)
	local anchor = Instance.new("Part")
	anchor.Name = "UpgradeCelebration"
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(position)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Anchored = true
	anchor.Parent = workspace
	Debris:AddItem(anchor, Fx.FxLifetimeSeconds)

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(rgb(Fx.Gold), rgb(Fx.Cream))
	sparkle.LightEmission = 1
	sparkle.Rate = 0
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, Fx.SparkleSize),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Lifetime = NumberRange.new(Fx.SparkleLifetimeMin, Fx.SparkleLifetimeMax)
	sparkle.Speed = NumberRange.new(Fx.SparkleSpeedMin, Fx.SparkleSpeedMax)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Acceleration = Vector3.new(0, Fx.SparkleAccelerationY, 0)
	sparkle.Parent = anchor
	sparkle:Emit(Fx.SparkleCount)
	task.delay(Fx.SparkleSecondDelay, function()
		if sparkle.Parent then
			sparkle:Emit(Fx.SparkleSecondCount)
		end
	end)

	local highlight = Instance.new("Highlight")
	highlight.Name = "UpgradeOutline"
	highlight.Adornee = stage
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = rgb(Fx.Gold)
	highlight.FillTransparency = 0.75
	highlight.OutlineColor = rgb(Fx.Cream)
	highlight.OutlineTransparency = 0.1
	highlight.Parent = anchor
	TweenService:Create(
		highlight,
		TweenInfo.new(Fx.OutlineSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FillTransparency = 1, OutlineTransparency = 1 }
	):Play()

	local gui = Instance.new("BillboardGui")
	gui.Name = "UpgradeTitle"
	gui.Adornee = anchor
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(Fx.MessageWidthPixels, Fx.MessageHeightPixels)
	gui.StudsOffsetWorldSpace = Vector3.new(0, Fx.MessageHeightStuds, 0)
	gui.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Area"
	title.Size = UDim2.fromScale(1, 0.58)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = rgb(Fx.Cream)
	title.TextStrokeColor3 = rgb(Fx.Shadow)
	title.TextStrokeTransparency = 0
	title.Text = NAMES[area] or string.upper(area)
	title.Parent = gui

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Level"
	subtitle.Position = UDim2.fromScale(0, 0.55)
	subtitle.Size = UDim2.fromScale(1, 0.4)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.FredokaOne
	subtitle.TextScaled = true
	subtitle.TextColor3 = rgb(Fx.Gold)
	subtitle.TextStrokeColor3 = rgb(Fx.Shadow)
	subtitle.TextStrokeTransparency = 0
	subtitle.Text = "LEVEL " .. tostring(level) .. " UNLOCKED!"
	subtitle.Parent = gui

	TweenService:Create(
		gui,
		TweenInfo.new(Fx.MessageSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = Vector3.new(0, Fx.MessageHeightStuds + Fx.MessageRiseStuds, 0) }
	):Play()
	for _, label in { title, subtitle } do
		TweenService:Create(
			label,
			TweenInfo.new(Fx.MessageSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()
	end
end

local function reveal(inst: Instance)
	if seen[inst] then
		return
	end
	seen[inst] = true
	if not inst:IsA("Model") then
		return
	end
	local timestamp = inst:GetAttribute("UpgradeFxAt")
	local area = inst:GetAttribute("UpgradeFxArea")
	local level = inst:GetAttribute("UpgradeFxLevel")
	local focus = inst:GetAttribute("UpgradeFxFocus")
	if type(timestamp) ~= "number" or type(area) ~= "string" or type(level) ~= "number" then
		return
	end
	local now = workspace:GetServerTimeNow()
	if timestamp < startedAt - Fx.JoinGraceSeconds or now - timestamp > Fx.MaxEventAgeSeconds then
		return -- never replay an old saved upgrade when joining or streaming distant scenery
	end
	if typeof(focus) ~= "Vector3" then
		focus = inst:GetPivot().Position
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") and (root.Position - focus).Magnitude > Fx.ViewDistanceStuds then
		return
	end
	-- Marked pieces materialise in staggered waves; their server collision stays intact.
	-- A brief settle lets replication deliver the children after the model's tag arrives.
	task.delay(Fx.ClientSettleSeconds, function()
		if not inst.Parent then
			return
		end
		local parts: { BasePart } = {}
		for _, descendant in inst:GetDescendants() do
			if descendant:IsA("BasePart") and descendant:GetAttribute(Fx.PartAttribute) == true then
				table.insert(parts, descendant)
				descendant.LocalTransparencyModifier = 1
			end
		end
		for i, part in parts do
			local delayTime = (i - 1) / math.max(1, #parts) * Fx.RevealStaggerSeconds
			task.delay(delayTime, function()
				if part.Parent then
					TweenService:Create(
						part,
						TweenInfo.new(Fx.RevealSeconds, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
						{ LocalTransparencyModifier = 0 }
					):Play()
				end
			end)
		end
		flash(inst, focus, area, level)
	end)
end

CollectionService:GetInstanceAddedSignal(Fx.Tag):Connect(reveal)
for _, inst in CollectionService:GetTagged(Fx.Tag) do
	task.spawn(reveal, inst)
end
