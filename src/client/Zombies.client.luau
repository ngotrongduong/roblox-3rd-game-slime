--!strict
-- Starts the zombies of the world: the groups outside the village that live round their places, the teams marching to them
-- and back, and the fights drawn against them. The screens (UiTeams, UiSquad) are started by VillageUI, which owns the screen.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ZombieFight = require(script.Parent.ZombieFight)
local ZombieMarch = require(script.Parent.ZombieMarch)
local ZombieWorld = require(script.Parent.ZombieWorld)

ZombieWorld.start()
ZombieMarch.start()
ZombieFight.start()
print(Config.LogPrefix, "zombies client started")
