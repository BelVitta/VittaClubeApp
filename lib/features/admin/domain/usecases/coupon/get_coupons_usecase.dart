import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/coupon_entity.dart';
import '../../repositories/coupon_repository.dart';

class GetCouponsUseCase {
  final CouponRepository repository;
  GetCouponsUseCase(this.repository);
  Future<Either<Failure, List<CouponEntity>>> call() => repository.getAll();
}
