--!strict
-- One living slime: the shared skinned body (SlimeBody + its outline hull, Bone.Transform about the feet), its face
-- (SlimeFace) and its jelly motion (SlimeMotion), with the three calls a future brain needs:
--
--   actor:setEmotion("happy")        the face and the body motion that goes with it (Expressions)
--   actor:lookAt(somewhere)          eyes (and a curious body) turn toward a point, a part or a model; nil = nothing
--   actor:playMotion("excited")      a body motion by name (SlimeMotion.Motions) until the next setEmotion
--   actor:hop(0.25)                  one hop (crouch, launch, stretch, landing squash and wobble)
--
-- ONE loop (RenderStepped, only connected while an actor exists) steps every actor: slimes within FullStuds and in
-- front of the camera every frame, farther ones at FarHz, those behind the camera or beyond SleepStuds only their
-- physics or nothing. All the parts that moved go in a single BulkMoveTo.
--
-- The model passed in holds the body as the SlimeShowcase builds it (a MeshPart "SlimeBody", optionally
-- "SlimeBodyOutline"); its pivot must be at the feet and its scale already set. The slime's front is the model's
-- look vector.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Expressions = require(ReplicatedStorage.Shared.Expressions)
local SlimeMotion = require(ReplicatedStorage.Shared.SlimeMotion)
local VillagePath = require(ReplicatedStorage.Shared.VillagePath)
local SlimeShape = require(ReplicatedStorage.Shared.SlimeShape)
local SlimeFace = require(script.Parent.SlimeFace)

local C = Config.Slime
-- The village's presentation numbers (ghost float, separation, facing, carried items).
local VC = Config.VillageClient

type BoneSet = { top: Bone, left: Bone, right: Bone, front: Bone, back: Bone }

export type Slime = {
	model: Model,
	body: MeshPart,
	hull: MeshPart?,
	bodyBones: BoneSet?,
	hullBones: BoneSet?,
	scale: number,
	root: CFrame,
	motion: SlimeMotion.State,
	face: SlimeFace.Face,
	target: Vector3?,
	targetPart: Instance?,
	override: boolean,
	acc: number,
	yawning: boolean,
	pose: SlimeMotion.Pose,
	destroyed: boolean,
	travelFrom: Vector3?,
	travelTo: Vector3?,
	travelStart: number,
	travelEnd: number,
	hopIndex: number,
	ghost: boolean,
	ground: Vector3,
	separation: Vector3,
	attached: Model?,
	attachedParts: { BasePart },
	attachedOffsets: { CFrame },
	attachOffset: CFrame,
	-- What the slime turns its body to while it stands still (a bin, the well, the water); nil keeps the heading.
	faceTarget: Vector3?,
	-- The height of the ground under the slime (raycast), and where it was last measured.
	groundY: number?,
	groundAt: Vector3?,
	-- A tool held in front of the body (a rod, a hoe): its parts and a pose that may change with time,
	-- relative to the feet frame (front = -Z, up = +Y), in studs.
	held: Model?,
	heldParts: { BasePart },
	heldOffsets: { CFrame },
	heldPose: ((now: number) -> CFrame)?,
}

local Actor = {}
Actor.__index = Actor

local actors: { Slime } = {}
local connection: RBXScriptConnection? = nil
local parts: { BasePart } = {}
local cfs: { CFrame } = {}
local seedCounter = 0
-- The ground ray skips every drawn slime, the server's village folders and the local character.
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
local function refreshRayFilter()
	local list: { Instance } = {}
	for _, name in { "VillageClientActors", "Villages" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(list, folder)
		end
	end
	for _, player in game:GetService("Players"):GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
end
local filterAt = -math.huge

local function bonesOf(part: BasePart): BoneSet?
	local root = part:FindFirstChild("Root")
	if not root then
		return nil
	end
	local top, left, right, front, back =
		root:FindFirstChild("Top"),
		root:FindFirstChild("Left"),
		root:FindFirstChild("Right"),
		root:FindFirstChild("Front"),
		root:FindFirstChild("Back")
	if top and left and right and front and back then
		return {
			top = top :: Bone,
			left = left :: Bone,
			right = right :: Bone,
			front = front :: Bone,
			back = back :: Bone,
		}
	end
	return nil
end

local function writeBones(set: BoneSet, b: SlimeShape.Bones, s: number)
	set.top.Transform = CFrame.new(b.top.x * s, b.top.y * s, b.top.z * s)
	set.left.Transform = CFrame.new(b.left.x * s, b.left.y * s, b.left.z * s)
	set.right.Transform = CFrame.new(b.right.x * s, b.right.y * s, b.right.z * s)
	set.front.Transform = CFrame.new(b.front.x * s, b.front.y * s, b.front.z * s)
	set.back.Transform = CFrame.new(b.back.x * s, b.back.y * s, b.back.z * s)
end

local function targetPosition(a: Slime): Vector3?
	local p = a.targetPart
	if p then
		if p:IsA("Model") then
			return p:GetPivot().Position
		elseif p:IsA("BasePart") then
			return p.Position
		end
	end
	return a.target
end

-- Replicated endpoints stay fixed for a leg. Movement is evaluated in the single render loop,
-- never from the village's slower network/metadata polling loop.
local function desired(a: Slime, now: number): Vector3
	local from, to = a.travelFrom, a.travelTo
	if not from or not to then
		return a.root.Position
	end
	local fraction = VillagePath.progress(a.travelStart, a.travelEnd, now)
	local pos = from:Lerp(to, fraction)
	if a.ghost then
		pos += Vector3.new(0, VC.GhostFloat + VC.GhostFloat * math.sin(now * VC.GhostFloatHz * math.pi * 2), 0)
	end
	return pos
end

local function walk(a: Slime, dt: number, now: number)
	local from, to = a.travelFrom, a.travelTo
	if not from or not to then
		return
	end
	local fraction, index = VillagePath.progress(a.travelStart, a.travelEnd, now)
	local moving = a.travelEnd > a.travelStart and now >= a.travelStart and now < a.travelEnd
	a.motion.walking = moving
	if moving and index ~= a.hopIndex then
		SlimeMotion.hop(a.motion, VC.HopHeight)
	end
	a.hopIndex = index
	local pos = from:Lerp(to, fraction)
	if a.ghost then
		pos += Vector3.new(0, VC.GhostFloat + VC.GhostFloat * math.sin(now * VC.GhostFloatHz * math.pi * 2), 0)
	end
	local away = Vector3.zero
	for _, other in actors do
		if
			other ~= a
			and not other.destroyed
			and math.abs(pos.X - other.ground.X) < VC.SlimeSeparationStuds
			and math.abs(pos.Z - other.ground.Z) < VC.SlimeSeparationStuds
		then
			local delta = pos - other.ground
			local flat = Vector3.new(delta.X, 0, delta.Z)
			if flat.Magnitude < VC.SlimeSeparationStuds then
				local direction = if flat.Magnitude > Config.Village.PathPointEpsilon
					then flat.Unit
					else Vector3.new(math.cos(a.motion.phase), 0, math.sin(a.motion.phase))
				away += direction * ((VC.SlimeSeparationStuds - flat.Magnitude) * VC.SeparationBlend)
			end
		end
	end
	if away.Magnitude > VC.SeparationMaxStuds then
		away = away.Unit * VC.SeparationMaxStuds
	end
	a.separation = a.separation:Lerp(away, 1 - math.exp(-dt / VC.SeparationSmoothSeconds))
	pos += a.separation
	-- Feet on the ground below, whatever the server's points say (no hovering over a slope, no sinking into
	-- paving). Measured again only when the slime has moved; a ghost floats above the ground it measures.
	local flatPos = Vector3.new(pos.X, 0, pos.Z)
	if not a.groundAt or (a.groundAt - flatPos).Magnitude > VC.GroundRecastStuds then
		a.groundAt = flatPos
		local start = Vector3.new(pos.X, pos.Y + VC.GroundProbeUp, pos.Z)
		local down = Vector3.new(0, -(VC.GroundProbeUp + VC.GroundProbeDown), 0)
		local hit = workspace:Raycast(start, down, rayParams)
		if not hit or hit.Material == Enum.Material.Water then
			-- (a ball does not fall through the gaps between dock planks)
			hit = workspace:Spherecast(start, VC.GroundProbeRadius, down, rayParams) or hit
		end
		a.groundY = if hit then hit.Position.Y else nil
	end
	if a.groundY then
		local floatBy = if a.ghost
			then VC.GhostFloat + VC.GhostFloat * math.sin(now * VC.GhostFloatHz * math.pi * 2)
			else 0
		pos = Vector3.new(pos.X, a.groundY + floatBy, pos.Z)
	end
	local direction = to - from
	local flat = Vector3.new(direction.X, 0, direction.Z)
	local still = not moving
	local face = a.faceTarget
	if still and face then
		local toward = Vector3.new(face.X - pos.X, 0, face.Z - pos.Z)
		if toward.Magnitude > VC.FacingThreshold then
			local goal = CFrame.lookAt(pos, pos + toward)
			local alpha = 1 - math.exp(-dt / VC.FacingTurnSeconds)
			a.root = CFrame.new(pos) * a.root.Rotation:Lerp(goal.Rotation, alpha)
		else
			a.root = CFrame.new(pos) * a.root.Rotation
		end
	elseif flat.Magnitude > VC.FacingThreshold then
		local goal = CFrame.lookAt(pos, pos + flat)
		-- Interpolate rotation only: an old yaw must never pull the feet off the server's path.
		local alpha = 1 - math.exp(-dt / VC.FacingTurnSeconds)
		local turned = a.root.Rotation:Lerp(goal.Rotation, alpha)
		a.root = CFrame.new(pos) * turned
	else
		a.root = CFrame.new(pos) * a.root.Rotation
	end
end

local function tick(a: Slime, dt: number, write: boolean)
	walk(a, dt, workspace:GetServerTimeNow())
	-- where the target is, in the slime's own frame
	local dirFwd, dirSide, gx, gy = 0, 0, nil :: number?, nil :: number?
	local tp = targetPosition(a)
	if tp then
		local rel = a.root:PointToObjectSpace(tp)
		local dist = math.max(rel.Magnitude, 0.001)
		dirFwd, dirSide = -rel.Z / dist, -rel.X / dist
		-- the eyes turn toward the viewer's right (-X of the slime's frame) and up; behind it they go to the side
		gx = if dirFwd >= 0 then math.clamp(dirSide * 1.5, -1, 1) else (if dirSide >= 0 then 1 else -1)
		gy = math.clamp((rel.Y - a.scale * 0.5) / dist * 2, -1, 1)
	end
	SlimeFace.setGaze(a.face, gx, gy)

	-- (the physics takes steps of at most MaxStep, so a far slime's longer wait is several steps)
	local ctx = { dirFwd = dirFwd, dirSide = dirSide }
	local pose = a.pose
	local left = dt
	repeat
		local d = math.min(left, C.MaxStep)
		pose = SlimeMotion.step(a.motion, d, ctx)
		left -= d
	until left <= 1e-6
	a.pose = pose
	if a.motion.landed then
		a.motion.landed = false
	end
	if not write then
		return
	end

	local bones = SlimeShape.bones(pose)
	local s = a.scale
	if a.bodyBones then
		writeBones(a.bodyBones, bones, s)
	end
	if a.hullBones then
		writeBones(a.hullBones, bones, s)
	end
	local feet = a.root * CFrame.new(0, pose.lift * s, 0) * CFrame.Angles(0, pose.yaw, 0)
	local bodyCf = feet * CFrame.new(0, C.MeshCentre * s, 0)
	local n = #parts
	n += 1
	parts[n] = a.body
	cfs[n] = bodyCf
	if a.hull then
		n += 1
		parts[n] = a.hull
		cfs[n] = bodyCf
	end
	if a.attached then
		-- Carries share this BulkMoveTo, including lift, squash and the jelly's lean.
		local top = a.root
			* CFrame.new(-pose.leanSide * s, pose.lift * s + s * pose.sy + VC.CarryTopOffset, -pose.leanFwd * s)
			* CFrame.Angles(pose.leanFwd, pose.yaw, pose.leanSide)
			* a.attachOffset
		for i, part in a.attachedParts do
			n += 1
			parts[n] = part
			cfs[n] = top * a.attachedOffsets[i]
		end
	end
	local heldPose = a.heldPose
	if a.held and heldPose then
		-- A held tool follows the body's hop and lean; its pose is in studs for a full-size slime.
		local grip = a.root
			* CFrame.new(-pose.leanSide * s, pose.lift * s, -pose.leanFwd * s)
			* CFrame.Angles(pose.leanFwd, pose.yaw, pose.leanSide)
		local held = heldPose(workspace:GetServerTimeNow())
		local heldCf = grip * CFrame.new(held.Position * s / VC.BodyHeight) * held.Rotation
		for i, part in a.heldParts do
			n += 1
			parts[n] = part
			cfs[n] = heldCf * a.heldOffsets[i]
		end
	end
	local blinked = SlimeFace.update(a.face, dt, bones, feet, parts, cfs)
	if blinked then
		SlimeMotion.kick(a.motion, "squash", C.BlinkBodyKick)
	end
	-- a yawn stretches the body too
	local yawning = a.face.yawnT >= 0
	if yawning and not a.yawning then
		SlimeMotion.kick(a.motion, "squash", 2.2)
		SlimeMotion.kick(a.motion, "lean", -1.2)
	end
	a.yawning = yawning
end

-- `force` (by hand only): every slime counts as close, wherever the camera is.
local function stepAll(dt: number, force: boolean?)
	local camera = workspace.CurrentCamera
	local camCf = if camera then camera.CFrame else nil
	table.clear(parts)
	table.clear(cfs)
	local now = workspace:GetServerTimeNow()
	if now - filterAt > 1 then
		filterAt = now
		refreshRayFilter()
	end
	for _, actor in actors do
		actor.ground = desired(actor, now)
	end
	for i = #actors, 1, -1 do
		local a = actors[i]
		if a.destroyed or not a.model.Parent then
			a.destroyed = true
			table.remove(actors, i)
		else
			a.acc += dt
			local mode = 0 -- 0 every frame, 1 at FarHz with writes, 2 at FarHz physics only, 3 nothing
			if camCf and not force then
				local rel = a.root.Position - camCf.Position
				local d = rel.Magnitude
				if d > C.SleepStuds then
					mode = 3
				elseif d > C.FarStuds or (d > 12 and rel:Dot(camCf.LookVector) < 0) then
					mode = 2
				elseif d > C.FullStuds then
					mode = 1
				end
			end
			if mode == 0 then
				tick(a, a.acc, true)
				a.acc = 0
			elseif mode ~= 3 and a.acc >= 1 / C.FarHz then
				tick(a, a.acc, mode == 1)
				a.acc = 0
			elseif mode == 3 then
				a.acc = 0
			end
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
	if #actors == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function register(a: Slime)
	table.insert(actors, a)
	if not connection then
		connection = RunService.RenderStepped:Connect(stepAll)
	end
end

-- `model`: the slime (see the top of this file). Returns nil if it has no SlimeBody.
function Actor.new(model: Model, emotion: string?): Slime?
	local body = model:FindFirstChild("SlimeBody")
	if not body or not body:IsA("MeshPart") then
		return nil
	end
	local hullInst = model:FindFirstChild("SlimeBodyOutline")
	local hull = if hullInst and hullInst:IsA("MeshPart") then hullInst else nil
	seedCounter += 1
	local scale = body.Size.Y / C.MeshHeight
	local root = model:GetPivot()
	local a: Slime = {
		model = model,
		body = body,
		hull = hull,
		bodyBones = bonesOf(body),
		hullBones = if hull then bonesOf(hull) else nil,
		scale = scale,
		root = root,
		motion = SlimeMotion.new(seedCounter * 13 + math.floor(root.Position.X * 7 + root.Position.Z * 3)),
		face = SlimeFace.new(model, scale, seedCounter * 17),
		target = nil,
		targetPart = nil,
		override = false,
		acc = 0,
		yawning = false,
		pose = { sy = 1, sx = 1, leanFwd = 0, leanSide = 0, yaw = 0, lift = 0 },
		destroyed = false,
		travelFrom = nil,
		travelTo = nil,
		travelStart = 0,
		travelEnd = 0,
		hopIndex = -1,
		ghost = false,
		ground = root.Position,
		separation = Vector3.zero,
		attached = nil,
		attachedParts = {},
		attachedOffsets = {},
		attachOffset = CFrame.new(),
		faceTarget = nil,
		groundY = nil,
		groundAt = nil,
		held = nil,
		heldParts = {},
		heldOffsets = {},
		heldPose = nil,
	}
	-- Only the body is a collision surface. The outline and face remain non-collidable.
	body.CanCollide = true
	if hull then
		hull.CanCollide = false
	end
	local self: any = setmetatable(a :: any, Actor)
	self:setEmotion(emotion or "normal")
	register(self)
	return self
end

function Actor.setEmotion(self: Slime, id: string)
	local e = Expressions.get(id)
	if not e then
		warn(Config.LogPrefix, "unknown emotion", id)
		return
	end
	SlimeFace.setEmotion(self.face, id)
	self.override = false
	SlimeMotion.set(self.motion, e.motion)
	SlimeMotion.kick(self.motion, "squash", 1.2)
end

-- A point in the world, a part or a model to look at; nil to look at nothing.
function Actor.lookAt(self: Slime, target: Vector3 | Instance | nil)
	if typeof(target) == "Vector3" then
		self.target = target
		self.targetPart = nil
	elseif typeof(target) == "Instance" then
		self.target = nil
		self.targetPart = target
	else
		self.target = nil
		self.targetPart = nil
	end
end

function Actor.playMotion(self: Slime, name: string)
	self.override = true
	SlimeMotion.set(self.motion, name)
end

function Actor.hop(self: Slime, height: number?)
	SlimeMotion.hop(self.motion, height or 0.25)
end

-- Where the slime stands and which way it faces (the look vector).
function Actor.setCFrame(self: Slime, cf: CFrame)
	self.root = cf
end

-- The server owns the leg clock; the actor interpolates the same hop progress every frame.
function Actor.setTravel(self: Slime, from: Vector3, to: Vector3, startTime: number, endTime: number, ghost: boolean)
	if self.travelStart ~= startTime or self.travelEnd ~= endTime then
		self.hopIndex = -1
	end
	self.travelFrom, self.travelTo = from, to
	self.travelStart, self.travelEnd = startTime, endTime
	self.ghost = ghost
end

function Actor.attach(self: Slime, model: Model, offset: CFrame?)
	self.attached = model
	-- The kit items pivot around different centres; rest their bottom at the slime's top.
	self.attachOffset = (offset or CFrame.new()) * CFrame.new(0, model:GetExtentsSize().Y / 2, 0)
	table.clear(self.attachedParts)
	table.clear(self.attachedOffsets)
	local pivot = model:GetPivot()
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			-- A carried item is presentation-only; collisions are owned by the slime body.
			inst.Anchored = true
			inst.CanCollide = false
			table.insert(self.attachedParts, inst)
			table.insert(self.attachedOffsets, pivot:ToObjectSpace(inst.CFrame))
		end
	end
end

-- Hold a tool in front of the body; `pose(now)` places the tool's pivot in the feet frame (studs for a
-- full-size slime; front = -Z). The model is scaled by the caller.
function Actor.hold(self: Slime, model: Model, pose: (now: number) -> CFrame)
	self.held = model
	self.heldPose = pose
	table.clear(self.heldParts)
	table.clear(self.heldOffsets)
	local pivot = model:GetPivot()
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.Anchored = true
			inst.CanCollide = false
			table.insert(self.heldParts, inst)
			table.insert(self.heldOffsets, pivot:ToObjectSpace(inst.CFrame))
		end
	end
end

function Actor.unhold(self: Slime)
	self.held = nil
	self.heldPose = nil
	table.clear(self.heldParts)
	table.clear(self.heldOffsets)
end

-- Turn the body to a point while standing still (nil: keep the heading).
function Actor.face(self: Slime, point: Vector3?)
	self.faceTarget = point
end

-- A small shove into the jelly ("lean" forward for a toss, "squash" for a reach).
function Actor.kick(self: Slime, what: string, amount: number)
	SlimeMotion.kick(self.motion, what, amount)
end

function Actor.detach(self: Slime)
	self.attached = nil
	table.clear(self.attachedParts)
	table.clear(self.attachedOffsets)
end

function Actor.destroy(self: Slime)
	Actor.detach(self)
	Actor.unhold(self)
	self.destroyed = true
	SlimeFace.destroy(self.face)
end

-- One step of the loop by hand (the review stage uses it in Edit mode to pose the slimes for a picture).
Actor.stepAll = stepAll

-- Stop the loop (the slimes stay as they are posed; `stepAll` still works by hand, and a new actor starts the loop again).
function Actor.pauseLoop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

-- The actor that animates this model, if any.
function Actor.of(model: Model): Slime?
	for _, a in actors do
		if a.model == model and not a.destroyed then
			return a
		end
	end
	return nil
end

return Actor
