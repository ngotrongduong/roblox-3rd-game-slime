--!strict
-- Starts the client: it draws what the server decides and sends the player's requests.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiMap = require(script.Parent.UiMap)
local VillageUI = require(script.Parent.VillageUI)

print(Config.LogPrefix, "client started")
VillageUI.start()
-- (after it: the map draws on the screen VillageUI mounts)
UiMap.start()
