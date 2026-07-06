import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/payment/infinitypay/infinitypay_checkout_service.dart';
import '../../../../core/payment/infinitypay/infinitypay_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../subscription/domain/usecases/activate_subscription_usecase.dart';
import '../../data/datasources/plans_supabase_datasource.dart';

class InfinityPayPendingPage extends StatefulWidget {
  final String checkoutUrl;
  final String orderNsu;
  final RemotePlan selectedPlan;

  const InfinityPayPendingPage({
    super.key,
    required this.checkoutUrl,
    required this.orderNsu,
    required this.selectedPlan,
  });

  @override
  State<InfinityPayPendingPage> createState() => _InfinityPayPendingPageState();
}

class _InfinityPayPendingPageState extends State<InfinityPayPendingPage>
    with WidgetsBindingObserver {
  bool _checking = false;

  // Preenchidos pelo usuário ao colar os parâmetros da redirect_url (opcional).
  // Na prática, virão via deep link quando configurado.
  String? _transactionNsu;
  String? _slug;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCheckout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o usuário volta ao app após pagar no navegador
    if (state == AppLifecycleState.resumed &&
        _transactionNsu != null &&
        _slug != null) {
      _verifyPayment();
    }
  }

  Future<void> _openCheckout() async {
    final uri = Uri.parse(widget.checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _verifyPayment() async {
    if (_checking) return;
    if (_transactionNsu == null || _slug == null) {
      _showManualVerificationDialog();
      return;
    }

    setState(() => _checking = true);

    try {
      final service = sl<InfinityPayCheckoutService>();
      final result = await service.checkPaymentStatus(
        InfinityPayPaymentCheckRequest(
          handle: service.handle,
          orderNsu: widget.orderNsu,
          transactionNsu: _transactionNsu!,
          slug: _slug!,
        ),
      );

      if (!mounted) return;

      if (result.success && result.paid) {
        await _activateSubscription();
      } else {
        _showErrorDialog('Pagamento ainda não confirmado pela InfinityPay.');
      }
    } on InfinityPayCheckoutException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erro ao verificar pagamento: $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _activateSubscription() async {
    final activateUseCase = sl<ActivateSubscriptionUseCase>();
    final result = await activateUseCase(
      planId: widget.selectedPlan.id,
      level: PlanLevelDb.bronze,
    );

    if (!mounted) return;

    result.fold(
      (failure) => _showErrorDialog(
        'Pagamento confirmado, mas erro ao ativar plano: ${failure.message}',
      ),
      (subscription) async {
        await _recordPayment(subscriptionId: subscription.id);
        if (!mounted) return;
        _showSuccessDialog();
      },
    );
  }

  Future<void> _recordPayment({required String subscriptionId}) async {
    final supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('payments').insert({
      'user_id': userId,
      'subscription_id': subscriptionId,
      'amount': widget.selectedPlan.price,
      'method': 'infinitypay',
      'status': 'aprovado',
      'receipt_number': widget.orderNsu,
      'paid_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void _showManualVerificationDialog() {
    final transactionController = TextEditingController();
    final slugController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dados do pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cole os dados que vieram na URL de retorno para verificar seu pagamento.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6D7F95)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: transactionController,
              decoration: const InputDecoration(
                labelText: 'transaction_nsu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: slugController,
              decoration: const InputDecoration(
                labelText: 'slug',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (transactionController.text.isNotEmpty &&
                  slugController.text.isNotEmpty) {
                setState(() {
                  _transactionNsu = transactionController.text.trim();
                  _slug = slugController.text.trim();
                });
                Navigator.pop(context);
                _verifyPayment();
              }
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
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
              Navigator.pop(context);
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
        title: const Text('Erro'),
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
                            color: const Color(0xFF01225B).withValues(alpha: 0.2),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.open_in_browser_rounded,
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Finalize o pagamento\nno seu navegador',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Uma aba foi aberta com a página de pagamento da InfinityPay. '
                          'Após concluir, volte aqui e toque em "Já paguei".',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF6D7F95),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pedido: ${widget.orderNsu}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF6D7F95),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextButton.icon(
                          onPressed: _openCheckout,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Reabrir página de pagamento'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
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
                text: _checking ? 'Verificando...' : 'Já paguei',
                onPressed: _checking ? null : _verifyPayment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
