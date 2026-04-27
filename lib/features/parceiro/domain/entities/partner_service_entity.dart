import 'package:equatable/equatable.dart';

class PartnerServiceEntity extends Equatable {
  final String id;
  final String partnerId;
  final String name;
  final String description;
  final double originalPrice;
  final double discountedPrice;
  final bool isActive;

  const PartnerServiceEntity({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        partnerId,
        name,
        description,
        originalPrice,
        discountedPrice,
        isActive,
      ];
}
