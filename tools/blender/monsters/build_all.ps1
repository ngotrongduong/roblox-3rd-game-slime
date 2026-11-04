# Rebuilds all seven Sunny Meadow monsters (FBX, palette png, json, review sheets), then MOTION.md, sheet.png and lineup.png.
# Run: & "C:\Roblox 3rd game\tools\blender\monsters\build_all.ps1" [-Round r9]
param([string]$Round = "final")
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$dir = "C:\Roblox 3rd game\tools\blender\monsters"
$names = @("sproutling", "honey_bee", "puffdandy", "glowmoth", "clover_snail", "bloomshell", "bramblehorn")
foreach ($n in $names) {
	$out = & $blender -b --factory-startup -P "$dir\$n.py" -- $Round
	$out | Where-Object { $_ -like "*[[]monster]*" } | ForEach-Object { Write-Output $_ }
}
$out = & $blender -b --factory-startup -P "$dir\motion_md.py"
$out | Where-Object { $_ -like "*[[]monster]*" } | ForEach-Object { Write-Output $_ }
$out = & $blender -b --factory-startup -P "$dir\sheets.py"
$out | Where-Object { $_ -like "*[[]monster]*" -or $_ -like "*Error*" -or $_ -like "*Traceback*" } | ForEach-Object { Write-Output $_ }
