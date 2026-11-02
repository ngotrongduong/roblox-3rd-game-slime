-- Checks the shared middle (tools/map/build_wild_slices.luau): nothing that collides within a zombie group's roam or across a
-- team's march line, no prop standing in a glade or on a line, no terrain step on those lines, the Heart's middle clear, and none of
-- the rejected first rebuild left (flat variants, discs, slabs, neon puddles). Run in Edit mode through Studio's MCP; it must end
-- with "WILD OK".
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Zombies = require(ReplicatedStorage.Shared.Zombies)

local M = Config.Map
local HOME_CLEAR = 16 -- a roam of 12 and a little more
local GLADE_OPEN = 11 -- no low prop nearer a home than this
local LINE_CLEAR = 1.75 -- half a slime's width
local HEART_CLEAR = 40 -- the boss rises here later
local MAX_OFF = 1 -- the ground on a line or at a home, off the plain
local MAX_STEP = 1 -- between two probes of a line, STEP studs apart
local STEP = 4
local TALL = 60 -- stands of test models high over the map are not in the way
local GATE_SILL = 2 -- the last studs before a gate belong to the village's own drop to its floor
local HEAD_CLEAR = 3.5 -- what hangs higher than a slime's head does not stop one
local FLOWER = 2 -- what stands lower than this is walked through (flowers, tufts)

local function flat(p: Vector3): Vector3
	return Vector3.new(p.X, 0, p.Z)
end
local function toSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local homes, lines = {}, {}
for slice = 0, M.PlotCount do
	local gate = Layout.sliceGate(slice)
	for camp = 1, #Config.Zombies.LevelOffsets do
		for index = 1, #Config.Zombies.Homes[camp] do
			local across, forward = Zombies.homeOffset(slice, camp, index)
			local home = flat((gate * CFrame.new(across, 0, -forward)).Position)
			local id = Zombies.groupId(slice, camp, index)
			table.insert(homes, { id = id, at = home })
			table.insert(lines, { id = id, from = flat(gate.Position), to = home })
		end
	end
end

local out = {}
local partsSeen = 0

local function checkSolid(part: BasePart, reach: number)
	local p = flat(part.Position)
	for _, home in homes do
		if (p - home.at).Magnitude < HOME_CLEAR + reach then
			table.insert(out, string.format("HOME %s: %s %.1f from it, reach %.1f", home.id, part:GetFullName(), (p - home.at).Magnitude, reach))
			return
		end
	end
	for _, line in lines do
		if toSegment(p, line.from, line.to) < LINE_CLEAR + reach then
			table.insert(out, string.format("LINE %s: %s, reach %.1f", line.id, part:GetFullName(), reach))
			return
		end
	end
end

local function checkLow(part: BasePart)
	-- A prop that does not collide but stands where a group lives or a team marches: it would be walked through in plain sight.
	local p = flat(part.Position)
	local bottom = part.Position.Y - part.Size.Y / 2
	if bottom > M.GroundY + HEAD_CLEAR or part.Size.Y < FLOWER then
		return
	end
	local reach = math.min(part.Size.X, part.Size.Z) / 2
	for _, home in homes do
		if (p - home.at).Magnitude < GLADE_OPEN then
			table.insert(out, string.format("GLADE %s: %s", home.id, part:GetFullName()))
			return
		end
	end
	if part.Size.Y < 25 then
		for _, line in lines do
			if toSegment(p, line.from, line.to) < LINE_CLEAR + reach * 0.5 then
				table.insert(out, string.format("ON LINE %s: %s, %.1f high", line.id, part:GetFullName(), part.Size.Y))
				return
			end
		end
	end
end

local map = workspace.Map
local wild = map.WildGarden
local count = 0
for _, d in wild:GetDescendants() do
	if d:IsA("BasePart") then
		partsSeen += 1
		if flat(d.Position).Magnitude < HEART_CLEAR and d.Position.Y < TALL then
			table.insert(out, "HEART: " .. d:GetFullName())
		end
		if d.CanCollide then
			local reach = if d.Name == "TrunkBlock"
				then d.Size.Y / 2
				else math.max(d.Size.X, d.Size.Z) / 2
			checkSolid(d, reach)
		elseif not d.Transparency or d.Transparency < 1 then
			checkLow(d)
		end
		if d.Material == Enum.Material.Neon and d.Name ~= "Spring" then
			table.insert(out, "NEON: " .. d:GetFullName())
		end
		if d.Name == "Road" or d.Name == "Path" or d.Name == "Puddle" or d.Name == "Clearing" or d.Name == "Goo" then
			table.insert(out, "OLD PIECE: " .. d:GetFullName())
		end
		count += 1
		if count % 50 == 0 then
			task.wait()
		end
	end
end
for _, v in MaterialService:GetChildren() do
	if v:IsA("MaterialVariant") and string.sub(v.Name, 1, 8) == "WildFlat" then
		table.insert(out, "OLD VARIANT: " .. v.Name)
	end
end

-- Whatever else stands on the lines: the Market, the rim, test models left in the place (not the villages).
for _, d in workspace:GetDescendants() do
	if
		d:IsA("BasePart")
		and d.CanCollide
		and d.Position.Y < TALL
		and d.Name ~= "Terrain"
		and not d:IsDescendantOf(wild)
		and not d:IsDescendantOf(map.Plot5)
		and flat(d.Position).Magnitude < M.WildRadius + 60
	then
		checkSolid(d, math.max(d.Size.X, d.Size.Z) / 2)
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
local function probe(p: Vector3, what: string): number
	probes += 1
	local y, material = ground(p)
	if math.abs(y - M.GroundY) > MAX_OFF or material == "Water" then
		table.insert(out, string.format("GROUND %s: %.2f %s at %.0f,%.0f", what, y, material, p.X, p.Z))
	end
	return y
end
for _, line in lines do
	local length = (line.to - line.from).Magnitude
	local d = GATE_SILL
	local last = nil
	while d <= length do
		local y = probe(line.from + (line.to - line.from).Unit * d, line.id)
		if last and math.abs(y - last) > MAX_STEP then
			table.insert(out, string.format("STEP %s: %.2f to %.2f at %.0f along", line.id, last, y, d))
		end
		last = y
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
