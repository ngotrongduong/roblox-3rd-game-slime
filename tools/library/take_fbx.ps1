# Takes props out of a free pack in art/library that ships FBX (Quaternius' older flat-colour packs) and makes each a small
# self-contained GLB in art/library/converted/<Set>/ (the materials' colours become vertex colours), plus a preview picture
# in art/library/converted/<Set>/preview/. Same job as take_props.ps1 for glTF packs.
#   & "C:\Roblox 3rd game\tools\library\take_fbx.ps1" -Zip "<pack>.zip" -Names "Rock_1","Bush_1" -Set meadow
param([string]$Zip, [string[]]$Names, [string]$Set)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$src = Join-Path $env:TEMP ("take_fbx_" + $Set)
if (Test-Path $src) { Remove-Item -Recurse -Force $src }
New-Item -ItemType Directory -Force -Path $src | Out-Null
$want = '^(' + ($Names -join '|') + ')\.fbx$'
$z = [System.IO.Compression.ZipFile]::OpenRead($Zip)
try {
	foreach ($e in $z.Entries) {
		if ($e.FullName -match '/FBX/' -and $e.Name -match $want) {
			[System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $src $e.Name), $true)
		}
	}
} finally { $z.Dispose() }
$out = Join-Path "C:\Roblox 3rd game\art\library\converted" $Set
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\library\fbx_to_glb.py" -- $src $out
