# Splits one region's monster slimes out of the owner's 3D file (tools/blender/monster_split.py):
#   & "C:\Roblox 3rd game\tools\blender\monster_split.ps1" "<file>.glb" meadow
param([string]$Glb, [string]$Region)
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\monster_split.py" -- $Glb $Region 2>&1 | Select-String -Pattern "^(ISLANDS|MAJOR|FAR|MONSTER|TEXTURE|DONE)|Error|Traceback|line \d+"
