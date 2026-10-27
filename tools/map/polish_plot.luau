-- Polish pass on a plot's built areas (research: RESEARCH.md "Stylized cozy look"): the storybook
-- grass (a generated hand-drawn MaterialVariant over terrain Grass), no blob shadows (the owner took
-- them out), dark outlines on the one hero piece of
-- each area. Nothing in a home plot sways (the owner, 2026-10-27: the plants at home stay still).
-- Run in Edit mode through MCP after the builders and dress_plot_nature. Rerunnable.
local MaterialService = game:GetService("MaterialService")

local PLOT = 5
local plot = workspace.Map["Plot" .. PLOT]

-- ===== grass =====
-- Tried 2026-10-27: a generated "hand-drawn grass" MaterialVariant came out as busy dark brush strokes,
-- and the same variant without maps rendered neon green whatever the terrain colour. Kept: no
-- override, a soft spring green.
MaterialService:SetBaseMaterialOverride(Enum.Material.Grass, "")
workspace.Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(112, 182, 66))
workspace.GlobalWind = Vector3.new(4, 0, 2)

-- (No blob shadow discs: the owner took the green circles under bushes and rocks out, 2026-10-27;
-- any left from an older run go.)
for _, d in plot:GetDescendants() do
	if d.Name == "BlobShadow" then
		d:Destroy()
	end
end

-- ===== outlines on the hero of each area =====
local function hero(area: Instance, modelName: string, partNames: { [string]: boolean })
	local m = area:FindFirstChild(modelName)
	if not m then
		m = Instance.new("Model")
		m.Name = modelName
		for _, c in area:GetChildren() do
			if c:IsA("BasePart") and partNames[c.Name] then
				c.Parent = m
			end
		end
		m.Parent = area
	end
	local h = m:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
	h.FillTransparency = 1
	h.OutlineColor = Color3.fromRGB(60, 38, 22)
	h.OutlineTransparency = 0.2
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = m
end
hero(plot.FishingPondL1, "Dock", { Plank = true, Beam = true, Post = true, Rope = true })
hero(plot.GardenL1, "Beds", { BedPlank = true, Soil = true })

return "polished"
