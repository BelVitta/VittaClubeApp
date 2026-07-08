import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/dependents/domain/services/dependent_cycle_service.dart';

void main() {
  test('handles day 31, short months, leap year, and year turn', () {
    final service = DependentCycleService();

    expect(
      service.currentCycleReference(
        adhesionDate: DateTime(2025, 1, 31),
        now: DateTime(2026, 2, 28),
      ),
      '2026-02-28',
    );
    expect(
      service.currentCycleReference(
        adhesionDate: DateTime(2024, 2, 29),
        now: DateTime(2025, 2, 28),
      ),
      '2025-02-28',
    );
    expect(
      service.currentCycleReference(
        adhesionDate: DateTime(2025, 12, 31),
        now: DateTime(2026, 1, 1),
      ),
      '2025-12-31',
    );
  });
}
