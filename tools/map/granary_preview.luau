-- The Granary with its Blender pieces BEFORE they are uploaded, in the Edit datamodel of the test place:
--   1. tools/blender/granary_pieces.py with `-- <folder>` after Blender's arguments writes one Luau script a piece; run
--      each in Edit (node tools/studio_mcp.js run <folder>/<Piece>.luau <studio_id> Edit): ServerStorage.GranaryPreview
--   2. node tools/studio_mcp.js run tools/map/granary_preview.luau <studio_id> Edit Granary=src/server/Granary.luau Architecture=src/server/Architecture.luau Config=src/shared/Config.luau
-- It builds workspace.GranaryPreview: the Granary at levels 20, 30, 40 and 50, 100 studs apart at y 500, front to -z,
-- taking each piece from the preview meshes at the size and place Config.LibraryKit gives it. Fresh copies of the
-- modules every run (the Edit VM keeps a module's first run). Delete both GranaryPreview folders when done: preview
-- meshes do not survive a save.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local LEVELS = { 20, 30, 40, 50 }
local server = ServerScriptService.Server
local kit = ServerStorage:FindFirstChild("GranaryPreview")
local stamp = tostring(math.floor(os.clock() * 1000))
local temp = {}

local function module(parent: Instance, name: string, source: string): ModuleScript
	local m = Instance.new("ModuleScript")
	m.Name = name .. stamp
	m.Source = source
	m.Parent = parent
	table.insert(temp, m)
	return m
end

local props = (require :: any)(module(ReplicatedStorage.Shared, "ConfigPreview", Config)).LibraryKit.Props
_G.GranaryPreviewKit = {
	find = function(name: string): Model?
		local src = kit and kit:FindFirstChild(name)
		local p = props[name]
		if not (src and p) then
			return nil
		end
		local part = src:FindFirstChildWhichIsA("BasePart")
		part.Size = Vector3.new(table.unpack(p[1].size))
		part.CFrame = CFrame.new(table.unpack(p[1].at))
		return src
	end,
}
module(server, "ArchitecturePreview", Architecture)
local source = Granary:gsub("require%(script%.Parent%.LibraryKit%)", "(_G.GranaryPreviewKit :: any)")
	:gsub("script%.Parent%.Architecture", "script.Parent.ArchitecturePreview" .. stamp)
local build = (require :: any)(module(server, "GranaryPreview", source)).build

local old = workspace:FindFirstChild("GranaryPreview")
if old then
	old:Destroy()
end
local out = Instance.new("Folder")
out.Name = "GranaryPreview"
local counts = {}
for i, level in LEVELS do
	local m = Instance.new("Model")
	m.Name = "L" .. level
	local frame = CFrame.new(i * 100, 500, 0)
	local lawn = Instance.new("Part")
	lawn.Name = "Lawn"
	lawn.Anchored = true
	lawn.Size = Vector3.new(90, 1, 90)
	lawn.CFrame = frame * CFrame.new(0, -0.5, 8)
	lawn.Color = Color3.fromRGB(104, 178, 62)
	lawn.Parent = m
	build(m, frame, level)
	m.Parent = out
	local meshes = 0
	for _, d in m:GetDescendants() do
		if d:IsA("MeshPart") and d.Name ~= "SlimeBody" then
			meshes += 1
		end
	end
	table.insert(counts, level .. ": " .. meshes .. " mesh pieces")
	task.wait()
end
out.Parent = workspace
for _, m in temp do
	m:Destroy()
end
_G.GranaryPreviewKit = nil
return table.concat(counts, "; ")
