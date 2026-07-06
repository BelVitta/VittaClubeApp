import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../admin/presentation/widgets/admin_search_bar.dart';
import '../../../admin/presentation/widgets/admin_list_item.dart';
import '../../../admin/presentation/widgets/admin_status_badge.dart';
import '../../../admin/presentation/widgets/admin_empty_state.dart';
import '../../../admin/presentation/widgets/admin_delete_dialog.dart';
import '../bloc/partner_service/partner_service_bloc.dart';
import '../bloc/partner_service/partner_service_event.dart';
import '../bloc/partner_service/partner_service_state.dart';
import 'partner_service_form_page.dart';

class PartnerServicesListPage extends StatelessWidget {
  final String partnerId;

  const PartnerServicesListPage({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<PartnerServiceBloc>()..add(LoadPartnerServices(partnerId)),
      child: _PartnerServicesListView(partnerId: partnerId),
    );
  }
}

class _PartnerServicesListView extends StatelessWidget {
  final String partnerId;

  const _PartnerServicesListView({required this.partnerId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerServiceBloc, PartnerServiceState>(
      listenWhen: (previous, current) =>
          current.status == PartnerServiceStatus.saved ||
          current.status == PartnerServiceStatus.deleted ||
          current.status == PartnerServiceStatus.failure,
      listener: (context, state) {
        if (state.status == PartnerServiceStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Servico salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PartnerServiceStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Servico excluido com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PartnerServiceStatus.failure) {
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
          title: 'Servicos',
          allowedRoles: const ['parceiro'],
          body: Column(
            children: [
              AdminSearchBar(
                onChanged: (query) {
                  context
                      .read<PartnerServiceBloc>()
                      .add(SearchPartnerServices(query));
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<PartnerServiceBloc, PartnerServiceState>(
                builder: (context, state) {
                  if (state.status == PartnerServiceStatus.loading) {
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
                      state.status == PartnerServiceStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.medical_services_outlined,
                      message: 'Nenhum servico encontrado',
                      subtitle:
                          'Toque no botao + para cadastrar um novo servico.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final service = state.filteredItems[index];
                      return AdminListItem(
                        title: service.name,
                        subtitle:
                            'R\$ ${service.originalPrice.toStringAsFixed(2)} → R\$ ${service.discountedPrice.toStringAsFixed(2)}',
                        leading: AdminStatusBadge(
                          status: service.isActive ? 'ativo' : 'inativo',
                        ),
                        onEdit: () {
                          final bloc = context.read<PartnerServiceBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: PartnerServiceFormPage(
                                  partnerId: partnerId,
                                  entity: service,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              bloc.add(LoadPartnerServices(partnerId));
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            service.name,
                          );
                          if (confirmed == true && context.mounted) {
                            context.read<PartnerServiceBloc>().add(
                                  DeletePartnerServiceRequested(
                                    id: service.id,
                                    partnerId: partnerId,
                                  ),
                                );
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
            final bloc = context.read<PartnerServiceBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: PartnerServiceFormPage(partnerId: partnerId),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context
                    .read<PartnerServiceBloc>()
                    .add(LoadPartnerServices(partnerId));
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
