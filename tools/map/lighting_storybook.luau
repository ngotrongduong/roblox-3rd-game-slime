-- The "sunny storybook" lighting of the Goo Valley (research: .claude/skills/studio-build/RESEARCH.md,
-- "Stylized cozy look"): sun from the side, lilac shade, no specular shine, light haze, a small
-- saturation lift, Bloom only for real light sources. Run in Edit mode through Studio's MCP.
local L = game:GetService("Lighting")
local notes = {}
local ok = pcall(function()
	L.LightingStyle = Enum.LightingStyle.Realistic
end)
table.insert(notes, "LightingStyle " .. (if ok then "set" else "refused: set it in the Properties panel"))
pcall(function()
	L.PrioritizeLightingQuality = true
end)
L.ClockTime = 14.6
L.GeographicLatitude = 35
L.Brightness = 2.6
pcall(function()
	L.ExposureCompensation = 0.1
end)
L.Ambient = Color3.fromRGB(110, 100, 125)
L.OutdoorAmbient = Color3.fromRGB(150, 140, 175)
L.ColorShift_Top = Color3.fromRGB(255, 236, 205)
L.ColorShift_Bottom = Color3.fromRGB(120, 140, 190)
L.EnvironmentDiffuseScale = 0.5
-- 1, not 0: the slimes' wet shine is the sky reflected in their gloss (owner, 2026-10-28: highlights
-- come from light, never painted on); the plastic scenery barely changes at play distance.
L.EnvironmentSpecularScale = 1
L.ShadowSoftness = 0.25
L.GlobalShadows = true
local function get(cls: string): Instance
	return L:FindFirstChildOfClass(cls) or Instance.new(cls, L)
end
local a = get("Atmosphere") :: Atmosphere
a.Density = 0.26
a.Offset = 0.35
a.Haze = 0.8
a.Glare = 0
a.Color = Color3.fromRGB(205, 225, 255)
a.Decay = Color3.fromRGB(120, 140, 170)
local cc = get("ColorCorrectionEffect") :: ColorCorrectionEffect
cc.Saturation = 0.18
cc.Contrast = 0.08
cc.Brightness = 0.02
cc.TintColor = Color3.fromRGB(255, 250, 240)
local b = get("BloomEffect") :: BloomEffect
b.Intensity = 0.35
b.Size = 24
b.Threshold = 1.6
return table.concat(notes, "; ")
