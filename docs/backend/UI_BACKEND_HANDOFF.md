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

---

### 2.6 Phase 1.2.1 — Shared User Profile & Account Settings

#### Overview & Scope
Provides unified personal account identity and configuration screens common to all platform users regardless of their active role context. Role-specific administrative metadata (e.g., Academy staff delegations, Venue banking data, Organizer permits) is decoupled from this personal profile.

#### Routes & Screen Inventory
1. **`/profile` — Personal Profile Screen (`ProfilePage`)**: Displays verified account details, avatar/initials, contact information, member status, and navigation to Edit Profile or Account Settings.
2. **`/profile/edit` — Edit Profile Screen (`EditProfilePage`)**: Enables editing personal details (full name, optional email, avatar badge), enforcing validation and unsaved changes confirmation.
3. **`/profile/settings` — Account Settings Screen (`AccountSettingsPage`)**: Central access hub for personal details, security placeholders (Change Password, Privacy), preference placeholders (Notifications), and Session Logout with confirmation.

#### Profile Fields & Data Types

| Field Name | Type | Editable | Requirement | Validation Rules | Description |
|---|---|---|---|---|---|
| `id` | `String` | No (Read-Only) | Mandatory | Backend UUID / ID format | Platform unique user identifier. |
| `name` | `String` | **Yes** | Mandatory | Min 2 chars, letters/spaces/hyphens | User's full display name. |
| `email` | `String` | **Yes** | Optional | Valid email format if provided | Secondary contact and receipt delivery email. |
| `phone` | `String` | No (Read-Only) | Mandatory | E.164 format (`+91XXXXXXXXXX`) | Primary verified login credential. Cannot be edited directly without OTP challenge. |
| `avatarUrl` | `String?` | **Yes** | Optional | Preset key or HTTPS URI | Avatar motif identifier or cloud asset URL. |
| `availableRoles` | `List<String>` | No (Read-Only) | Mandatory | Valid platform role enum IDs | Array of roles authorized for the user account. |
| `rating` | `Double?` | No (Read-Only) | Optional | Float (e.g. `3.8`, `4.5`) | Official skill/tournament rating if applicable. |
| `isSuspended` | `Boolean` | No (Read-Only) | Mandatory | Boolean | Account operational status gate. |
| `createdAt` | `DateTime` | No (Read-Only) | Mandatory | ISO 8601 string | Account registration timestamp for "Member Since" display. |

#### Profile Photo / Avatar Requirements
- **Frontend Presets:** The frontend supports preset avatar motifs (`avatar:champion`, `avatar:pro`, `avatar:shield`, `avatar:speed`, `avatar:trophy`) and initials fallback if no photo is set.
- **Future Image Uploads:** When custom photo uploads are implemented, the backend should support either:
  1. `POST /api/v1/users/me/avatar/presigned-url` returning an S3/Cloud Storage upload URL.
  2. Multipart form upload `POST /api/v1/users/me/avatar` returning the uploaded CDN URL.

#### Validation & Save/Cancel Behavior
- **Name Validation:** Must not be blank, minimum 2 characters, alphabetic characters, apostrophes, and hyphens permitted.
- **Email Validation:** Optional for player accounts. If entered, must conform to standard RFC 5322 email formatting.
- **Mobile Number:** Fixed and read-only. Marked with a "Primary ID" badge and informational tooltip explaining that mobile number is the primary authentication factor.
- **Unsaved Changes Guard:** If the user modifies any field and taps Cancel or triggers system back (`PopScope`), an `AppConfirmationDialog` prompts the user to either discard changes or keep editing.
- **Save Action:** Commits updates through `ProfileCubit.updateProfile`, displaying immediate feedback via SnackBar and updating the active view state.

#### Account Settings & Logout Lifecycle
- **Change Password Placeholder:** Displays informational dialog stating password management will be integrated in Phase 1.3.
- **Notification Preferences Placeholder:** Displays informational dialog stating notification channels will be integrated in Phase 1.4.
- **Privacy & Security Placeholder:** Displays informational dialog stating privacy controls and audit logs will be integrated in Phase 1.3.
- **Log Out:**
  - Tapping "Log Out" prompts an `AppConfirmationDialog` with destructive styling.
  - On confirmation, executes `SessionCubit.signOut()`, clearing the authenticated session and routing the user back to `AppRoutes.welcome`.
  - Token revocation and refresh token invalidation will be hooked into this action in Phase 1.2/1.3.

#### Proposed Backend API Contracts

##### 1. Fetch User Profile
**Endpoint:** `GET /api/v1/users/me`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):**
```json
{
  "id": "user_player_001",
  "name": "Alex Rivera",
  "email": "alex.rivera@example.com",
  "phone": "+919876543210",
  "avatarUrl": "avatar:champion",
  "availableRoles": ["player", "coach"],
  "rating": 3.8,
  "isSuspended": false,
  "createdAt": "2025-03-15T10:00:00Z"
}
```

##### 2. Update User Profile
**Endpoint:** `PUT /api/v1/users/me`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Request Payload:**
```json
{
  "name": "Alexander Rivera",
  "email": "alex.rivera@example.com",
  "avatarUrl": "avatar:champion"
}
```
**Response (`200 OK`):**
```json
{
  "id": "user_player_001",
  "name": "Alexander Rivera",
  "email": "alex.rivera@example.com",
  "phone": "+919876543210",
  "avatarUrl": "avatar:champion",
  "availableRoles": ["player", "coach"],
  "rating": 3.8,
  "isSuspended": false,
  "createdAt": "2025-03-15T10:00:00Z",
  "message": "Profile updated successfully"
}
```

---

### 2.7 Phase 1.2.2 — Notification Preferences

#### Overview & Scope
Provides fine-grained user control over alert delivery across Push, Email, and in-app sound/display channels. Preferences are scoped to the individual user account and persist across multi-role context switches.

#### Routes & Screen Inventory
- **`/profile/settings/notifications` — Notification Preferences Screen (`NotificationPreferencesPage`)**: Accessible from Account Settings (`/profile/settings`), this responsive screen presents three clear sections:
  1. **Push Notifications (Section A)**: Real-time alerts delivered to the device, controlled by a master switch and 8 category toggles.
  2. **Email Notifications (Section B)**: Formal email digests, receipts, and summaries, controlled by a master switch and 7 category toggles.
  3. **General Settings (Section C)**: In-app sound effects and notification preview privacy options.
  4. **Reset to Defaults (Section D)**: Restoration of all preferences to recommended platform baseline settings with destructive confirmation dialog.

#### Channels & Category Breakdown

| Section | Category Key | Channel(s) | Default | Description |
|---|---|---|---|---|
| **A / B** | `accountSecurity` | Push & Email | `true` | Critical alerts for logins, password resets, session terminations, and security challenges. |
| **A / B** | `bookingUpdates` | Push & Email | `true` | Court reservation confirmations, cancellation notices, slot rescheduling, and check-in reminders. |
| **A / B** | `tournamentUpdates` | Push & Email | `true` | Event registration status, bracket releases, match fixture announcements, and fee payment receipts. |
| **A** | `matchScoringUpdates` | Push Only | `true` | Real-time live score progress, court assignments, and referee calls (Push exclusive; unsuitable for email latency). |
| **A / B** | `coachingAcademyUpdates` | Push & Email | `true` | Training batch timings, academy enrollment documents, session schedules, and coach attendance logs. |
| **A / B** | `marketplaceUpdates` | Push & Email | `true` | Order confirmations, dispatch tracking, delivery notifications, and return/refund statements. |
| **A / B** | `communityUpdates` | Push & Email | Push: `true`<br>Email: `false` | Club activity notices, social challenges, connection invites, and weekly platform newsletter digests. |
| **A / B** | `promotions` | Push & Email | `false` | Partner perks, equipment sales, promotional vouchers, and seasonal marketing campaigns (Opt-in only). |
| **C** | `soundEnabled` | General (In-App) | `true` | Audible sound effects when notifications arrive while using the active application. |
| **C** | `detailedPreviews` | General (Display) | `true` | Include message snippet, sender identity, and action buttons in notification popup alerts. |

#### Master Toggle Behavior & State Preservation
1. **Push Master Switch (`pushMasterEnabled`)**:
   - When set to `false`, the push notification channel is paused. All push sub-category toggles become visually dimmed and non-interactive (`isChannelEnabled = false`).
   - Turning the master switch `false` does **not** erase or reset the underlying sub-category values.
   - When toggled back to `true`, all previous sub-category preferences are immediately restored.
2. **Email Master Switch (`emailMasterEnabled`)**:
   - Operates identically to the push master toggle, muting email dispatches while retaining individual category states.

#### Persistence & Reset Lifecycle
- **Immediate Local Persistence:** Preference toggle interactions automatically update local state and dispatch an optimistic persistence request without requiring a manual "Save" button. Feedback is delivered immediately via a floating SnackBar ("Preference updated", "Push notifications enabled/disabled").
- **Reset to Defaults:** Tapping "Reset to Default Settings" triggers an `AppConfirmationDialog` warning. Upon user confirmation, all categories, master switches, and general preferences are restored to platform defaults and confirmed via SnackBar feedback.

#### Proposed Backend API Contracts

##### 1. Fetch User Notification Preferences
**Endpoint:** `GET /api/v1/users/me/notification-preferences`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):**
```json
{
  "userId": "usr_player_001",
  "pushMasterEnabled": true,
  "emailMasterEnabled": true,
  "push": {
    "accountSecurity": true,
    "bookingUpdates": true,
    "tournamentUpdates": true,
    "matchScoringUpdates": true,
    "coachingAcademyUpdates": true,
    "marketplaceUpdates": true,
    "communityUpdates": true,
    "promotions": false
  },
  "email": {
    "accountSecurity": true,
    "bookingUpdates": true,
    "tournamentUpdates": true,
    "coachingAcademyUpdates": true,
    "marketplaceUpdates": true,
    "communityUpdates": false,
    "promotions": false
  },
  "general": {
    "soundEnabled": true,
    "detailedPreviews": true
  }
}
```

##### 2. Update Notification Preferences
**Endpoint:** `PUT /api/v1/users/me/notification-preferences`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Request Payload:** Complete or partial preferences payload matching the GET schema.  
**Response (`200 OK`):** Updated `NotificationPreferences` JSON object.

##### 3. Reset Preferences to Defaults
**Endpoint:** `POST /api/v1/users/me/notification-preferences/reset`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):** Returns default `NotificationPreferences` object with `"message": "Notification preferences restored to default settings"`.

#### Future Backend Data & Integration Requirements
1. **Device Push Token Registry:** When device push registration is integrated in Phase 1.4, the backend must support associating APNS / FCM device tokens with the `userId` (`POST /api/v1/users/me/devices/push-token`).
2. **Transactional Email Gate:** The backend email dispatch worker must enforce `emailMasterEnabled` and specific category flags before enqueuing jobs to SendGrid / AWS SES, with `accountSecurity` alerts designated as non-opt-out bypassable if legally required.
3. **Audit Trail:** Retain timestamped logs of promotional marketing opt-in / opt-out changes for data privacy and regulatory compliance (GDPR/DPDP).

---

### 2.8 Phase 1.2.3 — Notification Centre

#### Overview & Scope
Provides the central user-facing inbox for viewing, filtering, reading, and clearing platform notifications generated across all 12 platform roles and activities. Decoupled from Notification Preferences, the Notification Centre focuses strictly on notification lifecycle, inbox organization, and contextual deep-linking.

#### Routes & Screen Inventory
- **`/notifications` — Notification Centre Screen (`NotificationCenterPage`)**:
  - Main in-app notification center accessible from the navigation shell bell icon.
  - Horizontal category filter chips (`All`, `Unread`, `Bookings`, `Tournaments`, `Matches`, `Coaching & Academy`, `Marketplace`, `Community`, `Account & Security`).
  - Read/unread visual distinction (unread indicator dot, elevated card tint, bold title).
  - Individual item actions: Tap to open, toggle read/unread, and delete with `AppConfirmationDialog`.
  - Bulk actions: "Mark all as read" in top AppBar with confirmation dialog.
  - Shortcut to Notification Preferences (`/profile/settings/notifications`).

#### Notification Item Data Schema

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique notification identifier (e.g. `notif_001`). |
| `title` | `String` | Yes | Headline summary of the alert. |
| `description` | `String` | Yes | Detailed body text explaining the update. |
| `category` | `String` (Enum) | Yes | Category tag (`bookings`, `tournaments`, `matches`, `coaching_academy`, `marketplace`, `community`, `account_security`). |
| `timestamp` | `String` (ISO 8601) | Yes | When the notification was dispatched. Rendered relatively (e.g. "30m ago", "Yesterday"). |
| `isRead` | `Boolean` | Yes | Unread/read status flag. |
| `destinationRoute` | `String?` | Optional | Internal deep-link route (e.g. `/player/bookings`, `/player/match-day`). |
| `relatedEntityId` | `String?` | Optional | Identifier of associated booking, tournament, order, or session. |
| `organizationName` | `String?` | Optional | Venue or Academy name if notification is organization-scoped. |
| `tournamentName` | `String?` | Optional | Tournament title if event-scoped. |
| `roleContext` | `String?` | Optional | Role context associated with the alert (e.g. `player`, `coach`). |

#### Navigation & Deep-Linking Strategy
1. **Local State Update:** Tapping any unread notification immediately marks it read locally via `NotificationsCubit.markAsRead(item.id)`.
2. **Centralized Destination Mapping:** Handled by `NotificationDestinationRouter.navigateToDestination(context, notification)`:
   - If `destinationRoute` is available and wired into GoRouter, navigates directly to that screen.
   - If the destination belongs to a phase not yet developed or lacks an active route, an informational fallback dialog displays the notification details, organization context, and reference ID without crashing or breaking navigation.

#### Proposed Backend API Contracts

##### 1. Fetch Notification Feed
**Endpoint:** `GET /api/v1/notifications`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Query Parameters:**
- `category` *(optional)*: Filter by category (`bookings`, `tournaments`, etc.).
- `unreadOnly` *(optional)*: Boolean flag to query unread notifications only.
- `page` / `limit` *(optional)*: Page number and limit (default: 20).
**Response (`200 OK`):**
```json
{
  "total": 8,
  "unreadCount": 4,
  "items": [
    {
      "id": "notif_001",
      "title": "Court Booking Confirmed",
      "description": "Your reservation for Court 2 at Apex Pickleball Arena is confirmed for tomorrow at 6:00 PM.",
      "category": "bookings",
      "timestamp": "2026-11-06T10:00:00Z",
      "isRead": false,
      "destinationRoute": "/player/bookings",
      "relatedEntityId": "bk_apex_204",
      "organizationName": "Apex Pickleball Arena",
      "roleContext": "player"
    }
  ]
}
```

##### 2. Mark Notification as Read
**Endpoint:** `PATCH /api/v1/notifications/{id}/read`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):** Updated `NotificationItem` with `isRead: true`.

##### 3. Mark Notification as Unread
**Endpoint:** `PATCH /api/v1/notifications/{id}/unread`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):** Updated `NotificationItem` with `isRead: false`.

##### 4. Mark All Notifications as Read
**Endpoint:** `POST /api/v1/notifications/mark-all-read`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):** `{"message": "All notifications marked as read", "updatedCount": 4}`

##### 5. Delete Notification
**Endpoint:** `DELETE /api/v1/notifications/{id}`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):** `{"message": "Notification deleted"}`

#### Future Backend Data & Streaming Requirements
1. **Real-time Push / WebSocket Ingestion:** In Phase 1.4, WebSocket or SSE (`/api/v1/notifications/stream`) will push incoming notifications to the active client, incrementing `unreadCount` dynamically.
2. **Notification Retention / TTL Policy:** Automatically archive notifications older than 90 days.

---

### 2.9 Phase 2.1 — Player Dashboard UI

#### Overview & Scope
The **Player Dashboard** (`/player/dashboard`) serves as the primary home screen for authenticated users operating in the **Player** role (Role 1), conforming to Player PRD v1.6 and Frontend FSD §5. It provides a centralized operational snapshot aggregating player identity, verified skill ratings, quick-action navigation into core player flows, upcoming court reservations & tournament matches, performance statistics, and recent activity history.

#### Routes & Screen Inventory
- **`/player/dashboard` — Player Dashboard Screen (`PlayerDashboardPage`)**:
  - Primary landing screen for the Player role.
  - Responsive design adapting between mobile (vertical stacked single-column flow) and tablet/desktop (2-column layout: left column for actions and upcoming schedule; right column for statistics and recent activity history).
  - Pull-to-refresh (`RefreshIndicator`) for live state synchronization.
  - Responsive container constraining maximum content width to `1200dp` (`AppSpacing.maxContentWidth`).

#### Dashboard Sections & Data Schema

##### 1. Profile & Identity Header (`PlayerHeaderCard`)
Displays the player's personal greeting, avatar, verified rating, tier, and basic playing style.

| Field | Type | Required | Description |
|---|---|---|---|
| `userId` | `String` | Yes | Unique player profile ID (e.g. `user_player_001`). |
| `fullName` | `String` | Yes | Player's full legal/display name (e.g. "Alex Rivera"). |
| `avatarUrl` | `String?` | Optional | Profile image URL or avatar preset key (e.g. `avatar:champion`). |
| `skillRating` | `Double` | Yes | Official or self-reported DUPR / platform rating (e.g. `3.85`). |
| `ratingTier` | `String` | Yes | Descriptive tier label (e.g. "Intermediate 3.5+", "Advanced 4.5+"). |
| `location` | `String` | Yes | City/region of primary play (e.g. "Mumbai, MH"). |
| `playStyle` | `String` | Yes | Dominant hand & preferred format (e.g. "Right-handed • Mixed Doubles"). |
| `memberSince` | `String` (ISO 8601) | Yes | Account creation timestamp. |
| `unreadNotificationsCount`| `Integer` | Yes | Active unread notifications badge count. |

*Actions:*
- Tap Avatar / "My Profile" -> navigates to `/profile` (`AppRoutes.profile`).

##### 2. Quick Actions Hub (`PlayerQuickActions`)
Direct touch targets for the 6 primary player feature modules:

| Action Label | Subtitle | Destination Route | Icon | PRD Mapping |
|---|---|---|---|---|
| **Book a Court** | Reserve court slots | `/player/discovery/venues` | `Icons.sports_tennis` | Venue Discovery |
| **Find Coaches** | Academies & batches | `/player/discovery/academies` | `Icons.school_outlined` | Academy Discovery |
| **Tournaments** | Browse & enter draws | `/player/tournaments` | `Icons.emoji_events_outlined` | Tournament Registration |
| **Match Day** | Live schedules & scores | `/player/match-day` | `Icons.schedule_outlined` | Match Day Hub |
| **Shop Gear** | Paddles, balls & nets | `/player/marketplace` | `Icons.shopping_bag_outlined` | Marketplace Shop |
| **My Bookings** | Manage reservations | `/player/bookings` | `Icons.calendar_month_outlined` | Bookings Management |

##### 3. Upcoming Schedule & Commitments (`UpcomingActivitiesSection`)
Presents next scheduled commitments (court bookings, tournament matches, coaching sessions) with contextual status badges.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique commitment identifier (e.g. `up_001`). |
| `title` | `String` | Yes | Activity title (e.g. "Court Reservation", "Men's Singles Open — Round 1"). |
| `type` | `String` (Enum) | Yes | `courtBooking`, `tournamentMatch`, or `coachingSession`. |
| `venueOrLocation` | `String` | Yes | Venue facility or tournament name (e.g. "Grand Slam Pickleball Arena"). |
| `courtName` | `String?` | Optional | Specific court allocation (e.g. "Court 1 (Championship)"). |
| `dateTime` | `String` (ISO 8601) | Yes | Exact scheduled timestamp. |
| `timeSlot` | `String` | Yes | Human-readable time slot (e.g. "Today • 03:45 PM", "07:00 AM - 08:00 AM"). |
| `status` | `String` (Enum) | Yes | `confirmed`, `scheduled`, `pending`. |
| `statusLabel` | `String` | Yes | Display text for status badge (e.g. "Confirmed", "Scheduled", "Enrolled"). |
| `actionRoute` | `String?` | Optional | Target screen when tapped (e.g. `/player/bookings`, `/player/match-day`). |
| `opponentOrCoach` | `String?` | Optional | Opponent name or instructor label (e.g. "vs Jordan Cruz", "Coach David Miller"). |

*Empty State Behavior:*
- When `upcomingActivities` is empty, displays a friendly empty state card with a call-to-action button to "Book a Court" (`/player/discovery/venues`) or "Find Tournaments" (`/player/tournaments`).

##### 4. Activity & Performance Statistics (`PlayerStatsGrid`)
Key platform metrics and playing statistics:

| Stat Field | Key | Expected Type | Format / Example |
|---|---|---|---|
| Skill Rating | `skillRating` | `Double` | `3.85` (DUPR verified) |
| Matches Played | `matchesPlayed` | `Integer` | `24` (All official matches) |
| Win Rate | `winRatePercentage` | `Double` | `68%` (Match victory percentage) |
| Active Bookings | `upcomingBookingsCount` | `Integer` | `2` (Upcoming confirmed reservations) |
| Tournaments | `tournamentsEnteredCount` | `Integer` | `1` (Active or registered tournaments) |

##### 5. Recent Activity Feed (`RecentActivitySection`)
Audit stream of recently completed player interactions:

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique activity ID (e.g. `rec_001`). |
| `title` | `String` | Yes | Summary of the milestone (e.g. "Pacific Coast Masters — Quarter-final"). |
| `description` | `String` | Yes | Detail text (e.g. "Won against David Miller in straight sets (11-7, 11-5)."). |
| `timestamp` | `String` (ISO 8601) | Yes | Completion timestamp, rendered relatively ("Yesterday", "2d ago"). |
| `category` | `String` (Enum) | Yes | `match`, `booking`, `tournament`, `marketplace`. |
| `resultBadge` | `String?` | Optional | Result tag (e.g. "Won 2-0", "Completed", "Delivered"). |
| `actionRoute` | `String?` | Optional | Historical details screen route. |

#### Proposed Backend API Contract

##### 1. Fetch Aggregate Player Dashboard
**Endpoint:** `GET /api/v1/player/dashboard`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Response (`200 OK`):**
```json
{
  "profile": {
    "userId": "user_player_001",
    "fullName": "Alex Rivera",
    "avatarUrl": "avatar:champion",
    "skillRating": 3.85,
    "ratingTier": "Intermediate 3.5+",
    "location": "Mumbai, MH",
    "playStyle": "Right-handed • Mixed Doubles",
    "memberSince": "2025-03-15T00:00:00Z"
  },
  "stats": {
    "matchesPlayed": 24,
    "winRatePercentage": 68.0,
    "upcomingBookingsCount": 2,
    "tournamentsEnteredCount": 1,
    "skillRating": 3.85
  },
  "upcomingActivities": [
    {
      "id": "up_001",
      "title": "Court Reservation",
      "type": "courtBooking",
      "venueOrLocation": "Grand Slam Pickleball Arena",
      "courtName": "Court 1 (Championship Cushioned)",
      "dateTime": "2026-11-07T07:00:00Z",
      "timeSlot": "07:00 AM - 08:00 AM",
      "status": "confirmed",
      "statusLabel": "Confirmed",
      "actionRoute": "/player/bookings"
    },
    {
      "id": "up_002",
      "title": "Men's Singles Open — Round 1",
      "type": "tournamentMatch",
      "venueOrLocation": "National Pickleball Open 2026",
      "courtName": "Court 1 (Championship Court)",
      "dateTime": "2026-11-06T15:45:00Z",
      "timeSlot": "Today • 03:45 PM",
      "status": "scheduled",
      "statusLabel": "Scheduled",
      "opponentOrCoach": "vs Jordan Cruz (Seed #3)",
      "actionRoute": "/player/match-day"
    }
  ],
  "recentActivities": [
    {
      "id": "rec_001",
      "title": "Pacific Coast Masters — Quarter-final",
      "description": "Won against David Miller in straight sets (11-7, 11-5).",
      "timestamp": "2026-11-04T18:30:00Z",
      "category": "match",
      "resultBadge": "Won 2-0",
      "actionRoute": "/player/tournaments"
    }
  ],
  "unreadNotificationsCount": 3
}
```

#### Future Backend Data & Integration Requirements
1. **Aggregation Service:** A dedicated dashboard aggregator worker or BFF (Backend-for-Frontend) endpoint to composite profile, upcoming bookings, next match schedule, and recent orders in a single low-latency roundtrip.
2. **DUPR Sync Worker:** Synchronize verified player ratings and tiers from the official DUPR API on a daily cron schedule.
3. **Timezone Normalization:** Store all timestamps in UTC with timezone offset metadata to ensure court slot times display correctly in local venue timezone.

---

### 2.10 Feature 2.2.1 — Player Venue Discovery & Search UI

#### Overview & Scope
The **Venue Discovery** screen (`/player/discovery/venues`) enables players to find and explore verified pickleball venues, available courts, operating hours, prices, and amenities nearby. It features search-by-name/location, multi-facet filtering (distance, minimum rating, price tiers, indoor-only, amenities), sorting (distance, rating, price, name), empty state handling, and deep navigation into individual venue details placeholders (`/player/discovery/venues/:id`).

#### Routes & Screen Inventory
- **`/player/discovery/venues` — Venue Discovery Screen (`VenueDiscoveryPage`)**:
  - Primary venue search and filter gateway for players.
  - Responsive layout (single-column card list on mobile; 2-column grid layout on desktop viewports >800dp).
  - Search input with clear button, filter trigger with active filter count badge, sort options popup, and active filter chip strip with "Clear all".
- **`/player/discovery/venues/:id` — Venue Details Placeholder Screen (`RoutePlaceholderView`)**:
  - Placeholder destination opened upon tapping any venue card, passing `venue.id` in path and `venue.name` in extra state.

#### Venue Card Data Schema

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique venue organization ID (e.g. `org_venue_001`). |
| `name` | `String` | Yes | Venue display name (e.g. "Grand Slam Pickleball Arena"). |
| `imageUrl` | `String?` | Optional | Photo / banner URL for the venue facility. |
| `address` | `String` | Yes | Street address / area label (e.g. "742 Evergreen Terrace, Andheri West"). |
| `city` | `String` | Yes | Municipality / City (e.g. "Mumbai"). |
| `distanceKm` | `Double` | Yes | Mock calculated distance from player in kilometers (e.g. `1.8`). |
| `courtCount` | `Integer` | Yes | Total number of pickleball courts available (e.g. `8`). |
| `surfaceTypes` | `List<String>` | Yes | Court surfaces (e.g. `["Pro Cushion", "Acrylic Hardcourt"]`). |
| `isIndoor` | `Boolean` | Yes | Whether facility contains indoor/covered courts. |
| `hasNightLights` | `Boolean` | Yes | Whether floodlights / evening play is supported. |
| `amenities` | `List<String>` | Yes | Facility amenities (e.g. `["Night Lights", "Equipment Rental", "Pro Shop", "Locker Rooms", "Parking", "Cafeteria"]`). |
| `rating` | `Double` | Yes | Average verified player rating (1.0 - 5.0, e.g. `4.85`). |
| `reviewCount` | `Integer` | Yes | Total count of verified reviews (e.g. `214`). |
| `minHourlyRate` | `Double` | Yes | Lowest hourly court rental rate in INR (e.g. `500.0`). |
| `maxHourlyRate` | `Double` | Yes | Highest hourly court rental rate in INR (e.g. `900.0`). |
| `operatingHours` | `String` | Yes | Daily facility operating schedule (e.g. "06:00 - 23:00"). |

#### Search, Filter, and Sorting Specifications

##### 1. Search Query
- **Query Parameter:** `q` (string)
- Case-insensitive substring match against venue `name`, `address`, `city`, and `amenities`.

##### 2. Distance Filter
- **Query Parameter:** `maxDistanceKm` (numeric)
- Supported presets: Any, `< 5 km`, `< 10 km`, `< 25 km`.
- *Note:* Frontend uses local mock distance values. No GPS permission or live geocoding is invoked in UI mock mode.

##### 3. Rating Filter
- **Query Parameter:** `minRating` (numeric)
- Supported presets: Any, `4.0+`, `4.5+`.

##### 4. Price Tier Filter
- **Query Parameter:** `priceTier` (string enum: `budget`, `mid`, `premium`)
- Budget: `minHourlyRate <= 600`
- Mid: `minHourlyRate <= 1000` and `maxHourlyRate >= 600`
- Premium: `maxHourlyRate > 1000`

##### 5. Indoor Only Filter
- **Query Parameter:** `indoorOnly` (boolean)
- Filters `isIndoor == true`.

##### 6. Required Amenities Filter
- **Query Parameter:** `amenities` (comma-separated string)
- Venues must contain *all* selected amenities (AND operation). Supported items: `Night Lights`, `Equipment Rental`, `Pro Shop`, `Locker Rooms`, `Parking`, `Cafeteria`, `Coaching Available`.

##### 7. Sorting Criteria
- **Query Parameter:** `sortBy` (string enum)
  - `distanceAsc`: Distance: Nearest First (Default)
  - `ratingDesc`: Rating: Highest Rated
  - `priceAsc`: Price: Low to High
  - `priceDesc`: Price: High to Low
  - `nameAsc`: Alphabetical: Name (A-Z)

#### Proposed Backend API Contracts

##### 1. Discover & Search Venues
**Endpoint:** `GET /api/v1/venues`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Query Parameters:**
- `q` *(optional)*: Search string.
- `maxDistanceKm` *(optional)*: Distance ceiling.
- `minRating` *(optional)*: Rating floor.
- `priceTier` *(optional)*: Price tier filter.
- `indoorOnly` *(optional)*: Boolean.
- `amenities` *(optional)*: Comma-separated list of required amenities.
- `sortBy` *(optional)*: Sort order (`distanceAsc`, `ratingDesc`, `priceAsc`, `priceDesc`, `nameAsc`).
- `page` / `limit` *(optional)*: Pagination controls (default: 20).

**Response (`200 OK`):**
```json
{
  "total": 1,
  "venues": [
    {
      "id": "org_venue_001",
      "name": "Grand Slam Pickleball Arena",
      "imageUrl": "https://cdn.pickleballplatform.com/venues/org_venue_001.jpg",
      "address": "742 Evergreen Terrace, Andheri West",
      "city": "Mumbai",
      "distanceKm": 1.8,
      "courtCount": 8,
      "surfaceTypes": ["Pro Cushion", "Acrylic Hardcourt"],
      "isIndoor": true,
      "hasNightLights": true,
      "amenities": [
        "Night Lights",
        "Equipment Rental",
        "Pro Shop",
        "Locker Rooms",
        "Parking",
        "Cafeteria"
      ],
      "rating": 4.85,
      "reviewCount": 214,
      "minHourlyRate": 500.0,
      "maxHourlyRate": 900.0,
      "operatingHours": "06:00 - 23:00"
    }
  ]
}
```

##### 2. Get Single Venue Details (Feature 2.2.2)
**Endpoint:** `GET /api/v1/venues/{id}`  
**Headers:** `Authorization: Bearer <jwt_access_token>`  
**Path Parameter:**
- `id` *(string, required)*: Unique identifier of the venue (e.g. `org_venue_001`).

**Response (`200 OK`):**
```json
{
  "id": "org_venue_001",
  "name": "Grand Slam Pickleball Arena",
  "imageUrl": "https://cdn.pickleballplatform.com/venues/org_venue_001.jpg",
  "galleryImages": [
    "https://cdn.pickleballplatform.com/venues/org_venue_001.jpg",
    "https://cdn.pickleballplatform.com/venues/org_venue_001_interior.jpg",
    "https://cdn.pickleballplatform.com/venues/org_venue_001_courts.jpg"
  ],
  "description": "Premier indoor pickleball facility in Andheri West featuring 8 tournament-grade courts with professional cushioning, optimal LED lighting, pro equipment rental, and an on-site cafe for community post-match social sessions.",
  "address": "742 Evergreen Terrace, Andheri West",
  "city": "Mumbai",
  "distanceKm": 1.8,
  "courtCount": 8,
  "surfaceTypes": ["Pro Cushion", "Acrylic Hardcourt"],
  "isIndoor": true,
  "hasNightLights": true,
  "amenities": [
    "Night Lights",
    "Equipment Rental",
    "Pro Shop",
    "Locker Rooms",
    "Parking",
    "Cafeteria",
    "Showers",
    "Drinking Water",
    "Seating"
  ],
  "rating": 4.85,
  "reviewCount": 214,
  "minHourlyRate": 500.0,
  "maxHourlyRate": 900.0,
  "operatingHours": "06:00 - 23:00",
  "operatingStatus": "Open Now • 06:00 - 23:00",
  "cancellationPolicy": "Free cancellation up to 4 hours before slot time. 50% refund within 2 to 4 hours.",
  "supportedSports": ["Pickleball", "Tennis"],
  "reviews": [
    {
      "id": "rev_001_1",
      "reviewerName": "Vikram Mehta",
      "rating": 5.0,
      "date": "02 Nov 2026",
      "comment": "Outstanding court surface and lighting. The bounce is true and the staff is very welcoming! Will definitely book again.",
      "reviewerAvatar": null
    },
    {
      "id": "rev_001_2",
      "reviewerName": "Ananya Sharma",
      "rating": 4.8,
      "date": "28 Oct 2026",
      "comment": "Great indoor facility! Clean locker rooms, pro equipment rentals, and lovely cafe for recovery smoothies.",
      "reviewerAvatar": null
    }
  ]
}
```

**Error Responses:**
- `404 Not Found`:
```json
{
  "code": "VENUE_NOT_FOUND",
  "message": "The requested venue details could not be found."
}
```
- `500 Internal Server Error`:
```json
{
  "code": "INTERNAL_SERVER_ERROR",
  "message": "Failed to retrieve venue details."
}
```

#### Detailed Contract Fields & Data Types

| Field | Type | Description | Required |
|---|---|---|---|
| `id` | `String` | Unique venue ID | Yes |
| `name` | `String` | Venue display name | Yes |
| `imageUrl` | `String?` | Primary hero photo URL | Optional |
| `galleryImages` | `List<String>` | List of high-resolution gallery photo URLs | Yes |
| `description` | `String` | Full description of facility, vibe, and amenities | Yes |
| `address` | `String` | Street address / landmark | Yes |
| `city` | `String` | City name | Yes |
| `distanceKm` | `double` | Haversine distance from user location pin | Yes |
| `courtCount` | `int` | Total number of bookable courts | Yes |
| `surfaceTypes` | `List<String>` | Surface names (e.g., `Pro Cushion`, `Acrylic Hardcourt`) | Yes |
| `isIndoor` | `bool` | True if indoor/covered facility | Yes |
| `hasNightLights` | `bool` | True if illuminated for evening play | Yes |
| `amenities` | `List<String>` | Standardized amenity strings | Yes |
| `rating` | `double` | Average star rating (1.0 - 5.0) | Yes |
| `reviewCount` | `int` | Total number of verified player reviews | Yes |
| `minHourlyRate` | `double` | Minimum court hourly rate in INR | Yes |
| `maxHourlyRate` | `double` | Maximum court hourly rate in INR | Yes |
| `operatingHours` | `String` | Daily operational schedule (e.g. `06:00 - 23:00` or `24 Hours`) | Yes |
| `cancellationPolicy` | `String` | Slot cancellation & refund rules | Yes |
| `supportedSports` | `List<String>` | Sports playable at venue | Yes |
| `reviews` | `List<VenueReview>` | Recent player reviews with ratings and comments | Yes |

#### Actions & Navigation
- **Back Navigation:** Returns to `/player/discovery/venues` (Venue Discovery screen).
- **Gallery Switching:** Interactively switches active hero photograph from `galleryImages`.
- **View All Reviews:** Opens modal dialog listing all player feedback.
- **Check Court Availability (CTA):** Navigates to `/player/discovery/venues/{id}/availability` (Court Availability screen in Feature 2.2.3).

#### Future Backend Data & Geocoding Requirements
1. **Spatial Indexing & Haversine Distance:** Use PostGIS or Elasticsearch geo-distance queries based on user's selected location pin or coordinates to compute real `distanceKm`.
2. **Pricing Aggregation:** Calculate dynamic `minHourlyRate` and `maxHourlyRate` from the venue's active court rate matrix.
3. **Verified Badge & Status:** Filter out non-approved or suspended venue partner organizations.
4. **Review Moderation Pipeline:** Store review timestamps, verified booking IDs, and filter profanity before returning in public review payloads.

---

### 5.3 Player Court Availability & Slot Selection UI (Feature 2.2.3)

#### Screen Overview
The Court Availability and Slot Selection screen allows players to view all courts for a selected venue, select dates across a 14-day rolling window, inspect court surfaces and indoor/outdoor status, review morning/afternoon/evening bookable slots, view real-time slot pricing and statuses (`available`, `booked`, `unavailable`), and select a single slot to proceed to checkout.

- **Route:** `/player/discovery/venues/:id/availability` (`AppRoutes.playerCourtAvailability`)
- **Key Navigation Inbound:** Venue Details "Check Court Availability" primary button.
- **Key Navigation Outbound:** "Continue to Booking" -> `/player/bookings/checkout` (`AppRoutes.playerBookingCheckout`), passing `BookingSelectionPayload`.

#### UI State Lifecycle & Transitions
1. **Initial / Loading State (`CourtAvailabilityLoading`):**
   - Displays full-screen `LoadingView` with message: *"Loading court availability & slots..."*.
2. **Loaded State (`CourtAvailabilityLoaded`):**
   - **Date Picker Strip:** Displays rolling 14-day list starting from today. Past dates are blocked. Shows weekday abbreviation, numeric date, and month label. Selection updates active slots.
   - **Court Selector Tabs:** Displays all courts belonging to the venue with court name, surface type, indoor/outdoor indicator, and remaining available slots indicator.
   - **Time Slots Grid:** Grouped chronologically into Morning (`06:00 - 12:00`), Afternoon (`12:00 - 17:00`), and Evening & Night (`17:00 - 22:00`).
   - **Slot Cards:** Show time window (`HH:mm - HH:mm`), pricing, and status:
     - `available`: Interactive, high contrast border, tap to select/toggle.
     - `booked`: Disabled, lock icon, unselectable.
     - `unavailable`: Disabled, strikethrough/dimmed styling, unselectable.
   - **Booking Summary Card / Sticky Bar:** Displays selected venue name, court name and surface, formatted date, slot time, and total price in INR. "Continue to Booking" action button is enabled only when a valid slot is selected.
3. **Failure State (`CourtAvailabilityFailure`):**
   - Renders `ErrorStateView` with descriptive failure message and a "Retry" button.

#### Proposed API Contracts (Awaiting Backend Confirmation)

> [!IMPORTANT]
> **API Status: PROPOSED — PENDING BACKEND CONFIRMATION**  
> The endpoints, request parameters, and response formats below are proposed by the frontend architecture. Backend engineers must review and formalize this agreement.

##### 1. List Venue Courts Endpoint
`GET /api/v1/venues/{id}/courts?date={YYYY-MM-DD}`

###### Query Parameters
- `date` (`String`, ISO date format `YYYY-MM-DD`, optional, defaults to current date). Used to compute `availableSlotCount`.

###### Proposed Response (`200 OK`)
```json
{
  "courts": [
    {
      "id": "court_org_venue_001_1",
      "venueId": "org_venue_001",
      "name": "Court 1 (Center Court)",
      "courtNumber": 1,
      "surfaceType": "Pro Cushion",
      "isIndoor": true,
      "hasLighting": true,
      "isActive": true,
      "availableSlotCount": 11
    },
    {
      "id": "court_org_venue_001_2",
      "venueId": "org_venue_001",
      "name": "Court 2",
      "courtNumber": 2,
      "surfaceType": "Pro Cushion",
      "isIndoor": true,
      "hasLighting": true,
      "isActive": true,
      "availableSlotCount": 9
    }
  ]
}
```

##### 2. List Court Slots for Date Endpoint
`GET /api/v1/venues/{venueId}/courts/{courtId}/slots?date={YYYY-MM-DD}`

###### Query Parameters
- `date` (`String`, ISO date format `YYYY-MM-DD`, required).

###### Proposed Response (`200 OK`)
```json
{
  "venueId": "org_venue_001",
  "courtId": "court_org_venue_001_1",
  "date": "2026-11-07",
  "slots": [
    {
      "id": "slot_court_org_venue_001_1_2026-11-07_06-00",
      "courtId": "court_org_venue_001_1",
      "venueId": "org_venue_001",
      "startTime": "06:00",
      "endTime": "07:00",
      "price": 600.0,
      "status": "available"
    },
    {
      "id": "slot_court_org_venue_001_1_2026-11-07_07-00",
      "courtId": "court_org_venue_001_1",
      "venueId": "org_venue_001",
      "startTime": "07:00",
      "endTime": "08:00",
      "price": 600.0,
      "status": "booked"
    }
  ]
}
```

##### 3. Booking Selection Navigation Payload (`BookingSelectionPayload`)
When the user taps "Continue to Booking", the following transfer object is passed to `AppRoutes.playerBookingCheckout` (`extra` parameter):

```json
{
  "venueId": "org_venue_001",
  "venueName": "Andheri Central Pickleball Club",
  "courtId": "court_org_venue_001_1",
  "courtName": "Court 1 (Center Court)",
  "courtSurface": "Pro Cushion",
  "date": "2026-11-07T00:00:00.000",
  "slotId": "slot_court_org_venue_001_1_2026-11-07_06-00",
  "slotTime": "06:00 - 07:00",
  "price": 600.0
}
```

#### Backend Concurrency & Lock Notes
1. **Pessimistic vs Optimistic Locking:** When moving from slot selection to checkout, backend should temporarily reserve/hold the slot for 5-10 minutes (`HOLD` or `TEMP_LOCKED` status) to avoid race conditions and double bookings.
2. **Pricing Rules:** Dynamic peak/off-peak pricing must be computed server-side to guarantee integrity against frontend tampering.

---

### 5.4 Player Court Booking Checkout & Confirmation UI (Feature 2.2.4)

#### Screen Overview
The Booking Checkout and Confirmation journey allows players to review their chosen venue, court, date, time slot, duration, and pricing breakdown before committing to the booking. For V1, the payment mode is strictly **Pay at Venue / Offline Payment** (no online payment gateway integrations like Razorpay/Stripe, and no online refunds/cancellations). Upon confirming, a local booking record is created, assigning a human-readable booking reference (`PKL-BKG-YYYYMMDD-XXXX`), and navigating to the Confirmation screen with reservation details and venue check-in instructions.

- **Checkout Route:** `/player/booking/checkout` (`AppRoutes.playerBookingCheckout`)
- **Confirmation Route:** `/player/booking/confirmation` (`AppRoutes.playerBookingConfirmation`)
- **Payload Object:** `BookingSelectionPayload` passed via GoRouter `extra`
- **Domain Entities:** `CourtBooking`, `BookingStatus` (`confirmed`, `paymentPending`, `cancelled`, `completed`)
- **Cubit / State:** `BookingCheckoutCubit` (`BookingCheckoutInitial`, `BookingCheckoutInvalid`, `BookingCheckoutReady`, `BookingCheckoutSubmitting`, `BookingCheckoutSuccess`, `BookingCheckoutFailure`)

#### Required Booking Request Payload
When the player confirms their reservation on the Checkout screen, the following structured payload is submitted:

| Field | Type | Mandatory | Description / Validation Rule |
|---|---|---|---|
| `venueId` | `String` | Yes | Non-empty unique venue ID (e.g. `org_venue_001`). |
| `venueName` | `String` | Yes | Display name of the venue. |
| `venueAddress` | `String` | Optional | Street/area address of the venue. |
| `venueCity` | `String` | Optional | City where venue is located. |
| `courtId` | `String` | Yes | Non-empty unique court ID (e.g. `court_org_venue_001_1`). |
| `courtName` | `String` | Yes | Display name of the selected court. |
| `courtSurface` | `String` | Optional | Court surface type (e.g. `Pro Cushion`, `Synthetic`). |
| `date` | `String` (ISO 8601) | Yes | Calendar date of booking (e.g. `2026-11-09T00:00:00.000`). |
| `slotId` | `String` | Yes | Unique ID of the reserved time slot. |
| `slotTime` | `String` | Yes | Slot display string (e.g. `06:00 - 07:00`). |
| `startTime` | `String` | Yes | Start time in 24h format (e.g. `06:00`). |
| `endTime` | `String` | Yes | End time in 24h format (e.g. `07:00`). |
| `durationMinutes` | `Integer` | Yes | Total duration of the reserved slot (default: `60`). |
| `courtFee` | `Double` | Yes | Base court rental fee for the slot (₹). Must be > 0. |
| `platformFee` | `Double` | Yes | Booking convenience fee (₹0 in V1; backend configurable). |
| `taxes` | `Double` | Yes | Applicable taxes/GST (₹0 in V1; backend configurable). |
| `totalAmount` | `Double` | Yes | Final payable amount at venue counter (₹). Must match sum of fees. |
| `paymentMethod` | `String` | Yes | Payment mode enum/string: `"Pay at Venue (Offline)"`. |
| `playerId` | `String` | Optional | Authenticated player user ID (null for guest checkout). |
| `playerName` | `String` | Optional | Authenticated player display name. |

#### Booking Reference Generation Format
The booking reference follows the standardized, human-readable format:
```
PKL-BKG-YYYYMMDD-XXXX
```
- `PKL-BKG`: Fixed system prefix denoting Pickleball court booking.
- `YYYYMMDD`: 8-digit date string representing the creation date (e.g. `20261109`).
- `XXXX`: 4-character alphanumeric uppercase random token or sequential sequence (e.g. `742B`, `9K3M`).
- Example: `PKL-BKG-20261109-8A3F`

#### Booking Statuses
- `confirmed`: The court slot is officially reserved for the player.
- `paymentPending`: The reservation is held, pending offline counter payment at the venue.
- In V1 UI, bookings are presented as **"Confirmed (Pay at Venue)"**, with status code `BookingStatus.confirmed` and payment status pending.

#### Confirmation Response Payload
Upon successful creation, the backend/repository returns the full `CourtBooking` entity:

```json
{
  "id": "bkg_1731132000000",
  "bookingReference": "PKL-BKG-20261109-7A8B",
  "venueId": "org_venue_001",
  "venueName": "Andheri Central Pickleball Club",
  "venueAddress": "12 Sports Complex Road, Andheri West",
  "venueCity": "Mumbai",
  "courtId": "court_org_venue_001_1",
  "courtName": "Court 1 (Center Court)",
  "courtSurface": "Pro Cushion",
  "date": "2026-11-09T00:00:00.000",
  "slotId": "slot_court_org_venue_001_1_2026-11-09_06-00",
  "slotTime": "06:00 - 07:00",
  "startTime": "06:00",
  "endTime": "07:00",
  "durationMinutes": 60,
  "courtFee": 600.0,
  "platformFee": 0.0,
  "taxes": 0.0,
  "totalAmount": 600.0,
  "paymentMethod": "Pay at Venue (Offline)",
  "status": "confirmed",
  "playerId": "usr_player_001",
  "playerName": "Aarav Sharma",
  "createdAt": "2026-11-09T05:40:00.000Z"
}
```

#### Offline Payment Tracking & Slot Hold Requirements
1. **Pay at Venue Workflow:** V1 does not incorporate online payment gateways (Razorpay, Stripe, etc.). The booking is created immediately with offline payment instructions provided on both the Checkout and Confirmation screens.
2. **30-Minute Pending Slot Hold:** When a booking is confirmed with offline payment, the venue manager/system must hold the reserved court slot for **up to 30 minutes** prior to slot start time (or until check-in). If the player fails to check in and pay at the venue reception within the designated hold grace period, the slot may be released or marked `no_show`.
3. **Venue Reception Verification:** The player presents their Booking Reference (`PKL-BKG-YYYYMMDD-XXXX`) at the venue reception to complete offline payment (Cash/UPI/POS) and receive court access.

---

### 5.5 Player My Bookings & Booking History UI (Feature 2.3)

#### Screen Overview
The My Bookings experience allows players to track all current and historical court reservations across 3 distinct categories: **Upcoming**, **Past**, and **Cancelled**. Each category displays interactive booking cards with live status indicators, scheduling, venue allocation, and offline payment advisories. Selecting any card navigates to the detailed Booking Details screen (`/player/bookings/:id`) offering complete pricing breakdowns, venue directions, reference copy actions, and safe cancellation workflows.

- **List Route:** `/player/bookings` (`AppRoutes.playerBookings`)
- **Details Route:** `/player/bookings/:id` (`AppRoutes.playerBookingDetails`)
- **Domain Entities:** `CourtBooking`, `BookingStatus` (`confirmed`, `paymentPending`, `completed`, `cancelled`)
- **Cubits:** `MyBookingsCubit` (`MyBookingsState`), `BookingDetailsCubit` (`BookingDetailsState`)

#### Proposed Backend API Contracts

##### 1. Retrieve Player Bookings History
- **Endpoint:** `GET /api/v1/player/bookings`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Query Parameters (Optional):**
  - `status`: Filter by status (`confirmed`, `paymentPending`, `completed`, `cancelled`).
  - `category`: Filter by category (`upcoming`, `past`, `cancelled`).
- **Player Scoping:** The backend must scope the query strictly to the authenticated `playerId` derived from the JWT claims to guarantee zero cross-tenant leakage.

**Proposed Success Response (`200 OK`):**
```json
{
  "total": 4,
  "upcomingCount": 2,
  "pastCount": 1,
  "cancelledCount": 1,
  "bookings": [
    {
      "id": "bkg_mock_001",
      "bookingReference": "PKL-BKG-20261110-0001",
      "venueId": "org_venue_001",
      "venueName": "Grand Slam Pickleball Arena",
      "venueAddress": "742 Evergreen Terrace, Andheri West",
      "venueCity": "Mumbai",
      "courtId": "court_org_venue_001_1",
      "courtName": "Court 1 (Championship Cushioned)",
      "surfaceType": "Pro Cushion",
      "date": "2026-11-10T07:00:00.000",
      "slotId": "slot_001",
      "slotTime": "07:00 - 08:00",
      "startTime": "07:00",
      "endTime": "08:00",
      "durationMinutes": 60,
      "courtFee": 700.0,
      "platformFee": 0.0,
      "taxes": 0.0,
      "totalAmount": 700.0,
      "status": "confirmed",
      "paymentMethod": "Pay at Venue (Offline)",
      "paymentStatus": "pending",
      "playerId": "user_player_001",
      "playerName": "Alex Rivera",
      "createdAt": "2026-11-09T06:00:00.000Z"
    }
  ]
}
```

##### 2. Retrieve Booking Details by ID
- **Endpoint:** `GET /api/v1/player/bookings/{id}`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Response:** Returns the full `CourtBooking` JSON object.
- **Errors:** `404 Not Found` if the booking does not exist or does not belong to the authenticated player.

##### 3. Cancel Booking
- **Endpoint:** `POST /api/v1/player/bookings/{id}/cancel`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Rules & Restrictions:**
  - Permitted only if the booking belongs to the authenticated player.
  - Permitted only if the booking is currently in `confirmed` or `paymentPending` status.
  - Permitted only if the booking date/time has not elapsed.
  - On cancellation, updates status to `cancelled`, releases the held court slot back into availability, and dispatches a booking cancellation notification.
  - In V1 (offline payment model), no refund transactions or penalty fees are processed.

**Proposed Success Response (`200 OK`):**
```json
{
  "message": "Booking PKL-BKG-20261110-0001 has been cancelled successfully.",
  "booking": {
    "id": "bkg_mock_001",
    "bookingReference": "PKL-BKG-20261110-0001",
    "status": "cancelled",
    "updatedAt": "2026-11-09T06:30:00.000Z"
  }
}
```

#### Filtering & Sorting Business Rules
| Tab / Category | Status Criteria | Date Criteria | Sort Order |
|---|---|---|---|
| **Upcoming** | `status IN ('confirmed', 'paymentPending')` | `date >= today` | Ascending by `date` (earliest game first) |
| **Past** | `status == 'completed'` OR `date < today` (and not cancelled) | Historical | Descending by `date` (most recent game first) |
| **Cancelled** | `status == 'cancelled'` | Any date | Descending by `date` (most recently cancelled first) |

---

### 5.6 Player Match Day Hub (Feature 2.4)

#### Screen Overview
The Player Match Day Hub is the operational destination for registered tournament players on game day. Accessible from the Player Dashboard (`Upcoming Activities` fixture card and `Match Day` quick action), it provides centralized access to the active tournament overview, the player's personalized schedule and check-in workflows, live court scoreboards across all tournament courts, group stage standings, and the knockout elimination bracket.

- **Route:** `/player/match-day` (`AppRoutes.playerMatchDay`)
- **Domain Entities:** `PlayerMatchDayData`, `PlayerMatch`, `CourtLiveMatch`, `StandingsRow`, `BracketNode`, `MatchStatus` (`scheduled`, `warmup`, `live`, `completed`, `delayed`)
- **Cubit / State:** `MatchDayCubit` (`MatchDayInitial`, `MatchDayLoading`, `MatchDayLoaded`, `MatchDayFailure`)
- **Tabs:** `MatchDayTab.mySchedule` ("My Schedule"), `MatchDayTab.liveScores` ("Live Courts"), `MatchDayTab.bracketStandings` ("Bracket & Pools")

#### Proposed Backend API Contracts

##### 1. Retrieve Player Match Day Aggregate Data
- **Endpoint:** `GET /api/v1/player/match-day`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Query Parameters (Optional):**
  - `tournamentId`: Specific active tournament identifier (defaults to player's current active tournament).
- **Player Scoping:** The response is scoped to the authenticated player via JWT claims to populate `myMatches` and identify the player's seeds and opponent pairings.

**Proposed Success Response (`200 OK`):**
```json
{
  "tournamentId": "tourn_001",
  "tournamentName": "National Pickleball Open 2026",
  "tournamentVenue": "Grand Slam Pickleball Arena",
  "date": "2026-11-09T00:00:00.000Z",
  "myMatches": [
    {
      "id": "match_live_001",
      "tournamentId": "tourn_001",
      "tournamentName": "National Pickleball Open 2026",
      "category": "Men's Singles Open",
      "round": "Semi-Final",
      "courtName": "Court 1 (Championship Court)",
      "scheduledTime": "2026-11-09T15:45:00.000Z",
      "status": "live",
      "player1Name": "Alex Rivera",
      "player1Seed": 5,
      "player1Score": [11, 8, 6],
      "player2Name": "Jordan Cruz",
      "player2Seed": 3,
      "player2Score": [9, 11, 4],
      "currentSet": 3,
      "serverIndex": 1,
      "refereeName": "Carlos Vega",
      "winnerName": null,
      "isCheckedIn": true
    },
    {
      "id": "match_sched_002",
      "tournamentId": "tourn_001",
      "tournamentName": "National Pickleball Open 2026",
      "category": "Mixed Doubles 3.5",
      "round": "Quarter-Final",
      "courtName": "Court 3",
      "scheduledTime": "2026-11-09T17:30:00.000Z",
      "status": "scheduled",
      "player1Name": "Alex Rivera / Maya Lin",
      "player1Seed": 2,
      "player1Score": [],
      "player2Name": "Rohan Verma / Priya Rao",
      "player2Seed": 4,
      "player2Score": [],
      "currentSet": 1,
      "serverIndex": 1,
      "refereeName": "Sara Connor",
      "winnerName": null,
      "isCheckedIn": false,
      "checkInDeadline": "2026-11-09T17:15:00.000Z"
    }
  ],
  "courtMatches": [
    {
      "courtId": "court_1",
      "courtName": "Court 1 (Championship Court)",
      "tournamentName": "National Pickleball Open 2026",
      "category": "Men's Singles Open",
      "currentMatch": { "id": "match_live_001", "score": "11-9, 8-11, 6-4" },
      "nextMatch": { "id": "court1_next", "scheduledTime": "17:00" }
    }
  ],
  "standings": [
    {
      "rank": 1,
      "playerName": "Alex Rivera",
      "pool": "Pool A",
      "matchesPlayed": 3,
      "matchesWon": 3,
      "matchesLost": 0,
      "pointDifferential": 18,
      "isQualified": true
    }
  ],
  "bracket": [
    {
      "id": "sf_1",
      "roundName": "Semi-Finals",
      "matchIndex": 1,
      "player1": "Alex Rivera",
      "player1Seed": 5,
      "player1Score": "11, 8, 6",
      "player2": "Jordan Cruz",
      "player2Seed": 3,
      "player2Score": "9, 11, 4",
      "isLive": true,
      "court": "Court 1"
    }
  ]
}
```

##### 2. Check In to Match
- **Endpoint:** `POST /api/v1/player/match-day/matches/{id}/check-in`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Business Rules:**
  - Marks the player as present and available for court call.
  - Returns `400 Bad Request` if check-in deadline has expired.
  - Updates match status to `warmup` or flags player as checked-in for referee / tournament desk queue.

**Proposed Success Response (`200 OK`):**
```json
{
  "message": "Player successfully checked in for match fixture.",
  "matchId": "match_sched_002",
  "isCheckedIn": true,
  "checkInTimestamp": "2026-11-09T17:05:00.000Z"
}
```

#### Screen Elements & Interactions
1. **Tournament Header Card**: Tournament name, venue location, game date, active match badge count.
2. **Tab 1 — My Schedule**:
   - Player's fixtures for the day (live, upcoming, completed).
   - Set-by-set score display, serving indicators, referee assignment.
   - Interactive Check-in action button for scheduled matches.
3. **Tab 2 — Live Courts**:
   - All court allocation monitor with live match progress and next match queue.
4. **Tab 3 — Bracket & Pools**:
   - Filterable group stage standings table with qualification status.
   - Elimination draw tree across Quarter-finals, Semi-finals, and Final.
5. **Empty State**: Friendly card with "Explore Tournaments" CTA when the player has no fixtures today.### 5.7 Feature 2.5 — Player Tournament Discovery & Registration

#### Overview
Feature 2.5 implements the Player Tournament Discovery & Registration module according to Player PRD v1.6. It allows players to search, filter, and discover sanctioned/community pickleball tournaments, inspect division-specific eligibility (skill tier, DUPR rating bracket, age restrictions, capacity), review tournament rules and format, register for singles or doubles events, provide partner and emergency details, accept waivers, and view registration confirmation receipts with unique reference IDs.

#### Proposed API Contracts (Awaiting Backend Confirmation)

> [!IMPORTANT]
> **API Status: PROPOSED — PENDING BACKEND CONFIRMATION**  
> The endpoints, request payloads, and response structures below are proposed by the Flutter client. Spring Boot backend services must review and formalize these interfaces.

##### 1. List Tournaments with Filters & Sorting
- **Endpoint:** `GET /api/v1/player/tournaments`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Query Parameters:**
  - `query` (optional `string`): Text search matching tournament name, organizer, venue, or city.
  - `status` (optional `string`): `registrationOpen`, `upcoming`, `inProgress`, `completed`, `cancelled`.
  - `category` (optional `string`): Division category filter (`singles`, `doubles`, `mixed`, `senior`, `junior`).
  - `openOnly` (optional `boolean`): Only tournaments with open registration spots.
  - `myEntriesOnly` (optional `boolean`): Only tournaments the logged-in player is registered for.
  - `sort` (optional `string`): `dateAsc`, `dateDesc`, `feeLow`, `feeHigh`, `prizePoolHigh`.

**Proposed Response (`200 OK`):**
```json
{
  "tournaments": [
    {
      "id": "tourn_002",
      "name": "Monsoon Community Cup 2026",
      "organizerName": "Pinnacle Sports Academy",
      "venueName": "Pinnacle Sports Academy (Downtown)",
      "address": "Plot 12, Senapati Bapat Marg, Lower Parel",
      "city": "Mumbai",
      "imageUrl": "assets/images/venues/pinnacle_sports.jpg",
      "status": "registrationOpen",
      "startDate": "2026-11-20T09:00:00Z",
      "endDate": "2026-11-22T19:00:00Z",
      "registrationDeadline": "2026-11-18T23:59:00Z",
      "prizePool": "₹50,000",
      "entryFeeFrom": 800.0,
      "description": "Community-first weekend tournament designed for intermediate and advanced recreational players.",
      "scoringFormat": "Rounds 1-3: 1 game to 15 (win by 2). Finals: Best 2 of 3 to 11.",
      "rules": [
        "Paddle face must be smooth with no unapproved grit modifications.",
        "Withdrawal deadline with 100% refund is 48 hours prior to registration close."
      ],
      "categories": [
        {
          "id": "cat_002_ms",
          "name": "Men's Singles 3.5",
          "isDoubles": false,
          "minRating": 3.0,
          "maxRating": 3.75,
          "entryFee": 800.0,
          "maxParticipants": 16,
          "registeredCount": 12,
          "isRegistrationOpen": true
        },
        {
          "id": "cat_002_md",
          "name": "Mixed Doubles Open",
          "isDoubles": true,
          "entryFee": 1400.0,
          "maxParticipants": 16,
          "registeredCount": 10,
          "isRegistrationOpen": true
        }
      ],
      "isRegistered": false,
      "registeredCategoryIds": []
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 20
}
```

##### 2. Get Tournament Details
- **Endpoint:** `GET /api/v1/player/tournaments/{id}`
- **Headers:** `Authorization: Bearer <jwt_access_token>`

**Proposed Response (`200 OK`):**
Returns the detailed `TournamentItem` matching the requested ID, including categories, eligibility rules, and registration states.

##### 3. Register for Tournament Category
- **Endpoint:** `POST /api/v1/player/tournaments/{id}/register`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Proposed Request Payload:**
```json
{
  "tournamentId": "tourn_002",
  "categoryId": "cat_002_ms",
  "playerName": "Alex Rivera",
  "playerPhone": "+91 98765 43210",
  "playerEmail": "alex.rivera@example.com",
  "playerRating": 3.5,
  "partnerName": null,
  "partnerPhone": null,
  "tshirtSize": "L",
  "emergencyContactName": "Elena Rivera",
  "emergencyContactPhone": "+91 98765 00000",
  "acceptedWaiver": true,
  "acceptedRules": true,
  "entryFee": 800.0
}
```

**Proposed Success Response (`201 Created` or `200 OK`):**
```json
{
  "id": "PKL-TRN-20261120-7214",
  "tournamentId": "tourn_002",
  "tournamentName": "Monsoon Community Cup 2026",
  "categoryId": "cat_002_ms",
  "categoryName": "Men's Singles 3.5",
  "venueName": "Pinnacle Sports Academy (Downtown)",
  "dates": "Nov 20 - 22, 2026",
  "playerName": "Alex Rivera",
  "partnerName": null,
  "tshirtSize": "L",
  "entryFee": 800.0,
  "status": "confirmed",
  "registeredAt": "2026-11-09T12:00:00Z"
}
```

**Proposed Error Responses:**
- **`400 Bad Request` (Validation Failed):** Partner name missing for doubles, or waivers not accepted.
- **`403 Forbidden` (Eligibility Ineligible):** Player DUPR rating or age outside category limits.
- **`409 Conflict` (Duplicate Entry):** Player already registered in this division.

##### 4. Withdraw Registration
- **Endpoint:** `POST /api/v1/player/tournaments/registrations/{id}/withdraw`
- **Headers:** `Authorization: Bearer <jwt_access_token>`

**Proposed Success Response (`200 OK`):**
```json
{
  "message": "Registration withdrawn successfully. Spot released.",
  "registrationId": "PKL-TRN-20261120-7214",
  "status": "withdrawn"
}
```
### 5.7 Feature 2.5 — Player Tournament Discovery & Registration

#### Overview
Feature 2.5 implements the Player Tournament Discovery & Registration module according to Player PRD v1.6. It allows players to search, filter, and discover sanctioned/community pickleball tournaments, inspect division-specific eligibility (skill tier, DUPR rating bracket, age restrictions, capacity), review tournament rules and format, register for singles or doubles events, provide partner and emergency details, accept waivers, and view registration confirmation receipts with unique reference IDs.

#### Proposed API Contracts (Awaiting Backend Confirmation)

> [!IMPORTANT]
> **API Status: PROPOSED — PENDING BACKEND CONFIRMATION**  
> The endpoints, request payloads, and response structures below are proposed by the Flutter client. Spring Boot backend services must review and formalize these interfaces.

##### 1. List Tournaments with Filters & Sorting
- **Endpoint:** `GET /api/v1/player/tournaments`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Query Parameters:**
  - `query` (optional `string`): Text search matching tournament name, organizer, venue, or city.
  - `status` (optional `string`): `registrationOpen`, `upcoming`, `inProgress`, `completed`, `cancelled`.
  - `category` (optional `string`): Division category filter (`singles`, `doubles`, `mixed`, `senior`, `junior`).
  - `openOnly` (optional `boolean`): Only tournaments with open registration spots.
  - `myEntriesOnly` (optional `boolean`): Only tournaments the logged-in player is registered for.
  - `sort` (optional `string`): `dateAsc`, `dateDesc`, `feeLow`, `feeHigh`, `prizePoolHigh`.

**Proposed Response (`200 OK`):**
```json
{
  "tournaments": [
    {
      "id": "tourn_002",
      "name": "Monsoon Community Cup 2026",
      "organizerName": "Pinnacle Sports Academy",
      "venueName": "Pinnacle Sports Academy (Downtown)",
      "address": "Plot 12, Senapati Bapat Marg, Lower Parel",
      "city": "Mumbai",
      "imageUrl": "assets/images/venues/pinnacle_sports.jpg",
      "status": "registrationOpen",
      "startDate": "2026-11-20T09:00:00Z",
      "endDate": "2026-11-22T19:00:00Z",
      "registrationDeadline": "2026-11-18T23:59:00Z",
      "prizePool": "₹50,000",
      "entryFeeFrom": 800.0,
      "description": "Community-first weekend tournament designed for intermediate and advanced recreational players.",
      "scoringFormat": "Rounds 1-3: 1 game to 15 (win by 2). Finals: Best 2 of 3 to 11.",
      "rules": [
        "Paddle face must be smooth with no unapproved grit modifications.",
        "Withdrawal deadline with 100% refund is 48 hours prior to registration close."
      ],
      "categories": [
        {
          "id": "cat_002_ms",
          "name": "Men's Singles 3.5",
          "isDoubles": false,
          "minRating": 3.0,
          "maxRating": 3.75,
          "entryFee": 800.0,
          "maxParticipants": 16,
          "registeredCount": 12,
          "isRegistrationOpen": true
        },
        {
          "id": "cat_002_md",
          "name": "Mixed Doubles Open",
          "isDoubles": true,
          "entryFee": 1400.0,
          "maxParticipants": 16,
          "registeredCount": 10,
          "isRegistrationOpen": true
        }
      ],
      "isRegistered": false,
      "registeredCategoryIds": []
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 20
}
```

##### 2. Get Tournament Details
- **Endpoint:** `GET /api/v1/player/tournaments/{id}`
- **Headers:** `Authorization: Bearer <jwt_access_token>`

**Proposed Response (`200 OK`):**
Returns the detailed `TournamentItem` matching the requested ID, including categories, eligibility rules, and registration states.

##### 3. Register for Tournament Category
- **Endpoint:** `POST /api/v1/player/tournaments/{id}/register`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Proposed Request Payload:**
```json
{
  "tournamentId": "tourn_002",
  "categoryId": "cat_002_ms",
  "playerName": "Alex Rivera",
  "playerPhone": "+91 98765 43210",
  "playerEmail": "alex.rivera@example.com",
  "playerRating": 3.5,
  "partnerName": null,
  "partnerPhone": null,
  "tshirtSize": "L",
  "emergencyContactName": "Elena Rivera",
  "emergencyContactPhone": "+91 98765 00000",
  "acceptedWaiver": true,
  "acceptedRules": true,
  "entryFee": 800.0
}
```

**Proposed Success Response (`201 Created` or `200 OK`):**
```json
{
  "id": "PKL-TRN-20261120-7214",
  "tournamentId": "tourn_002",
  "tournamentName": "Monsoon Community Cup 2026",
  "categoryId": "cat_002_ms",
  "categoryName": "Men's Singles 3.5",
  "venueName": "Pinnacle Sports Academy (Downtown)",
  "dates": "Nov 20 - 22, 2026",
  "playerName": "Alex Rivera",
  "partnerName": null,
  "tshirtSize": "L",
  "entryFee": 800.0,
  "status": "confirmed",
  "registeredAt": "2026-11-09T12:00:00Z"
}
```

**Proposed Error Responses:**
- **`400 Bad Request` (Validation Failed):** Partner name missing for doubles, or waivers not accepted.
- **`403 Forbidden` (Eligibility Ineligible):** Player DUPR rating or age outside category limits.
- **`409 Conflict` (Duplicate Entry):** Player already registered in this division.

##### 4. Withdraw Registration
- **Endpoint:** `POST /api/v1/player/tournaments/registrations/{id}/withdraw`
- **Headers:** `Authorization: Bearer <jwt_access_token>`

**Proposed Success Response (`200 OK`):**
```json
{
  "message": "Registration withdrawn successfully. Spot released.",
  "registrationId": "PKL-TRN-20261120-7214",
  "status": "withdrawn"
}
```


### 5.8 Feature 2.6 — Player Marketplace Shopping Experience

#### Overview
Feature 2.6 implements the complete Player Marketplace Shopping Experience according to Player PRD v1.6 and Frontend FSD §3.2. It enables players to browse an equipment/merchandise catalog, search and filter gear (paddles, balls, shoes, bags, apparel, accessories), inspect detailed product specs and return windows, save wishlist items, manage a dynamic shopping cart, complete checkout with delivery address validation and pay-upon-receipt payment, and track the step-by-step shipment timeline of their placed orders with self-service cancellation for eligible orders.

- **Catalogue Route:** `/player/marketplace` (`AppRoutes.playerMarketplace`)
- **Product Details Route:** `/player/marketplace/products/:id` (`AppRoutes.playerProductDetails`)
- **Cart Route:** `/player/marketplace/cart` (`AppRoutes.playerMarketplaceCart`)
- **Wishlist Route:** `/player/marketplace/wishlist` (`AppRoutes.playerMarketplaceWishlist`)
- **Checkout Route:** `/player/marketplace/checkout` (`AppRoutes.playerMarketplaceCheckout`)
- **My Orders Route:** `/player/marketplace/orders` (`AppRoutes.playerMarketplaceOrders`)
- **Order Details Route:** `/player/marketplace/orders/:id` (`AppRoutes.playerMarketplaceOrderDetails`)

#### Proposed API Contracts (Awaiting Backend Implementation)

##### 1. Get Product Catalog
- **Endpoint:** `GET /api/v1/player/marketplace/products`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Query Parameters:**
  - `query` (optional string): Keyword search matching title, brand, or description.
  - `category` (optional enum): `paddles`, `balls`, `equipment`, `footwear`, `apparel`, `accessories`.
  - `minPrice` (optional float): Minimum price bound in INR.
  - `maxPrice` (optional float): Maximum price bound in INR.
  - `inStockOnly` (optional boolean): Filter only items with `stockCount > 0`.
  - `minRating` (optional float): Filter products by minimum rating (e.g. 4.0, 4.5).
  - `brand` (optional string): Filter products by brand name.
  - `sort` (optional enum): `featured`, `priceLow`, `priceHigh`, `ratingHigh`, `newest`.

**Proposed Success Response (`200 OK`):**
```json
{
  "products": [
    {
      "id": "prod_001",
      "title": "Pro Carbon 3K Precision Paddle",
      "brand": "Apex Paddle & Gear Co.",
      "sellerName": "Apex Paddle & Gear Co.",
      "description": "Engineered for aggressive tournament play with 3K raw carbon fiber face and 16mm core.",
      "price": 11999.0,
      "originalPrice": 13499.0,
      "rating": 4.8,
      "reviewCount": 124,
      "category": "paddles",
      "imageUrl": "https://cdn.pickleball.com/products/prod_001.jpg",
      "galleryImages": [
        "https://cdn.pickleball.com/products/prod_001_1.jpg",
        "https://cdn.pickleball.com/products/prod_001_2.jpg"
      ],
      "inStock": true,
      "stockCount": 18,
      "returnPolicyDays": 7,
      "specifications": {
        "Core": "16mm Polymer Honeycomb",
        "Face": "3K Toray Raw Carbon Fiber",
        "Weight": "7.9 - 8.3 oz",
        "Grip Size": "4 1/4 inch",
        "USAPA Approved": "Yes"
      },
      "availableSizes": [],
      "availableColors": ["Stealth Black", "Neon Lime"],
      "isFeatured": true,
      "isWishlisted": false
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 20
}
```

##### 2. Get Product Details
- **Endpoint:** `GET /api/v1/player/marketplace/products/{id}`
- **Headers:** `Authorization: Bearer <jwt_access_token>`

**Proposed Response (`200 OK`):** Returns the full `MarketplaceProduct` representation.

##### 3. Get / Toggle Wishlist
- **Get Wishlist:** `GET /api/v1/player/marketplace/wishlist`
- **Toggle Wishlist:** `POST /api/v1/player/marketplace/wishlist/{productId}/toggle`
- **Response (`200 OK`):** `{"isWishlisted": true, "productId": "prod_001"}`

##### 4. Shopping Cart Endpoints
- **Get Cart:** `GET /api/v1/player/marketplace/cart`
- **Add to Cart:** `POST /api/v1/player/marketplace/cart`
  - Body: `{"productId": "prod_001", "quantity": 1, "size": "UK 9", "color": "Stealth Black"}`
- **Update Quantity:** `PUT /api/v1/player/marketplace/cart/{itemId}`
  - Body: `{"quantity": 3}`
- **Remove Item:** `DELETE /api/v1/player/marketplace/cart/{itemId}`
- **Clear Cart:** `DELETE /api/v1/player/marketplace/cart`

##### 5. Place Marketplace Order (Checkout)
- **Endpoint:** `POST /api/v1/player/marketplace/orders`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Request Payload:**
```json
{
  "items": [
    {
      "productId": "prod_001",
      "quantity": 1,
      "selectedSize": null,
      "selectedColor": "Stealth Black",
      "price": 11999.0
    }
  ],
  "deliveryAddress": {
    "fullName": "Aarav Sharma",
    "phoneNumber": "9876543210",
    "streetAddress": "Flat 402, Green Glen Layout, Bellandur",
    "city": "Bengaluru",
    "state": "Karnataka",
    "postalCode": "560103",
    "landmark": "Opposite Community Park"
  },
  "paymentMethod": "Pay upon Receipt (UPI / Cash)",
  "subtotal": 11999.0,
  "deliveryFee": 0.0,
  "totalAmount": 11999.0
}
```
- **Response (`201 Created`):**
```json
{
  "id": "PKL-ORD-20261109-8421",
  "orderDate": "2026-11-09T15:30:00Z",
  "status": "placed",
  "paymentMethod": "Pay upon Receipt (UPI / Cash)",
  "paymentStatus": "Pending Delivery",
  "subtotal": 11999.0,
  "deliveryFee": 0.0,
  "totalAmount": 11999.0,
  "estimatedDeliveryDate": "2026-11-13T18:00:00Z",
  "trackingTimeline": [
    {
      "title": "Order Placed",
      "description": "Your order has been verified and confirmed.",
      "timestamp": "2026-11-09T15:30:00Z",
      "isCompleted": true,
      "isCurrent": false
    },
    {
      "title": "Processing",
      "description": "Seller is preparing items for dispatch.",
      "timestamp": null,
      "isCompleted": false,
      "isCurrent": true
    }
  ]
}
```

##### 6. Order Cancellation
- **Endpoint:** `POST /api/v1/player/marketplace/orders/{id}/cancel`
- **Headers:** `Authorization: Bearer <jwt_access_token>`
- **Request Payload:** `{"reason": "Ordered wrong paddle weight"}`
- **Business Rule:** Rejects cancellation with `400 Bad Request` if order status has progressed beyond `placed` or `processing`.

---
