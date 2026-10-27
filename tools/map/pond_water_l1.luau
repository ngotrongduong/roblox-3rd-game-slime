-- Cartoon water for the level-1 fishing pond (research: RESEARCH.md "Stylized cozy look" §4): flat
-- opaque parts over the terrain water in three tones (light shallows at the rim, a mid band, a deep
-- centre), the same on every phone; floating things (lilies, bobber) are put on top. Terrain water
-- elsewhere gets the cartoon settings. Run in Edit mode through MCP after build_fishing_l1.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local area = Layout.plotAreaFrame(PLOT, -1, 1)
local pond = workspace.Map["Plot" .. PLOT].FishingPondL1
-- The pond's lobes as the builder carved them: local x, z, radius.
local LOBES = { { 0, 5, 16 }, { 9, 11, 11 }, { -9, 2, 11 } }
-- Lifts above the measured terrain water: its waves rise about 0.8 studs over the raycast level, so
-- the paint sits just above them (found by eye in Studio, 2026-10-27).
local TONES = {
	{ inset = 0.3, colour = Color3.fromRGB(96, 196, 235), lift = 0.89 }, -- shallows at the rim
	{ inset = 2.6, colour = Color3.fromRGB(56, 156, 222), lift = 0.92 },
	{ inset = 5.5, colour = Color3.fromRGB(34, 118, 204), lift = 0.95 }, -- deep centre
}

-- Terrain water everywhere: clear cartoon blue, no glints.
local terrain = workspace.Terrain
terrain.WaterColor = Color3.fromRGB(40, 140, 215)
terrain.WaterReflectance = 0.08
terrain.WaterTransparency = 0.55
terrain.WaterWaveSize = 0.04
terrain.WaterWaveSpeed = 6

-- The water level, measured on the terrain water.
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { terrain }
local hit = workspace:Raycast((area * CFrame.new(0, 30, 5)).Position, Vector3.new(0, -60, 0), params)
local waterY = if hit then hit.Position.Y else area.Position.Y - 0.9

local old = pond:FindFirstChild("Water")
if old then
	old:Destroy()
end
local water = Instance.new("Model")
water.Name = "Water"
for _, tone in TONES do
	for _, l in LOBES do
		local r = l[3] - tone.inset
		if r > 1 then
			local p = Instance.new("Part")
			p.Name = "WaterTone"
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(0.1, r * 2, r * 2)
			local pos = (area * CFrame.new(l[1], 0, l[2])).Position
			p.CFrame = CFrame.new(pos.X, waterY + tone.lift, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
			p.Color = tone.colour
			p.Material = Enum.Material.SmoothPlastic
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Parent = water
		end
	end
end
water.Parent = pond
local top = waterY + TONES[#TONES].lift + 0.05

-- Floating things sit on the painted water.
local nature = pond:FindFirstChild("Nature")
if nature then
	for _, m in nature:GetChildren() do
		if m.Name == "WaterLily" then
			local box, size = m:GetBoundingBox()
			m:PivotTo(m:GetPivot() + Vector3.new(0, top - (box.Position.Y - size.Y / 2) - 0.25, 0))
		end
	end
end
for _, n in { "BobberBottom", "BobberTop" } do
	local b = pond:FindFirstChild(n)
	if b then
		b.Position = Vector3.new(b.Position.X, top + (if n == "BobberTop" then 0.55 else 0.2), b.Position.Z)
	end
end
return string.format("pond water painted at %.2f", waterY)
