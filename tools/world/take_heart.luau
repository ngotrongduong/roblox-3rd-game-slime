-- The Heart's own scenery (Meshy Smart Topology, art/models/world/heart/*.glb, uploaded 2026-11-14) taken into
-- ServerStorage.WorldKit, where tools/world/build_heart.luau clones it. Run again to take the models afresh.
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local MODELS = {
	CrownShrine = 129882405246422,
	HeartGuardian = 104753794485071,
	RuinColonnade = 74984591414162,
	SlimeSpout = 127775916474282,
	RuneStone = 111689925366023,
	CrystalLantern = 98344425380349,
}

local kit = ServerStorage:FindFirstChild("WorldKit") or Instance.new("Folder")
kit.Name = "WorldKit"
kit.Parent = ServerStorage

local out = {}
for name, id in MODELS do
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
