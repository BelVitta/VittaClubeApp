import '../../domain/entities/partner_service_entity.dart';

class PartnerServiceModel extends PartnerServiceEntity {
  const PartnerServiceModel({
    required super.id,
    required super.partnerId,
    required super.name,
    required super.description,
    required super.originalPrice,
    required super.discountedPrice,
    required super.isActive,
  });

  factory PartnerServiceModel.fromJson(Map<String, dynamic> json) {
    return PartnerServiceModel(
      id: json['id'] as String,
      partnerId: json['partnerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      originalPrice: (json['originalPrice'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'name': name,
      'description': description,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'isActive': isActive,
    };
  }

  factory PartnerServiceModel.fromEntity(PartnerServiceEntity entity) {
    return PartnerServiceModel(
      id: entity.id,
      partnerId: entity.partnerId,
      name: entity.name,
      description: entity.description,
      originalPrice: entity.originalPrice,
      discountedPrice: entity.discountedPrice,
      isActive: entity.isActive,
    );
  }
}
