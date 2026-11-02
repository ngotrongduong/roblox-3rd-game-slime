-- generate_mesh hands flat things back turned about Y inside their own mesh, so the kit box is a diagonal. This turns the market's flat
-- kit models (the dry-stone wall, the two crests, the bench) so their long side lies along X, with the pivot at the middle of the foot, and prints every market model's real triangles.
-- Run once after tools/kit/intake.luau: node tools/studio_mcp.js run tools/map/market_kit_square.luau <studio_id> Edit
local AssetService = game:GetService("AssetService")
local kit = game:GetService("ServerStorage").PropKit
local out = {}
local function vertices(part: MeshPart): ({ Vector3 }, number)
	local mesh = AssetService:CreateEditableMeshAsync(part.MeshContent)
	local list = {}
	for _, id in mesh:GetVertices() do
		table.insert(list, mesh:GetPosition(id))
	end
	local faces = #mesh:GetFaces()
	mesh:Destroy()
	return list, faces
end
local function bounds(list: { Vector3 })
	local lo, hi = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, v in list do
		lo, hi = lo:Min(v), hi:Max(v)
	end
	return lo, hi
end
for _, name in { "DryStoneWall", "MoneyBagCrest", "CrownCrest", "WoodBench" } do
	local model = kit[name]
	local part = model:FindFirstChildWhichIsA("MeshPart", true)
	local list = vertices(part)
	local lo, hi = bounds(list)
	local mid = (lo + hi) / 2
	-- the mesh's own units to studs along each axis
	local unit = part.MeshSize
	local sx, sz = part.Size.X / unit.X, part.Size.Z / unit.Z
	-- the principal axis on the floor
	local xx, zz, xz = 0, 0, 0
	for _, v in list do
		local x, z = (v.X - mid.X) * sx, (v.Z - mid.Z) * sz
		xx += x * x
		zz += z * z
		xz += x * z
	end
	local angle = 0.5 * math.atan2(2 * xz, xx - zz)
	-- turn by this about Y so the long side lies along X: a point (x, z) goes to x cos + z sin along the new X
	local turn = CFrame.Angles(0, angle, 0)
	local cx, cz = math.cos(angle), math.sin(angle)
	local depthSum = 0
	for _, v in list do
		local x, z = (v.X - mid.X) * sx, (v.Z - mid.Z) * sz
		depthSum += -x * cz + z * cx
	end
	-- (no flip: the generator's own front already looks along -Z; the relief sum is only printed)
	model.PrimaryPart = nil
	part.CFrame = CFrame.new(part.Position) * turn
	local box, size = model:GetBoundingBox()
	-- (GetBoundingBox follows the pivot's axes: start from a square pivot)
	model.WorldPivot = CFrame.new(part.Position)
	box, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	model:PivotTo(CFrame.new())
	table.insert(out, string.format("%s turned %.0f deg, relief sum %.0f: box %.1f x %.1f x %.1f", name, math.deg(angle), depthSum, size.X, size.Y, size.Z))
end
for _, name in { "DryStoneWall", "MoneyBagCrest", "CrownCrest", "WoodBench", "CoinStack", "MoneySack", "WoodLantern", "MarketStallBlue", "MarketStallVip" } do
	local part = kit[name]:FindFirstChildWhichIsA("MeshPart", true)
	local _, faces = vertices(part)
	table.insert(out, name .. " triangles " .. faces .. " parts " .. #kit[name]:GetDescendants())
end
return table.concat(out, "\n")
