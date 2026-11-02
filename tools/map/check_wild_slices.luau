-- Checks the shared middle (tools/map/build_wild_slices.luau): every part that stands within the limits of a zombie group's
-- home, its march line or a path, and every ground height off by more than a stud on those lines and homes. Run in Edit mode
-- through Studio's MCP; it must end with "WILD OK".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Zombies = require(ReplicatedStorage.Shared.Zombies)

local M = Config.Map
local HOME_CLEAR = 16 -- a roam of 12 and a little more
local LINE_CLEAR = 1.75 -- half a slime's width
local PATH_HALF = M.PathWidth / 2
local RINGS = { 261, 191, M.HeartRadius }
local MAX_OFF = 1
local TALL = 60 -- stands of test models high over the map are not in the way
local GATE_SILL = 2 -- the last studs before a gate belong to the village's own drop to its floor
local STEP = 4
-- A tree's crown may reach over a march line, above a slime's head (it does not collide): only this share of the spread of
-- these one-mesh models stands low; a part named Foliage whose underside clears HEAD_CLEAR counts for nothing on a line.
local LOW_SHARE = { TwistedTree = 0.45, GiantMushroom = 0.4 }
local HEAD_CLEAR = 3.5

local function flat(p: Vector3): Vector3
	return Vector3.new(p.X, 0, p.Z)
end
local function toSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local homes, lines, gates = {}, {}, {}
for slice = 0, M.PlotCount do
	local gate = Layout.sliceGate(slice)
	table.insert(gates, flat(gate.Position))
	for camp = 1, #Config.Zombies.LevelOffsets do
		for index = 1, Config.Zombies.GroupsPerCamp do
			local across, forward = Zombies.campOffset(camp, index)
			local home = flat((gate * CFrame.new(across, 0, -forward)).Position)
			local id = Zombies.groupId(slice, camp, index)
			table.insert(homes, { id = id, at = home })
			table.insert(lines, { id = id, from = flat(gate.Position), to = home })
		end
	end
end

local out = {}
local partsSeen = 0

local function checkPart(part: BasePart, isScenery: boolean)
	local p = flat(part.Position)
	-- trees and bushes are round in plan
	local reach = math.max(part.Size.X, part.Size.Z) / 2
	partsSeen += 1
	for _, home in homes do
		if (p - home.at).Magnitude < HOME_CLEAR + reach then
			table.insert(out, string.format("HOME %s: %s %.1f from it, reach %.1f", home.id, part:GetFullName(), (p - home.at).Magnitude, reach))
			return
		end
	end
	local low = reach * (LOW_SHARE[part:GetAttribute("Kit") or ""] or 1)
	if part.Name == "Foliage" and part.Position.Y - part.Size.Y / 2 > M.GroundY + HEAD_CLEAR then
		low = 0
	end
	for _, line in lines do
		if low > 0 and toSegment(p, line.from, line.to) < LINE_CLEAR + low then
			table.insert(out, string.format("LINE %s: %s, reach %.1f", line.id, part:GetFullName(), reach))
			return
		end
	end
	if isScenery then
		local r = p.Magnitude
		for _, ring in RINGS do
			if math.abs(r - ring) < PATH_HALF + reach then
				table.insert(out, string.format("CIRCLE %d: %s", ring, part:GetFullName()))
				return
			end
		end
		for _, gate in gates do
			if toSegment(p, gate, gate.Unit * M.HeartRadius) < PATH_HALF + reach then
				table.insert(out, string.format("PATH: %s", part:GetFullName()))
				return
			end
		end
	end
end

local map = workspace.Map
local scenery = map.WildGarden:FindFirstChild("Scenery")
local count = 0
for _, d in scenery:GetChildren() do
	if d:IsA("BasePart") then
		checkPart(d, true)
		count += 1
		if count % 50 == 0 then
			task.wait()
		end
	end
end
-- Whatever else stands on the lines: the heart, the Market, the rim, test models left in the place (not the villages).
for _, d in workspace:GetDescendants() do
	if
		d:IsA("BasePart")
		and d.Position.Y < TALL
		and d.Name ~= "Terrain"
		and not d:IsDescendantOf(scenery)
		and not d:IsDescendantOf(map.WildGarden.Paths)
		and not d:IsDescendantOf(map.WildGarden.Puddles)
		and not d:IsDescendantOf(map.WildGarden.Goo)
		and not d:IsDescendantOf(map.Plot5)
	then
		local r = flat(d.Position).Magnitude
		if r < M.WildRadius + 60 then
			checkPart(d, false)
		end
	end
	count += 1
	if count % 2000 == 0 then
		task.wait()
	end
end

-- The ground.
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { workspace.Terrain }
local function ground(p: Vector3): (number, string)
	local hit = workspace:Raycast(Vector3.new(p.X, 80, p.Z), Vector3.new(0, -200, 0), rp)
	if not hit then
		return math.huge, "none"
	end
	return hit.Position.Y, hit.Material.Name
end
local probes = 0
local function probe(p: Vector3, what: string)
	probes += 1
	local y, material = ground(p)
	if math.abs(y - M.GroundY) > MAX_OFF or material == "Water" then
		table.insert(out, string.format("GROUND %s: %.2f %s at %.0f,%.0f", what, y, material, p.X, p.Z))
	end
end
for _, line in lines do
	local length = (line.to - line.from).Magnitude
	local d = GATE_SILL
	while d <= length do
		probe(line.from + (line.to - line.from).Unit * d, line.id)
		d += STEP
	end
end
task.wait()
for _, home in homes do
	probe(home.at, home.id)
	for k = 1, 8 do
		local a = k * math.pi / 4
		probe(home.at + Vector3.new(math.cos(a), 0, math.sin(a)) * (HOME_CLEAR - 1), home.id)
	end
end

local shown = {}
for i = 1, math.min(#out, 60) do
	shown[i] = out[i]
end
table.insert(shown, string.format("%d parts checked, %d ground probes, %d problems", partsSeen, probes, #out))
table.insert(shown, if #out == 0 then "WILD OK" else "WILD NOT OK")
return table.concat(shown, "\n")
