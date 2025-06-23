#!/bin/bash

# Firestore Deployment Script
# Run this after upgrading Node.js to version 20+

echo "🚀 Deploying Firestore Rules and Indexes..."

# Check Node.js version
NODE_VERSION=$(node --version)
echo "📋 Current Node.js version: $NODE_VERSION"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Login to Firebase (if not already logged in)
echo "🔐 Checking Firebase authentication..."
firebase login --no-localhost

# Deploy Firestore rules and indexes
echo "📤 Deploying Firestore configuration..."
firebase deploy --only firestore

echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Check Firebase Console for index build progress"
echo "2. Test the Rombongan feature in your app"
echo "3. Verify CRUD operations work without errors"
