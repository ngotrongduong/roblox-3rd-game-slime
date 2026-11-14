--!strict
-- A waystone's look (docs/WORLD.md §7, M5b): the Dungeon Portal's own side pillar - a round slab, the carved pillar and a
-- glowing crystal, from the same kit meshes (Config.Dungeon.Portal.Pieces) and in the same colours - with one glowing rune
-- on its face, so a player reads it as kin of the portal: a stone that takes you somewhere. Built by the server, the same
-- for everyone; whether a player may use one is the map's to say (client/UiMap). Sizes are the portal's, times
-- Config.World.Waystones.Look.Scale.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local L = Config.World.Waystones.Look
local KEYS = { "rock_flat_slab", "portal_pillar", "portal_crystal" }
local STONE = Color3.fromRGB(132, 126, 168)
local SLAB = Color3.fromRGB(150, 146, 178)
local RUNE = Color3.fromRGB(110, 235, 255)
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

local Waystone = {}

local pieces: { [string]: MeshPart } = {}

-- Fetches the kit meshes (it yields); false when one did not come, and then no waystone has a look.
function Waystone.load(): boolean
	local ids: { [string]: number } = Config.Dungeon.Portal.Pieces :: any
	for _, key in KEYS do
		local ok, model = pcall(function()
			return InsertService:LoadAsset(ids[key])
		end)
		local mp = if ok then (model :: Instance):FindFirstChildWhichIsA("MeshPart", true) else nil
		if not mp then
			warn(Config.LogPrefix, "waystone: piece", key, "did not load:", if ok then "no mesh" else model)
			return false
		end
		mp.Parent = nil
		pieces[key] = mp
		model:Destroy()
	end
	return true
end

-- One waystone standing with the middle of its foot at `foot`, its rune on the side `foot` looks to.
function Waystone.build(foot: CFrame): Model
	local s = L.Scale
	local root = Instance.new("Model")
	root.Name = "Waystone"

	-- one kit mesh, its foot's middle `up` studs over the waystone's foot; painted flat as the portal's stones are
	local function piece(key: string, up: number, size: Vector3, color: Color3?, solid: boolean): MeshPart
		local mp = pieces[key]:Clone()
		mp.Size = size * s
		mp.CFrame = foot * CFrame.new(0, (up + size.Y / 2) * s, 0)
		mp.Anchored = true
		mp.CanTouch = false
		mp.CanCollide = solid
		mp.CanQuery = solid
		mp.CastShadow = false
		if solid then
			pcall(function()
				(mp :: any).CollisionFidelity = Enum.CollisionFidelity.Box
			end)
		end
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

	piece("rock_flat_slab", -1.2, Vector3.new(7.5, 2.4, 7), SLAB, true)
	piece("portal_pillar", 1.1, Vector3.new(4.5, 8, 4.5), STONE, true)
	local crystal = piece("portal_crystal", 9.1, Vector3.new(3, 6, 3), nil, false)

	-- the rune: one glyph of the portal's sheet (2 x 2) on the pillar's face
	local plate = Instance.new("Part")
	plate.Name = "RunePlate"
	plate.Size = Vector3.new(L.RuneStuds, L.RuneStuds, 0.1) * s
	plate.CFrame = foot * CFrame.new(0, L.RuneHeight * s, -L.RuneOut * s)
	plate.Transparency = 1
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanTouch = false
	plate.CanQuery = false
	plate.CastShadow = false
	plate.Parent = root
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 2.5
	gui.CanvasSize = Vector2.new(128, 128)
	gui.MaxDistance = Config.Perf.EmitterStuds
	gui.Parent = plate
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1, 1)
	img.BackgroundTransparency = 1
	img.Image = "rbxassetid://" .. L.Runes
	img.ImageRectSize = Vector2.new(512, 512)
	img.Parent = gui

	-- the crystal glows and gives off a few rising motes (the portal's own, fewer)
	local a = Instance.new("Attachment")
	a.Parent = crystal
	local light = Instance.new("PointLight")
	light.Color = RUNE
	light.Range = L.LightRange
	light.Brightness = L.LightBrightness
	light.Shadows = false
	light.Parent = crystal
	local motes = Instance.new("ParticleEmitter")
	motes.Name = "Motes"
	motes.Texture = SPARKLE
	motes.Rate = L.MotesRate
	motes.Lifetime = NumberRange.new(2, 3.5)
	motes.Speed = NumberRange.new(1.5, 3)
	motes.SpreadAngle = Vector2.new(20, 20)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.Acceleration = Vector3.new(0, 0.6, 0)
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	motes.Color = ColorSequence.new(Color3.fromRGB(210, 250, 255), RUNE)
	motes.LightEmission = 1
	motes.Parent = a

	root.WorldPivot = foot
	-- streamed in whole: piece by piece a phone showed half a portal
	root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return root
end

return Waystone
