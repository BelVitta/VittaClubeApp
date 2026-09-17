import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('financeiro dashboard source does not embed fake KPI numbers', () {
    final source = File(
      'lib/features/financeiro/presentation/pages/financeiro_dashboard_page.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('12.450')));
    expect(source, isNot(contains("'247'")));
    expect(source, isNot(contains("value: '18'")));
    expect(source, isNot(contains("variation: '+8%'")));
    expect(source, contains('GetFinanceiroDashboardMetricsUseCase'));
    expect(source, isNot(contains('count: 0')));
  });

  test('admin dashboard no longer links cancellation-reason CRUD', () {
    final source = File(
      'lib/features/admin/presentation/pages/admin_dashboard_page.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('AdminReasonsListPage')));
    expect(source, isNot(contains('Motivos Canc.')));
  });
}
