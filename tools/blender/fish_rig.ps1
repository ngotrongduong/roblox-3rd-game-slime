# Rigs the owner's decorative fish for VfxLib's swimmers (tools/blender/fish_rig.py):
#   & "C:\Roblox 3rd game\tools\blender\fish_rig.ps1"
param([string]$Glb = "C:\Roblox 3rd game\art\models\fish\decorative_fish.glb")
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\fish_rig.py" -- $Glb 2>&1 | Select-String -Pattern "^(BITS|FISH|TEXTURE|DONE)|Error|Traceback|line \d+"
