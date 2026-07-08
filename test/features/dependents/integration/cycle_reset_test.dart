import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/dependents/domain/services/dependent_cycle_service.dart';

void main() {
  test('cycle reset follows holder adhesion date', () {
    final service = DependentCycleService();

    expect(
      service.currentCycleReference(
        adhesionDate: DateTime(2026, 1, 15),
        now: DateTime(2026, 6, 14),
      ),
      '2026-05-15',
    );
    expect(
      service.currentCycleReference(
        adhesionDate: DateTime(2026, 1, 15),
        now: DateTime(2026, 6, 15),
      ),
      '2026-06-15',
    );
  });
}
