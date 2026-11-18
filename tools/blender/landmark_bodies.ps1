# Builds the named landmark bodies (tools/blender/landmark_bodies.py) into art/models/granary/blender/ and prints
# their ROW lines and any error. Names are exact model names, separated by spaces:
#   & "C:\Roblox 3rd game\tools\blender\landmark_bodies.ps1" DockBody3 DockRoof3 DockStorey3
if ($args.Count -eq 0) {
	"name at least one model (GranaryBody1, KitchenStack1, DockTall4, ...)"
	exit 1
}
$env:LANDMARK_BODIES = ($args -join ",")
$out = & "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\landmark_bodies.py" 2>&1
$out | Where-Object { $_ -match "granary_pieces|ROW|Error|Traceback|line \d+|Exception" } | ForEach-Object { "$_" }
