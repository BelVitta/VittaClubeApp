import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/services/dependent_quota_service.dart';
import 'package:vita_clube/features/dependents/domain/usecases/get_dependents_usecase.dart';

import '../../../helpers/test_helpers.dart';
import '../dependents_test_helpers.dart';

void main() {
  test('lists active dependents with remaining quota calculated', () async {
    final repository = MockDependentsRepository();
    final appointmentRepository = MockDependentAppointmentRepository();
    final quotaService = DependentQuotaService(
      appointmentRepository: appointmentRepository,
      monthlyUsesProvider: () async => 2,
    );
    final useCase = GetDependentsUseCase(
      repository: repository,
      quotaService: quotaService,
    );

    when(
      () => repository.getDependents(
        holderUserId: 'holder-1',
        status: DependentStatus.active,
      ),
    ).thenAnswer((_) async => Right([makeDependent()]));
    when(
      () => appointmentRepository.getUsageRecords(
        holderUserId: 'holder-1',
        beneficiaryType: BeneficiaryType.dependent,
        beneficiaryId: 'dep-1',
        cycleReference: '2026-06-10',
      ),
    ).thenAnswer((_) async => Right([makeUsageRecord()]));

    final result = await useCase(
      GetDependentsParams(
        holderUserId: 'holder-1',
        cycleReference: '2026-06-10',
      ),
    );

    final items = result.getOrElse(() => []);
    expect(items.single.remainingUses, 1);
  });
}
