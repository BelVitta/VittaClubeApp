import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_clube/features/auth/data/models/user_model.dart';
import 'package:vita_clube/features/auth/data/services/auth_session_manager.dart';

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late SharedPreferences sharedPreferences;
  late _MockGoTrueClient authClient;
  late AuthSessionManager sessionManager;

  const user = UserModel(
    id: 'user-1',
    name: 'Diana',
    email: 'diana@vitaclube.com',
    cpf: '',
    phone: '',
    role: 'user',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    authClient = _MockGoTrueClient();
    when(() => authClient.signOut()).thenAnswer((_) async {});

    sessionManager = AuthSessionManager(
      sharedPreferences: sharedPreferences,
      authClient: authClient,
    );
  });

  group('AuthSessionManager', () {
    test('salva sessao com expiracao de 24 horas', () async {
      final loginAt = DateTime(2026, 4, 22, 10, 30);

      await sessionManager.saveSession(user, now: loginAt);

      expect(
        sharedPreferences.getString(AuthSessionManager.cachedUserKey),
        isNotNull,
      );
      expect(
        sharedPreferences.getString(AuthSessionManager.sessionLoggedInAtKey),
        loginAt.toIso8601String(),
      );
      expect(
        sharedPreferences.getString(AuthSessionManager.sessionExpiresAtKey),
        loginAt.add(const Duration(hours: 24)).toIso8601String(),
      );
    });

    test('considera valida a sessao antes de 24 horas', () async {
      final loginAt = DateTime(2026, 4, 22, 10, 30);
      await sessionManager.saveSession(user, now: loginAt);

      final isValid = await sessionManager.isSessionWindowValid(
        now: loginAt.add(const Duration(hours: 23, minutes: 59)),
      );

      expect(isValid, isTrue);
    });

    test('invalida e limpa a sessao ao passar de 24 horas', () async {
      final loginAt = DateTime(2026, 4, 22, 10, 30);
      await sessionManager.saveSession(user, now: loginAt);

      final isValid = await sessionManager.isSessionWindowValid(
        now: loginAt.add(const Duration(hours: 24, seconds: 1)),
      );

      expect(isValid, isFalse);
      expect(
        sharedPreferences.getString(AuthSessionManager.cachedUserKey),
        isNull,
      );
      expect(
        sharedPreferences.getString(AuthSessionManager.sessionExpiresAtKey),
        isNull,
      );
    });

    test('clearSession limpa storage e faz signOut no Supabase', () async {
      await sessionManager.saveSession(user);

      await sessionManager.clearSession();

      expect(
        sharedPreferences.getString(AuthSessionManager.cachedUserKey),
        isNull,
      );
      verify(() => authClient.signOut()).called(1);
    });
  });
}
