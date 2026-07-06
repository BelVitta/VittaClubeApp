import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/repositories/qr_validation_repository.dart';
import 'package:vita_clube/features/dependents/domain/usecases/validate_dependent_qr_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('replay returns replay decision without new debit', () async {
    final repository = MockQrValidationRepository();
    final useCase = ValidateDependentQrUseCase(repository);
    when(
      () => repository.validateQr(
          qrToken: 'used', actorUserId: 'admin', establishmentId: null),
    ).thenAnswer(
      (_) async => const Right(
        QrValidationResult(
          decision: QrValidationDecision.replay,
          message: 'QR ja utilizado.',
        ),
      ),
    );

    final result = await useCase(
      const ValidateDependentQrParams(qrToken: 'used', actorUserId: 'admin'),
    );

    expect(result.getOrElse(() => throw StateError('missing')).decision,
        QrValidationDecision.replay);
  });
}
