import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/mock/mock_config.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/features/identity/data/datasources/mock_user_profile_data_source.dart';
import 'package:pickleball_platform/features/identity/data/datasources/user_profile_data_source.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_auth_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/remote_auth_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/remote_user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/forgot_password_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/login_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/registration_cubit.dart';
import 'package:pickleball_platform/features/role_selection/data/repositories/mock_role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/data/repositories/remote_role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/domain/repositories/role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/presentation/cubit/role_selection_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Compile-time & runtime flag for mock repository registration (ADR-015).
/// In release mode, this evaluates to `false` and mock bindings are dead-code eliminated.
const bool kUseMockRepositories =
    !kReleaseMode && bool.fromEnvironment('USE_MOCKS', defaultValue: true);

/// Initialize foundational dependencies and feature service locators.
Future<void> initServiceLocator() async {
  // --- ADR-015: Strict Production Mock Isolation ---
  // Registers storage, data sources, and repositories into GetIt
  if (kUseMockRepositories) {
    initMockServiceLocator();
  } else {
    initRemoteServiceLocator();
  }

  // --- Core Session Singleton (depends on registered RolePreferenceStorage) ---
  sl.registerLazySingleton<SessionCubit>(
    () => SessionCubit(preferenceStorage: sl<RolePreferenceStorage>()),
  );

  // --- Identity & Auth Cubits ---
  sl.registerFactory<LoginCubit>(
    () => LoginCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<RegistrationCubit>(
    () => RegistrationCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(authRepository: sl<AuthRepository>()),
  );

  // --- Role Selection Cubit ---
  sl.registerFactory<RoleSelectionCubit>(
    () => RoleSelectionCubit(
      repository: sl<RoleContextRepository>(),
      preferenceStorage: sl<RolePreferenceStorage>(),
    ),
  );
}

/// Registers mock dependencies, data sources, and repositories for development/testing.
///
/// Strictly guarded against invocation in release mode (ADR-015).
void initMockServiceLocator() {
  assert(!kReleaseMode, 'initMockServiceLocator must NEVER be called in release builds (ADR-015)');
  if (kReleaseMode) {
    throw UnsupportedError('Mock service locator cannot be initialized in release mode');
  }

  // In-memory mock storage (never registered in release mode)
  sl.registerLazySingleton<RolePreferenceStorage>(
    () => MockRolePreferenceStorage(),
  );

  // Network simulation harness & config singletons
  sl.registerLazySingleton<MockConfig>(() => MockConfig.instance);
  sl.registerLazySingleton<MockNetworkHarness>(
    () => MockNetworkHarness(config: sl<MockConfig>()),
  );

  // Exemplary User Profile slice
  sl.registerLazySingleton<UserProfileDataSource>(
    () => MockUserProfileDataSource(harness: sl<MockNetworkHarness>()),
  );
  sl.registerLazySingleton<UserProfileRepository>(
    () => MockUserProfileRepository(dataSource: sl<UserProfileDataSource>()),
  );

  // Identity & Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => MockAuthRepository(harness: sl<MockNetworkHarness>()),
  );

  // Multi-Role Context Repository
  sl.registerLazySingleton<RoleContextRepository>(
    () => MockRoleContextRepository(
      harness: sl<MockNetworkHarness>(),
      preferenceStorage: sl<RolePreferenceStorage>(),
    ),
  );
}

/// Registers real remote API dependencies, Dio clients, and production repositories.
void initRemoteServiceLocator() {
  // Production storage implementation backed by SharedPreferences
  sl.registerLazySingleton<RolePreferenceStorage>(
    () => const SharedPrefsRolePreferenceStorage(),
  );

  // Real remote repositories will connect to live backend endpoints in Phase 1+.
  sl.registerLazySingleton<UserProfileRepository>(
    () => const RemoteUserProfileRepository(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => const RemoteAuthRepository(),
  );

  // Multi-Role Context Repository (safe 503 fallback placeholder)
  sl.registerLazySingleton<RoleContextRepository>(
    () => const RemoteRoleContextRepository(),
  );
}
