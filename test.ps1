param (
    [string]$TargetHost = "localhost"
)

$Username = "admin_user"
$Password = "Admin@123"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    BẮT ĐẦU KIỂM THỬ HTTP BASIC AUTHENTICATION (PowerShell)" -ForegroundColor Cyan
Write-Host "    Target Host: $TargetHost" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Không xác thực
Write-Host "--- [TEST 1] Truy cập /admin không xác thực ---" -ForegroundColor Yellow
$test1Cmd = "curl.exe -i -s http://$TargetHost/admin"
Write-Host "Lệnh: $test1Cmd"
$res1 = Invoke-Expression $test1Cmd
$res1Text = $res1 -join "`n"
Write-Host $res1Text

if ($res1Text -match "HTTP/.* 401" -and $res1Text -match "WWW-Authenticate") {
    Write-Host "=> [PASS] Đạt yêu cầu: Trả về HTTP 401 Unauthorized và có WWW-Authenticate header!`n" -ForegroundColor Green
} else {
    Write-Host "=> [FAIL] Chưa đạt yêu cầu test 1.`n" -ForegroundColor Red
}

# Test 2: Xác thực đúng
Write-Host "--- [TEST 2] Truy cập /admin với tài khoản hợp lệ ---" -ForegroundColor Yellow
$test2Cmd = "curl.exe -i -s -u ${Username}:${Password} http://$TargetHost/admin"
Write-Host "Lệnh: $test2Cmd"
$res2 = Invoke-Expression $test2Cmd
$res2Text = $res2 -join "`n"
Write-Host $res2Text

if ($res2Text -match "HTTP/.* 200" -or $res2Text -match "HTTP/.* 301") {
    Write-Host "=> [PASS] Đạt yêu cầu: Xác thực thành công (HTTP 200 OK / 301 Redirect)!`n" -ForegroundColor Green
} elseif ($res2Text -match "HTTP/.* 401") {
    Write-Host "=> [FAIL] Vẫn bị mã 401 Unauthorized dù đã gửi thông tin đăng nhập đúng!`n" -ForegroundColor Red
} else {
    Write-Host "=> [INFO] Mã trạng thái phản hồi hợp lệ (không phải 401).`n" -ForegroundColor Yellow
}
