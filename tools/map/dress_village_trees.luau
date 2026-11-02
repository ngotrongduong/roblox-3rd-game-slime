-- Dresses the hand-built village (the template, workspace.Map.Plot5) with the valley's trees, bushes and small plants (the owner,
-- 2026-11-02: the village and the valley's middle must match). Replaces the old Nature kit's trees, bushes, flower patches, grass
-- tufts and ferns (the village's Nature folder, each area's, and FenceSkirt outside the fence) with models of ServerStorage.WildKit
-- (Quaternius' Stylized Nature MegaKit: QtPine_*, QtCommonTree_*, QtBush_Common_Green, QtBush_Common_Flowers, QtFlower_*_Group,
-- QtGrass_*, QtFern_1, QtPlant_1_Big), on the spot of each old one or the nearest spot that no upgrade piece of ANY level of ANY area
-- takes (tools/map/village_footprints.luau: every stage module is run level 1-50 on a clone; the paths, doors, work places and the pond's
-- water too). Stumps, log benches, rocks, boulders, sunflowers and water lilies are left as they are.
-- Run in Edit mode through Studio's MCP; it can be run again at any time (it removes what it made, and any old piece left):
--   node tools/studio_mcp.js run tools/map/dress_village_trees.luau <studio_id> Edit LIB=tools/map/village_footprints.luau PLAN=tools/map/village_scenery_plan.txt
-- Then tools/map/check_village_trees.luau must say VILLAGE TREES OK. Models keep their old names for the small plants (FlowerPatch,
-- GrassTuft, Fern, FernCluster, WildflowersGrass): the upgrade code finds them by name (VillageStages moves them off the paving).
-- Each stands as a Model with its feet at its pivot (WorldPivot, no PrimaryPart), anchored; foliage and flowers do not collide, only a
-- tree's trunk (Box hull); small props cast no shadow. Attribute VillageTrees = true marks them.
local ServerStorage = game:GetService("ServerStorage")

if not LIB or not PLAN then
	error("hand over LIB and PLAN: ... run tools/map/dress_village_trees.luau <id> Edit LIB=tools/map/village_footprints.luau PLAN=tools/map/village_scenery_plan.txt")
end
local holder = Instance.new("ModuleScript")
holder.Name = "VillageFootprintsLib"
holder.Source = LIB
holder.Parent = ServerStorage
local lib = require(holder)
holder:Destroy()

local AssetService = game:GetService("AssetService")
local began = os.clock()
local template = workspace.Map:FindFirstChild("Plot" .. lib.TEMPLATE)
local kit = ServerStorage:FindFirstChild("WildKit")
if not template or not kit then
	error("the template (workspace.Map.Plot" .. lib.TEMPLATE .. ") or ServerStorage.WildKit is missing")
end
local frame = lib.frame
local inverse = frame:Inverse()
local GROUND = lib.GROUND
local rng = Random.new(20261104)

-- ===== what each old kind becomes =====
local WHITE = Color3.fromRGB(255, 255, 255)
local TREE_TINTS = { WHITE, Color3.fromRGB(240, 255, 200), Color3.fromRGB(225, 250, 190) } -- the valley's QT_GREEN
local PINE_TINTS = { WHITE, Color3.fromRGB(210, 235, 225) } -- QT_PINE
local TUFT_TINTS = { Color3.fromRGB(240, 255, 200), Color3.fromRGB(225, 250, 190) } -- TUFT_GREEN
local PLANT_TINTS = { WHITE, Color3.fromRGB(240, 255, 200) }

-- old name -> role, and how the new piece is drawn: { kit names }, size (height, or width when wide), tints
local OLD = {
	TallPineLarge = "pine",
	TallPineDense = "pine",
	TallPineSlender = "pine",
	TallPineSparse = "pine",
	BroadleafTree = "round",
	BanyanTree = "round",
	OakTree = "oak",
	BerryBush = "bush",
	Bush = "bush",
	PineBerryBush = "bush",
	FloweringBush = "flowerbush",
	FlowerShrub = "flowerbush",
	FlowerPatch = "patch",
	GrassTuft = "tuft",
	Fern = "fern",
	FernCluster = "plant",
	WildflowersGrass = "meadow",
}
local ROLE_CLASS = {
	pine = "tree",
	round = "tree",
	oak = "tree",
	bush = "bush",
	flowerbush = "bush",
	patch = "small",
	tuft = "small",
	fern = "small",
	plant = "small",
	meadow = "small",
}
local CONTAINERS = {
	S = function()
		return template:FindFirstChild("FenceSkirt")
	end,
	V = function()
		return template.Village:FindFirstChild("Nature")
	end,
	Fis = function()
		return template.FishingPondL1:FindFirstChild("Nature")
	end,
	Gar = function()
		return template.GardenL1:FindFirstChild("Nature")
	end,
	Bre = function()
		return template.BreedingL1:FindFirstChild("Nature")
	end,
	Kit = function()
		return template.KitchenL1:FindFirstChild("Nature")
	end,
	Pan = function()
		return template.PantryL1:FindFirstChild("Nature")
	end,
	Tra = function()
		return template.TrainingL1:FindFirstChild("Nature")
	end,
}

-- ===== the plan =====
type Entry = { container: string, name: string, role: string, x: number, z: number, w: number, h: number }
local entries: { Entry } = {}
for line in string.gmatch(PLAN, "[^\r\n]+") do
	if string.sub(line, 1, 1) ~= "#" then
		local c, name, x, z, w, h = string.match(line, "^(%w+),(%w+),(-?[%d%.]+),(-?[%d%.]+),([%d%.]+),([%d%.]+)$")
		if c and OLD[name] then
			table.insert(entries, { container = c, name = name, role = OLD[name], x = tonumber(x) :: number, z = tonumber(z) :: number, w = tonumber(w) :: number, h = tonumber(h) :: number })
		else
			error("bad line in the plan: " .. line)
		end
	end
end

-- ===== clear: what an earlier run made, and any old piece left =====
local removed = 0
for _, folder in lib.sceneryFolders(template) do
	for _, item in folder:GetChildren() do
		if item:GetAttribute("VillageTrees") ~= nil or lib.isOld(item) then
			item:Destroy()
			removed += 1
		end
	end
end

-- ===== footprints of every upgrade, every level =====
local grid, info = lib.gather({ template = template })
print("[dress] footprints:", info.cells, "cells from", info.builds, "stage builds in", string.format("%.1f s", os.clock() - began))

-- ===== placing =====
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local floor = template:FindFirstChild("StudLawn")
params.FilterDescendantsInstances = if floor then { workspace.Terrain, floor } else { workspace.Terrain }
local function groundAt(x: number, z: number): number
	local w = frame:PointToWorldSpace(Vector3.new(x, 0, z))
	local hit = workspace:Raycast(Vector3.new(w.X, 80, w.Z), Vector3.new(0, -160, 0), params)
	return if hit then hit.Position.Y else GROUND
end

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

local function setTint(part: BasePart, tint: Color3)
	local sa = part:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		sa.Color = tint
	else
		part.Color = tint
	end
end

-- A kit model scaled to `size` (its height, or its width when `wide`), its feet at the origin, bare parts in a new Model.
local function make(name: string, size: number, wide: boolean, tint: Color3?): Model
	local src = kit:FindFirstChild(name)
	if not src then
		error("WildKit has no " .. name)
	end
	local model = src:Clone() :: Model
	model.PrimaryPart = nil
	model.WorldPivot = CFrame.new()
	local _, raw = model:GetBoundingBox()
	local ref = if wide then math.max(raw.X, raw.Z) else raw.Y
	model:ScaleTo(model:GetScale() * size / math.max(ref, 0.01))
	local box, scaled = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(box.Position - Vector3.new(0, scaled.Y / 2, 0))
	model:PivotTo(CFrame.new())
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = false
			d.CanCollide = false
			d.CastShadow = false
			local lower = string.lower(d.Name)
			if string.find(lower, "bark") then
				-- a tree's trunk is the only solid part: its hull (Box) keeps slimes and players from walking through it
				d.CanCollide = true
				d.CanQuery = true
				d.CollisionFidelity = Enum.CollisionFidelity.Box
			elseif tint then
				setTint(d, tint)
			end
		end
	end
	return model
end

-- The pieces of an old kind: { kit, size, wide, tints, offset x, z } each.
local function recipe(role: string, e: Entry, scale: number)
	if role == "pine" then
		local height = math.clamp(e.h * 0.96, 18, 28)
		return { { pick({ "QtPine_1", "QtPine_5" }), height, false, pick(PINE_TINTS) } }
	elseif role == "round" then
		local height = math.clamp(e.h * 1.0, 20, 26)
		return { { pick({ "QtCommonTree_1", "QtCommonTree_3", "QtCommonTree_5" }), height, false, pick(TREE_TINTS) } }
	elseif role == "oak" then
		return { { pick({ "QtCommonTree_5", "QtCommonTree_1" }), rng:NextNumber(12, 15), false, pick(TREE_TINTS) } }
	elseif role == "bush" then
		return { { "QtBush_Common_Green", math.clamp(e.w * 0.95, 4.6, 6.6), true, nil } }
	elseif role == "flowerbush" then
		return { { "QtBush_Common_Flowers", math.clamp(e.w * 1.05, 4.6, 6.4), true, nil } }
	elseif role == "patch" then
		local across = math.clamp(e.w, 3.2, 9.6)
		-- (a patch that finds no room as it is comes again with one group)
		local count = if scale < 1 then 1 elseif across > 6.5 then 3 elseif across > 4.2 then 2 else 1
		local out = {}
		for k = 1, count do
			local offset = (k - (count + 1) / 2) * 2.4
			table.insert(out, { pick({ "QtFlower_3_Group", "QtFlower_4_Group" }), rng:NextNumber(2.8, 3.8), true, nil, offset, rng:NextNumber(-0.5, 0.5) })
		end
		return out
	elseif role == "tuft" then
		return { { pick({ "QtGrass_Common_Short", "QtGrass_Common_Tall", "QtGrass_Common_Tall" }), rng:NextNumber(3, 4.2), false, pick(TUFT_TINTS) } }
	elseif role == "fern" then
		return { { "QtFern_1", math.clamp(e.w * 1.5, 3.8, 6), true, pick(PLANT_TINTS) } }
	elseif role == "plant" then
		return { { pick({ "QtPlant_1_Big", "QtFern_1" }), rng:NextNumber(4, 5.4), true, pick(PLANT_TINTS) } }
	end
	-- meadow: a flower group with a grass tuft beside it
	local group = { pick({ "QtFlower_3_Group", "QtFlower_4_Group" }), rng:NextNumber(2.8, 3.6), true, nil, -0.9, 0 }
	if scale < 1 then
		return { group }
	end
	return { group, { "QtGrass_Common_Short", rng:NextNumber(2.6, 3.4), false, pick(TUFT_TINTS), 1.0, 0.4 } }
end

-- A finished piece at the origin: a Model of the recipe's parts and its occupancy.
local function build(role: string, e: Entry, scale: number)
	local parts = recipe(role, e, scale)
	local item = Instance.new("Model")
	-- (a small plant keeps its old name: the upgrade code finds those by name; trees and bushes carry the kit model's)
	item.Name = if ROLE_CLASS[role] == "small" then e.name else parts[1][1]
	for _, p in parts do
		local model = make(p[1], p[2] * scale, p[3], p[4])
		local yaw = rng:NextNumber(0, math.pi * 2)
		model:PivotTo(CFrame.new(p[5] or 0, 0, p[6] or 0) * CFrame.Angles(0, yaw, 0))
		for _, d in model:GetChildren() do
			d.Parent = item
		end
		model:Destroy()
	end
	item.WorldPivot = CFrame.new()
	item:SetAttribute("VillageTrees", true)
	item:SetAttribute("Role", ROLE_CLASS[role])
	item:SetAttribute("Kit", parts[1][1])
	return item, lib.profile(item), parts
end

local placed: { { x: number, z: number, r: number, class: string } } = {}
local counts = { placed = 0, moved = 0, dropped = 0, shrunk = 0 }
local byRole: { [string]: number } = {}
local droppedList: { string } = {}
local triangles = 0
local tricache: { [string]: number } = {}
local function trisOf(part: MeshPart): number
	local id = part.MeshId
	if tricache[id] == nil then
		local ok, mesh = pcall(function()
			return AssetService:CreateEditableMeshAsync(part.MeshContent)
		end)
		tricache[id] = if ok and mesh then #mesh:GetFaces() else 0
		if ok and mesh then
			mesh:Destroy()
		end
	end
	return tricache[id]
end

-- where the old one stood, and rings outward: the first spot that clashes with no upgrade piece and no piece already placed
local TRUNK = 1.8 -- a bush or flower may stand under a crown but never against a trunk
local function spaced(class: string, radius: number, x: number, z: number): boolean
	for _, o in placed do
		local d = math.sqrt((o.x - x) ^ 2 + (o.z - z) ^ 2)
		local need
		if class == "tree" and o.class == "tree" then
			need = (radius + o.r) * 0.55 + 2
		elseif class == "tree" or o.class == "tree" then
			need = TRUNK + (if class == "tree" then o.r else radius) * 0.8
		elseif class == "bush" and o.class == "bush" then
			need = (radius + o.r) * 0.85
		else
			need = (radius + o.r) * 0.7
		end
		if d < need then
			return false
		end
	end
	return true
end

local REACH = { tree = 30, bush = 16, small = 12 }
-- the pond's scenery goes where PondStages.grow clears it (its water, the shore life, the parts built at the shore)
local Layout = require(game:GetService("ReplicatedStorage").Shared.Layout)
local PondStages = require(game:GetService("ServerScriptService").Server.PondStages)
local pondFrame = Layout.plotAreaFacing(lib.TEMPLATE, -1, 1)
local function pondClears(x: number, z: number): boolean
	local q = pondFrame:PointToObjectSpace(frame:PointToWorldSpace(Vector3.new(x, 0, z)))
	return PondStages.clears(q.X, q.Z, 50)
end
local function inZone(skirt: boolean, x: number, z: number, radius: number): boolean
	local edge = math.max(math.abs(x), math.abs(z))
	if skirt then
		return edge - radius >= 114.6 and edge + radius <= 128
	end
	return edge + radius <= 113.4
end

local function dress(e: Entry, index: number)
	local role = e.role
	local class = ROLE_CLASS[role]
	local folder = CONTAINERS[e.container]()
	if not folder then
		return
	end
	local skirt = e.container == "S"
	for _, scale in { 1, 0.85, 0.7 } do
		local item, profile, parts = build(role, e, scale)
		local radius = profile.radius
		local footprint = if class == "tree" then math.min(radius, 8) else radius
		local found: Vector3? = nil
		local step = if class == "tree" then 1.6 else 1.0
		local phase = rng:NextNumber(0, math.pi * 2)
		local ring = 0
		while not found and ring * step <= REACH[class] do
			local count = if ring == 0 then 1 else math.max(8, ring * 6)
			for k = 0, count - 1 do
				local a = phase + k * math.pi * 2 / count
				local x, z = e.x + math.cos(a) * ring * step, e.z + math.sin(a) * ring * step
				if
					inZone(skirt, x, z, if class == "tree" then 1.5 else radius * 0.7)
					and not (e.container == "Fis" and pondClears(x, z))
					and spaced(class, footprint, x, z)
					and not lib.clash(grid, profile, class, x, z)
				then
					found = Vector3.new(x, 0, z)
					break
				end
			end
			ring += 1
		end
		if found then
			local gy = groundAt(found.X, found.Z)
			local sink = if class == "tree" then 0.25 else 0.15
			item:PivotTo(frame * CFrame.new(found.X, 0, found.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
			item:PivotTo(item:GetPivot() + Vector3.new(0, gy - sink - item:GetPivot().Position.Y, 0))
			-- a tree's trunk is the only part that casts a real shadow of any weight; crowns do (the valley's trees do), small props never
			for _, d in item:GetDescendants() do
				if d:IsA("BasePart") then
					d.CastShadow = class == "tree"
					if d:IsA("MeshPart") then
						triangles += trisOf(d)
					end
				end
			end
			item.Parent = folder
			table.insert(placed, { x = found.X, z = found.Z, r = footprint, class = class })
			counts.placed += 1
			byRole[role] = (byRole[role] or 0) + 1
			if (Vector3.new(found.X, 0, found.Z) - Vector3.new(e.x, 0, e.z)).Magnitude > 0.6 then
				counts.moved += 1
			end
			if scale < 1 then
				counts.shrunk += 1
			end
			return
		end
		item:Destroy()
	end
	counts.dropped += 1
	table.insert(droppedList, string.format("%s %s (%.0f, %.0f)", e.container, e.name, e.x, e.z))
end

-- trees first (they need the room most), then bushes, then the small plants
for _, class in { "tree", "bush", "small" } do
	if class == "small" then
		-- The village layer slides its props round whatever trees and bushes stand, so it lies a little differently once they do:
		-- run it again with them in place and keep the small plants off that (VillageStages takes a flower from under a piece).
		lib.runVillage(template, grid, info, "footprints")
		print("[dress] the village layer with the trees and bushes in place:", grid.count, "cells in", string.format("%.1f s", os.clock() - began))
	end
	for i, e in entries do
		if ROLE_CLASS[e.role] == class then
			dress(e, i)
			if i % 12 == 0 then
				task.wait()
			end
		end
	end
	task.wait()
end

local lines = {}
table.insert(lines, string.format("removed %d old/earlier pieces; planned %d", removed, #entries))
local roles = {}
for role, n in byRole do
	table.insert(roles, role .. " " .. n)
end
table.sort(roles)
table.insert(lines, string.format("placed %d (%s), moved from the old spot %d, shrunk %d, dropped %d", counts.placed, table.concat(roles, ", "), counts.moved, counts.shrunk, counts.dropped))
if #droppedList > 0 then
	table.insert(lines, "dropped (no free spot within reach): " .. table.concat(droppedList, "; "))
end
table.insert(lines, string.format("triangles of the new pieces: %d (%.0f s)", triangles, os.clock() - began))
return table.concat(lines, "\n")
