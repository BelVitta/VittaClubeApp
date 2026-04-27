import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/professional_entity.dart';

/// Interface do repositório de profissionais no painel admin.
/// Define o contrato que a camada Data deve implementar.
abstract class ProfessionalRepository {
  /// Obtém todos os profissionais
  Future<Either<Failure, List<ProfessionalEntity>>> getAll();

  /// Cria um novo profissional
  Future<Either<Failure, ProfessionalEntity>> create(ProfessionalEntity entity);

  /// Atualiza um profissional existente
  Future<Either<Failure, ProfessionalEntity>> update(ProfessionalEntity entity);

  /// Remove um profissional pelo ID
  Future<Either<Failure, void>> delete(String id);
}
