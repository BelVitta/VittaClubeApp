import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/usecases/partner/get_all_partners_for_financeiro_usecase.dart';
import 'financeiro_partner_form_page.dart';

/// Gestão do acordo: financeiro publica o % vivo de cada parceiro.
class FinanceiroPartnersListPage extends StatefulWidget {
  const FinanceiroPartnersListPage({super.key});

  @override
  State<FinanceiroPartnersListPage> createState() =>
      _FinanceiroPartnersListPageState();
}

class _FinanceiroPartnersListPageState
    extends State<FinanceiroPartnersListPage> {
  late Future<List<PartnerEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PartnerEntity>> _load() async {
    final result = await sl<GetAllPartnersForFinanceiroUseCase>()();
    return result.fold((f) => throw Exception(f.message), (items) => items);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Parceiros',
      subtitle:
          'Publique o percentual do acordo. O caixa e o catálogo usam este número.',
      body: FutureBuilder<List<PartnerEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text(
              'Não foi possível carregar os parceiros.',
              style: GoogleFonts.outfit(color: const Color(0xFF6D7F95)),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Text(
              'Nenhum parceiro cadastrado ainda.',
              style: GoogleFonts.outfit(color: const Color(0xFF6D7F95)),
            );
          }
          return Column(
            children: items
                .map(
                  (partner) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEBEEF2)),
                      ),
                      title: Text(
                        partner.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      subtitle: Text(
                        '${partner.category} · '
                        '${partner.isActive ? 'Ativo' : 'Inativo'} · '
                        '${partner.discountPercentage.toStringAsFixed(0)}%',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FinanceiroPartnerFormPage(partner: partner),
                          ),
                        );
                        if (changed == true && mounted) _reload();
                      },
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
