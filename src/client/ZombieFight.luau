--!strict
-- The fight drawn. The server runs it (src/server/ZombieFights.luau) and sends Remotes.Fight events; this only draws them
-- on the bodies of the march (ZombieMarch stands the team's slimes at the end of the leg, facing the zombies): fighters
-- lunge as hits land, flinch, dodge and fall with floating coins; when it ends the team turns round and hops home on the
-- march, and the "home" event brings the notice. State follows the events even for a fight far from the camera; bodies,
-- bars and particles exist only while the group or the team is near. One error never stops the drawing: per-fighter work is
-- in pcall.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeActor = require(script.Parent.SlimeActor)
local UiKit = require(script.Parent.UiKit)
local UiTeams = require(script.Parent.UiTeams)
local ZombieLook = require(script.Parent.ZombieLook)
local ZombieMarch = require(script.Parent.ZombieMarch)
local ZombieTeams = require(script.Parent.ZombieTeams)
local ZombieWorld = require(script.Parent.ZombieWorld)

local V = Config.Zombies.View

type Fighter = {
	id: string,
	fallen: boolean,
}
type Fight = {
	team: number,
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
}

local ZombieFight = {}
local fights: { [number]: Fight } = {}
local bars: { [string]: Bar } = {}
local anims: { Anim } = {}
local animLoop: RBXScriptConnection? = nil
local syncing = false
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

-- The lunge and the dodge: out and back from the standing place, once.
local function stepAnims()
	local now = os.clock()
	for index = #anims, 1, -1 do
		local anim = anims[index]
		if anim.actor.destroyed then
			table.remove(anims, index)
		else
			safe("motion", function()
				local t = math.clamp((now - anim.start) / anim.duration, 0, 1)
				local k = math.sin(math.pi * t)
				SlimeActor.setCFrame(anim.actor, CFrame.new(anim.home + anim.delta * k) * anim.actor.root.Rotation)
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

local function play(actor: SlimeActor.Slime, home: Vector3, delta: Vector3, seconds: number)
	stopAnim(actor)
	table.insert(anims, {
		actor = actor,
		home = home,
		delta = delta,
		start = os.clock(),
		duration = seconds,
	})
	if not animLoop then
		animLoop = RunService.RenderStepped:Connect(stepAnims)
	end
end

-- ===== Who is who =====

-- The body and the standing place of a fighter (a body of the march) or a zombie by its id; the last is whether it is a
-- zombie (a zombie id never matches a slime of a team).
local function find(id: string): (SlimeActor.Slime?, Vector3?, boolean)
	for _, fight in fights do
		if fight.fighters[id] then
			local body = ZombieMarch.body(id)
			if body then
				return body.actor, body.stand, false
			end
			return nil, nil, false
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

-- Bars follow the bodies: drawn while the team or the group is near, gone when it is not (the fight itself goes on).
local function sync(fight: Fight)
	local group = ZombieWorld.group(fight.groupId)
	local team = ZombieTeams.get(fight.team)
	for _, id in fight.order do
		local fighter = fight.fighters[id]
		if fighter then
			safe("sync " .. id, function()
				local body = ZombieMarch.body(id)
				local node = if team then team.node:FindFirstChild(id) else nil
				if not fight.over and not fighter.fallen and body and node and node:IsA("Configuration") then
					showBar(id, body.actor, node, true)
				else
					dropBar(id)
				end
			end)
		end
	end
	if group then
		for id, entry in group.byId do
			safe("sync " .. id, function()
				if group.drawn and not fight.over and entry.actor and not ZombieWorld.isDead(id) then
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

local function onStart(teamIndex: number, event: { [string]: any })
	local members: { string } = event.members
	local fight: Fight = { team = teamIndex, groupId = event.group, fighters = {}, order = {}, over = false }
	fights[teamIndex] = fight
	for _, id in members do
		fight.fighters[id] = { id = id, fallen = false }
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
		play(attacker, from, flat(to - from) * V.LungeFraction, V.LungeSeconds)
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
		play(target, home, across * side * V.DodgeStuds, V.DodgeSeconds)
		SlimeActor.hop(target, V.LungeHop)
	end
end

local function onFallen(event: { [string]: any })
	local id: string = event.to
	local coins: number = event.coins or 0
	local actor, spot, foe = find(id)
	local size = V.RewardTextSize
	if foe then
		local tint = Color3.fromRGB(150, 150, 150)
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
				local body = ZombieMarch.body(id)
				if actor and body then
					SlimeActor.setEmotion(actor, "sad")
					for _, part in body.model:GetDescendants() do
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

-- The fight is over: the bars go; the team's bodies turn round and hop home on the march (the server has set them going).
local function onEnd(teamIndex: number)
	local fight = fights[teamIndex]
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
	task.delay(V.SyncSeconds * 2, function()
		if fights[teamIndex] == fight then
			fights[teamIndex] = nil
		end
	end)
end

-- The team is back at the gate: the small notice says which, how many died and what it earned.
local function onHome(payload: { [string]: any }, event: { [string]: any })
	local team = event.team
	local dead = event.dead
	local coins = event.coins
	pcall(
		UiTeams.notice,
		if type(team) == "number" then team else payload.team,
		if type(dead) == "number" then dead else 0,
		if type(coins) == "number" then coins else 0
	)
end

local function onEvents(payload: any)
	if type(payload) ~= "table" or type(payload.team) ~= "number" or type(payload.events) ~= "table" then
		return
	end
	for _, event in payload.events do
		safe("event " .. tostring(event.kind), function()
			local kind = event.kind
			if kind == "start" then
				onStart(payload.team, event)
			elseif kind == "hit" then
				onHit(event)
			elseif kind == "dodge" then
				onDodge(event)
			elseif kind == "fallen" then
				onFallen(event)
			elseif kind == "end" then
				onEnd(payload.team)
			elseif kind == "home" then
				onHome(payload, event)
			end
		end)
	end
end

function ZombieFight.start()
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local remote = remotes:WaitForChild("Fight")
		if remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(onEvents)
		end
	end)
end

return ZombieFight
