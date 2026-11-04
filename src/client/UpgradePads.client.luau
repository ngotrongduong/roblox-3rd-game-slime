--!strict
-- The price over each upgrade pad (src/server/UpgradePads.luau): "$cost" in green when this player has enough
-- coins, red when not, grey MAX at the top level, and under it what the upgrade does. Every client colours its own
-- view; the pad only carries AreaId, Level, MaxLevel and Cost attributes, and the coins are read from
-- workspace.Villages.<UserId>.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local TAG = "UpgradePad"
local GREEN = Color3.fromRGB(96, 226, 112)
local RED = Color3.fromRGB(244, 84, 72)
local GREY = Color3.fromRGB(200, 200, 200)

local player = Players.LocalPlayer
local coins = 0
-- the plot this player holds (0 until the server has handed it out): only the pads of that plot show a price
local ownPlot = 0
local labels: { [Instance]: () -> () } = {}

local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function draw(pad: BasePart): () -> ()
	local gui = Instance.new("BillboardGui")
	gui.Name = "PadPrice"
	-- (it hangs from the pad's own anchor point, 4.4 studs up: clear of the signs and lamps beside a path)
	local anchor = if pad.Parent then pad.Parent:WaitForChild("PriceAnchor", 3) else nil
	gui.Adornee = if anchor and anchor:IsA("BasePart") then anchor else pad
	gui.Size = UDim2.fromOffset(220, 118)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Parent = pad
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local price = Instance.new("TextLabel")
	price.BackgroundTransparency = 1
	price.Size = UDim2.fromScale(1, 0.48)
	price.Font = Enum.Font.FredokaOne
	price.TextScaled = true
	price.TextStrokeTransparency = 0
	price.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
	price.Parent = gui
	local level = Instance.new("TextLabel")
	level.BackgroundTransparency = 1
	level.Position = UDim2.fromScale(0, 0.48)
	level.Size = UDim2.fromScale(1, 0.23)
	level.Font = Enum.Font.FredokaOne
	level.TextScaled = true
	level.TextColor3 = Color3.fromRGB(255, 244, 214)
	level.TextStrokeTransparency = 0.2
	level.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
	level.Parent = gui
	-- what the upgrade does (Config.Pads.Gives), so a player knows why to buy it
	local gives = Instance.new("TextLabel")
	gives.BackgroundTransparency = 1
	gives.Position = UDim2.fromScale(0, 0.73)
	gives.Size = UDim2.fromScale(1, 0.27)
	gives.Font = Enum.Font.FredokaOne
	gives.TextScaled = true
	gives.TextColor3 = Color3.fromRGB(255, 226, 150)
	gives.TextStrokeTransparency = 0.2
	gives.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
	local areaId = pad:GetAttribute("AreaId")
	gives.Text = if type(areaId) == "string" then (Config.Pads.Gives :: any)[areaId] or "" else ""
	gives.Parent = gui

	local function refresh()
		local rawCost, rawLevel, rawMax =
			pad:GetAttribute("Cost"), pad:GetAttribute("Level"), pad:GetAttribute("MaxLevel")
		local cost: number = if type(rawCost) == "number" then rawCost else 0
		local lv: number = if type(rawLevel) == "number" then rawLevel else 1
		local max: number = if type(rawMax) == "number" then rawMax else Config.Village.MaxLevel
		scale.Scale = math.clamp(workspace.CurrentCamera.ViewportSize.Y / 900, 0.7, 1.3)
		gui.Enabled = pad:GetAttribute("Plot") == ownPlot
		if lv >= max then
			price.Text = "MAX"
			price.TextColor3 = GREY
			level.Text = "LEVEL " .. lv
		else
			price.Text = "$" .. money(cost)
			price.TextColor3 = if coins >= cost then GREEN else RED
			level.Text = "LEVEL " .. lv .. " > " .. (lv + 1)
		end
	end
	pad:GetAttributeChangedSignal("Cost"):Connect(refresh)
	pad:GetAttributeChangedSignal("Level"):Connect(refresh)
	refresh()
	return refresh
end

local function add(inst: Instance)
	if inst:IsA("BasePart") and not labels[inst] then
		labels[inst] = function() end -- (drawing may wait for the anchor to stream in)
		labels[inst] = draw(inst)
		inst.Destroying:Once(function()
			labels[inst] = nil
		end)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
	task.spawn(add, inst)
end)
for _, inst in CollectionService:GetTagged(TAG) do
	task.spawn(add, inst)
end

-- the coins of this player's village
task.spawn(function()
	local villages = workspace:WaitForChild("Villages")
	local root = villages:WaitForChild(tostring(player.UserId))
	local function read()
		local value = root:GetAttribute("Coins")
		coins = if type(value) == "number" then value else 0
		local plot = root:GetAttribute("Plot")
		ownPlot = if type(plot) == "number" then plot else 0
		for _, refresh in labels do
			refresh()
		end
	end
	root:GetAttributeChangedSignal("Coins"):Connect(read)
	root:GetAttributeChangedSignal("Plot"):Connect(read)
	read()
end)
