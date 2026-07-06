import '../../domain/entities/dependent_appointment_entity.dart';
import '../../domain/entities/dependent_entity.dart';
import '../../domain/entities/dependent_enums.dart';
import '../../domain/entities/usage_record_entity.dart';

class DependentModel extends DependentEntity {
  const DependentModel({
    required super.id,
    required super.holderUserId,
    required super.name,
    required super.cpf,
    required super.birthDate,
    required super.relationship,
    required super.status,
    required super.createdAt,
  });

  factory DependentModel.fromJson(Map<String, dynamic> json) {
    return DependentModel(
      id: json['id'] as String,
      holderUserId: json['holder_user_id'] as String,
      name: json['name'] as String,
      cpf: json['cpf'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      relationship: json['relationship'] as String,
      status: DependentStatus.fromDb(json['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'holder_user_id': holderUserId,
      'name': name,
      'cpf': cpf,
      'birth_date': birthDate.toIso8601String().split('T').first,
      'relationship': relationship,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DependentAppointmentModel extends DependentAppointmentEntity {
  const DependentAppointmentModel({
    required super.id,
    required super.holderUserId,
    required super.beneficiaryType,
    super.beneficiaryId,
    super.establishmentId,
    required super.scheduledAt,
    required super.status,
    required super.qrToken,
    required super.createdAt,
  });

  factory DependentAppointmentModel.fromJson(Map<String, dynamic> json) {
    return DependentAppointmentModel(
      id: json['id'] as String,
      holderUserId: json['holder_user_id'] as String,
      beneficiaryType:
          BeneficiaryType.fromDb(json['beneficiary_type'] as String),
      beneficiaryId: json['beneficiary_id'] as String?,
      establishmentId: json['establishment_id'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: DependentAppointmentStatus.fromDb(
        json['status'] as String? ?? 'agendado',
      ),
      qrToken: json['qr_token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'holder_user_id': holderUserId,
      'beneficiary_type': beneficiaryType.dbValue,
      'beneficiary_id': beneficiaryId,
      'establishment_id': establishmentId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.dbValue,
      'qr_token': qrToken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UsageRecordModel extends UsageRecordEntity {
  const UsageRecordModel({
    required super.id,
    required super.appointmentId,
    required super.holderUserId,
    required super.beneficiaryType,
    super.beneficiaryId,
    required super.cycleReference,
    required super.usedAt,
  });

  factory UsageRecordModel.fromJson(Map<String, dynamic> json) {
    return UsageRecordModel(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      holderUserId: json['holder_user_id'] as String,
      beneficiaryType:
          BeneficiaryType.fromDb(json['beneficiary_type'] as String),
      beneficiaryId: json['beneficiary_id'] as String?,
      cycleReference: json['cycle_reference'] as String,
      usedAt: DateTime.parse(json['used_at'] as String),
    );
  }
}
