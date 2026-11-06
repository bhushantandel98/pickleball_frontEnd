import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/app/app_bloc_observer.dart';

class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void triggerError(Object error, StackTrace stackTrace) {
    onError(error, stackTrace);
  }
}

void main() {
  group('AppBlocObserver Logging Security Tests', () {
    test('does not log raw error messages or stack traces in debug mode', () {
      final logs = <String>[];
      final observer = AppBlocObserver(
        logPrinter: logs.add,
        isDebugMode: true,
      );

      final cubit = _TestCubit();
      const sensitiveToken = 'Bearer secret-user-auth-token-12345';
      const sensitivePassword = 'super_secret_password_xyz';
      final exception = Exception('Failed with $sensitiveToken and $sensitivePassword');
      final stackTrace = StackTrace.current;

      observer.onError(cubit, exception, stackTrace);

      // Verify that exactly one sanitized diagnostic message was printed
      expect(logs.length, 1);
      final logMessage = logs.first;

      // Diagnostic should contain component and error runtime types only
      expect(logMessage, contains('_TestCubit'));
      expect(logMessage, contains('_Exception'));

      // Strict security verifications: zero sensitive data and zero stack trace traces
      expect(logMessage, isNot(contains(sensitiveToken)));
      expect(logMessage, isNot(contains(sensitivePassword)));
      expect(logMessage, isNot(contains('Failed with')));
      expect(logMessage, isNot(contains('#0')));
      expect(logMessage, isNot(contains('.dart')));
    });

    test('does not log state payloads on state change', () {
      final logs = <String>[];
      final observer = AppBlocObserver(
        logPrinter: logs.add,
        isDebugMode: true,
      );

      final cubit = _TestCubit();
      observer.onChange(
        cubit,
        const Change<int>(currentState: 0, nextState: 9999),
      );

      expect(logs.length, 1);
      expect(logs.first, '_TestCubit changed');
      expect(logs.first, isNot(contains('9999')));
      expect(logs.first, isNot(contains('currentState')));
      expect(logs.first, isNot(contains('nextState')));
    });

    test('silences all logging when not in debug mode (release mode)', () {
      final logs = <String>[];
      final observer = AppBlocObserver(
        logPrinter: logs.add,
        isDebugMode: false,
      );

      final cubit = _TestCubit();
      observer.onChange(
        cubit,
        const Change<int>(currentState: 0, nextState: 1),
      );
      observer.onError(
        cubit,
        Exception('Sensitive leak attempt'),
        StackTrace.current,
      );

      expect(logs, isEmpty);
    });
  });
}
