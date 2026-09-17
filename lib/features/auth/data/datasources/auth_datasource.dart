import '../models/user_model.dart';

abstract class AuthDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
    String? receptionistCode,
  });
  Future<UserModel> signInWithGoogle();

  /// Encerra a sessão do Google Sign-In (e outros providers locais).
  /// Necessário no logout para permitir trocar de conta Google no próximo login.
  Future<void> signOutExternalProviders();

  /// Checa se o CPF já está em uso por outra conta, antes do cadastro.
  Future<bool> checkCpfAvailable(String cpf);

  /// Altera a senha do usuário logado (reautentica com a senha atual).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Envia e-mail de recuperação (SMTP/Resend via Supabase Auth).
  Future<void> requestPasswordReset({required String email});

  /// Define nova senha quando já há sessão de recovery (deep link do e-mail).
  Future<void> updatePassword({required String newPassword});
}
