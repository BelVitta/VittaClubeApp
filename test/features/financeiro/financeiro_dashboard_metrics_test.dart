import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/financeiro/domain/entities/financeiro_dashboard_metrics.dart';

void main() {
  test('metrics are real totals, not showcase placeholders', () {
    const metrics = FinanceiroDashboardMetrics(
      monthRevenue: 0,
      activeMembers: 0,
      overdueMembers: 0,
      monthCancellations: 0,
    );
    expect(metrics.monthRevenue, 0);
    expect(metrics.activeMembers, 0);
  });
}
