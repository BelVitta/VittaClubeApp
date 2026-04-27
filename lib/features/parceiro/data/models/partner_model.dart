import '../../domain/entities/partner_entity.dart';

class PartnerModel extends PartnerEntity {
  const PartnerModel({
    required super.id,
    required super.profileId,
    required super.name,
    required super.category,
    required super.code,
    required super.address,
    required super.phone,
    required super.logoUrl,
    required super.isActive,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      code: json['code'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'category': category,
      'code': code,
      'address': address,
      'phone': phone,
      'logoUrl': logoUrl,
      'isActive': isActive,
    };
  }

  factory PartnerModel.fromEntity(PartnerEntity entity) {
    return PartnerModel(
      id: entity.id,
      profileId: entity.profileId,
      name: entity.name,
      category: entity.category,
      code: entity.code,
      address: entity.address,
      phone: entity.phone,
      logoUrl: entity.logoUrl,
      isActive: entity.isActive,
    );
  }
}
