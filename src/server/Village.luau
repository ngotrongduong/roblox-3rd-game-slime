--!strict
-- Server-authoritative village clocks and errands. Only lightweight intent is replicated.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brain = require(ReplicatedStorage.Shared.Brain)
local Config = require(ReplicatedStorage.Shared.Config)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Growth = require(ReplicatedStorage.Shared.Growth)
local Rng = require(ReplicatedStorage.Shared.Rng)
local Stats = require(ReplicatedStorage.Shared.Stats)
local VillageRules = require(ReplicatedStorage.Shared.Village)
local VillageSim = require(ReplicatedStorage.Shared.VillageSim)
local PlayerData = require(script.Parent.PlayerData)
local Spots = require(script.Parent.Spots)

type Farm = typeof(FarmState.newFarm(0))
type Spot = Spots.Spot
type Action = Brain.Action
type Actor = {
	current: Spot,
	from: Spot,
	to: Spot,
	action: Action?,
	route: { Spot },
	index: number,
	legStart: number,
	legEnd: number,
	finishAt: number,
	babyOnboard: boolean?,
}
type Session = {
	root: Folder,
	slimes: Folder,
	eggs: Folder,
	spots: { [string]: Spot },
	actors: { [string]: Actor },
	rng: typeof(Rng.new(0)),
	cursor: number,
	active: boolean,
}

local Village = {}
local VISUAL: { [string]: boolean } = {
	ghost = true,
	nursery = true,
	court = true,
	work = true,
	watchFish = true,
	flowers = true,
	splash = true,
	warm = true,
	wander = true,
	player = true,
}
local sessions: { [Player]: Session } = {}
local plotOwner: Player? = nil

local function set(inst: Instance, name: string, value: any)
	if inst:GetAttribute(name) ~= value then
		inst:SetAttribute(name, value)
	end
end

local function child(parent: Instance, name: string, className: string): Instance
	local inst = parent:FindFirstChild(name)
	if inst then
		return inst
	end
	local made = Instance.new(className)
	made.Name = name
	made.Parent = parent
	return made
end

local function point(s: Spot): Vector3
	return Vector3.new(s.x, s.y, s.z)
end

local function working(farm: Farm, id: string): string?
	for _, area in Config.Work.Areas do
		for _, slot in (farm.work :: any)[area].slots do
			if slot.worker == id or slot.reserve == id then
				return area
			end
		end
	end
	return nil
end

local function show(session: Session, farm: Farm, epoch: number)
	local root, slimes, eggs = session.root, session.slimes, session.eggs
	set(root, "Coins", farm.coins)
	set(root, "Storehouse", HttpService:JSONEncode(farm.storehouse))
	set(root, "Fridge", HttpService:JSONEncode(farm.fridge))
	set(root, "Population", #farm.slimes + #farm.eggs)
	set(root, "Limit", VillageRules.populationLimit(farm))
	set(root, "VillageLevel", VillageRules.level(farm))
	local live: { [string]: boolean } = {}
	for _, slime in farm.slimes do
		live[slime.id] = true
		local model = child(slimes, slime.id, "Configuration")
		local mutation = slime.appearanceMutation
		local actor = session.actors[slime.id]
		-- A carried baby borrows the adult's path, without creating a second moving part.
		for _, guardian in session.actors do
			if
				guardian.babyOnboard
				and guardian.action
				and guardian.action.kind == "walkBaby"
				and guardian.action.partner == slime.id
			then
				actor = guardian
				break
			end
		end
		local base = session.spots.plaza
		local from = if actor then actor.from else base
		local to = if actor then actor.to else base
		set(model, "Look", slime.assetId)
		set(model, "Colour", slime.visibleColour)
		set(model, "Material", if mutation.type == "material" then mutation.definitionId else nil)
		set(model, "DualId", if mutation.type == "dual" then mutation.definitionId else nil)
		set(model, "SecretId", if mutation.type == "secret" then mutation.definitionId else nil)
		set(
			model,
			"Scale",
			Growth.scale(
				slime.createdAt,
				epoch,
				Stats.level(slime.stats),
				farm.areas.breeding.level - Config.Village.StartLevel
			)
		)
		set(model, "Name", slime.name)
		set(model, "Trait", slime.trait)
		set(model, "Action", if actor and actor.action then actor.action.kind else "idle")
		set(model, "Emotion", if actor and actor.action then actor.action.emotion else "normal")
		set(model, "Carry", if actor and actor.action and actor.action.carry then actor.action.carry.item else "")
		set(model, "FromX", from.x)
		set(model, "FromY", from.y)
		set(model, "FromZ", from.z)
		set(model, "ToX", to.x)
		set(model, "ToY", to.y)
		set(model, "ToZ", to.z)
		set(model, "LegStart", if actor then actor.legStart else 0)
		set(model, "LegEnd", if actor then actor.legEnd else 0)
		set(model, "Ghost", slime.ghostUntil ~= nil and slime.ghostUntil > epoch)
		set(model, "Sleeping", slime.sleeping == true)
		set(model, "Working", working(farm, slime.id) or "")
	end
	for _, inst in slimes:GetChildren() do
		if not live[inst.Name] then
			inst:Destroy()
			session.actors[inst.Name] = nil
		end
	end
	local liveEggs: { [string]: boolean } = {}
	for _, egg in farm.eggs do
		liveEggs[egg.id] = true
		local model = child(eggs, egg.id, "Configuration")
		set(model, "Place", egg.place)
		set(model, "Slot", egg.slot)
		set(model, "HatchAt", egg.hatchAt or 0)
	end
	for _, inst in eggs:GetChildren() do
		if not liveEggs[inst.Name] then
			inst:Destroy()
		end
	end
end

local function route(session: Session, actor: Actor, action: Action, target: Spot): { Spot }
	local path: { Spot } = {}
	local current = actor.current
	local function add(spot: Spot?)
		if spot and (point(current) - point(spot)).Magnitude > 0 then
			table.insert(path, spot)
			current = spot
		end
	end
	local function travel(destination: Spot)
		if current.area ~= destination.area then
			if current.area ~= "plaza" and current.area ~= "gate" then
				add(session.spots["entrance:" .. current.area])
			end
			add(session.spots.plaza)
			if destination.area ~= "plaza" and destination.area ~= "gate" then
				add(session.spots["entrance:" .. destination.area])
			end
		end
		add(destination)
	end
	-- Pick up before delivery. Stock is actually committed only at the final destination.
	local pickup: Spot? = nil
	if action.kind == "carryBox" and action.source then
		pickup = session.spots["box:" .. action.source]
	elseif action.kind == "carryKitchen" then
		pickup = session.spots.storehouse
	elseif action.kind == "feedBaby" then
		pickup = session.spots[action.source or "storehouse"]
	elseif action.kind == "carryDish" then
		pickup = session.spots["box:kitchen"]
	elseif action.kind == "carryEgg" and action.source then
		pickup = session.spots[action.source]
	elseif action.kind == "walkBaby" then
		pickup = session.spots.nursery
	end
	if pickup then
		travel(pickup)
	end
	travel(target)
	if action.kind == "walkBaby" then
		-- The nursery is both the pickup and the safe return point for the child.
		travel(session.spots.nursery)
	end
	return path
end

-- The position is runtime-only; the server publishes each interpolation leg, not physical parts.
local function startLeg(actor: Actor, speed: number, when: number)
	local to = actor.route[actor.index]
	if not to then
		return
	end
	actor.from = actor.current
	actor.to = to
	actor.legStart = when
	actor.legEnd = when + (point(to) - point(actor.from)).Magnitude / speed
end

local function advance(
	player: Player,
	_session: Session,
	id: string,
	actor: Actor,
	speed: number,
	clock: number,
	epoch: number
)
	if not actor.action then
		return
	end
	while actor.index > 0 and clock >= actor.legEnd do
		local reachedAt = actor.legEnd
		actor.current = actor.to
		if actor.action.kind == "walkBaby" and actor.current.id == "nursery" then
			actor.babyOnboard = true
		end
		actor.index += 1
		if actor.route[actor.index] then
			startLeg(actor, speed, reachedAt)
		else
			actor.index = 0
			actor.from, actor.to = actor.current, actor.current
			actor.legStart, actor.legEnd = reachedAt, reachedAt
			local action = actor.action
			local did = false
			if action then
				PlayerData.update(player, function(farm: any)
					local _, applied = Brain.arrive(farm, id, action, epoch)
					did = applied
				end)
			end
			actor.finishAt = clock
				+ (if action and (did or VISUAL[action.kind]) then action.seconds else Config.Village.TickSeconds)
		end
	end
end

local function think(
	player: Player,
	session: Session,
	farm: Farm,
	slime: typeof(FarmState.newFarm(0).slimes[1]),
	clock: number,
	epoch: number
)
	local actor = session.actors[slime.id]
	local baby = Growth.isBaby(
		slime.createdAt,
		epoch,
		Stats.level(slime.stats),
		farm.areas.breeding.level - Config.Village.StartLevel
	)
	if not actor then
		local first = if baby then session.spots.nursery else session.spots.plaza
		actor = {
			current = first,
			from = first,
			to = first,
			route = {},
			index = 0,
			legStart = clock,
			legEnd = clock,
			finishAt = 0,
		}
		session.actors[slime.id] = actor
	end
	if actor.action then
		if actor.index > 0 or actor.finishAt > clock then
			return false
		end
		actor.action = nil
	end
	local nearby: { string } = {}
	for otherId, other in session.actors do
		if
			otherId ~= slime.id
			and (point(other.current) - point(actor.current)).Magnitude <= Config.Brain.NearbyStuds
		then
			table.insert(nearby, otherId)
		end
	end
	local playerPoint: Brain.Point? = nil
	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if
		rootPart
		and rootPart:IsA("BasePart")
		and (rootPart.Position - point(actor.current)).Magnitude <= Config.Brain.PlayerStuds
	then
		playerPoint = { x = rootPart.Position.X, y = rootPart.Position.Y, z = rootPart.Position.Z }
	end
	local action = Brain.choose(
		farm,
		slime.id,
		{ spots = session.spots, nearby = nearby, player = playerPoint },
		epoch,
		session.rng
	)
	actor.action = action
	actor.babyOnboard = action.kind == "walkBaby" and actor.current.id == "nursery"
	local target = session.spots[action.spot] or session.spots.plaza
	if action.spot == "player" and playerPoint then
		target = {
			id = "player",
			area = actor.current.area,
			x = playerPoint.x,
			y = playerPoint.y,
			z = playerPoint.z,
		}
	end
	actor.route = route(session, actor, action, target)
	actor.index = if #actor.route > 0 then 1 else 0
	if actor.index > 0 then
		local speed = Config.Village.WalkSpeed
			* (1 + (slime.stats.speed - Config.Stats.Starter.speed) * Config.Village.WalkPerSpeed)
		startLeg(actor, speed, clock)
	else
		local did = false
		PlayerData.update(player, function(data: any)
			local _, applied = Brain.arrive(data, slime.id, action, epoch)
			did = applied
		end)
		actor.finishAt = clock + (if did or VISUAL[action.kind] then action.seconds else Config.Village.TickSeconds)
		actor.from, actor.to = actor.current, actor.current
		actor.legStart, actor.legEnd = clock, clock
	end
	return true
end

local function tick(player: Player, session: Session)
	if not PlayerData.isReady(player) then
		return
	end
	local epoch = os.time()
	local clock = workspace:GetServerTimeNow()
	local events: { VillageSim.Event } = {}
	local farm: Farm? = nil
	-- A newly assigned worker must finish its route before the station earns output.
	local workReady: { [string]: string } = {}
	for id, actor in session.actors do
		if
			actor.action
			and actor.action.kind == "work"
			and actor.index == 0
			and actor.current.id == actor.action.spot
		then
			workReady[id] = actor.action.spot
		end
	end
	PlayerData.update(player, function(data: any)
		local elapsed = math.max(0, epoch - data.lastSimulatedAt)
		local courtReady: { [number]: boolean } = {}
		for index, pair in data.breeding.pairs do
			local a = if pair.a then session.actors[pair.a] else nil
			local b = if pair.b then session.actors[pair.b] else nil
			if
				a
				and b
				and a.action
				and b.action
				and a.action.kind == "court"
				and b.action.kind == "court"
				and a.index == 0
				and b.index == 0
				and a.current.area == "breeding"
				and b.current.area == "breeding"
			then
				courtReady[index] = true
			end
		end
		local nextFarm, changes = VillageSim.step(
			data,
			epoch,
			elapsed,
			session.rng,
			{ errands = false, workReady = workReady, courtReady = courtReady }
		)
		for key, value in nextFarm do
			data[key] = value
		end
		farm, events = data, changes
	end)
	if not farm then
		return
	end
	local snapshot = farm :: Farm
	for _, event in events do
		if event.kind == "laid" or event.kind == "hatched" then
			PlayerData.markKeyMoment(player, event.kind)
		end
	end
	for id, actor in session.actors do
		local slime = FarmState.findSlime(snapshot, id)
		if slime then
			local speed = Config.Village.WalkSpeed
				* (1 + (slime.stats.speed - Config.Stats.Starter.speed) * Config.Village.WalkPerSpeed)
			advance(player, session, id, actor, speed, clock, epoch)
		end
	end
	if #snapshot.slimes > 0 then
		local checked, thought = 0, 0
		while checked < #snapshot.slimes and thought < Config.Brain.ThinksPerTick do
			session.cursor = session.cursor % #snapshot.slimes + 1
			local slime = snapshot.slimes[session.cursor]
			if think(player, session, snapshot, slime, clock, epoch) then
				thought += 1
			end
			checked += 1
		end
	end
	show(session, snapshot, epoch)
end

function Village.ownsPlot(player: Player): boolean
	return plotOwner == player
end

function Village.start()
	PlayerData.onReady(function(player: Player, _data: any)
		if player.Parent ~= Players or not PlayerData.isReady(player) then
			return
		end
		-- Claim before catch-up so the visual stage restorer can see the owner on join.
		if not plotOwner then
			plotOwner = player
		end
		local epoch = os.time()
		local rng = Rng.new(player.UserId + epoch)
		local events: { VillageSim.Event } = {}
		PlayerData.update(player, function(farm: any)
			local last = farm.lastSimulatedAt
			local after, changes = VillageSim.catchUp(farm, last, epoch, rng)
			for key, value in after do
				farm[key] = value
			end
			events = changes
		end)
		for _, event in events do
			if event.kind == "laid" or event.kind == "hatched" then
				PlayerData.markKeyMoment(player, event.kind)
			end
		end
		if player.Parent ~= Players or not PlayerData.isReady(player) then
			return
		end
		local map = workspace:FindFirstChild("Map")
		local plot = if map and plotOwner == player then map:FindFirstChild("Plot" .. Config.Village.DevPlot) else nil
		local spots = Spots.build(Config.Village.DevPlot, plot)
		local world = child(workspace, "Villages", "Folder")
		local root = child(world, tostring(player.UserId), "Folder") :: Folder
		set(root, "Plot", if plotOwner == player then Config.Village.DevPlot else 0)
		local session: Session = {
			root = root,
			slimes = child(root, "Slimes", "Folder") :: Folder,
			eggs = child(root, "Eggs", "Folder") :: Folder,
			spots = spots,
			actors = {},
			rng = rng,
			cursor = 0,
			active = true,
		}
		sessions[player] = session
		local farm = PlayerData.get(player)
		if farm then
			show(session, farm, epoch)
		end
		task.spawn(function()
			while session.active and sessions[player] == session and PlayerData.isReady(player) do
				task.wait(Config.Village.TickSeconds)
				if session.active and sessions[player] == session then
					tick(player, session)
				end
			end
		end)
	end)
	PlayerData.onLeaving(function(player: Player, _data: any)
		local session = sessions[player]
		if session then
			session.active = false
			session.root:Destroy()
			sessions[player] = nil
		end
		if plotOwner == player then
			plotOwner = nil
		end
	end)
end

return Village
