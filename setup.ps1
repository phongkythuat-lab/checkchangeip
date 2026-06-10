# Bộ cài đặt tự động Giám sát IP Công cộng qua Telegram
$ErrorActionPreference = "Stop"

# Kiểm tra quyền Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "LỖI: Bạn phải chạy PowerShell dưới quyền Administrator (Run as Administrator) để cài đặt!" -ForegroundColor Red
    Write-Host "Vui lòng mở lại PowerShell (Admin) và thực hiện lại lệnh." -ForegroundColor Yellow
    exit 1
}

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "     BỘ CÀI ĐẶT TỰ ĐỘNG GIÁM SÁT IP CÔNG CỘNG         " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Nhập Token Telegram
$BotToken = ""
while ([string]::IsNullOrWhiteSpace($BotToken)) {
    $BotToken = Read-Host "1. Nhập Telegram Bot Token (Bắt buộc)"
    $BotToken = $BotToken.Trim()
    if ([string]::IsNullOrWhiteSpace($BotToken)) {
        Write-Host "Lỗi: Token không được để trống!" -ForegroundColor Red
    }
}

# 2. Nhập Chat ID
$ChatId = Read-Host "2. Nhập Telegram Chat ID (Mặc định: -5243518839)"
$ChatId = $ChatId.Trim()
if ([string]::IsNullOrWhiteSpace($ChatId)) {
    $ChatId = "-5243518839"
}

# 3. Nhập Wi-Fi cho phép
$AllowedSSID = Read-Host "3. Chỉ chạy khi kết nối Wi-Fi chỉ định? (Nhập tên Wi-Fi, ví dụ: Wifi_Van_Phong,Wifi_Nha_Rieng. Bỏ trống nếu giám sát mọi kết nối)"
$AllowedSSID = $AllowedSSID.Trim()

# 4. Nhập chu kỳ kiểm tra
$IntervalInput = Read-Host "4. Chu kỳ kiểm tra IP (phút, Mặc định: 5)"
$IntervalInput = $IntervalInput.Trim()
$IntervalMinutes = 5
if (-not [string]::IsNullOrWhiteSpace($IntervalInput)) {
    if ([int]::TryParse($IntervalInput, [ref]$IntervalMinutes)) {
        if ($IntervalMinutes -lt 1) { $IntervalMinutes = 1 }
    } else {
        $IntervalMinutes = 5
    }
}

Write-Host ""
Write-Host "Đang chuẩn bị cài đặt..." -ForegroundColor Yellow

# Định nghĩa các thư mục cài đặt
$InstallDir = "C:\ProgramData\PublicIpMonitor"
$ScriptPath = "$InstallDir\public-ip-monitor.ps1"
$StatePath = "$InstallDir\state.json"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# Tải script chính từ GitHub
$RawScriptUrl = "https://raw.githubusercontent.com/phongkythuat-lab/checkchangeip/main/public-ip-monitor.ps1"
Write-Host "Đang tải mã nguồn từ GitHub..." -ForegroundColor Yellow

try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $RawScriptUrl -OutFile $ScriptPath -UseBasicParsing | Out-Null
}
catch {
    Write-Host "LỖI: Không thể kết nối với GitHub để tải file script. Vui lòng kiểm tra lại mạng Internet!" -ForegroundColor Red
    Write-Host "Chi tiết lỗi: $_" -ForegroundColor DarkRed
    exit 1
}

# Thiết lập biến môi trường hệ thống
Write-Host "Đang lưu cấu hình Token Telegram..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("TELEGRAM_BOT_TOKEN", $BotToken, "User")
$env:TELEGRAM_BOT_TOKEN = $BotToken

# Đăng ký Scheduled Task
Write-Host "Đang đăng ký Task chạy ngầm trong Task Scheduler..." -ForegroundColor Yellow

$argumentsList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$ScriptPath`"",
    "-ChatId", "`"$ChatId`"",
    "-StatePath", "`"$StatePath`""
)
if (-not [string]::IsNullOrWhiteSpace($AllowedSSID)) {
    $argumentsList += "-AllowedSSID", "`"$AllowedSSID`""
}
$arguments = $argumentsList -join " "

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "Public IP Monitor" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Checks this computer's public IP and sends a Telegram message when it changes." `
    -Force | Out-Null

Write-Host ""
Write-Host "-----------------------------------------------------" -ForegroundColor Green
Write-Host "CÀI ĐẶT THÀNH CÔNG!" -ForegroundColor Green
Write-Host "  - Thư mục chương trình: $InstallDir" -ForegroundColor Green
Write-Host "  - Tác vụ tự động: Public IP Monitor (Chạy mỗi $IntervalMinutes phút)" -ForegroundColor Green
if (-not [string]::IsNullOrWhiteSpace($AllowedSSID)) {
    Write-Host "  - Wi-Fi được cho phép: $AllowedSSID" -ForegroundColor Green
}
Write-Host "-----------------------------------------------------" -ForegroundColor Green
Write-Host ""

# Chạy thử lần đầu để ghi nhận IP và gửi tin nhắn kích hoạt
Write-Host "Đang chạy thử lần đầu tiên để kích hoạt tin nhắn về nhóm Telegram..." -ForegroundColor Yellow
$testParams = @{
    BotToken = $BotToken
    ChatId = $ChatId
    StatePath = $StatePath
    SendInitial = $true
}
if (-not [string]::IsNullOrWhiteSpace($AllowedSSID)) {
    $testParams.AllowedSSID = $AllowedSSID
}

& $ScriptPath @testParams

Write-Host ""
Write-Host "HOÀN TẤT: Vui lòng kiểm tra nhóm Telegram xem đã nhận được tin nhắn khởi tạo chưa!" -ForegroundColor Green
