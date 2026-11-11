-- Builds the Slime Dungeon's monster kit (assets/MonsterKit.rbxm, Rojo puts it in ReplicatedStorage.MonsterKit) from the
-- place the owner imported the monsters into (File > Import 3D of art/models/monsters/<Name>/<Name>.fbx, then moved into
-- ReplicatedStorage.MonsterKit and saved): every model Config.Dungeon.Looks names. A missing one is named in the output
-- and the client draws its stand-in. Run after the place is saved:
--   lune run tools/kit/export_monsters.luau [place]      (default assets/raw/Publish.rbxl)
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance

local Config = require("../../src/shared/Config")

local SOURCE = process.args[1] or "assets/raw/Publish.rbxl"
local OUT = "assets/MonsterKit.rbxm"

local place = roblox.deserializePlace(fs.readFile(SOURCE))
local from = place:GetService("ReplicatedStorage"):FindFirstChild("MonsterKit")
if not from then
	print("no ReplicatedStorage.MonsterKit in " .. SOURCE)
	process.exit(1)
end

local kit = Instance.new("Folder")
kit.Name = "MonsterKit"
local lines = {}
local names = {}
for _, look in Config.Dungeon.Looks do
	-- (a monster slime's mesh is loaded from Roblox by the client: it is not in the kit)
	if not (look :: any).clips then
		table.insert(names, look.model)
	end
end
table.sort(names)
for _, name in names do
	local model = from:FindFirstChild(name)
	if model then
		model:Clone().Parent = kit
		local parts = 0
		for _, inst in model:GetDescendants() do
			if inst:IsA("BasePart") then
				parts += 1
			end
		end
		table.insert(lines, string.format("  %s  %d parts", name, parts))
	else
		table.insert(lines, "  " .. name .. "  MISSING")
	end
end

local data = roblox.serializeModel({ kit })
fs.writeFile(OUT, data)
print(string.format("%s  %.1f KB\n%s", OUT, #data / 1024, table.concat(lines, "\n")))
