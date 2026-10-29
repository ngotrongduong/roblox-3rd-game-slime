# Builds the movement lab in the open MapWork place (tools/slime/hop_lab.luau): eight lanes, one slime each, each lane a
# different style of hop or glide, numbers on the floor signs (the table is tools/slime/hop_lab_lanes.luau).
# Usage: & "C:\Roblox 3rd game\tools\slime\hop_lab.ps1"      (Studio in Edit mode, "Enable Studio as MCP server" on)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$studios = (node "$root\tools\studio_mcp.js" call list_roblox_studios | ConvertFrom-Json).studios
$id = ($studios | Where-Object { $_.name -like "MapWork*" } | Select-Object -First 1).id
if (-not $id) { Write-Host "MapWork is not open in Studio"; exit 1 }
node "$root\tools\studio_mcp.js" run "$root\tools\slime\hop_lab.luau" $id Edit `
    "CONFIG_SRC=$root\src\shared\Config.luau" `
    "EXPRESSIONS_SRC=$root\src\shared\Expressions.luau" `
    "FACEART_SRC=$root\src\shared\FaceArt.luau" `
    "SLIMESHAPE_SRC=$root\src\shared\SlimeShape.luau" `
    "SLIMEFACE_SRC=$root\src\client\SlimeFace.luau" `
    "LANES_SRC=$root\tools\slime\hop_lab_lanes.luau" `
    "LAB_SRC=$root\tools\slime\hop_lab_client.luau"
