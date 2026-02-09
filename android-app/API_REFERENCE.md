# API Endpoints Used by Mobile App

This document lists all the backend API endpoints that the React Native mobile app consumes.

## Base URL

- **Emulator**: `http://10.0.2.2:8000/api`
- **Physical Device**: `http://<YOUR_IP>:8000/api`

## Authentication Endpoints

### 1. Register
- **Endpoint**: `POST /users/register/`
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }
  ```
- **Response**:
  ```json
  {
    "access": "jwt_access_token",
    "refresh": "jwt_refresh_token"
  }
  ```

### 2. Login
- **Endpoint**: `POST /users/login/`
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Response**:
  ```json
  {
    "access": "jwt_access_token",
    "refresh": "jwt_refresh_token"
  }
  ```

### 3. Refresh Token
- **Endpoint**: `POST /users/token/refresh/`
- **Body**:
  ```json
  {
    "refresh": "jwt_refresh_token"
  }
  ```
- **Response**:
  ```json
  {
    "access": "new_jwt_access_token"
  }
  ```

### 4. Get Current User
- **Endpoint**: `GET /users/me/`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response**:
  ```json
  {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "is_verified": true
  }
  ```

### 5. Get User Profile
- **Endpoint**: `GET /users/profile/`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response**:
  ```json
  {
    "phone_number": "+1234567890",
    "address": "123 Main St",
    "is_aadhaar_verified": true
  }
  ```

### 6. Update Profile
- **Endpoint**: `PATCH /users/profile/`
- **Headers**: `Authorization: Bearer <access_token>`
- **Body**:
  ```json
  {
    "phone_number": "+1234567890",
    "address": "123 Main St"
  }
  ```

## Report Endpoints

### 1. Create Report
- **Endpoint**: `POST /report/`
- **Headers**: `Authorization: Bearer <access_token>`
- **Body**:
  ```json
  {
    "issue_title": "Broken streetlight",
    "location": "Main St & 1st Ave",
    "issue_description": "The streetlight has been broken for 3 days",
    "image_url": "https://s3.amazonaws.com/..."
  }
  ```
- **Response**:
  ```json
  {
    "id": 123,
    "tracking_id": "REP-20260209-XXXX",
    "issue_title": "Broken streetlight",
    "location": "Main St & 1st Ave",
    "issue_description": "...",
    "image_url": "...",
    "status": "submitted",
    "created_at": "2026-02-09T10:30:00Z"
  }
  ```

### 2. Get All Reports (Community)
- **Endpoint**: `GET /report/`
- **Response**: Array of reports
  ```json
  [
    {
      "id": 123,
      "issue_title": "Broken streetlight",
      "location": "Main St & 1st Ave",
      "status": "in_progress",
      "created_at": "2026-02-09T10:30:00Z"
    }
  ]
  ```

### 3. Get User's Reports (History)
- **Endpoint**: `GET /report/history/`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response**: Array of user's reports

### 4. Track Report by Tracking ID
- **Endpoint**: `GET /report/track/<tracking_id>/`
- **Example**: `GET /report/track/REP-20260209-XXXX/`
- **Response**: Single report object

### 5. Upload Image (if separate endpoint)
- **Endpoint**: `POST /report/upload/`
- **Headers**: 
  - `Authorization: Bearer <access_token>`
  - `Content-Type: multipart/form-data`
- **Body**: FormData with image file
- **Response**:
  ```json
  {
    "url": "https://s3.amazonaws.com/..."
  }
  ```

## Expected Backend Responses

### Success Response Format
```json
{
  "data": {},
  "message": "Success"
}
```

### Error Response Format
```json
{
  "detail": "Error message",
  "field_errors": {
    "email": ["This field is required"],
    "password": ["Password too short"]
  }
}
```

## HTTP Status Codes

- **200**: Success
- **201**: Created
- **400**: Bad Request (validation errors)
- **401**: Unauthorized (invalid/expired token)
- **403**: Forbidden (insufficient permissions)
- **404**: Not Found
- **500**: Internal Server Error

## Authentication Flow

1. User logs in → Receive access + refresh tokens
2. Store tokens in AsyncStorage
3. Add access token to all API requests
4. On 401 error → Attempt refresh with refresh token
5. If refresh succeeds → Retry original request
6. If refresh fails → Redirect to login

## CORS Configuration Required

The Django backend must allow requests from the React Native app:

```python
# settings.py
CORS_ALLOWED_ORIGINS = [
    'http://localhost:8081',
    'http://10.0.2.2:8081',
]

# Or for development:
CORS_ALLOW_ALL_ORIGINS = True
```

## Testing API Endpoints

### Using curl from terminal:
```bash
# Register
curl -X POST http://10.0.2.2:8000/api/users/register/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test1234","first_name":"Test","last_name":"User"}'

# Login
curl -X POST http://10.0.2.2:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test1234"}'

# Get current user
curl http://10.0.2.2:8000/api/users/me/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Using adb shell (from Android emulator):
```bash
adb shell
curl http://10.0.2.2:8000/api/users/me/
```

---

**Note**: Replace `10.0.2.2` with your computer's local IP if testing on a physical device.
