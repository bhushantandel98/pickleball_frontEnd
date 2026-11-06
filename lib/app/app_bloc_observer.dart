import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global BlocObserver for state transitions and diagnostic error tracking.
///
/// Security & Logging Standards:
/// - Never logs raw exception messages, error payloads, or stack traces.
/// - Never logs state payloads or sensitive user data.
/// - In debug mode, emits only sanitized high-level type diagnostics.
/// - In release/production mode, remains completely silent.
class AppBlocObserver extends BlocObserver {
  final void Function(String message)? logPrinter;
  final bool isDebugMode;

  const AppBlocObserver({
    this.logPrinter,
    this.isDebugMode = kDebugMode,
  });

  void _log(String message) {
    if (logPrinter != null) {
      logPrinter!(message);
    } else {
      debugPrint(message);
    }
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (isDebugMode) {
      _log('${bloc.runtimeType} changed');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (isDebugMode) {
      _log('${bloc.runtimeType} encountered an error: ${error.runtimeType}');
    }
  }
}
