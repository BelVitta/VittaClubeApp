import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_service_entity.dart';
import '../../repositories/partner_service_repository.dart';

class CreatePartnerServiceUseCase {
  final PartnerServiceRepository repository;

  CreatePartnerServiceUseCase(this.repository);

  Future<Either<Failure, PartnerServiceEntity>> call(PartnerServiceEntity entity) =>
      repository.create(entity);
}
