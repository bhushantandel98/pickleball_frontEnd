# API Contract Specification (PROPOSED)

**Project:** Pickleball Multi-Role Platform  
**Architecture:** Clean Architecture Client (Flutter 3.47.6) ↔ Spring Boot 3.x REST API  
**Status:** **PROPOSED** (Subject to backend engineering sign-off)  
**Last Updated:** 06 November 2026  
**Security Standard:** OAuth2 / JWT (Bearer Tokens), HTTPS/TLS 1.3, CSRF/XSS Protections  

---

## 1. Overview & Document Convention

This document specifies the canonical REST API contracts governing communication between the Flutter client application and the backend platform. All endpoints are currently marked as **PROPOSED** pending final backend architecture approval.

### Global Headers & Standards
- **Content-Type:** `application/json; charset=utf-8`
- **Accept:** `application/json`
- **Authorization:** `Bearer <jwt_access_token>` (for all authenticated endpoints)
- **Standard Error Schema:**
  ```json
  {
    "error": "ERROR_CODE",
    "message": "Human-readable explanation suitable for client UI display.",
    "statusCode": 400,
    "timestamp": "2026-11-06T12:00:00Z",
    "errors": {
      "field": "Specific validation failure reason"
    }
  }
  ```

---

## 2. Authentication & Identity Contracts

### 2.1 Password Login
- **Endpoint:** `POST /api/v1/auth/login`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210",
    "password": "SecurePassword123"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "userId": "usr_001",
    "phone": "+919876543210",
    "email": "player@example.com",
    "displayName": "Alex Rivera",
    "token": "jwt_access_token_sample",
    "refreshToken": "jwt_refresh_token_sample",
    "roles": ["player", "coach"],
    "isSuspended": false
  }
  ```
- **Error Responses:**
  - `401 Unauthorized`: Bad credentials (`INVALID_CREDENTIALS`)
  - `403 Forbidden`: Account suspended (`ACCOUNT_SUSPENDED`)
  - `422 Unprocessable Entity`: Invalid phone format (`VALIDATION_ERROR`)

---

### 2.2 Player Self-Registration
- **Endpoint:** `POST /api/v1/auth/register/player`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "fullName": "Rahul Sharma",
    "phone": "+919876543210",
    "password": "SecurePassword123"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "otpSessionId": "otp_sess_a1b2c3d4e5",
    "phone": "+919876543210",
    "resendCooldownSeconds": 30,
    "message": "OTP verification code sent successfully."
  }
  ```
- **Error Responses:**
  - `409 Conflict`: Phone already registered (`PHONE_ALREADY_EXISTS`)
  - `422 Unprocessable Entity`: Validation failure (`VALIDATION_ERROR`)

### 2.3 Registration OTP Verification
- **Endpoint:** `POST /api/v1/auth/register/verify-otp`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210",
    "otpSessionId": "otp_sess_a1b2c3d4e5",
    "otpCode": "123456"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "userId": "usr_reg_001",
    "phone": "+919876543210",
    "displayName": "Rahul Sharma",
    "roles": ["player"],
    "token": "jwt_access_token_sample",
    "message": "Player account registered successfully."
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Incorrect OTP code (`INVALID_OTP`)
  - `410 Gone`: Expired OTP code (`OTP_EXPIRED`)

### 2.4 Resend Registration OTP
- **Endpoint:** `POST /api/v1/auth/register/resend-otp`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210",
    "otpSessionId": "otp_sess_a1b2c3d4e5"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "otpSessionId": "otp_sess_b2c3d4e5f6",
    "phone": "+919876543210",
    "resendCooldownSeconds": 30,
    "message": "New OTP verification code sent."
  }
  ```
- **Error Responses:**
  - `429 Too Many Requests`: Resend cooldown active (`THROTTLED`)

---

### 2.5 Password Recovery (Forgot Password)

#### 2.5.1 Initiate Password Reset
- **Endpoint:** `POST /api/v1/auth/forgot-password/initiate`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "resetSessionId": "pwd_reset_sess_001",
    "phone": "+919876543210",
    "resendCooldownSeconds": 30,
    "message": "OTP sent for password reset verification."
  }
  ```
- **Error Responses:**
  - `404 Not Found`: Mobile number not registered (`USER_NOT_FOUND`)

#### 2.5.2 Verify Password Reset OTP
- **Endpoint:** `POST /api/v1/auth/forgot-password/verify-otp`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210",
    "resetSessionId": "pwd_reset_sess_001",
    "otpCode": "123456"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "resetSessionId": "pwd_reset_sess_001",
    "resetToken": "rst_tok_secure_token_abc123",
    "phone": "+919876543210",
    "message": "OTP verified. Proceed to set new password."
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Incorrect OTP code (`INVALID_OTP`)
  - `410 Gone`: Expired OTP code (`OTP_EXPIRED`)

#### 2.5.3 Resend Password Reset OTP
- **Endpoint:** `POST /api/v1/auth/forgot-password/resend-otp`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210",
    "resetSessionId": "pwd_reset_sess_001"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "resetSessionId": "pwd_reset_sess_002",
    "phone": "+919876543210",
    "resendCooldownSeconds": 30,
    "message": "New password reset code dispatched."
  }
  ```
- **Error Responses:**
  - `429 Too Many Requests`: Throttled (`THROTTLED`)

#### 2.5.4 Complete Password Reset
- **Endpoint:** `POST /api/v1/auth/forgot-password/reset`
- **Status:** **PROPOSED**
- **Authentication:** None (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210",
    "resetSessionId": "pwd_reset_sess_002",
    "resetToken": "rst_tok_secure_token_abc123",
    "newPassword": "NewSecurePassword123"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "phone": "+919876543210",
    "message": "Password has been reset successfully. Please sign in with your new password.",
    "timestamp": "2026-11-06T12:00:00Z"
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Password complexity failure (`VALIDATION_ERROR`)
  - `401 Unauthorized`: Invalid or expired reset token (`INVALID_TOKEN`)

---

## 3. Multi-Role Management & Context Contracts

### 3.1 Fetch Role Assignments
- **Endpoint:** `GET /api/v1/auth/roles`
- **Status:** **PROPOSED**
- **Authentication:** Required (`Bearer <jwt_access_token>`)
- **Query Parameters:** None
- **Headers:**
  - `Authorization: Bearer <jwt_access_token>`
- **Description:** Returns the complete list of assigned platform roles and organization-scoped assignments for the authenticated user account. Distinguishes multiple assignments of the same role across different organizations via unique `roleAssignmentId`.
- **Success Response (`200 OK`):**
  ```json
  {
    "userId": "usr_multi_001",
    "displayName": "Alex Rivera",
    "phone": "+919876543210",
    "email": "alex.rivera@example.com",
    "roles": [
      {
        "roleAssignmentId": "assign_player_001",
        "role": "player",
        "organizationId": null,
        "organizationName": null,
        "isActive": true,
        "description": "Book courts, join coaching programs, enter tournaments, and track match scores."
      },
      {
        "roleAssignmentId": "assign_vs_grand_slam",
        "role": "venue-staff",
        "organizationId": "org_venue_001",
        "organizationName": "Grand Slam Arena",
        "isActive": true,
        "description": "Oversee front-desk court check-ins, walk-in bookings, and facility operations."
      },
      {
        "roleAssignmentId": "assign_vs_metro_courts",
        "role": "venue-staff",
        "organizationId": "org_venue_002",
        "organizationName": "Metro Court Center",
        "isActive": true,
        "description": "Oversee front-desk court check-ins, walk-in bookings, and facility operations."
      }
    ],
    "preferredRoleAssignmentId": "assign_vs_grand_slam",
    "preferredRoleId": "venue-staff"
  }
  ```
- **Field Level Specification:**
  | Field | Type | Mandatory | Description |
  |---|---|---|---|
  | `userId` | `String` | Yes | Unique platform user ID |
  | `displayName` | `String` | Yes | User display name |
  | `phone` | `String` | Yes | Contact mobile number |
  | `email` | `String` | No | Registered email address |
  | `roles` | `Array<RoleProfileModel>` | Yes | Collection of role assignments |
  | `roles[].roleAssignmentId` | `String` | Yes | Unique identifier for this specific role assignment |
  | `roles[].role` | `String` | Yes | Canonical role string (e.g. `player`, `coach`, `venue-staff`) |
  | `roles[].organizationId` | `String` | No | ID of affiliated organization (null for individual roles) |
  | `roles[].organizationName` | `String` | No | Human-readable name of affiliated organization |
  | `roles[].isActive` | `Boolean` | Yes | Explicit status (`true` = active; `false`/null = disabled) |
  | `roles[].description` | `String` | No | Custom operational scope description |
  | `preferredRoleAssignmentId` | `String` | No | ID of user's saved default assignment |
  | `preferredRoleId` | `String` | No | Legacy role fallback identifier |
- **Error Responses:**
  - `401 Unauthorized`: Missing or expired Bearer token (`UNAUTHORIZED`)
  - `403 Forbidden`: Account suspended or access restricted (`FORBIDDEN`)
  - `500 Internal Server Error`: Server failure (`INTERNAL_ERROR`)

---

### 3.2 Save Preferred Role Assignment
- **Endpoint:** `PUT /api/v1/users/preferences/preferred-role`
- **Status:** **PROPOSED**
- **Authentication:** Required (`Bearer <jwt_access_token>`)
- **Headers:**
  - `Authorization: Bearer <jwt_access_token>`
  - `Content-Type: application/json`
- **Description:** Persists the user's preferred role assignment ID to skip role selection upon subsequent logins. Validates that the targeted `roleAssignmentId` belongs to the authenticated user and is currently active.
- **Request Body:**
  ```json
  {
    "roleAssignmentId": "assign_vs_grand_slam"
  }
  ```
- **Success Response (`200 OK`):**
  ```json
  {
    "userId": "usr_multi_001",
    "roleAssignmentId": "assign_vs_grand_slam",
    "role": "venue-staff",
    "message": "Preferred role assignment saved successfully.",
    "updatedAt": "2026-11-06T12:00:00Z"
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: `roleAssignmentId` missing or malformed (`VALIDATION_ERROR`)
  - `401 Unauthorized`: Unauthenticated request (`UNAUTHORIZED`)
  - `403 Forbidden`: The specified `roleAssignmentId` is not assigned to or not active for this user (`FORBIDDEN_ASSIGNMENT`)
  - `404 Not Found`: Role assignment not found (`ASSIGNMENT_NOT_FOUND`)

---

### 3.3 Clear Preferred Role Assignment
- **Endpoint:** `DELETE /api/v1/users/preferences/preferred-role`
- **Status:** **PROPOSED**
- **Authentication:** Required (`Bearer <jwt_access_token>`)
- **Headers:**
  - `Authorization: Bearer <jwt_access_token>`
- **Description:** Clears any saved preferred role assignment. On next login, multi-role users will be directed to the Role Selection interface to choose their active profile.
- **Success Response (`200 OK` or `204 No Content`):**
  ```json
  {
    "userId": "usr_multi_001",
    "message": "Preferred role assignment cleared successfully."
  }
  ```
- **Error Responses:**
  - `401 Unauthorized`: Unauthenticated request (`UNAUTHORIZED`)
  - `500 Internal Server Error`: Cache or database failure (`INTERNAL_ERROR`)
