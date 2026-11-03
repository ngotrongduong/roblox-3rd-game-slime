--!strict
-- The waving flag (Config.Flag): put together once from the owner's imported meshes (a pole, its gold finial and the thin
-- cloth with a chain of bones), then cloned wherever a flag stands. The model is tagged "WavingFlag" so every client
-- waves its cloth (client/FlagWave). Used by the team banner at the gate (ZombieFights) and the training ground
-- (TrainingStages).
local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local F = Config.Flag

local WavingFlag = {}

WavingFlag.TrainingHeight = F.TrainingHeight

local template: Model? = nil
local building = false
local failed = false

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function mesh(model: Model, root: BasePart, name: string, id: string, at: { number }): MeshPart
	local part = AssetService:CreateMeshPartAsync(Content.fromUri(id))
	part.Name = name
	part.Anchored = true
	part.CFrame = root.CFrame + v3(at)
	part.Parent = model
	return part
end

local function build(): Model
	local model = Instance.new("Model")
	model.Name = "WavingFlag"
	-- (whole or not at all on a client, so its waving finds every bone)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local root = Instance.new("Part")
	root.Name = "RootPart"
	root.Size = Vector3.one * 0.2
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.identity
	root.Parent = model
	model.PrimaryPart = root

	local pole = mesh(model, root, "Pole", F.PoleMesh, F.PoleAt)
	pole.Material = Enum.Material.Wood
	pole.Color = rgb(F.PoleColour)
	local finial = mesh(model, root, "Finial", F.FinialMesh, F.FinialAt)
	finial.Material = Enum.Material.Metal
	finial.Color = rgb(F.FinialColour)
	finial.CanCollide = false
	local cloth = mesh(model, root, "FlagCloth", F.ClothMesh, F.ClothAt)
	cloth.TextureID = F.ClothTexture
	cloth.Material = Enum.Material.Fabric
	cloth.Color = Color3.new(1, 1, 1)
	cloth.CanCollide = false
	cloth.CanQuery = false
	cloth.CanTouch = false

	-- the bones as the import made them: the first lies along -X (its own +Y), each next one BoneStep further. They hang
	-- under the cloth itself: a skinned mesh only follows bones of its own assembly, and these parts are anchored apart.
	local parent: Instance = cloth
	for k = 0, F.Bones - 1 do
		local bone = Instance.new("Bone")
		bone.Name = "Flag" .. k
		bone.CFrame = if k == 0
			then CFrame.new(v3(F.BoneAt) - v3(F.ClothAt)) * CFrame.fromMatrix(
				Vector3.zero,
				Vector3.zAxis,
				-Vector3.xAxis
			)
			else CFrame.new(0, F.BoneStep, 0)
		bone.Parent = parent
		parent = bone
	end
	CollectionService:AddTag(model, "WavingFlag")
	return model
end

-- Builds the flag once (the meshes load from Roblox); later callers wait for it. Nil if the meshes could not load.
local function ready(): Model?
	while building do
		task.wait(0.1)
	end
	if template or failed then
		return template
	end
	building = true
	local ok, result = pcall(build)
	building = false
	if ok then
		template = result
	else
		failed = true
		warn(Config.LogPrefix, "flag: the meshes did not load:", result)
	end
	return template
end

-- A flag standing at `foot` (its pole's foot; the cloth flies along the frame's -X), `height` studs tall, in `parent`.
function WavingFlag.stand(parent: Instance, foot: CFrame, height: number, name: string?): Model?
	local t = ready()
	if not t then
		return nil
	end
	local m = t:Clone()
	m:ScaleTo(height / F.ModelHeight)
	m:PivotTo(foot)
	m.Name = name or "WavingFlag"
	m.Parent = parent
	return m
end

-- Starts loading the meshes at once, so the first plot does not wait for them.
function WavingFlag.start()
	task.spawn(ready)
end

return WavingFlag
