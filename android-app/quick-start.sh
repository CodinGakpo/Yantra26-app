#!/bin/bash

# Quick Start Script for React Native Android App
# This script helps initialize the React Native project with native code

set -e  # Exit on error

echo "🚀 ReportHub Mobile - Quick Start Setup"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the android-app directory."
    exit 1
fi

# Check Node version
echo "📦 Checking Node.js version..."
NODE_VERSION=$(node -v)
echo "   Node version: $NODE_VERSION"

# Check if React Native CLI is installed
echo "🔍 Checking for React Native CLI..."
if ! command -v npx &> /dev/null; then
    echo "❌ npx not found. Please install Node.js first."
    exit 1
fi

# Check if android folder exists
if [ -d "android" ]; then
    echo "✅ Android folder already exists."
    echo "   → Skipping React Native initialization"
else
    echo "⚠️  Android folder not found. Need to initialize React Native project."
    echo ""
    read -p "   Do you want to initialize React Native project? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔨 Initializing React Native project..."
        echo "   This will create android/ and ios/ folders..."
        
        # Create temp directory and initialize
        npx react-native@latest init ReportHubMobile --directory temp --skip-install
        
        # Copy android and ios folders
        echo "📁 Copying native folders..."
        cp -r temp/android .
        cp -r temp/ios .
        
        # Clean up
        rm -rf temp
        
        echo "✅ Native folders created successfully!"
    else
        echo "⏭️  Skipping initialization. You'll need to set up Android manually."
    fi
fi

# Install dependencies
echo ""
echo "📦 Installing npm dependencies..."
npm install

# Check for Android SDK
echo ""
echo "🔍 Checking Android SDK..."
if [ -z "$ANDROID_HOME" ]; then
    echo "⚠️  ANDROID_HOME not set!"
    echo "   Please set ANDROID_HOME environment variable:"
    echo "   export ANDROID_HOME=\$HOME/Library/Android/sdk"
    echo "   export PATH=\$PATH:\$ANDROID_HOME/emulator:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools"
else
    echo "✅ ANDROID_HOME is set: $ANDROID_HOME"
fi

# Create local.properties for Android
if [ ! -f "android/local.properties" ] && [ -d "android" ]; then
    echo ""
    echo "📝 Creating android/local.properties..."
    if [ ! -z "$ANDROID_HOME" ]; then
        echo "sdk.dir=$ANDROID_HOME" > android/local.properties
        echo "✅ Created android/local.properties"
    else
        echo "⚠️  Skipped: ANDROID_HOME not set"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Start Django backend:"
echo "   cd ../backend && python manage.py runserver 0.0.0.0:8000"
echo ""
echo "2. Start Metro bundler (in this directory):"
echo "   npm start"
echo ""
echo "3. Run on Android (in new terminal):"
echo "   npm run android"
echo ""
echo "4. Or open android/ in Android Studio and run from there"
echo ""
echo "📚 For more details, see:"
echo "   - README.md"
echo "   - SETUP_GUIDE.md"
echo "   - MIGRATION_SUMMARY.md"
echo ""
echo "🎉 Happy coding!"
