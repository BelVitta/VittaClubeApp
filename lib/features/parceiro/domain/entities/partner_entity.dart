import 'package:equatable/equatable.dart';

class PartnerEntity extends Equatable {
  final String id;
  final String profileId;
  final String name;
  final String category;
  final String code;
  final String address;
  final String phone;
  final String logoUrl;
  final bool isActive;

  /// Percentual vivo do acordo (publicado pelo financeiro).
  final double discountPercentage;

  const PartnerEntity({
    required this.id,
    required this.profileId,
    required this.name,
    required this.category,
    required this.code,
    required this.address,
    required this.phone,
    required this.logoUrl,
    required this.isActive,
    this.discountPercentage = 0,
  });

  PartnerEntity copyWith({
    String? name,
    String? category,
    String? address,
    String? phone,
    String? logoUrl,
    bool? isActive,
    double? discountPercentage,
  }) {
    return PartnerEntity(
      id: id,
      profileId: profileId,
      name: name ?? this.name,
      category: category ?? this.category,
      code: code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        category,
        code,
        address,
        phone,
        logoUrl,
        isActive,
        discountPercentage,
      ];
}
