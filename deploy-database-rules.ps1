# Deploy Firebase Realtime Database Rules

Write-Host "🔥 Deploying Firebase Realtime Database Rules..." -ForegroundColor Yellow

# Check if firebase CLI is available
if (!(Get-Command "firebase" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Firebase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
$loginCheck = firebase projects:list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not logged in to Firebase. Please login first:" -ForegroundColor Red
    Write-Host "firebase login" -ForegroundColor Yellow
    exit 1
}

# Deploy database rules
Write-Host "📤 Deploying database rules..." -ForegroundColor Blue
firebase deploy --only database

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database rules deployed successfully!" -ForegroundColor Green
    Write-Host "" 
    Write-Host "🔍 You can now test the location feature:" -ForegroundColor Cyan
    Write-Host "1. Run: flutter run --debug" -ForegroundColor White
    Write-Host "2. Navigate to: /quick-rtdb-test" -ForegroundColor White
    Write-Host "3. Check if RTDB write operations work" -ForegroundColor White
} else {
    Write-Host "❌ Failed to deploy database rules" -ForegroundColor Red
    Write-Host "Please check your Firebase project configuration" -ForegroundColor Yellow
}
