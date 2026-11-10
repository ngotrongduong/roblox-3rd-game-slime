-- Edit datamodel (skill slime-wear): reads the owner's hand in the ear editor (`ear_editor.luau`) back into Config.Wear
-- numbers. For every ear he moved, turned or sized: `at` (its middle), `turn` (degrees about X, Y, Z,
-- CFrame.fromEulerAnglesXYZ) and `size` relative to the slime's feet in mesh units, and `anchor`, the point it rides
-- the skin by, carried with the ear and set back on the skin. Returns JSON {kit: {piece: {size, at, anchor, turn}}};
-- `ear_write.py` writes it into ConfigWear.luau.
--   node tools/studio_mcp.js run .claude/skills/slime-wear/ear_read.luau <studio_id> Edit
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeShape = require(ReplicatedStorage.Shared.SlimeShape)
local S = Config.Slime

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end
local function turnOf(t: { number }?): CFrame
	return if t then CFrame.fromEulerAnglesXYZ(math.rad(t[1]), math.rad(t[2]), math.rad(t[3])) else CFrame.identity
end
local function round(x: number): number
	return math.round(x * 10000) / 10000
end
local function list(v: Vector3): { number }
	return { round(v.X), round(v.Y), round(v.Z) }
end

local stage = workspace:FindFirstChild("EarEditor")
assert(stage, "no EarEditor: run ear_editor.luau first")
local result = {}
for _, folder in stage:GetChildren() do
	local id = folder:GetAttribute("SecretId")
	local kitName = id and Config.Wear.Secrets[id]
	local body = folder:FindFirstChild("SlimeBody")
	if not (kitName and body and body:IsA("BasePart")) then
		continue
	end
	local s = body.Size.Y / S.MeshHeight
	local feet = body.CFrame * CFrame.new(0, -S.MeshCentre * s, 0)
	for _, spec in Config.Wear.Kits[kitName].pieces do
		local part = folder:FindFirstChild(spec.name)
		if not (part and part:IsA("BasePart")) or part.Locked then
			continue
		end
		local was = feet * CFrame.new(v3(spec.at) * s) * turnOf(spec.turn)
		local rel = feet:ToObjectSpace(part.CFrame)
		local size = part.Size / s
		local moved = (rel.Position / s - v3(spec.at)).Magnitude > 0.0005
			or rel.Rotation:FuzzyEq(turnOf(spec.turn), 0.0005) == false
			or (size - v3(spec.size)).Magnitude > 0.0005
		if not moved then
			continue
		end
		-- the anchor rides along with the ear, then back onto the skin at its height
		local foot = was:PointToObjectSpace(feet:PointToWorldSpace(v3(spec.anchor) * s))
		local a = feet:PointToObjectSpace(part.CFrame:PointToWorldSpace(foot)) / s
		local y = math.clamp(a.Y, 0.02, 0.98)
		local flat = Vector3.new(a.X, 0, a.Z)
		local r = SlimeShape.radius(y)
		local anchor = if flat.Magnitude > 0.001 then Vector3.new(0, y, 0) + flat.Unit * r else Vector3.new(0, y, 0)
		local rx, ry, rz = rel:ToEulerAnglesXYZ()
		result[kitName] = result[kitName] or {}
		result[kitName][spec.name] = {
			size = list(size),
			at = list(rel.Position / s),
			anchor = list(anchor),
			turn = { round(math.deg(rx)), round(math.deg(ry)), round(math.deg(rz)) },
		}
	end
end
return HttpService:JSONEncode(result)
