# Renders the Legendary weapons one by one (tools/blender/weapon_icons.py), then trims and outlines them into
# art/icons/weapons/ (tools/blender/weapon_icons_finish.py).
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\weapon_icons.py" 2>&1 | Select-String -Pattern "^(ICON|DONE)|Error|Traceback|line \d+"
& python "C:\Roblox 3rd game\tools\blender\weapon_icons_finish.py"
