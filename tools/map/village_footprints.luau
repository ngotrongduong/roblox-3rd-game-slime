-- Library for tools/map/check_village_trees.luau and tools/map/dress_village_trees.luau (the owner, 2026-11-02: the village's trees and
-- small bushes use the valley's assets, and none of them may stand where a village upgrade puts something, at any level).
-- It is not run by itself: the two tools get its text as the string LIB (`... run <tool> <id> Edit LIB=tools/map/village_footprints.luau`)
-- and turn it into a ModuleScript they require, so there is one copy of the rules.
--
-- What it knows:
--   * a ground grid of the template plot in the plot's own frame (x across, z from the gate in, 1-stud cells, 264 x 264) in which every
--     piece that stands or may ever stand puts its footprint with the heights it fills (above the ground, GroundY);
--   * what goes in: the plot's own parts (areas, paving, fence, gate: everything not scenery), the scenery that stays (stumps, rocks,
--     sunflowers, benches), every piece of every level of every area (the stage modules are run, level 1 to 50, on a clone of the
--     template, as AreaUpgrade runs them: PondStages, GardenStages, PantryStages, KitchenStages, BreedingStages, TrainingStages and
--     VillageStages for the fence, gate, plaza, paths, lamps, benches, stalls...), the water of the pond (its grown lobes too), the
--     pads and entrances with the slimes' working room in front of them, and the invisible markers the stages leave (work spots, nests);
--   * what a tree, a bush or a flower is for the checks: its occupancy in 1.5-stud height bands read from the mesh's real vertices.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AssetService = game:GetService("AssetService")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local M = {}

M.TEMPLATE = Config.Plots.TemplatePlot
M.GROUND = Config.Map.GroundY
M.HALF = 132 -- cells each way from the plot's middle (the skirt outside the fence reaches 123)
M.BAND = 1.5 -- height bands of a plant's occupancy
M.LOW = 3.6 -- a band that starts under this is in a slime's way (3 tall) and a player's
M.CLEAR_ABOVE = 1.5 -- a crown or roof must clear the head of what stands below by this
M.LEVELS = 50
M.frame = Layout.plotFrame(M.TEMPLATE)
local inverse = M.frame:Inverse()
local HALF, SIZE, GROUND = M.HALF, M.HALF * 2, M.GROUND

-- bits of a cell's kinds
local SOLID, FENCE, LANE, WATER, SPOT = 1, 2, 4, 8, 16
M.Kind = { solid = SOLID, fence = FENCE, lane = LANE, water = WATER, spot = SPOT }

-- room kept free round what stands (studs, from the plant's own edge): a trunk (and a pine's low skirt, a bush) against each kind
-- of footprint. Fences may be leant on by low plants, lanes (paving) keep a slime's step, water a dry shore.
local MARGIN = {
	tree = { [SOLID] = 1.2, [FENCE] = 1.6, [LANE] = 2.6, [WATER] = 2.0, [SPOT] = 1.2 },
	bush = { [SOLID] = 1.0, [FENCE] = 0.0, [LANE] = 1.0, [WATER] = 1.2, [SPOT] = 0.6 },
	-- (a small plant on the paving is taken away or moved by VillageStages: it looks 1.1 studs round its middle, over 2-stud blocks)
	small = { [SOLID] = 0.3, [FENCE] = 0.0, [LANE] = 1.3, [WATER] = 0.6, [SPOT] = 0.0 },
}
-- a crown (bands above LOW) may not touch anything tall beside it by this
local CROWN_MARGIN = 0.4

-- ===== names =====
local TREES = { "^Qt%a*Tree", "^QtPine", "^TallPine", "^BroadleafTree$", "^BanyanTree$", "^OakTree$" }
local BUSHES = { "^QtBush", "^BerryBush$", "^FloweringBush$", "^Bush$", "^FlowerShrub$", "^PineBerryBush$" }
local SMALL = {
	"^FlowerPatch$",
	"^GrassTuft$",
	"^Fern$",
	"^FernCluster$",
	"^WildflowersGrass$",
	"^QtFlower",
	"^QtGrass",
	"^QtFern",
	"^QtPlant",
	"^QtClover",
}
-- the kit's old (replaced) names
local OLD = {
	"^TallPine",
	"^BroadleafTree$",
	"^BanyanTree$",
	"^OakTree$",
	"^BerryBush$",
	"^FloweringBush$",
	"^Bush$",
	"^FlowerShrub$",
	"^PineBerryBush$",
	"^FlowerPatch$",
	"^GrassTuft$",
	"^Fern$",
	"^FernCluster$",
	"^WildflowersGrass$",
}
local function matches(name: string, list: { string }): boolean
	for _, p in list do
		if string.find(name, p) then
			return true
		end
	end
	return false
end
-- "tree", "bush", "small" or nil: what a scenery model is for the rules
function M.classify(inst: Instance): string?
	local role = inst:GetAttribute("Role")
	if role == "tree" or role == "bush" or role == "small" then
		return role
	end
	local name = inst.Name
	if matches(name, TREES) then
		return "tree"
	elseif matches(name, BUSHES) then
		return "bush"
	elseif matches(name, SMALL) then
		return "small"
	end
	return nil
end
function M.isOld(inst: Instance): boolean
	return matches(inst.Name, OLD) and inst:GetAttribute("VillageTrees") == nil
end

-- the scenery of the template: every child of a Nature folder (a plot area's, the village's) and of FenceSkirt
function M.sceneryFolders(template: Instance): { Instance }
	local out = {}
	for _, d in template:GetDescendants() do
		if d:IsA("Folder") and (d.Name == "Nature" or d.Name == "FenceSkirt") then
			table.insert(out, d)
		end
	end
	return out
end

-- ===== the grid =====
function M.newGrid()
	local n = SIZE * SIZE
	return {
		hi = table.create(n, -1e9),
		lo = table.create(n, 1e9),
		label = table.create(n, ""),
		kinds = table.create(n, 0),
		count = 0,
	}
end
local function index(ix: number, iz: number): number
	return (ix + HALF) * SIZE + (iz + HALF) + 1
end
function M.inGrid(ix: number, iz: number): boolean
	return ix >= -HALF and ix < HALF and iz >= -HALF and iz < HALF
end
function M.cell(grid, x: number, z: number)
	local ix, iz = math.floor(x), math.floor(z)
	if not M.inGrid(ix, iz) then
		return nil
	end
	local i = index(ix, iz)
	return grid.hi[i], grid.lo[i], grid.label[i], grid.kinds[i]
end

local function put(grid, ix: number, iz: number, lo: number, hi: number, label: string, kind: number)
	if ix < -HALF or ix >= HALF or iz < -HALF or iz >= SIZE - HALF then
		return
	end
	local i = index(ix, iz)
	if grid.hi[i] < -1e8 then
		grid.count += 1
	end
	if hi > grid.hi[i] then
		grid.hi[i] = hi
		grid.label[i] = label
	end
	if lo < grid.lo[i] then
		grid.lo[i] = lo
	end
	grid.kinds[i] = bit32.bor(grid.kinds[i], kind)
end

local INFLATE = 0.5 -- a cell counts when its middle is within this of the footprint, so thin rails are not missed

-- footprint polygon (counter-clockwise points {x, z}) filled into the grid
local function fill(grid, poly, lo: number, hi: number, label: string, kind: number)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, p in poly do
		minX, maxX = math.min(minX, p[1]), math.max(maxX, p[1])
		minZ, maxZ = math.min(minZ, p[2]), math.max(maxZ, p[2])
	end
	local n = #poly
	-- (the points may come in either turn: the sign of the area says which side is inside)
	local area = 0
	for k = 1, n do
		local a, b = poly[k], poly[k % n + 1]
		area += a[1] * b[2] - b[1] * a[2]
	end
	local side = if area < 0 then -1 else 1
	for ix = math.floor(minX - INFLATE), math.ceil(maxX + INFLATE) do
		for iz = math.floor(minZ - INFLATE), math.ceil(maxZ + INFLATE) do
			local cx, cz = ix + 0.5, iz + 0.5
			local inside = true
			if n >= 3 then
				for k = 1, n do
					local a, b = poly[k], poly[k % n + 1]
					local ex, ez = b[1] - a[1], b[2] - a[2]
					local len = math.sqrt(ex * ex + ez * ez)
					if len > 1e-6 and side * (ex * (cz - a[2]) - ez * (cx - a[1])) / len < -INFLATE then
						inside = false
						break
					end
				end
			else
				inside = cx >= minX - INFLATE and cx <= maxX + INFLATE and cz >= minZ - INFLATE and cz <= maxZ + INFLATE
			end
			if inside then
				put(grid, ix, iz, lo, hi, label, kind)
			end
		end
	end
end

local function hull(points)
	table.sort(points, function(a, b)
		return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
	end)
	local function cross(o, a, b)
		return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1])
	end
	local lower, upper = {}, {}
	for _, p in points do
		while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], p) <= 0 do
			table.remove(lower)
		end
		table.insert(lower, p)
	end
	for i = #points, 1, -1 do
		local p = points[i]
		while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], p) <= 0 do
			table.remove(upper)
		end
		table.insert(upper, p)
	end
	table.remove(lower)
	table.remove(upper)
	for _, p in upper do
		table.insert(lower, p)
	end
	return lower
end

-- a box (cf in the plot's frame, heights measured from y = 0 of that frame) as a footprint
function M.addBox(grid, cf: CFrame, size: Vector3, label: string, kind: number)
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local lo, hi = math.huge, -math.huge
	local up = cf.UpVector
	if math.abs(up.Y) > 0.9999 then
		local c, r, l = cf.Position, cf.RightVector, cf.LookVector
		lo, hi = c.Y - hy, c.Y + hy
		local rx, rz, lx, lz = r.X * hx, r.Z * hx, l.X * hz, l.Z * hz
		fill(grid, {
			{ c.X - rx - lx, c.Z - rz - lz },
			{ c.X + rx - lx, c.Z + rz - lz },
			{ c.X + rx + lx, c.Z + rz + lz },
			{ c.X - rx + lx, c.Z - rz + lz },
		}, lo - GROUND, hi - GROUND, label, kind)
		return
	end
	local points = {}
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local p = cf:PointToWorldSpace(Vector3.new(sx * hx, sy * hy, sz * hz))
				lo, hi = math.min(lo, p.Y), math.max(hi, p.Y)
				table.insert(points, { p.X, p.Z })
			end
		end
	end
	fill(grid, hull(points), lo - GROUND, hi - GROUND, label, kind)
end

function M.addDisc(grid, cx: number, cz: number, radius: number, lo: number, hi: number, label: string, kind: number)
	for ix = math.floor(cx - radius - 1), math.ceil(cx + radius + 1) do
		for iz = math.floor(cz - radius - 1), math.ceil(cz + radius + 1) do
			local dx, dz = ix + 0.5 - cx, iz + 0.5 - cz
			if dx * dx + dz * dz <= radius * radius then
				put(grid, ix, iz, lo, hi, label, kind)
			end
		end
	end
end

local LANE_NAMES = { "Paving", "PlazaTile", "Path", "Walk", "Road", "Lane" }
local function laneName(name: string): boolean
	for _, n in LANE_NAMES do
		if string.find(name, n, 1, true) then
			return true
		end
	end
	return false
end

-- a world part into the grid. Invisible parts that do not collide are markers: a working room round them instead.
function M.addPart(grid, part: BasePart, label: string, forceKind: number?)
	if part.Transparency >= 1 and not part.CanCollide then
		local s = part.Size
		local side = math.clamp(math.max(s.X, s.Z), 3, 6)
		local cf = inverse * part.CFrame
		M.addBox(grid, CFrame.new(cf.Position.X, 0.15 + GROUND, cf.Position.Z), Vector3.new(side, 0.3, side), label .. "(marker)", SPOT)
		return
	end
	local s = part.Size
	if math.max(s.X, s.Y, s.Z) < 0.25 then
		return
	end
	local kind = forceKind or (if laneName(part.Name) then LANE else SOLID)
	if not forceKind and string.find(part.Name, "Fence", 1, true) then
		kind = FENCE
	end
	M.addBox(grid, inverse * part.CFrame, s, label, kind)
end

local FENCE_NAMES = { "Fence", "Picket", "Rail", "Ivy" }
local function fenceName(name: string): boolean
	for _, n in FENCE_NAMES do
		if string.find(name, n, 1, true) then
			return true
		end
	end
	return false
end

-- Every part under root (a built stage layer). kindOf(part) may name a kind (the village layer's wall pieces stand out at the fence:
-- a low plant may lean on them as on a fence).
function M.addInstance(grid, root: Instance, label: string, forceKind: number?, kindOf: ((BasePart) -> number?)?)
	local function one(d: BasePart)
		-- (a part keeps its model's name in the label: the nearest named ancestor under root)
		local top: Instance = d
		while top.Parent and top.Parent ~= root do
			top = top.Parent
		end
		local kind = forceKind
		if not kind and kindOf then
			kind = kindOf(d)
		end
		if not kind and (fenceName(top.Name) or fenceName(d.Name) or fenceName(d.Parent and d.Parent.Name or "")) then
			kind = FENCE
		end
		M.addPart(grid, d, label .. "/" .. top.Name .. "/" .. d.Name, kind)
	end
	if root:IsA("BasePart") then
		one(root)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			one(d)
		end
	end
end

-- ===== the clone the stages run on =====
local function removeReplaceable(clone: Instance)
	for _, folder in M.sceneryFolders(clone) do
		for _, item in folder:GetChildren() do
			if M.classify(item) then
				item:Destroy()
			end
		end
	end
end

-- Static footprints of the template: every part that is not scenery to be replaced and not the stud floor.
function M.addStatic(grid, template: Instance)
	local function walk(inst: Instance, path: string)
		for _, c in inst:GetChildren() do
			if c.Name == "StudLawn" then
				continue
			end
			if (inst.Name == "Nature" or inst.Name == "FenceSkirt") and M.classify(c) then
				continue
			end
			if c:IsA("BasePart") then
				M.addPart(grid, c, path .. "/" .. c.Name, if string.find(path, "Fence", 1, true) then FENCE else nil)
			else
				walk(c, path .. "/" .. c.Name)
			end
		end
	end
	walk(template, "plot")
end

-- The areas: template model, column, row, the stage module (nil: the pond), the id of Config.Pads.Spots, where the entrance is.
local AREAS = {
	{ model = "FishingPondL1", col = -1, row = 1, module = nil, id = "fishing", entrance = { -3, -20 } },
	{ model = "GardenL1", col = 1, row = 1, module = "GardenStages", id = "garden" },
	{ model = "PantryL1", col = 0, row = 1, module = "PantryStages", id = "pantry" },
	{ model = "KitchenL1", col = -1, row = 0, module = "KitchenStages", id = "kitchen" },
	{ model = "BreedingL1", col = 1, row = 0, module = "BreedingStages", id = "breeding" },
	{ model = "TrainingL1", col = -1, row = -1, module = "TrainingStages", id = "training" },
}
M.AREAS = AREAS

local function stageModule(name: string)
	return require(ServerScriptService.Server:FindFirstChild(name))
end

local function removedScan(tracked, area: string, level: number, found, seen)
	for _, t in tracked do
		if not seen[t.inst] then
			if t.inst.Parent == nil then
				seen[t.inst] = true
				table.insert(found, { name = t.inst.Name, role = t.role, x = t.x, z = t.z, by = area, level = level, what = "removed" })
			else
				local q = inverse * t.inst:GetPivot()
				if (Vector3.new(q.Position.X, 0, q.Position.Z) - Vector3.new(t.x, 0, t.z)).Magnitude > 0.5 then
					seen[t.inst] = true
					table.insert(found, { name = t.inst.Name, role = t.role, x = t.x, z = t.z, by = area, level = level, what = "moved" })
				end
			end
		end
	end
end

local function track(clone: Instance)
	local tracked = {}
	for _, folder in M.sceneryFolders(clone) do
		for _, item in folder:GetChildren() do
			local role = M.classify(item)
			if role and item:IsA("Model") then
				local q = inverse * item:GetPivot()
				table.insert(tracked, { inst = item, role = role, x = q.Position.X, z = q.Position.Z })
			end
		end
	end
	return tracked
end

-- Everything: the grid and what the stages did to the scenery (removed / moved by an upgrade) and to the village layer.
-- opts.template: the template plot; opts.progress: a function(text) called as it goes.
function M.gather(opts)
	local template = opts.template :: Instance
	local say = opts.progress or function() end
	local grid = M.newGrid()
	local info = { removed = {}, skippedIdeal = {}, skippedReal = {}, markers = 0, parts = 0, builds = 0 }

	-- every stage module loaded first, the pantry's before the pond's: it hands the pond its kit placer (the shore's benches and racks)
	for _, name in { "PantryStages", "PondStages", "GardenStages", "KitchenStages", "BreedingStages", "TrainingStages", "VillageStages" } do
		stageModule(name)
	end
	M.addStatic(grid, template)
	say("static plot parts")

	-- the stages of the six areas, level 1 to 50, on a clone with the scenery in place (so what they remove is seen)
	for _, a in AREAS do
		local clone = template:Clone()
		local areaModel = clone:FindFirstChild(a.model)
		local frame = Layout.plotAreaFacing(M.TEMPLATE, a.col, a.row) * CFrame.new(0, GROUND, 0)
		local tracked = track(clone)
		local seen = {}
		local mod = if a.module then stageModule(a.module) else stageModule("PondStages")
		for level = 1, M.LEVELS do
			local layer: Instance
			if a.module then
				layer = mod.build(areaModel, frame, level)
			else
				layer = mod.build(level, frame * CFrame.new(-3, 0, 0))
			end
			M.addInstance(grid, layer, string.format("%s L%d", a.id, level))
			info.builds += 1
			layer:Destroy()
			removedScan(tracked, a.id, level, info.removed, seen)
			if level % 5 == 0 then
				task.wait()
			end
		end
		clone:Destroy()
		-- the pad and the entrance, each with the slimes' working room
		local pad = Config.Pads.Spots[a.id]
		local function room(x: number, z: number, side: number, name: string)
			local cf = inverse * (Layout.plotAreaFacing(M.TEMPLATE, a.col, a.row) * CFrame.new(x, 0, z))
			M.addBox(grid, CFrame.new(cf.Position.X, GROUND + 0.15, cf.Position.Z), Vector3.new(side, 0.3, side), a.id .. " " .. name, SPOT)
		end
		room(pad[1], pad[2], 7, "pad")
		local entrance = a.entrance or require(ServerScriptService.Server.AreaStages).Specs[a.model].prompt
		room(entrance[1], entrance[2], 7, "entrance")
		-- the pond's water, the level-1 lobes and the grown ones (terrain: the stud floor is cut away over it)
		if not a.module then
			local P = stageModule("PondStages")
			for _, lobe in P.Lobes do
				local p = inverse * (Layout.plotAreaFacing(M.TEMPLATE, a.col, a.row) * CFrame.new(lobe[1], 0, lobe[2]))
				M.addDisc(grid, p.Position.X, p.Position.Z, lobe[3] + 1.5, -6, 0.4, "pond water", WATER)
			end
			for _, lobe in P.Grow do
				local p = inverse * (Layout.plotAreaFacing(M.TEMPLATE, a.col, a.row) * CFrame.new(lobe[1], 0, lobe[2]))
				M.addDisc(grid, p.Position.X, p.Position.Z, lobe[3] + 1.5, -6, 0.4, "pond water L" .. lobe[4], WATER)
			end
		end
		say("area " .. a.id)
	end

	-- the village layer: the ideal (nothing of the replaceable scenery stands in its way) and the real one
	M.runVillage(template, grid, info, "ideal")
	say("village (ideal)")
	M.runVillage(template, grid, info, "real")
	say("village (with the scenery)")
	-- the market street (from village level 4): the village moves small plants out of it
	local V = stageModule("VillageStages")
	for ix = -HALF, HALF - 1 do
		for iz = -HALF, HALF - 1 do
			if math.abs(ix) < 112 and math.abs(iz) < 112 and V.InMarket(Vector3.new(ix + 0.5, 0, iz + 0.5)) then
				put(grid, ix, iz, 0, 0.3, "market street (village level 4)", SPOT)
			end
		end
	end
	info.cells = grid.count
	return grid, info
end

-- The village layer's 50 levels on a clone of the template, the six areas standing at the same level. mode: "ideal" (the replaceable
-- scenery taken away first; every part goes into the grid), "real" (the scenery in place: what the layer removes or moves of it,
-- and the pieces it finds no room for, go into info), "footprints" (the scenery in place, and every part goes into the grid too: the
-- layer as it really lies once the trees and bushes stand, for the small plants to keep clear of).
function M.runVillage(template: Instance, grid, info, mode: string)
	local V = stageModule("VillageStages")
	local vframe = M.frame * CFrame.new(0, GROUND, 0)
	local ideal = mode == "ideal"
	local addToGrid = mode ~= "real"
	do
		local clone = template:Clone()
		if ideal then
			removeReplaceable(clone)
		end
		local village = clone:FindFirstChild("Village")
		local tracked = if mode == "real" then track(clone) else {}
		local seen = {}
		local standing: { [string]: Instance } = {}
		for level = 1, V.MaxLevel do
			-- the six areas stand at this level too, as in a village whose areas are all at the same level (their bigger boxes
			-- push the village's props about: VillageStages looks at them)
			for _, a in AREAS do
				local areaModel = clone:FindFirstChild(a.model)
				local aframe = Layout.plotAreaFacing(M.TEMPLATE, a.col, a.row) * CFrame.new(0, GROUND, 0)
				local layer2: Instance
				if a.module then
					layer2 = stageModule(a.module).build(areaModel, aframe, level)
				else
					layer2 = stageModule("PondStages").build(level, aframe * CFrame.new(-3, 0, 0))
				end
				layer2.Parent = areaModel
				if standing[a.id] then
					standing[a.id]:Destroy()
				end
				standing[a.id] = layer2
			end
			if mode == "real" then
				removedScan(tracked, "areas", level, {}, seen)
			end
			local layer = V.build(village, vframe, level)
			if mode == "real" then
				removedScan(tracked, "village", level, info.removed, seen)
			end
			if addToGrid then
				-- (the walls, gates, towers, ivy and balustrades at the fence line are fence for a plant that leans on them)
				M.addInstance(grid, layer, "village L" .. level, nil, function(p: BasePart): number?
					local q = inverse * p.CFrame
					if math.max(math.abs(q.Position.X), math.abs(q.Position.Z)) > 108 then
						return FENCE
					end
					return nil
				end)
				-- (VillageStages takes a small plant from under a placed model by a circle round it, not by its parts)
				for _, c in layer:GetChildren() do
					local cf, size = nil, nil
					if c:IsA("Model") then
						cf, size = c:GetBoundingBox()
					end
					if cf and size and size.X < 24 and size.Z < 24 then
						local q = inverse * cf
						M.addDisc(grid, q.Position.X, q.Position.Z, math.max(size.X, size.Z) / 2 + 0.6, 0, 0.3, string.format("village L%d/%s room", level, c.Name), SPOT)
					end
				end
				info.builds += 1
			end
			local skipped = layer:GetAttribute("Skipped")
			local target = if ideal then info.skippedIdeal else info.skippedReal
			if type(skipped) == "string" and skipped ~= "" and mode ~= "footprints" then
				target[level] = skipped
			end
			layer:Destroy()
			if level % 5 == 0 then
				task.wait()
			end
		end
		clone:Destroy()
	end
end

-- ===== a plant's occupancy =====
local meshCache = {}
local function meshPoints(part: MeshPart)
	local id = part.MeshId
	local cached = meshCache[id]
	if cached ~= nil then
		return cached or nil
	end
	local ok, mesh = pcall(function()
		return AssetService:CreateEditableMeshAsync(part.MeshContent)
	end)
	if not ok or not mesh then
		meshCache[id] = false
		return nil
	end
	local ids = mesh:GetVertices()
	local points = table.create(#ids)
	local mn = Vector3.new(math.huge, math.huge, math.huge)
	local mx = -mn
	for i, v in ids do
		local p = mesh:GetPosition(v)
		points[i] = p
		mn, mx = mn:Min(p), mx:Max(p)
	end
	mesh:Destroy()
	local centre, extent = (mn + mx) / 2, mx - mn
	local out = table.create(#points)
	for i, p in points do
		local d = p - centre
		out[i] = Vector3.new(
			if extent.X > 1e-6 then d.X / extent.X else 0,
			if extent.Y > 1e-6 then d.Y / extent.Y else 0,
			if extent.Z > 1e-6 then d.Z / extent.Z else 0
		)
	end
	meshCache[id] = out
	return out
end

-- Occupancy of a model standing with its foot at its pivot: bands {h0, h1, R} (R: the farthest a vertex is from the vertical axis
-- through the foot), the total height and the widest radius. Every vertex of the real meshes counts, so a pine's low skirt and a
-- trunk are seen as they are.
function M.profile(model: Instance)
	local foot = (model :: any):GetPivot().Position
	local radii: { [number]: number } = {}
	local top = 0
	local widest = 0
	local function add(w: Vector3)
		local y = w.Y - foot.Y
		local b = math.max(0, math.floor(y / M.BAND))
		local r = math.sqrt((w.X - foot.X) ^ 2 + (w.Z - foot.Z) ^ 2)
		if r > (radii[b] or 0) then
			radii[b] = r
		end
		top = math.max(top, y)
		widest = math.max(widest, r)
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local points = if d:IsA("MeshPart") then meshPoints(d) else nil
			if points then
				local cf, size = d.CFrame, d.Size
				for _, p in points do
					add(cf:PointToWorldSpace(p * size))
				end
			else
				local cf, hs = d.CFrame, d.Size / 2
				for _, sx in { -1, 0, 1 } do
					for _, sy in { -1, 0, 1 } do
						for _, sz in { -1, 0, 1 } do
							add(cf:PointToWorldSpace(Vector3.new(sx * hs.X, sy * hs.Y, sz * hs.Z)))
						end
					end
				end
			end
		end
	end
	local last = math.floor(top / M.BAND)
	-- bands no vertex fell in (a trunk between its foot and its fork): the thinner of the nearest filled ones
	local filled = {}
	for b = 0, last do
		if radii[b] then
			table.insert(filled, b)
		end
	end
	local bands = {}
	for b = 0, last do
		local r = radii[b]
		if not r then
			local below, above = nil, nil
			for _, f in filled do
				if f < b then
					below = f
				elseif f > b and not above then
					above = f
				end
			end
			local a = if below then radii[below] else nil
			local c = if above then radii[above] else nil
			r = if a and c then math.min(a, c) else (a or c or 0)
		end
		table.insert(bands, { b * M.BAND, (b + 1) * M.BAND, r + 0.1 })
	end
	return { bands = bands, height = top, radius = widest }
end

-- Does a plant of this class and profile, with its foot at plot-local (x, z), touch anything? Returns the first clash as text, or nil.
-- Only crown bands (above LOW) may overhang: when they clear the tallest piece in reach by CLEAR_ABOVE.
function M.clash(grid, profile, class: string, x: number, z: number): string?
	local margins = MARGIN[class]
	for _, band in profile.bands do
		local h0, h1, radius = band[1], band[2], band[3]
		local low = h0 < M.LOW
		local reach = radius + (if low then 2.7 else CROWN_MARGIN)
		for ix = math.floor(x - reach), math.floor(x + reach) do
			for iz = math.floor(z - reach), math.floor(z + reach) do
				if M.inGrid(ix, iz) then
					local i = index(ix, iz)
					local hi = grid.hi[i]
					if hi > -1e8 then
						local d = math.sqrt((ix + 0.5 - x) ^ 2 + (iz + 0.5 - z) ^ 2)
						local kinds = grid.kinds[i]
						local m = 0
						if low then
							for k, v in margins do
								if bit32.band(kinds, k) ~= 0 then
									m = math.max(m, v)
								end
							end
						else
							m = CROWN_MARGIN
						end
						if d < radius + m and hi + M.CLEAR_ABOVE > h0 and grid.lo[i] - 0.3 < h1 then
							return string.format(
								"%s at (%d,%d) %.1f studs away, %.1f-%.1f high (plant band %.1f-%.1f, radius %.1f)",
								grid.label[i],
								ix,
								iz,
								d,
								grid.lo[i],
								hi,
								h0,
								h1,
								radius
							)
						end
					end
				end
			end
		end
	end
	return nil
end

return M
