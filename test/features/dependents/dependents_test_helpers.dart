import 'package:vita_clube/features/dependents/domain/entities/dependent_entity.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/entities/usage_record_entity.dart';

DependentEntity makeDependent({
  String id = 'dep-1',
  String holderUserId = 'holder-1',
  String name = 'Maria Dependente',
  String cpf = '12345678909',
  DateTime? birthDate,
  String relationship = 'Filha',
  DependentStatus status = DependentStatus.active,
  DateTime? createdAt,
}) {
  return DependentEntity(
    id: id,
    holderUserId: holderUserId,
    name: name,
    cpf: cpf,
    birthDate: birthDate ?? DateTime(2014, 5, 10),
    relationship: relationship,
    status: status,
    createdAt: createdAt ?? DateTime(2026),
  );
}

UsageRecordEntity makeUsageRecord({
  String id = 'usage-1',
  String appointmentId = 'appointment-1',
  String holderUserId = 'holder-1',
  BeneficiaryType beneficiaryType = BeneficiaryType.dependent,
  String beneficiaryId = 'dep-1',
  String cycleReference = '2026-06-15',
  DateTime? usedAt,
}) {
  return UsageRecordEntity(
    id: id,
    appointmentId: appointmentId,
    holderUserId: holderUserId,
    beneficiaryType: beneficiaryType,
    beneficiaryId: beneficiaryId,
    cycleReference: cycleReference,
    usedAt: usedAt ?? DateTime(2026, 6, 20, 10),
  );
}
