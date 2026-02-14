# JanSaathi - iOS App

An iOS application for reporting civic issues and tracking their resolution. Built with SwiftUI and connected to the JanSaathi Django backend.

## 📱 Features

- **Report Issues**: Submit civic problems with photos, location, and description
- **Track Reports**: Search and monitor report status using tracking IDs
- **Community Feed**: View resolved issues from other citizens
- **User Profile**: Track your reporting history and statistics
- **Aadhaar Verification**: Verify your identity with Aadhaar integration
- **Real-time Updates**: Get instant status updates on your reports
- **Blockchain Integration**: Transparent and immutable report verification

## 🎨 Design

The app follows the same design language as the web frontend with:
- Emerald green primary color (#059669)
- Modern gradient backgrounds
- Clean, intuitive interface
- iOS-native components and gestures

## 🛠️ Tech Stack

- **SwiftUI**: Modern declarative UI framework
- **URLSession**: Native networking
- **PhotosPicker**: Image selection
- **UserDefaults**: Token persistence
- **Async/Await**: Modern concurrency
- **iOS 16.0+**: Minimum deployment target

## 📋 Prerequisites

- Mac with macOS 13.0 or later
- Xcode 14.0 or later
- iOS 16.0+ device or simulator
- Django backend running (see backend setup)

## 🚀 Getting Started

### 1. Backend Setup

First, ensure your Django backend is running:
Backend server = https://github.com/dibyajyoti-chakrabarti/devsoc26

```bash
cd backend
python manage.py runserver
```

### 2. Configure Backend URL

Open [APIConfig.swift](NagrikMitra2/APIConfig.swift) and update the base URL:

```swift
// For iOS Simulator (local backend)
static let baseURL = "http://localhost:8000"

// For Physical Device (use your computer's IP)
static let baseURL = "http://192.168.1.100:8000"

// For Production
static let baseURL = "https://your-backend-url.com"
```

**Finding Your IP Address:**
- macOS: System Settings → Network → Your active connection
- Command line: `ifconfig | grep "inet " | grep -v 127.0.0.1`

### 3. Open in Xcode

```bash
cd Yantra26-app
open NagrikMitra2.xcodeproj
```

### 4. Build and Run

1. Select a simulator or connected device
2. Press `Cmd + R` or click the Play button
3. Wait for the app to build and launch

## 📱 App Structure

```
Yantra26-app/
├── Models.swift              # Data models (User, Report, Profile)
├── APIConfig.swift           # API endpoints configuration
├── NetworkManager.swift      # Network layer
├── AuthManager.swift         # Authentication state
├── Theme.swift               # Design system
├── NagrikMitra2App.swift     # App entry point
├── MainTabView.swift         # Tab navigation
├── LandingView.swift         # Welcome screen
├── LoginView.swift           # Authentication
├── ReportView.swift          # Submit reports
├── TrackView.swift           # Track reports
├── CommunityView.swift       # Community feed
└── ProfileView.swift         # User profile
```

## 🔌 API Integration

The app connects to the following Django backend endpoints:

### Authentication
- `POST /api/users/login/` - User login
- `POST /api/users/register/` - User registration
- `GET /api/users/me/` - Get current user

### Reports
- `POST /api/reports/` - Submit new report
- `GET /api/reports/community/resolved/` - Get resolved reports
- `GET /api/reports/history/` - Get user's report history
- `POST /api/reports/s3/presign/` - Get S3 upload URL

### Tracking
- `GET /track/detail/{tracking_id}/` - Get report by tracking ID

### Profile
- `GET /api/profile/me/` - Get user profile
- `POST /api/aadhaar/verify/` - Verify Aadhaar

## 🔐 Authentication Flow

1. User enters credentials on LoginView
2. AuthManager sends request to backend
3. Backend returns JWT tokens (access + refresh)
4. Tokens stored in UserDefaults
5. NetworkManager includes token in subsequent requests
6. User remains logged in until explicit logout

## 📸 Image Upload Flow

1. User selects photo using PhotosPicker
2. App requests presigned S3 URL from backend
3. Backend generates presigned URL and returns it
4. App uploads image directly to S3
5. Backend stores image URL with report

## 🎯 Key Components

### AuthManager
Manages authentication state and user session:
- Handles login/register/logout
- Persists tokens in UserDefaults
- Provides current user information

### NetworkManager
Generic networking layer:
- Async/await based requests
- JWT authentication
- Error handling
- S3 image uploads

### Theme
Centralized design system:
- Brand colors
- Gradients
- Helper utilities

## 🐛 Troubleshooting

### Backend Connection Issues

**Simulator can't connect:**
- Make sure Django is running on `0.0.0.0:8000`, not `127.0.0.1:8000`
- Use `python manage.py runserver 0.0.0.0:8000`

**Physical device can't connect:**
- Ensure your device and computer are on the same WiFi
- Update `APIConfig.baseURL` to your computer's IP address
- Allow incoming connections in your firewall

### Build Errors

**Missing dependencies:**
- Clean build folder: Product → Clean Build Folder (`Cmd + Shift + K`)
- Restart Xcode

**iOS version mismatch:**
- Update deployment target in Xcode project settings
- Or use a newer simulator/device

### Runtime Errors

**401 Unauthorized:**
- Token expired, logout and login again
- Check if backend auth is working

**Network request failed:**
- Verify backend URL in APIConfig.swift
- Check if backend is running
- Check network connectivity

## 📝 Testing

### Test Accounts
Create test users via the app registration or Django admin:
- Email: test@example.com
- Password: testpass123

### Test Flow
1. Launch app → See landing page
2. Tap "Get Started" → Login/Register
3. Submit a test report with photo
4. Track report using tracking ID
5. View in community feed
6. Check profile for stats

## 🔄 Refresh Data

All screens support pull-to-refresh:
- Pull down on any list view
- Data reloads from backend
- Latest changes appear

## 🎨 Customization

### Change Colors
Edit [Theme.swift](NagrikMitra2/Theme.swift):
```swift
struct Colors {
    static let emerald500 = Color(hex: "YOUR_COLOR")
    static let primary = emerald500
}
```

### Add New Features
1. Create new view file in Yantra26-app/
2. Add view to MainTabView or navigation
3. Update NetworkManager with any new API calls
4. Update Models with new data structures

## 📱 iOS Platform Features

- Native SwiftUI components
- iOS 16+ PhotosPicker
- System SF Symbols icons
- iOS keyboard handling
- Pull-to-refresh gestures
- Native alerts and sheets
- Async/await concurrency

## 🚢 Deployment

### TestFlight Beta
1. Archive app in Xcode
2. Upload to App Store Connect
3. Create TestFlight beta
4. Share test link with users

### App Store Release
1. Configure app metadata
2. Submit for review
3. Wait for approval
4. Release to App Store

## 📞 Support

For issues or questions:
- Check backend logs: `backend/logs/`
- Review Xcode console output
- Verify API responses with network debugging

## 🙏 Credits

Built with SwiftUI and connected to the JanSaathi Django backend platform for civic engagement.
