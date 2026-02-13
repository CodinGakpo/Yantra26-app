# ProfileView - Complete Context Summary

## Overview
ProfileView is the user profile management screen in the NagrikMitra iOS app, handling user identity display, Aadhaar verification, statistics, and report history.

---

## File Location
`/NagrikMitra2/NagrikMitra2/ProfileView.swift`

---

## Dependencies & Imports
```swift
import SwiftUI
@EnvironmentObject var authManager: AuthManager
```

---

## State Management

### State Variables
```swift
// Profile Data
@State private var profile: UserProfile?           // User's profile with Aadhaar info
@State private var reports: [Report] = []          // User's report history

// UI States
@State private var isLoading = false               // Loading indicator
@State private var showError = false               // Error alert flag
@State private var errorMessage = ""               // Error message content

// Aadhaar Verification States
@State private var showAadhaarVerification = false // Sheet presentation flag
@State private var aadhaarNumber = ""              // 12-digit Aadhaar input
@State private var isVerifyingAadhaar = false      // Verification process flag
```

---

## Data Models

### Input Model: UserProfile
```json
{
  "id": 1,
  "aadhaar": {
    "aadhaar_number": "121212121212",
    "full_name": "Avadhoot Ganesh Mahadik",
    "date_of_birth": "2026-02-15",
    "address": "12034 Tower 2 Prestige Waterford...",
    "gender": "M",
    "phone_number": "8792813340",
    "first_name": "Avadhoot",
    "middle_name": "Ganesh",
    "last_name": "Mahadik",
    "created_at": "2026-02-11T03:23:40.207895Z"
  },
  "is_aadhaar_verified": true,
  "created_at": "2026-02-10T21:10:00.593542Z",
  "updated_at": "2026-02-11T04:29:05.245561Z"
}
```

### Input Model: Report (Array)
```json
[
  {
    "id": 1,
    "user": 1,
    "issue_title": "Pothole on Main Street",
    "location": "123 Main St, City",
    "issue_description": "Large pothole...",
    "image_url": "reports/abc123-image.jpg",
    "completion_url": null,
    "issue_date": "2026-02-11T10:00:00Z",
    "status": "pending",
    "updated_at": "2026-02-11T10:00:00Z",
    "tracking_id": "A1B2C3D4",
    "department": "Public Works Department",
    "confidence_score": 0.95,
    "allocated_to": ""
  }
]
```

### Output Model: AadhaarVerificationRequest
```json
{
  "aadhaar_number": "121212121212"
}
```

---

## UI Components Structure

### 1. Header Section
**Location:** Top of view  
**Components:**
- Circular avatar with initials (derived from username/email)
- Username display (from `authManager.currentUser?.username`)
- Email display (from `authManager.currentUser?.email`)
- Verification status badge:
  - ✅ "Verified User" (green) if `profile.isAadhaarVerified == true`
  - ❌ "Not Verified" (orange) if `profile.isAadhaarVerified == false`

**Conditional Display (If NOT Verified):**
- "Verify Aadhaar" button → Opens verification sheet
- Prominent verification card with:
  - Orange warning icon
  - "Complete Your Profile" headline
  - "Verify your Aadhaar to submit civic reports" description
  - "Verify Aadhaar Now" button

**Conditional Display (If Verified):**
- Full name (from `profile.aadhaar?.fullName`)
- Phone number (from `profile.aadhaar?.phoneNumber`)

### 2. Statistics Grid
**Layout:** 2x2 Grid  
**Data Source:** Computed from `reports` array

**Stats Displayed:**
```swift
1. Total Reports: reports.count
2. Resolved: reports.filter { $0.status == "resolved" }.count
3. Pending: reports.filter { $0.status == "pending" }.count
4. Success Rate: (resolvedCount * 100) / reports.count
```

### 3. Report History Section
**Header:** "My Reports"  
**States:**
- Empty state: Shows "No reports yet" with icon
- Populated: Displays list of `ReportHistoryCard` components

**ReportHistoryCard Data:**
- Status badge (color-coded by status)
- Issue title
- Location with map pin icon
- Created/Updated date (formatted)

### 4. Logout Button
**Action:** `authManager.logout()`  
**Styling:** Red tinted button at bottom

---

## API Integrations

### 1. Load Profile Data
**Endpoint:** `GET /api/profile/me/`  
**Trigger:** On view appear + pull-to-refresh  
**Method:** `getUserProfile()`  
**Response:** UserProfile JSON (see Input Model above)  
**Error Handling:** Shows alert with error message

### 2. Load Report History
**Endpoint:** `GET /api/reports/history/`  
**Trigger:** On view appear + pull-to-refresh (parallel with profile)  
**Method:** `getUserHistory()`  
**Response:** Array of Report JSON (see Input Model above)  
**Error Handling:** Shows alert with error message

### 3. Verify Aadhaar
**Endpoint:** `POST /api/aadhaar/verify/`  
**Trigger:** User submits Aadhaar in verification sheet  
**Method:** `verifyAadhaar(aadhaarNumber: String)`  
**Request Body:**
```json
{
  "aadhaar_number": "121212121212"
}
```
**Response:**
```json
{
  "verified": true,
  "aadhaar_number": "121212121212",
  "aadhaar": { /* AadhaarData object */ },
  "profile": { /* UserProfile object */ },
  "error": null
}
```
**Success Flow:**
1. Closes verification sheet
2. Reloads profile data
3. UI updates to show verified state

**Error Flow:**
1. Shows error alert
2. Keeps sheet open for retry

---

## User Flows

### Flow 1: View Profile (Verified User)
```
1. User opens Profile tab
2. App loads profile + reports (parallel API calls)
3. Display:
   - User info with green verified badge
   - Full name and phone from Aadhaar
   - Statistics grid
   - Report history list
```

### Flow 2: Aadhaar Verification (Unverified User)
```
1. User opens Profile tab
2. App loads profile + reports
3. Orange verification card displayed prominently
4. User taps "Verify Aadhaar Now" button
5. Modal sheet appears with:
   - Verification explanation
   - 12-digit Aadhaar input field
   - Privacy notice
   - "Verify Aadhaar" button (disabled until 12 digits entered)
6. User enters Aadhaar number (auto-limited to 12 digits)
7. User taps "Verify Aadhaar"
8. Loading state shown during API call
9. On success:
   - Sheet dismisses
   - Profile reloads
   - UI updates to verified state
10. On error:
    - Error alert shown
    - Sheet remains open
```

### Flow 3: View Report History
```
1. Profile loads with reports
2. If empty: Shows "Submit your first report" empty state
3. If populated: Shows cards with:
   - Status badges (color-coded)
   - Issue titles
   - Locations
   - Dates (formatted from ISO8601)
```

### Flow 4: Refresh Data
```
1. User pulls down on ScrollView
2. Concurrent API calls:
   - getUserProfile()
   - getUserHistory()
3. UI updates with fresh data
```

---

## Helper Functions

### `getInitials() -> String`
**Purpose:** Generate 2-letter initials for avatar  
**Logic:**
1. Try username first: `username.prefix(2).uppercased()`
2. Fallback to email: `email.prefix(2).uppercased()`
3. Final fallback: `"U"`

### `verifyAadhaar()`
**Purpose:** Submit Aadhaar for verification  
**Steps:**
1. Set loading state
2. Call API with `aadhaarNumber`
3. Check response `verified` flag
4. If true: Close sheet, reload profile
5. If false: Show error message
6. Clear loading state

### `loadData() async`
**Purpose:** Load profile and reports concurrently  
**Steps:**
1. Set loading flag
2. Create parallel tasks:
   - `async let profileTask = NetworkManager.shared.getUserProfile()`
   - `async let reportsTask = NetworkManager.shared.getUserHistory()`
3. Await both results
4. Update state on MainActor
5. Handle errors with alert

### Computed Properties
```swift
resolvedCount: Int    // Count of reports with status == "resolved"
pendingCount: Int     // Count of reports with status == "pending"
successRate: Int      // Percentage: (resolvedCount * 100) / total
```

---

## Child Components

### StatBox
**Props:**
- `icon: String` - SF Symbol name
- `value: String` - Numeric value
- `label: String` - Description text

**Styling:**
- Emerald icon color
- Bold value text
- Gray label text
- White background card with shadow

### ReportHistoryCard
**Props:**
- `report: Report` - Full report object

**Display:**
- Status badge (top-right)
- Issue title (bold)
- Location with pin icon
- Formatted date

### StatusBadge
**Props:**
- `status: String` - Report status

**Color Mapping:**
- "resolved" → Green
- "in_progress" / "in progress" → Orange
- "pending" → Blue
- Default → Gray

### AadhaarVerificationSheet
**Props:**
- `aadhaarNumber: Binding<String>` - Two-way binding
- `isVerifying: Binding<Bool>` - Loading state
- `onVerify: () -> Void` - Callback function

**Features:**
- NavigationView with cancel button
- Shield icon with emerald color
- Instructional text
- 12-digit number pad input
- Privacy notice
- Submit button (enabled only when 12 digits entered)

---

## Design System Usage

### Colors
```swift
Theme.Colors.emerald600    // Primary actions
Theme.Colors.emerald50     // Light backgrounds
Theme.Colors.gray900       // Headlines
Theme.Colors.gray600       // Body text
Theme.Colors.gray500       // Captions
Theme.Colors.gray400       // Icons (disabled)
Theme.Colors.gray300       // Borders
Theme.Colors.surface       // White cards
Theme.Colors.background    // Light gray background
Theme.Colors.error         // Red for logout/errors
```

### Typography
```swift
.title2.bold()            // Main headlines
.title3.bold()            // Section headers
.subheadline.bold()       // Labels
.subheadline              // Body text
.caption                  // Small text
```

### Spacing
```swift
24pt  // Section spacing
16pt  // Card padding
12pt  // Element spacing
8pt   // Small gaps
```

### Corner Radius
```swift
16pt  // Large cards
12pt  // Buttons, inputs
20pt  // Status badges
```

---

## Error States

### Error Alert Display
**Trigger:** Any API call failure  
**UI:** Native iOS alert
**Content:**
- Title: "Error"
- Message: API error description
- Action: "OK" button (dismisses alert)

### Common Errors
1. **Network Error:** "Failed to connect to server"
2. **Unauthorized:** "Please login again"
3. **Aadhaar Verification Failed:** "Invalid Aadhaar number format" or custom message
4. **No Data:** Handled gracefully with empty states

---

## Loading States

### Initial Load
- `isLoading = true` during API calls
- No explicit spinner (uses native refresh control)

### Aadhaar Verification
- `isVerifyingAadhaar = true`
- Circular progress indicator in submit button
- Button disabled during verification

---

## Accessibility Features

- All text uses system fonts (Dynamic Type support)
- SF Symbols for icons (scale with text)
- Semantic labels on buttons
- High contrast color scheme
- Clear tap targets (minimum 44pt)

---

## Key Integration Points

### With AuthManager
```swift
authManager.currentUser?.username    // User display name
authManager.currentUser?.email       // Email display
authManager.logout()                 // Logout action
```

### With NetworkManager
```swift
NetworkManager.shared.getUserProfile()              // GET /api/profile/me/
NetworkManager.shared.getUserHistory()              // GET /api/reports/history/
NetworkManager.shared.verifyAadhaar(aadhaarNumber:) // POST /api/aadhaar/verify/
```

---

## Recent Updates Summary

1. ✅ **Added Aadhaar Verification UI**
   - Modal sheet for entering Aadhaar number
   - 12-digit validation
   - Privacy notice
   - Loading states

2. ✅ **Added Prominent Verification Card**
   - Orange warning card for unverified users
   - Displayed between header and stats
   - Clear call-to-action button

3. ✅ **Enhanced Profile Display**
   - Shows Aadhaar data when verified
   - Full name and phone number display
   - Better verification status indicators

4. ✅ **Fixed API Integration**
   - Added CodingKeys to Report model
   - Proper snake_case to camelCase mapping
   - Handles all profile response fields

5. ✅ **Improved User Experience**
   - Pull-to-refresh support
   - Empty state messaging
   - Error handling with alerts
   - Async/await for concurrent API calls

---

## Future Enhancement Opportunities

1. Add profile editing capabilities
2. Display more Aadhaar details (DOB, address, gender)
3. Add report filtering/sorting
4. Implement pagination for report history
5. Add profile picture upload
6. Show verification date/timestamp
7. Add report analytics/insights
8. Implement deep linking to specific reports

---

## Testing Checklist

- [ ] Profile loads correctly with verified Aadhaar
- [ ] Profile loads correctly without Aadhaar
- [ ] Verification card appears for unverified users
- [ ] Verification sheet opens and closes properly
- [ ] Aadhaar input limited to 12 digits
- [ ] Submit button disabled until 12 digits entered
- [ ] Successful verification updates UI
- [ ] Error handling works for failed verification
- [ ] Report history displays correctly
- [ ] Empty state shows when no reports
- [ ] Pull-to-refresh works
- [ ] Statistics calculate correctly
- [ ] Logout function works
- [ ] Date formatting displays properly
- [ ] Status badges show correct colors

---

This document provides complete context for understanding and working with ProfileView in the NagrikMitra iOS application.
