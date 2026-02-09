# ReportHub Mobile - React Native Android App

This is the React Native Android mobile application for ReportHub, migrated from the Vite + React web application.

## 📁 Project Structure

```
android-app/
├── src/
│   ├── shared/              # Shared business logic (reusable)
│   │   ├── api/            # API client and service modules
│   │   │   ├── apiClient.ts       # Axios client with interceptors
│   │   │   ├── userApi.ts         # User/auth API calls
│   │   │   └── reportApi.ts       # Report/issue API calls
│   │   ├── context/        # React Context providers
│   │   │   └── AuthContext.tsx    # Authentication state
│   │   └── utils/          # Utility functions
│   │       ├── storage.ts         # AsyncStorage wrapper
│   │       └── validation.ts      # Form validation helpers
│   ├── screens/            # Screen components
│   │   ├── LandingScreen.tsx      # Landing page (unauthenticated)
│   │   ├── LoginScreen.tsx        # Login screen
│   │   ├── RegisterScreen.tsx     # Registration screen
│   │   ├── CommunityScreen.tsx    # View all reports
│   │   ├── ReportScreen.tsx       # Submit new report
│   │   ├── TrackScreen.tsx        # Track report by ID
│   │   ├── ProfileScreen.tsx      # User profile
│   │   ├── HistoryScreen.tsx      # User's reports
│   │   └── IssueDetailsScreen.tsx # Report details
│   ├── navigation/         # Navigation configuration
│   │   └── RootNavigator.tsx      # Main navigation
│   ├── config/            # Configuration files
│   │   └── environment.ts         # Environment config
│   └── App.tsx            # Root app component
├── android/               # Android native code (generated)
├── package.json
├── tsconfig.json
└── README.md
```

## 🚀 Getting Started

### Prerequisites

1. **Node.js** (v18+)
2. **React Native CLI**
   ```bash
   npm install -g react-native-cli
   ```
3. **Android Studio**
   - Download from https://developer.android.com/studio
   - Install Android SDK (API 33 recommended)
   - Set up Android emulator
4. **Java Development Kit (JDK 17)**

### Environment Setup

1. **Set ANDROID_HOME environment variable:**
   ```bash
   # macOS/Linux (add to ~/.bash_profile or ~/.zshrc)
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

2. **Install dependencies:**
   ```bash
   cd android-app
   npm install
   ```

3. **Initialize React Native Android project:**
   ```bash
   npx react-native init ReportHubMobile --template react-native-template-typescript
   # Then copy src/ folder and configuration files
   ```

   OR manually create android folder:
   ```bash
   npx react-native@latest init ReportHubMobile --directory android-temp
   # Copy android/ folder to android-app/
   # Copy ios/ folder to android-app/ (optional)
   ```

### Running the App

1. **Start Django backend** (in separate terminal):
   ```bash
   cd backend
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Start Metro bundler:**
   ```bash
   cd android-app
   npm start
   ```

3. **Run on Android emulator** (in separate terminal):
   ```bash
   npm run android
   ```

## 🔧 Configuration

### API Base URL

The app is configured to connect to Django backend via:
- **Android Emulator**: `http://10.0.2.2:8000/api`
- **Physical Device**: Update [src/config/environment.ts](src/config/environment.ts) with your computer's IP address

```typescript
// src/config/environment.ts
export const API_BASE_URL = 'http://10.0.2.2:8000/api'; // Emulator
// export const API_BASE_URL = 'http://192.168.1.X:8000/api'; // Physical device
```

### Backend Setup

Ensure Django backend allows connections:

```python
# backend/report_hub/settings/base.py
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '10.0.2.2', '192.168.1.*']

CORS_ALLOWED_ORIGINS = [
    'http://localhost:8081',
    'http://10.0.2.2:8081',
]
```

## 📱 Key Components

### Authentication

- **AuthContext**: Manages user authentication state
- **Storage**: AsyncStorage wrapper for token management
- Uses JWT tokens (access + refresh)
- Automatic token refresh on 401 errors

### API Client

- **apiClient**: Axios instance with interceptors
- Automatic auth header injection
- Token refresh handling
- Error handling

### Navigation

- **React Navigation** with Stack and Tab navigators
- Protected routes for authenticated users
- Automatic navigation based on auth state

## 🎨 Styling

- Uses StyleSheet.create() instead of CSS
- Flexbox-based layouts
- Dark theme for auth screens
- Light theme for app screens

## 📝 TODO / Known Limitations

### High Priority
- [ ] **Generate Android native code** - Run `react-native init` to create android/ folder
- [ ] **Test on Android emulator** - Verify app builds and runs
- [ ] **Image upload to S3** - Implement image upload in ReportScreen
- [ ] **Maps integration** - Add react-native-maps for location picker

### Medium Priority
- [ ] **Google OAuth** - Implement using react-native-google-signin
- [ ] **Push notifications** - For report status updates
- [ ] **Error boundary** - Add error boundary component
- [ ] **Loading screen** - Add proper loading screen

### Low Priority
- [ ] **Animations** - Add micro-interactions
- [ ] **Dark mode** - Full dark mode support
- [ ] **Localization** - i18n support
- [ ] **Offline support** - Cache reports locally

## 🔄 Migration Notes

### Converted from Web

| Web | React Native | Notes |
|-----|--------------|-------|
| `div` | `View` | Container component |
| `span`, `p` | `Text` | Text component |
| `button` | `Pressable` | Button with press feedback |
| `img` | `Image` | Image component |
| `input` | `TextInput` | Input field |
| CSS | `StyleSheet` | Inline styles |
| `localStorage` | `AsyncStorage` | Async storage |
| `window.location` | `navigation.navigate()` | Navigation |
| React Router | React Navigation | Navigation library |

### Not Migrated

- **Google OAuth**: Requires react-native-google-signin setup
- **Maps**: Requires react-native-maps configuration
- **AI Image Classification**: Backend integration needed
- **3D animations**: GSAP/Three.js not compatible with React Native
- **Leaflet maps**: Use react-native-maps instead

## 🛠️ Development

### Adding a new screen

1. Create screen in `src/screens/`
2. Add route in `src/navigation/RootNavigator.tsx`
3. Import and use in navigation

### Adding a new API endpoint

1. Add method in appropriate API service (`src/shared/api/`)
2. Add TypeScript interfaces
3. Use in screen components

### Debugging

```bash
# View logs
npx react-native log-android

# Clear cache
npm start -- --reset-cache
```

## 🧪 Testing

```bash
# Run tests
npm test

# Run with coverage
npm test -- --coverage
```

## 📦 Building for Production

```bash
# Build release APK
cd android
./gradlew assembleRelease

# APK location:
# android/app/build/outputs/apk/release/app-release.apk
```

## 🤝 Contributing

1. Follow existing code structure
2. Use TypeScript for type safety
3. Add TODO comments for incomplete features
4. Keep components focused and reusable

## 📄 License

Same as parent project.

---

**Note**: This is an initial migration. Some features from the web app are not yet implemented and are marked with TODO comments throughout the codebase.
