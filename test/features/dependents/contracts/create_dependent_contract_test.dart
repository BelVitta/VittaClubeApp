import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/core/services/clinic_settings_service.dart';
import 'package:vita_clube/features/dependents/domain/usecases/create_dependent_usecase.dart';

import '../../../helpers/test_helpers.dart';
import '../dependents_test_helpers.dart';

class MockClinicSettingsService extends Mock implements ClinicSettingsService {}

void main() {
  late MockDependentsRepository repository;
  late MockClinicSettingsService settings;
  late CreateDependentUseCase useCase;

  setUp(() {
    repository = MockDependentsRepository();
    settings = MockClinicSettingsService();
    useCase = CreateDependentUseCase(
      repository: repository,
      settingsService: settings,
    );
  });

  test('creates dependent when limit and CPF rules pass', () async {
    final dependent = makeDependent();
    when(() => settings.getMaxDependentsPerHolder()).thenAnswer((_) async => 2);
    when(
      () => repository.countActiveDependents(holderUserId: 'holder-1'),
    ).thenAnswer((_) async => const Right(1));
    when(() => repository.activeCpfExists('12345678909')).thenAnswer(
      (_) async => const Right(false),
    );
    when(
      () => repository.createDependent(
        holderUserId: 'holder-1',
        name: 'Maria Dependente',
        cpf: '12345678909',
        birthDate: DateTime(2014, 5, 10),
        relationship: 'Filha',
      ),
    ).thenAnswer((_) async => Right(dependent));

    final result = await useCase(
      CreateDependentParams(
        holderUserId: 'holder-1',
        name: 'Maria Dependente',
        cpf: '12345678909',
        birthDate: DateTime(2014, 5, 10),
        relationship: 'Filha',
      ),
    );

    expect(result, Right(dependent));
  });

  test('returns ValidationFailure when active dependent limit is reached',
      () async {
    when(() => settings.getMaxDependentsPerHolder()).thenAnswer((_) async => 2);
    when(
      () => repository.countActiveDependents(holderUserId: 'holder-1'),
    ).thenAnswer((_) async => const Right(2));

    final result = await useCase(
      CreateDependentParams(
        holderUserId: 'holder-1',
        name: 'Terceiro Dependente',
        cpf: '98765432100',
        birthDate: DateTime(2015),
        relationship: 'Filho',
      ),
    );

    expect(result.isLeft(), isTrue);
    expect(result.swap().getOrElse(() => const ServerFailure()),
        isA<ValidationFailure>());
  });
}
