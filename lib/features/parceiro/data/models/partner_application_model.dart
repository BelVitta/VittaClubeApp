import '../../domain/entities/partner_application_entity.dart';

class PartnerApplicationModel extends PartnerApplicationEntity {
  const PartnerApplicationModel({
    required super.id,
    super.userId,
    required super.name,
    required super.category,
    super.address,
    super.phone,
    required super.email,
    super.status,
    required super.createdAt,
    super.reviewedAt,
    super.rejectionReason,
  });

  factory PartnerApplicationModel.fromJson(Map<String, dynamic> json) {
    return PartnerApplicationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      category: json['category'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
