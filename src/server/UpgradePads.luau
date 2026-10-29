--!strict
-- The upgrade pads (the owner, 2026-10-29, docs/GAMEPLAY.md §10): a round pad on the ground beside the path
-- at every upgradable place, instead of an E prompt. Stepping onto it upgrades the area one level (paid and
-- saved by VillageRemotes.upgrade); stepping off and on again is the next level. Only the plot's owner is
-- counted. The pad carries its state in attributes (AreaId, Level, MaxLevel, Cost) and the tag "UpgradePad";
-- src/client/UpgradePads.client.luau draws the price over it, green or red for the viewing player.
-- Standing on the pad is a distance check (no Touched events: they miss a standing player).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local VillageRules = require(ReplicatedStorage.Shared.Village)
local Village = require(script.Parent.Village)

local UpgradePads = {}

local P = Config.Pads
local TAG = "UpgradePad"
local HONEY = Color3.fromRGB(214, 150, 70)
local WOOD = Color3.fromRGB(150, 98, 52)
local CREAM = Color3.fromRGB(250, 240, 214)
local GOLD = Color3.fromRGB(240, 190, 70)

type Pad = { part: Part, areaId: string, on: boolean }
local pads: { Pad } = {}

local function disc(parent: Instance, name: string, radius: number, height: number, cf: CFrame, colour: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Color = colour
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- A pad for one area at `at` (world CFrame on the ground's top, y up). Returns a function that sets its level.
function UpgradePads.add(parent: Instance, areaId: string, at: CFrame): (number) -> ()
	local m = Instance.new("Model")
	m.Name = "UpgradePad_" .. areaId
	-- a honey wood rim, a cream face, a gold ring, and two gold chevrons pointing up (toward the area)
	disc(m, "Rim", P.Radius, 0.3, at * CFrame.new(0, 0.15, 0), WOOD)
	disc(m, "RimTop", P.Radius - 0.15, 0.34, at * CFrame.new(0, 0.17, 0), HONEY)
	local pad = disc(m, "Pad", P.Radius - 0.5, 0.38, at * CFrame.new(0, 0.19, 0), CREAM)
	disc(m, "Ring", P.Radius - 0.7, 0.4, at * CFrame.new(0, 0.2, 0), GOLD)
	disc(m, "Face", P.Radius - 0.85, 0.42, at * CFrame.new(0, 0.21, 0), CREAM)
	for k = 0, 1 do
		for _, s in { -1, 1 } do
			local arm = Instance.new("Part")
			arm.Name = "Chevron"
			arm.Size = Vector3.new(1.3, 0.1, 0.34)
			arm.CFrame = at * CFrame.new(s * 0.45, 0.45, 0.45 - k * 0.8) * CFrame.Angles(0, s * math.rad(40), 0)
			arm.Color = GOLD
			arm.Material = Enum.Material.SmoothPlastic
			arm.Anchored = true
			arm.CanCollide = false
			arm.CanTouch = false
			arm.CanQuery = false
			arm.CastShadow = false
			arm.Parent = m
		end
	end
	-- the point the price hangs from (the client's billboard is adorned to it)
	local anchor = Instance.new("Part")
	anchor.Name = "PriceAnchor"
	anchor.Size = Vector3.one * 0.2
	anchor.CFrame = at * CFrame.new(0, 4.4, 0)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.Parent = m
	m.PrimaryPart = pad
	pad:SetAttribute("AreaId", areaId)
	pad:SetAttribute("MaxLevel", Config.Village.MaxLevel)
	pad:SetAttribute("Level", 1)
	pad:SetAttribute("Cost", 0)
	CollectionService:AddTag(pad, TAG)
	m.Parent = parent
	table.insert(pads, { part = pad, areaId = areaId, on = false })

	return function(level: number)
		pad:SetAttribute("Level", level)
		pad:SetAttribute("Cost", if P.FreeUpgrades then 0 else VillageRules.upgradeCost(level))
	end
end

-- Watches the plot owner's feet; `upgrade` is VillageRemotes.upgrade.
function UpgradePads.start(upgrade: (Player, string) -> { ok: boolean, reason: string? })
	local clock = 0
	RunService.Heartbeat:Connect(function(dt: number)
		clock += dt
		if clock < P.CheckSeconds then
			return
		end
		clock = 0
		local feet: { Vector3 } = {}
		local owner: Player? = nil
		for _, player in Players:GetPlayers() do
			if Village.ownsPlot(player) then
				owner = player
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					table.insert(feet, root.Position)
				end
			end
		end
		for _, pad in pads do
			local on = false
			if pad.part.Parent then
				local c = pad.part.Position
				for _, f in feet do
					if
						Vector3.new(f.X - c.X, 0, f.Z - c.Z).Magnitude < P.Radius
						and math.abs(f.Y - c.Y) < P.StandHeight
					then
						on = true
					end
				end
			end
			if on and not pad.on and owner then
				local who = owner
				task.spawn(function()
					local answer = upgrade(who, pad.areaId)
					if not answer.ok then
						print(Config.LogPrefix, "upgrade pad:", pad.areaId, answer.reason)
					end
				end)
			end
			pad.on = on
		end
	end)
end

return UpgradePads
