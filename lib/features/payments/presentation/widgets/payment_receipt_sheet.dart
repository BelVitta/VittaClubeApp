import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Bottom sheet de recibo de pagamento
class PaymentReceiptSheet extends StatelessWidget {
  final String receiptNumber;
  final String dateTime;
  final String paymentMethod;
  final String status;
  final String planName;
  final String amount;

  const PaymentReceiptSheet({
    super.key,
    required this.receiptNumber,
    required this.dateTime,
    required this.paymentMethod,
    required this.status,
    required this.planName,
    required this.amount,
  });

  static void show(
    BuildContext context, {
    required String receiptNumber,
    required String dateTime,
    required String paymentMethod,
    required String status,
    required String planName,
    required String amount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentReceiptSheet(
        receiptNumber: receiptNumber,
        dateTime: dateTime,
        paymentMethod: paymentMethod,
        status: status,
        planName: planName,
        amount: amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recibo de Pagamento',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          _buildRow('Número do Recibo', receiptNumber),
          const SizedBox(height: 8),
          _buildRow('Data e Hora', dateTime),
          const SizedBox(height: 8),
          _buildRow('Método de Pagamento', paymentMethod),
          const SizedBox(height: 8),
          _buildRow('Status', status),
          const SizedBox(height: 16),

          // Item section
          Text(
            'Item',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildRow('Plano', 'R\$ $amount'),
          const SizedBox(height: 8),
          Divider(color: const Color(0xFFEBEEF2).withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          _buildRow('Total:', 'R\$ $amount', isBold: true),

          const SizedBox(height: 24),

          // Compartilhar
          PrimaryButton(
            text: 'Compartilhar',
            onPressed: () {
              // TODO: Share receipt
            },
          ),
          const SizedBox(height: 8),

          // Baixar PDF
          GestureDetector(
            onTap: () {
              // TODO: Download PDF
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Baixar PDF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Voltar
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  'Voltar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF6D7F95),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}
