-- Last pass on a home plot (the owner, 2026-10-27): every tree, bush and prop stays inside the plot's
-- fence (one that reaches past it is moved in, and made smaller if moving is not enough), and the
-- outside foot of the plot's fence is hidden by a skirt of small bushes, rocks and grass tufts from
-- the nature kit and the owner's library. Run in Edit mode through MCP after stud_floor. Rerunnable.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local HALF = Config.Map.PlotSize / 2
local INSIDE = HALF - 2 -- how far from the middle anything inside may reach (the fence is 2 thick)
local plotFrame = Layout.plotFrame(PLOT)
local plot = workspace.Map["Plot" .. PLOT]
local FIXED = { VillageGate = true, Fence = true }

-- ===== keep everything inside the fence =====
local moved, shrunk = 0, 0
for _, d in plot:GetDescendants() do
	if d:IsA("Model") and not FIXED[d.Name] and d.Parent and (d.Parent.Name == "Nature" or d:GetAttribute("Swapped")) then
		local box, size = d:GetBoundingBox()
		local p = plotFrame:PointToObjectSpace(box.Position)
		local r = math.max(size.X, size.Z) / 2
		local over = math.max(math.abs(p.X), math.abs(p.Z)) + r - INSIDE
		if over > 0 then
			-- move in, up to 6 studs, along the axis that is over
			local step = math.min(over, 6)
			local dx = if math.abs(p.X) + r > INSIDE then -math.sign(p.X) * step else 0
			local dz = if math.abs(p.Z) + r > INSIDE then -math.sign(p.Z) * step else 0
			d:PivotTo(d:GetPivot() + plotFrame:VectorToWorldSpace(Vector3.new(dx, 0, dz)))
			moved += 1
			-- still over: smaller, about its foot
			box, size = d:GetBoundingBox()
			p = plotFrame:PointToObjectSpace(box.Position)
			r = math.max(size.X, size.Z) / 2
			local edge = math.max(math.abs(p.X), math.abs(p.Z))
			if edge + r > INSIDE then
				local k = math.max(0.6, (INSIDE - edge) / r)
				local foot = box.Position - Vector3.new(0, size.Y / 2, 0)
				d:ScaleTo(d:GetScale() * k)
				local b2, s2 = d:GetBoundingBox()
				d:PivotTo(d:GetPivot() + (foot - (b2.Position - Vector3.new(0, s2.Y / 2, 0))))
				shrunk += 1
			end
		end
	end
end

-- ===== a skirt of small plants and rocks outside the fence =====
local nature = ServerStorage:FindFirstChild("NatureKit")
local owner = ServerStorage:FindFirstChild("OwnerKit")
local KINDS = {
	{ nature, "Bush", 3.2 },
	{ owner, "PineBerryBush", 3 },
	{ nature, "SmallRocks", 1.4 },
	{ nature, "GrassTuft", 1.8 },
	{ owner, "FlowerShrub", 2.6 },
	{ nature, "BerryBush", 3 },
	{ nature, "MossyBoulder", 2 },
	{ nature, "Fern", 2.2 },
}
local old = plot:FindFirstChild("FenceSkirt")
if old then
	old:Destroy()
end
local skirt = Instance.new("Folder")
skirt.Name = "FenceSkirt"
local rng = Random.new(51)
local placed = 0
local function put(x: number, z: number, i: number)
	local kind = KINDS[(i - 1) % #KINDS + 1]
	local src = kind[1] and kind[1]:FindFirstChild(kind[2])
	if not src or not src:IsA("Model") then
		return
	end
	local m = src:Clone()
	for _, c in m:GetDescendants() do
		if c:IsA("BaseScript") then
			c:Destroy()
		elseif c:IsA("BasePart") then
			c.Anchored = true
		end
	end
	local _, s0 = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * kind[3] * rng:NextNumber(0.85, 1.2) / s0.Y)
	local pivot = m:GetPivot()
	m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) * pivot.Rotation)
	local box, size = m:GetBoundingBox()
	local target = (plotFrame * CFrame.new(x, GROUND + size.Y / 2 - 0.2, z)).Position
	m:PivotTo(m:GetPivot() + (target - box.Position))
	m.Parent = skirt
	placed += 1
end
local OUT = HALF + 2
local GATE = 14 -- the gate's half width, kept clear
local i = 0
for t = -HALF, HALF, 4.5 do
	for _, side in { { t, OUT }, { -OUT, t }, { OUT, t }, { t, -OUT } } do
		local x, z = side[1], side[2]
		if not (z < 0 and math.abs(z) > HALF and math.abs(x) < GATE) then
			i += 1
			put(x + rng:NextNumber(-1, 1), z + math.sign(z) * rng:NextNumber(0, 1.5) * (if math.abs(z) > HALF then 1 else 0), i)
		end
	end
end
skirt.Parent = plot
return string.format("inside: %d moved, %d made smaller; skirt: %d", moved, shrunk, placed)
