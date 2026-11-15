--!strict
-- The forge scene (docs/SMITHY.md §7, the owner 2026-11-15): once the server has made or tempered a piece, a few seconds at
-- the Market's anvil. The camera glides to the anvil; a copy of the hammer lying on it strikes two or three times (sparks,
-- the anvil's ring, the face heating towards the tier's colour); the piece rises out of the face, growing and turning, with
-- its tier's burst (and, from Core up, its weapon aura); its name shows over it; the camera glides back. A tempered piece
-- steams as it rises (the quench). Only a show: the server has already given the piece. The village screens hide while it
-- plays; after the first scene of a tier in a session, a tap skips it. Numbers in Config.Ui.Forge; the effects come from
-- the VFX library (one it does not have yet is left out).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local VfxLib = require(ReplicatedStorage.Shared.VfxLib)
local SlimeWeapon = require(script.Parent.SlimeWeapon)
local UiKit = require(script.Parent.UiKit)

local F = Config.Ui.Forge
local S = Config.Smithy
local W = Config.Weapons
local player = Players.LocalPlayer

local ForgeScene = {}
local busy = false
local seen: { [string]: boolean } = {}

local function has(id: string): boolean
	local ok, effect = pcall(VfxLib.get, id)
	return ok and effect ~= nil
end

local function effect(id: string, at: CFrame, variant: string)
	if has(id) then
		pcall(VfxLib.play, id, at, { variant = variant })
	end
end

local function sound(name: string, parent: Instance, speed: number?): Sound
	local entry: any = (F.Sounds :: any)[name]
	local made = Instance.new("Sound")
	made.SoundId = "rbxassetid://" .. tostring(entry.id)
	made.Volume = entry.volume
	made.PlaybackSpeed = (entry.speed or 1) * (speed or 1)
	made.Parent = parent
	made:Play()
	return made
end

local function easeOut(x: number): number
	x = math.clamp(x, 0, 1)
	return 1 - (1 - x) * (1 - x)
end

local function easeInOut(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- A part of the Blacksmith model by name.
local function partOf(smith: Instance, name: string): BasePart?
	local found = smith:FindFirstChild(name)
	return if found and found:IsA("BasePart") then found else nil
end

-- The picture of a piece (its `icon`: an asset id or a link), or nil.
local function imageOf(def: any): string?
	local icon = def.icon
	if type(icon) == "number" and icon > 0 then
		return "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and icon ~= "" then
		return icon
	end
	return nil
end

-- Plays the scene for the piece the server has just made (`gearId`) or tempered (`gearId` is then the tempered twin's).
-- Yields until the scene is over; a scene already playing, or a Market without its anvil, plays nothing.
function ForgeScene.play(gearId: string, tempered: boolean)
	local def: any = (S.Gear :: any)[gearId]
	local plain: any = if def and def.base then (S.Gear :: any)[def.base] else def
	local map = workspace:FindFirstChild("Map")
	local market = if map then map:FindFirstChild("Market") else nil
	local smith = if market then market:FindFirstChild(F.Anvil) else nil
	local face = if smith then partOf(smith, "AnvilFace") else nil
	local head = if smith then partOf(smith, "HammerHead") else nil
	local handle = if smith then partOf(smith, "HammerHandle") else nil
	local camera = workspace.CurrentCamera
	local gui = player:FindFirstChild("PlayerGui")
	if busy or not plain or not face or not head or not handle or not camera or not gui then
		return
	end
	busy = true
	local tier: string = plain.tier
	local variant = tier
	local heat = Color3.fromHex((F.Heat :: any)[tier] or F.Heat.wood)
	local hot = Color3.fromHex(F.HotFace)
	local colour = Color3.fromHex(((S.Tiers :: any)[tier] or S.Tiers.wood).colour)
	-- (the weapon's mesh may not be loaded yet: asking now gives it the strikes' time)
	SlimeWeapon.copy(gearId, F.WeaponLength)

	-- Where everything stands: the face's top, the camera's spot (towards the player, turned aside), the hammer's hinge.
	local up = face.CFrame.UpVector
	local top = face.Position + up * (face.Size.Y / 2)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local toward = if root and root:IsA("BasePart") then root.Position - top else face.CFrame.LookVector
	toward = Vector3.new(toward.X, 0, toward.Z)
	toward = if toward.Magnitude > 0.01 then toward.Unit else Vector3.zAxis
	toward = CFrame.Angles(0, math.rad(F.SideAngle), 0):VectorToWorldSpace(toward)
	local look = top + up * F.LookUp
	local shot = CFrame.lookAt(top + toward * F.CameraBack + up * F.CameraUp, look)
	local saved = {
		cframe = camera.CFrame,
		focus = camera.Focus,
		fieldOfView = camera.FieldOfView,
		cameraType = camera.CameraType,
		subject = camera.CameraSubject,
	}
	camera.CameraType = Enum.CameraType.Scriptable
	local hidden: { ScreenGui } = {}
	for _, screen in gui:GetChildren() do
		if screen:IsA("ScreenGui") and screen.Enabled then
			screen.Enabled = false
			table.insert(hidden, screen)
		end
	end
	-- (the player's own character, and what its avatar carries, would stand in the shot: hidden for this player)
	local veiled: { Instance } = {}
	local stilled: { Instance } = {}
	if character then
		for _, item in character:GetDescendants() do
			if item:IsA("BasePart") or item:IsA("Decal") then
				(item :: any).LocalTransparencyModifier = 1
				table.insert(veiled, item)
			elseif (item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail")) and (item :: any).Enabled then
				(item :: any).Enabled = false
				table.insert(stilled, item)
			end
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = "ForgeScene"
	folder.Parent = workspace
	local hammer = Instance.new("Model")
	hammer.Name = "Hammer"
	for _, part in { head, handle } do
		local copy = part:Clone()
		copy:ClearAllChildren()
		copy.Anchored = true
		copy.CanCollide = false
		copy.CanQuery = false
		copy.CanTouch = false
		copy.Parent = hammer
		part.LocalTransparencyModifier = 1
	end
	hammer.Parent = folder
	local rest = hammer:GetPivot()
	local along = head.Position - handle.Position
	along = Vector3.new(along.X, 0, along.Z)
	along = if along.Magnitude > 0.01 then along.Unit else handle.CFrame.LookVector
	local reach = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)
	local hinge = handle.Position - along * (reach / 2)
	local axis = along:Cross(Vector3.yAxis)
	local strikeAt = CFrame.new(Vector3.new(head.Position.X, top.Y, head.Position.Z))
	local light = Instance.new("PointLight")
	light.Color = heat
	light.Range = F.HeatRange
	light.Brightness = 0
	light.Parent = face
	local faceColour = face.Color

	local hits: number = (F.Hits :: any)[tier] or 2
	local riseAt = F.FirstHit + hits * F.HitGap + F.RiseDelay
	local cardAt = riseAt + F.Rising
	local backAt = cardAt + ((F.Hold :: any)[tier] or F.Hold.wood)
	local finish = backAt + F.Back

	local skip: TextButton? = nil
	local skipped = false
	if seen[tier] then
		local layer = UiKit.make("ScreenGui", {
			Name = "ForgeSkip",
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			DisplayOrder = 50,
		}, gui)
		local button: TextButton = UiKit.make("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromScale(1, 1),
		}, layer)
		button.Activated:Connect(function()
			skipped = true
		end)
		skip = button
	end

	local piece: BasePart? = nil
	local pieceSize = Vector3.one
	local aura: any = nil
	local auraTried = false
	local card: BillboardGui? = nil
	local steam: Sound? = nil
	local struck = 0
	local lastStrike = -math.huge
	local start = os.clock()
	while true do
		RunService.RenderStepped:Wait()
		local t = if skipped then finish else os.clock() - start
		-- the camera: in, held, back
		local into = if t < F.Glide
			then easeOut(t / F.Glide)
			elseif t < backAt then 1
			else 1 - easeInOut((t - backAt) / F.Back)
		camera.CFrame = saved.cframe:Lerp(shot, into)
		camera.FieldOfView = saved.fieldOfView + (F.FieldOfView - saved.fieldOfView) * into
		-- the hammer: each blow lifts (most of the gap) and falls (the last Fall of it)
		local angle = 0
		for blow = 1, hits do
			local landAt = F.FirstHit + blow * F.HitGap
			local liftAt = landAt - F.HitGap
			local fallAt = landAt - F.HitGap * F.Fall
			if t >= liftAt and t < fallAt then
				angle = easeOut((t - liftAt) / (fallAt - liftAt))
			elseif t >= fallAt and t < landAt then
				local x = (t - fallAt) / (landAt - fallAt)
				angle = 1 - x * x
			end
			if t >= landAt and struck < blow then
				struck = blow
				lastStrike = t
				effect(F.Effects.strike, strikeAt, variant)
				sound("strike", face, 0.95 + 0.1 * math.random())
				face.Color = faceColour:Lerp(hot, F.HeatShare * blow / hits)
			end
		end
		local swing = CFrame.new(hinge) * CFrame.fromAxisAngle(axis, math.rad(F.HammerTip) * angle) * CFrame.new(-hinge)
		hammer:PivotTo(CFrame.new(up * F.HammerLift * angle) * swing * rest)
		light.Brightness = F.HeatLight * math.clamp(1 - (t - lastStrike) / F.HeatFade, 0, 1)
		-- the piece: out of the face at riseAt, growing, rising and turning, then turning slowly
		if t >= riseAt and not piece then
			local made = SlimeWeapon.copy(gearId, F.WeaponLength)
			if made then
				pieceSize = made.Size
				made.Size = pieceSize * F.StartScale
			else
				local holder: BasePart = UiKit.make("Part", {
					Transparency = 1,
					Anchored = true,
					CanCollide = false,
					CanQuery = false,
					CanTouch = false,
					Size = Vector3.new(F.WeaponLength, F.WeaponLength, 0.2),
				})
				pieceSize = holder.Size
				local board = UiKit.make("BillboardGui", {
					Size = UDim2.fromOffset(F.IconSize, F.IconSize),
					LightInfluence = 0,
				}, holder)
				UiKit.make("ImageLabel", {
					BackgroundTransparency = 1,
					Image = imageOf(def) or imageOf(plain) or "",
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
				}, board)
				UiKit.make("UIScale", { Name = "Grow", Scale = F.StartScale }, board)
				made = holder
			end
			local built = made :: BasePart
			built.Name = "Piece"
			built.Parent = folder
			piece = built
			effect(F.Effects.reveal, CFrame.new(top), variant)
			sound("ting", face)
			if tempered then
				effect(F.Effects.quench, CFrame.new(top), variant)
				steam = sound("steam", face)
			end
		end
		local shown = piece
		if shown then
			local k = easeOut((t - riseAt) / F.Rising)
			local scale = F.StartScale + (1 - F.StartScale) * k
			local board = shown:FindFirstChildOfClass("BillboardGui")
			local grow = if board then board:FindFirstChild("Grow") else nil
			if grow and grow:IsA("UIScale") then
				grow.Scale = scale
			else
				shown.Size = pieceSize * scale
			end
			local turn = math.pi * 2 * F.Turns * k + math.max(0, t - cardAt) * F.SpinAfter
			local foot = top + up * (F.Hover * k + pieceSize.Y * scale / 2)
			shown.CFrame = CFrame.new(foot) * CFrame.Angles(0, turn, 0)
			-- (the aura is sized by its host when attached: it waits until the weapon is nearly full size)
			if k >= F.AuraAt and not auraTried then
				auraTried = true
				local auraId = W.Fx.Aura .. tostring(plain.family)
				if not board and (W.Fx.AuraTiers :: any)[tier] and has(auraId) then
					local ok, handleOf = pcall(VfxLib.attach, shown, auraId, { variant = tier, weld = true })
					aura = if ok then handleOf else nil
				end
			end
			if t >= cardAt and not card then
				local named: BillboardGui = UiKit.make("BillboardGui", {
					Name = "Card",
					Size = UDim2.fromOffset(F.CardWidth, F.CardHeight),
					StudsOffsetWorldSpace = Vector3.new(0, pieceSize.Y / 2 + F.CardAbove, 0),
					LightInfluence = 0,
				}, shown)
				local label = UiKit.label(named, tostring(def.name), F.CardText, nil, {
					TextColor3 = colour,
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.fromScale(1, 1),
				})
				UiKit.make("UIStroke", { Color = UiKit.colour("Wood"), Thickness = 3 }, label)
				local pop = UiKit.make("UIScale", { Scale = 0.4 }, named)
				UiKit.tween(pop, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
				card = named
			end
		end
		local hiss = steam
		if hiss and t >= riseAt + F.Sounds.steam.seconds then
			hiss:Stop()
			steam = nil
		end
		if t >= backAt then
			face.Color = faceColour:Lerp(hot, F.HeatShare * (1 - easeInOut((t - backAt) / F.Back)))
		end
		if t >= finish then
			break
		end
	end

	-- Everything back as it was.
	if aura then
		pcall(VfxLib.detach, aura)
	end
	folder:Destroy()
	light:Destroy()
	face.Color = faceColour
	head.LocalTransparencyModifier = 0
	handle.LocalTransparencyModifier = 0
	local layer = if skip then skip.Parent else nil
	if layer then
		layer:Destroy()
	end
	for _, screen in hidden do
		screen.Enabled = true
	end
	for _, item in veiled do
		(item :: any).LocalTransparencyModifier = 0
	end
	for _, item in stilled do
		(item :: any).Enabled = true
	end
	if workspace.CurrentCamera == camera then
		local subject = saved.subject
		if not (subject and subject:IsDescendantOf(game)) then
			local now = player.Character
			subject = if now then now:FindFirstChildOfClass("Humanoid") else nil
		end
		camera.CameraSubject = subject :: any
		camera.CFrame = saved.cframe
		camera.Focus = saved.focus
		camera.FieldOfView = saved.fieldOfView
		camera.CameraType = saved.cameraType
	end
	seen[tier] = true
	busy = false
end

return ForgeScene
