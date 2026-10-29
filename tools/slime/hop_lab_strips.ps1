# A strip of pictures for every lane of the movement lab (Edit mode, stepped by hand): art\movement_lab\strip_<lane>_<n>.png,
# the camera following each slime from the side at about the game's distance. Usage: & "...\tools\slime\hop_lab_strips.ps1"
param([int]$Shots = 6, [int]$Gap = 7)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$studios = (node "$root\tools\studio_mcp.js" call list_roblox_studios | ConvertFrom-Json).studios
$id = ($studios | Where-Object { $_.name -like "MapWork*" } | Select-Object -First 1).id
if (-not $id) { Write-Host "MapWork is not open in Studio"; exit 1 }
$dir = "$root\art\movement_lab"
New-Item -ItemType Directory -Force $dir | Out-Null
$tmp = Join-Path $env:TEMP "hop_lab_frames.txt"
$keys = "A", "B", "C", "D", "E", "F", "G", "H"
for ($lane = 0; $lane -lt 8; $lane++) {
    $z = -800 + (($lane + 1) - 4.5) * 9
    for ($n = 1; $n -le $Shots; $n++) {
        Set-Content -Path $tmp -Value "$Gap" -NoNewline
        $report = node "$root\tools\studio_mcp.js" run "$root\tools\slime\hop_lab_step.luau" $id Edit "FRAMES=$tmp"
        $s = [double](([regex]::Match($report, $keys[$lane] + " s=([0-9.]+)")).Groups[1].Value)
        $x = 140 + $s
        node "$root\tools\studio_mcp.js" shot $id "$dir\strip_$($keys[$lane])_$n.png" $x 314 ($z + 8) $x 301.2 $z | Out-Null
    }
    Write-Host "lane $($keys[$lane]) done"
}
