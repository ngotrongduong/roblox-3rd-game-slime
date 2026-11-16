--!strict
-- Wind wheels and windmill sails (models tagged "Turn" by the server, server/Garden) turn round their own pivot's
-- front-to-back line, at their attribute TurnSpeed in degrees a second. Drawn on this client only, and only near
-- the camera, at 30 updates a second, to stay cheap on phones.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "Turn"
local RANGE = 150 -- studs from the camera
local STEP = 1 / 30

type Turn = { home: CFrame, speed: number }

local turns: { [Model]: Turn } = {}

local function add(inst: Instance)
	if not inst:IsA("Model") or turns[inst] then
		return
	end
	local speed = inst:GetAttribute("TurnSpeed")
	turns[inst] = { home = inst:GetPivot(), speed = math.rad(if typeof(speed) == "number" then speed else 40) }
end

local function remove(inst: Instance)
	turns[inst :: Model] = nil
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
	for model, turn in turns do
		if not model.Parent then
			turns[model] = nil
		elseif (turn.home.Position - eye).Magnitude <= RANGE then
			model:PivotTo(turn.home * CFrame.Angles(0, 0, t * turn.speed))
		end
	end
end)
