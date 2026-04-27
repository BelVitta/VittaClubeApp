import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/coupon_entity.dart';
import '../../repositories/coupon_repository.dart';

class UpdateCouponUseCase {
  final CouponRepository repository;
  UpdateCouponUseCase(this.repository);
  Future<Either<Failure, CouponEntity>> call(CouponEntity entity) =>
      repository.update(entity);
}
