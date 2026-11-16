-- The village's UPLOADED pieces as ServerStorage.GranaryPreview, the folder tools/map/landmark_preview.luau takes its
-- pieces from: every prop of ConfigMeshyKit (the owner's sheet pieces) and every picture-less prop of Config.LibraryKit
-- (the Blender pieces) whose mesh id is no longer 0, one Model each holding its real MeshPart in its sheet's picture.
-- So a landmark is seen in Edit with the very meshes the game will load, their real front and their real picture.
--   node tools/studio_mcp.js run tools/map/real_kit_preview.luau <studio_id> Edit Config=src/shared/Config.luau ConfigMeshyKit=src/shared/ConfigMeshyKit.luau
-- A piece not uploaded yet still needs its preview script (landmark_preview's step 1), run AFTER this one.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local stamp = tostring(math.floor(os.clock() * 1000))
local temp = {}

local function module(called: string, source: string): ModuleScript
	local m = Instance.new("ModuleScript")
	m.Name = called .. stamp
	m.Source = source
	m.Parent = ReplicatedStorage.Shared
	table.insert(temp, m)
	return m
end

local meshy = (require :: any)(module("ConfigMeshyKitPreview", ConfigMeshyKit)).Props
local config = Config:gsub("script%.Parent%.ConfigMeshyKit", "script.Parent.ConfigMeshyKitPreview" .. stamp)
local kit = (require :: any)(module("ConfigPreview", config)).LibraryKit

local old = ServerStorage:FindFirstChild("GranaryPreview")
if old then
	old:Destroy()
end
local out = Instance.new("Folder")
out.Name = "GranaryPreview"
local pending, made, failed = 0, 0, {}
for name, parts in kit.Props do
	local p = parts[1]
	if p.mesh ~= 0 and (meshy[name] or p.tex == "") then
		pending += 1
		task.spawn(function()
			local ok, mesh = pcall(function()
				return AssetService:CreateMeshPartAsync(Content.fromAssetId(p.mesh))
			end)
			if ok then
				local model = Instance.new("Model")
				model.Name = name
				model.WorldPivot = CFrame.identity
				mesh.Anchored = true
				mesh.TextureID = kit.Textures[p.tex] or ""
				mesh.Parent = model
				model.Parent = out
				made += 1
			else
				table.insert(failed, name)
			end
			pending -= 1
		end)
	end
end
while pending > 0 do
	task.wait(0.1)
end
out.Parent = ServerStorage
for _, m in temp do
	m:Destroy()
end
return made .. " pieces; failed: " .. table.concat(failed, ", ")
