import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/partner_service_entity.dart';

abstract class PartnerServiceRepository {
  Future<Either<Failure, List<PartnerServiceEntity>>> getByPartnerId(String partnerId);
  Future<Either<Failure, List<PartnerServiceEntity>>> getAllActive();
  Future<Either<Failure, PartnerServiceEntity>> create(PartnerServiceEntity entity);
  Future<Either<Failure, PartnerServiceEntity>> update(PartnerServiceEntity entity);
  Future<Either<Failure, void>> delete(String id);
}
