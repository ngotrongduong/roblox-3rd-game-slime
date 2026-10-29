--!strict
-- Server-authoritative village clocks and errands. Only lightweight intent is replicated.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brain = require(ReplicatedStorage.Shared.Brain)
local Breeding = require(ReplicatedStorage.Shared.Breeding)
local Food = require(ReplicatedStorage.Shared.Food)
local VillageCarry = require(ReplicatedStorage.Shared.VillageCarry)
local VillagePath = require(ReplicatedStorage.Shared.VillagePath)
local Config = require(ReplicatedStorage.Shared.Config)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Growth = require(ReplicatedStorage.Shared.Growth)
local Rng = require(ReplicatedStorage.Shared.Rng)
local Stats = require(ReplicatedStorage.Shared.Stats)
local Stations = require(ReplicatedStorage.Shared.Stations)
local VillageRules = require(ReplicatedStorage.Shared.Village)
local VillageSim = require(ReplicatedStorage.Shared.VillageSim)
local PlayerData = require(script.Parent.PlayerData)
local Spots = require(script.Parent.Spots)

type Farm = typeof(FarmState.newFarm(0))
type Spot = Spots.Spot
type Action = Brain.Action
type Carried = {
	item: string,
	origin: string,
	eggId: string?,
	model: Model?,
}
type PathCache = { at: number, points: { Spot } }
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
	pickupId: string?,
	carrying: boolean?,
	lastRefresh: number?,
}
type Session = {
	root: Folder,
	slimes: Folder,
	eggs: Folder,
	spots: { [string]: Spot },
	actors: { [string]: Actor },
	reserved: { [string]: string },
	rng: typeof(Rng.new(0)),
	cursor: number,
	active: boolean,
	pathCache: { [string]: PathCache },
	pathWarnings: { [string]: number },
	carried: Carried?,
	prompts: { Instance },
	characterConnection: RBXScriptConnection?,
	deathConnection: RBXScriptConnection?,
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

local function working(farm: Farm, id: string): (string?, number, boolean)
	for _, area in Config.Work.Areas do
		for index, slot in (farm.work :: any)[area].slots do
			if slot.worker == id then
				return area, index, false
			elseif slot.reserve == id then
				return area, index, true
			end
		end
	end
	return nil, 0, false
end

local function release(session: Session, id: string, action: Action?)
	if not action then
		return
	end
	for _, key in Brain.reservationKeys(action) do
		if session.reserved[key] == id then
			session.reserved[key] = nil
		end
	end
end

local function claim(session: Session, id: string, action: Action)
	for _, key in Brain.reservationKeys(action) do
		session.reserved[key] = id
	end
end

local function show(session: Session, farm: Farm, epoch: number)
	local root, slimes, eggs = session.root, session.slimes, session.eggs
	set(root, "Coins", farm.coins)
	set(root, "Storehouse", HttpService:JSONEncode(farm.storehouse))
	set(root, "Fridge", HttpService:JSONEncode(farm.fridge))
	set(root, "Population", #farm.slimes + #farm.eggs)
	set(root, "Limit", VillageRules.populationLimit(farm))
	set(root, "VillageLevel", VillageRules.level(farm))
	-- Only public management state is replicated; unborn eggs remain secret.
	local areas: { [string]: number } = {}
	for _, area in Config.Village.Areas do
		areas[area] = (farm.areas :: any)[area].level
	end
	local work: { [string]: { { [string]: any } } } = {}
	local boxes: { [string]: { [string]: number } } = {}
	for _, area in Config.Work.Areas do
		local areaWork = (farm.work :: any)[area]
		local slots: { { [string]: any } } = {}
		local cycle = Stations.cycleSeconds(area, (farm.areas :: any)[area].level)
		for _, slot in areaWork.slots do
			table.insert(slots, {
				worker = slot.worker or "",
				reserve = slot.reserve or "",
				stat = slot.stat or "",
				progress = math.clamp(slot.progress / cycle, 0, 1),
			})
		end
		work[area] = slots
		boxes[area] = areaWork.box
	end
	set(root, "Work", HttpService:JSONEncode(work))
	set(root, "Pairs", HttpService:JSONEncode(farm.breeding.pairs))
	set(root, "Areas", HttpService:JSONEncode(areas))
	set(root, "Box", HttpService:JSONEncode(boxes))
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
		set(
			model,
			"Carry",
			if actor and actor.carrying and actor.index > 0 and actor.action
				then (if actor.action.kind == "carryEgg" then "Egg" else if actor.action.carry then actor.action.carry.item else "")
				else ""
		)
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
		local area, slot, isReserve = working(farm, slime.id)
		set(model, "Working", area or "")
		set(model, "WorkArea", area or "")
		set(model, "WorkSlot", slot)
		set(model, "Reserve", isReserve)
		set(model, "Fullness", slime.needs.fullness)
		set(model, "Energy", slime.needs.energy)
		set(model, "Fun", slime.needs.fun)
		set(model, "Level", Stats.level(slime.stats))
		set(model, "Attack", slime.stats.attack)
		set(model, "Defence", slime.stats.defence)
		set(model, "Speed", slime.stats.speed)
		set(model, "Hp", slime.stats.hp)
		set(
			model,
			"Baby",
			Growth.isBaby(
				slime.createdAt,
				epoch,
				Stats.level(slime.stats),
				farm.areas.breeding.level - Config.Village.StartLevel
			)
		)
		set(model, "CookedAllowed", table.find(farm.cookedAllowed, slime.id) ~= nil)
		local pairIndex = 0
		for index, pair in farm.breeding.pairs do
			if pair.a == slime.id or pair.b == slime.id then
				pairIndex = index
				break
			end
		end
		set(model, "PairIndex", pairIndex)
		set(model, "Partner", if actor and actor.action then actor.action.partner or "" else "")
	end
	for _, inst in slimes:GetChildren() do
		if not live[inst.Name] then
			inst:Destroy()
			local departing = session.actors[inst.Name]
			if departing then
				release(session, inst.Name, departing.action)
			end
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
		local held = session.carried
		local hidden = held ~= nil and held.eggId == egg.id
		if not hidden then
			for _, courier in session.actors do
				if courier.carrying and courier.index > 0 and courier.action and courier.action.eggId == egg.id then
					hidden = true
					break
				end
			end
		end
		set(model, "Held", hidden)
	end
	for _, inst in eggs:GetChildren() do
		if not liveEggs[inst.Name] then
			inst:Destroy()
		end
	end
end

-- Stop at a safe social distance instead of trying to occupy a character or another slime.
local function stopShort(origin: Spot, target: Spot): Spot
	local delta = point(target) - point(origin)
	local flat = Vector3.new(delta.X, 0, delta.Z)
	if flat.Magnitude <= Config.Brain.StopStuds then
		return { id = target.id, area = origin.area, x = origin.x, y = origin.y, z = origin.z }
	end
	local position = point(target) - flat.Unit * Config.Brain.StopStuds
	return { id = target.id, area = target.area, x = position.X, y = origin.y, z = position.Z }
end

-- Path computations use the real plot's navigation mesh; cache only unchanged fixed markers.
local function fixed(session: Session, spot: Spot): boolean
	local known = session.spots[spot.id]
	return known ~= nil and (point(known) - point(spot)).Magnitude <= Config.Village.PathPointEpsilon
end

local function pathBetween(session: Session, start: Spot, target: Spot, scale: number): { Spot }?
	local radius = math.max(Config.Village.PathMinRadius, Config.Village.PathRadiusPerScale * scale)
	local cacheKey: string? = nil
	if fixed(session, start) and fixed(session, target) then
		cacheKey = start.id .. ">" .. target.id .. ":" .. tostring(radius)
		local cached = session.pathCache[cacheKey]
		if cached and os.clock() - cached.at < Config.Village.PathCacheSeconds then
			return table.clone(cached.points)
		end
	end
	local path = PathfindingService:CreatePath({
		AgentRadius = radius,
		AgentHeight = math.max(Config.Village.PathHeightPerScale * scale, radius * 2),
		AgentCanJump = false,
		WaypointSpacing = Config.Village.PathWaypointStuds,
	})
	local ok = pcall(function()
		path:ComputeAsync(point(start), point(target))
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		return nil
	end
	local waypoints = path:GetWaypoints()
	if #waypoints == 0 then
		return nil
	end
	local points: { Spot } = {}
	for index, waypoint in waypoints do
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			return nil
		end
		if index > 1 and index < #waypoints then
			table.insert(points, {
				id = "via",
				area = start.area,
				x = waypoint.Position.X,
				y = waypoint.Position.Y,
				z = waypoint.Position.Z,
			})
		end
	end
	table.insert(points, target)
	local merged = VillagePath.merge(start, points)
	if cacheKey then
		session.pathCache[cacheKey] = { at = os.clock(), points = table.clone(merged) }
	end
	return merged
end

local function route(session: Session, actor: Actor, action: Action, target: Spot, scale: number): { Spot }
	local path: { Spot } = {}
	local current = actor.current
	local function add(spot: Spot?)
		if spot and (point(current) - point(spot)).Magnitude > Config.Village.PathPointEpsilon then
			table.insert(path, spot)
			current = spot
		elseif spot and spot.id ~= "via" and current.id ~= spot.id then
			-- A same-position service marker still matters to pickup / nursery state.
			table.insert(path, spot)
			current = spot
		end
	end
	local function fallback(destination: Spot)
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
	local function travel(destination: Spot)
		local start = current
		if (point(start) - point(destination)).Magnitude <= Config.Village.PathPointEpsilon then
			add(destination)
			return
		end
		local waypoints = pathBetween(session, start, destination, scale)
		if waypoints then
			for _, waypoint in waypoints do
				add(waypoint)
			end
		else
			local key = start.id .. " > " .. destination.id
			local clock = os.clock()
			if clock - (session.pathWarnings[key] or -math.huge) >= Config.Village.PathWarningSeconds then
				session.pathWarnings[key] = clock
				warn(Config.LogPrefix, "village path failed:", key, "- using plaza route")
			end
			fallback(destination)
		end
	end
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
	actor.pickupId = if pickup then pickup.id else nil
	actor.carrying = pickup ~= nil and actor.current.id == pickup.id
	if pickup then
		travel(pickup)
	end
	travel(target)
	if action.kind == "walkBaby" then
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
	actor.legEnd = when + VillagePath.duration((point(to) - point(actor.from)).Magnitude, speed)
end

local function advance(
	player: Player,
	session: Session,
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
		if actor.pickupId and actor.current.id == actor.pickupId then
			actor.carrying = true
		end
		if actor.action.kind == "walkBaby" and actor.current.id == "nursery" then
			actor.babyOnboard = true
		end
		actor.index += 1
		if actor.route[actor.index] then
			startLeg(actor, speed, reachedAt)
		else
			actor.index = 0
			actor.carrying = false
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
			release(session, id, action)
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
		local centre = if baby then session.spots.nursery else session.spots.plaza
		local count = 0
		for _, other in session.actors do
			if other.current.id == centre.id then
				count += 1
			end
		end
		-- New slimes need their own standing place before their first action is selected.
		local angle = (count % Config.Brain.SpotSpreadPlaces) * math.pi * 2 / Config.Brain.SpotSpreadPlaces
		local radius = (math.floor(count / Config.Brain.SpotSpreadPlaces) + 1) * Config.Brain.SpotSpread
		local first: Spot = {
			id = centre.id,
			area = centre.area,
			x = centre.x + math.cos(angle) * radius,
			y = centre.y,
			z = centre.z + math.sin(angle) * radius,
		}
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
		release(session, slime.id, actor.action)
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
		{ spots = session.spots, nearby = nearby, player = playerPoint, reserved = session.reserved },
		epoch,
		session.rng
	)
	claim(session, slime.id, action)
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
	-- Moving targets have a four-stud buffer; stationary targets get distinct standing places.
	local partner = if action.partner then session.actors[action.partner] else nil
	if action.kind == "player" and playerPoint then
		target = stopShort(actor.current, target)
	elseif
		partner
		and (
			action.kind == "chat"
			or action.kind == "greet"
			or action.kind == "argue"
			or action.kind == "makeup"
			or action.kind == "tag"
			or action.kind == "playBaby"
			or action.kind == "feedBaby"
		)
	then
		target = stopShort(actor.current, partner.to)
	elseif action.spot ~= "player" then
		local order = 1
		for otherId, other in session.actors do
			local otherSpot = if other.action then session.spots[other.action.spot] else nil
			if
				otherId ~= slime.id
				and (
					(other.action and other.action.spot == action.spot)
					or (otherSpot and (point(otherSpot) - point(target)).Magnitude <= Config.Brain.StopStuds)
					or (point(other.current) - point(target)).Magnitude <= Config.Brain.StopStuds
					or (point(other.to) - point(target)).Magnitude <= Config.Village.PathAvoidStuds
					or (other.route[#other.route] ~= nil and (point(other.route[#other.route]) - point(target)).Magnitude <= Config.Village.PathAvoidStuds)
				)
			then
				order += 1
			end
		end
		if order > 1 then
			local index = order - 2
			local angle = (index % Config.Brain.SpotSpreadPlaces) * math.pi * 2 / Config.Brain.SpotSpreadPlaces
			local radius = (math.floor(index / Config.Brain.SpotSpreadPlaces) + 1) * Config.Brain.SpotSpread
			target = {
				id = target.id,
				area = target.area,
				x = target.x + math.cos(angle) * radius,
				y = target.y,
				z = target.z + math.sin(angle) * radius,
			}
		end
	end
	local scale = Growth.scale(
		slime.createdAt,
		epoch,
		Stats.level(slime.stats),
		farm.areas.breeding.level - Config.Village.StartLevel
	)
	actor.route = route(session, actor, action, target, scale)
	actor.lastRefresh = clock
	actor.index = if #actor.route > 0 then 1 else 0
	if actor.index > 0 then
		local speed = Config.Village.WalkSpeed
			* (1 + (slime.stats.speed - Config.Stats.Starter.speed) * Config.Village.WalkPerSpeed)
		startLeg(actor, speed, clock)
	else
		-- Already close enough to walk nowhere: it is now AT the action's spot (a worker standing near its work spot
		-- would otherwise never count as arrived, and its station would never earn).
		actor.current = {
			id = target.id,
			area = target.area,
			x = actor.current.x,
			y = actor.current.y,
			z = actor.current.z,
		}
		local did = false
		PlayerData.update(player, function(data: any)
			local _, applied = Brain.arrive(data, slime.id, action, epoch)
			did = applied
		end)
		release(session, slime.id, action)
		actor.finishAt = clock + (if did or VISUAL[action.kind] then action.seconds else Config.Village.TickSeconds)
		actor.from, actor.to = actor.current, actor.current
		actor.carrying = false
		actor.legStart, actor.legEnd = clock, clock
	end
	return true
end

-- Player and social targets move; replan only when they moved far enough and after a cooldown.
local function refreshMoving(
	player: Player,
	session: Session,
	farm: Farm,
	id: string,
	actor: Actor,
	clock: number,
	epoch: number
)
	local action = actor.action
	if not action or actor.index == 0 or actor.pickupId then
		return
	end
	if clock - (actor.lastRefresh or 0) < Config.Village.PathRefreshSeconds then
		return
	end
	actor.lastRefresh = clock
	local target: Spot? = nil
	if action.kind == "player" then
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			target = { id = "player", area = actor.current.area, x = root.Position.X, y = root.Position.Y, z = root.Position.Z }
		end
	elseif action.partner and (
		action.kind == "chat" or action.kind == "greet" or action.kind == "argue"
		or action.kind == "makeup" or action.kind == "tag" or action.kind == "playBaby"
	) then
		local other = session.actors[action.partner]
		if other then
			target = other.to
		end
	end
	if not target then
		return
	end
	local fraction = VillagePath.progress(actor.legStart, actor.legEnd, clock)
	local position = point(actor.from):Lerp(point(actor.to), fraction)
	local start: Spot = { id = "via", area = actor.from.area, x = position.X, y = position.Y, z = position.Z }
	target = stopShort(start, target)
	local destination = actor.route[#actor.route]
	if destination and (point(destination) - point(target)).Magnitude < Config.Village.PathRefreshStuds then
		return
	end
	local slime = FarmState.findSlime(farm, id)
	if not slime then
		return
	end
	actor.current = start
	local scale = Growth.scale(
		slime.createdAt, epoch, Stats.level(slime.stats),
		farm.areas.breeding.level - Config.Village.StartLevel
	)
	actor.route = route(session, actor, action, target, scale)
	actor.index = if #actor.route > 0 then 1 else 0
	if actor.index > 0 then
		local speed = Config.Village.WalkSpeed
			* (1 + (slime.stats.speed - Config.Stats.Starter.speed) * Config.Village.WalkPerSpeed)
		startLeg(actor, speed, clock)
	end
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
			refreshMoving(player, session, snapshot, id, actor, clock, epoch)
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
			reserved = {},
			rng = rng,
			cursor = 0,
			active = true,
			pathCache = {},
			pathWarnings = {},
			carried = nil,
			prompts = {},
			characterConnection = nil,
			deathConnection = nil,
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
