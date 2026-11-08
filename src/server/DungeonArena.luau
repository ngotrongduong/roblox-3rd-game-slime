--!strict
-- The Slime Dungeon's Sunny Meadow, built once from the owner's painting (reference/goo-lineage-web/assets/battle.map.meadow.png)
-- and kept as a template that Dungeon clones for every run. A Model whose pivot is the floor's top middle (Dungeon pivots a clone
-- onto Layout.arenaFrame). Where things stand is shared/DungeonArenaPlan; every number is Config.Dungeon.Arena.
--
--   Floor     one grass block in the classic stud look (the village's), thick enough to stand on
--   Paths     the four dirt paths: flat stud-look blocks just over the grass, fading toward the grass at their inner ends
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

local A = Config.Dungeon.Arena

-- a kit model made ready to clone: its foot at the origin, and the height and width it measures at scale 1
type Proto = { model: Model, height: number, width: number }

local DungeonArena = {}

local cached: Model? = nil
local tried = false

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

local function build(kit: Instance): Model?
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
	local dirt = Color3.fromHex(A.PathColour)
	for _, seg in Plan.paths() do
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
	local hillGreen = Color3.fromHex(A.Hills.Colour)
	for index, hill in Plan.hills() do
		local part = Instance.new("Part")
		part.Name = "Hill"
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(hill.wide, hill.tall, hill.wide)
		part.Position = Vector3.new(hill.x, hill.tall * (0.5 - A.Hills.Sink), hill.z)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		-- (Plastic is matte; SmoothPlastic made the hills glossy balls)
		part.Material = Enum.Material.Plastic
		part.Color = hillGreen:Lerp(Color3.new(0, 0, 0), if index % 2 == 0 then 0.1 else 0)
		part.Parent = hills
	end

	-- the scenery: kit models scaled to the plan's size (by height, or by width), feet on the floor
	local folders: { [string]: Folder } = {}
	local models = 0
	for _, item in Plan.build(lists) do
		local proto = protos[item.model]
		local clone = proto.model:Clone()
		clone:ScaleTo(item.size / (if item.wide then proto.width else proto.height))
		clone:PivotTo(CFrame.new(item.x, 0, item.z) * CFrame.Angles(0, item.yaw, 0))
		if item.tint then
			tint(clone, item.tint)
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

-- The Sunny Meadow as a Model with its pivot at the floor's top middle, built on the first ask and kept (clone it; never parent
-- it). nil when the kit lacks a model it needs.
function DungeonArena.template(): Model?
	if cached or tried then
		return cached
	end
	tried = true
	local kit = wildKit()
	if not kit then
		warn(Config.LogPrefix, "dungeon arena: ServerStorage.Kit.WildKit is missing (the greybox stands in)")
		return nil
	end
	cached = build(kit)
	return cached
end

return DungeonArena
