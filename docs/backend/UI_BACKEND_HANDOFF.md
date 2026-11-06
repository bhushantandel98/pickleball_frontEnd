# UI to Backend Handoff Specification

**Project:** Pickleball Multi-Role Platform  
**Client Technology:** Flutter 3.47.6 (Mobile, Tablet & Responsive Web)  
**Target Backend:** Spring Boot 3.x (REST API / WebSocket)  
**Last Updated:** 04 November 2026  
**Document Status:** Active Handoff Reference  

---

## 1. Overview & Purpose

This document serves as the authoritative interface agreement between the Flutter frontend presentation layer and the Spring Boot backend services. It specifies the API contracts, data models, state workflows, authorization scopes, and backend assumptions required by each frontend screen as it is constructed.

---

## 2. Phase 1 — Identity & Shared Services

### 2.1 Welcome / App Entry Screen (`WelcomePage`)

#### Screen Metadata
- **Route Path:** `/auth/welcome` (`AppRoutes.welcome`)
- **Primary Purpose:** Initial entry gate for unauthenticated visitors. Introduces the Pickleball brand, communicates core multi-role value propositions, and routes visitors into either the authentication (Login) or onboarding (Registration) pipelines.
- **Access Level:** Public / Unauthenticated.
- **Supported Form Factors:** Mobile (portrait/landscape), Tablet, Desktop Web.

#### UI Elements & Interactive Actions
1. **Brand Logo Emblem (`BrandLogoEmblem`):**
   - Signature court-green emblem with pickleball paddle and court ball motif.
   - Purely presentational; no interactive triggers.
2. **Welcome Heading & Value Proposition:**
   - Heading: `"Welcome to Pickleball"`
   - Subtitle: Unified platform description connecting players, coaches, academies, venues, and tournament organizers.
   - Feature Highlights: 12 unified roles, venue court booking, tournament live scoring.
3. **Primary Action: "Sign In" Button (`AppButton.primary`):**
   - Action: Navigates visitor to the Login route (`/auth/login`).
   - Trigger: User click / tap.
4. **Secondary Action: "Create Account" Button (`AppButton.outline`):**
   - Action: Navigates visitor to the Registration route (`/auth/register`).
   - Trigger: User click / tap.
5. **Legal & Trust Footnote:**
   - Informs visitors about Terms of Service and Privacy Policy applicability.

#### Navigation Destinations
| Source Screen | Trigger Action | Destination Route | Destination Screen Description |
|---|---|---|---|
| `/auth/welcome` | Click "Sign In" | `/auth/login` | Phone / Password login screen |
| `/auth/welcome` | Click "Create Account" | `/auth/register` | Self-service registration & OTP verification |

#### API Requirements
- **Direct API Required:** **No**.
- This screen is an entirely static, presentation-only landing view. It does not issue network requests or read persisted session credentials.

#### Future Backend Dependencies (Downstream Screens)
While `/auth/welcome` has no direct backend calls, its navigation actions route into screens that require backend endpoints:
1. **Login Flow (`/auth/login`):**
   - **Endpoint:** `POST /api/v1/auth/login`
   - **Payload:** `{ "identifier": "phone_or_email", "password": "...", "deviceId": "..." }`
   - **Response:** `{ "accessToken": "JWT", "refreshToken": "JWT", "user": { "id": "...", "roles": [...] } }`
2. **Registration Flow (`/auth/register`):**
   - **Endpoint:** `POST /api/v1/auth/register/initiate` & `POST /api/v1/auth/register/verify-otp`
   - **Payload:** `{ "phone": "+1...", "fullName": "...", "role": "PLAYER" }`
3. **App Configuration / Feature Flags (Optional Future Enhancement):**
   - If dynamic branding, announcements, or server maintenance mode are required in future iterations, a lightweight bootstrap endpoint (`GET /api/v1/public/app-config`) may be queried prior to rendering.

#### Architectural Assumptions & Security Controls
1. **Unauthenticated Access Guarantee:** The `/auth/welcome` path is explicitly whitelisted in `AuthRouteGuard` (`CompositeRouteGuard`) so unauthenticated visitors are never redirected away from it.
2. **Auto-Redirect for Authenticated Users:** If a visitor with a valid, active session lands on `/auth/welcome`, `AuthEntryRedirectGuard` automatically redirects them to their active role's dashboard (e.g., `/player/dashboard` or `/role-selection`).
3. **Zero Credential Storage:** This screen does not cache or retain user inputs.

---

### 2.2 Phone & Password Login Screen (`LoginPage`)

#### Screen Metadata
- **Route Path:** `/auth/login` (`AppRoutes.login`)
- **Primary Purpose:** Authenticates registered users via their mobile number and password. Single entry point for all 12 platform roles. Delivers user identity and available assigned roles for downstream role routing.
- **Access Level:** Public / Unauthenticated.
- **Supported Form Factors:** Mobile (portrait/landscape), Tablet, Desktop Web (card-centered layout max 640dp).

#### Screen Fields & Field Types
| Field | UI Component | Input Type | Validation Rules | Default / Format |
|---|---|---|---|---|
| **Country Code** | Non-editable prefix / selector | Text | Mandatory | `+91` (India) |
| **Mobile Number** | `AppTextField` | Numeric (`TextInputType.phone`) | Mandatory; Exactly 10 digits; Starts with 6, 7, 8, or 9; Non-digit characters stripped | e.g., `9876543210` |
| **Password** | `AppTextField.password` | Obscured (`TextInputType.visiblePassword`) | Mandatory; Non-empty | Password string with visibility toggle |

#### Frontend Validation Rules
1. **Mobile Number:**
   - Empty input: `"Mobile number is required"`
   - Non-matching Indian regex (`^[6-9]\d{9}$`): `"Enter a valid 10-digit Indian mobile number"`
2. **Password:**
   - Empty input: `"Password is required"`
3. **Submission Behavior:**
   - Inline error messages appear beneath inputs when validation fails.
   - Form submission is blocked until both fields are valid.

#### Login Button Behavior & State Transitions
- **Initial State (`LoginInitial`):** "Sign In" button is enabled; inputs are editable.
- **Submitting State (`LoginLoading`):**
  - "Sign In" button shows an integrated loading spinner.
  - Inputs and links are disabled to prevent duplicate submissions.
- **Failure State (`LoginFailure`):**
  - Error banner displays at the top of the form with an error icon and human-readable message.
  - Form remains populated for correction without wiping user inputs.
- **Success State (`LoginSuccess`):**
  - Emits authenticated `AuthSession`.
  - Next navigation trigger executes immediately.

#### Proposed API Contract (Awaiting Backend Confirmation)

> [!IMPORTANT]
> **API Status: PROPOSED — PENDING BACKEND CONFIRMATION**  
> The endpoint, request schema, and response format below are proposed by the frontend architecture. Backend engineers must review, adjust, and formalize this agreement.

##### Proposed Endpoint
`POST /api/v1/auth/login`

##### Proposed Request Payload
```json
{
  "phone": "+919876543210",
  "password": "UserSuppliedPassword"
}
```

##### Proposed Success Response (`200 OK`)
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "dGhpcy1pcy1hLXJlZnJlc2gtdG9rZW4...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": "usr_789456123",
    "name": "Alex Rivera",
    "phone": "+919876543210",
    "email": "alex.rivera@example.com",
    "roles": ["player", "coach", "referee"],
    "activeRole": null,
    "isSuspended": false
  }
}
```

##### Proposed Error Responses
- **`401 Unauthorized` (Invalid Credentials):**
```json
{
  "error": "UNAUTHORIZED",
  "message": "Invalid mobile number or password. Please verify your credentials."
}
```
- **`403 Forbidden` (Suspended Account):**
```json
{
  "error": "ACCOUNT_SUSPENDED",
  "message": "Your account has been suspended. Please contact platform support."
}
```
- **`422 Unprocessable Entity` (Validation Error):**
```json
{
  "error": "VALIDATION_FAILED",
  "message": "Invalid request payload format.",
  "errors": {
    "phone": "Invalid mobile number format."
  }
}
```
- **`500 Internal Server Error` (Server Failure):**
```json
{
  "error": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected server error occurred. Please try again later."
}
```

#### Authentication & Token Requirements Still Requiring Agreement
1. **Token Refresh Strategy:** Agreement needed on whether `refreshToken` is delivered in JSON body or as an HTTP-only secure cookie.
2. **Access Token Lifespan:** Frontend proposes 1 hour (`3600` seconds).
3. **Rate Limiting & Lockout:** Agreement needed on maximum login retry attempts before temporary throttling/lockout.
4. **Device Tracking:** Whether optional `deviceId` and `deviceType` headers/fields should be passed during login.
5. **Multi-Role Role Assignment Representation:** Agreement that `roles` is an array of standardized string identifiers (`["player", "coach", "academy", "venue-partner", ...]`).

#### Next Screen & Navigation Expectations
1. **Developmental Stage Placeholder (`/auth/login-success`):** In the current developmental slice, successful mock login navigates to a temporary placeholder destination (`/auth/login-success`) via `AppRoutes.loginSuccess`. Real role selection and session persistence remain uncoupled until subsequent phases.
2. **Production Role Routing (Post-Role-Selection Integration):**
   - **Multi-Role User (`availableRoles.length > 1`):** Navigates to `/role-selection` to allow user to pick their operational context (or restore remembered role in later phases).
   - **Single-Role User (`availableRoles.length == 1`):** Directly navigates to that role's default dashboard (e.g., `/player/dashboard`).
3. **Empty Role Handling:** The client does not invent or assume fallback roles (e.g. `player`). If the backend returns an empty `roles` array, `availableRoles` is preserved as empty and access is not granted.
4. **Suspended Account (`isSuspended == true`):** Immediately blocked and redirected to `/account-suspended`.
5. **Forgot Password Link:** Navigates to placeholder route `/auth/forgot-password`.
6. **Create Account Link:** Navigates to registration route `/auth/register`.

---

### 2.3 Player Self-Registration & OTP Verification Screen (`RegisterPage`)

#### Screen Metadata
- **Route Path:** `/auth/register` (`AppRoutes.register`)
- **Primary Purpose:** Self-service registration gateway exclusively for independent **Player** profiles per Player PRD v1.6 and Frontend FSD. Allows players to register their full name, mobile number, and password, dispatch and verify an SMS OTP, and confirm their active Player role.
- **Access Level:** Public / Unauthenticated.
- **Supported Form Factors:** Mobile (portrait/landscape), Tablet, Desktop Web (card-centered layout max 640dp).

#### Multi-Step Workflow
The registration flow is managed within a single stateful route via `RegisterStep`:
1. **Step 1: Registration Form (`RegisterStep.form`):**
   - Visitor enters full name, 10-digit Indian mobile number (`+91`), password, and password confirmation.
   - Submission initiates registration and requests OTP dispatch from backend.
2. **Step 2: OTP Verification (`RegisterStep.otpVerification`):**
   - Displays destination mobile number with "Change" button returning to Step 1 with form data preserved.
   - 6-digit OTP code input field.
   - 30-second visible countdown timer disabling resend until expired.
   - Resend OTP trigger when timer reaches 0s.
   - Inline error handling for invalid or expired OTP codes.
3. **Step 3: Registration Success (`RegisterStep.success`):**
   - Confirmation message verifying the mobile number and account creation.
   - Role badge explicitly confirming independent **Player Role** assignment (`UserRole.player`).
   - Organizational role disclaimer: Explains that Academy, Venue, Coach, and Tournament roles require separate administrative onboarding or invitations.
   - Primary "Proceed to Sign In" CTA navigating to `/auth/login`.

#### Screen Fields & Validation Rules
| Field | UI Component | Input Type | Validation Rules | Default / Format |
|---|---|---|---|---|
| **Full Name** | `AppTextField` | Text (`TextInputType.name`) | Mandatory; Min 2 characters | User's full name |
| **Country Code** | Non-editable prefix | Text | Mandatory | `+91` (India) |
| **Mobile Number** | `AppTextField` | Numeric (`TextInputType.phone`) | Mandatory; Exactly 10 digits; Starts with 6, 7, 8, or 9; Non-digit characters stripped | e.g., `9876543210` |
| **Password** | `AppTextField.password` | Obscured (`TextInputType.visiblePassword`) | Mandatory; Min 8 characters; Must contain at least one letter and one number | Password string with visibility toggle |
| **Confirm Password** | `AppTextField.password` | Obscured (`TextInputType.visiblePassword`) | Mandatory; Must match Password exactly | Password string with visibility toggle |
| **OTP Code** | `AppTextField` | Numeric (`TextInputType.number`) | Mandatory; Exactly 6 digits | 6-digit numeric string |

#### Proposed API Contracts (Awaiting Backend Confirmation)

> [!IMPORTANT]
> **API Status: PROPOSED — PENDING BACKEND CONFIRMATION**  
> The endpoints, request payloads, and response structures below are proposed by the Flutter client. Spring Boot backend services must review and formalize these interfaces.

##### 1. Initiate Registration & Dispatch OTP
**Endpoint:** `POST /api/v1/auth/register/initiate`

**Proposed Request Payload:**
```json
{
  "fullName": "Rohit Sharma",
  "phone": "9876543210",
  "countryCode": "+91",
  "password": "Password123",
  "role": "player"
}
```

**Proposed Success Response (`200 OK` or `201 Created`):**
```json
{
  "otpSessionId": "otp_sess_a1b2c3d4e5",
  "phone": "+919876543210",
  "resendCooldownSeconds": 30,
  "expiresInSeconds": 300,
  "message": "OTP sent successfully to +919876543210."
}
```

**Proposed Error Responses:**
- **`409 Conflict` (Duplicate Mobile Number):**
  ```json
  {
    "error": "PHONE_ALREADY_REGISTERED",
    "message": "An account with this mobile number already exists. Please sign in instead."
  }
  ```
- **`422 Unprocessable Entity` (Validation Error):**
  ```json
  {
    "error": "VALIDATION_FAILED",
    "message": "Validation failed for registration parameters.",
    "errors": {
      "phone": "Invalid mobile number format.",
      "password": "Password must be at least 8 characters and contain letters and numbers."
    }
  }
  ```

##### 2. Verify OTP & Finalize Registration
**Endpoint:** `POST /api/v1/auth/register/verify-otp`

**Proposed Request Payload:**
```json
{
  "otpSessionId": "otp_sess_a1b2c3d4e5",
  "phone": "+919876543210",
  "otp": "123456",
  "fullName": "Rohit Sharma",
  "password": "Password123"
}
```

**Proposed Success Response (`200 OK`):**
```json
{
  "userId": "usr_new_987654321",
  "phone": "+919876543210",
  "fullName": "Rohit Sharma",
  "assignedRole": "player",
  "isVerified": true,
  "message": "Registration completed successfully."
}
```

**Proposed Error Responses:**
- **`400 Bad Request` (Invalid OTP):**
  ```json
  {
    "error": "INVALID_OTP",
    "message": "The OTP entered is incorrect. Please check the code and try again."
  }
  ```
- **`410 Gone` (Expired OTP):**
  ```json
  {
    "error": "OTP_EXPIRED",
    "message": "This OTP has expired. Please request a new verification code."
  }
  ```

##### 3. Resend OTP
**Endpoint:** `POST /api/v1/auth/register/resend-otp`

**Proposed Request Payload:**
```json
{
  "otpSessionId": "otp_sess_a1b2c3d4e5",
  "phone": "+919876543210"
}
```

**Proposed Success Response (`200 OK`):**
```json
{
  "otpSessionId": "otp_sess_f6g7h8i9j0",
  "phone": "+919876543210",
  "resendCooldownSeconds": 30,
  "expiresInSeconds": 300,
  "message": "New OTP dispatched successfully."
}
```

**Proposed Error Responses:**
- **`429 Too Many Requests` (Rate Limited):**
  ```json
  {
    "error": "RATE_LIMIT_EXCEEDED",
    "message": "Too many OTP requests. Please wait before requesting another code.",
    "retryAfterSeconds": 60
  }
  ```

#### Security & Business Architecture Questions Needing Agreement
1. **Password Retention vs Two-Step Registration:** Does the backend require password submission at step 1 (`/initiate`) or only upon step 2 (`/verify-otp`)? The frontend passes credentials to both steps cleanly.
2. **Session Identification:** Whether an explicit `otpSessionId` is returned and required, or if the user's formatted `phone` serves as the primary session key. The Flutter client explicitly stores and updates `otpSessionId` upon every resend response, ensuring subsequent verification requests submit the latest active session ID.
3. **Auto-Login vs Forced Sign In:** Current PRD indicates directing users to Sign In upon completion. If backend returns access/refresh tokens in the `/verify-otp` response, frontend can support direct entry.
4. **SMS Gateway Rate Limits:** Agreement on maximum resend attempts per phone number per hour.

---

### 2.4 Password Recovery / Forgot Password Flow (`ForgotPasswordPage`)

#### Screen Metadata
- **Route Path:** `/auth/forgot-password` (`AppRoutes.forgotPassword`)
- **Primary Purpose:** Self-service password recovery flow for registered users who have forgotten their credentials. Allows account identity verification via SMS OTP, validated password reset, and returning to Sign In with updated credentials.
- **Access Level:** Public / Unauthenticated.
- **Supported Form Factors:** Mobile (portrait/landscape), Tablet, Desktop Web (card-centered layout max 640dp).

#### Multi-Step Workflow
The password recovery flow is managed within a single stateful route via `ForgotPasswordState`:
1. **Step 1: Enter Mobile Number (`ForgotPasswordPhoneState`):**
   - User enters 10-digit Indian mobile number (`+91`).
   - Submission initiates recovery by checking account existence and requesting an OTP verification code.
   - "Sign In" link allows immediate return to the Login screen.
2. **Step 2: OTP Verification (`ForgotPasswordOtpState`):**
   - Displays destination mobile number with "Change" button returning to Step 1 with phone preserved.
   - 6-digit OTP code input field.
   - 30-second visible countdown timer disabling resend until expired.
   - Resend OTP trigger when timer reaches 0s.
   - Dedicated password-reset OTP verification distinguishable from registration OTP.
3. **Step 3: Set New Password (`ForgotPasswordNewPasswordState`):**
   - New password input with obscurity toggle.
   - Confirm new password input with obscurity toggle.
   - Client enforces minimum 8 characters, alphanumeric requirement, and matching passwords.
   - Submits using verified `resetToken` and `resetSessionId`.
4. **Step 4: Password Reset Success (`ForgotPasswordSuccessState`):**
   - Success icon, confirmation heading, and verified mobile account container.
   - "Sign In with New Password" CTA navigating to `/auth/login`.

#### Screen Fields & Validation Rules
| Field | UI Component | Input Type | Validation Rules | Default / Format |
|---|---|---|---|---|
| **Mobile Number** | `AppTextField` | Numeric (`TextInputType.phone`) | Mandatory; Exactly 10 digits; Starts with 6, 7, 8, or 9; Non-digit characters stripped | e.g., `9876543210` |
| **Country Code** | Non-editable prefix | Text | Mandatory | `+91` (India) |
| **OTP Code** | `AppTextField` | Numeric (`TextInputType.number`) | Mandatory; Exactly 6 digits | 6-digit numeric string |
| **New Password** | `AppTextField.password` | Obscured (`TextInputType.visiblePassword`) | Mandatory; Min 8 characters; At least one letter and one number | Password string with visibility toggle |
| **Confirm New Password** | `AppTextField.password` | Obscured (`TextInputType.visiblePassword`) | Mandatory; Must match New Password exactly | Password string with visibility toggle |

#### Proposed API Contracts (Awaiting Backend Confirmation)

> [!IMPORTANT]
> **API Status: PROPOSED — PENDING BACKEND CONFIRMATION**  
> The endpoints, request payloads, and response structures below are proposed by the Flutter client. Spring Boot backend services must review and formalize these interfaces.

##### 1. Initiate Password Reset & Dispatch OTP
**Endpoint:** `POST /api/v1/auth/forgot-password/initiate`

**Proposed Request Payload:**
```json
{
  "phone": "+919876543210",
  "countryCode": "+91"
}
```

**Proposed Success Response (`200 OK`):**
```json
{
  "resetSessionId": "pwd_reset_sess_a1b2c3d4e5",
  "phone": "+919876543210",
  "resendCooldownSeconds": 30,
  "expiresInSeconds": 300,
  "message": "Password reset code dispatched to +919876543210."
}
```

**Proposed Error Responses:**
- **`404 Not Found` (Account Does Not Exist):**
  ```json
  {
    "error": "ACCOUNT_NOT_FOUND",
    "message": "No account found associated with this mobile number. Please check the number or create an account."
  }
  ```
- **`422 Unprocessable Entity` (Validation Error):**
  ```json
  {
    "error": "VALIDATION_FAILED",
    "message": "Enter a valid 10-digit Indian mobile number."
  }
  ```

##### 2. Resend Password Reset OTP
**Endpoint:** `POST /api/v1/auth/forgot-password/resend-otp`

**Proposed Request Payload:**
```json
{
  "phone": "+919876543210",
  "resetSessionId": "pwd_reset_sess_a1b2c3d4e5"
}
```

**Proposed Success Response (`200 OK`):**
```json
{
  "resetSessionId": "pwd_reset_sess_f6g7h8i9j0",
  "phone": "+919876543210",
  "resendCooldownSeconds": 30,
  "expiresInSeconds": 300,
  "message": "New password reset OTP dispatched successfully."
}
```

##### 3. Verify Password Reset OTP
**Endpoint:** `POST /api/v1/auth/forgot-password/verify-otp`

**Proposed Request Payload:**
```json
{
  "phone": "+919876543210",
  "otp": "123456",
  "resetSessionId": "pwd_reset_sess_f6g7h8i9j0"
}
```

**Proposed Success Response (`200 OK`):**
```json
{
  "phone": "+919876543210",
  "resetSessionId": "pwd_reset_sess_f6g7h8i9j0",
  "resetToken": "rst_tok_secure_token_abc123",
  "expiresInSeconds": 600,
  "message": "Code verified. You may now set a new password."
}
```

**Proposed Error Responses:**
- **`400 Bad Request` (Invalid Code):**
  ```json
  {
    "error": "INVALID_OTP",
    "message": "Invalid verification code. Please check and try again."
  }
  ```
- **`410 Gone` (Expired Code):**
  ```json
  {
    "error": "OTP_EXPIRED",
    "message": "Verification code has expired. Please request a new code."
  }
  ```

##### 4. Complete Password Reset
**Endpoint:** `POST /api/v1/auth/forgot-password/reset`

**Proposed Request Payload:**
```json
{
  "phone": "+919876543210",
  "resetSessionId": "pwd_reset_sess_f6g7h8i9j0",
  "resetToken": "rst_tok_secure_token_abc123",
  "newPassword": "NewSecurePassword123"
}
```

**Proposed Success Response (`200 OK`):**
```json
{
  "phone": "+919876543210",
  "message": "Password has been reset successfully. Please sign in with your new password.",
  "timestamp": "2026-11-06T11:30:00Z"
}
```

#### Open Questions Requiring Backend Agreement
1. **Reset Token vs Session ID:** Does the backend require a distinct `resetToken` returned from `/verify-otp`, or is the validated `resetSessionId` sufficient to authorize the subsequent password commit? The frontend client preserves both.
2. **Account Enumeration Protection:** Should the backend return generic messages for unregistered mobile numbers (e.g. `200 OK: Code sent if account exists`) rather than `404 Not Found` to prevent account scraping? The frontend easily supports either approach without UI modifications.
3. **Auto-Login Post Reset:** PRD indicates routing to Sign In upon completion. If backend delivers auth tokens upon password reset, direct auto-login can be supported.

---

### 2.5 Multi-Role Selection & Dashboard Routing (`RoleSelectionPage`)

#### Screen Metadata
- **Route Path:** `/role-selection` (`AppRoutes.roleSelection`)
- **Primary Purpose:** Resolves and activates the operational role context for authenticated accounts. For single-role users, automatically routes them directly to their role dashboard. For multi-role users, presents a polished, responsive role selection interface detailing assigned roles, organizational scopes (academies, venues, tournaments), and role descriptions, with optional persistent preferred-role remembering. For zero-role accounts, renders an empty state preventing unauthorized platform entry.
- **Access Level:** Authenticated (`AuthRouteGuard` requires authenticated session; `ActiveRoleGuard` whitelists `/role-selection`).
- **Supported Form Factors:** Mobile (portrait/landscape), Tablet, Desktop Web (constrained card layout, max-width 640dp).

#### UI Elements & Interactive Architecture

##### 1. Role Information Displayed
For each authorized platform role, the selection UI renders:
- **Role Display Name:** Formatted title (e.g. `Player`, `Coach`, `Academy Admin`, `Tournament Organizer`).
- **Role Icon:** Canonical Material 3 outlined icon reflecting operational purpose (`UserRole.icon`).
- **Role Description:** Clear explanation of duties and actions available in that role context (`RoleProfile.description`).
- **Active Role Counter:** Badge in user identity header displaying total active platform roles (e.g. `3 Roles`).

##### 2. Organization & Tournament Assignment Information
When a role is scoped to a specific entity or event, dedicated badges are displayed:
- **Organization Badge (`AppChip.neutral`):** Displays parent academy, venue, or organizer name (e.g. `"Pinnacle Sports Academy"`, `"Grand Slam Arena"`, `"Pacific Pickleball Series"`, `"Apex Paddle & Gear Co."`).
- **Tournament Badge (`AppChip.info`):** Displays sanctioned tournament or league name (e.g. `"Mumbai Pickleball Championship 2026"`, `"Monsoon Open 2026"`).
- **Same-Role Disambiguation:** A user holding identical roles across multiple organizations or tournaments (e.g., Venue Staff at two different venues, or Tournament Staff at two different tournaments) receives distinct cards uniquely keyed by `roleAssignmentId`.

##### 3. Selection Behavior
- **Card Tap (Immediate Entry):** Tapping the role card body selects the assignment, updates the session context, and immediately routes to the corresponding dashboard.
- **Radio Button Tap (Deliberate Selection):** Tapping the radio button updates `selectedAssignmentId` and dynamically updates the **Active Context Summary Banner** without immediately leaving the screen.
- **Active Context Summary Banner:** Displays a prominent highlighted pill above the primary CTA indicating the currently selected operating context (e.g. `Active Context: Coach • Pinnacle Sports Academy`).
- **Primary CTA ("Continue to Dashboard"):** Commits the currently selected role assignment and routes to the dashboard.
- **Single-Role Auto-Continue:** Users possessing exactly 1 active role bypass the selection screen on initial session load and navigate directly to their dashboard. If navigated with `?switchRole=true` or `?bypass=true`, the selection UI is presented.
- **Zero-Role Empty State (`RoleSelectionEmpty`):** Renders when an account has 0 active roles. Displays a clear message explaining that no roles are assigned, offering "Create Player Account" and "Sign Out" actions. The platform **never** automatically assigns fallback roles.

##### 4. "Remember My Choice" Preference Behavior
- **Adaptive Switch:** `SwitchListTile.adaptive` allows the user to persist their preferred role assignment.
- **Client Storage:** Stored via `RolePreferenceStorage` (in-memory for mock/tests, `SharedPreferences` on device).
- **Auto-Continuation:** Subsequent session startups automatically bypass selection and navigate to the remembered assignment's dashboard.
- **Revocation Fallback Protection:** If a saved `roleAssignmentId` is revoked or modified by Platform Admin, the platform safely detects the discrepancy and falls back to the full selection screen without granting unauthorized access.

##### 5. Canonical Dashboard Destinations (All 12 Platform Roles)
Mapped centrally via `RoleDashboardRouter` (`lib/core/router/role_dashboard_router.dart`):

| Role # | Platform Role | Role ID (`UserRole.id`) | Canonical Dashboard Route | Organization / Event Context |
|---|---|---|---|---|
| 1 | Player | `player` | `/player/dashboard` | None (Individual Player) |
| 2 | Coach | `coach` | `/coach/dashboard` | Optional Academy affiliation |
| 3 | Academy Admin | `academy` | `/academy/dashboard` | Academy Entity (`organizationId`) |
| 4 | Academy Staff | `academy-staff` | `/academy-staff/dashboard` | Academy Entity (`organizationId`) |
| 5 | Venue Partner | `venue-partner` | `/venue-partner/dashboard` | Venue Entity (`organizationId`) |
| 6 | Venue Staff | `venue-staff` | `/venue-staff/dashboard` | Venue Entity (`organizationId`) |
| 7 | Tournament Organizer | `tournament-organizer` | `/tournament-organizer/dashboard` | Organizer Entity (`organizationId`, `tournamentId`) |
| 8 | Tournament Staff | `tournament-staff` | `/tournament-staff/dashboard` | Organizer Entity (`organizationId`, `tournamentId`) |
| 9 | Referee | `referee` | `/referee/dashboard` | Independent Association / Officiating |
| 10 | Marketplace Seller | `marketplace-seller` | `/marketplace-seller/dashboard` | Seller Business Entity (`organizationId`) |
| 11 | Application Staff | `application-staff` | `/application-staff/dashboard` | Platform Operations |
| 12 | Application Admin | `application-admin` | `/application-admin/dashboard` | Global Governance |

##### 6. Data Fields the Future Backend Must Provide
The future REST API endpoint (`GET /api/v1/auth/roles`) must provide the following fields per user profile:

| Field Name | Type | Nullable | Purpose / UI Mapping |
|---|---|---|---|
| `userId` | String (UUID) | No | Authenticated account identifier. |
| `displayName` | String | No | Displayed in user identity header card. |
| `phone` | String | No | Formatted contact phone displayed in header. |
| `email` | String | Yes | Account email address displayed if present. |
| `preferredRoleAssignmentId` | String | Yes | Server-remembered assignment identifier. |
| `roles` | Array | No | Collection of assigned role profile objects. |
| `roles[].roleAssignmentId` | String | No | Globally unique identifier for this specific role assignment context. |
| `roles[].role` | String | No | Standardized string identifier matching one of the 12 platform roles. |
| `roles[].organizationId` | String | Yes | Unique ID of the associated academy, venue, or organizer entity. |
| `roles[].organizationName` | String | Yes | Human-readable name displayed as an organization badge (`AppChip.neutral`). |
| `roles[].tournamentId` | String | Yes | Unique ID of the associated tournament or event series. |
| `roles[].tournamentName` | String | Yes | Human-readable name displayed as a tournament badge (`AppChip.info`). |
| `roles[].isActive` | Boolean | No | Explicit active status flag. Must be strictly `true` for the role to be selectable. |
| `roles[].description` | String | Yes | Custom role operational instructions (falls back to platform defaults). |

##### 7. Business Rules & Authorization Requirements
1. **Admin Governance:** Users cannot assign roles to themselves. All operational roles are provisioned by Application Admin or authorized Organization Admins.
2. **Strict Active Validation:** Incomplete, revoked, or unverified roles (`isActive: false` or missing) are never selectable and must not grant dashboard entry.
3. **No Automatic Role Inventing:** If an account has zero active roles, the frontend displays `RoleSelectionEmpty` and never defaults to granting a `Player` role.
4. **Context Isolation:** Revoking an organization membership or tournament assignment must not invalidate or disable unrelated active roles held by the same user.
5. **Session Synchronization:** Selecting a role assignment updates both `SessionCubit.activeRole` and `SessionCubit.activeOrganizationId`, ensuring downstream dashboard screens operate within the exact intended tenant scope.

#### API Requirements

##### 1. Fetch User Role Context
**Endpoint:** `GET /api/v1/auth/roles`

**Headers:**
- `Authorization: Bearer <jwt_access_token>`

**Proposed Success Response (`200 OK`):**
```json
{
  "userId": "usr_multi_001",
  "displayName": "Alex Rivera",
  "phone": "+919876543210",
  "email": "alex.rivera@example.com",
  "preferredRoleAssignmentId": "assign_coach_001",
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
      "roleAssignmentId": "assign_coach_001",
      "role": "coach",
      "organizationId": "org_acad_001",
      "organizationName": "Pinnacle Sports Academy",
      "isActive": true,
      "description": "Manage training batches, player attendance, session schedules, and performance evaluations."
    },
    {
      "roleAssignmentId": "assign_venue_staff_001",
      "role": "venue-staff",
      "organizationId": "org_venue_001",
      "organizationName": "Grand Slam Arena",
      "isActive": true,
      "description": "Check in players, manage court schedules, and oversee venue facilities."
    },
    {
      "roleAssignmentId": "assign_venue_staff_002",
      "role": "venue-staff",
      "organizationId": "org_venue_002",
      "organizationName": "Metro Court Center",
      "isActive": true,
      "description": "Check in players, manage court schedules, and oversee venue facilities."
    }
  ]
}
```

> [!NOTE]
> **Organization-Scoped Same-Role Support:** Users may hold identical role types across multiple organizations (e.g. Venue Staff at two distinct venues). Each assignment context has a unique `roleAssignmentId`. The client identifies, displays, and persists selections based on `roleAssignmentId`, updating `SessionCubit` with both the selected `UserRole` and its specific `organizationId`.

##### 2. Persist Preferred Role Assignment Preference
**Endpoint:** `PUT /api/v1/users/preferences/preferred-role`

**Headers:**
- `Authorization: Bearer <jwt_access_token>`

**Proposed Request Payload:**
```json
{
  "roleAssignmentId": "assign_coach_001"
}
```

**Proposed Success Response (`200 OK`):**
```json
{
  "userId": "usr_multi_001",
  "roleAssignmentId": "assign_coach_001",
  "message": "Preferred role assignment updated successfully"
}
```

##### 3. Clear Preferred Role Preference
**Endpoint:** `DELETE /api/v1/users/preferences/preferred-role`

**Headers:**
- `Authorization: Bearer <jwt_access_token>`

**Proposed Success Response (`204 No Content` or `200 OK`):**
```json
{
  "userId": "usr_multi_001",
  "message": "Preferred role cleared"
}
```

#### Open Questions Requiring Backend Agreement
1. **Login Response Optimization:** Can `/api/v1/auth/login` include the complete `roles` payload directly in the auth session response (as defined in Section 2.2)? If so, single-role accounts can be dispatched immediately to their dashboard during sign-in without a second roundtrip to `GET /api/v1/auth/roles`.
2. **Organization Membership Revocation:** When an Application Admin revokes a user's staff role in Organization A, the backend must ensure that unrelated roles (e.g. Player, Coach in Organization B) remain active and undisturbed. Does the backend issue updated refresh tokens upon role revocation?
3. **Preferred Role Storage Scope:** The frontend currently persists the preferred role locally via `RolePreferenceStorage` (`SharedPreferences`) with fallback to server-side user preferences. Backend confirmation is requested on whether server-side preference sync is required across devices.
