import 'package:equatable/equatable.dart';

/// Candidatura de um estabelecimento pra virar parceiro Vita Clube -
/// objeto de negócio puro.
class PartnerApplicationEntity extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final String category;
  final String? address;
  final String? phone;
  final String email;
  final String status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const PartnerApplicationEntity({
    required this.id,
    this.userId,
    required this.name,
    required this.category,
    this.address,
    this.phone,
    required this.email,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        category,
        address,
        phone,
        email,
        status,
        createdAt,
        reviewedAt,
        rejectionReason,
      ];
}
