import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../domain/entities/partner_entity.dart';
import '../../../domain/entities/partner_service_entity.dart';
import 'partner_checkin_page.dart';

class PartnerDetailPage extends StatelessWidget {
  final PartnerEntity partner;

  const PartnerDetailPage({super.key, required this.partner});

  // Mock services - will be replaced by BLoC
  List<PartnerServiceEntity> get _services {
    switch (partner.id) {
      case 'partner-001':
        return const [
          PartnerServiceEntity(
            id: 'svc-001',
            partnerId: 'partner-001',
            name: 'Hemograma Completo',
            description: 'Exame de sangue completo com analise de celulas',
            originalPrice: 80.00,
            discountedPrice: 56.00,
            isActive: true,
          ),
          PartnerServiceEntity(
            id: 'svc-002',
            partnerId: 'partner-001',
            name: 'Glicemia em Jejum',
            description: 'Dosagem de glicose no sangue',
            originalPrice: 25.00,
            discountedPrice: 17.50,
            isActive: true,
          ),
        ];
      case 'partner-002':
        return const [
          PartnerServiceEntity(
            id: 'svc-003',
            partnerId: 'partner-002',
            name: 'Raio-X Torax',
            description: 'Radiografia da regiao toracica',
            originalPrice: 120.00,
            discountedPrice: 84.00,
            isActive: true,
          ),
          PartnerServiceEntity(
            id: 'svc-004',
            partnerId: 'partner-002',
            name: 'Consulta Clinica Geral',
            description: 'Consulta medica com clinico geral',
            originalPrice: 200.00,
            discountedPrice: 140.00,
            isActive: true,
          ),
        ];
      case 'partner-003':
        return const [
          PartnerServiceEntity(
            id: 'svc-005',
            partnerId: 'partner-003',
            name: 'Exame de Vista',
            description: 'Avaliacao oftalmologica completa',
            originalPrice: 150.00,
            discountedPrice: 105.00,
            isActive: true,
          ),
          PartnerServiceEntity(
            id: 'svc-006',
            partnerId: 'partner-003',
            name: 'Lentes de Contato',
            description: 'Adaptacao e venda de lentes de contato',
            originalPrice: 350.00,
            discountedPrice: 245.00,
            isActive: true,
          ),
        ];
      default:
        return const [];
    }
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final service = _services[index];
              final discount = ((1 - service.discountedPrice / service.originalPrice) * 100).round();
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
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
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
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
