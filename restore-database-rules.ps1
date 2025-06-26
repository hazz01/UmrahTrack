# Restore Original Database Rules

Write-Host "🔄 RESTORING ORIGINAL DATABASE RULES" -ForegroundColor Blue

# Check if backup exists
if (!(Test-Path "database.rules.backup.json")) {
    Write-Host "❌ No backup file found!" -ForegroundColor Red
    Write-Host "💡 Manually restore your rules in Firebase Console" -ForegroundColor Yellow
    exit 1
}

# Restore original rules
Write-Host "📋 Restoring from backup..." -ForegroundColor Blue
Copy-Item "database.rules.backup.json" "database.rules.json" -Force

# Deploy original rules
Write-Host "🚀 Deploying original rules..." -ForegroundColor Blue
firebase deploy --only database

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Original rules restored successfully!" -ForegroundColor Green
    Write-Host "🗑️  Cleaning up emergency files..." -ForegroundColor Blue
    
    # Clean up emergency files
    if (Test-Path "database.rules.emergency.json") {
        Remove-Item "database.rules.emergency.json"
    }
    
    Write-Host "✅ Cleanup complete" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to restore original rules" -ForegroundColor Red
    Write-Host "💡 Check Firebase Console and manually restore rules" -ForegroundColor Yellow
}
