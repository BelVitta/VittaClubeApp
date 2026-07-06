import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

enum AccountAccessModalVariant {
  subscribe,
  reactivate,
}

class RestoreAccountModal extends StatelessWidget {
  final AccountAccessModalVariant variant;
  final VoidCallback? onRestore;
  final VoidCallback? onSupport;

  const RestoreAccountModal({
    super.key,
    this.variant = AccountAccessModalVariant.reactivate,
    this.onRestore,
    this.onSupport,
  });

  static Future<void> show(
    BuildContext context, {
    AccountAccessModalVariant variant = AccountAccessModalVariant.reactivate,
    VoidCallback? onRestore,
    VoidCallback? onSupport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RestoreAccountModal(
        variant: variant,
        onRestore: onRestore,
        onSupport: onSupport,
      ),
    );
  }

  static Future<void> showSubscribe(
    BuildContext context, {
    VoidCallback? onSubscribe,
    VoidCallback? onSupport,
  }) {
    return show(
      context,
      variant: AccountAccessModalVariant.subscribe,
      onRestore: onSubscribe,
      onSupport: onSupport,
    );
  }

  static Future<void> showReactivate(
    BuildContext context, {
    VoidCallback? onReactivate,
    VoidCallback? onSupport,
  }) {
    return show(
      context,
      variant: AccountAccessModalVariant.reactivate,
      onRestore: onReactivate,
      onSupport: onSupport,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    return Semantics(
      namesRoute: true,
      label: content.semanticLabel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(content.icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 14),
            Text(content.title, style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              content.message,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              content.highlight,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              text: content.primaryCta,
              onPressed: onRestore ?? () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSupport,
              child: const Text('Falar com suporte'),
            ),
          ],
        ),
      ),
    );
  }

  _ModalContent get _content {
    switch (variant) {
      case AccountAccessModalVariant.subscribe:
        return const _ModalContent(
          semanticLabel: 'Assinar VittaClube',
          icon: Icons.workspace_premium_outlined,
          title: 'Entre para o VittaClube',
          message:
              'Seu acesso aos descontos em consultas, exames, parceiros e carteirinha digital começa com uma assinatura ativa.',
          highlight:
              'Assine por R\$34,90/mês e libere os benefícios do clube em poucos minutos.',
          primaryCta: 'Assinar agora',
        );
      case AccountAccessModalVariant.reactivate:
        return const _ModalContent(
          semanticLabel: 'Reativar conta VittaClube',
          icon: Icons.refresh_rounded,
          title: 'Reative sua conta',
          message:
              'Sua assinatura não está ativa no momento. Enquanto isso, QR, dependentes, agendamentos e benefícios ficam bloqueados.',
          highlight:
              'Regularize por R\$34,90/mês e volte a usar o VittaClube sem perder tempo.',
          primaryCta: 'Reativar minha conta',
        );
    }
  }
}

class _ModalContent {
  final String semanticLabel;
  final IconData icon;
  final String title;
  final String message;
  final String highlight;
  final String primaryCta;

  const _ModalContent({
    required this.semanticLabel,
    required this.icon,
    required this.title,
    required this.message,
    required this.highlight,
    required this.primaryCta,
  });
}
