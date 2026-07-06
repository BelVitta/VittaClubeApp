import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

class PixAutomaticExplanationPage extends StatefulWidget {
  final String? paymentLinkUrl;
  final VoidCallback? onConfirmWithoutLink;

  const PixAutomaticExplanationPage({
    super.key,
    this.paymentLinkUrl,
    this.onConfirmWithoutLink,
  });

  @override
  State<PixAutomaticExplanationPage> createState() =>
      _PixAutomaticExplanationPageState();
}

class _PixAutomaticExplanationPageState
    extends State<PixAutomaticExplanationPage> {
  bool _bankOpened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Assinar VittaClube'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('R\$34,90 por mês', style: AppTheme.headingLarge),
            const SizedBox(height: 8),
            Text(
              'Você autorizará uma cobrança recorrente automática mensal. Não é um pagamento único.',
              style: AppTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            const _InfoRow(
              title: 'Aprovação no seu banco',
              body:
                  'Você sairá momentaneamente do VittaClube para aprovar a autorização no app do banco.',
            ),
            const _InfoRow(
              title: 'Primeira mensal cobrada na aprovação',
              body:
                  'Ao aprovar, a primeira mensalidade já é cobrada e o acesso é liberado quando o banco confirmar.',
            ),
            const _InfoRow(
              title: 'Cancelamento pelo banco',
              body:
                  'Você pode cancelar a recorrência quando quiser pelo aplicativo do banco.',
            ),
            const _InfoRow(
              title: 'Reembolso manual',
              body:
                  'Reembolso em até 7 dias se nenhum benefício for utilizado. A solicitação passa por análise financeira.',
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Autorizar no app do banco',
              onPressed: _openBank,
            ),
            if (_bankOpened && widget.paymentLinkUrl != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Já autorizei — verificar minha assinatura'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openBank() async {
    final link = widget.paymentLinkUrl;
    if (link == null || link.isEmpty) {
      widget.onConfirmWithoutLink?.call();
      return;
    }

    final uri = Uri.parse(link);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (opened) {
      setState(() => _bankOpened = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o app do banco.'),
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String body;

  const _InfoRow({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(body, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}
