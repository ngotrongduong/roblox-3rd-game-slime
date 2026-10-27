-- A spawn point for play tests in the work place, at the area being worked on (the owner, 2026-10-27:
-- start each play test next to the fishing pond, not at the Market). The Market's own spawn is
-- switched off while this one stands. Move it by changing AREA and rerunning; DEV_SPAWN = false
-- puts the Market's spawn back. Run in Edit mode through MCP, then save the place (Ctrl+S).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local DEV_SPAWN = true
local PLOT = 5
-- the area worked on (col, row), or nil for the plaza in the middle (all areas round it)
local AREA: { number }? = nil
local OFFSET = if AREA then CFrame.new(-3, 0, -24) else CFrame.new(0, 0, -16) -- in front of the dock, or the plaza's south edge

local market = workspace.Map:FindFirstChild("Market")
local marketSpawn = market and market:FindFirstChild("Spawn")
local old = workspace:FindFirstChild("DevSpawn")
if old then
	old:Destroy()
end
if marketSpawn and marketSpawn:IsA("SpawnLocation") then
	marketSpawn.Enabled = not DEV_SPAWN
end
if not DEV_SPAWN then
	return "dev spawn off, the Market's spawn is back"
end

local area = if AREA then Layout.plotAreaFacing(PLOT, AREA[1], AREA[2]) else Layout.plotFrame(PLOT)
local at = area * OFFSET
local spawn = Instance.new("SpawnLocation")
spawn.Name = "DevSpawn"
spawn.Size = Vector3.new(4, 0.2, 4)
-- facing the dock (+Z of the area)
spawn.CFrame = CFrame.lookAt(at.Position, (area * CFrame.new(if AREA then -3 else 0, 0, 0)).Position) + Vector3.new(0, (Config.Map.GroundY or 2) + 0.1, 0)
spawn.Anchored = true
spawn.CanCollide = false
spawn.Transparency = 1
spawn.Duration = 0 -- no force field
spawn.Neutral = true
for _, d in spawn:GetChildren() do
	if d:IsA("Decal") then
		d:Destroy()
	end
end
spawn.Parent = workspace
return "dev spawn at " .. tostring(spawn.Position)
