import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../consultation/presentation/bloc/consultation_bloc.dart';
import '../../../consultation/presentation/bloc/consultation_event.dart';
import '../../../consultation/presentation/bloc/consultation_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/presentation/widgets/restore_account_modal.dart';
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
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final memberName = switch (state) {
                        ProfileLoaded(profile: final p) => p.name,
                        _ => '',
                      };
                      final memberCode = switch (state) {
                        ProfileLoaded(profile: final p) => p.id,
                        _ => '',
                      };
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCard(memberName, memberCode),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final canQr =
                                  widget.subscription?.canUseQr ?? true;
                              if (!canQr) {
                                return PrimaryButton(
                                  text: 'Restaurar conta para usar QR',
                                  onPressed: () =>
                                      RestoreAccountModal.show(context),
                                );
                              }
                              return PrimaryButton(
                                text: 'Mostrar QR Code',
                                onPressed: memberCode.isEmpty
                                    ? null
                                    : () => QrCodeSheet.show(
                                          context,
                                          memberCode: memberCode,
                                        ),
                              );
                            },
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

  Widget _buildCard(String memberName, String memberCode) {
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
              const Icon(Icons.verified_outlined, color: Colors.white, size: 20),
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
                    valueText: '-${currency.format(c.finalValue)}',
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
