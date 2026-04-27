import '../../domain/entities/plan_admin_entity.dart';

/// Model de plano admin - DTO para serialização.
/// Estende PlanAdminEntity e adiciona métodos fromJson/toJson.
class PlanAdminModel extends PlanAdminEntity {
  const PlanAdminModel({
    required super.id,
    required super.name,
    required super.subscriptionType,
    required super.price,
    super.discountLabel,
    required super.benefits,
    required super.isActive,
  });

  /// Cria PlanAdminModel a partir de JSON
  factory PlanAdminModel.fromJson(Map<String, dynamic> json) {
    return PlanAdminModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subscriptionType: json['subscriptionType'] as String,
      price: (json['price'] as num).toDouble(),
      discountLabel: json['discountLabel'] as String?,
      benefits: List<String>.from(json['benefits']),
      isActive: json['isActive'] as bool,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subscriptionType': subscriptionType,
      'price': price,
      'discountLabel': discountLabel,
      'benefits': benefits,
      'isActive': isActive,
    };
  }

  /// Cria PlanAdminModel a partir de PlanAdminEntity
  factory PlanAdminModel.fromEntity(PlanAdminEntity entity) {
    return PlanAdminModel(
      id: entity.id,
      name: entity.name,
      subscriptionType: entity.subscriptionType,
      price: entity.price,
      discountLabel: entity.discountLabel,
      benefits: entity.benefits,
      isActive: entity.isActive,
    );
  }
}
