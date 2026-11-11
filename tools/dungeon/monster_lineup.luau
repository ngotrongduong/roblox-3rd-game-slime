-- Play test, Client datamodel: the 28 monster slimes in four rows (Meadow, Grove, Lava, Ice; Config.Dungeon.Maps order)
-- in front of the player, facing them, drawn by the game's own MonsterLook and SlimeActor. Every 8 seconds they all
-- walk forward, attack, take a hit and walk back; `_G.MonsterLineup.die()` lays them all down, `.clear()` takes them away.
-- Their meshes load from Roblox the first time: run it again after a few seconds if stand-ins show. With
-- `_G.MonsterLineupOnly = "<map id>"` set first (in the same datamodel), only that region's row is made.
--   node tools/studio_mcp.js run tools/dungeon/monster_lineup.luau <studio_id> Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local MonsterLook = require(client:WaitForChild("MonsterLook"))
local SlimeActor = require(client:WaitForChild("SlimeActor"))
local Config = require(ReplicatedStorage.Shared.Config)
local D = Config.Dungeon

if _G.MonsterLineup then
	_G.MonsterLineup.clear()
end

local character = Players.LocalPlayer.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
if not root then
	return "no character"
end
local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
local right = forward:Cross(Vector3.yAxis)
local origin = root.Position - Vector3.new(0, 3, 0) + forward * 30

local folder = Instance.new("Folder")
folder.Name = "MonsterLineup"
folder.Parent = workspace
local actors = {}
local ids = {}
local regions = if _G.MonsterLineupOnly then { _G.MonsterLineupOnly } else { "meadow", "mushroom", "lava", "ice" }
for row, mapId in regions do
	for col, entry in D.Maps[mapId].monsters do
		local def: any = entry
		table.insert(ids, def.id)
		local spot = origin + right * (col - 4) * 12 + forward * (row - 1) * 16
		local look = MonsterLook.build({ defId = def.id, kind = def.kind, role = def.role, name = def.name })
		look.model.Name = "Lineup_" .. def.id
		look.model:PivotTo(CFrame.lookAt(spot, spot - forward))
		look.model.Parent = folder
		local actor = SlimeActor.new(look.model, look.face)
		if actor then
			if look.creature then
				SlimeActor.dress(actor, look.creature)
			end
			table.insert(actors, { actor = actor, spot = spot, id = def.id, clip = look.creature and look.creature.clip })
		end
	end
end
MonsterLook.prepare(ids)

local alive = true
local function walk(a, from: Vector3, to: Vector3, seconds: number)
	local now = workspace:GetServerTimeNow()
	SlimeActor.setTravel(a.actor, from, to, now, now + seconds, false, "walk")
end
task.spawn(function()
	while alive do
		for _, a in actors do
			walk(a, a.spot, a.spot - forward * 4, 2)
		end
		task.wait(2.5)
		for _, a in actors do
			SlimeActor.act(a.actor, "Attack")
		end
		task.wait(1.5)
		for _, a in actors do
			SlimeActor.act(a.actor, "Hit")
		end
		task.wait(1.5)
		for _, a in actors do
			walk(a, a.spot - forward * 4, a.spot, 2)
		end
		task.wait(2.5)
	end
end)

_G.MonsterLineup = {
	actors = actors,
	origin = origin,
	forward = forward,
	right = right,
	die = function()
		alive = false
		for _, a in actors do
			SlimeActor.act(a.actor, "Die")
		end
	end,
	clear = function()
		alive = false
		for _, a in actors do
			SlimeActor.destroy(a.actor)
		end
		folder:Destroy()
		_G.MonsterLineup = nil
	end,
}
local clips = 0
for _, a in actors do
	if a.clip then
		clips += 1
	end
end
return string.format("%d monsters, %d with their own mesh and moves", #actors, clips)
