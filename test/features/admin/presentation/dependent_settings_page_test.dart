import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/di/injection_container.dart';
import 'package:vita_clube/core/services/clinic_settings_service.dart';
import 'package:vita_clube/features/admin/presentation/pages/clinic_settings/admin_clinic_settings_page.dart';

class MockClinicSettingsService extends Mock implements ClinicSettingsService {}

void main() {
  late MockClinicSettingsService settings;

  setUp(() async {
    await sl.reset();
    settings = MockClinicSettingsService();
    sl.registerLazySingleton<ClinicSettingsService>(() => settings);

    when(() => settings.get(ClinicSettingsService.kDefaultWhatsapp))
        .thenAnswer((_) async => '5585999000000');
    when(() => settings.getMaxDependentsPerHolder()).thenAnswer((_) async => 2);
    when(() => settings.getMonthlyUsesPerDependent())
        .thenAnswer((_) async => 2);
    when(() => settings.set(any(), any())).thenAnswer((_) async {});
    when(() => settings.setMaxDependentsPerHolder(any()))
        .thenAnswer((_) async {});
    when(() => settings.setMonthlyUsesPerDependent(any()))
        .thenAnswer((_) async {});
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('validates dependent settings fields before saving',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminClinicSettingsPage()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(
        find.text(
            'Limite de dependentes deve ser um número inteiro maior que zero.'),
        findsOneWidget);
    verifyNever(() => settings.setMaxDependentsPerHolder(any()));
  });

  testWidgets('saves whatsapp and dependent settings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminClinicSettingsPage()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '3');
    await tester.enterText(find.byType(TextFormField).at(2), '4');
    await tester.tap(find.text('Salvar'));
    await tester.pump();

    verify(() => settings.set(
        ClinicSettingsService.kDefaultWhatsapp, '5585999000000')).called(1);
    verify(() => settings.setMaxDependentsPerHolder(3)).called(1);
    verify(() => settings.setMonthlyUsesPerDependent(4)).called(1);
  });
}
