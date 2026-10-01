# IT209 - Session 2: Bài 3 - Bảo Mật Tài Nguyên Bằng HTTP Basic Authentication

## 1. Mục tiêu bài thực hành
- Cài đặt và sử dụng công cụ băm mật khẩu `htpasswd` (từ gói `apache2-utils`) để bảo vệ một đường dẫn hoặc thư mục nhạy cảm (`/admin`) trên máy chủ Web Nginx.
- Cấu hình Nginx yêu cầu xác thực tài khoản/mật khẩu trực tiếp trên trình duyệt hoặc API client bằng cơ chế **HTTP Basic Authentication**.
- Áp dụng các nguyên tắc bảo mật tệp tin cấu hình và tệp mật khẩu: lưu trữ tệp `.htpasswd` tại `/etc/nginx/`, không đặt trong thư mục web root `/var/www/` để tránh nguy cơ rò rỉ dữ liệu.

---

## 2. Cấu trúc thư mục

```text
Session2_b3/
├── .htpasswd                # Tệp mật khẩu mẫu chứa tài khoản admin_user (đã băm apr1)
├── admin.conf               # Tệp cấu hình Server Block Nginx bảo vệ /admin
├── my-web.conf              # Tệp alias cấu hình Nginx (tương thích các bài trước)
├── html/
│   ├── index.html           # Trang chủ công khai (Public Area)
│   └── admin/
│       └── index.html       # Bảng điều khiển quản trị bảo mật (Restricted Area)
├── nginx/
│   ├── admin.conf           # Tệp cấu hình Nginx cho môi trường container/module
│   └── my-web.conf          # Tệp alias cấu hình Nginx
├── docker-compose.yml       # Tùy chọn kiểm tra nhanh trên Docker
├── setup.sh                 # Script tự động hóa triển khai trên Droplet / Ubuntu
├── test.sh                  # Script kiểm thử tự động trên Linux (curl)
├── test.ps1                 # Script kiểm thử trên Windows PowerShell (curl.exe)
└── README.md                # Báo cáo chi tiết và hướng dẫn bài tập
```

---

## 3. Nội dung cấu hình Nginx Server Block

Tệp cấu hình tại [admin.conf](file:///d:/IT209/Session2_b3/admin.conf) (hoặc [nginx/admin.conf](file:///d:/IT209/Session2_b3/nginx/admin.conf)):

```nginx
server {
    listen 80;
    server_name _;

    # 1. Khai báo thư mục Web Root
    root /var/www/my-web/html;
    index index.html index.htm;

    # 2. Xử lý các request thông thường (Công khai)
    location / {
        try_files $uri $uri/ =404;
    }

    # 3. Bảo vệ khu vực quản trị nội bộ /admin bằng HTTP Basic Authentication
    location /admin {
        auth_basic "Restricted Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        try_files $uri $uri/ =404;
    }
}
```

### Giải thích chi tiết các chỉ thị:
- **`auth_basic "Restricted Admin Area";`**:
  - Kích hoạt module xác thực HTTP Basic Authentication (`ngx_http_auth_basic_module`).
  - Chuỗi `"Restricted Admin Area"` đóng vai trò là **Realm (khu vực xác thực)**, sẽ được gửi về cho client trong tiêu đề `WWW-Authenticate: Basic realm="..."` để hiển thị lời nhắc đăng nhập trên trình duyệt.
- **`auth_basic_user_file /etc/nginx/.htpasswd;`**:
  - Chỉ định đường dẫn tuyệt đối tới tệp chứa danh sách tài khoản và mật khẩu đã băm.
  - Tệp này được đặt an toàn tại `/etc/nginx/.htpasswd`, nằm ngoài phạm vi tài liệu công khai của Web Server (`/var/www/my-web/html/`).
- **`try_files $uri $uri/ =404;`**:
  - Sau khi xác thực thành công, Nginx sẽ tìm kiếm tệp hoặc thư mục tương ứng trong Web Root. Nếu tìm thấy tệp hoặc thư mục index (`/admin/index.html`), Nginx trả về `200 OK`. Nếu không tồn tại, trả về `404 Not Found` (nhưng tuyệt đối không để lộ lỗi 401).

---

## 4. Tệp Mật Khẩu `.htpasswd`

Tệp `.htpasswd` mẫu đã được tạo sẵn trong thư mục bài tập với tài khoản `admin_user` và mật khẩu mẫu:
- **Tài khoản (Username):** `admin_user`
- **Mật khẩu (Password):** `Admin@123`
- **Chuỗi băm trong tệp [.htpasswd](file:///d:/IT209/Session2_b3/.htpasswd):**
  ```text
  admin_user:$apr1$k8J2x9Pq$WaZyDTMJn3Vqs8QDH5kAj.
  ```

---

## 5. Các bước triển khai trên máy chủ (Ubuntu / DigitalOcean Droplet)

### Cách 1: Sử dụng script tự động hóa
Chạy lệnh sau trên thư mục dự án:
```bash
chmod +x setup.sh
./setup.sh
```

---

### Cách 2: Triển khai thủ công từng bước

#### Bước 1: Cài đặt công cụ băm mật khẩu `apache2-utils`
```bash
sudo apt update -y
sudo apt install apache2-utils -y
```

#### Bước 2: Tạo tệp mật khẩu ẩn `.htpasswd` tại `/etc/nginx/`
Sử dụng cờ `-c` để tạo mới tệp (lưu ý: chỉ dùng `-c` cho tài khoản đầu tiên để không ghi đè mất các user cũ):
```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin_user
# Hệ thống sẽ yêu cầu nhập và xác nhận mật khẩu cho admin_user (ví dụ: Admin@123)
```

**Thiết lập quyền bảo mật an toàn cho file mật khẩu:**
```bash
# Phân quyền: chỉ root sở hữu, nhóm www-data được phép đọc, người ngoài không có quyền
sudo chown root:www-data /etc/nginx/.htpasswd
sudo chmod 640 /etc/nginx/.htpasswd
```

#### Bước 3: Chuẩn bị thư mục Web Root và mã nguồn HTML
```bash
# Tạo cấu trúc thư mục
sudo mkdir -p /var/www/my-web/html/admin

# Sao chép các tệp tin HTML từ bài tập
sudo cp html/index.html /var/www/my-web/html/
sudo cp html/admin/index.html /var/www/my-web/html/admin/

# Phân quyền cho tiến trình Nginx
sudo chown -R www-data:www-data /var/www/my-web
sudo chmod -R 755 /var/www/my-web
```

#### Bước 4: Thiết lập cấu hình Nginx Server Block
```bash
# Sao chép cấu hình vào sites-available
sudo cp admin.conf /etc/nginx/sites-available/my-web.conf

# Tạo liên kết tượng trưng (symlink) sang sites-enabled
sudo ln -sf /etc/nginx/sites-available/my-web.conf /etc/nginx/sites-enabled/my-web.conf

# (Tùy chọn) Gỡ bỏ default site cũ nếu có xung đột port 80:
sudo rm -f /etc/nginx/sites-enabled/default
```

#### Bước 5: Kiểm tra cú pháp và kích hoạt cấu hình
```bash
# Kiểm tra tính hợp lệ của cấu hình Nginx
sudo nginx -t

# Tải lại cấu hình Nginx mà không làm gián đoạn dịch vụ
sudo systemctl reload nginx
```

---

## 6. Kiểm tra kết quả (Testing)

### Lệnh 1: Gửi request thông thường tới `/admin` (chưa xác thực)
```bash
curl -I http://<IP_ADDRESS_DROPLET>/admin
```
**Kết quả mong đợi:**
- Trả về mã trạng thái: **`HTTP/1.1 401 Unauthorized`**
- Xuất hiện tiêu đề: **`WWW-Authenticate: Basic realm="Restricted Admin Area"`**
- Trình duyệt sẽ tự động bật hộp thoại nhập Username và Password.

```http
HTTP/1.1 401 Unauthorized
Server: nginx/...
Date: ...
Content-Type: text/html
Content-Length: ...
Connection: keep-alive
WWW-Authenticate: Basic realm="Restricted Admin Area"
```

---

### Lệnh 2: Gửi request kèm mật khẩu SAI
```bash
curl -I -u admin_user:WrongPassword http://<IP_ADDRESS_DROPLET>/admin
```
**Kết quả mong đợi:**
- Máy chủ từ chối và tiếp tục trả về **`HTTP/1.1 401 Unauthorized`**.

---

### Lệnh 3: Gửi request kèm tài khoản và mật khẩu ĐÚNG
```bash
curl -I -u admin_user:Admin@123 http://<IP_ADDRESS_DROPLET>/admin
```
*(Hoặc truy cập trực tiếp bằng `curl -u admin_user:Admin@123 http://<IP_ADDRESS_DROPLET>/admin` để nhận toàn bộ nội dung HTML)*

**Kết quả mong đợi:**
- Trả về mã trạng thái: **`HTTP/1.1 200 OK`** (hoặc `301 Moved Permanently` điều hướng sang `/admin/` sau đó trả về `200 OK`).
- Tuyệt đối **không trả về 401**.

```http
HTTP/1.1 200 OK
Server: nginx/...
Date: ...
Content-Type: text/html
Content-Length: ...
Connection: keep-alive
```

---

## 7. Các Lưu Ý Bảo Mật Quan Trọng

1. **Vị trí lưu trữ `.htpasswd`**:
   - Tệp `.htpasswd` **bắt buộc** phải được lưu trữ tại `/etc/nginx/.htpasswd` (hoặc các thư mục hệ thống bên ngoài web root).
   - Tuyệt đối **không** lưu tệp `.htpasswd` trong `/var/www/my-web/html/`. Nếu đặt trong web root mà quên cấu hình chặn truy cập file ẩn (`.*`), kẻ tấn công có thể tải trực tiếp file `http://domain.com/.htpasswd` về máy để bẻ khóa (offline brute-force/dictionary attack).

2. **Phân quyền tệp (File Permissions)**:
   - File mật khẩu cần được gán quyền `640` (`rw-r-----`) với quyền sở hữu `root:www-data`. Điều này đảm bảo Nginx worker process (chạy dưới user `www-data`) có quyền đọc để kiểm tra mật khẩu, trong khi các user khác trên hệ thống không thể đọc nội dung file.

3. **Giao thức truyền tải (HTTP vs HTTPS)**:
   - Cơ chế HTTP Basic Authentication mã hóa chuỗi thông tin đăng nhập `username:password` dưới dạng **Base64** trong header `Authorization: Basic ...`.
   - **Base64 không phải là mã hóa bảo mật** mà chỉ là cơ chế encoding, bất kỳ ai bắt được gói tin qua mạng (Man-in-the-Middle) đều có thể giải mã ra mật khẩu gốc ngay lập tức.
   - Do đó, trong môi trường Production thực tế, HTTP Basic Authentication **luôn phải đi kèm giao thức HTTPS (SSL/TLS)** để mã hóa toàn bộ đường truyền.
