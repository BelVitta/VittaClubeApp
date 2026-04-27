import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/coupon/coupon_bloc.dart';
import '../../bloc/coupon/coupon_event.dart';
import '../../bloc/coupon/coupon_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import '../../widgets/admin_filter_chip.dart';
import 'admin_coupon_form_page.dart';

class AdminCouponsListPage extends StatelessWidget {
  const AdminCouponsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponBloc>()..add(LoadCoupons()),
      child: const _CouponsListView(),
    );
  }
}

class _CouponsListView extends StatelessWidget {
  const _CouponsListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CouponBloc, CouponState>(
      listenWhen: (previous, current) =>
          current.status == CouponStatus.saved ||
          current.status == CouponStatus.deleted ||
          current.status == CouponStatus.failure,
      listener: (context, state) {
        if (state.status == CouponStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cupom salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == CouponStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cupom excluido com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == CouponStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Erro ao processar operacao.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AdminPageScaffold(
          title: 'Cupons',
          body: Column(
            children: [
              AdminSearchBar(
                onChanged: (query) {
                  context.read<CouponBloc>().add(SearchCoupons(query));
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              BlocBuilder<CouponBloc, CouponState>(
                buildWhen: (prev, curr) =>
                    prev.filterIsActive != curr.filterIsActive,
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AdminFilterChip(
                          icon: Icons.toggle_on_outlined,
                          label: state.filterIsActive == null
                              ? 'Status'
                              : (state.filterIsActive! ? 'Ativo' : 'Inativo'),
                          isActive: state.filterIsActive != null,
                          onTap: () {
                            AdminFilterChip.showFilterBottomSheet(
                              context,
                              title: 'Filtrar por Status',
                              options: ['ativo', 'inativo'],
                              current: state.filterIsActive == null
                                  ? null
                                  : (state.filterIsActive! ? 'ativo' : 'inativo'),
                              onSelected: (value) {
                                context.read<CouponBloc>().add(
                                    FilterCouponsByStatus(
                                        value == null ? null : value == 'ativo'));
                              },
                            );
                          },
                        ),
                        if (state.hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          AdminFilterChip(
                            icon: Icons.clear,
                            label: 'Limpar',
                            isActive: false,
                            onTap: () => context
                                .read<CouponBloc>()
                                .add(ClearCouponFilters()),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<CouponBloc, CouponState>(
                builder: (context, state) {
                  if (state.status == CouponStatus.loading) {
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
                      state.status == CouponStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.confirmation_number_outlined,
                      message: 'Nenhum cupom encontrado',
                      subtitle:
                          'Toque no botao + para cadastrar um novo cupom.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final coupon = state.filteredItems[index];
                      return AdminListItem(
                        title:
                            '${coupon.code} (${coupon.discountPercentage.toStringAsFixed(0)}%)',
                        subtitle:
                            '${coupon.description} - Uso: ${coupon.usedCount}/${coupon.usageLimit}',
                        leading: AdminStatusBadge(
                          status: coupon.isActive ? 'ativo' : 'inativo',
                        ),
                        onEdit: () {
                          final bloc = context.read<CouponBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: AdminCouponFormPage(
                                  entity: coupon,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              context
                                  .read<CouponBloc>()
                                  .add(LoadCoupons());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            coupon.code,
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<CouponBloc>()
                                .add(DeleteCouponRequested(coupon.id));
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          onPressed: () {
            final bloc = context.read<CouponBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminCouponFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context.read<CouponBloc>().add(LoadCoupons());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
