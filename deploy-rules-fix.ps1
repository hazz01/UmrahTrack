# Firebase Database Rules Deployment Script
# Alternative method when Firebase CLI has Node.js issues

param(
    [string]$Action = "deploy",
    [switch]$Emergency = $false
)

Write-Host "🔥 Firebase Database Rules Deployment Tool" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

# Check if Firebase CLI is working
Write-Host "🔍 Checking Firebase CLI..." -ForegroundColor Cyan
try {
    $firebaseVersion = firebase --version 2>&1
    if ($firebaseVersion -match "incompatible") {
        Write-Host "❌ Firebase CLI has Node.js compatibility issues" -ForegroundColor Red
        Write-Host "   $firebaseVersion" -ForegroundColor Gray
        $useAlternative = $true
    } else {
        Write-Host "✅ Firebase CLI is working: $firebaseVersion" -ForegroundColor Green
        $useAlternative = $false
    }
} catch {
    Write-Host "❌ Firebase CLI not found or not working" -ForegroundColor Red
    $useAlternative = $true
}

if ($useAlternative) {
    Write-Host "🚀 Using Alternative Deployment Method" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "MANUAL DEPLOYMENT INSTRUCTIONS:" -ForegroundColor Yellow
    Write-Host "===============================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 🌐 Open Firebase Console:" -ForegroundColor White
    Write-Host "   https://console.firebase.google.com/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. 📁 Navigate to Project:" -ForegroundColor White
    Write-Host "   → Select 'umrahtrack-hazz'" -ForegroundColor Cyan
    Write-Host "   → Click 'Realtime Database' in sidebar" -ForegroundColor Cyan
    Write-Host "   → Make sure you're on the Asia Southeast instance" -ForegroundColor Cyan
    Write-Host "   → Click 'Rules' tab" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. 📝 Replace Rules with:" -ForegroundColor White
    
    if ($Emergency) {
        Write-Host "   {" -ForegroundColor Green
        Write-Host '     "rules": {' -ForegroundColor Green
        Write-Host '       ".read": true,' -ForegroundColor Green
        Write-Host '       ".write": true' -ForegroundColor Green
        Write-Host "     }" -ForegroundColor Green
        Write-Host "   }" -ForegroundColor Green
        Write-Host ""
        Write-Host "   ⚠️  EMERGENCY OPEN RULES - FOR TESTING ONLY!" -ForegroundColor Red
    } else {
        # Show current rules from file
        if (Test-Path "database.rules.json") {
            Write-Host "   Current rules from database.rules.json:" -ForegroundColor Gray
            Get-Content "database.rules.json" | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
        }
    }
    
    Write-Host ""
    Write-Host "4. 🚀 Deploy:" -ForegroundColor White
    Write-Host "   → Click 'Publish' button" -ForegroundColor Cyan
    Write-Host "   → Wait for confirmation" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "5. ✅ Verify:" -ForegroundColor White
    Write-Host "   → Run the test: flutter run -d chrome" -ForegroundColor Cyan
    Write-Host "   → Navigate to: http://localhost:3000/#/emergency-rtdb-test" -ForegroundColor Cyan
    Write-Host ""
    
} else {
    Write-Host "🚀 Using Firebase CLI Deployment" -ForegroundColor Magenta
    
    if ($Emergency) {
        Write-Host "⚠️  Deploying EMERGENCY OPEN RULES!" -ForegroundColor Red
        $rulesContent = @"
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
"@
        $rulesContent | Out-File -FilePath "database.rules.emergency.json" -Encoding UTF8
        firebase deploy --only database:rules --project umrahtrack-hazz
    } else {
        Write-Host "📝 Deploying standard rules from database.rules.json" -ForegroundColor Green
        firebase deploy --only database:rules --project umrahtrack-hazz
    }
}

Write-Host ""
Write-Host "🎯 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "===============" -ForegroundColor Yellow
Write-Host "1. After deploying rules, test the connection:" -ForegroundColor White
Write-Host "   ./start-test.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Navigate to emergency test:" -ForegroundColor White
Write-Host "   http://localhost:3000/#/emergency-rtdb-test" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Expected results:" -ForegroundColor White
Write-Host "   ✅ Database URL: Asia Southeast region" -ForegroundColor Green
Write-Host "   ✅ All write operations succeed" -ForegroundColor Green
Write-Host "   ✅ No 10-second timeouts" -ForegroundColor Green
Write-Host ""

if ($Emergency) {
    Write-Host "⚠️  IMPORTANT: These are OPEN rules for testing only!" -ForegroundColor Red
    Write-Host "   Deploy secure rules after testing is complete." -ForegroundColor Red
}
