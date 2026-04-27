import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_validation_entity.dart';
import '../../repositories/partner_validation_repository.dart';

class GetPartnerValidationsUseCase {
  final PartnerValidationRepository repository;

  GetPartnerValidationsUseCase(this.repository);

  Future<Either<Failure, List<PartnerValidationEntity>>> call(String partnerId) =>
      repository.getByPartnerId(partnerId);
}
