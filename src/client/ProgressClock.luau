--!strict
-- The small progress clock over a slime at work, a courting pair or an egg (owner, 2026-10-30): a cream face with the
-- owner's icon of the work and a gold ring that fills clockwise. The server publishes when the work started and
-- ends (server time); this module only draws the fraction. It grows in, pops when the work completes and shrinks
-- away, and a few clocks are pooled and reused, so nothing is built while playing beyond the first few.
--
-- The ring is the usual two-halves trick: each half of a circle outline is clipped to its side of the face and a
-- stepped gradient on its stroke is turned from 0 to 180 degrees, which sweeps the outline from 12 o'clock round.
-- (A ring picture from the owner would replace the outline; none exists yet.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)

local C = Config.VillageClient

export type Spec = {
	kind: string,
	start: number,
	finish: number,
	position: Vector3,
	size: number,
}
export type Clock = {
	part: Part,
	gui: BillboardGui,
	scale: UIScale,
	right: UIGradient,
	left: UIGradient,
	icon: ImageLabel,
	-- hidden (in the pool), in, shown, pop, out
	state: string,
	since: number,
	done: boolean,
	leaving: boolean,
	kind: string,
	size: number,
	fraction: number,
}

local ProgressClock = {}
local pool: { Clock } = {}
local folder: Folder? = nil

-- Opaque up to the half, clear after it: turning it sweeps the outline in or out.
local STEP = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local function ring(parent: Instance, side: string, colour: Color3): UIGradient
	local inset = C.ClockRingInset
	local clip = UiKit.make("Frame", {
		Name = side .. "Half",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromScale(if side == "Right" then 0.5 else 0, 0),
		Size = UDim2.fromScale(0.5, 1),
	}, parent)
	local width = (1 - 2 * inset) / 0.5
	local circle = UiKit.make("Frame", {
		Name = "Circle",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(if side == "Right" then (inset - 0.5) / 0.5 else inset / 0.5, inset),
		Size = UDim2.fromScale(width, 1 - 2 * inset),
	}, clip)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, circle)
	local stroke = UiKit.make("UIStroke", {
		Color = colour,
		Thickness = C.ClockRingPixels,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, circle)
	return UiKit.make("UIGradient", { Transparency = STEP, Rotation = if side == "Right" then 0 else 180 }, stroke)
end

local function build(): Clock
	local holder = folder
	if not holder then
		local made = Instance.new("Folder")
		made.Name = "ProgressClocks"
		made.Parent = workspace
		holder, folder = made, made
	end
	local part = UiKit.make("Part", {
		Name = "ClockMark",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
	}, holder)
	local gui = UiKit.make("BillboardGui", {
		Name = "Clock",
		Adornee = part,
		Size = UDim2.fromScale(1, 1),
		AlwaysOnTop = false,
		LightInfluence = 0,
		MaxDistance = C.ClockMaxDistance,
		Active = false,
		Enabled = false,
	}, part)
	local root = UiKit.make("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, gui)
	local scale = UiKit.make("UIScale", { Scale = 0 }, root)
	local face = UiKit.make("Frame", {
		Name = "Face",
		BackgroundColor3 = UiKit.colour("Cream"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, root)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, face)
	UiKit.make("UIStroke", { Color = UiKit.colour("Wood"), Thickness = 2 }, face)
	local track = UiKit.make("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1 - 2 * C.ClockRingInset, 1 - 2 * C.ClockRingInset),
	}, root)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
	UiKit.make("UIStroke", {
		Color = UiKit.colour("Track"),
		Thickness = C.ClockRingPixels,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, track)
	local gold = UiKit.colour("Gold")
	local right = ring(root, "Right", gold)
	local left = ring(root, "Left", gold)
	local icon = UiKit.make("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(C.ClockIconShare * 2, C.ClockIconShare * 2),
	}, root)
	return {
		part = part,
		gui = gui,
		scale = scale,
		right = right,
		left = left,
		icon = icon,
		state = "hidden",
		since = 0,
		done = false,
		leaving = false,
		kind = "",
		size = 0,
		fraction = 0,
	}
end

local function setKind(clock: Clock, kind: string)
	clock.kind = kind
	local name = (C.ClockIcons :: any)[kind]
	local id = if name then (Config.Ui.Icons :: any)[name] else nil
	clock.icon.Image = if type(id) == "number" and id > 0 then "rbxassetid://" .. tostring(id) else ""
end

local function release(clock: Clock)
	clock.state = "hidden"
	clock.gui.Enabled = false
	clock.scale.Scale = 0
	table.insert(pool, clock)
end

-- A running, finishing or leaving clock; call it every update of its owner with the current spec, or nil when
-- nothing is running. It returns the clock to keep (nil when there is none, now or any more).
function ProgressClock.update(clock: Clock?, spec: Spec?, serverNow: number): Clock?
	local t = os.clock()
	if not spec then
		if not clock then
			return nil
		end
		if clock.state == "hidden" then
			return nil
		end
		if not clock.leaving then
			clock.leaving = true
			if clock.state == "in" or clock.state == "shown" then
				clock.state = if clock.fraction >= C.ClockDoneFraction and not clock.done then "pop" else "out"
				clock.since = t
			end
		end
	else
		local current: Clock
		if clock then
			current = clock
		else
			current = table.remove(pool) or build()
			current.state, current.since, current.done, current.leaving, current.kind = "in", t, false, false, ""
			current.gui.Enabled = true
		end
		clock = current
		if current.leaving then
			current.leaving = false
			if current.state == "out" then
				current.state, current.since = "in", t
			end
		end
		if current.kind ~= spec.kind then
			setKind(current, spec.kind)
		end
		if current.size ~= spec.size then
			current.size = spec.size
			current.gui.Size = UDim2.fromScale(spec.size, spec.size)
		end
		current.part.Position = spec.position
		local fraction = math.clamp((serverNow - spec.start) / math.max(spec.finish - spec.start, 0.01), 0, 1)
		current.fraction = fraction
		local angle = fraction * 360
		current.right.Rotation = math.clamp(angle, 0, 180)
		current.left.Rotation = 180 + math.clamp(angle - 180, 0, 180)
		if fraction >= 1 and not current.done then
			current.done = true
			current.state, current.since = "pop", t
		elseif fraction < 0.9 then
			current.done = false
		end
	end
	local live: Clock = clock :: any
	local elapsed = t - live.since
	if live.state == "in" then
		local u = math.clamp(elapsed / C.ClockInSeconds, 0, 1)
		-- a little overshoot, like the owner's other pop-ins
		live.scale.Scale = 1 + 2.2 * (u - 1) ^ 3 + 1.2 * (u - 1) ^ 2
		if u >= 1 then
			live.state = "shown"
			live.scale.Scale = 1
		end
	elseif live.state == "pop" then
		local u = math.clamp(elapsed / C.ClockPopSeconds, 0, 1)
		live.scale.Scale = 1 + C.ClockPopGrow * math.sin(math.pi * u)
		if u >= 1 then
			live.scale.Scale = 1
			live.state = if live.leaving then "out" else "shown"
			live.since = t
		end
	elseif live.state == "out" then
		local u = math.clamp(elapsed / C.ClockOutSeconds, 0, 1)
		live.scale.Scale = 1 - u
		if u >= 1 then
			release(live)
			return nil
		end
	end
	return live
end

-- At once, for an owner that is removed or out of range.
function ProgressClock.drop(clock: Clock?)
	if clock and clock.state ~= "hidden" then
		release(clock)
	end
end

return ProgressClock
