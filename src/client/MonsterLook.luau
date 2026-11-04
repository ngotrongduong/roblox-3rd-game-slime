--!strict
-- The one place where a Slime Dungeon monster gets its look. A monster with a model in ReplicatedStorage.MonsterKit is
-- drawn on an unseen slime body that walks, hops and takes the hits (SlimeActor.dress), by Config.Dungeon.Looks:
--   * a look with `motion` is one of the owner's Egg Heist creatures (assets/MonsterKit.rbxm by
--     tools/kit/eggheist_models.luau), posed by its own motion module (CreatureRig);
--   * a look with `pieces` is a model of rigid pieces (the Blender builds of art/models/monsters/), each turned about
--     its joint (MonsterMotion). Until its model is in the kit it is a body in the rotten zombie
-- skin with its outline in the colour of its kind and its height by its role (Config.Dungeon.StandIn, the server's
-- stand-in Parts use the same colours and sizes). An unknown kind or role is never an error: it looks like a plain melee
-- monster.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SkinIds = require(ReplicatedStorage.Shared.SkinIds)
local CreatureRig = require(script.Parent.CreatureRig)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeLook = require(script.Parent.SlimeLook)
local ZombieLook = require(script.Parent.ZombieLook)

local D = Config.Dungeon
local C = Config.VillageClient

local MonsterLook = {}

export type Monster = { defId: string?, kind: string?, role: string?, name: string? }
export type Look = { model: Model, face: string, size: number, creature: SlimeActor.Creature? }

local warned: { [string]: boolean } = {}

local function vec(list: { number }): Vector3
	return Vector3.new(list[1], list[2], list[3])
end

-- The kit's model of a look, or nil (said once a model, not every spawn).
local function source(name: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("MonsterKit")
	local model = folder and folder:FindFirstChild(name)
	if model and model:IsA("Model") then
		return model
	end
	if not warned[name] then
		warned[name] = true
		warn(Config.LogPrefix, "missing MonsterKit/" .. name .. "; drawing the stand-in")
	end
	return nil
end

-- The piece spec whose name the part's name is or ends with (an import may put the file's name in front).
local function pieceOf(pieces: { [string]: any }, partName: string): (string?, any)
	for name, piece in pieces do
		if partName == name or string.sub(partName, -#name - 1) == "_" .. name then
			return name, piece
		end
	end
	return nil, nil
end

-- The monster's pieces as a creature for SlimeActor.dress, parented in `holder`. The kit model stands as built: its
-- lowest, leftmost, frontmost corner is the look's `min` from the monster's ground spot (the Body's origin), so every
-- joint is found again from the pieces' own bounds, whatever pivot the import gave them.
local function creatureOf(spec: any, kitModel: Model, holder: Model, scale: number): SlimeActor.Creature
	local copy = kitModel:Clone()
	local _, extents = copy:GetBoundingBox()
	copy:ScaleTo(copy:GetScale() * spec.height * scale / extents.Y)
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local list: { BasePart } = {}
	for _, inst in copy:GetDescendants() do
		if inst:IsA("BasePart") then
			table.insert(list, inst)
			local half = inst.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local corner = inst.CFrame:PointToWorldSpace(half * Vector3.new(sx, sy, sz))
						low = low:Min(corner)
					end
				end
			end
		end
	end
	local origin = CFrame.new(low - vec(spec.min) * scale)
	local creature: SlimeActor.Creature = {
		parts = {},
		specs = {},
		joints = {},
		fromJoints = {},
		hover = (spec.hover or 0) * scale,
		bob = (spec.bob or 0) * scale,
		bobHz = spec.bobHz or 0,
		top = ((spec.hover or 0) + spec.height) * scale,
		tilt = math.rad(spec.tilt or 0),
		lean = spec.lean or 0.5,
		attackGain = spec.attackGain or 2,
		last = nil,
		rig = nil,
		air = 0,
	}
	local folder = Instance.new("Folder")
	folder.Name = "Creature"
	folder.Parent = holder
	for _, part in list do
		local _, piece = pieceOf(spec.pieces, part.Name)
		local joint = if piece then CFrame.new(vec(piece.joint) * scale) else CFrame.new()
		table.insert(creature.parts, part)
		table.insert(creature.specs, piece or {})
		table.insert(creature.joints, joint)
		table.insert(creature.fromJoints, joint:Inverse() * origin:ToObjectSpace(part.CFrame))
		if piece and piece.transparency then
			part.Transparency = piece.transparency
		end
		part.CastShadow = spec.shadow == true
		part.Parent = folder
	end
	copy:Destroy()
	return creature
end

-- An Egg Heist creature (the look names its `motion` module): its one skinned part, scaled to the look's height, stands
-- with the bottom of its box on the monster's ground spot and faces the way its part faces; CreatureRig poses its bones.
-- Nil when its motion does not fit the model (said once): the stand-in is drawn instead.
local function rigOf(spec: any, kitModel: Model, holder: Model, scale: number): SlimeActor.Creature?
	local copy = kitModel:Clone()
	local _, extents = copy:GetBoundingBox()
	copy:ScaleTo(copy:GetScale() * spec.height * scale / extents.Y)
	local part: BasePart? = copy.PrimaryPart or copy:FindFirstChildWhichIsA("MeshPart")
	if not part then
		copy:Destroy()
		return nil
	end
	local rig, problem = CreatureRig.bind(part, spec.motion, math.random())
	if not rig then
		if not warned[spec.motion] then
			warned[spec.motion] = true
			warn(
				Config.LogPrefix,
				"the motion " .. spec.motion .. " does not fit its model (" .. tostring(problem) .. ")"
			)
		end
		copy:Destroy()
		return nil
	end
	local box, size = copy:GetBoundingBox()
	local origin = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0)) * part.CFrame.Rotation
	local creature: SlimeActor.Creature = {
		parts = { part },
		specs = { {} :: any },
		joints = { CFrame.new() },
		fromJoints = { origin:ToObjectSpace(part.CFrame) },
		hover = (spec.hover or 0) * scale,
		bob = (spec.bob or 0) * scale,
		bobHz = spec.bobHz or 0,
		top = ((spec.hover or 0) + spec.height) * scale,
		tilt = math.rad(spec.tilt or 0),
		lean = spec.lean or 0.3,
		attackGain = spec.attackGain or 2,
		last = nil,
		rig = rig,
		air = if (spec.hover or 0) > 0 then 1 else 0,
	}
	local folder = Instance.new("Folder")
	folder.Name = "Creature"
	folder.Parent = holder
	part.CastShadow = spec.shadow == true
	part.Parent = folder
	copy:Destroy()
	return creature
end

-- The monster's body at the origin (not parented), its emotion for SlimeActor, its size against a plain one, and its
-- pieces when its model is in the kit (DungeonFight dresses the actor with them).
function MonsterLook.build(monster: Monster): Look
	local colours: { [string]: string } = D.StandIn.Colours :: any
	local sizes: { [string]: number } = D.StandIn.Sizes :: any
	local looks: { [string]: any } = D.Looks :: any
	local colour = colours[monster.kind or ""] or colours.melee
	local size = (sizes[monster.role or ""] or sizes.normal) / sizes.normal
	local model = SlimeLook.build({ Scale = 1, SkinImage = SkinIds.Zombies.rotten })
	local hull = model:FindFirstChild("SlimeBodyOutline")
	if hull and hull:IsA("MeshPart") then
		hull.Color = Color3.fromHex(colour)
	end
	model:ScaleTo(C.BodyHeight * size)
	local spec = looks[monster.defId or ""]
	local kitModel = if spec then source(spec.model) else nil
	local creature = nil
	if spec and kitModel then
		model:PivotTo(CFrame.new())
		creature = if spec.motion then rigOf(spec, kitModel, model, 1) else creatureOf(spec, kitModel, model, 1)
	end
	return { model = model, face = ZombieLook.look("rotten").face, size = size, creature = creature }
end

return MonsterLook
