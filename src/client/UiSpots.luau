--!strict
-- The work positions in the world: a small marker over every OPEN position (a plus when empty, the worker's portrait
-- when filled) and a prompt (F) for that one position. Pure drawing: the server decides who may work where.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiFood = require(script.Parent.UiFood)
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
	-- what is drawn now: the worker and the ingredients the cook lacks
	shown: string,
	-- the card of the pictures of the ingredients a waiting cook lacks (kitchen only)
	card: Folder?,
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

-- Over a cook that waits float the 3D models of the ingredients it lacks, each crossed out; nothing when it has all it
-- needs. Real models, because a ViewportFrame draws nothing inside a world BillboardGui (seen in a play test).
local function setCard(spot: Spot, lacking: { string })
	if spot.card then
		spot.card:Destroy()
		spot.card = nil
	end
	if #lacking == 0 then
		return
	end
	local camera = workspace.CurrentCamera
	local scale = if camera then math.clamp(camera.ViewportSize.Y / U.ScaleBaseHeight, 1, U.ScaleMax) else 1
	local marker = spot.marker
	local at = if marker:IsA("BasePart")
		then marker.Position
		elseif marker:IsA("Attachment") then marker.WorldPosition
		elseif marker:IsA("Model") then marker:GetPivot().Position
		else Vector3.zero
	local folder = Instance.new("Folder")
	folder.Name = "MissingCard"
	local step = U.MissingStuds + U.MissingGap
	for index, id in lacking do
		local source = UiFood.model(id)
		if not source then
			continue
		end
		local copy = source:Clone()
		local holder: Model
		if copy:IsA("Model") then
			holder = copy
		else
			holder = Instance.new("Model")
			copy.Parent = holder
		end
		local first: BasePart? = nil
		for _, part in holder:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.CastShadow = false
				first = first or part
			end
		end
		local extents = holder:GetExtentsSize()
		holder:ScaleTo(holder:GetScale() * U.MissingStuds / math.max(extents.X, extents.Y, extents.Z))
		local offset = (index - (#lacking + 1) / 2) * step
		holder:PivotTo(CFrame.new(at + Vector3.new(offset, U.MissingLift, 0)))
		holder.Parent = folder
		if first then
			local cross = UiKit.make("BillboardGui", {
				Name = "Cross",
				Adornee = first,
				Size = UDim2.fromOffset(U.MissingCross * scale, U.MissingCross * scale),
				-- just above the model: an AlwaysOnTop billboard did not draw here in a play test
				StudsOffset = Vector3.new(0, U.MissingStuds / 2, 0),
				MaxDistance = U.SpotDistance,
				LightInfluence = 0,
				AlwaysOnTop = false,
				Active = false,
			}, holder)
			UiKit.icon(cross, "cross", U.MissingCross * scale)
		end
	end
	folder.Parent = marker
	spot.card = folder
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
	local have = UiFood.have(own)
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
				-- a cook that cannot start: the ingredients of its recipe that neither the counter nor the storehouse has
				local lacking: { string } = {}
				if area == "kitchen" and id ~= "" then
					local recipe = if type(saved.recipe) == "string" and saved.recipe ~= ""
						then saved.recipe
						else Config.Food.DefaultRecipe
					lacking = UiFood.missing(recipe, have)
				end
				local drawn = id .. "|" .. table.concat(lacking, ",")
				if spot.shown ~= drawn then
					spot.shown = drawn
					buildBody(spot, id)
					setCard(spot, lacking)
					spot.prompt.ActionText = if id ~= "" then "Change" else "Assign"
				end
			end
		end
	end
end

function UiSpots.clear()
	for _, spot in spots do
		if spot.card then
			spot.card:Destroy()
		end
		spot.gui:Destroy()
		spot.prompt:Destroy()
	end
	table.clear(spots)
	table.clear(overrides)
end

return UiSpots
