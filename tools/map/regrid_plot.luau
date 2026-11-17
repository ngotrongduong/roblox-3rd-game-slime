-- Moves the hand-built village (workspace.Map.Plot<Config.Plots.TemplatePlot>) to where the code now puts it, without
-- building it again (the owner, 2026-11-17: the houses grew, "the plot grows with its house"; docs/VILLAGE_SCALE.md §6).
-- Once, when the plot's size changed (the village then carries GridSize):
--   1. the whole village goes from its old plot frame to Layout.plotFrame (the villages moved);
--   2. what stands in the village spreads with the grid: the plaza's and the campfire's things keep their places round
--      their middles, the gate's go to the new front, the rest (trees, lamps) moves out in proportion;
--   3. the palisade is set again along the new edge, at the spacing it had; the skirt outside it goes
--      (tools/map/tidy_plot.luau makes it again).
-- Every run (so it is run again after Config.Map.AreaPull or an area's front changes):
--   4. each area's model goes, as it is, from the frame it stands on (AreaAt_<id>, kept on the village) to
--      Layout.plotAreaFacing;
--   5. the paving is laid again as tools/map/build_village.luau lays it (plaza, a path to each area's front, the gate
--      path, the campfire's patch), in the colours the old tiles had;
--   6. the village's scenery standing where the pond and its banks now are goes (the houses clear their own ground
--      when they are built: the *Stages modules).
-- Before a new plot size is synced, the old frames must be on the village as attributes: OldPlotFrame, and
-- OldArea_<id> = Layout.plotAreaFacing of every area. Then sync and run, in Edit:
--   node tools/studio_mcp.js run tools/map/regrid_plot.luau <studio_id> Edit
-- After it: stud_floor, pond_water_l1, tidy_plot, prepare_plots.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = Config.Plots.TemplatePlot
local SIZE = Config.Map.PlotSize
local HALF = SIZE / 2
local GROUND = Config.Map.GroundY or 2
local PLAZA = Config.Map.PlazaRadius
local CAMP_R = 13
local AREAS = {
	fishing = "FishingPondL1",
	pantry = "PantryL1",
	garden = "GardenL1",
	kitchen = "KitchenL1",
	breeding = "BreedingL1",
	training = "TrainingL1",
}
-- each area's front point in its own frame, where its path ends (tools/map/build_village.luau FRONTS)
local FRONTS = {
	fishing = { -3, -23 },
	pantry = { 0, -15.5 },
	garden = { 0, -13 },
	kitchen = { 0, -13.5 },
	breeding = { 4, -20 },
	training = { 0, -17.5 },
}
-- The pond's ground in the fishing area's frame, from the near bank's fence to the Boathouse's landing (x0, x1, z0, z1):
-- no village scenery stands on it, nor where the water is or will come.
local POND_GROUND = { -34, 34, -32, 26 }

local plot = workspace.Map["Plot" .. PLOT]
local village = plot.Village
local newFrame = Layout.plotFrame(PLOT)
local report = {}

local function turnAttributes(root: Instance, move: CFrame)
	for _, d in root:GetDescendants() do
		for tag, names in Config.Plots.Turned do
			if d:IsA("Model") and CollectionService:HasTag(d, tag) then
				for _, name in names do
					local value = d:GetAttribute(name)
					if typeof(value) == "Vector3" then
						d:SetAttribute(name, move * value)
					end
				end
			end
		end
	end
end
local function shift(item: Instance, by: Vector3)
	if item:IsA("PVInstance") then
		item:PivotTo(item:GetPivot() + newFrame:VectorToWorldSpace(by))
	end
end
-- a world position in the plot's (new) frame, flat
local function flat(world: Vector3): Vector3
	local p = newFrame:PointToObjectSpace(world)
	return Vector3.new(p.X, 0, p.Z)
end
-- where a thing stands in the plot's (new) frame, flat
local function flatAt(item: Instance): Vector3?
	return if item:IsA("PVInstance") then flat(item:GetPivot().Position) else nil
end
-- The frame an area's model stands on now. (A village regridded before AreaAt was kept stands at the middle of its
-- cells.)
local function standsAt(a): CFrame
	local at = plot:GetAttribute("AreaAt_" .. a.id)
	if typeof(at) == "CFrame" then
		return at
	end
	return Layout.plotAreaFacing(PLOT, a.col, a.row) * CFrame.new(0, 0, Config.Map.AreaPull[a.id] or 0)
end
local function camp(): any
	for _, a in Layout.PlotAreas do
		if a.id == "hatchery" then
			return a
		end
	end
	error("no hatchery cell")
end

-- ===== once: the village to a plot of another size =====
if plot:GetAttribute("GridSize") ~= SIZE then
	local oldFrame = plot:GetAttribute("OldPlotFrame")
	assert(typeof(oldFrame) == "CFrame", "no OldPlotFrame on the village: record the old frames before syncing")
	local OLD_HALF = (plot:GetAttribute("GridSize") or 228) / 2
	local k = HALF / OLD_HALF

	-- 1. the whole village to its plot's new frame
	local move = newFrame * oldFrame:Inverse()
	plot:PivotTo(move * plot:GetPivot())
	turnAttributes(plot, move)
	local devSpawn = workspace:FindFirstChild("DevSpawn")
	if devSpawn and devSpawn:IsA("BasePart") then
		devSpawn.CFrame = move * devSpawn.CFrame
	end
	for _, a in Layout.PlotAreas do
		local old = plot:GetAttribute("OldArea_" .. a.id)
		assert(typeof(old) == "CFrame", "no OldArea_" .. a.id)
		plot:SetAttribute("AreaAt_" .. a.id, move * old)
	end
	task.wait()
	table.insert(report, string.format("village to (%.0f, %.0f)", newFrame.Position.X, newFrame.Position.Z))

	-- 2. what stands in the village spreads with the grid
	local oldCamp = flat(standsAt(camp()).Position)
	local newCamp = flat(Layout.plotAreaFacing(PLOT, camp().col, camp().row).Position)
	local spread = 0
	local function place(item: Instance)
		local p = flatAt(item)
		if not p or p.Magnitude <= PLAZA + 3 then
			return
		end
		if (p - oldCamp).Magnitude <= CAMP_R + 8 then
			shift(item, newCamp - oldCamp)
		elseif math.abs(p.X) < 14 and p.Z < -OLD_HALF + 20 then
			shift(item, Vector3.new(0, 0, -(HALF - OLD_HALF)))
		else
			shift(item, p * (k - 1))
		end
		spread += 1
	end
	local samples: { [string]: BasePart } = {} -- a fence piece of each side
	local gateGap = math.huge
	for _, c in village:GetChildren() do
		if c.Name == "Paving" then
			continue
		elseif c.Name == "Fence" and c:IsA("Folder") then
			for _, piece in c:GetChildren() do
				local p = flatAt(piece) :: Vector3
				local side = if p.Z > OLD_HALF - 3
					then "back"
					elseif p.Z < -OLD_HALF + 3 then "front"
					elseif p.X > 0 then "right"
					else "left"
				samples[side] = samples[side] or piece
				if side == "front" then
					gateGap = math.min(gateGap, math.abs(p.X))
				end
			end
		elseif c.Name == "Nature" then
			for _, n in c:GetChildren() do
				place(n)
			end
		else
			place(c)
		end
	end
	task.wait()
	table.insert(report, spread .. " village pieces spread")

	-- 3. the palisade along the new edge
	local fence = village:FindFirstChild("Fence")
	if fence and samples.back then
		local kept = {}
		for side, piece in samples do
			kept[side] = piece:Clone()
		end
		local oldPieces = #fence:GetChildren()
		local length = samples.back.Size.X
		local old = 7.864 -- the spacing the pieces had
		local reach = HALF + 0.75 - length / 2 -- the last piece's middle
		fence:ClearAllChildren()
		local pieces = 0
		local function set(side: string, x: number, z: number)
			local piece = kept[side]:Clone()
			local was = newFrame:ToObjectSpace(piece.CFrame)
			piece.CFrame = newFrame * (CFrame.new(x, was.Position.Y, z) * was.Rotation)
			piece.Parent = fence
			pieces += 1
		end
		local n = math.round(reach / old)
		local step = reach / n
		for i = -n, n do
			set("back", i * step, HALF)
			set("left", -HALF, i * step)
			set("right", HALF, i * step)
		end
		local m = math.round((reach - gateGap) / old)
		local frontStep = (reach - gateGap) / m
		for i = 0, m do
			for _, s in { -1, 1 } do
				set("front", s * (gateGap + i * frontStep), -HALF)
			end
		end
		for _, piece in kept do
			piece:Destroy()
		end
		table.insert(report, "palisade " .. oldPieces .. " -> " .. pieces .. " pieces")
	end
	local skirt = plot:FindFirstChild("FenceSkirt")
	if skirt then
		skirt:Destroy()
	end
	plot:SetAttribute("GridSize", SIZE)
end

-- ===== 4. each area to its frame =====
local campWas = flat(standsAt(camp()).Position)
local moved = {}
for _, a in Layout.PlotAreas do
	local was = standsAt(a)
	local now = Layout.plotAreaFacing(PLOT, a.col, a.row)
	local model = AREAS[a.id] and plot:FindFirstChild(AREAS[a.id])
	local far = (now.Position - was.Position).Magnitude
	if model and (far > 0.01 or now.LookVector:Dot(was.LookVector) < 0.99999) then
		local areaMove = now * was:Inverse()
		model:PivotTo(areaMove * model:GetPivot())
		turnAttributes(model, areaMove)
		table.insert(moved, string.format("%s %.0f", a.id, far))
	end
	plot:SetAttribute("AreaAt_" .. a.id, now)
	plot:SetAttribute("OldArea_" .. a.id, nil)
end
plot:SetAttribute("OldPlotFrame", nil)
local campNow = flat(Layout.plotAreaFacing(PLOT, camp().col, camp().row).Position)
task.wait()
table.insert(report, "areas moved (studs): " .. (if #moved > 0 then table.concat(moved, ", ") else "none"))

-- ===== 5. the paving, laid again =====
local tiles: { BasePart } = {}
for _, c in village:GetChildren() do
	if c.Name == "Paving" and c:IsA("BasePart") then
		table.insert(tiles, c)
	end
end
-- (a colour is read from the old tiles: the plaza's, the gate path's just outside it, the campfire's patch)
local function colourAt(x: number, z: number): Color3
	local best, colour = math.huge, Color3.fromRGB(196, 192, 182)
	local at = newFrame:PointToWorldSpace(Vector3.new(x, 0, z))
	for _, t in tiles do
		local d = (Vector3.new(t.Position.X, 0, t.Position.Z) - Vector3.new(at.X, 0, at.Z)).Magnitude
		if d < best then
			best, colour = d, t.Color
		end
	end
	return colour
end
local STONE, STONE_DARK = colourAt(1, 5), colourAt(1, PLAZA - 1)
local PATH = colourAt(1, -(PLAZA + 10))
local EARTH, EARTH_DARK = colourAt(campWas.X + 1, campWas.Z + 1), colourAt(campWas.X + 1, campWas.Z + CAMP_R - 1)
local template = tiles[1]:Clone()
for _, t in tiles do
	t:Destroy()
end
task.wait()
local laid: { [string]: boolean } = {}
local count = 0
local function tile(gx: number, gz: number, colour: Color3)
	local key = gx .. "," .. gz
	if laid[key] then
		return
	end
	laid[key] = true
	local t = template:Clone()
	t.CFrame = newFrame * CFrame.new(gx * 2 + 1, GROUND + 0.15, gz * 2 + 1)
	t.Color = colour
	t.Parent = village
	count += 1
	if count % 400 == 0 then
		task.wait()
	end
end
local function path(from: Vector3, to: Vector3, width: number)
	local d = to - from
	local steps = math.ceil(d.Magnitude)
	local reach = width / 2 - 1
	for i = 0, steps do
		local p = from + d * (i / steps)
		for ox = -reach, reach, 2 do
			for oz = -reach, reach, 2 do
				tile(math.floor((p.X + ox) / 2), math.floor((p.Z + oz) / 2), PATH)
			end
		end
	end
end
local cells = math.ceil(PLAZA / 2)
for gx = -cells, cells - 1 do
	for gz = -cells, cells - 1 do
		local r = Vector2.new(gx * 2 + 1, gz * 2 + 1).Magnitude
		if r <= PLAZA then
			tile(gx, gz, if r > PLAZA - 2.2 then STONE_DARK else STONE)
		end
	end
end
for _, a in Layout.PlotAreas do
	local front = FRONTS[a.id]
	if front then
		local p = flat((Layout.plotAreaFacing(PLOT, a.col, a.row) * CFrame.new(front[1], 0, front[2])).Position)
		path(p.Unit * (PLAZA - 1), p, Config.Map.PathWidth)
	end
end
path(Vector3.new(0, 0, -(PLAZA - 1)), Vector3.new(0, 0, -HALF + 1), Config.Map.MainPathWidth)
for gx = -7, 6 do
	for gz = -7, 6 do
		local x, z = gx * 2 + 1, gz * 2 + 1
		local r = Vector2.new(x, z).Magnitude
		if r <= CAMP_R then
			tile(
				math.floor((campNow.X + x) / 2),
				math.floor((campNow.Z + z) / 2),
				if r > CAMP_R - 2.2 then EARTH_DARK else EARTH
			)
		end
	end
end
path(campNow.Unit * (PLAZA - 1), campNow - campNow.Unit * (CAMP_R - 1), Config.Map.PathWidth)
template:Destroy()
task.wait()
table.insert(report, #tiles .. " -> " .. count .. " paving tiles")

-- ===== 6. no village scenery on the pond's ground =====
local fishing = Layout.plotAreaFacing(PLOT, -1, 1)
local function onPond(world: Vector3): boolean
	local p = fishing:PointToObjectSpace(world)
	if p.X > POND_GROUND[1] and p.X < POND_GROUND[2] and p.Z > POND_GROUND[3] and p.Z < POND_GROUND[4] then
		return true
	end
	for _, lobes in { Config.Village.Pond.Lobes, Config.Village.Pond.Grow } do
		for _, l in lobes do
			if Vector2.new(p.X - l[1], p.Z - l[2]).Magnitude < l[3] + 4 then
				return true
			end
		end
	end
	return false
end
local gone: { string } = {}
local function clear(item: Instance)
	if item:IsA("PVInstance") and onPond(item:GetPivot().Position) then
		table.insert(gone, item.Name)
		item:Destroy()
	end
end
for _, c in village:GetChildren() do
	if c.Name == "Nature" then
		for _, n in c:GetChildren() do
			clear(n)
		end
	elseif c.Name ~= "Paving" and c.Name ~= "Fence" then
		clear(c)
	end
end
-- (and the pond's own trees and bushes the water came to: PondStages.grow takes them in the game anyway; lilies float)
local pondModel = plot:FindFirstChild(AREAS.fishing)
local pondNature = pondModel and pondModel:FindFirstChild("Nature")
for _, n in (if pondNature then pondNature:GetChildren() else {}) :: { Instance } do
	if n:IsA("Model") and n.Name ~= "WaterLily" then
		local p = fishing:PointToObjectSpace(n:GetPivot().Position)
		for _, l in Config.Village.Pond.Lobes do
			if Vector2.new(p.X - l[1], p.Z - l[2]).Magnitude < l[3] + 2.6 then
				table.insert(gone, n.Name)
				n:Destroy()
				break
			end
		end
	end
end
table.insert(report, #gone .. " village pieces off the pond's ground".. (if #gone > 0 then " (" .. table.concat(gone, " ") .. ")" else ""))

return table.concat(report, "; ")
