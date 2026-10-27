--!strict
-- Fish swimming under a pond's water (models tagged "PondFish" by the map builders): each glides
-- round a loose loop that slowly grows and shrinks, turned along its way, with a little tail wiggle
-- and bob, and every fish on its own phase and speed. The builder puts on each fish:
--   Centre (Vector3) the middle of its loop, Radius (number) its size, Speed (studs a second),
--   Dir (1 or -1) which way round.
-- Only fish near the camera move, at 30 updates a second, to stay cheap on phones.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "PondFish"
local RANGE = 90 -- studs from the camera
local STEP = 1 / 30
local WIGGLE = math.rad(12) -- the tail's swing, as a turn of the whole body
local WIGGLE_SPEED = 9 -- radians a second

type Fish = {
	model: PVInstance,
	centre: Vector3,
	radius: number,
	speed: number,
	dir: number,
	phase: number,
	rest: CFrame,
}

local fishes: { [PVInstance]: Fish } = {}

local function add(inst: Instance)
	if not inst:IsA("PVInstance") or fishes[inst] then
		return
	end
	local centre = inst:GetAttribute("Centre")
	local radius = inst:GetAttribute("Radius")
	if typeof(centre) ~= "Vector3" or type(radius) ~= "number" then
		return
	end
	local speed = inst:GetAttribute("Speed")
	local dir = inst:GetAttribute("Dir")
	fishes[inst] = {
		model = inst,
		centre = centre,
		radius = radius,
		speed = if type(speed) == "number" then speed else 3,
		dir = if dir == -1 then -1 else 1,
		phase = (centre.X * 0.71 + radius * 1.93 + (if type(speed) == "number" then speed else 3) * 2.3)
			% (2 * math.pi),
		rest = inst:GetPivot(),
	}
end

local function remove(inst: Instance)
	local f = fishes[inst :: PVInstance]
	if f then
		f.model:PivotTo(f.rest)
		fishes[inst :: PVInstance] = nil
	end
end

for _, inst in CollectionService:GetTagged(TAG) do
	add(inst)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(remove)

-- Where a fish is at time t: a loop whose size breathes, so the path never quite repeats.
local function at(f: Fish, t: number): Vector3
	local a = f.phase + f.dir * t * f.speed / f.radius
	local r = f.radius * (0.75 + 0.25 * math.sin(t * 0.23 + f.phase * 2))
	return f.centre + Vector3.new(math.cos(a) * r, math.sin(t * 1.1 + f.phase) * 0.15, math.sin(a) * r * 0.8)
end

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
	for _, f in fishes do
		if (f.centre - eye).Magnitude <= RANGE then
			local p = at(f, t)
			local ahead = at(f, t + 0.1)
			local flat = Vector3.new(ahead.X - p.X, 0, ahead.Z - p.Z)
			if flat.Magnitude > 1e-3 then
				-- the fish's nose is its -Z (the builder turns each model to that)
				local wiggle = CFrame.Angles(0, math.sin(t * WIGGLE_SPEED + f.phase) * WIGGLE, 0)
				f.model:PivotTo(CFrame.lookAt(p, p + flat) * wiggle)
			end
		end
	end
end)
