import '../../domain/entities/dependent_enums.dart';

abstract class DependentsDataSource {
  Future<Map<String, dynamic>> createDependent({
    required String holderUserId,
    required String name,
    required String cpf,
    required DateTime birthDate,
    required String relationship,
  });

  Future<List<Map<String, dynamic>>> getDependents({
    required String holderUserId,
    String? status,
  });

  Future<void> deactivateDependent({
    required String holderUserId,
    required String dependentId,
  });

  Future<int> countActiveDependents({required String holderUserId});

  Future<bool> activeCpfExists(String cpf);

  /// Admin-only (RLS): todos os dependentes `pending` de todos os titulares,
  /// com nome/e-mail do titular anexados (`holder_name`/`holder_email`).
  Future<List<Map<String, dynamic>>> getPendingDependents();

  /// Admin-only (RLS + trigger): aprova (`active`) ou rejeita (`inactive`)
  /// um cadastro pendente.
  Future<void> updateDependentStatus({
    required String dependentId,
    required String status,
    String? rejectionReason,
  });
}

abstract class DependentAppointmentDataSource {
  Future<Map<String, dynamic>> createAppointment({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    String? establishmentId,
    required DateTime scheduledAt,
    required String qrToken,
  });

  Future<void> cancelAppointment({
    required String holderUserId,
    required String appointmentId,
  });

  Future<List<Map<String, dynamic>>> getUsageRecords({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    required String cycleReference,
  });
}

abstract class QrValidationDataSource {
  Future<Map<String, dynamic>> validateQr({
    required String qrToken,
    required String actorUserId,
    String? establishmentId,
  });
}

abstract class MemberQrValidationDataSource {
  /// [identifier] pode ser UUID do membro ou código curto de 8 dígitos.
  Future<Map<String, dynamic>> validateMemberQr({
    required String identifier,
    required String actorUserId,
  });
}
