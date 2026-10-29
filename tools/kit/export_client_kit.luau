-- Builds the client's kit (assets/ClientKit.rbxm, Rojo puts it in ReplicatedStorage.ClientKit) from the work place
-- saved by Studio (assets/raw/MapWork.rbxlx): the rigged slime body and its outline hull (the models imported on
-- the owner's account, Workspace.SlimeBody / SlimeBodyOutline), and the food the slimes carry (Items/<item>: the
-- pond's koi, the ripe carrot and cabbage), the dishes, the egg and the work tools (from PropKit; see
-- docs/kit/README.md). A missing model is named in the output and the client draws a stand-in. Run after the work
-- place is saved:
--   lune run tools/kit/export_client_kit.luau
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance

local SOURCE = "assets/raw/MapWork.rbxlx"
local OUT = "assets/ClientKit.rbxm"

local place = roblox.deserializePlace(fs.readFile(SOURCE))
local workspace = place:GetService("Workspace")
local storage = place:GetService("ServerStorage")

local kit = Instance.new("Folder")
kit.Name = "ClientKit"
local lines = {}

local function take(source: any, name: string, parent: any)
	if source then
		local copy = source:Clone()
		copy.Name = name
		copy.Parent = parent
		table.insert(lines, "  " .. name)
	else
		table.insert(lines, "  " .. name .. "  MISSING")
	end
end

-- The rigged MeshParts with their bones; the client resets PivotOffset as the showcase does.
local body = workspace:FindFirstChild("SlimeBody")
local hull = workspace:FindFirstChild("SlimeBodyOutline")
take(body and body:FindFirstChild("SlimeBody"), "SlimeBody", kit)
take(hull and hull:FindFirstChild("SlimeBodyOutline"), "SlimeBodyOutline", kit)

local items = Instance.new("Folder")
items.Name = "Items"
items.Parent = kit
local fish = storage:FindFirstChild("FishKit")
local crops = storage:FindFirstChild("CropKit")
take(fish and fish:FindFirstChild("KoiFish"), "fish", items)
take(crops and crops:FindFirstChild("Carrot4"), "carrot", items)
take(crops and crops:FindFirstChild("Cabbage4"), "cabbage", items)
-- the cooked dishes and the egg (made with generate_mesh, docs/kit/README.md), and the gardener's and fisher's
-- tools (tools/kit/make_tools.luau builds the rod and the hoe; the watering can is the garden's): all in PropKit
local props = storage:FindFirstChild("PropKit")
for _, key in { "grilledFish", "veggieStew", "fishVegSoup", "Egg", "Hoe", "WateringCan", "FishingRod" } do
	take(props and props:FindFirstChild(key), key, items)
end
-- (the client draws a carried egg from ClientKit.Egg)
take(props and props:FindFirstChild("Egg"), "Egg", kit)

-- Looks: a game script may not set a SurfaceAppearance's maps (Plugin capability), only its Color, so every map the
-- slimes use is made here once: Plain (the white map, tinted per slime), PlainFine (roughness 0.03: Ice, Jelly),
-- Mirror (the chrome map for Gold and Silver) and Skin_<image id> for each of the 55 Duals. SlimeLook clones them.
local Config = require("../../src/shared/Config")
local SkinIds = require("../../src/shared/SkinIds")
local C = Config.VillageClient
local looks = Instance.new("Folder")
looks.Name = "Looks"
looks.Parent = kit
local function look(name: string, map: string, rough: string, metal: boolean)
	local sa = Instance.new("SurfaceAppearance")
	sa.Name = name
	sa.ColorMap = map
	sa.NormalMap = C.NormalMap
	sa.RoughnessMap = rough
	if metal then
		sa.MetalnessMap = C.WhiteMap
	end
	sa.Parent = looks
end
look("Plain", C.WhiteMap, C.RoughMap, false)
look("PlainFine", C.WhiteMap, C.RoughMetalMap, false)
look("Mirror", C.MirrorMap, C.RoughMetalMap, true)
local skins = 0
for _, image in SkinIds.ById do
	look("Skin_" .. tostring(image), "rbxassetid://" .. tostring(image), C.RoughMap, false)
	skins += 1
end
table.insert(lines, "  Looks: Plain, PlainFine, Mirror, " .. skins .. " skins")

local data = roblox.serializeModel({ kit })
fs.writeFile(OUT, data)
print(string.format("%s  %.1f KB\n%s", OUT, #data / 1024, table.concat(lines, "\n")))
