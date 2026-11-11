-- VfxLib: the owner's shared effects library (C:\roblox-vfx-library). One runtime for every game: effects are DATA
-- (Effects/<kind>.<name> modules, see Schema), this runs them. Client only: the server announces a moment, each client
-- draws it.
--
--   VfxLib.setup{ quality = { get, subscribe }, textures = { key = id }, log = "[Game]", effects = folder, start }
--   VfxLib.attach(host, id, opts)   a lasting effect (aura, trail, buff, wings, world) on a Part / Model / character
--   VfxLib.detach(handleOrHost, id) takes it off (every library effect of the host when no id)
--   VfxLib.update(handle, info)     optional: a run speed of your own ({ speed }); otherwise the loop measures it
--   VfxLib.play(id, at, opts)       a one-shot (hit, burst, reveal, skill) at a Vector3 / CFrame / host
--   VfxLib.stop(live)               ends a one-shot at once (gone this frame)
--   VfxLib.cancel(live, fade)       ends a one-shot softly: an interrupted attack fades out, nothing left behind
--   VfxLib.get(id), VfxLib.list(kind), VfxLib.measure(idOrHandle), VfxLib.freeze(on)
-- `opts` of both: palette (role colours of your own, for a tintable effect), variant, grade, height / scale, and the
-- one-shot's size, from, angle, adornees (Builder.play).
local Budget = require(script and script.Budget or "./Budget")
local Builder = require(script and script.Builder or "./Builder")
local Lod = require(script and script.Lod or "./Lod")
local Models = require(script and script.Models or "./Models")
local Palette = require(script and script.Palette or "./Palette")
local Quality = require(script and script.Quality or "./Quality")
local Schema = require(script and script.Schema or "./Schema")
local Textures = require(script and script.Textures or "./Textures")

local VfxLib = {}

VfxLib.Budget = Budget
VfxLib.Builder = Builder
VfxLib.Lod = Lod
VfxLib.Models = Models
VfxLib.Palette = Palette
VfxLib.Quality = Quality
VfxLib.Schema = Schema
VfxLib.Textures = Textures

VfxLib.effects = {} -- [id] = effect
VfxLib.prefix = "[VfxLib]"

local ready = false

local function warnOf(message)
	warn(`{VfxLib.prefix} {message}`)
end

-- Adds an effect (checked first: a broken one is refused with a warning, never half-built). A packaged effect
-- (packages/, tools/package.luau) brings the pictures, models and fish it wears in `assets`; they are taken in first.
function VfxLib.register(effect)
	local assets = type(effect) == "table" and effect.assets
	if type(assets) == "table" then
		for key, entry in assets.textures or {} do
			Textures.add(key, entry)
		end
		for key, entry in assets.models or {} do
			Models.add(key, entry)
		end
		for key, entry in assets.fish or {} do
			Models.addFish(key, entry)
		end
	end
	local problem = Schema.problem(effect, Builder.variantOf)
	if problem then
		warnOf(`effect refused: {problem}`)
		return false
	end
	VfxLib.effects[effect.id] = effect
	return true
end

-- Every ModuleScript below `folder` is an effect.
local function registerFolder(folder)
	for _, item in folder:GetDescendants() do
		if item:IsA("ModuleScript") then
			local ok, effect = pcall(require, item)
			if ok then
				VfxLib.register(effect)
			else
				warnOf(`effect {item.Name} failed to load: {effect}`)
			end
		end
	end
end

function VfxLib.setup(options)
	options = options or {}
	if options.log then
		VfxLib.prefix = options.log
	end
	if options.textures then
		Textures.override(options.textures)
	end
	if options.quality then
		Quality.plug(options.quality.get, options.quality.subscribe)
	end
	local folder = options.effects
	if folder == nil and typeof(script) == "Instance" then
		folder = script:FindFirstChild("Effects")
	end
	if folder then
		registerFolder(folder)
	end
	if not ready then
		Quality.onChange(function()
			VfxLib.refresh()
		end)
	end
	local client = pcall(function()
		return game:GetService("RunService"):IsClient()
	end) and game:GetService("RunService"):IsClient()
	if options.start == true or (options.start ~= false and client) then
		Lod.start()
	end
	ready = true
end

local function ensure()
	if not ready and typeof(script) == "Instance" then
		VfxLib.setup({})
	end
end

function VfxLib.get(id)
	ensure()
	return VfxLib.effects[id]
end

-- The effects of a kind (every one when nil), sorted by id.
function VfxLib.list(kind)
	ensure()
	local found = {}
	for id, effect in VfxLib.effects do
		if kind == nil or effect.kind == kind then
			table.insert(found, id)
		end
	end
	table.sort(found)
	return found
end

local function handlesOf(host)
	local found = {}
	for _, handle in Lod.handles do
		if handle.host == host and not handle.dead then
			table.insert(found, handle)
		end
	end
	return found
end

function VfxLib.attach(host, id, opts)
	local effect = VfxLib.get(id)
	if not effect then
		warnOf(`no effect {tostring(id)}`)
		return nil
	end
	if not Budget.Continuous[effect.kind] then
		warnOf(`{id} plays once: use VfxLib.play`)
		return nil
	end
	opts = opts or {}
	for _, handle in handlesOf(host) do
		if handle.id == id and handle.opts.variant == opts.variant and handle.opts.grade == opts.grade then
			return handle -- (the same again changes nothing)
		end
	end
	local handle = Builder.attach(effect, host, opts)
	if handle then
		Lod.add(handle)
		local fields = handle.effect -- (the variant's own start)
		if opts.burst and fields.start then
			local start = table.clone(fields)
			start.kind = "burst"
			start.pieces = fields.start.pieces
			start.light = fields.start.light
			start.bands = nil
			start.variants = nil
			local live = Builder.play(start, host, { palette = opts.palette, grade = opts.grade, scale = handle.scale })
			if live then
				Lod.addShot(live)
			end
		end
	end
	return handle
end

function VfxLib.detach(target, id)
	if type(target) == "table" and target.folder then
		Builder.detach(target)
		return
	end
	for _, handle in handlesOf(target) do
		if id == nil or handle.id == id then
			Builder.detach(handle)
		end
	end
end

function VfxLib.update(handle, info)
	if info.speed then
		handle.speedOverride = info.speed
	end
end

function VfxLib.play(id, at, opts)
	local effect = VfxLib.get(id)
	if not effect then
		warnOf(`no effect {tostring(id)}`)
		return nil
	end
	if Budget.Continuous[effect.kind] then
		warnOf(`{id} lasts: use VfxLib.attach`)
		return nil
	end
	local live = Builder.play(effect, at, opts)
	if live then
		Lod.addShot(live)
	end
	return live
end

function VfxLib.stop(live)
	Builder.stop(live)
end

-- Ends a one-shot softly: an interrupted attack (stun, death, cancel) fades in `fade` seconds instead of popping.
function VfxLib.cancel(live, fade)
	Builder.cancel(live, fade)
end

-- What an effect costs: of a built handle now, or of an id's data at its authored size (and its tier).
function VfxLib.measure(target)
	if type(target) == "table" and target.items then
		return Builder.measure(target)
	end
	local effect = VfxLib.get(target)
	if not effect then
		return nil
	end
	local measured = Budget.measure(effect, Builder.variantOf)
	measured.tier = Budget.tierOf(effect.kind, measured)
	return measured
end

-- Rebuilds every lasting effect (after a quality change: secondary pieces and lights come or go).
function VfxLib.refresh()
	local old = table.clone(Lod.handles)
	for _, handle in old do
		if not handle.dead then
			Builder.detach(handle)
			local fresh = Builder.attach(handle.effect, handle.host, handle.opts)
			if fresh then
				Lod.add(fresh)
			end
		end
	end
end

-- Stops (true) or frees (false) every particle of the library where it is: the showroom freezes a moment for its shot.
function VfxLib.freeze(on)
	Builder.timeScale = if on then 0 else 1
	for _, handle in Lod.handles do
		Builder.setTimeScale(handle, Builder.timeScale)
	end
	for _, live in Lod.shots do
		Builder.setTimeScale(live, Builder.timeScale)
	end
end

return VfxLib
