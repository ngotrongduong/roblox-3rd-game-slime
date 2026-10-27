-- Polish pass on a plot's built areas (research: RESEARCH.md "Stylized cozy look"): the storybook
-- grass (a generated hand-drawn MaterialVariant over terrain Grass), soft dark blob shadows under every
-- prop (so the scene still reads when phones turn shadows off), dark outlines on the one hero piece of
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

-- ===== blob shadows =====
local SHADOW = Color3.fromRGB(70, 128, 46)
-- Small fillers get no shadow disc (it reads as a pad under them).
local SMALL = { GrassTuft = true, FlowerPatch = true, Fern = true }
local function blob(parent: Instance, model: Model)
	local box, size = model:GetBoundingBox()
	local d = math.max(size.X, size.Z) * 0.95
	local p = Instance.new("Part")
	p.Name = "BlobShadow"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.06, d, d * 0.85)
	p.CFrame = CFrame.new(box.Position.X, box.Position.Y - size.Y / 2 + 0.04, box.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = SHADOW
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
end

for _, areaName in { "FishingPondL1", "GardenL1" } do
	local area = plot:FindFirstChild(areaName)
	local nature = area and area:FindFirstChild("Nature")
	if nature then
		for _, old in nature:GetChildren() do
			if old.Name == "BlobShadow" then
				old:Destroy()
			end
		end
		for _, m in nature:GetChildren() do
			if m:IsA("Model") then
				if m.Name ~= "WaterLily" and m.Name ~= "SteppingStones" and not SMALL[m.Name] then
					blob(nature, m)
				end
			end
		end
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
