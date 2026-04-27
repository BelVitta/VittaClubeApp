import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_service_entity.dart';
import '../../repositories/partner_service_repository.dart';

class UpdatePartnerServiceUseCase {
  final PartnerServiceRepository repository;

  UpdatePartnerServiceUseCase(this.repository);

  Future<Either<Failure, PartnerServiceEntity>> call(PartnerServiceEntity entity) =>
      repository.update(entity);
}
