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


-- ===== natural groups of rocks and plants outside the fence =====
-- (the owner, 2026-10-27: not a row, but groups placed the way nature would: a big boulder or a big
-- bush with smaller rocks, ferns, flowers and grass round it, set at different distances from the
-- fence, with open stretches between some of them)
local nature = ServerStorage:FindFirstChild("NatureKit")
local owner = ServerStorage:FindFirstChild("OwnerKit")
-- a kit, a model and its height range
type Kind = { any } -- { kit, model name, lowest height, highest height }
local ANCHORS: { Kind } = {
	{ owner, "WideBoulder", 3, 4.5 },
	{ owner, "FlatBoulder", 2.2, 3.2 },
	{ owner, "StackedRocks", 3.5, 5 },
	{ owner, "JaggedRocks", 3, 4.2 },
	{ nature, "MossyBoulder", 2.8, 3.8 },
	{ owner, "PineBerryBush", 3.5, 5 },
	{ nature, "Bush", 3.5, 5 },
	{ nature, "BerryBush", 3.2, 4.5 },
	{ nature, "FloweringBush", 3.2, 4.2 },
}
local SMALL: { Kind } = {
	{ nature, "SmallRocks", 0.8, 1.4 },
	{ nature, "MediumRock", 1.2, 2 },
	{ owner, "FernCluster", 1.6, 2.6 },
	{ nature, "Fern", 1.6, 2.4 },
	{ nature, "GrassTuft", 1.2, 2 },
	{ owner, "WildflowersGrass", 1, 1.8 },
	{ nature, "FlowerPatch", 0.9, 1.5 },
	{ owner, "FlowerShrub", 1.8, 2.8 },
}
local old = plot:FindFirstChild("FenceSkirt")
if old then
	old:Destroy()
end
local skirt = Instance.new("Folder")
skirt.Name = "FenceSkirt"
local rng = Random.new(51)
local placed = 0
local function put(kind: Kind, x: number, z: number)
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
	m:ScaleTo(m:GetScale() * rng:NextNumber(kind[3], kind[4]) / s0.Y)
	local pivot = m:GetPivot()
	m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) * pivot.Rotation)
	local box, size = m:GetBoundingBox()
	local target = (plotFrame * CFrame.new(x, GROUND + size.Y / 2 - 0.3, z)).Position
	m:PivotTo(m:GetPivot() + (target - box.Position))
	m.Parent = skirt
	placed += 1
end
local GATE = 12 -- the gate's half width (and its path), kept clear
-- each side of the plot: its direction along the fence and its outward direction
local SIDES = {
	{ along = Vector3.xAxis, out = Vector3.zAxis },
	{ along = Vector3.xAxis, out = -Vector3.zAxis, gate = true },
	{ along = Vector3.zAxis, out = Vector3.xAxis },
	{ along = Vector3.zAxis, out = -Vector3.xAxis },
}
for _, side in SIDES do
	local t = -HALF + rng:NextNumber(0, 6)
	while t < HALF do
		local gap = rng:NextNumber(7, 14)
		local skip = rng:NextNumber() < 0.12 or (side.gate and math.abs(t) < GATE)
		if not skip then
			-- the group's anchor, 2.5 to 6 studs out from the fence
			local d = HALF + rng:NextNumber(2.5, 6)
			local c = side.along * t + side.out * d
			put(ANCHORS[rng:NextInteger(1, #ANCHORS)], c.X, c.Z)
			-- smaller things round it, most nearer the fence, a few further out
			for _ = 1, rng:NextInteger(3, 6) do
				local a = rng:NextNumber(0, math.pi * 2)
				local r = rng:NextNumber(2, 4.5)
				local p = c + side.along * (math.cos(a) * r) + side.out * (math.sin(a) * r * 0.7)
				local fromFence = p:Dot(side.out) - HALF
				if fromFence > 1.6 and not (side.gate and math.abs(p:Dot(side.along)) < GATE) then
					put(SMALL[rng:NextInteger(1, #SMALL)], p.X, p.Z)
				end
			end
		end
		-- now and then a lone tuft or flower in the open stretch
		if rng:NextNumber() < 0.6 then
			local s = t + gap / 2
			local p = side.along * s + side.out * (HALF + rng:NextNumber(1.8, 4))
			if s < HALF and not (side.gate and math.abs(s) < GATE) then
				put(SMALL[rng:NextInteger(3, #SMALL)], p.X, p.Z)
			end
		end
		t += gap
	end
end
skirt.Parent = plot

-- ===== every mesh drawn from both sides, at full detail =====
-- (the owner, 2026-10-27: trees looked broken, with holes: their leaves are one-sided faces that
-- vanish when seen from behind, and the automatic level of detail thinned the big ones at a distance)
for _, d in plot:GetDescendants() do
	if d:IsA("MeshPart") then
		d.DoubleSided = true
		d.RenderFidelity = Enum.RenderFidelity.Precise
	end
end
return string.format("inside: %d moved, %d made smaller; groups outside: %d models", moved, shrunk, placed)
