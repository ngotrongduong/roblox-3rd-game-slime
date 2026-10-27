-- Swaps the part-built fences of a home plot for low-poly fence sections of the prop kit (the owner,
-- 2026-10-27: fences and area signs low poly too). Each fence run (found by its rails or panels)
-- is cut into bays and every bay gets one section model, its single mesh part stretched to the bay's
-- length (a MeshPart may be sized freely); the old posts, caps, rails, panels and pickets go. Kit
-- sections (ServerStorage.PropKit) are one bay with a post at each end, long side along X. Run in
-- Edit mode through MCP after replace_props and before stud_floor. Rerunnable after a rebuild.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local plot = workspace.Map["Plot" .. PLOT]
local kit = ServerStorage:FindFirstChild("PropKit")

-- where (an area model, or "Village" for the plot's own fence), which parts are the runs, which kit
-- section, the bay length to aim for (nil: one bay per run part, `extend` studs longer), the
-- section's height and depth, and every part name of the old fence
type Fence = {
	area: string,
	runs: string,
	kit: string,
	bay: number?,
	extend: number?,
	height: number,
	sink: number?, -- how far the section reaches below the floor's top (to hide the floor's edge)
	depth: number,
	old: { string },
}
local FENCES: { Fence } = {
	{
		area = "Village",
		runs = "FencePanel",
		kit = "PalisadeFence",
		extend = 3.4, -- (the panel plus its post, and a little more so the posts of neighbouring bays overlap)
		height = 11.5,
		depth = 2.6,
		sink = 1,
		old = { "FencePanel", "FenceRail", "FencePost", "FencePostCap" },
	},
	{ area = "GardenL1", runs = "Rail", kit = "PicketFence", bay = 4, height = 2.3, depth = 0.5, old = { "Rail", "Picket" } },
	{
		area = "BreedingL1",
		runs = "FenceRail",
		kit = "RanchFence",
		bay = 4,
		height = 4.4,
		depth = 1.2,
		old = { "FenceRail", "FencePost", "PostCap" },
	},
	{ area = "TrainingL1", runs = "FenceRail", kit = "RanchFence", bay = 4, height = 2.8, depth = 1, old = { "FenceRail", "FencePost" } },
}

local function container(name: string): Instance?
	if name == "Village" then
		return plot:FindFirstChild("Village")
	end
	return plot:FindFirstChild(name)
end

-- The kit section's mesh part, and whether its long side is its X (else its Z).
local function sectionOf(key: string): (MeshPart?, boolean)
	local m = kit and kit:FindFirstChild(key)
	local mesh = m and m:FindFirstChildWhichIsA("MeshPart", true)
	if not mesh then
		return nil, true
	end
	return mesh, mesh.Size.X >= mesh.Size.Z
end

local placed, missing = 0, {}
for _, f in FENCES do
	local parent = container(f.area)
	local mesh, alongX = sectionOf(f.kit)
	if not parent then
		continue
	end
	if not mesh then
		table.insert(missing, f.kit)
		continue
	end
	local base = Layout.plotFrame(PLOT).Position.Y + GROUND
	-- the runs: one per straight piece of fence (rails at two heights count once)
	local seen = {}
	local runs = {}
	for _, p in parent:GetChildren() do
		if p.Name == f.runs and p:IsA("BasePart") then
			local dir, len
			if p.Size.X >= p.Size.Z then
				dir, len = p.CFrame.RightVector, p.Size.X
			else
				dir, len = p.CFrame.LookVector, p.Size.Z
			end
			dir = Vector3.new(dir.X, 0, dir.Z).Unit
			local key = string.format("%d,%d,%d", math.round(p.Position.X), math.round(p.Position.Z), math.round(len))
			if not seen[key] then
				seen[key] = true
				table.insert(runs, { mid = Vector3.new(p.Position.X, base, p.Position.Z), dir = dir, len = len + (f.extend or 0) })
			end
		end
	end
	if #runs == 0 then
		continue -- (already swapped: the old fence is gone)
	end
	local folder = Instance.new("Folder")
	folder.Name = "Fence"
	for _, r in runs do
		local n = if f.bay then math.max(1, math.round(r.len / f.bay)) else 1
		local bay = r.len / n
		for k = 1, n do
			local centre = r.mid + r.dir * ((k - 0.5) * bay - r.len / 2) + Vector3.new(0, f.height / 2 - (f.sink or 0), 0)
			local s = mesh:Clone()
			s.Name = f.kit
			s.Anchored = true
			s.CanCollide = true
			local frame = CFrame.fromMatrix(centre, r.dir, Vector3.yAxis)
			if alongX then
				s.Size = Vector3.new(bay, f.height, f.depth)
				s.CFrame = frame
			else
				s.Size = Vector3.new(f.depth, f.height, bay)
				s.CFrame = frame * CFrame.Angles(0, math.rad(90), 0)
			end
			s.Parent = folder
			placed += 1
		end
	end
	local old = {}
	for _, n in f.old do
		old[n] = true
	end
	for _, p in parent:GetChildren() do
		if old[p.Name] and p:IsA("BasePart") then
			p:Destroy()
		end
	end
	local prev = parent:FindFirstChild("Fence")
	if prev then
		prev:Destroy()
	end
	folder.Parent = parent
	task.wait()
end
return "fence sections: " .. placed .. (if #missing > 0 then " (missing in kit: " .. table.concat(missing, ", ") .. ")" else "")
