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
-- Returns nil, with one warning naming what is missing, when the kit lacks a model: Dungeon then falls back to its greybox.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Plan = require(ReplicatedStorage.Shared.DungeonArenaPlan)

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
				d.Color = colour
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
	-- every kit model of the plan, found and made ready; one warning names all that are missing
	local protos: { [string]: Proto } = {}
	local missing: { string } = {}
	for kind, names in A.Models :: any do
		for _, name in names do
			local source = kit:FindFirstChild(name)
			local proto = if source then prepare(source, kind == "round" or kind == "pine") else nil
			if proto then
				protos[name] = proto
			else
				table.insert(missing, name)
			end
		end
	end
	if #missing > 0 then
		warn(Config.LogPrefix, "dungeon arena: the kit lacks", table.concat(missing, ", "), "(the greybox stands in)")
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

	-- the scenery: kit models scaled to the plan's size (by height, or by width), feet on the floor
	local folders: { [string]: Folder } = {}
	local models = 0
	for _, item in Plan.build() do
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
