import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../financeiro/presentation/pages/financeiro_dashboard_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/personal_data_page.dart';
import '../../../parceiro/presentation/pages/parceiro_dashboard_page.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SplashBloc>()..add(SplashStarted()),
      child: const SplashView(),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToOnboarding) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingPage()),
          );
        } else if (state is SplashNavigateToLogin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else if (state is SplashNavigateToAdmin) {
          unawaited(sl<PushNotificationService>().start());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          );
        } else if (state is SplashNavigateToFinanceiro) {
          unawaited(sl<PushNotificationService>().start());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FinanceiroDashboardPage()),
          );
        } else if (state is SplashNavigateToPartner) {
          unawaited(sl<PushNotificationService>().start());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ParceiroDashboardPage()),
          );
        } else if (state is SplashNavigateToHome) {
          unawaited(sl<PushNotificationService>().start());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else if (state is SplashNavigateToCompleteProfile) {
          unawaited(sl<PushNotificationService>().start());
          final sessionUser = SupabaseConfig.isInitialized
              ? SupabaseConfig.client.auth.currentUser
              : null;
          final meta = sessionUser?.userMetadata;
          String metaOf(String key) {
            final v = meta?[key];
            return v == null ? '' : v.toString().trim();
          }

          final name = metaOf('full_name').isNotEmpty
              ? metaOf('full_name')
              : metaOf('name');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PersonalDataPage(
                requiredCompletion: true,
                initialName: name,
                initialEmail: sessionUser?.email ?? metaOf('email'),
                initialCpf: metaOf('cpf'),
                initialPhone: metaOf('phone'),
              ),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: AppTheme.primaryColor,
          body: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/Logo.png',
                        width: 202.6,
                        height: 105.8,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
