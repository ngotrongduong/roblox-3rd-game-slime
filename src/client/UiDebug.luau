--!strict
-- THE OWNER'S DEBUG MENU, client side. Studio only: UiHud finds this module by name and only in Studio, the button shows
-- only for a player the server marked (attribute DebugMenu), and tools/build_publish.luau removes this file from the
-- published place (and fails if it stays). The sheet lists DebugPresets.Menu; a tap asks the server (Remotes.Debug) and shows
-- its answer as a toast. Every word is English.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DebugPresets = require(ReplicatedStorage.Shared.DebugPresets)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
-- Debug numbers (the owner's Config belongs to others, so they live here).
local ICON = "training" -- the kit icon on the round button (no wrench in the kit yet)
local SHEET_WIDTH = 560 -- the sheet's greatest width in points
local SHEET_HEIGHT = 520 -- and height
local CONFIRM_SECONDS = 3 -- a danger button asks for a second tap within this time

local UiDebug = {}

-- Asks the server to do one action of the menu and shows the answer.
local function ask(action: string, args: { [string]: any }?)
	task.spawn(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = if remotes then remotes:FindFirstChild("Debug") else nil
		if not remote or not remote:IsA("RemoteFunction") then
			UiKit.toast("The debug remote is missing")
			return
		end
		local ok, answer = pcall(function(): any
			return remote:InvokeServer({ action = action, args = args })
		end)
		if ok and type(answer) == "table" and type(answer.text) == "string" then
			UiKit.toast(answer.text)
		else
			UiKit.toast("No answer from the server")
		end
	end)
end

local function open()
	if UiKit.modalId() == "debug" then
		UiKit.closeModal()
		return
	end
	local modal = UiKit.openModal("debug", { Width = SHEET_WIDTH, Height = SHEET_HEIGHT })
	UiKit.label(modal.header, "Debug menu (Studio only)", U.TextNormal, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local list = UiKit.make("ScrollingFrame", {
		Name = "Groups",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
	}, modal.content)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	for groupIndex, group in DebugPresets.Menu do
		UiKit.label(list, group.group, U.TextSmall, "Brown", {
			Name = "Title_" .. group.group,
			LayoutOrder = groupIndex * 2 - 1,
			Size = UDim2.new(1, 0, 0, U.TextNormal + 4),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local row = UiKit.make("Frame", {
			Name = "Row_" .. group.group,
			BackgroundTransparency = 1,
			LayoutOrder = groupIndex * 2,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, list)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, U.Gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)
		for index, item in group.items do
			local armedAt = 0
			local button: TextButton
			button = UiKit.button(row, {
				Name = item.id,
				Text = item.text,
				Style = if item.danger then "danger" else "secondary",
				Size = UDim2.fromOffset(math.max(U.Touch * 2, #item.text * 10 + 28), U.Touch),
				LayoutOrder = index,
				OnClick = function()
					if item.danger then
						-- (a danger button wants a second tap: one slip cannot throw the farm away)
						local now = os.clock()
						local label = button:FindFirstChild("Label", true)
						if now - armedAt > CONFIRM_SECONDS then
							armedAt = now
							if label and label:IsA("TextLabel") then
								label.Text = "Tap again"
								task.delay(CONFIRM_SECONDS, function()
									if label.Parent then
										label.Text = item.text
									end
								end)
							end
							return
						end
						armedAt = 0
						if label and label:IsA("TextLabel") then
							label.Text = item.text
						end
					end
					ask(item.id, item.args)
				end,
			})
		end
	end
end

-- Adds the round button to the HUD's edge column. Does nothing outside Studio.
function UiDebug.attach(group: Instance)
	if not RunService:IsStudio() then
		return
	end
	local player = Players.LocalPlayer
	local button = UiKit.roundButton(group, ICON, U.TravelButton, open, { Name = "DebugMenu", LayoutOrder = 0 })
	local function show()
		button.Visible = player:GetAttribute("DebugMenu") == true
	end
	show()
	player:GetAttributeChangedSignal("DebugMenu"):Connect(show)
end

return UiDebug
