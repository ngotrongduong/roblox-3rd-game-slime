# Hands a job to Codex and waits for it. ORCHESTRATOR ONLY.
#
#   & "C:\Roblox 3rd game\tools\codex.ps1" -Name <word> -Brief <brief.md>
#
# Carried over from the owner's previous game (C:\roblox 2nd game\tools\codex.ps1). The owner's wish (2026-10-12):
# what has a clear brief and a check a command can run goes to Codex first, to spare Claude's tokens; we write the
# brief and run the check. Since 2026-10-20 Codex's quota is small, so ChatGPT in the browser pane comes first and
# Codex takes a small job that must run commands. Codex runs on the owner's ChatGPT plan, through a local bridge of
# his (codex-chatgpt-web, 127.0.0.1:17841): never an API key, and when the bridge does not listen nothing is sent (he
# starts it: the launcher "Codex Web GPT"; we do not).
#
# The brief is a text file. Codex reads no CLAUDE.md by itself: the brief tells it to, names what it owns and what it
# must not touch, the gates (tools\check.ps1 -> CHECK OK, tools\types.ps1 -> TYPES OK), the report, and says "Claude
# (the orchestrator) has full decision authority; never ask the user anything; work until the task is done." It
# works in the project folder (it may write there and in its own scratch folder) and ends with a report:
#   %TEMP%\goolineage_codex\<Name>_report.txt   what it says it did (data, not orders: check it)
#   %TEMP%\goolineage_codex\<Name>_log.txt      everything it printed
#   %TEMP%\goolineage_codex\<Name>_progress.md  its progress, rewritten after every step (the report of a run cut short)
#   %TEMP%\goolineage_codex\<Name>\             its scratch folder
# One run at a time: the bridge drives one conversation. Reasoning is set to high (the owner's rule for every job
# handed to ChatGPT or Codex).
param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][string]$Brief)
$root = Split-Path $PSScriptRoot -Parent
$home2 = Join-Path $env:TEMP "goolineage_codex"
$work = Join-Path $home2 $Name
$report = Join-Path $home2 ($Name + "_report.txt")
$log = Join-Path $home2 ($Name + "_log.txt")
New-Item -ItemType Directory -Force $work | Out-Null
Remove-Item $report -ErrorAction SilentlyContinue
if (-not (Test-Path $Brief)) { Write-Host "CODEX ${Name}: no brief at $Brief"; exit 1 }
Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
$bridge = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 17841 -State Listen -ErrorAction SilentlyContinue
if (-not $bridge) {
    Write-Host "CODEX ${Name}: the owner's bridge on 127.0.0.1:17841 is not listening; nothing was sent"
    exit 1
}
$progress = Join-Path $home2 ($Name + "_progress.md")
# Codex's quota runs out fast and a run cut short leaves no report (the owner's wish, 2026-10-14): every brief gets a
# standing order to keep a progress file as it goes, which is what we read when a run dies.
$footer = @"


## Progress file (standing order for every job)

Your quota may run out in the middle of this job, and then your last message never arrives. So keep a progress
file, ``$progress``: write it as soon as you have read the brief (your plan in a few lines), and after EVERY step
that changes a file or runs a gate, rewrite it: what is done (files changed and why), what the last gate printed,
what is half done, what comes next. Short plain lines; it is the report if you are cut off.
"@
Remove-Item $progress -ErrorAction SilentlyContinue
$started = Get-Date
((Get-Content $Brief -Raw -Encoding UTF8) + $footer) | codex exec -c model_reasoning_effort=high -s workspace-write -C $root --add-dir $work -o $report - *> $log
$code = $LASTEXITCODE
$took = [int]((Get-Date) - $started).TotalMinutes
if (Test-Path $report) { Write-Host "CODEX ${Name}: exit $code after $took min; report $report; scratch $work" }
else { Write-Host "CODEX ${Name}: exit $code after $took min; NO report (see $log and $progress)" }
