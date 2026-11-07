--!strict
-- The props from the free library (Config.LibraryKit): put together once from the owner's imported meshes, each a Model
-- whose pivot is the middle of its foot, kept in ServerStorage.LibraryKit. The stages place them by name like the kit's own
-- models (PantryStages.place), waiting for the meshes the first time.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local L = Config.LibraryKit

type PropPart = { mesh: number, tex: string, size: { number }, at: { number } }
local PROPS: { [string]: { PropPart } } = L.Props :: any
local TEXTURES: { [string]: string } = L.Textures :: any

local LibraryKit = {}

local folder: Folder? = nil
local building = false

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function build(): Folder
	local out = Instance.new("Folder")
	out.Name = "LibraryKit"
	local pending = 0
	for name, parts in PROPS do
		local model = Instance.new("Model")
		model.Name = name
		model.WorldPivot = CFrame.identity
		model.Parent = out
		for _, p in parts do
			pending += 1
			-- (every mesh loads at once: one at a time held the first plot several seconds)
			task.spawn(function()
				local ok, mesh = pcall(function()
					return AssetService:CreateMeshPartAsync(Content.fromAssetId(p.mesh))
				end)
				if ok then
					mesh.Name = name .. "Part"
					mesh.Size = v3(p.size)
					mesh.CFrame = CFrame.new(v3(p.at))
					mesh.TextureID = TEXTURES[p.tex] or ""
					mesh.Color = Color3.new(1, 1, 1)
					mesh.Material = Enum.Material.SmoothPlastic
					mesh.Anchored = true
					mesh.CastShadow = p.size[2] > 2
					mesh.Parent = model
				else
					warn(Config.LogPrefix, "library prop", name, "mesh did not load:", mesh)
				end
				pending -= 1
			end)
		end
	end
	while pending > 0 do
		task.wait(0.1)
	end
	-- (a prop missing a part is left out rather than shown broken)
	for _, model in out:GetChildren() do
		if #model:GetChildren() < #PROPS[model.Name] then
			model:Destroy()
		end
	end
	out.Parent = ServerStorage
	return out
end

local function ready(): Folder?
	local waited = 0
	while building and waited < L.WaitSeconds do
		waited += task.wait(0.1)
	end
	if folder or building then
		return folder
	end
	building = true
	folder = build()
	building = false
	return folder
end

-- The library prop called `name`, nil if there is none or its meshes did not load in time.
function LibraryKit.find(name: string): Model?
	if not PROPS[name] then
		return nil
	end
	local f = ready()
	local m = f and f:FindFirstChild(name)
	return if m and m:IsA("Model") then m else nil
end

-- Starts loading the meshes at once, so the first plot does not wait for them.
function LibraryKit.start()
	task.spawn(ready)
end

return LibraryKit
