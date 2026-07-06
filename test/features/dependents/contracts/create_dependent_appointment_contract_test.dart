import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_appointment_entity.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/services/qr_token_service.dart';
import 'package:vita_clube/features/dependents/domain/usecases/create_dependent_appointment_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test(
      'creates scheduled appointment for selected dependent without quota debit',
      () async {
    final repository = MockDependentAppointmentRepository();
    final tokenService = QrTokenService(secretProvider: () async => 'secret');
    final useCase = CreateDependentAppointmentUseCase(
      repository: repository,
      qrTokenService: tokenService,
    );
    final scheduledAt = DateTime(2026, 6, 20, 10);

    when(
      () => repository.createAppointment(
        holderUserId: 'holder-1',
        beneficiaryType: BeneficiaryType.dependent,
        beneficiaryId: 'dep-1',
        establishmentId: 'clinic-1',
        scheduledAt: scheduledAt,
        qrToken: any(named: 'qrToken'),
      ),
    ).thenAnswer(
      (_) async => Right(
        DependentAppointmentEntity(
          id: 'appointment-1',
          holderUserId: 'holder-1',
          beneficiaryType: BeneficiaryType.dependent,
          beneficiaryId: 'dep-1',
          establishmentId: 'clinic-1',
          scheduledAt: scheduledAt,
          status: DependentAppointmentStatus.scheduled,
          qrToken: 'opaque.signature',
          createdAt: DateTime(2026, 6, 1),
        ),
      ),
    );

    final result = await useCase(
      CreateDependentAppointmentParams(
        holderUserId: 'holder-1',
        beneficiaryType: BeneficiaryType.dependent,
        beneficiaryId: 'dep-1',
        establishmentId: 'clinic-1',
        scheduledAt: scheduledAt,
      ),
    );

    expect(result.isRight(), isTrue);
  });
}
