import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/payment_receipt_sheet.dart';
import 'cancellation_page.dart';

/// Dados mock de um pagamento no histórico
class _PaymentHistoryItem {
  final String title;
  final String date;
  final String method;
  final String amount;

  const _PaymentHistoryItem({
    required this.title,
    required this.date,
    required this.method,
    required this.amount,
  });
}

/// Página de Pagamentos com resumo do plano, ações rápidas e histórico
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  static const List<_PaymentHistoryItem> _history = [
    _PaymentHistoryItem(
      title: 'Plano Mensal',
      date: '16/11/2025',
      method: 'Pix',
      amount: '34,99',
    ),
    _PaymentHistoryItem(
      title: 'Plano Mensal',
      date: '16/10/2025',
      method: 'Pix',
      amount: '34,99',
    ),
    _PaymentHistoryItem(
      title: 'Plano Mensal',
      date: '16/09/2025',
      method: 'Cartão de Crédito',
      amount: '34,99',
    ),
    _PaymentHistoryItem(
      title: 'Plano Mensal',
      date: '16/08/2025',
      method: 'Cartão de Crédito',
      amount: '34,99',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient circle
            Positioned(
              top: -16,
              right: -180,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color: const Color(0xFF01225B)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(19.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Pagamento',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Plan info card
                        _buildPlanInfoCard(),
                        const SizedBox(height: 12),

                        // Quick actions
                        _buildQuickActions(context),
                        const SizedBox(height: 16),

                        // Payment history
                        Text(
                          'Histórico de Pagamentos',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.075,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._history.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildHistoryItem(context, item),
                            )),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Plano X',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF249689).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ativo',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF249689),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '•••• 4532',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D7F95),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Mensalidade',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D7F95),
                    ),
                  ),
                  Text(
                    'R\$ 34,99',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: const Color(0xFFEBEEF2).withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximo Vencimento:',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6D7F95),
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                '16/01/2026',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionCard(
          icon: Icons.credit_card,
          label: 'Pagar',
          onTap: () {
            // TODO: Navigate to payment
          },
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildActionCard(
            icon: Icons.swap_horiz,
            label: 'Forma de\nPagamento',
            onTap: () {
              // TODO: Change payment method
            },
          ),
        ),
        const SizedBox(width: 6),
        _buildActionCard(
          icon: Icons.block,
          label: 'Cancelar',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CancellationPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEEF2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: AppTheme.primaryColor),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, _PaymentHistoryItem item) {
    return GestureDetector(
      onTap: () {
        PaymentReceiptSheet.show(
          context,
          receiptNumber: 'REC-2025-001234',
          dateTime: '16 de dez. de 2025 às 21:52',
          paymentMethod: item.method == 'Pix'
              ? 'Pix'
              : 'Cartão •••• 4532',
          status: 'Pago',
          planName: item.title,
          amount: item.amount,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEEF2)),
        ),
        child: Row(
          children: [
            // Check icon
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF249689),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${item.date} - ${item.method}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D7F95),
                    ),
                  ),
                ],
              ),
            ),

            // Amount + chevron
            Text(
              'R\$ ${item.amount}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
