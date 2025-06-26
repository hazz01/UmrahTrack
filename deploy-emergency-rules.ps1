# Emergency Database Rules - Completely Open for Testing
# WARNING: This makes your database completely open! Only for testing!

Write-Host "🚨 EMERGENCY DATABASE RULES DEPLOYMENT" -ForegroundColor Red
Write-Host "⚠️  WARNING: This will make your database COMPLETELY OPEN!" -ForegroundColor Yellow
Write-Host "⚠️  Only use this for testing purposes!" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Type 'YES' to confirm you want to deploy open rules"
if ($confirmation -ne "YES") {
    Write-Host "❌ Deployment cancelled" -ForegroundColor Red
    exit 1
}

# Check if firebase CLI is available
if (!(Get-Command "firebase" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Firebase CLI not found. Installing..." -ForegroundColor Red
    npm install -g firebase-tools
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install Firebase CLI" -ForegroundColor Red
        exit 1
    }
}

# Backup current rules
Write-Host "📋 Backing up current rules..." -ForegroundColor Blue
Copy-Item "database.rules.json" "database.rules.backup.json" -Force
Write-Host "✅ Current rules backed up to database.rules.backup.json" -ForegroundColor Green

# Create completely open rules
Write-Host "📝 Creating emergency open rules..." -ForegroundColor Blue
$openRules = @'
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
'@

$openRules | Out-File -FilePath "database.rules.emergency.json" -Encoding utf8
Write-Host "✅ Emergency rules created" -ForegroundColor Green

# Deploy open rules
Write-Host "🚀 Deploying emergency open rules..." -ForegroundColor Blue
firebase deploy --only database
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Emergency rules deployed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🧪 Now test your location feature:" -ForegroundColor Cyan
    Write-Host "1. Run: flutter run --debug" -ForegroundColor White
    Write-Host "2. Navigate to: /emergency-rtdb-test" -ForegroundColor White
    Write-Host "3. Run emergency test to see what works" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Run restore-database-rules.ps1 after testing!" -ForegroundColor Yellow
} else {
    Write-Host "❌ Failed to deploy emergency rules" -ForegroundColor Red
    exit 1
}
