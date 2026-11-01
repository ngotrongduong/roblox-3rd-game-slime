--!strict
-- The zombie slimes outside the village and the teams that fight them (docs/ECONOMY.md, the owner 2026-11-02).
-- The server owns everything: the camps, the groups, the marches, every roll, the fight and the coins of each death.
-- Clients only read what is published under workspace.Villages.<id> and the Remotes.Fight event, and draw.
--   Camps/<groupId>   Configuration: Camp, Index, Level, Position, State ("waiting" | "taken" | "fighting" | "gone"),
--                     RespawnAt (server unix seconds, 0 unless gone), Team (the number of the team that ordered an attack
--                     on it, 0 when none)
--     <zombieId>      Configuration: Kind, Level, Hp, MaxHp
--   Teams/<n>         (n = 1..Config.Zombies.Teams, always there) Configuration:
--                     State ("home" | "going" | "fighting" | "returning"), Target (group id or ""), Repeat (boolean),
--                     Waiting (why a repeating team at home has not set out: "health" | "hungry" | "tired" | "group" | ""),
--                     Members (the saved line-up, slime ids comma separated), Marching (who went on this trip, comma
--                     separated, "" at home), and while State is not "home" the leg: FromX, FromZ, ToX, ToZ (flat studs),
--                     LegStart, LegEnd (workspace:GetServerTimeNow(); "going" walks gate to spot, "returning" spot to
--                     gate, "fighting" stands at the spot of the "going" leg; all 0 at home)
--     <slimeId>       Configuration, only while fighting: Hp, MaxHp
--   Slime models      HpShare (0 to 1): the share of health left, wounds included (written on the village's own models)
--   Remotes.Fight     RemoteEvent to the owner: ({ team = n, events = { event } })
--     event           { kind = "start" | "hit" | "dodge" | "fallen" | "end" | "home", ... } (see ZombieFights.launch,
--                     stepFight, endFight and arriveHome)
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
	team: number,
}
-- One team's trip (the saved line-up is farm.teams[index]).
type March = {
	index: number,
	state: string,
	group: Group?,
	-- who is on this trip (the line-up members able to go; after the fight, the survivors)
	members: { string },
	fight: Fight?,
	nodes: { [string]: Configuration },
	coins: number,
	dead: number,
	legStart: number,
	legEnd: number,
	from: Vector3,
	to: Vector3,
	-- the spot beside the group where the fight is (the far end of the march)
	spot: Vector3,
	waiting: string,
	folder: Configuration,
}
type Session = {
	player: Player,
	root: Folder,
	camps: Folder,
	teamsFolder: Folder,
	groups: { [string]: Group },
	order: { Group },
	teams: { March },
	-- the share of health each slime lost in its last fight (not saved: a rejoin heals everyone)
	wounds: { [string]: number },
	gate: Vector3,
	rng: typeof(Rng.new(0)),
	serial: number,
	accumulator: number,
}

local ZombieFights = {}
local sessions: { [Player]: Session } = {}
local fightRemote: RemoteEvent? = nil

-- Why a team at home waits, worst first: the screen shows the first one found among its members.
local WAIT_RANK: { [string]: number } = { health = 1, hungry = 2, tired = 3 }

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

local function near(player: Player, point: Vector3, range: number): boolean
	local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return false
	end
	return Vector3.new(root.Position.X - point.X, 0, root.Position.Z - point.Z).Magnitude <= range
end

local function publishGroup(group: Group)
	local folder = group.folder
	set(folder, "Camp", group.camp)
	set(folder, "Index", group.index)
	set(folder, "Level", group.zombies[1].level)
	set(folder, "Position", group.position)
	set(folder, "State", group.state)
	set(folder, "RespawnAt", if group.state == "gone" then group.respawnAt else 0)
	set(folder, "Team", group.team)
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
	group.team = 0
	group.respawnAt = 0
	publishGroup(group)
end

local function fire(session: Session, teamIndex: number, events: { any })
	local remote = fightRemote
	if remote and #events > 0 then
		remote:FireClient(session.player, { team = teamIndex, events = events })
	end
end

local function publishTeam(team: March, farmTeam: any)
	local folder = team.folder
	local marching = team.state ~= "home"
	set(folder, "State", team.state)
	set(folder, "Target", farmTeam.target or "")
	set(folder, "Repeat", farmTeam.repeatOn)
	set(folder, "Waiting", team.waiting)
	set(folder, "Members", table.concat(farmTeam.members, ","))
	set(folder, "Marching", if marching then table.concat(team.members, ",") else "")
	set(folder, "FromX", if marching then team.from.X else 0)
	set(folder, "FromZ", if marching then team.from.Z else 0)
	set(folder, "ToX", if marching then team.to.X else 0)
	set(folder, "ToZ", if marching then team.to.Z else 0)
	set(folder, "LegStart", if marching then team.legStart else 0)
	set(folder, "LegEnd", if marching then team.legEnd else 0)
end

local function openSession(player: Player, root: Folder, farm: any, now: number): Session
	local gate = Layout.plotGate(Config.Village.DevPlot)
	local session: Session = {
		player = player,
		root = root,
		camps = Instance.new("Folder"),
		teamsFolder = Instance.new("Folder"),
		groups = {},
		order = {},
		teams = {},
		wounds = {},
		gate = Vector3.new(gate.Position.X, 0, gate.Position.Z),
		rng = Rng.new(player.UserId + now),
		serial = 0,
		accumulator = 0,
	}
	session.camps.Name = "Camps"
	session.camps.Parent = root
	session.teamsFolder.Name = "Teams"
	session.teamsFolder.Parent = root
	for index = 1, Config.Zombies.Teams do
		local team: March = {
			index = index,
			state = "home",
			group = nil,
			members = {},
			fight = nil,
			nodes = {},
			coins = 0,
			dead = 0,
			legStart = 0,
			legEnd = 0,
			from = session.gate,
			to = session.gate,
			spot = session.gate,
			waiting = "",
			folder = make(session.teamsFolder, tostring(index)),
		}
		table.insert(session.teams, team)
		publishTeam(team, farm.teams[index])
	end
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
				team = 0,
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

-- The spot beside a group where a team fights: MarchStandOffStuds short of it, on the village's side.
local function spotBeside(session: Session, group: Group): Vector3
	local away = Vector3.new(session.gate.X - group.position.X, 0, session.gate.Z - group.position.Z)
	local flat = Vector3.new(group.position.X, 0, group.position.Z)
	if away.Magnitude < 1e-3 then
		return flat
	end
	return flat + away.Unit * math.min(Config.Zombies.MarchStandOffStuds, away.Magnitude)
end

local function speedsOf(farm: any, ids: { string }): { number }
	local speeds: { number } = {}
	for _, id in ids do
		local slime = FarmState.findSlime(farm, id)
		if slime then
			table.insert(speeds, slime.stats.speed)
		end
	end
	return speeds
end

-- Starts a leg of the march: the team walks from `from` to `to`, at the pace of the slowest of its members.
local function startLeg(team: March, farm: any, from: Vector3, to: Vector3)
	local seconds = Zombies.marchSeconds((to - from).Magnitude, speedsOf(farm, team.members))
	team.from, team.to = from, to
	team.legStart = workspace:GetServerTimeNow()
	team.legEnd = team.legStart + seconds
end

-- The team is back at the gate (or lost every slime that went): the survivors rejoin the village from the gate.
local function arriveHome(session: Session, team: March)
	for _, id in team.members do
		Village.setOut(session.player, id, false, true)
	end
	fire(session, team.index, { { kind = "home", team = team.index, dead = team.dead, coins = team.coins } })
	print(
		Config.LogPrefix,
		"zombies: team",
		team.index,
		"is home,",
		#team.members,
		"slimes back,",
		team.dead,
		"died, earned",
		team.coins
	)
	team.members = {}
	team.state = "home"
end

local function endFight(session: Session, team: March, winner: string, now: number)
	local player = session.player
	local fight = team.fight :: Fight
	local group = team.group :: Group
	local survivors: { string } = {}
	for _, unit in fight.units do
		if unit.side == "squad" then
			if unit.hp > 0 then
				table.insert(survivors, unit.id)
				local lost = 1 - unit.hp / unit.maxHp
				if lost > 0 then
					session.wounds[unit.id] = lost
				else
					session.wounds[unit.id] = nil
				end
			else
				-- a dead slime is a ghost in the village by the usual rules: it does not walk back
				session.wounds[unit.id] = nil
				Village.setOut(player, unit.id, false)
			end
		end
	end
	team.dead = #team.members - #survivors
	team.members = survivors
	if #survivors > 0 then
		PlayerData.update(player, function(farm: any)
			for _, id in survivors do
				local slime = FarmState.findSlime(farm, id)
				if slime then
					slime.needs.energy = math.max(0, slime.needs.energy - Config.Zombies.FightEnergy)
					slime.needs.fullness = math.max(0, slime.needs.fullness - Config.Zombies.FightFullness)
				end
			end
		end)
	end
	if winner == "squad" then
		group.state = "gone"
		group.team = 0
		group.respawnAt = now + Config.Zombies.RespawnSeconds
		publishGroup(group)
	else
		-- the zombies beat the team (or neither won in time): the group stands again, whole
		spawn(session, group, group.playerLevel)
	end
	for _, node in team.nodes do
		if node.Parent == team.folder then
			node:Destroy()
		end
	end
	team.nodes = {}
	team.fight = nil
	team.group = nil
	fire(session, team.index, { { kind = "end", winner = winner, coins = team.coins } })
	print(
		Config.LogPrefix,
		"zombies: team",
		team.index,
		"ended against",
		group.id,
		"winner",
		winner,
		"coins",
		team.coins,
		"survivors",
		#survivors
	)
	local farm = PlayerData.get(player)
	if #survivors > 0 and farm then
		team.state = "returning"
		startLeg(team, farm, team.spot, session.gate)
	else
		arriveHome(session, team)
	end
end

local function stepFight(session: Session, team: March, now: number)
	local fight = team.fight :: Fight
	local group = team.group :: Group
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
		local node = team.nodes[unit.id]
		if node then
			set(node, "Hp", unit.hp)
		end
	end
	if #fallen > 0 then
		-- Every slime that falls, on either side, pays at once.
		PlayerData.update(session.player, function(farm: any)
			for _, entry in fallen do
				local zombie = group.byId[entry.to]
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
			team.coins += entry.coins or 0
			print(Config.LogPrefix, "zombies:", entry.to, "fell in team", team.index, "paid", entry.coins or 0)
		end
	end
	fire(session, team.index, out)
	if fight.winner then
		endFight(session, team, fight.winner, now)
	elseif fight.seconds >= Config.Zombies.FightMaxSeconds then
		endFight(session, team, "draw", now)
	end
end

-- The team has reached its group: the fight starts from the health each slime has left.
local function beginFight(session: Session, team: March, farm: any, now: number)
	local group = team.group :: Group
	local fighters: { any } = {}
	local here: { string } = {}
	for _, id in team.members do
		local slime = FarmState.findSlime(farm, id)
		if slime then
			table.insert(fighters, Zombies.fighter(slime, now, 1 - (session.wounds[id] or 0)))
			table.insert(here, id)
		else
			-- (gone from the farm while away: nothing of it is left to bring back)
			Village.setOut(session.player, id, false)
		end
	end
	team.members = here
	if #fighters == 0 then
		-- nobody left to fight: the group stands free again and the team is home
		group.state = "waiting"
		group.team = 0
		publishGroup(group)
		team.group = nil
		arriveHome(session, team)
		return
	end
	local fight = Combat.new(fighters, group.zombies :: any, session.rng)
	team.fight = fight
	team.coins, team.dead = 0, 0
	team.nodes = {}
	for _, unit in fight.units do
		local node: Configuration?
		if unit.side == "squad" then
			node = make(team.folder, unit.id)
		else
			node = group.folder:FindFirstChild(unit.id) :: Configuration?
		end
		if node then
			set(node, "MaxHp", unit.maxHp)
			set(node, "Hp", unit.hp)
			team.nodes[unit.id] = node
		end
	end
	team.state = "fighting"
	group.state = "fighting"
	publishGroup(group)
	fire(session, team.index, { { kind = "start", group = group.id, members = table.clone(here) } })
	print(Config.LogPrefix, "zombies: team", team.index, "met", group.id, "level", group.zombies[1].level)
end

-- Sends a team from the gate at a waiting group (the player's order, or a repeating team setting out again). The team's
-- members that cannot go now (asleep, tired, dead, away) stay home. Returns whether it went, else why not; nothing
-- changes on a refusal.
local function launch(session: Session, team: March, group: Group, farm: any, now: number): (boolean, string?)
	local line = farm.teams[team.index]
	local going: { string } = {}
	for _, id in line.members do
		local slime = FarmState.findSlime(farm, id)
		if slime and not Village.isOut(session.player, id) and Zombies.canSend(farm, slime, now) then
			table.insert(going, id)
		end
	end
	if #going == 0 then
		return false, "NO_MEMBERS"
	end
	team.members = going
	team.coins, team.dead = 0, 0
	team.group = group
	team.spot = spotBeside(session, group)
	team.state = "going"
	startLeg(team, farm, session.gate, team.spot)
	group.state = "taken"
	group.team = team.index
	publishGroup(group)
	for _, id in going do
		Village.setOut(session.player, id, true)
	end
	print(
		Config.LogPrefix,
		"zombies: team",
		team.index,
		"sets out with",
		#going,
		"of",
		#line.members,
		"slimes at",
		group.id,
		"level",
		group.zombies[1].level,
		"march",
		string.format("%.1f", team.legEnd - team.legStart),
		"s"
	)
	return true, nil
end

-- A team at home with the repeat option on sets out again by itself once every living member is fit; else it says
-- why it waits. It stops by itself when no member is alive.
local function repeatTeam(session: Session, team: March, farm: any, now: number)
	local line = farm.teams[team.index]
	team.waiting = ""
	if not line.repeatOn then
		return
	end
	local alive = 0
	local why: string? = nil
	for _, id in line.members do
		local slime = FarmState.findSlime(farm, id)
		if slime and not (slime.ghostUntil and slime.ghostUntil > now) then
			alive += 1
			local ready, reason = Zombies.readyAgain(slime, now, session.wounds[id] or 0)
			if not ready and reason and (why == nil or (WAIT_RANK[reason] or 99) < (WAIT_RANK[why] or 99)) then
				why = reason
			end
		end
	end
	if alive == 0 then
		PlayerData.update(session.player, function(live: any)
			live.teams[team.index].repeatOn = false
		end)
		print(Config.LogPrefix, "zombies: team", team.index, "has no slime alive, repeat is off")
		return
	end
	if why then
		team.waiting = why
		return
	end
	local group = if line.target then session.groups[line.target] else nil
	if not group or group.state ~= "waiting" then
		team.waiting = "group"
		return
	end
	local went, reason = launch(session, team, group, farm, now)
	if not went then
		team.waiting = if reason == "NO_MEMBERS" then "tired" else "group"
	end
end

local function frame(session: Session, dt: number)
	local now = os.time()
	local serverNow = workspace:GetServerTimeNow()
	local player = session.player
	local farm = PlayerData.get(player)
	if farm then
		for _, group in session.order do
			if group.state == "gone" and now >= group.respawnAt then
				spawn(session, group, Zombies.playerLevel(farm, now))
				print(Config.LogPrefix, "zombies:", group.id, "is back at level", group.zombies[1].level)
			end
		end
	end
	-- the marches
	for index = 1, #session.teams do
		local team = session.teams[index]
		local state = team.state
		if farm and serverNow >= team.legEnd then
			if state == "going" then
				beginFight(session, team, farm, now)
			elseif state == "returning" then
				arriveHome(session, team)
			end
		end
	end
	-- the fights
	local step = Config.Zombies.FightStepSeconds
	session.accumulator = math.min(session.accumulator + dt, step * Config.Zombies.MaxStepsPerFrame)
	while session.accumulator >= step do
		session.accumulator -= step
		for index = 1, #session.teams do
			local team = session.teams[index]
			if team.fight then
				stepFight(session, team, now)
			end
		end
	end
	if not farm then
		return
	end
	-- wounds heal at home only (a slime on a march keeps them)
	for id, hurt in session.wounds do
		local slime = FarmState.findSlime(farm, id)
		if not slime or (slime.ghostUntil and slime.ghostUntil > now) then
			session.wounds[id] = nil
		elseif not Village.isOut(player, id) then
			local left = Zombies.heal(hurt, dt)
			if left > 0 then
				session.wounds[id] = left
			else
				session.wounds[id] = nil
			end
		end
	end
	for index = 1, #session.teams do
		local team = session.teams[index]
		local state = team.state
		if state == "home" then
			repeatTeam(session, team, farm, now)
		else
			team.waiting = ""
		end
		publishTeam(team, farm.teams[team.index])
	end
	-- the health share on every slime's model
	local fighting: { [string]: number } = {}
	for _, team in session.teams do
		local fight = team.fight
		if fight then
			for _, unit in fight.units do
				if unit.side == "squad" then
					fighting[unit.id] = unit.hp / unit.maxHp
				end
			end
		end
	end
	local models = session.root:FindFirstChild("Slimes")
	if models then
		local stepShare = Config.Zombies.HpShareStep
		for _, model in models:GetChildren() do
			local share = fighting[model.Name] or 1 - (session.wounds[model.Name] or 0)
			set(model, "HpShare", math.floor(share / stepShare + 0.5) * stepShare)
		end
	end
end

-- Orders a team at a waiting group. Called inside the PlayerData.update of the AttackGroup request, with that farm. The
-- order is kept as the team's target for its repeat option. Returns whether it went, else why not; nothing changes on a
-- refusal.
function ZombieFights.attack(
	player: Player,
	farm: any,
	teamIndex: number,
	groupId: string,
	now: number
): (boolean, string?)
	local session = sessions[player]
	if not session then
		return false, "NO_CAMPS"
	end
	local team = session.teams[teamIndex]
	if not team or not farm.teams[teamIndex] then
		return false, "BAD_TEAM"
	end
	local group = session.groups[groupId]
	if not group then
		return false, "NO_GROUP"
	elseif team.state ~= "home" then
		return false, "TEAM_OUT"
	elseif group.state ~= "waiting" then
		return false, "NOT_WAITING"
	elseif not near(player, group.position, Config.Zombies.SendRangeStuds) then
		return false, "TOO_FAR"
	end
	local went, why = launch(session, team, group, farm, now)
	if went then
		farm.teams[teamIndex].target = groupId
	end
	return went, why
end

-- Whether the team is away from home (on a march or fighting). A team that does not exist counts as away.
function ZombieFights.teamOut(player: Player, teamIndex: number): boolean
	local session = sessions[player]
	local team = if session then session.teams[teamIndex] else nil
	return team == nil or team.state ~= "home"
end

-- Heals a slime at once (a revive clears its wounds).
function ZombieFights.clearWounds(player: Player, slimeId: string)
	local session = sessions[player]
	if session then
		session.wounds[slimeId] = nil
	end
end

-- Whether the player stands within range of a point (flat distance), for the gate, the groups and the shop.
function ZombieFights.near(player: Player, point: Vector3, range: number): boolean
	return near(player, point, range)
end

-- Whether the player stands at the village gate, where the teams' line-ups are set.
function ZombieFights.nearGate(player: Player): boolean
	return near(player, Layout.plotGate(Config.Village.DevPlot).Position, Config.Zombies.GateRangeStuds)
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
	-- A player who leaves ends the marches and fights: nobody dies in them, the wounds are gone and nothing is lost (coins
	-- already paid stay, dead slimes stay dead with their time, the teams and their repeat option stay saved).
	PlayerData.onLeaving(function(player: Player, _data: any)
		local session = sessions[player]
		if session then
			sessions[player] = nil
			local away = 0
			for _, team in session.teams do
				if team.state ~= "home" then
					away += 1
				end
			end
			print(Config.LogPrefix, "zombies:", player.Name, "left with", away, "teams out; marches and fights dropped")
		end
	end)
end

return ZombieFights
