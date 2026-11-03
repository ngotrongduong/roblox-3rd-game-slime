-- Builds the one place that may go to players (assets/raw/Publish.rbxl): the world saved in the work place
-- (assets/raw/MapWork.rbxlx) with the code of the Rojo build (GooLineage.rbxlx), without the work place's test stages and
-- labs, with streaming on. The Rojo build alone has no world; the work place alone has labs and whatever code it last got.
-- Studio scripts cannot set most streaming properties, so they are set here. Fails loudly if anything needed is missing.
-- Run tools/check.ps1 first (it writes GooLineage.rbxlx), then:
--   lune run tools/build_publish.luau
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Enum = roblox.Enum
local Config = require("../src/shared/Config")

local WORLD = "assets/raw/MapWork.rbxlx"
local CODE = "GooLineage.rbxlx"
local OUT = "assets/raw/Publish.rbxl"

-- All that stays of the work place's Workspace. (Map holds the village template Plots.start needs; the rest are stages.)
local KEEP_IN_WORKSPACE = { Camera = true, Terrain = true, Map = true }
local DROP_FROM_SERVER_STORAGE = { "AssetTest" }

local problems: { string } = {}
local function problem(text: string)
	table.insert(problems, text)
end

local place = roblox.deserializePlace(fs.readFile(WORLD))
local code = roblox.deserializePlace(fs.readFile(CODE))

local function replaceCode(service: string, path: { string }, name: string)
	local function walk(root: any): any
		local node = root:GetService(service)
		for _, step in path do
			node = node and node:FindFirstChild(step)
		end
		return node
	end
	local into, from = walk(place), walk(code)
	local source = from and from:FindFirstChild(name)
	if not into or not source then
		problem("no " .. service .. "/" .. name .. " to copy")
		return
	end
	-- (the labs and old copies of scripts live beside the code: nothing else in these containers stays)
	for _, child in into:GetChildren() do
		child:Destroy()
	end
	source:Clone().Parent = into
end

replaceCode("ServerScriptService", {}, "Server")
replaceCode("StarterPlayer", { "StarterPlayerScripts" }, "Client")
local shared = place:GetService("ReplicatedStorage"):FindFirstChild("Shared")
if shared then
	shared:Destroy()
end
code:GetService("ReplicatedStorage").Shared:Clone().Parent = place:GetService("ReplicatedStorage")

local workspace = place:GetService("Workspace")
for _, child in workspace:GetChildren() do
	if not KEEP_IN_WORKSPACE[child.Name] then
		print("left out of the world:", child.Name)
		child:Destroy()
	end
end
for _, name in DROP_FROM_SERVER_STORAGE do
	local child = place:GetService("ServerStorage"):FindFirstChild(name)
	if child then
		child:Destroy()
	end
end

-- Phones hold only what is near; the owner's rule. MinRadius and TargetRadius: .claude/skills/studio-build/RESEARCH.md.
workspace.StreamingEnabled = true
workspace.StreamingMinRadius = 64
workspace.StreamingTargetRadius = 400
workspace.StreamOutBehavior = Enum.StreamOutBehavior.Opportunistic
workspace.ModelStreamingBehavior = Enum.ModelStreamingBehavior.Improved
workspace.StreamingIntegrityMode = Enum.StreamingIntegrityMode.PauseOutsideLoadedArea

local map = workspace:FindFirstChild("Map")
local template = if map then map:FindFirstChild("Plot" .. Config.Plots.TemplatePlot) else nil
local parts = 0
if template then
	for _, d in template:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
end
if parts == 0 then
	problem("no village template: Workspace.Map.Plot" .. Config.Plots.TemplatePlot)
end
if not (map and map:FindFirstChild("Market")) then
	problem("no Workspace.Map.Market")
end
if not place:GetService("ReplicatedStorage"):FindFirstChild("ClientKit") then
	problem("no ReplicatedStorage.ClientKit")
end

-- Nothing may run for players but the repo's code.
for _, service in place:GetChildren() do
	for _, d in service:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			local name = d:GetFullName()
			if
				not string.find(name, "^ServerScriptService%.Server%.")
				and not string.find(name, "^StarterPlayer%.StarterPlayerScripts%.Client%.")
				and not string.find(name, "^ReplicatedStorage%.Shared%.")
			then
				problem("a script from outside the repo: " .. name)
			end
		end
	end
end

if Config.Save.StudioUsesRealStore or Config.Pads.FreeUpgrades or Config.Leaderboard.StudioUsesRealStore then
	problem("a test switch in Config is on")
end

if #problems > 0 then
	for _, text in problems do
		print("PROBLEM:", text)
	end
	print("PUBLISH PLACE FAILED")
	process.exit(1)
end

fs.writeFile(OUT, roblox.serializePlace(place))
print(string.format("village template: %d parts", parts))
print("PUBLISH PLACE OK:", OUT)
