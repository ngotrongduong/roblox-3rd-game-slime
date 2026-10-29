--!strict
-- Draws a replicated appearance on the owner's shared rig; no genetics are decided here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Colours = require(ReplicatedStorage.Shared.Colours)
local Config = require(ReplicatedStorage.Shared.Config)
local DualDesigns = require(ReplicatedStorage.Shared.DualDesigns)
local Materials = require(ReplicatedStorage.Shared.Materials)
local SkinIds = require(ReplicatedStorage.Shared.SkinIds)

local C = Config.VillageClient
local SlimeLook = {}
local logged: { [string]: boolean } = {}
local surfaceCache: { [string]: SurfaceAppearance } = {}

local function missing(what: string)
	if not logged[what] then
		logged[what] = true
		warn(Config.LogPrefix, what)
	end
end

local function tint(hex: string): Color3
	return Color3.fromHex(hex)
end

local function hullColour(col: Color3): Color3
	local shade = Config.Material.HullShade
	return Color3.new(col.R * shade, col.G * shade, col.B * shade)
end

local function template(map: string, colour: Color3, mirror: boolean, fine: boolean): SurfaceAppearance
	local key = map .. ":" .. tostring(colour) .. ":" .. tostring(mirror) .. ":" .. tostring(fine)
	local saved = surfaceCache[key]
	if saved then
		return saved
	end
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = map
	sa.NormalMap = C.NormalMap
	sa.RoughnessMap = if fine then C.RoughMetalMap else C.RoughMap
	sa.Color = colour
	if mirror then
		sa.MetalnessMap = C.WhiteMap
	end
	-- A SurfaceAppearance belongs to one MeshPart, so cache the immutable template/texture selection,
	-- but clone its instance for each independent body.
	surfaceCache[key] = sa
	return sa
end

local function partFromKit(name: string): MeshPart?
	local kit = ReplicatedStorage:FindFirstChild("ClientKit")
	local source = if kit then kit:FindFirstChild(name) else nil
	if source and source:IsA("MeshPart") then
		return source
	elseif source and source:IsA("Model") then
		return source:FindFirstChildWhichIsA("MeshPart", true)
	end
	missing("missing ClientKit/" .. name)
	return nil
end

local function standIn(): Model
	local model = Instance.new("Model")
	local part = Instance.new("Part")
	part.Name = "MissingSlimeBody"
	part.Size = Vector3.new(C.StandInSize, C.StandInSize, C.StandInSize)
	part.Color = tint(C.StandInColour)
	part.Material = Enum.Material.SmoothPlastic
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.CFrame = CFrame.new(0, C.StandInSize / 2, 0)
	part.Parent = model
	model.WorldPivot = CFrame.new()
	return model
end

-- The server sends an appearance id, visible base colour and scale; all reads are checked.
function SlimeLook.build(attrs: { [string]: any }): Model
	local base = partFromKit("SlimeBody")
	if not base then
		local fallback = standIn()
		local scale = attrs.Scale
		fallback:ScaleTo(C.BodyHeight * (if type(scale) == "number" then math.clamp(scale, C.MinimumBodyScale, 1) else 1))
		return fallback
	end

	local colourName = if type(attrs.Colour) == "string" then attrs.Colour else Colours.Fallback
	local colourDef = Colours.get(colourName) or Colours.get(Colours.Fallback)
	local baseHex = if colourDef then colourDef.swatch else "#3f9ff0"
	local drawn = tint(baseHex)
	local surfaceColour = drawn
	local map = C.WhiteMap
	local material = if type(attrs.Material) == "string" then Materials.get(attrs.Material) else nil
	local dual = if type(attrs.DualId) == "string" then DualDesigns.get(attrs.DualId) else nil
	local secret = if type(attrs.SecretId) == "string" then attrs.SecretId else nil
	local surface = true
	local fine, mirror, alpha = false, false, 0
	local robloxMaterial = Enum.Material.SmoothPlastic
	local hullOn = true

	if secret and secret ~= "" then
		missing("missing Secret art " .. secret)
	elseif material then
		if material.colour then
			drawn = tint(material.colour)
		end
		surfaceColour = drawn
		fine = material.roughness == 0.03
		alpha = material.transparency
		hullOn = material.hull
		if material.draw == "mirror" then
			map = C.MirrorMap
			mirror = true
		elseif material.draw == "roblox" then
			surface = false
			local enumName = material.robloxMaterial
			if enumName then
				local ok, choice = pcall(function()
					return (Enum.Material :: any)[enumName]
				end)
				if ok and choice then
					robloxMaterial = choice
				end
			end
		end
	elseif dual then
		local image = SkinIds.get(dual.id)
		if image then
			map = "rbxassetid://" .. tostring(image)
			surfaceColour = Color3.new(1, 1, 1)
			drawn = tint((Colours.get(dual.bodyColour) or colourDef :: any).swatch)
		else
			missing("missing Dual skin " .. dual.id)
		end
	end

	local body = base:Clone()
	body.Name = "SlimeBody"
	body.PivotOffset = CFrame.new()
	body.CFrame = CFrame.new(0, Config.Slime.MeshCentre, 0)
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.CastShadow = false
	body.Color = drawn
	body.Material = robloxMaterial
	body.Transparency = alpha
	for _, old in body:GetChildren() do
		if old:IsA("SurfaceAppearance") then
			old:Destroy()
		end
	end
	if surface then
		template(map, surfaceColour, mirror, fine):Clone().Parent = body
	end

	local model = Instance.new("Model")
	body.Parent = model
	local originalHull = if hullOn then partFromKit("SlimeBodyOutline") else nil
	if originalHull then
		local hull = originalHull:Clone()
		hull.Name = "SlimeBodyOutline"
		hull.PivotOffset = CFrame.new()
		hull.CFrame = body.CFrame
		hull.Anchored = true
		hull.CanCollide = false
		hull.CanTouch = false
		hull.CanQuery = false
		hull.CastShadow = false
		hull.Color = hullColour(drawn)
		hull.Material = Enum.Material.SmoothPlastic
		hull.Parent = model
	end
	model.WorldPivot = CFrame.new()
	local scale = attrs.Scale
	model:ScaleTo(C.BodyHeight * (if type(scale) == "number" then math.clamp(scale, C.MinimumBodyScale, 1) else 1))
	if attrs.Ghost == true then
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				item.Transparency = math.max(item.Transparency, C.GhostTransparency)
				item.Color = item.Color:Lerp(Color3.new(1, 1, 1), C.GhostWhiten)
			end
		end
	end
	return model
end

return SlimeLook
