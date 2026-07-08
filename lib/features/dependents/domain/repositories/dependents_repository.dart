import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dependent_entity.dart';
import '../entities/dependent_enums.dart';

abstract class DependentsRepository {
  Future<Either<Failure, DependentEntity>> createDependent({
    required String holderUserId,
    required String name,
    required String cpf,
    required DateTime birthDate,
    required String relationship,
  });

  Future<Either<Failure, List<DependentEntity>>> getDependents({
    required String holderUserId,
    DependentStatus? status,
  });

  Future<Either<Failure, Unit>> deactivateDependent({
    required String holderUserId,
    required String dependentId,
  });

  Future<Either<Failure, int>> countActiveDependents({
    required String holderUserId,
  });

  Future<Either<Failure, bool>> activeCpfExists(String cpf);
}
