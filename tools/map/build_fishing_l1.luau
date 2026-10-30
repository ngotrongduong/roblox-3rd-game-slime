-- The level-1 fishing pond of one home plot, built in Studio through MCP (Edit mode) in the
-- plot's fishing area (back-left). Clean and simple: a small natural pond with a sandy shore,
-- a short wooden dock with ONE fishing spot at its end where a slime stands and fishes, and a few
-- props. Rebuilds itself each run. Change PLOT to build it on another plot.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY
local terrain = workspace.Terrain
local area = Layout.plotAreaFacing(PLOT, -1, 1)
local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)

-- Clear the greybox pieces and any previous build of this pond.
for _, name in { "Dock", "Seat", "FishingPondL1" } do
	local old = plotModel and plotModel:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local HONEY = Color3.fromRGB(205, 146, 82)
local HONEY_DARK = Color3.fromRGB(170, 112, 58)
local WOOD_DARK = Color3.fromRGB(120, 78, 44)
local ROPE = Color3.fromRGB(226, 196, 140)
local STONE = Color3.fromRGB(176, 172, 162)
local LEAF = Color3.fromRGB(96, 176, 70)
local REED = Color3.fromRGB(120, 168, 70)

local model = Instance.new("Model")
model.Name = "FishingPondL1"

-- Local placement in the area: x across (+x = left seen from the gate), z depth (+z = back), y up
-- from the ground's surface.
local function at(x: number, y: number, z: number): CFrame
	return area * CFrame.new(x, y + GROUND, z)
end

local function part(name: string, size: Vector3, cf: CFrame, colour: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.CastShadow = size.Magnitude > 6
	p.Parent = model
	return p
end

-- An upright cylinder (Roblox cylinders run along X).
local function post(name: string, cf: CFrame, height: number, diameter: number, colour: Color3): Part
	return part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.PartType.Cylinder)
end

-- ===== terrain: the pond =====
-- Grass back over the old round pond, then a soft three-lobed pond with a sandy rim.
-- (the village scale, 2026-10-30: the pond and all round it 1.3 times the old; src/server/PondStages LOBES)
local PK = 1.3
terrain:FillCylinder(at(0, -4, 0), 8, 34, Enum.Material.Grass)
local lobes = { { 0, 6.5, 20.8 }, { 11.7, 14.3, 14.3 }, { -11.7, 2.6, 14.3 } }
for _, l in lobes do
	terrain:FillCylinder(at(l[1], -2, l[2]), 4, l[3] + 3.5, Enum.Material.Sand)
end
for _, l in lobes do
	terrain:FillCylinder(at(l[1], -3, l[2]), 6, l[3], Enum.Material.Air)
	terrain:FillCylinder(at(l[1], -4, l[2]), 4.4, l[3], Enum.Material.Water)
end

-- ===== the dock =====
-- From the front shore straight out over the water: planks across, two tones, small gaps.
local dockX, dockStart, dockEnd, dockY = -3, -19.5, 5.2, 1.1
local plankDepth = 1.6
local i = 0
for z = dockStart, dockEnd, plankDepth + 0.15 do
	i += 1
	part("Plank", Vector3.new(6, 0.5, plankDepth), at(dockX, dockY, z), if i % 2 == 0 then HONEY else HONEY_DARK, nil, Enum.Material.Wood)
end
-- Two beams under the planks.
for _, dx in { -2.2, 2.2 } do
	part("Beam", Vector3.new(0.6, 0.6, dockEnd - dockStart + 1.6), at(dockX + dx, dockY - 0.55, (dockStart + dockEnd) / 2), WOOD_DARK)
end
-- Four round posts with rope rings at the water end and at the shore.
for _, z in { dockStart + 0.4, dockEnd + 0.6 } do
	for _, dx in { -3.2, 3.2 } do
		post("Post", at(dockX + dx, 0.9, z), 4.4, 1.1, HONEY_DARK)
		post("Rope", at(dockX + dx, 1.9, z), 0.5, 1.3, ROPE)
	end
end

-- ===== the fishing spot (one) =====
-- The place a working slime stands, at the end of the dock: an invisible marker (the owner took the
-- round straw mat out, 2026-10-27), kept for its WorkSpot1 attachment.
local spotCf = at(dockX, dockY + 0.3, dockEnd - 0.6)
local spot = post("FishingSpot1", spotCf, 0.15, 4, Color3.fromRGB(232, 200, 120))
spot.Transparency = 1
spot.CanCollide = false
spot.CanQuery = false
spot.CanTouch = false
spot.CastShadow = false
local mark = Instance.new("Attachment")
mark.Name = "WorkSpot1"
mark.Parent = spot
-- (the attachment of a cylinder is in its own rotated space; gameplay reads WorldCFrame)

-- A rod holder beside the spot with the rod leaning out over the water.
post("RodHolder", at(dockX + 2.4, dockY + 0.9, dockEnd - 0.2), 1.6, 0.6, WOOD_DARK)
local rodBase = at(dockX + 2.4, dockY + 1.8, dockEnd - 0.2)
-- tilted toward +z: out over the water, away from the shore
local rodDir = CFrame.Angles(math.rad(62), 0, 0)
local rodLen = 9
part("Rod", Vector3.new(rodLen, 0.25, 0.25), rodBase * rodDir * CFrame.new(0, rodLen / 2, 0), Color3.fromRGB(150, 96, 52), Enum.PartType.Cylinder):PivotTo(
	rodBase * rodDir * CFrame.new(0, rodLen / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
)
local tip = (rodBase * rodDir * CFrame.new(0, rodLen, 0)).Position
-- The water surface, measured: a ray from above the pond's middle stops on the water.
local hit = workspace:Raycast(at(0, 20, 5).Position, Vector3.new(0, -40, 0), RaycastParams.new())
local WATER_Y = if hit then hit.Position.Y - area.Position.Y else -1.7
local bobberPos = Vector3.new(tip.X, area.Position.Y + WATER_Y + 0.2, tip.Z)
local line = part("Line", Vector3.new(0.05, (tip - bobberPos).Magnitude, 0.05), CFrame.lookAt((tip + bobberPos) / 2, bobberPos) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(245, 245, 245))
line.CastShadow = false
part("BobberTop", Vector3.new(0.9, 0.9, 0.9), CFrame.new(bobberPos + Vector3.new(0, 0.35, 0)), Color3.fromRGB(230, 60, 50), Enum.PartType.Ball)
part("BobberBottom", Vector3.new(0.9, 0.9, 0.9), CFrame.new(bobberPos), Color3.fromRGB(250, 250, 245), Enum.PartType.Ball)


-- ===== props (few, big, readable) =====
-- A bucket for the catch beside the spot.
post("Bucket", at(dockX - 2, dockY + 0.95, dockEnd - 2.6), 1.6, 1.6, Color3.fromRGB(160, 168, 176)).Material = Enum.Material.Metal
part("Catch", Vector3.new(1.2, 0.3, 1.2), at(dockX - 2, dockY + 1.7, dockEnd - 2.6), Color3.fromRGB(120, 170, 220), Enum.PartType.Ball)

-- The lantern post with the area's sign at the shore end (the sign is where the level shows and
-- where the player taps to upgrade).
local postCf = at(dockX + 5, 0, dockStart - 0.5)
post("LanternPost", postCf * CFrame.new(0, 4, 0), 8, 0.9, HONEY_DARK)
part("Arm", Vector3.new(3, 0.5, 0.5), postCf * CFrame.new(-1.3, 7.6, 0), HONEY_DARK)
local lantern = part("Lantern", Vector3.new(1.1, 1.4, 1.1), postCf * CFrame.new(-2.4, 6.6, 0), Color3.fromRGB(255, 214, 120), nil, Enum.Material.Neon)
local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(255, 200, 120)
light.Brightness = 1.2
light.Range = 12
light.Parent = lantern
part("LanternCap", Vector3.new(1.4, 0.4, 1.4), postCf * CFrame.new(-2.4, 7.45, 0), WOOD_DARK)
local sign = part("Sign", Vector3.new(3.4, 2.2, 0.4), postCf * CFrame.new(0, 4.6, -0.6), HONEY)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(170, 110)
gui.LightInfluence = 0.6
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "🐟"
icon.TextScaled = true
icon.Parent = gui
gui.Parent = sign

-- Reeds in two clumps at the back of the pond, lily pads on the water, a few round stones.
local function reeds(x: number, z: number)
	for k = 1, 5 do
		local ox, oz = math.sin(k * 2.1) * 1.2, math.cos(k * 1.7) * 1.2
		local h = 3 + (k % 3)
		post("Reed", at(x + ox, h / 2 - 0.6, z + oz), h, 0.25, REED)
		if k % 2 == 1 then
			post("Cattail", at(x + ox, h - 0.4, z + oz), 1, 0.45, WOOD_DARK)
		end
	end
end
reeds(13 * PK, 19 * PK)
reeds(-17 * PK, 11 * PK)
for _, p in { { 9.1, 10.4 }, { 3.9, 19.5 }, { -10.4, 7.8 } } do
	post("LilyPad", at(p[1], WATER_Y + 0.05, p[2]), 0.12, 2.8, LEAF)
end
part("LilyFlower", Vector3.new(0.8, 0.6, 0.8), at(3.9, WATER_Y + 0.4, 19.5), Color3.fromRGB(250, 190, 210), Enum.PartType.Ball)
-- Round stones on the shore, two or three together.
for _, s in { { -19, -6, 2.8 }, { -16.5, -8, 1.8 }, { 18, 6, 2.4 }, { 19.5, 3.5, 1.6 }, { 7, -12, 1.8 } } do
	part("Stone", Vector3.new(s[3] * 1.3, s[3] * 0.8, s[3]), at(s[1] * PK, s[3] * 0.38, s[2] * PK) * CFrame.Angles(0, s[1], 0), STONE, Enum.PartType.Ball, Enum.Material.Slate)
end
-- Two soft bushes framing the pond, with a few white flowers.
local function bush(x: number, z: number, s: number)
	for k, o in { { 0, 0, 1 }, { 1.1, 0.4, 0.8 }, { -1, 0.3, 0.75 } } do
		part("Bush", Vector3.one * 3.4 * s * o[3], at(x + o[1] * s, 1.6 * s * o[3], z + o[2] * s), if k == 1 then LEAF else Color3.fromRGB(110, 190, 80), Enum.PartType.Ball, Enum.Material.SmoothPlastic)
	end
	for k = 1, 3 do
		part("Flower", Vector3.one * 0.6, at(x + math.sin(k * 2) * 1.6 * s, 3.1 * s, z + math.cos(k * 2) * 1.2 * s), Color3.fromRGB(255, 252, 240), Enum.PartType.Ball)
	end
end
bush(-15 * PK, 17 * PK, 1.2)
bush(17 * PK, -4 * PK, 1)

model.Parent = plotModel or workspace
return "fishing pond L1 built: " .. #model:GetChildren() .. " parts"
