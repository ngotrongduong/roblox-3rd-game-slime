-- Edit datamodel (skill slime-wear): makes every left-right pair in the ear editor (`ear_editor.luau`) mirror each other
-- across the slime's middle, keeping the owner's hand: each pair takes the halfway of the left piece and the right one
-- mirrored (place and turn, relative to the slime's feet), the right piece its mirror. Pieces are paired by name, `...L`
-- with `...R`; single pieces stay. Run before `ear_read.luau` when he asks for both sides alike.
--   node tools/studio_mcp.js run .claude/skills/slime-wear/ear_mirror.luau <studio_id> Edit
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local S = Config.Slime

-- the frame mirrored across the slime's own YZ plane (x -> -x)
local function mirror(cf: CFrame): CFrame
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end

local stage = workspace:FindFirstChild("EarEditor")
assert(stage, "no EarEditor: run ear_editor.luau first")
local out = {}
for _, folder in stage:GetChildren() do
	local body = folder:FindFirstChild("SlimeBody")
	if not (body and body:IsA("BasePart")) then
		continue
	end
	local s = body.Size.Y / S.MeshHeight
	local feet = body.CFrame * CFrame.new(0, -S.MeshCentre * s, 0)
	-- (a piece he copied keeps its name, so each left piece takes the right one of its name nearest its mirror)
	local taken = {}
	for _, left in folder:GetChildren() do
		local twin = string.match(left.Name, "^(.+)L$")
		if not (twin and left:IsA("BasePart")) or left.Locked then
			continue
		end
		local right: BasePart? = nil
		local best = math.huge
		for _, r in folder:GetChildren() do
			if r.Name == twin .. "R" and r:IsA("BasePart") and not taken[r] then
				local d = (mirror(feet:ToObjectSpace(r.CFrame)).Position - feet:ToObjectSpace(left.CFrame).Position).Magnitude
				if d < best then
					right, best = r, d
				end
			end
		end
		if not right then
			continue
		end
		taken[right] = true
		local relL = feet:ToObjectSpace(left.CFrame)
		local relR = feet:ToObjectSpace(right.CFrame)
		local half = relL:Lerp(mirror(relR), 0.5)
		local moved = (relL.Position - half.Position).Magnitude / s
		left.CFrame = feet * half
		right.CFrame = feet * mirror(half)
		table.insert(out, string.format("%s %s/%s evened (each side moved %.3f)", folder.Name, left.Name, right.Name, moved))
	end
	-- a single piece near the middle (a tail) is set on it, its turn evened; one set off to a side (a lure) stays
	for _, piece in folder:GetChildren() do
		if not piece:IsA("BasePart") or piece.Locked or string.match(piece.Name, "[LR]$") then
			continue
		end
		local rel = feet:ToObjectSpace(piece.CFrame)
		if math.abs(rel.X) / s < 0.05 then
			piece.CFrame = feet * rel:Lerp(mirror(rel), 0.5)
			table.insert(out, string.format("%s %s centred (moved %.3f)", folder.Name, piece.Name, math.abs(rel.X) / s))
		end
	end
end
return table.concat(out, "\n")
