import '../../domain/entities/coupon_entity.dart';

/// Model de cupom de desconto - DTO para serialização.
/// Estende CouponEntity e adiciona métodos fromJson/toJson.
class CouponModel extends CouponEntity {
  const CouponModel({
    required super.id,
    required super.code,
    required super.description,
    required super.discountPercentage,
    required super.expiryDate,
    required super.usageLimit,
    required super.usedCount,
    required super.isActive,
  });

  /// Cria CouponModel a partir de JSON
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      usageLimit: json['usageLimit'] as int,
      usedCount: json['usedCount'] as int,
      isActive: json['isActive'] as bool,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discountPercentage': discountPercentage,
      'expiryDate': expiryDate.toIso8601String(),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
    };
  }

  /// Cria CouponModel a partir de CouponEntity
  factory CouponModel.fromEntity(CouponEntity entity) {
    return CouponModel(
      id: entity.id,
      code: entity.code,
      description: entity.description,
      discountPercentage: entity.discountPercentage,
      expiryDate: entity.expiryDate,
      usageLimit: entity.usageLimit,
      usedCount: entity.usedCount,
      isActive: entity.isActive,
    );
  }
}
