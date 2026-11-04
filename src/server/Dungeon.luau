--!strict
-- The Slime Dungeon's run on the server (the owner, 2026-11-04; rules in shared/Dungeon, numbers in Config.Dungeon). One
-- private run a player, in an arena of their own far from the valley (Layout.arenaFrame), so nobody else interferes and the
-- valley stays light. The server decides everything: the waves, where and when each monster comes in, every blow (shared/
-- Combat, stepped at the zombie fights' pace), every drop and every coin. Clients read what is published and the
-- Remotes.Fight event, and draw.
--
-- A run goes COUNTDOWN -> WAVE_ACTIVE -> WAVE_CLEARED (Config.Dungeon.PauseSeconds) -> COUNTDOWN ... and ends in VICTORY
-- (wave 10 cleared) or DEFEAT (the squad is down); Leave ends it from any phase. A wave's drops wait in a ledger and reach
-- the farm when the wave is cleared (once); a defeat or a leave gives the wave in play up, never the earlier ones. A fallen
-- slime becomes a ghost by the village's one rule (Zombies.ghost, paying nothing); health carries from wave to wave and,
-- as wounds, from run to run.
--
-- Slimes are drawn by the clients, as in a zombie fight (the server places no slime body): the squad is `out` of the
-- village while it fights (Village.setOut) and the clients stand it round the arena's middle. The monsters are stand-in
-- balls until the art step brings their models.
--
--   workspace.DungeonArenas.<name>   the arena of one run, a Model (ServerStorage's Config.Dungeon.ArenaTemplate when it
--                     exists, else the Sunny Meadow of server/DungeonArena, else a greybox of parts). Attributes: Owner (UserId), Plot, MapId, Phase ("COUNTDOWN" |
--                     "WAVE_ACTIVE" | "WAVE_CLEARED" | "VICTORY" | "DEFEAT"), Wave (1..Waves; the wave in play, or the
--                     last one cleared), Waves, Level (the dungeon level), Left (monsters left this wave, the queue
--                     included), Best (the best level cleared), Ledger (JSON text, "{"coins":5,"wood":1}": what the
--                     run has won, the cleared waves' and the open wave's, by item), PhaseEnd (server time the timed
--                     phase ends, 0 when it has no end), Teams / Members (comma separated team numbers / slime ids),
--                     Centre (Vector3: the floor's top middle), Radius, PlayerSpot (CFrame the player is put at)
--       Squad/<slimeId>   Configuration: Hp, MaxHp
--       Monsters/<id>     the stand-in Part of a monster in play: MonsterId (its def id, e.g. "green_boar"), MonsterName,
--                     Role, Kind, Level, Hp, MaxHp, X, Z (flat, from the middle)
--   Player            DungeonPhase ("" outside a run), DungeonWave, DungeonWaves, DungeonLevel, DungeonLeft,
--                     DungeonLedger (as Ledger above), and DungeonBest (always: the best level cleared)
--   Remotes.Fight     the zombie fights' event, with { team = 0, dungeon = true, teams = { n }, events = { event } };
--                     event kinds: "start" ({ members, roles, level, waves, best }), "wave" ({ wave, waves, count,
--                     waveKind }), "spawn" ({ id, defId, name, role, foeKind, level, hp, x, z, wx, wy, wz }), the fight's
--                     own "aim" "hit" "dodge" "guard" "heal" "fallen" (a monster's carries drops = { { item, amount } }),
--                     "clear" ({ wave, coins, food, lost, materials }), "end" ({ winner = "squad" | "foe" | "left",
--                     level, wave, best }), "leave"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Config = require(ReplicatedStorage.Shared.Config)
local DungeonRules = require(ReplicatedStorage.Shared.Dungeon)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Rng = require(ReplicatedStorage.Shared.Rng)
local Zombies = require(ReplicatedStorage.Shared.Zombies)
local PlayerData = require(script.Parent.PlayerData)
local DungeonArena = require(script.Parent.DungeonArena)
local Plots = require(script.Parent.Plots)
local Village = require(script.Parent.Village)
local ZombieFights = require(script.Parent.ZombieFights)

local D = Config.Dungeon

type Fight = typeof(Combat.new({}, {}, Rng.new(0)))
type Ledger = typeof(DungeonRules.newLedger())
-- A monster in play: its plan entry, its def, its stand-in and where it stands (flat, from the arena's middle).
type Foe = {
	monster: any,
	def: any,
	part: Part?,
	lx: number,
	lz: number,
	alive: boolean,
}
type Run = {
	player: Player,
	plot: number,
	mapId: string,
	level: number,
	teams: { number },
	-- the squad of this run (slime ids) and which of them are out of the village now
	members: { string },
	out: { [string]: boolean },
	arena: Model,
	monsters: Folder,
	squad: Folder,
	nodes: { [string]: Configuration },
	frame: CFrame,
	-- false until the player is in the arena (the clock does not run before)
	ready: boolean,
	phase: string,
	-- server seconds of the run (steps of the fight), and when the timed phase ends on that clock
	clock: number,
	phaseEnd: number,
	phaseEndTime: number,
	accumulator: number,
	wave: number,
	plan: { any },
	-- how many of the plan have come in, how many of them stand, when the next may come, when the wave began
	queued: number,
	alive: number,
	nextSpawn: number,
	waveStart: number,
	foes: { [string]: Foe },
	fight: Fight?,
	ledger: Ledger,
	seed: number,
	rng: typeof(Rng.new(0)),
	-- the wounds and the cost of the run have been written for this run
	settled: boolean,
	publishAt: number,
}

local Dungeon = {}
local runs: { [Player]: Run } = {}
local lastAsk: { [Player]: number } = {}
local fightRemote: RemoteEvent? = nil
local serial = 0

local COUNTDOWN, ACTIVE, CLEARED, VICTORY, DEFEAT = "COUNTDOWN", "WAVE_ACTIVE", "WAVE_CLEARED", "VICTORY", "DEFEAT"

local function set(inst: Instance, name: string, value: any)
	if inst:GetAttribute(name) ~= value then
		inst:SetAttribute(name, value)
	end
end

local function fire(run: Run, events: { any })
	local remote = fightRemote
	if remote and #events > 0 and run.player.Parent == Players then
		remote:FireClient(run.player, { team = 0, dungeon = true, teams = run.teams, events = events })
	end
end

local function fail(reason: string): { ok: boolean, reason: string? }
	return { ok = false, reason = reason }
end

-- ===== The arena =====

local function arenaFolder(): Folder
	local found = workspace:FindFirstChild(D.ArenaFolder)
	if found and found:IsA("Folder") then
		return found
	end
	local folder = Instance.new("Folder")
	folder.Name = D.ArenaFolder
	folder.Parent = workspace
	return folder
end

local function box(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = color
	part.Material = Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Studs
	part.CastShadow = false
	part.Parent = model
	return part
end

-- FALLBACK: a round flat floor with a low rim, in the classic stud look, for when the kit lacks a model the Sunny Meadow
-- needs (server/DungeonArena warns which). A model named Config.Dungeon.ArenaTemplate in ServerStorage (built by hand in
-- Studio) wins over both; otherwise the Sunny Meadow of server/DungeonArena is cloned.
local function greybox(frame: CFrame): Model
	local model = Instance.new("Model")
	local radius = D.ArenaRadius
	local floor = box(
		model,
		"Floor",
		Vector3.new(D.ArenaFloorThickness, radius * 2, radius * 2),
		frame * CFrame.new(0, -D.ArenaFloorThickness / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(120, 178, 86)
	)
	floor.Shape = Enum.PartType.Cylinder
	local segments = D.ArenaRimSegments
	local arc = 2 * math.pi * (radius + D.ArenaRimThickness / 2) / segments
	for index = 1, segments do
		local yaw = (index - 1) / segments * math.pi * 2
		box(
			model,
			"Rim",
			Vector3.new(arc + 0.4, D.ArenaRimHeight, D.ArenaRimThickness),
			frame * CFrame.Angles(0, yaw, 0) * CFrame.new(0, D.ArenaRimHeight / 2, radius + D.ArenaRimThickness / 2),
			Color3.fromRGB(150, 128, 98)
		)
	end
	model.WorldPivot = frame
	return model
end

local function buildArena(plot: number): Model
	local frame = Layout.arenaFrame(plot)
	local template = ServerStorage:FindFirstChild(D.ArenaTemplate)
	local meadow = if template and template:IsA("Model") then template else DungeonArena.template()
	local arena: Model
	if meadow then
		arena = meadow:Clone()
		arena:PivotTo(frame)
	else
		arena = greybox(frame)
	end
	serial += 1
	arena.Name = "Arena" .. plot .. "_" .. serial
	arena.Parent = arenaFolder()
	return arena
end

local function standIn(run: Run, foe: Foe)
	local def, monster = foe.def, foe.monster
	local size = (D.StandIn.Sizes :: any)[def.role] or D.StandIn.Sizes.normal
	local part = Instance.new("Part")
	part.Name = monster.id
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromHex((D.StandIn.Colours :: any)[def.kind] or D.StandIn.Colours.melee)
	part.Position = (run.frame * CFrame.new(foe.lx, size / 2, foe.lz)).Position
	part:SetAttribute("MonsterId", def.id)
	part:SetAttribute("MonsterName", def.name)
	part:SetAttribute("Role", def.role)
	part:SetAttribute("Kind", def.kind)
	part:SetAttribute("Level", monster.level)
	part:SetAttribute("Hp", monster.hp)
	part:SetAttribute("MaxHp", monster.hp)
	part:SetAttribute("X", foe.lx)
	part:SetAttribute("Z", foe.lz)
	part.Parent = run.monsters
	foe.part = part
end

-- ===== What is published =====

-- The run's winnings by item as JSON text, items in a fixed order so the same winnings are the same text.
local function ledgerText(run: Run): string
	local totals: { [string]: number } = {}
	for _, page in run.ledger.waves do
		if page.state ~= "discarded" then
			for item, amount in page.drops do
				totals[item] = (totals[item] or 0) + amount
			end
		end
	end
	local items: { string } = {}
	for item in totals do
		table.insert(items, item)
	end
	table.sort(items)
	local parts: { string } = {}
	for _, item in items do
		table.insert(parts, HttpService:JSONEncode(item) .. ":" .. totals[item])
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

local function foesLeft(run: Run): number
	if run.phase == CLEARED or run.phase == VICTORY then
		return 0
	end
	return (#run.plan - run.queued) + run.alive
end

local function publish(run: Run)
	local farm = PlayerData.get(run.player)
	local best = if farm then farm.dungeon.best else 0
	local left = foesLeft(run)
	local ledger = ledgerText(run)
	local arena = run.arena
	set(arena, "Owner", run.player.UserId)
	set(arena, "Plot", run.plot)
	set(arena, "MapId", run.mapId)
	set(arena, "Phase", run.phase)
	set(arena, "Wave", run.wave)
	set(arena, "Waves", D.Waves)
	set(arena, "Level", run.level)
	set(arena, "Left", left)
	set(arena, "Best", best)
	set(arena, "Ledger", ledger)
	set(arena, "PhaseEnd", run.phaseEndTime)
	set(arena, "Teams", table.concat(run.teams :: any, ","))
	set(arena, "Members", table.concat(run.members, ","))
	set(arena, "Centre", run.frame.Position)
	set(arena, "Radius", D.ArenaRadius)
	set(arena, "PlayerSpot", Layout.arenaPlayerSpot(run.plot))
	local player = run.player
	set(player, "DungeonPhase", run.phase)
	set(player, "DungeonWave", run.wave)
	set(player, "DungeonWaves", D.Waves)
	set(player, "DungeonLevel", run.level)
	set(player, "DungeonLeft", left)
	set(player, "DungeonLedger", ledger)
	set(player, "DungeonBest", best)
	local fight = run.fight
	if fight then
		for _, unit in fight.units do
			if unit.side == "squad" then
				local node = run.nodes[unit.id]
				if node then
					set(node, "Hp", unit.hp)
				end
			else
				local foe = run.foes[unit.id]
				if foe and foe.part then
					set(foe.part, "Hp", unit.hp)
				end
			end
		end
	end
end

local function clearPlayerAttributes(player: Player)
	set(player, "DungeonPhase", "")
	set(player, "DungeonWave", 0)
	set(player, "DungeonWaves", 0)
	set(player, "DungeonLevel", 0)
	set(player, "DungeonLeft", 0)
	set(player, "DungeonLedger", "{}")
end

-- ===== The player's body =====

local function moveCharacter(player: Player, to: CFrame)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	humanoid.Sit = false
	character:PivotTo(to)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function characterAlive(player: Player): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart")
end

-- A player who left the arena by falling or by respawning is put back where they belong.
local function keepIn(run: Run)
	local character = run.player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	local flat = Vector3.new(root.Position.X - run.frame.Position.X, 0, root.Position.Z - run.frame.Position.Z)
	if flat.Magnitude > D.ArenaRadius + D.StrayStuds or root.Position.Y < run.frame.Position.Y - D.StrayStuds then
		moveCharacter(run.player, Layout.arenaPlayerSpot(run.plot))
		print(Config.LogPrefix, "dungeon:", run.player.Name, "strayed from the arena, put back")
	end
end

-- ===== The squad =====

-- The slimes a run brings from these teams, or nil and why not (LOCKED, BAD_TEAM, TEAM_OUT, NO_MEMBERS, NO_FIT). A slime
-- that cannot go now (a ghost, a baby, asleep, tired, at a job, in a pair, out on a march) stays home; `mine` are the
-- ones already out for this run.
local function squadFor(
	player: Player,
	farm: any,
	teams: { number },
	now: number,
	mine: { [string]: boolean }
): ({ string }?, string?)
	local ids: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, index in teams do
		local line = farm.teams[index]
		if not line then
			return nil, "BAD_TEAM"
		elseif not Zombies.teamOpen(farm, index) then
			return nil, "LOCKED"
		elseif ZombieFights.teamOut(player, index) then
			return nil, "TEAM_OUT"
		elseif #line.members == 0 then
			return nil, "NO_MEMBERS"
		end
		for _, id in line.members do
			local slime = FarmState.findSlime(farm, id)
			if
				slime
				and not seen[id]
				and (mine[id] or not Village.isOut(player, id))
				and Zombies.canSend(farm, slime, now)
			then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	if #ids == 0 then
		return nil, "NO_FIT"
	end
	return ids, nil
end

-- Sets who is in the squad: the village hides the ones that go out and shows the ones that come home at its gate.
local function setSquad(run: Run, ids: { string })
	local want: { [string]: boolean } = {}
	for _, id in ids do
		want[id] = true
	end
	for id in run.out do
		if not want[id] then
			Village.setOut(run.player, id, false, true)
			run.out[id] = nil
		end
	end
	for id in want do
		if not run.out[id] then
			Village.setOut(run.player, id, true)
			run.out[id] = true
		end
	end
	run.members = ids
	run.squad:ClearAllChildren()
	run.nodes = {}
	for _, id in ids do
		local node = Instance.new("Configuration")
		node.Name = id
		node.Parent = run.squad
		run.nodes[id] = node
	end
end

local function sendHome(run: Run)
	for id in run.out do
		Village.setOut(run.player, id, false, true)
	end
	run.out = {}
end

-- The run is over for the squad: survivors keep their wounds, and every slime that fought pays the run's energy and
-- fullness (once).
local function settle(run: Run)
	if run.settled then
		return
	end
	run.settled = true
	local fight = run.fight
	if not fight then
		return
	end
	local fought: { string } = {}
	for _, unit in fight.units do
		if unit.side == "squad" then
			if unit.hp > 0 then
				table.insert(fought, unit.id)
				ZombieFights.setWound(run.player, unit.id, 1 - unit.hp / unit.maxHp)
			else
				ZombieFights.setWound(run.player, unit.id, 0)
			end
		end
	end
	if #fought > 0 then
		PlayerData.update(run.player, function(farm: any)
			for _, id in fought do
				local slime = FarmState.findSlime(farm, id)
				if slime then
					slime.needs.energy = math.max(0, slime.needs.energy - D.RunEnergy)
					slime.needs.fullness = math.max(0, slime.needs.fullness - D.RunFullness)
				end
			end
		end)
	end
end

-- ===== The waves =====

local function endPhase(run: Run, phase: string, seconds: number)
	run.phase = phase
	run.phaseEnd = run.clock + seconds
	run.phaseEndTime = if seconds > 0 then workspace:GetServerTimeNow() + seconds else 0
end

-- The next wave is announced: its monsters are drawn and the countdown runs.
local function beginWave(run: Run)
	run.wave += 1
	run.plan = DungeonRules.plan(run.mapId, run.level, run.wave, run.seed)
	run.queued, run.alive = 0, 0
	endPhase(run, COUNTDOWN, D.CountdownSeconds)
	fire(run, {
		{
			kind = "wave",
			wave = run.wave,
			waves = D.Waves,
			count = #run.plan,
			waveKind = DungeonRules.waveKind(run.wave),
		},
	})
	publish(run)
	print(
		Config.LogPrefix,
		"dungeon:",
		run.player.Name,
		"level",
		run.level,
		"wave",
		run.wave,
		"of",
		D.Waves,
		"announced,",
		#run.plan,
		"monsters"
	)
end

-- (Re)starts a run with this squad on this level: a fresh ledger and seed, the squad fresh from its wounds, wave 1 next.
local function startRun(run: Run, farm: any, level: number, ids: { string }, now: number)
	run.level = level
	run.seed = run.rng:int(1, 2147483646)
	run.ledger = DungeonRules.newLedger()
	run.wave, run.clock, run.accumulator = 0, 0, 0
	run.plan, run.queued, run.alive = {}, 0, 0
	run.settled = false
	run.foes = {}
	run.monsters:ClearAllChildren()
	setSquad(run, ids)
	local fighters: { any } = {}
	local roles: { [string]: string } = {}
	for _, id in ids do
		local slime = FarmState.findSlime(farm, id)
		if slime then
			local fighter: any = Zombies.fighter(slime, now, 1 - ZombieFights.woundOf(run.player, id))
			fighter.role = Combat.role(fighter, slime.seed)
			table.insert(fighters, fighter)
			roles[id] = fighter.role
			local node = run.nodes[id]
			if node then
				set(node, "MaxHp", fighter.maxHp)
				set(node, "Hp", fighter.hp)
			end
		end
	end
	local fight = Combat.new(fighters, {}, run.rng)
	-- (the queue brings monsters in one by one: the fight does not end when the monsters in it are down)
	fight.open = true
	run.fight = fight
	fire(run, {
		{
			kind = "start",
			group = "dungeon",
			members = table.clone(ids),
			roles = roles,
			level = level,
			waves = D.Waves,
			best = farm.dungeon.best,
		},
	})
	print(
		Config.LogPrefix,
		"dungeon:",
		run.player.Name,
		"starts level",
		level,
		"with",
		#ids,
		"slimes, teams",
		table.concat(run.teams :: any, ",")
	)
	beginWave(run)
end

-- A monster comes in at a random point of the edge band.
local function spawnFoe(run: Run, fight: Fight)
	local monster = run.plan[run.queued + 1]
	local def = DungeonRules.defOf(run.mapId, monster.defId)
	local taken: { { x: number, z: number } } = {}
	for _, other in run.foes do
		if other.alive then
			table.insert(taken, { x = other.lx, z = other.lz })
		end
	end
	local lx, lz = DungeonRules.spawnPoint(run.rng, taken)
	local joined = Combat.add(fight, monster, "foe")
	if not joined then
		return
	end
	run.queued += 1
	run.alive += 1
	local foe: Foe = { monster = monster, def = def, part = nil, lx = lx, lz = lz, alive = true }
	run.foes[monster.id] = foe
	standIn(run, foe)
	local world = run.frame * Vector3.new(lx, 0, lz)
	fire(run, {
		{
			kind = "spawn",
			id = monster.id,
			defId = def.id,
			name = def.name,
			role = def.role,
			foeKind = def.kind,
			level = monster.level,
			hp = monster.hp,
			x = lx,
			z = lz,
			wx = world.X,
			wy = world.Y,
			wz = world.Z,
		},
	})
end

-- A fallen monster's stand-in lingers a moment, then goes.
local function fade(foe: Foe)
	local part = foe.part
	if part then
		task.delay(D.FoeFadeSeconds, function()
			if part.Parent then
				part:Destroy()
			end
		end)
	end
end

-- Every roll of a fallen monster's drops, on the server, into the wave's page of the ledger.
local function dropsOf(run: Run, foe: Foe): { any }
	local drops: { any } = {}
	local id = foe.monster.id
	for _, roll in DungeonRules.rollDrops(foe.def, run.level, id, run.seed) do
		if DungeonRules.addDrop(run.ledger, run.wave, roll) then
			table.insert(drops, { item = roll.item, amount = roll.amount })
		end
	end
	return drops
end

-- The squad is out of the arena for good: wave 10 is cleared (VICTORY, the best level moves up) or the squad is down.
local function endRun(run: Run, phase: string, winner: string)
	endPhase(run, phase, 0)
	settle(run)
	if phase == DEFEAT then
		-- the fallen are ghosts at home now: the player can revive them before another try
		sendHome(run)
	end
	local farm = PlayerData.get(run.player)
	fire(run, {
		{
			kind = "end",
			winner = winner,
			level = run.level,
			wave = run.wave,
			best = if farm then farm.dungeon.best else 0,
		},
	})
	publish(run)
	PlayerData.markKeyMoment(run.player, "dungeon run end")
	print(
		Config.LogPrefix,
		"dungeon:",
		run.player.Name,
		"level",
		run.level,
		if phase == VICTORY then "cleared" else "lost",
		"at wave",
		run.wave
	)
end

local function defeat(run: Run, why: string)
	DungeonRules.discardWave(run.ledger, run.wave)
	for _, foe in run.foes do
		if foe.alive then
			foe.alive = false
			fade(foe)
		end
	end
	print(Config.LogPrefix, "dungeon:", run.player.Name, "wave", run.wave, "given up:", why)
	endRun(run, DEFEAT, "foe")
end

-- The wave is cleared: its drops reach the farm, once; wave 10 ends the run in victory.
local function clearWave(run: Run, fight: Fight)
	local wave = run.wave
	local last = wave >= D.Waves
	local paid: any = nil
	local newBest = false
	local done = PlayerData.update(run.player, function(farm: any)
		paid = DungeonRules.commitWave(farm, run.ledger, wave)
		if last then
			newBest = DungeonRules.recordClear(farm, run.level)
		end
	end)
	PlayerData.markKeyMoment(run.player, "dungeon wave")
	if not done then
		warn(Config.LogPrefix, "dungeon:", run.player.Name, "wave", wave, "cleared but the save is not loaded")
	end
	-- (the monsters that fell are taken out of the fight; the squad, fallen or not, stays)
	local units = fight.units
	for index = #units, 1, -1 do
		if units[index].side == "foe" then
			table.remove(units, index)
		end
	end
	local materials: { [string]: number } = if paid then table.clone(paid.materials) else {}
	fire(run, {
		{
			kind = "clear",
			wave = wave,
			coins = if paid then paid.coins else 0,
			food = if paid then paid.food else 0,
			lost = if paid then paid.lost else 0,
			materials = materials,
		},
	})
	print(
		Config.LogPrefix,
		"dungeon:",
		run.player.Name,
		"wave",
		wave,
		"cleared, paid coins",
		if paid then paid.coins else 0,
		"food",
		if paid then paid.food else 0,
		"lost",
		if paid then paid.lost else 0,
		"materials",
		HttpService:JSONEncode(materials)
	)
	if last then
		if newBest then
			print(Config.LogPrefix, "dungeon:", run.player.Name, "best level is now", run.level)
		end
		endRun(run, VICTORY, "squad")
	else
		endPhase(run, CLEARED, D.PauseSeconds)
		publish(run)
	end
end

local function stepActive(run: Run, fight: Fight, now: number)
	local step = Config.Zombies.FightStepSeconds
	if run.queued < #run.plan and run.alive < D.MaxAlive and run.clock >= run.nextSpawn then
		spawnFoe(run, fight)
		run.nextSpawn = run.clock + D.SpawnSeconds
	end
	local out: { any } = {}
	local fallenFoes: { any } = {}
	local fallenSquad: { any } = {}
	for _, event in Combat.step(fight, step) do
		local entry: { [string]: any } = table.clone(event :: any)
		table.insert(out, entry)
		if event.kind == "fallen" then
			if run.foes[event.to] then
				table.insert(fallenFoes, entry)
			else
				table.insert(fallenSquad, entry)
			end
		end
	end
	for _, entry in fallenFoes do
		local foe = run.foes[entry.to]
		if foe.alive then
			foe.alive = false
			run.alive -= 1
			entry.drops = dropsOf(run, foe)
			fade(foe)
		end
	end
	if #fallenFoes > 0 or #fallenSquad > 0 then
		PlayerData.update(run.player, function(farm: any)
			for _, entry in fallenSquad do
				Zombies.ghost(farm, entry.to, now)
			end
			farm.lifetime.mobsKilled += #fallenFoes
		end)
		PlayerData.markKeyMoment(run.player, "dungeon fight")
		for _, entry in fallenSquad do
			print(Config.LogPrefix, "dungeon:", entry.to, "fell in wave", run.wave, "and is a ghost")
		end
		for _, entry in fallenFoes do
			local names: { string } = {}
			for _, drop in entry.drops or {} do
				table.insert(names, drop.item .. " x" .. drop.amount)
			end
			print(
				Config.LogPrefix,
				"dungeon:",
				entry.to,
				"fell in wave",
				run.wave,
				"drops",
				if #names > 0 then table.concat(names, ", ") else "nothing"
			)
		end
	end
	fire(run, out)
	if fight.winner == "foe" then
		defeat(run, "the squad is down")
	elseif run.queued >= #run.plan and run.alive <= 0 then
		clearWave(run, fight)
	elseif run.clock - run.waveStart >= D.WaveMaxSeconds then
		defeat(run, "the wave took too long")
	end
end

local function stepOnce(run: Run, now: number)
	run.clock += Config.Zombies.FightStepSeconds
	local fight = run.fight :: Fight
	local phase = run.phase
	if phase == COUNTDOWN then
		if run.clock >= run.phaseEnd then
			endPhase(run, ACTIVE, 0)
			run.waveStart = run.clock
			run.nextSpawn = run.clock
			publish(run)
		end
	elseif phase == ACTIVE then
		stepActive(run, fight, now)
	elseif phase == CLEARED then
		if run.clock >= run.phaseEnd then
			beginWave(run)
		end
	end
end

local function step(run: Run, dt: number)
	if not run.ready or not run.fight or run.phase == VICTORY or run.phase == DEFEAT then
		return
	end
	local fightStep = Config.Zombies.FightStepSeconds
	run.accumulator = math.min(run.accumulator + dt, fightStep * Config.Zombies.MaxStepsPerFrame)
	while run.accumulator >= fightStep do
		run.accumulator -= fightStep
		stepOnce(run, os.time())
		if run.phase == VICTORY or run.phase == DEFEAT then
			break
		end
	end
end

-- ===== Leaving =====

-- Ends the run from any phase: the wave in play gives nothing (earlier ones were paid), the squad comes home with its
-- wounds, the player goes back to their portal, the arena is destroyed. `quiet`: the player has left the game.
local function leave(run: Run, why: string, quiet: boolean)
	if runs[run.player] ~= run then
		return
	end
	runs[run.player] = nil
	if run.phase == COUNTDOWN or run.phase == ACTIVE then
		DungeonRules.discardWave(run.ledger, run.wave)
	end
	settle(run)
	sendHome(run)
	if not quiet then
		fire(run, { { kind = "end", winner = "left", level = run.level, wave = run.wave }, { kind = "leave" } })
		moveCharacter(run.player, Layout.portalLanding())
		clearPlayerAttributes(run.player)
	end
	run.arena:Destroy()
	print(Config.LogPrefix, "dungeon:", run.player.Name, "left the dungeon (" .. why .. ") at wave", run.wave)
end

-- ===== Requests =====

local function enter(player: Player, data: any, farm: any): { ok: boolean, reason: string? }
	if runs[player] then
		return fail("IN_RUN")
	end
	local plot = Plots.of(player)
	local blocked = DungeonRules.entryBlock(farm)
	if not plot then
		return fail("NO_PLOT")
	elseif blocked then
		return fail(blocked)
	elseif not DungeonRules.canEnter(farm, data.level) then
		return fail("LEVEL_LOCKED")
	elseif not characterAlive(player) then
		return fail("DEAD")
	elseif
		not ZombieFights.near(player, Layout.marketPortal().Position, D.Portal.PromptRangeStuds + D.EnterSlackStuds)
	then
		return fail("TOO_FAR")
	end
	local teams: { number } = table.clone(data.teams)
	local now = os.time()
	local ids, why = squadFor(player, farm, teams, now, {})
	if not ids then
		return fail(why or "NO_FIT")
	end
	local arena = buildArena(plot)
	local monsters = Instance.new("Folder")
	monsters.Name = "Monsters"
	monsters.Parent = arena
	local squad = Instance.new("Folder")
	squad.Name = "Squad"
	squad.Parent = arena
	local run: Run = {
		player = player,
		plot = plot,
		mapId = D.MapOrder[1],
		level = data.level,
		teams = teams,
		members = {},
		out = {},
		arena = arena,
		monsters = monsters,
		squad = squad,
		nodes = {},
		frame = Layout.arenaFrame(plot),
		ready = false,
		phase = COUNTDOWN,
		clock = 0,
		phaseEnd = 0,
		phaseEndTime = 0,
		accumulator = 0,
		wave = 0,
		plan = {},
		queued = 0,
		alive = 0,
		nextSpawn = 0,
		waveStart = 0,
		foes = {},
		fight = nil,
		ledger = DungeonRules.newLedger(),
		seed = 0,
		rng = Rng.new(player.UserId + now + serial),
		settled = false,
		publishAt = 0,
	}
	runs[player] = run
	local started, err = pcall(startRun :: any, run, farm, data.level, ids, now)
	if not started then
		-- (nothing may stay out of the village or in a half-made arena)
		warn(Config.LogPrefix, "dungeon: the run of", player.Name, "did not start:", err)
		leave(run, "error", true)
		return fail("SERVER_ERROR")
	end
	print(
		Config.LogPrefix,
		"dungeon:",
		player.Name,
		"enters level",
		data.level,
		"from plot",
		plot,
		"with",
		#ids,
		"slimes"
	)
	-- the arena is streamed to the player before they are put in it
	task.spawn(function()
		local spot = Layout.arenaPlayerSpot(plot)
		pcall(function()
			(player :: any):RequestStreamAroundAsync(spot.Position, D.StreamSeconds)
		end)
		if runs[player] ~= run then
			return
		end
		moveCharacter(player, spot)
		-- (the countdown starts when the player is there)
		run.phaseEnd = run.clock + D.CountdownSeconds
		run.phaseEndTime = workspace:GetServerTimeNow() + D.CountdownSeconds
		run.ready = true
		publish(run)
	end)
	return { ok = true, reason = nil }
end

-- Another try on the same arena (Next level or Replay): the saved teams are looked at again, so a slime that went tired
-- or was fed stays home or comes along; the survivors' wounds are kept.
local function again(run: Run, level: number, farm: any): { ok: boolean, reason: string? }
	if not DungeonRules.canEnter(farm, level) then
		return fail("LEVEL_LOCKED")
	end
	local now = os.time()
	local ids, why = squadFor(run.player, farm, run.teams, now, run.out)
	if not ids then
		return fail(why or "NO_FIT")
	end
	startRun(run, farm, level, ids, now)
	return { ok = true, reason = nil }
end

-- A request of the Village remote that begins with "Dungeon" (the shape is already checked: VillageRequests.valid).
function Dungeon.request(player: Player, data: any): { ok: boolean, reason: string? }
	local action = data.action
	local farm = PlayerData.get(player)
	if not farm then
		return fail("NOT_READY")
	end
	local run = runs[player]
	if action == "DungeonLeave" then
		if not run then
			return fail("NO_RUN")
		end
		leave(run, "asked", false)
		return { ok = true, reason = nil }
	end
	local clock = os.clock()
	if lastAsk[player] and clock - lastAsk[player] < D.RequestSeconds then
		return fail("RATE_LIMIT")
	end
	lastAsk[player] = clock
	if action == "DungeonEnter" then
		return enter(player, data, farm)
	end
	if not run or not run.ready then
		return fail("NO_RUN")
	end
	if action == "DungeonNext" then
		if run.phase ~= VICTORY then
			return fail("BAD_PHASE")
		end
		return again(run, run.level + 1, farm)
	elseif action == "DungeonReplay" then
		if run.phase ~= VICTORY and run.phase ~= DEFEAT then
			return fail("BAD_PHASE")
		end
		return again(run, run.level, farm)
	end
	return fail("BAD_REQUEST")
end

-- Whether the player is in a run (the village's other systems keep their hands off).
function Dungeon.inRun(player: Player): boolean
	return runs[player] ~= nil
end

function Dungeon.start()
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
	-- the Sunny Meadow is built now, once, so the first run does not wait for it
	task.spawn(DungeonArena.template)
	PlayerData.onReady(function(player: Player, data: any)
		if player.Parent == Players then
			set(player, "DungeonBest", if data and data.dungeon then data.dungeon.best else 0)
			clearPlayerAttributes(player)
		end
	end)
	RunService.Heartbeat:Connect(function(dt: number)
		local clock = os.clock()
		for _, each in runs do
			-- (any: the checker takes the closure's Run for another Run)
			local run: any = each
			local ok, err = pcall(function()
				step(run, dt)
				if clock - run.publishAt >= D.PublishSeconds then
					run.publishAt = clock
					publish(run)
					if run.ready then
						keepIn(run)
					end
				end
			end)
			if not ok then
				-- a run that breaks must not hold the squad: it is ended and everyone goes home
				warn(Config.LogPrefix, "dungeon: run of", run.player.Name, "failed:", err)
				pcall(leave, run, "error", false)
			end
		end
	end)
	-- A player who leaves the game ends their run: the wave in play gives nothing, the wounds and the cost are written,
	-- the squad is home, the arena is gone. Coins and materials of cleared waves were paid when they cleared.
	PlayerData.onLeaving(function(player: Player, _data: any)
		local run = runs[player]
		if run then
			leave(run, "left the game", true)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastAsk[player] = nil
	end)
end

return Dungeon
