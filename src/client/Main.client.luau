--!strict
-- Starts the client: it draws what the server decides and sends the player's requests.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local VillageUI = require(script.Parent.VillageUI)

print(Config.LogPrefix, "client started")
VillageUI.start()
