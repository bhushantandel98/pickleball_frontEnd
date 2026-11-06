import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/widgets/state_views/account_suspended_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/permission_denied_view.dart';

/// Sealed hierarchy of asynchronous UI states for Clean Architecture screens.
///
/// Designed to standardize presentation across all 12 platform role modules.
sealed class AsyncState<T> {
  const AsyncState();

  const factory AsyncState.initial() = AsyncInitial<T>;
  const factory AsyncState.loading({String? message}) = AsyncLoading<T>;
  const factory AsyncState.success(T data) = AsyncSuccess<T>;
  const factory AsyncState.empty({
    String? title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) = AsyncEmpty<T>;
  const factory AsyncState.error({
    required Failure failure,
    VoidCallback? onRetry,
  }) = AsyncError<T>;
  const factory AsyncState.unauthorized({
    String? message,
    VoidCallback? onLogin,
  }) = AsyncUnauthorized<T>;
  const factory AsyncState.permissionDenied({
    String? message,
    VoidCallback? onAction,
  }) = AsyncPermissionDenied<T>;
  const factory AsyncState.suspended({
    String? supportContact,
    VoidCallback? onContactSupport,
  }) = AsyncSuspended<T>;

  /// Factory helper that maps a domain [Result<T>] directly into an [AsyncState<T>].
  factory AsyncState.fromResult(
    Result<T> result, {
    VoidCallback? onRetry,
    bool Function(T data)? isEmpty,
    String? emptyMessage,
  }) {
    return switch (result) {
      Success<T>(data: final d) => (isEmpty != null && isEmpty(d))
          ? AsyncEmpty<T>(message: emptyMessage ?? 'No records available.')
          : AsyncSuccess<T>(d),
      FailureResult<T>(failure: final f) => switch (f) {
          UnauthorizedFailure() => AsyncUnauthorized<T>(
              message: f.message,
              onLogin: onRetry,
            ),
          ForbiddenFailure() => AsyncPermissionDenied<T>(
              message: f.message,
              onAction: onRetry,
            ),
          _ => AsyncError<T>(failure: f, onRetry: onRetry),
        },
    };
  }
}

/// Initial uninitialized state before any asynchronous operation begins.
final class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

/// Loading in-flight state with optional status message.
final class AsyncLoading<T> extends AsyncState<T> {
  final String? message;
  const AsyncLoading({this.message});
}

/// Successful terminal state holding resolved domain [data].
final class AsyncSuccess<T> extends AsyncState<T> {
  final T data;
  const AsyncSuccess(this.data);
}

/// Empty data state when request succeeded but returned zero records.
final class AsyncEmpty<T> extends AsyncState<T> {
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AsyncEmpty({
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });
}

/// Generic error state with typed [failure] and optional retry callback.
final class AsyncError<T> extends AsyncState<T> {
  final Failure failure;
  final VoidCallback? onRetry;

  const AsyncError({
    required this.failure,
    this.onRetry,
  });
}

/// Authentication failure state (HTTP 401) directing user to log in.
final class AsyncUnauthorized<T> extends AsyncState<T> {
  final String? message;
  final VoidCallback? onLogin;

  const AsyncUnauthorized({
    this.message,
    this.onLogin,
  });
}

/// Authorization failure state (HTTP 403) indicating insufficient permissions.
final class AsyncPermissionDenied<T> extends AsyncState<T> {
  final String? message;
  final VoidCallback? onAction;

  const AsyncPermissionDenied({
    this.message,
    this.onAction,
  });
}

/// Account suspended state directing user to support contact channels.
final class AsyncSuspended<T> extends AsyncState<T> {
  final String? supportContact;
  final VoidCallback? onContactSupport;

  const AsyncSuspended({
    this.supportContact,
    this.onContactSupport,
  });
}

/// Centralized presentation helper that renders appropriate state views.
///
/// Directly reuses existing P0-04 atomic state views ([LoadingView], [EmptyStateView],
/// [ErrorStateView], [PermissionDeniedView], [AccountSuspendedView]) to guarantee
/// visual and behavioral consistency across all 12 platform roles without duplication.
class AsyncStateView<T> extends StatelessWidget {
  final AsyncState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final WidgetBuilder? initialBuilder;
  final Widget Function(BuildContext context, String? message)? loadingBuilder;
  final Widget Function(
    BuildContext context,
    String title,
    String message,
    String? actionLabel,
    VoidCallback? onAction,
  )? emptyBuilder;
  final Widget Function(BuildContext context, Failure failure, VoidCallback? onRetry)? errorBuilder;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.builder,
    this.initialBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  });

  /// Convenience constructor to construct an [AsyncStateView] directly from a [Result<T>].
  factory AsyncStateView.fromResult({
    Key? key,
    required Result<T> result,
    required Widget Function(BuildContext context, T data) builder,
    VoidCallback? onRetry,
    bool Function(T data)? isEmpty,
    String? emptyMessage,
  }) {
    return AsyncStateView<T>(
      key: key,
      state: AsyncState<T>.fromResult(
        result,
        onRetry: onRetry,
        isEmpty: isEmpty,
        emptyMessage: emptyMessage,
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncInitial<T>() => initialBuilder?.call(context) ?? const SizedBox.shrink(),
      AsyncLoading<T>(message: final msg) =>
        loadingBuilder?.call(context, msg) ?? LoadingView(message: msg),
      AsyncSuccess<T>(data: final data) => builder(context, data),
      AsyncEmpty<T>(
        title: final title,
        message: final msg,
        actionLabel: final actLabel,
        onAction: final act,
      ) =>
        emptyBuilder?.call(
          context,
          title ?? 'No Items Found',
          msg ?? 'There are no items to display at this time.',
          actLabel,
          act,
        ) ??
            EmptyStateView(
              title: title ?? 'No Items Found',
              message: msg ?? 'There are no items to display at this time.',
              actionLabel: actLabel,
              onAction: act,
            ),
      AsyncError<T>(failure: final failure, onRetry: final retry) =>
        errorBuilder?.call(context, failure, retry) ??
            ErrorStateView(
              message: failure.message,
              onRetry: retry,
            ),
      AsyncUnauthorized<T>(message: final msg, onLogin: final login) => ErrorStateView(
          title: 'Session Expired',
          message: msg ?? 'Your session has expired. Please log in again to continue.',
          retryLabel: 'Log In',
          onRetry: login,
        ),
      AsyncPermissionDenied<T>(message: final msg, onAction: final act) =>
        PermissionDeniedView(
          message: msg ??
              'You do not have permission to view this section or perform this action.',
          onAction: act,
        ),
      AsyncSuspended<T>(supportContact: final contact, onContactSupport: final onContact) =>
        AccountSuspendedView(
          supportContact: contact,
          onContactSupport: onContact,
        ),
    };
  }
}
