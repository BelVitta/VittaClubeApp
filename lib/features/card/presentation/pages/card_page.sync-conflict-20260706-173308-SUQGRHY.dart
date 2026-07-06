import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/discount_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../consultation/domain/entities/consultation_entity.dart';
import '../../../consultation/presentation/bloc/consultation_bloc.dart';
import '../../../consultation/presentation/bloc/consultation_event.dart';
import '../../../consultation/presentation/bloc/consultation_state.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/restore_account_modal.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../widgets/qr_code_sheet.dart';
import '../widgets/transaction_item.dart';

/// Página da Carteirinha Digital VitaClube.
class CardPage extends StatefulWidget {
  final SubscriptionEntity? subscription;

  const CardPage({super.key, this.subscription});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  final int _currentNavIndex = 2;

  void _onNavTap(int index) {
    AppNavigation.goToBottomNavIndex(
      context,
      index,
      currentIndex: AppNavigation.cardIndex,
    );
  }

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
        if (widget.subscription == null)
          BlocProvider(
            create: (_) =>
                sl<SubscriptionBloc>()..add(const LoadCurrentSubscription()),
          ),
      ],
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          final profile =
              profileState is ProfileLoaded ? profileState.profile : null;
          final memberName = profile?.name ?? 'Carregando...';
          final memberId = profile?.id;
          final memberCode = _displayMemberCode(memberId);
          final subscription = widget.subscription;

          if (subscription != null) {
            return _buildScaffold(
              context,
              loadingSubscription: false,
              canUseQr: subscription.canUseQr,
              modalVariant: AccountAccessModalVariant.reactivate,
              memberName: memberName,
              memberCode: memberCode,
              memberId: memberId,
            );
          }

          return BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              final loading =
                  state is SubscriptionLoading || state is SubscriptionInitial;
              final canUseQr =
                  state is SubscriptionLoaded && state.subscription.canUseQr;

              return _buildScaffold(
                context,
                loadingSubscription: loading,
                canUseQr: canUseQr,
                modalVariant: state is SubscriptionLoaded
                    ? AccountAccessModalVariant.reactivate
                    : AccountAccessModalVariant.subscribe,
                memberName: memberName,
                memberCode: memberCode,
                memberId: memberId,
              );
            },
          );
        },
      ),
    );
  }

  String _displayMemberCode(String? memberId) {
    if (memberId == null || memberId.isEmpty) return '--------';
    final normalized = memberId.replaceAll('-', '').toUpperCase();
    if (normalized.length <= 8) return normalized;
    return normalized.substring(0, 8);
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool loadingSubscription,
    required bool canUseQr,
    required AccountAccessModalVariant modalVariant,
    required String memberName,
    required String memberCode,
    required String? memberId,
  }) {
    return Scaffold(
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
                    onTap: () => Navigator.pop(context),
                  ),
                  Text(
                    'Carteirinha',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  _circleIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsPage()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard(
                      memberName: memberName,
                      memberCode: memberCode,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: loadingSubscription
                          ? 'Verificando assinatura...'
                          : canUseQr
                              ? 'Mostrar QR Code'
                              : 'Restaurar conta para usar QR',
                      onPressed: loadingSubscription || memberId == null
                          ? null
                          : () {
                              if (!canUseQr) {
                                RestoreAccountModal.show(
                                  context,
                                  variant: modalVariant,
                                  onRestore: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const PlansPage()),
                                    );
                                  },
                                );
                                return;
                              }
                              QrCodeSheet.show(
                                context,
                                memberCode: memberId,
                              );
                            },
                    ),
                    const SizedBox(height: 24),
                    _buildHistorySection(),
                    const SizedBox(height: 32),
                  ],
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
    );
  }

  Widget _buildCard({
    required String memberName,
    required String memberCode,
  }) {
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
              Text(
                'Vita Clube',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.verified_outlined,
                  color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Titular',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            memberName,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Código',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            memberCode,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return BlocBuilder<ConsultationBloc, ConsultationState>(
      builder: (context, state) {
        final consultations =
            state is ConsultationLoaded ? state.items : <ConsultationEntity>[];
        final totalSavings = consultations.fold<double>(
          0,
          (sum, item) => sum + (item.discountAmount ?? 0),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histórico de uso',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF031535),
                    letterSpacing: 0.075,
                  ),
                ),
                if (totalSavings > 0)
                  Text(
                    'Economia ${DiscountService.formatPrice(totalSavings)}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (state is ConsultationLoading || state is ConsultationInitial)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is ConsultationError)
              Text(
                'Erro no servidor. Não foi possível carregar o histórico agora.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF6D7F95),
                ),
              )
            else if (consultations.isEmpty)
              Text(
                'Nenhuma consulta registrada.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF6D7F95),
                ),
              )
            else
              ...consultations.map(
                (consultation) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TransactionItem(
                    title: consultation.title.isEmpty
                        ? 'Consulta'
                        : consultation.title,
                    subtitle: _consultationSubtitle(consultation),
                    valueText: consultation.finalValue == null
                        ? null
                        : '-${DiscountService.formatPrice(consultation.finalValue!)}',
                    valueColor: AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _consultationSubtitle(ConsultationEntity consultation) {
    final parts = <String>[
      if (consultation.specialtyName != null) consultation.specialtyName!,
      if (consultation.professionalName != null) consultation.professionalName!,
      if ((consultation.discountAmount ?? 0) > 0)
        'Economizou ${DiscountService.formatPrice(consultation.discountAmount!)}',
    ];
    return parts.join(' • ');
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
