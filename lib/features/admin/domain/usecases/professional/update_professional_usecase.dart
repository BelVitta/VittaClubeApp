import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/professional_entity.dart';
import '../../repositories/professional_repository.dart';

class UpdateProfessionalUseCase {
  final ProfessionalRepository repository;

  UpdateProfessionalUseCase(this.repository);

  Future<Either<Failure, ProfessionalEntity>> call(
          ProfessionalEntity entity) =>
      repository.update(entity);
}
