import 'payment_gateway.dart';

/// Gateway de pagamento simulado para dev/staging.
/// Aprova toda cobrança após um delay de 1.5s e devolve um número de recibo
/// único. Não faz nenhuma chamada externa.
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> charge(PaymentRequest request) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final receipt =
        'MOCK-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    return PaymentResult.approved(receipt);
  }
}

/// Placeholder para produção enquanto o gateway real (Stripe / Mercado Pago /
/// Pagar.me) ainda não está integrado. Lança erro imediato para impedir que
/// usuários reais fechem compra sem processamento.
class UnimplementedPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> charge(PaymentRequest request) async {
    return const PaymentResult.denied(
      'Pagamento indisponível no momento. Tente novamente mais tarde.',
    );
  }
}
