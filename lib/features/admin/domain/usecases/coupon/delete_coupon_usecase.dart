import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/coupon_repository.dart';

class DeleteCouponUseCase {
  final CouponRepository repository;
  DeleteCouponUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
