-- The level-1 kitchen of one home plot (middle-left area), built in Studio through MCP (Edit mode)
-- in the classic stud look (docs/areas/kitchen.md). A small warm-brick stud patch with ONE cooking
-- spot: a stone stove with a glowing fire and a steaming pot, a wooden counter with today's
-- ingredients (fish from the pond, vegetables from the garden), a firewood pile, the area's signpost
-- (pot icon), dressed with the Nature stylized Pack. Rebuilds itself each run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local area = Layout.plotAreaFacing(PLOT, -1, 0)
local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)

-- Clear the greybox kitchen and any previous build.
if plotModel then
	for _, c in plotModel:GetChildren() do
		if c.Name:match("^Kitchen") or c.Name == "Chimney" or c.Name == "KitchenL1" then
			c:Destroy()
		end
	end
end

local HONEY = Color3.fromRGB(205, 146, 82)
local HONEY_DARK = Color3.fromRGB(170, 112, 58)
local WOOD_DARK = Color3.fromRGB(120, 78, 44)
local STONE = Color3.fromRGB(176, 170, 160)
local STONE_DARK = Color3.fromRGB(122, 116, 108)
local BRICK = Color3.fromRGB(222, 170, 118)
local IRON = Color3.fromRGB(58, 56, 60)

local model = Instance.new("Model")
model.Name = "KitchenL1"

-- Local placement: x across (+x toward the plot's outer hedge), z depth (+z toward the pond), y up
-- from the floor's top.
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
	p.CastShadow = size.Magnitude > 4
	p.Parent = model
	return p
end

local function post(name: string, cf: CFrame, height: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.PartType.Cylinder, material)
end

-- ===== the floor: a warm brick stud patch, the kitchen's island =====
local pad = part("Floor", Vector3.new(22, 0.4, 18), at(0, 0.2, 0), BRICK, nil, Enum.Material.Plastic)
pad.TopSurface = Enum.SurfaceType.Studs
pad.CastShadow = false
-- a darker stud border, one stud wide
for _, b in { { 0, 9.5, 24, 1 }, { 0, -9.5, 24, 1 }, { 11.5, 0, 1, 18 }, { -11.5, 0, 1, 18 } } do
	local e = part("FloorEdge", Vector3.new(b[3], 0.6, b[4]), at(b[1], 0.3, b[2]), Color3.fromRGB(176, 122, 80), nil, Enum.Material.Plastic)
	e.TopSurface = Enum.SurfaceType.Studs
	e.CastShadow = false
end

-- ===== the stove (back of the pad, facing the front) =====
local stoveCf = at(0, 0, 4.5)
part("StoveBase", Vector3.new(6, 3, 4), stoveCf * CFrame.new(0, 1.9, 0), STONE, nil, Enum.Material.Slate)
part("StoveTop", Vector3.new(6.6, 0.5, 4.6), stoveCf * CFrame.new(0, 3.6, 0), STONE_DARK, nil, Enum.Material.Slate)
-- the fire mouth at the front, glowing
part("Mouth", Vector3.new(2.6, 1.6, 0.3), stoveCf * CFrame.new(0, 1.4, -2), Color3.fromRGB(40, 30, 28))
local glow = part("Fire", Vector3.new(2, 1, 0.2), stoveCf * CFrame.new(0, 1.2, -2.05), Color3.fromRGB(255, 140, 40), nil, Enum.Material.Neon)
glow.CastShadow = false
-- Real-looking flames licking up the fire mouth (the owner: "fire like real"), the campfire's recipe
-- at a smaller scale (see build_village.luau): the owner's "Realistic Fire VFX" pack
-- (ServerStorage.OwnerKit.CampFlame) for glow and embers, Roblox's flame texture for the tongues,
-- one light tagged "Flicker" for the client's FireFlicker.
local ownerKit = game:GetService("ServerStorage"):FindFirstChild("OwnerKit")
local function addFire(parent: Instance, base: CFrame, scale: number)
	local core = Instance.new("Part")
	core.Name = "FireCore"
	core.Size = Vector3.one * scale
	core.CFrame = base
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.Parent = parent
	local pack = ownerKit and ownerKit:FindFirstChild("CampFlame")
	if pack then
		local m = pack:Clone()
		m:ScaleTo(0.45 * scale)
		m:PivotTo(base - Vector3.new(0, 0.5 * scale, 0))
		for _, d in m:GetDescendants() do
			if d:IsA("ParticleEmitter") and d.Name == "bloom" then
				d.Rate = 12
				d.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.92), NumberSequenceKeypoint.new(1, 1) })
			elseif d:IsA("ParticleEmitter") and d.Name == "smoke" then
				d.Speed = NumberRange.new(4.5 * scale, 6 * scale)
			elseif d:IsA("Light") then
				d:Destroy()
			end
		end
		m.Parent = parent
	end
	local at0 = Instance.new("Attachment")
	at0.Name = "Flames"
	at0.Parent = core
	local function flames(c0: Color3, c1: Color3, size: number, life: number, rate: number, speed: number)
		local e = Instance.new("ParticleEmitter")
		e.Name = "Flame"
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Color = ColorSequence.new(c0, c1)
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(0.4, size * 1.1), NumberSequenceKeypoint.new(1, size * 0.15) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(0.75, 0.35), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(life * 0.7, life)
		e.Rate = rate
		e.Speed = NumberRange.new(speed * 0.7, speed)
		e.SpreadAngle = Vector2.new(10, 10)
		e.Rotation = NumberRange.new(-15, 15)
		e.RotSpeed = NumberRange.new(-30, 30)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = at0
	end
	flames(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 80, 20), 2.8 * scale, 0.9, 22, 3.6 * scale)
	flames(Color3.fromRGB(255, 250, 200), Color3.fromRGB(255, 170, 60), 1.4 * scale, 0.6, 18, 2.8 * scale)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 70)
	light.Brightness = 2
	light.Range = 18 * scale
	light.Parent = core
	light:AddTag("Flicker")
end
glow.Color = Color3.fromRGB(200, 80, 30) -- (now the bed of embers under the flames)
addFire(model, stoveCf * CFrame.new(0, 0.9, -2.25), 0.45)
-- a stone chimney stub at the back corner
part("Chimney", Vector3.new(1.6, 4, 1.6), stoveCf * CFrame.new(2.3, 5.6, 1.4), STONE, nil, Enum.Material.Slate)
local cap = part("ChimneyCap", Vector3.new(2, 0.4, 2), stoveCf * CFrame.new(2.3, 7.7, 1.4), STONE_DARK, nil, Enum.Material.Slate)
-- a thin wisp of smoke from the chimney, few and slow (cheap on phones)
local smokeAt = Instance.new("Attachment")
smokeAt.Position = Vector3.new(0, 0.3, 0)
smokeAt.Parent = cap
local smoke = Instance.new("ParticleEmitter")
smoke.Name = "Smoke"
smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
smoke.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235), Color3.fromRGB(190, 190, 195))
smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3) })
smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.6), NumberSequenceKeypoint.new(1, 1) })
smoke.Lifetime = NumberRange.new(2.5, 3.5)
smoke.Rate = 3
smoke.Speed = NumberRange.new(1.2, 1.8)
smoke.SpreadAngle = Vector2.new(8, 8)
smoke.RotSpeed = NumberRange.new(-20, 20)
smoke.Acceleration = Vector3.new(0.4, 0.2, 0)
smoke.EmissionDirection = Enum.NormalId.Top
smoke.Parent = smokeAt

-- the pot on the stove, with a lid and gentle steam
local potCf = stoveCf * CFrame.new(-0.8, 3.85, 0)
post("Pot", potCf * CFrame.new(0, 1, 0), 2, 2.8, IRON)
post("PotRim", potCf * CFrame.new(0, 2.05, 0), 0.25, 3.1, Color3.fromRGB(78, 76, 80))
local soup = post("Soup", potCf * CFrame.new(0, 2.08, 0), 0.1, 2.5, Color3.fromRGB(236, 150, 64))
local steam = Instance.new("ParticleEmitter")
steam.Name = "Steam"
steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
steam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) })
steam.Lifetime = NumberRange.new(1.6, 2.4)
steam.Rate = 3
steam.Speed = NumberRange.new(1.2, 1.8)
steam.SpreadAngle = Vector2.new(10, 10)
steam.EmissionDirection = Enum.NormalId.Right -- the cylinder lies on its side: +X is up
steam.Parent = soup
-- a ladle leaning in the pot
part("Ladle", Vector3.new(0.25, 3, 0.25), potCf * CFrame.new(0.6, 2.6, 0.2) * CFrame.Angles(0, 0, math.rad(-25)), HONEY_DARK)

-- ===== the cooking spot (one) =====
-- A round straw mat in front of the stove: where the working slime stands to cook.
local spotCf = at(0, 0.45, -1.2)
local spot = post("CookingSpot1", spotCf, 0.12, 3.6, Color3.fromRGB(232, 200, 120), Enum.Material.Fabric)
local mark = Instance.new("Attachment")
mark.Name = "WorkSpot1"
mark.Parent = spot

-- ===== the counter (left of the stove) with today's ingredients =====
local counterCf = at(-7, 0, 3.5)
part("CounterTop", Vector3.new(4.4, 0.5, 6.4), counterCf * CFrame.new(0, 3, 0), HONEY, nil, Enum.Material.Wood)
part("CounterBody", Vector3.new(4, 2.6, 6), counterCf * CFrame.new(0, 1.6, 0), HONEY_DARK, nil, Enum.Material.Wood)
part("Shelf", Vector3.new(4.1, 0.3, 6.1), counterCf * CFrame.new(0, 1.1, 0), WOOD_DARK)
part("Board", Vector3.new(2.4, 0.2, 1.6), counterCf * CFrame.new(0, 3.35, -1.2), Color3.fromRGB(226, 180, 120))
-- a fish on the board, carrots and a cabbage beside it, a bowl
local fish = part("Fish", Vector3.new(0.6, 0.5, 1.6), counterCf * CFrame.new(0, 3.7, -1.2), Color3.fromRGB(110, 170, 225), Enum.PartType.Ball)
fish.CastShadow = false
part("FishTail", Vector3.new(0.15, 0.6, 0.6), counterCf * CFrame.new(0, 3.7, -2.1) * CFrame.Angles(math.rad(45), 0, 0), Color3.fromRGB(90, 150, 210))
for k = 0, 1 do
	part("Carrot", Vector3.new(0.45, 0.45, 1.5), counterCf * CFrame.new(-1 + k * 0.6, 3.5, 1) * CFrame.Angles(0, math.rad(20 * k), 0), Color3.fromRGB(240, 130, 40), Enum.PartType.Ball)
end
part("Cabbage", Vector3.new(1.3, 1.1, 1.3), counterCf * CFrame.new(1, 3.8, 1.6), Color3.fromRGB(150, 210, 90), Enum.PartType.Ball)
post("Bowl", counterCf * CFrame.new(1.1, 3.55, -2.4), 0.5, 1.4, Color3.fromRGB(240, 232, 214))

-- ===== the firewood pile (right of the stove) =====
-- logs lie front-to-back so their round ends face the gate: a pyramid of 3 + 2 + 1
for r, n in { 3, 2, 1 } do
	for i = 1, n do
		local x = 6.5 + (i - (n + 1) / 2) * 0.85
		local colour = if (r + i) % 2 == 0 then HONEY_DARK else Color3.fromRGB(150, 98, 52)
		part("Firewood", Vector3.new(3, 0.8, 0.8), at(x, 0.4 + (r - 1) * 0.72, 3) * CFrame.Angles(0, math.rad(90), 0), colour, Enum.PartType.Cylinder, Enum.Material.Wood)
	end
end

-- ===== the area's signpost (pot icon) at the front =====
local signCf = at(-8.5, 0, -10.5)
post("SignPost", signCf * CFrame.new(0, 2, 0), 4, 0.6, HONEY_DARK)
local sign = part("Sign", Vector3.new(3, 2, 0.35), signCf * CFrame.new(0, 3.6, -0.4), HONEY)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(150, 100)
gui.LightInfluence = 0.6
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "🍳"
icon.TextScaled = true
icon.Parent = gui
gui.Parent = sign

model.Parent = plotModel or workspace

-- ===== dressing from the Nature stylized Pack =====
local lib = ServerStorage:FindFirstChild("NatureKit")
if lib then
	local nature = Instance.new("Folder")
	nature.Name = "Nature"
	local function put(key: string, x: number, z: number, scale: number, turn: number)
		local m = (lib:FindFirstChild(key) :: Model):Clone()
		m:ScaleTo(scale)
		local pivot = m:GetPivot()
		m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.rad(turn), 0) * pivot.Rotation)
		local box, size = m:GetBoundingBox()
		local target = (area * CFrame.new(x, GROUND + size.Y / 2, z)).Position
		m:PivotTo(m:GetPivot() + (target - box.Position))
		m.Parent = nature
	end
	put("BerryBush", 15, 8, 0.9, 30)
	put("FloweringBush", -15, 9, 0.85, 0)
	put("Fern", 13, -6, 1.3, 60)
	put("GrassTuft", -14, -4, 1.4, 0)
	put("FlowerPatch", 14, -12, 1.2, 0)
	put("FlowerPatch", -4, -12, 1.1, 90)
	put("MossyBoulder", 17, 15, 0.7, 20)
	put("Sunflower", -13, 12.5, 1.2, 150)
	nature.Parent = model
end

return "kitchen L1 built: " .. #model:GetDescendants() .. " instances"
