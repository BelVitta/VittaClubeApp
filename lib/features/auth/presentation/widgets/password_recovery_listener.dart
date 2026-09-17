import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../pages/reset_password_page.dart';

/// Escuta deep link de recovery + evento [AuthChangeEvent.passwordRecovery]
/// e abre a tela de nova senha.
class PasswordRecoveryListener extends StatefulWidget {
  final Widget child;

  const PasswordRecoveryListener({super.key, required this.child});

  @override
  State<PasswordRecoveryListener> createState() =>
      _PasswordRecoveryListenerState();
}

class _PasswordRecoveryListenerState extends State<PasswordRecoveryListener> {
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Uri>? _linkSub;
  bool _openedReset = false;

  @override
  void initState() {
    super.initState();
    if (!SupabaseConfig.isInitialized) return;

    _authSub = SupabaseConfig.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _openResetPassword();
      }
    });

    final appLinks = AppLinks();
    _linkSub = appLinks.uriLinkStream.listen(_handleUri);
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  Future<void> _handleUri(Uri uri) async {
    if (!SupabaseConfig.isInitialized) return;

    final isAuthReset = uri.scheme == 'vittaclube' &&
        (uri.host == 'auth' || uri.path.contains('reset-password'));
    final hasAuthParams = uri.fragment.contains('access_token') ||
        uri.queryParameters.containsKey('code') ||
        uri.toString().contains('type=recovery');

    if (!isAuthReset && !hasAuthParams) return;

    try {
      // PKCE / tokens no deep link → estabelece sessão de recovery.
      await SupabaseConfig.client.auth.getSessionFromUrl(uri);
    } catch (_) {
      // Se o SDK já consumiu o link, o evento passwordRecovery ainda pode disparar.
    }

    if (SupabaseConfig.auth.currentSession != null) {
      _openResetPassword();
    }
  }

  void _openResetPassword() {
    if (_openedReset) return;
    final nav = AppNavigator.state;
    if (nav == null) {
      // App ainda no splash — tenta de novo no próximo frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openResetPassword();
      });
      return;
    }
    _openedReset = true;
    nav.push(
      MaterialPageRoute(
        builder: (_) => const ResetPasswordPage(fromRecoveryLink: true),
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
