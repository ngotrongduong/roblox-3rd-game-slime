-- A plain picture of the Market without Studio's screen (a minimised Studio shoots white and an agent may not restore the owner's window): one ray a
-- pixel against the real parts and terrain, a simple sun, each part's own Color, kit meshes coloured by their model's name. It judges shape, placing
-- and orientation only; it says nothing of textures, light or water. Run in Edit mode with CAM, a text file "cx cy cz lx ly lz width height fov" in
-- the market's local studs (y above the ground); it returns the picture, one line per row, RLE of "<count>.<3 hex digits>,":
--   node tools/studio_mcp.js run tools/map/market_raypreview.luau <studio_id> Edit CAM=<file> > out.txt   then   node tools/map/market_rle_to_png.js out.txt out.png
-- (the Dungeon portal shows if tools/map/preview_portal.luau has built its preview)
-- CanQuery is set on the Market's parts for the pictures and put back at the end.
-- (an MCP `run` cannot require the shared modules - "Capabilities: Network": Layout.marketFrame() by hand)
local F = CFrame.new(0, 0, -500) * CFrame.Angles(0, math.pi, 0)
local G = 2
local nums = {}
for n in string.gmatch(CAM, "[-%d%.]+") do
	table.insert(nums, tonumber(n))
end
local cam = F * CFrame.lookAt(Vector3.new(nums[1], nums[2] + G, nums[3]), Vector3.new(nums[4], nums[5] + G, nums[6]))
local W, H, fov = nums[7], nums[8], nums[9]
local tanV = math.tan(math.rad(fov) / 2)
local tanH = tanV * W / H

local changed = {}
for _, folder in { workspace.Map.Market, workspace.Map:FindFirstChild("RimTrees"), workspace:FindFirstChild("PortalPreview") } do
	if folder then
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") and not d.CanQuery then
				d.CanQuery = true
				table.insert(changed, d)
			end
		end
	end
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local skip = {}
for _, folder in { workspace.Map.Market, workspace:FindFirstChild("PortalPreview") } do
	for _, d in if folder then folder:GetDescendants() else {} do
		if d:IsA("BasePart") and d.Transparency >= 1 then
			table.insert(skip, d)
		end
	end
end
table.insert(skip, workspace:FindFirstChild("KitViewer"))
params.FilterDescendantsInstances = skip

local MESH = {
	QtCommonTree_1 = Color3.fromRGB(110, 170, 60), QtCommonTree_3 = Color3.fromRGB(110, 170, 60), QtCommonTree_5 = Color3.fromRGB(110, 170, 60),
	QtBush_Common_Green = Color3.fromRGB(90, 160, 70), QtBush_Common_Flowers = Color3.fromRGB(230, 130, 170),
	QtFlower_3_Group = Color3.fromRGB(240, 140, 180), QtFlower_4_Group = Color3.fromRGB(250, 240, 200), DokiFlower1 = Color3.fromRGB(250, 220, 90), DokiFlower2 = Color3.fromRGB(240, 240, 240),
	DokiFlower3 = Color3.fromRGB(160, 110, 220), DokiFlower4 = Color3.fromRGB(160, 110, 220), QtFern_1 = Color3.fromRGB(100, 180, 70), DokiGrass2 = Color3.fromRGB(110, 180, 70), DokiGrass7 = Color3.fromRGB(110, 180, 70),
	QtClover_1 = Color3.fromRGB(150, 200, 90), QtRock_Medium_1 = Color3.fromRGB(160, 160, 155), QtRock_Medium_2 = Color3.fromRGB(160, 160, 155), QtRock_Medium_3 = Color3.fromRGB(160, 160, 155),
	DryStoneWall = Color3.fromRGB(140, 140, 135), CoinBasket = Color3.fromRGB(210, 170, 90), CoinStack = Color3.fromRGB(245, 195, 70), MoneySack = Color3.fromRGB(246, 190, 56),
	WoodLantern = Color3.fromRGB(70, 70, 74), MoneyBagCrest = Color3.fromRGB(50, 90, 190), CrownCrest = Color3.fromRGB(130, 60, 170), WoodBarrel = Color3.fromRGB(150, 100, 50),
	PinkDaisies = Color3.fromRGB(240, 150, 190), WoodBench = Color3.fromRGB(190, 130, 66), RanchFence = Color3.fromRGB(130, 85, 50),
	Flagstone = Color3.fromRGB(196, 192, 182), portal_crystal = Color3.fromRGB(110, 220, 240), bush_tall_grass = Color3.fromRGB(110, 180, 70),
	WeaponRack = Color3.fromRGB(150, 110, 70), SwordBarrel = Color3.fromRGB(150, 100, 50), ArmorStand = Color3.fromRGB(140, 145, 155), ToolRack = Color3.fromRGB(150, 110, 70),
}
local TERRAIN = {
	[Enum.Material.Grass] = Color3.fromRGB(112, 182, 66),
	[Enum.Material.Sandstone] = Color3.fromRGB(196, 150, 96),
	[Enum.Material.Asphalt] = Color3.fromRGB(130, 90, 60),
	[Enum.Material.Sand] = Color3.fromRGB(232, 210, 150),
	[Enum.Material.Mud] = Color3.fromRGB(96, 98, 40),
	[Enum.Material.Rock] = Color3.fromRGB(138, 132, 122),
}
local SUN = Vector3.new(0.4, 0.8, -0.45).Unit
local function shade(hit: RaycastResult): Color3
	local c: Color3
	if hit.Instance == workspace.Terrain then
		c = TERRAIN[hit.Material] or Color3.fromRGB(200, 60, 200)
	elseif hit.Instance:IsA("MeshPart") then
		local name = hit.Instance.Parent and hit.Instance.Parent.Name or ""
		if name == "body" or name == "Geometry" then
			name = hit.Instance.Parent.Parent.Name
		end
		c = MESH[name] or MESH[hit.Instance.Name] or hit.Instance.Color
		if string.find(name, "Tree") then
			c = Color3.fromRGB(110, 170, 60)
		end
		if string.find(string.lower(hit.Instance.Name), "bark") then
			c = Color3.fromRGB(120, 80, 50)
		end
	else
		c = hit.Instance.Color
	end
	local light = 0.5 + 0.55 * math.max(0, hit.Normal:Dot(SUN))
	return Color3.new(math.min(c.R * light, 1), math.min(c.G * light, 1), math.min(c.B * light, 1))
end
local HEX = "0123456789abcdef"
local function hex4(v: number): string
	local i = math.clamp(math.floor(v * 15.99), 0, 15) + 1
	return string.sub(HEX, i, i)
end

local rows = {}
for y = 0, H - 1 do
	local row = {}
	local last, run = nil, 0
	for x = 0, W - 1 do
		local nx = ((x + 0.5) / W * 2 - 1) * tanH
		local ny = (1 - (y + 0.5) / H * 2) * tanV
		local dir = cam:VectorToWorldSpace(Vector3.new(nx, ny, -1).Unit)
		local hit = workspace:Raycast(cam.Position, dir * 700, params)
		local code
		if hit then
			local c = shade(hit)
			code = hex4(c.R) .. hex4(c.G) .. hex4(c.B)
		else
			code = "9cf"
		end
		if code == last then
			run += 1
		else
			if last then
				table.insert(row, run .. "." .. last)
			end
			last, run = code, 1
		end
	end
	table.insert(row, run .. "." .. last)
	table.insert(rows, table.concat(row, ","))
	if y % 12 == 0 then
		task.wait()
	end
end
for _, d in changed do
	d.CanQuery = false
end
return W .. " " .. H .. "\n" .. table.concat(rows, "\n")
