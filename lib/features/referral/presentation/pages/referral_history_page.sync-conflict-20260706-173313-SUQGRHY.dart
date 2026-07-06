import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/referral_entity.dart';
import '../bloc/referral_bloc.dart';
import '../bloc/referral_event.dart';
import '../bloc/referral_state.dart';
import '../widgets/referral_item.dart';

/// Pagina de historico detalhado de indicacoes com filtros.
class ReferralHistoryPage extends StatelessWidget {
  const ReferralHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    return BlocProvider(
      create: (_) {
        final bloc = sl<ReferralBloc>();
        if (userId != null) bloc.add(LoadReferrals(userId));
        return bloc;
      },
      child: const _ReferralHistoryView(),
    );
  }
}

class _ReferralHistoryView extends StatefulWidget {
  const _ReferralHistoryView();

  @override
  State<_ReferralHistoryView> createState() => _ReferralHistoryViewState();
}

class _ReferralHistoryViewState extends State<_ReferralHistoryView> {
  ReferralStatus? _selectedFilter;

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
          'Historico de Indicacoes',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ReferralBloc, ReferralState>(
        builder: (context, state) {
          if (state.status == ReferralBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _selectedFilter != null
              ? state.referrals
                  .where((r) => r.status == _selectedFilter)
                  .toList()
              : state.referrals;

          return Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('Todos', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pendentes', ReferralStatus.pending),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ativos', ReferralStatus.active),
                    const SizedBox(width: 8),
                    _buildFilterChip('Resgatados', ReferralStatus.rewarded),
                  ],
                ),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma indicacao encontrada.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return ReferralItem(
                            referral: filtered[index],
                            onClaimReward: () {
                              context.read<ReferralBloc>().add(
                                    ClaimRewardRequested(filtered[index].id),
                                  );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, ReferralStatus? status) {
    final isSelected = _selectedFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.secondaryText,
          ),
        ),
      ),
    );
  }
}
