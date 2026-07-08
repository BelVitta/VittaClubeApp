import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../dependents/domain/usecases/get_dependents_usecase.dart';
import '../../../dependents/presentation/widgets/beneficiary_selector.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/restore_account_modal.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';

class ConsultationSchedulePage extends StatelessWidget {
  final List<DependentWithQuota> dependents;
  final SubscriptionEntity? subscription;

  const ConsultationSchedulePage({
    super.key,
    this.dependents = const [],
    this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final subscription = this.subscription;
    if (subscription != null) {
      return _buildScaffold(
        context,
        loadingSubscription: false,
        canAccess: subscription.canAccessBenefits,
        modalVariant: AccountAccessModalVariant.reactivate,
      );
    }

    return BlocProvider(
      create: (_) =>
          sl<SubscriptionBloc>()..add(const LoadCurrentSubscription()),
      child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          final loading =
              state is SubscriptionLoading || state is SubscriptionInitial;
          final canAccess = state is SubscriptionLoaded &&
              state.subscription.canAccessBenefits;

          return _buildScaffold(
            context,
            loadingSubscription: loading,
            canAccess: canAccess,
            modalVariant: state is SubscriptionLoaded
                ? AccountAccessModalVariant.reactivate
                : AccountAccessModalVariant.subscribe,
          );
        },
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool loadingSubscription,
    required bool canAccess,
    required AccountAccessModalVariant modalVariant,
  }) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar desconto')),
      body: Builder(
        builder: (context) {
          if (loadingSubscription) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!canAccess) {
            return _BlockedScheduleState(
              modalVariant: modalVariant,
              onRestore: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlansPage()),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BeneficiarySelector(
                dependents: dependents,
                onSelected: (_) {},
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BlockedScheduleState extends StatelessWidget {
  final AccountAccessModalVariant modalVariant;
  final VoidCallback onRestore;

  const _BlockedScheduleState({
    required this.modalVariant,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Agendamento bloqueado', style: AppTheme.headingMedium),
        const SizedBox(height: 8),
        Text(
          'Regularize sua assinatura mensal para agendar descontos, gerar QR e usar os beneficios do VittaClube.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: modalVariant == AccountAccessModalVariant.subscribe
              ? 'Assinar agora'
              : 'Reativar minha conta',
          onPressed: onRestore,
        ),
      ],
    );
  }
}
