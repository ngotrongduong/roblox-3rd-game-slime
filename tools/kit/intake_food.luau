-- Takes the food models just made by generate_mesh (Workspace models tagged "Assistant-...", named after their prompt)
-- into ServerStorage.FoodKit, one model per Config.Food kind id: scripts removed, parts anchored, each mesh set square,
-- drawn from both sides, scaled to a fixed longest side, the pivot at the middle (carried food rests by its middle).
-- The ripe vegetables are also copied into ServerStorage.CropKit as <Crop>4 for the garden, and the pond's BlueFish is
-- copied as blueFish. Run in Edit mode:
--   node tools/studio_mcp.js run tools/kit/intake_food.luau <studio_id> Edit
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

-- id -> { words in the prompt name, longest side in studs, CropKit prefix or nil, is a fish }
local WANTED = {
	trout = { "trout", 3.25, nil, true }, -- a slim fish: longer than the rest so it does not look tiny
	salmon = { "salmon", 2.8, nil, true },
	pufferfish = { "pufferfish", 2.2, nil, true },
	goldenCarp = { "golden carp", 2.8, nil, true },
	tomato = { "tomato", 2.0, "Tomato", false },
	corn = { "ear of sweet corn", 2.6, "Corn", false },
	pumpkin = { "pumpkin", 2.5, "Pumpkin", false },
	starfruit = { "starfruit", 2.2, "Starfruit", false },
}

local kit = ServerStorage:FindFirstChild("FoodKit")
if not kit then
	kit = Instance.new("Folder")
	kit.Name = "FoodKit"
	kit.Parent = ServerStorage
end
local crops = ServerStorage:FindFirstChild("CropKit")
local out = {}

local function replace(parent: Instance, model: Instance)
	local old = parent:FindFirstChild(model.Name)
	if old then
		old:Destroy()
	end
	model.Parent = parent
end

for id, spec in WANTED do
	local found: Model? = nil
	for _, m in workspace:GetChildren() do
		if m:IsA("Model") and string.find(string.lower(m.Name), spec[1], 1, true) then
			local tagged = false
			for _, tag in CollectionService:GetTags(m) do
				if string.sub(tag, 1, 10) == "Assistant-" then
					tagged = true
				end
			end
			if tagged then
				found = m
				break
			end
		end
	end
	if not found then
		table.insert(out, id .. " MISSING")
		continue
	end
	local m = found :: Model
	for _, tag in CollectionService:GetTags(m) do
		CollectionService:RemoveTag(m, tag)
	end
	m.Name = id
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CFrame = CFrame.new(d.Position)
			if d:IsA("MeshPart") then
				d.DoubleSided = true
			end
		end
	end
	local _, size = m:GetBoundingBox()
	-- a fish comes back facing +Z; turn it a quarter to face +X, side-on, like the pond's koi
	if spec[4] then
		m:PivotTo(m:GetPivot() * CFrame.Angles(0, math.rad(90), 0))
	end
	local longest = math.max(size.X, size.Y, size.Z)
	m:ScaleTo(m:GetScale() * spec[2] / longest)
	-- the pivot at the middle on world axes (not the box's own, or the turn above would be undone)
	local box = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(box.Position)
	m:PivotTo(CFrame.new(0, 0, 0))
	local fitted = m:GetExtentsSize()
	replace(kit, m)
	table.insert(out, string.format("%s %.2f x %.2f x %.2f (was %.2f x %.2f x %.2f)", id, fitted.X, fitted.Y, fitted.Z, size.X, size.Y, size.Z))
	if spec[3] and crops then
		local ripe = m:Clone()
		ripe.Name = spec[3] .. "4"
		replace(crops, ripe)
	end
end

local fishKit = ServerStorage:FindFirstChild("FishKit")
local blue = fishKit and fishKit:FindFirstChild("BlueFish")
if blue then
	local copy = blue:Clone()
	copy.Name = "blueFish"
	replace(kit, copy)
	table.insert(out, "blueFish (FishKit.BlueFish)")
end
return table.concat(out, "\n")
