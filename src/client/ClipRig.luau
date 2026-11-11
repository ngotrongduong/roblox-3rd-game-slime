--!strict
-- Plays a Slime Dungeon monster slime by its sampled actions (Shared.MonsterClip, the data in
-- Shared.MonsterClips.<Name>). Its skinned mesh (the FBX of tools/blender/monster_rig.py, uploaded; its look in
-- Config.Dungeon.Looks names the mesh and its texture) is loaded from Roblox once a monster
-- (AssetService:CreateMeshPartAsync, as SlimeWear's tentacles); every copy gets its bones by name at their rest points,
-- unturned (the import gives these bones the part's own axes), and the skin binds to them. Every frame each bone's move,
-- given from its rest in the model's axes, is written to Bone.Transform.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MonsterClip = require(ReplicatedStorage.Shared.MonsterClip)

local ClipRig = {}

export type Rig = {
	bones: { Bone },
	player: MonsterClip.Player,
	scale: number,
}

-- a monster's mesh once loaded, and the monsters whose loading has started (once, even when it failed)
local templates: { [string]: MeshPart } = {}
local started: { [string]: boolean } = {}

-- The data of the monster `name`, or nil.
function ClipRig.data(name: string): MonsterClip.Data?
	local folder = ReplicatedStorage.Shared:FindFirstChild("MonsterClips")
	local module = folder and folder:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		return (require :: any)(module)
	end
	return nil
end

-- Starts loading a look's mesh (once); the look is { clips, mesh, texture }.
function ClipRig.prepare(look: any)
	local name: string = look.clips
	if started[name] then
		return
	end
	started[name] = true
	task.spawn(function()
		local loaded, part = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromAssetId(look.mesh))
		end)
		if loaded then
			part.Name = name
			part.TextureID = "rbxassetid://" .. tostring(look.texture)
			part.Color = Color3.new(1, 1, 1)
			part.Material = Enum.Material.SmoothPlastic
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			templates[name] = part
		else
			warn(Config.LogPrefix, "monster", name, "mesh did not load:", part)
		end
	end)
end

-- A copy of the look's mesh, or nil while it is not loaded (the loading is started).
function ClipRig.mesh(look: any): MeshPart?
	ClipRig.prepare(look)
	local template = templates[look.clips]
	return if template then template:Clone() else nil
end

-- The rig of a copy of a monster's mesh: its bones are made under it by the data. `scale`: how much bigger it is drawn
-- than it was built (the part is sized here; the moves are in built studs); `seed` 0..1 sets its loops apart from its
-- kin's.
function ClipRig.bind(part: MeshPart, data: MonsterClip.Data, scale: number, seed: number, now: number): Rig
	local set = MonsterClip.set(data)
	part.Size *= scale
	local c = data.centre
	local centre = Vector3.new(c[1], c[2], c[3])
	local made: { [string]: Bone } = {}
	local points: { [string]: Vector3 } = {}
	for _, rest in data.rest do
		local name: string, parentName: string = rest[1], rest[2]
		local at = Vector3.new(rest[3], rest[4], rest[5])
		local parent = made[parentName]
		local bone = Instance.new("Bone")
		bone.Name = name
		bone.CFrame = CFrame.new((at - (if parent then points[parentName] else centre)) * scale)
		bone.Parent = parent or part
		made[name], points[name] = bone, at
	end
	local bones = {}
	for i, name in set.bones do
		bones[i] = made[name]
	end
	return { bones = bones, player = MonsterClip.new(set, seed, now), scale = scale }
end

-- Plays an action once (MonsterClip.play): its length, 0 when it does not play.
function ClipRig.play(r: Rig, action: string, now: number, into: number): number
	return MonsterClip.play(r.player, action, now, into)
end

-- One frame; `moving`: it stepped this frame.
function ClipRig.step(r: Rig, now: number, dt: number, moving: boolean)
	local pose = MonsterClip.step(r.player, now, dt, moving)
	local s = r.scale
	for i, bone in r.bones do
		local k = 6 * (i - 1)
		local tx, ty, tz = pose[k + 4], pose[k + 5], pose[k + 6]
		local angle = math.sqrt(tx * tx + ty * ty + tz * tz)
		local move = CFrame.new(pose[k + 1] * s, pose[k + 2] * s, pose[k + 3] * s)
		if angle > 1e-6 then
			move *= CFrame.fromAxisAngle(Vector3.new(tx / angle, ty / angle, tz / angle), angle)
		end
		bone.Transform = move
	end
end

return ClipRig
