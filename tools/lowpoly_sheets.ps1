# The owner's Meshy low-poly library (C:\Ai kiem tien\products\lowpoly-library, thousands of CC0 models), seen cheaply:
# never open the models or list the folders, read the catalog by script and look at contact sheets of the previews.
#   & "C:\Roblox 3rd game\tools\lowpoly_sheets.ps1"                         model counts per theme\folder
#   & "C:\Roblox 3rd game\tools\lowpoly_sheets.ps1" Props                   sheets of every folder of a theme
#   & "C:\Roblox 3rd game\tools\lowpoly_sheets.ps1" Monsters\Dragons ice    one folder, names matching a regex
# Sheets (48 numbered tiles, name and triangle count under each) and an index <tag>.txt (n|file|triangles) go to
# C:\tmp\lowpoly-sheets. One sheet costs about as much to look at as 20 lines of text.
param([string]$Folder = '', [string]$Match = '')
$lib = 'C:\Ai kiem tien\products\lowpoly-library\models'
$rows = Import-Csv -LiteralPath (Join-Path $lib 'catalog.csv')
if (-not $Folder) {
	Write-Output ("rows " + $rows.Count)
	$rows | Group-Object theme | ForEach-Object {
		$subs = $_.Group | Group-Object folder | Sort-Object Count -Descending | ForEach-Object { $_.Name + ' ' + $_.Count }
		Write-Output ($_.Name + ' ' + $_.Count + ' : ' + ($subs -join ', '))
	}
	return
}
Add-Type -AssemblyName System.Drawing
$out = 'C:\tmp\lowpoly-sheets'
New-Item -ItemType Directory -Force $out | Out-Null
$pick = $rows | Where-Object { ($_.theme + '\' + $_.folder) -like ($Folder + '*') }
if ($Match) { $pick = $pick | Where-Object { $_.name -match $Match } }
$pick = @($pick | Sort-Object name)
$tile = 150; $label = 26; $cols = 8; $perSheet = 48
$tag = ($Folder -replace '[\\ ]', '_') + $(if ($Match) { '_m' } else { '' })
$font = New-Object System.Drawing.Font('Arial', 7.5)
$bold = New-Object System.Drawing.Font('Arial', 10, [System.Drawing.FontStyle]::Bold)
$index = @()
$sheetCount = [math]::Ceiling($pick.Count / $perSheet)
for ($s = 0; $s -lt $sheetCount; $s++) {
	$chunk = @($pick | Select-Object -Skip ($s * $perSheet) -First $perSheet)
	$rowsN = [math]::Ceiling($chunk.Count / $cols)
	$bmp = New-Object System.Drawing.Bitmap(($cols * $tile), ($rowsN * ($tile + $label)))
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.Clear([System.Drawing.Color]::FromArgb(40, 40, 46))
	$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	for ($i = 0; $i -lt $chunk.Count; $i++) {
		$r = $chunk[$i]
		$n = $s * $perSheet + $i + 1
		$x = ($i % $cols) * $tile
		$y = [math]::Floor($i / $cols) * ($tile + $label)
		$png = Join-Path $lib ($r.file -replace '\.glb$', '.png')
		if (Test-Path -LiteralPath $png) {
			# a preview that is not really a PNG stays an empty tile
			try {
				$img = [System.Drawing.Image]::FromFile($png)
				$g.DrawImage($img, $x + 2, $y + 2, $tile - 4, $tile - 4)
				$img.Dispose()
			} catch {}
		}
		$g.DrawString([string]$n, $bold, [System.Drawing.Brushes]::Yellow, $x + 3, $y + 3)
		$name = $r.name
		if ($name.Length -gt 26) { $name = $name.Substring(0, 26) }
		$g.DrawString($name, $font, [System.Drawing.Brushes]::White, $x + 2, $y + $tile)
		$g.DrawString(($r.triangles + 't'), $font, [System.Drawing.Brushes]::LightGreen, $x + 2, $y + $tile + 12)
		$index += ('{0}|{1}|{2}' -f $n, $r.file, $r.triangles)
	}
	$g.Dispose()
	$path = Join-Path $out ('{0}_{1}.jpg' -f $tag, ($s + 1))
	$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
	$bmp.Dispose()
	Write-Output $path
}
Set-Content -LiteralPath (Join-Path $out ($tag + '.txt')) -Value $index -Encoding utf8
Write-Output ('models ' + $pick.Count + ', sheets ' + $sheetCount)
