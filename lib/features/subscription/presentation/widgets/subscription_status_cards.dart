import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_status.dart';

class SubscriptionStatusCards extends StatelessWidget {
  const SubscriptionStatusCards._();

  static Widget forSubscription({
    required SubscriptionEntity? subscription,
    VoidCallback? onSubscribe,
    VoidCallback? onOpenBank,
    VoidCallback? onRefresh,
    VoidCallback? onRestore,
  }) {
    if (subscription == null ||
        subscription.billingStatus == SubscriptionBillingStatus.none) {
      return _StatusCard(
        title: 'Assine o VittaClube',
        message:
            'O acesso ao clube é pago e custa R\$34,90 por mês, sem teste grátis.',
        actionText: 'Assinar por R\$34,90/mês',
        onAction: onSubscribe,
      );
    }

    switch (subscription.billingStatus) {
      case SubscriptionBillingStatus.waitingAuthorization:
        return _StatusCard(
          title: 'Aguardando confirmação do seu banco',
          message: subscription.provider == SubscriptionProvider.mercadoPago
              ? 'O cartão foi tokenizado. Aguardamos a confirmação da primeira cobrança para liberar os benefícios.'
              : 'Você já iniciou a autorização Pix Automático. Volte ao app do banco para aprovar ou atualize o status.',
          actionText: subscription.paymentLinkUrl == null
              ? 'Atualizar status'
              : 'Abrir banco',
          onAction:
              subscription.paymentLinkUrl == null ? onRefresh : onOpenBank,
          secondaryText: 'Atualizar status',
          onSecondary: onRefresh,
        );
      case SubscriptionBillingStatus.active:
        return _StatusCard(
          title: 'Assinatura ativa',
          message:
              'Seu VittaClube está ativo. Valor: R\$34,90/mês. Próxima cobrança: ${_date(subscription.nextBillingDate)}.',
          actionText: 'Ver benefícios',
        );
      case SubscriptionBillingStatus.paymentPending:
        return _StatusCard(
          title: 'Pagamento pendente',
          message: subscription.provider == SubscriptionProvider.mercadoPago
              ? 'Não conseguimos confirmar a nova mensalidade. Seu acesso permanece ativo somente até o fim do período já pago.'
              : 'Não conseguimos cobrar sua mensalidade. O banco fará novas tentativas automáticas por até 7 dias. Seu acesso permanece ativo durante a recuperação.',
          actionText: 'Atualizar status',
          onAction: onRefresh,
        );
      case SubscriptionBillingStatus.blocked:
      case SubscriptionBillingStatus.expired:
        return _StatusCard(
          title: 'Conta bloqueada',
          message:
              'Sua assinatura não foi regularizada. Benefícios, dependentes e QR ficam bloqueados até a confirmação do pagamento.',
          actionText: 'Restaurar minha conta',
          onAction: onRestore,
          isDanger: true,
        );
      case SubscriptionBillingStatus.rejected:
        return _StatusCard(
          title: 'Autorização não concluída',
          message:
              'A cobrança ou autorização foi recusada e os benefícios não foram liberados.',
          actionText: 'Tentar novamente',
          onAction: onSubscribe,
          isDanger: true,
        );
      case SubscriptionBillingStatus.cancelled:
        return _StatusCard(
          title: 'Assinatura cancelada',
          message:
              'A recorrência foi cancelada. Seu acesso permanece até ${_date(subscription.currentPeriodEnd)}, se houver período pago vigente.',
          actionText: 'Reativar assinatura',
          onAction: onSubscribe,
        );
      case SubscriptionBillingStatus.none:
        return _StatusCard(
          title: 'Assine o VittaClube',
          message:
              'O acesso ao clube é pago e custa R\$34,90 por mês, sem teste grátis.',
          actionText: 'Assinar por R\$34,90/mês',
          onAction: onSubscribe,
        );
    }
  }

  static String _date(DateTime? value) {
    if (value == null) return 'a confirmar';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final VoidCallback? onAction;
  final String? secondaryText;
  final VoidCallback? onSecondary;
  final bool isDanger;

  const _StatusCard({
    required this.title,
    required this.message,
    required this.actionText,
    this.onAction,
    this.secondaryText,
    this.onSecondary,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDanger ? AppTheme.errorColor : AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(
              color: accent,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: AppTheme.bodyMedium),
          const SizedBox(height: 16),
          PrimaryButton(text: actionText, onPressed: onAction),
          if (secondaryText != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onSecondary, child: Text(secondaryText!)),
          ],
        ],
      ),
    );
  }
}
