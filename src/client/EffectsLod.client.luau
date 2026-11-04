--!strict
-- The world's fires, fountain splashes, chimney smoke and lamps (particle emitters and lights under Workspace.Map)
-- draw only near the camera: farther than Config.Perf.EmitterStuds an emitter stops, farther than LightStuds a light
-- goes out. Every home plot holds its own fires and lamps, and they all stayed on at any distance; big soft smoke
-- particles are what phones pay for most. Only what was on when it appeared is managed (nothing here turns on what a
-- builder left off), and distances are looked at Config.Perf.CheckHz times a second, not every frame.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local P = Config.Perf
local STEP = 1 / P.CheckHz

type Item = { inst: ParticleEmitter | Light, range: number, on: boolean }

local items: { [Instance]: Item } = {}

local function anchorPosition(inst: Instance): Vector3?
	local parent = inst.Parent
	if parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	elseif parent and parent:IsA("BasePart") then
		return parent.Position
	end
	return nil
end

local function add(inst: Instance)
	if items[inst] then
		return
	end
	if inst:IsA("ParticleEmitter") then
		if inst.Enabled then
			items[inst] = { inst = inst, range = P.EmitterStuds, on = true }
		end
	elseif inst:IsA("Light") then
		if inst.Enabled then
			items[inst] = { inst = inst, range = P.LightStuds, on = true }
		end
	end
end

local function remove(inst: Instance)
	items[inst] = nil
end

local map = workspace:WaitForChild("Map")
for _, inst in map:GetDescendants() do
	add(inst)
end
map.DescendantAdded:Connect(add)
map.DescendantRemoving:Connect(remove)

local acc = 0
RunService.Heartbeat:Connect(function(dt: number)
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
	for _, item in items do
		local at = anchorPosition(item.inst)
		local on = at ~= nil and (at - eye).Magnitude <= item.range
		if on ~= item.on then
			item.on = on
			local inst: any = item.inst
			inst.Enabled = on
		end
	end
end)
