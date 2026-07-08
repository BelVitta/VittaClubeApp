import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/core/services/clinic_settings_service.dart';
import 'package:vita_clube/features/dependents/domain/usecases/create_dependent_usecase.dart';

import '../../../helpers/test_helpers.dart';

class MockClinicSettingsService extends Mock implements ClinicSettingsService {}

void main() {
  test('rejects CPF already used by another active dependent', () async {
    final repository = MockDependentsRepository();
    final settings = MockClinicSettingsService();
    final useCase = CreateDependentUseCase(
      repository: repository,
      settingsService: settings,
    );

    when(() => settings.getMaxDependentsPerHolder()).thenAnswer((_) async => 2);
    when(
      () => repository.countActiveDependents(holderUserId: 'holder-2'),
    ).thenAnswer((_) async => const Right(0));
    when(() => repository.activeCpfExists('12345678909')).thenAnswer(
      (_) async => const Right(true),
    );

    final result = await useCase(
      CreateDependentParams(
        holderUserId: 'holder-2',
        name: 'Dependente Duplicado',
        cpf: '12345678909',
        birthDate: DateTime(2014, 5, 10),
        relationship: 'Filha',
      ),
    );

    expect(result.isLeft(), isTrue);
    expect(result.swap().getOrElse(() => const ServerFailure()),
        isA<ValidationFailure>());
  });
}
