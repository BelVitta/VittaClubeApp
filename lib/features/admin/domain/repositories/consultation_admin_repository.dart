import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/consultation_admin_entity.dart';

/// Interface do repositório de consultas no painel admin.
/// Define o contrato que a camada Data deve implementar.
abstract class ConsultationAdminRepository {
  /// Obtém todas as consultas
  Future<Either<Failure, List<ConsultationAdminEntity>>> getAll();

  /// Cria uma nova consulta
  Future<Either<Failure, ConsultationAdminEntity>> create(
      ConsultationAdminEntity entity);

  /// Atualiza uma consulta existente
  Future<Either<Failure, ConsultationAdminEntity>> update(
      ConsultationAdminEntity entity);

  /// Remove uma consulta pelo ID
  Future<Either<Failure, void>> delete(String id);
}
