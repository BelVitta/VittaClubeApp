import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/repositories/qr_validation_repository.dart';
import 'package:vita_clube/features/dependents/domain/usecases/validate_dependent_qr_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('two concurrent validations with one quota allow only one approval',
      () async {
    final repository = MockQrValidationRepository();
    final useCase = ValidateDependentQrUseCase(repository);
    var calls = 0;
    when(
      () => repository.validateQr(
        qrToken: 'token',
        actorUserId: 'admin',
        establishmentId: null,
      ),
    ).thenAnswer((_) async {
      calls++;
      return Right(
        QrValidationResult(
          decision: calls == 1
              ? QrValidationDecision.approved
              : QrValidationDecision.quotaExhausted,
          message: calls == 1 ? 'Uso validado.' : 'Cota esgotada.',
        ),
      );
    });

    final results = await Future.wait([
      useCase(const ValidateDependentQrParams(
          qrToken: 'token', actorUserId: 'admin')),
      useCase(const ValidateDependentQrParams(
          qrToken: 'token', actorUserId: 'admin')),
    ]);

    final decisions = results
        .map((r) => r.getOrElse(() => throw StateError('missing')).decision);
    expect(decisions.where((d) => d == QrValidationDecision.approved),
        hasLength(1));
  });
}
