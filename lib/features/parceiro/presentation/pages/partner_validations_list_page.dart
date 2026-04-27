import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../admin/presentation/widgets/admin_search_bar.dart';
import '../../../admin/presentation/widgets/admin_empty_state.dart';
import '../bloc/partner_validation/partner_validation_bloc.dart';
import '../bloc/partner_validation/partner_validation_event.dart';
import '../bloc/partner_validation/partner_validation_state.dart';

class PartnerValidationsListPage extends StatelessWidget {
  final String partnerId;

  const PartnerValidationsListPage({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PartnerValidationBloc>()..add(LoadPartnerValidations(partnerId)),
      child: const _PartnerValidationsListView(),
    );
  }
}

class _PartnerValidationsListView extends StatelessWidget {
  const _PartnerValidationsListView();

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Validacoes',
      body: Column(
        children: [
          AdminSearchBar(
            onChanged: (query) {
              context.read<PartnerValidationBloc>().add(SearchPartnerValidations(query));
            },
          ),
          const SizedBox(height: 16),
          BlocBuilder<PartnerValidationBloc, PartnerValidationState>(
            builder: (context, state) {
              if (state.status == PartnerValidationStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }

              if (state.filteredItems.isEmpty &&
                  state.status == PartnerValidationStatus.loaded) {
                return const AdminEmptyState(
                  icon: Icons.verified_outlined,
                  message: 'Nenhuma validacao encontrada',
                  subtitle: 'As validacoes de desconto aparecerao aqui.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.filteredItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final validation = state.filteredItems[index];
                  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEBEEF2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                validation.userName,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'R\$ ${validation.discountApplied.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          validation.serviceName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D7F95),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(validation.validatedAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9EAAB8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
