# Cuts the owner's weapon models into the 30 held weapons (tools/blender/weapon_kit.py): FBX and texture a file in
# art/models/weapons/, a review picture each in art/models/weapons/review/.
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\weapon_kit.py" 2>&1 | Select-String -Pattern "^(KIT|FBX|DONE)|Error|Traceback|line \d+"
