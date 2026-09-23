import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/payment/mercadopago/mercadopago_card_tokenization_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/legal_document_page.dart';
import '../../../subscription/domain/entities/pix_automatic_models.dart';
import '../../../subscription/domain/usecases/create_mercadopago_subscription_usecase.dart';
import '../../../subscription/domain/usecases/create_pix_automatic_subscription_usecase.dart';
import '../../../subscription/presentation/pages/billing_profile_page.dart';
import '../../../subscription/presentation/pages/pix_automatic_explanation_page.dart';
import '../../data/datasources/plans_supabase_datasource.dart';
import 'subscription_processing_page.dart';
import '../widgets/payment_method_item.dart';
import '../widgets/payment_summary_sheet.dart';

enum PaymentMethod { creditCard, pix }

/// Cartão é tokenizado nos PCI Fields nativos do Mercado Pago em Android e
/// iOS. Os dados sensíveis nunca atravessam o MethodChannel.
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
  bool _cardAvailable = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadCardAvailability();
  }

  Future<void> _loadCardAvailability() async {
    final available =
        await sl<MercadoPagoCardTokenizationService>().isAvailable();
    if (!mounted) return;
    setState(() {
      _cardAvailable = available;
      if (available) _selectedMethod = PaymentMethod.creditCard;
    });
  }

  double get _total => widget.selectedPlan.price;
  String get _paymentMethodLabel {
    switch (_selectedMethod) {
      case PaymentMethod.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethod.pix:
        return 'Pix Automático';
    }
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
        planName: widget.selectedPlan.name,
        paymentMethod: _paymentMethodLabel,
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
    if (_selectedMethod == PaymentMethod.creditCard) {
      await _startMercadoPagoSubscription();
      return;
    }
    await _startPixAutomaticSubscription();
  }

  Future<PixAutomaticBillingProfile?> _collectBillingProfile() async {
    PixAutomaticBillingProfile? initial;
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        final row = await SupabaseConfig.client
            .from('billing_profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (row != null) {
          initial = PixAutomaticBillingProfile(
            name: row['name'] as String,
            taxId: row['tax_id'] as String,
            email: row['email'] as String,
            phone: row['phone'] as String,
            address: PixAutomaticBillingAddress(
              zipcode: row['zipcode'] as String,
              street: row['street'] as String,
              number: row['number'] as String,
              complement: row['complement'] as String?,
              neighborhood: row['neighborhood'] as String,
              city: row['city'] as String,
              state: row['state'] as String,
            ),
          );
        }
      }
    } catch (_) {
      // A tela permite completar os dados mesmo quando ainda não há perfil.
    }
    if (!mounted) return null;
    return Navigator.of(context).push<PixAutomaticBillingProfile>(
      MaterialPageRoute(
          builder: (_) => BillingProfilePage(initialProfile: initial)),
    );
  }

  Future<void> _startMercadoPagoSubscription() async {
    if (!_cardAvailable) {
      _showErrorDialog(
          'Cartão não está configurado neste ambiente. Use o Pix Automático.');
      return;
    }
    final profile = await _collectBillingProfile();
    if (profile == null || !mounted) return;
    setState(() => _processing = true);
    try {
      final tokenization = await sl<MercadoPagoCardTokenizationService>()
          .openCardTokenization(payerName: profile.name, cpf: profile.taxId);
      if (!mounted ||
          tokenization.outcome == CardTokenizationOutcome.cancelled) {
        return;
      }
      if (tokenization.outcome != CardTokenizationOutcome.success ||
          tokenization.cardTokenId == null) {
        _showErrorDialog(
            tokenization.message ?? 'Não foi possível validar o cartão.');
        return;
      }
      final result = await sl<CreateMercadoPagoSubscriptionUseCase>()(
        CreateMercadoPagoSubscriptionParams(
          planId: widget.selectedPlan.id,
          cardTokenId: tokenization.cardTokenId!,
        ),
      );
      if (!mounted) return;
      result.fold(
        (failure) => _showErrorDialog(failure.message),
        (subscription) => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SubscriptionProcessingPage(
              subscriptionId: subscription.id,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Não foi possível iniciar a assinatura por cartão.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _startPixAutomaticSubscription() async {
    final profile = await _collectBillingProfile();
    if (profile == null || !mounted) return;
    setState(() => _processing = true);
    try {
      final result = await sl<CreatePixAutomaticSubscriptionUseCase>()(
        CreatePixAutomaticSubscriptionParams(
          planId: widget.selectedPlan.id,
          customer: PixAutomaticCustomer(
            name: profile.name,
            taxId: profile.taxId,
            email: profile.email,
            phone: profile.phone,
            address: profile.address,
          ),
        ),
      );
      if (!mounted) return;
      result.fold(
        (failure) => _showErrorDialog(failure.message),
        (subscription) => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PixAutomaticExplanationPage(
              paymentLinkUrl: subscription.paymentLinkUrl,
              onConfirmWithoutLink: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => SubscriptionProcessingPage(
                    subscriptionId: subscription.id,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showErrorDialog('Não foi possível iniciar o Pix Automático.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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
    LegalDocumentPage.openTerms(context);
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
                text: _processing ? 'Processando...' : 'Assinar',
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
                widget.selectedPlan.name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSummaryRow('Plano',
              'R\$ ${widget.selectedPlan.price.toStringAsFixed(2).replaceAll('.', ',')}'),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Total mensal',
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
        if (_cardAvailable) ...[
          PaymentMethodItem(
            title: 'Cartão de Crédito',
            isSelected: _selectedMethod == PaymentMethod.creditCard,
            onTap: () =>
                setState(() => _selectedMethod = PaymentMethod.creditCard),
            trailing: _buildCardBrands(),
          ),
          const SizedBox(height: 6),
        ],
        PaymentMethodItem(
          title: 'Pix Automático',
          isSelected: _selectedMethod == PaymentMethod.pix,
          onTap: () => setState(() => _selectedMethod = PaymentMethod.pix),
          trailing: _buildPixIcon(),
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
        PaymentMethod.creditCard => _buildCardRedirectForm(),
        PaymentMethod.pix => _buildPixForm(),
      },
    );
  }

  Widget _buildPixForm() {
    return Text(
      'Cadastre seus dados de cobrança e autorize a mensalidade recorrente no app do seu banco.',
      style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6D7F95)),
    );
  }

  Widget _buildCardRedirectForm() {
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
            'Os dados do cartão serão digitados nos campos PCI nativos do Mercado Pago. '
            'O VittaClube recebe somente um token temporário e aguarda a primeira cobrança aprovada.',
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
