import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/consultation_admin_entity.dart';
import '../../repositories/consultation_admin_repository.dart';

class CreateConsultationUseCase {
  final ConsultationAdminRepository repository;

  CreateConsultationUseCase(this.repository);

  Future<Either<Failure, ConsultationAdminEntity>> call(
          ConsultationAdminEntity entity) =>
      repository.create(entity);
}
