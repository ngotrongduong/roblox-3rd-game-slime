# Builds Tempest Dragon's worn pieces (tools/blender/wear_tempest_dragon.py) into art/models/accessories/tempest_dragon/.
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\wear_tempest_dragon.py" 2>&1 | Select-String -Pattern "^(NODE|PIECE|KEPT|FLAP|WEAR|DONE)|Error|Traceback|line \d+"
