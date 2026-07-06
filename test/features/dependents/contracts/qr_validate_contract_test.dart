import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/repositories/qr_validation_repository.dart';
import 'package:vita_clube/features/dependents/domain/usecases/validate_dependent_qr_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('validates QR through repository contract', () async {
    final repository = MockQrValidationRepository();
    final useCase = ValidateDependentQrUseCase(repository);

    when(
      () => repository.validateQr(
        qrToken: 'opaque.signature',
        actorUserId: 'admin-1',
        establishmentId: 'clinic-1',
      ),
    ).thenAnswer(
      (_) async => const Right(
        QrValidationResult(
          decision: QrValidationDecision.approved,
          message: 'Uso validado.',
          appointmentId: 'appointment-1',
          usageRecordId: 'usage-1',
          remainingUses: 1,
        ),
      ),
    );

    final result = await useCase(
      const ValidateDependentQrParams(
        qrToken: 'opaque.signature',
        actorUserId: 'admin-1',
        establishmentId: 'clinic-1',
      ),
    );

    expect(
        result.getOrElse(() => throw StateError('missing')).isApproved, true);
  });
}
