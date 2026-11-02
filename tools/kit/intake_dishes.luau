-- Takes dish models just made by generate_mesh into ServerStorage.PropKit, fitted like the first dishes
-- (grilledFish, veggieStew, fishVegSoup): scripts removed, parts anchored and non-colliding, each mesh set square,
-- drawn from both sides, scaled so the longest side (world extents) is the given number of studs (default 1.0), the
-- pivot at the middle. Run in Edit mode with SPEC, a text file of lines "Name=Assistant-tag[=longest side]"; a tag
-- of "kit" refits the model already in PropKit:
--   node tools/studio_mcp.js run tools/kit/intake_dishes.luau <studio_id> Edit SPEC=<file>
-- (the dish ids are Config.Food.DishOrder; docs/kit/README.md lists the asset ids)
local CollectionService = game:GetService("CollectionService")

local kit = game:GetService("ServerStorage"):FindFirstChild("PropKit")
local out = {}

local function fit(m: Model, name: string, target: number)
	for _, t in CollectionService:GetTags(m) do
		CollectionService:RemoveTag(m, t)
	end
	m.Name = name
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			if d:IsA("MeshPart") then
				d.DoubleSided = true
			end
		end
	end
	local before = m:GetExtentsSize()
	m:ScaleTo(m:GetScale() * target / math.max(before.X, before.Y, before.Z))
	-- the pivot at the middle of the world-aligned extents, then the model moved to the origin
	local box = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(box.Position)
	m:PivotTo(CFrame.new())
	local after = m:GetExtentsSize()
	table.insert(out, string.format("%s %.2f x %.2f x %.2f (was %.2f x %.2f x %.2f)", name, after.X, after.Y, after.Z, before.X, before.Y, before.Z))
end

for line in string.gmatch(SPEC, "[^\r\n]+") do
	local name, tag, side = string.match(line, "^%s*([%w_]+)%s*=%s*([%w%-]+)=?([%d%.]*)")
	local target = tonumber(side) or 1.0
	if name and tag == "kit" then
		local m = kit:FindFirstChild(name)
		if m then
			fit(m, name, target)
		else
			table.insert(out, name .. " MISSING")
		end
		continue
	end
	local done = false
	for _, m in if name then CollectionService:GetTagged(tag) else {} do
		if m:IsA("Model") and not done then
			-- each mesh part set square (generate_mesh hands it back turned)
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CFrame = CFrame.new(d.Position)
				end
			end
			local old = kit:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			m.Parent = kit
			-- fitted twice: the first pass of a fresh model reads stale extents and scales short
			fit(m, name, target)
			table.remove(out)
			fit(m, name, target)
			done = true
		end
	end
	if name and not done then
		table.insert(out, name .. " MISSING")
	end
end
return table.concat(out, "\n")
