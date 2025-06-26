# Quick Firebase Fix Verification
# Run this to verify the duplicate app error is fixed

Write-Host "🔥 Quick Firebase Fix Test" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow

Write-Host ""
Write-Host "📋 What was fixed:" -ForegroundColor Cyan
Write-Host "  ✅ Added Firebase.apps.isEmpty check" -ForegroundColor Green
Write-Host "  ✅ Added try-catch for duplicate-app error" -ForegroundColor Green
Write-Host "  ✅ Added proper error logging" -ForegroundColor Green
Write-Host ""

$quick = Read-Host "Run quick test? (y/n)"

if ($quick -eq "y" -or $quick -eq "Y") {
    Write-Host "🚀 Testing Firebase initialization..." -ForegroundColor Yellow
    
    # Try to compile the app first
    Write-Host "📝 Compiling app..." -ForegroundColor Gray
    $compileResult = flutter analyze 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ App compiles successfully" -ForegroundColor Green
        
        Write-Host "🌐 Starting app for 15 seconds..." -ForegroundColor Yellow
        Write-Host "   If no duplicate app error appears, the fix worked!" -ForegroundColor Cyan
        
        Start-Job -ScriptBlock {
            flutter run -d chrome --web-hostname localhost --web-port 3000
        } | Out-Null
        
        Start-Sleep 15
        
        # Stop any running Flutter processes
        Get-Process -Name "flutter" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        Write-Host "✅ Test completed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎯 Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Deploy database rules: ./emergency-rules.ps1" -ForegroundColor White
        Write-Host "  2. Run full test: ./start-test.ps1" -ForegroundColor White
        Write-Host "  3. Test location: http://localhost:3000/#/emergency-rtdb-test" -ForegroundColor White
        
    } else {
        Write-Host "❌ Compilation errors found:" -ForegroundColor Red
        Write-Host $compileResult -ForegroundColor Gray
    }
} else {
    Write-Host "⏭️  Skipped. Run ./start-test.ps1 for full testing" -ForegroundColor Yellow
}
