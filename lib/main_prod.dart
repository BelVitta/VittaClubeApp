import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/navigation/app_navigator.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/widgets/password_recovery_listener.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initProd();

  // Firebase: Google Sign-In + FCM
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  installPushBackgroundHandler();

  // Supabase: banco real (projeto prod)
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
    return PasswordRecoveryListener(
      child: MaterialApp(
        title: AppConfig.instance.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: AppNavigator.key,
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}
