# Rigs, skins and animates one region's monster slimes (tools/blender/monster_rig.py), then composes the review sheets
# (tools/blender/monster_rig_sheets.py):
#   & "C:\Roblox 3rd game\tools\blender\monster_rig.ps1" [region] [Name+Name or all] [full or weights or norender]
param([string]$Region = "meadow", [string]$Only = "all", [string]$Mode = "full")
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\monster_rig.py" -- $Region $Only $Mode 2>&1 | Select-String -Pattern "^(CHECK|CAGE|BONE|JOINT|PROFILE|FLOWER|PETALS|ORANGE|THICK|FAIL|EXPORT|ACTION|DONE|CHAIN|TEX|PART|CUT)|Error|Traceback|line \d+"
python "C:\Roblox 3rd game\tools\blender\monster_rig_sheets.py" $Region
