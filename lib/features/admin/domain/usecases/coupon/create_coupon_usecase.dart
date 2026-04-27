import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/coupon_entity.dart';
import '../../repositories/coupon_repository.dart';

class CreateCouponUseCase {
  final CouponRepository repository;
  CreateCouponUseCase(this.repository);
  Future<Either<Failure, CouponEntity>> call(CouponEntity entity) =>
      repository.create(entity);
}
