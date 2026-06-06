# Giám sát Thay đổi IP Công cộng qua Telegram (checkchangeip)

Dự án này cung cấp các kịch bản (script) PowerShell chạy độc lập trên hệ điều hành Windows để theo dõi địa chỉ IP công cộng (Public IP) của máy tính và gửi thông báo tự động qua nhóm Telegram khi phát hiện có sự thay đổi.

---

## 📋 Yêu cầu hệ thống & Chuẩn bị
1. **Hệ điều hành**: Windows (đã cài đặt sẵn PowerShell).
2. **Quyền hạn**: Quyền Administrator (để cài đặt Scheduled Task tự động chạy ngầm).
3. **Thông tin Telegram**:
   * **Bot Token**: Mã token của Telegram Bot điều khiển việc gửi tin nhắn.
   * **Chat ID**: ID của phòng chat hoặc nhóm Telegram muốn nhận thông báo (ví dụ: `-5243518839`).

---

## 🚀 Hướng dẫn cài đặt và sử dụng (Từng bước)

### Bước 1: Tải bộ mã nguồn về máy tính cần cài đặt
Mở PowerShell dưới quyền **Administrator** (Run as Administrator) và chạy các lệnh dưới đây để tải mã nguồn hoặc clone repository:

```powershell
# Chuyển đến thư mục muốn lưu trữ (ví dụ C:\)
cd C:\

# Clone repository từ GitHub
git clone https://github.com/phongkythuat-lab/checkchangeip.git

# Chuyển vào thư mục chứa script
cd C:\checkchangeip
```

*(Nếu máy chưa cài Git, bạn có thể tải file ZIP trực tiếp từ địa chỉ GitHub [https://github.com/phongkythuat-lab/checkchangeip](https://github.com/phongkythuat-lab/checkchangeip), giải nén ra một thư mục cố định).*

---

### Bước 2: Thiết lập Token Telegram (TELEGRAM_BOT_TOKEN)
Để các script có quyền gửi tin nhắn, bạn cần cấu hình biến môi trường hệ thống. Chạy các dòng lệnh sau trong PowerShell để thiết lập:

```powershell
# Thiết lập biến môi trường vĩnh viễn cấp độ User
[Environment]::SetEnvironmentVariable("TELEGRAM_BOT_TOKEN", "8031789825:AAFGgjjcnFVf4sGxS-uHzNkjSCziTdAyicU", "User")

# Đồng thời áp dụng ngay cho phiên PowerShell hiện tại
$env:TELEGRAM_BOT_TOKEN = "8031789825:AAFGgjjcnFVf4sGxS-uHzNkjSCziTdAyicU"
```
*(Hãy thay đổi chuỗi token `"8031789825:AAFGgjjcnFVf4sGxS-uHzNkjSCziTdAyicU"` bằng Token Bot của riêng bạn nếu cần).*

---

### Bước 3: Chạy kiểm tra thử (Test) lần đầu tiên
Bạn hãy kiểm tra xem kịch bản có gửi tin nhắn được về Telegram nhóm hay không bằng lệnh sau:

```powershell
# Chạy script giám sát lần đầu và yêu cầu gửi tin nhắn thông báo kích hoạt thành công
.\public-ip-monitor.ps1 -ChatId "-5243518839" -SendInitial
```

* **Kết quả dự kiến**: Bạn sẽ nhận được tin nhắn trên Telegram dạng: `Public IP monitor started on [TÊN_MÁY]: [IP_hiện_tại]`. Đồng thời hệ thống sẽ tạo file trạng thái lưu IP hiện tại.

---

### Bước 4: Thiết lập tự động chạy ngầm (Scheduled Task)
Để kịch bản tự động kiểm tra mỗi 5 phút một lần mà không cần mở PowerShell, hãy chạy công cụ cài đặt tự động Task Scheduler đi kèm:

```powershell
# Cài đặt Scheduled Task chạy ngầm chu kỳ mỗi 5 phút
.\install-public-ip-monitor-task.ps1 -ChatId "-5243518839" -IntervalMinutes 5
```

* **Quy trình hoạt động**: Tác vụ này sẽ chạy hoàn toàn ẩn dưới nền Windows. Mỗi lần chạy, nó sẽ tự động so sánh IP thực tế lúc đó với IP cũ lưu trong file trạng thái. Nếu IP bị thay đổi, nó sẽ lập tức bắn tin nhắn cảnh báo về Telegram.

---

## 🛠️ Thông tin kỹ thuật & Khắc phục sự cố

* **Vị trí lưu File Trạng thái**: IP cũ được lưu tại đường dẫn:
  ```text
  C:\ProgramData\PublicIpMonitor\state.json
  ```
  Nếu muốn ép hệ thống gửi lại thông báo kiểm tra ngay lập tức, bạn chỉ cần xóa file `state.json` này đi và chạy lại bước 3 hoặc chạy Scheduled Task.
  
* **Xem danh sách Task đang chạy**: Để kiểm tra xem Task đã được đăng ký thành công chưa, chạy lệnh:
  ```powershell
  Get-ScheduledTask -TaskName "Public IP Monitor"
  ```

* **Kiểm tra Log lỗi**: Nếu script không chạy được, hãy kiểm tra kết nối mạng hoặc đảm bảo PowerShell cho phép chạy script bằng lệnh:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  ```
