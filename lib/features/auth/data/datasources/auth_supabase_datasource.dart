import 'dart:developer' as dev;
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_datasource.dart';

/// Implementação do data source usando Supabase Auth.
/// Firebase é usado APENAS para obter o Google ID Token.
class AuthSupabaseDataSource implements AuthDataSource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  // Web client ID (tipo 3) — obrigatório para Supabase signInWithIdToken
  static const _webClientId =
      '538839527074-6jkduvf7njn04hcnjm8qhvrqk2mfpsh5.apps.googleusercontent.com';

  // iOS client ID (tipo 2) — lido do GoogleService-Info.plist no iOS
  static const _iosClientId =
      '538839527074-mnj5bjsb1uoisggi8sucrn2f4l8shsk9.apps.googleusercontent.com';

  AuthSupabaseDataSource({
    required SupabaseClient supabaseClient,
    GoogleSignIn? googleSignIn,
  })  : _supabase = supabaseClient,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: Platform.isIOS ? _iosClientId : null,
              serverClientId: _webClientId,
              scopes: ['email', 'profile'],
            );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException(message: 'Usuário não encontrado.');
      }

      return _userFromSession(response.user!);
    } on AuthRetryableFetchException catch (e) {
      _logServerError('login', e);
      throw const ServerUnavailableException();
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } catch (e) {
      if (e is AuthException || e is ServerUnavailableException) rethrow;
      _logServerError('login', e);
      throw AuthException(message: 'Erro ao fazer login: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
          'phone': phone.replaceAll(RegExp(r'\D'), ''),
        },
      );

      if (response.user == null) {
        throw const AuthException(message: 'Erro ao criar conta.');
      }

      return _userFromSession(response.user!);
    } on AuthRetryableFetchException catch (e) {
      _logServerError('register', e);
      throw const ServerUnavailableException();
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } catch (e) {
      if (e is AuthException || e is ServerUnavailableException) rethrow;
      _logServerError('register', e);
      throw AuthException(message: 'Erro ao criar conta: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(message: 'Login com Google cancelado.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException(
          message: 'Não foi possível obter token do Google.',
        );
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user == null) {
        throw const AuthException(message: 'Erro ao autenticar com Google.');
      }

      return _userFromSession(response.user!);
    } on AuthRetryableFetchException catch (e) {
      _logServerError('signInWithGoogle', e);
      throw const ServerUnavailableException();
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } on AuthException catch (e) {
      throw AuthException(message: 'Falha no login com Google: ${e.message}');
    } catch (e) {
      if (e is ServerUnavailableException) rethrow;
      throw AuthException(
        message: 'Erro inesperado no login com Google: ${e.toString()}',
      );
    }
  }

  void _logServerError(String operation, Object error) {
    dev.log(
      '[Supabase] Serviço indisponível durante "$operation". '
      'Verifique se o projeto está pausado no plano free.',
      name: 'AuthDataSource',
      error: error,
      level: 900,
    );
  }

  Future<UserModel> _userFromSession(User user) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('name, email, role')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        return UserModel(
          id: user.id,
          name: profile['name'] as String? ?? user.userMetadata?['name'] ?? '',
          email: profile['email'] as String? ?? user.email ?? '',
          cpf: '',
          phone: '',
          role: profile['role'] as String? ?? 'user',
        );
      }

      return UserModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? '',
        email: user.email ?? '',
        cpf: '',
        phone: '',
        role: 'user',
      );
    } catch (e) {
      return UserModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? '',
        email: user.email ?? '',
        cpf: '',
        phone: '',
        role: 'user',
      );
    }
  }

  String _mapSupabaseError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (msg.contains('email already registered') ||
        msg.contains('user already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return 'A senha é muito fraca. Use pelo menos 8 caracteres com letras e números.';
    }
    if (msg.contains('email') && msg.contains('invalid')) {
      return 'O formato do e-mail é inválido.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Muitas tentativas. Tente novamente mais tarde.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
}
