import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/notifications/presentation/notification_router.dart';
import '../../firebase_options.dart';
import '../config/supabase_config.dart';
import '../navigation/app_navigator.dart';
import '../theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _started = false;

  Future<void> start() async {
    if (kIsWeb || !SupabaseConfig.isInitialized) return;
    if (_started) {
      await _syncToken();
      return;
    }
    _started = true;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await _syncToken();
    _tokenSub = _messaging.onTokenRefresh.listen((token) {
      unawaited(_upsertToken(token));
    });
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForeground);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onOpened(initial);
    }
  }

  Future<void> unregister() async {
    if (!SupabaseConfig.isInitialized) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await SupabaseConfig.client
          .from('device_tokens')
          .delete()
          .eq('token', token);
    } catch (_) {
      // Logout não pode falhar por causa do token.
    }
  }

  Future<void> _syncToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _upsertToken(token);
    } catch (_) {}
  }

  Future<void> _upsertToken(String token) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    await SupabaseConfig.client.from('device_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );
  }

  void _onForeground(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    final context = AppNavigator.context;
    if (context == null || !context.mounted) return;
    if (title == null && body == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryColor,
        content: Text(
          [title, body]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join('\n'),
        ),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () => NotificationRouter.openFromData(message.data),
        ),
      ),
    );
  }

  void _onOpened(RemoteMessage message) {
    NotificationRouter.openFromData(message.data);
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _started = false;
  }
}

/// Garante Firebase Messaging no isolate de background antes do runApp.
void installPushBackgroundHandler() {
  if (kIsWeb) return;
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
