-- Counts the triangles of the hand-built village (the template, workspace.Map.Plot5): the plot's own parts and its scenery apart.
-- Run in Edit mode: node tools/studio_mcp.js run tools/map/count_village_triangles.luau <studio_id> Edit
-- A mesh's faces are read with EditableMesh when Studio may (the owner's and our own models, the Quaternius kit); the older Nature pack's
-- (other creators') cannot be read, so their scenery is counted by the measured triangles of one clone of each kind in an empty view
-- (Stats.SceneTriangleCount, tools of 2026-11-02): the table below. Primitive parts count 12 (blocks), 8 (wedges), 100 (balls, cylinders).
local AssetService = game:GetService("AssetService")
local template = workspace.Map:FindFirstChild("Plot5")

-- measured 2026-11-02 before the dressing, each model of the old Nature pack by name (triangles one)
local MEASURED = {
	BanyanTree = 5198,
	BerryBush = 1194,
	BroadleafTree = 4419,
	Bush = 792,
	Fern = 600,
	FernCluster = 1772,
	FlatBoulder = 3222,
	FlowerPatch = 1268,
	FlowerShrub = 2730,
	FloweringBush = 1198,
	GrassTuft = 300,
	JaggedRocks = 1740,
	LogBench = 1731,
	MediumRock = 1174,
	MossyBoulder = 1466,
	OakTree = 2000,
	PineBerryBush = 2642,
	SmallRocks = 5918,
	StackedRocks = 2290,
	Stump = 1498,
	Sunflower = 1998,
	TallPineDense = 4867,
	TallPineLarge = 4584,
	TallPineSlender = 2077,
	TallPineSparse = 2654,
	WaterLily = 1500,
	WideBoulder = 2948,
	WildflowersGrass = 4250,
}
-- the kinds the dressing replaces
local REPLACED = {
	BanyanTree = true,
	BerryBush = true,
	BroadleafTree = true,
	Bush = true,
	Fern = true,
	FernCluster = true,
	FlowerPatch = true,
	FlowerShrub = true,
	FloweringBush = true,
	GrassTuft = true,
	OakTree = true,
	PineBerryBush = true,
	WildflowersGrass = true,
}
local cache = {}
local unknown = 0
local function meshTris(p: MeshPart): number
	local id = p.MeshId
	if cache[id] == nil then
		local ok, mesh = pcall(function()
			return AssetService:CreateEditableMeshAsync(p.MeshContent)
		end)
		cache[id] = if ok and mesh then #mesh:GetFaces() else -1
		if ok and mesh then
			mesh:Destroy()
		end
	end
	if cache[id] < 0 then
		unknown += 1
		return 0
	end
	return cache[id]
end
local function partTris(d: BasePart): number
	if d:IsA("MeshPart") then
		return meshTris(d)
	elseif d:IsA("WedgePart") or d:IsA("CornerWedgePart") then
		return 8
	elseif d:IsA("Part") then
		return if d.Shape == Enum.PartType.Block then 12 else 100
	end
	return 12
end
local function treeOf(d: Instance, folder: Instance): Instance
	local top = d
	while top.Parent and top.Parent ~= folder do
		top = top.Parent :: Instance
	end
	return top
end

local own, sceneryKnown, sceneryStatic, sceneryNew, instances = 0, 0, 0, 0, 0
local newCount, staticCount, oldCount = 0, 0, 0
local counted = {}
for _, d in template:GetDescendants() do
	instances += 1
	if d:IsA("BasePart") then
		local at: Instance? = d.Parent
		local folder: Instance? = nil
		while at and at ~= template do
			if at.Name == "Nature" or at.Name == "FenceSkirt" then
				folder = at
				break
			end
			at = at.Parent
		end
		if folder then
			local item = treeOf(d, folder)
			if item:GetAttribute("VillageTrees") ~= nil or item:GetAttribute("VillageRocks") ~= nil then
				sceneryNew += partTris(d)
			elseif not counted[item] then
				counted[item] = true
				local t = MEASURED[item.Name]
				if t then
					if REPLACED[item.Name] or string.find(item.Name, "^TallPine") then
						sceneryKnown += t
						oldCount += 1
					else
						sceneryStatic += t
						staticCount += 1
					end
				else
					sceneryStatic += partTris(d)
				end
			end
		else
			own += partTris(d)
		end
	end
end
return string.format(
	"plot parts and buildings (everything but scenery): %d tris\nscenery kept (rocks, stumps, benches, sunflowers, lilies; %d items): %d\nold trees/bushes/flowers/grass still standing (%d): %d\nnew valley-asset scenery: %d\nTOTAL %d (instances %d, meshes EditableMesh could not read: %d parts)",
	own,
	staticCount,
	sceneryStatic,
	oldCount,
	sceneryKnown,
	sceneryNew,
	own + sceneryStatic + sceneryKnown + sceneryNew,
	instances,
	unknown
)
