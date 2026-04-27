import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_status_badge.dart';
import '../../../domain/entities/payment_admin_entity.dart';

class AdminPaymentDetailPage extends StatelessWidget {
  final PaymentAdminEntity entity;

  const AdminPaymentDetailPage({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Detalhe do Pagamento',
      body: AdminFormCard(
        child: Column(
          children: [
            _DetailRow(label: 'Usuario', value: entity.userName),
            const SizedBox(height: 16),
            _DetailRow(label: 'Plano', value: entity.planName),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Valor',
              value: 'R\$ ${entity.amount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Metodo', value: entity.method),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
                AdminStatusBadge(status: entity.status),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Data', value: entity.date),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'N. do Recibo',
              value: entity.receiptNumber,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6D7F95),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
