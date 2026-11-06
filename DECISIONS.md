# ARCHITECTURAL DECISIONS RECORD (ADR)

**Project:** Pickleball Multi-Role Platform (Frontend)  
**Baseline:** Frontend FSD v1.0  

---

### ADR-001: Single Flutter Codebase for All 12 Roles
- **Context:** The platform serves 12 distinct roles (Player, Coach, Academy, Academy Staff, Venue Partner, Venue Staff, Tournament Organizer, Tournament Staff, Referee, Marketplace Seller, Application Staff, Application Admin). Users can possess multiple roles simultaneously under a single identity.
- **Decision:** Build a single responsive Flutter codebase rather than 12 independent apps. Navigation, shell, and capabilities are dynamically scoped to the currently selected `ActiveRoleContext`.
- **Status:** Approved (FSD Section 1).

---

### ADR-002: Feature-First Clean Architecture
- **Context:** Large monolithic codebases become unmaintainable when cross-feature code leaks into presentation widgets.
- **Decision:** Adopt feature-first packaging (`lib/features/<feature>/presentation|domain|data`). The domain layer contains pure Dart entities and abstract repository interfaces without dependencies on Flutter widgets or third-party network libraries.
- **Status:** Approved (FSD Section 2).

---

### ADR-003: State Management via BLoC and Cubit
- **Context:** Multiple state management patterns (Riverpod, Provider, GetX, MobX) within the same codebase cause cognitive overhead and fragmentation.
- **Decision:** Enforce `flutter_bloc` exclusively across the entire application. Use `Cubit` for single-screen CRUD, form validation, and simple toggles. Use `Bloc` for multi-step workflows, session management, and live match scoring.
- **Status:** Approved (FSD Section 2.2).

---

### ADR-004: Declarative Routing with GoRouter & Role Guarding
- **Context:** Dynamic role switching, deep links, public unauthenticated screens (live tournament brackets), and guarded screens require declarative handling.
- **Decision:** Use `GoRouter` with a centralized redirect engine listening to `AuthBloc` and `RoleContextCubit`. Unauthorized accesses redirect to fallback screens without exposing protected data.
- **Status:** Approved (FSD Section 3.1).

---

### ADR-005: Mock-First Repository Pattern (Phase 0–7)
- **Context:** Frontend implementation must not be blocked by backend readiness. Hardcoding mock data inside UI widgets creates technical debt.
- **Decision:** Abstract all data access behind repository interfaces. Provide `MockXRepository` implementations with realistic network delays and error toggles. Swapping to `ApiXRepository` in Phase 8 will require zero widget-level changes.
- **Status:** Approved (FSD Section 1 & Section 4).

---

### ADR-006: Sealed Class Result Type for Explicit Error Handling
- **Context:** Exceptions leaking into widgets crash the UI and bypass typed error handling. Passing raw `Map<String, dynamic>` degrades type safety.
- **Decision:** Use an idiomatic Dart 3 sealed class `Result<T>` with `Success<T>` and `FailureResult<T>` variants rather than heavy external functional libraries.
- **Status:** Approved.

---

### ADR-007: V1 Scope Boundaries & Exclusions
- **Context:** PRDs and FSD establish firm scope exclusions for V1.
- **Decision:**
  1. No Razorpay online checkout or online payment processing for venue bookings in V1 (manual/offline payment status recording only).
  2. No automated platform refund execution in V1 (no refund UI).
  3. No live marketplace product listing prior to administrative approval.
  4. Exactly one Application Admin account; no UI or API flow to create another Application Admin.
- **Status:** Approved (FSD Section 4, 5, 10).

---

### ADR-008: Dependency Minimization (Zero Code-Generation for Models)
- **Context:** Large code-generation workflows (`freezed`, `json_serializable`, `build_runner`) slow down compilation, introduce massive boilerplate files into version control, and increase context token cost during AI-assisted development.
- **Decision:** Utilize native Dart 3 features (`sealed class`, pattern matching, record types) along with lightweight `equatable` for BLoC states/events and concise manual `fromJson`/`toJson` factory methods on DTOs.
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-009: Token Storage & Session Persistence Strategy
- **Context:** Auth JWT access/refresh tokens and active role context must persist across app restarts and be securely stored.
- **Decision:** Use `flutter_secure_storage` for sensitive credentials (access token, refresh token) and `shared_preferences` for non-sensitive local preferences (remembered active role ID, locale, theme mode).
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-010: Responsive Screen Strategy (Mobile-First with Breakpoint Tokens)
- **Context:** Mobile, tablet, and web desktop layouts must be supported with mobile-first default behavior.
- **Decision:** Avoid heavy third-party UI framework dependencies. Use an internal `ResponsiveLayout` widget backed by centralized breakpoint constants (`Breakpoint.mobile = <600`, `Breakpoint.tablet = 600..1024`, `Breakpoint.desktop = >1024`) and `LayoutBuilder`.
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-011: Unified Repository Mocking & Network Simulation Harness
- **Context:** Features must be testable without live APIs while still simulating real-world network conditions (latency, empty states, network timeouts, 403 Forbidden).
- **Decision:** Implement an internal `MockNetworkHarness` utility that wraps all `Mock*Repository` methods with configurable delay (default: 400ms) and controllable error triggers for QA/demo modes.
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-012: Safe Concurrent Token Refresh via QueuedInterceptor
- **Context:** When multiple concurrent HTTP requests fail with `401 Unauthorized`, naive implementations can trigger multiple refresh calls or infinite loops.
- **Decision:** Utilize Dio's `QueuedInterceptor` to lock incoming requests, invoke token refresh through an isolated Dio client (omitting interceptors), and replay failed requests with new credentials upon success, or trigger immediate session teardown upon failure.
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-013: Multi-Layer Cache & Context Isolation (Bloc, Requests, Persisted Data)
- **Context:** When switching between roles or organizations, in-memory caches, in-flight requests, active bloc states, and persisted org data must not leak across administrative boundaries.
- **Decision:** 
  1. Abort pending in-flight requests via `CancelTokenRegistry`.
  2. Clear in-memory repository caches via `CacheRegistry.clearAllCaches()`.
  3. Close or reset scoped Bloc/Cubit state containers.
  4. Purge persisted organization-scoped local storage keys (`org_${orgId}_*`).
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-014: Sensitive Data Logging Redaction & Release Silence
- **Context:** Logging tokens, personal documents (Aadhaar, PAN), or financial data violates privacy standards and FSD §10.
- **Decision:** Implement `LogSanitizer` in the HTTP logging pipeline to mask sensitive fields with `***REDACTED***`. Disable all console logging in release mode (`kReleaseMode == true`).
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-015: Production Mock Isolation (DI Bindings & Build Verification)
- **Context:** Mock data sources or failure simulation harnesses must never be enabled or accessible in production builds. kReleaseMode alone must not be assumed without build-level verification.
- **Decision:**
  1. Enforce compile-time guarding with `const bool kUseMockRepositories = !kReleaseMode && bool.fromEnvironment('USE_MOCKS')`.
  2. Strictly separate DI composition roots so release builds register only `Api*Repository`.
  3. Verify mock isolation through automated CI release-build tests and container inspection.
- **Status:** Approved (User Sign-Off on Proposal v1.2.0).

---

### ADR-016: Responsive Navigation Shell & Pure Route Guards Architecture
- **Context:** Supporting 12 platform roles across mobile, tablet, and desktop requires a scalable navigation structure without duplicating shell logic or hardcoding route strings.
- **Decision:**
  1. Centralize route paths in `AppRoutes` and destination definitions in `RoleNavConfig`.
  2. Implement `AppNavigationShell` adapting responsively: Mobile (<600dp) uses `NavigationBar`, Tablet (600–1024dp) uses `NavigationRail`, Desktop (>1024dp) uses permanent sidebar drawer.
  3. Decouple guard evaluation (`CompositeRouteGuard`) from Flutter UI widgets to guarantee unit testability without widget dependencies.
  4. Provide reactive GoRouter synchronization via `SessionCubit.refreshListenable`.
- **Status:** Implemented (Task P0-05, awaiting user approval).





