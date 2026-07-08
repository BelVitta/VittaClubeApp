import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_model.dart';

class PaymentsSupabaseDataSource {
  final SupabaseClient _supabase;

  PaymentsSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<List<PaymentModel>> getForCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _supabase
        .from('payments')
        .select('id, amount, method, status, receipt_number, paid_at')
        .eq('user_id', userId)
        .order('paid_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((row) => PaymentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
