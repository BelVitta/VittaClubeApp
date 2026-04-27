import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/partner_entity.dart';

abstract class PartnerRepository {
  Future<Either<Failure, List<PartnerEntity>>> getAll();
  Future<Either<Failure, PartnerEntity>> getByProfileId(String profileId);
  Future<Either<Failure, PartnerEntity>> update(PartnerEntity entity);
  Future<Either<Failure, PartnerEntity>> regenerateCode(String partnerId);
}
