import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/loyalty_card_payload.dart';
import '../../../consultation/presentation/bloc/consultation_bloc.dart';
import '../../../dependents/domain/entities/dependent_entity.dart';
import '../../../dependents/domain/entities/dependent_enums.dart';
import '../../../dependents/domain/services/dependent_cycle_service.dart';
import '../../../dependents/domain/usecases/get_dependents_usecase.dart';
import '../../../consultation/presentation/bloc/consultation_event.dart';
import '../../../consultation/presentation/bloc/consultation_state.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/restore_account_modal.dart';
import '../widgets/qr_code_sheet.dart';
import '../widgets/transaction_item.dart';

/// Página da Carteirinha Digital VitaClube.
///
/// [subscription] é opcional (útil em testes). Em produção a bottom nav abre
/// sem parâmetro e a página carrega a assinatura via [SubscriptionBloc].
class CardPage extends StatefulWidget {
  final SubscriptionEntity? subscription;

  const CardPage({super.key, this.subscription});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  final int _currentNavIndex = 2;
  DependentEntity? _selectedDependent;
  List<DependentEntity> _activeDependents = const [];
  bool _dependentsLoaded = false;

  void _onNavTap(int index) => AppNavigation.goToBottomNavIndex(
        context,
        index,
        currentIndex: _currentNavIndex,
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const LoadCurrentProfile()),
        ),
        BlocProvider(
          create: (_) =>
              sl<ConsultationBloc>()..add(const LoadUserConsultations()),
        ),
        // Sempre carrega a assinatura real — não confiar em default `?? true`.
        BlocProvider(
          create: (_) =>
              sl<SubscriptionBloc>()..add(const LoadCurrentSubscription()),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        } else {
                          AppNavigation.goToBottomNavIndex(
                            context,
                            AppNavigation.homeIndex,
                            currentIndex: _currentNavIndex,
                          );
                        }
                      },
                    ),
                    Text(
                      'Carteirinha',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 39, height: 39),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final profile =
                          state is ProfileLoaded ? state.profile : null;
                      final memberName = profile?.name ?? '';
                      // QR continua com UUID; display usa member_code curto.
                      final holderId = profile?.id ?? '';
                      if (profile != null && !_dependentsLoaded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _loadDependents(profile.id);
                        });
                      }
                      final qrPayload = _selectedDependent == null
                          ? LoyaltyCardPayload.holder(holderId)
                          : LoyaltyCardPayload.dependent(
                              _selectedDependent!.id,
                            );
                      final memberCodeDisplay =
                          profile?.memberCodeDisplay ?? '—';
                      final memberCodeRaw = profile?.memberCode;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCard(
                            memberName: _selectedDependent?.name ?? memberName,
                            memberCodeDisplay: memberCodeDisplay,
                            isDependent: _selectedDependent != null,
                            relationship: _selectedDependent?.relationship,
                          ),
                          if (_activeDependents.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildBeneficiaryChips(memberName),
                          ],
                          const SizedBox(height: 16),
                          _buildQrAction(
                            qrPayload: qrPayload,
                            memberCodeDisplay: memberCodeDisplay,
                            memberCodeRaw: memberCodeRaw,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Histórico de uso',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF031535),
                              letterSpacing: 0.075,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildUsageHistory(),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),
                ),
              ),
              AppBottomNavigation(
                currentIndex: _currentNavIndex,
                onTap: _onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolve se o QR pode ser usado: parâmetro de teste **ou** estado do BLoC.
  Widget _buildQrAction({
    required String qrPayload,
    required String memberCodeDisplay,
    required String? memberCodeRaw,
  }) {
    // Caminho de teste / caller explícito com subscription injetada.
    if (widget.subscription != null) {
      return _qrButtonFromAccess(
        canUseQr: widget.subscription!.canUseQr,
        hasSubscription: true,
        qrPayload: qrPayload,
        memberCodeDisplay: memberCodeDisplay,
        memberCodeRaw: memberCodeRaw,
        loading: false,
      );
    }

    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        if (subState is SubscriptionLoading ||
            subState is SubscriptionInitial) {
          return _qrButtonFromAccess(
            canUseQr: false,
            hasSubscription: false,
            qrPayload: qrPayload,
            memberCodeDisplay: memberCodeDisplay,
            memberCodeRaw: memberCodeRaw,
            loading: true,
          );
        }

        if (subState is SubscriptionLoaded) {
          return _qrButtonFromAccess(
            canUseQr: subState.subscription.canUseQr,
            hasSubscription: true,
            qrPayload: qrPayload,
            memberCodeDisplay: memberCodeDisplay,
            memberCodeRaw: memberCodeRaw,
            loading: false,
          );
        }

        // NoSubscription ou SubscriptionError → sem QR.
        return _qrButtonFromAccess(
          canUseQr: false,
          hasSubscription: false,
          qrPayload: qrPayload,
          memberCodeDisplay: memberCodeDisplay,
          memberCodeRaw: memberCodeRaw,
          loading: false,
        );
      },
    );
  }

  Widget _qrButtonFromAccess({
    required bool canUseQr,
    required bool hasSubscription,
    required String qrPayload,
    required String memberCodeDisplay,
    required String? memberCodeRaw,
    required bool loading,
  }) {
    if (loading) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!canUseQr) {
      final isSubscribe = !hasSubscription;
      return PrimaryButton(
        text: isSubscribe
            ? 'Assinar para usar o QR'
            : 'Restaurar conta para usar QR',
        onPressed: () {
          if (isSubscribe) {
            RestoreAccountModal.showSubscribe(
              context,
              onSubscribe: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlansPage()),
                );
              },
            );
          } else {
            RestoreAccountModal.showReactivate(
              context,
              onReactivate: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlansPage()),
                );
              },
            );
          }
        },
      );
    }

    return PrimaryButton(
      text: 'Mostrar QR Code',
      onPressed: qrPayload.isEmpty
          ? null
          : () => QrCodeSheet.show(
                context,
                qrPayload: qrPayload,
                memberCodeDisplay: memberCodeDisplay,
                memberCodeRaw: memberCodeRaw,
              ),
    );
  }

  Future<void> _loadDependents(String holderUserId) async {
    if (_dependentsLoaded) return;
    _dependentsLoaded = true;
    if (!sl.isRegistered<GetDependentsUseCase>()) return;
    final cycle = DependentCycleService().currentCycleReference(
      adhesionDate: DateTime.now(),
      now: DateTime.now(),
    );
    final result = await sl<GetDependentsUseCase>()(
      GetDependentsParams(
        holderUserId: holderUserId,
        cycleReference: cycle,
        status: DependentStatus.active,
      ),
    );
    if (!mounted) return;
    result.fold((_) {}, (items) {
      setState(() {
        _activeDependents = items.map((e) => e.dependent).toList();
      });
    });
  }

  Widget _buildBeneficiaryChips(String holderName) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(holderName.isEmpty ? 'Titular' : holderName),
          selected: _selectedDependent == null,
          onSelected: (_) => setState(() => _selectedDependent = null),
        ),
        ..._activeDependents.map(
          (d) => ChoiceChip(
            label: Text(d.name),
            selected: _selectedDependent?.id == d.id,
            onSelected: (_) => setState(() => _selectedDependent = d),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String memberName,
    required String memberCodeDisplay,
    bool isDependent = false,
    String? relationship,
  }) {
    final displayName = memberName.isEmpty ? '—' : memberName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF39586D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Vita Clube',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.verified_outlined,
                  color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            isDependent ? (relationship ?? 'Dependente') : 'Titular',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Código do membro',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            memberCodeDisplay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageHistory() {
    return BlocBuilder<ConsultationBloc, ConsultationState>(
      builder: (context, state) {
        if (state is ConsultationLoading || state is ConsultationInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ConsultationError) {
          return Text(
            'Não foi possível carregar o histórico.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          );
        }
        final used = (state as ConsultationLoaded)
            .items
            .where((c) => c.finalValue != null)
            .toList();
        if (used.isEmpty) {
          return Text(
            'Nenhum uso registrado ainda.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          );
        }
        final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        return Column(
          children: used
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TransactionItem(
                    title: c.professionalName ?? c.title,
                    subtitle: c.specialtyName ??
                        DateFormat('dd/MM/yyyy').format(c.scheduledDate),
                    valueText: c.discountAmount != null && c.discountAmount! > 0
                        ? 'Economizou ${currency.format(c.discountAmount)}'
                        : currency.format(c.finalValue),
                    valueColor:
                        c.discountAmount != null && c.discountAmount! > 0
                            ? const Color(0xFF4CAF50)
                            : null,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: const Color(0xFF01225B).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(19.5),
        ),
        child: Icon(icon, size: 19, color: const Color(0xFF01225B)),
      ),
    );
  }
}
