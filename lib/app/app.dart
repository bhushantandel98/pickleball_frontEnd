import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/router/app_router.dart';

/// Root application widget configuring Material 3 theme, SessionBloc scope,
/// and declarative GoRouter navigation.
class PickleballApp extends StatefulWidget {
  final ThemeMode themeMode;
  final SessionCubit? sessionCubit;
  final GoRouter? router;

  const PickleballApp({
    super.key,
    this.themeMode = ThemeMode.system,
    this.sessionCubit,
    this.router,
  });

  @override
  State<PickleballApp> createState() => _PickleballAppState();
}

class _PickleballAppState extends State<PickleballApp> {
  late final SessionCubit _sessionCubit;
  late final GoRouter _router;
  late final bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    if (widget.sessionCubit != null) {
      _sessionCubit = widget.sessionCubit!;
      _ownsCubit = false;
    } else if (sl.isRegistered<SessionCubit>()) {
      _sessionCubit = sl<SessionCubit>();
      _ownsCubit = false;
    } else {
      _sessionCubit = SessionCubit();
      _ownsCubit = true;
    }

    _router = widget.router ?? createAppRouter(sessionCubit: _sessionCubit);
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _sessionCubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionCubit>.value(
      value: _sessionCubit,
      child: MaterialApp.router(
        title: 'Pickleball Platform',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: widget.themeMode,
      ),
    );
  }
}
