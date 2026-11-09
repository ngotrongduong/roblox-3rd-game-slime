--!strict
-- The Slime Dungeon's maps (the Sunny Meadow, the Mushroom Grove, Ember Lava and Frozen Ice), each built once from the owner's painting
-- (reference/goo-lineage-web/assets/battle.map.<id>.png) and kept as a template that Dungeon clones for every run on that map.
-- A Model whose pivot is the floor's top middle (Dungeon pivots a clone onto Layout.arenaFrame). Where things stand is
-- shared/DungeonArenaPlan; every number is Config.Dungeon.Arenas.<map>.
--
--   Floor     one grass block in the classic stud look (the village's), thick enough to stand on
--   Paths     the four paths: flat stud-look blocks (dirt) or loose flagstones just over the grass, fading toward the grass at
--             their inner ends
--   Runes     (the Grove) four flat stone rings with glowing marks in the quarters
--   Lights    (the Grove) a few small point lights under the glowing mushroom clusters; (Ember Lava) the same under a few pools
--   Lava      (Ember Lava) flat veins and pools: library meshes turned Neon (Arenas.lava.Neon), under everything else
--             (Frozen Ice turns its crystals and shards Neon the same way, a little see-through: Neon, NeonAlpha)
--   Snow      (Frozen Ice) the low drifts of its shore, under everything else
--   Wall      an invisible ring of tall blocks at the edge of the fight: the only thing besides the floor that collides
--   Trees / Rocks / Bushes / Flowers   kit models (ServerStorage.Kit.WildKit): anchored, nothing collides or can be queried, only
--             the trees cast a shadow; the clones of one kit model share one mesh
--
-- Returns nil, with one warning, when there are no trees or rocks to be had at all: Dungeon then falls back to its greybox.
-- (Library props not in yet: the kind is built from the valley's WildKit models, one warning names which.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Plan = require(ReplicatedStorage.Shared.DungeonArenaPlan)
local LibraryKit = require(script.Parent.LibraryKit)

-- a kit model made ready to clone: its foot at the origin, and the height and width it measures at scale 1
type Proto = { model: Model, height: number, width: number }

local DungeonArena = {}

-- the template of each map, once built (and whether it was tried: a map that cannot be built is not tried again)
local cached: { [string]: Model } = {}
local tried: { [string]: boolean } = {}

local function wildKit(): Instance?
	local kit = ServerStorage:FindFirstChild("WildKit")
	local bundle = ServerStorage:FindFirstChild("Kit")
	return kit or (if bundle then bundle:FindFirstChild("WildKit") else nil)
end

-- Folder a kind goes in.
local FOLDERS: { [string]: string } = {
	round = "Trees",
	pine = "Trees",
	rock = "Rocks",
	bush = "Bushes",
	flower = "Flowers",
	tuft = "Flowers",
	pebble = "Flowers",
	stump = "Rocks",
	log = "Rocks",
	ruin = "Rocks",
	root = "Rocks",
	glow = "Flowers",
	vein = "Lava",
	pool = "Lava",
	mound = "Snow",
	bank = "Snow",
	patch = "Snow",
	cliff = "Rocks",
	hero = "Flowers",
	frost = "Bushes",
}

local function prepare(source: Instance, tree: boolean): Proto?
	if not source:IsA("Model") then
		return nil
	end
	local model = source:Clone()
	model.PrimaryPart = nil
	model.WorldPivot = CFrame.new()
	local box, size = model:GetBoundingBox()
	if size.Y < 0.01 then
		return nil
	end
	model.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	model:PivotTo(CFrame.new())
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			-- only a tree is big enough for its shadow to pay
			d.CastShadow = tree
		elseif d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	return { model = model, height = size.Y, width = math.max(size.X, size.Z) }
end

-- A tint multiplies the model's own colours, on its SurfaceAppearance (or its colour), the trunk left alone.
local function tint(model: Model, hex: string)
	if hex == "#ffffff" then
		return
	end
	local colour = Color3.fromHex(hex)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not string.find(string.lower(d.Name), "bark", 1, true) then
			local appearance = d:FindFirstChildOfClass("SurfaceAppearance")
			if appearance then
				appearance.Color = colour
			else
				-- (a library prop's colour is white under its vertex colours, so this is the tint itself)
				d.Color = Color3.new(d.Color.R * colour.R, d.Color.G * colour.G, d.Color.B * colour.B)
			end
		end
	end
end

-- Lava is lit by itself: the model's parts turn Neon in the map's lava colour. The mesh carries its own palette in vertex
-- colour (a hot core, an orange body, a dark burnt bank) and Roblox multiplies that by the part's colour, so with a white
-- part colour the lava glows as painted and the bank stays dark.
-- (Frozen Ice's crystals are the same, a little see-through: `clear` is the Transparency of the map's NeonAlpha, 0 when none.)
local function glowing(model: Model, hex: string, clear: number)
	local colour = Color3.fromHex(hex)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Material = Enum.Material.Neon
			d.Color = colour
			d.Transparency = clear
			d.CastShadow = false
		end
	end
end

local function slab(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = colour
	part.Material = Enum.Material.Plastic
	-- the classic stud look the owner chose for floors and built ground
	part.TopSurface = Enum.SurfaceType.Studs
	part.CastShadow = false
	part.CanTouch = false
	part.Parent = parent
	return part
end

local function build(kit: Instance, mapId: string): Model?
	local A = (Config.Dungeon.Arenas :: any)[mapId]
	-- every model of the plan, found and made ready: a kind is built from its library props, or from the valley's WildKit
	-- models when some library prop is not in yet; one warning names what is missing
	local protos: { [string]: Proto } = {}
	local lists: { [string]: { string } } = {}
	local missing: { string } = {}
	local function ready(kind: string, names: { string }): boolean
		local found: { [string]: Proto } = {}
		for _, name in names do
			if not protos[name] then
				local source = LibraryKit.find(name) or kit:FindFirstChild(name)
				local proto = if source then prepare(source, kind == "round" or kind == "pine") else nil
				if not proto then
					return false
				end
				found[name] = proto
			end
		end
		for name, proto in found do
			protos[name] = proto
		end
		return true
	end
	for kind, names in A.Models :: any do
		if ready(kind, names) then
			lists[kind] = names
		else
			local fallback: { string } = ((A.Fallback :: any)[kind] or {}) :: { string }
			table.insert(missing, kind)
			lists[kind] = if ready(kind, fallback) then fallback else {}
		end
	end
	if #missing > 0 then
		warn(
			Config.LogPrefix,
			"dungeon arena: the library lacks props of",
			table.concat(missing, ", "),
			"(the kit stands in)"
		)
	end
	if #lists.round == 0 or #lists.rock == 0 then
		warn(Config.LogPrefix, "dungeon arena: no trees or rocks at all (the greybox stands in)")
		return nil
	end

	local arena = Instance.new("Model")
	arena.Name = Config.Dungeon.ArenaTemplate
	arena.WorldPivot = CFrame.new()

	-- the floor: its top is the arena's middle height
	local grass = Color3.fromHex(A.FloorColour)
	local thick = Config.Dungeon.ArenaFloorThickness
	local floor = Instance.new("Folder")
	floor.Name = "Floor"
	floor.Parent = arena
	slab(floor, "Grass", Vector3.new(A.FloorHalf * 2, thick, A.FloorHalf * 2), CFrame.new(0, -thick / 2, 0), grass)

	-- the four paths: flat, just over the grass (a segment further in sits a little higher), nothing to stand on or hit
	local paths = Instance.new("Folder")
	paths.Name = "Paths"
	paths.Parent = arena
	if A.PathStyle == "stones" then
		-- loose flagstones, each a little uneven; some mossy; the inner ones fade toward the grass
		local S = A.Stones
		local stone = Color3.fromHex(S.Colour)
		local moss = Color3.fromHex(S.MossColour)
		for _, st in Plan.stones(mapId) do
			local colour = stone
			if st.shade >= 0 then
				colour = colour:Lerp(Color3.new(1, 1, 1), st.shade * S.Shade)
			else
				colour = colour:Lerp(Color3.new(0, 0, 0), -st.shade * S.Shade)
			end
			if st.mossy then
				colour = colour:Lerp(moss, 0.6)
			end
			local y = A.PathLift + S.Thick / 2 + (st.index - 1) * A.PathStep
			local part = slab(
				paths,
				"Stone",
				Vector3.new(st.wide, S.Thick, st.deep),
				CFrame.new(st.x, y, st.z) * CFrame.Angles(0, st.yaw, 0) * CFrame.Angles(st.pitch, 0, st.roll),
				colour:Lerp(grass, st.fade)
			)
			part.CanCollide = false
			part.CanQuery = false
		end
	elseif A.PathStyle ~= "none" then
		-- (PathStyle "none", Ember Lava: no path is drawn, the lanes along the four axes only stay free of scenery)
		local dirt = Color3.fromHex(A.PathColour)
		for _, seg in Plan.paths(mapId) do
			local y = A.PathLift + A.PathThick / 2 + (seg.index - 1) * A.PathStep
			local part = slab(
				paths,
				"Path",
				Vector3.new(seg.width, A.PathThick, seg.length),
				CFrame.new(seg.x, y, seg.z) * CFrame.Angles(0, seg.yaw, 0),
				dirt:Lerp(grass, seg.fade)
			)
			part.CanCollide = false
			part.CanQuery = false
		end
	end

	-- the rune circles (a map with `Runes`): a flat ring of stones with glowing marks round it and a smaller ring inside
	local R = A.Runes
	if R then
		local runes = Instance.new("Folder")
		runes.Name = "Runes"
		runes.Parent = arena
		local stoneColour = Color3.fromHex(R.Stone)
		local glowColour = Color3.fromHex(R.Colour)
		local function ring(
			circle: { x: number, z: number, radius: number, yaw: number },
			count: number,
			radius: number,
			size: Vector3,
			lift: number,
			glow: boolean,
			phase: number
		)
			for k = 1, count do
				local angle = circle.yaw + phase + (k - 0.5) / count * math.pi * 2
				local at = Vector3.new(
					circle.x + math.cos(angle) * radius,
					A.PathLift + lift,
					circle.z + math.sin(angle) * radius
				)
				local part = slab(
					runes,
					if glow then "Mark" else "RingStone",
					size,
					CFrame.lookAt(at, at + Vector3.new(-math.sin(angle), 0, math.cos(angle))),
					if glow then glowColour else stoneColour:Lerp(grass, 0.15 * (k % 3))
				)
				part.CanCollide = false
				part.CanQuery = false
				if glow then
					part.Material = Enum.Material.Neon
					part.TopSurface = Enum.SurfaceType.Smooth
				end
			end
		end
		for _, circle in Plan.runes(mapId) do
			local arc = 2 * math.pi * circle.radius / R.Marks
			ring(circle, R.Marks, circle.radius, Vector3.new(R.RingWidth, R.Thick, arc * 1.05), R.Thick / 2, false, 0)
			ring(
				circle,
				R.Marks,
				circle.radius - R.RingWidth * 1.6,
				Vector3.new(R.MarkWidth, R.Thick, R.MarkLength),
				R.Thick * 1.5,
				true,
				0.5 / R.Marks
			)
			ring(
				circle,
				R.Marks / 2,
				circle.radius * 0.5,
				Vector3.new(R.MarkWidth, R.Thick, R.MarkLength * 1.15),
				R.Thick * 1.5,
				true,
				0
			)
		end
	end

	-- the wall: invisible, tall, a ring of overlapping blocks just outside the fight
	local wall = Instance.new("Folder")
	wall.Name = "Wall"
	wall.Parent = arena
	local segments = A.WallSegments
	local radius = A.WallRadius + A.WallThickness / 2
	local arc = 2 * radius * math.tan(math.pi / segments) + 1
	for index = 1, segments do
		local angle = (index - 0.5) / segments * math.pi * 2
		local at = Vector3.new(math.cos(angle) * radius, A.WallHeight / 2, math.sin(angle) * radius)
		local part = slab(
			wall,
			"Wall",
			Vector3.new(arc, A.WallHeight, A.WallThickness),
			CFrame.lookAt(at, Vector3.new(0, A.WallHeight / 2, 0)),
			grass
		)
		part.Transparency = 1
		part.CanQuery = false
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
	end

	-- the hills: flattened balls of grass behind the woods, the horizon the player's camera reads past the trees
	local hills = Instance.new("Folder")
	hills.Name = "Hills"
	hills.Parent = arena
	for index, hill in Plan.hills(mapId, lists) do
		local proto = if hill.model then protos[hill.model] else nil
		local meshParts: { BasePart } = {}
		local clone: Model? = nil
		if proto then
			-- a library hill (Frozen Ice's faceted ridges and far land): one mesh stretched to the plan's width and height, its
			-- depth in proportion to its width, its foot sunk by hill.sink of its height, its X along the horizon
			clone = proto.model:Clone()
			for _, d in (clone :: Model):GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(meshParts, d)
				end
			end
		end
		if clone and #meshParts == 1 then
			local mesh = meshParts[1]
			local depth = hill.wide * mesh.Size.Z / mesh.Size.X
			mesh.Size = Vector3.new(hill.wide, hill.tall, depth)
			mesh.CFrame = CFrame.new(0, hill.tall / 2, 0)
			clone:PivotTo(CFrame.new(hill.x, -hill.sink * hill.tall, hill.z) * CFrame.Angles(0, hill.yaw, 0))
			clone.Name = "Hill"
			clone.Parent = hills
			continue
		elseif clone then
			clone:Destroy()
		end
		-- (a map with a far ring of hills gives each ring its own colour)
		local hillGreen = Color3.fromHex(hill.colour)
		local part = Instance.new("Part")
		part.Name = "Hill"
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(hill.wide, hill.tall, hill.wide)
		part.Position = Vector3.new(hill.x, hill.tall * (0.5 - hill.sink), hill.z)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		-- (Plastic is matte; SmoothPlastic made the hills glossy balls)
		part.Material = Enum.Material.Plastic
		part.Color = hillGreen:Lerp(Color3.new(0, 0, 0), if index % 2 == 0 then 0.1 else 0)
		part.Parent = hills
		-- (Ember Lava: every Every-th hill is a volcano, a glowing dome on its top)
		local cap = A.Hills.Glow
		if cap and index % cap.Every == 0 then
			local dome = part:Clone()
			dome.Name = "HillGlow"
			dome.Size = Vector3.new(hill.wide * cap.Wide, hill.tall * cap.Tall, hill.wide * cap.Wide)
			dome.Position = Vector3.new(hill.x, hill.tall * (1 - hill.sink) - hill.tall * cap.Tall * 0.15, hill.z)
			dome.Material = Enum.Material.Neon
			dome.Color = Color3.fromHex(cap.Colour)
			dome.Parent = hills
		end
	end

	-- the scenery: kit models scaled to the plan's size (by height, or by width), feet on the floor
	local folders: { [string]: Folder } = {}
	local models = 0
	local lights: Folder? = nil
	for _, item in Plan.build(lists, mapId) do
		local proto = protos[item.model]
		local clone = proto.model:Clone()
		clone:ScaleTo(item.size / (if item.wide then proto.width else proto.height))
		clone:PivotTo(CFrame.new(item.x, 0, item.z) * CFrame.Angles(0, item.yaw, 0))
		if item.tint then
			tint(clone, item.tint)
		end
		local lava = if A.Neon then A.Neon[item.kind] else nil
		if lava then
			glowing(clone, lava, if A.NeonAlpha then A.NeonAlpha[item.kind] or 0 else 0)
		end
		local name = FOLDERS[item.kind]
		local folder: Folder
		local found = folders[name]
		if found then
			folder = found
		else
			folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = arena
			folders[name] = folder
		end
		clone.Parent = folder
		models += 1
		if item.light then
			-- a small point light under a glowing cluster, in the colour its mushroom's name gives
			local G = A.Glow
			local holder: Folder
			if lights then
				holder = lights
			else
				holder = Instance.new("Folder")
				holder.Name = "Lights"
				holder.Parent = arena
				lights = holder
			end
			local spot = Instance.new("Part")
			spot.Name = "GlowLight"
			spot.Size = Vector3.one
			spot.Transparency = 1
			spot.Anchored = true
			spot.CanCollide = false
			spot.CanTouch = false
			spot.CanQuery = false
			spot.CastShadow = false
			spot.Position = Vector3.new(item.x, G.Lift, item.z)
			local light = Instance.new("PointLight")
			light.Range = G.Range
			light.Brightness = G.Brightness
			light.Shadows = false
			for key, hex in G.Colours do
				if string.find(item.model, key, 1, true) then
					light.Color = Color3.fromHex(hex)
				end
			end
			light.Parent = spot
			spot.Parent = holder
		end
		if item.zone == "backdrop" then
			-- the far woods are too far for a shadow to read
			for _, d in clone:GetDescendants() do
				if d:IsA("BasePart") then
					d.CastShadow = false
				end
			end
		end
	end

	local parts, meshes = 0, 0
	for _, d in arena:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			if d:IsA("MeshPart") then
				meshes += 1
			end
		end
	end
	print(Config.LogPrefix, "dungeon arena built:", parts, "parts,", meshes, "meshes,", models, "kit models")
	return arena
end

-- A map (the Meadow when none is named) as a Model with its pivot at the floor's top middle, built on the first ask and kept
-- (clone it; never parent it). nil when the kit lacks a model it needs, or the map is unknown.
function DungeonArena.template(mapId: string?): Model?
	local id = mapId or "meadow"
	if cached[id] or tried[id] then
		return cached[id]
	end
	tried[id] = true
	if not (Config.Dungeon.Arenas :: any)[id] then
		warn(Config.LogPrefix, "dungeon arena: no such map", id)
		return nil
	end
	local kit = wildKit()
	if not kit then
		warn(Config.LogPrefix, "dungeon arena: ServerStorage.Kit.WildKit is missing (the greybox stands in)")
		return nil
	end
	local arena = build(kit, id)
	if arena then
		arena:SetAttribute("MapId", id)
		cached[id] = arena
	end
	return arena
end

return DungeonArena
