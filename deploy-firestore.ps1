# Firestore Deployment Script for Windows PowerShell
# Run this after upgrading Node.js to version 20+

Write-Host "🚀 Deploying Firestore Rules and Indexes..." -ForegroundColor Green

# Check Node.js version
$nodeVersion = node --version
Write-Host "📋 Current Node.js version: $nodeVersion" -ForegroundColor Cyan

# Check if Firebase CLI is installed
try {
    firebase --version | Out-Null
    Write-Host "✅ Firebase CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g firebase-tools
}

# Deploy Firestore rules and indexes
Write-Host "📤 Deploying Firestore configuration..." -ForegroundColor Cyan

try {
    firebase deploy --only firestore
    Write-Host "✅ Deployment complete!" -ForegroundColor Green
} catch {
    Write-Host "❌ Deployment failed. Please check your Firebase authentication." -ForegroundColor Red
    Write-Host "Run 'firebase login' first, then try again." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Check Firebase Console for index build progress"
Write-Host "2. Test the Rombongan feature in your app"
Write-Host "3. Verify CRUD operations work without errors"
