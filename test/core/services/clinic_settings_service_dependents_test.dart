import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/core/services/clinic_settings_service.dart';

void main() {
  test('reads default dependent settings when values are absent', () async {
    final service = ClinicSettingsService()..seedCacheForTesting({});

    expect(
      await service.getMaxDependentsPerHolder(),
      ClinicSettingsService.defaultMaxDependentsPerHolder,
    );
    expect(
      await service.getMonthlyUsesPerDependent(),
      ClinicSettingsService.defaultMonthlyUsesPerDependent,
    );
  });

  test('parses configured dependent settings from cache', () async {
    final service = ClinicSettingsService()
      ..seedCacheForTesting({
        ClinicSettingsService.kMaxDependentsPerHolder: '3',
        ClinicSettingsService.kMonthlyUsesPerDependent: '4',
      });

    expect(await service.getMaxDependentsPerHolder(), 3);
    expect(await service.getMonthlyUsesPerDependent(), 4);
  });
}
