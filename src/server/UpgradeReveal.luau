--!strict
-- Mark visual differences before a rebuilt stage enters the world. The client alone animates them;
-- the authoritative new geometry, collision and save state are already final on the server.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UpgradeDiff = require(ReplicatedStorage.Shared.UpgradeDiff)
local Fx = Config.UpgradeFx

local UpgradeReveal = {}

-- What a piece looks like and where it stands, to the look of a player's eye (rounded to a tenth of a stud).
local function signature(part: BasePart): string
	local p, look, s = part.Position, part.CFrame.LookVector, part.Size
	return string.format(
		"%s|%s|%s|%s|%s|%.2f|%.1f,%.1f,%.1f|%.1f,%.1f,%.1f|%.1f,%.1f,%.1f",
		part.Name,
		part.ClassName,
		if part:IsA("MeshPart") then part.MeshId .. part.TextureID else "",
		part.Color:ToHex(),
		part.Material.Name,
		part.Transparency,
		p.X,
		p.Y,
		p.Z,
		look.X,
		look.Y,
		look.Z,
		s.X,
		s.Y,
		s.Z
	)
end

function UpgradeReveal.prepare(previous: Model?, stage: Model, areaId: string, level: number)
	local before: { string } = {}
	if previous then
		for _, inst in previous:GetDescendants() do
			if inst:IsA("BasePart") then
				table.insert(before, signature(inst))
			end
		end
	end

	local parts: { BasePart } = {}
	local pieces: { UpgradeDiff.Piece } = {}
	for _, inst in stage:GetDescendants() do
		if inst:IsA("BasePart") and inst.Transparency < 1 then
			table.insert(parts, inst)
			table.insert(pieces, { signature = signature(inst), size = inst.Size.X * inst.Size.Y * inst.Size.Z })
		end
	end

	local sum = Vector3.zero
	local picked = UpgradeDiff.changed(before, pieces, Fx.MaxChangedParts)
	for _, index in picked do
		parts[index]:SetAttribute(Fx.PartAttribute, true)
		sum += parts[index].Position
	end

	stage:SetAttribute("UpgradeFxFocus", if #picked > 0 then sum / #picked else stage:GetPivot().Position)
	stage:SetAttribute("UpgradeFxArea", areaId)
	stage:SetAttribute("UpgradeFxLevel", level)
	stage:SetAttribute("UpgradeFxAt", workspace:GetServerTimeNow())
	CollectionService:AddTag(stage, Fx.Tag)
end

return UpgradeReveal
