import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_admin_entity.dart';

/// Interface do repositório de usuários no painel admin.
/// Define o contrato que a camada Data deve implementar.
abstract class UserAdminRepository {
  /// Obtém todos os usuários
  Future<Either<Failure, List<UserAdminEntity>>> getAll();

  /// Cria um novo usuário
  Future<Either<Failure, UserAdminEntity>> create(UserAdminEntity entity);

  /// Atualiza um usuário existente
  Future<Either<Failure, UserAdminEntity>> update(UserAdminEntity entity);

  /// Remove um usuário pelo ID
  Future<Either<Failure, void>> delete(String id);
}
