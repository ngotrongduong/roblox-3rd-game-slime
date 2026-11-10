# Builds a Secret slime's own body (tools/blender/secret_body.py) into art/models/secret_bodies/<folder>/:
#   & "C:\Roblox 3rd game\tools\blender\secret_body.ps1" moss_golem
param([Parameter(Mandatory = $true)][string]$Folder)
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\secret_body.py" -- $Folder 2>&1 | Select-String -Pattern "^(BOX|TRIS|MAP|FBX|DONE)|Error|Traceback|line \d+"
