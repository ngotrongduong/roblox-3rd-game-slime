-- Dresses the built areas of a home plot with low-poly models from the reusable kit made for Egg
-- Heist (C:\roblox 2nd game\docs\kit\README.md: every model has an asset id, its pivot at the middle
-- of its foot, sizes at scale 1). Replaces the plain ball bushes, stones, reeds and lily pads of the
-- area builders. Run in Edit mode through Studio's MCP after build_fishing_l1 / build_garden_l1.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5

-- Kit asset ids (Egg Heist kit).
local KIT = {
	bush_flower_pink = 105995960036363,
	bush_round_green = 89397047915585,
	bush_berry_red = 89295744508336,
	flower_cattails = 106423717941443,
	flower_lily_pads = 117619434991794,
	flower_daisies = 107727493302274,
	flower_sunflower = 139029671315225,
	flower_tulips_red = 134340803816564,
	rock_boulder_mossy = 106056641881585,
	rock_pebbles = 93423185497735,
	rock_boulder_big = 76184147421470,
	tree_round_simple = 98374419030523,
	tree_round_tiny = 108294075137009,
}

-- One loaded copy of each kit model, kept in ServerStorage.KitCache.
local cache = ServerStorage:FindFirstChild("KitCache") or Instance.new("Folder")
cache.Name = "KitCache"
cache.Parent = ServerStorage
local function kit(key: string): Model
	local master = cache:FindFirstChild(key)
	if not master then
		local container = InsertService:LoadAsset(KIT[key])
		master = container:FindFirstChildWhichIsA("Model")
		master.Name = key
		master.Parent = cache
		container:Destroy()
	end
	return (master :: Model):Clone()
end

-- Places a kit model in an area: local x, z (as the area builders use), ground height y, a scale
-- and a turn in degrees.
local function place(parent: Instance, area: CFrame, key: string, x: number, z: number, scale: number, turn: number?, y: number?)
	local m = kit(key)
	m:ScaleTo(scale)
	m:PivotTo(area * CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(turn or 0), 0))
	m.Parent = parent
end

local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)
local PLAIN = { Bush = true, Flower = true, Stone = true, Reed = true, Cattail = true, LilyPad = true, LilyFlower = true }

local function dress(areaName: string, area: CFrame, items: { { any } })
	local m = plotModel:FindFirstChild(areaName)
	if not m then
		return 0
	end
	for _, c in m:GetChildren() do
		if PLAIN[c.Name] or c.Name == "Kit" then
			c:Destroy()
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "Kit"
	for _, it in items do
		place(folder, area, it[1], it[2], it[3], it[4], it[5], it[6])
	end
	folder.Parent = m
	return #items
end

-- The water surface of the pond, measured (lily pads float on it).
local fishingArea = Layout.plotAreaFrame(PLOT, -1, 1)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { workspace.Map }
local hit = workspace:Raycast((fishingArea * CFrame.new(0, 20, 5)).Position, Vector3.new(0, -40, 0), params)
local waterY = if hit then hit.Position.Y - fishingArea.Position.Y else -0.9

local n = dress("FishingPondL1", fishingArea, {
	{ "flower_cattails", 13, 19, 1, 20 },
	{ "flower_cattails", -17, 11, 0.9, 140 },
	{ "flower_cattails", 18, 12, 0.7, 260 },
	{ "flower_lily_pads", 7, 10, 0.55, 30, waterY - 0.1 },
	{ "flower_lily_pads", -8, 6, 0.4, 200, waterY - 0.1 },
	{ "rock_boulder_mossy", -19, -6, 0.45, 10 },
	{ "rock_pebbles", 18, 4, 0.45, 70 },
	{ "rock_boulder_big", -21, 19, 0.3, 120 },
	{ "bush_flower_pink", -14, 19, 0.75, 0 },
	{ "bush_round_green", 17, -6, 0.65, 45 },
	{ "flower_daisies", -10, -13, 0.8, 0 },
	{ "flower_daisies", 12, -12, 0.7, 90 },
	{ "tree_round_simple", -22, 23, 0.9, 30 },
})

local gardenArea = Layout.plotAreaFrame(PLOT, 1, 1)
n += dress("GardenL1", gardenArea, {
	{ "flower_sunflower", 7.5, 13.6, 0.75, 180 },
	{ "flower_sunflower", 10.5, 13.6, 0.7, 180 },
	{ "bush_berry_red", 17, 13, 0.7, 20 },
	{ "flower_tulips_red", -16, -11, 0.8, 0 },
	{ "flower_daisies", 16, -11, 0.75, 45 },
	{ "rock_pebbles", -17, 4, 0.4, 0 },
	{ "tree_round_tiny", 21, 21, 0.8, 0 },
})

return "dressed with " .. n .. " kit models"
