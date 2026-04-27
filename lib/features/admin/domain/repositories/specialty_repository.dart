import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/specialty_entity.dart';

/// Interface do repositório de especialidades.
/// Define o contrato que a camada Data deve implementar.
abstract class SpecialtyRepository {
  /// Obtém todas as especialidades
  Future<Either<Failure, List<SpecialtyEntity>>> getAll();

  /// Cria uma nova especialidade
  Future<Either<Failure, SpecialtyEntity>> create(SpecialtyEntity entity);

  /// Atualiza uma especialidade existente
  Future<Either<Failure, SpecialtyEntity>> update(SpecialtyEntity entity);

  /// Remove uma especialidade pelo ID
  Future<Either<Failure, void>> delete(String id);
}
