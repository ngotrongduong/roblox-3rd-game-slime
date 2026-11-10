-- Puts the own-body looks (Config.Wear.Bodies, ClientKit.Looks "Body_<secret>") into assets/ClientKit.rbxm without
-- rebuilding the kit from the work place (tools/kit/export_client_kit.luau makes them too when it runs). Run from the
-- repo root after a body is added or its maps change:
--   lune run tools/kit/add_body_looks.luau
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance

local Config = require("../../src/shared/Config")
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
fs.writeFile(PATH, roblox.serializeModel({ kit }))
print(string.format("%s: %d looks, %d own bodies", PATH, #looks:GetChildren(), n))
