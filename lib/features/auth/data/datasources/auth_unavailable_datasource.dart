import '../../../../core/error/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/user_model.dart';
import 'auth_datasource.dart';

class AuthUnavailableDataSource implements AuthDataSource {
  const AuthUnavailableDataSource();

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) {
    _logUnavailable('login');
    throw const AuthException(message: _userMessage);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
  }) {
    _logUnavailable('register');
    throw const AuthException(message: _userMessage);
  }

  @override
  Future<UserModel> signInWithGoogle() {
    _logUnavailable('signInWithGoogle');
    throw const AuthException(message: _userMessage);
  }

  static const _userMessage =
      'Não foi possível conectar ao servidor. Tente novamente em instantes.';

  void _logUnavailable(String operation) {
    AppLogger.warning(
      'AuthDataSource indisponível em $operation: Supabase não inicializado. '
      'Verifique SUPABASE_URL e SUPABASE_ANON_KEY no build.',
      name: 'AuthUnavailableDataSource',
      context: {'operation': operation},
    );
  }
}
