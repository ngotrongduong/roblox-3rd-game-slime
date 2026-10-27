--!strict
-- Gentle sway of reeds, ferns, tall flowers and flowering bushes (models tagged "Sway" by the map
-- builders): each leans a few degrees around its foot, slowly, with its own phase so nothing moves in
-- step. Only models near the camera move, at 30 updates a second, to stay cheap on phones.
-- (Research: .claude/skills/studio-build/RESEARCH.md "Stylized cozy look" §3.)
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "Sway"
local RANGE = 80 -- studs from the camera
local STEP = 1 / 30
local ANGLE = math.rad(3) -- the largest lean
local SPEED = 1.3 -- radians a second of the slow wave

type Swayer = { model: Model, rest: CFrame, foot: Vector3, phase: number }

local swayers: { [Model]: Swayer } = {}

local function add(inst: Instance)
	if not inst:IsA("Model") or swayers[inst] then
		return
	end
	local box, size = inst:GetBoundingBox()
	swayers[inst] = {
		model = inst,
		rest = inst:GetPivot(),
		foot = box.Position - Vector3.new(0, size.Y / 2, 0),
		phase = (box.Position.X * 0.37 + box.Position.Z * 0.61) % (2 * math.pi),
	}
end

local function remove(inst: Instance)
	local s = swayers[inst :: Model]
	if s then
		s.model:PivotTo(s.rest)
		swayers[inst :: Model] = nil
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
	local t = os.clock() * SPEED
	for _, s in swayers do
		if (s.foot - eye).Magnitude <= RANGE then
			local lean = CFrame.Angles(math.sin(t + s.phase) * ANGLE, 0, math.cos(t * 0.8 + s.phase) * ANGLE * 0.6)
			-- turn around the foot, so the base stays planted
			local pivotAtFoot = CFrame.new(s.foot)
			s.model:PivotTo(pivotAtFoot * lean * pivotAtFoot:Inverse() * s.rest)
		end
	end
end)
