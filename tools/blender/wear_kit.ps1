# Builds a Secret slime's worn pieces (tools/blender/wear_kit.py) into art/models/accessories/<folder>/:
#   & "C:\Roblox 3rd game\tools\blender\wear_kit.ps1" SteamDragon
param([Parameter(Mandatory = $true)][string]$Kit)
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\wear_kit.py" -- $Kit 2>&1 | Select-String -Pattern "^(PIECE|KEPT|HORN|FLAP|WEAR|DONE)|Error|Traceback|line \d+"
