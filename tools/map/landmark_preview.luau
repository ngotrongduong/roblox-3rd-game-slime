-- A village landmark (Granary, Kitchen) with its model pieces BEFORE they are uploaded, in the Edit datamodel of the test
-- place:
--   1. the pieces' preview scripts, one Luau script a piece (tools/blender/granary_pieces.py with `-- <folder>` after
--      Blender's arguments; tools/blender/meshy_sheet_split.py writes <out>/preview/): run each in Edit
--      (node tools/studio_mcp.js run <folder>/<Piece>.luau <studio_id> Edit): ServerStorage.GranaryPreview
--   2. node tools/studio_mcp.js run tools/map/landmark_preview.luau <studio_id> Edit Landmark=src/server/Kitchen.luau Architecture=src/server/Architecture.luau Config=src/shared/Config.luau ConfigMeshyKit=src/shared/ConfigMeshyKit.luau
-- It builds workspace.<Name>Preview (the name the module returns: KitchenPreview): the landmark at the last level of each
-- era, 100 studs apart at y 500, front to -z, taking each piece from the preview meshes at the size and place
-- Config.LibraryKit gives it. Fresh copies of the modules every run (the Edit VM keeps a module's first run). Delete the
-- preview folders when done: preview meshes do not survive a save. Shots: screen_capture from (x - 22, 516, -32) to
-- (x + 2, 508, 4), x = 100 * its place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local LEVELS = { 10, 20, 30, 40, 50 }
local server = ServerScriptService.Server
local kit = ServerStorage:FindFirstChild("GranaryPreview")
local stamp = tostring(math.floor(os.clock() * 1000))
local name = Landmark:match("return (%w+)%s*$") .. "Preview"
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
		-- (an uploaded mesh came in half a turn round, as server/LibraryKit turns it back; a preview script's did not)
		local uploaded = part:IsA("MeshPart") and part.MeshId ~= ""
		part.CFrame = CFrame.new(table.unpack(p[1].at)) * CFrame.Angles(0, if uploaded then math.pi else 0, 0)
		return src
	end,
}
module(server, "ArchitecturePreview", Architecture)
local source = Landmark:gsub("require%(script%.Parent%.LibraryKit%)", "(_G.GranaryPreviewKit :: any)")
	:gsub("script%.Parent%.Architecture", "script.Parent.ArchitecturePreview" .. stamp)
local build = (require :: any)(module(server, name, source)).build

local old = workspace:FindFirstChild(name)
if old then
	old:Destroy()
end
local out = Instance.new("Folder")
out.Name = name
local counts = {}
for i, level in LEVELS do
	local m = Instance.new("Model")
	m.Name = "L" .. level
	local frame = CFrame.new(i * 100, 500, if name == "GranaryPreview" then 0 else 300)
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
