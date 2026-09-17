import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/whatsapp_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../card/presentation/widgets/qr_code_sheet.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../dependents/domain/entities/dependent_enums.dart';
import '../../../dependents/domain/services/dependent_cycle_service.dart';
import '../../../dependents/presentation/bloc/dependent_appointment_bloc.dart';
import '../../../dependents/presentation/bloc/dependent_appointment_event.dart';
import '../../../dependents/presentation/bloc/dependent_appointment_state.dart';
import '../../../dependents/presentation/bloc/dependents_bloc.dart';
import '../../../dependents/presentation/bloc/dependents_event.dart';
import '../../../dependents/presentation/bloc/dependents_state.dart';
import '../../../dependents/presentation/widgets/beneficiary_selector.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/restore_account_modal.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';

/// Passo antes de combinar a consulta por WhatsApp: escolhe pra quem é o
/// desconto (titular ou dependente ativo), gera o QR do agendamento (sem
/// debitar cota — isso só acontece quando a recepção validar o QR).
class ConsultationSchedulePage extends StatelessWidget {
  final String holderUserId;
  final String professionalName;
  final SubscriptionEntity? subscription;

  const ConsultationSchedulePage({
    super.key,
    required this.holderUserId,
    required this.professionalName,
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

          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<DependentsBloc>()),
              BlocProvider(create: (_) => sl<DependentAppointmentBloc>()),
            ],
            child: _ScheduleForm(
              holderUserId: holderUserId,
              professionalName: professionalName,
              adhesionDate: adhesionDate ?? DateTime.now(),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleForm extends StatefulWidget {
  final String holderUserId;
  final String professionalName;
  final DateTime adhesionDate;

  const _ScheduleForm({
    required this.holderUserId,
    required this.professionalName,
    required this.adhesionDate,
  });

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    final cycleReference = DependentCycleService().currentCycleReference(
      adhesionDate: widget.adhesionDate,
      now: DateTime.now(),
    );
    context.read<DependentsBloc>().add(
          LoadDependents(
            holderUserId: widget.holderUserId,
            cycleReference: cycleReference,
            status: DependentStatus.active,
          ),
        );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (!mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  void _handleSelected(BeneficiarySelection selection) {
    context.read<DependentAppointmentBloc>().add(
          CreateDependentAppointmentRequested(
            holderUserId: widget.holderUserId,
            beneficiaryType: selection.isHolder
                ? BeneficiaryType.holder
                : BeneficiaryType.dependent,
            beneficiaryId: selection.beneficiaryId,
            scheduledAt: _scheduledAt,
          ),
        );
  }

  Future<void> _afterAppointmentCreated(String qrToken) async {
    await QrCodeSheet.show(
      context,
      qrPayload: qrToken,
      memberCodeDisplay:
          qrToken.length > 16 ? '${qrToken.substring(0, 8)}…' : qrToken,
      memberCodeRaw: qrToken,
    );
    if (!mounted) return;
    await WhatsAppLauncher.open(
      presetMessage: 'Olá! Gostaria de agendar uma consulta com '
          '${widget.professionalName} pelo Vita Clube em '
          '${DateFormat('dd/MM/yyyy \'às\' HH:mm').format(_scheduledAt)}.',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DependentAppointmentBloc, DependentAppointmentState>(
      listener: (context, state) {
        if (state.status == DependentAppointmentStatusState.created &&
            state.appointment != null) {
          _afterAppointmentCreated(state.appointment!.qrToken);
        } else if (state.status == DependentAppointmentStatusState.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, appointmentState) {
        final creating =
            appointmentState.status == DependentAppointmentStatusState.loading;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Quando vai ser a consulta?', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Isso é só uma previsão pra gerar o QR — o horário final é '
              'combinado por WhatsApp com a recepção.',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                DateFormat('dd/MM/yyyy \'às\' HH:mm').format(_scheduledAt),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<DependentsBloc, DependentsState>(
              builder: (context, depState) {
                if (depState.status == DependentsStatus.loading ||
                    depState.status == DependentsStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                return AbsorbPointer(
                  absorbing: creating,
                  child: Opacity(
                    opacity: creating ? 0.5 : 1,
                    child: BeneficiarySelector(
                      dependents: depState.items,
                      onSelected: _handleSelected,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
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
          'Regularize sua assinatura mensal para agendar descontos, gerar QR e usar os benefícios do VittaClube.',
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
