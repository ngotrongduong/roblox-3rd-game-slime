# Builds ONE monster: tools/blender/monsters/build.ps1 -Name sproutling [-Round r1]
# Out: art/models/monsters/<Name>/ (FBX, palette png, json, review/sheet_<round>.png). Prints only the result lines.
param([string]$Name = "sproutling", [string]$Round = "r1")
$out = & "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\monsters\$Name.py" -- $Round
$out | Where-Object { $_ -notmatch "render +\| Saved" -and $_ -notmatch "^\s*$" -and $_ -notmatch "Blender (5|quit)" } | ForEach-Object { Write-Output $_ }
