import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/usecases/deactivate_dependent_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('deactivates dependent through repository contract', () async {
    final repository = MockDependentsRepository();
    final useCase = DeactivateDependentUseCase(repository);

    when(
      () => repository.deactivateDependent(
        holderUserId: 'holder-1',
        dependentId: 'dep-1',
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(
      const DeactivateDependentParams(
        holderUserId: 'holder-1',
        dependentId: 'dep-1',
      ),
    );

    expect(result, const Right(unit));
  });
}
