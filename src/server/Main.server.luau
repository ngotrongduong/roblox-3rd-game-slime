--!strict
-- Starts the server services. The server decides everything; clients draw and ask.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FarmSave = require(ReplicatedStorage.Shared.FarmSave)
local PlayerData = require(script.Parent.PlayerData)
local Village = require(script.Parent.Village)
local VillageRemotes = require(script.Parent.VillageRemotes)
local ZFight = require(script.Parent.ZFight)

-- Register callbacks before profiles can finish loading.
VillageRemotes.start()
Village.start()
-- Stages built for any level settle their coplanar surfaces (no flicker).
local map = workspace:FindFirstChild("Map")
if map then
	ZFight.watch(map)
end

-- Player profiles: load, save, session lock. The farm rules give the data its shape.
PlayerData.start(FarmSave.hooks(function(line: string)
	warn(line)
end))

print(Config.LogPrefix, "server started")
