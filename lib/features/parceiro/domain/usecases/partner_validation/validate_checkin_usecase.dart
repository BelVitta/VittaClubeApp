import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_validation_entity.dart';
import '../../repositories/partner_validation_repository.dart';

class ValidateCheckinUseCase {
  final PartnerValidationRepository repository;

  ValidateCheckinUseCase(this.repository);

  Future<Either<Failure, PartnerValidationEntity>> call({
    required String userId,
    required String token,
    required String partnerCode,
    required String serviceId,
  }) =>
      repository.validateCheckin(
        userId: userId,
        token: token,
        partnerCode: partnerCode,
        serviceId: serviceId,
      );
}
