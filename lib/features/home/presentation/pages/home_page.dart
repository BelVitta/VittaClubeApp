import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../badge_progress/presentation/bloc/badge_progress_bloc.dart';
import '../../../badge_progress/presentation/bloc/badge_progress_event.dart';
import '../../../badge_progress/presentation/bloc/badge_progress_state.dart';
import '../../../consultation/presentation/bloc/consultation_bloc.dart';
import '../../../consultation/presentation/bloc/consultation_event.dart';
import '../../../consultation/presentation/bloc/consultation_state.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/no_plan_card.dart';
import '../widgets/plan_banner.dart';
import '../widgets/badge_detail_sheet.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/empty_consultation_state.dart';
import '../widgets/consultation_history_item.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../benefits/presentation/pages/benefits_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../card/presentation/pages/card_page.dart';
import '../../../professionals/presentation/pages/professionals_page.dart';
import '../../../payments/presentation/pages/payments_page.dart';
import '../../../parceiro/presentation/pages/user/partners_list_page.dart';

/// Página inicial. Ouve três BLoCs:
/// - `ProfileBloc` para a saudação (nome do usuário).
/// - `SubscriptionBloc` para decidir entre `NoPlanCard` e `PlanBanner`.
/// - `BadgeProgressBloc` para os números que alimentam o detalhe do badge.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const LoadCurrentProfile()),
        ),
        BlocProvider(
          create: (_) =>
              sl<SubscriptionBloc>()..add(const LoadCurrentSubscription()),
        ),
        BlocProvider(
          create: (_) {
            final bloc = sl<BadgeProgressBloc>();
            if (userId != null) bloc.add(LoadBadgeProgress(userId));
            return bloc;
          },
        ),
        BlocProvider(
          create: (_) =>
              sl<ConsultationBloc>()..add(const LoadUserConsultations()),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _currentNavIndex = 0;

  static const IconData _beneficiosIcon = Icons.star_rounded;
  static const IconData _pagarIcon = Icons.payment_outlined;
  static const IconData _parceirosIcon = Icons.handshake_outlined;
  static const IconData _emptyStateIcon = Icons.calendar_today_outlined;
  static const IconData _consultationBadgeIcon =
      Icons.medical_services_outlined;

  void _goToPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlansPage()),
    ).then((_) {
      if (!mounted) return;
      context.read<SubscriptionBloc>().add(const LoadCurrentSubscription());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -16,
              left: MediaQuery.of(context).size.width / 2 - 251.75,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(),
                        const SizedBox(height: 27),
                        _buildPlanSection(),
                        const SizedBox(height: 12),
                        _buildQuickActions(),
                        const SizedBox(height: 12),
                        _buildConsultationHistory(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                AppBottomNavigation(
                  currentIndex: _currentNavIndex,
                  onTap: (index) {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfessionalsPage()),
                      ).then((_) {
                        setState(() => _currentNavIndex = 0);
                      });
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CardPage()),
                      ).then((_) {
                        setState(() => _currentNavIndex = 0);
                      });
                    } else if (index == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      ).then((_) {
                        setState(() => _currentNavIndex = 0);
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Saudação: primeiro nome do perfil (Supabase). Skeleton enquanto carrega.
        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoaded) {
              final name = state.profile.firstName.isEmpty
                  ? 'visitante'
                  : state.profile.firstName;
              return Text(
                'Olá, $name',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF031535),
                  letterSpacing: 0.12,
                ),
              );
            }
            if (state is ProfileError) {
              return Text(
                'Olá',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF031535),
                  letterSpacing: 0.12,
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.only(top: 6),
              child: SkeletonBox(width: 180, height: 24),
            );
          },
        ),
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: const Color(0xFF01225B).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(19.5),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              size: 19,
              color: Color(0xFF01225B),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// Combina `SubscriptionBloc` + `BadgeProgressBloc`:
  /// - Sem assinatura → `NoPlanCard`
  /// - Com assinatura → `PlanBanner` alimentado pelo progresso real do badge
  Widget _buildPlanSection() {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        if (subState is SubscriptionLoading || subState is SubscriptionInitial) {
          return const SkeletonBox(
            width: double.infinity,
            height: 88,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          );
        }
        if (subState is NoSubscription || subState is SubscriptionError) {
          return NoPlanCard(onTap: _goToPlans);
        }
        if (subState is SubscriptionLoaded) {
          final level = subState.subscription.level;
          return BlocBuilder<BadgeProgressBloc, BadgeProgressState>(
            builder: (context, progState) {
              final progress = progState.progress?.progressToNextLevel ?? 0.0;
              return PlanBanner(
                planLevel: level,
                progress: progress,
                onTap: () {
                  final p = progState.progress;
                  BadgeDetailSheet.show(
                    context,
                    planLevel: level,
                    progress: progress,
                    consultationsThisMonth: p?.consultationCount ?? 0,
                    monthsAsMember: p?.monthsAsMember ?? 0,
                    totalConsultations: p?.consultationCount ?? 0,
                    hasAnnualPlan: p?.hasAnnualPlan ?? false,
                    onViewPlans: _goToPlans,
                  );
                },
              );
            },
          );
        }
        return NoPlanCard(onTap: _goToPlans);
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Beneficios',
                icon: _beneficiosIcon,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BenefitsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: QuickActionCard(
                title: 'Pagar',
                icon: _pagarIcon,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: QuickActionCard(
                title: 'Parceiros',
                icon: _parceirosIcon,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PartnersListPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsultationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de consultas',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF031535),
            letterSpacing: 0.075,
          ),
        ),
        const SizedBox(height: 6),
        BlocBuilder<ConsultationBloc, ConsultationState>(
          builder: (context, state) {
            if (state is ConsultationLoading ||
                state is ConsultationInitial) {
              return Column(
                children: const [
                  SkeletonBox(width: double.infinity, height: 62),
                  SizedBox(height: 6),
                  SkeletonBox(width: double.infinity, height: 62),
                  SizedBox(height: 6),
                  SkeletonBox(width: double.infinity, height: 62),
                ],
              );
            }
            if (state is ConsultationError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  state.message,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
              );
            }
            if (state is ConsultationLoaded) {
              if (state.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: EmptyConsultationState(icon: _emptyStateIcon),
                );
              }
              return Column(
                children: state.items.map((c) {
                  final subtitle = [c.specialtyName, c.subtitle]
                      .whereType<String>()
                      .where((s) => s.trim().isNotEmpty)
                      .join(' · ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ConsultationHistoryItem(
                      title: c.title,
                      subtitle: subtitle.isEmpty
                          ? (c.professionalName ?? '')
                          : subtitle,
                      date: c.scheduledDate,
                      badgeIcon: _consultationBadgeIcon,
                      onTap: () {},
                    ),
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
