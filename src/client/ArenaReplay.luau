--!strict
-- The Arena fight replayed on this client only (nobody else sees it). The server runs the fight and answers an attack with its
-- steps ({ t, events }, src/shared/ArenaFight.luau); this file stands both teams on a flat round field (the Arena's Pit, else a
-- spot in front of the player), hands the bodies to ZombieFight (ZombieFight.adopt, as DungeonFight does for the Slime Dungeon)
-- and feeds it the steps at their time (ZombieFight.feed), so the blows, dodges, healing and falls are the ones every fight
-- shows. Attackers are the ones with green bars, defenders red. A small x2 button and a Skip button sit on the right edge; one name
-- label per side hangs over its team. Everything made here is destroyed when the replay ends. No camera effects.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local FightFx = require(script.Parent.FightFx)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeLook = require(script.Parent.SlimeLook)
local UiKit = require(script.Parent.UiKit)
local ZombieFight = require(script.Parent.ZombieFight)

local R = Config.Arena.View.Replay
local V = Config.Zombies.View
local U = Config.Ui

-- One fighter: the id the events name, how it fights, its health for the bar and the look it is built from.
type Unit = {
	id: string,
	mine: boolean,
	role: string,
	maxHp: number,
	look: { [string]: any },
}
type Body = {
	unit: Unit,
	actor: SlimeActor.Slime,
	model: Model,
	node: Configuration,
}
type Session = {
	steps: { any },
	cursor: number,
	clock: number,
	speed: number,
	started: boolean,
	ended: boolean,
	skipped: boolean,
	finishAt: number,
	won: boolean,
	units: { Unit },
	bodies: { [string]: Body },
	extras: { Instance },
	connection: RBXScriptConnection?,
	onDone: (() -> ())?,
	done: boolean,
}

local ArenaReplay = {}
local current: Session? = nil
local warned: { [string]: boolean } = {}

local function safe(label: string, work: () -> ())
	local ok, err = pcall(function(): any
		work()
		return nil
	end)
	if not ok and not warned[label] then
		warned[label] = true
		warn(Config.LogPrefix, "arena replay", label, "error:", err)
	end
end

local function flat(delta: Vector3): Vector3
	return Vector3.new(delta.X, 0, delta.Z)
end

local function screenScale(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / 900, 0.7, 1.3) else 1
end

local function actorsFolder(): Instance
	return workspace:FindFirstChild("ZombieClientActors") or workspace
end

-- ===== Reading the answer =====

local function list(value: any): { any }
	return if type(value) == "table" then value else {}
end

-- The fighters of one side, in order. The server may name them (sides.<side>.fighters: { id, role, hp, maxHp }); when it does
-- not, they are the ids the events mention, in the order they first appear, with the looks given in order.
local function gather(answer: any, prefix: string, side: any, mine: boolean): { Unit }
	local looks = list(if type(side) == "table" then side.looks else nil)
	local named = list(if type(side) == "table" then side.fighters else nil)
	local role: { [string]: string } = {}
	local damage: { [string]: number } = {}
	local fallen: { [string]: boolean } = {}
	local order: { string } = {}
	local seen: { [string]: boolean } = {}
	local function note(id: any)
		if type(id) == "string" and string.sub(id, 1, 2) == prefix and not seen[id] then
			seen[id] = true
			table.insert(order, id)
		end
	end
	for _, step in list(answer.steps) do
		for _, event in list(if type(step) == "table" then step.events else nil) do
			if type(event) == "table" then
				note(event.from)
				note(event.to)
				if type(event.from) == "string" and type(event.skill) == "string" then
					role[event.from] = event.skill
				end
				local to = event.to
				if type(to) == "string" then
					local amount = if type(event.amount) == "number" then event.amount else 0
					if event.kind == "hit" then
						damage[to] = (damage[to] or 0) + amount
					elseif event.kind == "heal" then
						damage[to] = (damage[to] or 0) - amount
					elseif event.kind == "fallen" then
						fallen[to] = true
					end
				end
			end
		end
	end
	local units: { Unit } = {}
	local limit = Config.Arena.TeamSize
	local count = math.min(limit, math.max(#looks, #named, #order))
	for index = 1, count do
		local entry = named[index]
		local id: string = order[index] or (prefix .. "_" .. tostring(index))
		local roleName = role[id]
		local maxHp: number? = nil
		if type(entry) == "table" and type(entry.id) == "string" then
			id = if string.sub(entry.id, 1, 2) == prefix then entry.id else prefix .. entry.id
			roleName = if type(entry.role) == "string" then entry.role else roleName
			maxHp = if type(entry.maxHp) == "number"
				then entry.maxHp
				elseif type(entry.hp) == "number" then entry.hp
				else nil
		end
		if not maxHp then
			-- (the server did not say: the damage taken is what the bar is measured by)
			local net = math.max(damage[id] or 0, 0)
			maxHp = math.max(1, if fallen[id] then net else net * R.SurvivorShare)
		end
		local look = looks[index]
		table.insert(units, {
			id = id,
			mine = mine,
			role = roleName or "attack",
			maxHp = maxHp :: number,
			look = if type(look) == "table" then look else {},
		})
	end
	return units
end

-- ===== The field =====

local function floorY(point: Vector3, ignore: { Instance }): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(point + Vector3.new(0, R.RayUp, 0), Vector3.new(0, -(R.RayUp + R.RayDown), 0), params)
	return if hit then hit.Position.Y else point.Y
end

-- The middle of the field (at the floor's top) and the direction from it towards the player.
local function field(): (Vector3, Vector3)
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local here = if root and root:IsA("BasePart") then root.Position else Vector3.zero
	local map = workspace:FindFirstChild("Map")
	local zone = if map then map:FindFirstChild("Arena") else nil
	local pit = if zone then zone:FindFirstChild("Pit") else nil
	local centre: Vector3? = nil
	if pit and pit:IsA("BasePart") then
		centre = Vector3.new(pit.Position.X, pit.Position.Y + pit.Size.Y / 2, pit.Position.Z)
	elseif pit and pit:IsA("Attachment") then
		centre = pit.WorldPosition
	elseif pit and pit:IsA("Model") then
		centre = pit:GetPivot().Position
	end
	if centre then
		local toward = flat(here - centre)
		return centre, if toward.Magnitude > 1e-3 then toward.Unit else Vector3.zAxis
	end
	local look = if root and root:IsA("BasePart") then flat(root.CFrame.LookVector) else Vector3.zAxis
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.zAxis
	local ahead = here + look * R.FrontStuds
	local ignore: { Instance } = { actorsFolder() }
	if character then
		table.insert(ignore, character)
	end
	return Vector3.new(ahead.X, floorY(ahead, ignore), ahead.Z), -look
end

-- ===== The session =====

local function healthNode(maxHp: number): Configuration
	local node = Instance.new("Configuration")
	node:SetAttribute("MaxHp", maxHp)
	node:SetAttribute("Hp", maxHp)
	return node
end

local function moveHealth(session: Session, id: string, change: number)
	local body = session.bodies[id]
	if not body then
		return
	end
	local maxHp = body.unit.maxHp
	local hp = body.node:GetAttribute("Hp")
	body.node:SetAttribute("Hp", math.clamp((if type(hp) == "number" then hp else maxHp) + change, 0, maxHp))
end

local function feed(events: { any })
	safe("feed", function()
		ZombieFight.feed(events)
	end)
end

local function fadeOut(model: Model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			TweenService:Create(part, TweenInfo.new(R.FadeSeconds), {
				Transparency = math.max(part.Transparency, R.FadeTransparency),
			}):Play()
		end
	end
end

local function finish(session: Session, quiet: boolean)
	if session.done then
		return
	end
	session.done = true
	if current == session then
		current = nil
	end
	if session.connection then
		session.connection:Disconnect()
		session.connection = nil
	end
	for id, body in session.bodies do
		ZombieFight.release(id)
		SlimeActor.destroy(body.actor)
		body.model:Destroy()
		body.node:Destroy()
	end
	table.clear(session.bodies)
	-- (the field team 0 holds, with its bars and its round field)
	ZombieFight.endDungeon()
	for _, inst in session.extras do
		inst:Destroy()
	end
	table.clear(session.extras)
	local onDone = session.onDone
	session.onDone = nil
	if onDone and not quiet then
		safe("onDone", onDone)
	end
end

-- One name over one side, in pixels (scaled with the screen), hung on a hidden anchor over the side's middle.
local function sideLabel(session: Session, at: Vector3, text: string, mine: boolean)
	local anchor = FightFx.anchorAt(at + Vector3.new(0, R.LabelLift, 0))
	table.insert(session.extras, anchor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ArenaSide"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(R.LabelWidth, R.LabelHeight)
	gui.AlwaysOnTop = false
	gui.MaxDistance = R.LabelDistance
	gui.LightInfluence = 0
	gui.Parent = anchor
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local label = UiKit.label(gui, text, U.TextNormal, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = UiKit.colour(if mine then "Green" else "Red"),
	})
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromHex(U.KitOutline)
end

local function addBody(session: Session, unit: Unit, spot: Vector3, facing: Vector3)
	local look = unit.look
	local model = SlimeLook.build({
		Colour = look.Colour,
		Material = look.Material,
		DualId = look.DualId,
		SecretId = look.SecretId,
	})
	model.Name = "ArenaReplay_" .. unit.id
	model:PivotTo(CFrame.lookAt(spot, spot + facing))
	model.Parent = actorsFolder()
	local actor = SlimeActor.new(model, V.FighterFace)
	if not actor then
		model:Destroy()
		return
	end
	actor.body.CanCollide = false
	local node = healthNode(unit.maxHp)
	session.bodies[unit.id] = { unit = unit, actor = actor, model = model, node = node }
	ZombieFight.adopt(unit.id, {
		actor = actor,
		stand = spot,
		-- (a defender is "a foe" to the fight drawing: red bar, and it falls apart where it stands; `gone` fades what is left)
		foe = not unit.mine,
		way = unit.role,
		size = 1,
		dead = false,
		node = node,
		gone = if unit.mine
			then nil
			else function()
				fadeOut(model)
			end,
	})
	SlimeActor.kick(actor, "squash", V.PopSquash)
	SlimeActor.hop(actor, V.PopHop)
end

-- Both teams stand facing each other across the middle; the attackers on the player's side.
local function setUp(session: Session, answer: any, centre: Vector3, toPlayer: Vector3)
	ZombieFight.setArena(centre, R.FieldRadius)
	local across = Vector3.new(-toPlayer.Z, 0, toPlayer.X)
	local sides: { any } = if type(answer.sides) == "table"
		then { answer.sides.attacker, answer.sides.defender }
		else {}
	for sideIndex = 1, 2 do
		local mine = sideIndex == 1
		local units = gather(answer, if mine then "a:" else "d:", sides[sideIndex], mine)
		local sign = if mine then 1 else -1
		for index, unit in units do
			table.insert(session.units, unit)
			local x = (index - (#units + 1) / 2) * R.Spacing * sign
			local back = (R.SideGap - (index % 2) * R.Stagger) * sign
			addBody(session, unit, centre + across * x + toPlayer * back, -toPlayer * sign)
		end
		local info = sides[sideIndex]
		local name = if type(info) == "table" and type(info.name) == "string" then info.name else ""
		if name ~= "" and #units > 0 then
			sideLabel(session, centre + toPlayer * R.SideGap * sign, name, mine)
		end
	end
end

local function startEvent(session: Session): { any }
	local members: { string } = {}
	local roles: { [string]: string } = {}
	for _, unit in session.units do
		if unit.mine then
			table.insert(members, unit.id)
		end
		roles[unit.id] = unit.role
	end
	return { { kind = "start", group = "arena", members = members, roles = roles } }
end

local function endEvent(session: Session): { any }
	return { { kind = "end", winner = if session.won then "squad" else "foe" } }
end

-- A step: the bars move with its blows at once (as the Dungeon's do), then the fight draws it.
local function playStep(session: Session, step: any)
	local events = list(step.events)
	for _, event in events do
		if type(event) == "table" and type(event.to) == "string" and type(event.amount) == "number" then
			if event.kind == "hit" then
				moveHealth(session, event.to, -event.amount)
			elseif event.kind == "heal" then
				moveHealth(session, event.to, event.amount)
			end
		end
	end
	feed(events)
end

-- Skip: the rest of the fight is not played; only its falls are, so every unit that went down shows down.
local function skipRest(session: Session)
	if session.skipped or session.ended then
		return
	end
	session.skipped = true
	if not session.started then
		session.started = true
		feed(startEvent(session))
	end
	local falls: { any } = {}
	for index = session.cursor, #session.steps do
		for _, event in list(session.steps[index].events) do
			if type(event) == "table" and event.kind == "fallen" and type(event.to) == "string" then
				moveHealth(session, event.to, -math.huge)
				table.insert(falls, event)
			end
		end
	end
	session.cursor = #session.steps + 1
	if #falls > 0 then
		feed(falls)
	end
	session.ended = true
	feed(endEvent(session))
	session.finishAt = os.clock() + R.SkipHoldSeconds
end

local function tick(session: Session, dt: number)
	if session.done then
		return
	end
	if session.ended then
		if os.clock() >= session.finishAt then
			finish(session, false)
		end
		return
	end
	session.clock += dt * session.speed
	if not session.started and session.clock >= 0 then
		session.started = true
		feed(startEvent(session))
	end
	if not session.started then
		return
	end
	while session.cursor <= #session.steps and session.steps[session.cursor].t <= session.clock do
		playStep(session, session.steps[session.cursor])
		session.cursor += 1
	end
	if session.cursor > #session.steps then
		session.ended = true
		feed(endEvent(session))
		session.finishAt = os.clock() + R.EndHoldSeconds
	end
end

-- The x2 and Skip buttons, a column on the right edge (the middle of the screen stays empty).
local function controls(session: Session)
	local root = UiKit.root()
	local column = UiKit.make("Frame", {
		Name = "ArenaReplayControls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -U.Edge, 0.5, 0),
		Size = UDim2.fromOffset(R.ButtonWidth, U.Touch * 2 + U.Gap),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, root)
	table.insert(session.extras, column)
	UiKit.make("UIListLayout", {
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, column)
	local fast: TextButton? = nil
	fast = UiKit.button(column, {
		Name = "Fast",
		Text = "x" .. tostring(R.FastSpeed),
		Style = "secondary",
		Size = UDim2.fromOffset(R.ButtonWidth, U.Touch),
		LayoutOrder = 1,
		OnClick = function()
			session.speed = if session.speed == 1 then R.FastSpeed else 1
			if fast then
				UiKit.setStyle(fast, if session.speed == 1 then "secondary" else "primary")
			end
		end,
	})
	UiKit.button(column, {
		Name = "Skip",
		Text = "Skip",
		Style = "secondary",
		Size = UDim2.fromOffset(R.ButtonWidth, U.Touch),
		LayoutOrder = 2,
		OnClick = function()
			skipRest(session)
		end,
	})
end

-- Ends a replay that is still playing without calling its onDone (a new one begins, or the screen is closed).
function ArenaReplay.stop()
	local session = current
	if session then
		finish(session, true)
	end
end

function ArenaReplay.playing(): boolean
	return current ~= nil
end

-- Plays the fight of an `attack` answer; `onDone` runs once, when the replay is over and everything it made is gone.
function ArenaReplay.play(answer: any, onDone: (() -> ())?)
	ArenaReplay.stop()
	if type(answer) ~= "table" or type(answer.steps) ~= "table" or type(answer.sides) ~= "table" then
		if onDone then
			onDone()
		end
		return
	end
	local session: Session = {
		steps = answer.steps,
		cursor = 1,
		clock = -R.LeadSeconds,
		speed = 1,
		started = false,
		ended = false,
		skipped = false,
		finishAt = 0,
		won = answer.won == true,
		units = {},
		bodies = {},
		extras = {},
		connection = nil,
		onDone = onDone,
		done = false,
	}
	current = session
	local ok, err = pcall(function(): any
		local centre, toPlayer = field()
		setUp(session, answer, centre, toPlayer)
		controls(session)
		return nil
	end)
	if not ok then
		warn(Config.LogPrefix, "arena replay could not begin:", err)
		finish(session, false)
		return
	end
	session.connection = RunService.Heartbeat:Connect(function(dt)
		local alive, why = pcall(function(): any
			tick(session, dt)
			return nil
		end)
		if not alive then
			warn(Config.LogPrefix, "arena replay tick:", why)
			finish(session, false)
		end
	end)
end

return ArenaReplay
