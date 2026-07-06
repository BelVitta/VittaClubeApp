import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/restore_account_modal.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../plans/presentation/pages/plans_page.dart';

class DependentsPage extends StatelessWidget {
  final String holderUserId;
  final bool initialLimitReached;
  final SubscriptionEntity? subscription;

  const DependentsPage({
    super.key,
    required this.holderUserId,
    this.initialLimitReached = false,
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dependentes'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: Builder(
        builder: (context) {
          if (loadingSubscription) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!canAccess) {
            return _BlockedDependentsState(
              modalVariant: modalVariant,
              onRestore: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlansPage()),
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Gerencie quem pode usar seus beneficios',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Os dependentes usam uma cota mensal propria. O agendamento nao '
                  'consome cota; o uso so e debitado quando a recepcao valida o QR.',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 16),
                if (initialLimitReached)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text(
                      'Voce atingiu o limite de dependentes ativos do seu plano.',
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Nenhum dependente cadastrado ainda.',
                    ),
                  ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Adicionar dependente',
                  onPressed: initialLimitReached ? null : () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BlockedDependentsState extends StatelessWidget {
  final AccountAccessModalVariant modalVariant;
  final VoidCallback onRestore;

  const _BlockedDependentsState({
    required this.modalVariant,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dependentes bloqueados', style: AppTheme.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Regularize sua assinatura mensal para cadastrar dependentes e liberar o uso dos beneficios do clube.',
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
      ),
    );
  }
}
