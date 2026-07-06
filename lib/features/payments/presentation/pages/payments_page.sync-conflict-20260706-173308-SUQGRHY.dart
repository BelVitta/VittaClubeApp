import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../widgets/payment_receipt_sheet.dart';
import 'cancellation_page.dart';

class _PaymentHistoryItem {
  final String receiptNumber;
  final String title;
  final String date;
  final String dateTime;
  final String method;
  final String amount;
  final String status;

  const _PaymentHistoryItem({
    required this.receiptNumber,
    required this.title,
    required this.date,
    required this.dateTime,
    required this.method,
    required this.amount,
    required this.status,
  });
}

class _PaymentsData {
  final String planName;
  final String status;
  final String paymentMethod;
  final String monthlyAmount;
  final String nextBillingDate;
  final List<_PaymentHistoryItem> history;

  const _PaymentsData({
    required this.planName,
    required this.status,
    required this.paymentMethod,
    required this.monthlyAmount,
    required this.nextBillingDate,
    required this.history,
  });
}

/// Página de Pagamentos com resumo do plano, ações rápidas e histórico
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  Future<_PaymentsData> _loadPayments() async {
    final supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Usuário não autenticado.');
    }

    final subscription = await supabase
        .from('subscriptions')
        .select('id, status, value_cents, next_billing_date, plans(name)')
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();

    final payments = await supabase
        .from('payments')
        .select(
          'id, amount, method, status, receipt_number, paid_at, created_at, subscriptions(plans(name))',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final history = (payments as List<dynamic>).map((raw) {
      final row = raw as Map<String, dynamic>;
      final dateRaw = (row['paid_at'] ?? row['created_at']) as String;
      final date = DateTime.parse(dateRaw).toLocal();
      final planName =
          ((row['subscriptions'] as Map<String, dynamic>?)?['plans']
                  as Map<String, dynamic>?)?['name'] as String? ??
              'Plano Vita';
      return _PaymentHistoryItem(
        receiptNumber: row['receipt_number'] as String? ?? row['id'] as String,
        title: planName,
        date: _date(date),
        dateTime: _dateTime(date),
        method: _method(row['method'] as String?),
        amount: _money((row['amount'] as num?)?.toDouble() ?? 0),
        status: _status(row['status'] as String?),
      );
    }).toList();

    final sub = subscription;
    if (sub == null) {
      return _PaymentsData(
        planName: 'Sem plano ativo',
        status: 'Inativo',
        paymentMethod: 'Não configurado',
        monthlyAmount: 'R\$ 0,00',
        nextBillingDate: 'Sem vencimento',
        history: history,
      );
    }

    final planName =
        (sub['plans'] as Map<String, dynamic>?)?['name'] as String? ??
            'Plano Vita';
    final cents = sub['value_cents'] as int? ?? 0;
    final nextBillingRaw = sub['next_billing_date'] as String?;
    return _PaymentsData(
      planName: planName,
      status: _status(sub['status'] as String?),
      paymentMethod: 'Pix Automático',
      monthlyAmount: _money(cents / 100),
      nextBillingDate: nextBillingRaw == null
          ? 'Aguardando autorização'
          : _date(DateTime.parse(nextBillingRaw).toLocal()),
      history: history,
    );
  }

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
                            color:
                                const Color(0xFF01225B).withValues(alpha: 0.2),
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

                Expanded(
                  child: FutureBuilder<_PaymentsData>(
                    future: _loadPayments(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return _buildLoadError();
                      }
                      final data = snapshot.data!;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            _buildPlanInfoCard(data),
                            const SizedBox(height: 12),
                            _buildQuickActions(context),
                            const SizedBox(height: 16),
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
                            if (data.history.isEmpty)
                              _buildEmptyHistory()
                            else
                              ...data.history.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: _buildHistoryItem(context, item),
                                  )),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInfoCard(_PaymentsData data) {
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
                        data.planName,
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
                          data.status,
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
                    data.paymentMethod,
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
                    data.monthlyAmount,
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
              height: 1, color: const Color(0xFFEBEEF2).withValues(alpha: 0.5)),
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
                data.nextBillingDate,
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlansPage()),
            );
          },
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildActionCard(
            icon: Icons.swap_horiz,
            label: 'Forma de\nPagamento',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlansPage()),
              );
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
              MaterialPageRoute(builder: (_) => const CancellationPage()),
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
          receiptNumber: item.receiptNumber,
          dateTime: item.dateTime,
          paymentMethod: item.method,
          status: item.status,
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
              item.amount,
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

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Não foi possível carregar os pagamentos.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF6D7F95),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Nenhum pagamento encontrado.',
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: const Color(0xFF6D7F95),
        ),
      ),
    );
  }

  static String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _dateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_date(date)} às $hour:$minute';
  }

  static String _method(String? value) {
    switch (value) {
      case 'pix':
        return 'Pix';
      case 'credit_card':
        return 'Cartão de Crédito';
      default:
        return value ?? 'Não informado';
    }
  }

  static String _status(String? value) {
    switch (value) {
      case 'aprovado':
      case 'paid':
      case 'active':
        return 'Pago';
      case 'pending':
      case 'payment_pending':
        return 'Pendente';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      default:
        return value ?? 'Não informado';
    }
  }
}
