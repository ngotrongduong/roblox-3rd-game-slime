--!strict
-- Small, object-opened village controls. Server responses, not client guesses, decide what changes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeLook = require(script.Parent.SlimeLook)

local C = Config.VillageClient
local Icons = Config.Ui.Icons
local player = Players.LocalPlayer
local VillageUI = {}
local hud: ScrollingFrame? = nil
local sheet: Frame? = nil
local toast: TextLabel? = nil
local own: Folder? = nil
local prompts: { ProximityPrompt } = {}
local activePoint: Vector3? = nil
local busy = false
local remembered: { [string]: { [number]: { worker: string?, reserve: string? } } } = {}
local pairs: { [number]: { a: string?, b: string? } } = {}
local allowed: { [string]: boolean } = {}
local pickedFirst: string? = nil
local errorsLogged: { [string]: boolean } = {}

local function text(parent: Instance, label: string, size: UDim2, fontSize: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Size = size
	item.BackgroundTransparency = 1
	item.Text = label
	item.TextColor3 = Color3.fromHex(C.Brown)
	item.TextSize = fontSize
	item.TextWrapped = true
	item.Font = Enum.Font.GothamBold
	item.Parent = parent
	return item
end

local function rounded(instance: GuiObject, colour: string)
	instance.BackgroundColor3 = Color3.fromHex(colour)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, C.UiPadding)
	corner.Parent = instance
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromHex(C.Brown)
	border.Thickness = 1
	border.Parent = instance
end

local function button(parent: Instance, label: string, onClick: () -> (), width: number?): TextButton
	local item = Instance.new("TextButton")
	item.Size = UDim2.fromOffset(width or C.UiButtonSize, C.UiButtonSize)
	item.Text = label
	item.Font = Enum.Font.GothamBold
	item.TextScaled = true
	item.TextColor3 = Color3.fromHex(C.Brown)
	item.AutoButtonColor = true
	rounded(item, C.Cream)
	item.Parent = parent
	item.MouseButton1Click:Connect(onClick)
	return item
end

local function icon(parent: Instance, name: string, size: number): GuiObject
	local id = (Icons :: any)[name]
	if type(id) == "number" and id > 0 then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = "rbxassetid://" .. tostring(id)
		image.Size = UDim2.fromOffset(size, size)
		image.Parent = parent
		return image
	end
	if not errorsLogged[name] then
		errorsLogged[name] = true
		warn(Config.LogPrefix, "missing Config.Ui.Icons." .. name .. " (0 placeholder)")
	end
	-- A conspicuous placeholder is temporary, never shipped as a silent final icon.
	local placeholder = text(parent, "?", UDim2.fromOffset(size, size), size)
	placeholder.BackgroundTransparency = 0
	placeholder.BackgroundColor3 = Color3.fromHex(C.Card)
	return placeholder
end

local function list(parent: Instance, horizontal: boolean, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = parent
	return layout
end

local function row(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -C.UiPadding, 0, C.UiRowHeight)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	list(frame, true, C.UiPadding / 2)
	return frame
end

local function say(message: string)
	if not toast then
		return
	end
	toast.Text = message
	toast.Visible = true
	local current = toast
	task.delay(C.ToastSeconds, function()
		if current == toast and current and current.Text == message then
			current.Visible = false
		end
	end)
end

local reasons: { [string]: string } = {
	NOT_READY = "Village is loading.",
	RATE_LIMIT = "Too many requests.",
	BAD_REQUEST = "Try again.",
	INVALID_ARGUMENT = "Not available.",
	MISSING_SLIME = "Slime not found.",
	NOT_ASSIGNED = "Not assigned.",
	INVALID_STAT_OR_SLOT = "Choose a valid stat.",
	SERVER_ERROR = "Please try again.",
}
local function failure(reason: any): string
	if type(reason) ~= "string" then
		return "Action unavailable."
	end
	return reasons[reason] or string.gsub(reason, "_", " ")
end

local function request(data: { [string]: any }, onSuccess: () -> ())
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = if remotes then remotes:FindFirstChild("Village") else nil
	if not remote or not remote:IsA("RemoteFunction") then
		say("Village is loading.")
		return
	end
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local ok, answer = pcall(function()
			return remote:InvokeServer(data)
		end)
		busy = false
		if not ok or type(answer) ~= "table" then
			say("Please try again.")
		elseif answer.ok then
			onSuccess()
		else
			say(failure(answer.reason))
		end
	end)
end

local function ownSlimes(): { Configuration }
	local available: { Configuration } = {}
	local folder = if own then own:FindFirstChild("Slimes") else nil
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("Configuration") then
				table.insert(available, child)
			end
		end
	end
	table.sort(available, function(a, b)
		return a.Name < b.Name
	end)
	return available
end

local function labelFor(id: string?): string
	if not id then
		return "Choose"
	end
	local folder = if own then own:FindFirstChild("Slimes") else nil
	local found = if folder then folder:FindFirstChild(id) else nil
	if not found then
		return "Choose"
	end
	local value = found:GetAttribute("Name")
	return if type(value) == "string" and value ~= "" then value else id
end

local function canPick(slime: Configuration, permitWorking: boolean): boolean
	local scale = slime:GetAttribute("Scale")
	local working = slime:GetAttribute("Working")
	return type(scale) == "number"
		and scale >= 1
		and slime:GetAttribute("Ghost") ~= true
		and (permitWorking or working == nil or working == "")
end

local function portrait(parent: Instance, slime: Configuration)
	local view = Instance.new("ViewportFrame")
	view.Size = UDim2.fromOffset(C.UiButtonSize, C.UiButtonSize)
	view.BackgroundColor3 = Color3.fromHex(C.Card)
	view.LightColor = Color3.new(1, 1, 1)
	view.Ambient = Color3.new(1, 1, 1)
	view.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = SlimeLook.build({
		Colour = slime:GetAttribute("Colour"),
		Material = slime:GetAttribute("Material"),
		DualId = slime:GetAttribute("DualId"),
		SecretId = slime:GetAttribute("SecretId"),
		Scale = 1,
	})
	model:PivotTo(CFrame.Angles(0, math.pi, 0))
	model.Parent = world
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, C.BodyHeight * 0.65, C.BodyHeight * 2.5), Vector3.new(0, C.BodyHeight * 0.5, 0))
	camera.Parent = view
	view.CurrentCamera = camera
end

local function frameContent(): ScrollingFrame?
	if not sheet then
		return nil
	end
	local current = sheet:FindFirstChild("Content")
	if current then
		current:Destroy()
	end
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Content"
	scroller.Position = UDim2.fromOffset(C.UiPadding, C.UiButtonSize + C.UiPadding)
	scroller.Size = UDim2.new(1, -2 * C.UiPadding, 1, -C.UiButtonSize - 2 * C.UiPadding)
	scroller.BackgroundTransparency = 1
	scroller.ScrollBarThickness = 4
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.new()
	scroller.Parent = sheet
	list(scroller, false, C.UiPadding / 2)
	return scroller
end

local function close()
	activePoint, pickedFirst = nil, nil
	if sheet then
		sheet.Visible = false
	end
end

local renderArea: (string) -> () = function(_area) end

local function picker(area: string, choose: (string) -> (), permitWorking: boolean)
	local scroller = frameContent()
	if not scroller then
		return
	end
	local back = row(scroller)
	button(back, "Back", function()
		renderArea(area)
	end, C.UiButtonSize * 2)
	local count = 0
	for _, slime in ownSlimes() do
		if canPick(slime, permitWorking) then
			count += 1
			local cell = row(scroller)
			portrait(cell, slime)
			local name = labelFor(slime.Name)
			local chooseButton = button(cell, name .. "  Lv ?  ?/?", function()
				choose(slime.Name)
			end, C.UiWidth - C.UiButtonSize * 2 - C.UiPadding * 5)
			chooseButton.TextScaled = false
			chooseButton.TextSize = 14
		end
	end
	if count == 0 then
		text(scroller, "No free adults", UDim2.new(1, 0, 0, C.UiRowHeight), 18)
	end
	-- Level and needs are intentionally unknown: the server does not replicate them.
end

renderArea = function(area: string)
	local scroller = frameContent()
	if not scroller then
		return
	end
	if area == "breeding" then
		for index = 1, Config.Breeding.BasePlaces do
			local pair = pairs[index] or {}
			local cell = row(scroller)
			text(cell, tostring(index), UDim2.fromOffset(C.UiButtonSize / 2, C.UiButtonSize), 18)
			button(cell, labelFor(pair.a) .. " + " .. labelFor(pair.b), function()
				pickedFirst = nil
				picker(area, function(first)
					pickedFirst = first
					picker(area, function(second)
						local firstId = pickedFirst
						if not firstId or firstId == second then
							say("Choose two different slimes.")
							return
						end
						request({ action = "SetPair", index = index, a = firstId, b = second }, function()
							pairs[index] = { a = firstId, b = second }
							pickedFirst = nil
							renderArea(area)
						end)
					end, false)
				end, false)
			end, C.UiWidth - C.UiButtonSize * 3 - C.UiPadding * 5)
			button(cell, "Clear", function()
				request({ action = "SetPair", index = index }, function()
					pairs[index] = {}
					renderArea(area)
				end)
			end, C.UiButtonSize + C.UiPadding)
		end
	elseif area == "kitchen" then
		local choose = row(scroller)
		text(choose, "Cooked food", UDim2.fromOffset(C.UiWidth - C.UiPadding * 3, C.UiButtonSize), 19)
		for _, slime in ownSlimes() do
			if canPick(slime, true) then
				local cell = row(scroller)
				portrait(cell, slime)
				text(cell, labelFor(slime.Name), UDim2.fromOffset(C.UiWidth / 3, C.UiButtonSize), 15)
				local state = allowed[slime.Name]
				button(cell, if state == true then "On" else "Allow", function()
					request({ action = "SetCookedAllowed", slimeId = slime.Name, allowed = true }, function()
						allowed[slime.Name] = true
						renderArea(area)
					end)
				end, C.UiButtonSize + C.UiPadding)
				button(cell, if state == false then "Off" else "Raw", function()
					request({ action = "SetCookedAllowed", slimeId = slime.Name, allowed = false }, function()
						allowed[slime.Name] = false
						renderArea(area)
					end)
				end, C.UiButtonSize + C.UiPadding)
			end
		end
	end

	if table.find(Config.Work.Areas, area) then
		local stations = remembered[area] or {}
		for slot = 1, #Config.Work.SlotLevels + Config.Work.BaseSlots do
			local saved = stations[slot] or {}
			local cell = row(scroller)
			text(cell, tostring(slot), UDim2.fromOffset(C.UiButtonSize / 2, C.UiButtonSize), 17)
			for _, reserve in { false, true } do
				local position = if reserve then "reserve" else "worker"
				local selected = (saved :: any)[position]
				button(cell, labelFor(selected), function()
					picker(area, function(id)
						request({ action = "Assign", area = area, slot = slot, slimeId = id, asReserve = reserve }, function()
							remembered[area] = remembered[area] or {}
							remembered[area][slot] = remembered[area][slot] or {}
							(remembered[area][slot] :: any)[position] = id
							renderArea(area)
						end)
					end, false)
				end, (C.UiWidth - C.UiButtonSize * 2) / 2)
			end
			if saved.worker or saved.reserve then
				button(cell, "X", function()
					local id = saved.worker or saved.reserve
					if id then
						request({ action = "Unassign", slimeId = id }, function()
							local key = if saved.worker then "worker" else "reserve"
							(saved :: any)[key] = nil
							renderArea(area)
						end)
					end
				end)
			end
			if area == "training" then
				local stats = row(scroller)
				for _, stat in { "attack", "defence", "speed", "hp" } do
					local wrap = Instance.new("Frame")
					wrap.BackgroundTransparency = 1
					wrap.Size = UDim2.fromOffset(C.UiButtonSize + C.UiPadding, C.UiButtonSize)
					wrap.Parent = stats
					icon(wrap, stat, C.HudIconSize)
					local chooseStat = button(wrap, stat:sub(1, 3), function()
						request({ action = "SetTrainingStat", slot = slot, stat = stat }, function()
							say("Stat set.")
						end)
					end)
					chooseStat.Position = UDim2.fromOffset(C.HudIconSize, 0)
				end
			end
		end
	end
end

local function open(area: string, position: Vector3)
	if not sheet then
		return
	end
	activePoint = position
	sheet.Visible = true
	local title = sheet:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = string.upper(string.sub(area, 1, 1)) .. string.sub(area, 2)
	end
	renderArea(area)
end

local resources = { "coins", "fish", "carrot", "cabbage", "grilledFish", "veggieStew", "fishVegSoup", "slimes" }
local function parse(value: any): { [string]: any }
	if type(value) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(value)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

local function refreshHud()
	if not hud then
		return
	end
	for _, child in hud:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local store = if own then parse(own:GetAttribute("Storehouse")) else {}
	local fridge = if own then parse(own:GetAttribute("Fridge")) else {}
	for _, resource in resources do
		local amount: any = 0
		if own then
			if resource == "coins" then
				amount = own:GetAttribute("Coins")
			elseif resource == "slimes" then
				amount = tostring(own:GetAttribute("Population") or 0) .. "/" .. tostring(own:GetAttribute("Limit") or 0)
			elseif fridge[resource] then
				amount = fridge[resource]
			else
				amount = store[resource] or 0
			end
		end
		local cell = Instance.new("Frame")
		cell.Size = UDim2.fromOffset(C.UiButtonSize * 2, C.HudHeight)
		cell.BackgroundTransparency = 1
		cell.Parent = hud
		icon(cell, resource, C.HudIconSize)
		local value = text(cell, tostring(amount), UDim2.new(1, -C.HudIconSize, 1, 0), 15)
		value.Position = UDim2.fromOffset(C.HudIconSize, 0)
	end
end

local function anchor(inst: Instance): Instance?
	if inst:IsA("Attachment") or inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function positionOf(inst: Instance): Vector3?
	if inst:IsA("Attachment") then
		return inst.WorldPosition
	elseif inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

local modelNames: { [string]: string } = {
	fishing = "FishingPond", garden = "Garden", kitchen = "Kitchen",
	pantry = "Pantry", training = "Training", breeding = "Breeding",
}

local function createPrompts(root: Folder)
	local plotId = root:GetAttribute("Plot")
	if type(plotId) ~= "number" or plotId < 1 then
		return
	end
	local map = workspace:FindFirstChild("Map")
	local plot = if map then map:FindFirstChild("Plot" .. tostring(plotId)) else nil
	if not plot then
		return
	end
	for _, area in Config.Village.Areas do
		local model: Instance? = nil
		for _, child in plot:GetChildren() do
			if string.match(string.lower(child.Name), "^" .. string.lower(modelNames[area]) .. "l") then
				model = child
				break
			end
		end
		if model then
			local entrance = model:FindFirstChild("UpgradePoint", true)
				or model:FindFirstChild("Entrance", true)
				or model:FindFirstChild("Gate", true)
			local target = anchor(entrance or model)
			if target then
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "VillageManage"
				prompt.ActionText = "Manage"
				prompt.ObjectText = area
				prompt.KeyboardKeyCode = Enum.KeyCode.F
				prompt.HoldDuration = C.PromptHoldSeconds
				prompt.MaxActivationDistance = C.PromptDistance
				prompt.RequiresLineOfSight = false
				prompt.Parent = target
				prompt.Triggered:Connect(function()
					local position = positionOf(target)
					if position then
						open(area, position)
					end
				end)
				table.insert(prompts, prompt)
			end
		end
	end
end

local function bind(root: Folder?)
	for _, prompt in prompts do
		prompt:Destroy()
	end
	table.clear(prompts)
	own = root
	close()
	refreshHud()
	if not root or type(root:GetAttribute("Plot")) ~= "number" or (root:GetAttribute("Plot") :: number) < 1 then
		if hud then
			hud.Visible = false
		end
		return
	end
	if hud then
		hud.Visible = true
	end
	for _, attribute in { "Coins", "Storehouse", "Fridge", "Population", "Limit" } do
		root:GetAttributeChangedSignal(attribute):Connect(function()
			if own == root then
				refreshHud()
			end
		end)
	end
	createPrompts(root)
end

function VillageUI.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GooVillageUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	local strip = Instance.new("ScrollingFrame")
	strip.Name = "Resources"
	strip.Size = UDim2.new(1, -C.UiPadding * 2, 0, C.HudHeight)
	strip.Position = UDim2.fromOffset(C.UiPadding, C.UiPadding)
	strip.BackgroundTransparency = 1
	strip.AutomaticCanvasSize = Enum.AutomaticSize.X
	strip.ScrollBarThickness = 0
	strip.ScrollingDirection = Enum.ScrollingDirection.X
	strip.Parent = gui
	list(strip, true, C.UiPadding / 2)
	hud = strip

	local panel = Instance.new("Frame")
	panel.Name = "AreaSheet"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -C.UiPadding)
	panel.Size = UDim2.new(1, -2 * C.UiPadding, 0, C.UiHeight)
	panel.SizeConstraint = Enum.SizeConstraint.RelativeXX
	panel.ClipsDescendants = true
	panel.Visible = false
	rounded(panel, C.Parchment)
	panel.Parent = gui
	sheet = panel
	local title = text(panel, "", UDim2.new(1, -C.UiButtonSize - 2 * C.UiPadding, 0, C.UiButtonSize), 20)
	title.Name = "Title"
	title.Position = UDim2.fromOffset(C.UiPadding, 0)
	local closeButton = button(panel, "X", close)
	closeButton.Position = UDim2.new(1, -C.UiButtonSize - C.UiPadding, 0, 0)

	local message = text(gui, "", UDim2.fromOffset(C.UiWidth, C.UiButtonSize), 16)
	message.Name = "VillageToast"
	message.AnchorPoint = Vector2.new(0.5, 1)
	message.Position = UDim2.new(0.5, 0, 1, -C.UiHeight - C.UiPadding * 2)
	message.Visible = false
	rounded(message, C.Card)
	toast = message

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape then
			close()
		end
	end)
	local world = workspace:WaitForChild("Villages")
	local id = tostring(player.UserId)
	local function changed(child: Instance)
		if child.Name == id and child:IsA("Folder") then
			bind(child)
		end
	end
	local existing = world:FindFirstChild(id)
	if existing and existing:IsA("Folder") then
		bind(existing)
	end
	world.ChildAdded:Connect(changed)
	world.ChildRemoved:Connect(function(child)
		if child == own then
			bind(nil)
		end
	end)
	task.spawn(function()
		while gui.Parent do
			if activePoint then
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if root and root:IsA("BasePart") and (root.Position - activePoint).Magnitude > C.SheetWalkAwayStuds then
					close()
				end
			end
			if own and #prompts == 0 then
				createPrompts(own)
			end
			task.wait(C.FarUpdateSeconds)
		end
	end)
end

return VillageUI
