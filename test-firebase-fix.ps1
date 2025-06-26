# Test Firebase Duplicate App Fix
# This script will test the Firebase initialization fix

Write-Host "🔥 Testing Firebase Duplicate App Fix" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

Write-Host ""
Write-Host "🔍 Starting Flutter app to test Firebase initialization..." -ForegroundColor Cyan

# Test the fix by running the app
Write-Host "📱 Running: flutter run -d chrome --web-hostname localhost --web-port 3000" -ForegroundColor Gray

try {
    # Start the app in the background to capture logs
    $process = Start-Process -FilePath "flutter" -ArgumentList "run", "-d", "chrome", "--web-hostname", "localhost", "--web-port", "3000" -PassThru -WindowStyle Hidden -RedirectStandardOutput "firebase_test_output.log" -RedirectStandardError "firebase_test_error.log"
    
    Write-Host "⏱️  Waiting 10 seconds for app to start..." -ForegroundColor Yellow
    Start-Sleep 10
    
    # Check if the process is still running (no immediate crash)
    if ($process.HasExited) {
        Write-Host "❌ App crashed during startup!" -ForegroundColor Red
        Write-Host "   Exit code: $($process.ExitCode)" -ForegroundColor Red
        
        if (Test-Path "firebase_test_error.log") {
            Write-Host "📄 Error log:" -ForegroundColor Yellow
            Get-Content "firebase_test_error.log" | Select-Object -Last 10
        }
    } else {
        Write-Host "✅ App started successfully!" -ForegroundColor Green
        Write-Host "🌐 Testing URL: http://localhost:3000" -ForegroundColor Cyan
        
        # Check output logs for Firebase messages
        if (Test-Path "firebase_test_output.log") {
            Write-Host ""
            Write-Host "🔍 Firebase initialization logs:" -ForegroundColor Cyan
            Get-Content "firebase_test_output.log" | Where-Object { $_ -like "*Firebase*" -or $_ -like "*✅*" -or $_ -like "*⚠️*" -or $_ -like "*❌*" } | Select-Object -Last 5
        }
        
        Write-Host ""
        Write-Host "🧪 Test the emergency RTDB page:" -ForegroundColor Green
        Write-Host "   http://localhost:3000/#/emergency-rtdb-test" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📝 Expected results:" -ForegroundColor Yellow
        Write-Host "   ✅ No duplicate app errors" -ForegroundColor Green
        Write-Host "   ✅ App loads successfully" -ForegroundColor Green
        Write-Host "   ✅ Firebase connection works" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "⏹️  Press any key to stop the test app..." -ForegroundColor Gray
        Read-Host
        
        # Stop the process
        $process.Kill()
        Write-Host "🛑 Test app stopped" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error running test: $_" -ForegroundColor Red
}

# Clean up log files
if (Test-Path "firebase_test_output.log") { Remove-Item "firebase_test_output.log" }
if (Test-Path "firebase_test_error.log") { Remove-Item "firebase_test_error.log" }

Write-Host ""
Write-Host "🎯 If no duplicate app errors appeared, the fix is working!" -ForegroundColor Green
