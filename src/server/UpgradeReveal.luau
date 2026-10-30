--!strict
-- Mark visual differences before a rebuilt stage enters the world. The client alone animates them;
-- the authoritative new geometry, collision and save state are already final on the server.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Fx = Config.UpgradeFx

local UpgradeReveal = {}

local function changed(part: BasePart, before: BasePart?): boolean
	if not before or part.ClassName ~= before.ClassName then
		return true
	end
	return part.Size ~= before.Size
		or part.Color ~= before.Color
		or part.Material ~= before.Material
		or part.Transparency ~= before.Transparency
		or (part.Position - before.Position).Magnitude > Fx.PositionToleranceStuds
		or (part.CFrame.LookVector - before.CFrame.LookVector).Magnitude > Fx.PositionToleranceStuds
end

function UpgradeReveal.prepare(previous: Model?, stage: Model, areaId: string, level: number)
	local oldByName: { [string]: { BasePart } } = {}
	if previous then
		for _, inst in previous:GetDescendants() do
			if inst:IsA("BasePart") then
				local list = oldByName[inst.Name]
				if not list then
					list = {}
					oldByName[inst.Name] = list
				end
				table.insert(list, inst)
			end
		end
	end

	local seen: { [string]: number } = {}
	local added: { BasePart } = {}
	local altered: { BasePart } = {}
	for _, inst in stage:GetDescendants() do
		if inst:IsA("BasePart") then
			local index = (seen[inst.Name] or 0) + 1
			seen[inst.Name] = index
			local originals = oldByName[inst.Name]
			local before = if originals then originals[index] else nil
			if inst.Transparency < 1 and changed(inst, before) then
				table.insert(if before then altered else added, inst)
			end
		end
	end

	local picked: { [string]: number } = {}
	local count = 0
	local sum = Vector3.zero
	for _, group in { added, altered } do
		for _, part in group do
			if count >= Fx.MaxChangedParts then
				break
			end
			local used = picked[part.Name] or 0
			if used < Fx.MaxPerPartName then
				picked[part.Name] = used + 1
				part:SetAttribute(Fx.PartAttribute, true)
				sum += part.Position
				count += 1
			end
		end
	end

	local focus = if count > 0 then sum / count else stage:GetPivot().Position
	stage:SetAttribute("UpgradeFxFocus", focus)
	stage:SetAttribute("UpgradeFxArea", areaId)
	stage:SetAttribute("UpgradeFxLevel", level)
	stage:SetAttribute("UpgradeFxAt", workspace:GetServerTimeNow())
	CollectionService:AddTag(stage, Fx.Tag)
end

return UpgradeReveal
