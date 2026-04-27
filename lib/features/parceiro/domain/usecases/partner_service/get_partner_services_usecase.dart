import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_service_entity.dart';
import '../../repositories/partner_service_repository.dart';

class GetPartnerServicesUseCase {
  final PartnerServiceRepository repository;

  GetPartnerServicesUseCase(this.repository);

  Future<Either<Failure, List<PartnerServiceEntity>>> call(String partnerId) =>
      repository.getByPartnerId(partnerId);
}
