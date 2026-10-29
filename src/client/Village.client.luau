--!strict
-- Client-side village inhabitants. The server owns every action and leg clock; this script only draws them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local SlimeActor = require(script.Parent.SlimeActor)
local SlimeLook = require(script.Parent.SlimeLook)

local C = Config.VillageClient
type Entry = {
	config: Configuration,
	model: Model?,
	actor: SlimeActor.Slime?,
	connections: { RBXScriptConnection },
	signature: string,
	lastUpdate: number,
	lastHop: number,
	carryName: string,
	carry: Model?,
	lastAction: string,
	lastEmotion: string,
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
	local original = if name == "Egg" then (if kit then kit:FindFirstChild("Egg") else nil)
		else (if items then items:FindFirstChild(name) else nil)
	local model = Instance.new("Model")
	model.Name = name
	if original and original:IsA("Model") then
		for _, child in original:GetChildren() do
			child:Clone().Parent = model
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
	if entry.model then
		entry.model:Destroy()
	end
	if entry.carry then
		entry.carry:Destroy()
	end
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
	entry.signature = signature
	entry.lastEmotion = ""
	entry.lastAction = ""
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

local function nearestPartner(village: Village, current: Entry): Model?
	local here = if current.actor then current.actor.root.Position else at(current.config, "From")
	local nearest: Model? = nil
	local best = Config.Brain.NearbyStuds
	for _, other in village.slimes do
		if other ~= current and other.actor and other.model then
			local distance = (other.actor.root.Position - here).Magnitude
			if distance < best then
				best = distance
				nearest = other.model
			end
		end
	end
	return nearest
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
	local moving = finish > start and now < finish and (to - from).Magnitude > 0
	local fraction = if finish > start then math.clamp((now - start) / (finish - start), 0, 1) else 1
	local pos = from:Lerp(to, fraction)
	local ghost = entry.config:GetAttribute("Ghost") == true
	if ghost then
		pos += Vector3.new(0, C.GhostFloat + C.GhostFloat * math.sin(now * C.GhostFloatHz * math.pi * 2), 0)
	end
	local bearing = to - from
	local cf = if bearing.Magnitude > 0.01 then CFrame.lookAt(pos, pos + Vector3.new(bearing.X, 0, bearing.Z))
		else CFrame.new(pos)
	if actor then
		SlimeActor.setCFrame(actor, cf)
	else
		model:PivotTo(cf)
	end
	local emotion = stringAttr(entry.config, "Emotion", "normal")
	local action = stringAttr(entry.config, "Action", "idle")
	if actor then
		if entry.lastEmotion ~= emotion or entry.lastAction ~= action then
			SlimeActor.setEmotion(actor, if ghost then "sad" else emotion)
			local motion = actionMotion(action, stringAttr(entry.config, "Working", ""))
			if motion then
				SlimeActor.playMotion(actor, motion)
			end
			entry.lastEmotion, entry.lastAction = emotion, action
		end
		if moving then
			if now - entry.lastHop >= Config.Brain.HopSeconds then
				SlimeActor.hop(actor, C.HopHeight)
				entry.lastHop = now
			end
			SlimeActor.lookAt(actor, to)
		elseif action == "player" then
			local player = Players.LocalPlayer
			local character = player.Character
			SlimeActor.lookAt(actor, if character then character:FindFirstChild("Head") else nil)
		elseif action == "chat" or action == "greet" or action == "argue" or action == "makeup" or action == "court" then
			SlimeActor.lookAt(actor, nearestPartner(village, entry))
		elseif action == "work" and stringAttr(entry.config, "Working", "") == "fishing" then
			SlimeActor.lookAt(actor, to + (to - from))
		else
			SlimeActor.lookAt(actor, nil)
		end
	end

	local carryName = stringAttr(entry.config, "Carry", "")
	if entry.lastAction == "carryEgg" then
		carryName = "Egg"
	end
	if carryName ~= entry.carryName then
		if entry.carry then
			entry.carry:Destroy()
		end
		entry.carryName = carryName
		entry.carry = nil
		if carryName ~= "" then
			entry.carry = asset(carryName)
			entry.carry:ScaleTo(C.CarryScale)
			entry.carry.Parent = renderFolder
		end
	end
	if entry.carry then
		entry.carry:PivotTo(cf * CFrame.new(0, C.BodyHeight * C.CarryHeight, 0))
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
	return centre + Vector3.new(slot * C.EggSlotSpacing, 0, if prefix == "Nest" then -C.EggSlotSpacing else C.EggSlotSpacing)
end

local function addSlime(village: Village, child: Instance)
	if not child:IsA("Configuration") or village.slimes[child] then
		return
	end
	local entry: Entry = {
		config = child, model = nil, actor = nil, connections = {}, signature = "",
		lastUpdate = 0, lastHop = 0, lastAction = "", lastEmotion = "", carryName = "", carry = nil,
	}
	village.slimes[child] = entry
	for _, name in { "Look", "Colour", "Material", "DualId", "SecretId", "Ghost", "Scale" } do
		table.insert(entry.connections, child:GetAttributeChangedSignal(name):Connect(function()
			refreshLook(entry)
		end))
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
		local added = if name == "Slimes" then addSlime else addEgg
		local removed = if name == "Slimes" then removeSlime else removeEgg
		for _, child in folder:GetChildren() do
			added(village, child)
		end
		table.insert(village.connections, folder.ChildAdded:Connect(function(child)
			added(village, child)
		end))
		table.insert(village.connections, folder.ChildRemoved:Connect(function(child)
			removed(village, child)
		end))
	end
	bindFolder("Slimes")
	bindFolder("Eggs")
	table.insert(village.connections, root.ChildAdded:Connect(function(child)
		if child.Name == "Slimes" or child.Name == "Eggs" then
			bindFolder(child.Name)
		end
	end))
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
				refreshLook(entry)
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
