import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../domain/entities/partner_entity.dart';
import '../../../domain/usecases/partner/get_partners_usecase.dart';
import 'partner_detail_page.dart';
import 'seja_parceiro_page.dart';

class PartnersListPage extends StatefulWidget {
  const PartnersListPage({super.key});

  @override
  State<PartnersListPage> createState() => _PartnersListPageState();
}

class _PartnersListPageState extends State<PartnersListPage> {
  String _searchQuery = '';
  late Future<List<PartnerEntity>> _partnersFuture;

  @override
  void initState() {
    super.initState();
    _partnersFuture = _loadPartners();
  }

  Future<List<PartnerEntity>> _loadPartners() async {
    final result = await sl<GetPartnersUseCase>()();
    return result.fold(
        (failure) => throw Exception(failure.message), (partners) => partners);
  }

  List<PartnerEntity> _filter(List<PartnerEntity> partners) {
    if (_searchQuery.isEmpty) return partners;
    final query = _searchQuery.toLowerCase();
    return partners
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query))
        .toList();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'laboratorio':
        return 'Laboratório';
      case 'clinica':
        return 'Clínica';
      case 'farmacia':
        return 'Farmácia';
      case 'otica':
        return 'Ótica';
      default:
        return 'Outro';
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'laboratorio':
        return Icons.science_outlined;
      case 'clinica':
        return Icons.local_hospital_outlined;
      case 'farmacia':
        return Icons.local_pharmacy_outlined;
      case 'otica':
        return Icons.visibility_outlined;
      default:
        return Icons.store_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Parceiros',
      subtitle: 'Laboratórios, clínicas e mais',
      body: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar parceiro...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF9EAAB8),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF9EAAB8),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Seja Parceiro banner
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SejaParceiroPage(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.gradientDark, AppTheme.gradientLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.handshake,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seja um parceiro Vita Clube',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Cadastre seu estabelecimento',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Partners list
          FutureBuilder<List<PartnerEntity>>(
            future: _partnersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Text(
                    'Não foi possível carregar os parceiros.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6D7F95),
                    ),
                  ),
                );
              }
              final filtered = _filter(snapshot.data ?? const []);
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 48,
                        color: const Color(0xFF9EAAB8).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum parceiro encontrado',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6D7F95),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final partner = filtered[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartnerDetailPage(partner: partner),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEBEEF2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              _categoryIcon(partner.category),
                              size: 24,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  partner.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  partner.discountPercentage > 0
                                      ? '${_categoryLabel(partner.category)} · ${partner.discountPercentage.toStringAsFixed(0)}% de desconto'
                                      : _categoryLabel(partner.category),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF6D7F95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
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
