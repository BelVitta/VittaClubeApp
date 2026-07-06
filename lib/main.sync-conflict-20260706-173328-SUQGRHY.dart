import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/dependents/presentation/pages/dependents_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

class AppRoutes {
  static const dependents = '/dependents';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isInitialized) {
    AppConfig.initStaging();
  }

  // Firebase: apenas para Google Sign-In
  await initializeFirebase();

  // Supabase: banco, auth, storage (só staging/prod)
  await SupabaseConfig.initialize();

  await di.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const VitaClubeApp());
}

class VitaClubeApp extends StatelessWidget {
  const VitaClubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.dependents) {
          final holderUserId = settings.arguments as String? ?? 'current-user';
          return MaterialPageRoute(
            builder: (_) => DependentsPage(holderUserId: holderUserId),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}
