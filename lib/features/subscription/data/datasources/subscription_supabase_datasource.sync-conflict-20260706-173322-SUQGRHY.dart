import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/subscription_repository.dart';
import '../models/subscription_model.dart';

class SubscriptionSupabaseDataSource {
  final SupabaseClient _supabase;

  SubscriptionSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Retorna a assinatura ativa (`is_current = true`) do usuário logado.
  /// `null` se o usuário ainda não tem plano.
  Future<SubscriptionModel?> getCurrent() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _supabase
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();

    if (row == null) return null;
    return SubscriptionModel.fromJson(row);
  }

  /// Cria uma nova subscription marcando-a como a ativa do usuário. Antes,
  /// marca qualquer subscription anterior como `is_current = false` para não
  /// violar o índice único parcial.
  Future<SubscriptionModel> activate({
    required String planId,
    required String planLevelDb,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Nenhum usuário autenticado para ativar assinatura.');
    }

    // Desativa subscription anterior (se houver) para respeitar o UNIQUE parcial.
    await _supabase
        .from('subscriptions')
        .update({'is_current': false})
        .eq('user_id', userId)
        .eq('is_current', true);

    final inserted = await _supabase
        .from('subscriptions')
        .insert({
          'user_id': userId,
          'plan_id': planId,
          'badge_level': _badgeFromLevel(planLevelDb),
          'plan_level_status': planLevelDb,
          'is_current': true,
        })
        .select()
        .single();

    return SubscriptionModel.fromJson(inserted);
  }

  Future<SubscriptionModel> createPixAutomaticSubscription({
    required String planId,
    required PixAutomaticCustomer customer,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-woovi-subscription',
      body: {
        'planId': planId,
        'customer': customer.toJson(),
      },
    );

    final payload = response.data as Map<String, dynamic>;
    final subscriptionPayload =
        payload['subscription'] as Map<String, dynamic>? ?? payload;
    final localId = subscriptionPayload['id'] as String?;

    if (localId != null) {
      final row = await _supabase
          .from('subscriptions')
          .select()
          .eq('id', localId)
          .single();
      return SubscriptionModel.fromJson(row);
    }

    return getCurrent().then((value) {
      if (value == null) {
        throw StateError('Assinatura criada, mas status local não encontrado.');
      }
      return value;
    });
  }

  Future<PixAutomaticBillingProfile?> getBillingProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _supabase
        .from('billing_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;
    return _billingProfileFromJson(row);
  }

  Future<PixAutomaticBillingProfile> saveBillingProfile(
    PixAutomaticBillingProfile profile,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Nenhum usuário autenticado para salvar cobrança.');
    }

    final row = await _supabase
        .from('billing_profiles')
        .upsert({
          'user_id': userId,
          'name': profile.name,
          'tax_id': profile.taxId,
          'email': profile.email,
          'phone': profile.phone,
          'zipcode': profile.address.zipcode,
          'street': profile.address.street,
          'number': profile.address.number,
          'complement': profile.address.complement,
          'neighborhood': profile.address.neighborhood,
          'city': profile.address.city,
          'state': profile.address.state,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id')
        .select()
        .single();

    return _billingProfileFromJson(row);
  }

  Future<SubscriptionModel?> refreshSubscriptionStatus() async {
    final current = await getCurrent();
    if (current == null) return null;

    await _supabase.functions.invoke(
      'reconcile-woovi-subscription',
      body: {'subscriptionId': current.id},
    );

    return getCurrent();
  }

  Future<void> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    await _supabase.functions.invoke(
      'cancel-woovi-subscription',
      body: {
        'subscriptionId': subscriptionId,
        'reason': reason,
      },
    );
  }

  /// `plan_level_status` aceita 'inadimplente'/'cancelado' também, mas o enum
  /// `badge_level` só tem os 4 níveis reais. Mapeia com fallback seguro.
  String _badgeFromLevel(String level) {
    const validBadges = {'bronze', 'prata', 'ouro', 'diamante'};
    return validBadges.contains(level) ? level : 'bronze';
  }

  PixAutomaticBillingProfile _billingProfileFromJson(
    Map<String, dynamic> json,
  ) {
    return PixAutomaticBillingProfile(
      userId: json['user_id'] as String?,
      name: json['name'] as String? ?? '',
      taxId: json['tax_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: PixAutomaticBillingAddress(
        zipcode: json['zipcode'] as String? ?? '',
        street: json['street'] as String? ?? '',
        number: json['number'] as String? ?? '',
        complement: json['complement'] as String?,
        neighborhood: json['neighborhood'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
      ),
    );
  }
}
