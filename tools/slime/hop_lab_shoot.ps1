# Pictures of the movement lab in Edit mode (no play test): steps the lab by hand and shoots it.
# Usage: & "...\tools\slime\hop_lab_shoot.ps1" -Frames 90 -Out overview -Camera 160,345,-745,160,300,-800
#   -Frames  1/60 s steps to take first (0 = none)   -Out  file name in art\movement_lab (no extension)
#   -Camera  six numbers: where the camera stands and what it looks at
param([int]$Frames = 0, [string]$Out = "shot", [double[]]$Camera = @(160, 345, -745, 160, 300, -800))
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$studios = (node "$root\tools\studio_mcp.js" call list_roblox_studios | ConvertFrom-Json).studios
$id = ($studios | Where-Object { $_.name -like "MapWork*" } | Select-Object -First 1).id
if (-not $id) { Write-Host "MapWork is not open in Studio"; exit 1 }
$dir = "$root\art\movement_lab"
New-Item -ItemType Directory -Force $dir | Out-Null
$tmp = Join-Path $env:TEMP "hop_lab_frames.txt"
Set-Content -Path $tmp -Value "$Frames" -NoNewline
node "$root\tools\studio_mcp.js" run "$root\tools\slime\hop_lab_step.luau" $id Edit "FRAMES=$tmp"
node "$root\tools\studio_mcp.js" shot $id "$dir\$Out.png" $Camera[0] $Camera[1] $Camera[2] $Camera[3] $Camera[4] $Camera[5]
