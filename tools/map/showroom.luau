-- Lays kit models in rows at y = 3300 (far from everything) for a look at real size, to shoot from the front.
-- Run in Edit with LIST = "ModelA,ModelB,..." (a string; each from ServerStorage.WildKit or .Kit.WildKit or .LibraryKit),
-- HEIGHT = a number (every model scaled to it), PER = models per row. Destroys the previous showroom first.
local SS = game:GetService("ServerStorage")
local list = (LIST :: any)
local height = tonumber(HEIGHT) or 6
local per = tonumber(PER) or 10
local old = workspace:FindFirstChild("Showroom")
if old then
	old:Destroy()
end
local room = Instance.new("Folder")
room.Name = "Showroom"
room.Parent = workspace
local floor = Instance.new("Part")
floor.Anchored = true
floor.Size = Vector3.new(400, 1, 200)
floor.Position = Vector3.new(0, 3299.5, 0)
floor.Color = Color3.fromHex("#62ae3c")
floor.Parent = room
local function find(name: string): Instance?
	for _, parent in { SS:FindFirstChild("WildKit"), SS:FindFirstChild("LibraryKit"), SS:FindFirstChild("NatureKit"), SS:FindFirstChild("PropKit"), SS:FindFirstChild("OwnerKit") } do
		local found = parent and parent:FindFirstChild(name)
		if found then
			return found
		end
	end
	return nil
end
local n = 0
local missing = {}
for name in string.gmatch(list, "[^,]+") do
	local src = find(name)
	if src then
		local m = src:Clone()
		m.Parent = room
		local _, size = m:GetBoundingBox()
		m:ScaleTo(height / size.Y)
		local b2, s2 = m:GetBoundingBox()
		local row, col = n // per, n % per
		local target = Vector3.new(-per * 4 + col * 8, 3300 + s2.Y / 2, 40 - row * 14)
		m:PivotTo(m:GetPivot() + (target - b2.Position))
		n += 1
	else
		table.insert(missing, name)
	end
end
return "placed " .. n .. " missing " .. table.concat(missing, ",")
