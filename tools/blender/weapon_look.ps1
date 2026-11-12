# A first look at every weapon file in art/models/weapons/source (tools/blender/weapon_look.py).
foreach ($glb in Get-ChildItem "C:\Roblox 3rd game\art\models\weapons\source" -Filter "*.glb") {
	& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\weapon_look.py" -- $glb.FullName 2>&1 | Select-String -Pattern "^(LOOK|PART|DONE)|Error|Traceback|line \d+"
}
