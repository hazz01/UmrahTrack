# Emergency Open Rules for Testing
# Use this when you need to quickly test database connectivity

Write-Host "🚨 EMERGENCY DATABASE RULES DEPLOYMENT" -ForegroundColor Red
Write-Host "=======================================" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  WARNING: This deploys OPEN rules for testing only!" -ForegroundColor Yellow
Write-Host "   All users can read/write all data!" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Deploy emergency open rules? (type 'EMERGENCY' to confirm)"

if ($confirm -ne "EMERGENCY") {
    Write-Host "❌ Emergency deployment cancelled" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔥 Creating emergency rules..." -ForegroundColor Yellow

# Create emergency rules file
$emergencyRules = @"
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
"@

$emergencyRules | Out-File -FilePath "database.rules.emergency.json" -Encoding UTF8

Write-Host "✅ Emergency rules created: database.rules.emergency.json" -ForegroundColor Green
Write-Host ""
Write-Host "📋 MANUAL DEPLOYMENT REQUIRED:" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. 🌐 Open: https://console.firebase.google.com/" -ForegroundColor White
Write-Host "2. 📁 Select: umrahtrack-hazz project" -ForegroundColor White
Write-Host "3. 🗄️  Go to: Realtime Database → Rules" -ForegroundColor White
Write-Host "4. 🌏 Ensure: Asia Southeast instance selected" -ForegroundColor White
Write-Host "5. 📝 Replace rules with:" -ForegroundColor White
Write-Host ""
Write-Host $emergencyRules -ForegroundColor Green
Write-Host ""
Write-Host "6. 🚀 Click: Publish" -ForegroundColor White
Write-Host ""
Write-Host "⏱️  Expected result: Database writes complete in <1 second (no timeouts)" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Test immediately with:" -ForegroundColor Yellow
Write-Host "./start-test.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔒 REMEMBER: Deploy secure rules after testing!" -ForegroundColor Red
