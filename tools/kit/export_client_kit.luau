-- Builds the client's kit (assets/ClientKit.rbxm, Rojo puts it in ReplicatedStorage.ClientKit) from the work place
-- saved by Studio (assets/raw/MapWork.rbxlx): the rigged slime body and its outline hull (the models imported on
-- the owner's account, Workspace.SlimeBody / SlimeBodyOutline), and the food the slimes carry (Items/<item>: the
-- pond's koi, the ripe carrot and cabbage). Dishes and the egg have no model yet; the client draws a stand-in and
-- names it in the log. Run after the work place is saved:
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

local data = roblox.serializeModel({ kit })
fs.writeFile(OUT, data)
print(string.format("%s  %.1f KB\n%s", OUT, #data / 1024, table.concat(lines, "\n")))
