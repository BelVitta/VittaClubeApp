import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coupon_entity.dart';

/// Interface do repositório de cupons de desconto.
/// Define o contrato que a camada Data deve implementar.
abstract class CouponRepository {
  /// Obtém todos os cupons
  Future<Either<Failure, List<CouponEntity>>> getAll();

  /// Cria um novo cupom
  Future<Either<Failure, CouponEntity>> create(CouponEntity entity);

  /// Atualiza um cupom existente
  Future<Either<Failure, CouponEntity>> update(CouponEntity entity);

  /// Remove um cupom pelo ID
  Future<Either<Failure, void>> delete(String id);
}
