-- THE ONE LOOP of the library (Goo Lineage's EffectsLod, Egg Heist's TrailFx guard): a few times a second it looks at
-- every lasting effect and gives it a level of detail by its distance to the camera, how many are near and the quality:
--   full    every particle and the light            (the nearest MaxFull within Full studs; of the showcase (heavy)
--                                                    effects, the nearest MaxShowcase only)
--   half    half the rate, no light                 (within Half studs)
--   ribbon  a trail's bands only, no particles      (within Far studs)
--   off     nothing (behind the camera, or farther)
-- Only the nearest MaxLights get their light. Every frame it also runs the one-shots and moves the orbits; a trail's
-- run is read from how far its host moved (a dummy moved by CFrame has no velocity).
local Builder = require(if script then script.Parent.Builder else "./Builder")
local Quality = require(if script then script.Parent.Quality else "./Quality")

local Lod = {}

Lod.CheckHz = 4
Lod.Full = 60 -- studs
Lod.Half = 130
Lod.Far = 200
Lod.MaxFull = 8 -- hosts with every layer (Quality.full scales it)
Lod.MaxLights = 4 -- hosts with a light (Quality.lights scales it)
Lod.MaxShowcase = 1 -- showcase (heavy) effects with every layer: the rest of them run at half
Lod.Behind = 8 -- studs behind the camera that a host may stand and still be drawn (its effect reaches round it)

Lod.handles = {} -- the lasting effects
Lod.shots = {} -- the one-shots
Lod.clock = 0
Lod.connection = nil :: RBXScriptConnection? -- the loop, once started (declared so a game's type checker knows it)

local acc = 0

function Lod.add(handle)
	table.insert(Lod.handles, handle)
end

function Lod.addShot(live)
	table.insert(Lod.shots, live)
end

local function rootPosition(handle)
	local root = handle.root
	if root and root.Parent then
		return root.CFrame.Position -- (CFrame: Lune's parts have no Position)
	end
	return handle.carrier.CFrame.Position
end

-- The level of each handle from where the camera is (`eye`, its look `look`). Pure: the tests call it.
function Lod.levels(handles, eye, look)
	local entries = {}
	for _, handle in handles do
		if handle.fading then
			continue -- (on its way off: it takes no one's place)
		end
		local at = rootPosition(handle)
		local offset = at - eye
		local distance = offset.Magnitude
		local ahead = if look then offset:Dot(look) else 1
		table.insert(entries, { handle = handle, distance = distance, behind = ahead < -Lod.Behind })
	end
	table.sort(entries, function(a, b)
		return a.distance < b.distance
	end)
	local full = math.max(Quality.full(Lod.MaxFull), 1)
	local lights = Quality.lights(Lod.MaxLights)
	local fullUsed, lightsUsed, showcaseUsed = 0, 0, 0
	local out = {}
	for _, entry in entries do
		local d = entry.distance
		local showcase = entry.handle.effect and entry.handle.effect.tier == "heavy"
		local mode
		if entry.behind or d > Quality.distance(Lod.Far) then
			mode = "off"
		elseif d > Quality.distance(Lod.Half) then
			mode = if #entry.handle.bands > 0 then "ribbon" else "off"
		elseif d > Quality.distance(Lod.Full) or fullUsed >= full or (showcase and showcaseUsed >= Lod.MaxShowcase) then
			mode = "half"
		else
			mode = "full"
			fullUsed += 1
			if showcase then
				showcaseUsed += 1
			end
		end
		local light = false
		if mode == "full" and entry.handle.light and lightsUsed < lights then
			light = true
			lightsUsed += 1
		end
		out[entry.handle] = { mode = mode, light = light, distance = d }
	end
	return out
end

-- One frame: `dt` seconds; `camera` a CFrame (nil: no level of detail, everything full).
function Lod.step(dt, camera)
	Lod.clock += dt
	for index = #Lod.shots, 1, -1 do
		if not Builder.step(Lod.shots[index], dt) then
			table.remove(Lod.shots, index)
		end
	end
	for index = #Lod.handles, 1, -1 do
		local handle = Lod.handles[index]
		if handle.fading and not handle.dead then
			-- (taken off softly, Builder.release: gone once what it had out has faded)
			handle.fading -= dt
			if handle.fading <= 0 then
				Builder.detach(handle)
			end
		end
		if handle.dead or not handle.folder.Parent then
			handle.dead = true
			table.remove(Lod.handles, index)
		end
	end
	acc += dt
	local check = acc >= 1 / Lod.CheckHz
	local levels = nil
	if check then
		local span = acc
		acc = 0
		for _, handle in Lod.handles do
			local at = rootPosition(handle)
			if handle.lastAt then
				local moved = (at - handle.lastAt).Magnitude / span
				-- (smoothed, so a step of the loop does not flicker the run)
				handle.measuredSpeed = (handle.measuredSpeed or moved) * 0.5 + moved * 0.5
			end
			handle.lastAt = at
		end
		if camera then
			levels = Lod.levels(Lod.handles, camera.Position, camera.LookVector)
		end
	end
	for _, handle in Lod.handles do
		if handle.fading then
			continue -- (its emitters stay off)
		end
		local level = levels and levels[handle]
		local info = { clock = Lod.clock }
		if check then
			info.speed = handle.speedOverride or handle.measuredSpeed or 0
			if level then
				info.mode = level.mode
				info.light = level.light
			elseif not camera then
				info.mode = "full"
			end
		end
		if handle.keepFull then
			info.mode = "full"
			info.light = true
		end
		Builder.update(handle, info)
	end
end

-- Hooks the loop to the engine (the client): RunService.Heartbeat and the current camera.
function Lod.start()
	if Lod.connection then
		return
	end
	local RunService = game:GetService("RunService")
	Lod.connection = RunService.Heartbeat:Connect(function(dt)
		local camera = workspace.CurrentCamera
		Lod.step(dt, camera and camera.CFrame)
	end)
end

function Lod.stop()
	if Lod.connection then
		Lod.connection:Disconnect()
		Lod.connection = nil
	end
end

return Lod
