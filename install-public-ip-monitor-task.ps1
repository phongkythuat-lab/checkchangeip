param(
    [string]$TaskName = "Public IP Monitor",
    [string]$ChatId = "-5243518839",
    [string]$ScriptPath = "$PSScriptRoot\public-ip-monitor.ps1",
    [string]$StatePath = "$env:ProgramData\PublicIpMonitor\state.json",
    [int]$IntervalMinutes = 5
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ScriptPath)) {
    throw "Script not found: $ScriptPath"
}

$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).Path
$arguments = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$resolvedScript`"",
    "-ChatId", "`"$ChatId`"",
    "-StatePath", "`"$StatePath`""
) -join " "

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Checks this computer's public IP and sends a Telegram message when it changes." `
    -Force | Out-Null

Write-Host "Installed scheduled task: $TaskName"
Write-Host "Interval: every $IntervalMinutes minutes"
Write-Host "Chat ID: $ChatId"
Write-Host "State path: $StatePath"
Write-Host "Token source: TELEGRAM_BOT_TOKEN environment variable"
