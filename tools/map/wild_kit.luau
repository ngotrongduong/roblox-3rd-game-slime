-- Makes ServerStorage.WildKit, the models of the valley's middle that came from free Creator Store packs (docs/kit/README.md):
-- Yasu's Stylized Tree Pack (79689531752352, by mvyasu: two meshes a tree, colourless canopies, root meshes, bushes) and the
-- Doki3D Plant Pack (132133490211548, by Doki_3D: grass tufts and flowers, one mesh each, recolourable). Each kept piece is
-- fitted for placing (scripts gone, anchored, pivot at the middle of its foot). Run once in Edit mode after inserting the packs
-- under ServerStorage.AssetTest (the MCP insert_asset tool); a piece already in WildKit is replaced. The packs' own folders, with
-- their hundreds of label parts, are then removed from AssetTest: the kit is what the map uses.
local ServerStorage = game:GetService("ServerStorage")

-- Also here (2026-11-02): the thirty `Qt*` models of Quaternius' CC0 Stylized Nature MegaKit stay in WildKit as they are: the owner
-- imported art/models/quaternius/*.glb (tools/map/prepare_quaternius.py), a script cannot recreate them. And the owner's own models
-- from his inventory (Mue_you) are loaded as `Own<Name>` by the second half of this file; one already in the kit is left alone.
local InsertService = game:GetService("InsertService")
local tests = ServerStorage:FindFirstChild("AssetTest") or Instance.new("Folder")
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

-- The owner's own models (InsertService:LoadAsset works for his account in his Studio). One mesh each, 120-5,200 triangles; the
-- last seven are generated mushrooms and crystals (unnamed packages), cheap (120-400), the rest his hand-made pieces (1,500-5,200).
local OWN = {
	EmberCrystalPatch = 131791034889052,
	MagmaCrystalCluster = 128091965429686,
	MoltenPlateau = 117158825911208,
	StackedBasalt = 120326438638537,
	Firegrass = 79610957358740,
	IceCrystalCluster = 118055572065490,
	IceCrystalSpire = 96014375258879,
	FrozenRockSpire = 73340583537098,
	SnowberryBush = 133807897663279,
	MossyRockStack = 95076775374326,
	JungleStoneShelf = 88910027293012,
	AncientJungleTree = 138768266237986,
	FlowerBush = 110932950369537,
	MushBlue = 108230156976781,
	MushPurple = 82978024017038,
	MushPurpleSpotted = 129368300885107,
	MushPink = 105673382838100,
	CrystalPaleBlue = 89565445204716,
	CrystalRed = 83837005139701,
	CrystalBlue = 81030539240809,
}
local loaded = {}
for name, id in OWN do
	if not kit:FindFirstChild("Own" .. name) then
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok then
			local model = asset:FindFirstChildWhichIsA("Model") or asset:FindFirstChildWhichIsA("BasePart")
			if model then
				fit(model, "Own" .. name)
				table.insert(loaded, name)
			end
			asset:Destroy()
		else
			table.insert(loaded, name .. " FAILED")
		end
		task.wait()
	end
end
-- The Qt* pieces came in with the leaves' picture as MeshPart.TextureID, whose alpha Roblox ignores: every card drew as a dark
-- opaque sheet (seen 2026-11-02). The same picture as a SurfaceAppearance ColorMap with AlphaMode Transparency cuts the leaves out and
-- takes a tint through SurfaceAppearance.Color. Rocks, pebbles and mushrooms have no cut-out and keep their TextureID.
local solid = { "QtRock", "QtPebble", "QtRockPath", "QtMushroom" }
local converted = 0
for _, model in kit:GetChildren() do
	if string.sub(model.Name, 1, 2) == "Qt" then
		local keep = false
		for _, prefix in solid do
			if string.sub(model.Name, 1, #prefix) == prefix then
				keep = true
			end
		end
		if not keep then
			for _, d in model:GetDescendants() do
				if d:IsA("MeshPart") and d.TextureID ~= "" and not d:FindFirstChildOfClass("SurfaceAppearance") then
					local sa = Instance.new("SurfaceAppearance")
					sa.ColorMap = d.TextureID
					sa.AlphaMode = Enum.AlphaMode.Transparency
					sa.Parent = d
					d.TextureID = ""
					converted += 1
				end
			end
		end
	end
end
-- The Qt trees' Bark meshes came out shredded (the phone-size decimation tore them at the texture seams: scattered triangles instead of
-- a trunk), so the trees are made as Mix* models: the Qt crown (Skin) on a Yasu trunk. { name, crown, trunk's tree, trunk's share of
-- the crown model's height, width factor }. Their crowns keep their own colour (a tint only darkens): common green, twisted red.
local MIX = {
	{ "MixCommon1", "QtCommonTree_1", "YasuTree13", 0.75, 1.7 },
	{ "MixCommon3", "QtCommonTree_3", "YasuTree01", 0.7, 1.7 },
	{ "MixCommon5", "QtCommonTree_5", "YasuTree15", 0.72, 1.5 },
	{ "MixTwisted1", "QtTwistedTree_1", "YasuTree06", 0.55, 1.2 },
	{ "MixTwisted2", "QtTwistedTree_2", "YasuTree05", 0.6, 1.3 },
	{ "MixTwisted3", "QtTwistedTree_3", "YasuTree19", 0.6, 1.2 },
	{ "MixPine1", "QtPine_1", "YasuTree13", 0.55, 1.1 },
	{ "MixPine5", "QtPine_5", "YasuTree01", 0.5, 1.0 },
}
local mixed = {}
for _, spec in MIX do
	local crown, trunkTree = kit:FindFirstChild(spec[2]), kit:FindFirstChild(spec[3])
	if crown and trunkTree then
		local model = crown:Clone()
		model.Name = spec[1]
		local _, size = model:GetBoundingBox()
		local bark = model:FindFirstChild("Bark", true)
		if bark then
			bark:Destroy()
		end
		local trunk
		for _, d in trunkTree:GetDescendants() do
			if d:IsA("MeshPart") and string.find(d.Name, "Trunk") then
				trunk = d
			end
		end
		local t = trunk:Clone()
		local k = size.Y * spec[4] / t.Size.Y
		t.Size = Vector3.new(t.Size.X * k * spec[5], t.Size.Y * k, t.Size.Z * k * spec[5])
		local foot = model:GetPivot().Position
		t.CFrame = CFrame.new(foot.X, foot.Y + t.Size.Y / 2 - 0.05, foot.Z)
		t.Anchored = true
		t.Parent = model
		local old = kit:FindFirstChild(spec[1])
		if old then
			old:Destroy()
		end
		model.Parent = kit
		table.insert(mixed, spec[1])
	end
end
return table.concat(out, ", ") .. " | own: " .. table.concat(loaded, ", ") .. " | cut-out converted: " .. converted .. " | mixed: " .. table.concat(mixed, ", ")
