# Builds the base slime body (tools/blender/slime_body.py) headless; outputs in art/models/slime_body.
# Usage: & "C:\Roblox 3rd game\tools\blender\slime_body.ps1" -Round 1
param([int]$Round = 1)
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\slime_body.py" -- --round $Round
