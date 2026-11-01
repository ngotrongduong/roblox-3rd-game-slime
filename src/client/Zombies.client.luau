--!strict
-- Starts the zombies of the world: the groups outside the village and the fights drawn against them. The screens that
-- send a squad, revive and sell (UiSquad) are started by VillageUI, which owns the screen.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieFight = require(script.Parent.ZombieFight)
local ZombieWorld = require(script.Parent.ZombieWorld)

ZombieWorld.start()
ZombieFight.start()
print(Config.LogPrefix, "zombies client started")
