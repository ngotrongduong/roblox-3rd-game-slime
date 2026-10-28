# One close picture of every slime of the emotion stage (Workspace.SlimeEmotions, tools/slime/emotions.luau) from the
# front, into art/faces/shots/<emotion>.png, then the contact sheet art/faces/review_emotions.png.
# Usage: & "C:\Roblox 3rd game\tools\slime\shoot_emotions.ps1" [-Only "happy,sad"]   (Studio in Edit mode)
param([string]$Only = "")
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$studios = (node "$root\tools\studio_mcp.js" call list_roblox_studios | ConvertFrom-Json).studios
$id = ($studios | Where-Object { $_.name -like "MapWork*" } | Select-Object -First 1).id
$order = "normal","happy","laughing","exciting","wink","admiring","loved","shy","proud","dare","curious","surprise","scared","angry","sulking","sad","crying","dizzy","sleepy","sleep","bored","hungry","eating","full"
$dir = "$root\art\faces\shots"
New-Item -ItemType Directory -Force $dir | Out-Null
$want = if ($Only -ne "") { $Only.Split(",") } else { $order }
# the first picture after the pictures were loaded can still come out without faces: a throw-away shot first
node "$root\tools\studio_mcp.js" shot $id "$dir\warmup.png" -97.5 304.3 -785.5 -97.5 301.4 -794 | Out-Null
for ($i = 0; $i -lt $order.Count; $i++) {
    if ($want -notcontains $order[$i]) { continue }
    $col = $i % 6
    $row = [math]::Floor($i / 6)
    $x = -75 + ($col - 2.5) * 9
    $z = -800 + 6 - $row * 11
    # the face is 1.5 studs up the body; look at it from above and 8.5 studs in front, over the slime of the row before
    node "$root\tools\studio_mcp.js" shot $id "$dir\$($order[$i]).png" $x 304.3 ($z + 8.5) $x 301.4 $z | Out-Null
}
python "$root\tools\faces\sheet_emotions.py"
