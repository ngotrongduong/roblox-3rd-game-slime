--!strict
-- The lights of fires (campfire, kitchen stove; tagged "Flicker" by the map builders) flicker like
-- real flames: brightness and range wander on two mixed waves, each light on its own phase. Only
-- lights near the camera change, at 20 updates a second, to stay cheap on phones.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "Flicker"
local RANGE = 120 -- studs from the camera
local STEP = 1 / 20
local DEPTH = 0.3 -- how far the brightness dips, as a share of its own

type Flicker = { light: Light, brightness: number, range: number, phase: number }

local lights: { [Light]: Flicker } = {}

local function add(inst: Instance)
	if not (inst:IsA("PointLight") or inst:IsA("SpotLight")) or lights[inst] then
		return
	end
	local light = inst :: PointLight
	lights[light] = { light = light, brightness = light.Brightness, range = light.Range, phase = math.random() * 100 }
end

local function remove(inst: Instance)
	local f = lights[inst :: Light]
	if f then
		(f.light :: PointLight).Brightness = f.brightness;
		(f.light :: PointLight).Range = f.range
		lights[inst :: Light] = nil
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
	for _, f in lights do
		local parent = f.light.Parent
		if parent and parent:IsA("BasePart") and (parent.Position - eye).Magnitude <= RANGE then
			-- a slow sway plus a fast crackle, from 0 (dim) to 1 (full)
			local n = 0.5 + 0.3 * math.sin(t * 2.3 + f.phase) + 0.2 * math.sin(t * 11.7 + f.phase * 3)
			local light = f.light :: PointLight
			light.Brightness = f.brightness * (1 - DEPTH * (1 - n))
			light.Range = f.range * (0.92 + 0.08 * n)
		end
	end
end)
