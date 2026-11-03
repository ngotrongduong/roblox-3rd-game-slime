--!strict
-- The cloth of every flag (models tagged "WavingFlag": the kit's BannerFlag, built by tools/blender/flag.py) flies in the
-- wind: its chain of bones Flag0 (at the pole) .. FlagN (the free end) bends a little more towards the end, a ripple runs
-- along it and the whole cloth swings slowly about the pole, each flag on its own phase. Only flags near the camera move,
-- at 30 updates a second (the owner, 2026-11-03: "thin, flying softly like a real flag").
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "WavingFlag"
local RANGE = 140 -- studs from the camera
local STEP = 1 / 30
local RIPPLE_SPEED = 5.2 -- radians a second of the ripple
local RIPPLE_STEP = 0.9 -- radians of ripple phase from one bone to the next (about 1.2 waves along the cloth)
local RIPPLE_ROOT, RIPPLE_END = 0.06, 0.42 -- heading swing of the ripple at the pole and at the free end
local SWING, SWING_SPEED = 0.22, 0.45 -- the slow swing of the whole cloth about the pole
local DROOP, DROOP_WAVE = 0.035, 0.03 -- each bone bends the cloth down this much, breathing with the ripple

type Joint = { bone: Bone, up: Vector3, side: Vector3 }
type Flag = { model: Model, joints: { Joint }, at: Vector3, phase: number }

local flags: { [Model]: Flag } = {}

local function add(inst: Instance)
	if not inst:IsA("Model") or flags[inst] then
		return
	end
	local bones: { Bone } = {}
	for _, d in inst:GetDescendants() do
		local k = tonumber(string.match(d.Name, "^Flag(%d+)$"))
		if k and d:IsA("Bone") then
			bones[k + 1] = d :: Bone
		end
	end
	if #bones < 2 then
		return
	end
	-- the turn axes in each bone's own space: up (the pole) for the heading, the cloth's normal for the droop
	local along = (bones[2].WorldPosition - bones[1].WorldPosition).Unit
	local normal = Vector3.new(along.Z, 0, -along.X).Unit -- (up x along)
	local joints = {}
	for i, bone in bones do
		bone.Transform = CFrame.identity
		local cf = bone.WorldCFrame
		joints[i] = { bone = bone, up = cf:VectorToObjectSpace(Vector3.yAxis), side = cf:VectorToObjectSpace(normal) }
	end
	local p = bones[1].WorldPosition
	flags[inst] = { model = inst, joints = joints, at = p, phase = (p.X * 0.37 + p.Z * 0.61) % (2 * math.pi) }
end

local function remove(inst: Instance)
	local f = flags[inst :: Model]
	if f then
		for _, j in f.joints do
			j.bone.Transform = CFrame.identity
		end
		flags[inst :: Model] = nil
	end
end

for _, inst in CollectionService:GetTagged(TAG) do
	add(inst)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(remove)

local acc = 0
RunService.RenderStepped:Connect(function(dt: number)
	acc += dt
	if acc < STEP then
		return
	end
	acc = 0
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local t = os.clock()
	for _, f in flags do
		if (f.at - eye).Magnitude <= RANGE then
			local n = #f.joints
			local swing = SWING * math.sin(t * SWING_SPEED + f.phase) * (0.7 + 0.3 * math.sin(t * 1.7 + f.phase * 2))
			local before = 0
			for i, j in f.joints do
				local x = (i - 1) / (n - 1)
				local wave = math.sin(t * RIPPLE_SPEED - (i - 1) * RIPPLE_STEP + f.phase)
				-- the heading of this piece of cloth, turned into a turn from the piece before it
				local heading = swing + (RIPPLE_ROOT + (RIPPLE_END - RIPPLE_ROOT) * x) * wave
				local droop = DROOP + DROOP_WAVE * wave * x
				j.bone.Transform = CFrame.fromAxisAngle(j.up, heading - before) * CFrame.fromAxisAngle(j.side, droop)
				before = heading
			end
		end
	end
end)
