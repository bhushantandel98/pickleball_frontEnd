import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/features/identity/data/models/login_request_model.dart';
import 'package:pickleball_platform/features/identity/domain/entities/auth_session.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';

/// State hierarchy for the login presentation flow.
sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial resting state before user submission.
final class LoginInitial extends LoginState {
  const LoginInitial();
}

/// In-flight state during authentication request processing.
final class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Successful authentication delivering an active [AuthSession].
final class LoginSuccess extends LoginState {
  final AuthSession session;

  const LoginSuccess(this.session);

  @override
  List<Object?> get props => [session];
}

/// Authentication failure state delivering a user-facing error message.
final class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// State management Cubit orchestrating the user login flow.
///
/// Coordinates between user input validation and the domain [AuthRepository].
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;

  LoginCubit({required this.authRepository})
      : super(const LoginInitial());

  /// Submits the login form credentials to the repository.
  Future<void> submitLogin({
    required String phone,
    required String password,
    String countryCode = '+91',
  }) async {
    emit(const LoginLoading());

    final request = LoginRequestModel(
      phone: phone,
      password: password,
      countryCode: countryCode,
    );

    final result = await authRepository.login(request);

    result.when(
      success: (session) => emit(LoginSuccess(session)),
      failure: (failure) => emit(LoginFailure(failure.message)),
    );
  }

  /// Resets state back to [LoginInitial] (e.g. after error dismissal or form clear).
  void reset() {
    emit(const LoginInitial());
  }
}
