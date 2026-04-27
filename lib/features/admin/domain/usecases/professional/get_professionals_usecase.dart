import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/professional_entity.dart';
import '../../repositories/professional_repository.dart';

class GetProfessionalsUseCase {
  final ProfessionalRepository repository;

  GetProfessionalsUseCase(this.repository);

  Future<Either<Failure, List<ProfessionalEntity>>> call() =>
      repository.getAll();
}
