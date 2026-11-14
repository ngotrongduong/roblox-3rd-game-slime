# Draws art/map/world_map.png, the picture of the map (client/UiMap), from the plan of the big world.
#   & "C:\Roblox 3rd game\tools\world\map_picture.ps1"
# Then upload it (Studio MCP upload_image from the picture server) and put the id in Config.World.Map.Image.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $root
$plan = Join-Path $env:TEMP "goo_world_plan.json"
New-Item -ItemType Directory -Force (Join-Path $root "art\map") | Out-Null
lune run tools/world/export_plan.luau $plan
if ($LASTEXITCODE -ne 0) { throw "export_plan failed" }
python tools/world/map_picture.py $plan (Join-Path $root "art\map\world_map.png")
if ($LASTEXITCODE -ne 0) { throw "map_picture failed" }
