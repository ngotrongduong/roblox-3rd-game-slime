--!strict
-- The three zombie looks (Config.Zombies.Looks): the village's own slime body drawn in a sick colour, a Roblox material
-- and an unpleasant face, bigger the rarer the kind. A stand-in until the owner's zombie art exists.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Expressions = require(ReplicatedStorage.Shared.Expressions)
local FaceArt = require(ReplicatedStorage.Shared.FaceArt)
local SlimeLook = require(script.Parent.SlimeLook)
local UiKit = require(script.Parent.UiKit)

local Z = Config.Zombies
local U = Config.Ui
local C = Config.VillageClient

local ZombieLook = {}

function ZombieLook.look(
	kind: string
): { colour: string, outline: string, material: string, face: string, size: number }
	return (Z.Looks :: any)[kind] or Z.Looks.rotten
end

-- A zombie body at its feet, scaled for its kind. Not yet animated.
function ZombieLook.build(kind: string): Model
	local look = ZombieLook.look(kind)
	local model = SlimeLook.build({ Scale = 1 })
	local body = model:FindFirstChild("SlimeBody")
	if body and body:IsA("MeshPart") then
		-- The slime's tinted skin is replaced by a plain Roblox material in the kind's colour.
		for _, old in body:GetChildren() do
			if old:IsA("SurfaceAppearance") then
				old:Destroy()
			end
		end
		body.Color = Color3.fromHex(look.colour)
		local ok, material = pcall(function()
			return (Enum.Material :: any)[look.material]
		end)
		body.Material = if ok and material then material else Enum.Material.SmoothPlastic
		local hull = model:FindFirstChild("SlimeBodyOutline")
		if hull and hull:IsA("MeshPart") then
			hull.Color = Color3.fromHex(look.outline)
		end
	end
	model:ScaleTo(C.BodyHeight * look.size)
	return model
end

-- A small picture of a kind for a sheet: the real body in a viewport with the face laid over it (as UiSlimes does).
function ZombieLook.icon(parent: Instance?, kind: string, size: number, props: UiKit.Props?): ViewportFrame
	local view = UiKit.make("ViewportFrame", {
		Name = kind,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Ambient = Color3.new(1, 1, 1),
		LightColor = Color3.new(1, 1, 1),
	}, nil) :: ViewportFrame
	if props then
		for key, value in props do
			(view :: any)[key] = value
		end
	end
	local world = UiKit.make("WorldModel", nil, view)
	local model = ZombieLook.build(kind)
	-- (every kind is drawn at the same height here, so a rare one does not crop)
	model:ScaleTo(C.BodyHeight)
	model:PivotTo(CFrame.Angles(0, math.pi, 0))
	model.Parent = world
	local camera = UiKit.make("Camera", nil, view)
	camera.CFrame = CFrame.lookAt(
		Vector3.new(0, C.BodyHeight * U.PortraitEye, C.BodyHeight * U.PortraitDistance),
		Vector3.new(0, C.BodyHeight * U.PortraitLook, 0)
	)
	view.CurrentCamera = camera
	local unit = U.PortraitFaceZoom / (2 * U.PortraitDistance * math.tan(math.rad(U.PortraitFov / 2)))
	local expression = Expressions.get(ZombieLook.look(kind).face)
	if expression then
		for _, name in { expression.eyeL, expression.eyeR, expression.mouth } do
			local sprite = (FaceArt.Sprites :: any)[name]
			if sprite then
				UiKit.make("ImageLabel", {
					Name = name,
					BackgroundTransparency = 1,
					Image = "rbxassetid://" .. tostring(sprite.id),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(
						0.5 + sprite.cx * unit,
						0.5 - (FaceArt.FaceHeight - U.PortraitLook + sprite.cy) * unit
					),
					Size = UDim2.fromScale(sprite.w * unit, sprite.h * unit),
				}, view)
			end
		end
	end
	view.Parent = parent
	return view
end

return ZombieLook
