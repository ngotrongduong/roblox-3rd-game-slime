--!strict
-- The work positions in the world: a small marker over every OPEN position (a plus when empty, the worker's portrait
-- when filled) and a prompt (F) for that one position. Pure drawing: the server decides who may work where.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui

export type Context = {
	own: () -> Folder?,
	find: (area: string, slot: number) -> Instance?,
	open: (area: string, slot: number) -> (),
	title: (area: string) -> string,
}

type Spot = {
	marker: Instance,
	gui: BillboardGui,
	body: Frame,
	prompt: ProximityPrompt,
	shown: string,
}

local UiSpots = {}
local ctx: Context? = nil
local spots: { [string]: Spot } = {}
local overrides: { [string]: { id: string, at: number } } = {}

local function parse(value: any): { [string]: any }
	if type(value) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(value)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

function UiSpots.start(context: Context)
	ctx = context
end

-- The worker to show: the server's, unless the player's own pick is still on its way.
local function workerOf(area: string, slot: number, saved: { [string]: any }): string
	local key = area .. slot
	local real: string = if type(saved.worker) == "string" then saved.worker else ""
	local pending = overrides[key]
	if pending then
		if pending.id == real or os.clock() - pending.at > U.PendingSeconds then
			overrides[key] = nil
		else
			return pending.id
		end
	end
	return real
end

-- Shows the player's pick at once ("" = emptied); the server's answer replaces it.
function UiSpots.override(area: string, slot: number, id: string)
	overrides[area .. slot] = { id = id, at = os.clock() }
	UiSpots.refresh()
end

function UiSpots.clearOverride(area: string, slot: number)
	overrides[area .. slot] = nil
	UiSpots.refresh()
end

-- Slimes picked a moment ago whose job the server has not published yet.
function UiSpots.claimed(): { [string]: boolean }
	local out: { [string]: boolean } = {}
	for _, item in overrides do
		if item.id ~= "" and os.clock() - item.at <= U.PendingSeconds then
			out[item.id] = true
		end
	end
	return out
end

function UiSpots.workerAt(area: string, slot: number): string
	local context = ctx
	local own = if context then context.own() else nil
	local work = if own then parse(own:GetAttribute("Work")) else {}
	local stations: { any } = work[area] or {}
	return workerOf(area, slot, stations[slot] or {})
end

local function buildBody(spot: Spot, id: string)
	-- A filled position shows nothing: the slime working there is the sign. Only its prompt stays.
	spot.gui.Enabled = id == ""
	UiKit.clear(spot.body)
	if id == "" then
		local iconId = (U.Icons :: any).plus
		if type(iconId) == "number" and iconId > 0 then
			UiKit.make("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://" .. tostring(iconId),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
			}, spot.body)
		else
			UiKit.make("TextLabel", {
				BackgroundTransparency = 1,
				Text = "+",
				TextScaled = true,
				Font = (Enum.Font :: any)[U.Font],
				TextColor3 = UiKit.colour("Gold"),
				Size = UDim2.fromScale(1, 1),
			}, spot.body)
		end
	end
end

local function create(area: string, slot: number, marker: Instance): Spot
	local context = ctx :: Context
	local gui = UiKit.make("BillboardGui", {
		Name = "WorkSpotMarker",
		Adornee = marker,
		Size = UDim2.fromScale(U.SpotSize, U.SpotSize),
		StudsOffset = Vector3.new(0, U.SpotLift, 0),
		MaxDistance = U.SpotDistance,
		LightInfluence = 0,
		AlwaysOnTop = false,
		Active = false,
	}, marker)
	local fill = UiKit.make("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour("Parchment"),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, gui)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	UiKit.make("UIStroke", { Color = UiKit.colour("Wood"), Thickness = 2 }, fill)
	local body = UiKit.make("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, fill)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, body)
	local prompt = UiKit.make("ProximityPrompt", {
		Name = "SpotPrompt",
		ActionText = "Pick",
		ObjectText = context.title(area) .. " " .. tostring(slot),
		KeyboardKeyCode = Enum.KeyCode.F,
		HoldDuration = 0,
		MaxActivationDistance = U.SpotPromptDistance,
		RequiresLineOfSight = false,
	}, marker)
	prompt.Triggered:Connect(function()
		context.open(area, slot)
	end)
	return { marker = marker, gui = gui, body = body, prompt = prompt, shown = "?" }
end

function UiSpots.refresh()
	local context = ctx
	local own = if context then context.own() else nil
	if not context or not own then
		return
	end
	local work = parse(own:GetAttribute("Work"))
	for _, area in Config.Work.Areas do
		local stations: { any } = work[area] or {}
		for slot, saved in stations do
			local key = area .. slot
			local spot: Spot? = spots[key]
			if spot and not spot.marker.Parent then
				spots[key] = nil
				spot = nil
			end
			if not spot then
				local marker = context.find(area, slot)
				if marker then
					spot = create(area, slot, marker)
					spots[key] = spot
				end
			end
			if spot then
				local id = workerOf(area, slot, saved)
				if spot.shown ~= id then
					spot.shown = id
					buildBody(spot, id)
					spot.prompt.ActionText = if id ~= "" then "Change" else "Assign"
				end
			end
		end
	end
end

function UiSpots.clear()
	for _, spot in spots do
		spot.gui:Destroy()
		spot.prompt:Destroy()
	end
	table.clear(spots)
	table.clear(overrides)
end

return UiSpots
