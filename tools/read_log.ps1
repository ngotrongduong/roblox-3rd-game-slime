# Prints the game's own lines and any script warning/error from the newest
# Studio log (the last play test). Run from anywhere:
#   & "C:\Roblox 3rd game\tools\read_log.ps1"
#   & "C:\Roblox 3rd game\tools\read_log.ps1" 200     (more lines)
# (carried over from the owner's previous game, C:\roblox 2nd game\tools\read_log.ps1)
param([int]$Last = 60)

$log = Get-ChildItem "$env:LOCALAPPDATA\Roblox\logs" -Filter "*Studio*last.log" |
    Sort-Object CreationTime -Descending | Select-Object -First 1
if (-not $log) {
    Write-Host "no Studio log found"
    exit 1
}
Write-Host "$($log.Name)  (created $($log.CreationTime))"
Get-Content $log.FullName |
    Where-Object { $_ -match "\[GooLineage\]" -or $_ -match "(Warning|Error) \[FLog::Creator(Output|Error)\]" -or $_ -match "Info: (Stack Begin|Script ')" } |
    ForEach-Object { $_ -replace "^[^\]]*\] ", "" } |
    Select-Object -Last $Last
