# Migration from Web to React Native - Setup Guide

## Quick Start Checklist

### 1. Initialize React Native Project with Native Code

The current setup has all the JavaScript/TypeScript code but needs the native Android code.

**Option A: Using React Native CLI (Recommended)**
```bash
cd /Users/avi19/Documents/projects/hackathons/devsoc26/android-app

# Initialize a new React Native project
npx react-native@latest init ReportHubMobile --directory temp

# Copy the generated android and ios folders
cp -r temp/android .
cp -r temp/ios .

# Copy over our customized files
# (This preserves our src/, package.json, tsconfig.json, etc.)

# Clean up temp
rm -rf temp

# Install dependencies
npm install
```

**Option B: Manual Setup**
If you already have the android/ folder structure, just install dependencies:
```bash
npm install
cd android && ./gradlew clean
cd ..
```

### 2. Install Required Dependencies

```bash
# Core navigation
npm install @react-navigation/native @react-navigation/native-stack @react-navigation/bottom-tabs

# React Native dependencies
npm install react-native-screens react-native-safe-area-context

# Storage
npm install @react-native-async-storage/async-storage

# HTTP client
npm install axios

# Image picker
npm install react-native-image-picker

# Maps (optional, for location picker)
npm install react-native-maps

# Icons
npm install react-native-vector-icons

# Link native dependencies (for React Native < 0.60)
npx react-native link
```

### 3. Configure Android Studio

1. **Open Android Studio**
2. **Open the android/ folder** in Android Studio
3. **Let Gradle sync** (this may take several minutes the first time)
4. **Create/start an emulator:**
   - Tools → Device Manager
   - Create Device → Pixel 4 (or similar)
   - Download system image (API 33 recommended)
   - Start emulator

### 4. Update Gradle Files (if needed)

If you encounter build issues, you may need to update:

**android/build.gradle:**
```gradle
buildscript {
    ext {
        buildToolsVersion = "33.0.0"
        minSdkVersion = 21
        compileSdkVersion = 33
        targetSdkVersion = 33
    }
}
```

**android/app/build.gradle:**
```gradle
android {
    compileSdkVersion rootProject.ext.compileSdkVersion
    
    defaultConfig {
        applicationId "com.reporthubmobile"
        minSdkVersion rootProject.ext.minSdkVersion
        targetSdkVersion rootProject.ext.targetSdkVersion
        versionCode 1
        versionName "1.0"
    }
}
```

### 5. Configure Backend for Mobile

**backend/report_hub/settings/base.py:**
```python
# Allow connections from Android emulator
ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '10.0.2.2',  # Android emulator
    '192.168.1.*',  # Local network (for physical devices)
]

# CORS settings
CORS_ALLOWED_ORIGINS = [
    'http://localhost:8081',
    'http://10.0.2.2:8081',
]

# Or allow all for development
CORS_ALLOW_ALL_ORIGINS = True  # Development only!
```

### 6. Run the App

**Terminal 1 - Django Backend:**
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

**Terminal 2 - Metro Bundler:**
```bash
cd android-app
npm start
```

**Terminal 3 - Android App:**
```bash
cd android-app
npm run android
```

### 7. Verify Connection

The app should:
1. ✅ Build successfully
2. ✅ Install on emulator
3. ✅ Show Landing screen
4. ✅ Navigate to Login/Register
5. ✅ Connect to backend at `http://10.0.2.2:8000/api`

## Common Issues & Solutions

### Issue: "SDK location not found"
**Solution:**
```bash
# Create local.properties file
echo "sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk" > android/local.properties
```

### Issue: "Could not connect to development server"
**Solution:**
```bash
# Shake device/emulator → Dev Settings → Change Bundle Location
# Enter: localhost:8081
# Or run: adb reverse tcp:8081 tcp:8081
```

### Issue: "Unable to resolve module"
**Solution:**
```bash
# Clear cache and reinstall
rm -rf node_modules
npm install
npm start -- --reset-cache
```

### Issue: "Network request failed" when calling API
**Solution:**
1. Check backend is running on `0.0.0.0:8000`
2. Verify emulator can access `http://10.0.2.2:8000`
3. Check CORS settings in Django
4. Test API with curl:
   ```bash
   adb shell
   curl http://10.0.2.2:8000/api/users/me/
   ```

### Issue: Build fails with Gradle errors
**Solution:**
```bash
cd android
./gradlew clean
./gradlew build --stacktrace
```

## Testing the Migration

### 1. Test Authentication Flow
- [ ] Register new account
- [ ] Login with credentials
- [ ] Logout
- [ ] Token refresh works
- [ ] Protected routes work

### 2. Test Report Flow
- [ ] Submit new report
- [ ] View community reports
- [ ] Track report by ID
- [ ] View report history
- [ ] View report details

### 3. Test UI/UX
- [ ] Navigation works smoothly
- [ ] Forms validate correctly
- [ ] Loading states show
- [ ] Error messages display
- [ ] Images display correctly

## Performance Checklist

- [ ] Images are optimized (< 1MB)
- [ ] API calls have loading states
- [ ] Lists use FlatList for performance
- [ ] Unnecessary re-renders avoided
- [ ] App doesn't crash on network errors

## Next Steps

1. ✅ **Get app running on emulator**
2. ⏳ **Implement image upload to S3**
3. ⏳ **Add map location picker**
4. ⏳ **Implement Google OAuth**
5. ⏳ **Add push notifications**
6. ⏳ **Test on physical device**
7. ⏳ **Build release APK**
8. ⏳ **Submit to Play Store**

## Resources

- [React Native Docs](https://reactnative.dev/docs/getting-started)
- [React Navigation](https://reactnavigation.org/docs/getting-started)
- [Android Developer Guide](https://developer.android.com/guide)
- [Debugging Guide](https://reactnative.dev/docs/debugging)

---

**Need help?** Check the TODO comments in the code for guidance on incomplete features.
