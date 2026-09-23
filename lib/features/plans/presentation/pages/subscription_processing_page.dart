import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/domain/entities/subscription_status.dart';
import '../../../subscription/domain/repositories/subscription_repository.dart';

class SubscriptionProcessingPage extends StatefulWidget {
  final String subscriptionId;

  const SubscriptionProcessingPage({super.key, required this.subscriptionId});

  @override
  State<SubscriptionProcessingPage> createState() =>
      _SubscriptionProcessingPageState();
}

class _SubscriptionProcessingPageState
    extends State<SubscriptionProcessingPage> {
  Timer? _timer;
  bool _refreshing = false;
  SubscriptionEntity? _subscription;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    if (!silent && mounted) setState(() => _refreshing = true);
    _refreshing = true;
    final result = await sl<SubscriptionRepository>().refreshSubscriptionStatus(
      subscriptionId: widget.subscriptionId,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (subscription) {
        setState(() {
          _subscription = subscription;
          _error = null;
        });
        if (subscription?.billingStatus == SubscriptionBillingStatus.active) {
          _timer?.cancel();
        }
      },
    );
    _refreshing = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = _subscription?.billingStatus;
    final active = status == SubscriptionBillingStatus.active;
    final rejected = status == SubscriptionBillingStatus.rejected ||
        status == SubscriptionBillingStatus.blocked;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmando assinatura')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active
                    ? Icons.check_circle
                    : rejected
                        ? Icons.error_outline
                        : Icons.sync,
                size: 72,
                color: active
                    ? AppTheme.successColor
                    : rejected
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                active
                    ? 'Assinatura ativa'
                    : rejected
                        ? 'Pagamento não aprovado'
                        : 'Aguardando a primeira cobrança',
                style: AppTheme.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                active
                    ? 'A primeira mensalidade foi confirmada e seus benefícios já estão liberados.'
                    : rejected
                        ? 'Seus benefícios não foram liberados. Revise o meio de pagamento e tente novamente.'
                        : 'Seus benefícios serão liberados somente após a confirmação do Mercado Pago.',
                style: AppTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppTheme.errorColor)),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                text: active
                    ? 'Ir para o início'
                    : _refreshing
                        ? 'Atualizando...'
                        : 'Atualizar status',
                onPressed: _refreshing
                    ? null
                    : active
                        ? () => Navigator.of(context)
                            .popUntil((route) => route.isFirst)
                        : _refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
