--!nocheck
-- The movement lab's code (tools/slime/hop_lab.ps1 installs it as ModuleScript StarterPlayerScripts.SlimeMotionLab.LabRun,
-- with SlimeFace and Lanes next to it). It is NOT the game's SlimeActor: it keeps its own copy of the jelly (the damped
-- springs and the hop of src/shared/SlimeMotion.luau, written so every number comes from the lane's table in
-- hop_lab_lanes.luau instead of Config.Slime), walks each slime from one end of its lane to the other and back, and
-- draws it through the game's SlimeShape bones and SlimeFace. The review stage and this file are not part of the game.
--
--   Lab.build(stage)    one slime per lane model of Workspace.SlimeMotionLab (attribute Lane = index into Lanes.List)
--   Lab.start()         the render loop (only while the camera is within ActiveStuds of the lab)
--   Lab.step(dt)        one step by hand (the setup uses it in Edit mode to pose the slimes for a picture)
--   Lab.stop()          ONE way out: disconnects the loop and takes the faces down
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeShape = require(ReplicatedStorage.Shared.SlimeShape)
local SlimeFace = require(script.Parent.SlimeFace)
local Lanes = require(script.Parent.Lanes)

local C = Config.Slime
local TAU = math.pi * 2

-- Beyond this distance from the lab's middle the slimes are not stepped (a phone far away pays nothing).
local ACTIVE_STUDS = 220
-- The slime breathes a little while it stands at the end of a lane (the game's idle: amplitude, Hz).
local IDLE_BREATHE, IDLE_HZ = 0.028, 0.55
-- The launch's push up into the squash spring (as SlimeMotion.launch).
local LAUNCH_KICK = 2.2
-- The width puff on a landing (as SlimeMotion.step).
local LAND_PUFF = 0.6
-- A slime facing +X turns by -90 degrees about Y from the default (-Z); facing -X by +90.
local FACE_PLUS_X, FACE_MINUS_X = -math.pi / 2, math.pi / 2
-- The eyes look straight ahead, a hair up, instead of wandering.
local GAZE_Y = 0.1
-- A glide starts at this fraction of its speed, takes this long to reach it, and slows over the last studs.
local GLIDE_START_FRACTION, GLIDE_RAMP_SECONDS, GLIDE_SLOW_STUDS, GLIDE_MIN_FRACTION = 0.2, 0.25, 1.5, 0.15
local ARRIVE_STUDS = 0.03

local Lab = { lanes = {}, parts = {}, cfs = {} }
local connection: RBXScriptConnection? = nil

local function spring()
	return { x = 0, v = 0, to = 0 }
end

local function integrate(sp, hz, damping, dt)
	local w = TAU * hz
	local n = math.max(1, math.ceil(dt / C.SubStep))
	local h = dt / n
	for _ = 1, n do
		local a = w * w * (sp.to - sp.x) - 2 * damping * w * sp.v
		sp.v += a * h
		sp.x += sp.v * h
	end
end

local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function bonesOf(part)
	local root = part:FindFirstChild("Root")
	if not root then
		return nil
	end
	local set = {
		top = root:FindFirstChild("Top"),
		left = root:FindFirstChild("Left"),
		right = root:FindFirstChild("Right"),
		front = root:FindFirstChild("Front"),
		back = root:FindFirstChild("Back"),
	}
	if set.top and set.left and set.right and set.front and set.back then
		return set
	end
	return nil
end

local function writeBones(set, b, s)
	for name, bone in set do
		local v = b[name]
		bone.Transform = CFrame.new(v.x * s, v.y * s, v.z * s)
	end
end

local function remainingStuds(L)
	return if L.dir == 1 then Lanes.Length - L.s else L.s
end

local function beginHop(L)
	local remaining = remainingStuds(L)
	if remaining < ARRIVE_STUDS then
		L.mode, L.timer, L.flipped = "wait", 0, false
		return
	end
	L.mode, L.stage, L.stageT = "hop", "crouch", 0
	L.hopFrom = L.s
	L.hopDist = math.min(L.spec.HopStuds, remaining)
end

local function stepLane(L, dt)
	local P = L.spec
	dt = math.min(dt, C.MaxStep)
	L.t += dt
	local sq, lf, ls, yw, pf = L.sq, L.lf, L.ls, L.yw, L.pf
	sq.to, lf.to, ls.to, yw.to, pf.to = 0, 0, 0, 0, 0

	if L.mode == "wait" then
		L.timer += dt
		sq.to += IDLE_BREATHE * math.sin(TAU * IDLE_HZ * L.t + L.phase)
		-- it stands, then turns round in the middle of the pause, then sets off
		if not L.flipped and L.timer >= Lanes.EndIdle * 0.5 then
			L.dir = -L.dir
			L.flipped = true
		end
		if L.timer >= Lanes.EndIdle then
			if P.mode == "glide" then
				L.mode, L.speed = "glide", GLIDE_START_FRACTION * P.GlideSpeed
			else
				beginHop(L)
			end
		end
	elseif L.mode == "glide" then
		local remaining = remainingStuds(L)
		local fraction = math.max(
			GLIDE_MIN_FRACTION,
			math.min(remaining / GLIDE_SLOW_STUDS, GLIDE_START_FRACTION + (Lanes.Length - remaining) / 1.0)
		)
		L.speed += (P.GlideSpeed * math.min(fraction, 1) - L.speed) * (1 - math.exp(-dt / GLIDE_RAMP_SECONDS))
		L.s = math.clamp(L.s + L.dir * L.speed * dt, 0, Lanes.Length)
		local k = L.speed / P.GlideSpeed
		sq.to = P.GlideBob * math.sin(TAU * P.GlideBobHz * L.t) + 0.03 * k
		lf.to = P.GlideLean * k
		ls.to = 0.02 * k * math.sin(TAU * P.GlideBobHz * 0.5 * L.t)
		if remainingStuds(L) < ARRIVE_STUDS then
			L.mode, L.timer, L.flipped, L.speed = "wait", 0, false, 0
		end
	else
		-- a hop: crouch, launch, fly, land, rest (as SlimeMotion.step)
		local v0 = math.sqrt(2 * P.Gravity * P.HopHeight)
		if L.stage == "crouch" then
			L.stageT += dt
			local k = if P.CrouchSeconds > 0 then smooth(L.stageT / P.CrouchSeconds) else 1
			sq.to = P.CrouchSquash * k
			lf.to = -P.HopLean * 0.6 * k
			if L.stageT >= P.CrouchSeconds then
				L.vy, L.y, L.airT, L.stage = v0, 1e-4, 0, "air"
				sq.v += LAUNCH_KICK
			end
		elseif L.stage == "air" then
			L.airT += dt
			sq.to = P.AirStretch * math.min(math.abs(L.vy) / v0, 1)
			lf.to = P.HopLean
			L.vy -= P.Gravity * dt
			L.y += L.vy * dt
			local progress = math.clamp(L.airT / Lanes.airSeconds(P), 0, 1)
			if P.Ease then
				progress = smooth(progress)
			end
			L.s = L.hopFrom + L.dir * L.hopDist * progress
			if L.y <= 0 and L.vy < 0 then
				sq.v -= P.LandKick * -L.vy
				pf.v += LAND_PUFF * -L.vy
				L.y, L.vy = 0, 0
				L.s = L.hopFrom + L.dir * L.hopDist
				L.stage, L.stageT = "rest", 0
			end
		else
			L.stageT += dt
			if L.stageT >= P.Rest then
				beginHop(L)
			end
		end
	end

	-- the smooth turn
	local goal = if L.dir == 1 then FACE_PLUS_X else FACE_MINUS_X
	L.heading += (goal - L.heading) * (1 - math.exp(-dt / Lanes.TurnSeconds))

	integrate(sq, P.SquashHz, P.SquashDamping, dt)
	integrate(lf, P.LeanHz, P.LeanDamping, dt)
	integrate(ls, P.LeanHz, P.LeanDamping, dt)
	integrate(yw, C.YawHz, C.YawDamping, dt)
	integrate(pf, C.PuffHz, C.PuffDamping, dt)

	local q = math.clamp(sq.x, -0.7, 0.45)
	local pose = {
		sy = math.exp(q),
		sx = math.exp(-P.VolumeBulge * q + math.clamp(pf.x, -0.2, 0.3)),
		leanFwd = math.clamp(lf.x, -0.4, 0.4),
		leanSide = math.clamp(ls.x, -0.4, 0.4),
		yaw = yw.x,
		lift = L.y,
	}
	local bones = SlimeShape.bones(pose)
	local s = L.scale
	writeBones(L.bodyBones, bones, s)
	if L.hullBones then
		writeBones(L.hullBones, bones, s)
	end
	local root = CFrame.new(L.origin + Vector3.new(L.s, 0, 0)) * CFrame.Angles(0, L.heading, 0)
	local feet = root * CFrame.new(0, pose.lift * s, 0) * CFrame.Angles(0, pose.yaw, 0)
	local bodyCf = feet * CFrame.new(0, C.MeshCentre * s, 0)
	local parts, cfs = Lab.parts, Lab.cfs
	local n = #parts + 1
	parts[n], cfs[n] = L.body, bodyCf
	if L.hull then
		n += 1
		parts[n], cfs[n] = L.hull, bodyCf
	end
	SlimeFace.setGaze(L.face, 0, GAZE_Y)
	if SlimeFace.update(L.face, dt, bones, feet, parts, cfs) then
		sq.v += C.BlinkBodyKick
	end
end

function Lab.step(dt: number)
	table.clear(Lab.parts)
	table.clear(Lab.cfs)
	for _, L in Lab.lanes do
		stepLane(L, dt)
	end
	if #Lab.parts > 0 then
		workspace:BulkMoveTo(Lab.parts, Lab.cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function Lab.build(stage: Instance)
	Lab.stop()
	for _, m in stage:GetChildren() do
		local index = m:IsA("Model") and m:GetAttribute("Lane")
		local spec = if index then Lanes.List[index] else nil
		local body = if spec then m:FindFirstChild("SlimeBody") else nil
		if body then
			local hull = m:FindFirstChild("SlimeBodyOutline")
			local scale = body.Size.Y / C.MeshHeight
			table.insert(Lab.lanes, {
				spec = spec,
				model = m,
				body = body,
				hull = hull,
				bodyBones = bonesOf(body),
				hullBones = if hull then bonesOf(hull) else nil,
				scale = scale,
				face = SlimeFace.new(m, scale, index * 17),
				origin = m:GetPivot().Position,
				s = 0,
				dir = 1,
				heading = FACE_PLUS_X,
				sq = spring(),
				lf = spring(),
				ls = spring(),
				yw = spring(),
				pf = spring(),
				y = 0,
				vy = 0,
				t = index * 0.37,
				phase = index * 1.3,
				-- everybody sets off together after a short stand
				mode = "wait",
				timer = Lanes.EndIdle - 0.6,
				flipped = true,
				speed = 0,
				stage = "rest",
				stageT = 0,
				airT = 0,
				hopFrom = 0,
				hopDist = 0,
			})
		end
	end
	table.sort(Lab.lanes, function(a, b)
		return a.spec.key < b.spec.key
	end)
end

function Lab.start()
	if connection then
		return
	end
	local mid = nil
	for _, L in Lab.lanes do
		mid = L.origin + Vector3.new(Lanes.Length / 2, 0, 0)
		break
	end
	connection = RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if mid and camera and (camera.CFrame.Position - mid).Magnitude > ACTIVE_STUDS then
			return
		end
		Lab.step(dt)
	end)
end

-- Every way out: the loop, the faces (their parts and pictures), the lanes.
function Lab.stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	for _, L in Lab.lanes do
		SlimeFace.destroy(L.face)
	end
	table.clear(Lab.lanes)
end

return Lab
