--!strict
-- The Arena as its own scene, drawn on THIS client only (docs/ARENA.md). `ReplicatedStorage.ArenaStage` is a model (the
-- scene artist builds it in MapWork; its named parts are listed below). When the player attacks, `enter` fades the screen, puts
-- this client's own copy of the model far from the map (Config.Arena.Stage.Origin), points a still camera at the pit from the
-- stands, switches the player's controls off, stands a look-alike of their character in the front row and hands the pit's
-- middle to the replay (ArenaReplay). `leave` fades again, takes everything away and gives the camera and controls back exactly
-- as they were. Nobody else sees any of it, so many players on one server can watch their own fights at once. No camera effects.
--
-- The model's children (found by name, anywhere below it):
--   Pit (BasePart)         the round sand; its top surface's middle is the field's middle.
--   BlueSpot / OrangeSpot  parts on the sand: the player's side and the rival's side.
--   View (BasePart)        its CFrame is the camera's seat in the stands behind the blue side.
--   Avatar (BasePart)      optional: where a look-alike of the player's character stands, facing the pit.
--   Crowd (Folder)         optional: invisible parts named Spot, one a seat (CFrame = the slime's feet, facing the pit). This client
--                          fills them with the game's own slimes (SlimeLook, a still face) in the background (`prepare`); a few
--                          of them hop a little and all cheer when the fight ends.
-- With no model in ReplicatedStorage (it is not built yet) nothing here fails: `enter` hands out the field in front of the
-- player and changes nothing.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Colours = require(ReplicatedStorage.Shared.Colours)
local Config = require(ReplicatedStorage.Shared.Config)
local DualDesigns = require(ReplicatedStorage.Shared.DualDesigns)
local SlimeFace = require(script.Parent.SlimeFace)
local SlimeLook = require(script.Parent.SlimeLook)

local S = Config.Arena.Stage
local R = Config.Arena.View.Replay
local player = Players.LocalPlayer

type Spectator = {
	model: Model,
	base: CFrame,
	nextAt: number,
	hopFrom: number?,
	height: number,
	length: number,
}
type Saved = {
	camera: Camera,
	cameraType: Enum.CameraType,
	subject: Instance?,
	cframe: CFrame,
	focus: CFrame,
	fieldOfView: number,
}

local ArenaStage = {}

-- "out" (nothing shown), "entering" (fading in, the scene is not placed yet), "in" (shown), "leaving" (fading out)
local state = "out"
-- bumped by every enter / leave: a fade that finishes after a newer one began does nothing
local epoch = 0
local stage: Model? = nil
local avatar: Model? = nil
local avatarTrack: AnimationTrack? = nil
local saved: Saved? = nil
local controlsOff: any = nil
local spectators: { Spectator } = {}
-- every slime of the stands made so far, in the order they were made (a shuffled seat order)
local built: { Model } = {}
-- true while the scene is up and its movers are hopping
local crowdOn = false
local crowdLoop: RBXScriptConnection? = nil
local cheerUntil = 0
local cheerHeight = 0
local rng = Random.new()
local fadeGui: ScreenGui? = nil
local fadeFrame: Frame? = nil
local pendingCovered: (() -> ())? = nil

local function safe(label: string, work: () -> ())
	local ok, err = pcall(function(): any
		work()
		return nil
	end)
	if not ok then
		warn(Config.LogPrefix, "arena stage", label, "error:", err)
	end
end

-- ===== The fade =====

local function cover(): Frame
	if not (fadeGui and fadeFrame) then
		local gui = Instance.new("ScreenGui")
		gui.Name = "GooArenaFade"
		gui.ResetOnSpawn = false
		-- (over the whole screen, the top bar's strip too; above every other screen of the game)
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = S.FadeOrder
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Enabled = false
		local frame = Instance.new("Frame")
		frame.Name = "Cover"
		frame.Size = UDim2.fromScale(1, 1)
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.fromHex(Config.Ui.KitOutline)
		frame.BackgroundTransparency = 1
		-- (taps do not reach the screens under it while it is up)
		frame.Active = true
		frame.Parent = gui
		gui.Parent = player:WaitForChild("PlayerGui")
		fadeGui, fadeFrame = gui, frame
	end
	return fadeFrame :: Frame
end

-- Fades the cover to `transparency` and calls `after` when that is done, unless something newer began meanwhile.
local function fade(transparency: number, after: (() -> ())?)
	local frame = cover()
	local gui = fadeGui :: ScreenGui
	local mine = epoch
	gui.Enabled = true
	TweenService:Create(frame, TweenInfo.new(S.FadeSeconds), { BackgroundTransparency = transparency }):Play()
	task.delay(S.FadeSeconds, function()
		if epoch ~= mine then
			return
		end
		if transparency >= 1 then
			gui.Enabled = false
		end
		if after then
			safe("fade", after)
		end
	end)
end

local function hideCover()
	if fadeGui and fadeFrame then
		fadeFrame.BackgroundTransparency = 1
		fadeGui.Enabled = false
	end
end

-- ===== The field when there is no scene =====

local function actorsFolder(): Instance
	return workspace:FindFirstChild("ZombieClientActors") or workspace
end

-- The old field: a spot in front of the player, on the ground, the player's side looking back at it.
local function fallbackField(): (Vector3, Vector3)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local here = if root and root:IsA("BasePart") then root.Position else Vector3.zero
	local look = if root and root:IsA("BasePart")
		then Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		else Vector3.zAxis
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.zAxis
	local ahead = here + look * R.FrontStuds
	local ignore: { Instance } = { actorsFolder() }
	if character then
		table.insert(ignore, character)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(ahead + Vector3.new(0, R.RayUp, 0), Vector3.new(0, -(R.RayUp + R.RayDown), 0), params)
	return Vector3.new(ahead.X, if hit then hit.Position.Y else ahead.Y, ahead.Z), -look
end

-- ===== Camera and controls =====

local function controlModule(): any
	local scripts = player:FindFirstChild("PlayerScripts")
	local module = if scripts then scripts:FindFirstChild("PlayerModule") else nil
	if not (module and module:IsA("ModuleScript")) then
		return nil
	end
	local ok, controls = pcall(function(): any
		return (require(module) :: any):GetControls()
	end)
	return if ok then controls else nil
end

local function takeCamera(view: CFrame, centre: Vector3)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	saved = {
		camera = camera,
		cameraType = camera.CameraType,
		subject = camera.CameraSubject,
		cframe = camera.CFrame,
		focus = camera.Focus,
		fieldOfView = camera.FieldOfView,
	}
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = Config.Arena.Stage.FieldOfView
	camera.CFrame = view
	camera.Focus = CFrame.new(centre)
end

local function giveCameraBack()
	local keep = saved
	saved = nil
	if not keep then
		return
	end
	local camera = keep.camera
	if workspace.CurrentCamera ~= camera then
		return
	end
	-- (a character that respawned meanwhile has a new Humanoid: the old subject is gone)
	local subject = keep.subject
	if not (subject and subject:IsDescendantOf(game)) then
		local character = player.Character
		subject = if character then character:FindFirstChildOfClass("Humanoid") else nil
	end
	camera.CameraSubject = subject :: any
	camera.CFrame = keep.cframe
	camera.Focus = keep.focus
	camera.FieldOfView = keep.fieldOfView
	camera.CameraType = keep.cameraType
end

local function switchControlsOff()
	if controlsOff then
		return
	end
	local controls = controlModule()
	if controls then
		controls:Disable()
		controlsOff = controls
	end
end

local function switchControlsOn()
	local controls = controlsOff
	controlsOff = nil
	if controls then
		controls:Enable()
	end
end

-- ===== The look-alike =====

local function makeAvatar(spot: BasePart, centre: Vector3)
	local character = player.Character
	if not character then
		return
	end
	local was = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = was
	if not copy then
		return
	end
	copy.Name = "ArenaAvatar"
	-- The idle pose comes from the character's own Animate script (its `idle` folder), read before the scripts go.
	local idleId: string? = nil
	local animate = copy:FindFirstChild("Animate")
	local idle = if animate then animate:FindFirstChild(S.AvatarIdle) else nil
	local clip = if idle then idle:FindFirstChildWhichIsA("Animation") else nil
	if clip then
		idleId = clip.AnimationId
	end
	for _, inst in copy:GetDescendants() do
		if inst:IsA("LuaSourceContainer") then
			inst:Destroy()
		end
	end
	for _, inst in copy:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.Anchored = true
			inst.CanCollide = false
			inst.CanTouch = false
			inst.CanQuery = false
		end
	end
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.BreakJointsOnDeath = false
		for _, kind in Enum.HumanoidStateType:GetEnumItems() do
			if kind ~= Enum.HumanoidStateType.None then
				pcall(function()
					humanoid:SetStateEnabled(kind, false)
				end)
			end
		end
	end
	-- Facing the pit, feet on the spot's top surface.
	local top = Vector3.new(spot.Position.X, spot.Position.Y + spot.Size.Y / 2, spot.Position.Z)
	copy:PivotTo(CFrame.lookAt(top, Vector3.new(centre.X, top.Y, centre.Z)))
	local box, size = copy:GetBoundingBox()
	copy:PivotTo(copy:GetPivot() + Vector3.new(0, top.Y - (box.Position.Y - size.Y / 2), 0))
	copy.Parent = stage
	avatar = copy
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if animator and idleId then
		local animation = Instance.new("Animation")
		animation.AnimationId = idleId
		local ok, track = pcall(function(): AnimationTrack
			return animator:LoadAnimation(animation)
		end)
		if ok then
			track.Looped = true
			track:Play()
			avatarTrack = track
		end
		animation:Destroy()
	end
end

local function removeAvatar()
	if avatarTrack then
		pcall(function()
			(avatarTrack :: AnimationTrack):Stop(0)
		end)
		avatarTrack = nil
	end
	if avatar then
		avatar:Destroy()
		avatar = nil
	end
end

-- ===== The crowd =====

local function idleWait(): number
	return rng:NextNumber(S.IdleSeconds[1], S.IdleSeconds[2])
end

local function crowdStep()
	local now = os.clock()
	local cheering = now < cheerUntil
	for _, spectator in spectators do
		local from = spectator.hopFrom
		if from then
			local t = (now - from) / spectator.length
			if t >= 1 then
				spectator.hopFrom = nil
				spectator.model:PivotTo(spectator.base)
				spectator.nextAt = now + (if cheering then rng:NextNumber(0, S.CheerGapSeconds) else idleWait())
			else
				spectator.model:PivotTo(spectator.base + Vector3.new(0, 4 * spectator.height * t * (1 - t), 0))
			end
		elseif now >= spectator.nextAt then
			spectator.hopFrom = now
			local height = if cheering then cheerHeight else S.HopHeight
			spectator.height = height * rng:NextNumber(0.6, 1)
			spectator.length = if cheering then S.CheerHopSeconds else S.HopSeconds
		end
	end
end

-- One more spectator that hops (its seat is where it stands now: the stage is already pivoted to its place).
local function addMover(model: Model)
	table.insert(spectators, {
		model = model,
		base = model:GetPivot(),
		nextAt = os.clock() + idleWait(),
		hopFrom = nil,
		height = S.HopHeight,
		length = S.HopSeconds,
	})
	if not crowdLoop then
		crowdLoop = RunService.Heartbeat:Connect(function()
			safe("crowd", crowdStep)
		end)
	end
end

-- The movers are the first CrowdMax slimes made: the seats were shuffled before filling, so they are spread about the stands.
-- Slimes made after this (the crowd is still being filled) join while there is room.
local function startCrowd()
	table.clear(spectators)
	crowdOn = true
	for index = 1, math.min(#built, S.CrowdMax) do
		addMover(built[index])
	end
end

local function stopCrowd()
	crowdOn = false
	if crowdLoop then
		crowdLoop:Disconnect()
		crowdLoop = nil
	end
	for _, spectator in spectators do
		spectator.model:PivotTo(spectator.base)
	end
	table.clear(spectators)
	cheerUntil = 0
end

-- ===== Filling the stands, ahead of time =====

-- The stage copy of this client: made once, kept for every later fight. Its pictures start loading at once (the play test: put up
-- without it, the crest, banners and shields popped in a second after the fade).
local function ensureStage(template: Model): Model
	local model = stage
	if not model then
		local copy = template:Clone()
		model = copy
		stage = copy
		local pictures = {}
		for _, item in copy:GetDescendants() do
			if item:IsA("Decal") then
				table.insert(pictures, item)
			end
		end
		task.spawn(function()
			ContentProvider:PreloadAsync(pictures)
		end)
	end
	return model :: Model
end

type LookSpec = { attrs: { [string]: any }, weight: number, face: string }

-- What the crowd is made of, in a fixed seeded order: the 11 plain colours, CrowdDuals Dual designs, the named materials.
local function lookSpecs(pick: Random): { LookSpec }
	local specs: { LookSpec } = {}
	local function face(): string
		return S.CrowdFaces[pick:NextInteger(1, #S.CrowdFaces)]
	end
	for _, id in Colours.Ids do
		table.insert(specs, { attrs = { Colour = id }, weight = 1, face = face() })
	end
	local duals: { DualDesigns.Design } = table.clone(DualDesigns.List)
	for _ = 1, math.min(S.CrowdDuals, #duals) do
		local design = table.remove(duals, pick:NextInteger(1, #duals)) :: DualDesigns.Design
		table.insert(specs, {
			attrs = { Colour = design.bodyColour, DualId = design.id },
			weight = S.CrowdDualWeight,
			face = face(),
		})
	end
	for _, id in S.CrowdMaterials do
		table.insert(specs, {
			attrs = { Colour = Colours.Fallback, Material = id },
			weight = S.CrowdMaterialWeight,
			face = face(),
		})
	end
	return specs
end

-- One look: the game's slime body (SlimeLook), CrowdScale times the village's size, with a still face. At the origin, feet down.
local function makeLook(spec: LookSpec): Model
	local model = SlimeLook.build(spec.attrs)
	model:ScaleTo(model:GetScale() * S.CrowdScale)
	local body = model:FindFirstChild("SlimeBody")
	if body and body:IsA("MeshPart") then
		SlimeFace.still(model, body.Size.Y / Config.Slime.MeshHeight, spec.face)
	end
	return model
end

-- "idle" (not begun), "building", "done"
local prepared = "idle"
local prepareLoop: RBXScriptConnection? = nil

local function finishPrepare()
	prepared = "done"
	if prepareLoop then
		prepareLoop:Disconnect()
		prepareLoop = nil
	end
end

-- Starts making the stage copy and filling its stands with this client's slimes, a few steps a frame, once per session. Safe to
-- call again and again (the Arena screen opening, a fight starting): what is under way carries on, what is done stays. With no
-- scene model or no slime kit yet it does nothing and a later call tries again.
function ArenaStage.prepare()
	if prepared ~= "idle" then
		return
	end
	local template = ReplicatedStorage:FindFirstChild("ArenaStage")
	if not (template and template:IsA("Model") and ReplicatedStorage:FindFirstChild("ClientKit")) then
		return
	end
	prepared = "building"
	local pick = Random.new(S.CrowdSeed)
	local specs = lookSpecs(pick)
	local looks: { { model: Model, weight: number } } = {}
	local totalWeight = 0
	local seats: { BasePart }? = nil
	local nextSeat = 1
	local crowd: Instance? = nil
	local function place()
		local list = seats :: { BasePart }
		local spot = list[nextSeat]
		nextSeat += 1
		-- (a seat picks a look by weight)
		local roll = pick:NextNumber(0, totalWeight)
		local chosen = looks[#looks]
		for _, look in looks do
			roll -= look.weight
			if roll <= 0 then
				chosen = look
				break
			end
		end
		local model = chosen.model:Clone()
		model.Name = "Spectator"
		model:ScaleTo(model:GetScale() * (1 + pick:NextNumber(-S.CrowdScaleJitter, S.CrowdScaleJitter)))
		model:PivotTo(spot.CFrame * CFrame.Angles(0, pick:NextNumber(-S.CrowdYawJitter, S.CrowdYawJitter), 0))
		model.Parent = crowd
		spot:Destroy()
		table.insert(built, model)
		if crowdOn and #spectators < S.CrowdMax then
			addMover(model)
		end
	end
	local function step()
		if not stage then
			-- (the copy is a frame's work of its own)
			ensureStage(template)
			return
		end
		if not seats then
			crowd = stage:FindFirstChild("Crowd", true)
			local found: { BasePart } = {}
			if crowd then
				for _, child in crowd:GetChildren() do
					if child:IsA("BasePart") and child.Name == "Spot" then
						table.insert(found, child)
					end
				end
			end
			-- (shuffled, so slimes appear all over the stands as they are made, and the first few to hop are spread out)
			for index = #found, 2, -1 do
				local other = pick:NextInteger(1, index)
				found[index], found[other] = found[other], found[index]
			end
			seats = found
			return
		end
		for _ = 1, S.CrowdPerFrame do
			if #looks < #specs then
				local spec = specs[#looks + 1]
				local look = { model = makeLook(spec), weight = spec.weight }
				table.insert(looks, look)
				totalWeight += spec.weight
			elseif nextSeat <= #seats then
				place()
			else
				finishPrepare()
				return
			end
		end
	end
	prepareLoop = RunService.Heartbeat:Connect(function()
		local ok, err = pcall(function(): any
			step()
			return nil
		end)
		if not ok then
			warn(Config.LogPrefix, "arena crowd stopped:", err)
			finishPrepare()
		end
	end)
end

-- ===== Putting the scene up and taking it down =====

-- Everything this client put up, taken down; each step on its own so one failing leaves the rest done. Safe at any time.
local function takeDown()
	safe("crowd", stopCrowd)
	safe("avatar", removeAvatar)
	if stage then
		stage.Parent = nil
	end
	safe("camera", giveCameraBack)
	safe("controls", switchControlsOn)
end

local function find(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

-- The top of the sand in its middle: a ray down onto the Pit alone (it may be a round part whose axis is not up).
local function pitTop(pit: BasePart): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { pit }
	local hit =
		workspace:Raycast(pit.Position + Vector3.new(0, S.PitRayUp, 0), Vector3.new(0, -2 * S.PitRayUp, 0), params)
	return if hit then hit.Position else pit.Position + Vector3.new(0, pit.Size.Y / 2, 0)
end

-- Copies the scene (once, kept for later fights), pivots it to Origin, takes the camera and controls. Returns the pit's middle
-- and the flat direction from it to the blue side.
local function putUp(template: Model): (Vector3, Vector3)
	local scene = ensureStage(template)
	local folder = workspace:FindFirstChild("ArenaStageClient")
	if not folder then
		local made = Instance.new("Folder")
		made.Name = "ArenaStageClient"
		made.Parent = workspace
		folder = made
	end
	scene:PivotTo(CFrame.new(S.Origin.x, S.Origin.y, S.Origin.z) * scene:GetPivot().Rotation)
	scene.Parent = folder
	local pit, view = find(scene, "Pit"), find(scene, "View")
	if not (pit and view) then
		error("ArenaStage needs a Pit and a View")
	end
	local centre = pitTop(pit)
	local blue = find(scene, "BlueSpot")
	local toward = if blue then Vector3.new(blue.Position.X - centre.X, 0, blue.Position.Z - centre.Z) else Vector3.zero
	if toward.Magnitude < 1e-3 then
		toward = Vector3.new(view.Position.X - centre.X, 0, view.Position.Z - centre.Z)
	end
	local toPlayer = if toward.Magnitude > 1e-3 then toward.Unit else Vector3.zAxis
	takeCamera(view.CFrame, centre)
	switchControlsOff()
	local spot = find(scene, "Avatar")
	if spot then
		safe("avatar", function()
			makeAvatar(spot, centre)
		end)
	end
	safe("crowd", function()
		startCrowd()
	end)
	return centre, toPlayer
end

-- ===== The calls =====

-- True while the scene is up or on its way (a fight is being shown there).
function ArenaStage.active(): boolean
	return state ~= "out"
end

-- Fades the screen, puts the scene up while it is covered, calls `onReady(centre, toPlayer)` (the field's middle and the flat
-- unit direction from it towards the player's side), then fades back in. With no scene model, `onReady` is called at once with
-- the field in front of the player and nothing changes.
function ArenaStage.enter(onReady: (centre: Vector3, toPlayer: Vector3) -> ())
	if state ~= "out" then
		ArenaStage.leaveNow()
	end
	local template = ReplicatedStorage:FindFirstChild("ArenaStage")
	if not (template and template:IsA("Model")) then
		onReady(fallbackField())
		return
	end
	-- (normally begun when the Arena screen opened; what is not made by the time the scene shows appears as it is made)
	ArenaStage.prepare()
	epoch += 1
	local mine = epoch
	state = "entering"
	fade(0, function()
		local centre: Vector3? = nil
		local toPlayer: Vector3? = nil
		local ok, err = pcall(function(): any
			centre, toPlayer = putUp(template)
			return nil
		end)
		if not ok then
			warn(Config.LogPrefix, "arena stage could not be put up:", err)
			takeDown()
			centre, toPlayer = fallbackField()
			state = "out"
		else
			state = "in"
		end
		safe("onReady", function()
			onReady(centre :: Vector3, toPlayer :: Vector3)
		end)
		-- (the caller ended the scene from inside onReady: its own fade is under way, do not fight it)
		if epoch == mine then
			fade(1, nil)
		end
	end)
end

-- Ends the scene at once, no fade: the callbacks of a `leave` still waiting are dropped (the cover step first, so what the
-- caller made is cleaned up; `onDone` is not called, as ArenaReplay.stop() promises). Safe when nothing is shown.
function ArenaStage.leaveNow()
	epoch += 1
	local covered = pendingCovered
	pendingCovered = nil
	takeDown()
	hideCover()
	state = "out"
	if covered then
		safe("onCovered", covered)
	end
end

-- Fades the screen, takes the scene away while it is covered (`onCovered` runs then: the caller removes what it drew there),
-- gives back the camera and controls, fades in and calls `onDone`. With nothing shown both run at once. Safe to call twice.
function ArenaStage.leave(onDone: (() -> ())?, onCovered: (() -> ())?)
	if state ~= "in" then
		ArenaStage.leaveNow()
		if onCovered then
			safe("onCovered", onCovered)
		end
		if onDone then
			safe("onDone", onDone)
		end
		return
	end
	epoch += 1
	state = "leaving"
	pendingCovered = onCovered
	fade(0, function()
		local covered = pendingCovered
		pendingCovered = nil
		takeDown()
		if covered then
			safe("onCovered", covered)
		end
		fade(1, function()
			state = "out"
			if onDone then
				safe("onDone", onDone)
			end
		end)
	end)
end

-- The crowd cheers (the fight is over): `won` is the player's win, which is louder and longer than a loss.
function ArenaStage.cheer(won: boolean)
	if state ~= "in" then
		return
	end
	local cheer = if won then S.CheerWin else S.CheerLoss
	cheerHeight = cheer.Height
	local now = os.clock()
	cheerUntil = now + cheer.Seconds
	for _, spectator in spectators do
		if not spectator.hopFrom then
			spectator.nextAt = now + rng:NextNumber(0, S.CheerGapSeconds)
		end
	end
end

return ArenaStage
