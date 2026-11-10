-- The body of tools/map/sync_all.ps1 (it prepends FILES = { { group, name, class, source }, ... }).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function folder(parent: Instance, name: string): Instance
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local targets = {
	Shared = folder(ReplicatedStorage, "Shared"),
	Server = folder(ServerScriptService, "Server"),
	Client = folder(StarterPlayerScripts, "Client"),
}
targets.Creatures = folder(targets.Shared, "Creatures")
local counts = { Shared = 0, Server = 0, Client = 0, Creatures = 0, VfxLib = 0 }
local lib = Instance.new("ModuleScript")
lib.Name = "VfxLib"
for _, f in FILES do
	if f[1] == "VfxLib" then
		-- (the effects library, built fresh as Rojo lays it out: init is the module, each folder a Folder)
		local path = string.split(f[2], "/")
		local parent: Instance = lib
		for i = 1, #path - 1 do
			parent = folder(parent, path[i])
		end
		local m = if f[2] == "init" then lib else Instance.new("ModuleScript")
		m.Name = if f[2] == "init" then "VfxLib" else path[#path]
		m.Source = f[4]
		m.Parent = if f[2] == "init" then nil else parent
		counts.VfxLib += 1
		continue
	end
	local parent = targets[f[1]]
	-- The new copy is made before the old one goes, so a Source Studio refuses leaves the old script in place.
	local s = Instance.new(f[3])
	s.Name = f[2]
	s.Source = f[4]
	local old = parent:FindFirstChild(f[2])
	if old then
		old:Destroy()
	end
	s.Parent = parent
	counts[f[1]] += 1
end
if counts.VfxLib > 0 then
	local old = targets.Shared:FindFirstChild("VfxLib")
	if old then
		old:Destroy()
	end
	lib.Parent = targets.Shared
end

-- The emotion stage (tools/slime/emotions.ps1) runs its own copies of SlimeFace and SlimeActor: keep them current.
local stage = StarterPlayerScripts:FindFirstChild("SlimeFaceStage")
if stage then
	for _, name in { "SlimeFace", "SlimeActor" } do
		local old = stage:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		local m = Instance.new("ModuleScript")
		m.Name = name
		m.Source = (targets.Client:FindFirstChild(name) :: ModuleScript).Source
		m.Parent = stage
	end
end

-- Remotes the project file declares (Rojo makes them in the built game).
local remotes = folder(ReplicatedStorage, "Remotes")
for name, class in { Action = "RemoteEvent", Fx = "RemoteEvent", Query = "RemoteFunction" } do
	if not remotes:FindFirstChild(name) then
		local r = Instance.new(class)
		r.Name = name
		r.Parent = remotes
	end
end

local kitNote = "kept"
if not ReplicatedStorage:FindFirstChild("ClientKit") then
	local kit = Instance.new("Folder")
	kit.Name = "ClientKit"
	local function take(source: Instance?, name: string, parent: Instance)
		if source then
			local c = source:Clone()
			c.Name = name
			c.Parent = parent
		end
	end
	local body = workspace:FindFirstChild("SlimeBody")
	local hull = workspace:FindFirstChild("SlimeBodyOutline")
	take(body and body:FindFirstChild("SlimeBody"), "SlimeBody", kit)
	take(hull and hull:FindFirstChild("SlimeBodyOutline"), "SlimeBodyOutline", kit)
	local items = folder(kit, "Items")
	local ss = game:GetService("ServerStorage")
	local fish, crops = ss:FindFirstChild("FishKit"), ss:FindFirstChild("CropKit")
	take(fish and fish:FindFirstChild("KoiFish"), "fish", items)
	take(crops and crops:FindFirstChild("Carrot4"), "carrot", items)
	take(crops and crops:FindFirstChild("Cabbage4"), "cabbage", items)
	kit.Parent = ReplicatedStorage
	kitNote = "made"
end
-- The surface looks (same as tools/kit/export_client_kit.luau), rebuilt every sync from the synced Config and SkinIds.
local kit = ReplicatedStorage:FindFirstChild("ClientKit") :: Instance
local oldLooks = kit:FindFirstChild("Looks")
if oldLooks then
	oldLooks:Destroy()
end
local Config = require(targets.Shared:FindFirstChild("Config"))
local C = Config.VillageClient
local SkinIds = require(targets.Shared:FindFirstChild("SkinIds"))
local looks = Instance.new("Folder")
looks.Name = "Looks"
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
for _, image in SkinIds.ById do
	look("Skin_" .. tostring(image), "rbxassetid://" .. tostring(image), C.RoughMap, false)
end
-- a Secret's own body (Config.Wear.Bodies): its own maps, else the slime's normal and roughness
for secret, spec in Config.Wear.Bodies do
	local sa = Instance.new("SurfaceAppearance")
	sa.Name = "Body_" .. secret
	sa.ColorMap = "rbxassetid://" .. tostring(spec.color)
	sa.NormalMap = if spec.normal then "rbxassetid://" .. tostring(spec.normal) else C.NormalMap
	sa.RoughnessMap = if spec.rough then "rbxassetid://" .. tostring(spec.rough) else C.RoughMap
	sa.Parent = looks
end
looks.Parent = kit

return string.format(
	"synced shared %d, vfxlib %d, server %d, client %d; ClientKit %s",
	counts.Shared,
	counts.VfxLib,
	counts.Server,
	counts.Client,
	kitNote
)
