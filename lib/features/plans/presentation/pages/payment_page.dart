import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/payment/infinitypay/infinitypay_checkout_service.dart';
import '../../../../core/payment/infinitypay/infinitypay_models.dart';
import '../../../../core/payment/payment_gateway.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../subscription/domain/usecases/activate_subscription_usecase.dart';
import '../../data/datasources/plans_supabase_datasource.dart';
import 'infinitypay_pending_page.dart';
import '../widgets/payment_method_item.dart';
import '../widgets/payment_summary_sheet.dart';
import '../widgets/terms_bottom_sheet.dart';

enum PaymentMethod { creditCard, pix, infinityPay }

/// Página de pagamento — Cartão de Crédito ou Pix.
/// Persiste o resultado real em `payments` e ativa `subscriptions` ao aprovar.
class PaymentPage extends StatefulWidget {
  final RemotePlan selectedPlan;

  const PaymentPage({
    super.key,
    required this.selectedPlan,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  bool _processing = false;

  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _pixNameController = TextEditingController();
  final _pixCpfController = TextEditingController();

  double get _fee => _selectedMethod == PaymentMethod.infinityPay ? 0 : 4.99;
  double get _total => widget.selectedPlan.price + _fee;
  String get _paymentMethodLabel {
    switch (_selectedMethod) {
      case PaymentMethod.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.infinityPay:
        return 'Cartão via InfinitePay';
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _pixNameController.dispose();
    _pixCpfController.dispose();
    super.dispose();
  }

  void _handlePay() {
    if (_processing) return;
    _showPaymentSummary();
  }

  void _showPaymentSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaymentSummarySheet(
        planName: widget.selectedPlan.subscriptionType.displayName,
        paymentMethod: _paymentMethodLabel,
        fee: _fee,
        total: _total,
        onConfirm: () {
          Navigator.pop(context);
          _processPayment();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == PaymentMethod.infinityPay) {
      await _startInfinityPayCheckout();
      return;
    }

    setState(() => _processing = true);

    final gateway = sl<PaymentGateway>();
    final activateUseCase = sl<ActivateSubscriptionUseCase>();

    final request = PaymentRequest(
      planId: widget.selectedPlan.id,
      amount: widget.selectedPlan.price,
      method: _selectedMethod == PaymentMethod.creditCard
          ? PaymentMethodType.creditCard
          : PaymentMethodType.pix,
      cardHolderName: _cardNameController.text,
      cardNumber: _cardNumberController.text,
      cardExpiry: _cardExpiryController.text,
      cardCvv: _cardCvvController.text,
    );

    try {
      final result = await gateway.charge(request);
      if (!mounted) return;

      if (!result.approved) {
        _showErrorDialog(result.errorMessage ?? 'Pagamento não aprovado.');
        return;
      }

      final activation = await activateUseCase(
        planId: widget.selectedPlan.id,
        level: PlanLevelDb.bronze,
      );

      await activation.fold(
        (failure) async {
          if (!mounted) return;
          _showErrorDialog(
            'Pagamento aprovado, mas houve um erro ao ativar o plano. '
            'Nosso suporte foi notificado. (${failure.message})',
          );
        },
        (subscription) async {
          await _recordPayment(
            subscriptionId: subscription.id,
            receiptNumber: result.receiptNumber!,
            method: request.method,
          );
          if (!mounted) return;
          _showSuccessDialog();
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erro ao processar pagamento: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _startInfinityPayCheckout() async {
    setState(() => _processing = true);

    try {
      final service = sl<InfinityPayCheckoutService>();
      final appConfig = sl<AppConfig>();
      if (service.handle.trim().isEmpty) {
        _showErrorDialog(
          'INFINITYPAY_HANDLE não configurado para este ambiente.',
        );
        return;
      }

      final orderNsu = _buildOrderNsu();
      final amountCents = _priceInCents(widget.selectedPlan.price);
      await _createInfinityPayIntent(
        orderNsu: orderNsu,
        amountCents: amountCents,
      );

      final response = await service.createCheckoutLink(
        InfinityPayCreateLinkRequest(
          handle: service.handle,
          orderNsu: orderNsu,
          redirectUrl: appConfig.infinityPayRedirectUrl,
          webhookUrl: appConfig.resolvedInfinityPayWebhookUrl.isEmpty
              ? null
              : appConfig.resolvedInfinityPayWebhookUrl,
          items: [
            InfinityPayItem(
              description: 'Vitta Assinatura',
              quantity: 1,
              price: amountCents,
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (response.checkoutUrl.isEmpty) {
        _showErrorDialog('A InfinitePay não retornou o link de pagamento.');
        return;
      }

      await _updateInfinityPayIntentCheckoutUrl(
        orderNsu: orderNsu,
        checkoutUrl: response.checkoutUrl,
        slug: response.slug,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InfinityPayPendingPage(
            checkoutUrl: response.checkoutUrl,
            orderNsu: orderNsu,
            selectedPlan: widget.selectedPlan,
            initialSlug: response.slug,
          ),
        ),
      );
    } on InfinityPayCheckoutException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erro ao iniciar checkout InfinitePay: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _buildOrderNsu() {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? 'guest';
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'vitta_${userId}_$timestamp';
  }

  int _priceInCents(double value) => (value * 100).round();

  Future<void> _createInfinityPayIntent({
    required String orderNsu,
    required int amountCents,
  }) async {
    final supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Nenhum usuário autenticado para criar pagamento.');
    }

    await supabase.from('payment_intents').insert({
      'user_id': userId,
      'plan_id': widget.selectedPlan.id,
      'provider': 'infinitypay',
      'order_nsu': orderNsu,
      'amount': widget.selectedPlan.price,
      'amount_cents': amountCents,
      'currency': 'BRL',
      'status': 'pending',
    });
  }

  Future<void> _updateInfinityPayIntentCheckoutUrl({
    required String orderNsu,
    required String checkoutUrl,
    String? slug,
  }) async {
    await SupabaseConfig.client.from('payment_intents').update({
      'checkout_url': checkoutUrl,
      if (slug != null) 'slug': slug,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('order_nsu', orderNsu);
  }

  Future<void> _recordPayment({
    required String subscriptionId,
    required String receiptNumber,
    required PaymentMethodType method,
  }) async {
    final SupabaseClient supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('payments').insert({
      'user_id': userId,
      'subscription_id': subscriptionId,
      'amount': widget.selectedPlan.price,
      'method': method.dbValue,
      'status': 'aprovado',
      'receipt_number': receiptNumber,
      'paid_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Plano ativado!'),
        content: Text(
          'Seu plano ${widget.selectedPlan.subscriptionType.displayName} '
          'está ativo. Aproveite todos os benefícios!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              // Volta para a primeira rota (home) — SubscriptionBloc recarrega.
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Ir para o início'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Erro no pagamento'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TermsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -16,
              right: -180,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF01225B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(19.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pagamento',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPlanSummary(),
                        const SizedBox(height: 12),
                        _buildPaymentMethods(),
                        const SizedBox(height: 12),
                        _buildPaymentForm(),
                        const SizedBox(height: 12),
                        _buildTermsText(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              left: 24,
              right: 24,
              child: PrimaryButton(
                text: _processing ? 'Processando...' : 'Pagar',
                onPressed: _processing ? null : _handlePay,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.selectedPlan.subscriptionType.displayName,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.selectedPlan.name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6D7F95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSummaryRow('Plano',
              'R\$ ${widget.selectedPlan.price.toStringAsFixed(2).replaceAll('.', ',')}'),
          const SizedBox(height: 10),
          _buildSummaryRow(
              'Taxa', 'R\$ ${_fee.toStringAsFixed(2).replaceAll('.', ',')}'),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Total',
            'R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: highlight ? 16 : 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métodos de Pagamento',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
            letterSpacing: 0.075,
          ),
        ),
        const SizedBox(height: 6),
        PaymentMethodItem(
          title: 'Cartão de Crédito',
          isSelected: _selectedMethod == PaymentMethod.creditCard,
          onTap: () =>
              setState(() => _selectedMethod = PaymentMethod.creditCard),
          trailing: _buildCardBrands(),
        ),
        const SizedBox(height: 6),
        PaymentMethodItem(
          title: 'Pix',
          isSelected: _selectedMethod == PaymentMethod.pix,
          onTap: () => setState(() => _selectedMethod = PaymentMethod.pix),
          trailing: _buildPixIcon(),
        ),
        const SizedBox(height: 6),
        PaymentMethodItem(
          title: 'Cartão via InfinitePay',
          isSelected: _selectedMethod == PaymentMethod.infinityPay,
          onTap: () =>
              setState(() => _selectedMethod = PaymentMethod.infinityPay),
          trailing: _buildInfinityPayIcon(),
        ),
      ],
    );
  }

  Widget _buildCardBrands() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 23,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: Center(
            child: Text(
              'VISA',
              style: GoogleFonts.outfit(
                fontSize: 5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1F71),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 23,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEB001B),
                    shape: BoxShape.circle,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-2, 0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF79E1B).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPixIcon() {
    return const Icon(
      Icons.pix,
      color: Color(0xFF32BCAD),
      size: 24,
    );
  }

  Widget _buildInfinityPayIcon() {
    return const Icon(
      Icons.open_in_new_rounded,
      color: AppTheme.primaryColor,
      size: 22,
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: switch (_selectedMethod) {
        PaymentMethod.creditCard => _buildCreditCardForm(),
        PaymentMethod.pix => _buildPixForm(),
        PaymentMethod.infinityPay => _buildInfinityPayForm(),
      },
    );
  }

  Widget _buildCreditCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: 'Nome do Titular',
          hint: 'Nome Completo',
          controller: _cardNameController,
        ),
        const SizedBox(height: 6),
        _buildFormField(
          label: 'Número do Cartão',
          hint: '--- --- --- ----',
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Validade',
                hint: '06/26',
                controller: _cardExpiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildFormField(
                label: 'CVV',
                hint: '000',
                controller: _cardCvvController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPixForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: 'Nome do Pagador',
          hint: 'Nome Completo',
          controller: _pixNameController,
        ),
        const SizedBox(height: 6),
        _buildFormField(
          label: 'CPF',
          hint: '___.___.___-__',
          controller: _pixCpfController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
            _CpfFormatter(),
          ],
        ),
      ],
    );
  }

  Widget _buildInfinityPayForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Você será direcionado para o checkout seguro da InfinitePay para '
            'pagar com cartão ou carteira digital.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D7F95),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDDFE5)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.primaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D7F95).withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D7F95),
              letterSpacing: 0.065,
              height: 1.15,
            ),
            children: [
              const TextSpan(text: 'Ao pagar você aceita os '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: _showTerms,
                  child: Text(
                    'Termos e Condições',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D7F95),
                      decoration: TextDecoration.underline,
                      letterSpacing: 0.065,
                    ),
                  ),
                ),
              ),
              const TextSpan(
                  text: ' e confirma que tem mais de 18 anos (obrigatório).'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Seus dados pessoais estão seguros. Consulte nossa Política de Privacidade para mais informações.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
            letterSpacing: 0.065,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

/// Formatter para número de cartão de crédito (0000 0000 0000 0000)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formatter para data de validade (MM/YY)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i + 1 != text.length) {
        buffer.write('/');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formatter para CPF (000.000.000-00)
class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[.\-]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 5) {
        if (i + 1 != text.length) buffer.write('.');
      } else if (i == 8) {
        if (i + 1 != text.length) buffer.write('-');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
