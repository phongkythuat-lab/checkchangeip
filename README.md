# Giám sát Thay đổi IP Công cộng qua Telegram (checkchangeip)

Dự án này cung cấp các kịch bản PowerShell chạy ngầm trên hệ điều hành Windows để tự động theo dõi địa chỉ IP công cộng (Public IP) của máy tính và gửi thông báo qua nhóm Telegram khi phát hiện có sự thay đổi.

---

## ⚡ Hướng dẫn Cài đặt Nhanh (Chỉ 1 Dòng lệnh)

Để cài đặt dự án này lên bất kỳ máy tính Windows nào, bạn chỉ cần thực hiện 2 bước đơn giản dưới đây:

### Bước 1: Mở PowerShell (Admin)
Nhấp chuột phải vào nút Start hoặc bấm phím `Windows + X` và chọn **Windows PowerShell (Admin)** hoặc **Terminal (Admin)**.

### Bước 2: Dán dòng lệnh cài đặt và chạy
Sao chép dòng lệnh bên dưới, dán vào cửa sổ PowerShell rồi nhấn **Enter**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/phongkythuat-lab/checkchangeip/main/setup.ps1 | iex
```

### Bước 3: Nhập thông tin cấu hình theo hướng dẫn trên màn hình
Bộ cài đặt sẽ tự động hỏi bạn các thông tin sau:
1. **Telegram Bot Token** (Bắt buộc).
2. **Telegram Chat ID** (Mặc định: `-5243518839`, chỉ cần ấn Enter để chọn mặc định).
3. **Tên Wi-Fi được phép giám sát** (Tùy chọn, ví dụ: `Wifi_Van_Phong,Wifi_Nha_Rieng`. Nếu cài trên Laptop, bạn có thể điền vào đây để script chỉ hoạt động khi kết nối các mạng này, tránh tự kích hoạt khi mang đi nơi khác. Để trống nếu muốn chạy trên mọi kết nối).
4. **Chu kỳ kiểm tra IP** (phút, mặc định: 5 phút, ấn Enter để chọn mặc định).

*Sau khi nhập xong, bộ cài đặt sẽ tự động tải các tệp tin cần thiết từ GitHub, tạo biến môi trường, đăng ký Scheduled Task chạy ngầm trên Windows, và chạy kiểm thử gửi tin nhắn kích hoạt đầu tiên tới Telegram của bạn.*

---

## 🛠️ Hướng dẫn Quản lý & Gỡ cài đặt

### 1. Gỡ cài đặt hoàn toàn
Nếu bạn không muốn giám sát IP nữa và muốn xóa sạch cấu hình khỏi máy tính, hãy mở PowerShell (Admin) và chạy lệnh sau:

```powershell
# Xóa Task Scheduler chạy ngầm
Unregister-ScheduledTask -TaskName "Public IP Monitor" -Confirm:$false

# Xóa thư mục chứa script và file lưu trạng thái cũ
Remove-Item -Path "C:\ProgramData\PublicIpMonitor" -Recurse -Force -ErrorAction SilentlyContinue
```

### 2. File Trạng thái và Cách chỉnh sửa
* **Vị trí cài đặt**: Dự án tự động cài các tệp tin vào thư mục hệ thống:
  ```text
  C:\ProgramData\PublicIpMonitor\
  ```
* **File trạng thái (state.json)**: Lưu trữ địa chỉ IP cuối cùng được ghi nhận, vị trí tại:
  ```text
  C:\ProgramData\PublicIpMonitor\state.json
  ```
  Nếu muốn ép hệ thống chạy kiểm tra lại ngay lập tức hoặc thử nghiệm đổi IP, bạn có thể xóa file `state.json` này đi.
