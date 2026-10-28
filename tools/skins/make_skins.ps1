# Draws the 55 Dual slime skins (tools/skins/make_skins.py) in headless Blender; outputs in art/models/slime_body/skins.
# Usage: & "C:\Roblox 3rd game\tools\skins\make_skins.ps1" [-Only "1,5,9"] [-Test] [-Render] [-RenderOnly] [-Pass N]
param([string]$Only = "", [switch]$Test, [switch]$Render, [switch]$RenderOnly, [int]$Pass = 1)
$a = @("--pass", "$Pass")
if ($Only -ne "") { $a += @("--only", $Only) }
if ($Test) { $a += "--test" }
if ($Render -or $RenderOnly) { $a += "--render" }
if ($RenderOnly) { $a += "--render-only" }
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\skins\make_skins.py" -- @a
