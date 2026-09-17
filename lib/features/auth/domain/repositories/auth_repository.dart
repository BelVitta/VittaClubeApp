import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Interface do repositório de autenticação.
/// Define o contrato que a camada Data deve implementar.
abstract class AuthRepository {
  /// Realiza login com e-mail e senha
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Registra novo usuário. [receptionistCode] é o código opcional da
  /// recepcionista que indicou o cadastro.
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
    String? receptionistCode,
  });

  /// Login com Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Checa se o CPF já está em uso por outra conta, antes do cadastro.
  Future<Either<Failure, bool>> checkCpfAvailable(String cpf);

  /// Altera a senha do usuário logado.
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Solicita e-mail de recuperação (Resend/SMTP via Supabase).
  Future<Either<Failure, void>> requestPasswordReset({required String email});

  /// Redefine senha após abrir o link do e-mail (sessão recovery).
  Future<Either<Failure, void>> updatePassword({required String newPassword});

  /// Realiza logout
  Future<Either<Failure, void>> logout();

  /// Obtém usuário atual do cache
  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
