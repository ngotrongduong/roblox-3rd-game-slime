# Makes art/models/slime_body/skins/mirror_metal.png: the "mirror metal" map for the slime body's all-round
# UV (image top = tip, v = arc length from the base centre, uv_profile.json). Roblox reflects only a blurred
# sky, so polished metal reads milky; this map carries the classic chrome reflection instead - bright sky
# above, a dark horizon line where the body is widest (where a mirror shows the horizon), the ground below -
# in greys, tinted per metal by SurfaceAppearance.Color, with metalness 1 so the engine's own sun highlight
# and sky reflection still move on top.
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$prof = Get-Content (Join-Path $root "art\models\slime_body\uv_profile.json") -Raw | ConvertFrom-Json
# v of the widest ring (rows run v = 0 base .. 1 tip)
$best = 0; $vw = 0.5
for ($i = 0; $i -lt $prof.r.Count; $i++) { if ($prof.r[$i] -gt $best) { $best = $prof.r[$i]; $vw = $prof.v[$i] } }
$yh = 1 - $vw # image y fraction of the horizon line
$W = 1024; $H = 512
$b = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($b)
# (y fraction from the top, grey) stops, interpolated row by row
$sy = [double[]](0.0, ($yh * 0.55), ($yh - 0.06), ($yh - 0.012), $yh, ($yh + 0.025), ($yh + 0.07), ($yh + 0.22), 0.93, 1.0)
$sg = [double[]](255, 238, 200, 120, 45, 60, 165, 135, 80, 60)
for ($y = 0; $y -lt $H; $y++) {
	$f = ($y + 0.5) / $H
	$k = 0
	while ($k -lt $sy.Count - 2 -and $f -gt $sy[$k + 1]) { $k++ }
	# (double literals: [math]::Min(1, x) picks the int overload and rounds x)
	$t = [math]::Min([double]1.0, [math]::Max([double]0.0, [double](($f - $sy[$k]) / ($sy[$k + 1] - $sy[$k]))))
	$v = [int][math]::Round($sg[$k] + ($sg[$k + 1] - $sg[$k]) * $t)
	$pen = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, $v, $v, $v))
	$g.FillRectangle($pen, 0, $y, $W, 1)
	$pen.Dispose()
}
$g.Dispose()
$out = Join-Path $root "art\models\slime_body\skins\mirror_metal.png"
$b.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$b.Dispose()
"saved $out (horizon at v $vw)"
