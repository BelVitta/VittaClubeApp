import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/payment/infinitypay/infinitypay_checkout_service.dart';
import '../../../../core/payment/infinitypay/infinitypay_models.dart';
import '../../../../core/payment/payment_gateway.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../subscription/domain/repositories/subscription_repository.dart';
import '../../../subscription/domain/usecases/activate_subscription_usecase.dart';
import '../../../subscription/domain/usecases/create_pix_automatic_subscription_usecase.dart';
import '../../../subscription/presentation/pages/billing_profile_page.dart';
import '../../../subscription/presentation/pages/pix_automatic_explanation_page.dart';
import '../../data/datasources/plans_supabase_datasource.dart';
import '../widgets/payment_method_item.dart';
import '../widgets/payment_summary_sheet.dart';
import '../widgets/terms_bottom_sheet.dart';
import 'infinitypay_pending_page.dart';

enum PaymentMethod { creditCard, pix, infinityPay }

/// Página de assinatura mensal via Pix Automático.
/// A integração com Woovi acontece somente por Supabase Edge Functions.
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
  PaymentMethod _selectedMethod = PaymentMethod.pix;
  bool _processing = false;

  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  double get _fee => 0;
  double get _total => 34.90;

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  void _handlePay() {
    if (_processing) return;
    if (_selectedMethod == PaymentMethod.pix) {
      _openPixAutomaticExplanation();
      return;
    }
    if (_selectedMethod == PaymentMethod.infinityPay) {
      _startInfinityPayCheckout();
      return;
    }
    _showPaymentSummary();
  }

  Future<void> _openPixAutomaticExplanation() async {
    final profile = await _ensureBillingProfile();
    if (profile == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PixAutomaticExplanationPage(
          onConfirmWithoutLink: () => _createPixAutomaticSubscription(profile),
        ),
      ),
    );
  }

  Future<PixAutomaticBillingProfile?> _ensureBillingProfile() async {
    setState(() => _processing = true);
    final result = await sl<SubscriptionRepository>().getBillingProfile();
    if (!mounted) return null;
    setState(() => _processing = false);

    PixAutomaticBillingProfile? currentProfile;
    var hasFailure = false;
    result.fold(
      (failure) {
        hasFailure = true;
        _showErrorDialog(failure.message);
      },
      (profile) => currentProfile = profile,
    );

    if (hasFailure) return null;
    if (currentProfile != null && currentProfile!.isComplete) {
      return currentProfile;
    }

    return Navigator.of(context).push<PixAutomaticBillingProfile>(
      MaterialPageRoute(
        builder: (_) => BillingProfilePage(initialProfile: currentProfile),
      ),
    );
  }

  Future<void> _createPixAutomaticSubscription(
    PixAutomaticBillingProfile billingProfile,
  ) async {
    if (_processing || !billingProfile.isComplete) return;

    setState(() => _processing = true);
    final useCase = sl<CreatePixAutomaticSubscriptionUseCase>();
    final result = await useCase(
      CreatePixAutomaticSubscriptionParams(
        planId: widget.selectedPlan.id,
        customer: billingProfile.toCustomer(),
      ),
    );

    if (!mounted) return;
    setState(() => _processing = false);

    result.fold(
      (failure) => _showErrorDialog(failure.message),
      (subscription) {
        final link = subscription.paymentLinkUrl;
        if (link == null || link.isEmpty) {
          _showErrorDialog(
            'Assinatura criada, mas o link de autorização ainda não foi retornado. Atualize o status em instantes.',
          );
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PixAutomaticExplanationPage(paymentLinkUrl: link),
          ),
        );
      },
    );
  }

  Future<void> _startInfinityPayCheckout() async {
    setState(() => _processing = true);

    try {
      final service = sl<InfinityPayCheckoutService>();
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id ?? 'anonymous';
      final orderNsu =
          '${userId.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}';

      final priceInCents =
          (widget.selectedPlan.price * 100).round();

      final request = InfinityPayCreateLinkRequest(
        handle: service.handle,
        items: [
          InfinityPayItem(
            quantity: 1,
            price: priceInCents,
            description: widget.selectedPlan.subscriptionType.displayName,
          ),
        ],
        orderNsu: orderNsu,
      );

      final linkResponse = await service.createCheckoutLink(request);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InfinityPayPendingPage(
            checkoutUrl: linkResponse.checkoutUrl,
            orderNsu: orderNsu,
            selectedPlan: widget.selectedPlan,
          ),
        ),
      );
    } on InfinityPayCheckoutException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erro ao gerar link de pagamento: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showPaymentSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaymentSummarySheet(
        planName: widget.selectedPlan.subscriptionType.displayName,
        paymentMethod: _selectedMethod == PaymentMethod.creditCard
            ? 'Cartão de Crédito'
            : 'Pix',
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
                text: _processing
                    ? 'Processando...'
                    : _selectedMethod == PaymentMethod.infinityPay
                        ? 'Pagar via InfinityPay'
                        : 'Continuar com Pix Automático',
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
          _buildSummaryRow(
            'Assinatura mensal',
            'R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
          ),
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
          title: 'Pix Automático mensal',
          isSelected: _selectedMethod == PaymentMethod.pix,
          onTap: () => setState(() => _selectedMethod = PaymentMethod.pix),
          trailing: _buildPixIcon(),
        ),
        const SizedBox(height: 8),
        PaymentMethodItem(
          title: 'Cartão ou Pix via InfinityPay',
          isSelected: _selectedMethod == PaymentMethod.infinityPay,
          onTap: () =>
              setState(() => _selectedMethod = PaymentMethod.infinityPay),
          trailing: const Icon(
            Icons.credit_card_rounded,
            color: AppTheme.primaryColor,
            size: 24,
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
        PaymentMethod.infinityPay => _buildInfinityPayInfo(),
        PaymentMethod.pix => _buildPixForm(),
      },
    );
  }

  Widget _buildInfinityPayInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Você será redirecionado para a página segura da InfinityPay para concluir o pagamento com cartão de crédito ou Pix.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'O link de pagamento é gerado na hora e expira em 24 horas.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
            height: 1.25,
          ),
        ),
      ],
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
        Text(
          'Pix Automático mensal de R\$34,90. Você autoriza uma vez no app do banco e as próximas cobranças acontecem automaticamente.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Os dados de cobrança e endereço serão conferidos antes da autorização no banco.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reembolso em até 7 dias se nenhum benefício for utilizado.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
            height: 1.25,
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
