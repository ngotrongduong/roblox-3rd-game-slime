--!strict
-- A Secret slime's own worn pieces (Config.Wear; the first: Tempest Dragon's horns, wings and tail). SlimeLook puts them on
-- the model it builds, where they rest on the body; SlimeActor's loop then makes them ride the skin (SlimeWear.pose) as the
-- jelly squashes, hops and leans, and swings what flaps. The meshes load from Roblox once per kit
-- (AssetService:CreateMeshPartAsync, as the flag's); a slime built before they arrive is dressed when they do.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeShape = require(ReplicatedStorage.Shared.SlimeShape)

local W = Config.Wear
local S = Config.Slime

type FlapSpec = { axis: { number }, degrees: number, hz: number }
type PieceSpec = {
	name: string,
	mesh: number,
	size: { number },
	at: { number },
	anchor: { number },
	flap: FlapSpec?,
}
type KitSpec = { texture: string, pieces: { PieceSpec } }

-- `anchor` and `offset` (from the anchor to the piece's middle) are in mesh units, times the slime's scale in studs
type Piece = { part: BasePart, anchor: Vector3, offset: Vector3, axis: Vector3?, swing: number, speed: number }
type Worn = { pieces: { Piece }, phase: number }

local KITS: { [string]: KitSpec } = W.Kits :: any
local SECRETS: { [string]: string } = W.Secrets :: any

local SlimeWear = {}

-- kit -> its loaded pieces in Config order (a Studio check may fill a kit by hand before its meshes are uploaded)
local templates: { [string]: { BasePart } } = {}
SlimeWear.templates = templates
local waiting: { [string]: { Model } } = {}
local failed: { [string]: boolean } = {}
local worn: { [Model]: Worn } = setmetatable({} :: any, { __mode = "k" })
local random = Random.new()

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

-- Every mesh of a kit at once; nil if one did not load (the slime is then shown without its pieces).
local function load(name: string): { BasePart }?
	local kit = KITS[name]
	local parts: { BasePart } = {}
	local pending = #kit.pieces
	local ok = true
	for i, spec in kit.pieces do
		task.spawn(function()
			local loaded, part = pcall(function()
				return AssetService:CreateMeshPartAsync(Content.fromAssetId(spec.mesh))
			end)
			if loaded then
				part.Name = spec.name
				part.Size = v3(spec.size)
				part.TextureID = kit.texture
				part.Color = Color3.new(1, 1, 1)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.CastShadow = false
				parts[i] = part
			else
				ok = false
				warn(Config.LogPrefix, "wear", name, spec.name, "mesh did not load:", part)
			end
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait(0.1)
	end
	return if ok then parts else nil
end

-- Clones the kit's pieces into the model where they rest on its body (a still model keeps them there).
local function dress(model: Model, name: string)
	local body = model:FindFirstChild("SlimeBody")
	if worn[model] or not (body and body:IsA("BasePart")) then
		return
	end
	local s = body.Size.Y / S.MeshHeight
	local feet = body.CFrame * CFrame.new(0, -S.MeshCentre * s, 0)
	local pieces: { Piece } = {}
	for i, spec in KITS[name].pieces do
		local part = templates[name][i]:Clone()
		part.Size = v3(spec.size) * s
		part.CFrame = feet * CFrame.new(v3(spec.at) * s)
		-- (a ghost's pieces fade as its body does)
		part.Transparency = body.Transparency
		local flap = spec.flap
		table.insert(pieces, {
			part = part,
			anchor = v3(spec.anchor),
			offset = v3(spec.at) - v3(spec.anchor),
			axis = if flap then v3(flap.axis).Unit else nil,
			swing = if flap then math.rad(flap.degrees) else 0,
			speed = if flap then flap.hz * 2 * math.pi else 0,
		})
		-- (a model taken away while the meshes loaded cannot be dressed)
		if not pcall(function()
			part.Parent = model
		end) then
			return
		end
	end
	worn[model] = { pieces = pieces, phase = random:NextNumber(0, 10) }
end

-- Puts a Secret slime's pieces on its freshly built model (nothing for a slime without any).
function SlimeWear.put(model: Model, secretId: string?)
	local name = if secretId then SECRETS[secretId] else nil
	if not name or not KITS[name] or failed[name] then
		return
	end
	if templates[name] then
		dress(model, name)
		return
	end
	if KITS[name].pieces[1].mesh == 0 then
		return
	end
	local list = waiting[name]
	if list then
		table.insert(list, model)
		return
	end
	waiting[name] = { model }
	task.spawn(function()
		local parts = load(name)
		local models = waiting[name]
		waiting[name] = nil
		if not parts then
			failed[name] = true
			return
		end
		templates[name] = parts
		for _, m in models do
			if m.Parent then
				dress(m, name)
			end
		end
	end)
end

-- Adds the model's pieces to SlimeActor's move list for this frame: each rides the skin at its anchor (the body's bones
-- `b`, mesh units; `feet` the slime's feet with its hop and turn) and leans as the skin there does. Returns the new count.
function SlimeWear.pose(
	model: Model,
	feet: CFrame,
	b: SlimeShape.Bones,
	s: number,
	now: number,
	parts: { BasePart },
	cfs: { CFrame },
	n: number
): number
	local w = worn[model]
	if not w then
		return n
	end
	-- the skin's upright line under the jelly's lean and squash (SlimeShape.deform's slope up the body)
	local up = Vector3.new(b.top.x / S.BoneK, 1 + b.top.y / S.BoneK, b.top.z / S.BoneK).Unit
	local tilt = CFrame.fromMatrix(Vector3.zero, (Vector3.xAxis - up * up.X).Unit, up)
	for _, p in w.pieces do
		local x, y, z = SlimeShape.deform(p.anchor.X, p.anchor.Y, p.anchor.Z, b)
		local cf = feet * CFrame.new(x * s, y * s, z * s) * tilt
		local axis = p.axis
		if axis then
			cf *= CFrame.fromAxisAngle(axis, p.swing * math.sin((now + w.phase) * p.speed))
		end
		n += 1
		parts[n] = p.part
		cfs[n] = cf * CFrame.new(p.offset * s)
	end
	return n
end

return SlimeWear
