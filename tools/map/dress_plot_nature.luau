-- Dresses the built areas of a home plot with the free Creator Store "Nature stylized Pack"
-- (asset 109637424937405 by Phantomu4_228, no scripts): soft clay-like bushes, flowers, ferns, grass
-- tufts, water lilies, rocks, a stump, an oak. The pack's models live in ServerStorage.NatureKit
-- (moved there from Workspace.AssetTest by the first run). Run in Edit mode through Studio's MCP
-- after the area builders. Replaces the plain ball dressing and the older kit trial.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5

-- The library: one copy of every model of the pack.
local lib = ServerStorage:FindFirstChild("NatureKit")
if not lib then
	local pack = workspace.AssetTest.NatureStylized_Phantomu["Nature Pack"].StylizedNaturePack
	lib = Instance.new("Folder")
	lib.Name = "NatureKit"
	for _, m in pack:GetChildren() do
		m.Parent = lib
	end
	lib.Parent = ServerStorage
end

-- Places a model of the library so that its bounding box stands on the ground at local (x, z) of
-- an area, turned by `turn` degrees and scaled; y lifts it (water lilies sit on the water).
local function put(parent: Instance, area: CFrame, key: string, x: number, z: number, scale: number, turn: number?, y: number?)
	local m = (lib:FindFirstChild(key) :: Model):Clone()
	m:ScaleTo(scale)
	local pivot = m:GetPivot()
	m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.rad(turn or 0), 0) * pivot.Rotation)
	local box, size = m:GetBoundingBox()
	-- On the ground's surface unless a height is given (water lilies: the measured water level).
	local target = (area * CFrame.new(x, (y or Config.Map.GroundY) + size.Y / 2, z)).Position
	m:PivotTo(m:GetPivot() + (target - box.Position))
	m.Parent = parent
end

local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)
local PLAIN = {
	Bush = true,
	Flower = true,
	Stone = true,
	Reed = true,
	Cattail = true,
	LilyPad = true,
	LilyFlower = true,
	SteppingStone = true,
	Kit = true,
	Nature = true,
}

local function dress(areaName: string, area: CFrame, items: { { any } }): number
	local m = plotModel:FindFirstChild(areaName)
	if not m then
		return 0
	end
	for _, c in m:GetChildren() do
		if PLAIN[c.Name] then
			c:Destroy()
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "Nature"
	for _, it in items do
		put(folder, area, it[1], it[2], it[3], it[4], it[5], it[6])
	end
	folder.Parent = m
	return #items
end

-- The pond's water surface, measured.
local fishingArea = Layout.plotAreaFrame(PLOT, -1, 1)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { workspace.Map }
local hit = workspace:Raycast((fishingArea * CFrame.new(0, 20, 5)).Position, Vector3.new(0, -40, 0), params)
local waterY = if hit then hit.Position.Y - fishingArea.Position.Y else -0.9

local n = dress("FishingPondL1", fishingArea, {
	{ "WaterLily", 7, 10, 1.3, 30, waterY - 0.2 },
	{ "WaterLily", -8, 6, 1.1, 200, waterY - 0.2 },
	{ "WaterLily", 4, 16, 1.0, 90, waterY - 0.2 },
	{ "Fern", 13, 19, 1.5, 20 },
	{ "Fern", -17, 11, 1.4, 140 },
	{ "GrassTuft", 16, 14, 1.6, 0 },
	{ "GrassTuft", -14, -9, 1.5, 60 },
	{ "GrassTuft", 10, -13, 1.4, 120 },
	{ "GrassTuft", -6, 21, 1.5, 200 },
	{ "FloweringBush", -14, 20, 1.0, 0 },
	{ "Bush", 18, -7, 0.9, 45 },
	{ "BerryBush", -21, -2, 0.8, 0 },
	{ "MossyBoulder", -19, -9, 0.9, 10 },
	{ "SmallRocks", 18, 4, 1.2, 70 },
	{ "MediumRock", 20, 8, 0.8, 0 },
	{ "FlowerPatch", -10, -14, 1.3, 0 },
	{ "FlowerPatch", 12, -13, 1.2, 90 },
	{ "Stump", 21, -19, 0.9, 0 },
	{ "OakTree", -21, 22, 1.0, 30 },
	{ "SteppingStones", -3, -21.5, 0.8, 90 },
})

local gardenArea = Layout.plotAreaFrame(PLOT, 1, 1)
n += dress("GardenL1", gardenArea, {
	{ "Sunflower", 7.5, 13.6, 1.4, 180 },
	{ "Sunflower", 10.5, 13.4, 1.3, 170 },
	{ "BerryBush", 17, 13, 0.9, 20 },
	{ "FloweringBush", -17, -12, 0.8, 0 },
	{ "FlowerPatch", 16, -12, 1.2, 45 },
	{ "GrassTuft", -16, 6, 1.4, 0 },
	{ "GrassTuft", 15.5, 2, 1.4, 90 },
	{ "SmallRocks", -17, 1, 1.0, 0 },
	{ "Fern", 19, 20, 1.3, 0 },
	{ "OakTree", 21, 22, 0.8, 120 },
	{ "SteppingStones", 0, -6, 0.6, 90 },
})

return "dressed with " .. n .. " pack models"
