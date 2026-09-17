import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/whatsapp_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/subscription_status_cards.dart';
import '../../domain/entities/payment_entity.dart';
import '../bloc/payments_bloc.dart';
import '../bloc/payments_event.dart';
import '../bloc/payments_state.dart';
import '../widgets/payment_receipt_sheet.dart';
import 'cancellation_page.dart';

/// Página de Pagamentos com resumo do plano, ações rápidas e histórico.
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<SubscriptionBloc>()..add(const LoadCurrentSubscription()),
        ),
        BlocProvider(
          create: (_) => sl<PaymentsBloc>()..add(const LoadPaymentHistory()),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Background gradient circle
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
                  // Back button
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
                              color: const Color(0xFF01225B)
                                  .withValues(alpha: 0.2),
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
                  const SizedBox(height: 12),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'Pagamento',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.12,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Estado da assinatura (dependem da assinatura real)
                          BlocBuilder<SubscriptionBloc, SubscriptionState>(
                            builder: (context, state) {
                              if (state is SubscriptionLoading ||
                                  state is SubscriptionInitial) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final subscription = state is SubscriptionLoaded
                                  ? state.subscription
                                  : null;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SubscriptionStatusCards.forSubscription(
                                    subscription: subscription,
                                    onSubscribe: () => _goToPlans(context),
                                    onOpenBank:
                                        subscription?.paymentLinkUrl == null
                                            ? null
                                            : () => _openBank(context,
                                                subscription!.paymentLinkUrl!),
                                    onRefresh: () => context
                                        .read<SubscriptionBloc>()
                                        .add(const LoadCurrentSubscription()),
                                    onRestore: () => _goToPlans(context),
                                  ),
                                  if (subscription != null) ...[
                                    const SizedBox(height: 12),
                                    _buildCancelAction(context, subscription),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildSupportButton(context),
                          const SizedBox(height: 16),

                          // Payment history
                          Text(
                            'Histórico de Pagamentos',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.075,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildHistory(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToPlans(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlansPage()),
    ).then((_) {
      if (context.mounted) {
        context.read<SubscriptionBloc>().add(const LoadCurrentSubscription());
      }
    });
  }

  Future<void> _openBank(BuildContext context, String paymentLinkUrl) async {
    final uri = Uri.parse(paymentLinkUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o app do banco.')),
    );
  }

  Future<void> _talkToSupport(BuildContext context) async {
    final result = await WhatsAppLauncher.open(
      presetMessage: 'Olá! Preciso de ajuda com o pagamento da minha '
          'assinatura do Vita Clube.',
    );
    if (!context.mounted || result == WhatsAppLaunchResult.ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir o WhatsApp agora.'),
      ),
    );
  }

  Widget _buildSupportButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _talkToSupport(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size.fromHeight(0),
      ),
      icon: const Icon(Icons.chat_outlined, size: 18),
      label: Text(
        'Falar com Suporte',
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCancelAction(
    BuildContext context,
    SubscriptionEntity subscription,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CancellationPage(
            subscriptionId: subscription.id,
            pixStatus: subscription.pixStatus,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEEF2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Cancelar assinatura',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    return BlocBuilder<PaymentsBloc, PaymentsState>(
      builder: (context, state) {
        if (state is PaymentsLoading || state is PaymentsInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is PaymentsError) {
          return Text(
            'Não foi possível carregar o histórico.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          );
        }
        final items = (state as PaymentsLoaded).items;
        if (items.isEmpty) {
          return Text(
            'Nenhum pagamento registrado ainda.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          );
        }
        return Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildHistoryItem(context, item),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, PaymentEntity item) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateLabel = item.paidAt == null
        ? '—'
        : DateFormat('dd/MM/yyyy').format(item.paidAt!);
    return GestureDetector(
      onTap: () {
        PaymentReceiptSheet.show(
          context,
          receiptNumber: item.receiptNumber,
          dateTime: item.paidAt == null
              ? '—'
              : DateFormat('dd/MM/yyyy \'às\' HH:mm').format(item.paidAt!),
          paymentMethod: item.methodLabel,
          status: item.statusLabel,
          planName: 'Assinatura Vita Clube',
          amount: item.amount.toStringAsFixed(2).replaceAll('.', ','),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEEF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.status == 'aprovado'
                    ? const Color(0xFF249689)
                    : const Color(0xFFE8872B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.status == 'aprovado' ? Icons.check : Icons.schedule,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.statusLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '$dateLabel - ${item.methodLabel}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D7F95),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              currency.format(item.amount),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
