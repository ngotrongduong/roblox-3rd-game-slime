-- Exports the reusable kit from the work place saved by Studio (assets/raw/MapWork.rbxlx) into
-- model files in the repo (assets/Kit/*.rbxm), so nothing made for the map has to be made again
-- (the owner, 2026-10-27): every low-poly model as it was fitted (size, pivot at the foot, front to
-- -Z), the owner's library models, the nature pack, and the built home plot. Rojo puts the kit in
-- ServerStorage.Kit of the game. Run after the work place is saved (Ctrl+S in Studio):
--   lune run tools/kit/export_kit.luau
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Enum = roblox.Enum

local SOURCE = "assets/raw/MapWork.rbxlx"
local OUT = "assets/Kit"

-- what to export: a path in the place, and the file it goes to
local ITEMS = {
	{ { "ServerStorage", "PropKit" }, "PropKit.rbxm" }, -- props, fences, gates, signs (generate_mesh)
	{ { "ServerStorage", "CropKit" }, "CropKit.rbxm" }, -- carrots and cabbages at four growth stages
	{ { "ServerStorage", "FishKit" }, "FishKit.rbxm" }, -- the pond's fish
	{ { "ServerStorage", "OwnerKit" }, "OwnerKit.rbxm" }, -- the owner's library: trees, benches, fire VFX
	{ { "ServerStorage", "NatureKit" }, "NatureKit.rbxm" }, -- the free "Nature stylized Pack"
	{ { "Workspace", "Map", "Plot5" }, "HomePlot.rbxm" }, -- the finished level-1 home plot (the village)
}

local place = roblox.deserializePlace(fs.readFile(SOURCE))
if not fs.isDir(OUT) then
	fs.writeDir(OUT)
end

local function find(path: { string }): any
	local node: any = place:GetService(path[1])
	for i = 2, #path do
		node = node and node:FindFirstChild(path[i])
	end
	return node
end

-- Things the owner had taken out that an older save may still hold: they never go into the kit.
local DROPPED = { BlobShadow = true }

local lines = {}
for _, item in ITEMS do
	local inst = find(item[1])
	if inst then
		local dropped = 0
		for _, d in inst:GetDescendants() do
			if DROPPED[d.Name] then
				d:Destroy()
				dropped += 1
			end
		end
		-- every mesh drawn from both sides (one-sided leaves showed holes from behind); the home plot's
		-- at full detail too (tidy_plot does the same in Studio)
		for _, d in inst:GetDescendants() do
			if d:IsA("MeshPart") then
				d.DoubleSided = true
				if item[2] == "HomePlot.rbxm" then
					d.RenderFidelity = Enum.RenderFidelity.Precise
				end
			end
		end
		if dropped > 0 then
			table.insert(lines, string.format("  (%d left-overs dropped from %s)", dropped, item[2]))
		end
		local data = roblox.serializeModel({ inst })
		fs.writeFile(OUT .. "/" .. item[2], data)
		table.insert(lines, string.format("%-15s %4d children  %7.1f KB", item[2], #inst:GetChildren(), #data / 1024))
	else
		table.insert(lines, item[2] .. "  MISSING (" .. table.concat(item[1], ".") .. ")")
	end
end
print(table.concat(lines, "\n"))
