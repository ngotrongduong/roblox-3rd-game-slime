--!strict
-- Day and night (Config.World.DayNight, the clock in shared/DayClock; the owner, 2026-11-15). The sun follows the
-- server's hour, the same for everyone; as night falls the place's own light eases to the night's (Brightness, both
-- ambients, the Atmosphere's colour and decay) and back at dawn. While a Dungeon map with a light of its own is on
-- (client/DungeonLight) the clock is that map's; back from it, it eases in over BlendSeconds. Only this client's
-- lighting changes, a few times a second.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DayClock = require(ReplicatedStorage.Shared.DayClock)

local D = Config.World.DayNight
local ARENAS: any = Config.Dungeon.Arenas
local STEP = 1 / 10
local player = Players.LocalPlayer
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

type Look = { clock: number, brightness: number, ambient: Color3, outdoor: Color3, colour: Color3, decay: Color3 }

local function now(): Look
	return {
		clock = Lighting.ClockTime,
		brightness = Lighting.Brightness,
		ambient = Lighting.Ambient,
		outdoor = Lighting.OutdoorAmbient,
		colour = if atmosphere then atmosphere.Color else Color3.new(1, 1, 1),
		decay = if atmosphere then atmosphere.Decay else Color3.new(1, 1, 1),
	}
end

-- the place's own day, as it stands when the game starts
local day = now()
local N = D.Night
local night: Look = {
	clock = 0,
	brightness = N.Brightness,
	ambient = Color3.fromHex(N.Ambient),
	outdoor = Color3.fromHex(N.OutdoorAmbient),
	colour = Color3.fromHex(N.AtmosphereColour),
	decay = Color3.fromHex(N.AtmosphereDecay),
}

local function mix(a: Look, b: Look, k: number, clock: number): Look
	return {
		clock = clock,
		brightness = a.brightness + (b.brightness - a.brightness) * k,
		ambient = a.ambient:Lerp(b.ambient, k),
		outdoor = a.outdoor:Lerp(b.outdoor, k),
		colour = a.colour:Lerp(b.colour, k),
		decay = a.decay:Lerp(b.decay, k),
	}
end

-- the way round the clock from `a` to `b` that is shortest, `k` of it
local function turn(a: number, b: number, k: number): number
	return (a + ((b - a + 12) % 24 - 12) * k) % 24
end

local function dungeonLit(): boolean
	local map = player:GetAttribute("DungeonMap")
	local arena = if type(map) == "string" then ARENAS[map] else nil
	return arena ~= nil and arena.Lighting ~= nil
end

local held = false
local blendFrom: Look? = nil
local blendStart = 0

while true do
	if dungeonLit() then
		held = true
	else
		if held then
			held = false
			blendFrom = now()
			blendStart = os.clock()
		end
		local hour = DayClock.hour(workspace:GetServerTimeNow())
		local look = mix(day, night, DayClock.night(hour), hour)
		if blendFrom then
			local k = math.min((os.clock() - blendStart) / D.BlendSeconds, 1)
			look = mix(blendFrom, look, k, turn(blendFrom.clock, hour, k))
			if k >= 1 then
				blendFrom = nil
			end
		end
		Lighting.ClockTime = look.clock
		Lighting.Brightness = look.brightness
		Lighting.Ambient = look.ambient
		Lighting.OutdoorAmbient = look.outdoor
		if atmosphere then
			atmosphere.Color = look.colour
			atmosphere.Decay = look.decay
		end
	end
	task.wait(STEP)
end
