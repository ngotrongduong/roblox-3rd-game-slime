--!strict
-- The one place where a Slime Dungeon monster gets its look. For now every monster is a body in the rotten zombie skin
-- with its outline in the colour of its kind and its height by its role (Config.Dungeon.StandIn, the server's stand-in
-- Parts use the same colours and sizes); when the owner's monster art arrives, only this file changes. An unknown kind or
-- role is never an error: it looks like a plain melee monster.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SkinIds = require(ReplicatedStorage.Shared.SkinIds)
local SlimeLook = require(script.Parent.SlimeLook)
local ZombieLook = require(script.Parent.ZombieLook)

local D = Config.Dungeon
local C = Config.VillageClient

local MonsterLook = {}

export type Monster = { defId: string?, kind: string?, role: string?, name: string? }
export type Look = { model: Model, face: string, size: number }

-- The monster's body at the origin (not parented), its emotion for SlimeActor and its size against a plain one.
function MonsterLook.build(monster: Monster): Look
	local colours: { [string]: string } = D.StandIn.Colours :: any
	local sizes: { [string]: number } = D.StandIn.Sizes :: any
	local colour = colours[monster.kind or ""] or colours.melee
	local size = (sizes[monster.role or ""] or sizes.normal) / sizes.normal
	local model = SlimeLook.build({ Scale = 1, SkinImage = SkinIds.Zombies.rotten })
	local hull = model:FindFirstChild("SlimeBodyOutline")
	if hull and hull:IsA("MeshPart") then
		hull.Color = Color3.fromHex(colour)
	end
	model:ScaleTo(C.BodyHeight * size)
	return { model = model, face = ZombieLook.look("rotten").face, size = size }
end

return MonsterLook
