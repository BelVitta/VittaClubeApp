import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initStaging();

  // Firebase: apenas para Google Sign-In
  await initializeFirebase();

  // Supabase: banco real (projeto staging)
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
      builder: (context, child) {
        return Banner(
          message: 'STG',
          location: BannerLocation.topStart,
          color: Colors.orange,
          child: child!,
        );
      },
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
