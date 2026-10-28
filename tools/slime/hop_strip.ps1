# A strip of pictures of one hop of the "exciting" slime on the emotion stage (crouch, launch, stretch, land, wobble),
# stepping the real SlimeActor by hand: art/faces/hop_strip.png. Usage: & "...\tools\slime\hop_strip.ps1"
# (Studio in Edit mode, the stage built by emotions.ps1)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$studios = (node "$root\tools\studio_mcp.js" call list_roblox_studios | ConvertFrom-Json).studios
$id = ($studios | Where-Object { $_.name -like "MapWork*" } | Select-Object -First 1).id
$tmp = Join-Path $env:TEMP "hop_frames.txt"
$dir = "$root\art\faces\shots"
New-Item -ItemType Directory -Force $dir | Out-Null
# 60 steps a second: the crouch, the launch, the rise, the top, the fall, the landing and the wobble after it
$steps = 0, 6, 8, 10, 12, 8, 6, 8, 10
$n = 0
foreach ($s in $steps) {
    Set-Content -Path $tmp -Value "$s" -NoNewline
    node "$root\tools\studio_mcp.js" run "$root\tools\slime\hop_strip.luau" $id Edit "FRAMES=$tmp" | Out-Null
    if ($s -eq 0) { continue }
    $n++
    node "$root\tools\studio_mcp.js" shot $id "$dir\hop_$n.png" -62 302.2 -787 -70.5 301.8 -794 | Out-Null
}
python "$root\tools\faces\sheet_hop.py" $n
