--!strict
-- Starts the server services. The server decides everything; clients draw and ask.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FarmSave = require(ReplicatedStorage.Shared.FarmSave)
local AreaUpgrade = require(script.Parent.AreaUpgrade)
local Leaderboard = require(script.Parent.Leaderboard)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local QuickTravel = require(script.Parent.QuickTravel)
local Village = require(script.Parent.Village)
local VillageRemotes = require(script.Parent.VillageRemotes)
local ZombieFights = require(script.Parent.ZombieFights)

-- Register callbacks before profiles can load. The plots come first: a joining player is handed a plot (and spawns in it)
-- before anything else looks at them, and the hand-built village leaves the world to become the template.
Plots.start()
VillageRemotes.start()
Village.start()
AreaUpgrade.start()
ZombieFights.start()
QuickTravel.start()

-- Player profiles: load, save, session lock. The farm rules give the data its shape.
PlayerData.start(FarmSave.hooks(function(line: string)
	warn(line)
end))

-- The Market's leaderboard reads the loaded farms and sends the best slime of each player to its stores.
Leaderboard.start()

print(Config.LogPrefix, "server started")
