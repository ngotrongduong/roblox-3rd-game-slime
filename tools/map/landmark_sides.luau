-- A village landmark set out as its four-side reference sheets are drawn (docs/areas/village-v2/views/
-- <name>_views_era<N>.webp: front top left, left top right, back bottom left, right bottom right), so the owner sees
-- each shot beside its sheet (the owner, 2026-11-18: "chụp lại cho tôi toàn bộ các tòa nhà đặt bên cạnh hình tham
-- chiếu của chatgpt"). Edit datamodel of the test place, the uploaded meshes loaded first (real_kit_preview.luau):
--   node tools/studio_mcp.js run tools/map/landmark_sides.luau <studio_id> Edit Landmark=src/server/Kitchen.luau Architecture=src/server/Architecture.luau Config=src/shared/Config.luau ConfigMeshyKit=src/shared/ConfigMeshyKit.luau YardKit=src/server/YardKit.luau
-- It builds workspace.<Name>Sides: at each era's last level four copies of the house, each turned so the side its
-- quarter shows faces -z, the yard's fences and gates left out (the sheets draw the house alone), a grey wall behind,
-- the light flat and shadowless as the sheets' (the old values kept as Lighting attributes "Sides*"). It answers each
-- era's camera for screen_capture (the Edit camera's field of view is set to 20). Cleanup, in Edit: destroy
-- workspace's *Sides folders and ServerStorage.GranaryPreview, set each Lighting attribute "Sides<Prop>" back on its
-- property and clear it, Atmosphere.Density from "SidesDensity", and the camera's FieldOfView back to 70.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local LEVELS = { 10, 20, 30, 40, 50 }
local FOV = 20
-- the four quarters as the sheet draws them: the side shown, the turn that brings it to -z, the column, the row
local QUARTERS = {
	{ "front", 0, 0, 1 },
	{ "left", math.pi / 2, 1, 1 },
	{ "back", math.pi, 0, 0 },
	{ "right", -math.pi / 2, 1, 0 },
}
local CUT = { "Fence", "Gate", "PropFence", "PropGate" }
local CORNERS = {
	Vector3.new(-1, -1, -1),
	Vector3.new(1, -1, -1),
	Vector3.new(-1, 1, -1),
	Vector3.new(1, 1, -1),
	Vector3.new(-1, -1, 1),
	Vector3.new(1, -1, 1),
	Vector3.new(-1, 1, 1),
	Vector3.new(1, 1, 1),
}

local server = ServerScriptService.Server
local kit = ServerStorage:FindFirstChild("GranaryPreview")
local stamp = tostring(math.floor(os.clock() * 1000))
local name = Landmark:match("return (%w+)%s*$") .. "Sides"
local temp = {}

local function module(parent: Instance, called: string, source: string): ModuleScript
	local m = Instance.new("ModuleScript")
	m.Name = called .. stamp
	m.Source = source
	m.Parent = parent
	table.insert(temp, m)
	return m
end

module(ReplicatedStorage.Shared, "ConfigMeshyKitPreview", ConfigMeshyKit)
local config = Config:gsub("script%.Parent%.ConfigMeshyKit", "script.Parent.ConfigMeshyKitPreview" .. stamp)
local props = (require :: any)(module(ReplicatedStorage.Shared, "ConfigPreview", config)).LibraryKit.Props
_G.GranaryPreviewKit = {
	find = function(piece: string): Model?
		local src = kit and kit:FindFirstChild(piece)
		local p = props[piece]
		if not (src and p) then
			return nil
		end
		local part = src:FindFirstChildWhichIsA("BasePart")
		-- (a copy keeps the mesh's own name, "MeshPart": the piece's name rides along for `cut`)
		part:SetAttribute("Piece", piece)
		part.Size = Vector3.new(table.unpack(p[1].size))
		local uploaded = part:IsA("MeshPart") and part.MeshId ~= ""
		part.CFrame = CFrame.new(table.unpack(p[1].at)) * CFrame.Angles(0, if uploaded then math.pi else 0, 0)
		return src
	end,
}
module(server, "ArchitecturePreview", Architecture)
if YardKit then
	module(server, "YardKitPreview", YardKit:gsub("require%(script%.Parent%.LibraryKit%)", "(_G.GranaryPreviewKit :: any)"))
end
local source = Landmark:gsub("require%(script%.Parent%.LibraryKit%)", "(_G.GranaryPreviewKit :: any)")
	:gsub("script%.Parent%.Architecture", "script.Parent.ArchitecturePreview" .. stamp)
	:gsub("script%.Parent%.YardKit", if YardKit then "script.Parent.YardKitPreview" .. stamp else "script.Parent.YardKit")
local landmark = (require :: any)(module(server, name, source))
local build, footprint = landmark.build, landmark.footprint

-- the light: flat and shadowless, the old values kept once
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local FLAT = {
	ClockTime = 12,
	GlobalShadows = false,
	Brightness = 1.2,
	Ambient = Color3.fromRGB(150, 150, 155),
	OutdoorAmbient = Color3.fromRGB(165, 165, 170),
	ExposureCompensation = 0,
}
for prop, value in FLAT do
	if Lighting:GetAttribute("Sides" .. prop) == nil then
		Lighting:SetAttribute("Sides" .. prop, (Lighting :: any)[prop])
	end
	(Lighting :: any)[prop] = value
end
if atmosphere then
	if Lighting:GetAttribute("SidesDensity") == nil then
		Lighting:SetAttribute("SidesDensity", atmosphere.Density)
	end
	atmosphere.Density = 0
end
workspace.CurrentCamera.FieldOfView = FOV

for _, f in workspace:GetChildren() do
	if f:IsA("Folder") and f.Name:match("Sides$") then
		f:Destroy()
	end
end
local out = Instance.new("Folder")
out.Name = name

-- the yard's fences and gates out; and where the module gives its house's footprint (the Dock), all round it too
-- (the bank, the boat, the mooring posts)
local function cut(m: Instance, frame: CFrame, level: number)
	local x0, x1, z0, z1
	if footprint then
		x0, x1, z0, z1 = footprint(level)
	end
	for _, d in m:GetDescendants() do
		if d.Parent and x0 and d:IsA("BasePart") then
			local p = frame:PointToObjectSpace(d.Position)
			if p.X < x0 - 2 or p.X > x1 + 2 or p.Z < z0 - 2 or p.Z > z1 + 2 then
				d:Destroy()
			end
		end
		if d.Parent and (d:IsA("BasePart") or d:IsA("Model")) then
			local called = d:GetAttribute("Piece") or d.Name
			for _, prefix in CUT do
				if called:sub(1, #prefix) == prefix then
					d:Destroy()
					break
				end
			end
		end
	end
end

-- the house's box: its width from what is seen above the ground's top, its foot from what is seen at all (the
-- Dock's stilts stand in the water below it); wide flat floors and unseen stops left out
local function bounds(m: Instance, ground: number): (Vector3, Vector3, number)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	local foot = ground
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.99 then
			local floor = d.Size.Y < 1.5 and math.max(d.Size.X, d.Size.Z) > 24
			for _, c in CORNERS do
				local p = d.CFrame * (d.Size / 2 * c)
				if d.Position.Y > ground + 0.6 then
					lo = lo:Min(p)
					hi = hi:Max(p)
				end
				if not floor then
					foot = math.min(foot, p.Y)
				end
			end
		end
	end
	return lo, hi, foot
end

local shots = {}
for e, level in LEVELS do
	local base = Vector3.new(e * 700, 1000, 0)
	local copies = {}
	local w, h = 0, 0
	for i, q in QUARTERS do
		local m = Instance.new("Model")
		m.Name = q[1]
		local frame = CFrame.new(base + Vector3.new(0, 0, i * 150))
		build(m, frame, level)
		cut(m, frame, level)
		local lo, hi, foot = bounds(m, frame.Y)
		m.WorldPivot = CFrame.new((lo.X + hi.X) / 2, foot, (lo.Z + hi.Z) / 2)
		w = math.max(w, hi.X - lo.X, hi.Z - lo.Z)
		h = math.max(h, hi.Y - foot)
		copies[i] = m
		m.Parent = out
		task.wait()
	end
	local deep = w
	w += 8
	h += 6
	-- looking +z the screen's right is world -x: the left column stands at +x
	for i, q in QUARTERS do
		local x = base.X + (if q[3] == 0 then w / 2 else -w / 2)
		copies[i]:PivotTo(CFrame.new(x, base.Y + q[4] * h, base.Z) * CFrame.Angles(0, q[2], 0))
	end
	local wall = Instance.new("Part")
	wall.Name = "Backdrop"
	wall.Anchored = true
	wall.CastShadow = false
	wall.Material = Enum.Material.SmoothPlastic
	wall.Color = Color3.fromRGB(214, 214, 220)
	wall.Size = Vector3.new(1200, 800, 1)
	wall.CFrame = CFrame.new(base.X, base.Y + h, base.Z + deep / 2 + 12)
	wall.Parent = out
	local half = math.tan(math.rad(FOV / 2))
	local view = workspace.CurrentCamera.ViewportSize
	local dist = math.max(h / half, w / (half * view.X / view.Y)) * 1.06 + deep / 2
	local look = Vector3.new(base.X, base.Y + h, base.Z)
	local eye = look - Vector3.new(0, 0, dist)
	table.insert(
		shots,
		string.format("L%d camera %.1f %.1f %.1f look %.1f %.1f %.1f", level, eye.X, eye.Y, eye.Z, look.X, look.Y, look.Z)
	)
end
out.Parent = workspace
for _, m in temp do
	m:Destroy()
end
_G.GranaryPreviewKit = nil
return table.concat(shots, "\n")
