import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/domain/entities/subscription_status.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
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

                          // Plan info + quick actions (dependem da assinatura real)
                          BlocBuilder<SubscriptionBloc, SubscriptionState>(
                            builder: (context, state) {
                              if (state is SubscriptionLoading ||
                                  state is SubscriptionInitial) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (state is! SubscriptionLoaded) {
                                return _buildNoSubscriptionCard(context);
                              }
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _buildPlanInfoCard(
                                      state.subscription),
                                  const SizedBox(height: 12),
                                  _buildQuickActions(
                                      context, state.subscription),
                                ],
                              );
                            },
                          ),
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

  Widget _buildNoSubscriptionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Text(
        'Você ainda não tem uma assinatura ativa.',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6D7F95),
        ),
      ),
    );
  }

  Widget _buildPlanInfoCard(SubscriptionEntity subscription) {
    final nextDue = subscription.nextBillingDate ??
        subscription.currentPeriodEnd ??
        subscription.expirationDate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    subscription.level.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (subscription.isActive
                              ? const Color(0xFF249689)
                              : const Color(0xFFE8872B))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subscription.isActive ? 'Ativo' : 'Inativo',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: subscription.isActive
                            ? const Color(0xFF249689)
                            : const Color(0xFFE8872B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: const Color(0xFFEBEEF2).withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subscription.pixStatus == PixAutomaticSubscriptionStatus.none
                    ? 'Válido até:'
                    : 'Próximo Vencimento:',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6D7F95),
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                nextDue == null
                    ? '—'
                    : DateFormat('dd/MM/yyyy').format(nextDue),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    SubscriptionEntity subscription,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.credit_card,
            label: subscription.pixStatus ==
                    PixAutomaticSubscriptionStatus.none
                ? 'Renovar'
                : 'Pagar',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlansPage()),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildActionCard(
            icon: Icons.block,
            label: 'Cancelar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CancellationPage(
                    subscriptionId: subscription.id,
                    pixStatus: subscription.pixStatus,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEEF2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppTheme.primaryColor),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
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
