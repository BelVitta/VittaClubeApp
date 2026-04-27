import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/professional_entity.dart';
import '../../repositories/professional_repository.dart';

class CreateProfessionalUseCase {
  final ProfessionalRepository repository;

  CreateProfessionalUseCase(this.repository);

  Future<Either<Failure, ProfessionalEntity>> call(
          ProfessionalEntity entity) =>
      repository.create(entity);
}
