import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/professional_entity.dart';
import '../repositories/professionals_repository.dart';

class GetActiveProfessionalsUseCase {
  final ProfessionalsRepository repository;

  GetActiveProfessionalsUseCase(this.repository);

  Future<Either<Failure, List<ProfessionalEntity>>> call() =>
      repository.getActiveProfessionals();
}
