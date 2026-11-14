-- The Heart's three gates (Meshy Smart Topology, art/models/world/gates/*.glb, uploaded 2026-11-14) taken into
-- ServerStorage.WorldKit, where tools/world/build_sites.luau clones them. Run again to take them afresh.
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local GATES = { RootGate = 110858843893866, EmberGate = 131059782610116, FrostGate = 83305165757925 }

local kit = ServerStorage:FindFirstChild("WorldKit") or Instance.new("Folder")
kit.Name = "WorldKit"
kit.Parent = ServerStorage

local out = {}
for name, id in GATES do
	local old = kit:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local loaded = InsertService:LoadAsset(id)
	local model = Instance.new("Model")
	model.Name = name
	for _, d in loaded:GetDescendants() do
		if d:IsA("MeshPart") then
			d.Anchored = true
			d.Parent = model
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			table.insert(out, `{name}: {d.Size} mesh {d.MeshId} texture {d.TextureID} sa {sa and sa.ColorMap or "none"} material {d.Material.Name}`)
		end
	end
	model.Parent = kit
	loaded:Destroy()
	task.wait()
end
return table.concat(out, "\n")
