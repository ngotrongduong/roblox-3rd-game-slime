--!strict
-- The zombie groups outside the village, drawn from what the server publishes under workspace.Villages.<id>.Camps
-- (src/server/ZombieFights.luau): each waiting or fighting zombie as a real slime body with SlimeActor, a level marker over
-- each group and a prompt to send a squad. Only groups near the camera are drawn (Config.Zombies.DrawDistance, at most
-- View.MaxDrawnZombies bodies). It decides nothing: the fight (ZombieFight) and the sheets (UiSquad) use its small API.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local SlimeActor = require(script.Parent.SlimeActor)
local ZombieLook = require(script.Parent.ZombieLook)

local Z = Config.Zombies
local V = Z.View

export type Entry = {
	config: Configuration,
	kind: string,
	level: number,
	model: Model?,
	actor: SlimeActor.Slime?,
	-- where it stands in its group, and the way it faces (towards the village)
	spot: Vector3,
	facing: Vector3,
	connections: { RBXScriptConnection },
}
export type Group = {
	id: string,
	folder: Configuration,
	camp: number,
	level: number,
	state: string,
	position: Vector3,
	anchor: Part,
	gui: BillboardGui,
	label: TextLabel,
	scale: UIScale,
	prompt: ProximityPrompt,
	entries: { [Configuration]: Entry },
	byId: { [string]: Entry },
	drawn: boolean,
	connections: { RBXScriptConnection },
}

local ZombieWorld = {}
local groups: { [Configuration]: Group } = {}
local byGroupId: { [string]: Group } = {}
-- Zombies the fight has seen fall: never drawn again (their Configuration stays until the group respawns).
local dead: { [string]: boolean } = {}
local opener: ((groupId: string) -> ())? = nil
local started = false
local warned = false

local actorsFolder = Instance.new("Folder")
actorsFolder.Name = "ZombieClientActors"
actorsFolder.Parent = workspace

local function number(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if type(value) == "number" and value == value then value else default
end

local function stringAttr(inst: Instance, name: string, default: string): string
	local value = inst:GetAttribute(name)
	return if type(value) == "string" then value else default
end

local function gatePosition(): Vector3
	return Layout.plotGate(Config.Village.DevPlot).Position
end

-- The flat way from a point towards the village's gate.
function ZombieWorld.towardVillage(from: Vector3): Vector3
	local flat = gatePosition() - from
	flat = Vector3.new(flat.X, 0, flat.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
end

local function groundAt(point: Vector3): Vector3
	local ignore: { Instance } = { actorsFolder }
	for _, name in { "VillageClientActors", "Villages" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end
	local character = Players.LocalPlayer.Character
	if character then
		table.insert(ignore, character)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(
		point + Vector3.new(0, V.GroundProbeUp, 0),
		Vector3.new(0, -(V.GroundProbeUp + V.GroundProbeDown), 0),
		params
	)
	return if hit then hit.Position else point
end

-- The ground under a point (the map's own surface), for the fight to stand its fighters on.
ZombieWorld.groundAt = groundAt

local function undraw(entry: Entry)
	if entry.actor then
		SlimeActor.destroy(entry.actor)
		entry.actor = nil
	end
	if entry.model then
		entry.model:Destroy()
		entry.model = nil
	end
end

local function draw(entry: Entry)
	if entry.model or dead[entry.config.Name] then
		return
	end
	local look = ZombieLook.look(entry.kind)
	local model = ZombieLook.build(entry.kind)
	model.Name = entry.config.Name
	local foot = groundAt(entry.spot)
	entry.spot = foot
	model:PivotTo(CFrame.lookAt(foot, foot + entry.facing))
	model.Parent = actorsFolder
	local actor = SlimeActor.new(model, look.face)
	if actor then
		-- (the body collides by default; a zombie is only to be looked at)
		actor.body.CanCollide = false
		SlimeActor.lookAt(actor, gatePosition())
	else
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
	entry.model, entry.actor = model, actor
end

-- Spreads the group's zombies on a ring round its position, in a stable order.
local function layout(group: Group)
	local list: { Entry } = {}
	for _, entry in group.entries do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		return a.config.Name < b.config.Name
	end)
	local facing = ZombieWorld.towardVillage(group.position)
	for index, entry in list do
		local angle = (index - 1) / #list * math.pi * 2 + math.pi / 4
		local offset = if #list == 1
			then Vector3.zero
			else Vector3.new(math.cos(angle), 0, math.sin(angle)) * V.SpreadStuds
		entry.spot = group.position + offset
		entry.facing = facing
		-- a body that is drawn already is put back on its place
		if entry.model then
			undraw(entry)
			if group.drawn then
				draw(entry)
			end
		end
	end
end

local function dangerColour(group: Group): Color3
	local sum, count = 0, 0
	for _, other in groups do
		sum += other.level - (Z.LevelOffsets[other.camp] or 0)
		count += 1
	end
	local reference = if count > 0 then sum / count else group.level
	local gap = group.level - reference
	local colours = V.DangerColours
	if gap >= V.Danger.Hard then
		return Color3.fromHex(colours.Hard)
	elseif gap <= V.Danger.Easy then
		return Color3.fromHex(colours.Easy)
	end
	return Color3.fromHex(colours.Fair)
end

local function refreshMarker(group: Group)
	group.label.Text = "Lv " .. tostring(group.level)
	group.label.TextColor3 = dangerColour(group)
	group.gui.Enabled = group.state ~= "gone"
	group.prompt.Enabled = group.state == "waiting"
	local camera = workspace.CurrentCamera
	group.scale.Scale = if camera then math.clamp(camera.ViewportSize.Y / 900, 0.7, 1.3) else 1
end

local function setDrawn(group: Group, on: boolean)
	group.drawn = on
	for _, entry in group.entries do
		if on then
			draw(entry)
		else
			undraw(entry)
		end
	end
end

local function readGroup(group: Group)
	local folder = group.folder
	group.camp = math.floor(number(folder, "Camp", group.camp))
	group.level = math.floor(number(folder, "Level", group.level))
	group.state = stringAttr(folder, "State", "waiting")
	local at = folder:GetAttribute("Position")
	local moved = typeof(at) == "Vector3" and at ~= group.position
	if typeof(at) == "Vector3" then
		group.position = at
		group.anchor.CFrame = CFrame.new(at + Vector3.new(0, V.AnchorLift, 0))
	end
	if moved then
		layout(group)
	end
	for _, other in groups do
		refreshMarker(other)
	end
	if group.state == "gone" and group.drawn then
		setDrawn(group, false)
	end
end

local function addEntry(group: Group, child: Instance)
	if not child:IsA("Configuration") or group.entries[child] then
		return
	end
	local entry: Entry = {
		config = child,
		kind = stringAttr(child, "Kind", "rotten"),
		level = math.floor(number(child, "Level", group.level)),
		model = nil,
		actor = nil,
		spot = group.position,
		facing = Vector3.zAxis,
		connections = {},
	}
	group.entries[child] = entry
	group.byId[child.Name] = entry
	-- (its attributes may arrive just after it: a Kind that changes redraws it)
	table.insert(
		entry.connections,
		child:GetAttributeChangedSignal("Kind"):Connect(function()
			entry.kind = stringAttr(child, "Kind", "rotten")
			undraw(entry)
			if group.drawn then
				draw(entry)
			end
		end)
	)
	layout(group)
	if group.drawn then
		draw(entry)
	end
end

local function removeEntry(group: Group, child: Instance)
	local entry = group.entries[child :: Configuration]
	if not entry then
		return
	end
	for _, connection in entry.connections do
		connection:Disconnect()
	end
	undraw(entry)
	group.entries[child :: Configuration] = nil
	group.byId[child.Name] = nil
	dead[child.Name] = nil
	layout(group)
end

local function addGroup(child: Instance)
	if not child:IsA("Configuration") or groups[child] then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "Group_" .. child.Name
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.Parent = actorsFolder

	local gui = Instance.new("BillboardGui")
	gui.Name = "GroupMarker"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(V.MarkerWidth, V.MarkerHeight)
	gui.StudsOffset = Vector3.new(0, V.MarkerLift, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = V.MarkerDistance
	gui.LightInfluence = 0
	gui.Parent = anchor
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
	label.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SendSquad"
	prompt.ActionText = "Fight"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Z.SendRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	local group: Group = {
		id = child.Name,
		folder = child,
		camp = 1,
		level = 1,
		state = "waiting",
		position = Vector3.zero,
		anchor = anchor,
		gui = gui,
		label = label,
		scale = scale,
		prompt = prompt,
		entries = {},
		byId = {},
		drawn = false,
		connections = {},
	}
	groups[child] = group
	byGroupId[group.id] = group
	prompt.Triggered:Connect(function()
		local open = opener
		if open and group.state == "waiting" then
			open(group.id)
		end
	end)
	for _, name in { "Camp", "Level", "Position", "State" } do
		table.insert(
			group.connections,
			child:GetAttributeChangedSignal(name):Connect(function()
				readGroup(group)
			end)
		)
	end
	table.insert(
		group.connections,
		child.ChildAdded:Connect(function(grandchild)
			addEntry(group, grandchild)
		end)
	)
	table.insert(
		group.connections,
		child.ChildRemoved:Connect(function(grandchild)
			removeEntry(group, grandchild)
		end)
	)
	readGroup(group)
	for _, grandchild in child:GetChildren() do
		addEntry(group, grandchild)
	end
end

local function removeGroup(child: Instance)
	local group = groups[child :: Configuration]
	if not group then
		return
	end
	for _, connection in group.connections do
		connection:Disconnect()
	end
	for node in group.entries do
		removeEntry(group, node)
	end
	group.anchor:Destroy()
	groups[child :: Configuration] = nil
	byGroupId[group.id] = nil
end

-- Which groups are near enough to draw, nearest first, within the body budget.
local function check()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local from = camera.CFrame.Position
	local near: { { group: Group, distance: number } } = {}
	for _, group in groups do
		if group.state == "gone" then
			if group.drawn then
				setDrawn(group, false)
			end
		else
			table.insert(near, { group = group, distance = (group.position - from).Magnitude })
		end
	end
	table.sort(near, function(a, b)
		return a.distance < b.distance
	end)
	local budget = V.MaxDrawnZombies
	for _, item in near do
		local group = item.group
		local count = 0
		for _, entry in group.entries do
			if not dead[entry.config.Name] then
				count += 1
			end
		end
		local limit = if group.drawn then Z.DrawDistance * V.HideMargin else Z.DrawDistance
		local want = item.distance <= limit and count <= budget
		if want then
			budget -= count
		end
		if want ~= group.drawn then
			setDrawn(group, want)
		end
	end
end

-- The sheets ask for a group and its zombies; the fight asks where they stand.
function ZombieWorld.setOpener(open: (groupId: string) -> ())
	opener = open
end

function ZombieWorld.group(id: string): Group?
	return byGroupId[id]
end

function ZombieWorld.zombie(id: string): Entry?
	for _, group in groups do
		local entry = group.byId[id]
		if entry then
			return entry
		end
	end
	return nil
end

-- A zombie the fight saw fall: it bursts away (the caller adds the coins and the particles) and is not drawn again.
function ZombieWorld.kill(id: string)
	dead[id] = true
	local entry = ZombieWorld.zombie(id)
	if entry and entry.actor then
		SlimeActor.kick(entry.actor, "squash", V.DeathSquash)
		task.delay(V.DeathDelay, function()
			undraw(entry)
		end)
	end
end

function ZombieWorld.isDead(id: string): boolean
	return dead[id] == true
end

function ZombieWorld.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local villages = workspace:WaitForChild("Villages")
		local root = villages:WaitForChild(tostring(Players.LocalPlayer.UserId))
		local function bindCamps(camps: Instance)
			camps.ChildAdded:Connect(addGroup)
			camps.ChildRemoved:Connect(removeGroup)
			for _, child in camps:GetChildren() do
				addGroup(child)
			end
		end
		local camps = root:FindFirstChild("Camps")
		if camps then
			bindCamps(camps)
		else
			root.ChildAdded:Connect(function(child)
				if child.Name == "Camps" then
					bindCamps(child)
				end
			end)
		end
		while root.Parent do
			local ok, err = pcall(function(): any
				check()
				return nil
			end)
			if not ok and not warned then
				warned = true
				warn(Config.LogPrefix, "zombie world error:", err)
			end
			task.wait(V.CheckSeconds)
		end
		for child in groups do
			removeGroup(child)
		end
	end)
end

return ZombieWorld
