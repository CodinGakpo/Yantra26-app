# Quick Start Guide - NagrikMitra2 iOS

Get the NagrikMitra2 iOS app running in 5 minutes!

## ⚡ Quick Setup

### 1. Start Backend (Terminal 1)
```bash
cd backend
python manage.py runserver
```

Keep this terminal running!

### 2. Configure App

Open `NagrikMitra2/NagrikMitra2/APIConfig.swift` and set your backend URL:

**For iOS Simulator:**
```swift
static let baseURL = "http://localhost:8000"
```

**For Physical iPhone/iPad:**
```swift
static let baseURL = "http://YOUR_COMPUTER_IP:8000"  // e.g., "http://192.168.1.100:8000"
```

> 💡 **Find Your IP:** Run `ifconfig | grep "inet " | grep -v 127.0.0.1` in Terminal

### 3. Open & Run

```bash
cd NagrikMitra2
open NagrikMitra2.xcodeproj
```

In Xcode:
1. Select iPhone 15 Pro (or any iOS 16+ simulator/device)
2. Press `Cmd + R` to build and run
3. Wait for app to launch

## ✅ First Use

### Register Account
1. Tap **"Get Started"** on landing page
2. Tap **"Register"** at bottom
3. Enter:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `testpass123`
4. Tap **"Register"**

### Submit First Report
1. Go to **"Report"** tab
2. Fill in:
   - Title: `Pothole on Main Street`
   - Location: `Main Street, Downtown`
   - Description: `Large pothole causing traffic issues`
3. Tap **"Choose Photo"** (optional)
4. Tap **"Submit Report"**
5. Note the tracking ID from success message!

### Track Report
1. Go to **"Track"** tab
2. Enter your tracking ID
3. Tap **"Search"**
4. View report status and details

### View Community
1. Go to **"Community"** tab
2. See all resolved reports
3. Pull down to refresh

### Check Profile
1. Go to **"Profile"** tab
2. View your stats and report history

## 🐛 Common Issues

### "Cannot connect to backend"
**Solution:** Start backend first!
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

### "401 Unauthorized"
**Solution:** Logout and login again (token expired)

### Physical device can't connect
**Solutions:**
1. Update `APIConfig.baseURL` to your computer's IP
2. Ensure iPhone and Mac are on same WiFi
3. Start backend with: `python manage.py runserver 0.0.0.0:8000`

### Build fails in Xcode
**Solutions:**
1. Clean: `Cmd + Shift + K`
2. Restart Xcode
3. Delete Derived Data: `~/Library/Developer/Xcode/DerivedData`

## 🎯 Testing Checklist

- [ ] Backend is running
- [ ] App builds without errors
- [ ] Can see landing page
- [ ] Can register new account
- [ ] Can login with credentials
- [ ] Can submit report with photo
- [ ] Can track report by ID
- [ ] Can view community feed
- [ ] Can see profile and stats
- [ ] Can logout

## 📱 Next Steps

- Configure real backend URL for production
- Customize colors in `Theme.swift`
- Add app icon in Assets.xcassets
- Configure signing for physical device testing
- Set up TestFlight for beta distribution

## 🚀 Pro Tips

1. **Use Simulator:** Fastest for development, use localhost
2. **Test on Device:** Best for real-world testing, use IP address
3. **Clean Build:** If strange errors, clean build folder (`Cmd + Shift + K`)
4. **Console Logs:** Check Xcode console for API request/response details
5. **Backend Logs:** Check Django terminal for backend errors

## 📞 Need Help?

Check the full [README.md](README.md) for:
- Detailed API documentation
- Architecture overview
- Advanced configuration
- Deployment guide
- Troubleshooting tips

Happy coding! 🎉
