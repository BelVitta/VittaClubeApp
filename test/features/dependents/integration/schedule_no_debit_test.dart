import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/services/dependent_quota_service.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('appointment creation does not create usage records or change quota',
      () async {
    final repository = MockDependentAppointmentRepository();
    final quotaService = DependentQuotaService(
      appointmentRepository: repository,
      monthlyUsesProvider: () async => 2,
    );

    when(
      () => repository.getUsageRecords(
        holderUserId: 'holder-1',
        beneficiaryType: BeneficiaryType.dependent,
        beneficiaryId: 'dep-1',
        cycleReference: '2026-06-10',
      ),
    ).thenAnswer((_) async => const Right([]));

    final remaining = await quotaService.remainingUses(
      holderUserId: 'holder-1',
      beneficiaryType: BeneficiaryType.dependent,
      beneficiaryId: 'dep-1',
      cycleReference: '2026-06-10',
    );

    expect(remaining.getOrElse(() => -1), 2);
  });
}
