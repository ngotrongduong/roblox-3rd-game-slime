--!strict
-- The monsters standing at the zones of the open world (Config.World.Crowds; the owner, 2026-11-16: "at the miniboss spots,
-- a group of monsters"): each zone's guard on the middle of its pad with a few of its map's common monsters round it, all
-- facing the zone's waystone. Client only and only near the camera. Everyone sees them while the guard is up: it is the
-- whole server's (the owner, 2026-11-16: "this is a multiplayer map: hidden, how would the others fight it?"). They are
-- away while it is down, for everyone (its anchor's FellAt and the zone's rest), and only the crowd of the zone the viewer
-- is fighting is away during their fight (the run brings its own monsters). They do nothing but stand and breathe.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dungeon = require(ReplicatedStorage.Shared.Dungeon)
local Rng = require(ReplicatedStorage.Shared.Rng)
local WorldPacks = require(ReplicatedStorage.Shared.WorldPacks)
local WorldPlan = require(ReplicatedStorage.Shared.WorldPlan)
local ZoneFights = require(ReplicatedStorage.Shared.ZoneFights)
local MonsterLook = require(script.Parent:WaitForChild("MonsterLook"))
local SlimeActor = require(script.Parent:WaitForChild("SlimeActor"))
local ZombieWorld = require(script.Parent:WaitForChild("ZombieWorld"))

local K = Config.World.Crowds
local W = Config.World
local player = Players.LocalPlayer

type Body = { model: Model, actor: SlimeActor.Slime? }
type Crowd = {
	id: string,
	defs: { any },
	middle: Vector3,
	toward: Vector3,
	bodies: { Body }?,
}

local folder = Instance.new("Folder")
folder.Name = "ZoneCrowdActors"
folder.Parent = workspace

local crowds: { Crowd } = {}
for _, place in WorldPlan.Zones do
	if table.find(K.Kinds, place.kind) then
		local numbers = (W.Zones :: any)[place.id]
		local waves = numbers.waves
		local guard = Dungeon.defOf(numbers.map, waves[#waves].guard)
		local roster = WorldPacks.roster(numbers.map)
		local defs = { guard }
		local first = Rng.hash(place.id) % #roster
		for index = 1, K.Count do
			table.insert(defs, roster[(first + index) % #roster + 1])
		end
		local x, z = ZoneFights.middle(place.id)
		local sx, sz = ZoneFights.waystone(place.id)
		table.insert(crowds, {
			id = place.id,
			defs = defs,
			middle = Vector3.new(x, 0, z),
			toward = Vector3.new(sx, 0, sz),
			bodies = nil,
		})
	end
end

local function undraw(crowd: Crowd)
	local bodies: { Body } = crowd.bodies or {}
	for _, body in bodies do
		if body.actor then
			SlimeActor.destroy(body.actor)
		end
		body.model:Destroy()
	end
	crowd.bodies = nil
end

-- The zone's anchor (server/ZoneGuards: AnchorLift over the middle of the fight on the ground), once it has streamed in.
local function anchorOf(crowd: Crowd): Instance?
	local guards = workspace:FindFirstChild(W.Folder)
	return if guards then guards:FindFirstChild(crowd.id) else nil
end

local function groundOf(crowd: Crowd): Vector3?
	local anchor = anchorOf(crowd)
	if not anchor or not anchor:IsA("BasePart") then
		return nil
	end
	return anchor.Position - Vector3.new(0, W.AnchorLift, 0)
end

local function draw(crowd: Crowd, foot: Vector3)
	for _, def in crowd.defs do
		if not MonsterLook.ready(def.id) then
			return
		end
	end
	local bodies: { Body } = {}
	for index, def in crowd.defs do
		local at = foot
		if index > 1 then
			local angle = (index - 2) / K.Count * 2 * math.pi
			at = ZombieWorld.groundAt(foot + Vector3.new(math.cos(angle) * K.Ring, 0, math.sin(angle) * K.Ring))
		end
		local look = MonsterLook.build({ defId = def.id, kind = def.kind, role = def.role })
		local model = look.model
		local toward = Vector3.new(crowd.toward.X, at.Y, crowd.toward.Z)
		model:PivotTo(CFrame.lookAt(at, toward))
		model.Parent = folder
		local actor = SlimeActor.new(model, look.face)
		if actor then
			actor.body.CanCollide = false
			if look.creature then
				SlimeActor.dress(actor, look.creature)
			end
			SlimeActor.lookAt(actor, toward)
			SlimeActor.setTravel(actor, at, at, 0, 0, false, "stroll")
		else
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
		table.insert(bodies, { model = model, actor = actor })
	end
	crowd.bodies = bodies
end

local function wanted(crowd: Crowd, from: Vector3): boolean
	if player:GetAttribute("DungeonZone") == crowd.id then
		return false
	end
	local anchor = anchorOf(crowd)
	local fell = if anchor then anchor:GetAttribute("FellAt") else nil
	if type(fell) == "number" and ZoneFights.restLeft(crowd.id, fell, workspace:GetServerTimeNow()) > 0 then
		return false
	end
	local flat = Vector3.new(from.X - crowd.middle.X, 0, from.Z - crowd.middle.Z).Magnitude
	return flat <= K.DrawStuds * (if crowd.bodies then 1.1 else 1)
end

local warned = false
while true do
	local ok, err = pcall(function(): any
		local camera = workspace.CurrentCamera
		if not camera then
			return nil
		end
		local from = camera.CFrame.Position
		for _, crowd in crowds do
			if wanted(crowd, from) then
				if not crowd.bodies then
					local foot = groundOf(crowd)
					if foot then
						draw(crowd, foot)
					end
				end
			elseif crowd.bodies then
				undraw(crowd)
			end
		end
		return nil
	end)
	if not ok and not warned then
		warned = true
		warn(Config.LogPrefix, "zone crowds error:", err)
	end
	task.wait(K.CheckSeconds)
end
