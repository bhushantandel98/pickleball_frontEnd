# PROJECT RULES & ARCHITECTURAL GUIDELINES

**Document ID:** PR-001  
**Project:** Pickleball Multi-Role Platform (Frontend)  
**Version:** 1.0.0  
**Effective Date:** 02 November 2026  
**Source Baseline:** Frontend FSD v1.0, Master PRD v1.0, 12 Role PRDs  

---

## 1. Architectural Principles

1. **Single Application, Multi-Role Architecture:**  
   One Flutter codebase serving all 12 platform roles. A single authenticated identity may hold multiple roles. Role switching alters UI context, routes, and active organization scoping without requiring re-authentication.

2. **Clean Architecture with Feature-First Modular Organization:**  
   Code is partitioned by feature/domain boundary first, then layered internally into:
   - **Presentation Layer:** Widgets, Screens/Pages, Bloc/Cubit, UI State, and Form Controllers.
   - **Domain Layer:** Pure Dart entities, value objects, failure classes, and abstract repository contracts. Orchestration usecases are created only when multi-step domain coordination is required. Direct CRUD operations delegate directly from Bloc/Cubit to repository interfaces to prevent unnecessary boilerplate.
   - **Data Layer:** DTOs, JSON mappers, Data Sources (`RemoteDataSource`, `MockDataSource`), and concrete Repository implementations.
   - **Core Layer:** Cross-cutting concerns (Network client, Auth & Token session, Route guards, Active Role context, Design tokens, Base failure types, Utility extensions).

3. **Backend Authoritative Security:**  
   Client-side route guards and UI visibility toggles exist solely for user experience. Backend authorization is the sole source of security. Any `401 Unauthorized` or `403 Forbidden` response must be gracefully handled without leaking sensitive records.

4. **Mock-First Development with Release Isolation:**  
   All features must first implement and verify against `Mock<Feature>Repository` with simulated network latency and deterministic error toggles. Mock repositories and simulation harnesses are strictly guarded with `!kReleaseMode && bool.fromEnvironment('USE_MOCKS')` so that no mock fixtures or simulation controls exist in production builds.

5. **Lean Dependencies:**  
   Keep dependencies minimal and verified against Flutter 3.47.6 / Dart 3.13.5. Zero code-generation for models (`freezed`/`build_runner` omitted). Utilize modern Dart 3 sealed classes, records, and `equatable`.

---

## 2. Directory & Package Conventions

```
lib/
├── app/                        # Application bootstrap, DI, global observers, top-level widget
├── core/                       # Shared platform infrastructure
│   ├── access/                 # Role context, permission evaluators, capability checks
│   ├── auth/                   # Session state, token storage, auth interceptor
│   ├── constants/              # App-wide constants, regex, storage keys
│   ├── design_system/          # Theme, colors, typography, spacing, elevations
│   ├── errors/                 # Typed failures, exceptions, error mapper
│   ├── network/                # ApiClient, interceptors, connectivity, pagination params
│   ├── router/                 # GoRouter configuration, route names, path constants, guards
│   ├── utils/                  # Formatters (currency, dates), validators, device helpers
│   └── widgets/                # Core atomic widgets (buttons, fields, dialogs, state views)
├── shared/                     # Cross-feature domain entities and shared widgets
│   ├── entities/               # UserProfile, Address, Money, GeoLocation, RoleType
│   └── widgets/                # App bar, navigation shells, drawer, empty/error/loading views
├── features/                   # Feature modules (12 roles + identity + common services)
│   ├── identity/               # Login, register, forgot password, account status
│   ├── role_selection/         # Active role picker, role switcher, remembered role
│   ├── notifications/          # In-app notification center, preferences
│   ├── player/                 # Player dashboard, discovery, bookings, tournaments, orders
│   ├── coach/                  # Coach profile, sessions, batches, attendance, assessments
│   ├── academy/                # Academy branches, programs, batches, coaches, fees
│   ├── academy_staff/          # Delegated staff dashboard and permitted operations
│   ├── venue_partner/          # Venues, courts, slots, pricing, booking calendar, manual payments
│   ├── venue_staff/            # Check-in, daily tasks, purchase receipts, maintenance
│   ├── tournament_organizer/   # Tournaments, events, draws, referee assignments, scores
│   ├── tournament_staff/       # Delegated tournament operations, court monitoring
│   ├── referee/                # Assigned matches, live match scoring UI, result submission
│   ├── marketplace_seller/     # Seller onboarding, product drafts, catalog, orders, settlements
│   ├── application_staff/      # Verification queues, seller/product review, recommendations
│   └── application_admin/      # Global admin dashboard, user/org audit, policies, staff config
├── l10n/                       # Localization & string resources
└── main.dart                   # Application entry point
```

---

## 3. State Management Standards (Bloc & Cubit)

1. **Cubit vs. Bloc Usage:**
   - **Cubit:** Use for straightforward state holding, single-screen CRUD, toggle states, tabs, and form validation.
   - **Bloc:** Use for complex, multi-event workflows (e.g., live match scoring, multi-step tournament draw setup, payment status resolution, role switching with session cleanup).

2. **Immutable States & Sealed Classes:**
   - Use Dart 3 `sealed class` for UI states:
     ```dart
     sealed class ScreenState<T> {
       const ScreenState();
     }
     class ScreenInitial<T> extends ScreenState<T> { const ScreenInitial(); }
     class ScreenLoading<T> extends ScreenState<T> { const ScreenLoading(); }
     class ScreenSuccess<T> extends ScreenState<T> {
       final T data;
       const ScreenSuccess(this.data);
     }
     class ScreenEmpty<T> extends ScreenState<T> {
       final String message;
       const ScreenEmpty(this.message);
     }
     class ScreenError<T> extends ScreenState<T> {
       final Failure failure;
       const ScreenError(this.failure);
     }
     ```

3. **No Business Rules in Widgets:**  
   `build()` methods must only evaluate state and emit events or call cubit methods. Never invoke repositories, APIs, or role authorization logic directly inside widgets.

---

## 4. Navigation & Route Guards

1. **Declarative Routing:**  
   All routing is managed via `GoRouter`. Route paths and route names must be declared as static constants in `AppRoutes`.

2. **Route Guarding Flow:**
   - **Unauthenticated:** Redirect to `/auth/welcome` or `/auth/login`.
   - **Authenticated without Active Role:** Redirect to `/role-selection`.
   - **Suspended Account:** Redirect to `/account-suspended` (showing support contact details).
   - **Role Mismatch:** If a route belongs to `/venue-partner/*` and the user's active role is `Player`, redirect to the user's active role dashboard or 403 screen.

3. **Public Route Access:**  
   Public tournament details and live brackets (`/public/tournaments/:id`) must be accessible without requiring user authentication.

---

## 5. Coding & Naming Conventions

1. **File Names:** Lowercase with underscores (`snake_case.dart`).
   - Pages: `<feature>_<entity>_page.dart` (e.g., `tournament_draw_page.dart`)
   - Blocs: `<entity>_bloc.dart`, `<entity>_event.dart`, `<entity>_state.dart`
   - Repositories: `<entity>_repository.dart` (interface), `mock_<entity>_repository.dart`, `api_<entity>_repository.dart`
   - DTOs / Models: `<entity>_dto.dart`

2. **Class Names:** UpperCamelCase (`PascalCase`).
   - Blocs: `TournamentDrawBloc`
   - Repositories: `TournamentRepository` (interface), `MockTournamentRepository`
   - Entities: `Tournament`, `MatchFixture`

3. **Formatting & Lints:**  
   Enforce standard `flutter_lints` with zero warnings allowed before any task completion. Line length guideline: 100 characters.

---

## 6. Token-Efficient AI Protocol

1. **Context Boundary:** Do not inject entire PRDs into prompts. Reference specific requirement IDs and sections from `Pickleball Frontend FSD v1.0`.
2. **Minimal Diffs:** Modify only bounded files required for the active vertical slice. Never refactor unrelated shared components without an explicit architectural decision.
3. **Artifact Sync:** Update `BUILD_STATUS.md` and `MODULE_INDEX.md` after every completed vertical slice.

---

## 7. Security, Token Refresh & Session Lifecycle

1. **Safe Concurrent Token Refresh:**  
   Network authentication uses Dio's `QueuedInterceptor`. When a request triggers `401 Unauthorized`, all concurrent requests are queued. The token refresh request executes via an isolated Dio client (without interceptors) to prevent recursive loops.
2. **Session Teardown on Refresh Failure:**  
   If token refresh returns `401`, `403`, or fails, `SessionManager.clearSession()` erases all tokens, purges all in-memory caches, notifies `AuthBloc`, and navigates to `/auth/login` with an informative session-expired message.

---

## 8. Multi-Layer Cache & Context Isolation (Zero Cross-Tenant Leakage)

1. **In-Flight Request Abort:** When switching roles or organizations, `CancelTokenRegistry` cancels all active Dio `CancelToken` instances so pending requests cannot resolve into the new context.
2. **ClearableCache Interface:** Every repository or datasource holding in-memory lists or cached entities must implement `ClearableCache` and register with `CacheRegistry`.
3. **Bloc/Cubit State Reset:** Scoped Blocs/Cubits attached to the previous role context are closed or reset to `ScreenInitial` before the new role dashboard mounts.
4. **Persisted Organization-Scoped Data Purge:** Any cached local storage keys in `shared_preferences` scoped to an organization (`org_${orgId}_*`) are wiped via `ScopedStorageCleaner`.


---

## 9. Strict Logging & Data Redaction Rules

1. **Zero Sensitive Payload Logging:**  
   Never log bearer tokens, refresh tokens, passwords, OTPs, government IDs (Aadhaar, PAN), or financial data (bank accounts, UPI, card details).
2. **Log Sanitization:**  
   All HTTP request/response logging must pass through `LogSanitizer` to replace sensitive keys with `***REDACTED***`.
3. **Release Mode Silence:**  
   Console and HTTP logging are disabled completely in release builds (`kReleaseMode == true`).

---

## 10. Design System & Component Usage Rules

1. **Zero Hardcoded Colors & Dimensions:**
   - Always reference `Theme.of(context).colorScheme` or `AppColors` for semantic tokens. Never use literal `Color(0x...)` in feature screens.
   - Always reference `AppSpacing` (`AppSpacing.xs`, `AppSpacing.md`, `AppSpacing.screenPadding`) for margins, insets, and gaps.
   - Always reference `Theme.of(context).textTheme` for typography hierarchy.

2. **Standard State Handling in UI Views:**
   - Every feature page handling asynchronous state must render the standard state view components:
     - Loading: `LoadingView(message: '...')`
     - Empty: `EmptyStateView(title: '...', message: '...', actionLabel: '...', onAction: ...)`
     - Error: `ErrorStateView(message: failure.message, onRetry: ...)`
     - Restricted / Forbidden: `PermissionDeniedView()`
     - Suspended Account: `AccountSuspendedView(onContactSupport: ...)`

3. **Developer Usage Examples:**

```dart
// Example 1: Rendering Form Controls with Responsive Layout
ResponsiveLayout(
  mobile: (context) => Column(
    children: [
      AppTextField(
        label: 'Full Name',
        hint: 'Enter player name',
        onChanged: (val) => ...,
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton.primary(
        label: 'Register Player',
        onPressed: () => ...,
      ),
    ],
  ),
  tablet: (context) => Row(
    children: [
      Expanded(child: AppTextField(label: 'Full Name')),
      const SizedBox(width: AppSpacing.md),
      AppButton.primary(label: 'Register Player', onPressed: () => ...),
    ],
  ),
);

// Example 2: Destructive Confirmation Dialog
final confirmed = await AppConfirmationDialog.show(
  context: context,
  title: 'Cancel Booking',
  message: 'Are you sure you want to cancel this booking? This action cannot be undone.',
  confirmLabel: 'Cancel Booking',
  isDestructive: true,
);
if (confirmed == true) {
  // Execute cancellation workflow
}
```

---

## 11. Routing, Navigation & Access Control Rules (Task P0-05)

1. **Route Path Centralization:**
   - **Never** hardcode raw route strings (`/player/bookings`, `/auth/welcome`) in presentation widgets or Blocs.
   - Always reference centralized constants in [`AppRoutes`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/router/app_routes.dart).

2. **Authoritative Backend Security:**
   - Client-side route guards (`RouteGuard`, `CompositeRouteGuard`) exist purely for user experience, graceful fallback, and navigation flow.
   - **Never** rely on frontend guards or UI visibility toggles for data security. Backend API authorization is the sole authority.

3. **Multi-Role Switching Protocol:**
   - Switching between active roles must always execute via [`SessionCubit.switchRole(UserRole newRole)`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/access/session_cubit.dart).
   - Switching roles updates `activeRole`, invalidates role-scoped UI state, and navigates to the role's default dashboard path.
   - Users cannot switch to a role they do not possess in `session.availableRoles`.

4. **Pure & Testable Route Guards:**
   - Route guards must remain completely decoupled from Flutter widgets. They evaluate `SessionContext` against `String location` and return a redirect path `String?`.

5. **Responsive Navigation Shell Standard:**
   - All role-scoped routes execute within [`AppNavigationShell`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/widgets/navigation/app_navigation_shell.dart):
     - Mobile (`< 600dp`): Material 3 bottom `NavigationBar`.
     - Tablet (`600–1024dp`): Material 3 `NavigationRail`.
     - Desktop (`> 1024dp`): Permanent side navigation drawer / sidebar.

---

## 12. Responsive Web & Desktop-Priority Roles (Platform-Wide UI Requirement)

1. **Web-Priority Operational Roles (Full Desktop/Web Experience):**
   The following eight roles must have intentionally designed, full desktop/web-friendly experiences with tailored multi-column productivity workflows, in addition to mobile responsiveness:
   1. **Academy** (`/academy`)
   2. **Academy Staff** (`/academy-staff`)
   3. **Tournament Organizer** (`/tournament-organizer`)
   4. **Tournament Staff** (`/tournament-staff`)
   5. **Venue Partner** (`/venue-partner`)
   6. **Venue Staff** (`/venue-staff`)
   7. **Application Admin** (`/application-admin`)
   8. **Application Staff** (`/application-staff`)

2. **Mobile-First Roles with Responsive Compatibility:**
   - **Player** (`/player`), **Coach** (`/coach`), **Referee** (`/referee`), and **Marketplace Seller** (`/marketplace-seller`) remain mobile-first initially.
   - However, they **must** retain responsive compatibility on tablet and desktop without stretched layouts or visual clipping.

3. **Desktop Productivity UI Standards for Web-Priority Roles:**
   - **Navigation & Layout:** Permanent desktop sidebar navigation (`AppNavigationShell`) with top application bar displaying active context, organization badge, and role switcher.
   - **Content Max Widths:** Content must be constrained using [`ResponsiveContainer`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/design_system/responsive_layout.dart) (`AppSpacing.maxContentWidth` = 1200dp, `maxTableWidth` = 1440dp) to prevent unreadable stretching on ultra-wide monitors.
   - **Multi-Column Forms:** Long forms must utilize [`ResponsiveRowColumn`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/design_system/responsive_layout.dart) or multi-column grids on desktop (`isDesktop`), collapsing to single columns on mobile.
   - **Data Presentation:** Tables and administrative lists must support desktop layouts with inline search, multi-select filters, column sorting, and pagination.
   - **Operational Management:** Schedules, court calendars, tournament brackets, and verification queues must leverage the wider desktop viewport for high-density information display.

4. **Single Codebase Mandate:**
   - All 12 roles reside in the single Flutter codebase.
   - Do **not** duplicate feature implementations for web and mobile; use adaptive layout builders (`ResponsiveLayout`, `ResponsiveContainer`, `ResponsiveRowColumn`, and `context.responsive()`).

---

## 13. Mock Infrastructure, Error Simulation & Production DI Isolation Rules (Task P0-06)

1. **Clean Architecture Mock Pattern:**
   - **Domain Layer:** Exposes pure abstract repository contracts (`lib/features/<module>/domain/repositories/<name>_repository.dart`) returning compile-safe [`Result<T>`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/network/result.dart).
   - **Data Layer:** Exposes abstract data sources (`<name>_data_source.dart`), mock implementations (`mock_<name>_data_source.dart`), and mock repositories (`mock_<name>_repository.dart`).
   - Mock repositories catch data-source exceptions and cleanly convert them to domain [`Failure`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/errors/failures.dart) instances wrapped in `FailureResult<T>`.

2. **Centralized Mock Catalog (`MockData`):**
   - All sample datasets must be declared centrally in [`lib/core/mock/data/mock_data.dart`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/mock/data/mock_data.dart).
   - **Never** hardcode mock objects, arrays, or JSON fixtures inside UI widgets or Blocs.
   - Always supply empty state presets (`MockData.empty*`) alongside populated datasets to enable UI state testing.

3. **Developer Network & Error Simulation Controls (`MockConfig`):**
   - **Latency Toggle:** Enable or disable fake API delay via `MockConfig.instance.setLatencyEnabled(bool)` and configure duration via `MockConfig.instance.setLatencyDuration(Duration)`.
   - **Error Simulation:** Trigger deterministic HTTP error states via `MockConfig.instance.simulateError(SimulatedErrorType.<type>)`:
     - `networkTimeout` — Socket/offline connection drop
     - `serverError` — HTTP 500 internal server error
     - `unauthorized` — HTTP 401 expired/missing credentials
     - `forbidden` — HTTP 403 permission boundary violation
     - `notFound` — HTTP 404 missing resource
     - `validationError` — HTTP 422 payload validation rejection
   - **Restore Normal Operations:** Reset simulation via `MockConfig.instance.clearSimulatedError()` or `MockConfig.instance.reset()`.

4. **Strict ADR-015 Production Isolation:**
   - Mock registrations are partitioned into `initMockServiceLocator()`, while remote API registrations are partitioned into `initRemoteServiceLocator()`.
   - Gated by `const bool kUseMockRepositories = !kReleaseMode && bool.fromEnvironment('USE_MOCKS', defaultValue: true);`.
   - In release builds (`kReleaseMode == true`), `initMockServiceLocator()` and `MockNetworkHarness` unconditionally throw `UnsupportedError` and mock dependencies are dead-code eliminated from compiled binaries.

5. **How to Create a New Mock Repository for Future Modules:**
   ```dart
   // Step 1: Define repository interface in domain layer
   abstract interface class TournamentRepository {
     Future<Result<Tournament>> getTournament(String id);
   }

   // Step 2: Define datasource interface in data layer
   abstract interface class TournamentDataSource {
     Future<Tournament> getTournament(String id);
   }

   // Step 3: Implement mock datasource using MockNetworkHarness & MockData
   class MockTournamentDataSource implements TournamentDataSource {
     final MockNetworkHarness harness;
     MockTournamentDataSource({MockNetworkHarness? harness})
         : harness = harness ?? MockNetworkHarness();

     @override
     Future<Tournament> getTournament(String id) {
       return harness.request(() async {
         // Lookup in MockData or throw NotFoundException
         return tournament;
       });
     }
   }

   // Step 4: Implement mock repository in data layer returning Result<T>
   class MockTournamentRepository implements TournamentRepository {
     final TournamentDataSource dataSource;
     const MockTournamentRepository({required this.dataSource});

     @override
     Future<Result<Tournament>> getTournament(String id) async {
       try {
         final data = await dataSource.getTournament(id);
         return Success(data);
       } on AppException catch (e) {
         return FailureResult(Failure.fromException(e));
       }
     }
   }

   // Step 5: Register in initMockServiceLocator() in lib/app/service_locator.dart
   sl.registerLazySingleton<TournamentRepository>(
     () => MockTournamentRepository(dataSource: sl<TournamentDataSource>()),
   );
   ```

6. **How to Replace a Mock Repository with a Real API Repository:**
   1. Implement `ApiTournamentDataSource` connecting to backend endpoints via Dio `ApiClient`.
   2. Implement `ApiTournamentRepository` wrapping `ApiTournamentDataSource`.
   3. In `lib/app/service_locator.dart`, register `ApiTournamentRepository` inside `initRemoteServiceLocator()`.
   4. The presentation layer (screens, Blocs) remains completely unchanged because it depends solely on `sl<TournamentRepository>()`.

7. **Standard Async State Presentation via `AsyncStateView`:**
   All async screen states must be rendered using [`AsyncStateView<T>`](file:///c:/Users/bhushan_tandel/Flutter%20Idealake/PickleBall/lib/core/widgets/async_state_view.dart) which directly integrates with existing P0-04 state views:
   ```dart
   AsyncStateView<UserProfile>(
     state: AsyncState.fromResult(result, onRetry: () => fetchProfile()),
     builder: (context, profile) => ProfileDetailsCard(profile: profile),
   );
   ```

---

## 10. Testing Strategy — Token and Time Efficient

During UI development and feature implementation, adhere strictly to the following testing and execution principles:

1. **Targeted Execution:** Do not run the complete project test suite after every feature or small code change. Execute only targeted tests directly relevant to the files and functionality modified (e.g., `flutter test test/features/<feature>/<feature>_test.dart`).
2. **Lean Test Creation:** Avoid creating excessive or redundant test cases for simple, declarative UI components. Focus testing bandwidth on critical paths.
3. **Prioritized Test Coverage:** Prioritize tests for:
   - Important user interactions (taps, inputs, selections, toggles).
   - Route transitions, URL parameters, and navigation delegation.
   - Form validation, error messaging, and edge cases.
   - State management state machine transitions and lifecycle cleanup.
4. **Coverage Reuse:** Reuse and extend existing test files, fixtures, and harnesses wherever possible instead of spawning duplicate suites.
5. **Preserve Meaningful Coverage:** Never delete or disable existing meaningful tests merely to reduce local execution duration.
6. **Milestone Static Analysis:** Run `flutter analyze` only when relevant (e.g. after structural changes) or at a feature milestone, rather than on every trivial file tweak.
7. **Full Suite Gating:** Run the complete project test suite (`flutter test`) once as a comprehensive gate during the final pre-Git-push verification.
8. **Truthful & Precise Reporting:** Always report explicitly which specific tests were executed and their actual command output. Never claim or imply that the full test suite passed if only targeted tests were executed.

---

## 11. Git Workflow & Automated Push Rule

1. **Automatic Git Commit & Push:**
   - Once changes for a feature, bugfix, or modification are completed and verified (targeted tests pass and static analysis is clean), automatically stage all relevant changes (`git add .`).
   - Create a commit with a concise, descriptive commit message adhering to conventional commit formatting (e.g. `feat: ...`, `fix: ...`, `docs: ...`).
   - Automatically push the commit to the `dev` branch (`git push origin dev`).
2. **Default Behavior:**
   - Always follow this automated commit-and-push workflow unless the user explicitly instructs otherwise (e.g., "do not commit", "do not push", or "keep changes local").


