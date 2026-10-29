--!strict
-- No flicker where two surfaces meet at the same height (the owner, 2026-10-29: "where surfaces meet at the
-- same level they flicker; raise or lower one by a hair"). Two visible block parts whose top faces lie within
-- Config.Map.ZFightTolerance of each other and overlap in plan fight for the same pixels. The smaller one of
-- each pair (the detail: a path band on a floor, a cap on a post, a chevron on a pad) is raised by
-- Config.Map.ZFightStep, again if it still meets another, so every layer gets its own height.
--
-- The stage builders put their parts in place; `watch` runs `resolve` on an area each time a stage is built
-- or rebuilt (any level), and tools/map/fix_zfight.luau runs it on the parts saved in the place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local ZFight = {}

type Entry = { part: Part, area: number, minX: number, maxX: number, minZ: number, maxZ: number }

local function flatTop(p: Instance): boolean
	return p:IsA("Part")
		and p.Shape == Enum.PartType.Block
		and p.Transparency < 0.99
		and math.abs(p.CFrame.UpVector.Y) > 0.999
		and p.Size.X > 0.05
		and p.Size.Z > 0.05
end

local function top(p: Part): number
	return p.Position.Y + p.Size.Y / 2
end

local function project(p: Part, axis: Vector3): (number, number)
	local half = p.Size / 2
	local cf = p.CFrame
	local c = p.Position.X * axis.X + p.Position.Z * axis.Z
	local r = math.abs(half.X * (cf.RightVector.X * axis.X + cf.RightVector.Z * axis.Z))
		+ math.abs(half.Z * (cf.LookVector.X * axis.X + cf.LookVector.Z * axis.Z))
	return c - r, c + r
end

-- The two top rectangles overlap by more than a hair (separating axes; touching edges do not flicker).
function ZFight.overlap(a: Part, b: Part): boolean
	for _, p in { a, b } do
		for _, v in { p.CFrame.RightVector, p.CFrame.LookVector } do
			local axis = Vector3.new(v.X, 0, v.Z)
			if axis.Magnitude > 1e-6 then
				local u = axis.Unit
				local a0, a1 = project(a, u)
				local b0, b1 = project(b, u)
				if a1 <= b0 + Config.Map.ZFightEdge or b1 <= a0 + Config.Map.ZFightEdge then
					return false
				end
			end
		end
	end
	return true
end

local function entry(p: Part): Entry
	local half = p.Size / 2
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, s in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		local w = p.CFrame:PointToWorldSpace(Vector3.new(s[1] * half.X, 0, s[2] * half.Z))
		minX, maxX = math.min(minX, w.X), math.max(maxX, w.X)
		minZ, maxZ = math.min(minZ, w.Z), math.max(maxZ, w.Z)
	end
	return { part = p, area = p.Size.X * p.Size.Z, minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
end

-- Two pieces of one surface (the same colour and material, no picture on either) draw the same pixels:
-- they cannot flicker, and lifting one would only make a step in a path.
local function alike(a: Part, b: Part): boolean
	return a.Color == b.Color
		and a.Material == b.Material
		and a.MaterialVariant == b.MaterialVariant
		and a:FindFirstChildWhichIsA("FaceInstance") == nil
		and b:FindFirstChildWhichIsA("FaceInstance") == nil
end

-- The coplanar overlapping pairs among `parts` (each pair once).
function ZFight.pairs(parts: { Part }): { { Part } }
	local list: { Entry } = {}
	for _, p in parts do
		table.insert(list, entry(p))
	end
	local cell = Config.Map.ZFightCell
	local grid: { [string]: { number } } = {}
	for i, e in list do
		for gx = math.floor(e.minX / cell), math.floor(e.maxX / cell) do
			for gz = math.floor(e.minZ / cell), math.floor(e.maxZ / cell) do
				local key = gx .. "," .. gz
				local bucket = grid[key]
				if not bucket then
					bucket = {}
					grid[key] = bucket
				end
				table.insert(bucket, i)
			end
		end
	end
	local seen: { [string]: boolean } = {}
	local found: { { Part } } = {}
	for _, bucket in grid do
		for x = 1, #bucket do
			for y = x + 1, #bucket do
				local i, j = math.min(bucket[x], bucket[y]), math.max(bucket[x], bucket[y])
				local key = i .. ":" .. j
				if not seen[key] then
					seen[key] = true
					local a, b = list[i].part, list[j].part
					if
						math.abs(top(a) - top(b)) < Config.Map.ZFightTolerance
						and not alike(a, b)
						and ZFight.overlap(a, b)
					then
						-- the smaller part first: it is the one that moves
						if list[i].area <= list[j].area then
							table.insert(found, { a, b })
						else
							table.insert(found, { b, a })
						end
					end
				end
			end
		end
	end
	return found
end

-- Every flat-topped visible block part under `root` (and, if given, also those under `others`, which are
-- compared but never moved: the saved village floor beside a rebuilt stage).
local function collect(root: Instance): { Part }
	local parts: { Part } = {}
	for _, p in root:GetDescendants() do
		if flatTop(p) then
			table.insert(parts, p :: Part)
		end
	end
	return parts
end

-- Raise the smaller part of every coplanar overlap under `root` until none is left. Returns how many moved.
function ZFight.resolve(root: Instance, others: Instance?): number
	local movable: { [Part]: boolean } = {}
	local parts = collect(root)
	for _, p in parts do
		movable[p] = true
	end
	if others then
		for _, p in collect(others) do
			if not movable[p] then
				table.insert(parts, p)
			end
		end
	end
	local moved = 0
	for _ = 1, Config.Map.ZFightPasses do
		local found = ZFight.pairs(parts)
		local raised: { [Part]: boolean } = {}
		for _, pr in found do
			local small, big = pr[1], pr[2]
			local lift = if movable[small] then small else (if movable[big] then big else nil)
			-- one step a pass: a part fighting several others moves once, then is checked again
			if lift and not raised[small] and not raised[big] then
				raised[lift] = true
				lift.CFrame += Vector3.new(0, Config.Map.ZFightStep, 0)
				moved += 1
			end
		end
		if next(raised) == nil then
			break
		end
	end
	return moved
end

-- Resolve each stage when it is built or rebuilt (an upgrade replaces it), against the plot it stands in.
function ZFight.watch(map: Instance)
	local pending: { [Instance]: boolean } = {}
	local function settle(stage: Instance)
		if pending[stage] then
			return
		end
		pending[stage] = true
		task.defer(function()
			pending[stage] = nil
			-- (compared with the whole home plot it stands in: the saved floors and paths beside it)
			local plot: Instance? = stage.Parent
			while plot and not string.match(plot.Name, "^Plot%d+$") do
				plot = plot.Parent
			end
			local area = stage.Parent
			if area and plot then
				local moved = ZFight.resolve(stage, plot)
				if moved > 0 then
					print(Config.LogPrefix, "z-fight: raised", moved, "parts in", area.Name .. "." .. stage.Name)
				end
			end
		end)
	end
	local function isStage(inst: Instance): boolean
		return (inst:IsA("Model") or inst:IsA("Folder"))
			and (
				inst.Name == "AreaStage"
				or inst.Name == "PondStage"
				or inst.Name == "VillageStage"
				or inst.Name == "UpgradePads"
			)
	end
	for _, inst in map:GetDescendants() do
		if isStage(inst) then
			settle(inst)
		end
	end
	map.DescendantAdded:Connect(function(inst)
		if isStage(inst) then
			settle(inst)
		end
	end)
end

return ZFight
