-- Starts the client: it draws what the server decides and sends the player's requests.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

print(Config.LogPrefix, "client started")
