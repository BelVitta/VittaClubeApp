import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/consultation_admin_entity.dart';
import '../../repositories/consultation_admin_repository.dart';

class GetConsultationsUseCase {
  final ConsultationAdminRepository repository;

  GetConsultationsUseCase(this.repository);

  Future<Either<Failure, List<ConsultationAdminEntity>>> call() =>
      repository.getAll();
}
