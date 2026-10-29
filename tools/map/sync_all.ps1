# Copies the whole game code from the repo into the work place open in Studio (MapWork), so a play test there runs the
# real game on the hand-built map: src/shared -> ReplicatedStorage.Shared, src/server -> ServerScriptService.Server,
# src/client -> StarterPlayer.StarterPlayerScripts.Client (".server" = Script, ".client" = LocalScript, the rest
# ModuleScripts; each one replaced fresh, since Studio caches what require returned; other objects in those folders
# are left alone). It also fills ReplicatedStorage.ClientKit from the place's own slime body and food models when it
# is missing (the same content as assets/ClientKit.rbxm).
#   & "C:\Roblox 3rd game\tools\map\sync_all.ps1" -StudioId <id from list_roblox_studios>
param([Parameter(Mandatory = $true)][string]$StudioId)
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out = Join-Path $env:TEMP "goolineage_sync_all.luau"
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("local FILES = {")
$groups = @(
	@{ Dir = "src\shared"; Dest = "Shared" },
	@{ Dir = "src\server"; Dest = "Server" },
	@{ Dir = "src\client"; Dest = "Client" }
)
foreach ($g in $groups) {
	foreach ($f in Get-ChildItem (Join-Path $root $g.Dir) -Filter *.luau) {
		$name = $f.BaseName
		$class = "ModuleScript"
		if ($name.EndsWith(".server")) { $class = "Script"; $name = $name.Substring(0, $name.Length - 7) }
		elseif ($name.EndsWith(".client")) { $class = "LocalScript"; $name = $name.Substring(0, $name.Length - 7) }
		$src = Get-Content $f.FullName -Raw -Encoding UTF8
		[void]$sb.AppendLine("{ `"$($g.Dest)`", `"$name`", `"$class`", [=====[$src]=====] },")
	}
}
[void]$sb.AppendLine("}")
[void]$sb.Append((Get-Content (Join-Path $PSScriptRoot "sync_all_body.luau") -Raw -Encoding UTF8))
[System.IO.File]::WriteAllText($out, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
node (Join-Path $root "tools\studio_mcp.js") run $out $StudioId Edit
