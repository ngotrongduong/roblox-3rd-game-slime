-- Swaps the greybox's code-built trees (a cylinder trunk and a ball crown) for the owner's own tree
-- models (the owner, 2026-10-27: "replace the trees you built with trees from my assets"), kept in
-- ServerStorage.OwnerKit. Rim trees round the valley become a mixed wood of tall pines and broadleaf
-- trees; the Wild Garden's trees follow their quarter (meadow broadleaf, mushroom grove vine trees and
-- banyans, ember garden windswept pines, frost glade frozen trees). Same spots and about the same
-- heights. Run in Edit mode through MCP; build_greybox.luau places the same trees on a rebuild.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Layout = require(ReplicatedStorage.Shared.Layout)

local kit = ServerStorage.OwnerKit
local rng = Random.new(27)
local KINDS = {
	rim = { "TallPineLarge", "TallPineDense", "BroadleafTree", "TallPineSparse", "TallPineSlender", "TallPineWindswept" },
	meadow = { "BroadleafTree", "BanyanTree", "BroadleafTree" },
	mushroom = { "VineTree", "BanyanTree" },
	ember = { "TallPineWindswept", "TallPineSparse" },
	frost = { "FrozenDeadTree", "TallPineSlender" },
}

local function place(parent: Instance, key: string, foot: Vector3, height: number)
	local m = (kit:FindFirstChild(key) :: Model):Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			if d:IsA("MeshPart") then
				d.DoubleSided = true -- (one-sided leaves showed holes from behind)
			end
		end
	end
	local _, size0 = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * height / size0.Y)
	local pivot = m:GetPivot()
	m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) * pivot.Rotation)
	local box, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (foot + Vector3.new(0, size.Y / 2, 0) - box.Position))
	m.Name = "Tree"
	m.Parent = parent
end

local count = 0
local function swap(folder: Instance, kindOf: (Vector3) -> string)
	for _, trunk in folder:GetChildren() do
		if trunk.Name == "Trunk" and trunk:IsA("BasePart") then
			-- the trunk stands on the ground: its foot is its centre less half its length
			local foot = trunk.Position - Vector3.new(0, trunk.Size.X / 2, 0)
			local scale = trunk.Size.X / 9
			local kinds = KINDS[kindOf(foot)]
			place(folder, kinds[rng:NextInteger(1, #kinds)], foot, 16 * scale)
			trunk:Destroy()
			count += 1
		end
	end
	for _, crown in folder:GetChildren() do
		if crown.Name == "Crown" then
			crown:Destroy()
		end
	end
	task.wait()
end

local map = workspace.Map
local rim = map:FindFirstChild("RimTrees")
if rim then
	swap(rim, function()
		return "rim"
	end)
end
local wild = map:FindFirstChild("WildGarden")
if wild then
	swap(wild, function(pos: Vector3): string
		local q = Layout.quarterAt(pos)
		return if q then q.id else "meadow"
	end)
end
return "trees swapped: " .. count
