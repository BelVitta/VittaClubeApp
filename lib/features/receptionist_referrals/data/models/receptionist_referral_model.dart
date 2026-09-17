import '../../domain/entities/receptionist_referral_entity.dart';

/// Model de indicação de recepcionista - DTO para serialização.
class ReceptionistReferralModel extends ReceptionistReferralEntity {
  const ReceptionistReferralModel({
    required super.id,
    required super.receptionistId,
    required super.receptionistName,
    required super.referralCode,
    required super.referredUserId,
    required super.referredUserName,
    required super.referredUserEmail,
    required super.referredMemberSince,
    required super.status,
    super.convertedAt,
    super.planNameAtConversion,
    super.planPriceAtConversion,
    super.monthReference,
    required super.createdAt,
  });

  factory ReceptionistReferralModel.fromRow(Map<String, dynamic> row) {
    final receptionist = row['receptionist'] as Map<String, dynamic>?;
    final referred = row['referred'] as Map<String, dynamic>?;
    final plan = row['plan'] as Map<String, dynamic>?;

    return ReceptionistReferralModel(
      id: row['id'] as String,
      receptionistId: row['receptionist_id'] as String,
      receptionistName: receptionist?['name'] as String? ?? '',
      referralCode: row['referral_code'] as String,
      referredUserId: row['referred_user_id'] as String,
      referredUserName: referred?['name'] as String? ?? '',
      referredUserEmail: referred?['email'] as String? ?? '',
      referredMemberSince: DateTime.parse(referred?['member_since'] as String),
      status: ReceptionistReferralStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => ReceptionistReferralStatus.pending,
      ),
      convertedAt: row['converted_at'] != null
          ? DateTime.parse(row['converted_at'] as String)
          : null,
      planNameAtConversion: plan?['name'] as String?,
      planPriceAtConversion:
          (row['plan_price_at_conversion'] as num?)?.toDouble(),
      monthReference: row['month_reference'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
