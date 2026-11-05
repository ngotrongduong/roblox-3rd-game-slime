--!strict
-- Starts the server services. The server decides everything; clients draw and ask.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local FarmSave = require(ReplicatedStorage.Shared.FarmSave)
local Arena = require(script.Parent.Arena)
local AreaUpgrade = require(script.Parent.AreaUpgrade)
local Dungeon = require(script.Parent.Dungeon)
local DungeonPortal = require(script.Parent.DungeonPortal)
local Guide = require(script.Parent.Guide)
local Leaderboard = require(script.Parent.Leaderboard)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Purchases = require(script.Parent.Purchases)
local QuickTravel = require(script.Parent.QuickTravel)
local Rewards = require(script.Parent.Rewards)
local Village = require(script.Parent.Village)
local VillageRemotes = require(script.Parent.VillageRemotes)
local WavingFlag = require(script.Parent.WavingFlag)
local ZombieFights = require(script.Parent.ZombieFights)

-- The flag's meshes start loading before any plot needs one.
WavingFlag.start()

-- Register callbacks before profiles can load. The plots come first: a joining player is handed a plot (and spawns in it)
-- before anything else looks at them, and the hand-built village leaves the world to become the template.
Plots.start()
VillageRemotes.start()
Village.start()
AreaUpgrade.start()
ZombieFights.start()
QuickTravel.start()
Guide.start()
Rewards.start()
DungeonPortal.start()
Dungeon.start()

-- Player profiles: load, save, session lock. The farm rules give the data its shape.
PlayerData.start(FarmSave.hooks(function(line: string)
	warn(line)
end))

-- Robux: receipts, game passes and the shop's prompts (after the profiles it grants into; its onReady joins the loaded ones).
Purchases.start()

-- The Market's leaderboard reads the loaded farms and sends the best slime of each player to its stores.
Leaderboard.start()

-- The Arena: its remote, the ladder's leader ticks and the matches in flight (after the profiles it reads).
Arena.start()

-- The owner's debug menu: Studio only. It is found by name and not required at the top, because the publish build removes
-- the module (tools/build_publish.luau) and the published game must start without it.
if RunService:IsStudio() then
	local debugModule = script.Parent:FindFirstChild("OwnerDebug")
	if debugModule and debugModule:IsA("ModuleScript") then
		(require(debugModule) :: any).start()
	end
end

print(Config.LogPrefix, "server started")
