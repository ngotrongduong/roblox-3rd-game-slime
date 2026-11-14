--!strict
-- The zones of the big world on the server (docs/WORLD.md §7, M5; rules in shared/ZoneFights, numbers in Config.World):
-- where each zone's fight stands, the prompt that offers it, the seal of every gate of the Heart, and each player's wins
-- as attributes. The fight itself is a Dungeon run (server/Dungeon).
--
--   workspace.ZoneGuards.<zone id>   an unseen Part over the middle of the zone's fight. Attributes: Zone (its id),
--                     ZoneName, Level (the level its guard shows). Child: ZonePrompt (ProximityPrompt), answered by each
--                     client for itself (client/UiDungeon: the sheet, the rest, the lock).
--   workspace.ZoneGates.<gate id>    an unseen wall across a gate of the Heart. Attributes: Zone (the boss zone that
--                     opens it), ZoneName. A client lets its own player through once that zone is won (client/UiDungeon);
--                     what the server holds to is the Heart's own fight, which needs the three bosses.
--   Player            Zone_<id>: os.time of the player's last win in that zone, 0 for never
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local WorldPlan = require(ReplicatedStorage.Shared.WorldPlan)
local ZoneFights = require(ReplicatedStorage.Shared.ZoneFights)
local PlayerData = require(script.Parent.PlayerData)
local Waystone = require(script.Parent.Waystone)

local W = Config.World

local ZoneGuards = {}
local frames: { [string]: CFrame } = {}

-- The top of the land at a flat point (the terrain only: no rock, tree or player), nil where there is none.
local function ground(x: number, z: number): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(Vector3.new(x, 2000, z), Vector3.new(0, -4000, 0), params)
	return if hit then hit.Position.Y else nil
end

local function unseen(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

-- The middle of a zone's fight, on the ground, unturned (the squad stands south of it, as in the Dungeon's arena).
function ZoneGuards.frame(id: string): CFrame
	local found = frames[id]
	if not found then
		local x, z = ZoneFights.middle(id)
		local y = ground(x, z)
		if not y then
			warn(Config.LogPrefix, "zone", id, "has no ground under its middle")
		end
		found = CFrame.new(x, y or 0, z)
		frames[id] = found
	end
	return found
end

-- Where the player stands for a zone's fight: the Dungeon's spot from the middle, on the ground there.
function ZoneGuards.spot(id: string): CFrame
	local D = Config.Dungeon
	local frame = ZoneGuards.frame(id)
	local at = frame * Vector3.new(D.PlayerSpot.x, 0, D.PlayerSpot.z)
	local y = ground(at.X, at.Z) or frame.Position.Y
	local toward = frame.Position - at
	return CFrame.new(at.X, y + D.PlayerLift, at.Z) * CFrame.Angles(0, math.atan2(-toward.X, -toward.Z), 0)
end

-- Where quick travel puts a character at a zone's waystone: on the ground, `lift` studs up, facing the pad.
function ZoneGuards.landing(id: string, lift: number): CFrame
	local x, z = ZoneFights.landing(id)
	local middleX, middleZ = ZoneFights.middle(id)
	local at = Vector3.new(x, (ground(x, z) or ZoneGuards.frame(id).Position.Y) + lift, z)
	return CFrame.lookAt(at, Vector3.new(middleX, at.Y, middleZ))
end

-- A player's wins, for their own client: the prompts, the rests and the gates read them.
function ZoneGuards.publish(player: Player, farm: any)
	local beaten = if farm and farm.world then farm.world.beaten else {}
	for id in W.Zones :: { [string]: any } do
		local at = beaten[id] or 0
		if player:GetAttribute(W.Attribute .. id) ~= at then
			player:SetAttribute(W.Attribute .. id, at)
		end
	end
end

local function folder(name: string): Folder
	local made = Instance.new("Folder")
	made.Name = name
	made.Parent = workspace
	return made
end

function ZoneGuards.start()
	local guards = folder(W.Folder)
	for _, place in WorldPlan.Zones do
		local frame = ZoneGuards.frame(place.id)
		local anchor = unseen(place.id, Vector3.one, frame + Vector3.new(0, W.AnchorLift, 0), guards)
		anchor:SetAttribute("Zone", place.id)
		anchor:SetAttribute("ZoneName", place.name)
		anchor:SetAttribute("Level", ZoneFights.level(place.id))
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ZonePrompt"
		prompt.ActionText = "Fight"
		prompt.ObjectText = place.name
		prompt.MaxActivationDistance = W.PromptRangeStuds
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchor
	end

	-- The seals: a wall across each gate's arch, facing the Heart's middle.
	local gates = folder(W.GateFolder)
	local heartX, heartZ = WorldPlan.world(WorldPlan.Heart.x, WorldPlan.Heart.z)
	for gateId, zoneId in W.Gates :: { [string]: string } do
		local site = WorldPlan.find(gateId)
		local zone = WorldPlan.find(zoneId)
		if site and zone then
			local x, z = WorldPlan.world(site.x, site.z)
			local y = ground(x, z)
			if not y then
				warn(Config.LogPrefix, "gate", gateId, "has no ground under it")
			end
			local foot = Vector3.new(x, (y or 0) + W.Seal.Lift + W.Seal.Height / 2, z)
			local seal = unseen(
				gateId,
				Vector3.new(W.Seal.Width, W.Seal.Height, W.Seal.Depth),
				CFrame.lookAt(foot, Vector3.new(heartX, foot.Y, heartZ)),
				gates
			)
			seal.CanCollide = true
			seal:SetAttribute("Zone", zoneId)
			seal:SetAttribute("ZoneName", zone.name)
		end
	end

	-- The rim: an unseen wall along the crest between the gates, and over each seal, so the gates are the only way in.
	local R = WorldPlan.Heart.RimRadius
	local wall = W.RimWall
	local seals: { BasePart } = {}
	local angles: { number } = {}
	local floor = math.huge
	for _, seal in gates:GetChildren() do
		if seal:IsA("BasePart") then
			table.insert(seals, seal)
			table.insert(angles, math.atan2(seal.Position.Z - heartZ, seal.Position.X - heartX))
			floor = math.min(floor, seal.Position.Y - seal.Size.Y / 2)
		end
	end
	table.sort(angles)
	local pieces = 0
	local rim = folder(wall.Folder)
	local function solid(name: string, size: Vector3, cf: CFrame)
		unseen(name, size, cf, rim).CanCollide = true
		pieces += 1
	end
	if #angles > 0 then
		local middleY = floor - wall.Sink + wall.Height / 2
		for _, seal in seals do
			local over = floor - wall.Sink + wall.Height - (seal.Position.Y + seal.Size.Y / 2)
			solid(
				"Over_" .. seal.Name,
				Vector3.new(seal.Size.X, over, wall.Depth),
				seal.CFrame + Vector3.new(0, (seal.Size.Y + over) / 2, 0)
			)
		end
		-- (the wall runs a little into each seal's width, so no slit is left beside it)
		local half = (W.Seal.Width / 2 - wall.Depth) / R
		for index, from in angles do
			local to = angles[index % #angles + 1]
			if to <= from then
				to += 2 * math.pi
			end
			local span = (to - half) - (from + half)
			local count = math.max(1, math.ceil(span * R / wall.SegmentStuds))
			for step = 1, count do
				local angle = from + half + span * (step - 0.5) / count
				local at = Vector3.new(heartX + R * math.cos(angle), middleY, heartZ + R * math.sin(angle))
				solid(
					"Rim",
					Vector3.new(span * R / count + wall.Depth, wall.Height, wall.Depth),
					CFrame.lookAt(at, Vector3.new(heartX, middleY, heartZ))
				)
			end
		end
	end

	-- The waystones: one beside every zone's pad (its rune towards the pad), one inside every village's gate (towards the
	-- gate's path). The clients answer their prompts (the map); travel itself is server/QuickTravel's.
	local stones = folder(W.Waystones.Folder)
	local feet: { CFrame } = {}
	local function stone(
		name: string,
		x: number,
		z: number,
		title: string,
		towardX: number,
		towardZ: number,
		lawn: boolean?
	): Part
		local y = ground(x, z) or 0
		if lawn then
			-- (a village's lawn lies over the land: the stone stands on what is walked on)
			local top = workspace:Raycast(Vector3.new(x, y + 40, z), Vector3.new(0, -80, 0))
			y = if top then top.Position.Y else y
		end
		table.insert(feet, CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(towardX, y, towardZ)))
		local anchor = unseen(name, Vector3.one, CFrame.new(x, y + W.Waystones.Lift, z), stones)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "WaystonePrompt"
		prompt.ActionText = "Travel"
		prompt.ObjectText = title
		prompt.MaxActivationDistance = W.Waystones.PromptRangeStuds
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchor
		return anchor
	end
	for _, place in WorldPlan.Zones do
		local x, z = ZoneFights.waystone(place.id)
		local middleX, middleZ = ZoneFights.middle(place.id)
		stone(place.id, x, z, place.name, middleX, middleZ):SetAttribute("Zone", place.id)
	end
	for plot = 1, Config.Map.PlotCount do
		local gate = Layout.plotGate(plot)
		local at = (gate * CFrame.new(W.Waystones.HomeAcross, 0, W.Waystones.HomeIn)).Position
		local path = (gate * CFrame.new(0, 0, W.Waystones.HomeIn)).Position
		stone("home" .. plot, at.X, at.Z, "Home", path.X, path.Z, true):SetAttribute("Plot", plot)
	end
	-- their looks, once the kit meshes have come (the anchors and prompts do not wait for them)
	task.spawn(function()
		if not Waystone.load() then
			return
		end
		local looks = folder(W.Waystones.LookFolder)
		for _, foot in feet do
			Waystone.build(foot).Parent = looks
		end
		print(Config.LogPrefix, "waystones:", #feet, "stand in the world")
	end)

	PlayerData.onReady(function(player: Player, data: any)
		if player.Parent == Players then
			ZoneGuards.publish(player, data)
		end
	end)
	print(
		Config.LogPrefix,
		"zones of the big world ready:",
		#WorldPlan.Zones,
		"fights, 3 gates sealed, the rim walled in",
		pieces,
		"pieces,",
		#stones:GetChildren(),
		"waystones"
	)
end

return ZoneGuards
