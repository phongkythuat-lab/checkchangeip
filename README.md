# checkchangeip

Standalone Windows PowerShell scripts for monitoring a computer's public IP address and sending a Telegram message when it changes.

## Files

- `public-ip-monitor.ps1` checks the current public IP, compares it with local state, and sends Telegram only when the IP changes.
- `install-public-ip-monitor-task.ps1` installs a Windows Task Scheduler job that runs the monitor on a fixed interval.

## Setup

Set the Telegram bot token as an environment variable:

```powershell
setx TELEGRAM_BOT_TOKEN "<your_bot_token>"
$env:TELEGRAM_BOT_TOKEN = "<your_bot_token>"
```

Run the monitor once and send an initial message:

```powershell
.\public-ip-monitor.ps1 -ChatId "-5243518839" -SendInitial
```

Install the scheduled task:

```powershell
.\install-public-ip-monitor-task.ps1 -ChatId "-5243518839" -IntervalMinutes 5
```

The script stores state at:

```text
C:\ProgramData\PublicIpMonitor\state.json
```

Telegram messages are sent only when the public IP changes.
