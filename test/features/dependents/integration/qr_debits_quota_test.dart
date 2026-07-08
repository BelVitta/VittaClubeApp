import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/repositories/qr_validation_repository.dart';
import 'package:vita_clube/features/dependents/domain/usecases/validate_dependent_qr_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('approved QR validation returns decremented remaining quota', () async {
    final repository = MockQrValidationRepository();
    final useCase = ValidateDependentQrUseCase(repository);
    when(
      () => repository.validateQr(
        qrToken: 'token',
        actorUserId: 'admin',
        establishmentId: null,
      ),
    ).thenAnswer(
      (_) async => const Right(
        QrValidationResult(
          decision: QrValidationDecision.approved,
          message: 'Uso validado.',
          remainingUses: 1,
        ),
      ),
    );

    final result = await useCase(
      const ValidateDependentQrParams(qrToken: 'token', actorUserId: 'admin'),
    );

    expect(
        result.getOrElse(() => throw StateError('missing')).remainingUses, 1);
  });
}
