--!strict
-- Client-side village inhabitants. The server owns every action and leg clock; this script only draws them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeLook = require(script.Parent.SlimeLook)
local VillagePath = require(ReplicatedStorage.Shared.VillagePath)

local C = Config.VillageClient
type Entry = {
	config: Configuration,
	model: Model?,
	actor: SlimeActor.Slime?,
	connections: { RBXScriptConnection },
	signature: string,
	lastUpdate: number,
	carryName: string,
	carry: Model?,
	lastAction: string,
	lastEmotion: string,
	lastPhase: string,
	-- the stand's rod hidden by this slime, and the fishing place whose rod it last held
	rod: Model?,
	rodSlot: number,
	-- the tool held in front of the body, the bobber on its line, where the line lands
	tool: Model?,
	toolName: string,
	bobber: Model?,
	castKey: string,
	castPoint: Vector3?,
	-- the item flying between the slime and a bin during a hand event
	flight: Model?,
	flightKey: string,
}
type Village = {
	root: Folder,
	slimes: { [Instance]: Entry },
	eggs: { [Instance]: Model },
	connections: { RBXScriptConnection },
}
local villages: { [Folder]: Village } = {}
local logged: { [string]: boolean } = {}
local renderFolder = Instance.new("Folder")
renderFolder.Name = "VillageClientActors"
renderFolder.Parent = workspace

local function missing(name: string)
	if not logged[name] then
		logged[name] = true
		warn(Config.LogPrefix, "missing ClientKit/" .. name .. "; drawing neutral stand-in")
	end
end

local function number(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if type(value) == "number" and value == value then value else default
end

local function stringAttr(inst: Instance, name: string, default: string): string
	local value = inst:GetAttribute(name)
	return if type(value) == "string" then value else default
end

local function at(inst: Instance, prefix: string): Vector3
	return Vector3.new(number(inst, prefix .. "X", 0), number(inst, prefix .. "Y", 0), number(inst, prefix .. "Z", 0))
end

local function asset(name: string): Model
	local kit = ReplicatedStorage:FindFirstChild("ClientKit")
	local items = if kit then kit:FindFirstChild("Items") else nil
	local original = if name == "Egg"
		then (if kit then kit:FindFirstChild("Egg") else nil)
		else (if items then items:FindFirstChild(name) else nil)
	local model = Instance.new("Model")
	model.Name = name
	if original and original:IsA("Model") then
		for _, child in original:GetChildren() do
			child:Clone().Parent = model
		end
		-- Keep the kit's pivot (a tool's is the foot of its handle), not the new model's bounding-box centre.
		-- (carried food keeps the centre: it rests on the head by its bounding box)
		if name == "FishingRod" or name == "Hoe" then
			model.WorldPivot = original:GetPivot()
		end
	elseif original and original:IsA("BasePart") then
		original:Clone().Parent = model
	else
		missing(if name == "Egg" then "Egg" else "Items/" .. name)
		local part = Instance.new("Part")
		part.Name = "MissingArt"
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(C.StandInSize, C.StandInSize, C.StandInSize)
		part.Color = Color3.fromHex(C.StandInColour)
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = model
	end
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
			desc.CastShadow = false
		end
	end
	return model
end

local function clearEntry(entry: Entry)
	for _, conn in entry.connections do
		conn:Disconnect()
	end
	if entry.actor then
		SlimeActor.destroy(entry.actor)
	end
	if entry.rod then
		for _, piece in entry.rod:GetDescendants() do
			if piece:IsA("BasePart") then
				piece.LocalTransparencyModifier = 0
			end
		end
		entry.rod = nil
	end
	if entry.model then
		entry.model:Destroy()
	end
	if entry.carry then
		entry.carry:Destroy()
	end
	for _, extra in { entry.tool, entry.bobber, entry.flight } do
		if extra then
			extra:Destroy()
		end
	end
	entry.tool, entry.bobber, entry.flight = nil, nil, nil
end

local function refreshLook(entry: Entry)
	local config = entry.config
	if type(config:GetAttribute("Look")) ~= "string" or type(config:GetAttribute("Colour")) ~= "string" then
		return
	end
	local scale = number(config, "Scale", 1)
	local previousScale = if entry.model then tonumber(string.match(entry.signature, "([%d%.]+)$")) else nil
	local attrs = {
		Colour = config:GetAttribute("Colour"),
		DualId = config:GetAttribute("DualId"),
		Material = config:GetAttribute("Material"),
		SecretId = config:GetAttribute("SecretId"),
		Ghost = config:GetAttribute("Ghost"),
		Scale = scale,
	}
	local signature = table.concat({
		stringAttr(config, "Look", ""),
		stringAttr(config, "Colour", ""),
		stringAttr(config, "Material", ""),
		stringAttr(config, "DualId", ""),
		stringAttr(config, "SecretId", ""),
		tostring(config:GetAttribute("Ghost") == true),
	}, "|") .. "|" .. tostring(scale)
	if entry.signature == signature then
		return
	end
	-- Do not rebuild a full face rig on every tiny baby-growth replication.
	if previousScale and math.abs(scale - previousScale) < C.ScaleRebuildThreshold then
		local prefix = string.match(entry.signature, "^(.*)|[%d%.]+$")
		local nextPrefix = string.match(signature, "^(.*)|[%d%.]+$")
		if prefix == nextPrefix then
			return
		end
	end
	local pos = if entry.actor then entry.actor.root else CFrame.new(at(config, "From"))
	if entry.actor then
		SlimeActor.destroy(entry.actor)
	end
	if entry.model then
		entry.model:Destroy()
	end
	local model = SlimeLook.build(attrs)
	model.Name = config.Name
	model:PivotTo(pos)
	model.Parent = renderFolder
	entry.model = model
	entry.actor = SlimeActor.new(model, stringAttr(config, "Emotion", "normal"))
	if entry.actor and entry.carry then
		SlimeActor.attach(entry.actor, entry.carry, CFrame.new())
	elseif not entry.actor then
		-- The emergency stand-in still occupies physical space for the local character.
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = true
			end
		end
	end
	entry.signature = signature
	entry.lastEmotion = ""
	entry.lastAction = ""
	entry.lastPhase = ""
	-- the new body holds its tool again on the next update
	if entry.tool then
		entry.tool:Destroy()
		entry.tool = nil
	end
	entry.toolName = ""
end

local function actionMotion(action: string, working: string): string?
	if action == "sleep" or action == "ghost" then
		return "sleep"
	elseif action == "eat" then
		return "eat"
	elseif action == "court" or action == "makeup" then
		return "love"
	elseif action == "chat" or action == "greet" then
		return "bounce"
	elseif action == "tag" or action == "splash" or action == "playBaby" then
		return "excited"
	elseif action == "work" then
		if working == "fishing" then
			return "idle"
		elseif working == "garden" then
			return "bounce"
		elseif working == "training" then
			return "excited"
		end
		return "swagger"
	elseif action == "carryBox" or action == "carryKitchen" or action == "carryDish" or action == "carryEgg" then
		return "proud"
	end
	return nil
end

-- Face the actual partner selected by the server, not whichever slime is nearest.
local function partnerPosition(village: Village, current: Entry): Vector3?
	local partnerId = stringAttr(current.config, "Partner", "")
	if partnerId == "" then
		return nil
	end
	for _, other in village.slimes do
		if other.config.Name == partnerId and other.actor then
			return other.actor.root.Position
		end
	end
	return nil
end

-- The pond's stage (PondStages names it "PondStage"; the other areas use "AreaStage").
local function pondStage(): Instance?
	local map = workspace:FindFirstChild("Map")
	local plot = if map then map:FindFirstChild("Plot" .. Config.Village.DevPlot) else nil
	local pond = if plot then plot:FindFirstChild("FishingPondL1") else nil
	return if pond then pond:FindFirstChild("PondStage") or pond:FindFirstChild("AreaStage") else nil
end

local function pondMarker(slot: number): BasePart?
	local stage = pondStage()
	local marker = if stage then stage:FindFirstChild("WorkSpot" .. math.floor(slot)) else nil
	return if marker and marker:IsA("BasePart") then marker else nil
end

-- The rod resting in the stand nearest a fishing place.
local function stageRod(slot: number): Model?
	local stage = pondStage()
	local marker = pondMarker(slot)
	if not stage or not marker then
		return nil
	end
	local nearest: Model? = nil
	local distance = math.huge
	for _, stand in stage:GetChildren() do
		if stand:IsA("Model") and stand.Name == "RodStand" then
			local d = (stand:GetPivot().Position - marker.Position).Magnitude
			if d < distance then
				distance, nearest = d, stand
			end
		end
	end
	local rod = if nearest then nearest:FindFirstChild("FishingRod") else nil
	return if rod and rod:IsA("Model") then rod else nil
end

local function setHidden(model: Instance, hidden: boolean)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function addWaterDrops(carried: Model)
	local spout = carried:FindFirstChildWhichIsA("BasePart", true)
	if not spout then
		return
	end
	local drop = Instance.new("Attachment")
	drop.Name = "WaterDrops"
	drop.Position = Vector3.new(0, -spout.Size.Y / 2, 0)
	drop.Parent = spout
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Watering"
	-- Built-in Roblox particle texture: no invented art or image upload needed.
	emitter.Texture = Config.Work.WorkWaterDropTexture
	local rgb = Config.Work.WorkWaterDropColour
	emitter.Color = ColorSequence.new(Color3.fromRGB(rgb[1], rgb[2], rgb[3]))
	emitter.Size = NumberSequence.new(Config.Work.WorkWaterDropSize)
	emitter.Lifetime = NumberRange.new(Config.Work.WorkWaterDropLifetime)
	emitter.Speed = NumberRange.new(Config.Work.WorkWaterDropSpeed)
	emitter.Acceleration = Vector3.new(0, -Config.Work.WorkWaterDropGravity, 0)
	emitter.Rate = Config.Work.WorkDropsPerWater
	emitter.Parent = drop
end

local function smoothstep(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

local function phaseFraction(config: Configuration, clock: number): number
	local start, finish = number(config, "WorkStart", 0), number(config, "WorkEnd", 0)
	return math.clamp((clock - start) / math.max(finish - start, 0.01), 0, 1)
end

-- Where a held tool's foot sits in the feet frame (front = -Z), from the work phase at this instant: the rod
-- swings back and out for the cast, points over the water while waiting and jerks up while reeling in;
-- the hoe chops.
local function toolPose(config: Configuration, tool: string, clock: number): CFrame
	local phase = stringAttr(config, "WorkPhase", "")
	local moving = clock >= number(config, "LegStart", 0) and clock < number(config, "LegEnd", 0)
	if tool == "Hoe" then
		local swing = C.HoeSwingDegrees * math.max(0, math.sin(clock * C.HoeSwingHz * math.pi * 2))
		return CFrame.new(C.RodGripUp * 0.6, C.RodGripUp * 0.6, -C.RodGripForward)
			* CFrame.Angles(-math.rad(20 + swing), 0, 0)
	end
	local tilt = C.RodWalkTilt
	local atPlace = not moving
		and stringAttr(config, "Working", "") == "fishing"
		and stringAttr(config, "Carry", "") == ""
	if atPlace and phase == "cast" then
		local t = phaseFraction(config, clock)
		if t < C.CastBackShare then
			tilt = C.RodFishTilt + (C.RodBackTilt - C.RodFishTilt) * smoothstep(t / C.CastBackShare)
		else
			local u = smoothstep((t - C.CastBackShare) / (1 - C.CastBackShare) * 3)
			tilt = C.RodBackTilt + (C.RodFishTilt - C.RodBackTilt) * u
		end
	elseif atPlace and phase == "wait" then
		tilt = C.RodFishTilt + 2 * math.sin(clock * 1.7)
	elseif atPlace and phase == "reel" then
		local t = phaseFraction(config, clock)
		tilt = C.RodFishTilt + (C.RodReelTilt - C.RodFishTilt) * t + 4 * math.sin(clock * 15)
	end
	return CFrame.new(0, C.RodGripUp, -C.RodGripForward) * CFrame.Angles(-math.rad(tilt), 0, 0)
end

local function clearLine(entry: Entry)
	if entry.bobber then
		entry.bobber:Destroy()
		entry.bobber = nil
	end
	entry.castKey = ""
end

local waterParams = RaycastParams.new()
waterParams.FilterType = Enum.RaycastFilterType.Exclude
waterParams.FilterDescendantsInstances = { renderFolder }

-- The line and the bobber: on the rod tip during the back swing, flying out in an arc, bobbing on the water,
-- dipping at the bite, then pulled back to the tip.
local function updateLine(entry: Entry, actor: SlimeActor.Slime?, water: Vector3?, phase: string, now: number)
	local rod = entry.tool
	local tip = if rod and entry.toolName == "FishingRod" then rod:FindFirstChild("Tip") else nil
	if not actor or not water or not tip or not tip:IsA("BasePart") then
		if entry.bobber then
			clearLine(entry)
		end
		return
	end
	local key = tostring(number(entry.config, "WorkSlot", 1))
	if entry.castKey ~= key then
		entry.castKey = key
		local hit = workspace:Raycast(water + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), waterParams)
		entry.castPoint = if hit then hit.Position else water
	end
	if not entry.bobber then
		local bobber = Instance.new("Model")
		bobber.Name = "Bobber"
		local source = asset("FishingRod")
		for _, name in { "BobberBottom", "BobberTop" } do
			local piece = source:FindFirstChild(name)
			if piece and piece:IsA("BasePart") then
				piece.Parent = bobber
			end
		end
		source:Destroy()
		local main = bobber:FindFirstChild("BobberBottom")
		if main and main:IsA("BasePart") then
			bobber.PrimaryPart = main
			local a0 = Instance.new("Attachment")
			a0.Name = "LineTip"
			a0.Parent = tip
			local a1 = Instance.new("Attachment")
			a1.Name = "LineEnd"
			a1.Parent = main
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Width0, beam.Width1 = C.LineWidth, C.LineWidth
			beam.Color = ColorSequence.new(Color3.fromHex(C.LineColour))
			beam.FaceCamera = true
			beam.Segments = 1
			beam.LightInfluence = 0
			beam.Parent = main
		end
		bobber:ScaleTo(actor.scale / C.BodyHeight * C.BobberScale)
		bobber.Parent = renderFolder
		entry.bobber = bobber
	end
	local castPoint = entry.castPoint or water
	local tipPoint = tip.Position
	local position = castPoint
	local t = phaseFraction(entry.config, now)
	if phase == "cast" then
		if t < C.CastBackShare then
			position = tipPoint - Vector3.new(0, 0.3, 0)
		else
			local u = (t - C.CastBackShare) / (1 - C.CastBackShare)
			position = tipPoint:Lerp(castPoint, u) + Vector3.new(0, Config.Village.TossArcStuds * 4 * u * (1 - u), 0)
		end
	elseif phase == "wait" then
		position = castPoint + Vector3.new(0, C.BobberBobStuds * math.sin(now * C.BobberBobHz * math.pi * 2), 0)
	elseif phase == "reel" then
		if t < C.BiteShare then
			position = castPoint - Vector3.new(0, C.BobberBiteDip * math.sin(math.pi * t / C.BiteShare), 0)
		else
			position =
				castPoint:Lerp(tipPoint - Vector3.new(0, 1, 0), smoothstep((t - C.BiteShare) / (1 - C.BiteShare)))
		end
	end
	(entry.bobber :: Model):PivotTo(CFrame.new(position))
end

local function animate(village: Village, entry: Entry, now: number)
	local actor = entry.actor
	local model = entry.model
	if not model then
		return
	end
	local from, to = at(entry.config, "From"), at(entry.config, "To")
	local start = number(entry.config, "LegStart", 0)
	local finish = number(entry.config, "LegEnd", 0)
	local moving = finish > start and now >= start and now < finish and (to - from).Magnitude > 0
	local gait = stringAttr(entry.config, "Gait", "walk")
	local fraction = VillagePath.progress(start, finish, now, gait)
	local pos = from:Lerp(to, fraction)
	local ghost = entry.config:GetAttribute("Ghost") == true
	local bearing = to - from
	local flat = Vector3.new(bearing.X, 0, bearing.Z)
	local drawFrom, drawTo = from, to
	if
		moving
		and stringAttr(entry.config, "Action", "") == "walkBaby"
		and number(entry.config, "Scale", 1) < 1
		and flat.Magnitude > C.FacingThreshold
	then
		-- Both endpoints move back equally, preserving the guardian's exact hop clock.
		drawFrom -= flat.Unit * C.BabyFollowStuds
		drawTo -= flat.Unit * C.BabyFollowStuds
		pos -= flat.Unit * C.BabyFollowStuds
	elseif
		not moving
		and stringAttr(entry.config, "Action", "") == "work"
		and stringAttr(entry.config, "Working", "") == "garden"
	then
		local shift = Vector3.new(math.sin(now * C.WorkShiftHz) * C.WorkShiftStuds, 0, 0)
		drawFrom += shift
		drawTo += shift
		pos += shift
	end
	if actor then
		SlimeActor.setTravel(actor, drawFrom, drawTo, start, finish, ghost, gait)
	else
		if ghost then
			pos += Vector3.new(0, C.GhostFloat + C.GhostFloat * math.sin(now * C.GhostFloatHz * math.pi * 2), 0)
		end
		local cf = if flat.Magnitude > C.FacingThreshold then CFrame.lookAt(pos, pos + flat) else CFrame.new(pos)
		model:PivotTo(cf)
	end
	local emotion = stringAttr(entry.config, "Emotion", "normal")
	local phase = stringAttr(entry.config, "WorkPhase", "")
	local action = stringAttr(entry.config, "Action", "idle")
	local face = if ghost
		then "sad"
		else if not moving and action == "eat"
			then "eating"
			else if not moving and action == "sleep" then "sleep" else emotion
	if actor then
		if entry.lastEmotion ~= face or entry.lastAction ~= action or entry.lastPhase ~= phase then
			SlimeActor.setEmotion(actor, face)
			local motion = if action == "work"
					and (
						phase == "cast"
						or phase == "wait"
						or phase == "reel"
						or phase == "hoe"
						or phase == "plant"
						or phase == "water"
						or phase == "harvest"
					)
				then "work" .. string.upper(string.sub(phase, 1, 1)) .. string.sub(phase, 2)
				else actionMotion(action, stringAttr(entry.config, "Working", ""))
			if motion then
				SlimeActor.playMotion(actor, motion)
			end
			entry.lastEmotion, entry.lastAction, entry.lastPhase = face, action, phase
		end
	end
	local hand = stringAttr(entry.config, "Hand", "")
	local handStart = number(entry.config, "HandStart", 0)
	local handEnd = number(entry.config, "HandEnd", 0)
	local inHand = hand ~= "" and now >= handStart and now < handEnd
	local facePoint = if entry.config:GetAttribute("Face") == true then at(entry.config, "Face") else nil
	local fishing = action == "work"
		and not moving
		and stringAttr(entry.config, "Working", "") == "fishing"
		and stringAttr(entry.config, "Carry", "") == ""
		and (phase == "cast" or phase == "wait" or phase == "reel")
	local water: Vector3? = nil
	if fishing or (inHand and hand == "catch") then
		local marker = pondMarker(number(entry.config, "WorkSlot", 1))
		if marker then
			-- The dock runs toward its far end, opposite the marker's LookVector: the water is that way.
			water = marker.Position - marker.CFrame.LookVector * C.CastStuds
		end
	end
	if actor then
		-- (a catch looks at the water it comes out of; a take, toss or rod hand looks at the bin or the stand)
		local bodyFace = if inHand and facePoint and hand ~= "catch" then facePoint else (water or facePoint)
		SlimeActor.face(actor, if moving then nil else bodyFace)
		if moving then
			SlimeActor.lookAt(actor, to)
		elseif inHand and facePoint then
			SlimeActor.lookAt(actor, facePoint)
		elseif action == "player" then
			local player = Players.LocalPlayer
			local character = player.Character
			SlimeActor.lookAt(actor, if character then character:FindFirstChild("Head") else nil)
		elseif
			action == "chat"
			or action == "greet"
			or action == "argue"
			or action == "makeup"
			or action == "court"
		then
			SlimeActor.lookAt(actor, partnerPosition(village, entry))
		elseif entry.bobber and entry.bobber.Parent then
			SlimeActor.lookAt(actor, entry.bobber:GetPivot().Position)
		else
			SlimeActor.lookAt(actor, bodyFace)
		end
	end

	-- What sits on the head: a carried item, unless it is still flying up from the bin or the line.
	local carryName = stringAttr(entry.config, "Carry", "")
	if inHand and (hand == "take" or hand == "catch") then
		carryName = ""
	end
	local overHead = if action == "work"
			and not moving
			and carryName == ""
			and phase == "water"
		then "WateringCan"
		else ""
	local shown = if carryName ~= "" then carryName else overHead
	if shown ~= entry.carryName then
		if actor then
			SlimeActor.detach(actor)
		end
		if entry.carry then
			entry.carry:Destroy()
		end
		entry.carryName = shown
		entry.carry = nil
		if shown ~= "" then
			local carried = asset(shown)
			carried:ScaleTo(if overHead ~= "" then C.CanScale else C.CarryScale)
			carried.Parent = renderFolder
			if overHead == "WateringCan" then
				addWaterDrops(carried)
			end
			entry.carry = carried
			if actor then
				local offset = if overHead == "WateringCan"
					then CFrame.new(0, Config.Work.WorkToolOffset, 0) * CFrame.Angles(
						0,
						0,
						math.rad(Config.Work.WorkWaterTiltDegrees)
					)
					else CFrame.new()
				SlimeActor.attach(actor, carried, offset)
			end
		end
	end
	if entry.carry and not actor then
		entry.carry:PivotTo(CFrame.new(pos) * CFrame.new(0, C.BodyHeight * C.CarryHeight, 0))
	end

	-- The tool in front of the body: the rod from taking it off the stand until it is back on it, the hoe
	-- while hoeing.
	local rodSlot = math.floor(number(entry.config, "Rod", 0))
	if rodSlot > 0 then
		entry.rodSlot = rodSlot
	end
	local half = (handStart + handEnd) / 2
	local putting = hand == "rodPut" and now < half and now >= handStart
	local holdingRod = (rodSlot > 0 and not (hand == "rodTake" and now < half)) or putting

	local tool = if holdingRod
		then "FishingRod"
		else (if action == "work" and not moving and phase == "hoe" then "Hoe" else "")
	if tool ~= entry.toolName then
		entry.toolName = tool
		if actor then
			SlimeActor.unhold(actor)
		end
		if entry.tool then
			entry.tool:Destroy()
			entry.tool = nil
		end
		clearLine(entry)
		if tool ~= "" and actor then
			local toolModel = asset(tool)
			local scale = actor.scale
			if tool == "FishingRod" then
				-- The kit rod hangs its own short line; the held rod casts a real one.
				for _, name in { "Line", "BobberTop", "BobberBottom" } do
					local piece = toolModel:FindFirstChild(name)
					if piece then
						piece:Destroy()
					end
				end
				toolModel:ScaleTo(C.RodScale * scale / C.BodyHeight)
			else
				toolModel:ScaleTo(C.HoeScale * scale / C.BodyHeight)
			end
			toolModel.Parent = renderFolder
			entry.tool = toolModel
			local config = entry.config
			SlimeActor.hold(actor, toolModel, function(clock: number): CFrame
				return toolPose(config, tool, clock)
			end)
		end
	end
	updateLine(entry, actor, if fishing then water else nil, phase, now)

	-- The item in flight between the slime and the bin (or the bobber), drawn only during the hand event.
	local flying = inHand and (hand == "take" or hand == "toss" or hand == "catch")
	local key = if flying then hand .. "|" .. tostring(handStart) else ""
	if key ~= entry.flightKey then
		entry.flightKey = key
		if entry.flight then
			entry.flight:Destroy()
			entry.flight = nil
		end
		local item = stringAttr(entry.config, "HandItem", "")
		if flying and item ~= "" then
			local flyer = asset(item)
			flyer:ScaleTo(C.CarryScale)
			flyer.Parent = renderFolder
			entry.flight = flyer
			if actor then
				-- A toss leans into the throw; a take reaches and pulls back.
				SlimeActor.kick(actor, "lean", if hand == "toss" then C.TossLeanKick else -C.TossLeanKick)
				SlimeActor.kick(actor, "squash", C.TossSquashKick)
			end
		end
	end
	local flight = entry.flight
	if flight and actor then
		local head = actor.root.Position + Vector3.new(0, actor.body.Size.Y + C.CarryTopOffset, 0)
		local bin = if facePoint
			then facePoint + Vector3.new(0, C.HandBinHeight, 0)
			else head + actor.root.LookVector * C.CastStuds * 0.3
		local source = if hand == "catch" then (entry.castPoint or bin) else bin
		local a, b = if hand == "toss" then head else source, if hand == "toss" then source else head
		local t = math.clamp((now - handStart) / math.max(handEnd - handStart, 0.01), 0, 1)
		local arc = Config.Village.TossArcStuds * 4 * t * (1 - t)
		flight:PivotTo(CFrame.new(a:Lerp(b, t) + Vector3.new(0, arc, 0)) * CFrame.Angles(0, t * math.pi * 2, 0))
	end

	-- The place's own rod disappears from its stand while a slime holds it (this client only).
	local standRod: Model? = nil
	if holdingRod and entry.rodSlot > 0 then
		standRod = stageRod(entry.rodSlot)
	end
	if entry.rod ~= standRod then
		if entry.rod then
			setHidden(entry.rod, false)
		end
		entry.rod = standRod
		if standRod then
			setHidden(standRod, true)
		end
	end
end

local function eggPosition(village: Village, egg: Configuration): Vector3
	local plotNumber = number(village.root, "Plot", 0)
	if plotNumber < 1 then
		plotNumber = Config.Village.DevPlot
	end
	local map = workspace:FindFirstChild("Map")
	local plot = if map then map:FindFirstChild("Plot" .. plotNumber) else nil
	local breeding: Instance? = nil
	if plot then
		for _, child in plot:GetChildren() do
			if string.match(child.Name, "^BreedingL") then
				breeding = child
				break
			end
		end
	end
	local slot = math.floor(number(egg, "Slot", 1))
	local prefix = if stringAttr(egg, "Place", "nest") == "incubator" then "Incubator" else "Nest"
	local mark = if breeding then breeding:FindFirstChild(prefix .. tostring(slot), true) else nil
	if mark and mark:IsA("Attachment") then
		return mark.WorldPosition
	elseif mark and mark:IsA("BasePart") then
		return mark.Position
	elseif mark and mark:IsA("Model") then
		return mark:GetPivot().Position
	end
	local centre = Layout.plotAreaFacing(plotNumber, 1, 0).Position + Vector3.new(0, Config.Map.GroundY, 0)
	return centre
		+ Vector3.new(slot * C.EggSlotSpacing, 0, if prefix == "Nest" then -C.EggSlotSpacing else C.EggSlotSpacing)
end

local function addSlime(village: Village, child: Instance)
	if not child:IsA("Configuration") or village.slimes[child] then
		return
	end
	local entry: Entry = {
		config = child,
		model = nil,
		actor = nil,
		connections = {},
		signature = "",
		lastUpdate = 0,
		lastAction = "",
		lastEmotion = "",
		lastPhase = "",
		carryName = "",
		carry = nil,
		rod = nil,
		rodSlot = 0,
		tool = nil,
		toolName = "",
		bobber = nil,
		castKey = "",
		castPoint = nil,
		flight = nil,
		flightKey = "",
	}
	village.slimes[child] = entry
	for _, name in { "Look", "Colour", "Material", "DualId", "SecretId", "Ghost", "Scale" } do
		table.insert(
			entry.connections,
			child:GetAttributeChangedSignal(name):Connect(function()
				refreshLook(entry)
			end)
		)
	end
	refreshLook(entry)
end

local function removeSlime(village: Village, child: Instance)
	local entry = village.slimes[child]
	if entry then
		clearEntry(entry)
		village.slimes[child] = nil
	end
end

local function addEgg(village: Village, child: Instance)
	if child:IsA("Configuration") and not village.eggs[child] then
		local model = asset("Egg")
		model.Name = child.Name
		model.Parent = renderFolder
		village.eggs[child] = model
	end
end

local function removeEgg(village: Village, child: Instance)
	local model = village.eggs[child]
	if model then
		model:Destroy()
		village.eggs[child] = nil
	end
end

local function bindVillage(root: Instance)
	if not root:IsA("Folder") or villages[root] then
		return
	end
	local village: Village = { root = root, slimes = {}, eggs = {}, connections = {} }
	villages[root] = village
	local function bindFolder(name: string)
		local folder = root:FindFirstChild(name)
		if not folder or not folder:IsA("Folder") then
			return
		end
		local added: (any, Instance) -> () = if name == "Slimes" then addSlime :: any else addEgg :: any
		local removed: (any, Instance) -> () = if name == "Slimes" then removeSlime :: any else removeEgg :: any
		for _, child in folder:GetChildren() do
			added(village, child)
		end
		table.insert(
			village.connections,
			folder.ChildAdded:Connect(function(child)
				added(village, child)
			end)
		)
		table.insert(
			village.connections,
			folder.ChildRemoved:Connect(function(child)
				removed(village, child)
			end)
		)
	end
	bindFolder("Slimes")
	bindFolder("Eggs")
	table.insert(
		village.connections,
		root.ChildAdded:Connect(function(child)
			if child.Name == "Slimes" or child.Name == "Eggs" then
				bindFolder(child.Name)
			end
		end)
	)
end

local function unbindVillage(root: Instance)
	local village = villages[root :: Folder]
	if not village then
		return
	end
	for _, connection in village.connections do
		connection:Disconnect()
	end
	for child in village.slimes do
		removeSlime(village, child)
	end
	for child in village.eggs do
		removeEgg(village, child)
	end
	villages[root :: Folder] = nil
end

local folder = workspace:WaitForChild("Villages") :: Folder
for _, root in folder:GetChildren() do
	bindVillage(root)
end
folder.ChildAdded:Connect(bindVillage)
folder.ChildRemoved:Connect(unbindVillage)

-- One inexpensive timer for the entire village; SlimeActor owns the only render-step loop.
task.spawn(function()
	while folder.Parent do
		local now = workspace:GetServerTimeNow()
		local camera = workspace.CurrentCamera
		for _, village in villages do
			for _, entry in village.slimes do
				local origin = if entry.actor then entry.actor.root.Position else at(entry.config, "From")
				local distance = if camera then (camera.CFrame.Position - origin).Magnitude else 0
				if distance < C.MaxDrawDistance then
					local interval = if distance <= C.NearWorkDistance then C.UpdateSeconds else C.FarUpdateSeconds
					if now - entry.lastUpdate >= interval then
						entry.lastUpdate = now
						animate(village, entry, now)
					end
				end
			end
			for egg, model in village.eggs do
				if egg:GetAttribute("Held") == true then
					model.Parent = nil
					continue
				elseif model.Parent ~= renderFolder then
					model.Parent = renderFolder
				end
				local position = eggPosition(village, egg :: Configuration)
				if not camera or (camera.CFrame.Position - position).Magnitude <= C.MaxDrawDistance then
					local hatchAt = number(egg, "HatchAt", 0)
					local remaining = hatchAt - now
					local wobble = if remaining > 0 and remaining <= C.EggWobbleWindow
						then math.rad(C.EggWobbleDegrees) * math.sin(now * C.EggWobbleHz * math.pi * 2)
						else 0
					model:PivotTo(CFrame.new(position) * CFrame.Angles(0, 0, wobble))
				end
			end
		end
		task.wait(C.UpdateSeconds)
	end
end)
