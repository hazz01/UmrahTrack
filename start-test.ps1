# Quick Start Script for Testing Database Fix
# Run this script to start the Flutter app and test the location system

Write-Host "🚀 UmrahTrack Database Fix Testing Tool" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

Write-Host ""
Write-Host "✅ FIREBASE DUPLICATE APP ERROR - FIXED!" -ForegroundColor Green
Write-Host "  Enhanced main.dart with duplicate app protection" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 CHECKLIST - Complete these steps:" -ForegroundColor Yellow
Write-Host "1. ✅ Database rules deployed?" -ForegroundColor White
Write-Host "2. ✅ Firebase project: umrahtrack-hazz" -ForegroundColor White
Write-Host "3. ✅ Region: Asia Southeast" -ForegroundColor White
Write-Host ""

# Check if database rules need deployment
if (-not (Test-Path "database.rules.json")) {
    Write-Host "❌ database.rules.json not found!" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Current database rules:" -ForegroundColor Cyan
Get-Content "database.rules.json" | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
Write-Host ""

$deploy = Read-Host "Deploy these rules first? (y/n)"
if ($deploy -eq "y" -or $deploy -eq "Y") {
    Write-Host "🚀 Deploying database rules..." -ForegroundColor Yellow
    ./deploy-rules-fix.ps1
    Write-Host ""
    Write-Host "⚠️  Make sure to manually deploy via Firebase Console!" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter after deploying rules manually..."
}

# Start Flutter app
Write-Host "📱 Launching Flutter app in Chrome..." -ForegroundColor Yellow
Write-Host ""

try {
    Start-Process powershell -ArgumentList "-Command", "flutter run -d chrome --web-hostname localhost --web-port 3000" -WindowStyle Normal
    Start-Sleep 3
    
    Write-Host "🎯 Testing URLs Available:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🚨 PRIORITY TESTS:" -ForegroundColor Red
    Write-Host "  • Emergency RTDB Test: http://localhost:3000/#/emergency-rtdb-test" -ForegroundColor Yellow
    Write-Host "  • Database Region Test: http://localhost:3000/#/database-region-test" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📍 LOCATION TESTS:" -ForegroundColor Green
    Write-Host "  • Location Debug Test: http://localhost:3000/#/test-location-debug" -ForegroundColor White
    Write-Host "  • Location Diagnostic: http://localhost:3000/#/location-diagnostic" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 OTHER TESTS:" -ForegroundColor Blue
    Write-Host "  • Quick RTDB Test: http://localhost:3000/#/quick-rtdb-test" -ForegroundColor White
    Write-Host "  • Simple Firebase Test: http://localhost:3000/#/simple-firebase-test" -ForegroundColor White
    Write-Host ""
    
    Write-Host "✅ EXPECTED RESULTS:" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host "1. Emergency Test should show:" -ForegroundColor White
    Write-Host "   ✅ Database URL: Asia Southeast region" -ForegroundColor Green
    Write-Host "   ✅ All write operations succeed (no timeouts)" -ForegroundColor Green
    Write-Host "   ✅ Location data written successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "2. Location Debug should show:" -ForegroundColor White
    Write-Host "   ✅ GPS coordinates captured" -ForegroundColor Green
    Write-Host "   ✅ Firebase writes complete instantly" -ForegroundColor Green
    Write-Host "   ✅ Data visible in Firebase Console" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🔥 Firebase Console:" -ForegroundColor Magenta
    Write-Host "https://console.firebase.google.com/project/umrahtrack-hazz/database/umrahtrack-hazz-default-rtdb/data" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error starting Flutter app: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Try manually running:" -ForegroundColor Yellow
    Write-Host "flutter run -d chrome --web-hostname localhost --web-port 3000" -ForegroundColor White
}

Write-Host ""
Write-Host "📖 Need help? Check these files:" -ForegroundColor Yellow
Write-Host "  • URGENT_DATABASE_FIX_INSTRUCTIONS.md" -ForegroundColor White
Write-Host "  • deploy-rules-fix.ps1 -Emergency" -ForegroundColor White
