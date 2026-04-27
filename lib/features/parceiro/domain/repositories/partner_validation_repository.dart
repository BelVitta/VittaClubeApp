import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/partner_validation_entity.dart';

abstract class PartnerValidationRepository {
  Future<Either<Failure, List<PartnerValidationEntity>>> getByPartnerId(String partnerId);
  Future<Either<Failure, PartnerValidationEntity>> validateCheckin({
    required String userId,
    required String token,
    required String partnerCode,
    required String serviceId,
  });
  Future<Either<Failure, String>> generateToken(String userId);
}
