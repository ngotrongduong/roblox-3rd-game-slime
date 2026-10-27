-- Starts the server services. The server decides everything; clients draw and ask.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FarmSave = require(ReplicatedStorage.Shared.FarmSave)
local PlayerData = require(script.Parent.PlayerData)

-- Player profiles: load, save, session lock. The farm rules give the data its shape.
PlayerData.start(FarmSave.hooks(function(line: string)
	warn(line)
end))

print(Config.LogPrefix, "server started")
