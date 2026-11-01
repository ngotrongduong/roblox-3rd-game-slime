--!strict
-- The fight drawn. The server runs it (src/server/ZombieFights.luau) and sends Remotes.Fight events; this only draws them:
-- the squad pops in near its group and faces the zombies, fighters lunge as hits land, flinch, dodge, fall with floating
-- coins and leave when it ends. State follows the events even for a fight far from the camera; bodies, bars and particles
-- exist only while the group is near (ZombieWorld says so). One error never stops the drawing: per-fighter work is in pcall.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeLook = require(script.Parent.SlimeLook)
local UiKit = require(script.Parent.UiKit)
local ZombieLook = require(script.Parent.ZombieLook)
local ZombieWorld = require(script.Parent.ZombieWorld)

local V = Config.Zombies.View

type Fighter = {
	id: string,
	home: Vector3,
	facing: Vector3,
	model: Model?,
	actor: SlimeActor.Slime?,
	fallen: boolean,
}
type Fight = {
	id: string,
	groupId: string,
	fighters: { [string]: Fighter },
	order: { string },
	over: boolean,
}
type Bar = {
	gui: BillboardGui,
	fill: Frame,
	node: Configuration,
	connection: RBXScriptConnection,
}
type Anim = {
	actor: SlimeActor.Slime,
	home: Vector3,
	delta: Vector3,
	start: number,
	duration: number,
	-- "leave" walks the whole way; the others go out and come back
	leave: boolean,
	nextHop: number,
}

local ZombieFight = {}
local fights: { [string]: Fight } = {}
local bars: { [string]: Bar } = {}
local anims: { Anim } = {}
local animLoop: RBXScriptConnection? = nil
local syncing = false
local root: Instance? = nil
local numbersAlive = 0
local burstsAlive = 0
local warned: { [string]: boolean } = {}

local function safe(label: string, work: () -> ())
	local ok, err = pcall(function(): any
		work()
		return nil
	end)
	if not ok and not warned[label] then
		warned[label] = true
		warn(Config.LogPrefix, "zombie fight", label, "error:", err)
	end
end

local function number(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if type(value) == "number" and value == value then value else default
end

local function slimeNode(id: string): Configuration?
	local folder = if root then root:FindFirstChild("Slimes") else nil
	local found = if folder then folder:FindFirstChild(id) else nil
	return if found and found:IsA("Configuration") then found else nil
end

-- ===== Floating numbers and bursts =====

local function anchorAt(position: Vector3): Part
	local anchor = Instance.new("Part")
	anchor.Name = "FightFx"
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	return anchor
end

local function screenScale(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / 900, 0.7, 1.3) else 1
end

local function floatText(position: Vector3, text: string, colour: Color3, size: number)
	if numbersAlive >= V.MaxNumbers then
		return
	end
	numbersAlive += 1
	local jitter = Vector3.new((math.random() - 0.5) * 1.6, 0, (math.random() - 0.5) * 1.6)
	local anchor = anchorAt(position + jitter)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, size + 16)
	gui.AlwaysOnTop = true
	gui.MaxDistance = Config.Zombies.DrawDistance
	gui.LightInfluence = 0
	gui.Adornee = anchor
	gui.Parent = anchor
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextSize = size
	label.TextColor3 = colour
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(40, 28, 20)
	label.Parent = gui
	local info = TweenInfo.new(V.NumberSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = anchor.Position + Vector3.new(0, V.NumberRise, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(V.NumberSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(V.NumberSeconds + 0.1, function()
		numbersAlive -= 1
		anchor:Destroy()
	end)
end

local function emitter(texture: string, parent: Instance): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Rate = 0
	particles.Shape = Enum.ParticleEmitterShape.Box
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = parent
	return particles
end

-- A burst of coins and sparks (or only a puff) at a point; few particles, and never more than View.MaxBursts alive.
local function burst(position: Vector3, coins: boolean, tint: Color3, strength: number)
	if burstsAlive >= V.MaxBursts then
		return
	end
	burstsAlive += 1
	local anchor = anchorAt(position)
	local puff = emitter(V.PuffTexture, anchor)
	puff.Color = ColorSequence.new(tint)
	puff.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, V.Puff.size * 0.4),
		NumberSequenceKeypoint.new(1, V.Puff.size),
	})
	puff.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, V.Puff.transparency),
		NumberSequenceKeypoint.new(1, 1),
	})
	puff.Lifetime = NumberRange.new(V.Puff.life)
	puff.Speed = NumberRange.new(V.Puff.speedMin, V.Puff.speedMax)
	puff:Emit(math.floor(V.PuffBurst * strength))
	if coins then
		local spark = emitter(V.SparkTexture, anchor)
		spark.Color = ColorSequence.new(Color3.fromHex(V.Spark.colour))
		spark.LightEmission = 1
		spark.Size =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, V.Spark.size), NumberSequenceKeypoint.new(1, 0) })
		spark.Lifetime = NumberRange.new(V.Spark.life)
		spark.Speed = NumberRange.new(V.Spark.speedMin, V.Spark.speedMax)
		spark:Emit(math.floor(V.SparkBurst * strength))
		local id = (Config.Ui.Icons :: any).coins
		if type(id) == "number" and id > 0 then
			local coin = emitter("rbxassetid://" .. tostring(id), anchor)
			coin.Size = NumberSequence.new(V.Coin.size)
			coin.Lifetime = NumberRange.new(V.Coin.life)
			coin.Speed = NumberRange.new(V.Coin.speedMin, V.Coin.speedMax)
			coin.SpreadAngle = Vector2.new(35, 35)
			coin.EmissionDirection = Enum.NormalId.Top
			coin.Acceleration = Vector3.new(0, -V.Coin.gravity, 0)
			coin:Emit(math.floor(V.CoinBurst * strength))
		end
	end
	Debris:AddItem(anchor, V.BurstSeconds)
	task.delay(V.BurstSeconds, function()
		burstsAlive -= 1
	end)
end

-- ===== Motion =====

local function stopAnim(actor: SlimeActor.Slime)
	for index = #anims, 1, -1 do
		if anims[index].actor == actor then
			table.remove(anims, index)
		end
	end
end

local function stepAnims()
	local now = os.clock()
	for index = #anims, 1, -1 do
		local anim = anims[index]
		if anim.actor.destroyed then
			table.remove(anims, index)
		else
			safe("motion", function()
				local t = math.clamp((now - anim.start) / anim.duration, 0, 1)
				local k = if anim.leave then t else math.sin(math.pi * t)
				SlimeActor.setCFrame(anim.actor, CFrame.new(anim.home + anim.delta * k) * anim.actor.root.Rotation)
				if anim.leave and now >= anim.nextHop then
					anim.nextHop = now + V.LeaveHopSeconds
					SlimeActor.hop(anim.actor, V.LeaveHop)
				end
			end)
			if now - anim.start >= anim.duration and anims[index] == anim then
				table.remove(anims, index)
			end
		end
	end
	if #anims == 0 and animLoop then
		animLoop:Disconnect()
		animLoop = nil
	end
end

local function play(actor: SlimeActor.Slime, home: Vector3, delta: Vector3, seconds: number, leave: boolean)
	stopAnim(actor)
	table.insert(anims, {
		actor = actor,
		home = home,
		delta = delta,
		start = os.clock(),
		duration = seconds,
		leave = leave,
		nextHop = 0,
	})
	if not animLoop then
		animLoop = RunService.RenderStepped:Connect(stepAnims)
	end
end

-- ===== Who is who =====

-- The body and the standing place of a fighter or a zombie by its id (a zombie id never matches a slime of the squad).
local function find(id: string): (SlimeActor.Slime?, Vector3?, boolean)
	for _, fight in fights do
		local fighter = fight.fighters[id]
		if fighter then
			return fighter.actor, fighter.home, false
		end
	end
	local zombie = ZombieWorld.zombie(id)
	if zombie then
		return zombie.actor, zombie.spot, true
	end
	return nil, nil, true
end

local function flat(delta: Vector3): Vector3
	return Vector3.new(delta.X, 0, delta.Z)
end

local function destroyFighter(fighter: Fighter)
	if fighter.actor then
		stopAnim(fighter.actor)
		SlimeActor.destroy(fighter.actor)
		fighter.actor = nil
	end
	if fighter.model then
		fighter.model:Destroy()
		fighter.model = nil
	end
end

local function buildFighter(fighter: Fighter, pop: boolean)
	if fighter.model or fighter.fallen then
		return
	end
	local node = slimeNode(fighter.id)
	if not node then
		return
	end
	local model = SlimeLook.build({
		Colour = node:GetAttribute("Colour"),
		Material = node:GetAttribute("Material"),
		DualId = node:GetAttribute("DualId"),
		SecretId = node:GetAttribute("SecretId"),
		Scale = number(node, "Scale", 1),
	})
	model.Name = "Fighter_" .. fighter.id
	model:PivotTo(CFrame.lookAt(fighter.home, fighter.home + fighter.facing))
	model.Parent = workspace:FindFirstChild("ZombieClientActors") or workspace
	local actor = SlimeActor.new(model, V.FighterFace)
	if actor then
		actor.body.CanCollide = false
		if pop then
			SlimeActor.kick(actor, "squash", V.PopSquash)
			SlimeActor.hop(actor, V.PopHop)
		end
	end
	fighter.model, fighter.actor = model, actor
	if pop then
		burst(fighter.home, false, Color3.new(1, 1, 1), 0.6)
	end
end

-- ===== Health bars =====

local function dropBar(id: string)
	local bar = bars[id]
	if bar then
		bar.connection:Disconnect()
		bar.gui:Destroy()
		bars[id] = nil
	end
end

local function showBar(id: string, actor: SlimeActor.Slime, node: Configuration, ours: boolean)
	local bar = bars[id]
	if bar and bar.gui.Adornee == actor.body then
		return
	end
	dropBar(id)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HpBar"
	gui.Adornee = actor.body
	gui.Size = UDim2.fromOffset(V.BarWidth, V.BarHeight)
	gui.StudsOffset = Vector3.new(0, actor.body.Size.Y / 2 + V.BarLift, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = V.BarDistance
	gui.LightInfluence = 0
	gui.Parent = actor.body
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local track = UiKit.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
	}, gui)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
	local fill = UiKit.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour(if ours then "Green" else "Red"),
		BorderSizePixel = 0,
	}, track)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	local function update()
		local maxHp = math.max(number(node, "MaxHp", 1), 1)
		fill.Size = UDim2.fromScale(math.clamp(number(node, "Hp", maxHp) / maxHp, 0, 1), 1)
	end
	update()
	bars[id] =
		{ gui = gui, fill = fill, node = node, connection = node:GetAttributeChangedSignal("Hp"):Connect(update) }
end

-- Bodies and bars follow the group: drawn while it is near, gone when it is not (the fight itself goes on).
local function sync(fight: Fight)
	local group = ZombieWorld.group(fight.groupId)
	local near = group ~= nil and group.drawn
	local squad = if root then root:FindFirstChild("Squads") else nil
	local squadFolder = if squad then squad:FindFirstChild(fight.id) else nil
	for _, id in fight.order do
		local fighter = fight.fighters[id]
		if fighter then
			safe("sync " .. id, function()
				if near and not fight.over then
					buildFighter(fighter, true)
				elseif not near then
					destroyFighter(fighter)
				end
				local node = if squadFolder then squadFolder:FindFirstChild(id) else nil
				if
					near
					and not fight.over
					and not fighter.fallen
					and fighter.actor
					and node
					and node:IsA("Configuration")
				then
					showBar(id, fighter.actor, node, true)
				else
					dropBar(id)
				end
			end)
		end
	end
	if group then
		for id, entry in group.byId do
			safe("sync " .. id, function()
				if near and not fight.over and entry.actor and not ZombieWorld.isDead(id) then
					showBar(id, entry.actor, entry.config, false)
				else
					dropBar(id)
				end
			end)
		end
	end
end

local function syncLoop()
	if syncing then
		return
	end
	syncing = true
	task.spawn(function()
		while next(fights) ~= nil do
			for _, fight in fights do
				sync(fight)
			end
			task.wait(V.SyncSeconds)
		end
		syncing = false
	end)
end

-- ===== Events =====

local function onStart(squadId: string, event: { [string]: any })
	local group = ZombieWorld.group(event.group)
	local members: { string } = event.members
	local fight: Fight = { id = squadId, groupId = event.group, fighters = {}, order = {}, over = false }
	fights[squadId] = fight
	local facing = Vector3.zAxis
	local towards = Vector3.zAxis
	local centre = Vector3.zero
	if group then
		towards = ZombieWorld.towardVillage(group.position)
		facing = -towards
		centre = group.position
	end
	local across = Vector3.new(-towards.Z, 0, towards.X)
	for index, id in members do
		local offset = towards * V.FighterDistance + across * ((index - (#members + 1) / 2) * V.FighterSpacing)
		local home = ZombieWorld.groundAt(centre + offset)
		fight.fighters[id] = { id = id, home = home, facing = facing, model = nil, actor = nil, fallen = false }
		table.insert(fight.order, id)
	end
	sync(fight)
	syncLoop()
end

local function onHit(event: { [string]: any })
	local attacker, from = find(event.from)
	local target, to, foe = find(event.to)
	local crit = event.crit == true
	if attacker and from and target and to then
		play(attacker, from, flat(to - from) * V.LungeFraction, V.LungeSeconds, false)
		SlimeActor.hop(attacker, V.LungeHop)
	end
	if target then
		local side = if math.random() < 0.5 then -1 else 1
		SlimeActor.kick(target, "side", side * V.FlinchSide * (if crit then 2 else 1))
		SlimeActor.kick(target, "squash", V.FlinchSquash * (if crit then 2 else 1))
	end
	if target and to then
		local colours = V.NumberColours
		local hit = math.max(1, math.floor((event.amount or 0) + 0.5))
		floatText(
			to + Vector3.new(0, target.body.Size.Y, 0),
			(if crit then "-" .. hit .. "!" else "-" .. hit),
			Color3.fromHex(if crit then colours.Crit else (if foe then colours.Foe else colours.Ours)),
			if crit then V.CritTextSize else V.HitTextSize
		)
	end
end

local function onDodge(event: { [string]: any })
	local target, home = find(event.to)
	if target and home then
		local side = if math.random() < 0.5 then -1 else 1
		local across = Vector3.new(-target.root.LookVector.Z, 0, target.root.LookVector.X)
		play(target, home, across * side * V.DodgeStuds, V.DodgeSeconds, false)
		SlimeActor.hop(target, V.LungeHop)
	end
end

local function onFallen(event: { [string]: any })
	local id: string = event.to
	local coins: number = event.coins or 0
	local actor, spot, foe = find(id)
	local size = V.RewardTextSize
	local tint = Color3.fromRGB(150, 150, 150)
	if foe then
		local zombie = ZombieWorld.zombie(id)
		local look = if zombie then ZombieLook.look(zombie.kind) else nil
		if look then
			size = size * look.size
			tint = Color3.fromHex(look.burst)
		end
		ZombieWorld.kill(id)
		dropBar(id)
		if actor and spot then
			burst(spot + Vector3.new(0, 1.5, 0), true, tint, if look then look.size ^ 2 else 1)
		end
	else
		for _, fight in fights do
			local fighter = fight.fighters[id]
			if fighter then
				fighter.fallen = true
				dropBar(id)
				if actor and fighter.model then
					SlimeActor.setEmotion(actor, "sad")
					for _, part in fighter.model:GetDescendants() do
						if part:IsA("MeshPart") then
							TweenService
								:Create(part, TweenInfo.new(V.FadeSeconds), {
									Transparency = math.max(part.Transparency, Config.VillageClient.GhostTransparency),
									Color = part.Color:Lerp(Color3.new(1, 1, 1), V.FadeWhiten),
								})
								:Play()
						end
					end
				end
			end
		end
	end
	if actor and spot and coins > 0 then
		floatText(
			spot + Vector3.new(0, actor.body.Size.Y + 1, 0),
			"+" .. UiKit.money(coins),
			Color3.fromHex(V.NumberColours.Coins),
			size
		)
	end
end

local function onEnd(squadId: string, event: { [string]: any })
	local fight = fights[squadId]
	if not fight then
		return
	end
	fight.over = true
	for _, id in fight.order do
		dropBar(id)
	end
	local group = ZombieWorld.group(fight.groupId)
	if group then
		for id in group.byId do
			dropBar(id)
		end
	end
	for _, id in fight.order do
		local fighter = fight.fighters[id]
		if fighter and fighter.actor and not fighter.fallen then
			local towards = ZombieWorld.towardVillage(fighter.home)
			play(fighter.actor, fighter.home, towards * V.LeaveStuds, V.LeaveSeconds, true)
		end
	end
	local coins = event.coins
	if type(coins) == "number" and coins > 0 then
		pcall(UiKit.toast, "+" .. UiKit.money(coins))
	end
	task.delay(V.LeaveSeconds + 0.3, function()
		for _, fighter in fight.fighters do
			destroyFighter(fighter)
		end
		fights[squadId] = nil
	end)
end

local function onEvents(payload: any)
	if type(payload) ~= "table" or type(payload.squad) ~= "string" or type(payload.events) ~= "table" then
		return
	end
	for _, event in payload.events do
		safe("event " .. tostring(event.kind), function()
			local kind = event.kind
			if kind == "start" then
				onStart(payload.squad, event)
			elseif kind == "hit" then
				onHit(event)
			elseif kind == "dodge" then
				onDodge(event)
			elseif kind == "fallen" then
				onFallen(event)
			elseif kind == "end" then
				onEnd(payload.squad, event)
			end
		end)
	end
end

function ZombieFight.start()
	task.spawn(function()
		local villages = workspace:WaitForChild("Villages")
		root = villages:WaitForChild(tostring(Players.LocalPlayer.UserId))
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local remote = remotes:WaitForChild("Fight")
		if remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(onEvents)
		end
	end)
end

return ZombieFight
