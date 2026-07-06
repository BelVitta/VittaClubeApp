import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/features/dependents/domain/usecases/cancel_dependent_appointment_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('cancel appointment delegates without touching usage records', () async {
    final repository = MockDependentAppointmentRepository();
    final useCase = CancelDependentAppointmentUseCase(repository);

    when(
      () => repository.cancelAppointment(
        holderUserId: 'holder-1',
        appointmentId: 'appointment-1',
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(
      const CancelDependentAppointmentParams(
        holderUserId: 'holder-1',
        appointmentId: 'appointment-1',
      ),
    );

    expect(result, const Right(unit));
  });
}
