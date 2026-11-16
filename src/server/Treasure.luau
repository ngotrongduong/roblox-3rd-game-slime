--!strict
-- The treasure chests of the open world (Config.World.Chests; rules shared/Treasure; the owner, 2026-11-16): Count chests
-- lie on the land at a time, each under a pillar of light every player sees from afar. The first player to open one is
-- paid its coins, past the vault's cap (Zombies.payReward), and told so through Remotes.Treasure ({ coins, at }) for the
-- toast and the burst; RespawnSeconds later another chest lies somewhere else.
--
--   workspace.TreasureChests.Chest   a Model (Persistent: on every device) of one MeshPart, the chest, with the Beam of
--                     its pillar and its ProximityPrompt "ChestPrompt".
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Rng = require(ReplicatedStorage.Shared.Rng)
local Treasure = require(ReplicatedStorage.Shared.Treasure)
local WorldPlan = require(ReplicatedStorage.Shared.WorldPlan)
local Zombies = require(ReplicatedStorage.Shared.Zombies)
local PlayerData = require(script.Parent.PlayerData)

local C = Config.World.Chests

local TreasureServer = {}

local rng = Rng.new(os.time())
local folder: Folder
local remote: RemoteEvent
local mesh: MeshPart
-- the plan point of every chest lying now
local lying: { [Model]: { number } } = {}

-- Where a chest may lie at this world point, by one ray straight down: the terrain, not water, not steeper than the packs
-- stand on; nil anywhere else (a rock, a tree, a roof).
local function ground(x: number, z: number): Vector3?
	local ignore: { Instance } = { folder }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(x, 2000, z), Vector3.new(0, -4000, 0), params)
	if
		not hit
		or hit.Instance ~= workspace.Terrain
		or hit.Material == Enum.Material.Water
		or hit.Normal.Y < Config.World.Packs.MinNormalY
	then
		return nil
	end
	return hit.Position
end

local function taken(): { { number } }
	local out = {}
	for _, at in lying do
		table.insert(out, at)
	end
	return out
end

local open: (Model, Player) -> ()

-- One new chest on a free spot; false when none was found this time.
local function place(): boolean
	local px, pz = Treasure.spot(rng, taken(), function(x: number, z: number): boolean
		local wx, wz = WorldPlan.world(x, z)
		return ground(wx, wz) ~= nil
	end)
	if not px or not pz then
		return false
	end
	local wx, wz = WorldPlan.world(px, pz)
	local foot = ground(wx, wz) :: Vector3
	local model = Instance.new("Model")
	model.Name = "Chest"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local chest = mesh:Clone()
	chest.Name = "Chest"
	chest.Size = mesh.Size * C.Scale
	chest.CFrame = CFrame.new(foot + Vector3.new(0, chest.Size.Y / 2, 0))
		* CFrame.Angles(0, rng:next() * 2 * math.pi, 0)
	-- (its colours are the file's vertex colours, which the part's Color multiplies)
	chest.Color = Color3.new(1, 1, 1)
	chest.Anchored = true
	chest.CanTouch = false
	chest.CastShadow = false
	chest.Parent = model
	model.PrimaryPart = chest

	-- the pillar: the library's light shafts on a Beam from inside the chest up into the sky, turned to the camera; its foot
	-- fades in (a Beam's end is a hard straight line over the grass)
	local low = Instance.new("Attachment")
	low.Name = "PillarFoot"
	low.Position = Vector3.new(0, 0, 0)
	low.Parent = chest
	local high = Instance.new("Attachment")
	high.Name = "PillarTop"
	high.Position = Vector3.new(0, chest.Size.Y / 2 + C.PillarHeight, 0)
	high.Parent = chest
	local colour = Color3.fromHex(C.PillarColour)
	local beam = Instance.new("Beam")
	beam.Name = "Pillar"
	beam.Attachment0 = low
	beam.Attachment1 = high
	beam.Texture = "rbxassetid://" .. C.PillarTexture
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureSpeed = C.PillarSpeed
	beam.FaceCamera = true
	beam.Width0 = C.PillarWidth[1]
	beam.Width1 = C.PillarWidth[2]
	beam.Color = ColorSequence.new(colour, Color3.new(1, 1, 1))
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Brightness = 2
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.06, 0.05),
		NumberSequenceKeypoint.new(0.6, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	-- (a Beam reads its Transparency only at its segments' ends: one segment would lose the faded foot)
	beam.Segments = 16
	beam.Parent = chest

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChestPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = "Treasure Chest"
	prompt.HoldDuration = C.HoldSeconds
	prompt.MaxActivationDistance = C.PromptRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = chest
	prompt.Triggered:Connect(function(player: Player)
		open(model, player)
	end)

	lying[model] = { px, pz }
	model.Parent = folder
	return true
end

-- Places a chest now, or tries again a little later when the land had no free spot.
local function placeSoon()
	if not place() then
		task.delay(10, placeSoon)
	end
end

open = function(model: Model, player: Player)
	local at = lying[model]
	local chest = model.PrimaryPart
	if not at or not chest then
		return
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - chest.Position).Magnitude > C.PromptRangeStuds + 6 then
		return
	end
	local coins = Treasure.coins(at[1], at[2])
	local paid = 0
	local ok = PlayerData.update(player, function(farm: any)
		paid = Zombies.payReward(farm, coins, os.time())
	end)
	if not ok then
		return
	end
	-- (gone for everyone the moment it is paid: nobody opens it twice)
	lying[model] = nil
	local where = chest.Position
	model:Destroy()
	PlayerData.markKeyMoment(player, "treasure chest")
	remote:FireClient(player, { coins = paid, at = where })
	print(
		Config.LogPrefix,
		"treasure:",
		player.Name,
		"opened a chest at",
		math.floor(at[1]),
		math.floor(at[2]),
		"paid",
		paid
	)
	task.delay(C.RespawnSeconds, placeSoon)
end

function TreasureServer.start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local made = remotes:FindFirstChild(C.Remote)
	if not made then
		made = Instance.new("RemoteEvent")
		made.Name = C.Remote
		made.Parent = remotes
	end
	assert(made:IsA("RemoteEvent"), "Treasure remote must be a RemoteEvent")
	remote = made
	folder = Instance.new("Folder")
	folder.Name = C.Folder
	folder.Parent = workspace
	-- the chest's mesh first (it yields); no chests at all when it does not come
	task.spawn(function()
		local okLoad, loaded = pcall(function()
			return InsertService:LoadAsset(C.Model)
		end)
		local found = if okLoad then (loaded :: Instance):FindFirstChildWhichIsA("MeshPart", true) else nil
		if not found then
			warn(Config.LogPrefix, "treasure: the chest model did not load:", if okLoad then "no mesh" else loaded)
			return
		end
		found.Parent = nil
		mesh = found;
		(loaded :: Instance):Destroy()
		for _ = 1, C.Count do
			placeSoon()
		end
		local count = 0
		for _ in lying do
			count += 1
		end
		print(Config.LogPrefix, "treasure:", count, "chests lie in the world")
	end)
end

return TreasureServer
