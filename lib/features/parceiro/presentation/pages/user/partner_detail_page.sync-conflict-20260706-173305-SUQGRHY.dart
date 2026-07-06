import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../domain/entities/partner_entity.dart';
import '../../../domain/entities/partner_service_entity.dart';
import '../../../domain/usecases/partner_service/get_partner_services_usecase.dart';
import 'partner_checkin_page.dart';

class PartnerDetailPage extends StatelessWidget {
  final PartnerEntity partner;

  const PartnerDetailPage({super.key, required this.partner});

  Future<List<PartnerServiceEntity>> _loadServices() async {
    final result = await sl<GetPartnerServicesUseCase>()(partner.id);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (items) => items.where((service) => service.isActive).toList(),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'laboratorio':
        return 'Laboratorio';
      case 'clinica':
        return 'Clinica';
      case 'farmacia':
        return 'Farmacia';
      case 'otica':
        return 'Otica';
      default:
        return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: partner.name,
      subtitle: _categoryLabel(partner.category),
      allowedRoles: null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address
          if (partner.address.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partner.address,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D7F95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Services section
          Text(
            'Servicos Disponiveis',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<PartnerServiceEntity>>(
            future: _loadServices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _buildMessage('Não foi possível carregar os serviços.');
              }
              final services = snapshot.data ?? const [];
              if (services.isEmpty) {
                return _buildMessage('Nenhum serviço disponível.');
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final service = services[index];
                  final discount =
                      ((1 - service.discountedPrice / service.originalPrice) *
                              100)
                          .round();
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
                                service.name,
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
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-$discount%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (service.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            service.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6D7F95),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'R\$ ${service.originalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF9EAAB8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'R\$ ${service.discountedPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Check-in',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PartnerCheckinPage(
                                    partner: partner,
                                    service: service,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF6D7F95),
          ),
        ),
      ),
    );
  }
}
