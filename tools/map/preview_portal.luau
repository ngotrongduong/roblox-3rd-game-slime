-- A preview of the Dungeon Portal in the Market of the work place, for shots only: the game places the real one at run time
-- (src/server/DungeonPortal.luau, Layout.marketPortal). This is DungeonPortal's build (same kit meshes, ring, runes, crystals,
-- pillars, platform; the particles are left out, they do not show in an Edit shot) at Config.Dungeon.Portal.Market, scaled the
-- same. It goes to workspace.PortalPreview and must be removed before the place is saved:
--   node tools/studio_mcp.js run tools/map/preview_portal.luau <studio_id> Edit             (builds it again)
--   node tools/studio_mcp.js run tools/map/preview_portal.luau <studio_id> Edit REMOVE=<any file>   (only removes it)
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- (an MCP `run` cannot always require the shared modules - "Capabilities: Network" - so the numbers are kept here too, equal to
-- src/shared/Config.luau: Config.Dungeon.Portal and Config.Map)
local okC, Config = pcall(require, ReplicatedStorage.Shared.Config)
local P = if okC then Config.Dungeon.Portal else nil
local SPOT = if P then P.Market else { x = -51, z = 30 }
local SCALE = if P then P.Scale else 0.55
local PIECES = if P
	then P.Pieces
	else {
		bush_tall_grass = 86818606224653,
		portal_crystal = 81030539240809,
		portal_pillar = 95971264752250,
		rock_boulder_big = 76184147421470,
		rock_cliff_chunk = 120536488786893,
		rock_cracked_split = 74245328366319,
		rock_flat_slab = 120446354505612,
	}
local GROUND = 2
-- Layout.marketFrame(): rim slot 0, north, looking at the valley centre
local F = CFrame.new(0, 0, -500) * CFrame.Angles(0, math.pi, 0)

local old = workspace:FindFirstChild("PortalPreview")
if old then
	old:Destroy()
end
if REMOVE then
	return "PortalPreview removed"
end

-- Layout.marketPortal(): its foot on the ground, its opening (+Z) turned to the square's middle
local at = (F * CFrame.new(SPOT.x, 0, SPOT.z)).Position
at = Vector3.new(at.X, GROUND, at.Z)
local toward = Vector3.new(F.Position.X - at.X, 0, F.Position.Z - at.Z)
local base = CFrame.new(at) * CFrame.Angles(0, math.atan2(toward.X, toward.Z), 0)

local pieces: { [string]: MeshPart } = {}
for key, id in PIECES do
	local ok, model = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	local mp = if ok then model:FindFirstChildWhichIsA("MeshPart", true) else nil
	if not mp then
		return "piece " .. key .. " did not load: " .. tostring(model)
	end
	mp.Parent = nil
	pieces[key] = mp
	model:Destroy()
end

local R, BLOCKS = 12, 14
local STONE = Color3.fromRGB(132, 126, 168)
local SLAB = Color3.fromRGB(150, 146, 178)
local RUNE = Color3.fromRGB(110, 235, 255)
local RUNES = "rbxassetid://81706490345447"
local root = Instance.new("Model")
root.Name = "PortalPreview"
root.Parent = workspace

local function piece(key: string, foot: CFrame, size: Vector3, color: Color3?, solid: boolean): MeshPart
	local mp = pieces[key]:Clone()
	mp.Size = size
	mp.CFrame = foot * CFrame.new(0, size.Y / 2, 0)
	mp.Anchored = true
	mp.CanTouch = false
	mp.CanCollide = solid
	mp.CanQuery = solid
	mp.CastShadow = false
	if color then
		local sa = mp:FindFirstChildOfClass("SurfaceAppearance")
		if sa then
			sa:Destroy()
		end
		mp.TextureID = ""
		mp.Color = color
		mp.Material = Enum.Material.SmoothPlastic
	end
	mp.Parent = root
	return mp
end
local function air(name: string, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = root
	return p
end

local rng = Random.new(31)
for tier = 1, 2 do
	local radius = if tier == 1 then 17 else 11
	local count = if tier == 1 then 12 else 8
	local top = if tier == 1 then 1.6 else 3
	for i = 1, count do
		local a = (i - 0.5) / count * math.pi * 2
		local cf = base * CFrame.new(math.sin(a) * radius * 0.78, top - 2.4, math.cos(a) * radius * 0.78)
		local shade = SLAB:Lerp(STONE, rng:NextNumber(0, 0.5))
		piece("rock_flat_slab", cf * CFrame.Angles(0, a + rng:NextNumber(-0.15, 0.15), 0), Vector3.new(radius * 0.62, 2.4, radius * 0.5), shade, true)
	end
	piece("rock_flat_slab", base * CFrame.new(0, top - 2.4, 0), Vector3.new(radius * 1.1, 2.4, radius * 1.1), SLAB, true)
end
local floorY = 3
local centre = base * CFrame.new(0, floorY + R + 0.5, 0)
local shapes = { "rock_boulder_big", "rock_cracked_split", "rock_cliff_chunk" }
local spans, total = {}, 0
for i = 1, BLOCKS do
	spans[i] = rng:NextNumber(0.75, 1.3)
	total += spans[i]
end
local runes = {}
local angle = 0
for i = 1, BLOCKS do
	local share = spans[i] / total * math.pi * 2
	local a = angle + share / 2
	angle += share
	local radial = CFrame.Angles(0, 0, -a)
	local thick = rng:NextNumber(5.2, 7.2)
	local depth = rng:NextNumber(4.6, 6.4)
	local cf = centre * radial * CFrame.new(0, R - 3 + rng:NextNumber(-0.4, 0.4), 0) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), if rng:NextNumber() < 0.5 then 0 else math.pi, rng:NextNumber(-0.1, 0.1))
	local tint = STONE:Lerp(SLAB, rng:NextNumber(0, 0.45))
	local stone = piece(shapes[rng:NextInteger(1, #shapes)], cf, Vector3.new(share * R * 1.35, thick, depth), tint, true)
	if i % 2 == 0 then
		table.insert(runes, { cf = centre * radial * CFrame.new(0, R, 0), depth = depth, stone = stone })
	end
end
for n, r in runes do
	for side = -1, 1, 2 do
		local out = r.cf.LookVector * -side
		local p = r.cf.Position + out * (r.depth / 2 + 0.35)
		local plate = air("RunePlate", Vector3.new(3.6, 3.6, 0.1), CFrame.lookAt(p, p + out, r.cf.UpVector))
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		gui.Brightness = 2.5
		gui.CanvasSize = Vector2.new(128, 128)
		gui.Parent = plate
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = RUNES
		local k = (n + (if side < 0 then 1 else 0)) % 4
		img.ImageRectSize = Vector2.new(512, 512)
		img.ImageRectOffset = Vector2.new((k % 2) * 512, (k // 2) * 512)
		img.Parent = gui
	end
end
piece("portal_crystal", centre * CFrame.new(0, R + 1.5, 0), Vector3.new(5.5, 11, 5.5), nil, false)
for side = -1, 1, 2 do
	local foot = base * CFrame.new(side * 21, 0, 2.5)
	local shade = SLAB:Lerp(STONE, rng:NextNumber(0, 0.5))
	piece("rock_flat_slab", foot * CFrame.new(0, -1.2, 0) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), Vector3.new(7.5, 2.4, 7), shade, true)
	piece("portal_pillar", foot * CFrame.new(0, 1.1, 0), Vector3.new(4.5, 8, 4.5), STONE, true)
	piece("portal_crystal", foot * CFrame.new(0, 9.1, 0), Vector3.new(3, 6, 3), nil, false)
	piece("bush_tall_grass", foot * CFrame.new(side * 3, 0, 1.5), Vector3.new(3, 2, 3), nil, false)
end
-- the vortex, as a flat disc of its colour in the opening (the real one is particles)
local disc = air("VortexStandIn", Vector3.new(0.3, (R - 3) * 2.2, (R - 3) * 2.2), centre * CFrame.Angles(0, math.rad(90), 0))
disc.Shape = Enum.PartType.Cylinder
disc.Transparency = 0.25
disc.Color = Color3.fromRGB(120, 90, 220)
disc.Material = Enum.Material.Neon
local _ = RUNE
root.WorldPivot = base
root:ScaleTo(SCALE)
local cf, size = root:GetBoundingBox()
local lp = F:PointToObjectSpace(cf.Position)
return string.format("PortalPreview at local (%.1f, %.1f), box %.1f x %.1f x %.1f", lp.X, lp.Z, size.X, size.Y, size.Z)
