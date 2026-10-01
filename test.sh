#!/usr/bin/env bash
# ==============================================================================
# Script Kiểm Thử Tự Động Bài 3 - HTTP Basic Authentication trên Nginx
# ==============================================================================

TARGET_HOST="${1:-localhost}"
USERNAME="admin_user"
PASSWORD="Admin@123"

echo "=========================================================="
echo "    BẮT ĐẦU KIỂM THỬ HTTP BASIC AUTHENTICATION"
echo "    Target Host: $TARGET_HOST"
echo "=========================================================="
echo ""

# Test 1: Truy cập trang chủ công khai (không cần mật khẩu)
echo "--- [TEST 1] Truy cập trang chủ công khai: http://$TARGET_HOST/ ---"
STATUS_HOME=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET_HOST/")
echo "HTTP Status Code: $STATUS_HOME"
if [ "$STATUS_HOME" == "200" ]; then
    echo "=> [PASS] Trang chủ truy cập công khai bình thường (200 OK)."
else
    echo "=> [INFO] Trả về mã $STATUS_HOME."
fi
echo ""

# Test 2: Truy cập /admin mà KHÔNG gửi kèm thông tin đăng nhập
echo "--- [TEST 2] Truy cập /admin không xác thực ---"
echo "Lệnh: curl -i http://$TARGET_HOST/admin"
RESPONSE_NO_AUTH=$(curl -i -s "http://$TARGET_HOST/admin")
STATUS_NO_AUTH=$(echo "$RESPONSE_NO_AUTH" | grep -i "^HTTP" | tail -n 1 | awk '{print $2}')
WWW_AUTH_HEADER=$(echo "$RESPONSE_NO_AUTH" | grep -i "^WWW-Authenticate:")

echo "HTTP Status Code: $STATUS_NO_AUTH"
echo "Header kiểm tra: $WWW_AUTH_HEADER"

if [ "$STATUS_NO_AUTH" == "401" ] && [ -n "$WWW_AUTH_HEADER" ]; then
    echo "=> [PASS] Đạt chuẩn! Máy chủ từ chối với mã 401 Unauthorized và có WWW-Authenticate header."
else
    echo "=> [FAIL] Kỳ vọng HTTP 401 và có header WWW-Authenticate nhưng nhận được: $STATUS_NO_AUTH"
fi
echo ""

# Test 3: Truy cập /admin với sai thông tin xác thực
echo "--- [TEST 3] Truy cập /admin với mật khẩu SAI ---"
echo "Lệnh: curl -i -u admin_user:WrongPass http://$TARGET_HOST/admin"
STATUS_WRONG=$(curl -s -o /dev/null -w "%{http_code}" -u "admin_user:WrongPass" "http://$TARGET_HOST/admin")
echo "HTTP Status Code: $STATUS_WRONG"

if [ "$STATUS_WRONG" == "401" ]; then
    echo "=> [PASS] Đạt chuẩn! Đăng nhập sai bị từ chối với mã 401 Unauthorized."
else
    echo "=> [FAIL] Kỳ vọng mã 401 nhưng nhận được: $STATUS_WRONG"
fi
echo ""

# Test 4: Truy cập /admin với thông tin xác thực ĐÚNG
echo "--- [TEST 4] Truy cập /admin với tài khoản và mật khẩu ĐÚNG ---"
echo "Lệnh: curl -i -u $USERNAME:$PASSWORD http://$TARGET_HOST/admin"
RESPONSE_AUTH=$(curl -i -s -u "$USERNAME:$PASSWORD" "http://$TARGET_HOST/admin")
STATUS_AUTH=$(echo "$RESPONSE_AUTH" | grep -i "^HTTP" | tail -n 1 | awk '{print $2}')

echo "HTTP Status Code: $STATUS_AUTH"

if [ "$STATUS_AUTH" == "200" ] || [ "$STATUS_AUTH" == "301" ]; then
    echo "=> [PASS] Đạt chuẩn! Đăng nhập thành công, nhận mã $STATUS_AUTH (Được cấp quyền truy cập)."
else
    echo "=> [WARNING] Nhận mã $STATUS_AUTH (nếu là 404 thì do chưa có index.html trong /admin, nhưng không được là 401)."
fi
echo ""

echo "=========================================================="
echo "    KẾT THÚC KIỂM THỬ"
echo "=========================================================="
