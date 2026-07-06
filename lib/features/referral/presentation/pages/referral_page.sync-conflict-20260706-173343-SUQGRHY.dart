import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/referral_bloc.dart';
import '../bloc/referral_event.dart';
import '../bloc/referral_state.dart';
import '../widgets/referral_code_card.dart';
import '../widgets/referral_item.dart';

/// Pagina principal de indicacoes - "Indique e Ganhe".
class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    return BlocProvider(
      create: (_) {
        final bloc = sl<ReferralBloc>();
        if (userId != null) bloc.add(LoadReferrals(userId));
        return bloc;
      },
      child: _ReferralView(userId: userId),
    );
  }
}

class _ReferralView extends StatelessWidget {
  final String? userId;

  const _ReferralView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              size: 18, color: AppTheme.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Indique e Ganhe',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ReferralBloc, ReferralState>(
        listener: (context, state) {
          if (state.status == ReferralBlocStatus.created) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Codigo de indicacao criado!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
          if (state.status == ReferralBlocStatus.claimed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recompensa resgatada com sucesso!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            final id = userId;
            if (id != null) context.read<ReferralBloc>().add(LoadReferrals(id));
          }
          if (state.status == ReferralBlocStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Erro ao processar.'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ReferralBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                _buildStatsRow(state),
                const SizedBox(height: 20),
                // Referral code card
                ReferralCodeCard(
                  referralCode: state.lastCreated?.referralCode ?? '',
                  referralsThisMonth: state.referralsThisMonth,
                  canCreateMore: state.canCreateMore,
                  onGenerateCode: () {
                    final id = userId;
                    if (id == null) return;
                    context
                        .read<ReferralBloc>()
                        .add(CreateReferralRequested(id));
                  },
                  onShare: () {
                    // TODO: Implementar share nativo
                  },
                ),
                const SizedBox(height: 24),
                // Rules section
                _buildRulesSection(),
                const SizedBox(height: 24),
                // History
                Text(
                  'Historico de Indicacoes',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.referrals.isEmpty)
                  _buildEmptyState()
                else
                  ...state.referrals.map((referral) => ReferralItem(
                        referral: referral,
                        onClaimReward: () {
                          context
                              .read<ReferralBloc>()
                              .add(ClaimRewardRequested(referral.id));
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(ReferralState state) {
    return Row(
      children: [
        _buildStatCard(
          'Ativas',
          state.activeCount.toString(),
          const Color(0xFF2196F3),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'Resgatadas',
          state.rewardedCount.toString(),
          AppTheme.successColor,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'Pendentes',
          state.pendingCount.toString(),
          const Color(0xFFE8872B),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como funciona',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          _buildRuleItem('1', 'Compartilhe seu codigo com amigos'),
          _buildRuleItem('2', 'Seu amigo se cadastra usando o codigo'),
          _buildRuleItem('3', 'Ele deve permanecer ativo por 60 dias'),
          _buildRuleItem('4', 'E realizar pelo menos 1 consulta'),
          _buildRuleItem('5', 'Voce recebe creditos como recompensa!'),
          const SizedBox(height: 8),
          Text(
            'Limite: 10 indicacoes por mes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppTheme.secondaryText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma indicacao ainda',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gere um codigo e compartilhe com amigos!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
