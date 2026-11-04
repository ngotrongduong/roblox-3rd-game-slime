--!strict
-- The home plots of a server (the owner, 2026-11-02: up to 8 players, each in a plot of their own; docs/MAP.md section 3).
--   * hand-out: a player who joins gets the first free plot (PlotSlots), spawns in it, and frees it by leaving;
--   * the world: workspace.Map.Plot<Config.Plots.TemplatePlot> is the hand-built village. At server start it moves to
--     ServerStorage[Config.Plots.TemplateName] and every plot is left empty (a plain stud lawn over the sunken ground, one
--     part); a joining player's plot gets a copy of the village turned about the valley centre to that plot
--     (Layout.plotTurn), copied in steps so the server does not stall; a leaving player's plot is cleared the same way.
-- The terrain under every plot is prepared once in the work place (tools/map/prepare_plots.luau); nothing here touches it.
-- Published: Player attribute "Plot" (number) from the moment of the hand-out; Map.Plot<n> (the container, attribute Plot).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local PlotSlots = require(ReplicatedStorage.Shared.PlotSlots)

type PlotState = {
	plot: number,
	container: Model,
	spawn: SpawnLocation,
	lawn: Part?,
	owner: Player?,
	-- changes with every owner, so work for a player who left stops
	epoch: number,
	-- a copy or a clearing is running / the container holds (part of) a village and has not been cleared yet
	busy: boolean,
	dirty: boolean,
	built: boolean,
	ready: boolean,
}
type BuiltCallback = (player: Player, plot: number, model: Model) -> ()
type FreedCallback = (player: Player, plot: number) -> ()

local Plots = {}
local owners: { [number]: number } = {}
local states: { [number]: PlotState } = {}
local plotOf: { [Player]: number } = {}
local builtCallbacks: { BuiltCallback } = {}
local freedCallbacks: { FreedCallback } = {}
local template: Instance? = nil
local lawns: Folder? = nil
local started = false
local lastYield = os.clock()

-- Gives the frame back to the server after StepSeconds of work.
local function step()
	if os.clock() - lastYield >= Config.Plots.StepSeconds then
		task.wait()
		lastYield = os.clock()
	end
end

local function countParts(root: Instance): (number, number)
	local parts = 0
	local all = root:GetDescendants()
	for _, d in all do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	return #all, parts
end

-- ===== Copying a village =====

-- The Vector3 attributes that are world positions (the pond fish's loops) turn with the copy.
local function turnAttributes(root: Instance, turn: CFrame)
	local turned: { [string]: { string } } = Config.Plots.Turned
	local function one(inst: Instance)
		for tag, names in turned do
			if CollectionService:HasTag(inst, tag) then
				for _, name in names do
					local value = inst:GetAttribute(name)
					if typeof(value) == "Vector3" then
						inst:SetAttribute(name, turn * value)
					end
				end
			end
		end
	end
	one(root)
	for _, d in root:GetDescendants() do
		if d:IsA("Model") then
			one(d)
		end
	end
end

local function turnInstance(inst: Instance, turn: CFrame)
	if inst:IsA("BasePart") then
		inst.CFrame = turn * inst.CFrame
	elseif inst:IsA("Model") then
		inst:PivotTo(turn * inst:GetPivot())
		turnAttributes(inst, turn)
	elseif inst:IsA("Folder") then
		for _, child in inst:GetChildren() do
			turnInstance(child, turn)
		end
	end
end

local function marks(from: Instance, to: Instance)
	for name, value in from:GetAttributes() do
		to:SetAttribute(name, value)
	end
	for _, tag in from:GetTags() do
		to:AddTag(tag)
	end
end

-- The child numbers that lead from root down to target (nil when target is not inside root).
local function indexPath(root: Instance, target: Instance): { number }?
	local path: { number } = {}
	local at: Instance? = target
	while at and at ~= root do
		local parent = at.Parent
		if not parent then
			return nil
		end
		table.insert(path, 1, table.find(parent:GetChildren(), at) or 0)
		at = parent
	end
	return if at == root then path else nil
end

local function follow(root: Instance, path: { number }): Instance?
	local at: Instance? = root
	for _, index in path do
		at = if at then at:GetChildren()[index] else nil
	end
	return at
end

-- Copies `src` into `parent`, turned by `turn` (nil: not turned). A folder or model with more than ChunkParts parts under
-- it is rebuilt empty and its children copied one by one, so no single call is long. Returns false when `alive` said stop.
local function copyUnit(src: Instance, parent: Instance, turn: CFrame?, alive: () -> boolean): boolean
	if not alive() then
		return false
	end
	local container = src:IsA("Folder") or src:IsA("Model")
	if not container or #src:GetDescendants() <= Config.Plots.ChunkParts then
		local clone = src:Clone()
		if clone then
			if turn then
				turnInstance(clone, turn)
			end
			clone.Parent = parent
		end
		step()
		return true
	end
	local shell = Instance.new(src.ClassName)
	shell.Name = src.Name
	marks(src, shell)
	if src:IsA("Model") and shell:IsA("Model") then
		shell.WorldPivot = (turn or CFrame.new()) * src:GetPivot()
		shell.ModelStreamingMode = src.ModelStreamingMode
	end
	shell.Parent = parent
	for _, child in src:GetChildren() do
		if not copyUnit(child, shell, turn, alive) then
			return false
		end
	end
	if src:IsA("Model") and shell:IsA("Model") and src.PrimaryPart then
		local path = indexPath(src, src.PrimaryPart)
		local found = if path then follow(shell, path) else nil
		if found and found:IsA("BasePart") then
			shell.PrimaryPart = found
		end
	end
	return true
end

-- Destroys what a plot holds, big containers child by child.
local function destroyUnit(inst: Instance)
	if (inst:IsA("Folder") or inst:IsA("Model")) and #inst:GetDescendants() > Config.Plots.ChunkParts then
		for _, child in inst:GetChildren() do
			destroyUnit(child)
		end
	end
	inst:Destroy()
	step()
end

-- ===== The lawn of an empty plot =====

local function placeLawn(state: PlotState)
	if state.lawn and state.lawn.Parent then
		return
	end
	local size = Config.Map.PlotSize
	local lawn = Instance.new("Part")
	lawn.Name = "Lawn" .. state.plot
	lawn.Size = Vector3.new(size, Config.Plots.EmptyThickness, size)
	-- (its top just under the village floor's top, so a village built on it never flickers with it)
	lawn.CFrame = Layout.plotFrame(state.plot)
		* CFrame.new(0, Config.Map.GroundY - Config.Plots.EmptyDrop - Config.Plots.EmptyThickness / 2, 0)
	lawn.Color = Color3.fromHex(Config.Plots.EmptyColour)
	lawn.Material = Enum.Material.Plastic
	lawn.TopSurface = Enum.SurfaceType.Studs
	lawn.BottomSurface = Enum.SurfaceType.Smooth
	lawn.Anchored = true
	lawn.CastShadow = false
	lawn.Parent = lawns
	state.lawn = lawn
end

local function removeLawn(state: PlotState)
	if state.lawn then
		state.lawn:Destroy()
		state.lawn = nil
	end
end

-- ===== One plot's life =====

local function fireBuilt(player: Player, plot: number, model: Model)
	for _, callback in builtCallbacks do
		task.spawn(function()
			local ok, err = pcall(function(): any
				callback(player, plot, model)
				return nil
			end)
			if not ok then
				warn(Config.LogPrefix, "plots: built callback failed:", err)
			end
		end)
	end
end

local function build(state: PlotState, player: Player, epoch: number)
	local function alive(): boolean
		return state.epoch == epoch and state.owner == player and player.Parent == Players
	end
	while (state.busy or state.dirty) and alive() do
		task.wait(Config.Plots.WaitSeconds)
	end
	if not alive() then
		return
	end
	state.busy = true
	state.dirty = true
	local began = os.clock()
	local source = template
	local turn: CFrame? = nil
	if source and state.plot ~= Config.Plots.TemplatePlot then
		turn = Layout.plotTurn(state.plot, Config.Plots.TemplatePlot)
	end
	local done = true
	-- (an error in the copy must still free the plot: a busy flag left on held every later build and clear of it forever)
	local copied, err = pcall(function()
		if source then
			for _, child in source:GetChildren() do
				if not copyUnit(child, state.container, turn, alive) then
					done = false
					break
				end
			end
		end
	end)
	state.busy = false
	if not copied then
		warn(Config.LogPrefix, "plots: the copy for plot", state.plot, "failed:", err)
		return
	end
	if not done or not alive() then
		print(Config.LogPrefix, "plots: the copy for plot", state.plot, "stopped, its player left")
		return
	end
	removeLawn(state)
	local instances, parts = countParts(state.container)
	state.built = true
	print(
		Config.LogPrefix,
		string.format(
			"plots: plot %d built for %s in %.2f s: %d instances, %d parts%s",
			state.plot,
			player.Name,
			os.clock() - began,
			instances,
			parts,
			if source then "" else " (no village template)"
		)
	)
	fireBuilt(player, state.plot, state.container)
end

local function clear(state: PlotState)
	while state.busy do
		task.wait(Config.Plots.WaitSeconds)
	end
	if not state.dirty then
		return
	end
	state.busy = true
	local began = os.clock()
	placeLawn(state)
	for _, child in state.container:GetChildren() do
		destroyUnit(child)
	end
	state.dirty = false
	state.busy = false
	print(Config.LogPrefix, string.format("plots: plot %d cleared in %.2f s", state.plot, os.clock() - began))
end

local function onPlayerAdded(player: Player)
	if plotOf[player] then
		return
	end
	local plot = PlotSlots.assign(owners, player.UserId)
	if not plot then
		print(Config.LogPrefix, "plots: no free plot for", player.Name)
		player:Kick(Config.Plots.FullMessage)
		return
	end
	local state = states[plot]
	plotOf[player] = plot
	state.owner = player
	state.epoch += 1
	state.built = false
	state.ready = false
	player:SetAttribute("Plot", plot)
	-- (the character has not spawned yet: this handler runs before it loads)
	player.RespawnLocation = state.spawn
	print(Config.LogPrefix, "plots:", player.Name, "gets plot", plot)
	task.spawn(build, state, player, state.epoch)
end

local function onPlayerRemoving(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	plotOf[player] = nil
	PlotSlots.release(owners, player.UserId)
	local state = states[plot]
	if state.owner == player then
		state.owner = nil
		state.epoch += 1
		state.built = false
		state.ready = false
	end
	for _, callback in freedCallbacks do
		local ok, err = pcall(function(): any
			callback(player, plot)
			return nil
		end)
		if not ok then
			warn(Config.LogPrefix, "plots: freed callback failed:", err)
		end
	end
	print(Config.LogPrefix, "plots:", player.Name, "left plot", plot)
	task.spawn(clear, state)
end

-- ===== Reading =====

-- The plot a player holds, nil when none (not yet handed out, or the server was full).
function Plots.of(player: Player): number?
	return plotOf[player]
end

function Plots.ownerOf(plot: number): Player?
	local state = states[plot]
	return if state then state.owner else nil
end

-- The container of a plot's village: workspace.Map.Plot<n>. Empty while nobody holds the plot.
function Plots.model(plot: number): Model?
	local state = states[plot]
	return if state then state.container else nil
end

-- Called (in its own thread) when a player's plot holds a complete copy of the village.
function Plots.onBuilt(callback: BuiltCallback)
	table.insert(builtCallbacks, callback)
end

-- Called when a player leaves, before their plot is cleared: whatever was set up for the plot stops here.
function Plots.onFreed(callback: FreedCallback)
	table.insert(freedCallbacks, callback)
end

-- PlayerAdded handlers run in no set order: a farm can finish loading before this player has been handed a plot.
local function waitPlot(player: Player): number?
	while not plotOf[player] and player.Parent == Players do
		task.wait(Config.Plots.WaitSeconds)
	end
	return plotOf[player]
end

-- The player's village is complete and set to their saved levels (AreaUpgrade says so).
function Plots.setReady(player: Player)
	local plot = plotOf[player]
	local state = if plot then states[plot] else nil
	if state and state.owner == player and state.built then
		state.ready = true
	end
end

-- Yields until the village is ready; the plot's container, nil when the player left or has no plot.
function Plots.waitReady(player: Player): Model?
	local plot = waitPlot(player)
	local state = if plot then states[plot] else nil
	if not state then
		return nil
	end
	local epoch = state.epoch
	while state.epoch == epoch and not state.ready and player.Parent == Players do
		task.wait(Config.Plots.WaitSeconds)
	end
	return if state.epoch == epoch and state.ready then state.container else nil
end

-- ===== Start =====

local function spawnFor(plot: number, folder: Folder): SpawnLocation
	local frame = Layout.plotFrame(plot) * CFrame.new(0, 0, -Config.Plots.SpawnAhead)
	local at = Vector3.new(frame.Position.X, Config.Map.GroundY + Config.Plots.SpawnLift, frame.Position.Z)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn" .. plot
	spawn.Size = Vector3.new(4, 0.2, 4)
	-- facing the plaza, the middle of the plot
	spawn.CFrame =
		CFrame.lookAt(at, Vector3.new(Layout.plotFrame(plot).Position.X, at.Y, Layout.plotFrame(plot).Position.Z))
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Duration = 0
	spawn.Neutral = true
	for _, d in spawn:GetChildren() do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	spawn.Parent = folder
	return spawn
end

-- Map.Plot<n> as an empty Model.
local function emptyContainer(map: Instance, plot: number): Model
	local found = map:FindFirstChild("Plot" .. plot)
	if found and found:IsA("Model") then
		found:ClearAllChildren()
		found:SetAttribute("Plot", plot)
		return found
	end
	if found then
		found:Destroy()
	end
	local made = Instance.new("Model")
	made.Name = "Plot" .. plot
	made:SetAttribute("Plot", plot)
	made.Parent = map
	return made
end

-- Called once by Main, before profiles can load.
function Plots.start()
	assert(not started, "Plots.start called twice")
	started = true
	local map = workspace:FindFirstChild("Map")
	if not map then
		map = Instance.new("Folder")
		map.Name = "Map"
		map.Parent = workspace
	end
	-- the hand-built village leaves the world and becomes the template
	local hand = map:FindFirstChild("Plot" .. Config.Plots.TemplatePlot)
	if hand then
		hand.Name = Config.Plots.TemplateName
		hand.Parent = ServerStorage
		template = hand
	else
		template = ServerStorage:FindFirstChild(Config.Plots.TemplateName)
	end
	if template then
		local instances, parts = countParts(template)
		print(Config.LogPrefix, "plots: village template ready,", instances, "instances,", parts, "parts")
	else
		warn(Config.LogPrefix, "plots: no village template (workspace.Map.Plot" .. Config.Plots.TemplatePlot .. ")")
	end
	-- the spawns of the work place's earlier single-plot days must not catch anyone
	local old = workspace:FindFirstChild("DevSpawn")
	if old and old:IsA("SpawnLocation") then
		old.Enabled = false
	end
	local lawnFolder = Instance.new("Folder")
	lawnFolder.Name = "EmptyLawns"
	lawnFolder.Parent = map
	lawns = lawnFolder
	local spawnFolder = Instance.new("Folder")
	spawnFolder.Name = "PlotSpawns"
	spawnFolder.Parent = map
	for plot = 1, Config.Map.PlotCount do
		-- every plot starts empty (a greybox left in one goes too)
		local container = emptyContainer(map, plot)
		local state: PlotState = {
			plot = plot,
			container = container,
			spawn = spawnFor(plot, spawnFolder),
			lawn = nil,
			owner = nil,
			epoch = 0,
			busy = false,
			dirty = false,
			built = false,
			ready = false,
		}
		states[plot] = state
		placeLawn(state)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return Plots
