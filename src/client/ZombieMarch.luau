--!strict
-- The march drawn (the owner, 2026-11-02): from the moment a team sets out until it is back at the gate its members are real
-- slime bodies outside the village (SlimeLook, SlimeActor), hopping together along the leg the server publishes under
-- Teams/<n> (From, To, LegStart, LegEnd), spread side by side in a small formation. The hops follow
-- Config.Zombies.MarchGait and VillagePath.progress, so they fit the server's time; a long leg is cut into pieces of a few
-- hops, each measured against the ground again. While the team fights its bodies stand at the end of the leg (ZombieFight
-- draws the fight on them) and when it ends they turn round and hop home. Bodies exist only near the camera. It decides
-- nothing: the village draws the slimes again when the server says they are home.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Gaits = require(ReplicatedStorage.Shared.Gaits)
local VillagePath = require(ReplicatedStorage.Shared.VillagePath)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeLook = require(script.Parent.SlimeLook)
local ZombieTeams = require(script.Parent.ZombieTeams)
local ZombieWorld = require(script.Parent.ZombieWorld)

local Z = Config.Zombies
local V = Z.View

export type Body = {
	id: string,
	team: number,
	-- the place in the team's formation
	slot: number,
	count: number,
	model: Model,
	actor: SlimeActor.Slime,
	-- "travel" hops along the leg; "stand" is where it fights
	mode: string,
	key: string,
	face: string,
	stand: Vector3,
	facing: Vector3,
}

local ZombieMarch = {}
local bodies: { [string]: Body } = {}
local snapshot: { [number]: ZombieTeams.Team } = {}
local stepConnection: RBXScriptConnection? = nil
local started = false
local warned: { [string]: boolean } = {}

local function safe(label: string, work: () -> ())
	local ok, err = pcall(function(): any
		work()
		return nil
	end)
	if not ok and not warned[label] then
		warned[label] = true
		warn(Config.LogPrefix, "zombie march", label, "error:", err)
	end
end

local function slimeNode(id: string): Configuration?
	local root = ZombieTeams.root()
	local folder = if root then root:FindFirstChild("Slimes") else nil
	local found = if folder then folder:FindFirstChild(id) else nil
	return if found and found:IsA("Configuration") then found else nil
end

-- The flat way the team faces: towards the zombies (the going leg's way, also while it returns).
local function lead(team: ZombieTeams.Team): Vector3
	local delta = if team.state == "returning" then team.from - team.to else team.to - team.from
	local flat = Vector3.new(delta.X, 0, delta.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
end

-- Where a member stands beside the team's line (side by side, every other one a step behind).
local function offsetOf(team: ZombieTeams.Team, slot: number, count: number): Vector3
	local dir = lead(team)
	local across = Vector3.new(-dir.Z, 0, dir.X)
	return across * ((slot - (count + 1) / 2) * V.FormationSpacing) - dir * ((slot % 2) * V.FormationStagger)
end

local function ground(point: Vector3): Vector3
	return ZombieWorld.groundOnMap(point.X, point.Z)
end

-- ===== Bodies =====

local function destroyBody(body: Body)
	SlimeActor.destroy(body.actor)
	body.model:Destroy()
	bodies[body.id] = nil
	if next(bodies) == nil and stepConnection then
		stepConnection:Disconnect()
		stepConnection = nil
	end
end

local function numberOf(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if type(value) == "number" and value == value then value else default
end

-- The leg's piece the body is on now, set as its travel (the actor does the hopping and the ground under its feet).
local function travel(body: Body, team: ZombieTeams.Team, now: number)
	local gait = Z.MarchGait
	local offset = offsetOf(team, body.slot, body.count)
	local fromPoint, toPoint = team.from + offset, team.to + offset
	local total = team.legEnd - team.legStart
	local key = tostring(team.legStart)
	local a, b, t0, t1 = 0, 1, team.legStart, team.legEnd
	if total > 0 and not Gaits.isGlide(gait) then
		local cycle = VillagePath.cycle(gait)
		local hops = math.max(1, math.round(total / cycle))
		local per = math.max(1, V.SegmentHops)
		local elapsed = math.clamp(now - team.legStart, 0, total)
		local piece = math.min(math.floor(elapsed / (per * cycle)), math.ceil(hops / per) - 1)
		local first, last = piece * per, math.min((piece + 1) * per, hops)
		a, b = first / hops, last / hops
		t0, t1 = team.legStart + first * cycle, team.legStart + last * cycle
		key = key .. ":" .. tostring(piece)
	end
	key = key .. ":" .. tostring(body.slot) .. "/" .. tostring(body.count)
	if body.mode == "travel" and body.key == key then
		return
	end
	body.mode, body.key = "travel", key
	body.facing = lead(team)
	SlimeActor.setTravel(
		body.actor,
		ground(fromPoint:Lerp(toPoint, a)),
		ground(fromPoint:Lerp(toPoint, b)),
		t0,
		t1,
		false,
		gait
	)
	if body.face ~= "normal" then
		body.face = "normal"
		SlimeActor.setEmotion(body.actor, "normal")
	end
end

-- The team has met its group: the body stands at the end of the leg, facing the zombies (the fight takes it from here).
local function stand(body: Body, team: ZombieTeams.Team)
	local offset = offsetOf(team, body.slot, body.count)
	local key = "stand:" .. tostring(team.legStart) .. ":" .. tostring(body.slot) .. "/" .. tostring(body.count)
	if body.mode == "stand" and body.key == key then
		return
	end
	body.mode, body.key = "stand", key
	body.facing = lead(team)
	body.stand = ground(team.to + offset)
	local actor = body.actor
	actor.travelFrom, actor.travelTo = nil, nil
	SlimeActor.setCFrame(actor, CFrame.lookAt(body.stand, body.stand + body.facing))
	if body.face ~= V.FighterFace then
		body.face = V.FighterFace
		SlimeActor.setEmotion(actor, V.FighterFace)
	end
end

local function apply(body: Body, team: ZombieTeams.Team, now: number)
	if team.state == "going" or team.state == "returning" then
		travel(body, team, now)
	elseif team.state == "fighting" then
		stand(body, team)
	end
end

-- Every frame: a body that has finished its piece of the leg takes the next one.
local function step()
	local now = workspace:GetServerTimeNow()
	for id, body in bodies do
		safe("step " .. id, function()
			local team = snapshot[body.team]
			if team and (team.state == "going" or team.state == "returning") then
				travel(body, team, now)
			end
		end)
	end
end

local function build(team: ZombieTeams.Team, slot: number, count: number, id: string): Body?
	local node = slimeNode(id)
	if not node then
		return nil
	end
	local model = SlimeLook.build({
		Colour = node:GetAttribute("Colour"),
		Material = node:GetAttribute("Material"),
		DualId = node:GetAttribute("DualId"),
		SecretId = node:GetAttribute("SecretId"),
		Scale = numberOf(node, "Scale", 1),
	})
	model.Name = "March_" .. id
	local facing = lead(team)
	local start = ground(team.from + offsetOf(team, slot, count))
	model:PivotTo(CFrame.lookAt(start, start + facing))
	model.Parent = workspace:FindFirstChild("ZombieClientActors") or workspace
	local actor = SlimeActor.new(model, "normal")
	if not actor then
		model:Destroy()
		return nil
	end
	actor.body.CanCollide = false
	local body: Body = {
		id = id,
		team = team.index,
		slot = slot,
		count = count,
		model = model,
		actor = actor,
		mode = "",
		key = "",
		face = "normal",
		stand = start,
		facing = facing,
	}
	bodies[id] = body
	if team.state == "fighting" then
		-- arriving into a fight already on: a pop, as the slime joins it
		SlimeActor.kick(actor, "squash", V.PopSquash)
		SlimeActor.hop(actor, V.PopHop)
	end
	if not stepConnection then
		stepConnection = RunService.RenderStepped:Connect(step)
	end
	return body
end

-- Which teams are out and near the camera, and so which bodies to have.
local function check()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local now = workspace:GetServerTimeNow()
	local from = camera.CFrame.Position
	local wanted: { [string]: boolean } = {}
	table.clear(snapshot)
	for index, team in ZombieTeams.all() do
		snapshot[index] = team
		local position = ZombieTeams.position(team, now)
		if position then
			local has = false
			for _, id in team.marching do
				if bodies[id] then
					has = true
				end
			end
			local limit = if has then Z.DrawDistance * V.HideMargin else Z.DrawDistance
			if (Vector3.new(position.X, from.Y, position.Z) - from).Magnitude <= limit then
				for slot, id in team.marching do
					wanted[id] = true
					local body: Body? = bodies[id]
					if not body then
						body = build(team, slot, #team.marching, id)
					end
					if body then
						body.team, body.slot, body.count = index, slot, #team.marching
						apply(body, team, now)
					end
				end
			end
		end
	end
	local gone: { Body } = {}
	for id, body in bodies do
		if not wanted[id] then
			table.insert(gone, body)
		end
	end
	for _, body in gone do
		destroyBody(body)
	end
end

-- ===== Who is where, for the fight =====

function ZombieMarch.body(id: string): Body?
	return bodies[id]
end

-- Whether any body of this team is drawn (the team is near the camera).
function ZombieMarch.drawn(teamIndex: number): boolean
	for _, body in bodies do
		if body.team == teamIndex then
			return true
		end
	end
	return false
end

function ZombieMarch.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			safe("check", check)
			task.wait(V.MarchCheckSeconds)
		end
	end)
end

return ZombieMarch
