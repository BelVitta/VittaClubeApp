import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Bottom sheet com resumo do pagamento para confirmação
class PaymentSummarySheet extends StatelessWidget {
  final String planName;
  final String paymentMethod;
  final double fee;
  final double total;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PaymentSummarySheet({
    super.key,
    required this.planName,
    required this.paymentMethod,
    required this.fee,
    required this.total,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Resumo do Pagamento',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          // Summary rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildSummaryRow('Plano', planName),
                const SizedBox(height: 8),
                _buildSummaryRow('Método de Pagamento', paymentMethod),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Taxa',
                  'R\$ ${fee.toStringAsFixed(2).replaceAll('.', ',')}',
                  valueFontSize: 15,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Total',
                  'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                  valueFontSize: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          PrimaryButton(
            text: 'Pagar',
            onPressed: onConfirm,
          ),
          const SizedBox(height: 4),
          SecondaryButton(
            text: 'Voltar',
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {double valueFontSize = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: valueFontSize,
            fontWeight: FontWeight.w400,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}
