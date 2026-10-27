-- Real water for the level-1 fishing pond (the owner, 2026-10-27: "use real water"): Roblox terrain
-- water filling the pool that stud_floor leaves open in the stud floor, deeper in the middle, its
-- surface just under the floor's top, with gentle waves and clear blue-green colour. The painted
-- flat water of the earlier build is removed; floating things (lilies, bobber) are put on the surface.
-- Run in Edit mode through MCP after stud_floor (its terrain flattening would wipe the water).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local TOP = GROUND - 0.8 -- the water's surface, a little under the floor
local area = Layout.plotAreaFacing(PLOT, -1, 1)
local pond = workspace.Map["Plot" .. PLOT].FishingPondL1
-- The pond's lobes as the builder carved them: local x, z, radius.
local LOBES = { { 0, 5, 16 }, { 9, 11, 11 }, { -9, 2, 11 } }

local terrain = workspace.Terrain
terrain.WaterColor = Color3.fromRGB(38, 150, 196)
terrain.WaterReflectance = 0.25
terrain.WaterTransparency = 0.35
terrain.WaterWaveSize = 0.08
terrain.WaterWaveSpeed = 8

-- The painted water of the earlier build goes.
for _, n in { "Water" } do
	local old = pond:FindFirstChild(n)
	if old then
		old:Destroy()
	end
end

-- Each lobe: a shallow rim and a deeper middle of water (it replaces the ground the flattening left
-- below the floor), with sand at the bottom.
local function flatAt(x: number, z: number): CFrame
	local p = (area * CFrame.new(x, 0, z)).Position
	return CFrame.new(p.X, 0, p.Z)
end
for _, l in LOBES do
	local c = flatAt(l[1], l[2])
	local deep = 6
	terrain:FillCylinder(c + Vector3.new(0, TOP - deep - 2, 0), 4, l[3], Enum.Material.Sand)
	-- (a water fill does not replace solid terrain, so the ground is cleared to air first)
	terrain:FillCylinder(c + Vector3.new(0, TOP - deep / 2, 0), deep, l[3] - 0.5, Enum.Material.Air)
	terrain:FillCylinder(c + Vector3.new(0, TOP - deep / 2, 0), deep, l[3] - 0.5, Enum.Material.Water)
	terrain:FillCylinder(c + Vector3.new(0, TOP - deep - 0.5, 0), 1, l[3] * 0.6, Enum.Material.Water)
end
task.wait()

-- Terrain water keeps whole voxels near the top, so the surface is measured, not assumed.
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { terrain }
local hit = workspace:Raycast((area * CFrame.new(0, 30, 5)).Position, Vector3.new(0, -60, 0), params)
if hit and hit.Material == Enum.Material.Water then
	TOP = hit.Position.Y
end

-- Floating things sit on the water.
local nature = pond:FindFirstChild("Nature")
if nature then
	for _, m in nature:GetChildren() do
		if m.Name == "WaterLily" and m:IsA("Model") then
			local box, size = m:GetBoundingBox()
			m:PivotTo(m:GetPivot() + Vector3.new(0, TOP - (box.Position.Y - size.Y / 2) - 0.2, 0))
		end
	end
end
for _, n in { "BobberBottom", "BobberTop" } do
	local b = pond:FindFirstChild(n)
	if b then
		b.Position = Vector3.new(b.Position.X, TOP + (if n == "BobberTop" then 0.55 else 0.2), b.Position.Z)
	end
end
local rod, line, bob = pond:FindFirstChild("Rod"), pond:FindFirstChild("Line"), pond:FindFirstChild("BobberTop")
if rod and line and bob then
	local e1 = rod.Position + rod.CFrame.RightVector * rod.Size.X / 2
	local e2 = rod.Position - rod.CFrame.RightVector * rod.Size.X / 2
	local tip = if e1.Y > e2.Y then e1 else e2
	line.Size = Vector3.new(0.05, (tip - bob.Position).Magnitude, 0.05)
	line.CFrame = CFrame.lookAt((tip + bob.Position) / 2, bob.Position) * CFrame.Angles(math.rad(90), 0, 0)
end
return string.format("real water in the pond, surface at %.2f", TOP)
