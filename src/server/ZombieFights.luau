--!strict
-- The zombie slimes outside the village and the fights against them (docs/ECONOMY.md, the owner 2026-11-02).
-- The server owns everything: the camps, the groups, every roll, the fight and the coins of each death. Clients only
-- read the folders published under workspace.Villages.<id> and the Remotes.Fight event, and draw.
--   Camps/<groupId>   Configuration: Camp, Index, Level, Position, State ("waiting" | "fighting" | "gone"),
--                     RespawnAt (server unix seconds, 0 unless gone), Squad ("" or the squad fighting it)
--     <zombieId>      Configuration: Kind, Level, Hp, MaxHp
--   Squads/<squadId>  Configuration: Group, Camp, State ("fighting"), Members (slime ids, comma separated), StartedAt
--     <slimeId>       Configuration: Hp, MaxHp
--   Remotes.Fight     RemoteEvent to the owner: ({ squad = squadId, events = { event } })
--     event           { kind = "start" | "hit" | "dodge" | "fallen" | "end", ... } (see ZombieFights.start)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Config = require(ReplicatedStorage.Shared.Config)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Rng = require(ReplicatedStorage.Shared.Rng)
local Zombies = require(ReplicatedStorage.Shared.Zombies)
local PlayerData = require(script.Parent.PlayerData)
local Village = require(script.Parent.Village)

type Zombie = typeof(Zombies.make("z", "rotten", 1, 1))
type Fight = typeof(Combat.new({}, {}, Rng.new(0)))
type Group = {
	id: string,
	camp: number,
	index: number,
	playerLevel: number,
	zombies: { Zombie },
	byId: { [string]: Zombie },
	state: string,
	respawnAt: number,
	position: Vector3,
	folder: Configuration,
	squad: string,
}
type Squad = {
	id: string,
	group: Group,
	members: { string },
	fight: Fight,
	folder: Configuration,
	nodes: { [string]: Configuration },
	coins: number,
}
type Session = {
	player: Player,
	camps: Folder,
	squads: Folder,
	groups: { [string]: Group },
	order: { Group },
	squadList: { Squad },
	rng: typeof(Rng.new(0)),
	serial: number,
	squadSerial: number,
	accumulator: number,
}

local ZombieFights = {}
local sessions: { [Player]: Session } = {}
local fightRemote: RemoteEvent? = nil

local function set(inst: Instance, name: string, value: any)
	if inst:GetAttribute(name) ~= value then
		inst:SetAttribute(name, value)
	end
end

local function make(parent: Instance, name: string): Configuration
	local made = Instance.new("Configuration")
	made.Name = name
	made.Parent = parent
	return made
end

-- The ground under a point, by a ray from above (the map's ground height is the fallback).
local function groundAt(x: number, z: number): number
	local zc = Config.Zombies
	local ignore: { Instance } = {}
	local villages = workspace:FindFirstChild("Villages")
	if villages then
		table.insert(ignore, villages)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local top = Config.Map.GroundY + zc.GroundProbeUp
	local hit =
		workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -(zc.GroundProbeUp + zc.GroundProbeDown), 0), params)
	return if hit then hit.Position.Y else Config.Map.GroundY
end

local function publishGroup(group: Group)
	local folder = group.folder
	set(folder, "Camp", group.camp)
	set(folder, "Index", group.index)
	set(folder, "Level", group.zombies[1].level)
	set(folder, "Position", group.position)
	set(folder, "State", group.state)
	set(folder, "RespawnAt", if group.state == "gone" then group.respawnAt else 0)
	set(folder, "Squad", group.squad)
end

-- A fresh group of the camp, at the player's level of this moment.
local function spawn(session: Session, group: Group, playerLevel: number)
	session.serial += 1
	group.playerLevel = playerLevel
	group.zombies = Zombies.group(group.id .. "-" .. session.serial, playerLevel, group.camp, session.rng)
	group.byId = {}
	group.folder:ClearAllChildren()
	for _, zombie in group.zombies do
		group.byId[zombie.id] = zombie
		local node = make(group.folder, zombie.id)
		set(node, "Kind", zombie.kind)
		set(node, "Level", zombie.level)
		set(node, "MaxHp", zombie.hp)
		set(node, "Hp", zombie.hp)
	end
	group.state = "waiting"
	group.squad = ""
	group.respawnAt = 0
	publishGroup(group)
end

local function fire(session: Session, squadId: string, events: { any })
	local remote = fightRemote
	if remote and #events > 0 then
		remote:FireClient(session.player, { squad = squadId, events = events })
	end
end

local function openSession(player: Player, root: Folder, farm: any, now: number): Session
	local session: Session = {
		player = player,
		camps = Instance.new("Folder"),
		squads = Instance.new("Folder"),
		groups = {},
		order = {},
		squadList = {},
		rng = Rng.new(player.UserId + now),
		serial = 0,
		squadSerial = 0,
		accumulator = 0,
	}
	session.camps.Name = "Camps"
	session.camps.Parent = root
	session.squads.Name = "Squads"
	session.squads.Parent = root
	local gate = Layout.plotGate(Config.Village.DevPlot)
	local level = Zombies.playerLevel(farm, now)
	for camp = 1, #Config.Zombies.LevelOffsets do
		for index = 1, Config.Zombies.GroupsPerCamp do
			local across, forward = Zombies.campOffset(camp, index)
			-- the gate looks at the valley centre: local -Z is the way out
			local flat = (gate * CFrame.new(across, 0, -forward)).Position
			local id = "c" .. camp .. "g" .. index
			local group: Group = {
				id = id,
				camp = camp,
				index = index,
				playerLevel = level,
				zombies = {},
				byId = {},
				state = "waiting",
				respawnAt = 0,
				position = Vector3.new(flat.X, groundAt(flat.X, flat.Z), flat.Z),
				folder = make(session.camps, id),
				squad = "",
			}
			session.groups[id] = group
			table.insert(session.order, group)
			spawn(session, group, level)
		end
	end
	print(
		Config.LogPrefix,
		"zombies:",
		#session.order,
		"groups out in",
		#Config.Zombies.LevelOffsets,
		"camps, level",
		level
	)
	return session
end

local function finish(session: Session, squad: Squad, winner: string, now: number)
	local player = session.player
	for _, id in squad.members do
		Village.setOut(player, id, false)
	end
	local group = squad.group
	local events: { any } = { { kind = "end", winner = winner, coins = squad.coins } }
	if winner == "squad" then
		group.state = "gone"
		group.squad = ""
		group.respawnAt = now + Config.Zombies.RespawnSeconds
		publishGroup(group)
	else
		-- the zombies beat the squad (or neither won in time): the group stands again, whole
		spawn(session, group, group.playerLevel)
	end
	fire(session, squad.id, events)
	local index = table.find(session.squadList, squad)
	if index then
		table.remove(session.squadList, index)
	end
	squad.folder:Destroy()
	print(Config.LogPrefix, "zombies:", squad.id, "ended against", group.id, "winner", winner, "coins", squad.coins)
end

local function stepSquad(session: Session, squad: Squad, now: number)
	local fight = squad.fight
	local events = Combat.step(fight, Config.Zombies.FightStepSeconds)
	local out: { any } = {}
	local fallen: { any } = {}
	for _, event in events do
		local entry: { [string]: any } = {
			kind = event.kind,
			from = event.from,
			to = event.to,
			amount = event.amount,
			crit = event.crit,
		}
		table.insert(out, entry)
		if event.kind == "fallen" then
			table.insert(fallen, entry)
		end
	end
	for _, unit in fight.units do
		local node = squad.nodes[unit.id]
		if node then
			set(node, "Hp", unit.hp)
		end
	end
	if #fallen > 0 then
		-- Every slime that falls, on either side, pays at once.
		PlayerData.update(session.player, function(farm: any)
			for _, entry in fallen do
				local zombie = squad.group.byId[entry.to]
				if zombie then
					local reward = Zombies.killReward(zombie.kind, zombie.level)
					Zombies.pay(farm, reward)
					entry.coins = reward
				else
					entry.coins = Zombies.fall(farm, entry.to, now)
				end
			end
		end)
		PlayerData.markKeyMoment(session.player, "zombie fight")
		for _, entry in fallen do
			squad.coins += entry.coins or 0
			print(Config.LogPrefix, "zombies:", entry.to, "fell in", squad.id, "paid", entry.coins or 0)
		end
	end
	fire(session, squad.id, out)
	if fight.winner then
		finish(session, squad, fight.winner, now)
	elseif fight.seconds >= Config.Zombies.FightMaxSeconds then
		finish(session, squad, "draw", now)
	end
end

local function frame(session: Session, dt: number)
	local now = os.time()
	for _, group in session.order do
		if group.state == "gone" and now >= group.respawnAt then
			local farm = PlayerData.get(session.player)
			if farm then
				spawn(session, group, Zombies.playerLevel(farm, now))
				print(Config.LogPrefix, "zombies:", group.id, "is back at level", group.zombies[1].level)
			end
		end
	end
	local step = Config.Zombies.FightStepSeconds
	session.accumulator = math.min(session.accumulator + dt, step * Config.Zombies.MaxStepsPerFrame)
	while session.accumulator >= step do
		session.accumulator -= step
		for index = #session.squadList, 1, -1 do
			local squad = session.squadList[index]
			if squad then
				stepSquad(session, squad, now)
			end
		end
	end
end

-- Sends a squad at a waiting group. Called inside the PlayerData.update of the SendSquad request, with that farm.
-- Returns whether it went, else why not; nothing changes on a refusal.
function ZombieFights.send(
	player: Player,
	farm: any,
	groupId: string,
	slimeIds: { string },
	now: number
): (boolean, string?)
	local session = sessions[player]
	if not session then
		return false, "NO_CAMPS"
	end
	local group = session.groups[groupId]
	if not group then
		return false, "NO_GROUP"
	elseif group.state ~= "waiting" then
		return false, "NOT_WAITING"
	elseif #session.squadList >= Config.Zombies.Teams then
		return false, "TOO_MANY_SQUADS"
	end
	local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return false, "TOO_FAR"
	end
	local away = Vector3.new(root.Position.X - group.position.X, 0, root.Position.Z - group.position.Z)
	if away.Magnitude > Config.Zombies.SendRangeStuds then
		return false, "TOO_FAR"
	end
	local ok, why = Zombies.checkSquad(farm, slimeIds, function(id: string): boolean
		return Village.isOut(player, id)
	end, now)
	if not ok then
		return false, why
	end
	local fighters = {}
	for _, id in slimeIds do
		table.insert(fighters, Zombies.fighter(FarmState.findSlime(farm, id) :: any, now))
	end
	session.squadSerial += 1
	local id = "squad-" .. session.squadSerial
	local fight = Combat.new(fighters, group.zombies :: any, session.rng)
	local folder = make(session.squads, id)
	set(folder, "Group", group.id)
	set(folder, "Camp", group.camp)
	set(folder, "State", "fighting")
	set(folder, "Members", table.concat(slimeIds, ","))
	set(folder, "StartedAt", workspace:GetServerTimeNow())
	local squad: Squad = {
		id = id,
		group = group,
		members = table.clone(slimeIds),
		fight = fight,
		folder = folder,
		nodes = {},
		coins = 0,
	}
	for _, unit in fight.units do
		local node: Configuration
		if unit.side == "squad" then
			node = make(folder, unit.id)
		else
			node = group.folder:FindFirstChild(unit.id) :: Configuration
		end
		if node then
			set(node, "MaxHp", unit.maxHp)
			set(node, "Hp", unit.hp)
			squad.nodes[unit.id] = node
		end
	end
	table.insert(session.squadList, squad)
	for _, member in slimeIds do
		Village.setOut(player, member, true)
	end
	group.state = "fighting"
	group.squad = id
	publishGroup(group)
	fire(session, id, { { kind = "start", group = group.id, members = table.clone(slimeIds) } })
	print(Config.LogPrefix, "zombies:", id, "sent", #slimeIds, "slimes at", group.id, "level", group.zombies[1].level)
	return true, nil
end

-- Whether the player stands within range of a point (flat distance), for the shop.
function ZombieFights.near(player: Player, point: Vector3, range: number): boolean
	local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return false
	end
	return Vector3.new(root.Position.X - point.X, 0, root.Position.Z - point.Z).Magnitude <= range
end

function ZombieFights.start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local remote = remotes:FindFirstChild("Fight")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Fight"
		remote.Parent = remotes
	end
	assert(remote:IsA("RemoteEvent"), "Fight remote must be a RemoteEvent")
	fightRemote = remote
	RunService.Heartbeat:Connect(function(dt: number)
		for _, player in Players:GetPlayers() do
			if not sessions[player] and Village.ownsPlot(player) and PlayerData.isReady(player) then
				local root = Village.rootOf(player)
				local farm = PlayerData.get(player)
				if root and farm then
					sessions[player] = openSession(player, root, farm, os.time())
				end
			end
		end
		for _, session in sessions do
			frame(session :: any, dt)
		end
	end)
	-- A player who leaves ends the fights: nobody dies in them and nothing is lost (coins already paid stay,
	-- dead slimes stay dead with their time, as saved).
	PlayerData.onLeaving(function(player: Player, _data: any)
		local session = sessions[player]
		if session then
			sessions[player] = nil
			print(
				Config.LogPrefix,
				"zombies:",
				player.Name,
				"left with",
				#session.squadList,
				"squads out; fights dropped"
			)
		end
	end)
end

return ZombieFights
