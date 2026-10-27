# Formats, lints, tests and builds the place file. Run from anywhere:
#   & "C:\Roblox 3rd game\tools\check.ps1"
$root = Split-Path -Parent $PSScriptRoot
# (the tool versions are rokit.toml's alone)
. (Join-Path $PSScriptRoot "rokit_paths.ps1")
$rojo = Get-RokitTool "rojo"
$lune = Get-RokitTool "lune"
$stylua = Get-RokitTool "stylua"
$selene = Get-RokitTool "selene"

Set-Location $root
$failed = $false

Write-Host "== format (stylua)"
& $stylua src tests
if ($LASTEXITCODE -ne 0) { $failed = $true }

Write-Host "== lint (selene)"
& $selene src
if ($LASTEXITCODE -ne 0) { $failed = $true }

Write-Host "== tests (lune)"
& $lune run tests/run.luau
if ($LASTEXITCODE -ne 0) { $failed = $true }

Write-Host "== build (rojo)"
& $rojo build default.project.json -o GooLineage.rbxlx
if ($LASTEXITCODE -ne 0) { $failed = $true }

if ($failed) {
    Write-Host "CHECK FAILED"
    exit 1
}
Write-Host "CHECK OK"
