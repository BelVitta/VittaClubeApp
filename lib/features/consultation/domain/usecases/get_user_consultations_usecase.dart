import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/consultation_entity.dart';
import '../repositories/consultation_repository.dart';

class GetUserConsultationsUseCase {
  final ConsultationRepository repository;

  GetUserConsultationsUseCase(this.repository);

  Future<Either<Failure, List<ConsultationEntity>>> call() =>
      repository.getForCurrentUser();
}
