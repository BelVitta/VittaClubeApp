import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/pix_automatic_models.dart';
import '../../domain/entities/subscription_status.dart';
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

  Future<SubscriptionModel?> refreshCurrent({String? subscriptionId}) async {
    final current = subscriptionId == null
        ? await getCurrent()
        : await _getByIdForCurrentUser(subscriptionId);
    if (current == null) return null;
    final functionName = switch (current.provider) {
      SubscriptionProvider.mercadoPago => 'reconcile-mercadopago-subscription',
      SubscriptionProvider.woovi => 'reconcile-woovi-subscription',
      SubscriptionProvider.infinityPayLegacy ||
      SubscriptionProvider.manual =>
        null,
    };
    if (functionName != null) {
      await _supabase.functions.invoke(
        functionName,
        body: {'subscriptionId': current.id},
      );
    }
    return subscriptionId == null
        ? getCurrent()
        : _getByIdForCurrentUser(subscriptionId);
  }

  Future<SubscriptionModel?> _getByIdForCurrentUser(
      String subscriptionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _supabase
        .from('subscriptions')
        .select()
        .eq('id', subscriptionId)
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : SubscriptionModel.fromJson(row);
  }

  /// Cria uma nova subscription marcando-a como a ativa do usuário. Antes,
  /// marca qualquer subscription anterior como `is_current = false` para não
  /// violar o índice único parcial.
  Future<SubscriptionModel> activate({
    required String planId,
    required String planLevelDb,
  }) async {
    // Mantido apenas para compatibilidade binária com o use case legado.
    // Assinaturas agora só podem ser criadas por um provedor e ativadas após
    // a confirmação server-side da cobrança; o cliente nunca insere localmente.
    throw StateError(
      'Ativação local desabilitada; use o fluxo de assinatura do provedor.',
    );
  }

  Future<void> cancelSubscription({
    required String subscriptionId,
    String? reason,
    required SubscriptionProvider provider,
  }) async {
    final functionName = switch (provider) {
      SubscriptionProvider.mercadoPago => 'cancel-mercadopago-subscription',
      SubscriptionProvider.woovi => 'cancel-woovi-subscription',
      SubscriptionProvider.infinityPayLegacy ||
      SubscriptionProvider.manual =>
        'cancel-local-subscription',
    };
    final response = await _supabase.functions.invoke(
      functionName,
      body: {
        'subscriptionId': subscriptionId,
        if (reason != null) 'reason': reason
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('O servidor não confirmou o cancelamento.');
    }
  }

  Future<SubscriptionModel> createMercadoPagoSubscription({
    required String planId,
    required String cardTokenId,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-mercadopago-subscription',
      body: {'planId': planId, 'cardTokenId': cardTokenId},
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Não foi possível iniciar a assinatura por cartão.');
    }
    final current = await getCurrent();
    if (current == null) {
      throw StateError('Assinatura criada, mas ainda não sincronizada.');
    }
    return current;
  }

  Future<SubscriptionModel> createPixAutomaticSubscription({
    required String planId,
    required PixAutomaticCustomer customer,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-woovi-subscription',
      body: {
        'planId': planId,
        'customer': {
          'name': customer.name,
          'taxID': customer.taxId,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address.toJson(),
        },
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Não foi possível iniciar o Pix Automático.');
    }
    final current = await getCurrent();
    if (current == null) {
      throw StateError('Assinatura Pix ainda não sincronizada.');
    }
    return current;
  }

  Future<PixAutomaticBillingProfile> saveBillingProfile(
    PixAutomaticBillingProfile profile,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Nenhum usuário autenticado para salvar perfil.');
    }

    await _supabase.from('billing_profiles').upsert({
      'user_id': userId,
      ...profile.toJson(),
    });

    return profile;
  }
}
