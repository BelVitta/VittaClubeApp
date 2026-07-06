import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_user_card.dart';
import 'notification_settings_page.dart';
import 'personal_data_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import 'privacy_data_page.dart';
import 'security_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../parceiro/presentation/pages/user/seja_parceiro_page.dart';
import '../../../dependents/presentation/pages/dependents_page.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Página principal do Perfil / Configurações
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Navigation icons (same as HomePage)

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(const LoadCurrentProfile()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Background gradient circle (right side like Figma)
              Positioned(
                top: -16,
                right: -180,
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

              // Main content
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Header: "Perfil" + notification bell
                          _buildHeader(context),
                          const SizedBox(height: 12),

                          // User card
                          BlocBuilder<ProfileBloc, ProfileState>(
                            builder: (context, state) {
                              if (state is ProfileLoaded) {
                                final profile = state.profile;
                                return ProfileUserCard(
                                  name: profile.name,
                                  email: profile.email,
                                  memberSince: DateFormat('dd/MM/yyyy')
                                      .format(profile.memberSince),
                                  badgeUrl: profile.avatarUrl,
                                );
                              }

                              if (state is ProfileError) {
                                return const ProfileUserCard(
                                  name: 'Perfil indisponível',
                                  email:
                                      'Não foi possível carregar seus dados.',
                                  memberSince: '--/--/----',
                                );
                              }

                              return const ProfileUserCard(
                                name: 'Carregando...',
                                email: 'Carregando...',
                                memberSince: '--/--/----',
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Menu items
                          _buildMenuItems(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Navigation
                  AppBottomNavigation(
                    currentIndex: 3,
                    onTap: (index) => AppNavigation.goToBottomNavIndex(
                      context,
                      index,
                      currentIndex: AppNavigation.profileIndex,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await sl<AuthSessionManager>().clearSession();
              if (!context.mounted) return;
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Perfil',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF031535),
            letterSpacing: 0.12,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
          child: Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFF01225B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(19.5),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 19,
              color: Color(0xFF01225B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        ProfileMenuItem(
          title: 'Dados Pessoais',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalDataPage()),
          ),
        ),
        const SizedBox(height: 8),
        ProfileMenuItem(
          title: 'Notificações',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
          ),
        ),
        const SizedBox(height: 8),
        ProfileMenuItem(
          title: 'Planos',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlansPage()),
          ),
        ),
        const SizedBox(height: 8),
        ProfileMenuItem(
          title: 'Dependentes',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DependentsPage(holderUserId: 'current-user'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ProfileMenuItem(
          title: 'Segurança',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecurityPage()),
          ),
        ),
        const SizedBox(height: 8),
        ProfileMenuItem(
          title: 'Privacidade e Dados',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyDataPage()),
          ),
        ),
        const SizedBox(height: 8),
        ProfileMenuItem(
          title: 'Seja Parceiro',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SejaParcerioPage()),
          ),
        ),
        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoaded && state.profile.role == 'admin') {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    title: 'Administração',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDashboardPage()),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),

        // Logout button
        ProfileMenuItem(
          title: 'Sair',
          textColor: Colors.red,
          borderColor: Colors.red.withValues(alpha: 0.3),
          showChevron: false,
          onTap: () => _showLogoutDialog(context),
        ),
        const SizedBox(height: 8),

        // Version
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'v1.0',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
