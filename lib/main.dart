import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '/core/router/app_router.dart';
import '/core/theme/app_theme.dart';
import '/services/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  usePathUrlStrategy();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Center Assistant',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(lightColorScheme),
      darkTheme: buildTheme(darkColorScheme),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
