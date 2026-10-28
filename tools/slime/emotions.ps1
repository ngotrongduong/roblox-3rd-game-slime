# Builds the emotion review stage in the open MapWork place (tools/slime/emotions.luau) from the repo's own face code.
# Usage: & "C:\Roblox 3rd game\tools\slime\emotions.ps1"      (Studio in Edit mode, "Enable Studio as MCP server" on)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$studios = (node "$root\tools\studio_mcp.js" call list_roblox_studios | ConvertFrom-Json).studios
$id = ($studios | Where-Object { $_.name -like "MapWork*" } | Select-Object -First 1).id
if (-not $id) { Write-Host "MapWork is not open in Studio"; exit 1 }
node "$root\tools\studio_mcp.js" run "$root\tools\slime\emotions.luau" $id Edit `
    "CONFIG_SRC=$root\src\shared\Config.luau" `
    "EXPRESSIONS_SRC=$root\src\shared\Expressions.luau" `
    "FACEART_SRC=$root\src\shared\FaceArt.luau" `
    "SLIMESHAPE_SRC=$root\src\shared\SlimeShape.luau" `
    "SLIMEMOTION_SRC=$root\src\shared\SlimeMotion.luau" `
    "SLIMEFACE_SRC=$root\src\client\SlimeFace.luau" `
    "SLIMEACTOR_SRC=$root\src\client\SlimeActor.luau" `
    "STAGE_SRC=$root\tools\slime\emotions_client.luau"
