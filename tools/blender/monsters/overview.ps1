# MOTION.md, sheet.png and lineup.png only (after single builds).
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$dir = "C:\Roblox 3rd game\tools\blender\monsters"
$out = & $blender -b --factory-startup -P "$dir\motion_md.py"
$out | Where-Object { $_ -like "*[[]monster]*" -or $_ -like "*Error*" } | ForEach-Object { Write-Output $_ }
$out = & $blender -b --factory-startup -P "$dir\sheets.py"
$out | Where-Object { $_ -like "*[[]monster]*" -or $_ -like "*Error*" -or $_ -like "*Traceback*" -or $_ -like "*File*" } | ForEach-Object { Write-Output $_ }
