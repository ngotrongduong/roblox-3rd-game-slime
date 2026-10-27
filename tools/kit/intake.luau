-- Takes models just made by generate_mesh into ServerStorage.PropKit, fitted for placing: scripts
-- removed, parts anchored, each mesh part set square (generate_mesh hands it back turned), drawn from
-- both sides, the pivot at the middle of the foot. Run in Edit mode through MCP with SPEC, a text file
-- of lines "Name=Assistant-tag" (the tag generate_mesh returned):
--   node tools/studio_mcp.js run tools/kit/intake.luau <studio_id> Edit SPEC=<file>
local CollectionService = game:GetService("CollectionService")

local kit = game:GetService("ServerStorage"):FindFirstChild("PropKit")
local out = {}
for line in string.gmatch(SPEC, "[^\r\n]+") do
	local name, tag = string.match(line, "^%s*([%w_]+)%s*=%s*(%S+)")
	local done = false
	for _, m in if name then CollectionService:GetTagged(tag) else {} do
		if m:IsA("Model") and not done then
			m.Name = name
			for _, d in m:GetDescendants() do
				if d:IsA("BaseScript") then
					d:Destroy()
				elseif d:IsA("BasePart") then
					d.Anchored = true
					d.CFrame = CFrame.new(d.Position)
					if d:IsA("MeshPart") then
						d.DoubleSided = true
					end
				end
			end
			local box, size = m:GetBoundingBox()
			m.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
			m:PivotTo(CFrame.new())
			local old = kit:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			m.Parent = kit
			table.insert(out, string.format("%s %.1f x %.1f x %.1f", name, size.X, size.Y, size.Z))
			done = true
		end
	end
	if name and not done then
		table.insert(out, name .. " MISSING")
	end
end
return table.concat(out, "\n")
