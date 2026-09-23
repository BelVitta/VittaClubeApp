import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  AppConfig.initDev();

  // Firebase: Google Sign-In (+ FCM no isolate; token só com Supabase)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  installPushBackgroundHandler();

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
          message: 'DEV',
          location: BannerLocation.topStart,
          color: Colors.red,
          child: child!,
        );
      },
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
