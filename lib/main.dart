import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/url_strategy/url_strategy_stub.dart'
    if (dart.library.ui_web) 'core/utils/url_strategy/url_strategy_web.dart';
import 'services/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Riverpod container to read providers outside of widgets
  final container = ProviderContainer();

  // Initialize Notification Service
  //todo: test later
  // try {
  //   await container.read(notificationServiceProvider).initialize();
  // } catch (e) {
  //   debugPrint('Failed to initialize notifications: $e');
  // }

  // Configure URL strategy conditionally for Web
  configureUrlStrategy();

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(lightColorScheme),
      darkTheme: buildTheme(darkColorScheme),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
