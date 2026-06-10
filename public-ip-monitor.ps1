param(
    [string]$ChatId = "-5243518839",
    [string]$BotToken = $env:TELEGRAM_BOT_TOKEN,
    [string]$StatePath = "$env:ProgramData\PublicIpMonitor\state.json",
    [string[]]$AllowedSSID,
    [switch]$SendInitial
)

$ErrorActionPreference = "Stop"

function Get-PublicIp {
    $services = @(
        "https://api.ipify.org",
        "https://ifconfig.me/ip",
        "https://icanhazip.com"
    )

    foreach ($service in $services) {
        try {
            $ip = (Invoke-RestMethod -Uri $service -TimeoutSec 15).ToString().Trim()
            if ($ip -match '^(?:\d{1,3}\.){3}\d{1,3}$|^[0-9a-fA-F:]+$') {
                return $ip
            }
        }
        catch {
            continue
        }
    }

    throw "Could not resolve public IP from any configured service."
}

function Send-TelegramMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$TargetChatId,
        [Parameter(Mandatory = $true)][string]$Text
    )

    Invoke-RestMethod `
        -Method Post `
        -Uri "https://api.telegram.org/bot$Token/sendMessage" `
        -Body @{
            chat_id = $TargetChatId
            text = $Text
            disable_web_page_preview = "true"
        } `
        -TimeoutSec 20 | Out-Null
}

if ([string]::IsNullOrWhiteSpace($BotToken)) {
    throw "Missing bot token. Set TELEGRAM_BOT_TOKEN or pass -BotToken."
}

if ($AllowedSSID) {
    $allowedList = @()
    foreach ($item in $AllowedSSID) {
        if ($item -like "*,*") {
            $allowedList += $item -split ","
        }
        else {
            $allowedList += $item
        }
    }
    $allowedList = $allowedList | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    $currentSsid = $null
    try {
        $oldEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $wlanInfo = netsh wlan show interfaces
        [Console]::OutputEncoding = $oldEncoding
        foreach ($line in $wlanInfo) {
            if ($line -match '^\s*SSID\s*:\s*(.*)$') {
                $currentSsid = $Matches[1].Trim()
                break
            }
        }
    }
    catch {
        # Netsh failed or interface not found
    }

    if ([string]::IsNullOrWhiteSpace($currentSsid) -or $currentSsid -notin $allowedList) {
        Write-Host "Current Wi-Fi SSID '$currentSsid' is not in the allowed SSIDs list. Exiting."
        exit 0
    }
}

$currentIp = Get-PublicIp
$stateDir = Split-Path -Parent $StatePath
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
}

$previousIp = $null
if (Test-Path $StatePath) {
    try {
        $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        $previousIp = $state.ip
    }
    catch {
        $previousIp = $null
    }
}

$changed = -not [string]::IsNullOrWhiteSpace($previousIp) -and $previousIp -ne $currentIp
$firstRun = [string]::IsNullOrWhiteSpace($previousIp)

if ($changed) {
    Send-TelegramMessage `
        -Token $BotToken `
        -TargetChatId $ChatId `
        -Text "Public IP changed on $env:COMPUTERNAME: $previousIp -> $currentIp"
}
elseif ($firstRun -and $SendInitial) {
    Send-TelegramMessage `
        -Token $BotToken `
        -TargetChatId $ChatId `
        -Text "Public IP monitor started on $env:COMPUTERNAME: $currentIp"
}

@{
    ip = $currentIp
    checkedAt = (Get-Date).ToString("o")
    computerName = $env:COMPUTERNAME
} | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding UTF8

Write-Host "Current public IP: $currentIp"
if ($changed) {
    Write-Host "Changed from: $previousIp"
}
elseif ($firstRun) {
    Write-Host "First run. State saved."
}
else {
    Write-Host "No change."
}
