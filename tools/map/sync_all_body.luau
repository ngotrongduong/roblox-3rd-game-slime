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
local counts = { Shared = 0, Server = 0, Client = 0 }
for _, f in FILES do
	local parent = targets[f[1]]
	local old = parent:FindFirstChild(f[2])
	if old then
		old:Destroy()
	end
	local s = Instance.new(f[3])
	s.Name = f[2]
	s.Source = f[4]
	s.Parent = parent
	counts[f[1]] += 1
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
local C = require(targets.Shared:FindFirstChild("Config")).VillageClient
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
looks.Parent = kit

return string.format("synced shared %d, server %d, client %d; ClientKit %s", counts.Shared, counts.Server, counts.Client, kitNote)
