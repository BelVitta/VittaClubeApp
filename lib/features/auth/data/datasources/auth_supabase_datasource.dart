import 'dart:developer' as dev;
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/rate_limit.dart';
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

      await _syncProfileAfterAuth(response.user!);
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
    String? receptionistCode,
  }) async {
    try {
      final trimmedCode = receptionistCode?.trim();
      final cpfDigits = cpf.replaceAll(RegExp(r'\D'), '');
      final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'cpf': cpfDigits,
          'phone': phoneDigits,
          if (trimmedCode != null && trimmedCode.isNotEmpty)
            'receptionist_code': trimmedCode,
        },
      );

      if (response.user == null) {
        throw const AuthException(message: 'Erro ao criar conta.');
      }

      // Se houver sessão (e-mail confirmation desligado), garante perfil + sensíveis.
      await _syncProfileAfterAuth(
        response.user!,
        name: name,
        email: email,
        cpf: cpfDigits,
        phone: phoneDigits,
      );

      final user = await _userFromSession(response.user!);
      // Mantém o que o usuário acabou de digitar mesmo se o backend atrasar.
      return UserModel(
        id: user.id,
        name: user.name.isNotEmpty ? user.name : name.trim(),
        email: user.email.isNotEmpty ? user.email : email.trim(),
        cpf: user.cpf.isNotEmpty ? user.cpf : cpfDigits,
        phone: user.phone.isNotEmpty ? user.phone : phoneDigits,
        role: user.role,
      );
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
      // Sem signOut prévio, o SDK reutiliza a última conta Google e não
      // mostra o seletor — impossibilitando trocar de conta após logout.
      await _clearGoogleSession();

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

      await _syncProfileAfterAuth(response.user!);
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

  @override
  Future<void> signOutExternalProviders() async {
    await _clearGoogleSession();
  }

  /// Limpa a sessão local do Google Sign-In sem falhar o fluxo do app.
  Future<void> _clearGoogleSession() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      dev.log(
        'Falha ao fazer signOut do Google (ignorada).',
        name: 'AuthDataSource',
        error: e,
        level: 800,
      );
    }
  }

  /// Deep link aberto pelo e-mail de recuperação (configurar no Supabase Redirect URLs).
  static const passwordResetRedirectTo = 'vittaclube://auth/reset-password';

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final email = user?.email;
      if (user == null || email == null || email.isEmpty) {
        throw const AuthException(
          message:
              'Conta sem e-mail/senha. Quem entrou só com Google deve usar "Esqueci a senha" no login para definir uma senha.',
        );
      }

      // Conta só Google nunca teve senha — precisa do fluxo de recovery.
      final providers =
          user.identities?.map((i) => i.provider).toSet() ?? const <String>{};
      final hasPasswordIdentity =
          providers.contains('email') || providers.contains('phone');
      if (!hasPasswordIdentity && providers.contains('google')) {
        throw const AuthException(
          message:
              'Esta conta entra com Google e ainda não tem senha. Use "Esqueci a senha" no login (com este e-mail) para definir uma.',
        );
      }

      // Confirma a senha atual reautenticando.
      final reauth = await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      if (reauth.user == null) {
        throw const AuthException(message: 'Senha atual incorreta.');
      }

      final updated = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (updated.user == null) {
        throw const AuthException(message: 'Não foi possível alterar a senha.');
      }
    } on AuthRetryableFetchException catch (e) {
      _logServerError('changePassword', e);
      throw const ServerUnavailableException();
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is ServerUnavailableException) rethrow;
      throw AuthException(
        message: 'Erro ao alterar senha: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: passwordResetRedirectTo,
      );
    } on AuthRetryableFetchException catch (e) {
      _logServerError('requestPasswordReset', e);
      throw const ServerUnavailableException();
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } catch (e) {
      if (e is ServerUnavailableException) rethrow;
      throw AuthException(
        message: 'Erro ao enviar e-mail de recuperação: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw const AuthException(
          message:
              'Sessão de recuperação inválida ou expirada. Solicite um novo link.',
        );
      }
      final updated = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (updated.user == null) {
        throw const AuthException(
            message: 'Não foi possível redefinir a senha.');
      }
    } on AuthRetryableFetchException catch (e) {
      _logServerError('updatePassword', e);
      throw const ServerUnavailableException();
    } on AuthApiException catch (e) {
      throw AuthException(message: _mapSupabaseError(e.message));
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is ServerUnavailableException) rethrow;
      throw AuthException(
        message: 'Erro ao redefinir senha: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> checkCpfAvailable(String cpf) async {
    try {
      final digits = cpf.replaceAll(RegExp(r'\D'), '');
      final result = await _supabase.rpc(
        'check_cpf_available',
        params: {'p_cpf': digits},
      );
      return result as bool;
    } on AuthRetryableFetchException catch (e) {
      _logServerError('checkCpfAvailable', e);
      throw const ServerUnavailableException();
    } catch (e) {
      throw ServerException(message: 'Erro ao checar CPF: $e');
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

  /// Garante linha em `profiles` e tenta persistir CPF/telefone do metadata.
  ///
  /// Cobre três caminhos de falha comuns no signup e-mail/senha:
  /// 1. Trigger `handle_new_user` engole erro e deixa o user em auth sem profile.
  /// 2. RPC `ensure_own_profile` ausente/falha no remoto.
  /// 3. UPDATE de nome junto com e-mail bloqueado pelo trigger de colunas.
  ///
  /// Ignora erros residuais: a tela de completar cadastro cobre o restante.
  Future<void> _syncProfileAfterAuth(
    User user, {
    String? name,
    String? email,
    String? cpf,
    String? phone,
  }) async {
    if (_supabase.auth.currentSession == null) return;

    // Metadata do signup e-mail/senha: name; Google: full_name / given_name.
    final metaName = _firstNonEmptyMeta(user, const [
      'full_name',
      'name',
      'given_name',
    ]);
    final resolvedName =
        (name?.trim().isNotEmpty == true) ? name!.trim() : metaName;
    final resolvedEmail = (email?.trim().isNotEmpty == true)
        ? email!.trim()
        : (user.email ?? _metaString(user, 'email'));
    final cpfDigits =
        (cpf ?? _metaString(user, 'cpf')).replaceAll(RegExp(r'\D'), '');
    final phoneDigits =
        (phone ?? _metaString(user, 'phone')).replaceAll(RegExp(r'\D'), '');

    try {
      await _supabase.rpc('ensure_own_profile');
    } catch (e) {
      _logServerError('ensure_own_profile', e);
    }

    // Se o trigger/RPC falhou, tenta criar o perfil via RLS (insert próprio).
    try {
      final existing = await _supabase
          .from('profiles')
          .select('id, name')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        final fallbackName = resolvedName.isNotEmpty
            ? resolvedName
            : (resolvedEmail.contains('@')
                ? resolvedEmail.split('@').first
                : 'Usuário');
        await _supabase.from('profiles').insert({
          'id': user.id,
          'name': fallbackName,
          'email': resolvedEmail.isNotEmpty
              ? resolvedEmail
              : '${user.id}@users.local',
          'role': 'user',
        });
      } else if (resolvedName.isNotEmpty) {
        final stored = (existing['name'] as String?)?.trim() ?? '';
        if (stored.isEmpty) {
          // Só nome — e-mail é imutável no trigger de proteção.
          await _supabase.from('profiles').update({
            'name': resolvedName,
          }).eq('id', user.id);
        } else if (stored != resolvedName &&
            name != null &&
            name.trim().isNotEmpty) {
          // Cadastro acabou de enviar o nome digitado: prioriza o formulário.
          await _supabase.from('profiles').update({
            'name': resolvedName,
          }).eq('id', user.id);
        }
      }
    } catch (e) {
      _logServerError('sync_profile_row', e);
    }

    // Só grava sensíveis quando ambos existem — o RPC zera o campo se
    // vier vazio, o que apagaria CPF/telefone já salvos no login Google.
    if (cpfDigits.isNotEmpty && phoneDigits.isNotEmpty) {
      try {
        await _supabase.rpc('update_user_sensitive_profile', params: {
          'p_user_id': user.id,
          'p_cpf': cpfDigits,
          'p_phone': phoneDigits,
        });
      } catch (e) {
        _logServerError('update_user_sensitive_profile', e);
      }
    }
  }

  String _metaString(User user, String key) {
    final value = user.userMetadata?[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  String _firstNonEmptyMeta(User user, List<String> keys) {
    for (final key in keys) {
      final value = _metaString(user, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<UserModel> _userFromSession(User user) async {
    final metaName = _metaString(user, 'full_name').isNotEmpty
        ? _metaString(user, 'full_name')
        : _metaString(user, 'name');
    final metaEmail = user.email ?? _metaString(user, 'email');
    final metaCpf = _metaString(user, 'cpf').replaceAll(RegExp(r'\D'), '');
    final metaPhone = _metaString(user, 'phone').replaceAll(RegExp(r'\D'), '');

    try {
      final profile = await _supabase
          .from('profiles')
          .select('name, email, role')
          .eq('id', user.id)
          .maybeSingle();

      String cpf = '';
      String phone = '';
      try {
        final sensitive = await _supabase.rpc(
          'get_user_sensitive_profile',
          params: {'p_user_id': user.id},
        );
        final rows = sensitive is List
            ? sensitive
            : (sensitive == null ? const [] : [sensitive]);
        if (rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first as Map);
          cpf = (row['cpf'] ?? '').toString();
          phone = (row['phone'] ?? '').toString();
        }
      } catch (_) {
        // Perfil público continua disponível mesmo se os dados sensíveis
        // ainda não tiverem sido preenchidos.
      }

      final profileName = (profile?['name'] as String?)?.trim() ?? '';
      final profileEmail = (profile?['email'] as String?)?.trim() ?? '';

      return UserModel(
        id: user.id,
        name: profileName.isNotEmpty ? profileName : metaName,
        email: profileEmail.isNotEmpty ? profileEmail : metaEmail,
        cpf: cpf.isNotEmpty ? cpf : metaCpf,
        phone: phone.isNotEmpty ? phone : metaPhone,
        role: profile?['role'] as String? ?? 'user',
      );
    } catch (e) {
      return UserModel(
        id: user.id,
        name: metaName,
        email: metaEmail,
        cpf: metaCpf,
        phone: metaPhone,
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
    if (msg.contains('cpf')) {
      return 'Este CPF já está cadastrado.';
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return 'A senha é muito fraca. Use pelo menos 8 caracteres com letras e números.';
    }
    if (msg.contains('email') && msg.contains('invalid')) {
      return 'O formato do e-mail é inválido.';
    }
    if (RateLimitMessages.looksLike(message)) {
      return RateLimitMessages.userFacing;
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
}
