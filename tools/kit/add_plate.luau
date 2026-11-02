-- Gives a PropKit dish that came back without its plate (the generator drops plates now and then) a flat white plate
-- with a blue rim under it, then fits the model again: pivot at the middle, on the origin. Names from NAMES ("A,B"):
--   node tools/studio_mcp.js run tools/kit/add_plate.luau <studio_id> Edit NAMES=<file>
local kit = game:GetService("ServerStorage"):FindFirstChild("PropKit")
local out = {}

local function disc(name: string, diameter: number, thick: number, colour: Color3, at: Vector3, parent: Instance)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(thick, diameter, diameter)
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = colour
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Parent = parent
end

for name in string.gmatch(NAMES, "[^,]+") do
	local m = kit:FindFirstChild(name)
	if not m then
		table.insert(out, name .. " MISSING")
		continue
	end
	for _, old in { "Plate", "PlateRim" } do
		local o = m:FindFirstChild(old)
		if o then
			o:Destroy()
		end
	end
	local box, size = m:GetBoundingBox()
	local ext = m:GetExtentsSize()
	local width = math.max(ext.X, ext.Z, 0.7) * 1.15
	-- the extents' centre and floor, then the plate just under the food
	local c = box.Position
	local floorY = c.Y - ext.Y / 2
	disc("PlateRim", width, 0.04, Color3.fromRGB(70, 120, 200), Vector3.new(c.X, floorY - 0.01, c.Z), m)
	disc("Plate", width * 0.92, 0.05, Color3.fromRGB(248, 246, 240), Vector3.new(c.X, floorY + 0.02, c.Z), m)
	local after = m:GetExtentsSize()
	m:ScaleTo(m:GetScale() / math.max(after.X, after.Z))
	local box2 = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(box2.Position)
	m:PivotTo(CFrame.new())
	local fitted = m:GetExtentsSize()
	table.insert(out, string.format("%s %.2f x %.2f x %.2f", name, fitted.X, fitted.Y, fitted.Z))
end
return table.concat(out, "\n")
