--!strict
-- The one Dungeon Portal, in the Market (the owner, 2026-11-04: "use the portal we have"; then: one portal in the shopping
-- area for everyone, each player going to their own arena). It is Egg Heist's mount-realm portal
-- (C:\roblox 2nd game\tools\realm\portal.luau and its reference picture there), rebuilt from the same kit meshes, which the
-- owner's account published (Config.Dungeon.Portal.Pieces): an upright ring of grey-purple stones with glowing runes, a
-- crystal on top, two pillars with crystals, a round slab platform and a swirling vortex drawn by particles (no script
-- turns it). It is built at full size where it stands (the runes are fitted by rays at the stones) and scaled down about
-- its foot (Layout.marketPortal). PortalTrigger, the opening, carries the prompt that opens the Dungeon.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local P = Config.Dungeon.Portal

local R = 12 -- the ring's middle radius, full size
local BLOCKS = 14
local STONE = Color3.fromRGB(132, 126, 168)
local SLAB = Color3.fromRGB(150, 146, 178)
local RUNE = Color3.fromRGB(110, 235, 255)
local VORTEX = "rbxassetid://125584435060374"
local RUNES = "rbxassetid://81706490345447"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

local DungeonPortal = {}

local pieces: { [string]: MeshPart } = {}

local function load(): boolean
	local ids: { [string]: number } = P.Pieces :: any
	for key, id in ids do
		local ok, model = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		local mp = if ok then (model :: Instance):FindFirstChildWhichIsA("MeshPart", true) else nil
		if not mp then
			warn(Config.LogPrefix, "dungeon portal: piece", key, "did not load:", if ok then "no mesh" else model)
			return false
		end
		mp.Parent = nil
		pieces[key] = mp
		model:Destroy()
	end
	return true
end

local function build(base: CFrame): Model
	local root = Instance.new("Model")
	root.Name = "DungeonPortal"

	-- one kit mesh, sized to `size`, its foot's middle at `foot`; solid pieces collide by their box
	local function piece(key: string, foot: CFrame, size: Vector3, color: Color3?, solid: boolean): MeshPart
		local mp = pieces[key]:Clone()
		mp.Size = size
		mp.CFrame = foot * CFrame.new(0, size.Y / 2, 0)
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
			-- painted flat: a tint only multiplies the generated texture, which came out teal
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
		p.CastShadow = false
		p.Parent = root
		return p
	end

	local rng = Random.new(31)

	-- 1. the platform: an outer ring of low slabs and a higher inner disc
	for tier = 1, 2 do
		local radius = if tier == 1 then 17 else 11
		local count = if tier == 1 then 12 else 8
		local top = if tier == 1 then 1.6 else 3
		for i = 1, count do
			local a = (i - 0.5) / count * math.pi * 2
			local at = base * CFrame.new(math.sin(a) * radius * 0.78, top - 2.4, math.cos(a) * radius * 0.78)
			local shade = SLAB:Lerp(STONE, rng:NextNumber(0, 0.5))
			piece(
				"rock_flat_slab",
				at * CFrame.Angles(0, a + rng:NextNumber(-0.15, 0.15), 0),
				Vector3.new(radius * 0.62, 2.4, radius * 0.5),
				shade,
				true
			)
		end
		piece(
			"rock_flat_slab",
			base * CFrame.new(0, top - 2.4, 0),
			Vector3.new(radius * 1.1, 2.4, radius * 1.1),
			SLAB,
			true
		)
	end
	local floorY = 3

	-- 2. the ring: natural stones of three shapes round a circle in the portal's plane, each its own size, shade and twist
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
		local at = centre
			* radial
			* CFrame.new(0, R - 3 + rng:NextNumber(-0.4, 0.4), 0)
			* CFrame.Angles(
				rng:NextNumber(-0.12, 0.12),
				if rng:NextNumber() < 0.5 then 0 else math.pi,
				rng:NextNumber(-0.1, 0.1)
			)
		local tint = STONE:Lerp(SLAB, rng:NextNumber(0, 0.45))
		local stone =
			piece(shapes[rng:NextInteger(1, #shapes)], at, Vector3.new(share * R * 1.35, thick, depth), tint, true)
		stone.Name = "RingStone"
		if i % 2 == 0 then
			table.insert(runes, { cf = centre * radial * CFrame.new(0, R, 0), depth = depth, stone = stone })
		end
	end

	-- the runes: glowing glyphs (a 2 x 2 sheet) on the front and back of every other stone, each on the stone's real
	-- surface, found by a ray at a precise copy of the stone (a plate at half its depth was buried in most of them)
	for n, r in runes do
		local probe = r.stone:Clone()
		probe.Transparency = 1
		probe.CanQuery = true
		pcall(function()
			(probe :: any).CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
		end)
		probe.Parent = workspace
		task.wait()
		local only = RaycastParams.new()
		only.FilterType = Enum.RaycastFilterType.Include
		only.FilterDescendantsInstances = { probe }
		for side = -1, 1, 2 do
			local out = r.cf.LookVector * -side
			local hit = workspace:Raycast(r.cf.Position + out * 20, -out * 40, only)
			local at = if hit then hit.Position + out * 0.25 else r.cf.Position + out * (r.depth / 2 + 0.35)
			local plate = air("RunePlate", Vector3.new(3.6, 3.6, 0.1), CFrame.lookAt(at, at + out, r.cf.UpVector))
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Front
			gui.LightInfluence = 0
			gui.Brightness = 2.5
			gui.CanvasSize = Vector2.new(128, 128)
			-- (14 rune canvases: drawn as far as the portal's own sparkles, not from every plot of the valley)
			gui.MaxDistance = Config.Perf.EmitterStuds
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
		probe:Destroy()
	end

	-- 3. the crystal on top; 4. two pillars with crystals clear of the ring. The crystals glow and give off rising motes.
	local function glow(crystal: BasePart, height: number)
		local a = Instance.new("Attachment")
		a.Parent = crystal
		local light = Instance.new("PointLight")
		light.Color = RUNE
		light.Range = 9
		light.Brightness = 0.8
		light.Shadows = false
		light.Parent = crystal
		local halo = Instance.new("ParticleEmitter")
		halo.Name = "Halo"
		halo.Texture = SPARKLE
		halo.Rate = 2
		halo.Lifetime = NumberRange.new(1.5)
		halo.Speed = NumberRange.new(0)
		halo.LockedToPart = true
		halo.Size = NumberSequence.new(height * 1.1)
		halo.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		})
		halo.Color = ColorSequence.new(RUNE)
		halo.LightEmission = 1
		halo.Parent = a
		local motes = Instance.new("ParticleEmitter")
		motes.Name = "Motes"
		motes.Texture = SPARKLE
		motes.Rate = 4
		motes.Lifetime = NumberRange.new(2, 3.5)
		motes.Speed = NumberRange.new(1.5, 3)
		motes.SpreadAngle = Vector2.new(20, 20)
		motes.EmissionDirection = Enum.NormalId.Top
		motes.Acceleration = Vector3.new(0, 0.6, 0)
		motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		motes.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		motes.Color = ColorSequence.new(Color3.fromRGB(210, 250, 255), RUNE)
		motes.LightEmission = 1
		motes.Parent = a
	end
	glow(piece("portal_crystal", centre * CFrame.new(0, R + 1.5, 0), Vector3.new(5.5, 11, 5.5), nil, false), 11)
	for side = -1, 1, 2 do
		local foot = base * CFrame.new(side * 21, 0, 2.5)
		local shade = SLAB:Lerp(STONE, rng:NextNumber(0, 0.5))
		piece(
			"rock_flat_slab",
			foot * CFrame.new(0, -1.2, 0) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			Vector3.new(7.5, 2.4, 7),
			shade,
			true
		)
		piece("portal_pillar", foot * CFrame.new(0, 1.1, 0), Vector3.new(4.5, 8, 4.5), STONE, true)
		glow(piece("portal_crystal", foot * CFrame.new(0, 9.1, 0), Vector3.new(3, 6, 3), nil, false), 6)
		piece("bush_tall_grass", foot * CFrame.new(side * 3, 0, 1.5), Vector3.new(3, 2, 3), nil, false)
	end

	-- 5. the vortex: an invisible disc in the opening carrying big single particles that lie in the ring's plane and spin
	local inner = R - 3
	local disc = air("Vortex", Vector3.new(1, 1, 0.2), centre)
	local point = Instance.new("Attachment")
	point.Name = "VortexCentre"
	point.Parent = disc
	local function swirl(name: string, size: number, rot: number, alpha: number, emission: number)
		local e = Instance.new("ParticleEmitter")
		e.Name = name
		e.Texture = VORTEX
		e.EmissionDirection = Enum.NormalId.Front
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		e.Speed = NumberRange.new(0.001)
		e.SpreadAngle = Vector2.new(0, 0)
		e.Lifetime = NumberRange.new(4)
		e.Rate = 0.75
		e.Size = NumberSequence.new(size)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(rot)
		e.LockedToPart = true
		e.LightEmission = emission
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, alpha),
			NumberSequenceKeypoint.new(0.75, alpha),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Parent = point
	end
	swirl("Swirl", inner * 1.3, -55, 0.05, 0.55)
	swirl("SwirlGlow", inner * 0.9, 35, 0.6, 1)
	swirl("SwirlHalo", inner * 1.42, 20, 0.85, 1)
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "Sparkles"
	sparkle.Texture = SPARKLE
	sparkle.Rate = 6
	sparkle.Lifetime = NumberRange.new(1, 2)
	sparkle.Speed = NumberRange.new(1, 3)
	sparkle.SpreadAngle = Vector2.new(60, 60)
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Color = ColorSequence.new(Color3.fromRGB(220, 250, 255))
	sparkle.LightEmission = 1
	sparkle.Parent = point
	-- a soft light only: a strong one turned every stone cyan
	local light = Instance.new("PointLight")
	light.Color = RUNE
	light.Range = 16
	light.Brightness = 0.9
	light.Shadows = false
	light.Parent = disc

	-- 6. the opening, where the prompt hangs
	air("PortalTrigger", Vector3.new(inner * 1.6, inner * 1.8, 4), centre)

	-- no PrimaryPart: with one the pivot follows that part (the ring's middle) and PivotTo sank the portal to its waist
	root.WorldPivot = base
	-- streamed in whole: piece by piece a phone showed half a ring
	root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return root
end

function DungeonPortal.start()
	task.spawn(function()
		if not load() then
			return
		end
		local folder = Instance.new("Folder")
		folder.Name = "DungeonPortals"
		folder.Parent = workspace
		-- built in the world (the rune rays need it there), then scaled about its foot
		local portal = build(Layout.marketPortal())
		portal.Name = "Portal"
		portal.Parent = folder
		portal:ScaleTo(P.Scale)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DungeonPrompt"
		prompt.ActionText = "Enter"
		prompt.ObjectText = "Slime Dungeon"
		prompt.MaxActivationDistance = P.PromptRangeStuds
		prompt.RequiresLineOfSight = false
		prompt.Parent = portal:FindFirstChild("PortalTrigger")
		print(Config.LogPrefix, "dungeon portal placed in the Market")
	end)
end

return DungeonPortal
