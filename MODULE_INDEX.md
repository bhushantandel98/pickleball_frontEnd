# MODULE INDEX & SCREEN REGISTRY

**Project:** Pickleball Multi-Role Platform (Frontend)  
**Version:** 1.0.0  
**Baseline:** Frontend FSD v1.0  

---

## 1. Feature & Module Registry

| Module Name | Directory | Primary Role(s) | Primary Repository Interface | Key Route Prefix |
|---|---|---|---|---|
| **Identity & Auth** | `lib/features/identity` | All / Public | `AuthRepository` | `/auth` |
| **Role & Context** | `lib/features/role_selection` | All Authenticated | `RoleContextRepository` | `/role-selection` |
| **Notifications** | `lib/features/notifications` | All Authenticated | `NotificationRepository` | `/notifications` |
| **Player** | `lib/features/player` | Player | `PlayerRepository` | `/player` |
| **Coach** | `lib/features/coach` | Coach | `CoachRepository` | `/coach` |
| **Academy** | `lib/features/academy` | Academy Admin | `AcademyRepository` | `/academy` |
| **Academy Staff** | `lib/features/academy_staff` | Academy Staff | `AcademyStaffRepository` | `/academy-staff` |
| **Venue Partner** | `lib/features/venue_partner` | Venue Partner | `VenueRepository` | `/venue-partner` |
| **Venue Staff** | `lib/features/venue_staff` | Venue Staff | `VenueStaffRepository` | `/venue-staff` |
| **Tournament Organizer**| `lib/features/tournament_organizer` | Organizer | `TournamentOrganizerRepository` | `/tournament-organizer` |
| **Tournament Staff** | `lib/features/tournament_staff` | Tournament Staff | `TournamentStaffRepository` | `/tournament-staff` |
| **Referee** | `lib/features/referee` | Referee | `RefereeRepository` | `/referee` |
| **Marketplace Seller** | `lib/features/marketplace_seller` | Seller | `MarketplaceSellerRepository` | `/marketplace-seller` |
| **Application Staff** | `lib/features/application_staff` | Application Staff | `AppStaffRepository` | `/application-staff` |
| **Application Admin** | `lib/features/application_admin` | Sole App Admin | `AppAdminRepository` | `/application-admin` |
| **Public Tournament** | `lib/features/public_tournament` | Public / Unauthenticated | `PublicTournamentRepository` | `/public/tournaments` |

---

## 2. Screen Inventory & Route Map

### 2.1 Identity & Shared Services (Phase 1)
- `/auth/welcome` — Welcome & Entry Screen ([`WelcomePage`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/welcome_page.dart)) [Implemented - Phase 1.1.1]
- `/auth/login` — Phone & Password Login with toggle password visibility ([`LoginPage`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/login_page.dart)) [Implemented - Phase 1.1.2]
- `/auth/register` — Player Self-Registration & OTP verification ([`RegisterPage`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/register_page.dart)) [Implemented - Phase 1.1.3]
- `/auth/forgot-password` — Password Recovery ([`ForgotPasswordPage`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/forgot_password_page.dart)) [Implemented - Phase 1.1.4]
- `/account-status` — Account status gate (Active / Restricted / Suspended)
- `/account-suspended` — Suspended account notice with support email/contact
- `/role-selection` — Multi-role selector & "Remember preferred role" switch ([`RoleSelectionPage`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/presentation/pages/role_selection_page.dart)) [Implemented - Phase 1.1.5]
- `/notifications` — Notification Center (List, Unread count, Mark read, Preferences)
- `/profile` — Personal Profile view/edit

### 2.2 Player Module (Phase 2)
- `/player/dashboard` — Home dashboard, quick actions, recent activity
- `/player/discovery/academies` — Academy & Coach directory with search/filters
- `/player/discovery/venues` — Court discovery, slot availability view
- `/player/bookings` — My bookings (Upcoming/Past, Cancel/Reschedule, Offline payment status)
- `/player/tournaments` — Tournament browse, category selection, registration status
- `/player/match-day` — My match schedule, live score, standings, brackets
- `/player/marketplace` — Products catalog, order placement, order history, tracking

### 2.3 Coach & Academy Modules (Phase 3)
- `/coach/dashboard` — Session schedule, assigned batches, quick attendance
- `/coach/batches` — Batch roster, player attendance logging, skill assessments
- `/academy/dashboard` — Multi-branch overview, student count, staff summary
- `/academy/branches` — Branch profiles, courts, and operational hours
- `/academy/programs` — Coaching programs, batches, and fee structures
- `/academy/coaches` — Coach directory, invitations, batch assignments
- `/academy/enrollments` — Student enrollments, fee records, attendance reports
- `/academy-staff/dashboard` — Delegated operations scoped by assigned permissions

### 2.4 Venue Partner & Venue Staff Modules (Phase 4)
- `/venue-partner/dashboard` — Revenue summary, court utilization, today's schedule
- `/venue-partner/locations` — Venue facilities, courts, operating hours, slot pricing
- `/venue-partner/calendar` — Court booking calendar, slot lock/block actions
- `/venue-partner/bookings` — Booking requests, check-in status, manual payment status logging
- `/venue-staff/dashboard` — Daily court operations, check-in scanner, expense slips

### 2.5 Tournament Operations Modules (Phase 5)
- `/tournament-organizer/dashboard` — Active tournaments, registration counters, schedule health
- `/tournament-organizer/create` — Tournament creation wizard (events, capacity, scoring rules)
- `/tournament-organizer/:id/draws` — Draw generation, seeding, court scheduling
- `/tournament-organizer/:id/staff` — Staff delegation & referee court assignment
- `/tournament-staff/dashboard` — Match check-in, score monitoring, delegated actions
- `/referee/dashboard` — Assigned matches list and upcoming fixtures
- `/referee/match/:id/scoring` — Live scoring interface (rules locked to organizer spec)
- `/public/tournaments/:id` — Public live bracket, scoreboards, standings (No auth required)

### 2.6 Marketplace Seller Module (Phase 6)
- `/marketplace-seller/onboarding` — KYC & business document submission
- `/marketplace-seller/dashboard` — Product catalog status, orders pending fulfillment, earnings
- `/marketplace-seller/products/create` — Draft product creator (media, price, stock, return window)
- `/marketplace-seller/orders` — Orders pipeline (Processing, Dispatched, Delivered, Return requested)
- `/marketplace-seller/settlements` — Verified settlement records & commission statements

### 2.7 Application Staff & Application Admin Modules (Phase 7)
- `/application-staff/dashboard` — Verification queues (sellers, products, disputed reports)
- `/application-admin/dashboard` — Platform macro-metrics, user directory, organization directory
- `/application-admin/staff-management` — Staff account creation & granular capability assignment
- `/application-admin/policies` — Global commission structures & terms configuration
- `/application-admin/audit-logs` — Immutable audit log inspection (restricted access)

---

## 3. Design System Registry & Atomic Component Suite

### 3.1 Design System Tokens (`lib/core/design_system/`)
- `AppColors` (`app_colors.dart`) — Brand Court Green (`#1B5E20`), surface, text, semantic feedback, border tokens.
- `AppSpacing` (`app_spacing.dart`) — 4pt/8pt grid scale, border radii, elevations, icon sizes, component dimensions, and web maximum widths (`maxContentWidth: 1200`, `maxTableWidth: 1440`, `maxFormWidth: 640`, `maxModalWidth: 560`).
- `AppTypography` (`app_typography.dart`) — Material 3 text scales (Display, Headline, Title, Body, Label) with accessible contrast.
- `AppTheme` (`app_theme.dart`) — Centralized Material 3 `lightTheme` and `darkTheme` with component theme configurations.
- `ResponsiveLayout` (`responsive_layout.dart`) — Breakpoint engine (mobile <600, tablet 600-1024, desktop >1024), `ResponsiveContainer`, `ResponsiveRowColumn`, and `ResponsiveContext` extension.

### 3.2 Reusable Atomic Widgets (`lib/core/widgets/`)
- `AppButton` (`app_button.dart`) — Primary, secondary, outline, text, and destructive button variants with loading spinner.
- `AppTextField` (`app_text_field.dart`) — Text, phone, email, and secure password input with visibility toggle.
- `AppDropdown` (`app_dropdown.dart`) — Standardized dropdown select form field.
- `AppCard` (`app_card.dart`) — Surface card container with theme border radius, padding, and ink response.
- `AppChip` (`app_chip.dart`) — Status chips for active, pending, rejected, and draft entities.
- `CommonAppBar` (`common_app_bar.dart`) — Consistent app bar with title, role subtitle, and action items.
- `AppConfirmationDialog` (`app_dialog.dart`) — Consequence-aware confirmation dialog for destructive or high-impact actions.
- `AdaptivePageLayout` (`adaptive_page_layout.dart`) — Adaptive management page scaffold with title, desktop action bar, and responsive body container.
- `ResponsiveTableContainer` (`responsive_table_container.dart`) — Horizontal scroll wrapper for data tables and administrative operational grids.

### 3.3 Standard State Views (`lib/core/widgets/state_views/`)
- `LoadingView` (`loading_view.dart`) — Skeleton / progress indicator with optional status message.
- `EmptyStateView` (`empty_view.dart`) — Informative empty state with context explanation and action CTA.
- `ErrorStateView` (`error_view.dart`) — Human-readable error message with safe retry callback.
- `PermissionDeniedView` (`permission_denied_view.dart`) — 403 Forbidden state without leaking hidden records.
- `AccountSuspendedView` (`account_suspended_view.dart`) — Account suspended notice with direct support contact route.

---

## 4. Routing & Access Control Foundation (Task P0-05)

### 4.1 Access & Session Models (`lib/core/access/`)
- `UserRole` (`user_role.dart`) — Enum of all 12 platform roles with IDs, display names, route prefixes, icons, and `isWebPriority` classification identifying the 8 desktop/web-priority management roles.
- `SessionContext` (`session_context.dart`) — Immutable state model representing authentication status, active role, assigned roles, suspension status, and organization scope.
- `RolePreferenceStorage` (`role_preference_storage.dart`) — Abstract contract and `MockRolePreferenceStorage` implementation for remembering preferred roles across sessions.
- `SessionCubit` (`session_cubit.dart`) — State manager for multi-role sessions, role switching, and reactive GoRouter refresh notification.

### 4.2 Declarative Routing Engine (`lib/core/router/`)
- `AppRoutes` (`app_routes.dart`) — Centralized route path constants for all 12 platform roles, public endpoints, and auth flows.
- `RouteGuard` (`route_guards.dart`) — Modular guard interfaces (`AuthRouteGuard`, `SuspendedAccountGuard`, `ActiveRoleGuard`, `RoleAuthorizationGuard`, `AuthEntryRedirectGuard`) and `CompositeRouteGuard` pipeline.
- `createAppRouter()` (`app_router.dart`) — Central GoRouter factory wiring ShellRoute role shells, public endpoints, and 404 error builder.

### 4.3 Navigation Shell & Role Switching (`lib/core/widgets/navigation/`)
- `NavDestinationItem` (`nav_destination_item.dart`) — Item model for shell navigation destinations.
- `RoleNavConfig` (`role_nav_config.dart`) — Role-specific menu configurations for all 12 platform roles.
- `AppNavigationShell` (`app_navigation_shell.dart`) — Responsive layout shell adapting to Mobile (Bottom NavigationBar), Tablet (NavigationRail), and Desktop (Sidebar Drawer).
- `RoleSelectionView` (`role_selection_view.dart`) — Interactive screen allowing multi-role users to select or switch active roles with "Remember preferred role" persistence.
- `RoutePlaceholderView` (`route_placeholder_view.dart`) — Reusable routing verification container demonstrating nested paths without premature business logic.

---

## 5. Mock Infrastructure & Error Simulation Registry (Task P0-06)

### 5.1 Simulation Harness & Core Error Model
- `Result<T>` ([`lib/core/network/result.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/network/result.dart)) — Sealed result container for compile-safe domain outcomes (`Success<T>`, `FailureResult<T>`) per ADR-006.
- `AppException` ([`lib/core/errors/exceptions.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/errors/exceptions.dart)) — Typed exception hierarchy: `ServerException`, `NetworkException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ValidationException`, `CacheException`.
- `Failure` ([`lib/core/errors/failures.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/errors/failures.dart)) — Domain failures with `Failure.fromException(e)` mapper.
- `SimulatedErrorType` ([`lib/core/mock/simulated_error_type.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/mock/simulated_error_type.dart)) — Deterministic error simulation enum (`none`, `networkTimeout`, `serverError`, `unauthorized`, `forbidden`, `notFound`, `validationError`).
- `MockConfig` ([`lib/core/mock/mock_config.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/mock/mock_config.dart)) — Centralized developer control singleton for latency toggling, latency duration, and error simulation per ADR-011 and ADR-015.
- `MockNetworkHarness` ([`lib/core/mock/mock_network_harness.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/mock/mock_network_harness.dart)) — Mock request wrapper enforcing artificial latency and error simulation; strictly throws `UnsupportedError` in production builds.

### 5.2 Centralized Sample Data Catalog
- `MockData` ([`lib/core/mock/data/mock_data.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/mock/data/mock_data.dart)) — Fictional sample datasets covering:
  - 12 role profiles + multi-role and suspended users.
  - Organization memberships (Academy, Venue, Tournament Organizer).
  - Notifications list (read & unread variations).
  - Tournament records with live bracket fixtures and court scores.
  - Venue facilities, court lists, hourly rates, and slot availability matrix.
  - Booking records (confirmed, completed, cancelled, offline cash pending).
  - Marketplace products catalog and sample customer orders.
  - Empty dataset presets (`emptyNotifications`, `emptyTournaments`, etc.).

### 5.3 Exemplary Clean Architecture Slice (User Profile)
- Domain Entity: `UserProfile` ([`lib/shared/entities/user_profile.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/shared/entities/user_profile.dart))
- Domain Repository: `UserProfileRepository` ([`lib/features/identity/domain/repositories/user_profile_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/domain/repositories/user_profile_repository.dart))
- Data Source: `UserProfileDataSource` & `MockUserProfileDataSource` ([`lib/features/identity/data/datasources/`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/datasources/))
- Data Repository: `MockUserProfileRepository` & `RemoteUserProfileRepository` ([`lib/features/identity/data/repositories/`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/repositories/))

### 5.4 Common Async UI Presentation
- `AsyncStateView<T>` & `AsyncState<T>` ([`lib/core/widgets/async_state_view.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/widgets/async_state_view.dart)) — Standard async widget connecting Clean Architecture `Result<T>` and BLoC states with P0-04 state views (`LoadingView`, `EmptyStateView`, `ErrorStateView`, `PermissionDeniedView`, `AccountSuspendedView`).

### 5.5 Dependency Injection & Production Isolation
- `service_locator.dart` ([`lib/app/service_locator.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/app/service_locator.dart)) — Separates `initMockServiceLocator()` and `initRemoteServiceLocator()` guarded by `kUseMockRepositories`. Mocks (`MockRolePreferenceStorage`, `MockUserProfileDataSource`, `MockUserProfileRepository`, `MockConfig`, `MockNetworkHarness`) are strictly unreachable in release builds, where production `SharedPrefsRolePreferenceStorage` and remote repositories are registered.

---

## 6. Phase 1 — Identity & Shared Services Implementation

### 6.1 Phase 1.1.1 — Welcome / App Entry Screen
- `WelcomePage` ([`lib/features/identity/presentation/pages/welcome_page.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/welcome_page.dart)) — Responsive entry page featuring platform branding, feature value propositions, primary Login CTA, secondary Register CTA, and legal footer.
- `BrandLogoEmblem` ([`lib/features/identity/presentation/widgets/brand_logo_emblem.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/widgets/brand_logo_emblem.dart)) — Reusable court-green brand emblem with pickleball motif and semantic screen reader accessibility.
- Route: `AppRoutes.welcome` (`/auth/welcome`) wired in [`lib/core/router/app_router.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/router/app_router.dart).
- Backend Contract Handoff: [`docs/backend/UI_BACKEND_HANDOFF.md`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/docs/backend/UI_BACKEND_HANDOFF.md).

### 6.2 Phase 1.1.2 — Phone & Password Login Screen
- `LoginPage` ([`lib/features/identity/presentation/pages/login_page.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/login_page.dart)) — Responsive login screen with +91 Indian mobile number input, password obscurity toggle, inline validation, loading states, error banner, and responsive card/direct layouts.
- `LoginValidators` ([`lib/features/identity/presentation/validators/login_validators.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/validators/login_validators.dart)) — Pure unit-testable validation functions enforcing 10-digit Indian phone format (`^[6-9]\d{9}$`) and mandatory password.
- `LoginCubit` & `LoginState` ([`lib/features/identity/presentation/bloc/login_cubit.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/bloc/login_cubit.dart)) — State management coordinating `LoginInitial`, `LoginLoading`, `LoginSuccess`, and `LoginFailure` presentation states.
- Domain Entity: `AuthSession` ([`lib/features/identity/domain/entities/auth_session.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/domain/entities/auth_session.dart)) — Encapsulates authenticated identity, token placeholders, available roles, and active role context.
- Domain Repository: `AuthRepository` ([`lib/features/identity/domain/repositories/auth_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/domain/repositories/auth_repository.dart)).
- Data Models: `LoginRequestModel` ([`lib/features/identity/data/models/login_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/login_request_model.dart)) and `AuthResponseModel` ([`lib/features/identity/data/models/auth_response_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/auth_response_model.dart)).
- Data Repositories: `MockAuthRepository` ([`lib/features/identity/data/repositories/mock_auth_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/repositories/mock_auth_repository.dart)) and `RemoteAuthRepository` ([`lib/features/identity/data/repositories/remote_auth_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/repositories/remote_auth_repository.dart)).
- Route: `AppRoutes.login` (`/auth/login`) wired in [`lib/core/router/app_router.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/router/app_router.dart).
- Backend Contract Handoff: §2.2 in [`docs/backend/UI_BACKEND_HANDOFF.md`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/docs/backend/UI_BACKEND_HANDOFF.md).

### 6.3 Phase 1.1.3 — Player Self-Registration & OTP Verification
- `RegisterPage` ([`lib/features/identity/presentation/pages/register_page.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/register_page.dart)) — Multi-step registration view supporting Step 1 (Player registration form), Step 2 (6-digit OTP verification with 30s countdown and resend action), and Step 3 (Registration success with independent Player role badge and organizational role disclaimer).
- `RegistrationValidators` ([`lib/features/identity/presentation/validators/registration_validators.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/validators/registration_validators.dart)) — Pure unit-testable validation functions enforcing full name, Indian phone format (`^[6-9]\d{9}$`), alphanumeric password (min 8 chars), password confirmation match, and 6-digit OTP.
- `RegistrationCubit` & `RegistrationState` ([`lib/features/identity/presentation/bloc/registration_cubit.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/bloc/registration_cubit.dart)) — Multi-step state management coordinating form validation, OTP countdown timer lifecycle, resend dispatch, and success state.
- Domain Entities: `RegistrationInitiatedEntity` and `PlayerRegistrationSuccessEntity` ([`lib/features/identity/domain/entities/registration_entities.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/domain/entities/registration_entities.dart)).
- Domain Repository Methods: `AuthRepository.initiateRegistration`, `verifyOtp`, and `resendOtp` in [`lib/features/identity/domain/repositories/auth_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/domain/repositories/auth_repository.dart).
- Data Models: `RegisterRequestModel` ([`lib/features/identity/data/models/register_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/register_request_model.dart)), `VerifyOtpRequestModel` ([`lib/features/identity/data/models/verify_otp_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/verify_otp_request_model.dart)), `ResendOtpRequestModel` ([`lib/features/identity/data/models/resend_otp_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/resend_otp_request_model.dart)).
- Data Repositories: `MockAuthRepository` and `RemoteAuthRepository` updated with registration methods in [`lib/features/identity/data/repositories/`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/repositories/).
- Route: `AppRoutes.register` (`/auth/register`) wired in [`lib/core/router/app_router.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/router/app_router.dart).
- Backend Contract Handoff: §2.3 in [`docs/backend/UI_BACKEND_HANDOFF.md`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/docs/backend/UI_BACKEND_HANDOFF.md).

### 6.4 Phase 1.1.4 — Password Recovery / Forgot Password Flow
- `ForgotPasswordPage` ([`lib/features/identity/presentation/pages/forgot_password_page.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/pages/forgot_password_page.dart)) — Multi-step password recovery view supporting Step 1 (Mobile number input), Step 2 (6-digit OTP verification with visible 30s countdown and resend action), Step 3 (Set and confirm new password), and Step 4 (Password reset confirmation and proceed to Sign In).
- `ForgotPasswordValidators` ([`lib/features/identity/presentation/validators/forgot_password_validators.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/validators/forgot_password_validators.dart)) — Pure unit-testable validation functions enforcing 10-digit Indian phone format (`^[6-9]\d{9}$`), 6-digit OTP, alphanumeric password (min 8 chars), and password confirmation match.
- `ForgotPasswordCubit` & `ForgotPasswordState` ([`lib/features/identity/presentation/bloc/forgot_password_cubit.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/presentation/bloc/forgot_password_cubit.dart)) — Multi-step state management coordinating phone validation, OTP countdown lifecycle, resend session update, password commit, and success state.
- Domain Entities: `PasswordResetInitiatedEntity`, `PasswordResetVerifiedEntity`, `PasswordResetSuccessEntity` in [`lib/features/identity/domain/entities/password_reset_entities.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/domain/entities/password_reset_entities.dart).
- Domain Repository Methods: `AuthRepository.initiatePasswordReset`, `resendPasswordResetOtp`, `verifyPasswordResetOtp`, and `completePasswordReset` in [`lib/features/identity/domain/repositories/auth_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/domain/repositories/auth_repository.dart).
- Data Models: `ForgotPasswordRequestModel` ([`lib/features/identity/data/models/forgot_password_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/forgot_password_request_model.dart)), `ResendPasswordResetOtpRequestModel` ([`lib/features/identity/data/models/resend_password_reset_otp_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/resend_password_reset_otp_request_model.dart)), `VerifyPasswordResetOtpRequestModel` ([`lib/features/identity/data/models/verify_password_reset_otp_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/verify_password_reset_otp_request_model.dart)), `ResetPasswordRequestModel` ([`lib/features/identity/data/models/reset_password_request_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/models/reset_password_request_model.dart)).
- Data Repositories: `MockAuthRepository` and `RemoteAuthRepository` updated with password recovery implementations in [`lib/features/identity/data/repositories/`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/identity/data/repositories/).
- Route: `AppRoutes.forgotPassword` (`/auth/forgot-password`) wired in [`lib/core/router/app_router.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/router/app_router.dart).
- Backend Contract Handoff: §2.4 in [`docs/backend/UI_BACKEND_HANDOFF.md`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/docs/backend/UI_BACKEND_HANDOFF.md).

### 6.5 Phase 1.1.5 — Multi-Role Selection & Dashboard Routing (UI Finalized & State Preserved)
- `RoleSelectionPage` ([`lib/features/role_selection/presentation/pages/role_selection_page.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/presentation/pages/role_selection_page.dart)) — Responsive multi-role selection screen supporting all 12 platform roles, organization badges (`AppChip.neutral`), tournament badges (`AppChip.info`), active operating context summary banner, radio-button deliberate selection, 1-tap card entry, "Remember my choice" persistence switch, "Continue to Dashboard" confirmation CTA, and zero-role empty state (`RoleSelectionEmpty`). Passes complete selected assignment context to `SessionCubit` before dashboard navigation.
- `SessionContext` & `SessionCubit` ([`lib/core/access/`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/access/)) — Complete selected role context state preservation (`activeRoleAssignmentId`, `activeOrganizationId`, `activeOrganizationName`, `activeTournamentId`, and `activeTournamentName`) via `setActiveRoleProfile(profile)`, supporting automatic clearing of tournament context when switching to non-tournament roles and organization context switching.
- `RoleDashboardRouter` ([`lib/core/router/role_dashboard_router.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/router/role_dashboard_router.dart)) — Centralized routing authority mapping all 12 platform roles to canonical dashboard routes (`/player/dashboard`, `/coach/dashboard`, `/academy/dashboard`, `/academy-staff/dashboard`, `/venue-partner/dashboard`, `/venue-staff/dashboard`, `/tournament-organizer/dashboard`, `/tournament-staff/dashboard`, `/referee/dashboard`, `/marketplace-seller/dashboard`, `/application-staff/dashboard`, `/application-admin/dashboard`).
- `RoleSelectionCubit` & `RoleSelectionState` ([`lib/features/role_selection/presentation/cubit/role_selection_cubit.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/presentation/cubit/role_selection_cubit.dart)) — State management coordinating role resolution, single-role auto-continue, remembered assignment validation, revoked-role fallback, and selection confirmation with organization context propagation.
- Domain Entities: `RoleContext` and `RoleProfile` (with `roleAssignmentId`, `organizationName`, and `tournamentName`) in [`lib/features/role_selection/domain/entities/role_context.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/domain/entities/role_context.dart).
- Domain Repository: `RoleContextRepository` in [`lib/features/role_selection/domain/repositories/role_context_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/domain/repositories/role_context_repository.dart).
- Data Models: `RoleProfileModel` and `RoleContextModel` in [`lib/features/role_selection/data/models/role_context_model.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/data/models/role_context_model.dart).
- Data Repositories: `MockRoleContextRepository` ([`lib/features/role_selection/data/repositories/mock_role_context_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/data/repositories/mock_role_context_repository.dart)) with realistic mock datasets covering all 12 roles, multi-venue staff, multi-tournament staff, multi-tournament organizers, multi-academy coaches, and zero-role empty state, and `RemoteRoleContextRepository` ([`lib/features/role_selection/data/repositories/remote_role_context_repository.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/features/role_selection/data/repositories/remote_role_context_repository.dart)).
- Enhanced Placeholder: `RoutePlaceholderView` ([`lib/core/widgets/navigation/route_placeholder_view.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/widgets/navigation/route_placeholder_view.dart)) with active role badge, organization context, "Switch Role" action, and "Sign Out Session" action.
- Route: `AppRoutes.roleSelection` (`/role-selection`) wired in [`lib/core/router/app_router.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/router/app_router.dart).
- Backend Contract Handoff: §2.5 in [`docs/backend/UI_BACKEND_HANDOFF.md`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/docs/backend/UI_BACKEND_HANDOFF.md).






