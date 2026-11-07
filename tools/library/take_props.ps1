# Takes props out of a free pack in art/library (Quaternius glTF exports) and makes each a small self-contained GLB in
# art/library/converted/<Set>/, ready for the Open Cloud upload (Studio MCP open_cloud_invoke, assetType Model).
#   & "C:\Roblox 3rd game\tools\library\take_props.ps1" -Zip "<pack>.zip" -Names "Barrel","Bench" -Set fantasy_props
param([string]$Zip, [string[]]$Names, [string]$Set)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$src = Join-Path $env:TEMP ("take_props_" + $Set)
New-Item -ItemType Directory -Force -Path $src | Out-Null
$want = '^(' + ($Names -join '|') + ')\.(gltf|bin)$'
$z = [System.IO.Compression.ZipFile]::OpenRead($Zip)
try {
	foreach ($e in $z.Entries) {
		# the models asked for, and every picture next to them (the packs share a few texture sheets)
		if ($e.FullName -match '/glTF/' -and ($e.Name -match $want -or $e.Name -match '\.png$')) {
			[System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $src $e.Name), $true)
		}
	}
} finally { $z.Dispose() }
$out = Join-Path "C:\Roblox 3rd game\art\library\converted" $Set
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\library\gltf_to_glb.py" -- $src $out
