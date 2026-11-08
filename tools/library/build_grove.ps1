# Rebuilds the Mushroom Grove's props end to end: the ones made by script (make_grove.py), the Quaternius Ultimate Nature and
# Ultimate Modular Ruins props recoloured to the Grove palette (fbx_to_glb.py: OVERRIDE / SUFFIX / MAX_TRIS), and ONE combined
# art/library/converted/MushroomProps.glb for the owner's single File > Import 3D. Prints each prop's triangle count.
#   & "C:\Roblox 3rd game\tools\library\build_grove.ps1"
$root = "C:\Roblox 3rd game"
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$tools = "$root\tools\library"
$out = "$root\art\library\converted\mushroom"
$nature = "$root\art\library\quaternius\Ultimate Nature Pack - Jun 2019.zip"
$ruins = "$root\art\library\quaternius\Ultimate Modular Ruins Pack - Aug 2021.zip"
$stage = Join-Path $env:TEMP "build_grove"
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

# the procedural props
$lines = & $blender -b --factory-startup -P "$tools\make_grove.py" -- $out
foreach ($l in $lines) { if ($l -match '^GLB ') { $report += $l } }

# the Grove's cool palette over the packs' material names: teal leaves, bluish rock, purple-brown wood, glowing berries
$grove = '{"DarkGreen":"#1f8f78","Green":"#3cc09a","Wood":"#7a5a4c","Berry":"#ff6fb5","Rock":"#8f9c9e","Cyan":"#4fc8ff","Yellow":"#ffd84a"}'
Run-Fbx $nature @("Willow_1", "Willow_3", "CommonTree_2", "CommonTree_Dead_3", "CommonTree_Dead_4", "Willow_Dead_3", "Willow_Dead_1") "trees" 450 $grove "_Grove"
Run-Fbx $nature @("Bush_1", "Bush_2", "Plant_3", "Plant_4", "Plant_1") "bushes" 220 $grove "_Grove"
Run-Fbx $nature @("Flowers") "fl1" 200 $grove "_GroveBlue"
Run-Fbx $nature @("Flowers") "fl2" 200 '{"DarkGreen":"#1f8f78","Green":"#3cc09a","Cyan":"#c27cff","Yellow":"#ffd84a"}' "_GrovePurple"
Run-Fbx $nature @("Flowers") "fl3" 200 '{"DarkGreen":"#1f8f78","Green":"#3cc09a","Cyan":"#ff7fbf","Yellow":"#fff1a0"}' "_GrovePink"
Run-Fbx $nature @("Rock_6", "Rock_7", "Rock_Moss_1", "Rock_Moss_2", "Rock_Moss_4", "Rock_Moss_5", "Rock_Moss_7") "rocks" 130 $grove "_Grove"
$stone = '{"Main":"#a39f86","Highlights":"#cfc9aa","Black":"#6e6a58"}'
Run-Fbx $ruins @("Column_Round", "Column_Round_Short", "Wall_Half", "Wall_Broken", "Wall_Double_Broken", "Bricks", "Arch_Round") "ruins" 450 $stone "_Grove"
Remove-Item Env:MAX_TRIS
Remove-Item Env:OVERRIDE
Remove-Item Env:SUFFIX

$lines = & $blender -b --factory-startup -P "$tools\combine_glb.py" -- $out "$root\art\library\converted\MushroomProps.glb"
foreach ($l in $lines) { if ($l -match '^WROTE ') { $report += $l } }
$report
