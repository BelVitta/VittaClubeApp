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
  });

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
      ];
}
