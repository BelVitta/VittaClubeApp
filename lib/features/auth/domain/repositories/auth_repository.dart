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

  /// Registra novo usuário
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
  });

  /// Login com Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Realiza logout
  Future<Either<Failure, void>> logout();

  /// Obtém usuário atual do cache
  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
