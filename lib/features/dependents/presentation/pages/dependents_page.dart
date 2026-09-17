import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/how_it_works_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/restore_account_modal.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../domain/entities/dependent_enums.dart';
import '../../domain/services/dependent_cycle_service.dart';
import '../../domain/usecases/get_dependents_usecase.dart';
import '../bloc/dependents_bloc.dart';
import '../bloc/dependents_event.dart';
import '../bloc/dependents_state.dart';
import '../widgets/dependent_form.dart';

/// Tela do titular pra gerenciar seus dependentes (cadastrar, ver status de
/// aprovação, desativar). Ver docs/feature/dependentes.md pras regras.
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
        adhesionDate: subscription.activationDate,
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
            adhesionDate: state is SubscriptionLoaded
                ? state.subscription.activationDate
                : null,
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
    required DateTime? adhesionDate,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 12),
                  Text(
                    'Dependentes',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Builder(
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

                  if (initialLimitReached) {
                    return const _LimitReachedStaticState();
                  }

                  return BlocProvider(
                    create: (_) => sl<DependentsBloc>(),
                    child: _DependentsListView(
                      holderUserId: holderUserId,
                      adhesionDate: adhesionDate ?? DateTime.now(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado estático usado só quando `initialLimitReached` é forçado de fora
/// (preview/teste) — não passa pelo bloc.
class _LimitReachedStaticState extends StatelessWidget {
  const _LimitReachedStaticState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const HowItWorksCard(
          body: _dependentsHowItWorksBody,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8872B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFE8872B).withValues(alpha: 0.25)),
          ),
          child: Text(
            'Você atingiu o limite de dependentes do seu plano.',
            style:
                GoogleFonts.outfit(fontSize: 13, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 24),
        const PrimaryButton(text: 'Adicionar dependente', onPressed: null),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DependentsListView extends StatefulWidget {
  final String holderUserId;
  final DateTime adhesionDate;

  const _DependentsListView({
    required this.holderUserId,
    required this.adhesionDate,
  });

  @override
  State<_DependentsListView> createState() => _DependentsListViewState();
}

class _DependentsListViewState extends State<_DependentsListView> {
  late final String _cycleReference;

  @override
  void initState() {
    super.initState();
    _cycleReference = DependentCycleService().currentCycleReference(
      adhesionDate: widget.adhesionDate,
      now: DateTime.now(),
    );
    _load();
  }

  void _load() {
    context.read<DependentsBloc>().add(
          LoadDependents(
            holderUserId: widget.holderUserId,
            cycleReference: _cycleReference,
          ),
        );
  }

  void _openAddDependentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: DependentForm(
              onSubmit: ({
                required name,
                required cpf,
                required birthDate,
                required relationship,
              }) {
                Navigator.pop(sheetContext);
                context.read<DependentsBloc>().add(
                      CreateDependentRequested(
                        holderUserId: widget.holderUserId,
                        name: name,
                        cpf: cpf,
                        birthDate: birthDate,
                        relationship: relationship,
                      ),
                    );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeactivate(String dependentId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover dependente'),
        content: Text('Remover $name da sua lista de dependentes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DependentsBloc>().add(
                    DeactivateDependentRequested(
                      holderUserId: widget.holderUserId,
                      dependentId: dependentId,
                    ),
                  );
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DependentsBloc, DependentsState>(
      listener: (context, state) {
        if (state.status == DependentsStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feito!')),
          );
          _load();
        } else if (state.status == DependentsStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == DependentsStatus.loading ||
            state.status == DependentsStatus.initial;
        final saving = state.status == DependentsStatus.saving;
        final canAddMore = !state.limitReached && state.items.length < 2;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const HowItWorksCard(
              body: _dependentsHowItWorksBody,
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEBEEF2)),
                ),
                child: Text(
                  'Nenhum dependente cadastrado ainda.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
              )
            else
              ...state.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DependentCard(
                    item: item,
                    onRemove: () => _confirmDeactivate(
                        item.dependent.id, item.dependent.name),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: saving ? 'Salvando...' : 'Adicionar dependente',
              onPressed: canAddMore && !saving ? _openAddDependentSheet : null,
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

const _dependentsHowItWorksBody =
    'Você pode cadastrar até 2 dependentes, cada um com direito a '
    '1 consulta com desconto por mês. Um cadastro novo fica '
    '"Pendente" até ser aprovado presencialmente na recepção Vitta — '
    'leve o dependente com documento na primeira visita. Depois de '
    'ativo, escolha o nome dele na carteirinha para mostrar no caixa '
    'do parceiro ou na recepção.';

class _DependentCard extends StatelessWidget {
  final DependentWithQuota item;
  final VoidCallback onRemove;

  const _DependentCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final dependent = item.dependent;
    final (label, color) = switch (dependent.status) {
      DependentStatus.pending => (
          'Pendente de aprovação',
          const Color(0xFFE8872B)
        ),
      DependentStatus.active => ('Ativo', const Color(0xFF249689)),
      DependentStatus.inactive => ('Inativo', const Color(0xFF6D7F95)),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dependent.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dependent.relationship,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                    if (dependent.isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${item.remainingUses} uso(s) restante(s) no ciclo',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: const Color(0xFF6D7F95),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (dependent.status != DependentStatus.inactive)
            GestureDetector(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 18, color: Color(0xFF6D7F95)),
              ),
            ),
        ],
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
          Text(
            'Dependentes bloqueados',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Regularize sua assinatura mensal para cadastrar dependentes e '
            'liberar o uso dos benefícios do clube.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF6D7F95),
            ),
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
