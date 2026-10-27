# The path of a tool that Rokit installed, read from rokit.toml, so that a tool update means editing
# rokit.toml and nothing else. Dot-source it, then ask:
#   . (Join-Path $PSScriptRoot "rokit_paths.ps1")
#   $rojo = Get-RokitTool "rojo"          # ...\tool-storage\rojo-rbx\rojo\7.7.0\rojo.exe
# A tool is a line of [tools] in rokit.toml: name = "owner/repo@version". Rokit stores it under
# tool-storage\<owner>\<repo>\<version>\<name>.exe, owner and repo in lower case.
function Get-RokitTool {
    param([Parameter(Mandatory = $true)][string]$Name)

    $toml = Join-Path (Split-Path -Parent $PSScriptRoot) "rokit.toml"
    if (-not (Test-Path $toml)) {
        throw "rokit.toml not found at $toml"
    }
    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*=\s*"([^"/@]+)/([^"/@]+)@([^"]+)"'
    foreach ($line in Get-Content $toml) {
        if ($line -match $pattern) {
            $store = Join-Path $env:USERPROFILE ".rokit\tool-storage"
            $folder = Join-Path (Join-Path (Join-Path $store $Matches[1].ToLower()) $Matches[2].ToLower()) $Matches[3]
            $exe = Join-Path $folder "$Name.exe"
            if (-not (Test-Path $exe)) {
                throw "$Name $($Matches[3]) is in rokit.toml but not installed at $exe (run: rokit install)"
            }
            return $exe
        }
    }
    throw "tool '$Name' is not in $toml"
}
