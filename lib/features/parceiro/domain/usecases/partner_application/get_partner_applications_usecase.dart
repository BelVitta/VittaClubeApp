import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_application_entity.dart';
import '../../repositories/partner_application_repository.dart';

class GetPartnerApplicationsUseCase {
  final PartnerApplicationRepository repository;

  GetPartnerApplicationsUseCase(this.repository);

  Future<Either<Failure, List<PartnerApplicationEntity>>> call() =>
      repository.getAll();
}
