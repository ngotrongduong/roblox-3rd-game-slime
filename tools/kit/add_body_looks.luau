-- Puts the own-body looks (Config.Wear.Bodies, ClientKit.Looks "Body_<secret>") and any skin look still missing
-- (SkinIds, "Skin_<image id>") into assets/ClientKit.rbxm without rebuilding the kit from the work place
-- (tools/kit/export_client_kit.luau makes them too when it runs). Run from the repo root after a body or skin is added
-- or its maps change:
--   lune run tools/kit/add_body_looks.luau
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance

local Config = require("../../src/shared/Config")
local SkinIds = require("../../src/shared/SkinIds")
local C = Config.VillageClient
local PATH = "assets/ClientKit.rbxm"

local kit = roblox.deserializeModel(fs.readFile(PATH))[1]
local looks = kit:FindFirstChild("Looks")
local n = 0
for secret, spec in Config.Wear.Bodies do
	local old = looks:FindFirstChild("Body_" .. secret)
	if old then
		old:Destroy()
	end
	local sa = Instance.new("SurfaceAppearance")
	sa.Name = "Body_" .. secret
	sa.ColorMap = "rbxassetid://" .. tostring(spec.color)
	sa.NormalMap = if spec.normal then "rbxassetid://" .. tostring(spec.normal) else C.NormalMap
	sa.RoughnessMap = if spec.rough then "rbxassetid://" .. tostring(spec.rough) else C.RoughMap
	sa.Parent = looks
	n += 1
end
local skins = 0
for _, image in SkinIds.ById do
	local name = "Skin_" .. tostring(image)
	if not looks:FindFirstChild(name) then
		local sa = Instance.new("SurfaceAppearance")
		sa.Name = name
		sa.ColorMap = "rbxassetid://" .. tostring(image)
		sa.NormalMap = C.NormalMap
		sa.RoughnessMap = C.RoughMap
		sa.Parent = looks
		skins += 1
	end
end
print(string.format("%d skin looks added", skins))
fs.writeFile(PATH, roblox.serializeModel({ kit }))
print(string.format("%s: %d looks, %d own bodies", PATH, #looks:GetChildren(), n))
