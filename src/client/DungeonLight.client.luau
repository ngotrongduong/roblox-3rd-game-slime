--!strict
-- The light of a Slime Dungeon map. While a run is on a map whose Config.Dungeon.Arenas.<map>.Lighting exists (the Mushroom
-- Grove's dusk), the game's lighting eases to it; when the run ends, or the next level is on a map without one (the Sunny
-- Meadow keeps the place's own bright day), it eases back. Only this client's lighting changes. Reads the player attribute
-- DungeonMap (server/Dungeon); no particle, no script-drawn shape.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local ARENAS: any = Config.Dungeon.Arenas
local player = Players.LocalPlayer

-- the place's own look, taken once, the first time a map changes it
type Baseline = {
	brightness: number,
	clock: number,
	ambient: Color3,
	outdoor: Color3,
	atmosphere: Atmosphere?,
	atmColour: Color3,
	atmDecay: Color3,
	atmDensity: number,
	atmOffset: number,
	atmHaze: number,
	sky: Sky?,
	stars: number,
	exposure: number,
}

local baseline: Baseline? = nil
local atmosphere: Atmosphere? = nil
local grade: ColorCorrectionEffect? = nil
local current = ""

local function ensure()
	if baseline then
		return
	end
	local own = Lighting:FindFirstChildOfClass("Atmosphere")
	local sky = Lighting:FindFirstChildOfClass("Sky")
	baseline = {
		sky = sky,
		stars = if sky then sky.StarCount else 0,
		exposure = Lighting.ExposureCompensation,
		brightness = Lighting.Brightness,
		clock = Lighting.ClockTime,
		ambient = Lighting.Ambient,
		outdoor = Lighting.OutdoorAmbient,
		atmosphere = own,
		atmColour = if own then own.Color else Color3.new(1, 1, 1),
		atmDecay = if own then own.Decay else Color3.new(1, 1, 1),
		atmDensity = if own then own.Density else 0,
		atmOffset = if own then own.Offset else 0,
		atmHaze = if own then own.Haze else 0,
	}
	if own then
		atmosphere = own
	else
		local made = Instance.new("Atmosphere")
		made.Name = "DungeonAtmosphere"
		made.Density = 0
		made.Offset = 0
		made.Glare = 0
		made.Haze = 0
		made.Parent = Lighting
		atmosphere = made
	end
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "DungeonGrade"
	effect.Parent = Lighting
	grade = effect
end

local function ease(seconds: number, instance: Instance, goal: { [string]: any })
	TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
		:Play()
end

local function apply(mapId: string)
	if mapId == current then
		return
	end
	current = mapId
	local map = ARENAS[mapId]
	local look = if map then map.Lighting else nil
	if not look and not baseline then
		-- (nothing was changed yet: the place's day is already what is wanted)
		return
	end
	ensure()
	local base = baseline :: Baseline
	local atm, effect = atmosphere :: Atmosphere, grade :: ColorCorrectionEffect
	if look then
		local seconds = look.Seconds
		-- (a map may switch the night's stars off: Ember Lava's sky is a dark charcoal, not a starry one)
		-- (a place with no Sky of its own shows the engine's own sky, whose few stars at this hour cannot be switched off;
		-- a Sky made here turned the whole sky navy, so none is made)
		if base.sky and look.Stars ~= nil then
			base.sky.StarCount = look.Stars
		end
		ease(seconds, Lighting, {
			Brightness = look.Brightness,
			ExposureCompensation = look.Exposure or base.exposure,
			ClockTime = look.ClockTime,
			Ambient = Color3.fromHex(look.Ambient),
			OutdoorAmbient = Color3.fromHex(look.OutdoorAmbient),
		})
		ease(seconds, atm, {
			Color = Color3.fromHex(look.AtmosphereColour),
			Decay = Color3.fromHex(look.AtmosphereDecay),
			Density = look.AtmosphereDensity,
			Offset = look.AtmosphereOffset,
			Haze = look.AtmosphereHaze,
		})
		ease(seconds, effect, {
			TintColor = Color3.fromHex(look.TintColour),
			Saturation = look.Saturation,
			Brightness = look.GradeBrightness,
			Contrast = look.GradeContrast or 0,
		})
	else
		local seconds = Config.Dungeon.LightBackSeconds
		if base.sky then
			base.sky.StarCount = base.stars
		end
		ease(seconds, Lighting, {
			Brightness = base.brightness,
			ExposureCompensation = base.exposure,
			ClockTime = base.clock,
			Ambient = base.ambient,
			OutdoorAmbient = base.outdoor,
		})
		ease(seconds, atm, {
			Color = base.atmColour,
			Decay = base.atmDecay,
			Density = base.atmDensity,
			Offset = base.atmOffset,
			Haze = base.atmHaze,
		})
		ease(seconds, effect, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Brightness = 0, Contrast = 0 })
	end
end

local function read()
	local value = player:GetAttribute("DungeonMap")
	apply(if type(value) == "string" then value else "")
end

player:GetAttributeChangedSignal("DungeonMap"):Connect(read)
read()
