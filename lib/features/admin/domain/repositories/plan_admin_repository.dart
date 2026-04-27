import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plan_admin_entity.dart';

/// Interface do repositório de planos no painel admin.
/// Define o contrato que a camada Data deve implementar.
abstract class PlanAdminRepository {
  /// Obtém todos os planos
  Future<Either<Failure, List<PlanAdminEntity>>> getAll();

  /// Cria um novo plano
  Future<Either<Failure, PlanAdminEntity>> create(PlanAdminEntity entity);

  /// Atualiza um plano existente
  Future<Either<Failure, PlanAdminEntity>> update(PlanAdminEntity entity);

  /// Remove um plano pelo ID
  Future<Either<Failure, void>> delete(String id);
}
