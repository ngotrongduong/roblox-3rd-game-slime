# Skill slime-wear, step 10, after Play has started: put the character on the open lawn, line every dressed Secret up
# (each must say n/n pieces), bring one out onto open ground and shoot it from five sides into <out>:
# <secret>-front, -back, -side, -quarter (from above, as the game sees it) and -level (the painting's view).
#   & "C:\Roblox 3rd game\.claude\skills\slime-wear\shoot_close.ps1" <studio_id> secret-blue-white <out folder>
param([string]$StudioId, [string]$Secret, [string]$Out)
$skill = "C:\Roblox 3rd game\.claude\skills\slime-wear"
$tool = "C:\Roblox 3rd game\tools\studio_mcp.js"
New-Item -ItemType Directory -Force $Out | Out-Null
$idFile = Join-Path $Out "secret.txt"
Set-Content -Path $idFile -Value $Secret -Encoding ascii
node $tool run "$skill\play_stage.luau" $StudioId Server
node $tool run "$skill\play_check.luau" $StudioId Client
# (a new texture takes a few seconds to arrive; a shot taken at once shows grey pieces)
Start-Sleep -Seconds 8
$lines = @(node $tool run "$skill\play_close.luau" $StudioId Client "SECRET=$idFile")
$lines
$names = @("front", "back", "side", "quarter", "level")
$k = 0
foreach ($line in $lines) {
	$c = $line.Trim() -split "\s+"
	if ($c.Count -eq 6 -and $k -lt 5) {
		node $tool shot $StudioId (Join-Path $Out "$Secret-$($names[$k]).png") $c[0] $c[1] $c[2] $c[3] $c[4] $c[5]
		$k++
	}
}
