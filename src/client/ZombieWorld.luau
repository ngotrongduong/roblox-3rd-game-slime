--!strict
-- The zombie groups outside the villages, drawn from what the server publishes under workspace.ZombieCamps/<slice>/<id>
-- (src/server/ZombieFights.luau; the camps of the whole server, every slice of the valley has its own): each waiting or
-- fighting zombie as a real slime body with SlimeActor, a level marker over each group (coloured by the viewer's own level,
-- PlayerLevel on their village folder) and a prompt to order an attack. Only the groups nearest the camera, in any slice,
-- are drawn (Config.Zombies.DrawDistance, at most View.MaxDrawnZombies bodies), and only the groups near the camera have a
-- marker and a prompt. A waiting group's zombies live: each moves freely round the group's place, pauses, shows a feeling or
-- talks to a neighbour (client only, seeded per zombie, staggered, with a budget); a group that is taken or fighting turns to
-- face the team that attacks it (any player's). It decides nothing: the fight (ZombieFight) and the sheets (UiTeams) use its
-- small API.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local VillagePath = require(ReplicatedStorage.Shared.VillagePath)
local Zombies = require(ReplicatedStorage.Shared.Zombies)
local SlimeActor = require(script.Parent.SlimeActor)
local ZombieLook = require(script.Parent.ZombieLook)
local ZombieTeams = require(script.Parent.ZombieTeams)

local Z = Config.Zombies
local V = Z.View

-- What one zombie is doing with its time. mode: "idle" waits for nextAt; "walk" until legEnd (server time); "emote" and
-- "chat" until endAt; "face" (the group is taken) and "fight" (it is fighting) are the group's, not the zombie's.
type Roam = {
	rng: Random,
	mode: string,
	nextAt: number,
	legEnd: number,
	endAt: number,
	replyAt: number,
	reply: string,
}
export type Entry = {
	config: Configuration,
	kind: string,
	level: number,
	-- the slice of the valley its group stands in (its gate is the village it looks at)
	slice: number,
	model: Model?,
	actor: SlimeActor.Slime?,
	-- where it stands in its group, and the way it faces (towards the village)
	spot: Vector3,
	facing: Vector3,
	roam: Roam,
	connections: { RBXScriptConnection },
}
-- The level marker and the attack prompt of a group, made while the group is near the camera.
type Marker = {
	anchor: Part,
	gui: BillboardGui,
	label: TextLabel,
	scale: UIScale,
	prompt: ProximityPrompt,
}
export type Group = {
	id: string,
	folder: Configuration,
	slice: number,
	camp: number,
	level: number,
	state: string,
	-- the team that ordered the attack on it (0 when none) and the UserId of its player (0 when none)
	team: number,
	attacker: number,
	position: Vector3,
	marker: Marker?,
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

-- The gate of a slice of the valley (0 is the Market's): the village its groups look at.
local function gatePosition(slice: number): Vector3
	return Layout.sliceGate(math.clamp(slice, 0, Config.Map.PlotCount)).Position
end

-- The flat way from a point towards a slice's gate.
function ZombieWorld.towardVillage(from: Vector3, slice: number): Vector3
	local flat = gatePosition(slice) - from
	flat = Vector3.new(flat.X, 0, flat.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
end

local function probe(origin: Vector3, length: number): Vector3?
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
	-- (leaves, grass and other things nobody can stand on are not ground)
	params.RespectCanCollide = true
	local hit = workspace:Raycast(origin, Vector3.new(0, -length, 0), params)
	return if hit then hit.Position else nil
end

local function groundAt(point: Vector3): Vector3
	return probe(point + Vector3.new(0, V.GroundProbeUp, 0), V.GroundProbeUp + V.GroundProbeDown) or point
end

-- The ground under a point (the map's own surface), for the fight to stand its fighters on.
ZombieWorld.groundAt = groundAt

-- The ground under a flat spot of the valley whose height is not known (the march's legs are published flat): the same
-- ray the server used to place the groups, from Zombies.GroundProbeUp above the map's ground height.
function ZombieWorld.groundOnMap(x: number, z: number): Vector3
	local base = Config.Map.GroundY
	return probe(Vector3.new(x, base + Z.GroundProbeUp, z), Z.GroundProbeUp + Z.GroundProbeDown)
		or Vector3.new(x, base, z)
end

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
		SlimeActor.lookAt(actor, gatePosition(entry.slice))
		-- (it stands on its own feet from the start: a standing leg keeps it on the ground and lets it turn on the spot)
		SlimeActor.setTravel(actor, foot, foot, 0, 0, false, "stroll")
		local roam = entry.roam
		roam.mode = "idle"
		roam.nextAt = os.clock() + roam.rng:NextNumber() * V.Roam.PauseMax
	else
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
	entry.model, entry.actor = model, actor
end

-- Spreads the group's zombies on a ring round its position, in a stable order (Zombies.ringSpot: where a fight on them
-- places them too).
local function layout(group: Group)
	local list: { Entry } = {}
	for _, entry in group.entries do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		return a.config.Name < b.config.Name
	end)
	local facing = ZombieWorld.towardVillage(group.position, group.slice)
	for index, entry in list do
		local x, z = Zombies.ringSpot(index, #list)
		entry.spot = group.position + Vector3.new(x, 0, z)
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

-- How dangerous a group is for the person looking: by how far its level lies above the viewer's own (PlayerLevel on their
-- village folder; until it is published the group counts as even).
local function dangerColour(group: Group): Color3
	local own = ZombieTeams.level()
	local gap = if own > 0 then group.level - own else 0
	local colours = V.DangerColours
	if gap >= V.Danger.Hard then
		return Color3.fromHex(colours.Hard)
	elseif gap <= V.Danger.Easy then
		return Color3.fromHex(colours.Easy)
	end
	return Color3.fromHex(colours.Fair)
end

local function refreshMarker(group: Group)
	local marker = group.marker
	if not marker then
		return
	end
	marker.label.Text = "Lv " .. tostring(group.level)
	marker.label.TextColor3 = dangerColour(group)
	marker.gui.Enabled = group.state ~= "gone"
	marker.prompt.Enabled = group.state == "waiting"
	local camera = workspace.CurrentCamera
	marker.scale.Scale = if camera then math.clamp(camera.ViewportSize.Y / 900, 0.7, 1.3) else 1
end

-- The marker and the prompt of a group, made when the camera comes near and dropped when it goes away: a server of 8 has 108
-- groups, and most are far.
local function showMarker(group: Group, on: boolean)
	if not on then
		local marker = group.marker
		if marker then
			marker.anchor:Destroy()
			group.marker = nil
		end
		return
	end
	if group.marker then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "Group_" .. group.id
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new(group.position + Vector3.new(0, V.AnchorLift, 0))
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
	prompt.Name = "Attack"
	prompt.ActionText = "Attack"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Z.SendRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function()
		local open = opener
		if open and group.state == "waiting" then
			open(group.id)
		end
	end)
	group.marker = { anchor = anchor, gui = gui, label = label, scale = scale, prompt = prompt }
	refreshMarker(group)
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

-- ===== Zombies that live =====

local function seedOf(name: string): number
	local sum = 7
	for index = 1, #name do
		sum = (sum * 31 + string.byte(name, index)) % 2147483647
	end
	return sum
end

local function newRoam(name: string): Roam
	local rng = Random.new(seedOf(name))
	return {
		rng = rng,
		mode = "idle",
		nextAt = os.clock() + rng:NextNumber() * V.Roam.PauseMax,
		legEnd = 0,
		endAt = 0,
		replyAt = 0,
		reply = "",
	}
end

local function pause(roam: Roam): number
	return os.clock() + V.Roam.PauseMin + roam.rng:NextNumber() * (V.Roam.PauseMax - V.Roam.PauseMin)
end

local function pick(roam: Roam, list: { string }): string
	return list[roam.rng:NextInteger(1, #list)]
end

-- The standing place of a body: a leg that goes nowhere keeps it on the ground and lets it turn on the spot.
local function standStill(actor: SlimeActor.Slime, at: Vector3)
	SlimeActor.setTravel(actor, at, at, 0, 0, false, "stroll")
end

-- The face of its own kind and the eyes towards the village again, after a feeling or a chat.
local function ownFace(entry: Entry, actor: SlimeActor.Slime)
	SlimeActor.setEmotion(actor, ZombieLook.look(entry.kind).face)
	SlimeActor.lookAt(actor, gatePosition(entry.slice))
	SlimeActor.face(actor, nil)
end

-- Where a taken group looks: at the team that attacks it (any player's), else at its slice's village.
local function lookPoint(group: Group): Vector3
	local village = if group.attacker > 0 then ZombieTeams.rootOf(group.attacker) else nil
	local team = if group.team > 0 and village then ZombieTeams.get(group.team, village) else nil
	if team then
		return Vector3.new(team.to.X, group.position.Y, team.to.Z)
	end
	return gatePosition(group.slice)
end

local function nearestNeighbour(group: Group, entry: Entry, actor: SlimeActor.Slime): Entry?
	local best: Entry? = nil
	local bestDistance = V.Roam.ChatRangeStuds
	for _, other in group.entries do
		local body = other.actor
		if other ~= entry and body and other.roam.mode == "idle" and not dead[other.config.Name] then
			local distance = (body.root.Position - actor.root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = other, distance
			end
		end
	end
	return best
end

type RoamBudget = { movers: number, decisions: number }

-- One zombie's turn. A waiting group's zombies pick something to do now and then; a taken or fighting group's stand and
-- face the team (and a fighting one stops being placed by the roaming, the fight moves its bodies).
local function roamEntry(
	group: Group,
	entry: Entry,
	point: Vector3?,
	now: number,
	serverNow: number,
	budget: RoamBudget
)
	local actor = entry.actor
	local roam = entry.roam
	if not actor then
		return
	end
	local R = V.Roam
	if point then
		if group.state == "fighting" then
			if roam.mode ~= "fight" then
				roam.mode = "fight"
				entry.spot = actor.root.Position
				actor.travelFrom, actor.travelTo = nil, nil
			end
		elseif roam.mode ~= "face" then
			roam.mode = "face"
			ownFace(entry, actor)
			entry.spot = actor.root.Position
			standStill(actor, entry.spot)
		end
		if roam.mode == "face" then
			SlimeActor.face(actor, point)
		end
		return
	end
	if roam.mode == "fight" or roam.mode == "face" then
		-- the group is free again: it stands where it is and goes on after a pause
		SlimeActor.face(actor, nil)
		standStill(actor, actor.root.Position)
		roam.mode, roam.nextAt = "idle", pause(roam)
		return
	end
	if roam.mode == "walk" then
		if serverNow >= roam.legEnd then
			roam.mode, roam.nextAt = "idle", pause(roam)
			entry.spot = actor.root.Position
		end
		return
	end
	if roam.mode == "emote" or roam.mode == "chat" then
		if roam.replyAt > 0 and now >= roam.replyAt then
			roam.replyAt = 0
			SlimeActor.setEmotion(actor, roam.reply)
		end
		if now >= roam.endAt then
			ownFace(entry, actor)
			roam.mode, roam.nextAt = "idle", pause(roam)
		end
		return
	end
	if now < roam.nextAt or budget.decisions <= 0 then
		return
	end
	budget.decisions -= 1
	local roll = roam.rng:NextNumber()
	if roll < R.MoveChance then
		if budget.movers >= R.MaxMovers then
			roam.nextAt = pause(roam)
			return
		end
		-- a new spot inside the group's roaming ground, not right where it stands
		local here = actor.root.Position
		local goal = here
		for _ = 1, 3 do
			local angle = roam.rng:NextNumber() * math.pi * 2
			local reach = math.sqrt(roam.rng:NextNumber()) * V.RoamStuds
			local try = groundAt(
				Vector3.new(
					group.position.X + math.cos(angle) * reach,
					group.position.Y,
					group.position.Z + math.sin(angle) * reach
				)
			)
			if (Vector3.new(try.X, 0, try.Z) - Vector3.new(here.X, 0, here.Z)).Magnitude >= R.MinGoalStuds then
				goal = try
				break
			end
		end
		if goal == here then
			roam.nextAt = pause(roam)
			return
		end
		local total = 0
		for _, item in R.Gaits do
			total += item.weight
		end
		local ticket = roam.rng:NextNumber() * total
		local gait = R.Gaits[1].name
		for _, item in R.Gaits do
			ticket -= item.weight
			if ticket <= 0 then
				gait = item.name
				break
			end
		end
		local seconds = VillagePath.duration((goal - here).Magnitude, R.SpeedFactor, gait)
		SlimeActor.setTravel(actor, here, goal, serverNow, serverNow + seconds, false, gait)
		roam.mode, roam.legEnd = "walk", serverNow + seconds
		budget.movers += 1
	elseif roll < R.MoveChance + R.EmoteChance then
		SlimeActor.setEmotion(actor, pick(roam, R.Emotions))
		roam.mode, roam.endAt = "emote", now + R.EmoteSeconds
	elseif roll < R.MoveChance + R.EmoteChance + R.ChatChance then
		local neighbour = nearestNeighbour(group, entry, actor)
		local other = if neighbour then neighbour.actor else nil
		if neighbour and other then
			-- the first asks, the other turns to it and answers a beat later
			SlimeActor.face(actor, other.root.Position)
			SlimeActor.lookAt(actor, other.body)
			SlimeActor.setEmotion(actor, pick(roam, R.ChatAsk))
			roam.mode, roam.endAt = "chat", now + R.ChatReplySeconds + R.EmoteSeconds
			local reply = neighbour.roam
			SlimeActor.face(other, actor.root.Position)
			SlimeActor.lookAt(other, actor.body)
			reply.mode, reply.endAt = "chat", now + R.ChatReplySeconds + R.EmoteSeconds
			reply.replyAt, reply.reply = now + R.ChatReplySeconds, pick(roam, R.ChatAnswer)
		else
			SlimeActor.hop(actor, R.HopHeight)
			roam.nextAt = pause(roam)
		end
	else
		SlimeActor.hop(actor, R.HopHeight)
		roam.nextAt = pause(roam)
	end
end

local roamWarned: { [string]: boolean } = {}

-- Looks at the drawn groups: a few zombies at a time start something, so they never all act together.
local function roamTick()
	local now, serverNow = os.clock(), workspace:GetServerTimeNow()
	local budget: RoamBudget = { movers = 0, decisions = V.Roam.MaxPerTick }
	for _, group in groups do
		if group.drawn then
			for _, entry in group.entries do
				if entry.actor and entry.roam.mode == "walk" then
					budget.movers += 1
				end
			end
		end
	end
	for _, group in groups do
		if group.drawn then
			local point = if group.state == "waiting" then nil else lookPoint(group)
			for _, entry in group.entries do
				if entry.actor and not dead[entry.config.Name] then
					local ok, err = pcall(function(): any
						roamEntry(group, entry, point, now, serverNow, budget)
						return nil
					end)
					if not ok and not roamWarned[entry.config.Name] then
						roamWarned[entry.config.Name] = true
						warn(Config.LogPrefix, "zombie roam error:", err)
					end
				end
			end
		end
	end
end

local function readGroup(group: Group)
	local folder = group.folder
	group.slice = math.floor(number(folder, "Slice", group.slice))
	group.camp = math.floor(number(folder, "Camp", group.camp))
	group.level = math.floor(number(folder, "Level", group.level))
	group.state = stringAttr(folder, "State", "waiting")
	group.team = math.floor(number(folder, "Team", 0))
	group.attacker = math.floor(number(folder, "Attacker", 0))
	local at = folder:GetAttribute("Position")
	local moved = typeof(at) == "Vector3" and at ~= group.position
	if typeof(at) == "Vector3" then
		group.position = at
		local marker = group.marker
		if marker then
			marker.anchor.CFrame = CFrame.new(at + Vector3.new(0, V.AnchorLift, 0))
		end
	end
	if moved then
		layout(group)
	end
	refreshMarker(group)
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
		slice = group.slice,
		model = nil,
		actor = nil,
		spot = group.position,
		facing = Vector3.zAxis,
		roam = newRoam(child.Name),
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
	local group: Group = {
		id = child.Name,
		folder = child,
		slice = 0,
		camp = 1,
		level = 1,
		state = "waiting",
		team = 0,
		attacker = 0,
		position = Vector3.zero,
		marker = nil,
		entries = {},
		byId = {},
		drawn = false,
		connections = {},
	}
	groups[child] = group
	byGroupId[group.id] = group
	for _, name in { "Slice", "Camp", "Level", "Position", "State", "Team", "Attacker" } do
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
	showMarker(group, false)
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
			showMarker(group, false)
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
		-- (the level marker and the prompt exist only near the camera; the colour follows the viewer's level as it grows)
		local markerLimit = V.MarkerDistance * V.HideMargin
		if group.marker or item.distance <= V.MarkerDistance then
			showMarker(group, item.distance <= markerLimit)
			refreshMarker(group)
		end
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

-- (a zombie's id starts with its group's: "s3c2g4-17-2")
function ZombieWorld.zombie(id: string): Entry?
	local group = byGroupId[string.match(id, "^[^-]+") or ""]
	return if group then group.byId[id] else nil
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
		-- The camps of the whole server: workspace.ZombieCamps/<slice>/<group> (made by the server when the first player's
		-- village is up).
		local camps = workspace:FindFirstChild("ZombieCamps")
		while not camps do
			task.wait(V.CheckSeconds)
			camps = workspace:FindFirstChild("ZombieCamps")
		end
		local function bindSlice(slice: Instance)
			slice.ChildAdded:Connect(addGroup)
			slice.ChildRemoved:Connect(removeGroup)
			for _, child in slice:GetChildren() do
				addGroup(child)
			end
		end
		camps.ChildAdded:Connect(bindSlice)
		for _, slice in camps:GetChildren() do
			bindSlice(slice)
		end
		-- the zombies' own life, looked at a few times a second
		task.spawn(function()
			local roamFailed = false
			while camps.Parent do
				local ok, err = pcall(function(): any
					roamTick()
					return nil
				end)
				if not ok and not roamFailed then
					roamFailed = true
					warn(Config.LogPrefix, "zombie roaming error:", err)
				end
				task.wait(V.Roam.TickSeconds)
			end
		end)
		while camps.Parent do
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
