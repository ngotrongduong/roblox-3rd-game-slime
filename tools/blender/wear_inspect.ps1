# Looks into an accessory file before its kit is written (tools/blender/wear_inspect.py); renders go to
# <the file's folder>\review\inspect unless an out folder is given:
#   & "C:\Roblox 3rd game\tools\blender\wear_inspect.ps1" "C:\Roblox 3rd game\art\models\accessories\shadow_wolf\black_gray.glb"
param([Parameter(Mandatory = $true)][string]$Glb, [string]$Out = "")
if (-not $Out) {
	$Out = Join-Path (Split-Path $Glb -Parent) "review\inspect"
}
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\wear_inspect.py" -- $Glb $Out 2>&1 | Select-String -Pattern "^(IMG|FILE|ALL|BITS|BIT|DONE)|Error|Traceback|line \d+"
