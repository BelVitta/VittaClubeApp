import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dependent_enums.dart';
import '../repositories/dependent_appointment_repository.dart';

typedef MonthlyUsesProvider = Future<int> Function();

class DependentQuotaService {
  final DependentAppointmentRepository appointmentRepository;
  final MonthlyUsesProvider monthlyUsesProvider;

  const DependentQuotaService({
    required this.appointmentRepository,
    required this.monthlyUsesProvider,
  });

  Future<Either<Failure, int>> remainingUses({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    required String cycleReference,
  }) async {
    final limit = await monthlyUsesProvider();
    final usageResult = await appointmentRepository.getUsageRecords(
      holderUserId: holderUserId,
      beneficiaryType: beneficiaryType,
      beneficiaryId: beneficiaryId,
      cycleReference: cycleReference,
    );

    return usageResult.map((records) {
      final remaining = limit - records.length;
      return remaining < 0 ? 0 : remaining;
    });
  }
}
