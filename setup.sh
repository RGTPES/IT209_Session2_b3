#!/usr/bin/env bash
# ==============================================================================
# Script Triển Khai Nhanh Bài 3 - IT209 (Chạy trên Ubuntu Droplet / Linux Server)
# Đề tài: Bảo mật tài nguyên bằng HTTP Basic Authentication trên Nginx
# ==============================================================================

set -e

echo "=== [BƯỚC 1] Cài đặt công cụ apache2-utils để sinh mật khẩu băm htpasswd ==="
sudo apt-get update -y
sudo apt-get install -y apache2-utils

echo "=== [BƯỚC 2] Chuẩn bị thư mục Web Root: /var/www/my-web/html/ ==="
sudo mkdir -p /var/www/my-web/html/admin

echo "=== [BƯỚC 3] Sao chép tệp tin HTML vào Web Root ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/html/index.html" ]; then
    sudo cp "$SCRIPT_DIR/html/index.html" /var/www/my-web/html/
fi

if [ -f "$SCRIPT_DIR/html/admin/index.html" ]; then
    sudo cp "$SCRIPT_DIR/html/admin/index.html" /var/www/my-web/html/admin/
else
    # Tạo trang admin mặc định nếu chưa có
    sudo bash -c 'cat > /var/www/my-web/html/admin/index.html << "EOF"
<!DOCTYPE html>
<html>
<head><title>Admin Area</title></head>
<body><h1>Restricted Admin Dashboard</h1><p>Authenticated successfully as admin_user.</p></body>
</html>
EOF'
fi

# Thiết lập quyền sở hữu web root cho người dùng www-data
sudo chown -R www-data:www-data /var/www/my-web
sudo chmod -R 755 /var/www/my-web

echo "=== [BƯỚC 4] Thiết lập tệp mật khẩu ẩn .htpasswd tại /etc/nginx/ ==="
if [ -f "$SCRIPT_DIR/.htpasswd" ]; then
    sudo cp "$SCRIPT_DIR/.htpasswd" /etc/nginx/.htpasswd
    echo "Đã sao chép tệp .htpasswd mẫu vào /etc/nginx/.htpasswd"
else
    # Tạo mới với tài khoản admin_user và mật khẩu mặc định Admin@123
    echo "Đang tạo tệp mật khẩu /etc/nginx/.htpasswd mới..."
    sudo htpasswd -cb /etc/nginx/.htpasswd admin_user "Admin@123"
fi

# Thiết lập quyền bảo mật nghiêm ngặt cho file .htpasswd
# Chỉ root sở hữu, group www-data có quyền đọc, các user khác không có quyền
sudo chown root:www-data /etc/nginx/.htpasswd
sudo chmod 640 /etc/nginx/.htpasswd
echo "Đã phân quyền bảo mật 640 cho /etc/nginx/.htpasswd (chống rò rỉ)."

echo "=== [BƯỚC 5] Cấu hình Nginx Server Block ==="
CONFIG_SOURCE=""
if [ -f "$SCRIPT_DIR/nginx/admin.conf" ]; then
    CONFIG_SOURCE="$SCRIPT_DIR/nginx/admin.conf"
elif [ -f "$SCRIPT_DIR/admin.conf" ]; then
    CONFIG_SOURCE="$SCRIPT_DIR/admin.conf"
elif [ -f "$SCRIPT_DIR/nginx/my-web.conf" ]; then
    CONFIG_SOURCE="$SCRIPT_DIR/nginx/my-web.conf"
elif [ -f "$SCRIPT_DIR/my-web.conf" ]; then
    CONFIG_SOURCE="$SCRIPT_DIR/my-web.conf"
fi

if [ -n "$CONFIG_SOURCE" ]; then
    sudo cp "$CONFIG_SOURCE" /etc/nginx/sites-available/my-web.conf
else
    sudo bash -c 'cat > /etc/nginx/sites-available/my-web.conf << "EOF"
server {
    listen 80;
    server_name _;

    root /var/www/my-web/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    location /admin {
        auth_basic "Restricted Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        try_files $uri $uri/ =404;
    }
}
EOF'
fi

# Kích hoạt site trong sites-enabled
sudo ln -sf /etc/nginx/sites-available/my-web.conf /etc/nginx/sites-enabled/my-web.conf

# Vô hiệu hóa default site cũ nếu có xung đột port 80
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
    echo "Đã gỡ bỏ default site cũ để ưu tiên my-web."
fi

echo "=== [BƯỚC 6] Kiểm tra cú pháp Nginx và Tải lại dịch vụ ==="
sudo nginx -t
sudo systemctl reload nginx

echo ""
echo "=========================================================="
echo "    TRIỂN KHAI HOÀN TẤT BÀI 3 THÀNH CÔNG!"
echo "=========================================================="
echo "Kiểm tra bằng curl ngay tại máy chủ:"
echo ""
echo "1. Kiểm tra khi KHÔNG có xác thực (Kỳ vọng: HTTP 401 Unauthorized):"
echo "   curl -I http://localhost/admin"
echo ""
echo "2. Kiểm tra với tài khoản hợp lệ (Kỳ vọng: HTTP 200 OK):"
echo "   curl -u admin_user:Admin@123 http://localhost/admin"
echo ""
echo "3. Kiểm tra từ xa qua IP Droplet:"
echo "   curl -I http://<IP_DROPLET>/admin"
echo "   curl -u admin_user:Admin@123 http://<IP_DROPLET>/admin"
echo "=========================================================="
