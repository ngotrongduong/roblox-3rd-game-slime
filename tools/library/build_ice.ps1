# Rebuilds Frozen Ice's props end to end: the ones made by script (make_ice.py: snow mounds, pine groves, slate masses, boulders,
# crystal clusters and shards, twig corals, shrubs, snow fences, lake cracks), the Quaternius Ultimate Nature snow variants
# recoloured to the Ice palette (fbx_to_glb.py: OVERRIDE / SUFFIX / MAX_TRIS), and ONE combined
# art/library/converted/IceProps.glb for the owner's single File > Import 3D. Prints each prop's triangle count.
#   & "C:\Roblox 3rd game\tools\library\build_ice.ps1"
$root = "C:\Roblox 3rd game"
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$tools = "$root\tools\library"
$out = "$root\art\library\converted\ice"
$nature = "$root\art\library\quaternius\Ultimate Nature Pack - Jun 2019.zip"
$stage = Join-Path $env:TEMP "build_ice"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$report = @()

function Stage-Fbx($zip, $names, $dest) {
	if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
	New-Item -ItemType Directory -Force -Path $dest | Out-Null
	$want = '^(' + ($names -join '|') + ')\.fbx$'
	$z = [System.IO.Compression.ZipFile]::OpenRead($zip)
	try {
		foreach ($e in $z.Entries) {
			if (($e.FullName -match '(^|/)FBX/') -and ($e.Name -match $want)) {
				[System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $dest $e.Name), $true)
			}
		}
	} finally { $z.Dispose() }
}

function Run-Fbx($zip, $names, $name, $max, $override, $suffix) {
	$dest = Join-Path $stage $name
	Stage-Fbx $zip $names $dest
	$env:MAX_TRIS = "$max"
	$env:OVERRIDE = $override
	$env:SUFFIX = $suffix
	$lines = & $blender -b --factory-startup -P "$tools\fbx_to_glb.py" -- $dest $out
	foreach ($l in $lines) { if ($l -match '^GLB ') { $script:report += $l } }
}

# a stale file of an earlier build must not ride into the combined GLB
if (Test-Path $out) { Remove-Item -Recurse -Force $out }

# the procedural props
$lines = & $blender -b --factory-startup -P "$tools\make_ice.py" -- $out
foreach ($l in $lines) { if ($l -match '^GLB ') { $report += $l } }

# the Ice palette over the packs' material names: white snow (#f4f8ff), pale blue-green pine needles, dark cool twigs, and the
# slate rock that is the map's contrast (clearly darker than the floor #dbe9f7 and the snow). Raw sRGB, as make_ice.py stores.
$ice = '{"Snow":"#f0f6fa","Green":"#86c3c0","DarkGreen":"#5f9ea6","Wood":"#4a4658","LightWood":"#6a6478","Rock":"#4e6a85","Black":"#405a75","White":"#e6f1f8"}'
$env:RAW = "1"
# frosted pines, and the bare twig trees (Willow_Dead is the coral look); the other variants of those names use other material names
Run-Fbx $nature @("PineTree_Snow_1", "PineTree_Snow_2", "PineTree_Snow_4", "PineTree_Snow_5", "CommonTree_Dead_Snow_3", "CommonTree_Dead_Snow_4", "Willow_Dead_Snow_1", "Willow_Dead_Snow_3", "Willow_Dead_Snow_4") "trees" 420 $ice "_Ice"
Run-Fbx $nature @("Rock_Snow_1", "Rock_Snow_3", "Rock_Snow_4", "Rock_Snow_5", "Rock_Snow_6") "rocks" 160 $ice "_Ice"
Run-Fbx $nature @("Bush_Snow_1", "Bush_Snow_2", "TreeStump_Snow", "WoodLog_Snow") "small" 220 $ice "_Ice"
Remove-Item Env:RAW
Remove-Item Env:MAX_TRIS
Remove-Item Env:OVERRIDE
Remove-Item Env:SUFFIX

$lines = & $blender -b --factory-startup -P "$tools\combine_glb.py" -- $out "$root\art\library\converted\IceProps.glb"
foreach ($l in $lines) { if ($l -match '^WROTE ') { $report += $l } }
$report
