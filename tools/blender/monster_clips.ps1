param([string]$Region)
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\monster_clips.py" -- $Region 2>&1 | Select-String -Pattern "^(ACTION|CLIPS|WARN|DONE)|Error|Traceback|line \d+"
