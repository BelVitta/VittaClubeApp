import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/services/dependent_quota_service.dart';

import '../../../helpers/test_helpers.dart';
import '../dependents_test_helpers.dart';

void main() {
  test(
      'remaining uses ignores unvalidated appointments and counts usage records',
      () async {
    final appointmentRepository = MockDependentAppointmentRepository();
    final service = DependentQuotaService(
      appointmentRepository: appointmentRepository,
      monthlyUsesProvider: () async => 2,
    );

    when(
      () => appointmentRepository.getUsageRecords(
        holderUserId: 'holder-1',
        beneficiaryType: BeneficiaryType.dependent,
        beneficiaryId: 'dep-1',
        cycleReference: '2026-06-10',
      ),
    ).thenAnswer((_) async => Right([makeUsageRecord()]));

    final remaining = await service.remainingUses(
      holderUserId: 'holder-1',
      beneficiaryType: BeneficiaryType.dependent,
      beneficiaryId: 'dep-1',
      cycleReference: '2026-06-10',
    );

    expect(remaining.getOrElse(() => -1), 1);
  });
}
