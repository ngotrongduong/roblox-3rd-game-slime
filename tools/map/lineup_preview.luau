-- The village's landmarks side by side in Edit, to compare their sizes (the owner, 2026-11-17: "put them all next to
-- each other to compare the difference in size"; "have a top-down view to judge sizes").
-- node tools/studio_mcp.js run <this> <studio_id> Edit Architecture=src/server/Architecture.luau Config=src/shared/Config.luau ConfigMeshyKit=src/shared/ConfigMeshyKit.luau Pond=src/server/PondStages.luau Granary=src/server/Granary.luau Kitchen=src/server/Kitchen.luau Garden=src/server/Garden.luau BreedingHouse=src/server/BreedingHouse.luau TrainingHall=src/server/TrainingHall.luau Boathouse=src/server/Boathouse.luau Spec=<file>
-- Spec: first line `<folder name> <row z>`, then a line a landmark: `<Module> <level> <K> <splitZ> <pivotX> <pivotZ>`:
-- what stands at or behind splitZ (the area's frame) is the house and grows K times round (pivotX, 0, pivotZ).
-- (The modules grow their houses themselves now, by Config.Village.HouseScale: K here is 1, unless a size on top of
-- that is being tried; the House group is still made, for the report of its size.)
-- Run tools/map/real_kit_preview.luau first (the pieces). Every building gets the fishing pier's size as a brown slab
-- (6 x 24.7) and a red 5-stud player before its front, at x -GAP/2 + 12.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local SOURCES: { [string]: string } = {
	Granary = Granary,
	Kitchen = Kitchen,
	Garden = Garden,
	BreedingHouse = BreedingHouse,
	TrainingHall = TrainingHall,
	Boathouse = Boathouse,
}
local GAP = 170
local server = ServerScriptService.Server
local kit = ServerStorage:FindFirstChild("GranaryPreview")
local stamp = tostring(math.floor(os.clock() * 1000))
local temp = {}

local function module(parent: Instance, called: string, source: string): ModuleScript
	local m = Instance.new("ModuleScript")
	m.Name = called .. stamp
	m.Source = source
	m.Parent = parent
	table.insert(temp, m)
	return m
end

module(ReplicatedStorage.Shared, "ConfigMeshyKitPreview", ConfigMeshyKit)
local config = Config:gsub("script%.Parent%.ConfigMeshyKit", "script.Parent.ConfigMeshyKitPreview" .. stamp)
local props = (require :: any)(module(ReplicatedStorage.Shared, "ConfigPreview", config)).LibraryKit.Props
_G.GranaryPreviewKit = {
	find = function(piece: string): Model?
		local src = kit and kit:FindFirstChild(piece)
		local p = props[piece]
		if not (src and p) then
			return nil
		end
		local part = src:FindFirstChildWhichIsA("BasePart")
		part.Size = Vector3.new(table.unpack(p[1].size))
		local uploaded = part:IsA("MeshPart") and part.MeshId ~= ""
		part.CFrame = CFrame.new(table.unpack(p[1].at)) * CFrame.Angles(0, if uploaded then math.pi else 0, 0)
		return src
	end,
}
-- (Architecture reads the working tree's Config too: the houses grow by its Village.HouseScale.)
module(
	server,
	"ArchitecturePreview",
	(Architecture:gsub("ReplicatedStorage%.Shared%.Config%)", "ReplicatedStorage.Shared.ConfigPreview" .. stamp .. ")"))
)
local pond = (require :: any)(module(server, "PondPreview", Pond))

local lines = {}
for line in Spec:gmatch("[^\r\n]+") do
	table.insert(lines, line)
end
local name, rowZ = lines[1]:match("(%w+)%s+(%-?[%d%.]+)")
local old = workspace:FindFirstChild(name)
if old then
	old:Destroy()
end
local out = Instance.new("Folder")
out.Name = name
local function slab(m: Instance, called: string, sx: number, sy: number, sz: number, cf: CFrame, colour: Color3)
	local p = Instance.new("Part")
	p.Name = called
	p.Anchored = true
	p.Size = Vector3.new(sx, sy, sz)
	p.CFrame = cf
	p.Color = colour
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = m
end
local report = {}
for i = 2, #lines do
	local which, level, k, splitZ, px, pz =
		lines[i]:match("(%w+)%s+(%d+)%s+([%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)")
	if which then
		level, k, splitZ, px, pz = tonumber(level), tonumber(k), tonumber(splitZ), tonumber(px), tonumber(pz)
		local source = SOURCES[which]
			:gsub("require%(script%.Parent%.LibraryKit%)", "(_G.GranaryPreviewKit :: any)")
			:gsub("script%.Parent%.Architecture", "script.Parent.ArchitecturePreview" .. stamp)
		local build = (require :: any)(module(server, which .. "Lineup", source)).build
		local frame = CFrame.new((i - 1) * GAP, 500, tonumber(rowZ))
		local m: Instance
		local green, blue = Color3.fromRGB(104, 178, 62), Color3.fromRGB(56, 156, 222)
		if which == "Boathouse" then
			m = pond.build(level, frame * CFrame.new(-3, 0, 0))
			slab(m, "Water", GAP - 10, 1, 41, frame * CFrame.new(0, -2.8, 6.5), blue)
			slab(m, "NearBank", GAP - 10, 4, 22, frame * CFrame.new(0, -2, -25), green)
			slab(m, "BackBank", GAP - 10, 4, 80, frame * CFrame.new(0, -2, 67), green)
		else
			m = Instance.new("Model")
			slab(m, "Lawn", GAP - 10, 1, 140, frame * CFrame.new(0, -0.5, 30), green)
		end
		m.Name = which
		slab(m, "PierRuler", 6, 0.4, 24.7, frame * CFrame.new(-GAP / 2 + 12, 0.3, -24), Color3.fromRGB(150, 98, 52))
		slab(m, "PlayerRuler", 4, 5, 1, frame * CFrame.new(-GAP / 2 + 19, 2.5, -24), Color3.fromRGB(230, 60, 60))
		local before = {}
		for _, c in m:GetChildren() do
			before[c] = true
		end
		build(m, frame, level)
		local group = Instance.new("Model")
		group.Name = "House"
		for _, c in m:GetChildren() do
			if not before[c] and c:IsA("PVInstance") and frame:PointToObjectSpace(c:GetPivot().Position).Z >= splitZ then
				c.Parent = group
			end
		end
		group.WorldPivot = frame * CFrame.new(px, 0, pz)
		group.Parent = m
		if k ~= 1 then
			group:ScaleTo(k)
		end
		local cf, size = group:GetBoundingBox()
		local at = frame:PointToObjectSpace(cf.Position)
		table.insert(
			report,
			string.format(
				"%s L%d K%.2f: group %d x %d x %d (x %d..%d, z %d..%d)",
				which,
				level,
				k,
				size.X,
				size.Y,
				size.Z,
				at.X - size.X / 2,
				at.X + size.X / 2,
				at.Z - size.Z / 2,
				at.Z + size.Z / 2
			)
		)
		m.Parent = out
		task.wait()
	end
end
out.Parent = workspace
for _, m in temp do
	m:Destroy()
end
_G.GranaryPreviewKit = nil
return table.concat(report, "\n")
