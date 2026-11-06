import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/app.dart';
import 'package:pickleball_platform/app/app_bloc_observer.dart';
import 'package:pickleball_platform/app/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Bloc observer for state transition tracking
  Bloc.observer = const AppBlocObserver();

  // Initialize service locator registry
  await initServiceLocator();

  runApp(const PickleballApp());
}
