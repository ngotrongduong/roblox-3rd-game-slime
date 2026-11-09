# Rebuilds Ember Lava's props end to end: the ones made by script (make_lava.py: basalt masses, column groups, ledges, floor
# plates, boulders, peaks, lava fissures and pools), the Quaternius Ultimate Nature rocks recoloured to the Lava palette
# (fbx_to_glb.py: OVERRIDE / SUFFIX / MAX_TRIS), and ONE combined art/library/converted/LavaProps.glb for the owner's single
# File > Import 3D. Prints each prop's triangle count.
#   & "C:\Roblox 3rd game\tools\library\build_lava.ps1"
$root = "C:\Roblox 3rd game"
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$tools = "$root\tools\library"
$out = "$root\art\library\converted\lava"
$nature = "$root\art\library\quaternius\Ultimate Nature Pack - Jun 2019.zip"
$stage = Join-Path $env:TEMP "build_lava"
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
$lines = & $blender -b --factory-startup -P "$tools\make_lava.py" -- $out
foreach ($l in $lines) { if ($l -match '^GLB ') { $report += $l } }

# the Lava palette over the packs' material names (round 4: dark neutral basalt, #28262D with the stone highlight #48434B on
# the light faces; no dead trees: the painting has no plants)
$lava = '{"Rock":"#34313a","Wood":"#28262d","LightWood":"#28262d","Black":"#1f1d24","DarkGreen":"#28262d","Green":"#28262d"}'
$env:RAW = "1"
Run-Fbx $nature @("Rock_1", "Rock_2", "Rock_3", "Rock_4", "Rock_5") "rocks" 140 $lava "_Lava"
Remove-Item Env:RAW
Remove-Item Env:MAX_TRIS
Remove-Item Env:OVERRIDE
Remove-Item Env:SUFFIX

$lines = & $blender -b --factory-startup -P "$tools\combine_glb.py" -- $out "$root\art\library\converted\LavaProps.glb"
foreach ($l in $lines) { if ($l -match '^WROTE ') { $report += $l } }
$report
