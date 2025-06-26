# Script untuk memperbarui semua referensi Firebase Database ke Asia Southeast
# Mengatasi error: Database lives in a different region

Write-Host "🔥 Memperbarui Firebase Database ke Region Asia Southeast" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Yellow

Write-Host ""
Write-Host "🌏 Problem: Database lives in a different region" -ForegroundColor Red
Write-Host "✅ Solution: Menggunakan URL eksplisit Asia Southeast di semua file" -ForegroundColor Green
Write-Host ""

$asiaUrl = "https://umrahtrack-hazz-default-rtdb.asia-southeast1.firebasedatabase.app"

Write-Host "📋 Files yang telah diperbarui:" -ForegroundColor Cyan
Write-Host "  ✅ firebase_options.dart - Semua platform menggunakan Asia Southeast URL" -ForegroundColor Green
Write-Host "  ✅ location_service.dart - Database menggunakan eksplisit Asia Southeast URL" -ForegroundColor Green
Write-Host "  ✅ lokasi_person.dart - Admin page menggunakan eksplisit Asia Southeast URL" -ForegroundColor Green
Write-Host ""

Write-Host "📝 Files yang masih perlu diperbarui:" -ForegroundColor Yellow

$filesToUpdate = @(
    "lib\test_location_debug.dart",
    "lib\simple_firebase_test.dart", 
    "lib\location_diagnostic_page.dart",
    "lib\quick_rtdb_test.dart",
    "lib\emergency_rtdb_test.dart",
    "lib\test_location_realtime_verification.dart",
    "lib\test_location_status.dart",
    "lib\test_firebase_connection.dart",
    "lib\test_firebase_realtime.dart"
)

foreach ($file in $filesToUpdate) {
    if (Test-Path $file) {
        Write-Host "  ⚠️  $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎯 Prioritas Fix:" -ForegroundColor Magenta
Write-Host "==================" -ForegroundColor Magenta
Write-Host ""
Write-Host "1. 🚨 HIGH PRIORITY - Main Location Tracking:" -ForegroundColor Red
Write-Host "   ✅ LocationService - SUDAH DIPERBAIKI" -ForegroundColor Green
Write-Host "   ✅ Admin Location Page - SUDAH DIPERBAIKI" -ForegroundColor Green
Write-Host ""
Write-Host "2. 📊 MEDIUM PRIORITY - Testing Tools:" -ForegroundColor Yellow
Write-Host "   • Emergency RTDB Test (sudah ada fallback)" -ForegroundColor Gray
Write-Host "   • Database Region Test (sudah ada fallback)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 🔧 LOW PRIORITY - Other Tests:" -ForegroundColor Blue
Write-Host "   • Test files lainnya" -ForegroundColor Gray
Write-Host ""

Write-Host "🚀 TESTING LANGKAH:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Deploy database rules (jika belum):" -ForegroundColor White
Write-Host "   ./emergency-rules.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Test main location tracking:" -ForegroundColor White
Write-Host "   flutter run -d chrome --web-hostname localhost --web-port 3000" -ForegroundColor Cyan
Write-Host "   → Login sebagai jamaah → Enable location tracking" -ForegroundColor Gray
Write-Host "   → Login sebagai admin → Check location page" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test emergency diagnostic:" -ForegroundColor White
Write-Host "   http://localhost:3000/#/emergency-rtdb-test" -ForegroundColor Cyan
Write-Host "   → Harus melihat 'Asia Southeast region detected'" -ForegroundColor Gray
Write-Host "   → Semua write operations SUCCESS" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 EXPECTED RESULTS:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "  ❌ Before: Database connection was forcefully killed" -ForegroundColor Red
Write-Host "  ✅ After: Live location tracking works" -ForegroundColor Green
Write-Host "  ✅ Admin dapat melihat lokasi jamaah real-time" -ForegroundColor Green
Write-Host "  ✅ Tidak ada error region mismatch" -ForegroundColor Green
Write-Host ""

$test = Read-Host "Test sekarang? (y/n)"

if ($test -eq "y" -or $test -eq "Y") {
    Write-Host ""
    Write-Host "🚀 Starting test..." -ForegroundColor Yellow
    
    # Check if rules are deployed
    Write-Host "⚠️  PENTING: Pastikan database rules sudah di-deploy!" -ForegroundColor Red
    Write-Host "   Jika belum: ./emergency-rules.ps1" -ForegroundColor Yellow
    Write-Host ""
    
    Read-Host "Press Enter setelah memastikan rules sudah di-deploy..."
    
    # Start the app
    Write-Host "📱 Starting Flutter app..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-Command", "flutter run -d chrome --web-hostname localhost --web-port 3000"
    
    Start-Sleep 5
    
    Write-Host ""
    Write-Host "🧪 Test URLs:" -ForegroundColor Green
    Write-Host "  • Emergency Test: http://localhost:3000/#/emergency-rtdb-test" -ForegroundColor Cyan
    Write-Host "  • Location Debug: http://localhost:3000/#/test-location-debug" -ForegroundColor Cyan
    Write-Host "  • Admin Location: http://localhost:3000/admin/lokasi" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ Expected: Tidak ada error 'Database lives in a different region'" -ForegroundColor Green
    
} else {
    Write-Host ""
    Write-Host "📖 Manual testing:" -ForegroundColor Yellow
    Write-Host "  1. ./emergency-rules.ps1 (deploy rules)" -ForegroundColor White
    Write-Host "  2. flutter run -d chrome" -ForegroundColor White
    Write-Host "  3. Test emergency page" -ForegroundColor White
    Write-Host ""
}
