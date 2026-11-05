--!strict
-- The Slime Dungeon's fight drawn. The server runs it (src/server/Dungeon.luau) and sends Remotes.Fight batches that say
-- `dungeon = true`; ZombieFight draws the blows, the dodges, the falls and the healing on bodies it is given (ZombieFight.adopt),
-- and this file gives it those bodies: the squad's own slimes stand in a row in the middle of the arena (the server places no
-- slime bodies) and each monster comes in at its spawn point as a body made by MonsterLook, with a health bar (ZombieFight)
-- and its name and level over it. It also turns a fallen monster's drops into pictures floating up where it fell, keeps the
-- health bars to what the arena publishes, and clears everything when the run ends. No camera effects. One error never stops
-- the drawing: per-event work is in pcall.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local ArenaReplay = require(script.Parent.ArenaReplay)
local FightFx = require(script.Parent.FightFx)
local MonsterLook = require(script.Parent.MonsterLook)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeLook = require(script.Parent.SlimeLook)
local UiDungeon = require(script.Parent.UiDungeon)
local ZombieFight = require(script.Parent.ZombieFight)
local ZombieTeams = require(script.Parent.ZombieTeams)

local D = Config.Dungeon
local P = D.View
local V = Config.Zombies.View
local player = Players.LocalPlayer

-- A body on the arena: its model, its actor, the node its health bar reads and the name over it (monsters).
type Body = {
	actor: SlimeActor.Slime,
	model: Model,
	node: Configuration,
	foe: boolean,
	tag: BillboardGui?,
}

local DungeonFight = {}
local bodies: { [string]: Body } = {}
local centre: Vector3? = nil
local startedAt = 0
local polling = false
local popsAlive = 0
local warned: { [string]: boolean } = {}

local function safe(label: string, work: () -> ())
	local ok, err = pcall(function(): any
		work()
		return nil
	end)
	if not ok and not warned[label] then
		warned[label] = true
		warn(Config.LogPrefix, "dungeon fight", label, "error:", err)
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

local function attribute(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if type(value) == "number" and value == value then value else default
end

local function healthNode(hp: number, maxHp: number): Configuration
	local node = Instance.new("Configuration")
	node:SetAttribute("MaxHp", maxHp)
	node:SetAttribute("Hp", hp)
	return node
end

-- ===== Bodies =====

local function removeBody(id: string)
	local body = bodies[id]
	if not body then
		return
	end
	bodies[id] = nil
	ZombieFight.release(id)
	if body.tag then
		body.tag:Destroy()
	end
	SlimeActor.destroy(body.actor)
	body.model:Destroy()
	body.node:Destroy()
end

local function clearAll()
	ZombieFight.endDungeon()
	for _, body in bodies do
		if body.tag then
			body.tag:Destroy()
		end
		SlimeActor.destroy(body.actor)
		body.model:Destroy()
		body.node:Destroy()
	end
	table.clear(bodies)
	centre = nil
end

-- The name and level over a monster's health bar, in pixels (scaled with the screen, never in studs).
local function nameTag(actor: SlimeActor.Slime, text: string, role: string): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "MonsterTag"
	gui.Adornee = actor.body
	gui.Size = UDim2.fromOffset(P.NameWidth, P.NameHeight + V.BarHeight)
	-- (its lower edge stands on the health bar's centre; the label sits above the bar's own height)
	gui.SizeOffset = Vector2.new(0, 0.5)
	gui.StudsOffset = Vector3.new(0, SlimeActor.topOffset(actor) + V.BarLift, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = V.BarDistance
	gui.LightInfluence = 0
	gui.Parent = actor.body
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local colours: { [string]: string } = P.NameColours :: any
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, P.NameHeight)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextSize = Config.Ui.TextSmall
	label.TextColor3 = Color3.fromHex(colours[role] or colours.normal)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
	label.Parent = gui
	return gui
end

local function addSquad(id: string, role: string, spot: Vector3, facing: Vector3)
	local village = ZombieTeams.root()
	local folder = if village then village:FindFirstChild("Slimes") else nil
	local node = if folder then folder:FindFirstChild(id) else nil
	if not node or not node:IsA("Configuration") then
		return
	end
	local model = SlimeLook.build({
		Colour = node:GetAttribute("Colour"),
		Material = node:GetAttribute("Material"),
		DualId = node:GetAttribute("DualId"),
		SecretId = node:GetAttribute("SecretId"),
		Scale = attribute(node, "Scale", 1),
	})
	model.Name = "Dungeon_" .. id
	model:PivotTo(CFrame.lookAt(spot, spot + facing))
	model.Parent = actorsFolder()
	local actor = SlimeActor.new(model, V.FighterFace)
	if not actor then
		model:Destroy()
		return
	end
	actor.body.CanCollide = false
	-- (the real health comes from the arena; until it is there the bar is full)
	local hp = healthNode(1, 1)
	bodies[id] = { actor = actor, model = model, node = hp, foe = false, tag = nil }
	ZombieFight.adopt(id, {
		actor = actor,
		stand = spot,
		foe = false,
		way = role,
		size = 1,
		dead = false,
		node = hp,
		gone = nil,
	})
	SlimeActor.kick(actor, "squash", V.PopSquash)
	SlimeActor.hop(actor, V.PopHop)
end

-- A monster comes in at its spawn point, facing the middle. MonsterLook makes the body; the rest is the same for any look.
local function addMonster(event: { [string]: any })
	local floor = centre
	if not floor or type(event.id) ~= "string" then
		return
	end
	local id: string = event.id
	removeBody(id)
	local at = Vector3.new(event.wx, floor.Y, event.wz)
	local look = MonsterLook.build({ defId = event.defId, kind = event.foeKind, role = event.role, name = event.name })
	local toward = flat(floor - at)
	local facing = if toward.Magnitude > 1e-3 then toward.Unit else Vector3.zAxis
	look.model.Name = "Monster_" .. id
	look.model:PivotTo(CFrame.lookAt(at, at + facing))
	look.model.Parent = actorsFolder()
	local actor = SlimeActor.new(look.model, look.face)
	if not actor then
		look.model:Destroy()
		return
	end
	actor.body.CanCollide = false
	if look.creature then
		SlimeActor.dress(actor, look.creature)
	end
	local hp = if type(event.hp) == "number" then event.hp else 1
	local node = healthNode(hp, hp)
	local role = if type(event.role) == "string" then event.role else "normal"
	local tag = nameTag(actor, "Lv " .. tostring(event.level or 1) .. "  " .. tostring(event.name or ""), role)
	local body: Body = { actor = actor, model = look.model, node = node, foe = true, tag = tag }
	bodies[id] = body
	local ways: { [string]: string } = P.Ways :: any
	ZombieFight.adopt(id, {
		actor = actor,
		stand = at,
		foe = true,
		way = ways[event.foeKind] or "rotten",
		size = look.size,
		dead = false,
		node = node,
		gone = function()
			removeBody(id)
		end,
	})
	SlimeActor.kick(actor, "squash", V.PopSquash)
	SlimeActor.hop(actor, V.PopHop)
end

-- ===== Drops =====

-- What a fallen monster dropped, as pictures with their numbers floating up where it fell.
local function popDrops(at: Vector3, drops: { any })
	if popsAlive >= P.PopMax or #drops == 0 then
		return
	end
	popsAlive += 1
	local anchor = FightFx.anchorAt(at)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Drops"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(#drops * (P.PopIcon + 34), P.PopIcon + 8)
	gui.AlwaysOnTop = true
	gui.MaxDistance = Config.Zombies.DrawDistance
	gui.LightInfluence = 0
	gui.Parent = anchor
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local group = Instance.new("CanvasGroup")
	group.BackgroundTransparency = 1
	group.Size = UDim2.fromScale(1, 1)
	group.Parent = gui
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = group
	for order, drop in drops do
		local cell = Instance.new("Frame")
		cell.BackgroundTransparency = 1
		cell.Size = UDim2.fromOffset(P.PopIcon + 28, P.PopIcon)
		cell.LayoutOrder = order
		cell.Parent = group
		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.Padding = UDim.new(0, 2)
		row.SortOrder = Enum.SortOrder.LayoutOrder
		row.Parent = cell
		UiDungeon.dropIcon(cell, drop.item, P.PopIcon, { LayoutOrder = 1 })
		local number = Instance.new("TextLabel")
		number.BackgroundTransparency = 1
		number.Size = UDim2.new(1, -P.PopIcon - 2, 1, 0)
		number.Font = Enum.Font.FredokaOne
		number.Text = tostring(drop.amount)
		number.TextSize = Config.Ui.TextNormal
		number.TextXAlignment = Enum.TextXAlignment.Left
		number.TextColor3 = Color3.fromHex(V.NumberColours.Coins)
		number.TextStrokeTransparency = 0
		number.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
		number.LayoutOrder = 2
		number.Parent = cell
	end
	TweenService:Create(
		anchor,
		TweenInfo.new(P.PopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = anchor.Position + Vector3.new(0, P.PopRise, 0) }
	):Play()
	task.delay(P.PopSeconds * 0.5, function()
		TweenService:Create(group, TweenInfo.new(P.PopSeconds * 0.5), { GroupTransparency = 1 }):Play()
	end)
	task.delay(P.PopSeconds + 0.1, function()
		popsAlive -= 1
		anchor:Destroy()
	end)
end

-- ===== Health =====

-- The arena the server published for this player (its attributes name the owner); nil until it has streamed in.
local function arenaModel(): Instance?
	local folder = workspace:FindFirstChild(D.ArenaFolder)
	if not folder then
		return nil
	end
	for _, child in folder:GetChildren() do
		if child:GetAttribute("Owner") == player.UserId then
			return child
		end
	end
	return nil
end

-- The health bars follow what the arena publishes. A monster's bar only ever drops to the published number here (the blows
-- and heals of the events moved it already, and the published number is a quarter second old); the squad's follows it.
-- The server's stand-in Parts are hidden for this client: the bodies here are what is seen.
local function follow()
	local arena = arenaModel()
	if not arena then
		return
	end
	local monsters = arena:FindFirstChild("Monsters")
	local squad = arena:FindFirstChild("Squad")
	if monsters then
		for _, part in monsters:GetChildren() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
				local body = bodies[part.Name]
				if body then
					local maxHp = attribute(part, "MaxHp", attribute(body.node, "MaxHp", 1))
					body.node:SetAttribute("MaxHp", maxHp)
					local hp = attribute(part, "Hp", maxHp)
					if hp < attribute(body.node, "Hp", maxHp) then
						body.node:SetAttribute("Hp", hp)
					end
				end
			end
		end
	end
	if squad then
		for _, node in squad:GetChildren() do
			local body = bodies[node.Name]
			if body and not body.foe then
				local maxHp = attribute(node, "MaxHp", 1)
				body.node:SetAttribute("MaxHp", maxHp)
				body.node:SetAttribute("Hp", attribute(node, "Hp", maxHp))
			end
		end
	end
end

local function startPolling()
	if polling then
		return
	end
	polling = true
	task.spawn(function()
		while next(bodies) ~= nil or centre ~= nil do
			safe("follow", follow)
			-- (a run that is over without a "leave" reaching us: the bodies go with the phase)
			local phase = player:GetAttribute("DungeonPhase")
			if (type(phase) ~= "string" or phase == "") and os.clock() - startedAt > P.ClearGrace then
				clearAll()
			end
			task.wait(P.PollSeconds)
		end
		polling = false
	end)
end

-- ===== Events =====

-- The run begins: the field is made ready, the squad stands in a row across the middle (a little towards the player, facing
-- away from them into the arena).
local function onStart(event: { [string]: any })
	-- (an Arena replay still playing shares ZombieFight's field: it ends first, so its finish cannot clear the run's)
	ArenaReplay.stop()
	clearAll()
	local plot = ZombieTeams.plot()
	if not plot or type(event.members) ~= "table" then
		return
	end
	local middle = Layout.arenaFrame(plot).Position
	centre = middle
	startedAt = os.clock()
	ZombieFight.setArena(middle, D.ArenaRadius)
	local toPlayer = flat(Layout.arenaPlayerSpot(plot).Position - middle)
	toPlayer = if toPlayer.Magnitude > 1e-3 then toPlayer.Unit else Vector3.zAxis
	local across = Vector3.new(-toPlayer.Z, 0, toPlayer.X)
	local members: { string } = event.members
	local roles: { [string]: string } = if type(event.roles) == "table" then event.roles else {}
	for index, id in members do
		local x = (index - (#members + 1) / 2) * V.FormationSpacing
		local back = P.SquadBack - (index % 2) * V.FormationStagger
		addSquad(id, roles[id] or "attack", middle + across * x + toPlayer * back, -toPlayer)
	end
	startPolling()
end

-- Health moves with the events at once: a blow takes from a monster, a heal gives back.
local function moveHealth(id: string, change: number)
	local body = bodies[id]
	if not body or not body.foe then
		return
	end
	local maxHp = attribute(body.node, "MaxHp", 1)
	body.node:SetAttribute("Hp", math.clamp(attribute(body.node, "Hp", maxHp) + change, 0, maxHp))
end

local function onFallen(event: { [string]: any })
	local id = event.to
	if type(id) ~= "string" or type(event.drops) ~= "table" then
		return
	end
	local body = bodies[id]
	local at = ZombieFight.where(id)
	if body and body.foe and at then
		moveHealth(id, -math.huge)
		local drops: { any } = event.drops
		task.delay(P.PopDelay, function()
			safe("drops", function()
				popDrops(at + Vector3.new(0, body.actor.body.Size.Y, 0), drops)
			end)
		end)
	end
end

local function onEvents(events: { any })
	for _, event in events do
		safe("event " .. tostring(event.kind), function()
			local kind = event.kind
			if kind == "start" then
				onStart(event)
			elseif kind == "spawn" then
				addMonster(event)
			elseif kind == "wave" then
				pcall(UiDungeon.banner, event.waveKind, event.wave)
			elseif kind == "hit" then
				if type(event.to) == "string" and type(event.amount) == "number" then
					moveHealth(event.to, -event.amount)
				end
			elseif kind == "heal" then
				if type(event.to) == "string" and type(event.amount) == "number" then
					moveHealth(event.to, event.amount)
				end
			elseif kind == "fallen" then
				onFallen(event)
			elseif kind == "leave" then
				clearAll()
			end
		end)
	end
end

function DungeonFight.start()
	ZombieFight.setDungeon(onEvents)
end

return DungeonFight
