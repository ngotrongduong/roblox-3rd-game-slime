# Type-checks the sources with luau-lsp, the same checker Roblox Studio uses.
# It reports; it is not part of check.ps1, because it also questions code
# that is right but loosely typed. Run from anywhere:
#   & "C:\Roblox 3rd game\tools\types.ps1"
#   & "C:\Roblox 3rd game\tools\types.ps1" src/server      (one folder or file)
param([string]$Path = "src")

$root = Split-Path -Parent $PSScriptRoot
# (the tool versions are rokit.toml's alone)
. (Join-Path $PSScriptRoot "rokit_paths.ps1")
$rojo = Get-RokitTool "rojo"
$lsp = Get-RokitTool "luau-lsp"
$defs = Join-Path $root "tools\types\globalTypes.d.luau"

if (-not (Test-Path $defs)) {
    Write-Host "missing $defs"
    Write-Host "get scripts/globalTypes.d.luau of JohnnyMorganz/luau-lsp at tag 1.69.0"
    exit 1
}

Set-Location $root
& $rojo sourcemap default.project.json -o sourcemap.json
if ($LASTEXITCODE -ne 0) { exit 1 }

$lines = & $lsp analyze --sourcemap sourcemap.json --definitions "@roblox=$defs" --no-strict-dm-types --formatter plain $Path
$found = @($lines | Where-Object { $_ -match "TypeError|SyntaxError|LintWarning|\((W|E)\d+\)" })
$found | ForEach-Object { $_ -replace "^.*?\\src\\", "src\" }
if ($found.Count -gt 0) {
    Write-Host "TYPES: $($found.Count) finding(s)"
    exit 1
}
Write-Host "TYPES OK"
