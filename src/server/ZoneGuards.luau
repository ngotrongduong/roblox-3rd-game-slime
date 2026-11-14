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
local WorldPlan = require(ReplicatedStorage.Shared.WorldPlan)
local ZoneFights = require(ReplicatedStorage.Shared.ZoneFights)
local PlayerData = require(script.Parent.PlayerData)

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

	PlayerData.onReady(function(player: Player, data: any)
		if player.Parent == Players then
			ZoneGuards.publish(player, data)
		end
	end)
	print(Config.LogPrefix, "zones of the big world ready:", #WorldPlan.Zones, "fights, 3 gates sealed")
end

return ZoneGuards
