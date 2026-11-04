-- Brings the owner's rigged creatures of Egg Heist (C:\roblox 2nd game\assets\Pets|Guardians\<Name>.rbxm, read only)
-- into this game, two ways:
--   lune run tools/kit/eggheist_models.luau studio <out.luau> <Folder> <Pets/Name> ...
--     writes a Luau script that rebuilds those models in an open Studio place (under ReplicatedStorage.<Folder>):
--     a skinned MeshPart from its mesh id (AssetService), its SurfaceAppearance and its bones. The meshes and
--     textures are the owner's own uploads, so they load in his places. Run the script with tools/studio_mcp.js.
--   lune run tools/kit/eggheist_models.luau kit <Pets/Name> ...
--     writes them into assets/MonsterKit.rbxm (ReplicatedStorage.MonsterKit), each model named after its file.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local SOURCE = "C:/roblox 2nd game/assets/"
local KIT = "assets/MonsterKit.rbxm"

local function load(name: string)
	local list = roblox.deserializeModel(fs.readFile(SOURCE .. name .. ".rbxm"))
	local model = list[1]
	assert(model and model:IsA("Model"), name .. ": no model in the file")
	local short = string.match(name, "[^/]+$") :: string
	model.Name = short
	return model
end

local function get(item, property)
	local ok, value = pcall(function()
		return (item :: any)[property]
	end)
	return if ok then value else nil
end

-- A Content as a Luau expression (nil when it is empty).
local function content(value): string?
	if value == nil then
		return nil
	end
	local uri = string.match(tostring(value), "Uri=([^%)]+)")
	return if uri then `Content.fromUri("{uri}")` else nil
end

local function cframe(cf): string
	local c = { cf:GetComponents() }
	for i, v in c do
		c[i] = string.format("%.6g", v)
	end
	return `CFrame.new({table.concat(c, ", ")})`
end

local function vector(v): string
	return string.format("Vector3.new(%.6g, %.6g, %.6g)", v.X, v.Y, v.Z)
end

local function studio(out: string, folder: string, names: { string })
	local lines = {
		"-- Written by tools/kit/eggheist_models.luau: rebuilds Egg Heist creatures in this place.",
		"local AssetService = game:GetService(\"AssetService\")",
		`local folder = game.ReplicatedStorage:FindFirstChild("{folder}") or Instance.new("Folder")`,
		`folder.Name = "{folder}"`,
		"folder.Parent = game.ReplicatedStorage",
		"local made = {}",
	}
	for _, name in names do
		local model = load(name)
		local part = model.PrimaryPart or model:FindFirstChildWhichIsA("MeshPart")
		assert(part and part:IsA("MeshPart"), name .. ": no MeshPart")
		local mesh = content(get(part, "MeshContent"))
		assert(mesh, name .. ": no mesh id")
		table.insert(lines, "do")
		table.insert(lines, `\tlocal old = folder:FindFirstChild("{model.Name}") if old then old:Destroy() end`)
		table.insert(lines, `\tlocal model = Instance.new("Model") model.Name = "{model.Name}"`)
		table.insert(lines, `\tlocal part = AssetService:CreateMeshPartAsync({mesh})`)
		table.insert(lines, `\tpart.Name = "{part.Name}" part.Size = {vector(part.Size)} part.CFrame = {cframe(part.CFrame)}`)
		table.insert(lines, "\tpart.Anchored = true part.CanCollide = false part.CanQuery = false part.CanTouch = false")
		local texture = content(get(part, "TextureContent"))
		if texture then
			table.insert(lines, `\tpart.TextureContent = {texture}`)
		end
		local look = part:FindFirstChildWhichIsA("SurfaceAppearance")
		if look then
			table.insert(lines, "\tlocal look = Instance.new(\"SurfaceAppearance\")")
			for _, map in { "ColorMapContent", "NormalMapContent", "MetalnessMapContent", "RoughnessMapContent" } do
				local value = content(get(look, map))
				if value then
					table.insert(lines, `\tlook.{map} = {value}`)
				end
			end
			table.insert(lines, "\tlook.Parent = part")
		end
		-- the bones, parents first
		local index = 0
		local function bones(parent, parentVar)
			for _, child in parent:GetChildren() do
				if child:IsA("Bone") then
					index += 1
					local var = `b{index}`
					table.insert(lines, `\tlocal {var} = Instance.new("Bone") {var}.Name = "{child.Name}" {var}.CFrame = {cframe(child.CFrame)} {var}.Parent = {parentVar}`)
					bones(child, var)
				end
			end
		end
		bones(part, "part")
		table.insert(lines, "\tpart.Parent = model model.PrimaryPart = part model.Parent = folder")
		table.insert(lines, `\ttable.insert(made, "{model.Name}")`)
		table.insert(lines, "end")
	end
	table.insert(lines, "return table.concat(made, \", \")")
	fs.writeFile(out, table.concat(lines, "\n") .. "\n")
	print(`[GooLineage] wrote {out}: {#names} models`)
end

local function kit(names: { string })
	local holder = roblox.Instance.new("Folder")
	holder.Name = "MonsterKit"
	for _, name in names do
		local model = load(name)
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				item.Anchored = true
				item.CanCollide = false
				item.CanQuery = false
				item.CanTouch = false
			end
		end
		model.Parent = holder
	end
	fs.writeFile(KIT, roblox.serializeModel({ holder }))
	print(`[GooLineage] wrote {KIT}: {#names} models`)
end

local mode = process.args[1]
if mode == "studio" then
	local names = table.clone(process.args)
	local out, folder = names[2], names[3]
	table.move(names, 4, #names, 1, names)
	for _ = 1, 3 do
		table.remove(names)
	end
	studio(out, folder, names)
elseif mode == "kit" then
	local names = table.clone(process.args)
	table.remove(names, 1)
	kit(names)
else
	print("usage: lune run tools/kit/eggheist_models.luau studio <out.luau> <Folder> <Pets/Name> ... | kit <Pets/Name> ...")
	process.exit(1)
end
