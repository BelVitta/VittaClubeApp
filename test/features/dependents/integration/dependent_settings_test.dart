import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/services/clinic_settings_service.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/services/dependent_quota_service.dart';
import 'package:vita_clube/features/dependents/domain/usecases/create_dependent_usecase.dart';

import '../../../helpers/test_helpers.dart';
import '../dependents_test_helpers.dart';

class MockClinicSettingsService extends Mock implements ClinicSettingsService {}

void main() {
  test('configured max dependents changes create limit behavior', () async {
    final repository = MockDependentsRepository();
    final settings = MockClinicSettingsService();
    final useCase = CreateDependentUseCase(
      repository: repository,
      settingsService: settings,
    );

    when(() => settings.getMaxDependentsPerHolder()).thenAnswer((_) async => 3);
    when(
      () => repository.countActiveDependents(holderUserId: 'holder-1'),
    ).thenAnswer((_) async => const Right(2));
    when(() => repository.activeCpfExists('11122233344'))
        .thenAnswer((_) async => const Right(false));
    when(
      () => repository.createDependent(
        holderUserId: 'holder-1',
        name: 'Terceiro',
        cpf: '11122233344',
        birthDate: DateTime(2016),
        relationship: 'Filho',
      ),
    ).thenAnswer((_) async => Right(makeDependent(id: 'dep-3')));

    final result = await useCase(
      CreateDependentParams(
        holderUserId: 'holder-1',
        name: 'Terceiro',
        cpf: '11122233344',
        birthDate: DateTime(2016),
        relationship: 'Filho',
      ),
    );

    expect(result.isRight(), isTrue);
  });

  test('configured monthly uses changes remaining quota calculation', () async {
    final appointmentRepository = MockDependentAppointmentRepository();
    final service = DependentQuotaService(
      appointmentRepository: appointmentRepository,
      monthlyUsesProvider: () async => 4,
    );

    when(
      () => appointmentRepository.getUsageRecords(
        holderUserId: 'holder-1',
        beneficiaryType: BeneficiaryType.dependent,
        beneficiaryId: 'dep-1',
        cycleReference: '2026-06-10',
      ),
    ).thenAnswer(
      (_) async => Right([
        makeUsageRecord(id: 'usage-1'),
        makeUsageRecord(id: 'usage-2'),
      ]),
    );

    final result = await service.remainingUses(
      holderUserId: 'holder-1',
      beneficiaryType: BeneficiaryType.dependent,
      beneficiaryId: 'dep-1',
      cycleReference: '2026-06-10',
    );

    expect(result.getOrElse(() => -1), 2);
  });
}
