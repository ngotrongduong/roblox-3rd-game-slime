# Usage: sample.ps1 -Painting enemy-green-sprout.png -Points "body:600,640","belly:700,900"
param([string]$Painting, [string[]]$Points)
$out = & "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\monsters\sample.py" -- $Painting @Points
$out | Where-Object { $_ -like "*[[]sample]*" } | ForEach-Object { Write-Output $_ }
