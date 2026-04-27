import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_service_entity.dart';
import '../../repositories/partner_service_repository.dart';

class GetAllActiveServicesUseCase {
  final PartnerServiceRepository repository;

  GetAllActiveServicesUseCase(this.repository);

  Future<Either<Failure, List<PartnerServiceEntity>>> call() =>
      repository.getAllActive();
}
