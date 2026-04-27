import 'package:equatable/equatable.dart';

/// Entidade de cupom de desconto - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class CouponEntity extends Equatable {
  final String id;
  final String code;
  final String description;
  final double discountPercentage;
  final DateTime expiryDate;
  final int usageLimit;
  final int usedCount;
  final bool isActive;

  const CouponEntity({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercentage,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        code,
        description,
        discountPercentage,
        expiryDate,
        usageLimit,
        usedCount,
        isActive,
      ];
}
