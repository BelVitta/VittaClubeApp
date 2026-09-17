import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/financeiro_dashboard_metrics.dart';

class FinanceiroMetricsSupabaseDataSource {
  final SupabaseClient _supabase;

  FinanceiroMetricsSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<FinanceiroDashboardMetrics> getCurrentMonthMetrics() async {
    try {
      final now = DateTime.now().toUtc();
      final start = DateTime.utc(now.year, now.month, 1);
      final next = DateTime.utc(now.year, now.month + 1, 1);
      final startIso = start.toIso8601String();
      final nextIso = next.toIso8601String();

      final payments = await _supabase
          .from('payments')
          .select('amount')
          .eq('status', 'aprovado')
          .gte('paid_at', startIso)
          .lt('paid_at', nextIso);

      final monthRevenue = (payments as List).fold<double>(0, (sum, row) {
        final amount = (row as Map)['amount'];
        if (amount is num) return sum + amount.toDouble();
        return sum;
      });

      final active = await _supabase
          .from('subscriptions')
          .select('id')
          .eq('is_current', true)
          .isFilter('cancelled_at', null)
          .not('plan_level_status', 'in', '(inadimplente,cancelado,none)');

      final overdue = await _supabase
          .from('subscriptions')
          .select('id')
          .eq('is_current', true)
          .or('plan_level_status.eq.inadimplente,payment_access_status.eq.blocked');

      final cancelled = await _supabase
          .from('subscriptions')
          .select('id')
          .gte('cancelled_at', startIso)
          .lt('cancelled_at', nextIso);

      return FinanceiroDashboardMetrics(
        monthRevenue: monthRevenue,
        activeMembers: (active as List).length,
        overdueMembers: (overdue as List).length,
        monthCancellations: (cancelled as List).length,
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao carregar métricas: $e');
    }
  }
}
