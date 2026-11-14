--!strict
-- The world's fires and lamps (Config.World.Lights; the owner, 2026-11-15: "where there is a flame, put real fire;
-- where there is a lamp, make it glow"). Every torch burns with the VFX library's fire, day and night, on an unseen
-- anchor at its bowl (VfxLib's own distance rules keep only the near ones alive). Every lamp lights up at night
-- (shared/DayClock): its own lights switch on and its head wears the library's lamp glow on an unseen anchor (with a
-- light of ours when the lamp has none); by day both go. Only this client's copy changes; parts that stream in later
-- are taken as they come.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DayClock = require(ReplicatedStorage.Shared.DayClock)
local VfxLib = require(ReplicatedStorage.Shared.VfxLib)

local W = Config.World.Lights
local torches: { [string]: boolean } = {}
for _, name in W.Torches do
	torches[name] = true
end
type Lamp = { at: number, size: number, colour: string }
local LAMPS: { [string]: Lamp } = W.Lamps :: any

-- (plain tables: a weak one lost lamps still in the world, their Luau handles collected; streamed-out ones are pruned)
local lights: { [Light]: boolean } = {}
local glows: { [MeshPart]: Model } = {}
local lit = false

-- An unseen part on a mesh, `at` of its height up from its foot (it goes when the mesh streams out).
local function anchorAt(mesh: BasePart, name: string, size: Vector3, at: number): Part
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Size = size
	anchor.CFrame = mesh.CFrame * CFrame.new(0, -mesh.Size.Y / 2 + mesh.Size.Y * at, 0)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Parent = mesh
	return anchor
end

local function show(light: Light)
	light.Enabled = lit
end

-- A torch's mesh came in: the fire sits on an anchor parented to it, so it goes when the mesh streams out.
local function burn(mesh: BasePart)
	if mesh:FindFirstChild("FireAnchor") then
		return
	end
	local anchor =
		anchorAt(mesh, "FireAnchor", Vector3.new(1, W.FireHeight, 1), W.FireAt + W.FireHeight / 2 / mesh.Size.Y)
	VfxLib.attach(anchor, W.Fire)
end

-- A lamp's head: by night an unseen anchor there wears the glow (and our light, for a lamp with none of its own); by
-- day it goes, with all on it.
local function glow(mesh: MeshPart)
	local anchor = mesh:FindFirstChild("GlowAnchor")
	if not lit then
		if anchor then
			VfxLib.detach(anchor)
			anchor:Destroy()
		end
		return
	end
	if anchor then
		return
	end
	local model = glows[mesh]
	local lamp = LAMPS[model.Name]
	local made = anchorAt(mesh, "GlowAnchor", Vector3.one * lamp.size, lamp.at)
	local c = Color3.fromHex(lamp.colour)
	VfxLib.attach(made, W.Glow, { palette = { core = { c.R * 255, c.G * 255, c.B * 255 } } })
	if not model:FindFirstChildWhichIsA("Light", true) then
		local L = W.LampLight
		local light = Instance.new("PointLight")
		light.Color = c
		light.Brightness = L.Brightness
		light.Range = L.Range
		light.Shadows = false
		light.Parent = made
	end
end

-- The kit model (a torch or a lamp) a part or light sits in: kit meshes come wrapped in a "body" model.
local function kitOf(inst: Instance): Model?
	local at = inst.Parent
	for _ = 1, 3 do
		if not at or at == workspace then
			return nil
		end
		if at:IsA("Model") and (torches[at.Name] or LAMPS[at.Name] ~= nil) then
			return at
		end
		at = at.Parent
	end
	return nil
end

local function take(inst: Instance)
	if inst:IsA("Light") then
		local kit = kitOf(inst)
		if kit and LAMPS[kit.Name] ~= nil then
			lights[inst] = true
			show(inst)
		end
		return
	end
	if not inst:IsA("BasePart") or inst.Name == "FireAnchor" or inst.Name == "GlowAnchor" then
		return
	end
	local kit = kitOf(inst)
	if not kit then
		return
	end
	if torches[kit.Name] then
		burn(inst)
	elseif inst:IsA("MeshPart") then
		glows[inst] = kit
		glow(inst)
	end
end

for _, inst in workspace:GetDescendants() do
	take(inst)
end
workspace.DescendantAdded:Connect(take)

-- (the lamps follow the hour on the clock Lighting shows: a Dungeon map's dusk counts as its own hour)
while true do
	local now = DayClock.night(Lighting.ClockTime) >= W.LampsOnAt
	if now ~= lit then
		lit = now
		for light in lights do
			if light.Parent then
				show(light)
			else
				lights[light] = nil
			end
		end
		for mesh in glows do
			if mesh.Parent then
				glow(mesh)
			else
				glows[mesh] = nil
			end
		end
	end
	task.wait(1)
end
