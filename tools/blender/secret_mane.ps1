# Builds a Secret slime's skin and mane from its own model (tools/blender/secret_mane.py) into
# art/models/secret_bodies/<folder>/:
#   & "C:\Roblox 3rd game\tools\blender\secret_mane.ps1" sun_lion
param([Parameter(Mandatory = $true)][string]$Folder)
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\secret_mane.py" -- $Folder 2>&1 | Select-String -Pattern "^(FIT|BODY|FRONT|  azimuth|HAIR|MANE|MAPS|FBX|SKIN|DONE)|Error|Traceback|line \d+"
