--!strict
-- Things that float without gravity (the slime-tech hover cart; tagged "Hover" by the area stages)
-- bob gently up and down and rock a little, each on its own phase. Drawn on this client only, and
-- only near the camera, at 30 updates a second, to stay cheap on phones.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "Hover"
local RANGE = 120 -- studs from the camera
local STEP = 1 / 30
local RISE = 0.35 -- studs up and down from its resting place
local ROCK = math.rad(2.5)

type Hover = { model: Model, home: CFrame, phase: number }

local hovers: { [Model]: Hover } = {}

local function add(inst: Instance)
	if not inst:IsA("Model") or hovers[inst] then
		return
	end
	hovers[inst] = { model = inst, home = inst:GetPivot(), phase = math.random() * 100 }
end

local function remove(inst: Instance)
	hovers[inst :: Model] = nil
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
	for model, h in hovers do
		if not model.Parent then
			hovers[model] = nil
		elseif (h.home.Position - eye).Magnitude <= RANGE then
			local y = RISE * math.sin(t * 1.6 + h.phase)
			local rock = ROCK * math.sin(t * 1.1 + h.phase * 2)
			model:PivotTo(h.home * CFrame.new(0, y, 0) * CFrame.Angles(rock, 0, rock * 0.6))
		end
	end
end)
