import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/core/services/clinic_settings_service.dart';
import 'package:vita_clube/features/dependents/domain/usecases/create_dependent_usecase.dart';

import '../../../helpers/test_helpers.dart';

class MockClinicSettingsService extends Mock implements ClinicSettingsService {}

void main() {
  test('blocks third active dependent when configured limit is 2', () async {
    final repository = MockDependentsRepository();
    final settings = MockClinicSettingsService();
    final useCase = CreateDependentUseCase(
      repository: repository,
      settingsService: settings,
    );

    when(() => settings.getMaxDependentsPerHolder()).thenAnswer((_) async => 2);
    when(
      () => repository.countActiveDependents(holderUserId: 'holder-1'),
    ).thenAnswer((_) async => const Right(2));

    final result = await useCase(
      CreateDependentParams(
        holderUserId: 'holder-1',
        name: 'Terceiro',
        cpf: '11122233344',
        birthDate: DateTime(2016),
        relationship: 'Filho',
      ),
    );

    expect(result.isLeft(), isTrue);
    expect(result.swap().getOrElse(() => const ServerFailure()),
        isA<ValidationFailure>());
  });
}
