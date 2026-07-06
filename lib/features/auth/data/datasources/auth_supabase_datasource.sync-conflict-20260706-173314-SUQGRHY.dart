import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/user_model.dart';
import 'auth_datasource.dart';

/// Implementação do data source usando Supabase Auth.
/// Firebase é usado APENAS para obter o Google ID Token.
class AuthSupabaseDataSource implements AuthDataSource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  static Future<void>? _googleInitializeFuture;

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
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

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
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      AppLogger.error(
        'Erro inesperado ao fazer login.',
        name: 'AuthSupabaseDataSource',
        error: e,
      );
      throw const AuthException(
        message: 'Não foi possível fazer login. Tente novamente em instantes.',
      );
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
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      AppLogger.error(
        'Erro inesperado ao criar conta.',
        name: 'AuthSupabaseDataSource',
        error: e,
      );
      throw const AuthException(
        message:
            'Não foi possível criar sua conta. Tente novamente em instantes.',
      );
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      AppLogger.info(
        'Iniciando login com Google.',
        name: 'AuthSupabaseDataSource',
        context: {'platform': Platform.operatingSystem},
      );

      await _ensureGoogleInitialized();

      // 1. Google Sign-In para obter ID Token
      GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate(
          scopeHint: const ['email', 'profile'],
        );
      } on GoogleSignInException catch (e) {
        AppLogger.warning(
          'authenticate() falhou.',
          name: 'AuthSupabaseDataSource',
          error: e,
          context: {
            'code': e.code.name,
            'description': e.description,
            'details': e.details,
          },
        );

        final lightweightFuture =
            _googleSignIn.attemptLightweightAuthentication(
          reportAllExceptions: true,
        );
        final lightweightUser =
            lightweightFuture == null ? null : await lightweightFuture;
        if (lightweightUser == null) rethrow;
        googleUser = lightweightUser;
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        AppLogger.warning(
          'Google Sign-In não retornou idToken.',
          name: 'AuthSupabaseDataSource',
        );
        throw const AuthException(
          message: 'Não foi possível obter token do Google.',
        );
      }

      AppLogger.info(
        'Token Google obtido. Enviando para Supabase.',
        name: 'AuthSupabaseDataSource',
      );

      // 2. Enviar ID Token para Supabase Auth
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user == null) {
        AppLogger.warning(
          'Supabase não retornou usuário após login com Google.',
          name: 'AuthSupabaseDataSource',
        );
        throw const AuthException(message: 'Erro ao autenticar com Google.');
      }

      AppLogger.info(
        'Login com Google autenticado no Supabase.',
        name: 'AuthSupabaseDataSource',
        context: {'hasUser': true},
      );

      return _userFromSession(response.user!);
    } on AuthApiException catch (e) {
      AppLogger.warning(
        'Supabase rejeitou login com Google.',
        name: 'AuthSupabaseDataSource',
        error: e,
        context: {'statusCode': e.statusCode},
      );
      throw AuthException(message: _mapSupabaseError(e.message));
    } on AuthException catch (e) {
      throw AuthException(message: 'Falha no login com Google: ${e.message}');
    } on AuthRetryableFetchException {
      AppLogger.warning(
        'Falha de rede no login com Google.',
        name: 'AuthSupabaseDataSource',
      );
      throw const AuthException(
        message:
            'Não foi possível conectar ao servidor de autenticação. Verifique a internet e tente novamente.',
      );
    } on GoogleSignInException catch (e) {
      AppLogger.error(
        'Google Sign-In falhou.',
        name: 'AuthSupabaseDataSource',
        error: e,
        context: {
          'code': e.code.name,
          'description': e.description,
          'details': e.details,
        },
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.info(
          'Login com Google cancelado durante authenticate().',
          name: 'AuthSupabaseDataSource',
          context: {
            'description': e.description,
            'details': e.details,
          },
        );
        throw const AuthException(message: 'Login com Google cancelado.');
      }
      throw const AuthException(
        message:
            'Não foi possível entrar com Google. Tente novamente em instantes.',
      );
    } on PlatformException catch (e) {
      AppLogger.error(
        'Google Sign-In falhou na camada nativa.',
        name: 'AuthSupabaseDataSource',
        error: e,
        context: {
          'code': e.code,
          'message': e.message,
          'details': e.details,
        },
      );
      throw const AuthException(
        message:
            'Não foi possível entrar com Google. Tente novamente em instantes.',
      );
    } catch (e) {
      AppLogger.error(
        'Erro inesperado no login com Google.',
        name: 'AuthSupabaseDataSource',
        error: e,
      );
      throw AuthException(
        message:
            'Não foi possível entrar com Google. Tente novamente em instantes.',
      );
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitializeFuture ??= _googleSignIn.initialize(
      clientId: Platform.isIOS ? _iosClientId : null,
      serverClientId: _webClientId,
    );
  }

  /// Busca o perfil completo da tabela `profiles` e monta o UserModel.
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
          cpf: '', // CPF criptografado no banco, não retorna no select
          phone: '', // Telefone criptografado, não retorna no select
          role: profile['role'] as String? ?? 'user',
        );
      }

      // Fallback: profile ainda não criado (trigger pode ter delay)
      return UserModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? '',
        email: user.email ?? '',
        cpf: '',
        phone: '',
        role: 'user',
      );
    } catch (e) {
      // Se falhar ao buscar profile, retorna dados básicos do auth
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
    if (msg.contains('provider_disabled') ||
        msg.contains('provider') && msg.contains('not enabled')) {
      return 'Login com Google indisponível no momento.';
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
