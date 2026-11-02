-- Makes ServerStorage.WildKit, the models of the valley's middle that came from free Creator Store packs (docs/kit/README.md):
-- Yasu's Stylized Tree Pack (79689531752352, by mvyasu: two meshes a tree, colourless canopies, root meshes, bushes) and the
-- Doki3D Plant Pack (132133490211548, by Doki_3D: grass tufts and flowers, one mesh each, recolourable). Each kept piece is
-- fitted for placing (scripts gone, anchored, pivot at the middle of its foot). Run once in Edit mode after inserting the packs
-- under ServerStorage.AssetTest (the MCP insert_asset tool); a piece already in WildKit is replaced. The packs' own folders, with
-- their hundreds of label parts, are then removed from AssetTest: the kit is what the map uses.
local ServerStorage = game:GetService("ServerStorage")

local tests = ServerStorage:WaitForChild("AssetTest")
local yasu = tests:FindFirstChild("YasuTreePack")
local doki = tests:FindFirstChild("Doki3DPlants")
local kit = ServerStorage:FindFirstChild("WildKit")
if not kit then
	kit = Instance.new("Folder")
	kit.Name = "WildKit"
	kit.Parent = ServerStorage
end

local out = {}
local function fit(source: Instance, name: string)
	local copy = source:Clone()
	local model = copy
	if not copy:IsA("Model") then
		model = Instance.new("Model")
		copy.Parent = model
	end
	model.Name = name
	for _, d in model:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = false
			d.CanCollide = false
		end
	end
	local box, size = model:GetBoundingBox()
	local foot = box.Position - Vector3.new(0, size.Y / 2, 0)
	model.PrimaryPart = nil
	model.WorldPivot = CFrame.new(foot)
	model:PivotTo(CFrame.new())
	local old = kit:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	model.Parent = kit
	table.insert(out, string.format("%s %.0fx%.0fx%.0f", name, size.X, size.Y, size.Z))
end

if yasu then
	for _, t in yasu.Models_Trees.Models:GetChildren() do
		fit(t, (string.gsub(t.Name, "Tree_", "YasuTree")))
	end
	for _, b in yasu.Models_Bushes.Models:GetChildren() do
		fit(b, (string.gsub(b.Name, "Bush_", "YasuBush")))
	end
	for _, r in yasu.Meshes_Roots.Meshes:GetChildren() do
		if r:IsA("BasePart") then
			fit(r, "Yasu" .. string.gsub(r.Name, "_", ""))
		end
	end
	yasu:Destroy()
end
if doki then
	for _, g in doki.Grass:GetChildren() do
		if string.match(g.Name, "^Grass_%d") then
			fit(g, (string.gsub(g.Name, "Grass_", "DokiGrass")))
		end
	end
	for _, f in doki.Flowers:GetChildren() do
		if string.match(f.Name, "^Flower_%d") then
			fit(f, (string.gsub(f.Name, "Flower_", "DokiFlower")))
		end
	end
	doki:Destroy()
end
local tried = tests:FindFirstChild("ColorfulTrees_ceconello") -- 15-31 meshes a tree: too many parts, not used
if tried then
	tried:Destroy()
end
return table.concat(out, ", ")
